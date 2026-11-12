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
	"agent_entretien": "ordre_amenager", "intendant": "terrain_planter_foret", "animateur": "ressource_reputation",
}
const ICONES_TRAITS := {
	"polyvalent": "ui_ameliorer", "bon_eleve": "batiment_formation", "econome": "ressource_argent", "debrouillard": "ordre_construire",
	"matinal": "ui_jour", "naturaliste": "terrain_planter_foret", "gourmand": "ressource_nourriture", "rabat_joie": "ui_invalide",
	"distrait": "etat_inactif", "tetu": "ui_invalide", "peureux": "etat_pause", "casanier": "batiment_maison",
}
const ICONES_BATIMENTS := {
	"route": "batiment_route", "pont": "batiment_pont", "maison": "batiment_maison", "entrepot": "batiment_entrepot",
	"mine": "batiment_mine_or", "comptoir": "metier_marchand", "agence": "ui_recruter", "cabinet": "categorie_cadre", "acquisitions": "ressource_argent", "cloture": "batiment_enceinte", "entree": "batiment_entree_zoo", "enclos": "batiment_cloture",
	"boutique": "batiment_boutique", "cuisine": "ressource_nourriture",
	"entretien": "ordre_amenager", "intendance": "terrain_planter_foret", "snack": "ressource_billetterie", "kiosque": "ressource_reputation",
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
	if hors:
		sb.set_border_width_all(0)
		carte.draw.connect(func(): tirets_rect(carte, Rect2(Vector2(1, 1), carte.size - Vector2(2, 2)), UiTokens.ENCRE, 2.0, 10.0))
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
	# Tâche en cours (pastille ronde sur le portrait) : icône de la tâche sur fond sarcelle, « zzz » orange si inactif
	if d.has("tache"):
		var t: Dictionary = d["tache"]
		var pa := Panel.new()
		var spa := StyleBoxFlat.new()
		spa.bg_color = UiTokens.ORANGE if t.get("inactif", false) else UiTokens.SARCELLE
		spa.border_color = UiTokens.ENCRE
		spa.set_border_width_all(2)
		spa.set_corner_radius_all(15)
		pa.add_theme_stylebox_override("panel", spa)
		pa.tooltip_text = str(t.get("texte", ""))
		pa.mouse_filter = Control.MOUSE_FILTER_PASS
		placer(carte, pa, Vector2(6, 58), Vector2(30, 30))
		if t.get("inactif", false):
			var z := label("zzz", "")
			z.add_theme_font_override("font", UiTokens.police_mono(600))
			z.add_theme_font_size_override("font_size", 11)
			z.add_theme_color_override("font_color", Color.WHITE)
			z.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			z.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			z.mouse_filter = Control.MOUSE_FILTER_IGNORE
			placer(pa, z, Vector2.ZERO, Vector2(30, 30))
		elif UiTokens.icone(str(t["icone"])) != null:
			var ic := TextureRect.new()
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.texture = UiTokens.icone(str(t["icone"]))
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			placer(pa, ic, Vector2(6, 6), Vector2(18, 18))
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
	carte.add_theme_stylebox_override("panel", UiTokens.panneau(Color("FFFBEA"), 10, 0, 0, true))
	carte.draw.connect(func(): tirets_rect(carte, Rect2(Vector2(1, 1), carte.size - Vector2(2, 2)), UiTokens.ENCRE, 2.0, 10.0))
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


## Contour en tirets (StyleBoxFlat ne sait pas les faire) : à poser en enfant d'un Button ou d'un PanelContainer.
class CadreTirets extends Control:
	var rayon := 8
	var couleur := UiTokens.ENCRE

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		Composants.tirets_rect(self, Rect2(Vector2(1, 1), size - Vector2(2, 2)), couleur, 2.0, float(rayon))


## Dessine un rectangle en tirets, coins arrondis si rayon > 0.
static func tirets_rect(ci: CanvasItem, r: Rect2, couleur: Color, epaisseur := 1.5, rayon := 0.0) -> void:
	ci.draw_dashed_line(r.position + Vector2(rayon, 0), r.position + Vector2(r.size.x - rayon, 0), couleur, epaisseur, 6.0)
	ci.draw_dashed_line(Vector2(r.end.x, r.position.y + rayon), r.end - Vector2(0, rayon), couleur, epaisseur, 6.0)
	ci.draw_dashed_line(Vector2(r.position.x + rayon, r.end.y), Vector2(r.end.x - rayon, r.end.y), couleur, epaisseur, 6.0)
	ci.draw_dashed_line(r.position + Vector2(0, rayon), Vector2(r.position.x, r.end.y - rayon), couleur, epaisseur, 6.0)
	if rayon > 0.0:
		ci.draw_arc(r.position + Vector2(rayon, rayon), rayon, PI, PI * 1.5, 8, couleur, epaisseur)
		ci.draw_arc(Vector2(r.end.x - rayon, r.position.y + rayon), rayon, PI * 1.5, TAU, 8, couleur, epaisseur)
		ci.draw_arc(r.end - Vector2(rayon, rayon), rayon, 0.0, PI * 0.5, 8, couleur, epaisseur)
		ci.draw_arc(Vector2(r.position.x + rayon, r.end.y - rayon), rayon, PI * 0.5, PI, 8, couleur, epaisseur)


## Bouton indisponible : pointillé et raison écrite, jamais la couleur seule (« Manque 2 or »).
static func bouton_indisponible(texte: String, infobulle := "") -> Button:
	var b := Button.new()
	b.text = texte
	b.disabled = true
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = infobulle
	b.add_theme_font_override("font", UiTokens.police_corps(700))
	b.add_theme_font_size_override("font_size", 13)
	b.clip_text = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.PAPIER
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	b.add_theme_stylebox_override("disabled", sb)
	b.add_theme_color_override("font_disabled_color", UiTokens.TEXTE_2)
	b.add_child(CadreTirets.new())
	return b


## Niveau dans un disque jaune cerné, chiffre en mono.
static func pastille_niveau(niveau: int, d := 30) -> Control:
	var l := label(str(niveau), "")
	l.add_theme_font_override("font", UiTokens.police_mono(600))
	l.add_theme_font_size_override("font_size", int(d * 0.45))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sn := StyleBoxFlat.new()
	sn.bg_color = UiTokens.SELECTION
	sn.border_color = UiTokens.ENCRE
	sn.set_border_width_all(2)
	sn.set_corner_radius_all(d)
	sn.anti_aliasing = true
	l.add_theme_stylebox_override("normal", sn)
	l.custom_minimum_size = Vector2(d, d)
	l.tooltip_text = "Niveau %d sur 6" % niveau
	return l


## Fenêtre « Comité » : voile d'encre, panneau clair centré, en-tête blanc (sur-titre mono, titre condensé, ✕), corps, pied blanc.
## Renvoie {racine, corps, droite, pied, pied_boite} ; le pied reste caché tant qu'on ne l'affiche pas.
static func fenetre(taille: Vector2, sur: String, titre: String, fermer := Callable()) -> Dictionary:
	var voile := ColorRect.new()
	voile.color = Color(UiTokens.ENCRE, 0.55)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.FOND_FENETRE, 12, 2, 2, true))
	p.custom_minimum_size = taille
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	voile.add_child(p)
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
	h.add_theme_constant_override("separation", 16)
	tete.add_child(h)
	var tb := VBoxContainer.new()
	tb.add_theme_constant_override("separation", 0)
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tb)
	if sur != "":
		var ls := label(sur.to_upper())
		ls.add_theme_font_override("font", UiTokens.police_mono(500))
		ls.add_theme_font_size_override("font_size", 12)
		ls.add_theme_color_override("font_color", UiTokens.TEXTE_2)
		tb.add_child(ls)
	var lt := label(titre)
	lt.add_theme_font_override("font", UiTokens.police_titre())
	lt.add_theme_font_size_override("font_size", 30)
	tb.add_child(lt)
	var droite := HBoxContainer.new()
	droite.add_theme_constant_override("separation", 8)
	droite.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(droite)
	if fermer.is_valid():
		var x := bouton("✕", "BoutonSecondaire")
		x.custom_minimum_size = Vector2(40, 40)
		x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		x.pressed.connect(fermer)
		h.add_child(x)
	var marge := MarginContainer.new()
	for c in [["left", 18], ["right", 18], ["top", 14], ["bottom", 14]]:
		marge.add_theme_constant_override("margin_" + c[0], c[1])
	marge.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(marge)
	var corps := VBoxContainer.new()
	corps.add_theme_constant_override("separation", 10)
	marge.add_child(corps)
	var pied_boite := PanelContainer.new()
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
	pied_boite.add_theme_stylebox_override("panel", sp)
	pied_boite.visible = false
	v.add_child(pied_boite)
	var pied := HBoxContainer.new()
	pied.add_theme_constant_override("separation", 10)
	pied_boite.add_child(pied)
	return {"racine": voile, "corps": corps, "droite": droite, "pied": pied, "pied_boite": pied_boite}


## Titre de section dans une fenêtre : condensé, secondaire.
static func titre_section(t: String, taille := 14) -> Label:
	var l := label(t.to_upper())
	l.add_theme_font_override("font", UiTokens.police_titre())
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	return l


## Texte courant qui passe à la ligne, interligne serré.
static func paragraphe(t: String, taille := 14, couleur := UiTokens.ENCRE) -> Label:
	var l := label(t)
	l.add_theme_font_override("font", UiTokens.police_corps(600))
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_constant_override("line_spacing", -3)
	return l


# ---------------------------------------------------------------- menus, statistiques, défis (docs/handoff_menus)

## Texte d'une seule graisse : police (corps, titre condensé, mono, italique), taille, couleur.
static func texte(t: String, taille := 14, graisse := 600, couleur := UiTokens.ENCRE, famille := "corps") -> Label:
	var l := label(t)
	match famille:
		"titre":
			l.add_theme_font_override("font", UiTokens.police_titre())
		"mono":
			l.add_theme_font_override("font", UiTokens.police_mono(graisse))
		"italique":
			l.add_theme_font_override("font", UiTokens.police_italique())
		_:
			l.add_theme_font_override("font", UiTokens.police_corps(graisse))
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l


## Petite forme pleine (double codage couleur + forme) : rond, carre, losange, triangle, etoile.
class Forme extends Control:
	var forme := "rond"
	var couleur := UiTokens.ENCRE
	var contour := Color.TRANSPARENT
	var creux := false

	func _init(f := "rond", c := UiTokens.ENCRE, taille := 10.0) -> void:
		forme = f
		couleur = c
		custom_minimum_size = Vector2(taille, taille)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		var pts := PackedVector2Array()
		match forme:
			"rond":
				if creux:
					draw_circle(c, r - 1.0, UiTokens.PAPIER, true, -1.0, true)
					draw_arc(c, r - 1.0, 0.0, TAU, 24, couleur, 2.0, true)
				else:
					draw_circle(c, r, couleur, true, -1.0, true)
					if contour.a > 0.0:
						draw_arc(c, r - 0.75, 0.0, TAU, 24, contour, 1.5, true)
				return
			"carre":
				pts = PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), size, Vector2(0, size.y)])
			"losange":
				pts = PackedVector2Array([Vector2(c.x, 0), Vector2(size.x, c.y), Vector2(c.x, size.y), Vector2(0, c.y)])
			"triangle":
				pts = PackedVector2Array([Vector2(c.x, 0), size, Vector2(0, size.y)])
			"etoile":
				for k in 10:
					var a := -PI / 2.0 + k * PI / 5.0
					pts.append(c + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.42))
		draw_colored_polygon(pts, couleur)
		if contour.a > 0.0:
			var ferme := pts.duplicate()
			ferme.append(pts[0])
			draw_polyline(ferme, contour, 1.5, true)


## Pastille en pilule : texte, forme facultative à gauche, fond (blanc par défaut). h 24, contour encre.
static func etiquette(t: String, forme := "", couleur_forme := UiTokens.ENCRE, fond := UiTokens.PAPIER, taille := 12) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = fond
	sb.border_color = UiTokens.ENCRE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.anti_aliasing = true
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	if forme != "":
		h.add_child(Forme.new(forme, couleur_forme, 10.0))
	h.add_child(texte(t, taille, 700))
	return p


## Pastille du mode d'une partie : triangle orange « Terrain aménageable » (classique), rond vert « Réserve naturelle ».
static func pastille_mode(mode: String, court := false) -> PanelContainer:
	if mode == "nature":
		return etiquette("Réserve naturelle" if court else "Terrain tel quel", "rond", UiTokens.POSITIF, UiTokens.VERT_CLAIR)
	return etiquette("Aménagements" if court else "Terrain aménageable", "triangle", UiTokens.ORANGE, UiTokens.ORANGE_CLAIR)


## Chapitre de sommaire : numéro romain en mono, titre condensé, filet jusqu'au bord. h 26.
static func chapitre(num: String, titre: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.custom_minimum_size.y = 26
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(texte(num, 11, 600, UiTokens.TEXTE_2, "mono"))
	h.add_child(texte(titre.to_upper(), 12, 800, UiTokens.TEXTE_2, "titre"))
	var filet := Control.new()
	filet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filet.draw.connect(func(): filet.draw_line(Vector2(0, filet.size.y / 2.0), Vector2(filet.size.x, filet.size.y / 2.0), UiTokens.FILET, 1.0))
	h.add_child(filet)
	return h


## Tampon de BD (CONFIDENTIEL, PÉRIODE D'ESSAI…) : contour, légèrement tourné.
static func tampon(t: String, couleur := UiTokens.NEGATIF, taille := 13, angle := -6.0) -> Control:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1, 1, 1, 0.85)
	st.border_color = couleur
	st.set_border_width_all(2)
	st.set_corner_radius_all(4)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 1
	st.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(texte(t, taille, 800, couleur, "titre"))
	# Un conteneur remet la rotation de ses enfants à zéro : le tampon tourne dans une enveloppe à sa taille.
	var env := Control.new()
	env.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	env.add_child(p)
	var caler := func():
		p.size = p.get_combined_minimum_size()
		env.custom_minimum_size = p.size
		p.pivot_offset = p.size / 2.0
	p.minimum_size_changed.connect(caler)
	p.ready.connect(caler)
	p.rotation = deg_to_rad(angle)
	return env


## Ligne « indisponible » : cadre en tirets sur fond clair, texte secondaire (ex. « Sans objet en gestion libre »).
static func ligne_tirets(t: String, h := 38.0) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiTokens.FOND_FENETRE
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16
	sb.content_margin_right = 12
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.y = h
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := texte(t, 14, 600, UiTokens.TEXTE_2)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	var c := CadreTirets.new()
	c.rayon = 6
	p.add_child(c)
	return p


## Segments (adversaires, difficulté) : h 38, l'actif en encre. rappel(k) à chaque choix.
static func segments(options: Array, actif: int, rappel: Callable, h := 38.0) -> HBoxContainer:
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", -2)
	var groupe := ButtonGroup.new()
	for k in options.size():
		var b := bouton(str(options[k]), "Onglet")
		b.toggle_mode = true
		b.button_group = groupe
		b.button_pressed = k == actif
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = h
		b.add_theme_font_override("font", UiTokens.police_corps(700))
		var idx: int = k
		b.pressed.connect(func(): rappel.call(idx))
		seg.add_child(b)
	return seg


## Vignette d'une carte de jeu (graine), peinte case par case et gardée en cache (mémoire et user://cartes/).
## Générer une carte coûte ~0,5 s : seule la première vignette d'une graine prend ce temps.
static var _vignettes := {}
const DOSSIER_VIGNETTES := "user://cartes/"
const VIGNETTE_VERSION := 1

static func texture_carte(donnees: Dictionary, graine: int, mode := "course") -> Texture2D:
	var cle := "%d_%s_v%d" % [graine, "nature" if mode == "nature" else "course", VIGNETTE_VERSION]
	if _vignettes.has(cle):
		return _vignettes[cle]
	var chemin := DOSSIER_VIGNETTES + cle + ".png"
	var img: Image = null
	if FileAccess.file_exists(chemin):
		img = Image.load_from_file(chemin)
	if img == null:
		var d := ModesPartie.appliquer(donnees, "nature") if mode == "nature" else donnees
		img = peindre_carte(MapGenerator.generate(d["buildings"], graine))
		DirAccess.make_dir_recursive_absolute(DOSSIER_VIGNETTES)
		img.save_png(chemin)
	_vignettes[cle] = ImageTexture.create_from_image(img)
	return _vignettes[cle]


## Vignette cadrée : contour 2 encre, rayon 6, image carrée.
static func vignette_carte(tex: Texture2D, taille: float) -> PanelContainer:
	var cadre := PanelContainer.new()
	var sc := StyleBoxFlat.new()
	sc.border_color = UiTokens.ENCRE
	sc.bg_color = UiTokens.ENCRE
	sc.set_border_width_all(2)
	sc.set_corner_radius_all(6)
	sc.set_content_margin_all(2)
	sc.anti_aliasing = true
	cadre.add_theme_stylebox_override("panel", sc)
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cadre.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cadre.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var r := TextureRect.new()
	r.name = "Image"
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.custom_minimum_size = Vector2(taille - 4, taille - 4)
	r.texture = tex
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cadre.add_child(r)
	return cadre


const PX_CARTE := 8
const TERRAIN_CARTE := {
	GameMap.PRAIRIE: Color("62AE34"), GameMap.FORET: Color("2E7A2C"), GameMap.EAU: Color("2B86D2"),
	GameMap.ROCHE: Color("A8A296"), GameMap.SABLE: Color("F2D684"), GameMap.MONTAGNE: Color("8E7E6C"),
	GameMap.MINE_OR: Color("C9A13A"),
}

## Image d'une carte, 8 px par case (aperçu du menu et vignettes des défis).
static func peindre_carte(m: GameMap) -> Image:
	var PX := PX_CARTE
	var img := Image.create_empty(m.w * PX, m.h * PX, false, Image.FORMAT_RGBA8)
	for y in m.h:
		for x in m.w:
			var o := Vector2i(x * PX, y * PX)
			var t := m.get_t(x, y)
			var base: Color = TERRAIN_CARTE.get(t, TERRAIN_CARTE[GameMap.PRAIRIE])
			if t == GameMap.PRAIRIE and (x * 7 + y * 13) % 5 == 0:
				base = Color("74BE40")
			img.fill_rect(Rect2i(o, Vector2i(PX, PX)), base)
			match t:
				GameMap.FORET:
					img.fill_rect(Rect2i(o + Vector2i(0, 1), Vector2i(4, 4)), Color("1F5E22"))
					img.fill_rect(Rect2i(o + Vector2i(4, 3), Vector2i(4, 4)), Color("1F5E22"))
					img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(2, 2)), Color("6ABA48"))
					img.fill_rect(Rect2i(o + Vector2i(5, 3), Vector2i(2, 2)), Color("6ABA48"))
				GameMap.ROCHE:
					img.fill_rect(Rect2i(o + Vector2i(1, 2), Vector2i(3, 2)), Color("8E8A80"))
					img.fill_rect(Rect2i(o + Vector2i(3, 1), Vector2i(2, 1)), Color("D6D0C2"))
				GameMap.MONTAGNE:
					for r in 6:
						img.fill_rect(Rect2i(o + Vector2i(3 - r / 2, 1 + r), Vector2i(2 + r, 1)), Color("6E604F"))
					img.fill_rect(Rect2i(o + Vector2i(3, 1), Vector2i(2, 1)), Color("F4F4F0"))
				GameMap.EAU:
					var bord := false
					for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
						var q: Vector2i = Vector2i(x, y) + d
						if m.in_bounds(q.x, q.y) and m.get_t(q.x, q.y) != GameMap.EAU:
							bord = true
					if bord:
						img.fill_rect(Rect2i(o, Vector2i(PX, PX)), Color("3AB8D8"))
						img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(PX - 2, PX - 2)), Color("2B9AD2"))
					elif (x + 2 * y) % 5 == 0:
						img.fill_rect(Rect2i(o + Vector2i(1, 3), Vector2i(3, 1)), Color("6CC0F0"))
				GameMap.SABLE:
					if (x + y) % 2 == 0:
						img.fill_rect(Rect2i(o + Vector2i(2, 2), Vector2i(1, 1)), Color("D8B860"))
				GameMap.MINE_OR:
					img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(4, 4)), Color("6A5A48"))
					img.fill_rect(Rect2i(o + Vector2i(2, 2), Vector2i(2, 2)), Color("FFE04A"))
			if m.road.size() > 0 and m.road[m.idx(x, y)] != 0:
				img.fill_rect(Rect2i(o + Vector2i(1, 1), Vector2i(PX - 2, PX - 2)), Color("D6A866"))
	var c := m.camp
	if c.size != Vector2i.ZERO:
		img.fill_rect(Rect2i(c.position * PX, c.size * PX), Color("D2A868"))
		img.fill_rect(Rect2i(c.position * PX + Vector2i(2, 2), c.size * PX - Vector2i(4, 4)), Color("E2BC7E"))
	return img


## Compte à rebours du défi de la semaine : {"secondes", "texte" (« 3 j 03 h 14 »), "court" (« 3 j 3 h »),
## "fin" (« dimanche 23 h 59 »)}. La semaine finit lundi 0 h en temps universel (Defis.numero_semaine) ; la fin est
## écrite en heure locale.
static func rebours_semaine(n := -1) -> Dictionary:
	if n < 0:
		n = Defis.numero_semaine()
	var fin := ((n + 1) * 7 - 3) * 86400
	var reste := maxi(0, fin - int(Time.get_unix_time_from_system()))
	var j := reste / 86400
	var h := (reste % 86400) / 3600
	var mn := (reste % 3600) / 60
	var locale := Time.get_datetime_dict_from_unix_time(fin + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return {"secondes": reste, "texte": "%d j %02d h %02d" % [j, h, mn], "court": ("%d j %d h" % [j, h]) if j > 0 else ("%d h %02d" % [h, mn]),
		"fin": "%s %d h %02d" % [Defis.JOURS_SEMAINE[(int(locale["weekday"]) + 6) % 7], int(locale["hour"]), int(locale["minute"])]}


## Date du lundi d'un défi de la semaine, « 9/11 ».
static func date_semaine(n := -1) -> String:
	if n < 0:
		n = Defis.numero_semaine()
	var lundi := Time.get_datetime_dict_from_unix_time((n * 7 - 3) * 86400)
	return "%d/%d" % [lundi["day"], lundi["month"]]


## Rang écrit « 14e », « 1er ».
static func rang_texte(r: int) -> String:
	return "%d%s" % [r, "er" if r == 1 else "e"]
