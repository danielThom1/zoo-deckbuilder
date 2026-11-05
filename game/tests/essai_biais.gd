extends Node
## Photographie les bâtiments d'un zoo sous plusieurs axes de la vue isométrique (images de biais iso_<id>).
##   godot --path game --resolution 1600x900 -- --spectateur --seed=44 --jours=9 --iso --essai3d=res://tests/essai_biais.gd --essai-dossier=C:/chemin
var m


func _init(principal) -> void:
	m = principal


func _ready() -> void:
	_lancer.call_deferred()


func _lancer() -> void:
	while m.iso == null:
		await get_tree().process_frame
	var mt: Match = m.mt
	var cible := 0
	var vus := 0
	for i in mt.players.size():
		var n := mt.players[i].sites.filter(func(s): return s.done and s.def_id() in ["snack", "cuisine", "intendance"]).size()
		if n > vus:
			vus = n
			cible = i
	m._view_player(cible)
	var g: GameState = m.game
	# Ceux qui manquent sont posés terminés dans l'enceinte, pour les voir ensemble (contrôle visuel seulement)
	var interieur: Array = g.zoo_status()["interior"].keys()
	interieur.sort_custom(func(p, q): return p.y * 1000 + p.x < q.y * 1000 + q.x)
	g.stock["bois"] = 999.0
	g.stock["pierre"] = 999.0
	g.money = 999.0
	for id in ["snack", "cuisine", "intendance"]:
		if g.sites.any(func(s): return s.def_id() == id):
			continue
		for t in interieur:
			if g.placement_error("batiment", g.building_def(id), t) == "":
				var s: GameState.Site = g.place("batiment", g.building_def(id), t)
				s.work = s.travail()
				g._complete(s)
				break
	var batis: Array = g.sites.filter(func(s): return s.done and s.def_id() in ["snack", "cuisine", "intendance"])
	print("bâtiments de biais dans ce zoo : ", batis.map(func(s): return s.def_id()))
	var centre := Vector2.ZERO
	for s in batis:
		centre += Vector2(s.rect.get_center())
	centre = centre / maxf(1.0, batis.size()) if not batis.is_empty() else Vector2(mt.ais[cible].zoo_rect.get_center())
	var dossier := str(m.args.get("essai-dossier", "user://"))
	var iso: Vue25D = m.iso
	for v in [["biais_gauche", 45.0], ["biais_droite", 315.0], ["biais_axe", 0.0]]:
		iso.lacet = v[1]
		iso.tangage = 35.0
		m.camera.position = centre * m.TILE
		m.camera.zoom = Vector2.ONE * 3.2
		for k in 30:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dossier, v[0]])
		print("image : ", v[0])
	get_tree().quit()
