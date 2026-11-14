extends SceneTree
## Pourquoi une IA ne mobilise que 2 ou 3 collaborateurs : chaque matin et à midi, pour chaque IA, taille de l'équipe,
## de la main, cartes mobilisées, cédées, argent, plancher d'argent de l'IA, salaires.
## godot --headless --path game --script res://tests/trace_equipe.gd -- --graines=1-6 [--niveau=difficile] [--jours=12] [--detail]

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var bornes := str(args.get("graines", "1-6")).split("-")
	var strats: Array = load("res://scripts/main.gd").strategies_du_niveau(str(args.get("niveau", "difficile")))
	var jours := int(args.get("jours", "12"))
	var data := GameData.load_all()
	var cas := 0
	var total := 0
	for g in range(int(bornes[0]), int(bornes[-1]) + 1):
		var mt := Match.new(data, g, 4, -1, strats.slice(0, 4), [], "course")
		while mt.phase == "draft":
			mt.pick_draft(mt.ai_choice())
		var midi_fait := false
		while not mt.game_over and mt.day <= jours:
			if mt.phase == "day":
				var p0: GameState = mt.players[0]
				if not midi_fait and p0.time >= mt.day_length * 0.4:
					midi_fait = true
					for k in 4:
						var p: GameState = mt.players[k]
						var ai: AIController = mt.ais[k]
						var mob := p.workers.size()
						var main_nm: Array = p.hand.filter(func(c): return not c.is_action() and not c.deployed)
						var cedees := p.journal_cartes.filter(func(e): return e["id"] == "carte_cedee" and int(e["day"]) == mt.day).size()
						total += 1
						if mob <= 3 and mt.day >= 4:
							cas += 1
						if args.has("detail") or (mob <= 3 and mt.day >= 4):
							print("g%d J%d jour %d : équipe %d, main %d (taille %d), mobilisés %d, non mobilisés %d, cédées %d, argent %d, plancher %d, salaires main %s | pioche %d défausse %d | actions en main %d, dans le paquet %d, jouées aujourd'hui %d" % [
								g, k, mt.day, p.all_employees().size(), p.hand.size(), p.hand_size(), mob, main_nm.size(), cedees, int(p.money),
								int(ai._cash_floor()), str(main_nm.map(func(c): return p.salary(c))), p.deck.size(), p.discard.size(),
								p.hand.filter(func(c): return c.is_action()).size(), (p.deck + p.discard + p.hand).filter(func(c): return c.is_action()).size(),
								p.journal_cartes.filter(func(e): return int(e["day"]) == mt.day and not e["id"] in ["carte_cedee", "agence", "cabinet"]).size()])
				mt.tick(1.0)
			else:
				midi_fait = false
				mt.start_next_day()
	print("TOTAL : %d relevés (IA × jour), dont %d à 3 collaborateurs ou moins mobilisés à partir du jour 4" % [total, cas])
	quit()
