// A* sur grille 8 directions. Le coût d'une case dépend du terrain et des routes (×2 de vitesse).

const DIRS = [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]];

class MinHeap {
  constructor() { this.items = []; }
  get size() { return this.items.length; }
  push(id, prio) {
    const a = this.items;
    a.push([prio, id]);
    let i = a.length - 1;
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (a[p][0] <= a[i][0]) break;
      [a[p], a[i]] = [a[i], a[p]];
      i = p;
    }
  }
  pop() {
    const a = this.items;
    const top = a[0];
    const last = a.pop();
    if (a.length) {
      a[0] = last;
      let i = 0;
      for (;;) {
        const l = 2 * i + 1, r = l + 1;
        let m = i;
        if (l < a.length && a[l][0] < a[m][0]) m = l;
        if (r < a.length && a[r][0] < a[m][0]) m = r;
        if (m === i) break;
        [a[m], a[i]] = [a[i], a[m]];
        i = m;
      }
    }
    return top[1];
  }
}

export function findPath(map, sx, sy, tx, ty) {
  if (!map.passable(tx, ty)) return null;
  if (sx === tx && sy === ty) return [];
  const W = map.w, N = map.w * map.h;
  const maxSpeed = map.roadMult;
  const g = new Float32Array(N).fill(Infinity);
  const came = new Int32Array(N).fill(-1);
  const closed = new Uint8Array(N);
  const start = sy * W + sx, goal = ty * W + tx;
  const heur = (i) => {
    const dx = Math.abs((i % W) - tx), dy = Math.abs(((i / W) | 0) - ty);
    return (Math.max(dx, dy) + (Math.SQRT2 - 1) * Math.min(dx, dy)) / maxSpeed;
  };
  const heap = new MinHeap();
  g[start] = 0;
  heap.push(start, heur(start));
  while (heap.size) {
    const cur = heap.pop();
    if (closed[cur]) continue;
    if (cur === goal) break;
    closed[cur] = 1;
    const cx = cur % W, cy = (cur / W) | 0;
    const curSpeed = map.moveSpeed(cx, cy);
    for (const [dx, dy] of DIRS) {
      const nx = cx + dx, ny = cy + dy;
      if (!map.passable(nx, ny)) continue;
      const diag = dx !== 0 && dy !== 0;
      if (diag && (!map.passable(cx + dx, cy) || !map.passable(cx, cy + dy))) continue;
      const ni = ny * W + nx;
      if (closed[ni]) continue;
      const cost = (diag ? Math.SQRT2 : 1) / ((curSpeed + map.moveSpeed(nx, ny)) / 2);
      const ng = g[cur] + cost;
      if (ng < g[ni]) {
        g[ni] = ng;
        came[ni] = cur;
        heap.push(ni, ng + heur(ni));
      }
    }
  }
  if (came[goal] === -1) return null;
  const path = [];
  for (let i = goal; i !== start; i = came[i]) path.push({ x: i % W, y: (i / W) | 0 });
  return path.reverse();
}
