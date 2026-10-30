// Génération de carte déterministe à partir d'une graine (identique pour tous les joueurs).

export function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function valueNoise(rng, w, h, cell) {
  const gw = Math.ceil(w / cell) + 2;
  const gh = Math.ceil(h / cell) + 2;
  const g = new Float32Array(gw * gh);
  for (let i = 0; i < g.length; i++) g[i] = rng();
  const s = (t) => t * t * (3 - 2 * t);
  return (x, y) => {
    const fx = x / cell, fy = y / cell;
    const ix = Math.floor(fx), iy = Math.floor(fy);
    const tx = s(fx - ix), ty = s(fy - iy);
    const a = g[iy * gw + ix], b = g[iy * gw + ix + 1];
    const c = g[(iy + 1) * gw + ix], d = g[(iy + 1) * gw + ix + 1];
    return a + (b - a) * tx + (c - a) * ty + (a - b - c + d) * tx * ty;
  };
}

function fbm(rng, w, h) {
  const layers = [[16, 0.6], [8, 0.3], [4, 0.1]].map(([cell, wgt]) => [valueNoise(rng, w, h, cell), wgt]);
  return (x, y) => layers.reduce((sum, [n, wgt]) => sum + n(x, y) * wgt, 0);
}

export function generateMap(buildings, seed) {
  const [w, h] = buildings.carte.taille;
  const rep = buildings.carte.repartition_terrain;
  const defs = buildings.terrains;
  const rng = mulberry32(seed);
  const elevation = fbm(rng, w, h);
  const moisture = fbm(rng, w, h);
  const n = w * h;
  const tiles = new Array(n).fill('Prairie');

  // Répartition par quantiles pour respecter les proportions du JSON.
  const elev = new Float32Array(n);
  const moist = new Float32Array(n);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    elev[y * w + x] = elevation(x, y);
    moist[y * w + x] = moisture(x, y);
  }
  const byElev = [...Array(n).keys()].sort((a, b) => elev[a] - elev[b]);
  const nEau = Math.round(rep.Eau * n);
  const nMont = Math.round(rep.Montagne * n);
  const nRoche = Math.round(rep.Roche * n);
  byElev.slice(0, nEau).forEach((i) => (tiles[i] = 'Eau'));
  byElev.slice(n - nMont).forEach((i) => (tiles[i] = 'Montagne'));
  byElev.slice(n - nMont - nRoche, n - nMont).forEach((i) => (tiles[i] = 'Roche'));
  const rest = byElev.slice(nEau, n - nMont - nRoche).sort((a, b) => moist[a] - moist[b]);
  const nSable = Math.round(rep.Sable * n);
  const nForet = Math.round(rep.Foret * n);
  rest.slice(0, nSable).forEach((i) => (tiles[i] = 'Sable'));
  rest.slice(rest.length - nForet).forEach((i) => (tiles[i] = 'Foret'));

  const map = {
    w, h, tiles, defs,
    road: new Uint8Array(n),
    roadMult: buildings.carte.vitesse_route_mult,
    inBounds: (x, y) => x >= 0 && y >= 0 && x < w && y < h,
    get: (x, y) => tiles[y * w + x],
    passable: (x, y) => map.inBounds(x, y) && defs[tiles[y * w + x]].franchissable,
    moveSpeed: (x, y) => defs[tiles[y * w + x]].vitesse * (map.road[y * w + x] ? map.roadMult : 1),
  };

  // Camp de base 3x3 : la zone franchissable la plus proche du centre.
  const blocked = (x, y) => !map.inBounds(x, y) || ['Eau', 'Montagne'].includes(map.get(x, y));
  let camp = null;
  for (let r = 0; r < w / 2 && !camp; r++) {
    for (let dy = -r; dy <= r && !camp; dy++) for (let dx = -r; dx <= r && !camp; dx++) {
      const cx = Math.floor(w / 2) - 1 + dx, cy = Math.floor(h / 2) - 1 + dy;
      let ok = true;
      for (let j = 0; j < 3 && ok; j++) for (let i = 0; i < 3 && ok; i++) if (blocked(cx + i, cy + j)) ok = false;
      if (ok) camp = { x: cx, y: cy, w: 3, h: 3 };
    }
  }
  for (let j = 0; j < 3; j++) for (let i = 0; i < 3; i++) tiles[(camp.y + j) * w + camp.x + i] = 'Prairie';
  map.camp = camp;
  map.inCamp = (x, y) => x >= camp.x && y >= camp.y && x < camp.x + camp.w && y < camp.y + camp.h;

  // Cases atteignables depuis le camp (pour placer la mine d'or au bon endroit).
  const reach = new Uint8Array(n);
  const queue = [camp.y * w + camp.x];
  reach[queue[0]] = 1;
  while (queue.length) {
    const i = queue.pop();
    const x = i % w, y = (i / w) | 0;
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const nx = x + dx, ny = y + dy;
      if (map.passable(nx, ny) && !reach[ny * w + nx]) { reach[ny * w + nx] = 1; queue.push(ny * w + nx); }
    }
  }
  map.reachable = reach;

  // Une seule mine d'or, sur une roche atteignable, ni trop près ni trop loin du camp.
  const ccx = camp.x + 1, ccy = camp.y + 1;
  const rocks = [];
  for (let i = 0; i < n; i++) if (tiles[i] === 'Roche' && reach[i]) rocks.push(i);
  const far = rocks.filter((i) => {
    const d = Math.max(Math.abs((i % w) - ccx), Math.abs(((i / w) | 0) - ccy));
    return d >= 14 && d <= 28;
  });
  const pool = far.length ? far : rocks;
  const gold = pool[Math.floor(rng() * pool.length)];
  tiles[gold] = 'MineOr';
  map.gold = { x: gold % w, y: (gold / w) | 0 };

  return map;
}
