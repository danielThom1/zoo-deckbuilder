# Étude du jeu par l'IA qui apprend

168 parties sur 200 jouées (étude en cours), 37 min de calcul. Fin de partie en moyenne au jour 15.5.
Record : victoire au jour 12 (102 de réputation, graine 880236281).

**Comment lire les tableaux** : « Victoires avec » est le taux de victoire des joueurs qui avaient cet élément en fin de partie, « sans » celui des autres. Un écart positif veut dire que l'élément accompagne la victoire, sans le prouver : un joueur qui gagne a aussi plus d'ouvriers, de bâtiments et d'animaux. « ≈ » signale un écart trop faible pour conclure, compte tenu du nombre de parties.

## En bref : forts et faibles

Écart de victoires en points, seulement quand il est significatif, et hors éléments presque absents ou présents chez presque tous. Les bâtiments et les améliorations communes sont faussés : un joueur qui dure en a davantage.

- **Traits** : forts : Économe (+9) ; faibles : Rabat-joie (-7).
- **Métiers** : forts : Paysagiste (+13) ; faibles : Animalier (-8).
- **Améliorations** : forts : Devenir Charpentier (+15) ; faibles : aucun net.
- **Cartes** : forts : Portes ouvertes (+17), Heures sup (+12), Livraison (+11), Recrutement express (+9), Formation express (+8) ; faibles : aucun net.
- **Animaux** : forts : Ara rouge (+28), Phoque gris (+24), Loutre à joues blanches (+21), Zèbre (+16), Yak (+15) ; faibles : aucun net.
- **Bâtiments** : forts : Cuisine des animaux (+28), Local d'entretien (+26), Entrée du zoo (+25), Kiosque d'animation (+21), Camp niveau 3 (+18) ; faibles : Entrepôt (-8).

## Stratégies apprises

| Génération | Victoires de la meilleure | Jour moyen | Réputation | Moyenne de la population |
|---|---|---|---|---|
| 1 | 83 % | 16.2 | 99 | 25 % |
| 2 | 67 % | 14.3 | 102 | 24 % |
| 3 | 67 % | 15.5 | 74 | 25 % |
| 4 | 67 % | 13.8 | 97 | 25 % |
| 5 | 67 % | 14.8 | 93 | 25 % |
| 6 | 83 % | 14.8 | 100 | 25 % |
| 7 | 67 % | 14.8 | 77 | 24 % |

1. parc moyen, palier 0.8, réserve 3, lobby 0, camp 0, contrats 4, marche, rush_or, fast_expand, route_mine
2. parc moyen, palier 0.7, réserve 14, lobby 1, camp 1, contrats 4, marche, rush_or, fast_expand
3. parc moyen, palier 0.7, réserve 14, lobby 0, camp 2, contrats 4, marche, spectacle, fast_expand, route_mine
4. parc moyen, palier 0.7, réserve 14, lobby 0, camp 1, contrats 4, marche, rush_or, fast_expand, route_mine

Réglages retenus par les 8 meilleures : marche 5/8, rush_or 4/8, formation 0/8, cartes 0/8, spectacle 1/8, affinite 0/8, boutique 6/8, mine 2/8, specialisation 0/8, fast_expand 7/8, route_mine 6/8.

**Métiers, des plus recherchés aux plus évités par les IA qui gagnent** : Contremaître +0.7, Cantonnier +0.3, Apprenti +0.3, Agent d'entretien +0.3, Maçon +0.2, Paysagiste +0.2, Animalier +0.2, Lobbyiste +0.1, Marchand +0.1, Charpentier +0.0, Manœuvre +0.0, Terrassier -0.1, Animateur -0.1, Architecte -0.1, DRH -0.1, Mineur -0.1, Porteur -0.1, Bûcheron -0.2, Formateur -0.2, Vendeur de souvenirs -0.2, Guichetier -0.2, Soigneur -0.3.

**Traits, des plus recherchés aux plus évités par les IA qui gagnent** : Bon élève +1.0, Costaud +0.3, Naturaliste +0.2, Matinal +0.2, Endurant +0.2, Têtu +0.1, Économe +0.1, Casanier +0.0, Charismatique +0.0, Lent +0.0, Débrouillard -0.0, Polyvalent -0.0, Paresseux -0.0, Maladroit -0.0, Rabat-joie -0.1, Col blanc -0.1, Peureux -0.1, Rapide -0.2, Gourmand -0.2, Distrait -0.2.

**Animaux, des plus recherchés aux plus évités par les IA qui gagnent** : Calao bicorne +0.4, Ara rouge +0.3, Salamandre géante +0.2, Tapir de Baird +0.2, Bison d'Amérique +0.2, Alligator américain +0.2, Bouquetin des Alpes +0.2, Loup gris +0.1, Yak +0.1, Loutre d'Europe +0.1, Manchot du Cap +0.0, Jaguar +0.0, Loutre à joues blanches +0.0, Bison d'Europe +0.0, Hyène tachetée +0.0, Guépard +0.0, Pygargue à tête blanche +0.0, Lion +0.0, Messager sagittaire +0.0, Aigle royal +0.0, Mésange charbonnière +0.0, Paon bleu -0.0, Tigre du Bengale -0.0, Cerf élaphe -0.0, Hippopotame -0.0, Léopard des neiges -0.0, Lynx boréal -0.0, Panda géant -0.0, Girafe -0.0, Capybara -0.1, Zèbre -0.1, Ocelot -0.1, Loutre cendrée -0.1, Phoque gris -0.1, Grue du Japon -0.1, Puma -0.2, Dauphin rose de l'Amazone -0.2, Faucon pèlerin -0.2, Carpe koï -0.6, Grue couronnée -0.6.

**Cartes, des plus recherchés aux plus évités par les IA qui gagnent** : Prime +0.4, Heures sup +0.1, Formation express +0.0, Portes ouvertes +0.0, Promotion +0.0, Rupture de contrat -0.1, Recrutement express -0.2, Livraison -0.4.

**Améliorations, des plus recherchés aux plus évités par les IA qui gagnent** : Fidélité +0.5, Expérience +0.2, Révélation +0.0, Seconde spécialité +0.0, Négociateur +0.0, Visionnaire +0.0, Chasseur de têtes -0.0, Remise en question -0.0, Brouette -0.1, Scie affûtée -0.1, Pied léger -0.1, Pédagogue -0.2, Réseau -0.3, Maîtrise -0.6.

## Traits des ouvriers

Joueurs ayant au moins un ouvrier avec ce trait. Défauts et qualités sont tirés au draft, mais l'IA choisit ses cartes : les traits les plus visibles sont en partie évités.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Économe | 448 | 28 % | 19 % | +9 pts | 71 | 61 |
| Endurant | 435 | 27 % | 21 % | ≈ +6 pts | 69 | 65 |
| Bon élève | 486 | 26 % | 22 % | ≈ +4 pts | 70 | 61 |
| Naturaliste | 449 | 26 % | 22 % | ≈ +4 pts | 71 | 61 |
| Col blanc | 69 | 28 % | 24 % | ≈ +3 pts | 66 | 68 |
| Rapide | 426 | 25 % | 24 % | ≈ +2 pts | 69 | 65 |
| Costaud | 477 | 25 % | 24 % | ≈ +2 pts | 69 | 63 |
| Matinal | 450 | 25 % | 24 % | ≈ +1 pts | 69 | 64 |
| Casanier | 268 | 25 % | 24 % | ≈ +1 pts | 67 | 68 |
| Têtu | 294 | 25 % | 24 % | ≈ +1 pts | 66 | 68 |
| Paresseux | 273 | 25 % | 25 % | ≈ +0 pts | 66 | 68 |
| Charismatique | 446 | 25 % | 25 % | ≈ +0 pts | 69 | 65 |
| Polyvalent | 427 | 25 % | 25 % | ≈ +0 pts | 69 | 64 |
| Débrouillard | 443 | 24 % | 25 % | ≈ -1 pts | 69 | 65 |
| Peureux | 259 | 24 % | 25 % | ≈ -1 pts | 67 | 68 |
| Lent | 255 | 24 % | 25 % | ≈ -1 pts | 61 | 72 |
| Gourmand | 240 | 23 % | 26 % | ≈ -3 pts | 65 | 69 |
| Distrait | 260 | 22 % | 26 % | ≈ -4 pts | 65 | 69 |
| Maladroit | 252 | 22 % | 26 % | ≈ -5 pts | 64 | 69 |
| Rabat-joie | 249 | 20 % | 27 % | -7 pts | 65 | 69 |

## Métiers

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Paysagiste | 470 | 29 % | 15 % | +13 pts | 75 | 49 |
| Contremaître | 133 | 30 % | 23 % | ≈ +7 pts | 74 | 66 |
| Animateur | 126 | 29 % | 24 % | ≈ +6 pts | 73 | 66 |
| Terrassier | 346 | 27 % | 22 % | ≈ +6 pts | 70 | 65 |
| Marchand | 137 | 28 % | 24 % | ≈ +5 pts | 75 | 66 |
| Lobbyiste | 130 | 28 % | 24 % | ≈ +5 pts | 72 | 66 |
| Cantonnier | 359 | 27 % | 22 % | ≈ +4 pts | 70 | 65 |
| Bûcheron | 280 | 27 % | 23 % | ≈ +4 pts | 67 | 68 |
| DRH | 128 | 27 % | 24 % | ≈ +2 pts | 71 | 67 |
| Soigneur | 314 | 26 % | 24 % | ≈ +2 pts | 68 | 67 |
| Charpentier | 357 | 25 % | 24 % | ≈ +2 pts | 70 | 65 |
| Vendeur de souvenirs | 112 | 26 % | 24 % | ≈ +1 pts | 76 | 66 |
| Agent d'entretien | 241 | 25 % | 24 % | ≈ +1 pts | 64 | 69 |
| Mineur | 305 | 25 % | 25 % | ≈ +0 pts | 69 | 66 |
| Apprenti | 12 | 25 % | 25 % | ≈ +0 pts | 67 | 67 |
| Formateur | 74 | 24 % | 25 % | ≈ +0 pts | 69 | 67 |
| Porteur | 307 | 24 % | 25 % | ≈ -1 pts | 65 | 70 |
| Maçon | 310 | 24 % | 25 % | ≈ -1 pts | 68 | 67 |
| Architecte | 114 | 22 % | 25 % | ≈ -3 pts | 67 | 68 |
| Guichetier | 270 | 21 % | 27 % | ≈ -5 pts | 63 | 70 |
| Animalier | 302 | 21 % | 28 % | -8 pts | 63 | 71 |
| Manœuvre | 14 | 14 % | 25 % | ≈ -11 pts | 55 | 68 |

## Améliorations

Choisies 25 % du temps au hasard pendant l'apprentissage, pour que toutes soient essayées.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Remise en question | 669 | 25 % | 0 % | ≈ +25 pts | 68 | 52 |
| Maîtrise | 672 | 25 % | 0 % | ≈ +25 pts | 67 | 0 |
| Devenir Charpentier | 52 | 38 % | 24 % | +15 pts | 76 | 67 |
| Devenir Cantonnier | 59 | 32 % | 24 % | ≈ +8 pts | 64 | 68 |
| Fidélité | 615 | 25 % | 18 % | ≈ +8 pts | 69 | 54 |
| Devenir Porteur | 41 | 32 % | 24 % | ≈ +7 pts | 69 | 67 |
| Devenir Animalier | 64 | 31 % | 24 % | ≈ +7 pts | 73 | 67 |
| Négociateur | 48 | 31 % | 24 % | ≈ +7 pts | 76 | 67 |
| Pied léger | 555 | 26 % | 20 % | ≈ +6 pts | 69 | 61 |
| Visionnaire | 202 | 29 % | 23 % | ≈ +6 pts | 77 | 64 |
| Expérience | 564 | 26 % | 20 % | ≈ +5 pts | 69 | 60 |
| Seconde spécialité : Extraction de bois | 208 | 28 % | 23 % | ≈ +5 pts | 71 | 66 |
| Révélation | 596 | 25 % | 21 % | ≈ +4 pts | 68 | 60 |
| Scie affûtée | 149 | 28 % | 24 % | ≈ +4 pts | 65 | 68 |
| Seconde spécialité : Clôtures d'enclos | 167 | 27 % | 24 % | ≈ +3 pts | 69 | 67 |
| Devenir Agent d'entretien | 33 | 27 % | 25 % | ≈ +3 pts | 65 | 68 |
| Seconde spécialité : Extraction de pierre | 178 | 26 % | 24 % | ≈ +2 pts | 73 | 66 |
| Devenir Paysagiste | 53 | 26 % | 25 % | ≈ +2 pts | 74 | 67 |
| Seconde spécialité : Construction en bois | 161 | 26 % | 24 % | ≈ +2 pts | 69 | 67 |
| Brouette | 151 | 25 % | 25 % | ≈ +0 pts | 67 | 68 |
| Devenir Bûcheron | 37 | 24 % | 25 % | ≈ +0 pts | 68 | 67 |
| Seconde spécialité : Guichet | 177 | 24 % | 25 % | ≈ -1 pts | 72 | 66 |
| Seconde spécialité : Construction en pierre | 176 | 23 % | 25 % | ≈ -2 pts | 66 | 68 |
| Devenir Terrassier | 33 | 21 % | 25 % | ≈ -4 pts | 69 | 67 |
| Devenir Soigneur | 52 | 21 % | 25 % | ≈ -4 pts | 62 | 68 |
| Seconde spécialité : Routes | 208 | 22 % | 26 % | ≈ -4 pts | 69 | 67 |
| Chasseur de têtes | 40 | 20 % | 25 % | ≈ -5 pts | 75 | 67 |
| Devenir Guichetier | 41 | 20 % | 25 % | ≈ -6 pts | 55 | 68 |
| Pédagogue | 27 | 19 % | 25 % | ≈ -6 pts | 68 | 67 |
| Devenir Maçon | 39 | 18 % | 25 % | ≈ -7 pts | 65 | 68 |
| Réseau | 66 | 18 % | 25 % | ≈ -7 pts | 72 | 67 |
| Devenir Mineur | 55 | 16 % | 25 % | ≈ -9 pts | 66 | 68 |

## Bâtiments

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Cuisine des animaux | 588 | 28 % | 0 % | +28 pts | 76 | 10 |
| Local d'entretien | 490 | 32 % | 6 % | +26 pts | 80 | 34 |
| Abri chauffé | 4 | 50 % | 25 % | ≈ +25 pts | 73 | 67 |
| Entrée du zoo | 659 | 25 % | 0 % | +25 pts | 69 | 10 |
| Kiosque d'animation | 424 | 32 % | 12 % | +21 pts | 82 | 43 |
| Camp niveau 3 | 36 | 42 % | 24 % | +18 pts | 84 | 67 |
| Camp niveau 2 | 510 | 29 % | 11 % | +18 pts | 73 | 51 |
| Grand arbre | 12 | 42 % | 24 % | ≈ +17 pts | 80 | 67 |
| Boutique de souvenirs | 337 | 32 % | 17 % | +15 pts | 79 | 56 |
| Maison d'ouvriers | 615 | 25 % | 19 % | ≈ +6 pts | 68 | 57 |
| Rocher d'observation | 15 | 27 % | 25 % | ≈ +2 pts | 71 | 67 |
| Mine d'or | 282 | 26 % | 24 % | ≈ +1 pts | 71 | 65 |
| Centre de formation | 116 | 26 % | 24 % | ≈ +1 pts | 68 | 67 |
| Marché | 255 | 25 % | 24 % | ≈ +1 pts | 72 | 65 |
| Entrepôt | 371 | 21 % | 29 % | -8 pts | 66 | 70 |
| Bassin profond | 4 | 0 % | 25 % | ≈ -25 pts | 57 | 68 |

## Labels

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| certifie | 17 | 24 % | 25 % | ≈ -1 pts | 74 | 67 |
| mecenat | 5 | 20 % | 25 % | ≈ -5 pts | 69 | 67 |
| excellence | 1 | 0 % | 25 % | ≈ -25 pts | 78 | 67 |

## Cartes à usage unique et cadres joués

Joueurs ayant joué cette carte au moins une fois.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Portes ouvertes | 278 | 35 % | 18 % | +17 pts | 84 | 56 |
| Heures sup | 302 | 31 % | 19 % | +12 pts | 76 | 60 |
| Vendeur de souvenirs joué (Braderie) | 66 | 35 % | 24 % | ≈ +11 pts | 88 | 65 |
| Livraison | 280 | 31 % | 20 % | +11 pts | 78 | 60 |
| Recrutement express | 272 | 30 % | 21 % | +9 pts | 77 | 61 |
| Formation express | 284 | 30 % | 21 % | +8 pts | 76 | 61 |
| Prime | 276 | 28 % | 22 % | ≈ +6 pts | 75 | 62 |
| Animateur joué (Grand spectacle) | 70 | 30 % | 24 % | ≈ +6 pts | 81 | 66 |
| Promotion | 292 | 28 % | 22 % | ≈ +5 pts | 75 | 62 |
| Rupture de contrat | 287 | 28 % | 23 % | ≈ +5 pts | 75 | 62 |
| Lobbyiste joué (Coup de fil) | 90 | 28 % | 24 % | ≈ +4 pts | 70 | 67 |
| Formateur joué (Cours du soir) | 31 | 23 % | 25 % | ≈ -2 pts | 58 | 68 |
| DRH joué (Mutation) | 112 | 21 % | 25 % | ≈ -4 pts | 68 | 67 |
| Architecte joué (Plan d'urgence) | 99 | 21 % | 25 % | ≈ -4 pts | 70 | 67 |
| Contremaître joué (Cadence) | 77 | 18 % | 26 % | ≈ -7 pts | 62 | 68 |
| Marchand joué (Négoce) | 8 | 13 % | 25 % | ≈ -12 pts | 52 | 68 |

### Effet immédiat des cartes sur la réputation gagnée

Réputation gagnée le jour où la carte est jouée, comparée à la veille. La réputation monte naturellement chaque jour : à comparer d'une carte à l'autre plutôt qu'à zéro. « Tard » : à partir du jour 8.

| Carte | Coût | Jouée | Gain du jour | Veille | Écart | Tard : gain | Tard : veille | Tard : écart |
|---|---|---|---|---|---|---|---|---|
| Animateur joué (Grand spectacle) | — | 177 | 9.7 | 4.5 | +5.2 | 10.0 | 4.8 | +5.2 (148) |
| Vendeur de souvenirs joué (Braderie) | — | 190 | 12.1 | 9.6 | +2.5 | 12.1 | 9.7 | +2.4 (186) |
| Portes ouvertes | 10 | 398 | 10.8 | 8.5 | +2.3 | 11.2 | 8.9 | +2.2 (368) |
| Recrutement express | 4 | 356 | 8.7 | 6.9 | +1.8 | 10.4 | 8.4 | +1.9 (285) |
| Formation express | 8 | 382 | 8.7 | 7.1 | +1.6 | 9.8 | 8.0 | +1.8 (333) |
| Prime | 4 | 418 | 7.8 | 6.5 | +1.3 | 9.0 | 7.7 | +1.4 (348) |
| DRH joué (Mutation) | — | 282 | 2.7 | 2.3 | +0.5 | 6.7 | 5.9 | +0.8 (95) |
| Formateur joué (Cours du soir) | — | 134 | 3.6 | 3.1 | +0.5 | 5.9 | 5.2 | +0.7 (75) |
| Rupture de contrat | 3 | 387 | 7.0 | 6.5 | +0.4 | 8.2 | 7.7 | +0.5 (319) |
| Contremaître joué (Cadence) | — | 256 | 2.4 | 2.3 | +0.2 | 5.6 | 5.5 | +0.1 (91) |
| Lobbyiste joué (Coup de fil) | — | 178 | 6.0 | 5.8 | +0.1 | 7.8 | 7.7 | +0.1 (129) |
| Livraison | 6 | 393 | 7.4 | 7.3 | +0.0 | 8.5 | 8.5 | +0.0 (330) |
| Heures sup | 8 | 450 | 7.3 | 7.2 | +0.1 | 8.6 | 8.6 | +0.0 (374) |
| Marchand joué (Négoce) | — | 9 | 1.2 | 1.8 | -0.6 | 1.2 | 1.8 | -0.6 (9) |
| Promotion | 8 | 393 | 6.9 | 7.3 | -0.4 | 7.8 | 8.4 | -0.6 (339) |
| Architecte joué (Plan d'urgence) | — | 247 | 6.6 | 7.2 | -0.6 | 8.1 | 8.8 | -0.7 (198) |

## Animaux

Taux d'achat : achats par nuit passée au marché. Un rare est naturellement moins acheté : il coûte très cher.

| Espèce | Continent | Rareté | Nuits au marché | Achats | Taux d'achat | Jour moyen d'achat | Installée | Victoires avec | Écart |
|---|---|---|---|---|---|---|---|---|---|
| Messager sagittaire | Afrique | Commun | 257 | 111 | 43 % | 6.8 | 70 | 36 % | +12 pts |
| Cerf élaphe | Europe | Commun | 281 | 112 | 40 % | 6.5 | 75 | 37 % | +14 pts |
| Mésange charbonnière | Europe | Commun | 275 | 100 | 36 % | 7.1 | 62 | 34 % | +10 pts |
| Salamandre géante | Asie | Commun | 370 | 114 | 31 % | 6.6 | 54 | 33 % | +9 pts |
| Yak | Asie | Commun | 340 | 99 | 29 % | 7.3 | 46 | 39 % | +15 pts |
| Tapir de Baird | Amérique | Commun | 343 | 95 | 28 % | 6.8 | 49 | 37 % | +13 pts |
| Grue du Japon | Asie | Commun | 396 | 109 | 28 % | 6.3 | 52 | 25 % | +0 pts |
| Bouquetin des Alpes | Europe | Commun | 359 | 98 | 27 % | 6.3 | 52 | 27 % | +2 pts |
| Carpe koï | Asie | Commun | 350 | 93 | 27 % | 7.0 | 45 | 22 % | -3 pts |
| Grue couronnée | Afrique | Commun | 430 | 109 | 25 % | 6.7 | 51 | 33 % | +9 pts |
| Bison d'Amérique | Amérique | Commun | 438 | 110 | 25 % | 7.5 | 63 | 37 % | +13 pts |
| Capybara | Amérique | Peu commun | 97 | 22 | 23 % | 8.5 | 5 | 40 % | +15 pts |
| Faucon pèlerin | Europe | Commun | 394 | 87 | 22 % | 6.8 | 46 | 28 % | +4 pts |
| Ara rouge | Amérique | Commun | 461 | 101 | 22 % | 7.1 | 43 | 51 % | +28 pts |
| Hyène tachetée | Afrique | Commun | 438 | 92 | 21 % | 7.0 | 56 | 38 % | +14 pts |
| Calao bicorne | Asie | Commun | 499 | 89 | 18 % | 7.7 | 31 | 35 % | +11 pts |
| Loutre d'Europe | Europe | Peu commun | 175 | 29 | 17 % | 9.7 | 9 | 33 % | +9 pts |
| Loutre à joues blanches | Afrique | Commun | 523 | 84 | 16 % | 7.8 | 29 | 45 % | +21 pts |
| Lynx boréal | Europe | Peu commun | 138 | 22 | 16 % | 8.7 | 4 | 25 % | +0 pts |
| Phoque gris | Europe | Commun | 451 | 68 | 15 % | 7.9 | 21 | 48 % | +24 pts |
| Zèbre | Afrique | Commun | 640 | 93 | 15 % | 8.6 | 43 | 40 % | +16 pts |
| Paon bleu | Asie | Peu commun | 147 | 21 | 14 % | 9.3 | 5 | 20 % | -5 pts |
| Girafe | Afrique | Peu commun | 139 | 19 | 14 % | 9.2 | 3 | 33 % | +9 pts |
| Puma | Amérique | Peu commun | 202 | 27 | 13 % | 10.1 | 2 | 50 % | +25 pts |
| Loutre cendrée | Asie | Peu commun | 251 | 31 | 12 % | 10.0 | 6 | 67 % | +42 pts |
| Ocelot | Amérique | Commun | 570 | 64 | 11 % | 7.5 | 34 | 38 % | +14 pts |
| Manchot du Cap | Afrique | Peu commun | 223 | 25 | 11 % | 10.5 | 2 | 0 % | -25 pts |
| Loup gris | Europe | Peu commun | 227 | 24 | 11 % | 9.0 | 3 | 67 % | +42 pts |
| Jaguar | Amérique | Peu commun | 235 | 23 | 10 % | 10.3 | 1 | 100 % | +75 pts |
| Guépard | Afrique | Peu commun | 241 | 23 | 10 % | 10.3 | 5 | 20 % | -5 pts |
| Alligator américain | Amérique | Peu commun | 223 | 19 | 9 % | 10.5 | 3 | 33 % | +9 pts |
| Léopard des neiges | Asie | Peu commun | 307 | 25 | 8 % | 10.6 | 3 | 0 % | -25 pts |
| Tigre du Bengale | Asie | Rare | 301 | 5 | 2 % | 13.4 | 0 | 0 % | -25 pts |
| Bison d'Europe | Europe | Rare | 332 | 5 | 2 % | 11.6 | 1 | 100 % | +75 pts |
| Hippopotame | Afrique | Rare | 473 | 5 | 1 % | 12.0 | 0 | 0 % | -25 pts |
| Panda géant | Asie | Rare | 286 | 3 | 1 % | 11.3 | 1 | 100 % | +75 pts |
| Aigle royal | Europe | Rare | 289 | 3 | 1 % | 12.3 | 0 | 0 % | -25 pts |
| Dauphin rose de l'Amazone | Amérique | Rare | 389 | 4 | 1 % | 13.3 | 0 | 0 % | -25 pts |
| Pygargue à tête blanche | Amérique | Rare | 205 | 2 | 1 % | 10.0 | 1 | 0 % | -25 pts |
| Lion | Afrique | Rare | 330 | 2 | 1 % | 11.5 | 0 | 0 % | -25 pts |

## Continents

Selon le nombre d'espèces de ce continent en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Asie (3 espèces et plus) | 1 | 100 % | 25 % | +75 pts | 104 | 67 |
| Amerique (3 espèces et plus) | 1 | 100 % | 25 % | +75 pts | 118 | 67 |
| Afrique (3 espèces et plus) | 3 | 67 % | 25 % | ≈ +42 pts | 103 | 67 |
| Amerique (1 ou 2 espèces) | 176 | 38 % | 20 % | +18 pts | 81 | 63 |
| Afrique (1 ou 2 espèces) | 224 | 33 % | 21 % | +12 pts | 78 | 62 |
| Europe (1 ou 2 espèces) | 242 | 32 % | 20 % | +12 pts | 76 | 63 |
| Asie (1 ou 2 espèces) | 215 | 28 % | 23 % | ≈ +5 pts | 78 | 63 |
| Europe (3 espèces et plus) | 1 | 0 % | 25 % | ≈ -25 pts | 93 | 67 |

## D'où vient la réputation

- frequentation : 61 %
- legendaires : 7 %
- prestige : 7 %
- spectacles : 25 %
- labels : 0 %
