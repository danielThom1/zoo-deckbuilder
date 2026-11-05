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
	"adaptatif": true,  # l'équipe oriente le plan (mine, Marché, Kiosque…) et les besoins du moment orientent les embauches
	"agrandir": true,  # agrandit le parc quand il sature ou pour accueillir une espèce qui n'y tient pas
	"meme_type": false,  # contrats d'un seul type d'animal, choisi selon le marché et les animaux rares
	"type_cible": "",  # type d'animal imposé (herbivore, predateur, aquatique, aerien)
	"continent_cible": "",  # continent imposé (sinon « affinite » le choisit selon le marché)
	"score_simple": false,  # ancienne évaluation des contrats (réputation / prix), pour comparer
}

const ZOO_SIZES := {"petit": Vector2i(12, 10), "moyen": Vector2i(16, 13), "grand": Vector2i(22, 16)}

const DIRS4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const THINK_EVERY := 2.0
const AGRANDIR_MAX := 4  # agrandissements au plus dans une partie
const PARC_MAX := Vector2i(46, 38)
const PROFONDEURS := [6, 9, 12]  # cases gagnées d'un côté à chaque agrandissement

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
var _anneaux := {}
var _murs_version := -1
var _murs_rect := Rect2i()
var _murs_valeur := 0.0
var _cache_cle: Array = []
var _search_cache := {}  # recherches coûteuses (route d'accès, emplacements), même principe que _plan_cache
var agrandissements := 0  # commencés
var agrandis := 0  # terminés
var agrandi_jour := -1  # jour où l'agrandissement en cours a commencé
var agrandir_refus := []  # enceintes abandonnées : un mur n'a pas pu être posé
var _ext_cache := {}  # recherches d'agrandissement, valables une journée
var _ext_jour := -1
var roster_kiosque := false  # un Animateur dans l'équipe : le Kiosque dès l'ouverture
var epargne := 0.0  # argent mis de côté pour un contrat convoité, visible au marché
var agence_voulue := false  # il a manqué un ouvrier précis : l'Agence d'intérim servira
var cabinet_voulu := false  # la rangée n'avait personne d'utile : le Cabinet de recrutement servira


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
	if _opt("besoin"):
		v += _besoin_bonus(c)
	var pt: Dictionary = strat.get("poids_traits", {})
	for t in c.traits:
		v += float(pt.get(t, 0.0))
	return v


## Élément du comportement adaptatif, désactivable un par un pour mesurer ce qu'il apporte (« sans_camp » : true…).
func _opt(nom: String) -> bool:
	return strat["adaptatif"] and not strat.get("sans_" + nom, false)


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
			return (1.0 if strat["formation"] else 0.6) if not has.call("formateur") else -1.0
		"journaliste":
			return 0.5 if not has.call("journaliste") else -1.0
	return 0.0


## Ce qui manque à l'équipe aujourd'hui : file au guichet, mine sans mineur, murs à monter, animaux à soigner…
func _besoin_bonus(c: GameState.Card) -> float:
	var job: String = c.metier["id"]
	var team := g.all_employees()
	var n := team.filter(func(o): return o.metier["id"] == job).size()
	var v := 0.0
	if c.traits.has("peureux") and _owned_defs().any(func(d): return d.get("type", "") == "predateur"):
		v -= 0.5
	match job:
		"vendeur":
			if g.has_building("boutique") and n == 0:
				v += 0.7
		"animateur":
			if g.has_building("kiosque") and n == 0:
				v += 0.7
		"guichetier":
			if g.visitor_queue >= 10 and n == 0:
				v += 1.0
		"soigneur":
			if g.animals.size() >= 3 and n == 0:
				v += 0.6
		"animalier":
			if g.animals.size() >= 4 and n == 0:
				v += 0.5
		"mineur":
			if g.mine_built and n < 2:
				v += 0.8
		"marchand":
			if g.mine_built and n == 0:
				v += 0.6
		"macon":
			if zoo_rect.size != Vector2i.ZERO and (_walls_progress() < 0.7 or _extending()):
				v += 0.4
		"charpentier":
			if plans.any(func(p): return _ring_left(p) >= 8):
				v += 0.4
		"paysagiste", "terrassier":
			if not _has_landscaper():
				v += 0.8
		"lobbyiste":
			if n == 0:
				v += 0.6
		"contremaitre":
			if team.size() >= 6 and n == 0:
				v += 0.3
	return v


func card_value(c: GameState.Card) -> float:
	return mt.draft_value(c, g.index)


# --- Début et fin de journée -------------------------------------------------

func on_day_start() -> void:
	if zoo_rect.size == Vector2i.ZERO and (not g.contracts.is_empty() or g.day >= 3 or _opt("zoo_j1")):
		_choose_zoo()
	_index_resources()
	lobby_today = 0
	_adapter_au_roster()
	_maybe_extend()
	# Cartes d'action : avant de déployer (Prime, Heures sup, Livraison, Recrutement ; Portes ouvertes si le zoo
	# est ouvert), puis Formation express une fois les ouvriers sur la carte.
	for pass_i in 2:
		for c in g.hand.duplicate():
			if c.is_action() and c.action.get("cible", false):
				_play_targeted(c)
			elif c.is_action() and c.action["id"] != "formation_express" \
				and (c.action["id"] != "portes_ouvertes" or _portes_utiles()):
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
				# Posté à la boutique, il vend ×2,5 et rapporte de la réputation : la Braderie, faute de quoi le payer.
				if open and built.call("boutique") and g.money < g.salary(c):
					g.play_cadre(c)
			"formateur":
				# Stage : la meilleure carte qui a un défaut, s'il reste assez de bras pour la journée.
				if g.hand.filter(func(o): return not o.is_action()).size() >= 4:
					var eleve: GameState.Card = null
					for o in g.hand:
						if not o.is_action() and g.cadre_error(c, o) == "" and (eleve == null or card_value(o) > card_value(eleve)):
							eleve = o
					if eleve:
						g.play_cadre(c, eleve)
			"animateur":
				if open and not g.animals.is_empty() and not built.call("kiosque"):
					g.play_cadre(c)


## L'équipe oriente le plan : un cadre sans son bâtiment ne sert à rien, des mineurs sans mine non plus.
func _adapter_au_roster() -> void:
	if not _opt("roster"):
		return
	var n := {}
	for c in g.all_employees():
		n[c.metier["id"]] = int(n.get(c.metier["id"], 0)) + 1
	var mineurs := int(n.get("mineur", 0))
	var marchands := int(n.get("marchand", 0))
	if int(n.get("vendeur", 0)) > 0:
		strat["boutique"] = true
	if int(n.get("animateur", 0)) > 0:
		roster_kiosque = true
	if mineurs >= 2 or (mineurs >= 1 and marchands >= 1):
		strat["mine_prioritaire"] = true
	if marchands >= 1 and (g.mine_built or mineurs >= 1):
		strat["marche"] = true


## Portes ouvertes : seulement si le parc peut accueillir le surplus de visiteurs.
func _portes_utiles() -> bool:
	if not g.zoo_status()["open"]:
		return false
	return not strat["adaptatif"] or float(g.attractiveness()) * _presence_par_attractivite() * 1.25 < g.visitor_capacity()


## Argent à garder pour tout ce qui n'est pas indispensable : le plancher, plus le contrat convoité.
func _floor_achats() -> float:
	return _cash_floor() + epargne


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
		if g.money - float(g.campaign_cost(d)) * 2.0 >= _floor_achats() + float(strat["reserve"]):
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
	# Avant l'ouverture, tout le stock servira à l'enceinte et au premier enclos.
	if strat["adaptatif"] and not g.zoo_status()["open"] and g.money >= _cash_floor():
		return
	var needs := _needs()
	var keep := {}
	var missing := target - g.money
	var a_vendre := false
	for res in ["bois", "pierre"]:
		var extra := maxf(0.0, floorf(g.stock[res] - float(needs[res]) - SURPLUS_STOCK))
		var price := g.sell_price(res)
		var units := minf(extra, ceilf(missing / price)) if price > 0.0 else 0.0
		missing -= units * price
		keep[res] = g.stock[res] - units
		a_vendre = a_vendre or units >= 1.0
	if a_vendre:
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
var _wage_key := -1
var _wage_cache := 0.0


func _cash_floor() -> float:
	var food := 0.0
	if g.food_due():
		for a in g.animals:
			food += g.food_cost(a.def)
	return maxf(8.0, _wage_floor()) + food


func _wage_floor() -> float:
	if _wage_key == g.version:
		return _wage_cache
	var wages: Array = g.all_employees().map(func(c): return float(g.salary(c)))
	wages.sort()
	wages.reverse()
	var total := 0.0
	for k in mini(g.hand_size(), wages.size()):
		total += wages[k]
	_wage_key = g.version
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
	if _opt("agence"):
		_gerer_agence()
	_gerer_journaliste()
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

## Reportage chez le rival le mieux placé ; un article quand l'argent le permet, une accusation quand il abonde.
func _gerer_journaliste() -> void:
	for w in g.workers:
		if not g.est_journaliste(w) or not w.offmap:
			continue
		if w.reportage.is_empty():
			var cible := -1
			for i in mt.players.size():
				if i != g.index and (cible < 0 or mt.players[i].rep_points > mt.players[cible].rep_points):
					cible = i
			if cible >= 0:
				g.report_start(w, cible)
			continue
		var P: Dictionary = g.data["buildings"]["presse"]
		var rival: GameState = mt.players[int(w.reportage["cible"])]
		if rival.presse_jours == 0 and rival.zoo_status()["open"] and g.article_error(w) == "" \
			and g.money - float(P["article"]) >= _floor_achats() + float(strat["reserve"]) + 10.0:
			g.publish_article(w)
		if g.money - float(P["accusation"]) >= _floor_achats() + float(strat["reserve"]) + 20.0:
			var vise: GameState.Worker = null
			for o in g.report_visibles(w):
				if g.accuse_error(w, o.card.id) == "" and (vise == null or o.card.niveau > vise.card.niveau):
					vise = o
			if vise and (vise.card.niveau >= 3 or vise.card.metier["categorie"] != "peu_qualifie"):
				g.accuse_worker(w, vise.card.id)


## L'ouvrier qu'il faudrait sur le terrain tout de suite (celui que l'Agence d'intérim va chercher), ou "".
func _ouvrier_voulu() -> String:
	var present := func(id: String) -> bool:
		return g.workers.any(func(o): return o.card.metier["id"] == id)
	if not g.sick_animals().is_empty() and not present.call("soigneur"):
		return "soigneur"
	if plans.any(func(p): return not p["conv"].is_empty()) and not g.workers.any(func(o): return g.can_landscape(o.card)):
		return "amenageur"
	if g.visitor_queue >= 10 and not present.call("guichetier"):
		return "guichetier"
	if g.has_building("boutique") and g.zoo_status()["open"] and not present.call("vendeur"):
		return "vendeur"
	return ""


## Agence d'intérim : va chercher dans le deck l'ouvrier précis qui manque aujourd'hui, à la place du moins utile.
func _gerer_agence() -> void:
	if g.time > g.day_length * 0.7:
		return
	var voulu := _ouvrier_voulu()
	if voulu == "":
		return
	var cand: GameState.Card = null
	for c in g.swap_candidates():
		var ok: bool = g.can_landscape(c) if voulu == "amenageur" else c.metier["id"] == voulu
		if ok and (cand == null or card_value(c) > card_value(cand)):
			cand = c
	if cand == null:
		return
	agence_voulue = true
	if not g.agency_built() or g.money - g.swap_cost(cand) < _cash_floor():
		return
	var sort_de: GameState.Worker = null
	for w in g.workers:
		if w.offmap or w.task.get("kind") == "ticket" or w.task.get("type") == "feed":
			continue
		if sort_de == null or (w.unpaid and not sort_de.unpaid) or (w.unpaid == sort_de.unpaid and card_value(w.card) < card_value(sort_de.card)):
			sort_de = w
	if sort_de and g.swap_error(sort_de, cand) == "" and g.swap_worker(sort_de, cand):
		sort_de.task = {}
		sort_de.path.clear()


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
			var reve: Dictionary = {}  # le meilleur contrat hors de portée ce soir
			var reve_score := 0.0
			epargne = 0.0
			for def in g.market_contracts:
				if g.has_species(def["id"]) or g.contracts_tonight >= int(g.data["buildings"]["marche"]["contrats_par_nuit"]):
					continue
				var cost := _money_cost(def)
				var margin := 0.0 if _needs_first_animal() else float(strat["reserve"])
				var abordable: bool = g.contract_error(def) == "" and g.money - cost >= margin + _cash_floor()
				if not abordable and (g.animals.is_empty() or g.money + _revenu_estime() * 1.5 - cost < _cash_floor()):
					continue
				if zoo_rect.size != Vector2i.ZERO and _plan_enclosure(def).is_empty() and not _can_extend_for(def):
					continue
				if not _strategy_allows(def):
					continue
				# Sans Paysagiste ni Terrassier, aucun aménagement possible : le motif doit déjà exister.
				if not _has_landscaper() and not _natural_fit(def):
					continue
				var score := _contract_score(def, cost)
				if abordable and score > best_score:
					best_score = score
					best = def
				elif not abordable and score > reve_score:
					reve_score = score
					reve = def
			# Un contrat bien meilleur sera à portée dans un jour ou deux : on met de côté plutôt que d'acheter un petit.
			if _opt("epargne") and not reve.is_empty() and float(strat["preference_palier"]) >= 1.0 and reve_score > best_score * 1.5:
				epargne = _money_cost(reve)
				if best.is_empty() or (best["palier"] == "T1" and not g.animals.is_empty()):
					best = {}
			if not best.is_empty() and g.buy_contract(best):
				mt.log.append("%s achète le contrat %s." % [mt.names[g.index], best["nom"]])


## Note d'un contrat : la réputation qu'il rapportera d'ici la fin de la partie, moins vite s'il vide la trésorerie.
func _contract_score(def: Dictionary, cost: float) -> float:
	var tier := float(str(def["palier"]).substr(1).to_int())
	var pref := float(strat["preference_palier"])
	var score: float
	if strat["score_simple"]:
		# Argent abondant (fin de partie) : la réputation gagnée compte plus que le prix, d'où les T2/T3.
		var price_weight := 1.0 if cost * 3.0 > g.money - _cash_floor() else 0.3
		score = _rep_gain(def) * pow(tier, pref - 1.0) / (cost * price_weight + 10.0)
	else:
		var effort := _effort_days(def)
		if effort == INF:
			return 0.0
		var jours := maxf(0.5, _days_left() - 1.0 - effort)
		var marge := maxf(1.0, g.money - _cash_floor())
		score = (_contract_value(def) * jours + _objectif_bonus(def)) * pow(tier, (pref - 1.0) * 2.0) / (1.0 + cost / marge)
	return score * pow(2.0, float(strat.get("poids_animaux", {}).get(def["id"], 0.0)))


## Réputation qu'un contrat rapproche via les objectifs des actionnaires : le gain entier s'il remplit un objectif,
## une part s'il en rapproche.
func _objectif_bonus(def: Dictionary) -> float:
	var pts := float(g.data["buildings"]["objectifs"]["reputation"])
	var owned := _owned_defs()
	var bonus := 0.0
	for o in mt.objectifs:
		if g.objectifs_faits.has(o["id"]):
			continue
		var n := -1
		match str(o["type"]):
			"continent":
				n = owned.filter(func(d): return d.get("continent", "") == def.get("continent", "")).size()
			"type":
				n = owned.filter(func(d): return d.get("type", "") == def.get("type", "")).size()
			"palier":
				if def["palier"] == o["palier"]:
					n = owned.filter(func(d): return d["palier"] == o["palier"]).size()
			"especes":
				n = owned.size()
		if n < 0:
			continue
		if n + 1 >= int(o["n"]):
			bonus += pts
		elif n + 2 == int(o["n"]):
			bonus += pts * 0.3
	return bonus


## Objectif encore ouvert de ce type, ou vide.
func _objectif_ouvert(type: String) -> Dictionary:
	for o in mt.objectifs:
		if o["type"] == type and not g.objectifs_faits.has(o["id"]):
			return o
	return {}


## Espèces acquises ou attendues.
func _owned_defs() -> Array:
	var out := []
	for a in g.animals:
		if not out.has(a.def):
			out.append(a.def)
	for d in g.contracts:
		if not out.has(d):
			out.append(d)
	return out


## Visiteurs présents en même temps pour 1 point d'attractivité.
func _presence_par_attractivite() -> float:
	var Z: Dictionary = g.data["buildings"]["zoo"]
	return float(Z["visiteurs_par_point_attractivite"]) * float(Z["duree_visite_s"]) / g.day_length


## Attractivité au-delà de laquelle le parc est plein et la file attend.
func _attr_limit() -> float:
	var r := _park_area()
	if r.size == Vector2i.ZERO:
		r = Rect2i(Vector2i.ZERO, ZOO_SIZES["moyen"])
	var capacite := r.grow(-1).get_area() / float(g.data["buildings"]["zoo"]["cases_par_visiteur"])
	return capacite / _presence_par_attractivite()


func _owned_attr() -> float:
	var somme := 0.0
	for d in _owned_defs():
		somme += float(d["reputation"])
	return maxf(float(g.attractiveness()), somme)


## Attractivité ajoutée par une nouvelle espèce : la sienne et les effets des rares.
func _attr_gain(def: Dictionary) -> float:
	var owned := _owned_defs()
	if owned.any(func(d): return d["id"] == def["id"]):
		return 0.0
	var gain := float(def["reputation"])
	var rare: Dictionary = def.get("effet_rare", {})
	for d in owned:
		if rare.has("type_bonus") and rare["type_bonus"] == d.get("type", ""):
			gain += float(rare["points"])
		var autre: Dictionary = d.get("effet_rare", {})
		if autre.has("type_bonus") and autre["type_bonus"] == def.get("type", ""):
			gain += float(autre["points"])
	return gain


## Ce que le marché laisse espérer : un rare qui valoriserait ce type, d'autres espèces du même continent ;
## et le rare du type visé par la stratégie, même si la collection n'est pas encore là.
func _market_synergy(def: Dictionary) -> float:
	var s := 0.0
	var rare: Dictionary = def.get("effet_rare", {})
	if strat["adaptatif"]:
		for o in g.market_contracts:
			if o == def:
				continue
			var r2: Dictionary = o.get("effet_rare", {})
			if r2.has("type_bonus") and r2["type_bonus"] == def.get("type", ""):
				s += float(r2["points"]) * 0.5
			if rare.has("type_bonus") and rare["type_bonus"] == o.get("type", ""):
				s += float(rare["points"]) * 0.5
			if o.get("continent", "") == def.get("continent", ""):
				s += 1.0
	if rare.has("type_bonus") and rare["type_bonus"] == _type_target():
		s += float(rare["points"]) * 2.0
	return s


## Bonus d'affinité (part de réputation en plus) gagné avec une espèce de plus de ce continent.
func _affinity_gain(def: Dictionary) -> float:
	var steps: Array = g.data["animals"]["affinite_continent"]["paliers"]
	var n := _owned_defs().filter(func(d): return d.get("continent", "") == def.get("continent", "")).size()
	return float(steps[mini(n + 1, steps.size() - 1)]) - float(steps[mini(n, steps.size() - 1)])


## Réputation par jour qu'une espèce ajoutera, en tenant compte de la place dans le parc.
func _contract_value(def: Dictionary) -> float:
	var base := _owned_attr()
	var ajout := _attr_gain(def) + _market_synergy(def)
	var limite := _attr_limit()
	var place := maxf(0.0, limite - base)
	var utile := minf(ajout, place) + maxf(0.0, ajout - place) * (0.6 if strat["agrandir"] else 0.15)
	var par_point := _presence_par_attractivite() * float(g.data["buildings"]["zoo"]["reputation_par_visiteur_moyen"])
	return (utile + _affinity_gain(def) * minf(base + ajout, limite)) * par_point


## Jours restants estimés, d'après l'avance du meilleur joueur.
func _days_left() -> float:
	if g.day <= 2:
		return 12.0
	var leader := 0.0
	for p in mt.players:
		leader = maxf(leader, p.rep_points)
	var rythme := leader / float(g.day - 1) * 1.4
	return clampf((float(mt.objective()) - leader) / maxf(rythme, 2.0), 1.0, 14.0)


## Travail par journée sur cette tâche avec l'équipe actuelle : les meilleurs, tirés une partie des jours seulement.
func _team_rate(task: String, n: int) -> float:
	var team := g.all_employees()
	if team.is_empty():
		return 1.0
	var effs: Array = team.map(func(c): return g.efficiency(c, task))
	effs.sort()
	effs.reverse()
	var total := 0.0
	for k in mini(n, effs.size()):
		total += float(effs[k])
	return maxf(1.0, total * g.day_length * minf(1.0, float(g.hand_size()) / team.size()))


## Journées nécessaires pour accueillir cette espèce avec cette équipe : un aménageur rend les motifs difficiles
## abordables, un Charpentier les grands enclos. INF : aucune place, même en agrandissant.
func _effort_days(def: Dictionary) -> float:
	if zoo_rect.size == Vector2i.ZERO:
		return 1.0
	var plan := _plan_enclosure(def)
	var murs := 0
	if plan.is_empty():
		var ext := _extension_for(def)
		if ext.is_empty():
			return INF
		plan = ext["plan"]
		murs = int(ext["murs"])
	var manuel: float = float(g.building_def("enclos")["travail"]) * _ring_left(plan) + float(g.building_def("cloture")["travail"]) * murs
	var decor: String = def.get("decor", "")
	if decor != "" and not _has_decor(decor, plan["interior"]):
		manuel += float(g.building_def(decor)["travail"])
	var jours := manuel / _team_rate("construire_enclos", 2)
	var conv := _conv_cost(plan["conv"])
	if conv > 0:
		var pros := g.all_employees().filter(func(c): return g.can_landscape(c))
		var cadence := 0.0
		for c in pros:
			cadence += g.efficiency(c, "amenager")
		jours += conv * 40.0 / maxf(1.0, cadence * g.day_length * minf(1.0, float(g.hand_size()) / g.all_employees().size()))
	return jours


## Argent rapporté par une journée de visites, au billet seul.
func _revenu_estime() -> float:
	return minf(float(g.attractiveness()), _attr_limit()) * float(g.data["buildings"]["zoo"]["visiteurs_par_point_attractivite"]) * float(g.data["buildings"]["zoo"]["billet"])


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
		var best_card := _meilleure_embauche()
		# Personne d'utile dans la rangée : le Cabinet de recrutement fait venir un profil plus qualifié.
		if best_card == null and _opt("agence"):
			cabinet_voulu = true
			_recruter_au_cabinet()
			best_card = _meilleure_embauche()
		if best_card and g.hire(best_card):
			mt.log.append("%s embauche %s (%s)." % [mt.names[g.index], best_card.nom, g.job_name(best_card)])


func _meilleure_embauche() -> GameState.Card:
	var best_card: GameState.Card = null
	var best_v := 1.8
	for c in g.market_workers:
		if g.hire_error(c) != "" or g.money - g.hire_cost(c) < float(strat["reserve"]) + _floor_achats():
			continue
		var v := card_value(c) - g.hire_cost(c) * 0.05
		if v > best_v:
			best_v = v
			best_card = c
	return best_card


func _recruter_au_cabinet() -> void:
	if g.market_workers.is_empty():
		return
	var pire: GameState.Card = g.market_workers[0]
	for c in g.market_workers:
		if card_value(c) < card_value(pire):
			pire = c
	for cat in ["cadre", "qualifie"]:
		# De quoi payer le remplacement et l'embauche qui suit.
		if g.recruit_error(cat) == "" and g.money - g.recruit_price(cat) - 16.0 >= _floor_achats() + float(strat["reserve"]):
			g.recruit_replace(pire, cat)
			return


## Carte d'action : une par nuit quand l'argent abonde, 4 au plus dans le deck (sinon elles diluent la main).
func _night_buy_action() -> void:
	# Étude : une carte au hasard de temps en temps, pour que toutes soient jouées
	if g.rng.randf() < float(strat["explore"]) and not mt.market_actions.is_empty():
		var rc: GameState.Card = mt.market_actions[g.rng.randi_range(0, mt.market_actions.size() - 1)]
		if g.action_error(rc) == "" and g.money - g.action_price(rc) >= _cash_floor():
			g.buy_action(rc)
		return
	if strat["cartes"]:
		var pick: GameState.Card = null
		for c in mt.market_actions:
			if g.action_error(c) == "" and g.money - g.action_price(c) >= _floor_achats() \
				and (pick == null or _action_value(c) > _action_value(pick)):
				pick = c
		if pick and g.buy_action(pick):
			mt.log.append("%s achète la carte %s." % [mt.names[g.index], pick.action["nom"]])
		return
	if g.action_cards().size() < 4 and zoo_rect.size != Vector2i.ZERO:
		var best_a: GameState.Card = null
		for c in mt.market_actions:
			if g.action_error(c) != "" or g.money - g.action_price(c) < _floor_achats() + float(strat["reserve"]) + 20.0:
				continue
			if _action_value(c) > 0.0 and (best_a == null or _action_value(c) > _action_value(best_a)):
				best_a = c
		if best_a and g.buy_action(best_a):
			mt.log.append("%s achète la carte %s." % [mt.names[g.index], best_a.action["nom"]])


## Filtres de contrats propres à la stratégie : un seul continent (Affinités), pas de T1 en milieu de partie (Haut de gamme).
func _strategy_allows(def: Dictionary) -> bool:
	var first := g.animals.is_empty() and g.contracts.is_empty()
	var cc := _continent_target()
	if cc != "" and def.get("continent", "") != cc and not _cible_relachee(func(d): return d.get("continent", "") == cc):
		return false
	var tt := _type_target()
	if tt != "" and def.get("type", "") != tt and not _cible_relachee(func(d): return d.get("type", "") == tt):
		return false
	if int(strat["palier_min"]) >= 2 and not first and def["palier"] == "T1" \
		and g.day >= int(g.data["animals"]["paliers"]["T2"]["jour_min"]):
		return false
	return true


## Type d'animal visé : imposé, ou (Même type) celui que les animaux acquis et le marché favorisent le plus. Un rare
## qui donne un bonus à ce type pèse lourd : c'est lui qui rend la collection rentable.
func _type_target() -> String:
	if str(strat["type_cible"]) != "":
		return str(strat["type_cible"])
	if not strat["meme_type"]:
		return ""
	var notes := {}
	for t in g.data["animals"]["types"]:
		notes[t] = 0.0
	var compte := func(d: Dictionary, poids: float, poids_rare: float):
		notes[d.get("type", "")] = float(notes.get(d.get("type", ""), 0.0)) + poids
		var b: String = d.get("effet_rare", {}).get("type_bonus", "")
		if b != "":
			notes[b] = float(notes.get(b, 0.0)) + poids_rare
	for d in _owned_defs():
		compte.call(d, 3.0, 4.0)
	for d in g.market_contracts:
		compte.call(d, 1.0, 3.0)
	return _meilleure_note(notes)


## Continent visé : imposé, ou (Affinités) celui des animaux acquis et, à défaut, le mieux servi au marché.
func _continent_target() -> String:
	if str(strat["continent_cible"]) != "":
		return str(strat["continent_cible"])
	if not strat["affinite"]:
		return ""
	var notes := {}
	for c in g.data["animals"]["continents"]:
		notes[c] = 0.0
	for d in _owned_defs():
		notes[d.get("continent", "")] = float(notes.get(d.get("continent", ""), 0.0)) + 3.0
	for d in g.market_contracts:
		notes[d.get("continent", "")] = float(notes.get(d.get("continent", ""), 0.0)) + 1.0
	return _meilleure_note(notes)


func _meilleure_note(notes: Dictionary) -> String:
	var best := ""
	for k in notes:
		if best == "" or float(notes[k]) > float(notes[best]):
			best = k
	return best


## La cible cède si elle bloque la partie : aucun animal à portée pour ouvrir le zoo, ou beaucoup d'argent qui dort
## sans rien de ce type au marché.
func _cible_relachee(convient: Callable) -> bool:
	var dispo := g.market_contracts.filter(convient)
	if g.animals.is_empty() and (g.day >= 3 or not dispo.any(func(d): return g.money - _money_cost(d) >= _cash_floor())):
		return true
	return dispo.is_empty() and g.money > _cash_floor() + 60.0


## Part des murs de l'enceinte déjà terminés (0 à 1).
func _walls_progress() -> float:
	if _murs_version == g.version and _murs_rect == zoo_rect:
		return _murs_valeur
	var ring := _ring(zoo_rect)
	var done := 0
	for t in ring:
		if g.is_wall(t) or g.is_mountain(t):
			done += 1
	_murs_version = g.version
	_murs_rect = zoo_rect
	_murs_valeur = float(done) / ring.size()
	return _murs_valeur


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
	if g.night_action_error(cost) != "" or g.money - cost < _floor_achats() + float(strat["reserve"]):
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


## Réputation gagnée par une nouvelle espèce (ancienne note, pour comparer).
func _rep_gain(def: Dictionary) -> float:
	var gain := float(def["reputation"])
	# Affinité : une espèce d'un continent déjà représenté ajoute 5 % à toute la réputation gagnée.
	if g.animals.any(func(a): return a.def.get("continent", "") == def.get("continent", "")) \
		or g.contracts.any(func(d): return d.get("continent", "") == def.get("continent", "")):
		gain += float(g.data["animals"]["affinite_continent"]["par_espece"]) * maxf(10.0, float(g.attractiveness()))
	return gain


# --- Plan du zoo -------------------------------------------------------------

## Choisit l'emplacement de l'enceinte : terrain adapté aux motifs des contrats détenus, murs constructibles,
## entrée qu'une route peut rejoindre, proche du camp. Une part de hasard propre à chaque IA évite
## que toutes choisissent le même endroit. Parc évolutif : on vise un grand parc mais on commence petit.
## Reprise d'un zoo commencé par un joueur parti : l'enceinte et l'entrée déjà posées définissent le parc.
func reprendre_zoo() -> void:
	var murs := g.sites.filter(func(s): return s.def_id() in ["cloture", "entree"])
	var portes := g.sites.filter(func(s): return s.def_id() == "entree")
	if murs.is_empty() or portes.is_empty():
		return
	var zone: Rect2i = murs[0].rect
	for s in murs:
		zone = zone.merge(s.rect)
	if zone.size.x < 5 or zone.size.y < 5:
		return  # quelques murs seulement : l'IA choisira son propre emplacement
	zoo_rect = zone
	entrance = portes[0].rect.position
	var inner := zoo_rect.grow(-1)
	shop_rect = Rect2i(clampi(entrance.x + 3, inner.position.x, inner.end.x - 2), clampi(entrance.y, inner.position.y, inner.end.y - 2), 2, 2)
	for t in _ring(zoo_rect):
		reserved[t] = true
	for s in g.sites:
		for t in _rect_tiles(s.rect):
			reserved[t] = true


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
	var especes: Array = g.contracts
	# Dès le jour 1 : le terrain qui convient aux animaux communs visibles au marché.
	if especes.is_empty() and _opt("zoo_j1"):
		especes = g.market_contracts.filter(func(d): return d["palier"] == "T1").slice(0, 3)
	# Carte identique pour toutes les IA en début de partie : le calcul, le plus long de la partie, est partagé.
	var empreinte_carte: int = hash(m.tiles)
	for def in especes:
		var cle := "%d|%s" % [empreinte_carte, str(def["id"])]
		if not mt.cartes_motifs.has(cle):
			mt.cartes_motifs[cle] = _carte_motif(def)
		out.append({"def": def, "best": mt.cartes_motifs[cle]})
	return out


## Pour chaque case : le nombre d'aménagements qu'il faudrait pour y poser ce motif (99 : il sort de la carte).
func _carte_motif(def: Dictionary) -> PackedInt32Array:
	var m := g.map
	var w := m.w
	var h := m.h
	var tuiles := m.tiles
	# Coût d'une cellule du motif selon le terrain actuel, calculé une fois pour chaque terrain voulu.
	var couts := {}
	var best := PackedInt32Array()
	best.resize(w * h)
	best.fill(99)
	for v in g.pattern_variants(def):
		var dx := PackedInt32Array()
		var dy := PackedInt32Array()
		var cout_cellule: Array[PackedInt32Array] = []
		var largeur := 0
		var hauteur := 0
		for c in v:
			dx.append(int(c[0]))
			dy.append(int(c[1]))
			largeur = maxi(largeur, int(c[0]))
			hauteur = maxi(hauteur, int(c[1]))
			if not couts.has(c[2]):
				var t := PackedInt32Array()
				for k in GameMap.TERRAINS.size():
					var steps := _conversion_steps(GameMap.TERRAINS[k], c[2])
					t.append(steps if steps >= 0 else 5)
				couts[c[2]] = t
			cout_cellule.append(couts[c[2]])
		var nb := dx.size()
		for y in h - hauteur:
			for x in w - largeur:
				var n := 0
				for k in nb:
					n += cout_cellule[k][tuiles[(y + dy[k]) * w + x + dx[k]]]
				var i := y * w + x
				if n < best[i]:
					best[i] = n
	return best


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


## Le résultat est gardé pour chaque rectangle : à lire sans le modifier.
func _ring(r: Rect2i) -> Array[Vector2i]:
	if _anneaux.has(r):
		return _anneaux[r]
	var out: Array[Vector2i] = []
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if x == r.position.x or y == r.position.y or x == r.end.x - 1 or y == r.end.y - 1:
				out.append(Vector2i(x, y))
	_anneaux[r] = out
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
	var c: Vector2i = m.camp.get_center()
	for res in ["bois", "pierre"]:
		var ter := GameMap.FORET if res == "bois" else GameMap.ROCHE
		var tiles: Array[Vector2i] = []
		var i := 0
		for y in m.h:
			for x in m.w:
				if m.tiles[i] == ter and reach[i]:
					tiles.append(Vector2i(x, y))
				i += 1
		tiles.sort_custom(func(a: Vector2i, b: Vector2i): return (a - c).length_squared() < (b - c).length_squared())
		resource_tiles[res] = tiles.slice(0, 120)


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


## park et scan : parc supposé et zone à explorer, pour juger un agrandissement avant de le construire.
func _compute_plan(def: Dictionary, park := Rect2i(), scan := Rect2i()) -> Dictionary:
	var suppose := park.size != Vector2i.ZERO
	if not suppose:
		park = zoo_rect
		scan = zoo_rect
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
	if suppose:
		walls = {}
		for t in _ring(park):
			if t != entrance and t != entrance + Vector2i(1, 0):
				walls[t] = true
	# Devant l'entrée, on laisse le passage aux visiteurs.
	var gate := Rect2i(entrance - Vector2i(1, 2), Vector2i(4, 5))
	var best := {}
	var best_cost := INF
	for d in dims.slice(0, 3):
		for y in range(maxi(park.position.y, scan.position.y - d.y - 1), mini(park.end.y, scan.end.y + 1) - d.y - 1):
			for x in range(maxi(park.position.x, scan.position.x - d.x - 1), mini(park.end.x, scan.end.x + 1) - d.x - 1):
				var outer := Rect2i(x, y, d.x + 2, d.y + 2)
				if outer.intersects(gate):
					continue
				if suppose and not outer.grow(-1).intersects(scan):
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
				var wall_dist := maxi(0, mini(mini(x - park.position.x, y - park.position.y), mini(park.end.x - outer.end.x, park.end.y - outer.end.y)))
				var cost: float = _conv_cost(conv) * 2.0 - shared * 0.6 + wall_dist * 0.4
				if cost < best_cost:
					best_cost = cost
					best = {"def": def, "interior": interior, "ring": _ring(outer), "conv": conv}
	return best


# --- Agrandir le parc --------------------------------------------------------

## Un agrandissement (ou le grand parc évolutif) attend que son nouveau mur soit fermé.
func _extending() -> bool:
	return target_rect.size != Vector2i.ZERO and not expanded


## Contrat qui ne tient pas dans le parc mais qu'un agrandissement accueillerait, un à la fois.
func _can_extend_for(def: Dictionary) -> bool:
	if not strat["agrandir"] or _extending() or zoo_rect.size == Vector2i.ZERO or _walls_progress() < 1.0:
		return false
	if g.contracts.any(func(d): return _plan_enclosure(d).is_empty()):
		return false
	return not _extension_for(def).is_empty()


## Début de journée : un contrat attend une place, ou le parc est presque plein.
func _maybe_extend() -> void:
	if zoo_rect.size == Vector2i.ZERO:
		return
	# Un mur qui ne se termine pas (case devenue impossible) ne doit pas bloquer les enclos pour toujours.
	if agrandissements > 0 and _extending() and g.day - agrandi_jour >= 4:
		agrandir_refus.append(target_rect)
		target_rect = zoo_rect
		expanded = true
	if not strat["agrandir"] or _extending() or agrandissements >= AGRANDIR_MAX or _walls_progress() < 1.0 or _days_left() <= 2.0:
		return
	for def in g.contracts:
		if _plan_enclosure(def).is_empty():
			var ext := _extension_for(def)
			if not ext.is_empty():
				_start_extension(ext["rect"], "pour accueillir : " + str(def["nom"]))
				return
	var parc := _objectif_ouvert("parc")
	var pour_objectif: bool = not parc.is_empty() and _park_area().grow(-1).get_area() < int(parc["n"]) and g.money > _cash_floor() + 20.0
	if g.zoo_status()["open"] and (_owned_attr() >= _attr_limit() * 0.85 or pour_objectif):
		var best: Dictionary = {}
		var best_note := INF
		for c in _extension_rects():
			var bande: Rect2i = c["strip"]
			var note: float = float(c["murs"]) * 0.2 - bande.get_area() * 0.1 + int(c["montagnes"]) * 0.5
			if note < best_note:
				best_note = note
				best = c
		if not best.is_empty():
			_start_extension(best["rect"], "parc presque plein")


func _start_extension(r: Rect2i, raison: String) -> void:
	target_rect = r
	expanded = false
	agrandissements += 1
	agrandi_jour = g.day
	for t in _ring(r):
		reserved[t] = true
	mt.log.append("%s commence à agrandir son parc (%s)." % [mt.names[g.index], raison])


## Meilleur agrandissement pour cette espèce : celui où son motif demande le moins d'aménagements (terrain déjà bon
## à proximité), puis le moins de murs. {"rect", "plan", "murs"}, ou vide.
func _extension_for(def: Dictionary) -> Dictionary:
	if zoo_rect.size == Vector2i.ZERO or _extending() or agrandissements >= AGRANDIR_MAX:
		return {}
	if _ext_jour != g.day:
		_ext_jour = g.day
		_ext_cache.clear()
	var key := "%s|%d|%s" % [str(zoo_rect), fence_tiles.size(), def["id"]]
	if _ext_cache.has(key):
		return _ext_cache[key]
	var best := {}
	var best_note := INF
	for c in _extension_rects():
		var plan := _compute_plan(def, c["rect"], c["strip"])
		if plan.is_empty():
			continue
		var note: float = _conv_cost(plan["conv"]) + float(c["murs"]) * 0.15
		if note < best_note:
			best_note = note
			best = {"rect": c["rect"], "plan": plan, "murs": c["murs"]}
	_ext_cache[key] = best
	return best


## Agrandissements possibles : un côté sans l'entrée, de 6 à 12 cases.
func _extension_rects() -> Array:
	if _ext_jour != g.day:
		_ext_jour = g.day
		_ext_cache.clear()
	var key := "cotes|%s|%d" % [str(zoo_rect), fence_tiles.size()]
	if _ext_cache.has(key):
		return _ext_cache[key]
	var out := []
	var r := zoo_rect
	for k: int in PROFONDEURS:
		if entrance.y != r.position.y:
			_ajoute_extension(out, Rect2i(r.position - Vector2i(0, k), r.size + Vector2i(0, k)), Rect2i(r.position - Vector2i(0, k), Vector2i(r.size.x, k)), Vector2i(0, -1))
		if entrance.y != r.end.y - 1:
			_ajoute_extension(out, Rect2i(r.position, r.size + Vector2i(0, k)), Rect2i(Vector2i(r.position.x, r.end.y), Vector2i(r.size.x, k)), Vector2i(0, 1))
		if entrance.x != r.position.x:
			_ajoute_extension(out, Rect2i(r.position - Vector2i(k, 0), r.size + Vector2i(k, 0)), Rect2i(r.position - Vector2i(k, 0), Vector2i(k, r.size.y)), Vector2i(-1, 0))
		if entrance.x + 1 != r.end.x - 1:
			_ajoute_extension(out, Rect2i(r.position, r.size + Vector2i(k, 0)), Rect2i(Vector2i(r.end.x, r.position.y), Vector2i(k, r.size.y)), Vector2i(1, 0))
	_ext_cache[key] = out
	return out


## Retient cet agrandissement s'il est réalisable : murs posables, rien de construit dedans, et un passage possible
## à travers l'ancien mur (les murs qui servent de côté à un enclos restent debout).
func _ajoute_extension(out: Array, neuf: Rect2i, strip: Rect2i, cote: Vector2i) -> void:
	var m := g.map
	if neuf.position.x < 1 or neuf.position.y < 1 or neuf.end.x > m.w - 1 or neuf.end.y > m.h - 1:
		return
	if neuf.size.x > PARC_MAX.x or neuf.size.y > PARC_MAX.y or agrandir_refus.has(neuf) or neuf.intersects(m.camp.grow(2)):
		return
	var ancien := {}
	for t in _ring(zoo_rect):
		ancien[t] = true
	var murs := 0
	var cloture := g.building_def("cloture")
	for t in _ring(neuf):
		if ancien.has(t) or g.is_mountain(t):
			continue
		if reserved.has(t) or m.road[m.idx(t.x, t.y)] or m.get_t(t.x, t.y) == GameMap.MINE_OR or g.site_at(t) != null \
			or g.placement_error("batiment", cloture, t, false) != "":
			return
		murs += 1
	var montagnes := 0
	for t in _rect_tiles(strip):
		if m.road[m.idx(t.x, t.y)] or m.get_t(t.x, t.y) == GameMap.MINE_OR or g.site_at(t) != null or t == m.exit_tile or m.in_camp(t.x, t.y):
			return
		if g.is_mountain(t):
			montagnes += 1
	if montagnes * 5 > strip.get_area():
		return
	# Côté commun : au moins 3 cases de mur à démolir, ni coin, ni côté d'enclos.
	var passage := 0
	var nouveau := {}
	for t in _ring(neuf):
		nouveau[t] = true
	for t in _ring(zoo_rect):
		var sur_cote: bool = (cote.x != 0 and t.x == (zoo_rect.position.x if cote.x < 0 else zoo_rect.end.x - 1)) \
			or (cote.y != 0 and t.y == (zoo_rect.position.y if cote.y < 0 else zoo_rect.end.y - 1))
		if sur_cote and not nouveau.has(t) and not fence_tiles.has(t) and g.is_wall(t):
			passage += 1
	if passage < 3:
		return
	out.append({"rect": neuf, "strip": strip, "murs": murs, "montagnes": montagnes})


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
		# Zoo ouvert, trois ouvriers sur quatre tiennent des postes : il faut des bras en plus avant tout le reste.
		if _opt("camp") and g.zoo_status()["open"]:
			camp_max = maxi(camp_max, 2 if g.has_building("camp_n2") and (g.animals.size() >= 3 or not _objectif_ouvert("camp").is_empty()) else 1)
		if lvl - 1 > camp_max or day < 2:
			break
		var cid := "camp_n%d" % lvl
		if lvl == 3 and strat["adaptatif"] and not g.zoo_status()["open"]:
			break  # 70 de bois et de pierre avant le premier animal retardent trop l'ouverture
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
	if target_rect.size != Vector2i.ZERO and not expanded and _walls_progress() >= 1.0 and (day >= 6 or g.animals.size() >= 2 or agrandissements > 0):
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
		and (strat["spectacle"] or roster_kiosque or (day >= 5 and g.money > _floor_achats() + 60.0)):
		var kspot := _park_spot(g.building_def("kiosque"))
		if kspot.x >= 0:
			out.append(["batiment", g.building_def("kiosque"), kspot])
	# 3 quater. Snack : quand l'argent suit, ou pour un objectif des actionnaires.
	var services := not _objectif_ouvert("services").is_empty()
	if _opt("agence") and not g.has_building("snack") and g.zoo_status()["open"] and g.money > _floor_achats() + (15.0 if services else 45.0):
		var sspot := _park_spot(g.building_def("snack"))
		if sspot.x >= 0:
			out.append(["batiment", g.building_def("snack"), sspot])
	if services and not g.has_building("kiosque") and g.zoo_status()["open"] and g.money > _floor_achats() + 15.0:
		var ospot := _park_spot(g.building_def("kiosque"))
		if ospot.x >= 0:
			out.append(["batiment", g.building_def("kiosque"), ospot])
	# 3 quinquies. Agence d'intérim et Cabinet de recrutement, quand ils ont manqué et que l'argent suit.
	for b in [["agence", agence_voulue], ["cabinet", cabinet_voulu]]:
		if b[1] and not g.has_building(b[0]) and g.zoo_status()["open"] and g.money > _floor_achats() + 25.0:
			var bspot := _spot_near_camp(g.building_def(b[0]))
			if bspot.x >= 0:
				out.append(["batiment", g.building_def(b[0]), bspot])
	# 4. Boutique, une fois le premier animal installé.
	if strat["boutique"] and not g.animals.is_empty() and g.site_at(shop_rect.position) == null:
		out.append(["batiment", g.building_def("boutique"), shop_rect.position])
	# 5. Mine d'or si l'IA vise les gros contrats.
	if strat["mine"] and day >= 4 and float(strat["preference_palier"]) >= 1.0 and not g.mine_built 		and (not _opt("mine_apres") or g.zoo_status()["open"]) \
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
			if fence_tiles.has(t):
				continue  # ce mur sert de côté à un enclos : il reste debout
			var s := g.site_at(t)
			if s and s.def_id() == "cloture":
				g.demolish(s)
			reserved.erase(t)
	zoo_rect = target_rect
	expanded = true
	agrandis += 1
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
		if strat["adaptatif"] and str(wnt[1].get("id", "")).begins_with("camp_n"):
			_acheter_manque(wnt[1])
		var placed := g.place(wnt[0], wnt[1], wnt[2])
		if placed != null:
			open += 1
			# Bâtiment de service posé dans le parc : les enclos prévus ensuite l'éviteront.
			if placed.def_id() in ["cuisine", "entretien"]:
				for t in _rect_tiles(placed.rect):
					reserved[t] = true


## Un gros chantier ne se paie jamais avec un stock vidé par les petits : on achète ce qui manque si l'argent suffit.
func _acheter_manque(def: Dictionary) -> void:
	var cout: Dictionary = def.get("cout", {})
	var total := float(cout.get("argent", 0))
	var manque := {}
	for res in ["bois", "pierre"]:
		manque[res] = maxi(0, int(ceil(float(cout.get(res, 0)) - g.stock[res])))
		total += manque[res] * g.buy_price(res)
	if g.money - total < _cash_floor():
		return
	for res in manque:
		if manque[res] > 0:
			g.buy_material(res, manque[res])


## Ressources manquantes pour les prochains chantiers voulus.
func _needs() -> Dictionary:
	var need := {"bois": 0.0, "pierre": 0.0, "or": 0.0}
	if zoo_rect.size == Vector2i.ZERO:
		need["bois"] = 30.0  # rien de prévu encore : l'enceinte demandera surtout de la pierre
		need["pierre"] = 60.0
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
	# Comparaison directe : cette fonction est appelée sans arrêt, fabriquer une clé en texte coûtait cher.
	if _cache_cle.is_empty() or _cache_cle[0] != g.version or _cache_cle[1] != g.phase or _cache_cle[2] != zoo_rect or _cache_cle[3] != target_rect \
		or _cache_cle[4] != entrance or _cache_cle[5] != reserved.size() or _cache_cle[6] != fence_tiles.size():
		_cache_cle = [g.version, g.phase, zoo_rect, target_rect, entrance, reserved.size(), fence_tiles.size()]
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
	if job == "lobbyiste" or job == "journaliste" or w.card.traits.has("col_blanc"):
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
		and (not strat["adaptatif"] or _free_hands() > _builders_needed()) \
		and (not g.campaign.is_empty() or not _campaign_wanted().is_empty()):
		g.order([w], g.map.exit_tile)
		return
	if lobby_today < int(strat["lobbyistes_max"]) and not w.unpaid and g.money > _cash_floor() + float(strat["reserve"]):
		lobby_today += 1
		g.order([w], g.map.exit_tile)
		return
	if strat["formation"] and g.day <= 8 and w.card.niveau < 3 and not w.unpaid and (not strat["adaptatif"] or g.zoo_status()["open"]):
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
	var marge := float(strat["reserve"]) + 20.0
	if strat["rush_or"]:
		marge = 5.0
	elif _opt("marge") and g.zoo_status()["open"]:
		marge = 5.0 + (0.0 if not plans.is_empty() else epargne)  # la recette tombe toute la journée
	var spare := g.money - _cash_floor() - marge
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
			if w.task.get("kind") in ["ticket", "shop", "snack", "kiosque"]:
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
			if g.visitor_queue >= 10 and (_free_hands() > bras or (strat["adaptatif"] and g.visitor_queue >= 15 and _free_hands() >= 1)):
				_ensure_post(s, "ticket", 3 if g.visitor_queue >= 30 else 2)
		elif s.done and s.def_id() == "boutique" and open:
			if _free_hands() > bras:
				_ensure_post(s, "shop")
		elif s.done and s.def_id() == "snack" and open:
			if _free_hands() > bras:
				_ensure_post(s, "snack")
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
	return g.workers.filter(func(w): return not w.offmap and not w.task.get("type") in ["station", "feed", "clean"] and not w.card.metier["id"] in ["lobbyiste", "marchand", "journaliste"]).size()


## Bras à garder aux chantiers : aucun s'il n'y a plus rien à construire.
func _builders_needed() -> int:
	if not g.sites.any(func(s): return not s.done) and not plans.any(func(p): return _plan_left(p) > 0):
		return 0
	return 2 if g.workers.size() >= 4 else 1


## Libère un poste secondaire quand un chantier manque de bras (kiosque, boutique, puis nettoyage).
func _release_posts(bras: int) -> void:
	if _free_hands() >= bras:
		return
	for kind in ["snack", "kiosque", "shop"]:
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
			if w.offmap or w.task.get("type") in ["station", "feed", "clean"] or w.card.metier["id"] in ["lobbyiste", "marchand", "journaliste"]:
				continue
			if w.card.traits.has("col_blanc"):
				continue
			var v := g.efficiency(w.card, "defaut") - 2.0 * g.efficiency(w.card, task) + (3.0 if w.card.metier["id"] == "formateur" else 0.0)
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
		if w.offmap or w.task.get("type") in ["station", "feed", "clean"] or w.card.metier["id"] in ["lobbyiste", "marchand", "journaliste"]:
			continue
		# Les moins utiles ailleurs tiennent les postes (la recette ne dépend que de la présence).
		var v := g.efficiency(w.card, "defaut")
		if w.card.metier["id"] == "formateur":
			v += 3.0  # seul à un poste, il ne forme personne
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
		# Le Formateur rejoint un chantier déjà occupé : c'est là qu'il fait progresser les autres.
		var foule := -6.0 if w.card.metier["id"] == "formateur" else 6.0
		var score := w.pos.distance_to(Vector2(s.rect.get_center())) - (25.0 if strat["specialisation"] else 8.0) * eff + foule * n
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
	if (deficit_b <= 0 and deficit_p <= 0) or (strat["specialisation"] and deficit_b > 0 and deficit_p > 0):
		res = "bois" if g.efficiency(w.card, "extraire_bois") >= g.efficiency(w.card, "extraire_pierre") else "pierre"
	elif strat["specialisation"]:
		res = "bois" if deficit_b > 0 else "pierre"  # un seul manque : même les moins doués s'y mettent, sinon le zoo n'ouvre pas
	else:
		var wb: float = deficit_b * g.efficiency(w.card, "extraire_bois") / 6.0
		var wp: float = deficit_p * g.efficiency(w.card, "extraire_pierre") / 4.0
		res = "bois" if wb >= wp else "pierre"
	# Pas de récolte sous un bâtiment (un ordre sur l'entrée poste l'ouvrier au guichet, zoo fermé compris) ni dans
	# un enclos prévu (une forêt coupée n'est plus une forêt, et le motif de l'animal disparaît).
	var tiles: Array = resource_tiles.get(res, []).filter(func(t): return g.site_at(t) == null and not reserved.has(t))
	if tiles.is_empty():
		return
	# La case la moins occupée parmi les plus proches du camp.
	var best: Vector2i = tiles[0]
	var best_n := 99
	for t in tiles.slice(0, 10):
		var n := g.workers.filter(func(o): return o.task.get("target") == t).size()
		if w.card.metier["id"] == "formateur":
			n = -n  # il récolte près des autres
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
