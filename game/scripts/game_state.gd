class_name GameState
extends RefCounted
## État et simulation d'UN joueur : sa carte, son deck, ses ouvriers, ses chantiers, ses animaux et son argent.
## L'horloge, le draft et le marché sont partagés par la partie (Match).
## La simulation avance par ticks fixes, indépendamment de l'affichage.

const TICK := 0.1
const HUMAIN := 0
const LOBBYING_PAR_MINUTE := 1.0


class Card:
	var id := 0
	var nom := ""
	var metier: Dictionary
	var traits: Array[String] = []
	var niveau := 1
	var jours_travailles := 0
	var deployed := false
	var upgrades: Array = []  # effets des améliorations achetées (vitesse, defaut, specialite, salaire)
	var upgrade_names: Array[String] = []


class Worker:
	var card: Card
	var pos := Vector2.ZERO  # en cases ; le centre d'une case est à +0.5
	var path: Array[Vector2i] = []
	var task := {}  # vide = aucune tâche
	var carry := 0.0
	var carry_type := ""
	var minute_clock := 0.0
	var pause_left := 0.0
	var offmap := false  # parti en lobbying par l'accès route
	var unpaid := false  # déployé gratuitement : rendement réduit

	func tile() -> Vector2i:
		return Vector2i(floori(pos.x), floori(pos.y))


## Chantier ou bâtiment terminé (kind = "batiment"), ou aménagement de terrain en cours (kind = "amenagement").
class Site:
	var id := 0
	var kind := ""
	var def: Dictionary
	var rect := Rect2i()
	var work := 0.0
	var done := false
	var paid := {}

	func def_id() -> String:
		return str(def["id"])

	func travail() -> float:
		return float(def["travail"])

	func type_travail() -> String:
		return "amenager" if kind == "amenagement" else str(def["type_travail"])


## Animal installé dans un enclos (il arrive la nuit suivant l'installation).
class Animal:
	var def: Dictionary
	var tiles: Array[Vector2i] = []
	var arrived := false
	var fed := true


var mt: Match
var index := 0
var data: Dictionary
var seed_value := 0
var rng := RandomNumberGenerator.new()
var map: GameMap
var traits_by_id := {}
var positive_ids := {}
var money := 0.0
var influence := 0.0
var stock := {"bois": 0.0, "pierre": 0.0, "or": 0.0}

# Partagés par la partie
var day: int:
	get:
		return mt.day
var time: float:
	get:
		return mt.time
var day_length: float:
	get:
		return mt.day_length
var phase: String:  # draft, day, night
	get:
		return mt.phase
var game_over: bool:
	get:
		return mt.game_over
var market_workers: Array:
	get:
		return mt.market_workers
var market_contracts: Array:
	get:
		return mt.market_contracts
var night_order: Array[int]:
	get:
		return mt.night_order
var mine_built: bool:
	get:
		return sites.any(func(s): return s.done and s.def_id() == "mine")

var deck: Array[Card] = []
var discard: Array[Card] = []
var hand: Array[Card] = []
var workers: Array[Worker] = []
var messages: Array[Dictionary] = []
var day_stats := {}
var night_report := {}
var next_id := 1
var version := 0  # incrémenté à chaque changement visible dans les cartes (pour rafraîchir l'interface)

var sites: Array[Site] = []
var occupancy := {}  # Vector2i -> Site
var terrain_changed: Array[Vector2i] = []  # cases à redessiner par l'affichage

var contracts: Array = []  # contrats achetés, en attente d'un enclos
var animals: Array[Animal] = []
var bought_worker := false
var contracts_tonight := 0  # contrats achetés cette nuit
var drh_available := 0
var free_used_today := false
var cared_today := {}  # Animal -> true (un Soigneur s'en est occupé aujourd'hui)
var staffed_time := {}  # Site (entrée, boutique) -> secondes de présence d'un ouvrier aujourd'hui
var vendeur_time := {}  # Site (boutique) -> secondes de présence d'un Vendeur aujourd'hui
var night_bonus := {}  # bonus choisi cette nuit (actif demain)
var day_bonus := {}  # bonus actif aujourd'hui
var sick_animal: Animal = null  # événement « Épidémie »
var night_action_used := false
var pending_upgrade := {}  # {"card": Card, "options": [...]} pendant le choix d'une amélioration
var _zoo_cache_version := -1
var _zoo_cache := {}

# Visiteurs (simulés pendant la journée)
var rep_points := 0.0  # réputation accumulée (condition de victoire)
var road_visitors := PackedFloat32Array()  # distance parcourue sur le chemin Accès -> Entrée
var visitor_queue := 0  # visiteurs qui attendent au guichet
var in_zoo: Array = []  # [{"t": temps restant, "pos": Vector2}]
var visit := {}  # compteurs du jour
var _spawn_acc := 0.0
var _admit_acc := 0.0
var _path_cache_version := -1
var _path_cache: Array[Vector2i] = []


func _init(game_data: Dictionary, map_seed: int, the_match: Match, player_index: int) -> void:
	mt = the_match
	index = player_index
	data = game_data
	seed_value = map_seed
	rng.seed = (map_seed ^ 0x9e3779b9) + player_index * 7919
	map = MapGenerator.generate(data["buildings"], map_seed)
	for t in data["workers"]["traits_positifs"]:
		traits_by_id[t["id"]] = t
		positive_ids[t["id"]] = true
	for t in data["workers"]["traits_negatifs"]:
		traits_by_id[t["id"]] = t
	var partie: Dictionary = data["buildings"]["partie"]
	money = float(partie["argent_depart"])
	for k in partie.get("stock_depart", {}):
		stock[k] = float(partie["stock_depart"][k])
	_reset_day_stats()


# --- Hasard ------------------------------------------------------------------

func _pick(list: Array) -> Variant:
	return list[rng.randi_range(0, list.size() - 1)]


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func _pick_weighted(dist: Dictionary) -> String:
	var r := rng.randf()
	for k in dist:
		r -= float(dist[k])
		if r < 0.0:
			return k
	return dist.keys()[0]


# --- Cartes ouvriers ---------------------------------------------------------

func make_card(categorie: String) -> Card:
	return mt.make_card(categorie)


func trait_defs(card: Card) -> Array:
	return card.traits.map(func(id): return traits_by_id[id])


func is_positive(trait_id: String) -> bool:
	return positive_ids.has(trait_id)


# --- Modificateurs : événement du jour et bonus de nuit ----------------------

func event_effects() -> Dictionary:
	return mt.current_event.get("effets", {}) if mt else {}


func bonus_effects() -> Dictionary:
	return day_bonus.get("effets", {})


## Multiplicateur de productivité du jour pour une tâche (événement + bonus de nuit).
func task_mult(task: String) -> float:
	var b := bonus_effects()
	var m := float(event_effects().get("productivite", 1.0)) * float(b.get(task, 1.0))
	if task.begins_with("construire_"):
		m *= float(b.get("construire", 1.0))
	return m


func speed_mult() -> float:
	return float(event_effects().get("vitesse", 1.0)) * float(bonus_effects().get("vitesse", 1.0))


func salary(card: Card) -> int:
	var s := int(card.metier["salaire"]) + (card.niveau - 1) * int(data["workers"]["regles"].get("salaire_par_niveau", 0))
	for t in trait_defs(card):
		s += int(t["effet"].get("salaire", 0))
	for u in card.upgrades:
		s += int(u.get("salaire", 0))
	s += int(event_effects().get("salaire", 0))
	return maxi(0, s)


func speed(card: Card) -> float:
	var s := float(card.metier["vitesse"])
	for t in trait_defs(card):
		s *= float(t["effet"].get("vitesse", 1.0))
	for u in card.upgrades:
		s *= float(u.get("vitesse", 1.0))
	return s


func efficiency(card: Card, task: String) -> float:
	var eff: Dictionary = card.metier["efficacite"]
	var base: float
	if eff.has(task):
		base = float(eff[task])
	elif task == "lobbying":
		base = float(data["workers"]["regles"]["efficacite_lobbying_defaut"])
	else:
		base = float(eff["defaut"])
		if card.traits.has("polyvalent"):
			base = maxf(base, 1.2)
	for t in trait_defs(card):
		var e: Dictionary = t["effet"]
		base *= float(e.get("defaut", 1.0)) * float(e.get(task, 1.0))
		if task.begins_with("construire_"):
			base *= float(e.get("construire", 1.0))
	# Expérience : +10 % par niveau au-delà du premier, puis améliorations achetées.
	base *= 1.0 + float(data["workers"]["regles"].get("bonus_par_niveau", 0.0)) * (card.niveau - 1)
	for u in card.upgrades:
		base *= float(u.get("defaut", 1.0))
		if eff.has(task):
			base *= float(u.get("specialite", 1.0))
	return base


func auras_of(card: Card) -> Array:
	var out := []
	if card.metier.has("aura"):
		out.append(card.metier["aura"])
	for t in trait_defs(card):
		if t.has("aura"):
			out.append(t["aura"])
	return out


## Bonus de productivité reçu des AUTRES ouvriers présents sur la carte (Charismatique, Contremaître, Rabat-joie…).
func aura_mult(w: Worker) -> float:
	if w.offmap:
		return 1.0
	var bonus := 0.0
	for o in workers:
		if o == w or o.offmap:
			continue
		for a in auras_of(o.card):
			if o.pos.distance_to(w.pos) <= float(a["rayon"]) + 0.01:
				bonus += float(a["bonus"])
	return maxf(0.1, 1.0 + bonus)


func efficiency_at(w: Worker, task: String) -> float:
	return efficiency(w.card, task) * aura_mult(w) * unpaid_mult(w) * task_mult(task)


func unpaid_mult(w: Worker) -> float:
	return float(data["workers"]["regles"]["deploiement_gratuit"]["rendement"]) if w.unpaid else 1.0


func free_deploy_available() -> bool:
	return phase == "day" and not free_used_today


func carry_capacity(card: Card) -> int:
	return int(data["buildings"]["extraction"]["capacite_portage"]) + int(card.metier.get("capacite_portage", 0))


func draw_hand() -> void:
	var size := int(data["workers"]["regles"]["taille_main"])
	while hand.size() < size:
		if deck.is_empty():
			if discard.is_empty():
				break
			deck.assign(discard)
			discard.clear()
			_shuffle(deck)
		hand.append(deck.pop_back())
	version += 1


# --- Déploiement et ordres ---------------------------------------------------

func say(text: String) -> void:
	messages.append({"text": text, "at": Time.get_ticks_msec()})


## Déploie une carte de la main. Gratuit : sans salaire mais à 25 % de rendement (un par jour).
func deploy(card: Card, free := false) -> bool:
	if phase != "day" or card.deployed:
		return false
	if free:
		if free_used_today:
			return false
		free_used_today = true
	else:
		var cost := salary(card)
		if money < cost:
			say("Pas assez d'argent pour payer %s (%d)." % [card.nom, cost])
			return false
		money -= cost
	card.deployed = true
	var w := Worker.new()
	w.card = card
	w.unpaid = free
	w.pos = Vector2(map.camp.get_center()) + Vector2(0.5, 0.5)
	workers.append(w)
	version += 1
	return true


func worker_of(card: Card) -> Worker:
	for w in workers:
		if w.card == card:
			return w
	return null


func _set_path(w: Worker, target: Vector2i) -> bool:
	_unstick(w)
	var p = map.find_path(w.tile(), target)
	if p == null:
		say("%s ne trouve pas de chemin." % w.card.nom)
		w.task = {}
		w.path.clear()
		return false
	w.path.assign(p)
	return true


func depots() -> Array[Rect2i]:
	var out: Array[Rect2i] = [map.camp]
	for s in sites:
		if s.done and s.def_id() == "entrepot":
			out.append(s.rect)
	return out


func in_depot(t: Vector2i) -> bool:
	return depots().any(func(r): return r.has_point(t))


## Poste fixe : le Marchand au comptoir du camp, le Vendeur à la boutique, le Soigneur dans un enclos.
func _station(w: Worker, kind: String, obj, tile: Vector2i) -> void:
	w.task = {"type": "station", "kind": kind, "obj": obj, "tile": tile}
	_set_path(w, tile)


func _go_to_depot(w: Worker) -> void:
	w.task["phase"] = "to_depot"
	var best := map.camp
	for r in depots():
		if w.pos.distance_squared_to(Vector2(r.get_center())) < w.pos.distance_squared_to(Vector2(best.get_center())):
			best = r
	_set_path(w, best.get_center())


## Un ouvrier parti en lobbying revient sur la carte par l'accès route.
func _bring_back(w: Worker) -> void:
	if not w.offmap:
		return
	w.offmap = false
	w.pos = Vector2(map.exit_tile) + Vector2(0.5, 0.5)
	w.path.clear()
	w.task = {}
	version += 1


func recall(w: Worker) -> void:
	if w.offmap:
		_bring_back(w)
		say("%s revient par la route d'accès." % w.card.nom)


func order(targets: Array, target: Vector2i) -> void:
	if phase != "day" or not map.in_bounds(target.x, target.y):
		return
	var site := site_at(target)
	for w: Worker in targets:
		_bring_back(w)
		w.pause_left = 0.0
		if target == map.exit_tile:
			w.task = {"type": "lobby", "phase": "to_exit"}
			_set_path(w, target)
			continue
		if site and not site.done:
			if w.card.traits.has("col_blanc"):
				say("%s est un col blanc : il refuse le travail manuel." % w.card.nom)
				continue
			if site.kind == "amenagement" and not can_landscape(w.card):
				say("Seuls les Paysagistes et Terrassiers aménagent le terrain (%s est %s)." % [w.card.nom, w.card.metier["nom"]])
				continue
			w.task = {"type": "build", "site": site}
			_path_to_site(w, site)
			continue
		var job: String = w.card.metier["id"]
		if site and site.done and site.def_id() == "entree":
			_station(w, "ticket", site, target)
			continue
		if site and site.done and site.def_id() == "boutique":
			_station(w, "shop", site, target)
			if job != "vendeur":
				say("Seul un Vendeur de souvenirs double les ventes de la boutique.")
			continue
		if map.in_camp(target.x, target.y) and job == "marchand":
			_station(w, "trade", null, target)
			continue
		var animal := animal_at(target)
		if animal and job == "soigneur":
			_station(w, "care", animal, target)
			continue
		var tgt := target
		if site and site.def_id() == "mine":
			for g in map.golds:
				if site.rect.has_point(g):
					tgt = g
		var res := map.extractible(tgt.x, tgt.y)
		if res != "":
			if res == "or" and not mine_ready(tgt):
				say("Construisez d'abord une mine d'or sur ce gisement.")
				continue
			if w.card.traits.has("col_blanc"):
				say("%s est un col blanc : il refuse le travail manuel." % w.card.nom)
				continue
			w.task = {"type": "extract", "res": res, "target": tgt, "phase": "to_resource"}
			if w.carry > 0.0 and w.carry_type != res:
				_go_to_depot(w)
			else:
				_set_path(w, tgt)
		elif map.passable(target.x, target.y):
			w.task = {}
			_set_path(w, target)
		else:
			say("Case infranchissable.")
			return


# --- Simulation --------------------------------------------------------------

## Avance toute la partie (tous les joueurs) : raccourci pratique pour les tests.
func tick(dt: float) -> void:
	mt.tick(dt)


func _tick_player(dt: float) -> void:
	for w in workers:
		_update_worker(w, dt)
	_update_visitors(dt)


func _move(w: Worker, dt: float) -> void:
	var budget := dt
	while not w.path.is_empty() and budget > 0.0:
		var t := w.tile()
		var spd := speed(w.card) * map.move_speed(t.x, t.y) * speed_mult()
		var target := Vector2(w.path[0]) + Vector2(0.5, 0.5)
		var dist := w.pos.distance_to(target)
		var step := spd * budget
		if step >= dist:
			w.pos = target
			w.path.remove_at(0)
			budget -= dist / spd
		else:
			w.pos += (target - w.pos) / dist * step
			budget = 0.0


func lobbying_rate(card: Card) -> float:
	return LOBBYING_PAR_MINUTE * efficiency(card, "lobbying") / 60.0


func _update_worker(w: Worker, dt: float) -> void:
	if w.offmap:
		var gain := lobbying_rate(w.card) * unpaid_mult(w) * float(bonus_effects().get("lobbying", 1.0)) * dt
		influence += gain
		day_stats["influence"] += gain
		return
	if w.pause_left > 0.0:
		w.pause_left -= dt
		return
	if not w.path.is_empty():
		_move(w, dt)
		return
	if w.task.is_empty():
		return
	match w.task["type"]:
		"extract":
			_update_extract(w, dt)
		"build":
			_update_build(w, dt)
		"station":
			if w.tile() != w.task["tile"]:
				_set_path(w, w.task["tile"])
			elif w.task["kind"] in ["shop", "ticket"]:
				staffed_time[w.task["obj"]] = staffed_time.get(w.task["obj"], 0.0) + dt
				if w.task["kind"] == "shop" and w.card.metier["id"] == "vendeur":
					vendeur_time[w.task["obj"]] = vendeur_time.get(w.task["obj"], 0.0) + dt
			elif w.task["kind"] == "care":
				cared_today[w.task["obj"]] = true
		"lobby":
			if w.tile() == map.exit_tile:
				w.offmap = true
				w.task["phase"] = "outside"
				version += 1
			else:
				w.task = {}


func _update_extract(w: Worker, dt: float) -> void:
	var task := w.task
	match task["phase"]:
		"to_resource":
			var tg: Vector2i = task["target"]
			if map.extractible(tg.x, tg.y) != task["res"]:
				_retarget(w)
			else:
				task["phase"] = "working"
		"working":
			var res: String = task["res"]
			var tgt: Vector2i = task["target"]
			var per_minute := float(data["buildings"]["extraction"][res]) * efficiency_at(w, "extraire_" + res)
			var cap := carry_capacity(w.card)
			var amount := map.deplete(tgt.x, tgt.y, minf(per_minute / 60.0 * dt, cap - w.carry))
			w.carry_type = res
			w.carry += amount
			if map.depleted(tgt.x, tgt.y):
				# Forêt rasée -> prairie, roche épuisée -> sable
				map.set_t(tgt.x, tgt.y, GameMap.TERRAINS.find(str(map.def_of(tgt.x, tgt.y)["devient_si_epuise"])))
				_terrain_updated(tgt)
			_work_traits(w, dt)
			if w.task.is_empty():
				return
			if w.carry >= cap - 0.001:
				_go_to_depot(w)
			elif map.extractible(tgt.x, tgt.y) != res:
				if w.carry > 0.0:
					_go_to_depot(w)
				else:
					_retarget(w)
		"to_depot":
			if in_depot(w.tile()):
				if w.carry > 0.0:
					stock[w.carry_type] += w.carry
					day_stats[w.carry_type] += w.carry
				w.carry = 0.0
				task["phase"] = "to_resource"
				var tg: Vector2i = task["target"]
				if map.extractible(tg.x, tg.y) != task["res"]:
					_retarget(w)
				else:
					_set_path(w, tg)


## La case est épuisée : l'ouvrier passe à la case de même ressource la plus proche (rayon 10).
func _retarget(w: Worker) -> void:
	var res: String = w.task["res"]
	var c := w.tile()
	for r in range(1, 11):
		var best := Vector2i(-1, -1)
		var best_d := INF
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := c + Vector2i(dx, dy)
				if map.in_bounds(t.x, t.y) and map.extractible(t.x, t.y) == res and map.passable(t.x, t.y):
					var d := Vector2(dx, dy).length()
					if d < best_d:
						best_d = d
						best = t
		if best.x >= 0:
			w.task["target"] = best
			w.task["phase"] = "to_resource"
			_set_path(w, best)
			return
	say("%s ne trouve plus de %s à proximité." % [w.card.nom, res])
	w.task = {}


## Traits qui interrompent le travail (Paresseux, Distrait) : vérifiés à chaque minute travaillée.
func _work_traits(w: Worker, dt: float) -> void:
	w.minute_clock += dt
	if w.minute_clock < 60.0:
		return
	w.minute_clock -= 60.0
	if w.card.traits.has("paresseux"):
		w.pause_left = 15.0
		say("%s fait une pause (paresseux)." % w.card.nom)
	if w.card.traits.has("distrait") and rng.randf() < 0.1:
		w.task = {}
		say("%s a oublié ce qu'il faisait (distrait)." % w.card.nom)


# --- Construction et aménagement --------------------------------------------

func building_defs() -> Array:
	return data["buildings"]["batiments"].filter(func(b): return b["id"] != "camp")


func amenagement_defs() -> Array:
	return data["buildings"]["amenagements"]


func building_def(id: String) -> Dictionary:
	for b in data["buildings"]["batiments"]:
		if b["id"] == id:
			return b
	return {}


func cost_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "gratuit"
	var parts: Array[String] = []
	for k in cost:
		parts.append("%d %s" % [int(cost[k]), k])
	return ", ".join(parts)


func can_afford(cost: Dictionary) -> bool:
	for k in cost:
		var have: float = money if k == "argent" else float(stock.get(k, 0.0))
		if have < float(cost[k]):
			return false
	return true


func _pay(cost: Dictionary, factor := 1.0) -> void:
	for k in cost:
		if k == "argent":
			money -= factor * float(cost[k])
		else:
			stock[k] -= factor * float(cost[k])


func footprint(kind: String, def: Dictionary, origin: Vector2i) -> Rect2i:
	if kind == "amenagement":
		return Rect2i(origin, Vector2i.ONE)
	return Rect2i(origin, Vector2i(int(def["taille"][0]), int(def["taille"][1])))


func site_at(t: Vector2i) -> Site:
	return occupancy.get(t)


func has_building(id: String) -> bool:
	return sites.any(func(s): return s.kind == "batiment" and s.def_id() == id)


## Renvoie "" si le placement est possible, sinon la raison du refus.
func placement_error(kind: String, def: Dictionary, origin: Vector2i, check_cost := true) -> String:
	if phase != "day":
		return "Construction possible uniquement de jour"
	var r := footprint(kind, def, origin)
	var id: String = def["id"]
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not map.in_bounds(x, y):
				return "Hors de la carte"
			if map.in_camp(x, y):
				return "Sur le camp"
			if occupancy.has(Vector2i(x, y)):
				return "Case déjà occupée"
			if map.road[map.idx(x, y)]:
				return "Il y a déjà une route"
			var t := map.get_t(x, y)
			if kind == "amenagement":
				var de = def["de"]
				var allowed: Array = de if de is Array else [de]
				if not allowed.has(GameMap.TERRAINS[t]):
					return "Terrain requis : %s" % " ou ".join(allowed)
			elif id == "pont":
				if t != GameMap.EAU:
					return "Un pont se construit sur l'eau"
			elif t == GameMap.EAU or t == GameMap.MONTAGNE:
				return "Terrain infranchissable"
			elif t == GameMap.MINE_OR and id != "mine":
				return "Case réservée à la mine d'or"
	if kind == "batiment":
		if id == "mine" and not map.golds.any(func(g): return r.has_point(g)):
			return "La mine doit couvrir un gisement d'or"
		if def.get("unique", false) and has_building(id):
			return "Bâtiment unique, déjà placé"
		if def.get("hors_enceinte", false):
			var interior: Dictionary = zoo_status()["interior"]
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					if interior.has(Vector2i(x, y)):
						return "Interdit dans l'enceinte du zoo"
	var cost: Dictionary = def.get("cout", {})
	if check_cost and not can_afford(cost):
		return "Pas assez de ressources (%s)" % cost_text(cost)
	return ""


func place(kind: String, def: Dictionary, origin: Vector2i) -> Site:
	if placement_error(kind, def, origin) != "":
		return null
	var s := Site.new()
	s.id = next_id
	next_id += 1
	s.kind = kind
	s.def = def
	s.rect = footprint(kind, def, origin)
	s.paid = def.get("cout", {}).duplicate()
	_pay(s.paid)
	sites.append(s)
	for t in _tiles(s.rect):
		occupancy[t] = s
	version += 1
	return s


## Annule un chantier : remboursement total si personne n'y a travaillé, sinon la moitié.
func cancel_site(s: Site) -> void:
	if s == null or s.done or not sites.has(s):
		return
	var refund := 1.0 if s.work <= 0.0 else 0.5
	_pay(s.paid, -refund)
	_remove_site(s)
	for w in workers:
		if w.task.get("site") == s:
			w.task = {}
			w.path.clear()
	say("Chantier annulé (%d %% remboursé)." % int(refund * 100))


func _remove_site(s: Site) -> void:
	sites.erase(s)
	for t in _tiles(s.rect):
		occupancy.erase(t)
	version += 1


func _tiles(r: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			out.append(Vector2i(x, y))
	return out


## Cases d'où l'on peut travailler : dans l'emprise d'un bâtiment, ou tout autour
## (toujours autour pour un pont ou un aménagement, dont la case peut devenir infranchissable).
func work_tiles(s: Site) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var inside_ok := s.kind == "batiment" and s.def_id() != "pont"
	for t in _tiles(s.rect.grow(1)):
		if s.rect.has_point(t) and not inside_ok:
			continue
		if map.passable(t.x, t.y):
			out.append(t)
	return out


func _path_to_site(w: Worker, s: Site) -> bool:
	_unstick(w)
	var tiles := work_tiles(s)
	if tiles.has(w.tile()):
		w.path.clear()
		return true
	tiles.sort_custom(func(a, b): return w.pos.distance_squared_to(Vector2(a)) < w.pos.distance_squared_to(Vector2(b)))
	var best = null
	for t in tiles.slice(0, 6):
		var p = map.find_path(w.tile(), t)
		if p != null and (best == null or p.size() < best.size()):
			best = p
	if best == null:
		say("%s ne peut pas atteindre le chantier." % w.card.nom)
		w.task = {}
		w.path.clear()
		return false
	w.path.assign(best)
	return true


func _update_build(w: Worker, dt: float) -> void:
	var s: Site = w.task["site"]
	if s.done or not sites.has(s):
		w.task = {}
		return
	if not work_tiles(s).has(w.tile()):
		_path_to_site(w, s)
		return
	s.work += efficiency_at(w, s.type_travail()) * dt
	_work_traits(w, dt)
	if s.work >= s.travail():
		_complete(s)


func _complete(s: Site) -> void:
	s.done = true
	var p := s.rect.position
	if s.kind == "amenagement":
		map.set_t(p.x, p.y, GameMap.TERRAINS.find(str(s.def["vers"])))
		var bonus: Dictionary = s.def.get("bonus", {})
		for k in bonus:
			stock[k] += float(bonus[k])
			day_stats[k] += float(bonus[k])
		_remove_site(s)
		_terrain_updated(p)
	else:
		match s.def_id():
			"route":
				map.road[map.idx(p.x, p.y)] = 1
				map.refresh_cell(p.x, p.y)
			"pont":
				map.bridge[map.idx(p.x, p.y)] = 1
				map.road[map.idx(p.x, p.y)] = 1
				map.refresh_cell(p.x, p.y)
		version += 1
	say("%s : terminé." % s.def["nom"])
	# Les ouvriers de ce chantier enchaînent sur le chantier voisin du même type (routes, clôtures…).
	for w in workers:
		if w.task.get("site") == s:
			var nxt := _next_site_like(s, w)
			if nxt:
				w.task = {"type": "build", "site": nxt}
				_path_to_site(w, nxt)
			else:
				w.task = {}


func _next_site_like(s: Site, w: Worker) -> Site:
	var best: Site = null
	var best_d := 10.0
	for o in sites:
		if o.done or o.kind != s.kind or o.def_id() != s.def_id():
			continue
		var d := w.pos.distance_to(Vector2(o.rect.get_center()))
		if d < best_d:
			best_d = d
			best = o
	return best


func _terrain_updated(p: Vector2i) -> void:
	terrain_changed.append(p)
	map.reset_resource(p.x, p.y)
	map.refresh_cell(p.x, p.y)
	for w in workers:
		_unstick(w)


## Un ouvrier qui se retrouve sur une case devenue infranchissable (bassin creusé) est poussé à côté.
func _unstick(w: Worker) -> void:
	var t := w.tile()
	if w.offmap or map.passable(t.x, t.y):
		return
	for r in range(1, 4):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if map.passable(t.x + dx, t.y + dy):
					w.pos = Vector2(t.x + dx, t.y + dy) + Vector2(0.5, 0.5)
					w.path.clear()
					return


func can_landscape(card: Card) -> bool:
	return data["buildings"]["regles_amenagement"]["metiers"].has(card.metier["id"])


## Démolit un bâtiment terminé (mur, clôture, route…), sans remboursement.
func demolish(s: Site) -> bool:
	if s == null or not s.done or s.kind != "batiment" or not sites.has(s):
		return false
	var p := s.rect.position
	if s.def_id() in ["route", "pont"]:
		map.road[map.idx(p.x, p.y)] = 0
		map.bridge[map.idx(p.x, p.y)] = 0
		map.refresh_cell(p.x, p.y)
	for w in workers:
		if w.task.get("obj") == s or w.task.get("site") == s:
			w.task = {}
			w.path.clear()
	_remove_site(s)
	for w in workers:
		_unstick(w)
	return true


func mine_ready(gold_tile: Vector2i) -> bool:
	var s := site_at(gold_tile)
	return s != null and s.done and s.def_id() == "mine"


func housing() -> int:
	var cap := int(building_def("camp")["effet"]["logement"])
	for s in sites:
		if s.done and s.kind == "batiment":
			cap += int(s.def["effet"].get("logement", 0))
	return cap


func employees() -> int:
	return deck.size() + discard.size() + hand.size()


# --- Fin de journée ----------------------------------------------------------

func _reset_day_stats() -> void:
	day_stats = {"bois": 0.0, "pierre": 0.0, "or": 0.0, "influence": 0.0}


## Raccourcis pour les tests et l'interface : la journée et la nuit sont gérées par la partie.
func end_day() -> void:
	mt.end_day()


func start_next_day() -> void:
	mt.start_next_day()


func _end_day_player() -> void:
	var regles: Dictionary = data["workers"]["regles"]
	var level_ups: Array[Card] = []
	drh_available = workers.filter(func(w): return w.card.metier["id"] == "drh").size()
	var arrivals: Array[String] = []
	for a in animals:
		if not a.arrived:
			a.arrived = true
			arrivals.append(a.def["nom"])
	var income := _close_zoo_day()  # les recettes ont été encaissées pendant la journée
	version += 1  # invalide le cache de l'enceinte (nouveaux animaux)
	for w in workers:
		var card := w.card
		card.jours_travailles += 1
		if card.jours_travailles % int(regles["xp_jours_par_niveau"]) == 0 and card.niveau < int(regles["niveau_max"]):
			card.niveau += 1
			level_ups.append(card)
		card.deployed = false
	night_report = {"day": day, "stats": day_stats.duplicate(), "level_ups": level_ups, "deployed": workers.size(),
		"arrivals": arrivals, "income": income}
	workers.clear()
	discard.append_array(hand)
	hand.clear()
	version += 1


func _start_day_player() -> void:
	_reset_day_stats()
	free_used_today = false
	cared_today.clear()
	staffed_time.clear()
	vendeur_time.clear()
	day_bonus = night_bonus
	night_bonus = {}
	sick_animal = null
	pending_upgrade = {}
	_reset_visit()
	night_report = {}
	_feed_animals()
	draw_hand()


func objective() -> int:
	return mt.objective()


func zoo_area() -> int:
	return zoo_status()["interior"].size()


func hire_cost(card: Card) -> int:
	var pos := card.traits.filter(func(t): return is_positive(t)).size()
	var neg := card.traits.size() - pos
	var regles: Dictionary = data["workers"]["regles"]
	var base := float(card.metier["cout"]) * (1.0 + float(regles["modif_cout_par_trait_positif"]) * pos + float(regles["modif_cout_par_trait_negatif"]) * neg)
	return maxi(int(regles["cout_min_embauche"]), roundi(base))


func hire_error(card: Card) -> String:
	if phase != "night":
		return "Le marché n'ouvre que la nuit"
	if mt.current_buyer() != index:
		return "Ce n'est pas votre tour au marché"
	if bought_worker:
		return "Déjà embauché cette nuit"
	if employees() >= housing():
		return "Logement plein : construisez une maison"
	if money < hire_cost(card):
		return "Pas assez d'argent"
	return ""


func hire(card: Card) -> bool:
	if hire_error(card) != "" or not market_workers.has(card):
		return false
	money -= hire_cost(card)
	market_workers.erase(card)
	discard.append(card)
	bought_worker = true
	say("%s rejoint votre équipe (dans la défausse)." % card.nom)
	mt.bump()
	return true


## Coût réel d'un contrat pour ce joueur : le prix en argent monte avec le nombre d'animaux
## déjà possédés ou en attente, et le 2e contrat de la nuit coûte plus cher. L'or ne change pas.
func contract_cost(def: Dictionary) -> Dictionary:
	var m: Dictionary = data["buildings"]["marche"]
	var cost: Dictionary = def.get("cout", {}).duplicate()
	if cost.has("argent"):
		var mult := 1.0 + float(m["hausse_prix_par_animal"]) * (animals.size() + contracts.size())
		if contracts_tonight >= 1:
			mult *= 1.0 + float(m["surcout_2e_contrat"])
		cost["argent"] = roundi(float(cost["argent"]) * mult)
	return cost


func contract_error(def: Dictionary) -> String:
	if phase != "night":
		return "Le marché n'ouvre que la nuit"
	if mt.current_buyer() != index:
		return "Ce n'est pas votre tour au marché"
	if contracts_tonight >= int(data["buildings"]["marche"]["contrats_par_nuit"]):
		return "Déjà %d contrats achetés cette nuit" % contracts_tonight
	if has_species(def["id"]):
		return "Vous avez déjà cette espèce"
	if not can_afford(contract_cost(def)):
		return "Pas assez de ressources"
	return ""


func buy_contract(def: Dictionary) -> bool:
	if contract_error(def) != "" or not market_contracts.has(def):
		return false
	_pay(contract_cost(def))
	market_contracts.erase(def)
	contracts.append(def)
	contracts_tonight += 1
	say("Contrat acheté : %s. Construisez-lui un enclos." % def["nom"])
	mt.bump()
	return true


func has_species(id: String) -> bool:
	return contracts.any(func(d): return d["id"] == id) or animals.any(func(a): return a.def["id"] == id)


## Licenciement par le DRH (s'il a été déployé dans la journée).
func fire(card: Card) -> bool:
	if phase != "night" or drh_available <= 0:
		return false
	for pile in [deck, discard, hand]:
		if pile.has(card):
			pile.erase(card)
			drh_available -= 1
			say("%s a été licencié." % card.nom)
			version += 1
			return true
	return false


## Choisit un bonus parmi ceux offerts cette nuit (dans l'ordre d'influence).
func bonus_error(def: Dictionary) -> String:
	if phase != "night":
		return "Uniquement la nuit"
	if mt.current_buyer() != index:
		return "Ce n'est pas votre tour"
	if not night_bonus.is_empty():
		return "Bonus déjà choisi"
	if mt.bonus_taken.has(def["id"]):
		return "Déjà pris par %s" % mt.names[mt.bonus_taken[def["id"]]]
	return ""


func pick_bonus(def: Dictionary) -> bool:
	if bonus_error(def) != "":
		return false
	night_bonus = def
	mt.bonus_taken[def["id"]] = index
	mt.bump()
	return true


func night_action_rules() -> Dictionary:
	return data["workers"]["regles"]["actions_nuit"]


func night_action_error(cost: int) -> String:
	if phase != "night":
		return "Uniquement la nuit"
	if day < int(night_action_rules()["jour_min"]):
		return "Disponible à partir du jour %d" % int(night_action_rules()["jour_min"])
	if night_action_used:
		return "Déjà une action cette nuit"
	if money < cost:
		return "Pas assez d'argent (%d)" % cost
	return ""


## Licenciement payant (milieu de partie), en plus du licenciement gratuit par le DRH.
func fire_paid(card: Card) -> bool:
	var cost := int(night_action_rules()["cout_licenciement"])
	if night_action_error(cost) != "" or not all_employees().has(card):
		return false
	money -= cost
	for pile in [deck, discard, hand]:
		pile.erase(card)
	night_action_used = true
	say("%s a été licencié (%d)." % [card.nom, cost])
	version += 1
	return true


## Trois améliorations au choix pour cette carte (tirées une fois, puis gardées pendant le choix).
func upgrade_options(card: Card) -> Array:
	if pending_upgrade.get("card") == card:
		return pending_upgrade["options"]
	var has_neg := card.traits.any(func(t): return not is_positive(t))
	var pool: Array = data["workers"]["ameliorations_generiques"].filter(func(u):
		return u["id"] != "double_spe" and (u["id"] != "guerison" or has_neg) and (u["id"] != "salaire_down" or salary(card) > 0))
	mt.shuffle(pool)
	pending_upgrade = {"card": card, "options": pool.slice(0, 3)}
	version += 1
	return pending_upgrade["options"]


func apply_upgrade(card: Card, option: Dictionary) -> bool:
	var cost := int(night_action_rules()["cout_amelioration"])
	if night_action_error(cost) != "" or not all_employees().has(card):
		return false
	money -= cost
	match option["id"]:
		"guerison":
			for t in card.traits:
				if not is_positive(t):
					card.traits.erase(t)
					break
		"nouveau_trait":
			mt._draw_traits(card, data["workers"]["traits_positifs"], 1, data["workers"]["generation_traits"]["exclusions"])
		_:
			card.upgrades.append(option["effet"])
	card.upgrade_names.append(option["nom"])
	night_action_used = true
	pending_upgrade = {}
	say("%s : amélioration « %s »." % [card.nom, option["nom"]])
	version += 1
	return true


func all_employees() -> Array[Card]:
	var out: Array[Card] = []
	out.append_array(hand)
	out.append_array(deck)
	out.append_array(discard)
	return out


# --- Enclos, animaux et réputation -------------------------------------------

func is_fence(t: Vector2i) -> bool:
	var s := site_at(t)
	return s != null and s.done and s.def_id() == "enclos"


## Zone fermée par des clôtures d'enclos autour de la case t (remplissage 4 directions).
func enclosure_at(t: Vector2i) -> Dictionary:
	if not map.in_bounds(t.x, t.y) or is_fence(t):
		return {"closed": false, "reason": "Visez l'intérieur d'un enclos"}
	var seen := {t: true}
	var stack: Array[Vector2i] = [t]
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in dirs:
			var q := p + d
			if not map.in_bounds(q.x, q.y):
				return {"closed": false, "reason": "Enclos non fermé : entourez la zone de clôtures d'enclos terminées"}
			if seen.has(q) or is_fence(q):
				continue
			if seen.size() >= 120:
				return {"closed": false, "reason": "Enclos non fermé : entourez la zone de clôtures d'enclos terminées"}
			seen[q] = true
			stack.append(q)
	var tiles: Array[Vector2i] = []
	tiles.assign(seen.keys())
	return {"closed": true, "tiles": tiles}


## Les 8 orientations d'un motif (4 rotations x miroir), chacune ramenée à l'origine.
var _variants_cache := {}


func pattern_variants(def: Dictionary) -> Array:
	var id: String = def["id"]
	if _variants_cache.has(id):
		return _variants_cache[id]
	var seen := {}
	var out := []
	for mirror in [false, true]:
		for rot in 4:
			var cells := []
			for c in def["motif"]:
				var x := int(c[0])
				var y := int(c[1])
				if mirror:
					x = -x
				for r in rot:
					var tmp := x
					x = -y
					y = tmp
				cells.append([x, y, c[2]])
			var mx := 999
			var my := 999
			for c in cells:
				mx = mini(mx, c[0])
				my = mini(my, c[1])
			for c in cells:
				c[0] -= mx
				c[1] -= my
			cells.sort_custom(func(a, b): return a[1] < b[1] or (a[1] == b[1] and a[0] < b[0]))
			var key := str(cells)
			if not seen.has(key):
				seen[key] = true
				out.append(cells)
	_variants_cache[id] = out
	return out


## Cherche le motif dans la zone : renvoie {"found", "tiles" (cases du motif trouvé), "missing" (cases à aménager au mieux)}.
func pattern_status(def: Dictionary, tiles: Array) -> Dictionary:
	var zone := {}
	for t in tiles:
		zone[t] = true
	var best_missing := 99
	var best_tiles: Array[Vector2i] = []
	for v in pattern_variants(def):
		for anchor in tiles:
			var missing := 0
			var cells: Array[Vector2i] = []
			for c in v:
				var p: Vector2i = anchor + Vector2i(c[0], c[1])
				if not zone.has(p):
					missing = 99
					break
				cells.append(p)
				if GameMap.TERRAINS[map.get_t(p.x, p.y)] != c[2]:
					missing += 1
			if missing < best_missing:
				best_missing = missing
				best_tiles = cells
				if missing == 0:
					return {"found": true, "tiles": best_tiles, "missing": 0}
	return {"found": false, "tiles": best_tiles, "missing": best_missing}


## Renvoie "" si l'animal peut être installé dans cet enclos, sinon la raison.
func animal_error(def: Dictionary, enc: Dictionary) -> String:
	if phase != "day":
		return "Installation possible uniquement de jour"
	if not enc["closed"]:
		return enc["reason"]
	var tiles: Array = enc["tiles"]
	for t in tiles:
		if map.in_camp(t.x, t.y):
			return "L'enclos ne peut pas contenir le camp"
		for a in animals:
			if a.tiles.has(t):
				return "Enclos déjà occupé par : %s" % a.def["nom"]
	if tiles.size() < int(def["taille"]):
		return "Enclos trop petit (%d / %d cases)" % [tiles.size(), int(def["taille"])]
	var ps := pattern_status(def, tiles)
	if not ps["found"]:
		return "Motif absent" if ps["missing"] >= 99 else "Motif absent (au mieux, %d case(s) à aménager)" % ps["missing"]
	return ""


func install_animal(def: Dictionary, t: Vector2i) -> String:
	var enc := enclosure_at(t)
	var err := animal_error(def, enc)
	if err != "":
		return err
	var a := Animal.new()
	a.def = def
	a.tiles.assign(enc["tiles"])
	animals.append(a)
	contracts.erase(def)
	say("%s : enclos validé, l'animal arrive cette nuit." % def["nom"])
	version += 1
	return ""


func food_cost(def: Dictionary) -> int:
	var base := float(data["animals"]["paliers"][def["palier"]]["nourriture"])
	return roundi(base * float(event_effects().get("nourriture", 1.0)))


## Au début du jour, avant tout déploiement : les animaux les plus chers à nourrir passent en premier.
func _feed_animals() -> void:
	var arrived := animals.filter(func(a): return a.arrived)
	arrived.sort_custom(func(a, b): return food_cost(a.def) > food_cost(b.def))
	for a in arrived:
		var cost := food_cost(a.def)
		a.fed = money >= cost
		if a.fed:
			money -= cost
		else:
			say("%s n'a pas pu être nourri : il ne compte pas aujourd'hui." % a.def["nom"])


## Réputation accumulée : gagnée chaque nuit selon le nombre moyen de visiteurs présents dans le zoo.
func reputation() -> int:
	return floori(rep_points)


## Attractivité : points par espèce + diversité des biomes + collections (+ soins et prédateurs).
## Elle fixe combien de visiteurs se présentent. `only` : restreint aux animaux donnés (ceux de l'enceinte).
func attractiveness(only = null) -> int:
	var species := {}
	var extra := 0
	var Z: Dictionary = data["buildings"]["zoo"]
	for a in (animals if only == null else only):
		if not a.arrived or not a.fed or (a == sick_animal and not cared_today.has(a)):
			continue
		species[a.def["id"]] = a.def
		if a.def.get("special", "") == "predateur":
			extra += int(Z["bonus_predateur"])
		if cared_today.has(a):
			extra += int(Z["bonus_soigneur"])
	var total := extra
	var biomes := {}
	for d in species.values():
		total += int(d["reputation"])
		biomes[d["biome"]] = biomes.get(d["biome"], 0) + 1
	var A: Dictionary = data["animals"]
	total += int(A["bonus_diversite_biomes"].get(str(biomes.size()), 0))
	for b in biomes:
		if biomes[b] >= int(A["bonus_collection"]["especes_meme_biome"]):
			total += int(A["bonus_collection"]["points"])
	return total


## Publicité : l'influence attire plus de visiteurs, avec un rendement décroissant.
func publicity_mult() -> float:
	var P: Dictionary = data["buildings"]["zoo"]["publicite"]
	return 1.0 + float(P["max"]) * influence / (influence + float(P["demi_influence"]))


func marchand_present() -> bool:
	return workers.any(func(w): return w.task.get("kind") == "trade" and w.path.is_empty() and map.in_camp(w.tile().x, w.tile().y))


func sell_rate() -> float:
	return 1.0 if marchand_present() else float(data["buildings"]["zoo"]["vente_sans_marchand"])


## Vend le bois et la pierre du stock (l'or est gardé pour les contrats).
## Plein tarif si un Marchand tient le comptoir du camp, sinon taux réduit.
func sell_price(res: String) -> float:
	return float(data["buildings"]["conversion"][res]) * sell_rate() * float(event_effects().get("prix", {}).get(res, 1.0))


## Prix d'achat d'une unité de bois ou de pierre (double du prix de revente de base, sans Marchand ni événement).
func buy_price(res: String) -> float:
	return float(data["buildings"]["conversion"][res]) * float(data["buildings"]["marche"]["prix_achat_materiaux"])


func buy_material(res: String, qty: int) -> bool:
	var cost := ceilf(buy_price(res) * qty)
	if phase != "day" or qty <= 0 or not res in ["bois", "pierre"] or money < cost:
		return false
	money -= cost
	stock[res] += qty
	say("Achat : %d %s pour %d." % [qty, res, int(cost)])
	version += 1
	return true


func sell_stock(keep := {}, resources: Array = ["bois", "pierre"]) -> void:
	if phase != "day":
		return
	var rate := sell_rate()
	var gain := 0.0
	for res in resources:
		var units := floorf(maxf(0.0, stock[res] - float(keep.get(res, 0.0))))
		gain += units * sell_price(res)
		stock[res] -= units
	money += floorf(gain)
	say("Stock vendu : +%d%s" % [floori(gain), "" if rate >= 1.0 else " (sans Marchand : taux réduit)"])
	version += 1


# --- Zoo : enceinte, visiteurs et revenus ------------------------------------

func is_wall(t: Vector2i) -> bool:
	var s := site_at(t)
	return s != null and s.done and s.def_id() in ["cloture", "entree"]


## Intérieur de l'enceinte : la zone fermée (par les segments d'enceinte et l'entrée) qui touche l'entrée.
func zoo_status() -> Dictionary:
	if _zoo_cache_version == version:
		return _zoo_cache
	_zoo_cache_version = version
	_zoo_cache = _compute_zoo_status()
	return _zoo_cache


func _compute_zoo_status() -> Dictionary:
	var entree: Site = null
	for s in sites:
		if s.done and s.def_id() == "entree":
			entree = s
	if entree == null:
		return {"open": false, "reason": "Construisez l'entrée du zoo", "interior": {}}
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var interior := {}
	for t in _tiles(entree.rect):
		for d in dirs:
			var start := t + d
			if not map.in_bounds(start.x, start.y) or is_wall(start) or interior.has(start):
				continue
			var region := _closed_region(start, 2500)
			if region.size() > interior.size():
				interior = region
	if interior.is_empty():
		return {"open": false, "reason": "Enceinte non fermée : reliez l'entrée par des segments d'enceinte", "interior": {}}
	var inside: Array[Animal] = []
	for a in animals:
		if a.arrived and a.tiles.all(func(t): return interior.has(t)):
			inside.append(a)
	if inside.is_empty():
		return {"open": false, "reason": "Aucun animal arrivé dans l'enceinte", "interior": interior}
	return {"open": true, "reason": "", "interior": interior, "animals": inside}


## Remplissage borné par les murs ; renvoie {} si la zone touche le bord de la carte (non fermée).
func _closed_region(start: Vector2i, limit: int) -> Dictionary:
	var seen := {start: true}
	var stack: Array[Vector2i] = [start]
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in dirs:
			var q := p + d
			if not map.in_bounds(q.x, q.y):
				return {}
			if seen.has(q) or is_wall(q):
				continue
			seen[q] = true
			if seen.size() > limit:
				return {}
			stack.append(q)
	return seen


## Chemin des visiteurs : de l'Accès à la case devant l'Entrée, uniquement par les routes (le camp sert de carrefour).
func visitor_path() -> Array[Vector2i]:
	if _path_cache_version == version:
		return _path_cache
	_path_cache_version = version
	_path_cache = []
	var entree: Site = null
	for s in sites:
		if s.done and s.def_id() == "entree":
			entree = s
	if entree == null:
		return _path_cache
	var goals := {}
	for t in _tiles(entree.rect):
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			goals[t + d] = true
	var walk := func(t: Vector2i) -> bool:
		return map.in_bounds(t.x, t.y) and (map.road[map.idx(t.x, t.y)] == 1 or map.in_camp(t.x, t.y))
	var start := map.exit_tile
	var came := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	var found := Vector2i(-1, -1)
	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		if goals.has(p) and walk.call(p):
			found = p
			break
		# 8 directions : une route tracée en diagonale reste praticable
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			var q: Vector2i = p + d
			if not came.has(q) and walk.call(q):
				came[q] = p
				queue.append(q)
	if found.x < 0:
		return _path_cache
	var path: Array[Vector2i] = [found]
	while path[0] != start:
		path.push_front(came[path[0]])
	_path_cache = path
	return _path_cache


## Visiteurs par seconde qui se présentent à l'Accès.
func demand_rate() -> float:
	var z := zoo_status()
	if not z["open"]:
		return 0.0
	var Z: Dictionary = data["buildings"]["zoo"]
	var per_day := attractiveness(z["animals"]) * float(Z["visiteurs_par_point_attractivite"]) * publicity_mult() \
		* float(event_effects().get("visiteurs", 1.0)) * float(bonus_effects().get("visiteurs", 1.0))
	return per_day / day_length


## Visiteurs par seconde que le guichet fait entrer (somme des ouvriers présents au guichet).
func guichet_rate() -> float:
	var base := float(data["buildings"]["zoo"]["debit_guichet_par_minute"]) / 60.0
	var r := 0.0
	for w in workers:
		if w.task.get("kind") == "ticket" and w.path.is_empty() and w.tile() == w.task["tile"]:
			r += base * efficiency_at(w, "guichet")
	return r


## Multiplicateur de souvenirs à l'instant : 0 si la boutique est vide, 1 si tenue, 2 avec un Vendeur.
func _shop_mult() -> float:
	var interior: Dictionary = zoo_status()["interior"]
	var best := 0.0
	for w in workers:
		if w.task.get("kind") == "shop" and w.path.is_empty() and w.tile() == w.task["tile"] and interior.has(w.task["obj"].rect.position):
			best = maxf(best, float(data["buildings"]["zoo"]["mult_vendeur"]) if w.card.metier["id"] == "vendeur" else 1.0)
	return best


func _reset_visit() -> void:
	road_visitors.clear()
	visitor_queue = 0
	in_zoo.clear()
	_spawn_acc = 0.0
	_admit_acc = 0.0
	visit = {"admitted": 0, "lost": 0, "tickets": 0.0, "souvenirs": 0.0, "presence": 0.0}


func _update_visitors(dt: float) -> void:
	if visit.is_empty():
		_reset_visit()
	var Z: Dictionary = data["buildings"]["zoo"]
	var path := visitor_path()
	# Arrivées à l'Accès
	if not path.is_empty():
		_spawn_acc += demand_rate() * dt
		while _spawn_acc >= 1.0:
			_spawn_acc -= 1.0
			road_visitors.append(0.0)
	# Marche sur la route jusqu'à la file d'attente
	var step := float(Z["vitesse_visiteur"]) * dt
	var end := float(maxi(path.size() - 1, 0))
	for i in range(road_visitors.size() - 1, -1, -1):
		road_visitors[i] += step
		if road_visitors[i] >= end:
			road_visitors.remove_at(i)
			if visitor_queue < int(Z["file_max"]):
				visitor_queue += 1
			else:
				visit["lost"] += 1  # file pleine : le visiteur repart
	# Guichet : billet, souvenirs, entrée dans le zoo
	var interior: Array = zoo_status()["interior"].keys()
	_admit_acc += guichet_rate() * dt
	if visitor_queue == 0:
		_admit_acc = minf(_admit_acc, 1.0)
	while _admit_acc >= 1.0 and visitor_queue > 0 and not interior.is_empty():
		_admit_acc -= 1.0
		visitor_queue -= 1
		visit["admitted"] += 1
		var ticket := float(Z["billet"])
		money += ticket
		visit["tickets"] += ticket
		var souv := 0.0
		for s in sites:
			if s.done and s.def_id() == "boutique":
				souv = float(s.def["effet"]["souvenirs_par_visiteur"]) * _shop_mult()
				break
		money += souv
		visit["souvenirs"] += souv
		var t: Vector2i = interior[rng.randi_range(0, interior.size() - 1)]
		in_zoo.append({"t": float(Z["duree_visite_s"]), "pos": Vector2(t) + Vector2(rng.randf(), rng.randf())})
	# Visite puis départ
	for i in range(in_zoo.size() - 1, -1, -1):
		in_zoo[i]["t"] -= dt
		if in_zoo[i]["t"] <= 0.0:
			in_zoo.remove_at(i)
	visit["presence"] += in_zoo.size() * dt


## Fin de journée : réputation gagnée selon la fréquentation moyenne, puis remise à zéro des visiteurs.
func _close_zoo_day() -> Dictionary:
	if visit.is_empty():
		_reset_visit()
	var z := zoo_status()
	var avg: float = visit["presence"] / day_length
	var gain := avg * float(data["buildings"]["zoo"]["reputation_par_visiteur_moyen"])
	rep_points += gain
	var reason: String = z["reason"]
	if z["open"] and visitor_path().is_empty():
		reason = "Aucune route ne relie l'Accès à l'Entrée du zoo"
	var out := {"open": z["open"], "reason": reason, "visitors": visit["admitted"], "lost": visit["lost"],
		"tickets": roundi(visit["tickets"]), "souvenirs": roundi(visit["souvenirs"]), "avg_present": avg, "rep_gain": gain}
	_reset_visit()
	return out


## État du zoo en direct (panneau d'information).
func zoo_live() -> Dictionary:
	if visit.is_empty():
		_reset_visit()
	var z := zoo_status()
	var reason: String = z["reason"]
	if z["open"] and visitor_path().is_empty():
		reason = "Aucune route ne relie l'Accès à l'Entrée du zoo"
	return {"open": z["open"] and not visitor_path().is_empty(), "reason": reason,
		"attract": attractiveness(z.get("animals", [])), "demand_day": demand_rate() * day_length, "pub": publicity_mult(),
		"road": road_visitors.size(), "queue": visitor_queue, "inside": in_zoo.size(), "admitted": visit["admitted"],
		"lost": visit["lost"], "tickets": roundi(visit["tickets"]), "souvenirs": roundi(visit["souvenirs"]),
		"guichet_min": guichet_rate() * 60.0}


## Outil de test : construit instantanément un petit zoo (enceinte 9x8, entrée, enclos avec un Zèbre, boutique)
## dont le coin haut-gauche est o. Le terrain de la zone est forcé en prairie.
func debug_build_zoo(o: Vector2i) -> void:
	for y in range(o.y, o.y + 8):
		for x in range(o.x, o.x + 9):
			map.set_t(x, y, GameMap.PRAIRIE)
			_terrain_updated(Vector2i(x, y))
	stock["bois"] += 100.0
	stock["pierre"] += 100.0
	money += 50.0
	var built: Array[Site] = []
	for y in range(o.y, o.y + 8):
		for x in range(o.x, o.x + 9):
			var border := x == o.x or x == o.x + 8 or y == o.y or y == o.y + 7
			if border and not (y == o.y + 7 and (x == o.x + 3 or x == o.x + 4)):
				built.append(place("batiment", building_def("cloture"), Vector2i(x, y)))
	built.append(place("batiment", building_def("entree"), Vector2i(o.x + 3, o.y + 7)))
	for y in range(o.y + 1, o.y + 5):
		for x in range(o.x + 1, o.x + 6):
			if x == o.x + 1 or x == o.x + 5 or y == o.y + 1 or y == o.y + 4:
				built.append(place("batiment", building_def("enclos"), Vector2i(x, y)))
	built.append(place("batiment", building_def("boutique"), Vector2i(o.x + 6, o.y + 5)))
	for s in built:
		if s:
			s.work = s.travail()
			_complete(s)
	var zebre: Dictionary = data["animals"]["animaux"].filter(func(d): return d["id"] == "zebre")[0]
	contracts.append(zebre)
	install_animal(zebre, Vector2i(o.x + 2, o.y + 2))
	# Route de l'Accès jusque devant l'Entrée
	var front := Vector2i(o.x + 3, o.y + 8)
	var p = map.find_path(map.exit_tile, front)
	if p != null:
		for t in [map.exit_tile] + p:
			if not map.in_camp(t.x, t.y) and site_at(t) == null:
				map.road[map.idx(t.x, t.y)] = 1
				map.refresh_cell(t.x, t.y)
	version += 1


func animal_at(t: Vector2i) -> Animal:
	for a in animals:
		if a.tiles.has(t):
			return a
	return null
