# Étude du jeu par l'IA qui apprend

300 parties sur 300 jouées, 41 min de calcul. Fin de partie en moyenne au jour 15.2.
Record : victoire au jour 11 (102 de réputation, graine 938712846).

**Comment lire les tableaux** : « Victoires avec » est le taux de victoire des joueurs qui avaient cet élément en fin de partie, « sans » celui des autres. Un écart positif veut dire que l'élément accompagne la victoire, sans le prouver : un joueur qui gagne a aussi plus d'ouvriers, de bâtiments et d'animaux. « ≈ » signale un écart trop faible pour conclure, compte tenu du nombre de parties.

## En bref : forts et faibles

Écart de victoires en points, seulement quand il est significatif, et hors éléments presque absents ou présents chez presque tous. Les bâtiments et les améliorations communes sont faussés : un joueur qui dure en a davantage.

- **Traits** : forts : Polyvalent (+6), Rapide (+6) ; faibles : Lent (-6).
- **Métiers** : forts : Lobbyiste (+15), Vendeur de souvenirs (+12), Paysagiste (+11), Cantonnier (+7), Contremaître (+7) ; faibles : Formateur (-11), Animalier (-6).
- **Améliorations** : forts : Visionnaire (+7) ; faibles : Pédagogue (-14).
- **Cartes** : forts : Vendeur de souvenirs joué (Braderie) (+22), Portes ouvertes (+12), Lobbyiste joué (Coup de fil) (+12), Prime (+11), Livraison (+8) ; faibles : aucun net.
- **Animaux** : forts : Paon bleu (+35), Guépard (+34), Lynx boréal (+27), Loutre d'Europe (+20), Hyène tachetée (+19) ; faibles : aucun net.
- **Bâtiments** : forts : Cuisine des animaux (+28), Grand arbre (+26), Local d'entretien (+25), Kiosque d'animation (+22), Camp niveau 3 (+21) ; faibles : aucun net.

## Classement des stratégies (phase finale)

| Stratégie | Parties | Victoires | Jour moyen de victoire | Réputation moyenne |
|---|---|---|---|---|
| Apprise 1 | 6 | 67 % | 13.8 | 86 |
| Rush or | 7 | 57 % | 14.0 | 87 |
| Camp amélioré | 7 | 57 % | 13.8 | 91 |
| Affinités | 7 | 57 % | 13.8 | 101 |
| Lobbying | 7 | 57 % | 16.3 | 95 |
| Équilibrée | 7 | 29 % | 14.0 | 84 |
| Marché | 7 | 29 % | 13.5 | 75 |
| Apprise 3 | 7 | 29 % | 14.5 | 89 |
| Grand camp | 7 | 29 % | 16.0 | 69 |
| Cartes | 7 | 29 % | 14.0 | 79 |
| Petits contrats | 7 | 29 % | 12.0 | 71 |
| Apprise 4 | 7 | 14 % | 14.0 | 58 |
| Grand parc | 7 | 14 % | 13.0 | 70 |
| Haut de gamme | 7 | 14 % | 14.0 | 62 |
| Formation | 7 | 14 % | 16.0 | 54 |
| Parc évolutif | 7 | 0 % | — | 41 |
| Spectacle | 6 | 0 % | — | 72 |
| Spécialisation | 6 | 0 % | — | 21 |
| Apprise 2 | 7 | 0 % | — | 78 |
| Fast expand | 7 | 0 % | — | 39 |
| Rush or + route | 7 | 0 % | — | 47 |

## Stratégies apprises

| Génération | Victoires de la meilleure | Jour moyen | Réputation | Moyenne de la population |
|---|---|---|---|---|
| 1 | 67 % | 15.8 | 95 | 25 % |
| 2 | 83 % | 15.0 | 99 | 24 % |
| 3 | 33 % | 15.0 | 90 | 25 % |
| 4 | 67 % | 14.5 | 104 | 25 % |
| 5 | 67 % | 15.0 | 103 | 25 % |
| 6 | 83 % | 14.8 | 95 | 25 % |
| 7 | 83 % | 15.8 | 111 | 25 % |
| 8 | 67 % | 15.3 | 95 | 25 % |
| 9 | 67 % | 13.5 | 99 | 24 % |
| 10 | 83 % | 17.4 | 95 | 25 % |
| 11 | 67 % | 16.0 | 93 | 25 % |

1. parc grand, palier 2.4, réserve 22, lobby 1, camp 1, contrats 4, rush_or
2. parc moyen, palier 2.4, réserve 17, lobby 2, camp 1, contrats 3, rush_or, cartes, spectacle
3. parc moyen, palier 2.7, réserve 6, lobby 3, camp 2, contrats 4, rush_or
4. parc moyen, palier 2.4, réserve 28, lobby 1, camp 2, contrats 4

Réglages retenus par les 8 meilleures : marche 0/8, rush_or 6/8, formation 1/8, cartes 1/8, spectacle 1/8, affinite 0/8, boutique 8/8, mine 7/8, specialisation 0/8, fast_expand 0/8, route_mine 1/8.

**Métiers, des plus recherchés aux plus évités par les IA qui gagnent** : Guichetier +0.4, Contremaître +0.3, Porteur +0.3, Architecte +0.2, Cantonnier +0.2, Animalier +0.2, Animateur +0.2, Formateur +0.1, Maçon +0.0, DRH +0.0, Mineur +0.0, Apprenti +0.0, Agent d'entretien +0.0, Manœuvre +0.0, Terrassier -0.0, Vendeur de souvenirs -0.0, Paysagiste -0.0, Lobbyiste -0.1, Charpentier -0.2, Marchand -0.2, Soigneur -0.2, Bûcheron -0.2.

**Traits, des plus recherchés aux plus évités par les IA qui gagnent** : Costaud +0.3, Rapide +0.3, Bon élève +0.3, Maladroit +0.2, Matinal +0.1, Rabat-joie +0.1, Gourmand +0.1, Débrouillard +0.0, Casanier +0.0, Col blanc +0.0, Têtu -0.0, Économe -0.1, Peureux -0.2, Distrait -0.2, Paresseux -0.2, Naturaliste -0.4, Polyvalent -0.5, Endurant -0.5, Lent -0.6, Charismatique -0.6.

**Animaux, des plus recherchés aux plus évités par les IA qui gagnent** : Phoque gris +0.7, Tapir de Baird +0.4, Loutre à joues blanches +0.4, Dauphin rose de l'Amazone +0.3, Guépard +0.2, Loutre d'Europe +0.2, Paon bleu +0.2, Messager sagittaire +0.2, Manchot du Cap +0.2, Carpe koï +0.2, Calao bicorne +0.2, Capybara +0.1, Grue couronnée +0.1, Grue du Japon +0.1, Girafe +0.1, Hyène tachetée +0.1, Bison d'Europe +0.1, Mésange charbonnière +0.0, Lynx boréal +0.0, Pygargue à tête blanche +0.0, Ara rouge +0.0, Yak +0.0, Faucon pèlerin +0.0, Loutre cendrée +0.0, Loup gris +0.0, Zèbre +0.0, Alligator américain -0.0, Bouquetin des Alpes -0.0, Tigre du Bengale -0.1, Puma -0.1, Panda géant -0.1, Jaguar -0.2, Salamandre géante -0.2, Lion -0.2, Bison d'Amérique -0.2, Léopard des neiges -0.2, Ocelot -0.2, Hippopotame -0.2, Cerf élaphe -0.3, Aigle royal -1.1.

**Cartes, des plus recherchés aux plus évités par les IA qui gagnent** : Rupture de contrat +0.6, Promotion +0.4, Prime +0.1, Portes ouvertes +0.1, Recrutement express -0.0, Formation express -0.4, Livraison -0.4, Heures sup -0.4.

**Améliorations, des plus recherchés aux plus évités par les IA qui gagnent** : Négociateur +0.5, Brouette +0.4, Pied léger +0.2, Seconde spécialité +0.2, Remise en question +0.2, Chasseur de têtes +0.2, Fidélité +0.1, Révélation +0.1, Visionnaire +0.0, Maîtrise +0.0, Réseau -0.0, Scie affûtée -0.0, Expérience -0.1, Pédagogue -0.7.

## Traits des ouvriers

Joueurs ayant au moins un ouvrier avec ce trait. Défauts et qualités sont tirés au draft, mais l'IA choisit ses cartes : les traits les plus visibles sont en partie évités.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Col blanc | 106 | 31 % | 24 % | ≈ +7 pts | 76 | 67 |
| Polyvalent | 750 | 27 % | 21 % | +6 pts | 71 | 62 |
| Rapide | 749 | 27 % | 21 % | +6 pts | 71 | 62 |
| Bon élève | 746 | 27 % | 22 % | ≈ +5 pts | 70 | 64 |
| Costaud | 781 | 27 % | 22 % | ≈ +5 pts | 70 | 64 |
| Économe | 778 | 26 % | 22 % | ≈ +4 pts | 69 | 65 |
| Endurant | 743 | 26 % | 23 % | ≈ +4 pts | 69 | 65 |
| Débrouillard | 783 | 26 % | 23 % | ≈ +4 pts | 70 | 63 |
| Gourmand | 447 | 26 % | 24 % | ≈ +1 pts | 68 | 68 |
| Charismatique | 721 | 25 % | 24 % | ≈ +1 pts | 69 | 66 |
| Têtu | 525 | 25 % | 24 % | ≈ +1 pts | 66 | 69 |
| Naturaliste | 760 | 25 % | 25 % | ≈ +0 pts | 68 | 67 |
| Matinal | 777 | 25 % | 25 % | ≈ +0 pts | 69 | 65 |
| Distrait | 499 | 24 % | 25 % | ≈ -1 pts | 68 | 68 |
| Casanier | 485 | 24 % | 25 % | ≈ -2 pts | 68 | 68 |
| Maladroit | 468 | 24 % | 26 % | ≈ -2 pts | 65 | 69 |
| Rabat-joie | 474 | 23 % | 26 % | ≈ -3 pts | 64 | 70 |
| Paresseux | 504 | 23 % | 26 % | ≈ -4 pts | 64 | 70 |
| Peureux | 455 | 22 % | 26 % | ≈ -4 pts | 63 | 71 |
| Lent | 406 | 21 % | 27 % | -6 pts | 64 | 70 |

## Métiers

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Lobbyiste | 204 | 37 % | 22 % | +15 pts | 83 | 65 |
| Vendeur de souvenirs | 212 | 34 % | 23 % | +12 pts | 75 | 66 |
| Paysagiste | 828 | 28 % | 17 % | +11 pts | 74 | 54 |
| Cantonnier | 645 | 28 % | 21 % | +7 pts | 71 | 64 |
| Contremaître | 231 | 31 % | 23 % | +7 pts | 75 | 66 |
| Charpentier | 566 | 27 % | 23 % | ≈ +4 pts | 68 | 67 |
| DRH | 203 | 28 % | 24 % | ≈ +4 pts | 73 | 67 |
| Marchand | 222 | 28 % | 24 % | ≈ +4 pts | 79 | 65 |
| Terrassier | 590 | 27 % | 23 % | ≈ +3 pts | 69 | 67 |
| Animateur | 200 | 27 % | 25 % | ≈ +2 pts | 72 | 67 |
| Bûcheron | 465 | 26 % | 24 % | ≈ +2 pts | 66 | 69 |
| Mineur | 573 | 25 % | 25 % | ≈ +1 pts | 70 | 65 |
| Soigneur | 576 | 25 % | 25 % | ≈ +0 pts | 68 | 68 |
| Guichetier | 556 | 25 % | 25 % | ≈ +0 pts | 66 | 69 |
| Architecte | 200 | 25 % | 25 % | ≈ +0 pts | 67 | 68 |
| Maçon | 527 | 24 % | 25 % | ≈ -1 pts | 67 | 68 |
| Agent d'entretien | 497 | 23 % | 26 % | ≈ -3 pts | 65 | 70 |
| Porteur | 549 | 23 % | 26 % | ≈ -3 pts | 67 | 69 |
| Animalier | 572 | 22 % | 28 % | -6 pts | 65 | 70 |
| Apprenti | 21 | 19 % | 25 % | ≈ -6 pts | 65 | 68 |
| Formateur | 113 | 15 % | 26 % | -11 pts | 62 | 68 |
| Manœuvre | 18 | 6 % | 25 % | -20 pts | 42 | 68 |

## Améliorations

Choisies 25 % du temps au hasard pendant l'apprentissage, pour que toutes soient essayées.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Maîtrise | 1197 | 25 % | 0 % | ≈ +25 pts | 68 | 22 |
| Devenir Terrassier | 62 | 35 % | 24 % | ≈ +11 pts | 81 | 67 |
| Réseau | 95 | 34 % | 24 % | ≈ +10 pts | 82 | 66 |
| Visionnaire | 343 | 30 % | 23 % | +7 pts | 76 | 65 |
| Pied léger | 1044 | 25 % | 21 % | ≈ +5 pts | 68 | 63 |
| Devenir Maçon | 72 | 29 % | 25 % | ≈ +5 pts | 72 | 67 |
| Chasseur de têtes | 59 | 29 % | 25 % | ≈ +4 pts | 71 | 68 |
| Seconde spécialité : Construction en pierre | 354 | 28 % | 24 % | ≈ +4 pts | 72 | 66 |
| Seconde spécialité : Construction en bois | 298 | 28 % | 24 % | ≈ +4 pts | 68 | 68 |
| Devenir Porteur | 72 | 28 % | 25 % | ≈ +3 pts | 71 | 68 |
| Seconde spécialité : Guichet | 326 | 27 % | 24 % | ≈ +3 pts | 69 | 67 |
| Seconde spécialité : Extraction de pierre | 307 | 27 % | 24 % | ≈ +3 pts | 71 | 67 |
| Devenir Mineur | 70 | 27 % | 25 % | ≈ +2 pts | 75 | 67 |
| Fidélité | 980 | 25 % | 23 % | ≈ +2 pts | 68 | 65 |
| Devenir Cantonnier | 97 | 26 % | 25 % | ≈ +1 pts | 65 | 68 |
| Scie affûtée | 215 | 25 % | 25 % | ≈ +0 pts | 67 | 68 |
| Expérience | 973 | 25 % | 25 % | ≈ +0 pts | 68 | 67 |
| Remise en question | 1196 | 25 % | 25 % | ≈ +0 pts | 68 | 57 |
| Seconde spécialité : Clôtures d'enclos | 286 | 24 % | 25 % | ≈ +0 pts | 71 | 67 |
| Seconde spécialité : Extraction de bois | 343 | 24 % | 25 % | ≈ +0 pts | 70 | 67 |
| Devenir Guichetier | 67 | 24 % | 25 % | ≈ -1 pts | 71 | 68 |
| Brouette | 276 | 24 % | 25 % | ≈ -1 pts | 69 | 67 |
| Devenir Bûcheron | 76 | 24 % | 25 % | ≈ -1 pts | 67 | 68 |
| Révélation | 1000 | 25 % | 26 % | ≈ -1 pts | 68 | 67 |
| Seconde spécialité : Routes | 303 | 23 % | 25 % | ≈ -2 pts | 67 | 68 |
| Devenir Agent d'entretien | 54 | 22 % | 25 % | ≈ -3 pts | 63 | 68 |
| Devenir Charpentier | 82 | 22 % | 25 % | ≈ -3 pts | 61 | 68 |
| Négociateur | 82 | 21 % | 25 % | ≈ -4 pts | 77 | 67 |
| Devenir Paysagiste | 92 | 21 % | 25 % | ≈ -5 pts | 66 | 68 |
| Devenir Animalier | 142 | 20 % | 25 % | ≈ -5 pts | 62 | 69 |
| Devenir Soigneur | 91 | 20 % | 25 % | ≈ -5 pts | 62 | 68 |
| Pédagogue | 26 | 12 % | 25 % | -14 pts | 56 | 68 |

## Bâtiments

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Cuisine des animaux | 1046 | 28 % | 0 % | +28 pts | 75 | 15 |
| Grand arbre | 110 | 48 % | 22 % | +26 pts | 91 | 65 |
| Entrée du zoo | 1183 | 25 % | 0 % | +25 pts | 68 | 17 |
| Local d'entretien | 980 | 29 % | 5 % | +25 pts | 77 | 26 |
| Kiosque d'animation | 770 | 33 % | 11 % | +22 pts | 82 | 43 |
| Camp niveau 3 | 396 | 39 % | 18 % | +21 pts | 87 | 58 |
| Rocher d'observation | 137 | 42 % | 23 % | +19 pts | 86 | 65 |
| Abri chauffé | 26 | 42 % | 24 % | ≈ +18 pts | 90 | 67 |
| Camp niveau 2 | 837 | 30 % | 13 % | +16 pts | 76 | 49 |
| Bassin profond | 49 | 39 % | 24 % | +15 pts | 85 | 67 |
| Boutique de souvenirs | 644 | 31 % | 18 % | +13 pts | 78 | 56 |
| Maison du personnel | 1103 | 26 % | 14 % | +11 pts | 69 | 53 |
| Mine d'or | 858 | 26 % | 21 % | ≈ +5 pts | 72 | 57 |
| Marché | 584 | 25 % | 24 % | ≈ +1 pts | 73 | 62 |
| Entrepôt | 733 | 24 % | 25 % | ≈ -1 pts | 69 | 66 |
| Centre de formation | 231 | 22 % | 26 % | ≈ -4 pts | 63 | 69 |

## Labels

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| excellence | 7 | 43 % | 25 % | ≈ +18 pts | 77 | 68 |
| mecenat | 14 | 29 % | 25 % | ≈ +4 pts | 70 | 68 |
| certifie | 62 | 21 % | 25 % | ≈ -4 pts | 71 | 68 |

## Cartes à usage unique et cadres joués

Joueurs ayant joué cette carte au moins une fois.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Vendeur de souvenirs joué (Braderie) | 125 | 45 % | 23 % | +22 pts | 87 | 66 |
| Portes ouvertes | 452 | 33 % | 20 % | +12 pts | 82 | 59 |
| Lobbyiste joué (Coup de fil) | 135 | 36 % | 23 % | +12 pts | 82 | 66 |
| Prime | 497 | 31 % | 20 % | +11 pts | 77 | 61 |
| Livraison | 446 | 30 % | 22 % | +8 pts | 74 | 64 |
| Animateur joué (Grand spectacle) | 145 | 31 % | 24 % | ≈ +7 pts | 80 | 66 |
| Rupture de contrat | 539 | 29 % | 22 % | +7 pts | 73 | 63 |
| Recrutement express | 490 | 29 % | 22 % | +6 pts | 74 | 63 |
| Heures sup | 492 | 28 % | 22 % | +6 pts | 75 | 63 |
| Architecte joué (Plan d'urgence) | 131 | 27 % | 25 % | ≈ +2 pts | 71 | 67 |
| Promotion | 466 | 26 % | 24 % | ≈ +2 pts | 73 | 64 |
| DRH joué (Mutation) | 167 | 26 % | 25 % | ≈ +2 pts | 72 | 67 |
| Formation express | 435 | 24 % | 25 % | ≈ -1 pts | 71 | 66 |
| Contremaître joué (Cadence) | 139 | 24 % | 25 % | ≈ -1 pts | 68 | 68 |
| Marchand joué (Négoce) | 18 | 22 % | 25 % | ≈ -3 pts | 67 | 68 |
| Formateur joué (Cours du soir) | 47 | 15 % | 25 % | ≈ -10 pts | 64 | 68 |

### Effet immédiat des cartes sur la réputation gagnée

Réputation gagnée le jour où la carte est jouée, comparée à la veille. La réputation monte naturellement chaque jour : à comparer d'une carte à l'autre plutôt qu'à zéro. « Tard » : à partir du jour 8.

| Carte | Coût | Jouée | Gain du jour | Veille | Écart | Tard : gain | Tard : veille | Tard : écart |
|---|---|---|---|---|---|---|---|---|
| Vendeur de souvenirs joué (Braderie) | — | 310 | 15.4 | 8.6 | +6.8 | 15.5 | 8.7 | +6.8 (303) |
| Animateur joué (Grand spectacle) | — | 385 | 9.1 | 5.0 | +4.1 | 9.5 | 5.6 | +4.0 (312) |
| Portes ouvertes | 10 | 656 | 10.7 | 8.1 | +2.6 | 11.2 | 8.6 | +2.6 (596) |
| Formation express | 8 | 552 | 8.2 | 6.1 | +2.1 | 9.3 | 6.9 | +2.4 (472) |
| Recrutement express | 4 | 668 | 7.6 | 6.0 | +1.6 | 9.5 | 7.6 | +2.0 (504) |
| Prime | 4 | 764 | 7.4 | 6.3 | +1.1 | 9.0 | 7.8 | +1.2 (588) |
| Formateur joué (Cours du soir) | — | 161 | 5.1 | 4.2 | +0.9 | 6.4 | 5.1 | +1.2 (120) |
| Marchand joué (Négoce) | — | 21 | 4.5 | 3.7 | +0.8 | 4.9 | 3.9 | +0.9 (18) |
| Rupture de contrat | 3 | 798 | 6.5 | 5.8 | +0.7 | 8.3 | 7.4 | +0.8 (587) |
| Lobbyiste joué (Coup de fil) | — | 269 | 6.9 | 6.1 | +0.7 | 8.3 | 7.6 | +0.7 (191) |
| Livraison | 6 | 607 | 6.7 | 6.0 | +0.7 | 7.9 | 7.2 | +0.7 (489) |
| Contremaître joué (Cadence) | — | 400 | 3.3 | 2.9 | +0.4 | 6.8 | 6.2 | +0.6 (160) |
| Promotion | 8 | 651 | 6.7 | 6.3 | +0.4 | 7.8 | 7.4 | +0.4 (524) |
| Heures sup | 8 | 746 | 7.0 | 6.6 | +0.3 | 8.1 | 7.8 | +0.3 (604) |
| DRH joué (Mutation) | — | 420 | 3.6 | 3.3 | +0.3 | 9.1 | 8.8 | +0.3 (131) |
| Architecte joué (Plan d'urgence) | — | 287 | 6.1 | 6.7 | -0.5 | 8.1 | 8.8 | -0.7 (206) |

## Animaux

Taux d'achat : achats par nuit passée au marché. Un rare est naturellement moins acheté : il coûte très cher.

| Espèce | Continent | Rareté | Nuits au marché | Achats | Taux d'achat | Jour moyen d'achat | Installée | Victoires avec | Écart |
|---|---|---|---|---|---|---|---|---|---|
| Mésange charbonnière | Europe | Commun | 507 | 206 | 41 % | 6.9 | 155 | 34 % | +11 pts |
| Messager sagittaire | Afrique | Commun | 533 | 190 | 36 % | 7.2 | 139 | 34 % | +10 pts |
| Bouquetin des Alpes | Europe | Commun | 577 | 181 | 31 % | 7.2 | 117 | 33 % | +9 pts |
| Cerf élaphe | Europe | Commun | 660 | 206 | 31 % | 7.2 | 155 | 35 % | +11 pts |
| Grue couronnée | Afrique | Commun | 629 | 189 | 30 % | 7.1 | 113 | 30 % | +6 pts |
| Tapir de Baird | Amérique | Commun | 637 | 191 | 30 % | 7.5 | 119 | 38 % | +14 pts |
| Faucon pèlerin | Europe | Commun | 668 | 180 | 27 % | 7.5 | 111 | 34 % | +10 pts |
| Yak | Asie | Commun | 626 | 162 | 26 % | 7.3 | 125 | 40 % | +17 pts |
| Grue du Japon | Asie | Commun | 658 | 164 | 25 % | 6.2 | 108 | 31 % | +7 pts |
| Hyène tachetée | Afrique | Commun | 663 | 161 | 24 % | 8.0 | 104 | 42 % | +19 pts |
| Carpe koï | Asie | Commun | 714 | 172 | 24 % | 7.2 | 98 | 29 % | +4 pts |
| Salamandre géante | Asie | Commun | 661 | 157 | 24 % | 7.0 | 93 | 34 % | +10 pts |
| Paon bleu | Asie | Peu commun | 338 | 73 | 22 % | 8.6 | 41 | 59 % | +35 pts |
| Bison d'Amérique | Amérique | Commun | 764 | 165 | 22 % | 8.4 | 119 | 34 % | +11 pts |
| Capybara | Amérique | Peu commun | 225 | 46 | 20 % | 7.2 | 28 | 36 % | +11 pts |
| Phoque gris | Europe | Commun | 847 | 163 | 19 % | 7.8 | 96 | 36 % | +13 pts |
| Lynx boréal | Europe | Peu commun | 314 | 60 | 19 % | 7.0 | 35 | 51 % | +27 pts |
| Ara rouge | Amérique | Commun | 827 | 155 | 19 % | 8.1 | 86 | 34 % | +10 pts |
| Calao bicorne | Asie | Commun | 887 | 160 | 18 % | 8.3 | 85 | 33 % | +9 pts |
| Ocelot | Amérique | Commun | 918 | 149 | 16 % | 8.4 | 99 | 34 % | +10 pts |
| Zèbre | Afrique | Commun | 943 | 152 | 16 % | 8.9 | 99 | 30 % | +6 pts |
| Loutre d'Europe | Europe | Peu commun | 352 | 56 | 16 % | 7.9 | 25 | 44 % | +20 pts |
| Loutre à joues blanches | Afrique | Commun | 955 | 144 | 15 % | 7.8 | 87 | 33 % | +9 pts |
| Manchot du Cap | Afrique | Peu commun | 349 | 49 | 14 % | 7.1 | 27 | 41 % | +16 pts |
| Guépard | Afrique | Peu commun | 328 | 45 | 14 % | 8.2 | 31 | 58 % | +34 pts |
| Girafe | Afrique | Peu commun | 334 | 41 | 12 % | 7.8 | 20 | 55 % | +31 pts |
| Loup gris | Europe | Peu commun | 403 | 49 | 12 % | 7.2 | 23 | 35 % | +10 pts |
| Alligator américain | Amérique | Peu commun | 298 | 36 | 12 % | 7.0 | 21 | 38 % | +13 pts |
| Loutre cendrée | Asie | Peu commun | 334 | 39 | 12 % | 7.5 | 20 | 50 % | +26 pts |
| Puma | Amérique | Peu commun | 398 | 35 | 9 % | 8.1 | 24 | 42 % | +17 pts |
| Jaguar | Amérique | Peu commun | 409 | 35 | 9 % | 9.4 | 15 | 67 % | +42 pts |
| Léopard des neiges | Asie | Peu commun | 476 | 31 | 7 % | 8.8 | 9 | 56 % | +31 pts |
| Pygargue à tête blanche | Amérique | Rare | 517 | 15 | 3 % | 11.4 | 3 | 33 % | +9 pts |
| Lion | Afrique | Rare | 504 | 14 | 3 % | 11.2 | 6 | 33 % | +9 pts |
| Tigre du Bengale | Asie | Rare | 557 | 13 | 2 % | 10.8 | 3 | 33 % | +9 pts |
| Hippopotame | Afrique | Rare | 517 | 10 | 2 % | 12.2 | 2 | 50 % | +25 pts |
| Bison d'Europe | Europe | Rare | 521 | 9 | 2 % | 11.8 | 3 | 100 % | +75 pts |
| Panda géant | Asie | Rare | 742 | 12 | 2 % | 11.9 | 5 | 40 % | +15 pts |
| Aigle royal | Europe | Rare | 704 | 9 | 1 % | 11.4 | 6 | 33 % | +9 pts |
| Dauphin rose de l'Amazone | Amérique | Rare | 496 | 6 | 1 % | 11.5 | 3 | 33 % | +9 pts |

## Continents

Selon le nombre d'espèces de ce continent en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Europe (3 espèces et plus) | 21 | 67 % | 24 % | +43 pts | 104 | 67 |
| Asie (3 espèces et plus) | 15 | 60 % | 24 % | +36 pts | 98 | 67 |
| Amerique (1 ou 2 espèces) | 417 | 35 % | 19 % | +16 pts | 83 | 60 |
| Afrique (1 ou 2 espèces) | 470 | 34 % | 19 % | +15 pts | 81 | 59 |
| Amerique (3 espèces et plus) | 8 | 38 % | 25 % | ≈ +13 pts | 99 | 68 |
| Asie (1 ou 2 espèces) | 457 | 32 % | 20 % | +12 pts | 78 | 61 |
| Europe (1 ou 2 espèces) | 555 | 31 % | 19 % | +12 pts | 77 | 60 |
| Afrique (3 espèces et plus) | 18 | 33 % | 25 % | ≈ +9 pts | 92 | 67 |

## D'où vient la réputation

- frequentation : 66 %
- legendaires : 5 %
- prestige : 19 %
- spectacles : 9 %
- labels : 1 %
