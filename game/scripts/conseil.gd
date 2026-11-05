class_name Conseil
extends FenetreComite
## La nuit « Le Comité » (docs/handoff_comite, §2.5 et §2.6) : un conseil d'administration. À gauche l'ordre du jour et le
## tour de parole, à droite une diapositive par point. Tout est reconstruit à chaque changement de l'état de la partie
## (rafraichir, appelé par main.gd) ; aucun nœud d'ici ne modifie la partie autrement que par m._cmd.

const POINTS := {
	"contrats": ["Acquisitions animales", "ACQUISITIONS", "Quel animal signer ce soir ?"],
	"ouvriers": ["Recrutements", "RECRUTEMENTS · 1 EMBAUCHE AU PLUS", "Les candidats du jour"],
	"cartes": ["Cartes d'action", "CARTES D'ACTION · 1 ACHAT AU PLUS", "Outils de motivation du personnel"],
	"bonus": ["Bonus de demain", "BONUS DU LENDEMAIN", ""],
	"equipe": ["Revue d'équipe", "REVUE D'ÉQUIPE · CHACUN À SON RYTHME", "Organigramme de la filiale"],
}
const TEXTE_COLONNE := Color("C8D3DE")
const TEXTE_COLONNE_2 := Color("8496A8")
const BORD_COLONNE := Color("6B7C8E")

var colonne: VBoxContainer
var titre_sur: Label
var titre: Label
var jetons: HBoxContainer
var bouton_suivant: Button
var barre_auto: Control
var barre_auto_jauge: ProgressBar
var barre_auto_texte: Label
var pages := {}
var fenetre_journal: Control
var journal_corps: HBoxContainer
var fiche: GameState.Card = null  # collaborateur montré à l'étape Équipe
var fiche_action := ""  # "" , "ameliorer" ou "licencier"
var toast_boite: PanelContainer


## Cercle de l'ordre du jour : numéro ou coche, trait plein ou pointillé.
class Anneau extends Control:
	var texte := ""
	var couleur := Color.WHITE
	var couleur_texte := Color.WHITE
	var pointille := false

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0 - 1.0
		if pointille:
			for k in 10:
				var a := TAU * k / 10.0
				draw_arc(c, r, a, a + TAU / 20.0, 6, couleur, 2.0, true)
		else:
			draw_arc(c, r, 0.0, TAU, 40, couleur, 2.0, true)
		var f := UiTokens.police_mono(600)
		var sz := 13
		var w := f.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		draw_string(f, Vector2(c.x - w / 2.0, c.y + sz * 0.36), texte, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, couleur_texte)


## Traits de l'organigramme : de la Direction vers les trois colonnes.
class Liens extends Control:
	func _draw() -> void:
		var y := size.y * 0.5
		var w := size.x
		var xs := [w * 0.16, w * 0.5, w * 0.84]
		draw_line(Vector2(w * 0.5, 0), Vector2(w * 0.5, y), UiTokens.ENCRE, 3.0)
		draw_line(Vector2(xs[0], y), Vector2(xs[2], y), UiTokens.ENCRE, 3.0)
		for x in xs:
			draw_line(Vector2(x, y), Vector2(x, size.y), UiTokens.ENCRE, 3.0)


## Recettes en aplat sarcelle, dépenses en orange cerné de pointillés : la forme double la couleur.
class Barres extends Control:
	var recettes := 0
	var depenses := 0

	func _draw() -> void:
		var maxi_v := float(maxi(1, maxi(recettes, depenses)))
		var long := 180.0
		var f := UiTokens.police_mono(600)
		var r1 := Rect2(0, 6, long * recettes / maxi_v, 22)
		var r2 := Rect2(0, 40, long * depenses / maxi_v, 22)
		draw_rect(r1, UiTokens.SARCELLE)
		draw_string(f, Vector2(r1.size.x + 6, 22), "+%d recettes" % recettes, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiTokens.ENCRE)
		draw_rect(r2, UiTokens.ORANGE)
		Composants.tirets_rect(self, r2, UiTokens.ENCRE)
		draw_string(f, Vector2(r2.size.x + 6, 56), "−%d dépenses" % depenses, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiTokens.ENCRE)


func _init(principal) -> void:
	super(principal)
	color = UiTokens.ENCRE


func _ready() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	marge.offset_right = 270
	for c in [["left", 18], ["right", 18], ["top", 22], ["bottom", 22]]:
		marge.add_theme_constant_override("margin_" + c[0], c[1])
	add_child(marge)
	colonne = VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 4)
	marge.add_child(colonne)
	# Diapositive
	var diapo := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.PAPIER
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 20
	sb.anti_aliasing = true
	diapo.add_theme_stylebox_override("panel", sb)
	diapo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	diapo.offset_left = 270
	diapo.offset_top = 18
	diapo.offset_right = -18
	diapo.offset_bottom = -18
	add_child(diapo)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	diapo.add_child(v)
	# En-tête
	var entete := VBoxContainer.new()
	entete.add_theme_constant_override("separation", 8)
	v.add_child(entete)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	entete.add_child(ligne)
	var tb := VBoxContainer.new()
	tb.add_theme_constant_override("separation", 0)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.size_flags_vertical = Control.SIZE_SHRINK_END
	ligne.add_child(tb)
	titre_sur = _mono("", 12, 500, UiTokens.TEXTE_2)
	tb.add_child(titre_sur)
	titre = _cond("", 34)
	tb.add_child(titre)
	jetons = HBoxContainer.new()
	jetons.size_flags_vertical = Control.SIZE_SHRINK_END
	ligne.add_child(jetons)
	barre_auto = VBoxContainer.new()
	barre_auto.size_flags_vertical = Control.SIZE_SHRINK_END
	barre_auto.custom_minimum_size.x = 260
	ligne.add_child(barre_auto)
	barre_auto_texte = _corps("", 13, 600, UiTokens.TEXTE_2)
	barre_auto_texte.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	barre_auto.add_child(barre_auto_texte)
	barre_auto_jauge = ProgressBar.new()
	barre_auto_jauge.show_percentage = false
	barre_auto_jauge.custom_minimum_size.y = 8
	barre_auto_jauge.add_theme_stylebox_override("background", UiTokens.chip(UiTokens.FILET, 4, 0))
	barre_auto_jauge.add_theme_stylebox_override("fill", UiTokens.chip(UiTokens.SARCELLE, 4, 0))
	barre_auto.add_child(barre_auto_jauge)
	bouton_suivant = Composants.bouton("", "BoutonPrincipal")
	bouton_suivant.custom_minimum_size = Vector2(120, 44)
	bouton_suivant.add_theme_font_size_override("font_size", 15)
	bouton_suivant.size_flags_vertical = Control.SIZE_SHRINK_END
	bouton_suivant.pressed.connect(func(): m._on_night_next())
	ligne.add_child(bouton_suivant)
	var filet := ColorRect.new()
	filet.color = UiTokens.ENCRE
	filet.custom_minimum_size.y = 3
	entete.add_child(filet)
	# Une page par point
	for st in Match.NIGHT_STAGES:
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 12)
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(page)
		pages[st] = page
	_construire_journal()


# ------------------------------------------------------------------ petits outils

# ------------------------------------------------------------------ reconstruction

func rafraichir() -> void:
	var game: GameState = m.game
	var mt: Match = m.mt
	if game.phase != "night" or game.night_report.is_empty():
		return
	var stage: String = mt.night_stage
	_annoncer_suivis()
	_rendre_colonne()
	var n := Match.NIGHT_STAGES.find(stage) + 1
	titre_sur.text = "POINT %d / %d · %s" % [n, Match.NIGHT_STAGES.size(), POINTS[stage][1]]
	titre.text = POINTS[stage][2]
	_rendre_jetons(stage)
	_regler_suivant(stage)
	for st in pages:
		pages[st].visible = st == stage
		if st == stage:
			_clear(pages[st])
	match stage:
		"contrats":
			_page_contrats()
		"ouvriers":
			_page_collaborateurs()
		"cartes":
			_page_cartes()
		"bonus":
			_page_bonus()
		"equipe":
			_page_equipe()
	if fenetre_journal.visible:
		_rendre_journal()


## Un élément suivi vient d'être pris par un rival : on le dit, une seule fois.
func _annoncer_suivis() -> void:
	for t in m.mt.night_taken:
		if t["joueur"] != m.game.index and m.suivis.has(t["objet"]):
			m.suivis.erase(t["objet"])
			var o: Variant = t["objet"]
			var nom: String = str(o["nom"]) if o is Dictionary else (str(o.action["nom"]) if o.is_action() else o.nom)
			_toast("★ %s, que vous suiviez, est pris par %s" % [nom, _nom_court(t["joueur"])])


func _toast(texte: String) -> void:
	if toast_boite == null:
		toast_boite = PanelContainer.new()
		toast_boite.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.ENCRE, 8, 0, 10, false))
		toast_boite.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		toast_boite.grow_horizontal = Control.GROW_DIRECTION_BOTH
		toast_boite.grow_vertical = Control.GROW_DIRECTION_BEGIN
		toast_boite.offset_bottom = -30
		toast_boite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(toast_boite)
		toast_boite.add_child(_corps("", 14, 700, UiTokens.PAPIER))
	toast_boite.get_child(0).text = texte
	toast_boite.visible = true
	toast_boite.modulate.a = 1.0
	var tw := toast_boite.create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(toast_boite, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): toast_boite.visible = false)


func _regler_suivant(stage: String) -> void:
	var mt: Match = m.mt
	var game: GameState = m.game
	var moi: bool = not m.spectator
	barre_auto.visible = false
	bouton_suivant.visible = true
	bouton_suivant.disabled = false
	if stage == "equipe":
		bouton_suivant.text = "Passer au jour %d ›" % (mt.day + 1)
		bouton_suivant.disabled = mt.game_over or not moi
	elif mt.market_stage():
		var mon_tour: bool = mt.current_buyer() == game.index and moi
		bouton_suivant.text = "Passer ›" if mon_tour else "%s choisit…" % _nom_court(mt.current_buyer())
		bouton_suivant.disabled = not mon_tour
	else:
		# Bonus : le président décide ; les autres n'ont rien à faire, l'étape passe seule.
		var preside: bool = mt.influence_leader() == game.index and moi
		bouton_suivant.visible = false
		barre_auto.visible = not preside and not mt.bonus_choice.is_empty() and m.reseau == null


func _process(_delta: float) -> void:
	if not visible or not barre_auto.visible:
		return
	var duree: float = m.night_pause()
	var reste := maxf(0.0, duree - m.night_clock)
	barre_auto_jauge.max_value = duree
	barre_auto_jauge.value = duree - reste
	barre_auto_texte.text = "Point suivant dans %d s" % ceili(reste)


func _rendre_jetons(stage: String) -> void:
	_clear(jetons)
	var game: GameState = m.game
	if stage == "bonus":
		var preside: bool = m.mt.influence_leader() == game.index and not m.spectator
		titre.text = "Vous présidez la séance" if preside else "%s a tranché" % m.mt.names[m.mt.influence_leader()]
		if not preside and m.mt.bonus_choice.is_empty():
			titre.text = "%s délibère" % m.mt.names[m.mt.influence_leader()]
		if preside:
			var b := PanelContainer.new()
			b.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.SELECTION, 8, 2, 8, false))
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 8)
			b.add_child(hb)
			hb.add_child(_logo(game.index, 28))
			hb.add_child(_corps("1er en influence : vous seul décidez", 14, 800))
			jetons.add_child(b)
		return
	var cadre := PanelContainer.new()
	cadre.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 8, 2, 7, false))
	cadre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	cadre.add_child(h)
	h.add_child(_jeton("icone_pieces", str(floori(game.money))))
	if stage == "contrats":
		h.add_child(_jeton("icone_or", str(floori(game.stock["or"])), UiTokens.OR_TEXTE))
	if stage in ["contrats", "ouvriers"]:
		var plein: bool = game.employees() >= game.housing()
		h.add_child(_jeton("maison", "%d/%d" % [game.employees(), game.housing()], UiTokens.NEGATIF if plein else UiTokens.ENCRE))
	jetons.add_child(cadre)


# ------------------------------------------------------------------ colonne de l'ordre du jour

func _rendre_colonne() -> void:
	_clear(colonne)
	var mt: Match = m.mt
	var game: GameState = m.game
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 10)
	tete.add_child(_logo(game.index, 42))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.add_child(_cond("CONSEIL · NUIT %d" % mt.day, 24, UiTokens.PAPIER))
	tv.add_child(_corps("Ordre du jour de la séance", 12, 600, TEXTE_COLONNE))
	tete.add_child(tv)
	colonne.add_child(tete)
	var esp := Control.new()
	esp.custom_minimum_size.y = 8
	colonne.add_child(esp)
	var cur := Match.NIGHT_STAGES.find(mt.night_stage)
	for k in Match.NIGHT_STAGES.size():
		var fait: bool = k < cur
		var encours: bool = k == cur
		colonne.add_child(_point(str(POINTS[Match.NIGHT_STAGES[k]][0]), "✓" if fait else str(k + 1), fait, encours))
	var lever := _point("Levée de séance · jour %d" % (mt.day + 1), "›", true, false)
	lever.get_child(0).get_child(0).pointille = true
	colonne.add_child(lever)
	var titre_tour := _cond("TOUR DE PAROLE · INFLUENCE", 12, TEXTE_COLONNE_2)
	titre_tour.add_theme_constant_override("line_spacing", 0)
	var marge_tour := MarginContainer.new()
	marge_tour.add_theme_constant_override("margin_top", 18)
	marge_tour.add_child(titre_tour)
	colonne.add_child(marge_tour)
	for k in mt.night_order.size():
		colonne.add_child(_tour(k))
	colonne.add_child(_espace_v())
	var voir := _bouton_colonne("Voir mon zoo")
	voir.tooltip_text = "Masque le conseil pour regarder votre terrain (enclos, motifs) avant de décider"
	voir.pressed.connect(func(): m.night_peek = true)
	colonne.add_child(voir)
	var journal := _bouton_colonne("Classement · Objectifs · Journal")
	journal.pressed.connect(func():
		_rendre_journal()
		fenetre_journal.visible = true)
	colonne.add_child(journal)


func _point(nom: String, marque: String, fait: bool, encours: bool) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.SELECTION if encours else Color(0, 0, 0, 0)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var a := Anneau.new()
	a.custom_minimum_size = Vector2(26, 26)
	a.texte = marque
	a.couleur = UiTokens.ENCRE if encours else BORD_COLONNE
	var coul: Color = UiTokens.ENCRE if encours else (TEXTE_COLONNE_2 if fait else TEXTE_COLONNE)
	a.couleur_texte = coul
	a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(a)
	var l := _corps(nom, 14, 700, coul)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(l)
	return p


func _tour(k: int) -> Control:
	var mt: Match = m.mt
	var i: int = mt.night_order[k]
	var etat := ""
	var attendu := false
	var passe := false
	if mt.market_stage():
		attendu = k == mt.night_turn
		passe = k < mt.night_turn
	elif mt.night_stage == "bonus":
		attendu = i == mt.influence_leader() and mt.bonus_choice.is_empty()
	if attendu:
		etat = " · décision attendue"
	elif passe:
		etat = " · a joué ✓"
	elif mt.night_stage == "bonus" and i == mt.influence_leader():
		etat = " · préside"
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.MARINE_2 if attendu else Color(0, 0, 0, 0)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(4)
	sb.content_margin_left = 6
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	h.add_child(_logo(i, 22))
	var l := _corps("%d · %s%s" % [k + 1, _nom_court(i), etat], 13, 800 if attendu else 600, UiTokens.PAPIER if attendu else TEXTE_COLONNE)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.tooltip_text = str(mt.names[i])
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(l)
	if passe:
		p.modulate.a = 0.6
	return p


func _bouton_colonne(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 38
	b.add_theme_font_override("font", UiTokens.police_corps(700))
	b.add_theme_font_size_override("font_size", 13)
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0, 0, 0, 0)
	n.border_color = BORD_COLONNE
	n.set_border_width_all(2)
	n.set_corner_radius_all(8)
	n.anti_aliasing = true
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = UiTokens.MARINE_2
	for k in [["normal", n], ["hover", h], ["pressed", h]]:
		b.add_theme_stylebox_override(k[0], k[1])
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, UiTokens.PAPIER)
	return b


# ------------------------------------------------------------------ bas de diapositive

## Recettes, dépenses et total du jour, à partir du rapport de la nuit.
func _bilan() -> Dictionary:
	var r: Dictionary = m.game.night_report
	var s: Dictionary = r["stats"]
	var inc: Dictionary = r["income"]
	var recettes := int(inc["tickets"]) + int(inc["souvenirs"]) + roundi(float(s.get("cedees", 0.0)))
	var depenses := roundi(float(s.get("salaires", 0.0))) + roundi(float(s.get("nourriture", 0.0)))
	return {"recettes": recettes, "depenses": depenses, "total": recettes - depenses}


func _compte_de_resultat(parent: Control) -> void:
	var b := _bilan()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 10, false))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	p.add_child(h)
	var l := _replie(_cond("COMPTE DE RÉSULTAT · J%d" % m.mt.day, 13))
	l.custom_minimum_size.x = 92
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	var ba := Barres.new()
	ba.recettes = b["recettes"]
	ba.depenses = b["depenses"]
	ba.custom_minimum_size = Vector2(320, 68)
	h.add_child(ba)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(esp)
	var tot := _mono("%s %+d" % ["▲" if b["total"] >= 0 else "▼", b["total"]], 30)
	tot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tot)
	parent.add_child(p)


func _ligne_bas(page: Control, gauche: String, droite := "") -> void:
	var h := HBoxContainer.new()
	var g := _mono(gauche, 11, 500, UiTokens.TEXTE_2)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(g)
	h.add_child(_mono(droite, 11, 500, UiTokens.TEXTE_2))
	page.add_child(h)


# ------------------------------------------------------------------ point 1 : contrats

## Cellule d'une colonne : hauteur fixe pour que les lignes s'alignent d'une colonne à l'autre.
func _cellule(col: VBoxContainer, h: int, pris: bool, enfant: Control = null, bord_fort := false) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = GRIS_PRIS if pris else Color(1, 1, 1, 0)
	sb.border_color = UiTokens.ENCRE if bord_fort else UiTokens.FILET
	sb.border_width_bottom = 2 if bord_fort else 1
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.y = h
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if enfant:
		enfant.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p.add_child(enfant)
	col.add_child(p)
	return p


func _page_contrats() -> void:
	var page: VBoxContainer = pages["contrats"]
	var game: GameState = m.game
	var pris := _objets_pris("contrats")
	var defs := _dans_l_ordre("contrats", game.market_contracts + pris)
	# Meilleures valeurs, parmi ce qui reste à prendre : une pastille écrite, seulement si tout n'est pas à égalité
	var libres := defs.filter(func(d): return not pris.has(d))
	var valeur := func(d: Dictionary) -> float:
		var c := game.contract_cost(d)
		return float(c.get("argent", 0)) + float(c.get("or", 0)) * game.buy_price("or")
	var prix := libres.map(func(d): return valeur.call(d))
	var attr := libres.map(func(d): return int(d["reputation"]))
	var moins_cher: float = prix.min() if prix.size() > 1 and prix.min() != prix.max() else -1.0
	var meilleur: int = attr.max() if attr.size() > 1 and attr.min() != attr.max() else -1
	var table := HBoxContainer.new()
	table.add_theme_constant_override("separation", 0)
	page.add_child(table)
	var noms := VBoxContainer.new()
	noms.add_theme_constant_override("separation", 0)
	noms.custom_minimum_size.x = 118
	table.add_child(noms)
	var hauteurs := [128, 40, 40, 40, 66, 36, 36, 36, 50, 62]
	var libelles := ["", "Coût", "Attractivité", "Nourriture / jour", "Motif", "Aménagement", "Origine · type", "Rareté", "Bonus", ""]
	for k in hauteurs.size():
		var l: Label = _cond(str(libelles[k]).to_upper(), 12, UiTokens.TEXTE_2)
		var cel := _cellule(noms, hauteurs[k], false, l, k == 0)
		cel.get_theme_stylebox("panel").content_margin_left = 12
	for d in defs:
		var est_pris: bool = pris.has(d)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.custom_minimum_size.x = 100
		table.add_child(col)
		_colonne_contrat(col, d, hauteurs, est_pris, moins_cher, meilleur, valeur)
	page.add_child(_espace_v())
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 16)
	_compte_de_resultat(bas)
	_memo_hubert("soir_bon" if _bilan()["total"] >= 0 else "soir_mauvais", bas, 470.0)
	page.add_child(bas)
	var inc: Dictionary = game.night_report["income"]
	_ligne_bas(page, ("Document confidentiel — ne pas diffuser aux actionnaires" if inc["open"] else "Zoo fermé : %s" % inc["reason"]),
		"Lettres du motif : P prairie · F forêt · E eau · R roche · S sable")


func _colonne_contrat(col: VBoxContainer, d: Dictionary, H: Array, est_pris: bool, moins_cher: float, meilleur: int, valeur: Callable) -> void:
	var game: GameState = m.game
	var grise := UiTokens.ENCRE_DOUX
	var texte: Color = grise if est_pris else UiTokens.ENCRE
	# En-tête : image et nom
	var tete := VBoxContainer.new()
	tete.add_theme_constant_override("separation", 0)
	tete.add_child(_image_animal(str(d["id"]), est_pris))
	var nom := _cond(str(d["nom"]).to_upper(), 20 if str(d["nom"]).length() <= 18 else 16, texte)
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nom.tooltip_text = str(d["nom"])
	nom.mouse_filter = Control.MOUSE_FILTER_PASS
	tete.add_child(nom)
	_cellule(col, H[0], est_pris, tete, true)
	# Coût
	var c := game.contract_cost(d)
	var cout := "%d" % int(c.get("argent", 0))
	if int(c.get("or", 0)) > 0:
		cout += " + %d or" % int(c["or"])
	var hc := HBoxContainer.new()
	hc.add_theme_constant_override("separation", 6)
	hc.add_child(_mono(cout, 16, 600, texte))
	if not est_pris and is_equal_approx(float(valeur.call(d)), moins_cher):
		hc.add_child(_pilule("▼ moins cher"))
	_cellule(col, H[1], est_pris, hc)
	# Attractivité
	var ha := HBoxContainer.new()
	ha.add_theme_constant_override("separation", 6)
	ha.add_child(_mono("+%d" % int(d["reputation"]), 16, 600, texte))
	if not est_pris and int(d["reputation"]) == meilleur:
		ha.add_child(_pilule("▲ meilleur"))
	_cellule(col, H[2], est_pris, ha)
	_cellule(col, H[3], est_pris, _mono(str(game.food_cost(d)), 16, 600, texte))
	# Motif, en lettres
	if est_pris:
		_cellule(col, H[4], true)
	else:
		var hm := HBoxContainer.new()
		hm.add_theme_constant_override("separation", 8)
		var mo := MotifLettre.new()
		mo.regler(d, 14.0 if _hauteur_motif(d) <= 3 else 12.0)
		mo.tooltip_text = m._pattern_words(d)
		mo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hm.add_child(mo)
		var tn := _tient(d)
		var tl := _replie(_corps("%d cases · %s %s" % [int(d["taille"]), "✓" if tn[0] else "✕", tn[1]], 12, 600, UiTokens.TEXTE_2))
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hm.add_child(tl)
		_cellule(col, H[4], false, hm)
	# Aménagement
	var amen := "—"
	if d.has("decor"):
		amen = str(game.building_def(d["decor"])["nom"])
	var al := _corps(amen, 13, 600, texte)
	al.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_cellule(col, H[5], est_pris, al)
	var ol := _corps("%s · %s" % [game.continent_name(d.get("continent", "")), game.type_name(d.get("type", "")).to_lower()], 13, 600, texte)
	ol.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_cellule(col, H[6], est_pris, ol)
	var tier := int(str(d["palier"]).substr(1))
	_cellule(col, H[7], est_pris, _corps("%s %s" % ["◆".repeat(tier) + "◇".repeat(maxi(0, 3 - tier)), game.data["animals"]["paliers"][d["palier"]]["nom"]], 13, 600, texte))
	# Bonus : affinité avec ce qu'on a déjà, effet du rare
	var bonus: Array[String] = []
	var aff := game.affinity_gain(d)
	if aff > 0.0:
		bonus.append("+%d %% d'affinité" % roundi(aff * 100.0))
	if d.has("effet_texte"):
		bonus.append(str(d["effet_texte"]))
	var bl := _replie(_corps(" · ".join(bonus) if not bonus.is_empty() else "—", 12, 600, grise if est_pris else UiTokens.SARCELLE_FONCE if not bonus.is_empty() else UiTokens.ENCRE))
	bl.max_lines_visible = 3
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cellule(col, H[8], est_pris, bl)
	# Bouton
	var preneur := _preneur("contrats", d)
	if est_pris:
		var hp := HBoxContainer.new()
		hp.add_theme_constant_override("separation", 6)
		hp.add_child(_logo(preneur, 24))
		var pl := _corps("Pris par %s" % _nom_court(preneur), 13, 700, UiTokens.TEXTE_2)
		pl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hp.add_child(pl)
		_cellule(col, H[9], true, hp)
	else:
		var err: String = "Mode spectateur" if m.spectator else game.contract_error(d)
		var txt_prix := "Signer · %s" % cout
		_cellule(col, H[9], false, _bouton_ou_raison(txt_prix, _raison_contrat(err, d), err, m._cmd.bind("buy_contract", [d])))


func _hauteur_motif(d: Dictionary) -> int:
	var h := 0
	for c in d["motif"]:
		h = maxi(h, int(c[1]) + 1)
	return h


func _raison_contrat(err: String, d: Dictionary) -> String:
	if err == "":
		return ""
	var game: GameState = m.game
	if "pas votre tour" in err:
		return "En attente de votre tour"
	if "Pas assez" in err:
		var manque := ceili(float(game.contract_payment(d)["argent"]) - game.money)
		return "Manque %d argent" % manque
	if "espèce" in err:
		return "Espèce déjà au zoo"
	if "Déjà" in err:
		return "Contrat déjà signé"
	return m._short_reason(err)


# ------------------------------------------------------------------ point 2 : collaborateurs

func _page_collaborateurs() -> void:
	var page: VBoxContainer = pages["ouvriers"]
	var game: GameState = m.game
	var pris := _objets_pris("ouvriers")
	var plein: bool = game.employees() >= game.housing()
	if plein:
		var al := PanelContainer.new()
		al.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.ORANGE_CLAIR, 8, 2, 8, false))
		al.add_child(_corps("✕ Logement plein (%d / %d) : construisez une Maison de collaborateurs pour embaucher." % [game.employees(), game.housing()], 14, 700))
		page.add_child(al)
	var cartes := _dans_l_ordre("ouvriers", game.market_workers + pris)
	var rangee := HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 16)
	rangee.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(rangee)
	for card in cartes:
		rangee.add_child(_grand_badge(card, pris.has(card)))


# ------------------------------------------------------------------ point 3 : cartes d'action

func _page_cartes() -> void:
	var page: VBoxContainer = pages["cartes"]
	var mt: Match = m.mt
	var pris := _objets_pris("cartes")
	var cartes := _dans_l_ordre("cartes", mt.market_actions + pris)
	var rangee := HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 18)
	page.add_child(rangee)
	for card in cartes:
		rangee.add_child(_grande_carte(card, pris.has(card)))
	page.add_child(_espace_v())
	page.add_child(_bande_deck())


func _bande_deck() -> Control:
	var game: GameState = m.game
	var st := _stats_deck()
	var collab: int = st["collab"]
	var act: int = st["actions"]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 12, false))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	p.add_child(h)
	var l := _replie(_cond("VOTRE DECK APRÈS ACHAT", 13))
	l.custom_minimum_size.x = 100
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	var cases := HBoxContainer.new()
	cases.add_theme_constant_override("separation", 3)
	cases.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for k in collab + act + 1:
		var c := Panel.new()
		var est_action: bool = k >= collab
		var nouvelle: bool = k == collab + act
		var sc := StyleBoxFlat.new()
		sc.bg_color = Color(0, 0, 0, 0) if nouvelle else (UiTokens.SELECTION if est_action else UiTokens.SARCELLE)
		if nouvelle:
			sc.bg_color = UiTokens.JAUNE_CLAIR
		else:
			sc.border_color = UiTokens.ENCRE
			sc.set_border_width_all(1)
		sc.set_corner_radius_all(3)
		c.add_theme_stylebox_override("panel", sc)
		c.custom_minimum_size = Vector2(18, 24)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if nouvelle:
			c.add_child(_cadre_tirets(3))
		cases.add_child(c)
	h.add_child(cases)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_corps("%d collaborateurs · %d action%s · +1 action (en pointillé)" % [collab, act, "s" if act > 1 else ""], 13, 700))
	var ch := _corps("Chance d'avoir une action dans une main de %d : " % st["main"], 13, 600, UiTokens.TEXTE_2)
	var ligne := HBoxContainer.new()
	ligne.add_child(ch)
	ligne.add_child(_mono("%d %%" % _chance_action(act + 1, st["total"] + 1, st["main"]), 13, 600))
	v.add_child(ligne)
	h.add_child(v)
	_memo_hubert("conseil_cartes", h, 340.0, "Une prime, c'est un salaire qui a honte de lui.")
	return p


# ------------------------------------------------------------------ point 4 : bonus

## Ce que la résolution change pour ce joueur, avec ce qu'il sait déjà : rien sur l'état caché des rivaux.
func _pour_vous(b: Dictionary) -> Array:
	var game: GameState = m.game
	var fx: Dictionary = b.get("effets", {})
	if fx.has("attractivite_type"):
		var ty: String = fx["attractivite_type"].keys()[0]
		var n := game.animals.filter(func(a): return a.def.get("type", "") == ty).size()
		return [n > 0, "%d animal%s %s" % [n, "x" if n > 1 else "", game.type_name(ty).to_lower()] if n > 0 else "aucun animal %s" % game.type_name(ty).to_lower()]
	if fx.has("attractivite_continent"):
		var co: String = fx["attractivite_continent"].keys()[0]
		var n := game.animals.filter(func(a): return a.def.get("continent", "") == co).size()
		return [n > 0, "%d animal%s de ce continent" % [n, "x" if n > 1 else ""] if n > 0 else "aucun animal de ce continent"]
	if fx.has("visiteurs"):
		var ouvert: bool = game.zoo_status().get("open", false)
		return [ouvert, "zoo ouvert" if ouvert else "zoo fermé"]
	if fx.has("vitesse"):
		return [true, "toute l'équipe"]
	if fx.has("construire"):
		var n := game.sites.filter(func(s): return not s.done).size()
		return [n > 0, "%d chantier%s en cours" % [n, "s" if n > 1 else ""] if n > 0 else "aucun chantier en cours"]
	for k in fx:
		var tache := str(k)
		var n := game.all_employees().filter(func(c): return float(c.metier["efficacite"].get(tache, 0.0)) > 1.0 \
			or (tache.begins_with("extraire") and float(c.metier["efficacite"].get("extraire", 0.0)) > 1.0)).size()
		return [n > 0, "%d spécialiste%s dans l'équipe" % [n, "s" if n > 1 else ""] if n > 0 else "aucun spécialiste"]
	return [false, "aucun effet"]


func _ligne_resolution(n: int, b: Dictionary, preside: bool) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER if preside else GRIS_PRIS, 10, 2 if preside else 0, 14, false))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	if not preside:
		_tirets_sur(p, 10)
	var bloc := VBoxContainer.new()
	bloc.add_theme_constant_override("separation", 0)
	bloc.custom_minimum_size.x = 170
	bloc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bloc.add_child(_mono("N° %d" % n, 11, 500, UiTokens.TEXTE_2))
	bloc.add_child(_replie(_cond(str(b["nom"]), 22, UiTokens.ENCRE if preside else UiTokens.TEXTE_2)))
	h.add_child(bloc)
	var t := _replie(_corps(str(b["texte"]), 14, 600, UiTokens.ENCRE if preside else UiTokens.TEXTE_2))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	var pv := _pour_vous(b)
	h.add_child(_pilule("Pour vous : %s %s" % ["✓" if pv[0] else "—", pv[1]], Color("D8F0EC") if pv[0] else UiTokens.PAPIER, UiTokens.ENCRE, 12, true))
	if preside:
		var ad := Composants.bouton("Adopter", "BoutonPrincipal")
		ad.custom_minimum_size = Vector2(150, 44)
		ad.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ad.add_theme_font_size_override("font_size", 15)
		ad.pressed.connect(m._cmd.bind("pick_bonus", [b]))
		h.add_child(ad)
	else:
		h.add_child(_pilule("non retenue", UiTokens.PAPIER, UiTokens.ENCRE, 12, true))
	return p


func _page_bonus() -> void:
	var page: VBoxContainer = pages["bonus"]
	var mt: Match = m.mt
	var game: GameState = m.game
	var chef: int = mt.influence_leader()
	var preside: bool = chef == game.index and not m.spectator and mt.bonus_choice.is_empty()
	if preside:
		page.add_child(_replie(_corps("La résolution adoptée s'applique demain à toutes les filiales, rivaux compris.", 14, 600)))
		for k in mt.bonus_offer.size():
			page.add_child(_ligne_resolution(k + 1, mt.bonus_offer[k], true))
		var rej := Composants.bouton("Rejeter les trois résolutions", "BoutonSecondaire")
		rej.custom_minimum_size = Vector2(210, 44)
		rej.size_flags_horizontal = Control.SIZE_SHRINK_END
		rej.pressed.connect(m._cmd.bind("pick_bonus", [Match.NO_BONUS]))
		page.add_child(rej)
		page.add_child(_espace_v())
		_memo_hubert("conseil_bonus_vous", page, 0.0, "Présider, c'est décider pour les autres. Mon activité préférée.")
		return
	# Un rival préside : le joueur n'a rien à faire, on annonce la décision.
	var choix: Dictionary = mt.bonus_choice
	var bande := PanelContainer.new()
	var sb := UiTokens.panneau(UiTokens.JAUNE_CLAIR, 12, 2, 2, true)
	bande.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	bande.add_child(h)
	var gauche := PanelContainer.new()
	var sg := StyleBoxFlat.new()
	sg.bg_color = UiTokens.ENCRE
	sg.corner_radius_top_left = 10
	sg.corner_radius_bottom_left = 10
	sg.content_margin_top = 14
	sg.content_margin_bottom = 14
	gauche.add_theme_stylebox_override("panel", sg)
	gauche.custom_minimum_size.x = 240
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 4)
	gv.alignment = BoxContainer.ALIGNMENT_CENTER
	gauche.add_child(gv)
	var lg := _logo(chef, 86)
	lg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gv.add_child(lg)
	var pr := _cond("%s PRÉSIDE" % _nom_court(chef).to_upper(), 17, UiTokens.PAPIER)
	pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(pr)
	var pi := _corps("1er en influence", 13, 600, TEXTE_COLONNE)
	pi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(pi)
	h.add_child(gauche)
	var droite := MarginContainer.new()
	for c in [["left", 22], ["right", 22], ["top", 18], ["bottom", 18]]:
		droite.add_theme_constant_override("margin_" + c[0], c[1])
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(droite)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	droite.add_child(dv)
	if choix.is_empty():
		dv.add_child(_mono("DÉLIBÉRATION EN COURS", 12, 500, UiTokens.TEXTE_2))
		dv.add_child(_cond("Décision attendue", 38))
	elif choix.get("id", "") == "aucun":
		dv.add_child(_mono("AUCUNE RÉSOLUTION ADOPTÉE", 12, 500, UiTokens.TEXTE_2))
		dv.add_child(_cond("Toutes rejetées", 38))
		dv.add_child(_corps("Rien ne change demain pour les filiales.", 15, 600))
	else:
		dv.add_child(_mono("RÉSOLUTION ADOPTÉE · S'APPLIQUE DEMAIN À TOUTES LES FILIALES", 12, 500, UiTokens.TEXTE_2))
		dv.add_child(_cond(str(choix["nom"]), 38))
		dv.add_child(_replie(_corps(str(choix["texte"]), 15, 600)))
		var pv := _pour_vous(choix)
		var bh := HBoxContainer.new()
		bh.add_child(_pilule("Pour vous : %s %s" % ["✓" if pv[0] else "—", pv[1]], Color("D8F0EC") if pv[0] else UiTokens.PAPIER, UiTokens.ENCRE, 13, true))
		dv.add_child(bh)
	page.add_child(bande)
	var autres := mt.bonus_offer.filter(func(b): return b != choix)
	if not autres.is_empty():
		page.add_child(_cond("NON RETENUES" if not choix.is_empty() else "RÉSOLUTIONS PROPOSÉES", 13))
		for b in autres:
			page.add_child(_ligne_resolution(mt.bonus_offer.find(b) + 1, b, false))
	page.add_child(_espace_v())
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 16)
	_memo_hubert("conseil_bonus_rival", bas, 0.0, "Vous n'êtes pas premier en influence. Retenez la sensation : c'est celle de nos actionnaires minoritaires.")
	var aide := _replie(_corps("Pour présider : montez votre influence (lobbying à la Ville, cadres).", 13, 600, UiTokens.TEXTE_2))
	aide.custom_minimum_size.x = 260
	aide.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bas.add_child(aide)
	page.add_child(bas)


# ------------------------------------------------------------------ point 5 : équipe

func _page_equipe() -> void:
	var page: VBoxContainer = pages["equipe"]
	var game: GameState = m.game
	var equipe: Array = game.all_employees()
	_dans_l_ordre("equipe", [])  # remet la fiche à zéro à chaque nouvelle nuit
	if fiche == null or not equipe.has(fiche):
		fiche = game.level_choices[0]["card"] if not game.level_choices.is_empty() else (equipe[0] if not equipe.is_empty() else null)
		fiche_action = ""
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(h)
	var gauche := VBoxContainer.new()
	gauche.add_theme_constant_override("separation", 0)
	gauche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(gauche)
	# Direction
	var dir_c := CenterContainer.new()
	var dir_p := PanelContainer.new()
	dir_p.add_theme_stylebox_override("panel", _style_memo_cerne())
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 10)
	dir_p.add_child(dh)
	dh.add_child(_logo(game.index, 40))
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 0)
	dv.add_child(_cond("DIRECTION · FILIALE 01", 20))
	var masse := 0
	for c in equipe:
		masse += game.salary(c)
	dv.add_child(_corps("%d collaborateurs · masse salariale %d / jour" % [equipe.size(), masse], 12, 600, UiTokens.TEXTE_2))
	dh.add_child(dv)
	dir_c.add_child(dir_p)
	gauche.add_child(dir_c)
	var liens := Liens.new()
	liens.custom_minimum_size.y = 34
	gauche.add_child(liens)
	# Trois colonnes
	var defile := ScrollContainer.new()
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gauche.add_child(defile)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defile.add_child(cols)
	for cat in [["cadre", "CADRES"], ["qualifie", "QUALIFIÉS"], ["peu_qualifie", "PEU QUALIFIÉS"]]:
		var groupe := equipe.filter(func(c): return c.metier["categorie"] == cat[0])
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var e := PanelContainer.new()
		var se := StyleBoxFlat.new()
		se.bg_color = UiTokens.ENCRE
		se.set_corner_radius_all(6)
		se.set_content_margin_all(4)
		e.add_theme_stylebox_override("panel", se)
		var el := _cond("%s · %d" % [cat[1], groupe.size()], 15, UiTokens.PAPIER)
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e.add_child(el)
		v.add_child(e)
		for c in groupe:
			v.add_child(_mini_badge(c))
		cols.add_child(v)
	h.add_child(_panneau_fiche())


func _style_memo_cerne() -> StyleBoxFlat:
	var sb := UiTokens.panneau(UiTokens.MEMO, 8, 2, 10, false)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	return sb


func _a_choisir(card: GameState.Card) -> bool:
	return m.game.level_choices.any(func(lc): return lc["card"] == card)


func _mini_badge(card: GameState.Card) -> Control:
	var game: GameState = m.game
	var cat: Dictionary = UiTokens.CATEGORIES[card.metier["categorie"]]
	var choisi: bool = card == fiche
	var boite := VBoxContainer.new()
	boite.add_theme_constant_override("separation", 0)
	if _a_choisir(card):
		var etq := _pilule("▲ NIVEAU %d À CHOISIR" % card.niveau, UiTokens.SARCELLE, UiTokens.PAPIER, 10)
		etq.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		boite.add_child(etq)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 76
	var sb := UiTokens.panneau(UiTokens.PAPIER, 10, 3 if choisi else 2, 8, true, UiTokens.SELECTION if choisi else UiTokens.ENCRE)
	var sh: StyleBoxFlat = sb.duplicate()
	sh.bg_color = UiTokens.JAUNE_CLAIR
	for k in [["normal", sb], ["hover", sh], ["pressed", sh]]:
		b.add_theme_stylebox_override(k[0], k[1])
	b.tooltip_text = m._card_full_tooltip(card)
	b.pressed.connect(func():
		fiche = card
		fiche_action = ""
		rafraichir())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -10
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var cadre := PanelContainer.new()
	var sc := StyleBoxFlat.new()
	sc.bg_color = cat["portrait"]
	sc.border_color = UiTokens.ENCRE
	sc.set_border_width_all(2)
	sc.set_corner_radius_all(6)
	cadre.add_theme_stylebox_override("panel", sc)
	cadre.custom_minimum_size = Vector2(48, 58)
	cadre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cadre.clip_contents = true
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cadre.add_child(Composants.portrait_rect(game.perso_of(card)["id"], Vector2(44, 54)))
	h.add_child(cadre)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nm := _cond(card.nom.to_upper(), 19)
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	var met := _corps(game.job_name(card), 12, 600, UiTokens.TEXTE_2)
	met.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(met)
	h.add_child(v)
	var niv := Composants.pastille_niveau(card.niveau)
	niv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(niv)
	boite.add_child(b)
	return boite


func _panneau_fiche() -> Control:
	var game: GameState = m.game
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 12, 2, 2, false))
	p.custom_minimum_size.x = 334
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	if fiche == null or m.spectator:
		return p
	var cat: Dictionary = UiTokens.CATEGORIES[fiche.metier["categorie"]]
	var id := PanelContainer.new()
	var si := StyleBoxFlat.new()
	si.bg_color = Color(cat["portrait"], 0.45)
	si.corner_radius_top_left = 10
	si.corner_radius_top_right = 10
	si.border_color = UiTokens.ENCRE
	si.border_width_bottom = 2
	si.set_content_margin_all(12)
	id.add_theme_stylebox_override("panel", si)
	var ih := HBoxContainer.new()
	ih.add_theme_constant_override("separation", 10)
	id.add_child(ih)
	var cadre := PanelContainer.new()
	var sc := StyleBoxFlat.new()
	sc.bg_color = cat["portrait"]
	sc.border_color = UiTokens.ENCRE
	sc.set_border_width_all(2)
	sc.set_corner_radius_all(6)
	cadre.add_theme_stylebox_override("panel", sc)
	cadre.custom_minimum_size = Vector2(66, 80)
	cadre.clip_contents = true
	cadre.add_child(Composants.portrait_rect(game.perso_of(fiche)["id"], Vector2(62, 76)))
	ih.add_child(cadre)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 0)
	iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	iv.add_child(_cond(fiche.nom.to_upper(), 24))
	iv.add_child(_replie(_corps(game.job_name(fiche), 13, 700)))
	iv.add_child(_mono("Niv. %d · XP %d / %d" % [fiche.niveau, floori(fiche.xp), ceili(game.xp_next_level(fiche))] if fiche.niveau < 6 else "Niv. 6 · légendaire", 12, 500))
	ih.add_child(iv)
	v.add_child(id)
	var defile := ScrollContainer.new()
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(defile)
	var marge := MarginContainer.new()
	for c in [["left", 12], ["right", 12], ["top", 12], ["bottom", 12]]:
		marge.add_theme_constant_override("margin_" + c[0], c[1])
	marge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defile.add_child(marge)
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 8)
	marge.add_child(c)
	# Traits et améliorations
	for tr in game.trait_defs(fiche):
		c.add_child(_ligne_trait(tr))
	for u in fiche.upgrade_names:
		c.add_child(_replie(_corps("★ %s" % u, 12, 600, UiTokens.SARCELLE_FONCE)))
	# Montée de niveau : gratuite
	for lc in game.level_choices:
		if lc["card"] == fiche:
			c.add_child(_cond("CHOISIR UNE AMÉLIORATION · OFFERTE", 13))
			for opt in lc["options"]:
				c.add_child(_bouton_option(opt, "", m._cmd.bind("choose_level_upgrade", [fiche, opt])))
			break
	var filet := ColorRect.new()
	filet.color = UiTokens.FILET
	filet.custom_minimum_size.y = 1
	c.add_child(filet)
	# Une action payante par nuit (à partir du milieu de partie)
	var regles := game.night_action_rules()
	var cout_up := int(regles["cout_amelioration"])
	var cout_vire := int(regles["cout_licenciement"])
	var err_up := game.night_action_error(cout_up)
	var err_vire := game.night_action_error(cout_vire)
	var raison := func(err: String, cout: int) -> String:
		if err == "":
			return ""
		if "à partir" in err:
			return "À partir du jour %d" % int(regles["jour_min"])
		if "Pas assez" in err:
			return "Manque %d argent" % ceili(cout - game.money)
		if "Déjà" in err:
			return "Déjà une action cette nuit"
		return m._short_reason(err)
	var up := _bouton_ou_raison("", raison.call(err_up, cout_up), err_up, func(): pass, 42.0)
	if err_up == "":
		up = Composants.bouton("Améliorer · %d" % cout_up, "BoutonSecondaire")
		up.custom_minimum_size.y = 42
		up.pressed.connect(func():
			fiche_action = "" if fiche_action == "ameliorer" else "ameliorer"
			rafraichir())
	else:
		up.text = "Améliorer · %s" % up.text
	c.add_child(up)
	if fiche_action == "ameliorer" and err_up == "":
		for opt in game.upgrade_options(fiche):
			c.add_child(_bouton_option(opt, "%d" % cout_up, func():
				m._cmd("apply_upgrade", [fiche, opt])
				fiche_action = ""))
	# Licencier : le DRH offre le licenciement ; sinon, c'est payant
	if game.drh_available > 0:
		var vb := Composants.bouton("Licencier · gratuit avec un DRH", "BoutonSecondaire")
		vb.custom_minimum_size.y = 42
		vb.pressed.connect(func():
			fiche_action = "" if fiche_action == "virer_drh" else "virer_drh"
			rafraichir())
		c.add_child(vb)
		if fiche_action == "virer_drh":
			var ok := Composants.bouton("Confirmer le licenciement", "BoutonPrincipal")
			ok.custom_minimum_size.y = 42
			ok.pressed.connect(func():
				m._cmd("fire", [fiche])
				fiche_action = "")
			c.add_child(ok)
	else:
		var vb := _bouton_ou_raison("", raison.call(err_vire, cout_vire), err_vire, func(): pass, 42.0)
		if err_vire == "":
			vb = Composants.bouton("Licencier · %d" % cout_vire, "BoutonSecondaire")
			vb.custom_minimum_size.y = 42
			vb.pressed.connect(func():
				fiche_action = "" if fiche_action == "licencier" else "licencier"
				rafraichir())
		else:
			vb.text = "Licencier · %s" % vb.text
		c.add_child(vb)
		if fiche_action == "licencier" and err_vire == "":
			var ok := Composants.bouton("Confirmer le licenciement · %d" % cout_vire, "BoutonPrincipal")
			ok.custom_minimum_size.y = 42
			ok.pressed.connect(func():
				m._cmd("fire_paid", [fiche])
				fiche_action = "")
			c.add_child(ok)
	return p


func _bouton_option(opt: Dictionary, prix: String, action: Callable) -> Button:
	var texte := "%s · %s" % [opt["nom"], opt.get("texte", m._effect_text(opt["effet"]))]
	if prix != "":
		texte = "%s (%s)" % [texte, prix]
	var b := Composants.bouton(texte, "BoutonSecondaire")
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size.x = 280
	b.pressed.connect(action)
	return b


# ------------------------------------------------------------------ fenêtre Classement · Objectifs · Journal

func _construire_journal() -> void:
	fenetre_journal = ColorRect.new()
	fenetre_journal.color = Color(UiTokens.ENCRE, 0.55)
	fenetre_journal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fenetre_journal.mouse_filter = Control.MOUSE_FILTER_STOP
	fenetre_journal.visible = false
	add_child(fenetre_journal)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fenetre_journal.add_child(centre)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.FOND_FENETRE, 12, 2, 18, true))
	p.custom_minimum_size = Vector2(1180, 660)
	centre.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var tete := HBoxContainer.new()
	var tt := _cond("Classement · Objectifs · Journal", 30)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(tt)
	var fermer := Composants.bouton("✕", "BoutonSecondaire")
	fermer.custom_minimum_size = Vector2(40, 40)
	fermer.pressed.connect(func(): fenetre_journal.visible = false)
	tete.add_child(fermer)
	v.add_child(tete)
	journal_corps = HBoxContainer.new()
	journal_corps.add_theme_constant_override("separation", 16)
	journal_corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(journal_corps)


func _rendre_journal() -> void:
	_clear(journal_corps)
	var mt: Match = m.mt
	var game: GameState = m.game
	var r: Dictionary = game.night_report
	var s: Dictionary = r["stats"]
	var inc: Dictionary = r["income"]
	var cols := []
	for k in 3:
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(col)
		journal_corps.add_child(sc)
		cols.append(col)
	# Classement
	cols[0].add_child(_cond("RÉPUTATION · VICTOIRE À %d" % game.objective(), 16))
	var ordre := range(mt.players.size())
	ordre.sort_custom(func(a, b): return mt.players[a].reputation() > mt.players[b].reputation())
	for k in ordre.size():
		var i: int = ordre[k]
		var ligne := PanelContainer.new()
		ligne.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.JAUNE_CLAIR if i == game.index else UiTokens.PAPIER, 8, 2 if i == game.index else 1, 8, false))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		ligne.add_child(hb)
		hb.add_child(_mono(str(k + 1), 14))
		hb.add_child(_logo(i, 28))
		var nm := _corps(str(mt.names[i]), 14, 800)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hb.add_child(nm)
		var rep: int = mt.players[i].reputation()
		hb.add_child(_mono(str(rep), 18))
		var delta: int = rep - m._rep_on_night(i, -2)
		var dl := _mono("%s%+d" % ["▲" if delta >= 0 else "▼", delta], 12, 500, UiTokens.SARCELLE_FONCE if delta >= 0 else UiTokens.NEGATIF)
		hb.add_child(dl)
		cols[0].add_child(ligne)
	cols[0].add_child(_espace_v())
	cols[0].add_child(_cond("OBJECTIFS DES ACTIONNAIRES", 16))
	for o in mt.objectifs:
		var fait: bool = game.objectifs_faits.has(o["id"])
		cols[0].add_child(_replie(_corps(("✓ " if fait else "○ ") + "%s (%s)" % [o["texte"], "fait" if fait else "%d / %d" % [mini(game.objectif_valeur(o), int(o["n"])), int(o["n"])]],
			13, 600, UiTokens.SARCELLE_FONCE if fait else UiTokens.ENCRE)))
	# Compte de résultat
	cols[1].add_child(_cond("COMPTE DE RÉSULTAT · JOUR %d" % mt.day, 16))
	var sal := roundi(float(s.get("salaires", 0.0)))
	var food := roundi(float(s.get("nourriture", 0.0)))
	var lignes := [["Visiteurs", str(inc["visitors"]), 0], ["Billetterie", "▲ +%d" % inc["tickets"], 1], ["Souvenirs", "▲ +%d" % inc["souvenirs"], 1], ["Salaires", "▼ −%d" % sal, -1], ["Nourriture des animaux", "▼ −%d" % food, -1]]
	if float(s.get("cedees", 0.0)) > 0.0:
		lignes.append(["Journées cédées", "▲ +%d" % roundi(float(s["cedees"])), 1])
	for res in ["bois", "pierre", "or"]:
		if float(s[res]) >= 1.0:
			lignes.append(["%s rapporté" % UiTokens.RESSOURCES[res]["nom"], "+%d" % floori(s[res]), 0])
	if float(s["influence"]) > 0.0:
		lignes.append(["Influence gagnée", "+%.1f" % s["influence"], 0])
	lignes.append(["Réputation (fréquentation)", "▲ +%.1f" % inc["rep_gain"], 1])
	if float(inc.get("rep_spectacle", 0.0)) > 0.05:
		lignes.append(["Réputation (spectacles, boutique)", "▲ +%.1f" % inc["rep_spectacle"], 1])
	if r.has("prestige"):
		lignes.append(["Prestige politique (influence)", "▲ +%.1f" % r["prestige"], 1])
	for nm in r.get("legendes", []):
		lignes.append(["%s devient légendaire" % nm, "▲ +%d" % int(game.data["buildings"]["reputation_autres"]["legendaire"]), 1])
	for l in lignes:
		var hb := HBoxContainer.new()
		var t := _corps(l[0], 13, 600)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(t)
		hb.add_child(_mono(l[1], 13, 600, UiTokens.SARCELLE_FONCE if l[2] > 0 else (UiTokens.NEGATIF if l[2] < 0 else UiTokens.ENCRE)))
		cols[1].add_child(hb)
	var filet := ColorRect.new()
	filet.color = UiTokens.ENCRE
	filet.custom_minimum_size.y = 2
	cols[1].add_child(filet)
	var b := _bilan()
	var ht := HBoxContainer.new()
	var tt := _corps("Total de la journée", 15, 800)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ht.add_child(tt)
	ht.add_child(_mono("%s %+d" % ["▲" if b["total"] >= 0 else "▼", b["total"]], 20))
	cols[1].add_child(ht)
	if not inc["open"]:
		cols[1].add_child(_replie(_corps("Zoo fermé : %s" % inc["reason"], 13, 700, UiTokens.NEGATIF)))
	# Journal
	cols[2].add_child(_cond("JOURNAL DE LA NUIT", 16))
	var texte: Array[String] = []
	for nm in r["arrivals"]:
		texte.append("Arrivée au zoo : %s" % nm)
	for nm in r.get("malades", []):
		texte.append("■ Malade : %s (envoyez un Soigneur dans son enclos)" % nm)
	if inc["visitors"] > 0:
		texte.append("%d visiteurs (%d repartis faute de place), %.1f présents en moyenne%s" % [inc["visitors"], inc["lost"], inc["avg_present"],
			" · affinités +%d %%" % roundi(inc.get("affinity", 0.0) * 100) if inc.get("affinity", 0.0) > 0.0 else ""])
	texte.append("%d collaborateur(s) mobilisé(s) aujourd'hui" % r["deployed"])
	for l in mt.log:
		texte.append(str(l))
	if game.employees() >= game.housing():
		texte.append("Logement plein (%d / %d) : construisez une maison de collaborateurs pour embaucher." % [game.employees(), game.housing()])
	for l in texte:
		cols[2].add_child(_replie(_corps(l, 13, 500)))


func _nouvelle_nuit() -> void:
	fiche = null
	fiche_action = ""


func _pied_collaborateur(t: VBoxContainer, card: GameState.Card) -> void:
	var game: GameState = m.game
	# Cabinet de recrutement, Hippopotame
	var cabinet: bool = (game.has_building("cabinet") or game.rare_effects().any(func(e): return e.get("echange", false))) and not m.spectator
	if cabinet:
		var rc := Composants.bouton("Remplacer · Cabinet", "BoutonSecondaire")
		rc.add_theme_font_size_override("font_size", 12)
		rc.custom_minimum_size.y = 30
		rc.disabled = game.hippo_error() != "" and game.recruit_error("peu_qualifie") != "" and game.recruit_error("cadre") != "" and game.recruit_error("qualifie") != ""
		rc.pressed.connect(m._open_recruit.bind(card))
		t.add_child(rc)
	var err: String = "Mode spectateur" if m.spectator else game.hire_error(card)
	var cout := game.hire_cost(card)
	var court := ""
	if err != "":
		court = "Manque %d argent" % ceili(cout - game.money) if "assez" in err else ("En attente de votre tour" if "pas votre tour" in err else m._short_reason(err))
	t.add_child(_bouton_ou_raison("Embaucher · %d" % cout, court, err, m._cmd.bind("hire", [card]), 40.0))


func _pied_carte(t: VBoxContainer, card: GameState.Card) -> void:
	var game: GameState = m.game
	var err: String = "Mode spectateur" if m.spectator else game.action_error(card)
	var prix := game.action_price(card)
	var court := ""
	if err != "":
		court = "Manque %d argent" % ceili(prix - game.money) if "assez" in err else ("En attente de votre tour" if "pas votre tour" in err else ("Carte déjà achetée" if "Déjà" in err else m._short_reason(err)))
	t.add_child(_bouton_ou_raison("Acheter · %d" % prix, court, err, m._cmd.bind("buy_action", [card]), 44.0))
