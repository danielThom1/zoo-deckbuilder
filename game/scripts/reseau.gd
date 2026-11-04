class_name Reseau
extends Node
## Connexion multijoueur (ENet : un joueur héberge). L'hôte donne la cadence : dix fois par seconde, il envoie à tous une
## « trame » : les ordres reçus et le nombre de pas de temps à jouer. Tout le monde, hôte compris, applique les mêmes trames
## dans le même ordre. L'hôte décide aussi quand la partie avance : 20 s de préparation, joueurs prêts, délais de choix.

signal liste_changee
signal demarrage(params: Dictionary)
signal coupure(texte: String)

const PORT := 7777
const MAX_JOUEURS := 4
const PAS := 0.1  # une trame par dixième de seconde
const DELAIS := {"draft": 30.0, "marche": 45.0, "bonus": 30.0, "equipe": 60.0}
const VITESSES := [1.0, 2.0, 4.0, 8.0, 16.0]
const CONTROLE_TOUTES_LES := 50  # trames, soit 5 secondes

var pseudo := "Joueur"
var preparation := 20.0  # secondes de préparation au début de chaque journée
var controles_ok := 0
var est_hote := false
var joueurs: Array = []  # {"id", "pseudo"} ; l'ordre donne le numéro de joueur dans la partie
var index_local := 0
var mt: Match
var main_jeu: Node
var etat := {}  # dernier état reçu : préparation, délai, joueurs prêts, vitesse commune
var desynchro := false
var est_pret := false

# Hôte
var _attente: Array = []
var _decisions: Array = []
var _horloge := 0.0
var _prep := 0.0
var _signature := ""
var _chrono := 0.0
var _rythme_ia := 0.0
var _prets := {}
var _vitesses := {}
var _absents := {}
var _no_trame := 0
var _empreintes := {}


## Version du jeu : les données doivent être identiques sur toutes les machines, et le moteur le même. Les scripts ne
## comptent pas : un jeu exporté ne les lit pas comme l'éditeur. Une différence de règles déclenche l'alerte de divergence.
static func version_jeu() -> String:
	var morceaux: String = Engine.get_version_info()["string"]
	for f in ["res://data/animals.json", "res://data/workers.json", "res://data/buildings.json", "res://data/events.json", "res://data/personnages.json"]:
		morceaux += FileAccess.get_md5(f)
	return morceaux.md5_text()


func heberger() -> String:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_JOUEURS - 1)
	if err != OK:
		return "Impossible d'ouvrir le port %d : une autre partie est peut-être déjà ouverte." % PORT
	multiplayer.multiplayer_peer = peer
	est_hote = true
	joueurs = [{"id": 1, "pseudo": pseudo}]
	multiplayer.peer_disconnected.connect(_depart)
	liste_changee.emit()
	return ""


func rejoindre(adresse: String) -> String:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(adresse, PORT)
	if err != OK:
		return "Adresse invalide : %s" % adresse
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(func(): _annonce.rpc_id(1, pseudo, version_jeu()))
	multiplayer.connection_failed.connect(func(): coupure.emit("Connexion impossible. Vérifiez l'adresse, le port %d et le pare-feu de l'hôte." % PORT))
	multiplayer.server_disconnected.connect(func(): coupure.emit("L'hôte a quitté la partie."))
	return ""


func _exit_tree() -> void:
	quitter()


func quitter() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


@rpc("any_peer", "reliable")
func _annonce(nom: String, version: String) -> void:
	if not est_hote:
		return
	var id := multiplayer.get_remote_sender_id()
	if version != version_jeu():
		_refus.rpc_id(id, "Versions du jeu différentes : tout le monde doit avoir la même.")
		return
	if mt != null:
		_refus.rpc_id(id, "La partie a déjà commencé.")
		return
	if joueurs.size() >= MAX_JOUEURS:
		_refus.rpc_id(id, "La partie est complète.")
		return
	joueurs.append({"id": id, "pseudo": nom.strip_edges().left(16)})
	_liste.rpc(joueurs)


@rpc("authority", "reliable")
func _refus(texte: String) -> void:
	coupure.emit(texte)


@rpc("authority", "call_local", "reliable")
func _liste(liste: Array) -> void:
	joueurs = liste
	liste_changee.emit()


## Hôte : lance la partie pour tout le monde. Avec des IA, on joue toujours à 4.
func lancer(completer_ia: bool, difficile: bool) -> void:
	if not est_hote or joueurs.size() < 2:
		return
	multiplayer.multiplayer_peer.refuse_new_connections = true
	var params := {"graine": randi() % 1000000000, "nb": MAX_JOUEURS if completer_ia else joueurs.size(), "difficile": difficile}
	_demarrer.rpc(params)


@rpc("authority", "call_local", "reliable")
func _demarrer(params: Dictionary) -> void:
	for i in joueurs.size():
		if joueurs[i]["id"] == multiplayer.get_unique_id():
			index_local = i
	params["humains"] = joueurs
	params["index"] = index_local
	demarrage.emit(params)


func attacher(jeu: Node, partie: Match) -> void:
	main_jeu = jeu
	mt = partie
	_prep = preparation if mt.phase == "day" else 0.0


# --- Depuis les joueurs ---------------------------------------------------------------------------------------

func envoyer(nom: String, args: Array) -> void:
	if est_hote:
		_attente.append({"p": index_local, "n": nom, "a": args})
	else:
		_ordre.rpc_id(1, nom, args)


func _index_de(id: int) -> int:
	for i in joueurs.size():
		if joueurs[i]["id"] == id:
			return i
	return -1


@rpc("any_peer", "reliable")
func _ordre(nom: String, args: Array) -> void:
	var p := _index_de(multiplayer.get_remote_sender_id())
	if est_hote and p >= 0:
		_attente.append({"p": p, "n": nom, "a": args})


func basculer_pret() -> void:
	est_pret = not est_pret
	if est_hote:
		_prets[index_local] = est_pret
	else:
		_pret.rpc_id(1, est_pret)


@rpc("any_peer", "reliable")
func _pret(valeur: bool) -> void:
	if est_hote:
		_prets[_index_de(multiplayer.get_remote_sender_id())] = valeur


func demander_vitesse(v: float) -> void:
	if est_hote:
		_vitesses[index_local] = v
	else:
		_vitesse.rpc_id(1, v)


@rpc("any_peer", "reliable")
func _vitesse(v: float) -> void:
	if est_hote and VITESSES.has(v):
		_vitesses[_index_de(multiplayer.get_remote_sender_id())] = v


@rpc("any_peer", "reliable")
func _controle(no: int, valeur: int) -> void:
	if not est_hote or not _empreintes.has(no):
		return
	if _empreintes[no] != valeur:
		_alerte.rpc()
	else:
		controles_ok += 1


@rpc("authority", "call_local", "reliable")
func _alerte() -> void:
	desynchro = true


# --- Hôte : la cadence -------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not est_hote or mt == null or mt.game_over:
		return
	_horloge += delta
	while _horloge >= PAS:
		_horloge -= PAS
		_une_trame()


func _humains_presents() -> Array:
	var out := []
	for i in joueurs.size():
		if not _absents.has(i) and not mt.is_ai(i):
			out.append(i)
	return out


func _tous_prets() -> bool:
	var h := _humains_presents()
	return not h.is_empty() and h.all(func(i): return _prets.get(i, false))


func _vitesse_commune() -> float:
	var v := 16.0
	for i in _humains_presents():
		v = minf(v, float(_vitesses.get(i, 1.0)))
	return v


## Ce que la partie attend en ce moment : quand cela change, les délais et les « prêt » repartent de zéro.
func _attend() -> String:
	match mt.phase:
		"draft":
			return "draft|%d|%d" % [mt.current_drafter(), mt.draft_pool.size()]
		"day":
			return "jour|%d" % mt.day
		"night":
			if mt.market_stage():
				return "marche|%s|%d" % [mt.night_stage, mt.current_buyer()]
			return "%s|%d" % [mt.night_stage, mt.day]
	return ""


func _une_trame() -> void:
	var sig := _attend()
	if sig != _signature:
		_signature = sig
		_chrono = 0.0
		_prets.clear()
		_rythme_ia = 0.0
		_reinitialiser_pret.rpc()
		if mt.phase == "day":
			_prep = preparation
	_chrono += PAS
	_rythme_ia += PAS
	var n := 0
	var delai := 0.0
	match mt.phase:
		"day":
			if _prep > 0.0:
				_prep -= PAS
			else:
				n = int(_vitesse_commune())
			if _tous_prets():
				_decisions.append(["fin_jour", 0])
				_prets.clear()
		"draft":
			var d := mt.current_drafter()
			if mt.is_ai(d) or _absents.has(d):
				if _rythme_ia >= 0.35:
					_rythme_ia = 0.0
					_decisions.append(["draft_ia", 0])
			else:
				delai = DELAIS["draft"]
				if _chrono >= delai:
					_decisions.append(["draft_ia", 0])
		"night":
			if mt.market_stage():
				var b := mt.current_buyer()
				if b >= 0 and mt.is_ai(b):
					if _rythme_ia >= 1.1:
						_rythme_ia = 0.0
						_decisions.append(["pas_ia", 0])
				else:
					delai = DELAIS["marche"]
					if _chrono >= delai or _absents.has(b):
						_decisions.append(["tour_passe", 0])
			elif mt.night_stage == "bonus":
				var l := mt.influence_leader()
				if mt.is_ai(l):
					if _rythme_ia >= 2.0:
						_rythme_ia = 0.0
						_decisions.append(["pas_ia", 0])
				else:
					delai = DELAIS["bonus"]
					if _chrono >= delai:
						_decisions.append(["bonus_passe", 0])
			else:
				delai = DELAIS["equipe"]
				if _chrono >= delai or _tous_prets():
					_decisions.append(["jour_suivant", 0])
					_prets.clear()
	var infos := {"prep": ceili(_prep) if mt.phase == "day" else 0, "delai": ceili(delai - _chrono) if delai > 0.0 else 0,
		"prets": _humains_presents().filter(func(i): return _prets.get(i, false)).size(), "humains": _humains_presents().size(), "vitesse": _vitesse_commune()}
	var ordres := _attente
	var decisions := _decisions
	_attente = []
	_decisions = []
	_trame.rpc(n, ordres, decisions, infos)


@rpc("authority", "call_local", "reliable")
func _reinitialiser_pret() -> void:
	est_pret = false


## Chaque machine applique la trame : décisions de l'hôte, ordres des joueurs, puis pas de temps.
@rpc("authority", "call_local", "reliable")
func _trame(n: int, ordres: Array, decisions: Array, infos: Dictionary) -> void:
	if mt == null:
		return
	etat = infos
	for d in decisions:
		Commandes.decision(mt, d[0], d[1])
	for o in ordres:
		var err := Commandes.executer(mt, o["p"], o["n"], o["a"])
		if err != "" and o["p"] == index_local:
			mt.players[index_local].say(err)
	for k in n:
		mt.tick(GameState.TICK)
	_no_trame += 1
	if _no_trame % CONTROLE_TOUTES_LES == 0:
		var e := Commandes.empreinte(mt)
		if est_hote:
			_empreintes[_no_trame] = e
		else:
			_controle.rpc_id(1, _no_trame, e)


func _depart(id: int) -> void:
	var i := _index_de(id)
	if i < 0:
		return
	_absents[i] = true
	if mt == null:
		joueurs.remove_at(i)
		_absents.erase(i)
		_liste.rpc(joueurs)
	else:
		_decisions.append(["ia_reprend", i])
