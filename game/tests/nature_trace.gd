extends SceneTree
## Réserve naturelle : suit une IA soir après soir et dit, pour chaque contrat du marché, si son motif existe près du camp
## (_natural_fit), dans son parc (_compute_plan) ou après un agrandissement (_can_extend_for).
## godot --headless --path game --script res://tests/nature_trace.gd -- --graine=3 --joueur=0 [--jours=8]

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var graine := int(args.get("graine", "3"))
	var j := int(args.get("joueur", "0"))
	var jours := int(args.get("jours", "8"))
	var strategies: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/ia_niveaux.json"))["niveaux"]["difficile"]["strategies"]
	var data := ModesPartie.appliquer(GameData.load_all(), "nature")
	var mt := Match.new(data, graine, 4, -1, strategies.slice(0, 4).map(func(s): return ModesPartie.strategie(s, "nature")), [], "nature")
	while mt.phase == "draft":
		mt.pick_draft(mt.ai_choice())
	var ai: AIController = mt.ais[j]
	var p: GameState = mt.players[j]
	var midi := {}
	while mt.day <= jours and not mt.game_over:
		if mt.phase == "day":
			var avant := p.time
			mt.tick(0.5)
			if avant < mt.day_length * 0.5 and p.time >= mt.day_length * 0.5:
				var t := {}
				for w in p.workers:
					var k := str(w.task.get("type", "rien"))
					if k == "post" or k == "station":
						k += ":" + str(w.task.get("kind", ""))
					t[k] = int(t.get(k, 0)) + 1
				midi = t
			continue
		var z := p.zoo_status()
		print("Soir %d : parc %s, ouvert %s (%s), argent %d, animaux %d, contrats %d, métiers %s" % [mt.day, str(ai.zoo_rect), str(z["open"]), z.get("reason", ""),
			int(p.money), p.animals.size(), p.contracts.size(), str(p.all_employees().map(func(c): return c.metier["id"]))])
		var chantiers := {}
		for st in p.sites:
			if not st.done:
				chantiers[st.def_id()] = int(chantiers.get(st.def_id(), 0)) + 1
		var taches := midi
		print("   en main %s | réservés %d | chantiers %s | stock %s | tâches à midi %s | plans %d" % [str(p.contracts.map(func(c): return c["id"])),
			p.pending_installs.size(), str(chantiers), str(p.stock.keys().map(func(k): return "%s %d" % [k, int(p.stock[k])])), str(taches), ai.plans.size()])
		if args.has("marche"):
			for d in mt.market_contracts:
				var plan: Dictionary = ai._compute_plan(d)
				print("   %-22s %s coût %s | près du camp %s | dans le parc %s | agrandir %s" % [d["id"], d["palier"], str(d["cout"]), str(ai._natural_fit(d)),
					"oui" if not plan.is_empty() else "non", str(ai._can_extend_for(d))])
		mt.start_next_day()
	quit()
