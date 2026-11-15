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


## Sépare « adresse:port » (IPv4), « [adresse]:port » (IPv6) ; sans port : PORT. Renvoie [adresse, port].
static func lire_adresse(texte: String) -> Array:
	var t := texte.strip_edges()
	if t.begins_with("["):
		var fin := t.find("]")
		if fin > 0:
			var reste := t.substr(fin + 1)
			return [t.substr(1, fin - 1), int(reste.substr(1)) if reste.begins_with(":") and reste.substr(1).is_valid_int() else PORT]
	if t.count(":") == 1:
		var morceaux := t.split(":")
		if morceaux[1].is_valid_int():
			return [morceaux[0], int(morceaux[1])]
	return [t, PORT]


var port := PORT
var _upnp: UPNP
var _fil_upnp: Thread


func heberger(port_choisi := PORT) -> String:
	port = port_choisi
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_JOUEURS - 1)
	if err != OK:
		return "Impossible d'ouvrir le port %d : une autre partie est peut-être déjà ouverte." % port
	multiplayer.multiplayer_peer = peer
	est_hote = true
	joueurs = [{"id": 1, "pseudo": pseudo}]
	multiplayer.peer_disconnected.connect(_depart)
	liste_changee.emit()
	return ""


## Ouvre le port sur la box par UPnP, dans un fil à part (la recherche de la box prend quelques secondes).
## fini(adresse_publique, erreur) est appelé dans le fil principal.
func ouvrir_box(fini: Callable) -> void:
	_fil_upnp = Thread.new()
	_fil_upnp.start(func():
		var u := UPNP.new()
		var e := u.discover(2000, 2)
		var texte := ""
		var publique := ""
		if e != UPNP.UPNP_RESULT_SUCCESS or u.get_gateway() == null or not u.get_gateway().is_valid_gateway():
			texte = "box introuvable ou UPnP désactivé"
		elif u.add_port_mapping(port, port, "ZooLife", "UDP") != UPNP.UPNP_RESULT_SUCCESS:
			texte = "la box a refusé d'ouvrir le port"
		else:
			publique = u.query_external_address()
			_upnp = u
		fini.call_deferred(publique, texte))


func rejoindre(texte_adresse: String) -> String:
	var lu := lire_adresse(texte_adresse)
	var adresse: String = lu[0]
	port = int(lu[1])
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(adresse, port)
	if err != OK:
		return "Adresse invalide : %s" % adresse
	multiplayer.multiplayer_peer = peer
	# Méthodes nommées, branchées une seule fois : avec des fonctions anonymes, un second essai dans le même salon
	# rebranchait les signaux et le joueur s'annonçait deux fois (l'hôte voyait un joueur fantôme qu'il attendait).
	if not multiplayer.connected_to_server.is_connected(_connecte):
		multiplayer.connected_to_server.connect(_connecte)
		multiplayer.connection_failed.connect(_echec_connexion)
		multiplayer.server_disconnected.connect(_hote_parti)
	return ""


func _connecte() -> void:
	_annonce.rpc_id(1, pseudo, version_jeu())


func _echec_connexion() -> void:
	coupure.emit("Connexion impossible. Vérifiez l'adresse, le port %d et le pare-feu de l'hôte." % port)


func _hote_parti() -> void:
	coupure.emit("L'hôte a quitté la partie.")


func _exit_tree() -> void:
	quitter()
	if _fil_upnp != null:
		_fil_upnp.wait_to_finish()
		_fil_upnp = null
	if _upnp != null:
		_upnp.delete_port_mapping(port, "UDP")
		_upnp = null


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
	if _index_de(id) >= 0:
		return  # déjà dans la liste : une seconde annonce ne crée pas un second joueur
	# Deux joueurs du même nom (« Directeur » par défaut) : le second devient « Directeur 2 »
	var base := nom.strip_edges().left(16)
	if base == "":
		base = "Joueur"
	var pris: Array = joueurs.map(func(j): return str(j["pseudo"]))
	var nom_final := base
	var k := 2
	while nom_final in pris:
		nom_final = "%s %d" % [base.left(13), k]
		k += 1
	joueurs.append({"id": id, "pseudo": nom_final})
	_liste.rpc(joueurs)


@rpc("authority", "reliable")
func _refus(texte: String) -> void:
	coupure.emit(texte)


@rpc("authority", "call_local", "reliable")
func _liste(liste: Array) -> void:
	joueurs = liste
	liste_changee.emit()


## Hôte : lance la partie pour tout le monde. Avec des IA, on joue toujours à 4.
func lancer(completer_ia: bool, difficile: bool, mode := "course") -> void:
	if not est_hote or joueurs.size() < 2:
		return
	multiplayer.multiplayer_peer.refuse_new_connections = true
	var params := {"graine": randi() % 1000000000, "nb": MAX_JOUEURS if completer_ia else joueurs.size(), "difficile": difficile,
		"mode": mode}
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
