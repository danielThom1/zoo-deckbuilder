extends SceneTree
## Mesure : où passe le temps des collaborateurs de l'IA, et combien de fois ils changent d'avis.


func _cle(w: GameState.Worker) -> String:
	var t := w.task
	if t.is_empty():
		return ""
	match str(t.get("type", "")):
		"build":
			var s: GameState.Site = t.get("site")
			return "build:%s" % (str(s.rect.position) if s else "?")
		"extract":
			return "extract:%s" % str(t.get("res", ""))
		"station":
			return "station:%s" % str(t.get("kind", ""))
	return str(t.get("type", ""))


func _init() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		var kv := s.trim_prefix("--").split("=", true, 1)
		a[kv[0]] = kv[1] if kv.size() > 1 else ""
	var data := GameData.load_all()
	var niveaux = JSON.parse_string(FileAccess.get_file_as_string("res://data/ia_niveaux.json"))
	var strats: Array = niveaux["niveaux"]["difficile"]["strategies"]
	for gs in str(a.get("graines", "1")).split(","):
		var gi := int(gs)
		var m := Match.new(data, 7000 + gi * 13, 4, -1, [strats[0], strats[1 % strats.size()], strats[2 % strats.size()], strats[3 % strats.size()]])
		m.advance_ai_draft()
		var etat := {"inactif": 0.0, "marche": 0.0, "travail": 0.0, "dehors": 0.0}
		var changements := 0
		var allers_retours := 0
		var abandons := 0  # tâche de chantier quittée alors que le chantier n'était pas fini
		var hist := {}  # carte -> [clé précédente, clé d'avant, temps]
		var ouverture := [-1, -1, -1, -1]
		var premier := [-1, -1, -1, -1]
		var exemples := {}
		while not m.game_over:
			if m.phase == "day":
				m.tick(1.0)
				for i in 4:
					var g: GameState = m.players[i]
					if ouverture[i] < 0 and g.zoo_status()["open"]:
						ouverture[i] = m.day
					if premier[i] < 0 and g.animals.any(func(x): return x.arrived):
						premier[i] = m.day
					for w in g.workers:
						if w.offmap:
							etat["dehors"] += 1.0
						elif w.task.is_empty() and w.path.is_empty():
							etat["inactif"] += 1.0
						elif not w.path.is_empty():
							etat["marche"] += 1.0
						else:
							etat["travail"] += 1.0
						var k := _cle(w)
						var h: Array = hist.get(w.card.id, ["", "", 0.0])
						if k != h[0] and k != "":
							changements += 1
							if k == h[1] and m.time - float(h[2]) < 60.0:
								allers_retours += 1
								var cle_ex := "%s <-> %s" % [h[0].get_slice(":", 0), k.get_slice(":", 0)]
								exemples[cle_ex] = int(exemples.get(cle_ex, 0)) + 1
							if str(h[0]).begins_with("build:"):
								abandons += 1
							hist[w.card.id] = [k, h[0], m.time]
			else:
				m.start_next_day()
		var tot: float = etat.values().reduce(func(x, y): return x + y, 0.0)
		print("PARTIE %d jour %d gagnant %d | marche %d %% travail %d %% inactif %d %% dehors %d %% | changements %d, allers-retours <60 s %d, chantiers quittés %d | ouverture %s, premier animal %s | rep %s | %s" % [
			gi, m.day, m.winner, roundi(100 * etat["marche"] / tot), roundi(100 * etat["travail"] / tot), roundi(100 * etat["inactif"] / tot), roundi(100 * etat["dehors"] / tot),
			changements, allers_retours, abandons, str(ouverture), str(premier), str(m.players.map(func(p): return int(p.rep_points))), str(exemples)])
		m.dispose()
	quit()
