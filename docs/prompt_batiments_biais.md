# Texte pour le générateur d'images : bâtiments de biais

But : juger la vue isométrique avec 3 bâtiments dessinés pour elle. Pour chacun, il faut **2 images**, une façade vers la gauche et une façade vers la droite, car la vue peut tourner. Dans l'axe de la route, le jeu garde l'image de face actuelle.

Joignez à chaque demande :
1. Le bâtiment actuel, de face, pour garder ses matériaux, ses couleurs et son enseigne : `game/assets/bd/sprites/batiments/<nom>.png`.
2. Une fois la première image réussie, joignez-la aussi pour la seconde : c'est le même bâtiment.

Enregistrez chaque image sous le nom indiqué entre parenthèses, dans un même dossier.

## Texte commun

```text
Illustration d'un bâtiment pour un jeu vidéo de gestion de zoo en vue isométrique, dans le style de l'image jointe : bande dessinée franco-belge, trait d'encre noir épais, aplats de couleur, légères hachures. C'est exactement le même bâtiment que sur l'image jointe : mêmes matériaux, mêmes couleurs, même enseigne, mêmes détails, seul l'angle de vue change.

Format paysage 1536 x 1024. Fond magenta uni #FF00FF, parfaitement plat, jusqu'aux bords de l'image. Aucun cadre, aucune bordure.

Vue isométrique stricte : le bâtiment est vu depuis un coin et depuis le haut, comme dans un jeu de gestion classique. Son emprise au sol est un losange parfait, symétrique, plus large que haut (rapport 2 pour 1), et son angle le plus proche est tout en bas, au milieu de l'image. Toutes les lignes verticales restent verticales, sans aucun point de fuite. Le bâtiment est entier, centré, et occupe environ les deux tiers de la largeur de l'image, avec du magenta tout autour.

Règles à respecter strictement :
- Socle en forme de losange : herbe ou dalles, uniquement sous le bâtiment et ses accessoires, sans rien qui dépasse du losange.
- Aucune ombre portée sur le fond, aucun décor autour, aucun personnage.
- Aucun magenta ni rose vif sur le bâtiment.
- L'enseigne reste écrite à l'endroit, en lettres capitales, sans faute, et bien lisible.

Orientation : [ORIENTATION]
Bâtiment : [DESCRIPTION]
```

## Les deux orientations

- **Façade à gauche** (nom sans suffixe) : `La porte et l'enseigne sont sur la face qui regarde vers le bas à gauche de l'image. Le pignon, sans porte, regarde vers le bas à droite.`
- **Façade à droite** (nom finissant par `_d`) : `La porte et l'enseigne sont sur la face qui regarde vers le bas à droite de l'image. Le pignon, sans porte, regarde vers le bas à gauche.`

## Les 3 bâtiments

1. **Snack** (`iso_snack`, `iso_snack_d`) : image jointe `snack.png`. Kiosque à auvent rayé rouge et blanc, comptoir de vente sur la façade, grande enseigne « SNACK » sur le toit.
2. **Intendance du parc** (`iso_intendance`, `iso_intendance_d`) : image jointe `intendance.png`. Maison de jardinier en bois vert sombre, serre vitrée accolée, brouette et pots de fleurs devant la porte, enseigne « INTENDANCE ».
3. **Cuisine des animaux** (`iso_cuisine`, `iso_cuisine_d`) : image jointe `cuisine.png`. Bâtiment de ferme, cheminée qui fume, sacs de grain et cagettes devant la porte, enseigne « CUISINE ».

## Après la génération

Dites-le à Claude, ou lancez :

```bash
python docs/handoff_bd/generateurs/batiments_planches.py "<dossier des images>" .
```

```bash
godot --headless --path game --import
```

Puis, en jeu, F2, et tournez la vue avec la molette enfoncée : les nouvelles images s'affichent dès que la vue est en diagonale.
