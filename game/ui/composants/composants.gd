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
	"mine": "batiment_mine_or", "comptoir": "metier_marchand", "agence": "ui_recruter", "cabinet": "categorie_cadre", "cloture": "batiment_enceinte", "entree": "batiment_entree_zoo", "enclos": "batiment_cloture",
	"boutique": "batiment_boutique", "formation": "batiment_formation", "cuisine": "ressource_nourriture",
	"entretien": "ordre_amenager", "snack": "ressource_billetterie", "kiosque": "ressource_reputation",
	"camp_n2": "ui_ameliorer", "camp_n3": "ui_ameliorer", "planter": "terrain_planter_foret", "creuser": "terrain_bassin",
	"grand_arbre": "terrain_planter_foret", "rocher_obs": "biome_montagne", "bassin_profond": "terrain_bassin", "abri_chaud": "batiment_maison",
}


# ------------------------------------------------------------------ icônes et petits éléments

static var _portraits := {}


## Portrait dessiné d'un personnage (res://ui/portraits/<id>.svg), mis en cache.
static func texture_portrait(perso_id: String) -> Texture2D:
	if not _portraits.has(perso_id):
		# Style BD : portrait dessiné choisi de façon stable pour ce personnage (assets/bd/sprites/portraits)
		_portraits[perso_id] = SpritesBD.texture(SpritesBD.portrait_de(perso_id))
	return _portraits[perso_id]


## Logo (ou emblème carré) d'un groupe d'après son nom affiché ; null pour un nom sans logo (spectateur : « IA 1 »).
static func logo_groupe(nom: String, embleme := false) -> Texture2D:
	for cle in {"ZooLife": "zoolife", "PanZoo": "panzoo", "Safari": "safari", "BioLand": "bioland"}.keys():
		if nom.begins_with(cle):
			return load("res://assets/bd/logos/%s%s.png" % [cle.to_lower(), "_embleme" if embleme else ""])
	return null


static func image_logo(tex: Texture2D, taille: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.texture = tex
	tr.custom_minimum_size = taille
	tr.size = taille
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


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
	sb.border_color = UiTokens.ENCRE
	sb.set_border_width_all(2 if diametre >= 20 else 1)
	sb.anti_aliasing = true
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
	sb.border_color = UiTokens.ENCRE
	sb.set_border_width_all(2 if taille >= 20 else 1)
	sb.anti_aliasing = true
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(taille, taille)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cote := taille * 0.62
	placer(p, icone_rect(nom_icone, Vector2(cote, cote)), Vector2((taille - cote) / 2.0, (taille - cote) / 2.0), Vector2(cote, cote))
	return p


static func piece_salaire(valeur: int, orange: bool) -> Control:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.DEFAUT if orange else UiTokens.SELECTION
	sb.set_corner_radius_all(16)
	sb.border_color = UiTokens.ENCRE
	sb.set_border_width_all(2)
	sb.anti_aliasing = true
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
	l.add_theme_font_override("font", UiTokens.police_titre())
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", UiTokens.TEXTE_CLAIR)
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
static func jeton_ressource(nom_icone: String, couleur: Color, reflet: Color, legende: String, sprite := "") -> Dictionary:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	var p: Control
	if sprite != "" and SpritesBD.existe(sprite):
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.texture = SpritesBD.texture(sprite)
		tr.custom_minimum_size = Vector2(36, 32)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p = tr
	else:
		p = pastille(couleur, nom_icone, 30, reflet)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -6)
	var valeur := label("0", "Compteur")
	v.add_child(valeur)
	var leg := label(legende.to_upper(), "TexteSecondaire")
	leg.add_theme_font_override("font", UiTokens.police_corps(700))
	leg.add_theme_font_size_override("font_size", 10)
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
	return {"nom": card.nom.to_upper(), "metier": g.job_name(card), "metier_icone": icone_metier(card.metier["id"]),
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
	var sb_carte := UiTokens.panel(UiTokens.PANNEAU_MILIEU, UiTokens.DEFAUT if orange else UiTokens.ENCRE, 12, 3, 0)
	if etat == "survol":
		carte.position.y = -18
		sb_carte.border_color = UiTokens.SELECTION
		sb_carte.shadow_color = UiTokens.ENCRE
		sb_carte.shadow_offset = Vector2(5, 6)
	carte.add_theme_stylebox_override("panel", sb_carte)
	racine.add_child(carte)

	# Portrait : haut de carte teinté par catégorie, personnage dessiné, pastille du métier
	var portrait := Panel.new()
	var sb_port := StyleBoxFlat.new()
	sb_port.bg_color = cat["portrait"]
	sb_port.corner_radius_top_left = 9
	sb_port.corner_radius_top_right = 9
	sb_port.border_color = UiTokens.ENCRE
	sb_port.border_width_bottom = 3
	portrait.add_theme_stylebox_override("panel", sb_port)
	portrait.clip_contents = true
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placer(carte, portrait, Vector2(3, 3), Vector2(t.x - 6, hp))
	if d.has("portrait") and texture_portrait(d["portrait"]) != null:
		placer(portrait, portrait_rect(d["portrait"], Vector2(t.x - 4, hp + 10)), Vector2(0, 6), Vector2(t.x - 4, hp + 10))
		var pm := pastille(Color(cat["couleur"]).darkened(0.1), d["metier_icone"], 28, cat["portrait"])
		pm.tooltip_text = d["metier"]
		placer(portrait, pm, Vector2(4, hp - 32), Vector2(28, 28))
	else:
		var accessoire := icone_rect(d["metier_icone"], Vector2(54, 54), Color(cat["couleur"]).darkened(0.15))
		placer(portrait, accessoire, Vector2((t.x - 4 - 54) / 2.0, hp - 64), Vector2(54, 54))

	# Badge catégorie : couleur + icône de forme + libellé (jamais la couleur seule)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UiTokens.chip(cat["couleur"], 6, 2))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 3)
	hb.add_child(icone_rect(cat["icone"], Vector2(14, 14)))
	var lc := label(cat["court"])
	lc.add_theme_color_override("font_color", UiTokens.TEXTE_CLAIR)
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
	nom.add_theme_font_size_override("font_size", 16)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	placer(carte, nom, Vector2(6, y - 2), Vector2(t.x - 12, 20))
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
					parts.append("[color=#2F7FD8]+%s%s[/color]" % [NBSP, n[0]])
				"defaut":
					parts.append("[color=#B5452A]−%s%s[/color]" % [NBSP, n[0]])
				_:
					parts.append("[color=#8A6A00]★%s%s[/color]" % [NBSP, n[0]])
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
	if boutons.size() >= 3:
		# Cadre : « Jouer » son action, en pilule sur le bas du portrait
		carte.add_child(_bouton_carte(boutons[2], Vector2(t.x - 66, hp - 28), Vector2(60, 26)))

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
				sb_carte.border_color = UiTokens.DEFAUT if orange else UiTokens.ENCRE)
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
	if spec.size() > 4:
		b.tooltip_text = spec[4]
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
	carte.add_theme_stylebox_override("panel", UiTokens.panel(UiTokens.PAPIER, UiTokens.ENCRE, 12, 3, 0))
	racine.add_child(carte)
	var bandeau := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.SELECTION
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.border_color = UiTokens.ENCRE
	sb.border_width_bottom = 3
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


# ================================================================== direction « Le Comité »
# Maquettes : docs/handoff_comite/maquettes/ (briques : Briques.png, feuille de style : Feuille_de_style.png)

const BADGE := Vector2(132, 220)   # racine du badge : 176 visibles au repos, 220 au survol
const BADGE_REPOS := 44.0          # décalage vertical au repos (le bas sort de l'écran)


## Jeton de ressource du dock : icône dessinée 28 px, chiffre en IBM Plex Mono 20, légende en capitales 10.
## Renvoie {racine, valeur, legende, delta} (mêmes clés que jeton_ressource, + delta).
static func jeton_dock(sprite: String, legende: String, couleur_chiffre := UiTokens.ENCRE) -> Dictionary:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.custom_minimum_size = Vector2(112, 38)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if SpritesBD.existe(sprite):
		tr.texture = SpritesBD.texture(sprite)
	tr.custom_minimum_size = Vector2(28, 28)
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tr)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 4)
	var valeur := label("0", "Chiffre")
	valeur.add_theme_color_override("font_color", couleur_chiffre)
	ligne.add_child(valeur)
	var delta := label("", "")
	delta.add_theme_font_override("font", UiTokens.police_mono(600))
	delta.add_theme_font_size_override("font_size", 11)
	delta.add_theme_color_override("font_color", UiTokens.SARCELLE_FONCE)
	delta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ligne.add_child(delta)
	v.add_child(ligne)
	var leg := label(legende.to_upper(), "")
	leg.add_theme_font_override("font", UiTokens.police_corps(700))
	leg.add_theme_font_size_override("font_size", 10)
	leg.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	v.add_child(leg)
	h.add_child(v)
	return {"racine": h, "valeur": valeur, "legende": leg, "delta": delta}


## Badge de collaborateur (main, 132 × 176 visibles) : monte de 44 px au survol et révèle ses boutons.
##   etat    : "normale", "non_abordable", "deployee", "hors_carte", "selectionnee"
##   boutons : [texte, variation, désactivé, Callable, infobulle?] — 1 à 2 en bas ; le 3e (« Jouer » d'un cadre) en pilule sur la photo
##   ligne   : [texte, couleur] = ligne d'état sous le métier (« ● Sur le terrain », « ✕ Manque 2 argent »…)
static func badge_ouvrier(d: Dictionary, etat := "normale", boutons: Array = [], ligne: Array = [], clic := Callable()) -> Control:
	var cat: Dictionary = UiTokens.CATEGORIES[d["categorie"]]
	var racine := Control.new()
	racine.custom_minimum_size = BADGE
	racine.size = BADGE
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var carte := Panel.new()
	carte.size = BADGE
	carte.position.y = BADGE_REPOS
	carte.mouse_filter = Control.MOUSE_FILTER_PASS
	var hors := etat == "hors_carte"
	var sb := UiTokens.panneau(UiTokens.PAPIER, 10, 2, 0, true)
	if hors:
		sb.border_color = UiTokens.ENCRE
		sb.draw_center = true
	if etat == "selectionnee":
		sb.expand_margin_left = 3
		sb.expand_margin_right = 3
		sb.expand_margin_top = 3
		sb.border_color = UiTokens.SELECTION
		sb.set_border_width_all(3)
	carte.add_theme_stylebox_override("panel", sb)
	racine.add_child(carte)
	# trou de cordon
	var trou := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = UiTokens.ENCRE
	st.set_corner_radius_all(3)
	trou.add_theme_stylebox_override("panel", st)
	trou.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placer(carte, trou, Vector2(51, 7), Vector2(30, 6))
	# bande photo teintée par catégorie
	var photo := Panel.new()
	var sp := StyleBoxFlat.new()
	sp.bg_color = cat["portrait"]
	sp.border_color = UiTokens.ENCRE
	sp.border_width_top = 2
	sp.border_width_bottom = 2
	photo.add_theme_stylebox_override("panel", sp)
	photo.clip_contents = true
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placer(carte, photo, Vector2(2, 20), Vector2(BADGE.x - 4, 72))
	if d.has("portrait") and texture_portrait(d["portrait"]) != null:
		var pr := portrait_rect(d["portrait"], Vector2(76, 100))
		placer(photo, pr, Vector2(26, 2), Vector2(76, 100))
		if etat == "deployee" or etat == "non_abordable":
			desaturer(pr, 0.5, 0.9)
	# catégorie (texte + forme) et niveau
	var chip_cat := PanelContainer.new()
	chip_cat.add_theme_stylebox_override("panel", UiTokens.chip(UiTokens.PAPIER, 8, 1))
	chip_cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lc := label(cat["court"], "")
	lc.add_theme_font_override("font", UiTokens.police_titre())
	lc.add_theme_font_size_override("font_size", 10)
	chip_cat.add_child(lc)
	chip_cat.position = Vector2(6, 24)
	carte.add_child(chip_cat)
	var niv := label(str(d["niveau"]), "")
	niv.add_theme_font_override("font", UiTokens.police_mono(600))
	niv.add_theme_font_size_override("font_size", 12)
	niv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	niv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sn := StyleBoxFlat.new()
	sn.bg_color = UiTokens.SELECTION
	sn.border_color = UiTokens.ENCRE
	sn.set_border_width_all(2)
	sn.set_corner_radius_all(11)
	niv.add_theme_stylebox_override("normal", sn)
	niv.tooltip_text = "Niveau %d sur 6" % int(d["niveau"])
	placer(carte, niv, Vector2(BADGE.x - 30, 24), Vector2(22, 22))
	# nom, métier, état
	var nom := label(d["nom"], "")
	nom.add_theme_font_override("font", UiTokens.police_titre())
	nom.add_theme_font_size_override("font_size", 17)
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	placer(carte, nom, Vector2(8, 96), Vector2(BADGE.x - 16, 20))
	var met := label("%s · N%d" % [d["metier"], d["niveau"]], "")
	met.add_theme_font_override("font", UiTokens.police_corps(600))
	met.add_theme_font_size_override("font_size", 11)
	met.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	met.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	met.tooltip_text = d["metier"]
	met.mouse_filter = Control.MOUSE_FILTER_PASS
	placer(carte, met, Vector2(8, 115), Vector2(BADGE.x - 16, 16))
	if not ligne.is_empty():
		var le := label(ligne[0], "")
		le.add_theme_font_override("font", UiTokens.police_corps(700))
		le.add_theme_font_size_override("font_size", 11)
		le.add_theme_color_override("font_color", ligne[1])
		le.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		placer(carte, le, Vector2(8, 132), Vector2(BADGE.x - 16, 16))
	# qualités (cercle bleu) / défauts (carré orange) : double codage conservé
	var qd := HBoxContainer.new()
	qd.add_theme_constant_override("separation", 3)
	qd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for q in d["qualites"]:
		qd.add_child(mini_pastille(true, q, 18))
	for df in d["defauts"]:
		qd.add_child(mini_pastille(false, df, 18))
	placer(carte, qd, Vector2(8, 152), Vector2(BADGE.x - 16, 18))
	# boutons (révélés au survol)
	var by := BADGE.y - 38
	if boutons.size() == 1:
		carte.add_child(_bouton_carte(boutons[0], Vector2(8, by), Vector2(BADGE.x - 16, 30)))
	elif boutons.size() >= 2:
		carte.add_child(_bouton_carte(boutons[0], Vector2(8, by), Vector2(BADGE.x - 54, 30)))
		carte.add_child(_bouton_carte(boutons[1], Vector2(BADGE.x - 42, by), Vector2(34, 30)))
	if boutons.size() >= 3:
		carte.add_child(_bouton_carte(boutons[2], Vector2(BADGE.x - 60, 66), Vector2(54, 24)))
	# montée au survol ; reste levé tant que la souris est sur la carte ou ses boutons
	var monter := func(haut: bool):
		var tw := carte.create_tween()
		tw.tween_property(carte, "position:y", 0.0 if haut else BADGE_REPOS, 0.09)
	carte.mouse_entered.connect(func(): monter.call(true))
	carte.mouse_exited.connect(func():
		if not carte.get_global_rect().has_point(carte.get_global_mouse_position()):
			monter.call(false))
	carte.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			carte.accept_event()
			if ev.pressed and clic.is_valid():
				clic.call())
	return racine


## Badge d'une carte d'action (même gabarit, fond jaune clair, contour pointillé simulé par un filet doux).
static func badge_action(card: GameState.Card, texte_bouton: String, desactive: bool, action: Callable) -> Control:
	var racine := Control.new()
	racine.custom_minimum_size = BADGE
	racine.size = BADGE
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var carte := Panel.new()
	carte.size = BADGE
	carte.position.y = BADGE_REPOS
	carte.mouse_filter = Control.MOUSE_FILTER_PASS
	carte.add_theme_stylebox_override("panel", UiTokens.panneau(Color("FFFBEA"), 10, 2, 0, true))
	racine.add_child(carte)
	var k := label("CARTE D'ACTION", "")
	k.add_theme_font_override("font", UiTokens.police_titre())
	k.add_theme_font_size_override("font_size", 10)
	k.add_theme_color_override("font_color", UiTokens.OR_TEXTE)
	placer(carte, k, Vector2(8, 20), Vector2(BADGE.x - 16, 14))
	var nom := label(str(card.action["nom"]).to_upper(), "")
	nom.add_theme_font_override("font", UiTokens.police_titre())
	nom.add_theme_font_size_override("font_size", 17)
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placer(carte, nom, Vector2(8, 36), Vector2(BADGE.x - 16, 40))
	var txt := label(str(card.action["texte"]), "")
	txt.add_theme_font_override("font", UiTokens.police_corps(600))
	txt.add_theme_font_size_override("font_size", 11)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.clip_text = true
	placer(carte, txt, Vector2(8, 78), Vector2(BADGE.x - 16, 92))
	carte.add_child(_bouton_carte([texte_bouton, "BoutonPrincipal", desactive, action], Vector2(8, BADGE.y - 38), Vector2(BADGE.x - 16, 30)))
	carte.tooltip_text = "%s : %s" % [card.action["nom"], card.action["texte"]]
	carte.mouse_entered.connect(func(): carte.create_tween().tween_property(carte, "position:y", 0.0, 0.09))
	carte.mouse_exited.connect(func():
		if not carte.get_global_rect().has_point(carte.get_global_mouse_position()):
			carte.create_tween().tween_property(carte, "position:y", BADGE_REPOS, 0.09))
	carte.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			carte.accept_event())
	return racine


## En-tête de panneau Comité : bande colorée, titre condensé blanc, valeur à droite (mono).
static func entete_comite(titre: String, droite := "", couleur := UiTokens.SARCELLE) -> Dictionary:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UiTokens.entete(couleur))
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	pc.add_child(hb)
	var t := label(titre.to_upper(), "EnteteComite")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hb.add_child(t)
	var r := label(droite, "")
	r.add_theme_font_override("font", UiTokens.police_mono(600))
	r.add_theme_font_size_override("font_size", 12)
	r.add_theme_color_override("font_color", UiTokens.PAPIER)
	hb.add_child(r)
	return {"racine": pc, "titre": t, "droite": r}
