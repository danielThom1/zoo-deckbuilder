"""Génère la base de personnages du jeu : portraits SVG au trait « croquis » pour les cartes ouvrier
(game/ui/portraits/<id>.svg) et données d'apparence (game/data/personnages.json) reprises par le dessin des
ouvriers dans le monde (main.gd > _draw_person).

Usage : python tools/personnages.py   puis   godot --headless --path game --import
Le tracé est déterministe : relancer le script redonne les mêmes images.
"""
import io
import json
import math
import os
import random
import zlib

RACINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'game')

ENCRE = '#2B2118'
PEAUX = ['#F6D7BF', '#EBC09C', '#D69F78', '#B47A52', '#8A5638', '#5E3A26']
CHEVEUX = {
    'noir': '#2A2422', 'brun': '#5A3A24', 'chatain': '#7A5232', 'chatain_clair': '#9C7048', 'blond': '#D9B464',
    'roux': '#B5552B', 'auburn': '#8E3B26', 'gris': '#A9A6A2', 'blanc': '#E9E5DE', 'rose': '#E58AB0',
}
COULEURS = {
    'rouge': '#D04A3A', 'bleu': '#3A6EC8', 'marine': '#2C3E66', 'vert': '#3E9A55', 'vert_fonce': '#2F6B45',
    'jaune': '#E8B830', 'orange': '#E8782A', 'violet': '#7A4AB0', 'rose': '#E07AA0', 'gris': '#8A8F96',
    'gris_fonce': '#4E545C', 'blanc': '#F2EFE8', 'beige': '#D9C49A', 'turquoise': '#2FAAA0', 'marron': '#7A5232',
    'denim': '#4A6A9A', 'paille': '#E3C77A', 'casque_jaune': '#F2C230', 'casque_blanc': '#EEF0F0',
}

# id, nom, peau, visage, coiffure, cheveux, chapeau, couleur du chapeau, pilosité, lunettes, vêtement,
# couleur, couleur secondaire, expression, âge, extras (boucles d'oreilles, taches de rousseur)
P = [
    ('lea', 'Léa', 0, 'ovale', 'queue', 'auburn', '', '', '', '', 'salopette', 'jaune', 'denim', 'sourire', 'jeune', 'rousseur'),
    ('hugo', 'Hugo', 1, 'rond', 'court', 'brun', 'casquette', 'rouge', 'barbe3j', '', 'tshirt', 'bleu', '', 'rire', 'adulte', ''),
    ('jade', 'Jade', 3, 'ovale', 'chignon', 'noir', '', '', '', '', 'chemise', 'vert', '', 'neutre', 'adulte', 'boucles'),
    ('louis', 'Louis', 0, 'carre', 'raie', 'blond', '', '', '', 'rondes', 'polo', 'marine', '', 'sourire', 'adulte', ''),
    ('emma', 'Emma', 1, 'rond', 'long', 'chatain', 'bandeau', 'rose', '', '', 'tshirt', 'blanc', '', 'rire', 'jeune', ''),
    ('nathan', 'Nathan', 4, 'rond', 'rase', 'noir', '', '', '', '', 'securite', 'gris', '', 'sourire', 'adulte', ''),
    ('ines', 'Inès', 2, 'ovale', 'boucles', 'noir', '', '', '', '', 'sweat', 'violet', '', 'malin', 'jeune', 'boucles'),
    ('gabin', 'Gabin', 0, 'long', 'herisse', 'roux', '', '', '', '', 'tshirt', 'vert', '', 'rire', 'jeune', 'rousseur'),
    ('chloe', 'Chloé', 0, 'rond', 'carre', 'blond', '', '', '', 'rondes', 'chemise', 'rouge', '', 'sourire', 'adulte', ''),
    ('tom', 'Tom', 2, 'rond', 'court', 'brun', 'casque', 'casque_jaune', 'barbe', '', 'securite', 'bleu', '', 'neutre', 'adulte', ''),
    ('manon', 'Manon', 1, 'ovale', 'tresses', 'chatain_clair', 'paille', 'paille', '', '', 'salopette', 'rouge', 'denim', 'sourire', 'jeune', ''),
    ('jules', 'Jules', 5, 'carre', 'court', 'noir', '', '', 'barbe', '', 'chemise', 'denim', '', 'sourire', 'adulte', ''),
    ('sarah', 'Sarah', 3, 'long', 'long', 'noir', '', '', '', '', 'costume', 'gris_fonce', 'turquoise', 'neutre', 'adulte', 'boucles'),
    ('paul', 'Paul', 0, 'carre', 'couronne', 'gris', '', '', 'moustache', 'rondes', 'costume', 'marine', 'rouge', 'serieux', 'age', ''),
    ('yasmine', 'Yasmine', 2, 'ovale', 'chauve', 'noir', 'voile', 'vert_fonce', '', '', 'tshirt', 'beige', '', 'sourire', 'adulte', ''),
    ('malik', 'Malik', 4, 'ovale', 'herisse', 'noir', '', '', 'bouc', '', 'sweat', 'orange', '', 'malin', 'jeune', ''),
    ('aicha', 'Aïcha', 5, 'rond', 'afro', 'noir', 'bandeau', 'jaune', '', '', 'tshirt', 'vert', '', 'rire', 'jeune', 'boucles'),
    ('theo', 'Théo', 1, 'rond', 'frange', 'blond', 'bonnet', 'bleu', '', '', 'sweat', 'gris', '', 'sourire', 'jeune', ''),
    ('margaux', 'Margaux', 0, 'long', 'carre', 'roux', '', '', '', 'rondes', 'tablier', 'blanc', 'vert_fonce', 'neutre', 'adulte', 'rousseur'),
    ('kenji', 'Kenji', 1, 'ovale', 'raie', 'noir', '', '', '', 'rondes', 'polo', 'vert', '', 'sourire', 'adulte', ''),
    ('lucie', 'Lucie', 0, 'rond', 'queue', 'blond', 'casquette', 'vert', '', '', 'tshirt', 'orange', '', 'rire', 'jeune', 'rousseur'),
    ('mamadou', 'Mamadou', 5, 'carre', 'rase', 'noir', '', '', 'barbe', '', 'securite', 'gris', '', 'sourire', 'adulte', ''),
    ('clara', 'Clara', 2, 'ovale', 'chignon', 'chatain', '', '', '', '', 'tablier', 'blanc', 'vert', 'sourire', 'adulte', ''),
    ('bastien', 'Bastien', 0, 'long', 'long', 'chatain', 'bonnet', 'rouge', 'barbe', '', 'salopette', 'gris', 'denim', 'neutre', 'adulte', ''),
    ('nadia', 'Nadia', 3, 'rond', 'boucles', 'chatain', '', '', '', 'rondes', 'tshirt', 'jaune', '', 'sourire', 'adulte', ''),
    ('marcel', 'Marcel', 0, 'rond', 'chauve', 'blanc', 'paille', 'paille', 'moustache', '', 'chemise', 'beige', '', 'rire', 'age', ''),
    ('odette', 'Odette', 1, 'rond', 'chignon', 'blanc', '', '', '', 'rondes', 'tablier', 'violet', 'rose', 'sourire', 'age', 'boucles'),
    ('samir', 'Samir', 3, 'carre', 'court', 'noir', 'casque', 'casque_blanc', 'barbe', '', 'chemise', 'bleu', '', 'neutre', 'adulte', ''),
    ('fatou', 'Fatou', 5, 'ovale', 'tresses', 'noir', 'foulard', 'orange', '', '', 'tshirt', 'turquoise', '', 'rire', 'jeune', 'boucles'),
    ('igor', 'Igor', 0, 'carre', 'rase', 'blond', '', '', 'barbe', '', 'tshirt', 'rouge', '', 'serieux', 'adulte', ''),
    ('elise', 'Élise', 1, 'ovale', 'frange', 'brun', '', '', '', '', 'costume', 'vert_fonce', 'blanc', 'malin', 'adulte', 'boucles'),
    ('adam', 'Adam', 2, 'rond', 'boucles', 'brun', '', '', '', '', 'tshirt', 'jaune', '', 'sourire', 'jeune', ''),
    ('rose', 'Rose', 4, 'rond', 'carre', 'noir', 'casquette', 'rose', '', '', 'salopette', 'blanc', 'denim', 'rire', 'jeune', 'boucles'),
    ('victor', 'Victor', 1, 'ovale', 'raie', 'gris', '', '', '', 'rondes', 'costume', 'gris', 'bleu', 'neutre', 'adulte', ''),
    ('camille', 'Camille', 0, 'ovale', 'court', 'rose', '', '', '', '', 'sweat', 'vert', '', 'malin', 'jeune', 'boucles'),
    ('noah', 'Noah', 4, 'rond', 'court', 'noir', 'bonnet', 'jaune', '', '', 'polo', 'orange', '', 'sourire', 'jeune', ''),
    ('zoe', 'Zoé', 2, 'rond', 'queue', 'noir', 'casque', 'casque_jaune', '', '', 'salopette', 'vert', 'denim', 'sourire', 'jeune', ''),
    ('basile', 'Basile', 0, 'long', 'frange', 'chatain', '', '', 'barbe3j', 'rondes', 'tablier', 'beige', 'marron', 'neutre', 'adulte', ''),
    ('lina', 'Lina', 3, 'ovale', 'long', 'chatain_clair', 'paille', 'paille', '', '', 'chemise', 'blanc', '', 'sourire', 'jeune', 'rousseur'),
    ('omar', 'Omar', 4, 'carre', 'court', 'gris', '', '', 'barbe', '', 'sweat', 'bleu', '', 'sourire', 'age', ''),
]
CHAMPS = ['id', 'nom', 'peau', 'visage', 'coiffure', 'cheveux', 'chapeau', 'couleur_chapeau', 'pilosite', 'lunettes',
          'vetement', 'couleur', 'couleur2', 'expression', 'age', 'extras']

W, H = 120, 100
CX, CY = 60.0, 45.0
VISAGES = {'rond': (17.5, 19.5, 2.0), 'ovale': (16.0, 20.5, 2.0), 'carre': (17.5, 19.5, 2.9), 'long': (15.0, 22.0, 2.3)}


# ---------------------------------------------------------------- tracé « croquis »

def fmt(v):
    return ('%.1f' % v).rstrip('0').rstrip('.')


def catmull(pts, closed):
    """Courbe lisse passant par les points (Catmull-Rom convertie en Bézier cubiques)."""
    n = len(pts)
    if n < 2:
        return ''
    d = 'M%s %s' % (fmt(pts[0][0]), fmt(pts[0][1]))
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        p0 = pts[(i - 1) % n] if closed or i > 0 else pts[0]
        p1 = pts[i]
        p2 = pts[(i + 1) % n]
        p3 = pts[(i + 2) % n] if closed or i + 2 < n else pts[-1]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += 'C%s %s %s %s %s %s' % (fmt(c1[0]), fmt(c1[1]), fmt(c2[0]), fmt(c2[1]), fmt(p2[0]), fmt(p2[1]))
    return d + ('Z' if closed else '')


class Croquis:
    def __init__(self, seed):
        self.r = random.Random(seed)
        self.out = []

    def wob(self, pts, amp):
        return [(x + self.r.uniform(-amp, amp), y + self.r.uniform(-amp, amp)) for x, y in pts]

    def forme(self, pts, fill, closed=True, w=1.7, amp=0.45, opacite=1.0):
        """Remplissage + contour à l'encre, doublé d'un second passage plus fin et décalé (effet crayonné)."""
        a = self.wob(pts, amp)
        attr = ' fill-opacity="%s"' % fmt(opacite) if opacite < 1 else ''
        self.out.append('<path d="%s" fill="%s"%s stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"/>'
                        % (catmull(a, closed), fill if closed else 'none', attr, ENCRE, fmt(w)))
        b = self.wob(pts, amp * 1.8)
        self.out.append('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-opacity="0.45" stroke-linecap="round"/>'
                        % (catmull(b, closed), ENCRE, fmt(w * 0.5)))

    def aplat(self, pts, fill, opacite=1.0, closed=True):
        """Surface sans contour (ombres, reflets)."""
        self.out.append('<path d="%s" fill="%s" fill-opacity="%s"/>' % (catmull(self.wob(pts, 0.3), closed), fill, fmt(opacite)))

    def trait(self, pts, w=1.4, opacite=1.0, couleur=ENCRE, amp=0.35):
        self.out.append('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-opacity="%s" stroke-linecap="round" stroke-linejoin="round"/>'
                        % (catmull(self.wob(pts, amp), False), couleur, fmt(w), fmt(opacite)))

    def rond(self, x, y, r, fill, contour=True, opacite=1.0):
        pts = ellipse(x, y, r, r, 12)
        if contour:
            self.forme(pts, fill, w=1.2, amp=0.2)
        else:
            self.aplat(pts, fill, opacite)

    def hachures(self, dedans, x0, y0, x1, y1, pas=3.2, longueur=5.0, opacite=0.32):
        """Hachures diagonales courtes là où `dedans(x, y)` est vrai (ombre au crayon)."""
        y = y0
        while y < y1:
            x = x0 + (y - y0) * 0.3 % pas
            while x < x1:
                a = (x, y)
                b = (x + longueur * 0.55, y - longueur * 0.83)
                if dedans(*a) and dedans(*b):
                    self.out.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="0.8" stroke-opacity="%s" stroke-linecap="round"/>'
                                    % (fmt(a[0] + self.r.uniform(-0.4, 0.4)), fmt(a[1]), fmt(b[0]), fmt(b[1] + self.r.uniform(-0.4, 0.4)), ENCRE, fmt(opacite)))
                x += pas
            y += pas * 0.9


def ellipse(cx, cy, rx, ry, n=20, a0=0.0, a1=2 * math.pi):
    pts = []
    for i in range(n):
        t = a0 + (a1 - a0) * i / n
        pts.append((cx + rx * math.cos(t), cy + ry * math.sin(t)))
    return pts


def sombre(c, f=0.75):
    c = c.lstrip('#')
    return '#%02X%02X%02X' % tuple(int(int(c[i:i + 2], 16) * f) for i in (0, 2, 4))


def clair(c, f=0.35):
    c = c.lstrip('#')
    return '#%02X%02X%02X' % tuple(int(int(c[i:i + 2], 16) + (255 - int(c[i:i + 2], 16)) * f) for i in (0, 2, 4))


# ---------------------------------------------------------------- tête

def contour_visage(rx, ry, n_exp, n=28, gonfle=0.0):
    """Superellipse (visage carré si n_exp > 2), mâchoire un peu plus étroite."""
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        c, s = math.cos(t), math.sin(t)
        x = math.copysign(abs(c) ** (2 / n_exp), c) * (rx + gonfle)
        y = math.copysign(abs(s) ** (2 / n_exp), s) * (ry + gonfle)
        if s > 0:
            x *= 1 - 0.13 * s
        pts.append((CX + x, CY + y))
    return pts


def arc_haut(rx, ry, n_exp, gonfle, a0=math.pi * 0.95, a1=math.pi * 2.05, n=16):
    """Arc supérieur du crâne (angles SVG : -pi/2 = haut), élargi de `gonfle`."""
    pts = []
    for i in range(n + 1):
        t = a0 + (a1 - a0) * i / n
        c, s = math.cos(t), math.sin(t)
        x = math.copysign(abs(c) ** (2 / n_exp), c) * (rx + gonfle)
        y = math.copysign(abs(s) ** (2 / n_exp), s) * (ry + gonfle)
        pts.append((CX + x, CY + y))
    return pts


def portrait(p):
    k = Croquis(zlib.crc32(p['id'].encode()))
    rx, ry, ne = VISAGES[p['visage']]
    peau = PEAUX[p['peau']]
    cheveux = CHEVEUX[p['cheveux']]
    coul = COULEURS[p['couleur']]
    coul2 = COULEURS.get(p['couleur2'], sombre(coul))
    chap = COULEURS.get(p['couleur_chapeau'], '#888888')
    coif = p['coiffure']
    chapeau = p['chapeau']
    front = CY - ry * 0.5  # ligne du front (racine des cheveux)

    # Halo derrière la tête (style BD)
    k.aplat(ellipse(CX, CY - 2, rx + 16, ry + 13, 18), '#FFFFFF', 0.16)

    # Cheveux de derrière
    if chapeau == 'voile':
        k.forme([(CX - rx - 7, CY - 6), (CX - rx - 4, CY - ry - 4), (CX, CY - ry - 8), (CX + rx + 4, CY - ry - 4),
                 (CX + rx + 7, CY - 6), (CX + rx + 9, CY + 14), (CX + rx + 15, 86), (CX, 90), (CX - rx - 15, 86),
                 (CX - rx - 9, CY + 14)], chap)
    elif coif == 'afro':
        k.forme(ellipse(CX, CY - 7, rx + 11, ry + 7, 22), cheveux)
        k.hachures(lambda x, y: (x - CX) ** 2 / (rx + 10) ** 2 + (y - CY + 7) ** 2 / (ry + 6) ** 2 < 1 and x > CX + rx * 0.4,
                   CX, CY - ry - 14, CX + rx + 12, CY + 14)
    elif coif == 'long':
        k.forme([(CX - rx - 4, CY - 8), (CX - rx - 3, CY - ry - 1), (CX, CY - ry - 5), (CX + rx + 3, CY - ry - 1),
                 (CX + rx + 4, CY - 8), (CX + rx + 7, CY + 14), (CX + rx + 6, 83), (CX - rx - 6, 83), (CX - rx - 7, CY + 14)], cheveux)
    elif coif == 'carre':
        k.forme([(CX - rx - 5, CY - 6), (CX - rx - 3, CY - ry - 2), (CX, CY - ry - 5), (CX + rx + 3, CY - ry - 2),
                 (CX + rx + 5, CY - 6), (CX + rx + 6, CY + ry * 0.55), (CX + rx + 3, CY + ry * 0.75),
                 (CX - rx - 3, CY + ry * 0.75), (CX - rx - 6, CY + ry * 0.55)], cheveux)
    elif coif == 'queue':
        k.forme([(CX + rx - 3, CY - 10), (CX + rx + 7, CY - 4), (CX + rx + 11, CY + 10), (CX + rx + 7, CY + 22),
                 (CX + rx + 3, CY + 10), (CX + rx - 1, CY - 2)], cheveux)
        k.rond(CX + rx + 0.5, CY - 7, 2.6, COULEURS['rouge'])
    elif coif == 'chignon':
        k.forme(ellipse(CX, CY - ry - 5, 7.5, 6.5, 14), cheveux)
    elif coif == 'tresses':
        for side in (-1, 1):
            for j in range(6):
                k.forme(ellipse(CX + side * (rx + 3.5 + j * 0.2), CY + 2 + j * 6.2, 3.4, 3.8, 10), cheveux, w=1.1, amp=0.2)

    # Corps et vêtement
    corps = [(12, 101), (14, 90), (22, 81), (36, 76), (48, 73.5), (60, 73), (72, 73.5), (84, 76), (98, 81), (106, 90), (108, 101)]
    vet = p['vetement']
    base = coul if vet not in ('salopette', 'tablier') else coul
    k.forme(corps + [(60, 103)], base)
    k.hachures(lambda x, y: y > 77 and x > 84 and x < 105 and y < 99, 80, 76, 108, 100)
    cou_g, cou_d = CX - 6.5, CX + 6.5
    if vet == 'salopette':
        k.forme([(41, 101), (42, 84), (78, 84), (79, 101)], coul2)
        k.trait([(44, 84), (40, 75)], 3.2, 1, sombre(coul2))
        k.trait([(76, 84), (80, 75)], 3.2, 1, sombre(coul2))
        k.rond(45, 86.5, 1.6, COULEURS['jaune'])
        k.rond(75, 86.5, 1.6, COULEURS['jaune'])
        k.forme([(53, 88), (67, 88), (66.5, 95), (53.5, 95)], sombre(coul2, 0.9), w=1.1)
    elif vet == 'tablier':
        k.forme([(40, 101), (43, 81), (77, 81), (80, 101)], coul2)
        k.trait([(45, 81), (cou_g - 1, 72)], 1.6)
        k.trait([(75, 81), (cou_d + 1, 72)], 1.6)
        k.forme([(52, 89), (68, 89), (67.5, 96), (52.5, 96)], sombre(coul2, 0.85), w=1.1)
    elif vet == 'securite':
        k.forme([(30, 101), (33, 80), (47, 75), (52, 101)], COULEURS['orange'])
        k.forme([(68, 101), (73, 75), (87, 80), (90, 101)], COULEURS['orange'])
        for y in (87, 94):
            k.trait([(32, y), (51, y)], 2.4, 0.9, '#D8DCDC', 0.2)
            k.trait([(69, y), (89, y)], 2.4, 0.9, '#D8DCDC', 0.2)
    elif vet == 'costume':
        k.forme([(48, 73.5), (60, 96), (72, 73.5), (66, 72), (60, 76), (54, 72)], '#F4F1EA', w=1.2)
        k.forme([(57.5, 78), (62.5, 78), (63.5, 92), (60, 97), (56.5, 92)], coul2, w=1.1)
        k.forme([(46, 74), (55, 92), (51, 101), (44, 101), (40, 80)], sombre(coul, 0.85), w=1.2)
        k.forme([(74, 74), (65, 92), (69, 101), (76, 101), (80, 80)], sombre(coul, 0.85), w=1.2)
    elif vet == 'sweat':
        k.forme([(44, 74), (50, 82), (60, 84), (70, 82), (76, 74), (68, 77), (60, 79), (52, 77)], sombre(coul, 0.85), w=1.3)
        k.trait([(56, 83), (55, 93)], 1.0)
        k.trait([(64, 83), (65, 93)], 1.0)
        k.forme([(46, 101), (49, 92), (71, 92), (74, 101)], sombre(coul, 0.9), w=1.1)
    elif vet == 'chemise':
        k.forme([(52, 73), (60, 80), (55, 84), (48, 75)], clair(coul, 0.25), w=1.2)
        k.forme([(68, 73), (60, 80), (65, 84), (72, 75)], clair(coul, 0.25), w=1.2)
        k.trait([(60, 80), (60.5, 101)], 1.1)
        for y in (86, 92, 98):
            k.rond(61.8, y, 0.9, '#F4F1EA', contour=False)
        k.forme([(70, 85), (79, 85), (78.5, 92), (70.5, 92)], sombre(coul, 0.9), w=1.0)
    elif vet == 'polo':
        k.forme([(51, 73), (60, 78), (56, 82), (48, 76)], sombre(coul, 0.85), w=1.2)
        k.forme([(69, 73), (60, 78), (64, 82), (72, 76)], sombre(coul, 0.85), w=1.2)
        k.trait([(60, 78), (60, 87)], 1.1)
        k.rond(61.5, 82, 0.9, '#F4F1EA', contour=False)
        k.rond(61.5, 85.5, 0.9, '#F4F1EA', contour=False)
    else:  # t-shirt
        k.trait([(50, 74), (55, 79), (60, 80), (65, 79), (70, 74)], 1.4)
    if vet in ('salopette', 'tablier', 'tshirt'):
        k.trait([(50, 74), (55, 79), (60, 80), (65, 79), (70, 74)], 1.3)

    # Cou et oreilles
    k.forme([(cou_g, CY + ry - 8), (cou_g - 0.5, 75), (CX, 79), (cou_d + 0.5, 75), (cou_d, CY + ry - 8)], peau, w=1.4)
    k.aplat([(cou_g, CY + ry - 6), (cou_d, CY + ry - 6), (cou_d, CY + ry - 1), (CX, CY + ry + 1.5), (cou_g, CY + ry - 1)], sombre(peau, 0.8), 0.6)
    for side in (-1, 1):
        k.forme(ellipse(CX + side * (rx - 0.5), CY + 2, 3.4, 4.8, 12), peau, w=1.3)
        k.trait([(CX + side * (rx + 0.5), CY + 0.5), (CX + side * (rx - 0.3), CY + 3.5)], 0.8, 0.6)
        if 'boucles' in p['extras']:
            k.rond(CX + side * (rx - 0.2), CY + 7.8, 1.5, COULEURS['jaune'])

    # Visage
    visage = contour_visage(rx, ry, ne)
    k.forme(visage, peau, w=1.8)
    dedans = lambda x, y: ((x - CX) / rx) ** 2 + ((y - CY) / ry) ** 2 < 0.86
    k.hachures(lambda x, y: dedans(x, y) and x > CX + rx * 0.42, CX + rx * 0.3, CY - ry, CX + rx, CY + ry, 2.8, 4.0, 0.28)
    # Joues
    for side in (-1, 1):
        k.aplat(ellipse(CX + side * rx * 0.55, CY + ry * 0.32, 3.4, 2.0, 10), '#E8807A', 0.28)
    if 'rousseur' in p['extras']:
        for side in (-1, 1):
            for j in range(5):
                k.rond(CX + side * (rx * 0.42 + k.r.uniform(-2.5, 2.5)), CY + ry * 0.22 + k.r.uniform(-1.6, 1.6), 0.55, '#A0603A', contour=False, opacite=0.75)

    # Yeux, sourcils, nez, bouche
    ey = CY + 0.5
    ex = rx * 0.4
    expr = p['expression']
    for side in (-1, 1):
        x = CX + side * ex
        if expr == 'rire':
            k.trait([(x - 2.4, ey + 0.6), (x, ey - 1.3), (x + 2.4, ey + 0.6)], 1.5)
        else:
            k.rond(x, ey, 1.9, ENCRE, contour=False)
            k.rond(x + 0.6, ey - 0.6, 0.6, '#FFFFFF', contour=False)
        lift = {'malin': -1.2 if side < 0 else 0.6, 'serieux': 1.0, 'rire': -1.0}.get(expr, 0.0)
        bw = 1.8 if p['cheveux'] in ('noir', 'brun', 'chatain', 'auburn') else 1.4
        sc = sombre(cheveux, 0.8) if p['cheveux'] not in ('blanc', 'gris', 'blond', 'rose') else sombre(cheveux, 0.6)
        inner = -0.8 if expr == 'serieux' else 0.0
        k.trait([(x - side * 3.2 + 0, ey - 5 + lift + (inner if side > 0 else 0)), (x, ey - 6 + lift), (x + side * 3.2, ey - 5.2 + lift)], bw, 1, sc)
        if p['age'] == 'age':
            k.trait([(x + side * 4.0, ey - 1.0), (x + side * 5.4, ey - 1.8)], 0.8, 0.6)
            k.trait([(x + side * 4.0, ey + 1.0), (x + side * 5.4, ey + 1.6)], 0.8, 0.6)
    if p['age'] == 'age':
        k.trait([(CX - 6, CY - ry * 0.55 + 4), (CX, CY - ry * 0.55 + 3.4), (CX + 6, CY - ry * 0.55 + 4)], 0.8, 0.5)
    k.trait([(CX + 0.6, ey + 1.8), (CX + 2.3, ey + 6.8), (CX - 0.4, ey + 7.6)], 1.3, 0.85)
    my = CY + ry * 0.55
    if expr == 'rire':
        k.forme([(CX - 6, my - 1), (CX + 6, my - 1), (CX + 3.5, my + 4.2), (CX, my + 5), (CX - 3.5, my + 4.2)], '#7A2A22', w=1.4, amp=0.2)
        k.aplat([(CX - 4.6, my - 0.4), (CX + 4.6, my - 0.4), (CX + 3.6, my + 1.3), (CX - 3.6, my + 1.3)], '#FFFFFF', 0.95)
    elif expr == 'sourire':
        k.trait([(CX - 5, my - 0.8), (CX - 2, my + 1.6), (CX + 2, my + 1.6), (CX + 5, my - 0.8)], 1.5)
    elif expr == 'malin':
        k.trait([(CX - 4, my + 0.6), (CX + 1, my + 1.0), (CX + 5, my - 1.4)], 1.5)
    elif expr == 'serieux':
        k.trait([(CX - 3.5, my + 1.0), (CX, my + 0.6), (CX + 3.5, my + 1.0)], 1.5)
    else:
        k.trait([(CX - 3.5, my + 0.4), (CX + 3.5, my + 0.6)], 1.4)

    # Pilosité
    pil = p['pilosite']
    if pil == 'barbe':
        k.forme([(CX - rx + 0.5, CY + 1), (CX - rx + 1.5, CY + ry * 0.55), (CX - rx * 0.55, CY + ry * 0.92), (CX, CY + ry + 3.5),
                 (CX + rx * 0.55, CY + ry * 0.92), (CX + rx - 1.5, CY + ry * 0.55), (CX + rx - 0.5, CY + 1),
                 (CX + rx * 0.55, CY + ry * 0.38), (CX + 5, my - 2.5), (CX, my - 3.5), (CX - 5, my - 2.5), (CX - rx * 0.55, CY + ry * 0.38)], cheveux, w=1.4)
        if expr == 'rire':
            k.forme([(CX - 5, my - 1), (CX + 5, my - 1), (CX + 3, my + 3.6), (CX - 3, my + 3.6)], '#7A2A22', w=1.2, amp=0.15)
        else:
            k.trait([(CX - 4, my), (CX, my + 1.2), (CX + 4, my)], 1.4, 1, '#3A1A12')
    elif pil == 'moustache':
        k.forme([(CX - 7, my - 0.5), (CX - 3, my - 3.5), (CX, my - 2.6), (CX + 3, my - 3.5), (CX + 7, my - 0.5), (CX + 3, my - 1.4), (CX, my - 1.2), (CX - 3, my - 1.4)], cheveux, w=1.2)
    elif pil == 'bouc':
        k.forme([(CX - 3.5, my + 3), (CX + 3.5, my + 3), (CX + 2.5, CY + ry + 1.5), (CX - 2.5, CY + ry + 1.5)], cheveux, w=1.2)
        k.forme([(CX - 5, my - 1.5), (CX, my - 3), (CX + 5, my - 1.5), (CX, my - 1.8)], cheveux, w=1.0)
    elif pil == 'barbe3j':
        for j in range(26):
            a = k.r.uniform(0.15, math.pi - 0.15)
            rr = k.r.uniform(0.62, 0.92)
            x, y = CX + math.cos(a) * rx * rr, CY + math.sin(a) * ry * rr
            if y > CY + ry * 0.3:
                k.rond(x, y, 0.45, sombre(cheveux, 0.7), contour=False, opacite=0.7)

    # Lunettes
    if p['lunettes']:
        for side in (-1, 1):
            k.out.append('<circle cx="%s" cy="%s" r="4.3" fill="#FFFFFF" fill-opacity="0.18" stroke="%s" stroke-width="1.4"/>' % (fmt(CX + side * ex), fmt(ey), ENCRE))
        k.trait([(CX - ex + 4.3, ey - 0.4), (CX, ey - 1.2), (CX + ex - 4.3, ey - 0.4)], 1.2)

    # Cheveux du dessus
    if chapeau != 'voile':
        if coif in ('court', 'raie', 'frange', 'long', 'carre', 'queue', 'chignon', 'tresses', 'boucles', 'afro', 'herisse', 'rase'):
            g = {'rase': 0.3, 'queue': 1.2, 'chignon': 1.2, 'tresses': 1.2, 'herisse': 1.5}.get(coif, 2.4)
            arc = arc_haut(rx, ry, ne, g)
            if coif == 'herisse':
                spikes = []
                for i, (x, y) in enumerate(arc):
                    if i % 2:
                        dx, dy = x - CX, y - CY
                        d = math.hypot(dx, dy)
                        spikes.append((x + dx / d * 5, y + dy / d * 5))
                    else:
                        spikes.append((x, y))
                arc = spikes
            if coif == 'frange':
                ligne = [(CX + rx + 1, CY - ry * 0.2), (CX + rx * 0.5, CY - ry * 0.32), (CX, CY - ry * 0.3), (CX - rx * 0.5, CY - ry * 0.33), (CX - rx - 1, CY - ry * 0.2)]
            elif coif == 'raie':
                ligne = [(CX + rx + 1, CY - 2), (CX + rx * 0.4, front + 1), (CX - rx * 0.2, front - 2), (CX - rx * 0.6, front + 4), (CX - rx - 1, CY - 2)]
            elif coif in ('long', 'carre'):
                ligne = [(CX + rx + 1, CY + 2), (CX + rx * 0.6, front + 1), (CX + 2, front - 3.5), (CX - rx * 0.6, front + 1), (CX - rx - 1, CY + 2)]
            else:
                ligne = [(CX + rx + 0.5, CY - 1), (CX + rx * 0.55, front), (CX, front - 1.5), (CX - rx * 0.55, front), (CX - rx - 0.5, CY - 1)]
            if coif == 'rase':
                k.aplat(arc + ligne, cheveux, 0.6)
                k.trait(arc, 1.6, 1)
            elif coif == 'boucles':
                k.forme(arc + ligne, cheveux)
                for i in range(0, len(arc), 2):
                    k.forme(ellipse(arc[i][0], arc[i][1], 4.2, 4.2, 10), cheveux, w=1.2, amp=0.2)
            else:
                k.forme(arc + ligne, cheveux)
            if coif in ('long', 'carre'):
                for side in (-1, 1):
                    k.forme([(CX + side * (rx + 1), CY - 4), (CX + side * (rx + 4.5), CY + 8), (CX + side * (rx + 4), CY + ry * (0.75 if coif == 'carre' else 1.35)),
                             (CX + side * (rx - 0.5), CY + ry * (0.7 if coif == 'carre' else 1.3)), (CX + side * (rx - 1.5), CY + 6)], cheveux, w=1.4)
            if coif not in ('rase',):
                k.hachures(lambda x, y: y < front - 1 and ((x - CX) / (rx + g)) ** 2 + ((y - CY) / (ry + g)) ** 2 < 0.95 and x > CX + 2,
                           CX, CY - ry - 6, CX + rx + 4, front, 2.8, 4.0, 0.3)
            # mèches au crayon
            k.trait([(CX - rx * 0.3, front - 2), (CX - rx * 0.1, CY - ry - 0.5)], 0.9, 0.5)
            k.trait([(CX + rx * 0.25, front - 1), (CX + rx * 0.45, CY - ry + 1.5)], 0.9, 0.5)
            if coif == 'tresses':
                k.trait([(CX, front - 1.5), (CX, CY - ry - 1)], 1.0, 0.7)
        elif coif == 'couronne':
            for side in (-1, 1):
                k.forme([(CX + side * (rx - 3), CY - ry * 0.45), (CX + side * (rx + 2.5), CY - ry * 0.3), (CX + side * (rx + 2), CY + 4), (CX + side * (rx - 1.5), CY + 1)], cheveux, w=1.3)
        if coif in ('chauve', 'couronne') and not chapeau:
            k.aplat(ellipse(CX - rx * 0.3, CY - ry * 0.7, 4, 2.2, 10), '#FFFFFF', 0.35)

    # Couvre-chefs
    if chapeau == 'casquette':
        bas = CY - ry * 0.42
        crown = arc_haut(rx, ry, ne, 3.0, math.pi * 1.0, math.pi * 2.0, 12)
        k.forme(crown + [(CX + rx + 3, bas), (CX - rx - 3, bas)], chap)
        k.forme([(CX - rx - 3, bas - 1), (CX - rx - 16, bas + 2.5), (CX - rx - 15, bas + 5), (CX - 4, bas + 3.5), (CX + 2, bas + 1)], sombre(chap, 0.85), w=1.5)
        k.rond(CX, CY - ry - 3, 1.6, sombre(chap, 0.8))
        k.trait([(CX, CY - ry - 2), (CX + rx * 0.3, bas - 1)], 0.9, 0.5)
    elif chapeau == 'bonnet':
        bas = CY - ry * 0.32
        crown = arc_haut(rx, ry, ne, 3.5, math.pi * 1.0, math.pi * 2.0, 12)
        k.forme(crown + [(CX + rx + 3.5, bas), (CX - rx - 3.5, bas)], chap)
        k.forme([(CX - rx - 4, bas - 6), (CX + rx + 4, bas - 6), (CX + rx + 4, bas + 0.5), (CX - rx - 4, bas + 0.5)], sombre(chap, 0.82), w=1.4)
        for i in range(-3, 4):
            k.trait([(CX + i * 4.5, bas - 5), (CX + i * 4.5 + 0.3, bas - 0.5)], 0.8, 0.45)
        k.rond(CX, CY - ry - 6.5, 4.0, clair(chap, 0.45))
    elif chapeau == 'casque':
        bas = CY - ry * 0.4
        crown = arc_haut(rx, ry, ne, 4.5, math.pi * 1.0, math.pi * 2.0, 12)
        k.forme(crown + [(CX + rx + 4.5, bas), (CX - rx - 4.5, bas)], chap)
        k.forme([(CX - rx - 9, bas - 1), (CX + rx + 9, bas - 1), (CX + rx + 7, bas + 3), (CX - rx - 7, bas + 3)], sombre(chap, 0.88), w=1.5)
        k.forme([(CX - 2.5, CY - ry - 4.5), (CX + 2.5, CY - ry - 4.5), (CX + 2.5, bas - 1), (CX - 2.5, bas - 1)], clair(chap, 0.3), w=1.0)
        k.aplat(ellipse(CX - rx * 0.45, CY - ry * 0.85, 3.5, 2, 10), '#FFFFFF', 0.5)
    elif chapeau == 'paille':
        bas = CY - ry * 0.45
        crown = arc_haut(rx * 0.85, ry * 0.8, 2.2, 1.5, math.pi * 1.0, math.pi * 2.0, 12)
        crown = [(x, y - 4) for x, y in crown]
        k.forme(ellipse(CX, bas, rx + 15, 5.5, 22), chap, w=1.6)
        k.forme(crown + [(CX + rx * 0.85 + 1.5, bas), (CX - rx * 0.85 - 1.5, bas)], chap)
        k.forme([(CX - rx * 0.85 - 1.5, bas - 4.5), (CX + rx * 0.85 + 1.5, bas - 4.5), (CX + rx * 0.85 + 1.5, bas - 0.5), (CX - rx * 0.85 - 1.5, bas - 0.5)], COULEURS['rouge'], w=1.1)
        for i in range(-5, 6):
            k.trait([(CX + i * 3.6, bas + 1), (CX + i * 3.6 + 1.5, bas + 4)], 0.7, 0.4)
    elif chapeau == 'bandeau':
        pts = [(CX - rx - 1.5, CY - ry * 0.25), (CX - rx * 0.6, front - 1), (CX, front - 2.5), (CX + rx * 0.6, front - 1), (CX + rx + 1.5, CY - ry * 0.25)]
        k.trait(pts, 6.2, 1, ENCRE, 0.2)
        k.trait(pts, 4.4, 1, chap, 0.05)
    elif chapeau == 'foulard':
        bas = CY - ry * 0.38
        crown = arc_haut(rx, ry, ne, 3.0, math.pi * 1.0, math.pi * 2.0, 12)
        k.forme(crown + [(CX + rx + 3, bas), (CX - rx - 3, bas)], chap)
        k.forme([(CX + rx + 1, bas - 3), (CX + rx + 9, bas - 6), (CX + rx + 8, bas + 2)], sombre(chap, 0.85), w=1.2)
        for i in range(-2, 3):
            k.rond(CX + i * 6, CY - ry * 0.75, 1.1, '#FFFFFF', contour=False, opacite=0.8)
    elif chapeau == 'voile':
        k.forme([(CX - rx - 1, CY + 4), (CX - rx - 4, CY - ry * 0.4), (CX, CY - ry - 5), (CX + rx + 4, CY - ry * 0.4), (CX + rx + 1, CY + 4),
                 (CX + rx * 0.7, front + 1), (CX, front - 1.5), (CX - rx * 0.7, front + 1)], chap)
        k.hachures(lambda x, y: x > CX + rx * 0.3 and y < front and ((x - CX) / (rx + 3)) ** 2 + ((y - CY) / (ry + 4)) ** 2 < 0.95,
                   CX, CY - ry - 6, CX + rx + 5, front, 2.8, 4.0, 0.3)

    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' % (W, H, W, H)
            + '\n'.join(k.out) + '\n</svg>\n')


IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[params]

compress/mode=0
mipmaps/generate=true
process/fix_alpha_border=true
svg/scale=2.0
"""


def main():
    dossier = os.path.join(RACINE, 'ui', 'portraits')
    os.makedirs(dossier, exist_ok=True)
    base = []
    for row in P:
        p = dict(zip(CHAMPS, row))
        with io.open(os.path.join(dossier, p['id'] + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(portrait(p))
        imp = os.path.join(dossier, p['id'] + '.svg.import')
        if not os.path.exists(imp):
            with io.open(imp, 'w', encoding='utf-8', newline='\n') as f:
                f.write(IMPORT)
        # Apparence reprise par le dessin dans le monde (couleurs résolues)
        base.append({
            'id': p['id'], 'nom': p['nom'], 'peau': PEAUX[p['peau']], 'cheveux': CHEVEUX[p['cheveux']],
            'coiffure': p['coiffure'], 'chapeau': p['chapeau'], 'couleur_chapeau': COULEURS.get(p['couleur_chapeau'], ''),
            'pilosite': p['pilosite'], 'lunettes': p['lunettes'] != '', 'vetement': p['vetement'],
            'couleur': COULEURS[p['couleur']], 'couleur2': COULEURS.get(p['couleur2'], sombre(COULEURS[p['couleur']])),
        })
    with io.open(os.path.join(RACINE, 'data', 'personnages.json'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('{\n  "_note": "Généré par tools/personnages.py : ne pas modifier à la main. Chaque carte ouvrier tire un personnage (nom, portrait res://ui/portraits/<id>.svg, apparence dans le monde).",\n  "personnages": [\n')
        f.write(',\n'.join('    ' + json.dumps(b, ensure_ascii=False) for b in base))
        f.write('\n  ]\n}\n')
    print('%d personnages' % len(base))


if __name__ == '__main__':
    main()
