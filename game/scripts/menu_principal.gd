class_name MenuPrincipal
extends Control
## Menu principal « Le Comité » : une couverture de rapport annuel sur le paysage illustré, un sommaire pour les entrées,
## et le panneau « Nouvelle filiale » (adversaires, difficulté, carte) à droite.
## Ne dépend que de GameData, MapGenerator, GameMap et des polices de UiTokens.

signal lancer(spectateur: bool, graine: int, adversaires: int, niveau: String)
signal continuer
signal tutoriel
signal multijoueur
signal replay_etude(chemin: String)

# Couleurs (thème Émeraude, cf. docs/handoff_emeraude/tokens.json)
# Style « BD néo ligne claire » (docs/handoff_bd) : papier blanc, encre marine, accent jaune, bandeau sarcelle
const PANNEAU := Color("FFFFFF")
const PANNEAU_BAS := Color("EEF4F1")
const ENTETE := Color("13867F")
const OR := Color("14202B")
const OR_SOMBRE := Color("14202B")
const OR_CLAIR := Color("1E2C45")
const BOUTON_HAUT := Color("FFD86A")
const BOUTON_BAS := Color("FFC93C")
const BOUTON_TEXTE := Color("14202B")
const TEXTE := Color("14202B")
const TEXTE_2 := Color("4A5664")
const SELECTION := Color("FFC93C")
const JOUEURS := [Color("13867F"), Color("F0A020"), Color("3A6AE0"), Color("E04A8A")]
const FOND_ILLUSTRE := "res://assets/bd/menu_fond.jpg"
const TERRAIN := {
	GameMap.PRAIRIE: Color("62AE34"), GameMap.FORET: Color("2E7A2C"), GameMap.EAU: Color("2B86D2"),
	GameMap.ROCHE: Color("A8A296"), GameMap.SABLE: Color("F2D684"), GameMap.MONTAGNE: Color("8E7E6C"),
	GameMap.MINE_OR: Color("C9A13A"),
}

const PX := 8  # pixels par case dans l'image de fond

static var mode_partie := "course"  # course, nature ou cozy (ModesPartie), lu par main au lancement
static var iso_demande := false  # essai de la vue isométrique, lancé depuis le menu
static var vue3d_demandee := false  # essai de la vue 3D, lancé depuis le menu
var graine := 0
var adversaires := 3
var niveau := "moyen"  # niveau des IA : facile, moyen, difficile (stratégies choisies par l'étude)
const NIVEAUX := ["facile", "moyen", "difficile"]
var police_titre: Font
var police_texte: Font
var police_gras: Font

var fond: TextureRect
var apercu: TextureRect
var champ_graine: LineEdit
var lbl_carte: Label
var lbl_joueurs: Label
var sous_titre_jouer: Label
var note_jouer: Label
var rivaux_box: HBoxContainer
var boutons_adv: Array = []
var boutons_dif: Array = []
var bouton_jouer: Button
var attente_graine := -1.0
var donnees: Dictionary


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_charger_polices()
	donnees = GameData.load_all()
	graine = randi() % 1000000
	_construire()
	_changer_carte(graine)
	_apparition()


# ---------------------------------------------------------------- construction

func _construire() -> void:
	theme = _theme()
	var uit := UiTokens.build_theme()
	theme = uit
	# Fond : le paysage illustré, plein écran
	fond = TextureRect.new()
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fond.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(FOND_ILLUSTRE):
		fond.texture = load(FOND_ILLUSTRE)
	add_child(fond)
	# Couverture : bande blanche de 520 px, pleine hauteur
	var couverture := PanelContainer.new()
	couverture.name = "Colonne"
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.PAPIER
	sb.border_color = UiTokens.ENCRE
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 30
	sb.content_margin_bottom = 26
	couverture.add_theme_stylebox_override("panel", sb)
	couverture.anchor_bottom = 1.0
	couverture.offset_left = 60
	couverture.offset_right = 578
	add_child(couverture)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	couverture.add_child(col)
	var haut := HBoxContainer.new()
	var ra := _label_mono("RAPPORT ANNUEL", 12)
	ra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	haut.add_child(ra)
	haut.add_child(_label_mono("EXERCICE %d" % Time.get_date_dict_from_system()["year"], 12))
	col.add_child(haut)
	var logo := Composants.image_logo(load("res://assets/bd/logos/zoolife.png"), Vector2(360, 240))
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(logo)
	var accroche := Composants.label("Bâtissez le zoo le plus rentable de la vallée,\navec le personnel que vous méritez.")
	accroche.add_theme_font_override("font", UiTokens.police_italique())
	accroche.add_theme_font_size_override("font_size", 15)
	accroche.add_theme_constant_override("line_spacing", -3)
	accroche.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(accroche)
	col.add_child(_espace(16))
	var filet := ColorRect.new()
	filet.color = UiTokens.ENCRE
	filet.custom_minimum_size.y = 3
	col.add_child(filet)
	col.add_child(_espace(6))
	var sm := Composants.label("SOMMAIRE")
	sm.add_theme_font_override("font", UiTokens.police_titre())
	sm.add_theme_font_size_override("font_size", 12)
	sm.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	col.add_child(sm)
	col.add_child(_espace(4))
	var compteur := [0]  # une lambda capture les entiers par valeur
	var ligne := func(titre: String, note: String, action: Callable, actif := false) -> Button:
		compteur[0] += 1
		var b := _ligne_sommaire(compteur[0], titre, note, actif)
		b.pressed.connect(action)
		col.add_child(b)
		return b
	sous_titre_jouer = null
	bouton_jouer = ligne.call("Jouer contre l'IA", "vous + %d IA" % adversaires, func(): lancer.emit(false, graine, adversaires, niveau), true)
	note_jouer = bouton_jouer.get_meta("note")
	var sauvee := Sauvegarde.resume()
	if not sauvee.is_empty():
		ligne.call("Continuer", "Jour %d · %d joueurs" % [sauvee["jour"], sauvee["joueurs"]], func(): continuer.emit())
	ligne.call("Réserve naturelle", "sans aménagement · vous + %d IA" % adversaires, func():
		mode_partie = "nature"
		lancer.emit(false, graine, adversaires, niveau))
	ligne.call("Gestion libre", "seul, sans fin · livre d'or, naissances", func():
		mode_partie = "cozy"
		lancer.emit(false, graine, 0, niveau))
	ligne.call("Multijoueur", "2 à 4 joueurs", func(): multijoueur.emit())
	ligne.call("Tutoriel", "avec Hubert", func(): tutoriel.emit())
	ligne.call("Règles et glossaire", "", func(): add_child(Aide.new(donnees)))
	ligne.call("Réglages", "", func(): add_child(Reglages.new()))
	ligne.call("Quitter", "retour au bureau", func(): get_tree().quit())
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(esp)
	# Slogan du jour
	var slogans: Array = donnees["hubert"]["slogans"]
	var slogan := Composants.label(str(slogans[randi() % slogans.size()]))
	slogan.add_theme_font_override("font", UiTokens.police_italique())
	slogan.add_theme_font_size_override("font_size", 13)
	slogan.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	slogan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slogan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(slogan)
	col.add_child(_espace(8))
	var bas := HBoxContainer.new()
	var doc := _label_mono("Document réservé aux collaborateurs", 11)
	doc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bas.add_child(doc)
	var tampon := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0)
	st.border_color = Color("B3361F")
	st.set_border_width_all(2)
	st.content_margin_left = 8
	st.content_margin_right = 8
	tampon.add_theme_stylebox_override("panel", st)
	var lt := Composants.label("CONFIDENTIEL")
	lt.add_theme_font_override("font", UiTokens.police_titre())
	lt.add_theme_font_size_override("font_size", 14)
	lt.add_theme_color_override("font_color", Color("B3361F"))
	tampon.add_child(lt)
	tampon.rotation = deg_to_rad(-6)
	bas.add_child(tampon)
	col.add_child(bas)
	# Réservé au développement : ces entrées n'existent pas dans le jeu exporté.
	if OS.has_feature("editor"):
		var dev := HBoxContainer.new()
		dev.add_theme_constant_override("separation", 6)
		dev.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		dev.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		dev.position.y = 12
		dev.offset_right = -16
		add_child(dev)
		var b_iso := Button.new()
		b_iso.text = "Essai : vue isométrique"
		b_iso.tooltip_text = "Une partie normale, vue en isométrique. F2 change de vue à tout moment."
		b_iso.pressed.connect(func():
			iso_demande = true
			lancer.emit(false, graine, adversaires, niveau))
		dev.add_child(b_iso)
		var b_3d := Button.new()
		b_3d.text = "Essai : vue 3D"
		b_3d.tooltip_text = "Une partie normale, avec une caméra en perspective. F3 et F2 changent de vue à tout moment."
		b_3d.pressed.connect(func():
			vue3d_demandee = true
			lancer.emit(false, graine, adversaires, niveau))
		dev.add_child(b_3d)
		var b_regarder := Button.new()
		b_regarder.text = "Dév. : regarder des IA jouer"
		b_regarder.tooltip_text = "Quatre IA du niveau choisi (Facile, Moyen, Difficile), avec le code actuel"
		b_regarder.pressed.connect(func(): lancer.emit(true, graine, 4, niveau))
		dev.add_child(b_regarder)
		var b_etude := Button.new()
		b_etude.text = "Dév. : IA de la dernière étude"
		b_etude.tooltip_text = "Les 4 meilleures stratégies de la dernière étude (data/ia_evolution.json), avec le code actuel, sur la carte choisie"
		b_etude.pressed.connect(func(): lancer.emit(true, graine, 4, "etude"))
		dev.add_child(b_etude)
		if FileAccess.file_exists(Replay.chemin_etude()):
			var b_record := Button.new()
			b_record.text = "Dév. : partie la plus courte"
			b_record.pressed.connect(func(): replay_etude.emit(Replay.chemin_etude()))
			dev.add_child(b_record)
		var n_zero := 0
		for chemin in Replay.chemins_zero():
			n_zero += 1
			var b_zero := Button.new()
			b_zero.text = "Dév. : IA à 0 n° %d" % n_zero
			b_zero.pressed.connect(func(): replay_etude.emit(chemin))
			dev.add_child(b_zero)
	add_child(_carte_reglages())
	_maj_joueurs()


func _label_mono(t: String, taille: int) -> Label:
	var l := Composants.label(t)
	l.add_theme_font_override("font", UiTokens.police_mono(500))
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	return l


## Ligne de sommaire : numéro, titre, points de conduite, note à droite. L'entrée active est jaune.
func _ligne_sommaire(n: int, titre: String, note: String, actif: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 48
	var normal := StyleBoxFlat.new()
	normal.bg_color = UiTokens.SELECTION if actif else Color(0, 0, 0, 0)
	normal.set_corner_radius_all(8)
	normal.anti_aliasing = true
	if actif:
		normal.border_color = UiTokens.ENCRE
		normal.set_border_width_all(2)
	var survol: StyleBoxFlat = normal.duplicate()
	survol.bg_color = UiTokens.BOUTON_HAUT if actif else UiTokens.JAUNE_CLAIR
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", survol)
	b.add_theme_stylebox_override("pressed", survol)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -14
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var num := _label_mono("%02d" % n, 14)
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(num)
	var t := Composants.label(titre.to_upper())
	t.add_theme_font_override("font", UiTokens.police_titre())
	t.add_theme_font_size_override("font_size", 22)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	var points := Control.new()
	points.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	points.mouse_filter = Control.MOUSE_FILTER_IGNORE
	points.draw.connect(func():
		var y := points.size.y * 0.58
		var x := 0.0
		while x < points.size.x:
			points.draw_circle(Vector2(x, y), 0.8, UiTokens.ENCRE_DOUX)
			x += 4.0)
	h.add_child(points)
	var nl := Composants.label(note)
	nl.add_theme_font_override("font", UiTokens.police_corps(600))
	nl.add_theme_font_size_override("font_size", 13)
	nl.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(nl)
	b.set_meta("note", nl)
	return b


## Panneau « Nouvelle filiale » : adversaires, difficulté, carte, signature.
func _carte_reglages() -> Control:
	var p := PanelContainer.new()
	p.name = "Reglages"
	var sb := UiTokens.panneau(UiTokens.PAPIER, 12, 2, 2, true)
	p.add_theme_stylebox_override("panel", sb)
	p.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.offset_right = -70
	p.offset_left = -510
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var tete := PanelContainer.new()
	tete.add_theme_stylebox_override("panel", UiTokens.entete(UiTokens.SARCELLE, 10))
	var th := HBoxContainer.new()
	tete.add_child(th)
	var tt := Composants.label("NOUVELLE FILIALE", "EnteteComite")
	tt.add_theme_font_size_override("font_size", 20)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(tt)
	var duree := Composants.label("~14 jours")
	duree.add_theme_font_override("font", UiTokens.police_mono(500))
	duree.add_theme_font_size_override("font_size", 12)
	duree.add_theme_color_override("font_color", UiTokens.PAPIER)
	duree.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	th.add_child(duree)
	v.add_child(tete)
	var marge := MarginContainer.new()
	for c in [["left", 18], ["right", 18], ["top", 14], ["bottom", 18]]:
		marge.add_theme_constant_override("margin_" + c[0], c[1])
	v.add_child(marge)
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 8)
	marge.add_child(c)
	# Adversaires
	c.add_child(_titre_section("ADVERSAIRES"))
	boutons_adv = []
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", -2)
	for k in [1, 2, 3]:
		var b := _segment(str(k))
		b.pressed.connect(func():
			adversaires = k
			_maj_joueurs())
		seg.add_child(b)
		boutons_adv.append(b)
	c.add_child(seg)
	rivaux_box = HBoxContainer.new()
	rivaux_box.add_theme_constant_override("separation", 6)
	c.add_child(rivaux_box)
	# Difficulté
	c.add_child(_espace(4))
	c.add_child(_titre_section("DIFFICULTÉ"))
	var sd := HBoxContainer.new()
	sd.add_theme_constant_override("separation", -2)
	boutons_dif = []
	for k in 3:
		var b := _segment(["Facile", "Moyen", "Difficile"][k])
		b.tooltip_text = ["Des rivaux qui tâtonnent : les stratégies les plus faibles de l'étude",
			"Des rivaux sérieux : les stratégies du milieu du classement de l'étude",
			"Des rivaux redoutables : les meilleures stratégies apprises par l'étude"][k]
		b.pressed.connect(func():
			niveau = NIVEAUX[k]
			_maj_joueurs())
		sd.add_child(b)
		boutons_dif.append(b)
	c.add_child(sd)
	# Carte
	c.add_child(_espace(4))
	c.add_child(_titre_section("CARTE"))
	var hc := HBoxContainer.new()
	hc.add_theme_constant_override("separation", 12)
	var cadre := PanelContainer.new()
	var sc := StyleBoxFlat.new()
	sc.border_color = UiTokens.ENCRE
	sc.set_border_width_all(2)
	sc.set_corner_radius_all(8)
	sc.set_content_margin_all(2)
	cadre.add_theme_stylebox_override("panel", sc)
	apercu = TextureRect.new()
	apercu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	apercu.stretch_mode = TextureRect.STRETCH_SCALE
	apercu.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	apercu.custom_minimum_size = Vector2(120, 90)
	cadre.add_child(apercu)
	hc.add_child(cadre)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	champ_graine = LineEdit.new()
	champ_graine.custom_minimum_size.y = 40
	champ_graine.add_theme_font_override("font", UiTokens.police_mono(600))
	champ_graine.add_theme_font_size_override("font_size", 16)
	champ_graine.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	champ_graine.tooltip_text = "Même graine = même carte pour tous les joueurs."
	champ_graine.text_changed.connect(func(_t): attente_graine = 0.45)
	champ_graine.text_submitted.connect(func(_t): _valider_graine())
	cv.add_child(champ_graine)
	var autre := Composants.bouton("↻ Autre carte", "BoutonSecondaire")
	autre.custom_minimum_size.y = 34
	autre.pressed.connect(func(): _changer_carte(randi() % 1000000))
	cv.add_child(autre)
	hc.add_child(cv)
	c.add_child(hc)
	lbl_carte = Composants.label("")
	lbl_carte.add_theme_font_override("font", UiTokens.police_corps(600))
	lbl_carte.add_theme_font_size_override("font_size", 12)
	lbl_carte.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	c.add_child(lbl_carte)
	c.add_child(_espace(6))
	var signer := Composants.bouton("SIGNER LA PRISE DE POSTE ›", "BoutonPrincipal")
	signer.add_theme_font_override("font", UiTokens.police_titre())
	signer.add_theme_font_size_override("font_size", 20)
	signer.custom_minimum_size.y = 54
	signer.pressed.connect(func(): lancer.emit(false, graine, adversaires, niveau))
	c.add_child(signer)
	return p


func _titre_section(t: String) -> Label:
	var l := Composants.label(t)
	l.add_theme_font_override("font", UiTokens.police_titre())
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	return l


func _segment(t: String) -> Button:
	var b := Composants.bouton(t, "Onglet")
	b.toggle_mode = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 40
	return b


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") and champ_graine.has_focus():
		champ_graine.release_focus()
	elif e.is_action_pressed("ui_accept") and not champ_graine.has_focus() and get_viewport().gui_get_focus_owner() == null:
		bouton_jouer.pressed.emit()
		accept_event()


func _process(delta: float) -> void:
	if attente_graine > 0.0:
		attente_graine -= delta
		if attente_graine <= 0.0:
			_valider_graine()


func _valider_graine() -> void:
	attente_graine = -1.0
	var t := champ_graine.text.strip_edges()
	if t.is_valid_int() and int(t) != graine:
		_changer_carte(int(t))
	elif not t.is_valid_int():
		champ_graine.text = str(graine)


func _changer_carte(g: int) -> void:
	graine = g
	if champ_graine.text != str(g):
		champ_graine.text = str(g)
	var carte := MapGenerator.generate(donnees["buildings"], g)
	var img := _peindre(carte)
	var tex := ImageTexture.create_from_image(img)
	apercu.texture = tex
	# Résumé de la carte
	var compte := {}
	for y in carte.h:
		for x in carte.w:
			var tt := carte.get_t(x, y)
			compte[tt] = compte.get(tt, 0) + 1
	var n := float(carte.w * carte.h)
	lbl_carte.text = "Forêt %d\u00a0%% · eau %d\u00a0%% · roche %d\u00a0%%" % [
		roundi(100.0 * compte.get(GameMap.FORET, 0) / n), roundi(100.0 * compte.get(GameMap.EAU, 0) / n), roundi(100.0 * compte.get(GameMap.ROCHE, 0) / n)]


func _maj_joueurs() -> void:
	for k in boutons_adv.size():
		boutons_adv[k].button_pressed = k + 1 == adversaires
	for k in boutons_dif.size():
		boutons_dif[k].button_pressed = NIVEAUX[k] == niveau
	if note_jouer:
		note_jouer.text = "vous + %d IA" % adversaires
	if rivaux_box == null:
		return
	for c in rivaux_box.get_children():
		rivaux_box.remove_child(c)
		c.queue_free()
	var noms := ["PanZoo", "Safari Capital", "BioLand"]
	var pris: Array[String] = []
	for k in adversaires:
		rivaux_box.add_child(Composants.image_logo(Composants.logo_groupe(noms[k], true), Vector2(34, 34)))
		pris.append(noms[k])
	var l := Composants.label(", ".join(pris))
	l.add_theme_font_override("font", UiTokens.police_corps(600))
	l.add_theme_font_size_override("font_size", 13)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rivaux_box.add_child(l)


func _apparition() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)


# ---------------------------------------------------------------- peinture de la carte

func _peindre(m: GameMap) -> Image:
	var img := Image.create_empty(m.w * PX, m.h * PX, false, Image.FORMAT_RGBA8)
	for y in m.h:
		for x in m.w:
			var o := Vector2i(x * PX, y * PX)
			var t := m.get_t(x, y)
			var base: Color = TERRAIN.get(t, TERRAIN[GameMap.PRAIRIE])
			if t == GameMap.PRAIRIE and (x * 7 + y * 13) % 5 == 0:
				base = Color("74BE40")
			img.fill_rect(Rect2i(o, Vector2i(PX, PX)), base)
			match t:
				GameMap.FORET:
					img.fill_rect(Rect2i(o + Vector2i(0, 1), Vector2i(4, 4)), Color("1F5E22"))
					img.fill_rect(Rect2i(o + Vector2i(4, 3), Vector2i(4, 4)), Color("1F5E22"))
					img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(2, 2)), Color("6ABA48"))
					img.fill_rect(Rect2i(o + Vector2i(5, 3), Vector2i(2, 2)), Color("6ABA48"))
				GameMap.ROCHE:
					img.fill_rect(Rect2i(o + Vector2i(1, 2), Vector2i(3, 2)), Color("8E8A80"))
					img.fill_rect(Rect2i(o + Vector2i(3, 1), Vector2i(2, 1)), Color("D6D0C2"))
				GameMap.MONTAGNE:
					for r in 6:
						img.fill_rect(Rect2i(o + Vector2i(3 - r / 2, 1 + r), Vector2i(2 + r, 1)), Color("6E604F"))
					img.fill_rect(Rect2i(o + Vector2i(3, 1), Vector2i(2, 1)), Color("F4F4F0"))
				GameMap.EAU:
					var bord := false
					for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
						var q: Vector2i = Vector2i(x, y) + d
						if m.in_bounds(q.x, q.y) and m.get_t(q.x, q.y) != GameMap.EAU:
							bord = true
					if bord:
						img.fill_rect(Rect2i(o, Vector2i(PX, PX)), Color("3AB8D8"))
						img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(PX - 2, PX - 2)), Color("2B9AD2"))
					elif (x + 2 * y) % 5 == 0:
						img.fill_rect(Rect2i(o + Vector2i(1, 3), Vector2i(3, 1)), Color("6CC0F0"))
				GameMap.SABLE:
					if (x + y) % 2 == 0:
						img.fill_rect(Rect2i(o + Vector2i(2, 2), Vector2i(1, 1)), Color("D8B860"))
				GameMap.MINE_OR:
					img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(4, 4)), Color("6A5A48"))
					img.fill_rect(Rect2i(o + Vector2i(2, 2), Vector2i(2, 2)), Color("FFE04A"))
			if m.road.size() > 0 and m.road[m.idx(x, y)] != 0:
				img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(PX - 2, PX - 2)), Color("D6A866"))
	# Camp de départ
	var c := m.camp
	if c.size != Vector2i.ZERO:
		img.fill_rect(Rect2i(c.position * PX, c.size * PX), Color("D2A868"))
		img.fill_rect(Rect2i(c.position * PX + Vector2i(2, 2), c.size * PX - Vector2i(4, 4)), Color("E2BC7E"))
	return img


# ---------------------------------------------------------------- dessins

func _label(t: String, f: Font, taille: int, coul: Color, ombre := false) -> Label:
	var l := Label.new()
	l.text = t
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", coul)
	if ombre:
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 3)
	return l


func _espace(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _degrade(de: Vector2, a: Vector2, points: Array) -> TextureRect:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for p in points:
		offs.append(p[0])
		cols.append(p[1])
	g.offsets = offs
	g.colors = cols
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = de
	gt.fill_to = a
	gt.width = 256
	gt.height = 256
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _boite(bg: Color, bord: Color, ep: int, rayon: int, marge: int, ombre: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bord
	s.set_border_width_all(ep)
	s.set_corner_radius_all(rayon)
	s.set_content_margin_all(marge)
	s.anti_aliasing = true
	if ombre:
		s.shadow_color = Color(0, 0, 0, 0.4)
		s.shadow_size = 14
		s.shadow_offset = Vector2(0, 6)
	return s


func _anneau(rayon: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.border_color = SELECTION
	s.set_border_width_all(2)
	s.set_corner_radius_all(rayon + 4)
	s.set_expand_margin_all(4)
	s.anti_aliasing = true
	return s


func _theme() -> Theme:
	var t := Theme.new()
	if police_texte:
		t.default_font = police_texte
	t.default_font_size = 15
	t.set_color("font_color", "Label", TEXTE)
	t.set_color("font_color", "Button", TEXTE)
	t.set_color("font_hover_color", "Button", OR_CLAIR)
	t.set_color("font_focus_color", "Button", TEXTE)
	t.set_color("font_pressed_color", "Button", BOUTON_TEXTE)
	t.set_color("font_hover_pressed_color", "Button", BOUTON_TEXTE)
	t.set_stylebox("normal", "Button", _boite(Color(1, 1, 1, 0.07), Color(OR, 0.45), 1, 20, 8, false))
	t.set_stylebox("hover", "Button", _boite(Color(1, 1, 1, 0.13), OR, 1, 20, 8, false))
	t.set_stylebox("pressed", "Button", _boite(BOUTON_BAS, OR_SOMBRE, 1, 20, 8, false))
	t.set_stylebox("hover_pressed", "Button", _boite(BOUTON_HAUT, OR_SOMBRE, 1, 20, 8, false))
	t.set_stylebox("focus", "Button", _anneau(20))
	t.set_color("font_color", "LineEdit", TEXTE)
	t.set_color("caret_color", "LineEdit", SELECTION)
	t.set_color("selection_color", "LineEdit", Color(SELECTION, 0.35))
	t.set_stylebox("normal", "LineEdit", _boite(Color.WHITE, OR, 2, 8, 8, false))
	t.set_stylebox("focus", "LineEdit", _boite(Color.WHITE, SELECTION, 2, 8, 8, false))
	t.set_stylebox("panel", "TooltipPanel", _boite(PANNEAU_BAS, OR, 1, 6, 8, false))
	t.set_color("font_color", "TooltipLabel", TEXTE)
	return t


func _police_espacee(f: Font, esp: int) -> Font:
	if f == null:
		return null
	var v := FontVariation.new()
	v.base_font = f
	v.spacing_glyph = esp
	return v


## Polices du jeu (Marcellus SC pour les titres, Source Sans 3 variable pour le texte).
func _charger_polices() -> void:
	police_titre = UiTokens.police_titre()
	police_texte = UiTokens.police_corps(400)
	police_gras = UiTokens.police_corps(700)
