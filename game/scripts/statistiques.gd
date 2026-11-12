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
	donnees = {"pseudo": "", "parties": [], "totaux": {}, "especes": {}, "persos": {}, "defis": {}, "succes": {}}
	if FileAccess.file_exists(FICHIER):
		var d = JSON.parse_string(FileAccess.get_file_as_string(FICHIER))
		if d is Dictionary:
			for k in d:
				donnees[k] = d[k]


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
	for e in especes:
		donnees["especes"][e] = int(donnees["especes"].get(e, 0)) + 1
	for c in p.all_employees():
		if str(c.perso) != "":
			donnees["persos"][str(c.perso)] = int(donnees["persos"].get(str(c.perso), 0)) + 1
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

var _donnees_jeu := {}


func _init(donnees_jeu := {}) -> void:
	_donnees_jeu = donnees_jeu if not donnees_jeu.is_empty() else GameData.load_all()


func _ready() -> void:
	charger()
	theme = UiTokens.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var f := Composants.fenetre(Vector2(980, 0), "Dossier personnel", "Statistiques", queue_free)
	add_child(f["racine"])
	var corps: VBoxContainer = f["corps"]
	var defile := ScrollContainer.new()
	defile.custom_minimum_size = Vector2(940, 620)
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corps.add_child(defile)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defile.add_child(v)
	_profil(v)
	_par_mode(v)
	_defis(v)
	_dernieres(v)
	_sources(v)
	_collection(v)
	_succes(v)


func _texte(t: String, taille := 14, couleur := UiTokens.ENCRE, graisse := 600) -> Label:
	var l := Composants.label(t)
	l.add_theme_font_override("font", UiTokens.police_corps(graisse))
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l


func _profil(v: VBoxContainer) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	h.add_child(_texte("Pseudo :", 15, UiTokens.TEXTE_2))
	var champ := LineEdit.new()
	champ.text = pseudo()
	champ.max_length = 16
	champ.custom_minimum_size.x = 220
	h.add_child(champ)
	var ok := Composants.bouton("Modifier", "BoutonSecondaire")
	h.add_child(ok)
	var msg := _texte("", 13, UiTokens.TEXTE_2)
	h.add_child(msg)
	ok.pressed.connect(func():
		var e := erreur_pseudo(champ.text)
		if e == "":
			changer_pseudo(champ.text)
			msg.text = "Pseudo enregistré."
		else:
			msg.text = e)
	var n: int = donnees["parties"].size()
	var total := 0
	for k in donnees["totaux"]:
		total += int(donnees["totaux"][k]["parties"])
	h.add_child(_texte("  ·  %d partie%s jouée%s" % [total, "s" if total > 1 else "", "s" if total > 1 else ""], 14, UiTokens.TEXTE_2))
	if n == 0:
		v.add_child(_texte("Aucune partie terminée pour l'instant : les statistiques se rempliront à la fin de chaque partie.", 14, UiTokens.TEXTE_2, 500))


## Un tableau : une ligne d'en-tête puis les lignes, colonnes de largeur fixe.
func _tableau(v: VBoxContainer, entetes: Array, lignes: Array, largeurs: Array) -> void:
	var g := GridContainer.new()
	g.columns = entetes.size()
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 4)
	v.add_child(g)
	for k in entetes.size():
		var l := _texte(entetes[k], 12, UiTokens.TEXTE_2, 700)
		l.custom_minimum_size.x = largeurs[k]
		g.add_child(l)
	for ligne in lignes:
		for k in ligne.size():
			var l := _texte(str(ligne[k]), 14, UiTokens.ENCRE, 700 if k == 0 else 500)
			l.custom_minimum_size.x = largeurs[k]
			g.add_child(l)


func _par_mode(v: VBoxContainer) -> void:
	v.add_child(Composants.titre_section("Par mode de jeu"))
	var lignes: Array = []
	for m in MODES:
		var t: Dictionary = donnees["totaux"].get(m[0], {})
		if t.is_empty():
			continue
		var parties: Array = donnees["parties"].filter(func(p): return p["mode"] == m[0] and int(p["ouverture"]) > 0)
		var ouv := "—"
		if not parties.is_empty():
			var moi: float = parties.reduce(func(s, p): return s + float(p["ouverture"]), 0.0) / parties.size()
			var ia_l := parties.filter(func(p): return float(p["ouverture_ia"]) > 0.0)
			ouv = "jour %.1f" % moi
			if not ia_l.is_empty():
				ouv += " (IA : %.1f)" % (ia_l.reduce(func(s, p): return s + float(p["ouverture_ia"]), 0.0) / ia_l.size())
		var nb := int(t["parties"])
		lignes.append([m[1], nb, "%d (%d %%)" % [int(t["victoires"]), roundi(100.0 * int(t["victoires"]) / maxf(1, nb))] if m[0] != "cozy" else "—",
			"jour %d" % int(t["meilleur_jour"]) if int(t["meilleur_jour"]) > 0 else "—", roundi(float(t["record"])),
			roundi(float(t["rep_totale"]) / maxf(1, nb)), ouv])
	if lignes.is_empty():
		v.add_child(_texte("—", 14, UiTokens.TEXTE_2))
		return
	_tableau(v, ["MODE", "PARTIES", "VICTOIRES", "VICTOIRE LA PLUS RAPIDE", "RÉPUTATION RECORD", "MOYENNE", "OUVERTURE DU ZOO"], lignes,
		[170, 70, 100, 170, 140, 80, 170])


func _defis(v: VBoxContainer) -> void:
	v.add_child(Composants.titre_section("Défis"))
	var lignes: Array = []
	for d in Defis.liste():
		var s: Dictionary = donnees["defis"].get(d["id"], {})
		lignes.append([d["nom"], Defis.libelle_mode(d["mode"]), int(s.get("parties", 0)),
			roundi(float(s["meilleur"])) if not s.is_empty() else "—", "voir la fenêtre Défis"])
	_tableau(v, ["DÉFI", "MODE", "PARTIES", "MEILLEUR SCORE", "CLASSEMENT"], lignes, [260, 170, 80, 130, 240])


func _dernieres(v: VBoxContainer) -> void:
	var parties: Array = donnees["parties"].slice(-20)
	if parties.is_empty():
		return
	v.add_child(Composants.titre_section("Dernières parties (réputation finale)"))
	var c := Courbe.new()
	c.valeurs = parties.map(func(p): return float(p["rep"]))
	c.gagnees = parties.map(func(p): return bool(p["gagne"]))
	c.custom_minimum_size = Vector2(900, 130)
	v.add_child(c)
	var lignes: Array = []
	for p in parties.slice(-5):
		var nom := ""
		for m in MODES:
			if m[0] == p["mode"]:
				nom = m[1]
		lignes.append([p["date"], nom, "%de / %d" % [int(p["rang"]), int(p["joueurs"])], "jour %d" % int(p["jour"]), roundi(float(p["rep"])),
			"%d animal%s" % [p["especes"].size(), "" if p["especes"].size() <= 1 else "aux"]])
	lignes.reverse()
	_tableau(v, ["DATE", "MODE", "RANG", "FIN", "RÉPUTATION", "ZOO"], lignes, [120, 170, 90, 90, 110, 120])


func _sources(v: VBoxContainer) -> void:
	var somme := {}
	var total := 0.0
	for p in donnees["parties"]:
		for k in p["sources"]:
			somme[k] = float(somme.get(k, 0.0)) + float(p["sources"][k])
			total += float(p["sources"][k])
	if total <= 0.0:
		return
	v.add_child(Composants.titre_section("D'où vient votre réputation"))
	var cles := somme.keys()
	cles.sort_custom(func(a, b): return somme[a] > somme[b])
	for k in cles:
		if somme[k] <= 0.0:
			continue
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		v.add_child(h)
		var l := _texte(SOURCES.get(k, str(k).capitalize()), 14)
		l.custom_minimum_size.x = 170
		h.add_child(l)
		var barre := ColorRect.new()
		barre.color = UiTokens.SARCELLE
		barre.custom_minimum_size = Vector2(maxf(2.0, 560.0 * somme[k] / total), 14)
		barre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(barre)
		h.add_child(_texte("%d %%" % roundi(100.0 * somme[k] / total), 13, UiTokens.TEXTE_2))


## Une pastille par espèce ou personnage, grisée s'il n'est jamais sorti.
func _pastilles(v: VBoxContainer, liste: Array, vus: Dictionary) -> void:
	var flux := HFlowContainer.new()
	flux.add_theme_constant_override("h_separation", 6)
	flux.add_theme_constant_override("v_separation", 6)
	v.add_child(flux)
	for e in liste:
		var vu := vus.has(str(e["id"]))
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(UiTokens.SELECTION, 0.85) if vu else Color(UiTokens.FILET, 0.35)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		p.add_theme_stylebox_override("panel", sb)
		p.add_child(_texte(str(e["nom"]), 13, UiTokens.ENCRE if vu else UiTokens.TEXTE_2, 600 if vu else 500))
		if vu:
			p.tooltip_text = "%d fois" % int(vus[str(e["id"])])
		flux.add_child(p)


func _collection(v: VBoxContainer) -> void:
	var animaux: Array = _donnees_jeu["animals"]["animaux"]
	v.add_child(Composants.titre_section("Collection · espèces installées : %d / %d" % [donnees["especes"].size(), animaux.size()]))
	_pastilles(v, animaux, donnees["especes"])
	var persos: Array = _donnees_jeu["personnages"]["personnages"]
	v.add_child(Composants.titre_section("Collaborateurs recrutés : %d / %d" % [donnees["persos"].keys().filter(func(k): return persos.any(func(p): return str(p["id"]) == k)).size(), persos.size()]))
	_pastilles(v, persos, donnees["persos"])


func _succes(v: VBoxContainer) -> void:
	v.add_child(Composants.titre_section("Succès : %d / %d" % [donnees["succes"].size(), SUCCES.size()]))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 24)
	g.add_theme_constant_override("v_separation", 6)
	v.add_child(g)
	for s in SUCCES:
		var obtenu: bool = donnees["succes"].has(s[0])
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.custom_minimum_size.x = 440
		h.add_child(_texte("✓" if obtenu else "·", 16, UiTokens.SARCELLE if obtenu else UiTokens.TEXTE_2, 800))
		var t := _texte("%s · %s%s" % [s[1], s[2], ("  (" + str(donnees["succes"][s[0]]) + ")") if obtenu else ""], 13,
			UiTokens.ENCRE if obtenu else UiTokens.TEXTE_2, 600 if obtenu else 500)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		g.add_child(h)


## Réputation finale des dernières parties : un point par partie, plein si elle est gagnée.
class Courbe extends Control:
	var valeurs: Array = []
	var gagnees: Array = []

	func _draw() -> void:
		if valeurs.is_empty():
			return
		var maxi := 1.0
		for x in valeurs:
			maxi = maxf(maxi, x)
		var f := UiTokens.police_corps(600)
		var g := 40.0
		var w := size.x - g - 10.0
		var h := size.y - 20.0
		draw_line(Vector2(g, h + 6), Vector2(g + w, h + 6), UiTokens.FILET, 1.0)
		draw_string(f, Vector2(0, 12), str(roundi(maxi)), HORIZONTAL_ALIGNMENT_RIGHT, g - 8, 11, UiTokens.TEXTE_2)
		draw_string(f, Vector2(0, h + 10), "0", HORIZONTAL_ALIGNMENT_RIGHT, g - 8, 11, UiTokens.TEXTE_2)
		var pts := PackedVector2Array()
		for k in valeurs.size():
			var x := g + (w * k / maxf(1.0, valeurs.size() - 1.0) if valeurs.size() > 1 else w / 2.0)
			pts.append(Vector2(x, 6.0 + h * (1.0 - float(valeurs[k]) / maxi)))
		if pts.size() > 1:
			draw_polyline(pts, UiTokens.SARCELLE, 2.0, true)
		for k in pts.size():
			if gagnees[k]:
				draw_circle(pts[k], 5.0, UiTokens.SELECTION)
			draw_arc(pts[k], 5.0, 0, TAU, 16, UiTokens.ENCRE, 1.5, true)
