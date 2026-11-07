# Textes pour le générateur d'images : bâtiments vus de côté et de dos

En vue isométrique (F2), les bâtiments sont maintenant **fixes** : chacun a sa façade tournée vers le sud (vers le bas de la carte en 2D), et le jeu montre l'image qui correspond à l'endroit d'où on le regarde. Il en existe déjà trois par bâtiment : face, biais à gauche (`iso_<id>`), biais à droite (`iso_<id>_d`). Tant que les vues de côté et de dos manquent, la caméra ne tourne que d'environ 67° de chaque côté.

| Caméra | Image | Existe ? |
|---|---|---|
| Devant | face (`<image>.png`) | oui |
| Devant, de biais | `iso_<id>` et `iso_<id>_d` | oui |
| Côté | `cote_<id>` (l'autre côté : en miroir) | **à faire** |
| Derrière, de biais | `iso_<id>_dos` (l'autre biais : en miroir) | **à faire** |
| Derrière | `dos_<id>` | **à faire** |

Dès que les **côtés** existent, la caméra pourra tourner jusqu'à 112° de chaque côté ; avec les **dos**, elle fera le tour complet. Il faut ces images pour tous les bâtiments, sinon ceux qui n'en ont pas montreront leur image de biais la plus proche.

Le camp et l'entrée n'ont pas besoin de ces vues : le camp est maintenant posé à plat sur le terrain, et l'entrée est un portique qui se voit pareil des deux côtés.

## Ce qu'il faut joindre

À chaque demande, joignez **l'image de face et l'image de biais** du bâtiment (dans `game/assets/bd/sprites/batiments/`, noms dans la liste plus bas). Le générateur doit « deviner » l'arrière et le côté : plus il voit le bâtiment sous deux angles, plus il reste fidèle. Une fois une vue réussie, joignez-la aussi pour les suivantes du même bâtiment.

Enregistrez chaque image sous le nom indiqué entre parenthèses, dans un même dossier.

## Texte commun

```text
Illustration d'un bâtiment pour un jeu vidéo de gestion de zoo, dans le style des images jointes : bande dessinée franco-belge, trait d'encre noir épais, aplats de couleur, légères hachures. C'est exactement le même bâtiment que sur les images jointes, qui le montrent de face et de biais : mêmes matériaux, mêmes couleurs, même toit, mêmes proportions, même nombre d'étages. Seul l'angle de vue change : on a fait le tour du bâtiment.

Format paysage 1536 x 1024. Fond magenta uni #FF00FF, parfaitement plat, jusqu'aux bords de l'image. Aucun cadre, aucune bordure.

Le bâtiment est entier, centré, et occupe environ les deux tiers de la largeur de l'image, avec du magenta tout autour.

Règles à respecter strictement :
- Socle d'herbe ou de dalles uniquement sous le bâtiment et ses accessoires, de la même forme que sur les images jointes.
- Aucune ombre portée sur le fond, aucun décor autour, aucun personnage.
- Aucun magenta ni rose vif sur le bâtiment.
- Pas d'enseigne ni de texte à l'arrière, sauf indication contraire.

Vue : [VUE]
Bâtiment : [DESCRIPTION]
Ce qu'on voit à l'arrière : [ARRIÈRE]
```

## Les trois vues

Remplacez `[VUE]` par l'une de ces phrases.

- **Côté** (`cote_<id>`) : `Même angle que l'image de face jointe (vue depuis le haut, de trois quarts), mais on a tourné d'un quart de tour vers la droite : on voit en face le côté du bâtiment qui était à droite sur l'image de face, celui qu'on voit aussi en bas à droite sur l'image de biais. La façade avec la porte et l'enseigne est sur le bord gauche, presque de profil, l'arrière sur le bord droit.`
- **Dos de biais** (`iso_<id>_dos`) : `Même vue isométrique stricte que l'image de biais jointe : emprise au sol en losange parfait, plus large que haut (rapport 2 pour 1), angle le plus proche tout en bas au milieu, verticales bien verticales, sans point de fuite. Mais on est passé derrière le bâtiment : la face arrière, sans porte d'entrée ni enseigne, regarde vers le bas à droite de l'image, et le côté qui était en bas à droite sur l'image de biais jointe regarde maintenant vers le bas à gauche.`
- **Dos** (`dos_<id>`) : `Même angle que l'image de face jointe (vue depuis le haut, de trois quarts), mais depuis l'arrière du bâtiment : on voit la face arrière en entier, tournée vers le bas de l'image, avec le côté droit un peu visible. La façade avec la porte et l'enseigne est cachée derrière.`

Conseil : commencez par le **dos de biais**, le plus proche des images jointes, puis joignez-le pour faire le dos et le côté.

## Les 13 bâtiments

Pour chacun : images à joindre, description, et ce qu'on voit à l'arrière (à inventer, mais cohérent avec l'avant).

1. **Maison du personnel** (`cote_maison`, `iso_maison_dos`, `dos_maison`) : joindre `maison.png` et `iso_maison.png`. Petite maison de village, murs crème et colombages, toit de tuiles rouges, cheminée. Arrière : mur sans porte avec une petite fenêtre, tas de bûches contre le mur, corde à linge avec deux chemises.
2. **Entrepôt** (`cote_entrepot`, `iso_entrepot_dos`, `dos_entrepot`) : joindre `entrepot.png` et `iso_entrepot.png`. Grange en planches, toit de tuiles orange. Arrière : mur de planches aveugle avec une lucarne, fagots de bois empilés sous un petit auvent.
3. **Mine d'or** (`cote_mine`, `iso_mine_dos`, `dos_mine`) : joindre `mine.png` et `iso_mine.png`. Monticule de rochers avec une entrée de galerie étayée de poutres. Arrière : le dos du monticule, sans ouverture, quelques rochers et touffes d'herbe, une lanterne accrochée à un poteau, un filon doré qui affleure.
4. **Boutique de souvenirs** (`cote_boutique`, `iso_boutique_dos`, `dos_boutique`) : joindre `souvenirs.png` et `iso_boutique.png`. Échoppe à auvent rayé rouge et blanc, ourson sculpté sur le toit. Arrière : porte de service, cartons de peluches empilés, une poubelle ; l'ourson du toit vu de dos.
5. **Marché** (`cote_comptoir`, `iso_comptoir_dos`, `dos_comptoir`) : joindre `marche.png` et `iso_comptoir.png`. Étal de bois à auvent rayé rouge et blanc. Arrière : l'envers du comptoir avec des caisses et des sacs empilés, un tabouret, la toile de l'auvent vue de dos.
6. **Agence d'intérim** (`cote_agence`, `iso_agence_dos`, `dos_agence`) : joindre `agence.png` et `iso_agence.png`. Préfabriqué gris et bleu, climatiseur sur le toit. Arrière : mur de tôle avec une petite fenêtre, le groupe de climatisation, une poubelle et un carton d'offres d'emploi jetées.
7. **Cabinet de recrutement** (`cote_cabinet`, `iso_cabinet_dos`, `dos_cabinet`) : joindre `cabinet.png` et `iso_cabinet.png`. Petit immeuble de bureaux beige à deux étages, grandes baies vitrées. Arrière : fenêtres de bureaux, escalier de secours métallique, une porte de service.
8. **Local d'entretien** (`cote_entretien`, `iso_entretien_dos`, `dos_entretien`) : joindre `atelier.png` et `iso_entretien.png`. Cabane de planches au toit à une pente. Arrière : mur de planches, tonneau de récupération d'eau sous la gouttière, brouette retournée.
9. **Kiosque d'animation** (`cote_kiosque`, `iso_kiosque_dos`, `dos_kiosque`) : joindre `scene.png` et `iso_kiosque.png`. Petite scène à rideaux rouges, étoile dorée au fronton. Arrière : les coulisses, une paroi de planches peintes, une échelle, des malles de costumes et des câbles.
10. **Snack** (`cote_snack`, `iso_snack_dos`, `dos_snack`) : joindre `snack.png` et `iso_snack.png`. Kiosque à auvent rayé rouge et blanc, enseigne « SNACK » sur le toit. Arrière : porte de service, bouteille de gaz, caisses de boissons ; l'enseigne du toit vue de dos (lettres à l'envers, ou simple panneau de bois au dos).
11. **Intendance du parc** (`cote_intendance`, `iso_intendance_dos`, `dos_intendance`) : joindre `intendance.png` et `iso_intendance.png`. Maison de jardinier en bois vert sombre, serre vitrée accolée. Arrière : tas de compost, râteaux et pelles accrochés au mur, la serre vue de l'autre côté.
12. **Cuisine des animaux** (`cote_cuisine`, `iso_cuisine_dos`, `dos_cuisine`) : joindre `cuisine.png` et `iso_cuisine.png`. Bâtiment de ferme, cheminée qui fume. Arrière : bottes de foin, bidons de lait, tas de bûches pour le fourneau.
13. **Mairie** (`cote_mairie`, `iso_mairie_dos`, `dos_mairie`) : joindre `iso_mairie.png` et la nouvelle `mairie.png` (voir ci-dessous). Mairie de village à deux étages : corps central de briques orange avec horloge au fronton et drapeau violet à patte blanche, ailes enduites de rose pâle, toit d'ardoise bleue. Arrière : façade de briques sans perron, petite porte de service, rangée de fenêtres, l'horloge n'existe que devant.

## La mairie de face, à refaire d'abord

L'image de face actuelle (`mairie.png`) est minuscule et ne ressemble pas à l'image de biais : en tournant la vue, on voit la mairie changer. On garde l'image de biais, plus détaillée, comme référence, et on refait la face d'après elle.

Joignez `iso_mairie.png` et `iso_mairie_d.png`, puis utilisez le texte de `docs/prompt_batiments.md` en remplaçant sa première phrase de style par celle-ci : `C'est exactement le même bâtiment que sur les images jointes : mêmes matériaux, mêmes couleurs, même horloge, même drapeau. Seul l'angle de vue change.` Description : `Mairie de village vue de face, perron de pierre devant la porte, horloge au fronton, drapeau violet à patte blanche sur le toit. Enseigne « MAIRIE » au-dessus de la porte.` Nom : `mairie`.

Si vous préférez garder la mairie de face actuelle, dites-le à Claude : c'est alors l'image de biais qu'il faudra refaire.

## Facultatif : les miroirs

Le jeu retourne `cote_<id>` et `iso_<id>_dos` pour montrer l'autre côté. Si une enseigne ou un détail asymétrique gêne une fois retourné, faites aussi `cote_<id>_d` (le côté gauche, façade sur le bord droit) et `iso_<id>_dos_d` (face arrière vers le bas à gauche) : le jeu les prendra à la place du miroir.

## Après la génération

```bash
python docs/handoff_bd/generateurs/batiments_planches.py "<dossier des images>" .
```

```bash
godot --headless --path game --import
```

Puis F2 en jeu : la caméra tournera plus loin dès que les vues de côté de la Maison existent (`cote_maison`), et tout autour dès que ses vues de dos existent (`dos_maison`, `iso_maison_dos`).
