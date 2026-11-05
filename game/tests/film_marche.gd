extends Node
## Filme un collaborateur qui marche, image par image, autour de lui. Avec --iso, dans la vue isométrique.
##   godot --path game --resolution 1600x900 -- --seed=7 --autodraft [--iso] --essai3d=res://tests/film_marche.gd --essai-dossier=C:/chemin --film=nom [--film-vitesse=1]
## Écrit <nom>_NNN.png (un cadrage autour du personnage) et <nom>.txt (position, image de la feuille, à chaque image).
var m
var dossier := ""
var nom := "film"


func _init(principal) -> void:
	m = principal


func _ready() -> void:
	dossier = str(m.args.get("essai-dossier", "user://"))
	nom = str(m.args.get("film", "film"))
	_lancer.call_deferred()


func _lancer() -> void:
	for k in 30:
		await get_tree().process_frame
	var g: GameState = m.game
	var carte: GameState.Card = null
	for c in g.hand:
		if not c.is_action():
			carte = c
			break
	m._cmd("deploy", [carte])
	var w: GameState.Worker = g.worker_of(carte)
	m.selected = []
	# Une cible à une vingtaine de cases, sur l'axe voulu
	var c0: Vector2i = g.map.camp.get_center()
	var cible: Vector2i = c0 + Vector2i(-14, -12)
	g.order([w], cible)
	m._set_speed(float(m.args.get("film-vitesse", "1")))
	m.camera.zoom = Vector2.ONE * 4.0
	var journal: Array[String] = []
	var dernier := w.pos
	var images := 90
	for k in images:
		m.camera.position = w.pos * m.TILE
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var vue: Vector2i = img.get_size()
		var centre := Vector2i(vue.x / 2, vue.y / 2)
		var cote := vue.y / 3
		var part := img.get_region(Rect2i(centre.x - cote / 2, centre.y - cote * 3 / 4, cote, cote))
		part.save_png("%s/%s_%03d.png" % [dossier, nom, k])
		journal.append("%d pos %s bouge %.4f phase %.3f tache %s temps %.3f" % [k, str(w.pos), w.pos.distance_to(dernier), float(m.marche_phase.get(w, 0.0)), str(w.task.get("phase", "")), Time.get_ticks_msec() / 1000.0])
		dernier = w.pos
	var f := FileAccess.open("%s/%s.txt" % [dossier, nom], FileAccess.WRITE)
	f.store_string("\n".join(journal))
	f.close()
	get_tree().quit()
