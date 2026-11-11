class_name UiTokens
extends RefCounted
## Direction artistique « BD néo ligne claire » (docs/handoff_bd/HANDOFF_BD.md, maquette cible_interface.png) :
## panneaux blancs cernés d'encre marine, ombre portée nette décalée, en-têtes sarcelle, accent jaune,
## Barlow (texte) et Barlow Condensed (titres, capitales). Mêmes noms que la version Émeraude.
## Icônes SVG au trait blanc (res://ui/icones/) : toujours posées sur une pastille de couleur.

const DOSSIER_ICONES := "res://ui/icones/"
const POLICES := "res://assets/bd/polices/"

# Encre et papier
const ENCRE := Color("14202B")
const PAPIER := Color("FFFFFF")
const PAPIER_2 := Color("EEF4F1")
const MARINE := Color("1E2C45")
const SARCELLE := Color("13867F")
const TRAME := Color(1, 1, 1, 0.22)

# Panneaux (noms historiques)
const PANNEAU_HAUT := PAPIER
const PANNEAU_MILIEU := PAPIER
const PANNEAU_BAS := PAPIER_2
const ENTETE := Color("BFE6DF")        # en-tête clair, texte encre
const ENTETE_FORT := SARCELLE          # bandeau sarcelle, texte blanc
const ENTETE_BAS := Color("9FD6CC")
const OR := ENCRE                      # filets, titres : l'encre remplace l'or
const OR_SOMBRE := ENCRE
const OR_CLAIR := MARINE               # texte d'accent sur fond clair
const BOUTON_HAUT := Color("FFD86A")
const BOUTON_BAS := Color("FFC93C")
const BOUTON_TEXTE := ENCRE
const TEXTE := ENCRE
const TEXTE_SECONDAIRE := Color("4A5664")
const TEXTE_CLAIR := PAPIER            # sur bandeau sarcelle ou marine
const SELECTION := Color("FFC93C")
const ORANGE := Color("F07F2A")        # action forte (« Terminer la journée »)
const QUALITE := Color("2F7FD8")  # cercle bleu « + »
const DEFAUT := Color("F07F2A")   # carré orange « − »
const POSITIF := Color("1F7A4A")  # delta ▲ (toujours avec la flèche), lisible sur blanc
const NEGATIF := Color("B5452A")  # delta ▼
const FOND_ECRAN := MARINE
const INACTIF := Color("E8B020")
const PAUSE := Color("7A8A88")
const VOILE_NUIT := Color(0.024, 0.055, 0.133, 0.78)

const JOUEURS: Array[Color] = [Color("13867F"), Color("F0A020"), Color("3A6AE0"), Color("E04A8A")]

# Catégories d'ouvriers : couleur + forme (jamais la couleur seule)
const CATEGORIES := {
	"peu_qualifie": {"couleur": Color("F07F2A"), "portrait": Color("FFD39A"), "forme": "›", "icone": "categorie_peu_qualifie", "court": "PEU QUAL.", "long": "Peu qualifié"},
	"qualifie": {"couleur": Color("13867F"), "portrait": Color("9FE0D2"), "forme": "»", "icone": "categorie_qualifie", "court": "QUALIFIÉ", "long": "Qualifié"},
	"cadre": {"couleur": Color("6B4FC8"), "portrait": Color("D2C2F4"), "forme": "★", "icone": "categorie_cadre", "court": "CADRE", "long": "Cadre"},
}

# Ressources : pastille couleur + reflet, icône blanche ; « sprite » = dessin BD de la barre du haut
const RESSOURCES := {
	"argent": {"couleur": Color("3E9A48"), "reflet": Color("D6F0CC"), "nom": "Argent", "glyphe": "€", "icone": "ressource_argent", "sprite": "icone_billets"},  # billets verts : l'or garde ses pièces jaunes
	"bois": {"couleur": Color("C8601A"), "reflet": Color("FFB070"), "nom": "Bois", "glyphe": "B", "icone": "ressource_bois", "sprite": "icone_bois"},
	"pierre": {"couleur": Color("4A6A98"), "reflet": Color("A8C4E8"), "nom": "Pierre", "glyphe": "P", "icone": "ressource_pierre", "sprite": "icone_pierre"},
	"or": {"couleur": Color("E8B000"), "reflet": Color("FFF09A"), "nom": "Or", "glyphe": "Or", "icone": "ressource_or", "sprite": "icone_or"},
	"influence": {"couleur": Color("C8307A"), "reflet": Color("FF9AC8"), "nom": "Influence (privée)", "glyphe": "I", "icone": "ressource_influence", "sprite": "mairie"},
	"logement": {"couleur": Color("2A9A4A"), "reflet": Color("9AF0B0"), "nom": "Logement", "glyphe": "L", "icone": "ressource_logement", "sprite": "maison"},
	"reputation": {"couleur": Color("7A3AC8"), "reflet": Color("D0A8FF"), "nom": "Réputation", "glyphe": "R", "icone": "ressource_reputation", "sprite": "icone_etoile"},
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
	"prairie": Color("8CC25A"), "foret": Color("3E7A37"), "eau": Color("46A9D6"), "roche": Color("BDB8AA"),
	"sable": Color("E9CE8A"), "montagne": Color("A39C8C"), "or": Color("C9A13A"),
}

# Monde : couleurs de repli (le rendu de la carte est fait par scripts/rendu/carte_bd.gd)
const TERRAINS := {
	GameMap.PRAIRIE: Color("8CC25A"), GameMap.FORET: Color("5E9145"), GameMap.EAU: Color("46A9D6"),
	GameMap.ROCHE: Color("BDB8AA"), GameMap.SABLE: Color("E9CE8A"), GameMap.MONTAGNE: Color("A39C8C"),
	GameMap.MINE_OR: Color("C9A13A"),
}
const PRAIRIE_VARIANTE := Color("9DCB66")
const CANOPEE := [Color("3E7A37"), Color("5A9A45"), Color("8DC266")]
const EAU_BERGE := Color("7CCCE6")
const CHEMIN := Color("E6CB94")
const ALLEE_ZOO := Color("FAF0D8")
const ENCEINTE := Color("E4DED0")
const CLOTURE_ENCLOS := Color("A0703E")

static var _polices := {}

# --- Direction « Le Comité » (05/11/2026) : maquettes docs/handoff_comite/ -----------------
const FOND_FENETRE := Color("F7F8F9")   # fond des grandes fenêtres
const MEMO := Color("F3F1EA")           # répliques d'Hubert, notes
const FILET := Color("D5D9DE")          # séparateurs
const TEXTE_2 := Color("3D4752")        # légendes (contraste 7,9:1)
const ENCRE_DOUX := Color("6B7480")     # éléments indisponibles, pris par un rival
const MARINE_2 := Color("2E4256")       # ligne active du bandeau, ordre du jour
const JAUNE_CLAIR := Color("FFF3C4")    # étape en cours, carte suivie
const ORANGE_CLAIR := Color("FFE1C6")   # alerte douce, ressource insuffisante
const SARCELLE_FONCE := Color("0E615C") # gain ▲ en texte
const OR_TEXTE := Color("8A6400")       # chiffre de l'or (jamais l'argent)
const BLEU_QUALITE := Color("2F6FD0")   # cercle = qualité
const GAIN_BANDEAU := Color("7FD6A8")   # ▲ sur fond encre
const PERTE_BANDEAU := Color("FFB27A")  # ▼ sur fond encre
const H_BANDEAU := 34                   # bandeau du haut
const H_DOCK := 96                      # dock du bas


## Icône SVG au trait blanc (à teinter avec modulate / self_modulate).
static func icone(nom: String) -> Texture2D:
	var chemin := DOSSIER_ICONES + nom + ".svg"
	return load(chemin) if ResourceLoader.exists(chemin) else null


static func _fichier(famille: String, graisse: int) -> FontFile:
	var cle := "%s_%d" % [famille, graisse]
	if _polices.has(cle):
		return _polices[cle]
	var base := POLICES + "%s-latin-%d-normal.woff2" % [famille, graisse]
	var ext := POLICES + "%s-latin-ext-%d-normal.woff2" % [famille, graisse]
	var f: FontFile = null
	if ResourceLoader.exists(base):
		f = load(base)
		var replis: Array[Font] = []
		if ResourceLoader.exists(ext):
			replis.append(load(ext))
		replis.append(ThemeDB.fallback_font)
		f.fallbacks = replis
	_polices[cle] = f
	return f


## Titres : Barlow Condensed très gras (à écrire en capitales).
static func police_titre() -> FontFile:
	var f := _fichier("barlow-condensed", 800)
	return f if f else ThemeDB.fallback_font as FontFile


## Texte : Barlow à la graisse la plus proche (500 corps, 600 courant, 700 gras, 800 chiffres).
static func police_corps(graisse := 400) -> FontVariation:
	var g := 500 if graisse <= 550 else (600 if graisse <= 650 else (700 if graisse <= 750 else 800))
	var fv := FontVariation.new()
	var f := _fichier("barlow", g)
	fv.base_font = f if f else ThemeDB.fallback_font
	return fv


## Chiffres, heures, coûts : IBM Plex Mono (500 ou 600).
static func police_mono(graisse := 600) -> FontFile:
	var f := _fichier("ibm-plex-mono", 500 if graisse < 550 else 600)
	return f if f else ThemeDB.fallback_font as FontFile


## Répliques d'Hubert : Barlow 600 italique.
static func police_italique() -> FontFile:
	var cle := "barlow_italique"
	if not _polices.has(cle):
		var base := POLICES + "barlow-latin-600-italic.woff2"
		var f: FontFile = load(base) if ResourceLoader.exists(base) else null
		if f:
			var ext := POLICES + "barlow-latin-ext-600-italic.woff2"
			var replis: Array[Font] = []
			if ResourceLoader.exists(ext):
				replis.append(load(ext))
			replis.append(ThemeDB.fallback_font)
			f.fallbacks = replis
		_polices[cle] = f
	return _polices[cle] if _polices[cle] else ThemeDB.fallback_font as FontFile


## Panneau « Comité » : papier, contour 2 px, rayon 10, ombre pleine 0 / 4 (StyleBoxFlat seul, sans flou).
static func panneau(bg := PAPIER, radius := 10, border_w := 2, margin := 10, ombre := true, border := ENCRE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	if ombre:
		sb.shadow_color = ENCRE
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(0, 4)
	return sb


## En-tête de panneau « Comité » (sarcelle par défaut, orange = alerte, encre = sélection), texte blanc.
static func entete(couleur := SARCELLE, radius := 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = couleur
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


## Panneau BD : fond clair, cerne d'encre, ombre pleine décalée.
static func panel(bg := PANNEAU_MILIEU, border := OR, radius := 12, border_w := 3, margin := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	if border_w >= 2 and bg.a > 0.5:
		sb.shadow_color = ENCRE
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(0, 4)  # Comité : ombre pleine verticale
	return sb


## En-tête de panneau clair (texte encre).
static func header() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ENTETE
	sb.border_color = ENCRE
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.set_content_margin_all(6)
	sb.content_margin_left = 12
	return sb


## Bandeau sarcelle (texte blanc) : en-têtes des grands panneaux.
static func bandeau(couleur := ENTETE_FORT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = couleur
	sb.border_color = ENCRE
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.content_margin_left = 14
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func chip(bg: Color, radius := 6, margin := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = ENCRE
	sb.set_border_width_all(2 if bg.a > 0.6 and bg != PAPIER_2 else 0)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.content_margin_left = margin + 2
	sb.content_margin_right = margin + 2
	sb.anti_aliasing = true
	return sb


static func _button(bg: Color, border: Color, radius := 9, ombre := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(5)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.anti_aliasing = true
	if ombre:
		sb.shadow_color = ENCRE
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(0, 3)
	return sb


## Thème de toute l'interface.
static func build_theme() -> Theme:
	var t := Theme.new()
	var corps := police_corps(500)
	var gras := police_corps(700)
	var tres_gras := police_corps(800)
	var titre := police_titre()
	t.default_font = corps
	t.default_font_size = 15
	# Titre d'écran / de panneau / nom de carte : Barlow Condensed, encre
	t.set_type_variation("TitreEcran", "Label")
	t.set_font("font", "TitreEcran", titre)
	t.set_font_size("font_size", "TitreEcran", 34)
	t.set_color("font_color", "TitreEcran", TEXTE)
	t.set_type_variation("TitrePanneau", "Label")
	t.set_font("font", "TitrePanneau", titre)
	t.set_font_size("font_size", "TitrePanneau", 19)
	t.set_color("font_color", "TitrePanneau", TEXTE)
	t.set_type_variation("TitreBandeau", "Label")   # sur bandeau sarcelle
	t.set_font("font", "TitreBandeau", titre)
	t.set_font_size("font_size", "TitreBandeau", 21)
	t.set_color("font_color", "TitreBandeau", TEXTE_CLAIR)
	t.set_type_variation("NomCarte", "Label")
	t.set_font("font", "NomCarte", titre)
	t.set_font_size("font_size", "NomCarte", 14)
	t.set_type_variation("Compteur", "Label")
	t.set_font("font", "Compteur", tres_gras)
	t.set_font_size("font_size", "Compteur", 18)
	t.set_type_variation("TexteSecondaire", "Label")
	t.set_color("font_color", "TexteSecondaire", TEXTE_SECONDAIRE)
	t.set_font_size("font_size", "TexteSecondaire", 13)
	t.set_color("font_color", "Label", TEXTE)
	t.set_color("default_color", "RichTextLabel", TEXTE)
	t.set_font("bold_font", "RichTextLabel", gras)
	t.set_font("normal_font", "RichTextLabel", corps)
	# Boutons : blancs cernés d'encre
	t.set_font("font", "Button", gras)
	t.set_color("font_color", "Button", TEXTE)
	t.set_color("font_hover_color", "Button", TEXTE)
	t.set_color("font_focus_color", "Button", TEXTE)
	t.set_color("font_pressed_color", "Button", BOUTON_TEXTE)
	t.set_color("font_hover_pressed_color", "Button", BOUTON_TEXTE)
	t.set_color("font_disabled_color", "Button", Color(TEXTE_SECONDAIRE, 0.55))
	t.set_stylebox("normal", "Button", _button(PAPIER, ENCRE))
	t.set_stylebox("hover", "Button", _button(Color("FFF4D6"), ENCRE))
	t.set_stylebox("pressed", "Button", _button(SELECTION, ENCRE))
	t.set_stylebox("hover_pressed", "Button", _button(BOUTON_HAUT, ENCRE))
	t.set_stylebox("disabled", "Button", _button(PAPIER_2, Color(ENCRE, 0.25)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PanelContainer", panel())
	# Infobulle Comité : encre, texte blanc, sans ombre
	var tip := panneau(ENCRE, 8, 0, 10, false)
	tip.content_margin_left = 12
	tip.content_margin_right = 12
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", PAPIER)
	t.set_font("font", "TooltipLabel", corps)
	t.set_color("font_color", "LineEdit", TEXTE)
	t.set_stylebox("normal", "LineEdit", _button(PAPIER, ENCRE, 7))
	t.set_stylebox("focus", "LineEdit", _button(PAPIER, SELECTION, 7))
	t.set_stylebox("background", "ProgressBar", chip(PAPIER_2, 5, 0))
	t.set_stylebox("fill", "ProgressBar", chip(SELECTION, 5, 0))
	t.set_stylebox("scroll", "VScrollBar", chip(Color(0, 0, 0, 0), 4, 0))
	t.set_stylebox("grabber", "VScrollBar", chip(Color("B9C4C2"), 4, 2))
	t.set_stylebox("grabber_highlight", "VScrollBar", chip(Color("8E9C9A"), 4, 2))
	t.set_stylebox("grabber_pressed", "VScrollBar", chip(Color("8E9C9A"), 4, 2))
	t.set_stylebox("scroll", "HScrollBar", chip(Color(0, 0, 0, 0), 4, 0))
	t.set_stylebox("grabber", "HScrollBar", chip(Color("B9C4C2"), 4, 2))
	# Panneau et en-tête (variations historiques)
	t.set_type_variation("PanneauEmeraude", "PanelContainer")
	t.set_stylebox("panel", "PanneauEmeraude", panel(PANNEAU_MILIEU, ENCRE, 12, 3, 12))
	t.set_type_variation("EnteteEmeraude", "PanelContainer")
	t.set_stylebox("panel", "EnteteEmeraude", header())
	# Bouton principal jaune, ombre BD
	t.set_type_variation("BoutonPrincipal", "Button")
	t.set_stylebox("normal", "BoutonPrincipal", _button(BOUTON_BAS, ENCRE, 10, true))
	t.set_stylebox("hover", "BoutonPrincipal", _button(BOUTON_HAUT, ENCRE, 10, true))
	t.set_stylebox("pressed", "BoutonPrincipal", _button(Color("F0A020"), ENCRE, 10))
	t.set_stylebox("disabled", "BoutonPrincipal", _button(PAPIER_2, Color(ENCRE, 0.3), 10))
	t.set_font("font", "BoutonPrincipal", tres_gras)
	t.set_color("font_color", "BoutonPrincipal", BOUTON_TEXTE)
	t.set_color("font_hover_color", "BoutonPrincipal", BOUTON_TEXTE)
	t.set_color("font_pressed_color", "BoutonPrincipal", BOUTON_TEXTE)
	t.set_color("font_disabled_color", "BoutonPrincipal", Color(BOUTON_TEXTE, 0.45))
	# Bouton secondaire : blanc cerné
	t.set_type_variation("BoutonSecondaire", "Button")
	t.set_stylebox("normal", "BoutonSecondaire", _button(PAPIER, ENCRE, 9))
	t.set_stylebox("hover", "BoutonSecondaire", _button(Color("FFF4D6"), ENCRE, 9))
	t.set_stylebox("pressed", "BoutonSecondaire", _button(SELECTION, ENCRE, 9))
	t.set_stylebox("disabled", "BoutonSecondaire", _button(PAPIER_2, Color(ENCRE, 0.25), 9))
	t.set_font("font", "BoutonSecondaire", gras)
	t.set_color("font_color", "BoutonSecondaire", TEXTE)
	t.set_color("font_hover_color", "BoutonSecondaire", TEXTE)
	t.set_color("font_disabled_color", "BoutonSecondaire", Color(TEXTE_SECONDAIRE, 0.6))
	# Bouton fort orange (Terminer la journée)
	t.set_type_variation("BoutonFort", "Button")
	t.set_stylebox("normal", "BoutonFort", _button(ORANGE, ENCRE, 12, true))
	t.set_stylebox("hover", "BoutonFort", _button(Color("F79A50"), ENCRE, 12, true))
	t.set_stylebox("pressed", "BoutonFort", _button(Color("D86A1A"), ENCRE, 12))
	t.set_stylebox("disabled", "BoutonFort", _button(PAPIER_2, Color(ENCRE, 0.3), 12))
	t.set_font("font", "BoutonFort", titre)
	t.set_font_size("font_size", "BoutonFort", 21)
	t.set_color("font_color", "BoutonFort", ENCRE)
	t.set_color("font_hover_color", "BoutonFort", ENCRE)
	# Petit bouton d'ordre (icône blanche sur fond sarcelle)
	t.set_type_variation("BoutonOrdre", "Button")
	t.set_stylebox("normal", "BoutonOrdre", _button(SARCELLE, ENCRE, 10))
	t.set_stylebox("hover", "BoutonOrdre", _button(Color("1A9E96"), ENCRE, 10, true))
	t.set_stylebox("pressed", "BoutonOrdre", _button(SELECTION, ENCRE, 10))
	t.set_stylebox("disabled", "BoutonOrdre", _button(Color("9FB8B4"), Color(ENCRE, 0.35), 10))
	# Onglet : enfoncé = encre, texte blanc
	t.set_type_variation("Onglet", "Button")
	t.set_stylebox("normal", "Onglet", _button(PAPIER, ENCRE, 9))
	t.set_stylebox("hover", "Onglet", _button(Color("FFF4D6"), ENCRE, 9))
	t.set_stylebox("pressed", "Onglet", _button(ENCRE, ENCRE, 9))
	t.set_stylebox("hover_pressed", "Onglet", _button(ENCRE, ENCRE, 9))
	t.set_color("font_pressed_color", "Onglet", TEXTE_CLAIR)
	t.set_color("font_hover_pressed_color", "Onglet", TEXTE_CLAIR)
	# --- Comité ---
	# Boutons du bandeau du haut (fond encre) : texte blanc, actif = blanc plein, texte encre
	t.set_type_variation("BoutonBandeau", "Button")
	var bb_n := StyleBoxFlat.new()
	bb_n.bg_color = Color(0, 0, 0, 0)
	bb_n.set_content_margin_all(4)
	var bb_h := bb_n.duplicate()
	bb_h.bg_color = MARINE_2
	var bb_p := bb_n.duplicate()
	bb_p.bg_color = PAPIER
	for k in [["normal", bb_n], ["hover", bb_h], ["pressed", bb_p], ["hover_pressed", bb_p], ["disabled", bb_n]]:
		t.set_stylebox(k[0], "BoutonBandeau", k[1])
	t.set_font("font", "BoutonBandeau", tres_gras)
	t.set_font_size("font_size", "BoutonBandeau", 13)
	for k in ["font_color", "font_hover_color", "font_focus_color"]:
		t.set_color(k, "BoutonBandeau", PAPIER)
	t.set_color("font_pressed_color", "BoutonBandeau", ENCRE)
	t.set_color("font_hover_pressed_color", "BoutonBandeau", ENCRE)
	t.set_color("font_disabled_color", "BoutonBandeau", Color(PAPIER, 0.4))
	# Bouton d'outil 48 × 48 (colonne de droite) : blanc, actif = sarcelle + anneau jaune
	t.set_type_variation("BoutonOutil", "Button")
	t.set_stylebox("normal", "BoutonOutil", panneau(PAPIER, 10, 2, 6, false))
	t.set_stylebox("hover", "BoutonOutil", panneau(Color("FFF4D6"), 10, 2, 6, false))
	var outil_on := panneau(SARCELLE, 10, 2, 6, false)
	outil_on.expand_margin_left = 0
	t.set_stylebox("pressed", "BoutonOutil", outil_on)
	t.set_stylebox("hover_pressed", "BoutonOutil", outil_on)
	t.set_font("font", "BoutonOutil", tres_gras)
	t.set_font_size("font_size", "BoutonOutil", 11)
	t.set_color("font_pressed_color", "BoutonOutil", PAPIER)
	t.set_color("font_hover_pressed_color", "BoutonOutil", PAPIER)
	t.set_color("icon_normal_color", "BoutonOutil", ENCRE)
	t.set_color("icon_hover_color", "BoutonOutil", ENCRE)
	t.set_color("icon_pressed_color", "BoutonOutil", PAPIER)
	t.set_color("icon_hover_pressed_color", "BoutonOutil", PAPIER)
	# « Lever la séance » : orange, Barlow Condensed 18, ombre pleine
	t.set_type_variation("BoutonSeance", "Button")
	t.set_stylebox("normal", "BoutonSeance", _button(ORANGE, ENCRE, 10, true))
	t.set_stylebox("hover", "BoutonSeance", _button(Color("F79A50"), ENCRE, 10, true))
	t.set_stylebox("pressed", "BoutonSeance", _button(Color("D86A1A"), ENCRE, 10))
	t.set_stylebox("disabled", "BoutonSeance", _button(FOND_FENETRE, Color(ENCRE, 0.3), 10))
	t.set_font("font", "BoutonSeance", titre)
	t.set_font_size("font_size", "BoutonSeance", 18)
	t.set_color("font_color", "BoutonSeance", ENCRE)
	t.set_color("font_hover_color", "BoutonSeance", ENCRE)
	# Chiffres en IBM Plex Mono
	t.set_type_variation("Chiffre", "Label")
	t.set_font("font", "Chiffre", police_mono(600))
	t.set_font_size("font_size", "Chiffre", 20)
	t.set_color("font_color", "Chiffre", ENCRE)
	# En-tête de panneau Comité (texte blanc condensé 14, interlettré)
	t.set_type_variation("EnteteComite", "Label")
	t.set_font("font", "EnteteComite", titre)
	t.set_font_size("font_size", "EnteteComite", 15)
	t.set_color("font_color", "EnteteComite", PAPIER)
	t.set_constant("outline_size", "EnteteComite", 0)
	return t
