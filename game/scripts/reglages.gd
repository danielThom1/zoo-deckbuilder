class_name Reglages
extends Control
## Réglages du joueur (résolution, plein écran, volumes), gardés dans user://reglages.cfg. Fenêtre ouvrable du menu et en jeu.

const FICHIER := "user://reglages.cfg"
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1024, 768), Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1280, 1024), Vector2i(1366, 768),
	Vector2i(1440, 900), Vector2i(1536, 864), Vector2i(1600, 900), Vector2i(1680, 1050), Vector2i(1920, 1080), Vector2i(1920, 1200),
	Vector2i(2560, 1080), Vector2i(2560, 1440), Vector2i(2560, 1600), Vector2i(3440, 1440), Vector2i(3840, 2160)]


## Les résolutions proposées : la liste, plus celle de l'écran s'il n'y figure pas, sans dépasser l'écran.
static func resolutions() -> Array[Vector2i]:
	var ecran := DisplayServer.screen_get_size()
	var out: Array[Vector2i] = []
	for r in RESOLUTIONS:
		if ecran.x <= 0 or (r.x <= ecran.x and r.y <= ecran.y):
			out.append(r)
	if ecran.x > 0 and not out.has(ecran):
		out.append(ecran)
	out.sort_custom(func(a, b): return a.x * a.y < b.x * b.y)
	return out

static var valeurs := {"musique": 0.6, "effets": 0.8, "largeur": 1600, "hauteur": 900, "plein_ecran": false}
static var _charge := false


static func charger() -> void:
	if _charge:
		return
	_charge = true
	var cfg := ConfigFile.new()
	if cfg.load(FICHIER) != OK:
		return
	for k in valeurs:
		valeurs[k] = cfg.get_value("reglages", k, valeurs[k])


static func sauver() -> void:
	var cfg := ConfigFile.new()
	for k in valeurs:
		cfg.set_value("reglages", k, valeurs[k])
	cfg.save(FICHIER)


static func appliquer_volumes() -> void:
	charger()
	for b in [["Musique", "musique"], ["Effets", "effets"]]:
		var i := AudioServer.get_bus_index(b[0])
		if i >= 0:
			var v := float(valeurs[b[1]])
			AudioServer.set_bus_mute(i, v <= 0.001)
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


static func appliquer_fenetre() -> void:
	charger()
	if DisplayServer.get_name() == "headless":
		return
	if bool(valeurs["plein_ecran"]):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var taille := Vector2i(int(valeurs["largeur"]), int(valeurs["hauteur"]))
	DisplayServer.window_set_size(taille)
	var ecran := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	DisplayServer.window_set_position(ecran.position + (ecran.size - taille) / 2)


func _ready() -> void:
	charger()
	theme = UiTokens.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var f := Composants.fenetre(Vector2(560, 0), "Préférences", "Réglages", queue_free)
	add_child(f["racine"])
	var v: VBoxContainer = f["corps"]

	_curseur(v, "Musique", "musique")
	_curseur(v, "Bruitages", "effets")

	v.add_child(_titre("Résolution"))
	var liste := OptionButton.new()
	var actuelle := Vector2i(int(valeurs["largeur"]), int(valeurs["hauteur"]))
	var choix := resolutions()
	for i in choix.size():
		liste.add_item("%d × %d%s" % [choix[i].x, choix[i].y, " (écran)" if choix[i] == DisplayServer.screen_get_size() else ""])
		if choix[i] == actuelle:
			liste.select(i)
	liste.item_selected.connect(func(i: int):
		valeurs["largeur"] = choix[i].x
		valeurs["hauteur"] = choix[i].y
		sauver()
		appliquer_fenetre())
	v.add_child(liste)

	var plein := CheckBox.new()
	plein.text = "Plein écran"
	plein.button_pressed = bool(valeurs["plein_ecran"])
	plein.toggled.connect(func(oui: bool):
		valeurs["plein_ecran"] = oui
		liste.disabled = oui
		sauver()
		appliquer_fenetre())
	liste.disabled = plein.button_pressed
	v.add_child(plein)

	f["pied_boite"].visible = true
	# Les conseils d'Hubert ne s'affichent qu'une fois : ce bouton les fait tous revenir.
	var conseils := Composants.bouton("Réinitialiser les conseils", "BoutonSecondaire")
	conseils.custom_minimum_size.y = 40
	conseils.tooltip_text = "Les conseils d'Hubert réapparaîtront, chacun à la première occasion."
	conseils.pressed.connect(func():
		Conseils.reinitialiser()
		conseils.text = "Conseils réinitialisés ✓"
		conseils.disabled = true)
	f["pied"].add_child(conseils)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f["pied"].add_child(esp)
	var fermer := Composants.bouton("Fermer", "BoutonPrincipal")
	fermer.custom_minimum_size = Vector2(140, 40)
	fermer.pressed.connect(queue_free)
	f["pied"].add_child(fermer)


func _titre(t: String) -> Label:
	return Composants.titre_section(t)


func _curseur(parent: Control, nom: String, cle: String) -> void:
	parent.add_child(_titre(nom))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	parent.add_child(ligne)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(valeurs[cle])
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ligne.add_child(s)
	var pct := Composants.label("%d %%" % roundi(s.value * 100.0))
	pct.add_theme_font_override("font", UiTokens.police_mono(600))
	pct.custom_minimum_size.x = 56
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ligne.add_child(pct)
	s.value_changed.connect(func(val: float):
		valeurs[cle] = val
		pct.text = "%d %%" % roundi(val * 100.0)
		appliquer_volumes()
		sauver())
	if cle == "effets":
		s.drag_ended.connect(func(_c: bool): Sons.effet("valide"))
