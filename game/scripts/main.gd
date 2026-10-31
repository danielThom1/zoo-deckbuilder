extends Node2D
## Affichage, entrées et interface. Toute la logique de jeu est dans Match (la partie) et GameState (chaque joueur).
##
## Arguments (après « -- » sur la ligne de commande) :
##   --seed=123      carte fixe
##   --joueurs=4     nombre de joueurs (vous + des IA), 4 par défaut
##   --spectateur    4 IA jouent seules ; on regarde la carte de la première
##   --autodraft     l'IA fait aussi vos choix de draft
##   --autoplay      déploie la main et donne des ordres (forêt, roche, lobbying)
##   --sim=60        avance la simulation de N secondes au démarrage
##   --shot=img.png  enregistre une capture puis quitte
##   --marche        ouvre l'aperçu du marché du soir (captures)

const TILE := 16.0
const PX := 8  # pixels par case dans la texture du terrain

var terrain_colors := UiTokens.TERRAINS.duplicate()
var terrain_noms := {
	GameMap.PRAIRIE: "Prairie", GameMap.FORET: "Forêt", GameMap.EAU: "Eau", GameMap.ROCHE: "Roche",
	GameMap.SABLE: "Sable", GameMap.MONTAGNE: "Montagne", GameMap.MINE_OR: "Gisement d'or",
}
var category_colors := {"peu_qualifie": UiTokens.CATEGORIES["peu_qualifie"]["couleur"], "qualifie": UiTokens.CATEGORIES["qualifie"]["couleur"],
	"cadre": UiTokens.CATEGORIES["cadre"]["couleur"]}
var category_noms := {"peu_qualifie": "Peu qualifié", "qualifie": "Qualifié", "cadre": "Cadre"}
var res_noms := {"bois": "bois", "pierre": "pierre", "or": "or"}
var building_colors := {
	"route": UiTokens.CHEMIN, "pont": Color("9A6A3E"), "maison": Color("D2553A"), "entrepot": Color("8C6A48"),
	"mine": Color("5A4636"), "cloture": UiTokens.ENCEINTE, "entree": Color("E9D5A8"), "enclos": UiTokens.CLOTURE_ENCLOS,
	"boutique": Color("E06A5A"), "formation": Color("3A6AE0"), "cuisine": Color("D8A010"), "entretien": Color("7A8A88"),
	"snack": Color("E8782A"), "kiosque": Color("8A4AD0"), "camp_n2": Color("A0743C"), "camp_n3": Color("B8864A"),
}
var building_short := {
	"maison": "Maison", "entrepot": "Entrepôt", "mine": "Mine", "entree": "Entrée", "boutique": "Boutique", "formation": "Formation",
	"cuisine": "Cuisine", "entretien": "Entretien", "snack": "Snack", "kiosque": "Kiosque",
	"camp_n2": "Camp niv. 2", "camp_n3": "Camp niv. 3",
}

var mt: Match
var game: GameState  # le joueur affiché (vous, ou la première IA en mode spectateur)
var spectator := false
var view_buttons: Array = []
var night_clock := 0.0
var args := {}
var font: Font
var camera: Camera2D
var terrain_sprite: Sprite2D
var terrain_img: Image

var selected: Array = []
var selected_site: GameState.Site = null
var build_choice := {}  # {"kind": "batiment"|"amenagement", "def": {...}} pendant le placement
var painting := false
var last_paint := Vector2i(-99, -99)
var build_buttons := []  # [Button, kind, def]
var drag_start: Variant = null  # position écran du début de sélection
var drag_end := Vector2.ZERO
var drag_add := false
var panning := false
var speed := 1.0
var acc := 0.0
var info_clock := 0.0
var ai_timer := 0.0
var hand_version := -1
var toast_signature := ""
var night_shown_for := -1
var frame_count := 0

# Interface
var ui: Control
var lbl_day: Label
var lbl_timer: Label
var timebar: ProgressBar
var lbl_res: Label
var speed_buttons := {}
var info_text: RichTextLabel
var btn_lobby: Button
var btn_recall: Button
var btn_cancel_site: Button
var btn_demolish: Button
var sell_btn: Button
var hand_box: HBoxContainer
var toast_box: VBoxContainer
var status_label: Label
var night_root: Control
var night_title: Label
var night_text: RichTextLabel
var night_workers: HBoxContainer
var night_contracts: HBoxContainer
var night_fire_box: VBoxContainer
var night_bonus_box: HBoxContainer
var night_actions: HBoxContainer
var night_level_box: VBoxContainer
var night_level_rows: VBoxContainer
var night_action_box: VBoxContainer
var night_action_flow: HFlowContainer
var night_upgrade_box: HBoxContainer
var action_card: GameState.Card = null
var event_label: Label
var sell_gold_btn: Button
var night_fire: HFlowContainer
var night_next: Button
var contracts_box: VBoxContainer
var enc_cache_tile := Vector2i(-99, -99)
var enc_cache := {}
var biome_colors := {
	"Savane": Color("e0b34a"), "Foret": Color("4f9a4f"), "Jungle": Color("2fb37a"),
	"Aquatique": Color("4aa3e0"), "Montagne": Color("b7a6c9"), "Desert": Color("e08a4a"),
}
var biome_noms := {"Savane": "Savane", "Foret": "Forêt", "Jungle": "Jungle", "Aquatique": "Aquatique", "Montagne": "Montagne", "Desert": "Désert"}
var terrain_req_noms := {"Prairie": "Prairie", "Foret": "Forêt", "Eau": "Eau", "Roche": "Roche", "Sable": "Sable", "PrairieOuSable": "Prairie ou sable"}
var market_root: Control  # aperçu du marché du soir, consultable en journée
var market_box: VBoxContainer
var draft_root: Control
var draft_title: Label
var draft_order_lbl: RichTextLabel
var draft_grid: GridContainer
var draft_picks: RichTextLabel
# Interface Émeraude
var res_chips := {}  # clé -> [Label valeur, Label légende]
var race_labels: Array = []
var zoo_title: Label
var unit_name: Label
var unit_job: Label
var unit_text: RichTextLabel
var unit_portrait_box: Control
var unit_portrait_for: Variant = null
var pile_label: Label
var medallion: Control
var end_day_btn: Button
var build_pages := {}
var build_tabs := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	font = ThemeDB.fallback_font
	# Arguments de test : on démarre directement. Sinon, menu de lancement.
	if args.has("spectateur") or args.has("autodraft") or args.has("autoplay") or args.has("joueurs"):
		_start(args.has("spectateur"))
	else:
		_show_menu()


func _show_menu() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = UiTokens.PANNEAU_BAS
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.theme = UiTokens.build_theme()
	layer.add_child(bg)
	var v := VBoxContainer.new()
	v.position = Vector2(96, 96)
	v.add_theme_constant_override("separation", 14)
	bg.add_child(v)
	var title := Label.new()
	title.text = "ZOO\nDECKBUILDER"
	title.theme_type_variation = "TitreEcran"
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", UiTokens.OR)
	v.add_child(title)
	var tag := Label.new()
	tag.text = "Recrutez, construisez, attirez les visiteurs."
	tag.add_theme_color_override("font_color", UiTokens.TEXTE_SECONDAIRE)
	v.add_child(tag)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 60)
	v.add_child(gap)
	var seed_row := HBoxContainer.new()
	v.add_child(seed_row)
	var seed_lbl := Label.new()
	seed_lbl.text = "Graine de la carte (vide = au hasard) : "
	seed_row.add_child(seed_lbl)
	var seed_edit := LineEdit.new()
	seed_edit.custom_minimum_size = Vector2(160, 0)
	seed_row.add_child(seed_edit)
	var choices := [
		["Jouer contre l'IA", false, "Vous et 3 IA : draft par tours de 4 cartes puis partie complète.", true],
		["Regarder des IA jouer", true, "4 IA aux stratégies différentes, en accéléré (x8). Boutons « Voir » pour passer d'un zoo à l'autre.", false],
	]
	for c in choices:
		var b := Button.new()
		b.text = c[0]
		b.custom_minimum_size = Vector2(380, 52)
		b.add_theme_font_size_override("font_size", 18)
		if c[3]:
			b.theme_type_variation = "BoutonPrincipal"
		b.tooltip_text = c[2]
		b.pressed.connect(func():
			if seed_edit.text.strip_edges().is_valid_int():
				args["seed"] = seed_edit.text.strip_edges()
			layer.queue_free()
			_start(c[1]))
		v.add_child(b)
		var hint := Label.new()
		hint.text = c[2]
		hint.add_theme_color_override("font_color", UiTokens.TEXTE_SECONDAIRE)
		hint.add_theme_font_size_override("font_size", 13)
		v.add_child(hint)

## Stratégies des IA en mode spectateur (mêmes réglages que les simulations d'équilibrage).
const WATCH_STRATEGIES := [
	{"nom": "Petit parc", "taille_zoo": "petit"}, {"nom": "Grand parc", "taille_zoo": "grand"},
	{"nom": "Parc évolutif", "taille_zoo": "evolutif"}, {"nom": "Gros contrats", "preference_palier": 2.2, "reserve": 15},
]


func _start(watch: bool) -> void:
	spectator = watch
	var map_seed: int = int(args["seed"]) if args.has("seed") else randi() % 1000000000
	var nb := int(args.get("joueurs", "4"))
	mt = Match.new(GameData.load_all(), map_seed, nb, -1 if spectator else 0, WATCH_STRATEGIES if spectator else [])
	game = mt.players[0]
	_build_terrain()
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	camera.zoom = Vector2(1.6, 1.6)
	# Bas de la carte (camp et accès) calé juste au-dessus de la main, entre la barre du haut et la main.
	var vh := get_viewport_rect().size.y
	var visible_h := (vh - 48.0 - 210.0) / camera.zoom.y
	var visible_center_y := 48.0 + (vh - 48.0 - 210.0) / 2.0
	camera.position = Vector2((game.map.camp.get_center().x + 0.5) * TILE, game.map.h * TILE + 2.0 * TILE - visible_h / 2.0) \
		+ Vector2(0, vh / 2.0 - visible_center_y) / camera.zoom
	_build_ui()
	_set_speed(8.0 if spectator else 1.0)
	if args.has("autodraft") or spectator:
		while mt.phase == "draft":
			mt.pick_draft(mt.ai_choice())
	if args.has("autoplay"):
		_auto_play()
	if args.has("marche"):
		market_root.visible = true
		_rebuild_market_preview()
	_focus_zoo()
	# --jours=N (spectateur) : avance la partie de N jours avant d'afficher (captures).
	if spectator and args.has("jours"):
		while mt.day < int(args["jours"]) and not mt.game_over:
			if mt.phase == "day":
				mt.tick(0.5)
			else:
				mt.start_next_day()
		for i in 120:
			mt.tick(0.5)


# --- Terrain -----------------------------------------------------------------

func _build_terrain() -> void:
	var m := game.map
	terrain_img = Image.create_empty(m.w * PX, m.h * PX, false, Image.FORMAT_RGBA8)
	for y in m.h:
		for x in m.w:
			_paint_tile(x, y)
	terrain_sprite = Sprite2D.new()
	terrain_sprite.texture = ImageTexture.create_from_image(terrain_img)
	terrain_sprite.centered = false
	terrain_sprite.scale = Vector2.ONE * (TILE / PX)
	terrain_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	terrain_sprite.show_behind_parent = true
	add_child(terrain_sprite)


func _paint_tile(x: int, y: int) -> void:
	var img := terrain_img
	var m := game.map
	var t := m.get_t(x, y)
	var o := Vector2i(x * PX, y * PX)
	var base: Color = terrain_colors[t]
	if t == GameMap.PRAIRIE and (x * 7 + y * 13) % 5 == 0:
		base = UiTokens.PRAIRIE_VARIANTE
	img.fill_rect(Rect2i(o, Vector2i(PX, PX)), base)
	match t:
		GameMap.FORET:
			# Canopée en trois tons
			img.fill_rect(Rect2i(o + Vector2i(0, 1), Vector2i(4, 4)), UiTokens.CANOPEE[0])
			img.fill_rect(Rect2i(o + Vector2i(4, 3), Vector2i(4, 4)), UiTokens.CANOPEE[0])
			img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(2, 2)), UiTokens.CANOPEE[2])
			img.fill_rect(Rect2i(o + Vector2i(5, 3), Vector2i(2, 2)), UiTokens.CANOPEE[2])
		GameMap.ROCHE:
			img.fill_rect(Rect2i(o + Vector2i(1, 3), Vector2i(4, 3)), Color("8E8A80"))
			img.fill_rect(Rect2i(o + Vector2i(4, 1), Vector2i(3, 2)), Color("C8C2B4"))
		GameMap.MONTAGNE:
			for r in 6:
				img.fill_rect(Rect2i(o + Vector2i(3 - r / 2, 1 + r), Vector2i(2 + r, 1)), Color("6E604F"))
			img.fill_rect(Rect2i(o + Vector2i(3, 1), Vector2i(2, 1)), Color("F4F4F0"))  # neige
		GameMap.EAU:
			# Berge plus claire au bord de l'eau, vaguelettes au large
			for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				var q: Vector2i = Vector2i(x, y) + d
				if m.in_bounds(q.x, q.y) and m.get_t(q.x, q.y) != GameMap.EAU:
					var edge := Rect2i(o, Vector2i(PX, 1))
					if d.y == 1:
						edge = Rect2i(o + Vector2i(0, PX - 1), Vector2i(PX, 1))
					elif d.x == -1:
						edge = Rect2i(o, Vector2i(1, PX))
					elif d.x == 1:
						edge = Rect2i(o + Vector2i(PX - 1, 0), Vector2i(1, PX))
					img.fill_rect(edge, UiTokens.EAU_BERGE)
			if (x + 2 * y) % 5 == 0:
				img.fill_rect(Rect2i(o + Vector2i(2, 3), Vector2i(3, 1)), Color("6CC0F0"))
		GameMap.SABLE:
			if (x + y) % 2 == 0:
				img.fill_rect(Rect2i(o + Vector2i(2, 2), Vector2i(1, 1)), Color("D8B860"))
				img.fill_rect(Rect2i(o + Vector2i(5, 5), Vector2i(1, 1)), Color("D8B860"))
		GameMap.MINE_OR:
			img.fill_rect(Rect2i(o + Vector2i(1, 2), Vector2i(6, 4)), Color("6A5A48"))
			img.fill_rect(Rect2i(o + Vector2i(2, 3), Vector2i(2, 2)), Color("FFE04A"))
			img.fill_rect(Rect2i(o + Vector2i(5, 2), Vector2i(1, 1)), Color("FFE04A"))

## Redessine les cases modifiées par un aménagement.
func _refresh_terrain() -> void:
	if game.terrain_changed.is_empty():
		return
	for p in game.terrain_changed:
		_paint_tile(p.x, p.y)
	game.terrain_changed.clear()
	(terrain_sprite.texture as ImageTexture).update(terrain_img)


func _draw() -> void:
	if mt == null:
		return
	var m := game.map
	# Routes et ponts
	for y in m.h:
		for x in m.w:
			if m.bridge[m.idx(x, y)]:
				draw_rect(Rect2(x * TILE + 1, y * TILE + 1, TILE - 2, TILE - 2), building_colors["pont"])
				for k in 3:
					draw_line(Vector2(x * TILE + 2, y * TILE + 4 + k * 4), Vector2(x * TILE + TILE - 2, y * TILE + 4 + k * 4), Color("5e4630"), 1.0)
			elif m.road[m.idx(x, y)]:
				draw_rect(Rect2(x * TILE + 3, y * TILE, TILE - 6, TILE), building_colors["route"])
	# Chantiers et bâtiments
	for s in game.sites:
		_draw_site(s)
	# Plan de l'IA regardée : enceinte prévue et enclos en projet
	if spectator and mt.ais[game.index]:
		var ai: AIController = mt.ais[game.index]
		if ai.zoo_rect.size != Vector2i.ZERO:
			draw_rect(Rect2(Vector2(ai.zoo_rect.position) * TILE, Vector2(ai.zoo_rect.size) * TILE), Color(1, 0.85, 0.3, 0.5), false, 1.0)
		for p in ai.plans:
			var ir: Rect2i = p["interior"]
			draw_rect(Rect2(Vector2(ir.position) * TILE, Vector2(ir.size) * TILE), Color(biome_colors[p["def"]["biome"]], 0.25))
			_label("Projet : " + str(p["def"]["nom"]), (Vector2(ir.get_center()) + Vector2(0.5, 0)) * TILE, 9)
	# Intérieur de l'enceinte du zoo
	for t in game.zoo_status()["interior"]:
		draw_rect(Rect2(Vector2(t) * TILE, Vector2(TILE, TILE)), Color(UiTokens.ALLEE_ZOO, 0.22))
	# Visiteurs : sur la route, dans la file, dans le zoo
	var vpath := game.visitor_path()
	if not vpath.is_empty():
		for d in game.road_visitors:
			var i := mini(int(d), vpath.size() - 1)
			var j := mini(i + 1, vpath.size() - 1)
			var pos := Vector2(vpath[i]).lerp(Vector2(vpath[j]), d - i) + Vector2(0.5, 0.5)
			draw_circle(pos * TILE, 2.5, Color("f2e6c9"))
		var front := (Vector2(vpath[-1]) + Vector2(0.5, 0.5)) * TILE
		for q in game.visitor_queue:
			draw_circle(front + Vector2((q % 5) * 3.0 - 6.0, (q / 5) * 3.0 - 4.0), 2.0, Color("ffd27f"))
	for v in game.in_zoo:
		draw_circle(v["pos"] * TILE, 2.2, Color("ffe9b0"))
	# Animaux dans leurs enclos
	for a in game.animals:
		var col: Color = biome_colors[a.def["biome"]]
		var center := Vector2.ZERO
		for t in a.tiles:
			draw_rect(Rect2(Vector2(t) * TILE, Vector2(TILE, TILE)), Color(col, 0.18))
			center += Vector2(t) + Vector2(0.5, 0.5)
		center = center / a.tiles.size() * TILE
		draw_circle(center, 5, col)
		var txt: String = a.def["nom"]
		if not a.arrived:
			txt += " (arrive cette nuit)"
		elif not a.fed:
			txt += " (a faim !)"
		elif game.food_due():
			txt += " %.0f/%.0f" % [a.food, game.food_capacity(a.def)]
		_label(txt, center + Vector2(0, -8), 10)
	# Accès vers l'extérieur
	var ex := Vector2(m.exit_tile) * TILE
	draw_rect(Rect2(ex.x + 3, ex.y + TILE, TILE - 6, TILE * 1.5), Color("a0846288"))
	_label("Accès", ex + Vector2(TILE / 2, TILE * 2.9), 11)
	# Camp de base
	var c := Rect2(Vector2(m.camp.position) * TILE, Vector2(m.camp.size) * TILE).grow(-2)
	draw_rect(c, Color("8b5e3c"))
	draw_rect(c, Color("5a3a22"), false, 2.0)
	_label("Camp", c.get_center() + Vector2(0, 4), 12)
	# Gisements d'or
	for gold in m.golds:
		var g := Vector2(gold) * TILE
		draw_rect(Rect2(g, Vector2(TILE, TILE)), Color(1, 1, 1, 0.5), false, 1.5)
		_label("Or", g + Vector2(TILE / 2, -3), 10)

	# Chemins des ouvriers sélectionnés
	for w: GameState.Worker in selected:
		if w.offmap or w.path.is_empty():
			continue
		var pts := PackedVector2Array([w.pos * TILE])
		for p in w.path:
			pts.append((Vector2(p) + Vector2(0.5, 0.5)) * TILE)
		draw_polyline(pts, Color(1, 1, 1, 0.55), 1.5)

	# Zone d'influence des ouvriers sélectionnés (Charismatique, Contremaître, Rabat-joie)
	for w: GameState.Worker in selected:
		if w.offmap:
			continue
		for a in game.auras_of(w.card):
			var col := Color(1, 0.85, 0.3, 0.6) if float(a["bonus"]) > 0 else Color(1, 0.45, 0.45, 0.6)
			draw_circle(w.pos * TILE, float(a["rayon"]) * TILE, Color(col, 0.08))
			draw_arc(w.pos * TILE, float(a["rayon"]) * TILE, 0, TAU, 48, col, 1.0)

	# Ouvriers : écusson couleur de catégorie, liseré couleur du joueur, pastille d'état
	var r := TILE * 0.42
	var player_col: Color = UiTokens.JOUEURS[game.index % UiTokens.JOUEURS.size()]
	for w in game.workers:
		if w.offmap:
			continue
		var p := w.pos * TILE
		if selected.has(w):
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 190.0)
			draw_arc(p + Vector2(0, r * 0.9), r + 2 + pulse * 2, 0, TAU, 24, UiTokens.SELECTION, 2.0)
		var shield := PackedVector2Array([p + Vector2(-r, -r), p + Vector2(r, -r), p + Vector2(r, r * 0.35), p + Vector2(0, r * 1.15), p + Vector2(-r, r * 0.35)])
		draw_colored_polygon(shield, _worker_color(w.card))
		shield.append(shield[0])
		draw_polyline(shield, player_col, 1.5)
		draw_string(font, p + Vector2(-r, r * 0.3), w.card.metier["nom"].left(1), HORIZONTAL_ALIGNMENT_CENTER, r * 2, 10, Color.WHITE)
		if w.unpaid:
			draw_string(font, p + Vector2(-r, -r - 1), "25%", HORIZONTAL_ALIGNMENT_CENTER, r * 2, 7, UiTokens.OR_CLAIR)
		if w.carry > 0.0:
			var cap := game.carry_capacity(w.card)
			draw_rect(Rect2(p.x - r, p.y + r * 1.25, r * 2, 2.5), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(p.x - r, p.y + r * 1.25, r * 2 * w.carry / cap, 2.5), UiTokens.RESSOURCES.get(w.carry_type, {"couleur": Color.WHITE})["couleur"])
		if w.pause_left > 0.0:
			draw_circle(p + Vector2(r, -r), 3.0, Color("7A8A88"))
		elif w.task.is_empty() and w.path.is_empty():
			draw_circle(p + Vector2(r, -r), 3.0, Color("E8B020"))
			draw_string(font, p + Vector2(r - 3, -r + 3), "!", HORIZONTAL_ALIGNMENT_CENTER, 6, 7, Color("1E1406"))

	# Rectangle de sélection
	if drag_start != null:
		var a := _screen_to_world(drag_start)
		var b := _screen_to_world(drag_end)
		var rect := Rect2(a, Vector2.ZERO).expand(b)
		draw_rect(rect, Color(0.91, 0.73, 0.29, 0.15))
		draw_rect(rect, Color("e9b949"), false, 1.0 / camera.zoom.x)

	# Case survolée, ou aperçu du bâtiment à placer
	var hover := _hover_tile()
	if build_choice.get("kind") == "animal":
		var ev := _enc_eval(hover)
		var col := Color(0.4, 1, 0.4) if ev["err"] == "" else Color(1, 0.35, 0.35)
		if ev["enc"]["closed"]:
			for t in ev["enc"]["tiles"]:
				draw_rect(Rect2(Vector2(t) * TILE, Vector2(TILE, TILE)), Color(col, 0.3))
			# Motif trouvé (jaune) ou emplacement le plus proche (orange)
			var pcol := Color("ffe14d") if ev["ps"]["found"] else Color("ff9a3c")
			for t in ev["ps"]["tiles"]:
				draw_rect(Rect2(Vector2(t) * TILE + Vector2(2, 2), Vector2(TILE - 4, TILE - 4)), pcol, false, 2.0)
		elif m.in_bounds(hover.x, hover.y):
			draw_rect(Rect2(Vector2(hover) * TILE, Vector2(TILE, TILE)), col, false, 1.5)
	elif not build_choice.is_empty():
		var origin := _build_origin(hover)
		var rect := game.footprint(build_choice["kind"], build_choice["def"], origin)
		var ok := game.placement_error(build_choice["kind"], build_choice["def"], origin) == ""
		var rr := Rect2(Vector2(rect.position) * TILE, Vector2(rect.size) * TILE)
		if ok:
			draw_rect(rr, Color(UiTokens.SELECTION, 0.32))
			draw_rect(rr, UiTokens.SELECTION, false, 1.5)
		else:
			# Invalide : contour orange + hachures (jamais la couleur seule)
			draw_rect(rr, Color(UiTokens.DEFAUT, 0.18))
			var k := -rr.size.y
			while k < rr.size.x:
				var a := rr.position + Vector2(maxf(k, 0.0), maxf(-k, 0.0))
				var b := rr.position + Vector2(minf(k + rr.size.y, rr.size.x), minf(rr.size.x - k, rr.size.y))
				draw_line(a, b, Color(UiTokens.DEFAUT, 0.8), 1.0)
				k += 5.0
			draw_rect(rr, UiTokens.DEFAUT, false, 1.5)
	elif m.in_bounds(hover.x, hover.y):
		draw_rect(Rect2(Vector2(hover) * TILE, Vector2(TILE, TILE)), Color(1, 1, 1, 0.8), false, 1.0)
	if selected_site and game.sites.has(selected_site):
		var sr := Rect2(Vector2(selected_site.rect.position) * TILE, Vector2(selected_site.rect.size) * TILE)
		draw_rect(sr.grow(1), Color.WHITE, false, 2.0)


func _draw_site(s: GameState.Site) -> void:
	var id := s.def_id()
	var r := Rect2(Vector2(s.rect.position) * TILE, Vector2(s.rect.size) * TILE)
	var ratio := clampf(s.work / s.travail(), 0.0, 1.0)
	if s.kind == "amenagement":
		var col: Color = terrain_colors[GameMap.TERRAINS.find(str(s.def["vers"]))]
		draw_rect(r.grow(-3), Color(col, 0.7))
		draw_rect(r.grow(-1), Color(1, 1, 1, 0.7), false, 1.0)
		_progress(r, ratio)
		return
	var color: Color = building_colors.get(id, Color.GRAY)
	if s.done:
		match id:
			"route", "pont":
				return  # dessinés avec les routes
			"cloture", "enclos":
				_draw_fence(s, color)
			_:
				draw_rect(r.grow(-1), color)
				draw_rect(r.grow(-1), color.darkened(0.45), false, 2.0)
				_label(building_short.get(id, ""), r.get_center() + Vector2(0, 3), 9)
		return
	# Chantier en cours
	draw_rect(r.grow(-1), Color(color, 0.35))
	draw_rect(r.grow(-1), Color(1, 1, 1, 0.75), false, 1.0)
	if id in ["cloture", "enclos"]:
		draw_rect(Rect2(r.get_center() - Vector2(2, 2), Vector2(4, 4)), Color(color, 0.6))
	_progress(r, ratio)


func _progress(r: Rect2, ratio: float) -> void:
	draw_rect(Rect2(r.position.x + 2, r.end.y - 4, r.size.x - 4, 2), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position.x + 2, r.end.y - 4, (r.size.x - 4) * ratio, 2), Color("e9b949"))


func _draw_fence(s: GameState.Site, color: Color) -> void:
	var c := (Vector2(s.rect.position) + Vector2(0.5, 0.5)) * TILE
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var o := game.site_at(s.rect.position + d)
		if o and o.done and o.def_id() == s.def_id():
			draw_line(c, c + Vector2(d) * TILE / 2, color, 3.0)
	draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), color.darkened(0.3))


## Évaluation de l'enclos sous la souris (mise en cache tant que la case survolée ne change pas).
func _enc_eval(t: Vector2i) -> Dictionary:
	if t != enc_cache_tile:
		enc_cache_tile = t
		var enc := game.enclosure_at(t)
		var ps := game.pattern_status(build_choice["def"], enc["tiles"]) if enc["closed"] else {"found": false, "tiles": [], "missing": 99}
		enc_cache = {"enc": enc, "err": game.animal_error(build_choice["def"], enc), "ps": ps}
	return enc_cache


func _build_origin(hover: Vector2i) -> Vector2i:
	if build_choice.is_empty() or build_choice["kind"] != "batiment":
		return hover
	var size := Vector2i(int(build_choice["def"]["taille"][0]), int(build_choice["def"]["taille"][1]))
	return hover - (size - Vector2i.ONE) / 2


func _label(text: String, pos: Vector2, size: int) -> void:
	var width := 80.0
	draw_string_outline(font, pos - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, 3, Color(0, 0, 0, 0.8))
	draw_string(font, pos - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color.WHITE)


func _worker_color(card: GameState.Card) -> Color:
	return UiTokens.CATEGORIES[card.metier["categorie"]]["couleur"]


func _worker_color_old(card: GameState.Card) -> Color:
	var cat: String = card.metier["categorie"]
	if cat != "peu_qualifie":
		return category_colors[cat]
	return {
		"manoeuvre": Color("e8e6e1"), "bucheron": Color("c98b4a"), "macon": Color("e0a07a"), "mineur": Color("b0b8c8"),
		"terrassier": Color("a3785a"), "porteur": Color("7cc4d8"), "apprenti": Color("e7a3c8"),
	}.get(card.metier["id"], Color.WHITE)


# --- Caméra et entrées -------------------------------------------------------

func _screen_to_world(p: Vector2) -> Vector2:
	return camera.position + (p - get_viewport_rect().size / 2) / camera.zoom


func _hover_tile() -> Vector2i:
	var wp := _screen_to_world(get_viewport().get_mouse_position()) / TILE
	return Vector2i(floori(wp.x), floori(wp.y))


func _zoom_at(factor: float, screen_pos: Vector2) -> void:
	var before := _screen_to_world(screen_pos)
	camera.zoom = (camera.zoom * factor).clamp(Vector2(0.5, 0.5), Vector2(4, 4))
	camera.position += before - _screen_to_world(screen_pos)


func _unhandled_input(event: InputEvent) -> void:
	if mt == null:
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_at(1.15, event.position)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_at(1.0 / 1.15, event.position)
			MOUSE_BUTTON_LEFT:
				if not build_choice.is_empty():
					painting = true
					_try_place(_hover_tile(), true)
				else:
					drag_start = event.position
					drag_end = event.position
					drag_add = event.shift_pressed
			MOUSE_BUTTON_MIDDLE:
				panning = true
			MOUSE_BUTTON_RIGHT:
				if not build_choice.is_empty():
					_set_build({})
					return
				var targets := selected.filter(func(w): return game.workers.has(w))
				if not targets.is_empty():
					var t := _screen_to_world(event.position) / TILE
					game.order(targets, Vector2i(floori(t.x), floori(t.y)))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				if not build_choice.is_empty():
					_set_build({})
				else:
					selected.clear()
					selected_site = null
			KEY_SPACE:
				_set_speed(1.0 if speed == 0.0 else 0.0)
			KEY_1:
				_set_speed(1.0)
			KEY_2:
				_set_speed(2.0)
			KEY_3:
				_set_speed(4.0)


# Les relâchements et mouvements sont suivis partout, même au-dessus de l'interface.
func _input(event: InputEvent) -> void:
	if mt == null:
		return
	if event is InputEventMouseMotion:
		if drag_start != null:
			drag_end = event.position
		if panning:
			camera.position -= event.relative / camera.zoom
		if painting and _is_paint_build():
			var t := _hover_tile()
			if t != last_paint:
				_try_place(t, false)
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = false
		elif event.button_index == MOUSE_BUTTON_LEFT:
			painting = false
			if drag_start != null:
				_finish_selection()


# --- Construction ------------------------------------------------------------

func _set_build(choice: Dictionary) -> void:
	build_choice = choice
	painting = false
	enc_cache_tile = Vector2i(-99, -99)
	hand_version = -1  # rafraîchit l'état des boutons de contrats
	for entry in build_buttons:
		entry[0].button_pressed = not choice.is_empty() and entry[2] == choice["def"]


func _is_paint_build() -> bool:
	return not build_choice.is_empty() and (build_choice["kind"] == "amenagement" or build_choice["def"].get("peinture", false))


## Place un chantier. Les routes, clôtures et aménagements se « peignent » en glissant la souris ;
## les autres bâtiments se placent un par un (Maj pour en placer plusieurs).
func _try_place(t: Vector2i, first_click: bool) -> void:
	last_paint = t
	var kind: String = build_choice["kind"]
	var def: Dictionary = build_choice["def"]
	if kind == "animal":
		var aerr := game.install_animal(def, t)
		if aerr != "":
			game.say(aerr)
		else:
			_set_build({})
		return
	var origin := _build_origin(t)
	var err := game.placement_error(kind, def, origin)
	if err != "":
		if first_click:
			game.say(err)
		return
	var s := game.place(kind, def, origin)
	if s and not _is_paint_build() and not Input.is_key_pressed(KEY_SHIFT):
		_set_build({})
		selected_site = s


func _finish_selection() -> void:
	var start: Vector2 = drag_start
	drag_start = null
	if not drag_add:
		selected.clear()
	selected_site = null
	if start.distance_to(drag_end) < 5:
		var wp := _screen_to_world(drag_end) / TILE
		var best: GameState.Worker = null
		var best_d := 0.6
		for w in game.workers:
			if not w.offmap and w.pos.distance_to(wp) < best_d:
				best = w
				best_d = w.pos.distance_to(wp)
		if best and not selected.has(best):
			selected.append(best)
		elif not best and selected.is_empty():
			selected_site = game.site_at(Vector2i(floori(wp.x), floori(wp.y)))
	else:
		var rect := Rect2(_screen_to_world(start) / TILE, Vector2.ZERO).expand(_screen_to_world(drag_end) / TILE)
		for w in game.workers:
			if not w.offmap and rect.has_point(w.pos) and not selected.has(w):
				selected.append(w)
	_update_info()


func _pan_keys(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	camera.position += dir * 600.0 * delta / camera.zoom.x


func _set_speed(s: float) -> void:
	speed = s
	for k in speed_buttons:
		speed_buttons[k].button_pressed = (k == s)


# --- Boucle principale -------------------------------------------------------

func _process(delta: float) -> void:
	if mt == null:
		_screenshot_check()
		return
	_pan_keys(delta)
	if mt.phase == "draft" and mt.is_ai(mt.current_drafter()):
		ai_timer += delta
		if ai_timer > 0.35:
			ai_timer = 0.0
			mt.pick_draft(mt.ai_choice())
	# En mode spectateur, la nuit passe toute seule.
	if spectator and mt.phase == "night" and not mt.game_over:
		night_clock += delta
		if night_clock > (1.0 if speed >= 8.0 else 2.5):
			night_clock = 0.0
			mt.start_next_day()
	acc += minf(delta, 0.1) * speed
	while acc >= GameState.TICK:
		game.tick(GameState.TICK)
		acc -= GameState.TICK
	selected = selected.filter(func(w): return game.workers.has(w))
	if selected_site and not game.sites.has(selected_site):
		selected_site = null
	_refresh_terrain()
	queue_redraw()
	_update_hud()
	if hand_version != game.version:
		hand_version = game.version
		_rebuild_hand()
		_rebuild_draft()
		_rebuild_contracts()
		_rebuild_night()
		_rebuild_market_preview()
		enc_cache_tile = Vector2i(-99, -99)
		_update_info()
	info_clock += delta
	if info_clock > 0.25:
		info_clock = 0.0
		_update_info()
		for entry in build_buttons:
			entry[0].disabled = game.phase != "day" or not game.can_afford(entry[2].get("cout", {}))
		sell_btn.text = "Vendre bois/pierre (%s)" % ("plein" if game.marchand_present() else "-50 %")
		sell_gold_btn.text = "Vendre l'or (%.1f/u)" % game.sell_price("or")
		var ev: Dictionary = mt.current_event
		event_label.visible = mt.phase == "day" and not ev.is_empty()
		if not ev.is_empty():
			event_label.text = "  %s : %s  " % [ev["nom"], ev["texte"]]
		sell_btn.tooltip_text = "Vend le bois et la pierre du stock (l'or est conservé).
Sans Marchand : moitié prix. Envoyez un Marchand sur le camp (clic droit) pour le plein tarif."
	_screenshot_check()


func _screenshot_check() -> void:
	if not args.has("shot"):
		return
	frame_count += 1
	if frame_count == 20:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args["shot"])
		get_tree().quit()


func _auto_play() -> void:
	for c in game.hand.duplicate():
		game.deploy(c)
	var forest := _nearest(GameMap.FORET)
	var rock := _nearest(GameMap.ROCHE)
	var ws := game.workers
	for i in ws.size():
		var target := forest if i < 2 else (rock if i < 4 else game.map.exit_tile)
		game.order([ws[i]], target)
	if args.has("autobuild"):
		# Des ressources de départ pour montrer chantiers et bâtiments sur une capture.
		game.stock["bois"] += 60
		game.stock["pierre"] += 60
		var c := game.map.camp
		var maison := game.place("batiment", game.building_def("maison"), c.position + Vector2i(-4, 0))
		var entrepot := game.place("batiment", game.building_def("entrepot"), c.position + Vector2i(5, 0))
		for y in range(c.position.y - 1, c.position.y - 9, -1):
			game.place("batiment", game.building_def("route"), Vector2i(c.position.x + 1, y))
		for x in range(c.position.x - 3, c.position.x + 6):
			game.place("batiment", game.building_def("cloture"), Vector2i(x, c.position.y - 12))
		game.place("amenagement", game.amenagement_defs()[2], c.position + Vector2i(-3, -4))
		game.order(ws.slice(0, 2), maison.rect.position)
		game.order(ws.slice(2, 4), Vector2i(c.position.x + 1, c.position.y - 1))
		if entrepot:
			entrepot.work = entrepot.travail() * 0.4
	var sim := float(args.get("sim", "0"))
	for i in int(sim / GameState.TICK):
		game.tick(GameState.TICK)
	if args.has("autozoo"):
		var c := game.map.camp.position
		game.debug_build_zoo(Vector2i(c.x - 12, c.y - 12))
		game.end_day()
		game.start_next_day()
		for card in game.hand.duplicate():
			game.deploy(card)
	if args.has("endday"):
		game.end_day()
	selected = ws.slice(0, 2)


func _nearest(terrain: int) -> Vector2i:
	var m := game.map
	var reach := MapGenerator.reachable(m)
	var c := m.camp.get_center()
	var best := c
	var best_d := 1 << 30
	for y in m.h:
		for x in m.w:
			if m.get_t(x, y) == terrain and reach[m.idx(x, y)]:
				var d := absi(x - c.x) + absi(y - c.y)
				if d < best_d:
					best_d = d
					best = Vector2i(x, y)
	return best


# --- Interface ---------------------------------------------------------------

func _panel_style(bg := UiTokens.PANNEAU_MILIEU, border := UiTokens.OR, radius := 10) -> StyleBoxFlat:
	return UiTokens.panel(bg, border, radius, 2 if bg.a > 0.9 else 1)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UiTokens.build_theme()
	layer.add_child(ui)

	# Barre du haut
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", _panel_style())
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	ui.add_child(top)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	top.add_child(hb)
	lbl_day = Label.new()
	hb.add_child(lbl_day)
	lbl_timer = Label.new()
	hb.add_child(lbl_timer)
	timebar = ProgressBar.new()
	timebar.show_percentage = false
	timebar.custom_minimum_size = Vector2(140, 10)
	timebar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(timebar)
	lbl_res = Label.new()
	lbl_res.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl_res)
	if spectator:
		var see := Label.new()
		see.text = "Voir :"
		hb.add_child(see)
		for i in mt.players.size():
			var vb := Button.new()
			vb.text = "IA %d" % (i + 1)
			vb.tooltip_text = mt.names[i]
			vb.toggle_mode = true
			vb.button_pressed = i == 0
			vb.focus_mode = Control.FOCUS_NONE
			vb.pressed.connect(_view_player.bind(i))
			view_buttons.append(vb)
			hb.add_child(vb)
	for s in [0.0, 1.0, 2.0, 4.0, 8.0, 16.0]:
		var b := Button.new()
		b.text = "||" if s == 0.0 else "x%d" % int(s)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_set_speed.bind(s))
		speed_buttons[s] = b
		hb.add_child(b)
	var end_btn := Button.new()
	end_btn.text = "Finir la journée"
	end_btn.focus_mode = Control.FOCUS_NONE
	end_btn.pressed.connect(func(): game.end_day())
	if not spectator:
		hb.add_child(end_btn)
	# Le marché du soir est tiré le matin : on peut le consulter en journée pour s'organiser (influence, argent).
	var market_btn := Button.new()
	market_btn.text = "Marché du soir"
	market_btn.focus_mode = Control.FOCUS_NONE
	market_btn.tooltip_text = "Ouvriers et contrats proposés cette nuit, dans l'ordre d'influence"
	market_btn.pressed.connect(func():
		market_root.visible = not market_root.visible
		_rebuild_market_preview())
	hb.add_child(market_btn)
	sell_btn = Button.new()
	sell_btn.text = "Vendre bois et pierre"
	sell_btn.focus_mode = Control.FOCUS_NONE
	sell_btn.pressed.connect(func(): game.sell_stock())
	sell_gold_btn = Button.new()
	sell_gold_btn.focus_mode = Control.FOCUS_NONE
	sell_gold_btn.pressed.connect(func(): game.sell_stock({}, ["or"]))

	event_label = Label.new()
	event_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	event_label.offset_top = 52
	event_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	event_label.add_theme_stylebox_override("normal", _panel_style(Color(0.35, 0.22, 0.05, 0.85), Color("e9b949"), 6))
	event_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(event_label)

	# Panneau d'information à droite
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", _panel_style())
	right.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	right.offset_left = -280
	right.offset_top = 48
	right.offset_bottom = -215
	ui.add_child(right)
	var rv := VBoxContainer.new()
	right.add_child(rv)
	info_text = RichTextLabel.new()
	info_text.bbcode_enabled = true
	info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(info_text)
	btn_lobby = Button.new()
	btn_lobby.text = "Envoyer en lobbying"
	btn_lobby.focus_mode = Control.FOCUS_NONE
	btn_lobby.pressed.connect(func(): game.order(selected, game.map.exit_tile))
	rv.add_child(btn_lobby)
	btn_recall = Button.new()
	btn_recall.text = "Rappeler sur la carte"
	btn_recall.focus_mode = Control.FOCUS_NONE
	btn_recall.pressed.connect(func():
		for w in selected:
			game.recall(w))
	rv.add_child(btn_recall)
	btn_cancel_site = Button.new()
	btn_cancel_site.text = "Annuler le chantier"
	btn_cancel_site.focus_mode = Control.FOCUS_NONE
	btn_cancel_site.pressed.connect(func():
		if selected_site:
			game.cancel_site(selected_site)
			selected_site = null)
	rv.add_child(btn_cancel_site)
	btn_demolish = Button.new()
	btn_demolish.text = "Démolir (sans remboursement)"
	btn_demolish.focus_mode = Control.FOCUS_NONE
	btn_demolish.pressed.connect(func():
		if selected_site and game.demolish(selected_site):
			selected_site = null)
	rv.add_child(btn_demolish)
	# Marché du camp : vendre et acheter des matériaux
	if not spectator:
		_menu_title(rv, "Marché")
		var trade := GridContainer.new()
		trade.columns = 2
		rv.add_child(trade)
		sell_btn.add_theme_font_size_override("font_size", 12)
		sell_gold_btn.add_theme_font_size_override("font_size", 12)
		trade.add_child(sell_btn)
		trade.add_child(sell_gold_btn)
		for res in ["bois", "pierre"]:
			var bb := Button.new()
			bb.text = "Acheter 10 %s (%d)" % [res, ceili(game.buy_price(res) * 10)]
			bb.tooltip_text = "Au double du prix de revente : l'argent devient de la vitesse de construction."
			bb.focus_mode = Control.FOCUS_NONE
			bb.add_theme_font_size_override("font_size", 12)
			bb.pressed.connect(game.buy_material.bind(res, 10))
			trade.add_child(bb)

	# Menu de construction à gauche
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", _panel_style())
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left.offset_right = 214
	left.offset_top = 48
	left.offset_bottom = -215
	ui.add_child(left)
	var lscroll := ScrollContainer.new()
	lscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(lscroll)
	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lscroll.add_child(lv)
	_menu_title(lv, "Contrats à installer")
	contracts_box = VBoxContainer.new()
	lv.add_child(contracts_box)
	_menu_title(lv, "Construire")
	for b in game.building_defs():
		_build_button(lv, "batiment", b)
	_menu_title(lv, "Aménager le terrain")
	for a in game.amenagement_defs():
		_build_button(lv, "amenagement", a)

	# Main en bas
	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", _panel_style())
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -210
	ui.add_child(bottom)
	var bv := VBoxContainer.new()
	bottom.add_child(bv)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bv.add_child(scroll)
	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 10)
	scroll.add_child(hand_box)
	var help := Label.new()
	help.text = "Clic gauche : sélectionner · Clic droit : déplacer / extraire / construire / lobbying (Accès) · Menu de gauche : placer (glisser pour routes et clôtures), Échap pour arrêter · Molette : zoom · ZQSD : vue · Espace : pause"
	help.add_theme_font_size_override("font_size", 12)
	help.modulate = Color(1, 1, 1, 0.6)
	bv.add_child(help)

	status_label = Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	status_label.offset_top = -240
	status_label.offset_bottom = -216
	status_label.offset_left = 224
	status_label.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0.6), Color(0, 0, 0, 0), 6))
	ui.add_child(status_label)

	toast_box = VBoxContainer.new()
	toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_box.offset_top = 56
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(toast_box)

	# Écran de nuit
	var night := _overlay()
	night_root = night[0]
	var outer: VBoxContainer = night[1]
	night_title = Label.new()
	night_title.add_theme_font_size_override("font_size", 24)
	outer.add_child(night_title)
	var nscroll := ScrollContainer.new()
	nscroll.custom_minimum_size = Vector2(1100, 680)
	nscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(nscroll)
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 10)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nscroll.add_child(nv)
	night_text = RichTextLabel.new()
	night_text.bbcode_enabled = true
	night_text.fit_content = true
	night_text.custom_minimum_size = Vector2(1060, 0)
	nv.add_child(night_text)
	_menu_title(nv, "Marché des ouvriers (1 embauche par nuit)")
	night_workers = HBoxContainer.new()
	night_workers.add_theme_constant_override("separation", 10)
	nv.add_child(night_workers)
	_menu_title(nv, "Contrats d'animaux (jusqu'à 2 achats par nuit)")
	night_contracts = HBoxContainer.new()
	night_contracts.add_theme_constant_override("separation", 10)
	nv.add_child(night_contracts)
	_menu_title(nv, "Cartes d'action (1 achat par nuit, elles vont dans votre deck)")
	night_actions = HBoxContainer.new()
	night_actions.add_theme_constant_override("separation", 10)
	nv.add_child(night_actions)
	_menu_title(nv, "Bonus de demain, pour tous les zoos (choisi par le premier en influence)")
	night_bonus_box = HBoxContainer.new()
	night_bonus_box.add_theme_constant_override("separation", 8)
	nv.add_child(night_bonus_box)
	night_level_box = VBoxContainer.new()
	nv.add_child(night_level_box)
	_menu_title(night_level_box, "Montées de niveau : choisissez une amélioration (gratuite)")
	night_level_rows = VBoxContainer.new()
	night_level_box.add_child(night_level_rows)
	night_action_box = VBoxContainer.new()
	nv.add_child(night_action_box)
	_menu_title(night_action_box, "Améliorer ou licencier un ouvrier (une action par nuit)")
	night_action_flow = HFlowContainer.new()
	night_action_box.add_child(night_action_flow)
	night_upgrade_box = HBoxContainer.new()
	night_upgrade_box.add_theme_constant_override("separation", 8)
	night_action_box.add_child(night_upgrade_box)
	night_fire_box = VBoxContainer.new()
	nv.add_child(night_fire_box)
	_menu_title(night_fire_box, "Licencier (votre DRH a travaillé aujourd'hui)")
	night_fire = HFlowContainer.new()
	night_fire_box.add_child(night_fire)
	night_next = Button.new()
	night_next.text = "Commencer le jour suivant"
	night_next.pressed.connect(func():
		game.start_next_day()
		selected.clear())
	outer.add_child(night_next)

	# Aperçu du marché du soir (lecture seule, en journée)
	var market := _overlay()
	market_root = market[0]
	market_box = market[1]

	# Écran de draft
	var draft := _overlay()
	draft_root = draft[0]
	var dv: VBoxContainer = draft[1]
	draft_title = Label.new()
	draft_title.theme_type_variation = "TitreEcran"
	draft_title.add_theme_font_size_override("font_size", 26)
	dv.add_child(draft_title)
	draft_order_lbl = RichTextLabel.new()
	draft_order_lbl.bbcode_enabled = true
	draft_order_lbl.fit_content = true
	draft_order_lbl.custom_minimum_size = Vector2(1060, 0)
	dv.add_child(draft_order_lbl)
	var dscroll := ScrollContainer.new()
	dscroll.custom_minimum_size = Vector2(1060, 520)
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dv.add_child(dscroll)
	draft_grid = GridContainer.new()
	draft_grid.columns = 4
	draft_grid.add_theme_constant_override("h_separation", 10)
	draft_grid.add_theme_constant_override("v_separation", 10)
	dscroll.add_child(draft_grid)
	draft_picks = RichTextLabel.new()
	draft_picks.bbcode_enabled = true
	draft_picks.fit_content = true
	draft_picks.custom_minimum_size = Vector2(1060, 0)
	dv.add_child(draft_picks)


func _menu_title(parent: Control, text: String) -> void:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_color_override("font_color", UiTokens.OR)
	l.add_theme_font_size_override("font_size", 14)
	parent.add_child(l)


func _build_button(parent: Control, kind: String, def: Dictionary) -> void:
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 13)
	var cost: Dictionary = def.get("cout", {})
	b.text = "%s\n   %s" % [def["nom"], game.cost_text(cost)]
	var tip: Array[String] = ["Travail : %d" % int(def["travail"])]
	if kind == "amenagement":
		var de = def["de"]
		tip.append("%s → %s" % [" ou ".join(de if de is Array else [de]), def["vers"]])
		tip.append("Spécialistes : Terrassier, Paysagiste")
	else:
		tip.append("Taille : %dx%d" % [int(def["taille"][0]), int(def["taille"][1])])
		tip.append("Type de travail : %s" % def["type_travail"])
		if def.has("sur"):
			tip.append("Se construit sur : %s" % def["sur"])
		if def.get("unique", false):
			tip.append("Unique")
	b.tooltip_text = "\n".join(tip)
	b.pressed.connect(func():
		if build_choice.get("def") == def:
			_set_build({})
		else:
			_set_build({"kind": kind, "def": def})
			selected.clear())
	parent.add_child(b)
	build_buttons.append([b, kind, def])


## Marché du soir vu en journée : les cartes qui seront proposées la nuit, pour décider de l'effort de lobbying.
func _rebuild_market_preview() -> void:
	if market_root == null or not market_root.visible:
		return
	if game.phase != "day":
		market_root.visible = false
		return
	for c in market_box.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "MARCHÉ DE CE SOIR"
	title.theme_type_variation = "TitreEcran"
	title.add_theme_font_size_override("font_size", 26)
	market_box.add_child(title)
	var info := RichTextLabel.new()
	info.bbcode_enabled = true
	info.fit_content = true
	info.custom_minimum_size = Vector2(1060, 0)
	var rank := mt.night_order.find(game.index)
	info.text = "Cette nuit, on achète dans l'ordre d'influence (valeurs cachées) : 1 ouvrier et jusqu'à 2 contrats chacun, et le premier choisit le bonus de demain pour tous.\nVotre influence : [b]%.1f[/b]%s. Envoyez des ouvriers en lobbying (case Accès) pour passer devant." % [
		game.influence, " · la nuit dernière, vous étiez [b]%de[/b] sur %d" % [rank + 1, mt.players.size()] if rank >= 0 else ""]
	market_box.add_child(info)
	var workers := HBoxContainer.new()
	workers.add_theme_constant_override("separation", 10)
	for card in mt.market_workers:
		workers.add_child(_card_widget(card, "Embauche : %d" % game.hire_cost(card), true, func(): pass))
	market_box.add_child(workers)
	var contracts := HBoxContainer.new()
	contracts.add_theme_constant_override("separation", 10)
	for def in mt.market_contracts:
		contracts.add_child(_contract_widget(def, "Prix ce soir : %s" % game.cost_text(game.contract_cost(def)), "Achat possible cette nuit", func(): pass))
	market_box.add_child(contracts)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	for card in mt.market_actions:
		actions.add_child(_action_widget(card, "Prix ce soir : %d" % int(card.action["cout"]), true, func(): pass))
	market_box.add_child(actions)
	var close := Button.new()
	close.text = "Fermer"
	close.theme_type_variation = "BoutonPrincipal"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): market_root.visible = false)
	market_box.add_child(close)


func _overlay() -> Array:
	var root := ColorRect.new()
	root.color = UiTokens.VOILE_NUIT
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	ui.add_child(root)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	var style := UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 12, 2, 20)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	return [root, v]


func _traits_bbcode(card: GameState.Card) -> String:
	if card.traits.is_empty() and card.upgrade_names.is_empty():
		return "[color=#9aa0ab]Aucun trait[/color]"
	var parts: Array[String] = []
	for t in game.trait_defs(card):
		var pos := game.is_positive(t["id"])
		parts.append("[color=%s]%s %s[/color]" % ["#3A8AE8" if pos else "#E8782A", "● +" if pos else "■ −", t["nom"]])
	for u in card.upgrade_names:
		parts.append("[color=#FFD45A]★ %s[/color]" % u)
	return "  ".join(parts)


func _card_tooltip(card: GameState.Card) -> String:
	var lines: Array[String] = []
	if card.metier.has("capacite"):
		lines.append(card.metier["capacite"])
	for t in game.trait_defs(card):
		var txt: String = t.get("texte", "")
		if txt == "":
			var effets: Array[String] = []
			for k in t["effet"]:
				effets.append("%s %s" % [k, str(t["effet"][k])])
			txt = ", ".join(effets)
		lines.append("%s : %s" % [t["nom"], txt])
	return "\n".join(lines)


func _card_widget(card: GameState.Card, button_text: String, disabled: bool, cb: Callable, extra: Array = []) -> Control:
	var cat: String = card.metier["categorie"]
	var border: Color = Color("7fc97f") if card.deployed else category_colors[cat].darkened(0.35)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(196, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("2a2e38"), border, 8))
	panel.tooltip_text = _card_tooltip(card)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var lbl_name := Label.new()
	lbl_name.text = card.nom
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lbl_name)
	var lvl := Label.new()
	lvl.text = "Niv. %d" % card.niveau
	lvl.modulate = Color(1, 1, 1, 0.6)
	top.add_child(lvl)
	var job := Label.new()
	job.text = "%s · %s" % [card.metier["nom"], category_noms[cat]]
	job.add_theme_color_override("font_color", category_colors[cat])
	job.add_theme_font_size_override("font_size", 13)
	v.add_child(job)
	var tr := RichTextLabel.new()
	tr.bbcode_enabled = true
	tr.fit_content = true
	tr.scroll_active = false
	tr.custom_minimum_size = Vector2(176, 0)
	tr.add_theme_font_size_override("normal_font_size", 12)
	tr.mouse_filter = Control.MOUSE_FILTER_PASS
	tr.text = _traits_bbcode(card)
	v.add_child(tr)
	var sal := Label.new()
	sal.text = "Salaire : %d / jour" % game.salary(card)
	sal.add_theme_font_size_override("font_size", 12)
	sal.modulate = Color(1, 1, 1, 0.7)
	v.add_child(sal)
	var b := Button.new()
	b.text = button_text
	b.disabled = disabled
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	v.add_child(b)
	if not extra.is_empty():
		var b2 := Button.new()
		b2.text = extra[0]
		b2.disabled = extra[1]
		b2.tooltip_text = extra[3] if extra.size() > 3 else ""
		b2.focus_mode = Control.FOCUS_NONE
		b2.add_theme_font_size_override("font_size", 12)
		b2.pressed.connect(extra[2])
		v.add_child(b2)
	return panel


func _rebuild_hand() -> void:
	for c in hand_box.get_children():
		c.queue_free()
	if game.phase == "draft":
		return
	if game.hand.is_empty():
		var l := Label.new()
		l.text = "Main vide : la nuit tombe."
		hand_box.add_child(l)
		return
	for card in game.hand:
		if card.is_action():
			hand_box.add_child(_action_widget(card, "Jouée" if card.deployed else "Jouer",
				spectator or card.deployed or game.phase != "day", game.play_action.bind(card)))
			continue
		var w := game.worker_of(card)
		if not card.deployed:
			var sal := 0 if game.prime_left > 0 else game.salary(card)
			var free := ["Gratuit (rendement 25 %)", spectator or not game.free_deploy_available(), _on_deploy_free.bind(card),
				"Un ouvrier par jour peut travailler sans salaire, à 25 % de son rendement."]
			hand_box.add_child(_card_widget(card, ("Déployer (Prime)" if game.prime_left > 0 else "Déployer (%d)" % sal),
				spectator or game.money < sal, _on_deploy.bind(card), free))
		elif w and w.offmap:
			hand_box.add_child(_card_widget(card, "En lobbying : rappeler", false, _on_recall.bind(w)))
		else:
			hand_box.add_child(_card_widget(card, "Sélectionner", false, _on_focus.bind(w)))


## Carte d'action (main, marché) : nom, effet, et un bouton (jouer, acheter…).
func _action_widget(card: GameState.Card, button_text: String, disabled: bool, cb: Callable) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(196, 0)
	panel.add_theme_stylebox_override("panel", UiTokens.panel(Color("3a2a12"), UiTokens.OR, 8, 2, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var kind := Label.new()
	kind.text = "CARTE D'ACTION"
	kind.add_theme_font_size_override("font_size", 11)
	kind.add_theme_color_override("font_color", UiTokens.OR)
	v.add_child(kind)
	var nom := Label.new()
	nom.text = card.action["nom"]
	nom.theme_type_variation = "NomCarte"
	nom.add_theme_font_size_override("font_size", 15)
	v.add_child(nom)
	var txt := Label.new()
	txt.text = card.action["texte"]
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size = Vector2(176, 0)
	txt.add_theme_font_size_override("font_size", 12)
	v.add_child(txt)
	var b := Button.new()
	b.text = button_text
	b.disabled = disabled
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	v.add_child(b)
	return panel


func _on_deploy(card: GameState.Card) -> void:
	if game.deploy(card):
		selected = [game.worker_of(card)]


func _on_deploy_free(card: GameState.Card) -> void:
	if game.deploy(card, true):
		selected = [game.worker_of(card)]


## Mode spectateur : affiche le zoo d'une autre IA.
func _view_player(i: int) -> void:
	game = mt.players[i]
	for k in view_buttons.size():
		view_buttons[k].button_pressed = k == i
	selected.clear()
	selected_site = null
	build_choice = {}
	for y in game.map.h:
		for x in game.map.w:
			_paint_tile(x, y)
	game.terrain_changed.clear()
	(terrain_sprite.texture as ImageTexture).update(terrain_img)
	hand_version = -1
	_focus_zoo()


## Mode spectateur : centre la caméra sur l'enceinte prévue par l'IA regardée.
func _focus_zoo() -> void:
	if not spectator or mt.ais[game.index] == null:
		return
	var zr: Rect2i = mt.ais[game.index].zoo_rect
	if zr.size != Vector2i.ZERO:
		camera.position = Vector2(zr.get_center()) * TILE
		camera.zoom = Vector2(1.3, 1.3)


func _on_recall(w: GameState.Worker) -> void:
	game.recall(w)
	selected = [w]


func _on_focus(w: GameState.Worker) -> void:
	selected = [w]
	camera.position = w.pos * TILE


func _rebuild_draft() -> void:
	draft_root.visible = game.phase == "draft"
	if game.phase != "draft":
		return
	for c in draft_grid.get_children():
		c.queue_free()
	var my_turn := not mt.is_ai(mt.current_drafter())
	draft_title.text = "DRAFT · TOUR %d / %d — %s" % [mt.draft_round() + 1, mt.draft_rounds(),
		"À VOUS DE CHOISIR" if my_turn else "%s choisit…" % mt.names[mt.current_drafter()]]
	# Ordre du tour : déjà passés en gris, joueur courant en or, la dernière carte revient d'office au dernier.
	var order: Array[String] = []
	var pos_in_round := mt.draft_turn % mt.players.size()
	var round_order := mt.draft_round_order()
	for i in round_order.size():
		var nom := mt.names[round_order[i]]
		if i < pos_in_round:
			order.append("[color=#6E8F86]%s[/color]" % nom)
		elif i == pos_in_round:
			order.append("[color=#FFD45A][b]%s[/b][/color]" % nom)
		else:
			order.append(nom)
	draft_order_lbl.text = "Ordre du tour : %s\n[color=#A6D4C8]%d cartes révélées, une chacun. Le premier à choisir change à chaque tour.%s[/color]" % [
		"  ›  ".join(order), mt.draft_round_size(),
		" La dernière carte revient d'office au dernier joueur." if mt.draft_round_size() == mt.players.size() else " Les cartes restantes sont défaussées."]
	for card in mt.draft_pool:
		draft_grid.add_child(_card_widget(card, "Choisir", not my_turn, mt.pick_draft.bind(card)))
	var lines: Array[String] = []
	for p in mt.players.size():
		var names: Array[String] = []
		for c in mt.drafted[p]:
			names.append("%s ([color=%s]%s[/color])" % [c.nom, category_colors[c.metier["categorie"]].to_html(false), c.metier["nom"]])
		lines.append("[b]%s[/b] (%d) : %s" % [mt.names[p], names.size(), ", ".join(names)])
	draft_picks.text = "\n".join(lines)


func _task_text(w: GameState.Worker) -> String:
	if w.offmap:
		return "En lobbying (hors carte)"
	if w.pause_left > 0.0:
		return "En pause"
	if w.task.is_empty():
		return "Se déplace" if not w.path.is_empty() else "Inactif"
	if w.task["type"] == "lobby":
		return "Va vers l'accès"
	if w.task["type"] == "station":
		if not w.path.is_empty():
			return "Va à son poste"
		if w.task["kind"] == "formation":
			return "Forme les ouvriers du centre" if w.card.metier["id"] == "formateur" else "Se forme au centre de formation"
		return {"trade": "Tient le comptoir du camp", "shop": "Tient la boutique", "ticket": "Tient le guichet", "snack": "Tient le snack",
			"kiosque": "Anime le kiosque", "care": "Soigne : " + str(w.task["obj"].def["nom"] if w.task["obj"] else "")}[w.task["kind"]]
	if w.task["type"] == "feed":
		if w.task["phase"] == "deliver":
			return "Livre %.0f ration(s) : %s" % [w.task["rations"], w.task["animal"].def["nom"]]
		if not w.path.is_empty():
			return "Retourne à la cuisine"
		return "Prépare des rations (%.0f)" % w.task["rations"] if game.rations_needed() > 0.0 else "Attend à la cuisine (tous nourris)"
	if w.task["type"] == "clean":
		return "Nettoie le parc (propreté %d %%)" % roundi(game.proprete)
	if w.task["type"] == "build":
		var s: GameState.Site = w.task["site"]
		return ("Va au chantier : " if not w.path.is_empty() else "Construit : ") + str(s.def["nom"])
	var res: String = res_noms[w.task["res"]]
	return {"to_resource": "Va extraire du " + res, "working": "Extrait du " + res, "to_depot": "Rapporte au camp"}[w.task["phase"]]


func _update_info() -> void:
	btn_lobby.disabled = selected.is_empty() or game.phase != "day"
	btn_recall.disabled = not selected.any(func(w): return w.offmap)
	btn_cancel_site.visible = selected_site != null and not selected_site.done
	btn_demolish.visible = not spectator and selected_site != null and selected_site.done and selected_site.kind == "batiment"
	if selected.is_empty() and selected_site:
		var s := selected_site
		var builders := game.workers.filter(func(w): return w.task.get("site") == s).size()
		var lines: Array[String] = ["[b]%s[/b]" % s.def["nom"]]
		if s.done:
			lines.append("Terminé")
			match s.def_id():
				"maison":
					lines.append("Logement +%d" % int(s.def["effet"]["logement"]))
				"entrepot":
					lines.append("Dépôt de ressources : les ouvriers y rapportent leur charge s'il est plus proche que le camp.")
				"mine":
					lines.append("Clic droit avec des ouvriers pour extraire de l'or.")
		else:
			lines.append("Chantier : %d / %d" % [int(s.work), int(s.travail())])
			lines.append("Ouvriers dessus : %d" % builders)
			lines.append("Coût payé : %s" % game.cost_text(s.paid))
			lines.append("[color=#9aa0ab]Clic droit avec des ouvriers sélectionnés pour y travailler. L'avancement est conservé d'un jour à l'autre.[/color]")
		info_text.text = "\n".join(lines)
		return
	if selected.is_empty():
		var z := game.zoo_live()
		var zoo_line := ""
		if z["open"]:
			zoo_line = "[color=#7fc97f]Zoo ouvert[/color] · attractivité %d · publicité +%d %%\n" % [z["attract"], roundi((z["pub"] - 1.0) * 100)]
			zoo_line += "Visiteurs : %d sur la route, %d en file, %d / %d dans le zoo\n" % [z["road"], z["queue"], z["inside"], z["capacity"]]
			if z["inside"] >= z["capacity"] and z["queue"] > 0:
				zoo_line += "[color=#ffb09a]Parc plein : la file attend. Agrandissez l'enceinte pour accueillir plus de monde.[/color]\n"
			zoo_line += "Aujourd'hui : %d entrés, %d repartis (file pleine)\nRecettes : billets %d, souvenirs %d\n" % [z["admitted"], z["lost"], z["tickets"], z["souvenirs"]]
			zoo_line += "Demande ≈ %d visiteurs/jour · guichet %d/min\n" % [roundi(z["demand_day"]), roundi(z["guichet_min"])]
			var hungry := game.animals.filter(func(a): return a.arrived and not a.fed).size()
			if game.affinity_bonus() > 0.0:
				zoo_line += "Affinités de continent : réputation +%d %%\n" % roundi(game.affinity_bonus() * 100)
			zoo_line += "Propreté %d %%%s · rations à livrer %d%s" % [roundi(game.proprete),
				" [color=#ffb09a](visiteurs en baisse : Local d'entretien)[/color]" if game.cleanliness_mult() < 1.0 else "",
				ceili(game.rations_needed()), " · [color=#ffb09a]%d animal(aux) affamé(s) : Cuisine des animaux ![/color]" % hungry if hungry > 0 else ""]
			if z["guichet_min"] <= 0.0:
				zoo_line += "\n[color=#f08080]Personne au guichet : les visiteurs attendent dehors ![/color]"
		else:
			zoo_line = "[color=#f08080]Zoo fermé[/color] : %s" % z["reason"]
		if not game.day_bonus.is_empty():
			zoo_line += "\nBonus du jour : %s (%s)" % [game.day_bonus["nom"], game.day_bonus["texte"]]
		var who := ("[b]%s[/b] — %s\n" % [mt.names[game.index], "partie terminée" if mt.game_over else "jour %d" % mt.day]) if spectator else ""
		info_text.text = who + "[b]Aucune sélection[/b]\n%s\n\n[color=#9aa0ab]Déployez un ouvrier depuis votre main, puis clic droit sur une forêt, une roche, un chantier ou la case Accès (lobbying). Postes : Marchand sur le camp, Vendeur sur une boutique, Soigneur dans un enclos.[/color]\n\nGraine de la carte : %d\nDeck : %d   Défausse : %d" % [zoo_line, game.seed_value, game.deck.size(), game.discard.size()]
		return
	if selected.size() > 1:
		var lines: Array[String] = ["[b]%d ouvriers[/b]" % selected.size()]
		for w in selected:
			lines.append("%s : %s" % [w.card.nom, _task_text(w)])
		info_text.text = "\n".join(lines)
		return
	var w: GameState.Worker = selected[0]
	var c := w.card
	var team := game.aura_mult(w)
	var auras: Array[String] = []
	for a in game.auras_of(c):
		auras.append("%+d %% aux autres (rayon %s)" % [roundi(float(a["bonus"]) * 100), str(a["rayon"])])
	info_text.text = "\n".join([
		"[b]%s[/b]" % c.nom,
		"[color=#e9b949]%s · Niv. %d[/color]" % [c.metier["nom"], c.niveau],
		_traits_bbcode(c),
		"",
		"Tâche : %s" % _task_text(w),
		"Charge : %.1f / %d" % [w.carry, game.carry_capacity(c)],
		"",
		"Vitesse : %.2f case/s" % game.speed(c),
		"Bois : x%.2f   Pierre : x%.2f" % [game.efficiency(c, "extraire_bois"), game.efficiency(c, "extraire_pierre")],
		"Or : x%.2f   Lobbying : x%.2f" % [game.efficiency(c, "extraire_or"), game.efficiency(c, "lobbying")],
		"Construire bois x%.2f   pierre x%.2f" % [game.efficiency(c, "construire_bois"), game.efficiency(c, "construire_pierre")],
		"Aménager x%.2f   Routes x%.2f" % [game.efficiency(c, "amenager"), game.efficiency(c, "construire_route")],
		"Bonus d'équipe reçu : %+d %%" % roundi((team - 1.0) * 100),
		("Effet de zone : " + ", ".join(auras)) if not auras.is_empty() else "",
		"Salaire : %d" % game.salary(c),
		"Expérience : %.1f / %d jours (niveau suivant)%s" % [c.xp, roundi(game.xp_next_level(c)),
			"  ×%.1f" % game.xp_mult(c) if game.xp_mult(c) != 1.0 else ""] if c.niveau < 4 else "Niveau maximum",
	])


func _update_hud() -> void:
	lbl_day.text = "Jour %d" % game.day
	var left := maxf(0.0, game.day_length - game.time)
	lbl_timer.text = "%d:%02d" % [int(left) / 60, int(left) % 60]
	timebar.value = 100.0 * game.time / game.day_length
	lbl_res.text = "Réputation %d/%d   Argent %d   Bois %d   Pierre %d   Or %d   Influence %.1f   Logement %d/%d   Deck %d/%d" % [
		game.reputation(), game.objective(), floori(game.money), floori(game.stock["bois"]), floori(game.stock["pierre"]),
		floori(game.stock["or"]), game.influence, game.employees(), game.housing(), game.deck.size(), game.discard.size()]

	var now := Time.get_ticks_msec()
	game.messages = game.messages.filter(func(m): return now - m["at"] < 4000)
	if game.messages.size() > 3:
		game.messages = game.messages.slice(-3)
	var sig := "|".join(game.messages.map(func(m): return "%s%d" % [m["text"], m["at"]]))
	if sig != toast_signature:
		toast_signature = sig
		for c in toast_box.get_children():
			c.queue_free()
		for m in game.messages:
			var l := Label.new()
			l.text = m["text"]
			l.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0.75), Color(0, 0, 0, 0), 6))
			toast_box.add_child(l)

	var hover := _hover_tile()
	var m := game.map
	var status := ""
	var site := game.site_at(hover) if m.in_bounds(hover.x, hover.y) else null
	if build_choice.get("kind") == "animal":
		var ev := _enc_eval(hover)
		var tiles = ev["enc"]["tiles"] if ev["enc"]["closed"] else null
		var req := _requirements_text(build_choice["def"], tiles)
		var plain := RegEx.create_from_string("\\[[^\\]]*\\]").sub(req, "", true)
		status = "%s — %s" % [build_choice["def"]["nom"], plain]
		status += ("  —  " + ev["err"]) if ev["err"] != "" else "  —  clic gauche pour installer"
	elif not build_choice.is_empty():
		var def: Dictionary = build_choice["def"]
		var err := game.placement_error(build_choice["kind"], def, _build_origin(hover))
		status = "%s : %s, travail %d" % [def["nom"], game.cost_text(def.get("cout", {})), int(def["travail"])]
		if err != "":
			status += "  —  " + err
	elif site and game.phase == "day":
		if site.done:
			status = site.def["nom"]
			if site.def_id() == "mine":
				status += " : clic droit pour extraire de l'or"
			elif site.def_id() == "entree":
				status += " : clic droit pour tenir le guichet (sans personne, les visiteurs n'entrent pas ; un Guichetier va 2x plus vite)"
			elif site.def_id() == "boutique":
				status += " : clic droit pour tenir la boutique (un Vendeur double les ventes)"
		else:
			status = "Chantier %s : %d / %d — clic droit pour y travailler" % [site.def["nom"], int(site.work), int(site.travail())]
	elif m.in_bounds(hover.x, hover.y) and game.phase == "day":
		if hover == m.exit_tile:
			status = "Accès route : clic droit pour envoyer en lobbying"
		elif m.in_camp(hover.x, hover.y) and selected.any(func(w): return w.card.metier["id"] == "marchand"):
			status = "Camp : clic droit pour que le Marchand tienne le comptoir (vente au plein tarif)"
		elif game.animal_at(hover) and selected.any(func(w): return w.card.metier["id"] == "soigneur"):
			status = "%s : clic droit pour que le Soigneur s'en occupe (+%d visiteurs ce soir)" % [game.animal_at(hover).def["nom"], int(game.data["buildings"]["zoo"]["bonus_soigneur"])]
		elif m.in_camp(hover.x, hover.y):
			status = "Camp de base (dépôt des ressources)"
		else:
			status = terrain_noms[m.get_t(hover.x, hover.y)]
			var res := m.extractible(hover.x, hover.y)
			if res == "or":
				status += " : construisez la mine d'or dessus"
			elif res != "":
				status += " (%d restants) : clic droit pour extraire du %s" % [roundi(m.res_left[m.idx(hover.x, hover.y)]), res_noms[res]]
			elif not m.passable(hover.x, hover.y):
				status += " : infranchissable"
			if m.road[m.idx(hover.x, hover.y)]:
				status += " (route : vitesse x2)"
	status_label.text = status
	status_label.visible = status != ""

	night_root.visible = game.phase == "night"


func _rebuild_night() -> void:
	if game.phase != "night" or game.night_report.is_empty():
		return
	var r := game.night_report
	var s: Dictionary = r["stats"]
	night_title.text = ("Fin de partie : %s gagne avec %d de réputation" % [mt.names[mt.winner], mt.players[mt.winner].reputation()]) \
		if mt.game_over else "Nuit du jour %d" % r["day"]
	var lines: Array[String] = []
	lines.append("%d ouvrier(s) déployé(s) · ramené au camp : bois %d, pierre %d, or %d · influence gagnée %.1f (total %.1f)" % [
		r["deployed"], floori(s["bois"]), floori(s["pierre"]), floori(s["or"]), s["influence"], game.influence])
	for nm in r["arrivals"]:
		lines.append("[color=#7fc97f]Arrivée au zoo : %s[/color]" % nm)
	lines.append("Réputation : [b]%d / %d[/b]" % [game.reputation(), game.objective()])
	if not r["level_ups"].is_empty():
		var lv: Array[String] = []
		for c in r["level_ups"]:
			lv.append("%s → niv. %d" % [c.nom, c.niveau])
		lines.append("Montées de niveau : " + ", ".join(lv) + " [color=#9aa0ab](choisissez leurs améliorations plus bas)[/color]")
	var order := ", ".join(mt.night_order.map(func(i): return mt.names[i]))
	var inc: Dictionary = r["income"]
	if inc["visitors"] > 0:
		lines.append("[color=#7fc97f]Zoo : %d visiteurs entrés (%d repartis faute de place dans la file) · billets %d · souvenirs %d[/color]" % [
			inc["visitors"], inc["lost"], inc["tickets"], inc["souvenirs"]])
		lines.append("Fréquentation moyenne : %.1f visiteurs dans le zoo → [b]+%.1f de réputation[/b]%s" % [inc["avg_present"], inc["rep_gain"],
			" (dont affinités de continent +%d %%)" % roundi(inc.get("affinity", 0.0) * 100) if inc.get("affinity", 0.0) > 0.0 else ""])
	else:
		lines.append("[color=#f08080]Aucun visiteur : %s[/color]" % inc["reason"])
	lines.append("\nOrdre de passage au marché (selon l'influence, valeurs cachées) : [b]%s[/b]" % order)
	var scores: Array[String] = []
	for i in mt.players.size():
		var pl := mt.players[i]
		scores.append("%s : %d (%d animaux, attractivité %d)" % [mt.names[i], pl.reputation(), pl.animals.filter(func(a): return a.arrived).size(), pl.attractiveness()])
	lines.append("Réputation des zoos : " + " · ".join(scores))
	for l in mt.log:
		lines.append("[color=#e9b949]%s[/color]" % l)
	lines.append("Argent : %d · Logement : %d / %d" % [floori(game.money), game.employees(), game.housing()])
	if game.employees() >= game.housing():
		lines.append("[color=#f08080]Logement plein : construisez une maison d'ouvriers pour pouvoir embaucher.[/color]")
	night_text.text = "\n".join(lines)
	night_next.disabled = mt.game_over

	for c in night_workers.get_children():
		c.queue_free()
	for card in game.market_workers:
		var err := game.hire_error(card)
		var w := _card_widget(card, "Embaucher (%d)" % game.hire_cost(card), err != "", game.hire.bind(card))
		w.tooltip_text = (err + "\n" if err != "" else "") + w.tooltip_text
		night_workers.add_child(w)
	for c in night_contracts.get_children():
		c.queue_free()
	for def in game.market_contracts:
		var err := game.contract_error(def)
		night_contracts.add_child(_contract_widget(def, "Acheter", err, game.buy_contract.bind(def)))
	for c in night_actions.get_children():
		c.queue_free()
	for card in mt.market_actions:
		var aerr := game.action_error(card)
		var aw := _action_widget(card, "Acheter (%d)" % int(card.action["cout"]), spectator or aerr != "", game.buy_action.bind(card))
		aw.tooltip_text = aerr
		night_actions.add_child(aw)
	# Bonus de nuit
	for c in night_bonus_box.get_children():
		c.queue_free()
	var leader := mt.influence_leader()
	for b in mt.bonus_offer:
		var btn := Button.new()
		var chosen: bool = mt.bonus_choice == b
		btn.text = "%s\n%s" % [b["nom"], b["texte"]] + ("\n✔ choisi par %s" % mt.names[leader] if chosen else "")
		if chosen:
			btn.add_theme_color_override("font_disabled_color", UiTokens.SELECTION)
		btn.disabled = spectator or game.bonus_error(b) != ""
		btn.tooltip_text = game.bonus_error(b)
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(200, 0)
		btn.pressed.connect(game.pick_bonus.bind(b))
		night_bonus_box.add_child(btn)
	# Montées de niveau : une amélioration gratuite à choisir par niveau gagné
	for c in night_level_rows.get_children():
		c.queue_free()
	night_level_box.visible = not spectator and not game.level_choices.is_empty()
	for lc in game.level_choices:
		var card: GameState.Card = lc["card"]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var who := Label.new()
		who.text = "%s (%s, niv. %d)" % [card.nom, card.metier["nom"], card.niveau]
		who.custom_minimum_size = Vector2(220, 0)
		row.add_child(who)
		for opt in lc["options"]:
			var ob := Button.new()
			ob.text = "%s\n%s" % [opt["nom"], opt.get("texte", _effect_text(opt["effet"]))]
			ob.focus_mode = Control.FOCUS_NONE
			ob.pressed.connect(game.choose_level_upgrade.bind(card, opt))
			row.add_child(ob)
		night_level_rows.add_child(row)
	# Action de milieu de partie : améliorer ou licencier
	var rules := game.night_action_rules()
	var cost_up := int(rules["cout_amelioration"])
	var cost_fire := int(rules["cout_licenciement"])
	var act_err := game.night_action_error(mini(cost_up, cost_fire))
	night_action_box.visible = not spectator
	for c in night_action_flow.get_children():
		c.queue_free()
	for c in night_upgrade_box.get_children():
		c.queue_free()
	if act_err != "":
		var l := Label.new()
		l.text = act_err
		l.modulate = Color(1, 1, 1, 0.6)
		night_action_flow.add_child(l)
	else:
		for card in game.all_employees():
			var b := Button.new()
			b.text = "%s (%s, niv. %d)" % [card.nom, card.metier["nom"], card.niveau]
			b.toggle_mode = true
			b.button_pressed = card == action_card
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(func():
				action_card = card
				hand_version = -1)
			night_action_flow.add_child(b)
		if action_card and game.all_employees().has(action_card):
			for opt in game.upgrade_options(action_card):
				var ub := Button.new()
				ub.text = "Améliorer : %s (%d)\n%s" % [opt["nom"], cost_up, opt.get("texte", _effect_text(opt["effet"]))]
				ub.disabled = game.night_action_error(cost_up) != ""
				ub.focus_mode = Control.FOCUS_NONE
				ub.pressed.connect(func():
					game.apply_upgrade(action_card, opt)
					action_card = null)
				night_upgrade_box.add_child(ub)
			var fb := Button.new()
			fb.text = "Licencier (%d)" % cost_fire
			fb.disabled = game.night_action_error(cost_fire) != ""
			fb.focus_mode = Control.FOCUS_NONE
			fb.pressed.connect(func():
				game.fire_paid(action_card)
				action_card = null)
			night_upgrade_box.add_child(fb)
	night_fire_box.visible = game.drh_available > 0
	for c in night_fire.get_children():
		c.queue_free()
	for card in game.all_employees():
		var b := Button.new()
		b.text = "%s (%s)" % [card.nom, card.metier["nom"]]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(game.fire.bind(card))
		night_fire.add_child(b)


func _effect_text(fx: Dictionary) -> String:
	var parts: Array[String] = []
	for k in fx:
		var v := float(fx[k])
		parts.append("%s %s" % [k, ("%+d" % int(v)) if k == "salaire" else ("+%d %%" % roundi((v - 1.0) * 100))])
	return ", ".join(parts)


## Nom lisible d'une exigence : « Prairie », ou « Eau près de Prairie » pour un motif d'adjacence.
func _req_name(key: String) -> String:
	if "-" in key:
		var ab := key.split("-")
		return "%s près de %s" % [terrain_req_noms[ab[0]], terrain_req_noms[ab[1]].to_lower()]
	return terrain_req_noms[key]


func _requirements_text(def: Dictionary, tiles = null) -> String:
	if tiles == null:
		return "≥ %d cases, motif de %d cases" % [int(def["taille"]), def["motif"].size()]
	var size_ok: bool = tiles.size() >= int(def["taille"])
	var ps := game.pattern_status(def, tiles)
	var parts: Array[String] = []
	parts.append("[color=%s]%s %d / %d cases[/color]" % ["#7fc97f" if size_ok else "#f08080", "✓" if size_ok else "✗", tiles.size(), int(def["taille"])])
	if ps["found"]:
		parts.append("[color=#7fc97f]✓ motif présent[/color]")
	elif ps["missing"] < 99:
		parts.append("[color=#f08080]✗ motif : %d case(s) à aménager (en orange)[/color]" % ps["missing"])
	else:
		parts.append("[color=#f08080]✗ motif : enclos trop étroit[/color]")
	return " · ".join(parts)


## Petit dessin du motif d'un animal (cases colorées selon le terrain).
func _pattern_view(def: Dictionary, cell := 14.0) -> Control:
	var view := Control.new()
	var w := 0
	var h := 0
	for c in def["motif"]:
		w = maxi(w, int(c[0]) + 1)
		h = maxi(h, int(c[1]) + 1)
	view.custom_minimum_size = Vector2(w, h) * cell + Vector2(2, 2)
	view.mouse_filter = Control.MOUSE_FILTER_PASS
	view.draw.connect(func():
		for c in def["motif"]:
			var r := Rect2(Vector2(int(c[0]), int(c[1])) * cell + Vector2(1, 1), Vector2(cell - 2, cell - 2))
			view.draw_rect(r, terrain_colors[GameMap.TERRAINS.find(str(c[2]))])
			view.draw_rect(r, Color(0, 0, 0, 0.5), false, 1.0))
	var names: Array[String] = []
	for c in def["motif"]:
		names.append(terrain_noms[GameMap.TERRAINS.find(str(c[2]))])
	view.tooltip_text = "Motif à reproduire dans l'enclos (rotations et miroirs acceptés) : " + ", ".join(names)
	return view


func _contract_widget(def: Dictionary, button_text: String, err: String, cb: Callable) -> Control:
	var biome: String = def["biome"]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("2a2e38"), biome_colors[biome].darkened(0.3), 8))
	var v := VBoxContainer.new()
	panel.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var n := Label.new()
	n.text = def["nom"]
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(n)
	var tier := Label.new()
	tier.text = def["palier"]
	tier.modulate = Color(1, 1, 1, 0.6)
	top.add_child(tier)
	var b := Label.new()
	b.text = biome_noms[biome] + (" · prédateur" if def.get("special", "") == "predateur" else "")
	b.add_theme_color_override("font_color", biome_colors[biome])
	b.add_theme_font_size_override("font_size", 13)
	v.add_child(b)
	var info := RichTextLabel.new()
	info.bbcode_enabled = true
	info.fit_content = true
	info.scroll_active = false
	info.custom_minimum_size = Vector2(230, 0)
	info.add_theme_font_size_override("normal_font_size", 12)
	info.mouse_filter = Control.MOUSE_FILTER_PASS
	var gold_missing := game.contract_gold_missing(def)
	var same_continent := game.animals.filter(func(a): return a.def.get("continent", "") == def.get("continent", "")).size()
	info.text = "[b]%s[/b] · %s%s\nEnclos : %s\nAttractivité [b]%d[/b] · nourriture %d / jour\nCoût : %s%s" % [
		game.continent_name(def.get("continent", "")), game.type_name(def.get("type", "")),
		" · [color=#7cf29a]affinité +5 %% (%d animal(aux) du même continent)[/color]" % same_continent if same_continent > 0 else "",
		_requirements_text(def), int(def["reputation"]), game.food_cost(def), game.cost_text(game.contract_cost(def)),
		"\n[color=#ffd45a]Or manquant (%d) acheté : %d argent au total[/color]" % [gold_missing, int(game.contract_payment(def)["argent"])] if gold_missing > 0 else ""]
	v.add_child(_pattern_view(def))
	v.add_child(info)
	var btn := Button.new()
	btn.text = button_text
	btn.disabled = err != ""
	btn.tooltip_text = err
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(cb)
	v.add_child(btn)
	return panel


func _rebuild_contracts() -> void:
	for c in contracts_box.get_children():
		c.queue_free()
	if game.contracts.is_empty():
		var l := Label.new()
		l.text = "Aucun. Achetez-en au marché de nuit."
		l.add_theme_font_size_override("font_size", 12)
		l.modulate = Color(1, 1, 1, 0.6)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		contracts_box.add_child(l)
		return
	for def in game.contracts:
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", biome_colors[def["biome"]])
		b.text = "%s (%s)\n   Installer dans un enclos" % [def["nom"], biome_noms[def["biome"]]]
		b.tooltip_text = "Enclos fermé par des clôtures d'enclos terminées.\n" + _requirements_text(def).replace("[b]", "").replace("[/b]", "")
		b.button_pressed = build_choice.get("def") == def
		b.pressed.connect(func():
			if build_choice.get("def") == def:
				_set_build({})
			else:
				_set_build({"kind": "animal", "def": def})
				selected.clear())
		contracts_box.add_child(b)
