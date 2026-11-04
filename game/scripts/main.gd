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
##   --pioche        ouvre la vue de la pioche et de la défausse
##   --etape=nom     avec --endday : avance la nuit jusqu'à l'étape (contrats, ouvriers, cartes, bonus, equipe)
##   --contrat[=id]  ajoute un contrat (girafe…) et passe en mode installation d'animal (avec --autoplay --autozoo)
##   --cadre         ajoute un cadre à la main (bouton « Jouer »)
##   --un            avec --autoplay : un seul ouvrier sélectionné (panneau d'unité)
##   --zoom=2.5      zoom de la caméra (captures de détail)
##   --jours=N       spectateur : avance de N jours avant d'afficher

const TILE := 16.0
const TEXTE_NET := 4.0  # les textes du monde sont écrits 4 fois plus grands, puis réduits

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
	"snack": Color("E8782A"), "kiosque": Color("8A4AD0"), "comptoir": Color("D8A010"), "agence": Color("4A7AC8"), "cabinet": Color("6A3AB0"), "camp_n2": Color("A0743C"), "camp_n3": Color("B8864A"),
	"grand_arbre": Color("2E7A2C"), "rocher_obs": Color("8E8A80"), "bassin_profond": Color("2B86D2"), "abri_chaud": Color("C0703A"),
}
var building_short := {
	"maison": "Maison", "entrepot": "Entrepôt", "comptoir": "Marché", "agence": "Intérim", "cabinet": "Recrutement", "mine": "Mine", "entree": "Entrée", "boutique": "Boutique", "formation": "Formation",
	"cuisine": "Cuisine", "entretien": "Entretien", "snack": "Snack", "kiosque": "Kiosque",
	"camp_n2": "Camp niv. 2", "camp_n3": "Camp niv. 3",
	"grand_arbre": "Grand arbre", "rocher_obs": "Rocher", "bassin_profond": "Bassin profond", "abri_chaud": "Abri chauffé",
}

var mt: Match
var game: GameState  # le joueur affiché (vous, ou la première IA en mode spectateur)
var spectator := false
var view_buttons: Array = []
var night_clock := 0.0
var last_phase := ""
var args := {}
var font: Font
var font_noms: Font  # noms sur la carte : Bangers, lettrage de BD
var camera: Camera2D
var terrain_sprite: Sprite2D
var carte: CarteBD  # rendu BD de la carte : sol, routes, décor (scripts/rendu/)
var _occupation_version := -1
var terrain_img: Image
var depth_img: Image

var selected: Array = []
var selected_site: GameState.Site = null
var selected_sites: Array = []  # sélection multiple de bâtiments et chantiers (rectangle) : Suppr les démolit ou les annule
var selected_animal: GameState.Animal = null
# Aide au placement d'un animal : enclos possibles (motif en vert / orange) et enclos proposé
var animal_hints: Array = []
var enclosure_proposal := {}
var proposal_box: PanelContainer
var proposal_pattern: CenterContainer
var proposal_label: RichTextLabel
var proposal_btn: Button
var info_extra: VBoxContainer  # sous le texte du panneau de droite : motif de l'animal sélectionné
var info_extra_for: Variant = null
var build_choice := {}  # {"kind": "batiment"|"amenagement", "def": {...}} pendant le placement
var painting := false
var last_paint := Vector2i(-99, -99)
var build_buttons := []  # [Button, kind, def]
var drag_start: Variant = null  # position écran du début de sélection
var drag_end := Vector2.ZERO
var drag_add := false
var drag_sites := false  # Ctrl + glisser : bâtiments et chantiers seulement
var last_click := {"at": 0, "tile": Vector2i(-99, -99)}  # double-clic sur un tracé
var panning := false
var speed := 1.0
var acc := 0.0
var info_clock := 0.0
var ai_timer := 0.0
var hand_version := -1
var images := {}  # chemin -> texture des illustrations (animaux, bâtiments), ou null si absente
var facing := {}  # Worker -> [vue ("face", "profil", "dos"), miroir, dernière position]
var toast_signature := ""
var night_shown_for := -1
var frame_count := 0

# Interface
var ui: Control
var speed_buttons := {}
var info_text: RichTextLabel
var info_view: VBoxContainer  # fiche structurée du panneau de droite
var info_subtitle: Label
var info_sig := ""
var btn_lobby: Button
var btn_swap: Button
var btn_recall: Button
var btn_cancel_site: Button
var btn_demolish: Button
var hand_box: HBoxContainer
var deploy_all_btn: Button
var rotate_btn: Button  # « Tourner (R) » pendant la pose d'un bâtiment non carré
var toast_box: VBoxContainer
var status_label: Label
var night_root: Control
var night_title: Label
var night_text: RichTextLabel
var night_workers: Container
var night_contracts: Container
var night_fire_box: Control
var night_bonus_box: VBoxContainer
var night_actions: Container
var night_pages := {}  # étape de la nuit -> page du centre
var night_stage_title: Label
var night_stage_note: Label
var night_level_box: Control
var night_level_rows: VBoxContainer
var night_action_box: Control
var night_action_flow: VBoxContainer
var action_card: GameState.Card = null
var event_label: Label
var hover_card: Control  # carte affichée au survol d'un nom d'ouvrier
var hover_src: Control
var trade_rows := {}  # ressource -> [SpinBox, bouton Vendre, bouton Acheter]
var label_buttons := {}  # label (id) -> bouton d'achat (en or, prix doublé sans Marchand)
var trade_note: Label
var trade_card: Control  # carte « Bourse des ressources » du panneau de droite
var tutoriel: Tutoriel  # tutoriel scénarisé en cours
var menu_btn: Button
var reseau: Reseau  # partie multijoueur en cours (null en solo)
var partie_reseau := {}
var bandeau_multi: Label
var a_selectionner: GameState.Card  # carte mobilisée, en attente de la trame qui fera apparaître l'ouvrier
var hubert: BulleHubert  # Hubert à l'écran (joueur humain, hors tutoriel)
var hubert_dit := {}  # alertes déjà annoncées aujourd'hui
var hubert_ouverture := false
var marche_phase := {}  # ouvrier -> avancement de son cycle de marche
var memo_lignes := {}  # jour -> réplique d'Hubert du mémo du soir
var pub_note: Label
var pub_buttons := {}  # id de campagne -> bouton
# Choix d'un ouvrier (cartes Rupture de contrat et Promotion, échange à l'Agence d'intérim)
var picker_root: ColorRect
var picker_box: VBoxContainer
var picker_speed := -1.0  # vitesse à rétablir en refermant le choix (la journée est en pause pendant le choix)
var night_fire: VBoxContainer
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
var pile_root: ColorRect  # vue de la pioche et de la défausse (clic sur la pioche)
var pile_box: VBoxContainer
var loan_btn: Button
var medallion: Control
var end_day_btn: Button
var build_pages := {}
var build_tabs := {}
var pile_panel: PanelContainer
var hand_scroll: ScrollContainer
var unit_panel: PanelContainer
var unit_stars: Label
var unit_traits: HFlowContainer
var unit_task: Label
var unit_bar: ProgressBar
var unit_orders: Array[Button] = []
var action_mode := "up"  # « up » : améliorations proposées ; « fire » : confirmation du licenciement
# Nuit et fin de partie (captures 05 et 06)
var night_steps: HBoxContainer
var night_summary: VBoxContainer
var night_influence: HBoxContainer
var night_money_lbl: Label
var night_contracts_note: Label
var night_rep_rows: VBoxContainer
var night_bonus_note: Label
var end_root: ColorRect
var end_reopen: Button
var end_built := false
var night_peek := false  # la nuit, « Voir mon zoo » masque l'écran du marché
var night_return: Button
var peek_panel: PanelContainer  # la nuit, « Voir mon zoo » : motifs des contrats du marché
var peek_list: VBoxContainer
var peek_version := -1
var peek_hint := {}  # contrat montré sur la carte : {"def", "tiles", "missing"}
var night_chips := {}
var day_hud: Array[Control] = []  # masqués la nuit et sur l'écran de fin
var end_dismissed := false
var end_views: HBoxContainer  # carte finale : un bouton par joueur pour voir son zoo
## Relance demandée par l'écran de fin (« jouer », « spectateur », « menu ») : survit au rechargement de la scène.
static var relance := ""
static var relance_difficile := false  # « Rejouer » garde la difficulté choisie


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	font = UiTokens.police_corps(600)
	if font is FontVariation and font.base_font is FontFile:
		font.base_font.generate_mipmaps = true  # réduit sans scintiller (voir _ecrire)
	font_noms = load("res://assets/bd/polices/Bangers-Regular.ttf")
	font_noms.generate_mipmaps = true
	if relance != "":
		var mode := relance
		relance = ""
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		args.erase("seed")
		if relance_difficile and mode != "menu":
			args["difficile"] = ""
		if mode == "menu":
			_show_menu()
		else:
			_start(mode == "spectateur")
		return
	# icônes SVG du monde lissées quand on dézoome
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Test du multijoueur : un joueur automatique héberge ou rejoint (tests/mp_auto.gd)
	if args.has("mp-hote") or args.has("mp-rejoindre"):
		add_child(load("res://tests/mp_auto.gd").new(self))
		return
	# Arguments de test : on démarre directement. Sinon, menu de lancement.
	if args.has("spectateur") or args.has("autodraft") or args.has("autoplay") or args.has("joueurs") or args.has("tutoriel"):
		_start(args.has("spectateur"))
	else:
		_show_menu()


## Menu principal (MenuPrincipal) : la carte de la graine choisie en fond, réglages de la partie à droite.
func _show_menu() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var menu := MenuPrincipal.new()
	layer.add_child(menu)
	menu.multijoueur.connect(func(): _ouvrir_salon(layer))
	if args.has("salon"):
		_ouvrir_salon(layer)
	menu.tutoriel.connect(func():
		args["tutoriel"] = ""
		layer.queue_free()
		_start(false))
	menu.continuer.connect(func():
		args["charger"] = ""
		layer.queue_free()
		_start(false))
	menu.lancer.connect(func(watch: bool, graine: int, adversaires: int, difficile: bool):
		args["seed"] = str(graine)
		if difficile:
			args["difficile"] = ""
		args["joueurs"] = str(4 if watch else adversaires + 1)
		layer.queue_free()
		_start(watch))


## Salon multijoueur par-dessus le menu ; la partie démarre quand l'hôte la lance (--salon : ouvert d'office, pour les captures).
func _ouvrir_salon(layer: CanvasLayer) -> void:
	var r := Reseau.new()
	r.name = "Reseau"  # même chemin sur toutes les machines : les messages réseau en dépendent
	add_child(r)
	var salon := Salon.new(r)
	layer.add_child(salon)
	salon.retour.connect(func():
		salon.queue_free()
		r.queue_free())
	r.demarrage.connect(func(params: Dictionary):
		reseau = r
		partie_reseau = params
		layer.queue_free()
		_start(false))


## Multijoueur : le bandeau d'information, les boutons « prêt », la vitesse commune. Hôte parti : retour au menu.
func _maj_multijoueur() -> void:
	if bandeau_multi == null:
		bandeau_multi = Label.new()
		bandeau_multi.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		bandeau_multi.offset_top = 62
		bandeau_multi.grow_horizontal = Control.GROW_DIRECTION_BOTH
		bandeau_multi.add_theme_stylebox_override("normal", UiTokens.panel(UiTokens.BOUTON_HAUT, UiTokens.ENCRE, 8, 2, 4))
		bandeau_multi.add_theme_font_override("font", UiTokens.police_corps(700))
		bandeau_multi.add_theme_font_size_override("font_size", 15)
		bandeau_multi.add_theme_color_override("font_color", UiTokens.ENCRE)
		bandeau_multi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var calque := CanvasLayer.new()
		calque.layer = 14
		add_child(calque)
		calque.add_child(bandeau_multi)
		event_label.offset_top = 96
		if hubert:
			hubert.haut = 104.0
		reseau.coupure.connect(func(t):
			game.say(t)
			_restart("menu"))
	if a_selectionner and game.worker_of(a_selectionner):
		selected = [game.worker_of(a_selectionner)]
		a_selectionner = null
	var e: Dictionary = reseau.etat
	var morceaux: Array[String] = []
	if reseau.desynchro:
		morceaux.append("ATTENTION : les parties ne sont plus identiques sur toutes les machines")
	if int(e.get("prep", 0)) > 0:
		morceaux.append("Préparation : %d s" % int(e["prep"]))
	if int(e.get("delai", 0)) > 0:
		morceaux.append("Temps pour choisir : %d s" % int(e["delai"]))
	if mt.phase == "day":
		morceaux.append("Vitesse ×%d" % int(e.get("vitesse", 1.0)))
	bandeau_multi.text = "  " + " · ".join(morceaux) + "  "
	bandeau_multi.visible = not morceaux.is_empty() and not mt.game_over
	var prets := "%d/%d" % [int(e.get("prets", 0)), int(e.get("humains", 1))]
	if mt.phase == "day":
		end_day_btn.text = ("EN ATTENTE (%s)" if reseau.est_pret else "JE SUIS PRÊT (%s)") % prets
	elif mt.phase == "night" and mt.night_stage == "equipe" and night_next:
		night_next.text = ("En attente des autres (%s)" if reseau.est_pret else "Je suis prêt (%s)  ›") % prets
		night_next.disabled = mt.game_over


## Stratégies des IA en mode spectateur (mêmes réglages que les simulations d'équilibrage).
const WATCH_STRATEGIES := [
	{"nom": "Rush or", "rush_or": true}, {"nom": "Grand parc", "taille_zoo": "grand"},
	{"nom": "Parc évolutif", "taille_zoo": "evolutif"}, {"nom": "Gros contrats", "preference_palier": 2.2, "reserve": 15},
]


func _start(watch: bool) -> void:
	spectator = watch
	var map_seed: int = int(args["seed"]) if args.has("seed") else randi() % 1000000000
	var nb := int(args.get("joueurs", "4"))
	var local := 0
	var autres_humains: Array = []
	if reseau:
		map_seed = int(partie_reseau["graine"])
		nb = int(partie_reseau["nb"])
		local = int(partie_reseau["index"])
		for i in partie_reseau["humains"].size():
			if i != local:
				autres_humains.append(i)
		if partie_reseau["difficile"]:
			args["difficile"] = ""
	if args.has("tutoriel"):
		map_seed = Tutoriel.GRAINE
		nb = 4
	var strategies: Array = WATCH_STRATEGIES if spectator else []
	# --difficile (ou choix du menu) : les IA jouent les stratégies apprises par l'IA évolutive
	if args.has("difficile") and FileAccess.file_exists("res://data/ia_difficile.json"):
		var hard: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/ia_difficile.json"))["strategies"]
		strategies = []
		for i in nb:
			var humain: bool = (i == 0 and not spectator) if reseau == null else (i == local or autres_humains.has(i))
			strategies.append(null if humain else hard[(i - (0 if spectator else 1)) % hard.size()])
	var charge: Match = Sauvegarde.charger(GameData.load_all()) if args.has("charger") else null
	mt = charge if charge else Match.new(GameData.load_all(), map_seed, nb, -1 if spectator else local, strategies, autres_humains)
	mt.autosave = not spectator and not args.has("shot") and not args.has("tutoriel") and reseau == null
	if args.has("tutoriel"):
		Tutoriel.preparer(mt)
	elif not spectator and charge == null:
		# Chacun dirige ZooLife sur son écran ; les autres sont les groupes rivaux, avec le nom de l'ami qui les dirige
		var H: Dictionary = mt.data["hubert"]
		var r := 0
		for k in mt.names.size():
			if k == local:
				mt.names[k] = "%s (vous)" % H["entreprise"]
			else:
				var groupe: String = H["rivaux"][r % H["rivaux"].size()]
				r += 1
				mt.names[k] = "%s (%s)" % [groupe, partie_reseau["humains"][k]["pseudo"]] if reseau and k < partie_reseau["humains"].size() else groupe
	game = mt.players[local]
	RenderingServer.set_default_clear_color(UiTokens.FOND_ECRAN)
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
	if reseau:
		reseau.attacher(self, mt)
	if not spectator and not args.has("tutoriel"):
		var h_layer := CanvasLayer.new()
		h_layer.layer = 15
		add_child(h_layer)
		hubert = BulleHubert.new(mt.data["hubert"], hand_box)
		h_layer.add_child(hubert)
	if args.has("tutoriel"):
		var tuto_layer := CanvasLayer.new()
		tuto_layer.layer = 20
		add_child(tuto_layer)
		tutoriel = Tutoriel.new(self, args.has("tuto-auto"), args.get("tuto-dossier", ""))
		tuto_layer.add_child(tutoriel)
	if charge:
		Sauvegarde.reprendre(mt)
		_set_speed(0.0)
	if args.has("autodraft") or spectator:
		while mt.phase == "draft":
			mt.pick_draft(mt.ai_choice())
	if args.has("autoplay"):
		_auto_play()
	# --contrat : ajoute un contrat de palier 1 et passe en mode installation (captures de l'aide au placement)
	if args.has("contrat"):
		var cid: String = args["contrat"]
		var cdef: Dictionary = game.data["animals"]["animaux"].filter(func(d): return d["id"] == cid if cid != "" else (d["palier"] == "T1" and d["id"] != "zebre"))[0]
		game.contracts.append(cdef)
		_set_build({"kind": "animal", "def": cdef})
	# --tourner : pose une entrée tournée (verticale) terminée près du camp et laisse l'outil en mode pose tournée
	if args.has("tourner"):
		_set_build({"kind": "batiment", "def": game.building_def("entree")})
		_rotate_build()
		game.stock["bois"] += 20
		game.stock["pierre"] += 20
		var gs: GameState.Site = null
		for dx in range(3, 12):
			if gs == null:
				gs = game.place("batiment", build_choice["def"], game.map.camp.position + Vector2i(dx, -2))
		if gs:
			gs.work = gs.travail()
			game._complete(gs)
	# --cadre : ajoute un cadre à la main (captures du bouton « Jouer »)
	if args.has("cadre"):
		game.hand.append(game.make_card("cadre"))
		game.version += 1
	# --aide : ouvre le tutoriel ; --aide=animaux : le glossaire des animaux (captures)
	if args.has("aide"):
		var aide := Aide.new(game.data)
		ui.add_child(aide)
		if args["aide"] == "animaux":
			aide.call_deferred("_glossaire_animaux")
	if args.has("pioche"):
		_open_pile()
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
		_refresh_terrain(true)
		_focus_zoo()
	# --perso=victor : tous les ouvriers prennent ce personnage (contrôle d'une nouvelle planche)
	if args.has("perso"):
		for pl in mt.players:
			for c in pl.all_employees():
				c.perso = args["perso"]
	# --hubert=licenciement : bulle d'Hubert ; --hubert=ev_greve : bulle d'événement ; --defaite : écran de fin (captures)
	if args.has("hubert") and hubert:
		hubert.annoncer(args["hubert"], {"nom": "Marcel", "effet": "Tous les salaires +1 aujourd'hui." if str(args["hubert"]).begins_with("ev_") else ""})
		hubert.annoncer("licenciement", {"nom": "Marcel"})
	if args.has("defaite"):
		mt.players[1].rep_points = 100.0
		mt.winner = 1
		mt.game_over = true
	# --zoom=2.5 : zoom de la caméra (captures de détail)
	if args.has("zoom"):
		camera.zoom = Vector2.ONE * float(args["zoom"])


# --- Terrain -----------------------------------------------------------------

func _build_terrain() -> void:
	# Rendu « BD néo ligne claire » : sol en shader, routes tracées, décor trié en Y (scripts/rendu/).
	if carte:
		carte.queue_free()
	carte = CarteBD.new()
	add_child(carte)
	move_child(carte, 0)
	carte.construire(game.map, TILE, game.seed_value)
	_occupation_version = -1


## Remplit les deux textures lues par le shader du terrain : le type de chaque case,
## et pour l'eau la distance au rivage (dégradé turquoise → bleu profond).
func _fill_terrain_images() -> void:
	var m := game.map
	var dist := PackedInt32Array()
	dist.resize(m.w * m.h)
	var front: Array[Vector2i] = []
	for y in m.h:
		for x in m.w:
			var t := m.get_t(x, y)
			terrain_img.set_pixel(x, y, Color8(t * 32, 0, 0))
			dist[m.idx(x, y)] = 0 if t != GameMap.EAU else 99
			if t != GameMap.EAU:
				front.append(Vector2i(x, y))
	while not front.is_empty():
		var nxt: Array[Vector2i] = []
		for p in front:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = p + d
				if m.in_bounds(q.x, q.y) and dist[m.idx(q.x, q.y)] > dist[m.idx(p.x, p.y)] + 1:
					dist[m.idx(q.x, q.y)] = dist[m.idx(p.x, p.y)] + 1
					nxt.append(q)
		front = nxt
	for y in m.h:
		for x in m.w:
			depth_img.set_pixel(x, y, Color(minf(dist[m.idx(x, y)] / 4.0, 1.0), 0, 0))


## Met à jour le terrain après un aménagement (ou un changement de zoo regardé).
## CarteBD détecte seule les cases modifiées ; un changement de zoo regardé la reconstruit.
func _refresh_terrain(force := false) -> void:
	game.terrain_changed.clear()
	if force:
		_build_terrain()


## Cases occupées (sans décor) et allées pavées de l'enceinte, mises à jour quand la partie change.
func _update_occupation() -> void:
	if carte == null or _occupation_version == game.version:
		return
	_occupation_version = game.version
	var bati := {}
	for st in game.sites:
		for y in range(st.rect.position.y, st.rect.end.y):
			for x in range(st.rect.position.x, st.rect.end.x):
				bati[Vector2i(x, y)] = true
	for a in game.animals:
		for t in a.tiles:
			if game.site_at(t) == null and not a.park:
				pass
	var pave := {}
	for t in game.zoo_status()["interior"]:
		pave[t] = true
	carte.occuper(bati, pave)


func _draw() -> void:
	if mt == null:
		return
	var m := game.map
	# Camp de base (sous les chantiers d'agrandissement)
	_draw_camp()
	_draw_affiche()
	# Routes, ponts et allées pavées : RoutesBD (scripts/rendu/) ; ici la mairie au bout de l'accès
	_update_occupation()
	var ex := Vector2(m.exit_tile) * TILE
	_draw_town_hall(ex + Vector2(TILE / 2, TILE * 3.6))
	# Intérieur de l'enceinte du zoo : allées plus claires
	for t in game.zoo_status()["interior"]:
		draw_rect(Rect2(Vector2(t) * TILE, Vector2(TILE, TILE)), Color(UiTokens.ALLEE_ZOO, 0.16))
	# Animaux : enclos teinté par biome, bêtes qui déambulent, marqueur du biome
	var now := Time.get_ticks_msec() / 1000.0
	for ai_index in game.animals.size():
		_draw_animal(game.animals[ai_index], ai_index, now)
	# Animaux réservés dans un enclos en chantier : ils n'arrivent qu'après la fin des clôtures et de l'aménagement
	for r in game.pending_installs:
		var rc := (Vector2(r["tile"]) + Vector2(0.5, 0.5)) * TILE
		draw_rect(Rect2(rc - Vector2(5, 4), Vector2(10, 8)), Color("A0743C", 0.7))
		draw_rect(Rect2(rc - Vector2(5, 4), Vector2(10, 8)), Color("5A3A22"), false, 1.0)
		_label("%s (arrive quand l'enclos sera fini)" % r["def"]["nom"], rc + Vector2(0, -12), 9)
	# Chantiers et bâtiments, du fond vers l'avant
	var sites_tries := game.sites.duplicate()
	sites_tries.sort_custom(func(a, b): return a.rect.end.y < b.rect.end.y)
	for s in sites_tries:
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
	# Visiteurs (tenues de couleurs variées) : sur la route, dans la file, dans le zoo
	var vpath := game.visitor_path()
	if not vpath.is_empty():
		for k in game.road_visitors.size():
			var d: float = game.road_visitors[k]
			var i := mini(int(d), vpath.size() - 1)
			var j := mini(i + 1, vpath.size() - 1)
			_draw_visitor((Vector2(vpath[i]).lerp(Vector2(vpath[j]), d - i) + Vector2(0.5, 0.5)) * TILE, k)
		var front := (Vector2(vpath[-1]) + Vector2(0.5, 0.5)) * TILE
		for q in game.visitor_queue:
			_draw_visitor(front + Vector2((q % 5) * 3.2 - 6.0, (q / 5) * 3.2 - 4.0), q + 3)
	for k in game.in_zoo.size():
		_draw_visitor(game.in_zoo[k]["pos"] * TILE, k + 7)
	# Gisements d'or encore libres
	for gold in m.golds:
		if game.site_at(gold) == null:
			_draw_pin((Vector2(gold) + Vector2(0.5, 0.3)) * TILE, "ressource_or", UiTokens.RESSOURCES["or"]["couleur"])

	# Chemins des ouvriers sélectionnés
	for w: GameState.Worker in selected:
		if w.offmap or w.path.is_empty():
			continue
		var pts := PackedVector2Array([w.pos * TILE])
		for p in w.path:
			pts.append((Vector2(p) + Vector2(0.5, 0.5)) * TILE)
		draw_polyline(pts, Color(1, 1, 1, 0.55), 1.5)

	# Ordres en file (Maj + clic droit) des ouvriers sélectionnés : numérotés, reliés en pointillés
	for w: GameState.Worker in selected:
		var prev := w.pos * TILE if w.path.is_empty() else (Vector2(w.path[-1]) + Vector2(0.5, 0.5)) * TILE
		for k in w.queue.size():
			var q := (Vector2(w.queue[k]) + Vector2(0.5, 0.5)) * TILE
			draw_dashed_line(prev, q, Color(UiTokens.SELECTION, 0.7), 1.0, 3.0)
			draw_circle(q, 4.2, Color(0, 0, 0, 0.6))
			draw_circle(q, 3.6, UiTokens.SELECTION)
			_ecrire(q + Vector2(-2.2, 2.4), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 7, Color("1E1406"))
			prev = q

	# Zone d'influence des ouvriers sélectionnés (Charismatique, Contremaître, Rabat-joie)
	for w: GameState.Worker in selected:
		if w.offmap:
			continue
		for a in game.auras_of(w.card):
			var col := Color(1, 0.85, 0.3, 0.6) if float(a["bonus"]) > 0 else Color(1, 0.45, 0.45, 0.6)
			draw_circle(w.pos * TILE, float(a["rayon"]) * TILE, Color(col, 0.08))
			draw_arc(w.pos * TILE, float(a["rayon"]) * TILE, 0, TAU, 48, col, 1.0)

	# Ouvriers : le personnage de leur carte (face, profil ou dos selon la marche), anneau couleur du joueur,
	# pastille du métier, pastille d'état
	var r := TILE * 0.44
	var player_col: Color = UiTokens.JOUEURS[game.index % UiTokens.JOUEURS.size()]
	var ws := game.workers.duplicate()
	ws.sort_custom(func(a, b): return a.pos.y < b.pos.y)  # ceux du bas passent devant
	for w: GameState.Worker in ws:
		if w.offmap:
			continue
		var p := w.pos * TILE
		var f: Array = facing.get(w, ["face", false, w.pos])
		var d: Vector2 = w.pos - f[2]
		var moving := d.length() > 0.0005
		if moving:
			if absf(d.x) > absf(d.y):
				f = ["profil", d.x < 0.0, w.pos]
			else:
				f = ["face" if d.y > 0.0 else "dos", f[1], w.pos]  # de profil seulement : il garde son côté
		f[2] = w.pos
		facing[w] = f
		var ring := Color(player_col, 0.9) if not selected.has(w) else UiTokens.SELECTION
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 190.0) if selected.has(w) else 0.0
		draw_arc(p + Vector2(0, 6.4), 5.2 + pulse * 1.5, 0, TAU, 24, ring, 1.6 if selected.has(w) else 1.0, true)
		var work := {} if moving or w.pause_left > 0.0 else _work_anim(w)
		var tw := now * 1.0 + w.card.id * 0.37
		var body := p
		if not work.is_empty():
			# Au travail : tourné vers l'ouvrage, le corps suit le geste
			var to: Vector2 = work["target"] - p
			if to.length() > 1.0:
				f[0] = "profil" if absf(to.x) >= absf(to.y) * 0.6 else ("face" if to.y > 0.0 else "dos")
				f[1] = to.x < 0.0
			body = p + Vector2(0, -absf(sin(tw * float(work["rythme"]))) * 0.9)
		# personnage dessiné selon le métier (scripts/rendu/sprites_bd.gd), petit balancement en marchant
		# Les jambes suivent la distance parcourue, pas le temps : pas de pédalage sur place, et une cadence limitée en accéléré
		var phase_pas: float = marche_phase.get(w, 0.0)
		if moving:
			phase_pas += minf(d.length() / MARCHE_CASES_PAR_IMAGE, get_process_delta_time() * MARCHE_IMAGES_MAX)
			marche_phase[w] = phase_pas
		var pas := absf(sin(phase_pas * PI / 2.0)) * 0.4 if moving and w.pause_left <= 0.0 else 0.0
		# Personnage de la carte, animé : le geste de sa tâche s'il en a un sur sa feuille, sinon l'outil par-dessus
		var feuille := SpritesBD.feuille_perso(str(game.perso_of(w.card)["id"]))
		var geste := int(GESTES.get(str(work.get("outil", "")), -1))
		if feuille and geste >= 0 and not SpritesBD.perso_a_rangee(feuille, geste):
			geste = -1  # planche à 4 gestes : image de marche
		if feuille:
			var rangee: int = geste if geste >= 0 else SpritesBD.PERSO_MARCHE
			var image: int = MARCHE_CYCLE[int(phase_pas) % MARCHE_CYCLE.size()] if moving else (int(tw * float(work["rythme"]) * 0.45) if geste >= 0 else 1)
			SpritesBD.dessiner_perso(self, feuille, rangee, image, p + Vector2(0, 6.2 - pas), TILE * SpritesBD.HAUTEUR_PERSONNE, f[1])
		else:
			SpritesBD.dessiner(self, SpritesBD.pour_metier(str(w.card.metier["id"]), game.is_female(w.card)), body + Vector2(0, 6.2 - pas), TILE * SpritesBD.HAUTEUR_PERSONNE, f[1])
		if not work.is_empty() and (geste < 0 or feuille == null):
			_draw_work(work, body, tw, f[1])
		# pastille du métier (couleur de catégorie) au-dessus de l'épaule
		var bp := p + Vector2(-r - 1.5, -r * 1.9)
		draw_circle(bp, 3.4, Color.WHITE)
		draw_circle(bp, 2.8, _worker_color(w.card))
		var ic := UiTokens.icone(Composants.icone_metier(str(w.card.metier["id"])))
		if ic:
			draw_texture_rect(ic, Rect2(bp - Vector2(2.1, 2.1), Vector2(4.2, 4.2)), false)
		if w.unpaid:
			_label("25 %", p + Vector2(0, -r - 2), 7)
		if w.carry > 0.0:
			var cap := game.carry_capacity(w.card)
			draw_rect(Rect2(p.x - r, p.y + r * 1.3, r * 2, 2.5), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(p.x - r, p.y + r * 1.3, r * 2 * w.carry / cap, 2.5), UiTokens.RESSOURCES.get(w.carry_type, {"couleur": Color.WHITE})["couleur"])
			# quantité portée, lisible à côté de l'écusson
			var qty := "%d/%d" % [floori(w.carry), cap]
			_ecrire(p + Vector2(r + 1.5, r * 1.3 + 3), qty, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 7, Color.WHITE, 2, Color(0, 0, 0, 0.85))
		if w.pause_left > 0.0:
			draw_circle(p + Vector2(r, -r), 3.2, Color.WHITE)
			draw_circle(p + Vector2(r, -r), 2.5, UiTokens.PAUSE)
		elif w.task.is_empty() and w.path.is_empty():
			# Inactif : des « z » qui montent en grossissant au-dessus de la tête
			for k in 3:
				var zf := fmod(now * 0.7 + k / 3.0 + w.card.id * 0.13, 1.0)
				var zp := p + Vector2(3.0 + zf * 5.0, -9.0 - zf * 9.0)
				var size := int(5.0 + zf * 4.0)
				var za := sin(zf * PI)
				_ecrire(zp, "z", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(1, 1, 1, za), 2, Color(0.1, 0.07, 0.15, 0.8 * za))

	if facing.size() > game.workers.size() + 20:
		facing.clear()  # ouvriers des journées passées
	# Rectangle de sélection
	if drag_start != null:
		var a := _screen_to_world(drag_start)
		var b := _screen_to_world(drag_end)
		var rect := Rect2(a, Vector2.ZERO).expand(b)
		draw_rect(rect, Color(0.91, 0.73, 0.29, 0.15))
		draw_rect(rect, Color("e9b949"), false, 1.0 / camera.zoom.x)

	if build_choice.get("kind") == "animal":
		_draw_animal_hints()
	_draw_peek_hint()
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
	for site in selected_sites:
		var sr2 := Rect2(Vector2(site.rect.position) * TILE, Vector2(site.rect.size) * TILE)
		draw_rect(sr2.grow(0.5), UiTokens.SELECTION, false, 1.5)
	if selected_animal:
		for t in selected_animal.tiles:
			draw_rect(Rect2(Vector2(t) * TILE, Vector2(TILE, TILE)), Color(UiTokens.SELECTION, 0.18))
		for t in game.pattern_status(selected_animal.def, selected_animal.tiles)["tiles"]:
			draw_rect(Rect2(Vector2(t) * TILE + Vector2(2, 2), Vector2(TILE - 4, TILE - 4)), UiTokens.SELECTION, false, 1.5)
	if tutoriel:
		tutoriel.dessiner_monde(self, TILE)
	if args.has("vitrine"):
		_draw_vitrine()


func _draw_site(s: GameState.Site) -> void:
	var id := s.def_id()
	var r := Rect2(Vector2(s.rect.position) * TILE, Vector2(s.rect.size) * TILE)
	var ratio := clampf(s.work / s.travail(), 0.0, 1.0)
	if s.kind == "amenagement":
		var col: Color = terrain_colors[GameMap.TERRAINS.find(str(s.def["vers"]))]
		draw_rect(r.grow(-2), Color(col, 0.6))
		_dashed_rect(r.grow(-1), Color(1, 1, 1, 0.8))
		_progress(r, ratio)
		return
	var color: Color = building_colors.get(id, Color.GRAY)
	if s.done:
		match id:
			"route", "pont", "camp_n2", "camp_n3":
				return  # dessinés avec les routes ou le camp
			"cloture", "enclos":
				_draw_fence(s, color)
			"entree":
				_draw_gate(r, s.def.get("pivote", false))
			_:
				_draw_building(r, id, color)
		if building_short.has(id) and r.has_point(_screen_to_world(get_viewport().get_mouse_position())):
			_label(building_short[id], r.get_center() + Vector2(0, r.size.y / 2 + 9), 9)
		return
	# Chantier en cours : dalle claire, planches en biais, contour en pointillés, barre de progression
	if id in ["cloture", "enclos"]:
		var c := r.get_center()
		for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			var o := game.site_at(s.rect.position + d)
			if o and o.def_id() in ["cloture", "enclos"]:
				draw_dashed_line(c, c + Vector2(d) * TILE / 2, Color(color, 0.75), 1.2, 2.0)
		draw_rect(Rect2(c - Vector2(1.8, 1.8), Vector2(3.6, 3.6)), Color(color.darkened(0.3), 0.8))
		_progress(r, ratio)
		return
	# échafaudage dessiné, posé sur le bas de l'emprise
	_dashed_rect(r.grow(-1), Color(UiTokens.ENCRE, 0.6))
	if id in ["route", "pont"]:
		draw_rect(r.grow(-2), Color(UiTokens.CHEMIN, 0.6))
	else:
		SpritesBD.dessiner_largeur(self, SpritesBD.CHANTIERS[s.id % 2], Vector2(r.get_center().x, r.end.y), minf(r.size.x, r.size.y * 1.4) * 1.05)
	_progress(r, ratio)
	_draw_pin(Vector2(r.get_center().x, r.position.y + 6), "ordre_construire", UiTokens.OR.darkened(0.25), 0.9)


## Geste de travail d'un ouvrier arrivé à son poste : {"outil", "target" (point visé, en pixels du monde), "rythme",
## "res" (pour les particules)} ; vide s'il ne travaille pas.
func _work_anim(w: GameState.Worker) -> Dictionary:
	if w.task.is_empty() or not w.path.is_empty() or w.offmap:
		return {}
	var here := w.pos * TILE
	match w.task.get("type", ""):
		"extract":
			if w.task.get("phase") != "working":
				return {}
			var res: String = w.task["res"]
			var tg := (Vector2(w.task["target"]) + Vector2(0.5, 0.5)) * TILE
			return {"outil": "hache" if res == "bois" else "pioche", "target": tg, "rythme": 7.0, "res": res}
		"build":
			var st: GameState.Site = w.task["site"]
			if st.done or not game.work_tiles(st).has(w.tile()):
				return {}
			var c := (Vector2(st.rect.position) + Vector2(st.rect.size) / 2.0) * TILE
			if w.card.traits.has("col_blanc"):
				return {"outil": "plan", "target": c, "rythme": 2.0, "res": ""}
			return {"outil": "pelle" if st.kind == "amenagement" else "marteau", "target": c, "rythme": 8.0,
				"res": "terre" if st.kind == "amenagement" else "chantier"}
		"clean":
			return {"outil": "balai", "target": here + Vector2(6, 4), "rythme": 6.0, "res": "poussiere"}
		"feed":
			return {"outil": "seau", "target": here + Vector2(6, 2), "rythme": 3.0, "res": ""}
		"station":
			if w.tile() != w.task["tile"]:
				return {}
			match w.task["kind"]:
				"care":
					return {"outil": "soin", "target": here + Vector2(7, 0), "rythme": 2.5, "res": "coeur"}
				"formation":
					return {"outil": "livre", "target": here + Vector2(0, 6), "rythme": 1.5, "res": "etoile"}
				_:
					return {"outil": "caisse", "target": here + Vector2(0, 6), "rythme": 2.0, "res": "piece"}
	return {}


## Outil animé et particules du geste de travail (voir _work_anim).
func _draw_work(work: Dictionary, p: Vector2, t: float, flip: bool) -> void:
	var sx := -1.0 if flip else 1.0
	var hand := p + Vector2(4.6 * sx, 1.2)
	var tool: String = work["outil"]
	tool = ""  # les personnages dessinés tiennent déjà leur outil : seules les particules restent
	var ph := sin(t * float(work["rythme"]))  # -1 : bras levé, +1 : coup porté
	var bois := Color("9A6A36")
	var ink := Color(0.12, 0.08, 0.05, 0.85)
	match tool:
		"hache", "pioche", "marteau", "pelle":
			# Levé au-dessus de l'épaule, puis abattu vite devant soi (k au carré : le coup est sec)
			var k := pow(ph * 0.5 + 0.5, 2.0)
			var ang := lerpf(-0.5, 2.1, k) * sx
			var dir := Vector2(sin(ang), -cos(ang))
			var side := Vector2(-dir.y, dir.x) * sx
			var length := 9.0 if tool != "marteau" else 7.0
			var tip := hand + dir * length
			draw_line(hand, tip, ink, 2.8, true)
			draw_line(hand, tip, bois, 1.5, true)
			match tool:
				"hache":
					var blade := PackedVector2Array([tip - dir * 3.4, tip + side * 3.2 - dir * 2.4, tip + side * 3.4 + dir * 0.8, tip])
					draw_colored_polygon(blade, Color("D8DEE6"))
					draw_polyline(blade + PackedVector2Array([blade[0]]), ink, 0.8, true)
				"pioche":
					draw_line(tip - side * 4.0 - dir * 0.6, tip + side * 4.0 - dir * 0.6, ink, 2.6, true)
					draw_line(tip - side * 3.6 - dir * 0.6, tip + side * 3.6 - dir * 0.6, Color("B8C0CA"), 1.5, true)
				"marteau":
					draw_line(tip - side * 2.4, tip + side * 2.4, ink, 3.8, true)
					draw_line(tip - side * 2.0, tip + side * 2.0, Color("6A6E76"), 2.6, true)
				"pelle":
					var sh := PackedVector2Array([tip - side * 2.0, tip + side * 2.0, tip + dir * 3.4 + side * 1.2, tip + dir * 3.4 - side * 1.2])
					draw_colored_polygon(sh, Color("B8C0CA"))
					draw_polyline(sh + PackedVector2Array([sh[0]]), ink, 0.8, true)
			# Au moment du coup : copeaux, poussière ou éclats qui sautent au bout de l'outil
			if k > 0.8:
				var e := (k - 0.8) / 0.2
				var col: Color = {"bois": Color("D8A85A"), "pierre": Color("D0CABC"), "or": Color("FFD84A"), "terre": Color("A07848"),
					"chantier": Color("F0E4C8")}.get(work["res"], Color.WHITE)
				var hit := tip + dir * 1.5
				for n in 4:
					var a := -PI / 2.0 + (n - 1.5) * 0.7
					var q := hit + Vector2(cos(a), sin(a)) * (1.0 + 5.0 * e)
					draw_circle(q, 1.0, Color(col, 1.0 - e * 0.6))
				draw_arc(hit, 1.5 + 3.0 * e, 0, TAU, 12, Color(1, 1, 1, 0.5 * (1.0 - e)), 0.8)
				if work["res"] == "or":
					draw_line(hit + Vector2(-3, -2) * e, hit + Vector2(3, -5) * e, Color(1, 1, 0.7, 1.0 - e), 0.8)
		"balai":
			var sweep := ph * 0.6
			var head := hand + Vector2(4.0 * sx + sweep * 2.0, 4.5)
			draw_line(hand, head, bois, 1.1, true)
			draw_line(head - Vector2(2.2, 0), head + Vector2(2.2, 0), Color("D8B860"), 1.8, true)
			if absf(ph) > 0.7:
				draw_circle(head + Vector2(-sweep * 4.0, 0.5), 1.4 * (absf(ph) - 0.6) * 2.0, Color(0.85, 0.8, 0.7, 0.45))
		"seau":
			var b := hand + Vector2(1.5 * sx, 2.0 + ph * 0.4)
			draw_rect(Rect2(b - Vector2(1.6, 0), Vector2(3.2, 2.8)), Color("7A8A98"))
			draw_arc(b + Vector2(0, -0.2), 1.6, PI, TAU, 8, Color("4A5664"), 0.6)
		"plan":
			draw_rect(Rect2(hand + Vector2(-1.0, -1.0), Vector2(3.6, 4.4)), Color("E8F0F8"))
			draw_line(hand + Vector2(-0.4, 0.6), hand + Vector2(2.0, 0.6), Color("3A6AE0"), 0.5)
			draw_line(hand + Vector2(-0.4, 2.0), hand + Vector2(1.6, 2.0), Color("3A6AE0"), 0.5)
		"livre":
			draw_rect(Rect2(hand + Vector2(-2.0, -0.5), Vector2(4.0, 3.0)), Color("3A6AE0"))
			draw_line(hand + Vector2(0, -0.5), hand + Vector2(0, 2.5), Color("F4FAEE"), 0.5)
	# Particules qui montent : cœurs (soins), étoiles (formation), pièces (guichet, boutique, marché)
	if work["res"] in ["coeur", "etoile", "piece"]:
		var cyc := fmod(t * 0.6, 1.0)
		var q: Vector2 = p + Vector2(4.0 * sx, -7.0 - cyc * 7.0)
		var a := 1.0 - cyc
		match work["res"]:
			"coeur":
				draw_circle(q + Vector2(-0.8, 0), 1.0, Color(0.95, 0.35, 0.45, a))
				draw_circle(q + Vector2(0.8, 0), 1.0, Color(0.95, 0.35, 0.45, a))
				draw_colored_polygon(PackedVector2Array([q + Vector2(-1.8, 0.3), q + Vector2(1.8, 0.3), q + Vector2(0, 2.4)]), Color(0.95, 0.35, 0.45, a))
			"etoile":
				draw_circle(q, 0.9, Color(1, 0.85, 0.3, a))
				draw_line(q - Vector2(2, 0), q + Vector2(2, 0), Color(1, 0.9, 0.5, a), 0.5)
				draw_line(q - Vector2(0, 2), q + Vector2(0, 2), Color(1, 0.9, 0.5, a), 0.5)
			"piece":
				draw_set_transform(q, 0.0, Vector2(absf(cos(t * 5.0)) * 0.8 + 0.2, 1.0))
				draw_circle(Vector2.ZERO, 1.6, Color(0.95, 0.75, 0.2, a))
				draw_circle(Vector2.ZERO, 1.0, Color(1, 0.9, 0.5, a))
				draw_set_transform(Vector2.ZERO)


## Illustration générée (tools/animaux.py, tools/batiments.py), mise en cache ; null si elle n'existe pas.
func _image(chemin: String) -> Texture2D:
	if not images.has(chemin) and chemin.begins_with("res://ui/animaux/"):
		var esp: Array = SpritesBD.ANIMAUX.get(chemin.get_file().get_basename(), [])
		if not esp.is_empty() and SpritesBD.existe(str(esp[2])):
			images[chemin] = SpritesBD.texture(str(esp[2]))  # portrait encadré
		elif not esp.is_empty() and SpritesBD.existe(esp[0]):
			images[chemin] = SpritesBD.texture(esp[0])
	if not images.has(chemin):
		images[chemin] = load(chemin) if ResourceLoader.exists(chemin) else null
	return images[chemin]


## Image de bâtiment : 32 unités par case, plus 14 au-dessus de l'emprise pour le volume (voir tools/batiments.py).
func _draw_building_image(r: Rect2, tex: Texture2D) -> void:
	var extra := TILE * 14.0 / 32.0
	draw_texture_rect(tex, Rect2(r.position - Vector2(0, extra), r.size + Vector2(0, extra)), false)


## Bâtiment terminé : son illustration, ou à défaut un toit à deux pans avec marqueur d'icône.
func _draw_building(r: Rect2, id: String, color: Color) -> void:
	var nom_sp: String = SpritesBD.BATIMENTS.get(id, "")
	if nom_sp != "" and SpritesBD.existe(nom_sp):
		var largeur := r.size.x * SpritesBD.LARGEUR_BATIMENT
		if id in ["grand_arbre", "rocher_obs", "bassin_profond", "abri_chaud"]:
			largeur = r.size.x * 1.0
		SpritesBD.dessiner_largeur(self, nom_sp, Vector2(r.get_center().x, r.end.y - (r.size.y * 0.5 if id == "bassin_profond" else 0.0)), largeur)
		return
	var tex := _image("res://ui/batiments/%s.svg" % id)
	if tex:
		_draw_building_image(r, tex)
		return
	var b := r.grow(-1.5)
	draw_rect(Rect2(b.position + Vector2(2.5, 3.0), b.size), Color(0, 0, 0, 0.28))
	var half := b.size.y / 2.0
	draw_rect(Rect2(b.position, Vector2(b.size.x, half)), color.lightened(0.14))
	draw_rect(Rect2(b.position + Vector2(0, half), Vector2(b.size.x, half)), color.darkened(0.14))
	var x := 3.0
	while x < b.size.x:
		draw_line(b.position + Vector2(x, 0), b.position + Vector2(x, b.size.y), Color(0, 0, 0, 0.12), 1.0)
		x += 3.5
	draw_line(b.position + Vector2(0, half), b.position + Vector2(b.size.x, half), color.lightened(0.4), 1.5)
	draw_rect(b, color.darkened(0.5), false, 1.0)
	_draw_pin(Vector2(b.get_center().x, b.position.y + half), Composants.icone_batiment(id), color)


## Aménagements d'enclos : grand arbre, rocher d'observation, bassin profond, abri chauffé (vus du dessus).
func _draw_decor(r: Rect2, id: String) -> void:
	var c := r.get_center()
	match id:
		"grand_arbre":
			draw_circle(c + Vector2(2.5, 3.5), 9.0, Color(0, 0, 0, 0.25))
			draw_rect(Rect2(c + Vector2(-1.2, 1), Vector2(2.4, 6)), Color("6A4426"))
			for k in [[Vector2(-3, -1), 6.5], [Vector2(3, -2), 6.0], [Vector2(0, -5), 6.5], [Vector2(0, 0), 7.0]]:
				draw_circle(c + k[0], k[1], Color("2E6A2A"))
			for k in [[Vector2(-3, -3), 3.5], [Vector2(2, -6), 3.0], [Vector2(1, -1), 3.2]]:
				draw_circle(c + k[0], k[1], Color("5AA040"))
		"rocher_obs":
			draw_circle(c + Vector2(2, 3), 8.0, Color(0, 0, 0, 0.25))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-8, 5), c + Vector2(-6, -4), c + Vector2(0, -8), c + Vector2(7, -3),
				c + Vector2(8, 5)]), Color("8E8A80"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -4), c + Vector2(0, -8), c + Vector2(7, -3), c + Vector2(0, -1)]), Color("C8C2B4"))
			draw_line(c + Vector2(-8, 5), c + Vector2(8, 5), Color("5E5A52"), 1.2)
		"bassin_profond":
			draw_circle(c + Vector2(1, 1.5), 8.5, Color("7A7468"))
			draw_circle(c, 8.0, Color("B8B0A0"))
			draw_circle(c, 6.4, Color("1E6AB0"))
			draw_circle(c + Vector2(-1.5, -1.5), 3.6, Color("3A9AE0"))
			var t := Time.get_ticks_msec() / 700.0
			draw_arc(c, 2.0 + fmod(t, 1.0) * 4.0, 0, TAU, 20, Color(1, 1, 1, 0.5 * (1.0 - fmod(t, 1.0))), 0.8)
		"abri_chaud":
			var b := r.grow(-3)
			draw_rect(Rect2(b.position + Vector2(2, 3), b.size), Color(0, 0, 0, 0.25))
			draw_rect(b, Color("A85A30"))
			draw_rect(Rect2(b.position, Vector2(b.size.x, b.size.y / 2)), Color("C8783E"))
			draw_line(b.position + Vector2(0, b.size.y / 2), b.position + Vector2(b.size.x, b.size.y / 2), Color("E8A060"), 1.2)
			draw_circle(b.get_center() + Vector2(0, 4), 1.6, Color("FFC040"))


## Mairie de la ville, au bout de la route d'Accès : c'est là que partent les ouvriers en lobbying (et les campagnes).
func _draw_town_hall(base: Vector2) -> void:
	SpritesBD.dessiner_largeur(self, "mairie", base, TILE * 3.0)
	_draw_pin(base + Vector2(TILE * 1.6, -TILE * 2.0), "ressource_influence", UiTokens.RESSOURCES["influence"]["couleur"])
	_label("Ville · lobbying", base + Vector2(0, 10), 10)
	return
	var w := TILE * 2.6
	var h := TILE * 1.3
	var body := Rect2(base - Vector2(w / 2, h), Vector2(w, h))
	draw_rect(Rect2(body.position + Vector2(3, 3), body.size), Color(0, 0, 0, 0.3))
	draw_rect(body, Color("E8DCC0"))
	draw_rect(Rect2(body.position + Vector2(0, h - 3), Vector2(w, 3)), Color("B8A880"))
	# colonnes et porte
	for k in 4:
		var x := body.position.x + 5.0 + k * (w - 10.0) / 3.0
		draw_rect(Rect2(x - 1.3, body.position.y + 2.5, 2.6, h - 5.5), Color("FBF4E2"))
		draw_line(Vector2(x + 1.3, body.position.y + 2.5), Vector2(x + 1.3, body.end.y - 3), Color(0.5, 0.42, 0.3, 0.4), 0.6)
	draw_rect(Rect2(base + Vector2(-3, -9), Vector2(6, 6)), Color("6A4426"))
	# fronton et drapeau
	var roof := PackedVector2Array([body.position + Vector2(-3, 0), body.position + Vector2(w + 3, 0), body.position + Vector2(w / 2, -9)])
	draw_colored_polygon(roof, Color("C85A3A"))
	draw_polyline(roof + PackedVector2Array([roof[0]]), Color("7A3020"), 1.0)
	var mast := body.position + Vector2(w / 2, -9)
	draw_line(mast, mast + Vector2(0, -9), Color("5A4636"), 0.8)
	var wave := sin(Time.get_ticks_msec() / 300.0) * 0.8
	draw_colored_polygon(PackedVector2Array([mast + Vector2(0, -9), mast + Vector2(6, -7.5 + wave), mast + Vector2(0, -6)]), UiTokens.RESSOURCES["influence"]["couleur"])
	_draw_pin(body.position + Vector2(w + 2, -2), "ressource_influence", UiTokens.RESSOURCES["influence"]["couleur"])
	_label("Ville · lobbying", base + Vector2(0, 10), 10)


## Dessine un bâtiment tourné d'un quart de tour si besoin : on dessine dans le rectangle d'origine (non tourné),
## puis la transformation le fait pivoter autour du centre de son emprise.
func _draw_turned(r: Rect2, turned: bool, draw_fn: Callable) -> void:
	if not turned:
		draw_fn.call(r)
		return
	var c := r.get_center()
	draw_set_transform(c, PI / 2.0)
	draw_fn.call(Rect2(-Vector2(r.size.y, r.size.x) / 2.0, Vector2(r.size.y, r.size.x)))
	draw_set_transform(Vector2.ZERO)


## Entrée du zoo : deux piliers et un portique.
## Marche : jambe avant, jambes croisées, autre jambe, jambes croisées.
const MARCHE_CYCLE := [0, 1, 2, 1]
const MARCHE_CASES_PAR_IMAGE := 0.3
const MARCHE_IMAGES_MAX := 6.0  # images par seconde au plus, même en jeu accéléré


## Outil de la tâche -> rangée de la feuille d'animation du personnage.
const GESTES := {"hache": SpritesBD.PERSO_COUPER, "pioche": SpritesBD.PERSO_MINER, "pelle": SpritesBD.PERSO_MINER, "marteau": SpritesBD.PERSO_CONSTRUIRE,
	"caisse": SpritesBD.PERSO_SERVIR, "seau": SpritesBD.PERSO_NOURRIR, "balai": SpritesBD.PERSO_BALAYER, "soin": SpritesBD.PERSO_SOIGNER}


## --vitrine : les bâtiments côte à côte à leur taille de jeu, au-dessus du camp (contrôle de nouvelles images).
func _draw_vitrine() -> void:
	var o := Vector2(game.map.camp.position) * TILE + Vector2(-TILE * 9.0, -TILE * 9.0)
	var ids := ["cabinet", "agence", "cuisine", "formation", "maison", "snack"]
	for i in ids.size():
		_draw_building(Rect2(o + Vector2(i * TILE * 3.2, 0), Vector2(TILE * 2.0, TILE * 2.0)), ids[i], Color.WHITE)
	_draw_gate(Rect2(o + Vector2(0, TILE * 3.5), Vector2(TILE * 2.0, TILE)))
	_draw_gate(Rect2(o + Vector2(TILE * 3.2, TILE * 2.8), Vector2(TILE, TILE * 2.0)), true)
	_draw_building(Rect2(o + Vector2(TILE * 6.4, TILE * 3.5), Vector2(TILE, TILE)), "rocher_obs", Color.WHITE)


## Affiche d'entreprise près de la mairie : le slogan change chaque jour.
func _draw_affiche() -> void:
	if spectator or mt.phase == "draft":
		return
	var slogans: Array = mt.data["hubert"]["slogans"]
	var slogan: String = slogans[(mt.day + mt.seed_value) % slogans.size()]
	var mots := slogan.split(" ")
	var coupe := int(mots.size() / 2.0 + 0.5)
	var l1 := " ".join(mots.slice(0, coupe))
	var l2 := " ".join(mots.slice(coupe))
	var large := maxf(font.get_string_size(l1, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x, font.get_string_size(l2, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x) + 10.0
	var bas := (Vector2(game.map.exit_tile) + Vector2(0.0, 1.0)) * TILE + Vector2(-TILE * 2.5, TILE * 1.5)
	var panneau := Rect2(bas - Vector2(large, 24.0), Vector2(large, 18.0))
	for x in [panneau.position.x + 5.0, panneau.end.x - 5.0]:
		draw_line(Vector2(x, panneau.end.y), Vector2(x, bas.y), UiTokens.ENCRE, 2.0)
	draw_rect(panneau, UiTokens.BOUTON_HAUT)
	draw_rect(panneau, UiTokens.ENCRE, false, 1.5)
	_ecrire(panneau.position + Vector2(0, 7.5), l1, HORIZONTAL_ALIGNMENT_CENTER, large, 6, UiTokens.ENCRE)
	_ecrire(panneau.position + Vector2(0, 14.5), l2, HORIZONTAL_ALIGNMENT_CENTER, large, 6, UiTokens.ENCRE)


func _draw_gate(r: Rect2, vertical := false) -> void:
	if vertical:
		# entrée tournée (verticale) : le portique vu de côté, posé sur la case du bas
		SpritesBD.dessiner_largeur(self, "entree2", Vector2(r.get_center().x, r.end.y), r.size.x * 1.7)
		return
	SpritesBD.dessiner_largeur(self, "entree", Vector2(r.get_center().x, r.end.y), maxf(r.size.x, r.size.y) * 1.15)
	return
	var tex := _image("res://ui/batiments/entree.svg")
	if tex:
		_draw_building_image(r, tex)
		return
	var b := r.grow(-2)
	draw_rect(Rect2(b.position + Vector2(2, 3), b.size), Color(0, 0, 0, 0.2))
	draw_rect(b, Color(UiTokens.ALLEE_ZOO, 0.9))
	for px in [b.position.x, b.end.x - 4.0]:
		draw_rect(Rect2(px, b.position.y, 4, b.size.y), UiTokens.ENCEINTE)
		draw_rect(Rect2(px, b.position.y, 4, b.size.y), Color("8A7A60"), false, 1.0)
	draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 3), Color("18A88A"))
	_draw_pin(Vector2(b.get_center().x, b.position.y + 2), "batiment_entree_zoo", Color("18A88A"))


## Marqueur rond au-dessus d'un objet : pastille de couleur, icône blanche, pointe vers l'objet.
func _draw_pin(tip: Vector2, icon: String, color: Color, s := 1.0) -> void:
	var c := tip - Vector2(0, 9) * s
	draw_colored_polygon(PackedVector2Array([c + Vector2(-3.5, 3) * s, c + Vector2(3.5, 3) * s, tip]), Color.WHITE)
	draw_circle(c, 6.2 * s, Color.WHITE)
	draw_circle(c, 5.2 * s, color)
	var tex := UiTokens.icone(icon)
	if tex:
		var sz := 7.0 * s
		draw_texture_rect(tex, Rect2(c - Vector2(sz, sz) / 2, Vector2(sz, sz)), false)


func _dashed_rect(r: Rect2, color: Color) -> void:
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		draw_dashed_line(corners[k], corners[(k + 1) % 4], color, 1.0, 3.0)


func _draw_bridge(t: Vector2i) -> void:
	var m := game.map
	var r := Rect2(Vector2(t) * TILE, Vector2(TILE, TILE))
	# Sens de passage : le long des routes voisines (sinon en travers de l'eau)
	var horizontal := false
	for d in [Vector2i(1, 0), Vector2i(-1, 0)]:
		var q: Vector2i = t + d
		if m.in_bounds(q.x, q.y) and (m.road[m.idx(q.x, q.y)] or m.bridge[m.idx(q.x, q.y)] == 1):
			horizontal = true
	var deck := r.grow_individual(0, -2, 0, -2) if horizontal else r.grow_individual(-2, 0, -2, 0)
	draw_rect(Rect2(deck.position + Vector2(1.5, 2.5), deck.size), Color(0, 0, 0, 0.25))
	draw_rect(deck, building_colors["pont"])
	for k in 5:
		var f := (k + 0.5) / 5.0
		if horizontal:
			draw_line(Vector2(deck.position.x + deck.size.x * f, deck.position.y), Vector2(deck.position.x + deck.size.x * f, deck.end.y), Color("5E4630"), 1.0)
		else:
			draw_line(Vector2(deck.position.x, deck.position.y + deck.size.y * f), Vector2(deck.end.x, deck.position.y + deck.size.y * f), Color("5E4630"), 1.0)
	var rail := Color("4A3420")
	if horizontal:
		draw_line(deck.position, Vector2(deck.end.x, deck.position.y), rail, 1.5)
		draw_line(Vector2(deck.position.x, deck.end.y), deck.end, rail, 1.5)
	else:
		draw_line(deck.position, Vector2(deck.position.x, deck.end.y), rail, 1.5)
		draw_line(Vector2(deck.end.x, deck.position.y), deck.end, rail, 1.5)


## Camp de base : terre battue, tentes (une de plus par agrandissement), feu de camp.
func _draw_camp() -> void:
	var m := game.map
	var c := Rect2(Vector2(m.camp.position) * TILE, Vector2(m.camp.size) * TILE).grow(-1)
	var level := 1
	for s in game.sites:
		if s.done and s.def_id() in ["camp_n2", "camp_n3"]:
			level += 1
	var full := Rect2(Vector2(m.camp.position) * TILE, Vector2(m.camp.size) * TILE)
	if SpritesBD.existe(SpritesBD.CAMPS[clampi(level - 1, 0, 2)]):
		SpritesBD.dessiner_largeur(self, SpritesBD.CAMPS[clampi(level - 1, 0, 2)], Vector2(full.get_center().x, full.end.y + 2), full.size.x * 1.15)
		_label("Camp" + (" niv. %d" % level if level > 1 else ""), full.get_center() + Vector2(0, -full.size.y / 2 - 9), 10)
		return
	draw_rect(Rect2(c.position + Vector2(2, 3), c.size), Color(0, 0, 0, 0.22))
	draw_rect(c, Color("C49A64"))
	draw_rect(c.grow(-3), Color("D2AA72"))
	draw_rect(c, Color("7A5434"), false, 1.5)
	var tents := [[Vector2(0.27, 0.42), Color("E8DCC0")], [Vector2(0.73, 0.42), Color("D2553A")], [Vector2(0.27, 0.86), Color("3A6AE0")], [Vector2(0.73, 0.86), Color("18A88A")]]
	for k in mini(level + 1, tents.size()):
		_draw_tent(c.position + c.size * tents[k][0], c.size.x * 0.34, tents[k][1])
	# Feu de camp qui vacille
	var f := c.position + c.size * Vector2(0.5, 0.62)
	var flicker := 0.8 + 0.2 * sin(Time.get_ticks_msec() / 90.0)
	draw_circle(f, 4.0, Color("6A4A30"))
	draw_circle(f, 2.8 * flicker, Color("F08A20"))
	draw_circle(f, 1.5 * flicker, Color("FFE07A"))
	_label("Camp" + (" niv. %d" % level if level > 1 else ""), c.get_center() + Vector2(0, -c.size.y / 2 - 3), 10)


func _draw_tent(base: Vector2, w: float, col: Color) -> void:
	var h := w * 0.8
	draw_colored_polygon(PackedVector2Array([base + Vector2(-w / 2 + 2, 2), base + Vector2(w / 2 + 3, 2), base + Vector2(3, -h + 3)]), Color(0, 0, 0, 0.22))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-w / 2, 0), base, base + Vector2(0, -h)]), col.lightened(0.12))
	draw_colored_polygon(PackedVector2Array([base, base + Vector2(w / 2, 0), base + Vector2(0, -h)]), col.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.14, 0), base + Vector2(w * 0.14, 0), base + Vector2(0, -h * 0.45)]), Color(0.15, 0.1, 0.06, 0.8))


## Animal : enclos teinté, deux ou trois bêtes qui déambulent d'une case à l'autre, marqueur du biome.
func _draw_animal(a: GameState.Animal, index: int, now: float) -> void:
	var col: Color = biome_colors[a.def["biome"]]
	if not a.park:
		var inside := {}
		for t in a.tiles:
			inside[t] = true
		for t in a.tiles:
			var r := Rect2(Vector2(t) * TILE, Vector2(TILE, TILE))
			draw_rect(r, Color(col, 0.12))
			# herbe foulée et ombre le long des clôtures (côtés haut et gauche : l'ombre tombe vers le bas à droite)
			if not inside.has(t + Vector2i(0, -1)):
				draw_rect(Rect2(r.position, Vector2(TILE, 3.5)), Color(0, 0, 0, 0.12))
			if not inside.has(t + Vector2i(-1, 0)):
				draw_rect(Rect2(r.position, Vector2(2.5, TILE)), Color(0, 0, 0, 0.1))
			if not inside.has(t + Vector2i(0, 1)):
				draw_rect(Rect2(r.position + Vector2(0, TILE - 2.0), Vector2(TILE, 2.0)), Color(0.35, 0.25, 0.1, 0.12))
	# Marqueur au centre de son motif (plusieurs animaux peuvent partager un enclos)
	var anchor_tiles: Array = a.pattern_tiles if not a.pattern_tiles.is_empty() else a.tiles
	var center := Vector2.ZERO
	for t in anchor_tiles:
		center += Vector2(t) + Vector2(0.5, 0.5)
	center = center / anchor_tiles.size() * TILE
	if not a.arrived:
		# caisse de transport en attendant la nuit
		draw_rect(Rect2(center - Vector2(5, 4), Vector2(10, 8)), Color("A0743C"))
		draw_rect(Rect2(center - Vector2(5, 4), Vector2(10, 8)), Color("5A3A22"), false, 1.0)
		draw_line(center - Vector2(5, 4), center + Vector2(5, 4), Color("5A3A22"), 1.0)
	else:
		var body := col.darkened(0.35)
		var esp: Array = SpritesBD.ANIMAUX.get(str(a.def["id"]), [])
		var tex: bool = not esp.is_empty() and SpritesBD.existe(esp[0])
		var big := int(a.def["taille"]) >= 7
		var count := (1 if big else 2) + (1 if a.tiles.size() >= 24 else 0) if tex else mini(2 + a.tiles.size() / 12, 3)
		for k in count:
			var clock := now / 6.0 + k * 0.37 + index * 0.21
			var slot := int(clock)
			var f := smoothstep(0.55, 1.0, clock - slot)
			var seed := index * 7 + k * 13
			var p0 := Vector2(a.tiles[(seed + slot * 31) % a.tiles.size()])
			var p1 := Vector2(a.tiles[(seed + (slot + 1) * 31) % a.tiles.size()])
			var pos := (p0.lerp(p1, f) + Vector2(0.5, 0.5)) * TILE
			var dir := -1.0 if p1.x < p0.x else 1.0
			if tex:
				# illustration du contrat, à l'échelle de l'espèce, retournée selon la marche, petit sautillement
				var bob := absf(sin(clock * TAU * 3.0)) * 0.8 if f > 0.0 and f < 1.0 else 0.0
				var moving := f > 0.0 and f < 1.0
				var frame := SpritesBD.image_animal(esp, int(now * 6.0) + k if moving else 0)
				SpritesBD.dessiner(self, frame, pos + Vector2(0, TILE * 0.35 - bob), TILE * float(esp[1]) * 1.15, dir < 0.0)
				continue
			draw_set_transform(pos + Vector2(1, 2.5), 0.0, Vector2(1.5, 0.6))
			draw_circle(Vector2.ZERO, 3.0, Color(0, 0, 0, 0.25))
			draw_set_transform(pos, 0.0, Vector2(1.45, 1.0))
			draw_circle(Vector2.ZERO, 2.8, body)
			draw_set_transform(Vector2.ZERO)
			draw_circle(pos + Vector2(dir * 4.2, -1.2), 1.9, body.lightened(0.15))
	var biome := str(a.def["biome"]).to_lower()
	var icon: String = UiTokens.BIOMES[biome]["icone"] if UiTokens.BIOMES.has(biome) else "ui_valide"
	if not a.arrived or SpritesBD.ANIMAUX.get(str(a.def["id"]), []).is_empty():
		_draw_pin(center + Vector2(0, -2), icon, col.darkened(0.15))
	if not a.arrived:
		_draw_moon(center + Vector2(0, -14))
		return
	var txt: String = a.def["nom"]
	if a.sick:
		txt += " (malade !)"
		_draw_pin(center + Vector2(9, -4), "ui_invalide", UiTokens.DEFAUT, 0.8)
	if not a.fed:
		txt += " (a faim !)"
	elif game.food_due():
		txt += " %.0f/%.0f" % [a.food, game.food_capacity(a.def)]
	_label(txt, center + Vector2(0, -21), 9)


## Animal attendu : un croissant de lune sur fond de nuit (il arrive cette nuit).
func _draw_moon(p: Vector2) -> void:
	draw_circle(p, 7.5, UiTokens.ENCRE)
	draw_circle(p, 6.5, UiTokens.MARINE)
	draw_circle(p, 4.6, UiTokens.SELECTION)
	draw_circle(p + Vector2(2.0, -1.4), 4.0, UiTokens.MARINE)


const TENUES := [Color("E04A4A"), Color("3A6AE0"), Color("E8B020"), Color("8A4AD0"), Color("F2F2F2"), Color("18A88A"), Color("E8782A")]


## Visiteur : petite silhouette discrète aux couleurs adoucies (à distinguer nettement des ouvriers dessinés) ;
## un sur quatre est un enfant, plus petit.
const TENUES_VISITEURS := [Color("C98E8E"), Color("8EA6C9"), Color("C9B98E"), Color("A88EC9"), Color("8EC9B4"), Color("C9A08E")]


func _draw_visitor(pos: Vector2, k: int) -> void:
	var sc := 0.7 if k % 4 == 1 else 1.0
	var t := Time.get_ticks_msec() / 1000.0 + k * 0.37
	var p := pos + Vector2(0, -absf(sin(t * 8.0)) * 0.4)
	var col: Color = TENUES_VISITEURS[(k * 5 + 3) % TENUES_VISITEURS.size()]
	draw_set_transform(pos + Vector2(0.4, 2.0 * sc), 0.0, Vector2(1.5, 0.55))
	draw_circle(Vector2.ZERO, 1.5 * sc, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(p + Vector2(-1.1, -1.4) * sc, Vector2(2.2, 3.0) * sc), Color(col, 0.85))
	draw_circle(p + Vector2(0, -2.2) * sc, 1.0 * sc, Color(0.93, 0.84, 0.74, 0.85))


func _progress(r: Rect2, ratio: float) -> void:
	draw_rect(Rect2(r.position.x + 2, r.end.y - 4, r.size.x - 4, 2.5), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position.x + 2, r.end.y - 4, (r.size.x - 4) * ratio, 2.5), UiTokens.SELECTION)


## Enceinte (mur blanc à poteaux) ou enclos (palissade de bois) : segments vers les voisins identiques.
## Enceinte : mur de pierre claire (ombre, chaperon, piliers). Enclos : palissade de bois à double lisse.
## Une palissade ne rejoint le mur que si l'enclos qu'elle ferme utilise ce mur comme côté.
func _draw_fence(s: GameState.Site, color: Color) -> void:
	var p := s.rect.position
	var c := (Vector2(p) + Vector2(0.5, 0.5)) * TILE
	var wall := s.def_id() == "cloture"
	var links := _wall_links()
	var dirs: Array[Vector2i] = []
	var reaches: Array[float] = []
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var o := game.site_at(p + d)
		if o == null or not o.done:
			continue
		var reach := 0.0
		if o.def_id() == s.def_id() or (wall and o.def_id() == "entree"):
			reach = 0.5
		elif not wall and o.def_id() in ["cloture", "entree"] and links.has(p):
			reach = 1.0  # palissade accrochée au mur
		if reach > 0.0:
			dirs.append(d)
			reaches.append(reach)
	# Pilier ou poteau d'angle seulement là où le tracé tourne, s'arrête ou se divise
	var straight := dirs.size() == 2 and dirs[0] + dirs[1] == Vector2i.ZERO
	if wall:
		_draw_wall(c, dirs, reaches, straight, color)
	else:
		_draw_palisade(c, dirs, reaches, straight, color)


## Mur d'enceinte en perspective : face avant (assises et joints), chaperon clair, piliers aux angles.
func _draw_wall(c: Vector2, dirs: Array[Vector2i], reaches: Array[float], straight: bool, _color: Color) -> void:
	var ink := UiTokens.ENCRE
	var base := c + Vector2(0, TILE * 0.3)
	var h := TILE * 0.62
	var ep := TILE * 0.32
	for k in dirs.size():
		var d := dirs[k]
		var e := base + Vector2(d) * TILE * reaches[k]
		if d.y == 0:
			var face := PackedVector2Array([base, e, e - Vector2(0, h), base - Vector2(0, h)])
			draw_colored_polygon(face, Color("D8D2C2"))
			draw_line(base - Vector2(0, h * 0.5), e - Vector2(0, h * 0.5), Color(ink, 0.45), 1.0)
			var sx := signf(e.x - base.x) * TILE * reaches[k]
			draw_line(base + Vector2(sx * 0.5, -h * 0.5), base + Vector2(sx * 0.5, -h), Color(ink, 0.4), 1.0)
			draw_line(base + Vector2(sx * 0.2, 0), base + Vector2(sx * 0.2, -h * 0.5), Color(ink, 0.4), 1.0)
			draw_line(base + Vector2(sx * 0.8, 0), base + Vector2(sx * 0.8, -h * 0.5), Color(ink, 0.4), 1.0)
			draw_line(base, e, ink, 1.4)
			var top := PackedVector2Array([base - Vector2(0, h), e - Vector2(0, h), e - Vector2(0, h + ep * 0.45), base - Vector2(0, h + ep * 0.45)])
			draw_colored_polygon(top, Color("EFEADF"))
			draw_line(top[0], top[1], ink, 1.1)
			draw_line(top[2], top[3], ink, 1.3)
		else:
			var flanc := PackedVector2Array([base + Vector2(ep * 0.5, 0), e + Vector2(ep * 0.5, 0), e + Vector2(ep * 0.5, -h), base + Vector2(ep * 0.5, -h)])
			draw_colored_polygon(flanc, Color("C2BBA9"))
			draw_line(flanc[0], flanc[1], ink, 1.1)
			var top2 := PackedVector2Array([base + Vector2(-ep * 0.5, -h), e + Vector2(-ep * 0.5, -h), e + Vector2(ep * 0.5, -h), base + Vector2(ep * 0.5, -h)])
			draw_colored_polygon(top2, Color("EFEADF"))
			draw_line(top2[0], top2[1], ink, 1.3)
			draw_line(top2[3], top2[2], ink, 1.1)
	if not straight:
		var pil := Rect2(base + Vector2(-ep * 0.5, -h - ep * 0.5), Vector2(ep, h + ep * 0.5))
		draw_rect(pil, Color("E4DED0"))
		draw_rect(pil, ink, false, 1.2)
		draw_rect(Rect2(pil.position, Vector2(pil.size.x, ep * 0.32)), Color("F6F2EA"))
		draw_rect(Rect2(pil.position, Vector2(pil.size.x, ep * 0.32)), ink, false, 1.0)


## Palissade d'enclos en perspective : deux lisses de bois encrées, poteau au centre de la case.
func _draw_palisade(c: Vector2, dirs: Array[Vector2i], reaches: Array[float], straight: bool, _color: Color) -> void:
	var ink := UiTokens.ENCRE
	var base := c + Vector2(0, TILE * 0.3)
	var hp := TILE * 0.62
	for k in dirs.size():
		var e := base + Vector2(dirs[k]) * TILE * reaches[k]
		for t in [0.35, 0.72]:
			draw_line(base - Vector2(0, hp * t), e - Vector2(0, hp * t), ink, 3.4)
			draw_line(base - Vector2(0, hp * t), e - Vector2(0, hp * t), Color("A0703E"), 1.8)
	var w := TILE * (0.2 if not straight else 0.16)
	var pt := Rect2(base + Vector2(-w / 2, -hp), Vector2(w, hp))
	draw_rect(pt, Color("7A5230"))
	draw_rect(pt, ink, false, 1.0)


func _post(q: Vector2, ink: Color, wood: Color, light: Color, r: float) -> void:
	draw_circle(q + Vector2(1.0, 1.8), r, Color(0, 0, 0, 0.25))
	draw_circle(q, r + 0.6, ink)
	draw_circle(q, r, wood)
	draw_circle(q + Vector2(-r * 0.35, -r * 0.35), r * 0.4, light)


## Palissades qui ferment un enclos en s'appuyant sur le mur de l'enceinte (animal installé ou réservé).
var _links_version := -1
var _links := {}


func _wall_links() -> Dictionary:
	if _links_version == game.version:
		return _links
	_links_version = game.version
	_links = {}
	var zones: Array = []
	for a in game.animals:
		if not a.park:
			zones.append(a.tiles)
	for r in game.pending_installs:
		var enc := game.enclosure_at(r["tile"])
		if enc.get("closed", false) and not enc.get("park", false):
			zones.append(enc["tiles"])
	for tiles in zones:
		var fences: Array[Vector2i] = []
		var uses_wall := false
		for t in tiles:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = t + d
				var o := game.site_at(q)
				if o == null:
					continue
				if o.def_id() == "enclos":
					fences.append(q)
				elif o.def_id() in ["cloture", "entree"]:
					uses_wall = true
		if uses_wall:
			for f in fences:
				_links[f] = true
	return _links

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
	# largeur à la mesure du texte (une largeur fixe coupait les libellés longs)
	var taille := size + 2  # Bangers est étroite : un peu plus grande pour rester lisible
	var width := maxf(80.0, font_noms.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x + 8.0)
	_ecrire(pos - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_CENTER, width, taille, Color.WHITE, 3, Color(0, 0, 0, 0.85), font_noms)


## Texte du monde, net au zoom : écrit en grand puis réduit (une police de 7 pixels agrandie par la caméra serait floue).
func _ecrire(pos: Vector2, text: String, align: HorizontalAlignment, width: float, size: int, col: Color, contour := 0, col_contour := Color.BLACK, police: Font = null) -> void:
	var f: Font = police if police else font
	draw_set_transform(pos, 0.0, Vector2.ONE / TEXTE_NET)
	var w := width * TEXTE_NET if width > 0.0 else -1.0
	if contour > 0:
		draw_string_outline(f, Vector2.ZERO, text, align, w, int(size * TEXTE_NET), int(contour * TEXTE_NET), col_contour)
	draw_string(f, Vector2.ZERO, text, align, w, int(size * TEXTE_NET), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
					drag_sites = event.ctrl_pressed
			MOUSE_BUTTON_MIDDLE:
				panning = true
			MOUSE_BUTTON_RIGHT:
				if not build_choice.is_empty():
					_set_build({})
					return
				var targets := selected.filter(func(w): return game.workers.has(w))
				if not targets.is_empty():
					var t := _screen_to_world(event.position) / TILE
					_cmd("order", [targets, Vector2i(floori(t.x), floori(t.y)), event.shift_pressed])
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				if not build_choice.is_empty():
					_set_build({})
				else:
					selected.clear()
					selected_site = null
					selected_sites.clear()
					selected_animal = null
			KEY_DELETE, KEY_BACKSPACE:
				_delete_selection()
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
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R 		and not build_choice.is_empty() and not (get_viewport().gui_get_focus_owner() is LineEdit):
		_rotate_build()
		get_viewport().set_input_as_handled()
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
	if rotate_btn:
		rotate_btn.visible = _rotatable()
	if choice.get("kind") == "animal":
		_compute_animal_hints(choice["def"], true)
	else:
		animal_hints.clear()
		enclosure_proposal = {}
		proposal_box.visible = false
	enc_cache_tile = Vector2i(-99, -99)
	hand_version = -1  # rafraîchit l'état des boutons de contrats
	for entry in build_buttons:
		entry[0].button_pressed = not choice.is_empty() and entry[2] == choice["def"]


## R : tourne d'un quart de tour le bâtiment à poser (entrée du zoo, bâtiments non carrés).
func _rotatable() -> bool:
	if build_choice.get("kind") != "batiment":
		return false
	var t: Array = build_choice["def"].get("taille", [1, 1])
	return int(t[0]) != int(t[1]) and build_choice["def"].get("sur", "") != "camp"


func _rotate_build() -> void:
	if not _rotatable():
		return
	var def: Dictionary = build_choice["def"]
	var t: Array = def.get("taille", [1, 1])
	if int(t[0]) == int(t[1]) or def.get("sur", "") == "camp":
		return
	var turned := def.duplicate()
	turned["taille"] = [t[1], t[0]]
	turned["pivote"] = not def.get("pivote", false)
	build_choice["def"] = turned
	game.say("%s : %s." % [turned["nom"], "verticale" if turned["pivote"] else "horizontale"])


func _is_paint_build() -> bool:
	return not build_choice.is_empty() and (build_choice["kind"] == "amenagement" or build_choice["def"].get("peinture", false))


## Place un chantier. Les routes, clôtures et aménagements se « peignent » en glissant la souris ;
## les autres bâtiments se placent un par un (Maj pour en placer plusieurs).
func _try_place(t: Vector2i, first_click: bool) -> void:
	last_paint = t
	var kind: String = build_choice["kind"]
	var def: Dictionary = build_choice["def"]
	if tutoriel and not tutoriel.pose_permise(kind, def, _build_origin(t), t):
		if first_click:
			game.say("Hubert de la Marge n'a pas validé cet emplacement. Suivez la zone jaune.")
		return
	if kind == "animal":
		var in_park: bool = game.enclosure_at(t).get("park", false)
		var aerr := _cmd_texte("install_animal", [def, t])
		if aerr == "" and in_park:
			game.say("%s : enclos posé en chantier autour, l'animal y est réservé. Envoyez des collaborateurs (clic droit)." % def["nom"])
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
	var s: Variant = _cmd("place", [kind, def, origin])
	if (s or reseau) and not _is_paint_build() and not Input.is_key_pressed(KEY_SHIFT):
		_set_build({})
		selected_site = s


## Ouvrier sous le clic : le plus proche, ou, s'ils se superposent, le suivant de la pile à chaque nouveau clic.
func _ouvrier_clique(wp: Vector2, avant: Array) -> GameState.Worker:
	var pile: Array = game.workers.filter(func(w): return not w.offmap and w.pos.distance_to(wp) < 0.6)
	if pile.is_empty():
		return null
	pile.sort_custom(func(a, b): return a.card.id < b.card.id)
	if avant.size() == 1 and pile.has(avant[0]):
		return pile[(pile.find(avant[0]) + 1) % pile.size()]
	var best: GameState.Worker = pile[0]
	for w in pile:
		if w.pos.distance_to(wp) < best.pos.distance_to(wp):
			best = w
	return best


func _finish_selection() -> void:
	var start: Vector2 = drag_start
	drag_start = null
	var click := start.distance_to(drag_end) < 5
	var ct := Vector2i((_screen_to_world(drag_end) / TILE).floor())
	# Maj + clic sur un bâtiment ou un chantier : l'ajoute à la sélection multiple (ou l'en retire)
	if click and drag_add and game.site_at(ct) != null and selected.is_empty():
		var st := game.site_at(ct)
		if selected_site and not selected_sites.has(selected_site):
			selected_sites.append(selected_site)
		selected_site = null
		if selected_sites.has(st):
			selected_sites.erase(st)
		else:
			selected_sites.append(st)
		_update_info()
		return
	# Double-clic sur une clôture, un mur ou une route : tout le tracé relié
	var now := Time.get_ticks_msec()
	if click and last_click["tile"] == ct and now - int(last_click["at"]) < 400 and game.site_at(ct) != null:
		last_click = {"at": 0, "tile": Vector2i(-99, -99)}
		var chain := _connected_sites(game.site_at(ct))
		if chain.size() > 1:
			selected.clear()
			selected_site = null
			selected_sites = chain
			selected_animal = null
			_update_info()
			return
	if click:
		last_click = {"at": now, "tile": ct}
	var avant := selected.duplicate()
	if not drag_add:
		selected.clear()
	selected_site = null
	selected_sites.clear()
	selected_animal = null
	if click:
		var wp := _screen_to_world(drag_end) / TILE
		var best := _ouvrier_clique(wp, avant)
		if best and not selected.has(best):
			selected.append(best)
		elif not best and selected.is_empty():
			var t := Vector2i(floori(wp.x), floori(wp.y))
			selected_site = game.site_at(t)
			if selected_site == null:
				selected_animal = game.animal_at(t)
	else:
		var rect := Rect2(_screen_to_world(start) / TILE, Vector2.ZERO).expand(_screen_to_world(drag_end) / TILE)
		if not drag_sites:
			for w in game.workers:
				if not w.offmap and rect.has_point(w.pos) and not selected.has(w):
					selected.append(w)
		# Sans ouvrier dans le rectangle : on sélectionne les bâtiments et chantiers touchés (Suppr pour les retirer).
		if selected.is_empty():
			for site in game.sites:
				if rect.intersects(Rect2(Vector2(site.rect.position), Vector2(site.rect.size))):
					selected_sites.append(site)
			if selected_sites.size() == 1:
				selected_site = selected_sites[0]
				selected_sites.clear()
	_update_info()


## Éléments reliés de même type (segments de clôture, de mur, de route…) à partir de l'un d'eux.
func _connected_sites(first: GameState.Site) -> Array:
	var id := first.def_id()
	var out := [first]
	var seen := {first: true}
	var k := 0
	while k < out.size() and out.size() < 400:
		var cur: GameState.Site = out[k]
		k += 1
		for t in [cur.rect.position]:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var o := game.site_at(t + d)
				if o and not seen.has(o) and o.def_id() == id:
					seen[o] = true
					out.append(o)
	return out


## Suppr : démolit les bâtiments terminés et annule les chantiers sélectionnés (remboursés selon l'avancement).
func _delete_selection() -> void:
	if spectator or game.phase != "day":
		return
	var targets: Array = selected_sites.duplicate() if not selected_sites.is_empty() else ([selected_site] if selected_site else [])
	var demolished := 0
	var cancelled := 0
	for site in targets:
		if not game.sites.has(site):
			continue
		if site.done:
			if _cmd("demolish", [site]) != false:
				demolished += 1
		else:
			_cmd("cancel_site", [site])
			cancelled += 1
	if demolished + cancelled > 1:
		game.say("%d démoli(s), %d chantier(s) annulé(s)." % [demolished, cancelled])
	selected_sites.clear()
	selected_site = null
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
	if tutoriel and tutoriel.temps_verrouille:
		return
	if reseau:
		if s <= 0.0:  # pas de pause en multijoueur
			return
		reseau.demander_vitesse(s)
	speed = s
	for k in speed_buttons:
		speed_buttons[k].button_pressed = (k == s)


# --- Boucle principale -------------------------------------------------------

func _process(delta: float) -> void:
	if mt == null:
		_screenshot_check()
		return
	if hover_card and (not is_instance_valid(hover_src) or not hover_src.is_visible_in_tree() \
		or not hover_src.get_global_rect().has_point(hover_src.get_global_mouse_position())):
		_hide_hover_card()
	# Chaque nouvelle journée commence en pause : on prépare ses ordres, puis on lance le temps.
	if mt.phase != last_phase:
		if mt.phase == "day" and last_phase != "" and not spectator:
			_set_speed(0.0)
			selected.clear()
		last_phase = mt.phase
	_pan_keys(delta)
	if reseau == null and mt.phase == "draft" and mt.is_ai(mt.current_drafter()):
		ai_timer += delta
		if ai_timer > 0.35:
			ai_timer = 0.0
			mt.pick_draft(mt.ai_choice())
	# La nuit, les IA jouent l'une après l'autre (on voit ce qu'elles prennent) ; en spectateur, la nuit passe seule.
	if reseau == null and mt.phase == "night" and not mt.game_over:
		night_clock += delta
		var pause := 0.3 if speed >= 8.0 else (2.0 if mt.night_stage == "bonus" else 1.1)
		if night_clock > pause:
			night_clock = 0.0
			if not mt.step_night() and spectator and mt.night_stage == "equipe":
				mt.start_next_day()
	if reseau:
		_maj_multijoueur()
	else:
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
		if build_choice.get("kind") == "animal":
			_compute_animal_hints(build_choice["def"], false)
		_update_info()
	info_clock += delta
	if info_clock > 0.25:
		info_clock = 0.0
		_update_info()
		for entry in build_buttons:
			entry[0].disabled = game.phase != "day" or not game.can_afford(entry[2].get("cout", {}))
		_update_trade()
		_update_publicity()
		_update_loan()
		var ev: Dictionary = mt.current_event
		event_label.visible = mt.phase == "day" and not ev.is_empty() and not (hubert and hubert.grande_visible())
		if not ev.is_empty():
			event_label.text = "  %s : %s  " % [ev["nom"], ev["texte"]]
		_hubert_alertes()
	_hubert_annonces()
	_screenshot_check()


## Le bilan du soir signé par Hubert : sa réaction aux chiffres, son humeur, sa signature et le tampon.
func _note_de_direction(total: int) -> void:
	if hubert == null:
		return
	if not memo_lignes.has(mt.day):
		memo_lignes[mt.day] = hubert.replique("soir_bon" if total >= 0 else "soir_mauvais")
	var note := Composants.label("« %s »" % memo_lignes[mt.day])
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 14)
	night_summary.add_child(note)
	var humeur := _hubert_humeur()
	var hl := Composants.label("Humeur de la direction : %s" % ("satisfaite" if humeur > 0 else ("exécrable" if humeur < 0 else "vigilante")), "TexteSecondaire")
	hl.add_theme_font_size_override("font_size", 12)
	night_summary.add_child(hl)
	var cadre: Dictionary = mt.data["hubert"]["cadre"]
	var signe := Composants.label("%s\n%s" % [cadre["nom"], cadre["titre"]], "TexteSecondaire")
	signe.add_theme_font_size_override("font_size", 12)
	signe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	night_summary.add_child(signe)
	var support := Control.new()
	support.custom_minimum_size = Vector2(0, 34)
	support.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_summary.add_child(support)
	var tampon := Label.new()
	tampon.text = "CONFIDENTIEL"
	tampon.add_theme_font_override("font", UiTokens.police_corps(800))
	tampon.add_theme_font_size_override("font_size", 14)
	tampon.add_theme_color_override("font_color", UiTokens.ORANGE)
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0, 0, 0, 0)
	ts.border_color = UiTokens.ORANGE
	ts.set_border_width_all(2)
	ts.set_corner_radius_all(3)
	ts.content_margin_left = 8
	ts.content_margin_right = 8
	tampon.add_theme_stylebox_override("normal", ts)
	tampon.position = Vector2(60, 8)
	tampon.rotation = -0.1
	support.add_child(tampon)


## Tous les ordres du joueur passent ici : exécutés aussitôt en solo, envoyés à l'hôte en multijoueur (null : le résultat
## arrivera avec la trame suivante).
func _cmd(nom: String, args := []) -> Variant:
	if reseau:
		reseau.envoyer(nom, Commandes.coder(args))
		return null
	if nom in Commandes.SUR_PARTIE:
		return mt.callv(nom, args)
	return game.callv(nom, args)


func _cmd_texte(nom: String, args := []) -> String:
	var r: Variant = _cmd(nom, args)
	return r if r is String else ""


## Répliques en attente : en bulle, ou en message simple si le moment n'a pas de réplique (ou pendant le tutoriel).
func _hubert_annonces() -> void:
	if mt.game_over:  # la dernière nuit a pu faire monter des niveaux : Hubert ne commente plus que le résultat
		game.annonces.clear()
		return
	if hubert:
		hubert.humeur = _hubert_humeur()
	for a in game.annonces:
		if (hubert == null or not hubert.annoncer(a["moment"], a["args"])) and a["repli"] != "":
			game.say(a["repli"])
	game.annonces.clear()


## Satisfait en tête, furieux quand un concurrent a pris le large.
func _hubert_humeur() -> int:
	var best := 0
	for i in mt.players.size():
		if i != game.index:
			best = maxi(best, mt.players[i].reputation())
	var moi := game.reputation()
	if moi > best:
		return 1
	return -1 if best - moi >= 15 else 0


## Les situations qui durent : Hubert les signale une fois par jour.
func _hubert_alertes() -> void:
	if hubert == null or mt.phase != "day" or mt.game_over:
		return
	if hubert_dit.get("jour", -1) != mt.day:
		hubert_dit = {"jour": mt.day}
	var ouvert: bool = game.zoo_status()["open"]
	if ouvert and not hubert_ouverture:
		hubert_ouverture = true
		hubert.annoncer("ouverture")
	var alertes := {
		"guichet": ouvert and game.visitor_queue >= 3 and not game.workers.any(func(w): return w.task.get("kind") == "ticket"),
		"affame": game.animals.any(func(a): return a.arrived and not a.fed),
		"sale": ouvert and game.proprete < 50.0,
	}
	for k in alertes:
		if alertes[k] and not hubert_dit.has(k):
			hubert_dit[k] = true
			hubert.annoncer(k)


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
		if args.has("etape"):  # --etape=ouvriers : avance la nuit jusqu'à cette étape (captures)
			mt.night_goto(args["etape"], game.index)
		if args.has("peek"):  # --peek : « Voir mon zoo » avec le premier contrat montré sur la carte
			night_peek = true
	selected = ws.slice(0, 1 if args.has("un") else 2)


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

	# Barre du haut (h 52) : jetons de ressources, course à la réputation, vitesse — capture 03
	# Barre du haut « BD » : pastilles blanches flottantes cernées d'encre (ressources, course, vitesse)
	var top := MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 8
	top.offset_left = 14
	top.offset_right = -14
	top.custom_minimum_size.y = 50
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(bar)
	var pastille_haut := func(sep: int) -> HBoxContainer:
		var pc := PanelContainer.new()
		var st := UiTokens.panel(UiTokens.PAPIER, UiTokens.ENCRE, 14, 3, 6)
		st.content_margin_left = 10
		st.content_margin_right = 12
		pc.add_theme_stylebox_override("panel", st)
		bar.add_child(pc)
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", sep)
		pc.add_child(inner)
		return inner
	var hb: HBoxContainer = pastille_haut.call(14)
	for r in [["argent", "Argent"], ["bois", "Bois"], ["pierre", "Pierre"], ["or", "Or"], ["influence", "Influence (privée)"],
			["logement", "Logement"], ["reputation", "Réputation"]]:
		var res: Dictionary = UiTokens.RESSOURCES[r[0]]
		var chip := Composants.jeton_ressource(res["icone"], res["couleur"], res["reflet"], r[1], res.get("sprite", ""))
		chip["racine"].tooltip_text = res["nom"]
		hb.add_child(chip["racine"])
		res_chips[r[0]] = chip
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(spacer)
	hb = pastille_haut.call(6)
	var race_title := Composants.label("COURSE À %d" % game.objective(), "NomCarte")
	race_title.add_theme_font_size_override("font_size", 15)
	race_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(race_title)
	var race := HBoxContainer.new()
	race.add_theme_constant_override("separation", 4)
	race.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(race)
	for i in mt.players.size():
		var pill := PanelContainer.new()
		var ps := UiTokens.chip(UiTokens.JOUEURS[i % UiTokens.JOUEURS.size()], 15, 3)
		ps.content_margin_left = 8
		ps.content_margin_right = 8
		pill.add_theme_stylebox_override("panel", ps)
		pill.tooltip_text = mt.names[i]
		var pl := Composants.label("0", "Compteur")
		pl.add_theme_font_size_override("font_size", 15)
		pl.add_theme_color_override("font_color", UiTokens.TEXTE_CLAIR)
		if i == game.index:
			ps.border_color = UiTokens.SELECTION
			ps.set_border_width_all(3)
		pill.add_child(pl)
		race.add_child(pill)
		race_labels.append([pill, pl])
	if spectator:
		hb = pastille_haut.call(4)
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
	hb = pastille_haut.call(4)
	var speeds := HBoxContainer.new()
	speeds.add_theme_constant_override("separation", 4)
	speeds.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(speeds)
	for s in ([1.0, 2.0, 4.0, 8.0, 16.0] if reseau else [0.0, 1.0, 2.0, 4.0, 8.0, 16.0]):
		var b := Button.new()
		b.text = "II" if s == 0.0 else "×%d" % int(s)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(40, 34)
		b.theme_type_variation = "Onglet"
		b.pressed.connect(_set_speed.bind(s))
		speed_buttons[s] = b
		speeds.add_child(b)
	# Le marché du soir est tiré le matin : on peut le consulter en journée pour s'organiser (influence, argent).
	var market_btn := Button.new()
	market_btn.text = "Marché du soir"
	market_btn.focus_mode = Control.FOCUS_NONE
	market_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	market_btn.custom_minimum_size.y = 46
	market_btn.theme_type_variation = "BoutonPrincipal"
	market_btn.tooltip_text = "Collaborateurs, contrats et cartes d'action proposés cette nuit, dans l'ordre d'influence"
	market_btn.pressed.connect(func():
		market_root.visible = not market_root.visible
		_rebuild_market_preview())
	bar.add_child(market_btn)
	var help := Button.new()
	help.text = "?"
	help.focus_mode = Control.FOCUS_NONE
	help.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	help.custom_minimum_size = Vector2(46, 46)
	help.tooltip_text = "Clic gauche : sélectionner (glisser pour plusieurs)\nClic droit : déplacer, extraire, construire, tenir un poste, lobbying (case Accès) · Maj + clic droit : enchaîner un ordre après la tâche en cours
Ctrl + glisser : sélectionner les bâtiments seulement · Maj + clic : ajouter un bâtiment · double-clic : tout un tracé de clôture, mur ou route · Suppr : démolir\nMenu de gauche : placer un bâtiment (glisser pour routes et clôtures, R pour tourner l'entrée), Échap pour arrêter\nMolette : zoom · ZQSD : vue · Espace : pause"
	help.pressed.connect(func(): ui.add_child(Aide.new(game.data)))
	bar.add_child(help)
	var quit_btn := Button.new()
	menu_btn = quit_btn
	quit_btn.text = "Menu"
	quit_btn.focus_mode = Control.FOCUS_NONE
	quit_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	quit_btn.custom_minimum_size = Vector2(0, 46)
	quit_btn.tooltip_text = "Retour au menu. La partie est sauvegardée chaque matin : « Continuer » reprendra au début de cette journée."
	quit_btn.pressed.connect(func(): _restart("menu"))
	bar.add_child(quit_btn)

	event_label = Label.new()
	event_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	event_label.offset_top = 70
	event_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var ev_style := UiTokens.panel(UiTokens.PAPIER, UiTokens.ENCRE, 10, 3, 8)
	ev_style.border_width_left = 14
	ev_style.border_color = UiTokens.ENCRE
	ev_style.content_margin_left = 14
	event_label.add_theme_stylebox_override("normal", ev_style)
	event_label.add_theme_color_override("font_color", UiTokens.TEXTE)
	event_label.add_theme_font_override("font", UiTokens.police_corps(700))
	event_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(event_label)

	# Panneau d'information à droite : bandeau sarcelle + fiche en cartes (zoo, ouvrier, chantier, animal)
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PAPIER, UiTokens.ENCRE, 12, 3, 0))
	right.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	right.offset_left = -318
	right.offset_right = -14
	right.offset_top = 72
	right.offset_bottom = -250
	ui.add_child(right)
	var rv0 := VBoxContainer.new()
	rv0.add_theme_constant_override("separation", 0)
	right.add_child(rv0)
	var rhead := PanelContainer.new()
	rhead.add_theme_stylebox_override("panel", UiTokens.bandeau())
	rv0.add_child(rhead)
	var rhb := HBoxContainer.new()
	rhead.add_child(rhb)
	zoo_title = Composants.label("VOTRE ZOO", "TitreBandeau")
	zoo_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoo_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rhb.add_child(zoo_title)
	info_subtitle = Composants.label("", "")
	info_subtitle.add_theme_color_override("font_color", Color(UiTokens.TEXTE_CLAIR, 0.9))
	info_subtitle.add_theme_font_size_override("font_size", 13)
	info_subtitle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rhb.add_child(info_subtitle)
	var rscroll := ScrollContainer.new()
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv0.add_child(rscroll)
	var rmargin := MarginContainer.new()
	rmargin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		rmargin.add_theme_constant_override("margin_" + side, 10)
	rmargin.add_theme_constant_override("margin_right", 14)
	rscroll.add_child(rmargin)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rmargin.add_child(rv)
	info_view = VBoxContainer.new()
	info_view.add_theme_constant_override("separation", 8)
	rv.add_child(info_view)
	info_text = RichTextLabel.new()
	info_text.bbcode_enabled = true
	info_text.fit_content = true
	info_text.scroll_active = false
	info_text.add_theme_font_size_override("normal_font_size", 14)
	info_text.add_theme_font_size_override("bold_font_size", 15)
	rv.add_child(info_text)
	info_extra = VBoxContainer.new()
	info_extra.add_theme_constant_override("separation", 4)
	rv.add_child(info_extra)
	btn_lobby = Button.new()
	btn_lobby.text = "Envoyer en lobbying"
	btn_lobby.focus_mode = Control.FOCUS_NONE
	btn_lobby.pressed.connect(func(): _cmd("order", [selected, game.map.exit_tile]))
	rv.add_child(btn_lobby)
	btn_recall = Button.new()
	btn_recall.text = "Rappeler sur la carte"
	btn_recall.focus_mode = Control.FOCUS_NONE
	btn_recall.pressed.connect(func():
		for w in selected:
			_cmd("recall", [w]))
	rv.add_child(btn_recall)
	btn_swap = Button.new()
	btn_swap.text = "Remplacer (Agence d'intérim)"
	btn_swap.focus_mode = Control.FOCUS_NONE
	btn_swap.pressed.connect(func():
		if selected.size() == 1:
			_open_swap_picker(selected[0]))
	rv.add_child(btn_swap)
	btn_cancel_site = Button.new()
	btn_cancel_site.text = "Annuler le chantier"
	btn_cancel_site.focus_mode = Control.FOCUS_NONE
	btn_cancel_site.pressed.connect(func():
		if selected_site:
			_cmd("cancel_site", [selected_site])
			selected_site = null)
	rv.add_child(btn_cancel_site)
	btn_demolish = Button.new()
	btn_demolish.text = "Démolir (sans remboursement)"
	btn_demolish.focus_mode = Control.FOCUS_NONE
	btn_demolish.pressed.connect(_delete_selection)
	rv.add_child(btn_demolish)
	# Bourse des ressources : vendre et acheter la quantité choisie (Marchand au camp ou au bâtiment Marché pour de meilleurs prix)
	if not spectator:
		var cm := _fiche_carte(rv, "BOURSE DES RESSOURCES", "metier_marchand", UiTokens.RESSOURCES["argent"]["couleur"])
		trade_card = cm.get_parent().get_parent()
		rv = cm
		trade_note = Composants.label("", "TexteSecondaire")
		trade_note.add_theme_font_size_override("font_size", 12)
		trade_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(trade_note)
		for res in ["bois", "pierre", "or"]:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			rv.add_child(row)
			var rd: Dictionary = UiTokens.RESSOURCES[res]
			var dot := Composants.pastille(rd["couleur"], rd["icone"], 22)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			dot.tooltip_text = rd["nom"]
			row.add_child(dot)
			var spin := SpinBox.new()
			spin.min_value = 1
			spin.max_value = 999
			spin.step = 1
			spin.value = 10
			spin.custom_minimum_size = Vector2(70, 0)
			spin.tooltip_text = "Quantité (molette ou flèches)"
			spin.get_line_edit().add_theme_font_size_override("font_size", 12)
			row.add_child(spin)
			var sb := Composants.bouton("", "BoutonSecondaire")
			sb.add_theme_font_size_override("font_size", 12)
			sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sb.pressed.connect(func(): _cmd("sell_amount", [res, int(spin.value)]))
			row.add_child(sb)
			var bb := Composants.bouton("", "BoutonSecondaire")
			bb.add_theme_font_size_override("font_size", 12)
			bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bb.pressed.connect(func(): _cmd("buy_material", [res, int(spin.value)]))
			bb.visible = res != "or"
			row.add_child(bb)
			trade_rows[res] = [spin, sb, bb]
		# Labels : de la réputation contre de l'or, achetés par un Marchand déployé (une fois chacun)
		var lt := Composants.label("Labels (or ; prix doublé sans Marchand mobilisé)", "TexteSecondaire")
		lt.add_theme_font_size_override("font_size", 12)
		rv.add_child(lt)
		for ld in game.label_defs():
			var lb := Composants.bouton("", "BoutonSecondaire")
			lb.add_theme_font_size_override("font_size", 12)
			lb.pressed.connect(func(): _cmd("buy_label", [ld]))
			rv.add_child(lb)
			label_buttons[ld["id"]] = lb
		# Publicité : campagnes menées par les ouvriers à l'extérieur, elles seules augmentent l'affluence
		rv = _fiche_carte(cm.get_parent().get_parent().get_parent(), "PUBLICITÉ", "ressource_influence", UiTokens.RESSOURCES["influence"]["couleur"])
		pub_note = Composants.label("", "TexteSecondaire")
		pub_note.add_theme_font_size_override("font_size", 12)
		pub_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(pub_note)
		var prow := HBoxContainer.new()
		prow.add_theme_constant_override("separation", 4)
		rv.add_child(prow)
		for d in game.campaign_defs():
			var pb := Composants.bouton("", "BoutonSecondaire")
			pb.add_theme_font_size_override("font_size", 11)
			pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pb.pressed.connect(func(): _cmd("launch_campaign", [d]))
			prow.add_child(pb)
			pub_buttons[d["id"]] = pb

	# Panneau Construire à gauche (l 250) : onglets Bâtiments / Zoo / Terrain, lignes à icône et coût
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PAPIER, UiTokens.ENCRE, 12, 3, 0))
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left.offset_left = 14
	left.offset_right = 270
	left.offset_top = 72
	left.offset_bottom = -250
	ui.add_child(left)
	var lv0 := VBoxContainer.new()
	lv0.add_theme_constant_override("separation", 0)
	left.add_child(lv0)
	var lhead := PanelContainer.new()
	lhead.add_theme_stylebox_override("panel", UiTokens.bandeau())
	lv0.add_child(lhead)
	lhead.add_child(Composants.label("CONSTRUIRE", "TitreBandeau"))
	var lmargin := MarginContainer.new()
	lmargin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		lmargin.add_theme_constant_override("margin_" + side, 10)
	lv0.add_child(lmargin)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	lmargin.add_child(lv)
	contracts_box = VBoxContainer.new()
	lv.add_child(contracts_box)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 5)
	lv.add_child(tabs)
	var group := ButtonGroup.new()
	var pages := {
		"Bâtiments": ["route", "pont", "maison", "entrepot", "comptoir", "agence", "cabinet", "mine", "formation", "camp_n2", "camp_n3"],
		"Zoo": ["cloture", "entree", "enclos", "grand_arbre", "rocher_obs", "bassin_profond", "abri_chaud", "boutique", "cuisine", "entretien", "snack", "kiosque"],
		"Terrain": [],
	}
	for tab_name in pages:
		var tb := Button.new()
		tb.text = tab_name
		tb.toggle_mode = true
		tb.button_group = group
		tb.focus_mode = Control.FOCUS_NONE
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.theme_type_variation = "Onglet"
		tb.custom_minimum_size.y = 34
		tb.add_theme_font_size_override("font_size", 14)
		tabs.add_child(tb)
		build_tabs[tab_name] = tb
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lv.add_child(scroll)
		var page := VBoxContainer.new()
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_theme_constant_override("separation", 6)
		scroll.add_child(page)
		build_pages[tab_name] = scroll
		if tab_name == "Terrain":
			for a in game.amenagement_defs():
				_build_button(page, "amenagement", a)
		else:
			for id in pages[tab_name]:
				var def := game.building_def(id)
				if not def.is_empty():
					_build_button(page, "batiment", def)
		tb.pressed.connect(func():
			for k in build_pages:
				build_pages[k].visible = k == tab_name)
	build_tabs["Bâtiments"].button_pressed = true
	for k in build_pages:
		build_pages[k].visible = k == "Bâtiments"

	# Bas de l'écran : pioche et défausse, main de cartes, médaillon du jour (capture 03)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	shade.offset_top = -238
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	pile_panel = PanelContainer.new()
	pile_panel.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.SARCELLE, UiTokens.ENCRE, 14, 3, 8))
	pile_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pile_panel.offset_left = 14
	pile_panel.offset_right = 112
	pile_panel.offset_top = -200
	pile_panel.offset_bottom = -14
	ui.add_child(pile_panel)
	var pv := VBoxContainer.new()
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pile_panel.add_child(pv)
	var pico := Composants.icone_rect("ui_pioche", Vector2(40, 40), UiTokens.TEXTE_CLAIR)
	pico.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pv.add_child(pico)
	pile_label = Composants.label("", "")
	pile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pile_label.add_theme_color_override("font_color", UiTokens.TEXTE_CLAIR)
	pile_label.add_theme_font_override("font", UiTokens.police_corps(700))
	pile_label.add_theme_font_size_override("font_size", 14)
	pv.add_child(pile_label)
	pile_panel.tooltip_text = "Cliquez pour voir les cartes de la pioche et de la défausse"
	pile_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pile_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			pile_panel.accept_event()
			if ev.pressed:
				_open_pile())
	loan_btn = Composants.bouton("", "BoutonPrincipal")
	loan_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	loan_btn.offset_left = 14
	loan_btn.offset_right = 264
	loan_btn.offset_top = -246
	loan_btn.offset_bottom = -210
	loan_btn.visible = false
	loan_btn.pressed.connect(func(): _cmd("take_loan"))
	ui.add_child(loan_btn)
	rotate_btn = Composants.bouton("⟲ Tourner (R)", "BoutonPrincipal")
	rotate_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	rotate_btn.offset_left = -90
	rotate_btn.offset_right = 90
	rotate_btn.offset_top = 76
	rotate_btn.offset_bottom = 114
	rotate_btn.focus_mode = Control.FOCUS_NONE
	rotate_btn.visible = false
	rotate_btn.tooltip_text = "Tourne le bâtiment à poser d'un quart de tour (entrée du zoo verticale ou horizontale)"
	rotate_btn.pressed.connect(_rotate_build)
	ui.add_child(rotate_btn)
	# Tout déployer : chaque carte de la main payable part sur le terrain (au-dessus de la pioche)
	deploy_all_btn = Composants.bouton("Tout mobiliser", "BoutonPrincipal")
	deploy_all_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	deploy_all_btn.offset_left = 16
	deploy_all_btn.offset_right = 160
	deploy_all_btn.offset_top = -244
	deploy_all_btn.offset_bottom = -206
	deploy_all_btn.tooltip_text = "Mobilise toutes les cartes collaborateurs de la main, tant que l'argent suffit à payer leur salaire"
	deploy_all_btn.pressed.connect(_deploy_all)
	ui.add_child(deploy_all_btn)
	hand_scroll = ScrollContainer.new()
	hand_scroll.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hand_scroll.offset_left = 124
	hand_scroll.offset_right = -200
	hand_scroll.offset_top = -236
	hand_scroll.offset_bottom = -6
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.add_child(hand_scroll)
	hand_box = HBoxContainer.new()
	hand_box.add_theme_constant_override("separation", 8)
	hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_box.size_flags_vertical = Control.SIZE_SHRINK_END
	hand_box.custom_minimum_size.y = 228
	hand_scroll.add_child(hand_box)
	medallion = Control.new()
	medallion.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	medallion.offset_left = -178
	medallion.offset_right = -24
	medallion.offset_top = -228
	medallion.offset_bottom = -74
	medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medallion.draw.connect(_draw_medallion)
	ui.add_child(medallion)
	end_day_btn = Button.new()
	end_day_btn.text = "TERMINER LA JOURNÉE"
	end_day_btn.theme_type_variation = "BoutonFort"
	end_day_btn.focus_mode = Control.FOCUS_NONE
	end_day_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	end_day_btn.offset_left = -222
	end_day_btn.offset_right = -18
	end_day_btn.offset_top = -64
	end_day_btn.offset_bottom = -18
	end_day_btn.pressed.connect(func():
		if reseau:
			reseau.basculer_pret()
		elif tutoriel == null or tutoriel.fin_de_journee_permise():
			game.end_day())
	end_day_btn.visible = not spectator
	ui.add_child(end_day_btn)

	status_label = Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	status_label.offset_top = -272
	status_label.offset_bottom = -244
	status_label.offset_left = 276
	status_label.add_theme_stylebox_override("normal", UiTokens.panel(UiTokens.PAPIER, UiTokens.ENCRE, 8, 2, 6))
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(status_label)

	toast_box = VBoxContainer.new()
	toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_box.offset_top = 196
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(toast_box)

	day_hud = [left, right, shade, pile_panel, hand_scroll, medallion, deploy_all_btn]
	_build_proposal_box()
	_build_unit_panel()
	_build_night_ui()
	_build_end_ui()

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


## Médaillon du jour (Ø 154) : anneau doré qui se vide au fil de la journée, jour et temps restant au centre.
func _draw_medallion() -> void:
	var s := medallion.size
	var c := s / 2.0
	var r := minf(s.x, s.y) / 2.0 - 6.0
	var ink := UiTokens.ENCRE
	medallion.draw_circle(c + Vector2(4, 4), r, ink)
	medallion.draw_circle(c, r, UiTokens.PAPIER)
	medallion.draw_arc(c, r, 0, TAU, 72, ink, 3.0, true)
	var frac := clampf(1.0 - game.time / game.day_length, 0.0, 1.0) if game.phase == "day" else 0.0
	var n := 12
	var r_out := r - 6.0
	var r_in := r - 26.0
	for i in n:
		var a0 := -PI / 2.0 + TAU * i / n + 0.035
		var a1 := -PI / 2.0 + TAU * (i + 1) / n - 0.035
		var pts := PackedVector2Array()
		for k in 7:
			var a := lerpf(a0, a1, k / 6.0)
			pts.append(c + Vector2(cos(a), sin(a)) * r_out)
		for k in 7:
			var a := lerpf(a1, a0, k / 6.0)
			pts.append(c + Vector2(cos(a), sin(a)) * r_in)
		var on := float(i) / n < frac
		medallion.draw_colored_polygon(pts, (UiTokens.SELECTION if frac > 0.2 else UiTokens.ORANGE) if on else Color("DDE6E3"))
		pts.append(pts[0])
		medallion.draw_polyline(pts, ink, 2.0, true)
	medallion.draw_arc(c, r_in, 0, TAU, 64, ink, 2.5, true)
	var titre := UiTokens.police_titre()
	var left := maxf(0.0, game.day_length - game.time)
	medallion.draw_string(titre, Vector2(0, c.y - 14), "JOUR %d" % game.day, HORIZONTAL_ALIGNMENT_CENTER, s.x, 15, ink)
	medallion.draw_string(titre, Vector2(0, c.y + 16), "%d:%02d" % [int(left) / 60, int(left) % 60] if game.phase == "day" else "NUIT",
		HORIZONTAL_ALIGNMENT_CENTER, s.x, 32, ink)


func _menu_title(parent: Control, text: String) -> void:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_color_override("font_color", UiTokens.TEXTE)
	l.add_theme_font_override("font", UiTokens.police_titre())
	l.add_theme_font_size_override("font_size", 16)
	parent.add_child(l)


## Ligne du panneau Construire (h 54) : pastille d'icône, nom, coût en jetons, durée ; survol = filet or à gauche.
func _build_button(parent: Control, kind: String, def: Dictionary) -> void:
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 54)
	var flat := UiTokens._button(UiTokens.PAPIER, Color("C9D2D0"), 10)
	var hover := UiTokens._button(Color("FFF8E6"), UiTokens.ENCRE, 10)
	var pressed := UiTokens._button(Color("FFF4D6"), UiTokens.ENCRE, 10, true)
	b.add_theme_stylebox_override("normal", flat)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_right = -6
	b.add_child(row)
	var col: Color = building_colors.get(def["id"], UiTokens.ENTETE)
	if kind == "amenagement":
		col = terrain_colors[GameMap.TERRAINS.find(str(def["vers"]))]
	var ico: Control
	var vignette: String = SpritesBD.BATIMENTS.get(def["id"], "")
	if def["id"] in ["camp_n2", "camp_n3"]:
		vignette = SpritesBD.CAMPS[1 if def["id"] == "camp_n2" else 2]
	elif def["id"] == "pont":
		vignette = "pont"
	if kind != "amenagement" and vignette != "" and SpritesBD.existe(vignette):
		var cadre := PanelContainer.new()
		var cs := UiTokens._button(Color("E7F2DA"), UiTokens.ENCRE, 8)
		cs.set_border_width_all(2)
		cs.set_content_margin_all(2)
		cadre.add_theme_stylebox_override("panel", cs)
		cadre.custom_minimum_size = Vector2(50, 42)
		cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var vt := TextureRect.new()
		vt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vt.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		vt.texture = SpritesBD.texture(vignette)
		vt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cadre.add_child(vt)
		ico = cadre
	else:
		ico = Composants.pastille(col.darkened(0.15), Composants.icone_batiment(def["id"]), 38)
	ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ico)
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 0)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mid)
	var nm := Composants.label(def["nom"].replace(" (segment)", ""))
	nm.add_theme_font_override("font", UiTokens.police_corps(700))
	nm.add_theme_font_size_override("font_size", 14)
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	mid.add_child(nm)
	var costs := HBoxContainer.new()
	costs.add_theme_constant_override("separation", 6)
	costs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(costs)
	var cost: Dictionary = def.get("cout", {})
	for k in ["bois", "pierre", "argent", "or"]:
		if cost.has(k):
			var res: Dictionary = UiTokens.RESSOURCES[k]
			var dot := Panel.new()
			var ds := StyleBoxFlat.new()
			ds.bg_color = res["couleur"]
			ds.set_corner_radius_all(5)
			ds.border_color = UiTokens.ENCRE
			ds.set_border_width_all(1)
			dot.add_theme_stylebox_override("panel", ds)
			dot.custom_minimum_size = Vector2(10, 10)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			costs.add_child(dot)
			var cv := Composants.label(str(int(cost[k])), "TexteSecondaire")
			cv.add_theme_font_size_override("font_size", 12)
			costs.add_child(cv)
	if cost.is_empty():
		costs.add_child(Composants.label("gratuit", "TexteSecondaire"))
	var dur := Composants.label("%d:%02d" % [int(def["travail"]) / 60, int(def["travail"]) % 60], "NomCarte")
	dur.add_theme_font_size_override("font_size", 15)
	dur.tooltip_text = "Durée pour un collaborateur à 100 %"
	row.add_child(dur)
	var tip: Array[String] = ["%s : %s" % [def["nom"], game.cost_text(cost) if not cost.is_empty() else "gratuit"], "Travail : %d" % int(def["travail"])]
	if kind == "amenagement":
		var de = def["de"]
		tip.append("%s → %s" % [" ou ".join(de if de is Array else [de]), def["vers"]])
		tip.append("Spécialistes : Terrassier, Paysagiste")
	else:
		tip.append("Taille : %dx%d" % [int(def["taille"][0]), int(def["taille"][1])])
		tip.append("Type de travail : %s" % def["type_travail"])
		if def.has("sur"):
			tip.append("Se construit sur : %s" % ("le camp" if def["sur"] == "camp" else def["sur"]))
		if def.get("unique", false):
			tip.append("Unique")
	if def.has("_note_effet"):
		tip.append(def["_note_effet"])
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
	info.text = "Cette nuit, on achète dans l'ordre d'influence (valeurs cachées) : 1 collaborateur et jusqu'à 2 contrats chacun, et le premier choisit le bonus de demain pour tous.\nVotre influence : [b]%.1f[/b]%s. Envoyez des collaborateurs en lobbying (case Accès) pour passer devant." % [
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
		actions.add_child(_action_widget(card, "Prix ce soir : %d" % game.action_price(card), true, func(): pass))
	market_box.add_child(actions)
	var close := Button.new()
	close.text = "Fermer"
	close.theme_type_variation = "BoutonPrincipal"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): market_root.visible = false)
	market_box.add_child(close)


func _overlay() -> Array:
	var root := ColorRect.new()
	root.color = Color(UiTokens.MARINE, 0.6)
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
		return "[color=#4A5664]Aucun trait[/color]"
	var parts: Array[String] = []
	for t in game.trait_defs(card):
		var pos := game.is_positive(t["id"])
		parts.append("[color=%s]%s %s[/color]" % ["#3A8AE8" if pos else "#E8782A", "● +" if pos else "■ −", t["nom"]])
	for u in card.upgrade_names:
		parts.append("[color=#8A6A00]★ %s[/color]" % u)
	return "  ".join(parts)


const TACHES_NOMS := {"extraire_bois": "couper du bois", "extraire_pierre": "extraire la pierre", "extraire_or": "miner l'or",
	"construire_bois": "construire en bois", "construire_pierre": "construire en pierre", "construire_enclos": "poser les clôtures d'enclos",
	"construire_route": "tracer les routes", "amenager": "aménager le terrain", "lobbying": "faire du lobbying en ville",
	"guichet": "tenir le guichet", "nourrir": "nourrir les animaux", "nettoyer": "nettoyer le parc", "soigner": "soigner les animaux",
	"animer": "animer le kiosque"}


## Le nom d'un ouvrier, survolé, montre sa carte complète.
func _hover_card(ctrl: Control, card: GameState.Card) -> void:
	ctrl.mouse_filter = Control.MOUSE_FILTER_PASS
	ctrl.mouse_default_cursor_shape = Control.CURSOR_HELP
	ctrl.mouse_entered.connect(_show_hover_card.bind(card, ctrl))


func _show_hover_card(card: GameState.Card, ctrl: Control) -> void:
	_hide_hover_card()
	var w := Composants.carte_ouvrier(Composants.donnees_ouvrier(game, card), "normale", "marche", [])
	w.top_level = true
	for c in [w] + w.find_children("*", "Control", true, false):
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(w)
	var r := ctrl.get_global_rect()
	var vp := get_viewport_rect().size
	var sz := w.custom_minimum_size
	var pos := Vector2(r.end.x + 12, r.position.y - 40)
	if pos.x + sz.x > vp.x - 8:
		pos.x = r.position.x - sz.x - 12
	pos.y = clampf(pos.y, 8, vp.y - sz.y - 8)
	w.global_position = pos
	hover_card = w
	hover_src = ctrl


func _hide_hover_card() -> void:
	if hover_card and is_instance_valid(hover_card):
		hover_card.queue_free()
	hover_card = null
	hover_src = null


## Le métier en une phrase : ce qu'il fait mieux (ou moins bien) que les autres, avec son rendement.
func _job_text(card: GameState.Card) -> String:
	var eff: Dictionary = card.metier["efficacite"]
	var base := float(eff.get("defaut", 1.0))
	var best: Array[String] = []
	for k in eff:
		if k != "defaut" and TACHES_NOMS.has(k):
			best.append("%s ×%s" % [TACHES_NOMS[k], ("%.1f" % float(eff[k])).replace(".", ",")])
	var cat := str(UiTokens.CATEGORIES[card.metier["categorie"]]["long"]).to_lower()
	if game.is_female(card) and cat.ends_with("é"):
		cat += "e"  # qualifiée, peu qualifiée
	var line := "Métier : %s (%s). " % [game.job_name(card), cat]
	if best.is_empty():
		line += "Polyvalent : rendement ×%s partout." % ("%.1f" % base).replace(".", ",")
	else:
		line += "Spécialité : %s ; ailleurs ×%s." % [", ".join(best), ("%.1f" % base).replace(".", ",")]
	return line


func _card_tooltip(card: GameState.Card) -> String:
	var lines: Array[String] = [_job_text(card)]
	if card.metier.has("capacite"):
		lines.append("Capacité : " + str(card.metier["capacite"]))
	var A := game.cadre_action(card)
	if not A.is_empty():
		lines.append("Jouée comme action (%s) : %s" % [A["nom"], A["texte"]])
	for t in game.trait_defs(card):
		var txt: String = t.get("texte", "")
		if txt == "":
			var effets: Array[String] = []
			for k in t["effet"]:
				effets.append("%s %s" % [k, str(t["effet"][k])])
			txt = ", ".join(effets)
		lines.append("%s : %s" % [t["nom"], txt])
	return "\n".join(lines)


## Carte ouvrier Émeraude hors de la main (draft 146×196, marché 160×236) : un bouton, un second facultatif.
func _card_widget(card: GameState.Card, button_text: String, disabled: bool, cb: Callable, extra: Array = [], taille := "marche") -> Control:
	var boutons := [[button_text, "BoutonPrincipal", disabled, cb]]
	if not extra.is_empty():
		boutons.append([extra[0], "BoutonSecondaire", extra[1], extra[2]])
	var w := Composants.carte_ouvrier(Composants.donnees_ouvrier(game, card), "normale", taille, boutons)
	w.tooltip_text = _card_full_tooltip(card)
	return w


## Infobulle complète d'une carte ouvrier : identité, traits nommés, capacité et effets.
func _card_full_tooltip(card: GameState.Card) -> String:
	return "%s · %s, niveau %d · salaire %d\n%s\n%s" % [card.nom, game.job_name(card), card.niveau, game.salary(card),
		RegEx.create_from_string("\\[[^\\]]*\\]").sub(_traits_bbcode(card), "", true), _card_tooltip(card)]


func _rebuild_hand() -> void:
	for c in hand_box.get_children():
		c.queue_free()
	if game.phase == "draft":
		return
	if game.hand.is_empty():
		var l := Composants.label("Main vide : la nuit tombe.", "TexteSecondaire")
		hand_box.add_child(l)
		return
	deploy_all_btn.disabled = spectator or game.phase != "day" or not game.hand.any(func(c): return not c.is_action() and not c.deployed)
	# Cartes Émeraude 136×216 (capture 03) : à déployer, sur le terrain, en lobbying, ou carte d'action
	for card in game.hand:
		if card.is_action():
			var ciblee: bool = card.action.get("cible", false)
			hand_box.add_child(Composants.carte_action(card, "Choisir…" if ciblee else "Jouer", spectator or game.phase != "day",
				_open_action_picker.bind(card) if ciblee else _cmd.bind("play_action", [card])))
			continue
		var w := game.worker_of(card)
		var d := Composants.donnees_ouvrier(game, card)
		var widget: Control
		if not card.deployed:
			var sal := 0 if game.prime_left > 0 else game.salary(card)
			var short := game.money < sal
			var main_btn := ["Prime" if game.prime_left > 0 else ("Manque %d" % ceili(sal - game.money) if short else "Mobiliser"),
				"BoutonPrincipal", spectator or short, _on_deploy.bind(card)]
			var free_btn := ["25" + Composants.NBSP + "%", "BoutonSecondaire", spectator or not game.free_deploy_available(), _on_deploy_free.bind(card)]
			var btns := [main_btn, free_btn]
			var A := game.cadre_action(card)
			if not A.is_empty():
				btns.append(["Jouer", "BoutonOrdre", spectator or game.phase != "day", _on_play_cadre.bind(card),
					"%s : %s
Le cadre ne travaille pas aujourd'hui (pas de salaire) et part à la défausse." % [A["nom"], A["texte"]]])
			widget = Composants.carte_ouvrier(d, "non_abordable" if short else "normale", "main", btns)
		elif w and w.offmap:
			widget = Composants.carte_ouvrier(d, "hors_carte", "main", [["Rappeler", "BoutonSecondaire", spectator, _on_recall.bind(w)]],
				["LOBBYING", Color("6A3AB0")], _on_focus.bind(w))
		else:
			var tag := ["GRATUIT 25" + Composants.NBSP + "%", Color("18A88A")] if w and w.unpaid else ["SUR LE TERRAIN", UiTokens.MARINE]
			widget = Composants.carte_ouvrier(d, "deployee", "main", [["Localiser", "BoutonSecondaire", false, _on_focus.bind(w)]],
				tag, _on_focus.bind(w))
		widget.tooltip_text = _card_full_tooltip(card)
		hand_box.add_child(widget)


## Carte d'action au marché (format marché) : nom, effet, un bouton (acheter…).
func _action_widget(card: GameState.Card, button_text: String, disabled: bool, cb: Callable) -> Control:
	var w := Composants.carte_action(card, button_text, disabled, cb, "marche")
	w.tooltip_text = "%s : %s" % [card.action["nom"], card.action["texte"]]
	return w


func _deploy_all() -> void:
	for card in game.hand.duplicate():
		if not card.is_action() and not card.deployed and game.money >= (0 if game.prime_left > 0 else game.salary(card)):
			_cmd("deploy", [card])


func _on_deploy(card: GameState.Card) -> void:
	if _cmd("deploy", [card]):
		selected = [game.worker_of(card)]
	elif reseau:
		a_selectionner = card


func _on_deploy_free(card: GameState.Card) -> void:
	if _cmd("deploy", [card, true]):
		selected = [game.worker_of(card)]
	elif reseau:
		a_selectionner = card


## Mode spectateur : affiche le zoo d'une autre IA.
func _view_player(i: int) -> void:
	game = mt.players[i]
	for k in view_buttons.size():
		view_buttons[k].button_pressed = k == i
	selected.clear()
	selected_site = null
	build_choice = {}
	_refresh_terrain(true)
	hand_version = -1
	_focus_zoo()


## Fin de partie : montre la carte finale du zoo de ce joueur.
func _watch_board(i: int) -> void:
	end_dismissed = true
	_view_player(i)
	var interior: Array = game.zoo_status()["interior"].keys()
	if not interior.is_empty():
		var c := Vector2.ZERO
		for t in interior:
			c += Vector2(t)
		camera.position = (c / interior.size() + Vector2(0.5, 0.5)) * TILE
		camera.zoom = Vector2(1.3, 1.3)
	elif mt.ais[i] == null:
		camera.position = Vector2(game.map.camp.get_center()) * TILE


## Mode spectateur : centre la caméra sur l'enceinte prévue par l'IA regardée.
func _focus_zoo() -> void:
	if not spectator or mt.ais[game.index] == null:
		return
	var zr: Rect2i = mt.ais[game.index].zoo_rect
	if zr.size != Vector2i.ZERO:
		camera.position = Vector2(zr.get_center()) * TILE
		camera.zoom = Vector2(1.3, 1.3)


func _on_recall(w: GameState.Worker) -> void:
	_cmd("recall", [w])
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
			order.append("[color=#4A5664]%s[/color]" % nom)
		elif i == pos_in_round:
			order.append("[color=#8A6A00][b]%s[/b][/color]" % nom)
		else:
			order.append(nom)
	draft_order_lbl.text = "Ordre du tour : %s\n[color=#4A5664]%d cartes révélées, une chacun. Le premier à choisir change à chaque tour.%s[/color]" % [
		"  ›  ".join(order), mt.draft_round_size(),
		" La dernière carte revient d'office au dernier joueur." if mt.draft_round_size() == mt.players.size() else " Les cartes restantes sont défaussées."]
	for card in mt.draft_pool:
		draft_grid.add_child(_card_widget(card, "Choisir", not my_turn, _cmd.bind("pick_draft", [card])))
	var lines: Array[String] = []
	for p in mt.players.size():
		var names: Array[String] = []
		for c in mt.drafted[p]:
			names.append("%s ([color=%s]%s[/color])" % [c.nom, category_colors[c.metier["categorie"]].to_html(false), game.job_name(c)])
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
	if w.task["type"] == "deposit":
		return "Va déposer sa charge (%d %s)" % [floori(w.carry), res_noms.get(w.carry_type, "")]
	if w.task["type"] == "station":
		if not w.path.is_empty():
			return "Va à son poste"
		if w.task["kind"] == "formation":
			return "Forme les collaborateurs du centre" if w.card.metier["id"] == "formateur" else "Se forme au centre de formation"
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
	_update_unit_panel()
	selected_sites = selected_sites.filter(func(x): return game.sites.has(x))
	if selected_animal and not game.animals.has(selected_animal):
		selected_animal = null
	var show_animal := selected.is_empty() and selected_animal != null and selected_site == null
	if not show_animal and info_extra_for != null:
		info_extra_for = null
		_clear(info_extra)
	info_text.visible = show_animal
	info_subtitle.text = ""
	var fiche: Array = []
	if show_animal:
		_animal_info(selected_animal)
	elif selected.is_empty() and selected_sites.size() > 1:
		zoo_title.text = "%d ÉLÉMENTS" % selected_sites.size()
		var counts := {}
		for x in selected_sites:
			var key: String = ("Chantier : " if not x.done else "") + str(x.def["nom"])
			counts[key] = counts.get(key, 0) + 1
		fiche.append(["carte", "SÉLECTION", "ui_valide", UiTokens.SARCELLE])
		for k in counts:
			fiche.append(["ligne", "", Color(), k, "× %d" % counts[k]])
		fiche.append(["texte", "Suppr : démolit les bâtiments (sans remboursement) et annule les chantiers (remboursés à 100 % s'ils n'ont pas commencé, 50 % sinon)."])
		btn_lobby.visible = false
		btn_recall.visible = false
		btn_swap.visible = false
		btn_cancel_site.visible = false
		btn_demolish.visible = not spectator
		btn_demolish.text = "Démolir / annuler la sélection (Suppr)"
		_rendre_fiche(fiche)
		return
	btn_demolish.text = "Démolir (sans remboursement)"
	if show_animal:
		btn_lobby.visible = false
		btn_recall.visible = false
		btn_swap.visible = false
		btn_cancel_site.visible = false
		btn_demolish.visible = false
		_rendre_fiche([])
		return
	if selected.size() > 1:
		zoo_title.text = "%d COLLABORATEURS" % selected.size()
	elif selected.size() == 1:
		zoo_title.text = "COLLABORATEUR"
		info_subtitle.text = "%d sur %d" % [game.workers.find(selected[0]) + 1, game.workers.size()]
	elif selected_site:
		zoo_title.text = "BÂTIMENT" if selected_site.done else "CHANTIER"
	else:
		zoo_title.text = "VOTRE ZOO" if not spectator else mt.names[game.index].to_upper()
		info_subtitle.text = "partie terminée" if mt.game_over else "jour %d" % mt.day
	btn_lobby.visible = not selected.is_empty()
	btn_lobby.disabled = selected.is_empty() or game.phase != "day"
	btn_recall.visible = selected.any(func(w): return w.offmap)
	btn_recall.disabled = not btn_recall.visible
	btn_swap.visible = not spectator and selected.size() == 1 and game.agency_built() and game.phase == "day"
	if btn_swap.visible:
		var serr := game.swap_error(selected[0], null)
		btn_swap.disabled = not serr.begins_with("Choisissez une carte")
		btn_swap.tooltip_text = "Échanger %s contre une carte de votre pioche ou défausse (une fois par jour)" % selected[0].card.nom if not btn_swap.disabled else serr
	btn_cancel_site.visible = selected_site != null and not selected_site.done
	btn_demolish.visible = not spectator and selected_site != null and selected_site.done and selected_site.kind == "batiment"
	if selected.is_empty() and selected_site:
		var st := selected_site
		var builders := game.workers.filter(func(w): return w.task.get("site") == st).size()
		fiche.append(["image", SpritesBD.BATIMENTS.get(st.def_id(), "chantier1" if not st.done else "")])
		fiche.append(["titre", str(st.def["nom"]), "Terminé" if st.done else "Chantier en cours"])
		if st.done:
			fiche.append(["carte", "EFFET", Composants.icone_batiment(st.def_id()), UiTokens.SARCELLE])
			match st.def_id():
				"maison":
					fiche.append(["ligne", "ressource_logement", UiTokens.RESSOURCES["logement"]["couleur"], "Logement", "+%d" % int(st.def["effet"]["logement"])])
				"entrepot":
					fiche.append(["texte", "Dépôt de ressources : les collaborateurs y rapportent leur charge s'il est plus proche que le camp."])
				"mine":
					fiche.append(["texte", "Clic droit avec des collaborateurs pour extraire de l'or."])
				_:
					fiche.append(["texte", str(st.def.get("_note_effet", "Bâtiment en service."))])
		else:
			fiche.append(["carte", "AVANCEMENT", "ordre_construire", UiTokens.ORANGE])
			fiche.append(["barre", "Travail", clampf(st.work / st.travail(), 0.0, 1.0), "%d / %d" % [int(st.work), int(st.travail())], UiTokens.SELECTION])
			fiche.append(["ligne", "metier_contremaitre", UiTokens.SARCELLE, "Collaborateurs dessus", str(builders)])
			fiche.append(["ligne", "ressource_argent", UiTokens.RESSOURCES["argent"]["couleur"], "Coût payé", game.cost_text(st.paid) if not st.paid.is_empty() else "—"])
			fiche.append(["texte", "Clic droit avec des collaborateurs sélectionnés pour y travailler. L'avancement est conservé d'un jour à l'autre."])
		_rendre_fiche(fiche)
		return
	if selected.is_empty():
		_fiche_zoo(fiche)
		_rendre_fiche(fiche)
		return
	if selected.size() > 1:
		fiche.append(["carte", "ÉQUIPE", "metier_contremaitre", UiTokens.SARCELLE])
		for w in selected:
			fiche.append(["ligne", Composants.icone_metier(str(w.card.metier["id"])), UiTokens.CATEGORIES[w.card.metier["categorie"]]["couleur"], w.card.nom, _task_text(w), w.card])
		_rendre_fiche(fiche)
		return
	var w: GameState.Worker = selected[0]
	var c := w.card
	fiche.append(["ouvrier", w])
	fiche.append(["carte", "TÂCHE", "ordre_construire", UiTokens.ORANGE])
	fiche.append(["texte_fort", _task_text(w)])
	var cap := game.carry_capacity(c)
	fiche.append(["barre", "Charge", clampf(w.carry / maxf(1.0, cap), 0.0, 1.0), "%.1f / %d" % [w.carry, cap], UiTokens.RESSOURCES.get(w.carry_type, {"couleur": UiTokens.ORANGE})["couleur"]])
	if w.task.get("type") == "build":
		var bs: GameState.Site = w.task["site"]
		fiche.append(["barre", "Chantier", clampf(bs.work / bs.travail(), 0.0, 1.0), "%d %%" % roundi(100.0 * bs.work / bs.travail()), UiTokens.SELECTION])
	fiche.append(["ordres"])
	fiche.append(["carte", "RENDEMENT", "qualite_rapide", UiTokens.QUALITE])
	fiche.append(["ligne", "qualite_rapide", UiTokens.QUALITE, "Vitesse", "%.2f case/s" % game.speed(c)])
	for e in [["ressource_bois", "bois", "Bois", "extraire_bois"], ["ressource_pierre", "pierre", "Pierre", "extraire_pierre"], ["ressource_or", "or", "Or", "extraire_or"],
			["ressource_influence", "influence", "Lobbying", "lobbying"]]:
		fiche.append(["coef", e[0], UiTokens.RESSOURCES[e[1]]["couleur"], e[2], game.efficiency(c, e[3])])
	fiche.append(["coef", "ordre_construire", UiTokens.ORANGE, "Construire (bois)", game.efficiency(c, "construire_bois")])
	fiche.append(["coef", "ordre_construire", UiTokens.ORANGE, "Construire (pierre)", game.efficiency(c, "construire_pierre")])
	fiche.append(["coef", "ordre_amenager", UiTokens.SARCELLE, "Aménager", game.efficiency(c, "amenager")])
	fiche.append(["coef", "batiment_route", UiTokens.SARCELLE, "Routes", game.efficiency(c, "construire_route")])
	fiche.append(["carte", "CARRIÈRE", "ui_ameliorer", UiTokens.RESSOURCES["reputation"]["couleur"]])
	fiche.append(["ligne", "ressource_argent", UiTokens.RESSOURCES["argent"]["couleur"], "Salaire", "%d / jour" % game.salary(c)])
	var team := game.aura_mult(w)
	if not is_equal_approx(team, 1.0):
		fiche.append(["ligne", "metier_contremaitre", UiTokens.SARCELLE, "Bonus d'équipe reçu", "%+d %%" % roundi((team - 1.0) * 100)])
	for a in game.auras_of(c):
		fiche.append(["ligne", "ressource_reputation", UiTokens.SARCELLE, "Effet de zone (rayon %s)" % str(a["rayon"]), "%+d %%" % roundi(float(a["bonus"]) * 100)])
	if c.niveau < 4:
		var nxt := maxf(1.0, game.xp_next_level(c))
		fiche.append(["barre", "Expérience", clampf(c.xp / nxt, 0.0, 1.0), "%.1f / %d j%s" % [c.xp, roundi(nxt), "  ×%.1f" % game.xp_mult(c) if game.xp_mult(c) != 1.0 else ""], UiTokens.RESSOURCES["reputation"]["couleur"]])
	else:
		fiche.append(["texte", "Niveau maximum atteint."])
	_rendre_fiche(fiche)


## Fiche « votre zoo » (aucune sélection) : état, visiteurs, recettes du jour, entretien, alertes, bonus.
func _fiche_zoo(fiche: Array) -> void:
	var z := game.zoo_live()
	var hungry := game.animals.filter(func(a): return a.arrived and not a.fed).size()
	fiche.append(["etat", z["open"], "Zoo ouvert" if z["open"] else "Zoo fermé", "" if z["open"] else str(z["reason"])])
	if z["open"]:
		fiche.append(["chiffres", [["%d" % z["attract"], "attractivité", "ressource_reputation", UiTokens.RESSOURCES["reputation"]["couleur"]],
			["+%d %%" % roundi((z["pub"] - 1.0) * 100), "publicité", "ressource_influence", UiTokens.RESSOURCES["influence"]["couleur"]]]])
		fiche.append(["carte", "VISITEURS", "ressource_visiteurs", UiTokens.SARCELLE])
		fiche.append(["barre", "Dans le zoo", clampf(float(z["inside"]) / maxf(1.0, z["capacity"]), 0.0, 1.0), "%d / %d" % [z["inside"], z["capacity"]],
			UiTokens.ORANGE if z["inside"] >= z["capacity"] else UiTokens.SELECTION])
		fiche.append(["ligne", "batiment_route", UiTokens.CHEMIN.darkened(0.3), "Sur la route", str(z["road"])])
		fiche.append(["ligne", "batiment_entree_zoo", UiTokens.SARCELLE, "En file d'attente", str(z["queue"])])
		fiche.append(["ligne", "ressource_visiteurs", UiTokens.QUALITE, "Demande estimée", "≈ %d / jour" % roundi(z["demand_day"])])
		fiche.append(["ligne", "metier_vendeur_souvenirs", UiTokens.SARCELLE, "Guichet", "%d / min" % roundi(z["guichet_min"])])
		fiche.append(["carte", "AUJOURD'HUI", "ressource_argent", UiTokens.RESSOURCES["argent"]["couleur"]])
		fiche.append(["chiffres", [["%d" % z["admitted"], "entrés", "ui_valide", UiTokens.QUALITE], ["%d" % z["lost"], "repartis", "ui_invalide", UiTokens.ORANGE]]])
		fiche.append(["ligne", "ressource_billetterie", UiTokens.RESSOURCES["argent"]["couleur"], "Billets", "%d" % z["tickets"]])
		fiche.append(["ligne", "batiment_boutique", Color("E06A5A"), "Souvenirs", "%d" % z["souvenirs"]])
		fiche.append(["carte", "ENTRETIEN", "ordre_amenager", UiTokens.SARCELLE])
		fiche.append(["barre", "Propreté", clampf(game.proprete / 100.0, 0.0, 1.0), "%d %%" % roundi(game.proprete),
			UiTokens.ORANGE if game.cleanliness_mult() < 1.0 else UiTokens.QUALITE])
		fiche.append(["ligne", "ressource_nourriture", Color("8A6A30"), "Rations à livrer", "%d" % ceili(game.rations_needed())])
		if game.affinity_bonus() > 0.0:
			fiche.append(["ligne", "ressource_reputation", UiTokens.RESSOURCES["reputation"]["couleur"], "Affinités de continent", "+%d %%" % roundi(game.affinity_bonus() * 100)])
		if z["inside"] >= z["capacity"] and z["queue"] > 0:
			fiche.append(["alerte", "Parc plein : la file attend. Agrandissez l'enceinte pour accueillir plus de monde."])
		if z["guichet_min"] <= 0.0:
			fiche.append(["alerte", "Personne au guichet : les visiteurs attendent dehors !"])
		if game.cleanliness_mult() < 1.0:
			fiche.append(["alerte", "Propreté insuffisante : moins de visiteurs (Local d'entretien)."])
		if hungry > 0:
			fiche.append(["alerte", "%d animal(aux) affamé(s) : Cuisine des animaux !" % hungry])
	if not game.day_bonus.is_empty():
		fiche.append(["bonus", str(game.day_bonus["nom"]), str(game.day_bonus["texte"])])
	fiche.append(["texte", "Mobilisez un collaborateur depuis votre main, puis clic droit sur une forêt, une roche, un chantier ou la case Accès (lobbying). Postes : Marchand sur le camp, Vendeur sur une boutique, Soigneur dans un enclos."])
	fiche.append(["pied", "Graine %d · Pioche %d · Défausse %d" % [game.seed_value, game.deck.size(), game.discard.size()]])


## Carte de la fiche de droite : cadre clair cerné d'encre, en-tête à pastille d'icône ; renvoie le corps.
func _fiche_carte(parent: Control, titre: String, icone: String, couleur: Color) -> VBoxContainer:
	var pc := PanelContainer.new()
	var st := UiTokens._button(UiTokens.PAPIER_2, UiTokens.ENCRE, 10)
	st.set_content_margin_all(8)
	st.content_margin_left = 10
	pc.add_theme_stylebox_override("panel", st)
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	pc.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 7)
	v.add_child(head)
	if icone != "":
		var pa := Composants.pastille(couleur, icone, 24)
		pa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(pa)
	var t := Composants.label(titre, "NomCarte")
	t.add_theme_font_size_override("font_size", 16)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(t)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	v.add_child(body)
	return body


func _fiche_ligne(parent: Control, icone: String, couleur: Color, texte: String, valeur: String, vcol := UiTokens.TEXTE) -> Label:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	parent.add_child(h)
	if icone != "":
		var pa := Composants.pastille(couleur, icone, 20)
		pa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(pa)
	var l := Composants.label(texte)
	l.add_theme_font_size_override("font_size", 14)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	var v := Composants.label(valeur, "Compteur")
	v.add_theme_font_size_override("font_size", 15)
	v.add_theme_color_override("font_color", vcol)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	return l


func _fiche_barre(parent: Control, texte: String, ratio: float, valeur: String, couleur: Color) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	parent.add_child(h)
	var l := Composants.label(texte)
	l.add_theme_font_override("font", UiTokens.police_corps(700))
	l.add_theme_font_size_override("font_size", 14)
	l.custom_minimum_size.x = 78
	h.add_child(l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := UiTokens._button(UiTokens.PAPIER, UiTokens.ENCRE, 7)
	bg.set_content_margin_all(0)
	var fg := StyleBoxFlat.new()
	fg.bg_color = couleur
	fg.set_corner_radius_all(5)
	fg.set_expand_margin_all(-2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	bar.value = ratio * 100.0
	h.add_child(bar)
	var v := Composants.label(valeur, "Compteur")
	v.add_theme_font_size_override("font_size", 14)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)


## Construit la fiche de droite à partir d'une liste d'éléments ; ne refait rien si elle n'a pas changé.
func _rendre_fiche(fiche: Array) -> void:
	var parts: Array[String] = []
	for e in fiche:
		for x in e:
			parts.append(("W%d" % x.card.id) if x is GameState.Worker else str(x))
		parts.append("|")
	var sig := "".join(parts) + str(game.phase)
	if sig == info_sig:
		return
	info_sig = sig
	_clear(info_view)
	var corps: Control = info_view
	for e in fiche:
		match e[0]:
			"carte":
				corps = _fiche_carte(info_view, e[1], e[2], e[3])
			"ligne":
				var fl := _fiche_ligne(corps, e[1], e[2], e[3], e[4])
				if e.size() > 5:
					_hover_card(fl, e[5])
			"coef":
				var k: float = e[4]
				_fiche_ligne(corps, e[1], e[2], e[3], "×%.2f" % k, UiTokens.POSITIF if k > 1.001 else (UiTokens.NEGATIF if k < 0.999 else UiTokens.TEXTE))
			"barre":
				_fiche_barre(corps, e[1], e[2], e[3], e[4])
			"texte", "pied":
				var l := Composants.label(e[1], "TexteSecondaire")
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.add_theme_font_size_override("font_size", 12 if e[0] == "pied" else 13)
				corps.add_child(l)
			"texte_fort":
				var l2 := Composants.label(e[1])
				l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l2.add_theme_font_override("font", UiTokens.police_corps(700))
				l2.add_theme_font_size_override("font_size", 14)
				corps.add_child(l2)
			"titre":
				var t := Composants.label(str(e[1]).to_upper(), "NomCarte")
				t.add_theme_font_size_override("font_size", 22)
				t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				info_view.add_child(t)
				var st2 := Composants.label(e[2], "TexteSecondaire")
				st2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				info_view.add_child(st2)
				corps = info_view
			"image":
				if e[1] != "" and SpritesBD.existe(e[1]):
					var tr := TextureRect.new()
					tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
					tr.texture = SpritesBD.texture(e[1])
					tr.custom_minimum_size = Vector2(0, 110)
					info_view.add_child(tr)
			"etat":
				var pc := PanelContainer.new()
				var st := UiTokens._button(UiTokens.QUALITE if e[1] else UiTokens.ORANGE, UiTokens.ENCRE, 10, true)
				st.set_content_margin_all(8)
				pc.add_theme_stylebox_override("panel", st)
				info_view.add_child(pc)
				var hb := HBoxContainer.new()
				hb.add_theme_constant_override("separation", 8)
				pc.add_child(hb)
				hb.add_child(Composants.icone_rect("ui_valide" if e[1] else "ui_invalide", Vector2(24, 24)))
				var vv := VBoxContainer.new()
				vv.add_theme_constant_override("separation", 0)
				vv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hb.add_child(vv)
				var t3 := Composants.label(str(e[2]).to_upper(), "NomCarte")
				t3.add_theme_font_size_override("font_size", 19)
				t3.add_theme_color_override("font_color", UiTokens.TEXTE_CLAIR)
				vv.add_child(t3)
				if e[3] != "":
					var r3 := Composants.label(e[3])
					r3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					r3.add_theme_color_override("font_color", UiTokens.TEXTE_CLAIR)
					r3.add_theme_font_size_override("font_size", 13)
					vv.add_child(r3)
				corps = info_view
			"chiffres":
				var g := HBoxContainer.new()
				g.add_theme_constant_override("separation", 8)
				corps.add_child(g)
				for ch in e[1]:
					var cp := PanelContainer.new()
					var cs := UiTokens._button(UiTokens.PAPIER, UiTokens.ENCRE, 9)
					cs.set_content_margin_all(6)
					cp.add_theme_stylebox_override("panel", cs)
					cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					g.add_child(cp)
					var ch_h := HBoxContainer.new()
					ch_h.add_theme_constant_override("separation", 6)
					cp.add_child(ch_h)
					var pa := Composants.pastille(ch[3], ch[2], 26)
					pa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					ch_h.add_child(pa)
					var cv := VBoxContainer.new()
					cv.add_theme_constant_override("separation", -4)
					ch_h.add_child(cv)
					var big := Composants.label(ch[0], "NomCarte")
					big.add_theme_font_size_override("font_size", 22)
					cv.add_child(big)
					var small := Composants.label(ch[1], "TexteSecondaire")
					small.add_theme_font_size_override("font_size", 12)
					cv.add_child(small)
			"alerte", "bonus":
				var ap := PanelContainer.new()
				var ast := UiTokens._button(Color("FFF1E4") if e[0] == "alerte" else Color("FFF6D6"), UiTokens.ENCRE, 9)
				ast.set_content_margin_all(7)
				ap.add_theme_stylebox_override("panel", ast)
				info_view.add_child(ap)
				var ah := HBoxContainer.new()
				ah.add_theme_constant_override("separation", 8)
				ap.add_child(ah)
				var mark: Control = Composants.mini_pastille(false, "ui_invalide", 22) if e[0] == "alerte" else Composants.pastille(UiTokens.SELECTION, "ressource_reputation", 22)
				mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				ah.add_child(mark)
				var at := Composants.label(e[1] if e[0] == "alerte" else "BONUS DU JOUR · " + str(e[1]).to_upper())
				at.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				at.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				at.add_theme_font_override("font", UiTokens.police_corps(700) if e[0] == "alerte" else UiTokens.police_titre())
				at.add_theme_font_size_override("font_size", 13 if e[0] == "alerte" else 15)
				if e[0] == "bonus":
					var bv := VBoxContainer.new()
					bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					ah.add_child(bv)
					bv.add_child(at)
					var bt := Composants.label(e[2])
					bt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					bt.add_theme_font_size_override("font_size", 13)
					bv.add_child(bt)
				else:
					ah.add_child(at)
			"ouvrier":
				_fiche_ouvrier(e[1])
				corps = info_view
			"ordres":
				var grid := GridContainer.new()
				grid.columns = 3
				grid.add_theme_constant_override("h_separation", 6)
				grid.add_theme_constant_override("v_separation", 6)
				info_view.add_child(grid)
				for o in [["ordre_abattre", "Abattre", "bois"], ["ordre_extraire", "Extraire", "pierre"], ["ressource_or", "Or", "or"],
						["ordre_lobbying", "Lobbying", "lobby"], ["ordre_rappeler", "Rappeler", "camp"], ["ui_suivant", "Localiser", "voir"]]:
					var b := Button.new()
					b.text = o[1]
					b.icon = UiTokens.icone(o[0])
					b.expand_icon = true
					b.add_theme_constant_override("icon_max_width", 20)
					b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
					b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
					b.add_theme_color_override("icon_normal_color", UiTokens.ENCRE)
					b.add_theme_color_override("icon_hover_color", UiTokens.ENCRE)
					b.add_theme_color_override("icon_pressed_color", UiTokens.ENCRE)
					b.add_theme_font_size_override("font_size", 13)
					b.custom_minimum_size = Vector2(0, 56)
					b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					b.focus_mode = Control.FOCUS_NONE
					b.disabled = spectator or game.phase != "day"
					if o[2] == "voir":
						b.disabled = false
						b.pressed.connect(func():
							if not selected.is_empty():
								_on_focus(selected[0]))
					else:
						b.pressed.connect(_unit_order.bind(o[2]))
					grid.add_child(b)
				corps = info_view


## En-tête de la fiche d'un ouvrier : portrait dessiné, nom, métier, catégorie (couleur + forme), traits.
func _fiche_ouvrier(w: GameState.Worker) -> void:
	var c := w.card
	var cat: Dictionary = UiTokens.CATEGORIES[c.metier["categorie"]]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	info_view.add_child(h)
	var cadre := PanelContainer.new()
	var cs := UiTokens._button(cat["portrait"], UiTokens.ENCRE, 10)
	cs.set_border_width_all(3)
	cs.set_content_margin_all(0)
	cadre.add_theme_stylebox_override("panel", cs)
	cadre.custom_minimum_size = Vector2(84, 96)
	cadre.clip_contents = true
	h.add_child(cadre)
	cadre.add_child(Composants.portrait_rect(game.perso_of(c)["id"], Vector2(84, 96)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nm := Composants.label(c.nom.to_upper(), "NomCarte")
	nm.add_theme_font_size_override("font_size", 24)
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	var lmax := int(game.data["workers"]["regles"]["niveau_max"])
	var job := Composants.label("%s · niv. %d  %s" % [game.job_name(c), c.niveau, "★".repeat(c.niveau) + "☆".repeat(maxi(0, lmax - c.niveau))])
	job.add_theme_font_size_override("font_size", 13)
	v.add_child(job)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UiTokens.chip(cat["couleur"], 6, 2))
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var bl := Composants.label("%s %s" % [cat["forme"], cat["court"]])
	bl.add_theme_font_override("font", UiTokens.police_corps(800))
	bl.add_theme_font_size_override("font_size", 12)
	bl.add_theme_color_override("font_color", UiTokens.TEXTE_CLAIR)
	badge.add_child(bl)
	v.add_child(badge)
	var traits := HFlowContainer.new()
	traits.add_theme_constant_override("h_separation", 6)
	traits.add_theme_constant_override("v_separation", 3)
	info_view.add_child(traits)
	for t in game.trait_defs(c):
		var pos := game.is_positive(t["id"])
		traits.add_child(_trait_chip(Composants.icone_trait(t["id"], pos), t["nom"], pos))
	for u in c.upgrade_names:
		var l := Composants.label("★ " + u)
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", Color("8A6A00"))
		traits.add_child(l)


func _update_hud() -> void:
	res_chips["argent"]["valeur"].text = str(floori(game.money))
	for r in ["bois", "pierre", "or"]:
		res_chips[r]["valeur"].text = str(floori(game.stock[r]))
	res_chips["influence"]["valeur"].text = "%.1f" % game.influence
	res_chips["logement"]["valeur"].text = "%d/%d" % [game.employees(), game.housing()]
	res_chips["reputation"]["valeur"].text = "%d" % game.reputation()
	res_chips["reputation"]["legende"].text = "/ %d Réputation" % game.objective()
	for i in race_labels.size():
		race_labels[i][1].text = str(mt.players[i].reputation())
	pile_label.text = "Pioche %d\nDéfausse %d" % [game.deck.size(), game.discard.size()]
	medallion.queue_redraw()

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
			l.add_theme_stylebox_override("normal", UiTokens.panel(UiTokens.PAPIER, UiTokens.ENCRE, 10, 3, 8))
			l.add_theme_font_override("font", UiTokens.police_corps(700))
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
			elif site.def_id() == "comptoir":
				status += " : clic droit avec un Marchand (vente à 125 %, achat 30 % moins cher)"
			elif site.def_id() == "agence":
				status += " : sélectionnez un collaborateur puis « Remplacer (Agence) » pour l'échanger contre une carte du deck"
			elif site.def_id() == "entrepot":
				status += " : clic droit pour y déposer la charge"
		else:
			status = "Chantier %s : %d / %d — clic droit pour y travailler" % [site.def["nom"], int(site.work), int(site.travail())]
	elif m.in_bounds(hover.x, hover.y) and game.phase == "day":
		if hover == m.exit_tile:
			status = "Accès route : clic droit pour envoyer à l'extérieur (lobbying et campagnes de publicité)"
		elif m.in_camp(hover.x, hover.y) and selected.any(func(w): return w.card.metier["id"] == "marchand"):
			status = "Camp : clic droit pour que le Marchand tienne le comptoir (vente au plein tarif)"
		elif game.animal_at(hover) and selected.any(func(w): return w.card.metier["id"] == "soigneur"):
			status = "%s : clic droit pour que le Soigneur s'en occupe (+%d visiteurs ce soir)" % [game.animal_at(hover).def["nom"], int(game.data["buildings"]["zoo"]["bonus_soigneur"])]
		elif m.in_camp(hover.x, hover.y):
			status = "Camp de base : clic droit pour y déposer la charge"
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

	if game.phase != "night":
		night_peek = false
	night_root.visible = game.phase == "night" and not mt.game_over and not night_peek
	night_return.visible = game.phase == "night" and night_peek and not mt.game_over
	peek_panel.visible = night_return.visible and not game.market_contracts.is_empty()
	if peek_panel.visible and peek_version != game.version:
		peek_version = game.version
		_rebuild_peek()
	if not night_return.visible:
		peek_hint = {}
	if mt.game_over and not end_built:
		end_built = true
		if mt.autosave:
			Sauvegarde.effacer()
		if hubert:
			hubert.taire()
			hubert.grande_en_bas = true
			hubert.annoncer("victoire" if mt.winner == game.index else "defaite")
		_rebuild_end()
	end_root.visible = mt.game_over and not end_dismissed
	end_reopen.visible = mt.game_over and end_dismissed
	if end_views:
		end_views.visible = end_reopen.visible
		if end_views.visible and end_views.get_child_count() == 0:
			for i in mt.players.size():
				var vb := Composants.bouton(mt.names[i], "BoutonSecondaire")
				vb.add_theme_font_size_override("font_size", 13)
				vb.focus_mode = Control.FOCUS_NONE
				vb.pressed.connect(_watch_board.bind(i))
				end_views.add_child(vb)
	var day_view := game.phase == "day" or (mt.game_over and end_dismissed)
	for c in day_hud:
		c.visible = day_view
	end_day_btn.visible = day_view and not spectator and not mt.game_over
	status_label.visible = status_label.visible and day_view


# --- Panneau de l'ouvrier sélectionné (capture 03, en bas à gauche) ------------

func _build_unit_panel() -> void:
	unit_panel = PanelContainer.new()
	unit_panel.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 12, 2, 10))
	unit_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	unit_panel.offset_left = 14
	unit_panel.offset_right = 358
	unit_panel.offset_top = -214
	unit_panel.offset_bottom = -14
	unit_panel.visible = false
	ui.add_child(unit_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	unit_panel.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	unit_portrait_box = Control.new()
	unit_portrait_box.custom_minimum_size = Vector2(84, 84)
	top.add_child(unit_portrait_box)
	var id := VBoxContainer.new()
	id.add_theme_constant_override("separation", 0)
	id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(id)
	unit_name = Composants.label("", "NomCarte")
	unit_name.add_theme_font_size_override("font_size", 17)
	unit_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	unit_name.clip_text = true
	id.add_child(unit_name)
	unit_job = Composants.label("", "TexteSecondaire")
	unit_job.add_theme_font_size_override("font_size", 13)
	id.add_child(unit_job)
	unit_stars = Composants.label("")
	unit_stars.add_theme_font_size_override("font_size", 13)
	unit_stars.add_theme_color_override("font_color", UiTokens.OR)
	id.add_child(unit_stars)
	unit_traits = HFlowContainer.new()
	unit_traits.add_theme_constant_override("h_separation", 4)
	unit_traits.add_theme_constant_override("v_separation", 3)
	id.add_child(unit_traits)
	var task_row := HBoxContainer.new()
	task_row.add_theme_constant_override("separation", 8)
	v.add_child(task_row)
	unit_task = Composants.label("")
	unit_task.add_theme_font_size_override("font_size", 13)
	unit_task.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_task.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	unit_task.clip_text = true
	task_row.add_child(unit_task)
	unit_bar = ProgressBar.new()
	unit_bar.show_percentage = false
	unit_bar.custom_minimum_size = Vector2(90, 8)
	unit_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	unit_bar.add_theme_stylebox_override("background", UiTokens.chip(Color(0, 0, 0, 0.45), 4, 0))
	unit_bar.add_theme_stylebox_override("fill", UiTokens.chip(UiTokens.OR, 4, 0))
	task_row.add_child(unit_bar)
	# Ordres rapides : la ressource la plus proche de l'ouvrier, le lobbying, le retour au camp
	var orders := HBoxContainer.new()
	orders.add_theme_constant_override("separation", 10)
	orders.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(orders)
	for o in [["ordre_abattre", "Couper du bois (forêt la plus proche)", "bois"],
			["ordre_extraire", "Tailler de la pierre (roche la plus proche)", "pierre"],
			["ressource_or", "Extraire de l'or (gisement avec mine)", "or"],
			["ordre_lobbying", "Lobbying : quitter la carte par l'accès route", "lobby"],
			["ordre_rappeler", "Revenir au camp (rappelle aussi un lobbyiste)", "camp"]]:
		var b := Composants.bouton("", "BoutonOrdre")
		b.icon = UiTokens.icone(o[0])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("icon_max_width", 24)
		b.custom_minimum_size = Vector2(46, 46)
		b.tooltip_text = o[1]
		b.pressed.connect(_unit_order.bind(o[2]))
		orders.add_child(b)
		unit_orders.append(b)


func _update_unit_panel() -> void:
	# La fiche de l'ouvrier est désormais dans le panneau de droite (maquette « Néo ligne claire »).
	var show := false
	unit_panel.visible = show
	# Le panneau d'unité pousse la pioche et la main vers la droite (cotes de la capture 03).
	pile_panel.offset_left = 372.0 if show else 14.0
	pile_panel.offset_right = 458.0 if show else 112.0
	hand_scroll.offset_left = 470.0 if show else 124.0
	if not show:
		unit_portrait_for = null
		return
	var w: GameState.Worker = selected[0]
	var c := w.card
	var cat: Dictionary = UiTokens.CATEGORIES[c.metier["categorie"]]
	if unit_portrait_for != c:
		unit_portrait_for = c
		for k in unit_portrait_box.get_children():
			k.queue_free()
		var disc := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = cat["portrait"]
		sb.set_corner_radius_all(42)
		sb.border_color = UiTokens.OR
		sb.set_border_width_all(3)
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 6
		disc.add_theme_stylebox_override("panel", sb)
		disc.tooltip_text = "Centrer la vue sur %s" % c.nom
		disc.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and not selected.is_empty():
				_on_focus(selected[0]))
		Composants.placer(unit_portrait_box, disc, Vector2.ZERO, Vector2(84, 84))
		# Portrait du personnage découpé dans le disque, pastille du métier en bas à droite
		disc.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		Composants.placer(disc, Composants.portrait_rect(game.perso_of(c)["id"], Vector2(96, 80)), Vector2(-6, 8), Vector2(96, 80))
		var pm := Composants.pastille(Color(cat["couleur"]).darkened(0.1), Composants.icone_metier(str(c.metier["id"])), 26, cat["portrait"])
		Composants.placer(unit_portrait_box, pm, Vector2(60, 58), Vector2(26, 26))
		unit_name.text = c.nom.to_upper()
		unit_job.text = "%s · %s" % [game.job_name(c), str(cat["long"]).to_lower()]
		for k in unit_traits.get_children():
			k.queue_free()
		for t in game.trait_defs(c):
			var pos := game.is_positive(t["id"])
			unit_traits.add_child(_trait_chip(Composants.icone_trait(t["id"], pos), t["nom"], pos))
		for u in c.upgrade_names:
			var l := Composants.label("★ " + u)
			l.add_theme_font_size_override("font_size", 12)
			l.add_theme_color_override("font_color", UiTokens.SELECTION)
			unit_traits.add_child(l)
	var lmax := int(game.data["workers"]["regles"]["niveau_max"])
	unit_stars.text = "%s   Niv. %d · %d / jour" % ["★".repeat(c.niveau) + "☆".repeat(maxi(0, lmax - c.niveau)), c.niveau, game.salary(c)]
	unit_task.text = _task_text(w)
	unit_bar.visible = true
	if w.task.get("type") == "build":
		var s: GameState.Site = w.task["site"]
		unit_bar.value = 100.0 * clampf(s.work / s.travail(), 0.0, 1.0)
	elif w.carry > 0.0 or w.task.get("type") == "extract":
		unit_bar.value = 100.0 * w.carry / maxf(1.0, game.carry_capacity(c))
	else:
		unit_bar.visible = false
	for b in unit_orders:
		b.disabled = spectator or game.phase != "day"


func _trait_chip(icon: String, text: String, positive: bool) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 3)
	hb.add_child(Composants.mini_pastille(positive, icon, 16))
	var l := Composants.label(text)
	l.add_theme_font_size_override("font_size", 12)
	hb.add_child(l)
	return hb


func _unit_order(kind: String) -> void:
	if selected.is_empty() or game.phase != "day":
		return
	match kind:
		"lobby":
			_cmd("order", [selected, game.map.exit_tile])
		"camp":
			_cmd("order", [selected, game.map.camp.get_center()])
		_:
			var t := _nearest_resource(kind, Vector2i(selected[0].pos))
			if t.x < 0:
				game.say("Aucun gisement de %s accessible%s." % [res_noms[kind], " (construisez une mine d'or)" if kind == "or" else ""])
			else:
				_cmd("order", [selected, t])


## Case exploitable la plus proche (bois, pierre, or avec mine) parmi celles qu'on peut atteindre.
func _nearest_resource(res: String, from: Vector2i) -> Vector2i:
	var m := game.map
	var reach := MapGenerator.reachable(m)
	var best := Vector2i(-1, -1)
	var best_d := 1 << 30
	for y in m.h:
		for x in m.w:
			if m.extractible(x, y) != res or not reach[m.idx(x, y)]:
				continue
			if res == "or" and not game.mine_ready(Vector2i(x, y)):
				continue
			var d := absi(x - from.x) + absi(y - from.y)
			if d < best_d:
				best_d = d
				best = Vector2i(x, y)
	return best


# --- Écran de nuit (capture 05) ------------------------------------------------

## Panneau émeraude à en-tête : renvoie [panneau, corps, note à droite du titre].
func _titled_panel(parent: Control, title: String, note := "") -> Array:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 10, 2, 0))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	panel.add_child(v)
	var head := PanelContainer.new()
	var hs := UiTokens.header()
	hs.content_margin_top = 8
	hs.content_margin_bottom = 8
	hs.content_margin_right = 12
	head.add_theme_stylebox_override("panel", hs)
	v.add_child(head)
	var hb := HBoxContainer.new()
	head.add_child(hb)
	var t := Composants.label(title, "TitrePanneau")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t)
	var n := Composants.label(note, "TexteSecondaire")
	n.add_theme_font_size_override("font_size", 12)
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(n)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 12)
	v.add_child(m)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	m.add_child(body)
	return [panel, body, n]


## Titre de section du centre (Marcellus, capitales), avec une note à droite.
func _section_title(parent: Control, title: String) -> Label:
	var hb := HBoxContainer.new()
	parent.add_child(hb)
	var t := Composants.label(title, "TitreEcran")
	t.add_theme_font_size_override("font_size", 21)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t)
	var n := Composants.label("", "TexteSecondaire")
	n.add_theme_font_size_override("font_size", 13)
	n.size_flags_vertical = Control.SIZE_SHRINK_END
	hb.add_child(n)
	return n


func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _build_night_ui() -> void:
	night_root = ColorRect.new()
	night_root.color = Color("DCE4EE", 0.95)
	night_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night_root.mouse_filter = Control.MOUSE_FILTER_STOP
	night_root.visible = false
	ui.add_child(night_root)
	# En-tête h 64 : lune, titre, étapes de la nuit, bouton du jour suivant
	var head := PanelContainer.new()
	var hs := UiTokens.panel(UiTokens.PANNEAU_HAUT, UiTokens.OR, 0, 0, 10)
	hs.border_width_bottom = 1
	hs.content_margin_left = 24
	hs.content_margin_right = 24
	head.add_theme_stylebox_override("panel", hs)
	head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	head.custom_minimum_size.y = 64
	night_root.add_child(head)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	head.add_child(hb)
	var moon := Composants.icone_rect("ui_nuit", Vector2(30, 30), UiTokens.OR)
	moon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(moon)
	night_title = Composants.label("", "TitreEcran")
	night_title.add_theme_font_size_override("font_size", 28)
	night_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(night_title)
	night_steps = HBoxContainer.new()
	night_steps.add_theme_constant_override("separation", 6)
	night_steps.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	night_steps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(night_steps)
	# Argent et logement bien en vue : ce sont eux qui décident des achats de la nuit
	for r in [["argent", "Argent disponible"], ["logement", "Logement"]]:
		var res: Dictionary = UiTokens.RESSOURCES[r[0]]
		var chip := Composants.jeton_ressource(res["icone"], res["couleur"], res["reflet"], r[1], res.get("sprite", ""))
		chip["valeur"].add_theme_font_size_override("font_size", 24)
		chip["racine"].size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(chip["racine"])
		night_chips[r[0]] = chip
	var peek := Composants.bouton("Voir mon zoo", "BoutonSecondaire")
	peek.custom_minimum_size = Vector2(150, 40)
	peek.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	peek.tooltip_text = "Masque le marché pour regarder votre terrain (enclos, motifs) avant d'acheter"
	peek.pressed.connect(func(): night_peek = true)
	hb.add_child(peek)
	night_return = Composants.bouton("Retour au marché de nuit", "BoutonPrincipal")
	night_return.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	night_return.offset_top = 64
	night_return.offset_left = -140
	night_return.offset_right = 140
	night_return.offset_bottom = 106
	night_return.visible = false
	night_return.pressed.connect(func(): night_peek = false)
	ui.add_child(night_return)
	peek_panel = PanelContainer.new()
	peek_panel.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 10, 2, 10))
	peek_panel.anchor_left = 1.0
	peek_panel.anchor_right = 1.0
	peek_panel.offset_left = -330
	peek_panel.offset_right = -16
	peek_panel.offset_top = 64
	peek_panel.visible = false
	ui.add_child(peek_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	peek_panel.add_child(pv)
	pv.add_child(Composants.label("CONTRATS DU MARCHÉ", "TitrePanneau"))
	var pn := Composants.label("Motifs à reproduire (tournés ou retournés) : cherchez sur la carte où les placer.", "TexteSecondaire")
	pn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pn.custom_minimum_size.x = 290
	pn.add_theme_font_size_override("font_size", 12)
	pv.add_child(pn)
	peek_list = VBoxContainer.new()
	peek_list.add_theme_constant_override("separation", 6)
	pv.add_child(peek_list)
	night_next = Composants.bouton("", "BoutonPrincipal")
	night_next.custom_minimum_size = Vector2(230, 44)
	night_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	night_next.add_theme_font_size_override("font_size", 17)
	night_next.pressed.connect(_on_night_next)
	hb.add_child(night_next)
	# Trois colonnes (gauche l 330, centre, droite l 322), chacune défile si besoin
	var cols := [[20.0, 350.0], [372.0, -362.0], [-342.0, -20.0]]
	var boxes: Array[VBoxContainer] = []
	for k in 3:
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.anchor_bottom = 1.0
		sc.anchor_left = 0.0 if k < 2 else 1.0
		sc.anchor_right = 0.0 if k == 0 else 1.0
		sc.offset_left = cols[k][0]
		sc.offset_right = cols[k][1]
		sc.offset_top = 82
		sc.offset_bottom = -16
		night_root.add_child(sc)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 14)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v)
		boxes.append(v)
	# Gauche : bilan de la journée
	var p := _titled_panel(boxes[0], "BILAN DE LA JOURNÉE" if spectator else "NOTE DE LA DIRECTION")
	night_summary = p[1]
	# Centre : ordre d'influence (tour en cours), puis la page de l'étape de la nuit en grand
	var inf := PanelContainer.new()
	var ist := UiTokens.chip(Color(UiTokens.PANNEAU_BAS, 0.92), 22, 6)
	ist.border_color = Color(UiTokens.OR, 0.6)
	ist.set_border_width_all(1)
	ist.content_margin_left = 14
	ist.content_margin_right = 14
	inf.add_theme_stylebox_override("panel", ist)
	boxes[1].add_child(inf)
	night_influence = HBoxContainer.new()
	night_influence.add_theme_constant_override("separation", 8)
	inf.add_child(night_influence)
	night_stage_title = Composants.label("", "TitreEcran")
	night_stage_title.add_theme_font_size_override("font_size", 28)
	boxes[1].add_child(night_stage_title)
	night_stage_note = Composants.label("", "TexteSecondaire")
	night_stage_note.add_theme_font_size_override("font_size", 15)
	night_stage_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boxes[1].add_child(night_stage_note)
	for st in Match.NIGHT_STAGES:
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 12)
		boxes[1].add_child(page)
		night_pages[st] = page
	var flow := func(parent: Control) -> HFlowContainer:
		var f := HFlowContainer.new()
		f.add_theme_constant_override("h_separation", 14)
		f.add_theme_constant_override("v_separation", 14)
		parent.add_child(f)
		return f
	night_contracts_note = _section_title(night_pages["contrats"], "")
	night_contracts = flow.call(night_pages["contrats"])
	night_money_lbl = _section_title(night_pages["ouvriers"], "")
	night_workers = flow.call(night_pages["ouvriers"])
	var actions_note := _section_title(night_pages["cartes"], "")
	actions_note.text = "1 achat par nuit · elles rejoignent votre deck"
	night_actions = flow.call(night_pages["cartes"])
	night_bonus_note = _section_title(night_pages["bonus"], "")
	night_bonus_box = VBoxContainer.new()
	night_bonus_box.add_theme_constant_override("separation", 10)
	night_pages["bonus"].add_child(night_bonus_box)
	p = _titled_panel(night_pages["equipe"], "MONTÉES DE NIVEAU", "amélioration offerte")
	night_level_box = p[0]
	night_level_rows = p[1]
	p = _titled_panel(night_pages["equipe"], "AMÉLIORER OU LICENCIER", "1 par nuit")
	night_action_box = p[0]
	night_action_flow = p[1]
	p = _titled_panel(night_pages["equipe"], "LICENCIER", "DRH : gratuit ce soir")
	night_fire_box = p[0]
	night_fire = p[1]
	# Droite : réputation, journal
	p = _titled_panel(boxes[2], "RÉPUTATION")
	night_rep_rows = p[1]
	p = _titled_panel(boxes[2], "JOURNAL DE LA NUIT")
	night_text = RichTextLabel.new()
	night_text.bbcode_enabled = true
	night_text.fit_content = true
	night_text.scroll_active = false
	night_text.custom_minimum_size = Vector2(290, 0)
	night_text.add_theme_font_size_override("normal_font_size", 13)
	night_text.add_theme_font_size_override("bold_font_size", 13)
	p[1].add_child(night_text)


func _step_pill(text: String, state: String) -> Control:
	var pill := PanelContainer.new()
	var bg := Color(UiTokens.ENTETE, 0.9) if state == "fait" else (UiTokens.SELECTION if state == "courant" else Color(0, 0, 0, 0))
	var sb := UiTokens.chip(bg, 16, 5)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	if state != "courant":
		sb.border_color = Color(UiTokens.TEXTE_SECONDAIRE, 0.55)
		sb.set_border_width_all(1)
	pill.add_theme_stylebox_override("panel", sb)
	var l := Composants.label(("✓ " if state == "fait" else "· ") + text)
	l.add_theme_font_override("font", UiTokens.police_corps(800))
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", UiTokens.BOUTON_TEXTE if state == "courant" else (UiTokens.TEXTE if state == "fait" else UiTokens.TEXTE_SECONDAIRE))
	pill.add_child(l)
	return pill


func _summary_row(parent: Control, icon: String, color: Color, text: String, value: String, value_color := UiTokens.TEXTE) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var dot := Composants.pastille(color, icon, 24)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)
	var l := Composants.label(text)
	l.add_theme_font_size_override("font_size", 14)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := Composants.label(value, "Compteur")
	v.add_theme_font_size_override("font_size", 15)
	v.add_theme_color_override("font_color", value_color)
	row.add_child(v)
	parent.add_child(row)


## Petit disque numéroté à la couleur d'un joueur (ordre d'influence, classement).
func _rank_dot(n: int, color: Color, d := 22) -> Control:
	var p := PanelContainer.new()
	var sb := UiTokens.chip(color, d / 2, 0)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(d, d)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Composants.label(str(n), "Compteur")
	l.add_theme_font_size_override("font_size", int(d * 0.6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _bonus_icon(b: Dictionary) -> String:
	var keys := " ".join(b.get("effets", {}).keys())
	for pair in [["bois", "ressource_bois"], ["pierre", "ressource_pierre"], ["or", "ressource_or"], ["construire", "ordre_construire"],
			["vitesse", "qualite_rapide"], ["attractivite", "ressource_reputation"], ["lobbying", "ressource_influence"],
			["influence", "ressource_influence"], ["pioche", "ui_pioche"], ["visiteur", "ressource_visiteurs"]]:
		if pair[0] in keys:
			return pair[1]
	return "ui_ameliorer"


func _rebuild_night() -> void:
	if game.phase != "night" or game.night_report.is_empty():
		return
	var r := game.night_report
	var s: Dictionary = r["stats"]
	var inc: Dictionary = r["income"]
	night_title.text = "NUIT %d" % r["day"]
	var stage := mt.night_stage
	var buyer := mt.current_buyer()
	var my_turn := buyer == game.index and not spectator
	var leader := mt.influence_leader()
	if stage == "equipe":
		night_next.text = "Passer au jour %d  ›" % (r["day"] + 1)
		night_next.disabled = mt.game_over or spectator
	elif mt.market_stage():
		night_next.text = "Passer  ›" if my_turn else "%s choisit…" % mt.names[buyer]
		night_next.disabled = not my_turn
	else:
		var mine := leader == game.index and not spectator
		night_next.text = "Garder le 1er bonus  ›" if mine and mt.bonus_choice.is_empty() else "%s choisit…" % mt.names[leader]
		night_next.disabled = not mine or not mt.bonus_choice.is_empty()

	# Étapes : faites (✓), en cours (or), à venir
	_clear(night_steps)
	var step_names := {"contrats": "Contrats", "ouvriers": "Collaborateurs", "cartes": "Cartes", "bonus": "Bonus", "equipe": "Équipe"}
	var cur := Match.NIGHT_STAGES.find(stage)
	for k in Match.NIGHT_STAGES.size() + 1:
		var label: String = step_names[Match.NIGHT_STAGES[k]] if k < Match.NIGHT_STAGES.size() else "Jour %d" % (r["day"] + 1)
		if k > 0:
			night_steps.add_child(Composants.label("—", "TexteSecondaire"))
		night_steps.add_child(_step_pill(label, "fait" if k < cur else ("courant" if k == cur else "a_venir")))
	for st in night_pages:
		night_pages[st].visible = st == stage
	var turn_text := "À vous de choisir." if my_turn else ("%s choisit…" % mt.names[buyer] if buyer >= 0 else "")
	match stage:
		"contrats":
			night_stage_title.text = "CONTRATS D'ANIMAUX"
			night_stage_note.text = "Chacun à son tour, dans l'ordre d'influence : un contrat par joueur. Un contrat pris n'est remplacé que demain. " + turn_text
		"ouvriers":
			night_stage_title.text = "COLLABORATEURS À EMBAUCHER"
			night_stage_note.text = "Chacun à son tour : 1 embauche au plus, si votre logement le permet. " + turn_text
		"cartes":
			night_stage_title.text = "CARTES D'ACTION"
			night_stage_note.text = "Chacun à son tour : 1 carte au plus. " + turn_text
		"bonus":
			night_stage_title.text = "BONUS DE DEMAIN"
			night_stage_note.text = "Le premier en influence (%s) choisit un bonus : il s'appliquera demain à tous les zoos." % mt.names[leader]
		"equipe":
			night_stage_title.text = "VOTRE ÉQUIPE"
			night_stage_note.text = "Chacun de son côté : montées de niveau, une amélioration ou un licenciement payant, et le licenciement offert par le DRH." \
				+ ("\nBonus de demain : %s (%s)" % [mt.bonus_choice.get("nom", "?"), mt.bonus_choice.get("texte", "")] if not mt.bonus_choice.is_empty() else "")

	# Bilan de la journée
	_clear(night_summary)
	var sal := roundi(float(s.get("salaires", 0.0)))
	var food := roundi(float(s.get("nourriture", 0.0)))
	_summary_row(night_summary, "ressource_visiteurs", UiTokens.RESSOURCES["reputation"]["couleur"], "Visiteurs", str(inc["visitors"]))
	_summary_row(night_summary, "ressource_billetterie", UiTokens.RESSOURCES["argent"]["couleur"], "Billetterie", "+%d" % inc["tickets"], UiTokens.POSITIF)
	_summary_row(night_summary, "batiment_boutique", Color("E04A8A"), "Souvenirs", "+%d" % inc["souvenirs"], UiTokens.POSITIF)
	_summary_row(night_summary, "ressource_argent", UiTokens.PAUSE, "Salaires", "−%d" % sal, UiTokens.NEGATIF)
	if float(s.get("emprunt", 0.0)) > 0.0:
		_summary_row(night_summary, "ressource_argent", UiTokens.NEGATIF, "Emprunt remboursé", "−%d" % roundi(float(s["emprunt"])), UiTokens.NEGATIF)
	_summary_row(night_summary, "ressource_nourriture", UiTokens.RESSOURCES["logement"]["couleur"], "Nourriture des animaux", "−%d" % food, UiTokens.NEGATIF)
	for res in ["bois", "pierre", "or"]:
		if float(s[res]) >= 1.0:
			_summary_row(night_summary, UiTokens.RESSOURCES[res]["icone"], UiTokens.RESSOURCES[res]["couleur"], "%s rapporté" % UiTokens.RESSOURCES[res]["nom"], "+%d" % floori(s[res]))
	if float(s["influence"]) > 0.0:
		_summary_row(night_summary, "ressource_influence", UiTokens.RESSOURCES["influence"]["couleur"], "Influence gagnée", "+%.1f" % s["influence"])
	_summary_row(night_summary, "ressource_reputation", UiTokens.RESSOURCES["reputation"]["couleur"], "Réputation (fréquentation)", "+%.1f" % inc["rep_gain"], UiTokens.POSITIF)
	if float(inc.get("rep_spectacle", 0.0)) > 0.05:
		_summary_row(night_summary, "batiment_boutique", Color("8A4AD0"), "Réputation (spectacles, boutique)", "+%.1f" % inc["rep_spectacle"], UiTokens.POSITIF)
	if r.has("prestige"):
		_summary_row(night_summary, "ressource_influence", UiTokens.RESSOURCES["influence"]["couleur"], "Prestige politique (influence)", "+%.1f" % r["prestige"], UiTokens.POSITIF)
	for nm in r.get("legendes", []):
		_summary_row(night_summary, "ui_ameliorer", UiTokens.OR, "%s devient légendaire" % nm, "+%d" % int(game.data["buildings"]["reputation_autres"]["legendaire"]), UiTokens.POSITIF)
	if not inc["open"]:
		var closed := Composants.label("Zoo fermé : %s" % inc["reason"])
		closed.add_theme_color_override("font_color", UiTokens.NEGATIF)
		closed.add_theme_font_size_override("font_size", 12)
		closed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		closed.custom_minimum_size.x = 290
		night_summary.add_child(closed)
	night_summary.add_child(HSeparator.new())
	var total := int(inc["tickets"]) + int(inc["souvenirs"]) - sal - food
	var total_row := HBoxContainer.new()
	var tl := Composants.label("Total de la journée")
	tl.add_theme_font_override("font", UiTokens.police_corps(800))
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_row.add_child(tl)
	var tv := Composants.label("%+d" % total, "Compteur")
	tv.add_theme_font_size_override("font_size", 24)
	tv.add_theme_color_override("font_color", UiTokens.POSITIF if total >= 0 else UiTokens.NEGATIF)
	total_row.add_child(tv)
	night_summary.add_child(total_row)
	_note_de_direction(total)

	# Ordre d'influence (valeurs des adversaires cachées)
	_clear(night_influence)
	var it := Composants.label("INFLUENCE", "TitrePanneau")
	it.add_theme_font_size_override("font_size", 14)
	it.add_theme_color_override("font_color", UiTokens.OR)
	it.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	night_influence.add_child(it)
	for k in mt.night_order.size():
		var i: int = mt.night_order[k]
		var pill := PanelContainer.new()
		var mine := i == game.index
		var ps := UiTokens.chip(UiTokens.SELECTION if mine else Color(UiTokens.ENCRE, 0.06), 16, 4)
		if mt.market_stage() and k == mt.night_turn:
			ps.border_color = UiTokens.SELECTION if not mine else Color.WHITE
			ps.set_border_width_all(3)
		pill.add_theme_stylebox_override("panel", ps)
		var ph := HBoxContainer.new()
		ph.add_theme_constant_override("separation", 6)
		pill.add_child(ph)
		ph.add_child(_rank_dot(k + 1, UiTokens.JOUEURS[i % UiTokens.JOUEURS.size()]))
		var done_mark := "✓ " if mt.market_stage() and k < mt.night_turn else ""
		var pn := Composants.label(done_mark + ("%s · %.1f" % [mt.names[i], game.influence] if mine else "%s  ?" % mt.names[i]))
		pn.add_theme_font_override("font", UiTokens.police_corps(800))
		pn.add_theme_font_size_override("font_size", 14)
		pn.add_theme_color_override("font_color", UiTokens.BOUTON_TEXTE if mine else UiTokens.TEXTE)
		ph.add_child(pn)
		night_influence.add_child(pill)
	var hidden := Composants.label("valeurs adverses cachées", "TexteSecondaire")
	hidden.add_theme_font_size_override("font_size", 12)
	hidden.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hidden.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hidden.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	night_influence.add_child(hidden)

	# Marché : ouvriers, contrats, cartes d'action
	var full := game.employees() >= game.housing()
	night_chips["argent"]["valeur"].text = str(floori(game.money))
	night_chips["logement"]["valeur"].text = "%d/%d" % [game.employees(), game.housing()]
	night_chips["logement"]["valeur"].add_theme_color_override("font_color", UiTokens.NEGATIF if full else UiTokens.TEXTE)
	night_money_lbl.text = "Logement plein : construisez une Maison de collaborateurs" if full \
		else "Argent disponible : %d" % floori(game.money)
	night_money_lbl.add_theme_color_override("font_color", UiTokens.NEGATIF if full else UiTokens.TEXTE_SECONDAIRE)
	_clear(night_workers)
	for card in game.market_workers:
		var err := "Mode spectateur" if spectator else game.hire_error(card)
		var cost := game.hire_cost(card)
		var hire_text := "Embaucher · %d" % cost
		if err != "":
			# La raison du refus est écrite sur le bouton, et détaillée au survol.
			hire_text = ("Manque %d" % ceili(cost - game.money)) if game.money < cost and not full else _short_reason(err)
		var recruit := []
		if (game.has_building("cabinet") or game.rare_effects().any(func(e): return e.get("echange", false))) and not spectator:
			recruit = ["⟳", game.hippo_error() != "" and game.recruit_error("peu_qualifie") != "" and game.recruit_error("cadre") != "" and game.recruit_error("qualifie") != "",
				_open_recruit.bind(card)]
		var w := _card_widget(card, hire_text, err != "", _cmd.bind("hire", [card]), recruit)
		w.tooltip_text = (err + "\n" if err != "" else "") + w.tooltip_text
		for b in w.find_children("*", "Button", true, false):
			b.tooltip_text = err if err != "" else "Embaucher %s pour %d argent" % [card.nom, cost]
		night_workers.add_child(w)
	for t in _taken("ouvriers"):
		night_workers.add_child(_taken_mark(_card_widget(t["objet"], "Pris · %s" % mt.names[t["joueur"]], true, Callable()), t["joueur"]))
	_clear(night_contracts)
	night_contracts_note.text = "%d contrats · 1 achat par joueur · dans l'ordre d'influence" % game.market_contracts.size()
	for def in game.market_contracts:
		var err := game.contract_error(def)
		night_contracts.add_child(_contract_widget(def, "Acheter · %s" % game.cost_text(game.contract_cost(def)),
			"Mode spectateur" if spectator else err, _cmd.bind("buy_contract", [def])))
	for t in _taken("contrats"):
		night_contracts.add_child(_taken_mark(_contract_widget(t["objet"], "Pris · %s" % mt.names[t["joueur"]], "Pris par %s" % mt.names[t["joueur"]],
			Callable()), t["joueur"]))
	_clear(night_actions)
	for card in mt.market_actions:
		var aerr := game.action_error(card)
		var aw := _action_widget(card, "Acheter · %d" % game.action_price(card), spectator or aerr != "", _cmd.bind("buy_action", [card]))
		if aerr != "":
			aw.tooltip_text = aerr + "\n" + aw.tooltip_text
		night_actions.add_child(aw)
	for t in _taken("cartes"):
		night_actions.add_child(_taken_mark(_action_widget(t["objet"], "Pris · %s" % mt.names[t["joueur"]], true, Callable()), t["joueur"]))

	# Réputation : classement, écart d'hier, barre vers l'objectif
	_clear(night_rep_rows)
	var ranking := range(mt.players.size())
	ranking.sort_custom(func(a, b): return mt.players[a].reputation() > mt.players[b].reputation())
	for k in ranking.size():
		var i: int = ranking[k]
		var col: Color = UiTokens.JOUEURS[i % UiTokens.JOUEURS.size()]
		var row := PanelContainer.new()
		var rs := UiTokens.chip(Color(UiTokens.OR, 0.08) if i == game.index else Color(0, 0, 0, 0), 8, 6)
		if i == game.index:
			rs.border_color = UiTokens.SELECTION
			rs.set_border_width_all(2)
		row.add_theme_stylebox_override("panel", rs)
		var rv := VBoxContainer.new()
		rv.add_theme_constant_override("separation", 4)
		row.add_child(rv)
		var rh := HBoxContainer.new()
		rh.add_theme_constant_override("separation", 8)
		rv.add_child(rh)
		var rk := Composants.label(str(k + 1), "Compteur")
		rk.add_theme_font_size_override("font_size", 14)
		rh.add_child(rk)
		rh.add_child(_player_dot(col))
		var embleme := Composants.logo_groupe(mt.names[i], true)
		if embleme:
			rh.add_child(Composants.image_logo(embleme, Vector2(26, 26)))
		var nm := Composants.label(mt.names[i])
		nm.add_theme_font_override("font", UiTokens.police_corps(800))
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rh.add_child(nm)
		var rep := mt.players[i].reputation()
		var val := Composants.label(str(rep), "Compteur")
		val.add_theme_font_size_override("font_size", 18)
		rh.add_child(val)
		var delta := rep - _rep_on_night(i, -2)
		var dl := Composants.label(("+%d" % delta) if delta >= 0 else str(delta))
		dl.add_theme_font_size_override("font_size", 12)
		dl.add_theme_color_override("font_color", UiTokens.POSITIF if delta >= 0 else UiTokens.NEGATIF)
		dl.custom_minimum_size.x = 26
		rh.add_child(dl)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 5)
		bar.max_value = game.objective()
		bar.value = rep
		bar.add_theme_stylebox_override("background", UiTokens.chip(Color(UiTokens.ENCRE, 0.08), 3, 0))
		bar.add_theme_stylebox_override("fill", UiTokens.chip(col, 3, 0))
		rv.add_child(bar)
		night_rep_rows.add_child(row)
	var goal := Composants.label("Victoire au premier zoo à %d" % game.objective(), "TexteSecondaire")
	goal.add_theme_font_size_override("font_size", 12)
	night_rep_rows.add_child(goal)

	# Bonus de nuit : seul le premier en influence choisit, pour tous les zoos
	_clear(night_bonus_box)
	if not mt.bonus_choice.is_empty():
		night_bonus_note.text = "choisi par %s" % mt.names[leader]
	elif leader == game.index:
		night_bonus_note.text = "à vous de choisir"
	else:
		night_bonus_note.text = "%s choisit" % mt.names[leader]
	for b in mt.bonus_offer:
		var chosen: bool = mt.bonus_choice == b
		var err := game.bonus_error(b)
		var btn := Button.new()
		btn.text = "%s\n%s" % [b["nom"], b["texte"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.icon = UiTokens.icone(_bonus_icon(b))
		btn.expand_icon = false
		btn.add_theme_constant_override("icon_max_width", 26)
		btn.add_theme_constant_override("h_separation", 10)
		btn.add_theme_font_size_override("font_size", 13)
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(620, 64)
		btn.add_theme_font_size_override("font_size", 16)
		btn.tooltip_text = err
		btn.disabled = spectator or err != ""
		var normal := UiTokens.chip(Color(UiTokens.ENCRE, 0.05), 8, 8)
		if chosen:
			normal = UiTokens.chip(Color(UiTokens.OR, 0.14), 8, 8)
			normal.border_color = UiTokens.SELECTION
			normal.set_border_width_all(2)
		var hover := UiTokens.chip(Color(UiTokens.ENCRE, 0.12), 8, 8)
		hover.border_color = UiTokens.OR
		hover.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", normal)
		btn.add_theme_stylebox_override("disabled", normal)
		btn.add_theme_color_override("font_disabled_color", UiTokens.SELECTION if chosen else Color(UiTokens.TEXTE, 0.55))
		btn.pressed.connect(_cmd.bind("pick_bonus", [b]))
		night_bonus_box.add_child(btn)
	# Le premier en influence peut n'en choisir aucun
	if mt.influence_leader() == game.index and not spectator:
		var none := Composants.bouton("Aucun bonus : aucun ne m'intéresse", "BoutonSecondaire")
		none.custom_minimum_size = Vector2(620, 40)
		none.disabled = game.bonus_error(Match.NO_BONUS) != ""
		none.pressed.connect(_cmd.bind("pick_bonus", [Match.NO_BONUS]))
		night_bonus_box.add_child(none)

	# Montées de niveau : une amélioration gratuite à choisir par niveau gagné
	_clear(night_level_rows)
	night_level_box.visible = not spectator and not game.level_choices.is_empty()
	for lc in game.level_choices:
		var card: GameState.Card = lc["card"]
		var cat: Dictionary = UiTokens.CATEGORIES[card.metier["categorie"]]
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		var dot := Composants.pastille(cat["couleur"], Composants.icone_metier(str(card.metier["id"])), 32)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(dot)
		var who := VBoxContainer.new()
		who.add_theme_constant_override("separation", -2)
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var wn := Composants.label(card.nom)
		wn.add_theme_font_override("font", UiTokens.police_corps(800))
		_hover_card(wn, card)
		who.add_child(wn)
		var wj := Composants.label("%s · salaire %d" % [game.job_name(card), game.salary(card)], "TexteSecondaire")
		wj.add_theme_font_size_override("font_size", 12)
		who.add_child(wj)
		head.add_child(who)
		var lv := Composants.label("N%d → N%d" % [card.niveau - 1, card.niveau])
		lv.add_theme_font_override("font", UiTokens.police_corps(800))
		lv.add_theme_color_override("font_color", UiTokens.OR)
		head.add_child(lv)
		night_level_rows.add_child(head)
		for opt in lc["options"]:
			var ob := Composants.bouton("%s — %s" % [opt["nom"], opt.get("texte", _effect_text(opt["effet"]))], "BoutonSecondaire")
			ob.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ob.add_theme_font_size_override("font_size", 12)
			ob.custom_minimum_size = Vector2(290, 0)
			ob.pressed.connect(_cmd.bind("choose_level_upgrade", [card, opt]))
			night_level_rows.add_child(ob)

	# Améliorer ou licencier : ↑ ouvre les améliorations payantes, ✕ demande confirmation
	var rules := game.night_action_rules()
	var cost_up := int(rules["cout_amelioration"])
	var cost_fire := int(rules["cout_licenciement"])
	var act_err := game.night_action_error(mini(cost_up, cost_fire))
	night_action_box.visible = not spectator
	_clear(night_action_flow)
	if act_err != "":
		var l := Composants.label(act_err, "TexteSecondaire")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 290
		night_action_flow.add_child(l)
	else:
		for card in game.all_employees():
			night_action_flow.add_child(_employee_row(card, cost_up, cost_fire))
	night_fire_box.visible = not spectator and game.drh_available > 0
	_clear(night_fire)
	for card in game.all_employees():
		var row := HBoxContainer.new()
		var nl := Composants.label("%s · %s" % [card.nom, game.job_name(card)])
		nl.add_theme_font_size_override("font_size", 13)
		_hover_card(nl, card)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		var fb := Composants.bouton("Licencier", "BoutonSecondaire")
		fb.add_theme_font_size_override("font_size", 12)
		fb.pressed.connect(_cmd.bind("fire", [card]))
		row.add_child(fb)
		night_fire.add_child(row)

	# Journal : arrivées, achats des adversaires, alertes
	var lines: Array[String] = []
	for nm in r["arrivals"]:
		lines.append("[color=#1F7A4A]Arrivée au zoo : %s[/color]" % nm)
	for nm in r.get("malades", []):
		lines.append("[color=#E8782A]■ Malade : %s (envoyez un Soigneur dans son enclos)[/color]" % nm)
	if inc["visitors"] > 0:
		lines.append("%d visiteurs (%d repartis faute de place), %.1f présents en moyenne%s" % [inc["visitors"], inc["lost"], inc["avg_present"],
			" · affinités +%d %%" % roundi(inc.get("affinity", 0.0) * 100) if inc.get("affinity", 0.0) > 0.0 else ""])
	lines.append("%d collaborateur(s) mobilisé(s) aujourd'hui" % r["deployed"])
	for l in mt.log:
		lines.append("[color=#8A6A00]%s[/color]" % l)
	if game.employees() >= game.housing():
		lines.append("[color=#B5452A]Logement plein (%d / %d) : construisez une maison de collaborateurs pour embaucher.[/color]" % [game.employees(), game.housing()])
	night_text.text = "\n".join(lines)


## « Voir mon zoo » la nuit : une ligne par contrat du marché (motif, taille, aménagement requis).
func _rebuild_peek() -> void:
	_clear(peek_list)
	for def in game.market_contracts:
		var b := Button.new()
		b.custom_minimum_size = Vector2(296, 0)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", UiTokens.chip(Color(biome_colors[def["biome"]], 0.22), 8, 6))
		b.add_theme_stylebox_override("hover", UiTokens.chip(Color(biome_colors[def["biome"]], 0.36), 8, 6))
		b.add_theme_stylebox_override("pressed", UiTokens.chip(Color(UiTokens.OR, 0.3), 8, 6))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 8
		b.add_child(h)
		var pat := _pattern_view(def, 13.0)
		pat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(pat)
		var txt := Composants.label("%s\n%s · ≥ %d cases%s" % [def["nom"], biome_noms[def["biome"]], int(def["taille"]),
			"\n+ " + game.building_def(def["decor"])["nom"] if def.has("decor") else ""])
		txt.add_theme_font_size_override("font_size", 13)
		txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(txt)
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW
		b.tooltip_text = _pattern_words(def)
		peek_list.add_child(b)
		b.custom_minimum_size.y = maxf(54.0, pat.custom_minimum_size.y + 12.0)


## Montre (ou cache) sur la carte le meilleur emplacement du motif : dans l'enceinte si elle existe, sinon près du camp.
func _toggle_peek_hint(def: Dictionary) -> void:
	if peek_hint.get("def") == def:
		peek_hint = {}
	else:
		var zone: Array = []
		var interior: Dictionary = game.zoo_status()["interior"]
		var used := {}
		for a in game.animals:
			for t in a.pattern_tiles:
				used[t] = true
		if not interior.is_empty():
			zone = interior.keys().filter(func(t): return game.site_at(t) == null and not used.has(t))
		else:
			var c := game.map.camp.get_center()
			for y in range(c.y - 14, c.y + 15):
				for x in range(c.x - 14, c.x + 15):
					if game.map.in_bounds(x, y) and not game.map.in_camp(x, y) and game.site_at(Vector2i(x, y)) == null:
						zone.append(Vector2i(x, y))
		var ps := game.pattern_status(def, zone)
		peek_hint = {"def": def, "tiles": ps["tiles"], "missing": ps["missing"]}
		if not ps["tiles"].is_empty():
			var mid := Vector2.ZERO
			for t in ps["tiles"]:
				mid += Vector2(t) + Vector2(0.5, 0.5)
			camera.position = mid / ps["tiles"].size() * TILE
	peek_version = -1


## Bouton principal de la nuit : passer son tour au marché, garder le premier bonus, ou passer au jour suivant.
func _on_night_next() -> void:
	if mt.market_stage():
		if mt.current_buyer() == game.index:
			_cmd("pass_turn")
	elif mt.night_stage == "bonus":
		if mt.influence_leader() == game.index:
			_cmd("confirm_bonus")
	elif reseau:
		reseau.basculer_pret()
	else:
		game.start_next_day()
		selected.clear()


## Cabinet de recrutement : choisir la catégorie de la carte qui remplacera celle-ci.
func _open_recruit(card: GameState.Card) -> void:
	var rows := []
	if game.hippo_error() == "":
		# Hippopotame : on garde cette carte de la rangée en échange d'un de ses ouvriers
		for c in game.all_employees():
			rows.append([c, "Échanger", "", func():
				_cmd("hippo_swap", [c, card])
				_close_picker()])
	_open_picker("REMPLACER %s" % card.nom.to_upper(), "%s%s" % [
		"Hippopotame : échangez un de vos collaborateurs contre %s. " % card.nom if not rows.is_empty() else "",
		"Cabinet de recrutement : remplacez cette carte par une carte tirée au hasard dans la catégorie choisie. Une fois par nuit." if game.has_building("cabinet") else ""], rows)
	if not game.has_building("cabinet"):
		return
	for cat in ["peu_qualifie", "qualifie", "cadre"]:
		var err := game.recruit_error(cat)
		var b := Composants.bouton("%s · %d argent" % [UiTokens.CATEGORIES[cat]["long"], game.recruit_price(cat)], "BoutonPrincipal")
		b.disabled = err != ""
		b.tooltip_text = err
		b.pressed.connect(func():
			_cmd("recruit_replace", [card, cat])
			_close_picker())
		picker_box.add_child(b)
		picker_box.move_child(b, picker_box.get_child_count() - 2)


## Achats de cette étape de la nuit (tous les joueurs), dans l'ordre.
func _taken(stage: String) -> Array:
	return mt.night_taken.filter(func(t): return t["etape"] == stage)


## Carte déjà prise : grisée, sous une étiquette « Pris par … » à la couleur de l'acheteur.
func _taken_mark(w: Control, player: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UiTokens.chip(UiTokens.JOUEURS[player % UiTokens.JOUEURS.size()], 10, 3))
	var l := Composants.label("Pris par %s" % mt.names[player])
	l.add_theme_font_override("font", UiTokens.police_corps(800))
	l.add_theme_font_size_override("font_size", 13)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_child(l)
	box.add_child(tag)
	w.modulate = Color(1, 1, 1, 0.5)
	box.add_child(w)
	return box


# --- Aide au placement d'un animal ---------------------------------------------

func _build_proposal_box() -> void:
	proposal_box = PanelContainer.new()
	proposal_box.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 10, 2, 10))
	proposal_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	proposal_box.offset_top = 104
	proposal_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	proposal_box.visible = false
	ui.add_child(proposal_box)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	proposal_box.add_child(hb)
	proposal_pattern = CenterContainer.new()
	hb.add_child(proposal_pattern)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	hb.add_child(v)
	proposal_label = RichTextLabel.new()
	proposal_label.bbcode_enabled = true
	proposal_label.fit_content = true
	proposal_label.scroll_active = false
	proposal_label.custom_minimum_size = Vector2(430, 0)
	proposal_label.add_theme_font_size_override("normal_font_size", 13)
	proposal_label.add_theme_font_size_override("bold_font_size", 14)
	v.add_child(proposal_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	proposal_btn = Composants.bouton("", "BoutonPrincipal")
	proposal_btn.custom_minimum_size = Vector2(0, 34)
	proposal_btn.pressed.connect(_build_proposal)
	row.add_child(proposal_btn)
	var cancel := Composants.bouton("Annuler (Échap)", "BoutonSecondaire")
	cancel.custom_minimum_size = Vector2(0, 34)
	cancel.pressed.connect(func(): _set_build({}))
	row.add_child(cancel)


## Contrat choisi : repère les enclos où l'animal peut aller (motif en vert) ou presque (orange : cases à aménager),
## et propose un enclos à construire s'il n'y en a aucun.
func _compute_animal_hints(def: Dictionary, propose: bool) -> void:
	animal_hints.clear()
	var interior: Dictionary = game.zoo_status()["interior"]
	var seen := {}
	for t in interior:
		if seen.has(t) or game.is_fence(t) or game.site_at(t) != null:
			continue
		var enc := game.enclosure_at(t)
		if not enc["closed"]:
			seen[t] = true
			continue
		for q in enc["tiles"]:
			seen[q] = true
		var err := game.animal_error(def, enc)
		if err == "" or err.begins_with("Motif absent (au mieux"):
			var ps := game.pattern_status(def, game.free_enclosure_tiles(enc))
			animal_hints.append({"tiles": ps["tiles"], "ok": err == "", "missing": ps["missing"], "park": enc.get("park", false)})
	if propose:
		enclosure_proposal = {}
		if not animal_hints.any(func(h): return h["ok"] and not h["park"]):
			_propose_enclosure(def, interior)
	_update_proposal_box(def, interior)


## Enclos à construire proposé quand aucun enclos clôturé ne convient (voir GameState.enclosure_site).
func _propose_enclosure(def: Dictionary, _interior: Dictionary) -> void:
	enclosure_proposal = game.enclosure_site(def)


func _update_proposal_box(def: Dictionary, interior: Dictionary) -> void:
	proposal_box.visible = true
	_clear(proposal_pattern)
	proposal_pattern.add_child(_pattern_view(def, 20.0))
	var ok := animal_hints.filter(func(h): return h["ok"] and not h["park"]).size()
	var near := animal_hints.filter(func(h): return not h["ok"]).size()
	var lines: Array[String] = ["[b]%s[/b] · %s" % [def["nom"], _pattern_words(def).replace("\n", " ")]]
	proposal_btn.visible = false
	if interior.is_empty():
		lines.append("[color=#B5452A]Fermez d'abord l'enceinte du zoo avec son entrée : les animaux vivent à l'intérieur.[/color]")
	elif ok > 0:
		lines.append("[color=#1F7A4A]%d emplacement(s) possible(s), en vert : cliquez dedans pour installer.[/color]" % ok)
	elif not enclosure_proposal.is_empty():
		var n: int = enclosure_proposal["new"].size()
		lines.append("Aucun enclos ne convient. Enclos proposé en pointillés : %d clôture(s) à poser%s." % [n,
			", puis %d case(s) à aménager (en orange)" % enclosure_proposal["missing"] if enclosure_proposal["missing"] > 0 else ""])
		if enclosure_proposal["missing"] == 0:
			lines.append("Ou cliquez ailleurs dans le parc : l'enclos se pose en chantier autour de la case cliquée.")
		proposal_btn.visible = n > 0
		var cost := game.enclosure_cost(enclosure_proposal)
		proposal_btn.visible = n > 0 or enclosure_proposal.has("decor")
		proposal_btn.text = ("Construire l'enclos et réserver l'animal · %s" if enclosure_proposal["missing"] == 0 else "Construire cet enclos · %s") % game.cost_text(cost)
		proposal_btn.disabled = not game.can_afford(cost) or game.phase != "day"
		proposal_btn.tooltip_text = "Pose %d segments de clôture d'enclos (1 bois chacun) en chantier. Envoyez des collaborateurs (clic droit) : l'animal, réservé, arrive la nuit suivant la fin des clôtures." % n
	elif near > 0:
		lines.append("[color=#8A6A00]Aucun enclos ne convient tel quel : les cases orange sont à aménager (onglet Terrain).[/color]")
	else:
		lines.append("[color=#B5452A]Pas de place libre pour un enclos dans l'enceinte : agrandissez-la.[/color]")
	if near > 0 and ok > 0:
		lines.append("En orange : %d enclos presque prêt(s) (cases à aménager)." % near)
	proposal_label.text = "\n".join(lines)


func _build_proposal() -> void:
	if enclosure_proposal.is_empty():
		return
	var def: Dictionary = build_choice["def"] if build_choice.get("kind") == "animal" else {}
	var err := _cmd_texte("construire_proposition", [enclosure_proposal, def])
	if err != "":
		game.say(err)
	elif enclosure_proposal["missing"] == 0 and not def.is_empty():
		_set_build({})
	enclosure_proposal["new"] = []
	enclosure_proposal.erase("decor")


func _draw_peek_hint() -> void:
	if peek_hint.is_empty():
		return
	var ok: bool = peek_hint["missing"] == 0
	var col := Color("7CF29A") if ok else UiTokens.DEFAUT
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 260.0)
	for t in peek_hint["tiles"]:
		draw_rect(Rect2(Vector2(t) * TILE, Vector2(TILE, TILE)), Color(col, 0.3 * pulse))
		draw_rect(Rect2(Vector2(t) * TILE + Vector2(1.5, 1.5), Vector2(TILE - 3, TILE - 3)), col, false, 1.5)
	if not peek_hint["tiles"].is_empty():
		var t0: Vector2i = peek_hint["tiles"][0]
		_label("%s : %s" % [peek_hint["def"]["nom"], "motif présent" if ok else "%d case(s) à aménager" % peek_hint["missing"]],
			(Vector2(t0) + Vector2(0.5, -0.6)) * TILE, 10)


func _draw_animal_hints() -> void:
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 260.0)
	for h in animal_hints:
		var col: Color = Color("7CF29A") if h["ok"] else UiTokens.DEFAUT
		var c := Vector2.ZERO
		for t in h["tiles"]:
			draw_rect(Rect2(Vector2(t) * TILE, Vector2(TILE, TILE)), Color(col, 0.28 * pulse))
			draw_rect(Rect2(Vector2(t) * TILE + Vector2(1.5, 1.5), Vector2(TILE - 3, TILE - 3)), col, false, 1.5)
			c += Vector2(t) + Vector2(0.5, 0.5)
		if not h["tiles"].is_empty():
			c = c / h["tiles"].size() * TILE
			_draw_pin(c - Vector2(0, 2), "ui_valide" if h["ok"] else "terrain_planter_foret", col.darkened(0.25))
	if not enclosure_proposal.is_empty():
		var r: Rect2i = enclosure_proposal["rect"]
		draw_rect(Rect2(Vector2(r.position) * TILE, Vector2(r.size) * TILE), Color(UiTokens.SELECTION, 0.1))
		for t in enclosure_proposal["ring"]:
			var rr := Rect2(Vector2(t) * TILE, Vector2(TILE, TILE)).grow(-3)
			if enclosure_proposal["new"].has(t):
				_dashed_rect(rr, UiTokens.SELECTION)
		if enclosure_proposal.has("decor"):
			var dr := Rect2(Vector2(enclosure_proposal["decor_tile"]) * TILE, Vector2(TILE, TILE)).grow(-3)
			_dashed_rect(dr, UiTokens.SELECTION)
			_draw_pin(dr.get_center() + Vector2(0, 2), Composants.icone_batiment(enclosure_proposal["decor"]), building_colors[enclosure_proposal["decor"]])
		for t in enclosure_proposal["pattern"]:
			var ok_t: bool = enclosure_proposal["missing"] == 0
			draw_rect(Rect2(Vector2(t) * TILE + Vector2(2, 2), Vector2(TILE - 4, TILE - 4)), Color("7CF29A") if ok_t else UiTokens.DEFAUT, false, 1.5)


## Illustration d'un animal sur un disque clair (lisible sur les fonds sombres des biomes), ou null.
func _animal_picture(id: String, taille: Vector2) -> Control:
	var tex := _image("res://ui/animaux/%s.svg" % id)
	if tex == null:
		return null
	var box := Control.new()
	box.custom_minimum_size = taille
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var halo := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UiTokens.ENCRE, 0.16)
	sb.set_corner_radius_all(int(taille.y))
	halo.add_theme_stylebox_override("panel", sb)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Composants.placer(box, halo, Vector2(taille.x * 0.06, taille.y * 0.04), Vector2(taille.x * 0.88, taille.y * 0.92))
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.texture = tex
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Composants.placer(box, tr, Vector2.ZERO, taille)
	return box


## Fiche d'un animal installé : contrat, motif, nourriture, affinités.
func _animal_info(a: GameState.Animal) -> void:
	var d: Dictionary = a.def
	zoo_title.text = "ANIMAL"
	var mult := game.animal_attract_mult(a)
	var lines: Array[String] = [
		"[b]%s[/b] · palier %s" % [d["nom"], d["palier"]],
		"[color=%s]%s[/color] · %s · %s" % [biome_colors[d["biome"]].to_html(false), biome_noms[d["biome"]], game.continent_name(d.get("continent", "")), game.type_name(d.get("type", ""))],
		"",
		"État : %s" % ("arrive cette nuit" if not a.arrived else ("[color=#1F7A4A]nourri[/color]" if a.fed else "[color=#B5452A]a faim : il ne compte plus dans l'attractivité[/color]")),
		"Attractivité : [b]%d[/b]%s" % [int(d["reputation"]), " (×%.2f avec les bonus)" % mult if not is_equal_approx(mult, 1.0) else ""],
		"Nourriture : %d rations / jour · réserve %.0f / %.0f" % [roundi(game.rations_per_day(d)), a.food, game.food_capacity(d)],
		("En liberté dans le parc (%d cases)" if a.park else "Enclos : %d cases") % a.tiles.size() + " · il lui en faut %d" % int(d["taille"]),
	]
	var same := game.animals.filter(func(o): return o != a and o.arrived and o.def.get("continent", "") == d.get("continent", "")).size()
	if same > 0:
		lines.append("[color=#8A6A00]Affinité : %d autre(s) animal(aux) d'%s dans le zoo[/color]" % [same, game.continent_name(d.get("continent", ""))])
	var nb := game.continent_neighbours(a)
	if not nb.is_empty():
		lines.append("[color=#8A6A00]Voisins d'%s : %s (+%d d'attractivité)[/color]" % [game.continent_name(d.get("continent", "")),
			", ".join(nb.map(func(o): return o.def["nom"])), nb.size() * int(game.data["animals"]["voisinage_continent"]["points"])])
	if d.has("decor"):
		lines.append("Aménagement requis : %s" % game.building_def(d["decor"])["nom"])
	if d.has("effet_texte"):
		lines.append("[color=#13867F]Rare : %s[/color]" % d["effet_texte"])
	var mates := game.shared_type_count(a)
	if mates > 0:
		lines.append("[color=#8A6A00]Enclos partagé : %d autre(s) animal(aux) %s ici (+%d %% de réputation)[/color]" % [
			mates, game.type_name(d.get("type", "")), roundi(mates * float(game.data["animals"]["affinite_type"]["par_animal"]) * 100)])
	info_text.text = "\n".join(lines)
	if info_extra_for != a:
		info_extra_for = a
		_clear(info_extra)
		var pic := _animal_picture(d["id"], Vector2(150, 112))
		if pic:
			var pc := CenterContainer.new()
			pc.add_child(pic)
			info_extra.add_child(pc)
		info_extra.add_child(Composants.label("Motif d'enclos du contrat", "TexteSecondaire"))
		var cc := CenterContainer.new()
		cc.add_child(_pattern_view(d, 22.0))
		info_extra.add_child(cc)


## Prix du panneau Marché, recalculés selon la quantité choisie et les Marchands postés.
func _update_trade() -> void:
	if trade_rows.is_empty():
		return
	for ld in game.label_defs():
		var lb: Button = label_buttons[ld["id"]]
		var lerr := game.label_error(ld)
		lb.text = "%s · %d or → +%d réputation%s" % [ld["nom"], int(game.label_price(ld)), int(ld["reputation"]), " ✓" if game.labels_owned.has(ld["id"]) else ""]
		lb.disabled = lerr != ""
		lb.tooltip_text = lerr
	var rate := game.sell_rate()
	var who := "Marchand + bâtiment Marché" if game.buy_mult() < 1.0 else ("Marchand mobilisé" if game.marchand_present() else ("bâtiment Marché" if game.market_built() else "sans Marchand"))
	trade_note.text = "Vente à %d %%%s (%s)" % [roundi(rate * 100), " · achat −%d %%" % roundi((1.0 - game.buy_mult()) * 100) if game.buy_mult() < 1.0 else "", who]
	for res in trade_rows:
		var row: Array = trade_rows[res]
		var qty := int(row[0].value)
		var units := mini(qty, floori(game.stock[res] + 0.0001))
		# Moins que la quantité choisie en stock : on affiche ce qui sera vraiment vendu, et pour combien
		var gain := floori(units * game.sell_price(res))
		row[1].text = "Vendre +%d" % gain if units >= qty else "Vendre %d · +%d" % [units, gain]
		row[1].disabled = game.phase != "day" or units <= 0
		row[1].tooltip_text = "Vend %d %s (stock %d) à %.1f l'unité" % [units, res, floori(game.stock[res]), game.sell_price(res)]
		if res != "or":
			var cost := ceili(game.buy_price(res) * qty)
			row[2].text = "Acheter −%d" % cost
			row[2].disabled = game.phase != "day" or game.money < cost
			row[2].tooltip_text = "Achète %d %s à %.1f l'unité (double du prix de revente, moins la remise d'un Marchand au Marché)" % [qty, res, game.buy_price(res)]


## Publicité : multiplicateur de visiteurs, campagne en cours et boutons de lancement.
func _update_publicity() -> void:
	if pub_buttons.is_empty():
		return
	var lines: Array[String] = ["Visiteurs ×%s (%d point(s) de publicité)" % [("%.2f" % game.publicity_mult()).replace(".", ","), roundi(game.publicite)]]
	if not game.campaign.is_empty():
		var c: Dictionary = game.campaign
		var pct := roundi(100.0 * float(c["progress"]) / float(c["def"]["travail"]))
		var eta := game.campaign_eta()
		lines.append("En cours : %s, %d %% · %s" % [c["def"]["nom"], pct,
			"personne dehors : en pause" if eta == INF else "encore ~%d s" % ceili(eta)])
	elif game.outside_workers().is_empty():
		lines.append("Envoyez un collaborateur à l'extérieur (case Accès) pour lancer une campagne.")
	pub_note.text = "\n".join(lines)
	for d in game.campaign_defs():
		var b: Button = pub_buttons[d["id"]]
		var err := game.campaign_error(d)
		b.text = "%s · %d" % [d["court"], game.campaign_cost(d)]
		b.disabled = err != ""
		b.tooltip_text = "%s : %d argent (40 %% de moins avec un Lobbyiste dehors), %s (travail %d s à l'extérieur).%s" % [d["nom"], game.campaign_cost(d), d["texte"], int(d["travail"]),
			"\n" + err if err != "" else ""]


# --- Choix d'un ouvrier : cartes d'action ciblées, Agence d'intérim ----------------

## rows : [carte, texte du bouton, erreur ("" si possible), action]. En journée, la partie est en pause pendant le choix.
func _open_picker(title: String, subtitle: String, rows: Array) -> void:
	if picker_root == null:
		var o := _overlay()
		picker_root = o[0]
		picker_box = o[1]
	ui.move_child(picker_root, -1)
	if not picker_root.visible and game.phase == "day":
		picker_speed = speed
		_set_speed(0.0)
	picker_root.visible = true
	_clear(picker_box)
	picker_box.add_child(Composants.label(title, "TitrePanneau"))
	if subtitle != "":
		var s := Composants.label(subtitle, "TexteSecondaire")
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size.x = 560
		picker_box.add_child(s)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, mini(440, rows.size() * 52 + 8))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	picker_box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for r in rows:
		list.add_child(_picker_row(r[0], r[1], r[2], r[3]))
	var close := Composants.bouton("Annuler", "BoutonSecondaire")
	close.pressed.connect(_close_picker)
	picker_box.add_child(close)


func _close_picker() -> void:
	if picker_root and picker_root.visible:
		picker_root.visible = false
		if picker_speed >= 0.0:
			_set_speed(picker_speed)
			picker_speed = -1.0


func _picker_row(card: GameState.Card, button_text: String, err: String, cb: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.tooltip_text = _card_full_tooltip(card)
	var cat: Dictionary = UiTokens.CATEGORIES[card.metier["categorie"]]
	var dot := Composants.pastille(cat["couleur"], Composants.icone_metier(str(card.metier["id"])), 32)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", -2)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(who)
	var nm := Composants.label(card.nom)
	nm.add_theme_font_override("font", UiTokens.police_corps(800))
	_hover_card(nm, card)
	who.add_child(nm)
	var traits: Array[String] = []
	for t in game.trait_defs(card):
		traits.append(t["nom"])
	var jl := Composants.label("%s · N%d · salaire %d%s" % [game.job_name(card), card.niveau, game.salary(card),
		(" · " + ", ".join(traits)) if not traits.is_empty() else ""], "TexteSecondaire")
	jl.add_theme_font_size_override("font_size", 12)
	jl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	jl.custom_minimum_size.x = 340
	who.add_child(jl)
	var b := Composants.bouton(button_text if err == "" else _short_reason(err), "BoutonPrincipal")
	b.custom_minimum_size = Vector2(150, 34)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = err != ""
	b.tooltip_text = err
	b.pressed.connect(cb)
	row.add_child(b)
	return row


## Cadre joué : effet immédiat, ou choix d'une carte de la main (DRH) ou d'une ressource (Marchand).
func _on_play_cadre(card: GameState.Card) -> void:
	var A := game.cadre_action(card)
	match A.get("cible", ""):
		"main":
			var rows := []
			for c in game.hand:
				if c == card or c.is_action():
					continue
				rows.append([c, "Former" if A["effet"].has("stage") else "Licencier", game.cadre_error(card, c), func():
					_cmd("play_cadre", [card, c])
					_close_picker()])
			_open_picker(A["nom"].to_upper(), A["texte"], rows)
		"ressource":
			_open_picker(A["nom"].to_upper(), A["texte"], [])
			for res in ["bois", "pierre"]:
				var n := floori(game.stock[res])
				var gain := floori(n * float(game.data["buildings"]["conversion"][res]) * float(A["effet"]["vente"]))
				var b := Composants.bouton("Vendre %d %s · +%d" % [n, res, gain], "BoutonPrincipal")
				b.disabled = game.cadre_error(card, null, res) != ""
				b.pressed.connect(func():
					_cmd("play_cadre", [card, null, res])
					_close_picker())
				picker_box.add_child(b)
				picker_box.move_child(b, picker_box.get_child_count() - 2)
		_:
			_cmd("play_cadre", [card])


## Rupture de contrat : l'ouvrier à licencier. Promotion : l'ouvrier, puis son amélioration.
func _open_action_picker(card: GameState.Card) -> void:
	var fire: bool = card.action["effet"].has("licencier")
	var rows := []
	for c in game.all_employees():
		var err := game.action_target_error(card, c)
		if fire:
			rows.append([c, "Licencier", err, func():
				_cmd("play_action", [card, c])
				_close_picker()])
		else:
			rows.append([c, "Choisir", err, _open_promotion.bind(card, c)])
	_open_picker(card.action["nom"].to_upper(), card.action["texte"] + " La carte quitte ensuite votre deck.", rows)


func _open_promotion(card: GameState.Card, target: GameState.Card) -> void:
	_clear(picker_box)
	picker_box.add_child(Composants.label("PROMOTION : %s" % target.nom.to_upper(), "TitrePanneau"))
	var s := Composants.label("%s, niveau %d. Choisissez son amélioration :" % [game.job_name(target), target.niveau], "TexteSecondaire")
	picker_box.add_child(s)
	for opt in game.upgrade_options(target):
		var ob := Composants.bouton("%s — %s" % [opt["nom"], opt.get("texte", _effect_text(opt["effet"]))], "BoutonSecondaire")
		ob.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ob.custom_minimum_size = Vector2(560, 0)
		ob.pressed.connect(func():
			_cmd("play_action", [card, target, opt])
			_close_picker())
		picker_box.add_child(ob)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	picker_box.add_child(row)
	var back := Composants.bouton("Autre collaborateur", "BoutonSecondaire")
	back.pressed.connect(_open_action_picker.bind(card))
	row.add_child(back)
	var close := Composants.bouton("Annuler", "BoutonSecondaire")
	close.pressed.connect(_close_picker)
	row.add_child(close)


## Agence d'intérim : choisir dans la pioche ou la défausse le remplaçant de l'ouvrier `w` (sur le terrain).
func _open_swap_picker(w: GameState.Worker) -> void:
	var rows := []
	for c in game.swap_candidates():
		rows.append([c, "Prendre · %d" % game.swap_cost(c), game.swap_error(w, c), func():
			_cmd("swap_worker", [w, c])
			_close_picker()])
	_open_picker("AGENCE D'INTÉRIM", "Remplacer %s (%s) : le remplaçant arrive à sa place, garde sa charge et reprend sa tâche ; %s part à la défausse. Coût : %d de frais + salaire du remplaçant. Une fois par jour." % [
		w.card.nom, game.job_name(w.card), w.card.nom, int(game.data["buildings"]["agence"]["frais"])], rows)

## Emprunt : proposé quand aucun ouvrier de la main ne peut être payé ; rappel du remboursement une fois pris.
func _update_loan() -> void:
	var L: Dictionary = game.data["workers"]["regles"]["emprunt"]
	loan_btn.visible = not spectator and game.phase == "day" and (game.loan_today or game.loan_error() == "")
	loan_btn.disabled = game.loan_today
	loan_btn.text = ("Emprunt : −%d ce soir" % int(L["remboursement"])) if game.loan_today \
		else "Emprunter %d (−%d ce soir)" % [int(L["montant"]), int(L["remboursement"])]
	loan_btn.tooltip_text = "Aucun salaire payable : empruntez %d d'argent, %d seront retirés automatiquement ce soir (le solde peut devenir négatif). Une fois par jour." % [
		int(L["montant"]), int(L["remboursement"])]


## Pioche et défausse : ce que la main de demain peut contenir (l'ordre de la pioche reste caché).
func _open_pile() -> void:
	if pile_root == null:
		var o := _overlay()
		pile_root = o[0]
		pile_box = o[1]
	ui.move_child(pile_root, -1)
	pile_root.visible = true
	_clear(pile_box)
	var n := game.hand_size()
	pile_box.add_child(Composants.label("PIOCHE ET DÉFAUSSE", "TitrePanneau"))
	var info := "Demain matin, vous piocherez %d cartes au hasard dans la pioche (l'ordre est caché)." % n
	if game.deck.size() < n:
		info = "La pioche (%d carte(s)) ne suffit pas pour une main de %d : demain, vous prendrez toute la pioche, puis la défausse, avec la main d'aujourd'hui, sera remélangée pour compléter." % [game.deck.size(), n]
	var il := Composants.label(info, "TexteSecondaire")
	il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	il.custom_minimum_size.x = 1100
	pile_box.add_child(il)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1120, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pile_box.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 8)
	scroll.add_child(inner)
	for section in [["PIOCHE", game.deck], ["DÉFAUSSE", game.discard]]:
		var cards: Array = section[1]
		var st := Composants.label("%s · %d" % [section[0], cards.size()], "TitrePanneau")
		st.add_theme_font_size_override("font_size", 16)
		inner.add_child(st)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 10)
		flow.add_theme_constant_override("v_separation", 10)
		inner.add_child(flow)
		var sorted := cards.duplicate()
		sorted.sort_custom(func(a, b): return a.nom < b.nom)  # trié : la pioche ne révèle pas son ordre
		for c in sorted:
			if c.is_action():
				flow.add_child(_action_widget(c, "Carte d'action", true, func(): pass))
			else:
				flow.add_child(_card_widget(c, "Salaire %d" % game.salary(c), true, func(): pass, [], "draft"))
		if cards.is_empty():
			flow.add_child(Composants.label("Vide", "TexteSecondaire"))
	var close := Composants.bouton("Fermer", "BoutonPrincipal")
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.custom_minimum_size = Vector2(220, 36)
	close.pressed.connect(func(): pile_root.visible = false)
	pile_box.add_child(close)


## Raison courte à écrire sur un bouton désactivé (le détail reste dans l'infobulle).
func _short_reason(err: String) -> String:
	for pair in [["Logement plein", "Logement plein"], ["pas votre tour", "Pas votre tour"], ["Déjà un échange", "Déjà échangé"], ["Déjà", "Déjà embauché"],
			["terrain", "Sur le terrain"], ["dernier", "Dernier collaborateur"],
			["argent", "Pas assez d'argent"], ["spectateur", "Spectateur"], ["n'ouvre", "Marché fermé"]]:
		if pair[0] in err:
			return pair[1]
	return err.left(22)


func _player_dot(col: Color) -> Control:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(8)
	sb.border_color = Color.WHITE
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(16, 16)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Réputation d'un joueur à une nuit passée (historique de la partie ; offset -1 = cette nuit, -2 = la veille).
func _rep_on_night(i: int, offset: int) -> int:
	if mt.history.size() < -offset:
		return 0
	return int(mt.history[mt.history.size() + offset][i]["rep"])


func _employee_row(card: GameState.Card, cost_up: int, cost_fire: int) -> Control:
	var cat: Dictionary = UiTokens.CATEGORIES[card.metier["categorie"]]
	var box := PanelContainer.new()
	var bs := UiTokens.chip(Color(UiTokens.ENCRE, 0.05) if card != action_card else Color(UiTokens.OR, 0.1), 8, 6)
	box.add_theme_stylebox_override("panel", bs)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	box.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var dot := Composants.pastille(cat["couleur"], Composants.icone_metier(str(card.metier["id"])), 30)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", -2)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(who)
	var nm := Composants.label(card.nom)
	nm.add_theme_font_override("font", UiTokens.police_corps(800))
	nm.add_theme_font_size_override("font_size", 13)
	_hover_card(nm, card)
	who.add_child(nm)
	var traits: Array[String] = []
	for t in game.trait_defs(card):
		traits.append(t["nom"])
	var jl := Composants.label("%s · N%d%s" % [game.job_name(card), card.niveau, (" · " + ", ".join(traits)) if not traits.is_empty() else ""], "TexteSecondaire")
	jl.add_theme_font_size_override("font_size", 11)
	jl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	jl.custom_minimum_size.x = 170
	who.add_child(jl)
	var up := Composants.bouton("", "BoutonOrdre")
	up.icon = UiTokens.icone("ui_ameliorer")
	up.expand_icon = true
	up.add_theme_constant_override("icon_max_width", 18)
	up.custom_minimum_size = Vector2(36, 36)
	up.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	up.tooltip_text = "Améliorer (%d argent)" % cost_up
	up.pressed.connect(func():
		action_card = null if action_card == card and action_mode == "up" else card
		action_mode = "up"
		hand_version = -1)
	row.add_child(up)
	var fire := Composants.bouton("", "BoutonOrdre")
	fire.icon = UiTokens.icone("ui_invalide")
	fire.expand_icon = true
	fire.add_theme_constant_override("icon_max_width", 16)
	fire.custom_minimum_size = Vector2(36, 36)
	fire.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fire.add_theme_color_override("icon_normal_color", UiTokens.DEFAUT)
	fire.tooltip_text = "Licencier (%d argent)" % cost_fire
	fire.pressed.connect(func():
		action_card = null if action_card == card and action_mode == "fire" else card
		action_mode = "fire"
		hand_version = -1)
	row.add_child(fire)
	if card == action_card:
		if action_mode == "up":
			for opt in game.upgrade_options(card):
				var ub := Composants.bouton("%s (%d) — %s" % [opt["nom"], cost_up, opt.get("texte", _effect_text(opt["effet"]))], "BoutonSecondaire")
				ub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				ub.add_theme_font_size_override("font_size", 12)
				ub.disabled = game.night_action_error(cost_up) != ""
				ub.pressed.connect(func():
					_cmd("apply_upgrade", [card, opt])
					action_card = null)
				v.add_child(ub)
		else:
			var fb := Composants.bouton("Confirmer le licenciement (%d)" % cost_fire, "BoutonPrincipal")
			fb.add_theme_font_size_override("font_size", 12)
			fb.disabled = game.night_action_error(cost_fire) != ""
			fb.pressed.connect(func():
				_cmd("fire_paid", [card])
				action_card = null)
			v.add_child(fb)
	return box


# --- Écran de fin de partie (capture 06) ------------------------------------------

func _build_end_ui() -> void:
	end_root = ColorRect.new()
	end_root.color = Color(UiTokens.PAPIER_2, 0.92)
	end_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_root.mouse_filter = Control.MOUSE_FILTER_STOP
	end_root.visible = false
	ui.add_child(end_root)
	end_reopen = Composants.bouton("Résultats de la partie", "BoutonPrincipal")
	end_reopen.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	end_reopen.offset_top = 64
	end_reopen.offset_left = -120
	end_reopen.offset_right = 120
	end_reopen.offset_bottom = 104
	end_reopen.visible = false
	end_reopen.pressed.connect(func(): end_dismissed = false)
	ui.add_child(end_reopen)
	# Carte finale : passer d'un zoo à l'autre
	end_views = HBoxContainer.new()
	end_views.add_theme_constant_override("separation", 6)
	end_views.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	end_views.offset_top = 112
	end_views.offset_left = -300
	end_views.offset_right = 300
	end_views.alignment = BoxContainer.ALIGNMENT_CENTER
	end_views.visible = false
	ui.add_child(end_views)


func _rebuild_end() -> void:
	_clear(end_root)
	var n := mt.players.size()
	var w: int = mt.winner
	var won := not spectator and w == game.index
	var reached := mt.players[w].reputation() >= mt.objective()
	# Bandeau
	var band_c := CenterContainer.new()
	band_c.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	band_c.offset_top = 38
	band_c.offset_bottom = 116
	end_root.add_child(band_c)
	var band := PanelContainer.new()
	var bs := UiTokens.panel(UiTokens.ENTETE, UiTokens.OR, 4, 2, 12)
	bs.content_margin_left = 70
	bs.content_margin_right = 70
	band.add_theme_stylebox_override("panel", bs)
	band_c.add_child(band)
	var bl := Composants.label("CONCESSION REMPORTÉE" if won else ("FILIALE LIQUIDÉE" if not spectator else "FIN DE PARTIE"), "TitreEcran")
	bl.add_theme_font_size_override("font_size", 48)
	bl.add_theme_color_override("font_color", UiTokens.OR_CLAIR)
	band.add_child(bl)
	var sub := RichTextLabel.new()
	sub.bbcode_enabled = true
	sub.fit_content = true
	sub.scroll_active = false
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top = 124
	sub.offset_bottom = 152
	sub.add_theme_font_size_override("normal_font_size", 17)
	sub.text = "[center]Rapport annuel aux actionnaires · %s %s [color=#8A6A00]%d[/color] de réputation au soir du jour %d[/center]" % [
		mt.names[w], "atteint" if reached else "termine en tête avec", mt.players[w].reputation(), mt.day]
	end_root.add_child(sub)
	# Podium : 2e, 1er, 3e, 4e
	var ranking := range(n)
	ranking.sort_custom(func(a, b): return mt.players[a].reputation() > mt.players[b].reputation())
	var slots := [1, 0, 2, 3]
	var heights := [300.0, 240.0, 190.0, 140.0]
	var me_index := game.index if not spectator else -1
	var podium := Control.new()
	podium.position = Vector2(110, 190)
	podium.size = Vector2(700, 470)
	podium.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_root.add_child(podium)
	for slot in mini(n, 4):
		var rank: int = slots[slot]
		if rank >= n:
			continue
		var i: int = ranking[rank]
		var col: Color = UiTokens.JOUEURS[i % UiTokens.JOUEURS.size()]
		var x := slot * 172.0
		var top: float = 470.0 - heights[rank]
		var disc := PanelContainer.new()
		var ds := StyleBoxFlat.new()
		ds.bg_color = col
		ds.set_corner_radius_all(48)
		ds.border_color = UiTokens.SELECTION if rank == 0 else UiTokens.ENCRE
		ds.set_border_width_all(4)
		ds.shadow_color = Color(0, 0, 0, 0.4)
		ds.shadow_size = 8
		disc.add_theme_stylebox_override("panel", ds)
		var dl := Composants.label(str(rank + 1), "TitreEcran")
		dl.add_theme_font_size_override("font_size", 38)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		disc.add_child(dl)
		var logo_p := Composants.logo_groupe(mt.names[i])
		if logo_p:
			# Le logo du groupe, le rang en petit
			Composants.placer(podium, Composants.image_logo(logo_p, Vector2(180, 104)), Vector2(x - 15, top - 172), Vector2(180, 104))
			dl.add_theme_font_size_override("font_size", 18)
			Composants.placer(podium, disc, Vector2(x + 57, top - 100), Vector2(36, 36))
		else:
			Composants.placer(podium, disc, Vector2(x + 27, top - 164), Vector2(96, 96))
		var nm := Composants.label(mt.names[i])
		nm.add_theme_font_override("font", UiTokens.police_corps(800))
		nm.add_theme_font_size_override("font_size", 18)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Composants.placer(podium, nm, Vector2(x, top - 60), Vector2(150, 24))
		var pl: GameState = mt.players[i]
		var st := Composants.label("%d animaux · %d visiteurs" % [pl.animals.filter(func(a): return a.arrived).size(), _visitors_total(i)], "TexteSecondaire")
		st.add_theme_font_size_override("font_size", 12)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Composants.placer(podium, st, Vector2(x - 10, top - 34), Vector2(170, 20))
		var box := Panel.new()
		var xs := StyleBoxFlat.new()
		xs.bg_color = UiTokens.PANNEAU_MILIEU
		xs.border_color = UiTokens.SELECTION if i == game.index and not spectator else Color(UiTokens.TEXTE_SECONDAIRE, 0.4)
		xs.set_border_width_all(2)
		xs.corner_radius_top_left = 4
		xs.corner_radius_top_right = 4
		box.add_theme_stylebox_override("panel", xs)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Composants.placer(podium, box, Vector2(x, top), Vector2(150, heights[rank]))
		var val := Composants.label(str(pl.reputation()), "Compteur")
		val.add_theme_font_size_override("font_size", 30)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Composants.placer(box, val, Vector2(0, 12), Vector2(150, 36))
		var vl := Composants.label("réputation", "TexteSecondaire")
		vl.add_theme_font_size_override("font_size", 12)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Composants.placer(box, vl, Vector2(0, 48), Vector2(150, 18))
		var sort_ := Composants.label("Concession remportée" if rank == 0 else "Filiale liquidée", "TexteSecondaire")
		sort_.add_theme_font_size_override("font_size", 12)
		sort_.add_theme_color_override("font_color", UiTokens.POSITIF if rank == 0 else UiTokens.NEGATIF)
		sort_.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Composants.placer(box, sort_, Vector2(0, 108), Vector2(150, 18))
		# Voir le zoo de ce joueur sur la carte finale
		var see := Composants.bouton("Voir son zoo" if i != me_index else "Voir mon zoo", "BoutonSecondaire")
		see.add_theme_font_size_override("font_size", 13)
		see.pressed.connect(_watch_board.bind(i))
		Composants.placer(box, see, Vector2(10, 74), Vector2(130, 32))
	# Panneau « Votre partie » : chiffres clés, courbes de réputation, biomes
	var me := game.index
	var host := Control.new()
	host.position = Vector2(858, 190)
	host.size = Vector2(620, 470)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_root.add_child(host)
	var holder := VBoxContainer.new()
	holder.custom_minimum_size = Vector2(620, 0)
	host.add_child(holder)
	var p := _titled_panel(holder, "VOTRE PARTIE" if not spectator else mt.names[me].to_upper())
	var body: VBoxContainer = p[1]
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 8)
	body.add_child(tiles)
	var species := {}
	var biomes := {}
	for a in game.animals:
		if a.arrived:
			species[a.def["id"]] = true
			biomes[a.def["biome"]] = true
	for t in [[str(species.size()), "espèces", UiTokens.POSITIF], ["%d" % biomes.size(), "biomes sur %d" % biome_noms.size(), UiTokens.SELECTION],
			[str(_visitors_total(me)), "visiteurs cumulés", Color("C8A8F0")], [str(game.all_employees().size()), "collaborateurs dans le deck", Color("8CC4FF")]]:
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", UiTokens.chip(Color(UiTokens.ENCRE, 0.06), 8, 8))
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", -2)
		tile.add_child(tv)
		var big := Composants.label(t[0], "Compteur")
		big.add_theme_font_size_override("font_size", 24)
		big.add_theme_color_override("font_color", t[2])
		tv.add_child(big)
		var cap := Composants.label(t[1], "TexteSecondaire")
		cap.add_theme_font_size_override("font_size", 12)
		tv.add_child(cap)
		tiles.add_child(tile)
	# D'où vient la réputation : une barre par source
	body.add_child(Composants.label("Votre réputation, par source", "TexteSecondaire"))
	var total_rep := maxf(1.0, game.rep_points)
	for src in [["frequentation", "Fréquentation (visiteurs)", "ressource_visiteurs", Color("8A6AD0")],
			["spectacles", "Spectacles du Kiosque", "batiment_kiosque", Color("D0A040")],
			["boutique", "Boutique", "batiment_boutique", Color("E04A8A")],
			["labels", "Labels (or)", "ressource_or", UiTokens.RESSOURCES["or"]["couleur"]],
			["prestige", "Prestige politique", "ressource_influence", UiTokens.RESSOURCES["influence"]["couleur"]],
			["legendaires", "Collaborateurs légendaires", "ui_ameliorer", UiTokens.OR]]:
		var pts := float(game.rep_sources.get(src[0], 0.0))
		if pts < 0.05:
			continue
		_fiche_barre(body, "%s · %d" % [src[1], roundi(pts)], pts / total_rep, "%d %%" % roundi(100.0 * pts / total_rep), src[3])
	body.add_child(Composants.label("Réputation jour après jour", "TexteSecondaire"))
	var chart := Control.new()
	chart.custom_minimum_size = Vector2(590, 200)
	chart.draw.connect(_draw_rep_chart.bind(chart))
	body.add_child(chart)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 14)
	body.add_child(legend)
	for i in n:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		var mk := Control.new()
		mk.custom_minimum_size = Vector2(22, 14)
		var shape := i
		var col: Color = UiTokens.JOUEURS[i % UiTokens.JOUEURS.size()]
		mk.draw.connect(func():
			mk.draw_line(Vector2(0, 7), Vector2(22, 7), col, 2.0)
			_draw_marker(mk, Vector2(11, 7), shape, col, 4.0))
		item.add_child(mk)
		var il := Composants.label(mt.names[i])
		il.add_theme_font_size_override("font_size", 13)
		item.add_child(il)
		legend.add_child(item)
	body.add_child(Composants.label("Biomes ouverts", "TexteSecondaire"))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	body.add_child(chips)
	for b in biome_noms:
		var on := biomes.has(b)
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", UiTokens.chip(Color(1, 1, 1, 0.07 if on else 0.02), 14, 4))
		var ch := HBoxContainer.new()
		ch.add_theme_constant_override("separation", 6)
		chip.add_child(ch)
		var dot := Composants.pastille(biome_colors[b] if on else Color(biome_colors[b], 0.35), UiTokens.BIOMES[b.to_lower()]["icone"], 20)
		ch.add_child(dot)
		var cl := Composants.label(biome_noms[b])
		cl.add_theme_font_size_override("font_size", 13)
		cl.add_theme_color_override("font_color", UiTokens.TEXTE if on else Color(UiTokens.TEXTE, 0.4))
		ch.add_child(cl)
		chips.add_child(chip)
	# Boutons
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	buttons.offset_top = -124
	buttons.offset_bottom = -64
	end_root.add_child(buttons)
	for spec in [["Rejouer", "BoutonPrincipal", func(): _restart("spectateur" if spectator else "jouer")],
			["Revoir la carte finale", "BoutonSecondaire", func(): end_dismissed = true],
			["Menu principal", "BoutonSecondaire", func(): _restart("menu")]]:
		var b := Composants.bouton(spec[0], spec[1])
		b.custom_minimum_size = Vector2(220, 56)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(spec[2])
		buttons.add_child(b)


func _visitors_total(i: int) -> int:
	var total := 0
	for row in mt.history:
		total += int(row[i].get("visitors", 0))
	return total


## Courbes de réputation : une ligne par joueur, avec un marqueur de forme différente (jamais la couleur seule).
func _draw_rep_chart(c: Control) -> void:
	var left := 34.0
	var top := 8.0
	var w := c.size.x - left - 10.0
	var h := c.size.y - top - 6.0
	var goal := float(mt.objective())
	var max_rep := goal
	for row in mt.history:
		for e in row:
			max_rep = maxf(max_rep, float(e["rep"]))
	for v in [0.0, goal / 2.0, goal]:
		var y: float = top + h * (1.0 - v / max_rep)
		c.draw_line(Vector2(left, y), Vector2(left + w, y), Color(1, 1, 1, 0.1 if v > 0.0 else 0.25), 1.0)
		c.draw_string(font, Vector2(0, y + 4), str(roundi(v)), HORIZONTAL_ALIGNMENT_RIGHT, left - 6, 11, UiTokens.TEXTE_SECONDAIRE)
	var days := mt.history.size()
	if days == 0:
		return
	for i in mt.players.size():
		var col: Color = UiTokens.JOUEURS[i % UiTokens.JOUEURS.size()]
		var pts := PackedVector2Array([Vector2(left, top + h)])
		for k in days:
			pts.append(Vector2(left + w * (k + 1) / days, top + h * (1.0 - float(mt.history[k][i]["rep"]) / max_rep)))
		c.draw_polyline(pts, col, 3.0 if i == game.index else 2.0, true)
		for k in range(1, pts.size()):
			_draw_marker(c, pts[k], i, col, 3.5)


func _draw_marker(ci: CanvasItem, p: Vector2, shape: int, col: Color, s: float) -> void:
	match shape % 4:
		0:
			ci.draw_circle(p, s, col)
		1:
			ci.draw_rect(Rect2(p - Vector2(s, s), Vector2(s, s) * 2.0), col)
		2:
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 1.3), p + Vector2(s * 1.2, s * 0.9), p + Vector2(-s * 1.2, s * 0.9)]), col)
		_:
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 1.4), p + Vector2(s * 1.2, 0), p + Vector2(0, s * 1.4), p + Vector2(-s * 1.2, 0)]), col)


func _restart(mode: String) -> void:
	relance = mode
	relance_difficile = args.has("difficile")
	get_tree().reload_current_scene()


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
		return "≥ %d cases, motif de %d cases%s" % [int(def["taille"]), def["motif"].size(),
			" + " + game.building_def(def["decor"])["nom"] if def.has("decor") else ""]
	var size_ok: bool = tiles.size() >= int(def["taille"])
	var ps := game.pattern_status(def, game.free_enclosure_tiles(game.enclosure_at(tiles[0])) if not tiles.is_empty() else tiles)
	var parts: Array[String] = []
	parts.append("[color=%s]%s %d / %d cases[/color]" % ["#7fc97f" if size_ok else "#f08080", "✓" if size_ok else "✗", tiles.size(), int(def["taille"])])
	if ps["found"]:
		parts.append("[color=#1F7A4A]✓ motif présent[/color]")
	elif ps["missing"] < 99:
		parts.append("[color=#B5452A]✗ motif : %d case(s) à aménager (en orange)[/color]" % ps["missing"])
	else:
		parts.append("[color=#B5452A]✗ motif : enclos trop étroit[/color]")
	return " · ".join(parts)


## Petit dessin du motif d'un animal : tuiles colorées avec le signe du terrain (couleur + motif, HANDOFF §5.2).
func _pattern_view(def: Dictionary, cell := 14.0) -> Control:
	var view := Control.new()
	var w := 0
	var h := 0
	for c in def["motif"]:
		w = maxi(w, int(c[0]) + 1)
		h = maxi(h, int(c[1]) + 1)
	var decor := str(def.get("decor", ""))
	view.custom_minimum_size = Vector2(w, h) * cell + Vector2(2, 2) + (Vector2(cell * 1.6, 0) if decor != "" else Vector2.ZERO)
	view.mouse_filter = Control.MOUSE_FILTER_PASS
	view.draw.connect(func():
		for c in def["motif"]:
			var r := Rect2(Vector2(int(c[0]), int(c[1])) * cell + Vector2(1, 1), Vector2(cell - 2, cell - 2))
			_draw_tile_motif(view, r, str(c[2]))
		if decor != "":
			# l'aménagement est un bâtiment à poser dans l'enclos, en plus du motif : « + » puis son icône sur un disque
			var x := w * cell + 2.0
			view.draw_string(font, Vector2(x, h * cell / 2.0 + cell * 0.25), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, int(cell * 0.8), UiTokens.OR)
			var cc := Vector2(x + cell * 1.0, h * cell / 2.0)
			view.draw_circle(cc, cell * 0.5, building_colors.get(decor, Color.GRAY))
			var tex := UiTokens.icone(Composants.icone_batiment(decor))
			if tex:
				view.draw_texture_rect(tex, Rect2(cc - Vector2(cell, cell) * 0.32, Vector2(cell, cell) * 0.64), false))
	view.tooltip_text = _pattern_words(def)
	return view


## Le motif en toutes lettres : nombre de cases de chaque terrain, puis l'aménagement à construire à part.
func _pattern_words(def: Dictionary) -> String:
	var count := {}
	for c in def["motif"]:
		var nm: String = terrain_noms[GameMap.TERRAINS.find(str(c[2]))]
		count[nm] = int(count.get(nm, 0)) + 1
	var parts: Array[String] = []
	for nm in count:
		parts.append("%d %s" % [count[nm], nm])
	var txt := "Motif (tourné ou retourné) : %s, dans un enclos d'au moins %d cases." % [", ".join(parts), int(def["taille"])]
	if def.has("decor"):
		txt += "\nEn plus : un %s, bâtiment à poser dans l'enclos hors du motif (onglet Zoo). La case grise du motif est un terrain Roche, pas ce bâtiment." % game.building_def(def["decor"])["nom"] \
			if def["motif"].any(func(c): return str(c[2]) == "Roche") else "\nEn plus : un %s, bâtiment à poser dans l'enclos hors du motif (onglet Zoo)." % game.building_def(def["decor"])["nom"]
	return txt


func _draw_tile_motif(ci: CanvasItem, r: Rect2, terrain: String) -> void:
	var key := terrain.to_lower()
	var col: Color = UiTokens.TUILES.get(key, Color.GRAY)
	ci.draw_rect(r, col)
	var c := r.get_center()
	var s := r.size.x
	var mark := col.darkened(0.35)
	match key:
		"prairie":
			for k in 3:
				var x := r.position.x + s * (0.25 + 0.25 * k)
				ci.draw_line(Vector2(x, c.y - s * 0.18), Vector2(x, c.y + s * 0.18), mark, 1.0)
		"foret":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.3), c + Vector2(s * 0.26, s * 0.22), c + Vector2(-s * 0.26, s * 0.22)]), Color(1, 1, 1, 0.85))
		"eau":
			for k in 2:
				var y := c.y - s * 0.12 + k * s * 0.24
				ci.draw_polyline(PackedVector2Array([Vector2(r.position.x + s * 0.18, y), Vector2(c.x - s * 0.12, y - s * 0.08),
					Vector2(c.x + s * 0.12, y + s * 0.08), Vector2(r.end.x - s * 0.18, y)]), Color(1, 1, 1, 0.8), 1.0)
		"roche":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.24), c + Vector2(s * 0.26, s * 0.2), c + Vector2(-s * 0.26, s * 0.2)]), Color(0.3, 0.28, 0.25, 0.85))
		"sable":
			for d in [Vector2(-0.2, -0.15), Vector2(0.18, -0.1), Vector2(0, 0.18), Vector2(-0.15, 0.2), Vector2(0.22, 0.2)]:
				ci.draw_circle(c + d * s, maxf(0.8, s * 0.05), mark)
		"montagne":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.32, s * 0.2), c + Vector2(-s * 0.08, -s * 0.22),
				c + Vector2(s * 0.08, 0), c + Vector2(s * 0.2, -s * 0.12), c + Vector2(s * 0.34, s * 0.2)]), Color.WHITE, 1.2)
	ci.draw_rect(r, Color(0, 0, 0, 0.45), false, 1.0)


## Contrat d'animal (capture 05, l 204) : bandeau du biome et palier, motif d'enclos, nom, chiffres clés, bouton.
func _contract_widget(def: Dictionary, button_text: String, err: String, cb: Callable) -> Control:
	var biome: String = def["biome"]
	var bcol: Color = biome_colors[biome]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(204, 0)
	panel.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 10, 2, 0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	panel.add_child(v)
	# Bandeau : icône et nom du biome, palier en losanges
	var head := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bcol.darkened(0.2)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	head.add_theme_stylebox_override("panel", sb)
	v.add_child(head)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	head.add_child(top)
	var bkey := biome.to_lower()
	if UiTokens.BIOMES.has(bkey):
		top.add_child(Composants.icone_rect(UiTokens.BIOMES[bkey]["icone"], Vector2(18, 18)))
	var bn := Composants.label(biome_noms[biome].to_upper() + ("  · PRÉDATEUR" if def.get("special", "") == "predateur" else ""))
	bn.add_theme_font_override("font", UiTokens.police_corps(800))
	bn.add_theme_font_size_override("font_size", 12)
	bn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(bn)
	var tier := int(str(def["palier"]).substr(1))
	var tl := Composants.label("◆".repeat(tier) + "◇".repeat(maxi(0, 3 - tier)))
	tl.add_theme_font_size_override("font_size", 12)
	tl.tooltip_text = str(game.data["animals"]["paliers"][def["palier"]]["nom"])
	top.add_child(tl)
	# « Illustration » : le motif d'enclos à reproduire, sur fond du biome
	var art := PanelContainer.new()
	var asb := StyleBoxFlat.new()
	asb.bg_color = bcol.darkened(0.55)
	asb.content_margin_top = 8
	asb.content_margin_bottom = 8
	art.add_theme_stylebox_override("panel", asb)
	art.custom_minimum_size.y = 84
	v.add_child(art)
	var arow := HBoxContainer.new()
	arow.alignment = BoxContainer.ALIGNMENT_CENTER
	arow.add_theme_constant_override("separation", 6)
	art.add_child(arow)
	var illus := _animal_picture(def["id"], Vector2(104, 78))
	if illus:
		arow.add_child(illus)
	var cc := CenterContainer.new()
	arow.add_child(cc)
	cc.add_child(_pattern_view(def, 16.0 if illus else 18.0))
	# Corps
	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_left", 10)
	body.add_theme_constant_override("margin_right", 10)
	body.add_theme_constant_override("margin_top", 6)
	body.add_theme_constant_override("margin_bottom", 10)
	v.add_child(body)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	body.add_child(inner)
	var name_row := HBoxContainer.new()
	inner.add_child(name_row)
	var n := Composants.label(def["nom"])
	n.add_theme_font_override("font", UiTokens.police_titre())
	n.add_theme_font_size_override("font_size", 19)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	n.clip_text = true
	name_row.add_child(n)
	var cases := Composants.label("%d cases" % int(def["taille"]), "TexteSecondaire")
	cases.add_theme_font_size_override("font_size", 12)
	cases.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(cases)
	var origin := Composants.label("%s · %s" % [game.continent_name(def.get("continent", "")), game.type_name(def.get("type", ""))], "TexteSecondaire")
	origin.add_theme_font_size_override("font_size", 12)
	inner.add_child(origin)
	var same_continent := game.animals.filter(func(a): return a.def.get("continent", "") == def.get("continent", "")).size()
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 4)
	inner.add_child(stats)
	for st in [["+%d" % int(def["reputation"]), "attractivité", Color("C8A8F0")], [str(game.food_cost(def)), "nourriture/j", UiTokens.POSITIF],
			["+5 %" if same_continent > 0 else "—", "affinité", UiTokens.SELECTION if same_continent > 0 else UiTokens.TEXTE_SECONDAIRE]]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", -3)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var big := Composants.label(st[0], "Compteur")
		big.add_theme_font_size_override("font_size", 17)
		big.add_theme_color_override("font_color", st[2])
		big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(big)
		var cap := Composants.label(st[1], "TexteSecondaire")
		cap.add_theme_font_size_override("font_size", 11)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(cap)
		stats.add_child(col)
	var gold_missing := game.contract_gold_missing(def)
	if gold_missing > 0:
		var gm := Composants.label("Or manquant (%d) acheté : %d argent au total" % [gold_missing, int(game.contract_payment(def)["argent"])])
		gm.add_theme_font_size_override("font_size", 11)
		gm.add_theme_color_override("font_color", UiTokens.SELECTION)
		gm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gm.custom_minimum_size.x = 180
		inner.add_child(gm)
	if def.has("effet_texte"):
		var eff := Composants.label(str(def["effet_texte"]))
		eff.add_theme_font_size_override("font_size", 12)
		eff.add_theme_color_override("font_color", UiTokens.SARCELLE)
		eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		eff.custom_minimum_size.x = 180
		inner.add_child(eff)
	var btn := Composants.bouton(button_text, "BoutonPrincipal")
	btn.disabled = err != ""
	btn.tooltip_text = err
	btn.custom_minimum_size = Vector2(0, 34)
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if cb.is_valid():
		btn.pressed.connect(cb)
	inner.add_child(btn)
	panel.tooltip_text = "%s (%s, palier %s)\n%s · %s\nEnclos : %s\nAttractivité %d · nourriture %d / jour\nCoût : %s%s" % [
		def["nom"], biome_noms[biome], def["palier"], game.continent_name(def.get("continent", "")), game.type_name(def.get("type", "")),
		_requirements_text(def), int(def["reputation"]), game.food_cost(def), game.cost_text(game.contract_cost(def)),
		"\nAffinité : %d animal(aux) du même continent dans votre zoo (+5 %% de réputation)" % same_continent if same_continent > 0 else ""]
	return panel


func _rebuild_contracts() -> void:
	for c in contracts_box.get_children():
		c.queue_free()
	contracts_box.visible = not game.contracts.is_empty() or not game.pending_installs.is_empty()
	if not contracts_box.visible:
		return
	if not game.pending_installs.is_empty():
		var pt := Composants.label("ENCLOS EN CHANTIER", "TitrePanneau")
		pt.add_theme_font_size_override("font_size", 14)
		contracts_box.add_child(pt)
		for r in game.pending_installs:
			var row := HBoxContainer.new()
			var l := Composants.label("%s : arrive quand les clôtures sont finies" % r["def"]["nom"], "TexteSecondaire")
			l.add_theme_font_size_override("font_size", 12)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
			var cb := Composants.bouton("Annuler", "BoutonSecondaire")
			cb.add_theme_font_size_override("font_size", 12)
			cb.tooltip_text = "Annule la réservation : le contrat revient dans les contrats à installer (les clôtures restent)"
			cb.pressed.connect(_cmd.bind("cancel_pending", [r]))
			row.add_child(cb)
			contracts_box.add_child(row)
	if game.contracts.is_empty():
		return
	var title := Composants.label("CONTRATS À INSTALLER", "TitrePanneau")
	title.add_theme_font_size_override("font_size", 14)
	contracts_box.add_child(title)
	for def in game.contracts:
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 13)
		b.icon = UiTokens.icone("biome_" + {"Foret": "foret", "Desert": "desert"}.get(def["biome"], str(def["biome"]).to_lower()))
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 22)
		b.add_theme_color_override("icon_normal_color", biome_colors[def["biome"]])
		b.text = "%s (%s)\nInstaller dans un enclos" % [def["nom"], biome_noms[def["biome"]]]
		b.tooltip_text = "Cliquez pour voir où l'installer : un enclos clôturé (même partagé) ou le parc libre de l'enceinte.\n" + _requirements_text(def).replace("[b]", "").replace("[/b]", "")
		b.button_pressed = build_choice.get("def") == def
		b.pressed.connect(func():
			if build_choice.get("def") == def:
				_set_build({})
			else:
				_set_build({"kind": "animal", "def": def})
				selected.clear())
		contracts_box.add_child(b)
