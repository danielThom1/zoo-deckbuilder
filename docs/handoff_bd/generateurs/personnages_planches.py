"""Découpe les planches de personnages (fond vert : portrait, puis rangées de 3 images).

  python personnages_planches.py "<dossier des planches>" <racine du dépôt> [--controle=dossier]

Chaque planche porte le prénom du personnage (Fatou.png, Élise.webp). Deux formats, reconnus d'après l'image :
  portrait : 8 rangées (marcher, construire, couper, miner, servir, nourrir, balayer, soigner) ;
  paysage : 4 rangées (les 4 premières), le format des premières planches.
Écrit game/assets/bd/sprites/personnages_v2/<id>.png (3 colonnes), <id>_portrait.png, complète le manifeste
sprites_bd.json et réécrit game/data/personnages.json d'après toutes les feuilles présentes : une nouvelle planche
remplace celle du même personnage, les autres restent.
Dans chaque image, le pied du personnage est au même point (PIED) : l'animation ne saute pas.
"""
import glob, json, os, sys, unicodedata
from collections import deque
import numpy as np
from PIL import Image

# Cellule de la feuille : un personnage en marche mesure HAUTEUR pixels, ses pieds sont en PIED
CELLULE = (220, 150)
HAUTEUR = 96
PIED = (90, 144)
PORTRAIT_H = 200

# Les 40 personnages : prénom affiché -> genre. L'identifiant est le prénom en minuscules, sans accent.
PERSONNAGES = {
    "Élise": "f", "Nadia": "f", "Chloé": "f", "Zoé": "f", "Odette": "f", "Lina": "f", "Fatou": "f", "Rose": "f", "Inès": "f", "Jade": "f",
    "Margaux": "f", "Sarah": "f", "Aïcha": "f", "Yasmine": "f", "Clara": "f", "Manon": "f", "Emma": "f", "Lucie": "f", "Camille": "f", "Léa": "f",
    "Victor": "m", "Louis": "m", "Marcel": "m", "Basile": "m", "Kenji": "m", "Paul": "m", "Hugo": "m", "Mamadou": "m", "Igor": "m", "Samir": "m",
    "Théo": "m", "Bastien": "m", "Omar": "m", "Noah": "m", "Gabin": "m", "Malik": "m", "Jules": "m", "Nathan": "m", "Adam": "m", "Tom": "m",
}


def identifiant(nom):
    n = unicodedata.normalize('NFD', nom)
    return ''.join(c for c in n if unicodedata.category(c) != 'Mn').lower().strip()


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


def lignes_de_sol(masque, x0, x_gauche, rangees):
    """Les traits de sol, (haut, bas) de chacun. Quand les rangées sont séparées par du vide, le sol est le bas de
    chaque bande. Sinon (outils levés qui touchent la rangée du dessus), la marche reste seule en bande et, pour les
    autres, le trait est la ligne la plus large de la rangée."""
    largeur = masque[:, x0:].sum(axis=1).astype(float)
    h = len(largeur)
    ys = np.where(largeur > 2)[0]
    bandes = []
    y = ys[0]
    while y < h:
        if largeur[y] > 2:
            d = y
            while y < h and largeur[y] > 2:
                y += 1
            if y - d > 25:
                bandes.append((d, y - 1))
        else:
            y += 1
    if len(bandes) == rangees:
        sols = []
        for _, bas in bandes:
            haut = bas
            while haut > 0 and bas - haut < 6 and largeur[haut - 1] >= largeur[bas] * 0.6:
                haut -= 1
            sols.append((haut, bas))
        return sols
    bas0 = bandes[0][1]
    haut0 = bas0
    while haut0 > 0 and bas0 - haut0 < 4 and largeur[haut0 - 1] >= largeur[bas0] * 0.7:
        haut0 -= 1
    sols = [(haut0, bas0)]
    ecart = (ys[-1] - bas0) / float(rangees - 1) * 0.6
    pics = []
    for v in np.argsort(-largeur):
        v = int(v)
        if v > bas0 + 20 and all(abs(v - q) >= ecart for q in pics):
            pics.append(v)
            if len(pics) == rangees - 1:
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


def cadre_portrait(masque):
    """Le portrait est en haut à gauche : sa largeur se lit à la hauteur de la tête, sa hauteur à la première ligne vide,
    puis sa vraie largeur (épaules comprises) sur toute cette hauteur."""
    h, w = masque.shape
    proj = masque[:h // 6].sum(axis=0) > 0
    x = np.where(proj)[0][0]
    while x < w and proj[x]:
        x += 1
    lignes = masque[:, :x].sum(axis=1) > 6
    ys = np.where(lignes)[0]
    y = ys[0]
    vide = 0
    while y < h and vide < 6:
        vide = 0 if lignes[y] else vide + 1
        y += 1
    y_fin = y - vide
    proj = masque[ys[0]:y_fin].sum(axis=0) > 2
    x = np.where(proj)[0][0]
    while x < w and proj[x]:
        x += 1
    return x, ys[0], y_fin


def talon_de(cellule, m):
    """Le talon arrière : la colonne la plus à gauche, dans le bas de l'image, où la chaussure fait un bloc sombre.
    La poussière du balai et les éclats sont clairs ou clairsemés et ne comptent pas."""
    ch = m.shape[0]
    d = int(ch * 0.86)
    lum = cellule[d:, :, :3].astype(np.float32).mean(axis=2)
    sombre = ((lum < 75) & m[d:]).sum(axis=0)  # une chaussure : le manche et la paille du balai sont plus clairs
    colonnes = np.where(sombre >= max(3, (ch - d) * 0.3))[0]
    if len(colonnes):
        return colonnes[0]
    colonnes = np.where(m[d:].sum(axis=0) > 0)[0]
    return colonnes[0] if len(colonnes) else 0


def decouper(chemin, fiche_id):
    rgb = np.array(Image.open(chemin).convert('RGB'))
    rangees = 8 if rgb.shape[0] > rgb.shape[1] else 4
    couleurs, alpha = fond_transparent(rgb)
    masque = alpha > 0.5
    h, w = masque.shape
    x_portrait, y_p0, y_p1 = cadre_portrait(masque)
    rgba = np.dstack([np.clip(couleurs, 0, 255), alpha * 255.0]).astype(np.uint8)
    zone = masque[y_p0:y_p1, :x_portrait]
    ys = np.where(zone.sum(axis=1) > 6)[0] + y_p0
    xs = np.where(zone.sum(axis=0) > 6)[0]
    portrait = Image.fromarray(rgba[ys[0]:ys[-1] + 1, xs[0]:xs[-1] + 1], 'RGBA')
    # Sous le portrait, les rangées peuvent déborder à gauche (poussière du balai) : le sol se cherche à droite du portrait
    sols = lignes_de_sol(masque, x_portrait, 0, rangees)
    if len(sols) != rangees:
        raise ValueError('%s : %d lignes de sol %s' % (fiche_id, len(sols), sols))
    images = []
    y_prec = 0
    largeur = masque[:, x_portrait:].sum(axis=1)
    for r, (sol, sol_bas) in enumerate(sols):
        x0 = x_portrait if y_prec < y_p1 else 0
        cols = trois_images(masque, y_prec, sol - 1, x0)
        if len(cols) != 3:
            raise ValueError('%s : rangée %d, %d colonnes' % (fiche_id, r, len(cols)))
        for c0, c1 in cols:
            bloc = masque[y_prec:sol, c0:c1]
            yy = np.where(bloc.sum(axis=1) > 0)[0]
            haut = y_prec + yy[0]
            images.append((r, c0, c1, haut, sol))
        # Reste du trait de sol (les plus épais) : aucun outil levé n'est aussi large
        y_prec = sol_bas + 1
        while y_prec < h - 1 and y_prec - sol_bas < 16 and largeur[y_prec] > largeur[sol_bas] * 0.2:
            y_prec += 1
        y_prec += 1
    # Taille de référence : le corps en marche (rangée 0)
    marche = [i for i in images if i[0] == 0]
    corps = float(np.median([i[4] - i[3] for i in marche]))
    k = HAUTEUR / corps
    feuille = Image.new('RGBA', (CELLULE[0] * 3, CELLULE[1] * rangees), (0, 0, 0, 0))
    deborde = 0
    for n, (r, c0, c1, haut, sol) in enumerate(images):
        cellule = rgba[haut:sol, c0:c1].copy()
        m = cellule[:, :, 3] > 127
        ch, cw = m.shape
        # Morceaux du trait de sol à côté des pieds : tout en bas, avec du vide juste au-dessus
        rien_dessus = m[max(0, ch - 16):max(1, ch - 6)].sum(axis=0) == 0
        cellule[ch - 6:, rien_dessus, 3] = 0
        m = cellule[:, :, 3] > 127
        talon = talon_de(cellule, m)
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
    fichiers = [f for f in glob.glob(os.path.join(src, '**', '*'), recursive=True) if f.lower().endswith(('.png', '.webp', '.jpg', '.jpeg'))]
    sortie = os.path.join(racine, 'game', 'assets', 'bd', 'sprites', 'personnages_v2')
    os.makedirs(sortie, exist_ok=True)
    manifeste_p = os.path.join(racine, 'game', 'assets', 'bd', 'sprites_bd.json')
    manifeste = json.load(open(manifeste_p, encoding='utf-8'))
    connus = {identifiant(nom): nom for nom in PERSONNAGES}
    faits = []
    for chemin in sorted(fichiers):
        pid = identifiant(os.path.splitext(os.path.basename(chemin))[0])
        if pid not in connus:
            print('Ignorée (prénom inconnu) :', os.path.basename(chemin).encode('ascii', 'replace').decode())
            continue
        feuille, portrait, deborde = decouper(chemin, pid)
        feuille.save(os.path.join(sortie, pid + '.png'), optimize=True)
        portrait.save(os.path.join(sortie, pid + '_portrait.png'), optimize=True)
        manifeste['pv2_' + pid] = {"categorie": "personnages", "fichier": "res://assets/bd/sprites/personnages_v2/%s_portrait.png" % pid,
                                   "pied": [portrait.width // 2, portrait.height], "taille": [portrait.width, portrait.height]}
        faits.append((pid, feuille, portrait))
        if deborde:
            print(pid, ': images qui débordent de la cellule :', deborde)
    # Tous les personnages dont la feuille existe, nouveaux ou non
    persos = [{"id": pid, "nom": nom, "genre": PERSONNAGES[nom]} for pid, nom in sorted(connus.items())
              if os.path.exists(os.path.join(sortie, pid + '.png'))]
    json.dump({"_note": "Personnages des planches : docs/handoff_bd/generateurs/personnages_planches.py. Chacun a un portrait et une feuille d'animation (assets/bd/sprites/personnages_v2).", "personnages": persos},
              open(os.path.join(racine, 'game', 'data', 'personnages.json'), 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=2)
    json.dump(manifeste, open(manifeste_p, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent=1)
    if controle and faits:
        os.makedirs(controle, exist_ok=True)
        for pid, f, p in faits:
            fond = Image.new('RGB', (f.width + 220, f.height), (200, 220, 190))
            fond.paste(p, (0, 0), p)
            fond.paste(f, (220, 0), f)
            fond.save(os.path.join(controle, pid + '.png'))
    print(len(faits), 'planches découpées,', len(persos), 'personnages au total')


if __name__ == '__main__':
    main()
