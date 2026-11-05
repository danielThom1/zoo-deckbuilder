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
