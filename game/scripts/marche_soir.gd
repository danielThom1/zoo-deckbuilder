class_name MarcheSoir
extends FenetreComite
## Le marché de ce soir, consulté en journée (handoff §2.4) : un écran par catégorie, le jeu continue derrière.
## Rien ne s'achète ici. Suivre un élément ne change aucune règle : main.gd l'affiche dans le bandeau (suivis).

const ONGLETS := ["contrats", "ouvriers", "cartes"]
const NOMS := {"contrats": "Contrats", "ouvriers": "Collaborateurs", "cartes": "Cartes d'action"}

var onglet := "contrats"
var boutons := {}
var chef: HBoxContainer
var corps: MarginContainer
var pied_gauche: HBoxContainer
var pied_droite: HBoxContainer
var compte: Label
var signature := ""


func _init(principal) -> void:
	super(principal)
	color = Color(UiTokens.ENCRE, 0.4)
	offset_top = UiTokens.H_BANDEAU
	offset_bottom = -UiTokens.H_DOCK


func _ready() -> void:
	var p := PanelContainer.new()
	var sb := UiTokens.panneau(UiTokens.FOND_FENETRE, 12, 2, 2, true)
	p.add_theme_stylebox_override("panel", sb)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -640
	p.offset_right = 640
	p.offset_top = -352
	p.offset_bottom = 352
	add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	# En-tête blanc
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
	h.add_theme_constant_override("separation", 40)
	tete.add_child(h)
	var tb := VBoxContainer.new()
	tb.add_theme_constant_override("separation", 0)
	tb.add_child(_mono("APERÇU · LE JEU CONTINUE", 12, 500, UiTokens.TEXTE_2))
	tb.add_child(_cond("Marché de ce soir", 30))
	h.add_child(tb)
	var groupe := HBoxContainer.new()
	groupe.add_theme_constant_override("separation", -2)
	groupe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	groupe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(groupe)
	for o in ONGLETS:
		var b := Composants.bouton("", "Onglet")
		b.toggle_mode = true
		b.custom_minimum_size.y = 38
		b.add_theme_font_override("font", UiTokens.police_corps(700))
		b.pressed.connect(func(): choisir(o))
		groupe.add_child(b)
		boutons[o] = b
	chef = HBoxContainer.new()
	chef.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(chef)
	var fermer := Composants.bouton("✕", "BoutonSecondaire")
	fermer.custom_minimum_size = Vector2(40, 40)
	fermer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fermer.pressed.connect(func(): visible = false)
	h.add_child(fermer)
	# Corps
	corps = MarginContainer.new()
	for c in [["left", 18], ["right", 18], ["top", 12], ["bottom", 12]]:
		corps.add_theme_constant_override("margin_" + c[0], c[1])
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(corps)
	# Pied blanc
	var pied := PanelContainer.new()
	var sp := StyleBoxFlat.new()
	sp.bg_color = UiTokens.PAPIER
	sp.corner_radius_bottom_left = 10
	sp.corner_radius_bottom_right = 10
	sp.border_color = UiTokens.ENCRE
	sp.border_width_top = 2
	sp.content_margin_left = 18
	sp.content_margin_right = 18
	sp.content_margin_top = 10
	sp.content_margin_bottom = 10
	pied.add_theme_stylebox_override("panel", sp)
	v.add_child(pied)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 12)
	pied.add_child(ph)
	pied_gauche = HBoxContainer.new()
	pied_gauche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ph.add_child(pied_gauche)
	compte = _mono("", 14, 500)
	compte.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ph.add_child(compte)
	pied_droite = HBoxContainer.new()
	ph.add_child(pied_droite)


func choisir(o: String) -> void:
	onglet = o
	signature = ""
	rafraichir()


func ouvrir() -> void:
	visible = true
	signature = ""
	rafraichir()


## Ne reconstruit que si quelque chose d'affiché a changé : la fenêtre reste ouverte pendant que la partie tourne.
func rafraichir() -> void:
	if not visible or not is_node_ready():
		return
	var game: GameState = m.game
	if game.phase != "day":
		visible = false
		return
	var mt: Match = m.mt
	var sig := "%s|%d|%d|%d|%s|%d|%d|%d" % [onglet, game.market_contracts.size(), mt.market_workers.size(), mt.market_actions.size(), m.suivis.size(),
		floori(game.money), game.employees(), game.housing()]
	if sig == signature:
		return
	signature = sig
	tient_memo = {}
	var n := {"contrats": game.market_contracts.size(), "ouvriers": mt.market_workers.size(), "cartes": mt.market_actions.size()}
	for o in ONGLETS:
		boutons[o].text = "%s   %d" % [NOMS[o], n[o]]
		boutons[o].button_pressed = o == onglet
	_clear(chef)
	if not mt.night_order.is_empty():
		var i: int = mt.night_order[0]
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.JAUNE_CLAIR, 8, 2, 6, false))
		var hc := HBoxContainer.new()
		hc.add_theme_constant_override("separation", 8)
		pc.add_child(hc)
		hc.add_child(_logo(i, 24))
		hc.add_child(_corps("Vous avez choisi en premier hier soir" if i == game.index else "%s a choisi en premier hier soir" % _nom_court(i), 13, 700))
		pc.tooltip_text = "Ce soir, chacun choisit dans l'ordre d'influence. Les valeurs des rivaux restent cachées."
		chef.add_child(pc)
	_clear(corps)
	match onglet:
		"contrats":
			_ecran_contrats()
		"ouvriers":
			_ecran_collaborateurs()
		"cartes":
			_ecran_cartes()
	_clear(pied_gauche)
	_clear(pied_droite)
	var k := ONGLETS.find(onglet)
	if k > 0:
		var prec := Composants.bouton("‹ %s" % NOMS[ONGLETS[k - 1]], "BoutonSecondaire")
		prec.custom_minimum_size.y = 38
		prec.pressed.connect(func(): choisir(ONGLETS[k - 1]))
		pied_gauche.add_child(prec)
	else:
		var note := _corps("★ Un élément suivi s'affiche dans le bandeau et vous prévient s'il est pris.", 13, 600)
		pied_gauche.add_child(note)
	var suiv := Composants.bouton("%s ›" % NOMS[ONGLETS[k + 1]] if k < ONGLETS.size() - 1 else "Retour au jeu", "BoutonPrincipal")
	suiv.custom_minimum_size.y = 38
	suiv.pressed.connect(func():
		if k < ONGLETS.size() - 1:
			choisir(ONGLETS[k + 1])
		else:
			visible = false)
	pied_droite.add_child(suiv)
	_maj_compte()


func _process(_delta: float) -> void:
	if visible:
		_maj_compte()


func _maj_compte() -> void:
	var game: GameState = m.game
	var s := maxi(0, ceili(game.day_length - game.time))
	compte.text = "Nuit dans %d:%02d" % [s / 60, s % 60]


func _bouton_suivre(objet: Variant, court := false) -> Button:
	var suivi: bool = m.suivis.has(objet)
	var b := Composants.bouton(("★" if suivi else "☆") if court else ("★ Suivi" if suivi else "☆ Suivre"), "BoutonPrincipal" if suivi else "BoutonSecondaire")
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(32, 32)
	b.tooltip_text = "Vous prévenir si ce choix est pris par un rival"
	b.pressed.connect(func():
		if suivi:
			m.suivis.erase(objet)
		else:
			m.suivis.append(objet)
		signature = ""
		rafraichir())
	return b


## Contour jaune d'un élément suivi.
func _style_carte(objet: Variant, fond := UiTokens.PAPIER) -> StyleBoxFlat:
	var suivi: bool = m.suivis.has(objet)
	return UiTokens.panneau(fond, 10, 3 if suivi else 2, 2, suivi, UiTokens.SELECTION if suivi else UiTokens.ENCRE)


# ------------------------------------------------------------------ contrats

func _ecran_contrats() -> void:
	var game: GameState = m.game
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	corps.add_child(v)
	var ht := HBoxContainer.new()
	ht.add_theme_constant_override("separation", 12)
	ht.add_child(_cond("CONTRATS D'ANIMAUX · 1 PAR FILIALE", 15))
	var note := _corps("Un contrat pris n'est remplacé que demain.", 13, 600, UiTokens.TEXTE_2)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ht.add_child(note)
	ht.add_child(_corps("Votre argent :", 13, 600, UiTokens.TEXTE_2))
	ht.add_child(_mono(str(floori(game.money)), 13))
	v.add_child(ht)
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 12)
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(r)
	for d in _dans_l_ordre("contrats", game.market_contracts):
		r.add_child(_fiche_contrat(d))


func _ligne(parent: Control, libelle: String, valeur: Control) -> void:
	var filet := ColorRect.new()
	filet.color = UiTokens.FILET
	filet.custom_minimum_size.y = 1
	parent.add_child(filet)
	var h := HBoxContainer.new()
	h.custom_minimum_size.y = 28
	var l := _cond(libelle.to_upper(), 11, UiTokens.TEXTE_2)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	valeur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(valeur)
	parent.add_child(h)


func _fiche_contrat(d: Dictionary) -> Control:
	var game: GameState = m.game
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style_carte(d))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.x = 100
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	# Illustration sur la teinte du biome, bouton de suivi par-dessus
	var haut := PanelContainer.new()
	var sh := StyleBoxFlat.new()
	var biome: Dictionary = UiTokens.BIOMES.get(str(d["biome"]).to_lower(), {})
	sh.bg_color = Color(biome.get("couleur", UiTokens.SARCELLE)).lightened(0.8)
	sh.corner_radius_top_left = 8
	sh.corner_radius_top_right = 8
	sh.border_color = UiTokens.ENCRE
	sh.border_width_bottom = 2
	sh.content_margin_top = 8
	sh.content_margin_bottom = 4
	haut.add_theme_stylebox_override("panel", sh)
	haut.custom_minimum_size.y = 112
	haut.add_child(_image_animal(str(d["id"]), false))
	var calque := Control.new()
	calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	haut.add_child(calque)
	var s := _bouton_suivre(d)
	s.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	s.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	s.offset_left = -76
	s.offset_right = -8
	s.offset_top = 0
	calque.add_child(s)
	v.add_child(haut)
	var marge := MarginContainer.new()
	for c in [["left", 12], ["right", 12], ["top", 10], ["bottom", 12]]:
		marge.add_theme_constant_override("margin_" + c[0], c[1])
	marge.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(marge)
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 2)
	marge.add_child(t)
	var nom := _cond(str(d["nom"]).to_upper(), 20 if str(d["nom"]).length() <= 18 else 16)
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nom.tooltip_text = str(d["nom"])
	nom.mouse_filter = Control.MOUSE_FILTER_PASS
	t.add_child(nom)
	var tier := int(str(d["palier"]).substr(1))
	var sous := _corps("%s · %s · %s" % [game.continent_name(d.get("continent", "")), game.type_name(d.get("type", "")).to_lower(), "◆".repeat(tier) + "◇".repeat(maxi(0, 3 - tier))], 12, 600, UiTokens.TEXTE_2)
	sous.tooltip_text = str(game.data["animals"]["paliers"][d["palier"]]["nom"])
	sous.mouse_filter = Control.MOUSE_FILTER_PASS
	sous.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.add_child(sous)
	var c := game.contract_cost(d)
	var cout := "%d" % int(c.get("argent", 0))
	if int(c.get("or", 0)) > 0:
		cout += " + %d or" % int(c["or"])
	_ligne(t, "Prix", _mono(cout, 14))
	_ligne(t, "Attractivité", _mono("+%d" % int(d["reputation"]), 14))
	_ligne(t, "Nourriture", _mono("%d/j" % game.food_cost(d), 14))
	var mo := MotifLettre.new()
	mo.regler(d, 12.0)
	mo.tooltip_text = m._pattern_words(d)
	_ligne(t, "Motif · %d" % int(d["taille"]), mo)
	var am := _corps(str(game.building_def(d["decor"])["nom"]) if d.has("decor") else "—", 13, 600)
	_ligne(t, "Aménagement", am)
	var aff: float = game.affinity_gain(d)
	if aff > 0.0:
		_ligne(t, "Affinité", _mono("+%d %%" % roundi(aff * 100.0), 14, 600, UiTokens.SARCELLE_FONCE))
	if d.has("effet_texte"):
		t.add_child(_replie(_corps(str(d["effet_texte"]), 12, 600, UiTokens.SARCELLE_FONCE)))
	t.add_child(_espace_v())
	# Conclusion écrite
	var manque := ceili(float(game.contract_payment(d)["argent"]) - game.money)
	var ok := false
	var txt := ""
	if game.has_species(d["id"]):
		txt = "✕ espèce déjà au zoo"
	elif manque > 0:
		txt = "✕ manque %d argent" % manque
	else:
		var tn := _tient(d)
		ok = tn[0]
		txt = ("✓ tient dans votre zoo" if ok else "✕ %s" % tn[1])
	var pil := PanelContainer.new()
	var sc := StyleBoxFlat.new()
	sc.bg_color = Color("D8F0EC") if ok else UiTokens.JAUNE_CLAIR
	sc.border_color = UiTokens.ENCRE
	sc.set_border_width_all(1)
	sc.set_corner_radius_all(10)
	sc.content_margin_top = 2
	sc.content_margin_bottom = 2
	pil.add_theme_stylebox_override("panel", sc)
	var pl := _corps(txt, 12, 700)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pil.add_child(pl)
	t.add_child(pil)
	return p


# ------------------------------------------------------------------ collaborateurs

func _ecran_collaborateurs() -> void:
	var game: GameState = m.game
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	corps.add_child(v)
	var ht := HBoxContainer.new()
	var t := _cond("COLLABORATEURS · 1 EMBAUCHE AU PLUS", 15)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ht.add_child(t)
	if game.employees() >= game.housing():
		var al := PanelContainer.new()
		al.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.ORANGE_CLAIR, 8, 2, 5, false))
		var ah := HBoxContainer.new()
		ah.add_theme_constant_override("separation", 8)
		al.add_child(ah)
		ah.add_child(_jeton("maison", ""))
		ah.add_child(_corps("Logement plein (%d/%d) : construisez une maison avant ce soir pour embaucher" % [game.employees(), game.housing()], 13, 700))
		ht.add_child(al)
	v.add_child(ht)
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 12)
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(r)
	for card in _dans_l_ordre("ouvriers", m.mt.market_workers):
		var b := _grand_badge(card, false, 120)
		b.add_theme_stylebox_override("panel", _style_carte(card))
		r.add_child(b)


func _sur_photo(racine: Control, card: GameState.Card) -> void:
	var calque := Control.new()
	calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(calque)
	var s := _bouton_suivre(card, true)
	s.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	s.offset_left = -42
	s.offset_right = -10
	s.offset_top = 36
	s.offset_bottom = 68
	calque.add_child(s)


func _pied_prix(t: VBoxContainer, libelle: String, prix: int) -> void:
	var filet := ColorRect.new()
	filet.color = UiTokens.FILET
	filet.custom_minimum_size.y = 1
	t.add_child(filet)
	var h := HBoxContainer.new()
	var l := _cond(libelle, 12, UiTokens.TEXTE_2)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	h.add_child(_mono(str(prix), 20))
	t.add_child(h)


func _pied_collaborateur(t: VBoxContainer, card: GameState.Card) -> void:
	_pied_prix(t, "EMBAUCHE", m.game.hire_cost(card))


# ------------------------------------------------------------------ cartes

func _ecran_cartes() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	corps.add_child(v)
	var ht := HBoxContainer.new()
	ht.add_theme_constant_override("separation", 12)
	ht.add_child(_cond("CARTES D'ACTION · USAGE UNIQUE", 15))
	var note := _corps("Une carte achetée part dans votre défausse ; elle est jouée puis retirée du deck.", 13, 600, UiTokens.TEXTE_2)
	ht.add_child(note)
	v.add_child(ht)
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 14)
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(r)
	for card in _dans_l_ordre("cartes", m.mt.market_actions):
		var c := _grande_carte(card, false, 170, 200)
		c.add_theme_stylebox_override("panel", _style_carte(card))
		r.add_child(c)
	r.add_child(_panneau_deck())


func _sur_carte(haut: Control, card: GameState.Card) -> void:
	var s := _bouton_suivre(card)
	s.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	s.offset_left = -76
	s.offset_right = -10
	s.offset_top = 8
	s.offset_bottom = 40
	haut.add_child(s)


func _pied_carte(t: VBoxContainer, card: GameState.Card) -> void:
	_pied_prix(t, "PRIX CE SOIR", m.game.action_price(card))


func _panneau_deck() -> Control:
	var st := _stats_deck()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 14, false))
	p.custom_minimum_size.x = 300
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(_cond("VOTRE DECK", 15))
	var cases := HFlowContainer.new()
	cases.add_theme_constant_override("h_separation", 3)
	cases.add_theme_constant_override("v_separation", 3)
	for k in st["collab"] + st["actions"]:
		var c := Panel.new()
		var sc := StyleBoxFlat.new()
		sc.bg_color = UiTokens.SELECTION if k >= st["collab"] else UiTokens.SARCELLE
		sc.border_color = UiTokens.ENCRE
		sc.set_border_width_all(1)
		sc.set_corner_radius_all(3)
		c.add_theme_stylebox_override("panel", sc)
		c.custom_minimum_size = Vector2(20, 28)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cases.add_child(c)
	v.add_child(cases)
	v.add_child(_replie(_corps("%d collaborateurs · %d action%s" % [st["collab"], st["actions"], "s" if st["actions"] > 1 else ""], 13, 700)))
	v.add_child(_replie(_corps("Avec une carte de plus : %d %% de chances d'en avoir une dans une main de %d." % [_chance_action(st["actions"] + 1, st["total"] + 1, st["main"]), st["main"]], 13, 600, UiTokens.TEXTE_2)))
	v.add_child(_espace_v())
	_memo_hubert("conseil_cartes", v, 0.0, "Une prime, c'est un salaire qui a honte de lui.")
	return p
