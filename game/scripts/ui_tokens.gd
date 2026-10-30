class_name UiTokens
extends RefCounted
## Direction artistique « Émeraude » (HANDOFF.md) : jetons de couleur, styles de panneaux et thème Godot.
## Les icônes et polices de la maquette ne sont pas encore intégrées : formes dessinées et police par défaut.

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
const VOILE_NUIT := Color(0.024, 0.055, 0.133, 0.78)

const JOUEURS: Array[Color] = [Color("18A88A"), Color("E8A020"), Color("3A6AE0"), Color("E04A8A")]

# Catégories d'ouvriers : couleur + forme (jamais la couleur seule)
const CATEGORIES := {
	"peu_qualifie": {"couleur": Color("E39A4A"), "portrait": Color("F3D9B8"), "forme": "›", "court": "PEU QUAL.", "long": "Peu qualifié"},
	"qualifie": {"couleur": Color("2FA7A0"), "portrait": Color("BFE6DF"), "forme": "»", "court": "QUALIFIÉ", "long": "Qualifié"},
	"cadre": {"couleur": Color("9B6BD6"), "portrait": Color("DCCDF2"), "forme": "★", "court": "CADRE", "long": "Cadre"},
}

const RESSOURCES := {
	"argent": {"couleur": Color("E8B23A"), "nom": "Argent", "glyphe": "€"},
	"bois": {"couleur": Color("B8743A"), "nom": "Bois", "glyphe": "B"},
	"pierre": {"couleur": Color("8C9AA8"), "nom": "Pierre", "glyphe": "P"},
	"or": {"couleur": Color("F2C230"), "nom": "Or", "glyphe": "Or"},
	"influence": {"couleur": Color("D85AA0"), "nom": "Influence (privée)", "glyphe": "I"},
	"logement": {"couleur": Color("3FA45A"), "nom": "Logement", "glyphe": "L"},
	"reputation": {"couleur": Color("8A5AD8"), "nom": "Réputation", "glyphe": "R"},
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
	t.set_color("font_color", "Label", TEXTE)
	t.set_color("default_color", "RichTextLabel", TEXTE)
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
	# Bouton principal doré
	t.add_type_variation("BoutonPrincipal", "Button")
	t.set_stylebox("normal", "BoutonPrincipal", _button(Color("E8B468"), OR_SOMBRE))
	t.set_stylebox("hover", "BoutonPrincipal", _button(BOUTON_HAUT, OR_SOMBRE))
	t.set_stylebox("pressed", "BoutonPrincipal", _button(BOUTON_BAS, OR_SOMBRE))
	t.set_stylebox("disabled", "BoutonPrincipal", _button(Color("6A5A3E"), Color(OR_SOMBRE, 0.5)))
	t.set_color("font_color", "BoutonPrincipal", BOUTON_TEXTE)
	t.set_color("font_hover_color", "BoutonPrincipal", BOUTON_TEXTE)
	t.set_color("font_disabled_color", "BoutonPrincipal", Color(BOUTON_TEXTE, 0.5))
	# Petit bouton rond (ordres)
	t.add_type_variation("BoutonOrdre", "Button")
	t.set_stylebox("normal", "BoutonOrdre", _button(Color("174F47"), OR, 23))
	t.set_stylebox("hover", "BoutonOrdre", _button(Color("1E6A5E"), SELECTION, 23))
	t.set_stylebox("pressed", "BoutonOrdre", _button(SELECTION, OR, 23))
	t.set_stylebox("disabled", "BoutonOrdre", _button(Color("0B3631"), Color(OR, 0.2), 23))
	return t
