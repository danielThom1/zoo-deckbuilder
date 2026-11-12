extends SceneTree
## Tirages séparés (mode défi) : deux parties de même graine, jouées par des IA différentes, voient sortir au marché
## les mêmes collaborateurs, cartes d'action et espèces dans le même ordre, et les mêmes événements chaque jour.
## Lancer : godot --headless --path game --script res://tests/defi_test.gd

var echecs := 0


func _ok(cond: bool, texte: String) -> void:
	print(("  ok   " if cond else "  ÉCHEC ") + texte)
	if not cond:
		echecs += 1


func _signature(c: GameState.Card) -> String:
	return "%s/%s/%s" % [c.nom, c.metier["id"], ",".join(c.traits)]


## Joue la partie jusqu'au jour `jours` et note, dans l'ordre d'apparition, ce qui est sorti au marché.
func _jouer(data: Dictionary, graine: int, strategies: Array, jours: int) -> Dictionary:
	var m := Match.new(data, graine, 4, -1, strategies)
	var vus := {"ouvriers": [], "actions": [], "contrats": [], "evenements": []}
	var deja := {}
	m.advance_ai_draft()
	var jour := 0
	while m.day <= jours and not m.game_over:
		if m.phase == "day":
			if m.day != jour:
				jour = m.day
				vus["evenements"].append(str(m.current_event.get("id", "-")))
			for c in m.market_workers:
				if not deja.has(c):
					deja[c] = true
					vus["ouvriers"].append(_signature(c))
			for c in m.market_actions:
				if not deja.has(c):
					deja[c] = true
					vus["actions"].append(str(c.action["id"]))
			for d in m.market_contracts:
				if not deja.has(d["id"]):
					deja[d["id"]] = true
					vus["contrats"].append(str(d["id"]))
			m.tick(1.0)
		else:
			m.start_next_day()
	m.dispose()
	return vus


func _prefixe(a: Array, b: Array) -> bool:
	var n := mini(a.size(), b.size())
	return a.slice(0, n) == b.slice(0, n)


func _init() -> void:
	var data := GameData.load_all()
	var a := _jouer(data, 7, [{}, {}, {}, {}], 5)
	var b := _jouer(data, 7, [{"explore": 0.35}, {"taille_zoo": "petit"}, {"rush_or": true}, {"explore": 0.2}], 5)
	for k in ["ouvriers", "actions", "contrats"]:
		_ok(_prefixe(a[k], b[k]) and a[k].size() >= 5, "%s : même ordre de sortie (%d et %d sortis)" % [k, a[k].size(), b[k].size()])
	_ok(a["evenements"] == b["evenements"], "événements des jours : %s" % str(a["evenements"]))
	var c := _jouer(data, 8, [{}, {}, {}, {}], 2)
	_ok(c["contrats"] != a["contrats"].slice(0, c["contrats"].size()), "une autre graine change le marché")
	print("TOUS LES TESTS PASSENT" if echecs == 0 else "%d ÉCHEC(S)" % echecs)
	quit()
