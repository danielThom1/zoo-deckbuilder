class_name Classement
extends Node
## Classement en ligne des défis (12/11/2026), sur Supabase (docs/supabase_classement.sql). Chaque joueur a un compte
## anonyme créé à la première connexion (jeton gardé dans user://classement.cfg). Le jeu n'envoie et ne lit que par les
## fonctions du serveur : soumettre_score (score + replay de la partie), classement (rang, total, top 10 dont les
## pseudos ne sont montrés qu'aux joueurs du top 10), replay_semaine_precedente.
## Adresse du projet et clé publique (« anon », faite pour être distribuée) : data/classement.json. Sans elles, le
## classement est simplement indisponible.
## Nœud à ajouter à l'arbre (les requêtes HTTP en ont besoin) ; fonctions à attendre avec await.

const CONFIG := "res://data/classement.json"
const SESSION := "user://classement.cfg"
const DELAI := 15.0

var erreur := ""  # dernière erreur lisible, pour l'affichage
var _url := ""
var _cle := ""


func _init() -> void:
	if FileAccess.file_exists(CONFIG):
		var c = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		if c is Dictionary:
			_url = str(c.get("url", "")).trim_suffix("/")
			_cle = str(c.get("cle", ""))


func actif() -> bool:
	return _url != "" and _cle != ""


## Une requête JSON ; renvoie {"code", "corps"} (corps lu en JSON, ou null).
func _requete(chemin: String, corps: Variant, jeton := "", essai := 0) -> Dictionary:
	await get_tree().process_frame  # une image longue (calcul bloquant) déclencherait le délai d'attente d'emblée
	var h := HTTPRequest.new()
	h.timeout = DELAI
	add_child(h)
	# La clé publiable (sb_publishable_…) va dans « apikey » seulement : « Authorization » n'accepte qu'un jeton de session.
	var entetes := PackedStringArray(["apikey: " + _cle, "Content-Type: application/json"])
	if jeton != "":
		entetes.append("Authorization: Bearer " + jeton)
	if h.request(_url + chemin, entetes, HTTPClient.METHOD_POST, JSON.stringify(corps)) != OK:
		h.queue_free()
		return {"code": 0, "corps": null}
	var r: Array = await h.request_completed
	h.queue_free()
	if int(r[0]) == HTTPRequest.RESULT_TIMEOUT and essai == 0:
		return await _requete(chemin, corps, jeton, 1)
	if int(r[0]) != HTTPRequest.RESULT_SUCCESS:
		push_warning("Classement : requête %s échouée (résultat %d)" % [chemin, int(r[0])])
	var texte := (r[3] as PackedByteArray).get_string_from_utf8()
	return {"code": int(r[1]) if int(r[0]) == HTTPRequest.RESULT_SUCCESS else 0, "corps": JSON.parse_string(texte) if texte != "" else null}


## Jeton de session : gardé, renouvelé s'il expire, ou compte anonyme créé à la première connexion.
func _jeton() -> String:
	var cfg := ConfigFile.new()
	cfg.load(SESSION)
	var acces: String = cfg.get_value("session", "acces", "")
	var expire: float = cfg.get_value("session", "expire", 0.0)
	if acces != "" and Time.get_unix_time_from_system() < expire - 60.0:
		return acces
	var renouveler: String = cfg.get_value("session", "renouveler", "")
	var r: Dictionary = {}
	if renouveler != "":
		r = await _requete("/auth/v1/token?grant_type=refresh_token", {"refresh_token": renouveler})
	if r.get("code", 0) != 200:
		r = await _requete("/auth/v1/signup", {"data": {}})
	if r["code"] != 200 or not r["corps"] is Dictionary or not r["corps"].has("access_token"):
		erreur = "Connexion au classement impossible%s." % ((" (" + str(r["corps"].get("msg", r["corps"].get("message", ""))) + ")") if r.get("corps") is Dictionary else "")
		return ""
	var c: Dictionary = r["corps"]
	cfg.set_value("session", "acces", c["access_token"])
	cfg.set_value("session", "renouveler", c.get("refresh_token", ""))
	cfg.set_value("session", "expire", Time.get_unix_time_from_system() + float(c.get("expires_in", 3600)))
	cfg.save(SESSION)
	return str(c["access_token"])


func _rpc(nom: String, corps: Dictionary) -> Variant:
	erreur = ""
	if not actif():
		erreur = "Classement en ligne pas encore ouvert."
		return null
	var jeton: String = await _jeton()
	if jeton == "":
		return null
	var r: Dictionary = await _requete("/rest/v1/rpc/" + nom, corps, jeton)
	if r["code"] < 200 or r["code"] >= 300:
		erreur = "Classement indisponible (%s)." % (str(r["corps"].get("message", r["code"])) if r["corps"] is Dictionary else str(r["code"]))
		return null
	return r["corps"]


## {"rang" (null hors classement), "score", "total", "top": [{"rang", "score", "moi", "pseudo" (null hors top 10)}]}.
func classement(defi: String) -> Dictionary:
	var r = await _rpc("classement", {"p_defi": defi})
	return r if r is Dictionary else {}


## Envoie le score du joueur i à la fin d'un défi, avec le replay de la partie. Renvoie le classement après l'envoi.
func soumettre(mt: Match, i: int) -> Dictionary:
	var replay := Replay.vers_dict(Replay.depuis_partie(mt, i))
	replay["rep"] = mt.players[i].reputation()
	var r = await _rpc("soumettre_score", {"p_defi": mt.defi, "p_pseudo": Statistiques.pseudo(), "p_score": snappedf(mt.players[i].reputation(), 0.1),
		"p_version": Reseau.version_jeu(), "p_replay": replay})
	return r if r is Dictionary else {}


## Vainqueur du défi de la semaine passée, sans son replay : {"pseudo", "score"}, ou {} (personne, ou hors ligne).
func vainqueur_semaine() -> Dictionary:
	var r = await _rpc("vainqueur_semaine_precedente", {})
	return r if r is Dictionary else {}


## Replay du vainqueur de la semaine passée : {"pseudo", "score", "replay"}, ou {}.
func replay_semaine() -> Dictionary:
	var r = await _rpc("replay_semaine_precedente", {})
	return r if r is Dictionary and r.get("replay") is Dictionary else {}


## Texte d'une ligne de rang : « 14e sur 52 ».
static func texte_rang(c: Dictionary) -> String:
	if c.is_empty():
		return ""
	if c.get("rang") == null:
		return "%d participant%s" % [int(c.get("total", 0)), "s" if int(c.get("total", 0)) > 1 else ""]
	var rang := int(c["rang"])
	return "%d%s sur %d" % [rang, "er" if rang == 1 else "e", int(c["total"])]
