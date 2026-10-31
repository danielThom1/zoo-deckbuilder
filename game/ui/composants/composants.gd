class_name Composants
extends RefCounted
## Composants d'interface « Émeraude » réutilisables (HANDOFF §5, capture 07) : carte ouvrier, carte d'action,
## pastilles d'icônes, jetons de ressource. Construits en code, comme le reste de l'interface.

const NBSP := " "  # espace insécable avant % (§10 HANDOFF)
const DIMS := {"main": Vector2(136, 216), "draft": Vector2(146, 196), "marche": Vector2(160, 236)}
const HAUTEUR_PORTRAIT := {"main": 98, "draft": 86, "marche": 88}

## Icônes des métiers et traits qui n'ont pas d'icône dédiée dans le handoff.
const ICONES_METIERS := {
	"vendeur": "metier_vendeur_souvenirs", "guichetier": "batiment_entree_zoo", "animalier": "ressource_nourriture",
	"agent_entretien": "ordre_amenager", "animateur": "ressource_reputation",
}
const ICONES_TRAITS := {
	"polyvalent": "ui_ameliorer", "bon_eleve": "batiment_formation", "econome": "ressource_argent", "debrouillard": "ordre_construire",
	"matinal": "ui_jour", "naturaliste": "terrain_planter_foret", "gourmand": "ressource_nourriture", "rabat_joie": "ui_invalide",
	"distrait": "etat_inactif", "tetu": "ui_invalide", "peureux": "etat_pause", "casanier": "batiment_maison",
}
const ICONES_BATIMENTS := {
	"route": "batiment_route", "pont": "batiment_pont", "maison": "batiment_maison", "entrepot": "batiment_entrepot",
	"mine": "batiment_mine_or", "comptoir": "metier_marchand", "agence": "ui_recruter", "cloture": "batiment_enceinte", "entree": "batiment_entree_zoo", "enclos": "batiment_cloture",
	"boutique": "batiment_boutique", "formation": "batiment_formation", "cuisine": "ressource_nourriture",
	"entretien": "ordre_amenager", "snack": "ressource_billetterie", "kiosque": "ressource_reputation",
	"camp_n2": "ui_ameliorer", "camp_n3": "ui_ameliorer", "planter": "terrain_planter_foret", "creuser": "terrain_bassin",
}


# ------------------------------------------------------------------ icônes et petits éléments

static var _portraits := {}


## Portrait dessiné d'un personnage (res://ui/portraits/<id>.svg), mis en cache.
static func texture_portrait(perso_id: String) -> Texture2D:
	if not _portraits.has(perso_id):
		var chemin := "res://ui/portraits/%s.svg" % perso_id
		_portraits[perso_id] = load(chemin) if ResourceLoader.exists(chemin) else null
	return _portraits[perso_id]


static func portrait_rect(perso_id: String, taille: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.texture = texture_portrait(perso_id)
	tr.custom_minimum_size = taille
	tr.size = taille
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


static func icone_metier(metier_id: String) -> String:
	return ICONES_METIERS.get(metier_id, "metier_" + metier_id)


static func icone_trait(trait_id: String, positif: bool) -> String:
	var nom := ("qualite_" if positif else "defaut_") + trait_id
	if ResourceLoader.exists(UiTokens.DOSSIER_ICONES + nom + ".svg"):
		return nom
	return ICONES_TRAITS.get(trait_id, "ui_valide" if positif else "ui_invalide")


static func icone_batiment(id: String) -> String:
	return ICONES_BATIMENTS.get(id, "ordre_amenager")


static func icone_rect(nom: String, taille: Vector2, couleur := Color.WHITE) -> TextureRect:
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


static func placer(parent: Control, enfant: Control, pos: Vector2, taille: Vector2) -> void:
	parent.add_child(enfant)
	enfant.position = pos
	enfant.size = taille


static func label(txt: String, variation := "") -> Label:
	var l := Label.new()
	l.text = txt
	l.theme_type_variation = variation
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func bouton(txt: String, variation := "") -> Button:
	var b := Button.new()
	b.text = txt
	b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 14)
	return b


## Disque de couleur avec une icône blanche centrée (liseré clair en haut pour suggérer le reflet).
static func pastille(fond: Color, nom_icone: String, diametre: int, reflet := Color.TRANSPARENT) -> Control:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = fond
	sb.set_corner_radius_all(diametre)
	if reflet.a > 0.0:
		sb.border_color = Color(reflet, 0.8)
		sb.border_width_top = 2
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(diametre, diametre)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cote := diametre * 0.6
	placer(p, icone_rect(nom_icone, Vector2(cote, cote)), Vector2(diametre * 0.2, diametre * 0.2), Vector2(cote, cote))
	return p


## Qualité = cercle bleu ; défaut = carré orange rayon 3 (double codage couleur + forme).
static func mini_pastille(est_qualite: bool, nom_icone: String, taille := 24) -> Control:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.QUALITE if est_qualite else UiTokens.DEFAUT
	sb.set_corner_radius_all(taille / 2 if est_qualite else 3)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(taille, taille)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cote := taille * 0.62
	placer(p, icone_rect(nom_icone, Vector2(cote, cote)), Vector2((taille - cote) / 2.0, (taille - cote) / 2.0), Vector2(cote, cote))
	return p


static func piece_salaire(valeur: int, orange: bool) -> Control:
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
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(str(valeur), "Compteur")
	l.add_theme_color_override("font_color", UiTokens.BOUTON_TEXTE)
	l.add_theme_font_size_override("font_size", 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placer(p, l, Vector2.ZERO, Vector2(32, 32))
	return p


## Pastille de texte centrée sur une largeur donnée (bandeaux d'état des cartes).
static func pastille_texte(txt: String, fond: Color, largeur: float, y: float) -> Control:
	var centre := CenterContainer.new()
	centre.position = Vector2(0, y)
	centre.size = Vector2(largeur, 22)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.chip(fond, 11, 3))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(txt)
	l.add_theme_font_override("font", UiTokens.police_corps(800))
	l.add_theme_font_size_override("font_size", 11)
	p.add_child(l)
	centre.add_child(p)
	return centre


## Désature un nœud et ses descendants (carte déployée : grisée à 60 %).
static func desaturer(noeud: CanvasItem, force := 0.6, luminosite := 0.8) -> void:
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


## Jeton de ressource de la barre du haut : pastille + valeur + légende.
static func jeton_ressource(nom_icone: String, couleur: Color, reflet: Color, legende: String) -> Dictionary:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	var p := pastille(couleur, nom_icone, 30, reflet)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -6)
	var valeur := label("0", "Compteur")
	v.add_child(valeur)
	var leg := label(legende, "TexteSecondaire")
	leg.add_theme_font_size_override("font_size", 11)
	v.add_child(leg)
	h.add_child(v)
	return {"racine": h, "valeur": valeur, "legende": leg}


# ------------------------------------------------------------------ carte ouvrier

## Données d'affichage d'une carte du jeu.
static func donnees_ouvrier(g: GameState, card: GameState.Card) -> Dictionary:
	var qualites: Array = []
	var defauts: Array = []
	var noms: Array = []  # [texte, genre] avec genre "qualite", "defaut" ou "amelioration"
	for t in g.trait_defs(card):
		var pos := g.is_positive(t["id"])
		(qualites if pos else defauts).append(icone_trait(t["id"], pos))
		noms.append([t["nom"], "qualite" if pos else "defaut"])
	for u in card.upgrade_names:
		noms.append([u, "amelioration"])
	return {"nom": card.nom.to_upper(), "metier": card.metier["nom"], "metier_icone": icone_metier(card.metier["id"]),
		"portrait": g.perso_of(card)["id"],
		"categorie": card.metier["categorie"], "niveau": card.niveau, "salaire": g.salary(card),
		"qualites": qualites, "defauts": defauts, "traits_noms": noms}


## Carte ouvrier (main 136×216, draft 146×196, marché 160×236).
##   d       : nom, metier, metier_icone, categorie, niveau, salaire, qualites[], defauts[] (noms d'icônes)
##   etat    : "normale", "survol", "non_abordable", "deployee", "gratuite", "hors_carte"
##   boutons : jusqu'à 2 [texte, variation, désactivé, Callable] ; un seul occupe toute la largeur
##   bandeau : [texte, couleur] affiché au bas du portrait (ex. « SUR LE TERRAIN »), ou []
##   clic    : Callable appelée par un clic sur la carte (hors boutons), ou Callable()
static func carte_ouvrier(d: Dictionary, etat := "normale", taille := "main", boutons: Array = [], bandeau: Array = [],
		clic := Callable()) -> Control:
	var t: Vector2 = DIMS.get(taille, DIMS["main"])
	var hp: int = HAUTEUR_PORTRAIT.get(taille, 98)
	var cat: Dictionary = UiTokens.CATEGORIES[d["categorie"]]
	var orange := etat == "non_abordable"

	var racine := Control.new()
	racine.custom_minimum_size = t
	racine.size = t
	racine.mouse_filter = Control.MOUSE_FILTER_PASS

	var carte := Panel.new()
	carte.size = t
	carte.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb_carte := UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.DEFAUT if orange else UiTokens.OR, 10, 2, 0)
	if etat == "survol":
		carte.position.y = -18
		sb_carte.border_color = UiTokens.SELECTION
		sb_carte.shadow_color = Color(UiTokens.SELECTION, 0.55)
		sb_carte.shadow_size = 12
		sb_carte.shadow_offset = Vector2.ZERO
	carte.add_theme_stylebox_override("panel", sb_carte)
	racine.add_child(carte)

	# Portrait : haut de carte teinté par catégorie, personnage dessiné, pastille du métier
	var portrait := Panel.new()
	var sb_port := StyleBoxFlat.new()
	sb_port.bg_color = cat["portrait"]
	sb_port.corner_radius_top_left = 8
	sb_port.corner_radius_top_right = 8
	portrait.add_theme_stylebox_override("panel", sb_port)
	portrait.clip_contents = true
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placer(carte, portrait, Vector2(2, 2), Vector2(t.x - 4, hp))
	if d.has("portrait") and texture_portrait(d["portrait"]) != null:
		placer(portrait, portrait_rect(d["portrait"], Vector2(t.x - 4, hp)), Vector2.ZERO, Vector2(t.x - 4, hp))
		var pm := pastille(Color(cat["couleur"]).darkened(0.1), d["metier_icone"], 28, cat["portrait"])
		pm.tooltip_text = d["metier"]
		placer(portrait, pm, Vector2(4, hp - 32), Vector2(28, 28))
	else:
		var accessoire := icone_rect(d["metier_icone"], Vector2(54, 54), Color(cat["couleur"]).darkened(0.15))
		placer(portrait, accessoire, Vector2((t.x - 4 - 54) / 2.0, hp - 64), Vector2(54, 54))

	# Badge catégorie : couleur + icône de forme + libellé (jamais la couleur seule)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UiTokens.chip(cat["couleur"], 11, 2))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 3)
	hb.add_child(icone_rect(cat["icone"], Vector2(14, 14)))
	var lc := label(cat["court"])
	lc.add_theme_font_override("font", UiTokens.police_corps(800))
	lc.add_theme_font_size_override("font_size", 10)
	hb.add_child(lc)
	badge.add_child(hb)
	badge.position = Vector2(6, 6)
	carte.add_child(badge)

	var piece := piece_salaire(int(d["salaire"]), orange)
	piece.position = Vector2(t.x - 38, 6)
	carte.add_child(piece)

	# Nom, métier · niveau
	var y := hp + 6
	var nom := label(d["nom"], "NomCarte")
	nom.add_theme_font_size_override("font_size", 12)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	placer(carte, nom, Vector2(6, y), Vector2(t.x - 12, 18))
	var metier := label("%s · N%d" % [d["metier"], d["niveau"]], "TexteSecondaire")
	metier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	metier.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	placer(carte, metier, Vector2(6, y + 18), Vector2(t.x - 12, 16))

	# Qualités (cercle bleu) / défauts (carré orange)
	var qd := HBoxContainer.new()
	qd.alignment = BoxContainer.ALIGNMENT_CENTER
	qd.add_theme_constant_override("separation", 4)
	qd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for q in d["qualites"]:
		qd.add_child(mini_pastille(true, q, 22))
	for df in d["defauts"]:
		qd.add_child(mini_pastille(false, df, 22))
	placer(carte, qd, Vector2(6, y + 38), Vector2(t.x - 12, 22))

	# Boutons d'action en bas
	var by := t.y - 38

	# Draft et marché : la place libre sous les icônes reçoit le nom des traits (+ qualité, − défaut, ★ amélioration)
	if taille != "main" and not d.get("traits_noms", []).is_empty():
		var parts: Array[String] = []
		for n in d["traits_noms"]:
			match n[1]:
				"qualite":
					parts.append("[color=#8CC4FF]+%s%s[/color]" % [NBSP, n[0]])
				"defaut":
					parts.append("[color=#FFB07A]−%s%s[/color]" % [NBSP, n[0]])
				_:
					parts.append("[color=#FFD45A]★%s%s[/color]" % [NBSP, n[0]])
		var tl := RichTextLabel.new()
		tl.bbcode_enabled = true
		tl.scroll_active = false
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tl.add_theme_font_size_override("normal_font_size", 11)
		tl.text = "[center]%s[/center]" % " · ".join(parts)
		placer(carte, tl, Vector2(6, y + 64), Vector2(t.x - 12, by - y - 66))
	if boutons.size() == 1:
		carte.add_child(_bouton_carte(boutons[0], Vector2(8, by), Vector2(t.x - 16, 30)))
	elif boutons.size() >= 2:
		carte.add_child(_bouton_carte(boutons[0], Vector2(8, by), Vector2(t.x - 62, 30)))
		carte.add_child(_bouton_carte(boutons[1], Vector2(t.x - 50, by), Vector2(42, 30)))

	if not bandeau.is_empty():
		carte.add_child(pastille_texte(bandeau[0], bandeau[1], t.x, hp - 24))
	if etat == "deployee":
		desaturer(portrait)

	# Levée au survol (+8 px, contour or) ; le survol des boutons ne la fait pas retomber
	if etat != "survol":
		carte.mouse_entered.connect(func():
			carte.position.y = -8
			sb_carte.border_color = UiTokens.SELECTION)
		carte.mouse_exited.connect(func():
			if not carte.get_global_rect().has_point(carte.get_global_mouse_position()):
				carte.position.y = 0
				sb_carte.border_color = UiTokens.DEFAUT if orange else UiTokens.OR)
	# Le clic est consommé : sinon il atteindrait le monde, où un clic dans le vide désélectionne tout.
	carte.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			carte.accept_event()
			if ev.pressed and clic.is_valid():
				clic.call())
	return racine


static func _bouton_carte(spec: Array, pos: Vector2, taille: Vector2) -> Button:
	var b := bouton(spec[0], spec[1])
	b.disabled = spec[2]
	if spec.size() > 3 and spec[3] is Callable and spec[3].is_valid():
		b.pressed.connect(spec[3])
	b.position = pos
	b.size = taille
	return b


# ------------------------------------------------------------------ carte d'action

## Carte d'action au format des cartes ouvrier : bandeau or, effet, un bouton.
static func carte_action(card: GameState.Card, texte_bouton: String, desactive: bool, action: Callable, taille := "main") -> Control:
	var t: Vector2 = DIMS.get(taille, DIMS["main"])
	var racine := Control.new()
	racine.custom_minimum_size = t
	racine.size = t
	racine.mouse_filter = Control.MOUSE_FILTER_PASS
	var carte := Panel.new()
	carte.size = t
	carte.mouse_filter = Control.MOUSE_FILTER_PASS
	carte.add_theme_stylebox_override("panel", UiTokens.panel(Color("3A2A12"), UiTokens.OR, 10, 2, 0))
	racine.add_child(carte)
	var bandeau := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.OR
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	bandeau.add_theme_stylebox_override("panel", sb)
	bandeau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placer(carte, bandeau, Vector2(2, 2), Vector2(t.x - 4, 26))
	var kind := label("USAGE UNIQUE")
	kind.add_theme_font_override("font", UiTokens.police_corps(800))
	kind.add_theme_font_size_override("font_size", 11)
	kind.add_theme_color_override("font_color", UiTokens.BOUTON_TEXTE)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placer(bandeau, kind, Vector2(0, 4), Vector2(t.x - 4, 18))
	placer(carte, icone_rect("ui_pioche", Vector2(40, 40), UiTokens.OR_CLAIR), Vector2((t.x - 40) / 2.0, 34), Vector2(40, 40))
	var nom := label(card.action["nom"].to_upper(), "NomCarte")
	nom.add_theme_font_size_override("font_size", 12)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	placer(carte, nom, Vector2(6, 80), Vector2(t.x - 12, 18))
	var txt := label(card.action["texte"], "TexteSecondaire")
	txt.add_theme_font_size_override("font_size", 11)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placer(carte, txt, Vector2(8, 100), Vector2(t.x - 16, t.y - 146))
	carte.add_child(_bouton_carte([texte_bouton, "BoutonPrincipal", desactive, action], Vector2(8, t.y - 38), Vector2(t.x - 16, 30)))
	return racine
