import json, os, numpy as np
from PIL import Image
from playwright.sync_api import sync_playwright
from persp import *
import monde
ICI = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ICI, '..', 'pkg', 'game', 'assets', 'bd', 'decor')
os.makedirs(OUT, exist_ok=True)
K = 3            # échelle de rendu : 40 px de dessin = 1 case → 120 px par case
CX, CY, BW, BH = 110, 170, 220, 200
items = {}
def ajoute(nom, svg, groupe): items[nom] = (svg, groupe)
for pal in ['chene', 'hetre', 'sombre', 'automne', 'or']:
    for i in range(4): ajoute(f'feuillu_{pal}_{i + 1}', feuillu(CX, CY, 12.5 + i * 0.8, pal, 100 + i * 17 + len(pal)), 'arbre')
for i in range(5): ajoute(f'pin_{i + 1}', conifere(CX, CY, 40 + i * 3, 300 + i), 'arbre')
for i in range(3): ajoute(f'sapin_{i + 1}', conifere(CX, CY, 36 + i * 3, 320 + i, ('#2E6340', '#3F7F4C', '#6AA466')), 'arbre')
for i in range(3): ajoute(f'bouleau_{i + 1}', bouleau(CX, CY, 8.5 + i * 0.6, 340 + i), 'arbre')
for i in range(2): ajoute(f'saule_{i + 1}', saule(CX, CY, 14 + i, 360 + i), 'arbre')
for i in range(3): ajoute(f'acacia_{i + 1}', acacia(CX, CY, 16 + i * 2, 380 + i), 'arbre')
for i in range(2): ajoute(f'baobab_{i + 1}', baobab(CX, CY, 17 + i * 2, 400 + i), 'arbre')
for i in range(4): ajoute(f'buisson_{i + 1}', buisson(CX, CY, 8 + i * 0.7, 420 + i), 'buisson')
for i in range(3): ajoute(f'buisson_sec_{i + 1}', buisson(CX, CY, 7 + i * 0.7, 440 + i, 'olive'), 'buisson')
for i in range(6): ajoute(f'rocher_{i + 1}', rocher(CX, CY, 5 + i * 1.6, 460 + i), 'rocher')
for i in range(2):
    ajoute(f'rocher_or_{i + 1}', rocher(CX, CY, 11 + i * 2, 480 + i) + f'<path d="M{CX - 5},{CY - 10} l3,-2 l2,3 M{CX + 3},{CY - 7} l2,-2 M{CX - 1},{CY - 4} l2,-1" stroke="#FFE04A" stroke-width="2.6" stroke-linecap="round"/><path d="M{CX - 5},{CY - 10} l3,-2 l2,3" stroke="{INK}" stroke-width="0.6" fill="none"/>', 'rocher')
for i in range(8): ajoute(f'pic_{i + 1}', monde.montagne_dessinee(CX, CY, 40 + i * 3.5, 500 + i * 7), 'montagne')
for i in range(3): ajoute(f'roseaux_{i + 1}', roseaux(CX, CY, 15 + i, 520 + i), 'berge')
for i in range(3): ajoute(f'herbes_hautes_{i + 1}', herbes_hautes(CX, CY, 12 + i, 530 + i), 'herbe')
for i in range(2): ajoute(f'fougere_{i + 1}', fougere(CX, CY, 9 + i, 540 + i), 'herbe')
for i in range(2): ajoute(f'termitiere_{i + 1}', termitiere(CX, CY, 18 + i * 3, 550 + i), 'rocher')
for i in range(2): ajoute(f'souche_{i + 1}', souche(CX, CY, 5 + i, 560 + i), 'objet')
ajoute('rondins', rondins(CX, CY, 7), 'objet')
for i, c in enumerate(['#E8DCC0', '#D8C8A0']): ajoute(f'tente_{i + 1}', tente(CX, CY, 15 + i * 2, c), 'objet')
ajoute('feu_de_camp', feu(CX, CY), 'objet')
DEFS = f'<defs><pattern id="hach" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="5" stroke="{INK}" stroke-width="1" opacity="0.45"/></pattern></defs>'
manif = {}
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page(viewport={'width': BW, 'height': BH}, device_scale_factor=K)
    for nom, (svg, g) in items.items():
        pg.set_content(f'<html><body style="margin:0;background:transparent"><svg xmlns="http://www.w3.org/2000/svg" width="{BW}" height="{BH}" viewBox="0 0 {BW} {BH}">{DEFS}{svg}</svg></body></html>')
        f = os.path.join(OUT, nom + '.png'); pg.screenshot(path=f, omit_background=True)
        im = Image.open(f); a = np.array(im); ys, xs = np.nonzero(a[:, :, 3] > 8)
        x0, y0 = xs.min(), ys.min(); im = im.crop((x0, y0, xs.max() + 1, ys.max() + 1)); im.save(f, optimize=True)
        manif[nom] = {'fichier': f'res://assets/bd/decor/{nom}.png', 'groupe': g, 'taille': list(im.size), 'pied': [int(CX * K - x0), int(CY * K - y0)]}
    b.close()
json.dump({'px_par_case': 40 * K, 'elements': manif}, open(os.path.join(OUT, '..', 'decor_bd.json'), 'w'), indent=1, sort_keys=True)
print(len(manif))
