# Texte pour le générateur d'images : enceinte, enclos et camps

## Pourquoi ne pas utiliser la planche de propositions telle quelle

La planche montre de beaux styles, mais ses enclos sont des boîtes fermées en vue isométrique, posées en losange. Dans le jeu, une enceinte ou un enclos se dessine case par case, sur une grille droite, avec n'importe quelle longueur et n'importe quelle forme. Un côté de losange ne peut pas se poser sur une grille droite.

Il faut donc des **pièces détachées, dans la vue du jeu** : un tronçon vu de face, un tronçon vu dans le sens de la longueur, et un poteau. Les poteaux couvrent les raccords, donc les tronçons n'ont pas besoin de se raccorder parfaitement.

La planche reste utile comme référence de style. Recadrez le style retenu et joignez-le à la demande, avec une capture du jeu pour la vue.

## Pièces jointes à chaque demande

1. Une capture du jeu où l'on voit le mur actuel, pour la vue : [captures/04_jour_zoo_ouvert.png](prompt_redesign_interface/captures/04_jour_zoo_ouvert.png).
2. Le style choisi, recadré depuis la planche de propositions.

## Texte pour une enceinte ou un enclos

Une image par style. Enregistrez-la sous le nom indiqué entre parenthèses.

```text
Planche de pièces détachées pour un jeu vidéo de gestion de zoo vu du dessus, dans le style de la seconde image jointe : bande dessinée franco-belge, trait d'encre noir épais, aplats de couleur, légères hachures. Pour la vue et la taille relative, regarde le mur de la première image jointe.

Format paysage 1536 x 1024. Fond magenta uni #FF00FF, parfaitement plat, jusqu'aux bords de l'image. Aucun cadre, aucune bordure.

La planche montre exactement 3 pièces, alignées de gauche à droite, bien séparées par de larges bandes de magenta. Elles doivent appartenir à la même clôture : mêmes matériaux, mêmes couleurs, même épaisseur de trait.

Pièce 1, à gauche : un tronçon droit vu de face, comme un mur horizontal à l'écran. On voit sa face avant et un peu le dessus. Environ 520 pixels de large pour 300 de haut. Ses extrémités gauche et droite sont coupées net à la verticale, sans poteau.

Pièce 2, au centre : le même tronçon, mais qui s'éloigne droit vers le haut de l'image, comme un mur vertical à l'écran. On voit surtout le dessus, et un peu un seul flanc. Environ 130 pixels de large pour 520 de haut. Ses bords gauche et droit sont strictement parallèles et verticaux, sans aucun effet de perspective. Ses extrémités haute et basse sont coupées net à l'horizontale.

Pièce 3, à droite : un seul poteau ou pilier du même matériau, vu de face, posé bien droit. Environ 130 pixels de large pour 340 de haut. Il est un peu plus haut et plus large que le tronçon.

Règles à respecter strictement :
- Vue identique à celle de la première image jointe : pas d'isométrie, pas de losange, pas de diagonale, pas de point de fuite.
- Aucun sol, aucune herbe, aucun buisson, aucune pierre au pied, aucune ombre sur le fond, aucun personnage, aucun texte.
- Aucun magenta ni rose vif dans les pièces. Entre deux barreaux ou deux lisses, on voit le fond magenta.
- Dessin simple et lisible : un tronçon sera affiché à environ 40 pixels de large à l'écran.

Style de la clôture : [STYLE]
```

## Les styles

### Indispensables

1. **Enceinte** (`enceinte`) : mur de pierre claire en blocs réguliers, chaperon de pierre plus claire sur le dessus, pilier carré à chapeau de pierre. C'est le style de la première image de la deuxième rangée.
2. **Enclos** (`enclos`) : barrière de ranch en bois, deux lisses horizontales, poteau carré à tête plate. C'est le style de la première image de la première rangée.

### Facultatifs : un enclos selon le type d'animal

Le jeu pourrait choisir le style d'après l'animal installé, sans changer les règles. Les clôtures encore vides garderaient le style en bois.

3. **Prédateurs** (`enclos_predateur`) : grille de fer vert sombre, barreaux serrés, poteau de fer à boule. C'est le style de la dernière image de la deuxième rangée.
4. **Aquatiques** (`enclos_aquatique`) : muret de pierre bas surmonté d'une vitre épaisse bleutée, poteau de pierre. C'est le style de la première image de la troisième rangée. La vitre doit rester opaque et bleu très clair : le magenta ne doit pas apparaître à travers.
5. **Aériens** (`enclos_aerien`) : filet de corde tendu entre des poteaux de bois ronds, cordage épais. C'est le style de la deuxième image de la troisième rangée.
6. **Herbivores** (`enclos_herbivore`) : palissade de bambou jaune liée à la corde. C'est le style de l'avant-dernière image de la troisième rangée.

## Texte pour les camps

Une image par niveau, sur le même fond magenta. Joignez `game/assets/bd/sprites/batiments/snack.png` pour le style. Demandez d'abord le niveau 1, puis joignez-le aux deux suivants : les trois doivent être le même lieu qui grandit.

```text
Illustration d'un campement pour un jeu vidéo de gestion de zoo, dans le style de l'image jointe : bande dessinée franco-belge, trait d'encre noir épais, aplats de couleur, légères hachures.

Format paysage 1536 x 1024. Fond magenta uni #FF00FF, parfaitement plat, jusqu'aux bords de l'image. Aucun cadre, aucune bordure.

Vue de trois quarts depuis le haut, ouverture tournée vers le bas de l'image. Le campement est carré, entier et centré, et occupe environ les deux tiers de la hauteur de l'image, avec du magenta tout autour. Il repose sur un sol de terre battue et d'herbe rase, limité au carré du camp.

Règles à respecter strictement :
- Aucune ombre portée sur le fond, aucun décor en dehors du carré, aucun personnage, aucun texte.
- Aucun magenta ni rose vif sur le campement.
- Dessin simple et lisible : le camp sera affiché à environ 150 pixels de large à l'écran.

Campement : [DESCRIPTION]
```

1. **Camp niveau 1** (`camp1`) : un chantier qui démarre. Deux tentes de toile écrue rapiécée, un feu de camp entre des pierres, quelques caisses et un tas de bois, une clôture de bois sommaire et incomplète.
2. **Camp niveau 2** (`camp2`) : le même lieu, mieux installé. Trois tentes dont une grande à rayures, un feu de camp, une table de chantier avec des plans, un râtelier d'outils, une palissade de bois complète avec un portail.
3. **Camp niveau 3** (`camp3`) : le même lieu, devenu une base. Deux tentes et une petite baraque de bois à toit de tôle avec une lanterne, un feu de camp, un auvent avec des caisses bien rangées, une palissade solide avec un portail à fanion ZooLife sans texte.

## Après la génération

Pour les camps, c'est tout de suite utilisable :

```bash
python docs/handoff_bd/generateurs/batiments_planches.py "<dossier des images>" .
```

Pour les enceintes et les enclos, dites-le à Claude : il écrira le découpage des 3 pièces et le dessin case par case dans le jeu, une fois les images connues.
