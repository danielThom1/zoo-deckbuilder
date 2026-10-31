"""Outils de tracé « croquis » communs aux générateurs d'images du jeu (personnages, animaux, bâtiments) :
courbes lissées à l'encre doublée, aplats, hachures. Voir tools/personnages.py, tools/animaux.py, tools/batiments.py.
"""
import io
import math
import os
import random

RACINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'game')
ENCRE = '#2B2118'


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
        self.droit_max = 0  # polygones d'au plus droit_max points tracés en segments droits (bâtiments)

    def wob(self, pts, amp):
        return [(x + self.r.uniform(-amp, amp), y + self.r.uniform(-amp, amp)) for x, y in pts]

    def chemin(self, pts, closed):
        if len(pts) <= self.droit_max:
            return 'M' + ' L'.join('%s %s' % (fmt(x), fmt(y)) for x, y in pts) + ('Z' if closed else '')
        return catmull(pts, closed)

    def forme(self, pts, fill, closed=True, w=1.7, amp=0.45, opacite=1.0):
        """Remplissage + contour à l'encre, doublé d'un second passage plus fin et décalé (effet crayonné)."""
        a = self.wob(pts, amp)
        attr = ' fill-opacity="%s"' % fmt(opacite) if opacite < 1 else ''
        self.out.append('<path d="%s" fill="%s"%s stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"/>'
                        % (self.chemin(a, closed), fill if closed else 'none', attr, ENCRE, fmt(w)))
        b = self.wob(pts, amp * 1.8)
        self.out.append('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-opacity="0.45" stroke-linecap="round"/>'
                        % (self.chemin(b, closed), ENCRE, fmt(w * 0.5)))

    def aplat(self, pts, fill, opacite=1.0, closed=True):
        """Surface sans contour (ombres, reflets)."""
        self.out.append('<path d="%s" fill="%s" fill-opacity="%s"/>' % (self.chemin(self.wob(pts, 0.3), closed), fill, fmt(opacite)))

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


def rot_ellipse(cx, cy, rx, ry, angle_deg, n=20):
    """Ellipse tournée de angle_deg (sens horaire à l'écran)."""
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)
    out = []
    for x, y in ellipse(0, 0, rx, ry, n):
        out.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    return out


def dans_ellipse(cx, cy, rx, ry, marge=0.92):
    return lambda x, y: ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 < marge


IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[params]

compress/mode=0
mipmaps/generate=true
process/fix_alpha_border=true
svg/scale=2.0
"""


def ecrire_svg(chemin, w, h, morceaux):
    """Écrit le SVG et, s'il n'existe pas, son .import (svg/scale 2, mipmaps)."""
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with io.open(chemin, 'w', encoding='utf-8', newline='\n') as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' % (w, h, w, h))
        f.write('\n'.join(morceaux))
        f.write('\n</svg>\n')
    if not os.path.exists(chemin + '.import'):
        with io.open(chemin + '.import', 'w', encoding='utf-8', newline='\n') as f:
            f.write(IMPORT)
