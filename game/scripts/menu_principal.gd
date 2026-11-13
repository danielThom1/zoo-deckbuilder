class_name MenuPrincipal
extends Control
## Menu principal « Le Comité », variante A (docs/handoff_menus, maquettes 10A*) : couverture de rapport annuel à gauche,
## sommaire en trois chapitres (Jouer, Défis, Apprendre), bloc « Dossier en cours » quand une sauvegarde existe, et une
## fiche de mode agrafée à droite de la couverture, reliée à la ligne choisie par une languette jaune. Les réglages de la
## fiche dépendent du mode. Le défi de la semaine a sa note de service épinglée sur la carte. Statistiques, Réglages et
## Quitter sont dans le pied de la couverture.
## Fond : l'image du zoo en pleine journée (FOND_ILLUSTRE, rendue par le jeu), puis, dès qu'elle est prête, une vraie
## partie d'IA enregistrée qui tourne derrière (main.gd, vitrine_fond) dans un SubViewport, en fondu par-dessus l'image.
## Option de capture : --menu=course|nature|cozy|multi|semaine|permanents|tutoriel|dossier (ligne choisie au départ) ;
## --fond-fixe : sans le fond vivant ; --souris=x,y : souris posée là (survol).

signal lancer(spectateur: bool, graine: int, adversaires: int, niveau: String)
signal defi(id: String)  # un défi à jouer
signal revoir_defi(replay: Dictionary)  # replay du vainqueur de la semaine passée
signal continuer
signal tutoriel
signal multijoueur
signal replay_etude(chemin: String)

const FOND_ILLUSTRE := "res://assets/bd/menu_fond.jpg"
const JOUEURS := [Color("13867F"), Color("F0A020"), Color("3A6AE0"), Color("E04A8A")]
const FORMES := ["rond", "carre", "triangle", "losange"]
const NIVEAUX := ["facile", "moyen", "difficile"]
const RIVAUX := ["PanZoo", "Safari Capital", "BioLand"]
const LANGUETTE_X := 612.0  # bord droit de la languette (la fiche commence à 604)
const FICHE_X := 604.0
const FICHE_L := 452.0
const TERRAIN_MOTIF := {"Prairie": Color("62AE34"), "Foret": Color("2E7A2C"), "Eau": Color("2B86D2"), "Roche": Color("A8A296"),
	"Sable": Color("F2D684"), "Montagne": Color("8E7E6C")}

## Les lignes du sommaire : [choix, numéro, titre, chapitre].
const LIGNES := [
	["course", "01", "Partie classique", "I"], ["nature", "02", "Réserve naturelle", "I"], ["cozy", "03", "Gestion libre", "I"],
	["multi", "04", "Multijoueur", "I"], ["semaine", "05", "Défi de la semaine", "II"], ["permanents", "06", "Défis permanents", "II"],
	["tutoriel", "07", "Tutoriel", "III"], ["regles", "08", "Règles et glossaire", "III"],
]
const CHAPITRES := {"I": "Jouer", "II": "Défis · la même partie pour tous", "III": "Apprendre"}

static var mode_partie := "course"  # course, nature ou cozy (ModesPartie), lu par main au lancement
static var iso_demande := false  # essai de la vue isométrique, lancé depuis le menu
static var vue3d_demandee := false  # essai de la vue 3D, lancé depuis le menu

var graine := 0
var adversaires := 3
var niveau := "moyen"  # niveau des IA : facile, moyen, difficile (stratégies choisies par l'étude)
var choix := "course"
var donnees: Dictionary
var sauvee := {}
var classement: Classement
var rang_semaine := {}  # classement du défi de la semaine, lu sur le serveur
var vainqueur := {}

var fond: TextureRect
var fond_vivant: TextureRect  # image du SubViewport où tourne la partie du fond
var fond_vue: SubViewport
var fond_jeu: Node  # instance de main.tscn en mode vitrine_fond
var fond_attente := 0.6  # le fond vivant démarre après l'apparition du menu
var couverture: PanelContainer
var lignes := {}  # choix -> Button
var bloc_dossier: Button
var fiche: PanelContainer
var fiche_corps: VBoxContainer
var bouton_principal: Button
var note: Control
var champ_graine: LineEdit
var attente_graine := -1.0
var _cartes := {}  # "graine_mode" -> {"tex", "texte"}
var _rebours_lbl: Array = []  # libellés du compte à rebours, rafraîchis chaque minute
var _rebours_t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTokens.build_theme()
	donnees = GameData.load_all()
	graine = randi() % 1000000
	sauvee = Sauvegarde.resume()
	if not sauvee.is_empty():
		choix = "dossier"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--menu="):
			choix = a.trim_prefix("--menu=")
	if choix == "dossier" and sauvee.is_empty():
		choix = "course"
	classement = Classement.new()
	add_child(classement)
	_construire()
	# Les fenêtres ouvertes par-dessus le menu (défis, statistiques, réglages, pseudo…) passent devant la ligne choisie,
	# qui est dessinée en z 2 pour recouvrir le bord de la fiche.
	child_entered_tree.connect(func(n: Node):
		if n is Control and n != classement:
			(n as Control).z_index = 10)
	_choisir(choix)
	_lire_classement.call_deferred()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--souris="):  # captures : souris posée à x,y (survol)
			var xy := a.trim_prefix("--souris=").split(",")
			get_tree().create_timer(0.3).timeout.connect(func(): get_viewport().warp_mouse(Vector2(float(xy[0]), float(xy[1]))))
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)


# ---------------------------------------------------------------- construction

func _construire() -> void:
	fond = TextureRect.new()
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fond.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(FOND_ILLUSTRE):
		fond.texture = load(FOND_ILLUSTRE)
	add_child(fond)
	fond_vivant = TextureRect.new()
	fond_vivant.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond_vivant.stretch_mode = TextureRect.STRETCH_SCALE
	fond_vivant.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond_vivant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fond_vivant.modulate.a = 0.0
	add_child(fond_vivant)
	if "--fond-fixe" in OS.get_cmdline_user_args():
		fond_attente = -1.0
	# Ombre pleine de la couverture (10 px, encre à 35 %)
	var ombre := ColorRect.new()
	ombre.color = Color(UiTokens.ENCRE, 0.35)
	ombre.anchor_bottom = 1.0
	ombre.offset_left = 580
	ombre.offset_right = 590
	ombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ombre)
	add_child(_couverture())
	fiche = PanelContainer.new()
	fiche.name = "Fiche"
	fiche.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 2, true))
	fiche.position = Vector2(FICHE_X, 238)
	fiche.custom_minimum_size.x = FICHE_L
	fiche.size.x = FICHE_L
	add_child(fiche)
	note = _note_de_service()
	add_child(note)
	if OS.has_feature("editor"):
		add_child(_bouton_dev())


func _couverture() -> PanelContainer:
	couverture = PanelContainer.new()
	couverture.name = "Colonne"
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.PAPIER
	sb.border_color = UiTokens.ENCRE
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 26
	sb.content_margin_bottom = 16
	couverture.add_theme_stylebox_override("panel", sb)
	couverture.anchor_bottom = 1.0
	couverture.offset_left = 60
	couverture.offset_right = 580
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	couverture.add_child(col)
	var haut := HBoxContainer.new()
	var ra := Composants.texte("RAPPORT ANNUEL", 12, 600, UiTokens.TEXTE_2, "mono")
	ra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	haut.add_child(ra)
	haut.add_child(Composants.texte("EXERCICE %d" % Time.get_date_dict_from_system()["year"], 12, 600, UiTokens.TEXTE_2, "mono"))
	col.add_child(haut)
	var logo := Composants.image_logo(load("res://assets/bd/logos/zoolife.png"), Vector2(236, 158))
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(logo)
	var accroche := Composants.texte("Bâtissez le zoo le plus rentable de la vallée,\navec le personnel que vous méritez.", 14, 600, UiTokens.TEXTE_2, "italique")
	accroche.add_theme_constant_override("line_spacing", -2)
	accroche.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(accroche)
	if not sauvee.is_empty():
		col.add_child(_espace(12))
		bloc_dossier = _bloc_dossier()
		col.add_child(bloc_dossier)
	col.add_child(_espace(14))
	var filet := ColorRect.new()
	filet.color = UiTokens.ENCRE
	filet.custom_minimum_size.y = 3
	filet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(filet)
	col.add_child(_espace(6))
	col.add_child(Composants.texte("SOMMAIRE", 13, 800, UiTokens.ENCRE, "titre"))
	var chap := ""
	for l in LIGNES:
		if l[3] != chap:
			chap = l[3]
			col.add_child(_espace(4))
			col.add_child(Composants.chapitre(chap, CHAPITRES[chap]))
		var b := _ligne_sommaire(l[0], l[1], l[2], _note_ligne(l[0]))
		lignes[l[0]] = b
		col.add_child(b)
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(esp)
	col.add_child(_pied())
	return couverture


func _note_ligne(c: String) -> String:
	match c:
		"course":
			return "vous + 1 à 3 IA"
		"nature":
			return "terrain tel quel"
		"cozy":
			return "seul, sans fin"
		"multi":
			return "2 à 4 joueurs"
		"semaine":
			return "fin dans " + Composants.rebours_semaine()["court"]
		"permanents":
			return "%d cartes · classements" % Defis.donnees()["defis"].size()
		"tutoriel":
			return "avec Hubert"
	return ""


## Ligne du sommaire : numéro, titre en capitales, points de conduite, note. Choisie : jaune, ouverte à droite, et
## prolongée jusqu'à la fiche (languette) : son fond déborde de LANGUETTE_X − bord, au-dessus du contour de la fiche.
func _ligne_sommaire(c: String, num: String, titre: String, note_txt: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 38
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func(): _choisir(c))
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var n := Composants.texte(num, 13, 600, UiTokens.TEXTE_2, "mono")
	n.custom_minimum_size.x = 22
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(n)
	var t := Composants.texte(titre.to_upper(), 21, 800, UiTokens.ENCRE, "titre")
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	if c == "semaine":
		var badge := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiTokens.ENCRE
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		badge.add_theme_stylebox_override("panel", sb)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(Composants.texte(Composants.date_semaine(), 11, 600, UiTokens.SELECTION, "mono"))
		h.add_child(badge)
	var points := Control.new()
	points.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	points.mouse_filter = Control.MOUSE_FILTER_IGNORE
	points.draw.connect(func():
		var y := points.size.y * 0.5 + 6.0
		var x := 2.0
		while x < points.size.x - 2.0:
			points.draw_circle(Vector2(x, y), 1.0, UiTokens.POINTILLES)
			x += 4.0)
	h.add_child(points)
	var nl := Composants.texte(note_txt, 13, 600, UiTokens.TEXTE_2)
	nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(nl)
	b.set_meta("textes", [n, nl])
	if c == "semaine":
		_rebours_lbl.append([nl, "court", "fin dans "])
	return b


## Style d'une ligne (ou du bloc « Dossier en cours ») selon qu'elle est choisie.
func _styler_ligne(b: Button, on: bool, fond_repos := Color(0, 0, 0, 0)) -> void:
	var normal := StyleBoxFlat.new()
	normal.anti_aliasing = true
	normal.set_corner_radius_all(8)
	normal.bg_color = fond_repos
	if fond_repos.a > 0.0:
		normal.border_color = UiTokens.ENCRE
		normal.set_border_width_all(2)
	var survol: StyleBoxFlat = normal.duplicate()
	survol.bg_color = UiTokens.JAUNE_CLAIR
	if on:
		normal.bg_color = UiTokens.SELECTION
		normal.border_color = UiTokens.ENCRE
		normal.border_width_left = 2
		normal.border_width_top = 2
		normal.border_width_bottom = 2
		normal.border_width_right = 0
		normal.corner_radius_top_right = 0
		normal.corner_radius_bottom_right = 0
		# Languette : le fond déborde jusqu'à la fiche (la colonne s'arrête à 544 dans le repère de l'écran)
		normal.expand_margin_right = LANGUETTE_X - 544.0
		survol = normal
	b.z_index = 2 if on else 0
	for s in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, survol if s != "normal" else normal)
	for l in b.get_meta("textes", []):
		(l as Label).add_theme_color_override("font_color", UiTokens.ENCRE if on else UiTokens.TEXTE_2)


## Bloc « Dossier en cours » (sauvegarde) au-dessus du sommaire : h 66, fond mémo, jaune s'il est choisi.
func _bloc_dossier() -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 56
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func(): _choisir("dossier"))
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 12
	h.offset_right = -12
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(Composants.texte("DOSSIER EN COURS · CONTINUER", 13, 800, UiTokens.ENCRE, "titre"))
	var detail := Composants.texte("%s · Jour %d · %d joueurs · %s" % [_nom_mode(sauvee), int(sauvee["jour"]), int(sauvee["joueurs"]),
		_il_y_a(int(sauvee.get("modifie", 0)))], 13, 600, UiTokens.ENCRE)
	v.add_child(detail)
	var r := Composants.bouton("REPRENDRE ›", "BoutonMini")
	r.add_theme_font_override("font", UiTokens.police_titre())
	r.custom_minimum_size.y = 30
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.pressed.connect(func(): continuer.emit())
	h.add_child(r)
	b.set_meta("textes", [])
	return b


func _pied() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var filet := ColorRect.new()
	filet.color = UiTokens.ENCRE
	filet.custom_minimum_size.y = 2
	filet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(filet)
	v.add_child(_espace(10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(Composants.image_logo(load("res://assets/bd/logos/zoolife_embleme.png"), Vector2(34, 34)))
	var q := VBoxContainer.new()
	q.add_theme_constant_override("separation", -2)
	q.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(q)
	var pseudo := Statistiques.pseudo()
	q.add_child(Composants.texte((pseudo if pseudo != "" else "Nouveau collaborateur").to_upper(), 17, 800, UiTokens.ENCRE, "titre"))
	q.add_child(Composants.texte(_resume_joueur(), 12, 600, UiTokens.TEXTE_2))
	var st := Composants.bouton("Statistiques ›", "BoutonMini")
	st.custom_minimum_size.y = 28
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	st.pressed.connect(ouvrir_statistiques)
	h.add_child(st)
	v.add_child(_espace(10))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	v.add_child(hb)
	for spec in [["Réglages", func(): add_child(Reglages.new())], ["Quitter", func(): get_tree().quit()]]:
		var b := Composants.bouton(spec[0], "BoutonMini")
		b.custom_minimum_size.y = 28
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(spec[1])
		hb.add_child(b)
	v.add_child(_espace(8))
	var slogans: Array = donnees["hubert"]["slogans"]
	var cit := Composants.texte("« %s » H. de la Marge" % str(slogans[randi() % slogans.size()]), 13, 600, UiTokens.TEXTE_2, "italique")
	cit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cit)
	v.add_child(_espace(4))
	var bas := HBoxContainer.new()
	var doc := Composants.texte("Document réservé aux collaborateurs", 11, 500, UiTokens.TEXTE_2, "mono")
	doc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bas.add_child(doc)
	bas.add_child(Composants.tampon("CONFIDENTIEL"))
	v.add_child(bas)
	return v


## « 52 parties · 26 victoires · record 151 » (toutes parties, défis compris).
func _resume_joueur() -> String:
	Statistiques.charger()
	var n := 0
	var vic := 0
	var rec := 0.0
	for t in Statistiques.donnees["totaux"].values():
		n += int(t.get("parties", 0))
		vic += int(t.get("victoires", 0))
		rec = maxf(rec, float(t.get("record", 0.0)))
	if n == 0:
		return "Pas encore de partie · période d'essai"
	return "%d partie%s · %d victoire%s · record %d" % [n, "s" if n > 1 else "", vic, "s" if vic > 1 else "", roundi(rec)]


# ---------------------------------------------------------------- choix d'une ligne et fiche de mode

func _choisir(c: String) -> void:
	if c == "regles":
		add_child(Aide.new(donnees))
		return
	choix = c
	for k in lignes:
		_styler_ligne(lignes[k], k == c)
	if bloc_dossier:
		_styler_ligne(bloc_dossier, c == "dossier", UiTokens.MEMO)
	_remplir_fiche()
	_placer_fiche.call_deferred()


## La fiche commence à y 238 (300 sous le bloc « Dossier en cours », 214 quand c'est lui qui est choisi) et descend au
## moins jusqu'à la ligne choisie, pour que la languette la touche.
func _placer_fiche() -> void:
	var haut := 238.0
	if not sauvee.is_empty():
		haut = 214.0 if choix == "dossier" else 300.0
	var ligne: Control = bloc_dossier if choix == "dossier" else lignes.get(choix)
	fiche.custom_minimum_size.y = 0
	fiche.reset_size()
	fiche.size.x = FICHE_L
	if ligne:
		var r := ligne.get_global_rect()
		var gx := get_global_transform().affine_inverse()
		var y0 := (gx * r.position).y
		var y1 := (gx * r.end).y
		if y0 < haut + 44.0:
			haut = maxf(10.0, y0 - 44.0)
		fiche.custom_minimum_size.y = maxf(0.0, y1 + 24.0 - haut)
	fiche.position = Vector2(FICHE_X, haut)
	fiche.reset_size()
	# Pas plus bas que l'écran
	var bas := size.y - 16.0
	if fiche.position.y + fiche.size.y > bas:
		fiche.position.y = maxf(10.0, bas - fiche.size.y)


func _remplir_fiche() -> void:
	for e in fiche.get_children():
		fiche.remove_child(e)
		e.queue_free()
	_rebours_lbl = _rebours_lbl.filter(func(x): return is_instance_valid(x[0]) and (x[0] as Node).is_inside_tree())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	fiche.add_child(v)
	var num := ""
	for l in LIGNES:
		if l[0] == choix:
			num = l[1] + " · " + l[2]
	match choix:
		"course":
			_entete(v, num, "~14 jours", UiTokens.SARCELLE)
			_regles(v, "Premier à 120 de réputation contre 1 à 3 IA. Le terrain s'aménage : creuser des bassins, planter, dérocher. Le mode pour débuter, en Facile.",
				[Composants.etiquette("Pour débuter", "etoile", UiTokens.SELECTION, UiTokens.JAUNE_CLAIR), Composants.pastille_mode("course"), Composants.etiquette("Objectif 120")])
			var c := _corps(v)
			_reglages_rivaux(c)
			_reglage_carte(c, "course", "")
			_avertir_sauvegarde(c)
			_bouton(c, "SIGNER LA PRISE DE POSTE ›", func(): _lancer_mode("course"))
		"nature":
			_entete(v, num, "~14 jours", UiTokens.POSITIF)
			_regles(v, "Pas d'aménagement : un animal ne s'installe que là où son motif existe déjà. Placez votre enceinte autour de ces endroits. Plus exigeant : après quelques parties.",
				[Composants.pastille_mode("nature"), Composants.etiquette("Objectif 120"), Composants.etiquette("Avancé")], _motif_exemple())
			var c := _corps(v)
			_reglages_rivaux(c)
			_reglage_carte(c, "nature", "le relief compte : choisissez une carte variée")
			_avertir_sauvegarde(c)
			_bouton(c, "SIGNER LA PRISE DE POSTE ›", func(): _lancer_mode("nature"))
		"cozy":
			_entete(v, num, "sans fin", UiTokens.MARINE_2)
			_regles(v, "Seul, sans objectif ni fin de partie : pour découvrir le jeu sans pression. Les animaux font des petits, les visiteurs signent le livre d'or.",
				[Composants.etiquette("Seul"), Composants.etiquette("90 d'argent au départ"), Composants.etiquette("Pas de maladie"), Composants.etiquette("Naissances")])
			var c := _corps(v)
			c.add_child(_lab("Adversaires · difficulté"))
			c.add_child(Composants.ligne_tirets("Sans objet en gestion libre : aucun rival, aucune pression"))
			_reglage_carte(c, "cozy", "")
			_avertir_sauvegarde(c)
			_bouton(c, "OUVRIR LE PARC ›", func(): _lancer_mode("cozy"))
		"multi":
			_entete(v, num, "2 à 4 joueurs", UiTokens.SARCELLE)
			_regles(v, "Un joueur héberge la partie, les autres le rejoignent avec son adresse IP (réseau local ou VPN). Des IA complètent les places libres.",
				[Composants.etiquette("2 à 4 humains"), Composants.etiquette("IA en complément"), Composants.etiquette("Sans sauvegarde")])
			var c := _corps(v)
			for spec in [["Héberger", "Choisissez la carte et le nombre de places ; la partie démarre quand vous la lancez."],
					["Rejoindre", "Entrez l'adresse de l'hôte (port UDP 7777) et attendez son coup d'envoi."]]:
				c.add_child(_lab(spec[0]))
				c.add_child(Composants.paragraphe(spec[1], 14, UiTokens.ENCRE))
			_bouton(c, "OUVRIR LE SALON ›", func(): multijoueur.emit())
		"semaine":
			_fiche_semaine(v, num)
		"permanents":
			_fiche_permanents(v, num)
		"tutoriel":
			_entete(v, num, "~15 min", UiTokens.SARCELLE)
			_regles(v, "Une partie guidée pas à pas par Hubert de la Marge : récolter, bâtir l'enceinte, ouvrir le zoo, passer la nuit au conseil.",
				[Composants.etiquette("Seul"), Composants.etiquette("Carte imposée"), Composants.etiquette("~15 min")])
			var c := _corps(v)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 10)
			c.add_child(h)
			h.add_child(Composants.image_logo(load("res://assets/bd/hubert/content.png"), Vector2(64, 64)))
			h.add_child(_bulle("Je vous montre tout une fois. Ensuite, on attendra des résultats."))
			_avertir_sauvegarde(c)
			_bouton(c, "COMMENCER ›", func(): tutoriel.emit())
		"dossier":
			_fiche_dossier(v)


func _entete(v: VBoxContainer, titre: String, droite: String, couleur: Color) -> void:
	var e := Composants.entete_comite(titre, droite, couleur)
	var pc: PanelContainer = e["racine"]
	var sb: StyleBoxFlat = pc.get_theme_stylebox("panel").duplicate()
	sb.border_color = UiTokens.ENCRE
	sb.border_width_bottom = 2
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size.y = 40
	(e["titre"] as Label).add_theme_font_size_override("font_size", 15)
	if couleur == UiTokens.SELECTION:
		(e["titre"] as Label).add_theme_color_override("font_color", UiTokens.ENCRE)
		(e["droite"] as Label).add_theme_color_override("font_color", UiTokens.ENCRE)
	else:
		(e["droite"] as Label).add_theme_color_override("font_color", UiTokens.ENTETE)
	v.add_child(pc)


## Bloc des règles du mode : phrase, pastilles, illustration facultative à droite ; fond mémo, filet encre dessous.
func _regles(v: VBoxContainer, phrase: String, pastilles: Array, illustration: Control = null) -> void:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.MEMO
	sb.border_color = UiTokens.ENCRE
	sb.border_width_bottom = 2
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	v.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	var g := VBoxContainer.new()
	g.add_theme_constant_override("separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(g)
	g.add_child(Composants.paragraphe(phrase, 14, UiTokens.ENCRE))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	for c in pastilles:
		chips.add_child(c)
	g.add_child(chips)
	if illustration:
		h.add_child(illustration)


func _corps(v: VBoxContainer) -> VBoxContainer:
	var m := MarginContainer.new()
	for c in [["left", 14], ["right", 14], ["top", 2], ["bottom", 14]]:
		m.add_theme_constant_override("margin_" + c[0], c[1])
	v.add_child(m)
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 6)
	m.add_child(c)
	return c


func _lab(t: String) -> Label:
	var l := Composants.texte(t.to_upper(), 12, 800, UiTokens.TEXTE_2, "titre")
	l.custom_minimum_size.y = 30
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return l


func _reglages_rivaux(c: VBoxContainer) -> void:
	c.add_child(_lab("Adversaires"))
	var rivaux := HBoxContainer.new()
	rivaux.add_theme_constant_override("separation", 6)
	c.add_child(Composants.segments(["1", "2", "3"], adversaires - 1, func(k: int):
		adversaires = k + 1
		_maj_rivaux(rivaux)))
	c.add_child(rivaux)
	_maj_rivaux(rivaux)
	c.add_child(_lab("Difficulté"))
	var seg := Composants.segments(["Facile", "Moyen", "Difficile"], NIVEAUX.find(niveau), func(k: int): niveau = NIVEAUX[k])
	var aides := ["Des rivaux qui tâtonnent : les stratégies les plus faibles de l'étude",
		"Des rivaux sérieux : les stratégies du milieu du classement de l'étude",
		"Des rivaux redoutables : les meilleures stratégies apprises par l'étude"]
	for k in seg.get_child_count():
		(seg.get_child(k) as Button).tooltip_text = aides[k]
	c.add_child(seg)


func _maj_rivaux(box: HBoxContainer) -> void:
	for e in box.get_children():
		box.remove_child(e)
		e.queue_free()
	for k in adversaires:
		var cadre := PanelContainer.new()
		var sb := UiTokens.panneau(UiTokens.PAPIER, 6, 2, 0, false)
		cadre.add_theme_stylebox_override("panel", sb)
		cadre.add_child(Composants.image_logo(Composants.logo_groupe(RIVAUX[k], true), Vector2(28, 28)))
		box.add_child(cadre)
	var l := Composants.texte(", ".join(RIVAUX.slice(0, adversaires)), 13, 600)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(l)


## Carte : vignette 104, graine, « Autre carte », proportions de terrain (et un conseil facultatif).
func _reglage_carte(c: VBoxContainer, mode: String, conseil: String) -> void:
	c.add_child(_lab("Carte"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	c.add_child(h)
	var infos := _infos_carte(graine, mode)
	var vign := Composants.vignette_carte(infos["tex"], 104)
	h.add_child(vign)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(cv)
	champ_graine = LineEdit.new()
	champ_graine.text = str(graine)
	champ_graine.custom_minimum_size.y = 38
	champ_graine.add_theme_font_override("font", UiTokens.police_mono(600))
	champ_graine.add_theme_font_size_override("font_size", 17)
	champ_graine.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	champ_graine.tooltip_text = "Même numéro = même carte pour tous les joueurs."
	champ_graine.text_changed.connect(func(_t): attente_graine = 0.45)
	champ_graine.text_submitted.connect(func(_t): _valider_graine())
	cv.add_child(champ_graine)
	var autre := Composants.bouton("↻ Autre carte", "BoutonMini")
	autre.custom_minimum_size.y = 34
	autre.add_theme_font_size_override("font_size", 14)
	autre.pressed.connect(func(): _changer_carte(randi() % 1000000))
	cv.add_child(autre)
	var t := Composants.texte(infos["texte"] + ((" · " + conseil) if conseil != "" else ""), 12, 600, UiTokens.TEXTE_2)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cv.add_child(t)


func _infos_carte(g: int, mode: String) -> Dictionary:
	var m := "nature" if mode == "nature" else "course"
	var cle := "%d_%s" % [g, m]
	if not _cartes.has(cle):
		var d := ModesPartie.appliquer(donnees, "nature") if m == "nature" else donnees
		var carte := MapGenerator.generate(d["buildings"], g)
		var compte := {}
		for y in carte.h:
			for x in carte.w:
				compte[carte.get_t(x, y)] = compte.get(carte.get_t(x, y), 0) + 1
		var n := float(carte.w * carte.h)
		_cartes[cle] = {"tex": ImageTexture.create_from_image(Composants.peindre_carte(carte)),
			"texte": "Forêt %d %% · eau %d %% · roche %d %%" % [roundi(100.0 * compte.get(GameMap.FORET, 0) / n),
				roundi(100.0 * compte.get(GameMap.EAU, 0) / n), roundi(100.0 * compte.get(GameMap.ROCHE, 0) / n)]}
	return _cartes[cle]


func _avertir_sauvegarde(c: VBoxContainer) -> void:
	if sauvee.is_empty():
		return
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(Composants.Forme.new("triangle", UiTokens.NEGATIF, 11.0))
	h.add_child(Composants.texte("Une nouvelle partie remplacera le dossier en cours (jour %d)." % int(sauvee["jour"]), 12, 600, UiTokens.NEGATIF))
	c.add_child(_espace(4))
	c.add_child(h)


func _bouton(c: VBoxContainer, t: String, action: Callable) -> Button:
	c.add_child(_espace(10))
	var b := Composants.bouton(t, "BoutonPrincipal")
	b.add_theme_font_override("font", UiTokens.police_titre())
	b.add_theme_font_size_override("font_size", 21)
	b.custom_minimum_size.y = 52
	b.pressed.connect(action)
	c.add_child(b)
	bouton_principal = b
	return b


func _bulle(t: String) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UiTokens.panneau(UiTokens.MEMO, 10, 2, 0, false)
	sb.content_margin_left = 13
	sb.content_margin_right = 13
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	sb.shadow_color = UiTokens.ENCRE
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Composants.texte(t, 14, 600, UiTokens.ENCRE, "italique")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	return p


## Motif de l'aigle royal en petite grille (Réserve naturelle), d'après animals.json.
func _motif_exemple() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var def: Dictionary = {}
	var liste: Array = donnees["animals"].get("animaux", [])
	for a in liste:
		if a is Dictionary and a.get("id", "") == "aigle_royal":
			def = a
	if def.is_empty():
		return v
	var cases := {}
	for c in def["motif"]:
		cases[Vector2i(int(c[0]), int(c[1]))] = str(c[2])
	var grille := Control.new()
	grille.custom_minimum_size = Vector2(54, 54)
	grille.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grille.draw.connect(func():
		for k in cases:
			var r := Rect2(Vector2(k) * 13.0 + Vector2(1, 1), Vector2(11, 11))
			grille.draw_rect(r, TERRAIN_MOTIF.get(cases[k], Color.GRAY))
			grille.draw_rect(r, UiTokens.ENCRE, false, 1.0))
	v.add_child(grille)
	var l := Composants.texte("motif de\nl'aigle royal", 11, 600, UiTokens.TEXTE_2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("line_spacing", -3)
	v.add_child(l)
	return v


func _fiche_semaine(v: VBoxContainer, num: String) -> void:
	var d := Defis.semaine()
	var nb_jours := int(Defis.donnees()["jours"])
	_entete(v, num, "%d jours" % nb_jours, UiTokens.SELECTION)
	_regles(v, "La même partie pour tous : même carte, même draft, mêmes marchés. Seul contre les 3 meilleures IA ; score = réputation au soir du jour %d." % nb_jours,
		[Composants.pastille_mode(str(d["mode"]), true), Composants.etiquette("%d jours" % nb_jours), Composants.etiquette("Classement en ligne")])
	var c := _corps(v)
	c.add_child(_espace(10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	c.add_child(h)
	h.add_child(Composants.vignette_carte(Composants.texture_carte(donnees, int(d["graine"]), str(d["mode"])), 104))
	var g := VBoxContainer.new()
	g.add_theme_constant_override("separation", 2)
	h.add_child(g)
	g.add_child(Composants.texte("Semaine du " + Composants.date_semaine(), 24, 800, UiTokens.ENCRE, "titre"))
	g.add_child(Composants.texte("carte n° %d" % int(d["graine"]), 12, 600, UiTokens.TEXTE_2))
	var r := Composants.rebours_semaine()
	var rb := Composants.texte(r["texte"], 24, 600, UiTokens.ENCRE, "mono")
	g.add_child(rb)
	_rebours_lbl.append([rb, "texte", ""])
	g.add_child(Composants.texte("avant " + str(r["fin"]), 12, 600, UiTokens.TEXTE_2))
	c.add_child(_espace(6))
	c.add_child(_ligne_rang(str(d["id"])))
	_avertir_sauvegarde(c)
	_bouton(c, "JOUER LE DÉFI ›", func(): defi.emit(str(d["id"])))
	var tous := Composants.bouton("Tous les défis et classements ›", "BoutonMini")
	tous.custom_minimum_size.y = 30
	tous.pressed.connect(func(): ouvrir_defis(str(d["id"])))
	c.add_child(_espace(6))
	c.add_child(tous)


## « Votre record : 112 (3 parties) · 14e sur 52 » : record local tout de suite, rang quand le serveur répond.
func _ligne_rang(id: String) -> Label:
	var s: Dictionary = Statistiques.donnees["defis"].get(id, {})
	var t := ("Votre record : %d (%d partie%s)" % [roundi(float(s["meilleur"])), int(s["parties"]), "s" if int(s["parties"]) > 1 else ""]) if not s.is_empty() else "Pas encore joué"
	if id == Defis.semaine()["id"] and not rang_semaine.is_empty():
		t += " · " + (("rang " + Classement.texte_rang(rang_semaine)) if rang_semaine.get("rang") != null else Classement.texte_rang(rang_semaine))
	return Composants.texte(t, 13, 600)


func _fiche_permanents(v: VBoxContainer, num: String) -> void:
	_entete(v, num, "%d jours" % int(Defis.donnees()["jours"]), UiTokens.SARCELLE)
	_regles(v, "Quatre cartes fixes, toujours les mêmes : pour vous mesurer aux autres joueurs, améliorez votre record et grimpez au classement de chacune.",
		[Composants.etiquette("Seul contre 3 IA"), Composants.etiquette("Classement par carte")])
	var c := _corps(v)
	c.add_theme_constant_override("separation", 8)
	c.add_child(_espace(6))
	for d in Defis.donnees()["defis"]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		c.add_child(h)
		h.add_child(Composants.vignette_carte(Composants.texture_carte(donnees, int(d["graine"]), str(d["mode"])), 48))
		var g := VBoxContainer.new()
		g.add_theme_constant_override("separation", 0)
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(g)
		g.add_child(Composants.texte(str(d["nom"]), 18, 800, UiTokens.ENCRE, "titre"))
		var s: Dictionary = Statistiques.donnees["defis"].get(d["id"], {})
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 8)
		ligne.add_child(Composants.pastille_mode(str(d["mode"]), true))
		ligne.add_child(Composants.texte(("record %d" % roundi(float(s["meilleur"]))) if not s.is_empty() else "pas encore joué", 12, 600, UiTokens.TEXTE_2))
		g.add_child(ligne)
		var b := Composants.bouton("Jouer", "BoutonMini")
		b.custom_minimum_size = Vector2(70, 30)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var id := str(d["id"])
		b.pressed.connect(func(): defi.emit(id))
		h.add_child(b)
	_avertir_sauvegarde(c)
	_bouton(c, "OUVRIR LES DÉFIS ›", func(): ouvrir_defis(str(Defis.donnees()["defis"][0]["id"])))


func _fiche_dossier(v: VBoxContainer) -> void:
	var nb := int(Defis.donnees()["jours"]) if str(sauvee.get("defi", "")) != "" else 14
	_entete(v, "Dossier en cours · " + _nom_mode(sauvee), "jour %d / %s%d" % [int(sauvee["jour"]), "" if nb == 10 else "~", nb], UiTokens.ENCRE)
	var c := _corps(v)
	c.add_child(_espace(12))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	c.add_child(h)
	var g := int(sauvee.get("graine", 0))
	if g != 0:
		h.add_child(Composants.vignette_carte(Composants.texture_carte(donnees, g, str(sauvee.get("mode", "course"))), 120))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(Composants.texte(("SAUVEGARDÉ " + _il_y_a(int(sauvee.get("modifie", 0)))).to_upper(), 12, 600, UiTokens.TEXTE_2, "mono"))
	info.add_child(Composants.texte("Jour %d" % int(sauvee["jour"]), 26, 800, UiTokens.ENCRE, "titre"))
	var rivaux := int(sauvee["joueurs"]) - 1
	var det := Composants.texte("Carte n° %d · %s · %d espèce%s installée%s" % [g, ("%d adversaire%s" % [rivaux, "s" if rivaux > 1 else ""]) if rivaux > 0 else "seul",
		int(sauvee.get("especes", 0)), "s" if int(sauvee.get("especes", 0)) > 1 else "", "s" if int(sauvee.get("especes", 0)) > 1 else ""], 13, 600, UiTokens.ENCRE)
	det.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(det)
	var reps: Array = sauvee.get("reps", [])
	var noms: Array = sauvee.get("noms", [])
	if reps.size() > 1 or str(sauvee.get("mode", "")) != "cozy":
		c.add_child(_lab("Réputation (objectif %s)" % ("—" if str(sauvee.get("defi", "")) != "" else "120")))
		var maxi := 120.0
		for r in reps:
			maxi = maxf(maxi, float(r))
		for k in reps.size():
			var l := HBoxContainer.new()
			l.add_theme_constant_override("separation", 10)
			l.custom_minimum_size.y = 30
			c.add_child(l)
			var nom := "Vous" if k == 0 else (str(noms[k]) if k < noms.size() else "Rival %d" % k)
			var tex: Texture2D = load("res://assets/bd/logos/zoolife_embleme.png") if k == 0 else Composants.logo_groupe(nom, true)
			l.add_child(Composants.image_logo(tex, Vector2(26, 26)))
			var n := Composants.texte(nom, 14, 600 if k else 700)
			n.custom_minimum_size.x = 112
			n.clip_text = true
			n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			l.add_child(n)
			l.add_child(Composants.Forme.new(FORMES[k % 4], JOUEURS[k % 4], 10.0))
			var barre := ProgressBar.new()
			barre.show_percentage = false
			barre.max_value = maxi
			barre.value = float(reps[k])
			barre.custom_minimum_size = Vector2(0, 10)
			barre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			barre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var fill := StyleBoxFlat.new()
			fill.bg_color = JOUEURS[k % 4]
			fill.set_corner_radius_all(5)
			barre.add_theme_stylebox_override("fill", fill)
			l.add_child(barre)
			var val := Composants.texte(str(roundi(float(reps[k]))), 14, 600, UiTokens.ENCRE, "mono")
			val.custom_minimum_size.x = 34
			val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			l.add_child(val)
	_bouton(c, "REPRENDRE LE DOSSIER ›", func(): continuer.emit())
	var n2 := Composants.texte("Les autres modes restent accessibles dans le sommaire.", 12, 600, UiTokens.TEXTE_2)
	n2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(_espace(4))
	c.add_child(n2)


func _nom_mode(s: Dictionary) -> String:
	if str(s.get("defi", "")) != "":
		var d := Defis.trouver(str(s["defi"]))
		return "Défi " + str(d.get("nom", ""))
	if int(s.get("humains", 1)) > 1:
		return "Multijoueur"
	match str(s.get("mode", "course")):
		"nature":
			return "Réserve naturelle"
		"cozy":
			return "Gestion libre"
	return "Partie classique"


func _il_y_a(unix: int) -> String:
	if unix <= 0:
		return ""
	var s := int(Time.get_unix_time_from_system()) - unix
	if s < 3600:
		return "il y a %d min" % maxi(1, s / 60)
	if s < 86400:
		return "il y a %d h" % (s / 3600)
	return "il y a %d j" % (s / 86400)


func _lancer_mode(m: String) -> void:
	mode_partie = m
	lancer.emit(false, graine, 0 if m == "cozy" else adversaires, niveau)


# ---------------------------------------------------------------- note de service du défi de la semaine

func _note_de_service() -> Control:
	var racine := Control.new()
	racine.name = "NoteDeService"
	racine.anchor_left = 1.0
	racine.anchor_right = 1.0
	racine.anchor_top = 1.0
	racine.anchor_bottom = 1.0
	racine.offset_left = -480
	racine.offset_right = -60
	racine.offset_top = -352
	racine.offset_bottom = -352
	# Pas de rotation : un texte tourné se dessine flou et en escalier (retour de l'utilisateur).
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := PanelContainer.new()
	p.custom_minimum_size.x = 420
	racine.add_child(p)
	var sb := UiTokens.panneau(UiTokens.MEMO, 8, 2, 0, true)
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", sb)
	var d := Defis.semaine()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	v.add_child(Composants.texte("NOTE DE SERVICE · DÉFI DE LA SEMAINE", 12, 600, UiTokens.ENCRE, "mono"))
	v.add_child(_espace(8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	h.add_child(Composants.vignette_carte(Composants.texture_carte(donnees, int(d["graine"]), str(d["mode"])), 96))
	var g := VBoxContainer.new()
	g.add_theme_constant_override("separation", 2)
	h.add_child(g)
	g.add_child(Composants.texte("Semaine du " + Composants.date_semaine(), 25, 800, UiTokens.ENCRE, "titre"))
	g.add_child(Composants.pastille_mode(str(d["mode"]), true))
	var r := Composants.rebours_semaine()
	var rb := Composants.texte(r["texte"], 22, 600, UiTokens.ENCRE, "mono")
	g.add_child(rb)
	_rebours_lbl.append([rb, "texte", ""])
	g.add_child(Composants.texte("avant " + str(r["fin"]), 12, 600, UiTokens.TEXTE_2))
	v.add_child(_espace(10))
	var filet := ColorRect.new()
	filet.color = UiTokens.FILET
	filet.custom_minimum_size.y = 2
	v.add_child(filet)
	v.add_child(_espace(8))
	var bas := HBoxContainer.new()
	v.add_child(bas)
	var rang := Composants.texte("", 13, 600)
	rang.name = "Rang"
	rang.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rang.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bas.add_child(rang)
	var voir := Composants.bouton("Voir le défi ›", "BoutonMini")
	voir.custom_minimum_size.y = 28
	voir.pressed.connect(func(): ouvrir_defis(str(d["id"])))
	bas.add_child(voir)
	v.add_child(_espace(6))
	var vq := HBoxContainer.new()
	vq.name = "Vainqueur"
	vq.add_theme_constant_override("separation", 4)
	v.add_child(vq)
	_maj_note()
	# La punaise, par-dessus le bord haut
	var punaise := Control.new()
	punaise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	punaise.position = Vector2(196, -10)
	punaise.custom_minimum_size = Vector2(20, 20)
	punaise.draw.connect(func():
		punaise.draw_circle(Vector2(10, 10), 10, UiTokens.ENCRE, true, -1.0, true)
		punaise.draw_circle(Vector2(10, 10), 8, UiTokens.NEGATIF, true, -1.0, true))
	racine.add_child(punaise)
	return racine


## Rang et vainqueur de la note de service, une fois lus sur le serveur.
func _maj_note() -> void:
	var rang: Label = note.find_child("Rang", true, false) if note else null
	if rang == null:
		return
	var id := str(Defis.semaine()["id"])
	var s: Dictionary = Statistiques.donnees["defis"].get(id, {})
	var t := ""
	if not classement.actif():
		t = "Classement en ligne indisponible"
	elif rang_semaine.is_empty():
		t = "Classement…" if classement.erreur == "" else "Hors ligne : classement indisponible"
	elif rang_semaine.get("rang") != null:
		t = "Votre rang : %s sur %d" % [Composants.rang_texte(int(rang_semaine["rang"])), int(rang_semaine["total"])]
	else:
		t = "%s · pas encore classé" % Classement.texte_rang(rang_semaine)
	if not s.is_empty():
		t += " · record %d" % roundi(float(s["meilleur"]))
	rang.text = t
	var vq: HBoxContainer = note.find_child("Vainqueur", true, false)
	for e in vq.get_children():
		vq.remove_child(e)
		e.queue_free()
	if vainqueur.is_empty():
		vq.add_child(Composants.texte("Vainqueur de la semaine passée : —", 12, 600, UiTokens.TEXTE_2))
		return
	vq.add_child(Composants.texte("Vainqueur de la semaine passée :", 12, 600, UiTokens.TEXTE_2))
	vq.add_child(Composants.texte(str(vainqueur["pseudo"]), 12, 800, UiTokens.ENCRE))
	vq.add_child(Composants.texte("(%d) ·" % roundi(float(vainqueur["score"])), 12, 600, UiTokens.TEXTE_2))
	var lien := LinkButton.new()
	lien.text = "Revoir sa partie"
	lien.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	lien.add_theme_font_override("font", UiTokens.police_corps(600))
	lien.add_theme_font_size_override("font_size", 12)
	lien.add_theme_color_override("font_color", UiTokens.SARCELLE_FONCE)
	lien.focus_mode = Control.FOCUS_NONE
	lien.pressed.connect(_revoir_vainqueur)
	vq.add_child(lien)


func _lire_classement() -> void:
	if not classement.actif() or Array(OS.get_cmdline_user_args()).any(func(a): return a.begins_with("--shot")):
		_maj_note()
		return
	rang_semaine = await classement.classement(str(Defis.semaine()["id"]))
	if not is_instance_valid(self):
		return
	vainqueur = await classement.vainqueur_semaine()
	if not is_instance_valid(self):
		return
	_maj_note()
	if choix == "semaine":
		_remplir_fiche()
		_placer_fiche.call_deferred()


func _revoir_vainqueur() -> void:
	var r: Dictionary = await classement.replay_semaine()
	if is_instance_valid(self) and not r.is_empty():
		revoir_defi.emit(r["replay"])


# ---------------------------------------------------------------- développement

## Bouton « DÉV. ▾ » en pointillé, en haut à droite, éditeur seulement : il replie les entrées de développement.
func _bouton_dev() -> MenuButton:
	var m := MenuButton.new()
	m.text = "DÉV. ▾"
	m.flat = false
	m.focus_mode = Control.FOCUS_NONE
	m.add_theme_font_override("font", UiTokens.police_mono(600))
	m.add_theme_font_size_override("font_size", 11)
	m.add_theme_color_override("font_color", UiTokens.PAPIER)
	m.add_theme_color_override("font_hover_color", UiTokens.SELECTION)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UiTokens.ENCRE, 0.55)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	for s in ["normal", "hover", "pressed"]:
		m.add_theme_stylebox_override(s, sb)
	var cadre := Composants.CadreTirets.new()
	cadre.couleur = Color(1, 1, 1, 0.8)
	cadre.rayon = 6
	m.add_child(cadre)
	m.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	m.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	m.offset_right = -14
	m.offset_top = 12
	m.custom_minimum_size.y = 26
	var actions: Array = []
	var ajouter := func(t: String, f: Callable):
		m.get_popup().add_item(t, actions.size())
		actions.append(f)
	ajouter.call("Essai : vue isométrique", func():
		iso_demande = true
		lancer.emit(false, graine, adversaires, niveau))
	ajouter.call("Essai : vue 3D", func():
		vue3d_demandee = true
		lancer.emit(false, graine, adversaires, niveau))
	ajouter.call("Regarder des IA jouer (niveau choisi)", func(): lancer.emit(true, graine, 4, niveau))
	ajouter.call("IA de la dernière étude", func(): lancer.emit(true, graine, 4, "etude"))
	if FileAccess.file_exists(Replay.chemin_etude()):
		ajouter.call("Partie la plus courte de l'étude", func(): replay_etude.emit(Replay.chemin_etude()))
	var n_zero := 0
	for chemin in Replay.chemins_zero():
		n_zero += 1
		ajouter.call("IA à 0 n° %d" % n_zero, func(): replay_etude.emit(chemin))
	m.get_popup().id_pressed.connect(func(id: int): actions[id].call())
	return m


# ---------------------------------------------------------------- divers

## Statistiques ; les missions du premier lancement ramènent au menu (tutoriel, partie classique en Facile, défi).
func ouvrir_statistiques() -> void:
	var s := Statistiques.new(donnees)
	s.mission.connect(_mission)
	add_child(s)


func _mission(m: String) -> void:
	if m == "tutoriel":
		tutoriel.emit()
	elif m == "jouer":
		niveau = "facile"
		_choisir("course")
	elif m == "defi":
		ouvrir_defis(str(Defis.semaine()["id"]))


func ouvrir_defis(id := "") -> void:
	var f := FenetreDefis.new()
	if id != "" and "choisi" in f:
		f.set("choisi", id)
	f.jouer.connect(func(i: String): defi.emit(i))
	f.revoir.connect(func(r: Dictionary): revoir_defi.emit(r))
	add_child(f)


func _espace(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _unhandled_input(e: InputEvent) -> void:
	var champ := is_instance_valid(champ_graine) and champ_graine.has_focus()
	if e.is_action_pressed("ui_cancel") and champ:
		champ_graine.release_focus()
	elif e.is_action_pressed("ui_accept") and not champ and get_viewport().gui_get_focus_owner() == null \
			and is_instance_valid(bouton_principal) and not _fenetre_ouverte():
		bouton_principal.pressed.emit()
		accept_event()


func _fenetre_ouverte() -> bool:
	return get_children().any(func(c): return c is FenetreDefis or c is Statistiques or c is Aide or c is Reglages or c is FenetrePseudo)


## Fond vivant : la partie se charge dans un SubViewport (sans entrée clavier ni souris), s'avance seule jusqu'à la
## mi-journée puis apparaît en fondu. Quand sa journée touche à sa fin, l'image fixe revient et la partie est rechargée.
func _demarrer_fond() -> void:
	if not ResourceLoader.exists("res://assets/vitrine/partie_menu.txt") and not FileAccess.file_exists("res://assets/vitrine/partie_menu.txt"):
		return
	fond_vue = SubViewport.new()
	_taille_fond()
	fond_vue.render_target_update_mode = SubViewport.UPDATE_DISABLED  # la partie demande chaque image (main.FOND_IMAGES)
	fond_vue.gui_disable_input = true
	fond_vue.audio_listener_enable_2d = false
	add_child(fond_vue)
	fond_jeu = load("res://scenes/main.tscn").instantiate()
	fond_jeu.set("vitrine_fond", true)
	fond_vue.add_child(fond_jeu)
	fond_vivant.texture = fond_vue.get_texture()
	resized.connect(_taille_fond)


## Le fond est rendu à la taille réelle de la fenêtre (sinon l'image de 1600 × 900 est agrandie, donc floue) ; la partie,
## elle, voit toujours l'écran de référence (size_2d_override), comme en jeu.
func _taille_fond() -> void:
	if not is_instance_valid(fond_vue):
		return
	var vue := get_viewport_rect().size
	var fenetre := Vector2(get_window().size)
	var echelle := maxf(1.0, minf(fenetre.x / vue.x, fenetre.y / vue.y))
	fond_vue.size = Vector2i((vue * echelle).round())
	fond_vue.size_2d_override = Vector2i(vue.round())
	fond_vue.size_2d_override_stretch = true


func _suivre_fond(delta: float) -> void:
	if fond_attente > 0.0:
		fond_attente -= delta
		if fond_attente <= 0.0:
			_demarrer_fond()
		return
	if not is_instance_valid(fond_jeu):
		return
	match str(fond_jeu.get("fond_etat")):
		"pret":
			fond_vivant.modulate.a = minf(1.0, fond_vivant.modulate.a + delta / 1.5)
		"fini", "echec":
			fond_vivant.modulate.a = maxf(0.0, fond_vivant.modulate.a - delta / 1.0)
			if fond_vivant.modulate.a <= 0.0:
				var reprendre: bool = str(fond_jeu.get("fond_etat")) == "fini"
				fond_vue.queue_free()
				fond_jeu = null
				fond_vivant.texture = null
				fond_attente = 0.2 if reprendre else -1.0


func _process(delta: float) -> void:
	_suivre_fond(delta)
	if attente_graine > 0.0:
		attente_graine -= delta
		if attente_graine <= 0.0:
			_valider_graine()
	_rebours_t -= delta
	if _rebours_t <= 0.0:
		_rebours_t = 20.0
		var r := Composants.rebours_semaine()
		for x in _rebours_lbl:
			if is_instance_valid(x[0]):
				(x[0] as Label).text = str(x[2]) + str(r[x[1]])


func _valider_graine() -> void:
	attente_graine = -1.0
	if not is_instance_valid(champ_graine):
		return
	var t := champ_graine.text.strip_edges()
	if t.is_valid_int() and int(t) != graine:
		_changer_carte(int(t))
	elif not t.is_valid_int():
		champ_graine.text = str(graine)


func _changer_carte(g: int) -> void:
	var tapait := is_instance_valid(champ_graine) and champ_graine.has_focus()
	graine = g
	_remplir_fiche()
	_placer_fiche.call_deferred()
	if tapait:
		champ_graine.grab_focus.call_deferred()
		champ_graine.caret_column = champ_graine.text.length()
