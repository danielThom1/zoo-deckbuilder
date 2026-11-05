extends Node
## Contrôle de la caméra de l'essai : précision des clics et photos, sous plusieurs axes, en isométrique et en perspective.
##   godot --path game --resolution 1600x900 -- --spectateur --seed=44 --jours=9 --iso --essai3d=res://tests/essai_camera.gd --essai-dossier=C:/chemin
var m


func _init(principal) -> void:
	m = principal


func _ready() -> void:
	_lancer.call_deferred()


func _images(n: int) -> void:
	for k in n:
		await get_tree().process_frame


func _lancer() -> void:
	while m.iso == null:
		await get_tree().process_frame
	var mt: Match = m.mt
	var meilleur := 0
	for i in mt.players.size():
		if mt.players[i].animals.size() > mt.players[meilleur].animals.size():
			meilleur = i
	m._view_player(meilleur)
	m.speed = 1.0
	var g: GameState = m.game
	var iso: Vue25D = m.iso
	var zone: Rect2i = mt.ais[meilleur].zoo_rect
	var dossier := str(m.args.get("essai-dossier", "user://"))
	for v in [["cam_axe_camp", 0.0, 40.0, false, 2.0], ["cam_cote", 120.0, 35.0, false, 2.0], ["cam_3d", 25.0, 28.0, true, 2.2], ["cam_3d_pres", 200.0, 22.0, true, 4.0]]:
		iso.lacet = v[1]
		iso.tangage = v[2]
		iso.regler_perspective(v[3])
		m.camera.position = Vector2(zone.get_center()) * m.TILE
		m.camera.zoom = Vector2.ONE * float(v[4])
		await _images(30)
		var ok := 0
		var total := 0
		for dy in range(0, zone.size.y, 2):
			for dx in range(0, zone.size.x, 2):
				var t := zone.position + Vector2i(dx, dy)
				var e: Vector2 = iso.ecran_de(Vector3(t.x + 0.5, iso._h(t.x + 0.5, t.y + 0.5), t.y + 0.5))
				var s: Vector2 = iso.sol(e) / m.TILE
				total += 1
				if Vector2i(floori(s.x), floori(s.y)) == t:
					ok += 1
		print("%s : écran vers case %d / %d" % [v[0], ok, total])
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dossier, v[0]])
	var t0 := Time.get_ticks_msec()
	var n0 := Engine.get_frames_drawn()
	await get_tree().create_timer(3.0).timeout
	print("images par seconde en 3D : %.0f" % (float(Engine.get_frames_drawn() - n0) * 1000.0 / (Time.get_ticks_msec() - t0)))
	print("sans erreur, ", g.sites.size(), " chantiers")
	get_tree().quit()
