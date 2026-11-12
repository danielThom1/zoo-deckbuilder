class_name FenetreDefis
extends Control
## Fenêtre des défis, ouverte du menu : les quatre défis fixes et celui de la semaine, avec le meilleur score du joueur.

signal jouer(id: String)


func _ready() -> void:
	Statistiques.charger()
	theme = UiTokens.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var D := Defis.donnees()
	var f := Composants.fenetre(Vector2(760, 0), "La même partie pour tous", "Défis", queue_free)
	add_child(f["racine"])
	var v: VBoxContainer = f["corps"]
	var intro := Composants.label("%d jours, seul contre les 3 meilleures IA. Même carte, même draft, mêmes collaborateurs, cartes et espèces au marché, dans le même ordre, quoi que vous fassiez. Score : votre réputation au soir du jour %d." % [int(D["jours"]), int(D["jours"])])
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x = 720
	intro.add_theme_font_size_override("font_size", 14)
	v.add_child(intro)
	for d in Defis.liste():
		v.add_child(_ligne(d))
	var note := Composants.label("Classement en ligne à venir : pour l'instant, seul votre meilleur score est gardé, sur cette machine.")
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	v.add_child(note)


func _ligne(d: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.SELECTION if d.has("semaine") else UiTokens.PAPIER, 10, 2, 10, false))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 0)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var nom := Composants.label(str(d["nom"]))
	nom.add_theme_font_override("font", UiTokens.police_titre())
	nom.add_theme_font_size_override("font_size", 22)
	t.add_child(nom)
	var s: Dictionary = Statistiques.donnees["defis"].get(d["id"], {})
	var sous := Composants.label("%s · carte n° %d%s" % [Defis.libelle_mode(d["mode"]), int(d["graine"]),
		" · jusqu'à dimanche soir" if d.has("semaine") else ""])
	sous.add_theme_font_size_override("font_size", 13)
	sous.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	t.add_child(sous)
	var score := Composants.label("Meilleur score : %d (%d partie%s)" % [roundi(float(s["meilleur"])), int(s["parties"]), "s" if int(s["parties"]) > 1 else ""] if not s.is_empty() else "Pas encore joué")
	score.add_theme_font_size_override("font_size", 15)
	score.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(score)
	var b := Composants.bouton("Jouer", "BoutonFort")
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): jouer.emit(str(d["id"])))
	h.add_child(b)
	return p
