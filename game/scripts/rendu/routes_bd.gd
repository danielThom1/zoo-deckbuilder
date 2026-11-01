class_name RoutesBD
extends Node2D
## Chemins et ponts tracés en continu d'une case à l'autre (y compris en diagonale),
## avec liseré d'encre, bordure et cailloux. Redessiné quand CarteBD détecte un changement.

const ENCRE := Color("14202B")
const BORD := Color("C9A468")
const CHEMIN := Color("E6CB94")
const PLANCHE := Color("B8864E")
const PLANCHE_SOMBRE := Color("8A6038")

const PAVE := Color("E4DCC8")
const PAVE_BORD := Color("B9AE96")

var map: GameMap
var tile := 16.0
var interieur := {}   # cases de route dans l'enceinte du zoo : allées pavées
var acces := true     # tronçon de route qui sort par le bas de la carte (case Accès)


## Change les cases pavées (enceinte du zoo) ; ne redessine que si elles ont changé.
func definir_interieur(cases: Dictionary) -> void:
	if cases.size() == interieur.size() and cases.keys().all(func(k): return interieur.has(k)):
		return
	interieur = cases.duplicate()
	queue_redraw()


func construire(m: GameMap, taille_case: float) -> void:
	map = m
	tile = taille_case
	queue_redraw()


func _est(x: int, y: int) -> bool:
	if not map.in_bounds(x, y):
		return false
	var i := map.idx(x, y)
	return map.road[i] != 0 or map.bridge[i] == 1


func _pont(x: int, y: int) -> bool:
	return map.in_bounds(x, y) and map.bridge[map.idx(x, y)] == 1


func _segments() -> Array:
	var segs := []
	for y in map.h:
		for x in map.w:
			if not _est(x, y):
				continue
			var droite := _est(x + 1, y)
			var bas := _est(x, y + 1)
			if droite: segs.append([Vector2i(x, y), Vector2i(x + 1, y)])
			if bas: segs.append([Vector2i(x, y), Vector2i(x, y + 1)])
			if _est(x + 1, y + 1) and not droite and not _est(x + 1, y) and not bas and not _est(x, y + 1):
				segs.append([Vector2i(x, y), Vector2i(x + 1, y + 1)])
			if _est(x - 1, y + 1) and not _est(x - 1, y) and not bas:
				segs.append([Vector2i(x, y), Vector2i(x - 1, y + 1)])
	return segs


func _draw() -> void:
	if map == null:
		return
	var segs := _segments()
	var cases := []
	for y in map.h:
		for x in map.w:
			if _est(x, y):
				cases.append(Vector2i(x, y))
	var c := func(p: Vector2i) -> Vector2: return (Vector2(p) + Vector2(0.5, 0.5)) * tile
	var l := tile * 0.62
	# tronçon d'accès vers l'extérieur (sous la case Accès)
	var ex: Vector2 = c.call(map.exit_tile)
	if acces:
		for passe in 3:
			var lg: float = [l + 3.0, l, l - 4.0][passe]
			draw_line(ex, ex + Vector2(0, tile * 2.2), [ENCRE, BORD, CHEMIN][passe], lg)
	# trois passes : encre, bordure, chemin (allées pavées dans l'enceinte)
	for passe in 3:
		var larg: float = [l + 3.0, l, l - 4.0][passe]
		for s in segs:
			if _pont(s[0].x, s[0].y) and _pont(s[1].x, s[1].y):
				continue
			var pav: bool = interieur.has(s[0]) and interieur.has(s[1])
			var col: Color = [ENCRE, PAVE_BORD if pav else BORD, PAVE if pav else CHEMIN][passe]
			draw_line(c.call(s[0]), c.call(s[1]), col, larg)
		for p in cases:
			if not _pont(p.x, p.y):
				var pav2: bool = interieur.has(p)
				draw_circle(c.call(p), larg * 0.5, [ENCRE, PAVE_BORD if pav2 else BORD, PAVE if pav2 else CHEMIN][passe])
	# cailloux sur les chemins, joints de dalles sur les allées
	for p in cases:
		if _pont(p.x, p.y):
			continue
		var ctr0: Vector2 = c.call(p)
		if interieur.has(p):
			var j := Color(ENCRE, 0.28)
			draw_line(ctr0 + Vector2(-3.5, -1), ctr0 + Vector2(3.5, -1), j, 0.7)
			draw_line(ctr0 + Vector2(-1.5, -1), ctr0 + Vector2(-1.5, 3), j, 0.7)
			draw_line(ctr0 + Vector2(2, -4), ctr0 + Vector2(2, -1), j, 0.7)
			continue
		var r := RandomNumberGenerator.new()
		r.seed = hash(p)
		for k in 2:
			var q: Vector2 = ctr0 + Vector2(r.randf_range(-0.22, 0.22), r.randf_range(-0.22, 0.22)) * tile
			draw_circle(q, 0.9, BORD)
	# ponts : tablier de planches avec garde-corps
	for p in cases:
		if not _pont(p.x, p.y):
			continue
		var horiz := _est(p.x - 1, p.y) or _est(p.x + 1, p.y)
		var ctr: Vector2 = c.call(p)
		var rr := Rect2(ctr - Vector2(tile * 0.5, tile * 0.32), Vector2(tile, tile * 0.64)) if horiz else Rect2(ctr - Vector2(tile * 0.32, tile * 0.5), Vector2(tile * 0.64, tile))
		draw_rect(Rect2(rr.position + Vector2(0, rr.size.y), Vector2(rr.size.x, 2.5)), PLANCHE_SOMBRE)
		draw_rect(rr, PLANCHE)
		var n := 5
		for k in range(1, n):
			if horiz:
				var x := rr.position.x + rr.size.x * k / n
				draw_line(Vector2(x, rr.position.y), Vector2(x, rr.end.y), Color(ENCRE, 0.55), 0.8)
			else:
				var y := rr.position.y + rr.size.y * k / n
				draw_line(Vector2(rr.position.x, y), Vector2(rr.end.x, y), Color(ENCRE, 0.55), 0.8)
		draw_rect(rr, ENCRE, false, 1.4)
		# garde-corps
		if horiz:
			for yy in [rr.position.y, rr.end.y]:
				draw_line(Vector2(rr.position.x, yy - 3), Vector2(rr.end.x, yy - 3), ENCRE, 2.6)
				draw_line(Vector2(rr.position.x, yy - 3), Vector2(rr.end.x, yy - 3), PLANCHE_SOMBRE, 1.2)
		else:
			for xx in [rr.position.x, rr.end.x]:
				draw_line(Vector2(xx, rr.position.y - 3), Vector2(xx, rr.end.y - 3), ENCRE, 2.6)
				draw_line(Vector2(xx, rr.position.y - 3), Vector2(xx, rr.end.y - 3), PLANCHE_SOMBRE, 1.2)
