# Étude du jeu par l'IA qui apprend

1909 parties sur 1909 jouées, 142 min de calcul. Fin de partie en moyenne au jour 12.4.
Étude reprise : 1488 parties et 111 min des sessions précédentes, soit 3397 parties en tout ; les tableaux comptent toutes les sessions.
Record : victoire au jour 8 (101 de réputation, graine 717607344).
IA bloquées : 40 joueurs sur 13588 finissent à 0 de réputation, 75 sans aucun animal.
Rattrapage : le premier au soir du jour 4 gagne 33 % des parties, celui du jour 6 41 % (25 % si la tête ne comptait pas) ; écart moyen de 68 points entre premier et dernier à la fin.

**Comment lire les tableaux** : « Victoires avec » est le taux de victoire des joueurs qui avaient cet élément en fin de partie, « sans » celui des autres. Un écart positif veut dire que l'élément accompagne la victoire, sans le prouver : un joueur qui gagne a aussi plus d'ouvriers, de bâtiments et d'animaux. « ≈ » signale un écart trop faible pour conclure, compte tenu du nombre de parties.

## En bref : forts et faibles

Écart de victoires en points, seulement quand il est significatif, et hors éléments presque absents ou présents chez presque tous. Les bâtiments et les améliorations communes sont faussés : un joueur qui dure en a davantage.

- **Traits** : forts : Endurant (+5), Charismatique (+4), Bon élève (+3), Polyvalent (+3), Rapide (+3) ; faibles : Gourmand (-5), Rabat-joie (-3), Maladroit (-2), Paresseux (-2), Têtu (-2).
- **Métiers** : forts : Paysagiste (+9), Animateur (+5), Lobbyiste (+5), Terrassier (+4), Cantonnier (+3) ; faibles : Journaliste (-6), Architecte (-5), Formateur (-3), Contremaître (-2), Soigneur (-2).
- **Améliorations** : forts : Visionnaire (+6), Devenir Terrassier (+4), Révélation (+4), Devenir Paysagiste (+4), Seconde spécialité : Routes (+2) ; faibles : Chasseur de têtes (-5).
- **Cartes** : forts : Agence d'intérim (+12), Cabinet de recrutement (+12), Article de presse (Journaliste) (+9), Portes ouvertes (+8), Recrutement express (+7) ; faibles : Journée de carte cédée (+4) (-9), Contremaître joué (Cadence) (-6), Architecte joué (Plan d'urgence) (-5), Formateur joué (Stage de remise à niveau) (-3).
- **Animaux** : forts : Tigre du Bengale (+24), Hippopotame (+19), Capybara (+18), Panda géant (+18), Pygargue à tête blanche (+18) ; faibles : aucun net.
- **Bâtiments** : forts : Local d'entretien (+24), Camp niveau 2 (+23), Camp niveau 3 (+23), Kiosque d'animation (+22), Bassin profond (+19) ; faibles : Mine d'or (-11), Entrepôt (-7).
- **Bonus de nuit** : forts : Semaine des Amériques (Attractivité des animaux d'Amérique ×1,5) (+8), Semaine de l'Europe (Attractivité des animaux d'Europe ×1,4) (+7), Semaine de l'Asie (Attractivité des animaux d'Asie ×1,5) (+7), Journée de l'océan (Attractivité des animaux aquatiques ×1,5) (+7), Festival des oiseaux (Attractivité des animaux aériens ×1,5) (+7) ; faibles : Lampes de mineur (+40 % d'extraction d'or) (-2).

## Classement des stratégies (phase finale)

| Stratégie | Parties | Victoires | Jour moyen de victoire | Réputation moyenne |
|---|---|---|---|---|
| Apprise 1 | 22 | 59 % | 11.9 | 93 |
| Rush or + route | 22 | 45 % | 12.7 | 92 |
| Apprise 4 | 22 | 41 % | 11.7 | 82 |
| Apprise 3 | 22 | 41 % | 12.0 | 88 |
| Apprise 2 | 22 | 41 % | 12.6 | 89 |
| Spectacle | 22 | 41 % | 13.9 | 84 |
| Prédateurs | 22 | 36 % | 13.4 | 85 |
| Rush or | 22 | 32 % | 12.1 | 89 |
| Asie | 22 | 32 % | 13.7 | 83 |
| Aquatiques | 21 | 29 % | 13.0 | 78 |
| Fast expand | 22 | 27 % | 15.2 | 70 |
| Haut de gamme | 22 | 27 % | 12.5 | 78 |
| Grand camp | 22 | 27 % | 14.0 | 83 |
| Aériens | 22 | 27 % | 13.5 | 74 |
| Europe | 22 | 23 % | 13.2 | 75 |
| Grand parc | 22 | 23 % | 13.2 | 75 |
| Amérique | 22 | 23 % | 12.4 | 72 |
| Équilibrée | 22 | 18 % | 13.8 | 68 |
| Afrique | 22 | 18 % | 13.3 | 69 |
| Même type | 22 | 18 % | 14.3 | 76 |
| Ancienne IA | 22 | 18 % | 13.3 | 83 |
| Sans intendance | 22 | 18 % | 12.3 | 71 |
| Spécialisation | 22 | 18 % | 14.3 | 68 |
| Camp amélioré | 22 | 18 % | 13.5 | 72 |
| Formateur | 22 | 18 % | 13.3 | 70 |
| Parc évolutif | 21 | 14 % | 15.0 | 60 |
| Sans agrandir | 22 | 14 % | 13.3 | 77 |
| Herbivores | 22 | 14 % | 12.7 | 74 |
| Lobbying | 22 | 14 % | 13.0 | 75 |
| Affinités | 22 | 14 % | 11.7 | 70 |
| Cartes | 22 | 14 % | 14.7 | 60 |
| Marché | 22 | 14 % | 12.3 | 73 |
| Petits contrats | 22 | 9 % | 13.0 | 62 |

## Niveaux d'IA enregistrés (game/data/ia_niveaux.json)

| Niveau | Victoires en finale | Réputation moyenne | Stratégies |
|---|---|---|---|
| Facile | 13 % | 66 | Affinités, Cartes, Marché, Petits contrats |
| Moyen | 22 % | 73 | Europe, Grand parc, Amérique, Équilibrée |
| Difficile | 47 % | 89 | Apprise 1, Rush or + route, Apprise 4, Apprise 3 |

## Stratégies apprises

| Génération | Victoires de la meilleure | Ses parties | Jour moyen | Réputation | Moyenne de la population |
|---|---|---|---|---|---|
| 1 | 75 % | 12 | 12.9 | 107 | 25 % |
| 5 | 67 % | 12 | 12.1 | 95 | 28 % |
| 9 | 58 % | 12 | 12.0 | 94 | 28 % |
| 13 | 50 % | 24 | 11.0 | 86 | 27 % |
| 17 | 46 % | 132 | 12.1 | 92 | 25 % |
| 21 | 75 % | 12 | 12.6 | 105 | 31 % |
| 25 | 58 % | 12 | 13.0 | 90 | 26 % |
| 29 | 50 % | 36 | 12.7 | 91 | 26 % |
| 33 | 42 % | 84 | 11.8 | 91 | 28 % |
| 37 | 42 % | 132 | 12.5 | 91 | 25 % |
| 41 | 54 % | 24 | 12.3 | 101 | 27 % |
| 45 | 42 % | 228 | 11.9 | 91 | 28 % |
| 49 | 45 % | 84 | 12.0 | 91 | 28 % |
| 53 | 47 % | 36 | 12.2 | 90 | 26 % |
| 57 | 41 % | 372 | 12.0 | 91 | 29 % |
| 61 | 58 % | 12 | 12.0 | 97 | 25 % |
| 65 | 44 % | 48 | 11.9 | 98 | 25 % |

1. parc moyen, palier 2.9, réserve 0, lobby 0, camp 2, contrats 4, marche, affinite, sans adaptatif, meme_type
2. parc moyen, palier 3.0, réserve 0, lobby 0, camp 2, contrats 4, affinite, route_mine, sans adaptatif, intendance, Afrique
3. parc moyen, palier 2.6, réserve 0, lobby 0, camp 1, contrats 4, affinite, route_mine, sans adaptatif, sans agrandir, meme_type
4. parc moyen, palier 2.6, réserve 0, lobby 0, camp 1, contrats 4, affinite, route_mine, sans adaptatif, Afrique

Réglages retenus par les 8 meilleures : marche 1/8, rush_or 0/8, formation 2/8, cartes 1/8, spectacle 2/8, affinite 4/8, boutique 7/8, mine 0/8, specialisation 0/8, fast_expand 0/8, route_mine 4/8, adaptatif 0/8, agrandir 7/8, meme_type 4/8, intendance 1/8.

**Métiers, des plus recherchés aux plus évités par les IA qui gagnent** : Architecte +1.0, Intendant de parc +0.9, Contremaître +0.6, Porteur +0.5, Guichetier +0.4, Manœuvre +0.4, Terrassier +0.3, Lobbyiste +0.3, DRH +0.2, Cantonnier +0.1, Charpentier +0.0, Animateur +0.0, Paysagiste -0.0, Agent d'entretien -0.1, Vendeur de souvenirs -0.1, Marchand -0.2, Animalier -0.2, Journaliste -0.3, Mineur -0.3, Soigneur -0.4, Formateur -0.7, Bûcheron -0.8, Maçon -0.8, Apprenti -0.8.

**Traits, des plus recherchés aux plus évités par les IA qui gagnent** : Costaud +0.8, Charismatique +0.8, Peureux +0.7, Maladroit +0.6, Endurant +0.3, Matinal +0.3, Casanier +0.2, Naturaliste +0.2, Débrouillard +0.2, Bon élève +0.1, Paresseux +0.1, Rapide +0.1, Distrait +0.1, Polyvalent +0.0, Lent +0.0, Rabat-joie +0.0, Col blanc -0.2, Têtu -1.0, Gourmand -1.4, Économe -1.6.

**Animaux, des plus recherchés aux plus évités par les IA qui gagnent** : Messager sagittaire +0.7, Grue du Japon +0.7, Capybara +0.6, Girafe +0.6, Aigle royal +0.6, Hyène tachetée +0.5, Hippopotame +0.5, Bison d'Amérique +0.4, Panda géant +0.3, Salamandre géante +0.3, Lion +0.3, Loutre à joues blanches +0.2, Bison d'Europe +0.2, Carpe koï +0.2, Grue couronnée +0.2, Loutre cendrée +0.1, Bouquetin des Alpes +0.1, Loutre d'Europe +0.0, Lynx boréal +0.0, Mésange charbonnière +0.0, Dauphin rose de l'Amazone -0.0, Tapir de Baird -0.0, Phoque gris -0.1, Paon bleu -0.1, Léopard des neiges -0.1, Calao bicorne -0.1, Pygargue à tête blanche -0.2, Ara rouge -0.2, Jaguar -0.2, Puma -0.2, Faucon pèlerin -0.2, Tigre du Bengale -0.3, Yak -0.4, Zèbre -0.4, Ocelot -0.6, Cerf élaphe -0.6, Loup gris -0.7, Manchot du Cap -0.8, Alligator américain -0.8, Guépard -1.4.

**Cartes, des plus recherchés aux plus évités par les IA qui gagnent** : Rupture de contrat +0.8, Formation express +0.7, Livraison +0.2, Prime +0.1, Portes ouvertes +0.0, Promotion -0.1, Heures sup -0.3, Recrutement express -0.3.

**Améliorations, des plus recherchés aux plus évités par les IA qui gagnent** : Négociateur +1.1, Révélation +0.8, Expérience +0.4, Scie affûtée +0.2, Visionnaire +0.1, Fidélité +0.0, Pied léger +0.0, Maîtrise -0.0, Remise en question -0.3, Seconde spécialité -0.3, Réseau -0.4, Brouette -0.6, Pédagogue -0.6, Chasseur de têtes -0.9.

## Traits des ouvriers

Joueurs ayant au moins un ouvrier avec ce trait. Défauts et qualités sont tirés au draft, mais l'IA choisit ses cartes : les traits les plus visibles sont en partie évités.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Endurant | 10013 | 26 % | 21 % | +5 pts | 80 | 76 |
| Charismatique | 9654 | 26 % | 22 % | +4 pts | 80 | 76 |
| Bon élève | 9745 | 26 % | 23 % | +3 pts | 80 | 76 |
| Polyvalent | 9676 | 26 % | 23 % | +3 pts | 80 | 76 |
| Rapide | 9558 | 26 % | 23 % | +3 pts | 80 | 76 |
| Débrouillard | 9756 | 26 % | 23 % | +2 pts | 80 | 76 |
| Costaud | 9735 | 26 % | 24 % | +2 pts | 80 | 77 |
| Naturaliste | 9623 | 26 % | 24 % | +2 pts | 79 | 77 |
| Économe | 7817 | 26 % | 24 % | ≈ +1 pts | 80 | 78 |
| Matinal | 9564 | 25 % | 24 % | ≈ +1 pts | 79 | 78 |
| Distrait | 6271 | 25 % | 25 % | ≈ -1 pts | 78 | 80 |
| Col blanc | 1579 | 24 % | 25 % | ≈ -1 pts | 79 | 79 |
| Peureux | 6669 | 24 % | 26 % | ≈ -1 pts | 78 | 80 |
| Lent | 5568 | 24 % | 26 % | -2 pts | 77 | 80 |
| Casanier | 6395 | 24 % | 26 % | -2 pts | 77 | 80 |
| Têtu | 6490 | 24 % | 26 % | -2 pts | 78 | 80 |
| Paresseux | 6123 | 24 % | 26 % | -2 pts | 77 | 80 |
| Maladroit | 6187 | 24 % | 26 % | -2 pts | 78 | 80 |
| Rabat-joie | 5731 | 23 % | 26 % | -3 pts | 77 | 80 |
| Gourmand | 4525 | 22 % | 27 % | -5 pts | 75 | 81 |

## Métiers

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Paysagiste | 9855 | 27 % | 19 % | +9 pts | 81 | 72 |
| Animateur | 2096 | 30 % | 24 % | +5 pts | 83 | 78 |
| Lobbyiste | 2228 | 29 % | 24 % | +5 pts | 86 | 77 |
| Terrassier | 7685 | 27 % | 23 % | +4 pts | 80 | 77 |
| Cantonnier | 7759 | 26 % | 24 % | +3 pts | 80 | 77 |
| Guichetier | 7212 | 26 % | 24 % | +2 pts | 79 | 79 |
| Porteur | 6640 | 26 % | 24 % | +2 pts | 80 | 78 |
| Vendeur de souvenirs | 1963 | 26 % | 25 % | ≈ +1 pts | 80 | 79 |
| Maçon | 5318 | 26 % | 25 % | ≈ +1 pts | 79 | 79 |
| Charpentier | 7251 | 25 % | 25 % | ≈ +1 pts | 80 | 78 |
| Bûcheron | 4528 | 25 % | 25 % | ≈ +1 pts | 79 | 79 |
| Apprenti | 95 | 25 % | 25 % | ≈ +0 pts | 75 | 79 |
| Agent d'entretien | 6272 | 25 % | 25 % | ≈ +0 pts | 78 | 79 |
| Mineur | 5459 | 24 % | 25 % | ≈ -1 pts | 78 | 80 |
| Animalier | 6905 | 25 % | 25 % | ≈ -1 pts | 78 | 80 |
| Manœuvre | 520 | 24 % | 25 % | ≈ -1 pts | 78 | 79 |
| Marchand | 2254 | 24 % | 25 % | ≈ -1 pts | 79 | 79 |
| Intendant de parc | 1753 | 24 % | 25 % | ≈ -1 pts | 79 | 79 |
| DRH | 2187 | 24 % | 25 % | ≈ -1 pts | 78 | 79 |
| Soigneur | 7642 | 24 % | 26 % | -2 pts | 79 | 78 |
| Contremaître | 2317 | 23 % | 25 % | -2 pts | 79 | 79 |
| Formateur | 2085 | 23 % | 25 % | -3 pts | 77 | 79 |
| Architecte | 2250 | 21 % | 26 % | -5 pts | 76 | 79 |
| Journaliste | 2171 | 20 % | 26 % | -6 pts | 73 | 80 |

## Améliorations

Choisies 25 % du temps au hasard pendant l'apprentissage, pour que toutes soient essayées.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Maîtrise | 13556 | 25 % | 3 % | +22 pts | 79 | 54 |
| Visionnaire | 3543 | 29 % | 23 % | +6 pts | 84 | 77 |
| Devenir Terrassier | 888 | 29 % | 25 % | +4 pts | 81 | 79 |
| Révélation | 12015 | 26 % | 21 % | +4 pts | 79 | 74 |
| Devenir Paysagiste | 699 | 29 % | 25 % | +4 pts | 83 | 79 |
| Remise en question | 13469 | 25 % | 22 % | ≈ +3 pts | 79 | 74 |
| Réseau | 677 | 28 % | 25 % | ≈ +3 pts | 87 | 78 |
| Devenir Porteur | 865 | 27 % | 25 % | ≈ +2 pts | 81 | 79 |
| Seconde spécialité : Routes | 1904 | 27 % | 25 % | +2 pts | 81 | 79 |
| Devenir Maçon | 722 | 27 % | 25 % | ≈ +2 pts | 78 | 79 |
| Expérience | 10647 | 25 % | 23 % | +2 pts | 80 | 76 |
| Seconde spécialité : Construction en bois | 1802 | 27 % | 25 % | ≈ +2 pts | 81 | 79 |
| Seconde spécialité : Extraction de bois | 2010 | 27 % | 25 % | ≈ +2 pts | 80 | 79 |
| Seconde spécialité : Clôtures d'enclos | 1651 | 27 % | 25 % | ≈ +2 pts | 79 | 79 |
| Brouette | 2629 | 26 % | 25 % | ≈ +2 pts | 81 | 78 |
| Devenir Cantonnier | 748 | 26 % | 25 % | ≈ +2 pts | 78 | 79 |
| Devenir Agent d'entretien | 709 | 26 % | 25 % | ≈ +1 pts | 80 | 79 |
| Seconde spécialité : Guichet | 1879 | 26 % | 25 % | ≈ +1 pts | 79 | 79 |
| Pied léger | 10327 | 25 % | 24 % | ≈ +1 pts | 80 | 77 |
| Fidélité | 10477 | 25 % | 24 % | ≈ +1 pts | 79 | 77 |
| Scie affûtée | 1884 | 25 % | 25 % | ≈ +1 pts | 79 | 79 |
| Négociateur | 727 | 25 % | 25 % | ≈ +0 pts | 80 | 79 |
| Devenir Guichetier | 634 | 25 % | 25 % | ≈ +0 pts | 78 | 79 |
| Devenir Animalier | 1371 | 25 % | 25 % | ≈ +0 pts | 78 | 79 |
| Pédagogue | 113 | 25 % | 25 % | ≈ +0 pts | 78 | 79 |
| Seconde spécialité : Construction en pierre | 1982 | 25 % | 25 % | ≈ -1 pts | 80 | 79 |
| Seconde spécialité : Extraction de pierre | 1942 | 25 % | 25 % | ≈ -1 pts | 79 | 79 |
| Devenir Mineur | 766 | 24 % | 25 % | ≈ -1 pts | 77 | 79 |
| Devenir Bûcheron | 714 | 24 % | 25 % | ≈ -1 pts | 78 | 79 |
| Devenir Soigneur | 802 | 23 % | 25 % | ≈ -2 pts | 78 | 79 |
| Devenir Charpentier | 717 | 23 % | 25 % | ≈ -3 pts | 77 | 79 |
| Chasseur de têtes | 461 | 20 % | 25 % | -5 pts | 77 | 79 |

## Bâtiments

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Cuisine des animaux | 13507 | 25 % | 0 % | +25 pts | 79 | 15 |
| Entrée du zoo | 13563 | 25 % | 0 % | +25 pts | 79 | 12 |
| Local d'entretien | 13164 | 26 % | 1 % | +24 pts | 80 | 31 |
| Camp niveau 2 | 12004 | 28 % | 5 % | +23 pts | 82 | 56 |
| Camp niveau 3 | 7197 | 36 % | 13 % | +23 pts | 90 | 66 |
| Kiosque d'animation | 9913 | 31 % | 9 % | +22 pts | 87 | 58 |
| Bassin profond | 2147 | 41 % | 22 % | +19 pts | 93 | 76 |
| Rocher d'observation | 2979 | 36 % | 22 % | +15 pts | 91 | 76 |
| Grand arbre | 2329 | 36 % | 23 % | +13 pts | 91 | 76 |
| Abri chauffé | 387 | 32 % | 25 % | +7 pts | 89 | 79 |
| Maison du personnel | 13230 | 25 % | 19 % | +6 pts | 79 | 71 |
| Agence d'intérim | 934 | 31 % | 25 % | +6 pts | 87 | 78 |
| Snack | 1115 | 30 % | 25 % | +5 pts | 87 | 78 |
| Cabinet de recrutement | 1196 | 28 % | 25 % | +3 pts | 84 | 78 |
| Boutique de souvenirs | 5583 | 27 % | 24 % | +3 pts | 81 | 78 |
| Intendance du parc | 1384 | 27 % | 25 % | ≈ +2 pts | 83 | 78 |
| Marché | 7967 | 25 % | 25 % | ≈ +0 pts | 79 | 79 |
| Entrepôt | 4586 | 20 % | 27 % | -7 pts | 73 | 82 |
| Mine d'or | 2732 | 16 % | 27 % | -11 pts | 71 | 81 |

## Labels

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| excellence | 14 | 36 % | 25 % | ≈ +11 pts | 85 | 79 |
| mecenat | 86 | 21 % | 25 % | ≈ -4 pts | 76 | 79 |
| certifie | 414 | 20 % | 25 % | -5 pts | 75 | 79 |

## Objectifs remplis

Joueurs ayant rempli cet objectif. Le taux de réussite est dans le tableau suivant.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| 120 visiteurs en une journée | 898 | 56 % | 23 % | +33 pts | 105 | 77 |
| 4 points de publicité | 796 | 54 % | 23 % | +30 pts | 107 | 77 |
| 2 animaux peu communs | 174 | 52 % | 25 % | +27 pts | 103 | 79 |
| 3 espèces d'un même continent | 832 | 48 % | 23 % | +25 pts | 100 | 77 |
| Camp au niveau 3 avant le jour 10 | 701 | 48 % | 24 % | +24 pts | 98 | 78 |
| Enceinte de 350 cases | 986 | 46 % | 23 % | +22 pts | 98 | 77 |
| 5 espèces installées | 1086 | 45 % | 23 % | +21 pts | 100 | 77 |
| 1 animal rare installé | 788 | 43 % | 24 % | +20 pts | 96 | 78 |
| 3 espèces d'un même type | 926 | 43 % | 24 % | +19 pts | 97 | 78 |
| 2 collaborateurs au niveau 5 | 496 | 37 % | 25 % | +13 pts | 92 | 78 |
| 11 collaborateurs | 554 | 33 % | 25 % | +8 pts | 88 | 78 |
| Boutique, Kiosque et Snack | 176 | 30 % | 25 % | ≈ +5 pts | 87 | 79 |
| 3 cadres dans l'équipe | 642 | 30 % | 25 % | +5 pts | 85 | 79 |
| 1 label obtenu | 84 | 24 % | 25 % | ≈ -1 pts | 80 | 79 |

| Objectif | Parties où il est tiré | Joueurs qui l'ont rempli | Taux de réussite |
|---|---|---|---|
| 3 espèces d'un même continent | 701 | 832 | 30 % |
| 3 espèces d'un même type | 770 | 926 | 30 % |
| 1 animal rare installé | 733 | 788 | 27 % |
| 2 animaux peu communs | 726 | 174 | 6 % |
| 5 espèces installées | 723 | 1086 | 38 % |
| Enceinte de 350 cases | 711 | 986 | 35 % |
| 120 visiteurs en une journée | 749 | 898 | 30 % |
| 2 collaborateurs au niveau 5 | 708 | 496 | 18 % |
| 3 cadres dans l'équipe | 699 | 642 | 23 % |
| 11 collaborateurs | 740 | 554 | 19 % |
| Camp au niveau 3 avant le jour 10 | 770 | 701 | 23 % |
| Boutique, Kiosque et Snack | 747 | 176 | 6 % |
| 4 points de publicité | 686 | 796 | 29 % |
| 1 label obtenu | 728 | 84 | 3 % |

## Bonus de nuit

Joueurs ayant choisi ce bonus au moins une fois (le premier en influence choisit).

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Semaine des Amériques (Attractivité des animaux d'Amérique ×1,5) | 1224 | 32 % | 24 % | +8 pts | 87 | 78 |
| Semaine de l'Europe (Attractivité des animaux d'Europe ×1,4) | 1390 | 31 % | 24 % | +7 pts | 87 | 78 |
| Semaine de l'Asie (Attractivité des animaux d'Asie ×1,5) | 1276 | 31 % | 24 % | +7 pts | 87 | 78 |
| Journée de l'océan (Attractivité des animaux aquatiques ×1,5) | 1127 | 31 % | 24 % | +7 pts | 87 | 78 |
| Festival des oiseaux (Attractivité des animaux aériens ×1,5) | 1894 | 31 % | 24 % | +7 pts | 87 | 78 |
| Campagne d'affichage (+20 % de visiteurs le soir) | 3121 | 30 % | 24 % | +6 pts | 86 | 77 |
| Semaine de l'Afrique (Attractivité des animaux d'Afrique ×1,4) | 1477 | 31 % | 24 % | +6 pts | 87 | 78 |
| Pioches renforcées (+30 % d'extraction de pierre) | 3180 | 27 % | 25 % | +2 pts | 82 | 78 |
| Engins de terrassement (+40 % d'aménagement du terrain) | 1996 | 26 % | 25 % | ≈ +1 pts | 82 | 78 |
| Scies neuves (+30 % d'extraction de bois) | 3109 | 26 % | 25 % | ≈ +1 pts | 82 | 78 |
| Brouettes (+20 % de vitesse de déplacement) | 2287 | 26 % | 25 % | ≈ +1 pts | 82 | 78 |
| Échafaudages (+25 % de construction) | 2877 | 25 % | 25 % | ≈ +0 pts | 81 | 78 |
| Carnet d'adresses (+50 % de lobbying) | 2318 | 25 % | 25 % | ≈ +0 pts | 81 | 78 |
| Lampes de mineur (+40 % d'extraction d'or) | 1493 | 23 % | 25 % | -2 pts | 80 | 79 |

## Taille du parc

Agrandissements terminés et surface de l'enceinte en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Parc de 450 cases et plus | 3846 | 44 % | 17 % | +27 pts | 97 | 72 |
| Parc agrandi 2 fois et plus | 3893 | 44 % | 17 % | +27 pts | 97 | 72 |
| Beauté du parc : 6 décorations et plus | 272 | 32 % | 25 % | +7 pts | 88 | 79 |
| Beauté du parc : aucune décoration | 12811 | 25 % | 26 % | ≈ -1 pts | 79 | 83 |
| Beauté du parc : 1 à 5 décorations | 505 | 24 % | 25 % | ≈ -1 pts | 80 | 79 |
| Parc agrandi 1 fois | 4519 | 20 % | 28 % | -8 pts | 75 | 81 |
| Parc de 250 à 449 cases | 4956 | 20 % | 28 % | -8 pts | 74 | 81 |
| Parc de moins de 250 cases | 4786 | 15 % | 30 % | -16 pts | 69 | 84 |
| Parc agrandi jamais | 5176 | 15 % | 31 % | -16 pts | 69 | 85 |

## Cartes à usage unique et cadres joués

Joueurs ayant joué cette carte au moins une fois.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Accusation (Journaliste) | 107 | 57 % | 25 % | +32 pts | 106 | 79 |
| Agence d'intérim | 436 | 37 % | 25 % | +12 pts | 93 | 78 |
| Cabinet de recrutement | 423 | 36 % | 25 % | +12 pts | 94 | 78 |
| Article de presse (Journaliste) | 982 | 33 % | 24 % | +9 pts | 90 | 78 |
| Portes ouvertes | 2519 | 31 % | 24 % | +8 pts | 88 | 77 |
| Recrutement express | 2785 | 30 % | 24 % | +7 pts | 85 | 77 |
| Prime | 3153 | 29 % | 24 % | +5 pts | 85 | 77 |
| Formation express | 1860 | 29 % | 24 % | +5 pts | 86 | 78 |
| Livraison | 2238 | 28 % | 24 % | +4 pts | 85 | 78 |
| Rupture de contrat | 4169 | 27 % | 24 % | +3 pts | 83 | 77 |
| Lobbyiste joué (Coup de fil) | 1387 | 27 % | 25 % | +3 pts | 86 | 78 |
| Heures sup | 3739 | 27 % | 24 % | +2 pts | 82 | 77 |
| Animateur joué (Grand spectacle) | 1599 | 27 % | 25 % | ≈ +2 pts | 81 | 79 |
| Promotion | 3244 | 25 % | 25 % | ≈ +1 pts | 81 | 78 |
| DRH joué (Mutation) | 1667 | 25 % | 25 % | ≈ +0 pts | 79 | 79 |
| Marchand joué (Négoce) | 541 | 23 % | 25 % | ≈ -2 pts | 77 | 79 |
| Formateur joué (Stage de remise à niveau) | 2203 | 23 % | 25 % | -3 pts | 77 | 79 |
| Architecte joué (Plan d'urgence) | 1450 | 20 % | 26 % | -5 pts | 77 | 79 |
| Contremaître joué (Cadence) | 1618 | 20 % | 26 % | -6 pts | 76 | 79 |
| Journée de carte cédée (+4) | 5166 | 19 % | 29 % | -9 pts | 72 | 83 |
| Vendeur de souvenirs joué (Braderie) | 16 | 6 % | 25 % | -19 pts | 50 | 79 |

### Effet immédiat des cartes sur la réputation gagnée

Réputation gagnée le jour où la carte est jouée, comparée à la veille. La réputation monte naturellement chaque jour : à comparer d'une carte à l'autre plutôt qu'à zéro. « Tard » : à partir du jour 8.

| Carte | Coût | Jouée | Gain du jour | Veille | Écart | Tard : gain | Tard : veille | Tard : écart |
|---|---|---|---|---|---|---|---|---|
| Accusation (Journaliste) | — | 116 | 25.2 | 17.0 | +8.2 | 25.2 | 17.0 | +8.2 (116) |
| Vendeur de souvenirs joué (Braderie) | — | 17 | 9.2 | 1.9 | +7.4 | 9.6 | 1.8 | +7.8 (16) |
| Recrutement express | 8 | 3244 | 13.0 | 9.5 | +3.5 | 15.5 | 11.3 | +4.2 (2580) |
| Animateur joué (Grand spectacle) | — | 3836 | 9.7 | 5.7 | +4.1 | 11.5 | 7.6 | +4.0 (2188) |
| Article de presse (Journaliste) | — | 1199 | 16.7 | 13.0 | +3.7 | 16.8 | 13.1 | +3.7 (1178) |
| Cabinet de recrutement | — | 564 | 16.5 | 12.8 | +3.7 | 16.5 | 12.8 | +3.7 (559) |
| Agence d'intérim | — | 653 | 18.5 | 15.1 | +3.4 | 18.5 | 15.1 | +3.4 (650) |
| Formation express | 14 | 2075 | 14.2 | 11.6 | +2.6 | 15.9 | 13.0 | +2.9 (1817) |
| Portes ouvertes | 14 | 2999 | 15.0 | 12.4 | +2.6 | 15.5 | 12.9 | +2.7 (2822) |
| Prime | 10 | 3872 | 12.0 | 9.8 | +2.2 | 14.2 | 11.6 | +2.6 (3148) |
| Journée de carte cédée (+4) | — | 13866 | 2.2 | 1.0 | +1.2 | 3.4 | 1.2 | +2.2 (3951) |
| DRH joué (Mutation) | — | 2950 | 8.2 | 6.3 | +1.9 | 11.2 | 9.1 | +2.1 (1622) |
| Rupture de contrat | 3 | 5382 | 10.1 | 8.4 | +1.7 | 12.2 | 10.5 | +1.7 (3865) |
| Formateur joué (Stage de remise à niveau) | — | 8591 | 6.1 | 5.0 | +1.1 | 10.7 | 9.1 | +1.7 (4080) |
| Heures sup | 8 | 4846 | 10.8 | 9.5 | +1.2 | 13.1 | 11.6 | +1.5 (3768) |
| Contremaître joué (Cadence) | — | 4531 | 5.6 | 4.7 | +1.0 | 10.7 | 9.3 | +1.4 (1908) |
| Lobbyiste joué (Coup de fil) | — | 2375 | 8.0 | 7.1 | +0.9 | 11.3 | 10.0 | +1.3 (1402) |
| Architecte joué (Plan d'urgence) | — | 2566 | 8.9 | 8.2 | +0.7 | 11.4 | 10.5 | +1.0 (1909) |
| Promotion | 8 | 3926 | 10.1 | 9.3 | +0.8 | 12.3 | 11.3 | +0.9 (3044) |
| Livraison | 15 | 2530 | 12.0 | 11.3 | +0.8 | 13.1 | 12.3 | +0.8 (2277) |
| Marchand joué (Négoce) | — | 611 | 1.6 | 1.6 | +0.0 | 8.1 | 8.3 | -0.3 (84) |

## Animaux

Taux d'achat : achats par nuit passée au marché. Un rare est naturellement moins acheté : il coûte très cher.

| Espèce | Continent | Rareté | Nuits au marché | Achats | Taux d'achat | Jour moyen d'achat | Installée | Victoires avec | Écart |
|---|---|---|---|---|---|---|---|---|---|
| Messager sagittaire | Afrique | Commun | 4710 | 2639 | 56 % | 5.8 | 2397 | 28 % | +4 pts |
| Bison d'Amérique | Amérique | Commun | 5401 | 2584 | 48 % | 5.7 | 2382 | 29 % | +5 pts |
| Cerf élaphe | Europe | Commun | 5771 | 2717 | 47 % | 5.7 | 2497 | 30 % | +6 pts |
| Hyène tachetée | Afrique | Commun | 5822 | 2630 | 45 % | 5.8 | 2375 | 29 % | +5 pts |
| Zèbre | Afrique | Commun | 6020 | 2595 | 43 % | 5.8 | 2363 | 29 % | +5 pts |
| Mésange charbonnière | Europe | Commun | 6251 | 2661 | 43 % | 5.9 | 2403 | 30 % | +6 pts |
| Faucon pèlerin | Europe | Commun | 6279 | 2665 | 42 % | 6.0 | 2370 | 30 % | +6 pts |
| Loutre à joues blanches | Afrique | Commun | 6367 | 2621 | 41 % | 5.9 | 2299 | 30 % | +6 pts |
| Grue du Japon | Asie | Commun | 6461 | 2648 | 41 % | 6.0 | 2321 | 33 % | +10 pts |
| Grue couronnée | Afrique | Commun | 6517 | 2590 | 40 % | 5.9 | 2278 | 31 % | +7 pts |
| Carpe koï | Asie | Commun | 6683 | 2559 | 38 % | 6.0 | 2210 | 28 % | +4 pts |
| Bouquetin des Alpes | Europe | Commun | 6931 | 2606 | 38 % | 6.0 | 2304 | 30 % | +6 pts |
| Yak | Asie | Commun | 7189 | 2483 | 35 % | 6.1 | 2233 | 31 % | +7 pts |
| Salamandre géante | Asie | Commun | 7273 | 2487 | 34 % | 6.2 | 2161 | 31 % | +7 pts |
| Ara rouge | Amérique | Commun | 7549 | 2414 | 32 % | 6.1 | 2115 | 31 % | +7 pts |
| Tapir de Baird | Amérique | Commun | 7380 | 2346 | 32 % | 6.0 | 2052 | 30 % | +6 pts |
| Calao bicorne | Asie | Commun | 7789 | 2370 | 30 % | 6.1 | 2087 | 31 % | +7 pts |
| Ocelot | Amérique | Commun | 7929 | 2246 | 28 % | 6.0 | 2049 | 26 % | +1 pts |
| Phoque gris | Europe | Commun | 8494 | 2284 | 27 % | 6.2 | 2010 | 31 % | +7 pts |
| Loutre d'Europe | Europe | Peu commun | 2676 | 572 | 21 % | 8.4 | 407 | 39 % | +14 pts |
| Loutre cendrée | Asie | Peu commun | 2688 | 552 | 21 % | 8.3 | 406 | 38 % | +14 pts |
| Capybara | Amérique | Peu commun | 3047 | 598 | 20 % | 8.4 | 451 | 43 % | +18 pts |
| Paon bleu | Asie | Peu commun | 3079 | 602 | 20 % | 8.6 | 424 | 38 % | +13 pts |
| Lion | Afrique | Rare | 5405 | 1037 | 19 % | 9.3 | 602 | 42 % | +17 pts |
| Panda géant | Asie | Rare | 4946 | 923 | 19 % | 9.2 | 544 | 42 % | +18 pts |
| Lynx boréal | Europe | Peu commun | 3009 | 561 | 19 % | 8.6 | 373 | 38 % | +13 pts |
| Bison d'Europe | Europe | Rare | 5192 | 958 | 18 % | 9.4 | 612 | 40 % | +16 pts |
| Pygargue à tête blanche | Amérique | Rare | 5219 | 940 | 18 % | 9.4 | 458 | 42 % | +18 pts |
| Hippopotame | Afrique | Rare | 5406 | 969 | 18 % | 9.2 | 564 | 43 % | +19 pts |
| Dauphin rose de l'Amazone | Amérique | Rare | 5233 | 937 | 18 % | 9.3 | 537 | 41 % | +17 pts |
| Tigre du Bengale | Asie | Rare | 5411 | 962 | 18 % | 9.5 | 527 | 48 % | +24 pts |
| Manchot du Cap | Afrique | Peu commun | 3212 | 570 | 18 % | 8.7 | 373 | 36 % | +11 pts |
| Aigle royal | Europe | Rare | 5460 | 903 | 17 % | 9.4 | 469 | 39 % | +15 pts |
| Loup gris | Europe | Peu commun | 3449 | 557 | 16 % | 8.9 | 345 | 38 % | +13 pts |
| Guépard | Afrique | Peu commun | 3452 | 555 | 16 % | 8.7 | 439 | 38 % | +14 pts |
| Puma | Amérique | Peu commun | 3225 | 517 | 16 % | 9.0 | 333 | 36 % | +12 pts |
| Girafe | Afrique | Peu commun | 3265 | 517 | 16 % | 8.8 | 360 | 38 % | +13 pts |
| Alligator américain | Amérique | Peu commun | 3438 | 519 | 15 % | 9.0 | 324 | 32 % | +8 pts |
| Léopard des neiges | Asie | Peu commun | 3945 | 495 | 13 % | 9.1 | 329 | 33 % | +8 pts |
| Jaguar | Amérique | Peu commun | 3787 | 471 | 12 % | 9.0 | 314 | 31 % | +6 pts |

## Continents

Selon le nombre d'espèces de ce continent en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Europe (3 espèces et plus) | 1078 | 45 % | 23 % | +22 pts | 98 | 77 |
| Asie (3 espèces et plus) | 1240 | 44 % | 23 % | +21 pts | 97 | 77 |
| Afrique (3 espèces et plus) | 1154 | 44 % | 23 % | +21 pts | 97 | 77 |
| Amerique (3 espèces et plus) | 646 | 43 % | 24 % | +18 pts | 97 | 78 |
| Amerique (1 ou 2 espèces) | 6869 | 27 % | 23 % | +4 pts | 82 | 75 |
| Asie (1 ou 2 espèces) | 6848 | 26 % | 24 % | +2 pts | 81 | 76 |
| Europe (1 ou 2 espèces) | 7578 | 26 % | 24 % | ≈ +1 pts | 81 | 76 |
| Afrique (1 ou 2 espèces) | 7663 | 25 % | 25 % | ≈ +1 pts | 81 | 76 |

## Types d'animaux

Selon le nombre d'espèces de ce type en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| predateur (3 espèces et plus) | 166 | 54 % | 25 % | +30 pts | 103 | 79 |
| aquatique (3 espèces et plus) | 609 | 44 % | 24 % | +19 pts | 98 | 78 |
| herbivore (3 espèces et plus) | 1371 | 40 % | 23 % | +17 pts | 95 | 77 |
| aerien (3 espèces et plus) | 1791 | 39 % | 23 % | +16 pts | 94 | 77 |
| predateur (1 ou 2 espèces) | 6054 | 29 % | 21 % | +8 pts | 84 | 75 |
| aquatique (1 ou 2 espèces) | 7147 | 29 % | 21 % | +8 pts | 84 | 74 |
| herbivore (1 ou 2 espèces) | 8330 | 26 % | 23 % | +3 pts | 81 | 75 |
| aerien (1 ou 2 espèces) | 8252 | 26 % | 23 % | +3 pts | 81 | 75 |

## Raretés

Selon les animaux installés en fin de partie.

| | Joueurs concernés | Victoires avec | Victoires sans | Écart | Réputation avec | Réputation sans |
|---|---|---|---|---|---|---|
| Rare installés (2 et plus) | 609 | 55 % | 24 % | +31 pts | 104 | 78 |
| Peu commun installés (2 et plus) | 774 | 45 % | 24 % | +22 pts | 99 | 78 |
| Commun installés (2 et plus) | 11169 | 28 % | 11 % | +16 pts | 83 | 58 |
| Rare installé (1) | 3017 | 37 % | 22 % | +15 pts | 92 | 75 |
| Peu commun installé (1) | 3248 | 33 % | 23 % | +10 pts | 87 | 76 |
| Commun installé (1) | 2165 | 11 % | 28 % | -17 pts | 58 | 83 |

## D'où vient la réputation

- beaute : 0 %
- boutique : 3 %
- frequentation : 72 %
- labels : 0 %
- legendaires : 1 %
- objectifs : 9 %
- prestige : 10 %
- spectacles : 4 %
