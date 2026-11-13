extends SceneTree
## Enregistre la partie d'IA qui sert de fond vivant au menu (main.gd, FOND_PARTIE) : 4 IA du niveau difficile jouent
## jusqu'au matin du jour --jour (10 par défaut), puis la partie est écrite au format de la sauvegarde. À refaire quand la
## version de la sauvegarde change (Sauvegarde.VERSION) : sinon le menu garde son image fixe.
## godot --headless --path game --script res://tests/vitrine_fond.gd -- [--seed=11] [--jour=10]

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var graine := int(args.get("seed", "11"))
	var jour := int(args.get("jour", "10"))
	var strategies: Array = []
	var lu = JSON.parse_string(FileAccess.get_file_as_string("res://data/ia_niveaux.json"))
	if lu is Dictionary:
		strategies = lu["niveaux"]["difficile"]["strategies"]
	while strategies.size() < 4:
		strategies.append({})
	var mt := Match.new(GameData.load_all(), graine, 4, -1, strategies.slice(0, 4), [], "course")
	while mt.phase == "draft":
		mt.pick_draft(mt.ai_choice())
	while mt.day < jour and not mt.game_over:
		if mt.phase == "day":
			mt.tick(0.5)
		else:
			mt.start_next_day()
	Sauvegarde.ecrire_dans(mt, "res://assets/vitrine/partie_menu.txt")
	print("Partie du menu : graine %d, jour %d, animaux %s, réputations %s" % [graine, mt.day,
		str(mt.players.map(func(p): return p.animals.size())), str(mt.players.map(func(p): return int(p.reputation())))])
	quit()
