"""Découpe les planches de personnages (fond vert : portrait + 4 rangées de 3 images : marcher, construire, couper, miner).

  python personnages_planches.py "<dossier des planches>" <racine du dépôt> [--controle=dossier]

Écrit game/assets/bd/sprites/personnages_v2/<id>.png (feuille de 3 colonnes x 4 rangées), <id>_portrait.png,
game/data/personnages.json et complète le manifeste sprites_bd.json.
Dans chaque image, le pied du personnage est au même point (PIED) : l'animation ne saute pas.
"""
import glob, json, os, sys
from collections import deque
import numpy as np
from PIL import Image

# Cellule de la feuille : un personnage en marche mesure HAUTEUR pixels, ses pieds sont en PIED
CELLULE = (220, 150)
HAUTEUR = 96
PIED = (90, 144)
PORTRAIT_H = 200

# Nom du fichier (début) -> identifiant, nom, genre. Rien ne dépend de l'ordre de lecture.
FICHES = [
    ("Feuille de sprites d’une ouvrière âgée", "odette", "Odette", "f"),
    ("Feuille d’animation d’un bâtisseur robuste", "malik", "Malik", "m"),
    ("Fiche de sprites d’un aventurier travailleur", "hugo", "Hugo", "m"),
    ("Planche de sprite d’un ingénieur grisonnant", "victor", "Victor", "m"),
    ("Planche de sprites _ grand-mère bâtisseuse", "rose", "Rose", "f"),
    ("Planche de sprites _ mineur roux en action", "basile", "Basile", "m"),
    ("Planche de sprites _ ouvrière en action", "ines", "Inès", "f"),
    ("Planche de sprites animés de bâtisseuse", "aicha", "Aïcha", "f"),
    ("Planche de sprites de mineur barbu", "mamadou", "Mamadou", "m"),
    ("Planche de sprites du mineur chromatique", "igor", "Igor", "m"),
    ("Planche de sprites du vieux bâtisseur", "marcel", "Marcel", "m"),
    ("Planche de sprites du vieux mineur artisanal", "louis", "Louis", "m"),
    ("Planche de sprites d’aventurière blonde polyvalente", "clara", "Clara", "f"),
    ("Planche de sprites d’exploratrice aventurière", "lea", "Léa", "f"),
    ("Planche de sprites d’un bâtisseur aventurier", "noah", "Noah", "m"),
    ("Planche de sprites d’un bâtisseur barbu", "adam", "Adam", "m"),
    ("Planche de sprites d’un jeune bâtisseur", "tom", "Tom", "m"),
    ("Planche de sprites d’un mineur robuste", "paul", "Paul", "m"),
    ("Planche de sprites d’un ouvrier en bleu", "gabin", "Gabin", "m"),
    ("Planche de sprites d’un vieux bâtisseur (1)", "jules", "Jules", "m"),
    ("Planche de sprites d’un vieux bâtisseur", "samir", "Samir", "m"),
    ("Planche de sprites d’une ouvrière aventurière", "jade", "Jade", "f"),
    ("Planche de sprites pixel art sur fond vert", "omar", "Omar", "m"),
    ("Planche d’animation d’aventurière rousse", "margaux", "Margaux", "f"),
    ("Planche d’animation d’ouvrière en action", "emma", "Emma", "f"),
    ("Planche d’animation d’une bûcheronne souriante", "manon", "Manon", "f"),
    ("Planche d’animation _ aventurière au travail", "yasmine", "Yasmine", "f"),
    ("Planche d’animation _ travailleuse rustique au piolet", "fatou", "Fatou", "f"),
]


def fond_transparent(rgb):
    """Alpha par éloignement du fond : le fond touchant les bords (tolérant), puis les trous fermés (strict)."""
    h, w, _ = rgb.shape
    coins = np.concatenate([rgb[:12, :12].reshape(-1, 3), rgb[:12, -12:].reshape(-1, 3), rgb[-12:, :12].reshape(-1, 3), rgb[-12:, -12:].reshape(-1, 3)])
    fond = np.median(coins, axis=0)
    dist = np.sqrt(((rgb.astype(np.float32) - fond) ** 2).sum(axis=2))
    tol, strict = 62.0, 34.0
    candidat = dist < tol
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
    # Le vert du fond reste parfois enfermé dans les cheveux : aucun habit n'a ce vert franc
    r, v, b = rgb[:, :, 0].astype(np.int32), rgb[:, :, 1].astype(np.int32), rgb[:, :, 2].astype(np.int32)
    transparent = vu | (dist < strict) | ((v > 130) & (v - r > 60) & (v - b > 40))
    # Bord adouci, et le vert retiré des pixels de bord
    alpha = np.where(transparent, 0.0, 1.0)
    bord = np.zeros((h, w), bool)
    bord[1:-1, 1:-1] = (~transparent[1:-1, 1:-1]) & (transparent[:-2, 1:-1] | transparent[2:, 1:-1] | transparent[1:-1, :-2] | transparent[1:-1, 2:])
    alpha[bord] = np.clip((dist[bord] - strict) / (tol + 40.0 - strict), 0.25, 1.0)
    sortie = rgb.astype(np.float32).copy()
    vert_max = np.maximum(sortie[:, :, 0], sortie[:, :, 2])
    # Liseré vert : sur 3 pixels autour du fond, le vert ne dépasse plus les autres couleurs
    pres = transparent.copy()
    for _ in range(3):
        pres[1:-1, 1:-1] |= pres[:-2, 1:-1] | pres[2:, 1:-1] | pres[1:-1, :-2] | pres[1:-1, 2:]
    sortie[:, :, 1] = np.where(pres & (sortie[:, :, 1] > vert_max + 4.0), vert_max + 4.0, sortie[:, :, 1])
    return sortie, alpha


def lignes_de_sol(masque, x0):
    """Les 4 traits de sol, (haut, bas) de chacun. La marche est seule et suivie d'une ligne vide : son sol est le bas de
    la bande (ses bras écartés sont parfois plus larges que son trait). Pour les 3 autres rangées, où les outils se
    rejoignent, le trait est la ligne la plus large de chaque rangée."""
    largeur = masque[:, x0:].sum(axis=1).astype(float)
    h = len(largeur)
    ys = np.where(largeur > 2)[0]
    y = ys[0] + int((ys[-1] - ys[0]) * 0.15)
    while y < h and largeur[y] > 2:
        y += 1
    bas0 = y - 1
    haut0 = bas0
    while haut0 > 0 and bas0 - haut0 < 4 and largeur[haut0 - 1] >= largeur[bas0] * 0.7:
        haut0 -= 1
    sols = [(haut0, bas0)]
    ecart = (ys[-1] - bas0) / 3.0 * 0.6
    pics = []
    for v in np.argsort(-largeur):
        v = int(v)
        if v > bas0 + 20 and all(abs(v - q) >= ecart for q in pics):
            pics.append(v)
            if len(pics) == 3:
                break
    for v in sorted(pics):
        # Le trait fait quelques pixels ; au-dessus commencent les bottes, moins larges
        haut = v
        while haut > 0 and v - haut < 8 and largeur[haut - 1] >= largeur[v] * 0.75:
            haut -= 1
        bas = v
        while bas < h - 1 and bas - v < 8 and largeur[bas + 1] >= largeur[v] * 0.45:
            bas += 1
        sols.append((haut, bas))
    return sols


def trois_images(masque, y0, y1, x0):
    """Colonnes des 3 images d'une rangée : les images sont à intervalles réguliers, on coupe aux vides les plus
    proches du tiers et des deux tiers (une gerbe d'éclats laisse aussi des vides, mais à l'intérieur d'une image)."""
    proj = masque[y0:y1, x0:].sum(axis=0) > 0
    xs = np.where(proj)[0]
    if len(xs) == 0:
        return []
    deb, fin = xs[0], xs[-1]
    vides = []
    i = deb
    while i <= fin:
        if not proj[i]:
            j = i
            while j <= fin and not proj[j]:
                j += 1
            if j - i >= 3:
                vides.append((i, j))
            i = j
        else:
            i += 1
    if len(vides) < 2:
        return []
    coupes = []
    for part in (1.0 / 3.0, 2.0 / 3.0):
        cible = deb + (fin - deb) * part
        coupes.append(min(vides, key=lambda v: abs((v[0] + v[1]) / 2.0 - cible)))
    if coupes[0] == coupes[1]:
        return []
    return [(x0 + deb, x0 + coupes[0][0]), (x0 + coupes[0][1], x0 + coupes[1][0]), (x0 + coupes[1][1], x0 + fin + 1)]


def decouper(chemin, fiche_id):
    rgb = np.array(Image.open(chemin).convert('RGB'))
    couleurs, alpha = fond_transparent(rgb)
    masque = alpha > 0.5
    h, w = masque.shape
    # Portrait : tout ce qui est à gauche du premier grand vide vertical de la moitié haute
    proj = masque[:h // 2].sum(axis=0) > 0
    x = np.where(proj)[0][0]
    while x < w and proj[x]:
        x += 1
    x_portrait = x
    # Quelques pixels parasites ne comptent pas dans le cadre du portrait
    ys = np.where(masque[:, :x_portrait].sum(axis=1) > 6)[0]
    xs = np.where(masque[:, :x_portrait].sum(axis=0) > 6)[0]
    rgba = np.dstack([np.clip(couleurs, 0, 255), alpha * 255.0]).astype(np.uint8)
    portrait = Image.fromarray(rgba[ys[0]:ys[-1] + 1, xs[0]:xs[-1] + 1], 'RGBA')
    sols = lignes_de_sol(masque, x_portrait)
    if len(sols) != 4:
        raise ValueError('%s : %d lignes de sol %s' % (fiche_id, len(sols), sols))
    images = []
    y_prec = 0
    for r, (sol, sol_bas) in enumerate(sols):
        # Au-dessus du trait pour trouver les colonnes (les traits se touchent parfois)
        cols = trois_images(masque, y_prec, sol - 1, x_portrait)
        if len(cols) != 3:
            raise ValueError('%s : rangée %d, %d colonnes' % (fiche_id, r, len(cols)))
        for c0, c1 in cols:
            bloc = masque[y_prec:sol, c0:c1]
            yy = np.where(bloc.sum(axis=1) > 0)[0]
            haut = y_prec + yy[0]
            images.append((r, c0, c1, haut, sol))
        # Reste du trait de sol (les plus épais) : aucun outil levé n'est aussi large
        largeur = masque[:, x_portrait:].sum(axis=1)
        y_prec = sol_bas + 1
        while y_prec < h - 1 and y_prec - sol_bas < 16 and largeur[y_prec] > largeur[sol_bas] * 0.2:
            y_prec += 1
        y_prec += 1
    # Taille de référence : le corps en marche (rangée 0)
    marche = [i for i in images if i[0] == 0]
    corps = float(np.median([i[4] - i[3] for i in marche]))
    k = HAUTEUR / corps
    feuille = Image.new('RGBA', (CELLULE[0] * 3, CELLULE[1] * 4), (0, 0, 0, 0))
    deborde = 0
    for n, (r, c0, c1, haut, sol) in enumerate(images):
        cellule = rgba[haut:sol, c0:c1].copy()
        m = cellule[:, :, 3] > 127
        ch, cw = m.shape
        # Pied : le talon arrière, le plus à gauche des pieds dans le bas de l'image, sans les outils levés
        bas = m[int(ch * 0.82):]
        colonnes = np.where(bas.sum(axis=0) > 0)[0]
        talon = colonnes[0] if len(colonnes) else 0
        im = Image.fromarray(cellule, 'RGBA').convert('RGBa')
        nw, nh = max(1, round(cw * k)), max(1, round(ch * k))
        im = im.resize((nw, nh), Image.LANCZOS).convert('RGBA')
        cx = (n % 3) * CELLULE[0]
        cy = (n // 3) * CELLULE[1]
        px = PIED[0] - round(HAUTEUR * 0.30) - round(talon * k)
        py = PIED[1] - nh
        if px < 0 or py < 0 or px + nw > CELLULE[0] or py + nh > CELLULE[1]:
            deborde += 1
        boite = Image.new('RGBA', CELLULE, (0, 0, 0, 0))
        boite.paste(im, (px, py), im)
        feuille.paste(boite, (cx, cy))
    p_k = PORTRAIT_H / portrait.height
    portrait = portrait.convert('RGBa').resize((round(portrait.width * p_k), PORTRAIT_H), Image.LANCZOS).convert('RGBA')
    return feuille, portrait, deborde


def main():
    src, racine = sys.argv[1], sys.argv[2]
    controle = next((a.split('=', 1)[1] for a in sys.argv[3:] if a.startswith('--controle=')), '')
    fichiers = glob.glob(os.path.join(src, '**', '*.png'), recursive=True)
    sortie = os.path.join(racine, 'game', 'assets', 'bd', 'sprites', 'personnages_v2')
    os.makedirs(sortie, exist_ok=True)
    manifeste_p = os.path.join(racine, 'game', 'assets', 'bd', 'sprites_bd.json')
    manifeste = json.load(open(manifeste_p, encoding='utf-8'))
    persos = []
    feuilles = []
    # Les noms les plus longs d'abord : « vieux bâtisseur (1) » avant « vieux bâtisseur »
    for debut, pid, nom, genre in sorted(FICHES, key=lambda f: -len(f[0])):
        trouve = [f for f in fichiers if os.path.basename(f).startswith(debut)]
        if not trouve:
            raise SystemExit('Planche absente : ' + debut.encode('ascii', 'replace').decode())
        chemin = trouve[0]
        fichiers.remove(chemin)
        feuille, portrait, deborde = decouper(chemin, pid)
        feuille.save(os.path.join(sortie, pid + '.png'), optimize=True)
        portrait.save(os.path.join(sortie, pid + '_portrait.png'), optimize=True)
        manifeste['pv2_' + pid] = {"categorie": "personnages", "fichier": "res://assets/bd/sprites/personnages_v2/%s_portrait.png" % pid,
                                   "pied": [portrait.width // 2, portrait.height], "taille": [portrait.width, portrait.height]}
        persos.append({"id": pid, "nom": nom, "genre": genre})
        feuilles.append((pid, feuille, portrait))
        if deborde:
            print(pid, 'images qui débordent de la cellule :', deborde)
    persos.sort(key=lambda p: p["id"])
    json.dump({"_note": "Personnages des planches : docs/handoff_bd/generateurs/personnages_planches.py. Chacun a un portrait et une feuille d'animation (assets/bd/sprites/personnages_v2).", "personnages": persos},
              open(os.path.join(racine, 'game', 'data', 'personnages.json'), 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=2)
    json.dump(manifeste, open(manifeste_p, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=1)
    if controle:
        os.makedirs(controle, exist_ok=True)
        feuilles.sort(key=lambda f: f[0])
        W = 330
        H = 300
        M = Image.new('RGB', (W * 7, H * 4), (214, 226, 196))
        for i, (pid, f, p) in enumerate(feuilles):
            r = f.resize((W, H), Image.LANCZOS)
            M.paste(r, ((i % 7) * W, (i // 7) * H), r)
        M.save(os.path.join(controle, 'feuilles.jpg'), quality=82)
        M = Image.new('RGB', (160 * 7, 170 * 4), (191, 230, 223))
        for i, (pid, f, p) in enumerate(feuilles):
            r = p.resize((round(p.width * 160 / p.height), 160), Image.LANCZOS)
            M.paste(r, ((i % 7) * 160 + max(0, (160 - r.width) // 2), (i // 7) * 170), r)
        M.save(os.path.join(controle, 'portraits.jpg'), quality=85)
    print(len(persos), 'personnages')


if __name__ == '__main__':
    main()
