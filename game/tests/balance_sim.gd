extends SceneTree
## Parties IA contre IA pour l'équilibrage. Chaque partie oppose 4 IA de stratégies différentes.
##   godot --headless --path game --script res://tests/balance_sim.gd -- --parties=12 --dt=1.0
## Écrit un rapport dans rapport_equilibrage.md (à la racine du dossier, à côté de GDD.md).

const STRATEGIES := [
	{"nom": "Équilibrée"},
	{"nom": "Petit parc", "taille_zoo": "petit"},
	{"nom": "Grand parc", "taille_zoo": "grand"},
	{"nom": "Parc évolutif", "taille_zoo": "evolutif"},
	{"nom": "Gros contrats", "preference_palier": 2.2, "reserve": 15},
	{"nom": "Mine d'or", "mine_prioritaire": true},
	{"nom": "Lobbying", "lobbyistes_max": 2},
	{"nom": "Économe", "boutique": false, "mine": false},
]


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var n_games := int(args.get("parties", "12"))
	var dt := float(args.get("dt", "1.0"))
	var data := GameData.load_all()

	var stats := {}
	for st in STRATEGIES:
		stats[st["nom"]] = {"games": 0, "wins": 0, "rep": 0.0, "money": 0.0, "animals": 0.0, "tiers": {"T1": 0, "T2": 0, "T3": 0},
			"employees": 0.0, "influence": 0.0, "first_buyer": 0, "visitors": 0.0}
	var games := []
	var rep_by_day := {}  # jour -> somme des réputations (moyenne sur tous les joueurs)
	var money_by_day := {}
	var players_by_day := {}
	var contract_counts := {}
	var t0 := Time.get_ticks_msec()

	for gi in n_games:
		var seed := 1000 + gi * 17
		var picks := []
		for k in 4:
			picks.append(STRATEGIES[(gi + k) % STRATEGIES.size()])  # 4 stratégies différentes, chacune autant de fois
		var m := Match.new(data, seed, 4, -1, picks)
		var first_counts := [0, 0, 0, 0]
		m.advance_ai_draft()
		while not m.game_over:
			if m.phase == "day":
				m.tick(dt)
			elif m.phase == "night":
				first_counts[m.night_order[0]] += 1
				m.start_next_day()
		if args.has("detail"):
			for row in m.history:
				var cells := []
				for i in 4:
					var e: Dictionary = row[i]
					cells.append("%s: rép %d, %d€, %d anim, %d empl" % [picks[i]["nom"], e["rep"], int(e["money"]), e["animals"], e["employees"]])
				print("  jour %d | %s" % [row[0]["day"], " | ".join(cells)])
			for i in 4:
				var feasible := 0
				for d in data["animals"]["animaux"]:
					if not m.ais[i]._plan_enclosure(d).is_empty():
						feasible += 1
				print("  %s : %d espèces encore plaçables dans l'enceinte, %d plans en cours" % [picks[i]["nom"], feasible, m.ais[i].plans.size()])
			for i in 4:
				var p := m.players[i]
				print("  %s : zoo %s, entrée %s, %d chantiers ouverts, %d terminés, contrats %s, stock %s" % [
					picks[i]["nom"], str(m.ais[i].zoo_rect), str(m.ais[i].entrance), p.sites.filter(func(s): return not s.done).size(),
					p.sites.filter(func(s): return s.done).size(), str(p.contracts.map(func(d): return d["nom"])), str(p.stock)])
		var line := []
		for i in 4:
			var p := m.players[i]
			var nom: String = picks[i]["nom"]
			var s: Dictionary = stats[nom]
			s["games"] += 1
			s["rep"] += p.reputation()
			s["money"] += p.money
			s["animals"] += p.animals.size()
			s["employees"] += p.employees()
			s["influence"] += p.influence
			s["first_buyer"] += first_counts[i]
			for a in p.animals:
				s["tiers"][a.def["palier"]] += 1
				contract_counts[a.def["nom"]] = contract_counts.get(a.def["nom"], 0) + 1
			if i == m.winner:
				s["wins"] += 1
			line.append("%s %d" % [nom, p.reputation()])
		for row in m.history:
			for e in row:
				rep_by_day[e["day"]] = rep_by_day.get(e["day"], 0.0) + e["rep"]
				money_by_day[e["day"]] = money_by_day.get(e["day"], 0.0) + e["money"]
				players_by_day[e["day"]] = players_by_day.get(e["day"], 0) + 1
				stats[picks[row.find(e)]["nom"]]["visitors"] += e["visitors"]
		games.append({"seed": seed, "day": m.day, "winner": picks[m.winner]["nom"], "rep": m.players[m.winner].reputation(), "line": " · ".join(line)})
		print("Partie %d/%d (graine %d) : fin au jour %d, gagnant %s (%d) — %s  [%.0f s]" % [
			gi + 1, n_games, seed, m.day, picks[m.winner]["nom"], m.players[m.winner].reputation(), " · ".join(line),
			(Time.get_ticks_msec() - t0) / 1000.0])
		m.dispose()

	_write_report(stats, games, rep_by_day, money_by_day, players_by_day, contract_counts, dt, data)
	quit(0)


func _write_report(stats: Dictionary, games: Array, rep_by_day: Dictionary, money_by_day: Dictionary,
		players_by_day: Dictionary, contract_counts: Dictionary, dt: float, data: Dictionary) -> void:
	var L: Array[String] = []
	L.append("# Rapport d'équilibrage : parties IA contre IA")
	L.append("")
	L.append("%d parties à 4 IA, objectif %d de réputation, fin forcée au jour %d, pas de simulation %.1f s." % [
		games.size(), int(data["buildings"]["partie"]["objectif_reputation"]), int(data["buildings"]["partie"]["jour_max"]), dt])
	L.append("")
	L.append("## Résultats par stratégie")
	L.append("")
	L.append("| Stratégie | Parties | Victoires | Taux | Réputation finale | Argent final | Animaux | T1 / T2 / T3 | Employés | Influence | 1er au marché (nuits) | Visiteurs cumulés |")
	L.append("|---|---|---|---|---|---|---|---|---|---|---|---|")
	for nom in stats:
		var s: Dictionary = stats[nom]
		var n: int = maxi(1, s["games"])
		L.append("| %s | %d | %d | %d %% | %.0f | %.0f | %.1f | %.1f / %.1f / %.1f | %.1f | %.1f | %.1f | %.0f |" % [
			nom, s["games"], s["wins"], roundi(100.0 * s["wins"] / n), s["rep"] / n, s["money"] / n, s["animals"] / n,
			s["tiers"]["T1"] / float(n), s["tiers"]["T2"] / float(n), s["tiers"]["T3"] / float(n),
			s["employees"] / n, s["influence"] / n, s["first_buyer"] / float(n), s["visitors"] / n])
	L.append("")
	L.append("## Progression moyenne (tous joueurs)")
	L.append("")
	L.append("| Jour | Réputation moyenne | Argent moyen |")
	L.append("|---|---|---|")
	var days := rep_by_day.keys()
	days.sort()
	for d in days:
		var n: int = players_by_day[d]
		L.append("| %d | %.1f | %.0f |" % [d, rep_by_day[d] / n, money_by_day[d] / n])
	L.append("")
	L.append("## Animaux les plus installés")
	L.append("")
	var names := contract_counts.keys()
	names.sort_custom(func(a, b): return contract_counts[a] > contract_counts[b])
	for nm in names.slice(0, 12):
		L.append("- %s : %d" % [nm, contract_counts[nm]])
	L.append("")
	L.append("## Détail des parties")
	L.append("")
	for gm in games:
		L.append("- Graine %d : fin au jour %d, **%s** gagne (%d). %s" % [gm["seed"], gm["day"], gm["winner"], gm["rep"], gm["line"]])
	var path := ProjectSettings.globalize_path("res://").path_join("../rapport_equilibrage.md")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(L) + "\n")
	f.close()
	print("Rapport écrit : ", path)
