class_name Tutoriel
extends Control
## Tutoriel scénarisé : une première partie sur une graine fixée, racontée en bulles de BD par un cadre de ZooLife.
## Une suite d'étapes : le cadre parle (Suivant), demande une action (l'étape avance quand elle est faite) ou fait
## passer le temps. `preparer()` règle la partie avant la construction de la carte ; `main.gd` consulte `pose_permise`,
## `fin_de_journee_permise` et `temps_verrouille`, et appelle `dessiner_monde` à la fin de son _draw.
##
## Contrôle : godot --path game -- --tutoriel --tuto-auto --tuto-dossier=C:/chemin  joue seul et capture chaque étape.

const GRAINE := 404283
## Expression d'Hubert selon le début de sa réplique (neutre sinon).
const TETES := {"Bienvenue": "content", "Notre mission": "neutre", "Article 47": "moqueur", "Avec la hausse": "moqueur", "Assez parlé": "contrarie",
	"Parfait": "content", "Fin de journée": "contrarie", "Après diverses": "contrarie", "Ma qualité": "moqueur", "[b]100 de bois": "content",
	"Excellent": "content", "Le [b]Kiosque": "moqueur", "Les [b]labels": "moqueur", "Et chaque nuit": "moqueur", "Votre période": "moqueur"}
const CADRE := {"nom": "Hubert de la Marge", "titre": "Directeur des Ressources, Humaines et Autres, ZooLife™", "perso": "victor"}
const RIVAUX := ["ZooLife™ (vous)", "PanZoo Holdings", "Safari Capital", "BioLand Group"]
const ESPECE := "bison_amerique"
const EQUIPE := ["bucheron", "terrassier", "manoeuvre", "paysagiste", "guichetier", "charpentier", "macon", "animalier"]
const PARC := Vector2i(10, 8)
const ARGENT_VISE := 25
const TRAITS_EXEMPLE := {"bucheron": ["costaud"], "terrassier": ["distrait"], "manoeuvre": ["rapide", "gourmand"]}

var m  # main.gd
var mt: Match
var game: GameState
var etapes: Array = []
var i := -1
var etape := {}
var temps_verrouille := true
var parc := Rect2i()
var entree := Vector2i()
var clotures: Array[Vector2i] = []
var interieur: Array[Vector2i] = []
var case_foret := Vector2i()
var auto := false
var dossier := ""
var attente_auto := 0
var horloge := 0.0
var limite := 0.0
var espece := {}
var rapport_jour := 0.0

var voile: Voile
var bulle: PanelContainer
var queue: Queue
var portrait_cadre: Panel
var portrait_image: TextureRect
var nom_label: Label
var texte: RichTextLabel
var suivant: Button
var quitter: Button
var consigne: Label
var titre_ecran: Label
var logos_box: HBoxContainer


## Voile sombre percé autour des éléments montrés ; il arrête les clics partout sauf dans les trous.
class Voile extends Control:
	var trous: Array[Rect2] = []
	var bloque := true
	var sombre := true
	var passe := false  # clics permis dans les trous (action demandée) ; sinon, on montre seulement
	var pouls := 0.0

	func _has_point(p: Vector2) -> bool:
		if not bloque:
			return false
		return not passe or not trous.any(func(r): return r.has_point(p))

	func _draw() -> void:
		if sombre:
			var xs: Array[float] = [0.0, size.x]
			var ys: Array[float] = [0.0, size.y]
			for r in trous:
				xs.append_array([r.position.x, r.end.x])
				ys.append_array([r.position.y, r.end.y])
			xs.sort()
			ys.sort()
			for a in xs.size() - 1:
				for b in ys.size() - 1:
					var c := Rect2(xs[a], ys[b], xs[a + 1] - xs[a], ys[b + 1] - ys[b])
					if c.size.x > 0.0 and c.size.y > 0.0 and not trous.any(func(r): return r.encloses(c)):
						draw_rect(c, Color(0.03, 0.06, 0.12, 0.55))
		for r in trous:
			var g := 3.0 + 2.5 * sin(pouls * 5.0)
			draw_rect(r.grow(g), UiTokens.SELECTION, false, 4.0)


## Petit triangle du bouton Suivant.
class Fleche extends Control:
	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(10, 7), Vector2(0, 14)]), UiTokens.ENCRE)


## Queue de la bulle : triangle vers le portrait, qui recouvre le bord de la bulle.
class Queue extends Control:
	var a_droite := false

	func _draw() -> void:
		# La queue est dans le conteneur de la bulle : on sort de ses marges (24 à gauche et à droite) pour toucher le bord.
		var d := -1.0 if a_droite else 1.0
		var o := Vector2(size.x + 24.0 if a_droite else -24.0, 30.0)
		var pts := PackedVector2Array([o + Vector2(d * 2.0, -15.0), o + Vector2(d * 2.0, 15.0), o + Vector2(-d * 36.0, 6.0)])
		draw_colored_polygon(pts, Color.WHITE)
		draw_line(pts[0], pts[2], UiTokens.ENCRE, 3.0, true)
		draw_line(pts[1], pts[2], UiTokens.ENCRE, 3.0, true)


# --- Préparation de la partie -----------------------------------------------------------------------------

## Avant la construction de la carte : pas de draft, équipe imposée, terrain dégagé pour le parc, bois et rochers tout près.
static func preparer(partie: Match) -> void:
	while partie.phase == "draft":
		partie.pick_draft(partie.ai_choice())
	for k in partie.names.size():
		partie.names[k] = RIVAUX[k % RIVAUX.size()]
	var g: GameState = partie.players[0]
	var cartes: Array = []
	for id in EQUIPE:
		cartes.append(_carte(partie, id))
	g.hand.clear()
	g.discard.clear()
	g.deck.assign(cartes)
	_forcer_main(g, EQUIPE.slice(0, 4))
	var k := g.map
	var r := _rect_parc(k)
	for y in range(r.position.y - 1, r.end.y + 3):
		for x in range(r.position.x - 1, r.end.x + 1):
			if k.in_bounds(x, y) and not k.in_camp(x, y) and not k.road[k.idx(x, y)]:
				k.set_t(x, y, GameMap.PRAIRIE)
	var c := k.camp
	for y in range(c.position.y, c.end.y):
		for dx in 5:
			_poser_terrain(k, c.position.x - 3 - dx, y, GameMap.FORET)
			_poser_terrain(k, c.end.x + 2 + dx, y, GameMap.ROCHE)
	k.build_astar()


static func _poser_terrain(k: GameMap, x: int, y: int, t: int) -> void:
	if k.in_bounds(x, y) and not k.road[k.idx(x, y)] and not k.in_camp(x, y):
		k.set_t(x, y, t)
		k.reset_resource(x, y)


static func _rect_parc(k: GameMap) -> Rect2i:
	var bas := k.camp.position.y - 3
	return Rect2i(k.camp.get_center().x - 5, bas - PARC.y + 1, PARC.x, PARC.y)


static func _carte(partie: Match, id: String) -> GameState.Card:
	var c := partie.make_card("peu_qualifie")
	for d in partie.data["workers"]["metiers"]:
		if d["id"] == id:
			c.metier = d
	c.traits.assign(TRAITS_EXEMPLE.get(id, []))
	return c


## Met en main les cartes de ces métiers ; les autres retournent dans la pioche.
static func _forcer_main(g: GameState, metiers: Array) -> void:
	var toutes: Array = g.hand + g.deck + g.discard
	g.hand.clear()
	g.discard.clear()
	var reste: Array = []
	for c in toutes:
		if metiers.has(c.metier["id"]) and not c.deployed:
			g.hand.append(c)
		else:
			reste.append(c)
	g.deck.assign(reste)
	g.version += 1


func _init(principal, _auto := false, _dossier := "") -> void:
	m = principal
	mt = m.mt
	game = m.game
	auto = _auto
	dossier = _dossier
	name = "Tutoriel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	parc = _rect_parc(game.map)
	entree = Vector2i(parc.position.x + 4, parc.end.y - 1)
	for d in game.data["animals"]["animaux"]:
		if d["id"] == ESPECE:
			espece = d
	var p := parc.position
	for t in [Vector2i(4, 1), Vector2i(4, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3)]:
		clotures.append(p + t)
	for y in [1, 2]:
		for x in [1, 2, 3]:
			interieur.append(p + Vector2i(x, y))
	case_foret = p + Vector2i(3, 2)


func _ready() -> void:
	voile = Voile.new()
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)
	_construire_bulle()
	titre_ecran = Label.new()
	titre_ecran.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	titre_ecran.offset_top = 84
	titre_ecran.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var recit := StyleBoxFlat.new()
	recit.bg_color = UiTokens.SELECTION
	recit.border_color = UiTokens.ENCRE
	recit.set_border_width_all(3)
	recit.content_margin_left = 18
	recit.content_margin_right = 18
	recit.content_margin_top = 6
	recit.content_margin_bottom = 6
	titre_ecran.add_theme_stylebox_override("normal", recit)
	titre_ecran.add_theme_font_override("font", UiTokens.police_corps(800))
	titre_ecran.add_theme_font_size_override("font_size", 24)
	titre_ecran.add_theme_color_override("font_color", UiTokens.ENCRE)
	titre_ecran.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titre_ecran.visible = false
	add_child(titre_ecran)
	etapes = _scenario()
	_vitesse(0.0)
	_centrer(game.map.camp.get_center() + Vector2i(0, -5))
	_etape_suivante()


func _construire_bulle() -> void:
	portrait_cadre = Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = UiTokens.ENTETE
	ps.border_color = UiTokens.ENCRE
	ps.set_border_width_all(4)
	ps.set_corner_radius_all(66)
	portrait_cadre.add_theme_stylebox_override("panel", ps)
	portrait_cadre.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	portrait_cadre.custom_minimum_size = Vector2(132, 132)
	portrait_cadre.size = Vector2(132, 132)
	add_child(portrait_cadre)
	portrait_image = TextureRect.new()
	portrait_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_image.stretch_mode = TextureRect.STRETCH_SCALE
	portrait_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	portrait_cadre.add_child(portrait_image)

	bulle = PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color.WHITE
	bs.border_color = UiTokens.ENCRE
	bs.set_border_width_all(3)
	bs.set_corner_radius_all(26)
	bs.content_margin_left = 24
	bs.content_margin_right = 24
	bs.content_margin_top = 14
	bs.content_margin_bottom = 12
	bs.shadow_color = Color(0.08, 0.12, 0.17, 0.35)
	bs.shadow_size = 2
	bs.shadow_offset = Vector2(5, 6)
	bulle.add_theme_stylebox_override("panel", bs)
	add_child(bulle)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	bulle.add_child(v)
	nom_label = Label.new()
	nom_label.add_theme_font_override("font", UiTokens.police_corps(800))
	nom_label.add_theme_font_size_override("font_size", 14)
	nom_label.add_theme_color_override("font_color", UiTokens.SARCELLE)
	v.add_child(nom_label)
	texte = RichTextLabel.new()
	texte.bbcode_enabled = true
	texte.fit_content = true
	texte.scroll_active = false
	texte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texte.add_theme_font_override("normal_font", UiTokens.police_corps(500))
	texte.add_theme_font_override("bold_font", UiTokens.police_corps(800))
	texte.add_theme_font_size_override("normal_font_size", 19)
	texte.add_theme_font_size_override("bold_font_size", 19)
	texte.add_theme_color_override("default_color", UiTokens.ENCRE)
	v.add_child(texte)
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 10)
	bas.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(bas)
	consigne = Label.new()
	consigne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	consigne.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	consigne.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consigne.add_theme_font_override("font", UiTokens.police_corps(700))
	consigne.add_theme_font_size_override("font_size", 15)
	consigne.add_theme_color_override("font_color", UiTokens.ORANGE)
	bas.add_child(consigne)
	suivant = Button.new()
	suivant.focus_mode = Control.FOCUS_NONE
	_styler(suivant, UiTokens.BOUTON_BAS, UiTokens.BOUTON_HAUT, 18.0, 36.0)
	suivant.add_theme_font_override("font", UiTokens.police_corps(800))
	suivant.add_theme_font_size_override("font_size", 17)
	suivant.custom_minimum_size.y = 38
	suivant.pressed.connect(_clic_suivant)
	bas.add_child(suivant)
	var fleche := Fleche.new()
	fleche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fleche.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	fleche.position = Vector2(-24, -7)
	suivant.add_child(fleche)
	# Quitter : à la place du bouton Menu de la barre du haut (au-dessus du voile, toujours cliquable)
	quitter = Button.new()
	quitter.text = "Quitter le tutoriel"
	quitter.focus_mode = Control.FOCUS_NONE
	_styler(quitter, Color.WHITE, Color("FFF4D6"), 14.0, 14.0)
	quitter.add_theme_font_override("font", UiTokens.police_corps(700))
	quitter.add_theme_font_size_override("font_size", 14)
	quitter.pressed.connect(func(): m._restart("menu"))
	add_child(quitter)
	m.menu_btn.custom_minimum_size.x = 160
	m.menu_btn.modulate.a = 0.0
	m.menu_btn.disabled = true
	queue = Queue.new()
	queue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bulle.add_child(queue)


## Bouton de BD : aplat franc, trait d'encre et ombre d'encre décalée, qui s'enfonce au clic.
func _styler(b: Button, fond: Color, survol: Color, gauche: float, droite: float) -> void:
	for etat in [["normal", fond, 3.0], ["hover", survol, 3.0], ["pressed", survol, 0.0], ["hover_pressed", survol, 0.0]]:
		var st := StyleBoxFlat.new()
		st.bg_color = etat[1]
		st.border_color = UiTokens.ENCRE
		st.set_border_width_all(3)
		st.set_corner_radius_all(19)
		st.content_margin_left = gauche
		st.content_margin_right = droite
		st.content_margin_top = 5
		st.content_margin_bottom = 5
		st.shadow_color = UiTokens.ENCRE
		st.shadow_size = 0
		st.shadow_offset = Vector2(0, etat[2])
		b.add_theme_stylebox_override(etat[0], st)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, UiTokens.ENCRE)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and suivant.visible and bulle.visible \
		and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		_clic_suivant()


# --- Déroulement ---------------------------------------------------------------------------------------------

func _clic_suivant() -> void:
	if texte.visible_ratio < 1.0:
		texte.visible_ratio = 1.0
		return
	if etape.has("fin"):
		m._restart("menu")
		return
	_etape_suivante()


func _etape_suivante() -> void:
	i += 1
	if i >= etapes.size():
		return
	etape = etapes[i]
	horloge = 0.0
	for t in m.toast_box.get_children():
		t.queue_free()
	attente_auto = 0
	if etape.has("entree"):
		etape["entree"].call()
	var t: Variant = etape.get("texte", "")
	var phrase: String = t.call() if t is Callable else t
	bulle.visible = phrase != ""
	portrait_cadre.visible = phrase != ""
	titre_ecran.text = str(etape.get("legende", ""))
	titre_ecran.visible = titre_ecran.text != ""
	_montrer_logos(etape.get("logos", []))
	if phrase != "":
		_montrer_bulle(phrase)
	var action: bool = etape.has("attendre")
	voile.bloque = not etape.get("libre", false)
	voile.sombre = etape.get("voile", etape.has("cible"))
	voile.passe = action or etape.get("survol", false)
	suivant.visible = not action or etape.has("fin")
	suivant.text = "Terminer" if etape.has("fin") else "Suivant"
	consigne.text = str(etape.get("consigne", "")) if action else ""
	consigne.visible = consigne.text != ""


## Les logos annoncés par une réplique, au centre de la carte.
func _montrer_logos(noms: Array) -> void:
	if logos_box:
		logos_box.queue_free()
		logos_box = null
	if noms.is_empty():
		return
	logos_box = HBoxContainer.new()
	logos_box.add_theme_constant_override("separation", 24)
	logos_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var taille := Vector2(460, 306) if noms.size() == 1 else Vector2(300, 200)
	for n in noms:
		var logo := Composants.image_logo(load("res://assets/bd/logos/%s.png" % n), taille)
		if noms.size() == 1:
			logos_box.add_child(logo)
			continue
		# Les logos des rivaux s'effacent sur la carte assombrie : on les pose sur une carte de visite
		var carte := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color.WHITE
		st.border_color = UiTokens.ENCRE
		st.set_border_width_all(3)
		st.set_corner_radius_all(14)
		carte.add_theme_stylebox_override("panel", st)
		carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		carte.add_child(logo)
		logos_box.add_child(carte)
	add_child(logos_box)
	logos_box.position = Vector2((get_viewport_rect().size.x - (taille.x * noms.size() + 24.0 * (noms.size() - 1))) / 2.0, 90.0 if noms.size() == 1 else 120.0)


func _montrer_bulle(phrase: String) -> void:
	var qui: String = etape.get("qui", "cadre")
	var a_droite := qui != "cadre"
	if qui == "cadre":
		nom_label.text = "%s · %s" % [CADRE["nom"], CADRE["titre"]]
		_cadrer_portrait(load("res://assets/bd/hubert/%s.png" % etape.get("tete", "neutre")))
	else:
		var c: GameState.Card = _carte_de(qui)
		nom_label.text = "%s · %s" % [c.nom, game.job_name(c)]
		_cadrer_portrait(Composants.texture_portrait(c.perso))
	queue.a_droite = a_droite
	queue.queue_redraw()
	texte.text = phrase
	texte.visible_ratio = 1.0 if auto else 0.0
	var vue := get_viewport_rect().size
	var large := 800.0
	bulle.custom_minimum_size = Vector2(large, 0)
	# Entre le panneau Construire et le panneau du zoo, le portrait compris
	var x := 330.0 if a_droite else (vue.x - large) / 2.0 + 60.0
	bulle.position.x = x
	portrait_cadre.position.x = x + large + 28.0 if a_droite else x - 160.0


## Place le portrait dans le disque, la tête au centre : les visages ne sont pas au milieu de leur image.
func _cadrer_portrait(tex: Texture2D) -> void:
	portrait_image.texture = tex
	var img := tex.get_image()
	var haut := img.get_height()
	var somme := 0.0
	var n := 0.0
	var sommet := -1
	for y in int(haut * 0.55):  # le haut de l'image : la tête, sans les épaules
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				somme += x
				n += 1.0
				if sommet < 0:
					sommet = y
	var echelle := (172.0 if etape.get("qui", "cadre") == "cadre" else 150.0) / haut
	portrait_image.size = Vector2(img.get_width(), haut) * echelle
	portrait_image.position = Vector2(66.0 - somme / maxf(n, 1.0) * echelle, 8.0 - maxi(sommet, 0) * echelle)


func _carte_de(metier: String) -> GameState.Card:
	for c in game.hand + game.deck + game.discard:
		if c.metier["id"] == metier:
			return c
	for w in game.workers:
		if w.card.metier["id"] == metier:
			return w.card
	return game.all_employees()[0]


func _process(delta: float) -> void:
	horloge += delta
	voile.pouls += delta
	if horloge < 0.3:  # messages nés du changement d'étape (nuit, événement) : le cadre parle, pas les messages
		for t in m.toast_box.get_children():
			t.queue_free()
	if texte.visible_ratio < 1.0:
		var n := float(texte.get_total_character_count())
		texte.visible_ratio = minf(1.0, texte.visible_ratio + delta * 60.0 / maxf(1.0, n))
	if bulle.visible:
		var vue := get_viewport_rect().size
		bulle.size.y = 0.0  # la bulle reprend la hauteur de son texte
		# En bas, la bulle s'arrête au-dessus de la main : les cartes restent visibles.
		var bas: float = m.hand_box.get_global_rect().position.y - 12.0 if m.hand_box.is_visible_in_tree() else vue.y - 22.0
		var y: float = 78.0 if etape.get("position", "bas") == "haut" else bas - bulle.size.y
		bulle.position.y = y
		portrait_cadre.position.y = y + maxf(0.0, bulle.size.y - 132.0) / 2.0
	if mt.phase == "day":
		quitter.position = m.menu_btn.global_position
		quitter.size = m.menu_btn.size
	else:  # la nuit, plus de barre du haut
		quitter.size = Vector2(160, 46)
		quitter.position = get_viewport_rect().size - quitter.size - Vector2(18, 18)
	voile.trous.clear()
	if etape.has("cible"):
		for c in etape["cible"].call():
			if is_instance_valid(c) and c.is_visible_in_tree():
				voile.trous.append(c.get_global_rect().grow(4.0))
	voile.queue_redraw()
	m.queue_redraw()
	if etape.has("attendre"):
		if etape["attendre"].call():
			_etape_suivante()
			return
		if auto:
			_jouer_seul()
	elif auto and bulle.visible:
		_jouer_seul()


## Mode de contrôle : capture l'étape, résout l'action demandée et passe à la suite.
func _jouer_seul() -> void:
	attente_auto += 1
	if attente_auto == 8 and dossier != "":
		var img := get_viewport().get_texture().get_image()
		img.save_png(dossier.path_join("etape_%02d.png" % i))
	if attente_auto == 10:
		if etape.has("auto"):
			etape["auto"].call()
		elif not etape.has("attendre"):
			if etape.has("fin"):
				print("Tutoriel joué jusqu'au bout : jour %d, réputation %.1f, animaux %d, attractivité %d, zoo ouvert %s" % [mt.day, game.rep_points, game.animals.size(), game.attractiveness(), game.zoo_status()["open"]])
				m.get_tree().quit(0)
				return
			_etape_suivante()


## main.gd : la pose à cette case est-elle celle que demande l'étape ? Hors étape de pose : refus.
func pose_permise(kind: String, def: Dictionary, origine: Vector2i, t: Vector2i) -> bool:
	var pose: Dictionary = etape.get("pose", {})
	var id: String = def.get("id", "")
	if not pose.has(id):
		return false
	var cases: Array = pose[id]
	return cases.has(origine) or (kind == "animal" and cases.has(t))


func fin_de_journee_permise() -> bool:
	return etape.get("fin_jour", false)


## Appelé à la fin du _draw de main.gd : cases à viser, en coordonnées du monde.
func dessiner_monde(canvas: CanvasItem, tuile: float) -> void:
	if not etape.has("monde"):
		return
	var a := 0.35 + 0.2 * sin(voile.pouls * 5.0)
	for t in etape["monde"].call():
		var r := Rect2(Vector2(t) * tuile, Vector2(tuile, tuile))
		canvas.draw_rect(r, Color(UiTokens.SELECTION, a))
		canvas.draw_rect(r, UiTokens.ENCRE, false, 1.5)
	# Bâtiment montré tel qu'il sera une fois construit
	if etape.has("fantome"):
		var tex := SpritesBD.texture(SpritesBD.BATIMENTS[etape["fantome"]])
		var taille: Array = game.building_def(etape["fantome"])["taille"]
		var cote := Vector2(int(taille[0]), int(taille[1])) * tuile
		var pied := (Vector2(_filon()) + Vector2(0.5, 0.5)) * tuile
		canvas.draw_texture_rect(tex, Rect2(pied - Vector2(cote.x * 0.75, cote.y * 1.1), Vector2(cote.x * 1.5, cote.y * 1.5)), false)


# --- Outils du scénario -----------------------------------------------------------------------------------------

func _vitesse(s: float) -> void:
	m.speed = s
	for k in m.speed_buttons:
		m.speed_buttons[k].button_pressed = (k == s)


func _centrer(t: Vector2i) -> void:
	var tuile: float = m.TILE
	m.camera.zoom = Vector2(1.6, 1.6)
	m.camera.position = (Vector2(t) + Vector2(0.5, 0.5)) * tuile + Vector2(0, 60.0 / m.camera.zoom.y)


func _onglet(nom: String) -> void:
	m.ouvrir_outil("construire")  # interface Comité : le panneau Construire est un volet de la colonne d'outils
	m.build_tabs[nom].button_pressed = true
	m.build_tabs[nom].pressed.emit()


## Bouton d'un bâtiment dans le panneau Construire, amené à l'écran.
func _bouton(id: String) -> Control:
	for e in m.build_buttons:
		if e[2].get("id", "") == id:
			var c: Control = e[0]
			var sc := c.get_parent().get_parent() as ScrollContainer
			if sc and c.is_visible_in_tree():
				sc.ensure_control_visible(c)
			return c
	return null


func _bourse() -> Control:
	m.ouvrir_outil("bourse")
	var c: Node = m.trade_card
	while c and not c is ScrollContainer:
		c = c.get_parent()
	if c:
		c.ensure_control_visible(m.trade_card)
	return m.trade_card


func _ouvrier(metier: String) -> GameState.Worker:
	for w in game.workers:
		if w.card.metier["id"] == metier:
			return w
	return null


func _deployer_tout() -> void:
	for c in game.hand.duplicate():
		if not c.is_action():
			game.deploy(c)


func _nuit_blanche() -> void:
	# Le temps passe sans incident : ni maladie, ni événement pour troubler la démonstration.
	m.selected.clear()
	m.selected_site = null
	m._set_build({})
	for c in game.all_employees():
		c.xp = 0.0
	if mt.phase == "day":
		mt.end_day()
	mt.finish_night()
	mt.start_next_day()
	for a in game.animals:
		a.sick = false
		a.food = maxf(a.food, 2.0)
		a.starved = false
		a.fed = true
	mt.current_event = {}
	game.version += 1
	_vitesse(0.0)


func _sites_finis() -> void:
	for s in game.sites.duplicate():
		if not s.done:
			s.work = s.travail()
			game._complete(s)


func _poser(def_id: String, t: Vector2i) -> void:
	if game.site_at(t) == null:
		game.place("batiment", game.building_def(def_id), t)


func _mur() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(parc.position.x, parc.end.x):
		out.append(Vector2i(x, parc.position.y))
		out.append(Vector2i(x, parc.end.y - 1))
	for y in range(parc.position.y + 1, parc.end.y - 1):
		out.append(Vector2i(parc.position.x, y))
		out.append(Vector2i(parc.end.x - 1, y))
	return out.filter(func(t): return t != entree and t != entree + Vector2i(1, 0))


func _route() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(entree.y + 1, game.map.camp.position.y):
		out.append(Vector2i(entree.x, y))
	return out


## Mode de contrôle : pose par le même chemin que la souris, refusée hors de la zone demandée.
func _comme_joueur(kind: String, def: Dictionary, cases: Array) -> void:
	m._set_build({"kind": kind, "def": def})
	m._try_place(Vector2i(0, 0), true)
	assert(game.site_at(Vector2i(0, 0)) == null)
	for t in cases:
		m._try_place(t, true)
		if m.build_choice.is_empty() and t != cases[-1]:
			m._set_build({"kind": kind, "def": def})
	m._set_build({})


func _manquantes(cases: Array) -> Array:
	return cases.filter(func(t): return game.site_at(t) == null)


func _dit(qui: String, phrase: Variant, opts := {}) -> Dictionary:
	var e := {"qui": qui, "texte": phrase}
	e.merge(opts)
	return e


func _demande(phrase: Variant, fait: Callable, resoudre: Callable, opts := {}) -> Dictionary:
	var e := {"qui": "cadre", "texte": phrase, "attendre": fait, "auto": resoudre, "libre": true}
	e.merge(opts)
	return e


func _batiments(ids: Array) -> Callable:
	return func(): return ids.map(func(id): return _bouton(id))


func _jeton(res: String) -> Callable:
	return func(): return [m.res_chips[res]["racine"]]


func _a_recolter(res: String) -> bool:
	return game.workers.any(func(w): return w.task.get("res", "") == res)


# --- Le scénario ---------------------------------------------------------------------------------------------

func _scenario() -> Array:
	var bucheron := func(): return "%s (%s)" % [_carte_de("bucheron").nom, game.job_name(_carte_de("bucheron"))]
	var terrassier := func(): return "%s (%s)" % [_carte_de("terrassier").nom, game.job_name(_carte_de("terrassier"))]
	var paysagiste := func(): return "%s (%s)" % [_carte_de("paysagiste").nom, game.job_name(_carte_de("paysagiste"))]
	var guichetier := func(): return "%s (%s)" % [_carte_de("guichetier").nom, game.job_name(_carte_de("guichetier"))]
	var nom_animal: String = espece["nom"]
	var s := [
		# --- Présentation ---
		_dit("cadre", "Bienvenue chez [b]ZooLife™[/b], leader mondial du divertissement animalier responsable ! Vous entrez dans une grande famille. Une famille avec des objectifs trimestriels.", {"logos": ["zoolife"], "entree": func():
			_deployer_tout()
			game.money = 8.0}),
		_dit("cadre", "Notre mission : bâtir ici un parc animalier. Trois mégacorporations rivales font la même chose au même moment. La [b]première à 120 de réputation[/b] rafle la concession. Les autres licencient.", {"logos": ["panzoo", "safari", "bioland"], "cible": func(): return m.race_labels.map(func(r): return r[0]), "position": "bas"}),
		_dit("terrassier", "Excusez-moi… on a signé pour travailler dans un parc animalier. Il est où, le parc ?"),
		_dit("cadre", "Article 47, alinéa 12 de votre contrat : « Le salarié construit l'établissement qui l'emploie. » C'était écrit. En petit, certes, mais c'était écrit."),
		_dit("bucheron", "Et les machines ? Les camions ? Le matériel ?"),
		_dit("cadre", "Avec la hausse du prix de l'énergie, les machines ne sont plus au budget. Vous extrairez donc les ressources [b]vous-mêmes[/b], à la main. C'est bien plus respectueux de la planète : notre rapport RSE y consacre deux pages."),
		# --- Ressources ---
		_dit("cadre", "Le [b]bois[/b], d'abord. Il se coupe dans les forêts. Il sert aux bâtiments et aux clôtures des enclos.", {"cible": _jeton("bois")}),
		_dit("cadre", "La [b]pierre[/b] se casse dans les rochers. Murs d'enceinte, routes, bâtiments : on en manque toujours, et vos dos aussi.", {"cible": _jeton("pierre")}),
		_dit("cadre", "L'[b]or[/b] est facultatif : on peut gagner sans. Mais il se vend très bien et peut accélérer votre développement. Il s'extrait d'un filon, une fois la [b]Mine d'or[/b] construite dessus.", {"entree": func(): _onglet("Bâtiments"), "cible": _batiments(["mine"]), "position": "bas"}),
		_dit("cadre", "Tenez, là-bas : ce scintillement jaune, c'est un filon. Voilà ce que donne une Mine d'or une fois bâtie dessus. Comptez un bon moment de chantier, et de la marche : le chemin du camp n'est pas au budget.", {"entree": func(): _centrer(_filon()), "monde": _cases_filon, "fantome": "mine", "position": "haut"}),
		_dit("cadre", "Si vos récoltes sont loin du camp, l'[b]Entrepôt[/b] sert de dépôt rapproché : moins de marche, plus de rendement. Je chronomètre.", {"entree": func(): _centrer(game.map.camp.get_center() + Vector2i(0, -5)), "cible": _batiments(["entrepot"])}),
		_dit("cadre", "Le [b]Marché[/b], enfin, vous fait vendre vos ressources à meilleur prix. Avec un Marchand mobilisé, encore mieux : ZooLife adore les intermédiaires.", {"cible": _batiments(["comptoir"])}),
		# --- Première récolte ---
		_demande(func(): return "Assez parlé. Au travail ! Vos quatre collaborateurs attendent au camp. Cliquez sur %s, sur sa carte ou sur la carte du monde, puis faites un [b]clic droit sur un arbre[/b]." % bucheron.call(),
			_a_recolter.bind("bois"), func(): game.order([_ouvrier("bucheron")], _proche("bois")),
			{"qui": "cadre", "position": "haut", "consigne": "Clic droit sur la forêt en surbrillance", "monde": func(): return _cases_de(GameMap.FORET)}),
		_demande(func(): return "Parfait. Vous êtes presque rentable. Maintenant %s : clic droit sur un [b]rocher[/b]. Le dernier arrivé paie sa pause." % terrassier.call(),
			_a_recolter.bind("pierre"), func(): game.order([_ouvrier("terrassier")], _proche("pierre")),
			{"position": "haut", "consigne": "Clic droit sur les rochers en surbrillance", "monde": func(): return _cases_de(GameMap.ROCHE)}),
		_dit("cadre", "Les deux autres suivront. Maintenant, accélérons : à ZooLife, une journée de travail se résume très bien en quelques secondes de rapport d'activité.", {"entree": func():
			game.order([_ouvrier("manoeuvre")], _proche("pierre"))
			game.order([_ouvrier("paysagiste")], _proche("bois"))}),
		{"legende": "▸▸ Fin de journée", "attendre": func(): return mt.time >= mt.day_length - 5.0, "entree": func(): _vitesse(40.0)},
		# --- Vente ---
		_dit("cadre", "Fin de journée. Regardez votre trésorerie : [b]8[/b]. Demain matin, il faudra payer la mobilisation des collaborateurs. Si vous n'avez pas de quoi, ils restent au lit, et moi je n'aime pas ça.", {"entree": func():
			_vitesse(0.0)
			for w in game.workers:
				game._unload(w)
			game.stock["bois"] = maxf(game.stock["bois"], 40.0)
			game.stock["pierre"] = maxf(game.stock["pierre"], 40.0)
			game.version += 1, "cible": _jeton("argent")}),
		_demande("Vendez donc une partie de votre surplus à la [b]Bourse des ressources[/b], à droite, jusqu'à avoir [b]%d d'argent[/b]. Choisissez la quantité, cliquez sur Vendre. Sans Marchand, le taux est mauvais. C'est le marché." % ARGENT_VISE,
			func(): return game.money >= ARGENT_VISE, func():
				while game.money < ARGENT_VISE and game.sell_amount("bois", 5):
					pass,
			{"entree": func(): m.selected.clear(), "cible": func(): return [_bourse(), m.res_chips["argent"]["racine"]], "libre": false, "consigne": "Atteignez %d d'argent" % ARGENT_VISE, "position": "bas", "voile": true}),
		_demande("Voilà. Vous pouvez rentrer. Terminez la journée.",
			func(): return mt.phase == "night", func(): mt.end_day(),
			{"cible": func(): return [m.end_day_btn], "libre": false, "fin_jour": true, "position": "haut", "consigne": "Cliquez sur Terminer la journée"}),
		# --- Soir ---
		_dit("cadre", "Le soir, on fait ses courses : le [b]marché du soir[/b] propose des contrats d'animaux, puis des collaborateurs à recruter. Chacun achète à son tour, dans l'ordre d'influence. Nous y reviendrons.", {"entree": _ouvrir_contrats, "voile": true}),
		_dit("cadre", func(): return "Voici notre premier pensionnaire, le [b]%s[/b] : commun, pas cher, et qui ne se plaint jamais. Chaque animal exige un [b]motif de terrain[/b] : ici, quatre cases de prairie et une de forêt, disposées exactement ainsi. Vous pouvez le tourner ou le retourner, mais pas négocier." % nom_animal,
			{"cible": func(): return [m.night_pages["contrats"]], "position": "haut"}),
		_demande(func(): return "Achetez ce contrat. Je le déduirai de votre trésorerie, pas de mon bonus.",
			func(): return game.contracts.has(espece), func(): game.buy_contract(espece),
			{"cible": func(): return [m.night_pages["contrats"]], "libre": false, "position": "haut", "consigne": "Achetez le contrat"}),
		_dit("cadre", "Ensuite vient le [b]recrutement[/b]. Chaque soir, vous pouvez embaucher un collaborateur, s'il vous reste un logement au camp ou dans une Maison. Plus de cartes, plus de bras, plus de salaires. Ce soir, nous allons passer : les caisses sont vides.", {"entree": func():
			mt.night_goto("ouvriers", 0)
			game.version += 1, "cible": func(): return [m.night_pages["ouvriers"]], "position": "haut"}),
		# --- Lendemain ---
		_dit("cadre", "Bonjour ! Vous avez [b]4 collaborateurs en main[/b], à mobiliser pour la journée. Chaque mobilisation coûte son salaire, indiqué sur la carte.", {"entree": func():
			_nuit_blanche()
			_forcer_main(game, EQUIPE.slice(0, 4)), "cible": func(): return [m.hand_box], "position": "haut"}),
		_dit("manoeuvre", "Payés le matin même ? Avant, c'était à la fin du mois.", {"cible": func(): return [m.hand_box], "position": "haut"}),
		_dit("cadre", "Après diverses mésaventures antérieures : le parc de Dubaï, la grève de l'enclos à otaries, les bons d'achat à la boutique… Les collaborateurs exigent désormais d'être payés le matin. Quelle époque.", {"cible": func(): return [m.hand_box], "position": "haut"}),
		_dit("cadre", "Regardez vos cartes. Chaque collaborateur a une [b]spécialité[/b], son métier, qui le rend meilleur à certaines tâches. Et souvent des [b]qualités[/b] (rond bleu) et des [b]défauts[/b] (carré orange). Survolez une carte pour tout lire. Choisissez bien : un défaut, ça se paie aussi.", {"cible": func(): return [m.hand_box], "position": "haut", "survol": true}),
		_dit("terrassier", "Et vous, monsieur de la Marge, c'est quoi vos qualités et vos défauts ?", {"cible": func(): return [m.hand_box], "position": "haut"}),
		_dit("cadre", "Ma qualité ? Ma capacité d'écoute. Mon défaut ? Le perfectionnisme. Sujet suivant.", {"cible": func(): return [m.hand_box], "position": "haut"}),
		_demande("Mobilisez vos quatre collaborateurs, carte par carte ou avec le bouton [b]Tout mobiliser[/b].",
			func(): return game.hand.all(func(c): return c.deployed), _deployer_tout,
			{"cible": func(): return [m.hand_box, m.deploy_all_btn], "libre": false, "position": "haut", "consigne": "Mobilisez les 4 collaborateurs"}),
		_dit("cadre", "Quatre, c'est peu ? C'est la capacité du camp. Améliorez-le pour piocher [b]une carte de plus chaque matin[/b] : [b]Camp niveau 2[/b], puis [b]Camp niveau 3[/b]. Certains en font leur priorité absolue. Moi, je préfère le ratio bras / salaire.", {"entree": func(): _onglet("Bâtiments"), "cible": _batiments(["camp_n2", "camp_n3"]), "position": "bas"}),
		# --- Quelques jours plus tard ---
		_dit("cadre", "Sautons quelques jours de récolte et quelques doléances syndicales.", {"entree": func(): pass}),
		{"legende": "▸▸ Quelques jours plus tard…", "attendre": func(): return horloge > 1.2, "entree": _quelques_jours},
		_dit("cadre", "[b]100 de bois, 100 de pierre[/b] ! Vous avez enfin de quoi construire votre lieu de travail. On commence par l'[b]Entrée du zoo[/b] : onglet Zoo du panneau Construire, puis un clic sur l'emplacement.", {"cible": func(): return [m.res_chips["bois"]["racine"], m.res_chips["pierre"]["racine"]]}),
		_demande("Posez l'Entrée à l'emplacement jaune (touche R pour la tourner, si un jour le terrain l'exige).",
			func(): return game.site_at(entree) != null, func(): _comme_joueur("batiment", game.building_def("entree"), [entree]),
			{"entree": func(): _onglet("Zoo"), "cible": _batiments(["entree"]), "voile": false, "pose": {"entree": [entree]}, "position": "haut", "consigne": "Entrée du zoo, puis clic sur la case jaune de gauche", "monde": func(): return _manquantes([entree, entree + Vector2i(1, 0)])}),
		_demande("Maintenant l'[b]Enceinte[/b]. Choisissez-la et peignez le tracé en maintenant le clic. Il faut une enceinte fermée. Astuce budgétaire : une montagne sert de mur gratuit, et un mur peut se bâtir sur l'eau.",
			func(): return _manquantes(_mur()).is_empty(), func(): _comme_joueur("batiment", game.building_def("cloture"), _mur()),
			{"cible": _batiments(["cloture"]), "voile": false, "pose": {"cloture": _mur()}, "position": "haut", "consigne": "Enceinte (segment) : peignez toute la zone jaune", "monde": func(): return _manquantes(_mur())}),
		_dit("cadre", "Vos collaborateurs construisent les chantiers qu'on leur désigne d'un clic droit. Il reste la [b]route[/b] : sans route depuis l'Accès jusqu'à l'entrée, aucun visiteur. Celle-ci, je l'ai sous-traitée. C'est retenu sur vos salaires.", {"entree": _finir_enceinte}),
		_demande(func(): return "Au tour de l'[b]enclos[/b] du %s : des [b]Clôtures d'enclos[/b], appuyées sur le mur quand c'est possible. Ça économise du bois. Peignez la zone jaune." % nom_animal,
			func(): return _manquantes(clotures).is_empty(), func(): _comme_joueur("batiment", game.building_def("enclos"), clotures),
			{"cible": _batiments(["enclos"]), "voile": false, "pose": {"enclos": clotures}, "position": "haut", "consigne": "Clôture d'enclos : peignez la zone jaune", "monde": func(): return _manquantes(clotures)}),
		_demande(func(): return "Le motif demande une case de forêt, et il n'y a que de la prairie. Heureusement, votre équipe compte un Paysagiste. Onglet [b]Terrain[/b], [b]Planter une forêt[/b], puis clic sur la case jaune." ,
			func(): return game.site_at(case_foret) != null, func(): _comme_joueur("amenagement", _amenagement("planter"), [case_foret]),
			{"entree": func(): _onglet("Terrain"), "cible": _batiments(["planter"]), "voile": false, "pose": {"planter": [case_foret]}, "position": "haut", "consigne": "Planter une forêt, puis clic sur la case jaune", "monde": func(): return _manquantes([case_foret])}),
		_demande(func(): return "Seuls les Paysagistes et les Terrassiers aménagent le terrain. Sélectionnez %s et faites un clic droit sur le chantier." % paysagiste.call(),
			func(): return _ouvrier("paysagiste").task.get("site") == game.site_at(case_foret) and game.site_at(case_foret) != null, func(): game.order([_ouvrier("paysagiste")], case_foret),
			{"position": "haut", "consigne": "Clic droit sur le chantier avec le Paysagiste", "monde": func(): return [case_foret]}),
		{"legende": "▸▸ Plantation…", "attendre": func(): return game.map.get_t(case_foret.x, case_foret.y) == GameMap.FORET or horloge > 12.0, "entree": func(): _vitesse(20.0)},
		_demande(func(): return "Excellent. Les clôtures sont finies aussi, j'ai fait faire des heures supplémentaires. Choisissez le contrat du %s à gauche, puis cliquez dans l'enclos." % nom_animal,
			func(): return game.animals.any(func(a): return a.def == espece), func(): _comme_joueur("animal", espece, [interieur[0]]),
			{"entree": _finir_enclos, "cible": func(): return [m.contracts_box], "voile": false, "pose": {ESPECE: interieur}, "position": "haut", "consigne": "Contrat à gauche, puis clic dans l'enclos", "monde": func(): return interieur}),
		_dit("cadre", "L'animal arrive cette nuit. Avec lui, le zoo pourra ouvrir : enceinte fermée, route, un animal. Il manquera quelqu'un pour vendre les billets.", {"entree": func(): _vitesse(0.0)}),
		{"legende": "▸▸ La nuit passe…", "attendre": func(): return horloge > 1.0, "entree": func():
			_nuit_blanche()
			game.stock["bois"] = maxf(game.stock["bois"], 40.0)
			_forcer_main(game, ["guichetier", "paysagiste", "manoeuvre", "animalier"])
			_deployer_tout()},
		_demande(func(): return "Bonjour ! Le %s est là. Sélectionnez %s et faites un clic droit sur l'[b]Entrée[/b] : sans personne au guichet, les visiteurs font la queue dehors." % [nom_animal, guichetier.call()],
			func(): return game.workers.any(func(w): return w.task.get("kind", "") == "ticket"), func(): game.order([_ouvrier("guichetier")], entree),
			{"position": "haut", "consigne": "Clic droit sur l'entrée avec le Guichetier", "monde": func(): return [entree, entree + Vector2i(1, 0)]}),
		{"legende": "▸▸ Première journée d'ouverture", "attendre": func(): return mt.phase == "night", "entree": func():
			rapport_jour = game.rep_points
			_vitesse(40.0)},
		_dit("cadre", func(): return "Regardez : [b]+%d de réputation[/b]. Chaque nuit, la réputation dépend du nombre moyen de visiteurs présents. Et les visiteurs viennent pour l'[b]attractivité[/b] de vos animaux : plus d'espèces, plus rares, plusieurs du même continent, et ça grimpe." % roundi(game.rep_points - rapport_jour), {"entree": func():
			_nuit_blanche()
			_forcer_main(game, ["guichetier", "paysagiste", "manoeuvre", "animalier"])
			_onglet("Zoo"), "cible": func(): return [m.res_chips["reputation"]["racine"]] + m.race_labels.map(func(r): return r[0])}),
		_dit("cadre", "Des animaux qui ne mangent pas tombent malades. La [b]Cuisine[/b] prépare leurs rations ; un Animalier les livre plus vite. Un Soigneur guérit ceux qui sont malades.", {"cible": _batiments(["cuisine"])}),
		_dit("cadre", "La [b]Boutique de souvenirs[/b], tenue par un collaborateur, vend à chaque visiteur un souvenir au prix de sa dignité. Argent et réputation.", {"cible": _batiments(["boutique"])}),
		_dit("cadre", "Le [b]Snack[/b] : les visiteurs restent plus longtemps. Un visiteur qui reste est un visiteur qui compte.", {"cible": _batiments(["snack"])}),
		_dit("cadre", "Le [b]Kiosque d'animation[/b] attire du monde et donne des spectacles, surtout si un Animateur le tient. Oui, un collaborateur qui chante, c'est au tarif normal.", {"cible": _batiments(["kiosque"])}),
		_dit("cadre", "Le [b]Local d'entretien[/b] : un parc sale fait fuir les visiteurs et rend les bêtes malades. Un Agent d'entretien y fait des miracles, pour un salaire qui n'en est pas un.", {"cible": _batiments(["entretien"])}),
		_dit("cadre", "Certaines espèces rares exigent un aménagement dans leur enclos : [b]Grand arbre, Rocher d'observation, Bassin profond, Abri chauffé[/b]. Le contrat vous l'indique. Lisez vos contrats. Je dis ça pour vous.", {"cible": _batiments(["grand_arbre", "rocher_obs", "bassin_profond", "abri_chaud"])}),
		_dit("cadre", "Les animaux ne font pas tout. Le Kiosque tenu et les souvenirs vendus rapportent de la réputation. Un collaborateur qui atteint le [b]niveau 6[/b] devient légendaire : +5. Il réclamera une augmentation : refusez.", {"cible": func(): return [m.res_chips["reputation"]["racine"]]}),
		_dit("cadre", "Les [b]labels[/b] s'achètent en or à la Bourse, zoo ouvert. Le double du prix sans Marchand mobilisé. Oui, la réputation s'achète. Vous pensiez quoi ?", {"cible": func(): return [_bourse()], "position": "bas"}),
		_dit("cadre", "Reste l'[b]influence[/b]. Envoyez un collaborateur à la [b]Mairie[/b], au bout de la route d'Accès : c'est le lobbying. L'influence décide de qui achète en premier le soir et de qui choisit le bonus du lendemain.", {"entree": func(): _centrer(game.map.exit_tile + Vector2i(0, -4)), "voile": false, "monde": func(): return [game.map.exit_tile], "position": "haut"}),
		_dit("cadre", "Et chaque nuit, le premier en influence gagne [b]+3 de réputation[/b], le deuxième +1. On appelle ça le prestige politique. Nous, on appelle ça un mardi.", {"monde": func(): return [game.map.exit_tile], "position": "haut"}),
		_dit("manoeuvre", "Et notre période d'essai, elle est validée ?", {"entree": func(): _centrer(parc.get_center())}),
		_dit("cadre", "Votre période d'essai vient de s'achever. Elle n'était pas rémunérée : article 12. Bienvenue à bord. Maintenant, un vrai parc vous attend, de vraies rivales et de vrais trimestres. [b]Le premier à 120 l'emporte[/b]. Le reste, c'est de la communication.", {"fin": true}),
	]
	for e in s:
		if e.get("texte") is String:
			for debut in TETES:
				if e["texte"].begins_with(debut):
					e["tete"] = TETES[debut]
	return s


## Filon le plus proche du camp, et ses cases.
func _filon() -> Vector2i:
	var c := game.map.camp.get_center()
	var best: Vector2i = game.map.golds[0]
	for g in game.map.golds:
		if (g - c).length_squared() < (best - c).length_squared():
			best = g
	return best


func _cases_filon() -> Array:
	var f := _filon()
	var out := []
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var t := f + Vector2i(dx, dy)
			if game.map.in_bounds(t.x, t.y) and game.map.get_t(t.x, t.y) == GameMap.MINE_OR:
				out.append(t)
	return out


func _proche(res: String) -> Vector2i:
	return m._nearest_resource(res, game.map.camp.get_center())


func _cases_de(terrain: int) -> Array:
	var k := game.map
	var c := k.camp
	var out := []
	for y in range(c.position.y, c.end.y):
		for dx in 5:
			var x: int = c.position.x - 3 - dx if terrain == GameMap.FORET else c.end.x + 2 + dx
			if k.in_bounds(x, y) and k.get_t(x, y) == terrain:
				out.append(Vector2i(x, y))
	return out


func _amenagement(id: String) -> Dictionary:
	for a in game.amenagement_defs():
		if a["id"] == id:
			return a
	return {}


## La nuit : le tour du joueur aux contrats, avec la seule espèce du tutoriel sur le marché.
func _ouvrir_contrats() -> void:
	mt.night_goto("contrats", 0)
	mt.market_contracts.assign([espece])
	game.version += 1


## Quelques jours passent : ressources réunies, équipe de chantier en main, regard sur le terrain du parc.
func _quelques_jours() -> void:
	for k in 3:
		_nuit_blanche()
	game.stock["bois"] = 100.0
	game.stock["pierre"] = 100.0
	game.money = maxf(game.money, 100.0)
	_forcer_main(game, ["paysagiste", "manoeuvre", "charpentier", "macon"])
	_deployer_tout()
	game.version += 1
	_centrer(parc.get_center())


func _finir_enceinte() -> void:
	for t in _mur():
		_poser("cloture", t)
	_poser("entree", entree)
	for t in _route():
		_poser("route", t)
	_sites_finis()


func _finir_enclos() -> void:
	_vitesse(0.0)
	m.selected.clear()
	var s := game.site_at(case_foret)
	if s and not s.done:
		s.work = s.travail()
		game._complete(s)
	_sites_finis()
	for w in game.workers:
		game.order([w], game.map.camp.get_center())
	game.version += 1
