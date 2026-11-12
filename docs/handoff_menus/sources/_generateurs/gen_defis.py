"""Maquettes de la page Défis et de son classement : 5 états."""
from gen_menu import ecrire

CSS = """
.heros { position: absolute; left: 20px; top: 20px; width: 740px; height: 252px; background: #fff; border: 2.5px solid var(--encre); border-radius: 10px; box-shadow: 0 4px 0 var(--encre); overflow: hidden; }
.choisi { box-shadow: 0 4px 0 var(--encre), 0 0 0 4px var(--jaune); }     /* sélection : anneau jaune 4 px */
.heros .bandeau { height: 40px; background: var(--jaune); border-bottom: 2px solid var(--encre); display: flex; align-items: center; justify-content: space-between; padding: 0 14px; }
.heros .passe { position: absolute; left: 0; right: 0; bottom: 0; height: 44px; background: var(--memo); border-top: 2px solid var(--encre); display: flex; align-items: center; gap: 10px; padding: 0 14px; font: 600 13px Barlow; }
.compte { font: 600 30px/1 'IBM Plex Mono'; }
.grille { position: absolute; left: 20px; top: 314px; width: 740px; display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; }
.dcarte { min-width: 0; height: 284px; background: #fff; border: 2px solid var(--encre); border-radius: 10px; box-shadow: 0 4px 0 var(--encre); padding: 10px; display: flex; flex-direction: column; gap: 6px; }
.dcarte img.vign { width: 100%; height: 76px; }
.dcarte h4 { margin: 2px 0 0; font: 800 19px/1 'Barlow Condensed'; text-transform: uppercase; min-height: 38px; }
.dcarte .l { display: flex; justify-content: space-between; font: 600 13px Barlow; }
.dcarte .l b { font-family: 'IBM Plex Mono'; }
.cote { position: absolute; left: 778px; top: 20px; width: 462px; height: 579px; }
.cote .pos { display: flex; align-items: center; gap: 14px; padding: 12px 14px; border-bottom: 2px solid var(--encre); background: var(--papier2); }
.cote .pos .grand { font: 600 40px/1 'IBM Plex Mono'; }
.lg { display: grid; grid-template-columns: 40px 1fr 54px 92px; align-items: center; height: 33px; padding: 0 14px; border-bottom: 1px solid var(--filet); font: 600 14px Barlow; }
.lg.vous { background: var(--jaune); border: 2px solid var(--encre); margin: 0 6px; padding: 0 8px; border-radius: 6px; height: 35px; }
.lg .rg { font: 600 14px 'IBM Plex Mono'; }
.podium { width: 26px; height: 26px; border-radius: 50%; border: 2px solid var(--encre); display: flex; align-items: center; justify-content: center; font: 700 13px 'IBM Plex Mono'; }
.masque { display: inline-flex; align-items: center; height: 22px; padding: 0 9px; border-radius: 11px; border: 1.5px dashed #8C96A2; color: var(--texte2);
  font: italic 600 12px Barlow; background: repeating-linear-gradient(135deg, #F1F3F5 0 6px, #E6E9EC 6px 12px); }
.sc { text-align: right; font: 600 15px 'IBM Plex Mono'; }
.bar { height: 8px; background: var(--filet); border-radius: 4px; margin-left: 12px; overflow: hidden; }
.bar i { display: block; height: 100%; background: var(--sarcelle); }
.points { text-align: center; font: 700 16px 'IBM Plex Mono'; color: var(--texte2); height: 22px; letter-spacing: .3em; }
.hors-ligne { font: 600 12px 'IBM Plex Mono'; color: var(--neg); display: flex; align-items: center; gap: 6px; }
"""

DEFIS = {
    "saules": ("La vallée des Saules", "cl", 202611, None, None, None, 38),
    "roches": ("Le plateau des Roches", "cl", 424242, 127, 2, 21, 44),
    "delta": ("Le delta sauvage", "rn", 318807, 151, 1, 3, 41),
    "monts": ("Monts et marais", "rn", 777013, 96, 4, 17, 29),
}
TOP = {
    "semaine": [158, 149, 147, 140, 136, 131, 129, 127, 122, 118],
    "saules": [162, 155, 150, 148, 141, 139, 133, 130, 126, 121],
    "delta": [("Margaux_R", 168), ("PingouinFiscal", 157), ("Daniel", 151), ("LaLoutreDuNord", 149), ("Kev_Zoo", 144), ("Sabine.T", 141),
              ("Hippocampus", 137), ("ZooKeeper77", 133), ("Ondine", 129), ("MrLynx", 126)],
}


def pastille(m, court=False):
    if m == "cl":
        return f'<span class="pastille mode-cl"><i class="forme f-triangle" style="background:var(--orange)"></i>{"Aménagements" if court else "Avec aménagements"}</span>'
    return '<span class="pastille mode-rn"><i class="forme f-rond" style="background:var(--pos)"></i>Réserve naturelle</span>'


def squel(w, h=12):
    return f'<span class="squelette" style="display:inline-block;width:{w}px;height:{h}px;vertical-align:middle"></span>'


def heros(etat, choisi):
    if etat == "hors":
        rang = '<span class="t2">hors ligne</span>'
    elif etat == "charge":
        rang = squel(70)
    else:
        rang = '<b class="mono">14<sup>e</sup></b> sur <b class="mono">52</b>'
    return f'''<div class="heros{" choisi" if choisi else ""}">
<div class="bandeau"><span class="cond" style="font-size:22px;text-transform:uppercase">Défi de la semaine du 9/11</span><span class="mono" style="font-size:12px">nouveau défi lundi 16/11</span></div>
<div style="display:flex;gap:16px;padding:14px">
 <img class="vign" src="assets/cartes/carte_600024843.png" style="width:142px;height:142px" alt="">
 <div style="flex:1">
  {pastille("rn")}
  <div class="petit t2" style="font-weight:600;margin-top:6px">Carte n° 600024843 · 10 jours · 3 IA en Difficile</div>
  <div class="surtitre" style="margin-top:12px">SE TERMINE DANS</div>
  <div class="compte" style="margin-top:3px">3 j 03 h 14 min</div>
  <div class="petit t2" style="font-weight:600;margin-top:3px">dimanche 15/11 à 23 h 59</div>
 </div>
 <div style="width:196px;display:flex;flex-direction:column;gap:6px">
  <div class="l" style="display:flex;justify-content:space-between;font:600 13px Barlow"><span class="t2">Votre record</span><b class="mono" style="font-size:18px">112</b></div>
  <div style="display:flex;justify-content:space-between;font:600 13px Barlow"><span class="t2">Parties</span><b class="mono">3</b></div>
  <div style="display:flex;justify-content:space-between;font:600 13px Barlow"><span class="t2">Rang</span><span>{rang}</span></div>
  <div class="btn p" style="height:44px;margin-top:6px;font-size:19px">Jouer le défi ›</div>
 </div></div>
<div class="passe"><i class="forme f-etoile" style="background:var(--jaune);border:1px solid var(--encre)"></i>
 <span><span class="t2">Semaine du 2/11 · vainqueur :</span> <b>Margaux_R</b> · <b class="mono">163</b> · Partie classique</span>
 <span style="margin-left:auto" class="btn mini">▶ Revoir sa partie</span></div>
</div>'''


def carte_defi(k, choisi, etat):
    nom, m, g, rec, n, rg, tot = DEFIS[k]
    if rec is None:
        lignes = '<div class="l"><span class="t2">Pas encore joué</span></div>' + (f'<div class="l"><span class="t2">Participants</span><b>{tot}</b></div>' if etat not in ("hors", "charge") else "")
    else:
        if etat == "hors":
            rang = '<span class="t2">—</span>'
        elif etat == "charge":
            rang = squel(54)
        else:
            rang = f'<b>{rg}<sup>e</sup> / {tot}</b>'
        lignes = f'<div class="l"><span class="t2">Record</span><b>{rec}</b></div><div class="l"><span class="t2">Parties</span><b>{n}</b></div><div class="l"><span class="t2">Rang</span>{rang}</div>'
    clas = '<span class="btn mini" style="flex:1;background:var(--encre);color:#fff">Classement</span>' if choisi else '<span class="btn mini" style="flex:1">Classement</span>'
    return f'''<div class="dcarte{" choisi" if choisi else ""}"><img class="vign" src="assets/cartes/carte_{g}.png" alt="">
<h4>{nom}</h4><div>{pastille(m, court=True)}</div><div style="display:flex;flex-direction:column;gap:3px;margin-top:2px">{lignes}</div>
<div style="display:flex;gap:6px;margin-top:auto">{clas}<span class="btn mini p" style="font-size:14px">Jouer</span></div></div>'''


def podium(i):
    if i < 3:
        c = ["#FFC93C", "#D5D9DE", "#E2A06A"][i]
        return f'<div class="podium" style="background:{c}">{i+1}</div>'
    return f'<div class="rg" style="padding-left:6px">{i+1}</div>'


def ligne(i, nom, score, maxi, vous=False):
    p = nom if nom else '<span class="masque">joueur masqué</span>'
    if vous:
        p = f'<span><b>Vous</b> <span class="t2" style="color:var(--encre)">· {nom}</span></span>'
    return f'<div class="lg{" vous" if vous else ""}">{podium(i)}<div>{p}</div><div class="sc">{score}</div><div class="bar"><i style="width:{score/maxi*100:.0f}%"></i></div></div>'


def cote(etat, cle):
    if cle == "semaine":
        titre, vign, part = "Défi de la semaine du 9/11", 600024843, 52
    else:
        titre, vign, part = DEFIS[cle][0], DEFIS[cle][2], DEFIS[cle][6]
    tete = f'<div class="tete encre"><span>Cote · {titre}</span><span class="mono" style="color:var(--jaune)">{part} participants</span></div>' if etat not in ("hors", "charge") else \
        f'<div class="tete encre"><span>Cote · {titre}</span><span class="mono" style="color:var(--jaune)">{"…" if etat == "charge" else "hors ligne"}</span></div>'
    pied = '''<div style="position:absolute;left:14px;right:14px;bottom:12px;font:600 12px/1.35 Barlow" class="t2">
Les pseudos du top 10 deviennent visibles quand vous y entrez. Les parties sont privées ; seule celle du vainqueur de la semaine passée peut être revue.</div>'''
    if etat == "hors":
        corps = f'''<div class="pos"><div><div class="surtitre">MEILLEUR SCORE SUR CET ORDINATEUR</div><div style="display:flex;align-items:baseline;gap:10px;margin-top:4px"><span class="grand">112</span><span class="t2" style="font-weight:600">3 parties</span></div></div></div>
<div style="margin:22px 14px;height:300px;border:2px dashed #8C96A2;border-radius:10px;background:var(--papier2);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px;text-align:center;padding:20px">
<div class="cond" style="font-size:24px;text-transform:uppercase">Classement indisponible</div>
<div style="font:600 14px/1.4 Barlow;max-width:330px" class="t2">Impossible de joindre le serveur. Vous pouvez jouer : le score sera envoyé à la prochaine connexion.</div>
<div class="btn">↻ Réessayer</div></div>'''
        return f'<div class="cote panneau">{tete}{corps}{pied}</div>'
    if etat == "charge":
        lignes = "".join(f'<div class="lg">{podium(i)}<div>{squel(110 + (i * 37) % 70)}</div><div class="sc">{squel(30)}</div><div class="bar"></div></div>' for i in range(10))
        corps = f'''<div class="pos"><div><div class="surtitre">VOTRE RANG</div><div style="display:flex;align-items:baseline;gap:10px;margin-top:4px"><span class="grand">{squel(60, 34)}</span><span class="t2" style="font-weight:600">record 112 · 3 parties</span></div></div>
<div style="margin-left:auto" class="mono t2">cotation en cours…</div></div>
<div style="padding-top:6px">{lignes}</div>'''
        return f'<div class="cote panneau">{tete}{corps}{pied}</div>'
    if cle == "delta":
        maxi = TOP["delta"][0][1]
        lignes = "".join(ligne(i, n, s, maxi, vous=(n == "Daniel")) for i, (n, s) in enumerate(TOP["delta"]))
        pos = '<span class="grand">3<sup style="font-size:20px">e</sup></span><span style="font:600 14px Barlow">sur 41</span>'
        bloc = f'''<div class="pos"><div><div class="surtitre">VOTRE RANG</div><div style="display:flex;align-items:baseline;gap:8px;margin-top:4px">{pos}</div></div>
<div style="margin-left:auto;text-align:right"><div class="surtitre">VOTRE RECORD</div><div class="mono" style="font-size:22px;margin-top:4px">151</div><div class="petit" style="color:var(--pos);font-weight:700">✓ dans le top 10 : pseudos visibles</div></div></div>
<div style="padding-top:6px">{lignes}</div>'''
        return f'<div class="cote panneau">{tete}{bloc}{pied}</div>'
    scores = TOP[cle]
    maxi = scores[0]
    lignes = "".join(ligne(i, None, s, maxi) for i, s in enumerate(scores))
    if cle == "semaine":
        moi = ligne(13, "Daniel", 112, maxi, vous=True)
        pos = '<span class="grand">14<sup style="font-size:20px">e</sup></span><span style="font:600 14px Barlow">sur 52</span>'
        droite = '<div class="surtitre">VOTRE RECORD</div><div class="mono" style="font-size:22px;margin-top:4px">112</div><div class="petit t2" style="font-weight:700">6 points du top 10</div>'
    else:
        moi = '''<div class="lg vous" style="grid-template-columns:40px 1fr auto;background:var(--jaune-cl)"><div class="rg" style="padding-left:6px">—</div><div><b>Vous</b> <span class="t2">· pas encore classé</span></div><span class="btn mini p" style="font-size:13px">Jouer ›</span></div>'''
        pos = '<span class="grand">—</span><span style="font:600 14px Barlow">sur 38</span>'
        droite = '<div class="surtitre">VOTRE RECORD</div><div class="mono" style="font-size:22px;margin-top:4px">—</div><div class="petit t2" style="font-weight:700">jouez une fois pour être classé</div>'
    bloc = f'''<div class="pos"><div><div class="surtitre">VOTRE RANG</div><div style="display:flex;align-items:baseline;gap:8px;margin-top:4px">{pos}</div></div>
<div style="margin-left:auto;text-align:right">{droite}</div></div>
<div style="padding-top:6px">{lignes}</div><div class="points">⋯</div>{moi}'''
    return f'<div class="cote panneau">{tete}{bloc}{pied}</div>'


def defis(nom, etat, cle):
    sur = 'LA MÊME PARTIE POUR TOUS · 10 JOURS · SEUL CONTRE LES 3 MEILLEURES IA'
    note = ""
    if etat == "hors":
        note = '<div class="hors-ligne" style="position:absolute;right:80px;top:30px"><i class="forme f-triangle" style="background:var(--neg)"></i>Hors ligne : classements indisponibles</div>'
    cartes = "".join(carte_defi(k, k == cle, etat) for k in DEFIS)
    corps = f'''<img class="fond" src="assets/fond_menu.png" alt=""><div class="voile"></div>
<div class="fenetre"><div class="haut"><div class="surtitre">{sur}</div><div class="titre" style="margin-top:4px">Défis</div>
<div style="position:absolute;left:150px;top:46px;font:600 13px Barlow" class="t2">Même carte, même draft, mêmes collaborateurs et même marché pour tous. Score : votre réputation au soir du jour 10.</div>
{note}<div class="fermer">×</div></div>
<div style="position:relative;height:619px">
{heros(etat, cle == "semaine")}
<div style="position:absolute;left:20px;top:288px;width:740px;display:flex;align-items:baseline;gap:12px"><span class="entete" style="color:var(--encre);font-size:14px">Défis permanents</span><span class="petit t2" style="font-weight:600">toujours ouverts · un classement chacun</span></div>
<div class="grille">{cartes}</div>
{cote(etat, cle)}
</div></div>'''
    return f"""<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><title>{nom}</title>
<link rel="stylesheet" href="commun.css"><style>{CSS}</style></head>
<body><div class="ecran">
{corps}
</div></body></html>
"""


if __name__ == "__main__":
    ecrire("30_defis_hors_top10", defis("Défis — hors du top 10", "ok", "semaine"))
    ecrire("31_defis_dans_top10", defis("Défis — dans le top 10", "ok", "delta"))
    ecrire("32_defis_jamais_joue", defis("Défis — jamais joué", "ok", "saules"))
    ecrire("33_defis_indisponible", defis("Défis — classement indisponible", "hors", "semaine"))
    ecrire("34_defis_chargement", defis("Défis — chargement", "charge", "semaine"))
    print("défis ok")
