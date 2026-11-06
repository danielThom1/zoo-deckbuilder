# Étude du jeu par l'IA qui apprend

914 parties sur 914 jouées, 139 min de calcul. Fin de partie en moyenne au jour 12.9.
Record : victoire au jour 8 (106 de réputation, graine 23315607).
IA bloquées : 33 joueurs sur 3656 finissent à 0 de réputation, 72 sans aucun animal.

**Comment lire les tableaux** : « Victoires avec » est le taux de victoire des joueurs qui avaient cet élément en fin de partie, « sans » celui des autres. Un écart positif veut dire que l'élément accompagne la victoire, sans le prouver : un joueur qui gagne a aussi plus d'ouvriers, de bâtiments et d'animaux. « ≈ » signale un écart trop faible pour conclure, compte tenu du nombre de parties.

## En bref : forts et faibles

Écart de victoires en points, seulement quand il est significatif, et hors éléments presque absents ou présents chez presque tous. Les bâtiments et les améliorations communes sont faussés : un joueur qui dure en a davantage.

- **Traits** : forts : Col blanc (+6), Polyvalent (+5), Charismatique (+4), Débrouillard (+4), Costaud (+4) ; faibles : Peureux (-5), Lent (-3), Gourmand (-3).
- **Métiers** : forts : Animateur (+10), Vendeur de souvenirs (+10), Marchand (+7), Paysagiste (+7), Lobbyiste (+7) ; faibles : Mineur (-3).
- **Améliorations** : forts : Visionnaire (+6), Expérience (+4) ; faibles : aucun net.
- **Cartes** : forts : Accusation (Journaliste) (+42), Cabinet de recrutement (+29), Agence d'intérim (+25), Article de presse (Journaliste) (+19), Recrutement express (+6) ; faibles : Journée de carte cédée (+4) (-8).
- **Animaux** : forts : Tigre du Bengale (+30), Lion (+24), Pygargue à tête blanche (+23), Bison d'Europe (+22), Dauphin rose de l'Amazone (+21) ; faibles : aucun net.
- **Bâtiments** : forts : Camp niveau 3 (+30), Cuisine des animaux (+26), Local d'entretien (+25), Camp niveau 2 (+22), Kiosque d'animation (+22) ; faibles : Mine d'or (-7), Entrepôt (-6), Marché (-4).
- **Bonus de nuit** : forts : Semaine des Amériques (Attractivité des animaux d'Amérique ×1,5) (+6), Journée de l'océan (Attractivité des animaux aquatiques ×1,5) (+6), Semaine de l'Asie (Attractivité des animaux d'Asie ×1,5) (+5) ; faibles : Carnet d'adresses (+50 % de lobbying) (-5), Lampes de mineur (+40 % d'extraction d'or) (-5), Échafaudages (+25 % de construction) (-3).

## Classement des stratégies (phase finale)

| Stratégie | Parties | Victoires | Jour moyen de victoire | Réputation moyenne |
|---|---|---|---|---|
| Apprise 3 | 6 | 67 % | 13.5 | 89 |
| Camp amélioré | 6 | 67 % | 13.5 | 101 |
| Apprise 4 | 6 | 50 % | 12.7 | 99 |
| Rush or | 6 | 50 % | 12.0 | 94 |
| Apprise 2 | 6 | 50 % | 13.3 | 105 |
| Apprise 1 | 6 | 50 % | 13.0 | 104 |
| Haut de gamme | 6 | 50 % | 13.0 | 98 |
| Europe | 6 | 33 % | 13.5 | 81 |
| Herbivores | 6 | 33 % | 12.5 | 61 |
| Aquatiques | 6 | 33 % | 12.5 | 79 |
| Même type | 6 | 33 % | 11.0 | 89 |
| Sans agrandir | 6 | 33 % | 13.0 | 87 |
| Équilibrée | 6 | 33 % | 14.5 | 92 |
| Grand parc | 6 | 33 % | 12.0 | 79 |
| Marché | 6 | 17 % | 11.0 | 81 |
| Rush or + route | 6 | 17 % | 13.0 | 70 |
| Fast expand | 6 | 17 % | 11.0 | 70 |
| Amérique | 6 | 17 % | 11.0 | 68 |
| Formateur | 6 | 17 % | 12.0 | 70 |
| Prédateurs | 6 | 17 % | 14.0 | 64 |
| Affinités | 6 | 17 % | 12.0 | 67 |
| Sans intendance | 6 | 17 % | 11.0 | 75 |
| Spectacle | 6 | 17 % | 15.0 | 95 |
| Grand camp | 6 | 17 % | 12.0 | 60 |
| Lobbying | 6 | 17 % | 14.0 | 79 |
| Cartes | 7 | 14 % | 12.0 | 51 |
| Ancienne IA | 7 | 14 % | 17.0 | 85 |
| Parc évolutif | 6 | 0 % | — | 52 |
| Aériens | 6 | 0 % | — | 54 |
| Afrique | 6 | 0 % | — | 53 |
| Asie | 6 | 0 % | — | 42 |
| Spécialisation | 6 | 0 % | — | 46 |
| Petits contrats | 6 | 0 % | — | 89 |

## Niveaux d'IA enregistrés (game/data/ia_niveaux.json)

| Niveau | Victoires en finale | Réputation moyenne | Stratégies |
|---|---|---|---|
| Facile | 0 % | 58 | Afrique, Asie, Spécialisation, Petits contrats |
| Moyen | 17 % | 72 | Marché, Rush or + route, Fast expand, Amérique |
| Difficile | 58 % | 96 | Apprise 3, Camp amélioré, Apprise 4, Rush or |

## Stratégies apprises

| Génération | Victoires de la meilleure | Ses parties | Jour moyen | Réputation | Moyenne de la population |
|---|---|---|---|---|---|
| 1 | 92 % | 12 | 13.0 | 111 | 25 % |
| 2 | 79 % | 24 | 13.2 | 104 | 27 % |
| 3 | 72 % | 36 | 13.2 | 105 | 29 % |
| 4 | 63 % | 48 | 13.1 | 100 | 29 % |
| 5 | 57 % | 60 | 13.0 | 98 | 28 % |
| 6 | 60 % | 72 | 12.9 | 98 | 27 % |
| 7 | 56 % | 84 | 12.8 | 94 | 27 % |
| 8 | 53 % | 96 | 12.8 | 94 | 28 % |
| 9 | 51 % | 108 | 12.7 | 93 | 27 % |
| 10 | 49 % | 120 | 12.7 | 93 | 29 % |
| 11 | 47 % | 132 | 12.7 | 92 | 29 % |
| 12 | 47 % | 144 | 12.6 | 92 | 27 % |
| 13 | 45 % | 156 | 12.6 | 91 | 27 % |
| 14 | 45 % | 168 | 12.6 | 91 | 25 % |
| 15 | 67 % | 12 | 13.6 | 107 | 28 % |
| 16 | 44 % | 192 | 12.6 | 90 | 26 % |
| 17 | 43 % | 204 | 12.6 | 89 | 29 % |
| 18 | 43 % | 144 | 12.0 | 88 | 26 % |

1. parc grand, palier 1.7, réserve 2, lobby 0, camp 1, contrats 2, formation, sans agrandir, herbivore, Asie
2. parc grand, palier 2.3, réserve 2, lobby 0, camp 1, contrats 4, meme_type, aquatique, Asie
3. parc grand, palier 2.3, réserve 2, lobby 0, camp 2, contrats 4, marche, rush_or, formation, herbivore, Asie
4. parc moyen, palier 2.9, réserve 2, lobby 0, camp 1, contrats 4, formation, affinite, sans adaptatif, sans agrandir, meme_type, aquatique, Asie

Réglages retenus par les 8 meilleures : marche 1/8, rush_or 3/8, formation 5/8, cartes 0/8, spectacle 0/8, affinite 2/8, boutique 7/8, mine 0/8, specialisation 0/8, fast_expand 0/8, route_mine 0/8, adaptatif 7/8, agrandir 5/8, meme_type 3/8, intendance 0/8.

**Métiers, des plus recherchés aux plus évités par les IA qui gagnent** : Manœuvre +0.4, Terrassier +0.2, Agent d'entretien +0.2, Contremaître +0.2, Mineur +0.1, Intendant de parc +0.1, Guichetier +0.1, Marchand +0.1, Porteur +0.1, Cantonnier +0.1, Animateur +0.0, Paysagiste +0.0, Animalier +0.0, Apprenti -0.0, Bûcheron -0.0, Vendeur de souvenirs -0.0, Soigneur -0.1, Charpentier -0.1, Architecte -0.1, Lobbyiste -0.2, Journaliste -0.2, Maçon -0.2, DRH -0.4, Formateur -0.5.

**Traits, des plus recherchés aux plus évités par les IA qui gagnent** : Têtu +0.2, Col blanc +0.1, Naturaliste +0.1, Matinal +0.0, Débrouillard +0.0, Paresseux +0.0, Distrait +0.0, Bon élève +0.0, Casanier -0.0, Endurant -0.0, Maladroit -0.0, Rabat-joie -0.0, Gourmand -0.0, Économe -0.0, Polyvalent -0.1, Charismatique -0.1, Costaud -0.1, Lent -0.1, Rapide -0.2, Peureux -0.6.

**Animaux, des plus recherchés aux plus évités par les IA qui gagnent** : Loutre d'Europe +0.4, Calao bicorne +0.4, Pygargue à tête blanche +0.3, Grue couronnée +0.3, Cerf élaphe +0.2, Zèbre +0.1, Messager sagittaire +0.1, Bouquetin des Alpes +0.1, Bison d'Amérique +0.1, Carpe koï +0.1, Hyène tachetée +0.0, Manchot du Cap +0.0, Loutre à joues blanches +0.0, Mésange charbonnière +0.0, Lion +0.0, Grue du Japon +0.0, Hippopotame +0.0, Tapir de Baird +0.0, Ara rouge +0.0, Capybara +0.0, Faucon pèlerin +0.0, Phoque gris +0.0, Ocelot -0.0, Léopard des neiges -0.0, Alligator américain -0.1, Paon bleu -0.1, Loup gris -0.1, Girafe -0.1, Bison d'Europe -0.1, Tigre du Bengale -0.1, Lynx boréal -0.2, Jaguar -0.2, Guépard -0.2, Puma -0.2, Panda géant -0.3, Salamandre géante -0.3, Dauphin rose de l'Amazone -0.4, Yak -0.5, Aigle royal -0.5, Loutre cendrée -0.7.

**Cartes, des plus recherchés aux plus évités par les IA qui gagnent** : Promotion +0.3, Portes ouvertes +0.1, Rupture de contrat +0.1, Livraison +0.0, Heures sup -0.0, Formation express -0.1, Prime -0.3, Recrutement express -0.7.

**Améliorations, des plus recherchés aux plus évités par les IA qui gagnent** : Scie affûtée +0.3, Visionnaire +0.3, Pédagogue +0.1, Brouette +0.1, Négociateur +0.0, Maîtrise +0.0, Seconde spécialité -0.0, Expérience -0.1, Réseau -0.1, Révélation -0.1, Chasseur de têtes -0.2, Pied léger -0.2, Fidélité -0.4, Remise en question -0.6.

## Traits des ouvriers

Joueurs ayant au moins un ouvrier avec ce trait. Défauts et qualités sont tirés au draft, mais l'IA choisit ses cartes : les traits les plus visibles sont en partie évités.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Col blanc | 410 | 30 % | 24 % | +6 pts | 80 | 74 |
| Polyvalent | 2465 | 27 % | 21 % | +5 pts | 76 | 72 |
| Charismatique | 2480 | 26 % | 22 % | +4 pts | 75 | 73 |
| Débrouillard | 2518 | 26 % | 22 % | +4 pts | 76 | 72 |
| Costaud | 2453 | 26 % | 22 % | +4 pts | 76 | 72 |
| Bon élève | 2521 | 26 % | 22 % | +4 pts | 76 | 72 |
| Matinal | 2583 | 26 % | 23 % | ≈ +2 pts | 75 | 73 |
| Naturaliste | 2574 | 26 % | 24 % | ≈ +2 pts | 76 | 72 |
| Économe | 2456 | 26 % | 24 % | ≈ +2 pts | 76 | 72 |
| Endurant | 2546 | 25 % | 24 % | ≈ +2 pts | 76 | 73 |
| Rapide | 2407 | 25 % | 24 % | ≈ +1 pts | 76 | 73 |
| Distrait | 1624 | 25 % | 25 % | ≈ -1 pts | 74 | 75 |
| Casanier | 1566 | 25 % | 25 % | ≈ -1 pts | 73 | 76 |
| Maladroit | 1419 | 24 % | 25 % | ≈ -1 pts | 73 | 76 |
| Têtu | 1811 | 24 % | 26 % | ≈ -1 pts | 74 | 75 |
| Paresseux | 1578 | 24 % | 26 % | ≈ -1 pts | 73 | 76 |
| Rabat-joie | 1448 | 24 % | 25 % | ≈ -1 pts | 74 | 75 |
| Gourmand | 1434 | 23 % | 26 % | -3 pts | 73 | 76 |
| Lent | 1473 | 23 % | 26 % | -3 pts | 73 | 76 |
| Peureux | 1323 | 22 % | 27 % | -5 pts | 73 | 76 |

## Métiers

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Animateur | 576 | 33 % | 23 % | +10 pts | 82 | 73 |
| Vendeur de souvenirs | 633 | 33 % | 23 % | +10 pts | 81 | 73 |
| Marchand | 617 | 31 % | 24 % | +7 pts | 80 | 74 |
| Paysagiste | 2613 | 27 % | 20 % | +7 pts | 77 | 68 |
| Lobbyiste | 634 | 30 % | 24 % | +7 pts | 84 | 73 |
| Apprenti | 53 | 30 % | 25 % | ≈ +5 pts | 76 | 75 |
| Manœuvre | 125 | 30 % | 25 % | ≈ +5 pts | 74 | 75 |
| Charpentier | 2003 | 27 % | 23 % | +4 pts | 76 | 73 |
| Contremaître | 629 | 27 % | 25 % | ≈ +2 pts | 77 | 74 |
| Guichetier | 1633 | 26 % | 24 % | ≈ +2 pts | 74 | 75 |
| Soigneur | 1997 | 26 % | 24 % | ≈ +2 pts | 77 | 72 |
| Architecte | 553 | 26 % | 25 % | ≈ +2 pts | 77 | 74 |
| Animalier | 1740 | 26 % | 24 % | ≈ +1 pts | 74 | 75 |
| Maçon | 1485 | 26 % | 25 % | ≈ +1 pts | 75 | 75 |
| Porteur | 1506 | 26 % | 25 % | ≈ +1 pts | 76 | 74 |
| Bûcheron | 1531 | 26 % | 25 % | ≈ +1 pts | 75 | 74 |
| Cantonnier | 1940 | 25 % | 25 % | ≈ +1 pts | 76 | 73 |
| Terrassier | 1941 | 25 % | 25 % | ≈ +1 pts | 75 | 74 |
| Formateur | 580 | 25 % | 25 % | ≈ +0 pts | 75 | 75 |
| DRH | 566 | 25 % | 25 % | ≈ +0 pts | 76 | 74 |
| Journaliste | 625 | 25 % | 25 % | ≈ +0 pts | 72 | 75 |
| Agent d'entretien | 1486 | 25 % | 25 % | ≈ +0 pts | 74 | 75 |
| Intendant de parc | 458 | 24 % | 25 % | ≈ -1 pts | 75 | 75 |
| Mineur | 1763 | 23 % | 26 % | -3 pts | 74 | 75 |

## Améliorations

Choisies 25 % du temps au hasard pendant l'apprentissage, pour que toutes soient essayées.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Remise en question | 3621 | 25 % | 17 % | ≈ +8 pts | 75 | 70 |
| Pédagogue | 37 | 32 % | 25 % | ≈ +8 pts | 79 | 75 |
| Visionnaire | 1032 | 29 % | 23 % | +6 pts | 79 | 73 |
| Expérience | 2786 | 26 % | 22 % | +4 pts | 76 | 70 |
| Négociateur | 167 | 29 % | 25 % | ≈ +4 pts | 80 | 74 |
| Brouette | 641 | 28 % | 24 % | ≈ +4 pts | 78 | 74 |
| Révélation | 3118 | 25 % | 22 % | ≈ +4 pts | 75 | 72 |
| Scie affûtée | 635 | 28 % | 24 % | ≈ +3 pts | 78 | 74 |
| Seconde spécialité : Extraction de bois | 845 | 27 % | 24 % | ≈ +3 pts | 76 | 74 |
| Seconde spécialité : Extraction de pierre | 811 | 27 % | 24 % | ≈ +2 pts | 77 | 74 |
| Devenir Porteur | 226 | 27 % | 25 % | ≈ +2 pts | 72 | 75 |
| Devenir Soigneur | 271 | 26 % | 25 % | ≈ +1 pts | 75 | 75 |
| Seconde spécialité : Guichet | 868 | 26 % | 25 % | ≈ +1 pts | 77 | 74 |
| Seconde spécialité : Clôtures d'enclos | 736 | 26 % | 25 % | ≈ +1 pts | 77 | 74 |
| Devenir Agent d'entretien | 177 | 25 % | 25 % | ≈ +0 pts | 75 | 75 |
| Pied léger | 3006 | 25 % | 25 % | ≈ +0 pts | 75 | 74 |
| Devenir Charpentier | 300 | 25 % | 25 % | ≈ +0 pts | 74 | 75 |
| Seconde spécialité : Routes | 827 | 25 % | 25 % | ≈ +0 pts | 75 | 75 |
| Fidélité | 2637 | 25 % | 25 % | ≈ +0 pts | 75 | 75 |
| Seconde spécialité : Construction en pierre | 863 | 25 % | 25 % | ≈ +0 pts | 76 | 74 |
| Devenir Mineur | 231 | 25 % | 25 % | ≈ +0 pts | 73 | 75 |
| Devenir Cantonnier | 261 | 25 % | 25 % | ≈ +0 pts | 75 | 75 |
| Devenir Terrassier | 221 | 24 % | 25 % | ≈ -1 pts | 74 | 75 |
| Devenir Maçon | 201 | 24 % | 25 % | ≈ -1 pts | 73 | 75 |
| Devenir Paysagiste | 241 | 24 % | 25 % | ≈ -1 pts | 74 | 75 |
| Réseau | 189 | 23 % | 25 % | ≈ -2 pts | 85 | 74 |
| Devenir Bûcheron | 224 | 23 % | 25 % | ≈ -2 pts | 73 | 75 |
| Seconde spécialité : Construction en bois | 806 | 23 % | 25 % | ≈ -2 pts | 74 | 75 |
| Maîtrise | 3645 | 25 % | 27 % | ≈ -2 pts | 75 | 69 |
| Devenir Animalier | 363 | 23 % | 25 % | ≈ -2 pts | 72 | 75 |
| Chasseur de têtes | 183 | 21 % | 25 % | ≈ -4 pts | 73 | 75 |
| Devenir Guichetier | 178 | 20 % | 25 % | ≈ -6 pts | 69 | 75 |

## Bâtiments

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Camp niveau 3 | 1314 | 44 % | 14 % | +30 pts | 96 | 63 |
| Cuisine des animaux | 3539 | 26 % | 0 % | +26 pts | 77 | 21 |
| Entrée du zoo | 3634 | 25 % | 0 % | +25 pts | 75 | 9 |
| Local d'entretien | 3387 | 27 % | 2 % | +25 pts | 78 | 30 |
| Camp niveau 2 | 2987 | 29 % | 7 % | +22 pts | 80 | 50 |
| Kiosque d'animation | 2246 | 33 % | 12 % | +22 pts | 87 | 56 |
| Snack | 1781 | 36 % | 15 % | +21 pts | 88 | 62 |
| Bassin profond | 802 | 41 % | 21 % | +20 pts | 92 | 70 |
| Grand arbre | 957 | 40 % | 20 % | +20 pts | 92 | 69 |
| Rocher d'observation | 1207 | 38 % | 18 % | +20 pts | 89 | 67 |
| Agence d'intérim | 1548 | 36 % | 17 % | +20 pts | 89 | 64 |
| Cabinet de recrutement | 1917 | 34 % | 15 % | +19 pts | 87 | 62 |
| Abri chauffé | 189 | 37 % | 24 % | +12 pts | 89 | 74 |
| Maison du personnel | 3521 | 25 % | 16 % | +9 pts | 75 | 59 |
| Boutique de souvenirs | 1958 | 28 % | 21 % | +7 pts | 81 | 68 |
| Intendance du parc | 587 | 29 % | 24 % | +4 pts | 82 | 73 |
| Marché | 1356 | 23 % | 26 % | -4 pts | 73 | 76 |
| Entrepôt | 1750 | 22 % | 28 % | -6 pts | 71 | 78 |
| Mine d'or | 1667 | 21 % | 28 % | -7 pts | 71 | 77 |

## Labels

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| certifie | 304 | 22 % | 25 % | ≈ -3 pts | 71 | 75 |
| mecenat | 90 | 19 % | 25 % | ≈ -6 pts | 66 | 75 |
| excellence | 17 | 12 % | 25 % | ≈ -13 pts | 63 | 75 |

## Objectifs remplis

Joueurs ayant rempli cet objectif. Le taux de réussite est dans le tableau suivant.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Camp au niveau 3 avant le jour 8 | 14 | 71 % | 25 % | +47 pts | 108 | 75 |
| 5 espèces installées | 148 | 63 % | 23 % | +39 pts | 108 | 73 |
| 4 points de publicité | 120 | 57 % | 24 % | +34 pts | 108 | 74 |
| 3 espèces d'un même continent | 135 | 55 % | 24 % | +31 pts | 104 | 74 |
| 2 animaux peu communs | 121 | 54 % | 24 % | +30 pts | 101 | 74 |
| 120 visiteurs en une journée | 288 | 50 % | 23 % | +28 pts | 102 | 72 |
| 3 espèces d'un même type | 146 | 49 % | 24 % | +25 pts | 102 | 74 |
| 1 animal rare installé | 370 | 45 % | 23 % | +22 pts | 95 | 72 |
| 4 collaborateurs au niveau 5 | 20 | 45 % | 25 % | ≈ +20 pts | 84 | 75 |
| Boutique, Kiosque et Snack | 260 | 37 % | 24 % | +12 pts | 91 | 73 |
| 3 cadres dans l'équipe | 152 | 36 % | 25 % | +11 pts | 85 | 74 |
| Enceinte de 350 cases | 320 | 33 % | 24 % | +9 pts | 84 | 74 |
| 11 collaborateurs | 105 | 33 % | 25 % | ≈ +9 pts | 93 | 74 |
| 1 label obtenu | 61 | 28 % | 25 % | ≈ +3 pts | 78 | 75 |

| Objectif | Parties où il est tiré | Joueurs qui l'ont rempli | Taux de réussite |
|---|---|---|---|
| 3 espèces d'un même continent | 184 | 135 | 18 % |
| 3 espèces d'un même type | 196 | 146 | 19 % |
| 1 animal rare installé | 237 | 370 | 39 % |
| 2 animaux peu communs | 176 | 121 | 17 % |
| 5 espèces installées | 190 | 148 | 19 % |
| Enceinte de 350 cases | 202 | 320 | 40 % |
| 120 visiteurs en une journée | 191 | 288 | 38 % |
| 4 collaborateurs au niveau 5 | 203 | 20 | 2 % |
| 3 cadres dans l'équipe | 178 | 152 | 21 % |
| 11 collaborateurs | 188 | 105 | 14 % |
| Camp au niveau 3 avant le jour 8 | 202 | 14 | 2 % |
| Boutique, Kiosque et Snack | 195 | 260 | 33 % |
| 4 points de publicité | 196 | 120 | 15 % |
| 1 label obtenu | 204 | 61 | 7 % |

## Bonus de nuit

Joueurs ayant choisi ce bonus au moins une fois (le premier en influence choisit).

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Semaine des Amériques (Attractivité des animaux d'Amérique ×1,5) | 304 | 31 % | 24 % | +6 pts | 83 | 74 |
| Journée de l'océan (Attractivité des animaux aquatiques ×1,5) | 332 | 30 % | 24 % | +6 pts | 85 | 74 |
| Semaine de l'Asie (Attractivité des animaux d'Asie ×1,5) | 398 | 29 % | 24 % | +5 pts | 83 | 74 |
| Semaine de l'Europe (Attractivité des animaux d'Europe ×1,4) | 339 | 29 % | 25 % | ≈ +4 pts | 83 | 74 |
| Brouettes (+20 % de vitesse de déplacement) | 640 | 27 % | 25 % | ≈ +2 pts | 78 | 74 |
| Festival des oiseaux (Attractivité des animaux aériens ×1,5) | 351 | 27 % | 25 % | ≈ +2 pts | 83 | 74 |
| Campagne d'affichage (+20 % de visiteurs le soir) | 722 | 26 % | 25 % | ≈ +2 pts | 81 | 73 |
| Pioches renforcées (+30 % d'extraction de pierre) | 875 | 25 % | 25 % | ≈ +0 pts | 77 | 74 |
| Semaine de l'Afrique (Attractivité des animaux d'Afrique ×1,4) | 345 | 25 % | 25 % | ≈ +0 pts | 80 | 74 |
| Scies neuves (+30 % d'extraction de bois) | 843 | 25 % | 25 % | ≈ +0 pts | 78 | 74 |
| Engins de terrassement (+40 % d'aménagement du terrain) | 567 | 24 % | 25 % | ≈ -1 pts | 75 | 75 |
| Échafaudages (+25 % de construction) | 812 | 22 % | 26 % | -3 pts | 77 | 74 |
| Lampes de mineur (+40 % d'extraction d'or) | 631 | 21 % | 26 % | -5 pts | 77 | 74 |
| Carnet d'adresses (+50 % de lobbying) | 689 | 21 % | 26 % | -5 pts | 76 | 74 |

## Taille du parc

Agrandissements terminés et surface de l'enceinte en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Parc agrandi 2 fois et plus | 382 | 45 % | 23 % | +22 pts | 95 | 72 |
| Parc de 450 cases et plus | 1025 | 37 % | 20 % | +17 pts | 90 | 69 |
| Beauté du parc : aucune décoration | 3364 | 25 % | 24 % | ≈ +1 pts | 74 | 78 |
| Beauté du parc : 1 à 5 décorations | 192 | 25 % | 25 % | ≈ +0 pts | 77 | 75 |
| Parc agrandi 1 fois | 1115 | 24 % | 25 % | ≈ -1 pts | 76 | 74 |
| Beauté du parc : 6 décorations et plus | 100 | 22 % | 25 % | ≈ -3 pts | 81 | 75 |
| Parc de moins de 250 cases | 638 | 20 % | 26 % | -6 pts | 71 | 75 |
| Parc agrandi jamais | 2159 | 22 % | 30 % | -8 pts | 71 | 81 |
| Parc de 250 à 449 cases | 1993 | 20 % | 31 % | -10 pts | 68 | 83 |

## Cartes à usage unique et cadres joués

Joueurs ayant joué cette carte au moins une fois.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Accusation (Journaliste) | 79 | 66 % | 24 % | +42 pts | 107 | 74 |
| Cabinet de recrutement | 676 | 49 % | 20 % | +29 pts | 100 | 69 |
| Agence d'intérim | 843 | 44 % | 19 % | +25 pts | 95 | 69 |
| Article de presse (Journaliste) | 282 | 43 % | 23 % | +19 pts | 94 | 73 |
| Marchand joué (Négoce) | 56 | 32 % | 25 % | ≈ +7 pts | 76 | 75 |
| Recrutement express | 852 | 30 % | 24 % | +6 pts | 80 | 73 |
| Livraison | 728 | 28 % | 24 % | +4 pts | 79 | 74 |
| Prime | 951 | 27 % | 24 % | +3 pts | 78 | 73 |
| Formation express | 603 | 28 % | 24 % | ≈ +3 pts | 80 | 74 |
| Lobbyiste joué (Coup de fil) | 406 | 27 % | 25 % | ≈ +2 pts | 81 | 74 |
| Heures sup | 1101 | 26 % | 24 % | ≈ +2 pts | 77 | 74 |
| Animateur joué (Grand spectacle) | 422 | 26 % | 25 % | ≈ +2 pts | 78 | 74 |
| Portes ouvertes | 619 | 26 % | 25 % | ≈ +1 pts | 79 | 74 |
| Formateur joué (Stage de remise à niveau) | 581 | 25 % | 25 % | ≈ +1 pts | 75 | 75 |
| Promotion | 1002 | 25 % | 25 % | ≈ +0 pts | 76 | 74 |
| Rupture de contrat | 1129 | 25 % | 25 % | ≈ +0 pts | 77 | 74 |
| DRH joué (Mutation) | 384 | 25 % | 25 % | ≈ +0 pts | 77 | 74 |
| Architecte joué (Plan d'urgence) | 367 | 25 % | 25 % | ≈ +0 pts | 79 | 74 |
| Contremaître joué (Cadence) | 403 | 23 % | 25 % | ≈ -3 pts | 73 | 75 |
| Vendeur de souvenirs joué (Braderie) | 5 | 20 % | 25 % | ≈ -5 pts | 75 | 75 |
| Journée de carte cédée (+4) | 1904 | 21 % | 29 % | -8 pts | 71 | 79 |

### Effet immédiat des cartes sur la réputation gagnée

Réputation gagnée le jour où la carte est jouée, comparée à la veille. La réputation monte naturellement chaque jour : à comparer d'une carte à l'autre plutôt qu'à zéro. « Tard » : à partir du jour 8.

| Carte | Coût | Jouée | Gain du jour | Veille | Écart | Tard : gain | Tard : veille | Tard : écart |
|---|---|---|---|---|---|---|---|---|
| Accusation (Journaliste) | — | 90 | 25.8 | 19.5 | +6.3 | 25.8 | 19.5 | +6.3 (90) |
| Cabinet de recrutement | — | 924 | 18.3 | 13.7 | +4.6 | 18.3 | 13.7 | +4.6 (914) |
| Recrutement express | 8 | 1002 | 11.9 | 8.5 | +3.4 | 14.4 | 10.4 | +4.0 (791) |
| Agence d'intérim | — | 1463 | 18.7 | 15.1 | +3.5 | 18.7 | 15.2 | +3.5 (1455) |
| Article de presse (Journaliste) | — | 330 | 18.2 | 15.1 | +3.1 | 18.2 | 15.2 | +3.1 (327) |
| Animateur joué (Grand spectacle) | — | 819 | 8.6 | 5.3 | +3.3 | 9.6 | 6.7 | +2.8 (504) |
| DRH joué (Mutation) | — | 598 | 9.4 | 6.9 | +2.4 | 12.2 | 9.5 | +2.7 (376) |
| Vendeur de souvenirs joué (Braderie) | — | 6 | 4.5 | 2.0 | +2.5 | 4.5 | 2.0 | +2.5 (6) |
| Formation express | 14 | 667 | 11.5 | 9.8 | +1.8 | 13.5 | 11.4 | +2.1 (552) |
| Prime | 10 | 1205 | 10.4 | 8.8 | +1.6 | 12.8 | 10.9 | +1.9 (930) |
| Portes ouvertes | 14 | 731 | 11.9 | 10.0 | +1.9 | 12.6 | 10.8 | +1.8 (659) |
| Rupture de contrat | 3 | 1472 | 9.4 | 7.8 | +1.7 | 10.8 | 9.1 | +1.7 (1171) |
| Journée de carte cédée (+4) | — | 5711 | 1.5 | 0.9 | +0.6 | 2.8 | 1.2 | +1.6 (1564) |
| Formateur joué (Stage de remise à niveau) | — | 2203 | 5.7 | 4.7 | +1.0 | 10.4 | 8.8 | +1.6 (1045) |
| Contremaître joué (Cadence) | — | 1095 | 5.1 | 4.3 | +0.9 | 10.7 | 9.1 | +1.6 (450) |
| Heures sup | 8 | 1478 | 9.1 | 8.1 | +1.1 | 11.7 | 10.4 | +1.3 (1093) |
| Livraison | 15 | 857 | 10.3 | 9.2 | +1.1 | 12.1 | 10.8 | +1.3 (710) |
| Lobbyiste joué (Coup de fil) | — | 716 | 7.1 | 6.4 | +0.7 | 10.0 | 9.1 | +0.9 (431) |
| Architecte joué (Plan d'urgence) | — | 710 | 7.9 | 7.4 | +0.5 | 12.1 | 11.3 | +0.9 (439) |
| Promotion | 8 | 1234 | 8.9 | 8.5 | +0.4 | 11.1 | 10.6 | +0.4 (930) |
| Marchand joué (Négoce) | — | 63 | 4.3 | 4.5 | -0.2 | 9.5 | 9.7 | -0.2 (26) |

## Animaux

Taux d'achat : achats par nuit passée au marché. Un rare est naturellement moins acheté : il coûte très cher.

| Espèce | Continent | Rareté | Nuits au marché | Achats | Taux d'achat | Jour moyen d'achat | Installée | Victoires avec | Écart |
|---|---|---|---|---|---|---|---|---|---|
| Loutre cendrée | Asie | Peu commun | 695 | 228 | 33 % | 8.0 | 195 | 41 % | +17 pts |
| Loutre d'Europe | Europe | Peu commun | 769 | 250 | 33 % | 8.4 | 202 | 44 % | +20 pts |
| Cerf élaphe | Europe | Commun | 1456 | 462 | 32 % | 5.7 | 420 | 26 % | +1 pts |
| Capybara | Amérique | Peu commun | 773 | 243 | 31 % | 7.9 | 201 | 43 % | +19 pts |
| Yak | Asie | Commun | 1530 | 474 | 31 % | 5.7 | 425 | 27 % | +3 pts |
| Paon bleu | Asie | Peu commun | 846 | 260 | 31 % | 8.3 | 183 | 41 % | +17 pts |
| Bison d'Amérique | Amérique | Commun | 1469 | 436 | 30 % | 5.4 | 400 | 31 % | +6 pts |
| Lynx boréal | Europe | Peu commun | 838 | 247 | 29 % | 8.5 | 191 | 36 % | +12 pts |
| Zèbre | Afrique | Commun | 1475 | 431 | 29 % | 5.8 | 382 | 28 % | +4 pts |
| Manchot du Cap | Afrique | Peu commun | 998 | 286 | 29 % | 8.3 | 201 | 35 % | +11 pts |
| Panda géant | Asie | Rare | 1396 | 396 | 28 % | 9.2 | 253 | 44 % | +21 pts |
| Salamandre géante | Asie | Commun | 1707 | 471 | 28 % | 5.7 | 405 | 29 % | +5 pts |
| Girafe | Afrique | Peu commun | 934 | 240 | 26 % | 8.6 | 175 | 36 % | +12 pts |
| Alligator américain | Amérique | Peu commun | 982 | 252 | 26 % | 8.5 | 183 | 38 % | +13 pts |
| Léopard des neiges | Asie | Peu commun | 983 | 249 | 25 % | 8.5 | 198 | 40 % | +16 pts |
| Carpe koï | Asie | Commun | 1728 | 435 | 25 % | 5.9 | 374 | 28 % | +4 pts |
| Loup gris | Europe | Peu commun | 832 | 209 | 25 % | 8.3 | 156 | 42 % | +18 pts |
| Dauphin rose de l'Amazone | Amérique | Rare | 1342 | 332 | 25 % | 9.3 | 206 | 45 % | +21 pts |
| Calao bicorne | Asie | Commun | 1726 | 423 | 25 % | 6.0 | 383 | 28 % | +4 pts |
| Bison d'Europe | Europe | Rare | 1458 | 357 | 24 % | 9.0 | 249 | 45 % | +22 pts |
| Guépard | Afrique | Peu commun | 1065 | 257 | 24 % | 8.4 | 209 | 38 % | +14 pts |
| Hippopotame | Afrique | Rare | 1448 | 349 | 24 % | 9.2 | 230 | 40 % | +16 pts |
| Puma | Amérique | Peu commun | 1001 | 238 | 24 % | 8.5 | 175 | 39 % | +15 pts |
| Tigre du Bengale | Asie | Rare | 1392 | 329 | 24 % | 9.5 | 212 | 53 % | +30 pts |
| Lion | Afrique | Rare | 1616 | 381 | 24 % | 9.3 | 253 | 47 % | +24 pts |
| Mésange charbonnière | Europe | Commun | 1776 | 417 | 23 % | 6.1 | 364 | 27 % | +2 pts |
| Messager sagittaire | Afrique | Commun | 1940 | 449 | 23 % | 6.2 | 401 | 27 % | +2 pts |
| Ocelot | Amérique | Commun | 1831 | 422 | 23 % | 6.2 | 369 | 27 % | +2 pts |
| Aigle royal | Europe | Rare | 1554 | 351 | 23 % | 9.1 | 217 | 42 % | +18 pts |
| Loutre à joues blanches | Afrique | Commun | 1984 | 433 | 22 % | 5.7 | 388 | 29 % | +5 pts |
| Pygargue à tête blanche | Amérique | Rare | 1593 | 346 | 22 % | 9.1 | 204 | 47 % | +23 pts |
| Jaguar | Amérique | Peu commun | 1083 | 235 | 22 % | 8.4 | 188 | 38 % | +13 pts |
| Grue du Japon | Asie | Commun | 1781 | 386 | 22 % | 6.0 | 347 | 29 % | +5 pts |
| Bouquetin des Alpes | Europe | Commun | 1962 | 406 | 21 % | 6.4 | 351 | 26 % | +1 pts |
| Hyène tachetée | Afrique | Commun | 1950 | 403 | 21 % | 5.8 | 367 | 24 % | -1 pts |
| Phoque gris | Europe | Commun | 2105 | 403 | 19 % | 6.3 | 339 | 32 % | +7 pts |
| Faucon pèlerin | Europe | Commun | 2058 | 374 | 18 % | 6.3 | 321 | 32 % | +8 pts |
| Tapir de Baird | Amérique | Commun | 2144 | 356 | 17 % | 6.6 | 301 | 27 % | +2 pts |
| Grue couronnée | Afrique | Commun | 2285 | 373 | 16 % | 6.6 | 318 | 31 % | +7 pts |
| Ara rouge | Amérique | Commun | 2490 | 325 | 13 % | 7.1 | 274 | 24 % | -1 pts |

## Continents

Selon le nombre d'espèces de ce continent en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Asie (3 espèces et plus) | 179 | 55 % | 23 % | +31 pts | 103 | 73 |
| Amerique (3 espèces et plus) | 123 | 50 % | 24 % | +26 pts | 101 | 74 |
| Afrique (3 espèces et plus) | 168 | 48 % | 24 % | +24 pts | 99 | 74 |
| Europe (3 espèces et plus) | 178 | 46 % | 24 % | +22 pts | 99 | 73 |
| Amerique (1 ou 2 espèces) | 1663 | 30 % | 21 % | +9 pts | 82 | 68 |
| Europe (1 ou 2 espèces) | 1735 | 29 % | 21 % | +7 pts | 81 | 69 |
| Asie (1 ou 2 espèces) | 1838 | 27 % | 23 % | +5 pts | 79 | 70 |
| Afrique (1 ou 2 espèces) | 1855 | 27 % | 23 % | +4 pts | 80 | 70 |

## Types d'animaux

Selon le nombre d'espèces de ce type en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| predateur (3 espèces et plus) | 75 | 67 % | 24 % | +43 pts | 108 | 74 |
| aquatique (3 espèces et plus) | 123 | 47 % | 24 % | +23 pts | 99 | 74 |
| herbivore (3 espèces et plus) | 169 | 43 % | 24 % | +18 pts | 95 | 74 |
| aerien (3 espèces et plus) | 167 | 41 % | 24 % | +16 pts | 97 | 74 |
| predateur (1 ou 2 espèces) | 1707 | 32 % | 19 % | +13 pts | 84 | 67 |
| aquatique (1 ou 2 espèces) | 1802 | 31 % | 19 % | +12 pts | 82 | 67 |
| herbivore (1 ou 2 espèces) | 2016 | 29 % | 20 % | +8 pts | 81 | 67 |
| aerien (1 ou 2 espèces) | 1924 | 28 % | 22 % | +6 pts | 80 | 69 |

## Raretés

Selon les animaux installés en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Rare installés (2 et plus) | 339 | 55 % | 22 % | +34 pts | 104 | 72 |
| Peu commun installés (2 et plus) | 573 | 49 % | 21 % | +28 pts | 99 | 70 |
| Rare installé (1) | 1095 | 38 % | 19 % | +19 pts | 90 | 68 |
| Commun installés (2 et plus) | 1866 | 28 % | 22 % | +6 pts | 82 | 67 |
| Peu commun installé (1) | 1214 | 29 % | 23 % | +6 pts | 82 | 71 |
| Commun installé (1) | 1544 | 21 % | 28 % | -7 pts | 68 | 80 |

## D'où vient la réputation

- beaute : 0 %
- boutique : 6 %
- frequentation : 70 %
- legendaires : 2 %
- objectifs : 8 %
- prestige : 11 %
- spectacles : 2 %
- labels : 1 %
