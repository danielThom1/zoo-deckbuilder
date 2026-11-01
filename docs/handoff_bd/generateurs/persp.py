"""Paysages en semi-perspective (vue oblique 3/4) : plateaux à falaises, berges visibles,
objets dressés triés en profondeur, végétation dessinée variée. Palette « Néo ligne claire »."""
import math, os, sys
import numpy as np
from scipy import ndimage as nd
from skimage import measure

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ICI)
import monde  # sprites (SP, sprite, serre)
from monde import SP, serre

W, H, S = 1600, 900, 4
GW, GH = W // S, H // S
INK = '#14202B'
yy, xx = np.mgrid[0:GH, 0:GW] * S + S / 2

# sprites supplémentaires
SP.update({
    'ours': ('an', serre('an', 125, 283, 242, 388)), 'loup': ('an', serre('an', 468, 292, 586, 392)), 'cerf': ('an', serre('an', 8, 503, 122, 612)),
    'biche': ('an', serre('an', 120, 503, 222, 612)), 'elephant': ('an', serre('an', 1058, 38, 1168, 140)), 'elephanteau': ('an', serre('an', 1398, 50, 1468, 138)),
    'rhino': ('an', serre('an', 1166, 60, 1260, 140)), 'lion': ('an', serre('an', 718, 30, 802, 144)), 'lionne': ('an', serre('an', 796, 70, 918, 144)),
    'hippo': ('an', serre('an', 1276, 726, 1434, 820)), 'hippo_p': ('an', serre('an', 1434, 750, 1530, 820)), 'croco': ('an', serre('an', 10, 826, 264, 894)),
    'flamant': ('an', serre('an', 253, 726, 344, 828)), 'grue': ('an', serre('an', 1118, 905, 1205, 1012)), 'loutre': ('an', serre('an', 1062, 732, 1168, 820)),
    'antilope': ('an', serre('an', 490, 503, 580, 612)), 'chameau': ('an', serre('an', 768, 630, 862, 722)), 'ane': ('an', serre('an', 1096, 630, 1196, 718)),
    'guepard': ('an', serre('an', 462, 172, 592, 266)), 'gorille': ('an', serre('an', 470, 400, 578, 500)), 'panda_roux': ('an', serre('an', 1368, 300, 1454, 386)),
    'abri': ('s1', (1401, 535, 129, 96)), 'restaurant': ('s1', (960, 18, 151, 143)), 'atelier': ('s1', (1118, 32, 140, 134)), 'chantier2': ('s1', (1371, 188, 159, 143)),
    'tortue': ('an', serre('an', 945, 822, 1150, 898)), 'paon': ('an', serre('an', 928, 905, 1090, 1015)),
})

def bruit(sigma, seed):
    r = np.random.default_rng(seed).standard_normal((GH, GW))
    f = nd.gaussian_filter(r, sigma)
    return (f - f.mean()) / f.std()

def ell(cx, cy, rx, ry, seed=0, amp=0.18):
    return ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 + (bruit(4, seed) * amp if amp else 0) < 1

def dist_poly(pts):
    d = np.full((GH, GW), 1e9)
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        vx, vy = x1 - x0, y1 - y0
        L = vx * vx + vy * vy
        if L < 1e-9: continue
        t = np.clip(((xx - x0) * vx + (yy - y0) * vy) / L, 0, 1)
        d = np.minimum(d, np.hypot(xx - (x0 + t * vx), yy - (y0 + t * vy)))
    return d

def lisse(pts, n=12):
    """Courbe de Catmull-Rom passant par les points."""
    p = np.array(pts, float)
    p = np.vstack([p[:1], p, p[-1:]])
    out = []
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[i - 1], p[i], p[i + 1], p[i + 2]
        for t in np.linspace(0, 1, n, endpoint=False):
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(p[-2])
    return np.array(out)

def chaikin(p, it=2):
    for _ in range(it):
        q = p[:-1] * 0.75 + p[1:] * 0.25; r = p[:-1] * 0.25 + p[1:] * 0.75
        p = np.empty((len(q) * 2, 2)); p[0::2] = q; p[1::2] = r; p = np.vstack([p, p[:1]])
    return p

def contours(mask, sigma=1.1):
    f = np.pad(nd.gaussian_filter(mask.astype(float), sigma), 2)
    out = []
    for c in measure.find_contours(f, 0.5):
        if len(c) < 6: continue
        pts = (c[:, ::-1] - 2) * S + S / 2
        pts = pts[::2]
        if len(pts) < 4: continue
        pts = chaikin(np.vstack([pts, pts[:1]]), 2)
        out.append('M' + ' L'.join(f'{x:.1f},{y:.1f}' for x, y in pts) + 'Z')
    return ' '.join(out)

def semis(mask, ecart, seed, n_max=3000):
    r = np.random.default_rng(seed); pts = []; cell = ecart / math.sqrt(2); grille = {}
    cand = np.argwhere(mask)
    if len(cand) == 0: return pts
    essais = 0
    while len(pts) < n_max and essais < n_max * 10:
        essais += 1
        gy, gx = cand[r.integers(len(cand))]
        x, y = gx * S + r.uniform(0, S), gy * S + r.uniform(0, S)
        ci, cj = int(x // cell), int(y // cell); ok = True
        for di in (-2, -1, 0, 1, 2):
            for dj in (-2, -1, 0, 1, 2):
                for (px, py) in grille.get((ci + di, cj + dj), ()):
                    if (px - x) ** 2 + (py - y) ** 2 < ecart * ecart: ok = False; break
                if not ok: break
            if not ok: break
        if ok: pts.append((x, y)); grille.setdefault((ci, cj), []).append((x, y))
    return pts

def m_at(mask, x, y):
    gx, gy = int(x // S), int(y // S)
    return 0 <= gx < GW and 0 <= gy < GH and bool(mask[gy, gx])

def f2(v): return f'{v:.1f}'

# ================================================================== dessins de végétation
def bosse(cx, cy, r, n, rng, ry=None):
    """Contour festonné (feuillage)."""
    ry = ry or r
    pts = []
    for i in range(n):
        a = i / n * math.tau + rng.uniform(-0.12, 0.12); k = rng.uniform(0.86, 1.06)
        pts.append((cx + math.cos(a) * r * k, cy + math.sin(a) * ry * k))
    d = f'M{f2(pts[0][0])},{f2(pts[0][1])}'
    for i in range(n):
        p, q = pts[i], pts[(i + 1) % n]
        mx, my = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2
        cx2 = mx + (mx - cx) * 0.42; cy2 = my + (my - cy) * 0.42 * (ry / r if r else 1)
        d += f' Q{f2(cx2)},{f2(cy2)} {f2(q[0])},{f2(q[1])}'
    return d + 'Z'

PAL = {
    'chene': ('#3E7A37', '#5A9A45', '#8DC266'), 'hetre': ('#4C8A3C', '#6CAA4E', '#A6D27A'), 'sombre': ('#2F6232', '#477E3A', '#76AE5A'),
    'automne': ('#B4532A', '#DB8434', '#F2BE58'), 'or': ('#B8862A', '#DDB040', '#F4DE7A'), 'bouleau': ('#6E9A34', '#98BE4A', '#CFE27E'),
    'acacia': ('#5E7A2E', '#7E9A3C', '#B2C766'), 'saule': ('#4F8A3E', '#79AE52', '#B4D98A'), 'olive': ('#5B6E3A', '#7C9050', '#AFC07A'),
}

def ombre_sol(x, y, rx, ry, op=0.22):
    return f'<ellipse cx="{f2(x + rx * 0.35)}" cy="{f2(y)}" rx="{f2(rx)}" ry="{f2(ry)}" fill="{INK}" opacity="{op}"/>'

def feuillu(x, y, r, pal, seed, tronc=1.0):
    rng = np.random.default_rng(seed); sombre, moyen, clair = PAL[pal]; o = [ombre_sol(x, y, r * 1.2, r * 0.38)]
    th = r * 0.95 * tronc; cy = y - th - r * 0.62
    o.append(f'<path d="M{f2(x - 2.8)},{f2(y)} Q{f2(x - 1.4)},{f2(y - th * 0.5)} {f2(x - 1.8)},{f2(y - th - 2)} L{f2(x + 1.8)},{f2(y - th - 2)} Q{f2(x + 1.3)},{f2(y - th * 0.5)} {f2(x + 3)},{f2(y)} Z" fill="#6A4A2E" stroke="{INK}" stroke-width="1.1"/>')
    o.append(f'<path d="M{f2(x + 1)},{f2(y - 2)} q0.5,{f2(-th * 0.5)} -0.4,{f2(-th)}" stroke="#4A3220" stroke-width="1.1" fill="none"/>')
    # masses de feuillage en dôme
    lobes = [(0, -r * 0.1, r * 0.72)]
    n = int(rng.integers(5, 8))
    for k in range(n):
        a = math.pi + (k + 0.5) / n * math.pi + rng.uniform(-0.2, 0.2)
        d = r * rng.uniform(0.5, 0.7)
        lobes.append((math.cos(a) * d * 1.18, math.sin(a) * d * 0.85, r * rng.uniform(0.42, 0.58)))
    for k in range(2):
        lobes.append(((k - 0.5) * r * 0.9 + rng.uniform(-2, 2), r * 0.32, r * rng.uniform(0.4, 0.5)))
    chemins = [bosse(x + dx, cy + dy, rr, 9, rng) for dx, dy, rr in lobes]
    for d in chemins: o.append(f'<path d="{d}" fill="{sombre}" stroke="{INK}" stroke-width="2.8" stroke-linejoin="round"/>')
    for d in chemins: o.append(f'<path d="{d}" fill="{sombre}"/>')
    ordre = sorted(lobes, key=lambda l: l[1], reverse=True)   # du bas vers le haut : les masses hautes recouvrent
    for dx, dy, rr in ordre:
        px, py = x + dx - rr * 0.12, cy + dy - rr * 0.16
        o.append(f'<path d="{bosse(px, py, rr * 0.8, 8, rng)}" fill="{moyen}"/>')
        # contour interne de la masse (côté bas-droit)
        a0_, a1_ = 0.1, 2.4
        x0, y0 = px + math.cos(a0_) * rr * 0.8, py + math.sin(a0_) * rr * 0.8
        x1, y1 = px + math.cos(a1_) * rr * 0.8, py + math.sin(a1_) * rr * 0.8
        o.append(f'<path d="M{f2(x0)},{f2(y0)} A{f2(rr * 0.8)},{f2(rr * 0.8)} 0 0,1 {f2(x1)},{f2(y1)}" stroke="{INK}" stroke-width="1" fill="none" opacity="0.75"/>')
        o.append(f'<path d="{bosse(px - rr * 0.22, py - rr * 0.26, rr * 0.36, 6, rng)}" fill="{clair}" opacity="0.95"/>')
        for k in range(2):
            a = rng.uniform(0.3, 2.6); dd = rr * rng.uniform(0.3, 0.6)
            qx, qy = px + math.cos(a) * dd, py + math.sin(a) * dd
            o.append(f'<path d="M{f2(qx - 2)},{f2(qy)} q2,2.2 4,0" stroke="{sombre}" stroke-width="1.1" fill="none"/>')
    return ''.join(o)

def conifere(x, y, h, seed, pal=('#21503A', '#2E6A45', '#4E8C5A')):
    rng = np.random.default_rng(seed); sombre, moyen, clair = pal; o = [ombre_sol(x, y, h * 0.32, h * 0.1)]
    o.append(f'<rect x="{f2(x - 1.6)}" y="{f2(y - h * 0.16)}" width="3.2" height="{f2(h * 0.16)}" fill="#5E4028" stroke="{INK}" stroke-width="1"/>')
    n = rng.integers(5, 7); etages = []
    for i in range(n):
        t = i / (n - 1)
        top = y - h + t * h * 0.66; bas = y - h * 0.62 + t * h * 0.5; w = h * (0.1 + 0.24 * t) * rng.uniform(0.92, 1.08)
        dents = 5 + i
        pts = [(x, top)]
        for k in range(dents + 1):
            u = k / dents
            px = x + w - 2 * w * u; py = bas + (2.4 if k % 2 else -1.2) + abs(u - 0.5) * -3
            pts.append((px, py))
        etages.append(pts)
    ds = ['M' + ' L'.join(f'{f2(a)},{f2(b)}' for a, b in e) + 'Z' for e in etages]
    for d in ds: o.append(f'<path d="{d}" fill="{sombre}" stroke="{INK}" stroke-width="2.4" stroke-linejoin="round"/>')
    for d in ds: o.append(f'<path d="{d}" fill="{sombre}"/>')
    for e in etages:
        g = [p for p in e if p[0] <= x + 0.5]
        g = [e[0]] + [p for p in e[1:] if p[0] < x] + [(x, max(p[1] for p in e) - 1)]
        o.append('<path d="M' + ' L'.join(f'{f2(a)},{f2(b)}' for a, b in g) + f'Z" fill="{moyen}"/>')
        o.append(f'<path d="M{f2(e[0][0] - 1)},{f2(e[0][1] + 3)} l{f2(-(e[1][0] - x) * 0.45)},{f2((e[1][1] - e[0][1]) * 0.55)}" stroke="{clair}" stroke-width="1.3" fill="none" stroke-linecap="round"/>')
    return ''.join(o)

def bouleau(x, y, r, seed):
    o = feuillu(x, y, r * 1.25, 'bouleau', seed, tronc=1.5)
    th = r * 1.25 * 0.95 * 1.5
    o += f'<path d="M{f2(x - 2.2)},{f2(y)} L{f2(x - 1.5)},{f2(y - th * 0.45)} L{f2(x + 1.5)},{f2(y - th * 0.45)} L{f2(x + 2.4)},{f2(y)} Z" fill="#F1EEE4" stroke="{INK}" stroke-width="1.1"/>'
    for k, t in enumerate((0.1, 0.25, 0.38)):
        o += f'<path d="M{f2(x - 1.6)},{f2(y - th * t)} l{2.4 if k % 2 else 1.6},0" stroke="{INK}" stroke-width="1.4"/>'
    return o

def acacia(x, y, r, seed):
    rng = np.random.default_rng(seed); sombre, moyen, clair = PAL['acacia']; o = [ombre_sol(x, y, r * 1.6, r * 0.32, 0.25)]
    th = r * 1.5; cy = y - th - r * 0.15
    o.append(f'<path d="M{f2(x - 2)},{f2(y)} Q{f2(x - 1)},{f2(y - th * 0.5)} {f2(x - r * 0.6)},{f2(cy + 2)} M{f2(x + 1)},{f2(y - th * 0.45)} Q{f2(x + r * 0.3)},{f2(y - th * 0.7)} {f2(x + r * 0.7)},{f2(cy + 2)} M{f2(x)},{f2(y - th * 0.55)} L{f2(x + r * 0.05)},{f2(cy + 2)}" stroke="#5A3E26" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
    o.append(f'<path d="M{f2(x - 2)},{f2(y)} Q{f2(x - 1)},{f2(y - th * 0.5)} {f2(x - r * 0.6)},{f2(cy + 2)} M{f2(x + 1)},{f2(y - th * 0.45)} Q{f2(x + r * 0.3)},{f2(y - th * 0.7)} {f2(x + r * 0.7)},{f2(cy + 2)}" stroke="{INK}" stroke-width="0.8" fill="none" opacity="0.6"/>')
    d = bosse(x, cy, r * 1.7, 14, rng, r * 0.42)
    o.append(f'<path d="{d}" fill="{sombre}" stroke="{INK}" stroke-width="1.6"/>')
    o.append(f'<path d="{bosse(x - r * 0.15, cy - r * 0.12, r * 1.45, 12, rng, r * 0.28)}" fill="{moyen}"/>')
    o.append(f'<path d="{bosse(x - r * 0.45, cy - r * 0.2, r * 0.7, 8, rng, r * 0.14)}" fill="{clair}"/>')
    return ''.join(o)

def baobab(x, y, r, seed):
    rng = np.random.default_rng(seed); o = [ombre_sol(x, y, r * 1.2, r * 0.35, 0.25)]
    w = r * 0.55; th = r * 1.9
    o.append(f'<path d="M{f2(x - w)},{f2(y)} Q{f2(x - w * 1.25)},{f2(y - th * 0.5)} {f2(x - w * 0.45)},{f2(y - th)} L{f2(x + w * 0.45)},{f2(y - th)} Q{f2(x + w * 1.25)},{f2(y - th * 0.5)} {f2(x + w)},{f2(y)} Z" fill="#A8947A" stroke="{INK}" stroke-width="1.5"/>')
    o.append(f'<path d="M{f2(x + w * 0.1)},{f2(y)} Q{f2(x + w * 0.9)},{f2(y - th * 0.5)} {f2(x + w * 0.45)},{f2(y - th)} L{f2(x + w * 0.1)},{f2(y - th)} Z" fill="#857158"/>')
    for k in range(3):
        o.append(f'<path d="M{f2(x - w * 0.6 + k * w * 0.5)},{f2(y - th * 0.85)} l0,{f2(th * 0.4)}" stroke="{INK}" stroke-width="0.8" opacity="0.5"/>')
    for a in (-0.9, -0.35, 0.3, 0.85):
        ex, ey = x + a * r * 1.2, y - th - r * 0.45 - abs(a) * -r * 0.15
        o.append(f'<path d="M{f2(x + a * w * 0.6)},{f2(y - th + 2)} Q{f2(x + a * r * 0.6)},{f2(y - th - r * 0.2)} {f2(ex)},{f2(ey)}" stroke="#7A6650" stroke-width="3" fill="none" stroke-linecap="round"/>')
        o.append(f'<path d="{bosse(ex, ey - 3, r * 0.42, 7, rng, r * 0.26)}" fill="#6E8A3A" stroke="{INK}" stroke-width="1.3"/><path d="{bosse(ex - 2, ey - 5, r * 0.25, 6, rng, r * 0.14)}" fill="#A2BE5E"/>')
    return ''.join(o)

def saule(x, y, r, seed):
    rng = np.random.default_rng(seed); sombre, moyen, clair = PAL['saule']; o = [ombre_sol(x, y, r * 1.2, r * 0.34)]
    th = r * 0.9; cy = y - th - r * 0.7
    o.append(f'<path d="M{f2(x - 2.5)},{f2(y)} Q{f2(x - 1)},{f2(y - th)} {f2(x - 1.5)},{f2(cy)} L{f2(x + 1.5)},{f2(cy)} Q{f2(x + 1)},{f2(y - th)} {f2(x + 2.8)},{f2(y)}Z" fill="#6A4A2E" stroke="{INK}" stroke-width="1.1"/>')
    d = bosse(x, cy, r * 1.15, 11, rng, r * 0.8)
    o.append(f'<path d="{d}" fill="{sombre}" stroke="{INK}" stroke-width="1.8"/>')
    o.append(f'<path d="{bosse(x - r * 0.2, cy - r * 0.2, r * 0.85, 9, rng, r * 0.55)}" fill="{moyen}"/>')
    for k in range(int(r * 1.1)):
        px = x + rng.uniform(-1.05, 1.05) * r; py = cy + rng.uniform(-0.1, 0.6) * r; L = rng.uniform(0.5, 1.0) * r
        c = clair if px < x else sombre
        o.append(f'<path d="M{f2(px)},{f2(py)} q{f2(rng.uniform(-2, 2))},{f2(L * 0.5)} {f2(rng.uniform(-1, 1))},{f2(L)}" stroke="{c}" stroke-width="1.6" fill="none" stroke-linecap="round"/>')
    o.append(f'<path d="M{f2(x - r * 1.05)},{f2(cy + r * 0.3)} q{f2(-2)},{f2(r * 0.5)} 0,{f2(r * 0.9)} M{f2(x + r * 1.05)},{f2(cy + r * 0.3)} q2,{f2(r * 0.5)} 0,{f2(r * 0.9)}" stroke="{INK}" stroke-width="1.2" fill="none"/>')
    return ''.join(o)

def buisson(x, y, r, seed, pal='hetre'):
    rng = np.random.default_rng(seed); sombre, moyen, clair = PAL[pal]; o = [ombre_sol(x, y, r * 1.1, r * 0.3)]
    lobes = [(-r * 0.55, -r * 0.45, r * 0.6), (r * 0.5, -r * 0.4, r * 0.62), (0, -r * 0.75, r * 0.7)]
    ds = [bosse(x + a, y + b, c, 8, rng) for a, b, c in lobes]
    for d in ds: o.append(f'<path d="{d}" fill="{sombre}" stroke="{INK}" stroke-width="2"/>')
    for d in ds: o.append(f'<path d="{d}" fill="{sombre}"/>')
    for a, b, c in lobes: o.append(f'<path d="{bosse(x + a - c * 0.2, y + b - c * 0.25, c * 0.6, 7, rng)}" fill="{moyen}"/>')
    if rng.uniform() < 0.4:
        for k in range(3):
            o.append(f'<circle cx="{f2(x + rng.uniform(-r, r) * 0.7)}" cy="{f2(y - rng.uniform(0.3, 1.1) * r)}" r="1.6" fill="{["#E2504A", "#F4E9DA", "#B35FC9"][int(seed) % 3]}" stroke="{INK}" stroke-width="0.5"/>')
    return ''.join(o)

def fougere(x, y, s, seed):
    rng = np.random.default_rng(seed); o = []
    for a in np.linspace(-1.1, 1.1, 5):
        ex, ey = x + math.sin(a) * s, y - math.cos(a) * s * 0.8
        o.append(f'<path d="M{f2(x)},{f2(y)} Q{f2(x + math.sin(a) * s * 0.4)},{f2(y - s * 0.7)} {f2(ex)},{f2(ey)}" stroke="#3E7A37" stroke-width="2.2" fill="none" stroke-linecap="round"/>')
        o.append(f'<path d="M{f2(x)},{f2(y)} Q{f2(x + math.sin(a) * s * 0.4)},{f2(y - s * 0.7)} {f2(ex)},{f2(ey)}" stroke="#7FB45A" stroke-width="0.9" fill="none" stroke-linecap="round" stroke-dasharray="1.5 1.5"/>')
    return ''.join(o)

def herbes_hautes(x, y, s, seed, cols=('#B8963E', '#D9BC62', '#8A7A3A')):
    rng = np.random.default_rng(seed); o = []
    for k in range(6):
        dx = rng.uniform(-s * 0.5, s * 0.5); h = s * rng.uniform(0.7, 1.2); c = cols[k % 3]
        o.append(f'<path d="M{f2(x + dx)},{f2(y)} q{f2(rng.uniform(-3, 3))},{f2(-h * 0.6)} {f2(rng.uniform(-4, 4))},{f2(-h)}" stroke="{c}" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
    o.append(f'<path d="M{f2(x - s * 0.4)},{f2(y)} q{f2(s * 0.1)},{f2(-s * 0.5)} {f2(s * 0.05)},{f2(-s * 0.85)}" stroke="{INK}" stroke-width="0.7" fill="none" opacity="0.6"/>')
    return ''.join(o)

def roseaux(x, y, s, seed):
    rng = np.random.default_rng(seed); o = []
    for k in range(5):
        dx = rng.uniform(-4, 4); h = s * rng.uniform(0.7, 1.15)
        o.append(f'<path d="M{f2(x + dx)},{f2(y)} q{f2(rng.uniform(-2, 2))},{f2(-h * 0.5)} {f2(rng.uniform(-3, 3))},{f2(-h)}" stroke="#4E7A34" stroke-width="1.5" fill="none" stroke-linecap="round"/>')
        if k % 2 == 0:
            o.append(f'<ellipse cx="{f2(x + dx + rng.uniform(-1, 1))}" cy="{f2(y - h + 2)}" rx="1.5" ry="3.4" fill="#7A4E26" stroke="{INK}" stroke-width="0.6"/>')
    return ''.join(o)

def rocher(x, y, r, seed, teinte=('#D2CDBF', '#A8A194', '#80796C')):
    rng = np.random.default_rng(seed); clair, moyen, sombre = teinte; o = [ombre_sol(x, y + 1, r * 1.1, r * 0.32, 0.26)]
    n = 10; pts = []
    for i in range(n):
        a = math.pi + i / (n - 1) * math.pi; k = rng.uniform(0.78, 1.08)
        pts.append((x + math.cos(a) * r * k, y - r * 0.12 + math.sin(a) * r * 0.9 * k))
    pts += [(x + r * 0.9, y + r * 0.1), (x - r * 0.9, y + r * 0.1)]
    d = 'M' + ' L'.join(f'{f2(a)},{f2(b)}' for a, b in pts) + 'Z'
    o.append(f'<path d="{d}" fill="{clair}" stroke="{INK}" stroke-width="1.5" stroke-linejoin="round"/>')
    sx = x + r * rng.uniform(-0.05, 0.3)
    f = f'M{f2(sx)},{f2(y - r * 0.92)} L{f2(x + r * 0.98)},{f2(y - r * 0.15)} L{f2(x + r * 0.9)},{f2(y + r * 0.1)} L{f2(sx - r * 0.2)},{f2(y + r * 0.1)} L{f2(sx)},{f2(y - r * 0.4)}Z'
    o.append(f'<path d="{f}" fill="{moyen}"/>')
    o.append(f'<path d="M{f2(x - r * 0.9)},{f2(y + r * 0.1)} L{f2(x + r * 0.9)},{f2(y + r * 0.1)} L{f2(x + r * 0.7)},{f2(y - r * 0.12)} L{f2(x - r * 0.6)},{f2(y - r * 0.1)}Z" fill="{sombre}" opacity="0.8"/>')
    o.append(f'<path d="M{f2(sx)},{f2(y - r * 0.92)} L{f2(sx)},{f2(y - r * 0.4)} L{f2(sx - r * 0.2)},{f2(y + r * 0.1)}" stroke="{INK}" stroke-width="1" fill="none"/>')
    o.append(f'<path d="M{f2(x - r * 0.6)},{f2(y - r * 0.5)} l{f2(r * 0.22)},{f2(r * 0.1)} l{f2(r * 0.08)},{f2(r * 0.25)}" stroke="{INK}" stroke-width="0.9" fill="none" opacity="0.7"/>')
    if r > 8 and rng.uniform() < 0.5:
        o.append(f'<path d="{bosse(x - r * 0.3, y - r * 0.75, r * 0.3, 6, rng, r * 0.14)}" fill="#7FA84E" stroke="{INK}" stroke-width="0.8"/>')
    return ''.join(o)

def termitiere(x, y, h, seed):
    rng = np.random.default_rng(seed); w = h * 0.38
    o = ombre_sol(x, y, w * 1.4, w * 0.4)
    o += f'<path d="M{f2(x - w)},{f2(y)} Q{f2(x - w * 0.6)},{f2(y - h * 0.6)} {f2(x - w * 0.15)},{f2(y - h)} Q{f2(x + w * 0.1)},{f2(y - h * 1.05)} {f2(x + w * 0.25)},{f2(y - h * 0.8)} Q{f2(x + w * 0.7)},{f2(y - h * 0.4)} {f2(x + w)},{f2(y)} Z" fill="#B9825A" stroke="{INK}" stroke-width="1.3"/>'
    o += f'<path d="M{f2(x + w * 0.05)},{f2(y)} Q{f2(x + w * 0.6)},{f2(y - h * 0.4)} {f2(x + w * 0.25)},{f2(y - h * 0.8)} Q{f2(x + w * 0.7)},{f2(y - h * 0.4)} {f2(x + w)},{f2(y)} Z" fill="#94603E"/>'
    for k in range(3):
        o += f'<path d="M{f2(x - w * 0.5 + k * w * 0.4)},{f2(y - h * rng.uniform(0.2, 0.6))} l{f2(rng.uniform(-1, 1))},{f2(-h * 0.15)}" stroke="{INK}" stroke-width="0.8" opacity="0.5"/>'
    return o

def souche(x, y, r, seed):
    return (ombre_sol(x, y, r, r * 0.3) + f'<path d="M{f2(x - r)},{f2(y)} L{f2(x - r * 0.85)},{f2(y - r)} L{f2(x + r * 0.85)},{f2(y - r)} L{f2(x + r)},{f2(y)}Z" fill="#7A5A3A" stroke="{INK}" stroke-width="1.2"/>'
            f'<ellipse cx="{f2(x)}" cy="{f2(y - r)}" rx="{f2(r * 0.85)}" ry="{f2(r * 0.35)}" fill="#D9B784" stroke="{INK}" stroke-width="1.1"/><ellipse cx="{f2(x)}" cy="{f2(y - r)}" rx="{f2(r * 0.4)}" ry="{f2(r * 0.15)}" fill="none" stroke="#A07848" stroke-width="0.8"/>')

def rondins(x, y, s):
    o = [ombre_sol(x, y, s * 1.3, s * 0.3)]
    for i, (dx, dy) in enumerate([(-s * 0.6, 0), (s * 0.6, 0), (0, -s * 0.8)]):
        o.append(f'<rect x="{f2(x + dx - s * 0.9)}" y="{f2(y + dy - s * 0.8)}" width="{f2(s * 1.6)}" height="{f2(s * 0.8)}" rx="{f2(s * 0.4)}" fill="#8A6038" stroke="{INK}" stroke-width="1.1"/>')
        o.append(f'<ellipse cx="{f2(x + dx + s * 0.7)}" cy="{f2(y + dy - s * 0.4)}" rx="{f2(s * 0.3)}" ry="{f2(s * 0.4)}" fill="#D9B784" stroke="{INK}" stroke-width="1"/>')
    return ''.join(o)

def tente(x, y, s, col='#E8DCC0'):
    return (ombre_sol(x, y, s * 1.2, s * 0.3) + f'<path d="M{f2(x - s)},{f2(y)} L{f2(x - s * 0.15)},{f2(y - s * 1.1)} L{f2(x + s * 0.35)},{f2(y - s * 1.2)} L{f2(x + s * 1.1)},{f2(y - s * 0.05)} Z" fill="{col}" stroke="{INK}" stroke-width="1.3" stroke-linejoin="round"/>'
            f'<path d="M{f2(x + s * 0.35)},{f2(y - s * 1.2)} L{f2(x + s * 1.1)},{f2(y - s * 0.05)} L{f2(x + s * 0.2)},{f2(y)} Z" fill="#B8A882"/><path d="M{f2(x - s * 0.35)},{f2(y)} L{f2(x - s * 0.15)},{f2(y - s * 0.6)} L{f2(x + s * 0.05)},{f2(y)}Z" fill="#3A3226"/>')

def feu(x, y):
    return (f'<ellipse cx="{f2(x)}" cy="{f2(y)}" rx="9" ry="3.5" fill="#6B5A48" stroke="{INK}" stroke-width="1"/><path d="M{f2(x - 4)},{f2(y)} q-1,-8 4,-13 q1,6 4,5 q2,4 0,8 Z" fill="#F29A2E" stroke="{INK}" stroke-width="1"/><path d="M{f2(x - 1)},{f2(y - 1)} q0,-5 2,-7 q1,4 2,6Z" fill="#FFE07A"/>')

# ================================================================== constructions
def cloture(pts, h=12, ecart=13, bois='#A0703E', type_='bois'):
    """Clôture en perspective : renvoie des objets (y_base, svg) par segment."""
    p = lisse(pts, 8) if len(pts) > 2 else np.array(pts, float)
    # échantillonnage régulier
    seg = np.hypot(*np.diff(p, axis=0).T); L = np.concatenate([[0], np.cumsum(seg)])
    n = max(2, int(L[-1] / ecart)); t = np.linspace(0, L[-1], n + 1)
    xs = np.interp(t, L, p[:, 0]); ys = np.interp(t, L, p[:, 1])
    objs = []
    for i in range(n):
        x1, y1, x2, y2 = xs[i], ys[i], xs[i + 1], ys[i + 1]
        o = ''
        if type_ == 'bois':
            for hh in (h * 0.35, h * 0.75):
                o += f'<path d="M{f2(x1)},{f2(y1 - hh)} L{f2(x2)},{f2(y2 - hh)}" stroke="{INK}" stroke-width="3.6" stroke-linecap="round"/><path d="M{f2(x1)},{f2(y1 - hh)} L{f2(x2)},{f2(y2 - hh)}" stroke="{bois}" stroke-width="2" stroke-linecap="round"/>'
            o += f'<rect x="{f2(x2 - 1.8)}" y="{f2(y2 - h - 1)}" width="3.6" height="{f2(h + 1)}" rx="0.8" fill="#7A5230" stroke="{INK}" stroke-width="1"/>'
        elif type_ == 'pierre':
            hh = h
            L_ = math.hypot(x2 - x1, y2 - y1) or 1; ex, ey = -(y2 - y1) / L_ * 6, (x2 - x1) / L_ * 6
            if abs(ey) < 3:   # mur vu de côté : épaisseur visible
                o += f'<path d="M{f2(x1 - 3)},{f2(y1)} L{f2(x2 - 3)},{f2(y2)} L{f2(x2 - 3)},{f2(y2 - hh)} L{f2(x1 - 3)},{f2(y1 - hh)} Z" fill="#C2BBA9" stroke="{INK}" stroke-width="1.2"/>'
                o += f'<path d="M{f2(x1 - 3)},{f2(y1 - hh)} L{f2(x2 - 3)},{f2(y2 - hh)} L{f2(x2 + 4)},{f2(y2 - hh)} L{f2(x1 + 4)},{f2(y1 - hh)} Z" fill="#EFEADF" stroke="{INK}" stroke-width="1.1"/>'
                o += f'<path d="M{f2(x1 + 4)},{f2(y1 - hh)} L{f2(x2 + 4)},{f2(y2 - hh)} L{f2(x2 + 4)},{f2(y2)} L{f2(x1 + 4)},{f2(y1)} Z" fill="#D8D2C2" stroke="{INK}" stroke-width="1.2"/>'
                objs.append((max(y1, y2), o)); continue
            o += f'<path d="M{f2(x1)},{f2(y1)} L{f2(x2)},{f2(y2)} L{f2(x2)},{f2(y2 - hh)} L{f2(x1)},{f2(y1 - hh)} Z" fill="#D8D2C2" stroke="{INK}" stroke-width="1.2"/>'
            o += f'<path d="M{f2(x1)},{f2(y1 - hh)} L{f2(x2)},{f2(y2 - hh)} L{f2(x2)},{f2(y2 - hh - 4)} L{f2(x1)},{f2(y1 - hh - 4)} Z" fill="#EFEADF" stroke="{INK}" stroke-width="1.1"/>'
            o += f'<path d="M{f2(x1)},{f2(y1 - hh * 0.5)} L{f2(x2)},{f2(y2 - hh * 0.5)} M{f2((x1 + x2) / 2)},{f2((y1 + y2) / 2 - hh * 0.5)} l0,{f2(hh * 0.5)} M{f2(x1 + (x2 - x1) * 0.25)},{f2(y1 + (y2 - y1) * 0.25 - hh)} l0,{f2(hh * 0.5)}" stroke="{INK}" stroke-width="0.7" opacity="0.6"/>'
        objs.append((max(y1, y2), o))
    return objs

def ponton(x0, y0, x1, y1, larg=14):
    """Ponton/passerelle en planches posé à plat, avec pilotis."""
    ang = math.atan2(y1 - y0, x1 - x0); L = math.hypot(x1 - x0, y1 - y0)
    nx, ny = -math.sin(ang) * larg / 2, math.cos(ang) * larg / 2
    o = f'<path d="M{f2(x0 + nx)},{f2(y0 + ny)} L{f2(x1 + nx)},{f2(y1 + ny)} L{f2(x1 + nx)},{f2(y1 + ny + 5)} L{f2(x0 + nx)},{f2(y0 + ny + 5)}Z" fill="#6E4C2C" stroke="{INK}" stroke-width="1"/>'
    o += f'<path d="M{f2(x0 + nx)},{f2(y0 + ny)} L{f2(x1 + nx)},{f2(y1 + ny)} L{f2(x1 - nx)},{f2(y1 - ny)} L{f2(x0 - nx)},{f2(y0 - ny)}Z" fill="#B8864E" stroke="{INK}" stroke-width="1.4"/>'
    for k in range(1, int(L / 5)):
        t = k * 5 / L; px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        o += f'<path d="M{f2(px + nx)},{f2(py + ny)} L{f2(px - nx)},{f2(py - ny)}" stroke="{INK}" stroke-width="0.6" opacity="0.55"/>'
    return o

def escalier_cascade(x, ytop, ybas, larg=26):
    o = f'<path d="M{f2(x - larg / 2)},{f2(ytop)} L{f2(x + larg / 2)},{f2(ytop)} L{f2(x + larg / 2 + 4)},{f2(ybas)} L{f2(x - larg / 2 - 4)},{f2(ybas)}Z" fill="#7FCCE3" stroke="{INK}" stroke-width="1.6"/>'
    for k in range(7):
        xx_ = x - larg / 2 + 3 + k * (larg - 6) / 6
        o += f'<path d="M{f2(xx_)},{f2(ytop + 2)} L{f2(xx_ + (xx_ - x) * 0.15)},{f2(ybas - 3)}" stroke="#FFFFFF" stroke-width="{1.6 if k % 2 else 0.9}" opacity="0.85"/>'
    o += f'<ellipse cx="{f2(x)}" cy="{f2(ybas)}" rx="{f2(larg * 0.85)}" ry="6" fill="#FFFFFF" stroke="{INK}" stroke-width="1.2" opacity="0.95"/>'
    return o

# ================================================================== scène
class Scene:
    def __init__(self, nom, seed, sol):
        self.nom, self.seed = nom, seed
        self.sol = sol                      # dict de couleurs
        self.niv = np.zeros((GH, GW), int)  # niveau du terrain (0..3)
        self.hauteurs = {0: 0}
        self.eau = np.zeros((GH, GW), bool)
        self.prof = 9
        self.plat = {0: [], 1: [], 2: [], 3: []}   # éléments plats par niveau
        self.objs = []                      # (niveau, x, y_sol, svg déjà décalé)
        self.defs = []
        self.uid = 0

    def id(self, p='i'):
        self.uid += 1; return f'{p}{self.uid}'

    def Hn(self, L): return self.hauteurs.get(L, 0)

    def ajoute(self, L, x, y, svg):
        self.objs.append((L, x, y, svg))

    def niveau_en(self, x, y):
        gx, gy = int(x // S), int(y // S)
        if 0 <= gx < GW and 0 <= gy < GH: return int(self.niv[gy, gx])
        return 0

    def corps_ecran(self, L):
        """Masque écran du volume des plateaux de niveau >= L (pied + faces)."""
        f = self.niv >= L
        h = int(self.Hn(L) // S) + 1
        m = f.copy()
        for k in range(1, h + 1):
            m[:-k] |= f[k:]
        return m

    def rendu(self):
        sol = self.sol; o = [f'<rect width="{W}" height="{H}" fill="{sol["base"]}"/>']
        o += self.plat[0]
        # eau (niveau 0) : berge visible au nord, eau abaissée
        if self.eau.any():
            d = contours(self.eau, 1.0); cid = self.id('ce')
            self.defs.append(f'<clipPath id="{cid}"><path d="{d}" fill-rule="evenodd"/></clipPath>')
            o.append(f'<path d="{d}" fill="{sol.get("berge", "#9C8A68")}" fill-rule="evenodd" stroke="{INK}" stroke-width="2.4"/>')
            o.append(f'<g clip-path="url(#{cid})"><g transform="translate(0,{self.prof})">'
                     f'<path d="{d}" fill="{sol.get("eau", "#45A6D3")}" fill-rule="evenodd" stroke="{INK}" stroke-width="1" stroke-opacity="0.5"/>'
                     f'<path d="{contours(nd.binary_erosion(self.eau, iterations=4), 1.2)}" fill="{sol.get("eau2", "#2E86BE")}" fill-rule="evenodd" opacity="0.75"/>'
                     f'<path d="{contours(nd.binary_erosion(self.eau, iterations=9), 1.4)}" fill="{sol.get("eau3", "#246FA6")}" fill-rule="evenodd" opacity="0.6"/>'
                     f'<rect width="{W}" height="{H}" fill="url(#rides)"/></g>'
                     f'<path d="{d}" fill="none" stroke="#FFFFFF" stroke-width="5" opacity="0.45" transform="translate(0,{self.prof + 2})"/></g>')
            o += self.plat.get('eau', [])
        hmax = max(self.hauteurs)
        # objets classés : derrière un plateau plus haut, ou devant
        corps = {L: self.corps_ecran(L) for L in range(1, hmax + 1)}
        def derriere(L, x, ys):
            for L2 in range(L + 1, hmax + 1):
                gx = int(x // S)
                if not (0 <= gx < GW): continue
                col = corps[L2][:, gx]
                g0 = int(ys // S)
                if g0 < 0: return True
                if g0 < GH and col[g0]: return None   # caché dedans : à jeter
                if col[g0:min(GH, g0 + 40)].any(): return True
            return False
        avant = {L: [] for L in range(0, hmax + 1)}; devant = []
        for (L, x, y, svg) in self.objs:
            ys = y - self.Hn(L)
            r = derriere(L, x, ys)
            if r is None: continue
            (avant[L] if r else devant).append((ys, svg))
        o += [s for _, s in sorted(avant[0], key=lambda t: t[0])]
        for L in range(1, hmax + 1):
            o += self.plateau(L)
            o += self.plat[L]
            o += [s for _, s in sorted(avant[L], key=lambda t: t[0])]
        o += [s for _, s in sorted(devant, key=lambda t: t[0])]
        return o

    def plateau(self, L):
        sol = self.sol; f = self.niv >= L; d = contours(f, 1.0); h = self.Hn(L); h0 = self.Hn(L - 1)
        hauteur = h - h0; pid = self.id('pl'); o = []
        faces = sol.get('faces', ['#7E6E58', '#9C8A70', '#B5A48A', '#C9BA9E'])
        self.defs.append(f'<path id="{pid}" d="{d}" fill-rule="evenodd"/>')
        # volume : copies empilées du contour (pied → sommet), du plus sombre au plus clair
        etapes = int(hauteur / 1.5)
        for k in range(etapes + 1):
            dy = -h0 - k * hauteur / etapes
            c = faces[min(len(faces) - 1, int(k / (etapes + 1) * len(faces)))]
            o.append(f'<use href="#{pid}" y="{f2(dy)}" fill="{c}"/>')
        # contour du pied, strates et fissures verticales sur les faces sud
        o.append(f'<use href="#{pid}" y="{f2(-h0)}" fill="none" stroke="{INK}" stroke-width="2.2"/>')
        for t in (0.33, 0.66):
            o.append(f'<use href="#{pid}" y="{f2(-h0 - hauteur * t)}" fill="none" stroke="{INK}" stroke-width="0.9" opacity="0.4" stroke-dasharray="10 6 22 8"/>')
        bord = f & ~nd.binary_erosion(f, iterations=1)
        sud = bord & ~np.roll(f, -1, axis=0)
        rng = np.random.default_rng(L * 31 + self.seed)
        for (x, y) in semis(sud, 9, L * 7 + self.seed, 600):
            l = hauteur * rng.uniform(0.3, 0.85)
            o.append(f'<path d="M{f2(x)},{f2(y - h0 + 1)} l{f2(rng.uniform(-1.5, 1.5))},{f2(-l)}" stroke="{INK}" stroke-width="{0.8 if rng.uniform() < 0.6 else 1.3}" opacity="0.55"/>')
        for (x, y) in semis(sud, 30, L * 9 + self.seed, 200):
            o.append(rocher(x + 3, y - h0 + 4, rng.uniform(3, 6), int(x * y), ('#C9BA9E', '#9C8A70', '#7E6E58')))
        # dessus
        top = sol.get(f'dessus{L}', sol['base'])
        o.append(f'<use href="#{pid}" y="{f2(-h)}" fill="{top}" stroke="{INK}" stroke-width="2.4"/>')
        o.append(f'<use href="#{pid}" y="{f2(-h + 1.5)}" fill="none" stroke="#FFFFFF" stroke-width="1.6" opacity="0.35" stroke-dasharray="14 10"/>')
        return o

    # ---------- garnissage
    def taches(self, L, mask, col, op=1.0, trait=0.35):
        d = contours(mask, 1.6)
        if d: self.plat[L].append(f'<path d="{d}" fill="{col}" fill-rule="evenodd" opacity="{op}" stroke="{INK}" stroke-width="0.8" stroke-opacity="{trait}" transform="translate(0,{-self.Hn(L)})"/>')

    def touffes(self, L, mask, ecart, seed, col=INK, op=0.4):
        h = self.Hn(L)
        for (x, y) in semis(mask, ecart, seed, 4000):
            y -= h
            self.plat[L].append(f'<path d="M{f2(x - 3)},{f2(y)} l1.4,-4.6 M{f2(x)},{f2(y)} l0,-6 M{f2(x + 3)},{f2(y)} l-1.4,-4.6" stroke="{col}" stroke-width="1" stroke-linecap="round" opacity="{op}" fill="none"/>')

    def fleurs(self, L, mask, ecart, seed, cols=('#FFFFFF', '#FFD84A', '#F59AB8', '#B9A2F2')):
        h = self.Hn(L)
        for (x, y) in semis(mask, ecart, seed, 1500):
            c = cols[int(x * 3 + y) % len(cols)]
            for (dx, dy) in [(0, 0), (4, 2), (-3, 3)][: 1 + int(x) % 3]:
                self.plat[L].append(f'<circle cx="{f2(x + dx)}" cy="{f2(y + dy - h)}" r="1.7" fill="{c}" stroke="{INK}" stroke-width="0.6"/>')

    def chemin(self, L, pts, larg, col=None, bord=None, cailloux=True):
        col = col or self.sol['chemin']; bord = bord or self.sol['chemin_bord']; h = self.Hn(L)
        p = lisse(pts, 10); p[:, 1] -= h
        d = 'M' + ' L'.join(f'{f2(a)},{f2(b)}' for a, b in p)
        self.plat[L].append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{larg + 3}" stroke-linecap="round" stroke-linejoin="round" opacity="0.85"/>')
        self.plat[L].append(f'<path d="{d}" fill="none" stroke="{bord}" stroke-width="{larg}" stroke-linecap="round" stroke-linejoin="round"/>')
        self.plat[L].append(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{larg - 5}" stroke-linecap="round" stroke-linejoin="round"/>')
        if cailloux:
            rng = np.random.default_rng(int(p[0, 0] + p[-1, 1]))
            for i in range(0, len(p), 3):
                x, y = p[i]; o = rng.uniform(-larg * 0.35, larg * 0.35)
                self.plat[L].append(f'<ellipse cx="{f2(x + o)}" cy="{f2(y + rng.uniform(-3, 3))}" rx="{f2(rng.uniform(1, 2.3))}" ry="{f2(rng.uniform(0.8, 1.5))}" fill="{bord}" stroke="{INK}" stroke-width="0.5" opacity="0.8"/>')

    def pave(self, L, pts, larg):
        h = self.Hn(L); p = lisse(pts, 10); p[:, 1] -= h
        d = 'M' + ' L'.join(f'{f2(a)},{f2(b)}' for a, b in p)
        self.plat[L].append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{larg + 3}" stroke-linecap="round" stroke-linejoin="round"/>')
        self.plat[L].append(f'<path d="{d}" fill="none" stroke="#E4DCC8" stroke-width="{larg}" stroke-linecap="round" stroke-linejoin="round"/>')
        self.plat[L].append(f'<path d="{d}" fill="none" stroke="#B9AE96" stroke-width="{larg}" stroke-dasharray="1.2 7" stroke-linecap="butt" stroke-linejoin="round"/>')
        self.plat[L].append(f'<path d="{d}" fill="none" stroke="#FFFFFF" stroke-width="{larg * 0.3}" stroke-linecap="round" opacity="0.25"/>')

    def vegetation(self, L, mask, ecart, seed, melange, taille=(1.0, 1.0), n=3000):
        rng = np.random.default_rng(seed); h = self.Hn(L)
        noms = list(melange); poids = np.array([melange[k] for k in noms], float); poids /= poids.sum()
        for (x, y) in semis(mask, ecart, seed, n):
            t = noms[rng.choice(len(noms), p=poids)]; k = rng.uniform(*taille); s = int(rng.integers(1 << 30)); ys = y - h
            if t in PAL and t not in ('bouleau', 'acacia', 'saule'):
                svg = feuillu(x, ys, 10.5 * k, t, s)
            elif t == 'pin': svg = conifere(x, ys, 40 * k, s)
            elif t == 'sapin_clair': svg = conifere(x, ys, 34 * k, s, ('#2E6340', '#3F7F4C', '#6AA466'))
            elif t == 'bouleau': svg = bouleau(x, ys, 7.5 * k, s)
            elif t == 'acacia': svg = acacia(x, ys, 11 * k, s)
            elif t == 'baobab': svg = baobab(x, ys, 13 * k, s)
            elif t == 'saule': svg = saule(x, ys, 13 * k, s)
            elif t == 'buisson': svg = buisson(x, ys, 7 * k, s)
            elif t == 'buisson_sec': svg = buisson(x, ys, 6.5 * k, s, 'olive')
            elif t == 'fougere': svg = fougere(x, ys, 8 * k, s)
            elif t == 'herbes': svg = herbes_hautes(x, ys, 11 * k, s)
            elif t == 'roseaux': svg = roseaux(x, ys, 14 * k, s)
            elif t == 'rocher': svg = rocher(x, ys, 6 + 7 * rng.uniform() * k, s)
            elif t == 'souche': svg = souche(x, ys, 4.5 * k, s)
            elif t == 'termitiere': svg = termitiere(x, ys, 16 * k, s)
            else: continue
            self.ajoute(L, x, y, svg)

    def sprite(self, L, nom, x, y, haut, flip=False, ombre=True):
        self.ajoute(L, x, y, monde.sprite(nom, x, y - self.Hn(L), haut, ombre=ombre, flip=flip))

    def cloture(self, L, pts, h=12, type_='bois', ecart=13):
        hh = self.Hn(L)
        for yb, svg in cloture([(a, b - hh) for a, b in pts], h, ecart, type_=type_):
            self.objs.append((L, 0, yb + hh, svg))

    def svg(self):
        corps = self.rendu()
        defs = f'''<defs>
<pattern id="rides" width="34" height="14" patternUnits="userSpaceOnUse"><path d="M2,9 q7,-5 14,0" fill="none" stroke="#FFFFFF" stroke-width="1.2" opacity="0.55"/><path d="M19,4 q5,-3 10,0" fill="none" stroke="{INK}" stroke-width="0.7" opacity="0.2"/></pattern>
<pattern id="hach" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="5" stroke="{INK}" stroke-width="1" opacity="0.45"/></pattern>
{''.join(self.defs)}</defs>'''
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{defs}{"".join(corps)}</svg>'
