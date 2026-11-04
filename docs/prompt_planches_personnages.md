# Texte pour le générateur d'images : planches de personnages

Joignez toujours une planche existante en référence : le style et la mise en page seront bien mieux respectés. Une image par génération.
`docs/handoff_bd/generateurs/personnages_planches.py` découpe ces planches automatiquement si la mise en page est respectée.

## Format retenu : un personnage par planche, avec ses 8 gestes

Les 8 gestes dans la même image gardent exactement le même personnage, et le nombre d'images reste de 40. Remplacez `[DESCRIPTION]` par une ligne de la liste. Testez une planche avant de lancer les autres.

```text
Planche de sprites pour un jeu vidéo, dans le style de l'image jointe : bande dessinée franco-belge, trait d'encre noir épais, aplats de couleur, légères hachures. Reprends le style, pas le personnage de l'image jointe.

Format portrait 1024 x 1536. Fond vert uni #00FF40, parfaitement plat, jusqu'aux bords de l'image. Aucun cadre, aucune bordure, aucune bande de séparation.

Colonne de gauche, sur moins de 300 pixels de large : le portrait du personnage en haut, en buste, de trois quarts, sans cadre, coupé net en bas. Rien d'autre dans cette colonne. Le portrait, épaules comprises, ne dépasse jamais cette colonne.

À droite de cette colonne : le personnage en pied, vu de profil et tourné vers la droite, en 8 rangées de 3 images, à la même échelle partout :
1. Marcher : jambes écartées, jambes croisées, jambes écartées inversées.
2. Construire : à genoux, il pose des pierres taillées devant lui à droite, de plus en plus de pierres d'une image à l'autre.
3. Couper : hache levée au-dessus de la tête, puis hache abattue sur une souche à droite, avec des éclats de bois.
4. Miner : pioche levée au-dessus de la tête, puis pioche abattue sur un tas de roches à droite, avec des éclats.
5. Servir : debout, il tend un billet vers la droite, ramène le bras, tend une pièce.
6. Nourrir : il porte un seau, le penche, verse la nourriture au sol à droite.
7. Balayer : il balaie avec un balai, à gauche, au centre, puis à droite, avec un peu de poussière.
8. Soigner : penché en avant, il ouvre une trousse de secours, tend une seringue, pose un pansement vers la droite.

Règles de mise en page, à respecter strictement :
- Même personnage, mêmes vêtements et mêmes couleurs dans les 24 images et le portrait.
- Toutes les rangées ont la même hauteur, et le personnage y garde la même taille.
- Sous chaque image, un trait de sol noir fin et droit, à la même hauteur pour les 3 images de la rangée, et un seul trait par image.
- Les 3 images d'une rangée sont espacées régulièrement et ne se touchent pas.
- Un espace vert d'au moins 15 pixels entre le trait de sol d'une rangée et le haut de la rangée suivante, outils levés compris.
- Le personnage et ses outils restent entiers, rien n'est coupé par les bords de l'image.
- Aucun texte, aucun chiffre, aucun logo, aucune ombre au sol, aucun décor en dehors des objets cités.
- Aucune couleur vert vif sur le personnage ni ses objets.

Personnage : [DESCRIPTION]
```

Enregistrez chaque planche sous le prénom du personnage (par exemple `Fatou.png`).

## Si le générateur s'y perd : deux personnages par planche

Essai du 04/11 : ce format se découpe bien, mais les gestes 5 à 8 demanderaient des planches séparées, avec le risque que le personnage change. Dans le texte ci-dessus, remplacez le format et la mise en page par :

```text
Format paysage 1536 x 1024, partagé en deux moitiés égales, une par personnage, séparées par une simple bande blanche horizontale. Pas d'autre cadre ni bordure. Dans chaque moitié, le portrait reste à gauche, sur moins de 380 pixels de large, épaules comprises, et le personnage en pied garde la même échelle dans les deux moitiés, en 4 rangées de 3 images : marcher, construire, couper, miner.
```

Quarante personnages, 20 femmes et 20 hommes, pour refaire toutes les planches. Enregistrez chaque planche sous le prénom indiqué (par exemple `Elise.png`) : le découpage en déduira le nom et le genre. Le métier entre parenthèses inspire seulement la tenue, n'importe quelle carte pouvant recevoir n'importe quel personnage.

### Tenues des métiers d'encadrement et de service

1. Élise : une femme de 50 ans, chignon strict, tailleur gris et foulard, l'air pincé (DRH).
2. Victor : un homme de 45 ans, costume sombre, cravate rouge, cheveux gominés (Lobbyiste).
3. Nadia : une femme de 40 ans, tablier de commerçante à rayures, cheveux courts bouclés (Marchande).
4. Louis : un homme de 30 ans, chemise à rayures, gilet et canotier (Vendeur de souvenirs).
5. Chloé : une jeune femme, blouse blanche de vétérinaire et bottes en caoutchouc, queue de cheval (Soigneuse).
6. Marcel : un homme de 55 ans, parka vert sombre de garde animalier, gros sourcils (Animalier).
7. Zoé : une jeune femme, polo jaune à sifflet, casquette, très souriante (Animatrice).
8. Basile : un homme de 50 ans, casque de chantier blanc, chemise à manches courtes, plans dans la poche (Architecte).
9. Odette : une femme de 60 ans, cardigan, lunettes en demi-lune, cheveux gris courts (Formatrice).
10. Kenji : un homme de 35 ans, combinaison d'entretien bleu ciel, moustache fine (Agent d'entretien).
11. Lina : une jeune femme, uniforme de guichet bleu marine, cheveux au carré (Guichetière).
12. Paul : un homme de 40 ans, chemise à carreaux et bretelles, barbe de trois jours, gilet orange de chantier (Contremaître).

### Tenues de chantier et de terrain

13. Fatou : une femme noire de 30 ans, longues tresses nouées, salopette en jean et tee-shirt orange (Maçonne).
14. Hugo : un homme de 25 ans, cheveux blonds en bataille, tee-shirt blanc, pantalon de travail beige, ceinture à outils (Manœuvre).
15. Rose : une femme de 65 ans, chignon blanc, tablier de jardinier en toile bleue, gants de cuir (Paysagiste).
16. Mamadou : un homme noir de 55 ans, crâne rasé, grosse barbe grise, veste de travail bleu marine (Mineur).
17. Inès : une femme de 25 ans, cheveux noirs très courts, débardeur rouge, pantalon cargo gris (Terrassière).
18. Igor : un homme de 45 ans, très grand et massif, crâne chauve, moustache en guidon, marcel gris et bretelles (Porteur).
19. Jade : une femme asiatique de 20 ans, couettes noires, casque de chantier jaune trop grand, salopette bleue (Apprentie).
20. Samir : un homme de 35 ans, cheveux noirs ondulés, barbe taillée, chemise de bûcheron rouge et noire (Bûcheron).
21. Margaux : une femme de 35 ans, cheveux roux en tresse épaisse, chemise de bûcheron bleue et noire, bonnet gris (Bûcheronne).
22. Théo : un homme de 20 ans, taches de rousseur, casquette à l'envers, sweat jaune, jean troué (Apprenti).
23. Sarah : une femme de 45 ans, cheveux bruns courts, gilet de sécurité orange sur chemise grise, casque blanc (Cantonnière).
24. Bastien : un homme de 60 ans, béret noir, gilet de velours marron, chemise écrue, pipe éteinte (Charpentier).
25. Aïcha : une femme maghrébine de 40 ans, foulard noué sur les cheveux, veste de travail bordeaux, pantalon noir (Charpentière).
26. Omar : un homme maghrébin de 60 ans, barbe blanche courte, calot, veste kaki usée (Terrassier).
27. Yasmine : une femme de 30 ans, longs cheveux noirs en queue haute, combinaison de mécanicienne bleu pétrole (Mineuse).
28. Noah : un homme métis de 25 ans, cheveux crépus courts, débardeur blanc, pantalon de treillis gris (Maçon).
29. Clara : une femme de 50 ans, cheveux blonds grisonnants au carré, grand chapeau de paille, chemise à fleurs, tablier vert sombre (Jardinière).
30. Gabin : un homme de 30 ans, cheveux châtains mi-longs, bandana bleu, chemise en jean aux manches roulées (Paysagiste).
31. Manon : une femme de 25 ans, cheveux bouclés bruns, bandana jaune, tee-shirt violet, salopette beige (Manœuvre).
32. Malik : un homme noir de 30 ans, dreadlocks attachées, tablier de cuir, chemise blanche (Maréchal-ferrant).
33. Emma : une femme de 20 ans, cheveux roses courts, piercing, veste de travail noire, bottes montantes (Porteuse).
34. Jules : un homme de 70 ans, sourcils broussailleux, casquette de marin, pull rayé bleu et blanc (Vieux gardien).
35. Lucie : une femme de 60 ans, cheveux argentés en queue, lunettes rondes, salopette grise, carnet à la ceinture (Cheffe d'équipe).
36. Nathan : un homme de 40 ans, roux, grosse barbe, casque de mineur à lampe, veste de cuir marron (Mineur).
37. Camille : une femme de 35 ans, coupe garçonne châtain, gilet de reporter beige à poches, chemise blanche (Exploratrice).
38. Adam : un homme d'Asie du Sud de 45 ans, moustache noire, turban orange, chemise blanche, gilet marron (Soigneur).
39. Léa : une femme noire de 25 ans, afro volumineuse, chemise rouge nouée à la taille, pantalon de toile crème (Animalière).
40. Tom : un homme de 35 ans, lunettes carrées, chemise bleu clair, cravate rentrée dans la chemise, sac en bandoulière (Comptable égaré sur le chantier).
