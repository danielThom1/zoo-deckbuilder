extends SceneTree
## Contrôle des retours du 05/11, sans interface : grande zone fermée, objectif d'effectif, agence, diagonale qui ferme.
func _init() -> void:
	var data = GameData.load_all()
	var m := Match.new(data, 7, 2, -1, [{}, {}])
	m.advance_ai_draft()
	var g: GameState = m.players[0]
	g.stock["bois"] = 900.0
	g.stock["pierre"] = 900.0
	g.money = 900.0
	# Objectif d'effectif : coché sans attendre le soir
	m.objectifs = [{"id": "effectif", "type": "effectif", "n": 1, "texte": "test"}]
	for i in 200:
		m.tick(GameState.TICK)
	print("objectif coché en journée : ", g.objectifs_faits.has("effectif"))
	# Zone fermée de plus de 40 cases : pas un enclos ; de 16 cases : un enclos
	var c := g.map.camp.get_center()
	var cadre := func(x0: int, y0: int, w: int, h: int) -> void:
		for y in range(y0, y0 + h):
			for x in range(x0, x0 + w):
				if x == x0 or y == y0 or x == x0 + w - 1 or y == y0 + h - 1:
					var s: GameState.Site = g.place("batiment", g.building_def("enclos"), Vector2i(x, y))
					if s:
						s.work = s.travail()
						g._complete(s)
					else:
						print("refus ", Vector2i(x, y), " : ", g.placement_error("batiment", g.building_def("enclos"), Vector2i(x, y)))
	var depart := Vector2i(c.x - 24, c.y - 26)
	cadre.call(depart.x, depart.y, 12, 12)
	cadre.call(depart.x + 14, depart.y, 6, 6)
	var grand := g._fenced_enclosure(depart + Vector2i(3, 3))
	var petit := g._fenced_enclosure(depart + Vector2i(16, 2))
	print("100 cases fermées : enclos = ", grand["closed"], " (", grand.get("reason", ""), ")")
	print("16 cases fermées : enclos = ", petit["closed"], ", ", petit.get("tiles", []).size(), " cases (", petit.get("reason", ""), ")")
	# Agence : le collaborateur reste à son poste, l'échange ne l'y renvoie pas
	var a: GameState.Site = null
	for dy in range(-12, 8):
		for dx in range(-12, 12):
			if a == null and g.placement_error("batiment", g.building_def("agence"), Vector2i(c.x + dx, c.y + dy)) == "":
				a = g.place("batiment", g.building_def("agence"), Vector2i(c.x + dx, c.y + dy))
	print("agence : ", a != null, ", phase ", g.phase)
	a.work = a.travail()
	g._complete(a)
	var w: GameState.Worker = null
	for k in g.hand:
		if not k.is_action():
			g.deploy(k)
			w = g.worker_of(k)
			if w:
				break
	g.order([w], a.rect.position)
	print("poste : ", w.task.get("kind"))
	for i in 400:
		m.tick(GameState.TICK)
	print("arrivé : ", w.path.is_empty(), ", toujours au poste : ", w.task.get("kind"))
	var cand := g.swap_candidates()
	if not cand.is_empty():
		print("échange : ", g.swap_worker(w, cand[0]), ", tâche après : ", w.task.get("kind", "aucune"))
	quit()
