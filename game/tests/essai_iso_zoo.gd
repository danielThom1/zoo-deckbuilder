extends Node
## Photographie un zoo construit par une IA dans la vue isométrique, à deux distances, avec l'interface.
##   godot --path game --resolution 1600x900 -- --spectateur --seed=44 --jours=9 --iso --essai3d=res://tests/essai_iso_zoo.gd --essai-dossier=C:/chemin
var m


func _init(principal) -> void:
	m = principal


func _ready() -> void:
	_lancer.call_deferred()


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
	var zone: Rect2i = mt.ais[meilleur].zoo_rect
	var dossier := str(m.args.get("essai-dossier", "user://"))
	for vue in [["iso_3_zoo", 1.5], ["iso_4_zoo_pres", 3.0]]:
		m.camera.position = Vector2(zone.get_center()) * m.TILE
		m.camera.zoom = Vector2.ONE * float(vue[1])
		for k in 30:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dossier, vue[0]])
		print("image : ", vue[0])
	var t0 := Time.get_ticks_msec()
	var n0 := Engine.get_frames_drawn()
	await get_tree().create_timer(3.0).timeout
	print("images par seconde, zoo construit, ×1 : %.0f" % (float(Engine.get_frames_drawn() - n0) * 1000.0 / (Time.get_ticks_msec() - t0)))
	get_tree().quit()
