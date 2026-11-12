"""Maquettes du menu principal : variante A (sommaire en chapitres + fiche de mode agrafée) et variante B (chemises de mode)."""
import os

ICI = os.path.dirname(os.path.abspath(__file__))


def page(titre, corps, extra_css=""):
    return f"""<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><title>{titre}</title>
<link rel="stylesheet" href="commun.css">
<style>{extra_css}</style></head>
<body><div class="ecran">
{corps}
</div></body></html>
"""


CSS_MENU = """
/* couverture du rapport : x 60, l 520, h 900 */
.couv { position: absolute; left: 60px; top: 0; width: 520px; height: 900px; background: #fff; border-left: 2.5px solid var(--encre);
  border-right: 2.5px solid var(--encre); box-shadow: 10px 0 0 rgba(20,32,43,.35); padding: 26px 36px 18px; display: flex; flex-direction: column; }
.couv .logo { width: 236px; margin: 6px auto 0; display: block; }
.slogan { font: italic 600 14px/1.3 Barlow; text-align: center; color: var(--texte2); margin-top: 2px; }
.sommaire { border-top: 3px solid var(--encre); margin-top: 14px; padding-top: 6px; }
.chap { display: flex; align-items: center; gap: 8px; height: 26px; margin-top: 4px; font: 800 12px 'Barlow Condensed'; letter-spacing: .1em; color: var(--texte2); }
.chap::after { content: ""; flex: 1; border-top: 1px solid var(--filet); }
.chap b { font: 600 11px 'IBM Plex Mono'; color: var(--texte2); }
/* ligne du sommaire : h 38, rayon 8 ; sélection = jaune + contour 2 encre */
.toc { position: relative; display: flex; align-items: center; gap: 10px; height: 38px; padding: 0 12px; border-radius: 8px; border: 2px solid transparent; }
.toc i { font: 600 13px 'IBM Plex Mono'; font-style: normal; color: var(--texte2); width: 22px; }
.toc b { font: 800 21px 'Barlow Condensed'; text-transform: uppercase; letter-spacing: .01em; }
.toc span.pts { flex: 1; border-bottom: 2px dotted #9AA2AC; transform: translateY(5px); }
.toc em { font: 600 13px Barlow; font-style: normal; color: var(--texte2); }
.toc.on { background: var(--jaune); border-color: var(--encre); }
.toc.on em, .toc.on i { color: var(--encre); }
.toc .flag { font: 700 11px 'IBM Plex Mono'; background: var(--encre); color: var(--jaune); padding: 2px 6px; border-radius: 4px; }
/* languette qui relie la ligne choisie à la fiche de mode : jaune, contour haut/bas 2 encre */
/* ligne choisie : le jaune file jusqu'au bord de la couverture (x 582), puis la languette rejoint la fiche (x 582 → 612, recouvre son contour) */
.toc.on, .reprise.on { margin-right: -38.5px; border-right: none; border-radius: 8px 0 0 8px; padding-right: 50.5px; }
.toc.on::after, .reprise.on::after { content: ""; position: absolute; left: 100%; top: -2px; bottom: -2px; width: 30px; background: var(--jaune);
  border-top: 2px solid var(--encre); border-bottom: 2px solid var(--encre); z-index: 5; }
.languette { position: absolute; background: var(--jaune); z-index: 5; }
.pied { margin-top: auto; }
.fiche-j { display: flex; align-items: center; gap: 10px; border-top: 2px solid var(--encre); padding-top: 10px; }
.fiche-j img { width: 34px; height: 34px; }
.fiche-j .q { flex: 1; line-height: 1.15; }
.citation { font: italic 600 13px Barlow; color: var(--texte2); text-align: center; margin-top: 10px; }
.bas { display: flex; justify-content: space-between; align-items: center; margin-top: 6px; font: 500 11px 'IBM Plex Mono'; color: var(--texte2); }
/* dossier en cours (sauvegarde) */
.reprise { position: relative; margin-top: 12px; border: 2px solid var(--encre); border-radius: 8px; padding: 8px 12px; display: flex; align-items: center; gap: 12px; background: var(--memo); }
.reprise.on { background: var(--jaune); }
/* fiche de mode : x 604, l 452 */
.fiche { position: absolute; left: 604px; width: 452px; }
.fiche .lab { font: 800 12px 'Barlow Condensed'; letter-spacing: .08em; color: var(--texte2); margin: 14px 0 6px; text-transform: uppercase; }
.regles { padding: 12px 14px; border-bottom: 2px solid var(--encre); }
.regles p { margin: 0 0 8px; font: 600 14px/1.35 Barlow; }
.regles .chips { display: flex; flex-wrap: wrap; gap: 6px; }
.rivaux { display: flex; align-items: center; gap: 6px; margin-top: 8px; font: 600 13px Barlow; }
.rivaux img { width: 32px; height: 32px; border: 1.5px solid var(--encre); border-radius: 6px; background: #fff; }
.cartebloc { display: flex; gap: 12px; }
.cartebloc img { width: 104px; height: 104px; }
.note-rem { margin-top: 10px; font: 600 12px Barlow; color: var(--neg); display: flex; gap: 6px; align-items: center; }
/* note de service du défi de la semaine, épinglée sur la carte */
.note-service { position: absolute; left: 1120px; top: 548px; width: 420px; background: var(--memo); border: 2.5px solid var(--encre); border-radius: 8px;
  box-shadow: 0 5px 0 var(--encre); transform: rotate(-1.5deg); padding: 16px 18px 14px; }
.punaise { position: absolute; left: 196px; top: -10px; width: 20px; height: 20px; border-radius: 50%; background: var(--neg); border: 2px solid var(--encre); }
.dev { position: absolute; right: 14px; top: 12px; height: 26px; padding: 0 9px; border: 1.5px dashed rgba(255,255,255,.8); border-radius: 6px;
  background: rgba(20,32,43,.55); color: #fff; font: 600 11px 'IBM Plex Mono'; display: flex; align-items: center; }
"""


def toc(num, nom, note, on=False, flag=""):
    f = f'<span class="flag">{flag}</span>' if flag else ""
    return f'<div class="toc{" on" if on else ""}"><i>{num}</i><b>{nom}</b>{f}<span class="pts"></span><em>{note}</em></div>'


def couverture(sel, sauvegarde):
    lignes = []
    rep = ""
    if sauvegarde:
        rep = f'''<div class="reprise{" on" if sel == "continuer" else ""}">
  <div style="flex:1"><div class="entete" style="color:var(--encre)">DOSSIER EN COURS · CONTINUER</div>
  <div style="font:600 13px Barlow;margin-top:2px">Partie classique · <span class="mono">Jour 6</span> · 4 joueurs · il y a 2 h</div></div>
  <div class="btn p mini" style="height:32px">Reprendre ›</div></div>'''
    lignes.append('<div class="chap"><b>I</b>JOUER</div>')
    lignes.append(toc("01", "Partie classique", "vous + 1 à 3 IA", sel == "classique"))
    lignes.append(toc("02", "Réserve naturelle", "terrain tel quel", sel == "reserve"))
    lignes.append(toc("03", "Gestion libre", "seul, sans fin", sel == "libre"))
    lignes.append(toc("04", "Multijoueur", "2 à 4 joueurs", sel == "multi"))
    lignes.append('<div class="chap"><b>II</b>DÉFIS · LA MÊME PARTIE POUR TOUS</div>')
    lignes.append(toc("05", "Défi de la semaine", "fin dans 3 j 3 h", sel == "semaine", flag="9/11"))
    lignes.append(toc("06", "Défis permanents", "4 cartes · classements", sel == "defis"))
    lignes.append('<div class="chap"><b>III</b>APPRENDRE</div>')
    lignes.append(toc("07", "Tutoriel", "avec Hubert", sel == "tuto"))
    lignes.append(toc("08", "Règles et glossaire", "", sel == "regles"))
    return f'''<div class="couv">
<div style="display:flex;justify-content:space-between" class="surtitre"><span>RAPPORT ANNUEL</span><span>EXERCICE 2026</span></div>
<img class="logo" src="assets/logos/zoolife.png" alt="ZooLife">
<div class="slogan">Bâtissez le zoo le plus rentable de la vallée,<br>avec le personnel que vous méritez.</div>
{rep}
<div class="sommaire"><div class="entete" style="color:var(--encre);letter-spacing:.1em">SOMMAIRE</div>
{"".join(lignes)}
</div>
<div class="pied">
  <div class="fiche-j"><img src="assets/logos/zoolife_embleme.png" alt="">
    <div class="q"><div class="cond" style="font-size:17px">DANIEL</div><div class="petit t2" style="font-weight:600">52 parties · 26 victoires · record 151</div></div>
    <div class="btn mini">Statistiques ›</div></div>
  <div style="display:flex;gap:8px;margin-top:10px"><div class="btn mini" style="flex:1">Réglages</div><div class="btn mini" style="flex:1">Quitter</div></div>
  <div class="citation">« Un collaborateur fatigué est un collaborateur qui a travaillé. » H. de la Marge</div>
  <div class="bas"><span>Document réservé aux collaborateurs</span><span class="tampon" style="font-size:13px;padding:2px 8px">CONFIDENTIEL</span></div>
</div>
</div>'''


def note_service():
    return '''<div class="note-service"><div class="punaise"></div>
<div class="surtitre" style="color:var(--encre)">NOTE DE SERVICE · DÉFI DE LA SEMAINE</div>
<div style="display:flex;gap:14px;margin-top:8px">
 <img class="vign" src="assets/cartes/carte_600024843.png" style="width:96px;height:96px" alt="">
 <div style="flex:1">
  <div class="cond" style="font-size:25px;line-height:1">Semaine du 9/11</div>
  <div style="margin-top:5px"><span class="pastille mode-rn"><i class="forme f-rond" style="background:var(--pos)"></i>Réserve naturelle</span></div>
  <div class="mono" style="font-size:22px;margin-top:8px">3 j 03 h 14</div>
  <div class="petit t2" style="font-weight:600">avant dimanche 23 h 59</div>
 </div></div>
<div style="display:flex;align-items:center;justify-content:space-between;margin-top:10px;border-top:1.5px solid var(--filet);padding-top:9px">
 <div style="font:600 13px Barlow">Votre rang : <b class="mono">14<sup>e</sup></b> sur 52 · record <b class="mono">112</b></div>
 <div class="btn mini">Voir le défi ›</div></div>
<div class="petit t2" style="font-weight:600;margin-top:7px">Vainqueur de la semaine passée : <b style="color:var(--encre)">Margaux_R</b> (163) · <u>Revoir sa partie</u></div>
</div>'''


def rivaux(n=3):
    noms = ["PanZoo", "Safari Capital", "BioLand"][:n]
    imgs = "".join(f'<img src="assets/logos/{x}_embleme.png" alt="">' for x in ["panzoo", "safari", "bioland"][:n])
    return f'<div class="rivaux">{imgs}<span>{", ".join(noms)}</span></div>'


def bloc_carte(graine, prop="Forêt 21 % · eau 13 % · roche 11 %"):
    prop = prop.replace(" %", "\u202f%")
    return f'''<div class="lab">Carte</div><div class="cartebloc"><img class="vign" src="assets/cartes/carte_{graine}.png" alt="">
<div style="flex:1;display:flex;flex-direction:column;gap:8px"><div class="champ">{graine}</div><div class="btn" style="height:34px">↻ Autre carte</div>
<div class="petit t2" style="font-weight:600">{prop}</div></div></div>'''


def fiche(mode, top, sauvegarde):
    rem = '<div class="note-rem"><i class="forme f-triangle" style="background:var(--neg)"></i>Une nouvelle partie remplacera le dossier en cours (jour 6).</div>' if sauvegarde else ""
    if mode == "classique":
        return f'''<div class="fiche panneau" style="top:{top}px">
<div class="tete"><span>01 · Partie classique</span><span class="mono">~14 jours</span></div>
<div class="regles memo"><p>Premier à <b class="mono">120</b> de réputation. Le terrain s'aménage : creuser des bassins, planter, dérocher.</p>
<div class="chips"><span class="pastille mode-cl"><i class="forme f-triangle" style="background:var(--orange)"></i>Terrain aménageable</span><span class="pastille">Objectif 120</span><span class="pastille">Vous + IA</span></div></div>
<div class="corps" style="padding-top:2px">
<div class="lab">Adversaires</div><div class="seg"><div>1</div><div>2</div><div class="on">3</div></div>{rivaux()}
<div class="lab">Difficulté</div><div class="seg"><div>Facile</div><div class="on">Moyen</div><div>Difficile</div></div>
{bloc_carte(54953)}
<div style="margin-top:16px" class="btn p grand">Signer la prise de poste ›</div>{rem}
</div></div>'''
    if mode == "reserve":
        motif = "".join(
            f'<i style="position:absolute;left:{x*13}px;top:{y*13}px;width:12px;height:12px;background:{c};border:1px solid var(--encre)"></i>'
            for x, y, c in [(0, 0, "#9C968A"), (1, 0, "#9C968A"), (2, 0, "#9C968A"), (3, 0, "#3E8E41"), (0, 1, "#9C968A"), (2, 1, "#9C968A"), (3, 1, "#3E8E41"),
                            (0, 2, "#9C968A"), (1, 2, "#9C968A"), (2, 2, "#3E8E41"), (3, 2, "#3E8E41"), (1, 3, "#8CCB5E")])
        return f'''<div class="fiche panneau" style="top:{top}px">
<div class="tete" style="background:var(--pos)"><span>02 · Réserve naturelle</span><span class="mono" style="color:#D6F0DF">~14 jours</span></div>
<div class="regles memo" style="display:flex;gap:14px"><div style="flex:1"><p>Pas d'aménagement : trouvez sur la carte les endroits où le motif de chaque animal existe déjà.</p>
<div class="chips"><span class="pastille mode-rn"><i class="forme f-rond" style="background:var(--pos)"></i>Terrain tel quel</span><span class="pastille">Objectif 120</span></div></div>
<div style="width:72px;text-align:center"><div style="position:relative;width:52px;height:52px;margin:2px auto 4px">{motif}</div><div class="petit t2" style="font-weight:600;line-height:1.1">motif de l'aigle royal</div></div></div>
<div class="corps" style="padding-top:2px">
<div class="lab">Adversaires</div><div class="seg"><div>1</div><div>2</div><div class="on">3</div></div>{rivaux()}
<div class="lab">Difficulté</div><div class="seg"><div>Facile</div><div class="on">Moyen</div><div>Difficile</div></div>
{bloc_carte(227624, "Forêt 24 % · eau 15 % · roche 13 % · le relief compte : choisissez une carte variée")}
<div style="margin-top:16px" class="btn p grand">Signer la prise de poste ›</div>
</div></div>'''
    if mode == "libre":
        return f'''<div class="fiche panneau" style="top:{top}px">
<div class="tete" style="background:var(--marine)"><span>03 · Gestion libre</span><span class="mono" style="color:#C9D6E3">sans fin</span></div>
<div class="regles memo"><p>Seul, sans objectif ni fin de partie. Les animaux font des petits, les visiteurs signent le livre d'or.</p>
<div class="chips"><span class="pastille">Seul</span><span class="pastille">90 d'argent au départ</span><span class="pastille">Pas de maladie</span><span class="pastille">Naissances</span></div></div>
<div class="corps" style="padding-top:2px">
<div class="lab">Adversaires · difficulté</div>
<div class="btn off" style="width:100%;height:38px;justify-content:flex-start;font-weight:600">Sans objet en gestion libre : aucun rival, aucune pression</div>
{bloc_carte(54953)}
<div style="margin-top:16px" class="btn p grand">Ouvrir le parc ›</div>
</div></div>'''
    if mode == "continuer":
        joueurs = [("Vous", "zoolife", 58, "var(--j1)", "f-rond"), ("PanZoo", "panzoo", 61, "var(--j2)", "f-carre"),
                   ("Safari Capital", "safari", 44, "var(--j3)", "f-triangle"), ("BioLand", "bioland", 39, "var(--j4)", "f-losange")]
        rows = "".join(f'''<div style="display:flex;align-items:center;gap:8px;height:30px"><img src="assets/logos/{l}_embleme.png" style="width:24px;height:24px" alt="">
<span style="width:112px;font:{"800" if n=="Vous" else "600"} 14px Barlow">{n}</span><i class="forme {f}" style="background:{c}"></i>
<div class="barre" style="flex:1"><i style="width:{v/120*100:.0f}%;background:{c}"></i></div><b class="mono" style="width:34px;text-align:right">{v}</b></div>''' for n, l, v, c, f in joueurs)
        return f'''<div class="fiche panneau" style="top:{top}px">
<div class="tete encre"><span>Dossier en cours · Partie classique</span><span class="mono" style="color:var(--jaune)">jour 6 / ~14</span></div>
<div class="corps">
<div style="display:flex;gap:14px"><img class="vign" src="assets/cartes/carte_202611.png" style="width:120px;height:120px" alt="">
<div style="flex:1"><div class="surtitre">SAUVEGARDÉ IL Y A 2 H</div>
<div class="cond" style="font-size:24px;margin-top:6px">Soir du jour 6</div>
<div style="font:600 13px/1.35 Barlow;margin-top:4px" class="t2">Carte n° 202611 · 3 adversaires · Moyen<br>Zoo ouvert depuis le jour 5 · 4 espèces</div></div></div>
<div class="lab">Réputation (objectif 120)</div>{rows}
<div style="margin-top:18px" class="btn p grand">Reprendre le dossier ›</div>
<div class="petit t2" style="font-weight:600;margin-top:10px;text-align:center">Les autres modes restent accessibles dans le sommaire.</div>
</div></div>'''


def menu_A(nom, sel, sauvegarde):
    y0 = 314 if sauvegarde else 238   # ordonnée de la 1re ligne du chapitre I (dépend du bloc « dossier en cours »)
    pos = {"classique": y0 + 30, "reserve": y0 + 68, "libre": y0 + 106, "continuer": None}
    if sel == "continuer":
        lang_top, fiche_top = 236, 214
    else:
        lang_top = pos[sel]
        fiche_top = 300 if sauvegarde else 238
    corps = f'''<img class="fond" src="assets/menu_fond.jpg" alt="Carte vivante du menu">
<div class="dev">DÉV. ▾</div>
{couverture(sel, sauvegarde)}
{fiche(sel, fiche_top, sauvegarde)}
{note_service()}'''
    return page(nom, corps, CSS_MENU)


# ------------------------------------------------------------------ variante B : chemises de mode
CSS_B = CSS_MENU + """
.couvB { position: absolute; left: 60px; top: 0; width: 400px; height: 900px; background: #fff; border-left: 2.5px solid var(--encre);
  border-right: 2.5px solid var(--encre); box-shadow: 10px 0 0 rgba(20,32,43,.35); padding: 26px 30px 18px; display: flex; flex-direction: column; }
.chemises { position: absolute; left: 500px; top: 46px; width: 1060px; display: grid; grid-template-columns: repeat(3, 1fr); gap: 22px 20px; }
.chemise { position: relative; height: 150px; background: var(--memo); border: 2.5px solid var(--encre); border-radius: 0 10px 10px 10px; box-shadow: 0 4px 0 var(--encre); padding: 14px 16px; }
.chemise .onglet { position: absolute; left: -2.5px; top: -22px; height: 22px; padding: 0 12px; background: var(--memo); border: 2.5px solid var(--encre); border-bottom: none;
  border-radius: 6px 6px 0 0; font: 600 11px 'IBM Plex Mono'; display: flex; align-items: center; }
.chemise.on, .chemise.on .onglet { background: var(--jaune); }
.chemise.sem { background: #fff; }
.chemise h3 { margin: 0; font: 800 24px/1 'Barlow Condensed'; text-transform: uppercase; }
.chemise p { margin: 6px 0 0; font: 600 13px/1.3 Barlow; color: var(--texte2); max-width: 200px; }
.chemise .ill { position: absolute; right: 12px; bottom: 10px; width: 84px; height: 84px; object-fit: contain; }
.reglagesB { position: absolute; left: 500px; top: 430px; width: 1060px; }
.listeB .toc b { font-size: 19px; }
"""


def menu_B():
    cartes = [
        ("05", "Défi de la semaine", "", "assets/cartes/carte_600024843.png", "sem"),
        ("06", "Défis permanents", "4 cartes fixes, un classement chacune.", "assets/cartes/carte_318807.png", ""),
        ("04", "Multijoueur", "2 à 4 humains, IA en complément. Héberger ou rejoindre.", "", ""),
        ("01", "Partie classique", "Vous + 1 à 3 IA. Premier à 120 de réputation. Terrain aménageable.", "assets/logos/zoolife_embleme.png", "on"),
        ("02", "Réserve naturelle", "Mêmes rivaux, terrain tel quel : trouvez les motifs déjà présents.", "assets/especes/girafe.png", ""),
        ("03", "Gestion libre", "Seul, sans fin. Naissances et livre d'or.", "assets/especes/capybara.png", ""),
    ]
    onglets = {"06": "DÉFIS", "04": "JOUER À PLUSIEURS", "01": "JOUER", "02": "JOUER", "03": "JOUER"}
    h = []
    for num, t, p, ill, cls in cartes:
        if cls == "sem":
            h.append(f'''<div class="chemise sem" style="border-color:var(--encre);box-shadow:0 4px 0 var(--encre),0 0 0 4px var(--jaune)"><div class="onglet" style="background:var(--jaune)">DÉFIS · NOUVEAU CHAQUE LUNDI</div>
<h3>{t}</h3><div style="margin-top:6px"><span class="pastille mode-rn"><i class="forme f-rond" style="background:var(--pos)"></i>Réserve naturelle</span></div>
<div class="mono" style="font-size:20px;margin-top:8px">3 j 03 h 14</div><div class="petit t2" style="font-weight:600">rang 14<sup>e</sup> sur 52</div>
<img class="ill vign" src="{ill}" style="width:76px;height:76px" alt=""></div>''')
            continue
        if num == "04":
            img = '<div class="ill" style="display:grid;grid-template-columns:1fr 1fr;gap:6px;width:70px;height:70px">' + "".join(
                f'<i class="forme {f}" style="width:30px;height:30px;background:{c};border:2px solid var(--encre)"></i>' for c, f in
                [("var(--j1)", "f-rond"), ("var(--j2)", "f-carre"), ("var(--j3)", "f-carre"), ("var(--j4)", "f-rond")]) + "</div>"
        else:
            img = f'<img class="ill" src="{ill}" alt="">' if ill else ""
            if ill.startswith("assets/cartes"):
                img = f'<img class="ill vign" src="{ill}" style="width:76px;height:76px" alt="">'
        h.append(f'<div class="chemise {cls}"><div class="onglet">{onglets[num]}</div><h3>{t}</h3><p>{p}</p>{img}</div>')
    corps = f'''<img class="fond" src="assets/menu_fond.jpg" alt="">
<div class="dev">DÉV. ▾</div>
<div class="couvB">
<div style="display:flex;justify-content:space-between" class="surtitre"><span>RAPPORT ANNUEL</span><span>EXERCICE 2026</span></div>
<img class="logo" src="assets/logos/zoolife.png" style="width:220px;margin:8px auto 0;display:block" alt="">
<div class="slogan">Bâtissez le zoo le plus rentable de la vallée,<br>avec le personnel que vous méritez.</div>
<div class="reprise" style="margin-top:18px;flex-direction:column;align-items:stretch;gap:6px"><div class="entete" style="color:var(--encre)">DOSSIER EN COURS</div>
<div style="font:600 13px Barlow">Partie classique · <span class="mono">Jour 6</span> · 4 joueurs · il y a 2 h</div><div class="btn p" style="height:40px">Continuer ›</div></div>
<div class="sommaire listeB" style="margin-top:22px"><div class="entete" style="color:var(--encre);letter-spacing:.1em">ANNEXES</div>
{toc("01", "Tutoriel", "avec Hubert")}{toc("02", "Règles et glossaire", "")}{toc("03", "Statistiques", "Daniel")}{toc("04", "Réglages", "")}{toc("05", "Quitter", "retour au bureau")}</div>
<div class="pied"><div class="citation">« La pause est un état d'esprit. » H. de la Marge</div>
<div class="bas"><span>Document réservé aux collaborateurs</span><span class="tampon" style="font-size:13px;padding:2px 8px">CONFIDENTIEL</span></div></div>
</div>
<div class="chemises">{"".join(h)}</div>
<div class="languette" style="left:630px;top:368px;width:80px;height:66px;border-left:2.5px solid var(--encre);border-right:2.5px solid var(--encre)"></div>
<div class="reglagesB panneau"><div class="tete"><span>Partie classique · réglages</span><span class="mono">~14 jours</span></div>
<div class="corps" style="display:grid;grid-template-columns:300px 280px 1fr;gap:28px;padding:6px 20px 20px">
<div><div class="fiche" style="position:static;width:auto"><div class="lab">Adversaires</div></div><div class="seg"><div>1</div><div>2</div><div class="on">3</div></div>{rivaux()}
<div class="fiche" style="position:static;width:auto"><div class="lab">Difficulté</div></div><div class="seg"><div>Facile</div><div class="on">Moyen</div><div>Difficile</div></div></div>
<div class="fiche" style="position:static;width:auto">{bloc_carte(54953)}</div>
<div style="display:flex;flex-direction:column;justify-content:flex-end;gap:12px"><div class="regles memo" style="border:2px solid var(--encre);border-radius:8px">
<p>Premier à <b class="mono">120</b> de réputation. Le terrain s'aménage : creuser, planter, dérocher.</p>
<div class="chips"><span class="pastille mode-cl"><i class="forme f-triangle" style="background:var(--orange)"></i>Terrain aménageable</span></div></div>
<div class="btn p grand">Signer la prise de poste ›</div>
<div class="note-rem"><i class="forme f-triangle" style="background:var(--neg)"></i>Remplacera le dossier en cours (jour 6).</div></div>
</div></div>'''
    return page("Menu — variante B", corps, CSS_B)


def ecrire(nom, html):
    open(os.path.join(ICI, nom + ".html"), "w").write(html)


if __name__ == "__main__":
    ecrire("10A_menu_chapitres", menu_A("Menu A — sans sauvegarde", "classique", False))
    ecrire("10B_menu_chemises", menu_B())
    ecrire("10A2_menu_sauvegarde", menu_A("Menu A — avec sauvegarde", "continuer", True))
    ecrire("10A3_menu_gestion_libre", menu_A("Menu A — gestion libre", "libre", False))
    ecrire("10A4_menu_reserve", menu_A("Menu A — réserve naturelle", "reserve", False))
    print("menu ok")
