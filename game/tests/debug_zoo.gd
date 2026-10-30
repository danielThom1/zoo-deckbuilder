extends SceneTree
## Diagnostic : état du zoo de chaque IA au fil des jours, pour une graine donnée.
##   godot --headless --path game --script res://tests/debug_zoo.gd -- --seed=1051 --jours=9


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	# --rot=N : mêmes stratégies que la partie N de balance_sim.gd
	var strategies := []
	if args.has("rot"):
		var all: Array = load("res://tests/balance_sim.gd").STRATEGIES
		for k in 4:
			strategies.append(all[(int(args["rot"]) + k) % all.size()])
	var m := Match.new(GameData.load_all(), int(args.get("seed", "1051")), 4, -1, strategies)
	m.advance_ai_draft()
	var last_day := int(args.get("jours", "9"))
	while m.day < last_day and not m.game_over:
		if m.phase == "day":
			m.tick(1.0)
		else:
			m.start_next_day()
	for i in 4:
		var ai: AIController = m.ais[i]
		var p := m.players[i]
		var z := p.zoo_status()
		var team := p.all_employees().map(func(c): return c.metier["id"])
		print("%s : jour %d, rép %d, attractivité %d, %d visiteurs/jour attendus, file %d | équipe %s" % [m.names[i], m.day, p.reputation(), p.attractiveness(), roundi(p.demand_rate() * p.day_length), p.visitor_queue, str(team)])
		print("%s : zoo %s entrée %s murs %.0f %% | chemin visiteurs %d | plan de route %d | %s | animaux %d, contrats %d | argent %d" % [
			m.names[i], str(ai.zoo_rect), str(ai.entrance), ai._walls_progress() * 100, p.visitor_path().size(),
			ai._road_plan().size(), "ouvert" if z["open"] else z["reason"], p.animals.size(), p.contracts.size(), int(p.money)])
		var front := ai.entrance + (Vector2i(0, 1) if ai.entrance.y == ai.zoo_rect.end.y - 1 else Vector2i(0, -1))
		if ai.entrance.x >= 0:
			print("   devant l'entrée %s : terrain %s, chantier %s, réservé %s, terre %s" % [str(front), GameMap.TERRAINS[p.map.get_t(front.x, front.y)],
				str(p.site_at(front).def_id() if p.site_at(front) else "aucun"), str(ai.reserved.has(front)), str(ai._land(front))])
		var ent := p.site_at(ai.entrance)
		print("   entrée : %s" % (("terminée" if ent.done else "chantier %d/%d" % [int(ent.work), int(ent.travail())]) if ent else "non placée"))
	m.dispose()
	quit(0)
