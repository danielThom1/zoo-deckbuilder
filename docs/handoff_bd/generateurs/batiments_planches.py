"""Découpe les images de bâtiments (fond magenta, un bâtiment par image, fichier au nom du sprite).

  python batiments_planches.py "<dossier des images>" <racine du dépôt>

Écrit game/assets/bd/sprites/batiments/<nom>.png et complète le manifeste sprites_bd.json.
"""
import glob, json, os, sys
from collections import deque
import numpy as np
from PIL import Image

LARGEUR = 460  # les bâtiments sont réduits à cette largeur (assez pour le zoom maximal)
LARGEUR_DECO = 180  # une décoration occupe une seule case


def sans_fond(rgb):
    """Fond magenta : rouge et bleu forts, vert presque nul. Le dégradé d'une image à l'autre ne change pas ce critère."""
    r, v, b = [rgb[:, :, k].astype(np.int32) for k in range(3)]
    magenta = (v < 70) & (r > 170) & (b > 150)
    h, w = magenta.shape
    vu = np.zeros((h, w), bool)
    file = deque()
    for x in range(w):
        for y in (0, h - 1):
            if magenta[y, x] and not vu[y, x]:
                vu[y, x] = True
                file.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if magenta[y, x] and not vu[y, x]:
                vu[y, x] = True
                file.append((y, x))
    while file:
        y, x = file.popleft()
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < h and 0 <= nx < w and magenta[ny, nx] and not vu[ny, nx]:
                vu[ny, nx] = True
                file.append((ny, nx))
    # Trous fermés (sous une enseigne, entre les planches d'une palissade) : ce magenta franc n'existe sur aucun bâtiment
    transparent = vu | magenta
    alpha = np.where(transparent, 0.0, 255.0)
    # Bord adouci et débarrassé du rose : le pourtour est un trait d'encre mêlé au fond
    pres = transparent.copy()
    for _ in range(2):
        pres[1:-1, 1:-1] |= pres[:-2, 1:-1] | pres[2:, 1:-1] | pres[1:-1, :-2] | pres[1:-1, 2:]
    sortie = rgb.astype(np.float32).copy()
    rose = pres & (r > v + 30) & (b > v + 30)
    sortie[:, :, 0] = np.where(rose, np.minimum(sortie[:, :, 0], sortie[:, :, 1] + 30), sortie[:, :, 0])
    sortie[:, :, 2] = np.where(rose, np.minimum(sortie[:, :, 2], sortie[:, :, 1] + 30), sortie[:, :, 2])
    return Image.fromarray(np.dstack([np.clip(sortie, 0, 255), alpha]).astype(np.uint8), 'RGBA')


def main():
    src, racine = sys.argv[1], sys.argv[2]
    sortie = os.path.join(racine, 'game', 'assets', 'bd', 'sprites', 'batiments')
    manifeste_p = os.path.join(racine, 'game', 'assets', 'bd', 'sprites_bd.json')
    manifeste = json.load(open(manifeste_p, encoding='utf-8'))
    for chemin in sorted(glob.glob(os.path.join(src, '**', '*.png'), recursive=True)):
        nom = os.path.splitext(os.path.basename(chemin))[0].lower()
        im = sans_fond(np.array(Image.open(chemin).convert('RGB')))
        im = im.crop(im.getchannel('A').point(lambda a: 255 if a > 127 else 0).getbbox())
        large = LARGEUR_DECO if nom.startswith('deco_') else LARGEUR
        k = large / im.width
        im = im.convert('RGBa').resize((large, round(im.height * k)), Image.LANCZOS).convert('RGBA')
        im.save(os.path.join(sortie, nom + '.png'), optimize=True)
        manifeste[nom] = {"categorie": "batiments", "fichier": "res://assets/bd/sprites/batiments/%s.png" % nom,
                          "pied": [im.width // 2, im.height], "taille": [im.width, im.height]}
        print(nom, im.size)
    json.dump(manifeste, open(manifeste_p, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
