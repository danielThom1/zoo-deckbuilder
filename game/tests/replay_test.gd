extends SceneTree
## Vérifie qu'un replay redonne exactement la partie enregistrée : partie avec un joueur humain simulé (journal), et partie
## d'étude entre IA (dt 1,0). Sans affichage : godot --headless --path game --script res://tests/replay_test.gd

var data: Dictionary
var erreurs := 0


func check(ok: bool, texte: String) -> void:
	print(("  ok   " if ok else "  ÉCHEC ") + texte)
	if not ok:
		erreurs += 1


## Comme main.gd : l'ordre est noté avant d'être exécuté.
func _ordre(mt: Match, p: int, nom: String, args: Array) -> void:
	mt.noter(nom, p, Commandes.coder(args))
	if nom in Commandes.SUR_PARTIE:
		mt.callv(nom, args)
	else:
		mt.players[p].callv(nom, args)


## Un joueur humain très simple : mobilise tout le monde, envoie récolter, achète ce qu'il peut la nuit.
func _humain_du_matin(mt: Match) -> void:
	var g: GameState = mt.players[0]
	for c in g.hand.duplicate():
		if c.is_action():
			_ordre(mt, 0, "play_action", [c])
		elif g.money >= g.salary(c):
			_ordre(mt, 0, "deploy", [c])
	var cases: Array = []
	for y in g.map.h:
		for x in g.map.w:
			if g.map.get_t(x, y) == GameMap.FORET and g.map.passable(x, y):
				cases.append(Vector2i(x, y))
	if cases.is_empty():
		return
	var cible: Vector2i = cases[cases.size() / 2]
	if not g.workers.is_empty():
		_ordre(mt, 0, "order", [g.workers.duplicate(), cible])


func _partie_avec_humain(graine: int) -> void:
	var strat := [null, {"camp": 1}, {"rush_or": true}, {"camp": 2}]
	var mt := Match.new(data, graine, 4, 0, strat)
	while not mt.game_over:
		match mt.phase:
			"draft":
				if mt.is_ai(mt.current_drafter()):
					mt.noter("draft_ia")
					mt.pick_draft(mt.ai_choice())
				else:
					_ordre(mt, 0, "pick_draft", [mt.draft_pool[0]])
			"day":
				if mt.time < 0.01:
					_humain_du_matin(mt)
				if mt.time > 200.0 and mt.players[0].stock["bois"] >= 3.0:
					_ordre(mt, 0, "sell_amount", ["bois", 2])
				if mt.time > 280.0:
					mt.noter("fin_jour")
					mt.players[0].end_day()
				else:
					mt.tick(GameState.TICK)
			"night":
				if mt.market_stage():
					if mt.current_buyer() == 0:
						var g: GameState = mt.players[0]
						var achete := false
						if mt.night_stage == "contrats":
							for d in mt.market_contracts:
								if g.contract_error(d) == "":
									_ordre(mt, 0, "buy_contract", [d])
									achete = true
									break
						if not achete and mt.market_stage() and mt.current_buyer() == 0:
							_ordre(mt, 0, "pass_turn", [])
					else:
						mt.noter("pas_ia")
						mt.step_night()
				elif mt.night_stage == "bonus" and mt.influence_leader() == 0:
					_ordre(mt, 0, "confirm_bonus", [])
				elif mt.night_stage == "equipe":
					for lc in mt.players[0].level_choices.duplicate():
						_ordre(mt, 0, "choose_level_upgrade", [lc["card"], lc["options"][0]])
					mt.noter("jour_suivant")
					mt.players[0].start_next_day()
				else:
					mt.noter("pas_ia")
					mt.step_night()
	print("  partie jouée : jour %d, %d ordres au journal, réputations %s" % [mt.day, mt.journal.size(), str(mt.players.map(func(p): return int(p.rep_points)))])
	var r := Replay.depuis_partie(mt, 1)
	var m2 := r.creer_partie(GameData.load_all())
	var garde := 0
	while not m2.game_over and garde < 2000000:
		garde += 1
		if m2.phase == "day":
			r.ordres_du_pas(m2)
			if m2.phase == "day" and not m2.game_over:
				m2.tick(r.dt)
		else:
			r.coup_suivant(m2)
			if r.diverge:
				break
	check(r.conforme(m2), "graine %d : le replay du journal redonne la même partie (jour %d, %s)" % [graine, m2.day, str(m2.players.map(func(p): return int(p.rep_points)))])


func _partie_etude(graine: int) -> void:
	var strat: Array = JSON.parse_string(JSON.stringify([{"camp": 1}, {"rush_or": true}, {"preference_palier": 2.3}, {"camp": 2}]))
	var m := Match.new(data, graine, 4, -1, strat.duplicate(true))
	m.advance_ai_draft()
	while not m.game_over:
		if m.phase == "day":
			m.tick(1.0)
		elif m.phase == "night":
			m.start_next_day()
	var r := Replay.new()
	r.graine = graine
	r.strategies = strat
	r.automatique = true
	r.dt = 1.0
	r.attendu = {"gagnant": m.winner, "jour": m.day, "rep": m.players[m.winner].rep_points}
	var m2 := r.creer_partie(GameData.load_all())
	while not m2.game_over:
		if m2.phase == "day":
			m2.tick(r.dt)
		else:
			r.coup_suivant(m2)
	check(r.conforme(m2) and Commandes.empreinte(m) == Commandes.empreinte(m2), "graine %d : le replay d'étude redonne la même partie (jour %d)" % [graine, m2.day])


func _init() -> void:
	data = GameData.load_all()
	_partie_etude(31)
	_partie_avec_humain(77)
	print("TOUT EST CONFORME" if erreurs == 0 else "%d ERREUR(S)" % erreurs)
	quit(erreurs)
