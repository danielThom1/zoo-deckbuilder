"""Génère les bâtiments au trait « croquis » (même style que les personnages et les animaux) :
game/ui/batiments/<id>.svg, vus du dessus et un peu de face (toit + façade). 32 unités par case ; l'image
dépasse de HAUT unités au-dessus de l'emprise pour donner du volume. Le camp a trois versions (camp_1 à camp_3).

Usage : python tools/batiments.py   puis   godot --headless --path game --import
"""
import os
import zlib

from croquis import RACINE, ENCRE, Croquis, ellipse, rot_ellipse, sombre, clair, ecrire_svg

U = 32
HAUT = 14


def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def ombre(k, W, H):
    k.aplat([(8, H - 4), (W - 1, H - 6), (W - 1, H - 1), (10, H - 0.5)], '#000000', 0.2)


def toit_deux_pans(k, x0, x1, y_haut, y_faite, y_bas, col, deborde=3, tuiles=True):
    """Toit à deux pans vu du dessus et de face : pan arrière (clair), faîtage, pan avant (foncé)."""
    k.forme(rect(x0 - deborde + 2, y_haut, x1 + deborde - 2, y_faite), clair(col, 0.12), w=1.6)
    k.forme([(x0 - deborde, y_faite), (x1 + deborde, y_faite), (x1 + deborde + 1, y_bas), (x0 - deborde - 1, y_bas)], col, w=1.7)
    if tuiles:
        y = y_faite + 4
        while y < y_bas - 1:
            k.trait([(x0 - deborde, y), (x1 + deborde, y)], 0.8, 0.45)
            y += 3.6
        y = y_haut + 3
        while y < y_faite - 1:
            k.trait([(x0 - deborde + 2, y), (x1 + deborde - 2, y)], 0.7, 0.3)
            y += 3.6
    k.trait([(x0 - deborde, y_faite), (x1 + deborde, y_faite)], 1.8, 1, sombre(col, 0.6))
    k.hachures(lambda x, y: y_faite + 1 < y < y_bas - 1 and x > (x0 + x1) / 2 + (x1 - x0) * 0.2 and x < x1 + deborde - 1,
               x0, y_faite, x1 + deborde, y_bas, 3.0, 4.5, 0.25)


def facade(k, x0, x1, y0, y1, col, planches=False, colombage=False):
    k.forme(rect(x0, y0, x1, y1), col, w=1.6)
    if planches:
        x = x0 + 4
        while x < x1 - 1:
            k.trait([(x, y0 + 1), (x, y1 - 1)], 0.8, 0.4)
            x += 4
    if colombage:
        k.trait([(x0 + 1, y0 + (y1 - y0) * 0.45), (x1 - 1, y0 + (y1 - y0) * 0.45)], 1.4, 0.8, '#6A4A2E')
        k.trait([(x0 + 2, y0 + 1), (x0 + 8, y0 + (y1 - y0) * 0.45)], 1.2, 0.7, '#6A4A2E')
        k.trait([(x1 - 2, y0 + 1), (x1 - 8, y0 + (y1 - y0) * 0.45)], 1.2, 0.7, '#6A4A2E')


def porte(k, x, y1, l, h, col='#7A5232', double=False):
    k.forme(rect(x - l / 2, y1 - h, x + l / 2, y1), col, w=1.4)
    if double:
        k.trait([(x, y1 - h + 1), (x, y1 - 1)], 1.0, 0.8)
        k.trait([(x - l / 2 + 1, y1 - h + 1), (x + l / 2 - 1, y1 - 1)], 1.0, 0.6)
        k.trait([(x + l / 2 - 1, y1 - h + 1), (x - l / 2 + 1, y1 - 1)], 1.0, 0.6)
    else:
        k.rond(x + l * 0.28, y1 - h * 0.45, 0.8, '#F2C230', contour=False)


def fenetre(k, x, y, l, h, volets=None):
    if volets:
        k.forme(rect(x - l / 2 - 3, y, x - l / 2, y + h), volets, w=1.0)
        k.forme(rect(x + l / 2, y, x + l / 2 + 3, y + h), volets, w=1.0)
    k.forme(rect(x - l / 2, y, x + l / 2, y + h), '#BFE0EC', w=1.3)
    k.trait([(x, y + 0.5), (x, y + h - 0.5)], 0.9, 0.8)
    k.trait([(x - l / 2 + 0.5, y + h / 2), (x + l / 2 - 0.5, y + h / 2)], 0.9, 0.8)
    k.aplat(rect(x - l / 2 + 1, y + 1, x - l / 2 + 2.5, y + h / 2 - 1), '#FFFFFF', 0.7)


def store(k, x0, x1, y0, y1, c1, c2, bandes=6, festons=True):
    """Auvent rayé (marché, boutique, snack)."""
    w = (x1 - x0) / bandes
    for i in range(bandes):
        k.forme([(x0 + i * w, y0), (x0 + (i + 1) * w, y0), (x0 + (i + 1) * w + 1, y1), (x0 + i * w + 1, y1)], c1 if i % 2 == 0 else c2, w=1.0, amp=0.2)
    if festons:
        for i in range(bandes):
            k.forme(ellipse(x0 + (i + 0.5) * w + 1, y1, w / 2, 2.6, 10, 0, 3.1416), c1 if i % 2 == 0 else c2, w=1.0, amp=0.1)
    k.trait([(x0, y0), (x1, y0)], 1.6, 1)


def caisse(k, x, y, s=7, col='#B88A50'):
    k.forme(rect(x, y, x + s, y + s * 0.8), col, w=1.2)
    k.trait([(x + 0.5, y + 0.5), (x + s - 0.5, y + s * 0.8 - 0.5)], 0.8, 0.6)


def tonneau(k, x, y, col='#8A5A30'):
    k.forme(ellipse(x, y, 4, 5, 12), col, w=1.2)
    k.trait([(x - 4, y - 1.5), (x + 4, y - 1.5)], 0.8, 0.7, '#4A4440')
    k.trait([(x - 4, y + 1.5), (x + 4, y + 1.5)], 0.8, 0.7, '#4A4440')


# ---------------------------------------------------------------- bâtiments

def maison(k, W, H):
    ombre(k, W, H)
    facade(k, 6, W - 6, 40, H - 3, '#EADBC0', colombage=True)
    porte(k, W / 2, H - 3, 9, 14)
    fenetre(k, 17, 47, 8, 7, '#3A6AE0')
    fenetre(k, W - 17, 47, 8, 7, '#3A6AE0')
    toit_deux_pans(k, 6, W - 6, 4, 20, 42, '#C8503A')
    k.forme(rect(W - 20, 2, W - 14, 14), '#9A8A80', w=1.3)
    k.aplat(ellipse(W - 15, -0.5, 3.5, 2.4, 10), '#FFFFFF', 0.45)


def entrepot(k, W, H):
    ombre(k, W, H)
    facade(k, 4, W - 4, 38, H - 3, '#A8784A', planches=True)
    porte(k, W / 2, H - 3, 20, 20, '#7A5232', double=True)
    toit_deux_pans(k, 4, W - 4, 3, 18, 40, '#7A7E86')
    caisse(k, 6, H - 10, 7)
    caisse(k, W - 13, H - 9, 7, '#C89A60')
    caisse(k, W - 12, H - 15, 6, '#B88A50')


def comptoir(k, W, H):
    """Marché : étal sous un auvent rayé, cagettes de fruits."""
    ombre(k, W, H)
    k.forme(rect(5, 24, W - 5, H - 4), '#D8C49A', w=1.4)
    for x in (8, W - 8):
        k.forme(rect(x - 1.5, 22, x + 1.5, H - 4), '#7A5232', w=1.1)
    k.forme(rect(8, 46, W - 8, H - 6), '#9A6A40', w=1.5)
    k.trait([(8, 50), (W - 8, 50)], 0.8, 0.5)
    for i, col in enumerate(['#E04A3A', '#F2C230', '#4AA84A', '#E8782A']):
        x = 11 + i * 12
        k.forme(rect(x, 39, x + 10, 46), '#C89A60', w=1.1)
        for j in range(3):
            k.rond(x + 2.5 + j * 2.6, 38.5 - (j % 2), 1.9, col)
    store(k, 2, W - 2, 4, 26, '#E04A3A', '#F4F1EA', 7)
    for i in range(3):  # pile de pièces
        k.forme(ellipse(W / 2, 17 - i * 3, 5, 2, 12), '#F2C230', w=1.0, amp=0.1)


def agence(k, W, H):
    """Agence d'intérim : bureau à toit plat, vitrine et panneau aux deux silhouettes."""
    ombre(k, W, H)
    k.forme(rect(5, 6, W - 5, 38), '#8A9AB0', w=1.6)
    k.forme(rect(8, 9, W - 8, 35), '#A8B8CC', w=1.0)
    for x in range(14, W - 8, 9):
        k.trait([(x, 10), (x, 34)], 0.7, 0.35)
    facade(k, 5, W - 5, 36, H - 3, '#F0EBE0')
    k.forme(rect(9, 40, W - 26, H - 7), '#BFE0EC', w=1.3)
    k.aplat(rect(11, 42, 14, H - 10), '#FFFFFF', 0.6)
    porte(k, W - 16, H - 3, 9, 15, '#5A7AA8')
    k.forme(rect(14, 13, W - 14, 29), '#3A6AC8', w=1.4)
    for x, d in ((W / 2 - 7, 0), (W / 2 + 7, 0)):
        k.rond(x, 18, 2.6, '#F4F1EA', contour=False)
        k.aplat(ellipse(x, 25, 4.5, 3, 10, 3.1416, 6.2832), '#F4F1EA', 1)
    k.trait([(W / 2 - 3, 19), (W / 2 + 3, 19)], 1.2, 1, '#F2C230')
    k.trait([(W / 2 + 3, 23), (W / 2 - 3, 23)], 1.2, 1, '#F2C230')
    k.trait([(W / 2 + 1, 17.5), (W / 2 + 3, 19), (W / 2 + 1, 20.5)], 1.0, 1, '#F2C230')
    k.trait([(W / 2 - 1, 21.5), (W / 2 - 3, 23), (W / 2 - 1, 24.5)], 1.0, 1, '#F2C230')


def mine(k, W, H):
    """Mine d'or : butte rocheuse, entrée boisée, rails et wagonnet de pépites."""
    ombre(k, W, H)
    k.forme([(2, H - 6), (6, 22), (18, 8), (34, 4), (50, 10), (W - 2, 26), (W - 3, H - 8), (W / 2, H - 4)], '#8E8478', w=1.8)
    for p in [(14, 22), (44, 18), (52, 34), (10, 38)]:
        k.forme(rot_ellipse(p[0], p[1], 5, 3.4, 15, 10), '#A49A8C', w=1.0)
    k.hachures(lambda x, y: x > 40 and 12 < y < H - 10, 36, 10, W - 4, H - 8)
    k.forme([(20, H - 6), (20, 32), (44, 32), (44, H - 6)], '#7A5232', w=1.5)
    k.forme([(24, H - 6), (24, 36), (40, 36), (40, H - 6)], '#1E1A16', w=1.2)
    k.trait([(18, 32), (46, 32)], 3.0, 1, '#5A3A22')
    for x in (28, 36):
        k.trait([(x, H - 6), (x + (x - 32) * 0.8, H)], 1.2, 0.9, '#5A5450')
    k.forme([(44, H - 14), (58, H - 14), (56, H - 6), (46, H - 6)], '#6A6460', w=1.3)
    for i in range(4):
        k.rond(47 + i * 3, H - 15.5 - (i % 2), 1.8, '#F2C230')


def formation(k, W, H):
    """Centre de formation : école à toit d'ardoise, clocheton, tableau près de la porte."""
    ombre(k, W, H)
    facade(k, 6, W - 6, 38, H - 3, '#E8D8B8')
    for x in (18, 34, W - 34, W - 18):
        fenetre(k, x, 45, 9, 9)
    porte(k, W / 2, H - 3, 10, 15, '#5A4636')
    toit_deux_pans(k, 6, W - 6, 6, 21, 40, '#4E5A70')
    k.forme(rect(W / 2 - 5, 0, W / 2 + 5, 12), '#E8D8B8', w=1.3)
    k.forme([(W / 2 - 7, 1), (W / 2, -6), (W / 2 + 7, 1)], '#4E5A70', w=1.3)
    k.rond(W / 2, 6, 2.2, '#F2C230')
    k.forme(rect(W / 2 + 8, H - 16, W / 2 + 20, H - 7), '#2E4A3A', w=1.3)
    k.trait([(W / 2 + 10, H - 13), (W / 2 + 17, H - 13)], 0.8, 0.9, '#F4F1EA')
    k.trait([(W / 2 + 10, H - 10), (W / 2 + 15, H - 10)], 0.8, 0.9, '#F4F1EA')


def boutique(k, W, H):
    """Boutique de souvenirs : vitrine sous un auvent rose, peluche et ballons."""
    ombre(k, W, H)
    toit_deux_pans(k, 6, W - 6, 3, 15, 30, '#E06A8A', tuiles=False)
    facade(k, 6, W - 6, 28, H - 3, '#F4E8DC')
    store(k, 4, W - 4, 28, 36, '#E04A8A', '#F4F1EA', 7)
    k.forme(rect(10, 40, 36, H - 8), '#BFE0EC', w=1.3)
    k.forme(ellipse(23, H - 13, 5.5, 5, 12), '#A8784A', w=1.1)
    k.forme(ellipse(23, H - 20, 4, 3.6, 12), '#A8784A', w=1.1)
    k.rond(20.5, H - 23, 1.5, '#A8784A')
    k.rond(25.5, H - 23, 1.5, '#A8784A')
    porte(k, W - 15, H - 3, 9, 15, '#C8503A')
    for x, col in ((W - 8, '#3A6AE0'), (W - 3, '#F2C230')):
        k.trait([(x - 1, 22), (x - 2, 34)], 0.7, 0.8)
        k.forme(ellipse(x, 18, 3.4, 4.2, 10), col, w=1.0)


def cuisine(k, W, H):
    """Cuisine des animaux : toit vert, cheminée qui fume, tonneaux et seau de poissons."""
    ombre(k, W, H)
    facade(k, 6, W - 6, 38, H - 3, '#E0D4BC', planches=True)
    porte(k, 22, H - 3, 10, 15, '#6A8A4A')
    fenetre(k, W - 18, 44, 10, 8)
    toit_deux_pans(k, 6, W - 6, 4, 19, 40, '#4A8A4A')
    k.forme(rect(14, 0, 21, 12), '#9A8A80', w=1.3)
    for i, (dx, dy, r) in enumerate([(0, -3, 3.4), (4, -8, 4.2), (10, -12, 3.6)]):
        k.aplat(ellipse(18 + dx, dy, r, r * 0.8, 10), '#FFFFFF', 0.55 - i * 0.12)
    tonneau(k, W - 9, H - 8)
    k.forme([(W - 24, H - 9), (W - 16, H - 9), (W - 17, H - 3), (W - 23, H - 3)], '#7A8A96', w=1.2)
    k.forme(rot_ellipse(W - 20, H - 10.5, 4, 1.6, -15, 10), '#8AB0C8', w=0.9)


def entretien(k, W, H):
    """Local d'entretien : cabanon gris, balai et seau, poubelle."""
    ombre(k, W, H)
    facade(k, 8, W - 8, 36, H - 3, '#B8BCC0', planches=True)
    porte(k, W / 2, H - 3, 11, 16, '#5A6066')
    toit_deux_pans(k, 8, W - 8, 6, 19, 38, '#6A7078', tuiles=False)
    for y in range(9, 37, 4):
        k.trait([(6, y), (W - 6, y)], 0.7, 0.35)
    k.trait([(12, H - 3), (16, H - 24)], 1.4, 1, '#8A6A44')
    k.forme([(9, H - 3), (15, H - 3), (13, H - 8), (11, H - 8)], '#E8C060', w=1.0)
    k.forme([(W - 16, H - 9), (W - 8, H - 9), (W - 9, H - 2), (W - 15, H - 2)], '#3A6AC8', w=1.2)
    k.forme(rect(W - 7, H - 13, W - 1, H - 2), '#4A8A4A', w=1.1)


def snack(k, W, H):
    """Snack : comptoir sous un auvent orange, cornet de glace, parasol et table."""
    ombre(k, W, H)
    toit_deux_pans(k, 8, W - 14, 4, 14, 26, '#E8782A', tuiles=False)
    facade(k, 8, W - 14, 26, H - 10, '#F4E4C4')
    store(k, 6, W - 12, 26, 33, '#E8782A', '#F4F1EA', 6)
    k.forme(rect(10, 40, W - 16, H - 10), '#C89A60', w=1.4)
    k.forme([(15, 12), (19, 12), (17, 20)], '#D8A060', w=1.0)
    k.forme(ellipse(17, 10, 3.2, 3, 10), '#F4B8C8', w=1.0)
    k.forme(ellipse(W - 8, H - 18, 8, 3.4, 14), '#3AA0C8', w=1.2)
    k.trait([(W - 8, H - 18), (W - 8, H - 6)], 1.0, 1)
    k.forme(ellipse(W - 8, H - 6, 5, 2, 12), '#F4F1EA', w=1.0)


def kiosque(k, W, H):
    """Kiosque d'animation : estrade ronde, toit violet à pointe dorée, rideau de scène."""
    ombre(k, W, H)
    k.forme(ellipse(W / 2, H - 9, W / 2 - 4, 8, 22), '#C8A878', w=1.6)
    for x in (10, W / 2, W - 10):
        k.forme(rect(x - 1.5, 22, x + 1.5, H - 9), '#F4F1EA', w=1.0)
    k.forme([(13, 24), (W / 2 - 2, 24), (W / 2 - 4, H - 12), (15, H - 12)], '#C8303A', w=1.2)
    k.forme([(W / 2 + 2, 24), (W - 13, 24), (W - 15, H - 12), (W / 2 + 4, H - 12)], '#C8303A', w=1.2)
    k.forme([(2, 26), (W / 2, 2), (W - 2, 26), (W / 2, 30)], '#8A4AD0', w=1.7)
    k.trait([(W / 2, 2), (W / 2, 30)], 1.0, 0.6)
    k.trait([(W / 2, 2), (14, 28)], 0.8, 0.5)
    k.trait([(W / 2, 2), (W - 14, 28)], 0.8, 0.5)
    k.hachures(lambda x, y: x > W / 2 + 4 and y < 26 and y > 2 + (x - W / 2) * 0.7, W / 2, 2, W, 28)
    k.rond(W / 2, 0, 2.6, '#F2C230')


def entree(k, W, H):
    """Entrée du zoo : deux piliers, linteau vert à silhouette de girafe, grilles ouvertes."""
    ombre(k, W, H)
    k.forme(rect(14, H - 12, W - 14, H - 3), '#E9D5A8', w=1.2)
    for x in (4, W - 14):
        k.forme(rect(x, 10, x + 10, H - 3), '#E8E0CC', w=1.6)
        k.forme(rect(x - 1, 8, x + 11, 12), '#C8BCA4', w=1.2)
        k.hachures(lambda xx, yy, x=x: x + 6 < xx < x + 10 and 12 < yy < H - 4, x, 12, x + 10, H - 3)
    k.forme(rect(8, 2, W - 8, 13), '#18A88A', w=1.6)
    k.forme([(W / 2 - 6, 11), (W / 2 - 4, 4), (W / 2 - 1, 3), (W / 2 + 1, 4.5), (W / 2 - 2, 6), (W / 2 - 3, 11)], '#F2C230', w=0.9)
    for x in (16, 20, W - 20, W - 16):
        k.trait([(x, 15), (x + (3 if x < W / 2 else -3), H - 6)], 1.0, 0.8, '#4A4440')


def camp(k, W, H, niveau):
    """Camp de base : terre battue, tentes (une de plus par niveau), caisses. Le feu est animé à part."""
    k.forme([(4, HAUT + 4), (W - 4, HAUT + 2), (W - 2, H - 4), (6, H - 2)], '#D2AA72', w=1.6)
    k.hachures(lambda x, y: y > H - 22 and 8 < x < W - 8, 6, H - 24, W - 4, H - 4, 4.0, 4.0, 0.18)
    tentes = [((26, 46), '#E8DCC0'), ((70, 46), '#D2553A'), ((26, 92), '#3A6AE0'), ((70, 92), '#18A88A')]
    for (x, y), col in tentes[:niveau + 1]:
        k.aplat([(x - 14, y + 1), (x + 16, y + 1), (x + 3, y - 18)], '#000000', 0.18)
        k.forme([(x - 15, y), (x, y), (x, y - 21)], clair(col, 0.12), w=1.5)
        k.forme([(x, y), (x + 15, y), (x, y - 21)], sombre(col, 0.8), w=1.5)
        k.forme([(x - 4, y), (x + 4, y), (x, y - 9)], '#2A1E14', w=1.0)
        k.trait([(x, y - 21), (x, y - 25)], 1.0, 1)
    caisse(k, W - 22, H - 16, 8)
    caisse(k, 8, H - 14, 7, '#C89A60')
    for dx in (-4, 4):
        k.trait([(W / 2 + dx - 3, 62), (W / 2 - dx + 3, 66)], 2.2, 1, '#6A4A30')


BATIMENTS = {
    'maison': (2, 2, maison), 'entrepot': (2, 2, entrepot), 'comptoir': (2, 2, comptoir), 'agence': (2, 2, agence),
    'mine': (2, 2, mine), 'formation': (3, 2, formation), 'boutique': (2, 2, boutique), 'cuisine': (2, 2, cuisine),
    'entretien': (2, 2, entretien), 'snack': (2, 2, snack), 'kiosque': (2, 2, kiosque), 'entree': (2, 1, entree),
}


def main():
    dossier = os.path.join(RACINE, 'ui', 'batiments')
    for nom, (sx, sy, dessin) in BATIMENTS.items():
        k = Croquis(zlib.crc32(nom.encode()))
        k.droit_max = 8
        W, H = sx * U, sy * U + HAUT
        dessin(k, W, H)
        ecrire_svg(os.path.join(dossier, nom + '.svg'), W, H, k.out)
    for niveau in (1, 2, 3):
        k = Croquis(niveau)
        k.droit_max = 8
        W, H = 3 * U, 3 * U + HAUT
        camp(k, W, H, niveau)
        ecrire_svg(os.path.join(dossier, 'camp_%d.svg' % niveau), W, H, k.out)
    print('%d bâtiments' % (len(BATIMENTS) + 3))


if __name__ == '__main__':
    main()
