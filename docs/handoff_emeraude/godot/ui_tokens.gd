# Jetons du thème Émeraude (repris de tokens.json).
# À placer en autoload ou à utiliser comme classe statique : UiTokens.OR, UiTokens.CAT_COULEUR["cadre"]...
# Point de départ non testé dans le projet : à vérifier à la première compilation.
class_name UiTokens
extends RefCounted

# Interface
const PANNEAU_HAUT := Color("#11564E")
const PANNEAU_BAS := Color("#08302C")
const PANNEAU_MILIEU := Color("#0D433D") # approximation à plat du dégradé
const ENTETE_HAUT := Color("#1C7468")
const ENTETE_BAS := Color("#10483F")
const FOND_ECRAN := Color("#0B2A26")
const OR := Color("#E2AE62")
const OR_SOMBRE := Color("#6A4418")
const OR_CLAIR := Color("#FFF0B8")
const BOUTON_HAUT := Color("#FFD89A")
const BOUTON_BAS := Color("#C88A3A")
const BOUTON_TEXTE := Color("#1E1406")
const TEXTE := Color("#F4FAEE")
const TEXTE_SECONDAIRE := Color("#A6D4C8")
const SELECTION := Color("#FFD45A")
const JOUEUR := Color("#18A88A")
const POSITIF := Color("#7CF29A")
const NEGATIF := Color("#FFB09A")

# États (double codage : couleur + forme)
const QUALITE := Color("#3A8AE8")   # cercle, signe +
const DEFAUT := Color("#E8782A")    # carré rayon 3, signe −
const INACTIF := Color("#E8B020")
const PAUSE := Color("#7A8A88")

const CAT_COULEUR := {
	"peu_qualifie": Color("#D8642A"),
	"qualifie": Color("#1E9A8A"),
	"cadre": Color("#8A4AD0"),
}
const CAT_FOND_PORTRAIT := {
	"peu_qualifie": Color("#F2B85A"),
	"qualifie": Color("#7AD8C8"),
	"cadre": Color("#C8A8F0"),
}
const RESSOURCE_COULEUR := {
	"argent": Color("#D8A010"),
	"bois": Color("#C8601A"),
	"pierre": Color("#4A6A98"),
	"or": Color("#E8B000"),
	"influence": Color("#C8307A"),
	"logement": Color("#2A9A4A"),
	"reputation": Color("#7A3AC8"),
}
const BIOME_COULEUR := {
	"savane": Color("#C88A10"),
	"foret": Color("#3A7A2A"),
	"jungle": Color("#0E8A6A"),
	"aquatique": Color("#2E7AD0"),
	"montagne": Color("#7A6AA0"),
	"desert": Color("#C8602A"),
}
const TERRAIN_TUILE := {
	"prairie": Color("#8ACC4A"),
	"foret": Color("#1E6A22"),
	"eau": Color("#1E9AC8"),
	"roche": Color("#B8B2A6"),
	"sable": Color("#F2D684"),
	"montagne": Color("#8E7E6C"),
	"or": Color("#A8A296"),
}
const TERRAIN_MONDE := {
	"prairie": Color("#62AE34"),
	"foret": Color("#1A5A20"),
	"eau": Color("#1268B8"),
	"roche": Color("#A8A296"),
	"sable": Color("#F2D684"),
	"montagne": Color("#8E7E6C"),
	"or": Color("#A8A296"),
}
const JOUEUR_COULEUR := {
	"vous": Color("#18A88A"),
	"batisseuse": Color("#E8A020"),
	"marchande": Color("#3A6AE0"),
	"prudente": Color("#E04A8A"),
}

# Formes (px à 1600 x 900)
const BORDURE_PANNEAU := 2
const RAYON_PANNEAU := 10
const MARGE_PANNEAU := 12
const HAUTEUR_BOUTON := 44
const DIAMETRE_ORDRE := 46
const ZONE_CLIQUABLE_MIN := 44

const CARTE_MAIN := Vector2(136, 216)
const CARTE_DRAFT := Vector2(146, 196)
const CARTE_MARCHE := Vector2(160, 236)
const CARTE_CONTRAT := Vector2(204, 292)
const LEVEE_SELECTION := 26.0
const DEPASSE_MAIN := 34.0
