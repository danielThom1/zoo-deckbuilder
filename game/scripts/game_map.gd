class_name GameMap
extends RefCounted
## Grille de terrain, routes, camp, accès et recherche de chemin (AStarGrid2D).

const TERRAINS: Array[String] = ["Prairie", "Foret", "Eau", "Roche", "Sable", "Montagne", "MineOr"]
const PRAIRIE := 0
const FORET := 1
const EAU := 2
const ROCHE := 3
const SABLE := 4
const MONTAGNE := 5
const MINE_OR := 6

var w: int
var h: int
var tiles := PackedInt32Array()
var road := PackedByteArray()
var bridge := PackedByteArray()  # un pont rend une case d'eau franchissable
var res_left := PackedFloat32Array()  # ressource restante (forêts et roches s'épuisent)
var defs: Dictionary
var road_mult := 2.0
var camp := Rect2i()
var start_zone := Rect2i()
var exit_tile := Vector2i()
var golds: Array[Vector2i] = []  # gisements d'or (une mine par gisement)
var gold: Vector2i:  # premier gisement (raccourci)
	get:
		return golds[0]
var astar := AStarGrid2D.new()


func _init(width: int, height: int, terrain_defs: Dictionary, road_multiplier: float) -> void:
	w = width
	h = height
	defs = terrain_defs
	road_mult = road_multiplier
	tiles.resize(w * h)
	tiles.fill(PRAIRIE)
	road.resize(w * h)
	bridge.resize(w * h)
	res_left.resize(w * h)


## Copie indépendante (chaque joueur modifie sa propre carte) : ~10 fois moins chère que de la régénérer.
func copy() -> GameMap:
	var m := GameMap.new(w, h, defs, road_mult)
	m.tiles = tiles.duplicate()
	m.road = road.duplicate()
	m.bridge = bridge.duplicate()
	m.res_left = res_left.duplicate()
	m.camp = camp
	m.start_zone = start_zone
	m.exit_tile = exit_tile
	m.golds = golds.duplicate()
	m.build_astar()
	return m


func idx(x: int, y: int) -> int:
	return y * w + x


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func get_t(x: int, y: int) -> int:
	return tiles[y * w + x]


func set_t(x: int, y: int, t: int) -> void:
	tiles[y * w + x] = t


func def_of(x: int, y: int) -> Dictionary:
	return defs[TERRAINS[get_t(x, y)]]


func passable(x: int, y: int) -> bool:
	return in_bounds(x, y) and (bridge[idx(x, y)] == 1 or bool(def_of(x, y)["franchissable"]))


func move_speed(x: int, y: int) -> float:
	var base := 1.0 if bridge[idx(x, y)] else float(def_of(x, y)["vitesse"])
	return base * (road_mult if road[idx(x, y)] else 1.0)


func extractible(x: int, y: int) -> String:
	var e = def_of(x, y)["extractible"]
	return "" if e == null else str(e)


## Remet le stock d'une case à sa valeur de départ (à appeler quand le terrain change).
func reset_resource(x: int, y: int) -> void:
	var d := def_of(x, y)
	res_left[idx(x, y)] = float(d.get("stock", 0)) if d.get("epuisable", false) else 0.0


## Prélève jusqu'à `amount` sur la case ; renvoie ce qui a été réellement pris (l'or est inépuisable).
func deplete(x: int, y: int, amount: float) -> float:
	if not def_of(x, y).get("epuisable", false):
		return amount
	var i := idx(x, y)
	var take := minf(amount, res_left[i])
	res_left[i] -= take
	return take


func depleted(x: int, y: int) -> bool:
	return def_of(x, y).get("epuisable", false) and res_left[idx(x, y)] <= 0.0001


func in_camp(x: int, y: int) -> bool:
	return camp.has_point(Vector2i(x, y))


func build_astar() -> void:
	astar.region = Rect2i(0, 0, w, h)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for y in h:
		for x in w:
			refresh_cell(x, y)


## À appeler quand une case change (terrain, route).
func refresh_cell(x: int, y: int) -> void:
	var p := Vector2i(x, y)
	var solid := not passable(x, y)
	astar.set_point_solid(p, solid)
	if not solid:
		astar.set_point_weight_scale(p, 1.0 / move_speed(x, y))


## Renvoie la liste des cases à parcourir (sans la case de départ), ou null si aucun chemin.
func find_path(from: Vector2i, to: Vector2i) -> Variant:
	if not passable(to.x, to.y) or not passable(from.x, from.y):
		return null
	if from == to:
		return []
	var p := astar.get_id_path(from, to)
	if p.is_empty():
		return null
	p.remove_at(0)
	return p
