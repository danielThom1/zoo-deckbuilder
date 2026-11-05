class_name Aide
extends ColorRect
## Écran d'aide : tutoriel (comment se déroule une partie, comment gagner de la réputation) et glossaire de tout ce qui
## existe dans le jeu, généré depuis les fichiers de données. S'ouvre depuis le menu principal et le bouton « ? » en jeu.

const PAGES := [
	["Le but du jeu", """Vous bâtissez un zoo pour ZooLife™, en concurrence avec d'autres groupes. [b]Le premier à 100 de réputation l'emporte[/b] (sinon, le mieux placé au soir du jour 22).

Vos collaborateurs sont des [b]cartes[/b] : vous en choisissez 8 au début, vous en piochez 4 chaque matin, vous les envoyez travailler, puis ils repartent à la défausse. Une partie alterne [b]les jours[/b], en temps réel, où l'on récolte et construit, et [b]les nuits[/b], au tour par tour, où l'on achète."""],
	["Le draft", """Avant le premier jour, des cartes sont révélées par groupes de 4 et chacun en prend une à tour de rôle, pendant 8 tours. C'est votre deck de départ.

[b]Peu qualifiés[/b] : bon marché, un seul talent.
[b]Qualifiés[/b] : plus efficaces, souvent le seul moyen d'aménager le terrain (Paysagiste, Terrassier).
[b]Cadres[/b] : mauvais à la tâche, mais ils se mobilisent pour leur capacité ou se [b]jouent[/b] pour un effet immédiat.

Survolez une carte pour voir son métier et ses traits."""],
	["Le jour", """Chaque journée commence [b]en pause[/b] : préparez vos ordres, puis lancez le temps (Espace).

[b]Mobiliser[/b] une carte paie son salaire et la pose sur le camp. Un collaborateur par jour peut partir gratuitement, à 25 % de rendement. Plus d'argent ? Le bouton +4 d'une carte cède sa journée : elle ne travaille pas et part à la défausse.
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
[b]La formation[/b] : Centre de formation et Formateur, pour des collaborateurs légendaires.

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
	["Réputation", "Le score : le premier à 100 gagne."],
	["Logement", "Nombre maximal de collaborateurs. Le camp en loge 8, chaque Maison un de plus."],
	["Propreté", "Les visiteurs salissent le parc. Sous 60, puis sous 30, moins de visiteurs viennent."],
]
const DESCRIPTIONS := {
	"route": "Relie l'Accès à l'entrée pour les visiteurs ; les collaborateurs y vont deux fois plus vite.", "pont": "Une route sur l'eau.",
	"maison": "Loge un collaborateur de plus.", "entrepot": "Dépôt de ressources : réduit les trajets des récolteurs.",
	"comptoir": "Vente à 70 % sans Marchand ; avec un Marchand, vente à 125 % et achats 30 % moins chers.",
	"agence": "Une fois par jour, remplace un collaborateur sur le terrain par une carte de la pioche ou de la défausse.",
	"mine": "Sur un gisement : permet d'extraire de l'or.", "cloture": "Mur de l'enceinte du zoo. Se construit aussi sur l'eau.",
	"entree": "Porte du zoo : un collaborateur y tient le guichet. Touche R pour la tourner.", "enclos": "Ferme les enclos des animaux. Se construit aussi sur l'eau.",
	"boutique": "Tenue par un seul collaborateur : souvenirs (×2,5 avec un Vendeur) et un peu de réputation.",
	"cuisine": "Prépare et livre les rations des animaux.", "entretien": "Un collaborateur y nettoie le parc.",
	"snack": "Tenu par un collaborateur : les visiteurs restent 50 % plus longtemps et dépensent 1 d'argent de plus.", "kiosque": "Tenu par un collaborateur : attractivité et réputation (Animateur ×2).",
	"camp_n2": "Une carte de plus en main.", "camp_n3": "Encore une carte de plus en main.",
}

var data: Dictionary
var corps: VBoxContainer
var scroll: ScrollContainer
var onglets: VBoxContainer
var page := 0


func _init(game_data: Dictionary) -> void:
	data = game_data


func _ready() -> void:
	color = Color(UiTokens.MARINE, 0.75)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTokens.build_theme()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 12, 2, 16))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 70
	panel.offset_right = -70
	panel.offset_top = 40
	panel.offset_bottom = -40
	add_child(panel)
	var racine := HBoxContainer.new()
	racine.add_theme_constant_override("separation", 16)
	panel.add_child(racine)
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
	var fermer := Composants.bouton("Fermer", "BoutonPrincipal")
	fermer.custom_minimum_size = Vector2(180, 42)
	fermer.size_flags_horizontal = Control.SIZE_SHRINK_END
	fermer.pressed.connect(queue_free)
	droite.add_child(fermer)
	_titre_onglet("TUTORIEL")
	for k in PAGES.size():
		_onglet(PAGES[k][0], _montrer_page.bind(k))
	_titre_onglet("GLOSSAIRE")
	for g in [["Ressources", _glossaire_ressources], ["Métiers", _glossaire_metiers], ["Traits", _glossaire_traits],
			["Bâtiments", _glossaire_batiments], ["Terrain", _glossaire_terrain], ["Animaux", _glossaire_animaux],
			["Cartes d'action", _glossaire_actions], ["Labels", _glossaire_labels], ["Événements", _glossaire_evenements], ["Bonus de nuit", _glossaire_bonus]]:
		_onglet(g[0], g[1])
	_montrer_page(page)


func _titre_onglet(txt: String) -> void:
	var t := Composants.label(txt, "TitrePanneau")
	onglets.add_child(t)


func _onglet(txt: String, action: Callable) -> void:
	var b := Composants.bouton(txt, "BoutonSecondaire")
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 32
	b.pressed.connect(action)
	onglets.add_child(b)


## Vide le contenu, pose le titre, renvoie un texte riche prêt à remplir.
func _feuille(titre: String) -> RichTextLabel:
	for c in corps.get_children():
		c.queue_free()
	scroll.scroll_vertical = 0
	var t := Composants.label(titre, "TitreEcran")
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
	_feuille("Ressources").text = "\n\n".join(L)


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


func _glossaire_batiments() -> void:
	var L: Array[String] = []
	for b in data["buildings"]["batiments"]:
		if b["id"] == "camp":
			continue
		var d: String = DESCRIPTIONS.get(b["id"], str(b.get("_note_effet", "")))
		L.append("[b]%s[/b] (%s, %d s de travail) : %s" % [b["nom"], _cout(b.get("cout", {})), int(b["travail"]), d])
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
	var L: Array[String] = []
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
				var l := "%s[b]%s[/b] · %s · %s · %s · attractivité %d · enclos de %d cases" % [img, a["nom"], paliers[pal]["nom"], types[a["type"]],
					_cout(a["cout"]), int(a["reputation"]), int(a["taille"])]
				if a.has("decor"):
					l += " + aménagement requis"
				if a.has("effet_texte"):
					l += "\n    [color=#13867F]%s[/color]" % a["effet_texte"]
				L.append(l)
		L.append("")
	_feuille("Animaux").text = "\n".join(L)


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
