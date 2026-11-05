class_name Reportage
extends Control
## Carnet de reportage du Journaliste : le parc rival sous brouillard de guerre, ce qu'on y voit, et les coups possibles.
## Ne touche pas à la partie : tout passe par les ordres du joueur (_cmd), pour le multijoueur.

const TAILLE_CARTE := 640.0
const COULEURS := {"Prairie": Color("7DB24A"), "Foret": Color("2F6B3A"), "Eau": Color("3F8FD0"), "Roche": Color("8A8F96"), "Sable": Color("DCC48A"),
	"Montagne": Color("5A5560"), "Mine": Color("C8A020")}
const BROUILLARD := Color("16222E")

var main: Node
var g: GameState
var w: GameState.Worker
var carte: Control
var droite: VBoxContainer
var image: Image
var texture: ImageTexture
var _temps := 0.0
var _signature := ""


func _init(m: Node, jeu: GameState, ouvrier: GameState.Worker) -> void:
	main = m
	g = jeu
	w = ouvrier


func _ready() -> void:
	theme = UiTokens.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var f := Composants.fenetre(Vector2(1120, 0), "Journaliste", "Carnet de reportage", queue_free)
	add_child(f["racine"])
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	f["corps"].add_child(h)
	carte = Control.new()
	carte.custom_minimum_size = Vector2(TAILLE_CARTE, TAILLE_CARTE)
	carte.draw.connect(_dessiner)
	carte.gui_input.connect(_clic_carte)
	carte.mouse_default_cursor_shape = Control.CURSOR_CROSS
	h.add_child(carte)
	droite = VBoxContainer.new()
	droite.custom_minimum_size = Vector2(390, 0)
	droite.add_theme_constant_override("separation", 8)
	h.add_child(droite)
	_refaire_droite()


func _process(delta: float) -> void:
	_temps += delta
	if _temps < 0.25:
		return
	_temps = 0.0
	if w == null or not g.workers.has(w):
		queue_free()
		return
	_maj_image()
	carte.queue_redraw()
	_refaire_droite()


func _rival() -> GameState:
	return null if w.reportage.is_empty() else g.mt.players[int(w.reportage["cible"])]


func _maj_image() -> void:
	var rival := _rival()
	if rival == null:
		return
	if image == null or image.get_width() != rival.map.w:
		image = Image.create(rival.map.w, rival.map.h, false, Image.FORMAT_RGB8)
	var vu: Dictionary = g.vus.get(int(w.reportage["cible"]), {})
	image.fill(BROUILLARD)
	for t in vu:
		var nom: String = GameMap.TERRAINS[rival.map.get_t(t.x, t.y)]
		var c: Color = COULEURS.get(nom, COULEURS["Prairie"])
		if rival.map.road[rival.map.idx(t.x, t.y)]:
			c = Color("B89A6A")
		var s := rival.site_at(t)
		if s != null:
			c = Color("F4F0E4") if s.def_id() == "cloture" else (Color("8A5A2A") if s.def_id() == "enclos" else Color("E06A5A"))
		image.set_pixelv(t, c)
	for a in rival.animals:
		for t in a.tiles:
			if vu.has(t):
				image.set_pixelv(t, Color("F2C230"))
	if texture == null:
		texture = ImageTexture.create_from_image(image)
	else:
		texture.update(image)


func _dessiner() -> void:
	var rival := _rival()
	if rival == null or texture == null:
		carte.draw_rect(Rect2(Vector2.ZERO, carte.size), BROUILLARD)
		return
	var k := TAILLE_CARTE / rival.map.w
	carte.draw_texture_rect(texture, Rect2(Vector2.ZERO, Vector2.ONE * TAILLE_CARTE), false)
	for o in g.report_visibles(w):
		carte.draw_circle(o.pos * k, k * 0.8, UiTokens.ORANGE)
		carte.draw_arc(o.pos * k, k * 0.8, 0.0, TAU, 16, UiTokens.ENCRE, 1.5)
	var pos: Vector2 = w.reportage["pos"]
	var rayon := float(g.data["buildings"]["presse"]["rayon_vue"])
	carte.draw_arc(pos * k, rayon * k, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 2.0)
	carte.draw_circle(pos * k, k * 1.1, UiTokens.SELECTION)
	carte.draw_arc(pos * k, k * 1.1, 0.0, TAU, 16, UiTokens.ENCRE, 2.0)
	var but: Vector2 = w.reportage["but"]
	carte.draw_line(pos * k, but * k, Color(1, 1, 1, 0.35), 1.5)


func _clic_carte(e: InputEvent) -> void:
	var rival := _rival()
	if rival != null and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		main._cmd("report_goto", [w, Vector2i(e.position / (TAILLE_CARTE / rival.map.w))])


## Le panneau de droite n'est refait que si son contenu change (sinon les boutons perdent le clic).
func _refaire_droite() -> void:
	var P: Dictionary = g.data["buildings"]["presse"]
	var rival := _rival()
	var visibles := g.report_visibles(w)
	var vus_animaux: Array = []
	if rival != null:
		var vu: Dictionary = g.vus.get(int(w.reportage["cible"]), {})
		vus_animaux = rival.animals.filter(func(a): return a.tiles.any(func(t): return vu.has(t)))
	var sig := "%s|%s|%s|%s|%d" % [str(int(w.reportage.get("cible", -1))), str(visibles.map(func(o): return o.card.id)),
		str(vus_animaux.map(func(a): return a.def["id"])), "%s%s" % [g.article_error(w), g.accuse_error(w, -1)], int(g.money)]
	if sig == _signature:
		return
	_signature = sig
	for c in droite.get_children():
		droite.remove_child(c)
		c.queue_free()
	droite.add_child(_texte("%s, %s. Choisissez un parc, puis cliquez sur la carte pour diriger le reportage." % [w.card.nom, g.job_name(w.card)]))
	droite.add_child(Composants.titre_section("Parc visité"))
	var noms := HBoxContainer.new()
	noms.add_theme_constant_override("separation", 6)
	droite.add_child(noms)
	for i in g.mt.players.size():
		if i == g.index:
			continue
		var b := Composants.bouton(str(g.mt.names[i]).replace(" Holdings", ""), "BoutonPrincipal" if rival == g.mt.players[i] else "BoutonSecondaire")
		b.add_theme_font_size_override("font_size", 13)
		b.custom_minimum_size.y = 36
		b.pressed.connect(func(): main._cmd("report_start", [w, i]))
		noms.add_child(b)
	if rival != null:
		droite.add_child(_texte("Réputation %d · %d collaborateurs · publicité ×%s" % [rival.reputation(), rival.all_employees().size(), ("%.2f" % rival.publicity_mult()).replace(".", ",")]))
		droite.add_child(_texte("Animaux repérés : %s" % (", ".join(vus_animaux.map(func(a): return a.def["nom"])) if not vus_animaux.is_empty() else "aucun pour l'instant")))
		droite.add_child(Composants.titre_section("Article"))
		var infos_article := "Visiteurs de ce rival ×%s pendant %d jours. Un article par jour." % [str(P["mult_article"]).replace(".", ","), int(P["jours_article"])]
		var err_art := g.article_error(w)
		var art: Button
		if err_art != "":
			art = Composants.bouton_indisponible(err_art.left(44), err_art)
		else:
			art = Composants.bouton("Publier un article · %d" % int(P["article"]), "BoutonPrincipal")
			art.pressed.connect(func(): main._cmd("publish_article", [w]))
			art.tooltip_text = infos_article
		art.custom_minimum_size.y = 40
		droite.add_child(art)
		droite.add_child(Composants.titre_section("Accusation"))
		droite.add_child(_texte("En vue : accusez un collaborateur et sa direction le licenciera sans vérifier. Un légendaire emporte son bonus de réputation."))
		var liste := VBoxContainer.new()
		liste.add_theme_constant_override("separation", 4)
		droite.add_child(liste)
		if visibles.is_empty():
			liste.add_child(_texte("Personne en vue."))
		for o in visibles:
			var err := g.accuse_error(w, o.card.id)
			var txt := "Accuser %s (%s, N%d) · %d" % [o.card.nom, rival.job_name(o.card), o.card.niveau, int(P["accusation"])]
			var b2: Button = Composants.bouton_indisponible(txt, err) if err != "" else Composants.bouton(txt, "BoutonSecondaire")
			b2.add_theme_font_size_override("font_size", 13)
			b2.custom_minimum_size.y = 36
			var id: int = o.card.id
			if err == "":
				b2.pressed.connect(func(): main._cmd("accuse_worker", [w, id]))
			liste.add_child(b2)


func _texte(t: String) -> Label:
	var l := Composants.paragraphe(t, 14, UiTokens.TEXTE_2)
	l.custom_minimum_size.x = 380
	return l
