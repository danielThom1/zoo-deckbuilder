class_name Match
extends RefCounted
## Une partie : les joueurs (humain et IA), l'horloge commune, le draft par tours et le marché de nuit partagés.
## Chaque joueur (GameState) a sa propre copie de la carte, générée avec la même graine.

var data: Dictionary
var perso_bag: Array = []  # personnages pas encore tirés (data/personnages.json), remélangés une fois tous sortis
var seed_value := 0
var rng := RandomNumberGenerator.new()
# Tirages séparés (12/11) : à graine égale, le marché propose les mêmes collaborateurs, cartes et espèces dans le même
# ordre, quoi que fassent les joueurs (mode défi). Les files sont tirées une fois pour toutes au début de la partie.
var rng_marche := RandomNumberGenerator.new()  # carte retirée de chaque rangée au renouvellement
var file_ouvriers: Array = []  # collaborateurs à venir au marché, dans l'ordre
var i_ouvriers := 0
var file_actions: Array = []  # cartes d'action à venir (définitions)
var i_actions := 0
var file_contrats: Array = []  # espèces pas encore sorties au marché, dans l'ordre de sortie
const TAILLE_FILES := 160
var players: Array[GameState] = []
var ais: Array = []  # AIController, ou null pour le joueur humain
var names: Array[String] = []
var day := 1
var time := 0.0
var day_length := 300.0
var objectifs: Array = []  # objectifs des actionnaires de cette partie
var phase := "draft"  # draft, day, night
var game_over := false
var winner := -1
var next_card_id := 1
var positive_ids := {}

var draft_pool: Array = []  # cartes révélées du tour en cours
var draft_reserve: Array = []  # cartes des tours suivants, pas encore révélées
var draft_order: Array[int] = []
var draft_turn := 0
var drafted: Array = []  # cartes prises, par joueur

var market_workers: Array = []
var market_contracts: Array = []
var market_actions: Array = []  # cartes d'action proposées la nuit
var night_order: Array[int] = []
var night_turn := 0  # position dans night_order du joueur qui achète (étapes de marché)
## Étapes de la nuit : trois marchés dans l'ordre d'influence, le bonus du premier, puis l'équipe (chacun en parallèle).
const NIGHT_STAGES := ["contrats", "ouvriers", "cartes", "bonus", "equipe"]
var night_stage := ""
var night_taken: Array = []  # achats de la nuit, visibles de tous : {"etape", "joueur", "objet"}
var log: Array[String] = []  # achats des IA de la nuit
var current_event := {}  # événement du jour (commun à tous les joueurs)
var bonus_offer: Array = []  # bonus de nuit proposés (3)
## Le premier en influence peut refuser tous les bonus proposés.
const NO_BONUS := {"id": "aucun", "nom": "Aucun bonus", "texte": "Aucun bonus demain.", "effets": {}}
var bonus_choice := {}  # bonus choisi par le premier en influence : actif le lendemain pour tous les joueurs
var rival_en_tete := -1  # dernier concurrent annoncé en tête par Hubert
var offres := {}  # espèce -> nuits passées au marché (étude)
var cartes_motifs := {}  # calculs de l'IA partagés entre les joueurs : voir AIController._pattern_fit_maps
var journal: Array = []  # replay : [pas, joueur (-1 : décision), nom, arguments codés], voir Replay
var pas := 0  # pas de temps joués depuis le début
var pas_matin := 0  # pas et taille du journal au dernier matin : la journée en cours se rejoue depuis la sauvegarde
var journal_matin := 0
var params_replay := {}
var mode := "course"  # course, nature ou cozy (ModesPartie)
var defi := ""  # identifiant du défi joué (Defis), vide sinon
var replay_possible := true  # faux après une reprise de sauvegarde, au tutoriel et dans les captures
var autosave := false  # partie d'un joueur humain : sauvegarde automatique chaque matin
var history: Array = []  # statistiques par jour et par joueur (simulations)


## human = index du joueur humain, ou -1 pour une partie entièrement jouée par des IA.
func _init(game_data: Dictionary, map_seed: int, nb_players := 4, human := 0, strategies: Array = [], autres_humains: Array = [], mode_partie := "course", defi_id := "") -> void:
	mode = mode_partie if mode_partie != "" else "course"
	defi = defi_id
	data = ModesPartie.appliquer(game_data, mode)
	if defi != "":
		data = Defis.appliquer(data)
	seed_value = map_seed
	params_replay = {"graine": map_seed, "nb": nb_players, "humain": human, "strategies": strategies.duplicate(true), "autres": autres_humains.duplicate(), "mode": mode, "defi": defi}
	rng.seed = map_seed ^ 0x5bd1e995
	rng_marche.seed = hash([map_seed, "marche"])
	day_length = float(data["buildings"]["partie"]["duree_jour_s"])
	for t in data["workers"]["traits_positifs"]:
		positive_ids[t["id"]] = true
	# Même graine pour tous : la carte est générée une seule fois puis copiée pour chaque joueur.
	var base_map := MapGenerator.generate(data["buildings"], map_seed) if nb_players > 0 else null
	for i in nb_players:
		players.append(GameState.new(data, map_seed, self, i, base_map))
		drafted.append([])
	var ia_count := 0
	for i in nb_players:
		if i == human or autres_humains.has(i):
			ais.append(null)
			names.append("Vous")
		else:
			var strat: Dictionary = ModesPartie.strategie(strategies[i] if i < strategies.size() and strategies[i] != null else {}, mode)
			ais.append(AIController.new(self, players[i], strat))
			# Niveau difficile : l'IA part avec plus d'argent (Main.strategies_du_niveau, champ « argent_depart »)
			if strat.has("argent_depart"):
				players[i].money = float(strat["argent_depart"])
			ia_count += 1
			names.append("IA %d" % ia_count if str(strat.get("nom", "")) == "" else "IA %d (%s)" % [ia_count, strat["nom"]])
	# Objectifs tirés avant le draft : on peut les lire, avec la carte, avant de choisir ses collaborateurs.
	_tirer_objectifs()
	_setup_draft()
	_tirer_files()


## Note un ordre ou une décision pour le replay, avant de l'exécuter.
func noter(nom: String, joueur := -1, args: Array = []) -> void:
	journal.append([pas, joueur, nom, args])


func is_ai(i: int) -> bool:
	return i >= 0 and ais[i] != null


func bump() -> void:
	for p in players:
		p.version += 1


func objective() -> int:
	return int(data["buildings"]["partie"]["objectif_reputation"])


# --- Hasard et cartes --------------------------------------------------------

func pick(list: Array, r: RandomNumberGenerator = null) -> Variant:
	return list[(r if r else rng).randi_range(0, list.size() - 1)]


func shuffle(a: Array, r: RandomNumberGenerator = null) -> void:
	var g := r if r else rng
	for i in range(a.size() - 1, 0, -1):
		var j := g.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func pick_weighted(dist: Dictionary, g: RandomNumberGenerator = null) -> String:
	var r := (g if g else rng).randf()
	for k in dist:
		r -= float(dist[k])
		if r < 0.0:
			return k
	return dist.keys()[0]


func is_positive(trait_id: String) -> bool:
	return positive_ids.has(trait_id)


## `faiblesse` (0 à 1, premiers tours du draft) : un défaut de plus et une qualité de moins, avec les
## probabilités de generation_draft > defauts_debut multipliées par elle.
func make_card(categorie: String, faiblesse := 0.0, r: RandomNumberGenerator = null) -> GameState.Card:
	var g := r if r else rng
	var W: Dictionary = data["workers"]
	var card := GameState.Card.new()
	card.id = next_card_id
	next_card_id += 1
	var perso := _next_perso(g)
	card.nom = perso["nom"]
	card.perso = perso["id"]
	card.metier = pick(W["metiers"].filter(func(m): return m["categorie"] == categorie), g)
	var gen: Dictionary = W["generation_traits"]
	var n_pos := int(pick_weighted(gen["nb_positifs"], g))
	var n_neg := int(pick_weighted(gen["nb_negatifs"], g))
	if faiblesse > 0.0:
		var D: Dictionary = W["generation_draft"].get("defauts_debut", {})
		if g.randf() < faiblesse * float(D.get("negatif_en_plus", 0.0)):
			n_neg += 1
		if n_pos > 0 and g.randf() < faiblesse * float(D.get("positif_en_moins", 0.0)):
			n_pos -= 1
	_draw_traits(card, W["traits_positifs"], n_pos, gen["exclusions"], g)
	_draw_traits(card, W["traits_negatifs"], n_neg, gen["exclusions"], g)
	return card


## Personnage d'une nouvelle carte : tous sortent une fois avant qu'un même visage revienne.
func _next_perso(g: RandomNumberGenerator = null) -> Dictionary:
	if perso_bag.is_empty():
		perso_bag = data["personnages"]["personnages"].duplicate()
		shuffle(perso_bag, g)
	return perso_bag.pop_back()


## Carte d'action (workers.json > cartes_action) : une carte du deck qui n'est pas un ouvrier.
func make_action(def: Dictionary) -> GameState.Card:
	var card := GameState.Card.new()
	card.id = next_card_id
	next_card_id += 1
	card.nom = def["nom"]
	card.action = def
	return card


## Tire des traits en respectant les exclusions et les catégories autorisées (Col blanc : cadres uniquement).
func _draw_traits(card: GameState.Card, pool: Array, count: int, exclusions: Array, g: RandomNumberGenerator = null) -> void:
	var cat: String = card.metier["categorie"]
	for i in count:
		var options: Array = pool.filter(func(t):
			return not card.traits.has(t["id"]) and not _excluded(t["id"], card.traits, exclusions) \
				and (not t.has("categories") or t["categories"].has(cat)))
		if not options.is_empty():
			card.traits.append(pick(options, g)["id"])


func _excluded(id: String, chosen: Array[String], exclusions: Array) -> bool:
	for pair in exclusions:
		if (pair[0] == id and chosen.has(pair[1])) or (pair[1] == id and chosen.has(pair[0])):
			return true
	return false


## Files du marché, tirées après la réserve du draft avec leur propre flux : la n-ième carte qui sort au marché est la
## même dans toutes les parties de même graine (et de même mode), quels que soient les achats.
func _tirer_files() -> void:
	var g := RandomNumberGenerator.new()
	g.seed = hash([seed_value, "files"])
	var m: Dictionary = data["buildings"]["marche"]
	for k in TAILLE_FILES:
		file_ouvriers.append(make_card(pick_weighted(m["categories"], g), 0.0, g))
	if not data["workers"]["cartes_action"].is_empty():
		for k in TAILLE_FILES:
			file_actions.append(pick(data["workers"]["cartes_action"], g))
	file_contrats = data["animals"]["animaux"].map(func(d): return d["id"])
	shuffle(file_contrats, g)


func _ouvrier_suivant() -> GameState.Card:
	if i_ouvriers < file_ouvriers.size():
		i_ouvriers += 1
		return file_ouvriers[i_ouvriers - 1]
	return make_card(pick_weighted(data["buildings"]["marche"]["categories"], rng_marche), 0.0, rng_marche)


func _action_suivante() -> GameState.Card:
	if i_actions < file_actions.size():
		i_actions += 1
		return make_action(file_actions[i_actions - 1])
	return make_action(pick(data["workers"]["cartes_action"], rng_marche))


func _espece(id: String) -> Dictionary:
	for d in data["animals"]["animaux"]:
		if d["id"] == id:
			return d
	return {}


# --- Draft par tours ---------------------------------------------------------
# Chaque tour révèle une carte de plus qu'il n'y a de joueurs. Les joueurs en prennent une chacun, à tour de rôle :
# le dernier a donc encore le choix entre deux cartes. Celle qui reste est défaussée. Le premier à choisir avance
# d'un joueur à chaque tour.

func _setup_draft() -> void:
	var gen: Dictionary = data["workers"]["generation_draft"]
	var per_player := int(gen["cartes_par_joueur"])
	var n := players.size()
	var k := draft_round_size()
	for i in per_player * k:
		# Les premiers tours sont plus faibles (plus de défauts), le dernier tour est normal.
		var faiblesse := 1.0 - float(i / k) / maxf(1.0, per_player - 1.0)
		draft_reserve.append(make_card(pick_weighted(gen["probabilites"]), faiblesse))
	var first := rng.randi_range(0, n - 1)
	for r in per_player:
		for p in n:
			draft_order.append((first + r + p) % n)
	_reveal_draft_round()
	bump()


## Nombre de cartes révélées à chaque tour.
func draft_round_size() -> int:
	return players.size() + 1


func draft_round() -> int:
	return draft_turn / players.size()


func draft_rounds() -> int:
	return draft_order.size() / players.size()


## Ordre de choix du tour en cours (index des joueurs).
func draft_round_order() -> Array[int]:
	var start := draft_round() * players.size()
	return draft_order.slice(start, start + players.size())


func _reveal_draft_round() -> void:
	var k := draft_round_size()
	draft_pool = draft_reserve.slice(0, k)
	draft_reserve = draft_reserve.slice(k)


func current_drafter() -> int:
	return draft_order[draft_turn] if draft_turn < draft_order.size() else -1


func pick_draft(card: GameState.Card) -> void:
	if phase != "draft" or not draft_pool.has(card):
		return
	var n := players.size()
	draft_pool.erase(card)
	drafted[current_drafter()].append(card)
	draft_turn += 1
	if draft_turn >= draft_order.size():
		draft_pool.clear()
		_finish_draft()
		return
	if draft_turn % n == 0:
		_reveal_draft_round()
	bump()


## Choix au draft pour le joueur qui a la main (utilisé par les IA, et par --autodraft pour l'humain).
func ai_choice() -> GameState.Card:
	var player := maxi(current_drafter(), 0)
	var best: GameState.Card = null
	var best_score := -INF
	for c in draft_pool:
		var s := draft_value(c, player) + rng.randf() * 0.5
		if s > best_score:
			best_score = s
			best = c
	return best


func draft_value(c: GameState.Card, player: int) -> float:
	var v: float = {"peu_qualifie": 1.0, "qualifie": 2.0, "cadre": 2.5}[c.metier["categorie"]]
	for t in c.traits:
		v += 0.6 if is_positive(t) else -0.6
	for o in drafted[player]:
		if o.metier["id"] == c.metier["id"]:
			v -= 0.4
	if is_ai(player):
		v += ais[player].card_bonus(c)
	return v


## Fait jouer toutes les IA du draft jusqu'au tour de l'humain (ou jusqu'à la fin).
func advance_ai_draft() -> void:
	while phase == "draft" and is_ai(current_drafter()):
		pick_draft(ai_choice())


## Objectifs des actionnaires : les mêmes pour tous, tirés une fois pour toutes.
func _tirer_objectifs() -> void:
	var O: Dictionary = data["buildings"]["objectifs"]
	var liste: Array = O["liste"].duplicate()
	shuffle(liste)
	objectifs = liste.slice(0, int(O["par_partie"]))


func _finish_draft() -> void:
	if objectifs.is_empty():
		_tirer_objectifs()
	for i in players.size():
		players[i].deck.assign(drafted[i])
		players[i]._shuffle(players[i].deck)
	phase = "day"
	_refresh_market(1, false)
	for p in players:
		p.say("Draft terminé : votre deck compte %d collaborateurs." % p.deck.size())
		p._start_day_player()
	pas_matin = pas
	journal_matin = journal.size()
	if autosave:
		Sauvegarde.ecrire(self)
	for ai in ais:
		if ai:
			ai.on_day_start()
	bump()


# --- Journée -----------------------------------------------------------------

func tick(dt: float) -> void:
	if phase != "day":
		return
	pas += 1
	time += dt
	for i in players.size():
		players[i]._tick_player(dt)
		if ais[i]:
			ais[i].update(dt)
	if time >= day_length:
		end_day()


# --- Nuit et marché ----------------------------------------------------------

func end_day() -> void:
	if phase != "day":
		return
	for ai in ais:
		if ai:
			ai.on_day_end()
	phase = "night"
	for p in players:
		p._end_day_player()
	# Ordre de passage : influence (cachée, au dixième près, comme affichée) ; à égalité, le hasard.
	var keys := {}
	for i in players.size():
		keys[i] = [snappedf(players[i].influence, 0.1), rng.randf()]
	var order: Array = range(players.size())
	order.sort_custom(func(a, b):
		var ka: Array = keys[a]
		var kb: Array = keys[b]
		for k in ka.size():
			if not is_equal_approx(ka[k], kb[k]):
				return ka[k] > kb[k]
		return false)
	night_order.assign(order)
	for d in market_contracts:
		offres[d["id"]] = int(offres.get(d["id"], 0)) + 1
	for p in players:
		p.verifier_objectifs()
	# Prestige politique : le 1er puis le 2e en influence gagnent un peu de réputation (s'ils ont fait du lobbying)
	var R: Dictionary = data["buildings"]["reputation_autres"]
	for k in mini(order.size(), R["prestige_politique"].size()):
		var p: GameState = players[order[k]]
		var pts := float(R["prestige_politique"][k])
		if p.influence >= float(R["influence_min"]):
			p.rep_points += pts
			p.add_rep_source("prestige", pts)
			p.night_report["prestige"] = pts
			if k == 0:
				p.annonce("prestige", {"effet": "+%d de réputation" % int(pts)})
	# Plan de relance : les joueurs derrière le premier paient moins cher ce soir (GameState.remise_relance)
	for p in players:
		var remise := p.remise_relance()
		if remise > 0.0:
			p.night_report["relance"] = remise
			p.annonce("relance", {"remise": "%d %%" % roundi(remise * 100.0)}, "Plan de relance : −%d %% sur vos achats ce soir." % roundi(remise * 100.0))
	_annoncer_rival()
	night_turn = 0
	night_stage = NIGHT_STAGES[0]
	night_taken.clear()
	log.clear()
	for p in players:
		p.recruited_tonight = false
		p.hippo_used_tonight = false
		p.bought_worker = false
		p.bought_action = false
		p.contracts_tonight = 0
		p.night_action_used = false
	# Bonus de nuit : seul le premier en influence choisit, et le bonus s'applique à tous le lendemain.
	var pool: Array = data["events"]["bonus_nuit"].duplicate()
	shuffle(pool)
	bonus_offer = pool.slice(0, int(data["events"].get("bonus_proposes", 3)))
	bonus_choice = {}
	_check_game_over()
	_record_history()
	bump()


func _check_game_over() -> void:
	var best := -1
	for i in players.size():
		if best < 0 or players[i].reputation() > players[best].reputation() \
			or (players[i].reputation() == players[best].reputation() and players[i].money > players[best].money):
			best = i
	if players[best].reputation() >= objective() or day >= int(data["buildings"]["partie"]["jour_max"]):
		game_over = true
		winner = best


func _record_history() -> void:
	var row := []
	for p in players:
		row.append({"day": day, "rep": p.reputation(), "money": p.money, "animals": p.animals.size(),
			"employees": p.employees(), "influence": p.influence, "visitors": p.night_report.get("income", {}).get("visitors", 0)})
	history.append(row)


func market_stage() -> bool:
	return phase == "night" and night_stage in ["contrats", "ouvriers", "cartes"]


## Joueur dont c'est le tour au marché de l'étape en cours (-1 hors des étapes de marché).
func current_buyer() -> int:
	if not market_stage() or night_turn >= night_order.size():
		return -1
	return night_order[night_turn]


## Le joueur dont c'est le tour a fini ses achats de l'étape : au suivant, ou à l'étape suivante.
func pass_turn() -> void:
	if not market_stage():
		return
	night_turn += 1
	if night_turn >= night_order.size():
		night_turn = 0
		_next_stage()
	bump()


func _next_stage() -> void:
	night_stage = NIGHT_STAGES[mini(NIGHT_STAGES.find(night_stage) + 1, NIGHT_STAGES.size() - 1)]
	if night_stage == "bonus" and is_ai(influence_leader()):
		ais[influence_leader()].on_night_bonus()
	if night_stage == "equipe":
		# Chacun gère son équipe en parallèle : les IA le font tout de suite.
		for ai in ais:
			if ai:
				ai.on_night_team()
	bump()


## Fin de l'étape Bonus : le bonus choisi (ou le premier proposé) vaudra pour tous demain.
func confirm_bonus() -> void:
	if phase != "night" or night_stage != "bonus":
		return
	if bonus_choice.is_empty() and not bonus_offer.is_empty():
		bonus_choice = bonus_offer[0]
	_next_stage()


func record_purchase(player: int, obj: Variant) -> void:
	night_taken.append({"etape": night_stage, "joueur": player, "objet": obj})
	players[player].verifier_objectifs()


## Fait avancer la nuit d'un pas quand c'est à une IA d'agir : achats de l'IA dont c'est le tour, ou bonus déjà choisi
## par une IA. Faux si c'est au joueur humain (ou à l'étape Équipe, que chacun termine seul).
func step_night() -> bool:
	if phase != "night" or game_over:
		return false
	if market_stage():
		var i := current_buyer()
		if i < 0 or not is_ai(i):
			return false
		ais[i].on_night_stage(night_stage)
		pass_turn()
		return true
	if night_stage == "bonus" and is_ai(influence_leader()):
		confirm_bonus()
		return true
	return false


## Termine les étapes de la nuit d'un coup : les IA jouent, le joueur humain passe ce qui reste.
func finish_night() -> void:
	while phase == "night" and night_stage != "equipe" and not game_over:
		if not step_night():
			if market_stage():
				pass_turn()
			else:
				confirm_bonus()


## Tests : avance la nuit jusqu'à l'étape voulue, puis jusqu'au tour du joueur `who` (les autres jouent ou passent).
func night_goto(stage: String, who := 0) -> void:
	while phase == "night" and night_stage != stage and night_stage != "equipe":
		if not step_night():
			if market_stage():
				pass_turn()
			else:
				confirm_bonus()
	while market_stage() and current_buyer() != who:
		if not step_night():
			pass_turn()


## Le premier en influence cette nuit : lui seul choisit le bonus du lendemain.
func influence_leader() -> int:
	return night_order[0] if not night_order.is_empty() else -1


## Un concurrent vient de passer devant le joueur humain : Hubert le fait savoir, une fois par concurrent en tête.
func _annoncer_rival() -> void:
	for p in players:
		if is_ai(p.index):
			continue
		var best := -1
		for k in players.size():
			if k != p.index and (best < 0 or players[k].rep_points > players[best].rep_points):
				best = k
		if best < 0 or players[best].rep_points <= p.rep_points:
			rival_en_tete = -1
		elif best != rival_en_tete:
			rival_en_tete = best
			p.annonce("rival_devant", {"rival": names[best]})


## Un joueur a quitté la partie : une IA reprend son zoo, là où il en était.
func remplacer_par_ia(i: int) -> void:
	if ais[i] != null:
		return
	ais[i] = AIController.new(self, players[i], {})
	ais[i].reprendre_zoo()


func start_next_day() -> void:
	if phase != "night" or game_over:
		return
	finish_night()
	# Bonus du lendemain, le même pour tous : celui du premier en influence, ou le premier proposé s'il n'a pas choisi.
	if bonus_choice.is_empty() and not bonus_offer.is_empty():
		bonus_choice = bonus_offer[0]
	for p in players:
		p.night_bonus = bonus_choice
	day += 1
	time = 0.0
	_refresh_market(day, true)
	phase = "day"
	_draw_event()
	for p in players:
		p._start_day_player()
	_apply_event()
	if current_event.is_empty():
		for p in players:
			p.annonce("matin")
	pas_matin = pas
	journal_matin = journal.size()
	if autosave:
		Sauvegarde.ecrire(self)
	for ai in ais:
		if ai:
			ai.on_day_start()
	bump()


## Tire l'événement du jour (à partir du jour 2).
func _draw_event() -> void:
	current_event = {}
	var E: Dictionary = data["events"]
	var g := _flux_du_jour("evenement")
	if day >= 2 and g.randf() < float(E["proba_evenement"]):
		# Pas d'épidémie tant que personne n'a d'animal.
		var possibles: Array = E["evenements"]
		if not players.any(func(p): return p.animals.any(func(a): return a.arrived)):
			possibles = possibles.filter(func(e): return not e["effets"].get("epidemie", false))
		current_event = pick(possibles, g)


## Hasard propre à un jour : même tirage pour toutes les parties de même graine, quoi qu'il se soit passé avant.
func _flux_du_jour(nom: String) -> RandomNumberGenerator:
	var g := RandomNumberGenerator.new()
	g.seed = hash([seed_value, day, nom])
	return g


## Effets immédiats de l'événement, après le début de journée de chaque joueur.
func _apply_event() -> void:
	var fx: Dictionary = current_event.get("effets", {})
	for p in players:
		if fx.has("argent"):
			p.money += float(fx["argent"])
		if fx.has("chantiers"):
			for s in p.sites:
				if not s.done:
					s.work *= float(fx["chantiers"])
		if fx.get("epidemie", false):
			var arrived := p.animals.filter(func(a): return a.arrived)
			if not arrived.is_empty():
				var victim = pick(arrived, p.rng)
				victim.sick = true
				victim.heal = 0.0
		# Une épidémie ne concerne que ceux qui ont des animaux.
		if not current_event.is_empty() and (not fx.get("epidemie", false) or p.animals.any(func(a): return a.arrived)):
			p.annonce("ev_" + str(current_event["id"]), {"effet": current_event["texte"]}, "Événement : %s. %s" % [current_event["nom"], current_event["texte"]])


## Fait tourner le marché : retire une carte restante au hasard de chaque rangée, puis complète.
func _refresh_market(for_day: int, rotate: bool) -> void:
	var m: Dictionary = data["buildings"]["marche"]
	if rotate:
		if not market_workers.is_empty():
			market_workers.remove_at(rng_marche.randi_range(0, market_workers.size() - 1))
		if not market_actions.is_empty():
			market_actions.remove_at(rng_marche.randi_range(0, market_actions.size() - 1))
	while market_workers.size() < int(m["ouvriers"]):
		market_workers.append(_ouvrier_suivant())
	while market_actions.size() < int(m.get("actions", 0)):
		market_actions.append(_action_suivante())
	# Un seul contrat par espèce dans la partie : une espèce à l'étalage, ou qu'un joueur détient (contrat, réservation,
	# animal), ne peut pas sortir. Les places libres sont tirées au hasard parmi les autres, sans préférence de rareté.
	var pris := {}
	for d in market_contracts:
		pris[d["id"]] = true
	for p in players:
		for d in p.contracts:
			pris[d["id"]] = true
		for r in p.pending_installs:
			pris[r["def"]["id"]] = true
		for a in p.animals:
			pris[a.def["id"]] = true
	# Les espèces sortent dans l'ordre de file_contrats (la première permise ce jour-là).
	var paliers: Dictionary = data["animals"]["paliers"]
	var k := 0
	while market_contracts.size() < int(m["contrats"]) and k < file_contrats.size():
		var d := _espece(file_contrats[k])
		if d.is_empty() or pris.has(d["id"]):
			file_contrats.remove_at(k)
		elif int(paliers[d["palier"]]["jour_min"]) <= for_day:
			market_contracts.append(d)
			file_contrats.remove_at(k)
		else:
			k += 1
	bump()


## Casse les références circulaires partie <-> joueurs <-> IA (sinon la mémoire n'est pas libérée).
func dispose() -> void:
	for p in players:
		p.mt = null
	ais.clear()
	players.clear()


## Partie IA contre IA jusqu'à la fin, sans affichage (simulations d'équilibrage).
func run_headless(dt := 0.5) -> void:
	advance_ai_draft()
	while not game_over:
		if phase == "day":
			tick(dt)
		elif phase == "night":
			start_next_day()
