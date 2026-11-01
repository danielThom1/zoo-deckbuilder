"""Cinq rendus dessinés du même monde (palette « Néo ligne claire »).
Usage : python3 monde.py  -> svg/*.svg puis rendu PNG/JPEG par rendu.py"""
import json, math, os
import numpy as np
from PIL import Image
from scipy import ndimage as nd
from skimage import measure

ICI = os.path.dirname(os.path.abspath(__file__))
W, H, S = 1600, 900, 4            # monde en px, pas de la grille de calcul
GW, GH = W // S, H // S
rng = np.random.default_rng(7)

# ------------------------------------------------------------------ palette C
C = dict(ink='#14202B', grass='#94C66A', grass2='#82B758', grass3='#A6D27C', foret='#5E9A48', foret2='#4C8A3C',
         roche='#C9C6BC', roche2='#ADA99E', mont='#B8B0A2', mont2='#8E8578', neige='#FFFFFF', eau='#4FB3D9', eau2='#2E8EC0',
         berge='#A8E6EE', sable='#EDCB82', sable2='#D9B46A', route='#F2DDB0', allee='#FAF0D8', zoo='#A9D47F', mur='#E4E0D4',
         bois='#B07A3E', boisF='#7C4F22', sel='#FFC93C')

# ------------------------------------------------------------------ champs
def bruit(sigma, seed):
    r = np.random.default_rng(seed).standard_normal((GH, GW))
    f = nd.gaussian_filter(r, sigma)
    return (f - f.mean()) / f.std()

yy, xx = np.mgrid[0:GH, 0:GW] * S + S / 2
elev = bruit(9, 1) * 0.55 + bruit(3, 2) * 0.18
massif = np.clip((xx - 1210) / 230, 0, 1) * np.clip((480 - yy) / 260, 0, 1)
elev += massif * 2.5  # massif nord-est
elev -= np.clip((xx - 700) / 900, -1, 1) * 0.1

def dist_polyline(pts):
    d = np.full((GH, GW), 1e9)
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        vx, vy = x1 - x0, y1 - y0
        if vx * vx + vy * vy < 1e-9:
            continue
        t = np.clip(((xx - x0) * vx + (yy - y0) * vy) / (vx * vx + vy * vy), 0, 1)
        d = np.minimum(d, np.hypot(xx - (x0 + t * vx), yy - (y0 + t * vy)))
    return d

def bezier(p0, p1, p2, p3, n=40):
    t = np.linspace(0, 1, n)[:, None]
    return ((1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3)

riv_pts = np.vstack([bezier(np.array([1190, -30]), np.array([1160, 120]), np.array([1110, 220]), np.array([1150, 320])),
                     bezier(np.array([1150, 320]), np.array([1190, 420]), np.array([1240, 480]), np.array([1205, 560])),
                     bezier(np.array([1205, 560]), np.array([1170, 650]), np.array([1140, 800]), np.array([1185, 940]))])
largeur = 27 + 5 * np.sin(yy / 70)
d_riv = dist_polyline(riv_pts)
eau = d_riv < largeur
lac = ((xx - 250) / 120) ** 2 + ((yy - 770) / 62) ** 2 + bruit(4, 9) * 0.12 < 1
eau |= lac

routes_pts = [np.array([[800, 940], [800, 445]]), bezier(np.array([800, 612]), np.array([900, 606]), np.array([990, 622]), np.array([1085, 628])),
              bezier(np.array([800, 606]), np.array([700, 600]), np.array([600, 612]), np.array([470, 618])),
              np.vstack([bezier(np.array([1085, 628]), np.array([1150, 600]), np.array([1170, 540]), np.array([1210, 528])),
                         bezier(np.array([1210, 528]), np.array([1290, 510]), np.array([1350, 470]), np.array([1430, 440]))])]
d_route = np.min([dist_polyline(p) for p in routes_pts], axis=0)

zoo_rect = (505, 130, 1105, 445)
dans_zoo = (xx > zoo_rect[0] - 18) & (xx < zoo_rect[2] + 18) & (yy > zoo_rect[1] - 18) & (yy < zoo_rect[3] + 30)
camp_zone = ((xx - 800) / 230) ** 2 + ((yy - 680) / 130) ** 2 < 1
bati = camp_zone | (((xx - 470) / 90) ** 2 + ((yy - 610) / 70) ** 2 < 1) | (((xx - 1060) / 110) ** 2 + ((yy - 640) / 70) ** 2 < 1)
libre = ~dans_zoo & (d_route > 26) & ~bati

mont = (elev > 1.75) & (massif > 0.35) & ~eau
roche = (((elev > 0.75) & (massif > 0.08)) | ((bruit(3, 77) > 2.0) & (xx < 420) & (yy < 560))) & ~mont & ~eau & (d_riv > largeur + 8) & libre
f_for = bruit(7, 3) * 0.7 + np.clip((520 - xx) / 300, -1, 1.4) + np.clip((140 - yy) / 120, 0, 1) * 0.9 + np.clip((yy - 760) / 160, 0, 1) * np.clip((560 - xx) / 300, 0, 1) * 1.2
foret = (f_for > 0.62) & libre & ~eau & ~mont & ~roche & (np.hypot(xx - 470, yy - 424) > 46)
foret |= (bruit(4, 5) > 1.6) & libre & ~eau & ~mont & ~roche & (xx > 1250)
sable = ((d_riv > largeur) & (d_riv < largeur + 16 + 8 * bruit(3, 6)) & (bruit(6, 8) > 0.35)) & ~eau & ~mont & ~roche & ~foret & libre
sable |= nd.binary_dilation(roche | mont, iterations=3) & ~roche & ~mont & ~eau & ~foret & libre & (massif > 0.05) & (bruit(3, 11) > -0.3)

def nettoie(m, n=1):
    return nd.binary_opening(nd.binary_closing(m, iterations=n), iterations=n)
eau, mont, roche, foret, sable = nettoie(eau), nettoie(mont), nettoie(roche), nettoie(foret, 2), nettoie(sable)

# ------------------------------------------------------------------ outils géométriques
def chaikin(p, it=2):
    for _ in range(it):
        q = p[:-1] * 0.75 + p[1:] * 0.25
        r = p[:-1] * 0.25 + p[1:] * 0.75
        p = np.empty((len(q) * 2, 2)); p[0::2] = q; p[1::2] = r
        p = np.vstack([p, p[:1]])
    return p

def contours(mask, sigma=1.1, niveau=0.5, min_pts=6):
    f = np.pad(nd.gaussian_filter(mask.astype(float), sigma), 2)
    out = []
    for c in measure.find_contours(f, niveau):
        if len(c) < min_pts:
            continue
        pts = (c[:, ::-1] - 2) * S + S / 2
        pts = pts[::2]
        if len(pts) < 4:
            continue
        pts = chaikin(np.vstack([pts, pts[:1]]), 2)
        out.append('M' + ' L'.join(f'{x:.1f},{y:.1f}' for x, y in pts) + 'Z')
    return ' '.join(out)

def iso(champ, niveau, sigma=0.6):
    f = nd.gaussian_filter(champ, sigma)
    out = []
    for c in measure.find_contours(f, niveau):
        if len(c) < 10:
            continue
        pts = c[:, ::-1] * S + S / 2
        pts = pts[::2]
        out.append('M' + ' L'.join(f'{x:.1f},{y:.1f}' for x, y in pts))
    return ' '.join(out)

def semis(mask, ecart, seed, n_max=4000, marge=0):
    r = np.random.default_rng(seed)
    pts = []
    cell = ecart / math.sqrt(2)
    grille = {}
    essais = 0
    cand = np.argwhere(mask)
    if len(cand) == 0:
        return pts
    while len(pts) < n_max and essais < n_max * 12:
        essais += 1
        gy, gx = cand[r.integers(len(cand))]
        x, y = gx * S + r.uniform(0, S), gy * S + r.uniform(0, S)
        if x < marge or y < marge or x > W - marge or y > H - marge:
            continue
        ci, cj = int(x // cell), int(y // cell)
        ok = True
        for di in (-2, -1, 0, 1, 2):
            for dj in (-2, -1, 0, 1, 2):
                for (px, py) in grille.get((ci + di, cj + dj), ()):
                    if (px - x) ** 2 + (py - y) ** 2 < ecart * ecart:
                        ok = False; break
                if not ok: break
            if not ok: break
        if ok:
            pts.append((x, y)); grille.setdefault((ci, cj), []).append((x, y))
    return pts

def m_at(mask, x, y):
    gx, gy = int(x // S), int(y // S)
    return 0 <= gx < GW and 0 <= gy < GH and bool(mask[gy, gx])

hill = None
def ombrage():
    gy_, gx_ = np.gradient(nd.gaussian_filter(elev, 1.5))
    lx, ly = -0.7, -0.7
    return -(gx_ * lx + gy_ * ly) * 6

# ------------------------------------------------------------------ sprites
FEUILLES = {'s1': ('../bd/assets_bd.png', 1536, 1024), 'an': ('animaux.png', 1536, 1024), 'g1': ('gens1.png', 1536, 1024), 'g2': ('gens2.png', 1536, 1024)}
_alpha = {k: np.array(Image.open(os.path.join(ICI, v[0])))[:, :, 3] for k, v in FEUILLES.items()}

def serre(f, x0, y0, x1, y1):
    a = _alpha[f][y0:y1, x0:x1] > 40
    ys, xs = np.nonzero(a)
    return (x0 + xs.min(), y0 + ys.min(), xs.max() - xs.min() + 1, ys.max() - ys.min() + 1)

SP = {
    # feuille 1 : bâtiments, arbres, décor
    'maison': ('s1', (7, 14, 158, 140)), 'entrepot': ('s1', (173, 14, 177, 142)), 'souvenirs': ('s1', (799, 19, 153, 143)), 'snack': ('s1', (1268, 31, 126, 134)),
    'formation': ('s1', (6, 172, 192, 158)), 'entree': ('s1', (198, 172, 196, 156)), 'mine': ('s1', (643, 31, 151, 133)), 'camp': ('s1', (991, 179, 212, 152)),
    'chantier': ('s1', (1210, 194, 158, 136)), 'pont': ('s1', (1268, 433, 145, 72)), 'arbre1': ('s1', (9, 518, 107, 120)), 'arbre2': ('s1', (125, 520, 85, 116)),
    'arbre3': ('s1', (218, 516, 83, 114)), 'arbre4': ('s1', (310, 516, 82, 114)), 'sapin1': ('s1', (394, 516, 80, 113)), 'sapin2': ('s1', (473, 533, 65, 96)),
    'buisson': ('s1', (623, 519, 63, 57)), 'rocher': ('s1', (763, 544, 85, 70)), 'rocher_or': ('s1', (848, 544, 78, 70)), 'cailloux': ('s1', (547, 528, 73, 92)),
    'montagnes': ('s1', (1042, 514, 253, 109)), 'souche': ('s1', (926, 576, 54, 38)), 'bassin': ('s1', (1296, 542, 103, 82)), 'tas_bois': ('s1', (8, 964, 108, 49)), 'tas_pierre': ('s1', (125, 964, 86, 53)),
    # animaux
    'zebre': ('an', serre('an', 128, 25, 224, 128)), 'zebre2': ('an', serre('an', 226, 48, 342, 128)), 'girafe': ('an', serre('an', 458, 8, 528, 142)),
    'girafon': ('an', serre('an', 528, 55, 574, 142)), 'lion': ('an', serre('an', 720, 32, 800, 142)), 'lionne': ('an', serre('an', 798, 72, 916, 142)),
    'elephant': ('an', serre('an', 1060, 40, 1166, 138)), 'rhino': ('an', serre('an', 1166, 62, 1258, 138)), 'autruche': ('an', serre('an', 10, 725, 120, 824)),
    'tigre': ('an', serre('an', 128, 165, 238, 262)), 'tigre_c': ('an', serre('an', 238, 185, 354, 262)), 'flamant': ('an', serre('an', 255, 728, 342, 826)),
    'hippo': ('an', serre('an', 1278, 728, 1432, 818)), 'croco': ('an', serre('an', 12, 828, 262, 892)), 'cerf': ('an', serre('an', 120, 505, 220, 610)),
    # personnes
    'bucheron': ('g1', serre('g1', 492, 362, 622, 556)), 'porteur_planche': ('g1', serre('g1', 10, 352, 134, 556)), 'brouette': ('g1', serre('g1', 250, 362, 388, 552)),
    'piocheur': ('g1', serre('g1', 828, 762, 930, 885)), 'marcheur1': ('g1', serre('g1', 168, 762, 245, 885)), 'marcheur2': ('g1', serre('g1', 515, 755, 600, 882)),
    'pelleteur': ('g1', serre('g1', 930, 762, 1028, 885)), 'brouette_m': ('g1', serre('g1', 380, 760, 515, 885)), 'arpenteur': ('g1', serre('g1', 12, 565, 130, 750)),
    'soigneur': ('g2', serre('g2', 822, 365, 935, 585)), 'jardinier': ('g2', serre('g2', 668, 365, 812, 585)),
    'visiteur_canne': ('g2', serre('g2', 664, 800, 790, 1012)), 'visiteuse_sac': ('g2', serre('g2', 815, 800, 922, 1012)), 'enfant1': ('g2', serre('g2', 1290, 838, 1372, 1012)),
    'enfant2': ('g2', serre('g2', 1420, 842, 1500, 1012)), 'randonneur': ('g2', serre('g2', 505, 800, 628, 1012)), 'visiteur_sweat': ('g2', serre('g2', 988, 800, 1078, 1012)),
}

def sprite(nom, x, y, haut, ombre=True, flip=False, styl_ombre='plein'):
    f, (sx, sy, sw, sh) = SP[nom]
    k = haut / sh
    w, h = sw * k, sh * k
    fw, fh = FEUILLES[f][1], FEUILLES[f][2]
    out = ''
    if ombre:
        if styl_ombre == 'hachure':
            out += f'<ellipse cx="{x + w * 0.08:.1f}" cy="{y - 1:.1f}" rx="{w * 0.46:.1f}" ry="{max(3, w * 0.11):.1f}" fill="url(#hach)"/>'
        else:
            out += f'<ellipse cx="{x + w * 0.08:.1f}" cy="{y - 1:.1f}" rx="{w * 0.44:.1f}" ry="{max(3, w * 0.1):.1f}" fill="{C["ink"]}" opacity="0.2"/>'
    corps = (f'<svg x="{x - w / 2:.1f}" y="{y - h:.1f}" width="{w:.1f}" height="{h:.1f}" viewBox="{sx} {sy} {sw} {sh}" preserveAspectRatio="none" overflow="hidden">'
             f'<image href="{f}.png" width="{fw}" height="{fh}"/></svg>')
    out += f'<g transform="translate({2 * x:.1f},0) scale(-1,1)">{corps}</g>' if flip else corps
    return out

# ------------------------------------------------------------------ éléments communs (zoo, routes, bâtiments, animaux, gens)
def elements_communs(var):
    ink = C['ink']
    lw = {'trait': 2.6, 'gravure': 2.2, 'atlas': 1.8, 'illustre': 2.8, 'tuiles': 2.6}[var]
    o = []
    # routes
    for p in routes_pts:
        d = 'M' + ' L'.join(f'{x:.1f},{y:.1f}' for x, y in p)
        o.append(f'<path d="{d}" fill="none" stroke="{ink}" stroke-width="{24 + 2 * lw:.1f}" stroke-linecap="round" stroke-linejoin="round"/>')
    for p in routes_pts:
        d = 'M' + ' L'.join(f'{x:.1f},{y:.1f}' for x, y in p)
        o.append(f'<path d="{d}" fill="none" stroke="{C["route"]}" stroke-width="24" stroke-linecap="round" stroke-linejoin="round"/>')
        if var in ('gravure', 'illustre', 'atlas'):
            o.append(f'<path d="{d}" fill="none" stroke="{ink}" stroke-width="1" stroke-dasharray="2 9" opacity="0.4" transform="translate(0,-5)"/>')
            o.append(f'<path d="{d}" fill="none" stroke="{ink}" stroke-width="1" stroke-dasharray="1 13" opacity="0.35" transform="translate(3,4)"/>')
        if var == 'illustre':
            for t in np.linspace(0.05, 0.95, 9):
                i = int(t * (len(p) - 1)); x, y = p[i]
                o.append(f'<ellipse cx="{x + 7:.1f}" cy="{y + 2:.1f}" rx="2.6" ry="1.8" fill="#D9C08C" stroke="{ink}" stroke-width="0.8"/>')
    # intérieur du zoo
    x0, y0, x1, y1 = zoo_rect
    o.append(f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" fill="{C["zoo"]}"/>')
    o.append(f'<path d="M800,445 L800,352 M520,352 L1090,352" stroke="{ink}" stroke-width="{20 + 2 * lw:.1f}" stroke-linecap="round" fill="none"/>')
    o.append(f'<path d="M800,445 L800,352 M520,352 L1090,352" stroke="{C["allee"]}" stroke-width="20" stroke-linecap="round" fill="none"/>')
    o.append(f'<path d="M800,445 L800,352 M520,352 L1090,352" stroke="{ink}" stroke-width="20" stroke-dasharray="1 10" opacity="0.18" fill="none"/>')
    # enclos
    for (ex, ey, ew, eh, sol) in [(525, 152, 250, 178, C['sable']), (828, 152, 256, 178, C['foret'])]:
        o.append(f'<rect x="{ex}" y="{ey}" width="{ew}" height="{eh}" fill="{sol}"/>')
        if sol == C['sable']:
            for (px, py) in semis(np.zeros((GH, GW), bool) | ((xx > ex) & (xx < ex + ew) & (yy > ey) & (yy < ey + eh)), 14, 31, 400):
                o.append(f'<circle cx="{px:.1f}" cy="{py:.1f}" r="0.9" fill="{ink}" opacity="0.35"/>')
        else:
            for (px, py) in semis(((xx > ex) & (xx < ex + ew) & (yy > ey) & (yy < ey + eh)), 16, 32, 400):
                o.append(f'<path d="M{px - 3:.1f},{py:.1f} l1.5,-5 M{px:.1f},{py:.1f} l0,-6 M{px + 3:.1f},{py:.1f} l-1.5,-5" stroke="{ink}" stroke-width="1" opacity="0.4" fill="none"/>')
        o.append(f'<rect x="{ex}" y="{ey}" width="{ew}" height="{eh}" fill="none" stroke="{ink}" stroke-width="9"/>')
        o.append(f'<rect x="{ex}" y="{ey}" width="{ew}" height="{eh}" fill="none" stroke="{C["bois"]}" stroke-width="5"/>')
        o.append(f'<rect x="{ex}" y="{ey}" width="{ew}" height="{eh}" fill="none" stroke="{ink}" stroke-width="1"/>')
        for x in range(ex, ex + ew + 1, 32):
            for y in (ey, ey + eh):
                o.append(f'<rect x="{x - 3.5}" y="{y - 3.5}" width="7" height="7" rx="1.5" fill="{C["boisF"]}" stroke="{ink}" stroke-width="1.2"/>')
        for y in range(ey + 32, ey + eh, 32):
            for x in (ex, ex + ew):
                o.append(f'<rect x="{x - 3.5}" y="{y - 3.5}" width="7" height="7" rx="1.5" fill="{C["boisF"]}" stroke="{ink}" stroke-width="1.2"/>')
    # enceinte
    mur = 'M762,445 L505,445 L505,130 L1105,130 L1105,445 L838,445'
    o.append(f'<path d="{mur}" fill="none" stroke="{ink}" stroke-width="17" stroke-linejoin="round"/>')
    o.append(f'<path d="{mur}" fill="none" stroke="{C["mur"]}" stroke-width="11" stroke-linejoin="round"/>')
    o.append(f'<path d="{mur}" fill="none" stroke="{ink}" stroke-width="11" stroke-dasharray="1.2 12" opacity="0.55"/>')
    # sélection et chantier
    o.append(f'<ellipse cx="470" cy="426" rx="36" ry="13" fill="none" stroke="{C["sel"]}" stroke-width="4"/>')
    o.append(f'<ellipse cx="470" cy="426" rx="36" ry="13" fill="none" stroke="{ink}" stroke-width="1.2" stroke-dasharray="4 4"/>')
    return o

def acteurs(var):
    so = 'hachure' if var == 'gravure' else 'plein'
    L = []
    def a(n, x, y, h, flip=False, ombre=True):
        L.append((y, n, x, h, flip, ombre))
    # zoo
    a('arbre1', 870, 216, 52); a('sapin2', 960, 200, 46); a('arbre3', 1062, 236, 50); a('bassin', 1010, 318, 40, ombre=False)
    a('tigre', 905, 316, 44); a('tigre_c', 1040, 290, 30, True)
    a('autruche', 570, 250, 46); a('girafe', 625, 304, 86); a('girafon', 655, 312, 46); a('zebre', 712, 290, 46); a('zebre2', 742, 326, 40, True)
    a('souvenirs', 620, 440, 64); a('snack', 985, 440, 60)
    for n, x, y, f in [('visiteuse_sac', 700, 370, False), ('visiteur_canne', 738, 374, True), ('enfant1', 755, 380, False), ('randonneur', 880, 368, True), ('visiteur_sweat', 1030, 370, False), ('enfant2', 820, 426, True), ('visiteur_canne', 560, 368, False)]:
        a(n, x, y, 38 if 'enfant' not in n else 28, f)
    a('entree', 800, 474, 82, ombre=False)
    # camp, bâtiments
    a('formation', 470, 652, 84); a('maison', 640, 706, 70); a('maison', 590, 792, 66, True); a('camp', 800, 718, 108, ombre=False); a('entrepot', 965, 714, 70)
    a('chantier', 1080, 644, 74); a('tas_bois', 1015, 662, 18); a('tas_pierre', 1140, 670, 18)
    a('pont', 1206, 532, 42, ombre=False)
    a('mine', 1430, 432, 64)
    # gens au travail
    a('bucheron', 470, 426, 50); a('porteur_planche', 420, 504, 46, True); a('piocheur', 1302, 364, 42); a('brouette_m', 800, 590, 42); a('marcheur1', 920, 622, 40)
    a('pelleteur', 1112, 676, 42, True); a('marcheur2', 700, 610, 40, True); a('arpenteur', 1180, 700, 46)
    return L, so

def dessiner_acteurs(var):
    L, so = acteurs(var)
    L.sort(key=lambda t: t[0])
    return [sprite(n, x, y, h, ombre=om, flip=f, styl_ombre=so) for (y, n, x, h, f, om) in L]

# ------------------------------------------------------------------ défs communes
def defs():
    ink = C['ink']
    return f'''<defs>
<pattern id="hach" width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="5" stroke="{ink}" stroke-width="1.1" opacity="0.55"/></pattern>
<pattern id="hachL" width="7" height="7" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><line x1="0" y1="0" x2="0" y2="7" stroke="{ink}" stroke-width="0.9" opacity="0.35"/></pattern>
<pattern id="hachX" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(-35)"><line x1="0" y1="0" x2="0" y2="6" stroke="{ink}" stroke-width="0.9" opacity="0.4"/></pattern>
<pattern id="trame" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(30)"><circle cx="2" cy="2" r="1.3" fill="{ink}" opacity="0.2"/></pattern>
<pattern id="vagues" width="26" height="12" patternUnits="userSpaceOnUse"><path d="M1,8 q6,-5 12,0" fill="none" stroke="#FFFFFF" stroke-width="1.2" opacity="0.55"/><path d="M14,3 q5,-4 10,0" fill="none" stroke="{ink}" stroke-width="0.8" opacity="0.18"/></pattern>
<pattern id="lignesEau" width="14" height="6" patternUnits="userSpaceOnUse"><line x1="0" y1="3" x2="10" y2="3" stroke="{ink}" stroke-width="1" opacity="0.4"/><line x1="10" y1="3" x2="13" y2="3" stroke="#FFFFFF" stroke-width="1" opacity="0.6"/></pattern>
<pattern id="points" width="9" height="9" patternUnits="userSpaceOnUse"><circle cx="2" cy="3" r="0.8" fill="{ink}" opacity="0.4"/><circle cx="7" cy="7" r="0.6" fill="{ink}" opacity="0.3"/></pattern>
</defs>'''

def tufts(mask, ecart, seed, op=0.4, taille=1.0, n=3000):
    ink = C['ink']; o = []
    for (x, y) in semis(mask, ecart, seed, n):
        k = taille * (0.8 + 0.4 * ((x * 7 + y * 3) % 10) / 10)
        o.append(f'<path d="M{x - 3 * k:.1f},{y:.1f} l{1.5 * k:.1f},{-5 * k:.1f} M{x:.1f},{y:.1f} l0,{-6.5 * k:.1f} M{x + 3 * k:.1f},{y:.1f} l{-1.5 * k:.1f},{-5 * k:.1f}" stroke="{ink}" stroke-width="1" stroke-linecap="round" opacity="{op}" fill="none"/>')
    return o

def fond_terrain(lw, details=True):
    """Aplats + contours encrés de chaque terrain (base commune)."""
    ink = C['ink']; o = [f'<rect width="{W}" height="{H}" fill="{C["grass"]}"/>']
    var2 = (bruit(5, 21) > 0.55) & ~eau
    o.append(f'<path d="{contours(var2, 1.6)}" fill="{C["grass2"]}" fill-rule="evenodd" stroke="{ink}" stroke-width="{lw * 0.4:.1f}" stroke-opacity="0.35"/>')
    var3 = (bruit(5, 22) > 0.9) & ~eau
    o.append(f'<path d="{contours(var3, 1.6)}" fill="{C["grass3"]}" fill-rule="evenodd"/>')
    for m, col in [(sable, C['sable']), (foret, C['foret']), (roche, C['roche']), (mont, C['mont'])]:
        o.append(f'<path d="{contours(m)}" fill="{col}" fill-rule="evenodd" stroke="{ink}" stroke-width="{lw:.1f}" stroke-linejoin="round"/>')
    return o

def dessiner_eau(lw, style):
    ink = C['ink']; d = contours(eau, 1.0); o = []
    o.append(f'<clipPath id="clipEau"><path d="{d}" fill-rule="evenodd"/></clipPath>')
    o.append(f'<path d="{d}" fill="{C["berge"]}" fill-rule="evenodd" stroke="{ink}" stroke-width="{lw * 2.6:.1f}" stroke-linejoin="round"/>')
    o.append(f'<path d="{d}" fill="{C["berge"]}" fill-rule="evenodd"/>')
    eau_int = nd.binary_erosion(eau, iterations=2)
    o.append(f'<path d="{contours(eau_int, 1.0)}" fill="{C["eau"]}" fill-rule="evenodd" stroke="{ink}" stroke-width="0.8" stroke-opacity="0.4"/>')
    prof = nd.binary_erosion(eau, iterations=5)
    o.append(f'<path d="{contours(prof, 1.2)}" fill="{C["eau2"]}" fill-rule="evenodd" opacity="0.65"/>')
    if style in ('trait', 'illustre', 'tuiles'):
        o.append(f'<g clip-path="url(#clipEau)"><rect width="{W}" height="{H}" fill="url(#vagues)"/></g>')
    if style == 'gravure':
        o.append(f'<g clip-path="url(#clipEau)"><rect width="{W}" height="{H}" fill="url(#lignesEau)"/></g>')
    if style == 'atlas':
        for k in (3, 6, 10):
            o.append(f'<path d="{contours(nd.binary_erosion(eau, iterations=k), 1.0)}" fill="none" stroke="{ink}" stroke-width="0.8" opacity="0.35"/>')
    return o

# ------------------------------------------------------------------ variantes
def v_trait():
    """1 · Trait fin : aplats propres, contours encrés, détails légers (touffes, rides, fissures)."""
    ink = C['ink']; lw = 2.6; o = fond_terrain(lw)
    o += tufts(~eau & ~foret & ~mont & ~roche & ~sable & libre, 26, 1, 0.38)
    o.append(f'<path d="{contours(sable)}" fill="url(#points)" fill-rule="evenodd"/>')
    for (x, y) in semis(roche, 26, 2, 400):
        o.append(f'<path d="M{x - 5:.1f},{y:.1f} l4,-3 l3,2 l4,-4" stroke="{ink}" stroke-width="1.1" fill="none" opacity="0.5"/>')
    o += dessiner_eau(lw, 'trait')
    o += elements_communs('trait')
    arbres = []
    for (x, y) in semis(foret, 22, 3, 900, 6):
        arbres.append((y, x))
    for (x, y) in semis(roche, 70, 4, 60):
        arbres.append((y, x, 'rocher' if (int(x) % 3) else 'cailloux'))
    for (x, y) in semis(mont, 85, 5, 20):
        arbres.append((y, x, 'montagnes'))
    o += planter(arbres, 'plein')
    o += dessiner_acteurs('trait')
    return o

def planter(liste, so, hauteur=(40, 56)):
    o = []
    noms = ['arbre1', 'arbre2', 'arbre3', 'arbre4', 'sapin1', 'sapin2', 'arbre2', 'arbre3']
    for it in sorted(liste, key=lambda t: t[0]):
        y, x = it[0], it[1]
        if len(it) == 3:
            n = it[2]; h = {'rocher': 30, 'cailloux': 34, 'montagnes': 58 + int(x * 7) % 34}[n]
        else:
            n = noms[int(x * 13 + y * 7) % len(noms)]; h = hauteur[0] + (int(x * 3 + y) % (hauteur[1] - hauteur[0]))
        o.append(sprite(n, x, y + 4, h, ombre=True, flip=(int(x + y) % 2 == 0), styl_ombre=so))
    return o

def v_gravure():
    """2 · Gravure : relief et ombres traités en hachures, eau en traits horizontaux, sable pointillé."""
    ink = C['ink']; lw = 2.2; o = fond_terrain(lw)
    sh = ombrage()
    portee = (nd.shift(foret.astype(float), (2, 2), order=0) > 0.5) & ~foret & ~eau
    o.append(f'<path d="{contours(portee, 0.8)}" fill="url(#hach)" fill-rule="evenodd"/>')
    for niveau, pat in [(0.12, 'hachL'), (0.45, 'hach')]:
        m = (sh > niveau) & ~eau
        o.append(f'<path d="{contours(m, 1.4)}" fill="url(#{pat})" fill-rule="evenodd"/>')
    m = (sh > 0.9) & (mont | roche)
    o.append(f'<path d="{contours(m, 1.2)}" fill="url(#hachX)" fill-rule="evenodd"/>')
    o.append(f'<path d="{contours(foret)}" fill="url(#hachL)" fill-rule="evenodd"/>')
    o.append(f'<path d="{contours(sable)}" fill="url(#points)" fill-rule="evenodd"/>')
    # herbe : traits courts verticaux, densité selon le bruit
    dens = bruit(4, 40)
    for (x, y) in semis(~eau & ~foret & ~mont & ~roche & ~sable & libre, 11, 41, 3500):
        if dens[int(y // S), int(x // S)] > -0.4:
            o.append(f'<path d="M{x:.1f},{y:.1f} l0.8,-5.5 M{x + 2.5:.1f},{y + 0.5:.1f} l-0.4,-4" stroke="{ink}" stroke-width="1" opacity="0.5"/>')
    for (x, y) in semis(roche, 20, 42, 600):
        o.append(f'<path d="M{x - 6:.1f},{y:.1f} l5,-4 l3,3 l5,-5 M{x:.1f},{y - 1:.1f} l2,4" stroke="{ink}" stroke-width="1" fill="none" opacity="0.55"/>')
    o += dessiner_eau(lw, 'gravure')
    o += elements_communs('gravure')
    arbres = [(y, x) for (x, y) in semis(foret, 21, 43, 900, 6)]
    o += planter(arbres, 'hachure')
    objets = [(y, rocher_dessine(x, y, 8 + int(x) % 7, int(x * y), 'hachX')) for (x, y) in semis(roche, 24, 44, 200)]
    objets += [(y + 14, montagne_dessinee(x, y + 14, 70 + int(x * 7) % 60, int(x * 13 + y), 'hachX')) for (x, y) in semis(mont, 46, 45, 60)]
    for y, sv in sorted(objets, key=lambda t: t[0]):
        o.append(sv)
    o += dessiner_acteurs('gravure')
    return o

def v_atlas():
    """3 · Atlas : courbes de niveau, hachures de relief, forêts en symboles, rivage en lignes concentriques."""
    ink = C['ink']; lw = 1.8; o = fond_terrain(lw)
    for i, lv in enumerate(np.arange(-1.2, 3.2, 0.22)):
        maitresse = i % 4 == 0
        o.append(f'<path d="{iso(elev, lv)}" fill="none" stroke="{ink}" stroke-width="{1.1 if maitresse else 0.6}" opacity="{0.45 if maitresse else 0.25}"/>')
    # hachures de pente (perpendiculaires au relief) sur roche et montagne
    gy_, gx_ = np.gradient(nd.gaussian_filter(elev, 1.2))
    for (x, y) in semis(mont | roche, 7, 50, 2500):
        j, i = int(y // S), int(x // S)
        g = np.array([gx_[j, i], gy_[j, i]]); n = np.linalg.norm(g)
        if n < 1e-3: continue
        g = g / n * min(9, 3 + n * 40)
        o.append(f'<path d="M{x:.1f},{y:.1f} l{g[0]:.1f},{g[1]:.1f}" stroke="{ink}" stroke-width="0.9" opacity="0.5"/>')
    # cultures/prairie : pointillés en rangs
    o.append(f'<path d="{contours(sable)}" fill="url(#points)" fill-rule="evenodd"/>')
    o += dessiner_eau(lw, 'atlas')
    o += elements_communs('atlas')
    # forêt en symboles d'arbres (cercles encrés + ombre)
    pts = sorted(semis(foret, 12, 51, 3000, 4), key=lambda p: p[1])
    for (x, y) in pts:
        r = 6.5 + (int(x * 7 + y) % 3)
        col = [C['foret'], C['foret2'], '#6FAE52'][int(x + y) % 3]
        o.append(f'<circle cx="{x + 2:.1f}" cy="{y + 2:.1f}" r="{r:.1f}" fill="{ink}" opacity="0.25"/><circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{col}" stroke="{ink}" stroke-width="1.1"/><path d="M{x - r * 0.5:.1f},{y - r * 0.2:.1f} a{r * 0.55:.1f},{r * 0.55:.1f} 0 0,1 {r * 0.6:.1f},{-r * 0.45:.1f}" stroke="#FFFFFF" stroke-width="1" fill="none" opacity="0.55"/>')
    for (x, y) in semis(mont, 70, 52, 40):
        o.append(f'<path d="M{x - 22:.1f},{y + 10:.1f} L{x:.1f},{y - 20:.1f} L{x + 24:.1f},{y + 10:.1f}" fill="{C["mont"]}" stroke="{ink}" stroke-width="1.6" stroke-linejoin="round"/><path d="M{x:.1f},{y - 20:.1f} L{x + 24:.1f},{y + 10:.1f} L{x + 4:.1f},{y + 10:.1f} Z" fill="url(#hach)"/><path d="M{x - 7:.1f},{y - 10:.1f} L{x:.1f},{y - 20:.1f} L{x + 8:.1f},{y - 9:.1f} L{x + 2:.1f},{y - 12:.1f} Z" fill="#FFFFFF" stroke="{ink}" stroke-width="1"/>')
    o += dessiner_acteurs('atlas')
    # cartouche d'échelle et rose des vents
    o.append(f'<g transform="translate(1480,800)"><circle r="34" fill="#FFFFFF" fill-opacity="0.85" stroke="{ink}" stroke-width="2"/><path d="M0,-30 L7,0 L0,30 L-7,0 Z" fill="{ink}"/><path d="M0,-30 L7,0 L-7,0 Z" fill="{C["sel"]}" stroke="{ink}" stroke-width="1"/><text y="-38" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="14" fill="{ink}">N</text></g>')
    return o

def arbre_dessine(x, y, r, teinte, seed):
    """Houppier dessiné : lobes encrés, ombre propre, reflets, tronc."""
    ink = C['ink']; rr = np.random.default_rng(seed); o = []
    o.append(f'<ellipse cx="{x + r * 0.5:.1f}" cy="{y + r * 0.55:.1f}" rx="{r * 1.05:.1f}" ry="{r * 0.45:.1f}" fill="{ink}" opacity="0.22"/>')
    o.append(f'<path d="M{x - 1.6:.1f},{y + r * 0.6:.1f} l0,{-r * 0.5:.1f} l3.2,0 l0,{r * 0.5:.1f} Z" fill="#6B4423" stroke="{ink}" stroke-width="1"/>')
    n = 8; pts = []
    for i in range(n):
        a = i / n * math.tau; k = 0.82 + rr.uniform(0, 0.3)
        pts.append((x + math.cos(a) * r * k, y - r * 0.35 + math.sin(a) * r * 0.85 * k))
    d = f'M{pts[0][0]:.1f},{pts[0][1]:.1f}'
    for i in range(n):
        p, q = pts[i], pts[(i + 1) % n]
        mx, my = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2
        cx, cy = mx + (mx - x) * 0.35, my + (my - (y - r * 0.35)) * 0.35
        d += f' Q{cx:.1f},{cy:.1f} {q[0]:.1f},{q[1]:.1f}'
    base, sombre, clair = teinte
    o.append(f'<path d="{d}Z" fill="{base}" stroke="{ink}" stroke-width="1.5" stroke-linejoin="round"/>')
    o.append(f'<path d="M{x - r * 0.1:.1f},{y + r * 0.35:.1f} Q{x + r * 0.9:.1f},{y + r * 0.25:.1f} {x + r * 0.85:.1f},{y - r * 0.5:.1f} Q{x + r * 0.55:.1f},{y:.1f} {x - r * 0.1:.1f},{y + r * 0.35:.1f}Z" fill="{sombre}" opacity="0.9"/>')
    for k in range(3):
        a = rr.uniform(3.4, 4.6); rx = x + math.cos(a) * r * 0.45; ry = y - r * 0.35 + math.sin(a) * r * 0.4
        o.append(f'<path d="M{rx - 3:.1f},{ry + 1:.1f} q3,-3.5 6,0" stroke="{clair}" stroke-width="1.6" fill="none" stroke-linecap="round"/>')
    for k in range(2):
        a = rr.uniform(0, math.tau); rx = x + math.cos(a) * r * 0.4; ry = y - r * 0.3 + math.sin(a) * r * 0.35
        o.append(f'<path d="M{rx - 2:.1f},{ry:.1f} q2,2 4,0" stroke="{ink}" stroke-width="0.9" fill="none" opacity="0.6"/>')
    return ''.join(o)

def sapin_dessine(x, y, h, seed):
    ink = C['ink']; o = []
    o.append(f'<ellipse cx="{x + h * 0.2:.1f}" cy="{y:.1f}" rx="{h * 0.35:.1f}" ry="{h * 0.12:.1f}" fill="{ink}" opacity="0.22"/>')
    w = h * 0.36
    for i in range(3):
        top = y - h + i * h * 0.24; bas = y - h * 0.18 - (2 - i) * h * 0.13
        ww = w * (0.55 + i * 0.25)
        o.append(f'<path d="M{x:.1f},{top:.1f} L{x + ww:.1f},{bas:.1f} Q{x:.1f},{bas + 4:.1f} {x - ww:.1f},{bas:.1f} Z" fill="#3F7F3A" stroke="{ink}" stroke-width="1.4" stroke-linejoin="round"/>')
        o.append(f'<path d="M{x:.1f},{top:.1f} L{x + ww:.1f},{bas:.1f} Q{x + ww * 0.4:.1f},{bas + 2:.1f} {x:.1f},{bas + 1:.1f} Z" fill="#2E6430"/>')
    o.append(f'<rect x="{x - 1.6:.1f}" y="{y - h * 0.2:.1f}" width="3.2" height="{h * 0.2:.1f}" fill="#6B4423" stroke="{ink}" stroke-width="1"/>')
    return ''.join(o)

def montagne_dessinee(x, y, w, seed, hach='hach'):
    ink = C['ink']; rr = np.random.default_rng(seed); h = w * rr.uniform(0.62, 0.9); o = []
    px = x + rr.uniform(-0.15, 0.15) * w
    n = 6
    gauche = [(x - w / 2 + (px - x + w / 2) * t + rr.uniform(-3, 3), y - h * t + rr.uniform(-4, 4) * (0 < t < 1)) for t in np.linspace(0, 1, n)]
    droite = [(px + (x + w / 2 - px) * t + rr.uniform(-3, 3), y - h * (1 - t) + rr.uniform(-4, 4) * (0 < t < 1)) for t in np.linspace(0, 1, n)][1:]
    sil = gauche + droite
    d = 'M' + ' L'.join(f'{a:.1f},{b:.1f}' for a, b in sil) + 'Z'
    o.append(f'<path d="{d}" fill="#CFC7BA" stroke="{ink}" stroke-width="2" stroke-linejoin="round"/>')
    # arête principale : du sommet vers le pied, la face droite est à l'ombre
    ar = [(px, y - h)]
    for t in np.linspace(0.2, 1, 4):
        ar.append((px + w * 0.12 * t + rr.uniform(-4, 4), y - h + h * t))
    ombre = ar + [(x + w / 2, y)] + droite[::-1][1:]
    do = 'M' + ' L'.join(f'{a:.1f},{b:.1f}' for a, b in ombre) + 'Z'
    o.append(f'<path d="{do}" fill="#9A9083"/><path d="{do}" fill="url(#{hach})"/>')
    o.append('<path d="M' + ' L'.join(f'{a:.1f},{b:.1f}' for a, b in ar) + f'" fill="none" stroke="{ink}" stroke-width="1.4" stroke-linejoin="round"/>')
    # strates sur la face éclairée
    for k in range(4):
        t = rr.uniform(0.3, 0.85); xa = px - (px - (x - w / 2)) * t * rr.uniform(0.3, 0.8); ya = y - h * (1 - t)
        o.append(f'<path d="M{xa:.1f},{ya:.1f} l{w * 0.09:.1f},{-h * 0.04:.1f} l{w * 0.05:.1f},{h * 0.03:.1f}" stroke="{ink}" stroke-width="1" fill="none" opacity="0.55"/>')
    # neige découpée
    sn = rr.uniform(0.26, 0.36)
    pts = [(px, y - h)]
    for t in np.linspace(0, 1, 7):
        xx_ = px - w * 0.5 * sn + w * sn * t
        yy_ = y - h + h * sn * (1 - abs(t - 0.5) * 0.6) + (6 if k % 2 else -2) * 0
        pts.append((xx_, y - h + h * sn * rr.uniform(0.55, 1.05)))
    pts = [(px, y - h)] + sorted(pts[1:], key=lambda p: p[0])
    neige = [(px - (px - gauche[-2][0]) * 0.0, y - h)]
    ds = 'M' + ' L'.join(f'{a:.1f},{b:.1f}' for a, b in [pts[1]] + [(px, y - h)] + [pts[-1]] + pts[-2:0:-1]) + 'Z'
    o.append(f'<path d="{ds}" fill="#FFFFFF" stroke="{ink}" stroke-width="1.3" stroke-linejoin="round"/>')
    return ''.join(o)

def rocher_dessine(x, y, r, seed, hach='hach'):
    ink = C['ink']; rr = np.random.default_rng(seed); o = []
    n = 9; pts = []
    for i in range(n):
        a = math.pi + i / (n - 1) * math.pi
        k = rr.uniform(0.78, 1.08)
        pts.append((x + math.cos(a) * r * k, y + min(0, math.sin(a)) * r * 0.85 * k))
    pts.append((x + r * 0.8, y + r * 0.12)); pts.append((x - r * 0.8, y + r * 0.12))
    d = 'M' + ' L'.join(f'{a:.1f},{b:.1f}' for a, b in pts) + 'Z'
    o.append(f'<ellipse cx="{x + r * 0.35:.1f}" cy="{y + r * 0.15:.1f}" rx="{r * 1.15:.1f}" ry="{r * 0.32:.1f}" fill="{ink}" opacity="0.24"/>')
    o.append(f'<path d="{d}" fill="#CFCBC0" stroke="{ink}" stroke-width="1.5" stroke-linejoin="round"/>')
    sx = x + r * rr.uniform(-0.1, 0.25)
    o.append(f'<path d="M{sx:.1f},{y - r * 0.8:.1f} L{x + r * 0.95:.1f},{y - r * 0.1:.1f} L{x + r * 0.8:.1f},{y + r * 0.12:.1f} L{sx - r * 0.15:.1f},{y + r * 0.12:.1f} L{sx + r * 0.05:.1f},{y - r * 0.35:.1f} Z" fill="#A29E93"/>')
    if r > 7:
        o.append(f'<path d="M{sx:.1f},{y - r * 0.8:.1f} L{x + r * 0.95:.1f},{y - r * 0.1:.1f} L{x + r * 0.8:.1f},{y + r * 0.12:.1f} L{sx - r * 0.15:.1f},{y + r * 0.12:.1f} L{sx + r * 0.05:.1f},{y - r * 0.35:.1f} Z" fill="url(#{hach})"/>')
    o.append(f'<path d="M{sx:.1f},{y - r * 0.8:.1f} L{sx + r * 0.05:.1f},{y - r * 0.35:.1f} L{sx - r * 0.15:.1f},{y + r * 0.12:.1f}" stroke="{ink}" stroke-width="1" fill="none"/>')
    o.append(f'<path d="M{x - r * 0.55:.1f},{y - r * 0.45:.1f} l{r * 0.25:.1f},{r * 0.12:.1f} l{r * 0.05:.1f},{r * 0.25:.1f}" stroke="{ink}" stroke-width="0.9" fill="none" opacity="0.7"/>')
    o.append(f'<path d="M{x - r * 0.6:.1f},{y - r * 0.15:.1f} q{r * 0.3:.1f},{-r * 0.5:.1f} {r * 0.75:.1f},{-r * 0.62:.1f}" stroke="#FFFFFF" stroke-width="1.2" fill="none" opacity="0.7"/>')
    return ''.join(o)

def v_illustre():
    """4 · Ligne claire illustrée : tout est dessiné (houppiers, sapins, rochers, montagnes, fleurs, roseaux)."""
    ink = C['ink']; lw = 2.8; o = fond_terrain(lw)
    prairie = ~eau & ~foret & ~mont & ~roche & ~sable & libre
    o += tufts(prairie, 19, 60, 0.45, 1.1)
    for (x, y) in semis(prairie, 34, 61, 500):
        col = ['#FFFFFF', '#FFD84A', '#F59AB8', '#B9A2F2'][int(x * 3 + y) % 4]
        for (dx, dy) in [(0, 0), (4, 2), (-3, 3)][: 1 + int(x) % 3]:
            o.append(f'<circle cx="{x + dx:.1f}" cy="{y + dy:.1f}" r="1.9" fill="{col}" stroke="{ink}" stroke-width="0.7"/>')
    o.append(f'<path d="{contours(sable)}" fill="url(#points)" fill-rule="evenodd"/>')
    for (x, y) in semis(sable, 30, 62, 300):
        o.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="2.4" ry="1.6" fill="#D2C3A6" stroke="{ink}" stroke-width="0.7"/>')
    o.append(f'<path d="{contours(foret)}" fill="url(#hachL)" fill-rule="evenodd"/>')
    o += dessiner_eau(lw, 'illustre')
    # roseaux et pierres de berge
    berge = nd.binary_dilation(eau, iterations=3) & ~eau & libre
    for (x, y) in semis(berge, 18, 63, 400):
        if int(x + y) % 2:
            o.append(f'<path d="M{x:.1f},{y:.1f} q-2,-6 -1,-11 M{x + 2:.1f},{y:.1f} q1,-7 3,-10 M{x - 2:.1f},{y:.1f} q-3,-4 -5,-7" stroke="#3E6A2C" stroke-width="1.4" fill="none" stroke-linecap="round"/><ellipse cx="{x - 0.5:.1f}" cy="{y - 11:.1f}" rx="1.3" ry="3" fill="#7A4E26" stroke="{ink}" stroke-width="0.6"/>')
        else:
            o.append(rocher_dessine(x, y, 4.5, int(x * y)))
    o += elements_communs('illustre')
    objets = []
    for (x, y) in semis(foret, 17, 64, 1500, 6):
        if int(x * 3 + y * 5) % 5 == 0:
            objets.append((y, sapin_dessine(x, y, 30 + int(x) % 10, int(x))))
        else:
            teinte = [('#5E9A48', '#477E36', '#9ED07A'), ('#6CAA4E', '#4E8A3A', '#B4DE84'), ('#4F8F43', '#3A7232', '#8CC46C')][int(x + y) % 3]
            objets.append((y, arbre_dessine(x, y, 11 + int(x * 7) % 5, teinte, int(x * 31 + y))))
    for (x, y) in semis(roche, 26, 65, 200):
        objets.append((y, rocher_dessine(x, y, 9 + int(x) % 6, int(x * y))))
    for (x, y) in semis(mont, 46, 66, 60):
        objets.append((y + 14, montagne_dessinee(x, y + 14, 70 + int(x * 7) % 60, int(x * 13 + y))))
    for (x, y) in [(1345, 334)]:
        objets.append((y, rocher_dessine(x, y, 13, 5) + f'<path d="M{x - 4},{y - 6} l3,-2 l2,3 M{x + 3},{y - 4} l2,-2" stroke="#FFE04A" stroke-width="2.4" stroke-linecap="round"/>'))
    for y, s in sorted(objets, key=lambda t: t[0]):
        o.append(s)
    o += dessiner_acteurs('illustre')
    return o

def v_tuiles():
    """5 · Tuiles dessinées : la grille du jeu (cases de 25 px) assumée, motifs par case et bords encrés."""
    ink = C['ink']; T = 25; nx, ny = W // T + 1, H // T + 1
    def type_case(i, j):
        x, y = i * T + T / 2, j * T + T / 2
        for m, t in [(eau, 'eau'), (mont, 'mont'), (roche, 'roche'), (foret, 'foret'), (sable, 'sable')]:
            if m_at(m, x, y): return t
        return 'prairie'
    grille = [[type_case(i, j) for i in range(nx)] for j in range(ny)]
    col = {'prairie': C['grass'], 'eau': C['eau'], 'mont': C['mont'], 'roche': C['roche'], 'foret': C['foret'], 'sable': C['sable']}
    o = []
    for j in range(ny):
        for i in range(nx):
            t = grille[j][i]; x, y = i * T, j * T
            c = col[t]
            if t == 'prairie' and (i * 7 + j * 13) % 5 == 0: c = C['grass3']
            if t == 'eau':
                bord = any(grille[jj][ii] != 'eau' for ii, jj in [(i - 1, j), (i + 1, j), (i, j - 1), (i, j + 1)] if 0 <= ii < nx and 0 <= jj < ny)
                c = C['eau'] if bord else C['eau2']
            o.append(f'<rect x="{x}" y="{y}" width="{T}" height="{T}" fill="{c}"/>')
            if t == 'prairie' and (i + 2 * j) % 3 == 0:
                o.append(f'<path d="M{x + 9},{y + 17} l1.5,-5 M{x + 12},{y + 17} l0,-6.5 M{x + 15},{y + 17} l-1.5,-5" stroke="{ink}" stroke-width="1" opacity="0.4" fill="none"/>')
            elif t == 'sable':
                o.append(f'<circle cx="{x + 7}" cy="{y + 8}" r="0.9" fill="{ink}" opacity="0.4"/><circle cx="{x + 17}" cy="{y + 16}" r="0.9" fill="{ink}" opacity="0.4"/><circle cx="{x + 12}" cy="{y + 20}" r="0.7" fill="{ink}" opacity="0.3"/>')
            elif t == 'eau':
                o.append(f'<path d="M{x + 5},{y + 13} q4,-3 8,0 M{x + 12},{y + 19} q3,-2 6,0" stroke="#FFFFFF" stroke-width="1.1" fill="none" opacity="0.55"/>')
            elif t == 'roche':
                o.append(f'<path d="M{x + 4},{y + 18} l5,-4 l4,3 l6,-6" stroke="{ink}" stroke-width="1" fill="none" opacity="0.55"/><path d="M{x + 6},{y + 9} l4,-2" stroke="#FFFFFF" stroke-width="1.4" opacity="0.6"/>')
            elif t == 'mont':
                o.append(f'<path d="M{x},{y + T} L{x + T / 2},{y + 3} L{x + T},{y + T}" fill="none" stroke="{ink}" stroke-width="1" opacity="0.35"/><path d="M{x + T / 2},{y + 3} L{x + T},{y + T} L{x + T / 2 + 3},{y + T} Z" fill="url(#hach)"/>')
    # bords encrés entre terrains différents (sur les arêtes de la grille)
    for j in range(ny):
        for i in range(nx):
            t = grille[j][i]; x, y = i * T, j * T
            if i + 1 < nx and grille[j][i + 1] != t:
                o.append(f'<line x1="{x + T}" y1="{y}" x2="{x + T}" y2="{y + T}" stroke="{ink}" stroke-width="2.2" stroke-linecap="round"/>')
            if j + 1 < ny and grille[j + 1][i] != t:
                o.append(f'<line x1="{x}" y1="{y + T}" x2="{x + T}" y2="{y + T}" stroke="{ink}" stroke-width="2.2" stroke-linecap="round"/>')
    o.append(f'<path d="' + ' '.join(f'M{i * T},0 V{H}' for i in range(nx)) + ' ' + ' '.join(f'M0,{j * T} H{W}' for j in range(ny)) + f'" stroke="{ink}" stroke-width="0.6" opacity="0.08"/>')
    o += elements_communs('tuiles')
    arbres = []
    for j in range(ny):
        for i in range(nx):
            t = grille[j][i]
            if t == 'foret':
                arbres.append((j * T + T - 3, i * T + T / 2 + ((i * 7 + j) % 5 - 2)))
            elif t == 'roche' and (i + j) % 3 == 0:
                arbres.append((j * T + T - 4, i * T + T / 2, 'rocher'))
            elif t == 'mont' and (i % 4 == 0) and (j % 3 == 0):
                arbres.append((j * T + T, i * T + T / 2, 'montagnes'))
    o += planter(arbres, 'plein', (36, 46))
    o += dessiner_acteurs('tuiles')
    return o

VARIANTES = [('1_trait_fin', v_trait), ('2_gravure', v_gravure), ('3_atlas', v_atlas), ('4_illustre', v_illustre), ('5_tuiles', v_tuiles)]

if __name__ == '__main__':
    os.makedirs(os.path.join(ICI, 'svg'), exist_ok=True)
    for nom, f in VARIANTES:
        corps = f()
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{defs()}' + ''.join(corps) + '</svg>'
        open(os.path.join(ICI, 'svg', nom + '.svg'), 'w').write(svg)
        print(nom, len(svg) // 1024, 'Ko')
