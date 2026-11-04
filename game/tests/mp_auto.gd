extends Node
## Joueur automatique pour tester le multijoueur avec de vrais jeux connectés :
##   godot --headless --path game -- --mp-hote --mp-jours=4
##   godot --headless --path game -- --mp-rejoindre=127.0.0.1 --mp-jours=4 [--mp-tricher=2] [--mp-partir=2]
## Tout passe par _cmd et le réseau, comme pour un joueur. Écrit MP|… : bilan de la partie, divergence ou non.

var m: Node
var r: Reseau
var jours := 4
var horloge := 0.0
var fait_ce_jour := -1
var pret_ce_jour := -1
var pret_nuit := -1
var triche := -1
var depart := -1
var triche_faite := false
var empreintes_vues := 0
var capture_compte := 0


func _init(principal: Node) -> void:
	m = principal
	jours = int(m.args.get("mp-jours", "4"))
	triche = int(m.args.get("mp-tricher", "-1"))
	depart = int(m.args.get("mp-partir", "-1"))


func _ready() -> void:
	r = Reseau.new()
	r.name = "Reseau"
	r.pseudo = "Hote" if m.args.has("mp-hote") else "Ami"
	r.preparation = float(m.args.get("mp-prep", "1"))
	m.add_child(r)
	r.demarrage.connect(func(params: Dictionary):
		m.reseau = r
		m.partie_reseau = params
		m._start(false)
		print("MP|debut|joueur %d sur %d, graine %d" % [params["index"], params["nb"], params["graine"]]))
	r.coupure.connect(func(t): print("MP|coupure|", t))
	var err: String = r.heberger() if m.args.has("mp-hote") else r.rejoindre(m.args["mp-rejoindre"])
	if err != "":
		print("MP|erreur|", err)


func _process(delta: float) -> void:
	horloge += delta
	if horloge < 0.25:
		return
	horloge = 0.0
	if m.mt == null:
		if r.est_hote and r.joueurs.size() >= int(m.args.get("mp-attendre", "2")):
			r.lancer(true, false)
		return
	var mt: Match = m.mt
	var g: GameState = m.game
	if r.desynchro:
		print("MP|alerte|divergence détectée au jour ", mt.day)
		get_tree().quit(0)
		return
	if m.args.has("mp-capture") and mt.phase == "day" and mt.day == 1:
		capture_compte += 1
		if capture_compte == 6:
			get_viewport().get_texture().get_image().save_png(m.args["mp-capture"])
			print("MP|capture")
	if mt.game_over or mt.day > jours:
		print("MP|fin|jour %d, divergence %s, controles %d, empreinte %d, reputation %s, IA %s" % [mt.day, r.desynchro, r.controles_ok, Commandes.empreinte(mt), mt.players.map(func(p): return roundi(p.rep_points)), mt.ais.map(func(a): return a != null)])
		get_tree().quit(0)
		return
	if depart >= 0 and mt.day >= depart:
		print("MP|depart volontaire au jour ", mt.day)
		r.quitter()
		get_tree().quit(0)
		return
	if triche >= 0 and mt.day >= triche and not triche_faite:
		triche_faite = true
		g.money += 1000.0  # hors du réseau : les autres machines ne le savent pas
		print("MP|triche")
	match mt.phase:
		"draft":
			if mt.current_drafter() == g.index and not mt.draft_pool.is_empty():
				m._cmd("pick_draft", [mt.draft_pool[0]])
		"day":
			_journee(mt, g)
		"night":
			_nuit(mt, g)


func _journee(mt: Match, g: GameState) -> void:
	if fait_ce_jour != mt.day:
		fait_ce_jour = mt.day
		m._deploy_all()
		m._set_speed(16.0 if r.est_hote else 8.0)  # la plus lente doit s'appliquer
		var c := g.map.camp.position
		m._cmd("place", ["batiment", g.building_def("maison"), c + Vector2i(-4 - mt.day * 3, 0)])
		m._cmd("sell_amount", ["bois", 3])
	# Chacun récolte, ou construit ce qui est en chantier
	var libres := g.workers.filter(func(w): return w.task.is_empty() and w.path.is_empty() and not w.offmap)
	for i in libres.size():
		var chantier := g.sites.filter(func(s): return not s.done)
		var cible: Vector2i = chantier[0].rect.position if not chantier.is_empty() and i == 0 else m._nearest_resource("bois" if i % 2 == 0 else "pierre", g.map.camp.get_center())
		m._cmd("order", [[libres[i]], cible])
	if pret_ce_jour != mt.day and mt.time > 40.0:
		pret_ce_jour = mt.day
		if not r.est_pret:
			r.basculer_pret()


func _nuit(mt: Match, g: GameState) -> void:
	if mt.market_stage():
		if mt.current_buyer() == g.index:
			if mt.night_stage == "contrats" and not mt.market_contracts.is_empty() and g.contract_error(mt.market_contracts[0]) == "":
				m._cmd("buy_contract", [mt.market_contracts[0]])
			else:
				m._cmd("pass_turn")
	elif mt.night_stage == "bonus":
		if mt.influence_leader() == g.index:
			m._cmd("confirm_bonus")
	elif mt.night_stage == "equipe" and pret_nuit != mt.day:
		pret_nuit = mt.day
		if not r.est_pret:
			r.basculer_pret()
