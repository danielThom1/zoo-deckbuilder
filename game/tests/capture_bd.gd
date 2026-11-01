extends SceneTree
## Capture de contrôle du rendu BD (à lancer avec un affichage, pas en --headless) :
##   godot --path game --script res://tests/capture_bd.gd -- --seed=4242 --autodraft --autoplay --sim=240 --autozoo --zoom=3.2 --sortie=/chemin/capture.png
## Sans --zoom : vue par défaut du jeu.

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 15:
		await process_frame
	if args.has("zoom") and main.camera:
		var z := float(args["zoom"])
		main.camera.zoom = Vector2(z, z)
		var cible: Vector2 = Vector2(main.game.map.camp.get_center()) + Vector2(-3, -6)
		main.camera.position = cible * main.TILE
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args.get("sortie", "user://capture_bd.png"))
	print("capture : ", args.get("sortie", "user://capture_bd.png"))
	quit()
