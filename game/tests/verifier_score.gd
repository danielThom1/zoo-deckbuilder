extends SceneTree
## Vérifie un score de défi : rejoue le replay envoyé avec lui (colonne « replay » de la table scores de Supabase,
## copiée dans un fichier) et donne la réputation finale du joueur. Si elle diffère du score, ou si la partie diverge,
## le score est faux : cocher « exclu » dans la table. Sinon cocher « verifie ».
## godot --headless --path game --script res://tests/verifier_score.gd -- --fichier=C:/chemin/replay.json


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var d = JSON.parse_string(FileAccess.get_file_as_string(str(args.get("fichier", ""))))
	if not d is Dictionary:
		print("Fichier illisible.")
		quit(1)
		return
	var r := Replay.depuis_dict(d)
	if r.version != Reseau.version_jeu():
		print("Attention : partie jouée avec une autre version du jeu, le replay peut diverger.")
	var mt := r.creer_partie(GameData.load_all())
	while not mt.game_over:
		if mt.phase == "day":
			r.ordres_du_pas(mt)
			if mt.phase == "day" and not mt.game_over:
				mt.tick(r.dt)
		else:
			r.coup_suivant(mt)
			if r.diverge:
				break
	var rep := mt.players[r.humain].reputation()
	print("Défi %s, graine %d : réputation finale %.1f (annoncée %.1f), jour %d." % [r.defi, r.graine, rep, float(d.get("rep", -1)), mt.day])
	print("SCORE CONFIRMÉ" if r.conforme(mt) and absf(rep - float(d.get("rep", rep))) < 0.05 else "SCORE NON CONFIRMÉ (partie différente)")
	quit()
