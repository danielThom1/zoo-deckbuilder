"""Découpe les planches de clôtures (fond magenta, 3 pièces de gauche à droite : tronçon de face, tronçon en long, poteau).

  python clotures_planches.py "<dossier des images>" <racine du dépôt>

Fichier au nom du style : enceinte.png, enclos_herbivore.png, enclos_predateur.png…
Écrit game/assets/bd/sprites/clotures/<style>_face.png, _long.png, _poteau.png et complète sprites_bd.json.
Les bouts des tronçons sont recoupés pour retirer leur trait d'encre : posés bout à bout, ils ne laissent pas de raccord noir.
"""
import glob, json, os, sys
from collections import deque
import numpy as np
from PIL import Image

LARGEUR_FACE = 160  # largeur d'un tronçon de face, soit une case à l'écran (assez pour le zoom maximal)
RECOUPE = 0.022  # part de la longueur retirée à chaque bout d'un tronçon


def masque_magenta(rgb):
    r, v, b = [rgb[:, :, k].astype(np.int32) for k in range(3)]
    return (v < 70) & (r > 170) & (b > 150)


def pieces(masque):
    """Boîtes des 3 plus grands blocs, de gauche à droite (les colonnes vides séparent les pièces)."""
    colonnes = (~masque).sum(axis=0) > 2
    blocs = []
    debut = None
    for x, plein in enumerate(colonnes):
        if plein and debut is None:
            debut = x
        elif not plein and debut is not None:
            blocs.append((debut, x))
            debut = None
    if debut is not None:
        blocs.append((debut, len(colonnes)))
    # Un trou d'une colonne ou deux n'est pas une séparation
    fusion = []
    for b in blocs:
        if fusion and b[0] - fusion[-1][1] < 12:
            fusion[-1] = (fusion[-1][0], b[1])
        else:
            fusion.append(b)
    fusion.sort(key=lambda b: b[1] - b[0], reverse=True)
    garde = sorted(fusion[:3])
    assert len(garde) == 3, "3 pièces attendues, %d trouvées" % len(fusion)
    boites = []
    for a, b in garde:
        lignes = np.where((~masque[:, a:b]).sum(axis=1) > 0)[0]
        boites.append((a, int(lignes[0]), b, int(lignes[-1]) + 1))
    return boites


def rgba(rgb, masque):
    pres = masque.copy()
    for _ in range(2):
        pres[1:-1, 1:-1] |= pres[:-2, 1:-1] | pres[2:, 1:-1] | pres[1:-1, :-2] | pres[1:-1, 2:]
    r, v, b = [rgb[:, :, k].astype(np.int32) for k in range(3)]
    sortie = rgb.astype(np.float32).copy()
    rose = pres & (r > v + 30) & (b > v + 30)
    sortie[:, :, 0] = np.where(rose, np.minimum(sortie[:, :, 0], sortie[:, :, 1] + 30), sortie[:, :, 0])
    sortie[:, :, 2] = np.where(rose, np.minimum(sortie[:, :, 2], sortie[:, :, 1] + 30), sortie[:, :, 2])
    return Image.fromarray(np.dstack([np.clip(sortie, 0, 255), np.where(masque, 0.0, 255.0)]).astype(np.uint8), 'RGBA')


def reduit(im, l, h):
    return im.convert('RGBa').resize((max(1, l), max(1, h)), Image.LANCZOS).convert('RGBA')


def main():
    src, racine = sys.argv[1], sys.argv[2]
    sortie = os.path.join(racine, 'game', 'assets', 'bd', 'sprites', 'clotures')
    os.makedirs(sortie, exist_ok=True)
    manifeste_p = os.path.join(racine, 'game', 'assets', 'bd', 'sprites_bd.json')
    manifeste = json.load(open(manifeste_p, encoding='utf-8'))
    for chemin in sorted(glob.glob(os.path.join(src, '**', '*.png'), recursive=True)):
        style = os.path.splitext(os.path.basename(chemin))[0].lower()
        if not (style == 'enceinte' or style.startswith('enclos')):
            continue
        rgb = np.array(Image.open(chemin).convert('RGB'))
        masque = masque_magenta(rgb)
        image = rgba(rgb, masque)
        face, long_, poteau = pieces(masque)
        # Échelle commune : la longueur d'un tronçon de face vaut une case
        rx = int((face[2] - face[0]) * RECOUPE)
        face = (face[0] + rx, face[1], face[2] - rx, face[3])
        ry = int((long_[3] - long_[1]) * RECOUPE)
        long_ = (long_[0], long_[1] + ry, long_[2], long_[3] - ry)
        k = LARGEUR_FACE / (face[2] - face[0])
        k_long = LARGEUR_FACE / (long_[3] - long_[1])
        rendu = {
            'face': reduit(image.crop(face), LARGEUR_FACE, round((face[3] - face[1]) * k)),
            'long': reduit(image.crop(long_), round((long_[2] - long_[0]) * k_long), LARGEUR_FACE),
            'poteau': reduit(image.crop(poteau), round((poteau[2] - poteau[0]) * k), round((poteau[3] - poteau[1]) * k)),
        }
        for piece, im in rendu.items():
            nom = 'cl_%s_%s' % (style, piece)
            im.save(os.path.join(sortie, nom + '.png'), optimize=True)
            manifeste[nom] = {"categorie": "clotures", "fichier": "res://assets/bd/sprites/clotures/%s.png" % nom,
                              "pied": [im.width // 2, im.height], "taille": [im.width, im.height]}
            print(nom, im.size)
    json.dump(manifeste, open(manifeste_p, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
