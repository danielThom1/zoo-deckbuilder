class_name Aide
extends ColorRect
## Écran d'aide : tutoriel (comment se déroule une partie, comment gagner de la réputation) et glossaire de tout ce qui
## existe dans le jeu, généré depuis les fichiers de données. S'ouvre depuis le menu principal et le bouton « ? » en jeu.

const PAGES := [
	["Le but du jeu", """Vous bâtissez un zoo pour ZooLife™, en concurrence avec d'autres groupes. [b]Le premier à 120 de réputation l'emporte[/b] (sinon, le mieux placé au soir du jour 22).

Vos collaborateurs sont des [b]cartes[/b] : vous en choisissez 8 au début, vous en piochez 4 chaque matin, vous les envoyez travailler, puis ils repartent à la défausse. Une partie alterne [b]les jours[/b], en temps réel, où l'on récolte et construit, et [b]les nuits[/b], au tour par tour, où l'on achète."""],
	["Le draft", """Avant le premier jour, à chaque tour, une carte de plus que de joueurs est révélée et chacun en prend une à tour de rôle, pendant 8 tours. C'est votre deck de départ.

[b]Peu qualifiés[/b] : bon marché, un seul talent.
[b]Qualifiés[/b] : plus efficaces, souvent le seul moyen d'aménager le terrain (Paysagiste, Terrassier).
[b]Cadres[/b] : mauvais à la tâche, mais ils se mobilisent pour leur capacité ou se [b]jouent[/b] pour un effet immédiat.

Survolez une carte pour voir son métier et ses traits."""],
	["Le jour", """Chaque journée commence [b]en pause[/b] : préparez vos ordres, puis lancez le temps (Espace).

[b]Mobiliser[/b] une carte paie son salaire et la pose sur le camp. Plus d'argent ? Le bouton +4 d'une carte cède sa journée : elle ne travaille pas et part à la défausse.
[b]Clic droit[/b] avec un collaborateur sélectionné : couper du bois, extraire la pierre, construire, tenir un poste. [b]Maj + clic droit[/b] enchaîne un ordre après le précédent.

Le bois et la pierre récoltés s'échangent contre de l'argent à la Bourse des ressources, à droite. Un Marchand mobilisé vend mieux."""],
	["Ouvrir son zoo", """Pour accueillir des visiteurs, il faut trois choses :
1. Une [b]enceinte fermée[/b] avec une [b]entrée[/b] (touche R pour la tourner). Les montagnes servent de mur, et les murs se construisent sur l'eau.
2. Une [b]route[/b] de l'Accès jusqu'à l'entrée.
3. Au moins [b]un animal[/b] arrivé dans l'enceinte.

Placez ensuite quelqu'un au [b]guichet[/b] (clic droit sur l'entrée) : sans lui, les visiteurs attendent dehors."""],
	["Installer un animal", """Achetez un [b]contrat[/b] la nuit, puis installez l'animal dans un enclos fermé de clôtures. Le mur d'enceinte et les montagnes comptent comme côté.

Chaque espèce demande une taille d'enclos et un [b]motif de terrain[/b], à reproduire tel quel, tourné ou retourné. Les Paysagistes et les Terrassiers transforment les cases (onglet Terrain). Certaines espèces exigent aussi un [b]aménagement[/b] (Grand arbre, Rocher, Bassin, Abri).

Cliquez dans le parc sans enclos : un enclos est posé en chantier autour de la case et l'animal y est réservé. Il arrive la nuit qui suit la fin des travaux.

Un animal doit manger (Cuisine) et peut tomber malade : un Soigneur le guérit, sinon il se remet seul au bout de 2 nuits, mais il n'attire personne en attendant."""],
	["Gagner de la réputation", """[b]Fréquentation[/b] : la source principale, selon le nombre moyen de visiteurs présents. L'attractivité des animaux et la publicité amènent les visiteurs ; le zoo doit rester propre.
[b]Affinités[/b] : plusieurs espèces d'un même continent multiplient cette réputation (2 → +10 %, 3 → +25 %, 4 → +45 %, 5 → +70 %, 6 → +100 %).
[b]Spectacles et boutique[/b] : un Kiosque tenu et les souvenirs vendus en rapportent aussi.
[b]Objectifs des actionnaires[/b] : 3 objectifs, les mêmes pour tous, affichés dans le panneau du zoo. Chacun rapporte +10 de réputation à tous ceux qui le remplissent.
[b]Prestige politique[/b] : chaque nuit, le premier en influence gagne +3, le deuxième +1.
[b]Labels[/b] : achetés en or, zoo ouvert, à la Bourse des ressources. Le prix double sans Marchand mobilisé.
[b]Collaborateurs légendaires[/b] : +5 quand un collaborateur atteint le niveau 6."""],
	["La nuit", """La nuit se joue en écrans successifs, chacun à son tour selon l'influence :
1. [b]Contrats[/b] : un seul par tour. Un contrat pris n'est remplacé que le lendemain.
2. [b]Collaborateurs[/b] : une embauche, s'il reste un logement (une Maison = une place).
3. [b]Cartes d'action[/b] : une carte, à usage unique.
4. [b]Bonus[/b] : le premier en influence choisit le bonus de demain, valable pour tous, ou aucun.
5. [b]Équipe[/b] : montées de niveau, amélioration ou licenciement.

Le lobbying (envoyer un collaborateur à la case Accès) fait monter votre influence, donc votre ordre de passage."""],
	["Choisir un plan de jeu", """Plusieurs routes mènent à la victoire :
[b]Un continent[/b] : Europe, Amérique, Asie ou Afrique, pour de grosses affinités. Chacun a deux animaux [b]rares[/b], très chers, aux effets puissants.
[b]L'or[/b] : mine et entrepôt tôt, Mineurs et Marchand, or vendu ou changé en labels.
[b]Les spectacles[/b] : Kiosque et Animateur, boutiques et Vendeurs.
[b]La politique[/b] : Lobbyistes, prestige et ordre de passage.
[b]La formation[/b] : Formateur sur les chantiers et cartes Formation express, pour des collaborateurs légendaires.

Adaptez-vous à vos cartes et à ce que prennent les autres : tout se voit, la nuit."""],
	["Commandes", """[b]Clic gauche[/b] : sélectionner (glisser pour plusieurs). [b]Clic droit[/b] : donner un ordre. [b]Maj + clic droit[/b] : ordre à la suite.
[b]Ctrl + glisser[/b] : sélectionner des bâtiments. [b]Maj + clic[/b] : en ajouter un. [b]Double-clic[/b] : tout un tracé de clôture. [b]Suppr[/b] : démolir.
[b]R[/b] : tourner le bâtiment à poser. [b]Échap[/b] : annuler. [b]Espace[/b] : pause. [b]1, 2, 3[/b] : vitesse.
[b]Molette[/b] : zoom. [b]ZQSD[/b] ou flèches : déplacer la vue.

La partie est sauvegardée automatiquement chaque matin : « Continuer » au menu reprend au début du dernier jour."""],
]

const RESSOURCES := [
	["Argent", "Paie les salaires, les contrats, les embauches, la nourriture. Vient des billets, des souvenirs et des ventes."],
	["Bois", "Coupé en forêt. Clôtures d'enclos, maisons, de nombreux bâtiments."],
	["Pierre", "Extraite de la roche. Murs d'enceinte, entrée, aménagements."],
	["Or", "Extrait d'un gisement avec une mine. Contrats rares et labels, ou vendu très cher."],
	["Influence", "Gagnée par le lobbying. Fixe l'ordre de passage la nuit (valeurs cachées) et donne le prestige politique."],
	["Réputation", "Le score : le premier à 120 gagne."],
	["Logement", "Nombre maximal de collaborateurs. Le camp en loge 8, chaque Maison un de plus."],
	["Propreté", "Les visiteurs salissent le parc. Sous 60, puis sous 30, moins de visiteurs viennent."],
]
const DESCRIPTIONS := {
	"route": "Relie l'Accès à l'entrée pour les visiteurs ; les collaborateurs y vont deux fois plus vite.", "pont": "Une route sur l'eau.",
	"maison": "Loge un collaborateur de plus.", "entrepot": "Dépôt de ressources : réduit les trajets des récolteurs.",
	"comptoir": "Vente à 70 % sans Marchand ; avec un Marchand, vente à 125 % et achats 30 % moins chers.",
	"agence": "Une fois par jour : envoyez-y un collaborateur (clic droit), puis cliquez sur lui pour le remplacer par une carte de la pioche ou de la défausse.",
	"mine": "Sur un gisement : permet d'extraire de l'or.", "cloture": "Mur de l'enceinte du zoo. Se construit aussi sur l'eau.",
	"entree": "Porte du zoo : un collaborateur y tient le guichet. Touche R pour la tourner.", "enclos": "Ferme les enclos des animaux. Se construit aussi sur l'eau.",
	"boutique": "Tenue par un seul collaborateur : souvenirs (×2,5 avec un Vendeur) et un peu de réputation.",
	"cuisine": "Prépare et livre les rations des animaux.", "entretien": "Un collaborateur y nettoie le parc.",
	"intendance": "Un collaborateur y embellit le parc : chaque décoration se voit sur la carte et rapporte de la réputation chaque nuit (Intendant : 2,5 fois plus vite).",
	"snack": "Tenu par un collaborateur : les visiteurs restent 50 % plus longtemps et dépensent 1 d'argent de plus.", "kiosque": "Tenu par un collaborateur : attractivité et réputation (Animateur ×2).",
	"camp_n2": "Une carte de plus en main.", "camp_n3": "Encore une carte de plus en main.",
}

var data: Dictionary
var corps: VBoxContainer
var scroll: ScrollContainer
var onglets: VBoxContainer
var page := 0


var groupe_onglets := ButtonGroup.new()
var fiche_animal: Control  # fiche de l'animal cliqué, en haut de la page Animaux
const NOMS_TERRAINS := {"Prairie": "Prairie", "Foret": "Forêt", "Eau": "Eau", "Roche": "Roche", "Sable": "Sable"}


func _init(game_data: Dictionary) -> void:
	data = game_data


func _ready() -> void:
	color = Color(0, 0, 0, 0)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiTokens.build_theme()
	var f := Composants.fenetre(Vector2(1440, 800), "Manuel du collaborateur", "Règles et glossaire", queue_free)
	add_child(f["racine"])
	var racine := HBoxContainer.new()
	racine.add_theme_constant_override("separation", 16)
	racine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	f["corps"].add_child(racine)
	var gauche := ScrollContainer.new()
	gauche.custom_minimum_size.x = 270
	gauche.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	racine.add_child(gauche)
	onglets = VBoxContainer.new()
	onglets.add_theme_constant_override("separation", 4)
	onglets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gauche.add_child(onglets)
	var droite := VBoxContainer.new()
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	droite.add_theme_constant_override("separation", 10)
	racine.add_child(droite)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	droite.add_child(scroll)
	corps = VBoxContainer.new()
	corps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 10)
	scroll.add_child(corps)
	_titre_onglet("TUTORIEL")
	for k in PAGES.size():
		_onglet(PAGES[k][0], _montrer_page.bind(k))
	_titre_onglet("GLOSSAIRE")
	for g in [["Ressources", _glossaire_ressources], ["Métiers", _glossaire_metiers], ["Traits", _glossaire_traits],
			["Bâtiments", _glossaire_batiments], ["Terrain", _glossaire_terrain], ["Animaux", _glossaire_animaux],
			["Cartes d'action", _glossaire_actions], ["Labels", _glossaire_labels], ["Événements", _glossaire_evenements], ["Bonus de nuit", _glossaire_bonus]]:
		_onglet(g[0], g[1])
	_montrer_page(page)
	if not groupe_onglets.get_buttons().is_empty():
		groupe_onglets.get_buttons()[page].button_pressed = true


func _titre_onglet(txt: String) -> void:
	onglets.add_child(Composants.titre_section(txt, 13))


func _onglet(txt: String, action: Callable) -> void:
	var b := Composants.bouton(txt, "Onglet")
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 28
	b.add_theme_font_size_override("font_size", 13)
	b.toggle_mode = true
	b.button_group = groupe_onglets
	b.pressed.connect(action)
	onglets.add_child(b)


## Vide le contenu, pose le titre, renvoie un texte riche prêt à remplir.
func _feuille(titre: String) -> RichTextLabel:
	for c in corps.get_children():
		c.queue_free()
	scroll.scroll_vertical = 0
	var t := Composants.label(titre)
	t.add_theme_font_override("font", UiTokens.police_titre())
	t.add_theme_font_size_override("font_size", 28)
	corps.add_child(t)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_size_override("normal_font_size", 16)
	r.add_theme_font_size_override("bold_font_size", 16)
	r.add_theme_color_override("default_color", UiTokens.ENCRE)
	corps.add_child(r)
	return r


func _montrer_page(k: int) -> void:
	_feuille(PAGES[k][0]).text = PAGES[k][1]


func _fois(v: float) -> String:
	return ("×%.2f" % v).trim_suffix("0").trim_suffix("0").trim_suffix(",").replace(".", ",").trim_suffix(",")


func _glossaire_ressources() -> void:
	var L: Array[String] = []
	for r in RESSOURCES:
		L.append("[b]%s[/b] : %s" % [r[0], r[1]])
	var ex: Dictionary = data["buildings"]["extraction"]
	L.append("[b]Récolte[/b] : à rendement ×1, un collaborateur tire d'une case %s bois, %s pierre ou %s or par minute (l'or demande une Mine sur le gisement). Il porte %d unités, puis va les déposer au Camp ou à l'Entrepôt le plus proche : les trajets comptent. Les métiers et les traits multiplient ces chiffres (voir Métiers)." % [
		_nombre(float(ex["bois"])), _nombre(float(ex["pierre"])), _nombre(float(ex["or"])), int(ex["capacite_portage"])])
	_feuille("Ressources").text = "\n\n".join(L)


func _nombre(v: float) -> String:
	return ("%.2f" % v).trim_suffix("0").trim_suffix("0").trim_suffix(".").replace(".", ",")


func _glossaire_metiers() -> void:
	var noms := {"peu_qualifie": "Peu qualifié", "qualifie": "Qualifié", "cadre": "Cadre"}
	var L: Array[String] = []
	for m in data["workers"]["metiers"]:
		var eff: Array[String] = []
		for k in m["efficacite"]:
			if k != "defaut":
				eff.append("%s %s" % [str(k).replace("_", " "), _fois(float(m["efficacite"][k]))])
		var l := "[b]%s[/b] (%s, salaire %d) : rendement %s%s." % [m["nom"], noms[m["categorie"]], int(m["salaire"]),
			_fois(float(m["efficacite"]["defaut"])), (", " + ", ".join(eff)) if not eff.is_empty() else ""]
		if m.has("capacite"):
			l += " " + str(m["capacite"])
		if m.has("jouer"):
			l += "\n    [i]Joué : %s. %s[/i]" % [m["jouer"]["nom"], m["jouer"]["texte"]]
		L.append(l)
	_feuille("Métiers").text = "\n\n".join(L)


func _texte_trait(t: Dictionary) -> String:
	if t.has("texte"):
		return str(t["texte"])
	var noms := {"construire": "construction", "vitesse": "vitesse", "salaire": "salaire", "amenager": "aménagement", "construire_enclos": "clôtures d'enclos", "lobbying": "lobbying"}
	var p: Array[String] = []
	for k in t["effet"]:
		var v := float(t["effet"][k])
		p.append("%s %s" % [noms.get(k, k), ("%+d" % int(v)) if k == "salaire" else _fois(v)])
	return ", ".join(p)


func _glossaire_traits() -> void:
	var L: Array[String] = ["[b]Qualités[/b]"]
	for t in data["workers"]["traits_positifs"]:
		L.append("[b]%s[/b] : %s" % [t["nom"], _texte_trait(t)])
	L.append("\n[b]Défauts[/b]")
	for t in data["workers"]["traits_negatifs"]:
		L.append("[b]%s[/b] : %s" % [t["nom"], _texte_trait(t)])
	_feuille("Traits").text = "\n".join(L)


func _cout(c: Dictionary) -> String:
	if c.is_empty():
		return "gratuit"
	var p: Array[String] = []
	for k in c:
		p.append("%d %s" % [int(c[k]), k])
	return ", ".join(p)


## Postes : peut-on y mettre plusieurs collaborateurs, et que rapporte le second ? (d'après game_state.gd :
## guichet_rate, _update_feed, _sweep, _embellir additionnent ; _shop_mult, snack_mult, kiosque_bonus non).
const POSTES := {
	"entree": "Guichet : plusieurs collaborateurs s'additionnent, chacun fait entrer ses visiteurs (le Guichetier va plus vite).",
	"boutique": "Un seul collaborateur compte par boutique : un second n'ajoute rien. Pour vendre plus, construisez une autre boutique.",
	"cuisine": "Plusieurs collaborateurs s'additionnent : chacun prépare et livre ses rations, donc plus d'animaux sont nourris, plus vite.",
	"entretien": "Plusieurs collaborateurs s'additionnent : le parc se nettoie plus vite.",
	"snack": "Un seul collaborateur suffit : un second n'ajoute rien.",
	"kiosque": "Seul le meilleur animateur présent compte : un second n'ajoute rien.",
	"intendance": "Plusieurs collaborateurs s'additionnent : les décorations se posent plus vite (toujours une pour 10 cases au plus).",
	"mine": "Deux places par filon d'or ; chaque mineur extrait de son côté.",
	"comptoir": "Pas de poste : le Marchand vend où qu'il soit, mieux payé si ce bâtiment existe.",
	"agence": "Pas de poste à tenir.",
	"cabinet": "Pas de poste à tenir.",
	"acquisitions": "Pas de poste à tenir.",
}


func _glossaire_batiments() -> void:
	var L: Array[String] = []
	for b in data["buildings"]["batiments"]:
		if b["id"] == "camp":
			continue
		var d: String = DESCRIPTIONS.get(b["id"], str(b.get("_note_effet", "")))
		var poste: String = ("
[i]Poste :[/i] " + POSTES[b["id"]]) if POSTES.has(b["id"]) else ""
		L.append("[b]%s[/b] (%s, %d s de travail) : %s%s" % [b["nom"], _cout(b.get("cout", {})), int(b["travail"]), d, poste])
	_feuille("Bâtiments").text = "\n\n".join(L)


func _glossaire_terrain() -> void:
	var L: Array[String] = ["Seuls les Paysagistes et les Terrassiers savent transformer le terrain.\n"]
	for a in data["buildings"]["amenagements"]:
		var de = a["de"]
		L.append("[b]%s[/b] (%s, %d s) : %s → %s" % [a["nom"], _cout(a.get("cout", {})), int(a["travail"]), " ou ".join(de) if de is Array else de, a["vers"]])
	_feuille("Terrain").text = "\n".join(L)


func _glossaire_animaux() -> void:
	var conts: Dictionary = data["animals"]["continents"]
	var types: Dictionary = data["animals"]["types"]
	var paliers: Dictionary = data["animals"]["paliers"]
	var L: Array[String] = ["[i]Cliquez sur un animal pour voir le motif de terrain à reproduire.[/i]\n"]
	for c in ["Europe", "Amerique", "Asie", "Afrique"]:
		L.append("[b]%s[/b]" % str(conts[c]).to_upper())
		for pal in ["T3", "T2", "T1"]:
			for a in data["animals"]["animaux"]:
				if a["continent"] != c or a["palier"] != pal:
					continue
				var esp: Array = SpritesBD.ANIMAUX.get(a["id"], [])
				var img := ""
				if not esp.is_empty() and str(esp[2]) != "" and SpritesBD.existe(str(esp[2])):
					img = "[img=44x44]res://assets/bd/sprites/animaux_v2/%s.png[/img] " % str(esp[2])
				var l := "%s[url=%s][b]%s[/b][/url] · %s · %s · %s · attractivité %d · enclos de %d cases" % [img, a["id"], a["nom"], paliers[pal]["nom"], types[a["type"]],
					_cout(a["cout"]), int(a["reputation"]), int(a["taille"])]
				if a.has("decor"):
					l += " + aménagement requis"
				if a.has("effet_texte"):
					l += "\n    [color=#13867F]%s[/color]" % a["effet_texte"]
				L.append(l)
		L.append("")
	var r := _feuille("Animaux")
	r.meta_underlined = false
	r.meta_clicked.connect(func(meta): _fiche_animal(str(meta)))
	r.text = "\n".join(L)


## Fiche d'un animal en haut de la page : son image, ses chiffres et le motif à reproduire, case par case.
func _fiche_animal(id: String) -> void:
	var a: Dictionary = {}
	for x in data["animals"]["animaux"]:
		if x["id"] == id:
			a = x
	if a.is_empty():
		return
	if is_instance_valid(fiche_animal):
		fiche_animal.queue_free()
	var cadre := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color.WHITE
	st.border_color = UiTokens.ENCRE
	st.set_border_width_all(2)
	st.set_corner_radius_all(8)
	st.set_content_margin_all(14)
	cadre.add_theme_stylebox_override("panel", st)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 22)
	cadre.add_child(ligne)
	var esp: Array = SpritesBD.ANIMAUX.get(id, [])
	if not esp.is_empty() and SpritesBD.existe(str(esp[0])):
		var img := TextureRect.new()
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.texture = SpritesBD.texture(str(esp[0]))
		img.custom_minimum_size = Vector2(150, 130)
		ligne.add_child(img)
	var texte := VBoxContainer.new()
	texte.add_theme_constant_override("separation", 6)
	texte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(texte)
	var nom := Composants.label(str(a["nom"]))
	nom.add_theme_font_override("font", UiTokens.police_titre())
	nom.add_theme_font_size_override("font_size", 24)
	texte.add_child(nom)
	var paliers: Dictionary = data["animals"]["paliers"]
	var infos := RichTextLabel.new()
	infos.bbcode_enabled = true
	infos.fit_content = true
	infos.scroll_active = false
	infos.add_theme_font_size_override("normal_font_size", 15)
	infos.add_theme_font_size_override("bold_font_size", 15)
	infos.add_theme_color_override("default_color", UiTokens.ENCRE)
	var compte := {}
	for c in a["motif"]:
		compte[str(c[2])] = int(compte.get(str(c[2]), 0)) + 1
	var parts: Array[String] = []
	for k in compte:
		parts.append("%d %s" % [compte[k], NOMS_TERRAINS.get(k, k)])
	var l: Array[String] = ["%s · %s · %s · %s · attractivité %d" % [paliers[a["palier"]]["nom"], data["animals"]["types"][a["type"]],
		data["animals"]["continents"][a["continent"]], _cout(a["cout"]), int(a["reputation"])]]
	l.append("[b]Motif à reproduire[/b], tel quel, tourné ou retourné : %s, dans un enclos d'au moins %d cases." % [", ".join(parts), int(a["taille"])])
	if a.has("decor"):
		var dnom := str(a["decor"])
		for b in data["buildings"]["batiments"]:
			if b["id"] == a["decor"]:
				dnom = str(b["nom"])
		l.append("[b]En plus[/b] : un %s, bâtiment à poser dans l'enclos (onglet Zoo)." % dnom)
	if a.get("special", "") == "predateur":
		l.append("Prédateur : un enclos à lui seul, toujours clôturé.")
	if a.has("effet_texte"):
		l.append("[color=#13867F]%s[/color]" % a["effet_texte"])
	infos.text = "\n".join(l)
	texte.add_child(infos)
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 22)
	texte.add_child(bas)
	var motif := FenetreComite.MotifLettre.new()
	motif.regler(a, 30.0)
	bas.add_child(motif)
	var legende := VBoxContainer.new()
	legende.add_theme_constant_override("separation", 3)
	for k in ["Prairie", "Foret", "Eau", "Roche", "Sable"]:
		if not compte.has(k):
			continue
		var lg := HBoxContainer.new()
		lg.add_theme_constant_override("separation", 8)
		var pastille := ColorRect.new()
		pastille.color = FenetreComite.FOND_MOTIF[k]
		pastille.custom_minimum_size = Vector2(18, 18)
		lg.add_child(pastille)
		var nl := Composants.label("%s : %s" % [FenetreComite.LETTRES[k], NOMS_TERRAINS[k]])
		nl.add_theme_font_size_override("font_size", 14)
		lg.add_child(nl)
		legende.add_child(lg)
	bas.add_child(legende)
	corps.add_child(cadre)
	corps.move_child(cadre, 1)
	fiche_animal = cadre
	scroll.scroll_vertical = 0


func _glossaire_actions() -> void:
	var L: Array[String] = []
	for a in data["workers"]["cartes_action"]:
		L.append("[b]%s[/b] (%d) : %s" % [a["nom"], int(a["cout"]), a["texte"]])
	_feuille("Cartes d'action").text = "\n\n".join(L)


func _glossaire_labels() -> void:
	var L: Array[String] = ["S'achètent à la Bourse des ressources, zoo ouvert, une fois chacun. Le prix en or double sans Marchand mobilisé.\n"]
	for a in data["buildings"]["reputation_autres"]["labels"]:
		L.append("[b]%s[/b] : %d or → +%d de réputation" % [a["nom"], int(a["or"]), int(a["reputation"])])
	_feuille("Labels").text = "\n".join(L)


func _glossaire_evenements() -> void:
	var L: Array[String] = []
	for a in data["events"]["evenements"]:
		L.append("[b]%s[/b] : %s" % [a["nom"], a["texte"]])
	_feuille("Événements").text = "\n\n".join(L)


func _glossaire_bonus() -> void:
	var L: Array[String] = ["Le premier en influence en choisit un chaque nuit (ou aucun) : il vaut pour tous le lendemain.\n"]
	for a in data["events"]["bonus_nuit"]:
		L.append("[b]%s[/b] : %s" % [a["nom"], a["texte"]])
	_feuille("Bonus de nuit").text = "\n".join(L)
