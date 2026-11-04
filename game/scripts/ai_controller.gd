class_name AIController
extends RefCounted
## IA qui joue une partie complète avec exactement les mêmes actions qu'un joueur humain
## (déployer, donner des ordres, placer des chantiers, installer des animaux, acheter au marché…).
## Les réglages de « stratégie » servent aux simulations d'équilibrage (tests/balance_sim.gd).

const ARGENT_ABONDANT := 100.0  # au-dessus du plancher de dépenses, l'IA améliore son camp quelle que soit sa stratégie
const SURPLUS_STOCK := 30.0  # stock gardé en plus des besoins avant de vendre pour payer les chantiers
const SURPLUS_ARGENT := 30.0  # argent visé au-dessus du plancher de dépenses
const DEFAULT_STRATEGY := {
	"nom": "Équilibrée",
	"lobbyistes_max": 0,  # ouvriers non-Lobbyistes envoyés en lobbying chaque jour
	"preference_palier": 1.0,  # > 1 : favorise les gros contrats (T2, T3) ; < 1 : les petits
	"reserve": 8,  # argent gardé de côté lors des achats de nuit
	"maisons_max": 6,
	"embauche": true,
	"boutique": true,
	"routes": true,
	"mine": true,
	"contrats_en_attente_max": 2,
	"mine_prioritaire": false,  # construit une mine dès le jour 2 et vit de la vente d'or
	"camp": 0,  # niveau d'amélioration du camp visé (0, 1 ou 2) : +1 carte en main par niveau
	"taille_zoo": "moyen",  # petit, moyen, grand, ou evolutif (petit au départ, agrandi ensuite)
	"marche": false,  # construit le bâtiment Marché (vente à 70 %, 125 % avec un Marchand)
	"rush_or": false,  # mine et Marché d'abord, entrepôt près de la mine, la plupart des ouvriers à l'or
	"specialisation": false,  # chaque ouvrier va là où il est le plus efficace
	"formation": false,  # Centre de formation tôt, ouvriers peu utiles en formation les premiers jours
	"cartes": false,  # une carte d'action chaque nuit quand l'argent le permet
	"affinite": false,  # contrats d'un seul continent (affinités), terrain aménagé pour eux
	"palier_min": 1,  # 2 : plus de contrats T1 une fois les T2 disponibles (sauf premier animal)
	"fast_expand": false,  # améliore le camp d'abord (+1 carte en main), le zoo ensuite
	"route_mine": false,  # relie la mine au réseau de routes (les mineurs y vont deux fois plus vite)
	"explore": 0.0,  # part de choix au hasard pour les améliorations et les cartes d'action (étude)
	"spectacle": false,  # Kiosque et boutique tôt, Animateur et Vendeur recherchés : la réputation par les spectacles
}

const ZOO_SIZES := {"petit": Vector2i(12, 10), "moyen": Vector2i(16, 13), "grand": Vector2i(22, 16)}

const DIRS4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const THINK_EVERY := 2.0

var mt: Match
var g: GameState
var strat := {}
var think_clock := 0.0
var zoo_rect := Rect2i()  # enceinte, murs compris
var target_rect := Rect2i()  # parc évolutif : enceinte finale visée
var expanded := false
var entrance := Vector2i(-1, -1)  # case gauche de l'entrée (2x1)
var shop_rect := Rect2i()
var plans: Array = []  # enclos prévus : {"def", "interior": Rect2i, "ring": Array, "conv": Array}
var reserved := {}  # cases réservées par le plan du zoo (murs, boutique, intérieurs des enclos)
var fence_tiles := {}  # clôtures d'enclos prévues : elles peuvent être partagées entre enclos voisins
var conv_defs := {}  # "Prairie>Eau" -> définition d'aménagement
var resource_tiles := {}  # "bois" / "pierre" -> cases triées par distance au camp
var lobby_today := 0
var _plan_cache := {}  # id d'espèce -> plan d'enclos, valable tant que l'état du joueur ne change pas
var _plan_cache_key := ""
var _search_cache := {}  # recherches coûteuses (route d'accès, emplacements), même principe que _plan_cache
var _search_cache_key := ""


func _init(the_match: Match, state: GameState, strategy: Dictionary) -> void:
	mt = the_match
	g = state
	strat = DEFAULT_STRATEGY.duplicate()
	strat.merge(strategy, true)
	for a in g.amenagement_defs():
		var froms: Array = a["de"] if a["de"] is Array else [a["de"]]
		for f in froms:
			conv_defs["%s>%s" % [f, a["vers"]]] = a


# --- Évaluation des cartes (draft et marché) ---------------------------------

## Bonus ajouté à la valeur de base d'une carte selon les besoins de cette IA.
func card_bonus(c: GameState.Card) -> float:
	var v := _card_bonus(c) + float(strat.get("poids_metiers", {}).get(c.metier["id"], 0.0))
	var pt: Dictionary = strat.get("poids_traits", {})
	for t in c.traits:
		v += float(pt.get(t, 0.0))
	return v


func _card_bonus(c: GameState.Card) -> float:
	var job: String = c.metier["id"]
	var mine: Array = []
	mine.append_array(g.all_employees())
	mine.append_array(mt.drafted[g.index])
	var has := func(id): return mine.any(func(o): return o.metier["id"] == id)
	if strat["rush_or"] and job == "mineur":
		return 1.5  # Rush or : des mineurs, beaucoup
	match job:
		"marchand":
			return (2.0 if strat["rush_or"] else 1.0) if not has.call("marchand") else -1.0
		"lobbyiste":
			return 0.5 + 0.5 * float(strat["lobbyistes_max"])
		"vendeur":
			return (1.2 if strat["spectacle"] else 0.5) if strat["boutique"] and not has.call("vendeur") else -1.0
		"contremaitre":
			return 1.0
		"guichetier":
			return 0.8 if not has.call("guichetier") else -0.5
		"paysagiste":
			return 1.2 if not has.call("paysagiste") else 0.0
		"terrassier":
			return 1.0 if not (has.call("terrassier") or has.call("paysagiste")) else 0.0  # sans aménageur, beaucoup d'animaux sont impossibles
		"drh":
			return 0.2 if not has.call("drh") else -1.0
		"architecte":
			return 0.5 if not has.call("architecte") else -1.0  # rembourse 25 % des chantiers où il travaille
		"animalier":
			return 0.6 if not has.call("animalier") else -0.3  # nourrit les animaux deux fois plus vite
		"agent_entretien":
			return 0.3 if not has.call("agent_entretien") else -0.5
		"animateur":
			return (1.5 if strat["spectacle"] else 0.3) if not has.call("animateur") else -1.0  # spectacles au Kiosque
		"formateur":
			return 1.0 if strat["formation"] and not has.call("formateur") else -1.5  # sans Centre de formation, inutile
	return 0.0


func card_value(c: GameState.Card) -> float:
	return mt.draft_value(c, g.index)


# --- Début et fin de journée -------------------------------------------------

func on_day_start() -> void:
	if zoo_rect.size == Vector2i.ZERO and (not g.contracts.is_empty() or g.day >= 3):
		_choose_zoo()
	_index_resources()
	lobby_today = 0
	# Cartes d'action : avant de déployer (Prime, Heures sup, Livraison, Recrutement ; Portes ouvertes si le zoo
	# est ouvert), puis Formation express une fois les ouvriers sur la carte.
	for pass_i in 2:
		for c in g.hand.duplicate():
			if c.is_action() and c.action.get("cible", false):
				_play_targeted(c)
			elif c.is_action() and c.action["id"] != "formation_express" \
				and (c.action["id"] != "portes_ouvertes" or g.zoo_status()["open"]):
				g.play_action(c)
	_play_cadres()
	var hand := g.hand.filter(func(c): return not c.is_action())
	hand.sort_custom(func(a, b): return card_value(a) > card_value(b))
	g.take_loan()  # seulement si aucun salaire n'est payable (voir loan_error)
	for c in hand:
		if g.money >= g.salary(c):
			g.deploy(c)
	# Le meilleur ouvrier restant part gratuitement (rendement réduit) plutôt que de rester en main. Un ouvrier
	# manuel de préférence : sans argent, un cadre gratuit (lobbying, col blanc) ne ferait avancer aucun chantier.
	var free_pick: GameState.Card = null
	for c in hand:
		if not c.deployed and (free_pick == null or _manual_value(c) > _manual_value(free_pick)):
			free_pick = c
	if free_pick:
		g.deploy(free_pick, true)
	for c in g.hand.duplicate():
		if c.is_action() and c.action["id"] == "formation_express":
			g.play_action(c)
	think_clock = 0.0


## Cadres joués pour leur action plutôt que déployés, quand la situation s'y prête.
func _play_cadres() -> void:
	var built := func(id: String) -> bool:
		return g.sites.any(func(s): return s.done and s.def_id() == id)
	var open: bool = g.zoo_status()["open"]
	for c in g.hand.duplicate():
		var A := g.cadre_action(c)
		if A.is_empty() or not g.hand.has(c):
			continue
		match c.metier["id"]:
			"architecte":
				if g.sites.filter(func(s): return not s.done).size() >= 4:
					g.play_cadre(c)
			"contremaitre":
				if g.hand.filter(func(o): return o != c and o.traits.any(func(t): return not g.is_positive(t))).size() >= 3:
					g.play_cadre(c)
			"marchand":
				if g.stock["pierre"] >= 60:
					g.play_cadre(c, null, "pierre")
				elif g.stock["bois"] >= 80:
					g.play_cadre(c, null, "bois")
			"drh":
				var worst: GameState.Card = null
				for o in g.hand:
					if o != c and g.cadre_error(c, o) == "" and card_value(o) < 0.5 and (worst == null or card_value(o) < card_value(worst)):
						worst = o
				if worst and g.all_employees().size() > 5:
					g.play_cadre(c, worst)
			"lobbyiste":
				if g.event_is_negative():
					g.play_cadre(c)
			"vendeur":
				if open and built.call("boutique"):
					g.play_cadre(c)
			"formateur":
				if not built.call("formation") and g.hand.filter(func(o): return not o.is_action()).size() >= 5:
					g.play_cadre(c)
			"animateur":
				if open and not g.animals.is_empty() and not built.call("kiosque"):
					g.play_cadre(c)


## Intérêt d'une carte d'action pour cette IA (0 : inutile pour l'instant).
func _action_value(c: GameState.Card) -> float:
	return _base_action_value(c) + float(strat.get("poids_cartes", {}).get(c.action["id"], 0.0))


func _base_action_value(c: GameState.Card) -> float:
	match c.action["id"]:
		"heures_sup":
			return 3.0
		"portes_ouvertes":
			return 3.0 if g.zoo_status()["open"] else 0.0
		"livraison":
			return 2.0 if _walls_progress() < 1.0 or not plans.is_empty() else 0.5
		"prime":
			return 2.0
		"recrutement", "formation_express":
			return 1.0
		"promotion":
			return 1.5
		"licenciement":
			var cards := g.all_employees()
			return 1.5 if cards.size() > 4 and cards.any(func(c): return card_value(c) < 0.5) else 0.0
	return 0.0


## Rupture de contrat : la carte la plus faible qui n'est pas sur le terrain. Promotion : la meilleure carte.
func _play_targeted(c: GameState.Card) -> void:
	var cards := g.all_employees()
	if cards.is_empty():
		return
	cards.sort_custom(func(a, b): return card_value(a) > card_value(b))
	if c.action["effet"].has("licencier"):
		for k in range(cards.size() - 1, -1, -1):
			if g.action_target_error(c, cards[k]) == "":
				g.play_action(c, cards[k])
				return
		return
	var best: GameState.Card = cards[0]
	g.play_action(c, best, _best_upgrade(best, g.upgrade_options(best)))


## Campagne publicitaire voulue : zoo ouvert et argent abondant (deux fois son prix au-dessus de la réserve).
## La plus chère qui remplit cette condition (la liste va de la moins chère à la plus chère).
func _campaign_wanted() -> Dictionary:
	if not g.campaign.is_empty() or not g.zoo_status()["open"]:
		return {}
	var best := {}
	for d in g.campaign_defs():
		if g.money - float(g.campaign_cost(d)) * 2.0 >= _cash_floor() + float(strat["reserve"]):
			best = d
	return best


func _manual_value(c: GameState.Card) -> float:
	var v := card_value(c)
	if c.metier["categorie"] == "cadre" or c.traits.has("col_blanc"):
		v -= 3.0
	return v


## Trésorerie sous le plancher de dépenses et stock qui dort : vend le surplus, sinon l'IA ne peut plus rien construire
## (chantiers refusés faute d'argent) et reste à 0 de réputation, assise sur des centaines de bois.
func _sell_surplus() -> void:
	var target := _cash_floor() + float(strat["reserve"]) + SURPLUS_ARGENT
	if g.money >= target:
		return
	var needs := _needs()
	var keep := {}
	var missing := target - g.money
	for res in ["bois", "pierre"]:
		var extra := maxf(0.0, floorf(g.stock[res] - float(needs[res]) - SURPLUS_STOCK))
		var price := g.sell_price(res)
		var units := minf(extra, ceilf(missing / price)) if price > 0.0 else 0.0
		missing -= units * price
		keep[res] = g.stock[res] - units
	g.sell_stock(keep, ["bois", "pierre"])


## Vend juste assez de stock (l'or d'abord, puis le bois, puis la pierre) pour atteindre `target` d'argent.
func _sell_for(target: float) -> void:
	var missing := target - g.money
	if missing <= 0.0:
		return
	var keep := {}
	for res in ["or", "bois", "pierre"]:
		var price := g.sell_price(res)
		var units := 0.0
		if price > 0.0 and missing > 0.0:
			units = minf(floorf(g.stock[res]), ceilf(missing / price))
			missing -= units * price
		keep[res] = g.stock[res] - units
	g.sell_stock(keep, ["bois", "pierre", "or"])


## Aucun animal ni contrat réalisable, et une enceinte presque prête : le premier contrat est la priorité.
func _needs_first_animal() -> bool:
	return g.animals.is_empty() and _placeable_contracts() == 0 and (zoo_rect.size == Vector2i.ZERO or _walls_progress() >= 0.6)


## Contrats détenus qui ont un plan d'enclos dans le parc (avant le choix du parc, tous comptent). Un contrat
## irréalisable ne doit pas empêcher d'en acheter un autre.
func _placeable_contracts() -> int:
	if zoo_rect.size == Vector2i.ZERO:
		return g.contracts.size()
	return g.contracts.filter(func(d): return not _plan_enclosure(d).is_empty()).size()


## Argent minimum à garder : salaires d'une main complète + nourriture des animaux.
## Argent à garder pour le lendemain : les salaires de la main suivante (les plus élevés de l'équipe, par prudence)
## et la nourriture des animaux. Sans cela, l'IA ne peut plus déployer personne et sa partie s'arrête.
var _wage_key := ""
var _wage_cache := 0.0


func _cash_floor() -> float:
	var food := 0.0
	if g.food_due():
		for a in g.animals:
			food += g.food_cost(a.def)
	return maxf(8.0, _wage_floor()) + food


func _wage_floor() -> float:
	var key := "salaires|%d" % g.version
	if _wage_key == key:
		return _wage_cache
	var wages: Array = g.all_employees().map(func(c): return float(g.salary(c)))
	wages.sort()
	wages.reverse()
	var total := 0.0
	for k in mini(g.hand_size(), wages.size()):
		total += wages[k]
	_wage_key = key
	_wage_cache = total
	return total


func on_day_end() -> void:
	var needs := _needs()
	var target := _cash_floor() + float(strat["reserve"])
	if _needs_first_animal():
		target = _cash_floor() + 14.0  # de quoi acheter le premier contrat cette nuit
	if g.money < target:
		_sell_for(target)  # trésorerie d'abord, sans tout brader
	else:
		if g.stock["bois"] + g.stock["pierre"] > 120:
			g.sell_stock({"bois": needs["bois"], "pierre": needs["pierre"]})
		if g.stock["or"] > needs["or"] + 2.0:
			g.sell_stock({"or": needs["or"]}, ["or"])


func update(dt: float) -> void:
	think_clock -= dt
	if think_clock > 0.0:
		return
	think_clock = THINK_EVERY
	_buy_materials()
	_place_wants()
	_try_install()
	_staff_posts()
	_heal_sick()
	_reassign_idle_extractors()
	for w in g.workers:
		if not w.offmap and w.task.is_empty() and w.path.is_empty():
			_assign(w)
	var camp := _campaign_wanted()
	if not camp.is_empty() and not g.outside_workers().is_empty():
		g.launch_campaign(camp)
	# Le Marchand rejoint le comptoir en fin de journée pour la vente du soir.
	if g.time > g.day_length - 40.0:
		for w in g.workers:
			if w.card.metier["id"] == "marchand" and w.task.get("kind") != "trade":
				var market := g.sites.filter(func(s): return s.done and s.def_id() == "comptoir")
				g.order([w], market[0].rect.position if not market.is_empty() else g.map.camp.get_center())
	if g.money < 6.0 and g.stock["bois"] + g.stock["pierre"] + g.stock["or"] >= 5:
		_sell_for(_cash_floor())
	_sell_surplus()
	var a_marchand := g.all_employees().any(func(c): return c.metier["id"] == "marchand")
	for ld in g.label_defs():
		if g.label_error(ld) == "" and (not a_marchand or g.label_price(ld) <= float(ld["or"])):
			g.buy_label(ld)
	# Rush or : l'or extrait est vendu au fur et à mesure (petite réserve pour les contrats et le prochain label),
	# l'argent paie les matériaux.
	if strat["rush_or"] and g.stock["or"] >= 4.0:
		var keep := minf(float(_needs()["or"]), 6.0)
		if g.all_employees().any(func(c): return c.metier["id"] == "marchand"):
			for ld in g.label_defs():
				if not g.labels_owned.has(ld["id"]):
					keep = maxf(keep, float(ld["or"]))
					break
		if g.stock["or"] - keep >= 3.0:
			g.sell_stock({"or": keep}, ["or"])


# --- Nuit : marché ------------------------------------------------------------

## Étape Bonus : le premier en influence choisit (sans effet pour les autres).
func on_night_bonus() -> void:
	_pick_bonus()


## Étape Équipe : montées de niveau, amélioration ou licenciement payant, licenciement par le DRH.
func on_night_team() -> void:
	_choose_level_upgrades()
	_night_action()
	# Licenciement de la carte la plus faible si le DRH a travaillé.
	if g.drh_available > 0 and g.employees() >= g.housing():
		var worst: GameState.Card = null
		for c in g.all_employees():
			if worst == null or card_value(c) < card_value(worst):
				worst = c
		if worst and card_value(worst) < 0.0:
			g.fire(worst)
			mt.log.append("%s licencie %s (%s)." % [mt.names[g.index], worst.nom, g.job_name(worst)])


## Étapes de marché de la nuit, à son tour : contrats, puis ouvriers, puis cartes d'action.
func on_night_stage(stage: String) -> void:
	match stage:
		"contrats":
			_night_contracts()
		"ouvriers":
			_night_hire()
		"cartes":
			_night_buy_action()


func _night_contracts() -> void:
	if strat["fast_expand"] and not _camp_upgraded():
		return
	# Contrats (jusqu'à 2 par nuit, le 2e plus cher)
	for attempt in 2:
		# Le premier contrat oriente le choix de l'emplacement du zoo ; les suivants attendent que l'enceinte avance.
		var first := zoo_rect.size == Vector2i.ZERO and g.contracts.is_empty()
		var zoo_ok := zoo_rect.size != Vector2i.ZERO and (_walls_progress() >= 0.6 or g.contracts.is_empty())
		if _placeable_contracts() < int(strat["contrats_en_attente_max"]) and (first or zoo_ok):
			var best: Dictionary = {}
			var best_score := 0.0
			for def in g.market_contracts:
				if g.contract_error(def) != "":
					continue
				var cost := _money_cost(def)
				var margin := 0.0 if _needs_first_animal() else float(strat["reserve"])
				if g.money - cost < margin + _cash_floor():
					continue
				if zoo_rect.size != Vector2i.ZERO and _plan_enclosure(def).is_empty():
					continue
				if not _strategy_allows(def):
					continue
				# Sans Paysagiste ni Terrassier, aucun aménagement possible : le motif doit déjà exister.
				if not _has_landscaper() and not _natural_fit(def):
					continue
				var tier := float(str(def["palier"]).substr(1).to_int())
				# Argent abondant (fin de partie) : la réputation gagnée compte plus que le prix, d'où les T2/T3.
				var price_weight := 1.0 if cost * 3.0 > g.money - _cash_floor() else 0.3
				var score := _rep_gain(def) * pow(tier, float(strat["preference_palier"]) - 1.0) / (cost * price_weight + 10.0)
				score *= pow(2.0, float(strat.get("poids_animaux", {}).get(def["id"], 0.0)))
				if score > best_score:
					best_score = score
					best = def
			if not best.is_empty() and g.buy_contract(best):
				mt.log.append("%s achète le contrat %s." % [mt.names[g.index], best["nom"]])


func _night_hippo() -> void:
	if g.hippo_error() != "" or g.market_workers.is_empty():
		return
	var best: GameState.Card = null
	for c in g.market_workers:
		if best == null or card_value(c) > card_value(best):
			best = c
	var worst: GameState.Card = null
	for c in g.all_employees():
		if worst == null or card_value(c) < card_value(worst):
			worst = c
	if worst and card_value(best) > card_value(worst) + 1.0:
		g.hippo_swap(worst, best)


func _night_hire() -> void:
	_night_hippo()
	if strat["embauche"] and g.employees() < g.housing():
		var best_card: GameState.Card = null
		var best_v := 1.8
		for c in g.market_workers:
			if g.hire_error(c) != "" or g.money - g.hire_cost(c) < float(strat["reserve"]) + _cash_floor():
				continue
			var v := card_value(c) - g.hire_cost(c) * 0.05
			if v > best_v:
				best_v = v
				best_card = c
		if best_card and g.hire(best_card):
			mt.log.append("%s embauche %s (%s)." % [mt.names[g.index], best_card.nom, g.job_name(best_card)])


## Carte d'action : une par nuit quand l'argent abonde, 4 au plus dans le deck (sinon elles diluent la main).
func _night_buy_action() -> void:
	# Étude : une carte au hasard de temps en temps, pour que toutes soient jouées
	if g.rng.randf() < float(strat["explore"]) and not mt.market_actions.is_empty():
		var rc: GameState.Card = mt.market_actions[g.rng.randi_range(0, mt.market_actions.size() - 1)]
		if g.action_error(rc) == "" and g.money - float(rc.action["cout"]) >= _cash_floor():
			g.buy_action(rc)
		return
	if strat["cartes"]:
		var pick: GameState.Card = null
		for c in mt.market_actions:
			if g.action_error(c) == "" and g.money - float(c.action["cout"]) >= _cash_floor() \
				and (pick == null or _action_value(c) > _action_value(pick)):
				pick = c
		if pick and g.buy_action(pick):
			mt.log.append("%s achète la carte %s." % [mt.names[g.index], pick.action["nom"]])
		return
	if g.action_cards().size() < 4 and zoo_rect.size != Vector2i.ZERO:
		var best_a: GameState.Card = null
		for c in mt.market_actions:
			if g.action_error(c) != "" or g.money - float(c.action["cout"]) < _cash_floor() + float(strat["reserve"]) + 20.0:
				continue
			if _action_value(c) > 0.0 and (best_a == null or _action_value(c) > _action_value(best_a)):
				best_a = c
		if best_a and g.buy_action(best_a):
			mt.log.append("%s achète la carte %s." % [mt.names[g.index], best_a.action["nom"]])


## Filtres de contrats propres à la stratégie : un seul continent (Affinités), pas de T1 en milieu de partie (Haut de gamme).
func _strategy_allows(def: Dictionary) -> bool:
	var first := g.animals.is_empty() and g.contracts.is_empty()
	if strat["affinite"] and not first:
		var count := {}
		for d in g.contracts + g.animals.map(func(a): return a.def):
			count[d.get("continent", "")] = int(count.get(d.get("continent", ""), 0)) + 1
		var main := ""
		for k in count:
			if main == "" or count[k] > count[main]:
				main = k
		if def.get("continent", "") != main:
			return false
	if int(strat["palier_min"]) >= 2 and not first and def["palier"] == "T1" \
		and g.day >= int(g.data["animals"]["paliers"]["T2"]["jour_min"]):
		return false
	return true


## Part des murs de l'enceinte déjà terminés (0 à 1).
func _walls_progress() -> float:
	var ring := _ring(zoo_rect)
	var done := ring.filter(func(t): return g.is_wall(t) or g.is_mountain(t)).size()
	return float(done) / ring.size()


func _pick_bonus() -> void:
	var best: Dictionary = {}
	var best_s := -1.0
	for b in mt.bonus_offer:
		if g.bonus_error(b) != "":
			continue
		var sc := 0.0
		var fx: Dictionary = b["effets"]
		for k in fx:
			if fx[k] is Dictionary:
				sc += _animal_bonus_weight(k, fx[k])
			else:
				sc += _bonus_weight(k) * (float(fx[k]) - 1.0)
		if sc > best_s:
			best_s = sc
			best = b
	if not best.is_empty():
		g.pick_bonus(best)


## Bonus favorisant un type d'animal ou un continent : vaut la part d'attractivité gagnée par ses propres animaux
## (comparable au bonus de visiteurs : +x % d'attractivité ≈ +x % de visiteurs).
func _animal_bonus_weight(k: String, mults: Dictionary) -> float:
	if not g.zoo_status()["open"]:
		return 0.0
	var field := "type" if k == "attractivite_type" else "continent"
	var gained := 0.0
	for a in g.animals:
		if a.arrived:
			gained += float(a.def["reputation"]) * (float(mults.get(a.def.get(field, ""), 1.0)) - 1.0)
	return 6.0 * gained / maxf(1.0, float(g.attractiveness()))


func _bonus_weight(k: String) -> float:
	match k:
		"extraire_bois", "extraire_pierre":
			return 3.0
		"construire":
			return 4.0 if _walls_progress() < 1.0 or not plans.is_empty() else 2.0
		"amenager":
			return 2.5 if plans.any(func(p): return not p["conv"].is_empty()) else 0.3
		"extraire_or":
			return 5.0 if g.mine_built else 0.2
		"vitesse":
			return 3.0
		"lobbying":
			return 1.0 + float(strat["lobbyistes_max"])
		"visiteurs":
			return 6.0 if g.zoo_status()["open"] else 0.0
	return 0.0


## Montées de niveau : guérir un défaut, sinon renforcer la spécialité, sinon une amélioration de métier, sinon la première.
func _choose_level_upgrades() -> void:
	while not g.level_choices.is_empty():
		var lc: Dictionary = g.level_choices[0]
		g.choose_level_upgrade(lc["card"], _best_upgrade(lc["card"], lc["options"]))


func _best_upgrade(card: GameState.Card, opts: Array) -> Dictionary:
	if g.rng.randf() < float(strat["explore"]):
		return opts[g.rng.randi_range(0, opts.size() - 1)]
	var learned: Dictionary = strat.get("poids_ameliorations", {})
	if not learned.is_empty():
		var mids: Array = g.data["workers"]["ameliorations_metier"].get(card.metier["id"], []).map(func(u): return u["id"])
		var best: Dictionary = opts[0]
		var best_s := -INF
		for o in opts:
			var sc := float(learned.get(o["id"], 0.0)) + (3.0 if o["id"] == "guerison" else (2.0 if o["id"] == "specialite_up" else (1.0 if mids.has(o["id"]) else 0.0)))
			if sc > best_s:
				best_s = sc
				best = o
		return best
	for o in opts:
		if o["id"] == "guerison":
			return o
	for o in opts:
		if o["id"] == "specialite_up" and card.metier["efficacite"].size() > 1:
			return o
	var metier_ids: Array = g.data["workers"]["ameliorations_metier"].get(card.metier["id"], []).map(func(u): return u["id"])
	for o in opts:
		if metier_ids.has(o["id"]):
			return o
	return opts[0]


## Milieu de partie : licencier la pire carte si elle est vraiment mauvaise, sinon améliorer la meilleure.
func _night_action() -> void:
	var rules := g.night_action_rules()
	var cost := int(rules["cout_amelioration"])
	if g.night_action_error(cost) != "" or g.money - cost < _cash_floor() + float(strat["reserve"]):
		return
	var cards := g.all_employees()
	if cards.is_empty():
		return
	cards.sort_custom(func(a, b): return card_value(a) > card_value(b))
	var worst: GameState.Card = cards[-1]
	if card_value(worst) < 0.0 and g.employees() >= g.housing():
		if g.fire_paid(worst):
			mt.log.append("%s licencie %s." % [mt.names[g.index], worst.nom])
		return
	var best: GameState.Card = cards[0]
	var pick := _best_upgrade(best, g.upgrade_options(best))
	if g.apply_upgrade(best, pick):
		mt.log.append("%s améliore %s (%s)." % [mt.names[g.index], best.nom, pick["nom"]])


## Coût d'un contrat en argent : prix, or manquant acheté au marché, et or du stock compté à 4.
func _money_cost(def: Dictionary) -> float:
	var p: Dictionary = g.contract_payment(def)
	return float(p.get("argent", 0)) + 4.0 * float(p.get("or", 0))


## Réputation gagnée par une nouvelle espèce, bonus de diversité compris.
func _rep_gain(def: Dictionary) -> float:
	var biomes := {}
	for a in g.animals:
		biomes[a.def["biome"]] = true
	for d in g.contracts:
		biomes[d["biome"]] = true
	var gain := float(def["reputation"])
	if not biomes.has(def["biome"]):
		var table: Dictionary = g.data["animals"]["bonus_diversite_biomes"]
		gain += float(table.get(str(biomes.size() + 1), 0)) - float(table.get(str(biomes.size()), 0))
	# Affinité : une espèce d'un continent déjà représenté ajoute 5 % à toute la réputation gagnée.
	if g.animals.any(func(a): return a.def.get("continent", "") == def.get("continent", "")) \
		or g.contracts.any(func(d): return d.get("continent", "") == def.get("continent", "")):
		gain += float(g.data["animals"]["affinite_continent"]["par_espece"]) * maxf(10.0, float(g.attractiveness()))
	return gain


# --- Plan du zoo -------------------------------------------------------------

## Choisit l'emplacement de l'enceinte : terrain adapté aux motifs des contrats détenus, murs constructibles,
## entrée qu'une route peut rejoindre, proche du camp. Une part de hasard propre à chaque IA évite
## que toutes choisissent le même endroit. Parc évolutif : on vise un grand parc mais on commence petit.
func _choose_zoo() -> void:
	var m := g.map
	var camp_c := Vector2(m.camp.get_center())
	var mode: String = strat["taille_zoo"]
	var sizes: Array = [ZOO_SIZES["grand"] if mode == "evolutif" else ZOO_SIZES.get(mode, ZOO_SIZES["moyen"])]
	sizes.append_array([ZOO_SIZES["moyen"], ZOO_SIZES["petit"]])
	var fit := _pattern_fit_maps()
	for size in sizes:
		var cands := []
		for y in range(1, m.h - size.y - 1, 2):
			for x in range(1, m.w - size.x - 1, 2):
				var r := Rect2i(Vector2i(x, y), size)
				if r.intersects(m.camp.grow(2)):
					continue
				var sc := _zoo_score(r, camp_c, fit)
				if sc < INF:
					cands.append([sc + g.rng.randf() * 6.0, r])
		cands.sort_custom(func(a, b): return a[0] < b[0])
		for c in cands.slice(0, 12):
			var ent := _find_entrance(c[1], camp_c)
			if ent.x >= 0 and _setup_zoo(c[1], ent, mode == "evolutif"):
				return


## Murs constructibles sur tout le pourtour : ni route, ni or (l'eau se construit, la montagne sert de mur).
func _ring_ok(r: Rect2i) -> bool:
	var m := g.map
	for t in _ring(r):
		var ter := m.get_t(t.x, t.y)
		if m.road[m.idx(t.x, t.y)] or ter == GameMap.MINE_OR or g.site_at(t) != null:
			return false  # une route, la mine ou un bâtiment déjà posé empêcheraient de fermer l'enceinte
	return true


## Renvoie false si l'emplacement ne convient pas (parc évolutif : aucun petit parc aux murs constructibles).
func _setup_zoo(r: Rect2i, ent: Vector2i, evolutive: bool) -> bool:
	var bottom := ent.y == r.end.y - 1
	if evolutive:
		# Petit parc collé au mur de l'entrée, à l'intérieur du grand parc visé. Son mur intérieur traverse
		# le grand parc, où un peu de montagne est tolérée : on le décale jusqu'à des murs constructibles.
		var sz: Vector2i = ZOO_SIZES["petit"]
		var y0 := r.end.y - sz.y if bottom else r.position.y
		var x_center := clampi(ent.x - sz.x / 2, r.position.x, r.end.x - sz.x)
		var small := Rect2i()
		for off in sz.x:
			for sgn in [1, -1]:
				var x0 := clampi(x_center + off * sgn, r.position.x, r.end.x - sz.x)
				var cand := Rect2i(x0, y0, sz.x, sz.y)
				if small.size == Vector2i.ZERO and x0 + 1 <= ent.x and ent.x + 1 <= x0 + sz.x - 2 and _ring_ok(cand):
					small = cand
		if small.size == Vector2i.ZERO:
			return false
		target_rect = r
		zoo_rect = small
		for t in _ring(target_rect):
			reserved[t] = true
	else:
		zoo_rect = r
	entrance = ent
	var inner := zoo_rect.grow(-1)
	var shop_y := inner.end.y - 2 if bottom else inner.position.y
	shop_rect = Rect2i(clampi(entrance.x + 3, inner.position.x, inner.end.x - 2), shop_y, 2, 2)
	for t in _ring(zoo_rect):
		reserved[t] = true
	for t in _rect_tiles(shop_rect):
		reserved[t] = true
	return true


## Zone du parc (actuelle ou visée) où l'on ne construit ni maison, ni entrepôt, ni mine.
func _park_area() -> Rect2i:
	return target_rect if target_rect.size != Vector2i.ZERO else zoo_rect


## Entrée sur le mur le plus proche du camp : les deux cases et la case devant sur la terre ferme,
## et une route possible jusqu'à elle. Renvoie (-1, -1) si aucune.
func _find_entrance(r: Rect2i, camp_c: Vector2) -> Vector2i:
	var walls := [r.end.y - 1, r.position.y] if camp_c.y > r.get_center().y else [r.position.y, r.end.y - 1]
	for y_wall in walls:
		var out_dir := 1 if y_wall == r.end.y - 1 else -1
		var cx := clampi(int(camp_c.x), r.position.x + 2, r.end.x - 4)
		for off in range(0, r.size.x):
			for sgn in [1, -1]:
				var x: int = cx + off * sgn
				if x <= r.position.x or x + 1 >= r.end.x - 1:
					continue
				var front := Vector2i(x, y_wall + out_dir)
				if _land(Vector2i(x, y_wall)) and _land(Vector2i(x + 1, y_wall)) and _land(front) \
					and (not _road_plan_to(front, r).is_empty() or g.map.road[g.map.idx(front.x, front.y)] == 1):
					return Vector2i(x, y_wall)
	return Vector2i(-1, -1)


## Pour chaque contrat détenu : nombre minimal de cases à aménager si le motif est posé à partir de chaque case.
func _pattern_fit_maps() -> Array:
	var m := g.map
	var out := []
	for def in g.contracts:
		var best := PackedInt32Array()
		best.resize(m.w * m.h)
		best.fill(99)
		for v in g.pattern_variants(def):
			for y in m.h:
				for x in m.w:
					var n := 0
					for c in v:
						var px: int = x + c[0]
						var py: int = y + c[1]
						if not m.in_bounds(px, py):
							n = 99
							break
						var steps := _conversion_steps(GameMap.TERRAINS[m.get_t(px, py)], c[2])
						n += steps if steps >= 0 else 5
					var i := y * m.w + x
					best[i] = mini(best[i], n)
		out.append({"def": def, "best": best})
	return out


func _zoo_score(r: Rect2i, camp_c: Vector2, fit: Array) -> float:
	# Un bâtiment déjà posé sur le pourtour (mine, entrepôt, marché) empêcherait de fermer l'enceinte.
	if not g.sites.is_empty() and _ring(r).any(func(t): return g.site_at(t) != null):
		return INF
	var m := g.map
	var water := 0
	for t in _ring(r):
		var ter := m.get_t(t.x, t.y)
		if m.road[m.idx(t.x, t.y)] or ter == GameMap.MINE_OR:
			return INF
		if ter == GameMap.EAU:
			water += 1
		elif ter == GameMap.MONTAGNE:
			water -= 1  # un mur de moins à construire
	var bad := 0
	var inner := r.grow(-1)
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			var ter := m.get_t(x, y)
			if ter == GameMap.MONTAGNE or ter == GameMap.MINE_OR or m.road[m.idx(x, y)]:
				bad += 1
	if bad > inner.get_area() / 10:
		return INF
	# Bonus si le terrain se prête déjà aux motifs des contrats détenus.
	var bonus := 0.0
	var zone := r.grow(-2)
	for f in fit:
		var b := 99
		for y in range(zone.position.y, zone.end.y - 2):
			for x in range(zone.position.x, zone.end.x - 2):
				b = mini(b, f["best"][y * m.w + x])
		bonus += maxf(0.0, float(f["def"]["motif"].size() - b)) * 4.0
	return camp_c.distance_to(Vector2(r.get_center())) + water * 3.0 + bad * 2.0 - bonus


func _land(t: Vector2i) -> bool:
	var m := g.map
	if not m.in_bounds(t.x, t.y) or m.road[m.idx(t.x, t.y)] or m.in_camp(t.x, t.y):
		return false
	var ter := m.get_t(t.x, t.y)
	return ter != GameMap.EAU and ter != GameMap.MONTAGNE and ter != GameMap.MINE_OR


func _ring(r: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if x == r.position.x or y == r.position.y or x == r.end.x - 1 or y == r.end.y - 1:
				out.append(Vector2i(x, y))
	return out


func _rect_tiles(r: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			out.append(Vector2i(x, y))
	return out


func _index_resources() -> void:
	var m := g.map
	var reach := MapGenerator.reachable(m)
	var c := Vector2(m.camp.get_center())
	for res in ["bois", "pierre"]:
		var ter := GameMap.FORET if res == "bois" else GameMap.ROCHE
		var tiles: Array[Vector2i] = []
		for y in m.h:
			for x in m.w:
				if m.get_t(x, y) == ter and reach[m.idx(x, y)]:
					tiles.append(Vector2i(x, y))
		tiles.sort_custom(func(a, b): return c.distance_squared_to(Vector2(a)) < c.distance_squared_to(Vector2(b)))
		resource_tiles[res] = tiles.slice(0, 40)


# --- Plan des enclos ---------------------------------------------------------

## Cherche dans l'enceinte un enclos pour cette espèce : assez grand, et où le motif peut être obtenu
## avec le moins d'aménagements possible.
func _plan_enclosure(def: Dictionary) -> Dictionary:
	if zoo_rect.size == Vector2i.ZERO:
		return {}
	var key := "%d|%s|%d|%d" % [g.version, str(zoo_rect), reserved.size(), fence_tiles.size()]
	if key != _plan_cache_key:
		_plan_cache_key = key
		_plan_cache.clear()
	if not _plan_cache.has(def["id"]):
		_plan_cache[def["id"]] = _compute_plan(def)
	return _plan_cache[def["id"]]


func _compute_plan(def: Dictionary) -> Dictionary:
	var taille := int(def["taille"])
	var fits := []  # tailles (largeur, hauteur) des orientations du motif
	for v in g.pattern_variants(def):
		var w := 0
		var h := 0
		for c in v:
			w = maxi(w, int(c[0]) + 1)
			h = maxi(h, int(c[1]) + 1)
		fits.append(Vector2i(w, h))
	var dims: Array = []
	for a in range(2, 7):
		for b in range(2, 7):
			if a * b >= taille and fits.any(func(f): return f.x <= a and f.y <= b):
				dims.append(Vector2i(a, b))
	dims.sort_custom(func(p, q): return p.x * p.y < q.x * q.y or (p.x * p.y == q.x * q.y and absi(p.x - p.y) < absi(q.x - q.y)))
	var walls := _usable_walls()
	# Devant l'entrée, on laisse le passage aux visiteurs.
	var gate := Rect2i(entrance - Vector2i(1, 2), Vector2i(4, 5))
	var best := {}
	var best_cost := INF
	for d in dims.slice(0, 3):
		for y in range(zoo_rect.position.y, zoo_rect.end.y - d.y - 1):
			for x in range(zoo_rect.position.x, zoo_rect.end.x - d.x - 1):
				var outer := Rect2i(x, y, d.x + 2, d.y + 2)
				if outer.intersects(gate):
					continue
				var interior := outer.grow(-1)
				var ok := true
				var shared := 0
				for t in _ring(outer):
					if walls.has(t):
						shared += 2  # le mur de l'enceinte sert de côté : aucune clôture à construire
						continue
					if fence_tiles.has(t):
						shared += 1  # clôture commune avec un enclos voisin
						continue
					if reserved.has(t) or not _land(t) or g.site_at(t) != null:
						ok = false
						break
				if not ok:
					continue
				var tiles := _rect_tiles(interior)
				if tiles.any(func(t): return reserved.has(t) or fence_tiles.has(t) or g.map.in_camp(t.x, t.y)):
					continue
				var conv = _pattern_conversions(def, interior)
				if conv == null:
					continue
				# Une montagne dans l'enclos réduit sa surface, et l'animal ne peut pas y être posé.
				if tiles.any(func(t): return g.is_mountain(t) and not conv.any(func(c): return c[0] == t)):
					continue
				# Moins d'aménagements, clôtures partagées et enclos tassés contre les murs : on garde de la place.
				var wall_dist := maxi(0, mini(mini(x - zoo_rect.position.x, y - zoo_rect.position.y), mini(zoo_rect.end.x - outer.end.x, zoo_rect.end.y - outer.end.y)))
				var cost: float = _conv_cost(conv) * 2.0 - shared * 0.6 + wall_dist * 0.4
				if cost < best_cost:
					best_cost = cost
					best = {"def": def, "interior": interior, "ring": _ring(outer), "conv": conv}
	return best


## Cases du mur de l'enceinte qu'un enclos peut prendre comme côté : pas l'entrée, et pas les murs
## du petit parc évolutif qui seront démolis à l'agrandissement.
func _usable_walls() -> Dictionary:
	var out := {}
	var keep := {}
	if target_rect.size != Vector2i.ZERO and not expanded:
		for t in _ring(target_rect):
			keep[t] = true
	for t in _ring(zoo_rect):
		if t == entrance or t == entrance + Vector2i(1, 0):
			continue
		if keep.is_empty() or keep.has(t):
			out[t] = true
	return out


func _has_landscaper() -> bool:
	return g.all_employees().any(func(c): return g.can_landscape(c))


## Étapes pour transformer un terrain en un autre : 0 (déjà bon), 1 (directe), 2 (en passant par la Prairie,
## par ex. Forêt -> Prairie -> Eau), ou -1 (impossible).
func _conversion_steps(cur: String, target: String) -> int:
	if cur == target:
		return 0
	if conv_defs.has("%s>%s" % [cur, target]):
		return 1
	if conv_defs.has(cur + ">Prairie") and conv_defs.has("Prairie>" + target):
		return 2
	return -1


## Prochain aménagement à poser pour aller de `cur` vers `target` (direct, ou d'abord vers la Prairie), ou null.
func _conversion_step(cur: String, target: String) -> Variant:
	match _conversion_steps(cur, target):
		1:
			return conv_defs["%s>%s" % [cur, target]]
		2:
			return conv_defs[cur + ">Prairie"]
	return null


## Nombre total d'aménagements d'un plan (une transformation en deux étapes compte double).
func _conv_cost(conv: Array) -> int:
	var n := 0
	for c in conv:
		n += int(c[2])
	return n


## Aménagements nécessaires pour obtenir le motif dans l'enclos : [case, terrain visé, nombre d'étapes], ou null.
## On ne teste que les positions où l'orientation du motif tient entièrement dans l'enclos.
func _pattern_conversions(def: Dictionary, interior: Rect2i) -> Variant:
	var can := _has_landscaper()
	var m := g.map
	var best = null
	for v in g.pattern_variants(def):
		var w := 0
		var h := 0
		for c in v:
			w = maxi(w, int(c[0]) + 1)
			h = maxi(h, int(c[1]) + 1)
		if w > interior.size.x or h > interior.size.y:
			continue
		for ay in range(interior.position.y, interior.end.y - h + 1):
			for ax in range(interior.position.x, interior.end.x - w + 1):
				var conv := []
				var ok := true
				for c in v:
					var px: int = ax + c[0]
					var py: int = ay + c[1]
					var steps := _conversion_steps(GameMap.TERRAINS[m.get_t(px, py)], c[2])
					if steps == 0:
						continue
					if not can or steps < 0:
						ok = false
						break
					conv.append([Vector2i(px, py), str(c[2]), steps])
				if ok and (best == null or _conv_cost(conv) < _conv_cost(best)):
					best = conv
					if conv.is_empty():
						return best
	return best


func _ensure_plans() -> void:
	plans = plans.filter(func(p): return g.contracts.has(p["def"]))
	for def in g.contracts:
		if plans.any(func(p): return p["def"] == def):
			continue
		var p := _plan_enclosure(def)
		if p.is_empty():
			continue
		plans.append(p)
		for t in p["ring"]:
			fence_tiles[t] = true
		for t in _rect_tiles(p["interior"]):
			reserved[t] = true


func _try_install() -> void:
	for p in plans.duplicate():
		var ring: Array = p["ring"]
		if not ring.all(func(t): return g.is_fence(t) or g.is_wall(t) or g.is_mountain(t)):
			continue
		var interior: Rect2i = p["interior"]
		if _rect_tiles(interior).any(func(t): return g.site_at(t) != null and not g.is_decor(t)):
			continue  # aménagements de terrain en cours
		if not _place_decor(p["def"], interior):
			continue
		var err := g.install_animal(p["def"], interior.position)
		if err == "":
			plans.erase(p)
		elif err.begins_with("Motif absent"):
			var conv = _pattern_conversions(p["def"], interior)
			if conv != null:
				p["conv"] = conv


## Aménagement d'enclos requis (Grand arbre…) : posé sur une case de l'enclos hors du motif. Faux tant qu'il
## ne peut pas être posé (ressources) ; l'animal est ensuite réservé jusqu'à la fin du chantier.
func _place_decor(def: Dictionary, interior: Rect2i) -> bool:
	var decor: String = def.get("decor", "")
	if decor == "":
		return true
	if _has_decor(decor, interior):
		return true
	var t := _decor_tile(def, interior)
	return t.x >= 0 and g.place("batiment", g.building_def(decor), t) != null


func _has_decor(decor: String, interior: Rect2i) -> bool:
	return _rect_tiles(interior).any(func(t): return g.site_at(t) != null and g.site_at(t).def_id() == decor)


## Case pour l'aménagement requis : hors du motif si possible, sinon sur le motif (seul son terrain compte).
## (-1, -1) tant que l'enclos n'est pas fermé.
func _decor_tile(def: Dictionary, interior: Rect2i) -> Vector2i:
	var enc := g.enclosure_at(interior.position)
	if not enc["closed"] or enc.get("park", false):
		return Vector2i(-1, -1)
	var pattern: Array = g.pattern_status(def, g.free_enclosure_tiles(enc))["tiles"]
	var ddef := g.building_def(def["decor"])
	var free := _rect_tiles(interior).filter(func(t): return g.placement_error("batiment", ddef, t, false) == "")
	for t in free:
		if not pattern.has(t):
			return t
	return free[0] if not free.is_empty() else Vector2i(-1, -1)


## Travail restant sur un enclos prévu : aménagements, plus clôtures et murs qui manquent.
func _plan_left(p: Dictionary) -> int:
	return _ring_left(p) + p["conv"].filter(func(c): return GameMap.TERRAINS[g.map.get_t(c[0].x, c[0].y)] != c[1]).size()


func _ring_left(p: Dictionary) -> int:
	return p["ring"].filter(func(t): return not (g.is_fence(t) or g.is_wall(t) or g.is_mountain(t))).size()


# --- Chantiers voulus --------------------------------------------------------

## Liste ordonnée des chantiers que l'IA veut placer : [kind, def, origin].
func _wants() -> Array:
	var out := []
	var day := g.day
	if strat["fast_expand"] and not _camp_upgraded():
		if not g.has_building("camp_n2") and g.placement_error("batiment", g.building_def("camp_n2"), g.map.camp.position, false) == "":
			out.append(["batiment", g.building_def("camp_n2"), g.map.camp.position])
		return out
	# 1. Une maison quand le logement est plein (pour pouvoir embaucher).
	var houses := g.sites.filter(func(s): return s.def_id() == "maison").size()
	if strat["embauche"] and day >= 2 and g.employees() >= g.housing() and houses < int(strat["maisons_max"]) \
		and not g.sites.any(func(s): return s.def_id() == "maison" and not s.done):
		var spot := _spot_near_camp(g.building_def("maison"))
		if spot.x >= 0:
			out.append(["batiment", g.building_def("maison"), spot])
	# 1 bis. Entrepôt rentable : les récolteurs perdent trop de temps en allers-retours jusqu'au dépôt le plus proche.
	var dspot := _depot_wanted()
	if dspot.x >= 0:
		out.append(["batiment", g.building_def("entrepot"), dspot])
	# 1 quater. Améliorations du camp (stratégies « Camp amélioré » et « Grand camp ») : +1 carte en main par niveau.
	for lvl in [2, 3]:
		# Argent qui dort : plus de cartes en main, donc plus de bras.
		var camp_max := 2 if g.money > _cash_floor() + ARGENT_ABONDANT else int(strat["camp"])
		if lvl - 1 > camp_max or day < 2:
			break
		var cid := "camp_n%d" % lvl
		if not g.has_building(cid):
			if g.placement_error("batiment", g.building_def(cid), g.map.camp.position, false) == "":
				out.append(["batiment", g.building_def(cid), g.map.camp.position])
			break
	# 0. Rush or : mine, entrepôt collé à la mine (trajets courts), puis Marché pour vendre l'or ; le parc attend.
	if strat["rush_or"]:
		var rush := _rush_wants()
		out.append_array(rush)
		if not _rush_ready() and day < 6:
			return out
	if zoo_rect.size == Vector2i.ZERO:
		return out
	# 1 ter. Route jusqu'à l'entrée : indispensable, les visiteurs n'arrivent que par la route.
	if day >= 2 and entrance.x >= 0 and _walls_progress() >= 0.3 and g.visitor_path().is_empty():
		var n := 0
		for t in _road_plan():
			if n >= 12:
				break
			if g.site_at(t) == null:
				# Sur l'eau, la route passe par un pont.
				var kind_id := "pont" if g.map.get_t(t.x, t.y) == GameMap.EAU else "route"
				out.append(["batiment", g.building_def(kind_id), t])
				n += 1
	# 1 bis. Stratégie « Mine d'or » : la mine passe avant tout le reste.
	if (strat["mine_prioritaire"] or strat["rush_or"]) and day >= 2 and not g.sites.any(func(s): return s.def_id() == "mine"):
		var mspot := _mine_spot()
		if mspot.x >= 0:
			out.append(["batiment", g.building_def("mine"), mspot])
	# 1 sexies. Route de la mine.
	if strat["route_mine"] and g.mine_built:
		var nr := 0
		for t in _mine_road():
			if nr >= 12:
				break
			if g.site_at(t) == null and not g.map.road[g.map.idx(t.x, t.y)]:
				out.append(["batiment", g.building_def("pont" if g.map.get_t(t.x, t.y) == GameMap.EAU else "route"), t])
				nr += 1
	# 1 ter. Marché : vendre plus cher (stratégie « Marché »).
	if strat["marche"] and day >= 2 and not g.has_building("comptoir"):
		var cspot := _spot_near_camp(g.building_def("comptoir"))
		if cspot.x >= 0:
			out.append(["batiment", g.building_def("comptoir"), cspot])
	# 1 quinquies. Centre de formation (stratégie « Formation »).
	if strat["formation"] and day >= 2 and not g.has_building("formation"):
		var fspot := _spot_near_camp(g.building_def("formation"))
		if fspot.x >= 0:
			out.append(["batiment", g.building_def("formation"), fspot])
	# 2. Enceinte et entrée.
	if entrance.x >= 0 and g.site_at(entrance) == null:
		out.append(["batiment", g.building_def("entree"), entrance])
	for t in _ring(zoo_rect):
		if t == entrance or t == entrance + Vector2i(1, 0) or g.site_at(t) != null or g.is_mountain(t):
			continue
		out.append(["batiment", g.building_def("cloture"), t])
	# 2 bis. Parc évolutif : une fois le petit parc lancé, on construit l'enceinte du grand parc,
	# puis on démolit les anciens murs intérieurs.
	if target_rect.size != Vector2i.ZERO and not expanded and _walls_progress() >= 1.0 and (day >= 6 or g.animals.size() >= 2):
		var big_ring := _ring(target_rect)
		var pending := false
		for t in big_ring:
			if t == entrance or t == entrance + Vector2i(1, 0) or g.is_wall(t) or g.is_mountain(t):
				continue
			pending = true
			if g.site_at(t) != null:
				continue
			out.append(["batiment", g.building_def("cloture"), t])
		if not pending:
			_finish_expansion()
	# 3. Enclos des contrats en attente (aménagements puis clôtures).
	_ensure_plans()
	# Un enclos à la fois, le plus avancé d'abord : deux enclos à moitié faits n'accueillent aucun animal.
	var en_cours := plans.duplicate()
	en_cours.sort_custom(func(a, b): return _plan_left(a) < _plan_left(b))
	for p in en_cours:
		for c in p["conv"]:
			# Étape suivante vers le terrain visé (une transformation en deux étapes passe par la Prairie)
			var step = _conversion_step(GameMap.TERRAINS[g.map.get_t(c[0].x, c[0].y)], c[1])
			if g.site_at(c[0]) == null and step != null:
				out.append(["amenagement", step, c[0]])
		var walls := _usable_walls()
		for t in p["ring"]:
			if g.site_at(t) == null and not walls.has(t):
				out.append(["batiment", g.building_def("enclos"), t])
		var ring_left := _ring_left(p)
		var decor: String = p["def"].get("decor", "")
		if ring_left == 0 and decor != "" and not _has_decor(decor, p["interior"]):
			var dt := _decor_tile(p["def"], p["interior"])
			if dt.x >= 0:
				out.append(["batiment", g.building_def(decor), dt])
		# Des aménagements sans Paysagiste au travail aujourd'hui ne bloquent pas l'enclos suivant.
		if ring_left > 0 or (_plan_left(p) > 0 and g.workers.any(func(w): return g.can_landscape(w.card))):
			break
	# 3 bis. Cuisine dès le premier animal (zoo ouvert : il faut livrer les rations), puis local d'entretien
	# quand le parc commence à se salir.
	for b in [["cuisine", not g.animals.is_empty()], ["entretien", g.proprete < 85.0]]:
		if b[1] and not g.has_building(b[0]):
			var spot := _park_spot(g.building_def(b[0]))
			if spot.x >= 0:
				out.append(["batiment", g.building_def(b[0]), spot])
	# 3 ter. Kiosque d'animation : stratégie Spectacle dès l'ouverture, sinon quand l'argent abonde.
	if not g.has_building("kiosque") and g.zoo_status()["open"] \
		and (strat["spectacle"] or (day >= 5 and g.money > _cash_floor() + 60.0)):
		var kspot := _park_spot(g.building_def("kiosque"))
		if kspot.x >= 0:
			out.append(["batiment", g.building_def("kiosque"), kspot])
	# 4. Boutique, une fois le premier animal installé.
	if strat["boutique"] and not g.animals.is_empty() and g.site_at(shop_rect.position) == null:
		out.append(["batiment", g.building_def("boutique"), shop_rect.position])
	# 5. Mine d'or si l'IA vise les gros contrats.
	if strat["mine"] and day >= 4 and float(strat["preference_palier"]) >= 1.0 and not g.mine_built \
		and not g.sites.any(func(s): return s.def_id() == "mine"):
		var spot := _mine_spot()
		if spot.x >= 0:
			out.append(["batiment", g.building_def("mine"), spot])
	return out


func _camp_upgraded() -> bool:
	return g.sites.any(func(s): return s.done and s.def_id() == "camp_n2")


## Route de la mine jusqu'au réseau (Accès, routes, camp) : la case libre autour de la mine la plus proche du camp.
func _mine_road() -> Array[Vector2i]:
	return _cached("route_mine", _search_mine_road)


func _search_mine_road() -> Array[Vector2i]:
	var mines := g.sites.filter(func(s): return s.done and s.def_id() == "mine")
	if mines.is_empty():
		return []
	var c := Vector2(g.map.camp.get_center())
	var cases: Array = g.work_tiles(mines[0]).filter(func(t): return g.site_at(t) == null)
	cases.sort_custom(func(a, b): return c.distance_squared_to(Vector2(a)) < c.distance_squared_to(Vector2(b)))
	for t in cases.slice(0, 4):
		var p := _road_plan_to(t, _park_area())
		if not p.is_empty():
			return p
	return []


## Rush or : chantiers de l'économie de l'or, dans l'ordre (mine, entrepôt à côté, Marché).
func _rush_wants() -> Array:
	var out := []
	var mine_sites := g.sites.filter(func(s): return s.def_id() == "mine")
	if mine_sites.is_empty():
		var mspot := _mine_spot()
		if mspot.x >= 0:
			out.append(["batiment", g.building_def("mine"), mspot])
		return out
	var mine_site: GameState.Site = mine_sites[0]
	if not g.sites.any(func(s): return s.def_id() == "entrepot" and Vector2(s.rect.get_center()).distance_to(Vector2(mine_site.rect.get_center())) < 7.0):
		var espot := _spot_near(mine_site.rect.get_center(), g.building_def("entrepot"), 2)
		if espot.x >= 0:
			out.append(["batiment", g.building_def("entrepot"), espot])
	if not g.has_building("comptoir"):
		var cspot := _spot_near(mine_site.rect.get_center(), g.building_def("comptoir"), 2)
		if cspot.x < 0:
			cspot = _spot_near_camp(g.building_def("comptoir"))
		if cspot.x >= 0:
			out.append(["batiment", g.building_def("comptoir"), cspot])
	return out


## L'économie de l'or tourne : mine, entrepôt et Marché terminés (ou pas de gisement : on joue normalement).
func _rush_ready() -> bool:
	if _mine_spot().x < 0 and not g.sites.any(func(s): return s.def_id() == "mine"):
		return true
	return g.mine_built  # l'entrepôt et le Marché se construisent ensuite, en même temps que le parc


## Le grand mur est fermé : on démolit les murs de l'ancien petit parc qui sont désormais à l'intérieur.
func _finish_expansion() -> void:
	var big := {}
	for t in _ring(target_rect):
		big[t] = true
	for t in _ring(zoo_rect):
		if not big.has(t):
			var s := g.site_at(t)
			if s and s.def_id() == "cloture":
				g.demolish(s)
			reserved.erase(t)
	zoo_rect = target_rect
	expanded = true
	mt.log.append("%s agrandit son parc." % mt.names[g.index])


func _place_wants() -> void:
	var open := g.sites.filter(func(s): return not s.done).size()
	var max_open := 6 + g.workers.size() * 3
	var floor_cash := _cash_floor() + float(strat["reserve"])
	for wnt in _wants():
		if open >= max_open:
			break
		# Les chantiers payés en argent ne doivent pas vider la trésorerie (salaires de demain), sauf ceux du
		# premier enclos : sans animal il n'y a aucun revenu, et garder la réserve bloquerait la partie.
		var argent := float(wnt[1].get("cout", {}).get("argent", 0))
		var first_enclosure: bool = g.animals.is_empty() and (wnt[0] == "amenagement" or wnt[1].get("id") == "enclos")
		if strat["fast_expand"] and str(wnt[1].get("id", "")) == "camp_n2":
			first_enclosure = true  # Fast expand : le camp passe avant la réserve
		if argent > 0.0 and g.money - argent < (0.0 if first_enclosure else floor_cash):
			continue
		var placed := g.place(wnt[0], wnt[1], wnt[2])
		if placed != null:
			open += 1
			# Bâtiment de service posé dans le parc : les enclos prévus ensuite l'éviteront.
			if placed.def_id() in ["cuisine", "entretien"]:
				for t in _rect_tiles(placed.rect):
					reserved[t] = true


## Ressources manquantes pour les prochains chantiers voulus.
func _needs() -> Dictionary:
	var need := {"bois": 0.0, "pierre": 0.0, "or": 0.0}
	var n := 0
	for wnt in _wants():
		if n >= 25:
			break
		n += 1
		var cost: Dictionary = wnt[1].get("cout", {})
		for k in cost:
			if need.has(k):
				need[k] += float(cost[k])
	# Garder de l'or pour un T3 (2 à 3 or) plutôt que de tout vendre le soir.
	if (float(strat["preference_palier"]) > 1.0 or g.mine_built) and g.day >= 5:
		need["or"] += 3.0
	return need


func _spot_near_camp(def: Dictionary) -> Vector2i:
	return _spot_near(g.map.camp.get_center(), def, 3)


## Mémorise le résultat d'une recherche tant que la carte, les chantiers et le plan du zoo n'ont pas changé :
## _wants() est rappelé à chaque réflexion et pour chaque ouvrier inactif (via _needs).
func _cached(name: String, compute: Callable) -> Variant:
	var key := "%d|%s|%s|%s|%s|%d|%d" % [g.version, g.phase, str(zoo_rect), str(target_rect), str(entrance),
		reserved.size(), fence_tiles.size()]
	if key != _search_cache_key:
		_search_cache_key = key
		_search_cache.clear()
	if not _search_cache.has(name):
		_search_cache[name] = compute.call()
	return _search_cache[name]


func _spot_near(c: Vector2i, def: Dictionary, r0 := 1) -> Vector2i:
	return _cached("spot|%s|%s|%d" % [str(c), def["id"], r0], _search_spot_near.bind(c, def, r0))


func _search_spot_near(c: Vector2i, def: Dictionary, r0: int) -> Vector2i:
	for r in range(r0, 14):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var o := c + Vector2i(dx, dy)
				var rect := g.footprint("batiment", def, o)
				if _rect_tiles(rect.grow(1)).any(func(t): return reserved.has(t) or _park_area().has_point(t)):
					continue
				if g.placement_error("batiment", def, o, false) == "":
					return o
	return Vector2i(-1, -1)


## Ressource à plus de 10 cases du camp et des entrepôts : là où un entrepôt fera gagner du temps.
## Entrepôt rentable ? Chaque charge (5 unités) coûte un aller-retour jusqu'au dépôt le plus proche. Au-delà de
## 4 cases, ce trajet dépasse le temps d'extraction perdu à bâtir l'entrepôt en un ou deux jours : on en pose un au
## milieu des récolteurs éloignés quand le total des distances en trop atteint 14 cases (ex. 2 ouvriers à 11 cases).
func _depot_wanted() -> Vector2i:
	if g.day >= int(g.data["buildings"]["partie"]["jour_max"]) - 2 or g.sites.any(func(s): return s.def_id() == "entrepot" and not s.done) 		or g.sites.filter(func(s): return s.def_id() == "entrepot").size() >= 3:
		return Vector2i(-1, -1)
	var depots := g.depots()
	var excess := 0.0
	var mid := Vector2.ZERO
	var n := 0
	for w in g.workers:
		if w.task.get("type") != "extract":
			continue
		var t: Vector2i = w.task["target"]
		var d := INF
		for r in depots:
			d = minf(d, Vector2(r.get_center()).distance_to(Vector2(t)))
		if d > 4.0:
			excess += d - 4.0
			mid += Vector2(t)
			n += 1
	if excess < 14.0 or n == 0:
		return Vector2i(-1, -1)
	var c := Vector2i((mid / n).round())
	return _spot_near(c, g.building_def("entrepot"), 1)


func _far_resource() -> Vector2i:
	var depots := g.depots()
	for res in ["bois", "pierre"]:
		for t in resource_tiles.get(res, []):
			if depots.all(func(r): return Vector2(r.get_center()).distance_to(Vector2(t)) > 10.0):
				return t
	return Vector2i(-1, -1)


func _mine_spot() -> Vector2i:
	return _cached("mine", _search_mine_spot)


## Le motif de l'animal existe déjà tel quel sur la carte, près du camp (là où ira le zoo) : réalisable sans aménageur.
func _natural_fit(def: Dictionary) -> bool:
	return _cached("motif|" + str(def["id"]), _search_natural_fit.bind(def))


func _search_natural_fit(def: Dictionary) -> bool:
	var m := g.map
	var c := m.camp.get_center()
	for v in g.pattern_variants(def):
		for y in range(maxi(0, c.y - 30), m.h):
			for x in range(maxi(0, c.x - 30), mini(m.w, c.x + 30)):
				var ok := true
				for cell in v:
					var px: int = x + cell[0]
					var py: int = y + cell[1]
					if not m.in_bounds(px, py) or GameMap.TERRAINS[m.get_t(px, py)] != cell[2]:
						ok = false
						break
				if ok:
					return true
	return false


## Place libre dans le parc pour un petit bâtiment de service (cuisine, entretien), au plus près de l'entrée.
## Choisie au moment de construire, hors des cases déjà réservées (murs, boutique, enclos prévus) : la
## réserver d'avance empêchait les enclos de tenir dans un petit parc.
func _park_spot(def: Dictionary) -> Vector2i:
	return _cached("parc|" + str(def["id"]), _search_park_spot.bind(def))


func _search_park_spot(def: Dictionary) -> Vector2i:
	var inner := zoo_rect.grow(-1)
	var cands: Array[Vector2i] = []
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			cands.append(Vector2i(x, y))
	cands.sort_custom(func(a, b): return a.distance_squared_to(entrance) < b.distance_squared_to(entrance))
	for o in cands:
		var tiles := _rect_tiles(g.footprint("batiment", def, o))
		if tiles.any(func(t): return not inner.has_point(t) or reserved.has(t) or fence_tiles.has(t) or g.animal_at(t) != null):
			continue
		if g.placement_error("batiment", def, o, false) == "":
			return o
	return Vector2i(-1, -1)


func _search_mine_spot() -> Vector2i:
	var c := Vector2(g.map.camp.get_center())
	var golds := g.map.golds.duplicate()
	golds.sort_custom(func(a, b): return c.distance_squared_to(Vector2(a)) < c.distance_squared_to(Vector2(b)))
	for gold in golds:
		for o in [gold, gold - Vector2i(1, 0), gold - Vector2i(0, 1), gold - Vector2i(1, 1)]:
			if g.placement_error("batiment", g.building_def("mine"), o, false) == "" \
				and not _rect_tiles(Rect2i(o, Vector2i(2, 2))).any(func(t): return _park_area().has_point(t)):
				return o
	return Vector2i(-1, -1)


# --- Affectation des ouvriers -------------------------------------------------

func _assign(w: GameState.Worker) -> void:
	var job: String = w.card.metier["id"]
	if job == "lobbyiste" or w.card.traits.has("col_blanc"):
		g.order([w], g.map.exit_tile)
		return
	# Équipe réduite (faute d'argent) et zoo fermé : les chantiers avant les soins, sinon le zoo n'ouvre jamais.
	var survival: bool = g.workers.size() <= 2 and not g.zoo_status()["open"]
	if job == "vendeur":
		var shop := g.site_at(shop_rect.position)
		if shop and shop.done and g.zoo_status()["open"]:
			g.order([w], shop.rect.position)
			return
	if job == "soigneur" and not survival:
		var patient = _patient()
		if patient:
			g.order([w], patient.tiles[0])
			return
	# Campagne publicitaire à mener (en cours ou voulue) : un ouvrier part à l'extérieur s'il n'y a personne.
	if not g.workers.any(func(o): return o.offmap or o.task.get("type") == "lobby") and not w.unpaid and g.workers.size() >= 4 \
		and (not g.campaign.is_empty() or not _campaign_wanted().is_empty()):
		g.order([w], g.map.exit_tile)
		return
	if lobby_today < int(strat["lobbyistes_max"]) and not w.unpaid and g.money > _cash_floor() + float(strat["reserve"]):
		lobby_today += 1
		g.order([w], g.map.exit_tile)
		return
	if strat["formation"] and g.day <= 8 and w.card.niveau < 3 and not w.unpaid:
		var school := g.sites.filter(func(s): return s.done and s.def_id() == "formation")
		var trainees := g.workers.filter(func(o): return o.task.get("kind") == "formation").size()
		if not school.is_empty() and trainees < (3 if w.card.metier["id"] == "formateur" else 2):
			g.order([w], school[0].rect.position)
			return
	var site := _best_site_for(w)
	if site:
		g.order([w], site.rect.position)
		return
	_gather(w)


## L'argent en trop achète le bois et la pierre qui manquent aux prochains chantiers.
func _buy_materials() -> void:
	# Rush or : l'or vendu paie les matériaux, on achète plus volontiers (l'extraction de bois et de pierre est délaissée)
	var spare := g.money - _cash_floor() - (5.0 if strat["rush_or"] else float(strat["reserve"]) + 20.0)
	if spare <= 0.0:
		return
	var needs := _needs()
	for res in ["pierre", "bois"]:
		var missing := int(ceil(needs[res] - g.stock[res]))
		if missing <= 0:
			continue
		var qty := mini(missing, int(spare / g.buy_price(res)))
		if qty > 0 and g.buy_material(res, qty):
			spare -= qty * g.buy_price(res)


## Cases de route à poser pour relier le réseau praticable (Accès, routes, camp) à la case devant l'entrée.
## Recherche en largeur sur 8 directions, uniquement sur des cases où une route peut être posée.
func _road_plan() -> Array[Vector2i]:
	var front := entrance + (Vector2i(0, 1) if entrance.y == _park_area().end.y - 1 or entrance.y == zoo_rect.end.y - 1 else Vector2i(0, -1))
	return _cached("route", _road_plan_to.bind(front, _park_area()))


func _road_plan_to(front: Vector2i, park: Rect2i) -> Array[Vector2i]:
	var m := g.map
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var network := func(t: Vector2i) -> bool:
		return m.in_bounds(t.x, t.y) and (m.road[m.idx(t.x, t.y)] == 1 or m.in_camp(t.x, t.y))
	var buildable := func(t: Vector2i) -> bool:
		var site := g.site_at(t)
		var water := m.in_bounds(t.x, t.y) and m.get_t(t.x, t.y) == GameMap.EAU and not m.in_camp(t.x, t.y)
		var road := m.in_bounds(t.x, t.y) and m.road[m.idx(t.x, t.y)] == 1  # tronçon déjà posé mais isolé
		return (_land(t) or water or road) and not reserved.has(t) and not fence_tiles.has(t) and not park.has_point(t) \
			and (site == null or site.def_id() in ["route", "pont"])
	# Départ : tout le réseau déjà praticable depuis l'Accès
	var came := {m.exit_tile: m.exit_tile}
	var queue: Array[Vector2i] = [m.exit_tile]
	var head := 0
	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		for d in dirs:
			var q: Vector2i = p + d
			if not came.has(q) and network.call(q):
				came[q] = q  # fait partie du réseau existant
				queue.append(q)
	# Extension sur les cases constructibles jusqu'à la case devant l'entrée
	head = 0
	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		if p == front:
			var path: Array[Vector2i] = []
			var t := p
			while came[t] != t:
				path.push_front(t)
				t = came[t]
			if not network.call(t):
				path.push_front(t)
			return path.filter(func(x): return not network.call(x))
		for d in dirs:
			var q: Vector2i = p + d
			if not came.has(q) and buildable.call(q):
				came[q] = p
				queue.append(q)
	return []


## Animal à soigner : un malade que personne ne soigne, sinon un animal pas encore soigné aujourd'hui.
func _patient():
	var treated := {}
	for o in g.workers:
		if o.task.get("kind") == "care":
			treated[o.task["obj"]] = true
	for a in g.animals:
		if a.arrived and a.sick and not treated.has(a):
			return a
	for a in g.animals:
		if a.arrived and not g.cared_today.has(a) and not treated.has(a):
			return a
	return null


## Un malade attend : un Soigneur posté auprès d'un animal en bonne santé change d'enclos.
func _heal_sick() -> void:
	var waiting := g.sick_animals().filter(func(a): return not g.workers.any(func(o): return o.task.get("obj") == a))
	if waiting.is_empty():
		return
	for o in g.workers:
		if o.task.get("kind") == "care" and not o.task["obj"].sick:
			g.order([o], waiting[0].tiles[0])
			return


## Une fois le zoo ouvert, quelqu'un tient le guichet et la boutique (sinon pas de recettes).
func _staff_posts() -> void:
	# Zoo fermé (aucun animal arrivé) : personne au guichet ni à la boutique, ils retournent aux chantiers.
	if not g.zoo_status()["open"]:
		for w in g.workers:
			if w.task.get("kind") in ["ticket", "shop"]:
				w.task = {}
				w.path.clear()
	if g.animals.filter(func(a): return a.arrived).is_empty() and g.contracts.is_empty():
		return
	# Guichet et boutique seulement zoo ouvert : avant, personne ne vient, et ces ouvriers manqueraient aux chantiers.
	var open: bool = g.zoo_status()["open"]
	# Guichet et cuisine d'abord. Les autres postes laissent des bras aux chantiers : sinon, zoo ouvert, plus rien ne se construit.
	var bras := _builders_needed()
	_release_posts(bras)
	for s in g.sites:
		if s.done and s.def_id() == "entree" and open:
			_ensure_post(s, "ticket")
			# File qui s'allonge : un deuxième guichetier
			if g.visitor_queue >= 10 and _free_hands() > bras:
				_ensure_post(s, "ticket", 2)
		elif s.done and s.def_id() == "boutique" and open:
			if _free_hands() > bras:
				_ensure_post(s, "shop")
		elif s.done and s.def_id() == "kiosque" and open:
			if _free_hands() > (0 if strat["spectacle"] else bras):
				_ensure_post(s, "kiosque")
		elif s.done and s.def_id() == "cuisine" and g.food_due():
			# Un nourrisseur pour 4 animaux (l'Animalier, puis le Soigneur, puis le moins utile ailleurs)
			var arrived := g.animals.filter(func(a): return a.arrived).size()
			_ensure_job(s, "feed", ceili(arrived / 4.0), "nourrir", "animalier")
		elif s.done and s.def_id() == "entretien" and g.proprete < 75.0:
			# Parc vraiment sale : il fait fuir les visiteurs, le nettoyage passe avant les chantiers
			if g.proprete < 50.0 or _free_hands() > bras:
				_ensure_job(s, "clean", 1, "nettoyer", "agent_entretien")


## Ouvriers disponibles pour les chantiers : ni postés, ni dehors.
func _free_hands() -> int:
	return g.workers.filter(func(w): return not w.offmap and not w.task.get("type") in ["station", "feed", "clean"] and not w.card.metier["id"] in ["lobbyiste", "marchand"]).size()


## Bras à garder aux chantiers : aucun s'il n'y a plus rien à construire.
func _builders_needed() -> int:
	if not g.sites.any(func(s): return not s.done) and not plans.any(func(p): return _plan_left(p) > 0):
		return 0
	return 2 if g.workers.size() >= 4 else 1


## Libère un poste secondaire quand un chantier manque de bras (kiosque, boutique, puis nettoyage).
func _release_posts(bras: int) -> void:
	if _free_hands() >= bras:
		return
	for kind in ["kiosque", "shop"]:
		if kind == "kiosque" and strat["spectacle"]:
			continue
		for w in g.workers:
			if w.task.get("kind") == kind:
				w.task = {}
				w.path.clear()
				return
	if g.proprete >= 50.0:
		for w in g.workers:
			if w.task.get("type") == "clean":
				w.task = {}
				w.path.clear()
				return


## Affecte des ouvriers à une tâche en boucle partant d'un bâtiment (nourrir, nettoyer) jusqu'à `wanted`.
func _ensure_job(site: GameState.Site, type: String, wanted: int, task: String, specialist: String) -> void:
	var have := g.workers.filter(func(w): return w.task.get("type") == type and w.task.get("site") == site).size()
	for i in wanted - have:
		var best: GameState.Worker = null
		var best_v := INF
		for w in g.workers:
			if w.offmap or w.task.get("type") in ["station", "feed", "clean"] or w.card.metier["id"] in ["lobbyiste", "marchand"]:
				continue
			if w.card.traits.has("col_blanc"):
				continue
			var v := g.efficiency(w.card, "defaut") - 2.0 * g.efficiency(w.card, task)
			if w.card.metier["id"] == specialist:
				v -= 5.0
			if v < best_v:
				best_v = v
				best = w
		if best == null:
			return
		g.order([best], site.rect.position)


func _ensure_post(site: GameState.Site, kind: String, wanted := 1) -> void:
	if g.workers.filter(func(w): return w.task.get("kind") == kind and w.task.get("obj") == site).size() >= wanted:
		return
	var best: GameState.Worker = null
	var best_v := INF
	for w in g.workers:
		if w.offmap or w.task.get("type") in ["station", "feed", "clean"] or w.card.metier["id"] in ["lobbyiste", "marchand"]:
			continue
		# Les moins utiles ailleurs tiennent les postes (la recette ne dépend que de la présence).
		var v := g.efficiency(w.card, "defaut")
		if w.unpaid:
			v -= 2.0
		if w.card.traits.has("col_blanc"):
			v -= 3.0
		if kind == "shop" and w.card.metier["id"] == "vendeur":
			v -= 5.0
		if kind == "ticket":
			v -= 3.0 * (g.efficiency(w.card, "guichet") - g.efficiency(w.card, "defaut"))  # le Guichetier d'abord
		if kind == "kiosque":
			v -= 3.0 * (g.efficiency(w.card, "animer") - g.efficiency(w.card, "defaut"))  # l'Animateur d'abord
		if v < best_v:
			best_v = v
			best = w
	if best:
		g.order([best], site.rect.position)


func _builders(s: GameState.Site) -> int:
	return g.workers.filter(func(o): return o.task.get("site") == s).size()


func _best_site_for(w: GameState.Worker) -> GameState.Site:
	var best: GameState.Site = null
	var best_score := INF
	for s in g.sites:
		if s.done:
			continue
		if s.kind == "amenagement" and not g.can_landscape(w.card):
			continue
		var cap := 1 if s.rect.get_area() == 1 else 3
		var n := _builders(s)
		if n >= cap or g.work_tiles(s).is_empty():
			continue
		var eff := g.efficiency(w.card, s.type_travail())
		if strat["specialisation"] and eff < 0.9 and _builders(s) > 0:
			continue  # spécialisation : les chantiers aux bons ouvriers, les autres récoltent
		var score := w.pos.distance_to(Vector2(s.rect.get_center())) - (25.0 if strat["specialisation"] else 8.0) * eff + 6.0 * n
		if score < best_score:
			best_score = score
			best = s
	return best


func _gather(w: GameState.Worker) -> void:
	var needs := _needs()
	var res := ""
	if needs["or"] > g.stock["or"] or ((strat["mine_prioritaire"] or strat["rush_or"]) and g.mine_built):
		for gold in g.map.golds:
			# L'or finance le zoo, il ne le remplace pas : 2 mineurs tant que l'enceinte n'est pas finie.
			var cap := 3 if strat["mine_prioritaire"] and _walls_progress() >= 1.0 else 2
			if strat["rush_or"]:
				# l'économie repose sur l'or vendu au Marché ; 3 bâtisseurs tant que l'enceinte n'est pas finie
				cap = maxi(2, g.workers.size() - (3 if _walls_progress() < 1.0 else 2))
			if g.mine_ready(gold) and (w.card.metier["id"] == "mineur" or g.workers.filter(func(o): return o.task.get("res") == "or").size() < cap):
				g.order([w], gold)
				return
	var deficit_b: float = needs["bois"] - g.stock["bois"]
	var deficit_p: float = needs["pierre"] - g.stock["pierre"]
	if deficit_b <= 0 and deficit_p <= 0 or strat["specialisation"]:
		res = "bois" if g.efficiency(w.card, "extraire_bois") >= g.efficiency(w.card, "extraire_pierre") else "pierre"
	else:
		var wb: float = deficit_b * g.efficiency(w.card, "extraire_bois") / 6.0
		var wp: float = deficit_p * g.efficiency(w.card, "extraire_pierre") / 4.0
		res = "bois" if wb >= wp else "pierre"
	var tiles: Array = resource_tiles.get(res, [])
	if tiles.is_empty():
		return
	# La case la moins occupée parmi les plus proches du camp.
	var best: Vector2i = tiles[0]
	var best_n := 99
	for t in tiles.slice(0, 10):
		var n := g.workers.filter(func(o): return o.task.get("target") == t).size()
		if n < best_n:
			best_n = n
			best = t
	g.order([w], best)


## Si des chantiers attendent sans personne, un extracteur sans charge part y travailler.
func _reassign_idle_extractors() -> void:
	var empty_sites := g.sites.filter(func(s): return not s.done and _builders(s) == 0)
	if empty_sites.is_empty():
		return
	for w in g.workers:
		if w.task.get("type") == "extract" and w.carry < 0.5 and w.task.get("res") != "or":
			var site := _best_site_for(w)
			if site:
				g.order([w], site.rect.position)
				return
