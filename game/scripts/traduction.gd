class_name Traduction
extends Translation
## Version anglaise (18/11/2026). Le jeu est écrit en français ; cette traduction reconnaît les textes français au moment de
## les afficher et rend leur version anglaise, sans toucher au code qui les fabrique :
## - les contrôles (Label, Button, infobulles, RichTextLabel…) passent seuls par TranslationServer (traduction automatique
##   de Godot) ; les textes dessinés (draw_string) passent par Traduction.t() ;
## - correspondance exacte d'abord (table fr → en de res://lang/en.json), puis gabarits : un texte du code qui contient
##   %d, %s, %.1f ou {nom} devient une expression régulière, et ce qui remplit un %s est lui-même traduit ;
## - à défaut, le texte est coupé aux séparateurs (« · », « — », retours à la ligne) et chaque morceau est traduit.
## La table se complète avec tools/traduction_extraire.py (textes nouveaux du code et des données) ; ce qui n'y est pas
## reste en français. Rien de la partie ne dépend de la langue : seul l'affichage change.

const FICHIER := "res://lang/en.json"
const LANGUES := {"fr": "Français", "en": "English"}

static var langue := "fr"
static var instance: Traduction

var exact := {}             # texte français → texte anglais (majuscules comprises)
var _gabarits := {}         # trois premières lettres (minuscules) → [[RegEx, anglais, [types]], …]
var _gabarits_ouverts := [] # gabarits qui commencent par une variable
var _cache := {}
var _re_variable := RegEx.create_from_string("%[-+0#]*\\d*(?:\\.\\d+)?[dsfi]|\\{[a-z_0-9]+\\}")
var _re_coupe := RegEx.create_from_string("( · | — | – |\\n)")
var _re_coupe_faible := RegEx.create_from_string("(, | ; )")
var _re_lettre := RegEx.create_from_string("\\p{L}")
var _re_balises := RegEx.create_from_string("^((?:\\[[^\\]/][^\\]]*\\])+)(.*?)((?:\\[/[^\\]]*\\])+)$")
var _re_tete := RegEx.create_from_string("^[^\\p{L}\\p{N}\\[\"'(+\\-−]+")
var _re_queue := RegEx.create_from_string("(?:\\s*(?:[^\\p{L}\\p{N}\\]\"'.!?)%\\s]+|[×x+\\-−]?\\d+(?:[.,]\\d+)*(?:\\s?%)?))+$")
var _re_virgule := RegEx.create_from_string("(\\d),(\\d)")
var _partiels := []          # gabarits cherchés au milieu d'un texte : [RegEx, anglais, types, longueur]


## Langue enregistrée dans les réglages, sinon celle du système (français si le système est en français, anglais sinon).
static func langue_par_defaut() -> String:
	return "fr" if OS.get_locale_language() == "fr" else "en"


## Active une langue pour tout le jeu (appelé au démarrage et par les Réglages).
static func choisir(code: String) -> void:
	langue = code if LANGUES.has(code) else "fr"
	if langue == "en" and instance == null:
		instance = Traduction.new()
		TranslationServer.add_translation(instance)
	TranslationServer.set_locale(langue)


## À la fermeture : une traduction écrite en GDScript encore enregistrée quand Godot détruit les scripts fait planter
## le jeu en quittant (main.gd l'appelle dans _exit_tree).
static func retirer() -> void:
	if instance != null:
		TranslationServer.remove_translation(instance)
		instance = null


## Pour les textes dessinés à la main (draw_string) et ceux qui ne passent pas par un contrôle.
static func t(texte: String) -> String:
	if langue != "en" or instance == null:
		return texte
	return instance.traduire(texte)


func _init() -> void:
	locale = "en"
	var donnees = JSON.parse_string(FileAccess.get_file_as_string(FICHIER)) if FileAccess.file_exists(FICHIER) else null
	if not donnees is Dictionary:
		return
	for fr: String in donnees:
		var en := str(donnees[fr])
		if en == "":
			continue
		var formes := [[fr, en]]
		if fr.strip_edges() != fr:  # « Métier : %s (%s). » : aussi sans l'espace du bout, ôtée avant la recherche
			formes.append([fr.strip_edges(), en.strip_edges()])
		for f in formes.duplicate():
			var maj := _majuscules(f[0])
			if maj != f[0]:  # titres passés par to_upper()
				formes.append([maj, _majuscules(f[1])])
		for f in formes:
			if _re_variable.search(f[0]) != null:
				_ajouter_gabarit(f[0], f[1])
			elif not exact.has(f[0]) or f[0] == fr:
				exact[f[0]] = f[1]
	# Le gabarit le plus précis d'abord (« Vendre %d · +%d » avant « Vendre %s »)
	var precis := func(a, b): return a[3] > b[3]
	for cle in _gabarits:
		_gabarits[cle].sort_custom(precis)
	_gabarits_ouverts.sort_custom(precis)


func _get_message(src_message: StringName, _context: StringName) -> StringName:
	return StringName(traduire(String(src_message)))


func traduire(texte: String, profondeur := 0) -> String:
	if texte.length() < 2 or profondeur > 6:
		return texte
	if _cache.has(texte):
		return _cache[texte]
	var en := _traduire(texte, profondeur)
	if profondeur == 0 and en != texte:
		en = _re_virgule.sub(en, "$1.$2", true)  # 1,5 → 1.5
		en = en.replace("« ", "“").replace(" »", "”").replace("«", "“").replace("»", "”")
	if _cache.size() > 30000:
		_cache.clear()
	_cache[texte] = en
	return en


func _traduire(texte: String, profondeur: int) -> String:
	if exact.has(texte):
		return exact[texte]
	# Rien à traduire : nombres, ponctuation
	if _re_lettre.search(texte) == null:
		return texte
	# Espaces autour : traduits sans, puis remis
	var nu := texte.strip_edges()
	if nu != texte and nu != "":
		var i := texte.find(nu)
		return texte.substr(0, i) + traduire(nu, profondeur) + texte.substr(i + nu.length())
	var g := _par_gabarit(texte, profondeur)
	if g != "":
		return g
	var p := profondeur + 1
	# [b]Texte[/b] : le texte entre les balises
	var m := _re_balises.search(texte)
	if m != null and m.get_string(2) != "":
		return m.get_string(1) + traduire(m.get_string(2), p) + m.get_string(3)
	# Symboles devant (◆◇, ★, ▲…) ou derrière (✓, ›, ×1,5, +20 %…)
	m = _re_tete.search(texte)
	if m != null and m.get_end() < texte.length():
		return m.get_string() + traduire(texte.substr(m.get_end()), p)
	# Une phrase connue au milieu d'un texte plus long (« Métier : … Spécialité : … », « 25 + 1 or »)
	var part := _par_partiel(texte, p)
	if part != "":
		return part
	# Morceaux : « A · B », lignes, tirets ; puis la fin chiffrée ou symbolique ; puis les virgules
	var coupe := _couper(texte, _re_coupe, p)
	if coupe != "":
		return coupe
	m = _re_queue.search(texte)
	if m != null and m.get_start() > 0 and _re_lettre.search(texte.substr(0, m.get_start())) != null:
		return traduire(texte.substr(0, m.get_start()), p) + m.get_string()
	coupe = _couper(texte, _re_coupe_faible, p)
	if coupe != "":
		return coupe
	# « Libellé : valeur » (typographie française : espace avant les deux-points)
	var deux_points := texte.find(" : ")
	if deux_points > 0:
		return traduire(texte.substr(0, deux_points), p) + ": " + traduire(texte.substr(deux_points + 3), p)
	return texte


func _couper(texte: String, re: RegEx, profondeur: int) -> String:
	var morceaux := re.search_all(texte)
	if morceaux.is_empty():
		return ""
	var out := ""
	var debut := 0
	for mc in morceaux:
		out += traduire(texte.substr(debut, mc.get_start() - debut), profondeur) + mc.get_string()
		debut = mc.get_end()
	return out + traduire(texte.substr(debut), profondeur)


func _par_partiel(texte: String, profondeur: int) -> String:
	var meilleur: RegExMatch = null
	var g_meilleur: Array = []
	for g in _partiels:
		var m: RegExMatch = g[0].search(texte)
		if m == null or (m.get_start() == 0 and m.get_end() == texte.length()):
			continue
		if meilleur == null or m.get_end() - m.get_start() > meilleur.get_end() - meilleur.get_start():
			meilleur = m
			g_meilleur = g
	if meilleur == null:
		return ""
	return traduire(texte.substr(0, meilleur.get_start()), profondeur) + _remplir(g_meilleur[1], g_meilleur[2], meilleur, profondeur) 		+ traduire(texte.substr(meilleur.get_end()), profondeur)


func _par_gabarit(texte: String, profondeur: int) -> String:
	var cle := texte.substr(0, 3).to_lower()
	for liste in [_gabarits.get(cle, []), _gabarits_ouverts]:
		for g in liste:
			var m: RegExMatch = g[0].search(texte)
			if m == null:
				continue
			return _remplir(g[1], g[2], m, profondeur)
	return ""


func _remplir(anglais: String, types: Array, m: RegExMatch, profondeur: int) -> String:
	var valeurs := []
	for k in types.size():
		var v := m.get_string(k + 1)
		var ty: String = types[k]
		if ty == "s" or ty.begins_with("{"):
			v = traduire(v, profondeur + 1)
		elif "," in v:
			v = v.replace(",", ".")  # 1,5 → 1.5
		valeurs.append(v)
	# Les variables anglaises sont remplies dans l'ordre (les {nom} par leur nom)
	var out := ""
	var debut := 0
	var k := 0
	for v in _re_variable.search_all(anglais):
		out += anglais.substr(debut, v.get_start() - debut).replace("%%", "%")
		var nom := v.get_string()
		if nom.begins_with("{"):
			var j := types.find(nom)
			out += str(valeurs[j]) if j >= 0 else nom
		else:
			# « %0s » : la valeur est sautée (pluriel français « s » ou « x » sans équivalent en anglais)
			if nom != "%0s":
				out += str(valeurs[k]) if k < valeurs.size() else ""
			k += 1
		debut = v.get_end()
	return out + anglais.substr(debut).replace("%%", "%")


func _ajouter_gabarit(fr: String, en: String) -> void:
	var motif := "^"
	var types := []
	var debut := 0
	var lettres := false
	for v in _re_variable.search_all(fr):
		var morceau := fr.substr(debut, v.get_start() - debut).replace("%%", "%")
		motif += _echapper(morceau)
		var nom := v.get_string()
		if nom.begins_with("{"):
			types.append(nom)
			motif += "(.*?)"
		else:
			var ty := nom.right(1)
			types.append(ty)
			match ty:
				"d", "i":
					motif += "([+\\-−]?\\d+)"
				"f":
					motif += "([+\\-−]?\\d+(?:[.,]\\d+)?)"
				_:
					motif += "(.*?)"
		debut = v.get_end()
	var fin := fr.substr(debut).replace("%%", "%")
	motif += _echapper(fin) + "$"
	for c in _re_variable.sub(fr, "", true):
		if (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c.unicode_at(0) >= 0xC0:
			lettres = true
			break
	if not lettres:
		return  # « %s : %s », « %d / %d » : rien à traduire, et ils attraperaient tout
	var re := RegEx.create_from_string(motif)
	if not re.is_valid():
		return
	var g := [re, en, types, _re_variable.sub(fr, "", true).length()]
	# Gabarit qui commence et finit par du texte : il peut aussi être cherché au milieu d'un texte plus long
	var premiere := _re_variable.search(fr)
	if premiere.get_start() >= 2 and fin.strip_edges().length() >= 1:
		var re_partiel := RegEx.create_from_string(motif.substr(1, motif.length() - 2))
		if re_partiel.is_valid():
			_partiels.append([re_partiel, en, types, g[3]])
	var premier := _re_variable.search(fr)
	if premier.get_start() >= 3:
		var cle := fr.substr(0, 3).to_lower()
		if not _gabarits.has(cle):
			_gabarits[cle] = []
		_gabarits[cle].append(g)
	else:
		_gabarits_ouverts.append(g)


## Majuscules hors des variables (« %d » ne doit pas devenir « %D »).
func _majuscules(s: String) -> String:
	var out := ""
	var debut := 0
	for v in _re_variable.search_all(s):
		out += s.substr(debut, v.get_start() - debut).to_upper() + v.get_string()
		debut = v.get_end()
	return out + s.substr(debut).to_upper()


func _echapper(s: String) -> String:
	var out := ""
	for c in s:
		if c in "\\.^$|?*+()[]{}":
			out += "\\" + c
		else:
			out += c
	return out
