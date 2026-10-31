extends Control
## Galerie de composants « Émeraude » — reproduit docs/handoff_emeraude/captures/07_composants_cartes.png.
## Sert de banc d'essai pour les icônes SVG teintées et les polices intégrées.
## Capture de contrôle :  <godot> --path game res://ui/galerie_composants.tscn -- --capture
## (enregistre capture_galerie.png à la racine du dépôt puis quitte)

const BLANC := Color("FFFFFF")
const NBSP := " "  # espace insécable avant % (§10 HANDOFF)
const DIMS := {"main": Vector2(136, 216), "draft": Vector2(146, 196), "marche": Vector2(160, 236)}
const HAUTEUR_PORTRAIT := {"main": 98, "draft": 86, "marche": 88}


func _ready() -> void:
	theme = UiTokens.build_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construire()
	if "--capture" in OS.get_cmdline_user_args():
		await _capture_et_quitte()


# ------------------------------------------------------------------ mise en page

func _construire() -> void:
	var fond := ColorRect.new()
	fond.color = UiTokens.FOND_ECRAN.darkened(0.25)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var titre := HBoxContainer.new()
	titre.add_theme_constant_override("separation", 18)
	titre.position = Vector2(40, 24)
	titre.add_child(_label("COMPOSANTS · CARTES", "TitreEcran"))
	var st := _label("variante Émeraude · mesures en px à 1600 × 900", "TexteSecondaire")
	st.size_flags_vertical = Control.SIZE_SHRINK_END
	titre.add_child(st)
	add_child(titre)

	# Colonne 1 — carte ouvrier de référence, agrandie ×1,7, et ses 8 repères
	_entete_section("CARTE OUVRIER · MAIN (136 × 216, agrandie ×1,7)", Vector2(40, 92))
	var ref := carte_ouvrier(_ouvrier("reference"), "normale", "main")
	ref.position = Vector2(40, 124)
	ref.scale = Vector2(1.7, 1.7)
	add_child(ref)
	_reperes([
		["Catégorie", "pastille couleur + chevrons (1, 2) ou étoile, jamais la couleur seule"],
		["Salaire", "pièce dorée, coût par jour ; orange si non abordable"],
		["Portrait", "fond teinté par catégorie (image peinte en prototype)"],
		["Nom", "Marcellus SC 12,5 px, majuscules, 2 lignes max"],
		["Métier et niveau", "Source Sans 3 13 px, N1 à N4"],
		["Qualités et défauts", "rond bleu + / carré orange −, icône blanche"],
		["Déployer", "bouton principal, zone cliquable 44 px avec la marge"],
		["Gratuit 25" + NBSP + "%", "secondaire, un seul par jour"],
	], Vector2(300, 124), 240)
	_rangee_ordres(Vector2(40, 516))
	_rangee_jetons(Vector2(40, 596))
	_rangee_qualites(Vector2(40, 676))
	_rangee_boutons(Vector2(40, 744))

	# Colonne 2 — états en main
	_entete_section("ÉTATS EN MAIN", Vector2(570, 92))
	var etats := [
		["normale", "Normale", "en main, déployable"],
		["survol", "Survol / sélection", "monte de 26 px, halo #FFD45A"],
		["non_abordable", "Non abordable", "pièce orange, bouton contour"],
		["deployee", "Déployée", "grisée, visible jusqu'à la nuit"],
		["gratuite", "Gratuite", "jeton 25" + NBSP + "% : bouton turquoise"],
		["hors_carte", "Ouvrier hors carte", "lobbying en cours, retour minuté"],
	]
	for i in etats.size():
		var pos := Vector2(570 + (i % 3) * 160, 136 + (i / 3) * 300)
		var c := carte_ouvrier(_ouvrier(etats[i][0]), etats[i][0], "main")
		c.position = pos
		add_child(c)
		_legende(etats[i][1], etats[i][2], pos + Vector2(0, 226))

	# Colonne 3 — contrat d'animal + tuiles de motif
	_entete_section("CONTRAT D'ANIMAL (204 × 292)", Vector2(1080, 92))
	var contrat := carte_contrat(_contrat_demo())
	contrat.position = Vector2(1080, 124)
	add_child(contrat)
	_reperes([
		["Biome", "bandeau couleur + icône"], ["Palier", "1 à 3 losanges pleins"],
		["Illustration", "portrait de l'animal"], ["Motif requis", "une tuile par case ; pointillé = libre"],
		["Règle spéciale", "adjacences, minimums"], ["Gains", "réputation · nourriture/nuit · visiteurs"],
		["Achat", "coût au marché de nuit"],
	], Vector2(1300, 124), 270, false)
	_tuiles_motifs(Vector2(1080, 446))

	# Bas — encadrés de synthèse des tailles
	var syntheses := [
		["Main · 136 × 216", "jour, 5 cartes, écart 8 px, dépasse de 34 px en bas"],
		["Draft · 146 × 196", "grille 7 × 3, écart 12 px"],
		["Marché · 160 × 236", "nuit, 5 ouvriers avec bouton Embaucher"],
		["Contrat · 204 × 292", "nuit, 4 contrats"],
		["Cadre commun", "bord doré 2 px, rayon 12, fond #11564E → #08302C"],
	]
	for i in syntheses.size():
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PANNEAU_BAS, Color(UiTokens.OR, 0.35), 8, 1, 10))
		p.position = Vector2(40 + i * 306, 812)
		p.custom_minimum_size = Vector2(296, 64)
		p.add_child(_texte_riche("[b]%s[/b]\n[color=#A6D4C8]%s[/color]" % syntheses[i], 276, 13))
		add_child(p)


# ------------------------------------------------------------------ carte ouvrier

func carte_ouvrier(d: Dictionary, etat: String, taille: String) -> Control:
	var t: Vector2 = DIMS.get(taille, DIMS["main"])
	var hp: int = HAUTEUR_PORTRAIT.get(taille, 98)
	var cat: Dictionary = UiTokens.CATEGORIES[d["categorie"]]
	var orange := etat == "non_abordable"

	var racine := Control.new()
	racine.custom_minimum_size = t
	racine.size = t

	var carte := Panel.new()
	carte.size = t
	var sb_carte := UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 10, 2, 0)
	if etat == "survol":
		# levée + halo de sélection
		carte.position.y = -18
		sb_carte.border_color = UiTokens.SELECTION
		sb_carte.shadow_color = Color(UiTokens.SELECTION, 0.55)
		sb_carte.shadow_size = 12
		sb_carte.shadow_offset = Vector2.ZERO
	carte.add_theme_stylebox_override("panel", sb_carte)
	racine.add_child(carte)

	# 3 — portrait : haut de carte teinté par catégorie, accessoire du métier au centre
	var portrait := Panel.new()
	var sb_port := StyleBoxFlat.new()
	sb_port.bg_color = cat["portrait"]
	sb_port.corner_radius_top_left = 8
	sb_port.corner_radius_top_right = 8
	portrait.add_theme_stylebox_override("panel", sb_port)
	portrait.position = Vector2(2, 2)
	portrait.size = Vector2(t.x - 4, hp)
	portrait.clip_contents = true
	carte.add_child(portrait)
	var accessoire := _icone_rect("metier_" + d["metier_icone"], Vector2(54, 54), Color(cat["couleur"]).darkened(0.15))
	accessoire.position = Vector2((portrait.size.x - 54) / 2.0, hp - 64)
	portrait.add_child(accessoire)

	# 1 — badge catégorie : couleur + icône de forme + libellé
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UiTokens.chip(cat["couleur"], 11, 2))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 3)
	hb.add_child(_icone_rect(cat["icone"], Vector2(14, 14), BLANC))
	var lc := _label(cat["court"])
	lc.add_theme_font_override("font", UiTokens.police_corps(800))
	lc.add_theme_font_size_override("font_size", 10)
	hb.add_child(lc)
	badge.add_child(hb)
	badge.position = Vector2(6, 6)
	carte.add_child(badge)

	# 2 — pièce de salaire
	var piece := _piece_salaire(d["salaire"], orange)
	piece.position = Vector2(t.x - 38, 6)
	carte.add_child(piece)

	# 4 / 5 — nom + métier · niveau
	var y := hp + 6
	var nom := _label(d["nom"], "NomCarte")
	nom.add_theme_font_size_override("font_size", 12)
	nom.position = Vector2(6, y)
	nom.size = Vector2(t.x - 12, 18)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	carte.add_child(nom)
	var metier := _label("%s · N%d" % [d["metier"], d["niveau"]], "TexteSecondaire")
	metier.position = Vector2(6, y + 18)
	metier.size = Vector2(t.x - 12, 16)
	metier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carte.add_child(metier)

	# 6 — qualités (cercle bleu) / défauts (carré orange)
	var qd := HBoxContainer.new()
	qd.alignment = BoxContainer.ALIGNMENT_CENTER
	qd.add_theme_constant_override("separation", 5)
	qd.position = Vector2(6, y + 38)
	qd.size = Vector2(t.x - 12, 24)
	for q in d["qualites"]:
		qd.add_child(_mini_pastille(true, q))
	for df in d["defauts"]:
		qd.add_child(_mini_pastille(false, df))
	carte.add_child(qd)

	# 7 / 8 — actions, ou état spécial
	_zone_basse(racine, carte, t, hp, etat, d)
	return racine


func _zone_basse(racine: Control, carte: Panel, t: Vector2, hp: int, etat: String, d: Dictionary) -> void:
	var y := t.y - 38
	var plein := Vector2(t.x - 16, 30)
	match etat:
		"non_abordable":
			var b := _bouton("Manque %d" % d["manque"], "BoutonSecondaire")
			var sb := UiTokens._button(Color(UiTokens.PANNEAU_BAS, 0.85), UiTokens.DEFAUT, 22)
			sb.set_border_width_all(2)
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_color_override("font_color", UiTokens.NEGATIF)
			_placer(carte, b, Vector2(8, y), plein)
		"gratuite":
			carte.add_child(_pastille_texte("GRATUIT 25" + NBSP + "%", Color("18A88A"), t.x, hp - 24))
			var b2 := _bouton("Déployer · 0", "BoutonPrincipal")
			b2.add_theme_stylebox_override("normal", UiTokens._button(Color("2EC8A8"), Color("0E6A58"), 22))
			_placer(carte, b2, Vector2(8, y), plein)
		"hors_carte":
			carte.add_child(_pastille_texte("HORS CARTE 0:42", Color("6A3AB0"), t.x, hp - 24))
			_placer(carte, _bouton("Rappeler", "BoutonSecondaire"), Vector2(8, y), plein)
		"deployee":
			_placer(carte, _bouton("Localiser", "BoutonSecondaire"), Vector2(8, y), plein)
			# désaturée 60 % (§5.1) ; le badge, hors de la carte, reste en couleur
			_desaturer(carte)
			racine.add_child(_pastille_texte("SUR LE TERRAIN", Color("1A2422"), t.x, 72))
		_:
			_placer(carte, _bouton("Déployer", "BoutonPrincipal"), Vector2(8, y), Vector2(t.x - 62, 30))
			_placer(carte, _bouton("25" + NBSP + "%", "BoutonSecondaire"), Vector2(t.x - 50, y), Vector2(42, 30))


## Désature un nœud et tous ses descendants (shader commun, enfants en use_parent_material).
func _desaturer(noeud: CanvasItem, force := 0.6, luminosite := 0.8) -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float force = 0.6;
uniform float luminosite = 0.8;
void fragment() {
	float gris = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(gris), force) * luminosite;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("force", force)
	mat.set_shader_parameter("luminosite", luminosite)
	noeud.material = mat
	for enfant in noeud.find_children("*", "CanvasItem", true, false):
		enfant.use_parent_material = true


# ------------------------------------------------------------------ carte contrat

func carte_contrat(d: Dictionary) -> Control:
	var t := Vector2(204, 292)
	var biome: Dictionary = UiTokens.BIOMES[d["biome"]]
	var carte := Panel.new()
	carte.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 12, 2, 0))
	carte.custom_minimum_size = t
	carte.size = t

	# bandeau biome 30 px : couleur + icône + palier
	var bandeau := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = biome["couleur"]
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	bandeau.add_theme_stylebox_override("panel", sb)
	_placer(carte, bandeau, Vector2(2, 2), Vector2(200, 30))
	_placer(bandeau, _icone_rect(biome["icone"], Vector2(18, 18), BLANC), Vector2(10, 6), Vector2(18, 18))
	var bnom := _label(biome["nom"].to_upper())
	bnom.add_theme_font_override("font", UiTokens.police_corps(800))
	bnom.add_theme_font_size_override("font_size", 13)
	_placer(bandeau, bnom, Vector2(34, 5), Vector2(100, 20))
	var palier := _label("◆".repeat(d["palier"]) + "◇".repeat(3 - d["palier"]))
	palier.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_placer(bandeau, palier, Vector2(120, 5), Vector2(70, 20))

	# illustration 86 px
	var illu := Panel.new()
	var sb2 := StyleBoxFlat.new()
	sb2.bg_color = Color(biome["couleur"]).lightened(0.12)
	illu.add_theme_stylebox_override("panel", sb2)
	_placer(carte, illu, Vector2(2, 32), Vector2(200, 86))
	_placer(illu, _icone_rect(d["illustration"], Vector2(60, 60), Color(UiTokens.TEXTE, 0.95)), Vector2(70, 13), Vector2(60, 60))

	# nom + nombre de cases
	var nom := _label(d["nom"], "NomCarte")
	nom.add_theme_font_size_override("font_size", 19)
	_placer(carte, nom, Vector2(12, 122), Vector2(110, 24))
	var cases := _label("%d cases" % d["cases"], "TexteSecondaire")
	cases.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_placer(carte, cases, Vector2(112, 126), Vector2(80, 18))

	# motif requis : une tuile par case
	var tuiles := HBoxContainer.new()
	tuiles.add_theme_constant_override("separation", 3)
	for ty in d["exigences"]:
		tuiles.add_child(tuile_motif(ty, 18))
	_placer(carte, tuiles, Vector2(12, 150), Vector2(180, 18))
	var regle := _label(d["regle"], "TexteSecondaire")
	regle.add_theme_color_override("font_color", UiTokens.TEXTE)
	regle.add_theme_font_size_override("font_size", 12)
	regle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	regle.custom_minimum_size = Vector2(180, 0)
	_placer(carte, regle, Vector2(12, 170), Vector2(180, 34))

	# gains
	var gains := HBoxContainer.new()
	gains.add_theme_constant_override("separation", 0)
	for g in d["gains"]:
		gains.add_child(_gain(g[0], g[1], g[2]))
	_placer(carte, gains, Vector2(12, 212), Vector2(180, 38))

	_placer(carte, _bouton("Acheter · %d" % d["cout"], "BoutonPrincipal"), Vector2(12, 254), Vector2(180, 30))
	return carte


# ------------------------------------------------------------------ petits composants

func tuile_motif(type: String, taille := 18) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(taille, taille)
	c.draw.connect(_dessiner_tuile.bind(c, type))
	return c


func _dessiner_tuile(c: Control, type: String) -> void:
	var s: float = c.custom_minimum_size.x
	var r := Rect2(Vector2.ZERO, Vector2(s, s))
	if type == "libre":
		var coins := [Vector2(0.5, 0.5), Vector2(s - 0.5, 0.5), Vector2(s - 0.5, s - 0.5), Vector2(0.5, s - 0.5)]
		for i in 4:
			c.draw_dashed_line(coins[i], coins[(i + 1) % 4], UiTokens.TEXTE_SECONDAIRE, 1.0, 3.0)
		return
	c.draw_rect(r, UiTokens.TUILES.get(type, UiTokens.PANNEAU_BAS))
	match type:
		"prairie":  # traits verticaux
			for x in range(4, int(s) - 2, 4):
				c.draw_line(Vector2(x, 5), Vector2(x, s - 4), Color("E8F8C8"), 1.0)
		"foret":  # triangles blancs
			for x in [3.0, 10.0]:
				c.draw_colored_polygon(PackedVector2Array([Vector2(x, s - 4), Vector2(x + 5, s - 4), Vector2(x + 2.5, 5)]), BLANC)
		"eau":  # vagues
			for yv in [6.0, 11.0]:
				var pts := PackedVector2Array()
				for k in 7:
					pts.append(Vector2(2 + k * 2.4, yv + (1.2 if k % 2 else -1.2)))
				c.draw_polyline(pts, BLANC, 1.0)
		"roche":  # triangles sombres
			c.draw_colored_polygon(PackedVector2Array([Vector2(2, s - 3), Vector2(7, 6), Vector2(12, s - 3)]), Color("5A564C"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(8, s - 3), Vector2(12, 9), Vector2(16, s - 3)]), Color("6E6A60"))
		"sable":  # points
			for p in [Vector2(5, 5), Vector2(12, 7), Vector2(7, 12), Vector2(13, 13)]:
				c.draw_circle(p, 1.2, Color("B8964A"))
	c.draw_rect(r, Color(0, 0, 0, 0.3), false, 1.0)


func _pastille(fond: Color, nom_icone: String, diametre: int, reflet := Color.TRANSPARENT) -> Control:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = fond
	sb.set_corner_radius_all(diametre)
	if reflet.a > 0.0:  # reflet suggéré par un liseré clair en haut
		sb.border_color = Color(reflet, 0.8)
		sb.border_width_top = 2
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(diametre, diametre)
	var cote := diametre * 0.6
	_placer(p, _icone_rect(nom_icone, Vector2(cote, cote), BLANC), Vector2(diametre * 0.2, diametre * 0.2), Vector2(cote, cote))
	return p


func _mini_pastille(est_qualite: bool, nom_icone: String) -> Control:
	# qualité = cercle bleu ; défaut = carré orange rayon 3 (double codage couleur + forme)
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.QUALITE if est_qualite else UiTokens.DEFAUT
	sb.set_corner_radius_all(12 if est_qualite else 3)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(24, 24)
	_placer(p, _icone_rect(nom_icone, Vector2(15, 15), BLANC), Vector2(4.5, 4.5), Vector2(15, 15))
	return p


func _piece_salaire(valeur: int, orange: bool) -> Control:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.DEFAUT if orange else UiTokens.OR
	sb.set_corner_radius_all(16)
	sb.border_color = UiTokens.OR_CLAIR if not orange else Color("FFC89A")
	sb.border_width_top = 2
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 2)
	p.add_theme_stylebox_override("panel", sb)
	p.size = Vector2(32, 32)
	var l := _label(str(valeur), "Compteur")
	l.add_theme_color_override("font_color", UiTokens.BOUTON_TEXTE)
	l.add_theme_font_size_override("font_size", 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_placer(p, l, Vector2.ZERO, Vector2(32, 32))
	return p


func _gain(valeur: String, legende: String, couleur: Color) -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 60
	v.add_theme_constant_override("separation", -2)
	var l := _label(valeur, "Compteur")
	l.add_theme_color_override("font_color", couleur)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var s := _label(legende, "TexteSecondaire")
	s.add_theme_font_size_override("font_size", 11)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	return v


## Pastille de texte centrée horizontalement sur une largeur donnée (bandeaux d'état des cartes).
func _pastille_texte(txt: String, fond: Color, largeur: float, y: float) -> Control:
	var centre := CenterContainer.new()
	centre.position = Vector2(0, y)
	centre.size = Vector2(largeur, 22)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.chip(fond, 11, 3))
	var l := _label(txt)
	l.add_theme_font_override("font", UiTokens.police_corps(800))
	l.add_theme_font_size_override("font_size", 11)
	p.add_child(l)
	centre.add_child(p)
	return centre


# ------------------------------------------------------------------ rangées de démo

func _rangee_ordres(pos: Vector2) -> void:
	_entete_section("BOUTONS D'ORDRE (46 px · actif en or)", pos)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.position = pos + Vector2(0, 28)
	var noms := ["ordre_construire", "ordre_extraire", "ordre_amenager", "ordre_abattre", "ordre_tenir_poste", "ordre_lobbying", "ordre_rappeler"]
	for i in noms.size():
		var b := Button.new()
		b.theme_type_variation = "BoutonOrdre"
		b.custom_minimum_size = Vector2(46, 46)
		b.tooltip_text = noms[i].trim_prefix("ordre_").replace("_", " ").capitalize()
		var actif := i == 0
		if actif:
			b.add_theme_stylebox_override("normal", UiTokens._button(Color("E8B468"), UiTokens.OR_CLAIR, 23))
		_placer(b, _icone_rect(noms[i], Vector2(22, 22), UiTokens.BOUTON_TEXTE if actif else UiTokens.OR_CLAIR), Vector2(12, 12), Vector2(22, 22))
		h.add_child(b)
	add_child(h)


func _rangee_jetons(pos: Vector2) -> void:
	_entete_section("JETONS DE RESSOURCE (delta avec flèche)", pos)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	h.position = pos + Vector2(0, 28)
	for j in [["argent", 182, 24], ["bois", 46, -3], ["pierre", 31, 0], ["or", 4, 1], ["logement", 12, 0]]:
		h.add_child(_jeton_ressource(j[0], j[1], j[2]))
	add_child(h)


func _jeton_ressource(cle: String, valeur: int, delta: int) -> Control:
	var res: Dictionary = UiTokens.RESSOURCES[cle]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	var pastille := _pastille(res["couleur"], res["icone"], 30, res["reflet"])
	pastille.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(pastille)
	h.add_child(_label(str(valeur), "Compteur"))
	if delta != 0:
		var dl := _label("%s%d" % ["▲" if delta > 0 else "▼", absi(delta)], "TexteSecondaire")
		dl.add_theme_color_override("font_color", UiTokens.POSITIF if delta > 0 else UiTokens.NEGATIF)
		dl.add_theme_font_size_override("font_size", 12)
		h.add_child(dl)
	return h


func _rangee_qualites(pos: Vector2) -> void:
	_entete_section("QUALITÉS ET DÉFAUTS", pos)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.position = pos + Vector2(0, 28)
	for it in [[true, "qualite_costaud", "Costaud"], [true, "qualite_rapide", "Rapide"], [false, "defaut_lent", "Lent"], [false, "defaut_paresseux", "Paresseux"]]:
		var g := HBoxContainer.new()
		g.add_theme_constant_override("separation", 5)
		g.add_child(_mini_pastille(it[0], it[1]))
		g.add_child(_label(("+ " if it[0] else "− ") + it[2]))
		h.add_child(g)
	add_child(h)


func _rangee_boutons(pos: Vector2) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.position = pos
	for b in [["Principal", "BoutonPrincipal", false], ["Secondaire", "BoutonSecondaire", false], ["Indisponible", "BoutonPrincipal", true]]:
		var bt := _bouton(b[0], b[1])
		bt.disabled = b[2]
		bt.custom_minimum_size = Vector2(130, 40)
		h.add_child(bt)
	add_child(h)


func _tuiles_motifs(pos: Vector2) -> void:
	_entete_section("TUILES DE MOTIF (18 px, couleur + motif)", pos)
	var grille := GridContainer.new()
	grille.columns = 4
	grille.add_theme_constant_override("h_separation", 18)
	grille.add_theme_constant_override("v_separation", 10)
	grille.position = pos + Vector2(0, 30)
	for t in [["foret", "Forêt"], ["eau", "Eau"], ["roche", "Roche"], ["prairie", "Prairie"], ["sable", "Sable (points)"], ["libre", "Libre"]]:
		var g := HBoxContainer.new()
		g.add_theme_constant_override("separation", 6)
		var tu := tuile_motif(t[0], 22)
		tu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		g.add_child(tu)
		g.add_child(_label(t[1]))
		grille.add_child(g)
	add_child(grille)


# ------------------------------------------------------------------ utilitaires

func _icone_rect(nom: String, taille: Vector2, couleur := BLANC) -> TextureRect:
	var tr := TextureRect.new()
	# expand_mode avant la texture : sinon la taille native (96 px à svg/scale 2) impose la taille minimale
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.texture = UiTokens.icone(nom)
	tr.custom_minimum_size = taille
	tr.size = taille
	tr.modulate = couleur
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _placer(parent: Control, enfant: Control, pos: Vector2, taille: Vector2) -> void:
	parent.add_child(enfant)
	enfant.position = pos
	enfant.size = taille


func _label(txt: String, variation := "") -> Label:
	var l := Label.new()
	l.text = txt
	l.theme_type_variation = variation
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _bouton(txt: String, variation := "") -> Button:
	var b := Button.new()
	b.text = txt
	b.theme_type_variation = variation
	b.add_theme_font_size_override("font_size", 14)
	return b


func _texte_riche(bbcode: String, largeur: float, taille := 13) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(largeur, 0)
	r.add_theme_font_size_override("normal_font_size", taille)
	r.add_theme_font_size_override("bold_font_size", taille)
	r.text = bbcode
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _entete_section(txt: String, pos: Vector2) -> void:
	var l := _label(txt, "TitrePanneau")
	l.position = pos
	add_child(l)


func _legende(titre: String, sous: String, pos: Vector2) -> void:
	var r := _texte_riche("[b]%s[/b]\n[color=#A6D4C8]%s[/color]" % [titre, sous], 150, 13)
	r.position = pos
	add_child(r)


## Liste de repères (numérotés ou non) à côté d'un composant.
func _reperes(items: Array, pos: Vector2, largeur: float, numerotes := true) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.position = pos
	for i in items.size():
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 8)
		if numerotes:
			var n := Panel.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = UiTokens.SELECTION
			sb.set_corner_radius_all(10)
			n.add_theme_stylebox_override("panel", sb)
			n.custom_minimum_size = Vector2(20, 20)
			n.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			var nl := _label(str(i + 1))
			nl.add_theme_color_override("font_color", UiTokens.BOUTON_TEXTE)
			nl.add_theme_font_override("font", UiTokens.police_corps(800))
			nl.add_theme_font_size_override("font_size", 12)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_placer(n, nl, Vector2.ZERO, Vector2(20, 20))
			ligne.add_child(n)
		ligne.add_child(_texte_riche("[b]%s[/b] · [color=#A6D4C8]%s[/color]" % items[i] if numerotes else "[b]%s[/b]\n[color=#A6D4C8]%s[/color]" % items[i], largeur - (28 if numerotes else 0), 13))
		v.add_child(ligne)
	add_child(v)


# ------------------------------------------------------------------ données factices (§11 HANDOFF)

func _ouvrier(etat: String) -> Dictionary:
	match etat:
		"reference":
			return {"nom": "BRUNO LEFÈVRE", "metier": "Maçon", "metier_icone": "macon", "categorie": "peu_qualifie", "niveau": 3, "salaire": 18, "manque": 0, "qualites": ["qualite_costaud"], "defauts": ["defaut_paresseux"]}
		"non_abordable":
			return {"nom": "GÉRARD BLANCHET", "metier": "Marchand", "metier_icone": "marchand", "categorie": "cadre", "niveau": 2, "salaire": 34, "manque": 6, "qualites": ["qualite_charismatique"], "defauts": ["defaut_col_blanc"]}
		"hors_carte":
			return {"nom": "HÉLÈNE VASSEUR", "metier": "Lobbyiste", "metier_icone": "lobbyiste", "categorie": "cadre", "niveau": 1, "salaire": 30, "manque": 0, "qualites": ["qualite_charismatique"], "defauts": []}
		_:
			return {"nom": "AÏCHA DIALLO", "metier": "Bûcheronne", "metier_icone": "bucheron", "categorie": "peu_qualifie", "niveau": 2, "salaire": 12, "manque": 0, "qualites": ["qualite_endurant"], "defauts": ["defaut_lent"]}


func _contrat_demo() -> Dictionary:
	return {
		"nom": "Tigre", "illustration": "biome_jungle", "biome": "jungle", "cases": 8, "palier": 2, "cout": 70,
		"exigences": ["foret", "foret", "foret", "eau", "eau", "roche", "prairie", "libre"],
		"regle": "au moins 3 paires eau / forêt voisines",
		"gains": [["+6", "réputation", Color("D0A8FF")], ["4", "nourriture", Color("FFE48A")], ["+9", "visiteurs", UiTokens.OR_CLAIR]],
	}


# ------------------------------------------------------------------ capture de contrôle

func _capture_et_quitte() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	var chemin := ProjectSettings.globalize_path("res://").path_join("../capture_galerie.png").simplify_path()
	get_viewport().get_texture().get_image().save_png(chemin)
	print("Capture enregistrée : ", chemin)
	get_tree().quit()
