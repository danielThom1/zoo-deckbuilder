class_name MenuPrincipal
extends Control
## Menu principal « Émeraude » : la vraie carte de la graine choisie en fond (floutée, qui dérive lentement),
## titre gravé, boutons d'action à gauche, réglages de la partie à droite avec aperçu de la carte.
## Ne dépend que de GameData, MapGenerator, GameMap et des polices de UiTokens.

signal lancer(spectateur: bool, graine: int, adversaires: int, difficile: bool)
signal continuer
signal tutoriel
signal multijoueur

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

var graine := 0
var adversaires := 3
var difficile := false  # IA difficile : stratégies apprises par l'IA évolutive
var police_titre: Font
var police_texte: Font
var police_gras: Font

var fond: TextureRect
var apercu: TextureRect
var champ_graine: LineEdit
var lbl_carte: Label
var lbl_joueurs: Label
var sous_titre_jouer: Label
var sous_titre_regarder: Label
var jetons_ia: Array = []
var nuages: Control
var bouton_jouer: Button
var temps := 0.0
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
	# Fond : la carte, en plus grand que l'écran pour pouvoir dériver
	fond = TextureRect.new()
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fond.size = Vector2(1900, 1069)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float flou = 0.0;
uniform float sombre = 1.0;
uniform float sature = 1.12;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec3 g = vec3(dot(c.rgb, vec3(0.299, 0.587, 0.114)));
	COLOR = vec4(mix(g, c.rgb, sature) * sombre, 1.0);
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	fond.material = mat
	add_child(fond)

	# Ombres de nuages qui passent sur la carte
	nuages = Control.new()
	nuages.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nuages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nuages.draw.connect(_dessiner_nuages)
	add_child(nuages)

	# Voiles : dégradé émeraude à gauche (lisibilité), vignettage haut et bas
	add_child(_degrade(Vector2(0, 0), Vector2(1, 0), [
		[0.0, Color(PANNEAU_BAS, 0.97)], [0.30, Color(PANNEAU_BAS, 0.90)], [0.50, Color(PANNEAU_BAS, 0.45)], [0.72, Color(PANNEAU_BAS, 0.0)]]))
	add_child(_degrade(Vector2(0, 0), Vector2(0, 1), [
		[0.0, Color(PANNEAU_BAS, 0.55)], [0.18, Color(PANNEAU_BAS, 0.0)], [0.78, Color(PANNEAU_BAS, 0.0)], [1.0, Color(PANNEAU_BAS, 0.75)]]))

	# --- Colonne de gauche
	var col := VBoxContainer.new()
	col.name = "Colonne"
	col.position = Vector2(96, 16)
	col.custom_minimum_size = Vector2(440, 0)
	col.add_theme_constant_override("separation", 0)
	add_child(col)

	col.add_child(Composants.image_logo(load("res://assets/bd/logos/zoolife.png"), Vector2(410, 274)))
	col.add_child(_espace(10))
	var accroche := _label("Bâtissez le zoo le plus rentable de la vallée,\navec le personnel que vous méritez.", police_texte, 18, TEXTE_2)
	col.add_child(accroche)
	col.add_child(_espace(12))
	var filet := Control.new()
	filet.custom_minimum_size = Vector2(380, 14)
	filet.draw.connect(_dessiner_filet.bind(filet))
	col.add_child(filet)
	col.add_child(_espace(26))

	var boutons := VBoxContainer.new()
	boutons.add_theme_constant_override("separation", 8)
	col.add_child(boutons)
	var b_jouer := _bouton_menu("Jouer contre l'IA", "", "jouer", true)
	sous_titre_jouer = b_jouer.get_meta("sous_titre")
	b_jouer.pressed.connect(func(): lancer.emit(false, graine, adversaires, difficile))
	boutons.add_child(b_jouer)
	var sauvee := Sauvegarde.resume()
	if not sauvee.is_empty():
		var b_suite := _bouton_menu("Continuer", "Partie sauvegardée : début du jour %d, %d joueurs" % [sauvee["jour"], sauvee["joueurs"]], "jouer", false)
		b_suite.pressed.connect(func(): continuer.emit())
		boutons.add_child(b_suite)
	var b_regarder := _bouton_menu("Regarder des IA jouer", "4 IA aux stratégies différentes, en accéléré ×8", "oeil", false)
	sous_titre_regarder = b_regarder.get_meta("sous_titre")
	b_regarder.pressed.connect(func(): lancer.emit(true, graine, 4, difficile))
	boutons.add_child(b_regarder)
	var b_multi := _bouton_menu("Multijoueur", "Par Internet, de 2 à 4 joueurs : héberger ou rejoindre", "jouer", false)
	b_multi.pressed.connect(func(): multijoueur.emit())
	boutons.add_child(b_multi)
	var b_tuto := _bouton_menu("Tutoriel", "Une première partie guidée par votre nouvel employeur", "oeil", false)
	b_tuto.pressed.connect(func(): tutoriel.emit())
	boutons.add_child(b_tuto)
	var b_aide := _bouton_menu("Règles et glossaire", "Comment jouer, et tout ce qui existe dans le jeu", "oeil", false)
	b_aide.pressed.connect(func(): add_child(Aide.new(donnees)))
	boutons.add_child(b_aide)
	var b_quitter := _bouton_menu("Quitter", "Retour au bureau", "sortie", false)
	b_quitter.pressed.connect(func(): get_tree().quit())
	boutons.add_child(b_quitter)
	bouton_jouer = b_jouer
	# Affiche d'entreprise : un slogan différent à chaque ouverture
	var slogans: Array = donnees["hubert"]["slogans"]
	var affiche := Label.new()
	affiche.text = slogans[randi() % slogans.size()]
	affiche.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	affiche.custom_minimum_size = Vector2(420, 0)
	affiche.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	affiche.add_theme_font_override("font", UiTokens.police_corps(700))
	affiche.add_theme_font_size_override("font_size", 15)
	affiche.add_theme_color_override("font_color", UiTokens.ENCRE)
	var affiche_style := StyleBoxFlat.new()
	affiche_style.bg_color = UiTokens.BOUTON_HAUT
	affiche_style.border_color = UiTokens.ENCRE
	affiche_style.set_border_width_all(3)
	affiche_style.content_margin_left = 12
	affiche_style.content_margin_right = 12
	affiche_style.content_margin_top = 6
	affiche_style.content_margin_bottom = 6
	affiche.add_theme_stylebox_override("normal", affiche_style)
	col.add_child(_espace(14))
	col.add_child(affiche)

	var pied := _label("Prototype jouable · Godot 4.7 · Entrée pour jouer", police_texte, 13, Color(TEXTE_2, 0.7))
	pied.name = "Pied"
	pied.position = Vector2(96, 900 - 52)
	add_child(pied)

	# --- Carte de réglages (en bas à droite)
	add_child(_carte_reglages())


func _carte_reglages() -> Control:
	var carte := PanelContainer.new()
	carte.name = "Reglages"
	carte.add_theme_stylebox_override("panel", _boite(Color(PANNEAU, 0.95), OR, 2, 12, 0, true))
	carte.custom_minimum_size = Vector2(440, 0)
	carte.position = Vector2(1600 - 64 - 440, 0)  # y calé après mise en page
	carte.resized.connect(func(): carte.position.y = 900 - 64 - carte.size.y)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	carte.add_child(v)

	var tete := PanelContainer.new()
	var st := _boite(ENTETE, OR, 0, 0, 0, false)
	st.border_width_bottom = 1
	st.corner_radius_top_left = 10
	st.corner_radius_top_right = 10
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	tete.add_theme_stylebox_override("panel", st)
	v.add_child(tete)
	var th := HBoxContainer.new()
	tete.add_child(th)
	var t := _label("NOUVELLE PARTIE", _police_espacee(police_titre, 2), 21, TEXTE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(t)
	lbl_joueurs = _label("", police_texte, 14, Color.WHITE)
	th.add_child(lbl_joueurs)

	var m := MarginContainer.new()
	for c in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + c, 16)
	v.add_child(m)
	var corps := VBoxContainer.new()
	corps.add_theme_constant_override("separation", 10)
	m.add_child(corps)

	# Adversaires
	corps.add_child(_label("Adversaires IA", police_texte, 14, TEXTE_2))
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", 8)
	corps.add_child(seg)
	var groupe := ButtonGroup.new()
	for n in [1, 2, 3]:
		var b := Button.new()
		b.text = str(n)
		b.toggle_mode = true
		b.button_group = groupe
		b.button_pressed = n == adversaires
		b.custom_minimum_size = Vector2(0, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", police_gras)
		b.add_theme_font_size_override("font_size", 17)
		b.toggled.connect(func(on: bool):
			if on:
				adversaires = n
				_maj_joueurs())
		seg.add_child(b)

	# Difficulté : IA normales, ou IA difficiles (stratégies apprises par l'IA évolutive)
	corps.add_child(_label("Difficulté", police_texte, 14, TEXTE_2))
	var segd := HBoxContainer.new()
	segd.add_theme_constant_override("separation", 8)
	corps.add_child(segd)
	var groupe_d := ButtonGroup.new()
	for opt in [["Normale", false, "IA aux stratégies écrites à la main"], ["Difficile", true, "IA entraînées par évolution : elles ont appris en jouant des centaines de parties"]]:
		var bd := Button.new()
		bd.text = opt[0]
		bd.tooltip_text = opt[2]
		bd.toggle_mode = true
		bd.button_group = groupe_d
		bd.button_pressed = opt[1] == difficile
		bd.custom_minimum_size = Vector2(0, 40)
		bd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bd.add_theme_font_override("font", police_gras)
		bd.add_theme_font_size_override("font_size", 17)
		var val: bool = opt[1]
		bd.toggled.connect(func(on: bool):
			if on:
				difficile = val
				_maj_joueurs())
		segd.add_child(bd)

	var jetons := HBoxContainer.new()
	jetons.add_theme_constant_override("separation", 8)
	corps.add_child(jetons)
	for i in 4:
		var j := _jeton_joueur("Vous" if i == 0 else "IA %d" % i, JOUEURS[i])
		jetons.add_child(j)
		if i > 0:
			jetons_ia.append(j)

	corps.add_child(_espace(4))
	corps.add_child(_label("Carte", police_texte, 14, TEXTE_2))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	corps.add_child(ligne)

	var cadre := PanelContainer.new()
	cadre.add_theme_stylebox_override("panel", _boite(PANNEAU_BAS, OR, 2, 6, 3, false))
	ligne.add_child(cadre)
	apercu = TextureRect.new()
	apercu.custom_minimum_size = Vector2(128, 128)
	apercu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	apercu.stretch_mode = TextureRect.STRETCH_SCALE
	apercu.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cadre.add_child(apercu)

	var droite := VBoxContainer.new()
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	droite.add_theme_constant_override("separation", 8)
	ligne.add_child(droite)
	var rg := HBoxContainer.new()
	rg.add_theme_constant_override("separation", 8)
	droite.add_child(rg)
	var lg := _label("Graine", police_texte, 14, TEXTE)
	lg.custom_minimum_size = Vector2(52, 0)
	rg.add_child(lg)
	champ_graine = LineEdit.new()
	champ_graine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	champ_graine.custom_minimum_size = Vector2(0, 36)
	champ_graine.add_theme_font_override("font", police_gras)
	champ_graine.add_theme_font_size_override("font_size", 16)
	champ_graine.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	champ_graine.tooltip_text = "Même graine = même carte pour tous les joueurs."
	champ_graine.text_changed.connect(func(_t): attente_graine = 0.45)
	champ_graine.text_submitted.connect(func(_t): _valider_graine())
	rg.add_child(champ_graine)

	var de := Button.new()
	de.text = "Nouvelle carte"
	de.custom_minimum_size = Vector2(0, 38)
	de.add_theme_font_override("font", police_gras)
	de.add_theme_font_size_override("font_size", 15)
	de.icon = _icone_de()
	de.pressed.connect(func(): _changer_carte(randi() % 1000000))
	droite.add_child(de)
	lbl_carte = _label("", police_texte, 13, TEXTE_2)
	lbl_carte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_carte.custom_minimum_size = Vector2(240, 0)
	droite.add_child(lbl_carte)

	_maj_joueurs()
	return carte


func _bouton_menu(titre: String, sous_titre: String, icone: String, principal: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(420, 62)
	b.focus_mode = Control.FOCUS_ALL
	var fond_n := Color(PANNEAU_BAS, 0.78)
	if principal:
		b.add_theme_stylebox_override("normal", _boite(BOUTON_BAS, OR_SOMBRE, 2, 35, 0, true))
		b.add_theme_stylebox_override("hover", _boite(BOUTON_HAUT, OR_CLAIR, 2, 35, 0, true))
		b.add_theme_stylebox_override("pressed", _boite(BOUTON_BAS, OR_SOMBRE, 2, 35, 0, true))
		b.add_theme_stylebox_override("focus", _anneau(35))
	else:
		b.add_theme_stylebox_override("normal", _boite(fond_n, Color(OR, 0.75), 2, 35, 0, false))
		b.add_theme_stylebox_override("hover", _boite(Color("FFF4D6"), OR, 2, 35, 0, false))
		b.add_theme_stylebox_override("pressed", _boite(PANNEAU_BAS, OR_CLAIR, 2, 35, 0, false))
		b.add_theme_stylebox_override("focus", _anneau(35))
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -20
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(46, 46)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.draw.connect(_dessiner_icone.bind(ic, icone, principal))
	h.add_child(ic)
	var txt := VBoxContainer.new()
	txt.alignment = BoxContainer.ALIGNMENT_CENTER
	txt.add_theme_constant_override("separation", 0)
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(txt)
	var coul_t := BOUTON_TEXTE if principal else TEXTE
	var coul_s := Color(BOUTON_TEXTE, 0.72) if principal else TEXTE_2
	var lt := _label(titre, _police_espacee(police_titre, 1), 23, coul_t)
	lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt.add_child(lt)
	var ls := _label(sous_titre, police_texte if not principal else police_gras, 14, coul_s)
	ls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt.add_child(ls)
	b.set_meta("sous_titre", ls)
	# Survol : léger glissement vers la droite
	b.pivot_offset = Vector2(0, 35)
	b.mouse_entered.connect(func(): _survol(b, true))
	b.mouse_exited.connect(func(): _survol(b, false))
	b.focus_entered.connect(func(): _survol(b, true))
	b.focus_exited.connect(func(): _survol(b, false))
	return b


func _survol(b: Button, actif: bool) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2.ONE * (1.025 if actif else 1.0), 0.14)


func _jeton_joueur(nom: String, coul: Color) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _boite(Color(1, 1, 1, 0.07), Color(coul, 0.6), 1, 8, 6, false))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	var pastille := Control.new()
	pastille.custom_minimum_size = Vector2(16, 16)
	pastille.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pastille.draw.connect(func():
		pastille.draw_circle(Vector2(8, 8), 8, Color(1, 1, 1, 0.9))
		pastille.draw_circle(Vector2(8, 8), 6.5, coul))
	h.add_child(pastille)
	h.add_child(_label(nom, police_gras, 14, TEXTE))
	return p


# ---------------------------------------------------------------- logique

func _process(delta: float) -> void:
	temps += delta
	# Dérive lente de la carte (aller-retour) et léger zoom
	var d := Vector2(sin(temps * 0.035) * 120.0, cos(temps * 0.027) * 80.0)
	var z := 1.0 + 0.04 * sin(temps * 0.05)
	fond.size = Vector2(1900, 1069) * z
	fond.position = Vector2(800, 450) - fond.size / 2.0 + d * 0.6 + Vector2(60, 0)
	nuages.queue_redraw()
	if attente_graine > 0.0:
		attente_graine -= delta
		if attente_graine <= 0.0:
			_valider_graine()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") and champ_graine.has_focus():
		champ_graine.release_focus()
	elif e.is_action_pressed("ui_accept") and not champ_graine.has_focus() and get_viewport().gui_get_focus_owner() == null:
		bouton_jouer.pressed.emit()
		accept_event()


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
	var img_flou := img.duplicate()
	img_flou.generate_mipmaps()
	# Fond : paysage illustré (style BD) ; la carte de la graine reste visible dans l'aperçu
	if fond.texture == null:
		fond.texture = load(FOND_ILLUSTRE) if ResourceLoader.exists(FOND_ILLUSTRE) else ImageTexture.create_from_image(img_flou)
	# Résumé de la carte
	var compte := {}
	for y in carte.h:
		for x in carte.w:
			var tt := carte.get_t(x, y)
			compte[tt] = compte.get(tt, 0) + 1
	var n := float(carte.w * carte.h)
	lbl_carte.text = "Forêt %d\u00a0%% · eau %d\u00a0%% · roche %d\u00a0%%\n%d\u00a0gisement%s d'or · %d\u00a0×\u00a0%d cases" % [
		roundi(100.0 * compte.get(GameMap.FORET, 0) / n), roundi(100.0 * compte.get(GameMap.EAU, 0) / n),
		roundi(100.0 * compte.get(GameMap.ROCHE, 0) / n), carte.golds.size(), "s" if carte.golds.size() > 1 else "", carte.w, carte.h]


func _maj_joueurs() -> void:
	for i in jetons_ia.size():
		var actif := i < adversaires
		jetons_ia[i].modulate = Color(1, 1, 1, 1.0 if actif else 0.3)
	lbl_joueurs.text = "%d joueurs" % (adversaires + 1)
	if sous_titre_jouer:
		sous_titre_jouer.text = "Vous et %d IA%s · draft puis partie complète" % [adversaires, " difficiles" if difficile else ""]
	if sous_titre_regarder:
		sous_titre_regarder.text = "4 IA %s, en accéléré ×8" % ("difficiles (stratégies apprises)" if difficile else "aux stratégies différentes")


func _apparition() -> void:
	var col: Control = get_node("Colonne")
	var reg: Control = get_node("Reglages")
	var pied: Control = get_node("Pied")
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.5)
	col.position.x -= 40
	tw.tween_property(col, "position:x", col.position.x + 40, 0.7)
	reg.modulate.a = 0.0
	tw.tween_property(reg, "modulate:a", 1.0, 0.6).set_delay(0.25)
	pied.modulate.a = 0.0
	tw.tween_property(pied, "modulate:a", 1.0, 0.6).set_delay(0.5)


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

func _dessiner_medaillon(c: Control) -> void:
	var ctr := c.size / 2.0
	c.draw_circle(ctr + Vector2(0, 5), 56, Color(0, 0, 0, 0.35))
	c.draw_circle(ctr, 56, OR_SOMBRE)
	c.draw_circle(ctr, 54, OR)
	c.draw_circle(ctr, 49, OR_SOMBRE)
	c.draw_circle(ctr, 47, ENTETE)
	c.draw_circle(ctr + Vector2(-8, -10), 34, Color(1, 1, 1, 0.04))
	c.draw_arc(ctr, 42, 0, TAU, 64, Color(OR, 0.35), 1.0, true)
	# Patte
	var p := OR
	c.draw_set_transform(ctr + Vector2(0, 10), 0.0, Vector2(1.18, 1.0))
	c.draw_circle(Vector2.ZERO, 13, p)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for d in [Vector2(-19, -9), Vector2(-7, -21), Vector2(7, -21), Vector2(19, -9)]:
		c.draw_set_transform(ctr + d, 0.0, Vector2(0.85, 1.1))
		c.draw_circle(Vector2.ZERO, 6.5, p)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _dessiner_filet(c: Control) -> void:
	var y := c.size.y / 2.0
	var w := c.size.x
	c.draw_line(Vector2(0, y), Vector2(w * 0.5 - 14, y), Color(OR, 0.75), 1.5, true)
	c.draw_line(Vector2(w * 0.5 + 14, y), Vector2(w, y), Color(OR, 0.75), 1.5, true)
	var cx := w * 0.5
	c.draw_colored_polygon(PackedVector2Array([Vector2(cx, y - 6), Vector2(cx + 7, y), Vector2(cx, y + 6), Vector2(cx - 7, y)]), OR)
	c.draw_circle(Vector2(0, y), 2.5, OR)
	c.draw_circle(Vector2(w, y), 2.5, OR)


func _dessiner_icone(c: Control, nom: String, principal: bool) -> void:
	var ctr := c.size / 2.0
	var r := c.size.x / 2.0
	var fond_c := Color(BOUTON_TEXTE, 0.12) if principal else Color(OR, 0.14)
	var coul_trait := BOUTON_TEXTE if principal else OR_CLAIR
	c.draw_circle(ctr, r, fond_c)
	c.draw_arc(ctr, r - 1, 0, TAU, 48, Color(coul_trait, 0.5), 1.5, true)
	match nom:
		"jouer":
			c.draw_colored_polygon(PackedVector2Array([ctr + Vector2(-6, -10), ctr + Vector2(11, 0), ctr + Vector2(-6, 10)]), coul_trait)
		"oeil":
			var pts := PackedVector2Array()
			for i in 17:
				var a := PI * i / 16.0
				pts.append(ctr + Vector2(-cos(a) * 13, -sin(a) * 8))
			for i in 17:
				var a := PI * i / 16.0
				pts.append(ctr + Vector2(cos(a) * 13, sin(a) * 8))
			pts.append(pts[0])
			c.draw_polyline(pts, coul_trait, 2.0, true)
			c.draw_circle(ctr, 4.5, coul_trait)
		"sortie":
			c.draw_polyline(PackedVector2Array([ctr + Vector2(2, -11), ctr + Vector2(-9, -11), ctr + Vector2(-9, 11), ctr + Vector2(2, 11)]), coul_trait, 2.0, true)
			c.draw_line(ctr + Vector2(-2, 0), ctr + Vector2(12, 0), coul_trait, 2.0, true)
			c.draw_polyline(PackedVector2Array([ctr + Vector2(7, -5), ctr + Vector2(12, 0), ctr + Vector2(7, 5)]), coul_trait, 2.0, true)


func _dessiner_nuages() -> void:
	for i in 5:
		var vit := 9.0 + i * 3.0
		var x := fmod(temps * vit + i * 420.0, 2200.0) - 300.0
		var y := 140.0 + fmod(i * 233.0, 640.0)
		var rr := 110.0 + (i % 3) * 50.0
		for k in 3:
			nuages.draw_set_transform(Vector2(x + k * rr * 0.6, y + (k % 2) * 18.0), 0.0, Vector2(1.6, 0.8))
			nuages.draw_circle(Vector2.ZERO, rr * (0.8 + 0.15 * k), Color(0.02, 0.08, 0.1, 0.055))
	nuages.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _icone_de() -> ImageTexture:
	var img := Image.create_empty(20, 20, false, Image.FORMAT_RGBA8)
	for y in 20:
		for x in 20:
			var dx: float = max(abs(x - 9.5) - 6.0, 0.0)
			var dy: float = max(abs(y - 9.5) - 6.0, 0.0)
			if Vector2(dx, dy).length() < 3.0:
				img.set_pixel(x, y, OR_CLAIR)
	for p in [Vector2i(6, 6), Vector2i(13, 13), Vector2i(10, 10), Vector2i(13, 6), Vector2i(6, 13)]:
		img.fill_rect(Rect2i(p - Vector2i(1, 1), Vector2i(3, 3)), PANNEAU_BAS)
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- utilitaires

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
