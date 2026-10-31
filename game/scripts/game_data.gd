class_name GameData
extends RefCounted
## Charge les fichiers d'équilibrage JSON de res://data/.


static func load_all() -> Dictionary:
	var out := {}
	for n in ["animals", "workers", "buildings", "events", "personnages"]:
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % n))
		assert(parsed != null, "JSON invalide : %s.json" % n)
		out[n] = parsed
	return out
