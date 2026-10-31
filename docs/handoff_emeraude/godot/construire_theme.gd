@tool
extends EditorScript
# Construit res://ui/theme_emeraude.tres à partir des jetons.
# Lancer depuis l'éditeur de script : Fichier > Exécuter (Ctrl+Maj+X).
# Point de départ non testé dans le projet. Les dégradés de la maquette sont approchés par des aplats ;
# pour les retrouver, remplacer les StyleBoxFlat par des StyleBoxTexture (GradientTexture2D ou 9-patch).

const POLICE_TITRE := "res://ui/fonts/MarcellusSC-Regular.ttf"
const POLICE_TEXTE := "res://ui/fonts/SourceSans3-Regular.ttf"
const POLICE_TEXTE_GRAS := "res://ui/fonts/SourceSans3-Bold.ttf"
const SORTIE := "res://ui/theme_emeraude.tres"


func _run() -> void:
	var t := Theme.new()

	var texte: Font = load(POLICE_TEXTE)
	var texte_gras: Font = load(POLICE_TEXTE_GRAS)
	var titre: Font = load(POLICE_TITRE)
	t.default_font = texte
	t.default_font_size = 15
	t.set_color("font_color", "Label", UiTokens.TEXTE)

	# Panneau à bord doré
	t.add_type("PanneauEmeraude")
	t.set_type_variation("PanneauEmeraude", "PanelContainer")
	t.set_stylebox("panel", "PanneauEmeraude", _boite(UiTokens.PANNEAU_MILIEU, UiTokens.OR, 2, 10, 12, true))

	# En-tête de panneau
	t.add_type("EnteteEmeraude")
	t.set_type_variation("EnteteEmeraude", "PanelContainer")
	var entete := _boite(UiTokens.ENTETE_HAUT, UiTokens.OR, 0, 0, 0, false)
	entete.border_width_bottom = 1
	entete.corner_radius_top_left = 8
	entete.corner_radius_top_right = 8
	entete.content_margin_left = 12
	entete.content_margin_right = 12
	entete.content_margin_top = 9
	entete.content_margin_bottom = 9
	t.set_stylebox("panel", "EnteteEmeraude", entete)

	# Titre de panneau
	t.add_type("TitrePanneau")
	t.set_type_variation("TitrePanneau", "Label")
	t.set_font("font", "TitrePanneau", titre)
	t.set_font_size("font_size", "TitrePanneau", 17)
	t.set_color("font_color", "TitrePanneau", UiTokens.TEXTE)

	# Texte secondaire
	t.add_type("TexteSecondaire")
	t.set_type_variation("TexteSecondaire", "Label")
	t.set_font_size("font_size", "TexteSecondaire", 13)
	t.set_color("font_color", "TexteSecondaire", UiTokens.TEXTE_SECONDAIRE)

	# Bouton principal (pilule dorée)
	t.add_type("BoutonPrincipal")
	t.set_type_variation("BoutonPrincipal", "Button")
	t.set_stylebox("normal", "BoutonPrincipal", _boite(UiTokens.BOUTON_BAS.lerp(UiTokens.BOUTON_HAUT, 0.5), UiTokens.BOUTON_BAS, 0, 22, 18, false))
	t.set_stylebox("hover", "BoutonPrincipal", _boite(UiTokens.BOUTON_HAUT, UiTokens.BOUTON_BAS, 0, 22, 18, false))
	t.set_stylebox("pressed", "BoutonPrincipal", _boite(UiTokens.BOUTON_BAS, UiTokens.BOUTON_BAS, 0, 22, 18, false))
	t.set_stylebox("disabled", "BoutonPrincipal", _boite(Color(1, 1, 1, 0.08), UiTokens.DEFAUT, 2, 22, 18, false))
	t.set_stylebox("focus", "BoutonPrincipal", _anneau_focus(22))
	t.set_font("font", "BoutonPrincipal", texte_gras)
	t.set_font_size("font_size", "BoutonPrincipal", 15)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(etat, "BoutonPrincipal", UiTokens.BOUTON_TEXTE)
	t.set_color("font_disabled_color", "BoutonPrincipal", UiTokens.NEGATIF)

	# Bouton secondaire (contour or)
	t.add_type("BoutonSecondaire")
	t.set_type_variation("BoutonSecondaire", "Button")
	t.set_stylebox("normal", "BoutonSecondaire", _boite(Color(0.031, 0.188, 0.172, 0.85), UiTokens.OR, 2, 22, 18, false))
	t.set_stylebox("hover", "BoutonSecondaire", _boite(UiTokens.PANNEAU_HAUT, UiTokens.OR_CLAIR, 2, 22, 18, false))
	t.set_stylebox("pressed", "BoutonSecondaire", _boite(UiTokens.PANNEAU_BAS, UiTokens.OR, 2, 22, 18, false))
	t.set_stylebox("focus", "BoutonSecondaire", _anneau_focus(22))
	t.set_font("font", "BoutonSecondaire", texte_gras)
	t.set_color("font_color", "BoutonSecondaire", UiTokens.TEXTE)

	# Bouton rond d'ordre (46 px)
	t.add_type("BoutonOrdre")
	t.set_type_variation("BoutonOrdre", "Button")
	t.set_stylebox("normal", "BoutonOrdre", _boite(Color(1, 1, 1, 0.10), UiTokens.OR, 2, 23, 0, false))
	t.set_stylebox("hover", "BoutonOrdre", _boite(Color(1, 1, 1, 0.18), UiTokens.OR_CLAIR, 2, 23, 0, false))
	t.set_stylebox("pressed", "BoutonOrdre", _boite(UiTokens.BOUTON_HAUT, UiTokens.OR, 2, 23, 0, false))
	t.set_stylebox("focus", "BoutonOrdre", _anneau_focus(23))

	var err := ResourceSaver.save(t, SORTIE)
	print("Thème Émeraude enregistré : ", SORTIE, " (", error_string(err), ")")


func _boite(fond: Color, bord: Color, epaisseur: int, rayon: int, marge: int, ombre: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fond
	s.border_color = bord
	s.set_border_width_all(epaisseur)
	s.set_corner_radius_all(rayon)
	s.set_content_margin_all(marge)
	s.anti_aliasing = true
	if ombre:
		s.shadow_color = Color(0, 0, 0, 0.4)
		s.shadow_size = 12
		s.shadow_offset = Vector2(0, 6)
	return s


func _anneau_focus(rayon: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.border_color = UiTokens.SELECTION
	s.set_border_width_all(2)
	s.set_corner_radius_all(rayon + 3)
	s.expand_margin_left = 3
	s.expand_margin_right = 3
	s.expand_margin_top = 3
	s.expand_margin_bottom = 3
	return s
