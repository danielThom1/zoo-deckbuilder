extends Node
## Personnages cachés en isométrique : au camp (dans l'emprise, ils doivent passer devant), et derrière le camp
## (une silhouette doit les montrer). Photos sous plusieurs angles, puis en perspective.
##   godot --path game --resolution 1600x900 -- --seed=7 --autodraft --iso --essai3d=res://tests/essai_caches.gd --essai-dossier=C:/chemin
var m


func _init(principal) -> void:
	m = principal


func _ready() -> void:
	_lancer.call_deferred()


func _lancer() -> void:
	while m.iso == null:
		await get_tree().process_frame
	for k in 30:
		await get_tree().process_frame
	var g: GameState = m.game
	var iso: Vue25D = m.iso
	var dossier := str(m.args.get("essai-dossier", "user://"))
	var camp: Rect2i = g.map.camp
	var cartes: Array = g.hand.filter(func(c): return not c.is_action())
	for c in cartes:
		m._cmd("deploy", [c])
	m.selected = []
	m._set_speed(0.0)
	var ws: Array = cartes.map(func(c): return g.worker_of(c))
	# Deux dans le camp, un juste derrière (côté opposé à la caméra à 45°), le dernier à côté
	var centre := Vector2(camp.get_center())
	var places := [centre + Vector2(-0.5, 0.2), centre + Vector2(0.8, -0.6), Vector2(camp.position) - Vector2(0.6, 0.6), Vector2(camp.end) + Vector2(0.5, -1.5)]
	for i in ws.size():
		ws[i].pos = places[i % places.size()]
		ws[i].task = {}
	for v in [["cache_45", 45.0, false], ["cache_0", 0.0, false], ["cache_135", 135.0, false], ["cache_3d", 30.0, true]]:
		iso.lacet = v[1]
		iso.tangage = 35.0
		iso.regler_perspective(v[2])
		m.camera.position = centre * m.TILE
		m.camera.zoom = Vector2.ONE * 4.0
		for k in 20:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dossier, v[0]])
		print("image : ", v[0])
	get_tree().quit()
