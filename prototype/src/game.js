// Simulation : deck, déploiement, ordres, déplacement, extraction et portage.
// Elle avance par ticks fixes, indépendamment de l'affichage.

import { mulberry32, generateMap } from './map.js';
import { findPath } from './pathfinding.js';

export const TICK = 0.1;

const PRENOMS = ['Léa', 'Hugo', 'Jade', 'Louis', 'Emma', 'Nathan', 'Inès', 'Gabin', 'Chloé', 'Tom', 'Lina', 'Jules',
  'Manon', 'Noah', 'Zoé', 'Adam', 'Rose', 'Paul', 'Alice', 'Sacha', 'Lou', 'Malo', 'Nina', 'Théo', 'Elsa', 'Victor'];

export class Game {
  constructor(data, seed) {
    this.data = data;
    this.seed = seed;
    this.rng = mulberry32(seed ^ 0x9e3779b9);
    this.map = generateMap(data.buildings, seed);
    this.money = data.buildings.partie.argent_depart;
    this.stock = { bois: 0, pierre: 0, or: 0 };
    this.day = 1;
    this.time = 0;
    this.dayLength = data.buildings.partie.duree_jour_s;
    this.phase = 'day';
    this.deck = [];
    this.discard = [];
    this.hand = [];
    this.workers = [];
    this.messages = [];
    this.dayStats = { bois: 0, pierre: 0, or: 0 };
    this.nightReport = null;
    this.nextId = 1;
    this.version = 0; // incrémenté à chaque changement de la main (pour rafraîchir l'interface)

    const regles = data.workers.regles;
    for (let i = 0; i < regles.taille_deck_initial; i++) this.deck.push(this.makeCard('peu_qualifie'));
    this.shuffle(this.deck);
    this.drawHand();
  }

  // --- Cartes ouvriers ---------------------------------------------------

  pick(list) { return list[Math.floor(this.rng() * list.length)]; }

  shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(this.rng() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
  }

  pickCount(dist) {
    let r = this.rng();
    for (const [k, p] of Object.entries(dist)) { if ((r -= p) < 0) return Number(k); }
    return 0;
  }

  makeCard(categorie) {
    const W = this.data.workers;
    const metier = this.pick(W.metiers.filter((m) => m.categorie === categorie));
    const excluded = (id, chosen) => W.generation_traits.exclusions.some(
      ([a, b]) => (a === id && chosen.includes(b)) || (b === id && chosen.includes(a)));
    const traits = [];
    const draw = (pool, count) => {
      for (let i = 0; i < count; i++) {
        const options = pool.filter((t) => !traits.includes(t.id) && !excluded(t.id, traits));
        if (options.length) traits.push(this.pick(options).id);
      }
    };
    draw(W.traits_positifs, this.pickCount(W.generation_traits.nb_positifs));
    draw(W.traits_negatifs, this.pickCount(W.generation_traits.nb_negatifs));
    return {
      id: this.nextId++,
      nom: this.pick(PRENOMS),
      metier,
      traits,
      niveau: 1,
      joursTravailles: 0,
      deployed: false,
    };
  }

  traitDefs(card) {
    const W = this.data.workers;
    return card.traits.map((id) => W.traits_positifs.find((t) => t.id === id) || W.traits_negatifs.find((t) => t.id === id));
  }

  isPositive(traitId) { return this.data.workers.traits_positifs.some((t) => t.id === traitId); }

  salary(card) {
    return Math.max(0, card.metier.salaire + this.traitDefs(card).reduce((s, t) => s + (t.effet.salaire || 0), 0));
  }

  speed(card) {
    return card.metier.vitesse * this.traitDefs(card).reduce((m, t) => m * (t.effet.vitesse || 1), 1);
  }

  efficiency(card, task) {
    const eff = card.metier.efficacite;
    let base = eff[task] ?? eff.defaut;
    if (card.traits.includes('polyvalent') && eff[task] === undefined) base = Math.max(base, 1.2);
    for (const t of this.traitDefs(card)) {
      base *= (t.effet.defaut || 1) * (t.effet[task] || 1);
      if (task.startsWith('construire') && task !== 'construire') base *= t.effet.construire || 1;
    }
    return base;
  }

  carryCapacity(card) {
    return this.data.buildings.extraction.capacite_portage + (card.metier.capacite_portage || 0);
  }

  drawHand() {
    const size = this.data.workers.regles.taille_main;
    while (this.hand.length < size) {
      if (!this.deck.length) {
        if (!this.discard.length) break;
        this.deck = this.discard;
        this.discard = [];
        this.shuffle(this.deck);
      }
      this.hand.push(this.deck.pop());
    }
    this.version++;
  }

  // --- Déploiement et ordres ---------------------------------------------

  say(text) { this.messages.push({ text, at: performance.now() }); }

  deploy(card) {
    if (this.phase !== 'day' || card.deployed) return false;
    const cost = this.salary(card);
    if (this.money < cost) { this.say(`Pas assez d'argent pour payer ${card.nom} (${cost} 💰).`); return false; }
    this.money -= cost;
    card.deployed = true;
    const c = this.map.camp;
    this.workers.push({
      card,
      x: c.x + 1.5, y: c.y + 1.5,
      path: [],
      task: null,
      carry: 0, carryType: null,
      minuteClock: 0, pauseLeft: 0,
    });
    this.version++;
    return true;
  }

  workerOf(card) { return this.workers.find((w) => w.card === card); }

  tileOf(w) { return { x: Math.floor(w.x), y: Math.floor(w.y) }; }

  setPath(w, tx, ty) {
    const from = this.tileOf(w);
    const path = findPath(this.map, from.x, from.y, tx, ty);
    if (!path) { this.say(`${w.card.nom} ne trouve pas de chemin.`); w.task = null; w.path = []; return false; }
    w.path = path;
    return true;
  }

  goToDepot(w) {
    const c = this.map.camp;
    w.task.phase = 'toDepot';
    this.setPath(w, c.x + 1, c.y + 1);
  }

  order(workers, tx, ty) {
    if (this.phase !== 'day' || !this.map.inBounds(tx, ty)) return;
    const terrain = this.map.get(tx, ty);
    const res = this.map.defs[terrain].extractible;
    for (const w of workers) {
      w.pauseLeft = 0;
      if (res) {
        if (res === 'or') { this.say("La mine d'or doit d'abord être construite (pas encore dans ce prototype)."); continue; }
        if (w.card.traits.includes('col_blanc')) { this.say(`${w.card.nom} est un col blanc : il refuse le travail manuel.`); continue; }
        w.task = { type: 'extract', res, tx, ty, phase: 'toResource' };
        if (w.carry > 0 && w.carryType !== res) this.goToDepot(w);
        else this.setPath(w, tx, ty);
      } else if (this.map.passable(tx, ty)) {
        w.task = null;
        this.setPath(w, tx, ty);
      } else {
        this.say('Case infranchissable.');
        return;
      }
    }
  }

  // --- Simulation --------------------------------------------------------

  tick(dt) {
    if (this.phase !== 'day') return;
    this.time += dt;
    for (const w of this.workers) this.updateWorker(w, dt);
    if (this.time >= this.dayLength) this.endDay();
  }

  move(w, dt) {
    let budget = dt;
    while (w.path.length && budget > 0) {
      const t = this.tileOf(w);
      const speed = this.speed(w.card) * this.map.moveSpeed(t.x, t.y);
      const next = w.path[0];
      const dx = next.x + 0.5 - w.x, dy = next.y + 0.5 - w.y;
      const dist = Math.hypot(dx, dy);
      const step = speed * budget;
      if (step >= dist) {
        w.x = next.x + 0.5; w.y = next.y + 0.5;
        w.path.shift();
        budget -= dist / speed;
      } else {
        w.x += (dx / dist) * step; w.y += (dy / dist) * step;
        budget = 0;
      }
    }
  }

  updateWorker(w, dt) {
    if (w.pauseLeft > 0) { w.pauseLeft -= dt; return; }
    if (w.path.length) { this.move(w, dt); return; }
    const task = w.task;
    if (!task) return;

    if (task.phase === 'toResource') {
      task.phase = 'working';
    } else if (task.phase === 'working') {
      const key = `extraire_${task.res}`;
      const perMinute = this.data.buildings.extraction[task.res] * this.efficiency(w.card, key);
      w.carryType = task.res;
      w.carry = Math.min(this.carryCapacity(w.card), w.carry + (perMinute / 60) * dt);
      this.workTraits(w, dt);
      if (w.carry >= this.carryCapacity(w.card) && w.task) this.goToDepot(w);
    } else if (task.phase === 'toDepot') {
      const t = this.tileOf(w);
      if (this.map.inCamp(t.x, t.y)) {
        if (w.carry > 0) {
          this.stock[w.carryType] += w.carry;
          this.dayStats[w.carryType] += w.carry;
        }
        w.carry = 0;
        task.phase = 'toResource';
        this.setPath(w, task.tx, task.ty);
      }
    }
  }

  // Traits qui interrompent le travail (Paresseux, Distrait) : vérifiés chaque minute travaillée.
  workTraits(w, dt) {
    w.minuteClock += dt;
    if (w.minuteClock < 60) return;
    w.minuteClock -= 60;
    if (w.card.traits.includes('paresseux')) { w.pauseLeft = 15; this.say(`${w.card.nom} fait une pause (paresseux).`); }
    if (w.card.traits.includes('distrait') && this.rng() < 0.1) {
      w.task = null;
      this.say(`${w.card.nom} a oublié ce qu'il faisait (distrait).`);
    }
  }

  // --- Fin de journée ----------------------------------------------------

  endDay() {
    if (this.phase !== 'day') return;
    this.phase = 'night';
    const regles = this.data.workers.regles;
    const levelUps = [];
    for (const w of this.workers) {
      const card = w.card;
      card.joursTravailles++;
      if (card.joursTravailles % regles.xp_jours_par_niveau === 0 && card.niveau < regles.niveau_max) {
        card.niveau++;
        levelUps.push(card);
      }
      card.deployed = false;
    }
    this.nightReport = { day: this.day, stats: { ...this.dayStats }, levelUps, deployed: this.workers.length };
    this.workers = [];
    this.discard.push(...this.hand);
    this.hand = [];
    this.version++;
  }

  startNextDay() {
    if (this.phase !== 'night') return;
    this.day++;
    this.time = 0;
    this.dayStats = { bois: 0, pierre: 0, or: 0 };
    this.phase = 'day';
    this.nightReport = null;
    this.drawHand();
  }

  // Outil de test : remplace le Marchand tant qu'il n'existe pas dans le prototype.
  sellStock() {
    const conv = this.data.buildings.conversion;
    let gain = 0;
    for (const res of ['bois', 'pierre', 'or']) {
      const units = Math.floor(this.stock[res]);
      gain += units * conv[res];
      this.stock[res] -= units;
    }
    gain = Math.floor(gain);
    this.money += gain;
    this.say(`Stock vendu : +${gain} 💰`);
    this.version++;
  }
}
