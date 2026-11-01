class_name CarteBD
extends Node2D
## Rendu de la carte en style « BD néo ligne claire, semi-perspective ».
## - Sol : un seul Sprite2D + shader (sol_bd.gdshader) qui lit des masques 1 texel = 1 case.
## - Routes et ponts : RoutesBD (tracés continus, diagonales comprises).
## - Décor : arbres, rochers, pics, roseaux… en Sprite2D triés en Y (DecorBD).
## Autonome : il suffit de lui donner la GameMap. Il surveille lui-même les changements
## (terrain, routes, ponts) à chaque image et ne redessine que les cases modifiées.
##
## Utilisation (dans main.gd) :
##   carte = CarteBD.new()
##   add_child(carte); move_child(carte, 0)
##   carte.construire(game.map, TILE)
## Changer de joueur affiché : carte.construire(autre_map, TILE)

const SHADER := preload("res://scripts/rendu/sol_bd.gdshader")
const DOSSIER_TEX := "res://assets/bd/textures/"

var map: GameMap
var tile := 16.0
var graine := 0
var sol: Sprite2D
var decor: DecorBD
var routes: RoutesBD
var img_a: Image   # R eau, G forêt, B roche, A sable
var img_b: Image   # R montagne, G or, B route, A pont
var img_c: Image   # R profondeur d'eau
var tex_a: ImageTexture
var tex_b: ImageTexture
var tex_c: ImageTexture
var _tiles_vus := PackedInt32Array()
var _routes_vues := PackedByteArray()
var _ponts_vus := PackedByteArray()
var _temps := 0.0


func _init() -> void:
	show_behind_parent = true   # tout ce que main.gd dessine dans _draw() passe au-dessus


func construire(m: GameMap, taille_case: float, graine_decor := 0) -> void:
	map = m
	tile = taille_case
	graine = graine_decor
	for c in get_children():
		c.queue_free()
	img_a = Image.create_empty(m.w, m.h, false, Image.FORMAT_RGBA8)
	img_b = Image.create_empty(m.w, m.h, false, Image.FORMAT_RGBA8)
	img_c = Image.create_empty(m.w, m.h, false, Image.FORMAT_RGBA8)
	for y in m.h:
		for x in m.w:
			_ecrire_case(x, y)
	_calculer_profondeur()
	tex_a = ImageTexture.create_from_image(img_a)
	tex_b = ImageTexture.create_from_image(img_b)
	tex_c = ImageTexture.create_from_image(img_c)

	sol = Sprite2D.new()
	sol.name = "Sol"
	sol.centered = false
	var blanc := Image.create_empty(m.w, m.h, false, Image.FORMAT_RGBA8)
	blanc.fill(Color.WHITE)
	sol.texture = ImageTexture.create_from_image(blanc)
	sol.scale = Vector2(tile, tile)
	sol.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("taille_carte", Vector2(m.w, m.h))
	mat.set_shader_parameter("masque_a", tex_a)
	mat.set_shader_parameter("masque_b", tex_b)
	mat.set_shader_parameter("masque_c", tex_c)
	mat.set_shader_parameter("bruit", _bruit())
	for n in ["herbe", "sable", "roche", "eau", "falaise"]:
		mat.set_shader_parameter("tex_" + n, load(DOSSIER_TEX + n + "_details.png"))
	sol.material = mat
	add_child(sol)

	routes = RoutesBD.new()
	routes.name = "Routes"
	add_child(routes)
	routes.construire(m, tile)

	decor = DecorBD.new()
	decor.name = "Decor"
	add_child(decor)
	decor.construire(m, tile, graine)

	_tiles_vus = m.tiles.duplicate()
	_routes_vues = m.road.duplicate()
	_ponts_vus = m.bridge.duplicate()


## Cases sans décor (bâtiments, chantiers) et allées pavées (enceinte du zoo).
func occuper(cases_bati: Dictionary, cases_pavees: Dictionary) -> void:
	if decor:
		decor.masquer(cases_bati)
	if routes:
		routes.definir_interieur(cases_pavees)


## Force le rafraîchissement de quelques cases (facultatif : la surveillance automatique suffit).
func rafraichir(cases: Array) -> void:
	if map == null or cases.is_empty():
		return
	var touche := {}
	for p in cases:
		var q := Vector2i(p)
		_ecrire_case(q.x, q.y)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				touche[q + Vector2i(dx, dy)] = true
	_calculer_profondeur()
	tex_a.update(img_a)
	tex_b.update(img_b)
	tex_c.update(img_c)
	decor.rafraichir(touche.keys())
	routes.queue_redraw()


func _process(delta: float) -> void:
	if map == null:
		return
	_temps += delta
	(sol.material as ShaderMaterial).set_shader_parameter("temps_eau", _temps)
	# Surveillance : les tableaux natifs se comparent très vite.
	if map.tiles == _tiles_vus and map.road == _routes_vues and map.bridge == _ponts_vus:
		return
	var changees := []
	for i in map.tiles.size():
		if map.tiles[i] != _tiles_vus[i] or map.road[i] != _routes_vues[i] or map.bridge[i] != _ponts_vus[i]:
			changees.append(Vector2i(i % map.w, i / map.w))
	_tiles_vus = map.tiles.duplicate()
	_routes_vues = map.road.duplicate()
	_ponts_vus = map.bridge.duplicate()
	rafraichir(changees)


func _ecrire_case(x: int, y: int) -> void:
	var t := map.get_t(x, y)
	var i := map.idx(x, y)
	var pont := map.bridge[i] != 0
	var route := map.road[i] != 0 and not pont
	img_a.set_pixel(x, y, Color(
		1.0 if t == GameMap.EAU else 0.0,
		1.0 if t == GameMap.FORET else 0.0,
		1.0 if t == GameMap.ROCHE else 0.0,
		1.0 if t == GameMap.SABLE else 0.0))
	img_b.set_pixel(x, y, Color(
		1.0 if t == GameMap.MONTAGNE else 0.0,
		1.0 if t == GameMap.MINE_OR else 0.0,
		0.0,   # routes et ponts : tracés par RoutesBD (canaux B et A libres)
		0.0))


## Distance de chaque case d'eau à la rive (parcours en largeur), normalisée sur 4 cases.
func _calculer_profondeur() -> void:
	var w := map.w
	var h := map.h
	var dist := PackedInt32Array()
	dist.resize(w * h)
	dist.fill(-1)
	var file: Array[Vector2i] = []
	for y in h:
		for x in w:
			if map.get_t(x, y) != GameMap.EAU:
				dist[y * w + x] = 0
				file.append(Vector2i(x, y))
	var k := 0
	while k < file.size():
		var p := file[k]
		k += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and dist[q.y * w + q.x] < 0:
				dist[q.y * w + q.x] = dist[p.y * w + p.x] + 1
				file.append(q)
	for y in h:
		for x in w:
			var d := dist[y * w + x]
			img_c.set_pixel(x, y, Color(clampf((d - 0.5) / 4.0, 0.0, 1.0) if d > 0 else 0.0, 0, 0, 1))


func _bruit() -> ImageTexture:
	var n := FastNoiseLite.new()
	n.seed = 7
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.02
	n.fractal_octaves = 3
	var img := n.get_seamless_image(256, 256)
	img.convert(Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(img)
