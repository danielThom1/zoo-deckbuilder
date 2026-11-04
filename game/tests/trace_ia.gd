extends SceneTree
## Suit une IA pas à pas : à chaque journée, argent, stock, murs, chantiers et tâches des ouvriers.
##   godot --headless --path game --script res://tests/trace_ia.gd -- --gi=0 --joueur=0 --jours=8 [--tranche=100]

func _init() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		var kv := s.trim_prefix("--").split("=", true, 1)
		a[kv[0]] = kv[1] if kv.size() > 1 else ""
	var data := GameData.load_all()
	var script := load("res://tests/balance_sim.gd")
	var liste: Array = script.STRATEGIES
	var gi := int(a.get("gi", "0"))
	var j := int(a.get("joueur", "0"))
	var jours := int(a.get("jours", "8"))
	var tranche := float(a.get("tranche", "100"))
	var picks := []
	for k in 4:
		picks.append(liste[(gi + k * (1 + gi % 5)) % liste.size()])
	var m := Match.new(data, 1000 + gi * 17, 4, -1, picks)
	m.advance_ai_draft()
	var p := m.players[j]
	var ai: AIController = m.ais[j]
	print("Stratégie : ", picks[j]["nom"])
	print("Équipe : ", ", ".join(p.all_employees().map(func(c): return "%s(%d)" % [c.metier["id"], p.salary(c)])))
	var prochain := 0.0
	var jour := 0
	while not m.game_over and m.day <= jours:
		if m.phase == "day":
			if m.day != jour:
				jour = m.day
				prochain = 0.0
				print("--- jour %d : argent %d, main %d, %d déployés, contrats %s, animaux %d" % [jour, int(p.money), p.hand.size(), p.workers.size(),
					str(p.contracts.map(func(d): return d["nom"])), p.animals.size()])
			if m.time == 0.0 and a.has("marche"):
				for d in p.market_contracts:
					var cout: float = ai._money_cost(d)
					print("    marché %-26s %s %3d argent | plan %s, agrandir %s, motif naturel %s, permis %s, note %.0f, effort %.1f" % [d["nom"], d["palier"], int(cout),
						not ai._plan_enclosure(d).is_empty(), ai._can_extend_for(d), ai._natural_fit(d), ai._strategy_allows(d), ai._contract_score(d, cout), ai._effort_days(d)])
				print("    plancher %d, épargne %d, attractivité %d, limite %d, parc %s, agrandissements %d" % [int(ai._cash_floor()), int(ai.epargne), p.attractiveness(), int(ai._attr_limit()), str(ai.zoo_rect.size), ai.agrandis])
			if m.time >= prochain:
				prochain += tranche
				var t := {}
				for w in p.workers:
					var k := str(w.task.get("kind", w.task.get("type", "libre")))
					if w.unpaid:
						k += "(gratuit)"
					t[k] = int(t.get(k, 0)) + 1
				print("  t=%3d argent %4d bois %3d pierre %3d or %2d murs %3d%% chantiers %2d plans %d attr %2d nourris %d/%d malades %d propreté %d file %d rép %d | %s" % [int(m.time), int(p.money), int(p.stock["bois"]), int(p.stock["pierre"]), int(p.stock["or"]),
					roundi(ai._walls_progress() * 100) if ai.zoo_rect.size != Vector2i.ZERO else -1, p.sites.filter(func(s): return not s.done).size(), ai.plans.size(), p.attractiveness(), p.animals.filter(func(x): return x.fed).size(), p.animals.size(), p.sick_animals().size(), int(p.proprete), p.visitor_queue, p.reputation(), str(t)])
			m.tick(1.0)
		elif m.phase == "night":
			m.start_next_day()
	m.dispose()
	quit(0)
