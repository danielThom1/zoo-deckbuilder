# Étude du jeu par l'IA qui apprend

3312 parties sur 5000 jouées (étude en cours), 288 min de calcul. Fin de partie en moyenne au jour 14.3.
Record : victoire au jour 9 (107 de réputation, graine 675706189).

**Comment lire les tableaux** : « Victoires avec » est le taux de victoire des joueurs qui avaient cet élément en fin de partie, « sans » celui des autres. Un écart positif veut dire que l'élément accompagne la victoire, sans le prouver : un joueur qui gagne a aussi plus d'ouvriers, de bâtiments et d'animaux. « ≈ » signale un écart trop faible pour conclure, compte tenu du nombre de parties.

## En bref : forts et faibles

Écart de victoires en points, seulement quand il est significatif, et hors éléments presque absents ou présents chez presque tous. Les bâtiments et les améliorations communes sont faussés : un joueur qui dure en a davantage.

- **Traits** : forts : Charismatique (+6), Économe (+4), Rapide (+3), Bon élève (+3), Endurant (+2) ; faibles : Gourmand (-5), Rabat-joie (-4), Paresseux (-3), Col blanc (-3), Lent (-3).
- **Métiers** : forts : Paysagiste (+7), Lobbyiste (+6), Animateur (+4), Terrassier (+4), DRH (+4) ; faibles : Journaliste (-8), Maçon (-2), Guichetier (-2).
- **Améliorations** : forts : Visionnaire (+7), Expérience (+5), Devenir Terrassier (+3), Pied léger (+3), Révélation (+2) ; faibles : Devenir Guichetier (-4), Devenir Porteur (-4), Devenir Maçon (-4).
- **Cartes** : forts : Agence d'intérim (+18), Portes ouvertes (+14), Cabinet de recrutement (+14), Article de presse (Journaliste) (+11), Livraison (+9) ; faibles : Contremaître joué (Cadence) (-2).
- **Animaux** : forts : Paon bleu (+27), Ocelot (+16), Hyène tachetée (+16), Messager sagittaire (+13), Bison d'Amérique (+13) ; faibles : aucun net.
- **Bâtiments** : forts : Cuisine des animaux (+26), Kiosque d'animation (+25), Local d'entretien (+25), Grand arbre (+21), Camp niveau 3 (+21) ; faibles : Entrepôt (-11), Mine d'or (-9), Centre de formation (-7), Marché (-3).
- **Bonus de nuit** : forts : Campagne d'affichage (+20 % de visiteurs le soir) (+18), Semaine des Amériques (Attractivité des animaux d'Amérique ×1,5) (+18), Festival des oiseaux (Attractivité des animaux aériens ×1,5) (+18), Semaine de l'Afrique (Attractivité des animaux d'Afrique ×1,4) (+15), Semaine de l'Asie (Attractivité des animaux d'Asie ×1,5) (+14) ; faibles : aucun net.

## Stratégies apprises

| Génération | Victoires de la meilleure | Jour moyen | Réputation | Moyenne de la population |
|---|---|---|---|---|
| 1 | 58 % | 16.3 | 97 | 25 % |
| 5 | 50 % | 16.2 | 89 | 25 % |
| 9 | 58 % | 13.3 | 91 | 25 % |
| 13 | 58 % | 13.7 | 96 | 25 % |
| 17 | 50 % | 12.7 | 93 | 25 % |
| 21 | 67 % | 13.1 | 102 | 25 % |
| 25 | 58 % | 13.3 | 92 | 25 % |
| 29 | 67 % | 13.0 | 96 | 25 % |
| 33 | 67 % | 12.0 | 102 | 25 % |
| 37 | 42 % | 14.8 | 91 | 24 % |
| 41 | 67 % | 13.4 | 87 | 25 % |
| 45 | 58 % | 14.9 | 84 | 25 % |
| 49 | 58 % | 12.4 | 93 | 25 % |
| 53 | 67 % | 12.4 | 101 | 25 % |
| 57 | 58 % | 13.9 | 101 | 25 % |
| 61 | 58 % | 13.9 | 92 | 25 % |
| 65 | 58 % | 14.0 | 86 | 25 % |
| 69 | 50 % | 13.8 | 90 | 24 % |

1. parc moyen, palier 2.6, réserve 0, lobby 0, camp 1, contrats 1, marche, route_mine, sans adaptatif, sans agrandir
2. parc moyen, palier 2.4, réserve 2, lobby 0, camp 2, contrats 3, sans adaptatif
3. parc moyen, palier 2.6, réserve 0, lobby 1, camp 1, contrats 1, marche, spectacle, sans adaptatif, sans agrandir
4. parc moyen, palier 2.3, réserve 0, lobby 0, camp 2, contrats 2, sans adaptatif

Réglages retenus par les 8 meilleures : marche 6/8, rush_or 0/8, formation 0/8, cartes 0/8, spectacle 2/8, affinite 0/8, boutique 3/8, mine 1/8, specialisation 0/8, fast_expand 0/8, route_mine 1/8, adaptatif 0/8, agrandir 6/8, meme_type 0/8.

**Métiers, des plus recherchés aux plus évités par les IA qui gagnent** : Charpentier +1.7, Formateur +1.3, Architecte +0.9, Mineur +0.8, Terrassier +0.7, Animalier +0.6, Bûcheron +0.6, Porteur +0.5, Maçon +0.5, Agent d'entretien +0.3, DRH +0.2, Paysagiste +0.1, Manœuvre -0.1, Cantonnier -0.1, Marchand -0.2, Vendeur de souvenirs -0.3, Soigneur -0.3, Contremaître -0.4, Animateur -0.5, Guichetier -1.1, Lobbyiste -1.5, Apprenti -1.6, Journaliste -1.8.

**Traits, des plus recherchés aux plus évités par les IA qui gagnent** : Charismatique +1.7, Rapide +1.1, Économe +0.8, Bon élève +0.8, Casanier +0.5, Têtu +0.4, Distrait +0.4, Lent +0.2, Endurant +0.1, Matinal -0.1, Paresseux -0.2, Maladroit -0.4, Naturaliste -0.5, Débrouillard -0.5, Polyvalent -0.8, Peureux -0.8, Gourmand -0.9, Col blanc -1.1, Costaud -1.1, Rabat-joie -1.3.

**Animaux, des plus recherchés aux plus évités par les IA qui gagnent** : Loutre à joues blanches +2.0, Grue couronnée +1.8, Manchot du Cap +1.8, Yak +1.6, Ocelot +1.0, Puma +1.0, Léopard des neiges +0.9, Lynx boréal +0.8, Jaguar +0.6, Bouquetin des Alpes +0.6, Bison d'Amérique +0.5, Capybara +0.5, Guépard +0.5, Cerf élaphe +0.5, Mésange charbonnière +0.4, Loutre cendrée +0.4, Bison d'Europe +0.3, Dauphin rose de l'Amazone +0.3, Messager sagittaire +0.3, Zèbre +0.1, Tapir de Baird +0.1, Girafe +0.1, Lion -0.1, Grue du Japon -0.2, Aigle royal -0.3, Faucon pèlerin -0.3, Loup gris -0.3, Hippopotame -0.3, Panda géant -0.5, Carpe koï -0.5, Pygargue à tête blanche -0.6, Paon bleu -0.7, Phoque gris -0.7, Ara rouge -0.9, Hyène tachetée -0.9, Tigre du Bengale -1.2, Salamandre géante -1.2, Loutre d'Europe -1.2, Alligator américain -1.3, Calao bicorne -1.5.

**Cartes, des plus recherchés aux plus évités par les IA qui gagnent** : Portes ouvertes +0.7, Heures sup +0.4, Livraison +0.2, Recrutement express -0.1, Prime -0.2, Formation express -0.6, Promotion -0.9, Rupture de contrat -1.0.

**Améliorations, des plus recherchés aux plus évités par les IA qui gagnent** : Remise en question +1.1, Pédagogue +0.9, Chasseur de têtes +0.6, Expérience +0.5, Négociateur +0.2, Visionnaire -0.0, Maîtrise -0.1, Fidélité -0.1, Scie affûtée -0.4, Révélation -0.4, Pied léger -0.5, Brouette -0.5, Seconde spécialité -0.7, Réseau -1.9.

## Traits des ouvriers

Joueurs ayant au moins un ouvrier avec ce trait. Défauts et qualités sont tirés au draft, mais l'IA choisit ses cartes : les traits les plus visibles sont en partie évités.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Charismatique | 9455 | 27 % | 21 % | +6 pts | 75 | 67 |
| Économe | 8847 | 26 % | 22 % | +4 pts | 74 | 69 |
| Rapide | 8724 | 26 % | 23 % | +3 pts | 74 | 69 |
| Bon élève | 8555 | 26 % | 23 % | +3 pts | 74 | 70 |
| Endurant | 8295 | 26 % | 23 % | +2 pts | 74 | 70 |
| Matinal | 8770 | 26 % | 24 % | +2 pts | 73 | 71 |
| Naturaliste | 8235 | 25 % | 24 % | ≈ +1 pts | 73 | 71 |
| Costaud | 7992 | 25 % | 24 % | ≈ +1 pts | 73 | 72 |
| Polyvalent | 7434 | 25 % | 25 % | ≈ +1 pts | 73 | 72 |
| Casanier | 5998 | 25 % | 25 % | ≈ +0 pts | 72 | 73 |
| Débrouillard | 7344 | 25 % | 25 % | ≈ -1 pts | 72 | 72 |
| Têtu | 6100 | 24 % | 25 % | ≈ -1 pts | 71 | 74 |
| Distrait | 5710 | 24 % | 25 % | ≈ -1 pts | 71 | 73 |
| Maladroit | 4979 | 23 % | 26 % | -3 pts | 70 | 74 |
| Peureux | 5245 | 23 % | 26 % | -3 pts | 70 | 74 |
| Lent | 5111 | 23 % | 26 % | -3 pts | 70 | 74 |
| Col blanc | 1019 | 22 % | 25 % | -3 pts | 72 | 72 |
| Paresseux | 5602 | 23 % | 26 % | -3 pts | 70 | 74 |
| Rabat-joie | 3820 | 22 % | 26 % | -4 pts | 68 | 74 |
| Gourmand | 4803 | 22 % | 27 % | -5 pts | 68 | 75 |

## Métiers

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Paysagiste | 8370 | 28 % | 20 % | +7 pts | 76 | 67 |
| Lobbyiste | 1943 | 30 % | 24 % | +6 pts | 82 | 71 |
| Animateur | 1941 | 29 % | 24 % | +4 pts | 78 | 71 |
| Terrassier | 6831 | 27 % | 23 % | +4 pts | 74 | 70 |
| DRH | 1974 | 28 % | 24 % | +4 pts | 76 | 72 |
| Charpentier | 7629 | 26 % | 23 % | +4 pts | 74 | 70 |
| Vendeur de souvenirs | 1814 | 27 % | 25 % | +3 pts | 75 | 72 |
| Marchand | 2156 | 27 % | 24 % | +3 pts | 76 | 72 |
| Cantonnier | 7337 | 26 % | 23 % | +3 pts | 74 | 70 |
| Contremaître | 2104 | 27 % | 25 % | +2 pts | 75 | 72 |
| Animalier | 7344 | 25 % | 24 % | ≈ +1 pts | 73 | 72 |
| Manœuvre | 325 | 26 % | 25 % | ≈ +1 pts | 71 | 72 |
| Formateur | 2240 | 25 % | 25 % | ≈ +1 pts | 74 | 72 |
| Porteur | 5611 | 25 % | 25 % | ≈ +0 pts | 72 | 73 |
| Bûcheron | 5531 | 25 % | 25 % | ≈ +0 pts | 72 | 73 |
| Apprenti | 223 | 24 % | 25 % | ≈ -1 pts | 70 | 72 |
| Soigneur | 6641 | 25 % | 25 % | ≈ -1 pts | 73 | 72 |
| Mineur | 5984 | 24 % | 25 % | ≈ -1 pts | 72 | 73 |
| Architecte | 1877 | 24 % | 25 % | ≈ -1 pts | 72 | 72 |
| Agent d'entretien | 5323 | 24 % | 25 % | ≈ -1 pts | 70 | 74 |
| Guichetier | 4432 | 24 % | 25 % | -2 pts | 69 | 74 |
| Maçon | 5968 | 24 % | 26 % | -2 pts | 71 | 74 |
| Journaliste | 1515 | 17 % | 26 % | -8 pts | 64 | 74 |

## Améliorations

Choisies 25 % du temps au hasard pendant l'apprentissage, pour que toutes soient essayées.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Visionnaire | 3283 | 30 % | 23 % | +7 pts | 77 | 71 |
| Expérience | 12460 | 25 % | 20 % | +5 pts | 73 | 66 |
| Réseau | 527 | 28 % | 25 % | ≈ +4 pts | 84 | 72 |
| Devenir Terrassier | 839 | 28 % | 25 % | +3 pts | 75 | 72 |
| Pied léger | 10861 | 25 % | 23 % | +3 pts | 73 | 70 |
| Maîtrise | 13230 | 25 % | 22 % | ≈ +3 pts | 72 | 68 |
| Révélation | 9613 | 25 % | 23 % | +2 pts | 73 | 70 |
| Devenir Mineur | 810 | 27 % | 25 % | ≈ +2 pts | 72 | 72 |
| Devenir Paysagiste | 998 | 27 % | 25 % | ≈ +2 pts | 74 | 72 |
| Chasseur de têtes | 582 | 27 % | 25 % | ≈ +2 pts | 76 | 72 |
| Seconde spécialité : Extraction de pierre | 1839 | 27 % | 25 % | ≈ +2 pts | 74 | 72 |
| Remise en question | 13163 | 25 % | 24 % | ≈ +1 pts | 72 | 69 |
| Brouette | 1994 | 26 % | 25 % | ≈ +1 pts | 73 | 72 |
| Seconde spécialité : Construction en pierre | 1876 | 26 % | 25 % | ≈ +1 pts | 74 | 72 |
| Seconde spécialité : Construction en bois | 1737 | 26 % | 25 % | ≈ +1 pts | 74 | 72 |
| Seconde spécialité : Extraction de bois | 1920 | 26 % | 25 % | ≈ +1 pts | 73 | 72 |
| Négociateur | 640 | 26 % | 25 % | ≈ +1 pts | 77 | 72 |
| Seconde spécialité : Guichet | 1921 | 26 % | 25 % | ≈ +1 pts | 74 | 72 |
| Seconde spécialité : Clôtures d'enclos | 1620 | 25 % | 25 % | ≈ +1 pts | 73 | 72 |
| Fidélité | 10649 | 25 % | 24 % | ≈ +1 pts | 73 | 70 |
| Scie affûtée | 2393 | 25 % | 25 % | ≈ +0 pts | 73 | 72 |
| Devenir Cantonnier | 1075 | 25 % | 25 % | ≈ +0 pts | 73 | 72 |
| Seconde spécialité : Routes | 1817 | 24 % | 25 % | ≈ -1 pts | 73 | 72 |
| Devenir Animalier | 1659 | 24 % | 25 % | ≈ -1 pts | 72 | 73 |
| Devenir Soigneur | 1048 | 24 % | 25 % | ≈ -1 pts | 73 | 72 |
| Devenir Bûcheron | 717 | 23 % | 25 % | ≈ -2 pts | 70 | 73 |
| Devenir Agent d'entretien | 671 | 23 % | 25 % | ≈ -2 pts | 68 | 73 |
| Devenir Charpentier | 1046 | 23 % | 25 % | ≈ -2 pts | 71 | 73 |
| Pédagogue | 307 | 21 % | 25 % | ≈ -3 pts | 74 | 72 |
| Devenir Maçon | 753 | 22 % | 25 % | -4 pts | 69 | 73 |
| Devenir Porteur | 733 | 21 % | 25 % | -4 pts | 71 | 73 |
| Devenir Guichetier | 619 | 21 % | 25 % | -4 pts | 67 | 73 |

## Bâtiments

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Cuisine des animaux | 12480 | 26 % | 0 % | +26 pts | 75 | 26 |
| Kiosque d'animation | 9534 | 32 % | 7 % | +25 pts | 82 | 47 |
| Entrée du zoo | 13149 | 25 % | 0 % | +25 pts | 73 | 27 |
| Local d'entretien | 11833 | 28 % | 3 % | +25 pts | 77 | 35 |
| Grand arbre | 1296 | 44 % | 23 % | +21 pts | 90 | 71 |
| Camp niveau 3 | 5450 | 37 % | 16 % | +21 pts | 85 | 63 |
| Bassin profond | 852 | 43 % | 24 % | +19 pts | 90 | 71 |
| Rocher d'observation | 1613 | 41 % | 23 % | +19 pts | 88 | 70 |
| Camp niveau 2 | 10567 | 28 % | 12 % | +17 pts | 76 | 59 |
| Abri chauffé | 287 | 41 % | 25 % | +16 pts | 87 | 72 |
| Agence d'intérim | 1487 | 32 % | 24 % | +8 pts | 82 | 71 |
| Snack | 2056 | 32 % | 24 % | +8 pts | 83 | 71 |
| Boutique de souvenirs | 5444 | 29 % | 22 % | +8 pts | 78 | 68 |
| Maison du personnel | 12350 | 25 % | 19 % | +7 pts | 73 | 64 |
| Cabinet de recrutement | 2196 | 30 % | 24 % | +6 pts | 80 | 71 |
| Marché | 6890 | 24 % | 26 % | -3 pts | 73 | 72 |
| Centre de formation | 1542 | 19 % | 26 % | -7 pts | 67 | 73 |
| Mine d'or | 3897 | 19 % | 27 % | -9 pts | 69 | 74 |
| Entrepôt | 5626 | 19 % | 29 % | -11 pts | 66 | 77 |

## Labels

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| certifie | 398 | 18 % | 25 % | -8 pts | 71 | 72 |
| mecenat | 158 | 12 % | 25 % | -13 pts | 68 | 72 |
| excellence | 74 | 7 % | 25 % | -18 pts | 63 | 72 |

## Objectifs remplis

Joueurs ayant rempli cet objectif. Le taux de réussite est dans le tableau suivant.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| 5 espèces installées | 175 | 78 % | 24 % | +54 pts | 109 | 72 |
| 2 animaux peu communs | 104 | 68 % | 25 % | +44 pts | 104 | 72 |
| 3 espèces d'un même continent | 230 | 67 % | 24 % | +43 pts | 104 | 72 |
| 3 espèces d'un même type | 245 | 64 % | 24 % | +40 pts | 101 | 72 |
| 4 points de publicité | 743 | 61 % | 23 % | +39 pts | 103 | 71 |
| 1 animal rare installé | 212 | 56 % | 24 % | +31 pts | 100 | 72 |
| 80 visiteurs en une journée | 1174 | 50 % | 22 % | +28 pts | 96 | 70 |
| Camp au niveau 3 | 1315 | 38 % | 23 % | +15 pts | 87 | 71 |
| 11 collaborateurs | 240 | 40 % | 25 % | +15 pts | 86 | 72 |
| Boutique, Kiosque et Snack | 238 | 34 % | 25 % | +9 pts | 85 | 72 |
| 3 cadres dans l'équipe | 440 | 34 % | 25 % | +9 pts | 83 | 72 |
| Enceinte de 250 cases | 1081 | 30 % | 24 % | +5 pts | 78 | 72 |
| 2 collaborateurs au niveau 4 | 3009 | 25 % | 25 % | ≈ +1 pts | 75 | 72 |
| 1 label obtenu | 83 | 20 % | 25 % | ≈ -4 pts | 75 | 72 |

| Objectif | Parties où il est tiré | Joueurs qui l'ont rempli | Taux de réussite |
|---|---|---|---|
| 3 espèces d'un même continent | 700 | 230 | 8 % |
| 3 espèces d'un même type | 713 | 245 | 9 % |
| 1 animal rare installé | 724 | 212 | 7 % |
| 2 animaux peu communs | 710 | 104 | 4 % |
| 5 espèces installées | 691 | 175 | 6 % |
| Enceinte de 250 cases | 670 | 1081 | 40 % |
| 80 visiteurs en une journée | 696 | 1174 | 42 % |
| 2 collaborateurs au niveau 4 | 764 | 3009 | 98 % |
| 3 cadres dans l'équipe | 730 | 440 | 15 % |
| 11 collaborateurs | 710 | 240 | 8 % |
| Camp au niveau 3 | 755 | 1315 | 44 % |
| Boutique, Kiosque et Snack | 712 | 238 | 8 % |
| 4 points de publicité | 668 | 743 | 28 % |
| 1 label obtenu | 693 | 83 | 3 % |

## Bonus de nuit

Joueurs ayant choisi ce bonus au moins une fois (le premier en influence choisit).

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Campagne d'affichage (+20 % de visiteurs le soir) | 2568 | 39 % | 22 % | +18 pts | 90 | 68 |
| Semaine des Amériques (Attractivité des animaux d'Amérique ×1,5) | 1042 | 41 % | 24 % | +18 pts | 90 | 71 |
| Festival des oiseaux (Attractivité des animaux aériens ×1,5) | 1434 | 41 % | 23 % | +18 pts | 90 | 70 |
| Semaine de l'Afrique (Attractivité des animaux d'Afrique ×1,4) | 1225 | 38 % | 24 % | +15 pts | 89 | 71 |
| Semaine de l'Asie (Attractivité des animaux d'Asie ×1,5) | 1014 | 38 % | 24 % | +14 pts | 87 | 71 |
| Semaine de l'Europe (Attractivité des animaux d'Europe ×1,4) | 1180 | 35 % | 24 % | +11 pts | 88 | 71 |
| Journée de l'océan (Attractivité des animaux aquatiques ×1,5) | 846 | 35 % | 24 % | +11 pts | 86 | 72 |
| Scies neuves (+30 % d'extraction de bois) | 2951 | 32 % | 23 % | +9 pts | 82 | 70 |
| Carnet d'adresses (+50 % de lobbying) | 3513 | 31 % | 23 % | +8 pts | 82 | 69 |
| Échafaudages (+25 % de construction) | 2929 | 31 % | 23 % | +7 pts | 81 | 70 |
| Pioches renforcées (+30 % d'extraction de pierre) | 2927 | 30 % | 23 % | +7 pts | 82 | 70 |
| Engins de terrassement (+40 % d'aménagement du terrain) | 2021 | 31 % | 24 % | +7 pts | 82 | 71 |
| Brouettes (+20 % de vitesse de déplacement) | 2362 | 30 % | 24 % | +7 pts | 82 | 70 |
| Lampes de mineur (+40 % d'extraction d'or) | 1961 | 28 % | 24 % | +4 pts | 81 | 71 |

## Taille du parc

Agrandissements terminés et surface de l'enceinte en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Parc de 450 cases et plus | 501 | 52 % | 24 % | +28 pts | 96 | 72 |
| Parc agrandi 2 fois et plus | 429 | 52 % | 24 % | +28 pts | 95 | 72 |
| Parc agrandi 1 fois | 1701 | 29 % | 24 % | +5 pts | 78 | 72 |
| Parc de 250 à 449 cases | 4799 | 25 % | 25 % | ≈ +0 pts | 71 | 73 |
| Parc de moins de 250 cases | 7948 | 23 % | 28 % | -5 pts | 72 | 74 |
| Parc agrandi jamais | 11118 | 23 % | 34 % | -11 pts | 71 | 81 |

## Cartes à usage unique et cadres joués

Joueurs ayant joué cette carte au moins une fois.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Accusation (Journaliste) | 102 | 57 % | 25 % | +32 pts | 96 | 72 |
| Agence d'intérim | 733 | 42 % | 24 % | +18 pts | 90 | 71 |
| Portes ouvertes | 3561 | 35 % | 21 % | +14 pts | 85 | 68 |
| Cabinet de recrutement | 813 | 38 % | 24 % | +14 pts | 88 | 71 |
| Article de presse (Journaliste) | 579 | 36 % | 24 % | +11 pts | 87 | 72 |
| Livraison | 2318 | 32 % | 23 % | +9 pts | 84 | 70 |
| Heures sup | 4728 | 30 % | 22 % | +8 pts | 80 | 68 |
| Prime | 4290 | 30 % | 22 % | +8 pts | 79 | 69 |
| Formation express | 2432 | 31 % | 24 % | +8 pts | 81 | 71 |
| Recrutement express | 4150 | 30 % | 23 % | +7 pts | 78 | 70 |
| Lobbyiste joué (Coup de fil) | 1310 | 30 % | 24 % | +5 pts | 82 | 71 |
| Rupture de contrat | 4842 | 27 % | 24 % | +3 pts | 76 | 70 |
| Promotion | 4299 | 27 % | 24 % | +3 pts | 77 | 70 |
| Animateur joué (Grand spectacle) | 1318 | 28 % | 25 % | +3 pts | 79 | 72 |
| DRH joué (Mutation) | 1823 | 27 % | 25 % | +3 pts | 75 | 72 |
| Marchand joué (Négoce) | 455 | 27 % | 25 % | ≈ +2 pts | 74 | 72 |
| Formateur joué (Stage de remise à niveau) | 2195 | 24 % | 25 % | ≈ -1 pts | 74 | 72 |
| Architecte joué (Plan d'urgence) | 1076 | 23 % | 25 % | ≈ -2 pts | 73 | 72 |
| Contremaître joué (Cadence) | 1344 | 23 % | 25 % | -2 pts | 72 | 73 |
| Vendeur de souvenirs joué (Braderie) | 18 | 6 % | 25 % | -19 pts | 62 | 72 |

### Effet immédiat des cartes sur la réputation gagnée

Réputation gagnée le jour où la carte est jouée, comparée à la veille. La réputation monte naturellement chaque jour : à comparer d'une carte à l'autre plutôt qu'à zéro. « Tard » : à partir du jour 8.

| Carte | Coût | Jouée | Gain du jour | Veille | Écart | Tard : gain | Tard : veille | Tard : écart |
|---|---|---|---|---|---|---|---|---|
| Accusation (Journaliste) | — | 133 | 17.3 | 13.6 | +3.8 | 17.3 | 13.6 | +3.8 (133) |
| Animateur joué (Grand spectacle) | — | 2844 | 8.7 | 5.2 | +3.5 | 9.3 | 6.0 | +3.3 (1985) |
| Portes ouvertes | 10 | 4640 | 12.4 | 9.2 | +3.2 | 12.7 | 9.5 | +3.2 (4361) |
| Vendeur de souvenirs joué (Braderie) | — | 28 | 3.9 | 1.5 | +2.4 | 3.9 | 1.5 | +2.4 (28) |
| Cabinet de recrutement | — | 1265 | 12.7 | 10.4 | +2.3 | 12.7 | 10.4 | +2.3 (1259) |
| Article de presse (Journaliste) | — | 725 | 13.2 | 10.9 | +2.3 | 13.2 | 10.9 | +2.3 (718) |
| Recrutement express | 8 | 5347 | 9.4 | 7.4 | +2.0 | 10.8 | 8.6 | +2.2 (4424) |
| Formation express | 14 | 2862 | 11.1 | 9.2 | +1.9 | 11.9 | 9.9 | +2.0 (2602) |
| Agence d'intérim | — | 1228 | 13.8 | 12.0 | +1.8 | 13.8 | 12.0 | +1.8 (1223) |
| DRH joué (Mutation) | — | 4875 | 4.0 | 3.3 | +0.7 | 9.1 | 8.0 | +1.1 (1436) |
| Prime | 10 | 5682 | 8.6 | 7.8 | +0.8 | 9.7 | 8.8 | +0.9 (4853) |
| Contremaître joué (Cadence) | — | 3998 | 4.4 | 3.9 | +0.6 | 8.1 | 7.2 | +0.9 (1747) |
| Marchand joué (Négoce) | — | 533 | 3.1 | 2.7 | +0.4 | 7.0 | 6.4 | +0.6 (187) |
| Rupture de contrat | 3 | 6582 | 6.8 | 6.3 | +0.6 | 8.8 | 8.2 | +0.6 (4645) |
| Lobbyiste joué (Coup de fil) | — | 2451 | 6.4 | 5.9 | +0.4 | 8.1 | 7.6 | +0.6 (1570) |
| Formateur joué (Stage de remise à niveau) | — | 8966 | 5.0 | 4.6 | +0.5 | 7.7 | 7.2 | +0.5 (4876) |
| Heures sup | 8 | 6599 | 8.0 | 7.6 | +0.4 | 9.3 | 8.9 | +0.4 (5396) |
| Promotion | 8 | 5510 | 7.5 | 7.4 | +0.1 | 8.7 | 8.6 | +0.1 (4514) |
| Livraison | 25 | 2780 | 9.6 | 9.7 | -0.1 | 9.8 | 9.8 | -0.1 (2700) |
| Architecte joué (Plan d'urgence) | — | 2011 | 6.1 | 6.3 | -0.3 | 8.0 | 8.4 | -0.4 (1439) |

## Animaux

Taux d'achat : achats par nuit passée au marché. Un rare est naturellement moins acheté : il coûte très cher.

| Espèce | Continent | Rareté | Nuits au marché | Achats | Taux d'achat | Jour moyen d'achat | Installée | Victoires avec | Écart |
|---|---|---|---|---|---|---|---|---|---|
| Zèbre | Afrique | Commun | 5457 | 1810 | 33 % | 5.7 | 1573 | 36 % | +12 pts |
| Bison d'Amérique | Amérique | Commun | 5950 | 1805 | 30 % | 5.8 | 1566 | 36 % | +13 pts |
| Messager sagittaire | Afrique | Commun | 6013 | 1804 | 30 % | 5.8 | 1540 | 36 % | +13 pts |
| Yak | Asie | Commun | 6050 | 1789 | 30 % | 5.6 | 1478 | 35 % | +11 pts |
| Cerf élaphe | Europe | Commun | 5945 | 1751 | 29 % | 5.7 | 1516 | 35 % | +11 pts |
| Grue couronnée | Afrique | Commun | 6308 | 1822 | 29 % | 5.7 | 1338 | 36 % | +12 pts |
| Ocelot | Amérique | Commun | 6220 | 1775 | 29 % | 5.7 | 1540 | 39 % | +16 pts |
| Bouquetin des Alpes | Europe | Commun | 6010 | 1688 | 28 % | 5.8 | 1367 | 36 % | +12 pts |
| Mésange charbonnière | Europe | Commun | 6244 | 1702 | 27 % | 5.9 | 1443 | 36 % | +12 pts |
| Loutre à joues blanches | Afrique | Commun | 7242 | 1563 | 22 % | 5.9 | 1118 | 34 % | +10 pts |
| Faucon pèlerin | Europe | Commun | 7954 | 1556 | 20 % | 6.1 | 1227 | 34 % | +10 pts |
| Tapir de Baird | Amérique | Commun | 8050 | 1475 | 18 % | 6.3 | 1047 | 36 % | +12 pts |
| Hyène tachetée | Afrique | Commun | 8167 | 1409 | 17 % | 5.9 | 1192 | 39 % | +16 pts |
| Calao bicorne | Asie | Commun | 8550 | 1472 | 17 % | 6.1 | 1088 | 32 % | +8 pts |
| Phoque gris | Europe | Commun | 8975 | 1441 | 16 % | 6.1 | 1094 | 32 % | +8 pts |
| Grue du Japon | Asie | Commun | 9193 | 1427 | 16 % | 6.0 | 1058 | 31 % | +6 pts |
| Carpe koï | Asie | Commun | 9146 | 1337 | 15 % | 6.1 | 941 | 31 % | +6 pts |
| Salamandre géante | Asie | Commun | 9460 | 1262 | 13 % | 5.9 | 902 | 30 % | +6 pts |
| Paon bleu | Asie | Peu commun | 3508 | 455 | 13 % | 10.0 | 267 | 51 % | +27 pts |
| Loutre cendrée | Asie | Peu commun | 3781 | 466 | 12 % | 10.0 | 245 | 49 % | +25 pts |
| Capybara | Amérique | Peu commun | 3462 | 423 | 12 % | 9.6 | 241 | 49 % | +25 pts |
| Girafe | Afrique | Peu commun | 3379 | 412 | 12 % | 10.0 | 239 | 56 % | +31 pts |
| Loutre d'Europe | Europe | Peu commun | 3625 | 432 | 12 % | 10.0 | 222 | 45 % | +20 pts |
| Lynx boréal | Europe | Peu commun | 3395 | 391 | 12 % | 10.2 | 224 | 51 % | +26 pts |
| Manchot du Cap | Afrique | Peu commun | 3743 | 425 | 11 % | 10.0 | 227 | 48 % | +23 pts |
| Loup gris | Europe | Peu commun | 4068 | 440 | 11 % | 10.1 | 240 | 50 % | +26 pts |
| Guépard | Afrique | Peu commun | 3649 | 379 | 10 % | 10.1 | 228 | 50 % | +25 pts |
| Alligator américain | Amérique | Peu commun | 3598 | 369 | 10 % | 10.3 | 190 | 50 % | +25 pts |
| Jaguar | Amérique | Peu commun | 3374 | 336 | 10 % | 10.1 | 191 | 48 % | +23 pts |
| Puma | Amérique | Peu commun | 3810 | 379 | 10 % | 10.4 | 190 | 43 % | +19 pts |
| Ara rouge | Amérique | Commun | 10981 | 1077 | 10 % | 6.1 | 785 | 33 % | +9 pts |
| Léopard des neiges | Asie | Peu commun | 3913 | 373 | 10 % | 10.2 | 209 | 46 % | +22 pts |
| Dauphin rose de l'Amazone | Amérique | Rare | 5962 | 284 | 5 % | 10.8 | 144 | 48 % | +23 pts |
| Lion | Afrique | Rare | 5586 | 264 | 5 % | 10.8 | 132 | 56 % | +31 pts |
| Panda géant | Asie | Rare | 6141 | 285 | 5 % | 11.2 | 142 | 51 % | +26 pts |
| Bison d'Europe | Europe | Rare | 5841 | 255 | 4 % | 11.1 | 144 | 58 % | +33 pts |
| Aigle royal | Europe | Rare | 5993 | 252 | 4 % | 11.4 | 131 | 53 % | +29 pts |
| Hippopotame | Afrique | Rare | 5779 | 242 | 4 % | 10.7 | 123 | 49 % | +24 pts |
| Tigre du Bengale | Asie | Rare | 6005 | 203 | 3 % | 11.0 | 101 | 52 % | +28 pts |
| Pygargue à tête blanche | Amérique | Rare | 5998 | 191 | 3 % | 11.1 | 75 | 52 % | +27 pts |

## Continents

Selon le nombre d'espèces de ce continent en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Afrique (3 espèces et plus) | 286 | 64 % | 24 % | +40 pts | 102 | 72 |
| Europe (3 espèces et plus) | 293 | 63 % | 24 % | +39 pts | 102 | 72 |
| Amerique (3 espèces et plus) | 185 | 58 % | 24 % | +33 pts | 99 | 72 |
| Asie (3 espèces et plus) | 267 | 55 % | 24 % | +31 pts | 98 | 72 |
| Amerique (1 ou 2 espèces) | 4556 | 34 % | 20 % | +14 pts | 81 | 68 |
| Afrique (1 ou 2 espèces) | 5513 | 32 % | 20 % | +12 pts | 80 | 67 |
| Europe (1 ou 2 espèces) | 5383 | 30 % | 21 % | +9 pts | 79 | 68 |
| Asie (1 ou 2 espèces) | 4584 | 30 % | 22 % | +7 pts | 78 | 70 |

## Types d'animaux

Selon le nombre d'espèces de ce type en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| predateur (3 espèces et plus) | 52 | 77 % | 25 % | +52 pts | 106 | 72 |
| herbivore (3 espèces et plus) | 422 | 61 % | 24 % | +37 pts | 100 | 72 |
| aquatique (3 espèces et plus) | 123 | 57 % | 25 % | +32 pts | 98 | 72 |
| aerien (3 espèces et plus) | 395 | 52 % | 24 % | +28 pts | 97 | 72 |
| predateur (1 ou 2 espèces) | 3613 | 40 % | 19 % | +20 pts | 86 | 67 |
| aquatique (1 ou 2 espèces) | 4076 | 32 % | 22 % | +11 pts | 79 | 69 |
| aerien (1 ou 2 espèces) | 6257 | 30 % | 20 % | +10 pts | 79 | 67 |
| herbivore (1 ou 2 espèces) | 6442 | 30 % | 20 % | +10 pts | 79 | 67 |

## Raretés

Selon les animaux installés en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Rare installés (2 et plus) | 93 | 67 % | 25 % | +42 pts | 103 | 72 |
| Peu commun installés (2 et plus) | 437 | 61 % | 24 % | +37 pts | 101 | 71 |
| Rare installé (1) | 801 | 49 % | 23 % | +26 pts | 94 | 71 |
| Commun installés (2 et plus) | 6253 | 38 % | 13 % | +25 pts | 86 | 60 |
| Peu commun installé (1) | 1999 | 44 % | 22 % | +22 pts | 90 | 69 |
| Commun installé (1) | 6296 | 14 % | 35 % | -21 pts | 63 | 81 |

## D'où vient la réputation

- boutique : 3 %
- frequentation : 59 %
- legendaires : 3 %
- spectacles : 6 %
- prestige : 18 %
- objectifs : 10 %
- labels : 0 %
