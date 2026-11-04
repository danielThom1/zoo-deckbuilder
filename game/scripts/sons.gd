class_name Sons
extends Node
## Musique et bruitages. Un seul nœud sous la racine de la scène : il survit au retour au menu et aux relances.
## N'a aucun effet sur la partie. Sons générés par tools/audio.py (assets/audio/).

const DOSSIER := "res://assets/audio/"
const MUSIQUES := {"menu": "musique_menu", "jour": "musique_jour", "nuit": "musique_nuit"}
const VOIX := 8  # bruitages simultanés
const ECART_MIN_MS := 70  # un même bruitage ne se répète pas plus vite

static var moi: Sons
static var _musique_voulue := ""

var _lecteurs: Array[AudioStreamPlayer] = []
var _suivant := 0
var _musique_a: AudioStreamPlayer
var _musique_b: AudioStreamPlayer
var _piste := ""
var _cache := {}
var _dernier := {}


## À appeler une fois au démarrage. Sans carte son (--headless), rien n'est créé et les appels sont sans effet.
static func demarrer(arbre: SceneTree) -> void:
	if (moi != null and is_instance_valid(moi)) or DisplayServer.get_name() == "headless":
		return
	moi = Sons.new()
	moi.name = "Sons"
	arbre.root.add_child.call_deferred(moi)


static func effet(nom: String) -> void:
	if moi != null and is_instance_valid(moi) and moi.is_inside_tree():
		moi._jouer(nom)


static func musique(nom: String) -> void:
	_musique_voulue = nom
	if moi != null and is_instance_valid(moi) and moi.is_inside_tree():
		moi._changer_musique(nom)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Musique", "Effets"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in VOIX:
		var p := AudioStreamPlayer.new()
		p.bus = "Effets"
		add_child(p)
		_lecteurs.append(p)
	_musique_a = AudioStreamPlayer.new()
	_musique_b = AudioStreamPlayer.new()
	for p in [_musique_a, _musique_b]:
		p.bus = "Musique"
		add_child(p)
	Reglages.appliquer_volumes()
	# Chaque bouton du jeu fait son clic, sans rien changer aux écrans.
	get_tree().node_added.connect(_noeud_ajoute)
	_parcourir(get_tree().root)
	if _musique_voulue != "":
		_changer_musique(_musique_voulue)


func _parcourir(n: Node) -> void:
	_noeud_ajoute(n)
	for c in n.get_children():
		_parcourir(c)


func _noeud_ajoute(n: Node) -> void:
	if n is BaseButton and not n.pressed.is_connected(_clic):
		n.pressed.connect(_clic)


func _clic() -> void:
	_jouer("clic")


func _charger(nom: String) -> AudioStream:
	if not _cache.has(nom):
		var chemin := DOSSIER + nom + ".wav"
		_cache[nom] = load(chemin) if ResourceLoader.exists(chemin) else null
	return _cache[nom]


func _jouer(nom: String) -> void:
	var s := _charger(nom)
	if s == null:
		return
	var maintenant := Time.get_ticks_msec()
	if maintenant - int(_dernier.get(nom, -1000)) < ECART_MIN_MS:
		return
	_dernier[nom] = maintenant
	var p := _lecteurs[_suivant]
	_suivant = (_suivant + 1) % VOIX
	p.stream = s
	p.play()


## Fondu enchaîné entre deux pistes.
func _changer_musique(nom: String) -> void:
	if nom == _piste:
		return
	_piste = nom
	var ancien := _musique_a if _musique_a.playing else _musique_b
	var nouveau := _musique_b if ancien == _musique_a else _musique_a
	if ancien.playing:
		var t := create_tween()
		t.tween_property(ancien, "volume_db", -60.0, 1.2)
		t.tween_callback(ancien.stop)
	var s := _charger(MUSIQUES.get(nom, ""))
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.get_length() * s.mix_rate)
	if s != null:
		nouveau.stream = s
		nouveau.volume_db = -40.0
		nouveau.play()
		create_tween().tween_property(nouveau, "volume_db", 0.0, 1.2)
