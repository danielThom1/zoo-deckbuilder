class_name MapGenerator
extends RefCounted
## Génération déterministe à partir d'une graine (identique pour tous les joueurs) :
## terrain par bruit, lacs, rivières, zone de départ en bas au centre, route d'accès,
## gués pour que tout reste atteignable, et une seule mine d'or.


static func generate(b: Dictionary, map_seed: int) -> GameMap:
	var carte: Dictionary = b["carte"]
	var w := int(carte["taille"][0])
	var h := int(carte["taille"][1])
	var map := GameMap.new(w, h, b["terrains"], float(carte["vitesse_route_mult"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var motif := float(carte.get("taille_motifs", 6))
	var n := w * h

	var elev_noise := _noise(rng.randi(), motif * 2.0)
	var moist_noise := _noise(rng.randi(), motif * 1.5)
	var elev := PackedFloat32Array()
	var moist := PackedFloat32Array()
	elev.resize(n)
	moist.resize(n)
	for y in h:
		for x in w:
			elev[y * w + x] = elev_noise.get_noise_2d(x, y)
			moist[y * w + x] = moist_noise.get_noise_2d(x, y)

	# Répartition par quantiles pour respecter les proportions du JSON.
	var rep: Dictionary = carte["repartition_terrain"]
	var by_elev: Array = range(n)
	by_elev.sort_custom(func(a, c): return elev[a] < elev[c])
	var n_eau := roundi(float(rep["Eau"]) * n)
	var n_mont := roundi(float(rep["Montagne"]) * n)
	var n_roche := roundi(float(rep["Roche"]) * n)
	for k in n_eau:
		map.tiles[by_elev[k]] = GameMap.EAU
	for k in range(n - n_mont, n):
		map.tiles[by_elev[k]] = GameMap.MONTAGNE
	for k in range(n - n_mont - n_roche, n - n_mont):
		map.tiles[by_elev[k]] = GameMap.ROCHE
	var rest: Array = by_elev.slice(n_eau, n - n_mont - n_roche)
	rest.sort_custom(func(a, c): return moist[a] < moist[c])
	var n_sable := roundi(float(rep["Sable"]) * n)
	var n_foret := roundi(float(rep["Foret"]) * n)
	for k in n_sable:
		map.tiles[rest[k]] = GameMap.SABLE
	for k in range(rest.size() - n_foret, rest.size()):
		map.tiles[rest[k]] = GameMap.FORET

	_rivers(map, rng, elev, by_elev, int(carte.get("rivieres", 0)))
	_start_zone(map, carte)
	_connect_regions(map)
	for i in int(carte.get("mines_or", 1)):
		_place_gold(map, rng)
	# Réserve naturelle (ModesPartie) : chaque motif d'espèce existe au moins une fois près du camp.
	if carte.has("motifs_garantis"):
		_graver_motifs(map, rng, carte["motifs_garantis"])
	for y in h:
		for x in w:
			map.reset_resource(x, y)
	map.build_astar()
	return map


static func _noise(noise_seed: int, scale: float) -> FastNoiseLite:
	var nz := FastNoiseLite.new()
	nz.seed = noise_seed
	nz.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nz.frequency = 1.0 / scale
	nz.fractal_type = FastNoiseLite.FRACTAL_FBM
	nz.fractal_octaves = 3
	return nz


## Rivières : partent des hauteurs et descendent la pente jusqu'au bord ou à un lac.
static func _rivers(map: GameMap, rng: RandomNumberGenerator, elev: PackedFloat32Array, by_elev: Array, count: int) -> void:
	var w := map.w
	var n := map.w * map.h
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for r in count:
		var start: int = by_elev[n - 1 - rng.randi_range(0, n / 4)]
		var cur := Vector2i(start % w, start / w)
		var visited := {}
		for step in 140:
			visited[cur] = true
			map.set_t(cur.x, cur.y, GameMap.EAU)
			if cur.x == 0 or cur.y == 0 or cur.x == map.w - 1 or cur.y == map.h - 1:
				break
			var best := Vector2i(-1, -1)
			var best_v := INF
			for d in dirs:
				var nb := cur + d
				if visited.has(nb):
					continue
				var v := elev[nb.y * w + nb.x] + rng.randf() * 0.12
				if v < best_v:
					best_v = v
					best = nb
			if best.x < 0:
				break
			if step > 6 and map.get_t(best.x, best.y) == GameMap.EAU:
				break  # la rivière se jette dans un lac
			cur = best


## Zone de départ en Prairie en bas au centre, camp 3x3 et route jusqu'au bord bas (l'accès).
static func _start_zone(map: GameMap, carte: Dictionary) -> void:
	var zw := int(carte["zone_depart"][0])
	var zh := int(carte["zone_depart"][1])
	var cx := map.w / 2
	map.start_zone = Rect2i(cx - zw / 2, map.h - zh, zw, zh)
	for y in range(map.start_zone.position.y, map.start_zone.end.y):
		for x in range(map.start_zone.position.x, map.start_zone.end.x):
			map.set_t(x, y, GameMap.PRAIRIE)
	map.camp = Rect2i(cx - 1, map.h - zh + 2, 3, 3)
	for y in range(map.camp.end.y, map.h):
		map.road[map.idx(cx, y)] = 1
	map.exit_tile = Vector2i(cx, map.h - 1)


static func reachable(map: GameMap) -> PackedByteArray:
	var w := map.w
	var h := map.h
	var reach := PackedByteArray()
	reach.resize(w * h)
	# Une case à franchir d'un coup d'œil : pont, ou terrain franchissable.
	var libre := PackedByteArray()
	libre.resize(w * h)
	for i in w * h:
		libre[i] = 1 if map.bridge[i] != 0 or map.franchissable[map.tiles[i]] != 0 else 0
	var start := map.camp.position.y * w + map.camp.position.x
	var pile := PackedInt32Array()
	pile.resize(w * h)
	var haut := 1
	pile[0] = start
	reach[start] = 1
	while haut > 0:
		haut -= 1
		var i := pile[haut]
		var x := i % w
		var voisins: Array[int] = [i + 1 if x < w - 1 else -1, i - 1 if x > 0 else -1, i + w if i + w < w * h else -1, i - w]
		for q in voisins:
			if q >= 0 and libre[q] != 0 and reach[q] == 0:
				reach[q] = 1
				pile[haut] = q
				haut += 1
	return reach


## Toute zone franchissable isolée (par l'eau ou la montagne) est reliée au camp
## par le passage le plus court : l'eau devient un gué (sable), la montagne de la roche.
static func _connect_regions(map: GameMap) -> void:
	var w := map.w
	var n := map.w * map.h
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for guard in 400:
		var reach := reachable(map)
		var parent := PackedInt32Array()
		parent.resize(n)
		parent.fill(-2)
		var queue := PackedInt32Array()
		for i in n:
			if reach[i]:
				parent[i] = -1
				queue.append(i)
		var found := -1
		var head := 0
		while head < queue.size() and found < 0:
			var i := queue[head]
			head += 1
			var p := Vector2i(i % w, i / w)
			for d in dirs:
				var q := p + d
				if not map.in_bounds(q.x, q.y):
					continue
				var j := q.y * w + q.x
				if parent[j] != -2:
					continue
				parent[j] = i
				if map.passable(q.x, q.y):
					found = j
					break
				queue.append(j)
		if found < 0:
			return
		var k := parent[found]
		while k >= 0 and not reach[k]:
			map.tiles[k] = GameMap.SABLE if map.tiles[k] == GameMap.EAU else GameMap.ROCHE
			k = parent[k]


## Un gisement d'or sur une roche atteignable, ni trop près ni trop loin du camp,
## et à au moins 12 cases des autres gisements.
static func _place_gold(map: GameMap, rng: RandomNumberGenerator) -> void:
	var reach := reachable(map)
	var c := map.camp.get_center()
	var rocks: Array[int] = []
	var far: Array[int] = []
	for i in map.w * map.h:
		if map.tiles[i] != GameMap.ROCHE or not reach[i]:
			continue
		var p := Vector2i(i % map.w, i / map.w)
		if map.golds.any(func(g): return maxi(absi(g.x - p.x), absi(g.y - p.y)) < 12):
			continue
		rocks.append(i)
		var d := maxi(absi(p.x - c.x), absi(p.y - c.y))
		if d >= 14 and d <= 40:
			far.append(i)
	var pool := far if not far.is_empty() else rocks
	if pool.is_empty():
		return
	var g: int = pool[rng.randi_range(0, pool.size() - 1)]
	map.tiles[g] = GameMap.MINE_OR
	map.golds.append(Vector2i(g % map.w, g / map.w))


# --- Réserve naturelle : motifs garantis -----------------------------------------------------------------

const ECART_MOTIFS := 7.0  # distance minimale entre deux motifs gravés : ils se répartissent sur toute la carte


## Les 8 orientations d'un motif (même calcul que GameState.pattern_variants), cellules [x, y, terrain].
static func _variantes(motif: Array) -> Array:
	var seen := {}
	var out := []
	for mirror in [false, true]:
		for rot in 4:
			var cells := []
			for c in motif:
				var x := int(c[0])
				var y := int(c[1])
				if mirror:
					x = -x
				for r in rot:
					var tmp := x
					x = -y
					y = tmp
				cells.append([x, y, GameMap.TERRAINS.find(str(c[2]))])
			var mx := 999
			var my := 999
			for c in cells:
				mx = mini(mx, c[0])
				my = mini(my, c[1])
			for c in cells:
				c[0] -= mx
				c[1] -= my
			var key := str(cells)
			if not seen.has(key):
				seen[key] = true
				out.append(cells)
	return out


## Case où un motif peut se trouver ou être gravé : dans la carte, hors de la zone de départ, des routes et des
## gisements d'or, pas sur une montagne (les massifs restent intacts).
static func _case_libre(map: GameMap, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= map.w or y >= map.h:
		return false
	var i := map.idx(x, y)
	return not map.start_zone.has_point(Vector2i(x, y)) and map.road[i] == 0 and map.tiles[i] != GameMap.MONTAGNE and map.tiles[i] != GameMap.MINE_OR


## Le motif existe-t-il quelque part sur la carte (hors zone de départ, routes, or, montagnes) ?
static func _motif_present(map: GameMap, variantes: Array, _c := Vector2.ZERO) -> bool:
	for v in variantes:
		for ay in map.h:
			for ax in map.w:
				var ok := true
				for cell in v:
					var x: int = ax + cell[0]
					var y: int = ay + cell[1]
					if not _case_libre(map, x, y) or map.tiles[map.idx(x, y)] != cell[2]:
						ok = false
						break
				if ok:
					return true
	return false


static func _nb_atteignables(map: GameMap) -> int:
	var n := 0
	for v in reachable(map):
		n += v
	return n


## Grave le motif des espèces absentes de toute la carte, des plus grands aux plus petits, à des endroits tirés au
## hasard sur toute la carte et écartés les uns des autres (ECART_MOTIFS), sans couper le reste de la carte du camp
## (un motif d'eau qui isolerait une zone est annulé et tenté ailleurs).
static func _graver_motifs(map: GameMap, rng: RandomNumberGenerator, especes: Array) -> void:
	var c := Vector2(map.camp.get_center())
	var graves := {}
	var centres: Array[Vector2] = []
	var liste := especes.duplicate()
	liste.sort_custom(func(a, b): return a["motif"].size() > b["motif"].size() or (a["motif"].size() == b["motif"].size() and str(a["id"]) < str(b["id"])))
	for def in liste:
		var variantes := _variantes(def["motif"])
		if _motif_present(map, variantes, c):
			continue
		var v: Array = variantes[rng.randi() % variantes.size()]
		var w := 0
		var h := 0
		for cell in v:
			w = maxi(w, cell[0] + 1)
			h = maxi(h, cell[1] + 1)
		for essai in 800:
			var ax := rng.randi_range(1, map.w - w - 1)
			var ay := rng.randi_range(1, map.h - h - 1)
			var centre := Vector2(ax + w / 2.0, ay + h / 2.0)
			if centre.distance_to(c) < 7.0 or (essai < 600 and centres.any(func(o): return o.distance_to(centre) < ECART_MOTIFS)):
				continue
			var place := true
			for y in range(ay - 1, ay + h + 1):
				for x in range(ax - 1, ax + w + 1):
					if not _case_libre(map, x, y) or graves.has(Vector2i(x, y)):
						place = false
			if not place:
				continue
			var avant := _nb_atteignables(map)
			var anciens := {}
			for cell in v:
				var t := Vector2i(ax + cell[0], ay + cell[1])
				anciens[t] = map.tiles[map.idx(t.x, t.y)]
				map.set_t(t.x, t.y, cell[2])
			var eau := v.filter(func(cell): return cell[2] == GameMap.EAU).size()
			# Les cases d'eau gravées sortent du compte ; au-delà, une zone a été coupée du camp.
			if _nb_atteignables(map) < avant - eau:
				for t in anciens:
					map.set_t(t.x, t.y, anciens[t])
				continue
			for y in range(ay - 1, ay + h + 1):
				for x in range(ax - 1, ax + w + 1):
					graves[Vector2i(x, y)] = true
			centres.append(centre)
			break
