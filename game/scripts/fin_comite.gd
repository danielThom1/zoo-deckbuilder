class_name FinComite
extends FenetreComite
## Fin de partie « Le Comité » (handoff §2.8) : un rapport aux actionnaires. Même mise en page pour la victoire et la défaite.

const TRAITS := [[], [8.0, 5.0], [2.0, 4.0], [10.0, 4.0, 2.0, 4.0]]  # motifs de trait : plein, tirets, points, tiret-point
const COULEURS_COURBES := [UiTokens.SARCELLE, UiTokens.ORANGE, Color("2F6FD0"), UiTokens.ENCRE_DOUX]
const SOURCES := [["frequentation", "Fréquentation", UiTokens.SARCELLE], ["spectacles", "Spectacles", Color("6B4FC8")], ["boutique", "Boutique", Color("E04A8A")],
	["objectifs", "Objectifs", UiTokens.SELECTION], ["labels", "Labels", UiTokens.OR_TEXTE], ["prestige", "Prestige", UiTokens.ORANGE],
	["legendaires", "Légendaires", UiTokens.ENCRE], ["beaute", "Beauté du parc", Color("3E8F4E")]]


## Courbes de réputation : motif de trait et étiquette au bout de chaque ligne, pas seulement une couleur.
class Courbes extends Control:
	var mt: Match
	var moi := 0
	var noms: Array = []

	func _draw() -> void:
		var f := UiTokens.police_mono(500)
		var fc := UiTokens.police_corps(700)
		var gauche := 52.0
		var droite := 92.0
		var haut := 12.0
		var bas := 26.0
		var w := size.x - gauche - droite
		var h := size.y - haut - bas
		var objectif := float(mt.objective()) if mt.defi == "" and mt.mode != "cozy" else 0.0  # en défi : pas de ligne de victoire
		var maxi_v := maxf(objectif, 1.0)
		for row in mt.history:
			for e in row:
				maxi_v = maxf(maxi_v, float(e["rep"]))
		var yval := func(v: float) -> float: return haut + h * (1.0 - v / maxi_v)
		var haut_v := objectif if objectif > 0.0 else maxi_v
		for v in [0.0, haut_v / 2.0, haut_v]:
			var y: float = yval.call(v)
			draw_string(f, Vector2(0, y + 4), str(roundi(v)), HORIZONTAL_ALIGNMENT_RIGHT, gauche - 14, 11, UiTokens.TEXTE_2)
			if v == objectif and objectif > 0.0:
				draw_dashed_line(Vector2(gauche, y), Vector2(gauche + w, y), UiTokens.ENCRE, 1.5, 5.0)
			else:
				draw_line(Vector2(gauche, y), Vector2(gauche + w, y), UiTokens.ENCRE if v == 0.0 else UiTokens.FILET, 1.5 if v == 0.0 else 1.0)
		var jours: int = mt.history.size()
		if jours == 0:
			return
		draw_string(f, Vector2(gauche - 4, size.y - 6), "J1", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiTokens.TEXTE_2)
		draw_string(f, Vector2(gauche + w - 24, size.y - 6), "J%d" % int(mt.history[jours - 1][0]["day"]), HORIZONTAL_ALIGNMENT_RIGHT, 24, 11, UiTokens.TEXTE_2)
		var ordre := range(mt.players.size())
		ordre.sort_custom(func(a, b): return (a == moi) == false and (b == moi))  # le joueur est dessiné en dernier
		var etiquettes := []
		var rang := 0
		for i in ordre:
			var couleur: Color = FinComite.COULEURS_COURBES[0] if i == moi else FinComite.COULEURS_COURBES[1 + (rang % 3)]
			var motif: Array = FinComite.TRAITS[0] if i == moi else FinComite.TRAITS[1 + (rang % 3)]
			if i != moi:
				rang += 1
			var pts := PackedVector2Array([Vector2(gauche, yval.call(0.0))])
			for k in jours:
				pts.append(Vector2(gauche + w * (k + 1) / jours, yval.call(float(mt.history[k][i]["rep"]))))
			_ligne(pts, couleur, 4.0 if i == moi else 3.0, motif)
			etiquettes.append([pts[pts.size() - 1], noms[i], couleur, motif])
		# Étiquettes au bout des lignes, écartées si elles se touchent
		etiquettes.sort_custom(func(a, b): return a[0].y < b[0].y)
		var y_prec := -99.0
		for e in etiquettes:
			var y := maxf(e[0].y + 4.0, y_prec + 16.0)
			y_prec = y
			draw_string(fc, Vector2(gauche + w + 8, y), e[1], HORIZONTAL_ALIGNMENT_LEFT, droite - 8, 13, UiTokens.ENCRE)

	func _ligne(pts: PackedVector2Array, couleur: Color, ep: float, motif: Array) -> void:
		if motif.is_empty():
			draw_polyline(pts, couleur, ep, true)
			return
		var k := 0
		var reste: float = motif[0]
		var plein := true
		for s in pts.size() - 1:
			var a := pts[s]
			var b := pts[s + 1]
			var long := a.distance_to(b)
			var dir := (b - a) / maxf(long, 0.001)
			var pos := 0.0
			while pos < long:
				var pas := minf(reste, long - pos)
				if plein:
					draw_line(a + dir * pos, a + dir * (pos + pas), couleur, ep, true)
				pos += pas
				reste -= pas
				if reste <= 0.001:
					k = (k + 1) % motif.size()
					reste = motif[k]
					plein = k % 2 == 0


func _init(principal) -> void:
	super(principal)
	color = UiTokens.ENCRE


func rafraichir() -> void:
	_clear(self)
	var mt: Match = m.mt
	var game: GameState = m.game
	var spectateur: bool = m.spectator
	var gagne: bool = not spectateur and mt.winner == game.index
	var diapo := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.PAPIER
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 20
	diapo.add_theme_stylebox_override("panel", sb)
	diapo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	diapo.offset_left = 18
	diapo.offset_top = 18
	diapo.offset_right = -18
	diapo.offset_bottom = -18
	add_child(diapo)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	diapo.add_child(v)
	v.add_child(_entete(gagne, spectateur))
	var milieu := HBoxContainer.new()
	milieu.add_theme_constant_override("separation", 26)
	milieu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(milieu)
	milieu.add_child(_podium(gagne))
	var droite := VBoxContainer.new()
	droite.add_theme_constant_override("separation", 14)
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milieu.add_child(droite)
	droite.add_child(_panneau_courbes())
	droite.add_child(_chiffres())
	v.add_child(_pied(gagne))


func _entete(gagne: bool, spectateur: bool) -> Control:
	var mt: Match = m.mt
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	var bande := PanelContainer.new()
	bande.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.SELECTION if gagne or spectateur else UiTokens.ORANGE, 10, 3, 10, true))
	bande.get_theme_stylebox("panel").content_margin_left = 22
	bande.get_theme_stylebox("panel").content_margin_right = 22
	var titre := _cond("FIN DE PARTIE" if spectateur else ("CONCESSION REMPORTÉE" if gagne else "FILIALE LIQUIDÉE"), 46)
	bande.add_child(titre)
	h.add_child(bande)
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 2)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.add_child(_mono("RAPPORT AUX ACTIONNAIRES · CLÔTURE AU SOIR DU JOUR %d" % mt.day, 12, 500, UiTokens.TEXTE_2))
	var w: int = mt.winner
	var atteint: bool = mt.players[w].reputation() >= mt.objective()
	t.add_child(_replie(_corps("%s %s %d de réputation%s." % [mt.names[w], "atteint" if atteint else "termine en tête avec", mt.players[w].reputation(),
		" et remporte la concession de la vallée" if atteint else ""], 15, 600)))
	if mt.defi != "" and not spectateur:
		var b: Dictionary = m.bilan_fin
		var ligne := "Défi « %s » : votre score est de %d." % [Defis.trouver(mt.defi).get("nom", mt.defi), roundi(m.game.reputation())]
		if b.get("record", false):
			ligne += " Nouveau record personnel%s !" % ((" (ancien : %d)" % roundi(float(b["ancien"]))) if float(b.get("ancien", 0.0)) > 0.0 else "")
		elif not b.is_empty():
			ligne += " Votre record : %d." % roundi(float(b["ancien"]))
		t.add_child(_replie(_corps(ligne, 15, 700, UiTokens.SARCELLE_FONCE)))
	if not m.bilan_fin.get("succes", []).is_empty():
		t.add_child(_replie(_corps("Succès débloqué : %s." % ", ".join(m.bilan_fin["succes"]), 14, 600, UiTokens.SARCELLE_FONCE)))
	h.add_child(t)
	if not spectateur:
		h.add_child(_tampon("APPROUVÉ" if gagne else "LIQUIDÉ", UiTokens.SARCELLE if gagne else Color("B3361F")))
	return h


func _tampon(texte: String, couleur: Color) -> Control:
	var boite := Control.new()
	boite.custom_minimum_size = Vector2(140, 50)
	boite.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = couleur
	sb.set_border_width_all(3)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(_cond(texte, 24, couleur))
	p.rotation = deg_to_rad(-7)
	p.position = Vector2(4, 10)
	boite.add_child(p)
	return boite


func _podium(gagne: bool) -> Control:
	var mt: Match = m.mt
	var game: GameState = m.game
	var racine := HBoxContainer.new()
	racine.add_theme_constant_override("separation", 10)
	racine.alignment = BoxContainer.ALIGNMENT_END
	racine.custom_minimum_size.x = 600
	var classes := range(mt.players.size())
	classes.sort_custom(func(a, b): return mt.players[a].reputation() > mt.players[b].reputation())
	var hauteurs := [270, 220, 180, 150]
	for rang in [1, 0, 2, 3]:
		if rang >= classes.size():
			continue
		var i: int = classes[rang]
		var est_moi: bool = i == game.index and not m.spectator
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		col.alignment = BoxContainer.ALIGNMENT_END
		col.custom_minimum_size.x = 142
		var lg := _logo(i, 76)
		lg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(lg)
		var nm := _cond(str(mt.names[i]), 17)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(nm)
		var rp := _mono(str(mt.players[i].reputation()), 22)
		rp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(rp)
		var marche := PanelContainer.new()
		var fond: Color = (UiTokens.SARCELLE if gagne else UiTokens.ORANGE_CLAIR) if est_moi else UiTokens.MEMO
		var sm := StyleBoxFlat.new()
		sm.bg_color = fond
		sm.border_color = UiTokens.ENCRE
		sm.border_width_left = 2
		sm.border_width_right = 2
		sm.border_width_top = 2
		sm.corner_radius_top_left = 8
		sm.corner_radius_top_right = 8
		sm.content_margin_left = 10
		sm.content_margin_right = 10
		sm.content_margin_top = 8
		marche.add_theme_stylebox_override("panel", sm)
		marche.custom_minimum_size.y = hauteurs[rang]
		var mv := VBoxContainer.new()
		mv.add_theme_constant_override("separation", 6)
		marche.add_child(mv)
		var r := _cond(str(rang + 1), 30, UiTokens.PAPIER if est_moi and gagne else UiTokens.ENCRE)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mv.add_child(r)
		var voir := Composants.bouton("Voir son zoo" if not est_moi else "Voir mon zoo", "BoutonSecondaire")
		voir.add_theme_font_size_override("font_size", 12)
		voir.custom_minimum_size.y = 30
		voir.pressed.connect(m._watch_board.bind(i))
		mv.add_child(voir)
		if mt.is_ai(i) and m._replay_disponible():
			var rv := Composants.bouton("Revoir sa partie", "BoutonSecondaire")
			rv.add_theme_font_size_override("font_size", 12)
			rv.custom_minimum_size.y = 30
			rv.pressed.connect(m._voir_replay.bind(i))
			mv.add_child(rv)
		col.add_child(marche)
		racine.add_child(col)
	return racine


func _panneau_courbes() -> Control:
	var mt: Match = m.mt
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 12, false))
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var h := HBoxContainer.new()
	var t := _cond("RÉPUTATION, JOUR PAR JOUR", 14)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	if mt.defi == "" and mt.mode != "cozy":
		h.add_child(_corps("ligne %d = victoire" % mt.objective(), 12, 600, UiTokens.TEXTE_2))
	v.add_child(h)
	var c := Courbes.new()
	c.mt = mt
	c.moi = m.game.index
	c.noms = []
	for i in mt.players.size():
		c.noms.append(_nom_court(i).replace(" Capital", "").replace(" Group", ""))
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size.y = 220
	v.add_child(c)
	return p


func _chiffres() -> Control:
	var mt: Match = m.mt
	var game: GameState = m.game
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var especes := {}
	for a in game.animals:
		if a.arrived:
			especes[a.def["id"]] = true
	for c in [[str(especes.size()), "espèces"], [str(m._visitors_total(game.index)), "visiteurs cumulés"],
			["%d/%d" % [game.objectifs_faits.size(), mt.objectifs.size()], "objectifs atteints"], [str(game.all_employees().size()), "collaborateurs"]]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 10, false))
		p.custom_minimum_size = Vector2(112, 96)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		p.add_child(v)
		v.add_child(_mono(c[0], 26))
		v.add_child(_replie(_corps(c[1], 12, 600, UiTokens.TEXTE_2)))
		h.add_child(p)
	# Réputation par source : barre empilée et légende écrite
	var ps := PanelContainer.new()
	ps.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 10, false))
	ps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 6)
	ps.add_child(sv)
	sv.add_child(_cond("VOTRE RÉPUTATION PAR SOURCE", 13))
	var total := 0.0
	var parts := []
	for s in SOURCES:
		var pts := float(game.rep_sources.get(s[0], 0.0))
		if pts >= 0.5:
			parts.append([s[1], pts, s[2]])
			total += pts
	var barre := HBoxContainer.new()
	barre.add_theme_constant_override("separation", 0)
	barre.custom_minimum_size.y = 24
	var legende := GridContainer.new()
	legende.columns = 3
	legende.add_theme_constant_override("h_separation", 12)
	legende.add_theme_constant_override("v_separation", 0)
	for q in parts:
		var seg := ColorRect.new()
		seg.color = q[2]
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.size_flags_stretch_ratio = q[1] / maxf(total, 1.0)
		seg.mouse_filter = Control.MOUSE_FILTER_PASS
		seg.tooltip_text = "%s : %d" % [q[0], roundi(q[1])]
		barre.add_child(seg)
		var lh := HBoxContainer.new()
		lh.add_theme_constant_override("separation", 4)
		var carre := ColorRect.new()
		carre.color = q[2]
		carre.custom_minimum_size = Vector2(9, 9)
		carre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lh.add_child(carre)
		lh.add_child(_corps("%s %d %%" % [q[0], roundi(100.0 * q[1] / maxf(total, 1.0))], 11, 600))
		legende.add_child(lh)
	var cadre := PanelContainer.new()
	var sc := StyleBoxFlat.new()
	sc.bg_color = UiTokens.PAPIER
	sc.border_color = UiTokens.ENCRE
	sc.set_border_width_all(2)
	sc.set_content_margin_all(2)
	cadre.add_theme_stylebox_override("panel", sc)
	cadre.add_child(barre)
	sv.add_child(cadre)
	sv.add_child(legende)
	h.add_child(ps)
	return h


func _pied(gagne: bool) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var hubert: BulleHubert = m.hubert
	if hubert:
		var moment := "victoire" if gagne else "defaite"
		var cle := "fin_%s" % moment
		if not m.memo_lignes.has(cle):
			m.memo_lignes[cle] = hubert.replique(moment)
		var tete := Composants.image_logo(load("res://assets/bd/hubert/%s.png" % ("content" if gagne else "furieux")), Vector2(70, 70))
		h.add_child(tete)
		var t := Composants.label("« %s »" % m.memo_lignes[cle])
		t.add_theme_font_override("font", UiTokens.police_italique())
		t.add_theme_font_size_override("font_size", 15)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_theme_constant_override("line_spacing", -3)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(t)
	else:
		var e := Control.new()
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(e)
	for spec in [["Menu principal", "BoutonSecondaire", func(): m._restart("menu")], ["Revoir la carte finale", "BoutonSecondaire", func(): m.end_dismissed = true],
			["NOUVELLE PARTIE" if m.replay else "REJOUER", "BoutonPrincipal", func(): m._restart("spectateur" if m.spectator and m.replay == null else "jouer")]]:
		var b := Composants.bouton(spec[0], spec[1])
		b.custom_minimum_size = Vector2(0, 50)
		b.add_theme_font_size_override("font_size", 15)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(spec[2])
		h.add_child(b)
	return h
