class_name FenetreDefis
extends Control
## Page des défis (docs/handoff_menus, maquettes 30 à 34) : fenêtre 1280 × 700 en deux colonnes.
## À gauche, le défi de la semaine en grand (compte à rebours, record, rang, vainqueur de la semaine passée et son
## replay, le seul public), puis les 4 défis permanents en cartes. À droite, la cote du défi choisi : votre rang, le
## top 10 façon cours de bourse et votre ligne. Le top 10 est visible par tous, pseudos compris ; un joueur hors du
## top 10 n'est jamais montré aux autres (le serveur ne renvoie que le top 10 et la ligne du joueur).
## États : chargement (squelettes), classé, hors du top 10, jamais joué, hors ligne.
## Captures : --defis [--defis-demo=hors_top|top|jamais|indispo|charge] [--defis-choix=<id>].

signal jouer(id: String)
signal revoir(replay: Dictionary)  # replay du vainqueur de la semaine passée

const L := 1280.0
const H := 700.0
const CORPS_Y := 80.0
const PODIUM := [Color("FFC93C"), Color("D5D9DE"), Color("E2A06A")]

var choisi := ""  # identifiant du défi dont la cote est ouverte (le défi de la semaine par défaut)
var classement: Classement
var resultats := {}  # id -> classement lu sur le serveur ({} tant qu'il n'est pas arrivé)
var hors_ligne := false
var chargement := true
var vainqueur := {}
var demo := ""

var fenetre: Panel
var corps: Control
var cote: PanelContainer
var avertissement: HBoxContainer
var cartes := {}  # id -> {"racine", "anneau", "bouton", "rang", ...}
var _rebours: Label


func _ready() -> void:
	Statistiques.charger()
	theme = UiTokens.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--defis-demo="):
			demo = a.trim_prefix("--defis-demo=")
		elif a.begins_with("--defis-choix="):
			choisi = a.trim_prefix("--defis-choix=")
	if choisi == "" or Defis.trouver(choisi).is_empty():
		choisi = str(Defis.semaine()["id"])
	classement = Classement.new()
	add_child(classement)
	var voile := ColorRect.new()
	voile.color = Color(UiTokens.ENCRE, 0.55)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)
	fenetre = Panel.new()
	fenetre.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.FOND_FENETRE, 12, 2, 0, true))
	fenetre.set_anchors_preset(Control.PRESET_CENTER)
	fenetre.offset_left = -L / 2.0
	fenetre.offset_right = L / 2.0
	fenetre.offset_top = -H / 2.0
	fenetre.offset_bottom = H / 2.0
	fenetre.clip_contents = false
	add_child(fenetre)
	_entete()
	corps = Control.new()
	corps.position = Vector2(0, CORPS_Y)
	corps.size = Vector2(L, H - CORPS_Y)
	corps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fenetre.add_child(corps)
	_construire()
	_charger()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		queue_free()
		accept_event()


func _process(_d: float) -> void:
	if is_instance_valid(_rebours) and Engine.get_process_frames() % 60 == 0:
		_rebours.text = _texte_rebours()


# ---------------------------------------------------------------- en-tête

func _entete() -> void:
	var tete := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = UiTokens.PAPIER
	st.corner_radius_top_left = 11
	st.corner_radius_top_right = 11
	st.border_color = UiTokens.ENCRE
	st.border_width_bottom = 2
	tete.add_theme_stylebox_override("panel", st)
	Composants.placer(fenetre, tete, Vector2(2, 2), Vector2(L - 4, CORPS_Y - 2))
	var jours := int(Defis.donnees()["jours"])
	Composants.placer(tete, Composants.texte("LA MÊME PARTIE POUR TOUS · %d JOURS · SEUL CONTRE LES 3 MEILLEURES IA" % jours, 12, 600, UiTokens.TEXTE_2, "mono"),
		Vector2(20, 12), Vector2(700, 18))
	Composants.placer(tete, Composants.texte("Défis", 34, 800, UiTokens.ENCRE, "titre"), Vector2(20, 30), Vector2(120, 40))
	Composants.placer(tete, Composants.texte("Même carte, même draft, mêmes collaborateurs et même marché pour tous. Score : votre réputation au soir du jour %d." % jours,
		13, 600, UiTokens.TEXTE_2), Vector2(148, 44), Vector2(860, 20))
	avertissement = HBoxContainer.new()
	avertissement.add_theme_constant_override("separation", 6)
	avertissement.alignment = BoxContainer.ALIGNMENT_END
	avertissement.add_child(Composants.Forme.new("triangle", UiTokens.NEGATIF, 11.0))
	avertissement.add_child(Composants.texte("Hors ligne : classements indisponibles", 12, 600, UiTokens.NEGATIF, "mono"))
	avertissement.visible = false
	Composants.placer(tete, avertissement, Vector2(860, 28), Vector2(340, 20))
	var x := Composants.bouton("✕", "BoutonSecondaire")
	x.add_theme_font_size_override("font_size", 18)
	x.pressed.connect(queue_free)
	Composants.placer(tete, x, Vector2(L - 4 - 60, 18), Vector2(40, 40))


# ---------------------------------------------------------------- corps

func _construire() -> void:
	for e in corps.get_children():
		corps.remove_child(e)
		e.queue_free()
	cartes.clear()
	avertissement.visible = hors_ligne
	corps.add_child(_heros())
	var titre := HBoxContainer.new()
	titre.add_theme_constant_override("separation", 12)
	titre.add_child(Composants.texte("DÉFIS PERMANENTS", 14, 800, UiTokens.ENCRE, "titre"))
	var sous := Composants.texte("toujours ouverts · un classement chacun", 12, 600, UiTokens.TEXTE_2)
	sous.size_flags_vertical = Control.SIZE_SHRINK_END
	titre.add_child(sous)
	Composants.placer(corps, titre, Vector2(20, 282), Vector2(740, 24))
	var defis: Array = Defis.donnees()["defis"]
	var lc := (740.0 - 12.0 * (defis.size() - 1)) / maxf(1, defis.size())
	for k in defis.size():
		var c := _carte_defi(defis[k])
		Composants.placer(corps, c, Vector2(20 + k * (lc + 12.0), 314), Vector2(lc, 284))
	cote = _cote()
	Composants.placer(corps, cote, Vector2(778, 20), Vector2(462, 579))
	_maj_selection()


## Cadre de sélection : anneau jaune de 4 px autour de la carte choisie, dessiné derrière elle.
func _anneau(parent: Control, rayon: int) -> Panel:
	var a := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = UiTokens.SELECTION
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(rayon + 4)
	sb.anti_aliasing = true
	a.add_theme_stylebox_override("panel", sb)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.show_behind_parent = true
	a.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	a.offset_left = -4
	a.offset_top = -4
	a.offset_right = 4
	a.offset_bottom = 8
	a.visible = false
	parent.add_child(a)
	return a


func _heros() -> Control:
	var d := Defis.semaine()
	var id := str(d["id"])
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 0, true))
	p.position = Vector2(20, 20)
	p.size = Vector2(740, 252)
	p.gui_input.connect(func(e): _clic_carte(e, id))
	var anneau := _anneau(p, 10)
	# Bandeau jaune
	var bandeau := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.SELECTION
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.border_color = UiTokens.ENCRE
	sb.border_width_bottom = 2
	bandeau.add_theme_stylebox_override("panel", sb)
	bandeau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Composants.placer(p, bandeau, Vector2(2, 2), Vector2(736, 40))
	Composants.placer(bandeau, Composants.texte(("Défi de la semaine du " + Composants.date_semaine()).to_upper(), 22, 800, UiTokens.ENCRE, "titre"),
		Vector2(14, 6), Vector2(500, 28))
	var prochain := Composants.texte("nouveau défi lundi " + Composants.date_semaine(Defis.numero_semaine() + 1), 12, 600, UiTokens.ENCRE, "mono")
	prochain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Composants.placer(bandeau, prochain, Vector2(436, 11), Vector2(286, 18))
	# Vignette
	var vign := Composants.vignette_carte(Composants.texture_carte(GameData.load_all(), int(d["graine"]), str(d["mode"])), 142)
	Composants.placer(p, vign, Vector2(16, 56), Vector2(142, 142))
	# Colonne du milieu
	var m := VBoxContainer.new()
	m.add_theme_constant_override("separation", 0)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Composants.placer(p, m, Vector2(174, 56), Vector2(330, 140))
	m.add_child(Composants.pastille_mode(str(d["mode"]), true))
	m.add_child(_espace(6))
	m.add_child(Composants.texte("Carte n° %d · %d jours · 3 IA en Difficile" % [int(d["graine"]), int(Defis.donnees()["jours"])], 12, 600, UiTokens.TEXTE_2))
	m.add_child(_espace(12))
	m.add_child(Composants.texte("SE TERMINE DANS", 12, 600, UiTokens.TEXTE_2, "mono"))
	_rebours = Composants.texte(_texte_rebours(), 30, 600, UiTokens.ENCRE, "mono")
	m.add_child(_rebours)
	m.add_child(Composants.texte(_texte_fin(), 12, 600, UiTokens.TEXTE_2))
	# Colonne de droite : record, parties, rang, Jouer
	var r := VBoxContainer.new()
	r.add_theme_constant_override("separation", 4)
	Composants.placer(p, r, Vector2(528, 56), Vector2(196, 140))
	var s := _stats_locales(id)
	r.add_child(_ligne_chiffre("Votre record", str(roundi(float(s["meilleur"]))) if not s.is_empty() else "—", 18))
	r.add_child(_ligne_chiffre("Parties", str(int(s.get("parties", 0)))))
	var rang := _ligne_chiffre("Rang", "")
	r.add_child(rang)
	r.add_child(_espace(4))
	var j := Composants.bouton("JOUER LE DÉFI ›", "BoutonPrincipal")
	j.add_theme_font_override("font", UiTokens.police_titre())
	j.add_theme_font_size_override("font_size", 19)
	j.custom_minimum_size.y = 44
	j.pressed.connect(func(): _jouer(id))
	r.add_child(j)
	# Pied : vainqueur de la semaine passée
	var passe := Panel.new()
	var sp := StyleBoxFlat.new()
	sp.bg_color = UiTokens.MEMO
	sp.border_color = UiTokens.ENCRE
	sp.border_width_top = 2
	sp.corner_radius_bottom_left = 9
	sp.corner_radius_bottom_right = 9
	passe.add_theme_stylebox_override("panel", sp)
	passe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Composants.placer(p, passe, Vector2(2, 252 - 46), Vector2(736, 44))
	var hp := HBoxContainer.new()
	hp.add_theme_constant_override("separation", 8)
	Composants.placer(passe, hp, Vector2(14, 6), Vector2(708, 32))
	var etoile := Composants.Forme.new("etoile", UiTokens.SELECTION, 14.0)
	etoile.contour = UiTokens.ENCRE
	hp.add_child(etoile)
	var pd := Defis.semaine(Defis.numero_semaine() - 1)
	if vainqueur.is_empty():
		hp.add_child(Composants.texte("Semaine du %s · %s" % [Composants.date_semaine(Defis.numero_semaine() - 1),
			"pas de vainqueur connu" if not chargement or hors_ligne else "vainqueur…"], 13, 600, UiTokens.TEXTE_2))
	else:
		hp.add_child(Composants.texte("Semaine du %s · vainqueur :" % Composants.date_semaine(Defis.numero_semaine() - 1), 13, 600, UiTokens.TEXTE_2))
		hp.add_child(Composants.texte(str(vainqueur["pseudo"]), 13, 800))
		hp.add_child(Composants.texte("·", 13, 600, UiTokens.TEXTE_2))
		hp.add_child(Composants.texte(str(roundi(float(vainqueur["score"]))), 13, 600, UiTokens.ENCRE, "mono"))
		hp.add_child(Composants.texte("· " + ("Réserve naturelle" if str(pd["mode"]) == "nature" else "Partie classique"), 13, 600))
		var esp := Control.new()
		esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hp.add_child(esp)
		var b := Composants.bouton("▶ Revoir sa partie", "BoutonMini")
		b.custom_minimum_size.y = 28
		b.pressed.connect(_revoir_vainqueur)
		hp.add_child(b)
	for c in hp.get_children():
		if c is Label:
			c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cartes[id] = {"racine": p, "anneau": anneau, "rang": rang.get_meta("valeur")}
	_maj_rang_carte(id)
	return p


func _carte_defi(d: Dictionary) -> Control:
	var id := str(d["id"])
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 0, true))
	p.gui_input.connect(func(e): _clic_carte(e, id))
	var anneau := _anneau(p, 10)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 10
	v.offset_right = -10
	v.offset_top = 10
	v.offset_bottom = -10
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var vign := Composants.vignette_carte(Composants.texture_carte(GameData.load_all(), int(d["graine"]), str(d["mode"])), 76)
	vign.size_flags_horizontal = Control.SIZE_FILL
	(vign.get_node("Image") as TextureRect).custom_minimum_size = Vector2(0, 72)
	v.add_child(vign)
	var t := Composants.texte(str(d["nom"]).to_upper(), 19, 800, UiTokens.ENCRE, "titre")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size.y = 40
	t.add_theme_constant_override("line_spacing", -4)
	v.add_child(t)
	v.add_child(Composants.pastille_mode(str(d["mode"]), true))
	var s := _stats_locales(id)
	var lignes := VBoxContainer.new()
	lignes.add_theme_constant_override("separation", 3)
	v.add_child(lignes)
	var rang: Label
	if s.is_empty():
		lignes.add_child(_ligne_chiffre("Pas encore joué", ""))
		var part := _ligne_chiffre("Participants", "")
		lignes.add_child(part)
		rang = part.get_meta("valeur")
	else:
		lignes.add_child(_ligne_chiffre("Record", str(roundi(float(s["meilleur"])))))
		lignes.add_child(_ligne_chiffre("Parties", str(int(s["parties"]))))
		var lr := _ligne_chiffre("Rang", "")
		lignes.add_child(lr)
		rang = lr.get_meta("valeur")
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(esp)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	v.add_child(h)
	var bc := Composants.bouton("Classement", "BoutonMini")
	bc.custom_minimum_size.y = 28
	bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bc.toggle_mode = true
	bc.pressed.connect(func(): _choisir(id))
	h.add_child(bc)
	var bj := Composants.bouton("JOUER", "BoutonPrincipal")
	bj.add_theme_font_override("font", UiTokens.police_titre())
	bj.add_theme_font_size_override("font_size", 14)
	bj.custom_minimum_size = Vector2(58, 28)
	bj.pressed.connect(func(): _jouer(id))
	h.add_child(bj)
	cartes[id] = {"racine": p, "anneau": anneau, "bouton": bc, "rang": rang, "joue": not s.is_empty()}
	_maj_rang_carte(id)
	return p


## Ligne « libellé ……… valeur » (valeur en mono, gardée en méta pour la remplir plus tard).
func _ligne_chiffre(lib: String, val: String, taille := 14) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Composants.texte(lib, 13, 600, UiTokens.TEXTE_2)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var v := Composants.texte(val, taille, 600, UiTokens.ENCRE, "mono")
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	h.set_meta("valeur", v)
	return h


## Rang ou nombre de participants d'une carte, d'après le classement reçu (squelette pendant le chargement).
func _maj_rang_carte(id: String) -> void:
	var c: Dictionary = cartes.get(id, {})
	if c.is_empty():
		return
	var l: Label = c["rang"]
	var r: Dictionary = resultats.get(id, {})
	for e in l.get_children():
		e.queue_free()
	if hors_ligne:
		l.text = "hors ligne" if id == str(Defis.semaine()["id"]) else "—"
	elif r.is_empty():
		l.text = "        "
		var sq := _squelette(Vector2(54, 12))
		sq.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		sq.offset_left = -54
		sq.offset_top = -6
		sq.offset_bottom = 6
		l.add_child(sq)
	elif not c.get("joue", true) and c.has("bouton"):
		l.text = str(int(r.get("total", 0)))
	elif r.get("rang") == null:
		l.text = "— sur %d" % int(r.get("total", 0))
	else:
		l.text = "%s sur %d" % [Composants.rang_texte(int(r["rang"])), int(r["total"])] if not c.has("bouton") else "%s / %d" % [Composants.rang_texte(int(r["rang"])), int(r["total"])]


func _clic_carte(e: InputEvent, id: String) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_choisir(id)


func _choisir(id: String) -> void:
	choisi = id
	_maj_selection()
	var nouvelle := _cote()
	Composants.placer(corps, nouvelle, Vector2(778, 20), Vector2(462, 579))
	cote.queue_free()
	cote = nouvelle


func _maj_selection() -> void:
	for id in cartes:
		var c: Dictionary = cartes[id]
		(c["anneau"] as Panel).visible = id == choisi
		if c.has("bouton"):
			var b: Button = c["bouton"]
			b.set_pressed_no_signal(id == choisi)
			b.add_theme_stylebox_override("pressed", _style_encre())
			b.add_theme_color_override("font_pressed_color", UiTokens.PAPIER)
			b.add_theme_color_override("font_hover_pressed_color", UiTokens.PAPIER)
			b.add_theme_stylebox_override("hover_pressed", _style_encre())


func _style_encre() -> StyleBoxFlat:
	var s := UiTokens.panneau(UiTokens.ENCRE, 6, 2, 5, true)
	s.content_margin_left = 10
	s.content_margin_right = 10
	return s


# ---------------------------------------------------------------- cote

func _cote() -> PanelContainer:
	var d := Defis.trouver(choisi)
	var r: Dictionary = resultats.get(choisi, {})
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 2, true))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var nom := str(d.get("nom", ""))
	if d.has("semaine"):
		nom = "Défi de la semaine du " + Composants.date_semaine(int(d["semaine"]))
	var droite := "hors ligne" if hors_ligne else ("…" if r.is_empty() else "%d participant%s" % [int(r.get("total", 0)), "s" if int(r.get("total", 0)) > 1 else ""])
	var e := Composants.entete_comite("Cote · " + nom, droite, UiTokens.ENCRE)
	var pc: PanelContainer = e["racine"]
	var sb: StyleBoxFlat = pc.get_theme_stylebox("panel").duplicate()
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	pc.add_theme_stylebox_override("panel", sb)
	(e["titre"] as Label).add_theme_font_size_override("font_size", 15)
	(e["droite"] as Label).add_theme_color_override("font_color", UiTokens.SELECTION)
	v.add_child(pc)
	var s := _stats_locales(choisi)
	if hors_ligne:
		_cote_hors_ligne(v, s)
		return p
	v.add_child(_bloc_rang(r, s))
	var liste := VBoxContainer.new()
	liste.add_theme_constant_override("separation", 0)
	liste.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_espace(6))
	v.add_child(liste)
	if r.is_empty():
		for k in 10:
			liste.add_child(_ligne_cote(k + 1, null, 0.0, 0.0, false))
	else:
		var top: Array = r.get("top", [])
		var maxi := float(top[0]["score"]) if not top.is_empty() else 1.0
		if top.is_empty():
			var l := Composants.paragraphe("Personne n'est encore classé sur ce défi : le premier score prendra la tête.", 14, UiTokens.TEXTE_2)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			liste.add_child(_espace(40))
			liste.add_child(l)
		for t in top:
			liste.add_child(_ligne_cote(int(t["rang"]), t, float(t["score"]), maxi, bool(t.get("moi", false))))
		var dans_top := top.any(func(t): return bool(t.get("moi", false)))
		if not dans_top:
			var pts := Composants.texte("⋯", 16, 700, UiTokens.TEXTE_2, "mono")
			pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pts.custom_minimum_size.y = 22
			liste.add_child(pts)
			if r.get("rang") != null:
				liste.add_child(_ligne_vous(int(r["rang"]), float(r["score"]), maxi))
			else:
				liste.add_child(_ligne_jamais())
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(esp)
	var pied := Composants.paragraphe("Top 10 public ; au-delà, chacun ne voit que sa propre ligne. Les parties restent privées, sauf celle du vainqueur de la semaine passée.",
		12, UiTokens.TEXTE_2)
	pied.custom_minimum_size.x = 430
	var mp := MarginContainer.new()
	for c in [["left", 14], ["right", 14], ["bottom", 10]]:
		mp.add_theme_constant_override("margin_" + c[0], c[1])
	mp.add_child(pied)
	v.add_child(mp)
	return p


## Bloc « Votre rang / Votre record » sous le bandeau de la cote.
func _bloc_rang(r: Dictionary, s: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.FOND_FENETRE
	sb.border_color = UiTokens.ENCRE
	sb.border_width_bottom = 2
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	p.add_child(h)
	var g := VBoxContainer.new()
	g.add_theme_constant_override("separation", 2)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(g)
	g.add_child(Composants.texte("VOTRE RANG", 12, 600, UiTokens.TEXTE_2, "mono"))
	var lg := HBoxContainer.new()
	lg.add_theme_constant_override("separation", 8)
	g.add_child(lg)
	var d := VBoxContainer.new()
	d.add_theme_constant_override("separation", 2)
	h.add_child(d)
	if r.is_empty():
		lg.add_child(_squelette(Vector2(60, 40)))
		var rec := Composants.texte(("record %d · %d partie%s" % [roundi(float(s["meilleur"])), int(s["parties"]), "s" if int(s["parties"]) > 1 else ""]) if not s.is_empty() else "pas encore joué", 14, 600)
		rec.size_flags_vertical = Control.SIZE_SHRINK_END
		lg.add_child(rec)
		var c := Composants.texte("cotation en cours…", 14, 500, UiTokens.TEXTE_2, "mono")
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		d.add_child(_espace(14))
		d.add_child(c)
		return p
	var total := int(r.get("total", 0))
	if r.get("rang") == null:
		lg.add_child(Composants.texte("—", 40, 600, UiTokens.ENCRE, "mono"))
	else:
		lg.add_child(Composants.texte(Composants.rang_texte(int(r["rang"])), 40, 600, UiTokens.ENCRE, "mono"))
	var sur := Composants.texte("sur %d" % total, 14, 600)
	sur.size_flags_vertical = Control.SIZE_SHRINK_END
	lg.add_child(sur)
	var t := Composants.texte("VOTRE RECORD", 12, 600, UiTokens.TEXTE_2, "mono")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	d.add_child(t)
	var mon := float(r["score"]) if r.get("score") != null else (float(s["meilleur"]) if not s.is_empty() else -1.0)
	var val := Composants.texte(str(roundi(mon)) if mon >= 0.0 else "—", 22, 600, UiTokens.ENCRE, "mono")
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	d.add_child(val)
	var top: Array = r.get("top", [])
	var note := ""
	var coul := UiTokens.TEXTE_2
	if r.get("rang") == null:
		note = "jouez une fois pour être classé"
	elif int(r["rang"]) <= 10:
		note = "✓ dans le top 10"
		coul = UiTokens.POSITIF
	elif top.size() >= 10:
		var ecart := ceili(float(top[9]["score"]) - mon)
		note = "%d point%s du top 10" % [maxi(1, ecart), "s" if ecart > 1 else ""]
	var n := Composants.texte(note, 12, 700, coul)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	d.add_child(n)
	return p


## Ligne de cote : rang (pastille numérotée or / argent / bronze sur le podium), pseudo, score, barre. e == null : squelette.
func _ligne_cote(rang: int, e, score: float, maxi: float, moi: bool) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.SELECTION if moi else Color(0, 0, 0, 0)
	sb.border_color = UiTokens.ENCRE if moi else UiTokens.FILET
	if moi:
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
	else:
		sb.border_width_bottom = 1
		sb.content_margin_left = 14
		sb.content_margin_right = 14
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.y = 35 if moi else 33
	var h := _grille_cote(rang, moi)
	p.add_child(h)
	if e == null:
		h.add_child(_cellule(_squelette(Vector2(110 + (rang * 37) % 50, 12)), true))
		h.add_child(_cellule(_squelette(Vector2(30, 12)), false, 54))
		h.add_child(_cellule(_squelette(Vector2(80, 8)), false, 92))
		return p
	var nom := HBoxContainer.new()
	nom.add_theme_constant_override("separation", 0)
	if moi:
		nom.add_child(Composants.texte("Vous", 14, 800))
		nom.add_child(Composants.texte(" · " + str(e.get("pseudo", Statistiques.pseudo())), 14, 600))
	else:
		var lp := Composants.texte(str(e["pseudo"]) if e.get("pseudo") != null else "—", 14, 600)
		lp.clip_text = true
		lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.add_child(lp)
	h.add_child(_cellule(nom, true))
	h.add_child(_cellule(_score(score), false, 54))
	h.add_child(_cellule(_barre(score / maxf(1.0, maxi)), false, 92))
	if moi:
		var w := MarginContainer.new()
		w.add_theme_constant_override("margin_left", 6)
		w.add_theme_constant_override("margin_right", 6)
		w.add_child(p)
		return w
	return p


## Grille des colonnes de la cote : rang 40 px, pseudo, score 54, barre 92.
func _grille_cote(rang: int, moi: bool) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	var c := CenterContainer.new()
	c.custom_minimum_size.x = 40
	if rang <= 3:
		var pod := Composants.texte(str(rang), 13, 700, UiTokens.ENCRE, "mono")
		pod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pod.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pod.custom_minimum_size = Vector2(26, 26)
		var sp := StyleBoxFlat.new()
		sp.bg_color = PODIUM[rang - 1]
		sp.border_color = UiTokens.ENCRE
		sp.set_border_width_all(2)
		sp.set_corner_radius_all(13)
		sp.anti_aliasing = true
		pod.add_theme_stylebox_override("normal", sp)
		c.add_child(pod)
	else:
		var l := Composants.texte(str(rang), 14, 600, UiTokens.ENCRE, "mono")
		c.add_child(l)
	h.add_child(c)
	return h


func _cellule(enfant: Control, etirer: bool, largeur := 0) -> Control:
	var c := MarginContainer.new()
	c.add_theme_constant_override("margin_left", 8 if etirer else 0)
	if etirer:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.custom_minimum_size.x = largeur
	enfant.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not etirer:
		enfant.size_flags_horizontal = Control.SIZE_SHRINK_END if largeur == 54 else Control.SIZE_FILL
	c.add_child(enfant)
	return c


func _score(s: float) -> Label:
	var l := Composants.texte(str(roundi(s)), 15, 600, UiTokens.ENCRE, "mono")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l


func _barre(f: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(80, 8)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var r := Rect2(Vector2(12, 0), Vector2(c.size.x - 12, 8))
		var fond := StyleBoxFlat.new()
		fond.bg_color = UiTokens.FILET
		fond.set_corner_radius_all(4)
		fond.draw(c.get_canvas_item(), r)
		var plein: StyleBoxFlat = fond.duplicate()
		plein.bg_color = UiTokens.SARCELLE
		plein.draw(c.get_canvas_item(), Rect2(r.position, Vector2(r.size.x * clampf(f, 0.0, 1.0), 8))))
	return c


func _ligne_vous(rang: int, score: float, maxi: float) -> Control:
	return _ligne_cote(rang, {"pseudo": Statistiques.pseudo()}, score, maxi, true)


## Joueur pas encore classé : ligne jaune clair « — Vous · pas encore classé », avec « Jouer ».
func _ligne_jamais() -> Control:
	var w := MarginContainer.new()
	w.add_theme_constant_override("margin_left", 6)
	w.add_theme_constant_override("margin_right", 6)
	var p := PanelContainer.new()
	var sb := UiTokens.panneau(UiTokens.JAUNE_CLAIR, 6, 2, 0, false)
	sb.content_margin_left = 8
	sb.content_margin_right = 4
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.y = 35
	w.add_child(p)
	var h := _grille_cote(99, true)
	(h.get_child(0).get_child(0) as Label).text = "—"
	p.add_child(h)
	var nom := HBoxContainer.new()
	nom.add_child(Composants.texte("Vous", 14, 800))
	nom.add_child(Composants.texte(" · pas encore classé", 14, 600))
	h.add_child(_cellule(nom, true))
	var b := Composants.bouton("JOUER ›", "BoutonPrincipal")
	b.add_theme_font_override("font", UiTokens.police_titre())
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(64, 26)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var id := choisi
	b.pressed.connect(func(): _jouer(id))
	h.add_child(b)
	return w


func _cote_hors_ligne(v: VBoxContainer, s: Dictionary) -> void:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.FOND_FENETRE
	sb.border_color = UiTokens.ENCRE
	sb.border_width_bottom = 2
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	v.add_child(p)
	var g := VBoxContainer.new()
	g.add_theme_constant_override("separation", 2)
	p.add_child(g)
	g.add_child(Composants.texte("MEILLEUR SCORE SUR CET ORDINATEUR", 12, 600, UiTokens.TEXTE_2, "mono"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	g.add_child(h)
	h.add_child(Composants.texte(str(roundi(float(s["meilleur"]))) if not s.is_empty() else "—", 40, 600, UiTokens.ENCRE, "mono"))
	var n := Composants.texte(("%d partie%s" % [int(s["parties"]), "s" if int(s["parties"]) > 1 else ""]) if not s.is_empty() else "pas encore joué", 14, 600)
	n.size_flags_vertical = Control.SIZE_SHRINK_END
	h.add_child(n)
	var m := MarginContainer.new()
	for c in [["left", 14], ["right", 14], ["top", 22], ["bottom", 12]]:
		m.add_theme_constant_override("margin_" + c[0], c[1])
	m.custom_minimum_size.y = 340
	v.add_child(m)
	var cadre := PanelContainer.new()
	var sc := StyleBoxFlat.new()
	sc.bg_color = UiTokens.FOND_FENETRE
	sc.set_corner_radius_all(8)
	cadre.add_theme_stylebox_override("panel", sc)
	m.add_child(cadre)
	var tirets := Composants.CadreTirets.new()
	tirets.couleur = UiTokens.POINTILLES
	cadre.add_child(tirets)
	var cc := CenterContainer.new()
	cadre.add_child(cc)
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", 10)
	b.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(b)
	var t := Composants.texte("CLASSEMENT INDISPONIBLE", 24, 800, UiTokens.ENCRE, "titre")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(t)
	var l := Composants.paragraphe("Impossible de joindre le serveur. Vous pouvez jouer : votre record reste gardé sur cet ordinateur, mais une partie jouée hors ligne n'entre pas au classement.", 14, UiTokens.ENCRE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 380
	b.add_child(l)
	var r := Composants.bouton("↻ Réessayer", "BoutonMini")
	r.custom_minimum_size = Vector2(116, 36)
	r.add_theme_font_size_override("font_size", 14)
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	r.pressed.connect(func():
		hors_ligne = false
		chargement = true
		resultats.clear()
		_construire()
		_charger())
	b.add_child(r)


func _squelette(taille: Vector2) -> Control:
	var c := Control.new()
	c.custom_minimum_size = taille
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var x := 0.0
		var k := 0
		while x < c.size.x:
			var w := minf(14.0, c.size.x - x)
			c.draw_rect(Rect2(Vector2(x, 0), Vector2(w, c.size.y)), UiTokens.SQUELETTE if k % 2 == 0 else Color("EEF0F2"))
			x += 14.0
			k += 1)
	return c


# ---------------------------------------------------------------- données

func _stats_locales(id: String) -> Dictionary:
	return Statistiques.donnees["defis"].get(id, {})


func _texte_rebours() -> String:
	return Composants.rebours_semaine()["texte"] + " min"


## « lundi 16/11 à 1 h 00 » : fin du défi de la semaine, en heure locale.
func _texte_fin() -> String:
	var n := Defis.numero_semaine()
	var fin := ((n + 1) * 7 - 3) * 86400 + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(fin)
	return "fin %s %d/%d à %d h %02d" % [Defis.JOURS_SEMAINE[(int(d["weekday"]) + 6) % 7], int(d["day"]), int(d["month"]), int(d["hour"]), int(d["minute"])]


## Lit les classements de tous les défis (celui qui est choisi d'abord), puis le vainqueur de la semaine passée.
func _charger() -> void:
	if demo != "":
		_charger_demo()
		return
	if not classement.actif():
		hors_ligne = true
		chargement = false
		_construire()
		return
	var ids: Array = [choisi]
	for d in Defis.liste():
		if not str(d["id"]) in ids:
			ids.append(str(d["id"]))
	for id in ids:
		var r: Dictionary = await classement.classement(id)
		if not is_instance_valid(self):
			return
		if r.is_empty():
			hors_ligne = true
			chargement = false
			_construire()
			return
		resultats[id] = r
		_maj_rang_carte(id)
		if id == choisi:
			_choisir(choisi)
	vainqueur = await classement.vainqueur_semaine()
	if not is_instance_valid(self):
		return
	chargement = false
	_construire()


func _jouer(id: String) -> void:
	jouer.emit(id)


func _revoir_vainqueur() -> void:
	var r: Dictionary = await classement.replay_semaine()
	if is_instance_valid(self) and not r.is_empty():
		revoir.emit(r["replay"])


## Données fictives pour les captures (--defis-demo=…).
func _charger_demo() -> void:
	var pseudos := ["Margaux_R", "PingouinFiscal", "LaLoutreDuNord", "Kev_Zoo", "Sabine.T", "Hippocampus", "ZooKeeper77", "Ondine", "MrLynx", "Capybarbu"]
	var classer := func(base: float, total: int, mon_rang, mon_score: float) -> Dictionary:
		var top: Array = []
		for k in 10:
			var moi: bool = mon_rang != null and int(mon_rang) == k + 1
			top.append({"rang": k + 1, "score": mon_score if moi else base - k * 4.4 - (k % 3), "moi": moi, "pseudo": Statistiques.pseudo() if moi else pseudos[k]})
		return {"rang": mon_rang, "score": mon_score if mon_rang != null else null, "total": total, "top": top}
	match demo:
		"charge":
			return
		"indispo":
			hors_ligne = true
			chargement = false
			_construire()
			return
	var sem := str(Defis.semaine()["id"])
	resultats[sem] = classer.call(158.0, 52, 14 if demo != "jamais" else null, 112.0)
	var fixes: Array = Defis.donnees()["defis"]
	var rangs := [null, 21, 3, 17]
	var totaux := [38, 44, 41, 29]
	for k in fixes.size():
		var mr = rangs[k % 4]
		resultats[str(fixes[k]["id"])] = classer.call(168.0 - k * 4.0, totaux[k % 4], mr, 151.0 if mr == 3 else 120.0 - k)
	vainqueur = {"pseudo": "Margaux_R", "score": 163}
	chargement = false
	_construire()
	_choisir(choisi)


func _espace(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
