extends SceneTree
## Jour moyen de victoire d'un niveau d'IA : 4 IA du même niveau s'affrontent sur une série de cartes, jusqu'à la victoire
## (objectif de réputation) ou au dernier jour. Une ligne RES|… par partie, puis un résumé.
## godot --headless --path game --script res://tests/mesure_niveaux.gd -- --niveau=difficile [--argent=50] [--graines=1-10]
##   --argent : argent de départ imposé à chaque IA (sinon celui du niveau : 50 en Difficile, 30 ailleurs)
##   --adverses=fichier.json ({"strategies": [...]}) : duel, les joueurs 1 et 3 prennent ces stratégies (même argent)

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var niveau := str(args.get("niveau", "difficile"))
	var bornes := str(args.get("graines", "1-10")).split("-")
	var de := int(bornes[0])
	var a_ := int(bornes[1]) if bornes.size() > 1 else de
	var strats: Array = load("res://scripts/main.gd").strategies_du_niveau(niveau)
	if args.has("argent"):
		strats = strats.map(func(s):
			var d: Dictionary = s.duplicate(true)
			d["argent_depart"] = int(args["argent"])
			return d)
	if args.has("adverses"):
		var autres: Array = JSON.parse_string(FileAccess.get_file_as_string(str(args["adverses"])))["strategies"]
		autres = autres.map(func(s):
			var d: Dictionary = s.duplicate(true)
			if args.has("argent"):
				d["argent_depart"] = int(args["argent"])
			return d)
		strats = [strats[0], autres[0], strats[1 % strats.size()], autres[1 % autres.size()]]
	var data := GameData.load_all()
	var jour_max := int(data["buildings"]["partie"]["jour_max"])
	for g in range(de, a_ + 1):
		var t0 := Time.get_ticks_msec()
		var mt := Match.new(data, g, 4, -1, strats.slice(0, 4), [], "course")
		while mt.phase == "draft":
			mt.pick_draft(mt.ai_choice())
		var ouverture := [0, 0, 0, 0]
		while not mt.game_over and mt.day <= jour_max + 1:
			if mt.phase == "day":
				mt.tick(1.0)
			else:
				for k in 4:
					if ouverture[k] == 0 and mt.players[k].zoo_status()["open"]:
						ouverture[k] = mt.day
				mt.start_next_day()
		var reps: Array = mt.players.map(func(p): return int(p.reputation()))
		var gagne := mt.winner >= 0 and mt.players[mt.winner].reputation() >= float(data["buildings"]["partie"]["objectif_reputation"])
		print("RES|%d|%d|%d|%d|%s|%s|%d" % [g, mt.day, mt.winner, 1 if gagne else 0, ",".join(reps.map(func(x): return str(x))),
			",".join(ouverture.map(func(x): return str(x))), (Time.get_ticks_msec() - t0) / 1000])
	quit()
