extends SceneTree
## IA qui apprend par évolution : une population de stratégies (génomes : réglages de l'IA et préférences de métiers)
## joue des parties à 4 ; les meilleures sont gardées, croisées et légèrement modifiées, génération après génération.
##
##   godot --headless --path game --script res://tests/evolution.gd -- --generations=20 --population=16 --parties=6
## (--parties : parties jouées par génome et par génération ; --jobs=N processus en parallèle)
## Écrit rapport_evolution.md (à la racine) et game/data/ia_evolution.json (meilleurs génomes, réutilisables par l'IA).

const BOOLS := ["marche", "rush_or", "formation", "cartes", "spectacle", "affinite", "boutique", "mine", "specialisation"]
const TAILLES := ["moyen", "grand", "evolutif"]
## Plages des réglages numériques : [min, max, entier ?]
const NUMS := {
	"reserve": [0.0, 40.0, false], "preference_palier": [0.3, 3.0, false], "contrats_en_attente_max": [1, 4, true],
	"lobbyistes_max": [0, 3, true], "maisons_max": [1, 8, true], "camp": [0, 2, true], "palier_min": [1, 2, true],
}

var data: Dictionary
var jobs_ids: Array = []
var rng := RandomNumberGenerator.new()


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	data = GameData.load_all()
	for m in data["workers"]["metiers"]:
		jobs_ids.append(m["id"])
	var dir := ProjectSettings.globalize_path("user://evolution")

	# Processus de travail : joue les parties de son lot (fichier matches.json) et écrit un résultat par partie.
	if args.has("lot"):
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("matches.json")))
		var lots := int(args["lots"])
		for k in range(int(args["lot"]), spec["matches"].size(), lots):
			var mm: Dictionary = spec["matches"][k]
			var res := _play(mm["seed"], mm["genomes"])
			_save(dir, k, res)
		quit(0)
		return

	rng.seed = int(args.get("seed", "2026"))
	var n_gen := int(args.get("generations", "20"))
	var n_pop := int(args.get("population", "16"))
	var per := int(args.get("parties", "6"))
	var jobs := int(args.get("jobs", str(maxi(1, OS.get_processor_count() / 2))))
	DirAccess.make_dir_recursive_absolute(dir)
	var pop: Array = _initial_population(n_pop)
	var history: Array = []
	var t0 := Time.get_ticks_msec()
	var scores: Array = []
	for gen in n_gen:
		scores = _evaluate(pop, per, jobs, dir, gen)
		var order := range(pop.size())
		order.sort_custom(func(a, b): return scores[a]["fitness"] > scores[b]["fitness"])
		var best: Dictionary = scores[order[0]]
		history.append({"gen": gen, "best": best, "mean_wins": _mean(scores.map(func(s): return s["wins"]))})
		print("Génération %d : meilleur %.2f (victoires %d %%, jour moyen %.1f, rép. %.0f) — %s · %.0f s" % [
			gen + 1, best["fitness"], roundi(100.0 * best["wins"]), best["win_day"], best["rep"], _describe(pop[order[0]]),
			(Time.get_ticks_msec() - t0) / 1000.0])
		if gen < n_gen - 1:
			pop = _next_generation(pop, order)
	_write_report(pop, scores, history, n_gen, n_pop, per)
	quit(0)


# --- Génomes -----------------------------------------------------------------------------------------

func _initial_population(n: int) -> Array:
	var pop: Array = []
	# On part des stratégies écrites à la main, puis des génomes au hasard.
	var seeds := [{}, {"rush_or": true}, {"camp": 1}, {"preference_palier": 0.4, "contrats_en_attente_max": 3},
		{"formation": true, "camp": 1}, {"spectacle": true}, {"lobbyistes_max": 2}, {"cartes": true}]
	for s in seeds:
		if pop.size() < n:
			var g := _random_genome()
			for k in s:
				g[k] = s[k]
			pop.append(g)
	while pop.size() < n:
		pop.append(_random_genome())
	return pop


func _random_genome() -> Dictionary:
	var g := {"nom": "", "taille_zoo": TAILLES[rng.randi_range(0, TAILLES.size() - 1)], "poids_metiers": {}}
	for k in NUMS:
		var r: Array = NUMS[k]
		g[k] = rng.randi_range(int(r[0]), int(r[1])) if r[2] else rng.randf_range(float(r[0]), float(r[1]))
	for b in BOOLS:
		g[b] = rng.randf() < (0.8 if b in ["boutique", "mine"] else (0.05 if b == "specialisation" else 0.25))
	for j in jobs_ids:
		g["poids_metiers"][j] = 0.0
	return g


func _mutate(g: Dictionary, rate := 0.25) -> Dictionary:
	var c: Dictionary = g.duplicate(true)
	for k in NUMS:
		if rng.randf() < rate:
			var r: Array = NUMS[k]
			if r[2]:
				c[k] = clampi(int(c[k]) + rng.randi_range(-1, 1), int(r[0]), int(r[1]))
			else:
				c[k] = clampf(float(c[k]) + rng.randfn(0.0, (float(r[1]) - float(r[0])) * 0.15), float(r[0]), float(r[1]))
	for b in BOOLS:
		if rng.randf() < rate * 0.4:
			c[b] = not c[b]
	if rng.randf() < rate * 0.3:
		c["taille_zoo"] = TAILLES[rng.randi_range(0, TAILLES.size() - 1)]
	for j in jobs_ids:
		if rng.randf() < rate * 0.5:
			c["poids_metiers"][j] = clampf(float(c["poids_metiers"][j]) + rng.randfn(0.0, 0.5), -2.0, 2.0)
	return c


func _cross(a: Dictionary, b: Dictionary) -> Dictionary:
	var c: Dictionary = a.duplicate(true)
	for k in a:
		if k != "poids_metiers" and rng.randf() < 0.5:
			c[k] = b[k]
	for j in jobs_ids:
		if rng.randf() < 0.5:
			c["poids_metiers"][j] = b["poids_metiers"][j]
	return c


## Élitisme : les 4 meilleurs restent ; le reste naît de deux parents tirés parmi la meilleure moitié, puis mute.
func _next_generation(pop: Array, order: Array) -> Array:
	var nxt: Array = []
	var elite := 4
	for k in elite:
		nxt.append(pop[order[k]].duplicate(true))
	var half := pop.size() / 2
	while nxt.size() < pop.size():
		var a: Dictionary = pop[order[rng.randi_range(0, half - 1)]]
		var b: Dictionary = pop[order[rng.randi_range(0, half - 1)]]
		nxt.append(_mutate(_cross(a, b)))
	return nxt


func _describe(g: Dictionary) -> String:
	var on: Array[String] = []
	for b in BOOLS:
		if g[b] and not b in ["boutique", "mine"]:
			on.append(b)
	var jobs := (g["poids_metiers"] as Dictionary).keys()
	jobs.sort_custom(func(x, y): return g["poids_metiers"][x] > g["poids_metiers"][y])
	return "parc %s, palier %.1f, réserve %d, lobby %d, camp %d, contrats %d%s · métiers favoris : %s" % [
		g["taille_zoo"], g["preference_palier"], int(g["reserve"]), g["lobbyistes_max"], g["camp"], g["contrats_en_attente_max"],
		(", " + ", ".join(on)) if not on.is_empty() else "", ", ".join(jobs.slice(0, 3))]


# --- Évaluation --------------------------------------------------------------------------------------

## Chaque génome joue `per` parties contre des adversaires tirés dans la population. Score : victoires (×3),
## vitesse de victoire, réputation finale.
func _evaluate(pop: Array, per: int, jobs: int, dir: String, gen: int) -> Array:
	var slots: Array = []
	for k in per:
		var idx := range(pop.size())
		idx.shuffle()
		slots.append_array(idx)
	var matches: Array = []
	for k in range(0, slots.size() - 3, 4):
		var ids: Array = slots.slice(k, k + 4)
		matches.append({"seed": 5000 + gen * 977 + k, "ids": ids, "genomes": ids.map(func(i): return pop[i])})
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	var fm := FileAccess.open(dir.path_join("matches.json"), FileAccess.WRITE)
	fm.store_string(JSON.stringify({"matches": matches}))
	fm.close()
	var pids: Array[int] = []
	for lot in jobs:
		pids.append(OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tests/evolution.gd", "--", "--lot=%d" % lot, "--lots=%d" % jobs]))
	var results := {}
	while results.size() < matches.size():
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".res"):
				var k := f.get_basename().to_int()
				if not results.has(k):
					results[k] = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
		if pids.all(func(p): return not OS.is_process_running(p)) and results.size() < matches.size():
			for f in DirAccess.get_files_at(dir):
				if f.ends_with(".res"):
					results[f.get_basename().to_int()] = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
			break
		OS.delay_msec(300)
	var sc: Array = []
	for i in pop.size():
		sc.append({"games": 0, "wins": 0.0, "rep": 0.0, "win_days": [], "fitness": 0.0, "win_day": 99.0})
	for k in results:
		var r: Dictionary = results[k]
		var ids: Array = matches[k]["ids"]
		for p in 4:
			var s: Dictionary = sc[ids[p]]
			s["games"] += 1
			s["rep"] += float(r["rep"][p])
			if int(r["winner"]) == p and float(r["rep"][p]) >= float(data["buildings"]["partie"]["objectif_reputation"]):
				s["wins"] += 1.0
				s["win_days"].append(int(r["day"]))
	var jmax := float(data["buildings"]["partie"]["jour_max"])
	for s in sc:
		var n := maxf(1.0, s["games"])
		s["rep"] /= n
		s["wins"] /= n
		if not s["win_days"].is_empty():
			s["win_day"] = _mean(s["win_days"])
		s["fitness"] = s["wins"] * 3.0 + (jmax - s["win_day"]) / jmax * s["wins"] * 2.0 + s["rep"] / 100.0
	return sc


func _play(seed: int, genomes: Array) -> Dictionary:
	var m := Match.new(data, seed, 4, -1, genomes)
	m.advance_ai_draft()
	while not m.game_over:
		if m.phase == "day":
			m.tick(1.0)
		elif m.phase == "night":
			m.start_next_day()
	var out := {"day": m.day, "winner": m.winner, "rep": m.players.map(func(p): return p.rep_points),
		"jobs": m.players.map(func(p): return p.all_employees().map(func(c): return c.metier["id"]))}
	m.dispose()
	return out


func _save(dir: String, k: int, result: Dictionary) -> void:
	var tmp := dir.path_join("%d.tmp" % k)
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(result))
	f.close()
	DirAccess.rename_absolute(tmp, dir.path_join("%d.res" % k))


func _mean(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var t := 0.0
	for x in a:
		t += float(x)
	return t / a.size()


# --- Rapport -----------------------------------------------------------------------------------------

func _write_report(pop: Array, scores: Array, history: Array, n_gen: int, n_pop: int, per: int) -> void:
	var order := range(pop.size())
	order.sort_custom(func(a, b): return scores[a]["fitness"] > scores[b]["fitness"])
	var L: Array[String] = ["# IA évolutive : stratégies apprises", "",
		"%d générations, population %d, %d parties par génome et par génération (objectif %d de réputation)." % [
			n_gen, n_pop, per, int(data["buildings"]["partie"]["objectif_reputation"])], "",
		"## Progression du meilleur génome", "", "| Génération | Score | Victoires | Jour moyen de victoire | Réputation moyenne | Victoires moyennes (population) |", "|---|---|---|---|---|---|"]
	for h in history:
		var b: Dictionary = h["best"]
		L.append("| %d | %.2f | %d %% | %s | %.0f | %d %% |" % [h["gen"] + 1, b["fitness"], roundi(100.0 * b["wins"]),
			"—" if b["win_day"] >= 99.0 else "%.1f" % b["win_day"], b["rep"], roundi(100.0 * h["mean_wins"])])
	L.append("")
	L.append("## Meilleurs génomes de la dernière génération")
	L.append("")
	for k in mini(6, order.size()):
		var s: Dictionary = scores[order[k]]
		L.append("%d. **%d %% de victoires**, jour moyen %s, réputation %.0f — %s" % [k + 1, roundi(100.0 * s["wins"]),
			"—" if s["win_day"] >= 99.0 else "%.1f" % s["win_day"], s["rep"], _describe(pop[order[k]])])
	L.append("")
	# Métiers : préférence moyenne des 8 meilleurs génomes (> 0 : recherché, < 0 : évité)
	L.append("## Métiers recherchés ou évités par les meilleures IA")
	L.append("")
	L.append("Poids moyen ajouté à la valeur d'un métier au draft et à l'embauche (8 meilleurs génomes). Un métier évité par toutes les IA qui gagnent est probablement trop faible.")
	L.append("")
	var avg := {}
	for j in jobs_ids:
		var t := 0.0
		for k in mini(8, order.size()):
			t += float(pop[order[k]]["poids_metiers"][j])
		avg[j] = t / mini(8, order.size())
	var js := avg.keys()
	js.sort_custom(func(a, b): return avg[a] > avg[b])
	L.append("| Métier | Poids moyen |")
	L.append("|---|---|")
	for j in js:
		L.append("| %s | %+.2f |" % [j, avg[j]])
	L.append("")
	L.append("## Réglages les plus fréquents chez les 8 meilleurs")
	L.append("")
	for b in BOOLS:
		var n := 0
		for k in mini(8, order.size()):
			if pop[order[k]][b]:
				n += 1
		L.append("- %s : %d / 8" % [b, n])
	var path := ProjectSettings.globalize_path("res://").path_join("../rapport_evolution.md")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(L) + "\n")
	f.close()
	var best: Array = []
	for k in mini(4, order.size()):
		var g: Dictionary = pop[order[k]].duplicate(true)
		g["nom"] = "Évoluée %d" % (k + 1)
		best.append(g)
	var fj := FileAccess.open("res://data/ia_evolution.json", FileAccess.WRITE)
	fj.store_string(JSON.stringify({"_note": "Meilleurs génomes trouvés par tests/evolution.gd (stratégies d'IA).", "strategies": best}, "  "))
	fj.close()
	print("Rapport écrit : %s" % path)
