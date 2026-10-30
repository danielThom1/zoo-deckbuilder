// Affichage, entrées et interface. Toute la logique de jeu est dans game.js.

import { Game, TICK } from './game.js';

const TERRAIN_COLORS = {
  Prairie: '#7fae5a', Foret: '#2f6b3a', Eau: '#3b78b5', Roche: '#8a8a86',
  Sable: '#d9c48a', Montagne: '#5b5450', MineOr: '#d4a62a',
};
const TERRAIN_NOMS = {
  Prairie: 'Prairie', Foret: 'Forêt', Eau: 'Eau', Roche: 'Roche', Sable: 'Sable', Montagne: 'Montagne', MineOr: "Gisement d'or",
};
const JOB_COLORS = {
  manoeuvre: '#e8e6e1', bucheron: '#c98b4a', carrier: '#b0b8c8', terrassier: '#a3785a', porteur: '#7cc4d8', apprenti: '#e7a3c8',
};
const RES_ICON = { bois: '🪵', pierre: '🪨', or: '🥇' };

async function loadData() {
  const names = ['animals', 'workers', 'buildings'];
  const files = await Promise.all(names.map((n) => fetch(`../game/data/${n}.json`).then((r) => r.json())));
  return Object.fromEntries(names.map((n, i) => [n, files[i]]));
}

const params = new URLSearchParams(location.search);
const seed = Number(params.get('seed')) || Math.floor(Math.random() * 1e9);
const data = await loadData();
const game = new Game(data, seed);
window.game = game; // pratique pour déboguer depuis la console

// --- Caméra ---------------------------------------------------------------

const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');
const cam = { x: 0, y: 0, ts: 18 };
let viewW = 0, viewH = 0;

function resize() {
  const r = canvas.getBoundingClientRect();
  const dpr = window.devicePixelRatio || 1;
  viewW = r.width; viewH = r.height;
  canvas.width = Math.round(r.width * dpr);
  canvas.height = Math.round(r.height * dpr);
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}
new ResizeObserver(resize).observe(canvas);
resize();
cam.x = game.map.camp.x + 1.5 - viewW / cam.ts / 2;
cam.y = game.map.camp.y + 1.5 - viewH / cam.ts / 2;

const toWorld = (px, py) => ({ x: px / cam.ts + cam.x, y: py / cam.ts + cam.y });
const toScreen = (wx, wy) => ({ x: (wx - cam.x) * cam.ts, y: (wy - cam.y) * cam.ts });

// --- Entrées --------------------------------------------------------------

let selected = new Set();
let drag = null;   // sélection en cours (clic gauche)
let pan = null;    // déplacement de vue (clic molette)
let mouse = null;  // position de la souris sur le canvas
let speed = 1;
const keys = new Set();

function workerAt(wx, wy) {
  let best = null, bestD = 0.6;
  for (const w of game.workers) {
    const d = Math.hypot(w.x - wx, w.y - wy);
    if (d < bestD) { best = w; bestD = d; }
  }
  return best;
}

canvas.addEventListener('contextmenu', (e) => e.preventDefault());
canvas.addEventListener('mousedown', (e) => {
  const p = { x: e.offsetX, y: e.offsetY };
  if (e.button === 0) drag = { start: p, end: p, add: e.shiftKey };
  if (e.button === 1) { e.preventDefault(); pan = { p, cam: { ...cam } }; }
  if (e.button === 2) {
    const w = toWorld(p.x, p.y);
    const targets = game.workers.filter((wk) => selected.has(wk));
    if (targets.length) game.order(targets, Math.floor(w.x), Math.floor(w.y));
  }
});
window.addEventListener('mousemove', (e) => {
  const r = canvas.getBoundingClientRect();
  const p = { x: e.clientX - r.left, y: e.clientY - r.top };
  mouse = p.x >= 0 && p.y >= 0 && p.x < r.width && p.y < r.height ? p : null;
  if (drag) drag.end = p;
  if (pan) {
    cam.x = pan.cam.x - (p.x - pan.p.x) / cam.ts;
    cam.y = pan.cam.y - (p.y - pan.p.y) / cam.ts;
  }
});
window.addEventListener('mouseup', (e) => {
  if (e.button === 1) pan = null;
  if (e.button !== 0 || !drag) return;
  const { start, end, add } = drag;
  drag = null;
  if (!add) selected.clear();
  if (Math.hypot(end.x - start.x, end.y - start.y) < 5) {
    const w = toWorld(end.x, end.y);
    const hit = workerAt(w.x, w.y);
    if (hit) selected.add(hit);
  } else {
    const a = toWorld(Math.min(start.x, end.x), Math.min(start.y, end.y));
    const b = toWorld(Math.max(start.x, end.x), Math.max(start.y, end.y));
    for (const w of game.workers) if (w.x >= a.x && w.x <= b.x && w.y >= a.y && w.y <= b.y) selected.add(w);
  }
  renderInfo();
});
canvas.addEventListener('wheel', (e) => {
  e.preventDefault();
  const before = toWorld(e.offsetX, e.offsetY);
  cam.ts = Math.min(48, Math.max(6, cam.ts * (e.deltaY < 0 ? 1.15 : 1 / 1.15)));
  cam.x = before.x - e.offsetX / cam.ts;
  cam.y = before.y - e.offsetY / cam.ts;
}, { passive: false });

window.addEventListener('keydown', (e) => {
  keys.add(e.key.toLowerCase());
  if (e.key === ' ') { e.preventDefault(); setSpeed(speed === 0 ? 1 : 0); }
  if (e.key === '1') setSpeed(1);
  if (e.key === '2') setSpeed(2);
  if (e.key === '3') setSpeed(4);
});
window.addEventListener('keyup', (e) => keys.delete(e.key.toLowerCase()));

function setSpeed(s) {
  speed = s;
  document.querySelectorAll('[data-speed]').forEach((b) => b.classList.toggle('active', Number(b.dataset.speed) === s));
}
document.querySelectorAll('[data-speed]').forEach((b) => b.addEventListener('click', () => setSpeed(Number(b.dataset.speed))));
setSpeed(1);
document.getElementById('endday').addEventListener('click', () => game.endDay());
document.getElementById('sell').addEventListener('click', () => game.sellStock());
document.getElementById('nextday').addEventListener('click', () => { game.startNextDay(); selected.clear(); });

// --- Rendu de la carte ----------------------------------------------------

function draw() {
  const { map } = game;
  const ts = cam.ts;
  ctx.fillStyle = '#0f1115';
  ctx.fillRect(0, 0, viewW, viewH);

  const x0 = Math.max(0, Math.floor(cam.x)), y0 = Math.max(0, Math.floor(cam.y));
  const x1 = Math.min(map.w, Math.ceil(cam.x + viewW / ts)), y1 = Math.min(map.h, Math.ceil(cam.y + viewH / ts));
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
    const t = map.get(x, y);
    const s = toScreen(x, y);
    ctx.fillStyle = TERRAIN_COLORS[t];
    ctx.fillRect(s.x, s.y, ts + 0.5, ts + 0.5);
    if (t === 'Foret' && ts >= 10) {
      ctx.fillStyle = '#1f4f2a';
      ctx.beginPath(); ctx.arc(s.x + ts * 0.5, s.y + ts * 0.45, ts * 0.28, 0, Math.PI * 2); ctx.fill();
    } else if (t === 'Roche' && ts >= 10) {
      ctx.fillStyle = '#6e6e6a';
      ctx.fillRect(s.x + ts * 0.25, s.y + ts * 0.35, ts * 0.45, ts * 0.3);
    } else if (t === 'Montagne' && ts >= 10) {
      ctx.fillStyle = '#7a716b';
      ctx.beginPath(); ctx.moveTo(s.x + ts * 0.15, s.y + ts * 0.85); ctx.lineTo(s.x + ts * 0.5, s.y + ts * 0.15); ctx.lineTo(s.x + ts * 0.85, s.y + ts * 0.85); ctx.fill();
    }
  }
  if (ts >= 22) {
    ctx.strokeStyle = '#00000018';
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let x = x0; x <= x1; x++) { const s = toScreen(x, 0); ctx.moveTo(s.x, 0); ctx.lineTo(s.x, viewH); }
    for (let y = y0; y <= y1; y++) { const s = toScreen(0, y); ctx.moveTo(0, s.y); ctx.lineTo(viewW, s.y); }
    ctx.stroke();
  }

  // Camp de base et mine d'or
  const c = map.camp, cs = toScreen(c.x, c.y);
  ctx.fillStyle = '#8b5e3c';
  ctx.fillRect(cs.x + 2, cs.y + 2, c.w * ts - 4, c.h * ts - 4);
  ctx.strokeStyle = '#5a3a22'; ctx.lineWidth = 2;
  ctx.strokeRect(cs.x + 2, cs.y + 2, c.w * ts - 4, c.h * ts - 4);
  label('Camp', cs.x + (c.w * ts) / 2, cs.y + (c.h * ts) / 2);
  const g = toScreen(map.gold.x, map.gold.y);
  ctx.strokeStyle = '#fff3'; ctx.lineWidth = 2; ctx.strokeRect(g.x + 1, g.y + 1, ts - 2, ts - 2);
  if (ts >= 14) label('Or', g.x + ts / 2, g.y + ts / 2);

  // Chemins des ouvriers sélectionnés
  ctx.setLineDash([4, 4]);
  ctx.strokeStyle = '#ffffffaa'; ctx.lineWidth = 1.5;
  for (const w of selected) {
    if (!w.path.length) continue;
    ctx.beginPath();
    const s = toScreen(w.x, w.y); ctx.moveTo(s.x, s.y);
    for (const p of w.path) { const q = toScreen(p.x + 0.5, p.y + 0.5); ctx.lineTo(q.x, q.y); }
    ctx.stroke();
  }
  ctx.setLineDash([]);

  // Ouvriers
  const r = Math.max(4, ts * 0.33);
  for (const w of game.workers) {
    const s = toScreen(w.x, w.y);
    if (selected.has(w)) {
      ctx.strokeStyle = '#fff'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(s.x, s.y, r + 3, 0, Math.PI * 2); ctx.stroke();
    }
    ctx.fillStyle = JOB_COLORS[w.card.metier.id] || '#fff';
    ctx.beginPath(); ctx.arc(s.x, s.y, r, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = '#000a'; ctx.lineWidth = 1; ctx.stroke();
    if (ts >= 12) {
      ctx.fillStyle = '#111'; ctx.font = `bold ${Math.round(r * 1.1)}px system-ui`;
      ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText(w.card.metier.nom[0], s.x, s.y + 1);
    }
    const cap = game.carryCapacity(w.card);
    if (w.carry > 0) {
      ctx.fillStyle = '#000a'; ctx.fillRect(s.x - r, s.y - r - 7, r * 2, 4);
      ctx.fillStyle = w.carryType === 'bois' ? '#c98b4a' : '#cfd3da';
      ctx.fillRect(s.x - r, s.y - r - 7, (r * 2 * w.carry) / cap, 4);
    }
    if (w.pauseLeft > 0) label('z', s.x + r, s.y - r);
    else if (!w.task && !w.path.length) label('?', s.x + r, s.y - r);
  }

  // Rectangle de sélection
  if (drag) {
    ctx.strokeStyle = '#e9b949'; ctx.fillStyle = '#e9b94922'; ctx.lineWidth = 1;
    const x = Math.min(drag.start.x, drag.end.x), y = Math.min(drag.start.y, drag.end.y);
    const w = Math.abs(drag.end.x - drag.start.x), h = Math.abs(drag.end.y - drag.start.y);
    ctx.fillRect(x, y, w, h); ctx.strokeRect(x, y, w, h);
  }

  // Case survolée
  if (mouse) {
    const w = toWorld(mouse.x, mouse.y);
    const tx = Math.floor(w.x), ty = Math.floor(w.y);
    if (map.inBounds(tx, ty)) {
      const s = toScreen(tx, ty);
      ctx.strokeStyle = '#ffffffcc'; ctx.lineWidth = 1.5; ctx.strokeRect(s.x, s.y, ts, ts);
    }
  }
}

function label(text, x, y) {
  ctx.font = 'bold 12px system-ui';
  ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.lineWidth = 3; ctx.strokeStyle = '#000c'; ctx.strokeText(text, x, y);
  ctx.fillStyle = '#fff'; ctx.fillText(text, x, y);
}

// --- Interface HTML -------------------------------------------------------

const $ = (id) => document.getElementById(id);
const fmtTime = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;

function traitChips(card) {
  return game.traitDefs(card).map((t) =>
    `<span class="trait ${game.isPositive(t.id) ? 'pos' : 'neg'}" title="${t.texte || describeEffect(t.effet)}">${t.nom}</span>`).join('');
}

function describeEffect(effet) {
  return Object.entries(effet).map(([k, v]) => (k === 'salaire' ? `salaire ${v > 0 ? '+' : ''}${v}` : `${k} ×${v}`)).join(', ');
}

let handVersion = -1;
function renderHand() {
  if (handVersion === game.version) return;
  handVersion = game.version;
  const el = $('hand');
  if (!game.hand.length) { el.innerHTML = '<div class="empty-hand">Main vide — la nuit tombe.</div>'; return; }
  el.innerHTML = game.hand.map((card) => {
    const sal = game.salary(card);
    const btn = card.deployed
      ? '<button disabled>Sur le terrain</button>'
      : `<button data-deploy="${card.id}" ${game.money < sal ? 'disabled' : ''}>Déployer (${sal} 💰)</button>`;
    return `<div class="card ${card.deployed ? 'deployed' : ''}" data-card="${card.id}">
      <div class="top"><span class="name">${card.nom}</span><span class="lvl">Niv. ${card.niveau}</span></div>
      <div class="job">${card.metier.nom}</div>
      <div class="traits">${traitChips(card) || '<span class="muted" style="font-size:11px">Aucun trait</span>'}</div>
      ${btn}
    </div>`;
  }).join('');
}

$('hand').addEventListener('click', (e) => {
  const deployId = e.target.closest('[data-deploy]')?.dataset.deploy;
  if (deployId) {
    const card = game.hand.find((c) => c.id === Number(deployId));
    if (game.deploy(card)) { selected = new Set([game.workerOf(card)]); renderInfo(); }
    return;
  }
  const cardEl = e.target.closest('.card.deployed');
  if (cardEl) {
    const w = game.workerOf(game.hand.find((c) => c.id === Number(cardEl.dataset.card)));
    if (w) {
      selected = new Set([w]);
      cam.x = w.x - viewW / cam.ts / 2; cam.y = w.y - viewH / cam.ts / 2;
      renderInfo();
    }
  }
});

function taskText(w) {
  if (w.pauseLeft > 0) return 'En pause';
  if (!w.task) return w.path.length ? 'Se déplace' : 'Inactif';
  const res = w.task.res;
  return { toResource: `Va extraire ${RES_ICON[res]}`, working: `Extrait ${RES_ICON[res]}`, toDepot: 'Rapporte au camp' }[w.task.phase];
}

function renderInfo() {
  const el = $('info');
  const list = game.workers.filter((w) => selected.has(w));
  if (!list.length) {
    el.innerHTML = `<h3>Aucune sélection</h3>
      <p class="muted">Déployez un ouvrier depuis votre main, puis clic droit sur une forêt ou une roche.</p>
      <hr><div class="row">Graine de la carte <b class="mono">${game.seed}</b></div>
      <div class="row">Deck <b>${game.deck.length}</b></div>
      <div class="row">Défausse <b>${game.discard.length}</b></div>`;
    return;
  }
  if (list.length > 1) {
    el.innerHTML = `<h3>${list.length} ouvriers</h3>` + list.map((w) =>
      `<div class="row">${w.card.nom} <b>${taskText(w)}</b></div>`).join('');
    return;
  }
  const w = list[0], c = w.card;
  const eff = (k) => game.efficiency(c, k).toFixed(2);
  el.innerHTML = `<h3>${c.nom}</h3>
    <div class="job" style="color:var(--accent)">${c.metier.nom} · Niv. ${c.niveau}</div>
    <div class="traits" style="margin:6px 0">${traitChips(c)}</div>
    <div class="row">Tâche <b>${taskText(w)}</b></div>
    <div class="row">Charge <b>${w.carry.toFixed(1)} / ${game.carryCapacity(c)}</b></div>
    <hr>
    <div class="row">Vitesse <b>${game.speed(c).toFixed(2)} case/s</b></div>
    <div class="row">Bois <b>×${eff('extraire_bois')}</b></div>
    <div class="row">Pierre <b>×${eff('extraire_pierre')}</b></div>
    <div class="row">Salaire <b>${game.salary(c)} 💰</b></div>
    <div class="row">Jours travaillés <b>${c.joursTravailles}</b></div>`;
}

function renderHud() {
  $('day').textContent = `Jour ${game.day}`;
  $('timer').textContent = fmtTime(Math.max(0, game.dayLength - game.time));
  $('timefill').style.width = `${(100 * game.time) / game.dayLength}%`;
  $('money').textContent = Math.floor(game.money);
  for (const r of ['bois', 'pierre', 'or']) $(r).textContent = Math.floor(game.stock[r]);
  $('pile').textContent = `${game.deck.length} / ${game.discard.length}`;

  const now = performance.now();
  game.messages = game.messages.filter((m) => now - m.at < 4000).slice(-3);
  $('toasts').innerHTML = game.messages.map((m) => `<div class="toast">${m.text}</div>`).join('');

  let status = '';
  if (mouse) {
    const w = toWorld(mouse.x, mouse.y);
    const tx = Math.floor(w.x), ty = Math.floor(w.y);
    if (game.map.inBounds(tx, ty)) {
      const t = game.map.get(tx, ty);
      const res = game.map.defs[t].extractible;
      status = game.map.inCamp(tx, ty) ? 'Camp de base (dépôt des ressources)' : TERRAIN_NOMS[t];
      if (res === 'or') status += " — nécessite une mine (bientôt)";
      else if (res) status += ` — clic droit : extraire ${RES_ICON[res]}`;
      else if (!game.map.defs[t].franchissable) status += ' — infranchissable';
    }
  }
  $('status').textContent = status;

  const night = $('night');
  if (game.phase === 'night' && game.nightReport) {
    if (night.hidden) {
      const r = game.nightReport;
      $('night-title').textContent = `Nuit du jour ${r.day}`;
      $('night-body').innerHTML = `
        <p>${r.deployed} ouvrier(s) déployé(s) aujourd'hui.</p>
        <p>Ramené au camp : 🪵 ${Math.floor(r.stats.bois)} · 🪨 ${Math.floor(r.stats.pierre)}</p>
        ${r.levelUps.length ? `<p>Montées de niveau :</p><ul>${r.levelUps.map((c) => `<li>${c.nom} (${c.metier.nom}) → niveau ${c.niveau}</li>`).join('')}</ul>
          <p class="muted">Le choix des améliorations arrivera dans un prochain prototype.</p>` : ''}
        <p class="muted">Marchés, contrats et salaires de nuit : prochaines étapes.</p>`;
      night.hidden = false;
    }
  } else {
    night.hidden = true;
  }
}

// --- Boucle principale ----------------------------------------------------

let last = performance.now();
let acc = 0;
let infoClock = 0;
function frame(now) {
  const dt = Math.min(0.1, (now - last) / 1000);
  last = now;

  const panSpeed = 20 / cam.ts * 30 * dt;
  if (keys.has('arrowleft') || keys.has('q') || keys.has('a')) cam.x -= panSpeed;
  if (keys.has('arrowright') || keys.has('d')) cam.x += panSpeed;
  if (keys.has('arrowup') || keys.has('z') || keys.has('w')) cam.y -= panSpeed;
  if (keys.has('arrowdown') || keys.has('s')) cam.y += panSpeed;

  acc += dt * speed;
  while (acc >= TICK) { game.tick(TICK); acc -= TICK; }
  // Un ouvrier qui disparaît (fin de journée) ne doit pas rester sélectionné.
  for (const w of selected) if (!game.workers.includes(w)) selected.delete(w);

  draw();
  renderHud();
  renderHand();
  infoClock += dt;
  if (infoClock > 0.25) { infoClock = 0; renderInfo(); }
  requestAnimationFrame(frame);
}
renderInfo();
requestAnimationFrame(frame);
