extends SceneTree
## Duel de deux réglages d'IA : 2 joueurs de chaque côté sur la même carte, places alternées d'une partie à l'autre.
##   godot --headless --path game --script res://tests/duel_ia.gd -- --a=Équilibrée --b="Ancienne IA" --parties=8 [--depart=0]
## Ou une ligue : --ligue=a,b,c,d,e : 4 réglages différents à chaque partie, chacun autant de fois.
## Les noms sont ceux de balance_sim.gd ou de VARIANTES. Écrit une ligne DUEL|… par partie.

## Réglages testés un par un, pour isoler ce qui aide ou nuit.
const VARIANTES := {
	"note": {"nom": "note", "adaptatif": false, "agrandir": false},
	"agrandir": {"nom": "agrandir", "adaptatif": false, "agrandir": true, "score_simple": true},
	"adaptatif": {"nom": "adaptatif", "adaptatif": true, "agrandir": false, "score_simple": true},
	"tout_sauf_note": {"nom": "tout_sauf_note", "adaptatif": true, "agrandir": true, "score_simple": true},
	"complet": {"nom": "complet"},
	"sans_zoo_j1": {"nom": "sans_zoo_j1", "sans_zoo_j1": true},
	"sans_camp": {"nom": "sans_camp", "sans_camp": true},
	"sans_marge": {"nom": "sans_marge", "sans_marge": true},
	"sans_mine_apres": {"nom": "sans_mine_apres", "sans_mine_apres": true},
	"sans_roster": {"nom": "sans_roster", "sans_roster": true},
	"sans_epargne": {"nom": "sans_epargne", "sans_epargne": true},
	"sans_besoin": {"nom": "sans_besoin", "sans_besoin": true},
	"sans_roles": {"nom": "sans_roles", "sans_roles": true},
	"sans_route_tot": {"nom": "sans_route_tot", "sans_route_tot": true},
	"sans_les_deux": {"nom": "sans_les_deux", "sans_roles": true, "sans_route_tot": true},
}


func _init() -> void:
	var args := {}
	for s in OS.get_cmdline_user_args():
		var kv := s.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var liste: Array = load("res://tests/balance_sim.gd").STRATEGIES
	var trouve := func(nom: String) -> Dictionary:
		if VARIANTES.has(nom):
			return VARIANTES[nom]
		for st in liste:
			if st["nom"] == nom:
				return st
		push_error("Stratégie inconnue : " + nom)
		return {"nom": nom}
	var a: Dictionary = trouve.call(args.get("a", "Équilibrée"))
	var b: Dictionary = trouve.call(args.get("b", "Ancienne IA"))
	var data := GameData.load_all()
	var depart := int(args.get("depart", "0"))
	for i in int(args.get("parties", "8")):
		var gi := depart + i
		var picks := [a, b, a, b] if gi % 2 == 0 else [b, a, b, a]
		if args.has("ligue"):
			var noms: PackedStringArray = args["ligue"].split(",")
			picks = []
			for k in 4:
				picks.append(trouve.call(noms[(gi + k * (1 + gi % 2)) % noms.size()]))
		var m := Match.new(data, 5000 + gi * 23, 4, -1, picks)
		m.advance_ai_draft()
		while not m.game_over:
			if m.phase == "day":
				m.tick(1.0)
			elif m.phase == "night":
				m.start_next_day()
		var reps: Array = m.players.map(func(p): return p.reputation())
		print("DUEL|%d|%s|%d|%s|%s" % [gi, picks[m.winner]["nom"], m.day, str(reps), str(picks.map(func(p): return p["nom"]))])
		m.dispose()
	quit(0)
