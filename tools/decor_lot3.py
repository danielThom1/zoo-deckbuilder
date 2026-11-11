"""Usage : python tools/decor_lot3.py game
Nouveaux éléments de décor dans le style BD du jeu : aplats, ombre hachurée, trait d'encre épais.
Dessin à 4x puis réduction. Écrit les PNG dans assets/bd/decor et complète decor_bd.json."""
import json, math, random, sys
from PIL import Image, ImageDraw, ImageFilter

DEST = sys.argv[1]  # dossier game/
S = 4
ENCRE = (0x14, 0x20, 0x2B, 255)
TRAIT = 3.6  # épaisseur du trait final (px)


def toile(w, h):
    return Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))


def P(pts):
    return [(x * S, y * S) for x, y in pts]


def forme(im, pts, fond, trait=TRAIT, encre=ENCRE):
    d = ImageDraw.Draw(im)
    d.polygon(P(pts), fill=fond)
    if trait:
        d.line(P(pts + [pts[0]]), fill=encre, width=int(trait * S), joint="curve")
        for x, y in pts:
            r = trait * S / 2
            d.ellipse((x * S - r, y * S - r, x * S + r, y * S + r), fill=encre)


def ligne(im, pts, w=1.6, col=ENCRE):
    d = ImageDraw.Draw(im)
    d.line(P(pts), fill=col, width=max(1, int(w * S)), joint="curve")


def ellipse(im, box, fond, trait=TRAIT, encre=ENCRE):
    d = ImageDraw.Draw(im)
    b = [v * S for v in box]
    d.ellipse(b, fill=fond, outline=encre if trait else None, width=int(trait * S) if trait else 0)


def hachures(im, pts, fond, col, pas=5.0, angle=55, w=1.3):
    """Remplit pts de fond puis y trace des hachures (côté à l'ombre)."""
    masque = Image.new("L", im.size, 0)
    ImageDraw.Draw(masque).polygon(P(pts), fill=255)
    calque = Image.new("RGBA", im.size, fond)
    d = ImageDraw.Draw(calque)
    a = math.radians(angle)
    L = max(im.size) * 2
    for k in range(-int(L / (pas * S)), int(L / (pas * S))):
        o = k * pas * S
        x0, y0 = o, 0
        d.line([(x0 - math.cos(a) * L, y0 - math.sin(a) * L), (x0 + math.cos(a) * L, y0 + math.sin(a) * L)], fill=col, width=int(w * S))
    im.paste(calque, (0, 0), masque)


def finir(im, nom, groupe, pied):
    w, h = im.size[0] // S, im.size[1] // S
    out = im.resize((w, h), Image.LANCZOS)
    out.save(f"{DEST}/assets/bd/decor/{nom}.png")
    return nom, {"fichier": f"res://assets/bd/decor/{nom}.png", "groupe": groupe, "pied": list(pied), "taille": [w, h]}


PIERRE, PIERRE_OMBRE, PIERRE_TRAIT = (0xCF, 0xC7, 0xBA, 255), (0x9A, 0x90, 0x83, 255), (0x7A, 0x72, 0x66, 255)
NEIGE = (255, 255, 255, 255)
GRANIT, GRANIT_OMBRE = (0xD6, 0xCE, 0xC0, 255), (0xA3, 0x99, 0x8B, 255)
OCRE, OCRE_OMBRE, OCRE_TRAIT = (0xC9, 0xC0, 0xB0, 255), (0x98, 0x8E, 0x80, 255), (0x76, 0x6E, 0x62, 255)
HERBE = (0x6A, 0xA4, 0x66, 255)
BOIS, BOIS_CLAIR, BOIS_COEUR = (0x7A, 0x5A, 0x3A, 255), (0xA0, 0x78, 0x48, 255), (0xD9, 0xB7, 0x84, 255)
TERRE, TERRE_OMBRE = (0x8A, 0x66, 0x44, 255), (0x6B, 0x4E, 0x33, 255)
ECUME = (0xF4, 0xFB, 0xFF, 255)

sortie = {}


def ajoute(t):
    sortie[t[0]] = t[1]


# ---------------------------------------------------------------- aiguilles (pics fins, en grappe)
def aiguille(n, seed):
    r = random.Random(seed)
    W, H = 110, 160
    im = toile(W, H)
    flèches = [(55 + r.uniform(-4, 4), 8 + r.uniform(0, 8), 26)]
    flèches.append((28 + r.uniform(-4, 4), 48 + r.uniform(0, 12), 19))
    if n != 2:
        flèches.append((82 + r.uniform(-4, 4), 58 + r.uniform(0, 12), 18))
    flèches.sort(key=lambda f: f[1])
    for cx, top, demi in flèches:
        base = H - 4
        g, dr = (cx - demi, base), (cx + demi, base)
        s = (cx + r.uniform(-2, 2), top)
        m1 = (cx - demi * 0.55 + r.uniform(-2, 2), top + (base - top) * 0.45)
        m2 = (cx + demi * 0.5 + r.uniform(-2, 2), top + (base - top) * 0.55)
        contour = [s, m2, dr, g, m1]
        forme(im, contour, PIERRE)
        arete = (cx + r.uniform(-1, 3), base)
        hachures(im, [s, m2, dr, arete], PIERRE_OMBRE, PIERRE_TRAIT, pas=4.2)
        forme(im, contour, None) if False else None
        ImageDraw.Draw(im).line(P(contour + [contour[0]]), fill=ENCRE, width=int(TRAIT * S), joint="curve")
        ligne(im, [s, arete], 1.4)
        # neige
        k = 0.16
        ns = [s, (s[0] + (m2[0] - s[0]) * k * 1.6, s[1] + (m2[1] - s[1]) * k * 1.6), (s[0] + 1, s[1] + (base - top) * 0.12), (s[0] + (m1[0] - s[0]) * k * 1.5, s[1] + (m1[1] - s[1]) * k * 1.5)]
        forme(im, ns, NEIGE, trait=2.2)
        for j in range(2):
            y = top + (base - top) * (0.45 + 0.18 * j)
            ligne(im, [(cx - demi * 0.35, y), (cx - demi * 0.1, y + 2)], 1.2, PIERRE_TRAIT)
    return finir(im, f"aiguille_{n}", "montagne", (W // 2, H - 4))


# ---------------------------------------------------------------- dômes (granite arrondi)
def dome(n, seed):
    r = random.Random(seed)
    W, H = 150, 100
    im = toile(W, H)
    base = H - 5
    pts = []
    larg = 66 + r.uniform(-6, 6)
    haut = 70 + r.uniform(-8, 6)
    for i in range(41):
        t = math.pi * i / 40
        x = W / 2 - math.cos(t) * larg
        y = base - math.sin(t) ** 0.8 * haut * (1 + 0.06 * math.sin(3 * t + seed))
        pts.append((x, y))
    forme(im, pts, GRANIT)
    # ombre : croissant à droite
    ombre = [(W / 2 + 6, base)] + [(x, y) for x, y in pts if x > W / 2 + 6] + [(W / 2 + larg, base)]
    ombre = [p for p in pts if p[0] >= W / 2 + 4]
    ombre = ombre + [(W / 2 + larg * 0.35, base), (W / 2 + larg * 0.18, base - haut * 0.6)]
    hachures(im, ombre, GRANIT_OMBRE, PIERRE_TRAIT, pas=4.6, angle=60)
    ImageDraw.Draw(im).line(P(pts), fill=ENCRE, width=int(TRAIT * S), joint="curve")
    ligne(im, [(pts[0][0], base), (pts[-1][0], base)], TRAIT)
    # fissures d'exfoliation (courbes parallèles au contour)
    for k in (0.55, 0.78):
        arc = [(W / 2 - math.cos(t) * larg * k, base - math.sin(t) ** 0.8 * haut * k - haut * (1 - k) * 0.5) for t in [math.pi * (0.2 + 0.5 * i / 10) for i in range(11)]]
        ligne(im, arc, 1.3, PIERRE_TRAIT)
    # touffe sur le sommet
    if n != 3:
        tx = W / 2 - 10 + r.uniform(-8, 8)
        ty = base - haut * 0.97
        forme(im, [(tx - 8, ty + 4), (tx - 4, ty - 3), (tx, ty + 1), (tx + 4, ty - 4), (tx + 8, ty + 4)], HERBE, trait=2.2)
    return finir(im, f"dome_{n}", "montagne", (W // 2, base))


# ---------------------------------------------------------------- tables (sommet plat, strates)
def table(n, seed):
    r = random.Random(seed)
    W, H = 170, 100
    im = toile(W, H)
    base = H - 5
    top = 26 + r.uniform(-4, 6)
    gx, dx = 14, W - 14
    pts = [(gx, base), (gx + 10, top + 14), (gx + 24, top), (dx - 26, top + r.uniform(-2, 2)), (dx - 10, top + 16), (dx, base)]
    forme(im, pts, OCRE)
    # face avant ombrée à droite
    hachures(im, [(W * 0.62, top + 12), (dx - 10, top + 16), (dx, base), (W * 0.6, base)], OCRE_OMBRE, OCRE_TRAIT, pas=4.4)
    # plateau sommital
    plat = [(gx + 24, top), (dx - 26, top), (dx - 18, top + 9), (gx + 18, top + 10)]
    forme(im, plat, (0xDD, 0xD6, 0xC8, 255), trait=0)
    forme(im, [(gx + 30, top + 2), (gx + 60, top + 1), (gx + 56, top + 6), (gx + 32, top + 7)], HERBE, trait=0)
    ImageDraw.Draw(im).line(P(pts + [pts[0]]), fill=ENCRE, width=int(TRAIT * S), joint="curve")
    ligne(im, [plat[3], plat[2]], 1.6)
    # strates
    for k, y in enumerate([top + 24, top + 40, top + 54]):
        if y < base - 4:
            ligne(im, [(gx + 9 - k, y), (W * 0.45, y + r.uniform(-2, 2)), (dx - 6 + k, y + 1)], 1.3, OCRE_TRAIT)
    for x in (W * 0.3, W * 0.5, W * 0.72):
        ligne(im, [(x, top + 26), (x + 1, top + 38)], 1.1, OCRE_TRAIT)
    return finir(im, f"table_{n}", "montagne", (W // 2, base))


# ---------------------------------------------------------------- grotte (ouverture sur une falaise)
def grotte(n, seed):
    r = random.Random(seed)
    W, H = 52, 44
    im = toile(W, H)
    base = H - 3
    arc = [(W / 2 - math.cos(math.pi * i / 16) * 18, base - math.sin(math.pi * i / 16) * (24 + 3 * n)) for i in range(17)]
    forme(im, arc, (0x2A, 0x2A, 0x2E, 255), trait=TRAIT)
    forme(im, [(W / 2 - 12, base), (W / 2 - 6, base - 8), (W / 2 + 4, base - 6), (W / 2 + 13, base)], (0x45, 0x44, 0x46, 255), trait=0)
    # pierres de l'encadrement
    for (x, y, rr) in [(W / 2 - 19, base - 4, 6), (W / 2 + 18, base - 3, 7), (W / 2 + 13, base - 20, 5)]:
        ellipse(im, (x - rr, y - rr * 0.75, x + rr, y + rr * 0.75), PIERRE, trait=2.4)
    return finir(im, f"grotte_{n}", "montagne", (W // 2, base))


# ---------------------------------------------------------------- rocher émergé avec écume
def rocher_eau(n, seed):
    r = random.Random(seed)
    W, H = 58, 40
    im = toile(W, H)
    base = H - 9
    ellipse(im, (5, base - 7, W - 5, base + 7), ECUME, trait=0)
    ellipse(im, (10, base - 4, W - 10, base + 4), (0xBF, 0xE4, 0xF2, 255), trait=0)
    larg = 15 + 3 * n
    pts = [(W / 2 - larg, base), (W / 2 - larg + 5, base - 13), (W / 2 - 3, base - 20 - n * 2), (W / 2 + larg - 6, base - 12), (W / 2 + larg, base)]
    forme(im, pts, PIERRE)
    hachures(im, [pts[2], pts[3], pts[4], (W / 2 + 2, base)], PIERRE_OMBRE, PIERRE_TRAIT, pas=4)
    ImageDraw.Draw(im).line(P(pts), fill=ENCRE, width=int(TRAIT * S), joint="curve")
    # mouillé : bande sombre à la ligne d'eau
    ligne(im, [(W / 2 - larg + 2, base - 1.5), (W / 2 + larg - 2, base - 1.5)], 1.6, (0x6D, 0x80, 0x88, 255))
    return finir(im, f"rocher_eau_{n}", "berge", (W // 2, base))


# ---------------------------------------------------------------- galets
def galets(n, seed):
    r = random.Random(seed)
    W, H = 46, 26
    im = toile(W, H)
    items = []
    for i in range(4 + n):
        items.append((r.uniform(8, W - 8), r.uniform(9, H - 6), r.uniform(4, 7.5)))
    items.sort(key=lambda t: t[1])
    teintes = [(0xE0, 0xD9, 0xCA, 255), (0xCB, 0xC2, 0xB2, 255), (0xEB, 0xE4, 0xD6, 255), (0xBF, 0xB5, 0xA4, 255)]
    for x, y, rr in items:
        ellipse(im, (x - rr, y - rr * 0.7, x + rr, y + rr * 0.7), r.choice(teintes), trait=1.5)
    return finir(im, f"galets_{n}", "objet", (W // 2, H - 6))


# ---------------------------------------------------------------- traces d'animaux (au sol, sans encre)
def traces(n, seed):
    r = random.Random(seed)
    W, H = 60, 40
    im = toile(W, H)
    d = ImageDraw.Draw(im)
    col = (0x8A, 0x6C, 0x46, 235)
    x, y = 6, H - 8
    ang = -0.45 + n * 0.25
    for i in range(7):
        x += math.cos(ang) * 7.5
        y += math.sin(ang) * 7.5
        ang += r.uniform(-0.18, 0.18)
        cote = 1 if i % 2 else -1
        px, py = x - math.sin(ang) * 2.4 * cote, y + math.cos(ang) * 2.4 * cote
        for ox, oy, rr in [(0, 0, 1.5), (-1.3, -1.8, 0.7), (0.2, -2.3, 0.7), (1.5, -1.6, 0.7)] if n == 1 else [(0, 0, 1.2), (1.1, -1.4, 1.0)]:
            cx, cy = (px + ox) * S, (py + oy) * S
            d.ellipse((cx - rr * S, cy - rr * S, cx + rr * S, cy + rr * S), fill=col)
    return finir(im, f"traces_{n}", "sol", (W // 2, H // 2))


# ---------------------------------------------------------------- taupinière, fourmilière
def taupiniere(n, seed):
    r = random.Random(seed)
    W, H = 30, 18
    im = toile(W, H)
    base = H - 4
    pts = [(4, base)] + [(W / 2 - math.cos(math.pi * i / 10) * 11, base - math.sin(math.pi * i / 10) * (8 + n)) for i in range(11)] + [(W - 4, base)]
    forme(im, pts, TERRE, trait=2.4)
    hachures(im, [(W / 2 + 2, base - 8), (W / 2 + 11, base), (W / 2 + 2, base)], TERRE_OMBRE, (0x55, 0x3D, 0x28, 255), pas=3)
    ImageDraw.Draw(im).line(P(pts), fill=ENCRE, width=int(2.4 * S), joint="curve")
    for i in range(4):
        x, y = r.uniform(9, W - 9), r.uniform(base - 6, base - 2)
        ellipse(im, (x - 0.8, y - 0.6, x + 0.8, y + 0.6), (0xA8, 0x86, 0x60, 255), trait=0)
    return finir(im, f"taupiniere_{n}", "objet", (W // 2, base))


def fourmiliere(n, seed):
    r = random.Random(seed)
    W, H = 34, 26
    im = toile(W, H)
    base = H - 4
    pts = [(3, base), (W / 2 - 4, 6), (W / 2 + 4, 6), (W - 3, base)]
    forme(im, pts, (0xA6, 0x7E, 0x4E, 255), trait=2.4)
    hachures(im, [(W / 2 + 2, 7), (W - 4, base), (W / 2 + 3, base)], (0x86, 0x62, 0x3C, 255), (0x6B, 0x4C, 0x2E, 255), pas=3)
    ImageDraw.Draw(im).line(P(pts + [pts[0]]), fill=ENCRE, width=int(2.4 * S), joint="curve")
    d = ImageDraw.Draw(im)
    for i in range(14):
        x, y = r.uniform(8, W - 8), r.uniform(10, base - 2)
        if abs(x - W / 2) < (y - 6) * 0.55:
            d.line([(x * S, y * S), ((x + r.uniform(-1.5, 1.5)) * S, (y + 1.2) * S)], fill=(0x5A, 0x40, 0x26, 255), width=S)
    return finir(im, f"fourmiliere_{n}", "objet", (W // 2, base))


# ---------------------------------------------------------------- tronc couché, champignons
def tronc(n, seed):
    r = random.Random(seed)
    W, H = 84, 30
    im = toile(W, H)
    y0, y1 = 8, 22
    x0, x1 = 8, W - 16
    corps = [(x0, y0), (x1, y0 + 1), (x1, y1 + 1), (x0, y1)]
    forme(im, corps, BOIS)
    hachures(im, [(x0, y1 - 4), (x1, y1 - 3), (x1, y1 + 1), (x0, y1)], (0x5E, 0x44, 0x2B, 255), (0x4A, 0x35, 0x22, 255), pas=3.5, angle=90)
    ImageDraw.Draw(im).line(P(corps + [corps[0]]), fill=ENCRE, width=int(TRAIT * S), joint="curve")
    for k in range(4):
        x = x0 + 8 + k * 14 + r.uniform(-2, 2)
        ligne(im, [(x, y0 + 3), (x + 9, y0 + 4)], 1.2, (0x55, 0x3D, 0x28, 255))
    ellipse(im, (x1 - 6, y0 + 0.5, x1 + 6, y1 + 1.5), BOIS_COEUR)
    ellipse(im, (x1 - 2.5, y0 + 6, x1 + 2.5, y1 - 4), (0xBE, 0x96, 0x62, 255), trait=1.2)
    # branche cassée et mousse
    forme(im, [(x0 + 22, y0 + 1), (x0 + 26, y0 - 6), (x0 + 30, y0 - 5), (x0 + 28, y0 + 1)], BOIS, trait=2.2)
    if n == 1:
        forme(im, [(x0 + 4, y0 + 1), (x0 + 16, y0 - 1), (x0 + 18, y0 + 3), (x0 + 6, y0 + 4)], HERBE, trait=0)
    return finir(im, f"tronc_couche_{n}", "objet", (W // 2 - 4, y1))


def champignons(n, seed):
    r = random.Random(seed)
    W, H = 30, 24
    im = toile(W, H)
    rouge = n == 1
    chap = (0xD9, 0x3F, 0x35, 255) if rouge else (0xB0, 0x7A, 0x48, 255)
    pieds = [(10, H - 4, 1.0), (19, H - 3, 0.8), (24, H - 5, 0.6)] if n != 3 else [(12, H - 4, 1.0), (20, H - 4, 0.9)]
    for x, y, k in pieds:
        forme(im, [(x - 2 * k, y), (x - 1.6 * k, y - 8 * k), (x + 1.6 * k, y - 8 * k), (x + 2 * k, y)], (0xF2, 0xEA, 0xD8, 255), trait=1.8)
        cap = [(x - 7 * k + 3.5 * k - 3.5 * k * math.cos(math.pi * i / 10) - 0 * k, y - 8 * k - math.sin(math.pi * i / 10) * 6 * k) for i in range(11)]
        cap = [(x - 7 * k * math.cos(math.pi * i / 10), y - 7.5 * k - math.sin(math.pi * i / 10) * 6 * k) for i in range(11)]
        forme(im, cap, chap, trait=2.0)
        if rouge:
            for dx, dy in [(-3, -3), (1.5, -4.5), (3.5, -1.5)]:
                ellipse(im, (x + dx * k - 0.9, y - 9 * k + dy * k - 0.9, x + dx * k + 0.9, y - 9 * k + dy * k + 0.9), (255, 255, 255, 255), trait=0)
    return finir(im, f"champignons_{n}", "objet", (W // 2, H - 3))


# ---------------------------------------------------------------- muret de pierres sèches (segment d'une case)
def muret(sens, n, seed):
    r = random.Random(seed)
    if sens == "h":
        W, H = 124, 30
    else:
        W, H = 28, 128
    im = toile(W, H)
    teintes = [(0xA9, 0xA2, 0x94, 255), (0x9A, 0x92, 0x84, 255), (0xB4, 0xAD, 0x9F, 255), (0x8E, 0x87, 0x7A, 255)]
    if sens == "h":
        for rang, y in enumerate((H - 9, H - 17)):
            x = 2 + (6 if rang else 0)
            while x < W - 8:
                w = r.uniform(11, 17)
                ellipse(im, (x, y - 5, x + w, y + 5), r.choice(teintes), trait=2.1)
                x += w - 1.5
    else:
        y = 4
        while y < H - 10:
            h = r.uniform(10, 14)
            for col, x in enumerate((5, 14)):
                ellipse(im, (x - 1 + (2 if col else 0), y + (4 if col else 0), x + 11, y + h + (4 if col else 0)), r.choice(teintes), trait=2.1)
            y += h - 1
    return finir(im, f"muret_{sens}_{n}", "objet", (W // 2, H - 4))


for i, s in enumerate([11, 12, 13]):
    ajoute(aiguille(i + 1, s))
for i, s in enumerate([21, 22, 23]):
    ajoute(dome(i + 1, s))
for i in range(2):
    ajoute(grotte(i + 1, 40 + i))
    ajoute(rocher_eau(i + 1, 50 + i))
    ajoute(traces(i + 1, 60 + i))
    ajoute(taupiniere(i + 1, 70 + i))
    ajoute(tronc(i + 1, 80 + i))
    ajoute(muret("h", i + 1, 90 + i))
    ajoute(muret("v", i + 1, 95 + i))
for i in range(3):
    ajoute(galets(i + 1, 100 + i))
    ajoute(champignons(i + 1, 110 + i))
ajoute(fourmiliere(1, 120))

man = f"{DEST}/assets/bd/decor_bd.json"
j = json.load(open(man))
j["elements"].update(sortie)
json.dump(j, open(man, "w"), ensure_ascii=False, indent=1)
print(len(sortie), "éléments")
