class_name Defis
extends RefCounted
## Défis (12/11/2026) : la même partie pour tout le monde, à comparer au score. Seul contre 3 IA figées (data/defis.json),
## partie de 10 jours, score = réputation au soir du dernier jour. Les files du marché (Match._tirer_files) et les
## événements tirés jour par jour font sortir les mêmes cartes et espèces dans le même ordre, quoi que l'on fasse.
## Quatre défis fixes (deux en Réserve naturelle) et un défi de la semaine, tiré de son numéro.

const CHEMIN := "res://data/defis.json"
const JOURS_SEMAINE := ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]

static var _donnees := {}


static func donnees() -> Dictionary:
	if _donnees.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(CHEMIN))
		_donnees = d if d is Dictionary else {"jours": 10, "ia": [], "defis": [], "semaine": {"modes": ["course"]}}
	return _donnees


## Numéro de la semaine (lundi à dimanche, en temps universel) depuis le 1er janvier 1970 (un jeudi).
static func numero_semaine(unix := -1.0) -> int:
	var t := Time.get_unix_time_from_system() if unix < 0.0 else unix
	return floori((floorf(t / 86400.0) + 3.0) / 7.0)


## Le défi de la semaine : graine et mode tirés du numéro de semaine (le mode alterne d'une semaine à l'autre).
static func semaine(n := -1) -> Dictionary:
	if n < 0:
		n = numero_semaine()
	var modes: Array = donnees()["semaine"]["modes"]
	var lundi := Time.get_datetime_dict_from_unix_time(int((n * 7 - 3) * 86400))
	return {"id": "semaine_%d" % n, "nom": "Défi de la semaine du %d/%d" % [lundi["day"], lundi["month"]],
		"graine": absi(hash(["semaine", n])) % 1000000000, "mode": modes[n % modes.size()], "semaine": n}


## Tous les défis jouables maintenant : les fixes, puis celui de la semaine.
static func liste() -> Array:
	var out: Array = donnees()["defis"].duplicate(true)
	out.append(semaine())
	return out


static func trouver(id: String) -> Dictionary:
	if id.begins_with("semaine_"):
		return semaine(int(id.trim_prefix("semaine_")))
	for d in donnees()["defis"]:
		if d["id"] == id:
			return d
	return {}


## Stratégies des joueurs : le joueur humain en premier, puis les 3 IA du défi.
static func strategies() -> Array:
	var out: Array = [null]
	out.append_array(donnees()["ia"].duplicate(true))
	return out


## Règles du défi sur une copie des données : partie de N jours, sans victoire avant (objectif hors d'atteinte).
static func appliquer(data: Dictionary) -> Dictionary:
	var d := data.duplicate(true)
	d["buildings"]["partie"]["jour_max"] = int(donnees()["jours"])
	d["buildings"]["partie"]["objectif_reputation"] = 1000000
	return d


static func libelle_mode(mode: String) -> String:
	return "Réserve naturelle" if mode == "nature" else "Avec aménagements"
