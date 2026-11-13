class_name Conseils
extends Control
## Conseils d'Hubert à la première occasion (13/11/2026) : ce que le tutoriel ne montre pas (nuit au conseil, équipe,
## événements, caisse vide, parc plein, modes de jeu). Chaque conseil n'apparaît qu'une fois par joueur : les conseils vus
## sont notés dans user://reglages.cfg, section « conseils » ; « Ne plus afficher de conseils » les coupe tous.
## Le panneau reste à l'écran jusqu'au clic sur « Compris » et ne met pas la partie en pause.
## main.gd appelle proposer(id) quand la situation se présente (_conseils_du_moment). Capture : --conseil=id.

const SECTION := "conseils"

## id → [titre, texte]. Le texte peut contenir du BBCode ([b]).
const TEXTES := {
	"nature": ["Réserve naturelle", "Ici, [b]personne ne modifie le terrain[/b] : un animal ne s'installe que là où son motif existe déjà. Avant de fermer votre enceinte, repérez ces endroits : la nuit, « Voir mon zoo » montre où le motif de chaque contrat du marché se trouve près du camp. Une enceinte posée au hasard peut n'en contenir aucun."],
	"defi": ["Défi", "Partie de [b]10 jours[/b], seul contre trois IA qui jouent toujours de la même façon. Le marché sort les mêmes collaborateurs, cartes et espèces pour tout le monde, dans le même ordre. Votre score : la réputation au soir du jour 10. Il part au classement en ligne si vous avez un pseudo."],
	"cozy": ["Gestion libre", "Ni rival, ni objectif, ni fin de partie, et pas de maladie. Les animaux bien nourris dans un parc propre font des petits, et les visiteurs laissent un mot chaque soir dans le livre d'or (fiche du zoo)."],
	"nuit": ["Le conseil du soir", "Chaque soir, l'ordre du jour, à gauche, enchaîne les achats : [b]contrats d'animaux, collaborateurs, cartes d'action[/b]. Chacun achète à son tour, [b]dans l'ordre d'influence[/b] : le premier choisit avant les autres. Les contrats prennent [b]4 % par jour[/b], et le marché ne se renouvelle que lorsqu'un contrat est acheté."],
	"bonus": ["Le bonus de nuit", "Le premier en influence choisit un bonus pour le lendemain, appliqué [b]à tous les zoos[/b]. Choisissez celui qui vous sert le plus que vos rivaux. Pour présider, envoyez des collaborateurs en lobbying à la Mairie."],
	"equipe": ["L'équipe", "Dernière étape du soir : [b]améliorer[/b] une carte (une amélioration au choix parmi plusieurs) ou [b]licencier[/b] un poids mort. Un paquet sans mauvaises cartes pioche plus souvent les bonnes. Chaque collaborateur gagne aussi de l'expérience en travaillant : à chaque niveau, vous choisissez une amélioration ; au niveau 6, il devient légendaire et rapporte de la réputation."],
	"evenement": ["Un événement", "Chaque matin, un événement peut toucher [b]tous les zoos[/b] : grève, tempête, pluie, subvention… Il est écrit dans le bandeau en haut de l'écran pour la journée. Adaptez votre plan : vendre du bois quand il manque en ville, ne pas lancer de grand chantier avant une tempête."],
	"caisse_vide": ["Caisse vide", "Pas de quoi payer tout le monde ce matin ? Le bouton [b]+4[/b] d'une carte cède sa journée : elle ne travaille pas, part à la défausse, et rapporte 4 d'argent pour payer les autres. Vous pouvez aussi vendre du bois ou de la pierre à la Bourse."],
	"parc_plein": ["Parc plein", "Votre parc accueille au plus [b]un visiteur pour trois cases[/b] de l'enceinte. Les autres attendent à l'entrée, puis repartent. Pour en recevoir plus, agrandissez l'enceinte."],
	"carte_action": ["Carte d'action", "Une carte d'action se joue depuis la main, en journée, puis disparaît : elle ne revient pas dans le paquet. Survolez-la pour lire son effet."],
	"cadre": ["Un cadre", "Certains collaborateurs qualifiés ont un bouton [b]Jouer[/b] sur leur portrait : au lieu de travailler sur le terrain, ils rendent un service une fois dans la journée. Survolez la carte pour lire lequel."],
}

static var _vus := {}
static var _charges := false

var _file: Array[String] = []
var _panneau: PanelContainer
var _titre: Label
var _texte: RichTextLabel
var _courant := ""


static func _charger() -> void:
	if _charges:
		return
	_charges = true
	var cfg := ConfigFile.new()
	cfg.load(Reglages.FICHIER)
	if cfg.has_section(SECTION):
		for k in cfg.get_section_keys(SECTION):
			_vus[k] = cfg.get_value(SECTION, k, false)


static func deja_vu(id: String) -> bool:
	_charger()
	return bool(_vus.get(id, false)) or bool(_vus.get("tous", false))


static func noter(id: String) -> void:
	_charger()
	_vus[id] = true
	var cfg := ConfigFile.new()
	cfg.load(Reglages.FICHIER)
	cfg.set_value(SECTION, id, true)
	cfg.save(Reglages.FICHIER)


## Tous les conseils réapparaîtront (Réglages).
static func reinitialiser() -> void:
	_charger()
	_vus.clear()
	var cfg := ConfigFile.new()
	cfg.load(Reglages.FICHIER)
	if cfg.has_section(SECTION):
		cfg.erase_section(SECTION)
	cfg.save(Reglages.FICHIER)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panneau = PanelContainer.new()
	var sb := UiTokens.panneau(UiTokens.MEMO, 10, 2, 0, true)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_panneau.add_theme_stylebox_override("panel", sb)
	_panneau.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panneau.offset_left = -300
	_panneau.offset_right = 300
	_panneau.offset_top = 46
	_panneau.grow_vertical = Control.GROW_DIRECTION_END
	_panneau.visible = false
	add_child(_panneau)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	_panneau.add_child(h)
	var tete := Composants.image_logo(load("res://assets/bd/hubert/neutre.png"), Vector2(64, 64))
	tete.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(tete)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var l1 := HBoxContainer.new()
	v.add_child(l1)
	var sur := Composants.texte("CONSEIL D'HUBERT · ", 12, 600, UiTokens.TEXTE_2, "mono")
	l1.add_child(sur)
	_titre = Composants.texte("", 17, 800, UiTokens.ENCRE, "titre")
	l1.add_child(_titre)
	_texte = RichTextLabel.new()
	_texte.bbcode_enabled = true
	_texte.fit_content = true
	_texte.scroll_active = false
	_texte.custom_minimum_size.x = 480
	_texte.add_theme_font_override("normal_font", UiTokens.police_corps(600))
	_texte.add_theme_font_override("bold_font", UiTokens.police_corps(800))
	_texte.add_theme_font_size_override("normal_font_size", 14)
	_texte.add_theme_font_size_override("bold_font_size", 14)
	_texte.add_theme_color_override("default_color", UiTokens.ENCRE)
	_texte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_texte)
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 10)
	v.add_child(bas)
	var aucun := LinkButton.new()
	aucun.text = "Ne plus afficher de conseils"
	aucun.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	aucun.add_theme_font_override("font", UiTokens.police_corps(600))
	aucun.add_theme_font_size_override("font_size", 12)
	aucun.add_theme_color_override("font_color", UiTokens.TEXTE_2)
	aucun.focus_mode = Control.FOCUS_NONE
	aucun.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	aucun.pressed.connect(func():
		noter("tous")
		_file.clear()
		_fermer())
	bas.add_child(aucun)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bas.add_child(esp)
	var ok := Composants.bouton("COMPRIS", "BoutonPrincipal")
	ok.add_theme_font_override("font", UiTokens.police_titre())
	ok.add_theme_font_size_override("font_size", 15)
	ok.custom_minimum_size = Vector2(110, 32)
	ok.pressed.connect(_fermer)
	bas.add_child(ok)


## La situation se présente : le conseil s'affiche s'il n'a jamais été vu (après celui en cours, le cas échéant).
func proposer(id: String) -> void:
	if not TEXTES.has(id) or deja_vu(id) or id == _courant or id in _file:
		return
	_file.append(id)
	if _courant == "":
		_suivant()


## Captures (--conseil=id) : montre le conseil même s'il a déjà été vu, sans le noter.
func afficher(id: String) -> void:
	if TEXTES.has(id):
		_file.push_front(id)
		_suivant()


func _suivant() -> void:
	if _file.is_empty():
		_courant = ""
		_panneau.visible = false
		return
	_courant = _file.pop_front()
	_titre.text = str(TEXTES[_courant][0]).to_upper()
	_texte.text = str(TEXTES[_courant][1])
	_panneau.visible = true
	_panneau.reset_size()


func _fermer() -> void:
	if _courant != "":
		noter(_courant)
	_suivant()


func visible_maintenant() -> bool:
	return _panneau.visible
