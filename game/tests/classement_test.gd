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
	quit()
