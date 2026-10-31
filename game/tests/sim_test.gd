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
	check(mt.draft_pool.size() == 4 and mt.draft_reserve.size() == 36, "4 cartes révélées par tour, 10 tours (2 joueurs)")
	var order := mt.draft_order.slice(0, 4)
	check(order[0] != order[1] and order[2] == order[1], "le premier à choisir tourne (%s)" % str(order))
	mt.pick_draft(mt.ai_choice())
	check(mt.draft_pool.size() == 3 and mt.draft_round() == 0, "un choix retire la carte, le tour continue")
	mt.pick_draft(mt.ai_choice())
	check(mt.draft_round() == 1 and mt.draft_pool.size() == 4, "à 2 joueurs, les 2 cartes restantes sont défaussées")
	while mt.phase == "draft":
		mt.pick_draft(mt.ai_choice())
	check(mt.drafted[0].size() == 10 and mt.drafted[1].size() == 10, "10 cartes chacun")
	# À 4 joueurs : la 4e carte du tour revient d'office au 4e joueur, puis le premier change.
	var m4 := Match.new(data, 43, 4, -1)
	var first4 := m4.current_drafter()
	for k in 3:
		m4.pick_draft(m4.ai_choice())
	check(m4.draft_round() == 1 and m4.draft_pool.size() == 4 and m4.drafted.all(func(d): return d.size() == 1),
		"4 joueurs : 3 choix, la dernière carte attribuée d'office")
	check(m4.current_drafter() == (first4 + 1) % 4, "4 joueurs : le premier à choisir avance d'un joueur")
	while m4.phase == "draft":
		m4.pick_draft(m4.ai_choice())
	check(m4.drafted.all(func(d): return d.size() == 10), "4 joueurs : 10 cartes chacun")
	check(g.phase == "day" and g.hand.size() == 5, "le jour 1 commence avec 5 cartes en main")

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
	check(g.day == 2 and g.hand.size() == 5, "jour 2 : nouvelle main")

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
	check(is_equal_approx(ga.aura_mult(b), 1.15), "Charismatique à 2 cases : +15 %% (x%.2f)" % ga.aura_mult(b))
	b.pos = a.pos + Vector2(5, 0)
	check(is_equal_approx(ga.aura_mult(b), 1.0), "à 5 cases : aucun bonus")
	check(is_equal_approx(ga.aura_mult(a), 1.0), "pas de bonus pour lui-même")
	a.card.traits.assign(["rabat_joie"])
	b.pos = a.pos + Vector2(1, 0)
	check(is_equal_approx(ga.aura_mult(b), 0.9), "Rabat-joie adjacent : -10 %%")

	print("Construction :")
	var gc := _fresh_day(data, 12345)
	gc.stock["bois"] = 100.0
	gc.stock["pierre"] = 100.0
	for c in gc.hand.duplicate():
		gc.deploy(c)
	var builders := gc.workers.filter(func(w): return not w.card.traits.has("col_blanc"))
	var camp := gc.map.camp
	check(gc.placement_error("batiment", gc.building_def("maison"), camp.position) != "", "refus sur le camp")
	var maison := gc.place("batiment", gc.building_def("maison"), camp.position + Vector2i(-4, 0))
	check(maison != null and is_equal_approx(gc.stock["bois"], 88.0), "maison placée, 12 bois payés")
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
	check(maison.done and gc.housing() == 14, "maison terminée : logement %d" % gc.housing())
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
	check(gk.market_workers.size() == 5 and gk.market_contracts.size() == 4, "marché ouvert : 5 ouvriers, 4 contrats")
	check(gk.market_contracts.all(func(d): return d["palier"] == "T1"), "jour 1 : uniquement des contrats T1")
	gk.stock["bois"] = 20.0
	gk.stock["pierre"] = 10.0
	var house := gk.place("batiment", gk.building_def("maison"), gk.map.camp.position + Vector2i(3, 0))
	gk.end_day()
	check(gk.night_order.size() == 2, "ordre de passage fixé (%s)" % str(gk.night_order))
	gk.money = 100.0
	check(gk.hire_error(gk.market_workers[0]) != "", "logement plein (10/10) : embauche refusée sans maison")
	house.work = house.travail()
	gk._complete(house)
	var before := gk.employees()
	var recrue: GameState.Card = gk.market_workers[0]
	var prix := gk.hire_cost(recrue)
	check(gk.hire(recrue) and gk.employees() == before + 1 and gk.discard.has(recrue), "embauche : la recrue va dans la défausse (%d argent)" % prix)
	check(not gk.hire(gk.market_workers[0]), "une seule embauche par nuit")
	var zebre: Dictionary = data["animals"]["animaux"].filter(func(d): return d["id"] == "zebre")[0]
	var lion: Dictionary = data["animals"]["animaux"].filter(func(d): return d["id"] == "lion")[0]
	gk.market_contracts.append(zebre)
	check(gk.buy_contract(zebre) and gk.contracts.has(zebre), "contrat Zèbre acheté")
	var second: Dictionary = gk.market_contracts[0]
	var base_price := int(second["cout"].get("argent", 0))
	var expected := roundi(base_price * (1.0 + 0.15 * 1) * 1.5)
	check(int(gk.contract_cost(second).get("argent", 0)) == expected, "2e contrat : prix x1,15 (1 animal) x1,5 (2e de la nuit) = %d (base %d)" % [expected, base_price])
	check(gk.buy_contract(second), "2e contrat de la nuit accepté")
	check(gk.contract_error(gk.market_contracts[0]).begins_with("Déjà 2"), "3e contrat refusé")
	gk.contracts.erase(second)
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
	var fences: Array = []
	for y in range(y0, y0 + 4):
		for x in range(cx - 6, cx - 1):
			if x == cx - 6 or x == cx - 2 or y == y0 or y == y0 + 3:
				fences.append(gk.place("batiment", gk.building_def("enclos"), Vector2i(x, y)))
	check(fences.all(func(f): return f != null), "%d clôtures d'enclos placées" % fences.size())
	check(gk.install_animal(zebre, interior) != "", "refusé tant que les clôtures ne sont pas terminées")
	for f in fences:
		f.work = f.travail()
		gk._complete(f)
	var enc := gk.enclosure_at(interior)
	check(enc["closed"] and enc["tiles"].size() == 6, "enclos fermé de 6 cases")
	check(gk.animal_error(lion, enc) != "", "Lion refusé : %s" % gk.animal_error(lion, enc))
	check(gk.install_animal(zebre, interior) == "" and gk.contracts.is_empty(), "Zèbre installé")
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
	gz.sick_animal = null
	var live := gz.zoo_live()
	check(live["open"] and live["attract"] == 4, "le Zèbre est arrivé : zoo ouvert, attractivité %d" % live["attract"])
	for i in 1500:
		gz.tick(GameState.TICK)
	check(gz.visitor_queue > 0 and gz.visit["admitted"] == 0, "personne au guichet : %d visiteurs attendent, aucun n'entre" % gz.visitor_queue)
	var money_mid := gz.money
	var clerk: GameState.Card = gz.hand[0]
	gz.deploy(clerk, true)
	var entree: GameState.Site = gz.sites.filter(func(s): return s.def_id() == "entree")[0]
	gz.order([gz.worker_of(clerk)], entree.rect.position)
	for i in 1300:
		gz.tick(GameState.TICK)
	var admitted: int = gz.visit["admitted"]
	check(admitted > 0 and is_equal_approx(gz.visit["tickets"], admitted * 2.0), "guichet tenu : %d visiteurs entrés, billets %d" % [admitted, int(gz.visit["tickets"])])
	check(gz.money > money_mid, "les billets sont encaissés pendant la journée")
	gz.end_day()
	var inc: Dictionary = gz.night_report["income"]
	var rep_coef := float(data["buildings"]["zoo"]["reputation_par_visiteur_moyen"])
	check(gz.rep_points > 0.0 and is_equal_approx(gz.rep_points, inc["avg_present"] * rep_coef), "réputation gagnée selon la fréquentation moyenne : +%.2f" % gz.rep_points)
	gz.cared_today[gz.animals[0]] = true
	check(gz.attractiveness() == 6, "Soigneur : +2 d'attractivité")
	gz.influence = 15.0
	check(is_equal_approx(gz.publicity_mult(), 1.3), "publicité : influence 15 -> +30 %% de visiteurs")
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
	gvz.sick_animal = null
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
	check(is_equal_approx(gv.money - m0, 6.0) and is_equal_approx(gv.stock["or"], 2.0), "sans Marchand : moitié prix (+%d), l'or est gardé" % int(gv.money - m0))

	print("Nouvelles règles :")
	var gf := _fresh_day(data, 77)
	check(is_equal_approx(gf.stock["bois"], 15.0) and is_equal_approx(gf.stock["pierre"], 15.0), "stock de départ : 15 bois, 15 pierre")
	gf.money = 0.0
	var c0: GameState.Card = gf.hand[0]
	var c1: GameState.Card = gf.hand[1]
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
	check(tigre["motif"].size() == 5, "Tigre : motif de 5 cases")

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
	check(mn.bonus_offer.size() == 3, "3 bonus offerts pour 2 joueurs")
	var free_bonus: Array = mn.bonus_offer.filter(func(b): return not mn.bonus_taken.has(b["id"]))
	check(me.pick_bonus(free_bonus[0]), "bonus choisi : %s" % free_bonus[0]["nom"])
	check(me.night_action_error(12) != "", "pas d'amélioration avant le milieu de partie (%s)" % me.night_action_error(12))
	mn.start_next_day()
	check(me.day_bonus == free_bonus[0], "le bonus est actif le lendemain")
	while mn.day < 7:
		mn.end_day()
		mn.start_next_day()
	mn.end_day()
	me.money = 100.0
	var target: GameState.Card = me.all_employees()[0]
	var opts := me.upgrade_options(target)
	check(opts.size() == 3, "3 améliorations proposées")
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
	check(is_equal_approx(b_appr.xp, 2.0), "Apprenti : expérience ×2 (%.1f jour pour 1 jour travaillé)" % b_appr.xp)
	var b_eleve: GameState.Card = b_mk.call("manoeuvre", ["bon_eleve"])
	b_g.gain_xp(b_eleve, 1.0)
	check(is_equal_approx(b_eleve.xp, 1.5), "Bon élève : expérience ×1,5")
	check(b_g._upgrade_pool(b_mk.call("manoeuvre", ["tetu"])).size() == 2, "Têtu : 2 améliorations au choix au lieu de 3")
	# Montée de niveau : une amélioration gratuite au choix
	var b_lc: GameState.Card = b_g.hand[0]
	b_g.deploy(b_lc, true)
	b_lc.xp = 1.0
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
	# Centre de formation
	var b_proba = data["events"]["proba_evenement"]
	data["events"]["proba_evenement"] = 0.0
	b_g.start_next_day()
	data["events"]["proba_evenement"] = b_proba
	b_g.stock["bois"] += 60.0
	b_g.stock["pierre"] += 60.0
	b_g.money += 80.0
	var b_o := Vector2i(b_g.map.camp.position.x - 5, b_g.map.camp.position.y)
	var b_centre := b_g.place("batiment", b_g.building_def("formation"), b_o)
	check(b_centre != null, "Centre de formation placé")
	b_centre.work = b_centre.travail()
	b_g._complete(b_centre)
	var b_trainee: GameState.Card = b_g.hand[0]
	b_g.deploy(b_trainee)
	b_g.order([b_g.worker_of(b_trainee)], b_centre.rect.position)
	for i in 300:
		b_g.tick(GameState.TICK)
	var b_xp0 := b_trainee.xp
	for i in 600:
		b_g.tick(GameState.TICK)
	var b_rate: float = float(b_g.building_def("formation")["effet"]["xp_par_minute"]) * b_g.xp_mult(b_trainee)
	var b_gain1 := b_trainee.xp - b_xp0
	check(absf(b_gain1 - b_rate) < 0.02, "Centre de formation : +%.2f jour d'expérience par minute" % b_gain1)
	var b_form: GameState.Card = b_mk.call("formateur", [])
	b_g.deploy(b_form)
	b_g.order([b_g.worker_of(b_form)], b_centre.rect.position)
	for i in 300:
		b_g.tick(GameState.TICK)
	var b_xp1 := b_trainee.xp
	for i in 600:
		b_g.tick(GameState.TICK)
	var b_gain2 := b_trainee.xp - b_xp1
	check(absf(b_gain2 - 2.0 * b_rate) < 0.02, "avec un Formateur posté : ×2 (+%.2f par minute)" % b_gain2)
	# Architecte col blanc : supervise sans construire, puis rembourse 25 % à la fin
	var b_arch: GameState.Card = b_mk.call("architecte", ["col_blanc"])
	b_g.deploy(b_arch)
	var b_maison := b_g.place("batiment", b_g.building_def("maison"), b_o + Vector2i(0, 3))
	check(b_maison != null, "maison placée")
	b_g.order([b_g.worker_of(b_arch)], b_maison.rect.position)
	for i in 300:
		b_g.tick(GameState.TICK)
	check(is_equal_approx(b_maison.savings, 0.75) and is_zero_approx(b_maison.work), "Architecte col blanc : il supervise sans construire")
	var b_bois0: float = b_g.stock["bois"]
	b_maison.work = b_maison.travail()
	b_g._complete(b_maison)
	var b_refund: float = b_g.stock["bois"] - b_bois0
	check(is_equal_approx(b_refund, floorf(float(b_maison.paid["bois"]) * 0.25)), "chantier terminé : 25 %% du bois remboursé (+%d)" % int(b_refund))
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
	check(is_equal_approx(c_g.snack_mult(), 1.25), "Snack tenu : visites 25 % plus longues")
	data["events"]["proba_evenement"] = c_proba

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
