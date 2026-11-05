# Texte pour le générateur d'images : Intendance et décorations du parc

Une image par élément. Joignez une image de référence pour le style, par exemple `game/assets/bd/sprites/batiments/snack.png`. Enregistrez chaque image sous le nom indiqué entre parenthèses, dans un même dossier, puis dites-le à Claude : `batiments_planches.py` les découpe et les ajoute au jeu. Tant qu'une image manque, le jeu dessine un petit repli simple à la place.

Le fond est magenta et non vert : ces éléments contiennent de la verdure, que le découpage d'un fond vert effacerait.

## Texte commun

```text
Illustration d'un élément de décor pour un jeu vidéo de gestion de zoo, dans le style de l'image jointe : bande dessinée franco-belge, trait d'encre noir épais, aplats de couleur, légères hachures. Reprends le style et la lumière de cette image.

Format paysage 1536 x 1024. Fond magenta uni #FF00FF, parfaitement plat, jusqu'aux bords de l'image. Aucun cadre, aucune bordure.

Vue de trois quarts depuis le haut, comme le reste du jeu. Un seul élément, centré, entier, qui occupe environ la moitié de la hauteur de l'image, avec du magenta tout autour.

Règles à respecter strictement :
- Aucune ombre portée sur le fond, aucun sol ni socle en dehors de ce qui est décrit, aucun personnage.
- Aucun magenta ni rose vif sur l'élément : pour les fleurs, utiliser le jaune, l'orange, le rouge, le violet et le blanc.
- Pas de texte, sauf l'enseigne indiquée, écrite en lettres capitales, sans faute, et bien lisible.
- Dessin simple et lisible : il sera affiché tout petit, à environ 40 pixels de large à l'écran.

Élément : [DESCRIPTION]
```

## Bâtiment

Ce bâtiment occupe 2 × 2 cases sur la carte. Pour lui, demandez qu'il occupe les deux tiers de la largeur de l'image.

1. **Intendance du parc** (`intendance`) : petite maison de jardinier en bois vert sombre, serre vitrée accolée sur le côté, brouette, arrosoir, râteaux et pots de fleurs devant la porte, plantes grimpantes sur le mur. Enseigne « INTENDANCE ».

## Décorations

Chacune occupe une seule case sur la carte.

2. **Massif de fleurs** (`deco_massif`) : massif rond bordé de petites pierres, fleurs jaunes, orange et blanches, un peu de feuillage.
3. **Banc** (`deco_banc`) : banc public en bois à pieds de fonte, vu de face, sans personne.
4. **Lampadaire** (`deco_lampadaire`) : lampadaire de jardin en fonte vert sombre à un globe, élancé et fin.
5. **Topiaire** (`deco_topiaire`) : petit arbuste taillé en boule sur un tronc fin, dans un pot de terre cuite.
6. **Fontaine** (`deco_fontaine`) : petite fontaine ronde en pierre, un jet d'eau au centre, eau bleu clair dans le bassin.
7. **Statue** (`deco_statue`) : statue de pierre grise d'un lion assis sur un socle carré, un peu solennelle.
8. **Tonnelle** (`deco_tonnelle`) : petite arche de jardin en bois couverte de roses rouges et de feuilles.
9. **Parterre** (`deco_parterre`) : parterre carré bordé de buis taillé, fleurs violettes et blanches en lignes.

## Après la génération

```bash
python docs/handoff_bd/generateurs/batiments_planches.py "<dossier des images>" .
```

```bash
godot --headless --path game --import
```

Contrôle : `godot --path game -- --seed=404283 --autodraft --autoplay --sim=240 --autozoo --deco=20 --zoom=3 --shot=deco.png`.
