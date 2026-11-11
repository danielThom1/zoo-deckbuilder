extends SceneTree
## Atelier de rendu : capture de la carte seule (sans interface), axes d'enrichissement au choix.
## À lancer avec un affichage (pas en --headless) :
##   godot --path game --script res://tests/atelier_rendu.gd -- --seed=4242 --zoom=3 --cx=8 --cy=-6 --axes=tout --sortie=/chemin/apres.png
##   --axes=aucun (rendu d'origine) | tout | liste séparée par des virgules parmi CarteBD.AXES
##   --cx/--cy : décalage de la caméra en cases par rapport au camp ; --temps : secondes d'animation avant la capture
##   --images=N --dossier=/chemin : N images successives (vidéo de l'animation), 30 par seconde

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
	var z := float(args.get("zoom", "3"))
	main.camera.zoom = Vector2(z, z)
	var cible: Vector2 = Vector2(main.game.map.camp.get_center()) + Vector2(float(args.get("cx", "0")), float(args.get("cy", "0")))
	main.camera.position = cible * main.TILE
	if main.has_method("set_process_input"):
		main.set_process_input(false)
	var attente := int(float(args.get("temps", "0.5")) * 60.0)
	for i in maxi(attente, 10):
		main.camera.position = cible * main.TILE
		await process_frame
	var n := int(args.get("images", "0"))
	if n > 0:
		var dossier := str(args.get("dossier", "user://atelier"))
		DirAccess.make_dir_recursive_absolute(dossier)
		for i in n:
			main.camera.position = cible * main.TILE
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/i_%04d.png" % [dossier, i])
	else:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(args.get("sortie", "user://atelier.png"))
	print("atelier : ", choix)
	quit()
