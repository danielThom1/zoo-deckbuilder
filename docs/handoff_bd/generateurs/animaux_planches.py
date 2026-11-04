"""Découpe les planches d'animaux (zip « Planche animaux ») : pour chaque espèce, le portrait encadré et les images
d'animation, avec fond transparent, dans game/assets/bd/sprites/animaux_v2/, et met à jour sprites_bd.json.
Usage : python animaux_planches.py <dossier des planches> <dossier game>"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as nd

src, game = sys.argv[1], sys.argv[2]
out = os.path.join(game, 'assets/bd/sprites/animaux_v2')
os.makedirs(out, exist_ok=True)
fs = sorted(glob.glob(os.path.join(src, '*.png')))
# indice de planche (ordre alphabétique) -> espèces par rangée (None : rangée ignorée)
SPEC = {
    0: ['panda', 'loutre_cendree', 'paon', 'salamandre', 'calao'],
    1: ['grue_japon', 'yak', 'hippopotame', 'guepard', 'girafe'],
    2: [None, 'bouquetin', 'mesange', None, None, 'dauphin_rose'],
    4: ['bison_europe', 'lynx', 'loutre_europe', 'loup', 'phoque'],
    5: ['puma', 'ocelot', 'ara', None, 'tapir'],
    6: ['jaguar', 'alligator', None, 'lion', 'tigre', None],
    7: ['faucon', 'cerf', 'leopard_neiges', None],
    9: ['pygargue', 'bison_amerique', None, None],
    10: ['manchot', 'koi', 'capybara', 'aigle_royal', 'zebre'],
    12: ['loutre_joues_blanches', 'hyene', 'grue_couronnee', 'messager', None],
}
LARGEUR_MAX = 240  # images d'animation réduites (le jeu les affiche petites)
manifest_path = os.path.join(game, 'assets/bd/sprites_bd.json')
manifest = json.load(open(manifest_path, encoding='utf-8'))


def masque(im):
    a = np.array(im.convert('RGBA'))
    if Image.open(im.filename).mode == 'RGBA':
        return a, a[:, :, 3] > 40
    rgb = a[:, :, :3].astype(int)
    clair = (rgb.min(axis=2) >= 222) & (rgb.max(axis=2) - rgb.min(axis=2) < 20)
    lab, _ = nd.label(clair)
    bord = set(lab[0, :]) | set(lab[-1, :]) | set(lab[:, 0]) | set(lab[:, -1])
    bord.discard(0)
    fond = np.isin(lab, list(bord))
    # Fond enfermé entre les pattes : blanc parfaitement neutre (les pelages et plumages blancs sont teintés ou ombrés)
    tailles = nd.sum(clair, lab, range(1, lab.max() + 1))
    moy = nd.mean(rgb.max(axis=2) - rgb.min(axis=2), lab, range(1, lab.max() + 1))
    mini = nd.mean(rgb.min(axis=2), lab, range(1, lab.max() + 1))
    trous = [k + 1 for k in range(len(tailles)) if tailles[k] >= 25 and moy[k] < 3.0 and mini[k] > 238]
    fond |= np.isin(lab, trous)
    fg = nd.binary_erosion(~fond, iterations=1)  # retire le liseré clair du détourage
    return a, fg


def sauver(a, m, nom, largeur_max=None):
    ys, xs = np.nonzero(m)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    c = a[y0:y1, x0:x1].copy()
    c[:, :, 3] = np.where(m[y0:y1, x0:x1], np.maximum(c[:, :, 3], 255 if c[:, :, 3].max() == 255 else 0), 0)
    img = Image.fromarray(c, 'RGBA')
    if largeur_max and img.size[0] > largeur_max:
        img = img.resize((largeur_max, round(img.size[1] * largeur_max / img.size[0])), Image.LANCZOS)
    img.save(os.path.join(out, nom + '.png'), optimize=True)
    w, h = img.size
    manifest[nom] = {'categorie': 'animaux', 'fichier': 'res://assets/bd/sprites/animaux_v2/%s.png' % nom, 'pied': [w // 2, h], 'taille': [w, h]}


for i, ids in SPEC.items():
    im = Image.open(fs[i])
    a, fg = masque(im)
    # Colonne des portraits : à gauche, jusqu'à la première colonne vide (les cadres peuvent presque se toucher)
    proj = fg.sum(axis=0)
    fin = next(x for x in range(60, fg.shape[1]) if proj[x] == 0)
    col = fg.copy()
    col[:, fin:] = False
    lc, nc = nd.label(col)
    tc = nd.sum(col, lc, range(1, nc + 1))
    cadres = sorted([k + 1 for k, t in enumerate(tc) if t > 2500], key=lambda k: nd.find_objects(lc)[k - 1][0].start)
    assert len(cadres) == len(ids), (i, len(cadres))
    oc = nd.find_objects(lc)
    centres_y = [(oc[k - 1][0].start + oc[k - 1][0].stop) / 2 for k in cadres]
    # Images d'animation : blocs (les petits morceaux, éclaboussures, sont ignorés) rangés selon le cadre le plus proche
    reste = fg.copy()
    reste[:, :fin] = False
    lab, n = nd.label(nd.binary_dilation(reste, iterations=3))
    tailles = nd.sum(reste, lab, range(1, n + 1))
    objets = nd.find_objects(lab)
    rangs = [[] for _ in ids]
    for k, t in enumerate(tailles):
        if t > 2500:
            yc = (objets[k][0].start + objets[k][0].stop) / 2
            rangs[min(range(len(ids)), key=lambda r: abs(centres_y[r] - yc))].append(k + 1)
    print(os.path.basename(fs[i]).encode('ascii', 'replace').decode(), [len(r) for r in rangs])
    for r, espece in enumerate(ids):
        if espece is None:
            continue
        sauver(a, col & (lc == cadres[r]), espece + '_tete')
        for f, k in enumerate(sorted(rangs[r], key=lambda k: objets[k - 1][1].start)):
            sauver(a, reste & (lab == k), espece if f == 0 else '%s_f%d' % (espece, f + 1), LARGEUR_MAX)
json.dump(manifest, open(manifest_path, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=1, sort_keys=True)
print('ok')
