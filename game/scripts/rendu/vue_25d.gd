class_name Vue25D
extends Node
## Essai jouable de la vue isométrique (F2 en jeu, ou --iso) et de la vue 3D (F3, ou --voie3). Ce n'est pas le mode
## principal : la partie ne change pas. Molette enfoncée + glisser ou direction : tourne et incline la vue.
## - Sol : main.gd et la carte continuent de dessiner comme d'habitude. Un SubViewport partage leur World2D et photographie
##   toute la carte : chemins, chantiers, repères et sélections se retrouvent ainsi drapés sur un terrain en relief.
## - Tout ce qui est debout (bâtiments, animaux, personnages) n'est plus dessiné en 2D : SpritesBD le note (collecte), et cette
##   vue le pose en Sprite3D, aux mêmes positions et avec les mêmes images. Arbres et rochers viennent de DecorBD.
## - Clôtures : panneaux dans l'espace, à partir des images de face.
## - Clics : main._screen_to_world passe par monde_depuis_ecran. Tout le reste du code garde ses coordonnées de carte.

const ECHELLE_SOL := 3  # pixels de la photo du sol par pixel du monde (16 pixels du monde par case)
const FOV := 38.0
const AXES_ALIGNEMENT := 8.0  # degrés : à moins de cet écart d'un multiple de 45°, la vue s'aligne au relâchement
const TANGAGE_MIN := 18.0
const TANGAGE_MAX := 80.0
const CADRAGE := 1.15  # à zoom égal, un peu plus de terrain visible qu'en 2D
const AGRANDI_BATIMENT := 0.25  # en plus à 45° : une emprise vue en losange est plus large, le bâtiment doit suivre
const RELIEF := {"Prairie": 0.0, "Foret": 0.1, "Eau": -0.26, "Roche": 0.22, "Sable": 0.02, "Montagne": 1.1, "MineOr": 0.2}
const PAS_GRILLE := 2  # points de relief par case

var m  # main.gd
var lacet := 45.0  # 0 : on regarde vers le nord, dans l'axe mairie, route, camp
var tangage := 35.0
var perspective := false
var etendue := 30.0  # cases visibles en hauteur
var env: Environment
var couleurs_rail := {"enceinte": Color("EFE6D0"), "enclos": Color("B97A35"), "enclos_herbivore": Color("F0C02A"), "enclos_predateur": Color("2F6B3A"),
	"enclos_aquatique": Color("BFE6F0"), "enclos_aerien": Color("C8A070")}
var map: GameMap
var sol_vp: SubViewport
var vue: SubViewport
var image: TextureRect
var racine: Node3D
var camera: Camera3D
var terrain: MeshInstance3D
var clotures: Node3D
var hauteurs := PackedFloat32Array()
var sprites: Array[Sprite3D] = []
var textes: Array[Label3D] = []
var decor3d := {}
var mats := {}
var cadres: Array = []
var silhouettes := {}  # Sprite3D d'un personnage -> sa silhouette (MeshInstance3D, vue à travers ce qui le cache)
var mats_silhouette := {}
const SILHOUETTE := """
shader_type spatial;
// Ce qui est caché derrière un bâtiment ou un arbre : test de profondeur inversé, la silhouette n'apparaît que là.
render_mode unshaded, depth_draw_never, depth_test_inverted, cull_disabled, blend_mix;
uniform sampler2D tex : source_color, filter_linear_mipmap;
instance uniform vec4 cadre;  // rectangle de l'image autour du pied, en cases (x, y, largeur, hauteur ; y vers le haut)
instance uniform vec4 region;  // partie de la texture (u, v, largeur, hauteur)
instance uniform vec4 teinte;
instance uniform float miroir;
void vertex() {
	VERTEX = vec3(cadre.x + (VERTEX.x + 0.5) * cadre.z, cadre.y + (VERTEX.y + 0.5) * cadre.w, 0.0);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	vec2 uv = UV;
	if (miroir > 0.5) {
		uv.x = 1.0 - uv.x;
	}
	UV = region.xy + uv * region.zw;
}
void fragment() {
	if (texture(tex, UV).a < 0.5) {
		discard;
	}
	ALBEDO = teinte.rgb;
	ALPHA = teinte.a;
}
"""
var shader_silhouette: Shader
var sig_terrain := -1
var sig_clotures := ""
var attente := 0.0


func _init(principal) -> void:
	m = principal


func _ready() -> void:
	# Le sol : la même toile 2D que la fenêtre, cadrée sur toute la carte
	sol_vp = SubViewport.new()
	sol_vp.world_2d = m.get_viewport().world_2d
	sol_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sol_vp.canvas_transform = Transform2D().scaled(Vector2.ONE * ECHELLE_SOL)
	add_child(sol_vp)
	# Le monde 3D, affiché sous l'interface
	vue = SubViewport.new()
	vue.own_world_3d = true
	vue.msaa_3d = Viewport.MSAA_4X
	vue.positional_shadow_atlas_size = 2048
	vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vue)
	racine = Node3D.new()
	vue.add_child(racine)
	image = TextureRect.new()
	image.texture = vue.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.ui.add_child(image)
	m.ui.move_child(image, 0)
	env = Environment.new()
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
	soleil.rotation_degrees = Vector3(-52.0, 15.0, 0.0)
	soleil.light_energy = 0.62
	soleil.shadow_enabled = true
	soleil.directional_shadow_max_distance = 300.0
	soleil.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	soleil.shadow_opacity = 0.7
	soleil.shadow_blur = 1.4
	racine.add_child(soleil)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 1.0
	camera.far = 3000.0
	racine.add_child(camera)
	camera.current = true
	var autour := MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = Vector2(4000, 4000)
	autour.mesh = plan
	var ma := StandardMaterial3D.new()
	ma.albedo_color = Color("6FA845")
	ma.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	autour.material_override = ma
	autour.position = Vector3(32, -0.8, 32)  # sous l'eau, la plus basse du terrain
	racine.add_child(autour)
	clotures = Node3D.new()
	racine.add_child(clotures)
	terrain = MeshInstance3D.new()
	racine.add_child(terrain)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = sol_vp.get_texture()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.roughness = 1.0
	mat.metallic_specular = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	terrain.material_override = mat
	_synchroniser()
	regler_perspective(perspective)


## Isométrique ou caméra en perspective : deux réglages de la même scène.
func regler_perspective(oui: bool) -> void:
	perspective = oui
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE if oui else Camera3D.PROJECTION_ORTHOGONAL
	camera.fov = FOV
	env.background_color = Color("BFE3F0") if oui else UiTokens.ENCRE
	if oui:
		tangage = minf(tangage, 40.0)
	_placer_camera()


## Molette enfoncée : le glissement tourne autour de la verticale et incline la vue.
func tourner(d_lacet: float, d_tangage: float) -> void:
	lacet = fposmod(lacet - d_lacet, 360.0)
	tangage = clampf(tangage + d_tangage, TANGAGE_MIN, TANGAGE_MAX)
	_placer_camera()
	sig_clotures = ""  # les rails suivent l'axe de la vue
	attente = minf(attente, 0.1)


## Au relâchement, la vue se cale sur l'axe voisin : 0° est l'axe mairie, route, camp.
func aligner() -> void:
	var axe := roundf(lacet / 45.0) * 45.0
	if absf(lacet - axe) <= AXES_ALIGNEMENT:
		lacet = fposmod(axe, 360.0)
		_placer_camera()


## Déplacement sur la carte vu à l'écran : son décalage horizontal (+ : vers la droite).
func x_ecran(d: Vector2) -> float:
	var l := deg_to_rad(lacet)
	return d.x * cos(l) - d.y * sin(l)


## Direction, sur la carte, de ce qui est tourné vers la caméra.
func _vers_camera() -> Vector2:
	var l := deg_to_rad(lacet)
	return Vector2(sin(l), cos(l))


## Retour à la vue 2D : le décor reprend sa place, rien d'autre n'a changé.
func quitter() -> void:
	if is_instance_valid(m.carte) and m.carte.decor:
		m.carte.decor.visible = true
	image.queue_free()
	SpritesBD.collecte = null
	queue_free()


func _process(delta: float) -> void:
	var ecran: Vector2i = get_window().size
	if vue.size != ecran:
		vue.size = ecran
	_placer_camera()
	attente -= delta
	if attente <= 0.0:
		attente = 0.5
		_synchroniser()


func _placer_camera() -> void:
	var cible := Vector3(m.camera.position.x / m.TILE, 0.0, m.camera.position.y / m.TILE)
	var t := deg_to_rad(tangage)
	var dir := Vector3(0.0, sin(t), cos(t)).rotated(Vector3.UP, deg_to_rad(lacet))
	etendue = _hauteur_ui() / (m.camera.zoom.x * m.TILE) * CADRAGE
	camera.size = etendue
	var recul := etendue / (2.0 * tan(deg_to_rad(FOV) / 2.0)) if perspective else 200.0
	camera.look_at_from_position(cible + dir * recul, cible)


func _hauteur_ui() -> float:
	return m.get_viewport_rect().size.y


func _synchroniser() -> void:
	var mp: GameMap = m.game.map
	sol_vp.size = Vector2i(mp.w, mp.h) * int(m.TILE) * ECHELLE_SOL
	if map != mp:
		map = mp
		sig_terrain = -1
		sig_clotures = ""
		for k in decor3d:
			decor3d[k].queue_free()
		decor3d.clear()
	var s := hash(mp.tiles)
	if s != sig_terrain:
		sig_terrain = s
		_construire_terrain()
		sig_clotures = ""
		for k in decor3d:
			decor3d[k].position.y = _h(decor3d[k].position.x, decor3d[k].position.z)
	_synchroniser_decor()
	_synchroniser_clotures()


# ------------------------------------------------------------------ terrain

func _calculer_hauteurs() -> void:
	var w := map.w * PAS_GRILLE + 1
	var h := map.h * PAS_GRILLE + 1
	hauteurs.resize(w * h)
	for y in h:
		for x in w:
			var tx := clampi(x / PAS_GRILLE, 0, map.w - 1)
			var ty := clampi(y / PAS_GRILLE, 0, map.h - 1)
			var v: float = RELIEF.get(GameMap.TERRAINS[map.get_t(tx, ty)], 0.0)
			hauteurs[y * w + x] = 0.0 if map.road[map.idx(tx, ty)] else v
	for passe in 3:
		var copie := hauteurs.duplicate()
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				hauteurs[y * w + x] = (copie[y * w + x] * 4.0 + copie[y * w + x - 1] + copie[y * w + x + 1] + copie[(y - 1) * w + x] + copie[(y + 1) * w + x]) / 8.0


func _h(x: float, z: float) -> float:
	var w := map.w * PAS_GRILLE + 1
	var h := map.h * PAS_GRILLE + 1
	if hauteurs.is_empty():
		return 0.0
	return hauteurs[clampi(int(round(z * PAS_GRILLE)), 0, h - 1) * w + clampi(int(round(x * PAS_GRILLE)), 0, w - 1)]


func _construire_terrain() -> void:
	_calculer_hauteurs()
	var w := map.w * PAS_GRILLE + 1
	var h := map.h * PAS_GRILLE + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in h:
		for x in w:
			st.set_uv(Vector2(float(x) / (w - 1), float(y) / (h - 1)))
			st.add_vertex(Vector3(float(x) / PAS_GRILLE, hauteurs[y * w + x], float(y) / PAS_GRILLE))
	for y in h - 1:
		for x in w - 1:
			var a := y * w + x
			for i in [a, a + 1, a + w, a + 1, a + w + 1, a + w]:
				st.add_index(i)
	st.generate_normals()
	terrain.mesh = st.commit()


# ------------------------------------------------------------------ objets debout

func _nouveau_sprite() -> Sprite3D:
	var s := Sprite3D.new()
	s.centered = false
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	racine.add_child(s)
	return s


## taille : cases par pixel de l'image.
func _regler(s: Sprite3D, tex: Texture2D, pied: Vector2, x: float, z: float, taille: float, miroir := false, region := Rect2()) -> void:
	s.texture = tex
	var dim := Vector2(tex.get_width(), tex.get_height())
	s.region_enabled = region.size != Vector2.ZERO
	if s.region_enabled:
		s.region_rect = region
		dim = region.size
	s.offset = Vector2(-(dim.x - pied.x) if miroir else -pied.x, -(dim.y - pied.y))
	s.flip_h = miroir
	s.pixel_size = taille
	s.position = Vector3(x, _h(x, z), z)


func _synchroniser_decor() -> void:
	var carte: CarteBD = m.carte
	if carte == null or carte.decor == null:
		return
	carte.decor.visible = false
	for k in decor3d.keys():
		if not is_instance_valid(k):
			decor3d[k].queue_free()
			decor3d.erase(k)
	for n in carte.decor.get_children():
		if not n is Sprite2D:
			continue
		var d: Sprite2D = n
		if not decor3d.has(d):
			var s := _nouveau_sprite()
			var pied := -d.offset
			if d.flip_h:
				pied = Vector2(-d.offset.x * 0 + d.texture.get_width() + d.offset.x, -d.offset.y)
			_regler(s, d.texture, pied, d.position.x / m.TILE, d.position.y / m.TILE, d.scale.x / m.TILE, d.flip_h)
			decor3d[d] = s
		decor3d[d].visible = d.visible


## Appelé à la fin du dessin du monde : place les sprites notés par SpritesBD.
func recevoir(notes: Array) -> void:
	cadres.clear()
	var n := 0
	var nb_textes := 0
	var cote_cam := _vers_camera()
	var vers_cam := absf(sin(2.0 * deg_to_rad(lacet)))  # 0 dans l'axe d'un côté, 1 en diagonale
	var batis: Array = []  # [emprise, pied de l'image] des bâtiments posés
	var persos: Array = []  # [sprite, position sur la carte, collaborateur]
	for e: Dictionary in notes:
		if e.has("texte"):
			_poser_texte(nb_textes, e)
			nb_textes += 1
			continue
		if n >= sprites.size():
			sprites.append(_nouveau_sprite())
		var s: Sprite3D = sprites[n]
		n += 1
		s.visible = true
		var tex: Texture2D = e["tex"]
		var pos: Vector2 = e["pos"] / m.TILE
		var taille: float = float(e["k"]) / m.TILE
		var objet: Variant = e["objet"]
		var rect := Rect2()
		if objet is GameState.Site:
			rect = Rect2(objet.rect)
		elif objet is String and objet == "camp":
			rect = Rect2(m.game.map.camp)
		var pied_note: Vector2 = e["pied"]
		if rect.size != Vector2.ZERO and (not objet is GameState.Site or not objet.def.get("effet", {}).has("decor")):
			# Le pied du bâtiment va au bord de l'emprise tourné vers la caméra
			var profond: float = maxf(rect.size.x, rect.size.y) * (0.5 - 0.08 * vers_cam)
			pos = rect.get_center() + cote_cam * profond
			taille *= 1.0 + AGRANDI_BATIMENT * vers_cam
			var biais := _image_de_biais(objet, rect)
			if not biais.is_empty():
				tex = biais["tex"]
				pied_note = biais["pied"]
				pos = rect.get_center() + cote_cam * maxf(rect.size.x, rect.size.y) * 0.68
				taille = biais["taille"]
		_regler(s, tex, pied_note, pos.x, pos.y, taille, e["miroir"], e["region"])
		s.modulate = e["teinte"]
		if rect.size != Vector2.ZERO:
			batis.append([rect, s.position])
		if objet is GameState.Worker:
			persos.append([s, objet.pos, objet])
		_silhouette(s, objet if objet is GameState.Worker else null)
		# Cadres cliquables : personnages et bâtiments
		if objet is GameState.Worker or objet is GameState.Site:
			var dim: Vector2 = (e["region"] as Rect2).size if e["region"].size != Vector2.ZERO else Vector2(tex.get_width(), tex.get_height())
			var ecran := ecran_de(s.position)
			# Pixels d'interface par case, à cette distance de la caméra (elle varie en perspective)
			var par_case: float = ecran.distance_to(ecran_de(s.position + camera.global_basis.x))
			var r := Rect2(ecran - pied_note * taille * par_case, dim * taille * par_case)
			var cible: Vector2 = objet.pos * m.TILE if objet is GameState.Worker else Vector2(objet.rect.get_center()) * m.TILE + Vector2(m.TILE, m.TILE) * 0.0
			if objet is GameState.Worker:
				r = r.grow_individual(-r.size.x * 0.32, -r.size.y * 0.1, -r.size.x * 0.32, 0.0)
			else:
				r = r.grow(-r.size.x * 0.1)
			cadres.append({"rect": r, "monde": cible, "rang": (1000.0 if objet is GameState.Worker else 0.0) + s.position.x * cote_cam.x + s.position.z * cote_cam.y})
	_devant_les_batiments(batis, persos)
	for k in range(n, sprites.size()):
		sprites[k].visible = false
		if silhouettes.has(sprites[k]):
			silhouettes[sprites[k]].visible = false
	for k in range(nb_textes, textes.size()):
		textes[k].visible = false
	cadres.sort_custom(func(a, b): return a["rang"] > b["rang"])


## Un collaborateur dans l'emprise d'un bâtiment (au camp, à son poste) est dedans : en 2D il est dessiné par-dessus.
## L'image du bâtiment se tient au bord de l'emprise tourné vers la caméra, il passerait donc derrière : on le rapproche
## de la caméra le long du rayon de vue, ce qui ne change pas sa place à l'écran, jusqu'à passer devant.
func _devant_les_batiments(batis: Array, persos: Array) -> void:
	for pe in persos:
		var s: Sprite3D = pe[0]
		var case_: Vector2 = pe[1]
		var vers := camera.global_basis.z
		if perspective:
			vers = (camera.global_position - s.position).normalized()
		var recul := 0.0
		for b in batis:
			var r: Rect2 = b[0]
			if r.grow(0.25).has_point(case_):
				recul = maxf(recul, (b[1] - s.position).dot(vers) + 0.2)
		if recul <= 0.0:
			continue
		if perspective:
			# Plus près de la caméra, il paraîtrait plus grand : sa taille suit la distance
			var d0 := camera.global_position.distance_to(s.position)
			s.pixel_size *= maxf(0.1, (d0 - recul) / d0)
		s.position += vers * recul
		_silhouette(s, pe[2])  # elle suit le personnage avancé


## Silhouette couleur du joueur, visible seulement là où le personnage est caché (arbre, bâtiment devant lui).
## Un quadrilatère calculé ici plutôt qu'un Sprite3D : un Sprite3D avec un matériau à lui ne se dessine pas toujours.
func _silhouette(s: Sprite3D, w: Variant) -> void:
	var sil: MeshInstance3D = silhouettes.get(s)
	if w == null:
		if sil:
			sil.visible = false
		return
	if sil == null:
		sil = MeshInstance3D.new()
		sil.mesh = QuadMesh.new()
		sil.extra_cull_margin = 4.0
		sil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		racine.add_child(sil)
		silhouettes[s] = sil
	if shader_silhouette == null:
		shader_silhouette = Shader.new()
		shader_silhouette.code = SILHOUETTE
	var tex := s.texture
	var cle := tex.get_rid().get_id()
	if not mats_silhouette.has(cle):
		var mat := ShaderMaterial.new()
		mat.shader = shader_silhouette
		mat.set_shader_parameter("tex", tex)
		# Les images (bâtiments, arbres) passent aussi parmi les objets transparents, du plus loin au plus près :
		# la silhouette vient après toutes, sinon le bâtiment devant la recouvrirait.
		mat.render_priority = 1
		mats_silhouette[cle] = mat
	var taille_tex := Vector2(tex.get_width(), tex.get_height())
	var reg := s.region_rect if s.region_enabled else Rect2(Vector2.ZERO, taille_tex)
	var px := s.pixel_size
	var couleur: Color = UiTokens.SELECTION if m.selected.has(w) else UiTokens.JOUEURS[m.game.index % UiTokens.JOUEURS.size()]
	sil.visible = true
	sil.material_override = mats_silhouette[cle]
	sil.position = s.position
	sil.set_instance_shader_parameter("cadre", Vector4(s.offset.x * px, s.offset.y * px, reg.size.x * px, reg.size.y * px))
	sil.set_instance_shader_parameter("region", Vector4(reg.position.x / taille_tex.x, reg.position.y / taille_tex.y, reg.size.x / taille_tex.x, reg.size.y / taille_tex.y))
	sil.set_instance_shader_parameter("teinte", Vector4(couleur.r, couleur.g, couleur.b, 0.6))
	sil.set_instance_shader_parameter("miroir", 1.0 if s.flip_h else 0.0)


## Bâtiment dessiné de biais, s'il existe et si la vue est en diagonale : iso_<id> (façade vers le bas à gauche), iso_<id>_d (vers le bas à droite).
func _image_de_biais(objet: Variant, rect: Rect2) -> Dictionary:
	if not objet is GameState.Site or not objet.done:
		return {}
	var s := sin(deg_to_rad(lacet))
	if absf(s) < 0.38:
		return {}  # dans l'axe : l'image de face est la bonne
	var nom := "iso_%s" % objet.def_id()
	if s < 0.0:
		nom += "_d"
	if not SpritesBD.existe(nom):
		return {}
	var tex := SpritesBD.texture(nom)
	return {"tex": tex, "pied": SpritesBD.pied(nom), "taille": (rect.size.x + rect.size.y) * 0.8 / tex.get_width()}


func _poser_texte(i: int, e: Dictionary) -> void:
	if i >= textes.size():
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.font = m.font_noms
		l.outline_size = 10
		l.render_priority = 2
		l.outline_render_priority = 1
		racine.add_child(l)
		textes.append(l)
	var l := textes[i]
	l.visible = true
	l.text = e["texte"]
	l.font_size = 24
	l.pixel_size = etendue / _hauteur_ui() * clampf(float(e["taille"]) * 0.05, 0.4, 0.9)
	l.modulate = e["encre"]
	l.outline_modulate = e["fond"]
	var p: Vector2 = e["pos"] / m.TILE
	var hausse := 2.8 if str(e["texte"]).begins_with("Camp") else 0.4  # au-dessus de l'image du camp
	l.position = Vector3(p.x, _h(p.x, p.y) + hausse, p.y)


# ------------------------------------------------------------------ clôtures

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


func _style_de(s: GameState.Site, styles: Dictionary) -> String:
	return "enceinte" if s.def_id() == "cloture" else str(styles.get(s.rect.position, "enclos"))


func _synchroniser_clotures() -> void:
	var styles: Dictionary = m._styles_enclos()
	var liste := []
	var parts: Array[String] = []
	for s: GameState.Site in m.game.sites:
		if s.done and s.def_id() in ["cloture", "enclos"]:
			liste.append(s)
			parts.append("%d,%d,%s" % [s.rect.position.x, s.rect.position.y, _style_de(s, styles)])
	var sig := "|".join(parts)
	if sig == sig_clotures:
		return
	sig_clotures = sig
	for c in clotures.get_children():
		clotures.remove_child(c)
		c.queue_free()
	var liens: Dictionary = m._wall_links()
	for s: GameState.Site in liste:
		_construire_cloture(s, _style_de(s, styles), liens)


## Un tronçon debout, de longueur « long », centré en (cx, cz). angle en degrés autour de la verticale.
func _troncon(style: String, phase: int, cx: float, cz: float, long: float, angle: float) -> float:
	var face := SpritesBD.texture("cl_%s_face" % style)
	var haut := 2.0 * face.get_height() / float(face.get_width())
	var q := QuadMesh.new()
	q.size = Vector2(long, haut)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = _mat_cloture(style, phase)
	mi.position = Vector3(cx, _h(cx, cz) + haut / 2.0, cz)
	mi.rotation_degrees.y = angle
	clotures.add_child(mi)
	return haut


func _construire_cloture(s: GameState.Site, style: String, liens: Dictionary) -> void:
	var p: Vector2i = s.rect.position
	var id: String = s.def_id()
	var droit := 0
	var en_x := false
	var c := Vector2(p) + Vector2(0.5, 0.5)
	for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		var o: GameState.Site = m.game.site_at(p + d)
		if o == null or not o.done or m._lignes_paralleles(p, d, id):
			continue
		var pareil: bool = o.def_id() == id
		var accroche: bool = (id == "cloture" and o.def_id() == "entree") or (id == "enclos" and o.def_id() in ["cloture", "entree"] and liens.has(p))
		if not pareil and not accroche:
			continue
		droit += 1
		en_x = en_x or d.x != 0
		if pareil and (d.x < 0 or d.y < 0):
			continue  # la case d'à côté s'en charge
		var long := 1.0 if pareil else 0.5
		var centre := c + Vector2(d) * long * 0.5
		var phase: int = posmod(p.x if d.x != 0 else p.y, 2)
		var haut := _troncon(style, phase, centre.x, centre.y, long, 0.0 if d.x != 0 else 90.0)
		# Un dessus : vue dans son axe, la clôture ne disparaît pas
		var large := 0.2 if id == "cloture" else 0.07
		var b := BoxMesh.new()
		b.size = Vector3(long, 0.05, large) if d.x != 0 else Vector3(large, 0.05, long)
		var dessus := MeshInstance3D.new()
		dessus.mesh = b
		var mb := StandardMaterial3D.new()
		mb.albedo_color = couleurs_rail.get(style, Color("B97A35"))
		mb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dessus.material_override = mb
		dessus.position = Vector3(centre.x, _h(centre.x, centre.y) + haut * (1.0 if id == "cloture" else 0.8), centre.y)
		clotures.add_child(dessus)
	# Coins seuls : un tronçon de biais
	var diagonale := false
	for d: Vector2i in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		if m._cloture_finie(p + d) and not m._cloture_finie(p + Vector2i(d.x, 0)) and not m._cloture_finie(p + Vector2i(0, d.y)) \
				and (id == "cloture") == (m.game.site_at(p + d).def_id() == "cloture"):
			diagonale = true
			if d.x > 0:
				var centre := c + Vector2(d) * 0.5
				_troncon(style, 0, centre.x, centre.y, 1.414, 45.0 if d.y < 0 else -45.0)
	var rang: int = p.x if en_x else p.y
	if droit != 2 or diagonale or posmod(rang, 6 if id == "cloture" else 2) == 0:
		var pot := SpritesBD.texture("cl_%s_poteau" % style)
		var face := SpritesBD.texture("cl_%s_face" % style)
		var sp := Sprite3D.new()
		sp.centered = false
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.shaded = false
		sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		clotures.add_child(sp)
		_regler(sp, pot, Vector2(pot.get_width() / 2.0, pot.get_height()), c.x, c.y, 2.0 / face.get_width() * 0.75)


# ------------------------------------------------------------------ clics

func _vers_vue(p: Vector2) -> Vector2:
	return p * Vector2(vue.size) / m.get_viewport_rect().size


## Position à l'écran (coordonnées de l'interface) d'un point du monde 3D.
func ecran_de(point: Vector3) -> Vector2:
	return camera.unproject_position(point) * m.get_viewport_rect().size / Vector2(vue.size)


func _sur_le_plan(p: Vector2, y: float) -> Vector3:
	var o := camera.project_ray_origin(_vers_vue(p))
	var d := camera.project_ray_normal(_vers_vue(p))
	return o + d * (y - o.y) / d.y


## Le terrain sous ce point de l'écran, relief compris.
func sol(p: Vector2) -> Vector2:
	_placer_camera()
	var q := _sur_le_plan(p, 0.0)
	for k in 8:  # amorti : sur une pente, le point oscillerait sinon d'une case à l'autre
		q = q.lerp(_sur_le_plan(p, _h(q.x, q.z)), 0.6)
	return Vector2(q.x, q.z) * m.TILE


## Ce que vise la souris : un personnage ou un bâtiment s'il est dessous (leur image dépasse de leur case), sinon le sol.
func monde_depuis_ecran(p: Vector2) -> Vector2:
	if m.build_choice.is_empty():
		for c in cadres:
			if c["rect"].has_point(p):
				return c["monde"]
	return sol(p)


## Glissement de la vue : le déplacement au sol qui correspond à ce déplacement à l'écran.
func delta_monde(d: Vector2) -> Vector2:
	_placer_camera()
	var centre: Vector2 = m.get_viewport_rect().size / 2.0
	var a := _sur_le_plan(centre, 0.0)
	var b := _sur_le_plan(centre + d, 0.0)
	return Vector2(b.x - a.x, b.z - a.z) * m.TILE
