"""Génère les illustrations des animaux au trait « croquis » (même style que les personnages) :
game/ui/animaux/<id>.svg, vus de profil tournés vers la droite. Elles servent sur les cartes de contrat et,
réduites (et retournées selon la marche), dans les enclos du monde.

Usage : python tools/animaux.py   puis   godot --headless --path game --import
"""
import io
import json
import math
import os
import zlib

from croquis import RACINE, ENCRE, Croquis, ellipse, rot_ellipse, dans_ellipse, sombre, clair, ecrire_svg

W, H = 120, 90
SOL = 84


# ---------------------------------------------------------------- pièces communes

def ombre(k, cx, rx):
    k.aplat(ellipse(cx, SOL + 1, rx, 3.2, 16), '#000000', 0.18)


def patte(k, x, y0, y1, l, col, sabot=None, coussinet=False, genou=0.0):
    """Patte droite légèrement effilée ; sabot sombre ou patte ronde de félin."""
    pts = [(x - l / 2, y0), (x + l / 2, y0), (x + l * 0.42 + genou, (y0 + y1) / 2), (x + l * 0.38, y1),
           (x - l * 0.38, y1), (x - l * 0.42 + genou, (y0 + y1) / 2)]
    k.forme(pts, col, w=1.4)
    if sabot:
        k.forme([(x - l * 0.42, y1 - 3), (x + l * 0.42, y1 - 3), (x + l * 0.5, y1), (x - l * 0.45, y1)], sabot, w=1.1, amp=0.15)
    if coussinet:
        k.forme(ellipse(x + l * 0.25, y1 - 1.2, l * 0.62, 2.2, 10), col, w=1.2, amp=0.15)


def oeil(k, x, y, r=1.8, clair_oeil=False):
    if clair_oeil:
        k.rond(x, y, r + 0.8, '#F4EFE0')
    k.rond(x, y, r, ENCRE, contour=False)
    k.rond(x + r * 0.35, y - r * 0.35, r * 0.35, '#FFFFFF', contour=False)


def oreille(k, x, y, sorte, taille, col, dedans='#E8A890', angle=-20):
    if sorte == 'pointu':
        a = math.radians(angle)
        tip = (x + math.sin(a) * taille, y - math.cos(a) * taille)
        k.forme([(x - taille * 0.38, y + 1), tip, (x + taille * 0.42, y + 1.5)], col, w=1.3)
        k.aplat([(x - taille * 0.18, y + 0.5), (tip[0] * 0.7 + x * 0.3, tip[1] * 0.7 + y * 0.3), (x + taille * 0.22, y + 1)], dedans, 0.85)
    elif sorte == 'rond':
        k.forme(ellipse(x, y - taille * 0.3, taille * 0.55, taille * 0.5, 10), col, w=1.3)
        k.aplat(ellipse(x, y - taille * 0.25, taille * 0.3, taille * 0.26, 10), dedans, 0.8)
    elif sorte == 'long':  # cervidés, antilopes : oreille couchée vers l'arrière
        k.forme(rot_ellipse(x - taille * 0.45, y - 1, taille * 0.62, taille * 0.24, -25, 12), col, w=1.3)
        k.aplat(rot_ellipse(x - taille * 0.45, y - 1, taille * 0.4, taille * 0.12, -25, 10), dedans, 0.8)


def queue(k, x, y, sorte, col, taille=1.0, bout=None):
    s = taille
    if sorte == 'fine':
        k.trait([(x, y), (x - 4 * s, y + 6 * s), (x - 5 * s, y + 14 * s)], 2.0 * s, 1)
        k.forme(ellipse(x - 5 * s, y + 16 * s, 2.4 * s, 3.6 * s, 10), bout or sombre(col, 0.5), w=1.1)
    elif sorte == 'touffue':
        k.forme(rot_ellipse(x - 7 * s, y + 6 * s, 10 * s, 4.6 * s, 35, 14), col, w=1.4)
        k.forme(rot_ellipse(x - 13 * s, y + 10.5 * s, 3.5 * s, 2.6 * s, 35, 10), bout or '#F4EFE0', w=1.1)
    elif sorte == 'longue':  # félins
        pts = [(x, y), (x - 7 * s, y + 4 * s), (x - 12 * s, y + 14 * s), (x - 10 * s, y + 24 * s), (x - 6 * s, y + 28 * s)]
        k.trait(pts, 4.6 * s, 1, ENCRE, 0.25)
        k.trait(pts, 3.0 * s, 1, col, 0.05)
        if bout:
            k.rond(x - 6 * s, y + 28 * s, 2.2 * s, bout)
    elif sorte == 'courte':
        k.forme(rot_ellipse(x - 2 * s, y + 2 * s, 3.4 * s, 2.2 * s, 30, 10), col, w=1.2)
    elif sorte == 'anneaux':  # panda roux
        k.forme(rot_ellipse(x - 9 * s, y + 8 * s, 12 * s, 5 * s, 38, 16), col, w=1.4)
        for i in range(3):
            cx = x - (4 + i * 5.5) * s
            cy = y + (3.5 + i * 4.3) * s
            k.trait([(cx - 2.5 * s, cy - 3.5 * s), (cx + 2.5 * s, cy + 3 * s)], 2.2 * s, 0.9, sombre(col, 0.55))


def rayures(k, cx, cy, rx, ry, n, col, ep=2.4, x0=None, x1=None):
    """Bandes verticales ondulées dans l'ellipse (zèbre, tigre)."""
    x0 = cx - rx * 0.85 if x0 is None else x0
    x1 = cx + rx * 0.8 if x1 is None else x1
    for i in range(n):
        x = x0 + (x1 - x0) * (i + 0.5) / n
        h = ry * math.sqrt(max(0.0, 1 - ((x - cx) / rx) ** 2)) * 0.92
        if h < 2:
            continue
        k.trait([(x, cy - h), (x + k.r.uniform(-1.5, 1.5), cy - h * 0.2), (x - k.r.uniform(0.5, 2), cy + h * 0.5)], ep, 1, col, 0.4)


def taches(k, cx, cy, rx, ry, n, col, r0=1.6, r1=2.8, anneau=False):
    for i in range(n):
        for _ in range(20):
            x = cx + k.r.uniform(-rx, rx) * 0.85
            y = cy + k.r.uniform(-ry, ry) * 0.8
            if dans_ellipse(cx, cy, rx, ry, 0.7)(x, y):
                break
        r = k.r.uniform(r0, r1)
        if anneau:
            k.out.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="none" stroke="%s" stroke-width="1.3" stroke-opacity="0.9"/>' % (x, y, r, col))
            k.rond(x, y, r * 0.35, col, contour=False, opacite=0.7)
        else:
            k.aplat(ellipse(x, y, r * k.r.uniform(0.8, 1.3), r * k.r.uniform(0.7, 1.1), 9), col, 0.9)


# ---------------------------------------------------------------- quadrupèdes

def quadrupede(k, a):
    c = a['c']
    ventre = a.get('ventre', clair(c, 0.35))
    fonce = a.get('fonce', sombre(c, 0.45))
    loin = sombre(c, 0.82)
    bx, by, brx, bry = a.get('corps', (56, 50, 24, 13))
    lw = a.get('pattes', 5.5)
    haut_patte = by + bry * 0.35
    sabot = a.get('sabot')
    felin = a.get('felin', False)
    ombre(k, bx, brx + 6)

    # Pattes de l'autre côté (plus sombres, décalées)
    xf, xb = bx + brx * 0.58, bx - brx * 0.6
    for x in (xb + 4, xf + 4):
        patte(k, x, haut_patte, SOL - 1, lw * 0.92, loin, sabot and sombre(sabot, 0.8), felin)
    # Queue
    if a.get('queue'):
        queue(k, bx - brx * 0.92, by - bry * 0.35, a['queue'], a.get('c_queue', c), a.get('t_queue', 1.0), a.get('bout_queue'))
    # Bosse (dromadaire)
    if a.get('bosse'):
        k.forme(ellipse(bx - 2, by - bry * 0.8, brx * 0.45, bry * 0.75, 16), c)
    # Corps
    corps = ellipse(bx, by, brx, bry, 26)
    if a.get('epaules'):  # garrot plus haut (bisons, yak, ours)
        corps = [(x, y - a['epaules'] * max(0.0, (x - bx) / brx)) if y < by else (x, y) for x, y in corps]
    k.forme(corps, c, w=1.8)
    k.aplat(ellipse(bx + 2, by + bry * 0.5, brx * 0.72, bry * 0.42, 16), ventre, 0.85)
    motif = a.get('motif')
    if motif == 'rayures':
        rayures(k, bx, by, brx, bry, a.get('n_rayures', 7), a.get('c_motif', ENCRE), a.get('ep_rayures', 2.6))
    elif motif == 'taches':
        taches(k, bx, by, brx, bry, a.get('n_taches', 9), a.get('c_motif', ENCRE), *a.get('r_taches', (1.6, 2.8)))
    elif motif == 'rosettes':
        taches(k, bx, by, brx, bry, a.get('n_taches', 8), a.get('c_motif', ENCRE), 1.8, 2.6, anneau=True)
    elif motif == 'girafe':
        for i in range(10):
            x = bx + k.r.uniform(-brx * 0.8, brx * 0.8)
            y = by + k.r.uniform(-bry * 0.7, bry * 0.5)
            if dans_ellipse(bx, by, brx, bry, 0.72)(x, y):
                k.forme(rot_ellipse(x, y, k.r.uniform(3.2, 4.6), k.r.uniform(2.4, 3.4), k.r.uniform(-30, 30), 6), a['c_motif'], w=0.8, amp=0.5)
    if a.get('poils'):  # frange de poils sous le ventre (yak, sanglier)
        pts = []
        for i in range(13):
            x = bx - brx * 0.8 + brx * 1.6 * i / 12
            pts.append((x, by + bry * 0.75 + (5 if i % 2 else 0)))
        k.trait(pts, 1.2, 0.8)
    k.hachures(lambda x, y: dans_ellipse(bx, by, brx, bry, 0.85)(x, y) and y > by + bry * 0.25, bx - brx, by, bx + brx, by + bry)
    # Pattes de ce côté
    for x in (xb, xf):
        patte(k, x, haut_patte, SOL, lw, c if not a.get('c_pattes') else a['c_pattes'], sabot, felin)
    if motif == 'rayures' and a.get('rayures_pattes', True):
        for x in (xb, xf):
            for j in range(3):
                y = haut_patte + 6 + j * 5
                if y < SOL - 4:
                    k.trait([(x - lw * 0.42, y), (x + lw * 0.42, y + 1)], 1.6, 0.9, a.get('c_motif', ENCRE))

    # Cou et tête
    na = math.radians(a.get('cou_angle', 40))
    nl = a.get('cou', 14)
    base = (bx + brx * 0.72, by - bry * 0.3)
    bout = (base[0] + math.cos(na) * nl, base[1] - math.sin(na) * nl)
    nw = a.get('cou_l', 9)
    px, py = -math.sin(na) * nw / 2, -math.cos(na) * nw / 2
    if a.get('criniere') == 'lion':
        k.forme(ellipse(bout[0] + 1, bout[1] + 2, a['tete'][0] + 9, a['tete'][1] + 8, 22), a['c_criniere'], w=1.6, amp=1.2)
        k.hachures(dans_ellipse(bout[0] + 1, bout[1] + 2, a['tete'][0] + 8, a['tete'][1] + 7, 0.9), bout[0] - 20, bout[1] - 20, bout[0] + 20, bout[1] + 24, 2.6, 4.5, 0.3)
    k.forme([(base[0] - px * 1.1, base[1] - py * 1.1 + 4), (base[0] + px, base[1] + py), (bout[0] + px * 0.8, bout[1] + py * 0.8),
             (bout[0] - px * 0.8, bout[1] - py * 0.8 + 2)], c, w=1.6)
    if a.get('criniere') == 'zebre':
        k.forme([(base[0] + px * 1.1 - 1, base[1] + py * 1.1 - 1), (bout[0] + px * 1.3 - 1, bout[1] + py * 1.3 - 2),
                 (bout[0] + px * 0.6, bout[1] + py * 0.6), (base[0] + px * 0.4, base[1] + py * 0.4)], ENCRE, w=1.0)
    if motif == 'rayures' and a.get('rayures_cou', True):
        for j in range(3):
            t = 0.25 + j * 0.25
            mx, my = base[0] + (bout[0] - base[0]) * t, base[1] + (bout[1] - base[1]) * t
            k.trait([(mx + px * 0.9, my + py * 0.9), (mx - px * 0.9, my - py * 0.9 + 1)], 2.0, 1, a.get('c_motif', ENCRE))
    if motif == 'girafe':
        for j in range(4):
            t = 0.15 + j * 0.22
            mx, my = base[0] + (bout[0] - base[0]) * t, base[1] + (bout[1] - base[1]) * t
            k.forme(ellipse(mx + 0.5, my + 0.5, 2.6, 2.0, 7), a['c_motif'], w=0.7, amp=0.4)
    hrx, hry = a.get('tete', (8, 7))
    hx, hy = bout[0] + 2, bout[1]
    # Oreilles derrière la tête
    if a.get('oreille'):
        oreille(k, hx - hrx * 0.35, hy - hry * 0.7, a['oreille'], a.get('t_oreille', 7), c, a.get('c_oreille', '#E8A890'), a.get('a_oreille', -20))
    if a.get('grande_oreille'):  # éléphant
        k.forme(rot_ellipse(hx - hrx * 0.7, hy + 3, hry * 1.15, hry * 1.45, -10, 18), sombre(c, 0.92), w=1.6)
        k.hachures(dans_ellipse(hx - hrx * 0.7, hy + 3, hry * 1.1, hry * 1.4), hx - 30, hy - 20, hx + 5, hy + 25)
    # Cornes et bois (avant la tête : la tête les recouvre à la base)
    corne = a.get('cornes')
    if corne == 'cerf':
        for side in (0, 1):
            ox = hx - 2 + side * 3
            k.trait([(ox, hy - hry + 1), (ox - 3, hy - hry - 9), (ox - 8, hy - hry - 17)], 2.2, 1, '#8A6A44')
            k.trait([(ox - 3, hy - hry - 9), (ox + 3, hy - hry - 14)], 1.8, 1, '#8A6A44')
            k.trait([(ox - 6, hy - hry - 14), (ox - 3, hy - hry - 20)], 1.6, 1, '#8A6A44')
            k.trait([(ox - 1.5, hy - hry - 5), (ox - 7, hy - hry - 7)], 1.6, 1, '#8A6A44')
    elif corne == 'chevre':
        k.forme([(hx - 2, hy - hry + 1), (hx - 7, hy - hry - 8), (hx - 13, hy - hry - 5), (hx - 9, hy - hry - 4), (hx - 5, hy - hry - 6), (hx + 1, hy - hry + 1)], '#D9C49A', w=1.3)
    elif corne == 'yak':
        for side in (-1, 1):
            k.forme([(hx - 1 + side, hy - hry + 2), (hx - 9 + side * 2, hy - hry - 1), (hx - 11 + side * 2, hy - hry - 8), (hx - 8 + side * 2, hy - hry - 5), (hx + 1 + side, hy - hry - 1)], '#E8E0CC', w=1.2)
    elif corne == 'addax':
        pts = []
        for i in range(10):
            t = i / 9
            pts.append((hx - 2 - 14 * t + math.sin(t * 12) * 1.6, hy - hry - 18 * t))
        k.trait(pts, 2.6, 1, '#4A3A2A')
        k.trait([(p[0] + 3, p[1] + 1) for p in pts], 2.2, 1, '#6A5A44')
    elif corne == 'gazelle':
        for d in (0, 3):
            k.trait([(hx - 1 + d, hy - hry + 1), (hx - 3 + d, hy - hry - 8), (hx - 1 + d, hy - hry - 14)], 1.9, 1, '#3A2A1A')
    elif corne == 'girafe':
        for d in (-1.5, 2):
            k.trait([(hx + d, hy - hry + 1), (hx + d - 1, hy - hry - 5)], 2.0, 1, sombre(c, 0.6))
            k.rond(hx + d - 1, hy - hry - 5.5, 1.6, '#3A2A1A')
    # Tête et museau
    tete = ellipse(hx, hy, hrx, hry, 18)
    k.forme(tete, a.get('c_tete', c), w=1.7)
    sl, sh = a.get('museau', (6, 4.5))
    sx, sy = hx + hrx * 0.75, hy + hry * 0.3
    if sl > 0:
        k.forme(ellipse(sx, sy, sl, sh, 14), a.get('c_museau', clair(c, 0.15)), w=1.5)
    if a.get('masque'):  # panda roux, fennec : visage clair
        k.aplat(ellipse(hx + hrx * 0.4, hy + hry * 0.25, hrx * 0.55, hry * 0.45, 12), a['masque'], 0.95)
    if a.get('trompe') == 'elephant':
        pts = [(sx + sl * 0.6, sy - 1), (sx + sl + 4, sy + 6), (sx + sl + 5, sy + 16), (sx + sl + 2, sy + 26), (sx + sl + 6, sy + 29)]
        k.trait(pts, 6.4, 1, ENCRE, 0.3)
        k.trait(pts, 4.6, 1, c, 0.05)
        for i in range(1, 4):
            p = pts[i]
            k.trait([(p[0] - 2, p[1]), (p[0] + 2, p[1] + 0.5)], 0.8, 0.6)
    if a.get('defenses'):
        k.forme([(sx + 1, sy + 2), (sx + 9, sy + 6), (sx + 13, sy + 3), (sx + 9, sy + 8), (sx + 1, sy + 5)], '#F4EFE0', w=1.1)
    if a.get('trompe') == 'tapir':
        k.forme(rot_ellipse(sx + sl + 1, sy + 1.5, 4, 2.6, 30, 10), a.get('c_museau', c), w=1.2)
    if a.get('corne_nez'):
        k.forme([(sx + 1, sy - sh + 1), (sx + 4, sy - sh - 9), (sx + 6, sy - sh + 1.5)], '#D8D0C0', w=1.2)
        k.forme([(sx - 4, sy - sh), (sx - 2.5, sy - sh - 4.5), (sx - 0.5, sy - sh + 0.5)], '#D8D0C0', w=1.0)
    if a.get('defense_sanglier'):
        k.forme([(sx + sl - 2, sy + 1), (sx + sl + 1, sy - 3), (sx + sl, sy + 2)], '#F4EFE0', w=0.9)
    if a.get('barbe'):
        k.forme([(sx - 2, sy + sh - 1), (sx + 2, sy + sh - 1), (sx, sy + sh + 6)], a['barbe'], w=1.0)
    # Nez, œil, bouche
    if sl > 0:
        k.rond(sx + sl * 0.72, sy - sh * 0.25, a.get('t_nez', 1.3), a.get('c_nez', ENCRE), contour=False)
        k.trait([(sx + sl * 0.4, sy + sh * 0.55), (sx + sl * 0.85, sy + sh * 0.4)], 1.0, 0.8)
    oeil(k, hx + hrx * 0.25, hy - hry * 0.2, a.get('t_oeil', 1.6), a.get('oeil_clair', False))
    if felin or a.get('moustaches'):
        for j in (-1, 0, 1):
            k.trait([(sx + sl * 0.3, sy + j), (sx + sl + 6, sy + j * 2.2 - 1)], 0.6, 0.6)
    if a.get('larmes'):  # guépard / suricate : trait sombre sous l'œil
        k.trait([(hx + hrx * 0.25, hy), (hx + hrx * 0.45, hy + hry * 0.6)], 1.4, 0.8)
    if a.get('oreille_devant'):
        oreille(k, hx - hrx * 0.05, hy - hry * 0.75, a['oreille_devant'], a.get('t_oreille', 7), c, a.get('c_oreille', '#E8A890'), a.get('a_oreille', -10))


# ---------------------------------------------------------------- oiseaux

def oiseau_perche(k, a):
    c = a['c']
    # Branche
    k.forme([(14, 70), (108, 67), (108, 73), (14, 76)], '#8A6A44', w=1.6)
    k.trait([(30, 72), (44, 71.5)], 0.8, 0.5)
    k.trait([(70, 70.5), (90, 70)], 0.8, 0.5)
    # Queue
    k.forme([(52, 58), (40, 86), (46, 88), (60, 62)], a.get('c_queue', sombre(c, 0.8)), w=1.5)
    # Corps
    corps = rot_ellipse(60, 48, 14, 21, -14, 22)
    k.forme(corps, c, w=1.8)
    if a.get('ventre'):
        k.aplat(rot_ellipse(64, 52, 8, 14, -14, 16), a['ventre'], 0.9)
    k.forme(rot_ellipse(55, 50, 8, 17, -18, 16), a.get('c_aile', sombre(c, 0.85)), w=1.4)
    for i in range(3):
        k.trait([(51 + i * 2.5, 56 + i * 3), (49 + i * 2.5, 64 + i * 3)], 0.9, 0.6)
    k.hachures(lambda x, y: dans_ellipse(55, 50, 8, 17)(x, y) and x < 54, 44, 32, 64, 68)
    # Pattes
    for dx in (0, 5):
        k.trait([(60 + dx, 66), (61 + dx, 70)], 1.8, 1, '#7A6A5A')
        k.trait([(58 + dx, 70.5), (64 + dx, 70.5)], 1.6, 1, '#7A6A5A')
    # Collerette (vautour)
    if a.get('collerette'):
        k.forme(ellipse(66, 30, 11, 5, 16), a['collerette'], w=1.4, amp=0.9)
    # Tête
    hx, hy = 68, 22
    k.forme(ellipse(hx, hy, 10, 9.5, 18), a.get('c_tete', c), w=1.7)
    if a.get('joue'):
        k.aplat(ellipse(hx + 2, hy + 1, 6, 5, 12), a['joue'], 0.95)
    if a.get('huppe'):
        for i in range(3):
            k.forme([(hx - 4 + i * 2, hy - 8), (hx - 9 + i * 3, hy - 17 + i), (hx - 1 + i * 2, hy - 8.5)], a['huppe'], w=1.0)
    # Bec
    bec = a.get('bec', 'crochu')
    cb = a.get('c_bec', '#3A2A1A')
    if bec == 'crochu':
        k.forme([(hx + 7, hy - 4), (hx + 14, hy - 2), (hx + 15, hy + 5), (hx + 11, hy + 3), (hx + 8, hy + 4)], cb, w=1.4)
    elif bec == 'toucan':
        k.forme([(hx + 6, hy - 6), (hx + 30, hy - 1), (hx + 34, hy + 4), (hx + 22, hy + 6), (hx + 7, hy + 5)], cb, w=1.5)
        k.aplat([(hx + 26, hy - 2), (hx + 34, hy + 4), (hx + 28, hy + 5)], '#D04A3A', 0.95)
        k.trait([(hx + 7, hy + 0.5), (hx + 30, hy + 2)], 1.0, 0.7)
    elif bec == 'aigle':
        k.forme([(hx + 7, hy - 3), (hx + 15, hy - 1), (hx + 16, hy + 5), (hx + 12, hy + 2.5), (hx + 8, hy + 3.5)], cb, w=1.4)
        k.aplat([(hx + 6, hy - 3.5), (hx + 9, hy - 3), (hx + 9, hy + 3), (hx + 6, hy + 3)], '#F2C230', 0.95)
    oeil(k, hx + 3, hy - 2, 1.7, a.get('oeil_clair', True))


def echassier(k, a):
    """Flamant, autruche : longues pattes et long cou."""
    c = a['c']
    ombre(k, 56, 16)
    cou = a.get('cou', 'flamant')
    if cou == 'flamant':
        k.trait([(60, 52), (61, 68), (61, 84)], 2.2, 1, ENCRE)
        k.trait([(60, 52), (61, 68), (61, 84)], 1.4, 1, a['c_pattes'])
        k.trait([(55, 52), (54, 62), (62, 66), (56, 70)], 2.2, 1, ENCRE)
        k.trait([(55, 52), (54, 62), (62, 66), (56, 70)], 1.4, 1, a['c_pattes'])
        k.trait([(58, 84), (65, 84)], 2.0, 1, a['c_pattes'])
    else:
        for x, g in ((52, -3), (60, 3)):
            pts = [(x, 50), (x + g, 66), (x + g * 0.5, 82)]
            k.trait(pts, 4.6, 1, ENCRE, 0.2)
            k.trait(pts, 3.2, 1, a['c_pattes'], 0.05)
            k.trait([(x + g * 0.5 - 2, 83.5), (x + g * 0.5 + 6, 83.5)], 2.6, 1, a['c_pattes'])
    corps = rot_ellipse(54, 42, 21, 13, -8, 22)
    k.forme(corps, c, w=1.8)
    if a.get('plumes'):
        for i in range(4):
            k.forme(rot_ellipse(38 + i * 4, 40 + i * 1.5, 7, 3.4, 25 + i * 8, 10), a['plumes'], w=1.0, amp=0.5)
    k.forme(rot_ellipse(52, 40, 13, 8, -10, 16), a.get('c_aile', sombre(c, 0.9)), w=1.3)
    k.hachures(lambda x, y: dans_ellipse(54, 42, 21, 13)(x, y) and y > 46, 30, 40, 78, 56)
    # Cou
    if cou == 'flamant':
        pts = [(70, 38), (76, 28), (72, 18), (70, 10), (78, 6)]
    else:
        pts = [(70, 38), (73, 26), (74, 14), (76, 7)]
    k.trait(pts, a.get('ep_cou', 5.6) + 1.8, 1, ENCRE, 0.2)
    k.trait(pts, a.get('ep_cou', 5.6), 1, a.get('c_cou', c), 0.05)
    hx, hy = pts[-1][0] + 2, pts[-1][1]
    k.forme(ellipse(hx, hy, 5.5, 4.6, 14), a.get('c_cou', c), w=1.5)
    if cou == 'flamant':
        k.forme([(hx + 4, hy - 2), (hx + 11, hy + 1), (hx + 10, hy + 7), (hx + 7, hy + 4), (hx + 4, hy + 2)], '#F4EFE0', w=1.2)
        k.aplat([(hx + 9, hy + 2), (hx + 11, hy + 1), (hx + 10, hy + 7), (hx + 8, hy + 5)], ENCRE, 0.95)
    else:
        k.forme([(hx + 4, hy - 1), (hx + 10, hy + 1), (hx + 4, hy + 2.5)], '#E8C090', w=1.1)
    oeil(k, hx + 1, hy - 1, 1.3, True)


def manchot(k, a):
    ombre(k, 60, 14)
    k.forme([(48, 82), (53, 84), (56, 81)], '#E8782A', w=1.1)
    k.forme([(62, 82), (68, 84), (70, 81)], '#E8782A', w=1.1)
    k.forme(ellipse(60, 52, 16, 30, 24), '#2A2830', w=1.8)
    k.forme(ellipse(64, 56, 10, 23, 20), '#F4F1EA', w=1.2)
    k.aplat(ellipse(66, 34, 7, 3.5, 12), '#F2C230', 0.7)
    k.forme(rot_ellipse(48, 54, 4.5, 15, 15, 14), '#22202A', w=1.3)
    k.forme(ellipse(62, 20, 10.5, 10, 18), '#2A2830', w=1.6)
    k.aplat(ellipse(64, 24, 5, 4, 12), '#F4F1EA', 0.9)
    k.forme([(70, 18), (79, 21), (70, 23)], '#E8782A', w=1.2)
    oeil(k, 66, 17, 1.4, True)
    k.hachures(lambda x, y: dans_ellipse(60, 52, 16, 30)(x, y) and x < 53, 42, 28, 60, 80)


# ---------------------------------------------------------------- reptiles, mammifères marins, petits

def reptile(k, a):
    c = a['c']
    ombre(k, 56, 36)
    # Pattes écartées, coudées
    for x, far in ((40, True), (70, True), (36, False), (66, False)):
        col = sombre(c, 0.82) if far else c
        dx = 3 if far else 0
        k.forme([(x + dx - 3, 66), (x + dx + 3, 66), (x + dx + 5, 76), (x + dx + 9, 80), (x + dx + 1, 81), (x + dx - 2, 74)], col, w=1.3)
    # Queue
    k.forme([(32, 62), (6, 74), (4, 77), (34, 72)], c, w=1.6)
    # Corps
    k.forme(ellipse(52, 66, 24, 8.5, 22), c, w=1.8)
    k.aplat(ellipse(54, 70, 18, 3.6, 14), a.get('ventre', clair(c, 0.35)), 0.9)
    if a.get('crete'):
        pts = []
        for i in range(14):
            x = 12 + i * 4.6
            y = 64.5 - (3.5 if i % 2 else 0) - (2 if 30 < x < 72 else 0)
            pts.append((x, y if x > 30 else 69 - (x - 12) * 0.25 - (2.5 if i % 2 else 0)))
        k.trait(pts, 1.4, 1)
    taches(k, 52, 66, 24, 8.5, 12, sombre(c, 0.7), 0.8, 1.4)
    # Tête
    if a.get('long_museau'):
        k.forme([(72, 60), (80, 58), (104, 62), (108, 66), (104, 70), (80, 72), (72, 70)], c, w=1.7)
        k.trait([(80, 66.5), (104, 66)], 1.1, 0.9)
        for i in range(5):
            k.forme([(84 + i * 4, 66), (85.5 + i * 4, 68.5), (87 + i * 4, 66)], '#F4EFE0', w=0.6, amp=0.1)
        k.rond(105, 61, 1.2, ENCRE, contour=False)
        oeil(k, 81, 58.5, 1.6, True)
    else:
        k.forme([(72, 60), (82, 57), (94, 60), (96, 65), (92, 69), (78, 71), (72, 70)], c, w=1.7)
        k.trait([(80, 66), (95, 65)], 1.0, 0.8)
        k.trait([(96, 65), (101, 63.5)], 1.0, 1, '#D04A3A')
        k.trait([(101, 63.5), (104, 62)], 0.8, 1, '#D04A3A')
        k.trait([(101, 63.5), (104, 65)], 0.8, 1, '#D04A3A')
        oeil(k, 85, 61, 1.5, True)
    k.hachures(lambda x, y: dans_ellipse(52, 66, 24, 8.5)(x, y) and y > 67, 28, 62, 78, 76)


def phoque(k, a):
    c = a['c']
    ombre(k, 58, 34)
    k.forme([(18, 78), (12, 70), (6, 76), (14, 84), (24, 82)], sombre(c, 0.85), w=1.4)
    k.forme([(22, 80), (34, 64), (56, 56), (78, 52), (90, 56), (94, 70), (86, 82), (56, 84), (30, 84)], c, w=1.9)
    k.forme(rot_ellipse(74, 76, 9, 3.6, 30, 12), sombre(c, 0.85), w=1.3)
    k.forme(ellipse(88, 48, 12, 11, 18), c, w=1.7)
    k.aplat(ellipse(90, 74, 6, 7, 12), clair(c, 0.3), 0.8)
    taches(k, 56, 70, 28, 10, 9, sombre(c, 0.65), 0.9, 1.6)
    k.rond(98, 50, 1.5, ENCRE, contour=False)
    oeil(k, 91, 45, 2.2)
    for j in (-1, 0, 1):
        k.trait([(97, 52 + j), (106, 51 + j * 2.4)], 0.6, 0.6)
    k.hachures(lambda x, y: y > 74 and 30 < x < 86, 28, 70, 90, 84)


def loutre(k, a):
    c = a['c']
    ombre(k, 58, 30)
    k.forme([(36, 66), (10, 76), (8, 80), (34, 74)], c, w=1.6)
    for x, far in ((44, True), (68, True), (40, False), (64, False)):
        patte(k, x + (3 if far else 0), 66, 83 if far else 84, 5, sombre(c, 0.82) if far else c, coussinet=True)
    k.forme(ellipse(54, 64, 24, 10, 22), c, w=1.8)
    k.aplat(ellipse(70, 66, 9, 6, 14), a['ventre'], 0.9)
    k.forme(ellipse(82, 56, 9.5, 8.5, 16), c, w=1.6)
    k.aplat(ellipse(86, 60, 6, 4, 12), a['ventre'], 0.95)
    k.forme(ellipse(78, 48.5, 2.5, 2.2, 8), c, w=1.1)
    k.rond(91, 57, 1.5, ENCRE, contour=False)
    oeil(k, 85, 53, 1.5)
    for j in (-1, 0, 1):
        k.trait([(89, 59 + j), (97, 58 + j * 2.4)], 0.6, 0.6)
    k.hachures(lambda x, y: dans_ellipse(54, 64, 24, 10)(x, y) and y > 66, 30, 60, 78, 76)


def primate(k, a):
    c = a['c']
    if a.get('sorte') == 'gorille':
        ombre(k, 58, 30)
        patte(k, 40, 60, SOL, 10, sombre(c, 0.85), coussinet=True)
        k.forme([(70, 44), (80, 60), (82, 84), (74, 84), (72, 62), (66, 52)], sombre(c, 0.85), w=1.5)
        k.forme(rot_ellipse(54, 52, 25, 18, -15, 24), c, w=1.9)
        k.aplat(rot_ellipse(46, 46, 14, 7, -15, 16), '#A8A6A2', 0.85)
        patte(k, 46, 62, SOL, 10, c, coussinet=True)
        k.forme([(64, 46), (76, 62), (78, 84), (69, 84), (68, 64), (60, 54)], c, w=1.6)
        k.forme(ellipse(78, 32, 12, 12.5, 18), c, w=1.8)
        k.forme(ellipse(82, 34, 8, 8.5, 16), '#4E4A48', w=1.4)
        k.trait([(76, 27), (88, 27)], 2.0, 0.9)
        oeil(k, 84, 30, 1.4)
        k.rond(87, 36, 0.9, ENCRE, contour=False)
        k.trait([(82, 39), (87, 39.5)], 1.0, 0.8)
        k.hachures(lambda x, y: dans_ellipse(54, 52, 25, 18)(x, y) and y > 56, 30, 48, 80, 72)
    else:  # capucin assis
        ombre(k, 58, 18)
        k.trait([(48, 74), (30, 80), (20, 70), (24, 58), (32, 56)], 4.2, 1, ENCRE, 0.2)
        k.trait([(48, 74), (30, 80), (20, 70), (24, 58), (32, 56)], 2.8, 1, c, 0.05)
        k.forme(ellipse(56, 62, 14, 18, 20), c, w=1.8)
        k.aplat(ellipse(60, 58, 7, 10, 14), a['ventre'], 0.9)
        k.forme([(48, 74), (64, 74), (70, 84), (46, 84)], sombre(c, 0.9), w=1.4)
        k.forme([(62, 54), (70, 64), (68, 70), (63, 66)], c, w=1.3)
        k.forme(ellipse(62, 34, 11, 11, 18), c, w=1.7)
        k.forme(ellipse(65, 37, 8, 8, 16), a['ventre'], w=1.3)
        k.aplat(ellipse(61, 26, 8, 4, 12), sombre(c, 0.6), 0.95)
        k.forme(ellipse(51.5, 34, 3, 3.6, 10), a['ventre'], w=1.1)
        oeil(k, 67, 34, 1.5)
        k.trait([(66, 41), (70, 40.5)], 1.0, 0.8)
        k.hachures(lambda x, y: dans_ellipse(56, 62, 14, 18)(x, y) and x < 52, 40, 46, 56, 78)


def debout(k, a):
    """Suricate (dressé) et marmotte (assise)."""
    c = a['c']
    if a.get('sorte') == 'suricate':
        ombre(k, 58, 12)
        k.trait([(54, 80), (44, 84), (36, 82)], 3.2, 1, ENCRE, 0.2)
        k.trait([(54, 80), (44, 84), (36, 82)], 2.0, 1, c, 0.05)
        patte(k, 56, 70, SOL, 4.5, sombre(c, 0.85))
        patte(k, 62, 70, SOL, 4.5, c)
        k.forme(ellipse(59, 54, 9, 22, 20), c, w=1.8)
        k.aplat(ellipse(62, 56, 5, 15, 14), a['ventre'], 0.9)
        k.forme([(62, 42), (68, 48), (66, 50), (61, 46)], c, w=1.2)
        k.forme(ellipse(62, 26, 7.5, 7, 16), c, w=1.6)
        k.forme([(66, 23), (75, 27), (66, 30)], c, w=1.3)
        k.rond(74.5, 27, 1.0, ENCRE, contour=False)
        k.aplat(ellipse(65, 25.5, 2.6, 2.2, 10), '#3A2A1A', 0.95)
        oeil(k, 65, 25.5, 1.1)
        k.forme(ellipse(58, 21.5, 2, 1.8, 8), sombre(c, 0.6), w=1.0)
        for j in range(4):
            k.trait([(53 + j * 2, 52 + j), (57 + j * 2, 50 + j)], 1.0, 0.6, sombre(c, 0.6))
    else:  # marmotte
        ombre(k, 58, 18)
        k.forme(rot_ellipse(42, 78, 7, 4, 10, 12), sombre(c, 0.8), w=1.3)
        k.forme(ellipse(58, 60, 17, 22, 22), c, w=1.8)
        k.aplat(ellipse(62, 62, 9, 15, 16), a['ventre'], 0.9)
        k.forme(ellipse(54, 82, 6, 3, 10), sombre(c, 0.7), w=1.2)
        k.forme(ellipse(66, 82, 6, 3, 10), sombre(c, 0.7), w=1.2)
        k.forme([(64, 48), (71, 54), (68, 57), (62, 52)], c, w=1.2)
        k.forme(ellipse(62, 32, 11, 10, 18), c, w=1.7)
        k.forme(ellipse(56, 23.5, 2.6, 2.2, 8), sombre(c, 0.7), w=1.0)
        k.forme(ellipse(68, 35, 6, 4.5, 12), a['ventre'], w=1.2)
        k.rond(73, 33.5, 1.2, ENCRE, contour=False)
        k.forme([(70, 38.5), (72, 38.5), (72, 41), (70, 41)], '#F4EFE0', w=0.7, amp=0.1)
        oeil(k, 64, 29.5, 1.5)
        k.hachures(lambda x, y: dans_ellipse(58, 60, 17, 22)(x, y) and x < 50, 40, 40, 60, 82)


# ---------------------------------------------------------------- les espèces

F = 'felin'
ESPECES = {
    # Savane
    'zebre': ('q', dict(c='#F2EFE6', ventre='#FFFFFF', corps=(56, 50, 23, 12), pattes=5, sabot='#2A2422', cou=15, cou_angle=48, tete=(7, 6.5),
                        museau=(6.5, 4.6), c_museau='#3A3434', oreille='pointu', t_oreille=7, queue='fine', motif='rayures', n_rayures=8, criniere='zebre')),
    'gazelle': ('q', dict(c='#C8955A', ventre='#F4EBDD', corps=(56, 52, 20, 10), pattes=3.6, sabot='#2A2422', cou=13, cou_angle=55, tete=(6, 5.5),
                          museau=(5, 3.6), oreille='long', t_oreille=7, queue='courte', cornes='gazelle', larmes=True)),
    'autruche': ('e', dict(c='#2A2422', cou='autruche', c_pattes='#E8B8A8', c_cou='#E8C4B8', ep_cou=4.6, plumes='#F4F1EA', c_aile='#3A3434')),
    'girafe': ('q', dict(c='#E8B860', ventre='#F4E4C4', corps=(46, 50, 19, 11), pattes=4.6, sabot='#3A2A1A', cou=34, cou_angle=70, cou_l=8, tete=(6.5, 5.5),
                         museau=(5, 4), oreille='pointu', t_oreille=5, a_oreille=-60, queue='fine', motif='girafe', c_motif='#9A5A28', cornes='girafe')),
    'lion': ('q', dict(c='#D8A050', ventre='#F0D8A8', corps=(54, 54, 23, 12), pattes=6.5, felin=True, cou=8, cou_angle=25, tete=(9, 8),
                       museau=(5.5, 4.5), c_museau='#E8C890', oreille='rond', t_oreille=5, queue='longue', bout_queue='#7A4A22', criniere='lion', c_criniere='#9A5A28', c_nez='#7A4A3A')),
    'elephant': ('q', dict(c='#9A9A9E', ventre='#B4B4B8', corps=(50, 48, 27, 18), pattes=10, cou=4, cou_angle=10, cou_l=16, tete=(12, 12),
                           museau=(0, 0), trompe='elephant', grande_oreille=True, defenses=True, queue='fine', t_queue=0.8, c_nez='#9A9A9E')),
    'rhinoceros': ('q', dict(c='#9C9690', corps=(52, 52, 27, 15), pattes=9, sabot='#5A5450', cou=5, cou_angle=-5, cou_l=15, tete=(11, 8),
                             museau=(7, 6), oreille='pointu', t_oreille=6, a_oreille=-35, corne_nez=True, queue='fine', t_queue=0.7, epaules=4)),
    'vautour': ('p', dict(c='#6A5A4A', c_aile='#4A3E34', c_queue='#3A3028', c_tete='#E8B8A8', collerette='#F4F1EA', bec='crochu', c_bec='#D8C8A8')),
    # Forêt
    'cerf': ('q', dict(c='#9A6A40', ventre='#E8D4B4', corps=(56, 50, 22, 11), pattes=4.4, sabot='#2A2422', cou=15, cou_angle=55, tete=(6.5, 5.6),
                       museau=(5.5, 4), oreille='long', t_oreille=8, queue='courte', cornes='cerf')),
    'renard': ('q', dict(c='#D86A2A', ventre='#F4EFE6', corps=(54, 60, 20, 9), pattes=3.6, c_pattes='#3A2A22', cou=6, cou_angle=25, tete=(7, 6),
                         museau=(7.5, 3.4), c_museau='#F4EFE6', oreille='pointu', t_oreille=8, c_oreille='#3A2A22', queue='touffue', t_queue=1.2, moustaches=True)),
    'sanglier': ('q', dict(c='#5A4636', corps=(54, 56, 23, 13), pattes=5, sabot='#2A2422', cou=4, cou_angle=-10, cou_l=14, tete=(9, 8),
                           museau=(7, 5), c_museau='#6A5646', c_nez='#2A2422', oreille='pointu', t_oreille=6, a_oreille=-35, queue='courte', poils=True,
                           defense_sanglier=True, epaules=4)),
    'loup': ('q', dict(c='#8A8A88', ventre='#E8E6E0', corps=(54, 54, 21, 10), pattes=4.6, felin=True, cou=9, cou_angle=30, tete=(7.5, 6.5),
                       museau=(7, 3.8), c_museau='#D8D4CC', oreille='pointu', t_oreille=7, queue='touffue', bout_queue='#3A3838')),
    'ours_brun': ('q', dict(c='#6A4A2E', corps=(52, 52, 26, 16), pattes=9, felin=True, cou=6, cou_angle=10, cou_l=14, tete=(10, 9),
                            museau=(6, 4.6), c_museau='#8A6A48', oreille='rond', t_oreille=6, queue='courte', epaules=6)),
    'lynx': ('q', dict(c='#C8A070', ventre='#F0E4CC', corps=(54, 56, 20, 10), pattes=5, felin=True, cou=7, cou_angle=30, tete=(8, 7),
                       museau=(4.5, 3.6), c_museau='#F0E4CC', oreille='pointu', t_oreille=8, c_oreille='#3A2A22', queue='courte', motif='taches',
                       c_motif='#7A5A3A', r_taches=(0.9, 1.5), n_taches=14)),
    # Jungle
    'perroquet': ('p', dict(c='#D83A2A', c_aile='#2A6AC8', c_queue='#2A6AC8', ventre='#E85A3A', joue='#F4F1EA', bec='crochu', c_bec='#2A2422')),
    'capucin': ('m', dict(sorte='capucin', c='#6A4A2E', ventre='#F0E0C4')),
    'tapir': ('q', dict(c='#3A3634', ventre='#4A4644', corps=(54, 54, 24, 13), pattes=6.5, sabot='#222222', cou=4, cou_angle=0, cou_l=13, tete=(9, 7),
                        museau=(6, 4.5), trompe='tapir', oreille='rond', t_oreille=5, queue='courte', c_oreille='#D8D4CC')),
    'jaguar': ('q', dict(c='#E0A040', ventre='#F4E4C4', corps=(54, 56, 22, 10.5), pattes=5.4, felin=True, cou=7, cou_angle=25, tete=(8, 7),
                         museau=(4.5, 3.8), c_museau='#F4E4C4', oreille='rond', t_oreille=4.5, queue='longue', motif='rosettes', c_motif='#2A2422', n_taches=10)),
    'tigre': ('q', dict(c='#E8782A', ventre='#F8F0E2', corps=(54, 55, 25, 11.5), pattes=6, felin=True, cou=7, cou_angle=25, tete=(9, 7.5),
                        museau=(5, 4.2), c_museau='#F8F0E2', oreille='rond', t_oreille=5, queue='longue', bout_queue='#2A2422', motif='rayures',
                        n_rayures=9, ep_rayures=2.2, rayures_cou=True)),
    'gorille': ('m', dict(sorte='gorille', c='#2E2C2C')),
    'toucan': ('p', dict(c='#2A2422', c_aile='#3A3434', c_queue='#2A2422', ventre='#F4E0A0', joue='#F8F0C8', bec='toucan', c_bec='#F2A030')),
    # Aquatique
    'flamant': ('e', dict(c='#F0A0A8', cou='flamant', c_pattes='#E87A8A', c_aile='#E87A8A')),
    'loutre': ('l', dict(c='#7A5232', ventre='#D8C0A0')),
    'manchot': ('n', dict()),
    'phoque': ('s', dict(c='#9AA0A6')),
    'hippopotame': ('q', dict(c='#8A7A86', ventre='#C8A8A8', corps=(50, 54, 28, 16), pattes=9, cou=2, cou_angle=0, cou_l=18, tete=(12, 9),
                              museau=(8, 7), c_museau='#9A8A96', oreille='rond', t_oreille=4, queue='courte', t_nez=1.6)),
    'crocodile': ('r', dict(c='#5A7A44', ventre='#C8C890', crete=True, long_museau=True)),
    # Montagne
    'chevre': ('q', dict(c='#F2EFE6', ventre='#FFFFFF', corps=(56, 54, 20, 11), pattes=4.6, sabot='#3A3434', cou=11, cou_angle=50, tete=(6.5, 6),
                         museau=(5, 3.8), oreille='long', t_oreille=6, cornes='chevre', barbe='#F2EFE6', queue='courte')),
    'marmotte': ('d', dict(sorte='marmotte', c='#9A7048', ventre='#D8B888')),
    'panda_roux': ('q', dict(c='#C8582A', ventre='#3A2A22', corps=(56, 58, 19, 9.5), pattes=4.6, felin=True, c_pattes='#2E2420', cou=5, cou_angle=20,
                             tete=(8, 7), museau=(4, 3.4), c_museau='#F4F1EA', masque='#F4F1EA', oreille='pointu', t_oreille=5.5, c_oreille='#F4F1EA',
                             queue='anneaux', t_queue=1.2)),
    'yak': ('q', dict(c='#3A2E26', corps=(52, 52, 26, 15), pattes=7, sabot='#1A1412', cou=4, cou_angle=0, cou_l=14, tete=(9, 8), museau=(6, 5),
                      c_museau='#4A3E36', cornes='yak', queue='touffue', poils=True, epaules=6)),
    'panthere_neiges': ('q', dict(c='#D8D4C8', ventre='#F4F1EA', corps=(54, 56, 22, 10.5), pattes=5.4, felin=True, cou=7, cou_angle=25, tete=(8, 7),
                                  museau=(4.5, 3.8), c_museau='#F4F1EA', oreille='rond', t_oreille=4.5, queue='longue', t_queue=1.2, motif='rosettes',
                                  c_motif='#5A5450', n_taches=10)),
    'aigle_royal': ('p', dict(c='#6A4A2E', c_aile='#4A3220', c_queue='#3A2A1A', c_tete='#B8884A', bec='aigle', c_bec='#3A3434')),
    # Désert
    'suricate': ('d', dict(sorte='suricate', c='#C8A478', ventre='#E8D4B4')),
    'fennec': ('q', dict(c='#E8CC98', ventre='#F8F0E2', corps=(54, 62, 16, 8), pattes=3.4, cou=5, cou_angle=25, tete=(6.5, 5.5),
                         museau=(6, 3), c_museau='#F8F0E2', oreille='pointu', t_oreille=14, a_oreille=-15, queue='touffue', bout_queue='#3A2A22', moustaches=True)),
    'dromadaire': ('q', dict(c='#C89A60', ventre='#E0C090', corps=(52, 46, 23, 12), pattes=5, sabot='#5A4636', cou=18, cou_angle=55, cou_l=8,
                             tete=(7, 5.5), museau=(6, 4), oreille='rond', t_oreille=3.5, queue='fine', bosse=True)),
    'addax': ('q', dict(c='#E8DCC4', ventre='#F8F4EA', corps=(56, 52, 21, 11), pattes=4.6, sabot='#3A3434', cou=11, cou_angle=45, tete=(6.5, 6),
                        museau=(5, 4), c_tete='#C8B8A0', oreille='long', t_oreille=6, cornes='addax', queue='fine')),
    'dragon_komodo': ('r', dict(c='#7A7060', ventre='#9A9080')),
}
DESSINS = {'q': quadrupede, 'p': oiseau_perche, 'e': echassier, 'n': manchot, 'r': reptile, 's': phoque, 'l': loutre,
           'm': primate, 'd': debout}


def main():
    especes = json.load(io.open(os.path.join(RACINE, 'data', 'animals.json'), encoding='utf-8'))['animaux']
    manquants = [e['id'] for e in especes if e['id'] not in ESPECES]
    assert not manquants, 'Espèces sans dessin : %s' % manquants
    for e in especes:
        sorte, params = ESPECES[e['id']]
        k = Croquis(zlib.crc32(e['id'].encode()))
        DESSINS[sorte](k, params)
        ecrire_svg(os.path.join(RACINE, 'ui', 'animaux', e['id'] + '.svg'), W, H, k.out)
    print('%d animaux' % len(especes))


if __name__ == '__main__':
    main()
