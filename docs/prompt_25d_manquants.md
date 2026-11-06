# Textes pour le générateur d'images : tout ce qui manque à la vue 2,5D

La vue isométrique (F2) et la vue 3D (F3) réutilisent les images de la 2D. Ce qui manque, ce sont les images vues **de biais** : quand la vue est en diagonale, un bâtiment de face ou un personnage de profil paraît « collé » à l'écran.

## Bilan

| Quoi | Déjà fait | Reste à faire | Images | Priorité |
|---|---|---|---|---|
| Marche de biais des collaborateurs | Victor, Clara | 38 personnages | 38 planches | 1 |
| Bâtiments de biais | Snack, Intendance, Cuisine | 9 bâtiments | 18 images | 1 |
| Mairie, camp (3 niveaux), entrée de biais | — | 5 éléments | 10 images | 2 |
| Animaux de trois quarts (marche) | — | 40 espèces | 40 planches | 3, facultatif |
| Visiteurs de trois quarts | — | 6 silhouettes types | 6 planches | 4, facultatif |

Déjà bons tels quels, pas besoin de les refaire : clôtures et murs (posés en vraies faces dans la 3D), décorations du parc, aménagements d'enclos (arbre, rocher, bassin, abri), arbres et rochers du décor, gestes de travail (vus le plus souvent à l'arrêt).

Pour chaque lot, envoyez les images à Claude : il les découpe, les branche dans le jeu (la mairie, le camp et l'entrée demandent aussi un peu de code) et vous montre le résultat.

---

## 1. Marche de biais des 38 personnages

Même texte que pour Victor et Clara, dans `docs/prompt_marche_biais.md` (planche paysage 1536 × 1024, fond vert #00FF40, 2 rangées de 3 images : trois quarts face vers le bas à droite, trois quarts dos vers le haut à droite). Joignez à chaque demande la feuille actuelle du personnage : `game/assets/bd/sprites/personnages_v2/<id>.png` (prénom en minuscules sans accent : `elise.png`, `aicha.png`…).

Enregistrez chaque planche sous le nom indiqué. Remplacez `[DESCRIPTION]` par la ligne du personnage ; si elle ne correspond pas exactement à sa feuille, c'est la feuille jointe qui compte.

**Encadrement et service**
1. Élise (`Elise_biais.png`) : une femme de 50 ans, chignon strict, tailleur gris et foulard, l'air pincé.
2. Nadia (`Nadia_biais.png`) : une femme de 40 ans, tablier de commerçante à rayures, cheveux courts bouclés.
3. Louis (`Louis_biais.png`) : un homme de 30 ans, chemise à rayures, gilet et canotier.
4. Chloé (`Chloe_biais.png`) : une jeune femme, blouse blanche de vétérinaire et bottes en caoutchouc, queue de cheval.
5. Marcel (`Marcel_biais.png`) : un homme de 55 ans, parka vert sombre de garde animalier, gros sourcils.
6. Zoé (`Zoe_biais.png`) : une jeune femme, polo jaune à sifflet, casquette, très souriante.
7. Basile (`Basile_biais.png`) : un homme de 50 ans, casque de chantier blanc, chemise à manches courtes, plans dans la poche.
8. Odette (`Odette_biais.png`) : une femme de 60 ans, cardigan, lunettes en demi-lune, cheveux gris courts.
9. Kenji (`Kenji_biais.png`) : un homme de 35 ans, combinaison d'entretien bleu ciel, moustache fine.
10. Lina (`Lina_biais.png`) : une jeune femme, uniforme de guichet bleu marine, cheveux au carré.
11. Paul (`Paul_biais.png`) : un homme de 40 ans, chemise à carreaux et bretelles, barbe de trois jours, gilet orange de chantier.

**Chantier et terrain**
12. Fatou (`Fatou_biais.png`) : une femme noire de 30 ans, longues tresses nouées, salopette en jean et tee-shirt orange.
13. Hugo (`Hugo_biais.png`) : un homme de 25 ans, cheveux blonds en bataille, tee-shirt blanc, pantalon de travail beige, ceinture à outils.
14. Rose (`Rose_biais.png`) : une femme de 65 ans, chignon blanc, tablier de jardinier en toile bleue, gants de cuir.
15. Mamadou (`Mamadou_biais.png`) : un homme noir de 55 ans, crâne rasé, grosse barbe grise, veste de travail bleu marine.
16. Inès (`Ines_biais.png`) : une femme de 25 ans, cheveux noirs très courts, débardeur rouge, pantalon cargo gris.
17. Igor (`Igor_biais.png`) : un homme de 45 ans, très grand et massif, crâne chauve, moustache en guidon, marcel gris et bretelles.
18. Jade (`Jade_biais.png`) : une femme asiatique de 20 ans, couettes noires, casque de chantier jaune trop grand, salopette bleue.
19. Samir (`Samir_biais.png`) : un homme de 35 ans, cheveux noirs ondulés, barbe taillée, chemise de bûcheron rouge et noire.
20. Margaux (`Margaux_biais.png`) : une femme de 35 ans, cheveux roux en tresse épaisse, chemise de bûcheron bleue et noire, bonnet gris.
21. Théo (`Theo_biais.png`) : un homme de 20 ans, taches de rousseur, casquette à l'envers, sweat jaune, jean troué.
22. Sarah (`Sarah_biais.png`) : une femme de 45 ans, cheveux bruns courts, gilet de sécurité orange sur chemise grise, casque blanc.
23. Bastien (`Bastien_biais.png`) : un homme de 60 ans, béret noir, gilet de velours marron, chemise écrue, pipe éteinte.
24. Aïcha (`Aicha_biais.png`) : une femme maghrébine de 40 ans, foulard noué sur les cheveux, veste de travail bordeaux, pantalon noir.
25. Omar (`Omar_biais.png`) : un homme maghrébin de 60 ans, barbe blanche courte, calot, veste kaki usée.
26. Yasmine (`Yasmine_biais.png`) : une femme de 30 ans, longs cheveux noirs en queue haute, combinaison de mécanicienne bleu pétrole.
27. Noah (`Noah_biais.png`) : un homme métis de 25 ans, cheveux crépus courts, débardeur blanc, pantalon de treillis gris.
28. Gabin (`Gabin_biais.png`) : un homme de 30 ans, cheveux châtains mi-longs, bandana bleu, chemise en jean aux manches roulées.
29. Manon (`Manon_biais.png`) : une femme de 25 ans, cheveux bouclés bruns, bandana jaune, tee-shirt violet, salopette beige.
30. Malik (`Malik_biais.png`) : un homme noir de 30 ans, dreadlocks attachées, tablier de cuir, chemise blanche.
31. Emma (`Emma_biais.png`) : une femme de 20 ans, cheveux roses courts, piercing, veste de travail noire, bottes montantes.
32. Jules (`Jules_biais.png`) : un homme de 70 ans, sourcils broussailleux, casquette de marin, pull rayé bleu et blanc.
33. Lucie (`Lucie_biais.png`) : une femme de 60 ans, cheveux argentés en queue, lunettes rondes, salopette grise, carnet à la ceinture.
34. Nathan (`Nathan_biais.png`) : un homme de 40 ans, roux, grosse barbe, casque de mineur à lampe, veste de cuir marron.
35. Camille (`Camille_biais.png`) : une femme de 35 ans, coupe garçonne châtain, gilet de reporter beige à poches, chemise blanche.
36. Adam (`Adam_biais.png`) : un homme d'Asie du Sud de 45 ans, moustache noire, turban orange, chemise blanche, gilet marron.
37. Léa (`Lea_biais.png`) : une femme noire de 25 ans, afro volumineuse, chemise rouge nouée à la taille, pantalon de toile crème.
38. Tom (`Tom_biais.png`) : un homme de 35 ans, lunettes carrées, chemise bleu clair, cravate rentrée dans la chemise, sac en bandoulière.

Découpage : `python docs/handoff_bd/generateurs/personnages_planches.py "<dossier>" .` puis `godot --headless --path game --import`. Rien d'autre à faire : le jeu les prend dès qu'elles existent.

---

## 2. Les 9 bâtiments de biais

Même texte commun et mêmes deux orientations que dans `docs/prompt_batiments_biais.md` (paysage 1536 × 1024, fond magenta #FF00FF, emprise en losange 2 pour 1, angle le plus proche en bas au milieu). Joignez à chaque demande l'image actuelle du bâtiment, puis, pour la seconde orientation, la première réussie.

Deux images par bâtiment : façade à gauche (nom sans suffixe) et façade à droite (nom finissant par `_d`).

1. **Maison du personnel** (`iso_maison`, `iso_maison_d`) : image jointe `maison.png`. Petite maison de village, murs crème et colombages, toit de tuiles rouges, cheminée, fleurs devant la porte.
2. **Entrepôt** (`iso_entrepot`, `iso_entrepot_d`) : image jointe `entrepot.png`. Grange en planches, toit de tuiles orange, grande porte ouverte sur la façade, caisses empilées devant.
3. **Mine d'or** (`iso_mine`, `iso_mine_d`) : image jointe `mine.png`. Entrée de galerie étayée de poutres dans un monticule de rochers, rails qui sortent par l'ouverture, pépites dorées dans la roche. L'ouverture tient lieu de façade.
4. **Boutique de souvenirs** (`iso_boutique`, `iso_boutique_d`) : image jointe `souvenirs.png`. Échoppe à auvent rayé rouge et blanc, vitrine de peluches, ourson sculpté sur le toit, enseigne « SOUVENIRS ».
5. **Marché** (`iso_comptoir`, `iso_comptoir_d`) : image jointe `marche.png`. Étal de bois à auvent rayé rouge et blanc, cagettes de marchandises sur le comptoir, sans enseigne écrite.
6. **Agence d'intérim** (`iso_agence`, `iso_agence_d`) : image jointe `agence.png`. Bâtiment préfabriqué gris et bleu, climatiseur sur le toit, vitrine couverte d'offres d'emploi, deux chaises en plastique devant, enseigne « INTÉRIM ».
7. **Cabinet de recrutement** (`iso_cabinet`, `iso_cabinet_d`) : image jointe `cabinet.png`. Petit immeuble de bureaux à deux étages, beige, grandes baies vitrées, enseigne « RECRUTEMENT » au-dessus de l'entrée.
8. **Local d'entretien** (`iso_entretien`, `iso_entretien_d`) : image jointe `atelier.png`. Cabane de planches au toit à une pente, balais, râteaux et seaux appuyés contre la façade, sans enseigne écrite.
9. **Kiosque d'animation** (`iso_kiosque`, `iso_kiosque_d`) : image jointe `scene.png`. Petite scène de spectacle à rideaux rouges, étoile dorée au fronton, enceintes de chaque côté. Le devant de la scène tient lieu de façade.

Découpage : `python docs/handoff_bd/generateurs/batiments_planches.py "<dossier>" .` puis `godot --headless --path game --import`. Rien d'autre à faire non plus.

---

## 3. Mairie, camp et entrée de biais

Même texte commun que les bâtiments. Ces éléments sont dessinés à part dans le jeu : il faudra un peu de code pour les brancher (Claude s'en charge à réception).

1. **Mairie** (`iso_mairie`, `iso_mairie_d`) : image jointe `mairie.png`. Mairie de village en briques roses, toit d'ardoise bleue, horloge au fronton, drapeau violet sur le toit, perron de pierre devant la porte.
2. **Camp, niveau 1** (`iso_camp1`, `iso_camp1_d`) : image jointe `camp1.png`. Campement vu en losange : deux tentes de toile écrue rapiécées, caisses de bois, feu de camp entouré de pierres, rondins, clôture basse en bois tout autour avec une ouverture côté façade.
3. **Camp, niveau 2** (`iso_camp2`, `iso_camp2_d`) : image jointe `camp2.png`. Le même campement plus grand : grande tente rayée orange et blanc, trois tentes écrues, table à plans, outils sur un râtelier, palissade de pieux et portail de bois côté façade.
4. **Camp, niveau 3** (`iso_camp3`, `iso_camp3_d`) : image jointe `camp3.png`. Le campement agrandi : cabane en planches au toit de tôle, tentes, auvent rayé, table à plans, palissade de pieux et portail orné d'une patte de chat orange côté façade.
5. **Entrée du zoo** (`iso_entree`, `iso_entree_d`) : image jointe `entree.png`. Portique de bois et de pierre, deux piliers de pierre à lanternes, toit d'ardoise, enseigne « ZOOLIFE » avec une patte au milieu, amorce de palissade de chaque côté. Ici, la « façade » est le passage : vu de biais, on voit le passage en diagonale, vers le bas à gauche (sans suffixe) ou vers le bas à droite (`_d`).

Pour les trois camps, ajoutez au texte commun : `Le campement est carré et vu depuis un coin : son emprise est un losange plein, la clôture en suit les quatre côtés.`

---

## 4. Animaux de trois quarts (facultatif)

Dans la vue en diagonale, les animaux marchent aujourd'hui de profil, retournés selon le sens : ça passe, mais une marche de trois quarts serait plus juste. Une planche par espèce, sur le modèle des personnages. Joignez l'image actuelle de l'animal : `game/assets/bd/sprites/animaux_v2/<id>.png`.

```text
Planche de sprites pour un jeu vidéo, dans le style de l'image jointe : bande dessinée franco-belge, trait d'encre noir épais, aplats de couleur, légères hachures. C'est exactement le même animal que sur l'image jointe : même pelage ou plumage, mêmes couleurs, mêmes proportions, même trait. Seul l'angle de vue change.

Format paysage 1536 x 1024. Fond vert uni #00FF40, parfaitement plat, jusqu'aux bords de l'image. Aucun cadre, aucune bordure.

L'animal entier, en 2 rangées de 3 images, à la même échelle partout :
1. Rangée du haut, il marche vers nous en diagonale : vu de trois quarts face, il avance vers le bas à droite de l'image. Trois temps de sa marche (ou de son vol, ou de sa nage pour un animal qui ne marche pas).
2. Rangée du bas, il s'éloigne en diagonale : vu de trois quarts dos, il avance vers le haut à droite de l'image. Les trois mêmes temps.

Règles à respecter strictement :
- Même animal, mêmes couleurs dans les 6 images.
- Sous chaque image, un trait de sol noir fin et droit, à la même hauteur pour les 3 images de la rangée.
- Les 3 images d'une rangée sont espacées régulièrement et ne se touchent pas.
- Un espace vert d'au moins 30 pixels entre les deux rangées.
- Aucun texte, aucune ombre au sol, aucun décor.
- Aucune couleur vert vif sur l'animal.

Animal : [NOM]
```

Fichier au nom de l'espèce, par exemple `zebre_biais.png`. Ordre conseillé : les 19 communs d'abord (les plus vus), puis les 13 peu communs, puis les 8 rares. Liste complète dans le glossaire (Règles et glossaire › Animaux). Ces planches demandent un découpage nouveau : Claude l'écrira à réception des premières.

---

## 5. Visiteurs de trois quarts (facultatif)

Les visiteurs sont de petites silhouettes, peu visibles : six planches types suffisent (le jeu les répartit entre tous les visiteurs). Même texte que les personnages (`docs/prompt_marche_biais.md`), sans pièce jointe ; joignez seulement une planche de personnage réussie pour le style.

1. `Visiteur1_biais.png` : un père de famille en polo bleu et bermuda beige, appareil photo autour du cou.
2. `Visiteur2_biais.png` : une mère de famille en robe d'été jaune, sac à main, lunettes de soleil sur la tête.
3. `Visiteur3_biais.png` : un garçon de 8 ans, tee-shirt rouge, short, casquette, ballon à la main.
4. `Visiteur4_biais.png` : une fille de 10 ans, robe à pois roses, couettes, peluche sous le bras.
5. `Visiteur5_biais.png` : un grand-père à canne, gilet beige, chapeau de paille.
6. `Visiteur6_biais.png` : une randonneuse en coupe-vent vert, sac à dos, gourde.

Ces planches aussi demandent un peu de code ; Claude s'en charge à réception.
