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
	var cats := {"peu_qualifie": 0, "qualifie": 0, "cadre": 0}
	var runs := 200
	for s in runs:
		var md := Match.new(data, s + 1000, 2, 0)
		for c in md.draft_pool:
			cats[c.metier["categorie"]] += 1
	print("  moyenne par draft de 20 cartes : %.1f peu qualifiés, %.1f qualifiés, %.1f cadres" % [
		cats["peu_qualifie"] / float(runs), cats["qualifie"] / float(runs), cats["cadre"] / float(runs)])
	var cols := 0
	var col_ok := true
	for s in 100:
		var mc := Match.new(data, s + 5000, 1, 0)
		for i in 30:
			var c := mc.make_card(["peu_qualifie", "qualifie", "cadre"][i % 3])
			if c.traits.has("col_blanc"):
				cols += 1
				col_ok = col_ok and c.metier["categorie"] == "cadre"
	check(col_ok and cols > 0, "Col blanc uniquement chez les cadres (%d tirés)" % cols)
	var mt := Match.new(data, 42, 2, 0)
	var g: GameState = mt.players[0]
	check(mt.draft_pool.size() == 20, "pool de 20 cartes pour 2 joueurs")
	var order := mt.draft_order.slice(0, 4)
	check(order[0] != order[1] and order[1] == order[2], "ordre serpent (%s)" % str(order))
	while mt.phase == "draft":
		mt.pick_draft(mt.ai_choice())
	check(mt.drafted[0].size() == 10 and mt.drafted[1].size() == 10, "10 cartes chacun")
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
	gk.start_next_day()
	check(gk.attractiveness() == 0, "non nourri faute d'argent : il ne compte pas ce tour-ci")
	gk.end_day()
	gk.money = 10.0
	gk.start_next_day()
	check(gk.attractiveness() == 4 and is_equal_approx(gk.money, 8.0), "nourri (2 argent pour un T1) : il compte de nouveau")

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
	check(gz.rep_points > 0.0 and is_equal_approx(gz.rep_points, inc["avg_present"] * 0.6), "réputation gagnée selon la fréquentation moyenne : +%.2f" % gz.rep_points)
	gz.cared_today[gz.animals[0]] = true
	check(gz.attractiveness() == 6, "Soigneur : +2 d'attractivité")
	gz.influence = 15.0
	check(is_equal_approx(gz.publicity_mult(), 1.3), "publicité : influence 15 -> +30 %% de visiteurs")
	# Ouvrir une brèche dans l'enceinte ferme le zoo
	var wall: GameState.Site = gz.site_at(Vector2i(6, 4))  # milieu du mur du haut (un coin ne laisse rien passer)
	gz._remove_site(wall)
	check(not gz.zoo_status()["open"], "brèche dans l'enceinte : zoo fermé")

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
