extends SceneTree
## Classement en ligne : connexion anonyme et lecture du classement d'un défi. Avec --envoi, envoie aussi un score sur le
## défi d'essai « essai_connexion » (jamais montré dans le jeu ; à supprimer de la table ensuite).
## godot --headless --path game --script res://tests/classement_test.gd [-- --envoi]


func _initialize() -> void:
	_lancer.call_deferred()


func _lancer() -> void:
	var c := Classement.new()
	root.add_child(c)
	print("  actif : ", c.actif())
	var jeton: String = await c._jeton()
	print("  connexion anonyme : ", "ok" if jeton != "" else "ÉCHEC " + c.erreur)
	var r: Dictionary = await c.classement("saules")
	print("  classement « saules » : ", r if not r.is_empty() else "ÉCHEC " + c.erreur)
	if "--envoi" in OS.get_cmdline_user_args():
		var e = await c._rpc("soumettre_score", {"p_defi": "essai_connexion", "p_pseudo": "Essai", "p_score": 1.0, "p_version": "essai",
			"p_replay": {"essai": true}})
		print("  envoi d'essai : ", e if e != null else "ÉCHEC " + c.erreur)
	if "--partie" in OS.get_cmdline_user_args():
		# Une vraie partie de défi (le joueur passe ses tours), envoyée avec son replay sous l'identifiant « essai_replay »
		var mt := Match.new(GameData.load_all(), int(Defis.trouver("saules")["graine"]), 4, 0, Defis.strategies(), [], "course", "saules")
		while not mt.game_over:
			match mt.phase:
				"draft":
					if mt.is_ai(mt.current_drafter()):
						mt.noter("draft_ia")
						mt.pick_draft(mt.ai_choice())
					else:
						var carte = mt.draft_pool[0]
						mt.noter("pick_draft", 0, Commandes.coder([carte]))
						mt.pick_draft(carte)
				"day":
					mt.tick(GameState.TICK)
				"night":
					if mt.market_stage() and mt.current_buyer() == 0:
						mt.noter("pass_turn", 0, [])
						mt.pass_turn()
					elif mt.night_stage == "bonus" and mt.influence_leader() == 0:
						mt.noter("confirm_bonus", 0, [])
						mt.confirm_bonus()
					elif mt.night_stage == "equipe":
						mt.noter("jour_suivant")
						mt.start_next_day()
					else:
						mt.noter("pas_ia")
						mt.step_night()
		var d := Replay.vers_dict(Replay.depuis_partie(mt, 0))
		print("  partie jouée : jour %d, réputations %s, replay de %d Ko" % [mt.day, str(mt.players.map(func(p): return int(p.reputation()))), JSON.stringify(d).length() / 1024])
		mt.defi = "essai_replay"
		Statistiques.charger()
		Statistiques.donnees["pseudo"] = "Essai"  # en mémoire seulement : rien n'est écrit
		var envoi: Dictionary = await c.soumettre(mt, 0)
		print("  envoi de la partie : ", envoi if not envoi.is_empty() else "ÉCHEC " + c.erreur)
	quit()
