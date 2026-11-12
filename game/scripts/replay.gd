class_name Replay
extends RefCounted
## Revoir une partie. Le jeu est déterministe (même graine, mêmes pas de temps, mêmes ordres dans le même ordre) : on ne
## filme rien, on rejoue la partie. Deux sortes de replay :
## - « journal » : la partie d'un joueur humain, avec ses ordres, datés au pas de temps près (Match.journal, écran de fin) ;
## - « étude » : une partie entre IA de tests/evolution.gd, qui joue d'elle-même à partir de sa graine et de ses stratégies
##   (partie la plus courte, fichier replay_plus_courte.json à la racine du dépôt, réservé au développement).

const FICHIER_ETUDE := "../replay_plus_courte.json"
const PREFIXE_ZERO := "replay_ia_a_zero_"  # parties où une IA finit à 0, pour comprendre ce qu'elle a mal fait
const ZERO_MAX := 3

var graine := 0
var nb := 4
var humain := -1
var autres: Array = []
var strategies: Array = []
var noms: Array = []
var journal: Array = []
var dt := GameState.TICK
var automatique := false  # étude : pas de journal, on enchaîne comme tests/evolution.gd
var voir := 0  # joueur montré au départ
var empreinte := 0  # état final attendu (journal)
var attendu := {}  # étude : gagnant, jour et réputation attendus
var version := ""
var mode := "course"
var defi := ""
var prochain := 0
var diverge := false


## Replay de la partie qui vient de se terminer.
static func depuis_partie(mt: Match, joueur: int) -> Replay:
	var r := Replay.new()
	var P: Dictionary = mt.params_replay
	r.graine = int(P["graine"])
	r.nb = int(P["nb"])
	r.humain = int(P["humain"])
	r.autres = P["autres"]
	r.strategies = P["strategies"]
	r.mode = str(P.get("mode", "course"))
	r.defi = str(P.get("defi", ""))
	r.noms = mt.names.duplicate()
	r.journal = mt.journal
	r.voir = joueur
	r.empreinte = Commandes.empreinte(mt)
	return r


## Replay d'une partie en dictionnaire JSON (envoyé avec un score de défi) ; depuis_dict fait l'inverse.
static func vers_dict(r: Replay) -> Dictionary:
	return {"graine": r.graine, "nb": r.nb, "humain": r.humain, "autres": r.autres, "strategies": r.strategies, "mode": r.mode,
		"defi": r.defi, "noms": r.noms, "journal": _vers_json(r.journal), "voir": r.voir, "empreinte": str(r.empreinte), "version": Reseau.version_jeu()}


static func depuis_dict(d: Dictionary) -> Replay:
	var r := Replay.new()
	r.graine = int(d["graine"])
	r.nb = int(d["nb"])
	r.humain = int(d["humain"])
	r.autres = d["autres"]
	r.strategies = d["strategies"]
	r.mode = str(d.get("mode", "course"))
	r.defi = str(d.get("defi", ""))
	r.noms = d.get("noms", [])
	r.journal = _depuis_json(d["journal"])
	r.voir = int(d.get("voir", 0))
	r.empreinte = int(str(d.get("empreinte", "0")))  # en texte : un entier de 64 bits ne survit pas au JSON
	r.version = str(d.get("version", ""))
	return r


## Le JSON ne connaît ni les cases (Vector2i) ni les entiers : les cases sont notées {"_v": [x, y]}, un décimal rond
## {"_r": x}, et les autres nombres ronds relus redeviennent des entiers (un ordre attend parfois un int).
static func _vers_json(v: Variant) -> Variant:
	if v is float and v == floorf(v):
		return {"_r": v}
	if v is Vector2i:
		return {"_v": [v.x, v.y]}
	if v is Vector2:
		return {"_f": [v.x, v.y]}
	if v is Array:
		return v.map(func(x): return _vers_json(x))
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _vers_json(v[k])
		return d
	return v


static func _depuis_json(v: Variant) -> Variant:
	if v is float and v == floorf(v) and absf(v) < 1e15:
		return int(v)
	if v is Array:
		return v.map(func(x): return _depuis_json(x))
	if v is Dictionary:
		if v.has("_v") and v.size() == 1:
			return Vector2i(int(v["_v"][0]), int(v["_v"][1]))
		if v.has("_r") and v.size() == 1:
			return float(v["_r"])
		if v.has("_f") and v.size() == 1:
			return Vector2(float(v["_f"][0]), float(v["_f"][1]))
		var d := {}
		for k in v:
			d[k] = _depuis_json(v[k])
		return d
	return v


static func chemin_etude() -> String:
	return ProjectSettings.globalize_path("res://").path_join(FICHIER_ETUDE)


static func chemin_zero(n: int) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../%s%d.json" % [PREFIXE_ZERO, n])


## Parties à 0 enregistrées par la dernière étude.
static func chemins_zero() -> Array:
	var out := []
	for n in range(1, ZERO_MAX + 1):
		if FileAccess.file_exists(chemin_zero(n)):
			out.append(chemin_zero(n))
	return out


## Partie la plus courte d'une étude : tout ce qu'il faut pour la rejouer tient en quelques lignes.
## voir : le joueur montré au départ ; chemin : vide pour le fichier de la partie la plus courte.
static func ecrire_etude(seed_partie: int, genomes: Array, gagnant: int, jour: int, rep: float, voir := -1, chemin := "") -> void:
	var f := FileAccess.open(chemin if chemin != "" else chemin_etude(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"graine": seed_partie, "strategies": genomes, "gagnant": gagnant, "voir": voir if voir >= 0 else gagnant, "jour": jour, "rep": rep, "version": Reseau.version_jeu()}, "  "))
		f.close()


## null s'il n'y a pas de fichier. Si les règles ont changé depuis l'étude, la partie rejouée ne sera plus la même.
static func lire_etude(chemin := "") -> Replay:
	if chemin == "":
		chemin = chemin_etude()
	if not FileAccess.file_exists(chemin):
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(chemin))
	if not d is Dictionary:
		return null
	var r := Replay.new()
	r.graine = int(d["graine"])
	r.strategies = d["strategies"]
	r.automatique = true
	r.dt = 1.0
	r.voir = int(d.get("voir", d["gagnant"]))
	r.attendu = {"gagnant": int(d["gagnant"]), "jour": int(d["jour"]), "rep": float(d["rep"])}
	r.version = str(d.get("version", ""))
	return r


func creer_partie(data: Dictionary) -> Match:
	prochain = 0
	diverge = false
	var mt := Match.new(data, graine, nb, humain, strategies.duplicate(true), autres, mode, defi)
	if not noms.is_empty():
		mt.names.assign(noms)
	return mt


## À appeler avant chaque pas de temps de la journée : les ordres donnés à ce moment-là.
func ordres_du_pas(mt: Match) -> void:
	while mt.phase == "day" and not mt.game_over and prochain < journal.size() and int(journal[prochain][0]) <= mt.pas:
		_appliquer(mt, journal[prochain])
		prochain += 1


## Draft et nuit : un coup à la fois, pour qu'on voie ce qui se passe.
func coup_suivant(mt: Match) -> void:
	if automatique:
		if mt.phase == "draft":
			mt.pick_draft(mt.ai_choice())
		elif mt.phase == "night":
			mt.start_next_day()
		return
	if prochain >= journal.size():
		diverge = true
		return
	_appliquer(mt, journal[prochain])
	prochain += 1


func _appliquer(mt: Match, e: Array) -> void:
	if int(e[1]) < 0:
		Commandes.decision(mt, str(e[2]), 0)
	else:
		Commandes.executer(mt, int(e[1]), str(e[2]), e[3])


## La partie rejouée est-elle bien celle qu'on a enregistrée ? À appeler une fois la partie terminée.
func conforme(mt: Match) -> bool:
	if automatique:
		return mt.winner == int(attendu["gagnant"]) and mt.day == int(attendu["jour"]) \
			and is_equal_approx(snappedf(float(mt.players[mt.winner].rep_points), 0.001), snappedf(float(attendu["rep"]), 0.001))
	return not diverge and Commandes.empreinte(mt) == empreinte
