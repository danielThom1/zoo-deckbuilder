class_name DraftComite
extends FenetreComite
## Le draft « Le Comité » (handoff §3) : une fenêtre, les candidats en grands badges, l'ordre de passage en tour de parole.

var titre: Label
var sur: Label
var tour: HBoxContainer
var rangee: HBoxContainer
var recap: GridContainer
var fenetre: PanelContainer
var apercu: PanelContainer  # « Voir la carte » : objectifs en encart, la carte libre derrière


func _init(principal) -> void:
	super(principal)
	color = Color(UiTokens.ENCRE, 0.55)
	offset_top = UiTokens.H_BANDEAU  # la barre du haut reste cliquable : menu (abandonner), réglages, aide


func _ready() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.FOND_FENETRE, 12, 2, 2, true))
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -640
	p.offset_right = 640
	p.offset_top = -420
	p.offset_bottom = 420
	add_child(p)
	fenetre = p
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var tete := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = UiTokens.PAPIER
	st.corner_radius_top_left = 10
	st.corner_radius_top_right = 10
	st.border_color = UiTokens.ENCRE
	st.border_width_bottom = 2
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	tete.add_theme_stylebox_override("panel", st)
	v.add_child(tete)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	tete.add_child(h)
	var tb := VBoxContainer.new()
	tb.add_theme_constant_override("separation", 0)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sur = _mono("", 12, 500, UiTokens.TEXTE_2)
	tb.add_child(sur)
	titre = _cond("", 30)
	tb.add_child(titre)
	h.add_child(tb)
	tour = HBoxContainer.new()
	tour.add_theme_constant_override("separation", 6)
	tour.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tour)
	var voir := Composants.bouton("Carte et objectifs", "BoutonSecondaire")
	voir.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	voir.tooltip_text = "Regarder la carte et les objectifs des actionnaires avant de choisir"
	voir.pressed.connect(_voir_carte.bind(true))
	h.add_child(voir)
	var marge := MarginContainer.new()
	for c in [["left", 18], ["right", 18], ["top", 14], ["bottom", 14]]:
		marge.add_theme_constant_override("margin_" + c[0], c[1])
	marge.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(marge)
	var corps := VBoxContainer.new()
	corps.add_theme_constant_override("separation", 12)
	marge.add_child(corps)
	rangee = HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 14)
	rangee.alignment = BoxContainer.ALIGNMENT_CENTER
	rangee.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_child(rangee)
	corps.add_child(_cond("DÉJÀ CHOISIS", 13, UiTokens.TEXTE_2))
	recap = GridContainer.new()
	recap.columns = 2
	recap.add_theme_constant_override("h_separation", 24)
	recap.add_theme_constant_override("v_separation", 4)
	corps.add_child(recap)


## La carte (vraie, déplaçable et zoomable) et les objectifs des actionnaires, le temps de préparer son plan.
func _voir_carte(oui: bool) -> void:
	fenetre.visible = not oui
	color = Color(UiTokens.ENCRE, 0.0 if oui else 0.55)
	mouse_filter = Control.MOUSE_FILTER_IGNORE if oui else Control.MOUSE_FILTER_STOP
	if apercu:
		apercu.queue_free()
		apercu = null
	if not oui:
		return
	apercu = PanelContainer.new()
	apercu.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.FOND_FENETRE, 12, 2, 2, true))
	apercu.position = Vector2(16, 16)
	apercu.custom_minimum_size.x = 380
	add_child(apercu)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var marge := MarginContainer.new()
	for c in [["left", 14], ["right", 14], ["top", 12], ["bottom", 12]]:
		marge.add_theme_constant_override("margin_" + c[0], c[1])
	marge.add_child(v)
	apercu.add_child(marge)
	v.add_child(_mono("AVANT LE DRAFT · LA CARTE EST LIBRE", 12, 500, UiTokens.TEXTE_2))
	v.add_child(_cond("Objectifs des actionnaires", 22))
	var pts := int(m.game.data["buildings"]["objectifs"]["reputation"])
	for o in m.mt.objectifs:
		var l := _corps("◆ %s · +%d réputation" % [str(o["texte"]), pts], 14, 600)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	var aide := _corps("Molette : zoom. Clic droit maintenu, molette enfoncée ou ZQSD : déplacer la vue. Votre camp est au bout de la route d'accès.", 12, 600, UiTokens.TEXTE_2)
	aide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(aide)
	var retour := Composants.bouton("Revenir au draft", "BoutonPrincipal")
	retour.pressed.connect(_voir_carte.bind(false))
	v.add_child(retour)


func rafraichir() -> void:
	if not is_node_ready():
		return
	var mt: Match = m.mt
	var mon_tour: bool = not mt.is_ai(mt.current_drafter())
	sur.text = "DRAFT · TOUR %d / %d · %d CARTES, UNE CHACUN, LA DERNIÈRE EST DÉFAUSSÉE" % [mt.draft_round() + 1, mt.draft_rounds(), mt.draft_round_size()]
	titre.text = "À vous de choisir" if mon_tour else "%s choisit…" % _nom_court(mt.current_drafter())
	_clear(tour)
	var ordre := mt.draft_round_order()
	var pos := mt.draft_turn % mt.players.size()
	for k in ordre.size():
		var i: int = ordre[k]
		var pc := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiTokens.SELECTION if k == pos else Color(0, 0, 0, 0)
		sb.border_color = UiTokens.ENCRE if k == pos else UiTokens.FILET
		sb.set_border_width_all(2 if k == pos else 1)
		sb.set_corner_radius_all(8)
		sb.set_content_margin_all(4)
		sb.content_margin_right = 8
		pc.add_theme_stylebox_override("panel", sb)
		var ph := HBoxContainer.new()
		ph.add_theme_constant_override("separation", 6)
		pc.add_child(ph)
		ph.add_child(_logo(i, 22))
		ph.add_child(_corps("%s%s" % [_nom_court(i), " ✓" if k < pos else ""], 13, 800 if k == pos else 600, UiTokens.ENCRE if k >= pos else UiTokens.ENCRE_DOUX))
		tour.add_child(pc)
	_clear(rangee)
	# Les cartes se partagent la largeur de la fenêtre (1280 − marges) : à 5 cartes, 290 px chacune débordaient à droite.
	var n: int = maxi(1, mt.draft_pool.size())
	var largeur: float = minf(290.0, (1280.0 - 36.0 - 14.0 * (n - 1)) / n)
	for card in mt.draft_pool:
		var b := _grand_badge(card, false, 140)
		b.custom_minimum_size.x = largeur
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rangee.add_child(b)
	_clear(recap)
	for i in mt.players.size():
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		h.add_child(_logo(i, 20))
		var noms: Array = mt.drafted[i].map(func(c): return "%s (%s)" % [c.nom, m.game.job_name(c)])
		var l := _corps("%s · %d : %s" % [_nom_court(i), noms.size(), ", ".join(noms) if not noms.is_empty() else "—"], 12, 600)
		l.custom_minimum_size.x = 590
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.tooltip_text = ", ".join(noms)
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(l)
		recap.add_child(h)


func _pied_collaborateur(t: VBoxContainer, card: GameState.Card) -> void:
	var mt: Match = m.mt
	if mt.is_ai(mt.current_drafter()) or m.spectator:
		t.add_child(_bouton_ou_raison("", "%s choisit…" % _nom_court(mt.current_drafter()), "", func(): pass, 44.0))
	else:
		t.add_child(_bouton_ou_raison("Choisir", "", "", m._cmd.bind("pick_draft", [card]), 44.0))
