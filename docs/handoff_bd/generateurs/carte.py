"""Redessine la carte de jeu (capture du prototype) dans le style « 5 · zoo en cours de partie »."""
import os
import numpy as np
from PIL import Image
from scipy import ndimage as nd
from persp import *

KX, KY = 1600 / 1027, 900 / 599
def P(x, y): return (x * KX, y * KY)

cls0 = np.load(os.path.join(ICI, 'carte_cls.npy'))
cls = np.array(Image.fromarray(cls0.astype(np.uint8)).resize((GW, GH), Image.NEAREST)).astype(int)

zx0, zy0 = P(708, 420); zx1, zy1 = P(928, 640)
zoo = (xx > zx0) & (xx < zx1) & (yy > zy0)
batis = [P(565, 505), P(623, 352), P(410, 563), P(875, 563), P(233, 120), P(612, 560)]
for (bx, by) in batis:
    cls[((xx - bx) / 46) ** 2 + ((yy - by) / 34) ** 2 < 1] = 0
cls[zoo & ~np.isin(cls, (1, 2))] = 0
cls[zoo & (cls == 1) & (bruit(3, 5) < 0.6)] = 0

def nettoie(m, k=1): return nd.binary_opening(nd.binary_closing(m, iterations=k), iterations=k)
foret = nettoie(cls == 1); eau = nettoie(cls == 2); roche = nettoie(cls == 3); sable = nettoie(cls == 4); mont = nettoie(cls == 5, 2)

s = Scene('6_carte', 606, dict(base='#8CC25A', chemin='#E6CB94', chemin_bord='#C9A468', berge='#8E7A5A', eau='#46A9D6', eau2='#2E8CC4', eau3='#2272A8',
                              dessus1='#A39C8C', faces=['#5F574B', '#786E60', '#938878', '#ADA190']))
s.hauteurs = {0: 0, 1: 22}
s.prof = 8
s.eau = eau
s.niv[mont] = 1

# ------------------------------------------------------------------ prairie détaillée
herbe = ~eau & ~foret & ~roche & ~sable & ~mont
s.taches(0, (bruit(6, 11) > 0.35), '#7FB64F', trait=0.25)
s.taches(0, (bruit(6, 12) > 1.0), '#9DCB66', trait=0.2)
s.taches(0, (bruit(3, 13) > 1.4) & herbe, '#B2D579', trait=0.3)
s.taches(0, nd.binary_dilation(foret, iterations=2) & ~foret & ~eau, '#6EA548', trait=0.0)   # ombre de lisière
rng = np.random.default_rng(14)
for (x, y) in semis(herbe, 9, 15, 6000):   # brins fins partout
    a = rng.uniform(-0.35, 0.35); h = rng.uniform(3, 5.5)
    c = '#5E9A3A' if rng.uniform() < 0.7 else '#C6E08E'
    s.plat[0].append(f'<path d="M{f2(x)},{f2(y)} l{f2(math.sin(a) * h)},{f2(-math.cos(a) * h)}" stroke="{c}" stroke-width="1.1" stroke-linecap="round"/>')
for (x, y) in semis(herbe, 20, 16, 2500):   # touffes encrées de 3 formes
    k = rng.integers(3)
    if k == 0: d = f'M{f2(x - 3)},{f2(y)} l1.4,-4.6 M{f2(x)},{f2(y)} l0,-6 M{f2(x + 3)},{f2(y)} l-1.4,-4.6'
    elif k == 1: d = f'M{f2(x - 4)},{f2(y)} q1,-5 3,-6 M{f2(x)},{f2(y)} q0.5,-4 -1,-7 M{f2(x + 3)},{f2(y)} q1,-3 3,-4'
    else: d = f'M{f2(x - 2)},{f2(y)} l-1.5,-4 M{f2(x)},{f2(y)} l0.6,-5 M{f2(x + 2)},{f2(y)} l2,-3.4 M{f2(x + 4)},{f2(y)} l0.5,-2.5'
    s.plat[0].append(f'<path d="{d}" stroke="{INK}" stroke-width="1" stroke-linecap="round" fill="none" opacity="0.45"/>')
for (x, y) in semis(herbe & (bruit(4, 17) > 0.8), 30, 18, 300):   # trèfle
    for (dx, dy) in [(0, 0), (4, 1.5), (1.5, 3.5)]:
        s.plat[0].append(f'<circle cx="{f2(x + dx)}" cy="{f2(y + dy)}" r="2.2" fill="#6FAE48" stroke="{INK}" stroke-width="0.6"/>')
for (x, y) in semis(herbe & (bruit(4, 19) > 0.5), 26, 20, 400):   # fleurs
    c = ['#FFFFFF', '#FFD84A', '#F59AB8', '#B9A2F2'][int(x * 3 + y) % 4]
    for (dx, dy) in [(0, 0), (4, 2), (-3, 3)][: 1 + int(x) % 3]:
        s.plat[0].append(f'<circle cx="{f2(x + dx)}" cy="{f2(y + dy)}" r="1.7" fill="{c}" stroke="{INK}" stroke-width="0.6"/>')
for (x, y) in semis(herbe, 55, 21, 300):   # cailloux
    s.plat[0].append(f'<ellipse cx="{f2(x)}" cy="{f2(y)}" rx="2.3" ry="1.5" fill="#C9C4B4" stroke="{INK}" stroke-width="0.7"/>')

# ------------------------------------------------------------------ sable
s.taches(0, sable, '#E9CE8A', trait=0.9)
s.taches(0, nd.binary_erosion(sable, iterations=2) & (bruit(3, 22) > 0.2), '#F3DDA4', trait=0.0)
for (x, y) in semis(sable, 15, 23, 1200):
    w = rng.uniform(5, 10)
    s.plat[0].append(f'<path d="M{f2(x - w)},{f2(y)} q{f2(w)},{f2(-3)} {f2(2 * w)},0" stroke="#B9955A" stroke-width="1" fill="none" opacity="0.7"/>')
for (x, y) in semis(sable, 11, 24, 2000):
    s.plat[0].append(f'<circle cx="{f2(x)}" cy="{f2(y)}" r="0.8" fill="{INK}" opacity="0.35"/>')
s.vegetation(0, sable & nd.binary_erosion(sable, iterations=1), 34, 25, {'herbes': 3, 'rocher': 1, 'buisson_sec': 1}, (0.7, 1.0), 200)

# ------------------------------------------------------------------ rocaille
s.taches(0, roche, '#BDB8AA', trait=0.9)
s.taches(0, roche & (bruit(3, 26) > 0.3), '#A7A193', trait=0.3)
for (x, y) in semis(roche, 7, 27, 3000):
    s.plat[0].append(f'<ellipse cx="{f2(x)}" cy="{f2(y)}" rx="{f2(rng.uniform(1, 2.4))}" ry="{f2(rng.uniform(0.8, 1.6))}" fill="#D6D1C4" stroke="{INK}" stroke-width="0.6"/>')
for (x, y) in semis(roche, 13, 28, 900):
    s.ajoute(0, x, y, rocher(x, y, rng.uniform(3.5, 8), int(x * 7 + y)))
s.vegetation(0, roche, 40, 29, {'buisson_sec': 1, 'herbes': 1, 'pin': 0.5}, (0.8, 1.1), 80)

# ------------------------------------------------------------------ montagnes (petit plateau + pics dessinés)
s.taches(1, mont, '#A39C8C', trait=0.0)
pics = semis(nd.binary_erosion(mont, iterations=2), 24, 30, 400)
for (x, y) in pics:
    w = rng.uniform(34, 54)
    s.ajoute(1, x, y + 8, monde.montagne_dessinee(x, y + 8 - s.Hn(1), w, int(x * 13 + y)))
for (x, y) in semis(mont & ~nd.binary_erosion(mont, iterations=2), 14, 31, 400):
    s.ajoute(1, x, y, rocher(x, y - s.Hn(1), rng.uniform(4, 7), int(x + y * 3)))

# ------------------------------------------------------------------ eau détaillée
cid = 'eauclip'
s.defs.append(f'<clipPath id="{cid}"><path d="{contours(eau, 1.0)}" fill-rule="evenodd"/></clipPath>')
extra = []
haut_fond = eau & ~nd.binary_erosion(eau, iterations=2)
extra.append(f'<g clip-path="url(#{cid})"><g transform="translate(0,{s.prof})">')
extra.append(f'<path d="{contours(haut_fond, 0.8)}" fill="#7CCCE6" fill-rule="evenodd" opacity="0.8"/>')
for (x, y) in semis(haut_fond, 9, 32, 800):          # galets au fond
    extra.append(f'<ellipse cx="{f2(x)}" cy="{f2(y)}" rx="{f2(rng.uniform(1.4, 2.6))}" ry="{f2(rng.uniform(1, 1.6))}" fill="#9FD9EA" stroke="#3A8CB4" stroke-width="0.6"/>')
for (x, y) in semis(nd.binary_erosion(eau, iterations=3), 16, 33, 1500):   # rides et reflets
    w = rng.uniform(4, 9)
    if rng.uniform() < 0.6:
        extra.append(f'<path d="M{f2(x - w)},{f2(y)} q{f2(w / 2)},-2.6 {f2(w)},0 t{f2(w)},0" stroke="#FFFFFF" stroke-width="1.2" fill="none" opacity="0.6"/>')
    else:
        extra.append(f'<path d="M{f2(x - w * 0.6)},{f2(y)} l{f2(w * 1.2)},0" stroke="{INK}" stroke-width="0.8" opacity="0.25"/>')
for (x, y) in semis(nd.binary_erosion(eau, iterations=4), 45, 34, 300):  # éclats
    extra.append(f'<path d="M{f2(x)},{f2(y - 3)} l0.8,2.2 2.2,0.8 -2.2,0.8 -0.8,2.2 -0.8,-2.2 -2.2,-0.8 2.2,-0.8z" fill="#FFFFFF"/>')
extra.append('</g>')
# écume au pied de la berge
extra.append(f'<path d="{contours(eau, 1.0)}" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-dasharray="7 4 2 5" opacity="0.85" transform="translate(0,{s.prof + 3})"/>')
extra.append('</g>')
# rochers émergés
for (x, y) in semis(nd.binary_erosion(eau, iterations=4) & (bruit(3, 35) > 1.0), 60, 36, 30):
    extra.append(rocher(x, y + s.prof, rng.uniform(4, 7), int(x)) + f'<ellipse cx="{f2(x)}" cy="{f2(y + s.prof + 1)}" rx="9" ry="2.4" fill="none" stroke="#FFFFFF" stroke-width="1.2" opacity="0.8"/>')
s.plat['eau'] = extra
berge = nd.binary_dilation(eau, iterations=2) & ~eau & herbe
s.vegetation(0, berge & (bruit(4, 37) > 0.0), 16, 38, {'roseaux': 4, 'rocher': 1.2, 'herbes': 0.6}, (0.8, 1.1), 700)

# ------------------------------------------------------------------ forêts
s.taches(0, nd.binary_erosion(foret, iterations=1), '#5E9145', trait=0.4)
s.vegetation(0, foret, 15, 39, {'chene': 3, 'hetre': 3, 'sombre': 3, 'pin': 2, 'sapin_clair': 1, 'bouleau': 0.6, 'automne': 0.3, 'buisson': 0.5}, (1.0, 1.4), 2200)
s.vegetation(0, herbe & (bruit(3, 40) > 1.6), 40, 41, {'chene': 1, 'buisson': 2, 'bouleau': 1}, (1.0, 1.3), 60)

# ------------------------------------------------------------------ chemins, camp, bâtiments
cx, cy = P(612, 560)
s.chemin(0, [P(565, 520), P(590, 545), (cx, cy)], 16)
s.chemin(0, [(cx, cy), P(700, 560), P(760, 580), P(800, 600)], 16)
s.chemin(0, [P(410, 578), P(500, 570), (cx - 30, cy + 10)], 16)
s.chemin(0, [P(623, 368), P(600, 430), P(570, 490)], 14)
s.chemin(0, [P(233, 134), P(260, 180), P(300, 240)], 14)
s.sprite(0, 'camp', cx, cy + 34, 76, ombre=False)
s.sprite(0, 'maison', *P(565, 520), 58)
s.sprite(0, 'entrepot', *P(623, 372), 58)
s.sprite(0, 'entrepot', *P(410, 582), 56, True)
s.sprite(0, 'mine', *P(233, 140), 56)
s.ajoute(0, *P(650, 577), rondins(*P(650, 577), 6))
s.sprite(0, 'bucheron', *P(517, 490), 30); s.sprite(0, 'porteur_planche', *P(540, 498), 28, True)
s.sprite(0, 'piocheur', *P(250, 150), 26); s.sprite(0, 'brouette_m', *P(600, 470), 26)

# ------------------------------------------------------------------ zoo (en bas à droite)
s.cloture(0, [(zx0, 905), (zx0, zy0), (zx1, zy0), (zx1, 905)], 15, 'pierre', 16)
e1 = [P(712, 426), P(870, 426), P(870, 472), P(712, 472), P(712, 426)]
e2 = [P(770, 426), P(770, 520)]
s.cloture(0, e1, 12); s.cloture(0, [P(712, 472), P(712, 522), P(770, 522)], 12); s.cloture(0, e2, 12)
s.sprite(0, 'cerf', *P(735, 470), 30); s.sprite(0, 'biche', *P(800, 448), 26, True); s.sprite(0, 'biche', *P(840, 460), 24)
s.sprite(0, 'soigneur', *P(730, 505), 26)
s.sprite(0, 'snack', *P(800, 500), 46); s.sprite(0, 'entrepot', *P(875, 572), 48)
s.sprite(0, 'flamant', *P(790, 560), 30); s.sprite(0, 'flamant', *P(810, 566), 26, True)
for n, (x, y), f in [('visiteuse_sac', P(760, 590), False), ('enfant2', P(772, 594), True), ('visiteur_canne', P(845, 585), False)]:
    s.sprite(0, n, x, y, 24 if 'enfant' not in n else 18, f)

os.makedirs(os.path.join(ICI, 'svg3'), exist_ok=True)
open(os.path.join(ICI, 'svg3', '6_carte.svg'), 'w').write(s.svg())
print('ok')
