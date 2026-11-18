extends SceneTree
## Version anglaise : la table se charge et quelques textes typiques sont traduits (exacts, gabarits, morceaux).
## godot --headless --path game --script res://tests/traduction_test.gd

func _init() -> void:
	var t := Traduction.new()
	print("entrées exactes : ", t.exact.size())
	var ok := 0
	var cas := {
		"Réglages": "Settings",
		"JOUR 3": "DAY 3",
		"Salaire 4": "Wage 4",
		"Vendre 12 · +3": "Sell 12 · +3",
		"Lion · Afrique": "Lion · Africa",
		"Zoo fermé : Construisez l'entrée du zoo": "Zoo closed: Build the zoo entrance",
		"RÉSERVE NATURELLE": "NATURE RESERVE",
		"Pris par PanZoo": "Taken by PanZoo",
		"01 · PARTIE CLASSIQUE": "01 · CLASSIC GAME",
		"fin dans 4 j 14 h": "ends in 4 d 14 h",
		"[b]Gourmande[/b]": "[b]Greedy[/b]",
		"◆◇◇ Commun": "◆◇◇ Common",
		"25 + 1 or": "25 + 1 gold",
		"« Défaite. J'ai déjà rédigé le communiqué : il y est écrit que vous étiez en charge. »": "“Defeat. I've already written the press release: it says you were in charge.”",
		"DOSSIER EN COURS · GESTION LIBRE": "FILE IN PROGRESS · FREE PLAY",
		"SAUVEGARDÉ IL Y A 3 J": "SAVED 3 D AGO",
		"Distraite · 40 % de chance par minute d'abandonner sa tâche (redevient inactif)": "Absent-minded · 40% chance per minute of dropping their task (goes back to idle)",
		"+20 % de productivité pour tous les collaborateurs.": "",
	}
	for fr in cas:
		var en := t.traduire(fr)
		var attendu: String = cas[fr]
		var bon := attendu == "" or en == attendu
		if bon:
			ok += 1
		print("%s  %s → %s" % ["ok  " if bon else "FAUX", fr, en])
	Traduction.choisir("en")
	print("tr : ", TranslationServer.translate("Réglages"))
	print("%d / %d" % [ok, cas.size()])
	quit()
