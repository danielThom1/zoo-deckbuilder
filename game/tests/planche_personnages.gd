extends SceneTree
## Planche de contrôle des personnages : portraits des cartes (fond couleur de catégorie) et, dessous,
## leur silhouette dans le monde. Rendu réel (pas --headless) :
##   godot --path game --script res://tests/planche_personnages.gd -- --shot=C:/chemin/planche.png
## --figures : silhouettes seules, en grand (12 premiers personnages).

const COLONNES := 8
const CASE := Vector2(150, 176)


func _init() -> void:
	var data := GameData.load_all()
	var shot := ""
	var figures := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot = a.substr(7)
		figures = figures or a == "--figures"
	var fond := ColorRect.new()
	fond.color = Color("0E3B33")
	fond.size = Vector2(COLONNES * CASE.x + 20, ceili(data["personnages"]["personnages"].size() / float(COLONNES)) * CASE.y + 20)
	root.add_child(fond)
	root.size = Vector2i(fond.size)
	var cats := ["peu_qualifie", "qualifie", "cadre"]
	var i := 0
	if figures:
		for p in data["personnages"]["personnages"].slice(0, 12):
			var fig := Personnage.new()
			fig.perso = p
			fig.position = Vector2(270 + (i % 3) * 520, 120 + (i / 3) * 200)
			fig.scale = Vector2(6, 6)
			fond.add_child(fig)
			i += 1
		await _capture(shot)
		return
	for p in data["personnages"]["personnages"]:
		var pos := Vector2(10 + (i % COLONNES) * CASE.x, 10 + (i / COLONNES) * CASE.y)
		var bg := ColorRect.new()
		bg.color = UiTokens.CATEGORIES[cats[i % 3]]["portrait"]
		bg.position = pos
		bg.size = Vector2(140, 98)
		fond.add_child(bg)
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = load("res://ui/portraits/%s.svg" % p["id"])
		tr.position = pos
		tr.size = Vector2(140, 98)
		fond.add_child(tr)
		var l := Label.new()
		l.text = p["nom"]
		l.position = pos + Vector2(0, 100)
		fond.add_child(l)
		var fig := Personnage.new()
		fig.perso = p
		fig.position = pos + Vector2(70, 148)
		fig.scale = Vector2(2.2, 2.2)
		fond.add_child(fig)
		i += 1
	await _capture(shot)


func _capture(shot: String) -> void:
	if shot != "":
		for k in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(shot)
		quit()


## Silhouette dans le monde : la même fonction que main.gd (dessinée face, profil, dos).
class Personnage extends Node2D:
	var perso: Dictionary

	func _draw() -> void:
		for k in 3:
			PersoDessin.dessiner(self, Vector2(-24 + k * 24, 0), perso, ["face", "profil", "dos"][k], 0.0, false)
