class_name Match
extends RefCounted
## Une partie : les joueurs (humain et IA), l'horloge commune, le draft par tours et le marché de nuit partagés.
## Chaque joueur (GameState) a sa propre copie de la carte, générée avec la même graine.

const PRENOMS: Array[String] = ["Léa", "Hugo", "Jade", "Louis", "Emma", "Nathan", "Inès", "Gabin", "Chloé", "Tom",
	"Lina", "Jules", "Manon", "Noah", "Zoé", "Adam", "Rose", "Paul", "Alice", "Sacha", "Lou", "Malo", "Nina",
	"Théo", "Elsa", "Victor", "Margot", "Arthur", "Camille", "Basile"]

var data: Dictionary
var seed_value := 0
var rng := RandomNumberGenerator.new()
var players: Array[GameState] = []
var ais: Array = []  # AIController, ou null pour le joueur humain
var names: Array[String] = []
var day := 1
var time := 0.0
var day_length := 300.0
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
var night_order: Array[int] = []
var night_turn := 0  # position dans night_order du joueur qui achète
var log: Array[String] = []  # achats des IA de la nuit
var current_event := {}  # événement du jour (commun à tous les joueurs)
var bonus_offer: Array = []  # bonus de nuit proposés (n + 1)
var bonus_taken := {}  # id du bonus -> index du joueur
var history: Array = []  # statistiques par jour et par joueur (simulations)


## human = index du joueur humain, ou -1 pour une partie entièrement jouée par des IA.
func _init(game_data: Dictionary, map_seed: int, nb_players := 4, human := 0, strategies: Array = []) -> void:
	data = game_data
	seed_value = map_seed
	rng.seed = map_seed ^ 0x5bd1e995
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
		if i == human:
			ais.append(null)
			names.append("Vous")
		else:
			var strat: Dictionary = strategies[i] if i < strategies.size() and strategies[i] != null else {}
			ais.append(AIController.new(self, players[i], strat))
			ia_count += 1
			names.append("IA %d" % ia_count if strat.is_empty() else "IA %d (%s)" % [ia_count, strat.get("nom", "?")])
	_setup_draft()


func is_ai(i: int) -> bool:
	return i >= 0 and ais[i] != null


func bump() -> void:
	for p in players:
		p.version += 1


func objective() -> int:
	return int(data["buildings"]["partie"]["objectif_reputation"])


# --- Hasard et cartes --------------------------------------------------------

func pick(list: Array) -> Variant:
	return list[rng.randi_range(0, list.size() - 1)]


func shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func pick_weighted(dist: Dictionary) -> String:
	var r := rng.randf()
	for k in dist:
		r -= float(dist[k])
		if r < 0.0:
			return k
	return dist.keys()[0]


func is_positive(trait_id: String) -> bool:
	return positive_ids.has(trait_id)


func make_card(categorie: String) -> GameState.Card:
	var W: Dictionary = data["workers"]
	var card := GameState.Card.new()
	card.id = next_card_id
	next_card_id += 1
	card.nom = pick(PRENOMS)
	card.metier = pick(W["metiers"].filter(func(m): return m["categorie"] == categorie))
	var gen: Dictionary = W["generation_traits"]
	_draw_traits(card, W["traits_positifs"], int(pick_weighted(gen["nb_positifs"])), gen["exclusions"])
	_draw_traits(card, W["traits_negatifs"], int(pick_weighted(gen["nb_negatifs"])), gen["exclusions"])
	return card


## Tire des traits en respectant les exclusions et les catégories autorisées (Col blanc : cadres uniquement).
func _draw_traits(card: GameState.Card, pool: Array, count: int, exclusions: Array) -> void:
	var cat: String = card.metier["categorie"]
	for i in count:
		var options: Array = pool.filter(func(t):
			return not card.traits.has(t["id"]) and not _excluded(t["id"], card.traits, exclusions) \
				and (not t.has("categories") or t["categories"].has(cat)))
		if not options.is_empty():
			card.traits.append(pick(options)["id"])


func _excluded(id: String, chosen: Array[String], exclusions: Array) -> bool:
	for pair in exclusions:
		if (pair[0] == id and chosen.has(pair[1])) or (pair[1] == id and chosen.has(pair[0])):
			return true
	return false


# --- Draft par tours ---------------------------------------------------------
# Chaque tour révèle `cartes_par_tour` cartes (au moins une par joueur). Les joueurs en prennent une
# chacun, à tour de rôle ; s'il ne reste qu'une carte pour le dernier joueur, elle lui revient d'office.
# Les cartes non prises sont défaussées. Le premier à choisir avance d'un joueur à chaque tour.

func _setup_draft() -> void:
	var gen: Dictionary = data["workers"]["generation_draft"]
	var per_player := int(gen["cartes_par_joueur"])
	var n := players.size()
	for i in per_player * draft_round_size():
		draft_reserve.append(make_card(pick_weighted(gen["probabilites"])))
	var first := rng.randi_range(0, n - 1)
	for r in per_player:
		for p in n:
			draft_order.append((first + r + p) % n)
	_reveal_draft_round()
	bump()


## Nombre de cartes révélées à chaque tour.
func draft_round_size() -> int:
	return maxi(int(data["workers"]["generation_draft"].get("cartes_par_tour", 4)), players.size())


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
	# Dernier joueur du tour face à une seule carte : elle lui revient d'office.
	if draft_turn % n != 0 and draft_pool.size() == 1:
		drafted[current_drafter()].append(draft_pool.pop_back())
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


func _finish_draft() -> void:
	for i in players.size():
		players[i].deck.assign(drafted[i])
		players[i]._shuffle(players[i].deck)
	phase = "day"
	_refresh_market(1, false)
	for p in players:
		p.say("Draft terminé : votre deck compte %d ouvriers." % p.deck.size())
		p._start_day_player()
	for ai in ais:
		if ai:
			ai.on_day_start()
	bump()


# --- Journée -----------------------------------------------------------------

func tick(dt: float) -> void:
	if phase != "day":
		return
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
	# Ordre de passage : influence (cachée), puis la plus grande superficie de zoo, puis le hasard.
	var keys := {}
	for i in players.size():
		keys[i] = [players[i].influence, players[i].zoo_area(), rng.randf()]
	var order: Array = range(players.size())
	order.sort_custom(func(a, b):
		var ka: Array = keys[a]
		var kb: Array = keys[b]
		for k in 3:
			if not is_equal_approx(ka[k], kb[k]):
				return ka[k] > kb[k]
		return false)
	night_order.assign(order)
	night_turn = 0
	log.clear()
	for p in players:
		p.bought_worker = false
		p.contracts_tonight = 0
		p.night_action_used = false
	var pool: Array = data["events"]["bonus_nuit"].duplicate()
	shuffle(pool)
	bonus_offer = pool.slice(0, players.size() + 1)
	bonus_taken.clear()
	_check_game_over()
	_record_history()
	if not game_over:
		_advance_night()
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


## Les IA dont c'est le tour achètent, jusqu'au tour du joueur humain.
func _advance_night() -> void:
	while night_turn < night_order.size() and is_ai(night_order[night_turn]):
		ais[night_order[night_turn]].on_night()
		night_turn += 1
	bump()


func current_buyer() -> int:
	return night_order[night_turn] if night_turn < night_order.size() else -1


func start_next_day() -> void:
	if phase != "night" or game_over:
		return
	# Le joueur humain a fini ses achats : les IA suivantes jouent à leur tour.
	if night_turn < night_order.size() and not is_ai(night_order[night_turn]):
		night_turn += 1
	_advance_night()
	day += 1
	time = 0.0
	_refresh_market(day, true)
	phase = "day"
	_draw_event()
	for p in players:
		p._start_day_player()
	_apply_event()
	for ai in ais:
		if ai:
			ai.on_day_start()
	bump()


## Tire l'événement du jour (à partir du jour 2).
func _draw_event() -> void:
	current_event = {}
	var E: Dictionary = data["events"]
	if day >= 2 and rng.randf() < float(E["proba_evenement"]):
		current_event = pick(E["evenements"])


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
				p.sick_animal = pick(arrived)
		if not current_event.is_empty():
			p.say("Événement : %s. %s" % [current_event["nom"], current_event["texte"]])


## Fait tourner le marché : retire une carte restante au hasard de chaque rangée, puis complète.
func _refresh_market(for_day: int, rotate: bool) -> void:
	var m: Dictionary = data["buildings"]["marche"]
	if rotate:
		if not market_workers.is_empty():
			market_workers.remove_at(rng.randi_range(0, market_workers.size() - 1))
		if not market_contracts.is_empty():
			market_contracts.remove_at(rng.randi_range(0, market_contracts.size() - 1))
	while market_workers.size() < int(m["ouvriers"]):
		market_workers.append(make_card(pick_weighted(m["categories"])))
	var in_market := {}
	for d in market_contracts:
		in_market[d["id"]] = true
	var paliers: Dictionary = data["animals"]["paliers"]
	var eligible: Array = data["animals"]["animaux"].filter(func(d):
		return int(paliers[d["palier"]]["jour_min"]) <= for_day and not in_market.has(d["id"]))
	shuffle(eligible)
	while market_contracts.size() < int(m["contrats"]) and not eligible.is_empty():
		market_contracts.append(eligible.pop_back())
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
