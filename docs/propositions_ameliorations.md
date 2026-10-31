# Propositions d'amélioration — 30/10/2026

État des lieux après lecture du GDD, des données (`game/data/*.json`), du code et du dernier `rapport_equilibrage.md` (32 parties à 4 IA). Les chiffres proposés sont des **points de départ à valider** par simulation.

---

## 1. Pourquoi le jeu ne ressemble pas encore aux maquettes

Les maquettes de Claude Design sont **la cible finale**, pas l'état actuel. Le handoff découpe le travail en 8 jalons (§12 de `HANDOFF.md`) :

| Jalon | Contenu | État |
|---|---|---|
| 1 | Couleurs, polices, icônes, thème | ✅ fait |
| 2 | Composants (cartes ouvrier, contrat, jetons, ordres) | ✅ fait, mais seulement dans la galerie `ui/galerie_composants.tscn` |
| 3 | **HUD de jour** à la disposition de la capture 03 | ❌ à faire |
| 4 | Monde : terrains, eau, lumière | ❌ à faire |
| 5 | Mode construction | ❌ |
| 6 | Nuit | ❌ |
| 7 | Draft, menu, fin de partie | ❌ |
| 8 | Accessibilité | ❌ |

Ce que tu vois en jeu, c'est **l'ancienne mise en page avec le nouveau thème** (polices, couleurs, boutons). Deux écarts majeurs restent :

1. **L'interface** : barre de ressources à icônes, panneau Construire à onglets avec temps de construction, cartes à portrait en bas, panneau d'unité avec boutons d'ordre, médaillon d'horloge. Tout cela existe en composants mais n'est pas branché dans `main.gd`. C'est le jalon 3, le prochain gros morceau.
2. **Le monde** : la maquette est une **illustration 3D** (perspective, arbres peints, bâtiments en volume). Le prototype est en **2D vu du dessus, en cases**. Le HANDOFF le dit lui-même : le monde 3D vise la version finale. Pour le prototype, je propose de **rester en 2D mais de le restyler** : herbe variée, arbres en sprites, bâtiments dessinés avec les icônes `batiment_*`, chemins et allées aux couleurs de la maquette, ombres douces. Passer en 3D dans Godot est un chantier à part entière, à décider plus tard.

Les **portraits** des cartes (visages peints) ne sont pas fournis dans le handoff. En attendant des illustrations, la galerie utilise l'icône du métier sur fond de couleur de catégorie.

---

## 2. Récapitulatif des métiers

Efficacité : multiplicateur de rendement (1,0 = normal). « Spécialité » = tâche où le métier est meilleur. ✅ = capacité codée, ❌ = décrite dans les données mais **sans effet en jeu**.

### Peu qualifiés (salaire 1, environ 70 % du draft)

| Métier | Vitesse | Spécialité | Capacité | État |
|---|---|---|---|---|
| Manœuvre | 1,0 | aucune (1,0 partout) | Généraliste | ✅ |
| Bûcheron | 1,0 | Extraire du bois ×1,5 | — | ✅ |
| Maçon | 1,0 | Construire en pierre ×1,5 (enceinte, entrée, mine, centre de formation) | — | ✅ |
| Mineur | 0,9 | Extraire pierre et or ×1,5 | — | ✅ |
| Terrassier | 1,0 | Aménager ×1,5 | Un des deux seuls métiers qui peuvent aménager | ✅ |
| Porteur | **1,4** | — | Porte 7 au lieu de 5 | ✅ |
| Guichetier | 1,0 | Guichet ×2 | Fait entrer les visiteurs deux fois plus vite | ✅ |
| Apprenti | 1,0 | aucune (0,8 partout) | « XP ×2 » | ❌ C'est donc juste un Manœuvre moins bon |

### Qualifiés (salaire 2, environ 20 % du draft)

| Métier | Vitesse | Spécialité | Capacité | État |
|---|---|---|---|---|
| Charpentier | 1,0 | Construire en bois ×1,8 (pont, maison, entrepôt, boutique) | — | ✅ |
| Paysagiste | 1,0 | Aménager ×2 | — | ✅ |
| Cantonnier | 1,1 | Routes ×2,5 | — | ✅ |
| Soigneur | 1,0 | Clôtures d'enclos ×1,6 | Posté dans un enclos : +2 d'attractivité pour l'animal soigné | ✅ |

### Cadres (salaire 3–4, rendement manuel 0,6, environ 10 % du draft)

| Métier | Capacité | État |
|---|---|---|
| DRH | S'il a été déployé, licenciement gratuit la nuit | ✅ |
| Lobbyiste | Sort par l'Accès et rapporte +1 influence par minute (les autres : 0,25) | ✅ |
| Marchand | Posté au camp : la vente du stock se fait à plein tarif (sinon à moitié prix) | ✅ |
| Vendeur de souvenirs | Posté à la boutique : souvenirs ×2 | ✅ |
| Contremaître | Aura : +25 % de productivité aux ouvriers à 3 cases ou moins | ✅ |
| Formateur | Au Centre de formation, fait gagner de l'XP | ❌ Le centre se construit mais ne fait rien |
| Architecte | Chantier supervisé : −25 % de ressources | ❌ |

### Traits et améliorations décrits mais sans effet

- **Traits** : Bon élève (XP ×1,5), Débrouillard (chantiers −15 %), Matinal, Têtu, Peureux, Casanier. Le joueur les lit sur la carte, mais **ils ne font rien**.
- **Améliorations** : « Seconde spécialité » est exclue du tirage. Les 7 améliorations propres à un métier (Scie affûtée, Brouette, Pédagogue…) ne sont pas codées.
- **Montée de niveau** : le GDD prévoit « choisir 1 amélioration parmi 3 à chaque niveau ». En jeu, un niveau donne seulement +10 % de rendement et +1 de salaire. Les améliorations ne s'achètent que la nuit, à partir du jour 7.

### Ce que je propose pour les métiers

- **Rendre utile ou supprimer** : l'Apprenti (voir §5 : il pourrait **évoluer** en métier qualifié au niveau 3, ce qui crée un vrai moment de deckbuilding), le Formateur et l'Architecte.
- **Fusionner** le Porteur dans le Manœuvre (vitesse 1,2 et +1 de portage) : le Porteur est un rôle très étroit. *À discuter.*
- **Ajouter** des métiers liés aux nouveaux systèmes proposés plus bas :
  - **Animalier** (peu qualifié) : nourrir et entretenir ×2 (§3.4). Le Soigneur reste le qualifié des animaux.
  - **Vétérinaire** (cadre) : soigne les animaux malades (événement Épidémie, animaux mal entretenus).
  - **Agent d'entretien** (peu qualifié) : propreté du parc et réparations ×2 (§3.4).
  - **Animateur** (cadre) : spectacles et visites guidées, qui augmentent la durée de visite et la réputation.
- Au total, environ 21 métiers au lieu de 19, mais tous avec un rôle clair et **une tâche qui existe en fin de partie**.

---

## 3. Tes demandes, avec une proposition chiffrée

### 3.1 Vitesse des ouvriers
Elle passe de 1,0 à **0,7 case/s** (−30 %). Le bonus de route ×2 est conservé : les routes deviennent plus utiles. Le Porteur (ou le Manœuvre fusionné) garde son avantage relatif. Effet de bord : tous les allers-retours d'extraction ralentissent, donc il faudra rééquilibrer la production (simulation).

### 3.2 Temps de construction (points de travail, 1 point par seconde à efficacité 1,0)

| Bâtiment | Actuel | Proposé |
|---|---|---|
| Route | 8 | 8 (inchangé) |
| Enceinte (segment) | 6 | 6 (inchangé) |
| Clôture d'enclos (segment) | 5 | 8 |
| Pont | 30 | 45 |
| Entrée du zoo | 60 | 120 |
| Boutique | 70 | 150 |
| Entrepôt | 80 | 160 |
| Maison | 90 | 180 |
| Centre de formation | 120 | 240 |
| Mine d'or | 150 | 300 |

Avec la baisse de vitesse, la construction devient un vrai investissement d'équipe, ce qui donne du sens au Contremaître et au Charpentier.

### 3.3 Visiteurs
- **Capacité du parc** : 1 visiteur simultané pour **3 cases intérieures** de l'enceinte. Un petit parc (12×10) accueille environ 26 visiteurs, un grand (22×16) environ 93. Quand le parc est plein, les visiteurs attendent dans la file (20 maximum), puis repartent. Le Grand parc, perdant aujourd'hui (6 % de victoires), y gagne un vrai intérêt.
- **Durée de visite** : **3 minutes en moyenne**, tirée au hasard entre 1,5 et 4,5 minutes (au lieu de 60 s fixes). À la fermeture, tout le monde sort.
- **Arrivées** : par **groupes de 1 à 5** (familles, couples, solos), à intervalles aléatoires, avec une **courbe sur la journée** : montée le matin, pic entre 30 % et 70 % de la journée, puis forte baisse sur le dernier quart, et plus aucune arrivée dans les 30 dernières secondes.
- La réputation reste calculée sur le **nombre moyen de visiteurs présents** : la capacité plafonne donc la réputation, et agrandir son parc devient une décision stratégique.

### 3.4 Bâtiment d'entretien des animaux
**Cuisine des animaux** (2×2, dans l'enceinte) :
- Chaque animal demande **des rations chaque jour** (T1 : 2, T2 : 3, T3 : 4). Un ouvrier posté à la cuisine prépare les rations (l'argent de la nourriture y est payé), puis les **porte** aux enclos, comme pour l'extraction mais en sens inverse.
- Un animal non nourri à la fin de la journée ne compte pas dans l'attractivité. Deux jours de suite, il tombe malade (soin par le Vétérinaire ou le Soigneur).
- Le Soigneur et l'Animalier font ce travail deux fois plus vite. Les soins d'aujourd'hui (+2 d'attractivité) restent.
- **Effet recherché** : la charge de travail **augmente avec la taille du zoo**. En fin de partie, au lieu de couper du bois, on nourrit et on soigne.

### 3.5 Centre de formation (il existe, mais ne fait rien)
- Implémenter : 3 places. Chaque minute passée au centre donne **+0,5 jour d'XP**. Avec un Formateur présent, c'est **×2** et **+2 places** (amélioration Pédagogue).
- Implémenter en même temps : Apprenti (XP ×2), Bon élève (×1,5), et le **choix d'une amélioration parmi 3 à chaque montée de niveau** (Têtu : parmi 2).
- La formation devient une occupation utile pour les ouvriers en trop, surtout en fin de partie.

### 3.6 Fin de partie : des ouvriers qui coupent du bois
**Cause** : les besoins en bois et en pierre s'effondrent une fois le zoo construit, alors que l'argent s'accumule (950 en moyenne en fin de partie) sans rien à acheter d'utile. Il n'existe **aucune tâche dont la quantité augmente avec la taille du zoo**. Propositions, à combiner :
1. **Entretien des animaux** (§3.4) et **propreté du parc** : les visiteurs salissent, et un parc sale perd de l'attractivité. Ce sont les tâches de l'Agent d'entretien.
2. **Usure** : les bâtiments et les clôtures s'usent avec le temps et les visiteurs, et un segment usé finit par lâcher (brèche !). Il faut les réparer.
3. **Bâtiments pour les visiteurs, avec du personnel** : Snack (revenus et satisfaction), Toilettes et Aire de jeux (allongent la visite), Kiosque d'animation (spectacles par l'Animateur).
4. **Grands projets** pour dépenser l'argent et l'or : Aquarium, Vivarium, Grande volière. Ce sont des enclos spéciaux très chers qui accueillent des espèces exclusives et donnent un gros bonus de réputation. Les T3 (jamais installés aujourd'hui) pourraient en dépendre.
5. **Améliorer les enclos** (niveau 2 : décor, abri) pour gagner en attractivité. C'est un débouché pour les aménageurs.

### 3.7 Nouveaux bâtiments (récapitulatif)

| Bâtiment | Rôle | Tâche créée |
|---|---|---|
| Cuisine des animaux | Nourriture | Préparer et livrer les rations |
| Infirmerie vétérinaire | Animaux malades | Soigner |
| Local d'entretien | Propreté et réparations | Nettoyer, réparer |
| Snack | Revenus, satisfaction | Tenir le snack |
| Toilettes / Aire de jeux | Durée de visite, capacité | Entretien |
| Kiosque d'animation | Spectacles : réputation | Animer |
| Bureau de communication | Influence sans sortir de la carte (plus lent que le lobbying) | Travail de bureau |
| Grands projets (Aquarium, Vivarium, Volière) | Espèces exclusives, gros bonus | Gros chantiers de fin de partie |

---

## 4. Le deckbuilding : diagnostic

Aujourd'hui, **une carte est un corps pour la journée**. On pioche 5 ouvriers, on les déploie presque tous (s'il y a assez d'argent), et ils travaillent jusqu'au soir. Les décisions de deck sont donc faibles :
- **Pas de choix dans la main** : on déploie tout le monde. La seule contrainte est l'argent, et elle disparaît en milieu de partie.
- **Le deck grossit à peine** : 10,6 ouvriers en moyenne en fin de partie (logement, 1 embauche par nuit au maximum, maison obligatoire).
- **Aucune synergie** entre cartes, sauf les auras.
- **Progression peu visible** : les niveaux arrivent automatiquement et n'offrent aucun choix.
- **Le cycle du deck compte peu** : piocher son Soigneur aujourd'hui ou demain change peu de choses.

## 5. Le deckbuilding : propositions

Par ordre d'impact estimé :

1. **Un choix à chaque montée de niveau**, ainsi que l'**évolution des cartes** : un Apprenti de niveau 3 devient le métier qualifié de son choix, et un Manœuvre peut se spécialiser. Le deck **se façonne** au fil de la partie.
2. **Des cartes d'action au marché**, en plus des ouvriers. Elles se jouent depuis la main au lieu de déployer un ouvrier, puis vont à la défausse. Exemples : *Heures sup* (un ouvrier travaille 30 % plus vite aujourd'hui), *Prime* (+1 déploiement gratuit), *Portes ouvertes* (visiteurs ×1,5 pendant 2 minutes), *Livraison* (+10 bois), *Recrutement express* (piocher 2 cartes). On obtient ainsi un vrai moteur de deck, et l'argent de fin de partie trouve une utilité.
3. **Des capacités de carte pour les cadres** : chaque cadre peut soit être **déployé** (son travail), soit être **joué** pour un effet immédiat (Architecte : le prochain chantier à −40 % ; Marchand : vente immédiate du stock à +20 % ; DRH : licencier tout de suite et repiocher). Chaque main devient un vrai choix.
4. **Fatigue** : un ouvrier déployé deux jours de suite est moins efficace le second jour. Le cycle du deck compte, et on a intérêt à avoir un deck large.
5. **Garder une carte** : à la fin du jour, on peut garder 1 carte en main pour le lendemain, comme une réserve.
6. **Synergies d'équipe** : +10 % quand un Charpentier et un Maçon travaillent sur le même chantier, ou quand deux ouvriers de même métier travaillent côte à côte, etc.
7. **Embauche plus fluide** : jusqu'à 2 embauches par nuit (la 2e plus chère). Le Camp loge 12 au lieu de 10. Le DRH garde son rôle de « dégraissage ».

Je recommande de **prototyper 1 et 2 en premier** : ce sont eux qui transforment le plus la sensation de deckbuilding.

---

## 6. Autres axes (mes observations)

1. **Cohérence (prioritaire, rapide)** : 2 métiers, 6 traits et 8 améliorations promettent un effet qui n'existe pas. Il faut les implémenter ou les retirer : un joueur qui embauche un « Matinal » doit voir la différence.
2. **Équilibrage** :
   - Les **T3 ne sont jamais installés**, ils sont trop chers et arrivent trop tard. Il faut les rendre accessibles ou les lier aux grands projets.
   - **L'argent explose** à partir du jour 7 (161, puis 315, puis 528…). Il manque des dépenses utiles (§3.6 et §5.2).
   - **Le début est lent** : réputation 0 jusqu'au jour 4, puis croissance exponentielle. Il faudrait un petit revenu dès le premier animal, ou un premier contrat offert.
   - La stratégie **Lobbying ne gagne jamais** (0 %) : l'influence ne rapporte pas assez par rapport à un ouvrier productif.
3. **IA** : environ 99 % de ses tentatives de construction échouent, parce qu'elle retente sans cesse des emplacements impossibles. Corriger ce point accélère les simulations et améliore son jeu.
4. **Lisibilité** : expliquer pourquoi un ouvrier est inactif, afficher le temps restant d'un chantier, notifier quand un animal a faim ou que le parc est plein. Prévoir un **didacticiel** (prévu sur la maquette du menu).
5. **Graphismes** : HUD 03, puis cartes en main au format des maquettes, puis restyle 2D du monde (§1).

## 7. Ordre proposé

| Lot | Contenu | Taille |
|---|---|---|
| A — Rythme | Vitesse, temps de construction, visiteurs (capacité, durée, groupes, courbe) | ✅ fait, avec la nourriture payée seulement une fois le zoo ouvert |
| B — Cohérence | Formation et Formateur, Apprenti, Architecte, traits manquants, choix d'amélioration au niveau | ✅ fait |
| C — Vie du zoo | Cuisine et nourrissage, entretien et usure, nouveaux métiers, bâtiments visiteurs | 🟡 en partie : nourrissage, propreté, snack, kiosque, Animalier, Agent d'entretien et Animateur sont faits. Restent l'usure, le Vétérinaire, les grands projets, l'amélioration des enclos et le bureau de communication |
| D — Deckbuilding | Évolution des cartes, cartes d'action, capacités jouables des cadres | 🟡 en partie : évolution (Apprenti, Manœuvre) et 6 cartes d'action au marché sont faites. Restent les capacités jouables des cadres, la fatigue, la carte gardée en main et les synergies d'équipe |
| E — Graphismes | HUD 03, cartes en main, monde 2D restylé | Gros |

Chaque lot se termine par `sim_test` et un `balance_sim` (maintenant parallélisé, environ 7 minutes pour 32 parties) pour mesurer l'effet.
