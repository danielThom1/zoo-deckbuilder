class_name SpritesBD
extends RefCounted
## Accès aux sprites dessinés (bâtiments, personnes, animaux, portraits) et tables de correspondance
## avec les identifiants du jeu. Toutes les fonctions de dessin s'appellent depuis un _draw().
##
##   SpritesBD.dessiner(self, "maison", pied, 1.6 * TILE)          # hauteur imposée
##   SpritesBD.dessiner_largeur(self, "entrepot", pied, 2.2 * TILE) # largeur imposée
##   SpritesBD.texture("portrait_07")                               # pour l'interface (TextureRect)

const MANIFESTE := "res://assets/bd/sprites_bd.json"

## Bâtiment terminé → sprite. Largeur dessinée = largeur de l'emprise × LARGEUR_BATIMENT.
const BATIMENTS := {
	"camp": "camp3", "maison": "maison", "entrepot": "entrepot", "mine": "mine", "entree": "entree",
	"boutique": "souvenirs", "comptoir": "marche", "agence": "agence", "cabinet": "cabinet", "acquisitions": "interim",
	"cuisine": "cuisine", "entretien": "atelier", "intendance": "intendance", "snack": "snack", "kiosque": "scene", "mairie": "mairie",
	# aménagements d'enclos
	"grand_arbre": "arbre1", "rocher_obs": "rocher_obs", "bassin_profond": "bassin", "abri_chaud": "abri",
}
## Camp selon son niveau (1 à 3).
const CAMPS := ["camp1", "camp2", "camp3"]
const CHANTIERS := ["chantier1", "chantier2"]
const LARGEUR_BATIMENT := 1.15

## Métier → personnage (hauteur conseillée : 1,15 case).
const METIERS := {
	"manoeuvre": "manoeuvre", "bucheron": "bucheron", "macon": "macon", "mineur": "mineur", "terrassier": "terrassier",
	"porteur": "porteur", "guichetier": "guichetier", "apprenti": "ouvrier_marche_04", "charpentier": "charpentier",
	"paysagiste": "paysagiste", "cantonnier": "cantonnier", "soigneur": "soigneur", "drh": "cadre_valise", "lobbyiste": "lobbyiste",
	"marchand": "marchand", "vendeur": "vendeur", "formateur": "formateur", "contremaitre": "contremaitre", "architecte": "architecte",
	"animalier": "soigneur_2", "agent_entretien": "ouvrier_seau", "animateur": "guide_fanion", "intendant": "guide",
}
## Métier → personnage féminin, pour les ouvrières.
const METIERS_F := {
	"manoeuvre": "ouvrier_marche_14", "bucheron": "ouvrier_marche_17", "macon": "ouvrier_marche_16", "mineur": "ouvrier_marche_05",
	"terrassier": "ouvrier_marche_16", "porteur": "ouvrier_marche_17", "guichetier": "visiteur_08", "apprenti": "apprenti",
	"charpentier": "ouvrier_marche_14", "paysagiste": "visiteur_16", "cantonnier": "ouvrier_marche_05", "soigneur": "infirmiere",
	"drh": "drh", "lobbyiste": "drh_2", "marchand": "visiteur_06", "vendeur": "visiteur_07", "formateur": "formatrice",
	"contremaitre": "guide", "architecte": "chimiste", "animalier": "visiteur_05", "agent_entretien": "ouvrier_marche_05",
	"animateur": "guide",
}
const HAUTEUR_PERSONNE := 1.15

const VISITEURS := ["visiteuse_sac", "visiteur_sweat", "visiteur_canne", "randonneur", "enfant_garcon", "enfant_fille",
	"visiteur_01", "visiteur_02", "visiteur_03", "visiteur_04", "visiteur_05", "visiteur_06", "visiteur_07", "visiteur_08",
	"visiteur_09", "visiteur_10", "visiteur_11", "visiteur_12", "visiteur_13", "visiteur_14", "visiteur_15", "visiteur_16"]

## Espèce (animals.json) → [sprite du corps, hauteur en cases, portrait pour les cartes ou "", images d'animation].
const ANIMAUX := {
	"aigle_royal": ["aigle_royal", 0.9, "aigle_royal_tete", 4],
	"bison_europe": ["bison_europe", 1.2, "bison_europe_tete", 4],
	"lynx": ["lynx", 0.7, "lynx_tete", 4],
	"loutre_europe": ["loutre_europe", 0.45, "loutre_europe_tete", 4],
	"loup": ["loup", 0.8, "loup_tete", 4],
	"phoque": ["phoque", 0.5, "phoque_tete", 4],
	"cerf": ["cerf", 1.2, "cerf_tete", 4],
	"pygargue": ["pygargue", 0.9, "pygargue_tete", 4],
	"puma": ["puma", 0.75, "puma_tete", 4],
	"capybara": ["capybara", 0.6, "capybara_tete", 4],
	"alligator": ["alligator", 0.4, "alligator_tete", 4],
	"jaguar": ["jaguar", 0.7, "jaguar_tete", 4],
	"ocelot": ["ocelot", 0.6, "ocelot_tete", 4],
	"ara": ["ara", 0.7, "ara_tete", 4],
	"bison_amerique": ["bison_amerique", 1.2, "bison_amerique_tete", 4],
	"tapir": ["tapir", 0.8, "tapir_tete", 4],
	"tigre": ["tigre", 0.85, "tigre_tete", 4],
	"panda": ["panda", 1.0, "panda_tete", 4],
	"leopard_neiges": ["leopard_neiges", 0.7, "leopard_neiges_tete", 4],
	"loutre_cendree": ["loutre_cendree", 0.45, "loutre_cendree_tete", 4],
	"paon": ["paon", 0.9, "paon_tete", 4],
	"koi": ["koi", 0.35, "koi_tete", 4],
	"salamandre": ["salamandre", 0.3, "salamandre_tete", 4],
	"calao": ["calao", 0.7, "calao_tete", 4],
	"grue_japon": ["grue_japon", 1.1, "grue_japon_tete", 4],
	"yak": ["yak", 1.1, "yak_tete", 4],
	"lion": ["lion", 0.9, "lion_tete", 4],
	"hippopotame": ["hippopotame", 1.1, "hippopotame_tete", 4],
	"guepard": ["guepard", 0.75, "guepard_tete", 4],
	"girafe": ["girafe", 2.2, "girafe_tete", 4],
	"manchot": ["manchot", 0.7, "manchot_tete", 4],
	"loutre_joues_blanches": ["loutre_joues_blanches", 0.5, "loutre_joues_blanches_tete", 4],
	"hyene": ["hyene", 0.75, "hyene_tete", 4],
	"zebre": ["zebre", 1.0, "zebre_tete", 4],
	"grue_couronnee": ["grue_couronnee", 1.1, "grue_couronnee_tete", 4],
	"messager": ["messager", 0.7, "messager_tete", 4],
	"mesange": ["mesange", 0.4, "mesange_tete", 4], "faucon": ["faucon", 0.8, "faucon_tete", 4],
	"dauphin_rose": ["dauphin_rose", 0.6, "dauphin_rose_tete", 4], "bouquetin": ["bouquetin", 1.1, "bouquetin_tete", 4],
}

static var _manif := {}
static var _tex := {}


static func _charger() -> void:
	if _manif.is_empty():
		_manif = JSON.parse_string(FileAccess.get_file_as_string(MANIFESTE))


static func existe(nom: String) -> bool:
	_charger()
	return _manif.has(nom)


static func texture(nom: String) -> Texture2D:
	_charger()
	if not _tex.has(nom):
		_tex[nom] = load(_manif[nom]["fichier"]) if _manif.has(nom) else null
	return _tex[nom]


static func pied(nom: String) -> Vector2:
	_charger()
	var p: Array = _manif[nom]["pied"]
	return Vector2(p[0], p[1])


## Dessine le sprite « nom » posé sur le point « pied_monde », à la hauteur donnée (unités monde).
static func dessiner(ci: CanvasItem, nom: String, pied_monde: Vector2, hauteur: float, miroir := false, teinte := Color.WHITE) -> void:
	var t := texture(nom)
	if t == null:
		return
	var k := hauteur / t.get_height()
	_dessiner_k(ci, t, nom, pied_monde, k, miroir, teinte)


static func dessiner_largeur(ci: CanvasItem, nom: String, pied_monde: Vector2, largeur: float, miroir := false, teinte := Color.WHITE) -> void:
	var t := texture(nom)
	if t == null:
		return
	_dessiner_k(ci, t, nom, pied_monde, largeur / t.get_width(), miroir, teinte)


## Vue isométrique (Vue25D) : les objets debout sont notés ici au lieu d'être dessinés sur le sol.
static var collecte = null
static var collecte_objet: Variant = null


static func _noter(t: Texture2D, pd: Vector2, pos: Vector2, k: float, miroir: bool, teinte: Color, region := Rect2()) -> void:
	collecte.append({"tex": t, "pied": pd, "pos": pos, "k": k, "miroir": miroir, "teinte": teinte, "region": region, "objet": collecte_objet})


## Image posée sur le sol par son bord bas, sans ombre (camp, décorations).
static func image_debout(ci: CanvasItem, t: Texture2D, r: Rect2) -> void:
	if collecte != null:
		_noter(t, Vector2(t.get_width() / 2.0, t.get_height()), Vector2(r.get_center().x, r.end.y), r.size.x / t.get_width(), false, Color.WHITE)
		return
	ci.draw_texture_rect(t, r, false)


static func _dessiner_k(ci: CanvasItem, t: Texture2D, nom: String, pied_monde: Vector2, k: float, miroir: bool, teinte: Color) -> void:
	var pd := pied(nom)
	if collecte != null:
		_noter(t, pd, pied_monde, k, miroir, teinte)
		return
	var taille := Vector2(t.get_width(), t.get_height()) * k
	# ombre portée au sol
	ci.draw_set_transform(pied_monde + Vector2(taille.x * 0.08, 0), 0.0, Vector2(1.0, 0.28))
	ci.draw_circle(Vector2.ZERO, taille.x * 0.42, Color(0.078, 0.125, 0.169, 0.2))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if miroir:
		ci.draw_set_transform(pied_monde, 0.0, Vector2(-1, 1))
		ci.draw_texture_rect(t, Rect2(-pd * k, taille), false, teinte)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		ci.draw_texture_rect(t, Rect2(pied_monde - pd * k, taille), false, teinte)


## Feuille d'animation d'un personnage (planches : personnages_planches.py) : 3 images par rangée.
const PERSO_CELLULE := Vector2(220, 150)
const PERSO_PIED := Vector2(90, 144)
const PERSO_CORPS := 96.0
const PERSO_MARCHE := 0
const PERSO_CONSTRUIRE := 1
const PERSO_COUPER := 2
const PERSO_MINER := 3
const PERSO_SERVIR := 4  # les 4 dernières rangées n'existent que sur les planches à 8 gestes
const PERSO_NOURRIR := 5
const PERSO_BALAYER := 6
const PERSO_SOIGNER := 7
static var _feuilles := {}


static func feuille_perso(id: String) -> Texture2D:
	if not _feuilles.has(id):
		var chemin := "res://assets/bd/sprites/personnages_v2/%s.png" % id
		_feuilles[id] = load(chemin) if ResourceLoader.exists(chemin) else null
	return _feuilles[id]


static func perso_a_rangee(tex: Texture2D, rangee: int) -> bool:
	return (rangee + 1) * PERSO_CELLULE.y <= tex.get_height()


static var _tetes := {}


## Les images de marche sont calées sur le pied arrière : d'une image à l'autre, le corps sauterait d'avant en arrière.
## On les recale sur le milieu de la tête, qui reste à la même place pendant la marche.
static func _centre_tete(tex: Texture2D, image: int) -> float:
	var cle := "%d_%d" % [tex.get_rid().get_id(), image]
	if _tetes.has(cle):
		return _tetes[cle]
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var x0 := int(image * PERSO_CELLULE.x)
	var haut := -1
	var somme := 0.0
	var n := 0
	for y in int(PERSO_CELLULE.y):
		for x in int(PERSO_CELLULE.x):
			if img.get_pixel(x0 + x, y).a > 0.5:
				if haut < 0:
					haut = y
				somme += x
				n += 1
		if haut >= 0 and y >= haut + 22:
			break
	_tetes[cle] = somme / n if n > 0 else PERSO_PIED.x
	return _tetes[cle]


## Dessine une image de la feuille, les pieds sur « pied_monde » ; « hauteur » est celle du corps debout.
static func dessiner_perso(ci: CanvasItem, tex: Texture2D, rangee: int, image: int, pied_monde: Vector2, hauteur: float, miroir := false) -> void:
	var k := hauteur / PERSO_CORPS
	var source := Rect2(Vector2(image % 3, rangee) * PERSO_CELLULE, PERSO_CELLULE)
	var pied_image := PERSO_PIED
	if rangee == PERSO_MARCHE:
		pied_image.x = _centre_tete(tex, image % 3)
	if collecte != null:
		_noter(tex, pied_image, pied_monde, k, miroir, Color.WHITE, source)
		return
	ci.draw_set_transform(pied_monde, 0.0, Vector2(1.0, 0.28))
	ci.draw_circle(Vector2.ZERO, hauteur * 0.26, Color(0.078, 0.125, 0.169, 0.2))
	if miroir:
		ci.draw_set_transform(pied_monde, 0.0, Vector2(-1, 1))
	else:
		ci.draw_set_transform(pied_monde, 0.0, Vector2.ONE)
	ci.draw_texture_rect_region(tex, Rect2(-pied_image * k, PERSO_CELLULE * k), source)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Sprite d'un ouvrier selon son métier (repli : manœuvre).
## Image d'animation d'une espèce : « id », « id_f2 », « id_f3 »… (les planches n'ont pas toutes le même nombre d'images).
static func image_animal(esp: Array, k: int) -> String:
	var n := mini(int(esp[3]) if esp.size() > 3 else 1, 3)  # les dernières images sont souvent couché ou en plein saut
	var f := k % maxi(1, n)
	var nom: String = esp[0] if f == 0 else "%s_f%d" % [esp[0], f + 1]
	return nom if existe(nom) else esp[0]


static func pour_metier(id_metier: String, feminin := false) -> String:
	if feminin:
		return METIERS_F.get(id_metier, "ouvrier_marche_14")
	return METIERS.get(id_metier, "manoeuvre")


## Visiteur stable pour un indice donné.
static func visiteur(i: int) -> String:
	return VISITEURS[absi(i) % VISITEURS.size()]


## Portrait stable pour un personnage identifié par une chaîne (perso du jeu).
## Portrait de chaque personnage (data/personnages.json), choisi pour son genre et son âge ; un portrait par personnage.
const PORTRAIT_DE := {"lea": 36, "jade": 4, "emma": 31, "ines": 21, "chloe": 25, "manon": 41, "sarah": 14, "yasmine": 17, "aicha": 8, "margaux": 10, "lucie": 30, "clara": 1, "nadia": 23, "odette": 26, "fatou": 39, "elise": 40, "rose": 5, "camille": 34, "zoe": 19, "lina": 12, "hugo": 2, "louis": 6, "nathan": 7, "gabin": 13, "tom": 37, "jules": 27, "paul": 24, "malik": 20, "theo": 32, "kenji": 16, "mamadou": 3, "bastien": 18, "marcel": 29, "samir": 42, "igor": 9, "adam": 38, "victor": 11, "noah": 43, "basile": 35, "omar": 22}


static func portrait_de(cle: String) -> String:
	if existe("pv2_" + cle):
		return "pv2_" + cle
	return "portrait_%02d" % int(PORTRAIT_DE[cle]) if PORTRAIT_DE.has(cle) else portrait(hash(cle))


## Portrait stable pour un ouvrier (42 portraits disponibles : portrait_01 … portrait_42).
static func portrait(cle: int) -> String:
	return "portrait_%02d" % (absi(cle) % 42 + 1)


## Clôture en perspective sur une case : poteau au centre et lisses vers les voisins reliés.
## dirs : directions (Vector2i) des voisins du même type. type_ : "bois" (enclos) ou "pierre" (enceinte).
static func cloture(ci: CanvasItem, centre: Vector2, dirs: Array, type_: String, tile: float) -> void:
	var encre := Color("14202B")
	if type_ == "pierre":
		var h := tile * 0.62
		var ep := tile * 0.32
		# murs horizontaux : face avant + dessus ; verticaux : flanc + dessus
		for d in dirs:
			var dv := Vector2(d)
			var b := centre + dv * tile * 0.5
			if d.y == 0:
				var a := centre
				var face := PackedVector2Array([a, b, b - Vector2(0, h), a - Vector2(0, h)])
				ci.draw_colored_polygon(face, Color("D8D2C2"))
				# assises de pierre : ligne médiane et joints décalés
				ci.draw_line(a - Vector2(0, h * 0.5), b - Vector2(0, h * 0.5), Color(encre, 0.45), 1.0)
				var sx := signf(b.x - a.x) * tile * 0.5
				ci.draw_line(a + Vector2(sx * 0.5, -h * 0.5), a + Vector2(sx * 0.5, -h), Color(encre, 0.4), 1.0)
				ci.draw_line(a + Vector2(sx * 0.15, 0), a + Vector2(sx * 0.15, -h * 0.5), Color(encre, 0.4), 1.0)
				ci.draw_line(a + Vector2(sx * 0.85, 0), a + Vector2(sx * 0.85, -h * 0.5), Color(encre, 0.4), 1.0)
				ci.draw_line(a, b, encre, 1.4)
				var dessus := PackedVector2Array([a - Vector2(0, h), b - Vector2(0, h), b - Vector2(0, h + ep * 0.45), a - Vector2(0, h + ep * 0.45)])
				ci.draw_colored_polygon(dessus, Color("EFEADF"))
				ci.draw_line(dessus[0], dessus[1], encre, 1.1)
				ci.draw_line(dessus[2], dessus[3], encre, 1.3)
			else:
				var a := centre
				var flanc := PackedVector2Array([a + Vector2(ep * 0.5, 0), b + Vector2(ep * 0.5, 0), b + Vector2(ep * 0.5, -h), a + Vector2(ep * 0.5, -h)])
				ci.draw_colored_polygon(flanc, Color("C2BBA9"))
				ci.draw_line(flanc[0], flanc[1], encre, 1.1)
				ci.draw_line(flanc[3], flanc[2], Color(encre, 0.5), 1.0)
				var dessus := PackedVector2Array([a + Vector2(-ep * 0.5, -h), b + Vector2(-ep * 0.5, -h), b + Vector2(ep * 0.5, -h), a + Vector2(ep * 0.5, -h)])
				ci.draw_colored_polygon(dessus, Color("EFEADF"))
				ci.draw_line(dessus[0], dessus[1], encre, 1.3)
				ci.draw_line(dessus[3], dessus[2], encre, 1.1)
		# pilier : seulement aux angles, extrémités et tous les 3 segments
		var droit := dirs.size() == 2 and Vector2(dirs[0]) == -Vector2(dirs[1])
		if droit and int(centre.x / tile + centre.y / tile) % 3 != 0:
			return
		var pil := Rect2(centre + Vector2(-ep * 0.42, -h - ep * 0.45), Vector2(ep * 0.84, h + ep * 0.45))
		ci.draw_rect(pil, Color("E4DED0"))
		ci.draw_rect(pil, encre, false, 1.2)
		ci.draw_rect(Rect2(pil.position, Vector2(pil.size.x, ep * 0.3)), Color("F6F2EA"))
		ci.draw_rect(Rect2(pil.position, Vector2(pil.size.x, ep * 0.3)), encre, false, 1.0)
		return
	# bois
	var hp := tile * 0.62
	for d in dirs:
		var b := centre + Vector2(d) * tile * 0.5
		for t in [0.35, 0.72]:
			ci.draw_line(centre - Vector2(0, hp * t), b - Vector2(0, hp * t), encre, 3.4)
			ci.draw_line(centre - Vector2(0, hp * t), b - Vector2(0, hp * t), Color("A0703E"), 1.8)
	var pt := Rect2(centre + Vector2(-tile * 0.08, -hp), Vector2(tile * 0.16, hp))
	ci.draw_rect(pt, Color("7A5230"))
	ci.draw_rect(pt, encre, false, 1.0)
