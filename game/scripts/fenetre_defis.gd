class_name FenetreDefis
extends Control
## Fenêtre des défis, ouverte du menu : les quatre défis fixes et celui de la semaine, avec le meilleur score du joueur,
## son rang en ligne et le top 10 (pseudos visibles seulement pour qui y figure), et le replay du vainqueur du défi de
## la semaine passée.

signal jouer(id: String)
signal revoir(replay: Dictionary)  # replay du vainqueur de la semaine passée

var classement: Classement


func _ready() -> void:
	Statistiques.charger()
	theme = UiTokens.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	classement = Classement.new()
	add_child(classement)
	var D := Defis.donnees()
	var f := Composants.fenetre(Vector2(800, 0), "La même partie pour tous", "Défis", queue_free)
	add_child(f["racine"])
	var v: VBoxContainer = f["corps"]
	var intro := Composants.label("%d jours, seul contre les 3 meilleures IA. Même carte, même draft, mêmes collaborateurs, cartes et espèces au marché, dans le même ordre, quoi que vous fassiez. Score : votre réputation au soir du jour %d." % [int(D["jours"]), int(D["jours"])])
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x = 760
	intro.add_theme_font_size_override("font_size", 14)
	v.add_child(intro)
	for d in Defis.liste():
		v.add_child(_ligne(d))
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 12)
	v.add_child(bas)
	var note := Composants.label("" if classement.actif() else "Classement en ligne pas encore ouvert : seul votre meilleur score est gardé, sur cette machine.")
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bas.add_child(note)
	if classement.actif():
		_replay_semaine(bas, note)


func _ligne(d: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.SELECTION if d.has("semaine") else UiTokens.PAPIER, 10, 2, 10, false))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	p.add_child(col)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	col.add_child(h)
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
	var droite := VBoxContainer.new()
	droite.add_theme_constant_override("separation", 0)
	droite.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(droite)
	var score := Composants.label("Meilleur score : %d (%d partie%s)" % [roundi(float(s["meilleur"])), int(s["parties"]), "s" if int(s["parties"]) > 1 else ""] if not s.is_empty() else "Pas encore joué")
	score.add_theme_font_size_override("font_size", 15)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	droite.add_child(score)
	var rang := Composants.label("")
	rang.add_theme_font_size_override("font_size", 13)
	rang.add_theme_color_override("font_color", UiTokens.SARCELLE_FONCE)
	rang.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	droite.add_child(rang)
	var top_btn := Composants.bouton("Top 10", "BoutonSecondaire")
	top_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_btn.visible = false
	h.add_child(top_btn)
	var b := Composants.bouton("Jouer", "BoutonFort")
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): jouer.emit(str(d["id"])))
	h.add_child(b)
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 2)
	top.visible = false
	col.add_child(top)
	top_btn.pressed.connect(func(): top.visible = not top.visible)
	if classement.actif():
		rang.text = "Classement…"
		_remplir.call_deferred(str(d["id"]), rang, top, top_btn)
	return p


## Rang du joueur et top 10, lus sur le serveur après l'ouverture de la fenêtre.
func _remplir(id: String, rang: Label, top: VBoxContainer, top_btn: Button) -> void:
	var c: Dictionary = await classement.classement(id)
	if not is_instance_valid(rang):
		return
	if c.is_empty():
		rang.text = classement.erreur
		return
	rang.text = ("Vous : " + Classement.texte_rang(c)) if c.get("rang") != null else Classement.texte_rang(c)
	var lignes: Array = c.get("top", [])
	top_btn.visible = not lignes.is_empty()
	for e in lignes:
		var nom: String = str(e["pseudo"]) if e.get("pseudo") != null else ("vous" if e.get("moi", false) else "joueur masqué")
		var l := Composants.label("%2d.  %-18s  %d" % [int(e["rang"]), nom, roundi(float(e["score"]))])
		l.add_theme_font_override("font", UiTokens.police_mono(600 if e.get("moi", false) else 500))
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", UiTokens.SARCELLE_FONCE if e.get("moi", false) else UiTokens.ENCRE)
		top.add_child(l)
	if c.get("rang") == null or int(c["rang"]) > 10:
		var n := Composants.label("Les pseudos du top 10 ne se voient qu'une fois dedans.")
		n.add_theme_font_size_override("font_size", 12)
		n.add_theme_color_override("font_color", UiTokens.TEXTE_2)
		top.add_child(n)


func _replay_semaine(bas: HBoxContainer, note: Label) -> void:
	var r = await classement._rpc("replay_semaine_precedente", {})
	if not is_instance_valid(bas) or not r is Dictionary or not r.get("replay") is Dictionary:
		return
	note.text = "Vainqueur de la semaine passée : %s, %d de réputation." % [r["pseudo"], roundi(float(r["score"]))]
	var b := Composants.bouton("Revoir sa partie", "BoutonSecondaire")
	b.pressed.connect(func(): revoir.emit(r["replay"]))
	bas.add_child(b)
