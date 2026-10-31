extends SceneTree
## Planche de contrôle des illustrations générées (rendu réel, pas --headless) :
##   godot --path game --script res://tests/planche_images.gd -- --animaux --shot=C:/chemin/animaux.png
##   godot --path game --script res://tests/planche_images.gd -- --batiments --shot=C:/chemin/batiments.png
## Animaux : illustration sur le fond de son biome, puis en petit (taille dans le monde) sur l'herbe.


func _init() -> void:
	var data := GameData.load_all()
	var shot := ""
	var batiments := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.substr(7)
		batiments = batiments or a == "--batiments"
	var fond := ColorRect.new()
	fond.color = Color("0E3B33")
	fond.size = Vector2(1600, 900)
	root.add_child(fond)
	if batiments:
		_batiments(fond)
	else:
		_animaux(fond, data)
	if shot != "":
		for k in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(shot)
		quit()


func _animaux(fond: Control, data: Dictionary) -> void:
	var i := 0
	for d in data["animals"]["animaux"]:
		var pos := Vector2(8 + (i % 8) * 198, 6 + (i / 8) * 178)
		var bg := ColorRect.new()
		bg.color = UiTokens.BIOMES.get(str(d["biome"]).to_lower(), {"couleur": Color("4A6A4A")})["couleur"].darkened(0.55) \
			if UiTokens.BIOMES.has(str(d["biome"]).to_lower()) else Color("2A4A3A")
		bg.position = pos
		bg.size = Vector2(130, 100)
		fond.add_child(bg)
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = load("res://ui/animaux/%s.svg" % d["id"])
		tr.position = pos + Vector2(2, 2)
		tr.size = Vector2(126, 96)
		fond.add_child(tr)
		var herbe := ColorRect.new()
		herbe.color = Color("6FA84A")
		herbe.position = pos + Vector2(134, 50)
		herbe.size = Vector2(56, 50)
		fond.add_child(herbe)
		var petit := TextureRect.new()
		petit.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		petit.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		petit.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		petit.texture = tr.texture
		var w := 3.0 * (14.0 + 1.2 * float(d["taille"]))  # taille dans le monde au zoom 3
		petit.size = Vector2(minf(w, 54), minf(w, 54) * 0.75)
		petit.position = pos + Vector2(134 + (56 - petit.size.x) / 2, 98 - petit.size.y)
		fond.add_child(petit)
		var l := Label.new()
		l.text = d["nom"]
		l.add_theme_font_size_override("font_size", 13)
		l.position = pos + Vector2(0, 102)
		fond.add_child(l)
		i += 1


func _batiments(fond: Control) -> void:
	var dir := DirAccess.open("res://ui/batiments")
	if dir == null:
		return
	var noms: Array = []
	for f in dir.get_files():
		if f.ends_with(".svg"):
			noms.append(f.get_basename())
	noms.sort()
	var x := 10.0
	var y := 10.0
	var ligne := 0.0
	for n in noms:
		var tex: Texture2D = load("res://ui/batiments/%s.svg" % n)
		var s := tex.get_size() / 2.0 * 2.2  # svg/scale 2 : 32 px par case, affichées à 70 px
		if x + s.x > 1590:
			x = 10.0
			y += ligne + 30
			ligne = 0.0
		var herbe := ColorRect.new()
		herbe.color = Color("6FA84A")
		herbe.position = Vector2(x, y)
		herbe.size = s
		fond.add_child(herbe)
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.texture = tex
		tr.position = Vector2(x, y)
		tr.size = s
		fond.add_child(tr)
		var l := Label.new()
		l.text = n
		l.position = Vector2(x, y + s.y + 2)
		fond.add_child(l)
		x += s.x + 16
		ligne = maxf(ligne, s.y)
