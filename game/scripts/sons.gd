class_name Sons
extends Node
## Musique, ambiances et bruitages. Un seul nœud sous la racine de la scène : il survit au retour au menu et aux relances.
## N'a aucun effet sur la partie. Sons générés par IA (docs/prompt_musique_sons.md), rangés dans assets/audio/ ; quelques
## anciens sons synthétisés par tools/audio.py restent en secours (ne pas relancer ce script : il écraserait les nouveaux).
## Un .ogg ou un .mp3 passe avant le .wav du même nom, et les variantes nom_2, nom_3… sont tirées au hasard.

const DOSSIER := "res://assets/audio/"
const MUSIQUES := {"menu": "musique_menu", "jour": "musique_jour", "nuit": "musique_nuit", "victoire": "musique_victoire"}
## Musiques qui finissent par une vraie fin (accord final, fondu) : on enchaîne en fondu avant, vers le début de la même
## piste ou d'une variante. Secondes : début du son, puis moment où la fin commence. Mesuré à l'import (preparer_sons.py).
const BOUCLES := {
	"musique_jour": {"debut": 0.04, "fin": 171.0}, "musique_jour_2": {"debut": 0.03, "fin": 151.0},
	"musique_menu": {"debut": 0.58, "fin": 162.0}, "musique_nuit": {"debut": 0.06, "fin": 163.0},
	"musique_victoire": {"debut": 1.22, "fin": 62.0},
}
const FONDU := 3.0  # secondes de fondu enchaîné à la boucle
const VOIX := 10  # bruitages simultanés
const ECART_MIN_MS := 70  # un même bruitage ne se répète pas plus vite

static var moi: Sons
static var _musique_voulue := ""

var _lecteurs: Array[AudioStreamPlayer] = []
var _suivant := 0
var _musique_a: AudioStreamPlayer
var _musique_b: AudioStreamPlayer
var _piste := ""
var _boucle := {}  # la piste qui joue, si elle se boucle en fondu : {"lecteur", "fin", "debut"}
var _fondus := {}  # lecteur -> son tween en cours
var _ambiances := {}  # nom -> {"lecteur", "voulu"} (dB visés ; -80 : s'éteint)
var _cache := {}
var _dernier := {}
var _variantes_de := {}
var _nom_de := {}  # flux -> nom du fichier (pour les boucles)
var _hasard := RandomNumberGenerator.new()  # le sien : le hasard de la partie n'est pas touché


## À appeler une fois au démarrage. Sans carte son (--headless), rien n'est créé et les appels sont sans effet.
static func demarrer(arbre: SceneTree) -> void:
	if (moi != null and is_instance_valid(moi)) or DisplayServer.get_name() == "headless":
		return
	moi = Sons.new()
	moi.name = "Sons"
	arbre.root.add_child.call_deferred(moi)


static func _pret() -> bool:
	return moi != null and is_instance_valid(moi) and moi.is_inside_tree()


## volume : en dB (0 : tel quel). Un bruitage absent ne fait rien.
static func effet(nom: String, volume := 0.0) -> void:
	if _pret():
		moi._jouer(nom, volume)


static func existe(nom: String) -> bool:
	return _pret() and moi._choisir(nom) != null


## delai : secondes avant que la nouvelle piste commence (l'ancienne s'efface tout de suite), pour laisser passer un jingle.
static func musique(nom: String, delai := 0.0) -> void:
	_musique_voulue = nom
	if _pret():
		moi._changer_musique(nom, delai)


## Ambiance en boucle, réglée en continu : volume en dB, -80 pour l'éteindre (en fondu).
static func ambiance(nom: String, volume: float) -> void:
	if _pret():
		moi._regler_ambiance(nom, volume)


static func couper_ambiances() -> void:
	if _pret():
		for nom in moi._ambiances:
			moi._regler_ambiance(nom, -80.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hasard.randomize()
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
		_cache[nom] = null
		for ext in [".ogg", ".mp3", ".wav"]:
			if ResourceLoader.exists(DOSSIER + nom + ext):
				_cache[nom] = load(DOSSIER + nom + ext)
				_nom_de[_cache[nom]] = nom
				break
	return _cache[nom]


## Le son et ses variantes (nom_2, nom_3…), l'un d'eux au hasard.
func _choisir(nom: String) -> AudioStream:
	if not _variantes_de.has(nom):
		var l := []
		if _charger(nom) != null:
			l.append(_charger(nom))
		for i in range(2, 10):
			var v := _charger("%s_%d" % [nom, i])
			if v == null:
				break
			l.append(v)
		_variantes_de[nom] = l
	var l: Array = _variantes_de[nom]
	return null if l.is_empty() else l[_hasard.randi() % l.size()]


func _jouer(nom: String, volume := 0.0) -> void:
	var s := _choisir(nom)
	if s == null:
		return
	var maintenant := Time.get_ticks_msec()
	if maintenant - int(_dernier.get(nom, -1000)) < ECART_MIN_MS:
		return
	_dernier[nom] = maintenant
	var p := _lecteurs[_suivant]
	_suivant = (_suivant + 1) % VOIX
	p.stream = s
	p.volume_db = volume
	p.play()


func _fondu(p: AudioStreamPlayer, vers: float, duree: float, arreter := false) -> void:
	if _fondus.has(p) and _fondus[p].is_valid():
		_fondus[p].kill()
	var t := create_tween()
	t.tween_property(p, "volume_db", vers, duree)
	if arreter:
		t.tween_callback(p.stop)
	_fondus[p] = t


## Fondu enchaîné entre deux pistes.
func _changer_musique(nom: String, delai := 0.0) -> void:
	if nom == _piste:
		return
	_piste = nom
	var s := _choisir(MUSIQUES.get(nom, ""))
	_lancer_piste(s, 1.2, delai)


func _lancer_piste(s: AudioStream, fondu: float, delai := 0.0) -> void:
	var ancien := _boucle.get("lecteur", _musique_a if _musique_a.playing else _musique_b) as AudioStreamPlayer
	var nouveau := _musique_b if ancien == _musique_a else _musique_a
	if ancien.playing:
		_fondu(ancien, -60.0, fondu, true)
	_boucle = {}
	if s == null:
		return
	var reglage: Dictionary = BOUCLES.get(_nom_de.get(s, ""), {})
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_DISABLED if not reglage.is_empty() else AudioStreamWAV.LOOP_FORWARD
		s.loop_end = int(s.get_length() * s.mix_rate)
	elif s is AudioStreamOggVorbis or s is AudioStreamMP3:
		s.loop = reglage.is_empty()
	nouveau.stream = s
	nouveau.volume_db = -40.0
	if delai > 0.0:
		await get_tree().create_timer(delai).timeout
		if nouveau.stream != s:
			return
	nouveau.play(float(reglage.get("debut", 0.0)))
	_fondu(nouveau, 0.0, fondu)
	if not reglage.is_empty():
		_boucle = {"lecteur": nouveau, "fin": float(reglage["fin"])}


func _regler_ambiance(nom: String, volume: float) -> void:
	if not _ambiances.has(nom):
		if volume <= -60.0:
			return
		var s := _charger(nom)
		if s == null:
			return
		if s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = int(s.get_length() * s.mix_rate)
		elif s is AudioStreamOggVorbis or s is AudioStreamMP3:
			s.loop = true
		var p := AudioStreamPlayer.new()
		p.bus = "Effets"
		p.stream = s
		p.volume_db = -60.0
		add_child(p)
		_ambiances[nom] = {"lecteur": p, "voulu": volume}
	_ambiances[nom]["voulu"] = volume


func _process(delta: float) -> void:
	# Boucle en fondu : avant la fin écrite de la piste, on repart du début (ou d'une variante)
	if not _boucle.is_empty():
		var p: AudioStreamPlayer = _boucle["lecteur"]
		if p.playing and p.get_playback_position() >= _boucle["fin"] - FONDU * 0.5:
			_lancer_piste(_choisir(MUSIQUES.get(_piste, "")), FONDU)
	# Ambiances : le volume suit doucement la valeur voulue (6 dB par seconde)
	for nom in _ambiances:
		var a: Dictionary = _ambiances[nom]
		var p: AudioStreamPlayer = a["lecteur"]
		var voulu: float = a["voulu"]
		p.volume_db = move_toward(p.volume_db, maxf(voulu, -60.0), 6.0 * delta)
		if voulu > -60.0 and not p.playing:
			p.play(_hasard.randf() * p.stream.get_length())
		elif voulu <= -60.0 and p.playing and p.volume_db <= -59.0:
			p.stop()
