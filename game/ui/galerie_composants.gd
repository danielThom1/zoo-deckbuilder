extends Control
## Galerie « Le Comité » : les briques réutilisables et leurs états, à comparer à docs/handoff_comite/maquettes/91_briques.png.
## Capture de contrôle :  <godot> --path game res://ui/galerie_composants.tscn -- --capture=C:/chemin/galerie.png


func _ready() -> void:
	theme = UiTokens.build_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fond := ColorRect.new()
	fond.color = UiTokens.PAPIER
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right"]:
		marge.add_theme_constant_override("margin_" + c, 48)
	marge.add_theme_constant_override("margin_top", 28)
	add_child(marge)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	marge.add_child(v)
	var titre := Composants.label("Briques réutilisables · états")
	titre.add_theme_font_override("font", UiTokens.police_titre())
	titre.add_theme_font_size_override("font_size", 38)
	v.add_child(titre)
	_section_badges(v)
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 36)
	v.add_child(bas)
	_section_boutons(bas)
	_section_jetons(bas)
	var bas2 := HBoxContainer.new()
	bas2.add_theme_constant_override("separation", 36)
	v.add_child(bas2)
	_section_infobulle(bas2)
	_section_bulles(bas2)
	_section_panneau(bas2)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capture"):
			await get_tree().create_timer(0.3).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(a.get_slice("=", 1) if "=" in a else "capture_galerie.png")
			get_tree().quit()


func _entete(parent: Control, t: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := Composants.label(t)
	l.add_theme_font_override("font", UiTokens.police_titre())
	l.add_theme_font_size_override("font_size", 20)
	v.add_child(l)
	var filet := ColorRect.new()
	filet.color = UiTokens.ENCRE
	filet.custom_minimum_size.y = 3
	v.add_child(filet)
	parent.add_child(v)
	return v


func _legende(parent: Control, enfant: Control, t: String, decale := 0) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(enfant)
	if decale > 0:
		var esp := Control.new()
		esp.custom_minimum_size.y = decale
		v.add_child(esp)
	var l := Composants.label(t)
	l.add_theme_font_override("font", UiTokens.police_mono(500))
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	parent.add_child(v)


func _ouvrier(nom: String, metier: String, portrait: String, categorie: String, niveau := 1) -> Dictionary:
	return {"nom": nom, "metier": metier, "metier_icone": "metier_macon", "portrait": portrait, "categorie": categorie, "niveau": niveau, "salaire": niveau,
		"qualites": ["qualite_costaud"], "defauts": ["defaut_lent"], "traits_noms": []}


func _section_badges(parent: Control) -> void:
	var s := _entete(parent, "BADGE DE COLLABORATEUR (MAIN)")
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 14)
	s.add_child(r)
	var ponctuel := Callable()
	_legende(r, Composants.badge_ouvrier(_ouvrier("ADAM", "Maçon", "adam", "peu_qualifie"), "normale", [], ["Salaire 1", UiTokens.ENCRE]), "normal", 44)
	_legende(r, Composants.badge_ouvrier(_ouvrier("BASILE", "Manœuvre", "basile", "peu_qualifie", 2), "selectionnee", [["Mobiliser 2", "BoutonPrincipal", false, ponctuel], ["+4", "BoutonSecondaire", false, ponctuel]], ["● Sélectionné", UiTokens.SARCELLE_FONCE]), "sélectionné", 44)
	_legende(r, Composants.badge_ouvrier(_ouvrier("BASTIEN", "Soigneur", "bastien", "qualifie", 4), "non_abordable", [], ["✕ Manque 2 argent", UiTokens.ENCRE]), "salaire trop élevé", 44)
	_legende(r, Composants.badge_ouvrier(_ouvrier("NADIA", "Vendeuse de souvenirs", "nadia", "cadre", 3), "deployee", [], ["● Sur le terrain · Voir", UiTokens.SARCELLE_FONCE]), "sur le terrain", 44)
	_legende(r, Composants.badge_ouvrier(_ouvrier("AÏCHA", "Lobbyiste", "aicha", "cadre", 3), "hors_carte", [], ["⇢ Hors carte · Rappeler", UiTokens.ENCRE]), "hors carte", 44)
	_legende(r, Composants.badge_ouvrier(_ouvrier("AÏCHA", "Lobbyiste", "aicha", "cadre", 3), "normale", [], ["◆ Peut jouer", UiTokens.SARCELLE_FONCE]), "cadre jouable", 44)
	var carte := GameState.Card.new()
	carte.action = {"id": "heures_sup", "nom": "Heures sup", "texte": "Un collaborateur travaille plus vite jusqu'au soir."}
	_legende(r, Composants.badge_action(carte, "Jouer", false, ponctuel), "carte d'action", 44)


func _section_boutons(parent: Control) -> void:
	var s := _entete(parent, "BOUTONS")
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 8)
	s.add_child(g)
	for e in [["Signer · 12", "BoutonPrincipal", "principal"], ["Voir mon zoo", "BoutonSecondaire", "secondaire"], ["LEVER LA SÉANCE", "BoutonSeance", "fin de phase"]]:
		var b := Composants.bouton(e[0], e[1])
		b.custom_minimum_size = Vector2(170, 42)
		_legende(g, b, e[2])
	var i := Composants.bouton_indisponible("Manque 2 or", "Raison écrite")
	i.custom_minimum_size = Vector2(170, 42)
	_legende(g, i, "indisponible + raison")


func _section_jetons(parent: Control) -> void:
	var s := _entete(parent, "JETONS DE RESSOURCE")
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 12)
	s.add_child(r)
	for e in [["icone_pieces", "Argent", "57", UiTokens.ENCRE, "+14"], ["icone_pierre", "Pierre", "3", UiTokens.ENCRE, "−8"], ["icone_or", "Or", "4", UiTokens.OR_TEXTE, ""]]:
		var j := Composants.jeton_dock(e[0], e[1], e[3])
		j["valeur"].text = e[2]
		j["delta"].text = e[4]
		r.add_child(j["racine"])


func _section_infobulle(parent: Control) -> void:
	var s := _entete(parent, "INFOBULLE")
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.ENCRE, 8, 0, 12, false))
	p.custom_minimum_size.x = 320
	var v := VBoxContainer.new()
	p.add_child(v)
	var t := Composants.label("CABINET DE RECRUTEMENT")
	t.add_theme_font_override("font", UiTokens.police_titre())
	t.add_theme_color_override("font_color", UiTokens.SELECTION)
	v.add_child(t)
	v.add_child(Composants.paragraphe("Permet de remplacer une carte de la rangée « Collaborateurs » chaque nuit.", 13, UiTokens.PAPIER))
	s.add_child(p)


func _section_bulles(parent: Control) -> void:
	var s := _entete(parent, "BULLES D'HUBERT")
	for e in [["moqueur", "Petite bulle : remarque, ne bloque rien."], ["furieux", "Événement du jour : grève des poubelles, propreté −20 %."]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.add_child(Composants.image_logo(load("res://assets/bd/hubert/%s.png" % e[0]), Vector2(56, 56)))
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 14, 2, 10, false))
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p.add_child(Composants.label(e[1]))
		h.add_child(p)
		s.add_child(h)


func _section_panneau(parent: Control) -> void:
	var s := _entete(parent, "PANNEAU")
	for c in [UiTokens.SARCELLE, UiTokens.ORANGE, UiTokens.ENCRE]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 0, true))
		p.add_child(Composants.entete_comite("En-tête de panneau", "2 / 4", c)["racine"])
		s.add_child(p)
