class_name Salon
extends Control
## Salon multijoueur : héberger ou rejoindre une partie, voir les joueurs, lancer.

signal retour

var reseau: Reseau
var champ_pseudo: LineEdit
var champ_adresse: LineEdit
var champ_port: LineEdit
var _adresses_texte := ""
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
	var fond := TextureRect.new()
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.texture = load("res://assets/bd/menu_fond.jpg")
	add_child(fond)
	var quitter := func():
		reseau.quitter()
		retour.emit()
	var f := Composants.fenetre(Vector2(640, 0), "Plusieurs filiales, une seule vallée", "Multijoueur", quitter)
	add_child(f["racine"])
	var v: VBoxContainer = f["corps"]
	v.add_child(_texte("Votre nom"))
	champ_pseudo = LineEdit.new()
	champ_pseudo.text = "Directeur"
	champ_pseudo.max_length = 16
	v.add_child(champ_pseudo)

	choix = VBoxContainer.new()
	choix.add_theme_constant_override("separation", 10)
	v.add_child(choix)
	var ligne_h := HBoxContainer.new()
	ligne_h.add_theme_constant_override("separation", 8)
	choix.add_child(ligne_h)
	var heberger := Composants.bouton("Héberger une partie", "BoutonPrincipal")
	heberger.custom_minimum_size.y = 42
	heberger.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heberger.pressed.connect(_heberger)
	ligne_h.add_child(heberger)
	var l_port := Composants.label("Port UDP")
	l_port.add_theme_font_override("font", UiTokens.police_corps(700))
	ligne_h.add_child(l_port)
	champ_port = LineEdit.new()
	champ_port.text = str(Reseau.PORT)
	champ_port.max_length = 5
	champ_port.custom_minimum_size.x = 90
	ligne_h.add_child(champ_port)
	choix.add_child(_texte("Le jeu essaie d'ouvrir le port tout seul sur votre box (UPnP). Sinon, redirigez ce port UDP vers ce PC dans la box ; si la box impose une plage de ports (IP partagée), redirigez un port de la plage vers ce port-ci et donnez « adresse:port » à vos amis. Autre solution : un réseau privé comme Tailscale.", true))
	choix.add_child(_texte("Ou rejoindre : adresse de l'hôte"))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 8)
	choix.add_child(ligne)
	champ_adresse = LineEdit.new()
	champ_adresse.placeholder_text = "ex. 82.65.10.21 ou 82.65.10.21:27777"
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
	f["pied_boite"].visible = true
	var retour_b := Composants.bouton("‹ Retour au menu", "BoutonSecondaire")
	retour_b.custom_minimum_size.y = 40
	retour_b.pressed.connect(quitter)
	f["pied"].add_child(retour_b)
	reseau.liste_changee.connect(_actualiser)
	reseau.coupure.connect(func(t):
		statut.text = t
		reseau.quitter()
		choix.visible = true
		attente.visible = false)


func _texte(t: String, long := false) -> Label:
	if not long:
		return Composants.titre_section(t)
	var l := Composants.paragraphe(t, 13, UiTokens.TEXTE_2)
	l.custom_minimum_size.x = 590
	return l


func _heberger() -> void:
	reseau.pseudo = champ_pseudo.text.strip_edges()
	var p := int(champ_port.text) if champ_port.text.strip_edges().is_valid_int() else 0
	if p < 1024 or p > 65535:
		statut.text = "Port invalide : choisissez un nombre entre 1024 et 65535."
		return
	var err := reseau.heberger(p)
	statut.text = err
	if err != "":
		return
	choix.visible = false
	attente.visible = true
	var adresses: Array = Array(IP.get_local_addresses()).filter(func(a): return "." in a and not a.begins_with("127.") and not a.begins_with("169.254"))
	var ipv6: Array = Array(IP.get_local_addresses()).filter(func(a): return ":" in a and (a.begins_with("2") or a.begins_with("3")))
	statut.add_theme_color_override("font_color", UiTokens.TEXTE_SECONDAIRE)
	_adresses_texte = "En attente de joueurs (port %d).
Réseau local ou Tailscale : %s" % [p, ", ".join(adresses)]
	if not ipv6.is_empty():
		_adresses_texte += "
IPv6 (si vos amis l'ont aussi) : [%s]:%d" % [ipv6[0], p]
	statut.text = _adresses_texte + "
Ouverture du port sur la box…"
	reseau.ouvrir_box(func(publique: String, erreur: String):
		if not is_instance_valid(statut):
			return
		if erreur == "":
			statut.text = _adresses_texte + "
Port ouvert sur la box. Adresse à donner par Internet : %s%s" % [publique, "" if p == Reseau.PORT else ":%d" % p]
		else:
			statut.text = _adresses_texte + "
Ouverture automatique impossible (%s) : redirigez le port à la main ou utilisez Tailscale." % erreur)


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
		var ligne := PanelContainer.new()
		ligne.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 8, 2, 8, false))
		var l := Composants.label(str(j["pseudo"]) + ("  ·  hôte" if j["id"] == 1 else ""))
		l.add_theme_font_override("font", UiTokens.police_corps(700))
		l.add_theme_font_size_override("font_size", 15)
		ligne.add_child(l)
		liste.add_child(ligne)
	if not reseau.est_hote:
		statut.text = "Connecté. L'hôte lancera la partie."
	bouton_lancer.disabled = reseau.joueurs.size() < 2
