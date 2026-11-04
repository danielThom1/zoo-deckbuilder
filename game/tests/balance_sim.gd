extends SceneTree
## Parties IA contre IA pour l'équilibrage. Chaque partie oppose 4 IA de stratégies différentes.
##   godot --headless --path game --script res://tests/balance_sim.gd -- --parties=12 --dt=1.0 [--jobs=4] [--detail]
## Les parties sont réparties sur plusieurs processus Godot (--jobs, par défaut la moitié des cœurs logiques).
## Chaque partie est indépendante et déterministe (graine fixe) : le rapport est le même quel que soit --jobs.
## Écrit un rapport dans rapport_equilibrage.md (à la racine du dossier, à côté de GDD.md).

const STRATEGIES := [
	{"nom": "Équilibrée"},
	{"nom": "Marché", "marche": true},
	{"nom": "Rush or", "rush_or": true},
	{"nom": "Spécialisation", "specialisation": true},
	{"nom": "Formation", "formation": true},
	{"nom": "Cartes", "cartes": true},
	{"nom": "Parc évolutif", "taille_zoo": "evolutif"},
	{"nom": "Affinités", "affinite": true},
	{"nom": "Haut de gamme", "preference_palier": 3.0, "palier_min": 2, "reserve": 15},
	{"nom": "Petits contrats", "preference_palier": 0.4, "contrats_en_attente_max": 3},
	{"nom": "Grand parc", "taille_zoo": "grand"},
	{"nom": "Lobbying", "lobbyistes_max": 2},
	{"nom": "Camp amélioré", "camp": 1},
	{"nom": "Grand camp", "camp": 2},
	{"nom": "Fast expand", "fast_expand": true, "camp": 1},
	{"nom": "Rush or + route", "rush_or": true, "route_mine": true},
	{"nom": "Spectacle", "spectacle": true},
	{"nom": "Formation légendaire", "formation": true, "camp": 1},
	{"nom": "Ancienne IA", "adaptatif": false, "agrandir": false, "score_simple": true},
	{"nom": "Sans agrandir", "agrandir": false},
	{"nom": "Même type", "meme_type": true},
	{"nom": "Prédateurs", "type_cible": "predateur"},
	{"nom": "Aériens", "type_cible": "aerien"},
	{"nom": "Aquatiques", "type_cible": "aquatique"},
	{"nom": "Herbivores", "type_cible": "herbivore"},
	{"nom": "Afrique", "continent_cible": "Afrique"},
	{"nom": "Amérique", "continent_cible": "Amerique"},
	{"nom": "Asie", "continent_cible": "Asie"},
	{"nom": "Europe", "continent_cible": "Europe"},
]


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var n_games := int(args.get("parties", "12"))
	var dt := float(args.get("dt", "1.0"))
	var detail := args.has("detail")
	var data := GameData.load_all()
	var dir := ProjectSettings.globalize_path("user://balance_sim")

	# Processus de travail : joue les parties gi ≡ lot (mod lots), un fichier de résultat par partie.
	if args.has("lot"):
		var lots := int(args["lots"])
		for gi in range(int(args["lot"]), n_games, lots):
			_save(dir, gi, _play(gi, data, dt, detail))
		quit(0)
		return

	var jobs := clampi(int(args.get("jobs", str(maxi(1, OS.get_processor_count() / 2)))), 1, maxi(1, n_games))
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	var t0 := Time.get_ticks_msec()
	var results := {}  # index de partie -> résultat
	if jobs == 1:
		for gi in n_games:
			results[gi] = _play(gi, data, dt, detail)
			_print_game(results[gi], n_games, t0)
	else:
		print("%d parties réparties sur %d processus…" % [n_games, jobs])
		var pids: Array[int] = []
		for lot in jobs:
			var a := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/balance_sim.gd", "--",
				"--parties=%d" % n_games, "--dt=%s" % str(dt), "--lot=%d" % lot, "--lots=%d" % jobs]
			if detail:
				a.append("--detail")
			pids.append(OS.create_process(OS.get_executable_path(), a))
		while results.size() < n_games:
			var all_done := pids.all(func(p): return not OS.is_process_running(p))
			for f in DirAccess.get_files_at(dir):
				var gi := f.get_basename().to_int()
				if f.ends_with(".json") and not results.has(gi):
					results[gi] = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
					_print_game(results[gi], n_games, t0)
			if all_done and results.size() < n_games:
				printerr("Échec : %d partie(s) sur %d sans résultat (un processus s'est arrêté)." % [n_games - results.size(), n_games])
				quit(1)
				return
			OS.delay_msec(250)

	_write_report(results, n_games, dt, data)
	print("Durée totale : %.0f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit(0)


## Joue une partie et renvoie un résultat sérialisable en JSON (pour les processus de travail).
func _play(gi: int, data: Dictionary, dt: float, detail: bool) -> Dictionary:
	var t_start := Time.get_ticks_msec()
	var seed := 1000 + gi * 17
	var picks := []
	for k in 4:
		# 4 stratégies différentes, chacune autant de fois ; l'écart varie pour qu'elles ne croisent pas toujours les mêmes.
		picks.append(STRATEGIES[(gi + k * (1 + gi % 5)) % STRATEGIES.size()])
	var m := Match.new(data, seed, 4, -1, picks)
	var first_counts := [0, 0, 0, 0]
	m.advance_ai_draft()
	while not m.game_over:
		if m.phase == "day":
			m.tick(dt)
		elif m.phase == "night":
			first_counts[m.night_order[0]] += 1
			m.start_next_day()
	var lines: Array[String] = []
	if detail:
		for row in m.history:
			var cells := []
			for i in 4:
				var e: Dictionary = row[i]
				cells.append("%s: rép %d, %d€, %d anim, %d empl" % [picks[i]["nom"], e["rep"], int(e["money"]), e["animals"], e["employees"]])
			lines.append("  jour %d | %s" % [row[0]["day"], " | ".join(cells)])
		for i in 4:
			var feasible := 0
			for d in data["animals"]["animaux"]:
				if not m.ais[i]._plan_enclosure(d).is_empty():
					feasible += 1
			lines.append("  %s : %d espèces encore plaçables dans l'enceinte, %d plans en cours" % [picks[i]["nom"], feasible, m.ais[i].plans.size()])
		for i in 4:
			var p := m.players[i]
			var ai: AIController = m.ais[i]
			var walls := roundi(ai._walls_progress() * 100) if ai.zoo_rect.size != Vector2i.ZERO else -1
			var plans: Array = p.contracts.map(func(d): return "%s:%s" % [d["nom"], "plan" if not ai._plan_enclosure(d).is_empty() else "SANS PLAN"])
			lines.append("  ETAT|%s|rép %d|argent %d|animaux %d|murs %d %%|route %s|aménageur %s|zoo : %s|contrats %s|chantiers ouverts %d|stock %s" % [
				picks[i]["nom"], p.reputation(), int(p.money), p.animals.size(), walls, "oui" if not p.visitor_path().is_empty() else "non",
				"oui" if ai._has_landscaper() else "non", "ouvert" if p.zoo_status()["open"] else p.zoo_status()["reason"],
				str(plans), p.sites.filter(func(s): return not s.done).size(), str(p.stock)])
	var players := []
	for i in 4:
		var p := m.players[i]
		players.append({"nom": picks[i]["nom"], "rep": p.reputation(), "money": p.money, "animals": p.animals.size(),
			"employees": p.employees(), "influence": p.influence, "first_buyer": first_counts[i],
			"paliers": p.animals.map(func(a): return a.def["palier"]), "especes": p.animals.map(func(a): return a.def["nom"]),
			"entrepots": p.sites.filter(func(st): return st.done and st.def_id() == "entrepot").size(),
			"agrandissements": m.ais[i].agrandis, "parc": m.ais[i].zoo_rect.get_area(),
			"sources": p.rep_sources})
	var history := []
	for row in m.history:
		history.append(row.map(func(e): return {"day": e["day"], "rep": e["rep"], "money": e["money"], "visitors": e["visitors"]}))
	var out := {"gi": gi, "seed": seed, "day": m.day, "winner": m.winner, "players": players, "history": history,
		"detail": lines, "duree": (Time.get_ticks_msec() - t_start) / 1000.0}
	m.dispose()
	return out


## Écrit le résultat d'une partie (fichier temporaire puis renommé : le processus principal ne lit jamais un fichier incomplet).
func _save(dir: String, gi: int, result: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var tmp := dir.path_join("%d.tmp" % gi)
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(result))
	f.close()
	DirAccess.rename_absolute(tmp, dir.path_join("%d.json" % gi))


func _print_game(r: Dictionary, n_games: int, t0: int) -> void:
	var w: Dictionary = r["players"][int(r["winner"])]
	print("Partie %d/%d (graine %d) : fin au jour %d, gagnant %s (%d) — %s  [%.0f s, total %.0f s]" % [
		int(r["gi"]) + 1, n_games, int(r["seed"]), int(r["day"]), w["nom"], int(w["rep"]), _line(r),
		float(r["duree"]), (Time.get_ticks_msec() - t0) / 1000.0])
	for l in r["detail"]:
		print(l)


func _line(r: Dictionary) -> String:
	return " · ".join(r["players"].map(func(p): return "%s %d" % [p["nom"], int(p["rep"])]))


## Agrège les résultats (dans l'ordre des parties) et écrit le rapport.
func _write_report(results: Dictionary, n_games: int, dt: float, data: Dictionary) -> void:
	var stats := {}
	for st in STRATEGIES:
		stats[st["nom"]] = {"games": 0, "wins": 0, "rep": 0.0, "money": 0.0, "animals": 0.0, "tiers": {"T1": 0, "T2": 0, "T3": 0},
			"employees": 0.0, "influence": 0.0, "first_buyer": 0, "visitors": 0.0, "win_days": [], "entrepots": 0.0, "agrandissements": 0.0, "parc": 0.0}
	var games := []
	var rep_by_day := {}  # jour -> somme des réputations (moyenne sur tous les joueurs)
	var money_by_day := {}
	var players_by_day := {}
	var contract_counts := {}
	var rep_sources := {}
	for gi in n_games:
		var r: Dictionary = results[gi]
		for i in 4:
			var p: Dictionary = r["players"][i]
			var s: Dictionary = stats[p["nom"]]
			s["games"] += 1
			s["rep"] += p["rep"]
			s["money"] += p["money"]
			s["animals"] += p["animals"]
			s["employees"] += p["employees"]
			s["influence"] += p["influence"]
			s["first_buyer"] += int(p["first_buyer"])
			s["entrepots"] += float(p.get("entrepots", 0))
			s["agrandissements"] += float(p.get("agrandissements", 0))
			s["parc"] += float(p.get("parc", 0))
			var src: Dictionary = p.get("sources", {})
			for k in src:
				rep_sources[k] = float(rep_sources.get(k, 0.0)) + float(src[k])
			for t in p["paliers"]:
				s["tiers"][t] += 1
			for nm in p["especes"]:
				contract_counts[nm] = contract_counts.get(nm, 0) + 1
			if i == int(r["winner"]) and int(p["rep"]) >= int(data["buildings"]["partie"]["objectif_reputation"]):
				s["wins"] += 1
				s["win_days"].append(int(r["day"]))
		for row in r["history"]:
			for i in row.size():
				var e: Dictionary = row[i]
				var d := int(e["day"])
				rep_by_day[d] = rep_by_day.get(d, 0.0) + e["rep"]
				money_by_day[d] = money_by_day.get(d, 0.0) + e["money"]
				players_by_day[d] = players_by_day.get(d, 0) + 1
				stats[r["players"][i]["nom"]]["visitors"] += e["visitors"]
		var w: Dictionary = r["players"][int(r["winner"])]
		games.append({"seed": int(r["seed"]), "day": int(r["day"]), "winner": w["nom"], "rep": int(w["rep"]), "line": _line(r)})

	var L: Array[String] = []
	L.append("# Rapport d'équilibrage : parties IA contre IA")
	L.append("")
	L.append("%d parties à 4 IA, objectif %d de réputation, fin forcée au jour %d, pas de simulation %.1f s." % [
		games.size(), int(data["buildings"]["partie"]["objectif_reputation"]), int(data["buildings"]["partie"]["jour_max"]), dt])
	L.append("")
	L.append("## Vitesse : victoires à %d et jour de victoire" % int(data["buildings"]["partie"]["objectif_reputation"]))
	L.append("")
	L.append("Classement par taux de victoire, puis par jour moyen de victoire (plus tôt = mieux).")
	L.append("")
	L.append("| Stratégie | Victoires | Taux | Jour moyen de victoire | Victoire la plus rapide | Réputation moyenne en fin de partie | Animaux | T1 / T2 / T3 | Agrandissements | Parc (cases) | Entrepôts |")
	L.append("|---|---|---|---|---|---|---|---|---|---|---|")
	var ranking: Array = stats.keys()
	ranking.sort_custom(func(a, b):
		var sa: Dictionary = stats[a]
		var sb: Dictionary = stats[b]
		var ra := float(sa["wins"]) / maxi(1, sa["games"])
		var rb := float(sb["wins"]) / maxi(1, sb["games"])
		if not is_equal_approx(ra, rb):
			return ra > rb
		var da: float = 99.0 if sa["win_days"].is_empty() else float(sa["win_days"].reduce(func(x, y): return x + y, 0)) / sa["win_days"].size()
		var db: float = 99.0 if sb["win_days"].is_empty() else float(sb["win_days"].reduce(func(x, y): return x + y, 0)) / sb["win_days"].size()
		return da < db)
	for nom in ranking:
		var s: Dictionary = stats[nom]
		var n: int = maxi(1, s["games"])
		var wd: Array = s["win_days"]
		L.append("| %s | %d / %d | %d %% | %s | %s | %.0f | %.1f | %.1f / %.1f / %.1f | %.1f | %.0f | %.1f |" % [nom, s["wins"], s["games"], roundi(100.0 * s["wins"] / n),
			"—" if wd.is_empty() else "%.1f" % (float(wd.reduce(func(x, y): return x + y, 0)) / wd.size()),
			"—" if wd.is_empty() else "jour %d" % wd.min(), s["rep"] / n, s["animals"] / n,
			s["tiers"]["T1"] / float(n), s["tiers"]["T2"] / float(n), s["tiers"]["T3"] / float(n),
			s["agrandissements"] / n, s["parc"] / n, s["entrepots"] / n])
	var record: Dictionary = {}
	for gm in games:
		if record.is_empty() or gm["day"] < record["day"]:
			record = gm
	if not record.is_empty():
		L.append("")
		L.append("**Record** : partie terminée au jour %d, gagnée par %s (%d de réputation, graine %d)." % [
			record["day"], record["winner"], record["rep"], record["seed"]])
	L.append("")
	L.append("## D'où vient la réputation")
	L.append("")
	var rep_total := 0.0
	for k in rep_sources:
		rep_total += float(rep_sources[k])
	for k in rep_sources:
		L.append("- %s : %d %%" % [k, roundi(100.0 * float(rep_sources[k]) / maxf(1.0, rep_total))])
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
