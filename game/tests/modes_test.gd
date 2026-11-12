extends SceneTree
## Modes de partie (ModesPartie) : réserve naturelle (motifs garantis, ni Terrassier ni Paysagiste, aucun aménagement)
## et gestion libre (seul, sans fin, naissances, livre d'or). Lancer : godot --headless --path game --script res://tests/modes_test.gd

var echecs := 0


func _ok(cond: bool, texte: String) -> void:
	print(("  ok   " if cond else "  ÉCHEC ") + texte)
	if not cond:
		echecs += 1


func _init() -> void:
	var data := GameData.load_all()
	# --- Réserve naturelle
	for graine in [11, 4242]:
		var t0 := Time.get_ticks_msec()
		var m := Match.new(data, graine, 2, -1, [{}, {}], [], "nature")
		var g: GameState = m.players[0]
		var c := Vector2(g.map.camp.get_center())
		var manquants: Array = []
		for def in m.data["animals"]["animaux"]:
			if not MapGenerator._motif_present(g.map, MapGenerator._variantes(def["motif"]), c):
				manquants.append(def["id"])
		_ok(manquants.is_empty(), "réserve %d : tous les motifs sur la carte (manquants : %s), carte en %d ms" % [graine, str(manquants), Time.get_ticks_msec() - t0])
		_ok(not m.data["workers"]["metiers"].any(func(x): return x["id"] in ["terrassier", "paysagiste"]), "réserve %d : ni Terrassier ni Paysagiste" % graine)
		_ok(m.data["buildings"]["amenagements"].is_empty() and data["buildings"]["amenagements"].size() > 0, "réserve %d : aucun aménagement (données d'origine intactes)" % graine)
		_ok(str(m.ais[0].strat["taille_zoo"]) == "grand", "réserve %d : IA en grand parc" % graine)
		m.advance_ai_draft()
		var cartes := 0
		for p in m.players:
			for card in p.all_employees():
				cartes += 1
				_ok(not card.metier["id"] in ["terrassier", "paysagiste"], "réserve : carte %s sans aménageur" % card.metier["id"]) if card.metier["id"] in ["terrassier", "paysagiste"] else null
		_ok(cartes > 0, "réserve %d : draft fait (%d cartes)" % [graine, cartes])
		while m.day < 6 and not m.game_over:
			if m.phase == "day":
				m.tick(1.0)
			else:
				m.start_next_day()
		_ok(true, "réserve %d : 6 jours joués, %s animaux" % [graine, str(m.players.map(func(p): return p.animals.size()))])
		m.dispose()
	# --- Gestion libre : une IA seule (le joueur humain ne joue pas en test)
	var z := Match.new(data, 7, 1, -1, [{}], [], "cozy")
	var g: GameState = z.players[0]
	_ok(g.money >= 90.0, "gestion libre : argent de départ %d" % int(g.money))
	z.advance_ai_draft()
	while z.day < 12 and not z.game_over:
		if z.phase == "day":
			z.tick(1.0)
		else:
			z.start_next_day()
	var petits := 0
	for a in g.animals:
		petits += a.petits
	_ok(not z.game_over, "gestion libre : pas de fin au jour %d (réputation %d)" % [z.day, int(g.reputation())])
	_ok(g.sick_animals().is_empty(), "gestion libre : aucun animal malade")
	_ok(not g.carnet.is_empty(), "gestion libre : livre d'or, %d mots (%s)" % [g.carnet.size(), g.carnet[-1]["texte"] if not g.carnet.is_empty() else ""])
	print("  info gestion libre : %d animaux, %d petits" % [g.animals.size(), petits])
	z.dispose()
	# --- Le mode est rejoué tel quel
	var r := Match.new(data, 5, 2, -1, [{}, {}], [], "nature")
	_ok(r.params_replay.get("mode") == "nature", "le mode est noté pour le replay")
	r.dispose()
	print("TOUS LES TESTS PASSENT" if echecs == 0 else "%d ÉCHEC(S)" % echecs)
	quit()
