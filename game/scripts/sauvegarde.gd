class_name Sauvegarde
extends RefCounted
## Sauvegarde automatique de la partie : une photo prise chaque matin, avant le déploiement. À ce moment il n'y a ni
## ouvrier sur le terrain ni visiteur, donc aucune tâche à restituer ; « Continuer » reprend au début de ce jour.

const CHEMIN := "user://sauvegarde.txt"
const CHEMIN_JOURNEE := "user://sauvegarde_journee.txt"  # ordres donnés depuis le matin, au retour au menu
const VERSION := 2  # 2 : files du marché (tirages séparés)


static func existe() -> bool:
	return FileAccess.file_exists(CHEMIN)


## Résumé pour le menu : {"jour", "joueurs"}, ou {} si le fichier est illisible ou d'une ancienne version.
static func resume() -> Dictionary:
	var d := _lire()
	if d.is_empty():
		return {}
	# Pour la fiche « Dossier en cours » du menu : carte, mode, réputation de chacun, espèces du joueur, date de sauvegarde
	var j: Array = d["joueurs"]
	var ias: Array = d.get("ias", [])
	return {"jour": d["match"]["day"], "joueurs": j.size(), "graine": int(d.get("seed", 0)), "mode": str(d.get("mode", "course")),
		"defi": str(d.get("defi", "")), "noms": d["match"].get("names", []), "reps": j.map(func(x): return float(x.get("rep", 0.0))),
		"humains": range(j.size()).filter(func(k): return k >= ias.size() or ias[k] == null).size(),
		"especes": j[0]["animals"].filter(func(a): return a.get("arrived", false)).size() if not j.is_empty() else 0,
		"modifie": FileAccess.get_modified_time(CHEMIN)}


static func effacer() -> void:
	if existe():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CHEMIN))
	effacer_journee()


static func _lire() -> Dictionary:
	if not existe():
		return {}
	var v = str_to_var(FileAccess.get_file_as_string(CHEMIN))
	return v if v is Dictionary and v.get("version", 0) == VERSION else {}


static func _carte(c: GameState.Card) -> Dictionary:
	return {"id": c.id, "nom": c.nom, "metier": c.metier, "traits": Array(c.traits), "niveau": c.niveau, "jours": c.jours_travailles, "xp": c.xp,
		"upgrades": c.upgrades, "upgrade_names": Array(c.upgrade_names), "last": c.last_work_tile, "action": c.action, "perso": c.perso}


static func _vers_carte(d: Dictionary) -> GameState.Card:
	var c := GameState.Card.new()
	c.id = d["id"]
	c.nom = d["nom"]
	c.metier = d["metier"]
	c.traits.assign(d["traits"])
	c.niveau = d["niveau"]
	c.jours_travailles = d["jours"]
	c.xp = d["xp"]
	c.upgrades = d["upgrades"]
	c.upgrade_names.assign(d["upgrade_names"])
	c.last_work_tile = d["last"]
	c.action = d["action"]
	c.perso = d["perso"]
	return c


static func _cartes(a: Array) -> Array:
	return a.map(func(c): return _carte(c))


static func ecrire(m: Match) -> void:
	var joueurs := []
	for p in m.players:
		joueurs.append({"money": p.money, "influence": p.influence, "publicite": p.publicite, "campaign": p.campaign, "stock": p.stock,
			"deck": _cartes(p.deck), "discard": _cartes(p.discard), "hand": _cartes(p.hand), "next_id": p.next_id,
			"sites": p.sites.map(func(s): return {"id": s.id, "kind": s.kind, "def": s.def, "rect": s.rect, "work": s.work, "done": s.done, "paid": s.paid, "savings": s.savings}),
			"contracts": p.contracts, "pending": p.pending_installs, "day_bonus": p.day_bonus, "night_bonus": p.night_bonus,
			"animals": p.animals.map(func(a): return {"def": a.def, "tiles": Array(a.tiles), "pattern": Array(a.pattern_tiles), "arrived": a.arrived, "fed": a.fed, "food": a.food,
				"key": a.key, "park": a.park, "sick": a.sick, "heal": a.heal, "sick_nights": a.sick_nights, "starved": a.starved, "petits": a.petits}),
			"carnet": p.carnet,
			"objectifs_faits": p.objectifs_faits, "record_visiteurs": p.record_visiteurs, "presse_jours": p.presse_jours, "vus": p.vus,
			"rep": p.rep_points, "labels": p.labels_owned, "sources": p.rep_sources, "proprete": p.proprete, "rng": p.rng.state, "embellissement": p.embellissement,
			"decorations": p.decorations.map(func(d): return [d["t"].x, d["t"].y, d["id"]]),
			"tiles": p.map.tiles, "road": p.map.road, "bridge": p.map.bridge, "res_left": p.map.res_left})
	var ias := []
	for ai in m.ais:
		ias.append(null if ai == null else {"strat": ai.strat, "zoo_rect": ai.zoo_rect, "target_rect": ai.target_rect, "expanded": ai.expanded, "entrance": ai.entrance,
			"shop_rect": ai.shop_rect, "plans": ai.plans, "reserved": ai.reserved, "fence_tiles": ai.fence_tiles,
			"agrandissements": ai.agrandissements, "agrandis": ai.agrandis, "agrandi_jour": ai.agrandi_jour, "agrandir_refus": ai.agrandir_refus,
			"roster_kiosque": ai.roster_kiosque, "epargne": ai.epargne, "agence_voulue": ai.agence_voulue, "cabinet_voulu": ai.cabinet_voulu})
	var d := {"version": VERSION, "seed": m.seed_value, "mode": m.mode, "defi": m.defi, "joueurs": joueurs, "ias": ias, "match": {"objectifs": m.objectifs, "day": m.day, "next_card_id": m.next_card_id, "perso_bag": m.perso_bag,
		"names": Array(m.names), "market_workers": _cartes(m.market_workers), "market_contracts": m.market_contracts, "market_actions": _cartes(m.market_actions),
		"current_event": m.current_event, "history": m.history, "rng": m.rng.state, "pas": m.pas,
		"rng_marche": m.rng_marche.state, "i_ouvriers": m.i_ouvriers, "i_actions": m.i_actions, "file_contrats": m.file_contrats}}
	var f := FileAccess.open(CHEMIN, FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(d))
		f.close()
	effacer_journee()  # un nouveau matin : la journée précédente n'a plus à être rejouée


## Retour au menu en cours de journée : les ordres donnés depuis le matin. « Continuer » repart de la photo du matin
## et les rejoue en accéléré (la partie est déterministe), jusqu'au pas où le joueur s'était arrêté.
static func ecrire_journee(m: Match) -> void:
	var d := {"seed": m.seed_value, "day": m.day, "pas_matin": m.pas_matin, "pas": m.pas, "ordres": m.journal.slice(m.journal_matin)}
	var f := FileAccess.open(CHEMIN_JOURNEE, FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(d))
		f.close()


static func lire_journee() -> Dictionary:
	if not FileAccess.file_exists(CHEMIN_JOURNEE):
		return {}
	var v = str_to_var(FileAccess.get_file_as_string(CHEMIN_JOURNEE))
	return v if v is Dictionary else {}


static func effacer_journee() -> void:
	if FileAccess.file_exists(CHEMIN_JOURNEE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CHEMIN_JOURNEE))


## Après reprendre() : rejoue la journée enregistrée au retour au menu, s'il y en a une pour ce matin-là.
static func rattraper_journee(m: Match) -> bool:
	var j := lire_journee()
	if j.is_empty() or int(j["day"]) != m.day or int(j["seed"]) != m.seed_value or int(j["pas_matin"]) != m.pas:
		return false
	var r := Replay.new()
	r.journal = j["ordres"]
	m.journal = r.journal.duplicate()  # un nouveau retour au menu ce jour-là enregistrera toute la journée
	m.journal_matin = 0
	var cible := int(j["pas"])
	var garde := 0
	while not m.game_over and garde < 500000:
		garde += 1
		if m.phase == "day":
			if m.pas >= cible and r.prochain >= r.journal.size():
				break
			r.ordres_du_pas(m)
			if m.phase == "day" and not m.game_over:
				m.tick(GameState.TICK)
		else:
			if r.prochain >= r.journal.size():
				break
			r.coup_suivant(m)
			if r.diverge:
				break
	for p in m.players:
		p.annonces.clear()
	return true


## Recrée la partie au matin sauvegardé. Les IA n'ont pas encore joué ce matin : l'appelant lance reprendre().
static func charger(data: Dictionary) -> Match:
	var d := _lire()
	if d.is_empty():
		return null
	var human: int = d["ias"].find(null)
	var strategies: Array = d["ias"].map(func(a): return null if a == null else a["strat"])
	var m := Match.new(data, d["seed"], d["joueurs"].size(), human, strategies, [], str(d.get("mode", "course")), str(d.get("defi", "")))
	var w: Dictionary = d["match"]
	m.objectifs = w.get("objectifs", [])
	m.day = w["day"]
	m.next_card_id = w["next_card_id"]
	m.perso_bag = w["perso_bag"]
	m.names.assign(w["names"])
	m.market_workers = w["market_workers"].map(func(c): return _vers_carte(c))
	m.market_contracts = w["market_contracts"]
	m.market_actions = w["market_actions"].map(func(c): return _vers_carte(c))
	m.current_event = w["current_event"]
	m.history = w["history"]
	m.rng.state = w["rng"]
	m.rng_marche.state = w["rng_marche"]
	m.i_ouvriers = w["i_ouvriers"]
	m.i_actions = w["i_actions"]
	m.file_contrats = w["file_contrats"]
	m.pas = int(w.get("pas", 0))
	m.pas_matin = m.pas
	m.phase = "day"
	m.time = 0.0
	m.draft_pool.clear()
	m.draft_reserve.clear()
	for i in m.players.size():
		var p: GameState = m.players[i]
		var j: Dictionary = d["joueurs"][i]
		p.money = j["money"]
		p.influence = j["influence"]
		p.publicite = j["publicite"]
		p.campaign = j["campaign"]
		p.stock = j["stock"]
		p.deck.assign(j["deck"].map(func(c): return _vers_carte(c)))
		p.discard.assign(j["discard"].map(func(c): return _vers_carte(c)))
		p.hand.assign(j["hand"].map(func(c): return _vers_carte(c)))
		p.next_id = j["next_id"]
		p.contracts = j["contracts"]
		p.pending_installs = j["pending"]
		p.day_bonus = j["day_bonus"]
		p.night_bonus = j["night_bonus"]
		p.objectifs_faits = j.get("objectifs_faits", {})
		p.record_visiteurs = int(j.get("record_visiteurs", 0))
		p.presse_jours = int(j.get("presse_jours", 0))
		p.vus = j.get("vus", {})
		p.rep_points = j["rep"]
		p.labels_owned = j["labels"]
		p.rep_sources = j["sources"]
		p.proprete = j["proprete"]
		p.embellissement = float(j.get("embellissement", 0.0))
		p.decorations = j.get("decorations", []).map(func(d): return {"t": Vector2i(int(d[0]), int(d[1])), "id": str(d[2])})
		p.rng.state = j["rng"]
		p.map.tiles = j["tiles"]
		p.map.road = j["road"]
		p.map.bridge = j["bridge"]
		p.map.res_left = j["res_left"]
		for y in p.map.h:
			for x in p.map.w:
				p.map.refresh_cell(x, y)
		p.sites.clear()
		p.occupancy.clear()
		for sd in j["sites"]:
			var s := GameState.Site.new()
			s.id = sd["id"]
			s.kind = sd["kind"]
			s.def = sd["def"]
			s.rect = sd["rect"]
			s.work = sd["work"]
			s.done = sd["done"]
			s.paid = sd["paid"]
			s.savings = sd["savings"]
			p.sites.append(s)
			for t in p._tiles(s.rect):
				p.occupancy[t] = s
		p.carnet = j.get("carnet", [])
		p.animals.clear()
		for ad in j["animals"]:
			var a := GameState.Animal.new()
			a.def = ad["def"]
			a.tiles.assign(ad["tiles"])
			a.pattern_tiles.assign(ad["pattern"])
			a.arrived = ad["arrived"]
			a.fed = ad["fed"]
			a.food = ad["food"]
			a.key = ad["key"]
			a.park = ad["park"]
			a.sick = ad["sick"]
			a.heal = ad["heal"]
			a.sick_nights = ad["sick_nights"]
			a.starved = ad["starved"]
			a.petits = int(ad.get("petits", 0))
			p.animals.append(a)
		p.version += 1
		var ia = d["ias"][i]
		if ia != null:
			var ai: AIController = m.ais[i]
			ai.zoo_rect = ia["zoo_rect"]
			ai.target_rect = ia["target_rect"]
			ai.expanded = ia["expanded"]
			ai.agrandissements = int(ia.get("agrandissements", 0))
			ai.agrandis = int(ia.get("agrandis", 0))
			ai.agrandi_jour = int(ia.get("agrandi_jour", -1))
			ai.agrandir_refus = ia.get("agrandir_refus", [])
			ai.roster_kiosque = bool(ia.get("roster_kiosque", false))
			ai.epargne = float(ia.get("epargne", 0.0))
			ai.agence_voulue = bool(ia.get("agence_voulue", false))
			ai.cabinet_voulu = bool(ia.get("cabinet_voulu", false))
			ai.entrance = ia["entrance"]
			ai.shop_rect = ia["shop_rect"]
			ai.plans = ia["plans"]
			ai.reserved = ia["reserved"]
			ai.fence_tiles = ia["fence_tiles"]
	return m


## Après le chargement : les IA jouent leur matin, comme dans une journée normale.
static func reprendre(m: Match) -> void:
	for ai in m.ais:
		if ai:
			ai.on_day_start()
	m.bump()
