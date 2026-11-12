class_name Statistiques
extends Control
## Statistiques du joueur (12/11/2026), gardées sur sa machine dans user://statistiques.json : pseudo, parties jouées par
## mode, records, défis, collection (espèces installées, collaborateurs recrutés), succès. La partie est notée à sa fin
## (enregistrer, appelé par main). Comme Reglages, la classe est aussi la fenêtre qui les montre.

const FICHIER := "user://statistiques.json"
const MAX_PARTIES := 200
const MODES := [["course", "Course"], ["nature", "Réserve naturelle"], ["cozy", "Gestion libre"], ["defi", "Défis"], ["multi", "Multijoueur"]]
const SOURCES := {"frequentation": "Fréquentation", "spectacles": "Spectacles", "boutique": "Boutique", "beaute": "Beauté du parc",
	"prestige": "Prestige politique", "labels": "Labels", "legendaires": "Légendaires", "objectifs": "Objectifs"}
const SUCCES := [
	["premiere", "Première concession", "Gagner une partie."],
	["reserve", "Garde forestier", "Gagner en Réserve naturelle."],
	["rapide", "Promotion éclair", "Gagner avant le jour 10."],
	["ouverture", "Portes ouvertes", "Ouvrir son zoo au jour 3 ou avant."],
	["sans_amenageur", "Le terrain tel qu'il est", "Gagner une course sans Terrassier ni Paysagiste dans l'équipe."],
	["continent", "Spécialiste", "Réunir 4 espèces du même continent dans un zoo."],
	["monde", "Tour du monde", "Réunir des espèces de 4 continents dans un zoo."],
	["famille", "Heureux événement", "Voir naître 2 petits chez un même animal."],
	["defi_100", "Actionnaire satisfait", "Atteindre 100 de réputation dans un défi."],
	["collection_10", "Collectionneur", "Installer 10 espèces différentes, toutes parties confondues."],
	["collection_toutes", "Arche de ZooLife", "Installer toutes les espèces au moins une fois."],
	["legende", "Légende vivante", "Amener un collaborateur au niveau 6."],
]

static var donnees := {}
static var _charge := false


static func charger() -> void:
	if _charge:
		return
	_charge = true
	donnees = {"pseudo": "", "parties": [], "totaux": {}, "especes": {}, "persos": {}, "defis": {}, "succes": {},
		"especes_date": {}, "persos_niveau": {}, "niveau_max": 1}
	if FileAccess.file_exists(FICHIER):
		var d = JSON.parse_string(FileAccess.get_file_as_string(FICHIER))
		if d is Dictionary:
			for k in d:
				donnees[k] = d[k]
	if not donnees.has("debut") and not donnees["parties"].is_empty():
		donnees["debut"] = str(donnees["parties"][0].get("date", ""))


static func sauver() -> void:
	var f := FileAccess.open(FICHIER, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(donnees, "  "))


static func pseudo() -> String:
	charger()
	return str(donnees["pseudo"])


## Pseudo valide : 3 à 16 caractères, lettres, chiffres, espace, tiret, point, souligné. Renvoie l'erreur ou "".
static func erreur_pseudo(p: String) -> String:
	p = p.strip_edges()
	if p.length() < 3 or p.length() > 16:
		return "De 3 à 16 caractères."
	var re := RegEx.create_from_string("^[\\p{L}\\p{N} ._-]+$")
	return "" if re.search(p) else "Lettres, chiffres, espace, tiret, point ou souligné seulement."


static func changer_pseudo(p: String) -> void:
	charger()
	donnees["pseudo"] = p.strip_edges()
	sauver()


static func cle_mode(mt: Match) -> String:
	if mt.defi != "":
		return "defi"
	return "multi" if mt.ais.count(null) > 1 else mt.mode


## Premier jour où le zoo du joueur a reçu des visiteurs (d'après l'historique des soirs), 0 s'il n'a jamais ouvert.
static func jour_ouverture(mt: Match, i: int) -> int:
	for row in mt.history:
		if i < row.size() and int(row[i].get("visitors", 0)) > 0:
			return int(row[i]["day"])
	return 0


## Note la partie finie du joueur i. Renvoie {"record": vrai si c'est son meilleur score au défi, "ancien": score
## précédent, "succes": noms des succès débloqués}.
static func enregistrer(mt: Match, i: int) -> Dictionary:
	charger()
	var p: GameState = mt.players[i]
	var cle := cle_mode(mt)
	var rangs := range(mt.players.size())
	rangs.sort_custom(func(a, b): return mt.players[a].reputation() > mt.players[b].reputation())
	var ouv_ia: Array = []
	for k in mt.players.size():
		if mt.ais[k] != null and jour_ouverture(mt, k) > 0:
			ouv_ia.append(jour_ouverture(mt, k))
	var arrives := p.animals.filter(func(a): return a.arrived)
	var especes: Array = arrives.map(func(a): return str(a.def["id"]))
	var partie := {"date": Time.get_date_string_from_system(), "mode": cle, "defi": mt.defi, "graine": mt.seed_value,
		"jour": mt.day, "rep": snappedf(p.reputation(), 0.1), "rang": rangs.find(i) + 1, "joueurs": mt.players.size(),
		"gagne": mt.winner == i and mt.mode != "cozy", "ouverture": jour_ouverture(mt, i),
		"ouverture_ia": snappedf(ouv_ia.reduce(func(s, x): return s + x, 0.0) / maxf(1.0, ouv_ia.size()), 0.1) if not ouv_ia.is_empty() else 0.0,
		"especes": especes, "sources": p.rep_sources.duplicate()}
	donnees["parties"].append(partie)
	if donnees["parties"].size() > MAX_PARTIES:
		donnees["parties"] = donnees["parties"].slice(-MAX_PARTIES)
	var t: Dictionary = donnees["totaux"].get(cle, {"parties": 0, "victoires": 0, "meilleur_jour": 0, "record": 0.0, "rep_totale": 0.0})
	t["parties"] = int(t["parties"]) + 1
	t["rep_totale"] = float(t["rep_totale"]) + p.reputation()
	t["record"] = maxf(float(t["record"]), p.reputation())
	if partie["gagne"]:
		t["victoires"] = int(t["victoires"]) + 1
		if int(t["meilleur_jour"]) == 0 or mt.day < int(t["meilleur_jour"]):
			t["meilleur_jour"] = mt.day
	donnees["totaux"][cle] = t
	if not donnees.has("debut"):
		donnees["debut"] = partie["date"]
	for e in especes:
		donnees["especes"][e] = int(donnees["especes"].get(e, 0)) + 1
		donnees["especes_date"][e] = partie["date"]
	for c in p.all_employees():
		if str(c.perso) != "":
			donnees["persos"][str(c.perso)] = int(donnees["persos"].get(str(c.perso), 0)) + 1
			donnees["persos_niveau"][str(c.perso)] = maxi(int(donnees["persos_niveau"].get(str(c.perso), 1)), c.niveau)
		donnees["niveau_max"] = maxi(int(donnees.get("niveau_max", 1)), c.niveau)
	var out := {"record": false, "ancien": 0.0, "succes": []}
	if mt.defi != "":
		var d: Dictionary = donnees["defis"].get(mt.defi, {"meilleur": 0.0, "parties": 0})
		out["ancien"] = float(d["meilleur"])
		out["record"] = int(d["parties"]) == 0 or p.reputation() > float(d["meilleur"])
		d["parties"] = int(d["parties"]) + 1
		if out["record"]:
			d["meilleur"] = snappedf(p.reputation(), 0.1)
			d["date"] = partie["date"]
		donnees["defis"][mt.defi] = d
	for s in _succes_obtenus(mt, i, partie):
		if not donnees["succes"].has(s):
			donnees["succes"][s] = partie["date"]
			out["succes"].append(SUCCES.filter(func(x): return x[0] == s)[0][1])
	sauver()
	return out


static func _succes_obtenus(mt: Match, i: int, partie: Dictionary) -> Array:
	var p: GameState = mt.players[i]
	var out: Array = []
	var gagne: bool = partie["gagne"]
	if gagne:
		out.append("premiere")
		if mt.mode == "nature":
			out.append("reserve")
		if mt.day < 10 and mt.defi == "":
			out.append("rapide")
		if mt.mode == "course" and mt.defi == "" and not p.all_employees().any(func(c): return c.metier["id"] in ["terrassier", "paysagiste"]):
			out.append("sans_amenageur")
	if int(partie["ouverture"]) > 0 and int(partie["ouverture"]) <= 3:
		out.append("ouverture")
	var par_continent := {}
	for a in p.animals.filter(func(x): return x.arrived):
		par_continent[a.def["continent"]] = int(par_continent.get(a.def["continent"], 0)) + 1
		if a.petits >= 2:
			out.append("famille")
	if par_continent.values().any(func(n): return n >= 4):
		out.append("continent")
	if par_continent.size() >= 4:
		out.append("monde")
	if mt.defi != "" and p.reputation() >= 100.0:
		out.append("defi_100")
	if donnees["especes"].size() >= 10:
		out.append("collection_10")
	if donnees["especes"].size() >= mt.data["animals"]["animaux"].size():
		out.append("collection_toutes")
	if p.all_employees().any(func(c): return c.niveau >= 6):
		out.append("legende")
	return out


# --- La fenêtre -----------------------------------------------------------------
## « Dossier personnel » (docs/handoff_menus, maquettes 20 à 24) : fenêtre 1280 × 700, quatre onglets en intercalaires
## (Résumé, Parties, Collection, Succès), rien ne défile sauf la liste des dernières parties. Sans aucune partie, le
## Résumé propose trois missions (tutoriel, première partie, défi de la semaine).
## Captures : --statistiques [--stats-onglet=resume|parties|collection|succes] [--stats-demo] (données fictives, rien
## n'est écrit).

signal mission(nom: String)  # « tutoriel », « jouer » ou « defi » : le menu s'en charge

const L := 1280.0
const H := 700.0
const CORPS_Y := 80.0
const ONGLETS := [["resume", "Résumé"], ["parties", "Parties"], ["collection", "Collection"], ["succes", "Succès"]]
## Forme et couleur de chaque mode (double codage) : [clé, nom, forme, couleur].
const FORMES_MODES := [["course", "Partie classique", "triangle", Color("F07F2A")], ["nature", "Réserve naturelle", "rond", Color("1F7A4A")],
	["cozy", "Gestion libre", "carre", Color("2E4256")], ["defi", "Défis", "losange", Color("2F6FD0")], ["multi", "Multijoueur", "etoile", Color("E04A8A")]]
const COULEURS_SOURCES := [["frequentation", "Fréquentation", Color("13867F")], ["spectacles", "Spectacles", Color("F0A020")],
	["boutique", "Boutique", Color("3A6AE0")], ["objectifs", "Objectifs", Color("E04A8A")], ["beaute", "Beauté du parc", Color("8DBF5A")],
	["labels", "Labels", Color("8A6400")], ["prestige", "Prestige politique", Color("2E4256")], ["legendaires", "Collaborateurs légendaires", Color("B5452A")]]
const RARETES := {"T1": ["rond", Color("9AA2AC"), "commun"], "T2": ["losange", Color("2F6FD0"), "peu commun"], "T3": ["etoile", Color("FFC93C"), "rare"]}
const CONTINENTS := [["Europe", "Europe"], ["Amerique", "Amérique"], ["Asie", "Asie"], ["Afrique", "Afrique"]]
## Code inscrit sur la médaille de chaque succès.
const CODES_SUCCES := {"premiere": "1er", "reserve": "RN", "rapide": "J9", "ouverture": "J3", "sans_amenageur": "T0", "continent": "4×",
	"monde": "4C", "famille": "+2", "defi_100": "100", "collection_10": "10", "collection_toutes": "40", "legende": "N6"}
const GRADES := [[60, "Membre du comité"], [30, "Directeur"], [15, "Directeur adjoint"], [3, "Cadre"], [0, "Stagiaire"]]

var _donnees_jeu := {}
var onglet := "resume"
var d := {}  # données montrées (les vraies, ou des données fictives pour les captures)
var fenetre: Panel
var corps: Control
var barre_onglets: HBoxContainer


func _init(donnees_jeu := {}) -> void:
	_donnees_jeu = donnees_jeu if not donnees_jeu.is_empty() else GameData.load_all()


func _ready() -> void:
	charger()
	d = donnees
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--stats-onglet="):
			onglet = a.trim_prefix("--stats-onglet=")
		elif a == "--stats-demo":
			d = _demo()
		elif a == "--stats-vide":
			d = {"pseudo": str(donnees.get("pseudo", "")), "parties": [], "totaux": {}, "especes": {}, "persos": {}, "defis": {}, "succes": {}}
	theme = UiTokens.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var voile := ColorRect.new()
	voile.color = Color(UiTokens.ENCRE, 0.55)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)
	fenetre = Panel.new()
	fenetre.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.FOND_FENETRE, 12, 2, 0, true))
	fenetre.set_anchors_preset(Control.PRESET_CENTER)
	fenetre.offset_left = -L / 2.0
	fenetre.offset_right = L / 2.0
	fenetre.offset_top = -H / 2.0
	fenetre.offset_bottom = H / 2.0
	add_child(fenetre)
	corps = Control.new()
	corps.position = Vector2(0, CORPS_Y)
	corps.size = Vector2(L, H - CORPS_Y)
	corps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fenetre.add_child(corps)
	_entete()
	_montrer(onglet)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		queue_free()
		accept_event()


# ---------------------------------------------------------------- en-tête et onglets

func _entete() -> void:
	var tete := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = UiTokens.PAPIER
	st.corner_radius_top_left = 11
	st.corner_radius_top_right = 11
	tete.add_theme_stylebox_override("panel", st)
	Composants.placer(fenetre, tete, Vector2(2, 2), Vector2(L - 4, CORPS_Y - 2))
	var filet := ColorRect.new()
	filet.color = UiTokens.ENCRE
	filet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Composants.placer(fenetre, filet, Vector2(2, CORPS_Y - 2), Vector2(L - 4, 2))
	Composants.placer(tete, Composants.texte("DOSSIER PERSONNEL · CONFIDENTIEL RH", 12, 600, UiTokens.TEXTE_2, "mono"), Vector2(20, 12), Vector2(400, 18))
	Composants.placer(tete, Composants.texte("Statistiques", 34, 800, UiTokens.ENCRE, "titre"), Vector2(20, 30), Vector2(230, 40))
	barre_onglets = HBoxContainer.new()
	barre_onglets.add_theme_constant_override("separation", 6)
	barre_onglets.alignment = BoxContainer.ALIGNMENT_BEGIN
	Composants.placer(fenetre, barre_onglets, Vector2(260, CORPS_Y - 44), Vector2(800, 44))
	var x := Composants.bouton("✕", "BoutonSecondaire")
	x.add_theme_font_size_override("font_size", 18)
	x.pressed.connect(queue_free)
	Composants.placer(tete, x, Vector2(L - 4 - 60, 18), Vector2(40, 40))


func _compte_onglet(id: String) -> String:
	match id:
		"parties":
			return str(_total_parties())
		"collection":
			return "%d/%d" % [_especes_vues().size(), _animaux().size()]
		"succes":
			return "%d/%d" % [d["succes"].size(), SUCCES.size()]
	return ""


func _maj_onglets() -> void:
	for e in barre_onglets.get_children():
		barre_onglets.remove_child(e)
		e.queue_free()
	for o in ONGLETS:
		var actif: bool = o[0] == onglet
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.size_flags_vertical = Control.SIZE_SHRINK_END
		b.custom_minimum_size.y = 44 if actif else 38
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiTokens.FOND_FENETRE if actif else UiTokens.GRIS_ONGLET
		sb.border_color = UiTokens.ENCRE
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.content_margin_left = 20
		sb.content_margin_right = 20
		sb.anti_aliasing = true
		if actif:
			sb.expand_margin_bottom = 2  # recouvre le filet de l'en-tête : l'onglet s'ouvre sur la page
		for s in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(s, sb)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(h)
		h.add_child(Composants.texte(str(o[1]).to_upper(), 16, 800, UiTokens.ENCRE if actif else UiTokens.TEXTE_2, "titre"))
		var n := _compte_onglet(o[0])
		if n != "":
			h.add_child(Composants.texte(n, 12, 600, UiTokens.ENCRE if actif else UiTokens.TEXTE_2, "mono"))
		var largeur := Composants.texte(str(o[1]).to_upper(), 16, 800, UiTokens.ENCRE, "titre").get_minimum_size().x
		b.custom_minimum_size.x = 40 + largeur + (8 + 9 * n.length() if n != "" else 0)
		if actif:
			var jaune := ColorRect.new()
			jaune.color = UiTokens.SELECTION
			jaune.mouse_filter = Control.MOUSE_FILTER_IGNORE
			jaune.position = Vector2(2, 2)
			jaune.size = Vector2(b.custom_minimum_size.x - 4, 4)
			b.add_child(jaune)
			b.resized.connect(func(): jaune.size.x = b.size.x - 4)
		var id: String = o[0]
		b.pressed.connect(func(): _montrer(id))
		barre_onglets.add_child(b)


func _montrer(id: String) -> void:
	onglet = id
	_maj_onglets()
	for e in corps.get_children():
		corps.remove_child(e)
		e.queue_free()
	match id:
		"parties":
			_page_parties()
		"collection":
			_page_collection()
		"succes":
			_page_succes()
		_:
			if _total_parties() == 0:
				_page_premiere()
			else:
				_page_resume()


# ---------------------------------------------------------------- briques

## Panneau à bandeau (sarcelle par défaut) : renvoie {"racine", "corps"} ; le corps est une marge de 14.
func _panneau(titre: String, droite: String, pos: Vector2, taille: Vector2, couleur := UiTokens.SARCELLE, droite_couleur := UiTokens.ENTETE) -> Dictionary:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTokens.panneau(UiTokens.PAPIER, 10, 2, 2, true))
	Composants.placer(corps, p, pos, taille)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var e := Composants.entete_comite(titre, droite, couleur)
	var pc: PanelContainer = e["racine"]
	var sb: StyleBoxFlat = pc.get_theme_stylebox("panel").duplicate()
	sb.border_color = UiTokens.ENCRE
	sb.border_width_bottom = 2
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	pc.add_theme_stylebox_override("panel", sb)
	(e["titre"] as Label).add_theme_font_size_override("font_size", 15)
	(e["droite"] as Label).add_theme_color_override("font_color", droite_couleur)
	v.add_child(pc)
	var m := MarginContainer.new()
	for c in [["left", 14], ["right", 14], ["top", 10], ["bottom", 12]]:
		m.add_theme_constant_override("margin_" + c[0], c[1])
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(m)
	return {"racine": p, "corps": m}


func _txt(t: String, taille := 14, graisse := 600, couleur := UiTokens.ENCRE, famille := "corps") -> Label:
	return Composants.texte(t, taille, graisse, couleur, famille)


func _espace(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _barre(f: float, couleur := UiTokens.SARCELLE, h := 10.0, largeur := 0.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(largeur, h)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var fond := StyleBoxFlat.new()
		fond.bg_color = UiTokens.FILET
		fond.set_corner_radius_all(int(h / 2.0))
		fond.draw(c.get_canvas_item(), Rect2(Vector2.ZERO, c.size))
		if f > 0.0:
			var plein: StyleBoxFlat = fond.duplicate()
			plein.bg_color = couleur
			plein.draw(c.get_canvas_item(), Rect2(Vector2.ZERO, Vector2(maxf(h, c.size.x * clampf(f, 0.0, 1.0)), c.size.y))))
	return c


func _bulle_hubert(t: String, pos: Vector2, largeur: float, legende := true) -> void:
	var b := PanelContainer.new()
	var sb := UiTokens.panneau(UiTokens.MEMO, 10, 2, 0, true)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("panel", sb)
	var l := _txt("« %s »" % t, 14, 600, UiTokens.ENCRE, "italique")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = largeur - 32
	b.add_child(l)
	if legende:
		Composants.placer(corps, b, pos, Vector2(largeur, 0))
		b.reset_size()
		var bas := pos.y + maxf(56.0, b.get_combined_minimum_size().y) + 12.0
		var tete := Composants.image_logo(load("res://assets/bd/hubert/content.png"), Vector2(62, 62))
		Composants.placer(corps, tete, Vector2(pos.x, bas), Vector2(62, 62))
		var n := VBoxContainer.new()
		n.add_theme_constant_override("separation", -2)
		n.add_child(_txt("Hubert de la Marge", 12, 700))
		n.add_child(_txt("votre supérieur", 12, 600, UiTokens.TEXTE_2))
		Composants.placer(corps, n, Vector2(pos.x + 68, bas + 16), Vector2(200, 34))
	else:
		var tete := Composants.image_logo(load("res://assets/bd/hubert/moqueur.png"), Vector2(58, 58))
		Composants.placer(corps, tete, pos, Vector2(58, 58))
		Composants.placer(corps, b, pos + Vector2(66, 8), Vector2(largeur, 0))
		b.reset_size()


## Médaille de succès : disque jaune à ruban sarcelle (obtenu) ou disque et ruban gris en pointillé (à obtenir).
class Medaille extends Control:
	var code := ""
	var obtenu := true

	func _init(c: String, o: bool, taille := 64.0) -> void:
		code = c
		obtenu = o
		custom_minimum_size = Vector2(taille, taille * 1.25)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := size.x / 2.0 - 2.0
		var c := Vector2(size.x / 2.0, r + 2.0)
		var ruban := UiTokens.SARCELLE if obtenu else Color("C9CED4")
		for s in [-1.0, 1.0]:
			var pts := PackedVector2Array([c + Vector2(s * r * 0.15, r * 0.5), c + Vector2(s * r * 0.75, r * 0.6),
				c + Vector2(s * r * 0.6, r * 1.55), c + Vector2(s * r * 0.35, r * 1.35), c + Vector2(s * r * 0.1, r * 1.5)])
			draw_colored_polygon(pts, ruban)
			var ferme := pts.duplicate()
			ferme.append(pts[0])
			draw_polyline(ferme, UiTokens.ENCRE if obtenu else UiTokens.POINTILLES, 2.0, true)
		if obtenu:
			draw_circle(c, r, UiTokens.SELECTION, true, -1.0, true)
			draw_arc(c, r - 1.0, 0.0, TAU, 40, UiTokens.ENCRE, 2.0, true)
		else:
			draw_circle(c, r, UiTokens.FOND_FENETRE, true, -1.0, true)
			var k := 0.0
			while k < TAU:
				draw_arc(c, r - 1.0, k, k + 0.22, 4, UiTokens.POINTILLES, 2.5, true)
				k += 0.4
		var f := UiTokens.police_mono(600)
		var t := int(r * (0.62 if code.length() <= 2 else 0.5))
		var w := f.get_string_size(code, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x
		draw_string(f, c + Vector2(-w / 2.0, t * 0.36), code, HORIZONTAL_ALIGNMENT_LEFT, -1, t, UiTokens.ENCRE if obtenu else UiTokens.POINTILLES)


## Réputation finale des dernières parties : point plein si gagnée, creux sinon, objectif en tirets.
class Courbe extends Control:
	var valeurs: Array = []
	var gagnees: Array = []
	var objectif := 120.0

	func _draw() -> void:
		var f := UiTokens.police_mono(500)
		var g := 40.0
		var bas := size.y - 36.0
		var haut := 12.0
		var mini := 60.0
		var maxi := objectif + 20.0
		for x in valeurs:
			maxi = maxf(maxi, float(x))
			mini = minf(mini, float(x))
		var y_de := func(v: float) -> float: return bas - (v - mini) / maxf(1.0, maxi - mini) * (bas - haut)
		draw_line(Vector2(g, bas), Vector2(size.x - 8, bas), UiTokens.ENCRE, 2.0)
		draw_string(f, Vector2(0, bas + 4), str(roundi(mini)), HORIZONTAL_ALIGNMENT_RIGHT, g - 8, 11, UiTokens.TEXTE_2)
		var yo: float = y_de.call(objectif)
		draw_dashed_line(Vector2(g, yo), Vector2(size.x - 8, yo), UiTokens.ENCRE, 1.5, 6.0)
		draw_string(f, Vector2(0, yo + 4), str(roundi(objectif)), HORIZONTAL_ALIGNMENT_RIGHT, g - 8, 11, UiTokens.TEXTE_2)
		draw_string(f, Vector2(g + 6, bas + 18), "il y a %d partie%s" % [valeurs.size(), "s" if valeurs.size() > 1 else ""], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiTokens.TEXTE_2)
		draw_string(f, Vector2(size.x - 70, bas + 18), "dernière", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UiTokens.TEXTE_2)
		if valeurs.is_empty():
			return
		var pas := (size.x - g - 30.0) / maxf(1.0, valeurs.size() - 1)
		var pts := PackedVector2Array()
		for k in valeurs.size():
			pts.append(Vector2(g + 12.0 + k * pas, y_de.call(float(valeurs[k]))))
		if pts.size() > 1:
			draw_polyline(pts, UiTokens.SARCELLE, 2.5, true)
		for k in pts.size():
			if gagnees[k]:
				draw_circle(pts[k], 6.0, UiTokens.SARCELLE, true, -1.0, true)
				draw_arc(pts[k], 6.0, 0.0, TAU, 20, UiTokens.ENCRE, 2.0, true)
			else:
				draw_circle(pts[k], 6.0, UiTokens.PAPIER, true, -1.0, true)
				draw_arc(pts[k], 6.0, 0.0, TAU, 20, UiTokens.ENCRE, 2.0, true)


func _legende_courbe() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var plein := Composants.Forme.new("rond", UiTokens.SARCELLE, 11.0)
	plein.contour = UiTokens.ENCRE
	h.add_child(plein)
	h.add_child(_txt("victoire", 12, 600))
	h.add_child(_espace(0))
	var creux := Composants.Forme.new("rond", UiTokens.ENCRE, 11.0)
	creux.creux = true
	h.add_child(creux)
	h.add_child(_txt("défaite", 12, 600))
	h.add_child(_txt("  - -", 12, 700, UiTokens.ENCRE, "mono"))
	h.add_child(_txt("objectif 120", 12, 600))
	return h


func _courbe(parent: Control, n: int) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	parent.add_child(v)
	var parties: Array = d["parties"].slice(-n)
	var c := Courbe.new()
	c.valeurs = parties.map(func(p): return float(p["rep"]))
	c.gagnees = parties.map(func(p): return bool(p.get("gagne", false)))
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size.y = 100
	v.add_child(c)
	v.add_child(_legende_courbe())


# ---------------------------------------------------------------- calculs

func _n_dernieres() -> String:
	var n := mini(20, d["parties"].size())
	return "%d dernière%s" % [n, "s" if n > 1 else ""]


func _total_parties() -> int:
	var n := 0
	for k in d["totaux"]:
		n += int(d["totaux"][k].get("parties", 0))
	return n


func _total(cle: String) -> float:
	var n := 0.0
	for k in d["totaux"]:
		n += float(d["totaux"][k].get(cle, 0))
	return n


func _animaux() -> Array:
	return _donnees_jeu["animals"]["animaux"]


func _persos() -> Array:
	return _donnees_jeu["personnages"]["personnages"]


func _especes_vues() -> Array:
	return _animaux().filter(func(a): return d["especes"].has(str(a["id"])))


func _persos_vus() -> Array:
	return _persos().filter(func(p): return d["persos"].has(str(p["id"])))


func _grade() -> String:
	var v := int(_total("victoires"))
	for g in GRADES:
		if v >= int(g[0]):
			return g[1]
	return "Stagiaire"


func _matricule() -> String:
	var annee := str(d.get("debut", Time.get_date_string_from_system())).substr(0, 4)
	return "ZL-%s-%04d" % [annee, absi(hash(str(d["pseudo"]))) % 10000]


func _date_courte(iso: String, annee := false) -> String:
	var p := iso.split("-")
	if p.size() < 3:
		return iso
	return ("%s/%s/%s" % [p[2], p[1], p[0]]) if annee else ("%s/%s" % [p[2], p[1]])


func _anciennete() -> String:
	var debut := str(d.get("debut", ""))
	if debut == "":
		return ""
	var j := int((Time.get_unix_time_from_system() - Time.get_unix_time_from_datetime_string(debut)) / 86400.0)
	if j < 1:
		return "aujourd'hui"
	if j < 31:
		return "%d jour%s" % [j, "s" if j > 1 else ""]
	return "%d mois" % (j / 30)


func _sources_totales() -> Dictionary:
	var somme := {}
	for p in d["parties"]:
		for k in p.get("sources", {}):
			somme[k] = float(somme.get(k, 0.0)) + maxf(0.0, float(p["sources"][k]))
	return somme


func _ouvertures() -> Array:
	var moi: Array = d["parties"].filter(func(p): return int(p.get("ouverture", 0)) > 0)
	var ia: Array = moi.filter(func(p): return float(p.get("ouverture_ia", 0.0)) > 0.0)
	return [moi.reduce(func(s, p): return s + float(p["ouverture"]), 0.0) / maxf(1, moi.size()) if not moi.is_empty() else 0.0,
		ia.reduce(func(s, p): return s + float(p["ouverture_ia"]), 0.0) / maxf(1, ia.size()) if not ia.is_empty() else 0.0]


func _nom_mode(cle: String) -> String:
	for m in FORMES_MODES:
		if m[0] == cle:
			return m[1]
	return cle


func _forme_mode(cle: String) -> Control:
	for m in FORMES_MODES:
		if m[0] == cle:
			return Composants.Forme.new(m[2], m[3], 11.0)
	return Composants.Forme.new("rond", UiTokens.ENCRE, 11.0)


func _virgule(x: float) -> String:
	return ("%.1f" % x).replace(".", ",")


# ---------------------------------------------------------------- Résumé

func _fiche_signaletique(essai: bool) -> void:
	var p := _panneau("Fiche signalétique", "RÉF. %04d" % (absi(hash(str(d["pseudo"]))) % 10000), Vector2(20, 20), Vector2(330, 372), UiTokens.ENCRE, UiTokens.SELECTION)
	var c: MarginContainer = p["corps"]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	c.add_child(v)
	var haut := HBoxContainer.new()
	haut.add_theme_constant_override("separation", 12)
	v.add_child(haut)
	var photo := PanelContainer.new()
	var sp := UiTokens.panneau(Color("BFE6DF"), 6, 2, 0, false)
	photo.add_theme_stylebox_override("panel", sp)
	photo.custom_minimum_size = Vector2(96, 118)
	var im := Composants.image_logo(load("res://assets/bd/logos/zoolife_embleme.png"), Vector2(92, 92))
	im.size_flags_vertical = Control.SIZE_SHRINK_END
	photo.add_child(im)
	haut.add_child(photo)
	var droite := VBoxContainer.new()
	droite.add_theme_constant_override("separation", 0)
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	haut.add_child(droite)
	var tp := HBoxContainer.new()
	tp.alignment = BoxContainer.ALIGNMENT_END
	tp.add_child(Composants.tampon("PÉRIODE D'ESSAI" if essai else "ÉVALUATION : CONFORME", UiTokens.SARCELLE, 12, -6.0))
	droite.add_child(tp)
	droite.add_child(_espace(16))
	var nom := str(d["pseudo"]) if str(d["pseudo"]) != "" else "Sans nom"
	droite.add_child(_txt(nom.to_upper(), 28, 800, UiTokens.ENCRE, "titre"))
	droite.add_child(_txt("Cadre ZooLife™", 12, 600, UiTokens.TEXTE_2))
	droite.add_child(_txt("filiale de la vallée", 12, 600, UiTokens.TEXTE_2))
	v.add_child(_espace(14))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	var lib := func(t: String) -> Label:
		var l := _txt(t, 11, 600, UiTokens.TEXTE_2, "mono")
		l.custom_minimum_size.x = 106
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return l
	g.add_child(lib.call("PSEUDO"))
	g.add_child(_ligne_pseudo())
	g.add_child(lib.call("MATRICULE"))
	g.add_child(_txt(_matricule(), 15, 600, UiTokens.ENCRE, "mono"))
	g.add_child(lib.call("EN POSTE DEPUIS"))
	g.add_child(_txt(_date_courte(str(d.get("debut", Time.get_date_string_from_system())), true), 15, 600, UiTokens.ENCRE, "mono"))
	g.add_child(lib.call("PARTIES"))
	var n := _total_parties()
	g.add_child(_txt(str(n) + ((" · " + _anciennete()) if n > 0 and _anciennete() != "" else ""), 15, 600, UiTokens.ENCRE, "mono"))
	g.add_child(lib.call("GRADE"))
	g.add_child(_txt(_grade(), 14, 600))


## Pseudo et « Modifier » : le bouton ouvre un champ, « OK » enregistre (3 à 16 caractères).
func _ligne_pseudo() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := _txt(str(d["pseudo"]), 14, 600)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	var champ := LineEdit.new()
	champ.text = str(d["pseudo"])
	champ.max_length = 16
	champ.custom_minimum_size = Vector2(110, 30)
	champ.visible = false
	h.add_child(champ)
	var b := Composants.bouton("Modifier", "BoutonMini")
	b.custom_minimum_size.y = 26
	b.add_theme_font_size_override("font_size", 12)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	var valider := func():
		var e := erreur_pseudo(champ.text)
		if e != "":
			champ.tooltip_text = e
			champ.add_theme_color_override("font_color", UiTokens.NEGATIF)
			return
		if d == donnees:
			changer_pseudo(champ.text)
		d["pseudo"] = champ.text.strip_edges()
		_montrer(onglet)
	b.pressed.connect(func():
		if champ.visible:
			valider.call()
		else:
			l.visible = false
			champ.visible = true
			b.text = "OK"
			champ.grab_focus())
	champ.text_submitted.connect(func(_t): valider.call())
	return h


func _kpi(pos: Vector2, valeur: String, titre: String, sous: String, sous_couleur := UiTokens.TEXTE_2) -> void:
	var p := PanelContainer.new()
	var sb := UiTokens.panneau(UiTokens.PAPIER, 10, 2, 0, true)
	sb.content_margin_left = 14
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	p.add_theme_stylebox_override("panel", sb)
	Composants.placer(corps, p, pos, Vector2(208, 108))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	v.add_child(_txt(valeur, 38, 600, UiTokens.ENCRE, "mono"))
	v.add_child(_txt(titre.to_upper(), 13, 800, UiTokens.ENCRE, "titre"))
	var s := _txt(sous, 12, 600, sous_couleur)
	s.clip_text = true
	v.add_child(s)


func _page_resume() -> void:
	_fiche_signaletique(false)
	_bulle_hubert(_phrase_hubert(), Vector2(20, 410), 330)
	var n := _total_parties()
	var vic := int(_total("victoires"))
	var rec := 0.0
	var rec_p := {}
	for p in d["parties"]:
		if float(p["rep"]) >= rec:
			rec = float(p["rep"])
			rec_p = p
	var rapide := 0
	var rapide_p := {}
	for p in d["parties"]:
		if p.get("gagne", false) and (rapide == 0 or int(p["jour"]) < rapide):
			rapide = int(p["jour"])
			rapide_p = p
	var parties_jouees := n - int(d["totaux"].get("cozy", {}).get("parties", 0))
	_kpi(Vector2(370, 20), str(vic), "Victoires", "%d %% des %d parties disputées" % [roundi(100.0 * vic / maxf(1, parties_jouees)), parties_jouees])
	_kpi(Vector2(590, 20), str(roundi(rec)), "Réputation record",
		("%s · %s" % [_nom_mode(str(rec_p.get("mode", ""))) if str(rec_p.get("defi", "")) == "" else "Défi", _date_courte(str(rec_p.get("date", "")))]) if not rec_p.is_empty() else "—")
	_kpi(Vector2(810, 20), ("J%d" % rapide) if rapide > 0 else "—", "Victoire la plus rapide",
		("%s, %s" % [_nom_mode(str(rapide_p.get("mode", ""))), _date_courte(str(rapide_p.get("date", "")))]) if rapide > 0 else "pas encore de victoire")
	var ouv := _ouvertures()
	var ecart: float = ouv[1] - ouv[0]
	_kpi(Vector2(1030, 20), _virgule(ouv[0]) if ouv[0] > 0.0 else "—", "Ouverture du zoo",
		("%s %s jour plus %s que les IA" % ["▲" if ecart >= 0.0 else "▼", _virgule(absf(ecart)), "tôt" if ecart >= 0.0 else "tard"]) if ouv[0] > 0.0 and ouv[1] > 0.0 else "jour moyen d'ouverture",
		UiTokens.POSITIF if ecart >= 0.0 else UiTokens.NEGATIF)
	# Par mode
	var pm := _panneau("Par mode de jeu", "détail : onglet Parties", Vector2(370, 144), Vector2(498, 236))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 0)
	(pm["corps"] as MarginContainer).add_child(g)
	for e in [["MODE", 200], ["PARTIES", 60], ["VICTOIRES", 128], ["RECORD", 60]]:
		var l := _txt(e[0], 12, 800, UiTokens.TEXTE_2, "titre")
		l.custom_minimum_size = Vector2(e[1], 22)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if e[0] in ["PARTIES", "RECORD"] else HORIZONTAL_ALIGNMENT_LEFT
		g.add_child(l)
	for m in FORMES_MODES:
		var t: Dictionary = d["totaux"].get(m[0], {})
		if t.is_empty():
			continue
		var nom := HBoxContainer.new()
		nom.add_theme_constant_override("separation", 8)
		nom.custom_minimum_size.y = 30
		nom.add_child(_forme_mode(m[0]))
		nom.add_child(_txt(m[1], 14, 600))
		g.add_child(nom)
		var np := _txt(str(int(t["parties"])), 14, 600, UiTokens.ENCRE, "mono")
		np.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		g.add_child(np)
		if m[0] == "cozy":
			g.add_child(_txt("sans objet", 13, 600, UiTokens.TEXTE_2))
		else:
			var hv := HBoxContainer.new()
			hv.add_theme_constant_override("separation", 8)
			var f := float(t["victoires"]) / maxf(1.0, float(t["parties"]))
			var b := _barre(f, UiTokens.SARCELLE, 8.0, 80.0)
			hv.add_child(b)
			hv.add_child(_txt("%d %%" % roundi(100.0 * f), 13, 600, UiTokens.ENCRE, "mono"))
			g.add_child(hv)
		var r := _txt(str(roundi(float(t["record"]))), 14, 600, UiTokens.ENCRE, "mono")
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		g.add_child(r)
	# Courbe
	var pc := _panneau("Réputation finale", _n_dernieres(), Vector2(882, 144), Vector2(358, 236))
	_courbe(pc["corps"], 20)
	# Sources
	var ps := _panneau("D'où vient votre réputation", "toutes parties", Vector2(370, 394), Vector2(498, 206))
	_sources_bloc(ps["corps"])
	# Collection et succès
	var pcs := _panneau("Collection et succès", "", Vector2(882, 394), Vector2(358, 206))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	(pcs["corps"] as MarginContainer).add_child(v)
	for e in [["Espèces installées", _especes_vues().size(), _animaux().size()], ["Collaborateurs recrutés", _persos_vus().size(), _persos().size()],
			["Succès", d["succes"].size(), SUCCES.size()]]:
		var h := HBoxContainer.new()
		var l := _txt(e[0], 13, 600)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(_txt("%d/%d" % [e[1], e[2]], 13, 600, UiTokens.ENCRE, "mono"))
		v.add_child(h)
		var b := _barre(float(e[1]) / maxf(1.0, float(e[2])))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(b)
	var dernier := ""
	var dd := ""
	for s in d["succes"]:
		if str(d["succes"][s]) >= dd:
			dd = str(d["succes"][s])
			dernier = s
	if dernier != "":
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		var et := Composants.Forme.new("etoile", UiTokens.SELECTION, 13.0)
		et.contour = UiTokens.ENCRE
		h.add_child(et)
		h.add_child(_txt("Dernier succès :", 12, 600, UiTokens.TEXTE_2))
		h.add_child(_txt(str(SUCCES.filter(func(x): return x[0] == dernier)[0][1]), 12, 800))
		h.add_child(_txt(", " + _quand(dd), 12, 600, UiTokens.TEXTE_2))
		v.add_child(h)


func _quand(iso: String) -> String:
	return "aujourd'hui" if iso == Time.get_date_string_from_system() else "le " + _date_courte(iso)


func _sources_bloc(parent: Control) -> void:
	var somme := _sources_totales()
	var total := 0.0
	for k in somme:
		total += somme[k]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	parent.add_child(v)
	if total <= 0.0:
		v.add_child(_txt("Aucune réputation gagnée pour l'instant.", 14, 600, UiTokens.TEXTE_2))
		return
	var liste: Array = []
	for s in COULEURS_SOURCES:
		if float(somme.get(s[0], 0.0)) > 0.0:
			liste.append([s[1], s[2], float(somme[s[0]]) / total])
	liste.sort_custom(func(a, b): return a[2] > b[2])
	var barre := Control.new()
	barre.custom_minimum_size.y = 24
	barre.draw.connect(func():
		var x := 0.0
		var f := UiTokens.police_mono(600)
		for e in liste:
			var w: float = barre.size.x * e[2]
			barre.draw_rect(Rect2(Vector2(x, 0), Vector2(w, 24)), e[1])
			if e[2] >= 0.08:
				var t := str(roundi(e[2] * 100.0))
				var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
				barre.draw_string(f, Vector2(x + (w - tw) / 2.0, 16), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
					UiTokens.ENCRE if e[1].get_luminance() > 0.5 else UiTokens.PAPIER)
			barre.draw_line(Vector2(x + w, 0), Vector2(x + w, 24), UiTokens.ENCRE, 1.0)
			x += w
		barre.draw_rect(Rect2(Vector2.ZERO, barre.size), UiTokens.ENCRE, false, 2.0))
	v.add_child(barre)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 24)
	g.add_theme_constant_override("v_separation", 3)
	v.add_child(g)
	for e in liste:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 7)
		h.custom_minimum_size.x = 210
		var cr := Composants.Forme.new("carre", e[1], 10.0)
		cr.contour = UiTokens.ENCRE
		h.add_child(cr)
		var l := _txt(e[0], 12, 600)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(_txt("%d %%" % roundi(e[2] * 100.0), 12, 600, UiTokens.ENCRE, "mono"))
		g.add_child(h)


func _phrase_hubert() -> String:
	var n := _total_parties()
	var vic := int(_total("victoires"))
	if n == 0:
		return "Un dossier vide est un dossier sans faute. Profitez-en, ça ne durera pas."
	if vic == 0:
		return "Aucune victoire, mais beaucoup d'expérience. C'est ce qu'on écrit dans les dossiers qu'on ne relit pas."
	if float(vic) / n >= 0.5:
		return "Votre taux de victoire progresse. Votre salaire, lui, reste un modèle de stabilité."
	return "Une victoire de temps en temps, c'est bien. Toutes les fois, ce serait mieux."


# ---------------------------------------------------------------- Premier lancement

func _page_premiere() -> void:
	_fiche_signaletique(true)
	_bulle_hubert(_phrase_hubert(), Vector2(20, 410), 330)
	Composants.placer(corps, _txt("ÉVALUATION ANNUELLE · AUCUNE DONNÉE", 12, 600, UiTokens.TEXTE_2, "mono"), Vector2(370, 20), Vector2(600, 18))
	Composants.placer(corps, _txt("Votre dossier est encore vierge.", 34, 800, UiTokens.ENCRE, "titre"), Vector2(370, 38), Vector2(860, 40))
	Composants.placer(corps, _txt("Chaque partie le remplit : records, courbes, espèces découvertes, succès. Trois façons de commencer :", 14, 600, UiTokens.TEXTE_2),
		Vector2(370, 84), Vector2(860, 20))
	var missions := [["01", "Suivre le tutoriel", "Hubert vous montre comment recruter, construire et ouvrir votre zoo. 15 minutes.", "COMMENCER ›", "tutoriel", true],
		["02", "Signer une première partie", "Une partie classique contre une IA en Facile. Premier à 120 de réputation.", "Jouer ›", "jouer", false],
		["03", "Tenter le défi de la semaine", "La même partie pour tous. Votre score entre au classement.", "Voir le défi ›", "defi", false]]
	for k in 3:
		var m: Array = missions[k]
		var p := PanelContainer.new()
		var sb := UiTokens.panneau(UiTokens.PAPIER, 10, 2, 0, true)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 14
		sb.content_margin_bottom = 14
		p.add_theme_stylebox_override("panel", sb)
		Composants.placer(corps, p, Vector2(370 + k * 296, 118), Vector2(280, 198))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		p.add_child(v)
		v.add_child(_txt("MISSION " + m[0], 12, 600, UiTokens.TEXTE_2, "mono"))
		var t := _txt(str(m[1]).to_upper(), 21, 800, UiTokens.ENCRE, "titre")
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_theme_constant_override("line_spacing", -4)
		v.add_child(t)
		var l := Composants.paragraphe(m[2], 13, UiTokens.TEXTE_2)
		v.add_child(l)
		var esp := Control.new()
		esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(esp)
		var b := Composants.bouton(m[3], "BoutonPrincipal" if m[5] else "BoutonMini")
		if m[5]:
			b.add_theme_font_override("font", UiTokens.police_titre())
			b.add_theme_font_size_override("font_size", 15)
		b.custom_minimum_size.y = 34
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var nom: String = m[4]
		b.pressed.connect(func():
			mission.emit(nom)
			queue_free())
		v.add_child(b)
	var pc := _panneau("Collection à découvrir", "0 / %d" % _animaux().size(), Vector2(370, 330), Vector2(498, 270))
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 10)
	(pc["corps"] as MarginContainer).add_child(cv)
	var grille := GridContainer.new()
	grille.columns = 5
	grille.add_theme_constant_override("h_separation", 14)
	grille.add_theme_constant_override("v_separation", 10)
	grille.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cv.add_child(grille)
	for a in _animaux().slice(0, 10):
		grille.add_child(_tuile_espece(a, false, false))
	var l2 := _txt("%d espèces sur 4 continents. Chaque espèce installée apparaît ici." % _animaux().size(), 13, 600)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(l2)
	var psu := _panneau("Succès à obtenir", "0 / %d" % SUCCES.size(), Vector2(882, 330), Vector2(358, 270))
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	(psu["corps"] as MarginContainer).add_child(sv)
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 22)
	sh.alignment = BoxContainer.ALIGNMENT_CENTER
	sv.add_child(sh)
	for s in SUCCES.slice(0, 3):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		var md := Medaille.new(CODES_SUCCES.get(s[0], "?"), false, 62.0)
		md.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(md)
		var n := _txt(s[1], 12, 600)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.custom_minimum_size.x = 86
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(n)
		sh.add_child(col)
	var l3 := Composants.paragraphe("+ %d autres, jusqu'à Arche de ZooLife : installer les %d espèces." % [SUCCES.size() - 3, _animaux().size()], 12, UiTokens.ENCRE)
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sv.add_child(l3)


# ---------------------------------------------------------------- Parties

func _page_parties() -> void:
	var debut := str(d.get("debut", ""))
	var pm := _panneau("Par mode de jeu", "%d parties%s" % [_total_parties(), (" depuis le " + _date_courte(debut, true)) if debut != "" else ""],
		Vector2(20, 20), Vector2(1220, 228))
	var g := GridContainer.new()
	g.columns = 8
	g.add_theme_constant_override("h_separation", 0)
	g.add_theme_constant_override("v_separation", 0)
	(pm["corps"] as MarginContainer).add_child(g)
	var cols := [["MODE", 250], ["PARTIES", 80], ["VICTOIRES", 130], ["TAUX", 90], ["LA PLUS RAPIDE", 190], ["RECORD", 110], ["MOYENNE", 110], ["OUVERTURE DU ZOO", 230]]
	for k in cols.size():
		var l := _txt(cols[k][0], 12, 800, UiTokens.TEXTE_2, "titre")
		l.custom_minimum_size = Vector2(cols[k][1], 24)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if k == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		g.add_child(l)
	for m in FORMES_MODES:
		var t: Dictionary = d["totaux"].get(m[0], {})
		if t.is_empty():
			continue
		var nom := HBoxContainer.new()
		nom.add_theme_constant_override("separation", 8)
		nom.custom_minimum_size = Vector2(250, 30)
		nom.add_child(_forme_mode(m[0]))
		nom.add_child(_txt(m[1], 14, 700))
		g.add_child(nom)
		var nb := int(t["parties"])
		var cozy: bool = m[0] == "cozy"
		var ps: Array = d["parties"].filter(func(p): return p["mode"] == m[0] and int(p.get("ouverture", 0)) > 0)
		var ouv := "—"
		if not ps.is_empty():
			var moi: float = ps.reduce(func(s, p): return s + float(p["ouverture"]), 0.0) / ps.size()
			var ia: Array = ps.filter(func(p): return float(p.get("ouverture_ia", 0.0)) > 0.0)
			ouv = "jour %s · IA %s" % [_virgule(moi), _virgule(ia.reduce(func(s, p): return s + float(p["ouverture_ia"]), 0.0) / ia.size()) if not ia.is_empty() else "—"]
		var vals := [str(nb), "—" if cozy else str(int(t["victoires"])), "—" if cozy else "%d %%" % roundi(100.0 * int(t["victoires"]) / maxf(1, nb)),
			"jour %d" % int(t["meilleur_jour"]) if int(t["meilleur_jour"]) > 0 else "—", str(roundi(float(t["record"]))),
			str(roundi(float(t["rep_totale"]) / maxf(1, nb))), ouv]
		for k in vals.size():
			var l := _txt(vals[k], 14, 600, UiTokens.ENCRE, "mono")
			l.custom_minimum_size.x = cols[k + 1][1]
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			g.add_child(l)
	var pc := _panneau("Réputation finale, partie après partie", _n_dernieres(), Vector2(20, 268), Vector2(558, 332))
	_courbe(pc["corps"], 20)
	var dernieres: Array = d["parties"].slice(-20)
	dernieres.reverse()
	var pd := _panneau("Dernières parties", "%d sur %d · défiler" % [mini(8, dernieres.size()), dernieres.size()], Vector2(598, 268), Vector2(642, 332))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	(pd["corps"] as MarginContainer).add_child(v)
	var cols2 := [["DATE", 80], ["MODE", 150], ["RANG", 90], ["FIN", 70], ["RÉPUTATION", 110], ["ANIMAUX", 100]]
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 0)
	v.add_child(tete)
	for k in cols2.size():
		var l := _txt(cols2[k][0], 12, 800, UiTokens.TEXTE_2, "titre")
		l.custom_minimum_size = Vector2(cols2[k][1], 22)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if k < 2 else HORIZONTAL_ALIGNMENT_RIGHT
		tete.add_child(l)
	var filet := ColorRect.new()
	filet.color = UiTokens.ENCRE
	filet.custom_minimum_size.y = 2
	v.add_child(filet)
	var defile := ScrollContainer.new()
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(defile)
	var lignes := VBoxContainer.new()
	lignes.add_theme_constant_override("separation", 0)
	defile.add_child(lignes)
	for k in dernieres.size():
		var p: Dictionary = dernieres[k]
		var ligne := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiTokens.JAUNE_CLAIR if k == 0 else Color(0, 0, 0, 0)
		sb.border_color = UiTokens.FILET
		sb.border_width_bottom = 1
		ligne.add_theme_stylebox_override("panel", sb)
		ligne.custom_minimum_size.y = 30
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 0)
		ligne.add_child(h)
		var date := _txt(_date_courte(str(p["date"])), 14, 600, UiTokens.ENCRE, "mono")
		date.custom_minimum_size.x = cols2[0][1]
		h.add_child(date)
		var mode := HBoxContainer.new()
		mode.add_theme_constant_override("separation", 6)
		mode.custom_minimum_size.x = cols2[1][1]
		var cle := str(p["mode"])
		mode.add_child(_forme_mode(cle))
		mode.add_child(_txt({"course": "Classique", "nature": "Réserve", "cozy": "Libre", "defi": "Défi", "multi": "Multi"}.get(cle, cle), 14, 600))
		h.add_child(mode)
		var gagne := int(p.get("rang", 0)) == 1 and cle != "cozy"
		var vals := ["—" if cle == "cozy" else "%s / %d" % [Composants.rang_texte(int(p["rang"])), int(p["joueurs"])], "j%d" % int(p["jour"]),
			str(roundi(float(p["rep"]))), str(p.get("especes", []).size())]
		for j in vals.size():
			var l := _txt(vals[j], 14, 700 if j == 0 and gagne else 600, UiTokens.POSITIF if j == 0 and gagne else UiTokens.ENCRE, "mono")
			l.custom_minimum_size.x = cols2[j + 2][1]
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			h.add_child(l)
		lignes.add_child(ligne)
	if dernieres.is_empty():
		lignes.add_child(_txt("Aucune partie terminée.", 14, 600, UiTokens.TEXTE_2))


# ---------------------------------------------------------------- Collection

func _tuile_espece(a: Dictionary, vue: bool, rarete := true) -> Control:
	var t := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("FFF7E0") if vue else UiTokens.FOND_FENETRE
	sb.set_corner_radius_all(6)
	sb.anti_aliasing = true
	if vue:
		sb.border_color = UiTokens.ENCRE
		sb.set_border_width_all(2)
		sb.shadow_color = UiTokens.ENCRE
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(0, 2)
	sb.set_content_margin_all(3)
	t.add_theme_stylebox_override("panel", sb)
	t.custom_minimum_size = Vector2(50, 50)
	var id := str(a["id"])
	var im := TextureRect.new()
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	im.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	im.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if vue:
		im.texture = SpritesBD.texture(id + "_tete") if SpritesBD.existe(id + "_tete") else SpritesBD.texture(id)
	else:
		# Silhouette : le corps de l'animal (les têtes ont un fond carré), teinté en gris
		im.texture = SpritesBD.texture(id)
		im.modulate = Color(0, 0, 0, 0.22)
	t.add_child(im)
	if not vue:
		var c := Composants.CadreTirets.new()
		c.couleur = UiTokens.POINTILLES
		c.rayon = 6
		t.add_child(c)
	var r: Array = RARETES.get(str(a.get("palier", "T1")), RARETES["T1"])
	if rarete:
		var f := Composants.Forme.new(r[0], r[1], 12.0 if r[0] == "etoile" else 11.0)
		f.contour = UiTokens.ENCRE if r[0] != "etoile" else Color.TRANSPARENT
		var coin := Control.new()
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(coin)
		coin.add_child(f)
		f.position = Vector2(40, -6)
		f.size = f.custom_minimum_size
	var nom := str(a.get("nom", id))
	var tip := "%s · %s" % [nom, r[2]]
	if vue:
		var e = d.get("especes_date", {}).get(id, "")
		tip += "\n%s · installé %d fois%s" % [str(_donnees_jeu["animals"]["continents"].get(a.get("continent", ""), "")), int(d["especes"][id]),
			(" · dernière le " + _date_courte(str(e))) if str(e) != "" else ""]
	else:
		tip += "\npas encore installée"
	t.tooltip_text = tip
	t.mouse_filter = Control.MOUSE_FILTER_STOP
	return t


func _page_collection() -> void:
	var vues := _especes_vues()
	var pe := _panneau("Espèces installées au moins une fois", "%d / %d" % [vues.size(), _animaux().size()], Vector2(20, 20), Vector2(1220, 282))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	(pe["corps"] as MarginContainer).add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 26)
	v.add_child(h)
	for c in CONTINENTS:
		var liste := _animaux().filter(func(a): return a.get("continent", "") == c[0])
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		col.custom_minimum_size.x = 278
		h.add_child(col)
		var tete := HBoxContainer.new()
		var nl := _txt(str(c[1]).to_upper(), 17, 800, UiTokens.ENCRE, "titre")
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tete.add_child(nl)
		tete.add_child(_txt("%d/%d" % [liste.filter(func(a): return d["especes"].has(str(a["id"]))).size(), liste.size()], 13, 600, UiTokens.ENCRE, "mono"))
		col.add_child(tete)
		var filet := ColorRect.new()
		filet.color = UiTokens.ENCRE
		filet.custom_minimum_size.y = 2
		col.add_child(filet)
		col.add_child(_espace(4))
		var g := GridContainer.new()
		g.columns = 5
		g.add_theme_constant_override("h_separation", 7)
		g.add_theme_constant_override("v_separation", 8)
		col.add_child(g)
		for a in liste:
			g.add_child(_tuile_espece(a, d["especes"].has(str(a["id"]))))
	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(esp)
	var leg := HBoxContainer.new()
	leg.add_theme_constant_override("separation", 8)
	v.add_child(leg)
	for k in ["T1", "T2", "T3"]:
		var r: Array = RARETES[k]
		var f := Composants.Forme.new(r[0], r[1], 11.0)
		f.contour = UiTokens.ENCRE if r[0] != "etoile" else Color.TRANSPARENT
		leg.add_child(f)
		leg.add_child(_txt(r[2] + "   ", 12, 600))
	var cr := Composants.Forme.new("carre", UiTokens.FOND_FENETRE, 10.0)
	cr.contour = UiTokens.POINTILLES
	leg.add_child(cr)
	leg.add_child(_txt("pas encore installée (silhouette)", 12, 600))
	# Collaborateurs
	var persos := _persos()
	var pp := _panneau("Collaborateurs recrutés", "%d / %d" % [_persos_vus().size(), persos.size()], Vector2(20, 322), Vector2(1220, 278))
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	(pp["corps"] as MarginContainer).add_child(pv)
	var g2 := GridContainer.new()
	g2.columns = 20
	g2.add_theme_constant_override("h_separation", 6)
	g2.add_theme_constant_override("v_separation", 14)
	pv.add_child(g2)
	for p in persos:
		g2.add_child(_tuile_perso(p))
	var esp2 := Control.new()
	esp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv.add_child(esp2)
	pv.add_child(_txt("Survol : nom, plus haut niveau atteint, nombre de parties dans votre équipe.", 12, 600, UiTokens.TEXTE_2))


func _tuile_perso(p: Dictionary) -> Control:
	var id := str(p["id"])
	var vu: bool = d["persos"].has(id)
	var t := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("FFF7E0") if vu else UiTokens.FOND_FENETRE
	sb.set_corner_radius_all(6)
	sb.anti_aliasing = true
	if vu:
		sb.border_color = UiTokens.ENCRE
		sb.set_border_width_all(2)
	sb.set_content_margin_all(2)
	t.add_theme_stylebox_override("panel", sb)
	t.custom_minimum_size = Vector2(52, 66)
	var im := TextureRect.new()
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	im.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	im.mouse_filter = Control.MOUSE_FILTER_IGNORE
	im.texture = Composants.texture_portrait(id)
	if not vu:
		im.modulate = Color(0, 0, 0, 0.22)
	t.add_child(im)
	if not vu:
		var c := Composants.CadreTirets.new()
		c.couleur = UiTokens.POINTILLES
		c.rayon = 6
		t.add_child(c)
	var nom := str(p.get("nom", id))
	t.tooltip_text = ("%s\nniveau max %d · %d partie%s dans votre équipe" % [nom, int(d.get("persos_niveau", {}).get(id, 1)), int(d["persos"][id]),
		"s" if int(d["persos"][id]) > 1 else ""]) if vu else ("%s\npas encore recruté" % nom)
	t.mouse_filter = Control.MOUSE_FILTER_STOP
	return t


# ---------------------------------------------------------------- Succès

## Progression d'un succès qui se compte : [valeur, but, libellé], ou [].
func _progression(id: String) -> Array:
	match id:
		"collection_10":
			return [_especes_vues().size(), 10, "espèces"]
		"collection_toutes":
			return [_especes_vues().size(), _animaux().size(), "espèces"]
		"legende":
			return [int(d.get("niveau_max", 1)), 6, "niveau max atteint"]
		"defi_100":
			var m := 0.0
			for k in d["defis"]:
				m = maxf(m, float(d["defis"][k].get("meilleur", 0.0)))
			return [roundi(m), 100, "meilleur défi"]
	return []


func _page_succes() -> void:
	var n: int = d["succes"].size()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	Composants.placer(corps, h, Vector2(20, 18), Vector2(1220, 30))
	h.add_child(_txt("%d SUCCÈS SUR %d" % [n, SUCCES.size()], 22, 800, UiTokens.ENCRE, "titre"))
	var b := _barre(float(n) / SUCCES.size(), UiTokens.SARCELLE, 10.0, 300.0)
	h.add_child(b)
	var l := _txt("Les succès obtenus sont pleins et cochés ; les autres sont en pointillé, avec leur condition.", 12, 600, UiTokens.TEXTE_2)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	var plus_proche := ""
	var meilleur := -1.0
	for k in SUCCES.size():
		var s: Array = SUCCES[k]
		var obtenu: bool = d["succes"].has(s[0])
		var pos := Vector2(20 + (k % 4) * 309, 58 + (k / 4) * 162)
		var carte := PanelContainer.new()
		var sb := UiTokens.panneau(UiTokens.PAPIER if obtenu else UiTokens.FOND_FENETRE, 10, 2 if obtenu else 0, 0, obtenu)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 14
		sb.content_margin_bottom = 12
		carte.add_theme_stylebox_override("panel", sb)
		Composants.placer(corps, carte, pos, Vector2(294, 146))
		if not obtenu:
			# Le cadre en tirets couvre toute la carte : posé à côté d'elle, pas dans ses marges
			var c := Composants.CadreTirets.new()
			c.couleur = UiTokens.POINTILLES
			c.rayon = 10
			var env := Control.new()
			env.mouse_filter = Control.MOUSE_FILTER_IGNORE
			Composants.placer(corps, env, pos, Vector2(294, 146))
			env.add_child(c)
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 12)
		carte.add_child(hh)
		var md := Medaille.new(CODES_SUCCES.get(s[0], "?"), obtenu, 62.0)
		md.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		hh.add_child(md)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hh.add_child(v)
		v.add_child(_txt(str(s[1]).to_upper(), 18, 800, UiTokens.ENCRE, "titre"))
		var cond := Composants.paragraphe(s[2], 12, UiTokens.ENCRE if obtenu else UiTokens.TEXTE_2)
		v.add_child(cond)
		if obtenu:
			v.add_child(_txt("✓ obtenu le " + _date_courte(str(d["succes"][s[0]])), 12, 700, UiTokens.POSITIF))
		else:
			var pr := _progression(s[0])
			if pr.is_empty():
				v.add_child(_txt("Pas encore obtenu", 12, 700))
			else:
				v.add_child(_txt("%s : %d/%d" % [pr[2], pr[0], pr[1]], 12, 700, UiTokens.ENCRE, "mono"))
				var pb := _barre(float(pr[0]) / maxf(1.0, float(pr[1])), UiTokens.MARINE_2, 8.0)
				pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				v.add_child(pb)
				var f := float(pr[0]) / maxf(1.0, float(pr[1]))
				if f > meilleur and f < 1.0:
					meilleur = f
					plus_proche = s[1]
	var phrase := "Douze succès, et le comité les compte tous. Commencez par le plus facile : gagner."
	if n == SUCCES.size():
		phrase = "Tous les succès. Le comité vous propose une médaille de plus : celle de la modestie."
	elif plus_proche != "":
		phrase = "Le plus proche : %s. Vous y êtes presque. Moi aussi, d'ailleurs, à ma promotion." % plus_proche
	_bulle_hubert(phrase, Vector2(20, 548), 660, false)


# ---------------------------------------------------------------- données fictives (captures)

func _demo() -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = 42
	var out := {"pseudo": str(donnees.get("pseudo", "Daniel")) if str(donnees.get("pseudo", "")) != "" else "Daniel", "debut": "2026-09-14",
		"parties": [], "totaux": {}, "especes": {}, "especes_date": {}, "persos": {}, "persos_niveau": {}, "defis": {}, "succes": {}, "niveau_max": 5}
	var modes := ["course", "course", "nature", "defi", "course", "cozy", "multi", "nature", "course", "defi"]
	for k in 52:
		var m: String = modes[k % modes.size()]
		var gagne := m != "cozy" and r.randf() < 0.55
		var rep := r.randf_range(98.0, 165.0) if gagne else r.randf_range(80.0, 119.0)
		var p := {"date": "2026-%02d-%02d" % [9 + k / 20, 1 + k % 28], "mode": m, "defi": "saules" if m == "defi" else "", "jour": r.randi_range(9, 14),
			"rep": snappedf(rep, 0.1), "rang": 1 if gagne else r.randi_range(2, 4), "joueurs": 4, "gagne": gagne, "ouverture": r.randi_range(4, 7),
			"ouverture_ia": snappedf(r.randf_range(5.5, 6.8), 0.1), "especes": ["lion", "zebre", "girafe"].slice(0, r.randi_range(1, 3)),
			"sources": {"frequentation": 41.0, "spectacles": 15.0, "boutique": 11.0, "objectifs": 10.0, "beaute": 8.0, "labels": 7.0, "prestige": 5.0, "legendaires": 3.0}}
		out["parties"].append(p)
		var t: Dictionary = out["totaux"].get(m, {"parties": 0, "victoires": 0, "meilleur_jour": 0, "record": 0.0, "rep_totale": 0.0})
		t["parties"] += 1
		t["rep_totale"] += rep
		t["record"] = maxf(t["record"], rep)
		if gagne:
			t["victoires"] += 1
			if t["meilleur_jour"] == 0 or p["jour"] < t["meilleur_jour"]:
				t["meilleur_jour"] = p["jour"]
		out["totaux"][m] = t
	var animaux := _animaux()
	for k in animaux.size():
		if r.randf() < 0.68:
			out["especes"][str(animaux[k]["id"])] = r.randi_range(1, 4)
			out["especes_date"][str(animaux[k]["id"])] = "2026-10-%02d" % r.randi_range(1, 30)
	for p in _persos():
		if r.randf() < 0.78:
			out["persos"][str(p["id"])] = r.randi_range(1, 6)
			out["persos_niveau"][str(p["id"])] = r.randi_range(1, 5)
	for k in 9:
		out["succes"][SUCCES[[0, 1, 2, 3, 5, 6, 7, 8, 9][k]][0]] = "2026-%02d-%02d" % [9 + k / 4, 5 + k * 3]
	out["succes"]["defi_100"] = Time.get_date_string_from_system()
	return out
