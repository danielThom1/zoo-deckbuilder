# Étude du jeu par l'IA qui apprend

10000 parties sur 10000 jouées, 772 min de calcul. Fin de partie en moyenne au jour 12.3.
Record : victoire au jour 8 (109 de réputation, graine 507869521).
IA bloquées : 253 joueurs sur 40000 finissent à 0 de réputation, 541 sans aucun animal.

**Comment lire les tableaux** : « Victoires avec » est le taux de victoire des joueurs qui avaient cet élément en fin de partie, « sans » celui des autres. Un écart positif veut dire que l'élément accompagne la victoire, sans le prouver : un joueur qui gagne a aussi plus d'ouvriers, de bâtiments et d'animaux. « ≈ » signale un écart trop faible pour conclure, compte tenu du nombre de parties.

## En bref : forts et faibles

Écart de victoires en points, seulement quand il est significatif, et hors éléments presque absents ou présents chez presque tous. Les bâtiments et les améliorations communes sont faussés : un joueur qui dure en a davantage.

- **Traits** : forts : Endurant (+2), Débrouillard (+2), Rapide (+2), Économe (+2), Polyvalent (+1) ; faibles : Gourmand (-5), Casanier (-5), Paresseux (-4), Peureux (-4), Lent (-4).
- **Métiers** : forts : Paysagiste (+7), Lobbyiste (+6), Vendeur de souvenirs (+5), Cantonnier (+3), Terrassier (+3) ; faibles : Journaliste (-9), Intendant de parc (-6), Formateur (-4), Architecte (-3), Soigneur (-3).
- **Améliorations** : forts : Réseau (+7), Visionnaire (+5), Expérience (+4), Seconde spécialité : Guichet (+3), Devenir Terrassier (+3) ; faibles : Négociateur (-3), Devenir Soigneur (-2), Devenir Animalier (-1), Maîtrise (-1).
- **Cartes** : forts : Portes ouvertes (+17), Cabinet de recrutement (+10), Agence d'intérim (+10), Heures sup (+9), Recrutement express (+9) ; faibles : Journée de carte cédée (+4) (-11), Marchand joué (Négoce) (-5), Contremaître joué (Cadence) (-5), Formateur joué (Stage de remise à niveau) (-4), Architecte joué (Plan d'urgence) (-4).
- **Animaux** : forts : Guépard (+23), Capybara (+18), Loutre cendrée (+18), Lynx boréal (+18), Paon bleu (+15) ; faibles : aucun net.
- **Bâtiments** : forts : Local d'entretien (+25), Camp niveau 3 (+24), Kiosque d'animation (+24), Abri chauffé (+22), Camp niveau 2 (+20) ; faibles : Mine d'or (-14), Entrepôt (-11), Marché (-8).
- **Bonus de nuit** : forts : Semaine des Amériques (Attractivité des animaux d'Amérique ×1,5) (+16), Festival des oiseaux (Attractivité des animaux aériens ×1,5) (+16), Campagne d'affichage (+20 % de visiteurs le soir) (+16), Semaine de l'Afrique (Attractivité des animaux d'Afrique ×1,4) (+15), Semaine de l'Europe (Attractivité des animaux d'Europe ×1,4) (+13) ; faibles : aucun net.

## Classement des stratégies (phase finale)

| Stratégie | Parties | Victoires | Jour moyen de victoire | Réputation moyenne |
|---|---|---|---|---|
| Apprise 4 | 124 | 67 % | 11.8 | 101 |
| Apprise 3 | 124 | 65 % | 11.8 | 100 |
| Apprise 1 | 124 | 59 % | 12.1 | 100 |
| Apprise 2 | 125 | 56 % | 12.1 | 97 |
| Amérique | 125 | 27 % | 13.1 | 76 |
| Formateur | 124 | 26 % | 12.8 | 77 |
| Rush or | 124 | 25 % | 13.6 | 81 |
| Ancienne IA | 124 | 23 % | 13.0 | 77 |
| Europe | 124 | 23 % | 13.1 | 72 |
| Afrique | 124 | 23 % | 13.1 | 78 |
| Prédateurs | 124 | 23 % | 13.0 | 75 |
| Sans agrandir | 124 | 23 % | 13.0 | 75 |
| Équilibrée | 124 | 23 % | 13.4 | 76 |
| Fast expand | 125 | 22 % | 13.1 | 69 |
| Sans intendance | 124 | 22 % | 13.0 | 72 |
| Marché | 125 | 22 % | 13.4 | 77 |
| Aériens | 124 | 21 % | 13.2 | 74 |
| Même type | 124 | 20 % | 12.8 | 68 |
| Grand camp | 124 | 20 % | 13.4 | 74 |
| Spectacle | 124 | 19 % | 12.9 | 73 |
| Haut de gamme | 124 | 19 % | 12.9 | 70 |
| Affinités | 124 | 19 % | 13.1 | 70 |
| Aquatiques | 124 | 19 % | 13.8 | 70 |
| Spécialisation | 124 | 18 % | 13.1 | 71 |
| Rush or + route | 124 | 18 % | 12.9 | 65 |
| Lobbying | 124 | 18 % | 13.4 | 77 |
| Petits contrats | 125 | 17 % | 13.0 | 72 |
| Asie | 125 | 17 % | 13.8 | 73 |
| Camp amélioré | 123 | 15 % | 13.4 | 70 |
| Herbivores | 124 | 15 % | 13.8 | 70 |
| Grand parc | 122 | 15 % | 13.3 | 66 |
| Cartes | 124 | 13 % | 13.3 | 65 |
| Parc évolutif | 125 | 12 % | 13.2 | 51 |

## Niveaux d'IA enregistrés (game/data/ia_niveaux.json)

| Niveau | Victoires en finale | Réputation moyenne | Stratégies |
|---|---|---|---|
| Facile | 14 % | 63 | Herbivores, Grand parc, Cartes, Parc évolutif |
| Moyen | 21 % | 73 | Sans intendance, Marché, Aériens, Même type |
| Difficile | 62 % | 100 | Apprise 4, Apprise 3, Apprise 1, Apprise 2 |

## Stratégies apprises

| Génération | Victoires de la meilleure | Ses parties | Jour moyen | Réputation | Moyenne de la population |
|---|---|---|---|---|---|
| 1 | 42 % | 12 | 13.6 | 90 | 25 % |
| 13 | 47 % | 36 | 12.2 | 92 | 28 % |
| 25 | 67 % | 12 | 11.5 | 99 | 26 % |
| 37 | 45 % | 228 | 11.5 | 89 | 27 % |
| 49 | 48 % | 132 | 11.5 | 94 | 25 % |
| 61 | 58 % | 24 | 11.6 | 95 | 27 % |
| 73 | 50 % | 24 | 12.2 | 99 | 27 % |
| 85 | 58 % | 12 | 11.7 | 93 | 26 % |
| 97 | 54 % | 72 | 11.9 | 95 | 28 % |
| 109 | 48 % | 216 | 12.0 | 91 | 27 % |
| 121 | 41 % | 360 | 12.0 | 89 | 28 % |
| 133 | 63 % | 24 | 11.6 | 95 | 28 % |
| 145 | 44 % | 168 | 12.0 | 89 | 28 % |
| 157 | 47 % | 96 | 11.5 | 87 | 23 % |
| 169 | 42 % | 60 | 11.9 | 94 | 26 % |
| 181 | 58 % | 12 | 12.0 | 94 | 26 % |

1. parc grand, palier 1.0, réserve 5, lobby 0, camp 2, contrats 3, marche, sans adaptatif
2. parc grand, palier 1.0, réserve 5, lobby 2, camp 2, contrats 3, sans adaptatif, sans agrandir
3. parc grand, palier 1.0, réserve 0, lobby 1, camp 2, contrats 3, sans adaptatif, sans agrandir
4. parc grand, palier 1.0, réserve 0, lobby 0, camp 2, contrats 2, sans adaptatif

Réglages retenus par les 8 meilleures : marche 2/8, rush_or 0/8, formation 1/8, cartes 0/8, spectacle 0/8, affinite 0/8, boutique 8/8, mine 0/8, specialisation 0/8, fast_expand 2/8, route_mine 1/8, adaptatif 0/8, agrandir 3/8, meme_type 0/8, intendance 0/8.

**Métiers, des plus recherchés aux plus évités par les IA qui gagnent** : Agent d'entretien +2.0, DRH +1.8, Manœuvre +1.4, Cantonnier +1.1, Charpentier +0.7, Paysagiste +0.6, Guichetier +0.6, Terrassier +0.6, Mineur +0.4, Apprenti +0.4, Porteur +0.3, Lobbyiste +0.1, Journaliste -0.0, Maçon -0.1, Contremaître -0.3, Bûcheron -0.5, Formateur -0.5, Architecte -0.6, Vendeur de souvenirs -0.6, Soigneur -1.3, Animalier -1.4, Animateur -1.6, Intendant de parc -1.8, Marchand -1.8.

**Traits, des plus recherchés aux plus évités par les IA qui gagnent** : Rapide +1.0, Costaud +0.6, Polyvalent +0.2, Naturaliste +0.0, Matinal +0.0, Économe -0.1, Débrouillard -0.1, Rabat-joie -0.1, Col blanc -0.2, Endurant -0.4, Maladroit -0.4, Charismatique -0.5, Têtu -0.7, Lent -1.2, Distrait -1.2, Bon élève -1.4, Peureux -1.5, Gourmand -1.5, Paresseux -1.6, Casanier -1.8.

**Animaux, des plus recherchés aux plus évités par les IA qui gagnent** : Hyène tachetée +1.9, Ara rouge +1.5, Jaguar +1.5, Pygargue à tête blanche +1.4, Faucon pèlerin +1.3, Girafe +1.0, Paon bleu +1.0, Ocelot +0.9, Loutre cendrée +0.9, Bouquetin des Alpes +0.8, Grue du Japon +0.8, Cerf élaphe +0.8, Lynx boréal +0.6, Dauphin rose de l'Amazone +0.6, Alligator américain +0.4, Bison d'Amérique +0.4, Messager sagittaire +0.3, Phoque gris +0.2, Mésange charbonnière +0.2, Puma +0.2, Guépard +0.1, Salamandre géante +0.0, Léopard des neiges +0.0, Zèbre +0.0, Loup gris -0.0, Capybara -0.0, Carpe koï -0.0, Tapir de Baird -0.1, Lion -0.2, Grue couronnée -0.2, Bison d'Europe -0.2, Hippopotame -0.3, Calao bicorne -0.4, Aigle royal -0.6, Tigre du Bengale -0.9, Manchot du Cap -1.0, Yak -1.5, Loutre à joues blanches -1.7, Panda géant -1.8, Loutre d'Europe -1.9.

**Cartes, des plus recherchés aux plus évités par les IA qui gagnent** : Promotion +1.3, Portes ouvertes +0.8, Rupture de contrat +0.3, Formation express +0.3, Heures sup +0.2, Recrutement express -0.1, Livraison -0.5, Prime -0.9.

**Améliorations, des plus recherchés aux plus évités par les IA qui gagnent** : Négociateur +2.0, Visionnaire +1.5, Réseau +1.5, Expérience +0.9, Pied léger +0.8, Seconde spécialité +0.6, Remise en question +0.5, Fidélité +0.3, Chasseur de têtes +0.2, Brouette -0.2, Scie affûtée -0.3, Révélation -1.0, Pédagogue -1.5, Maîtrise -1.9.

## Traits des ouvriers

Joueurs ayant au moins un ouvrier avec ce trait. Défauts et qualités sont tirés au draft, mais l'IA choisit ses cartes : les traits les plus visibles sont en partie évités.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Endurant | 24535 | 26 % | 24 % | +2 pts | 77 | 74 |
| Débrouillard | 25725 | 26 % | 24 % | +2 pts | 77 | 74 |
| Rapide | 25377 | 26 % | 24 % | +2 pts | 77 | 74 |
| Économe | 24496 | 26 % | 24 % | +2 pts | 77 | 74 |
| Polyvalent | 23613 | 26 % | 24 % | +1 pts | 77 | 75 |
| Naturaliste | 25017 | 25 % | 24 % | +1 pts | 76 | 75 |
| Charismatique | 21958 | 25 % | 24 % | +1 pts | 76 | 75 |
| Costaud | 24550 | 25 % | 25 % | ≈ +1 pts | 76 | 75 |
| Bon élève | 21155 | 25 % | 25 % | ≈ +0 pts | 76 | 76 |
| Matinal | 23619 | 25 % | 25 % | ≈ +0 pts | 76 | 76 |
| Têtu | 20551 | 25 % | 25 % | ≈ -1 pts | 75 | 77 |
| Col blanc | 3680 | 23 % | 25 % | -2 pts | 76 | 76 |
| Maladroit | 16146 | 24 % | 26 % | -2 pts | 74 | 77 |
| Rabat-joie | 17666 | 24 % | 26 % | -2 pts | 74 | 77 |
| Distrait | 15592 | 24 % | 26 % | -2 pts | 74 | 77 |
| Lent | 14100 | 23 % | 26 % | -4 pts | 73 | 78 |
| Peureux | 15286 | 23 % | 26 % | -4 pts | 73 | 78 |
| Paresseux | 15555 | 22 % | 27 % | -4 pts | 73 | 78 |
| Casanier | 14337 | 22 % | 27 % | -5 pts | 72 | 78 |
| Gourmand | 15293 | 22 % | 27 % | -5 pts | 72 | 78 |

## Métiers

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Paysagiste | 27131 | 27 % | 20 % | +7 pts | 79 | 70 |
| Lobbyiste | 5741 | 30 % | 24 % | +6 pts | 84 | 75 |
| Vendeur de souvenirs | 4779 | 29 % | 24 % | +5 pts | 79 | 76 |
| Apprenti | 391 | 28 % | 25 % | ≈ +3 pts | 78 | 76 |
| Cantonnier | 20695 | 26 % | 23 % | +3 pts | 77 | 75 |
| Terrassier | 20083 | 26 % | 24 % | +3 pts | 77 | 74 |
| DRH | 5905 | 27 % | 25 % | +2 pts | 78 | 76 |
| Charpentier | 20431 | 26 % | 24 % | +2 pts | 77 | 75 |
| Agent d'entretien | 23245 | 26 % | 24 % | +2 pts | 76 | 75 |
| Manœuvre | 1417 | 27 % | 25 % | ≈ +2 pts | 76 | 76 |
| Porteur | 16770 | 26 % | 25 % | +1 pts | 76 | 76 |
| Guichetier | 22409 | 25 % | 24 % | +1 pts | 76 | 76 |
| Bûcheron | 14225 | 25 % | 25 % | ≈ +0 pts | 76 | 76 |
| Animateur | 4247 | 25 % | 25 % | ≈ +0 pts | 78 | 76 |
| Maçon | 15252 | 25 % | 25 % | ≈ +0 pts | 75 | 76 |
| Contremaître | 5228 | 24 % | 25 % | ≈ -1 pts | 76 | 76 |
| Mineur | 19069 | 24 % | 26 % | -1 pts | 75 | 77 |
| Animalier | 18329 | 24 % | 26 % | -2 pts | 74 | 77 |
| Marchand | 4315 | 23 % | 25 % | -2 pts | 76 | 76 |
| Soigneur | 18789 | 24 % | 26 % | -3 pts | 76 | 76 |
| Architecte | 5001 | 22 % | 25 % | -3 pts | 74 | 76 |
| Formateur | 4863 | 21 % | 26 % | -4 pts | 73 | 76 |
| Intendant de parc | 2697 | 19 % | 25 % | -6 pts | 70 | 76 |
| Journaliste | 5990 | 17 % | 26 % | -9 pts | 67 | 78 |

## Améliorations

Choisies 25 % du temps au hasard pendant l'apprentissage, pour que toutes soient essayées.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Réseau | 2396 | 32 % | 25 % | +7 pts | 86 | 75 |
| Visionnaire | 13347 | 28 % | 23 % | +5 pts | 81 | 74 |
| Expérience | 29724 | 26 % | 22 % | +4 pts | 77 | 73 |
| Seconde spécialité : Guichet | 19084 | 27 % | 23 % | +3 pts | 78 | 74 |
| Devenir Terrassier | 2453 | 28 % | 25 % | +3 pts | 79 | 76 |
| Pied léger | 32022 | 26 % | 22 % | +3 pts | 77 | 73 |
| Seconde spécialité : Extraction de pierre | 19131 | 27 % | 23 % | +3 pts | 78 | 74 |
| Seconde spécialité : Construction en bois | 18761 | 26 % | 24 % | +3 pts | 78 | 74 |
| Devenir Paysagiste | 2943 | 28 % | 25 % | +3 pts | 78 | 76 |
| Seconde spécialité : Construction en pierre | 19363 | 26 % | 24 % | +3 pts | 78 | 74 |
| Seconde spécialité : Extraction de bois | 19822 | 26 % | 24 % | +3 pts | 78 | 74 |
| Pédagogue | 288 | 27 % | 25 % | ≈ +2 pts | 81 | 76 |
| Seconde spécialité : Clôtures d'enclos | 17579 | 26 % | 24 % | +2 pts | 78 | 74 |
| Seconde spécialité : Routes | 18763 | 26 % | 24 % | +2 pts | 78 | 74 |
| Devenir Agent d'entretien | 2481 | 26 % | 25 % | ≈ +2 pts | 77 | 76 |
| Fidélité | 33229 | 25 % | 24 % | +1 pts | 77 | 73 |
| Chasseur de têtes | 2306 | 26 % | 25 % | ≈ +1 pts | 77 | 76 |
| Devenir Porteur | 2355 | 25 % | 25 % | ≈ +1 pts | 77 | 76 |
| Scie affûtée | 6730 | 25 % | 25 % | ≈ +1 pts | 77 | 76 |
| Devenir Guichetier | 2543 | 25 % | 25 % | ≈ +0 pts | 75 | 76 |
| Devenir Mineur | 2514 | 25 % | 25 % | ≈ +0 pts | 76 | 76 |
| Brouette | 7681 | 25 % | 25 % | ≈ +0 pts | 77 | 76 |
| Devenir Bûcheron | 2194 | 25 % | 25 % | ≈ +0 pts | 76 | 76 |
| Devenir Cantonnier | 2914 | 25 % | 25 % | ≈ +0 pts | 76 | 76 |
| Remise en question | 39653 | 25 % | 25 % | ≈ +0 pts | 76 | 70 |
| Révélation | 25259 | 25 % | 25 % | ≈ +0 pts | 77 | 75 |
| Devenir Charpentier | 2929 | 25 % | 25 % | ≈ +0 pts | 76 | 76 |
| Maîtrise | 33028 | 25 % | 26 % | -1 pts | 76 | 75 |
| Devenir Animalier | 4228 | 24 % | 25 % | -1 pts | 73 | 76 |
| Devenir Maçon | 2300 | 23 % | 25 % | ≈ -2 pts | 75 | 76 |
| Devenir Soigneur | 2836 | 23 % | 25 % | -2 pts | 74 | 76 |
| Négociateur | 1728 | 23 % | 25 % | -3 pts | 76 | 76 |

## Bâtiments

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Cuisine des animaux | 39228 | 25 % | 0 % | +25 pts | 77 | 18 |
| Local d'entretien | 37920 | 26 % | 1 % | +25 pts | 79 | 28 |
| Entrée du zoo | 39877 | 25 % | 0 % | +25 pts | 76 | 19 |
| Camp niveau 3 | 21939 | 36 % | 12 % | +24 pts | 89 | 60 |
| Kiosque d'animation | 28073 | 32 % | 8 % | +24 pts | 86 | 52 |
| Abri chauffé | 856 | 46 % | 25 % | +22 pts | 96 | 75 |
| Camp niveau 2 | 34557 | 28 % | 8 % | +20 pts | 79 | 55 |
| Grand arbre | 3185 | 42 % | 24 % | +18 pts | 94 | 74 |
| Bassin profond | 1680 | 41 % | 24 % | +17 pts | 95 | 75 |
| Rocher d'observation | 3964 | 40 % | 23 % | +17 pts | 94 | 74 |
| Boutique de souvenirs | 22777 | 28 % | 21 % | +6 pts | 79 | 71 |
| Maison du personnel | 38401 | 25 % | 21 % | +4 pts | 76 | 71 |
| Intendance du parc | 5741 | 27 % | 25 % | +2 pts | 82 | 75 |
| Snack | 3598 | 27 % | 25 % | +2 pts | 83 | 75 |
| Agence d'intérim | 2924 | 27 % | 25 % | ≈ +2 pts | 83 | 75 |
| Cabinet de recrutement | 4053 | 24 % | 25 % | ≈ -1 pts | 80 | 75 |
| Marché | 9697 | 19 % | 27 % | -8 pts | 70 | 78 |
| Entrepôt | 13139 | 17 % | 29 % | -11 pts | 66 | 81 |
| Mine d'or | 7975 | 14 % | 28 % | -14 pts | 64 | 79 |

## Labels

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| certifie | 1236 | 14 % | 25 % | -11 pts | 68 | 76 |
| mecenat | 326 | 13 % | 25 % | -12 pts | 64 | 76 |
| excellence | 56 | 11 % | 25 % | -14 pts | 69 | 76 |

## Objectifs remplis

Joueurs ayant rempli cet objectif. Le taux de réussite est dans le tableau suivant.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| 4 points de publicité | 2624 | 56 % | 23 % | +34 pts | 105 | 74 |
| 2 animaux peu communs | 460 | 58 % | 25 % | +33 pts | 106 | 76 |
| 5 espèces installées | 2285 | 55 % | 23 % | +31 pts | 104 | 74 |
| 3 espèces d'un même continent | 2086 | 53 % | 23 % | +29 pts | 101 | 75 |
| 1 animal rare installé | 548 | 53 % | 25 % | +28 pts | 102 | 76 |
| 3 espèces d'un même type | 2159 | 47 % | 24 % | +23 pts | 98 | 75 |
| Enceinte de 350 cases | 1510 | 47 % | 24 % | +23 pts | 96 | 75 |
| 80 visiteurs en une journée | 5152 | 40 % | 23 % | +18 pts | 95 | 73 |
| 11 collaborateurs | 650 | 40 % | 25 % | +15 pts | 90 | 76 |
| Camp au niveau 3 | 4894 | 38 % | 23 % | +15 pts | 90 | 74 |
| 3 cadres dans l'équipe | 1198 | 29 % | 25 % | +5 pts | 82 | 76 |
| 4 collaborateurs au niveau 4 | 6957 | 28 % | 24 % | +3 pts | 82 | 75 |
| Boutique, Kiosque et Snack | 721 | 27 % | 25 % | ≈ +3 pts | 83 | 76 |
| 1 label obtenu | 253 | 19 % | 25 % | -6 pts | 74 | 76 |

| Objectif | Parties où il est tiré | Joueurs qui l'ont rempli | Taux de réussite |
|---|---|---|---|
| 3 espèces d'un même continent | 2131 | 2086 | 24 % |
| 3 espèces d'un même type | 2161 | 2159 | 25 % |
| 1 animal rare installé | 2122 | 548 | 6 % |
| 2 animaux peu communs | 2076 | 460 | 6 % |
| 5 espèces installées | 2147 | 2285 | 27 % |
| Enceinte de 350 cases | 2185 | 1510 | 17 % |
| 80 visiteurs en une journée | 2158 | 5152 | 60 % |
| 4 collaborateurs au niveau 4 | 2073 | 6957 | 84 % |
| 3 cadres dans l'équipe | 2180 | 1198 | 14 % |
| 11 collaborateurs | 2121 | 650 | 8 % |
| Camp au niveau 3 | 2189 | 4894 | 56 % |
| Boutique, Kiosque et Snack | 2183 | 721 | 8 % |
| 4 points de publicité | 2099 | 2624 | 31 % |
| 1 label obtenu | 2175 | 253 | 3 % |

## Bonus de nuit

Joueurs ayant choisi ce bonus au moins une fois (le premier en influence choisit).

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Semaine des Amériques (Attractivité des animaux d'Amérique ×1,5) | 3778 | 40 % | 23 % | +16 pts | 91 | 74 |
| Festival des oiseaux (Attractivité des animaux aériens ×1,5) | 4887 | 39 % | 23 % | +16 pts | 91 | 74 |
| Campagne d'affichage (+20 % de visiteurs le soir) | 7859 | 38 % | 22 % | +16 pts | 90 | 72 |
| Semaine de l'Afrique (Attractivité des animaux d'Afrique ×1,4) | 3342 | 38 % | 24 % | +15 pts | 91 | 75 |
| Semaine de l'Europe (Attractivité des animaux d'Europe ×1,4) | 3658 | 37 % | 24 % | +13 pts | 90 | 75 |
| Journée de l'océan (Attractivité des animaux aquatiques ×1,5) | 2429 | 37 % | 24 % | +12 pts | 89 | 75 |
| Semaine de l'Asie (Attractivité des animaux d'Asie ×1,5) | 2842 | 36 % | 24 % | +11 pts | 89 | 75 |
| Scies neuves (+30 % d'extraction de bois) | 8343 | 32 % | 23 % | +8 pts | 84 | 74 |
| Pioches renforcées (+30 % d'extraction de pierre) | 8340 | 32 % | 23 % | +8 pts | 84 | 74 |
| Carnet d'adresses (+50 % de lobbying) | 8668 | 31 % | 23 % | +8 pts | 84 | 74 |
| Engins de terrassement (+40 % d'aménagement du terrain) | 5544 | 31 % | 24 % | +7 pts | 84 | 75 |
| Échafaudages (+25 % de construction) | 7921 | 30 % | 24 % | +6 pts | 83 | 74 |
| Brouettes (+20 % de vitesse de déplacement) | 6267 | 30 % | 24 % | +6 pts | 83 | 75 |
| Lampes de mineur (+40 % d'extraction d'or) | 4391 | 25 % | 25 % | ≈ +0 pts | 79 | 76 |

## Taille du parc

Agrandissements terminés et surface de l'enceinte en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Parc de 450 cases et plus | 4238 | 50 % | 22 % | +28 pts | 99 | 73 |
| Parc agrandi 2 fois et plus | 3492 | 51 % | 22 % | +28 pts | 99 | 74 |
| Parc agrandi 1 fois | 9705 | 29 % | 24 % | +5 pts | 82 | 74 |
| Beauté du parc : aucune décoration | 37018 | 25 % | 23 % | +2 pts | 76 | 79 |
| Parc de 250 à 449 cases | 18590 | 26 % | 24 % | +1 pts | 77 | 75 |
| Beauté du parc : 6 décorations et plus | 1071 | 24 % | 25 % | ≈ -1 pts | 81 | 76 |
| Beauté du parc : 1 à 5 décorations | 1911 | 23 % | 25 % | ≈ -2 pts | 78 | 76 |
| Parc de moins de 250 cases | 17172 | 18 % | 30 % | -12 pts | 69 | 81 |
| Parc agrandi jamais | 26803 | 20 % | 35 % | -14 pts | 71 | 87 |

## Cartes à usage unique et cadres joués

Joueurs ayant joué cette carte au moins une fois.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Accusation (Journaliste) | 359 | 56 % | 25 % | +31 pts | 105 | 76 |
| Portes ouvertes | 6559 | 39 % | 22 % | +17 pts | 93 | 73 |
| Cabinet de recrutement | 1182 | 35 % | 25 % | +10 pts | 93 | 75 |
| Agence d'intérim | 1329 | 34 % | 25 % | +10 pts | 90 | 75 |
| Heures sup | 9871 | 32 % | 23 % | +9 pts | 84 | 73 |
| Recrutement express | 7942 | 32 % | 23 % | +9 pts | 84 | 74 |
| Formation express | 4465 | 32 % | 24 % | +8 pts | 87 | 75 |
| Livraison | 3763 | 32 % | 24 % | +8 pts | 89 | 75 |
| Prime | 8045 | 31 % | 23 % | +7 pts | 84 | 74 |
| Article de presse (Journaliste) | 2470 | 31 % | 25 % | +7 pts | 88 | 75 |
| Promotion | 9219 | 30 % | 23 % | +7 pts | 82 | 74 |
| Rupture de contrat | 10292 | 28 % | 24 % | +5 pts | 81 | 74 |
| Lobbyiste joué (Coup de fil) | 3791 | 28 % | 25 % | +4 pts | 83 | 75 |
| DRH joué (Mutation) | 4966 | 28 % | 25 % | +3 pts | 80 | 75 |
| Animateur joué (Grand spectacle) | 3724 | 24 % | 25 % | ≈ -1 pts | 78 | 76 |
| Architecte joué (Plan d'urgence) | 3029 | 22 % | 25 % | -4 pts | 74 | 76 |
| Formateur joué (Stage de remise à niveau) | 5450 | 22 % | 26 % | -4 pts | 74 | 76 |
| Contremaître joué (Cadence) | 3793 | 21 % | 25 % | -5 pts | 73 | 76 |
| Marchand joué (Négoce) | 1269 | 20 % | 25 % | -5 pts | 74 | 76 |
| Journée de carte cédée (+4) | 14220 | 18 % | 29 % | -11 pts | 69 | 80 |
| Vendeur de souvenirs joué (Braderie) | 27 | 7 % | 25 % | -18 pts | 51 | 76 |

### Effet immédiat des cartes sur la réputation gagnée

Réputation gagnée le jour où la carte est jouée, comparée à la veille. La réputation monte naturellement chaque jour : à comparer d'une carte à l'autre plutôt qu'à zéro. « Tard » : à partir du jour 8.

| Carte | Coût | Jouée | Gain du jour | Veille | Écart | Tard : gain | Tard : veille | Tard : écart |
|---|---|---|---|---|---|---|---|---|
| Accusation (Journaliste) | — | 411 | 25.4 | 17.9 | +7.5 | 25.4 | 17.9 | +7.5 (411) |
| Recrutement express | 8 | 9305 | 13.8 | 10.0 | +3.7 | 16.3 | 11.9 | +4.4 (7509) |
| Portes ouvertes | 14 | 7818 | 17.5 | 13.2 | +4.3 | 18.2 | 13.9 | +4.3 (7272) |
| Cabinet de recrutement | — | 1685 | 16.4 | 12.2 | +4.2 | 16.4 | 12.3 | +4.2 (1665) |
| Animateur joué (Grand spectacle) | — | 8720 | 9.6 | 5.5 | +4.1 | 11.0 | 7.1 | +3.9 (5049) |
| Article de presse (Journaliste) | — | 2908 | 16.9 | 13.1 | +3.8 | 17.0 | 13.3 | +3.8 (2853) |
| Agence d'intérim | — | 2042 | 17.0 | 14.3 | +2.8 | 17.1 | 14.3 | +2.8 (2022) |
| Formation express | 14 | 4894 | 14.9 | 12.7 | +2.2 | 16.6 | 14.2 | +2.5 (4289) |
| DRH joué (Mutation) | — | 9593 | 8.7 | 6.6 | +2.0 | 11.8 | 9.4 | +2.4 (5379) |
| Prime | 10 | 9561 | 12.8 | 10.6 | +2.1 | 14.6 | 12.2 | +2.4 (7987) |
| Journée de carte cédée (+4) | — | 35831 | 2.1 | 1.3 | +0.8 | 3.6 | 1.5 | +2.1 (9485) |
| Vendeur de souvenirs joué (Braderie) | — | 32 | 3.3 | 1.3 | +2.0 | 3.4 | 1.4 | +2.0 (30) |
| Rupture de contrat | 3 | 12742 | 10.6 | 9.0 | +1.6 | 12.5 | 10.8 | +1.7 (9609) |
| Heures sup | 8 | 12263 | 11.6 | 10.2 | +1.4 | 13.8 | 12.2 | +1.6 (9847) |
| Contremaître joué (Cadence) | — | 10431 | 5.1 | 4.2 | +0.9 | 10.6 | 9.0 | +1.5 (3924) |
| Formateur joué (Stage de remise à niveau) | — | 22087 | 5.5 | 4.6 | +0.9 | 10.0 | 8.6 | +1.4 (9504) |
| Lobbyiste joué (Coup de fil) | — | 6878 | 7.5 | 6.5 | +1.0 | 10.5 | 9.3 | +1.3 (3847) |
| Promotion | 8 | 11145 | 10.9 | 10.2 | +0.7 | 13.0 | 12.2 | +0.8 (8912) |
| Livraison | 25 | 4130 | 14.5 | 13.8 | +0.7 | 14.7 | 14.0 | +0.7 (4020) |
| Marchand joué (Négoce) | — | 1441 | 1.7 | 1.5 | +0.2 | 7.6 | 7.0 | +0.6 (186) |
| Architecte joué (Plan d'urgence) | — | 5000 | 7.2 | 7.1 | +0.1 | 10.7 | 10.4 | +0.2 (3096) |

## Animaux

Taux d'achat : achats par nuit passée au marché. Un rare est naturellement moins acheté : il coûte très cher.

| Espèce | Continent | Rareté | Nuits au marché | Achats | Taux d'achat | Jour moyen d'achat | Installée | Victoires avec | Écart |
|---|---|---|---|---|---|---|---|---|---|
| Hyène tachetée | Afrique | Commun | 14235 | 8145 | 57 % | 5.7 | 7399 | 37 % | +14 pts |
| Ocelot | Amérique | Commun | 14596 | 8122 | 56 % | 5.8 | 7408 | 36 % | +14 pts |
| Cerf élaphe | Europe | Commun | 15289 | 7886 | 52 % | 5.9 | 7181 | 32 % | +9 pts |
| Faucon pèlerin | Europe | Commun | 15516 | 7936 | 51 % | 5.8 | 7082 | 33 % | +10 pts |
| Bison d'Amérique | Amérique | Commun | 16046 | 7831 | 49 % | 5.8 | 7170 | 32 % | +9 pts |
| Ara rouge | Amérique | Commun | 16968 | 7751 | 46 % | 6.0 | 6788 | 34 % | +10 pts |
| Messager sagittaire | Afrique | Commun | 16950 | 7700 | 45 % | 6.0 | 7018 | 32 % | +8 pts |
| Zèbre | Afrique | Commun | 17588 | 7703 | 44 % | 6.1 | 6973 | 32 % | +8 pts |
| Bouquetin des Alpes | Europe | Commun | 17628 | 7582 | 43 % | 6.0 | 6761 | 32 % | +9 pts |
| Mésange charbonnière | Europe | Commun | 18788 | 7576 | 40 % | 6.1 | 6824 | 31 % | +8 pts |
| Grue du Japon | Asie | Commun | 20085 | 7305 | 36 % | 6.2 | 6403 | 32 % | +8 pts |
| Grue couronnée | Afrique | Commun | 20258 | 7222 | 36 % | 6.2 | 6311 | 32 % | +8 pts |
| Phoque gris | Europe | Commun | 20881 | 7306 | 35 % | 6.3 | 6432 | 32 % | +9 pts |
| Calao bicorne | Asie | Commun | 22217 | 7090 | 32 % | 6.3 | 6215 | 30 % | +6 pts |
| Tapir de Baird | Amérique | Commun | 22305 | 6976 | 31 % | 6.3 | 6060 | 32 % | +8 pts |
| Salamandre géante | Asie | Commun | 22857 | 6963 | 30 % | 6.3 | 5971 | 30 % | +6 pts |
| Carpe koï | Asie | Commun | 23199 | 6846 | 30 % | 6.4 | 5889 | 29 % | +4 pts |
| Yak | Asie | Commun | 24384 | 6312 | 26 % | 6.2 | 5640 | 28 % | +3 pts |
| Loutre à joues blanches | Afrique | Commun | 28856 | 5761 | 20 % | 6.5 | 4918 | 28 % | +4 pts |
| Loutre cendrée | Asie | Peu commun | 8475 | 1321 | 16 % | 8.8 | 1014 | 42 % | +18 pts |
| Paon bleu | Asie | Peu commun | 8571 | 1299 | 15 % | 8.9 | 936 | 40 % | +15 pts |
| Lynx boréal | Europe | Peu commun | 8898 | 1256 | 14 % | 9.1 | 892 | 42 % | +18 pts |
| Capybara | Amérique | Peu commun | 9094 | 1228 | 14 % | 9.0 | 947 | 43 % | +18 pts |
| Girafe | Afrique | Peu commun | 9497 | 1151 | 12 % | 9.3 | 799 | 45 % | +20 pts |
| Alligator américain | Amérique | Peu commun | 9319 | 1116 | 12 % | 9.3 | 741 | 47 % | +22 pts |
| Guépard | Afrique | Peu commun | 9802 | 1135 | 12 % | 9.0 | 873 | 48 % | +23 pts |
| Manchot du Cap | Afrique | Peu commun | 9539 | 1082 | 11 % | 9.2 | 717 | 39 % | +14 pts |
| Jaguar | Amérique | Peu commun | 9806 | 1071 | 11 % | 9.3 | 693 | 44 % | +19 pts |
| Loup gris | Europe | Peu commun | 9757 | 1033 | 11 % | 9.3 | 684 | 41 % | +16 pts |
| Puma | Amérique | Peu commun | 9926 | 1033 | 10 % | 9.2 | 714 | 43 % | +18 pts |
| Léopard des neiges | Asie | Peu commun | 9927 | 1018 | 10 % | 9.4 | 671 | 40 % | +15 pts |
| Loutre d'Europe | Europe | Peu commun | 10271 | 1003 | 10 % | 9.0 | 719 | 39 % | +14 pts |
| Dauphin rose de l'Amazone | Amérique | Rare | 15224 | 501 | 3 % | 10.2 | 262 | 48 % | +24 pts |
| Pygargue à tête blanche | Amérique | Rare | 15467 | 490 | 3 % | 10.2 | 252 | 48 % | +23 pts |
| Hippopotame | Afrique | Rare | 14597 | 457 | 3 % | 10.2 | 268 | 46 % | +21 pts |
| Lion | Afrique | Rare | 15766 | 463 | 3 % | 10.1 | 278 | 50 % | +26 pts |
| Bison d'Europe | Europe | Rare | 15346 | 447 | 3 % | 10.0 | 272 | 54 % | +29 pts |
| Aigle royal | Europe | Rare | 15378 | 412 | 3 % | 10.2 | 224 | 50 % | +25 pts |
| Tigre du Bengale | Asie | Rare | 15363 | 378 | 2 % | 10.3 | 195 | 49 % | +24 pts |
| Panda géant | Asie | Rare | 15741 | 347 | 2 % | 10.3 | 198 | 41 % | +16 pts |

## Continents

Selon le nombre d'espèces de ce continent en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Amerique (3 espèces et plus) | 1591 | 57 % | 24 % | +33 pts | 103 | 75 |
| Europe (3 espèces et plus) | 2570 | 51 % | 23 % | +28 pts | 100 | 74 |
| Afrique (3 espèces et plus) | 2411 | 50 % | 23 % | +27 pts | 100 | 74 |
| Asie (3 espèces et plus) | 2444 | 42 % | 24 % | +18 pts | 96 | 75 |
| Amerique (1 ou 2 espèces) | 20141 | 29 % | 21 % | +8 pts | 82 | 70 |
| Afrique (1 ou 2 espèces) | 21018 | 27 % | 22 % | +5 pts | 81 | 71 |
| Europe (1 ou 2 espèces) | 21698 | 27 % | 23 % | +3 pts | 80 | 72 |
| Asie (1 ou 2 espèces) | 19149 | 26 % | 24 % | +2 pts | 79 | 73 |

## Types d'animaux

Selon le nombre d'espèces de ce type en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| predateur (3 espèces et plus) | 284 | 65 % | 25 % | +41 pts | 108 | 76 |
| herbivore (3 espèces et plus) | 2857 | 44 % | 23 % | +21 pts | 97 | 74 |
| aerien (3 espèces et plus) | 4277 | 43 % | 23 % | +20 pts | 96 | 74 |
| aquatique (3 espèces et plus) | 1014 | 42 % | 25 % | +17 pts | 96 | 75 |
| predateur (1 ou 2 espèces) | 16171 | 35 % | 18 % | +17 pts | 87 | 68 |
| aquatique (1 ou 2 espèces) | 18830 | 29 % | 21 % | +8 pts | 82 | 71 |
| herbivore (1 ou 2 espèces) | 24560 | 27 % | 21 % | +6 pts | 80 | 70 |
| aerien (1 ou 2 espèces) | 24873 | 27 % | 22 % | +4 pts | 79 | 71 |

## Raretés

Selon les animaux installés en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Rare installés (2 et plus) | 114 | 68 % | 25 % | +43 pts | 112 | 76 |
| Peu commun installés (2 et plus) | 1468 | 56 % | 24 % | +32 pts | 104 | 75 |
| Commun installés (2 et plus) | 33416 | 29 % | 6 % | +23 pts | 82 | 45 |
| Rare installé (1) | 1717 | 46 % | 24 % | +22 pts | 99 | 75 |
| Peu commun installé (1) | 7319 | 37 % | 22 % | +15 pts | 90 | 73 |
| Commun installé (1) | 5919 | 6 % | 28 % | -22 pts | 47 | 81 |

## D'où vient la réputation

- beaute : 0 %
- boutique : 6 %
- frequentation : 64 %
- legendaires : 1 %
- objectifs : 10 %
- prestige : 14 %
- spectacles : 3 %
- labels : 0 %
