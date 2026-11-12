"""Maquettes de la page Statistiques (« Dossier personnel ») : premier lancement, puis joueur régulier en 4 onglets."""
import json, os, random
from gen_menu import ecrire

ICI = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(ICI, "donnees.json")))

CSS = """
.kpi { background: #fff; border: 2px solid var(--encre); border-radius: 10px; box-shadow: 0 4px 0 var(--encre); padding: 12px 14px; height: 108px; }
.kpi .v { font: 600 38px/1 'IBM Plex Mono'; }
.kpi .l { font: 800 13px 'Barlow Condensed'; letter-spacing: .07em; text-transform: uppercase; margin-top: 6px; }
.kpi .d { font: 600 12px Barlow; color: var(--texte2); margin-top: 3px; }
.champs { display: grid; grid-template-columns: 116px 1fr; row-gap: 9px; margin-top: 14px; font: 600 14px Barlow; }
.champs .k { font: 600 11px 'IBM Plex Mono'; color: var(--texte2); letter-spacing: .04em; padding-top: 2px; }
.photo { width: 96px; height: 118px; border: 2px solid var(--encre); border-radius: 6px; background: var(--sarcelle-cl); display: flex; align-items: flex-end; justify-content: center; overflow: hidden; }
.leg { display: flex; align-items: center; gap: 6px; font: 600 12px Barlow; }
.leg b { font-family: 'IBM Plex Mono'; margin-left: auto; }
.tuile { position: relative; width: 50px; height: 50px; border: 2px solid var(--encre); border-radius: 8px; background: #fff; display: flex; align-items: center; justify-content: center; }
.tuile img { width: 42px; height: 42px; object-fit: contain; }
.tuile.non { background: #E9ECEF; border-style: dashed; border-color: #8C96A2; }
.tuile.non img { filter: brightness(0); opacity: .22; }    /* Godot : modulate (0,0,0,0.22) */
.tuile .r { position: absolute; right: -5px; top: -5px; width: 15px; height: 15px; border: 1.5px solid var(--encre); }
.portrait { width: 52px; height: 66px; border: 2px solid var(--encre); border-radius: 6px; overflow: hidden; background: var(--memo); }
.portrait img { width: 100%; height: 100%; object-fit: cover; object-position: top; }
.portrait.non { background: #E9ECEF; border-style: dashed; border-color: #8C96A2; }
.portrait.non img { filter: brightness(0); opacity: .2; }
.medaille { position: relative; width: 70px; height: 84px; flex: none; }
.medaille .rub { position: absolute; top: 46px; width: 18px; height: 34px; background: var(--sarcelle); border: 2px solid var(--encre); }
.medaille .rond { position: absolute; left: 3px; top: 0; width: 64px; height: 64px; border-radius: 50%; border: 3px solid var(--encre); background: var(--jaune);
  display: flex; align-items: center; justify-content: center; font: 700 20px 'IBM Plex Mono'; box-shadow: inset 0 0 0 5px #FFE08A; }
.medaille.non .rond { background: var(--papier2); border-style: dashed; border-color: #8C96A2; color: #8C96A2; box-shadow: none; }
.medaille.non .rub { background: #D5D9DE; border-color: #8C96A2; }
.succes { display: flex; gap: 12px; align-items: flex-start; background: #fff; border: 2px solid var(--encre); border-radius: 10px; box-shadow: 0 4px 0 var(--encre); padding: 14px 12px; height: 146px; }
.succes.non { box-shadow: none; border-style: dashed; border-color: #8C96A2; background: var(--papier2); }
.succes h4 { margin: 0; font: 800 19px/1.05 'Barlow Condensed'; text-transform: uppercase; }
.succes p { margin: 4px 0 0; font: 600 13px/1.3 Barlow; color: var(--texte2); }
.succes .st { margin-top: 8px; font: 700 12px Barlow; display: flex; align-items: center; gap: 6px; }
.mission { background: #fff; border: 2px solid var(--encre); border-radius: 10px; box-shadow: 0 4px 0 var(--encre); padding: 14px; display: flex; flex-direction: column; gap: 8px; }
.mission .num { font: 600 12px 'IBM Plex Mono'; color: var(--texte2); }
.mission h4 { margin: 0; font: 800 22px/1 'Barlow Condensed'; text-transform: uppercase; }
"""

MODES = [  # nom, forme, couleur, parties, victoires, plus rapide, record, moyenne, ouverture, ouverture IA
    ("Partie classique", "f-triangle", "var(--orange)", 24, 15, "jour 9", 148, 112, "5,4", "6,1"),
    ("Réserve naturelle", "f-rond", "var(--pos)", 11, 5, "jour 11", 131, 98, "6,2", "6,3"),
    ("Gestion libre", "f-carre", "var(--marine)", 6, None, "—", 186, 140, "4,8", "—"),
    ("Défis", "f-losange", "var(--bleu)", 8, 5, "jour 10", 151, 118, "6,0", "6,3"),
    ("Multijoueur", "f-etoile", "var(--j4)", 3, 1, "jour 13", 122, 104, "5,7", "6,0"),
]
SOURCES = [("Fréquentation", 41, "#13867F"), ("Spectacles", 15, "#F0A020"), ("Boutique", 11, "#3A6AE0"), ("Objectifs", 10, "#E04A8A"),
           ("Beauté du parc", 8, "#8FB86A"), ("Labels", 7, "#8A6400"), ("Prestige politique", 5, "#2E4256"), ("Collaborateurs légendaires", 3, "#B5452A")]
SUCCES = [
    ("Première concession", "Gagner une partie.", "1er", "obtenu le 14/09"),
    ("Garde forestier", "Gagner en Réserve naturelle.", "RN", "obtenu le 21/09"),
    ("Promotion éclair", "Gagner avant le jour 10.", "J9", "obtenu le 30/10 · jour 9"),
    ("Portes ouvertes", "Ouvrir son zoo au jour 3 ou avant.", "J3", "obtenu le 05/10"),
    ("Le terrain tel qu'il est", "Gagner une course sans Terrassier ni Paysagiste.", "T0", None),
    ("Spécialiste", "4 espèces du même continent.", "4×", "obtenu le 28/09"),
    ("Tour du monde", "4 continents dans un même zoo.", "4C", "obtenu le 12/10"),
    ("Heureux événement", "2 petits chez un même animal.", "+2", "obtenu le 02/11"),
    ("Actionnaire satisfait", "100 de réputation dans un défi.", "100", "obtenu le 12/11"),
    ("Collectionneur", "Installer 10 espèces différentes.", "10", "obtenu le 08/10"),
    ("Arche de ZooLife", "Installer toutes les espèces.", "40", (27, 40, "espèces")),
    ("Légende vivante", "Un collaborateur au niveau 6.", "N6", (5, 6, "niveau max atteint")),
]
r = random.Random(7)
PARTIES = []
modes_cycle = ["Classique", "Réserve", "Défi", "Classique", "Libre", "Classique", "Réserve", "Défi", "Multi", "Classique"] * 2
for i in range(20):
    m = modes_cycle[i]
    rang = 1 if r.random() < .55 else r.choice([2, 2, 3, 4])
    rep = r.randint(120, 151) if rang == 1 else r.randint(78, 119)
    if m == "Libre":
        rang, rep = None, r.randint(130, 186)
    PARTIES.append((f"{12 - i // 2:02d}/11" if i < 20 else "", m, rang, r.randint(9, 15), rep, r.randint(3, 8)))
PARTIES[0] = ("12/11", "Défi", 1, 10, 151, 5)
FORME = {"Classique": ("f-triangle", "var(--orange)"), "Réserve": ("f-rond", "var(--pos)"), "Libre": ("f-carre", "var(--marine)"),
         "Défi": ("f-losange", "var(--bleu)"), "Multi": ("f-etoile", "var(--j4)")}


def cadre(onglet, contenu, vierge=False):
    ong = [("resume", "Résumé", ""), ("parties", "Parties", "52" if not vierge else "0"), ("collection", "Collection", "27/40" if not vierge else "0/40"),
           ("succes", "Succès", "9/12" if not vierge else "0/12")]
    o = "".join(f'<div class="{"on" if k == onglet else ""}">{n}{f" <span class=mono>{c}</span>" if c else ""}</div>' for k, n, c in ong)
    return f'''<img class="fond" src="assets/fond_menu.png" alt=""><div class="voile"></div>
<div class="fenetre"><div class="haut"><div class="surtitre">DOSSIER PERSONNEL · CONFIDENTIEL RH</div><div class="titre" style="margin-top:4px">Statistiques</div>
<div class="onglets">{o}</div><div class="fermer">×</div></div>
<div style="position:relative;padding:20px;height:619px">{contenu}</div></div>'''


def fiche_signal(vierge):
    if vierge:
        champs = [("PSEUDO", 'Daniel <span class="btn mini" style="margin-left:8px;height:24px">Modifier</span>'), ("MATRICULE", '<span class="mono">ZL-2026-0042</span>'),
                  ("EN POSTE DEPUIS", '<span class="mono">12/11/2026</span>'), ("PARTIES", '<span class="mono">0</span>'), ("GRADE", "Stagiaire")]
        tampon = '<span class="tampon vert" style="position:absolute;right:14px;top:22px;font-size:12px;padding:2px 7px">PÉRIODE D\'ESSAI</span>'
    else:
        champs = [("PSEUDO", 'Daniel <span class="btn mini" style="margin-left:8px;height:24px">Modifier</span>'), ("MATRICULE", '<span class="mono">ZL-2026-0042</span>'),
                  ("EN POSTE DEPUIS", '<span class="mono">14/09/2026</span>'), ("PARTIES", '<span class="mono">52</span> · 2 mois'), ("GRADE", "Directeur adjoint")]
        tampon = '<span class="tampon vert" style="position:absolute;right:14px;top:22px;font-size:12px;padding:2px 7px">ÉVALUATION : CONFORME</span>'
    ch = "".join(f'<div class="k">{k}</div><div>{v}</div>' for k, v in champs)
    return f'''<div class="panneau" style="position:absolute;left:20px;top:20px;width:330px;height:372px"><div class="tete encre"><span>Fiche signalétique</span><span class="mono" style="color:var(--jaune)">RÉF. 0042</span></div>
<div class="corps" style="position:relative"><div style="display:flex;gap:14px;align-items:flex-end"><div class="photo"><img src="assets/logos/zoolife_embleme.png" style="width:88px" alt=""></div>
<div><div class="cond" style="font-size:30px;line-height:1">DANIEL</div><div class="petit t2" style="font-weight:600;margin-top:4px">Cadre ZooLife™<br>filiale de la vallée</div></div></div>
{tampon}<div class="champs">{ch}</div></div></div>'''


def hubert(txt, top=410, humeur="moqueur"):
    return f'''<div class="hubert" style="position:absolute;left:20px;top:{top}px;width:330px;flex-direction:column;align-items:flex-start;gap:6px">
<div class="bulle">« {txt} »</div><div style="display:flex;align-items:center;gap:8px"><img src="assets/hubert/{humeur}.png" style="width:60px;height:60px" alt="">
<span class="petit t2" style="font-weight:700">Hubert de la Marge<br><span style="font-weight:600">votre supérieur</span></span></div></div>'''


def courbe(w, h, n=20, grand=False):
    pts = list(reversed(PARTIES[:n]))
    x0, y0, x1, y1 = 34, 10, w - 10, h - 24
    def X(i): return x0 + (x1 - x0) * i / (n - 1)
    def Y(v): return y1 - (y1 - y0) * (v - 60) / 100   # axe de 60 à 160
    poly = " ".join(f"{X(i):.1f},{Y(p[4]):.1f}" for i, p in enumerate(pts))
    pp = []
    for i, p in enumerate(pts):
        f, c = FORME[p[1]]
        gagne = p[2] == 1
        rr = 6 if grand else 5
        if gagne:
            pp.append(f'<circle cx="{X(i):.1f}" cy="{Y(p[4]):.1f}" r="{rr}" fill="#13867F" stroke="#14202B" stroke-width="2"/>')
        else:
            pp.append(f'<circle cx="{X(i):.1f}" cy="{Y(p[4]):.1f}" r="{rr}" fill="#fff" stroke="#14202B" stroke-width="2"/>')
    return f'''<svg width="{w}" height="{h}" style="display:block">
<line x1="{x0}" y1="{Y(60)}" x2="{x1}" y2="{Y(60)}" stroke="#14202B" stroke-width="2"/>
<line x1="{x0}" y1="{Y(120)}" x2="{x1}" y2="{Y(120)}" stroke="#14202B" stroke-width="1.5" stroke-dasharray="6 5"/>
<text x="{x0-6}" y="{Y(120)+4}" text-anchor="end" font-family="IBM Plex Mono" font-weight="600" font-size="11" fill="#3D4752">120</text>
<text x="{x0-6}" y="{Y(60)+4}" text-anchor="end" font-family="IBM Plex Mono" font-weight="600" font-size="11" fill="#3D4752">60</text>
<polyline points="{poly}" fill="none" stroke="#13867F" stroke-width="2.5"/>{"".join(pp)}
<text x="{x0}" y="{h-6}" font-family="IBM Plex Mono" font-weight="600" font-size="11" fill="#3D4752">il y a {n} parties</text>
<text x="{x1}" y="{h-6}" text-anchor="end" font-family="IBM Plex Mono" font-weight="600" font-size="11" fill="#3D4752">dernière</text></svg>'''


def legende_courbe():
    return '''<div style="display:flex;gap:14px;font:600 12px Barlow" class="t2"><span style="display:flex;gap:5px;align-items:center"><i class="forme f-rond" style="background:var(--sarcelle);border:2px solid var(--encre);width:11px;height:11px"></i>victoire</span>
<span style="display:flex;gap:5px;align-items:center"><i class="forme f-rond" style="background:#fff;border:2px solid var(--encre);width:11px;height:11px"></i>défaite</span>
<span style="display:flex;gap:5px;align-items:center"><i style="width:16px;border-top:2px dashed var(--encre)"></i>objectif 120</span></div>'''


def sources_bar(w):
    segs = "".join(f'<i style="width:{v}%;background:{c};border-right:2px solid #14202B;display:flex;align-items:center;justify-content:center;font:700 11px \'IBM Plex Mono\';color:#fff">{v if v >= 8 else ""}</i>' for n, v, c in SOURCES)
    leg = "".join(f'<div class="leg"><i class="forme f-carre" style="background:{c};border:1.5px solid var(--encre)"></i>{n}<b>{v} %</b></div>' for n, v, c in SOURCES)
    return f'''<div style="display:flex;height:26px;border:2px solid var(--encre);border-radius:6px;overflow:hidden">{segs}</div>
<div style="display:grid;grid-template-columns:1fr 1fr;gap:6px 26px;margin-top:12px">{leg}</div>'''


def resume():
    kpis = [("26", "Victoires", "57 % des 46 parties disputées"), ("151", "Réputation record", "Défi · Le delta sauvage, 12/11"),
            ("J9", "Victoire la plus rapide", "Partie classique, 30/10"), ("5,6", "Ouverture du zoo", '<span style="color:var(--pos)">▲ 0,5 jour plus tôt que les IA</span>')]
    k = "".join(f'<div class="kpi"><div class="v">{v}</div><div class="l">{l}</div><div class="d">{d}</div></div>' for v, l, d in kpis)
    rows = "".join(f'''<tr><td><span style="display:flex;align-items:center;gap:8px"><i class="forme {f}" style="background:{c}"></i>{n}</span></td><td class="n">{p}</td>
<td style="width:150px">{'<div style="display:flex;align-items:center;gap:8px"><div class="barre" style="flex:1"><i style="width:%d%%"></i></div><span class="mono" style="width:38px;text-align:right">%d %%</span></div>' % (round(v/p*100), round(v/p*100)) if v is not None else '<span class="t2">sans objet</span>'}</td>
<td class="n">{rec}</td></tr>''' for n, f, c, p, v, rap, rec, moy, o, oi in MODES)
    contenu = f'''{fiche_signal(False)}{hubert("Votre taux de victoire progresse. Votre salaire, lui, reste un modèle de stabilité.")}
<div style="position:absolute;left:370px;top:20px;width:870px;display:grid;grid-template-columns:repeat(4,1fr);gap:12px">{k}</div>
<div class="panneau" style="position:absolute;left:370px;top:144px;width:500px;height:236px"><div class="tete"><span>Par mode de jeu</span><span class="mono">détail : onglet Parties</span></div>
<div class="corps" style="padding:10px 6px 0"><table class="t"><tr><th>Mode</th><th class="n">Parties</th><th>Victoires</th><th class="n">Record</th></tr>{rows}</table></div></div>
<div class="panneau" style="position:absolute;left:882px;top:144px;width:358px;height:236px"><div class="tete"><span>Réputation finale</span><span class="mono">20 dernières</span></div>
<div class="corps" style="padding:8px 10px 0">{courbe(334, 150)}{legende_courbe()}</div></div>
<div class="panneau" style="position:absolute;left:370px;top:394px;width:500px;height:205px"><div class="tete"><span>D'où vient votre réputation</span><span class="mono">toutes parties</span></div>
<div class="corps" style="padding:12px 14px">{sources_bar(470)}</div></div>
<div class="panneau" style="position:absolute;left:882px;top:394px;width:358px;height:205px"><div class="tete"><span>Collection et succès</span></div>
<div class="corps" style="display:flex;flex-direction:column;gap:11px">
{"".join(f'<div><div style="display:flex;justify-content:space-between;font:700 13px Barlow"><span>{n}</span><span class="mono">{a}/{b}</span></div><div class="barre" style="margin-top:4px"><i style="width:{a/b*100:.0f}%"></i></div></div>' for n, a, b in [("Espèces installées", 27, 40), ("Collaborateurs recrutés", 31, 40), ("Succès", 9, 12)])}
<div style="display:flex;align-items:center;gap:8px;font:600 12px Barlow" class="t2"><i class="forme f-etoile" style="background:var(--jaune)"></i><span>Dernier succès : <b style="color:var(--encre)">Actionnaire satisfait</b>, aujourd'hui</span></div></div></div>'''
    return cadre("resume", contenu)


def parties():
    rows = "".join(f'''<tr><td><span style="display:flex;align-items:center;gap:8px"><i class="forme {f}" style="background:{c}"></i><b>{n}</b></span></td><td class="n">{p}</td>
<td class="n">{v if v is not None else "—"}</td><td class="n">{str(round(v/p*100)) + " %" if v is not None else "—"}</td><td class="n">{rap}</td><td class="n">{rec}</td><td class="n">{moy}</td>
<td class="n">jour {o} <span class="t2" style="font-weight:600">· IA {oi}</span></td></tr>''' for n, f, c, p, v, rap, rec, moy, o, oi in MODES)
    rang = lambda x: "—" if x is None else (f'<b style="color:var(--pos)">1<sup>er</sup></b> / 4' if x == 1 else f'{x}<sup>e</sup> / 4')
    lp = "".join(f'''<tr{' style="background:var(--jaune-cl)"' if i == 0 else ''}><td class="n" style="text-align:left">{d}</td><td><span style="display:flex;align-items:center;gap:7px"><i class="forme {FORME[m][0]}" style="background:{FORME[m][1]}"></i>{m}</span></td>
<td class="n">{rang(rg)}</td><td class="n">j{fin}</td><td class="n">{rep}</td><td class="n">{z}</td></tr>''' for i, (d, m, rg, fin, rep, z) in enumerate(PARTIES[:8]))
    contenu = f'''<div class="panneau" style="position:absolute;left:20px;top:20px;width:1220px;height:232px"><div class="tete"><span>Par mode de jeu</span><span class="mono">52 parties depuis le 14/09/2026</span></div>
<div class="corps" style="padding:10px 6px 0"><table class="t"><tr><th>Mode</th><th class="n">Parties</th><th class="n">Victoires</th><th class="n">Taux</th><th class="n">La plus rapide</th><th class="n">Record</th><th class="n">Moyenne</th><th class="n">Ouverture du zoo</th></tr>{rows}</table></div></div>
<div class="panneau" style="position:absolute;left:20px;top:268px;width:560px;height:331px"><div class="tete"><span>Réputation finale, partie après partie</span><span class="mono">20 dernières</span></div>
<div class="corps" style="padding:10px 12px 0">{courbe(534, 238, grand=True)}{legende_courbe()}</div></div>
<div class="panneau" style="position:absolute;left:596px;top:268px;width:644px;height:331px"><div class="tete"><span>Dernières parties</span><span class="mono">8 sur 20 · défiler</span></div>
<div class="corps" style="padding:8px 18px 0 6px;position:relative"><table class="t"><tr><th>Date</th><th>Mode</th><th class="n">Rang</th><th class="n">Fin</th><th class="n">Réputation</th><th class="n">Animaux</th></tr>{lp.replace('height: 30px','')}</table>
<div style="position:absolute;right:6px;top:8px;width:6px;height:262px;background:var(--filet);border-radius:3px"><div style="height:104px;background:var(--encre);border-radius:3px"></div></div></div></div>'''
    return cadre("parties", contenu, ).replace("table.t td { padding: 0 8px; height: 30px;", "")


RAR = {"T1": ("f-rond", "#C9CFD6", "commun"), "T2": ("f-losange", "var(--bleu)", "peu commun"), "T3": ("f-etoile", "var(--jaune)", "rare")}


def collection():
    vus = set()
    r2 = random.Random(3)
    esp = D["especes"]
    for e in esp:
        if (e["palier"] == "T1" and r2.random() < .9) or (e["palier"] == "T2" and r2.random() < .62) or (e["palier"] == "T3" and r2.random() < .35):
            vus.add(e["id"])
    while len(vus) > 27:
        vus.pop()
    cont = [("Europe", "Europe"), ("Amerique", "Amérique"), ("Asie", "Asie"), ("Afrique", "Afrique")]
    blocs = []
    for cid, cn in cont:
        L = sorted([e for e in esp if e["continent"] == cid], key=lambda e: e["palier"])
        n = sum(1 for e in L if e["id"] in vus)
        tu = "".join(f'''<div class="tuile{"" if e["id"] in vus else " non"}"><img src="assets/especes/{"" if e["id"] in vus else "corps/"}{e["id"]}.png" alt="{e["nom"]}"><i class="r forme {RAR[e["palier"]][0]}" style="background:{RAR[e["palier"]][1]}"></i></div>''' for e in L)
        blocs.append(f'''<div><div style="display:flex;justify-content:space-between;align-items:baseline;border-bottom:2px solid var(--encre);padding-bottom:4px;margin-bottom:10px">
<span class="cond" style="font-size:18px;text-transform:uppercase">{cn}</span><span class="mono">{n}/10</span></div>
<div style="display:grid;grid-template-columns:repeat(5,50px);gap:10px 7px">{tu}</div></div>''')
    r3 = random.Random(5)
    pers = D["perso"]
    recr = set(p["id"] for p in pers if r3.random() < .78)
    while len(recr) > 31:
        recr.pop()
    while len(recr) < 31:
        recr.add(r3.choice(pers)["id"])
    po = "".join(f'<div class="portrait{"" if p["id"] in recr else " non"}"><img src="assets/portraits/{p["id"]}.png" alt="{p["nom"]}"></div>' for p in pers)
    leg = "".join(f'<span style="display:inline-flex;align-items:center;gap:6px;margin-right:16px"><i class="forme {f}" style="background:{c};border:1.5px solid var(--encre)"></i>{n}</span>' for f, c, n in RAR.values())
    # infobulle sur une espèce survolée (2e de l'Asie)
    contenu = f'''<div class="panneau" style="position:absolute;left:20px;top:20px;width:1220px;height:282px"><div class="tete"><span>Espèces installées au moins une fois</span><span class="mono">27 / 40</span></div>
<div class="corps" style="display:grid;grid-template-columns:repeat(4,1fr);gap:26px;padding:14px 22px 0">{"".join(blocs)}</div>
<div style="position:absolute;left:22px;bottom:12px;font:600 12px Barlow" class="t2">{leg}<span style="display:inline-flex;align-items:center;gap:6px"><i class="forme f-carre" style="background:#E9ECEF;border:1.5px dashed #8C96A2"></i>pas encore installée (silhouette)</span></div></div>
<div style="position:absolute;left:968px;top:412px;width:236px;background:var(--encre);color:#fff;border-radius:8px;padding:9px 12px;z-index:4">
<i style="position:absolute;left:92px;top:-7px;width:14px;height:14px;background:var(--encre);transform:rotate(45deg)"></i><div style="font:800 13px 'Barlow Condensed';letter-spacing:.07em;color:var(--jaune);text-transform:uppercase">Panda géant · rare</div>
<div style="font:600 12px/1.3 Barlow;margin-top:3px">Asie · installé 2 fois · dernière le 30/10</div></div>
<div class="panneau" style="position:absolute;left:20px;top:320px;width:1220px;height:279px"><div class="tete"><span>Collaborateurs recrutés</span><span class="mono">31 / 40</span></div>
<div class="corps" style="display:grid;grid-template-columns:repeat(20,52px);gap:14px 6.5px;padding:18px 22px 0">{po}</div>
<div style="position:absolute;left:22px;bottom:12px;font:600 12px Barlow" class="t2">Survol : nom, métier, niveau le plus haut atteint, nombre de parties dans votre équipe.</div></div>'''
    return cadre("collection", contenu)


def medaille(g, ok):
    return f'''<div class="medaille{"" if ok else " non"}"><i class="rub" style="left:14px;transform:rotate(14deg)"></i><i class="rub" style="left:36px;transform:rotate(-14deg)"></i><div class="rond">{g}</div></div>'''


def succes():
    cartes = []
    for nom, cond, g, st in SUCCES:
        ok = isinstance(st, str)
        if ok:
            s = f'<div class="st" style="color:var(--pos)">✓ {st}</div>'
        elif st:
            a, b, lib = st
            s = f'<div class="st t2" style="flex-direction:column;align-items:stretch;gap:4px"><span>{lib} : <b class="mono" style="color:var(--encre)">{a}/{b}</b></span><div class="barre"><i style="width:{a/b*100:.0f}%;background:var(--texte2)"></i></div></div>'
        else:
            s = '<div class="st t2">Pas encore obtenu</div>'
        cartes.append(f'<div class="succes{"" if ok else " non"}">{medaille(g, ok)}<div style="flex:1"><h4>{nom}</h4><p>{cond}</p>{s}</div></div>')
    contenu = f'''<div style="position:absolute;left:20px;top:16px;width:1220px;display:flex;align-items:center;gap:16px">
<div class="cond" style="font-size:22px">9 SUCCÈS SUR 12</div><div class="barre" style="width:300px;height:12px"><i style="width:75%"></i></div>
<span class="petit t2" style="font-weight:600">Les succès obtenus sont pleins et cochés ; les autres sont en pointillé, avec leur condition.</span></div>
<div style="position:absolute;left:20px;top:58px;width:1220px;display:grid;grid-template-columns:repeat(4,1fr);gap:16px 14px">{"".join(cartes)}</div>
<div class="hubert" style="position:absolute;left:20px;top:538px;align-items:center"><img src="assets/hubert/neutre.png" style="width:56px;height:56px" alt="">
<div class="bulle">« Le plus proche : <b>Légende vivante</b>. Un collaborateur de niveau 5 attend sa promotion. Moi aussi, d'ailleurs. »</div></div>'''
    return cadre("succes", contenu)


def vierge():
    missions = [
        ("01", "Suivre le tutoriel", "Hubert vous montre comment recruter, construire et ouvrir votre zoo. 15 minutes.", "Commencer ›", "p"),
        ("02", "Signer une première partie", "Une partie classique contre une IA en Facile. Premier à 120 de réputation.", "Jouer ›", ""),
        ("03", "Tenter le défi de la semaine", "La même partie pour tous. Votre score entre au classement.", "Voir le défi ›", ""),
    ]
    mi = "".join(f'<div class="mission"><div class="num">MISSION {n}</div><h4>{t}</h4><div style="font:600 14px/1.35 Barlow;flex:1" class="t2">{d}</div><div class="btn {c}" style="align-self:flex-start">{b}</div></div>' for n, t, d, b, c in missions)
    sil = "".join(f'<div class="tuile non"><img src="assets/especes/corps/{e["id"]}.png" alt=""></div>' for e in D["especes"][::4])
    meds = "".join(f'<div style="display:flex;flex-direction:column;align-items:center;gap:4px;width:98px">{medaille(g, False)}<span class="petit t2" style="font-weight:700;text-align:center;line-height:1.15">{n}</span></div>' for n, c, g, s in SUCCES[:3])
    contenu = f'''{fiche_signal(True)}{hubert("Un dossier vide est un dossier sans faute. Profitez-en, ça ne durera pas.", humeur="content")}
<div style="position:absolute;left:370px;top:20px;width:870px">
<div class="surtitre">ÉVALUATION ANNUELLE · AUCUNE DONNÉE</div>
<div class="cond" style="font-size:36px;line-height:1.05;margin-top:4px">Votre dossier est encore vierge.</div>
<div style="font:600 15px Barlow;margin-top:6px" class="t2">Chaque partie le remplit : records, courbes, espèces découvertes, succès. Trois façons de commencer :</div>
<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin-top:16px;height:200px">{mi}</div></div>
<div class="panneau" style="position:absolute;left:370px;top:330px;width:500px;height:269px"><div class="tete"><span>Collection à découvrir</span><span class="mono">0 / 40</span></div>
<div class="corps"><div style="display:grid;grid-template-columns:repeat(5,54px);gap:10px 12px;justify-content:center">{sil}</div>
<div style="font:600 13px Barlow;margin-top:12px;text-align:center" class="t2">40 espèces sur 4 continents. Chaque espèce installée apparaît ici.</div></div></div>
<div class="panneau" style="position:absolute;left:882px;top:330px;width:358px;height:269px"><div class="tete"><span>Succès à obtenir</span><span class="mono">0 / 12</span></div>
<div class="corps" style="display:flex;flex-wrap:wrap;gap:10px 4px;justify-content:center">{meds}<div class="petit t2" style="font-weight:600;text-align:center;margin-top:6px;line-height:1.35">+ 9 autres, jusqu'à <b style="color:var(--encre)">Arche de ZooLife</b> :<br>installer les 40 espèces.</div></div></div>'''
    return cadre("resume", contenu, vierge=True)


def page(titre, corps):
    return f"""<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><title>{titre}</title>
<link rel="stylesheet" href="commun.css"><style>{CSS}</style></head>
<body><div class="ecran">
{corps}
</div></body></html>
"""


if __name__ == "__main__":
    ecrire("20_stats_premier_lancement", page("Statistiques — premier lancement", vierge()))
    ecrire("21_stats_resume", page("Statistiques — résumé", resume()))
    ecrire("22_stats_parties", page("Statistiques — parties", parties()))
    ecrire("23_stats_collection", page("Statistiques — collection", collection()))
    ecrire("24_stats_succes", page("Statistiques — succès", succes()))
    print("stats ok")
