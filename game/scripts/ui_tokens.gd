class_name UiTokens
extends RefCounted
## Direction artistique « Émeraude » (HANDOFF.md) : jetons de couleur, styles de panneaux et thème Godot.
## Icônes SVG (res://ui/icones/, 76 au trait blanc à teinter) et polices (Marcellus SC, Source Sans 3)
## intégrées : voir icone(), police_titre(), police_corps() et build_theme().

const DOSSIER_ICONES := "res://ui/icones/"
const POLICE_TITRE := "res://ui/fonts/MarcellusSC-Regular.ttf"
const POLICE_CORPS := "res://ui/fonts/SourceSans3-VF.ttf"

# Panneaux
const PANNEAU_HAUT := Color("11564E")
const PANNEAU_MILIEU := Color("0D433D")
const PANNEAU_BAS := Color("08302C")
const ENTETE := Color("1C7468")
const ENTETE_BAS := Color("10483F")
const OR := Color("E2AE62")
const OR_SOMBRE := Color("6A4418")
const OR_CLAIR := Color("FFF0B8")
const BOUTON_HAUT := Color("FFD89A")
const BOUTON_BAS := Color("C88A3A")
const BOUTON_TEXTE := Color("1E1406")
const TEXTE := Color("F4FAEE")
const TEXTE_SECONDAIRE := Color("A6D4C8")
const SELECTION := Color("FFD45A")
const QUALITE := Color("3A8AE8")  # cercle bleu « + »
const DEFAUT := Color("E8782A")  # carré orange « − »
const POSITIF := Color("7CF29A")  # delta ▲ (toujours avec la flèche)
const NEGATIF := Color("FFB09A")  # delta ▼
const FOND_ECRAN := Color("0B2A26")
const INACTIF := Color("E8B020")
const PAUSE := Color("7A8A88")
const VOILE_NUIT := Color(0.024, 0.055, 0.133, 0.78)

const JOUEURS: Array[Color] = [Color("18A88A"), Color("E8A020"), Color("3A6AE0"), Color("E04A8A")]

# Catégories d'ouvriers : couleur + forme (jamais la couleur seule) — valeurs de tokens.json
const CATEGORIES := {
	"peu_qualifie": {"couleur": Color("D8642A"), "portrait": Color("F2B85A"), "forme": "›", "icone": "categorie_peu_qualifie", "court": "PEU QUAL.", "long": "Peu qualifié"},
	"qualifie": {"couleur": Color("1E9A8A"), "portrait": Color("7AD8C8"), "forme": "»", "icone": "categorie_qualifie", "court": "QUALIFIÉ", "long": "Qualifié"},
	"cadre": {"couleur": Color("8A4AD0"), "portrait": Color("C8A8F0"), "forme": "★", "icone": "categorie_cadre", "court": "CADRE", "long": "Cadre"},
}

# Ressources : pastille couleur + reflet, icône blanche — valeurs de tokens.json
const RESSOURCES := {
	"argent": {"couleur": Color("D8A010"), "reflet": Color("FFE48A"), "nom": "Argent", "glyphe": "€", "icone": "ressource_argent"},
	"bois": {"couleur": Color("C8601A"), "reflet": Color("FFB070"), "nom": "Bois", "glyphe": "B", "icone": "ressource_bois"},
	"pierre": {"couleur": Color("4A6A98"), "reflet": Color("A8C4E8"), "nom": "Pierre", "glyphe": "P", "icone": "ressource_pierre"},
	"or": {"couleur": Color("E8B000"), "reflet": Color("FFF09A"), "nom": "Or", "glyphe": "Or", "icone": "ressource_or"},
	"influence": {"couleur": Color("C8307A"), "reflet": Color("FF9AC8"), "nom": "Influence (privée)", "glyphe": "I", "icone": "ressource_influence"},
	"logement": {"couleur": Color("2A9A4A"), "reflet": Color("9AF0B0"), "nom": "Logement", "glyphe": "L", "icone": "ressource_logement"},
	"reputation": {"couleur": Color("7A3AC8"), "reflet": Color("D0A8FF"), "nom": "Réputation", "glyphe": "R", "icone": "ressource_reputation"},
}

const BIOMES := {
	"savane": {"couleur": Color("C88A10"), "nom": "Savane", "icone": "biome_savane"},
	"foret": {"couleur": Color("3A7A2A"), "nom": "Forêt", "icone": "biome_foret"},
	"jungle": {"couleur": Color("0E8A6A"), "nom": "Jungle", "icone": "biome_jungle"},
	"aquatique": {"couleur": Color("2E7AD0"), "nom": "Aquatique", "icone": "biome_aquatique"},
	"montagne": {"couleur": Color("7A6AA0"), "nom": "Montagne", "icone": "biome_montagne"},
	"desert": {"couleur": Color("C8602A"), "nom": "Désert", "icone": "biome_desert"},
}

# Tuiles de motif (UI) : couleur + motif, jamais la couleur seule
const TUILES := {
	"prairie": Color("8ACC4A"), "foret": Color("1E6A22"), "eau": Color("1E9AC8"), "roche": Color("B8B2A6"),
	"sable": Color("F2D684"), "montagne": Color("8E7E6C"), "or": Color("A8A296"),
}

# Monde (couleurs de la maquette, vue du dessus)
const TERRAINS := {
	GameMap.PRAIRIE: Color("62AE34"), GameMap.FORET: Color("2E7A2C"), GameMap.EAU: Color("2B86D2"),
	GameMap.ROCHE: Color("A8A296"), GameMap.SABLE: Color("F2D684"), GameMap.MONTAGNE: Color("8E7E6C"),
	GameMap.MINE_OR: Color("C9A13A"),
}
const PRAIRIE_VARIANTE := Color("74BE40")
const CANOPEE := [Color("1F5E22"), Color("2E7A2C"), Color("4A9A38")]
const EAU_BERGE := Color("46E0D8")
const CHEMIN := Color("D6A866")
const ALLEE_ZOO := Color("F4E6C4")
const ENCEINTE := Color("F2EEE2")
const CLOTURE_ENCLOS := Color("8A5A2B")


## Icône SVG au trait blanc (à teinter avec modulate / self_modulate).
static func icone(nom: String) -> Texture2D:
	var chemin := DOSSIER_ICONES + nom + ".svg"
	return load(chemin) if ResourceLoader.exists(chemin) else null


## Police de titre : Marcellus SC (une seule graisse 400, jamais de gras synthétique).
static func police_titre() -> FontFile:
	return load(POLICE_TITRE)


## Source Sans 3 à la graisse voulue (400 corps, 600 demi-gras, 700 gras, 800 très gras / chiffres).
static func police_corps(graisse := 400) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = load(POLICE_CORPS)
	# la clé doit être le tag OpenType entier, pas la chaîne « wght »
	fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): float(graisse)}
	return fv


static func panel(bg := PANNEAU_MILIEU, border := OR, radius := 10, border_w := 2, margin := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	return sb


static func header() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ENTETE
	sb.border_color = OR
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.set_content_margin_all(6)
	sb.content_margin_left = 12
	return sb


static func chip(bg: Color, radius := 6, margin := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.content_margin_left = margin + 2
	sb.content_margin_right = margin + 2
	return sb


static func _button(bg: Color, border: Color, radius := 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	return sb


## Thème appliqué à toute l'interface : texte clair, boutons émeraude à filet doré,
## variation « BoutonPrincipal » dorée pour les actions principales.
static func build_theme() -> Theme:
	var t := Theme.new()
	# Polices : Source Sans 3 pour le corps, Marcellus SC pour les titres (voir §4.2 HANDOFF)
	var corps := police_corps(400)
	var corps_tres_gras := police_corps(800)
	var titre := police_titre()
	t.default_font = corps
	t.default_font_size = 15
	# Titre d'écran (Marcellus, grandes capitales dorées)
	t.set_type_variation("TitreEcran", "Label")
	t.set_font("font", "TitreEcran", titre)
	t.set_font_size("font_size", "TitreEcran", 34)
	t.set_color("font_color", "TitreEcran", OR_CLAIR)
	# Titre / en-tête de panneau
	t.set_type_variation("TitrePanneau", "Label")
	t.set_font("font", "TitrePanneau", titre)
	t.set_font_size("font_size", "TitrePanneau", 16)
	t.set_color("font_color", "TitrePanneau", OR)
	# Nom de carte (Marcellus 13, capitales)
	t.set_type_variation("NomCarte", "Label")
	t.set_font("font", "NomCarte", titre)
	t.set_font_size("font_size", "NomCarte", 13)
	# Compteur / chiffres (Source Sans 3 ExtraBold)
	t.set_type_variation("Compteur", "Label")
	t.set_font("font", "Compteur", corps_tres_gras)
	t.set_font_size("font_size", "Compteur", 18)
	# Texte secondaire
	t.set_type_variation("TexteSecondaire", "Label")
	t.set_color("font_color", "TexteSecondaire", TEXTE_SECONDAIRE)
	t.set_font_size("font_size", "TexteSecondaire", 13)
	t.set_color("font_color", "Label", TEXTE)
	t.set_color("default_color", "RichTextLabel", TEXTE)
	t.set_font("bold_font", "RichTextLabel", police_corps(700))
	t.set_color("font_color", "Button", TEXTE)
	t.set_color("font_hover_color", "Button", OR_CLAIR)
	t.set_color("font_pressed_color", "Button", BOUTON_TEXTE)
	t.set_color("font_disabled_color", "Button", Color(TEXTE_SECONDAIRE, 0.45))
	t.set_stylebox("normal", "Button", _button(Color("174F47"), Color(OR, 0.55)))
	t.set_stylebox("hover", "Button", _button(Color("1E6A5E"), OR))
	t.set_stylebox("pressed", "Button", _button(SELECTION, OR))
	t.set_stylebox("disabled", "Button", _button(Color("0B3631"), Color(OR, 0.18)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PanelContainer", panel())
	t.set_stylebox("panel", "TooltipPanel", panel(PANNEAU_BAS, OR, 6, 1, 8))
	t.set_color("font_color", "TooltipLabel", TEXTE)
	t.set_color("font_color", "LineEdit", TEXTE)
	t.set_stylebox("normal", "LineEdit", _button(PANNEAU_BAS, Color(OR, 0.6)))
	t.set_stylebox("background", "ProgressBar", chip(Color("06231F"), 4, 0))
	t.set_stylebox("fill", "ProgressBar", chip(OR, 4, 0))
	# Panneau émeraude et en-tête (variations de PanelContainer, §4.4)
	t.set_type_variation("PanneauEmeraude", "PanelContainer")
	t.set_stylebox("panel", "PanneauEmeraude", panel(PANNEAU_MILIEU, OR, 10, 2, 12))
	t.set_type_variation("EnteteEmeraude", "PanelContainer")
	t.set_stylebox("panel", "EnteteEmeraude", header())
	# Bouton principal doré, en pilule (tokens.formes.bouton_principal : rayon 22)
	t.set_type_variation("BoutonPrincipal", "Button")
	t.set_stylebox("normal", "BoutonPrincipal", _button(Color("E8B468"), OR_SOMBRE, 22))
	t.set_stylebox("hover", "BoutonPrincipal", _button(BOUTON_HAUT, OR_SOMBRE, 22))
	t.set_stylebox("pressed", "BoutonPrincipal", _button(BOUTON_BAS, OR_SOMBRE, 22))
	t.set_stylebox("disabled", "BoutonPrincipal", _button(Color("6A5A3E"), Color(OR_SOMBRE, 0.5), 22))
	t.set_font("font", "BoutonPrincipal", police_corps(700))
	t.set_color("font_color", "BoutonPrincipal", BOUTON_TEXTE)
	t.set_color("font_hover_color", "BoutonPrincipal", BOUTON_TEXTE)
	t.set_color("font_disabled_color", "BoutonPrincipal", Color(BOUTON_TEXTE, 0.5))
	# Bouton secondaire : fond sombre translucide, contour or (tokens.formes.bouton_secondaire)
	t.set_type_variation("BoutonSecondaire", "Button")
	t.set_stylebox("normal", "BoutonSecondaire", _button(Color(PANNEAU_BAS, 0.85), OR, 22))
	t.set_stylebox("hover", "BoutonSecondaire", _button(Color("1E6A5E"), SELECTION, 22))
	t.set_stylebox("pressed", "BoutonSecondaire", _button(SELECTION, OR, 22))
	t.set_stylebox("disabled", "BoutonSecondaire", _button(Color(PANNEAU_BAS, 0.6), Color(OR, 0.25), 22))
	t.set_font("font", "BoutonSecondaire", police_corps(700))
	t.set_color("font_disabled_color", "BoutonSecondaire", Color(TEXTE_SECONDAIRE, 0.6))
	# Petit bouton rond (ordres)
	t.set_type_variation("BoutonOrdre", "Button")
	t.set_stylebox("normal", "BoutonOrdre", _button(Color("174F47"), OR, 23))
	t.set_stylebox("hover", "BoutonOrdre", _button(Color("1E6A5E"), SELECTION, 23))
	t.set_stylebox("pressed", "BoutonOrdre", _button(SELECTION, OR, 23))
	t.set_stylebox("disabled", "BoutonOrdre", _button(Color("0B3631"), Color(OR, 0.2), 23))
	return t
