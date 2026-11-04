extends SceneTree
## Étude du jeu par une IA qui apprend. Une population de stratégies (réglages de l'IA et préférences de métiers, traits,
## animaux, cartes, améliorations) joue des parties à 4 ; les meilleures sont gardées, croisées et légèrement modifiées,
## génération après génération. Chaque partie alimente les statistiques du rapport. Une phase finale oppose les stratégies
## écrites à la main aux meilleures stratégies apprises.
##
##   godot --headless --path game --script res://tests/evolution.gd -- --total=1000
## --total : nombre de parties de l'étude (ou lancer_etude.bat à la racine). --jobs=N : processus en parallèle.
## Écrit rapport_etude.md à la racine, mis à jour à chaque génération, et game/data/ia_evolution.json (meilleures stratégies).

const POPULATION := 16
const PARTIES_PAR_GENOME := 6
const PARTIES_PAR_GENOME_LONGUE := 12  # à partir de 2000 parties : moins de chance dans la sélection
const ETUDE_LONGUE := 2000
const ATTENTE_MAX_MS := 600000  # sans nouveau résultat pendant 10 min, les processus bloqués sont arrêtés
const PART_FINALE := 0.1  # part des parties gardée pour la phase finale
const EXPLORATION := 0.25  # part de choix au hasard (améliorations, cartes) pour que tout soit essayé
const BOOLS := ["marche", "rush_or", "formation", "cartes", "spectacle", "affinite", "boutique", "mine", "specialisation", "fast_expand", "route_mine", "adaptatif", "agrandir", "meme_type"]
const TYPES := ["herbivore", "predateur", "aquatique", "aerien"]
const CONTINENTS := ["Afrique", "Amerique", "Asie", "Europe"]
const TAILLES := ["moyen", "grand", "evolutif"]
## Plages des réglages numériques : [min, max, entier ?]
const NUMS := {
	"reserve": [0.0, 40.0, false], "preference_palier": [0.3, 3.0, false], "contrats_en_attente_max": [1, 4, true],
	"lobbyistes_max": [0, 3, true], "maisons_max": [1, 8, true], "camp": [0, 2, true], "palier_min": [1, 2, true],
}
const POIDS := ["poids_metiers", "poids_traits", "poids_animaux", "poids_cartes", "poids_ameliorations"]
const STRATEGIES := [
	{"nom": "Équilibrée"}, {"nom": "Marché", "marche": true}, {"nom": "Rush or", "rush_or": true},
	{"nom": "Rush or + route", "rush_or": true, "route_mine": true}, {"nom": "Fast expand", "fast_expand": true, "camp": 1},
	{"nom": "Spécialisation", "specialisation": true}, {"nom": "Formation", "formation": true}, {"nom": "Cartes", "cartes": true},
	{"nom": "Parc évolutif", "taille_zoo": "evolutif"}, {"nom": "Affinités", "affinite": true},
	{"nom": "Haut de gamme", "preference_palier": 3.0, "palier_min": 2, "reserve": 15},
	{"nom": "Petits contrats", "preference_palier": 0.4, "contrats_en_attente_max": 3}, {"nom": "Grand parc", "taille_zoo": "grand"},
	{"nom": "Lobbying", "lobbyistes_max": 2}, {"nom": "Camp amélioré", "camp": 1}, {"nom": "Grand camp", "camp": 2},
	{"nom": "Spectacle", "spectacle": true},
	{"nom": "Ancienne IA", "adaptatif": false, "agrandir": false, "score_simple": true}, {"nom": "Sans agrandir", "agrandir": false},
	{"nom": "Même type", "meme_type": true}, {"nom": "Prédateurs", "type_cible": "predateur"}, {"nom": "Aériens", "type_cible": "aerien"},
	{"nom": "Aquatiques", "type_cible": "aquatique"}, {"nom": "Herbivores", "type_cible": "herbivore"},
	{"nom": "Afrique", "continent_cible": "Afrique"}, {"nom": "Amérique", "continent_cible": "Amerique"},
	{"nom": "Asie", "continent_cible": "Asie"}, {"nom": "Europe", "continent_cible": "Europe"},
]

var data: Dictionary
var ids := {}  # famille de préférences -> identifiants
var noms := {}  # identifiant -> nom affiché
var rng := RandomNumberGenerator.new()
var dir := ""
var t0 := 0
var parties_jouees := 0
var total_parties := 0
# Statistiques cumulées : catégorie -> clé -> {"n", "wins", "rep"} ; base : tous les joueurs
var stats := {}
var base := {"n": 0, "wins": 0, "rep": 0.0}
var cartes := {}  # carte -> {"n", "tot", "tard_n", "tard_tot", "tot_prec", "tard_prec"}
var offres := {}  # espèce -> nuits au marché
var achats := {}  # espèce -> achats
var jours_achat := {}
var sources := {}
var jours_fin: Array = []
var record := {}
var parties_par_genome := PARTIES_PAR_GENOME
var objectifs_tires := {}  # objectif -> parties où il a été tiré
var processus_bloques := 0


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	data = GameData.load_all()
	dir = ProjectSettings.globalize_path("user://evolution")

	# Processus de travail : joue les parties de son lot (fichier matches.json) et écrit un résultat par partie.
	if args.has("lot"):
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("matches.json")))
		var lots := int(args["lots"])
		for k in range(int(args["lot"]), spec["matches"].size(), lots):
			var mm: Dictionary = spec["matches"][k]
			_save(k, _play(mm["seed"], mm["genomes"]))
		quit(0)
		return

	ids["poids_metiers"] = data["workers"]["metiers"].map(func(m): return m["id"])
	ids["poids_traits"] = (data["workers"]["traits_positifs"] + data["workers"]["traits_negatifs"]).map(func(t): return t["id"])
	ids["poids_animaux"] = data["animals"]["animaux"].map(func(a): return a["id"])
	ids["poids_cartes"] = data["workers"]["cartes_action"].map(func(c): return c["id"])
	var ups: Array = data["workers"]["ameliorations_generiques"].map(func(u): return u["id"])
	for j in data["workers"]["ameliorations_metier"]:
		ups.append_array(data["workers"]["ameliorations_metier"][j].map(func(u): return u["id"]))
	ids["poids_ameliorations"] = ups
	for m in data["workers"]["metiers"]:
		noms[m["id"]] = m["nom"]
		if m.has("jouer"):
			noms["cadre_" + m["id"]] = "%s joué (%s)" % [m["nom"], m["jouer"]["nom"]]
	for t in data["workers"]["traits_positifs"] + data["workers"]["traits_negatifs"]:
		noms[t["id"]] = t["nom"]
	for a in data["animals"]["animaux"]:
		noms[a["id"]] = a["nom"]
	for c in data["workers"]["cartes_action"]:
		noms[c["id"]] = c["nom"]
	for o in data["buildings"]["objectifs"]["liste"]:
		noms["obj_" + str(o["id"])] = o["texte"]
	for b in data["events"]["bonus_nuit"]:
		noms[str(b["id"])] = "%s (%s)" % [b["nom"], b["texte"]]
	noms["article"] = "Article de presse (Journaliste)"
	noms["accusation"] = "Accusation (Journaliste)"
	noms["agence"] = "Échange à l'Agence d'intérim"
	noms["cabinet"] = "Remplacement au Cabinet de recrutement"
	for b in data["buildings"]["batiments"]:
		noms[b["id"]] = b["nom"]
	for u in data["workers"]["ameliorations_generiques"]:
		noms[u["id"]] = u["nom"]
	for j in data["workers"]["ameliorations_metier"]:
		for u in data["workers"]["ameliorations_metier"][j]:
			noms[u["id"]] = u["nom"]

	rng.seed = int(args.get("seed", str(Time.get_ticks_usec())))
	total_parties = maxi(8, int(args.get("total", "200")))
	var jobs := int(args.get("jobs", str(maxi(1, OS.get_processor_count() / 2))))
	if total_parties >= ETUDE_LONGUE:
		parties_par_genome = PARTIES_PAR_GENOME_LONGUE
	# --fin=08:00 : l'étude s'arrête d'elle-même à temps pour jouer sa finale et écrire son rapport.
	var budget_ms := 0
	if args.has("fin") and ":" in str(args["fin"]):
		var h: PackedStringArray = str(args["fin"]).split(":")
		var now := Time.get_time_dict_from_system()
		var secondes := int(h[0]) * 3600 + int(h[1]) * 60 - (int(now["hour"]) * 3600 + int(now["minute"]) * 60)
		budget_ms = (secondes if secondes > 0 else secondes + 86400) * 1000
	var par_generation: int = POPULATION * parties_par_genome / 4
	var n_gen := maxi(1, roundi(total_parties * (1.0 - PART_FINALE)) / par_generation)
	var finale := maxi(4, total_parties - n_gen * par_generation)
	total_parties = n_gen * par_generation + finale
	DirAccess.make_dir_recursive_absolute(dir)
	t0 = Time.get_ticks_msec()
	print("Étude : %d parties (%d générations de %d parties, puis %d parties de finale), %d processus." % [total_parties, n_gen, par_generation, finale, jobs])
	var pop: Array = _initial_population(POPULATION)
	var history: Array = []
	var order: Array = []
	var scores: Array = []
	for gen in n_gen:
		scores = _evaluate(pop, jobs, gen)
		order = range(pop.size())
		order.sort_custom(func(a, b): return scores[a]["fitness"] > scores[b]["fitness"])
		var best: Dictionary = scores[order[0]]
		history.append({"gen": gen, "best": best, "mean_wins": _mean(scores.map(func(s): return s["wins"]))})
		var ecoule := (Time.get_ticks_msec() - t0) / 1000.0
		var reste := ecoule / maxf(1.0, parties_jouees) * (total_parties - parties_jouees)
		print("Génération %d / %d : meilleure %d %% de victoires, jour %.1f, rép. %.0f · %d parties en %d min, reste ~%d min" % [
			gen + 1, n_gen, roundi(100.0 * best["wins"]), best["win_day"], best["rep"], parties_jouees, int(ecoule / 60.0), int(reste / 60.0)])
		_write_report(pop, order, scores, history, [])
		if budget_ms > 0 and Time.get_ticks_msec() - t0 >= budget_ms * 0.88:
			# Le temps tourne : la finale garde ce qu'il reste, à la vitesse mesurée jusqu'ici.
			var par_ms := float(parties_jouees) / maxf(1.0, Time.get_ticks_msec() - t0)
			finale = clampi(int(par_ms * (budget_ms - (Time.get_ticks_msec() - t0)) * 0.8), 8, finale)
			total_parties = parties_jouees + finale
			print("Heure de fin proche : finale de %d parties." % finale)
			break
		if gen < n_gen - 1:
			pop = _next_generation(pop, order)
	var classement := _finale(pop, order, finale, jobs)
	_write_report(pop, order, scores, history, classement)
	print("Étude terminée en %d min. Rapport : %s" % [int((Time.get_ticks_msec() - t0) / 60000), ProjectSettings.globalize_path("res://").path_join("../rapport_etude.md")])
	quit(0)


# --- Génomes -----------------------------------------------------------------------------------------

func _initial_population(n: int) -> Array:
	var pop: Array = []
	# On part des stratégies écrites à la main, puis des génomes au hasard.
	var depart := [{}, {"rush_or": true}, {"camp": 1}, {"preference_palier": 0.4, "contrats_en_attente_max": 3},
		{"formation": true, "camp": 1}, {"spectacle": true}, {"lobbyistes_max": 2}, {"cartes": true}, {"fast_expand": true, "camp": 1}, {"rush_or": true, "route_mine": true},
		{"meme_type": true}, {"affinite": true}]
	for s in depart:
		if pop.size() < n:
			var g := _random_genome()
			for k in s:
				g[k] = s[k]
			pop.append(g)
	while pop.size() < n:
		pop.append(_random_genome())
	return pop


func _random_genome() -> Dictionary:
	var g := {"nom": "", "explore": EXPLORATION, "taille_zoo": TAILLES[rng.randi_range(0, TAILLES.size() - 1)]}
	for k in NUMS:
		var r: Array = NUMS[k]
		g[k] = rng.randi_range(int(r[0]), int(r[1])) if r[2] else rng.randf_range(float(r[0]), float(r[1]))
	for b in BOOLS:
		g[b] = rng.randf() < (0.8 if b in ["boutique", "mine", "adaptatif", "agrandir"] else (0.05 if b == "specialisation" else 0.2))
	g["type_cible"] = TYPES[rng.randi_range(0, TYPES.size() - 1)] if rng.randf() < 0.15 else ""
	g["continent_cible"] = CONTINENTS[rng.randi_range(0, CONTINENTS.size() - 1)] if rng.randf() < 0.15 else ""
	for f in POIDS:
		g[f] = {}
		for i in ids[f]:
			g[f][i] = 0.0
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
	if rng.randf() < rate * 0.2:
		c["type_cible"] = TYPES[rng.randi_range(0, TYPES.size() - 1)] if rng.randf() < 0.5 else ""
	if rng.randf() < rate * 0.2:
		c["continent_cible"] = CONTINENTS[rng.randi_range(0, CONTINENTS.size() - 1)] if rng.randf() < 0.5 else ""
	for f in POIDS:
		for i in ids[f]:
			if rng.randf() < rate * 0.5:
				c[f][i] = clampf(float(c[f][i]) + rng.randfn(0.0, 0.5), -2.0, 2.0)
	return c


func _cross(a: Dictionary, b: Dictionary) -> Dictionary:
	var c: Dictionary = a.duplicate(true)
	for k in a:
		if not k in POIDS and rng.randf() < 0.5:
			c[k] = b[k]
	for f in POIDS:
		for i in ids[f]:
			if rng.randf() < 0.5:
				c[f][i] = b[f][i]
	return c


## Élitisme : les 4 meilleurs restent ; le reste naît de deux parents tirés parmi la meilleure moitié, puis mute.
func _next_generation(pop: Array, order: Array) -> Array:
	var nxt: Array = []
	for k in 4:
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
		if g.get(b, false) and not b in ["boutique", "mine", "adaptatif", "agrandir"]:
			on.append(b)
		elif not g.get(b, false) and b in ["adaptatif", "agrandir"]:
			on.append("sans " + b)
	for k in ["type_cible", "continent_cible"]:
		if str(g.get(k, "")) != "":
			on.append(str(g[k]))
	return "parc %s, palier %.1f, réserve %d, lobby %d, camp %d, contrats %d%s" % [
		g["taille_zoo"], g["preference_palier"], int(g["reserve"]), int(g["lobbyistes_max"]), int(g["camp"]), int(g["contrats_en_attente_max"]),
		(", " + ", ".join(on)) if not on.is_empty() else ""]


# --- Parties -----------------------------------------------------------------------------------------

## Joue des parties en parallèle ; renvoie les résultats par indice de partie.
func _jouer(matches: Array, jobs: int) -> Dictionary:
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	var fm := FileAccess.open(dir.path_join("matches.json"), FileAccess.WRITE)
	fm.store_string(JSON.stringify({"matches": matches}))
	fm.close()
	var pids: Array[int] = []
	for lot in mini(jobs, matches.size()):
		pids.append(OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tests/evolution.gd", "--", "--lot=%d" % lot, "--lots=%d" % mini(jobs, matches.size())]))
	var results := {}
	var dernier_resultat := Time.get_ticks_msec()
	while results.size() < matches.size():
		var fini := pids.all(func(p): return not OS.is_process_running(p))
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".res") and not results.has(f.get_basename().to_int()):
				results[f.get_basename().to_int()] = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
				dernier_resultat = Time.get_ticks_msec()
		if fini:
			break
		# Une erreur de script bloque un processus sans le fermer : on l'arrête, l'étude continue avec les parties jouées.
		if Time.get_ticks_msec() - dernier_resultat > ATTENTE_MAX_MS:
			for p in pids:
				if OS.is_process_running(p):
					OS.kill(p)
					processus_bloques += 1
			print("Attention : processus bloqué(s) arrêté(s), %d partie(s) perdue(s)." % (matches.size() - results.size()))
			break
		OS.delay_msec(300)
	parties_jouees += results.size()
	return results


## Chaque génome joue PARTIES_PAR_GENOME parties contre des adversaires tirés dans la population. Score : victoires (×3),
## vitesse de victoire, réputation finale.
func _evaluate(pop: Array, jobs: int, gen: int) -> Array:
	var slots: Array = []
	for k in parties_par_genome:
		var idx := range(pop.size())
		idx.shuffle()
		slots.append_array(idx)
	var matches: Array = []
	for k in range(0, slots.size() - 3, 4):
		var four: Array = slots.slice(k, k + 4)
		matches.append({"seed": rng.randi_range(1, 1 << 30), "ids": four, "genomes": four.map(func(i): return pop[i])})
	var results := _jouer(matches, jobs)
	var sc: Array = []
	for i in pop.size():
		sc.append({"games": 0, "wins": 0.0, "rep": 0.0, "win_days": [], "fitness": 0.0, "win_day": 99.0})
	var objectif := float(data["buildings"]["partie"]["objectif_reputation"])
	for k in results:
		var r: Dictionary = results[k]
		_cumuler(r)
		var four: Array = matches[k]["ids"]
		for p in 4:
			var s: Dictionary = sc[four[p]]
			s["games"] += 1
			s["rep"] += float(r["joueurs"][p]["rep"])
			if int(r["winner"]) == p and float(r["joueurs"][p]["rep"]) >= objectif:
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


## Phase finale : stratégies écrites à la main contre les meilleures stratégies apprises, sans exploration.
func _finale(pop: Array, order: Array, n: int, jobs: int) -> Array:
	var candidats: Array = STRATEGIES.duplicate(true)
	for k in mini(4, order.size()):
		var g: Dictionary = pop[order[k]].duplicate(true)
		g["nom"] = "Apprise %d" % (k + 1)
		g["explore"] = 0.0
		candidats.append(g)
	var fj := FileAccess.open("res://data/ia_evolution.json", FileAccess.WRITE)
	fj.store_string(JSON.stringify({"_note": "Meilleures stratégies trouvées par tests/evolution.gd.", "strategies": candidats.slice(STRATEGIES.size())}, "  "))
	fj.close()
	var matches: Array = []
	var pile: Array = []
	for k in n:
		var four: Array = []
		while four.size() < 4:
			if pile.is_empty():
				pile = range(candidats.size())
				pile.shuffle()
			var c: int = pile.pop_back()
			if not four.has(c):
				four.append(c)
		matches.append({"seed": rng.randi_range(1, 1 << 30), "ids": four, "genomes": four.map(func(i): return candidats[i])})
	var results := _jouer(matches, jobs)
	var cl := {}
	for c in candidats:
		cl[c["nom"]] = {"nom": c["nom"], "n": 0, "wins": 0, "rep": 0.0, "days": []}
	var objectif := float(data["buildings"]["partie"]["objectif_reputation"])
	for k in results:
		var r: Dictionary = results[k]
		_cumuler(r)
		var four: Array = matches[k]["ids"]
		for p in 4:
			var e: Dictionary = cl[candidats[four[p]]["nom"]]
			e["n"] += 1
			e["rep"] += float(r["joueurs"][p]["rep"])
			if int(r["winner"]) == p and float(r["joueurs"][p]["rep"]) >= objectif:
				e["wins"] += 1
				e["days"].append(int(r["day"]))
	var out: Array = cl.values()
	out.sort_custom(func(a, b): return float(a["wins"]) / maxi(1, a["n"]) > float(b["wins"]) / maxi(1, b["n"]))
	return out


func _play(seed: int, genomes: Array) -> Dictionary:
	var m := Match.new(data, seed, 4, -1, genomes)
	m.advance_ai_draft()
	while not m.game_over:
		if m.phase == "day":
			m.tick(1.0)
		elif m.phase == "night":
			m.start_next_day()
	var joueurs := []
	for i in 4:
		var p: GameState = m.players[i]
		var traits := {}
		var metiers := {}
		var ups := {}
		for c in p.all_employees():
			metiers[c.metier["id"]] = int(metiers.get(c.metier["id"], 0)) + 1
			for t in c.traits:
				traits[t] = int(traits.get(t, 0)) + 1
			for u in c.upgrade_names:
				ups[u] = int(ups.get(u, 0)) + 1
		var bat := {}
		for s in p.sites:
			if s.done and s.kind == "batiment" and not s.def_id() in ["route", "pont", "cloture", "enclos"]:
				bat[s.def_id()] = int(bat.get(s.def_id(), 0)) + 1
		var gains := {}
		var prec := 0.0
		for row in m.history:
			gains[str(int(row[i]["day"]))] = float(row[i]["rep"]) - prec
			prec = float(row[i]["rep"])
		joueurs.append({"rep": p.rep_points, "traits": traits, "metiers": metiers, "ameliorations": ups, "batiments": bat, "gains": gains,
			"cartes": p.journal_cartes, "contrats": p.journal_contrats, "animaux": p.animals.filter(func(a): return a.arrived).map(func(a): return a.def["id"]),
			"continents": p.animals.filter(func(a): return a.arrived).map(func(a): return a.def["continent"]), "labels": p.labels_owned.keys(), "sources": p.rep_sources,
			"types": p.animals.filter(func(a): return a.arrived).map(func(a): return a.def.get("type", "")),
			"paliers": p.animals.filter(func(a): return a.arrived).map(func(a): return a.def["palier"]),
			"objectifs": p.objectifs_faits.keys(), "bonus": p.journal_bonus, "agrandis": m.ais[i].agrandis, "parc": m.ais[i].zoo_rect.get_area()})
	var out := {"day": m.day, "winner": m.winner, "seed": seed, "joueurs": joueurs, "offres": m.offres, "objectifs": m.objectifs.map(func(o): return o["id"])}
	m.dispose()
	return out


func _save(k: int, result: Dictionary) -> void:
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


# --- Statistiques ------------------------------------------------------------------------------------

func _note(cat: String, cle: String, gagne: bool, rep: float) -> void:
	if not stats.has(cat):
		stats[cat] = {}
	if not stats[cat].has(cle):
		stats[cat][cle] = {"n": 0, "wins": 0, "rep": 0.0}
	var e: Dictionary = stats[cat][cle]
	e["n"] += 1
	e["wins"] += 1 if gagne else 0
	e["rep"] += rep


func _cumuler(r: Dictionary) -> void:
	jours_fin.append(int(r["day"]))
	var objectif := float(data["buildings"]["partie"]["objectif_reputation"])
	for i in 4:
		var j: Dictionary = r["joueurs"][i]
		var gagne: bool = int(r["winner"]) == i and float(j["rep"]) >= objectif
		var rep := float(j["rep"])
		base["n"] += 1
		base["wins"] += 1 if gagne else 0
		base["rep"] += rep
		if gagne and (record.is_empty() or int(r["day"]) < int(record["day"])):
			record = {"day": int(r["day"]), "seed": int(r["seed"]), "rep": rep}
		for cat in ["traits", "metiers", "ameliorations", "batiments"]:
			for k in j[cat]:
				_note(cat, k, gagne, rep)
		for a in j["animaux"]:
			_note("animaux", a, gagne, rep)
		for c in j["contrats"]:
			achats[c["id"]] = int(achats.get(c["id"], 0)) + 1
			jours_achat[c["id"]] = int(jours_achat.get(c["id"], 0)) + int(c["day"])
		for l in j["labels"]:
			_note("labels", l, gagne, rep)
		for o in j["objectifs"]:
			_note("objectifs", "obj_" + str(o), gagne, rep)
		var choisis := {}
		for b in j["bonus"]:
			choisis[b] = true
		for b in choisis:
			_note("bonus", b, gagne, rep)
		var par_type := {}
		for t in j["types"]:
			par_type[t] = int(par_type.get(t, 0)) + 1
		for t in par_type:
			_note("types", "%s (%s)" % [t, "3 espèces et plus" if par_type[t] >= 3 else "1 ou 2 espèces"], gagne, rep)
		var par_palier := {}
		for t in j["paliers"]:
			par_palier[t] = int(par_palier.get(t, 0)) + 1
		for t in par_palier:
			_note("raretes", "%s installé%s" % [data["animals"]["paliers"][t]["nom"], "s (2 et plus)" if par_palier[t] >= 2 else " (1)"], gagne, rep)
		var ag := int(j["agrandis"])
		_note("parc", "Parc agrandi %s" % ("jamais" if ag == 0 else ("1 fois" if ag == 1 else "2 fois et plus")), gagne, rep)
		var surface := int(j["parc"])
		_note("parc", "Parc de %s" % ("moins de 250 cases" if surface < 250 else ("250 à 449 cases" if surface < 450 else "450 cases et plus")), gagne, rep)
		var compte := {}
		for c in j["continents"]:
			compte[c] = int(compte.get(c, 0)) + 1
		for c in compte:
			_note("continents", "%s (%d espèces et plus)" % [c, 3] if compte[c] >= 3 else "%s (1 ou 2 espèces)" % c, gagne, rep)
		for s in j["sources"]:
			sources[s] = float(sources.get(s, 0.0)) + float(j["sources"][s])
		var vus := {}
		for c in j["cartes"]:
			vus[c["id"]] = true
			var d := int(c["day"])
			var e: Dictionary = cartes.get(c["id"], {"n": 0, "tot": 0.0, "prec": 0.0, "tard_n": 0, "tard_tot": 0.0, "tard_prec": 0.0})
			var gain := float(j["gains"].get(str(d), 0.0))
			var avant := float(j["gains"].get(str(d - 1), 0.0))
			e["n"] += 1
			e["tot"] += gain
			e["prec"] += avant
			if d >= 8:
				e["tard_n"] += 1
				e["tard_tot"] += gain
				e["tard_prec"] += avant
			cartes[c["id"]] = e
		for k in vus:
			_note("cartes", k, gagne, rep)
	for k in r["offres"]:
		offres[k] = int(offres.get(k, 0)) + int(r["offres"][k])
	for o in r.get("objectifs", []):
		objectifs_tires[o] = int(objectifs_tires.get(o, 0)) + 1


func _nom(k: String) -> String:
	return str(noms.get(k, k))


## Lignes d'une catégorie, triées par écart de victoires : avec ce critère contre sans. La marge (95 %) est lissée
## pour qu'un élément vu une seule fois ne paraisse jamais significatif.
func _lignes(cat: String) -> Array:
	var groupe: Dictionary = stats.get(cat, {})
	var rows: Array = []
	for k in groupe:
		var e: Dictionary = groupe[k]
		var n: int = e["n"]
		var sans_n: int = maxi(1, int(base["n"]) - n)
		var p := float(e["wins"]) / maxi(1, n)
		var q := float(int(base["wins"]) - int(e["wins"])) / sans_n
		var pl := (float(e["wins"]) + 1.0) / (n + 2.0)
		var ql := (float(int(base["wins"]) - int(e["wins"])) + 1.0) / (sans_n + 2.0)
		var marge := 1.96 * sqrt(pl * (1.0 - pl) / (n + 2.0) + ql * (1.0 - ql) / (sans_n + 2.0))
		rows.append({"k": k, "n": n, "p": p, "q": q, "d": p - q, "marge": marge, "r": float(e["rep"]) / maxi(1, n), "rs": (float(base["rep"]) - float(e["rep"])) / sans_n})
	rows.sort_custom(func(a, b): return a["d"] > b["d"])
	return rows


## Forts et faibles d'une catégorie : seuls les écarts significatifs comptent.
func _synthese(L: Array[String], titre: String, cat: String) -> void:
	# Un élément presque absent, ou présent chez presque tous, ne se compare à rien
	var mini_n := maxi(10, int(base["n"]) / 50)
	var sures := _lignes(cat).filter(func(x): return absf(x["d"]) >= x["marge"] and x["n"] >= mini_n and int(base["n"]) - x["n"] >= mini_n)
	var fmt := func(x): return "%s (%+d)" % [_nom(x["k"]), roundi(100.0 * x["d"])]
	var forts: Array = sures.filter(func(x): return x["d"] > 0.0).slice(0, 5).map(fmt)
	var faibles: Array = sures.filter(func(x): return x["d"] < 0.0).slice(-5).map(fmt)
	faibles.reverse()
	L.append("- **%s** : forts : %s ; faibles : %s." % [titre, ", ".join(forts) if not forts.is_empty() else "aucun net", ", ".join(faibles) if not faibles.is_empty() else "aucun net"])


## Tableau trié par écart de victoires. « ≈ » : l'écart n'est pas significatif.
func _table(L: Array[String], titre: String, cat: String, texte := "") -> void:
	L.append("## %s" % titre)
	L.append("")
	if texte != "":
		L.append(texte)
		L.append("")
	var rows := _lignes(cat)
	if rows.is_empty():
		L.append("Pas encore de données.")
		L.append("")
		return
	L.append("| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |")
	L.append("|---|---|---|---|---|---|---|")
	for x in rows:
		L.append("| %s | %d | %d %% | %d %% | %s%+d pts | %.0f | %.0f |" % [_nom(x["k"]), x["n"], roundi(100.0 * x["p"]), roundi(100.0 * x["q"]),
			"≈ " if absf(x["d"]) < x["marge"] else "", roundi(100.0 * x["d"]), x["r"], x["rs"]])
	L.append("")


func _write_report(pop: Array, order: Array, scores: Array, history: Array, classement: Array) -> void:
	var L: Array[String] = ["# Étude du jeu par l'IA qui apprend", ""]
	var fin: bool = not classement.is_empty()
	L.append("%d parties sur %d jouées%s, %d min de calcul. Fin de partie en moyenne au jour %.1f." % [parties_jouees, total_parties, "" if fin else " (étude en cours)",
		int((Time.get_ticks_msec() - t0) / 60000), _mean(jours_fin)])
	if not record.is_empty():
		L.append("Record : victoire au jour %d (%.0f de réputation, graine %d)." % [record["day"], record["rep"], record["seed"]])
	L.append("")
	L.append("**Comment lire les tableaux** : « Victoires avec » est le taux de victoire des joueurs qui avaient cet élément en fin de partie, « sans » celui des autres. Un écart positif veut dire que l'élément accompagne la victoire, sans le prouver : un joueur qui gagne a aussi plus d'ouvriers, de bâtiments et d'animaux. « ≈ » signale un écart trop faible pour conclure, compte tenu du nombre de parties.")
	L.append("")
	L.append("## En bref : forts et faibles")
	L.append("")
	L.append("Écart de victoires en points, seulement quand il est significatif, et hors éléments presque absents ou présents chez presque tous. Les bâtiments et les améliorations communes sont faussés : un joueur qui dure en a davantage.")
	L.append("")
	_synthese(L, "Traits", "traits")
	_synthese(L, "Métiers", "metiers")
	_synthese(L, "Améliorations", "ameliorations")
	_synthese(L, "Cartes", "cartes")
	_synthese(L, "Animaux", "animaux")
	_synthese(L, "Bâtiments", "batiments")
	_synthese(L, "Bonus de nuit", "bonus")
	L.append("")
	if processus_bloques > 0:
		L.append("**Attention** : %d processus se sont bloqués et ont été arrêtés. Cherchez l'erreur de script en relançant quelques parties." % processus_bloques)
		L.append("")
	if fin:
		L.append("## Classement des stratégies (phase finale)")
		L.append("")
		L.append("| Stratégie | Parties | Victoires | Jour moyen de victoire | Réputation moyenne |")
		L.append("|---|---|---|---|---|")
		for e in classement:
			L.append("| %s | %d | %d %% | %s | %.0f |" % [e["nom"], e["n"], roundi(100.0 * e["wins"] / maxi(1, e["n"])), "—" if e["days"].is_empty() else "%.1f" % _mean(e["days"]), e["rep"] / maxi(1, e["n"])])
		L.append("")
	L.append("## Stratégies apprises")
	L.append("")
	L.append("| Génération | Victoires de la meilleure | Jour moyen | Réputation | Moyenne de la population |")
	L.append("|---|---|---|---|---|")
	var pas := maxi(1, history.size() / 15)
	for k in range(0, history.size(), pas):
		var h: Dictionary = history[k]
		var b: Dictionary = h["best"]
		L.append("| %d | %d %% | %s | %.0f | %d %% |" % [h["gen"] + 1, roundi(100.0 * b["wins"]), "—" if b["win_day"] >= 99.0 else "%.1f" % b["win_day"], b["rep"], roundi(100.0 * h["mean_wins"])])
	L.append("")
	var top := mini(8, order.size())
	for k in mini(4, top):
		L.append("%d. %s" % [k + 1, _describe(pop[order[k]])])
	L.append("")
	L.append("Réglages retenus par les %d meilleures : %s." % [top, ", ".join(BOOLS.map(func(b): return "%s %d/%d" % [b, order.slice(0, top).filter(func(i): return pop[i].get(b, false)).size(), top]))])
	L.append("")
	for f in [["poids_metiers", "Métiers"], ["poids_traits", "Traits"], ["poids_animaux", "Animaux"], ["poids_cartes", "Cartes"], ["poids_ameliorations", "Améliorations"]]:
		var moy := {}
		for i in ids[f[0]]:
			moy[i] = _mean(order.slice(0, top).map(func(o): return float(pop[o][f[0]].get(i, 0.0))))
		var cles: Array = moy.keys()
		cles.sort_custom(func(a, b): return moy[a] > moy[b])
		L.append("**%s, des plus recherchés aux plus évités par les IA qui gagnent** : %s." % [f[1], ", ".join(cles.map(func(c): return "%s %+.1f" % [_nom(c), moy[c]]))])
		L.append("")
	_table(L, "Traits des ouvriers", "traits", "Joueurs ayant au moins un ouvrier avec ce trait. Défauts et qualités sont tirés au draft, mais l'IA choisit ses cartes : les traits les plus visibles sont en partie évités.")
	_table(L, "Métiers", "metiers")
	_table(L, "Améliorations", "ameliorations", "Choisies %d %% du temps au hasard pendant l'apprentissage, pour que toutes soient essayées." % roundi(EXPLORATION * 100))
	_table(L, "Bâtiments", "batiments")
	_table(L, "Labels", "labels")
	_table(L, "Objectifs remplis", "objectifs", "Joueurs ayant rempli cet objectif. Le taux de réussite est dans le tableau suivant.")
	L.append("| Objectif | Parties où il est tiré | Joueurs qui l'ont rempli | Taux de réussite |")
	L.append("|---|---|---|---|")
	for o in data["buildings"]["objectifs"]["liste"]:
		var tires := int(objectifs_tires.get(o["id"], 0))
		var remplis := int(stats.get("objectifs", {}).get("obj_" + str(o["id"]), {"n": 0})["n"])
		L.append("| %s | %d | %d | %d %% |" % [o["texte"], tires, remplis, roundi(100.0 * remplis / maxi(1, tires * 4))])
	L.append("")
	_table(L, "Bonus de nuit", "bonus", "Joueurs ayant choisi ce bonus au moins une fois (le premier en influence choisit).")
	_table(L, "Taille du parc", "parc", "Agrandissements terminés et surface de l'enceinte en fin de partie.")
	_table(L, "Cartes à usage unique et cadres joués", "cartes", "Joueurs ayant joué cette carte au moins une fois.")
	L.append("### Effet immédiat des cartes sur la réputation gagnée")
	L.append("")
	L.append("Réputation gagnée le jour où la carte est jouée, comparée à la veille. La réputation monte naturellement chaque jour : à comparer d'une carte à l'autre plutôt qu'à zéro. « Tard » : à partir du jour 8.")
	L.append("")
	L.append("| Carte | Coût | Jouée | Gain du jour | Veille | Écart | Tard : gain | Tard : veille | Tard : écart |")
	L.append("|---|---|---|---|---|---|---|---|---|")
	var couts := {}
	for c in data["workers"]["cartes_action"]:
		couts[c["id"]] = int(c["cout"])
	var ck: Array = cartes.keys()
	ck.sort_custom(func(a, b): return cartes[a]["tard_tot"] / maxi(1, cartes[a]["tard_n"]) - cartes[a]["tard_prec"] / maxi(1, cartes[a]["tard_n"]) > cartes[b]["tard_tot"] / maxi(1, cartes[b]["tard_n"]) - cartes[b]["tard_prec"] / maxi(1, cartes[b]["tard_n"]))
	for k in ck:
		var e: Dictionary = cartes[k]
		var n := maxi(1, e["n"])
		var tn := maxi(1, e["tard_n"])
		L.append("| %s | %s | %d | %.1f | %.1f | %+.1f | %.1f | %.1f | %+.1f (%d) |" % [_nom(k), str(couts.get(k, "—")), e["n"], e["tot"] / n, e["prec"] / n, (e["tot"] - e["prec"]) / n,
			e["tard_tot"] / tn, e["tard_prec"] / tn, (e["tard_tot"] - e["tard_prec"]) / tn, e["tard_n"]])
	L.append("")
	L.append("## Animaux")
	L.append("")
	L.append("Taux d'achat : achats par nuit passée au marché. Un rare est naturellement moins acheté : il coûte très cher.")
	L.append("")
	L.append("| Espèce | Continent | Rareté | Nuits au marché | Achats | Taux d'achat | Jour moyen d'achat | Installée | Victoires avec | Écart |")
	L.append("|---|---|---|---|---|---|---|---|---|---|")
	var spp: Array = data["animals"]["animaux"].duplicate()
	spp.sort_custom(func(a, b): return float(achats.get(a["id"], 0)) / maxi(1, offres.get(a["id"], 1)) > float(achats.get(b["id"], 0)) / maxi(1, offres.get(b["id"], 1)))
	for a in spp:
		var i: String = a["id"]
		var e: Dictionary = stats.get("animaux", {}).get(i, {"n": 0, "wins": 0})
		var nb := int(achats.get(i, 0))
		var p := float(e["wins"]) / maxi(1, e["n"])
		var q := float(int(base["wins"]) - int(e["wins"])) / maxi(1, int(base["n"]) - int(e["n"]))
		L.append("| %s | %s | %s | %d | %d | %d %% | %s | %d | %d %% | %+d pts |" % [a["nom"], data["animals"]["continents"][a["continent"]], data["animals"]["paliers"][a["palier"]]["nom"],
			int(offres.get(i, 0)), nb, roundi(100.0 * nb / maxi(1, offres.get(i, 1))), "—" if nb == 0 else "%.1f" % (float(jours_achat[i]) / nb), e["n"], roundi(100.0 * p), roundi(100.0 * (p - q))])
	L.append("")
	_table(L, "Continents", "continents", "Selon le nombre d'espèces de ce continent en fin de partie.")
	_table(L, "Types d'animaux", "types", "Selon le nombre d'espèces de ce type en fin de partie.")
	_table(L, "Raretés", "raretes", "Selon les animaux installés en fin de partie.")
	L.append("## D'où vient la réputation")
	L.append("")
	var tot := 0.0
	for s in sources:
		tot += float(sources[s])
	for s in sources:
		L.append("- %s : %d %%" % [s, roundi(100.0 * float(sources[s]) / maxf(1.0, tot))])
	var f := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../rapport_etude.md"), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(L) + "\n")
		f.close()
