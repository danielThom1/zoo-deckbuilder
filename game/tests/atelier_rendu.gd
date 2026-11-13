extends SceneTree
## Atelier de rendu : capture de la carte seule (sans interface), axes d'enrichissement au choix.
## À lancer avec un affichage (pas en --headless) :
##   godot --path game --script res://tests/atelier_rendu.gd -- --seed=4242 --zoom=3 --cx=8 --cy=-6 --axes=tout --sortie=/chemin/apres.png
##   --axes=aucun (rendu d'origine) | tout | liste séparée par des virgules parmi CarteBD.AXES
##   --cx/--cy : décalage de la caméra en cases par rapport au camp ; --suivre : centre sur un collaborateur au travail
##   --temps : secondes avant la capture ; --vitesse=1 : vitesse du jeu (0 = pause)
##   --heure=0.9 : heure imposée (0 = 06:00, 1 = 18:00) ; --heure-de=0 --heure-a=1 : balayage pendant la vidéo
##   --demo=4 : faune plus fréquente (pour une courte vidéo)
##   --images=N --dossier=/chemin : N images successives ; lancer Godot avec --fixed-fps 24 pour une vidéo à vitesse réelle

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var choix := str(args.get("axes", "tout"))
	for k in CarteBD.AXES:
		CarteBD.AXES[k] = choix == "tout" or (choix != "aucun" and k in choix.split(","))
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 20:
		await process_frame
	for c in main.get_children():
		if c is CanvasLayer:
			c.visible = false
	if args.has("vitesse") and main.has_method("_set_speed"):
		main._set_speed(float(args["vitesse"]))
	if main.vie and args.has("demo"):
		main.vie.demo = float(args["demo"])
	var z := float(args.get("zoom", "3"))
	main.camera.zoom = Vector2(z, z)
	var etat := {"cible": Vector2(main.game.map.camp.get_center()) + Vector2(float(args.get("cx", "0")), float(args.get("cy", "0")))}
	var h_de := float(args.get("heure-de", args.get("heure", "-1")))
	var h_a := float(args.get("heure-a", args.get("heure", "-1")))
	if args.has("vitrine"):
		main.vitrine = true
		main.selected.clear()
	var cacher := func():
		for c in main.get_children():
			if c is CanvasLayer:
				c.visible = false
		if main.hubert:
			main.hubert.get_parent().visible = false
			main.hubert.visible = false
		main.selected.clear()
	var regler := func(k: float):
		cacher.call()
		main.camera.zoom = Vector2(z, z)
		main.camera.position = etat["cible"] * main.TILE
		if h_de >= 0.0 and main.carte:
			main.carte.heure_forcee = lerpf(h_de, h_a, k)
	var attente := int(float(args.get("temps", "0.5")) * 60.0)
	for i in maxi(attente, 10):
		regler.call(0.0)
		await process_frame
	if args.has("suivre"):
		# envoie les collaborateurs sur la ressource la plus proche du camp, attend qu'ils travaillent, puis cadre
		var g = main.game
		var centre: Vector2i = g.map.camp.get_center()
		var meilleur := Vector2i(-1, -1)
		var dmin := 1e9
		for y in g.map.h:
			for x in g.map.w:
				if g.map.extractible(x, y) == str(args["suivre"]):
					var voisins := 0
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							if g.map.extractible(clampi(x + dx, 0, g.map.w - 1), clampi(y + dy, 0, g.map.h - 1)) == str(args["suivre"]):
								voisins += 1
					var d := Vector2(x - centre.x, y - centre.y).length() + (0.0 if voisins >= 6 else 50.0)
					if d < dmin:
						dmin = d
						meilleur = Vector2i(x, y)
		var libres: Array = g.workers.filter(func(w): return not w.offmap and w.task.is_empty())
		if meilleur.x >= 0 and not libres.is_empty():
			g.order(libres, meilleur)
		for essai in 1200:
			var trouve := false
			for w in main.game.workers:
				if w.task.get("type") == "extract" and w.task.get("phase") == "working" and str(w.task.get("res", "")) == str(args["suivre"]):
					etat["cible"] = Vector2(w.task["target"]) + Vector2(0.5, 0.5) + Vector2(float(args.get("cx", "0")), float(args.get("cy", "0")))
					trouve = true
					break
			if trouve:
				print("suivre : trouvé après ", essai, " images")
				break
			if essai % 300 == 0:
				print("suivre : ", essai, " ", main.game.phase, " ", main.game.workers.map(func(w): return [w.task.get("type"), w.task.get("res"), w.task.get("phase")]))
			cacher.call()
			await process_frame
		for i in 48:
			regler.call(0.0)
			await process_frame
	if args.has("visiteurs"):
		# figurants pour juger le dessin des visiteurs (jeu en pause : rien n'est simulé)
		main._set_speed(0.0)
		var g = main.game
		var fin := Vector2(g.map.camp.get_center())
		for st in g.sites:
			if st.done and st.def_id() == "entree":
				fin = Vector2(st.rect.position) + Vector2(st.rect.size) * 0.5
		var rz := RandomNumberGenerator.new()
		rz.seed = 5
		g.in_zoo.clear()
		for i in int(args["visiteurs"]):
			g.in_zoo.append({"pos": fin + Vector2(rz.randf_range(-3.0, 3.5), rz.randf_range(-5.5, -1.5))})
		# et quelques-uns sur la route, près de l'entrée
		var routes: Array = []
		for y in g.map.h:
			for x in g.map.w:
				if g.map.road[g.map.idx(x, y)] and Vector2(x, y).distance_to(fin) < 7.0:
					routes.append(Vector2(x + 0.5, y + 0.5))
		for i in mini(8, routes.size()):
			g.in_zoo.append({"pos": routes[rz.randi() % routes.size()] + Vector2(rz.randf_range(-0.25, 0.25), rz.randf_range(-0.2, 0.2))})
	var n := int(args.get("images", "0"))
	if n > 0:
		var dossier := str(args.get("dossier", "user://atelier"))
		DirAccess.make_dir_recursive_absolute(dossier)
		for i in n:
			regler.call(float(i) / maxf(1.0, n - 1.0))
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/i_%04d.png" % [dossier, i])
	else:
		regler.call(1.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(args.get("sortie", "user://atelier.png"))
	print("or (relatif au camp) : ", main.game.map.golds.map(func(g): return Vector2(g) - Vector2(main.game.map.camp.get_center())))
	print("atelier : ", choix, " ; visiteurs route ", main.game.road_visitors.size(), " file ", main.game.visitor_queue, " zoo ", main.game.in_zoo.size(), " jour ", main.game.day if "day" in main.game else -1)
	quit()
