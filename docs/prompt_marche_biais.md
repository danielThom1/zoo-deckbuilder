# Texte pour le générateur d'images : marche de biais, essai sur deux personnages

But : dans la vue isométrique, les collaborateurs marchent en diagonale, alors qu'ils n'ont aujourd'hui qu'une marche de profil. Il faut deux marches en plus : **vers nous** (de trois quarts face) et **en s'éloignant** (de trois quarts dos). Le jeu les retourne en miroir pour obtenir les quatre diagonales.

Essai sur **Victor** et **Clara**, une image chacun, avant de décider pour les 40.

## Pièce jointe

La feuille actuelle du personnage, pour qu'il reste exactement le même : `game/assets/bd/sprites/personnages_v2/victor.png` ou `game/assets/bd/sprites/personnages_v2/clara.png`.

## Texte

```text
Planche de sprites pour un jeu vidéo, dans le style de l'image jointe : bande dessinée franco-belge, trait d'encre noir épais, aplats de couleur, légères hachures. C'est exactement le même personnage que sur l'image jointe : même visage, mêmes vêtements, mêmes couleurs, même taille et même trait. Seul l'angle de vue change.

Format paysage 1536 x 1024. Fond vert uni #00FF40, parfaitement plat, jusqu'aux bords de l'image. Aucun cadre, aucune bordure, aucune bande de séparation. Pas de portrait.

Le personnage en pied, en 2 rangées de 3 images, à la même échelle partout et à la même taille que sur l'image jointe :
1. Rangée du haut, il marche vers nous en diagonale : vu de trois quarts face, il avance vers le bas à droite de l'image. Jambes écartées, jambes croisées, jambes écartées inversées. On voit son visage et le devant de ses vêtements.
2. Rangée du bas, il s'éloigne en diagonale : vu de trois quarts dos, il avance vers le haut à droite de l'image. Jambes écartées, jambes croisées, jambes écartées inversées. On voit son dos et l'arrière de sa tête, à peine le profil du visage.

Règles de mise en page, à respecter strictement :
- Même personnage, mêmes vêtements et mêmes couleurs dans les 6 images.
- Les deux rangées ont la même hauteur, et le personnage y garde la même taille.
- Dans chaque image, la tête reste à la même place : seules les jambes et les bras changent d'une image à l'autre.
- Sous chaque image, un trait de sol noir fin et droit, à la même hauteur pour les 3 images de la rangée, et un seul trait par image.
- Les 3 images d'une rangée sont espacées régulièrement et ne se touchent pas.
- Un espace vert d'au moins 30 pixels entre le trait de sol de la rangée du haut et le haut de la rangée du bas.
- Le personnage reste entier, rien n'est coupé par les bords de l'image.
- Aucun texte, aucun chiffre, aucun logo, aucune ombre au sol, aucun décor.
- Aucune couleur vert vif sur le personnage.

Personnage : [DESCRIPTION]
```

## Les deux personnages

Enregistrez chaque planche sous ce nom :

1. **Victor** (`Victor_biais.png`) : un homme de 45 ans, costume sombre, cravate rouge, cheveux gominés.
2. **Clara** (`Clara_biais.png`) : une femme d'une trentaine d'années, chapeau de paille, chemise à fleurs et salopette de jardinier, bottes.

Pour Clara, si la description ne correspond pas exactement à sa feuille, c'est la feuille jointe qui compte.

## Après la génération

Envoyez les deux images à Claude : il écrira le découpage de ce nouveau format et le branchement dans le jeu, puis vous montrera le résultat en mouvement.
