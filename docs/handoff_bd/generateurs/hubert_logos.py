"""Découpe les expressions d'Hubert et les logos (fond clair ou papier retiré).

  python hubert_logos.py <expressions.webp> <logo_zoolife.webp> <logos_rivaux.webp> <racine du dépôt>

Écrit game/assets/bd/hubert/<expression>.png et game/assets/bd/logos/<groupe>.png, <groupe>_embleme.png.
"""
import os, sys
from collections import deque
import numpy as np
from PIL import Image

HUBERT = {  # expression -> cadre dans la planche
    "content": (0, 0, 490, 500), "furieux": (505, 0, 975, 500), "contrarie": (1015, 0, 1515, 500),
    "moqueur": (150, 505, 670, 1012), "neutre": (775, 505, 1295, 1012),
}
RIVAUX = {"panzoo": (95, 15, 1395, 465), "safari": (10, 450, 750, 965), "bioland": (775, 480, 1525, 945)}
EMBLEMES = {"zoolife": (345, 25, 845, 525), "panzoo": (300, 55, 680, 435), "safari": (20, 470, 330, 780), "bioland": (805, 495, 1055, 745)}


def sans_fond(rgb, est_fond, enferme_haut=0.0):
    """Retire ce qui touche les bords de l'image et ressemble au fond, avec un bord adouci."""
    h, w, _ = rgb.shape
    candidat = est_fond(rgb.astype(np.float32))
    vu = np.zeros((h, w), bool)
    file = deque()
    for x in range(w):
        for y in (0, h - 1):
            if candidat[y, x] and not vu[y, x]:
                vu[y, x] = True
                file.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if candidat[y, x] and not vu[y, x]:
                vu[y, x] = True
                file.append((y, x))
    while file:
        y, x = file.popleft()
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < h and 0 <= nx < w and candidat[ny, nx] and not vu[ny, nx]:
                vu[ny, nx] = True
                file.append((ny, nx))
    alpha = np.where(vu, 0, 255).astype(np.uint8)
    # Fond enfermé dans les boucles de cheveux : le haut de l'image seulement (les yeux et les dents restent blancs)
    if enferme_haut > 0.0:
        y_max = int(h * enferme_haut)
        alpha[:y_max][candidat[:y_max]] = 0
    return Image.fromarray(np.dstack([rgb, alpha]), 'RGBA')


def recadrer(im, hauteur=None, largeur=None):
    im = im.crop(im.getchannel('A').point(lambda a: 255 if a > 127 else 0).getbbox())
    k = hauteur / im.height if hauteur else largeur / im.width
    return im.convert('RGBa').resize((round(im.width * k), round(im.height * k)), Image.LANCZOS).convert('RGBA')


def main():
    expressions, logo, rivaux, racine = sys.argv[1:5]
    dos_h = os.path.join(racine, 'game', 'assets', 'bd', 'hubert')
    dos_l = os.path.join(racine, 'game', 'assets', 'bd', 'logos')
    os.makedirs(dos_h, exist_ok=True)
    os.makedirs(dos_l, exist_ok=True)
    planche = np.array(Image.open(expressions).convert('RGB'))
    # Fond à motifs gris très clair, sans couleur (la chemise, elle, tire sur le jaune)
    gris_clair = lambda c: (c.min(axis=2) > 205) & ((c.max(axis=2) - c.min(axis=2)) < 16)
    for nom, (x0, y0, x1, y1) in HUBERT.items():
        im = sans_fond(planche[y0:y1, x0:x1], gris_clair, 0.2)
        recadrer(im, hauteur=260).save(os.path.join(dos_h, nom + '.png'), optimize=True)
    papier_de = lambda ref, tol: (lambda c: np.sqrt(((c - ref) ** 2).sum(axis=2)) < tol)
    z = np.array(Image.open(logo).convert('RGB'))
    ref = np.median(z[:30, :30].reshape(-1, 3), axis=0).astype(np.float32)
    recadrer(sans_fond(z, papier_de(ref, 30.0)), largeur=900).save(os.path.join(dos_l, 'zoolife.png'), optimize=True)
    r = np.array(Image.open(rivaux).convert('RGB'))
    ref = np.median(r[:30, :30].reshape(-1, 3), axis=0).astype(np.float32)
    for nom, (x0, y0, x1, y1) in RIVAUX.items():
        im = sans_fond(r[y0:y1, x0:x1], papier_de(ref, 26.0))
        if nom == 'safari':  # le bas du logo PanZoo déborde sur le haut de ce cadre : rien d'orange dans Safari
            a = np.array(im)
            c = a[:, :, :3].astype(np.int32)
            orange = (c[:, :, 0] - c[:, :, 2] > 40) & (np.arange(a.shape[0])[:, None] < 60)
            a[:, :, 3][orange] = 0
            im = Image.fromarray(a, 'RGBA')
        recadrer(im, largeur=640).save(os.path.join(dos_l, nom + '.png'), optimize=True)
    for nom, (x0, y0, x1, y1) in EMBLEMES.items():
        src = z if nom == 'zoolife' else r
        Image.fromarray(src[y0:y1, x0:x1]).convert('RGB').resize((160, 160), Image.LANCZOS).save(os.path.join(dos_l, nom + '_embleme.png'), optimize=True)


if __name__ == '__main__':
    main()
