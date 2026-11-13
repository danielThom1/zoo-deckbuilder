extends SceneTree
## Pourquoi l'IA est faible en Réserve naturelle : mêmes graines en course et en nature, 4 IA du niveau difficile,
## relevé chaque soir (zoo ouvert, animaux arrivés, contrats en main non installés, argent, réputation) et à la fin.
## godot --headless --path game --script res://tests/nature_ia.gd -- [--graines=1,2,3] [--jours=10] [--modes=course,nature]

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var graines: Array = Array(str(args.get("graines", "1,2,3")).split(",")).map(func(x): return int(x))
	var jours := int(args.get("jours", "10"))
	var strategies: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/ia_niveaux.json"))["niveaux"]["difficile"]["strategies"]
	for mode in str(args.get("modes", "course,nature")).split(","):
		var tot := {"rep": 0.0, "animaux": 0.0, "contrats": 0.0, "ouvert": 0.0, "n": 0}
		for g in graines:
			var data := ModesPartie.appliquer(GameData.load_all(), mode)
			var strats: Array = strategies.slice(0, 4).map(func(s): return ModesPartie.strategie(s, mode))
			var mt := Match.new(data, g, 4, -1, strats, [], mode)
			while mt.phase == "draft":
				mt.pick_draft(mt.ai_choice())
			var ouverture := [0, 0, 0, 0]
			while mt.day <= jours and not mt.game_over:
				if mt.phase == "day":
					mt.tick(0.5)
				else:
					for k in 4:
						if ouverture[k] == 0 and mt.players[k].zoo_status()["open"]:
							ouverture[k] = mt.day
					mt.start_next_day()
			for k in 4:
				var p: GameState = mt.players[k]
				var ai: AIController = mt.ais[k]
				var arrives := p.animals.filter(func(a): return a.arrived).size()
				var raisons: Array = []
				for c in p.contracts:
					raisons.append("%s (%s)" % [c["id"], "place dans l'enceinte" if not p.enclosure_site(c).is_empty() else "aucune place"])
				print("%s g%d J%d : rép %3d, animaux %d, contrats en main %d, ouvert j%d, argent %d, parc %s | %s" % [mode, g, k, int(p.reputation()), arrives,
					p.contracts.size(), ouverture[k], int(p.money), str(ai.zoo_rect.size), ", ".join(raisons)])
				tot["rep"] += p.reputation()
				tot["animaux"] += arrives
				tot["contrats"] += p.contracts.size()
				tot["ouvert"] += ouverture[k]
				tot["n"] += 1
		print("== %s : rép moyenne %.1f, animaux %.2f, contrats non installés %.2f, ouverture moyenne j%.1f" % [mode, tot["rep"] / tot["n"],
			tot["animaux"] / tot["n"], tot["contrats"] / tot["n"], tot["ouvert"] / tot["n"]])
	quit()
