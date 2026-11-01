"""Textures de détail raccordables (4 × 4 cases, 512 px) : herbe, sable, rocaille, eau."""
import math, os, numpy as np
from playwright.sync_api import sync_playwright
INK = '#14202B'; T = 160  # 4 cases × 40 unités
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'pkg', 'game', 'assets', 'bd', 'textures')
os.makedirs(OUT, exist_ok=True)
def f2(v): return f'{v:.2f}'
def poisson(ecart, seed, n=4000):
    r = np.random.default_rng(seed); pts = []
    for _ in range(n * 30):
        if len(pts) >= n: break
        x, y = r.uniform(0, T), r.uniform(0, T)
        if all(min(abs(x - a), T - abs(x - a)) ** 2 + min(abs(y - b), T - abs(y - b)) ** 2 >= ecart * ecart for a, b in pts[-400:]):
            pts.append((x, y))
    return pts
def wrap(fn, pts):
    o = []
    for (x, y) in pts:
        for dx in (-T, 0, T):
            for dy in (-T, 0, T):
                if -12 < x + dx < T + 12 and -12 < y + dy < T + 12: o.append(fn(x + dx, y + dy))
    return o
rng = np.random.default_rng(1)
tex = {}
# herbe
o = []
def brin(x, y):
    a = math.sin(x * 12.9 + y * 7.1) * 0.35; h = 3 + (math.sin(x * 3.3 + y) + 1) * 1.2
    c = '#5E9A3A' if (int(x * 7 + y * 3) % 10) < 7 else '#C6E08E'
    return f'<path d="M{f2(x)},{f2(y)} l{f2(math.sin(a) * h)},{f2(-math.cos(a) * h)}" stroke="{c}" stroke-width="1.1" stroke-linecap="round"/>'
o += wrap(brin, poisson(6.5, 2, 900))
def touffe(x, y):
    k = int(x * 13 + y * 7) % 3
    d = [f'M{f2(x - 3)},{f2(y)} l1.4,-4.6 M{f2(x)},{f2(y)} l0,-6 M{f2(x + 3)},{f2(y)} l-1.4,-4.6', f'M{f2(x - 4)},{f2(y)} q1,-5 3,-6 M{f2(x)},{f2(y)} q0.5,-4 -1,-7 M{f2(x + 3)},{f2(y)} q1,-3 3,-4',
         f'M{f2(x - 2)},{f2(y)} l-1.5,-4 M{f2(x)},{f2(y)} l0.6,-5 M{f2(x + 2)},{f2(y)} l2,-3.4'][k]
    return f'<path d="{d}" stroke="{INK}" stroke-width="1" stroke-linecap="round" fill="none" opacity="0.45"/>'
o += wrap(touffe, poisson(17, 3, 120))
o += wrap(lambda x, y: ''.join(f'<circle cx="{f2(x + dx)}" cy="{f2(y + dy)}" r="2.1" fill="#6FAE48" stroke="{INK}" stroke-width="0.6"/>' for dx, dy in [(0, 0), (4, 1.5), (1.5, 3.5)]), poisson(60, 4, 4))
cols = ['#FFFFFF', '#FFD84A', '#F59AB8', '#B9A2F2']
o += wrap(lambda x, y: ''.join(f'<circle cx="{f2(x + dx)}" cy="{f2(y + dy)}" r="1.6" fill="{cols[int(x * 3 + y) % 4]}" stroke="{INK}" stroke-width="0.6"/>' for dx, dy in [(0, 0), (4, 2), (-3, 3)][: 1 + int(x) % 3]), poisson(38, 5, 12))
o += wrap(lambda x, y: f'<ellipse cx="{f2(x)}" cy="{f2(y)}" rx="2.2" ry="1.4" fill="#C9C4B4" stroke="{INK}" stroke-width="0.7"/>', poisson(70, 6, 3))
tex['herbe_details'] = o
# sable
o = []
o += wrap(lambda x, y: f'<path d="M{f2(x - 7)},{f2(y)} q7,-3 14,0" stroke="#B9955A" stroke-width="1" fill="none" opacity="0.75"/>', poisson(13, 7, 150))
o += wrap(lambda x, y: f'<circle cx="{f2(x)}" cy="{f2(y)}" r="0.8" fill="{INK}" opacity="0.35"/>', poisson(6, 8, 700))
o += wrap(lambda x, y: f'<ellipse cx="{f2(x)}" cy="{f2(y)}" rx="2.3" ry="1.5" fill="#D2C3A6" stroke="{INK}" stroke-width="0.7"/>', poisson(45, 9, 8))
tex['sable_details'] = o
# rocaille
o = []
o += wrap(lambda x, y: f'<ellipse cx="{f2(x)}" cy="{f2(y)}" rx="{f2(1.2 + (x * 7 % 1.3))}" ry="{f2(0.9 + (y * 3 % 0.8))}" fill="#D6D1C4" stroke="{INK}" stroke-width="0.6"/>', poisson(6, 10, 800))
o += wrap(lambda x, y: f'<path d="M{f2(x - 5)},{f2(y)} l4,-3 l3,2 l4,-4" stroke="{INK}" stroke-width="0.9" fill="none" opacity="0.45"/>', poisson(30, 11, 30))
tex['roche_details'] = o
# eau
o = []
o += wrap(lambda x, y: f'<path d="M{f2(x - 7)},{f2(y)} q3.5,-2.6 7,0 t7,0" stroke="#FFFFFF" stroke-width="1.2" fill="none" opacity="0.6"/>', poisson(16, 12, 90))
o += wrap(lambda x, y: f'<path d="M{f2(x - 5)},{f2(y)} l10,0" stroke="{INK}" stroke-width="0.8" opacity="0.22"/>', poisson(22, 13, 50))
o += wrap(lambda x, y: f'<path d="M{f2(x)},{f2(y - 3)} l0.8,2.2 2.2,0.8 -2.2,0.8 -0.8,2.2 -0.8,-2.2 -2.2,-0.8 2.2,-0.8z" fill="#FFFFFF"/>', poisson(50, 14, 6))
tex['eau_details'] = o
# falaise (verticale) : stries et blocs, raccordable horizontalement
o = []
o += wrap(lambda x, y: f'<path d="M{f2(x)},{f2(y)} l{f2(math.sin(x) * 1.2)},{f2(-10 - (x * 7 % 8))}" stroke="{INK}" stroke-width="{0.8 if int(x) % 3 else 1.3}" opacity="0.5"/>', poisson(7, 15, 500))
tex['falaise_details'] = o
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page(viewport={'width': T, 'height': T}, device_scale_factor=3.2)
    for nom, els in tex.items():
        pg.set_content(f'<html><body style="margin:0;background:transparent"><svg xmlns="http://www.w3.org/2000/svg" width="{T}" height="{T}" viewBox="0 0 {T} {T}">{"".join(els)}</svg></body></html>')
        pg.screenshot(path=os.path.join(OUT, nom + '.png'), omit_background=True); print(nom)
    b.close()
