class_name BulleHubert
extends Control
## Hubert de la Marge parle pendant la partie sans bloquer le jeu : une petite bulle au-dessus de la main, une plus
## grande en haut pour l'événement du jour. Elles s'effacent seules. Les répliques (data/hubert.json) tournent :
## aucune ne revient avant que les autres du même moment soient passées.

const ATTENTE_MEME_MOMENT := 20.0  # secondes avant de redire quelque chose sur le même sujet

var data: Dictionary
var main_box: Control  # la main : la petite bulle s'arrête au-dessus
var humeur := 0  # -1 furieux, 0 neutre, 1 satisfait
var grande_en_bas := false  # fin de partie : la grande bulle laisse le haut de l'écran au classement
var _rng := RandomNumberGenerator.new()
var _sacs := {}
var _derniers := {}
var _file: Array = []
var _petite: Dictionary
var _grande: Dictionary


class Queue extends Control:
	func _draw() -> void:
		var pts := PackedVector2Array([Vector2(18, 0), Vector2(18, 16), Vector2(0, 10)])
		draw_colored_polygon(pts, Color.WHITE)
		draw_line(pts[0], pts[2], UiTokens.ENCRE, 3.0, true)
		draw_line(pts[1], pts[2], UiTokens.ENCRE, 3.0, true)


func _init(donnees: Dictionary, main_cartes: Control) -> void:
	data = donnees
	main_box = main_cartes
	_rng.randomize()
	name = "BulleHubert"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_petite = _construire(460.0, 60.0, 15)
	_grande = _construire(680.0, 84.0, 18)


func _construire(large: float, tete: float, police: int) -> Dictionary:
	var racine := Control.new()
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.visible = false
	add_child(racine)
	var disque := Panel.new()
	var ds := StyleBoxFlat.new()
	ds.bg_color = UiTokens.ENTETE
	ds.border_color = UiTokens.ENCRE
	ds.set_border_width_all(3)
	ds.set_corner_radius_all(int(tete / 2.0))
	disque.add_theme_stylebox_override("panel", ds)
	disque.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	disque.size = Vector2(tete, tete)
	disque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(disque)
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disque.add_child(image)
	var cadre := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color.WHITE
	bs.border_color = UiTokens.ENCRE
	bs.set_border_width_all(3)
	bs.set_corner_radius_all(18)
	bs.content_margin_left = 16
	bs.content_margin_right = 16
	bs.content_margin_top = 8
	bs.content_margin_bottom = 8
	bs.shadow_color = Color(0.08, 0.12, 0.17, 0.35)
	bs.shadow_size = 2
	bs.shadow_offset = Vector2(4, 5)
	cadre.add_theme_stylebox_override("panel", bs)
	cadre.custom_minimum_size.x = large
	cadre.position = Vector2(tete + 16.0, 0)
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(cadre)
	var queue := Queue.new()
	queue.position = Vector2(tete, 12)
	queue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.add_child(queue)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cadre.add_child(v)
	var texte := Label.new()
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texte.custom_minimum_size.x = large - 32.0
	texte.add_theme_font_override("font", UiTokens.police_corps(500))
	texte.add_theme_font_size_override("font_size", police)
	texte.add_theme_color_override("font_color", UiTokens.ENCRE)
	v.add_child(texte)
	var effet := Label.new()
	effet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effet.custom_minimum_size.x = large - 32.0
	effet.add_theme_font_override("font", UiTokens.police_corps(700))
	effet.add_theme_font_size_override("font_size", police - 2)
	effet.add_theme_color_override("font_color", UiTokens.SARCELLE)
	v.add_child(effet)
	return {"racine": racine, "cadre": cadre, "texte": texte, "effet": effet, "image": image, "tete": tete, "reste": 0.0}


## La tête au centre du disque : les visages ne sont pas au milieu de leur image.
func _cadrer(image: TextureRect, tex: Texture2D, tete: float) -> void:
	image.texture = tex
	var img := tex.get_image()
	var haut := img.get_height()
	var somme := 0.0
	var n := 0.0
	var sommet := -1
	for y in int(haut * 0.55):
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				somme += x
				n += 1.0
				if sommet < 0:
					sommet = y
	var echelle := tete * 1.3 / haut
	image.size = Vector2(img.get_width(), haut) * echelle
	image.position = Vector2(tete / 2.0 - somme / maxf(n, 1.0) * echelle, tete * 0.06 - maxi(sommet, 0) * echelle)


## Une réplique de ce moment, ou "" s'il n'y en a pas. Les tirages ne touchent pas au hasard de la partie.
func replique(moment: String, args := {}) -> String:
	var toutes: Array = data["repliques"].get(moment, [])
	if toutes.is_empty():
		return ""
	var sac: Array = _sacs.get(moment, [])
	if sac.is_empty():
		sac = toutes.duplicate()
		for i in range(sac.size() - 1, 0, -1):
			var j := _rng.randi_range(0, i)
			var t = sac[i]
			sac[i] = sac[j]
			sac[j] = t
	var ligne: String = sac.pop_back()
	_sacs[moment] = sac
	for k in args:
		ligne = ligne.replace("{%s}" % k, str(args[k]))
	return ligne


## Traite une annonce de GameState : renvoie false si ce moment n'a pas de réplique (le message simple reste alors).
func annoncer(moment: String, args := {}) -> bool:
	if not data["repliques"].has(moment):
		return false
	var maintenant := Time.get_ticks_msec() / 1000.0
	var grande := moment.begins_with("ev_") or moment in ["victoire", "defaite"]
	if not grande and maintenant - float(_derniers.get(moment, -999.0)) < ATTENTE_MEME_MOMENT:
		return true
	_derniers[moment] = maintenant
	var ligne := replique(moment, args)
	if grande:
		_montrer(_grande, ligne, str(args.get("effet", "")), 30.0 if moment in ["victoire", "defaite"] else 9.0, moment)
	else:
		_file.append([ligne, str(args.get("effet", "")), moment])
		if _file.size() > 3:
			_file.pop_front()
	return true


## Expression du moment, sinon selon l'humeur.
func expression(moment: String) -> Texture2D:
	var nom: String = data["expressions"].get(moment, "content" if humeur > 0 else ("furieux" if humeur < 0 else "neutre"))
	return load("res://assets/bd/hubert/%s.png" % nom)


func _montrer(b: Dictionary, ligne: String, effet: String, duree: float, moment: String) -> void:
	b["texte"].text = ligne
	b["effet"].text = effet
	b["effet"].visible = effet != ""
	_cadrer(b["image"], expression(moment), b["tete"])
	b["racine"].visible = true
	b["reste"] = duree
	var trait_: StyleBoxFlat = b["cadre"].get_theme_stylebox("panel")
	trait_.border_color = UiTokens.ORANGE if humeur < 0 else UiTokens.ENCRE


func _process(delta: float) -> void:
	if not _petite["racine"].visible and not _file.is_empty():
		var s: Array = _file.pop_front()
		_montrer(_petite, s[0], s[1], clampf(2.5 + s[0].length() * 0.05, 4.0, 8.0), s[2])
	var vue := get_viewport_rect().size
	for b in [_petite, _grande]:
		if not b["racine"].visible:
			continue
		b["reste"] -= delta
		if b["reste"] <= 0.0:
			b["racine"].visible = false
			continue
		var cadre: Control = b["cadre"]
		cadre.size = Vector2.ZERO
		var haut: float = cadre.size.y
		var y: float
		var x: float
		if b == _grande:
			x = (vue.x - cadre.size.x - b["tete"] - 16.0) / 2.0
			y = vue.y - maxf(haut, b["tete"]) - 135.0 if grande_en_bas else 78.0
		else:
			x = 284.0
			y = (main_box.get_global_rect().position.y if main_box.is_visible_in_tree() else vue.y) - maxf(haut, b["tete"]) - 12.0
		b["racine"].position = Vector2(x, y)
