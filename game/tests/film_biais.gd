extends Node
## Filme un personnage qui marche dans les quatre diagonales de la vue isométrique (planches <id>_biais).
##   godot --path game --resolution 1600x900 -- --seed=7 --autodraft --iso --essai3d=res://tests/film_biais.gd --essai-dossier=C:/chemin [--film-perso=victor]
## Écrit <perso>_NNN.png (cadrage autour du personnage) et <perso>.txt (sens de marche à chaque image).
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
	var dossier := str(m.args.get("essai-dossier", "user://"))
	var perso := str(m.args.get("film-perso", "victor"))
	var carte: GameState.Card = g.hand.filter(func(c): return not c.is_action())[0]
	carte.perso = perso
	m._cmd("deploy", [carte])
	var w: GameState.Worker = g.worker_of(carte)
	m.selected = []
	# Un carré : avec le lacet de 45°, chaque côté est une diagonale de l'écran
	var cote := 6
	# Un carré dégagé près du camp : de la prairie partout, marge comprise (les arbres cacheraient le personnage)
	var depart: Vector2i = g.map.camp.get_center()
	var meilleur := -1
	for dy in range(-24, 25):
		for dx in range(-24, 25):
			var o: Vector2i = g.map.camp.get_center() + Vector2i(dx, dy)
			var n := 0
			for y in range(-2, cote + 3):
				for x in range(-2, cote + 3):
					var q := o + Vector2i(x, y)
					if g.map.in_bounds(q.x, q.y) and g.map.tiles[q.y * g.map.w + q.x] == GameMap.PRAIRIE and not g.map.camp.has_point(q):
						n += 1
			if n > meilleur:
				meilleur = n
				depart = o
	var coins := [depart, depart + Vector2i(cote, 0), depart + Vector2i(cote, cote), depart + Vector2i(0, cote), depart]
	var etape := 0
	g.order([w], coins[0])
	m._set_speed(1.5)
	m.camera.zoom = Vector2.ONE * 5.0
	var journal: Array[String] = []
	var n_img := 0
	for k in 4000:
		m.camera.position = w.pos * m.TILE
		await RenderingServer.frame_post_draw
		if etape >= 1 and k % 3 == 0:
			var img := get_viewport().get_texture().get_image()
			var vue: Vector2i = img.get_size()
			var c := vue.y / 3
			var part := img.get_region(Rect2i(vue.x / 2 - c / 2, vue.y / 2 - c * 3 / 5, c, c))
			part.save_png("%s/%s_%03d.png" % [dossier, perso, n_img])
			n_img += 1
		journal.append("%d %s %s" % [k, str(m.facing.get(w, ["?"])[0]), str(w.pos)])
		# Coin suivant une fois arrivé : chaque côté du carré est une diagonale de l'écran
		if w.pos.distance_to(Vector2(coins[etape]) + Vector2(0.5, 0.5)) < 0.3:
			etape += 1
			if etape >= coins.size():
				break
			g.order([w], coins[etape])
	var f := FileAccess.open("%s/%s.txt" % [dossier, perso], FileAccess.WRITE)
	f.store_string("\n".join(journal))
	f.close()
	get_tree().quit()
