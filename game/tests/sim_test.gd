extends SceneTree
## Tests de la simulation, sans affichage :
##   godot --headless --path game --script res://tests/sim_test.gd

var failures := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  ÉCHEC ", msg)


func _init() -> void:
	var data := GameData.load_all()

	print("Cartes :")
	for s in [1, 42, 12345, 777, 2026, 99999]:
		var g: GameState = Match.new(data, s, 1, 0).players[0]
		var m := g.map
		var reach := MapGenerator.reachable(m)
		var unreachable := 0
		var water := 0
		for y in m.h:
			for x in m.w:
				if m.passable(x, y) and not reach[m.idx(x, y)]:
					unreachable += 1
				if m.get_t(x, y) == GameMap.EAU:
					water += 1
		var zone_ok := true
		for y in range(m.start_zone.position.y, m.start_zone.end.y):
			for x in range(m.start_zone.position.x, m.start_zone.end.x):
				if m.get_t(x, y) != GameMap.PRAIRIE:
					zone_ok = false
		check(unreachable == 0, "graine %d : tout est atteignable (%d isolées), eau %.0f %%" % [s, unreachable, 100.0 * water / (m.w * m.h)])
		check(zone_ok, "graine %d : zone de départ en prairie" % s)
		check(m.exit_tile.y == m.h - 1 and m.road[m.idx(m.exit_tile.x, m.exit_tile.y)] == 1, "graine %d : accès route au bord bas" % s)
		check(m.golds.size() == 2 and m.golds.all(func(gd): return m.find_path(m.camp.get_center(), gd) != null),
			"graine %d : 2 gisements d'or atteignables" % s)

	print("Draft :")
	# Tirages statistiques sur une seule partie : créer une partie génère une carte (~0,5 s), inutile ici.
	var cats := {"peu_qualifie": 0, "qualifie": 0, "cadre": 0}
	var runs := 200
	var md := Match.new(data, 1000, 1, 0)
	var proba: Dictionary = data["workers"]["generation_draft"]["probabilites"]
	for i in runs * 40:
		cats[md.pick_weighted(proba)] += 1
	print("  moyenne pour 40 cartes révélées (2 joueurs, 10 tours de 4) : %.1f peu qualifiés, %.1f qualifiés, %.1f cadres" % [
		cats["peu_qualifie"] / float(runs), cats["qualifie"] / float(runs), cats["cadre"] / float(runs)])
	var cols := 0
	var col_ok := true
	for i in 3000:
		var c := md.make_card(["peu_qualifie", "qualifie", "cadre"][i % 3])
		if c.traits.has("col_blanc"):
			cols += 1
			col_ok = col_ok and c.metier["categorie"] == "cadre"
	check(col_ok and cols > 0, "Col blanc uniquement chez les cadres (%d tirés)" % cols)
	var mt := Match.new(data, 42, 2, 0)
	var g: GameState = mt.players[0]
	check(mt.draft_pool.size() == 3 and mt.draft_reserve.size() == 21, "3 cartes révélées par tour, 8 tours (2 joueurs)")
	var order := mt.draft_order.slice(0, 4)
	check(order[0] != order[1] and order[2] == order[1], "le premier à choisir tourne (%s)" % str(order))
	mt.pick_draft(mt.ai_choice())
	check(mt.draft_pool.size() == 2 and mt.draft_round() == 0, "un choix retire la carte, le tour continue")
	mt.pick_draft(mt.ai_choice())
	check(mt.draft_round() == 1 and mt.draft_pool.size() == 3, "à 2 joueurs, la carte restante est défaussée")
	while mt.phase == "draft":
		mt.pick_draft(mt.ai_choice())
	check(mt.drafted[0].size() == 8 and mt.drafted[1].size() == 8, "8 cartes chacun")
	# À 4 joueurs : 5 cartes, le dernier choisit encore entre deux, puis le premier change.
	var m4 := Match.new(data, 43, 4, -1)
	var first4 := m4.current_drafter()
	check(m4.draft_pool.size() == 5, "4 joueurs : 5 cartes révélées")
	for k in 3:
		m4.pick_draft(m4.ai_choice())
	check(m4.draft_pool.size() == 2, "4 joueurs : le dernier choisit entre deux cartes")
	m4.pick_draft(m4.ai_choice())
	check(m4.draft_round() == 1 and m4.draft_pool.size() == 5 and m4.drafted.all(func(d): return d.size() == 1),
		"4 joueurs : une carte chacun, la cinquième est défaussée")
	check(m4.current_drafter() == (first4 + 1) % 4, "4 joueurs : le premier à choisir avance d'un joueur")
	while m4.phase == "draft":
		m4.pick_draft(m4.ai_choice())
	check(m4.drafted.all(func(d): return d.size() == 8), "4 joueurs : 8 cartes chacun")
	check(g.phase == "day" and g.hand.size() == 4, "le jour 1 commence avec 4 cartes en main")

	print("Journée :")
	for c in g.hand.duplicate():
		g.deploy(c)
	var manual := g.workers.filter(func(w): return not w.card.traits.has("col_blanc"))
	var lobbyist: GameState.Worker = g.workers[0]
	var forest := _nearest(g.map, GameMap.FORET)
	g.order([lobbyist], g.map.exit_tile)
	for w in manual:
		if w != lobbyist:
			g.order([w], forest)
	for i in 1200:
		g.tick(GameState.TICK)
	check(lobbyist.offmap, "le lobbyiste est sorti par l'accès")
	check(g.influence > 0.0, "influence gagnée : %.2f" % g.influence)
	check(g.stock["bois"] > 0.0, "bois rapporté au camp : %.0f" % g.stock["bois"])
	g.recall(lobbyist)
	check(not lobbyist.offmap and lobbyist.tile() == g.map.exit_tile, "rappelé, il revient par l'accès")
	var road_speed := g.map.move_speed(g.map.exit_tile.x, g.map.exit_tile.y)
	check(is_equal_approx(road_speed, 2.0), "vitesse sur la route x2 (%.1f)" % road_speed)
	for i in 3000:
		g.tick(GameState.TICK)
	check(g.phase == "night", "la nuit tombe après 5 minutes")
	g.start_next_day()
	check(g.day == 2 and g.hand.size() == 4, "jour 2 : nouvelle main")

	print("Effets de zone :")
	var ga := _fresh_day(data, 7)
	for c in ga.hand.duplicate():
		ga.deploy(c)
	var a: GameState.Worker = ga.workers[0]
	var b: GameState.Worker = ga.workers[1]
	ga.workers.assign([a, b])  # seuls ces deux-là, pour ne pas capter les effets des autres
	a.card.metier = ga.building_def("camp")  # métier factice sans effet de zone
	b.card.metier = a.card.metier
	a.card.traits.assign(["charismatique"])
	b.card.traits.assign([])
	b.pos = a.pos + Vector2(2, 0)
	check(is_equal_approx(ga.aura_mult(b), 1.2), "Charismatique à 2 cases : +20 %% (x%.2f)" % ga.aura_mult(b))
	b.pos = a.pos + Vector2(5, 0)
	check(is_equal_approx(ga.aura_mult(b), 1.0), "à 5 cases : aucun bonus")
	check(is_equal_approx(ga.aura_mult(a), 1.0), "pas de bonus pour lui-même")
	a.card.traits.assign(["rabat_joie"])
	b.pos = a.pos + Vector2(1, 0)
	check(is_equal_approx(ga.aura_mult(b), 0.8), "Rabat-joie adjacent : -20 %%")
	b.pos = a.pos + Vector2(3, 0)
	check(is_equal_approx(ga.aura_mult(b), 0.8), "Rabat-joie à 3 cases : -20 %% aussi")

	print("Construction :")
	var gc := _fresh_day(data, 12345)
	gc.stock["bois"] = 100.0
	gc.stock["pierre"] = 100.0
	gc.money = 100.0
	for c in gc.hand.duplicate():
		c.traits.assign(c.traits.filter(func(t): return gc.is_positive(t)))  # 4 ouvriers manuels sans défaut, quel que soit le tirage
		gc.deploy(c)
	var builders := gc.workers.filter(func(w): return not w.card.traits.has("col_blanc"))
	var camp := gc.map.camp
	check(gc.placement_error("batiment", gc.building_def("maison"), camp.position) != "", "refus sur le camp")
	var maison := gc.place("batiment", gc.building_def("maison"), camp.position + Vector2i(-4, 0))
	check(maison != null and is_equal_approx(gc.stock["bois"], 95.0), "maison placée, 5 bois payés")
	var route_tile := Vector2i(camp.position.x + 1, camp.position.y - 1)
	var route := gc.place("batiment", gc.building_def("route"), route_tile)
	var creuser := gc.place("amenagement", gc.amenagement_defs()[2], camp.position + Vector2i(-3, -4))
	gc.order(builders.slice(0, 2), maison.rect.position)
	gc.order([builders[2]], route_tile)
	# Seuls les Paysagistes et Terrassiers aménagent : on en fait un pour ce test.
	builders[3].card.metier = data["workers"]["metiers"].filter(func(mt): return mt["id"] == "paysagiste")[0]
	gc.order([builders[3]], creuser.rect.position)
	for i in 1500:
		gc.tick(GameState.TICK)
	check(maison.done and gc.housing() == 9, "maison terminée : logement %d" % gc.housing())
	check(route.done and gc.map.road[gc.map.idx(route_tile.x, route_tile.y)] == 1, "route terminée")
	var cp := creuser.rect.position
	check(gc.map.get_t(cp.x, cp.y) == GameMap.EAU and not gc.sites.has(creuser), "bassin creusé : la case devient de l'eau")
	check(builders.all(func(w): return gc.map.passable(w.tile().x, w.tile().y)), "aucun ouvrier coincé dans l'eau")
	var pont := gc.place("batiment", gc.building_def("pont"), cp)
	check(pont != null, "pont placé sur le bassin")
	gc.order([builders[3]], cp)
	for i in 600:
		gc.tick(GameState.TICK)
	check(pont.done and gc.map.passable(cp.x, cp.y), "pont terminé : l'eau devient franchissable")
	var bois_avant: float = gc.stock["bois"]
	var cancel := gc.place("batiment", gc.building_def("entrepot"), camp.position + Vector2i(4, 0))
	check(cancel != null and gc.stock["bois"] < bois_avant, "entrepôt placé")
	gc.cancel_site(cancel)
	check(is_equal_approx(gc.stock["bois"], bois_avant) and not gc.sites.has(cancel), "chantier annulé sans travail : remboursé")

	print("Mine d'or :")
	var gm := _fresh_day(data, 42)
	gm.stock["bois"] = 50.0
	gm.stock["pierre"] = 50.0
	for c in gm.hand.duplicate():
		gm.deploy(c)
	var miners := gm.workers.filter(func(w): return not w.card.traits.has("col_blanc"))
	gm.order([miners[0]], gm.map.golds[1])
	check(miners[0].task.is_empty(), "or refusé tant que la mine n'existe pas")
	var mine: GameState.Site = null
	for dy in [-1, 0]:
		for dx in [-1, 0]:
			if mine == null:
				mine = gm.place("batiment", gm.building_def("mine"), gm.map.gold + Vector2i(dx, dy))
	check(mine != null, "mine placée sur le gisement")
	if mine:
		mine.work = mine.travail() - 0.5
		gm.order(miners, gm.map.gold)
		for i in 400:
			gm.tick(GameState.TICK)
		check(gm.mine_built, "mine terminée")
		gm.order(miners, gm.map.gold)
		for i in 1600:
			gm.tick(GameState.TICK)
		var gold_carried := 0.0
		for w in miners:
			if w.carry_type == "or":
				gold_carried += w.carry
		check(gm.stock["or"] + gold_carried > 0.0, "or extrait : %.1f au camp, %.1f en charge" % [gm.stock["or"], gold_carried])

	print("Marché et contrats :")
	var gk := _fresh_day(data, 12345)
	gk.sans_enceinte = true  # ces tests d'enclos se passent hors de toute enceinte
	check(gk.market_workers.size() == 5 and gk.market_contracts.size() == 5, "marché ouvert : 5 ouvriers, 5 contrats")
	var gk_ids := {}
	for d in gk.market_contracts:
		gk_ids[d["id"]] = true
	check(gk_ids.size() == 5, "marché : 5 espèces différentes")
	# Une espèce par partie : achetée, elle ne revient plus, même après plusieurs renouvellements
	var gk_pris: Dictionary = gk.market_contracts[0]
	gk.market_contracts.erase(gk_pris)
	gk.contracts.append(gk_pris)
	var gk_revenu := false
	for gk_k in 30:
		gk.mt._refresh_market(gk.mt.day, false)
		gk_revenu = gk_revenu or gk.market_contracts.has(gk_pris)
		gk.market_contracts.pop_back()
	gk.mt._refresh_market(gk.mt.day, false)
	gk.contracts.erase(gk_pris)
	check(not gk_revenu and gk.market_contracts.size() == 5, "espèce achetée : ne revient jamais au marché")
	gk.stock["bois"] = 20.0
	gk.stock["pierre"] = 10.0
	var house := gk.place("batiment", gk.building_def("maison"), gk.map.camp.position + Vector2i(3, 0))
	gk.end_day()
	check(gk.night_order.size() == 2, "ordre de passage fixé (%s)" % str(gk.night_order))
	gk.money = 100.0
	check(gk.hire_error(gk.market_workers[0]) != "", "logement plein (10/10) : embauche refusée sans maison")
	house.work = house.travail()
	gk._complete(house)
	check(gk.mt.night_stage == "contrats", "la nuit commence par l'étape Contrats")
	gk.mt.night_goto("contrats")
	check(gk.hire_error(gk.market_workers[0]).begins_with("Embauche à l'étape"), "pas d'embauche pendant l'étape Contrats")
	var zebre: Dictionary = data["animals"]["animaux"].filter(func(d): return d["id"] == "zebre")[0]
	var lion: Dictionary = data["animals"]["animaux"].filter(func(d): return d["id"] == "lion")[0]
	gk.market_contracts.append(zebre)
	check(gk.buy_contract(zebre) and gk.contracts.has(zebre), "contrat Zèbre acheté")
	var second: Dictionary = gk.market_contracts[0]
	var base_price := int(second["cout"].get("argent", 0))
	var expected := roundi(base_price * (1.0 + 0.15 * 1) * 1.5 * (1.0 - gk.remise_relance()))
	check(absi(int(gk.contract_cost(second).get("argent", 0)) - expected) <= 1, "2e contrat : prix x1,15 (1 animal) x1,5 (2e de la nuit) = %d (base %d, obtenu %d, %s, relance %.2f)" % [expected, base_price, int(gk.contract_cost(second).get("argent", 0)), second["id"], gk.remise_relance()])
	check(gk.contract_error(second) != "", "un seul contrat par tour : le tour est passé")
	check(gk.mt.night_taken.filter(func(t): return t["joueur"] == gk.index).size() == 1, "achats de la nuit visibles de tous")
	gk.contracts.erase(second)
	gk.mt.night_goto("ouvriers")
	check(gk.mt.night_stage == "ouvriers" and gk.mt.current_buyer() == gk.index, "étape Ouvriers : à votre tour")
	var before := gk.employees()
	var recrue: GameState.Card = gk.market_workers[0]
	var prix := gk.hire_cost(recrue)
	check(gk.hire(recrue) and gk.employees() == before + 1 and gk.discard.has(recrue), "embauche : la recrue va dans la défausse (%d argent)" % prix)
	check(not gk.hire(gk.market_workers[0]), "une seule embauche par nuit")
	gk.mt.night_goto("equipe")
	check(gk.mt.night_stage == "equipe", "dernière étape : Équipe")
	gk.drh_available = 1
	var licencie: GameState.Card = gk.all_employees()[0]
	check(gk.fire(licencie) and not gk.all_employees().has(licencie), "licenciement par le DRH")
	gk.start_next_day()
	check(gk.day == 2 and gk.market_workers.size() == 5, "jour 2 : marché complété")

	print("Enclos et réputation :")
	var cx := gk.map.w / 2
	var y0 := gk.map.h - 9
	var interior := Vector2i(cx - 4, y0 + 1)
	gk.stock["bois"] = 50.0
	# Terrain de l'enclos préparé pour le motif du Zèbre (PPP / P.S)
	for yy in range(y0 + 1, y0 + 3):
		for xx in range(cx - 5, cx - 2):
			gk.map.set_t(xx, yy, GameMap.SABLE if (xx == cx - 3 and yy == y0 + 2) else GameMap.PRAIRIE)
			gk._terrain_updated(Vector2i(xx, yy))
	var fences: Array = []
	for y in range(y0, y0 + 4):
		for x in range(cx - 6, cx - 1):
			if x == cx - 6 or x == cx - 2 or y == y0 or y == y0 + 3:
				fences.append(gk.place("batiment", gk.building_def("enclos"), Vector2i(x, y)))
	check(fences.all(func(f): return f != null), "%d clôtures d'enclos placées" % fences.size())
	check(gk.install_animal(zebre, interior) == "" and gk.pending_installs.size() == 1 and gk.animals.is_empty(),
		"clôtures en chantier : le Zèbre est réservé, pas encore installé")
	for f in fences:
		f.work = f.travail()
		gk._complete(f)
	var enc := gk.enclosure_at(interior)
	check(enc["closed"] and enc["tiles"].size() == 6, "enclos fermé de 6 cases")
	check(gk.animal_error(lion, enc) != "", "Lion refusé : %s" % gk.animal_error(lion, enc))
	gk.sans_enceinte = false
	check(gk.animal_error(zebre, enc) == "Terminez d'abord l'enceinte du zoo (entrée comprise)", "pas d'animal avant que l'enceinte soit fermée")
	gk.sans_enceinte = true
	check(gk.animals.size() == 1 and gk.pending_installs.is_empty() and gk.contracts.is_empty(), "clôtures terminées : le Zèbre s'installe")
	check(gk.attractiveness() == 0, "pas d'attractivité avant l'arrivée")
	gk.end_day()
	check(gk.attractiveness() == 4, "le Zèbre arrive la nuit : attractivité %d" % gk.attractiveness())
	gk.money = 0.0
	var gk_proba = data["events"]["proba_evenement"]
	data["events"]["proba_evenement"] = 0.0  # un événement (subvention, épidémie) fausserait l'argent ou l'attractivité
	gk.start_next_day()
	data["events"]["proba_evenement"] = gk_proba
	check(not gk.food_due() and gk.attractiveness() == 4 and is_equal_approx(gk.money, 0.0),
		"zoo pas encore ouvert : nourriture offerte, même sans argent")

	print("Zoo et revenus :")
	var gz := _fresh_day(data, 2026)
	check(not gz.zoo_status()["open"], "pas d'entrée : zoo fermé (%s)" % gz.zoo_status()["reason"])
	gz.debug_build_zoo(Vector2i(4, 4))
	var zs := gz.zoo_status()
	check(zs["interior"].size() == 7 * 6, "enceinte fermée : %d cases à l'intérieur" % zs["interior"].size())
	check(not zs["open"], "zoo fermé tant que le Zèbre n'est pas arrivé")
	check(not gz.visitor_path().is_empty(), "une route relie l'Accès à l'Entrée")
	gz.end_day()
	gz.start_next_day()
	gz.mt.current_event = {}  # pas d'événement aléatoire pendant ce test
	for an in gz.animals:
		an.sick = false
	var live := gz.zoo_live()
	check(live["open"] and live["attract"] == 4, "le Zèbre est arrivé : zoo ouvert, attractivité %d" % live["attract"])
	for i in 1500:
		gz.tick(GameState.TICK)
	check(gz.visitor_queue > 0 and gz.visit["admitted"] == 0, "personne au guichet : %d visiteurs attendent, aucun n'entre" % gz.visitor_queue)
	var money_mid := gz.money
	var clerk: GameState.Card = gz.hand[0]
	clerk.traits.clear()  # un Lent ou un Distrait tiré au hasard n'atteindrait pas le guichet à temps
	gz.deploy(clerk, true)
	var entree: GameState.Site = gz.sites.filter(func(s): return s.def_id() == "entree")[0]
	gz.order([gz.worker_of(clerk)], entree.rect.position)
	for i in 1300:
		gz.tick(GameState.TICK)
	var admitted: int = gz.visit["admitted"]
	check(admitted > 0 and is_equal_approx(gz.visit["tickets"], admitted * float(data["buildings"]["zoo"]["billet"])), "guichet tenu : %d visiteurs entrés, billets %d" % [admitted, int(gz.visit["tickets"])])
	check(gz.money > money_mid, "les billets sont encaissés pendant la journée")
	gz.end_day()
	var inc: Dictionary = gz.night_report["income"]
	var rep_coef := float(data["buildings"]["zoo"]["reputation_par_visiteur_moyen"])
	check(gz.rep_points > 0.0 and is_equal_approx(gz.rep_points, inc["avg_present"] * rep_coef), "réputation gagnée selon la fréquentation moyenne : +%.2f" % gz.rep_points)
	gz.cared_today[gz.animals[0]] = true
	check(gz.attractiveness() == 6, "Soigneur : +2 d'attractivité")
	gz.influence = 15.0
	check(is_equal_approx(gz.publicity_mult(), 1.0), "l'influence n'attire plus de visiteurs")
	gz.publicite = 8.0
	check(is_equal_approx(gz.publicity_mult(), 1.5), "publicité : 8 points de campagnes -> +50 %% de visiteurs")
	# Ouvrir une brèche dans l'enceinte ferme le zoo
	var wall: GameState.Site = gz.site_at(Vector2i(6, 4))  # milieu du mur du haut (un coin ne laisse rien passer)
	gz._remove_site(wall)
	check(not gz.zoo_status()["open"], "brèche dans l'enceinte : zoo fermé")

	print("Visiteurs : capacité, arrivées, durée :")
	var gvz := _fresh_day(data, 2027)
	gvz.debug_build_zoo(Vector2i(4, 4))
	gvz.end_day()
	gvz.start_next_day()
	gvz.mt.current_event = {}
	for an in gvz.animals:
		an.sick = false
	var Zd: Dictionary = data["buildings"]["zoo"]
	var cap := gvz.visitor_capacity()
	check(cap > 0 and cap == int(gvz.zoo_status()["interior"].size() / float(Zd["cases_par_visiteur"])),
		"capacité = cases intérieures / %d : %d visiteurs" % [int(Zd["cases_par_visiteur"]), cap])
	var dl := gvz.day_length
	var somme := 0.0
	for i in 300:
		somme += gvz.arrival_factor((i + 0.5) / 300.0 * dl)
	check(absf(somme / 300.0 - 1.0) < 0.02, "courbe d'arrivées normalisée (moyenne %.2f)" % (somme / 300.0))
	check(gvz.arrival_factor(dl * 0.5) > gvz.arrival_factor(dl * 0.02) and gvz.arrival_factor(dl - 10.0) == 0.0,
		"pic en milieu de journée, plus d'arrivées juste avant la fermeture")
	var guichetier: GameState.Card = gvz.hand[0]
	gvz.deploy(guichetier, true)
	var entree2: GameState.Site = gvz.sites.filter(func(s): return s.def_id() == "entree")[0]
	var gw := gvz.worker_of(guichetier)
	gvz.order([gw], entree2.rect.position)
	for i in 3000:
		gvz.tick(GameState.TICK)
		if gvz.guichet_rate() > 0.0:
			break
	check(gvz.guichet_rate() > 0.0, "guichetier à son poste")
	var durees_ok := gvz.in_zoo.all(func(v): return v["t"] <= float(Zd["duree_visite_s"]) + float(Zd["duree_visite_ecart_s"]))
	check(durees_ok, "durées de visite au plus %d s" % int(float(Zd["duree_visite_s"]) + float(Zd["duree_visite_ecart_s"])))
	gvz.in_zoo.clear()
	for i in cap:
		gvz.in_zoo.append({"t": 9999.0, "pos": Vector2.ZERO})
	gvz.visitor_queue = 10
	var adm0: int = gvz.visit["admitted"]
	for i in 300:
		gvz.tick(GameState.TICK)
	check(gvz.visit["admitted"] == adm0 and gvz.visitor_queue > 0, "parc plein : la file attend (%d), personne n'entre" % gvz.visitor_queue)
	gvz.in_zoo.clear()
	for i in 300:
		gvz.tick(GameState.TICK)
	check(gvz.visit["admitted"] > adm0, "places libérées : %d visiteurs entrent" % (gvz.visit["admitted"] - adm0))

	print("Vente du stock :")
	var gv := _fresh_day(data, 5)
	gv.stock["bois"] = 10.0
	gv.stock["pierre"] = 10.0
	gv.stock["or"] = 2.0
	var m0 := gv.money
	gv.sell_stock()
	check(is_equal_approx(gv.money - m0, 6.5) and is_equal_approx(gv.stock["or"], 2.0), "sans Marchand : moitié prix (+%.1f, sans arrondi), l'or est gardé" % (gv.money - m0))

	print("Nouvelles règles :")
	var gf := _fresh_day(data, 77)
	check(is_equal_approx(gf.stock["bois"], 15.0) and is_equal_approx(gf.stock["pierre"], 15.0), "stock de départ : 15 bois, 15 pierre")
	gf.money = 0.0
	var paid_hand := gf.hand.filter(func(c): return gf.salary(c) > 0)  # un Économe peut avoir un salaire nul
	var c0: GameState.Card = paid_hand[0]
	var c1: GameState.Card = paid_hand[1]
	check(not gf.deploy(c0), "sans argent, déploiement normal refusé")
	check(gf.deploy(c0, true), "déploiement gratuit accepté")
	check(not gf.deploy(c1, true), "un seul déploiement gratuit par jour")
	var wf := gf.worker_of(c0)
	check(is_equal_approx(gf.efficiency_at(wf, "extraire_bois"), gf.efficiency(c0, "extraire_bois") * gf.aura_mult(wf) * 0.25), "rendement de l'ouvrier gratuit : 25 %")
	var base_sal := gf.salary(c1)
	c1.niveau = 3
	check(gf.salary(c1) == base_sal + 2, "salaire +1 par niveau (%d -> %d)" % [base_sal, gf.salary(c1)])

	print("Ressources, enceinte, or :")
	var gr := _fresh_day(data, 404)
	for c in gr.hand.duplicate():
		gr.deploy(c)
	var foret_t := _nearest(gr.map, GameMap.FORET)
	var stock0: float = gr.map.res_left[gr.map.idx(foret_t.x, foret_t.y)]
	check(is_equal_approx(stock0, 25.0), "une forêt contient 25 bois")
	var lumber := gr.workers.filter(func(w): return not w.card.traits.has("col_blanc"))
	gr.order(lumber, foret_t)
	for i in 2000:
		gr.tick(GameState.TICK)
	check(gr.map.get_t(foret_t.x, foret_t.y) == GameMap.PRAIRIE, "forêt épuisée : elle devient une prairie")
	check(gr.stock["bois"] > 25.0 + 15.0 - 1.0, "les bûcherons continuent sur la forêt voisine (bois %d)" % int(gr.stock["bois"]))
	var gz2 := _fresh_day(data, 2026)
	gz2.debug_build_zoo(Vector2i(4, 4))
	gz2.stock["bois"] = 50.0
	gz2.stock["pierre"] = 50.0
	check(gz2.placement_error("batiment", gz2.building_def("entrepot"), Vector2i(6, 9)) == "Interdit dans l'enceinte du zoo", "entrepôt interdit dans l'enceinte")
	check(gz2.placement_error("batiment", gz2.building_def("maison"), Vector2i(6, 9)) == "", "une maison reste possible dans l'enceinte")
	check(gz2.sell_price("or") > 6.0 * gz2.sell_price("bois"), "l'or se vend bien plus cher que le bois (%.1f contre %.1f)" % [gz2.sell_price("or"), gz2.sell_price("bois")])
	var tigre: Dictionary = data["animals"]["animaux"].filter(func(d): return d["id"] == "tigre")[0]
	check(tigre["motif"].size() == 12 and tigre.get("decor", "") == "bassin_profond", "Tigre : motif de 12 cases et bassin profond")

	print("Motifs, aménagement, démolition :")
	var gp := _fresh_day(data, 321)
	# Motif du Tigre posé à la main, tourné d'un quart de tour, dans une zone de 4x4
	var zone: Array[Vector2i] = []
	var o := Vector2i(10, 10)
	for y in 4:
		for x in 4:
			zone.append(o + Vector2i(x, y))
			gp.map.set_t(o.x + x, o.y + y, GameMap.PRAIRIE)
	var turned: Array = gp.pattern_variants(tigre)[2]
	for c in turned:
		gp.map.set_t(o.x + int(c[0]), o.y + int(c[1]), GameMap.TERRAINS.find(str(c[2])))
	check(gp.pattern_variants(tigre).size() == 8, "8 orientations du motif (rotations et miroirs)")
	check(gp.pattern_status(tigre, zone)["found"], "motif tourné reconnu dans la zone")
	gp.map.set_t(o.x + int(turned[0][0]), o.y + int(turned[0][1]), GameMap.MONTAGNE)
	check(not gp.pattern_status(tigre, zone)["found"] and gp.pattern_status(tigre, zone)["missing"] >= 1, "une case modifiée : motif absent")
	gp.stock["bois"] = 50.0
	gp.stock["pierre"] = 50.0
	for c in gp.hand.duplicate():
		gp.deploy(c)
	var spot := gp.map.camp.position + Vector2i(-3, -1)
	var amen := gp.place("amenagement", gp.amenagement_defs()[2], spot)
	var non_land := gp.workers.filter(func(w): return not gp.can_landscape(w.card) and not w.card.traits.has("col_blanc"))
	if amen and not non_land.is_empty():
		gp.order([non_land[0]], spot)
		check(non_land[0].task.is_empty(), "un %s ne peut pas aménager le terrain" % non_land[0].card.metier["nom"])
	var road := gp.place("batiment", gp.building_def("route"), gp.map.camp.position + Vector2i(4, 0))
	road.work = road.travail()
	gp._complete(road)
	var rp := road.rect.position
	check(gp.demolish(road) and gp.map.road[gp.map.idx(rp.x, rp.y)] == 0 and gp.site_at(rp) == null, "route démolie")

	var m_before := gz2.money
	var b_before: float = gz2.stock["bois"]
	check(gz2.buy_material("bois", 10) and is_equal_approx(gz2.money, m_before - 10.0) and is_equal_approx(gz2.stock["bois"], b_before + 10.0),
		"achat de 10 bois pour 10 (double du prix de revente)")

	print("Nuit : bonus, amélioration, licenciement :")
	var mn := Match.new(data, 99, 2, 0)
	mn.advance_ai_draft()
	while mn.phase == "draft":
		mn.pick_draft(mn.ai_choice())
	var me: GameState = mn.players[0]
	mn.end_day()
	check(mn.bonus_offer.size() == 3, "3 bonus proposés")
	var leader := mn.influence_leader()
	check(me.bonus_error(mn.bonus_offer[0]) != "", "pas de bonus avant l'étape Bonus")
	mn.night_goto("bonus")
	check(mn.players[1 - leader].bonus_error(mn.bonus_offer[0]) != "", "seul le premier en influence choisit le bonus")
	var chosen_bonus: Dictionary = mn.bonus_choice
	if leader == 0:
		check(me.pick_bonus(mn.bonus_offer[1]), "vous êtes premier : bonus choisi (%s)" % mn.bonus_offer[1]["nom"])
		chosen_bonus = mn.bonus_offer[1]
	else:
		check(not chosen_bonus.is_empty(), "l'IA, première en influence, a choisi : %s" % chosen_bonus.get("nom", "?"))
	mn.night_goto("equipe")
	check(me.night_action_error(12) != "", "pas d'amélioration avant le milieu de partie (%s)" % me.night_action_error(12))
	mn.start_next_day()
	check(me.day_bonus == chosen_bonus and mn.players[1].day_bonus == chosen_bonus, "le bonus choisi s'applique à tous le lendemain")
	while mn.day < 7:
		mn.end_day()
		mn.start_next_day()
	mn.end_day()
	me.money = 100.0
	check(me.night_action_error(12) != "", "pas d'amélioration pendant les marchés")
	mn.night_goto("equipe")
	var target: GameState.Card = me.all_employees()[0]
	var opts := me.upgrade_options(target)
	check(opts.size() >= 2, "améliorations proposées (%d)" % opts.size())
	var eff_before := me.efficiency(target, "extraire_bois")
	var eff_opt: Dictionary = {"id": "plus_efficace", "nom": "Expérience", "effet": {"defaut": 1.15}}
	check(me.apply_upgrade(target, eff_opt) and is_equal_approx(me.efficiency(target, "extraire_bois"), eff_before * 1.15), "amélioration payée (12) et appliquée")
	check(not me.fire_paid(me.all_employees()[1]), "une seule action par nuit")

	print("Lot B : expérience, formation, capacités :")
	var b_g := _fresh_day(data, 4242)
	b_g.mt.current_event = {}
	var b_W: Dictionary = data["workers"]
	var b_mk := func(metier_id: String, traits: Array) -> GameState.Card:
		var c := GameState.Card.new()
		c.nom = "Test " + metier_id
		c.metier = b_W["metiers"].filter(func(mm): return mm["id"] == metier_id)[0]
		c.traits.assign(traits)
		return c
	var b_appr: GameState.Card = b_mk.call("apprenti", [])
	b_g.gain_xp(b_appr, 1.0)
	check(is_equal_approx(b_appr.xp, 1.7), "Apprenti : expérience ×1,7 (%.1f jour pour 1 jour travaillé)" % b_appr.xp)
	var b_eleve: GameState.Card = b_mk.call("manoeuvre", ["bon_eleve"])
	b_g.gain_xp(b_eleve, 1.0)
	check(is_equal_approx(b_eleve.xp, 2.0), "Bon élève : expérience ×2")
	check(b_g._upgrade_pool(b_mk.call("manoeuvre", ["tetu"])).size() == 2, "Têtu : 2 améliorations au choix au lieu de 3")
	# Montée de niveau : une amélioration gratuite au choix
	var b_lc: GameState.Card = b_g.hand[0]
	b_g.deploy(b_lc, true)
	b_lc.xp = 1.9  # un jour de travail suffit, même à −15 % (Têtu)
	var b_niv0 := b_lc.niveau
	b_g.end_day()
	var b_nopt := 2 if b_lc.traits.has("tetu") else 3
	check(b_lc.niveau == b_niv0 + 1 and b_g.level_choices.size() == 1 and b_g.level_choices[0]["options"].size() == b_nopt,
		"montée de niveau : %d améliorations au choix" % b_nopt)
	var b_opt: Dictionary = b_g.level_choices[0]["options"][0]
	var b_nup := b_lc.upgrade_names.size()
	var b_money := b_g.money
	check(b_g.choose_level_upgrade(b_lc, b_opt) and b_g.level_choices.is_empty() and b_lc.upgrade_names.size() == b_nup + 1 \
		and is_equal_approx(b_g.money, b_money), "amélioration de niveau choisie gratuitement : %s" % b_opt["nom"])
	var b_proba = data["events"]["proba_evenement"]
	data["events"]["proba_evenement"] = 0.0
	b_g.start_next_day()
	data["events"]["proba_evenement"] = b_proba
	b_g.stock["bois"] += 60.0
	b_g.stock["pierre"] += 60.0
	b_g.money += 80.0
	var b_o := Vector2i(b_g.map.camp.position.x - 5, b_g.map.camp.position.y)
	var b_form: GameState.Card = b_mk.call("formateur", [])
	b_g.deploy(b_form)
	# Apprentissage sur le tas : du temps cumulé à 3 cases ou moins du Formateur, rien plus loin
	var b_pres: GameState.Card = b_mk.call("macon", [])
	var b_loin: GameState.Card = b_mk.call("macon", [])
	b_g.deploy(b_pres)
	b_g.deploy(b_loin)
	var b_wf: GameState.Worker = b_g.worker_of(b_form)
	b_g.worker_of(b_pres).pos = b_wf.pos + Vector2(2, 0)
	b_g.worker_of(b_loin).pos = b_wf.pos + Vector2(8, 0)
	for i in 60:
		b_g.tick(GameState.TICK)
	check(b_g.worker_of(b_pres).temps_mentor > 0.0 and is_zero_approx(b_g.worker_of(b_loin).temps_mentor), "Formateur : du temps d'apprentissage seulement à 3 cases ou moins")
	check(b_g.mentor_rayon(b_form) == 3.0 and b_g.mentor_rayon(b_pres) == 0.0, "Formateur : rayon de 3 cases")
	# Architecte mobilisé : -33 % sur tous les nouveaux chantiers, même là où il ne travaille pas ; col blanc : il ne construit pas
	var b_route_def: Dictionary = b_g.building_def("route")
	check(is_equal_approx(float(b_g.cout_chantier(b_route_def)["pierre"]), 1.0), "sans Architecte : route à 1 pierre")
	var b_arch: GameState.Card = b_mk.call("architecte", ["col_blanc"])
	b_g.deploy(b_arch)
	check(is_equal_approx(float(b_g.cout_chantier(b_route_def)["pierre"]), 0.67), "Architecte mobilisé : route à 0,67 pierre")
	var b_bois_av: float = b_g.stock["bois"]
	var b_maison := b_g.place("batiment", b_g.building_def("maison"), b_o + Vector2i(0, 3))
	check(b_maison != null, "maison placée")
	var b_prix_maison := float(b_g.building_def("maison")["cout"]["bois"])
	check(is_equal_approx(b_bois_av - b_g.stock["bois"], snappedf(b_prix_maison * 0.67, 0.01)), "Architecte : maison payée %.2f bois au lieu de %d" % [b_bois_av - b_g.stock["bois"], int(b_prix_maison)])
	b_g.order([b_g.worker_of(b_arch)], b_maison.rect.position)
	for i in 300:
		b_g.tick(GameState.TICK)
	check(is_zero_approx(b_maison.work), "Architecte col blanc : il ne construit pas de ses mains")
	# Débrouillard : 40 % des ressources payées remboursées à la fin, sans arrondi
	var b_debr: GameState.Card = b_mk.call("manoeuvre", ["debrouillard"])
	b_maison.savings = b_g.resource_mult(b_debr)
	var b_bois0: float = b_g.stock["bois"]
	b_maison.work = b_maison.travail()
	b_g._complete(b_maison)
	var b_refund: float = b_g.stock["bois"] - b_bois0
	check(is_equal_approx(b_refund, snappedf(float(b_maison.paid["bois"]) * 0.4, 0.01)), "Débrouillard : 40 %% du bois remboursé (+%.2f)" % b_refund)
	# Matinal, Peureux
	var b_mat: GameState.Card = b_mk.call("manoeuvre", ["matinal"])
	b_mat.last_work_tile = b_o + Vector2i(0, 3)
	b_g.deploy(b_mat)
	check(b_g.worker_of(b_mat).tile() == b_mat.last_work_tile, "Matinal : commence sur sa dernière case de travail")
	var b_pred: Dictionary = data["animals"]["animaux"].filter(func(d): return d.get("special", "") == "predateur")[0]
	var b_fauve := GameState.Animal.new()
	b_fauve.def = b_pred
	b_fauve.tiles.assign([Vector2i(10, 10)])
	b_g.animals.append(b_fauve)
	check(not b_g.near_predator(Vector2i(12, 11)), "Peureux : un prédateur pas encore arrivé ne fait pas peur")
	b_fauve.arrived = true
	check(b_g.near_predator(Vector2i(12, 11)) and not b_g.near_predator(Vector2i(13, 10)), "Peureux : un prédateur à 2 cases ou moins")
	b_g.animals.erase(b_fauve)
	# Améliorations de métier et seconde spécialité
	var b_port: GameState.Card = b_mk.call("porteur", [])
	var b_cap0 := b_g.carry_capacity(b_port)
	b_port.upgrades.append(b_W["ameliorations_metier"]["porteur"][0]["effet"])
	check(b_g.carry_capacity(b_port) == b_cap0 + 2, "Brouette : portage +2")
	var b_spe: GameState.Card = b_mk.call("manoeuvre", [])
	b_spe.upgrades.append({"seconde_specialite": "construire_bois"})
	check(is_equal_approx(b_g.efficiency(b_spe, "construire_bois"), 1.4), "Seconde spécialité : efficacité 1,4")
	var b_charp: GameState.Card = b_mk.call("charpentier", [])
	var b_drh: GameState.Card = b_mk.call("drh", [])
	b_g.deck.append(b_drh)
	var b_cost0 := b_g.hire_cost(b_charp)
	b_drh.upgrades.append({"capacite": "chasseur_tetes"})
	check(b_g.hire_cost(b_charp) == b_cost0 - 3, "Chasseur de têtes : embauche 3 moins chère (%d → %d)" % [b_cost0, b_g.hire_cost(b_charp)])
	b_g.deck.erase(b_drh)

	print("Lot C : nourrissage, propreté, snack, kiosque :")
	var c_proba = data["events"]["proba_evenement"]
	data["events"]["proba_evenement"] = 0.0  # pas d'événement : argent et rations prévisibles
	var c_g := _fresh_day(data, 2027)
	c_g.debug_build_zoo(Vector2i(4, 4))
	c_g.end_day()
	c_g.start_next_day()
	check(c_g.food_due(), "zoo ouvert : les animaux dépendent de la Cuisine")
	var c_a: GameState.Animal = c_g.animals[0]
	check(is_equal_approx(c_a.food, c_g.food_capacity(c_a.def)), "l'animal arrive avec une journée de rations (%.0f)" % c_a.food)
	c_a.food = 0.05
	for i in 100:
		c_g.tick(GameState.TICK)
	check(not c_a.fed and c_g.attractiveness() == 0, "réserve vide : l'animal a faim et ne compte plus")
	c_g.stock["bois"] += 60.0
	c_g.stock["pierre"] += 60.0
	c_g.money += 80.0
	var c_o := Vector2i(c_g.map.camp.position.x - 5, c_g.map.camp.position.y)
	var c_cuisine := c_g.place("batiment", c_g.building_def("cuisine"), c_o)
	check(c_cuisine != null, "Cuisine des animaux placée")
	c_cuisine.work = c_cuisine.travail()
	c_g._complete(c_cuisine)
	var c_feeder: GameState.Card = c_g.hand[0]
	c_g.deploy(c_feeder)
	c_g.order([c_g.worker_of(c_feeder)], c_cuisine.rect.position)
	var c_m0 := c_g.money
	for i in 2400:
		c_g.tick(GameState.TICK)
		if c_a.food > 1.0:
			break
	check(c_a.fed and c_a.food > 1.0, "nourrisseur : rations préparées à la cuisine puis livrées (réserve %.1f)" % c_a.food)
	check(c_g.money < c_m0, "les rations se paient à la préparation (%d dépensés)" % int(c_m0 - c_g.money))
	# Propreté et entretien (nouvelle journée)
	c_g.end_day()
	c_g.start_next_day()
	c_g.proprete = 40.0
	check(is_equal_approx(c_g.cleanliness_mult(), 0.85), "propreté 40 : visiteurs ×0,85")
	var c_ent := c_g.place("batiment", c_g.building_def("entretien"), c_o + Vector2i(0, 3))
	check(c_ent != null, "Local d'entretien placé")
	c_ent.work = c_ent.travail()
	c_g._complete(c_ent)
	var c_cleaner: GameState.Card = c_g.hand[0]
	c_g.deploy(c_cleaner)
	c_g.order([c_g.worker_of(c_cleaner)], c_ent.rect.position)
	for i in 1500:
		c_g.tick(GameState.TICK)
	check(c_g.proprete > 45.0, "agent d'entretien : le parc redevient propre (%d)" % roundi(c_g.proprete))
	# Kiosque et snack : un ouvrier tient le poste dans l'enceinte
	var c_in: Vector2i = c_g.zoo_status()["interior"].keys()[0]
	var c_kiosque := GameState.Site.new()
	c_kiosque.def = c_g.building_def("kiosque")
	c_kiosque.rect = Rect2i(c_in, Vector2i(2, 2))
	var c_anim: GameState.Card = b_mk.call("animateur", [])
	c_g.deploy(c_anim)
	var c_aw := c_g.worker_of(c_anim)
	c_aw.pos = Vector2(c_in) + Vector2(0.5, 0.5)
	c_aw.path.clear()
	c_aw.task = {"type": "station", "kind": "kiosque", "obj": c_kiosque, "tile": c_in}
	check(c_g.kiosque_bonus() == 6, "Kiosque tenu par un Animateur : +6 d'attractivité")
	var c_snack := GameState.Site.new()
	c_snack.def = c_g.building_def("snack")
	c_snack.rect = Rect2i(c_in, Vector2i(2, 2))
	c_aw.task = {"type": "station", "kind": "snack", "obj": c_snack, "tile": c_in}
	check(is_equal_approx(c_g.snack_mult(), 1.5), "Snack tenu : visites 50 % plus longues")
	# Intendance : le poste fait paraître des décorations, qui coûtent des matériaux et rapportent de la réputation
	var c_int := GameState.Site.new()
	c_int.def = c_g.building_def("intendance")
	c_int.rect = Rect2i(c_in, Vector2i(2, 2))
	c_int.done = true
	c_g.sites.append(c_int)
	var c_ii: GameState.Card = b_mk.call("intendant", [])
	check(c_g.efficiency(c_ii, "embellir") > c_g.efficiency(c_anim, "embellir"), "l'Intendant embellit plus vite qu'un autre cadre")
	c_g.deploy(c_ii)
	var c_iw := c_g.worker_of(c_ii)
	c_iw.pos = Vector2(c_in) + Vector2(0.5, 0.5)
	c_iw.path.clear()
	c_iw.task = {"type": "station", "kind": "intendance", "obj": c_int, "tile": c_in}
	c_g.stock["bois"] = 5.0
	c_g.stock["pierre"] = 5.0
	c_g.decorations.clear()
	c_g.time = 0.0
	for _i in roundi(90.0 / GameState.TICK):
		c_g.tick(GameState.TICK)
	check(not c_g.decorations.is_empty(), "Intendance : des décorations apparaissent (%d)" % c_g.decorations.size())
	check(c_g.stock["bois"] < 5.0 and c_g.stock["pierre"] < 5.0, "Intendance : chaque décoration coûte des matériaux")
	var c_case: Vector2i = c_g.decorations[0]["t"]
	check(c_g.site_at(c_case) == null and not c_g.is_fence(c_case) and c_g.zoo_status()["interior"].has(c_case), "décoration sur une case libre du parc")
	c_g.decorations = [c_g.decorations[0]]
	var c_max := c_g.decorations_max()
	check(c_max == floori(c_g.zoo_status()["interior"].size() / 10.0), "une décoration au plus pour 10 cases (%d)" % c_max)
	for _i in c_max + 5:
		c_g.decorations.append({"t": Vector2i(0, 0), "id": "banc"})
	var c_nb := c_g.decorations.size()
	for _i in roundi(60.0 / GameState.TICK):
		c_g.tick(GameState.TICK)
	check(c_g.decorations.size() == c_nb, "parc au maximum : plus de nouvelle décoration")
	c_g.decorations.clear()
	c_g.recall(c_iw)
	c_g.sites.erase(c_int)
	data["events"]["proba_evenement"] = c_proba

	print("Lot D : évolution des cartes, cartes d'action, terrain :")
	# Évolution : un Apprenti au niveau 3 choisit son nouveau métier
	var d_g := _fresh_day(data, 6060)
	var d_appr: GameState.Card = b_mk.call("apprenti", [])
	d_appr.niveau = 3
	var d_opts := d_g._upgrade_pool(d_appr)
	check(not d_opts.is_empty() and d_opts.all(func(o): return o["id"] == "evolution"), "Apprenti niveau 3 : %d métiers au choix (%s)" % [
		d_opts.size(), ", ".join(d_opts.map(func(o): return o["nom"]))])
	d_g._apply_upgrade_effect(d_appr, d_opts[0])
	check(d_appr.metier["id"] == d_opts[0]["metier"] and d_appr.niveau == 3, "l'Apprenti devient %s (niveau gardé)" % d_appr.metier["nom"])
	# Cartes d'action jouées depuis la main
	var d_defs: Dictionary = {}
	for d_def in data["workers"]["cartes_action"]:
		d_defs[d_def["id"]] = d_def
	var d_emp0 := d_g.employees()
	var d_sup := d_g.mt.make_action(d_defs["heures_sup"])
	var d_liv := d_g.mt.make_action(d_defs["livraison"])
	var d_prime := d_g.mt.make_action(d_defs["prime"])
	var d_recr := d_g.mt.make_action(d_defs["recrutement"])
	d_g.hand.append_array([d_sup, d_liv, d_prime, d_recr])
	check(d_g.employees() == d_emp0, "les cartes d'action ne comptent pas dans le logement")
	check(not d_g.deploy(d_sup), "une carte d'action ne se déploie pas")
	var d_mult0 := d_g.task_mult("construire_bois")
	check(d_g.play_action(d_sup) and is_equal_approx(d_g.task_mult("construire_bois"), d_mult0 * 1.4), "Heures sup : +40 % de productivité")
	check(not d_g.hand.has(d_sup) and not d_g.play_action(d_sup), "usage unique : la carte jouée quitte la main")
	var d_bois0: float = d_g.stock["bois"]
	check(d_g.play_action(d_liv) and is_equal_approx(d_g.stock["bois"], d_bois0 + 30.0), "Livraison : +30 bois")
	var d_hand0 := d_g.hand.size()
	check(d_g.play_action(d_recr) and d_g.hand.size() == d_hand0 + 1, "Recrutement express : 2 cartes piochées (la carte jouée sort de la main)")
	d_g.play_action(d_prime)
	var d_worker: GameState.Card = d_g.hand.filter(func(c): return not c.is_action() and not c.deployed)[0]
	var d_money0 := d_g.money
	check(d_g.deploy(d_worker) and is_equal_approx(d_g.money, d_money0) and d_g.prime_left == 3, "Prime : ouvrier déployé sans salaire (3 restants)")
	d_g.end_day()
	check(d_g.action_cards().is_empty(), "le soir, les cartes jouées ne reviennent pas dans le deck")
	d_g.start_next_day()
	var d_fire := d_g.mt.make_action(d_defs["licenciement"])
	var d_promo := d_g.mt.make_action(d_defs["promotion"])
	var d_form := d_g.mt.make_action(d_defs["formation_express"])
	d_g.hand.append_array([d_fire, d_promo, d_form])
	var d_n0 := d_g.employees()
	var d_victim: GameState.Card = d_g.all_employees()[-1]
	check(not d_g.play_action(d_fire), "Rupture de contrat : il faut choisir un ouvrier")
	check(d_g.play_action(d_fire, d_victim) and d_g.employees() == d_n0 - 1 and not d_g.all_employees().has(d_victim),
		"Rupture de contrat : %s licencié, la carte quitte le deck" % d_victim.nom)
	var d_star: GameState.Card = d_g.all_employees()[0]
	var d_opt: Dictionary = d_g.upgrade_options(d_star)[0]
	var d_up0 := d_star.upgrade_names.size()
	check(d_g.play_action(d_promo, d_star, d_opt) and d_star.upgrade_names.size() == d_up0 + 1, "Promotion : %s gagne « %s »" % [d_star.nom, d_opt["nom"]])
	var d_far: GameState.Card = d_g.all_employees()[-1]
	var d_xp0 := d_far.xp
	check(d_g.play_action(d_form) and d_far.xp >= d_xp0 + 1.999, "Formation express : +2 jours d'expérience, même dans la pioche")
	# Draft : premiers tours plus faibles
	var d_neg := [0, 0]
	for i in 300:
		d_neg[0] += d_g.mt.make_card("peu_qualifie", 1.0).traits.filter(func(t): return not d_g.is_positive(t)).size()
		d_neg[1] += d_g.mt.make_card("peu_qualifie", 0.0).traits.filter(func(t): return not d_g.is_positive(t)).size()
	check(d_neg[0] > d_neg[1] + 200, "draft : cartes du 1er tour avec plus de défauts (%d contre %d sur 300 cartes)" % d_neg)
	# Achat au marché (partie à un joueur : on achète toujours en premier)
	var d_solo := Match.new(data, 6161, 1, 0)
	while d_solo.phase == "draft":
		d_solo.pick_draft(d_solo.ai_choice())
	var d_me: GameState = d_solo.players[0]
	d_me.money = 100.0
	d_me.stock["bois"] = 60.0
	d_me.stock["pierre"] = 60.0
	var d_agdef := d_me.building_def("agence")
	var d_ag: GameState.Site = null
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			if d_ag == null and d_me.placement_error("batiment", d_agdef, d_me.map.camp.position + Vector2i(dx, dy), false) == "":
				d_ag = d_me.place("batiment", d_agdef, d_me.map.camp.position + Vector2i(dx, dy))
	check(d_ag != null, "Agence d'intérim placée")
	d_ag.work = d_ag.travail()
	d_me._complete(d_ag)
	var d_dep: GameState.Card = d_me.hand.filter(func(c): return not c.is_action())[0]
	d_me.deploy(d_dep)
	var d_w := d_me.worker_of(d_dep)
	d_w.carry = 2.0
	d_w.carry_type = "bois"
	var d_take: GameState.Card = d_me.swap_candidates()[0]
	var d_cost := d_me.swap_cost(d_take)
	var d_m := d_me.money
	check(d_me.swap_worker(d_w, d_take) and d_w.card == d_take and d_take.deployed and d_me.discard.has(d_dep) and not d_dep.deployed \
		and is_equal_approx(d_me.money, d_m - d_cost) and is_equal_approx(d_w.carry, 2.0),
		"Agence d'intérim : %s remplace %s sur le terrain pour %d, la charge est gardée" % [d_take.nom, d_dep.nom, d_cost])
	check(not d_me.swap_worker(d_w, d_me.swap_candidates()[0]), "un seul échange par jour")
	var d_b0: float = d_me.stock["bois"]
	d_solo.end_day()
	check(is_equal_approx(d_me.stock["bois"], d_b0 + 2.0), "fin de journée : la charge des ouvriers est encaissée")
	check(d_solo.market_actions.size() == int(data["buildings"]["marche"]["actions"]), "%d cartes d'action au marché de nuit" % d_solo.market_actions.size())
	d_solo.night_goto("cartes")
	var d_buy: GameState.Card = d_solo.market_actions[0]
	check(d_me.buy_action(d_buy) and d_me.discard.has(d_buy) and d_me.action_cards().size() == 1, "carte d'action achetée : %s, dans la défausse" % d_buy.action["nom"])
	check(not d_me.buy_action(d_solo.market_actions[0]), "une seule carte d'action par nuit")

	# Terrain : transformations en deux étapes (par la Prairie) pour l'IA
	var d_ai: AIController = Match.new(data, 6262, 2, 0).ais[1]
	check(d_ai._conversion_steps("Foret", "Eau") == 2 and d_ai._conversion_steps("Roche", "Sable") == 2 \
		and d_ai._conversion_steps("Prairie", "Roche") == 1 and d_ai._conversion_steps("Eau", "Eau") == 0,
		"aménagement en deux étapes : Forêt → Eau, Roche → Sable (Dérocher)")

	print("Animaux (continent, type, affinités) et amélioration du camp :")
	var e_all: Array = data["animals"]["animaux"]
	check(e_all.all(func(d): return d.has("continent") and d.has("type")), "les %d animaux ont un continent et un type" % e_all.size())
	check(e_all.filter(func(d): return d["type"] == "aerien").size() >= 5, "au moins 5 animaux aériens (bonus « oiseaux » utile)")
	var e_proba = data["events"]["proba_evenement"]
	data["events"]["proba_evenement"] = 0.0
	var e_g := _fresh_day(data, 2027)
	e_g.debug_build_zoo(Vector2i(4, 4))
	e_g.end_day()
	e_g.start_next_day()
	check(is_zero_approx(e_g.affinity_bonus()), "un seul animal : pas d'affinité")
	var e_inside: Array = e_g.zoo_status()["interior"].keys().filter(func(t): return e_g.animal_at(t) == null)
	var e_def: Dictionary = e_all.filter(func(d): return d["continent"] == e_g.animals[0].def["continent"] and d["id"] != e_g.animals[0].def["id"])[0]
	var e_a := GameState.Animal.new()
	e_a.def = e_def
	e_a.tiles.assign([e_inside[0]])
	e_a.arrived = true
	e_a.food = e_g.food_capacity(e_def)
	e_g.animals.append(e_a)
	e_g.version += 1
	check(is_equal_approx(e_g.affinity_bonus(), 0.10), "2 animaux du même continent (%s) : réputation +10 %%" % e_g.continent_name(e_def["continent"]))
	var e_att0 := e_g.attractiveness()
	var e_bonus: Dictionary = data["events"]["bonus_nuit"].filter(func(b): return b["effets"].get("attractivite_continent", {}).has(e_def["continent"]))[0]
	e_g.day_bonus = e_bonus
	check(e_g.attractiveness() > e_att0, "%s : attractivité %d → %d" % [e_bonus["nom"], e_att0, e_g.attractiveness()])
	e_g.day_bonus = {}
	# Amélioration du camp : +1 carte en main, dans l'ordre des niveaux
	var e_hand0 := e_g.hand_size()
	e_g.stock["bois"] += 100.0
	e_g.stock["pierre"] += 100.0
	e_g.money += 100.0
	check(e_g.placement_error("batiment", e_g.building_def("camp_n3"), e_g.map.camp.position).begins_with("Terminez d'abord"), "niveau 3 impossible avant le niveau 2")
	var e_camp := e_g.place("batiment", e_g.building_def("camp_n2"), Vector2i(0, 0))
	check(e_camp != null and e_camp.rect == e_g.map.camp, "amélioration posée sur le camp, où que l'on clique")
	e_camp.work = e_camp.travail()
	e_g._complete(e_camp)
	check(e_g.hand_size() == e_hand0 + 1, "camp niveau 2 : %d cartes en main au lieu de %d" % [e_g.hand_size(), e_hand0])
	e_g.end_day()
	e_g.start_next_day()
	check(e_g.hand.size() == e_hand0 + 1 or e_g.deck.is_empty(), "le lendemain, la main compte %d cartes" % e_g.hand.size())
	data["events"]["proba_evenement"] = e_proba

	print("Lot F : marché, dépôt, enclos partagés, parc libre :")
	var f_proba = data["events"]["proba_evenement"]
	data["events"]["proba_evenement"] = 0.0
	var fm := _fresh_day(data, 12345)
	fm.stock["bois"] = 60.0
	fm.stock["pierre"] = 60.0
	fm.money = 100.0
	for c in fm.hand.duplicate():
		if c.metier["id"] != "marchand":  # un Marchand en main fausserait le test du prix sans Marchand
			fm.deploy(c)
	var f_site := fm.place("batiment", fm.building_def("comptoir"), fm.map.camp.position + Vector2i(-4, 0))
	check(f_site != null, "bâtiment Marché placé")
	f_site.work = f_site.travail()
	fm._complete(f_site)
	check(not fm.building_def("comptoir")["cout"].has("or") and not fm.building_def("comptoir")["cout"].has("argent"), "Marché : bois et pierre seulement")
	check(is_equal_approx(fm.sell_rate(), 0.7), "Marché sans Marchand : vente à 70 %% (%.2f)" % fm.sell_rate())
	var f_tr: GameState.Worker = fm.workers[0]
	f_tr.card.metier = fm.metier_def("marchand")
	f_tr.task = {"type": "station", "kind": "trade", "obj": f_site, "tile": f_site.rect.position}
	f_tr.pos = Vector2(f_site.rect.position) + Vector2(0.5, 0.5)
	f_tr.path.clear()
	check(is_equal_approx(fm.sell_rate(), 1.25) and is_equal_approx(fm.buy_mult(), 0.7),
		"Marchand au Marché : vente %.2f, achat ×%.2f" % [fm.sell_rate(), fm.buy_mult()])
	fm.stock["bois"] = 20.0
	var f_m0 := fm.money
	check(fm.sell_amount("bois", 8) and is_equal_approx(fm.stock["bois"], 12.0) and fm.money > f_m0, "vente d'une quantité choisie : 8 bois sur 20")
	var f_w: GameState.Worker = fm.workers[1]
	f_w.carry = 3.0
	f_w.carry_type = "pierre"
	f_w.task = {}
	var f_p0: float = fm.stock["pierre"]
	fm.order([f_w], fm.map.camp.get_center())
	for i in 300:
		fm.tick(0.1)
		if f_w.carry == 0.0:
			break
	check(is_zero_approx(f_w.carry) and is_equal_approx(fm.stock["pierre"], f_p0 + 3.0), "clic droit sur le camp : la charge est déposée")
	# Campagne publicitaire menée par un ouvrier à l'extérieur
	var f_out: GameState.Worker = fm.workers[2]
	fm.money = 100.0
	var f_aff: Dictionary = fm.campaign_defs()[0]
	check(fm.campaign_error(f_aff) != "", "campagne : il faut un ouvrier à l'extérieur")
	f_out.offmap = true
	f_out.path.clear()
	var f_metier0: Dictionary = f_out.card.metier
	f_out.card.metier = fm.metier_def("lobbyiste")
	check(fm.campaign_cost(f_aff) < int(f_aff["cout"]), "campagne moins chère avec un Lobbyiste dehors (%d au lieu de %d)" % [fm.campaign_cost(f_aff), int(f_aff["cout"])])
	f_out.card.metier = f_metier0
	# Influence gagnée (et non solde) : un Journaliste rival en reportage chez nous la fait baisser
	var f_inf0: float = fm.day_stats["influence"]
	check(fm.launch_campaign(f_aff) and is_equal_approx(fm.money, 100.0 - float(f_aff["cout"])), "campagne lancée et payée (%d)" % int(f_aff["cout"]))
	for i in 1500:
		fm.tick(0.1)
		if fm.campaign.is_empty():
			break
	check(is_equal_approx(fm.publicite, float(f_aff["points"])) and float(fm.day_stats["influence"]) > f_inf0,
		"campagne terminée par l'ouvrier dehors (+%d point), l'influence continue (+%.2f)" % [int(f_aff["points"]), float(fm.day_stats["influence"]) - f_inf0])
	check(fm.publicity_mult() > 1.05, "la publicité augmente l'affluence : ×%.2f" % fm.publicity_mult())

	var fg := _fresh_day(data, 2027)
	fg.debug_build_zoo(Vector2i(4, 4))
	fg.end_day()
	fg.start_next_day()
	var f_zebre: Dictionary = fg.animals[0].def
	var f_enc := fg.enclosure_at(Vector2i(7, 6))
	check(f_enc["closed"] and not f_enc.get("park", false), "enclos clôturé reconnu")
	var f_big: Dictionary = f_zebre.duplicate(true)
	f_big["id"] = "test_grand"
	f_big["taille"] = 3
	check("trop petit" in fg.animal_error(f_big, f_enc), "enclos partagé : la surface couvre tous les animaux (%s)" % fg.animal_error(f_big, f_enc))
	var f_park := fg.enclosure_at(Vector2i(10, 6))
	check(f_park["closed"] and f_park.get("park", false) and f_park["tiles"].size() >= 10, "le parc libre de l'enceinte sert d'enclos (%d cases)" % f_park.get("tiles", []).size())
	var f_lion: Dictionary = data["animals"]["animaux"].filter(func(d): return d.get("special", "") == "predateur")[0]
	check("prédateur" in fg.animal_error(f_lion, f_park), "pas de prédateur en liberté")
	var f_a: Dictionary = f_zebre.duplicate(true)
	f_a["id"] = "test_parc_a"
	f_a["taille"] = 4
	var f_b: Dictionary = f_zebre.duplicate(true)
	f_b["id"] = "test_parc_b"
	f_b["taille"] = 4
	f_a["taille"] = 5
	f_a["motif"] = [[0, 0, "Prairie"], [1, 0, "Prairie"], [0, 1, "Prairie"]]
	f_b["taille"] = 1
	f_b["motif"] = [[0, 0, "Prairie"]]
	fg.contracts.append_array([f_a, f_b])
	var f_bonus0 := fg.affinity_bonus()
	var f_sites0 := fg.sites.size()
	fg.stock["bois"] = 30.0
	check(fg.install_animal(f_a, Vector2i(10, 6)) == "" and fg.pending_installs.size() == 1 and fg.sites.size() > f_sites0,
		"animal posé dans le parc sans clôture : %d clôture(s) en chantier, l'animal est réservé" % (fg.sites.size() - f_sites0))
	for s in fg.sites.duplicate():
		if not s.done and s.def_id() == "enclos":
			s.work = s.travail()
			fg._complete(s)
	check(fg.pending_installs.is_empty() and fg.animals.size() == 2, "clôtures finies : l'animal s'installe")
	var f_home: Vector2i = fg.animals[1].tiles[0]
	check(fg.install_animal(f_b, f_home) == "", "deux animaux dans le même enclos (%s)" % fg.animal_error(f_b, fg.enclosure_at(f_home)))
	check(fg.animals[1].pattern_tiles.all(func(t): return not fg.animals[2].pattern_tiles.has(t)), "chaque animal garde ses cases de motif")
	fg.end_day()
	fg.start_next_day()
	check(fg.affinity_bonus() >= f_bonus0 + 0.149, "affinités : continent +10 %% et type partagé +5 %% (%.2f → %.2f)" % [f_bonus0, fg.affinity_bonus()])
	# Enclos en chantier : l'animal est réservé et n'arrive qu'une fois les clôtures terminées
	var fq := _fresh_day(data, 2027)
	fq.sans_enceinte = true
	fq.stock["bois"] = 50.0
	var f_fence := fq.building_def("enclos")
	var f_spot := Vector2i(-1, -1)
	var f_camp := fq.map.camp.position
	for y in range(f_camp.y - 12, f_camp.y):
		for x in range(f_camp.x - 12, f_camp.x + 12):
			var t := Vector2i(x, y)
			if f_spot.x >= 0 or fq.placement_error("batiment", f_fence, t, false) != "":
				continue
			var ok := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if fq.placement_error("batiment", f_fence, t + Vector2i(dx, dy), false) != "":
						ok = false
			if ok:
				f_spot = t
	check(f_spot.x >= 0, "emplacement libre pour un enclos d'une case")
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx != 0 or dy != 0:
				fq.place("batiment", f_fence, f_spot + Vector2i(dx, dy))
	var f_one: Dictionary = f_zebre.duplicate(true)
	f_one["id"] = "test_reserve"
	f_one["taille"] = 1
	f_one["motif"] = [[0, 0, GameMap.TERRAINS[fq.map.get_t(f_spot.x, f_spot.y)]]]
	fq.contracts.append(f_one)
	var f_n0 := fq.animals.size()
	check(fq.enclosure_at(f_spot).get("planned", false) and fq.install_animal(f_one, f_spot) == "" and fq.animals.size() == f_n0 		and fq.pending_installs.size() == 1 and not fq.contracts.has(f_one), "enclos en chantier : l'animal est réservé, pas encore installé")
	for st in fq.sites.duplicate():
		if not st.done and st.def_id() == "enclos":
			st.work = st.travail()
			fq._complete(st)
	check(fq.animals.size() == f_n0 + 1 and fq.pending_installs.is_empty() and fq.animals[-1].def == f_one,
		"clôtures terminées : l'animal réservé s'installe")
	# Céder la journée d'une carte contre de l'argent
	var gl := _fresh_day(data, 4242)
	for c in gl.hand:
		c.traits.erase("econome")
	gl.money = 0.0
	var gl_carte: GameState.Card = gl.hand[0]
	var gl_main := gl.hand.size()
	check(gl.ceder_carte(gl_carte) and is_equal_approx(gl.money, 4.0) and gl.hand.size() == gl_main - 1 and gl.discard.has(gl_carte), "carte cédée : +4 d'argent, elle part à la défausse")
	check(not gl.ceder_carte(gl_carte), "une carte déjà cédée ne se cède plus")
	data["events"]["proba_evenement"] = f_proba

	print("IA :")
	var mi := Match.new(data, 31, 2, -1)
	mi.advance_ai_draft()
	while mi.day < 6 and not mi.game_over:
		if mi.phase == "day":
			mi.tick(0.5)
		else:
			mi.start_next_day()
	for i in 2:
		var pl := mi.players[i]
		var built := pl.sites.filter(func(st): return st.done).size()
		print("  %s : jour %d, %d bâtiments terminés, %d animaux, %d argent, réputation %d" % [
			mi.names[i], mi.day, built, pl.animals.size(), int(pl.money), pl.reputation()])
		check(built > 20, "%s construit (%d bâtiments)" % [mi.names[i], built])
	check(mi.players.any(func(pl): return not pl.animals.is_empty() or not pl.contracts.is_empty()), "au moins une IA a un contrat ou un animal")

	print("Lot M : cadres jouables :")
	var m_g := _fresh_day(data, 4242)
	var m_arch: GameState.Card = b_mk.call("architecte", [])
	var m_cm: GameState.Card = b_mk.call("contremaitre", [])
	var m_mar: GameState.Card = b_mk.call("marchand", [])
	var m_drh: GameState.Card = b_mk.call("drh", [])
	var m_lent: GameState.Card = b_mk.call("manoeuvre", ["lent"])
	m_g.hand.append_array([m_arch, m_cm, m_mar, m_drh, m_lent])
	var m_c0 := m_g.task_mult("construire_bois")
	var m_e0 := m_g.task_mult("extraire_bois")
	check(m_g.play_cadre(m_arch) and is_equal_approx(m_g.task_mult("construire_bois"), m_c0 * 1.5) and is_equal_approx(m_g.task_mult("extraire_bois"), m_e0),
		"Architecte joué : construction +50 %, rien d'autre")
	check(not m_g.hand.has(m_arch) and m_g.discard.has(m_arch) and not m_g.play_cadre(m_arch), "le cadre joué part à la défausse")
	var m_s0 := m_g.speed(m_lent)
	check(m_g.play_cadre(m_cm) and m_g.speed(m_lent) > m_s0, "Contremaître joué : le défaut Lent n'agit plus (%.2f → %.2f)" % [m_s0, m_g.speed(m_lent)])
	m_g.stock["pierre"] = 20.0
	var m_money0 := m_g.money
	check(m_g.cadre_error(m_mar, null, "or") != "" and m_g.play_cadre(m_mar, null, "pierre") and m_g.stock["pierre"] < 1.0 \
		and m_g.money >= m_money0 + 22, "Marchand joué : pierre vendue à 140 %% (+%d)" % int(m_g.money - m_money0))
	var m_h0 := m_g.hand.size()
	check(m_g.cadre_error(m_drh, m_drh) != "" and m_g.play_cadre(m_drh, m_lent) and not m_g.all_employees().has(m_lent),
		"DRH joué : un ouvrier de la main est licencié")
	check(m_g.hand.size() == m_h0 or m_g.deck.is_empty(), "DRH joué : 2 cartes piochées (main %d → %d)" % [m_h0, m_g.hand.size()])
	var m_anim: GameState.Card = b_mk.call("animateur", [])
	m_g.hand.append(m_anim)
	var m_att0 := m_g.attractiveness()
	m_g.play_cadre(m_anim)
	check(m_g.animals.is_empty() or m_g.attractiveness() == m_att0 + 6, "Animateur joué : +6 d'attractivité")
	var m_form: GameState.Card = b_mk.call("formateur", [])
	var m_defaut: GameState.Card = b_mk.call("macon", ["lent"])
	var m_sans: GameState.Card = b_mk.call("macon", ["costaud"])
	m_g.hand.append_array([m_form, m_defaut, m_sans])
	check(m_g.cadre_error(m_form, m_sans) != "", "Stage : impossible sur un collaborateur sans défaut")
	check(m_g.play_cadre(m_form, m_defaut) and not m_defaut.traits.has("lent") and m_defaut.traits.size() == 1 and m_g.is_positive(m_defaut.traits[0]),
		"Stage : le défaut part et une qualité arrive (%s)" % str(m_defaut.traits))
	m_g.hand.erase(m_defaut)
	m_g.hand.erase(m_sans)
	var m_lob: GameState.Card = b_mk.call("lobbyiste", [])
	m_g.hand.append(m_lob)
	var m_inf0 := m_g.influence
	var m_neg := m_g.event_is_negative()
	m_g.play_cadre(m_lob)
	check(m_g.event_effects().is_empty() if m_neg else is_equal_approx(m_g.influence, m_inf0 + 3.0), "Lobbyiste joué : événement annulé ou +3 d'influence")

	print("Lot M : motifs, aménagements d'enclos, voisinage :")
	var v_zeb: Dictionary = data["animals"]["animaux"].filter(func(d): return d["id"] == "zebre")[0]
	var v_g := _fresh_day(data, 2027)
	check(v_g.pattern_variants(v_zeb).size() == 8, "motif du Zèbre : 8 orientations (rotations et miroirs)")
	v_g.debug_build_zoo(Vector2i(4, 4))
	v_g.end_day()
	v_g.start_next_day()
	var v_d: Dictionary = v_zeb.duplicate(true)
	v_d["id"] = "test_decor"
	v_d["nom"] = "Test arbre"
	v_d["taille"] = 5
	v_d["decor"] = "grand_arbre"
	v_d["motif"] = [[0, 0, "Prairie"], [1, 0, "Prairie"], [0, 1, "Prairie"]]
	v_g.contracts.append(v_d)
	v_g.stock["bois"] = 40.0
	check(v_g.install_animal(v_d, Vector2i(10, 6)) == "" and v_g.pending_installs.size() == 1, "enclos posé dans le parc avec son aménagement requis")
	var v_tree: Array = v_g.sites.filter(func(s): return s.def_id() == "grand_arbre")
	check(v_tree.size() == 1 and not v_tree[0].done, "Grand arbre posé en chantier dans l'enclos")
	for s in v_g.sites.duplicate():
		if not s.done and s.def_id() == "enclos":
			s.work = s.travail()
			v_g._complete(s)
	check(v_g.pending_installs.size() == 1 and v_g.animals.size() == 1, "clôtures finies, arbre en chantier : l'animal attend")
	v_tree[0].work = v_tree[0].travail()
	v_g._complete(v_tree[0])
	check(v_g.pending_installs.is_empty() and v_g.animals.size() == 2, "arbre terminé : l'animal s'installe")
	check(v_g.animals[1].pattern_tiles.size() == 3, "le motif peut passer sur la case de l'aménagement")
	v_g.end_day()
	var v_enc := v_g.enclosure_at(v_g.animals[1].tiles[0])
	v_g.start_next_day()
	var v_r: Dictionary = v_d.duplicate(true)
	v_r["id"] = "test_rocher"
	v_r["taille"] = 1
	v_r["decor"] = "rocher_obs"
	v_r["motif"] = [[0, 0, "Prairie"]]
	check("Rocher" in v_g.animal_error(v_r, v_enc), "aménagement requis absent : %s" % v_g.animal_error(v_r, v_enc))

	print("Lot O : entrée tournée, ordres enchaînés :")
	var o_g := _fresh_day(data, 3131)
	var o_def: Dictionary = o_g.building_def("entree").duplicate()
	o_def["taille"] = [1, 2]
	o_def["pivote"] = true
	var o_o := Vector2i(4, 4)
	o_g.stock["bois"] = 200.0
	o_g.stock["pierre"] = 200.0
	o_g.money = 200.0
	for y in range(o_o.y, o_o.y + 7):
		for x in range(o_o.x, o_o.x + 8):
			o_g.map.set_t(x, y, GameMap.PRAIRIE)
			o_g._terrain_updated(Vector2i(x, y))
	var o_built: Array = [o_g.place("batiment", o_def, Vector2i(o_o.x, o_o.y + 2))]
	check(o_built[0] != null and o_built[0].rect.size == Vector2i(1, 2), "entrée tournée : emprise 1 × 2")
	for y in range(o_o.y, o_o.y + 7):
		for x in range(o_o.x, o_o.x + 8):
			var border := x == o_o.x or x == o_o.x + 7 or y == o_o.y or y == o_o.y + 6
			if border and o_g.site_at(Vector2i(x, y)) == null:
				o_built.append(o_g.place("batiment", o_g.building_def("cloture"), Vector2i(x, y)))
	for st in o_built:
		if st:
			st.work = st.travail()
			o_g._complete(st)
	check(o_g.zoo_status()["interior"].size() == 30, "enceinte fermée par une entrée verticale (%d cases)" % o_g.zoo_status()["interior"].size())

	var q_g := _fresh_day(data, 5151)
	q_g.stock["bois"] = 50.0
	var q_card: GameState.Card = q_g.hand.filter(func(c): return not c.is_action())[0]
	q_g.deploy(q_card)
	var q_w := q_g.worker_of(q_card)
	var q_site := q_g.place("batiment", q_g.building_def("enclos"), q_g.map.camp.position + Vector2i(-2, 0))
	var q_forest := _nearest(q_g.map, GameMap.FORET)
	q_g.order([q_w], q_site.rect.position)
	q_g.order([q_w], q_forest, true)
	check(q_w.task.get("type") == "build" and q_w.queue == [q_forest], "Maj + clic droit : l'extraction attend la fin du chantier")
	for i in 3000:
		q_g.tick(GameState.TICK)
		if q_w.task.get("type") == "extract":
			break
	check(q_site.done and q_w.task.get("type") == "extract" and q_w.queue.is_empty(), "chantier fini : l'ouvrier enchaîne sur la récolte")
	q_g.order([q_w], q_site.rect.position)
	check(q_w.queue.is_empty(), "un nouvel ordre sans Maj vide la file")

	# Lion du joueur : enclos de 9 cases, motif de 8, Rocher d'observation sur une case du motif
	var l_g := _fresh_day(data, 8181)
	l_g.debug_build_zoo(Vector2i(4, 4))
	l_g.end_day()
	l_g.start_next_day()
	var l_lion: Dictionary = data["animals"]["animaux"].filter(func(d): return d["id"] == "lion")[0]
	var l_o := Vector2i(14, 4)
	l_g.stock["bois"] = 60.0
	l_g.stock["pierre"] = 60.0
	var l_rows := ["SSPPP", "SRPPP", "SPPPP"]
	for y in range(l_o.y, l_o.y + 5):
		for x in range(l_o.x, l_o.x + 7):
			l_g.map.set_t(x, y, GameMap.PRAIRIE)
			l_g._terrain_updated(Vector2i(x, y))
	for y in 3:
		for x in 5:
			var ch: String = l_rows[y][x]
			l_g.map.set_t(l_o.x + 1 + x, l_o.y + 1 + y, GameMap.SABLE if ch == "S" else (GameMap.ROCHE if ch == "R" else GameMap.PRAIRIE))
			l_g._terrain_updated(Vector2i(l_o.x + 1 + x, l_o.y + 1 + y))
	var l_sites: Array = []
	for y in range(l_o.y, l_o.y + 5):
		for x in range(l_o.x, l_o.x + 7):
			if (x == l_o.x or x == l_o.x + 6 or y == l_o.y or y == l_o.y + 4) and l_g.site_at(Vector2i(x, y)) == null:
				l_sites.append(l_g.place("batiment", l_g.building_def("enclos"), Vector2i(x, y)))
	for st in l_sites:
		if st:
			st.work = st.travail()
			l_g._complete(st)
	var l_rock := l_g.place("batiment", l_g.building_def("rocher_obs"), l_o + Vector2i(1, 1))
	l_rock.work = l_rock.travail()
	l_g._complete(l_rock)
	l_g.contracts.append(l_lion)
	var l_enc := l_g.enclosure_at(l_o + Vector2i(2, 2))
	check("enceinte" in l_g.animal_error(l_lion, l_enc), "enclos hors de l'enceinte refusé (%s)" % l_g.animal_error(l_lion, l_enc))
	l_g.sans_enceinte = true
	check(l_enc["closed"] and l_g.animal_error(l_lion, l_enc) == "", "Lion : rocher sur une case du motif, installation possible (%s)" % l_g.animal_error(l_lion, l_enc))

	print("Lot Q : eau, Marchand, bonus refusé :")
	var w_g := _fresh_day(data, 7171)
	var w_eau := Vector2i(-1, -1)
	for y in w_g.map.h:
		for x in w_g.map.w:
			if w_eau.x < 0 and w_g.map.get_t(x, y) == GameMap.EAU and w_g.map.road[w_g.map.idx(x, y)] == 0:
				w_eau = Vector2i(x, y)
	w_g.stock["bois"] = 20.0
	w_g.stock["pierre"] = 20.0
	check(w_g.placement_error("batiment", w_g.building_def("enclos"), w_eau) == "", "une clôture d'enclos se pose sur l'eau (%s)" % w_g.placement_error("batiment", w_g.building_def("enclos"), w_eau))
	check(w_g.placement_error("batiment", w_g.building_def("cloture"), w_eau) == "", "le mur d'enceinte aussi")
	var w_rate0 := w_g.sell_rate()
	var w_mar: GameState.Card = b_mk.call("marchand", [])
	w_g.hand.append(w_mar)
	w_g.deploy(w_mar, true)
	check(w_rate0 < 1.0 and is_equal_approx(w_g.sell_rate(), 1.0), "Marchand déployé, sans poste : plein tarif (%.2f → %.2f)" % [w_rate0, w_g.sell_rate()])
	w_g.end_day()
	w_g.mt.night_goto("bonus")
	var w_lead: GameState = w_g.mt.players[w_g.mt.influence_leader()]
	if not w_g.mt.is_ai(w_lead.index):
		check(w_lead.pick_bonus(Match.NO_BONUS) and w_g.mt.night_stage == "equipe", "le premier en influence peut refuser tous les bonus")
		w_g.start_next_day()
		check(w_g.day_bonus.get("id", "") == "aucun", "aucun bonus le lendemain")

	print("Rework : animaux rares, montagnes, guérison :")
	var y_g := _fresh_day(data, 1212)
	var y_defs: Dictionary = {}
	for d in data["animals"]["animaux"]:
		y_defs[d["id"]] = d
	check(data["animals"]["animaux"].size() == 40, "40 espèces sur 4 continents")
	y_g.debug_build_zoo(Vector2i(4, 4))
	y_g.end_day()
	y_g.mt.night_goto("equipe")
	y_g.start_next_day()
	var y_hand0 := y_g.hand_size()
	var y_tigre := GameState.Animal.new()
	y_tigre.def = y_defs["tigre"]
	y_tigre.arrived = true
	y_tigre.fed = true
	y_tigre.tiles.assign(y_g.animals[0].tiles)
	y_g.animals.append(y_tigre)
	check(y_g.hand_size() == y_hand0 + 1, "Tigre du Bengale : 1 carte de plus par jour")
	y_g.animals.erase(y_tigre)
	var y_a0 := y_g.attractiveness()
	var y_panda := GameState.Animal.new()
	y_panda.def = y_defs["panda"]
	y_panda.arrived = true
	y_panda.fed = true
	y_panda.tiles.assign(y_g.animals[0].tiles)
	y_g.animals.append(y_panda)
	check(y_g.attractiveness() >= y_a0 + 14 + 5, "Panda géant : +5 d'attractivité par autre herbivore (%d → %d)" % [y_a0, y_g.attractiveness()])
	y_g.animals.erase(y_panda)
	# Malade sans Soigneur : guérit seul au bout de 2 nuits
	var y_sick: GameState.Animal = y_g.animals[0]
	y_sick.sick = true
	y_sick.sick_nights = 0
	y_g._roll_diseases()
	check(y_sick.sick, "malade : encore malade après 1 nuit")
	y_sick.sick_nights = 1
	y_g._roll_diseases()
	check(not y_sick.sick or y_sick.sick_nights == 0, "malade : guérit seul au bout de 2 nuits")
	# Montagnes : elles ferment l'enceinte
	var y_m := _fresh_day(data, 1313)
	y_m.stock["pierre"] = 200.0
	y_m.stock["bois"] = 200.0
	var y_o := Vector2i(4, 4)
	for y in range(y_o.y, y_o.y + 6):
		for x in range(y_o.x, y_o.x + 8):
			y_m.map.set_t(x, y, GameMap.MONTAGNE if x == y_o.x else GameMap.PRAIRIE)
			y_m._terrain_updated(Vector2i(x, y))
	var y_sites: Array = [y_m.place("batiment", y_m.building_def("entree"), Vector2i(y_o.x + 3, y_o.y + 5))]
	for y in range(y_o.y, y_o.y + 6):
		for x in range(y_o.x + 1, y_o.x + 8):
			if (x == y_o.x + 7 or y == y_o.y or y == y_o.y + 5) and y_m.site_at(Vector2i(x, y)) == null:
				y_sites.append(y_m.place("batiment", y_m.building_def("cloture"), Vector2i(x, y)))
	for st in y_sites:
		if st:
			st.work = st.travail()
			y_m._complete(st)
	check(not y_m.zoo_status()["interior"].is_empty(), "une montagne sert de mur d'enceinte (%d cases)" % y_m.zoo_status()["interior"].size())

	print("Sauvegarde :")
	var s_m := Match.new(data, 2468, 4, 0)
	s_m.advance_ai_draft()
	while s_m.phase == "draft":
		s_m.pick_draft(s_m.ai_choice())
	for i in 3:
		for k in 300:
			s_m.tick(1.0)
		s_m.end_day()
		s_m.finish_night()
		s_m.autosave = i == 2
		s_m.start_next_day()
	s_m.autosave = false
	check(Sauvegarde.existe(), "sauvegarde écrite le matin du jour %d" % s_m.day)
	var s_c := Sauvegarde.charger(data)
	check(s_c != null and s_c.day == s_m.day, "partie rechargée au jour %d" % (s_c.day if s_c else -1))
	var s_rep_ok := true
	for i in 4:
		if not is_equal_approx(s_c.players[i].rep_points, s_m.players[i].rep_points) or s_c.players[i].sites.size() != s_m.players[i].sites.size() \
			or s_c.players[i].all_employees().size() != s_m.players[i].all_employees().size():
			s_rep_ok = false
	check(s_rep_ok, "réputation, chantiers et ouvriers identiques après chargement")
	Sauvegarde.reprendre(s_c)
	for k in 300:
		s_c.tick(1.0)
	s_c.end_day()
	s_c.finish_night()
	s_c.start_next_day()
	check(s_c.day == s_m.day + 1, "la partie rechargée continue normalement (jour %d)" % s_c.day)
	Sauvegarde.effacer()

	print("Multijoueur :")
	# La même partie jouée deux fois, avec les mêmes ordres, doit donner exactement le même état
	var mp_empreintes := []
	for essai in 2:
		var mp := Match.new(data, 3131, 4, 0, [], [1])
		while mp.phase == "draft":
			mp.pick_draft(mp.ai_choice())
		for jour in 2:
			for j in 2:
				var mg: GameState = mp.players[j]
				for c in mg.hand.duplicate():
					Commandes.executer(mp, j, "deploy", Commandes.coder([c]))
				for w in mg.workers:
					Commandes.executer(mp, j, "order", Commandes.coder([[w], mg.map.camp.get_center() + Vector2i(-3, j)]))
			for k in 600:
				mp.tick(GameState.TICK)
			Commandes.decision(mp, "fin_jour", 0)
			Commandes.decision(mp, "jour_suivant", 0)
		mp_empreintes.append(Commandes.empreinte(mp))
		if essai == 1:
			var d_av: Variant = mp.ais[1]
			Commandes.decision(mp, "ia_reprend", 1)
			check(d_av == null and mp.ais[1] != null, "joueur parti : une IA reprend son zoo")
			for k in 200:
				mp.tick(GameState.TICK)
	check(mp_empreintes[0] == mp_empreintes[1], "même graine et mêmes ordres : parties identiques")
	var mp_c: Variant = Commandes.coder({"a": [Vector2i(1, 2)], "b": 3})
	check(mp_c["a"][0] == Vector2i(1, 2) and mp_c["b"] == 3, "codage : les valeurs simples restent telles quelles")

	print("Braderie :")
	var bd_m := Match.new(data, 777, 2, 0)
	while bd_m.phase == "draft":
		bd_m.pick_draft(bd_m.ai_choice())
	var bd_g: GameState = bd_m.players[0]
	var bd_def: Dictionary = bd_g.building_def("boutique")
	var bd_inter := {}
	for k in 2:
		var s := GameState.Site.new()
		s.kind = "batiment"
		s.def = bd_def
		s.rect = Rect2i(Vector2i(5 + 3 * k, 5), Vector2i(2, 2))
		s.done = true
		bd_g.sites.append(s)
		bd_inter[s.rect.position] = true
	var bd_ventes := func() -> float:
		bd_g._zoo_cache_version = bd_g.version
		bd_g._zoo_cache = {"interior": bd_inter}
		var avant := bd_g.money
		bd_g._sell_souvenirs()
		return bd_g.money - avant
	check(is_zero_approx(bd_ventes.call()), "boutiques vides : rien de vendu")
	bd_g.action_fx["boutiques"] = 2.0
	var bd_v: float = bd_ventes.call()
	check(is_equal_approx(bd_v, 4.0 * float(bd_def["effet"]["souvenirs_par_visiteur"])), "Braderie : deux boutiques vides vendent ×2 chacune (%.1f)" % bd_v)
	check(float(bd_g.visit.get("souvenirs_rep", 0.0)) > 0.0, "Braderie : la réputation de boutique compte")
	bd_g.action_fx.erase("boutiques")

	print("Bureau des acquisitions :")
	var aq_g := _fresh_day(data, 5151)
	aq_g.money = 500.0
	aq_g.stock["bois"] = 100.0
	aq_g.stock["pierre"] = 100.0
	var aq_def: Dictionary = aq_g.market_contracts[0]
	check(aq_g.achat_jour_error(aq_def) != "", "sans le Bureau : pas d'achat de contrat en journée")
	var aq_c := aq_g.map.camp.get_center()
	var aq_s: GameState.Site = null
	for aq_r in range(2, 14):
		for aq_dy in range(-aq_r, aq_r + 1):
			for aq_dx in range(-aq_r, aq_r + 1):
				if aq_s == null and aq_g.placement_error("batiment", aq_g.building_def("acquisitions"), aq_c + Vector2i(aq_dx, aq_dy)) == "":
					aq_s = aq_g.place("batiment", aq_g.building_def("acquisitions"), aq_c + Vector2i(aq_dx, aq_dy))
	check(aq_s != null, "Bureau des acquisitions posé")
	aq_s.work = aq_s.travail()
	aq_g._complete(aq_s)
	var aq_prix := roundi(float(aq_g.contract_cost(aq_def, false)["argent"]) * 0.5)
	check(int(aq_g.achat_jour_cout(aq_def)["argent"]) == aq_prix, "moitié prix : %d argent" % aq_prix)
	var aq_argent := aq_g.money
	var aq_n := aq_g.market_contracts.size()
	check(aq_g.achat_jour(aq_def) and aq_g.contracts.has(aq_def), "contrat acheté en journée au Bureau")
	check(aq_g.market_contracts.size() == aq_n and not aq_g.market_contracts.has(aq_def), "le marché est aussitôt complété")
	check(aq_argent - aq_g.money >= aq_prix - 0.01, "payé au moins %d argent (or manquant compris)" % aq_prix)
	check(aq_g.achat_jour_error(aq_g.market_contracts[0]) != "", "un seul achat par jour")
	aq_g.mt.dispose()
	print("Plan de relance :")
	var rl_a: GameState = bd_m.players[0]
	var rl_b: GameState = bd_m.players[1]
	var rl_carte: GameState.Card = bd_m.market_workers[0] if not bd_m.market_workers.is_empty() else rl_a.hand[0]
	var rl_def: Dictionary = data["animals"]["animaux"].filter(func(d): return d["palier"] == "T2")[0]
	rl_a.rep_points = 10.0
	rl_b.rep_points = 10.0
	var rl_embauche := rl_a.hire_cost(rl_carte)
	var rl_contrat := int(rl_a.contract_cost(rl_def)["argent"])
	check(is_zero_approx(rl_a.remise_relance()), "à égalité : pas de remise")
	rl_b.rep_points = 30.0
	check(is_equal_approx(rl_a.remise_relance(), 0.2) and is_zero_approx(rl_b.remise_relance()), "20 points derrière : −20 %% (%.2f), rien pour le premier" % rl_a.remise_relance())
	check(int(rl_a.contract_cost(rl_def)["argent"]) == roundi(rl_contrat * 0.8) and rl_a.hire_cost(rl_carte) <= rl_embauche,
		"contrat %d → %d, embauche %d → %d" % [rl_contrat, int(rl_a.contract_cost(rl_def)["argent"]), rl_embauche, rl_a.hire_cost(rl_carte)])
	rl_b.rep_points = 90.0
	check(is_equal_approx(rl_a.remise_relance(), 0.3), "remise plafonnée à 30 %")
	rl_a.rep_points = 0.0
	rl_b.rep_points = 0.0

	var ob_m := Match.new(data, 4242, 3, 0, [{}, {}, {}])
	ob_m.advance_ai_draft()
	while ob_m.phase == "draft":
		ob_m.pick_draft(ob_m.draft_pool[0])
		ob_m.advance_ai_draft()
	check(ob_m.objectifs.size() == 3, "3 objectifs des actionnaires tirés")
	var ob_g: GameState = ob_m.players[0]
	var ob_r: GameState = ob_m.players[1]
	ob_m.objectifs = [{"id": "test", "type": "effectif", "n": 1, "texte": "test"}]
	var ob_rep := ob_g.rep_points
	ob_g.verifier_objectifs()
	check(is_equal_approx(ob_g.rep_points, ob_rep + 10.0) and ob_g.objectifs_faits.has("test"), "objectif rempli : +10 de réputation")
	ob_g.verifier_objectifs()
	check(is_equal_approx(ob_g.rep_points, ob_rep + 10.0), "un objectif ne paie qu'une fois")
	ob_m.objectifs = [{"id": "test_date", "type": "effectif", "n": 1, "avant_jour": 8, "texte": "test"}]
	var ob_jour := ob_m.day
	ob_m.day = 8
	ob_g.verifier_objectifs()
	check(ob_g.objectif_manque(ob_m.objectifs[0]) and not ob_g.objectifs_faits.has("test_date") and ob_g.objectif_avancement(ob_m.objectifs[0]) == "manqué",
		"objectif à date : manqué à partir du jour 8")
	ob_m.day = 7
	ob_g.verifier_objectifs()
	check(ob_g.objectifs_faits.has("test_date"), "objectif à date : rempli au jour 7")
	ob_m.day = ob_jour
	var ob_c: GameState.Card = ob_g.hand[0]
	ob_c.metier = data["workers"]["metiers"].filter(func(mm): return mm["id"] == "journaliste")[0]
	ob_g.money = 500.0
	ob_g.deploy(ob_c)
	var ob_w := ob_g.worker_of(ob_c)
	check(ob_g.report_error(ob_w, 1) != "", "reportage : il faut d'abord sortir de la carte")
	ob_w.offmap = true
	check(ob_g.report_error(ob_w, 0) != "" and ob_g.report_start(ob_w, 1), "reportage : seulement chez un rival")
	var ob_rival: GameState = ob_g.mt.players[1]
	ob_rival.influence = 5.0
	ob_g._update_reportage(ob_w, 60.0)
	check(is_equal_approx(ob_rival.influence, 4.0), "reportage : le parc visité perd 1 d'influence par minute (%.2f)" % ob_rival.influence)
	ob_rival.influence = 0.3
	ob_g._update_reportage(ob_w, 60.0)
	check(ob_rival.influence == 0.0, "reportage : l'influence ne descend pas sous 0")
	check(not ob_g.vus[1].is_empty() and ob_g.vus[1].size() < ob_r.map.w * ob_r.map.h / 4, "brouillard : seules les cases autour du Journaliste sont dévoilées")
	var ob_pub := ob_r.publicity_mult()
	check(ob_g.publish_article(ob_w) and is_equal_approx(ob_r.publicity_mult(), ob_pub * 0.8), "article : publicité du rival ×0,8")
	check(ob_g.article_error(ob_w) != "", "un seul article par jour")
	for ob_k in ob_r.hand.duplicate():
		ob_r.deploy(ob_k)
	var ob_cible: GameState.Worker = ob_r.workers[0]
	ob_cible.pos = ob_w.reportage["pos"]
	ob_cible.card.niveau = int(data["workers"]["regles"]["niveau_max"])
	var ob_rep_r := ob_r.rep_points
	var ob_eff := ob_r.all_employees().size()
	check(ob_g.accuse_error(ob_w, -1) != "", "accusation : la cible doit être en vue")
	check(ob_g.accuse_worker(ob_w, ob_cible.card.id) and ob_r.all_employees().size() == ob_eff - 1 and not ob_r.workers.has(ob_cible), "accusation : le collaborateur est licencié")
	check(is_equal_approx(ob_r.rep_points, ob_rep_r - 5.0), "un légendaire licencié emporte son bonus de réputation")
	var ob_ep: Array = data["events"]["evenements"].filter(func(e): return e["effets"].get("epidemie", false))
	check(ob_ep.size() == 1, "l'épidémie existe")
	var ob_n: Match = Match.new(data, 4243, 2, -1, [{}, {}])
	var ob_vieux: Variant = data["events"]["proba_evenement"]
	data["events"]["proba_evenement"] = 1.0
	var ob_vu := false
	ob_n.day = 3
	for ob_i in 200:
		ob_n._draw_event()
		ob_vu = ob_vu or ob_n.current_event.get("effets", {}).get("epidemie", false)
	data["events"]["proba_evenement"] = ob_vieux
	check(not ob_vu, "pas d'épidémie tant que personne n'a d'animal")
	ob_m.dispose()
	ob_n.dispose()
	print("Lot S : autres sources de réputation :")
	var x_g := _fresh_day(data, 9191)
	check(x_g.objective() == 120, "objectif : 120 de réputation")
	x_g.annonce("licenciement", {"nom": "Marcel"})
	check(x_g.annonces.size() >= 1 and x_g.annonces[-1]["moment"] == "licenciement", "Hubert : une réplique attend le joueur humain")
	x_g.annonces.clear()
	var ev_sans_replique: Array = data["events"]["evenements"].filter(func(e): return not data["hubert"]["repliques"].has("ev_" + str(e["id"])))
	check(ev_sans_replique.is_empty(), "Hubert : une réplique pour chaque événement (%s)" % str(ev_sans_replique.map(func(e): return e["id"])))
	var x_lab: Dictionary = x_g.label_defs()[0]
	x_g.stock["or"] = 40.0
	check(x_g.label_error(x_lab).begins_with("Ouvrez d'abord"), "label : impossible avant l'ouverture du zoo")
	x_g.debug_build_zoo(Vector2i(4, 4))
	x_g.end_day()
	x_g.mt.night_goto("equipe")
	x_g.start_next_day()
	x_g.stock["or"] = 40.0
	check(is_equal_approx(x_g.label_price(x_lab), float(x_lab["or"]) * 2.0) and x_g.label_error(x_lab) == "", "label sans Marchand : possible, au double du prix (%d or)" % int(x_g.label_price(x_lab)))
	var x_mar: GameState.Card = b_mk.call("marchand", [])
	x_g.hand.append(x_mar)
	x_g.deploy(x_mar, true)
	var x_rep0 := x_g.rep_points
	check(x_g.buy_label(x_lab) and is_equal_approx(x_g.rep_points, x_rep0 + float(x_lab["reputation"])) and is_equal_approx(x_g.stock["or"], 40.0 - float(x_lab["or"])),
		"label %s : %d or → +%d de réputation" % [x_lab["nom"], int(x_lab["or"]), int(x_lab["reputation"])])
	check(not x_g.buy_label(x_lab), "un label ne s'achète qu'une fois")
	var x_card: GameState.Card = x_g.all_employees()[0]
	x_card.niveau = 5
	x_card.xp = 16.0
	var x_rep1 := x_g.rep_points
	x_g.mt.players[1].influence = 5.0
	x_g.end_day()
	check(x_card.niveau == 6 and x_g.night_report["legendes"].has(x_card.nom), "niveau 6 : %s devient légendaire" % x_card.nom)
	check(x_g.rep_points >= x_rep1 + 5.0, "légendaire : +5 de réputation pour le parc")
	var x_lead: GameState = x_g.mt.players[x_g.mt.night_order[0]]
	check(x_lead.night_report.get("prestige", 0.0) == 3.0, "prestige politique : +3 pour le premier en influence")

	print("\n%s" % ("TOUS LES TESTS PASSENT" if failures == 0 else "%d ÉCHEC(S)" % failures))
	quit(failures)


## Partie à 2 joueurs (vous + une IA), draft fait automatiquement : renvoie votre état au jour 1.
func _fresh_day(data: Dictionary, s: int) -> GameState:
	var m := Match.new(data, s, 2, 0)
	while m.phase == "draft":
		m.pick_draft(m.ai_choice())
	return m.players[0]


func _nearest(m: GameMap, terrain: int) -> Vector2i:
	var reach := MapGenerator.reachable(m)
	var c := m.camp.get_center()
	var best := c
	var best_d := 1 << 30
	for y in m.h:
		for x in m.w:
			if m.get_t(x, y) == terrain and reach[m.idx(x, y)]:
				var d := absi(x - c.x) + absi(y - c.y)
				if d < best_d:
					best_d = d
					best = Vector2i(x, y)
	return best
