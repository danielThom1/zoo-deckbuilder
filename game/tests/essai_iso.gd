extends Node
## Joue un peu dans la vue isométrique avec de vrais événements de souris, photographie et mesure.
##   godot --path game --resolution 1600x900 -- --seed=7 --autodraft --iso --essai3d=res://tests/essai_iso.gd --essai-dossier=C:/chemin
var m
var dossier := ""


func _init(principal) -> void:
	m = principal


func _ready() -> void:
	dossier = str(m.args.get("essai-dossier", "user://"))
	_lancer.call_deferred()


func _images(n: int) -> void:
	for k in n:
		await get_tree().process_frame


func _photo(nom: String) -> void:
	await _images(4)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dossier, nom])
	print("image : ", nom)


func _clic(ecran_ui: Vector2, bouton: int) -> void:
	get_viewport().warp_mouse(ecran_ui)
	var ecran: Vector2 = ecran_ui * Vector2(get_window().size) / m.get_viewport_rect().size
	var mv := InputEventMouseMotion.new()
	mv.position = ecran
	mv.global_position = ecran
	Input.parse_input_event(mv)
	await _images(3)
	for appui in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = ecran
		e.global_position = ecran
		e.button_index = bouton
		e.pressed = appui
		Input.parse_input_event(e)
		await _images(3)


func _ecran_case(t: Vector2i) -> Vector2:
	var iso: Vue25D = m.iso
	var c := Vector3(t.x + 0.5, iso._h(t.x + 0.5, t.y + 0.5), t.y + 0.5)
	return iso.ecran_de(c)


func _lancer() -> void:
	while m.iso == null:
		await _images(1)
	await _images(10)
	var iso: Vue25D = m.iso
	var g: GameState = m.game
	# Aller-retour écran -> case
	var ok := 0
	var total := 0
	var c := g.map.camp.get_center()
	for dy in range(-12, 4, 3):
		for dx in range(-12, 13, 3):
			var t := c + Vector2i(dx, dy)
			var s: Vector2 = iso.sol(_ecran_case(t)) / m.TILE
			total += 1
			if Vector2i(floori(s.x), floori(s.y)) == t:
				ok += 1
	print("écran vers case : %d / %d exactes" % [ok, total])
	# Mobiliser, sélectionner en cliquant sur le personnage, envoyer au bois d'un clic droit
	m._set_speed(1.0)
	for card in g.hand.duplicate():
		if not card.is_action():
			m._cmd("deploy", [card])
	await _images(10)
	var w: GameState.Worker = g.workers[0]
	var ecran_w := iso.ecran_de(Vector3(w.pos.x, iso._h(w.pos.x, w.pos.y), w.pos.y)) + Vector2(0, -14)
	await _clic(ecran_w, MOUSE_BUTTON_LEFT)
	print("sélection au clic : ", m.selected.has(w), " (", m.selected.size(), " sélectionné)")
	if not m.selected.has(w):
		m.selected = [w]
	var foret := Vector2i(-1, -1)
	for r in range(3, 25):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := c + Vector2i(dx, dy)
				if foret.x < 0 and g.map.in_bounds(t.x, t.y) and g.map.extractible(t.x, t.y) == "bois":
					foret = t
	m.camera.position = Vector2(foret) * m.TILE
	await _images(5)
	await _clic(_ecran_case(foret), MOUSE_BUTTON_RIGHT)
	print("ordre au clic droit : ", w.task.get("type", "aucun"), " vers ", foret)
	# Poser une maison d'un clic gauche
	m.camera.position = Vector2(c) * m.TILE
	await _images(5)
	var nb := g.sites.size()
	m._set_build({"kind": "batiment", "def": g.building_def("maison")})
	var pose := c
	for r in range(3, 15):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if pose == c and g.placement_error("batiment", g.building_def("maison"), c + Vector2i(dx, dy)) == "":
					pose = c + Vector2i(dx, dy)
	var ecran_pose := _ecran_case(pose)
	await _clic(ecran_pose, MOUSE_BUTTON_LEFT)
	var sous_souris: Vector2i = m._hover_tile()
	print("souris : %s, case visée %s, case sous la souris %s" % [str(m.get_viewport().get_mouse_position()), str(pose), str(sous_souris)])
	print("pose au clic gauche : %d chantier de plus, sur %s, visé %s" % [g.sites.size() - nb, str(g.sites[-1].rect.position), str(pose)])
	if g.sites.size() == nb:
		var vise: Vector2 = iso.sol(ecran_pose) / m.TILE
		m._try_place(Vector2i(floori(vise.x), floori(vise.y)), true)
		print("pose à la case calculée depuis l'écran : %d chantier de plus" % (g.sites.size() - nb))
	m._set_build({})
	# Bascule aller-retour
	m.basculer_iso()
	await _images(5)
	await _photo("iso_2d_apres_retour")
	m.basculer_iso()
	await _images(20)
	# Vitesse d'affichage
	var t0 := Time.get_ticks_msec()
	var n0 := Engine.get_frames_drawn()
	await get_tree().create_timer(3.0).timeout
	print("images par seconde : %.0f" % (float(Engine.get_frames_drawn() - n0) * 1000.0 / (Time.get_ticks_msec() - t0)))
	await _photo("iso_1_debut")
	# Un zoo construit : la partie joue seule quelques jours
	for k in 40:
		m.mt.tick(0.5)
	await _photo("iso_2_chantier")
	get_tree().quit()
