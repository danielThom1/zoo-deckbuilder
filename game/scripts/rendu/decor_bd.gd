class_name DecorBD
extends Node2D
## Végétation et reliefs posés sur la carte : un Sprite2D par élément, trié en Y.
## Placement déterministe (même graine = même forêt) et reconstruit case par case.

const MANIFESTE := "res://assets/bd/decor_bd.json"
const HAUTEUR_FALAISE := 0.55   # doit correspondre à hauteur_falaise du shader

## Mélanges par terrain : nom de famille → poids. Une famille = tous les fichiers « famille_N ».
const FORET := {"feuillu_chene": 3.0, "feuillu_hetre": 3.0, "feuillu_sombre": 2.5, "pin": 2.5, "sapin": 1.5, "bouleau": 1.0, "feuillu_automne": 0.5, "feuillu_or": 0.4}
const PRAIRIE_RARE := {"buisson": 3.0, "feuillu_chene": 0.6, "bouleau": 0.4, "fougere": 1.0}
const SABLE := {"herbes_hautes": 2.0, "buisson_sec": 1.0, "rocher": 0.6}
const ROCHE := {"rocher": 4.0, "buisson_sec": 0.5}

## Axe « végétation » : feuillus d'automne seulement en bosquets, lisières et arbres de prairie
const FORET_VERTE := {"feuillu_chene": 3.0, "feuillu_hetre": 3.0, "feuillu_sombre": 2.5, "pin": 2.5, "sapin": 1.5, "bouleau": 1.0}
const BOSQUET_AUTOMNE := {"feuillu_automne": 3.0, "feuillu_or": 2.5, "feuillu_chene": 1.5, "bouleau": 1.0}
const LISIERE := {"buisson": 3.0, "fougere": 2.0, "bouleau": 0.8, "souche": 0.3}
const ARBRES_PRAIRIE := {"feuillu_chene": 2.0, "feuillu_hetre": 1.5, "bouleau": 1.0}
const FAMILLES_AU_VENT := ["feuillu", "pin", "sapin", "bouleau", "saule", "buisson", "fougere", "herbes", "roseaux", "acacia", "baobab"]
const VENT := preload("res://scripts/rendu/vent_bd.gdshader")

static var _cache := {}
static var _mat_vent: ShaderMaterial

var map: GameMap
var tile := 16.0
var graine := 0
var px_par_case := 120.0
var familles := {}          # famille → Array[String] (noms d'éléments)
var elements := {}          # nom → {texture, pied}
var par_case := {}          # Vector2i → Array[Node]
var masquees := {}          # cases sans décor (bâtiments, chantiers, enclos aménagés…)


func _init() -> void:
	y_sort_enabled = true


func construire(m: GameMap, taille_case: float, g := 0) -> void:
	map = m
	tile = taille_case
	graine = g
	_charger()
	for c in get_children():
		c.queue_free()
	par_case.clear()
	for y in m.h:
		for x in m.w:
			_peupler(x, y)


func rafraichir(cases: Array) -> void:
	for p in cases:
		var q := Vector2i(p)
		if not map.in_bounds(q.x, q.y):
			continue
		for n in par_case.get(q, []):
			n.queue_free()
		par_case.erase(q)
		_peupler(q.x, q.y)


## Cases à laisser nues (bâtiments, chantiers) : le décor y est retiré, puis remis quand elles se libèrent.
func masquer(cases: Dictionary) -> void:
	var changees := []
	for k in masquees:
		if not cases.has(k):
			changees.append(k)
	for k in cases:
		if not masquees.has(k):
			changees.append(k)
	masquees = cases.duplicate()
	if not changees.is_empty():
		rafraichir(changees)


func _charger() -> void:
	if _cache.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(MANIFESTE))
		_cache["px"] = float(j["px_par_case"])
		var el := {}
		var fam := {}
		for nom in j["elements"]:
			var e: Dictionary = j["elements"][nom]
			el[nom] = {"texture": load(e["fichier"]), "pied": Vector2(e["pied"][0], e["pied"][1])}
			var f: String = nom
			var parties: PackedStringArray = str(nom).split("_")
			if parties[-1].is_valid_int():
				f = "_".join(parties.slice(0, parties.size() - 1))
			if not fam.has(f):
				fam[f] = []
			fam[f].append(nom)
		_cache["elements"] = el
		_cache["familles"] = fam
	px_par_case = _cache["px"]
	elements = _cache["elements"]
	familles = _cache["familles"]


func _rng(x: int, y: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(Vector3i(x, y, graine))
	return r


func _choisir(r: RandomNumberGenerator, melange: Dictionary) -> String:
	var total := 0.0
	for k in melange:
		total += melange[k]
	var t := r.randf() * total
	for k in melange:
		t -= melange[k]
		if t <= 0.0:
			var liste: Array = familles.get(k, [])
			return liste[r.randi() % liste.size()] if not liste.is_empty() else ""
	return ""


func _poser(case_: Vector2i, nom: String, pos_cases: Vector2, echelle := 1.0, miroir := false) -> void:
	if nom == "" or not elements.has(nom):
		return
	var e: Dictionary = elements[nom]
	var s := Sprite2D.new()
	s.texture = e["texture"]
	s.centered = false
	s.offset = -e["pied"]
	s.flip_h = miroir
	if miroir:
		s.offset.x = -(s.texture.get_width() - e["pied"].x)
	var k := tile / px_par_case * echelle
	s.scale = Vector2(k, k)
	s.position = pos_cases * tile
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if CarteBD.AXES.get("vie", false):
		for f in FAMILLES_AU_VENT:
			if nom.begins_with(f):
				if _mat_vent == null:
					_mat_vent = ShaderMaterial.new()
					_mat_vent.shader = VENT
				s.material = _mat_vent
				break
	add_child(s)
	if not par_case.has(case_):
		par_case[case_] = []
	par_case[case_].append(s)


func _voisin_eau(x: int, y: int) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q: Vector2i = Vector2i(x, y) + d
		if map.in_bounds(q.x, q.y) and map.get_t(q.x, q.y) == GameMap.EAU and not map.bridge[map.idx(q.x, q.y)]:
			return true
	return false


## Nombre de voisins (8 directions) du même terrain.
func _voisins(x: int, y: int, t: int) -> int:
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if (dx != 0 or dy != 0) and map.in_bounds(x + dx, y + dy) and map.get_t(x + dx, y + dy) == t:
				n += 1
	return n


## Tirage stable par bloc de cases (bosquets, groupes d'arbres) : même valeur pour tout le bloc.
func _bloc(x: int, y: int, taille: int, sel: int) -> float:
	var r := RandomNumberGenerator.new()
	r.seed = hash(Vector4i(floori(float(x) / taille), floori(float(y) / taille), graine, sel))
	return r.randf()


func _peupler(x: int, y: int) -> void:
	var i := map.idx(x, y)
	if map.road[i] or map.bridge[i] or map.in_camp(x, y) or masquees.has(Vector2i(x, y)):
		return
	var r := _rng(x, y)
	if CarteBD.AXES.get("vegetation", false):
		_peupler_enrichi(x, y, r)
		return
	var c := Vector2i(x, y)
	var base := Vector2(x + 0.5, y + 0.5)
	var j := func(a: float) -> Vector2: return Vector2(r.randf_range(-a, a), r.randf_range(-a, a))
	match map.get_t(x, y):
		GameMap.FORET:
			var n := 2 if r.randf() < 0.7 else 3
			for k in n:
				var o: Vector2 = Vector2(-0.22 + 0.44 * (k % 2), -0.2 + 0.4 * float(k / 2)) + j.call(0.14)
				_poser(c, _choisir(r, FORET), base + o + Vector2(0, 0.25), r.randf_range(0.95, 1.3), r.randf() < 0.5)
		GameMap.ROCHE:
			for k in (1 if r.randf() < 0.6 else 2):
				_poser(c, _choisir(r, ROCHE), base + j.call(0.3) + Vector2(0, 0.2), r.randf_range(0.8, 1.1), r.randf() < 0.5)
		GameMap.MONTAGNE:
			if (x + y * 2) % 3 != 1 and r.randf() < 0.7:
				_poser(c, _choisir(r, {"pic": 1.0}), base + Vector2(r.randf_range(-0.2, 0.2), 0.55 - HAUTEUR_FALAISE), r.randf_range(0.7, 0.95), r.randf() < 0.5)
			elif r.randf() < 0.8:
				_poser(c, _choisir(r, {"rocher": 1.0}), base + j.call(0.3) + Vector2(0, 0.4 - HAUTEUR_FALAISE), 0.8)
		GameMap.MINE_OR:
			# Gisement d'or : gros rocher veiné bien visible, et un second plus petit à côté
			_poser(c, _choisir(r, {"rocher_or": 1.0}), base + Vector2(-0.12, 0.35), 1.9)
			_poser(c, _choisir(r, {"rocher_or": 1.0}), base + Vector2(0.32, 0.4), 1.1, true)
		GameMap.SABLE:
			if r.randf() < 0.35:
				_poser(c, _choisir(r, SABLE), base + j.call(0.3), r.randf_range(0.8, 1.1), r.randf() < 0.5)
		GameMap.PRAIRIE:
			if _voisin_eau(x, y) and r.randf() < 0.55:
				_poser(c, _choisir(r, {"roseaux": 1.0}), base + j.call(0.3), r.randf_range(0.8, 1.1), r.randf() < 0.5)
			elif r.randf() < 0.06:
				_poser(c, _choisir(r, PRAIRIE_RARE), base + j.call(0.25), r.randf_range(0.85, 1.1), r.randf() < 0.5)
		GameMap.EAU:
			if r.randf() < 0.025:
				_poser(c, _choisir(r, {"rocher": 1.0}), base + Vector2(0, 0.3), 0.7)


## Axe « végétation » (11/11/2026) : lisières, bosquets d'automne groupés, arbres de prairie et saules,
## arbres plus petits au bord des forêts, pics à l'échelle du massif, rocaille moins tamponnée.
func _peupler_enrichi(x: int, y: int, r: RandomNumberGenerator) -> void:
	var c := Vector2i(x, y)
	var base := Vector2(x + 0.5, y + 0.5)
	var j := func(a: float) -> Vector2: return Vector2(r.randf_range(-a, a), r.randf_range(-a, a))
	match map.get_t(x, y):
		GameMap.FORET:
			var v := _voisins(x, y, GameMap.FORET)
			var bord := v <= 5
			var melange: Dictionary = BOSQUET_AUTOMNE if _bloc(x, y, 5, 1) < 0.14 else FORET_VERTE
			var n := 2 if (bord or r.randf() < 0.6) else 3
			for k in n:
				var o: Vector2 = Vector2(-0.22 + 0.44 * (k % 2), -0.2 + 0.4 * float(k / 2)) + j.call(0.16)
				var e := r.randf_range(0.72, 0.98) if bord else r.randf_range(1.0, 1.4)
				_poser(c, _choisir(r, melange), base + o + Vector2(0, 0.25), e, r.randf() < 0.5)
			if bord and r.randf() < 0.45:
				_poser(c, _choisir(r, LISIERE), base + j.call(0.35) + Vector2(0, 0.4), r.randf_range(0.6, 0.85), r.randf() < 0.5)
		GameMap.ROCHE:
			# Rochers d'origine (densité inchangée : 1 ou 2 par case), plus parfois un buisson sec ou une souche
			for k in (1 if r.randf() < 0.6 else 2):
				_poser(c, _choisir(r, ROCHE), base + j.call(0.3) + Vector2(0, 0.2), r.randf_range(0.8, 1.1), r.randf() < 0.5)
			if r.randf() < 0.12:
				_poser(c, _choisir(r, {"buisson_sec": 2.0, "souche": 1.0}), base + j.call(0.3), r.randf_range(0.6, 0.85), r.randf() < 0.5)
		GameMap.MONTAGNE:
			# Massifs : placement d'origine, inchangé (le détail des roches prime)
			if (x + y * 2) % 3 != 1 and r.randf() < 0.7:
				_poser(c, _choisir(r, {"pic": 1.0}), base + Vector2(r.randf_range(-0.2, 0.2), 0.55 - HAUTEUR_FALAISE), r.randf_range(0.7, 0.95), r.randf() < 0.5)
			elif r.randf() < 0.8:
				_poser(c, _choisir(r, {"rocher": 1.0}), base + j.call(0.3) + Vector2(0, 0.4 - HAUTEUR_FALAISE), 0.8)
		GameMap.MINE_OR:
			_poser(c, _choisir(r, {"rocher_or": 1.0}), base + Vector2(-0.12, 0.35), 1.9)
			_poser(c, _choisir(r, {"rocher_or": 1.0}), base + Vector2(0.32, 0.4), 1.1, true)
		GameMap.SABLE:
			var pres_eau := _voisin_eau(x, y)
			if r.randf() < (0.15 if pres_eau else 0.3):
				_poser(c, _choisir(r, {"herbes_hautes": 2.0, "buisson_sec": 1.0} if not pres_eau else {"herbes_hautes": 1.0}), base + j.call(0.3), r.randf_range(0.7, 1.0), r.randf() < 0.5)
		GameMap.PRAIRIE:
			var eau := _voisin_eau(x, y)
			var foret := _voisins(x, y, GameMap.FORET)
			if eau and r.randf() < 0.5:
				_poser(c, _choisir(r, {"roseaux": 1.0}), base + j.call(0.3), r.randf_range(0.8, 1.1), r.randf() < 0.5)
			elif eau and r.randf() < 0.08:
				_poser(c, _choisir(r, {"saule": 1.0}), base + j.call(0.2) + Vector2(0, 0.2), r.randf_range(0.85, 1.1), r.randf() < 0.5)
			elif foret > 0 and r.randf() < 0.32:
				_poser(c, _choisir(r, LISIERE), base + j.call(0.3), r.randf_range(0.6, 0.85), r.randf() < 0.5)
			elif _bloc(x, y, 4, 2) < 0.25 and r.randf() < 0.14:
				_poser(c, _choisir(r, ARBRES_PRAIRIE), base + j.call(0.25) + Vector2(0, 0.2), r.randf_range(0.85, 1.15), r.randf() < 0.5)
			elif r.randf() < 0.04:
				_poser(c, _choisir(r, {"buisson": 3.0, "fougere": 1.0}), base + j.call(0.25), r.randf_range(0.7, 0.95), r.randf() < 0.5)
		GameMap.EAU:
			if r.randf() < 0.02:
				_poser(c, _choisir(r, {"rocher": 1.0}), base + Vector2(0, 0.3), 0.65)


## Axe travail : les arbres (ou rochers) d'une case tremblent sous les coups d'un collaborateur.
func secouer(case_: Vector2i, force := 1.0) -> void:
	for n in par_case.get(case_, []):
		var s := n as Sprite2D
		if s == null or s.has_meta("secoue"):
			continue
		s.set_meta("secoue", true)
		var tw := s.create_tween()
		var a := 0.06 * force
		tw.tween_property(s, "rotation", a, 0.05)
		tw.tween_property(s, "rotation", -a * 0.7, 0.08)
		tw.tween_property(s, "rotation", a * 0.35, 0.07)
		tw.tween_property(s, "rotation", 0.0, 0.08)
		tw.tween_callback(func(): s.remove_meta("secoue"))
