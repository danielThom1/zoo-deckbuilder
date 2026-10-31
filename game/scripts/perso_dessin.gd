class_name PersoDessin
extends RefCounted
## Silhouette d'un personnage dans le monde (≈ 1 case de haut), aux couleurs de son portrait de carte :
## peau, cheveux et coiffure, couvre-chef, vêtement. Trois vues comme dans RimWorld : face, profil (vers la
## droite, `miroir` pour la gauche) et dos. Données : data/personnages.json (généré par tools/personnages.py).

const ENCRE := Color("2B2118")
const TRAIT := 0.7
const PANTALON := Color("3A3F48")


static func dessiner(ci: CanvasItem, p: Vector2, perso: Dictionary, vue: String, t: float, marche: bool, miroir := false) -> void:
	var sx := -1.0 if miroir else 1.0
	var pas := sin(t * 11.0) if marche else 0.0
	var bob := absf(pas) * -0.6
	var peau := Color(perso.get("peau", "#EBC09C"))
	var cheveux := Color(perso.get("cheveux", "#5A3A24"))
	var coul := Color(perso.get("couleur", "#3A6EC8"))
	var coul2 := Color(perso.get("couleur2", "#2C3E66"))
	var vet: String = perso.get("vetement", "tshirt")
	var coif: String = perso.get("coiffure", "court")
	var chap: String = perso.get("chapeau", "")
	var chap_col := Color(perso["couleur_chapeau"]) if str(perso.get("couleur_chapeau", "")) != "" else coul
	var o := p + Vector2(0, bob)
	var tete := o + Vector2(0, -4.4)

	# Ombre et pieds
	ci.draw_colored_polygon(_ell(p + Vector2(0, 6.4), 4.6, 1.7), Color(0, 0, 0, 0.28))
	var bas := coul2 if vet == "salopette" else PANTALON
	if vue == "profil":
		_forme(ci, _ell(p + Vector2(sx * pas * 1.6, 5.4), 1.7, 1.2), bas)
		_forme(ci, _ell(p + Vector2(-sx * pas * 1.6, 5.4), 1.7, 1.2), bas.darkened(0.2))
	else:
		_forme(ci, _ell(p + Vector2(-1.8, 5.4 + pas * 0.7), 1.5, 1.3), bas)
		_forme(ci, _ell(p + Vector2(1.8, 5.4 - pas * 0.7), 1.5, 1.3), bas)

	# Cheveux et couvre-chefs de derrière (avant le corps et la tête)
	if chap == "voile":
		_forme(ci, _ell(tete + Vector2(0, 1.2), 5.6, 6.4), chap_col)
	elif coif == "afro":
		_forme(ci, _ell(tete + Vector2(0, -0.8), 6.3, 5.8), cheveux)
	elif coif == "long" and vue != "dos":
		_forme(ci, _rect_arrondi(tete + Vector2(-4.9, -1.0), Vector2(9.8, 7.0)), cheveux)
	elif coif == "chignon" and vue != "dos":
		_forme(ci, _ell(tete + Vector2(-sx * 1.5 if vue == "profil" else 0.0, -4.4), 2.2, 2.0), cheveux)
	elif coif == "queue" and vue == "face":
		_forme(ci, _ell(tete + Vector2(4.6, 1.4), 1.4, 2.8), cheveux)

	var bras_y := 1.4 + bob
	# Corps
	var torse := _ell(o + Vector2(0, 1.6), 3.9 if vue == "profil" else 5.0, 4.3)
	_forme(ci, torse, coul)
	_vetement(ci, o, vue, vet, coul, coul2, sx)
	if vue != "profil":
		for s in [-1.0, 1.0]:
			var sw: float = pas * s * 0.9
			_forme(ci, _ell(o + Vector2(s * 5.0, bras_y + sw), 1.5, 2.4), coul.darkened(0.08))
			_forme(ci, _ell(o + Vector2(s * 5.1, bras_y + 2.6 + sw), 1.0, 1.0), peau, 0.5)
	else:
		# de profil, un seul bras devant le corps, qui balance avec la marche
		var bx := sx * pas * 1.6
		_forme(ci, _ell(o + Vector2(bx, bras_y + 0.4), 1.4, 2.5), coul.darkened(0.08))
		_forme(ci, _ell(o + Vector2(bx + sx * 0.3, bras_y + 2.9), 0.95, 0.95), peau, 0.5)

	# Tête
	var r := 4.4
	if chap == "voile" and vue != "dos":
		_forme(ci, _ell(tete + Vector2(sx * 0.8 if vue == "profil" else 0.0, 0.6), 3.4, 3.8), peau)
	elif chap != "voile":
		_forme(ci, _ell(tete, r, r), peau)
		if vue == "profil":
			_forme(ci, _ell(tete + Vector2(sx * 4.3, 0.6), 0.9, 0.8), peau, 0.5)
	# Visage
	if vue == "face":
		for s in [-1.0, 1.0]:
			ci.draw_circle(tete + Vector2(s * 1.5, 0.3), 0.55, ENCRE)
		if perso.get("lunettes", false):
			for s in [-1.0, 1.0]:
				ci.draw_arc(tete + Vector2(s * 1.5, 0.3), 1.1, 0, TAU, 10, ENCRE, 0.35, true)
		ci.draw_circle(tete + Vector2(-2.6, 1.6), 0.8, Color(0.91, 0.5, 0.48, 0.35))
		ci.draw_circle(tete + Vector2(2.6, 1.6), 0.8, Color(0.91, 0.5, 0.48, 0.35))
	elif vue == "profil":
		ci.draw_circle(tete + Vector2(sx * 2.4, 0.2), 0.55, ENCRE)
		if perso.get("lunettes", false):
			ci.draw_arc(tete + Vector2(sx * 2.4, 0.2), 1.1, 0, TAU, 10, ENCRE, 0.35, true)
	_pilosite(ci, tete, vue, str(perso.get("pilosite", "")), cheveux, sx)

	# Cheveux du dessus
	if chap != "voile":
		_cheveux(ci, tete, vue, coif, cheveux, sx, chap != "")
	_chapeau(ci, tete, vue, chap, chap_col, sx)


static func _vetement(ci: CanvasItem, o: Vector2, vue: String, vet: String, coul: Color, coul2: Color, sx: float) -> void:
	match vet:
		"salopette":
			if vue == "face":
				_forme(ci, _rect_arrondi(o + Vector2(-2.6, 0.6), Vector2(5.2, 4.8)), coul2, 0.5)
			elif vue == "dos":
				ci.draw_line(o + Vector2(-3, -1.8), o + Vector2(3, 3.6), coul2, 1.0)
				ci.draw_line(o + Vector2(3, -1.8), o + Vector2(-3, 3.6), coul2, 1.0)
			else:
				_forme(ci, _rect_arrondi(o + Vector2(-1.5, 0.8), Vector2(3.6, 4.4)), coul2, 0.5)
		"tablier":
			if vue != "dos":
				_forme(ci, _rect_arrondi(o + Vector2(-2.8 if vue == "face" else sx * 0.5 - 1.6, -0.2), Vector2(5.6 if vue == "face" else 3.2, 5.6)), coul2, 0.5)
			else:
				ci.draw_line(o + Vector2(-4, 2.4), o + Vector2(4, 2.4), coul2, 0.9)
		"securite":
			var gilet := Color("E8782A")
			if vue == "face":
				_forme(ci, _ell(o + Vector2(-2.9, 1.8), 1.9, 3.8), gilet, 0.4)
				_forme(ci, _ell(o + Vector2(2.9, 1.8), 1.9, 3.8), gilet, 0.4)
			else:
				_forme(ci, _ell(o + Vector2(0, 1.6), 3.9 if vue == "profil" else 4.6, 4.0), gilet, 0.4)
			ci.draw_line(o + Vector2(-4.2, 2.8), o + Vector2(4.2, 2.8), Color("D8DCDC"), 0.8)
		"costume":
			if vue == "face":
				ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-1.8, -2.4), o + Vector2(1.8, -2.4), o + Vector2(0, 2.4)]), Color("F4F1EA"))
				ci.draw_line(o + Vector2(0, -2.0), o + Vector2(0, 2.0), coul2, 0.9)
		"sweat":
			if vue == "dos":
				_forme(ci, _ell(o + Vector2(0, -1.6), 3.0, 1.8), coul.darkened(0.15), 0.5)
			elif vue == "face":
				ci.draw_line(o + Vector2(-0.9, -1.8), o + Vector2(-1.0, 0.6), Color(1, 1, 1, 0.8), 0.4)
				ci.draw_line(o + Vector2(0.9, -1.8), o + Vector2(1.0, 0.6), Color(1, 1, 1, 0.8), 0.4)
		"chemise", "polo":
			if vue == "face":
				ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-2.0, -2.6), o + Vector2(0, -1.0), o + Vector2(2.0, -2.6), o + Vector2(0, 0.6)]), coul.lightened(0.3))


static func _pilosite(ci: CanvasItem, tete: Vector2, vue: String, pil: String, cheveux: Color, sx: float) -> void:
	if vue == "dos" or pil == "":
		return
	var c := tete + (Vector2(sx * 1.2, 0) if vue == "profil" else Vector2.ZERO)
	match pil:
		"barbe":
			# croissant sous la bouche, des oreilles au menton
			var pts := PackedVector2Array()
			var lx := 0.8 if vue == "profil" else 1.0
			for i in 9:
				var a := deg_to_rad(10 + i * 20)
				pts.append(c + Vector2(cos(a) * 4.2 * lx, sin(a) * 4.5))
			for i in 9:
				var a := deg_to_rad(170 - i * 20)
				pts.append(c + Vector2(cos(a) * 2.7 * lx, 1.3 + sin(a) * 1.5))
			_forme(ci, pts, cheveux, 0.5)
		"moustache", "bouc":
			_forme(ci, _ell(c + Vector2(0, 2.0), 1.6, 0.6), cheveux, 0.4)
		"barbe3j":
			ci.draw_arc(c, 3.2, deg_to_rad(30), deg_to_rad(150), 10, Color(cheveux, 0.55), 1.0)


static func _cheveux(ci: CanvasItem, tete: Vector2, vue: String, coif: String, cheveux: Color, sx: float, sous_chapeau: bool) -> void:
	if coif == "chauve":
		if not sous_chapeau:
			ci.draw_circle(tete + Vector2(-1.2, -2.4), 1.0, Color(1, 1, 1, 0.35))
		return
	if coif == "couronne":
		for s in [-1.0, 1.0]:
			if vue == "face" or vue == "dos" or s == -sx:
				_forme(ci, _ell(tete + Vector2(s * 3.9, -0.6), 1.2, 1.8), cheveux, 0.4)
		return
	var a0 := 180.0
	var a1 := 360.0
	var front := -1.4  # ligne du front (y relatif à la tête)
	if vue == "dos":
		a0 = 0.0
		a1 = 360.0
	elif vue == "profil":
		if sx > 0:
			a0 = 110.0
			a1 = 335.0
		else:
			a0 = 205.0
			a1 = 430.0
	var rr := 4.7 if coif != "rase" else 4.5
	var pts := PackedVector2Array()
	var n := 14 if vue != "dos" else 18
	for i in n + 1:
		var a := deg_to_rad(a0 + (a1 - a0) * i / n)
		var k := rr
		if coif == "herisse" and i % 2 == 1:
			k += 1.2
		elif coif == "boucles" and i % 2 == 1:
			k += 0.7
		pts.append(tete + Vector2(cos(a), sin(a)) * k)
	if vue == "face":
		pts.append(tete + Vector2(3.6, front))
		pts.append(tete + Vector2(0, front - 0.8 if coif != "frange" else front + 0.4))
		pts.append(tete + Vector2(-3.6, front))
	elif vue == "profil":
		pts.append(tete + Vector2(sx * 1.2, front - 0.6))
	var col := cheveux if coif != "rase" else Color(cheveux, 0.7)
	_forme(ci, pts, col, 0.6)
	# Mèches qui tombent : cheveux longs, carré, tresses, queue (de dos)
	match coif:
		"long":
			if vue == "dos":
				_forme(ci, _rect_arrondi(tete + Vector2(-4.7, -0.5), Vector2(9.4, 6.6)), cheveux, 0.6)
			elif vue == "face":
				for s in [-1.0, 1.0]:
					_forme(ci, _rect_arrondi(tete + Vector2(s * 4.2 - 1.1, -1.0), Vector2(2.2, 6.4)), cheveux, 0.5)
		"carre":
			if vue == "dos":
				_forme(ci, _rect_arrondi(tete + Vector2(-4.8, -0.5), Vector2(9.6, 3.6)), cheveux, 0.6)
			elif vue == "face":
				for s in [-1.0, 1.0]:
					_forme(ci, _rect_arrondi(tete + Vector2(s * 4.3 - 1.0, -1.0), Vector2(2.0, 3.6)), cheveux, 0.5)
		"tresses":
			for s in [-1.0, 1.0]:
				if vue != "profil" or s == -sx:
					for j in 3:
						_forme(ci, _ell(tete + Vector2(s * 4.4, 1.2 + j * 1.7), 0.9, 1.0), cheveux, 0.4)
		"queue":
			if vue == "dos":
				_forme(ci, _ell(tete + Vector2(0, 3.4), 1.2, 2.6), cheveux, 0.5)
			elif vue == "profil":
				_forme(ci, _ell(tete + Vector2(-sx * 5.0, 1.2), 1.2, 2.6), cheveux, 0.5)
		"chignon":
			if vue == "dos":
				_forme(ci, _ell(tete + Vector2(0, -1.6), 2.0, 1.8), cheveux.darkened(0.1), 0.5)


static func _chapeau(ci: CanvasItem, tete: Vector2, vue: String, chap: String, col: Color, sx: float) -> void:
	match chap:
		"casquette", "foulard", "bonnet", "casque":
			var rr: float = {"casquette": 4.9, "foulard": 4.8, "bonnet": 5.0, "casque": 5.3}[chap]
			var base_y: float = {"casquette": -1.6, "foulard": -1.2, "bonnet": -0.8, "casque": -1.4}[chap]
			var pts := PackedVector2Array()
			for i in 13:
				var a := deg_to_rad(180.0 + 180.0 * i / 12)
				pts.append(tete + Vector2(cos(a) * rr, minf(sin(a) * rr, base_y)))
			_forme(ci, pts, col, 0.6)
			match chap:
				"casquette":
					if vue == "face":
						_forme(ci, _ell(tete + Vector2(0, base_y + 0.2), 3.6, 1.1), col.darkened(0.2), 0.5)
					elif vue == "profil":
						_forme(ci, _ell(tete + Vector2(sx * 5.2, base_y + 0.2), 2.6, 0.9), col.darkened(0.2), 0.5)
				"bonnet":
					_forme(ci, _rect_arrondi(tete + Vector2(-5.0, base_y - 1.4), Vector2(10.0, 1.8)), col.darkened(0.18), 0.5)
					_forme(ci, _ell(tete + Vector2(0, -5.6), 1.4, 1.4), col.lightened(0.45), 0.4)
				"casque":
					_forme(ci, _ell(tete + Vector2(0, base_y + 0.2), 6.4, 1.4), col.darkened(0.12), 0.5)
					ci.draw_line(tete + Vector2(0, -5.2), tete + Vector2(0, base_y - 0.4), col.lightened(0.4), 0.8)
				"foulard":
					if vue != "face":
						_forme(ci, _ell(tete + Vector2(-sx * 4.8 if vue == "profil" else 0.0, base_y + 0.6), 1.3, 1.0), col.darkened(0.15), 0.4)
		"paille":
			_forme(ci, _ell(tete + Vector2(0, -1.6), 7.4, 2.8), col, 0.6)
			_forme(ci, _ell(tete + Vector2(0, -3.0), 3.6, 2.6), col.darkened(0.06), 0.5)
			ci.draw_line(tete + Vector2(-3.5, -2.0), tete + Vector2(3.5, -2.0), Color("D04A3A"), 0.9)
		"bandeau":
			if vue == "dos":
				ci.draw_arc(tete, 4.5, deg_to_rad(-170), deg_to_rad(-10), 12, col, 1.2)
			else:
				ci.draw_line(tete + Vector2(-4.3, -2.2), tete + Vector2(4.3, -2.2), col, 1.3)
		"voile":
			if vue != "dos":
				var pts := PackedVector2Array()
				for i in 13:
					var a := deg_to_rad(180.0 + 180.0 * i / 12)
					pts.append(tete + Vector2(cos(a) * 5.6, sin(a) * 5.4 + 0.6))
				pts.append(tete + Vector2(3.2, -1.6))
				pts.append(tete + Vector2(-3.2, -1.6))
				_forme(ci, pts, col, 0.6)


# --- Primitives -------------------------------------------------------------------

static func _forme(ci: CanvasItem, pts: PackedVector2Array, col: Color, w := TRAIT) -> void:
	ci.draw_colored_polygon(pts, col)
	var ferme := pts.duplicate()
	ferme.append(pts[0])
	ci.draw_polyline(ferme, ENCRE, w, true)


static func _ell(c: Vector2, rx: float, ry: float, n := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _rect_arrondi(pos: Vector2, taille: Vector2) -> PackedVector2Array:
	var r := minf(1.2, minf(taille.x, taille.y) * 0.4)
	var pts := PackedVector2Array()
	var coins := [[pos + Vector2(taille.x - r, r), -90.0], [pos + Vector2(taille.x - r, taille.y - r), 0.0],
		[pos + Vector2(r, taille.y - r), 90.0], [pos + Vector2(r, r), 180.0]]
	for c in coins:
		for i in 4:
			var a := deg_to_rad(c[1] + 30.0 * i)
			pts.append(c[0] + Vector2(cos(a), sin(a)) * r)
	return pts
