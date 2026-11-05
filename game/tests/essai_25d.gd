extends Node
## Essai visuel de la 2,5D : le même parc, avec les images actuelles, vu de quatre façons (vue du jeu, relief, isométrique, 3D).
## Ne touche pas aux règles. Lancement :
##   godot --path game --resolution 1600x900 -- --spectateur --seed=11 --jours=11 --essai3d=res://tests/essai_25d.gd --essai-dossier=C:/chemin
## Les bâtiments restent de face : dans une vraie version isométrique, ils seraient redessinés de biais.

const PX := 32.0  # résolution du sol cuit, par case
const RELIEF := {"Prairie": 0.0, "Foret": 0.14, "Eau": -0.34, "Roche": 0.34, "Sable": 0.02, "Montagne": 1.5, "MineOr": 0.3}
const STYLE_PAR_TYPE := {"herbivore": "enclos_herbivore", "predateur": "enclos_predateur", "aquatique": "enclos_aquatique", "aerien": "enclos_aerien"}

var m
var game: GameState
var dossier := ""
var racine: Node3D
var camera: Camera3D
var hauteurs := PackedFloat32Array()
var cote := 0
var relief_actif := 1.0
var mats := {}
var murs_plats: Array = []
var murs_volume: Array = []


func _init(principal) -> void:
	m = principal


func _ready() -> void:
	dossier = str(m.args.get("essai-dossier", "user://"))
	_lancer.call_deferred()


func _attendre(n := 3) -> void:
	for k in n:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _photo(nom: String) -> void:
	await _attendre(4)
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dossier, nom])
	print("image : ", nom)


func _lancer() -> void:
	# Le zoo le plus fourni
	var mt: Match = m.mt
	var meilleur := 0
	for i in mt.players.size():
		if mt.players[i].animals.size() + mt.players[i].sites.size() * 0.01 > mt.players[meilleur].animals.size() + mt.players[meilleur].sites.size() * 0.01:
			meilleur = i
	m._view_player(meilleur)
	game = mt.players[meilleur]
	var ai: AIController = mt.ais[meilleur]
	var zone: Rect2i = ai.zoo_rect
	m.speed = 0.0
	m.spectator = false  # sans les libellés de plan de l'IA regardée
	m.selected.clear()
	var types: Array = game.data["buildings"]["reputation_autres"]["embellissement"]["types"]
	if game.decorations.size() < 14:
		for k in 14:
			var t := game._case_decoration()
			if t.x >= 0:
				game.decorations.append({"t": t, "id": types[k % types.size()]})
	print("zoo : ", zone, ", ", game.animals.size(), " animaux")
	var large := maxf(zone.size.x + 8.0, (zone.size.y + 4.0) * 16.0 / 9.0)
	# Le cadre reste sur la carte, même si le parc est près d'un bord
	var cx: float = clampf(zone.get_center().x, large / 2.0, game.map.w - large / 2.0)
	var cz: float = clampf(zone.get_center().y, large * 9.0 / 32.0, game.map.h - large * 9.0 / 32.0)
	var centre := Vector3(cx, 0.0, cz)
	# Vue d'aujourd'hui : le vrai jeu, sans l'interface
	for c in m.get_children():
		if c is CanvasLayer:
			c.visible = false
	m.camera.position = Vector2(cx, cz) * m.TILE
	m.camera.zoom = Vector2.ONE * 1600.0 / (large * m.TILE)
	m.queue_redraw()
	await _photo("0_aujourd_hui")
	m.visible = false
	await _construire()
	# Voie 1 : même vue, avec du relief et des ombres
	_murs_plats(true)
	_camera_ortho(centre, 0.0, 62.0, large)
	await _photo("1_relief")
	# Voie 2 : isométrique
	_murs_plats(false)
	_camera_ortho(centre, 45.0, 35.0, large * 0.85)
	await _photo("2_isometrique")
	# Voie 3 : caméra en perspective
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 38.0
	var cible := centre + Vector3(0, 0, -1)
	camera.position = cible + Vector3(large * 0.2, large * 0.42, large * 0.72)
	camera.look_at(cible)
	await _photo("3_3d")
	get_tree().quit()


## Vue du dessus : les murs sont dessinés comme dans le jeu (de face et en long). Vues de biais : de vrais panneaux dans l'espace.
func _murs_plats(plats: bool) -> void:
	for n in murs_plats:
		n.visible = plats
	for n in murs_volume:
		n.visible = not plats


func _camera_ortho(centre: Vector3, lacet: float, tangage: float, largeur: float) -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = largeur * 9.0 / 16.0
	camera.near = 0.1
	camera.far = 400.0
	var dir := Vector3(0, sin(deg_to_rad(tangage)), cos(deg_to_rad(tangage))).rotated(Vector3.UP, deg_to_rad(lacet))
	camera.position = centre + dir * 120.0
	camera.look_at(centre)


func _construire() -> void:
	racine = Node3D.new()
	add_child(racine)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	get_viewport().positional_shadow_atlas_size = 4096
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = UiTokens.ENCRE
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	racine.add_child(we)
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-48.0, -38.0, 0.0)
	soleil.light_energy = 0.62
	soleil.shadow_enabled = true
	soleil.directional_shadow_max_distance = 500.0
	soleil.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	soleil.shadow_opacity = 0.75
	soleil.shadow_blur = 1.4
	racine.add_child(soleil)
	camera = Camera3D.new()
	racine.add_child(camera)
	camera.current = true
	_calculer_hauteurs()
	var sol: ImageTexture = await _cuire_sol()
	_terrain(sol)
	_decor()
	_batiments()
	_clotures()
	_animaux()
	_personnages()
	_decorations()


func _cuire_sol() -> ImageTexture:
	var mp := game.map
	var vp := SubViewport.new()
	vp.size = Vector2i(mp.w, mp.h) * int(PX)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var carte := CarteBD.new()
	vp.add_child(carte)
	carte.construire(mp, PX, game.seed_value)
	var pave := {}
	for t in game.zoo_status()["interior"]:
		pave[t] = true
	carte.occuper({}, pave)
	carte.decor.visible = false
	await _attendre(5)
	var img := vp.get_texture().get_image()
	img.generate_mipmaps()
	vp.queue_free()
	return ImageTexture.create_from_image(img)


## Hauteur du sol, adoucie, sur une grille de deux points par case.
func _calculer_hauteurs() -> void:
	var mp := game.map
	cote = 2
	var w := mp.w * cote + 1
	var h := mp.h * cote + 1
	hauteurs.resize(w * h)
	var interieur: Dictionary = game.zoo_status()["interior"]
	for y in h:
		for x in w:
			var tx := clampi(x / cote, 0, mp.w - 1)
			var ty := clampi(y / cote, 0, mp.h - 1)
			var nom: String = GameMap.TERRAINS[mp.get_t(tx, ty)]
			var v: float = RELIEF.get(nom, 0.0)
			if mp.road[mp.idx(tx, ty)]:
				v = 0.0
			hauteurs[y * w + x] = v
	for passe in 3:
		var copie := hauteurs.duplicate()
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				hauteurs[y * w + x] = (copie[y * w + x] * 4.0 + copie[y * w + x - 1] + copie[y * w + x + 1] + copie[(y - 1) * w + x] + copie[(y + 1) * w + x]) / 8.0


func _h(x: float, z: float) -> float:
	var w := game.map.w * cote + 1
	var h := game.map.h * cote + 1
	var gx := clampi(int(round(x * cote)), 0, w - 1)
	var gz := clampi(int(round(z * cote)), 0, h - 1)
	return hauteurs[gz * w + gx]


func _terrain(tex: ImageTexture) -> void:
	var mp := game.map
	var w := mp.w * cote + 1
	var h := mp.h * cote + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in h:
		for x in w:
			st.set_uv(Vector2(float(x) / (w - 1), float(y) / (h - 1)))
			st.add_vertex(Vector3(float(x) / cote, hauteurs[y * w + x], float(y) / cote))
	for y in h - 1:
		for x in w - 1:
			var a := y * w + x
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + w)
			st.add_index(a + 1)
			st.add_index(a + w + 1)
			st.add_index(a + w)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.roughness = 1.0
	mat.metallic_specular = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	racine.add_child(mi)


## Une image debout, les pieds en (x, z). largeur en cases.
func _panneau(tex: Texture2D, pied: Vector2, x: float, z: float, largeur: float, miroir := false, region := Rect2()) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	var taille := Vector2(tex.get_width(), tex.get_height())
	if region.size != Vector2.ZERO:
		s.region_enabled = true
		s.region_rect = region
		taille = region.size
	s.centered = false
	s.offset = Vector2(-pied.x, -(taille.y - pied.y))
	s.pixel_size = largeur / taille.x
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.flip_h = miroir
	s.position = Vector3(x, _h(x, z), z)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	racine.add_child(s)
	return s


func _decor() -> void:
	var mt_carte: CarteBD = m.carte
	for s in mt_carte.decor.get_children():
		if not (s is Sprite2D) or not s.visible:
			continue
		var pos: Vector2 = s.position / m.TILE
		var k: float = s.scale.x / m.TILE  # cases par pixel
		_panneau(s.texture, -s.offset, pos.x, pos.y, s.texture.get_width() * k, s.flip_h)


func _batiments() -> void:
	# Camp
	var niveau := 1
	for st in game.sites:
		if st.done and st.def_id() in ["camp_n2", "camp_n3"]:
			niveau += 1
	var camp := game.map.camp
	var nom_camp: String = SpritesBD.CAMPS[clampi(niveau - 1, 0, 2)]
	_panneau(SpritesBD.texture(nom_camp), SpritesBD.pied(nom_camp), camp.get_center().x + 0.5, camp.end.y, camp.size.x * 1.08)
	for st in game.sites:
		var id: String = st.def_id()
		if id in ["cloture", "enclos", "route", "pont", "camp_n2", "camp_n3"] or st.kind == "amenagement":
			continue
		var r: Rect2i = st.rect
		var nom := ""
		var largeur := float(r.size.x) * SpritesBD.LARGEUR_BATIMENT
		if not st.done:
			nom = "chantier1"
		elif id == "entree":
			var tourne: bool = st.def.get("pivote", false)
			nom = "entree2" if tourne else "entree"
			largeur = float(r.size.x) * 1.7 if tourne else maxf(r.size.x, r.size.y) * 1.15
		else:
			nom = SpritesBD.BATIMENTS.get(id, "")
			if id in ["grand_arbre", "rocher_obs", "bassin_profond", "abri_chaud"]:
				largeur = float(r.size.x)
		if nom != "" and SpritesBD.existe(nom):
			_panneau(SpritesBD.texture(nom), SpritesBD.pied(nom), r.position.x + r.size.x / 2.0, r.end.y, largeur)


func _style_clotures() -> Dictionary:
	var styles := {}
	for a in game.animals:
		if a.park:
			continue
		var style: String = STYLE_PAR_TYPE.get(a.def.get("type", ""), "enclos")
		for t in a.tiles:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var q: Vector2i = t + Vector2i(dx, dy)
					var o := game.site_at(q)
					if o != null and o.def_id() == "enclos" and not styles.has(q):
						styles[q] = style
	return styles


func _mat_cloture(style: String, phase: int) -> StandardMaterial3D:
	var cle := "%s_%d" % [style, phase]
	if not mats.has(cle):
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = SpritesBD.texture("cl_%s_face" % style)
		mat.uv1_scale = Vector3(0.5, 1.0, 1.0)
		mat.uv1_offset = Vector3(0.5 * phase, 0.0, 0.0)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.5
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mats[cle] = mat
	return mats[cle]


func _clotures() -> void:
	var styles := _style_clotures()
	var finis := {}
	for st in game.sites:
		if st.done and st.def_id() in ["cloture", "enclos"]:
			finis[st.rect.position] = st.def_id()
	for p: Vector2i in finis:
		var id: String = finis[p]
		var style: String = "enceinte" if id == "cloture" else str(styles.get(p, "enclos"))
		var face := SpritesBD.texture("cl_%s_face" % style)
		var haut := 2.0 * face.get_height() / float(face.get_width())
		var voisins := 0
		var ligne_x := false
		for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			if finis.get(p + d, "") == id or (id == "cloture" and game.site_at(p + d) != null and game.site_at(p + d).def_id() == "entree"):
				voisins += 1
				ligne_x = ligne_x or d.x != 0
		for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
			if finis.get(p + d, "") != id:
				continue
			var cx: float = p.x + 0.5 + d.x * 0.5
			var cz: float = p.y + 0.5 + d.y * 0.5
			var q := QuadMesh.new()
			q.size = Vector2(1.0, haut)
			var mi := MeshInstance3D.new()
			mi.mesh = q
			mi.material_override = _mat_cloture(style, posmod(p.x if d.x != 0 else p.y, 2))
			mi.position = Vector3(cx, _h(cx, cz) + haut / 2.0, cz)
			if d.y != 0:
				mi.rotation_degrees.y = 90.0
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			racine.add_child(mi)
			murs_volume.append(mi)
			var phase: int = posmod(p.x if d.x != 0 else p.y, 2)
			var plat: Sprite3D
			if d.x != 0:
				var fw: float = face.get_width()
				var fh: float = face.get_height()
				plat = _panneau(face, Vector2(fw / 4.0, fh), cx, p.y + 0.8, 1.0, false, Rect2(fw / 2.0 * phase, 0, fw / 2.0, fh))
			else:
				var lg := SpritesBD.texture("cl_%s_long" % style)
				var lw: float = lg.get_width()
				var lh: float = lg.get_height()
				plat = _panneau(lg, Vector2(lw / 2.0, lh / 2.0), p.x + 0.5, p.y + 1.3, lw * 2.0 / face.get_width(), false, Rect2(0, lh / 2.0 * phase, lw, lh / 2.0))
			murs_plats.append(plat)
			# Dessus du mur : donne l'épaisseur
			if id == "cloture":
				var b := BoxMesh.new()
				b.size = Vector3(1.0, 0.04, 0.2) if d.x != 0 else Vector3(0.2, 0.04, 1.0)
				var dessus := MeshInstance3D.new()
				dessus.mesh = b
				var mb := StandardMaterial3D.new()
				mb.albedo_color = Color("EFE6D0")
				mb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				dessus.material_override = mb
				dessus.position = Vector3(cx, _h(cx, cz) + haut, cz)
				racine.add_child(dessus)
				murs_volume.append(dessus)
		var droit := voisins == 2
		var rang: int = p.x if ligne_x else p.y
		if not droit or posmod(rang, 6 if id == "cloture" else 2) == 0:
			var pot := SpritesBD.texture("cl_%s_poteau" % style)
			var k := 2.0 / face.get_width() * 0.75
			_panneau(pot, Vector2(pot.get_width() / 2.0, pot.get_height()), p.x + 0.5, p.y + 0.5, pot.get_width() * k)


func _animaux() -> void:
	var index := 0
	for a in game.animals:
		index += 1
		var esp: Array = SpritesBD.ANIMAUX.get(str(a.def["id"]), [])
		if esp.is_empty() or not SpritesBD.existe(esp[0]) or a.tiles.is_empty():
			continue
		var n := 1 if int(a.def["taille"]) >= 7 else 2
		for k in n:
			var t: Vector2i = a.tiles[(index * 7 + k * 13) % a.tiles.size()]
			var tex := SpritesBD.texture(esp[0])
			_panneau(tex, SpritesBD.pied(esp[0]), t.x + 0.5, t.y + 0.85, float(esp[1]) * 1.15 * tex.get_width() / float(tex.get_height()), k == 1)


func _personnages() -> void:
	for w in game.workers:
		if w.offmap:
			continue
		var f := SpritesBD.feuille_perso(str(game.perso_of(w.card)["id"]))
		if f == null:
			continue
		var region := Rect2(Vector2(1, 0) * SpritesBD.PERSO_CELLULE, SpritesBD.PERSO_CELLULE)
		var k := SpritesBD.HAUTEUR_PERSONNE / SpritesBD.PERSO_CORPS
		_panneau(f, SpritesBD.PERSO_PIED, w.pos.x, w.pos.y, SpritesBD.PERSO_CELLULE.x * k, false, region)


func _decorations() -> void:
	for d in game.decorations:
		var nom := "deco_%s" % d["id"]
		if not SpritesBD.existe(nom):
			continue
		var tex := SpritesBD.texture(nom)
		var ratio := tex.get_height() / float(tex.get_width())
		var haut: float = float(m.DECO_HAUTEUR.get(d["id"], 0.0))
		var large: float = haut / ratio if haut > 0.0 else float(m.DECO_LARGEUR.get(d["id"], 1.0))
		_panneau(tex, Vector2(tex.get_width() / 2.0, tex.get_height()), d["t"].x + 0.5, d["t"].y + 0.85, large)
