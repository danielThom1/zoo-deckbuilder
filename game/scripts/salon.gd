class_name Salon
extends Control
## Salon multijoueur : héberger ou rejoindre une partie, voir les joueurs, lancer.

signal retour

var reseau: Reseau
var champ_pseudo: LineEdit
var champ_adresse: LineEdit
var liste: VBoxContainer
var statut: Label
var choix: Control
var attente: Control
var bouton_lancer: Button
var case_ia: CheckBox
var case_difficile: CheckBox


func _init(r: Reseau) -> void:
	reseau = r
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	theme = UiTokens.build_theme()
	var fond := ColorRect.new()
	fond.color = UiTokens.MARINE
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var carte := PanelContainer.new()
	carte.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PAPIER, UiTokens.ENCRE, 14, 3, 22))
	carte.custom_minimum_size = Vector2(620, 0)
	centre.add_child(carte)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	carte.add_child(v)
	var titre := Composants.label("MULTIJOUEUR", "TitreEcran")
	titre.add_theme_font_size_override("font_size", 34)
	titre.add_theme_color_override("font_color", UiTokens.SARCELLE)
	v.add_child(titre)
	v.add_child(_texte("Votre nom"))
	champ_pseudo = LineEdit.new()
	champ_pseudo.text = "Directeur"
	champ_pseudo.max_length = 16
	v.add_child(champ_pseudo)

	choix = VBoxContainer.new()
	choix.add_theme_constant_override("separation", 10)
	v.add_child(choix)
	var heberger := Composants.bouton("Héberger une partie", "BoutonPrincipal")
	heberger.custom_minimum_size.y = 42
	heberger.pressed.connect(_heberger)
	choix.add_child(heberger)
	choix.add_child(_texte("Ouvrez le port %d (UDP) sur votre box et donnez votre adresse IP publique à vos amis. Sans accès à la box : installez tous un VPN gratuit comme Tailscale et utilisez son adresse." % Reseau.PORT, true))
	choix.add_child(_texte("Ou rejoindre : adresse de l'hôte"))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 8)
	choix.add_child(ligne)
	champ_adresse = LineEdit.new()
	champ_adresse.placeholder_text = "ex. 82.65.10.21"
	champ_adresse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(champ_adresse)
	var rejoindre := Composants.bouton("Rejoindre", "BoutonPrincipal")
	rejoindre.pressed.connect(_rejoindre)
	ligne.add_child(rejoindre)

	attente = VBoxContainer.new()
	attente.add_theme_constant_override("separation", 10)
	attente.visible = false
	v.add_child(attente)
	attente.add_child(_texte("Joueurs"))
	liste = VBoxContainer.new()
	attente.add_child(liste)
	case_ia = CheckBox.new()
	case_ia.text = "Compléter jusqu'à 4 joueurs avec des IA"
	case_ia.button_pressed = true
	attente.add_child(case_ia)
	case_difficile = CheckBox.new()
	case_difficile.text = "IA difficiles"
	attente.add_child(case_difficile)
	bouton_lancer = Composants.bouton("Lancer la partie", "BoutonPrincipal")
	bouton_lancer.custom_minimum_size.y = 42
	bouton_lancer.pressed.connect(func(): reseau.lancer(case_ia.button_pressed, case_difficile.button_pressed))
	attente.add_child(bouton_lancer)

	statut = _texte("", true)
	statut.add_theme_color_override("font_color", UiTokens.NEGATIF)
	v.add_child(statut)
	var retour_b := Composants.bouton("Retour", "BoutonSecondaire")
	retour_b.pressed.connect(func():
		reseau.quitter()
		retour.emit())
	v.add_child(retour_b)
	reseau.liste_changee.connect(_actualiser)
	reseau.coupure.connect(func(t):
		statut.text = t
		reseau.quitter()
		choix.visible = true
		attente.visible = false)


func _texte(t: String, long := false) -> Label:
	var l := Composants.label(t, "TexteSecondaire")
	l.add_theme_font_size_override("font_size", 14)
	if long:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 570
	return l


func _heberger() -> void:
	reseau.pseudo = champ_pseudo.text.strip_edges()
	var err := reseau.heberger()
	statut.text = err
	if err != "":
		return
	choix.visible = false
	attente.visible = true
	var adresses: Array = Array(IP.get_local_addresses()).filter(func(a): return "." in a and not a.begins_with("127.") and not a.begins_with("169.254"))
	statut.add_theme_color_override("font_color", UiTokens.TEXTE_SECONDAIRE)
	statut.text = "En attente de joueurs (port %d). Sur votre réseau local : %s" % [Reseau.PORT, ", ".join(adresses)]


func _rejoindre() -> void:
	if champ_adresse.text.strip_edges() == "":
		statut.text = "Indiquez l'adresse de l'hôte."
		return
	reseau.pseudo = champ_pseudo.text.strip_edges()
	var err := reseau.rejoindre(champ_adresse.text.strip_edges())
	statut.add_theme_color_override("font_color", UiTokens.TEXTE_SECONDAIRE if err == "" else UiTokens.NEGATIF)
	statut.text = err if err != "" else "Connexion…"
	if err == "":
		choix.visible = false
		attente.visible = true
		case_ia.visible = false
		case_difficile.visible = false
		bouton_lancer.visible = false


func _actualiser() -> void:
	for c in liste.get_children():
		c.queue_free()
	for j in reseau.joueurs:
		var l := Composants.label(("★ " if j["id"] == 1 else "• ") + str(j["pseudo"]))
		l.add_theme_font_size_override("font_size", 17)
		liste.add_child(l)
	if not reseau.est_hote:
		statut.text = "Connecté. L'hôte lancera la partie."
	bouton_lancer.disabled = reseau.joueurs.size() < 2
