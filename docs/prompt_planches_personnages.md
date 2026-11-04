# Texte pour le générateur d'images : planches de personnages

Joignez toujours une planche existante en référence : le style et la mise en page seront bien mieux respectés. Une image par génération.
`docs/handoff_bd/generateurs/personnages_planches.py` découpe ces planches automatiquement si la mise en page est respectée.

## 1. Un nouveau personnage

Remplacez la dernière ligne par un personnage de la liste ci-dessous.

```text
Planche de sprites pour un jeu vidéo, en reprenant exactement le style et la mise en page de l'image jointe : bande dessinée franco-belge, trait d'encre noir épais, aplats de couleur, légères hachures.

Format paysage 1536 x 1024. Fond vert uni #00FF40, parfaitement plat, sans dégradé, sans texture, sans ombre.

En haut à gauche : le portrait du personnage, en buste, de trois quarts, sans cadre, coupé net en bas.

À droite du portrait : le personnage en pied, vu de profil et tourné vers la droite, en 4 rangées de 3 images :
- Rangée 1, marcher : 3 phases de marche nettement différentes (jambes écartées, jambes croisées, jambes écartées inversées).
- Rangée 2, construire : à genoux, il pose des pierres taillées ; 3 images, de plus en plus de pierres, posées devant lui à droite.
- Rangée 3, couper : hache levée au-dessus de la tête, puis hache abattue sur une souche à droite, avec des éclats de bois.
- Rangée 4, miner : pioche levée au-dessus de la tête, puis pioche abattue sur un tas de roches à droite, avec des éclats.

Règles de mise en page, à respecter strictement :
- Même personnage, même taille, mêmes vêtements et mêmes couleurs dans les 12 images et le portrait.
- Sous chaque image, un trait de sol noir fin et droit, à la même hauteur pour les 3 images de la rangée.
- Les 3 images d'une rangée sont espacées régulièrement et ne se touchent pas.
- Un espace vert d'au moins 20 pixels entre le trait de sol d'une rangée et le haut de la rangée suivante, outils levés compris.
- Le personnage entier reste visible, rien n'est coupé par les bords de l'image.
- Aucun texte, aucun chiffre, aucun logo, aucune ombre au sol, aucun décor en dehors des pierres, de la souche et des roches.
- Aucune couleur vert vif sur le personnage ni ses outils.

Personnage : [DESCRIPTION]
```

Douze personnages pour passer de 28 à 40, avec des tenues qui évoquent les métiers absents des planches actuelles :

1. Une femme de 50 ans, chignon strict, tailleur gris et foulard, l'air pincé (DRH).
2. Un homme de 45 ans, costume sombre, cravate rouge, cheveux gominés (Lobbyiste).
3. Une femme de 40 ans, tablier de commerçante à rayures, cheveux courts bouclés (Marchande).
4. Un homme de 30 ans, chemise à rayures, gilet et canotier (Vendeur de souvenirs).
5. Une jeune femme, blouse blanche de vétérinaire et bottes en caoutchouc, queue de cheval (Soigneuse).
6. Un homme de 55 ans, parka vert sombre de garde animalier, gros sourcils (Animalier).
7. Une jeune femme, polo jaune à sifflet, casquette, très souriante (Animatrice).
8. Un homme de 50 ans, casque de chantier blanc, chemise à manches courtes, plans dans la poche (Architecte).
9. Une femme de 60 ans, cardigan, lunettes en demi-lune, cheveux gris courts (Formatrice).
10. Un homme de 35 ans, combinaison d'entretien bleu ciel, moustache fine (Agent d'entretien).
11. Une jeune femme, uniforme de guichet bleu marine, cheveux au carré (Guichetière).
12. Un homme de 40 ans, chemise à carreaux et bretelles, barbe de trois jours, gilet orange de chantier (Contremaître).

## 2. Des gestes en plus pour un personnage existant

Pour les tâches qui n'ont pas encore d'animation : guichet, nourriture, nettoyage, soins. Joignez la planche du personnage.

```text
Planche de sprites pour un jeu vidéo : exactement le même personnage que sur l'image jointe, mêmes vêtements, mêmes couleurs, même taille, même style de bande dessinée, même trait d'encre.

Format paysage 1536 x 1024. Fond vert uni #00FF40, parfaitement plat, sans dégradé, sans texture, sans ombre.

En haut à gauche : le même portrait que sur l'image jointe, au même endroit.

À droite du portrait : le personnage en pied, vu de profil et tourné vers la droite, en 4 rangées de 3 images, placées comme sur l'image jointe :
- Rangée 1, guichet : debout, il tend un billet vers la droite, range le bras, tend à nouveau une pièce.
- Rangée 2, nourrir : il porte un seau de nourriture, le penche, verse le contenu au sol à droite.
- Rangée 3, nettoyer : il balaie avec un balai, balai à gauche, au centre, puis à droite, avec un peu de poussière.
- Rangée 4, soigner : penché en avant, il ouvre une trousse de secours, tend une seringue, puis pose un pansement vers la droite.

Règles de mise en page, à respecter strictement :
- Sous chaque image, un trait de sol noir fin et droit, à la même hauteur pour les 3 images de la rangée.
- Les 3 images d'une rangée sont espacées régulièrement et ne se touchent pas.
- Un espace vert d'au moins 20 pixels entre le trait de sol d'une rangée et le haut de la rangée suivante.
- Le personnage entier reste visible, rien n'est coupé par les bords de l'image.
- Aucun texte, aucun chiffre, aucun logo, aucune ombre au sol, aucun décor en dehors du seau, du balai, de la trousse et du billet.
- Aucune couleur vert vif sur le personnage ni ses objets.
```

Nommez ces planches avec le nom du personnage et « gestes » (par exemple `odette gestes.png`). Le découpage de ce second format reste à brancher dans `personnages_planches.py`, une fois la première planche reçue.
