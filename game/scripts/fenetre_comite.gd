class_name FenetreComite
extends ColorRect
## Ce qu'ont en commun les écrans « Le Comité » construits en code (conseil de nuit, marché du soir) : petits outils de
## texte, badges de collaborateurs, cartes d'action, motif lettré, répliques d'Hubert.

const LETTRES := {"Prairie": "P", "Foret": "F", "Eau": "E", "Roche": "R", "Sable": "S"}
const FOND_MOTIF := {"Prairie": Color("9CD36A"), "Foret": Color("3E8F4E"), "Eau": Color("6EC3EA"), "Roche": Color("BDB8AA"), "Sable": Color("F1D58C")}
const ICONES_CARTES := {"heures_sup": "qualite_rapide", "prime": "ressource_argent", "portes_ouvertes": "ressource_visiteurs", "livraison": "ressource_bois",
	"recrutement": "ui_recruter", "formation_express": "batiment_formation", "licenciement": "ui_invalide", "promotion": "ui_ameliorer"}
const GRIS_PRIS := Color("F1F2F4")

var m  # main.gd
var ordres := {}  # étape -> objets dans leur ordre d'apparition : une carte prise reste à sa place
var ordres_nuit := -1
var tient_memo := {}


## Motif en cases lettrées : la couleur n'est jamais seule (P, F, E, R, S).
class MotifLettre extends Control:
	var motif: Array = []
	var cote := 15.0

	func regler(def: Dictionary, c: float) -> void:
		motif = def["motif"]
		cote = c
		var w := 0
		var h := 0
		for k in motif:
			w = maxi(w, int(k[0]) + 1)
			h = maxi(h, int(k[1]) + 1)
		custom_minimum_size = Vector2(w, h) * (cote + 1.0) + Vector2.ONE
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var f := UiTokens.police_corps(800)
		var sz := int(cote * 0.62)
		for k in motif:
			var t := str(k[2])
			var r := Rect2(Vector2(int(k[0]), int(k[1])) * (cote + 1.0), Vector2(cote, cote))
			draw_rect(r, FOND_MOTIF.get(t, Color.GRAY))
			draw_rect(r, UiTokens.ENCRE, false, 1.2)
			var l: String = LETTRES.get(t, "?")
			var w := f.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
			draw_string(f, r.position + Vector2((cote - w) / 2.0, cote * 0.5 + sz * 0.36), l, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color.WHITE if t == "Foret" else UiTokens.ENCRE)


func _init(principal) -> void:
	m = principal
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


## Appelé quand les marchés changent de nuit.
func _nouvelle_nuit() -> void:
	pass


## Bas d'un grand badge : bouton d'embauche la nuit, prix en journée.
func _pied_collaborateur(_t: VBoxContainer, _card: GameState.Card) -> void:
	pass


## Par-dessus la photo d'un grand badge.
func _sur_photo(_racine: Control, _card: GameState.Card) -> void:
	pass


## Bas d'une grande carte d'action.
func _pied_carte(_t: VBoxContainer, _card: GameState.Card) -> void:
	pass


## Par-dessus le haut d'une grande carte d'action.
func _sur_carte(_haut: Control, _card: GameState.Card) -> void:
	pass


func _corps(txt: String, sz := 14, graisse := 600, couleur := UiTokens.ENCRE) -> Label:
	var l := Composants.label(txt)
	l.add_theme_font_override("font", UiTokens.police_corps(graisse))
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", couleur)
	return l


func _cond(txt: String, sz := 20, couleur := UiTokens.ENCRE) -> Label:
	var l := Composants.label(txt)
	l.add_theme_font_override("font", UiTokens.police_titre())
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", couleur)
	return l


func _mono(txt: String, sz := 14, graisse := 600, couleur := UiTokens.ENCRE) -> Label:
	var l := Composants.label(txt)
	l.add_theme_font_override("font", UiTokens.police_mono(graisse))
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", couleur)
	return l


func _replie(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_constant_override("line_spacing", -3)
	return l


## Contour en tirets sur tout le panneau : un enfant serait décalé par les marges du PanelContainer.
func _tirets_sur(p: Control, rayon := 10) -> void:
	p.draw.connect(func(): Composants.tirets_rect(p, Rect2(Vector2(1, 1), p.size - Vector2(2, 2)), UiTokens.ENCRE_DOUX, 2.0, float(rayon)))


## Pastille écrite (« ▼ moins cher »).
func _pilule(txt: String, fond := UiTokens.SARCELLE, texte := UiTokens.PAPIER, sz := 11, bord := false) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = fond
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	sb.anti_aliasing = true
	if bord:
		sb.border_color = UiTokens.ENCRE
		sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(_corps(txt, sz, 700, texte))
	return p


func _espace_v() -> Control:
	var e := Control.new()
	e.size_flags_vertical = Control.SIZE_EXPAND_FILL
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return e


func _nom_court(i: int) -> String:
	if i == m.game.index:
		return "Vous"
	return str(m.mt.names[i]).replace(" Holdings", "")


func _logo(i: int, taille := 22.0) -> Control:
	var t := Composants.logo_groupe(m.mt.names[i], true)
	if t == null:
		var e := Control.new()
		e.custom_minimum_size = Vector2(taille, taille)
		return e
	return Composants.image_logo(t, Vector2(taille, taille))


func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


## Objets de l'étape dans l'ordre où on les a vus cette nuit : une carte prise ne fait pas bouger les autres.
func _dans_l_ordre(etape: String, presents: Array) -> Array:
	if ordres_nuit != m.mt.day:
		ordres_nuit = m.mt.day
		ordres = {}
		tient_memo = {}
		_nouvelle_nuit()
	var liste: Array = ordres.get(etape, [])
	for o in presents:
		if not liste.has(o):
			liste.append(o)
	ordres[etape] = liste
	return liste.filter(func(o): return presents.has(o))


## Qui a pris cet objet cette nuit, ou -1.
func _preneur(etape: String, objet: Variant) -> int:
	for t in m.mt.night_taken:
		if t["etape"] == etape and t["objet"] == objet:
			return int(t["joueur"])
	return -1


func _objets_pris(etape: String) -> Array:
	var out := []
	for t in m.mt.night_taken:
		if t["etape"] == etape:
			out.append(t["objet"])
	return out


func _bouton_ou_raison(texte: String, raison_courte: String, raison: String, action: Callable, hauteur := 40.0) -> Button:
	var b: Button
	if raison_courte != "":
		b = Composants.bouton_indisponible(raison_courte, raison)
	else:
		b = Composants.bouton(texte, "BoutonPrincipal")
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(action)
	b.custom_minimum_size.y = hauteur
	return b


func _jeton(sprite: String, txt: String, couleur := UiTokens.ENCRE) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	if SpritesBD.existe(sprite):
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.texture = SpritesBD.texture(sprite)
		tr.custom_minimum_size = Vector2(24, 24)
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(tr)
	h.add_child(_mono(txt, 18, 600, couleur))
	return h


func _memo_hubert(moment: String, parent: Control, largeur := 470.0, repli := "") -> void:
	var hubert: BulleHubert = m.hubert
	if hubert == null:
		return
	var cle := "%d_%s" % [m.mt.day, moment]
	if not m.memo_lignes.has(cle):
		m.memo_lignes[cle] = hubert.replique(moment)
	var ligne: String = m.memo_lignes[cle]
	if ligne == "":
		ligne = repli
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.MEMO
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	if largeur > 0.0:
		p.custom_minimum_size.x = largeur
	else:
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var tete := Composants.image_logo(hubert.expression(moment), Vector2(64, 64))
	tete.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tete)
	var t := Composants.label("« %s » — H. de la Marge" % ligne)
	t.add_theme_font_override("font", UiTokens.police_italique())
	t.add_theme_font_size_override("font_size", 14)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(t)
	parent.add_child(p)


## « ✓ tient » ou ce qui manque : informe avant d'acheter, sans rien calculer pour l'IA.
func _tient(def: Dictionary) -> Array:
	var id := str(def["id"])
	if tient_memo.has(id):
		return tient_memo[id]
	var game: GameState = m.game
	var interieur: Dictionary = game.zoo_status()["interior"]
	var res: Array
	if interieur.is_empty():
		res = [false, "enceinte à fermer"]
	elif not game.enclosure_site(def).is_empty():
		res = [true, "tient"]
	elif interieur.size() < int(def["taille"]):
		res = [false, "parc trop petit"]
	else:
		var st := game.pattern_status(def, interieur.keys())
		if st["found"]:
			res = [false, "place occupée"]
		elif int(st["missing"]) >= 99:
			res = [false, "forme impossible"]
		else:
			res = [false, "%d case%s à aménager" % [st["missing"], "s" if int(st["missing"]) > 1 else ""]]
	tient_memo[id] = res
	return res


func _image_animal(id: String, pris: bool) -> Control:
	var boite := Control.new()
	boite.custom_minimum_size = Vector2(0, 92)
	boite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var esp = SpritesBD.ANIMAUX.get(id)
	if esp != null and SpritesBD.existe(str(esp[0])):
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.texture = SpritesBD.texture(str(esp[0]))
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if pris:
			Composants.desaturer(tr, 1.0, 1.0)
			tr.modulate.a = 0.5
		boite.add_child(tr)
	return boite


func _grand_badge(card: GameState.Card, est_pris: bool, h_photo := 150) -> Control:
	var game: GameState = m.game
	var d := Composants.donnees_ouvrier(game, card)
	var cat: Dictionary = UiTokens.CATEGORIES[d["categorie"]]
	var racine := PanelContainer.new()
	var sb := UiTokens.panneau(UiTokens.PAPIER if not est_pris else Color("E2E5EA"), 12, 2, 2, true, UiTokens.ENCRE if not est_pris else UiTokens.ENCRE_DOUX)
	if est_pris:
		sb.shadow_color = UiTokens.ENCRE_DOUX
	racine.add_theme_stylebox_override("panel", sb)
	racine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	racine.custom_minimum_size.x = 100
	racine.tooltip_text = m._card_full_tooltip(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	racine.add_child(v)
	# Cordon
	var cordon := Control.new()
	cordon.custom_minimum_size.y = 28
	cordon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fente := ColorRect.new()
	fente.color = UiTokens.ENCRE if not est_pris else UiTokens.ENCRE_DOUX
	fente.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	fente.offset_left = -20
	fente.offset_right = 20
	fente.offset_top = 14
	fente.offset_bottom = 21
	fente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cordon.add_child(fente)
	var attache := ColorRect.new()
	attache.color = UiTokens.SARCELLE if not est_pris else UiTokens.ENCRE_DOUX
	attache.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	attache.offset_left = -13
	attache.offset_right = 13
	attache.offset_top = 2
	attache.offset_bottom = 14
	attache.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cordon.add_child(attache)
	v.add_child(cordon)
	# Photo
	var photo := PanelContainer.new()
	var sp := StyleBoxFlat.new()
	sp.bg_color = cat["portrait"] if not est_pris else Color("CDD1D8")
	sp.border_color = UiTokens.ENCRE if not est_pris else UiTokens.ENCRE_DOUX
	sp.border_width_top = 2
	sp.border_width_bottom = 2
	photo.add_theme_stylebox_override("panel", sp)
	photo.custom_minimum_size.y = h_photo
	photo.clip_contents = true
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pr := Composants.portrait_rect(d["portrait"], Vector2(h_photo * 0.94, h_photo))
	pr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if est_pris:
		Composants.desaturer(pr, 1.0, 1.0)
	photo.add_child(pr)
	v.add_child(photo)
	if not est_pris and not game.all_employees().any(func(c): return c.metier["id"] == card.metier["id"]):
		var neuf := _pilule("Nouveau métier", UiTokens.SELECTION, UiTokens.ENCRE, 11, true)
		neuf.position = Vector2(8, 34)
		racine.add_child(_hors_conteneur(neuf))
	_sur_photo(racine, card)
	var corps := MarginContainer.new()
	for c in [["left", 12], ["right", 12], ["top", 8], ["bottom", 14]]:
		corps.add_theme_constant_override("margin_" + c[0], c[1])
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(corps)
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 6)
	corps.add_child(t)
	var encre: Color = UiTokens.ENCRE if not est_pris else UiTokens.ENCRE_DOUX
	var nom := _cond(str(d["nom"]), 26, encre)
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.add_child(nom)
	t.add_child(_corps("%s · N%d" % [d["metier"], d["niveau"]], 13, 700, encre))
	if est_pris:
		var preneur := _preneur("ouvriers", card)
		var tampon := _tampon_pris(preneur)
		t.add_child(tampon)
		return racine
	var pills := HBoxContainer.new()
	pills.add_theme_constant_override("separation", 6)
	var genre: String = game.agree(card, str(cat["long"]), str(cat["long"]) + "e") if not str(cat["long"]).ends_with("re") else str(cat["long"])
	pills.add_child(_pilule(genre, UiTokens.PAPIER, UiTokens.ENCRE, 11, true))
	var ps := _pilule("%d / jour" % int(d["salaire"]), UiTokens.PAPIER, UiTokens.ENCRE, 11, true)
	ps.get_child(0).add_theme_font_override("font", UiTokens.police_mono(600))
	pills.add_child(ps)
	t.add_child(pills)
	# Le métier en clair
	var phrase := str(card.metier.get("capacite", ""))
	if phrase == "":
		phrase = m._job_text(card)
	var ph := _replie(_corps(phrase, 12, 600, UiTokens.TEXTE_2))
	t.add_child(ph)
	var A := game.cadre_action(card)
	if not A.is_empty():
		var aj := _replie(_corps("Jouée : %s. %s" % [A["nom"], A["texte"]], 12, 600, UiTokens.SARCELLE_FONCE))
		t.add_child(aj)
	for tr in game.trait_defs(card):
		t.add_child(_ligne_trait(tr))
	t.add_child(_espace_v())
	_pied_collaborateur(t, card)
	return racine


## Un PanelContainer étire ses enfants : ce qui flotte par-dessus passe par un calque sans mise en page.
func _hors_conteneur(enfant: Control) -> Control:
	var calque := Control.new()
	calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	calque.add_child(enfant)
	return calque


func _ligne_trait(tr: Dictionary) -> Control:
	var game: GameState = m.game
	var pos: bool = game.is_positive(tr["id"])
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var marque := Composants.mini_pastille(pos, Composants.icone_trait(tr["id"], pos), 16)
	marque.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(marque)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_size_override("normal_font_size", 12)
	rt.add_theme_font_size_override("bold_font_size", 12)
	rt.add_theme_color_override("default_color", UiTokens.ENCRE)
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.text = "[b]%s[/b] · %s" % [tr["nom"], m._trait_texte(tr)]
	h.add_child(rt)
	return h


func _tampon_pris(joueur: int) -> Control:
	var boite := CenterContainer.new()
	boite.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 6, 3, 10, false))
	p.rotation = deg_to_rad(-8)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var lg := _logo(joueur, 34)
	lg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(lg)
	v.add_child(_cond("PRIS PAR %s" % _nom_court(joueur).to_upper(), 17))
	boite.add_child(p)
	return boite


func _grande_carte(card: GameState.Card, est_pris: bool, h_haut := 150, h_mini := 380) -> Control:
	var game: GameState = m.game
	var conseille: bool = not est_pris and card.action.get("id", "") == "portes_ouvertes" and game.zoo_status().get("open", false)
	var racine := PanelContainer.new()
	var sb := UiTokens.panneau(UiTokens.PAPIER if not est_pris else GRIS_PRIS, 12, 2, 2, true, UiTokens.ENCRE if not est_pris else UiTokens.ENCRE_DOUX)
	if est_pris:
		sb.shadow_color = UiTokens.ENCRE_DOUX
	if conseille:
		sb.border_color = UiTokens.SELECTION
		sb.set_border_width_all(3)
	racine.add_theme_stylebox_override("panel", sb)
	racine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	racine.custom_minimum_size = Vector2(100, h_mini)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	racine.add_child(v)
	var haut := PanelContainer.new()
	var sh := StyleBoxFlat.new()
	sh.bg_color = UiTokens.JAUNE_CLAIR if not est_pris else Color("E2E5EA")
	sh.corner_radius_top_left = 10
	sh.corner_radius_top_right = 10
	sh.border_color = UiTokens.ENCRE if not est_pris else UiTokens.ENCRE_DOUX
	sh.border_width_bottom = 2
	haut.add_theme_stylebox_override("panel", sh)
	haut.custom_minimum_size.y = h_haut
	var hc := Control.new()
	hc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	haut.add_child(hc)
	var coul: Color = UiTokens.ENCRE if not est_pris else UiTokens.ENCRE_DOUX
	var ic := Composants.icone_rect(ICONES_CARTES.get(str(card.action.get("id", "")), "ui_pioche"), Vector2(84, 84), coul)
	ic.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ic.offset_left = -42
	ic.offset_right = 42
	ic.offset_top = -38
	ic.offset_bottom = 46
	hc.add_child(ic)
	var pu := _pilule("USAGE UNIQUE", UiTokens.PAPIER, coul, 10, true)
	pu.get_child(0).add_theme_font_override("font", UiTokens.police_mono(600))
	pu.position = Vector2(12, 10)
	hc.add_child(pu)
	_sur_carte(hc, card)
	v.add_child(haut)
	var marge := MarginContainer.new()
	for c in [["left", 16], ["right", 16], ["top", 14], ["bottom", 16]]:
		marge.add_theme_constant_override("margin_" + c[0], c[1])
	marge.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(marge)
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 8)
	marge.add_child(t)
	var nom := _replie(_cond(str(card.action["nom"]).to_upper(), 26, coul))
	t.add_child(nom)
	t.add_child(_replie(_corps(str(card.action["texte"]), 14, 600, coul if est_pris else UiTokens.ENCRE)))
	if not est_pris:
		var ciblee: bool = card.action.get("cible", false)
		var pil := PanelContainer.new()
		pil.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 0 if ciblee else 1, 2, false))
		pil.get_theme_stylebox("panel").content_margin_left = 8
		var lc := _corps("◎ choisir une cible" if ciblee else "sans cible", 12, 700)
		pil.add_child(lc)
		if ciblee:
			_tirets_sur(pil, 10)
		t.add_child(pil)
		if conseille:
			var co := PanelContainer.new()
			var sc := StyleBoxFlat.new()
			sc.bg_color = Color("D8F0EC")
			sc.set_corner_radius_all(6)
			sc.content_margin_left = 8
			sc.content_margin_right = 8
			sc.content_margin_top = 3
			sc.content_margin_bottom = 3
			co.add_theme_stylebox_override("panel", sc)
			co.add_child(_corps("Conseillé : votre zoo est ouvert", 12, 700))
			t.add_child(co)
	t.add_child(_espace_v())
	if est_pris:
		var hp := HBoxContainer.new()
		hp.add_theme_constant_override("separation", 6)
		var preneur := _preneur("cartes", card)
		hp.add_child(_logo(preneur, 28))
		hp.add_child(_corps("Pris par %s" % _nom_court(preneur), 13, 700, UiTokens.TEXTE_2))
		t.add_child(hp)
	else:
		_pied_carte(t, card)
	return racine


func _cadre_tirets(rayon := 8) -> Control:
	var c := Composants.CadreTirets.new()
	c.rayon = rayon
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Cartes du joueur, toutes piles confondues.
func _stats_deck() -> Dictionary:
	var game: GameState = m.game
	var cartes: Array = []
	cartes.append_array(game.deck)
	cartes.append_array(game.discard)
	cartes.append_array(game.hand)
	for c in game.all_employees():
		if not cartes.has(c):
			cartes.append(c)
	var collab := cartes.filter(func(c): return not c.is_action()).size()
	return {"collab": collab, "actions": cartes.size() - collab, "total": cartes.size(), "main": game.hand_size()}


## Chance (en %) d'avoir au moins une action dans une main tirée du deck entier.
func _chance_action(actions: int, total: int, main: int) -> int:
	var aucune := 1.0
	for k in mini(main, total):
		aucune *= maxf(0.0, float(total - actions - k)) / float(total - k)
	return roundi((1.0 - aucune) * 100.0)
