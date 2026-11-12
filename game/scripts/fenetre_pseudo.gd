class_name FenetrePseudo
extends Control
## À la première ouverture du jeu : le joueur choisit son pseudo (classements des défis, statistiques).


func _ready() -> void:
	theme = UiTokens.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var f := Composants.fenetre(Vector2(520, 0), "Bienvenue chez ZooLife™", "Votre pseudo")
	add_child(f["racine"])
	var v: VBoxContainer = f["corps"]
	var t := Composants.label("Il signera vos scores aux défis. Vous pourrez le changer dans les statistiques.")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size.x = 480
	t.add_theme_font_size_override("font_size", 14)
	v.add_child(t)
	var champ := LineEdit.new()
	champ.max_length = 16
	champ.placeholder_text = "3 à 16 caractères"
	v.add_child(champ)
	var msg := Composants.label("")
	msg.add_theme_font_size_override("font_size", 13)
	msg.add_theme_color_override("font_color", UiTokens.ORANGE)
	v.add_child(msg)
	var ok := Composants.bouton("Valider", "BoutonFort")
	v.add_child(ok)
	var valider := func(_t = ""):
		var e := Statistiques.erreur_pseudo(champ.text)
		if e != "":
			msg.text = e
			return
		Statistiques.changer_pseudo(champ.text)
		queue_free()
	ok.pressed.connect(valider)
	champ.text_submitted.connect(valider)
	champ.grab_focus.call_deferred()
