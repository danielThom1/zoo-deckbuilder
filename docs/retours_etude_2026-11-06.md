# Retours sur l'étude de 10 000 parties (06/11/2026)

Étude lancée le 05/11 à 21 h 09 (`--total=10000 --jobs=10 --fin=08h30`). Rapport : `rapport_etude.md`.

## Ce que l'étude a montré
- L'apprentissage plafonne vers la génération 40 : les meilleures stratégies jouées longtemps gagnent 41 à 48 % (25 % en moyenne).
- Elles convergent : grand parc, animaux communs, camp niveau 2, boutique, ni mine, ni ruée vers l'or, ni intendance.
- Parties finies au jour 12,2 en moyenne : peu communs achetés vers le jour 9, rares vers le jour 10, trop tard pour rapporter.
- Réputation : fréquentation 64 %, prestige 14 %, objectifs 10 %, boutique 6 %, spectacles 4 %, légendaires 1 %, beauté 0 %, labels 0 %.
- Mine −18 pts, Entrepôt −12, Marché −9. Journaliste −9, Intendant −7, Formateur −5. Paysagiste +7, Lobbyiste +6.
- Objectifs : 4 au niveau 4 : 83 % ; 80 visiteurs : 61 % ; camp niveau 3 : 55 % ; label : 2 % ; Boutique-Kiosque-Snack : 3 %.

Deux défauts de l'étude elle-même : `--fin=08h30` ignoré (seul `08:30` est lu) ; un processus de travail reste bloqué quand l'écriture d'un résultat échoue (`_save`, fichier refusé par Windows), l'étude perd alors une partie et 10 minutes.

## Demandes de l'utilisateur, avis, décision

| # | Demande | Avis | Valeur proposée |
|---|---|---|---|
| 1 | Rares bien moins chers, pour qu'économiser pour un rare soit une orientation | D'accord. Aujourd'hui 40 argent + 2 or (≈ 50) pour 18 d'attractivité, enclos de 15 et aménagement : le pire rapport du jeu (commun : 10 pour 4). La hausse de 4 % par jour rend l'épargne encore plus chère. | 25 argent + 1 or |
| 2 | Creusement moins cher | D'accord : les aquatiques et l'Asie en dépendent (voir l'étude des motifs). | Creuser 20 de travail, 1 pierre (35 et 2) |
| 3 | Peu communs un peu moins chers | D'accord. | −4 argent chacun (20 à 26 au lieu de 24 à 30) |
| 4 | Or : production comme avant, ruée vers l'or viable avec une mine proche et des mineurs | D'accord pour 1,875 par minute (1,75 depuis le 05/11). Seul, ça ne suffira sans doute pas : les rares à 1 or et les labels inutiles laissent l'or sans débouché autre que la vente à 5. À essayer ensuite : vente à 6 (7 jusqu'au Lot U), mine à 120 de travail (150). | 1,875 / min |
| 5 | Intendant : meilleur hors spécialité, plus de réputation quand il est affecté | D'accord. Compris comme : la réputation des décorations augmente. 30 décorations (parc de 300 cases) rapporteraient 7,5 par nuit, à surveiller. | Rendement 0,9 (0,6) ; 0,25 par décoration et par nuit (0,1) |
| 6 | Animateur et Formateur meilleurs hors spécialité | D'accord. | Animateur 0,9 (0,6) ; Formateur 1,0 (0,9) |
| 7 | Comprendre la Braderie | Voir plus bas : elle est dominée par le simple fait de mobiliser le Vendeur. | Proposition à valider |
| 8 | Portes ouvertes à +50 % | D'accord : la carte la plus forte de l'étude (+17 pts). | ×1,5 (×2) |
| 9 | Paysagiste un peu affaibli | D'accord, d'autant que creuser devient moins cher. Le glossaire des métiers est tiré des données (à jour) ; les rendements de récolte n'y figuraient pas : ajoutés. | Aménager ×2,0 (×2,5) |
| 10 | Journaliste : fait baisser l'influence du zoo où elle se trouve, autant qu'un Lobbyiste la fait monter | D'accord, ça lui donne un rôle politique clair. | −1 influence par minute au rival visité |
| 11 | Objectif 4 collaborateurs au niveau 5 | Il était à 5, puis passé à 4 quand le Centre de formation a été supprimé. Le niveau 5 demande 11 jours d'expérience pour des parties de 12 jours : objectif très difficile, sans doute sous 10 %. À surveiller ; à défaut, 3 au niveau 5. | 4 au niveau 5 |
| 12 | 120 visiteurs en une journée | D'accord (61 % à 80). | 120 |
| 13 | Camp niveau 3 avant le jour 8 | D'accord (55 % sans limite). | Avant le jour 8 |
| 14 | Hyène et Ocelot, prédateurs dominants | Voir plus bas : c'est le bonus de prédateur (+2 d'attractivité) qui fait les deux. | Proposition à valider |
| 15 | Étude des motifs déjà présents sur les cartes | Faite, voir plus bas. | — |
| 16 | Asie à la traîne | Voir plus bas. | — |
| 17 | Glossaire : voir le motif en cliquant sur un animal | Fait. | — |
| 18 | Livraison à 15 | D'accord : +0,7 de réputation le jour même pour 25, la carte la moins rentable. | 15 |
| 19 | Objectif de fin à 120 | À essayer : des parties plus longues laissent aux peu communs et aux rares le temps de rapporter. À simuler contre 100 avant de trancher. | À tester |
| 20 | Mécanismes de rattrapage | Voir plus bas. | Proposition à valider |

## Appliqué le 06/11 après l'étude
Rares 25 argent + 1 or ; peu communs −4 ; creuser 20 de travail et 1 pierre ; or 1,875 par minute ; Intendant 0,9 hors spécialité et 0,25 de réputation par décoration et par nuit ; Animateur 0,9 ; Formateur 1,0 ; Portes ouvertes ×1,5 ; Paysagiste aménager ×2,0 ; Journaliste : −1 influence par minute au parc visité (`_update_reportage`, jamais sous 0) ; objectifs : 4 collaborateurs au niveau 5, 120 visiteurs, camp niveau 3 avant le jour 8 (`avant_jour`, `objectif_manque`, `objectif_avancement` : « manqué » à l'écran, l'IA ne le vise plus) ; Livraison 15 ; glossaire : motif au clic sur un animal (`Aide._fiche_animal`), rendements de récolte dans Ressources ; étude : `--fin=08h30` accepté, écriture d'un résultat réessayée (`_save`).

Pas encore appliqué, en attente de votre avis : Braderie, bonus de prédateur, prix de vente de l'or et travail de la Mine, objectif de fin à 120, mécanismes de rattrapage.

Les niveaux d'IA (`ia_niveaux.json`) et les stratégies apprises viennent des règles d'avant ces changements : ils restent jouables, mais une nouvelle étude les ajustera. Ne pas reprendre l'étude d'hier (`etude_reprise.json`) : ses statistiques mêleraient les deux versions des règles.

## Braderie : pourquoi elle ne sert à rien
- Effet : aujourd'hui, une boutique vend ×2, même vide, de l'argent sans réputation. Le calcul (`_sell_souvenirs`) prend le meilleur écart entre ×2 et ce que la boutique vend déjà.
- Jouer la carte, c'est ne pas mobiliser le Vendeur. Or mobilisé, il fait vendre ×2,5 **et** rapporte de la réputation, pour 2 de salaire. La Braderie (×2, sans réputation) est donc toujours moins bonne, sauf si l'on ne peut pas payer ce salaire.
- Si un Vendeur tient déjà une boutique (×2,5), la Braderie n'ajoute rien à cette boutique.
- L'IA ne la joue que sans argent pour le salaire (24 fois en 10 000 parties).
- Proposition : « Aujourd'hui, toutes vos boutiques vendent ×2, en plus de celui qui les tient, et la réputation de boutique compte. » Elle vaut alors le coup avec deux boutiques ou une boutique tenue par un autre.

## Prédateurs, Hyène et Ocelot
- Chaque prédateur donne **+2 d'attractivité** (`zoo.bonus_predateur`), en plus de son attractivité. Pour un commun (4), c'est +50 % pour le même prix (10).
- Hyène et Ocelot sont les deux seuls prédateurs communs : ce sont les meilleurs communs du jeu, d'où leurs taux d'achat (61 et 58 %, contre 20 à 55 % pour les autres).
- Les prédateurs dominent donc à cause du bonus, et l'effet passe surtout par ces deux-là : les joueurs « 1 ou 2 prédateurs » sont surtout des joueurs avec une Hyène ou un Ocelot.
- Contrepartie actuelle : un prédateur ne partage pas son enclos et n'est jamais en liberté. Elle ne pèse pas assez.
- Proposition : bonus de prédateur à +1, ou le retirer et garder la contrainte d'enclos.
- Les motifs jouent aussi (voir l'étude) : à compléter.

## Étude des motifs
200 cartes générées comme en jeu (graines 1000 + 7919 k). Pour chaque espèce, les 8 orientations du motif sont cherchées
dans un carré de 19 × 19 cases centré sur le camp (la taille d'un parc). « Présent » : le motif y existe déjà, sans aménagement.
« Travail » : le travail d'aménagement le plus faible pour l'y faire (aménagements enchaînés, sans les matériaux). Script :
`etude_motifs.gd` (hors du projet, lancé avec `--script`), résultats aussi pour un carré de 37 × 37.

| Espèce | Continent | Type | Rareté | Présent | Travail min. | Achat (étude) |
|---|---|---|---|---|---|---|
| Cerf élaphe | Europe | herbivore | Commun | 100 % | 0 | 53 % |
| Bison d'Amérique | Amérique | herbivore | Commun | 100 % | 0 | 50 % |
| Zèbre | Afrique | herbivore | Commun | 100 % | 0 | 45 % |
| Ocelot | Amérique | prédateur | Commun | 100 % | 0 | 58 % |
| Messager sagittaire | Afrique | aérien | Commun | 99 % | 0 | 46 % |
| Mésange charbonnière | Europe | aérien | Commun | 98 % | 0 | 41 % |
| Grue du Japon | Asie | aérien | Commun | 94 % | 2 | 38 % |
| Hyène tachetée | Afrique | prédateur | Commun | 91 % | 2 | 61 % |
| Yak | Asie | herbivore | Commun | 90 % | 3 | 26 % |
| Carpe koï | Asie | aquatique | Commun | 86 % | 7 | 31 % |
| Bouquetin des Alpes | Europe | herbivore | Commun | 83 % | 5 | 44 % |
| Loutre à joues blanches | Afrique | aquatique | Commun | 82 % | 5 | 20 % |
| Tapir de Baird | Amérique | herbivore | Commun | 76 % | 12 | 32 % |
| Calao bicorne | Asie | aérien | Commun | 72 % | 10 | 33 % |
| Faucon pèlerin | Europe | aérien | Commun | 66 % | 15 | 55 % |
| Ara rouge | Amérique | aérien | Commun | 66 % | 13 | 48 % |
| Salamandre géante | Asie | aquatique | Commun | 60 % | 18 | 32 % |
| Grue couronnée | Afrique | aérien | Commun | 56 % | 11 | 38 % |
| Phoque gris | Europe | aquatique | Commun | 2 % | 68 | 37 % |
| Guépard | Afrique | prédateur | Peu commun | 66 % | 9 | 11 % |
| Capybara | Amérique | herbivore | Peu commun | 57 % | 13 | 13 % |
| Paon bleu | Asie | aérien | Peu commun | 30 % | 17 | 15 % |
| Girafe | Afrique | herbivore | Peu commun | 30 % | 20 | 11 % |
| Loutre cendrée | Asie | aquatique | Peu commun | 27 % | 41 | 15 % |
| Lynx boréal | Europe | prédateur | Peu commun | 18 % | 34 | 13 % |
| Loup gris | Europe | prédateur | Peu commun | 14 % | 41 | 10 % |
| Léopard des neiges | Asie | prédateur | Peu commun | 7 % | 71 | 9 % |
| Loutre d'Europe | Europe | aquatique | Peu commun | 6 % | 48 | 9 % |
| Jaguar | Amérique | prédateur | Peu commun | 4 % | 62 | 10 % |
| Puma | Amérique | prédateur | Peu commun | 3 % | 61 | 10 % |
| Alligator américain | Amérique | aquatique | Peu commun | 0 % | 82 | 11 % |
| Manchot du Cap | Afrique | aquatique | Peu commun | 0 % | 148 | 11 % |
| Bison d'Europe | Europe | herbivore | Rare | 3 % | 47 | 2 % |
| Tigre du Bengale | Asie | prédateur | Rare | 3 % | 102 | 2 % |
| Hippopotame | Afrique | aquatique | Rare | 1 % | 70 | 3 % |
| Lion | Afrique | prédateur | Rare | 0 % | 54 | 3 % |
| Panda géant | Asie | herbivore | Rare | 0 % | 89 | 2 % |
| Dauphin rose | Amérique | aquatique | Rare | 0 % | 112 | 3 % |
| Aigle royal | Europe | aérien | Rare | 0 % | 156 | 2 % |
| Pygargue à tête blanche | Amérique | aérien | Rare | 0 % | 214 | 3 % |

Ce qu'on en tire :
- **Communs** : presque tous existent déjà près du camp. Le motif explique peu les écarts d'achat : le Faucon (66 %) se vend mieux que le Yak (90 %). Hyène et Ocelot sont faciles, mais pas plus que Cerf, Bison ou Zèbre : leur avance vient du bonus de prédateur.
- **Eau + Roche** : le générateur ne place presque jamais l'eau contre la roche. Phoque (2 %), Manchot (0 %, 148 de travail), Alligator, Pygargue et Aigle en souffrent. À redessiner, ou à laisser comme espèces « à aménager », mais alors moins chères.
- **Peu communs** : seuls Guépard et Capybara sont souvent présents. Les autres demandent 30 à 80 de travail : c'est ce qui fait la valeur du Paysagiste, et le creusement moins cher touchera surtout les aquatiques (Loutre cendrée, Loutre d'Europe, Alligator).
- **Rares** : jamais présents, 50 à 210 de travail en plus de l'aménagement exigé. Avec leur prix et l'achat au jour 10, il ne reste pas assez de jours pour qu'ils rapportent.

## Asie
- Les communs d'Asie ne sont pas plus durs à faire près du camp (81 % présents, contre 70 % en Europe, 85 % en Amérique, 86 % en Afrique).
- Ce qui manque : un prédateur commun. Afrique (Hyène) et Amérique (Ocelot) ont le leur, avec ses +2 d'attractivité. L'Europe n'en a pas non plus, mais elle a des communs faciles et deux prédateurs peu communs (Lynx, Loup) plus accessibles que le Léopard des neiges (7 %, 71 de travail).
- 4 communs d'Asie sur 5 demandent de l'eau dans le parc (Koï, Grue du Japon, Salamandre, Calao). L'eau existe, mais l'enceinte doit la contenir et la clôture doit la contourner : un parc bien placé pour l'Asie est plus rare.
- L'IA apprise évite d'ailleurs Yak (−1,5) et Panda (−1,8).
- Pistes : bonus de prédateur réduit (il cesse d'avantager l'Afrique et l'Amérique), creusement moins cher, et un Léopard des neiges moins exigeant (5 cases de roche, dont des cases rarement voisines de la forêt).

## Mécanismes de rattrapage
Aujourd'hui, presque toutes les boucles poussent le premier : visiteurs → argent → animaux → visiteurs ; et l'influence donne à la fois le premier choix au marché, le choix du bonus de nuit et le prestige politique (+3). Les seuls freins (hausse des contrats de 4 % par jour, accusations du Journaliste) touchent tout le monde ou presque jamais.

Propositions, de la plus simple à la plus forte :
1. **Plan de relance de la direction** : chaque nuit, un joueur à plus de 15 points du premier reçoit de l'argent, la moitié de l'écart (au plus 15). Automatique, lisible (Hubert « aide » la filiale en retard), aucun changement pour l'IA.
2. **Premier choix des contrats au dernier** : le soir, les contrats se choisissent dans l'ordre inverse de la réputation ; l'influence garde les collaborateurs, les cartes et le bonus de nuit. C'est le frein le plus efficace des jeux de plateau (Power Grid, Age of Steam), mais il retire une partie de la valeur du lobbying.
3. **Pression des actionnaires** : le premier en réputation gagne 15 % de réputation de fréquentation en moins. Freine le premier sans aider personne ; à combiner avec l'objectif à 120, sinon les parties s'allongent pour tous.
4. **Prestige politique** seulement pour un joueur qui n'est pas premier en réputation.
5. **Objectifs** : +10 au premier qui les remplit, +15 à un joueur à plus de 20 points du premier.

Mon avis : commencer par 1 et 4, qui ne changent pas la façon de jouer, puis essayer 2 si l'écart reste grand. Pour juger, il faut une mesure qu'on n'a pas encore : la part des parties gagnées par le premier au jour 6, et l'écart moyen entre le premier et le dernier à la fin. Je peux l'ajouter à `balance_sim` et à l'étude.
