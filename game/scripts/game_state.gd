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
	var xp := 0.0  # expérience en jours de travail (voir gain_xp) ; le niveau suit, la nuit
	var deployed := false
	var upgrades: Array = []  # effets des améliorations (vitesse, defaut, specialite, salaire, portage, capacite…)
	var upgrade_names: Array[String] = []
	var last_work_tile := Vector2i(-1, -1)  # dernière case de travail (trait Matinal)
	var action := {}  # carte d'action (workers.json > cartes_action) : pas un ouvrier, elle se joue depuis la main
	var perso := ""  # personnage (data/personnages.json) : portrait de la carte et apparence dans le monde

	func is_action() -> bool:
		return not action.is_empty()


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
	var savings := 1.0  # part des ressources réellement dépensée (Architecte, Débrouillard) : le reste est remboursé à la fin

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
	var fed := true  # a encore des rations en réserve (sinon il a faim et ne compte pas)
	var food := 0.0  # rations en réserve, une journée au maximum
	var key := Vector2i(-9, -9)  # identifie l'enclos (plus petite case) ; (-1, -1) = le parc libre de l'enceinte
	var park := false  # vit en liberté dans l'enceinte, hors des enclos
	var pattern_tiles: Array[Vector2i] = []  # cases de son motif (réservées : un autre animal ne peut pas les reprendre)
	var sick := false  # malade : ne compte pas dans l'attractivité tant qu'un Soigneur ne l'a pas guéri
	var heal := 0.0  # soins reçus (points de travail du Soigneur)
	var starved := false  # a eu faim aujourd'hui (risque de maladie accru la nuit)


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
var publicite := 0.0  # points de publicité gagnés par les campagnes terminées (pour toute la partie)
var campaign := {}  # campagne en cours : {"def": définition, "progress": travail fait}
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
var night_action_used := false
var pending_upgrade := {}  # {"card": Card, "options": [...]} pendant le choix d'une amélioration
var level_choices: Array = []  # [{"card": Card, "options": [...]}] : une amélioration gratuite à choisir par niveau gagné
var action_fx := {}  # effets du jour des cartes d'action jouées (productivite, visiteurs)
var prime_left := 0  # déploiements sans salaire offerts par la carte Prime aujourd'hui
var bought_action := false  # carte d'action achetée cette nuit
var swapped_today := false  # échange fait à l'Agence d'intérim aujourd'hui
var loan_today := false  # emprunt du jour, remboursé automatiquement le soir
var pending_installs: Array = []  # animaux réservés dans un enclos en chantier : [{"def", "tile"}]
var _zoo_cache_version := -1
var _zoo_cache := {}
var _persos := {}  # id -> personnage
var _aura_cache: Array = []  # émetteurs d'aura du pas en cours (voir _tick_player)
var _aura_cache_valid := false

# Visiteurs (simulés pendant la journée)
var rep_points := 0.0  # réputation accumulée (condition de victoire)
var road_visitors := PackedFloat32Array()  # distance parcourue sur le chemin Accès -> Entrée
var visitor_queue := 0  # visiteurs qui attendent au guichet
var in_zoo: Array = []  # [{"t": temps restant, "pos": Vector2}]
var visit := {}  # compteurs du jour
var _admit_acc := 0.0
var proprete := 100.0  # propreté du parc (0 à 100) : les visiteurs salissent, l'entretien nettoie
var _arrival_norm := 1.0  # moyenne de courbe_arrivees sur la journée (voir arrival_factor)
var _arrival_norm_len := -1.0
var _path_cache_version := -1
var _path_cache: Array[Vector2i] = []


## base_map : carte déjà générée avec cette graine (partagée par la partie), copiée plutôt que régénérée.
func _init(game_data: Dictionary, map_seed: int, the_match: Match, player_index: int, base_map: GameMap = null) -> void:
	mt = the_match
	index = player_index
	data = game_data
	seed_value = map_seed
	rng.seed = (map_seed ^ 0x9e3779b9) + player_index * 7919
	map = base_map.copy() if base_map else MapGenerator.generate(data["buildings"], map_seed)
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
	if action_fx.has("sans_defauts"):  # Contremaître joué (Cadence)
		return card.traits.filter(func(id): return is_positive(id)).map(func(id): return traits_by_id[id])
	return card.traits.map(func(id): return traits_by_id[id])


func is_positive(trait_id: String) -> bool:
	return positive_ids.has(trait_id)


# --- Modificateurs : événement du jour et bonus de nuit ----------------------

func event_effects() -> Dictionary:
	if action_fx.has("sans_evenement"):  # Lobbyiste joué (Coup de fil)
		return {}
	return mt.current_event.get("effets", {}) if mt else {}


## Événement du jour défavorable (Pluie, Canicule, Grève, Tempête…) : ce qu'un Coup de fil peut annuler.
func event_is_negative() -> bool:
	var e: Dictionary = mt.current_event.get("effets", {}) if mt else {}
	return float(e.get("vitesse", 1.0)) < 1.0 or float(e.get("visiteurs", 1.0)) < 1.0 or float(e.get("productivite", 1.0)) < 1.0 \
		or float(e.get("nourriture", 1.0)) > 1.0 or int(e.get("salaire", 0)) > 0 or float(e.get("chantiers", 1.0)) < 1.0


func bonus_effects() -> Dictionary:
	return day_bonus.get("effets", {})


## Multiplicateur de productivité du jour pour une tâche (événement + bonus de nuit + cartes d'action jouées).
func task_mult(task: String) -> float:
	var b := bonus_effects()
	var m := float(event_effects().get("productivite", 1.0)) * float(b.get(task, 1.0)) * float(action_fx.get("productivite", 1.0))
	if task.begins_with("construire_"):
		m *= float(b.get("construire", 1.0)) * float(action_fx.get("construction", 1.0))
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
	var s := float(card.metier["vitesse"]) * float(data["workers"]["regles"].get("vitesse_ouvriers", 1.0))
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
		for u in card.upgrades:
			if u.get("seconde_specialite", "") == task:
				base = maxf(base, float(data["workers"]["regles"]["efficacite_seconde_specialite"]))
	for t in trait_defs(card):
		var e: Dictionary = t["effet"]
		base *= float(e.get("defaut", 1.0)) * float(e.get(task, 1.0))
		if task.begins_with("construire_"):
			base *= float(e.get("construire", 1.0))
	# Expérience : +10 % par niveau au-delà du premier, puis améliorations (générales, de spécialité, ou d'une tâche).
	base *= 1.0 + float(data["workers"]["regles"].get("bonus_par_niveau", 0.0)) * (card.niveau - 1)
	for u in card.upgrades:
		base *= float(u.get("defaut", 1.0)) * float(u.get(task, 1.0))
		if eff.has(task):
			base *= float(u.get("specialite", 1.0))
	return base


## Capacité spéciale apportée par une amélioration de métier (effet.capacite : chasseur_tetes, reseau…).
func has_capacity(card: Card, id: String) -> bool:
	return card.upgrades.any(func(u): return u.get("capacite", "") == id)


## Multiplicateur d'expérience : métier (Apprenti ×2) et traits (Bon élève ×1,5).
func xp_mult(card: Card) -> float:
	var m := float(card.metier.get("xp_mult", 1.0))
	for t in trait_defs(card):
		m *= float(t["effet"].get("xp", 1.0))
	return m


## Ajoute de l'expérience, en jours de travail. Les niveaux sont gagnés la nuit (voir _end_day_player).
func gain_xp(card: Card, days: float) -> void:
	card.xp += days * xp_mult(card)


## Expérience nécessaire pour passer au niveau suivant (en jours de travail).
func xp_next_level(card: Card) -> float:
	return card.niveau * float(data["workers"]["regles"]["xp_jours_par_niveau"])


## Part des ressources réellement dépensée sur un chantier où travaille cette carte (Architecte 0,75, Débrouillard 0,85).
func resource_mult(card: Card) -> float:
	var m := float(card.metier.get("cout_ressources_chantier", 1.0))
	for t in trait_defs(card):
		m *= float(t["effet"].get("cout_ressources_chantier", 1.0))
	return m


## Trait Peureux : un enclos de prédateur à 2 cases ou moins.
func near_predator(t: Vector2i) -> bool:
	for a in animals:
		if a.def.get("special", "") == "predateur" and a.tiles.any(func(p): return maxi(absi(p.x - t.x), absi(p.y - t.y)) <= 2):
			return true
	return false


func auras_of(card: Card) -> Array:
	var out := []
	if card.metier.has("aura"):
		out.append(card.metier["aura"])
	for t in trait_defs(card):
		if t.has("aura"):
			out.append(t["aura"])
	return out


## Liste [ouvrier, aura] des ouvriers qui émettent une aura. Pendant un pas de simulation, elle est calculée
## une seule fois (voir _tick_player) au lieu d'une fois par ouvrier au travail : O(n) au lieu de O(n²).
func _aura_sources() -> Array:
	if _aura_cache_valid:
		return _aura_cache
	var out := []
	for o in workers:
		for a in auras_of(o.card):
			out.append([o, a])
	return out


## Bonus de productivité reçu des AUTRES ouvriers présents sur la carte (Charismatique, Contremaître, Rabat-joie…).
func aura_mult(w: Worker) -> float:
	if w.offmap:
		return 1.0
	var bonus := 0.0
	for s in _aura_sources():
		var o: Worker = s[0]
		if o == w or o.offmap:
			continue
		var a: Dictionary = s[1]
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
	var c := int(data["buildings"]["extraction"]["capacite_portage"]) + int(card.metier.get("capacite_portage", 0))
	for u in card.upgrades:
		c += int(u.get("portage", 0))
	return c


func draw_hand(extra := 0) -> void:
	var size := hand_size() if extra == 0 else hand.size() + extra
	while hand.size() < size:
		if deck.is_empty():
			if discard.is_empty():
				break
			deck.assign(discard)
			discard.clear()
			_shuffle(deck)
		hand.append(deck.pop_back())
	version += 1


## Joue une carte d'action de la main. Usage unique : son effet s'applique, puis la carte quitte le deck.
## Rupture de contrat et Promotion visent un ouvrier (`target`) ; Promotion applique l'amélioration `option`,
## choisie parmi upgrade_options(target).
func play_action(card: Card, target: Card = null, option := {}) -> bool:
	if phase != "day" or not card.is_action() or not hand.has(card):
		return false
	var fx: Dictionary = card.action["effet"]
	if card.action.get("cible", false) and action_target_error(card, target) != "":
		return false
	if fx.has("ameliorer") and not upgrade_options(target).has(option):
		return false
	hand.erase(card)
	for k in ["productivite", "visiteurs"]:
		if fx.has(k):
			action_fx[k] = float(action_fx.get(k, 1.0)) * float(fx[k])
	for k in ["bois", "pierre"]:
		if fx.has(k):
			stock[k] += float(fx[k])
	prime_left += int(fx.get("prime", 0))
	if fx.has("pioche"):
		draw_hand(int(fx["pioche"]))
	if fx.has("xp"):
		for c in all_employees():
			gain_xp(c, float(fx["xp"]))
	if fx.has("licencier"):
		for pile in [deck, discard, hand]:
			pile.erase(target)
		say("%s a été licencié." % target.nom)
	if fx.has("ameliorer"):
		_apply_upgrade_effect(target, option)
		pending_upgrade = {}
	say("Carte jouée : %s. %s" % [card.action["nom"], card.action["texte"]] if not card.action.get("cible", false) \
		else "Carte jouée : %s." % card.action["nom"])
	version += 1
	return true


## Action d'un cadre (workers.json > metiers > jouer) : {} si la carte n'en a pas.
func cadre_action(card: Card) -> Dictionary:
	return {} if card.is_action() else card.metier.get("jouer", {})


## Pourquoi ce cadre ne peut pas être joué maintenant ("" s'il le peut). target : carte de la main (DRH),
## option : ressource à vendre (Marchand).
func cadre_error(card: Card, target: Card = null, option := "") -> String:
	var A := cadre_action(card)
	if A.is_empty():
		return "Ce métier n'a pas d'action"
	if phase != "day":
		return "Seulement de jour"
	if not hand.has(card) or card.deployed:
		return "Déjà sur le terrain"
	match A.get("cible", ""):
		"main":
			if target == null or target == card or not hand.has(target) or target.deployed or target.is_action():
				return "Choisissez un ouvrier de votre main"
			if employees() <= 2:
				return "Pas assez d'ouvriers"
		"ressource":
			if not option in ["bois", "pierre"] or stock.get(option, 0.0) < 1.0:
				return "Rien à vendre"
	return ""


## Joue un cadre de la main pour son action : il ne travaille pas aujourd'hui (pas de salaire) et part à la défausse.
func play_cadre(card: Card, target: Card = null, option := "") -> bool:
	if cadre_error(card, target, option) != "":
		return false
	var A := cadre_action(card)
	var fx: Dictionary = A["effet"]
	var extra := ""
	hand.erase(card)
	discard.append(card)
	for k in ["construction", "boutiques"]:
		if fx.has(k):
			action_fx[k] = maxf(float(action_fx.get(k, 1.0)), float(fx[k]))
	for k in ["sans_defauts"]:
		if fx.has(k):
			action_fx[k] = true
	if fx.has("attractivite"):
		action_fx["attractivite"] = int(action_fx.get("attractivite", 0)) + int(fx["attractivite"])
	if fx.has("xp_soir"):
		action_fx["xp_soir"] = float(action_fx.get("xp_soir", 0.0)) + float(fx["xp_soir"])
	if fx.has("vente"):
		var units := floorf(stock[option])
		var gain := floorf(units * float(data["buildings"]["conversion"][option]) * float(fx["vente"]) \
			* float(event_effects().get("prix", {}).get(option, 1.0)))
		stock[option] -= units
		money += gain
		extra = " %d %s vendus pour %d." % [int(units), option, int(gain)]
	if fx.has("annule_evenement"):
		if event_is_negative():
			action_fx["sans_evenement"] = true
			extra = " L'événement « %s » ne vous touche plus aujourd'hui." % mt.current_event.get("nom", "")
		else:
			influence += float(fx["influence"])
			extra = " Pas d'événement à annuler : +%d d'influence." % int(fx["influence"])
	if fx.has("licencier_main"):
		hand.erase(target)
		extra = " %s a été licencié." % target.nom
		draw_hand(int(fx.get("pioche", 0)))
	say("%s joue %s.%s" % [card.nom, A["nom"], extra if extra != "" else " " + A["texte"]])
	version += 1
	return true


## Pourquoi un ouvrier ne peut pas être visé par cette carte d'action ("" s'il le peut).
func action_target_error(card: Card, target: Card) -> String:
	if target == null or not all_employees().has(target):
		return "Choisissez un de vos ouvriers"
	if card.action["effet"].has("licencier"):
		if target.deployed:
			return "Sur le terrain aujourd'hui"
		if employees() <= 1:
			return "Votre dernier ouvrier"
	return ""


# --- Déploiement et ordres ---------------------------------------------------

func say(text: String) -> void:
	messages.append({"text": text, "at": Time.get_ticks_msec()})


## Déploie une carte de la main. Gratuit : sans salaire mais à 25 % de rendement (un par jour).
func deploy(card: Card, free := false) -> bool:
	if phase != "day" or card.deployed or card.is_action():
		return false
	if free:
		if free_used_today:
			return false
		free_used_today = true
	elif prime_left > 0:
		prime_left -= 1  # carte Prime : pas de salaire, rendement plein
	else:
		var cost := salary(card)
		if money < cost:
			say("Pas assez d'argent pour payer %s (%d)." % [card.nom, cost])
			return false
		money -= cost
		day_stats["salaires"] += cost
	card.deployed = true
	var w := Worker.new()
	w.card = card
	w.unpaid = free
	w.pos = Vector2(map.camp.get_center()) + Vector2(0.5, 0.5)
	# Matinal : commence la journée sur sa dernière case de travail plutôt qu'au camp.
	var last := card.last_work_tile
	if card.traits.has("matinal") and last.x >= 0 and map.passable(last.x, last.y):
		w.pos = Vector2(last) + Vector2(0.5, 0.5)
	workers.append(w)
	version += 1
	return true


## Apparence d'une carte ouvrier ; une carte sans personnage (tests) en reçoit un d'après son numéro.
func perso_of(card: Card) -> Dictionary:
	var all: Array = data["personnages"]["personnages"]
	if _persos.is_empty():
		for p in all:
			_persos[p["id"]] = p
	return _persos.get(card.perso, all[card.id % all.size()])


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
			# Un Architecte col blanc ne construit pas, mais il supervise (économie de ressources).
			if w.card.traits.has("col_blanc") and w.card.metier["id"] != "architecte":
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
		if site and site.done and site.def_id() == "formation":
			_station(w, "formation", site, target)
			continue
		if site and site.done and site.def_id() == "cuisine":
			w.task = {"type": "feed", "site": site, "phase": "to_kitchen", "rations": 0.0, "prep": 0.0}
			_set_path(w, target)
			continue
		if site and site.done and site.def_id() == "entretien":
			w.task = {"type": "clean", "site": site, "t": 0.0}
			_set_path(w, target)
			continue
		if site and site.done and site.def_id() in ["snack", "kiosque"]:
			_station(w, site.def_id(), site, target)
			continue
		if site and site.done and site.def_id() == "boutique":
			_station(w, "shop", site, target)
			if job != "vendeur":
				say("Seul un Vendeur de souvenirs double les ventes de la boutique.")
			continue
		if map.in_camp(target.x, target.y) and job == "marchand":
			_station(w, "trade", null, target)
			continue
		if site and site.done and site.def_id() == "comptoir":
			if job == "marchand":
				_station(w, "trade", site, target)
			else:
				say("Seul un Marchand peut tenir le Marché.")
			continue
		var animal := animal_at(target)
		if animal and job == "soigneur":
			_station(w, "care", animal, target)
			continue
		if (map.in_camp(target.x, target.y) or in_depot(target)) and w.carry > 0.0:
			# Clic droit sur le camp ou un entrepôt : l'ouvrier y dépose sa charge.
			w.task = {"type": "deposit"}
			_set_path(w, target)
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
	# Les traits et la liste des ouvriers ne changent pas pendant un pas : les auras sont listées une fois.
	_aura_cache_valid = false
	_aura_cache = _aura_sources()
	_aura_cache_valid = true
	for w in workers:
		_update_worker(w, dt)
	_aura_cache_valid = false
	_animals_eat(dt)
	_update_visitors(dt)


func _move(w: Worker, dt: float) -> void:
	var budget := dt
	while not w.path.is_empty() and budget > 0.0:
		var t := w.tile()
		var spd := speed(w.card) * map.move_speed(t.x, t.y) * speed_mult()
		if w.unpaid:
			spd *= float(data["workers"]["regles"]["deploiement_gratuit"].get("vitesse", 1.0))
		if w.card.traits.has("casanier") and w.pos.distance_to(Vector2(map.camp.get_center())) > 15.0:
			spd *= 0.7
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
		if not campaign.is_empty():
			campaign["progress"] += campaign_rate(w.card) * unpaid_mult(w) * dt
			if campaign["progress"] >= float(campaign["def"]["travail"]):
				publicite += float(campaign["def"]["points"])
				say("Campagne terminée : %s. Visiteurs ×%.2f." % [campaign["def"]["nom"], publicity_mult()])
				campaign = {}
				version += 1
		return
	if w.pause_left > 0.0:
		w.pause_left -= dt
		return
	if w.task.get("type") == "clean":
		_sweep(w, dt)  # l'agent d'entretien nettoie aussi en marchant dans l'enceinte
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
		"feed":
			_update_feed(w, dt)
		"clean":
			_update_clean(w, dt)
		"station":
			if w.tile() != w.task["tile"]:
				_set_path(w, w.task["tile"])
			elif w.task["kind"] in ["shop", "ticket"]:
				staffed_time[w.task["obj"]] = staffed_time.get(w.task["obj"], 0.0) + dt
				if w.task["kind"] == "shop" and w.card.metier["id"] == "vendeur":
					vendeur_time[w.task["obj"]] = vendeur_time.get(w.task["obj"], 0.0) + dt
			elif w.task["kind"] == "care":
				var pet: Animal = w.task["obj"]
				cared_today[pet] = true
				if pet.sick and can_heal(w.card):
					pet.heal += efficiency_at(w, "soigner") * dt
					if pet.heal >= float(data["buildings"]["zoo"]["maladie"]["soin_travail"]):
						pet.sick = false
						pet.heal = 0.0
						say("%s est guéri." % pet.def["nom"])
						version += 1
			elif w.task["kind"] == "formation":
				_train(w, dt)
		"deposit":
			if in_depot(w.tile()):
				_unload(w)
			w.task = {}
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
			if _refuses_near_predator(w):
				return
			w.card.last_work_tile = w.tile()
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
				_unload(w)
				task["phase"] = "to_resource"
				var tg: Vector2i = task["target"]
				if map.extractible(tg.x, tg.y) != task["res"]:
					_retarget(w)
				else:
					_set_path(w, tg)


func _unload(w: Worker) -> void:
	if w.carry > 0.0:
		stock[w.carry_type] += w.carry
		day_stats[w.carry_type] += w.carry
	w.carry = 0.0


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
	if def.get("sur", "") == "camp":
		return map.camp  # amélioration du camp : toujours sur le camp, où que l'on clique
	return Rect2i(origin, Vector2i(int(def["taille"][0]), int(def["taille"][1])))


## Taille de la main : règle de base + 1 carte par amélioration du camp terminée.
func hand_size() -> int:
	var n := int(data["workers"]["regles"]["taille_main"])
	for s in sites:
		if s.done:
			n += int(s.def.get("effet", {}).get("pioche", 0))
	return n


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
	# Amélioration du camp : sur le camp, une seule fois, dans l'ordre des niveaux.
	if def.get("sur", "") == "camp":
		if has_building(id):
			return "Déjà construit"
		if def.has("requiert") and not sites.any(func(s): return s.done and s.def_id() == def["requiert"]):
			return "Terminez d'abord : %s" % building_def(def["requiert"])["nom"]
		if sites.any(func(s): return not s.done and s.def.get("sur", "") == "camp"):
			return "Une amélioration du camp est déjà en chantier"
		if check_cost and not can_afford(def.get("cout", {})):
			return "Pas assez de ressources (%s)" % cost_text(def.get("cout", {}))
		return ""
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
		if def.get("effet", {}).has("decor"):
			var denc := enclosure_at(r.position)
			if not denc["closed"] or denc.get("park", false):
				return "À placer dans un enclos (clôturé ou en chantier)"
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
	if s.def_id() == "enclos" or s.def.get("effet", {}).has("decor"):
		_check_pending_installs()


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
	if _refuses_near_predator(w):
		return
	w.card.last_work_tile = w.tile()
	s.savings = minf(s.savings, resource_mult(w.card))
	# Un Architecte col blanc supervise sans travailler de ses mains.
	if not w.card.traits.has("col_blanc"):
		var rate := efficiency_at(w, s.type_travail())
		# Visionnaire (Paysagiste) : aménager à côté d'une case déjà du type voulu va 2× plus vite.
		if s.kind == "amenagement" and has_capacity(w.card, "visionnaire") and _next_to_terrain(s.rect.position, str(s.def["vers"])):
			rate *= 2.0
		s.work += rate * dt
	_work_traits(w, dt)
	if s.work >= s.travail():
		_complete(s)


## Trait Peureux : refuse de travailler près d'un enclos de prédateur (la tâche est abandonnée).
func _refuses_near_predator(w: Worker) -> bool:
	if not w.card.traits.has("peureux") or not near_predator(w.tile()):
		return false
	say("%s a peur des fauves : il refuse de travailler si près d'un prédateur." % w.card.nom)
	w.task = {}
	return true


func _next_to_terrain(t: Vector2i, terrain: String) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q: Vector2i = t + d
		if map.in_bounds(q.x, q.y) and GameMap.TERRAINS[map.get_t(q.x, q.y)] == terrain:
			return true
	return false


## Centre de formation : les ouvriers postés gagnent de l'expérience (×2 si un Formateur est posté aussi).
## Places limitées (capacite_formation, +2 avec un Formateur Pédagogue) : les premiers arrivés sont formés.
func _train(w: Worker, dt: float) -> void:
	if w.card.metier["id"] == "formateur":
		return  # il forme les autres
	var s: Site = w.task["obj"]
	var present := workers.filter(func(o): return o.task.get("kind") == "formation" and o.task.get("obj") == s \
		and o.path.is_empty() and o.tile() == o.task["tile"])
	var trainers := present.filter(func(o): return o.card.metier["id"] == "formateur")
	var trainees := present.filter(func(o): return o.card.metier["id"] != "formateur")
	var fx: Dictionary = s.def["effet"]
	var places := int(fx["capacite_formation"]) + (2 if trainers.any(func(o): return has_capacity(o.card, "pedagogue")) else 0)
	if trainees.find(w) >= places:
		return
	var rate := float(fx["xp_par_minute"]) * (2.0 if not trainers.is_empty() else 1.0) * unpaid_mult(w)
	gain_xp(w.card, rate * dt / 60.0)


func _complete(s: Site) -> void:
	s.done = true
	if s.def_id() == "enclos" or s.def.get("effet", {}).has("decor"):
		_check_pending_installs()
	var p := s.rect.position
	# Architecte / Débrouillard : une partie des ressources payées est remboursée.
	if s.savings < 1.0:
		var refund: Array[String] = []
		for k in s.paid:
			var back := floorf(float(s.paid[k]) * (1.0 - s.savings))
			if back <= 0.0:
				continue
			if k == "argent":
				money += back
			else:
				stock[k] += back
			refund.append("%d %s" % [int(back), k])
		if not refund.is_empty():
			say("%s : économie de %s." % [s.def["nom"], ", ".join(refund)])
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


## Ouvriers employés (le logement les limite) ; les cartes d'action ne comptent pas.
func employees() -> int:
	return all_employees().size()


# --- Fin de journée ----------------------------------------------------------

func _reset_day_stats() -> void:
	day_stats = {"bois": 0.0, "pierre": 0.0, "or": 0.0, "influence": 0.0, "salaires": 0.0, "nourriture": 0.0}


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
			a.food = food_capacity(a.def)  # il arrive avec une journée de rations
			arrivals.append(a.def["nom"])
	var income := _close_zoo_day()  # les recettes ont été encaissées pendant la journée
	var fallen_ill := _roll_diseases()
	version += 1  # invalide le cache de l'enceinte (nouveaux animaux)
	# Emprunt du jour : remboursé automatiquement, quitte à passer en négatif.
	if loan_today:
		var back := float(data["workers"]["regles"]["emprunt"]["remboursement"])
		money -= back
		day_stats["emprunt"] = back
		say("Emprunt remboursé : %d (solde %d)." % [int(back), floori(money)])
	for w in workers:
		_unload(w)  # la charge portée est encaissée le soir
		var card := w.card
		card.jours_travailles += 1
		gain_xp(card, 1.0 + float(action_fx.get("xp_soir", 0.0)))  # Formateur joué (Cours du soir)
		# Réseau (Lobbyiste) : +1 influence chaque soir où il a été déployé.
		if has_capacity(card, "reseau"):
			influence += 1.0
		card.deployed = false
	# Montées de niveau (journées de travail et Centre de formation) : une amélioration gratuite au choix par niveau.
	for card in all_employees():
		while card.niveau < int(regles["niveau_max"]) and card.xp >= xp_next_level(card) - 0.0001:
			card.niveau += 1
			level_ups.append(card)
			level_choices.append({"card": card, "options": _upgrade_pool(card)})
	night_report = {"day": day, "stats": day_stats.duplicate(), "level_ups": level_ups, "deployed": workers.size(),
		"arrivals": arrivals, "income": income, "malades": fallen_ill}
	workers.clear()
	for c in hand:
		c.deployed = false  # cartes d'action jouées comprises
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
	pending_upgrade = {}
	action_fx = {}
	prime_left = 0
	swapped_today = false
	loan_today = false
	# Améliorations de niveau non choisies pendant la nuit : la première proposée est appliquée.
	while not level_choices.is_empty():
		var lc: Dictionary = level_choices[0]
		choose_level_upgrade(lc["card"], lc["options"][0])
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
	# Chasseur de têtes : un DRH de l'équipe négocie 3 de moins.
	if all_employees().any(func(c): return has_capacity(c, "chasseur_tetes")):
		base -= 3.0
	return maxi(int(regles["cout_min_embauche"]), roundi(base))


func hire_error(card: Card) -> String:
	if phase != "night":
		return "Le marché n'ouvre que la nuit"
	if mt.night_stage != "ouvriers":
		return "Embauche à l'étape Ouvriers"
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
	mt.record_purchase(index, card)
	say("%s rejoint votre équipe (dans la défausse)." % card.nom)
	if not mt.is_ai(index):
		mt.pass_turn()  # une embauche par nuit : au suivant
	mt.bump()
	return true


## Coût réel d'un contrat pour ce joueur : le prix en argent monte avec le nombre d'animaux
## déjà possédés ou en attente, et le 2e contrat de la nuit coûte plus cher. L'or ne change pas.
func contract_cost(def: Dictionary) -> Dictionary:
	var m: Dictionary = data["buildings"]["marche"]
	var cost: Dictionary = def.get("cout", {}).duplicate()
	if cost.has("argent"):
		var mult := 1.0 + float(m["hausse_prix_par_animal"]) * (animals.size() + contracts.size() + pending_installs.size())
		if contracts_tonight >= 1:
			mult *= 1.0 + float(m["surcout_2e_contrat"])
		cost["argent"] = roundi(float(cost["argent"]) * mult)
	return cost


func contract_error(def: Dictionary) -> String:
	if phase != "night":
		return "Le marché n'ouvre que la nuit"
	if mt.night_stage != "contrats":
		return "Contrats à l'étape Contrats"
	if mt.current_buyer() != index:
		return "Ce n'est pas votre tour au marché"
	if contracts_tonight >= int(data["buildings"]["marche"]["contrats_par_nuit"]):
		return "Déjà %d contrats achetés cette nuit" % contracts_tonight
	if has_species(def["id"]):
		return "Vous avez déjà cette espèce"
	if not can_afford(contract_payment(def)):
		return "Pas assez d'argent (%d, or manquant compris)" % int(contract_payment(def)["argent"])
	return ""


## Ce que l'achat d'un contrat prélève : l'or du stock, puis l'or manquant acheté en argent au prix du marché
## (double du prix de revente). L'argent de fin de partie ouvre ainsi les T3, la mine restant plus rentable.
func contract_payment(def: Dictionary) -> Dictionary:
	var cost := contract_cost(def)
	var need_or := float(cost.get("or", 0))
	var from_stock := minf(need_or, floorf(float(stock["or"])))
	var pay := {"argent": float(cost.get("argent", 0)) + ceilf((need_or - from_stock) * buy_price("or"))}
	if from_stock > 0.0:
		pay["or"] = from_stock
	return pay


## Or manquant pour ce contrat (acheté en argent au moment de l'achat).
func contract_gold_missing(def: Dictionary) -> int:
	return int(float(contract_cost(def).get("or", 0)) - float(contract_payment(def).get("or", 0.0)))


func buy_contract(def: Dictionary) -> bool:
	if contract_error(def) != "" or not market_contracts.has(def):
		return false
	var missing := contract_gold_missing(def)
	_pay(contract_payment(def))
	if missing > 0:
		say("%d or acheté pour le contrat (%d argent)." % [missing, int(ceilf(missing * buy_price("or")))])
	market_contracts.erase(def)
	contracts.append(def)
	contracts_tonight += 1
	mt.record_purchase(index, def)
	say("Contrat acheté : %s. Construisez-lui un enclos." % def["nom"])
	if not mt.is_ai(index) and contracts_tonight >= int(data["buildings"]["marche"]["contrats_par_nuit"]):
		mt.pass_turn()
	mt.bump()
	return true


func has_species(id: String) -> bool:
	return contracts.any(func(d): return d["id"] == id) or animals.any(func(a): return a.def["id"] == id) \
		or pending_installs.any(func(r): return r["def"]["id"] == id)


## Emprunt : possible une fois par jour quand aucun ouvrier de la main ne peut être payé.
func loan_error() -> String:
	if phase != "day":
		return "Uniquement en journée"
	if loan_today:
		return "Déjà un emprunt aujourd'hui"
	var waiting := hand.filter(func(c): return not c.is_action() and not c.deployed)
	if waiting.is_empty():
		return "Aucun ouvrier à déployer"
	if prime_left > 0 or waiting.any(func(c): return money >= salary(c)):
		return "Vous pouvez encore payer un ouvrier"
	return ""


func take_loan() -> bool:
	if loan_error() != "":
		return false
	var L: Dictionary = data["workers"]["regles"]["emprunt"]
	money += float(L["montant"])
	loan_today = true
	say("Emprunt de %d : %d seront retirés ce soir." % [int(L["montant"]), int(L["remboursement"])])
	version += 1
	return true


## Agence d'intérim : en journée, remplacer un ouvrier sur le terrain par une carte de sa pioche ou de sa défausse.
func agency_built() -> bool:
	return sites.any(func(s): return s.done and s.def_id() == "agence")


func swap_candidates() -> Array[Card]:
	var out: Array[Card] = []
	for pile in [deck, discard]:
		for c in pile:
			if not c.is_action():
				out.append(c)
	return out


## Frais de l'agence + salaire du remplaçant (celui de l'ouvrier remplacé n'est pas rendu).
func swap_cost(take: Card) -> int:
	return int(data["buildings"]["agence"]["frais"]) + salary(take)


func swap_error(w: Worker, take: Card) -> String:
	if phase != "day":
		return "Uniquement en journée"
	if not agency_built():
		return "Construisez une Agence d'intérim"
	if swapped_today:
		return "Déjà un échange aujourd'hui"
	if w == null or not workers.has(w):
		return "Choisissez un ouvrier sur le terrain"
	if w.offmap:
		return "Rappelez-le d'abord sur la carte"
	if take == null or not swap_candidates().has(take):
		return "Choisissez une carte de la pioche ou de la défausse"
	if money < swap_cost(take):
		return "Pas assez d'argent (%d)" % swap_cost(take)
	return ""


## Le remplaçant arrive à la place de l'ouvrier, garde sa charge et reprend sa tâche ; l'ouvrier remplacé
## part à la défausse (sans expérience pour la journée).
func swap_worker(w: Worker, take: Card) -> bool:
	if swap_error(w, take) != "":
		return false
	money -= swap_cost(take)
	day_stats["salaires"] += salary(take)
	var target := _task_target(w)
	var old := w.card
	old.deployed = false
	hand.erase(old)
	discard.append(old)
	deck.erase(take)
	discard.erase(take)
	take.deployed = true
	hand.append(take)
	w.card = take
	w.unpaid = false
	w.pause_left = 0.0
	w.task = {}
	w.path.clear()
	swapped_today = true
	if target.x >= 0:
		order([w], target)
	say("Agence d'intérim : %s remplace %s (%d)." % [take.nom, old.nom, swap_cost(take)])
	version += 1
	return true


## Case visée par la tâche d'un ouvrier (pour la confier à son remplaçant), (-1, -1) s'il n'y en a pas.
func _task_target(w: Worker) -> Vector2i:
	match w.task.get("type", ""):
		"extract":
			return w.task["target"]
		"station":
			return w.task["tile"]
		"build", "feed", "clean":
			return w.task["site"].rect.position
	return Vector2i(-1, -1)


## Licenciement par le DRH (s'il a été déployé dans la journée).
func fire(card: Card) -> bool:
	if phase != "night" or drh_available <= 0 or mt.night_stage != "equipe":
		return false
	for pile in [deck, discard, hand]:
		if pile.has(card):
			pile.erase(card)
			drh_available -= 1
			say("%s a été licencié." % card.nom)
			version += 1
			return true
	return false


## Bonus du lendemain : seul le premier en influence le choisit parmi ceux offerts, et il s'applique à tous.
func bonus_error(def: Dictionary) -> String:
	if phase != "night":
		return "Uniquement la nuit"
	if mt.night_stage != "bonus":
		return "Bonus à l'étape Bonus"
	if mt.influence_leader() != index:
		return "Seul le premier en influence choisit (%s)" % mt.names[mt.influence_leader()]
	if not mt.bonus_choice.is_empty():
		return "Bonus déjà choisi : %s" % mt.bonus_choice["nom"]
	if not mt.bonus_offer.has(def):
		return "Bonus non proposé cette nuit"
	return ""


func pick_bonus(def: Dictionary) -> bool:
	if bonus_error(def) != "":
		return false
	mt.bonus_choice = def
	if not mt.is_ai(index):
		mt.confirm_bonus()
	mt.bump()
	return true


func night_action_rules() -> Dictionary:
	return data["workers"]["regles"]["actions_nuit"]


func night_action_error(cost: int) -> String:
	if phase != "night":
		return "Uniquement la nuit"
	if mt.night_stage != "equipe":
		return "Améliorations et licenciements à la dernière étape de la nuit (Équipe)"
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
	pending_upgrade = {"card": card, "options": _upgrade_pool(card)}
	version += 1
	return pending_upgrade["options"]


const LIBELLES_TACHES := {
	"extraire_bois": "Extraction de bois", "extraire_pierre": "Extraction de pierre", "construire_bois": "Construction en bois",
	"construire_pierre": "Construction en pierre", "construire_route": "Routes", "construire_enclos": "Clôtures d'enclos",
	"guichet": "Guichet",
}


## Améliorations proposées à une carte : génériques utiles pour elle + celles de son métier, tirées au hasard.
## 3 au choix (Têtu : 2). « Seconde spécialité » désigne au tirage une tâche hors de son métier.
func _upgrade_pool(card: Card) -> Array:
	var n := int(data["workers"]["regles"]["choix_ameliorations"])
	for t in trait_defs(card):
		n = mini(n, int(t["effet"].get("choix_ameliorations", n)))
	# Évolution (Apprenti, Manœuvre) : au niveau prévu, on choisit son nouveau métier au lieu d'une amélioration.
	var evo: Dictionary = data["workers"].get("evolutions", {}).get(card.metier["id"], {})
	if not evo.is_empty() and card.niveau == int(evo["niveau"]):
		var choices: Array = evo["vers"].duplicate()
		mt.shuffle(choices)
		var evolutions := []
		for id in choices.slice(0, n):
			var m := metier_def(id)
			evolutions.append({"id": "evolution", "nom": "Devenir %s" % m["nom"], "metier": id, "effet": {},
				"texte": "%s (%s)" % [specialite_text(m), category_label(m["categorie"])]})
		return evolutions
	var has_neg := card.traits.any(func(t): return not is_positive(t))
	var specs: Array = LIBELLES_TACHES.keys().filter(func(k): return not card.metier["efficacite"].has(k) \
		and not card.upgrades.any(func(u): return u.get("seconde_specialite", "") == k))
	var pool: Array = data["workers"]["ameliorations_generiques"].filter(func(u):
		return (u["id"] != "guerison" or has_neg) and (u["id"] != "salaire_down" or salary(card) > 0) \
			and (u["id"] != "double_spe" or not specs.is_empty()))
	pool.append_array(data["workers"]["ameliorations_metier"].get(card.metier["id"], []).filter(func(u):
		return not card.upgrade_names.has(u["nom"])))
	mt.shuffle(pool)
	var out := []
	for u in pool.slice(0, n):
		if u["id"] == "double_spe":
			var task: String = specs[mt.rng.randi_range(0, specs.size() - 1)]
			u = {"id": "double_spe", "nom": "Seconde spécialité : %s" % LIBELLES_TACHES[task],
				"effet": {"seconde_specialite": task}, "texte": "%s : efficacité 1,4" % LIBELLES_TACHES[task]}
		out.append(u)
	return out


func metier_def(id: String) -> Dictionary:
	for m in data["workers"]["metiers"]:
		if m["id"] == id:
			return m
	return {}


func category_label(cat: String) -> String:
	return {"peu_qualifie": "peu qualifié", "qualifie": "qualifié", "cadre": "cadre"}.get(cat, cat)


## Spécialité d'un métier en clair (ex. « Construction en bois ×1,8 »), ou sa capacité.
func specialite_text(m: Dictionary) -> String:
	var noms := LIBELLES_TACHES.merged({"amenager": "Aménager", "nourrir": "Nourrir", "nettoyer": "Nettoyer", "animer": "Animer", "lobbying": "Lobbying"})
	var parts: Array[String] = []
	for k in m["efficacite"]:
		if k != "defaut":
			parts.append("%s ×%s" % [noms.get(k, k), str(m["efficacite"][k]).replace(".", ",")])
	return ", ".join(parts) if not parts.is_empty() else str(m.get("capacite", "Polyvalent"))


## Applique l'effet d'une amélioration (sans coût) : guérison, nouveau trait, évolution, ou effet ajouté à la carte.
func _apply_upgrade_effect(card: Card, option: Dictionary) -> void:
	match option["id"]:
		"evolution":
			card.metier = metier_def(option["metier"])
			say("%s devient %s !" % [card.nom, card.metier["nom"]])
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
	say("%s : amélioration « %s »." % [card.nom, option["nom"]])
	version += 1


## Amélioration payante de milieu de partie (action de nuit).
func apply_upgrade(card: Card, option: Dictionary) -> bool:
	var cost := int(night_action_rules()["cout_amelioration"])
	if night_action_error(cost) != "" or not all_employees().has(card):
		return false
	money -= cost
	_apply_upgrade_effect(card, option)
	night_action_used = true
	pending_upgrade = {}
	return true


## Amélioration gratuite gagnée à une montée de niveau : choisie parmi les options proposées pour cette carte.
func choose_level_upgrade(card: Card, option: Dictionary) -> bool:
	for i in level_choices.size():
		var lc: Dictionary = level_choices[i]
		if lc["card"] == card and lc["options"].has(option):
			level_choices.remove_at(i)
			_apply_upgrade_effect(card, option)
			return true
	return false


## Tous les ouvriers du joueur (main, pioche, défausse), sans les cartes d'action.
func all_employees() -> Array[Card]:
	var out: Array[Card] = []
	for pile in [hand, deck, discard]:
		for c in pile:
			if not c.is_action():
				out.append(c)
	return out


## Cartes d'action possédées (main, pioche, défausse).
func action_cards() -> Array[Card]:
	var out: Array[Card] = []
	for pile in [hand, deck, discard]:
		for c in pile:
			if c.is_action():
				out.append(c)
	return out


## Achat d'une carte d'action au marché de nuit (1 par nuit, dans l'ordre d'influence) : elle va à la défausse.
func action_error(card: Card) -> String:
	if phase != "night":
		return "Le marché n'ouvre que la nuit"
	if mt.night_stage != "cartes":
		return "Cartes à l'étape Cartes"
	if mt.current_buyer() != index:
		return "Ce n'est pas votre tour au marché"
	if bought_action:
		return "Déjà une carte d'action achetée cette nuit"
	if money < float(card.action["cout"]):
		return "Pas assez d'argent"
	return ""


func buy_action(card: Card) -> bool:
	if action_error(card) != "" or not mt.market_actions.has(card):
		return false
	money -= float(card.action["cout"])
	mt.market_actions.erase(card)
	discard.append(card)
	bought_action = true
	mt.record_purchase(index, card)
	say("Carte d'action achetée : %s (dans la défausse)." % card.action["nom"])
	if not mt.is_ai(index):
		mt.pass_turn()
	mt.bump()
	return true


# --- Enclos, animaux et réputation -------------------------------------------

func is_fence(t: Vector2i) -> bool:
	var s := site_at(t)
	return s != null and s.done and s.def_id() == "enclos"


## Zone fermée par des clôtures d'enclos autour de la case t (remplissage 4 directions).
## À défaut, dans l'enceinte du zoo : le parc libre (hors enclos et hors bâtiments) sert d'enclos.
## Une zone que des clôtures d'enclos encore en chantier ferment est un enclos « prévu » (planned) : l'animal y est
## réservé et n'arrive qu'une fois les clôtures terminées.
func enclosure_at(t: Vector2i) -> Dictionary:
	var enc := _fenced_enclosure(t)
	if enc["closed"] or not map.in_bounds(t.x, t.y) or is_fence(t):
		return enc
	var planned := _planned_enclosure(t)
	if not planned.is_empty():
		return planned
	return _park_enclosure(t, enc["reason"])


func _is_fence_site(t: Vector2i) -> bool:
	var s := site_at(t)
	return s != null and not s.done and s.def_id() == "enclos"


func _planned_enclosure(t: Vector2i) -> Dictionary:
	if _is_fence_site(t):
		return {}
	var seen := {t: true}
	var stack: Array[Vector2i] = [t]
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var unfinished := false
	var gate := false
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in dirs:
			var q := p + d
			if not map.in_bounds(q.x, q.y) or seen.size() >= 120:
				return {}
			if seen.has(q):
				continue
			if is_fence(q):
				continue
			if is_wall(q) or (site_at(q) != null and site_at(q).def_id() in ["cloture", "entree"]):
				if site_at(q).def_id() == "entree":
					gate = true
				continue
			if _is_fence_site(q):
				unfinished = true
				continue
			seen[q] = true
			stack.append(q)
	if not unfinished or gate:
		return {}
	var tiles: Array[Vector2i] = []
	tiles.assign(seen.keys())
	return {"closed": true, "tiles": tiles, "planned": true}


## Réservations : une fois les clôtures terminées, l'animal s'installe ; si le chantier est abandonné, le contrat revient.
func _check_pending_installs() -> void:
	for r in pending_installs.duplicate():
		var enc := enclosure_at(r["tile"])
		if enc.get("planned", false) or (enc["closed"] and decor_waiting(r["def"], enc)):
			continue
		pending_installs.erase(r)
		contracts.append(r["def"])
		if enc["closed"] and not enc.get("park", false):
			var err := install_animal(r["def"], r["tile"])
			if err != "":
				say("%s ne peut pas s'installer : %s. Le contrat revient dans vos contrats." % [r["def"]["nom"], err])
		else:
			say("Enclos de %s abandonné : le contrat revient dans vos contrats." % r["def"]["nom"])
	version += 1


## Annule une réservation : le contrat revient dans les contrats à installer.
func cancel_pending(r: Dictionary) -> void:
	if pending_installs.has(r):
		pending_installs.erase(r)
		contracts.append(r["def"])
		version += 1


func _park_enclosure(t: Vector2i, reason: String) -> Dictionary:
	var interior: Dictionary = zoo_status()["interior"]
	if not interior.has(t) or site_at(t) != null:
		return {"closed": false, "reason": reason}
	var seen := {t: true}
	var stack: Array[Vector2i] = [t]
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in dirs:
			var q := p + d
			if seen.has(q) or not interior.has(q) or is_fence(q) or _is_fence_site(q):
				continue
			seen[q] = true
			stack.append(q)
	var tiles: Array[Vector2i] = []
	for q in seen:
		if site_at(q) == null:
			tiles.append(q)
	return {"closed": true, "tiles": tiles, "park": true}


## Identifiant d'un enclos : sa plus petite case (ordre ligne puis colonne), ou (-1, -1) pour le parc libre.
func enclosure_key(enc: Dictionary) -> Vector2i:
	if enc.get("park", false):
		return Vector2i(-1, -1)
	var best: Vector2i = enc["tiles"][0]
	for t in enc["tiles"]:
		if t.y < best.y or (t.y == best.y and t.x < best.x):
			best = t
	return best


## Cases d'un enclos libres pour un nouveau motif (hors motifs des animaux déjà installés).
func free_enclosure_tiles(enc: Dictionary) -> Array:
	var key := enclosure_key(enc)
	var used := {}
	for a in animals:
		if a.key == key:
			for p in a.pattern_tiles:
				used[p] = true
	return enc["tiles"].filter(func(p): return not used.has(p) and not is_decor(p))


## Les murs de l'enceinte peuvent servir de côté à un enclos : la zone doit alors toucher au moins une
## clôture d'enclos, et pas l'entrée (sinon c'est l'allée du parc, pas un enclos).
func _fenced_enclosure(t: Vector2i) -> Dictionary:
	var open_msg := "Enclos non fermé : entourez la zone de clôtures d'enclos terminées (le mur de l'enceinte peut servir de côté)"
	if not map.in_bounds(t.x, t.y) or is_fence(t) or is_wall(t):
		return {"closed": false, "reason": "Visez l'intérieur d'un enclos"}
	var seen := {t: true}
	var stack: Array[Vector2i] = [t]
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var fenced := false
	var gate := false
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		for d in dirs:
			var q := p + d
			if not map.in_bounds(q.x, q.y):
				return {"closed": false, "reason": open_msg}
			if seen.has(q):
				continue
			if is_fence(q):
				fenced = true
				continue
			if is_wall(q):
				if site_at(q).def_id() == "entree":
					gate = true
				continue
			if seen.size() >= 120:
				return {"closed": false, "reason": open_msg}
			seen[q] = true
			stack.append(q)
	if not fenced or gate:
		return {"closed": false, "reason": open_msg}
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
	# Enclos partagé : la surface doit couvrir tous les animaux ; un prédateur reste seul, et jamais en liberté.
	var predator: bool = def.get("special", "") == "predateur"
	if predator and enc.get("park", false):
		return "Un prédateur a besoin d'un enclos clôturé"
	var key := enclosure_key(enc)
	var need := int(def["taille"])
	var mates := 0
	for a in animals:
		if a.key == key:
			if predator or a.def.get("special", "") == "predateur":
				return "Un prédateur ne partage pas son enclos (%s)" % a.def["nom"]
			need += int(a.def["taille"])
			mates += 1
	if tiles.size() < need:
		return "Enclos trop petit (%d / %d cases%s)" % [tiles.size(), need, " avec les %d animal(aux) déjà là" % mates if mates > 0 else ""]
	var ps := pattern_status(def, free_enclosure_tiles(enc))
	if not ps["found"]:
		return "Motif absent" if ps["missing"] >= 99 else "Motif absent (au mieux, %d case(s) à aménager)" % ps["missing"]
	var decor: String = def.get("decor", "")
	if decor != "" and decor_site(enc, decor) == null:
		return "Il faut un %s dans l'enclos (onglet Zoo)" % building_def(decor)["nom"]
	return ""


## Aménagement d'enclos (Grand arbre, Rocher d'observation…) posé dans l'enclos, terminé ou en chantier ; null sinon.
func decor_site(enc: Dictionary, decor: String) -> Site:
	for p in enc.get("tiles", []):
		var s := site_at(p)
		if s and s.def_id() == decor:
			return s
	return null


## L'aménagement requis est posé mais pas encore terminé : l'animal attend (réservé).
func decor_waiting(def: Dictionary, enc: Dictionary) -> bool:
	var decor: String = def.get("decor", "")
	if decor == "":
		return false
	var s := decor_site(enc, decor)
	return s != null and not s.done


func is_decor(t: Vector2i) -> bool:
	var s := site_at(t)
	return s != null and s.def.get("effet", {}).has("decor")


func install_animal(def: Dictionary, t: Vector2i) -> String:
	var enc := enclosure_at(t)
	if enc.get("park", false):
		return _install_with_fences(def, t)
	var err := animal_error(def, enc)
	if err != "":
		return err
	if enc.get("planned", false) or decor_waiting(def, enc):
		contracts.erase(def)
		pending_installs.append({"def": def, "tile": t})
		say("%s : enclos réservé. L'animal arrivera la nuit suivant la fin des chantiers de l'enclos." % def["nom"])
		version += 1
		return ""
	var a := Animal.new()
	a.def = def
	a.tiles.assign(enc["tiles"])
	a.key = enclosure_key(enc)
	a.park = enc.get("park", false)
	a.pattern_tiles.assign(pattern_status(def, free_enclosure_tiles(enc))["tiles"])
	animals.append(a)
	contracts.erase(def)
	say("%s : enclos validé, l'animal arrive cette nuit." % def["nom"])
	version += 1
	return ""


## Clic dans le parc sans clôture : l'animal n'y vit pas en liberté. On pose en chantier un enclos autour de la case
## (le plus petit où son motif existe, en reprenant clôtures et mur de l'enceinte) et l'animal y est réservé.
func _install_with_fences(def: Dictionary, t: Vector2i) -> String:
	if phase != "day":
		return "Installation possible uniquement de jour"
	var site := enclosure_site(def, t)
	if site.is_empty():
		return "Pas de place pour un enclos autour de cette case"
	if site["missing"] > 0:
		return "Motif absent autour de cette case (%d case(s) à aménager)" % site["missing"]
	var total := enclosure_cost(site)
	if not can_afford(total):
		return "Il faut %s pour cet enclos (%d segments de clôture%s)" % [cost_text(total), site["new"].size(),
			" et un " + building_def(site["decor"])["nom"] if site.has("decor") else ""]
	place_enclosure(site)
	var spot: Vector2i = site["pattern"][0]
	var enc := enclosure_at(spot)
	if not enc["closed"] or enc.get("park", false):
		return "Enclos impossible à fermer ici"
	return install_animal(def, spot)


## Enclos rectangulaire à construire pour un animal dans l'enceinte : le plus petit où son motif existe (sinon le plus
## proche, cases à aménager comptées dans missing), en reprenant les clôtures d'enclos et le mur de l'enceinte.
## Avec around, l'enclos doit contenir cette case. Renvoie {} si rien ne convient, sinon
## {"rect", "ring", "new" (segments à poser), "pattern", "missing", "area"}.
func enclosure_site(def: Dictionary, around := Vector2i(-1, -1)) -> Dictionary:
	var interior: Dictionary = zoo_status()["interior"]
	if interior.is_empty():
		return {}
	var need := int(def["taille"])
	var occupied := {}  # enclos habités ou réservés : on ne construit pas dedans
	for a in animals:
		if not a.park:
			for p in a.tiles:
				occupied[p] = true
		for p in a.pattern_tiles:
			occupied[p] = true
	for r in pending_installs:
		var penc := enclosure_at(r["tile"])
		if penc.get("planned", false):
			for p in penc["tiles"]:
				occupied[p] = true
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for p in interior:
		lo = Vector2i(mini(lo.x, p.x), mini(lo.y, p.y))
		hi = Vector2i(maxi(hi.x, p.x), maxi(hi.y, p.y))
	var fence_def := building_def("enclos")
	var ring_cache := {}
	var free := func(p: Vector2i) -> bool:
		return interior.has(p) and site_at(p) == null and not occupied.has(p) and not map.in_camp(p.x, p.y)
	var ring_ok := func(p: Vector2i) -> bool:
		if not ring_cache.has(p):
			var wall := is_wall(p) and site_at(p).def_id() == "cloture"
			ring_cache[p] = wall or (interior.has(p) and not occupied.has(p) \
				and (is_fence(p) or _is_fence_site(p) or placement_error("batiment", fence_def, p, false) == ""))
		return ring_cache[p]
	var sizes: Array[Vector2i] = []
	for w in range(2, 7):
		for h in range(2, 7):
			if w * h >= need and w * h <= need + 6:
				sizes.append(Vector2i(w, h))
	var decor: String = def.get("decor", "")
	sizes.sort_custom(func(a, b): return a.x * a.y < b.x * b.y or (a.x * a.y == b.x * b.y and absi(a.x - a.y) < absi(b.x - b.y)))
	var best := {}
	var best_score := INF
	for sz in sizes:
		# Le premier enclos de surface minimale où le motif existe déjà suffit.
		if not best.is_empty() and best["missing"] == 0 and sz.x * sz.y > best["area"]:
			break
		var ys := range(lo.y, hi.y - sz.y + 2)
		var xs := range(lo.x, hi.x - sz.x + 2)
		if around.x >= 0:
			ys = range(around.y - sz.y + 1, around.y + 1)
			xs = range(around.x - sz.x + 1, around.x + 1)
		for y in ys:
			for x in xs:
				var r := Rect2i(x, y, sz.x, sz.y)
				var inner: Array[Vector2i] = []
				var ok := true
				for yy in range(r.position.y, r.end.y):
					for xx in range(r.position.x, r.end.x):
						var p := Vector2i(xx, yy)
						if not free.call(p):
							ok = false
							break
						inner.append(p)
					if not ok:
						break
				if not ok:
					continue
				var ring: Array[Vector2i] = []
				var fresh: Array[Vector2i] = []
				var fenced := false
				for yy in range(r.position.y - 1, r.end.y + 1):
					for xx in range(r.position.x - 1, r.end.x + 1):
						var q := Vector2i(xx, yy)
						if r.has_point(q):
							continue
						if not ring_ok.call(q):
							ok = false
							break
						ring.append(q)
						if not is_wall(q):
							fenced = true
							if not is_fence(q) and not _is_fence_site(q):
								fresh.append(q)
					if not ok:
						break
				if not ok or not fenced:
					continue
				var ps := pattern_status(def, inner)
				if ps["missing"] >= 99:
					continue
				var decor_tile := Vector2i(-1, -1)
				if decor != "":
					for p in inner:
						if not ps["tiles"].has(p) and not map.get_t(p.x, p.y) in [GameMap.EAU, GameMap.MONTAGNE, GameMap.MINE_OR] \
							and not map.road[map.idx(p.x, p.y)]:
							decor_tile = p
							break
					if decor_tile.x < 0:
						continue
				var score: float = ps["missing"] * 100.0 + fresh.size() + sz.x * sz.y * 0.5
				if score < best_score:
					best_score = score
					best = {"rect": r, "ring": ring, "new": fresh, "pattern": ps["tiles"], "missing": ps["missing"], "area": sz.x * sz.y}
					if decor != "":
						best["decor"] = decor
						best["decor_tile"] = decor_tile
	return best


## Coût d'un enclos trouvé par enclosure_site : segments de clôture neufs et aménagement requis.
func enclosure_cost(site: Dictionary) -> Dictionary:
	var total := {}
	var parts := [[building_def("enclos"), site["new"].size()]]
	if site.has("decor"):
		parts.append([building_def(site["decor"]), 1])
	for part in parts:
		for k in part[0].get("cout", {}):
			total[k] = float(total.get(k, 0.0)) + float(part[0]["cout"][k]) * part[1]
	return total


## Pose en chantier les clôtures d'un enclos trouvé par enclosure_site, puis son aménagement requis.
## Renvoie le nombre de segments posés.
func place_enclosure(site: Dictionary) -> int:
	var fence_def := building_def("enclos")
	var placed := 0
	for p in site["new"]:
		if place("batiment", fence_def, p) != null:
			placed += 1
	if site.has("decor"):
		place("batiment", building_def(site["decor"]), site["decor_tile"])
	return placed


## Coût de la nourriture d'un animal pour une journée (rations × prix d'une ration).
func food_cost(def: Dictionary) -> int:
	return roundi(rations_per_day(def) * float(data["buildings"]["zoo"]["rations"]["cout"]))


## Rations mangées par jour (= nourriture du palier ; la Canicule et d'autres événements la modifient).
func rations_per_day(def: Dictionary) -> float:
	return float(data["animals"]["paliers"][def["palier"]]["nourriture"]) * float(event_effects().get("nourriture", 1.0))


## Réserve maximale d'un animal : une journée de rations (hors événement).
func food_capacity(def: Dictionary) -> float:
	return float(data["animals"]["paliers"][def["palier"]]["nourriture"])


## Les animaux ne dépendent de la Cuisine qu'une fois le zoo ouvert au public (enceinte, entrée, animal et
## route) : avant, le fournisseur les nourrit. Cela évite de s'endetter avant les premiers revenus.
func can_heal(card: Card) -> bool:
	return card.metier["efficacite"].has("soigner")


func sick_animals() -> Array:
	return animals.filter(func(a): return a.arrived and a.sick)


## La nuit : risque de maladie (faim dans la journée, parc sale), puis contagion dans un même enclos.
## Renvoie les noms des animaux tombés malades.
func _roll_diseases() -> Array[String]:
	var M: Dictionary = data["buildings"]["zoo"]["maladie"]
	var out: Array[String] = []
	var already := animals.filter(func(a): return a.sick)
	for a in animals:
		if not a.arrived or a.sick:
			continue
		var p := float(M["proba_nuit"])
		if a.starved:
			p += float(M["proba_faim"])
		if proprete < float(M["seuil_sale"]):
			p += float(M["proba_sale"])
		var contact := already.any(func(o): return not o.park and not a.park and o.key == a.key)
		if contact:
			p += float(M["contagion"])
		if rng.randf() < p:
			a.sick = true
			a.heal = 0.0
			out.append(a.def["nom"])
	for a in animals:
		a.starved = false
	if not out.is_empty():
		say("Animaux malades : %s. Envoyez un Soigneur dans leur enclos." % ", ".join(out))
	return out


func food_due() -> bool:
	return zoo_status()["open"] and not visitor_path().is_empty()


## Début du jour : avant l'ouverture, le fournisseur remplit les réserves ; ensuite, il faut livrer les rations.
func _feed_animals() -> void:
	var due := food_due()
	for a in animals:
		if a.arrived and not due:
			a.food = food_capacity(a.def)
		a.fed = not a.arrived or a.food > 0.0


## Les animaux mangent leur réserve au fil de la journée. À 0, ils ont faim : ils ne comptent plus dans l'attractivité.
func _animals_eat(dt: float) -> void:
	var due := food_due()
	for a in animals:
		if not a.arrived:
			continue
		if due:
			a.food = maxf(0.0, a.food - rations_per_day(a.def) * dt / day_length)
		else:
			a.food = food_capacity(a.def)
		a.fed = a.food > 0.0
		if not a.fed:
			a.starved = true


## Rations qui manquent pour remplir toutes les réserves (zoo ouvert seulement).
func rations_needed() -> float:
	if not food_due():
		return 0.0
	var n := 0.0
	for a in animals:
		if a.arrived:
			n += maxf(0.0, food_capacity(a.def) - a.food)
	return n


## L'animal à nourrir en priorité : la réserve la plus basse, en part de sa journée.
func _hungriest() -> Animal:
	var best: Animal = null
	var best_r := 0.95
	for a in animals:
		if a.arrived:
			var r := a.food / food_capacity(a.def)
			if r < best_r:
				best_r = r
				best = a
	return best


## Nourrisseur (clic droit sur la Cuisine) : prépare des rations (payées), les livre aux animaux qui en ont le
## plus besoin, puis revient, en boucle. Il attend à la cuisine quand toutes les réserves sont pleines.
func _update_feed(w: Worker, dt: float) -> void:
	var task := w.task
	var kitchen: Site = task["site"]
	if not sites.has(kitchen):
		w.task = {}
		return
	var R: Dictionary = data["buildings"]["zoo"]["rations"]
	if task["phase"] == "deliver":
		var a: Animal = task["animal"]
		if not animals.has(a):
			_feed_next(w)
			return
		if _refuses_near_predator(w):
			return
		var give := minf(float(task["rations"]), maxf(0.0, food_capacity(a.def) - a.food))
		a.food += give
		a.fed = a.food > 0.0
		task["rations"] = float(task["rations"]) - give
		w.card.last_work_tile = w.tile()
		_feed_next(w)
		return
	# À la cuisine : préparer jusqu'à remplir ses bras ou couvrir le besoin, puis partir livrer.
	if not kitchen.rect.has_point(w.tile()):
		_set_path(w, kitchen.rect.position)
		return
	var want := minf(float(carry_capacity(w.card)), ceilf(rations_needed() - 0.0001))
	if task["rations"] >= want or (task["rations"] > 0.01 and money < float(R["cout"])):
		if task["rations"] > 0.01:
			_feed_next(w)
		return
	if money < float(R["cout"]):
		return
	task["prep"] += efficiency_at(w, "nourrir") * dt
	_work_traits(w, dt)
	if task["prep"] >= float(R["preparation_s"]):
		task["prep"] -= float(R["preparation_s"])
		money -= float(R["cout"])
		day_stats["nourriture"] += float(R["cout"])
		task["rations"] += 1


## Agent d'entretien (clic droit sur le Local d'entretien) : circule dans l'enceinte et nettoie le parc.
func _update_clean(w: Worker, dt: float) -> void:
	var task := w.task
	if not sites.has(task["site"]):
		w.task = {}
		return
	var interior: Dictionary = zoo_status()["interior"]
	if interior.is_empty():
		return
	task["t"] += dt
	if not interior.has(w.tile()) or task["t"] >= 15.0:
		# Change d'endroit toutes les 15 s (quelques essais au hasard parmi les cases de l'enceinte)
		task["t"] = 0.0
		var keys := interior.keys()
		for i in 5:
			var t: Vector2i = keys[rng.randi_range(0, keys.size() - 1)]
			var p = map.find_path(w.tile(), t) if map.passable(t.x, t.y) else null
			if p != null:
				w.path.assign(p)
				return
		if not interior.has(w.tile()):
			return
	w.card.last_work_tile = w.tile()
	_work_traits(w, dt)


## Nettoyage : tant que l'agent est dans l'enceinte (à l'arrêt ou en marchant), la propreté remonte.
func _sweep(w: Worker, dt: float) -> void:
	if not zoo_status()["interior"].has(w.tile()):
		return
	var P: Dictionary = data["buildings"]["zoo"]["proprete"]
	proprete = minf(100.0, proprete + float(P["nettoyage_par_minute"]) * efficiency_at(w, "nettoyer") * dt / 60.0)


## Demande de visiteurs selon la propreté : ×0,85 sous 60, ×0,6 sous 30 (voir zoo.proprete.seuils).
func cleanliness_mult() -> float:
	var m := 1.0
	for s in data["buildings"]["zoo"]["proprete"]["seuils"]:
		if proprete < float(s[0]):
			m = float(s[1])
	return m


## L'ouvrier tient en ce moment un poste de ce type situé dans l'enceinte (snack, kiosque…).
func _at_post(w: Worker, kind: String) -> bool:
	return w.task.get("kind") == kind and w.path.is_empty() and w.tile() == w.task["tile"] \
		and zoo_status()["interior"].has(w.task["obj"].rect.position)


## Snack tenu : multiplicateur de durée de visite des visiteurs qui entrent.
func snack_mult() -> float:
	for w in workers:
		if _at_post(w, "snack"):
			return float(building_def("snack")["effet"]["duree_visite_mult"])
	return 1.0


## Kiosque d'animation tenu : +3 d'attractivité × l'efficacité « animer » du meilleur ouvrier présent (Animateur : +6).
func kiosque_bonus() -> int:
	var best := 0
	var base := float(building_def("kiosque")["effet"]["attractivite"])
	for w in workers:
		if _at_post(w, "kiosque"):
			best = maxi(best, roundi(base * efficiency(w.card, "animer")))
	return best


## Va livrer l'animal le plus affamé avec les rations portées, ou retourne à la cuisine.
func _feed_next(w: Worker) -> void:
	var task := w.task
	var a := _hungriest() if task["rations"] > 0.01 else null
	if a == null:
		task["phase"] = "to_kitchen"
		_set_path(w, task["site"].rect.position)
		return
	var tiles: Array = a.tiles.filter(func(t): return map.passable(t.x, t.y))
	if tiles.is_empty():
		task["phase"] = "to_kitchen"
		_set_path(w, task["site"].rect.position)
		return
	tiles.sort_custom(func(p, q): return w.pos.distance_squared_to(Vector2(p)) < w.pos.distance_squared_to(Vector2(q)))
	task["phase"] = "deliver"
	task["animal"] = a
	_set_path(w, tiles[0])


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
		if not a.arrived or not a.fed or a.sick:
			continue
		species[a.def["id"]] = a.def
		if a.def.get("special", "") == "predateur":
			extra += int(Z["bonus_predateur"])
		if cared_today.has(a):
			extra += int(Z["bonus_soigneur"])
	var total := extra + (kiosque_bonus() + int(action_fx.get("attractivite", 0)) if not species.is_empty() else 0)
	var biomes := {}
	# Bonus de nuit favorisant un type d'animal ou un continent (Festival des oiseaux, Semaine de l'Afrique…)
	var by_type: Dictionary = bonus_effects().get("attractivite_type", {})
	var by_cont: Dictionary = bonus_effects().get("attractivite_continent", {})
	for d in species.values():
		total += roundi(float(d["reputation"]) * float(by_type.get(d.get("type", ""), 1.0)) * float(by_cont.get(d.get("continent", ""), 1.0)))
		biomes[d["biome"]] = biomes.get(d["biome"], 0) + 1
	var A: Dictionary = data["animals"]
	total += int(A["bonus_diversite_biomes"].get(str(biomes.size()), 0))
	# Voisinage : +2 par animal voisin du même continent (enclos différents, de part et d'autre d'une clôture)
	var counted: Array = (animals if only == null else only).filter(func(a): return a.arrived and a.fed and not a.sick)
	for a in counted:
		total += int(A.get("voisinage_continent", {}).get("points", 0)) * continent_neighbours(a, counted).size()
	for b in biomes:
		if biomes[b] >= int(A["bonus_collection"]["especes_meme_biome"]):
			total += int(A["bonus_collection"]["points"])
	return total


## Animaux voisins de a venant du même continent : dans un autre enclos, à `distance` cases au plus (Tchebychev).
## among : animaux pris en compte (par défaut, tous ceux arrivés).
func continent_neighbours(a: Animal, among = null) -> Array:
	if a.park:
		return []
	var near := _near_tiles(a)
	var out := []
	for b in (animals.filter(func(o): return o.arrived) if among == null else among):
		if b == a or b.park or b.key == a.key or b.def.get("continent", "") != a.def.get("continent", ""):
			continue
		if b.tiles.any(func(t): return near.has(t)):
			out.append(b)
	return out


var _near_version := -1
var _near := {}


func _near_tiles(a: Animal) -> Dictionary:
	if _near_version != version:
		_near_version = version
		_near = {}
	if not _near.has(a):
		var dist := int(data["animals"].get("voisinage_continent", {}).get("distance", 2))
		var out := {}
		for t in a.tiles:
			for dy in range(-dist, dist + 1):
				for dx in range(-dist, dist + 1):
					out[t + Vector2i(dx, dy)] = true
		_near[a] = out
	return _near[a]


## Publicité : les campagnes terminées attirent plus de visiteurs, avec un rendement décroissant.
func publicity_mult() -> float:
	var P: Dictionary = data["buildings"]["publicite"]
	return 1.0 + float(P["max"]) * publicite / (publicite + float(P["demi_points"]))


func campaign_defs() -> Array:
	return data["buildings"]["publicite"]["campagnes"]


## Avancement d'une campagne par seconde pour un ouvrier hors carte : 1 + son efficacité de lobbying.
func campaign_rate(card: Card) -> float:
	return 1.0 + efficiency(card, "lobbying")


func outside_workers() -> Array:
	return workers.filter(func(w): return w.offmap)


func campaign_error(def: Dictionary) -> String:
	if phase != "day":
		return "Uniquement en journée"
	if not campaign.is_empty():
		return "Campagne en cours : %s" % campaign["def"]["nom"]
	if outside_workers().is_empty():
		return "Envoyez d'abord un ouvrier à l'extérieur (case Accès)"
	if money < campaign_cost(def):
		return "Pas assez d'argent (%d)" % campaign_cost(def)
	return ""


## Prix d'une campagne : réduit si un ouvrier spécialisé en influence (Lobbyiste) est à l'extérieur.
func campaign_cost(def: Dictionary) -> int:
	var c := float(def["cout"])
	if outside_workers().any(func(w): return w.card.metier["efficacite"].has("lobbying")):
		c *= 1.0 - float(data["buildings"]["publicite"]["remise_lobbyiste"])
	return roundi(c)


## Lance une campagne publicitaire (payée tout de suite) : les ouvriers dehors la réalisent sans perdre d'influence.
func launch_campaign(def: Dictionary) -> bool:
	if campaign_error(def) != "":
		return false
	money -= campaign_cost(def)
	campaign = {"def": def, "progress": 0.0}
	say("Campagne lancée : %s. Vos ouvriers à l'extérieur s'en occupent." % def["nom"])
	version += 1
	return true


## Secondes restantes d'une campagne au rythme des ouvriers actuellement dehors (INF si personne).
func campaign_eta() -> float:
	if campaign.is_empty():
		return 0.0
	var rate := 0.0
	for w in outside_workers():
		rate += campaign_rate(w.card) * unpaid_mult(w)
	return (float(campaign["def"]["travail"]) - float(campaign["progress"])) / rate if rate > 0.0 else INF


## Marchands à leur poste : au camp (obj null) ou au bâtiment Marché (obj = le chantier terminé).
func _traders() -> Array:
	return workers.filter(func(w): return w.task.get("kind") == "trade" and w.path.is_empty() and w.tile() == w.task["tile"])


func marchand_present() -> bool:
	return not _traders().is_empty()


func market_built() -> bool:
	return sites.any(func(s): return s.done and s.def_id() == "comptoir")


## Taux de vente du stock : réduit sans personne, 70 % avec le bâtiment Marché, plein tarif avec un Marchand au camp,
## 125 % avec un Marchand au Marché (Négociateur : +25 %).
func sell_rate() -> float:
	var C: Dictionary = data["buildings"]["comptoir"]
	var rate := float(data["buildings"]["zoo"]["vente_sans_marchand"])
	if market_built():
		rate = maxf(rate, float(C["vente_batiment"]))
	for w in _traders():
		var r := float(C["vente_marchand"]) if w.task["obj"] != null else 1.0
		if has_capacity(w.card, "negociateur"):
			r += float(C["negociateur_vente"])
		rate = maxf(rate, r)
	return rate


## Remise à l'achat : un Marchand au bâtiment Marché achète 30 % moins cher (Négociateur : 10 % de plus).
func buy_mult() -> float:
	var C: Dictionary = data["buildings"]["comptoir"]
	var m := 1.0
	for w in _traders():
		if w.task["obj"] != null:
			m = minf(m, float(C["achat_marchand"]) - (float(C["negociateur_achat"]) if has_capacity(w.card, "negociateur") else 0.0))
	return m


## Vend le bois et la pierre du stock (l'or est gardé pour les contrats).
## Plein tarif si un Marchand tient le comptoir du camp, sinon taux réduit.
func sell_price(res: String) -> float:
	return float(data["buildings"]["conversion"][res]) * sell_rate() * float(event_effects().get("prix", {}).get(res, 1.0))


## Prix d'achat d'une unité (double du prix de revente de base), moins la remise d'un Marchand au bâtiment Marché.
func buy_price(res: String) -> float:
	return float(data["buildings"]["conversion"][res]) * float(data["buildings"]["marche"]["prix_achat_materiaux"]) * buy_mult()


func buy_material(res: String, qty: int) -> bool:
	var cost := ceilf(buy_price(res) * qty)
	if phase != "day" or qty <= 0 or not res in ["bois", "pierre"] or money < cost:
		return false
	money -= cost
	stock[res] += qty
	say("Achat : %d %s pour %d." % [qty, res, int(cost)])
	version += 1
	return true


## Vend une quantité choisie d'une ressource (panneau Marché).
func sell_amount(res: String, qty: int) -> bool:
	var units := mini(qty, floori(stock[res] + 0.0001))
	if phase != "day" or units <= 0:
		return false
	var gain := floorf(units * sell_price(res))
	stock[res] -= units
	money += gain
	say("Vente : %d %s pour %d%s." % [units, res, int(gain), "" if sell_rate() >= 1.0 else " (taux réduit : postez un Marchand)"])
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
		* float(event_effects().get("visiteurs", 1.0)) * float(bonus_effects().get("visiteurs", 1.0)) * cleanliness_mult() \
		* float(action_fx.get("visiteurs", 1.0))
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
	return maxf(best, float(action_fx.get("boutiques", 0.0)))  # Vendeur joué (Braderie)


## Visiteurs simultanés maximum : cases intérieures de l'enceinte / cases_par_visiteur.
func visitor_capacity() -> int:
	return int(zoo_status()["interior"].size() / float(data["buildings"]["zoo"]["cases_par_visiteur"]))


## Intensité des arrivées à l'instant t (1,0 = moyenne de la journée), selon courbe_arrivees, et nulle dans
## les dernières secondes. Normalisée : le total des arrivées de la journée reste égal à la demande.
func arrival_factor(t: float) -> float:
	var stop := 1.0 - float(data["buildings"]["zoo"]["arret_arrivees_s"]) / day_length
	if t / day_length >= stop:
		return 0.0
	if _arrival_norm_len != day_length:
		var sum := 0.0
		for i in 200:
			var x := (i + 0.5) / 200.0
			if x < stop:
				sum += _arrival_curve(x)
		_arrival_norm = sum / 200.0
		_arrival_norm_len = day_length
	return _arrival_curve(t / day_length) / _arrival_norm


func _arrival_curve(x: float) -> float:
	var pts: Array = data["buildings"]["zoo"]["courbe_arrivees"]
	for i in range(1, pts.size()):
		if x <= float(pts[i][0]):
			var a: Array = pts[i - 1]
			var b: Array = pts[i]
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001))
	return float(pts[-1][1])


## Taille moyenne d'un groupe de visiteurs.
func _group_mean() -> float:
	var dist: Dictionary = data["buildings"]["zoo"]["groupes"]
	var m := 0.0
	for k in dist:
		m += int(k) * float(dist[k])
	return m


func _group_size() -> int:
	var dist: Dictionary = data["buildings"]["zoo"]["groupes"]
	var r := rng.randf()
	for k in dist:
		r -= float(dist[k])
		if r < 0.0:
			return int(k)
	return int(dist.keys()[-1])


## Nombre d'arrivées d'un processus de Poisson de moyenne lam pendant un pas (méthode de Knuth, lam petit).
func _poisson(lam: float) -> int:
	if lam <= 0.0:
		return 0
	var limit := exp(-lam)
	var k := 0
	var p := rng.randf()
	while p > limit:
		k += 1
		p *= rng.randf()
	return k


func _reset_visit() -> void:
	road_visitors.clear()
	visitor_queue = 0
	in_zoo.clear()
	_admit_acc = 0.0
	visit = {"admitted": 0, "lost": 0, "tickets": 0.0, "souvenirs": 0.0, "presence": 0.0}


func _update_visitors(dt: float) -> void:
	if visit.is_empty():
		_reset_visit()
	var Z: Dictionary = data["buildings"]["zoo"]
	var path := visitor_path()
	# Arrivées à l'Accès : des groupes, à intervalles aléatoires, plus nombreux en milieu de journée
	if not path.is_empty():
		var groups_per_s := demand_rate() * arrival_factor(time) / _group_mean()
		for _g in _poisson(groups_per_s * dt):
			for _k in _group_size():
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
	# Guichet : billet, souvenirs, entrée dans le zoo, dans la limite de la capacité du parc (sinon la file attend)
	var room := visitor_capacity() - in_zoo.size()
	_admit_acc += guichet_rate() * dt
	if visitor_queue == 0 or room <= 0:
		_admit_acc = minf(_admit_acc, 1.0)
	var interior: Array = []
	while _admit_acc >= 1.0 and visitor_queue > 0 and room > 0:
		if interior.is_empty():
			interior = zoo_status()["interior"].keys()
		room -= 1
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
		var ecart := float(Z["duree_visite_ecart_s"])
		var duree := (float(Z["duree_visite_s"]) + rng.randf_range(-ecart, ecart)) * snack_mult()
		in_zoo.append({"t": duree, "pos": Vector2(t) + Vector2(rng.randf(), rng.randf())})
	# Visite puis départ
	for i in range(in_zoo.size() - 1, -1, -1):
		in_zoo[i]["t"] -= dt
		if in_zoo[i]["t"] <= 0.0:
			in_zoo.remove_at(i)
	visit["presence"] += in_zoo.size() * dt
	# Les visiteurs salissent le parc
	proprete = maxf(0.0, proprete - float(Z["proprete"]["salete_par_visiteur_minute"]) * in_zoo.size() * dt / 60.0)


## Fin de journée : réputation gagnée selon la fréquentation moyenne, puis remise à zéro des visiteurs.
func _close_zoo_day() -> Dictionary:
	if visit.is_empty():
		_reset_visit()
	var z := zoo_status()
	var avg: float = visit["presence"] / day_length
	var affinity := affinity_bonus()
	var gain := avg * float(data["buildings"]["zoo"]["reputation_par_visiteur_moyen"]) * (1.0 + affinity)
	rep_points += gain
	var reason: String = z["reason"]
	if z["open"] and visitor_path().is_empty():
		reason = "Aucune route ne relie l'Accès à l'Entrée du zoo"
	var out := {"open": z["open"], "reason": reason, "visitors": visit["admitted"], "lost": visit["lost"],
		"tickets": roundi(visit["tickets"]), "souvenirs": roundi(visit["souvenirs"]), "avg_present": avg, "rep_gain": gain,
		"affinity": affinity}
	_reset_visit()
	return out


## Affinités entre animaux d'un même continent : +5 % de réputation par espèce au-delà de la première,
## pour chaque continent (animaux arrivés et nourris dans l'enceinte).
func affinity_bonus() -> float:
	var per_cont := {}
	for a in zoo_status().get("animals", []):
		if a.arrived and a.fed:
			var c: String = a.def.get("continent", "")
			per_cont[c] = per_cont.get(c, 0) + 1
	var bonus := 0.0
	for c in per_cont:
		bonus += maxi(0, per_cont[c] - 1) * float(data["animals"]["affinite_continent"]["par_espece"])
	# Animaux d'un même type partageant un enclos (ou le parc libre) : +5 % par animal en plus.
	var groups := {}
	for a in zoo_status().get("animals", []):
		if a.arrived and a.fed and a.key != Vector2i(-9, -9):
			var k := "%s|%s" % [str(a.key), a.def.get("type", "")]
			groups[k] = groups.get(k, 0) + 1
	for k in groups:
		bonus += maxi(0, groups[k] - 1) * float(data["animals"]["affinite_type"]["par_animal"])
	return bonus


## Nom affiché d'un continent ou d'un type d'animal.
func continent_name(c: String) -> String:
	return str(data["animals"]["continents"].get(c, c))


func type_name(t: String) -> String:
	return str(data["animals"]["types"].get(t, t))


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
		"road": road_visitors.size(), "queue": visitor_queue, "inside": in_zoo.size(), "capacity": visitor_capacity(),
		"admitted": visit["admitted"],
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
	map.set_t(o.x + 4, o.y + 3, GameMap.SABLE)  # motif du Zèbre : PPP / P.S
	_terrain_updated(Vector2i(o.x + 4, o.y + 3))
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


## Animal sous la case : d'abord celui dont le motif couvre la case, sinon le premier de l'enclos clôturé.
func animal_at(t: Vector2i) -> Animal:
	var fallback: Animal = null
	for a in animals:
		if a.pattern_tiles.has(t):
			return a
		if fallback == null and not a.park and a.tiles.has(t):
			fallback = a
	return fallback


## Nombre d'autres animaux du même type (aérien, terrestre, aquatique) dans le même enclos.
func shared_type_count(a: Animal) -> int:
	return animals.filter(func(o): return o != a and o.key == a.key and o.key != Vector2i(-9, -9) \
		and o.def.get("type", "") == a.def.get("type", "")).size()


## Multiplicateur d'attractivité d'un animal dû au bonus de nuit (type ou continent mis à l'honneur).
func animal_attract_mult(a: Animal) -> float:
	return float(bonus_effects().get("attractivite_type", {}).get(a.def.get("type", ""), 1.0)) \
		* float(bonus_effects().get("attractivite_continent", {}).get(a.def.get("continent", ""), 1.0))
