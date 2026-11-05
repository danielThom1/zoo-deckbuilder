class_name DraftComite
extends FenetreComite
## Le draft « Le Comité » (handoff §3) : une fenêtre, les candidats en grands badges, l'ordre de passage en tour de parole.

var titre: Label
var sur: Label
var tour: HBoxContainer
var rangee: HBoxContainer
var recap: GridContainer


func _init(principal) -> void:
	super(principal)
	color = Color(UiTokens.ENCRE, 0.55)


func _ready() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.FOND_FENETRE, 12, 2, 2, true))
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -640
	p.offset_right = 640
	p.offset_top = -420
	p.offset_bottom = 420
	add_child(p)
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
	for card in mt.draft_pool:
		var b := _grand_badge(card, false, 140)
		b.custom_minimum_size.x = 290
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
