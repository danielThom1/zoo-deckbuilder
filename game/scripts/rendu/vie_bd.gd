class_name VieBD
extends Node2D
## Vie de la carte (11/11/2026), au-dessus des unités. Trois axes de CarteBD.AXES :
## - « journee » : lueurs du soir (feu du camp, fenêtres) ; la teinte et les ombres sont dans CarteBD
## - « travail » : copeaux, éclats, poussière de chantier, fumées, arbres qui tremblent, herbe qui s'use
## - « faune »   : vols d'oiseaux (et envols quand on abat un arbre), papillons, libellules, poissons
## Tout est dessiné à l'encre ou en petites particules, sans nouvelles images. Rare et discret par défaut ;
## « demo » multiplie les apparitions (atelier de capture uniquement).

const FUMEES := ["maison", "cuisine", "snack"]
const FENETRES := ["maison", "boutique", "snack", "cuisine", "entretien", "intendance", "kiosque", "comptoir", "agence", "cabinet", "acquisitions"]
const ENCRE := Color("14202B")

var m              # main.gd (game, camera, TILE)
var carte: CarteBD
var demo := 1.0
var T := 16.0

var _emetteurs := {}       # clé -> CPUParticles2D (travail, fumées)
var _vus := {}             # clés vues cette image
var _cible_vue := {}       # ouvrier -> dernière case travaillée (envols, secousses)
var _secousse := {}        # ouvrier -> chrono
var _t_fumees := 0.0
var _t_usure := 0.0
var _t_publier := 0.0
var _dernier_temps := -1.0
var _disque: Texture2D
var _bouffee: Texture2D
var _lueur: Texture2D
var _lueurs: Node2D
var _sources_lueur: Array = []   # [position monde, rayon en cases, est un feu]

var oiseaux: Array = []    # {p, v, ph, s, alt, alt_v}
var papillons: Array = []  # {p, cible, ph, col, t}
var libellules: Array = [] # {p, cible, t, pause}
var ronds: Array = []      # {p, t, saut}
var _t_vol := 4.0
var _t_poisson := 1.0
var _rng := RandomNumberGenerator.new()


func _init(principal, c: CarteBD) -> void:
	m = principal
	carte = c
	T = m.TILE
	z_index = 5
	_rng.seed = 1234
	_disque = _texture_disque(16, false)
	_bouffee = _texture_disque(32, true)
	_lueur = _texture_lueur()
	_lueurs = Node2D.new()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_lueurs.material = add
	_lueurs.draw.connect(_dessiner_lueurs)
	add_child(_lueurs)


## Appelé à chaque pas de simulation (y compris pendant l'avance rapide --sim) : l'herbe s'use sous les pas.
func observer(dt_jeu: float) -> void:
	if not CarteBD.AXES.get("travail", false) or dt_jeu <= 0.0:
		return
	for w in m.game.workers:
		if w.offmap or w.path.is_empty():
			continue
		carte.usure_ajouter(w.pos, 0.11 * dt_jeu)
	_t_usure += dt_jeu
	if _t_usure >= 2.0:
		carte.usure_attenuer(exp(-_t_usure / 900.0))  # demi-vie d'environ 10 minutes de jeu (2 journées)
		_t_usure = 0.0


func _process(delta: float) -> void:
	var g = m.game
	if g == null:
		return
	visible = m.mt.phase != "night"
	# Temps de jeu écoulé (respecte la pause et les vitesses)
	var tj: float = g.time
	var dt_jeu := 0.0
	if _dernier_temps >= 0.0 and tj >= _dernier_temps and tj - _dernier_temps < 5.0:
		dt_jeu = tj - _dernier_temps
	_dernier_temps = tj
	observer(dt_jeu)
	_t_publier += delta
	if _t_publier > 0.4:
		_t_publier = 0.0
		carte.usure_publier()
	_vus.clear()
	if CarteBD.AXES.get("travail", false):
		_travail(delta, dt_jeu > 0.0)
	if CarteBD.AXES.get("journee", false) or CarteBD.AXES.get("travail", false):
		_t_fumees -= delta
		if _t_fumees <= 0.0:
			_t_fumees = 1.0
			_sources_fixes()
		for k in _emetteurs:
			if str(k).begins_with("fumee"):
				_vus[k] = true
	for k in _emetteurs.keys():
		if not _vus.has(k):
			var e: CPUParticles2D = _emetteurs[k]
			e.emitting = false
			if not str(k).begins_with("fumee"):
				_emetteurs.erase(k)
				get_tree().create_timer(e.lifetime + 0.2).timeout.connect(e.queue_free)
	if CarteBD.AXES.get("faune", false):
		_faune(delta, dt_jeu > 0.0 or demo > 1.0)
	_lueurs.queue_redraw()
	queue_redraw()


# ------------------------------------------------------------------ travail

func _travail(delta: float, en_marche: bool) -> void:
	for w in m.game.workers:
		if w.offmap or w.task.is_empty():
			_cible_vue.erase(w)
			continue
		var t: Dictionary = w.task
		var cle := "w%d" % w.get_instance_id()
		if t.get("type") == "extract" and t.get("phase") == "working" and en_marche:
			var tg: Vector2i = t["target"]
			var res := str(t.get("res", "bois"))
			var p := (Vector2(tg) + Vector2(0.5, 0.3)) * T
			_emettre(cle + res, p, res)
			_secousse[w] = _secousse.get(w, 0.0) - delta
			if _secousse[w] <= 0.0:
				_secousse[w] = 0.55
				carte.decor.secouer(tg, 1.0 if res == "bois" else 0.4)
			if res == "bois" and _cible_vue.get(w, Vector2i(-1, -1)) != tg:
				if CarteBD.AXES.get("faune", false) and _rng.randf() < 0.45 * demo:
					_envol(Vector2(tg) * T + Vector2(T * 0.5, T * 0.2), _rng.randi_range(2, 4))
				_cible_vue[w] = tg
		elif t.get("type") == "build" and w.path.is_empty() and en_marche:
			_emettre(cle + "poussiere", w.pos * T + Vector2(0, T * 0.15), "poussiere")


func _emettre(cle: String, p: Vector2, sorte: String) -> void:
	_vus[cle] = true
	var e: CPUParticles2D = _emetteurs.get(cle)
	if e == null:
		e = _particules(sorte)
		add_child(e)
		_emetteurs[cle] = e
	e.position = p
	e.emitting = true


func _particules(sorte: String) -> CPUParticles2D:
	var e := CPUParticles2D.new()
	e.local_coords = false
	var ramp := Gradient.new()
	match sorte:
		"bois", "pierre", "or":
			e.amount = 7
			e.lifetime = 0.55
			e.explosiveness = 0.25
			e.direction = Vector2(0, -1)
			e.spread = 70.0
			e.initial_velocity_min = 22.0
			e.initial_velocity_max = 42.0
			e.gravity = Vector2(0, 150)
			e.angular_velocity_min = -360.0
			e.angular_velocity_max = 360.0
			e.scale_amount_min = 1.3
			e.scale_amount_max = 2.4
			var cols: Array = {"bois": [Color("8B5A2B"), Color("D9A55C")], "pierre": [Color("8F8A80"), Color("D6D2C8")], "or": [Color("B8860B"), Color("FFD95A")]}[sorte]
			ramp.colors = PackedColorArray(cols)
			e.color_initial_ramp = ramp
		"poussiere":
			e.texture = _disque
			e.amount = 4
			e.lifetime = 1.0
			e.direction = Vector2(0, -1)
			e.spread = 160.0
			e.initial_velocity_min = 5.0
			e.initial_velocity_max = 12.0
			e.gravity = Vector2(0, -6)
			e.scale_amount_min = 0.25
			e.scale_amount_max = 0.45
			e.scale_amount_curve = _courbe(0.5, 1.4)
			ramp.colors = PackedColorArray([Color(0.9, 0.82, 0.64, 0.55), Color(0.9, 0.82, 0.64, 0.0)])
			e.color_ramp = ramp
		"fumee":
			e.texture = _bouffee
			e.amount = 5
			e.lifetime = 3.0
			e.preprocess = 3.0
			e.direction = Vector2(0.25, -1)
			e.spread = 10.0
			e.initial_velocity_min = 5.0
			e.initial_velocity_max = 8.0
			e.gravity = Vector2(3, -1.5)
			e.scale_amount_min = 0.11
			e.scale_amount_max = 0.16
			e.scale_amount_curve = _courbe(0.6, 2.2)
			ramp.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
			ramp.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.85), Color(0.85, 0.87, 0.9, 0.0)])
			e.color_ramp = ramp
	return e


## Fumées (maisons, cuisine, snack, feu du camp) et lueurs du soir : positions tirées des bâtiments terminés.
func _sources_fixes() -> void:
	var g = m.game
	_sources_lueur.clear()
	var camp: Rect2i = g.map.camp
	var feu := (Vector2(camp.position) + Vector2(camp.size) * Vector2(0.5, 0.62)) * T
	_sources_lueur.append([feu, 1.9, true])
	var cles := {}
	if CarteBD.AXES.get("travail", false):
		cles["fumee_camp"] = feu + Vector2(0, -T * 0.3)
	for s in g.sites:
		if not s.done:
			continue
		var id: String = s.def_id()
		var r := Rect2(s.rect)
		if CarteBD.AXES.get("travail", false) and id in FUMEES:
			cles["fumee%d" % s.id] = (r.position + Vector2(r.size.x * 0.72, 0.15)) * T
		if id in FENETRES:
			_sources_lueur.append([(r.position + r.size * Vector2(0.5, 0.65)) * T, 1.3, false])
	for k in cles:
		if not _emetteurs.has(k):
			var e := _particules("fumee")
			add_child(e)
			_emetteurs[k] = e
		_emetteurs[k].position = cles[k]
		_emetteurs[k].emitting = true
	for k in _emetteurs.keys():
		if str(k).begins_with("fumee") and not cles.has(k):
			_emetteurs[k].queue_free()
			_emetteurs.erase(k)


func _dessiner_lueurs() -> void:
	if not CarteBD.AXES.get("journee", false):
		return
	var h: float = carte.heure_forcee if carte.heure_forcee >= 0.0 else carte.heure
	var soir := smoothstep(0.8, 0.95, h)
	if soir <= 0.0:
		return
	var t := Time.get_ticks_msec() / 1000.0
	for s in _sources_lueur:
		var p: Vector2 = s[0]
		var r: float = s[1] * T * (1.0 + (0.06 * sin(t * 7.0 + p.x) + 0.04 * sin(t * 13.0) if s[2] else 0.0))
		var a: float = soir * (0.42 if s[2] else 0.3)
		_lueurs.draw_texture_rect(_lueur, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 0.62, 0.25, a))


# ------------------------------------------------------------------ faune

func _faune(delta: float, en_marche: bool) -> void:
	var vue := _vue()
	var zoom: float = m.camera.zoom.x if m.camera else 1.0
	# Vols qui traversent l'écran
	_t_vol -= delta * demo
	if _t_vol <= 0.0:
		_t_vol = _rng.randf_range(18.0, 40.0)
		_vol(vue)
	if en_marche:
		# Poissons : ronds dans l'eau profonde visible
		_t_poisson -= delta * demo
		if _t_poisson <= 0.0:
			_t_poisson = _rng.randf_range(2.5, 6.0)
			var c := _case_au_hasard(vue, func(x, y): return _eau_profonde(x, y), 30)
			if c.x >= 0:
				ronds.append({"p": (Vector2(c) + Vector2(_rng.randf_range(0.2, 0.8), _rng.randf_range(0.3, 0.8))) * T, "t": 0.0, "saut": _rng.randf() < 0.35})
	for r in ronds:
		r["t"] += delta
	ronds = ronds.filter(func(r): return r["t"] < 1.8)
	# Oiseaux
	for o in oiseaux:
		o["v"] += o.get("acc", Vector2.ZERO) * delta
		o["p"] += o["v"] * delta
		o["ph"] += delta * o.get("bat", 9.0)
		o["alt"] = minf(1.0, o["alt"] + delta * o.get("monte", 0.0))
	var marge := vue.grow(200.0)
	oiseaux = oiseaux.filter(func(o): return marge.has_point(o["p"]))
	# Papillons et libellules : seulement quand on voit le détail
	if zoom >= 2.2 and en_marche:
		var n_pap := int(4 * minf(demo, 2.0))
		while papillons.size() < n_pap:
			var c := _case_au_hasard(vue, func(x, y): return m.game.map.get_t(x, y) == GameMap.PRAIRIE, 25)
			if c.x < 0:
				break
			var p := (Vector2(c) + Vector2(0.5, 0.5)) * T
			var col: Color = [Color("FFFFFF"), Color("FFD54A"), Color("9FC4FF"), Color("FFB0D0")][_rng.randi() % 4]
			papillons.append({"p": p, "cible": p, "ph": _rng.randf() * 6.0, "col": col, "t": 0.0, "vie": _rng.randf_range(10.0, 22.0)})
		var n_lib := int(2 * minf(demo, 2.0))
		while libellules.size() < n_lib:
			var c := _case_au_hasard(vue, func(x, y): return m.game.map.get_t(x, y) == GameMap.PRAIRIE and carte.decor._voisin_eau(x, y), 40)
			if c.x < 0:
				break
			var p := (Vector2(c) + Vector2(0.5, 0.5)) * T
			libellules.append({"p": p, "cible": p, "t": 0.0, "pause": 0.5, "vie": _rng.randf_range(12.0, 25.0), "base": p})
	for b in papillons:
		b["t"] += delta
		b["ph"] += delta * 14.0
		if b["p"].distance_to(b["cible"]) < 2.0:
			b["cible"] = b["p"] + Vector2(_rng.randf_range(-1.6, 1.6), _rng.randf_range(-1.2, 1.2)) * T
		b["p"] += (b["cible"] - b["p"]).normalized() * 9.0 * delta + Vector2(0, sin(b["ph"] * 0.5) * 6.0 * delta)
	papillons = papillons.filter(func(b): return b["t"] < b["vie"] and vue.grow(40).has_point(b["p"]))
	for l in libellules:
		l["t"] += delta
		l["pause"] -= delta
		if l["pause"] <= 0.0:
			l["cible"] = l["base"] + Vector2(_rng.randf_range(-1.5, 1.5), _rng.randf_range(-1.5, 1.5)) * T
			l["pause"] = _rng.randf_range(0.6, 1.6)
		l["p"] = l["p"].lerp(l["cible"], minf(1.0, delta * 6.0))
	libellules = libellules.filter(func(l): return l["t"] < l["vie"] and vue.grow(40).has_point(l["p"]))


func _vol(vue: Rect2) -> void:
	var gauche := _rng.randf() < 0.5
	var y := _rng.randf_range(vue.position.y + vue.size.y * 0.15, vue.end.y - vue.size.y * 0.25)
	var depart := Vector2(vue.position.x - 60.0 if gauche else vue.end.x + 60.0, y)
	var v := Vector2((1.0 if gauche else -1.0) * _rng.randf_range(38.0, 55.0), _rng.randf_range(-8.0, 8.0))
	var n := _rng.randi_range(3, 6)
	for i in n:
		var rang := float(i + 1) / 2.0
		var cote := -1.0 if i % 2 == 0 else 1.0
		var decal := Vector2(-v.normalized().x * rang * 9.0, cote * rang * 6.0)
		oiseaux.append({"p": depart + decal, "v": v, "ph": _rng.randf() * 6.0, "s": _rng.randf_range(3.2, 4.2), "alt": 1.0})


## Envol : des oiseaux quittent la forêt où l'on abat un arbre.
func _envol(p: Vector2, n: int) -> void:
	var dir := Vector2.from_angle(_rng.randf_range(-PI * 0.9, -PI * 0.1))
	for i in n:
		var v := dir.rotated(_rng.randf_range(-0.5, 0.5)) * _rng.randf_range(20.0, 30.0)
		oiseaux.append({"p": p + Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-4, 4)), "v": v, "acc": v.normalized() * 30.0,
			"ph": _rng.randf() * 6.0, "s": _rng.randf_range(2.6, 3.4), "alt": 0.0, "monte": 0.8, "bat": 16.0})


func _vue() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	return inv * get_viewport_rect()


func _case_au_hasard(vue: Rect2, ok: Callable, essais: int) -> Vector2i:
	var g = m.game
	for i in essais:
		var x := int(_rng.randf_range(vue.position.x, vue.end.x) / T)
		var y := int(_rng.randf_range(vue.position.y, vue.end.y) / T)
		if g.map.in_bounds(x, y) and ok.call(x, y):
			return Vector2i(x, y)
	return Vector2i(-1, -1)


func _eau_profonde(x: int, y: int) -> bool:
	var mp: GameMap = m.game.map
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if not mp.in_bounds(x + d.x, y + d.y) or mp.get_t(x + d.x, y + d.y) != GameMap.EAU:
			return false
	return true


func _draw() -> void:
	var zoom: float = m.camera.zoom.x if m.camera else 1.0
	var tr := 1.4 / zoom   # épaisseur du trait : constante à l'écran
	# ronds dans l'eau
	for r in ronds:
		var t: float = r["t"]
		var p: Vector2 = r["p"]
		if r["saut"] and t < 0.5:
			var k := t / 0.5
			var q := p + Vector2(lerpf(-4.0, 4.0, k), -sin(k * PI) * 7.0)
			draw_arc(q, 1.8, PI * (0.1 + k * 0.6), PI * (1.0 + k * 0.6), 6, Color("F08A3A"), 1.8, true)
		for j in 2:
			var tt := t - j * 0.35
			if tt <= 0.0:
				continue
			var rad := 1.5 + tt * 7.0
			var a := clampf(1.0 - tt / 1.4, 0.0, 1.0) * 0.8
			draw_set_transform(p, 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, rad, 0.0, TAU, 24, Color(1, 1, 1, a), tr * 1.2, true)
			draw_set_transform(Vector2.ZERO)
	# ombres puis oiseaux
	for o in oiseaux:
		var off: Vector2 = Vector2(16.0, 30.0) * float(o["alt"])
		if o["alt"] > 0.05:
			_oiseau(o["p"] + off, o, Color(ENCRE, 0.16 * o["alt"]), tr * 1.6)
	for o in oiseaux:
		_oiseau(o["p"], o, ENCRE, tr)
	if zoom < 2.2:
		return
	for b in papillons:
		var p: Vector2 = b["p"]
		var ouv := 0.35 + 0.65 * absf(sin(b["ph"]))
		for cote in [-1.0, 1.0]:
			var c := p + Vector2(cote * 1.7 * ouv, -0.4)
			draw_set_transform(c, 0.0, Vector2(ouv, 1.0))
			draw_circle(Vector2.ZERO, 1.8, b["col"])
			draw_arc(Vector2.ZERO, 1.8, 0.0, TAU, 10, ENCRE, tr * 0.8, true)
			draw_set_transform(Vector2.ZERO)
		draw_line(p + Vector2(0, -1.3), p + Vector2(0, 1.1), ENCRE, tr * 1.3)
	for l in libellules:
		var p: Vector2 = l["p"]
		var ail := Color(0.85, 0.95, 1.0, 0.75)
		var bat := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.06)
		for cote in [-1.0, 1.0]:
			draw_line(p + Vector2(0, -0.6), p + Vector2(cote * 2.6, -1.2 - bat * 0.4), ail, tr * 1.6)
			draw_line(p + Vector2(0, -0.1), p + Vector2(cote * 2.3, 0.2 + bat * 0.4), ail, tr * 1.6)
		draw_line(p + Vector2(0, -1.4), p + Vector2(0, 2.6), Color("1E7A8C"), tr * 1.7)
		draw_circle(p + Vector2(0, -1.5), 0.55, ENCRE)


func _oiseau(p: Vector2, o: Dictionary, col: Color, larg: float) -> void:
	var s: float = o["s"]
	var f := sin(o["ph"]) * s * 0.55
	var sens := signf(o["v"].x) if o["v"].x != 0.0 else 1.0
	var pts := PackedVector2Array([p + Vector2(-s, -f - s * 0.15), p + Vector2(-s * 0.45, -s * 0.12), p, p + Vector2(s * 0.45, -s * 0.12), p + Vector2(s, -f - s * 0.15)])
	draw_polyline(pts, col, larg, true)
	draw_line(p, p + Vector2(sens * s * 0.25, s * 0.05), col, larg, true)


# ------------------------------------------------------------------ textures

func _texture_disque(taille: int, cerne: bool) -> Texture2D:
	var img := Image.create_empty(taille, taille, false, Image.FORMAT_RGBA8)
	var c := Vector2(taille, taille) * 0.5
	var r := taille * 0.5 - 1.0
	for y in taille:
		for x in taille:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var a := clampf(r - d + 0.5, 0.0, 1.0)
			var col := Color(1, 1, 1, a)
			if cerne and d > r - 2.6:
				col = Color(ENCRE.r, ENCRE.g, ENCRE.b, a * 0.3)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _texture_lueur() -> Texture2D:
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	g.width = 64
	g.height = 64
	var gr := Gradient.new()
	gr.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	g.gradient = gr
	return g


func _courbe(debut: float, fin: float) -> Curve:
	var c := Curve.new()
	c.max_value = maxf(debut, fin)
	c.add_point(Vector2(0, debut))
	c.add_point(Vector2(1, fin))
	return c
