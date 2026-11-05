class_name Commandes
extends RefCounted
## Multijoueur : chaque machine fait tourner la même partie (même graine, même pas de temps). Seuls les ordres des joueurs
## circulent, et chacun les applique au même moment. Ici : le codage des ordres pour le réseau, leur exécution et
## l'empreinte de la partie, qui vérifie que toutes les machines ont bien le même état.

## Ordres du joueur, sur GameState (ou Match pour SUR_PARTIE). Rien d'autre n'est exécuté.
const ORDRES := ["order", "place", "deploy", "recall", "cancel_site", "demolish", "install_animal", "construire_proposition", "sell_amount",
	"buy_material", "buy_label", "launch_campaign", "ceder_carte", "swap_worker", "play_action", "play_cadre", "hire", "buy_contract", "buy_action",
	"pick_bonus", "choose_level_upgrade", "fire", "fire_paid", "apply_upgrade", "hippo_swap", "recruit_replace", "cancel_pending",
	"report_start", "report_goto", "publish_article", "accuse_worker"]
const SUR_PARTIE := ["pick_draft", "pass_turn", "confirm_bonus"]


## Remplace les cartes, ouvriers et chantiers par leur identifiant : seules des valeurs simples passent sur le réseau.
static func coder(v: Variant) -> Variant:
	if v is GameState.Card:
		return {"_c": v.id}
	if v is GameState.Worker:
		return {"_o": v.card.id}
	if v is GameState.Site:
		return {"_s": v.rect.position}
	if v is Array:
		return v.map(func(x): return coder(x))
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = coder(v[k])
		return d
	return v


## L'inverse, pour le joueur g. `ok` passe à faux si un objet n'existe plus (ouvrier déjà rentré, chantier supprimé).
static func decoder(v: Variant, g: GameState, ok: Array) -> Variant:
	if v is Array:
		return v.map(func(x): return decoder(x, g, ok))
	if v is Dictionary:
		if v.has("_c"):
			var c := carte(g, int(v["_c"]))
			if c == null:
				ok[0] = false
			return c
		if v.has("_o"):
			for w in g.workers:
				if w.card.id == int(v["_o"]):
					return w
			ok[0] = false
			return null
		if v.has("_s"):
			var s := g.site_at(v["_s"])
			if s == null:
				ok[0] = false
			return s
		var d := {}
		for k in v:
			d[k] = decoder(v[k], g, ok)
		return d
	return v


## Une carte d'après son numéro : équipe du joueur, marché du soir ou tirage du draft.
static func carte(g: GameState, id: int) -> GameState.Card:
	for groupe in [g.hand, g.deck, g.discard, g.mt.market_workers, g.mt.market_actions, g.mt.draft_pool]:
		for c in groupe:
			if c.id == id:
				return c
	for w in g.workers:
		if w.card.id == id:
			return w.card
	return null


## Exécute un ordre de joueur. Renvoie le message d'erreur éventuel, à montrer à ce joueur.
static func executer(mt: Match, p: int, nom: String, args: Array) -> String:
	var g: GameState = mt.players[p]
	var ok := [true]
	var valeurs: Array = decoder(args, g, ok)
	if not ok[0]:
		return ""
	var r: Variant = null
	if nom in SUR_PARTIE:
		match nom:
			"pick_draft":
				if mt.phase == "draft" and mt.current_drafter() == p and mt.draft_pool.has(valeurs[0]):
					mt.pick_draft(valeurs[0])
			"pass_turn":
				if mt.market_stage() and mt.current_buyer() == p:
					mt.pass_turn()
			"confirm_bonus":
				if mt.phase == "night" and mt.night_stage == "bonus" and mt.influence_leader() == p:
					mt.confirm_bonus()
	elif nom in ORDRES:
		r = g.callv(nom, valeurs)
	return r if r is String else ""


## Décision de l'hôte, valable pour tous : l'avancée de la partie quand un joueur tarde, et les IA.
static func decision(mt: Match, nom: String, valeur: int) -> void:
	match nom:
		"pas_ia":
			mt.step_night()
		"draft_ia":
			if mt.phase == "draft":
				mt.pick_draft(mt.ai_choice())
		"tour_passe":
			if mt.market_stage():
				mt.pass_turn()
		"bonus_passe":
			if mt.phase == "night" and mt.night_stage == "bonus":
				mt.confirm_bonus()
		"fin_jour":
			mt.end_day()
		"jour_suivant":
			mt.start_next_day()
		"ia_reprend":
			mt.remplacer_par_ia(valeur)


## Résumé de l'état de la partie. Le hasard y compte : deux machines qui ont divergé ne tirent plus les mêmes nombres.
static func empreinte(mt: Match) -> int:
	var morceaux: Array = [mt.day, mt.phase, snappedf(mt.time, 0.01), mt.rng.state, mt.night_stage, mt.winner]
	for g in mt.players:
		morceaux.append_array([g.rng.state, snappedf(g.money, 0.01), snappedf(g.rep_points, 0.01), snappedf(g.stock["bois"], 0.01),
			snappedf(g.stock["pierre"], 0.01), snappedf(g.stock["or"], 0.01), g.sites.size(), g.animals.size(), g.hand.size(), g.workers.size()])
		for w in g.workers:
			morceaux.append_array([w.card.id, snappedf(w.pos.x, 0.01), snappedf(w.pos.y, 0.01)])
	return hash(str(morceaux))
