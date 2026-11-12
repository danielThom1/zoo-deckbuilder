class_name ModesPartie
## Modes de partie (12/11/2026). Un mode ajuste une copie des données du jeu avant la création de la carte et des
## joueurs : les règles lisent ces valeurs comme d'habitude. Le mode est noté dans les paramètres du replay et dans
## la sauvegarde. Les données d'origine (GameData) ne sont jamais modifiées.
##   course : la partie habituelle (premier à l'objectif de réputation).
##   nature : réserve naturelle. Ni Terrassier ni Paysagiste, aucun aménagement de terrain ; la carte contient au
##            moins une fois le motif de chaque espèce, réparti sur toute la carte ; enclos plus grands, IA en grand parc.
##   cozy   : gestion libre. Seul, sans fin ni course, plus d'argent au départ, pas de maladie ; carnet des visiteurs
##            chaque soir et naissances chez les animaux heureux.

const NOMS := {"course": "Course", "nature": "Réserve naturelle", "cozy": "Gestion libre"}
const SANS_AMENAGEMENT := ["terrassier", "paysagiste"]


static func appliquer(source: Dictionary, mode: String) -> Dictionary:
	if mode == "" or mode == "course":
		return source
	var d: Dictionary = source.duplicate(true)
	var B: Dictionary = d["buildings"]
	match mode:
		"nature":
			d["workers"]["metiers"] = d["workers"]["metiers"].filter(func(m): return not m["id"] in SANS_AMENAGEMENT)
			for id in d["workers"].get("evolutions", {}):
				var evo: Dictionary = d["workers"]["evolutions"][id]
				evo["vers"] = evo["vers"].filter(func(x): return not x in SANS_AMENAGEMENT)
			B["amenagements"] = []
			B["regles_amenagement"]["metiers"] = []
			B["carte"]["motifs_garantis"] = d["animals"]["animaux"]
			B["zoo"]["enclos_max_cases"] = 60
		"cozy":
			B["partie"]["argent_depart"] = 90
			B["partie"]["objectif_reputation"] = 1000000
			B["partie"]["jour_max"] = 100000
			B["partie"]["carnet"] = true
			for k in ["proba_nuit", "proba_faim", "proba_sale", "contagion"]:
				B["zoo"]["maladie"][k] = 0.0
			B["zoo"]["naissances"] = {"proba": 0.2, "max": 2, "part_attractivite": 0.3, "proprete_min": 60.0}
	d["mode"] = mode
	return d


## Réglage imposé aux IA d'un mode (la réserve naturelle demande un grand parc).
static func strategie(strat, mode: String):
	if strat == null or mode != "nature":
		return strat
	var s: Dictionary = strat.duplicate(true)
	s["taille_zoo"] = "grand"
	s["agrandir"] = true
	return s
