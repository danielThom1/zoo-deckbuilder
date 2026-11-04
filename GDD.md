# Zoo Builder Deckbuilder — Document de Game Design (v0.2)

> Statut : brouillon. Les chiffres sont **provisoires** et vivent dans `data/*.json` pour l'équilibrage.
> Les points marqués ❓ sont des questions ouvertes.

---

## 1. Pitch

Jeu de gestion vu du dessus, 1 à 4 joueurs (humain contre IA pour la v1). Chaque joueur dispose d'un **deck d'ouvriers** qu'il pioche chaque jour, les envoie extraire des ressources, aménager le terrain et construire, pour bâtir le **zoo le plus réputé**. La partie s'arrête quand un joueur atteint l'objectif de réputation.

## 2. Piliers de design

1. **Deckbuilding d'ouvriers** : on recrute, forme et licencie pour façonner un deck efficace.
2. **Microgestion en temps réel** : la journée exige de réaffecter sans cesse ses ouvriers.
3. **Puzzle de terrain** (inspiré d'*Harmonies*) : chaque animal exige une composition de terrain précise. Plus le terrain naturel convient, moins il faut d'aménagements.
4. **Collection** : la réputation récompense les espèces d'un même continent et les animaux rares qui valorisent un type.

## 3. Structure d'une partie

- Durée cible : ~1 h, soit environ 12 jours.
- **Carte** : générée aléatoirement à partir d'une graine, **identique pour tous les joueurs**. Chaque joueur joue sur sa propre copie.
- **Fin de partie** : à la fin de la nuit où un joueur atteint **100 points de réputation** ❓ (valeur à équilibrer). Les autres joueurs terminent la même nuit.
- Garde-fou : fin forcée au jour 18 ❓.
- **Départage** : réputation, puis argent, puis nombre d'espèces.

### 3.1 Mise en place
1. Génération de la carte (graine commune).
2. Chaque joueur reçoit un **Camp de base** (logement pour 10) avec 30 💰, **15 bois et 15 pierre** pour pouvoir construire des routes dès le début. Le camp est placé **en bas au centre** de la carte, au milieu d'une zone de départ toujours en Prairie (13×9 cases), et une **route d'accès** le relie au bord bas de la carte : c'est la porte vers l'extérieur.
3. **Draft par tours** de 10 ouvriers (10 tours) :
   - à chaque tour, **4 cartes** sont révélées (`cartes_par_tour`, au moins une par joueur) ;
   - chaque carte tire sa catégorie au hasard : **70 % peu qualifiés, 20 % qualifiés, 10 % cadres** ;
   - chaque joueur en prend une, à tour de rôle. À 4 joueurs, la dernière carte revient d'office au dernier joueur ; à moins de 4 joueurs, les cartes restantes sont défaussées ;
   - le premier à choisir est tiré au sort au premier tour, puis **avance d'un joueur à chaque tour** (1-2-3-4, puis 2-3-4-1, puis 3-4-1-2…) ;
   - **les premiers tours sont plus faibles** : au 1er tour, chaque carte a un défaut de plus et une chance sur deux d'avoir une qualité de moins ; l'effet décroît jusqu'au dernier tour, normal (`defauts_debut`).
4. Le deck est mélangé et chaque joueur pioche 5 cartes.

### 3.2 Le Jour (temps réel, 5 min)
- La simulation tourne en ticks fixes (10 par seconde), indépendamment de l'affichage.
- **Alimentation (début du jour, avant tout déploiement)** : **une fois le zoo ouvert au public** (enceinte, entrée, animal et route depuis l'Accès), la nourriture de chaque animal est payée automatiquement, en priorité sur les salaires. Avant l'ouverture, le fournisseur la prend en charge : on ne s'endette pas avant les premiers revenus. Les animaux les plus chers à nourrir sont servis en premier ❓. Un animal qui n'a pas pu être nourri **ne rapporte rien ce tour-ci** : son espèce n'est comptée ni dans la réputation ni dans les visiteurs de la nuit suivante.
- **Déploiement** : les 5 cartes piochées sont en main. Pour déployer un ouvrier, le joueur doit **payer son salaire immédiatement**. S'il n'a pas assez d'argent, la carte reste en main. Le déploiement est possible **à tout moment de la journée** : l'argent gagné par le Marchand peut ainsi servir à déployer d'autres ouvriers en cours de journée.
- L'ouvrier déployé apparaît au Camp de base.
- Les cartes non déployées à la fin de la journée vont à la défausse, sans gagner d'XP.
- Contrôles : **clic gauche** pour sélectionner (boîte de sélection possible), **clic droit** pour donner un ordre sur une case ou un bâtiment.
- Les ouvriers suivent le plus court chemin (A*). Sur une route, la vitesse est **×2**.
- Pause possible en solo, et accélération ×2 / ×4 ❓.
- Tâches possibles : voir §5.
- À la fin du jour, les ouvriers s'arrêtent où ils sont. **L'avancement des chantiers est conservé**, et n'importe quel ouvrier peut le reprendre.

### 3.3 La Nuit (tour par tour, sans chrono)
**Lot N (31/10) : la nuit se joue en écrans successifs**, visibles de tous :
1. **Contrats** (grand écran des contrats d'animaux), puis 2. **Ouvriers**, puis 3. **Cartes d'action** : à chaque étape, chacun passe à son tour dans l'ordre d'influence (jusqu'à 2 contrats, 1 embauche, 1 carte). On voit ce que prennent les autres joueurs, qu'on passe avant ou après eux : leurs achats restent affichés, grisés, sous une étiquette « Pris par … », et le journal les liste. Le tour passe seul après le dernier achat permis, ou avec « Passer ».
   **Lot O** : **un contrat par tour** (le tour passe aussitôt). Les contrats du marché **ne tournent pas** : un contrat pris n'est remplacé qu'au jour suivant, et le joueur suivant a un choix de moins. À égalité d'influence (au dixième près), l'ordre est tiré au hasard. Pendant l'étape Contrats, « Voir mon zoo » affiche à droite les motifs des contrats du marché ; un clic montre sur la carte où le motif existe déjà.
4. **Bonus** : le premier en influence choisit le bonus du lendemain parmi 3 ; tout le monde voit le choix.
5. **Équipe** : chacun, en parallèle, choisit ses montées de niveau, une amélioration ou un licenciement payant, et le licenciement offert par le DRH. Puis « Passer au jour suivant ».
Le bilan de la journée reste affiché à gauche ; la réputation et le journal à droite.

Ordre de résolution (avant le lot N, pour mémoire) :
1. **Revenus du zoo** : billetterie et souvenirs (§7), sans compter les animaux non nourris ce jour-là.
2. **Montées de niveau** : un ouvrier qui a travaillé 2 jours depuis son dernier niveau gagne un niveau et le joueur choisit 1 amélioration parmi 3 (§6.4).
3. **Licenciements** : uniquement si le DRH a été déployé ce jour-là (1 par DRH).
4. **Ordre d'achat** déterminé par l'influence, du plus haut total au plus bas. Seul l'ordre est révélé, jamais les valeurs (§4). **En cas d'égalité**, le joueur dont le zoo a la plus grande superficie (cases à l'intérieur de l'enceinte) passe devant ; si l'égalité persiste, tirage au sort.
5. **Marché des contrats** : chacun peut acheter **1 contrat** au maximum, dans l'ordre d'influence.
6. **Marché des ouvriers** : chacun peut embaucher **1 ouvrier** au maximum, dans l'ordre d'influence. Les nouvelles recrues vont dans la **défausse**.
7. **Vérification de fin de partie** : réputation calculée sans les animaux non nourris ce jour-là.
8. Les marchés se renouvellent.
9. Défausse de la main, puis pioche de 5 cartes. Quand le deck est vide, on mélange la défausse.

> Les salaires et la nourriture ne sont plus payés la nuit : ils sont payés au début du jour suivant (§3.2), la nourriture en premier.

## 4. Ressources

| Ressource | Source | Usage |
|---|---|---|
| 💰 Argent | Marchand (conversion), billetterie, souvenirs | Embauches, contrats, salaires (au déploiement), nourriture des animaux |
| 🪵 Bois | Forêts (**inépuisables** en v1) | Construction |
| 🪨 Pierre | Cases de roche (**inépuisables** en v1) | Construction |
| 🥇 Or | **Une seule mine d'or par carte** | Contrats d'animaux T3, ouvriers d'élite, améliorations |
| 🎖️ Influence | Lobbying : l'ouvrier **sort de la carte** par la route d'accès | Ordre de passage au marché uniquement |

- **Stockage** : le bois, la pierre et l'or extraits sont **portés** jusqu'au Camp ou à l'Entrepôt le plus proche (allers-retours automatiques). C'est ce qui crée l'intérêt des entrepôts et des routes. La construction puise ensuite dans le **stock global**, sans livraison au chantier en v1.
- **Marchand** : convertit le bois et la pierre en argent à tout moment au cours du jour, s'il est déployé et présent au Camp. Les taux sont dans `buildings.json > conversion`.
- **Influence** : elle **ne se remet pas à zéro** et **ne se dépense pas**. Elle est **cachée** : chaque joueur ne connaît que sa propre valeur et voit seulement l'ordre de passage révélé chaque nuit. Le dilemme est donc : faut-il continuer d'investir des ouvriers dans le lobbying sans savoir où en sont les autres ?
- Le bois et la pierre ne s'épuisent pas en v1. On reverra ce point si l'abondance pose problème (le champ `epuisable` est déjà prévu dans les données).

## 5. Tâches des ouvriers

| Tâche | Où | Effet |
|---|---|---|
| Extraire | Forêt, roche, mine d'or | +X ressource par minute selon l'efficacité, puis transport |
| Construire | Chantier (bâtiment, route, enclos) | +points de travail par seconde |
| Aménager | Case de terrain | Transforme le terrain (§8) |
| Lobbying | Hors carte, via la route d'accès | L'ouvrier marche jusqu'à la sortie et disparaît. Tant qu'il est dehors : +1 influence/min × efficacité (Lobbyiste 1.0, autres 0.25). Quand on le rappelle, il revient par la même sortie |
| Vendre | Boutique de souvenirs | Multiplie les revenus de souvenirs de la nuit |
| Commerce | Camp | Conversion de ressources en argent |
| Former | Centre de formation | +XP pour les ouvriers qui s'y entraînent |

- **Construction** (prototype Godot) : on choisit un bâtiment ou un aménagement dans le menu de gauche et on le place sur la carte. Les routes, clôtures et aménagements se placent en glissant la souris. Le coût est payé **au placement** : il est remboursé en entier si on annule avant tout travail, et à moitié ensuite. On envoie ensuite des ouvriers sur le chantier par clic droit, et l'avancement est conservé d'un jour à l'autre. Un ouvrier qui termine un chantier passe tout seul au chantier voisin du même type, dans un rayon de 10 cases (pratique pour une route). Pour l'instant, les bâtiments ne bloquent pas le passage.
- **Effets de zone** : *Charismatique* donne +15 % de productivité aux autres ouvriers dans un rayon de 3 cases, le *Contremaître* +25 % dans un rayon de 3 cases, et *Rabat-joie* −10 % aux autres ouvriers dans un rayon de 3 cases. Les effets se cumulent et s'appliquent à l'extraction, à la construction et à l'aménagement.
- Tout ouvrier peut faire un **travail manuel** (efficacité de base 1.0, ×1.5 dans sa spécialité), sauf s'il a le trait *Col blanc*.
- Les **cadres** ont accès aux tâches spéciales et ont une faible efficacité manuelle (0.6).

## 6. Ouvriers

### 6.1 Catégories
- **Peu qualifiés** (métiers de base) : Manœuvre, Bûcheron, Maçon, Mineur, Terrassier, Porteur, Apprenti. Les plus fréquents au draft. Salaire 1.
- **Qualifiés** : Charpentier, Paysagiste, Cantonnier, Soigneur. Environ 2 par joueur au draft, puis au marché.
- **Cadres** : DRH, Lobbyiste, Marchand, Vendeur, Formateur, Contremaître, Architecte. Rares au draft (≈ 1 par joueur), plus chers, avec des capacités uniques.
- Le Carrier a été fusionné dans le Mineur (pierre et or).

Liste complète : `data/workers.json`.

### 6.2 Statistiques
`vitesse` (cases/s), `efficacite` (par type de tâche), `salaire` (💰/nuit), `cout_embauche`.

### 6.3 Traits
- À la génération, un ouvrier reçoit **0 à 2 traits positifs** et **0 à 2 traits négatifs**, avec une distribution pondérée (voir `workers.json > generation_traits`).
- Le coût d'embauche est ajusté : +15 % par trait positif et −15 % par trait négatif. Le joueur peut ainsi parier sur un ouvrier « défectueux » mais peu cher.

### 6.4 Progression (lot B : implémenté)
- **Expérience** en jours de travail : +1 par jour déployé, ×2 pour l'**Apprenti**, ×1,5 pour **Bon élève**. Un niveau tous les **2 jours d'expérience**, au maximum le **niveau 4** (+10 % de rendement et +1 de salaire par niveau).
- **Centre de formation** : un ouvrier posté dessus (clic droit) gagne **0,4 jour d'expérience par minute**, **×2 si un Formateur** y est posté aussi. 4 places. Une journée complète de formation vaut 2 jours de travail en expérience (4 avec un Formateur), en plus du jour travaillé.
- **À chaque niveau, une amélioration gratuite au choix** parmi 3 (**Têtu** : 2), tirées dans le pool générique et dans celui du métier. Le choix se fait la nuit ; s'il est oublié, la première option est appliquée au matin.
- Améliorations génériques : Pied léger, Expérience, Maîtrise, Remise en question (supprime un défaut), Révélation (nouveau trait positif), Fidélité, **Seconde spécialité** (une tâche hors métier, tirée au hasard, passe à 1,4).
- Améliorations de métier : Scie affûtée (Bûcheron : bois +25 %, portage +1), Brouette (Porteur : portage +2), Chasseur de têtes (DRH : embauches −3), Réseau (Lobbyiste : +1 influence par soir déployé), Négociateur (Marchand : vente +25 %), Pédagogue (Formateur : +2 places), Visionnaire (Paysagiste : aménager à côté d'une case du type voulu ×2).
- L'amélioration payante de milieu de partie (12, à partir du jour 7) reste disponible en plus.

### 6.4 bis Deckbuilding (lot D)
- **Évolution des cartes** : en atteignant le **niveau 3**, un **Apprenti** choisit le métier qualifié qu'il devient (3 tirés parmi Charpentier, Paysagiste, Cantonnier, Soigneur, Guichetier, Animalier), et un **Manœuvre** la spécialité qu'il prend (Bûcheron, Maçon, Mineur, Terrassier, Porteur, Animalier, Agent d'entretien). Ce choix remplace l'amélioration de ce niveau. Il garde ses traits, son niveau et ses améliorations.
- **Cartes d'action** : 3 au marché de nuit (1 achat par nuit). Elles entrent dans le deck et se piochent **dans la même main de 5 que les ouvriers**, ce qui crée le choix entre déployer et jouer. Jouer une carte est gratuit ; elle est à **usage unique** : son effet s'applique, puis elle quitte le deck. Elles ne comptent pas dans le logement. Liste : Heures sup (8, productivité +40 % pour la journée), Prime (4, 4 déploiements sans salaire), Portes ouvertes (10, visiteurs ×2 pour la journée), Livraison (6, +30 bois +25 pierre), Recrutement express (4, piocher 2), Formation express (8, +2 jours d'expérience à tous les ouvriers, deck compris), **Rupture de contrat** (3, licencier l'ouvrier de son choix, sauf ceux sur le terrain), **Promotion** (8, une amélioration au choix parmi 3 pour l'ouvrier de son choix).
- **Agence d'intérim** (bâtiment unique, 12 bois 6 pierre) : en journée, une fois par jour, on peut **remplacer un ouvrier sur le terrain** par une carte de sa pioche ou de sa défausse. Le remplaçant arrive à sa place, garde sa charge et reprend sa tâche ; l'ouvrier remplacé part à la défausse, sans expérience pour la journée. Coût : 4 de frais + le salaire du remplaçant (celui du remplacé n'est pas rendu). Bouton « Remplacer (Agence d'intérim) » dans le panneau de l'ouvrier sélectionné.
- **IA** : elle joue ses actions le matin (Formation express après avoir déployé) et en achète une quand l'argent abonde, 4 au plus dans son deck.

- **Cadres jouables (lot M)** : un cadre en main se **déploie** (son travail) **ou se joue** (bouton « Jouer » sur la carte) pour un effet immédiat. Joué, il ne travaille pas ce jour-là, ne coûte pas de salaire et part à la défausse (il reste dans le deck). Pas de carte gardée pour l'instant (un bâtiment pourra la débloquer).
  - Architecte, *Plan d'urgence* : tous vos ouvriers construisent 50 % plus vite aujourd'hui (Heures sup reste +40 % sur tout le travail).
  - Contremaître, *Cadence* : les défauts de vos ouvriers n'ont aucun effet aujourd'hui.
  - Marchand, *Négoce* : vend tout le stock de bois ou de pierre (au choix) à 140 %, même sans Marché.
  - DRH, *Mutation* : licenciez une carte de votre main, puis piochez-en 2.
  - Lobbyiste, *Coup de fil* : annule pour vous l'événement négatif du jour (Pluie, Canicule, Grève, Tempête) ; sinon +3 d'influence.
  - Vendeur de souvenirs, *Braderie* : la boutique rapporte ×2 aujourd'hui, même sans vendeur posté.
  - Formateur, *Stage de remise à niveau* : retire un défaut à une carte de la main et lui donne une qualité (refusé sans défaut). Mobilisé, il travaille à ×0,9 et les ouvriers à 3 cases ou moins (5 avec Pédagogue) gagnent jusqu'à 2 fois plus d'expérience.
  - Animateur, *Grand spectacle* : +10 d'attractivité aujourd'hui, même sans Kiosque.
  - L'IA joue un cadre quand la situation s'y prête (4 chantiers ouverts pour l'Architecte, événement négatif pour le Lobbyiste, gros stock pour le Marchand, etc.).

### 6.5 bis Capacités et traits (lot B : implémentés)
- **Architecte** : un chantier où il a travaillé rembourse **25 % des ressources** à la fin. Même col blanc, il peut superviser (sans construire). **Débrouillard** : 15 %.
- **Matinal** : commence la journée sur sa dernière case de travail. **Casanier** : −30 % de vitesse à plus de 15 cases du camp. **Peureux** : abandonne sa tâche à 2 cases ou moins d'un enclos de prédateur.

### 6.4 ter Améliorations du camp (v6)
- **Camp niveau 2** (25 bois, 20 pierre, 20 argent, 200 de travail) puis **niveau 3** (30 bois, 40 pierre, 30 argent, 350 de travail) : chacun donne **une carte de plus en main** chaque jour. Ils se construisent sur le camp, un à la fois et dans l'ordre.
- Le coût est pensé pour un vrai dilemme : investir tôt (zoo retardé, mais plus d'ouvriers ou d'actions chaque jour), ou s'en passer. Les simulations comparent les stratégies « Camp amélioré » (niveau 2) et « Grand camp » (niveaux 2 et 3) aux autres.

### 6.5 Logement
- La taille totale du deck est limitée par la **capacité de logement** : 10 pour le Camp, +4 par Maison.
- On ne peut pas embaucher au-delà, ce qui rend les maisons indispensables.

### 6.6 Salaires
- Le salaire est payé **au moment du déploiement** d'un ouvrier, et uniquement pour les ouvriers déployés.
- Le salaire augmente de **+1 par niveau** au-delà du niveau 1 : un ouvrier expérimenté rapporte plus, mais coûte plus.
- **Déploiement gratuit** (anti-blocage) : chaque jour, un ouvrier peut être déployé sans salaire, avec **25 % de rendement** (extraction, construction, aménagement, lobbying). Un joueur sans argent peut donc toujours produire un peu.
- Un ouvrier mal payé peut donc rester en main, mais une carte non déployée est une journée perdue. Les ouvriers chers et inefficaces « bouchent » la main, ce qui garde au licenciement tout son intérêt.

## 7. Le zoo et ses revenus

- Le zoo **ouvre** quand il existe une **Enceinte fermée avec une Entrée** et **au moins un animal** dans un enclos à l'intérieur.
- **Visiteurs par nuit** : `V = 20 × nb_especes × (1 + 0,1 × nb_biomes)` ❓
- **Billetterie** : `V × 1 💰`
- **Souvenirs** : `V × 0,3 💰` par boutique, ×2 si un Vendeur y a travaillé dans la journée.
- Un petit zoo rapporte donc peu, et la croissance devient vite exponentielle. À surveiller.

### 7.1 Implémentation (prototype Godot)
- **Enceinte** : c'est la zone fermée par des segments d'enceinte terminés qui touche l'Entrée. La fermeture se teste en 4 directions, donc un coin ouvert ne crée pas de brèche. Le zoo est **ouvert** s'il y a une Entrée, une enceinte fermée et au moins un animal arrivé dont tout l'enclos est à l'intérieur.
- **Visiteurs** = 20 × espèces nourries dans l'enceinte × (1 + 0,1 × biomes), +2 par prédateur, +2 par animal dont un **Soigneur** s'est occupé dans la journée. Exemple : 1 Zèbre donne 22 visiteurs.
- **Billetterie** : 1 par visiteur. **Souvenirs** : 0,3 par visiteur et par boutique dans l'enceinte, ×2 si un **Vendeur** a tenu la boutique dans la journée.
- **Vente et achat** : le panneau Marché vend ou achète la quantité choisie de bois, de pierre ou d'or (l'or ne s'achète pas). Sans Marchand, la vente se fait à 50 % ; avec le bâtiment **Marché** seul, à 70 % ; avec un **Marchand** posté sur le camp, au plein tarif ; avec un Marchand posté au Marché (bâtiment : 10 bois, 4 pierre), à **125 %**, et le bois et la pierre s'achètent **30 % moins cher** (Négociateur : +25 % de vente et −10 % d'achat en plus). L'achat coûte de base le double du prix de revente.
- **Pioche visible** : un clic sur la pioche montre ses cartes (triées, l'ordre reste caché) et celles de la défausse, et dit si la défausse sera remélangée demain.
- **Emprunt** : une fois par jour, si l'on ne peut payer le salaire d'aucun ouvrier de sa main, on peut emprunter 10 d'argent ; 12 sont retirés automatiquement le soir, quitte à passer en négatif.
- **Dépôt** : un clic droit sur le camp ou un entrepôt avec un ouvrier chargé lui fait déposer sa charge. En fin de journée, ce que portent encore les ouvriers est encaissé automatiquement.
- **Postes fixes** (clic droit) : le Marchand sur le camp ou au Marché, le Vendeur sur une boutique, le Soigneur dans un enclos, n'importe quel ouvrier (et le Formateur) au Centre de formation.

### 7.3 Visiteurs, routes et réputation (v4 : remplace les revenus de nuit)
- **Les visiteurs sont simulés pendant la journée.** Ils apparaissent à la case **Accès**, marchent **uniquement sur les routes** jusqu'à la case devant l'**Entrée** (le camp sert de carrefour, les ponts comptent comme des routes, une route en diagonale passe), puis font la queue. Sans route reliant l'Accès à l'Entrée, personne ne vient.
- **Demande** (visiteurs par jour) = attractivité × 6 × publicité × événement × bonus de nuit.
  - **Attractivité** : ce qu'on appelait avant la réputation. Ce sont les points des espèces nourries de l'enceinte, plus les collections, +2 par prédateur et +2 par animal soigné.
  - **Publicité** = 1 + points / (points + 8), où les points viennent des **campagnes publicitaires** terminées (pour toute la partie). L'influence ne joue plus sur les visiteurs : elle ne sert qu'à l'ordre du marché et au bonus de nuit.
  - **Campagnes publicitaires** (panneau Publicité, en journée) : il faut au moins un ouvrier à l'extérieur (case Accès). Une seule campagne à la fois, payée au lancement : Affiches en ville (40, +1 point), Spot radio (120, +4), Campagne télévisée (300, +12). Elle coûte **40 % de moins** si un ouvrier spécialisé en influence (Lobbyiste) est dehors au lancement. Les ouvriers dehors la réalisent (1 + efficacité de lobbying par seconde chacun) tout en continuant à gagner de l'influence ; une campagne inachevée reprend le lendemain. C'est la façon de dépenser l'argent de fin de partie.
- **Guichet** : il fait entrer 24 visiteurs par minute × le rendement de l'ouvrier au poste. Le nouveau métier **Guichetier** (peu qualifié) va 2 fois plus vite. Plusieurs ouvriers au guichet additionnent leur débit. File de 20 visiteurs au maximum : au-delà, les visiteurs repartent.
- **Recettes encaissées à l'entrée** : billet à **2**, plus **0,6** de souvenirs si la boutique est tenue à ce moment-là (×2 avec un Vendeur).
- **Arrivées (lot A)** : les visiteurs arrivent **par groupes de 1 à 5** (familles, couples, solos), à intervalles aléatoires. L'intensité suit une **courbe sur la journée** : montée le matin, pic entre 30 % et 70 % de la journée, puis baisse, et **plus aucune arrivée dans les 30 dernières secondes**. Le total du jour reste égal à la demande.
- **Capacité du parc** : au plus **1 visiteur pour 3 cases intérieures** de l'enceinte en même temps. Parc plein : la file attend au guichet (20 au maximum, au-delà les visiteurs repartent). Un grand parc accueille donc plus de monde.
- **Visite** : **3 minutes en moyenne**, tirées au hasard entre 1,5 et 4,5 minutes. À la fermeture, tout le monde sort.
- **Réputation** : chaque nuit, on gagne **0,2 × le nombre moyen de visiteurs présents dans le zoo** pendant la journée (0,6 avec des visites de 60 s). La réputation s'accumule. **Objectif : 60**, fin forcée au jour 15.
- **Rythme (lot A)** : les ouvriers se déplacent **30 % moins vite** (`regles.vitesse_ouvriers` = 0,7). Les bâtiments demandent environ **2 fois plus de travail** (maison 180, entrepôt 160, boutique 150, entrée 120, centre de formation 240, mine 300, pont 45, clôture d'enclos 8). Les routes (8) et l'enceinte (6) ne changent pas.

### 7.4 Vie du zoo (lot C)
- **Nourrissage** : chaque animal a une **réserve de rations** (une journée au maximum : T1 2, T2 4, T3 6) qu'il mange au fil de la journée. À 0, il **a faim** et ne compte plus dans l'attractivité. Il arrive avec une journée de rations, et le fournisseur le nourrit tant que le zoo n'est pas ouvert. Ensuite, il faut une **Cuisine des animaux** : un ouvrier envoyé dessus (clic droit) prépare les rations (1 argent chacune, 3 s par ration), les **livre** aux animaux les plus affamés puis revient, en boucle. **Animalier** ×2. Plus le zoo grandit, plus il faut de nourrisseurs.
- **Propreté** (0 à 100) : chaque visiteur présent la fait baisser (0,3 par minute). En dessous de 60, la demande de visiteurs est ×0,85 ; en dessous de 30, ×0,6. Un ouvrier envoyé sur le **Local d'entretien** circule dans l'enceinte et nettoie, même en marchant (12 par minute, **Agent d'entretien** ×2).
- **Snack** (tenu) : les visiteurs qui entrent restent 25 % plus longtemps, donc plus de réputation.
- **Kiosque d'animation** (tenu) : +3 d'attractivité × l'efficacité « animer » (**Animateur** : +6).
- **Nouveaux métiers** : Animalier et Agent d'entretien (peu qualifiés), Animateur (cadre).
- **IA** : elle construit la cuisine dès le premier animal, sur la place libre du parc la plus proche de l'entrée, choisie au moment de construire : la réserver d'avance empêchait les enclos de tenir dans un petit parc. Elle affecte un nourrisseur pour 4 animaux, et un agent d'entretien quand la propreté passe sous 75. Sans Paysagiste ni Terrassier, elle n'achète que des animaux dont le motif existe déjà près du camp. Elle ne construit ni snack ni kiosque.
- **Maladies (lot K)** : chaque nuit, un animal peut tomber malade : 3 % de base, +15 % s'il a eu faim dans la journée, +8 % si la propreté est sous 40, +25 % si un animal de son enclos est déjà malade (contagion). Un animal malade **ne compte pas dans l'attractivité**. Seul le **Soigneur**, posté dans l'enclos (clic droit), le guérit : 60 points de soin, soit environ une minute. L'événement Épidémie rend un animal malade de la même façon. Le bilan de nuit liste les nouveaux malades, et le monde les signale par un carré orange. L'IA envoie son Soigneur aux malades en priorité. Il n'y a donc pas de Vétérinaire : le Soigneur tient ce rôle.
- **Pas encore fait** : usure et réparations, grands projets (Aquarium, Vivarium, Volière), amélioration des enclos, bureau de communication.

### 7.2 Personnel, événements, bonus et milieu de partie (v3)
- **Personnel obligatoire** : pas de billetterie sans quelqu'un au **guichet** (clic droit sur l'Entrée), pas de souvenirs sans quelqu'un à la **boutique**. N'importe quel ouvrier peut tenir ces postes, y compris un Col blanc ou un ouvrier déployé gratuitement, puisque la recette dépend de la présence et non du rendement. La recette est proportionnelle au temps de présence et devient pleine dès la moitié de la journée. Un Vendeur double les souvenirs.
- **Événements aléatoires** (`data/events.json`) : chaque matin à partir du jour 2, 60 % de chance qu'un événement touche tous les zoos. Il y en a 10 : Pluie, Journaliste, Pénurie de bois, Ruée vers l'or, Canicule, Grève, Subvention, Tempête, Beau temps, Épidémie. Ils s'affichent dans une bannière pendant la journée.
- **Bonus de nuit (v6)** : 3 bonus sont proposés et **seul le premier en influence en choisit un**, qui s'applique **à tous les zoos** le lendemain. S'il ne choisit pas, le premier proposé s'applique. Liste : +30 % de bois, +30 % de pierre, +40 % d'or, +25 % de construction, +40 % d'aménagement, +20 % de vitesse, +50 % de lobbying, +20 % de visiteurs. L'influence devient un levier : orienter la journée de tous vers sa propre stratégie.
- **Marché du soir visible en journée** : il est tiré le matin. Le bouton « Marché du soir » montre les ouvriers, contrats et cartes d'action de la nuit à venir, avec son influence et son rang de la veille, pour décider de l'effort de lobbying.
- **Milieu de partie (à partir du jour 7)** : une action par nuit, au choix. **Améliorer** un ouvrier coûte 12 (choix entre 3 améliorations : Expérience, Maîtrise, Pied léger, Remise en question, Révélation, Fidélité). **Licencier** coûte 8. Le DRH garde son licenciement gratuit.
- **Niveaux** : chaque niveau donne +10 % de rendement et +1 de salaire.
- **Achat de matériaux** : bois et pierre s'achètent à tout moment de la journée, au double du prix de revente de base (1 le bois, 1,6 la pierre). L'argent, et donc l'or, se transforme en vitesse de construction.
- **Durée** : objectif ramené à **70 de réputation**, fin forcée au **jour 15**, pour viser environ une heure de jeu.

## 8. Terrain et aménagement (système type *Harmonies*)

- Types de case : **Prairie, Forêt, Eau, Roche, Sable**, plus la **Montagne** (infranchissable, décor) et la **Mine d'or** (unique).
- **Enclos contre le mur (lot K)** : le mur de l'enceinte peut servir de côté à un enclos. La zone doit alors être bordée par au moins une clôture d'enclos, et ne pas toucher l'entrée (sinon c'est l'allée du parc). On économise ainsi les clôtures de ce côté. Visuellement, une palissade ne se raccorde au mur que si l'enclos qu'elle ferme utilise ce mur. L'IA adosse ses enclos aux murs, mais jamais devant l'entrée, ni contre les murs d'un petit parc évolutif qui seront démolis.
- **Ressources épuisables** : une forêt contient 25 bois et devient une prairie une fois rasée ; une roche contient 40 pierres et devient du sable. L'or est inépuisable. L'ouvrier passe tout seul à la case voisine (rayon 10). Les ressources proches s'épuisent, ce qui rend utiles les **entrepôts** près des ressources lointaines.
- **Hors de l'enceinte** : la mine d'or et l'entrepôt ne peuvent pas être construits dans l'enceinte du zoo.
- **Or** : il se vend 7 l'unité, contre 0,5 pour le bois et 0,8 pour la pierre. Un mineur rapporte environ 3 fois plus en or qu'un bûcheron en bois. Une mine proche du camp devient une vraie stratégie.
- **Motifs (v5, à la Harmonies)** : chaque animal demande une **forme précise de cases** à reproduire dans son enclos (rotations et miroirs autorisés), en plus d'une taille minimale. Les motifs font 3 cases pour les T1, 4 pour les T2, et 5 ou 6 pour les T3. Exemple, le Tigre : forêt, eau, forêt, roche, prairie disposées en « P ». Les cartes de contrat dessinent le motif. Quand on vise un enclos, le motif trouvé est encadré en jaune ; sinon, l'emplacement le plus proche est encadré en orange, avec le nombre de cases à aménager.
- **Aménagement réservé** : seuls le **Paysagiste** (×2) et le **Terrassier** (×1,5) savent transformer une case en une autre. Chaque transformation prend du temps (20 à 50 points de travail). Depuis la Prairie, on peut tout obtenir. La Forêt, l'Eau et (avec **Dérocher**, v6) la Roche redeviennent Prairie : n'importe quel terrain s'obtient donc en au plus deux étapes, et l'IA sait planifier ces deux étapes.
- **T3** : ils apparaissent au marché à partir du **jour 7** (au lieu de 8). L'IA garde 3 or si elle a une mine, et, quand l'argent abonde, privilégie la réputation gagnée plutôt que le prix.
- **Démolition** : un bâtiment terminé (mur, clôture, route…) peut être démoli, sans remboursement. Cela sert à agrandir son parc.
- Génération : des motifs de petite taille (zones de ~6 cases), des **lacs** et quelques **rivières**. Toute zone franchissable reste atteignable depuis le camp : là où l'eau ou la montagne isolerait une zone, un **gué** (case de sable) est créé.
- L'aménagement transforme une case en une autre, pour un coût en temps et en ressources (`buildings.json > amenagements`).
- Un **enclos** est une zone de N cases contiguës, entourée d'une clôture, qui doit respecter les **exigences de terrain** de l'animal. Exemple : *Lion, 6 cases dont ≥ 4 Prairie ou Sable et ≥ 1 Roche*.
- Bien placer son zoo sur un terrain naturellement adapté fait gagner un temps précieux, d'où l'intérêt stratégique de la carte commune.

## 9. Contrats d'animaux

- Un **contrat** donne le droit d'accueillir une espèce. Il est acheté au marché et reste en main jusqu'à sa réalisation.
- Pour le réaliser : construire un enclos conforme dans l'enceinte. L'animal arrive alors à la nuit suivante.
- Paliers :
  - **T1** : disponible dès le jour 1, coût modéré.
  - **T2** : apparaît à partir du jour 4.
  - **T3** : apparaît à partir du jour 8, coûte de l'or.
- **Aucune limite** au nombre de contrats détenus en v1.
- **Prix des contrats** (rééquilibrage) : jusqu'à **2 contrats par nuit**, le 2e coûtant 50 % de plus. Le prix en argent augmente aussi de **15 % par animal déjà possédé ou en attente**. L'or ne change pas. La réputation des animaux T3 a été baissée de 2 points.
- **Marché de nuit** (prototype Godot) : 5 ouvriers (35 % peu qualifiés, 45 % qualifiés, 20 % cadres) et 4 contrats parmi les espèces disponibles ce jour-là. Chaque nuit, une carte restante de chaque rangée est retirée au hasard puis le marché est complété. Coût d'embauche : coût du métier ±15 % par trait (3 minimum). Comme le camp loge 10 ouvriers et que le draft en donne 10, **il faut construire une maison avant la première embauche**.
- **IA (provisoire)** : elle ne joue pas encore les journées. Elle gagne 0,5 à 3 points d'influence par jour (cachés), passe au marché selon l'ordre d'influence et prend un ouvrier (70 % du temps) et un contrat (60 %).
- **Installer un animal** : on choisit le contrat dans le menu de gauche, puis on clique à l'intérieur d'une zone **fermée par des clôtures d'enclos terminées**. Au survol, le jeu affiche la zone détectée et les exigences remplies ou non (taille, terrain). L'animal arrive la nuit suivante. Un enclos n'accueille qu'une espèce. La vérification « dans l'enceinte du zoo » viendra avec les revenus des visiteurs.
- **Nourriture** : chaque animal coûte de l'argent au début de chaque jour (T1 = 2, T2 = 4, T3 = 6 depuis l'équilibrage ; c'était 1 / 2 / 3).
- **Combien d'animaux ?** Il n'y a pas de maximum. Un enclos peut accueillir **plusieurs espèces** si sa surface couvre la somme de leurs tailles et si chaque motif tient sur des cases que n'utilisent pas les autres (un prédateur reste seul). Un animal ne vit **jamais sans clôture** : cliquer dans le parc libre de l'enceinte (hors enclos et hors bâtiments) pose en chantier le plus petit enclos rectangulaire autour de la case où son motif existe, en reprenant les clôtures d'enclos et le mur de l'enceinte, et y réserve l'animal (il faut le bois des segments). Une zone fermée par des clôtures d'enclos **encore en chantier** est un enclos prévu : l'animal y est réservé (« Enclos en chantier » dans les contrats, annulable) et ne s'installe qu'une fois les clôtures terminées ; il arrive la nuit suivante. Le bouton de l'enclos proposé pose les clôtures et réserve l'animal d'un coup. Les limites viennent d'ailleurs : un contrat par nuit, chaque espèce une seule fois par joueur, les espèces disponibles au marché, et la place dans l'enceinte. Un animal non nourri ne compte pas ce tour-ci (§3.2).
- Liste : `data/animals.json`.

### 9.0 Motifs et aménagements d'enclos (lot M)
- **Motifs tournables** : un motif se pose dans n'importe laquelle de ses 8 orientations (4 rotations, et leur miroir).
- **Motifs plus grands et mixtes** : palier 1, 4 à 5 cases sur 2 terrains ; palier 2, 7 à 9 cases sur 2 ou 3 terrains ; palier 3, 12 cases sur 3 ou 4 terrains. Les tailles d'enclos suivent (6, 8 à 10, 13 à 15 cases). Le Paysagiste et le Terrassier deviennent nécessaires pour la plupart des espèces.
- **Aménagements d'enclos requis** (onglet Zoo, 1 case, à poser dans un enclos clôturé ou en chantier, hors du motif) : **Grand arbre** (8 bois : Girafe, Ours brun, Jaguar, Panda roux, Gorille), **Rocher d'observation** (8 pierre : Lion, Loup, Lynx, Phoque, Aigle royal, Panthère des neiges), **Bassin profond** (6 pierre : Éléphant, Rhinocéros, Tapir, Tigre, Manchot, Hippopotame), **Abri chauffé** (4 bois, 4 pierre : Crocodile, Dragon de Komodo). Le palier 1, le Yak, le Dromadaire et l'Addax n'en demandent pas. Un aménagement en chantier réserve l'animal, qui arrive la nuit suivant la fin des travaux. L'enclos proposé (bouton ou clic dans le parc) pose aussi l'aménagement requis.
- **Voisinage** : +2 d'attractivité par animal voisin du même continent, dans un autre enclos à 2 cases au plus (de part et d'autre d'une clôture). Indiqué dans la fiche de l'animal.

### 9.1 Origines et types (v6)
- Chaque animal a un **continent d'origine** (Afrique, Europe, Asie, Amérique, Océanie) et un **type** (terrestre, aquatique, aérien). On compte 38 espèces, dont 3 oiseaux ajoutés : Vautour, Toucan, Aigle royal.
- **Affinités** : la réputation gagnée chaque nuit augmente de **+5 % par espèce au-delà de la première venant du même continent**. Par exemple, 3 animaux d'Afrique et 2 d'Europe donnent +15 %.
- **Aide au placement** : en choisissant un contrat, les enclos où l'animal peut aller sont surlignés en vert, ceux qui demandent des aménagements en orange. S'il n'y en a aucun, le jeu propose un petit enclos libre dans l'enceinte (clôtures en pointillés, bouton pour les poser).
- **Bonus de nuit thématiques** (choisis par le premier en influence, pour tous) : Festival des oiseaux (aériens ×1,5), Journée de l'océan (aquatiques ×1,5), Semaine de l'Afrique (×1,4), de l'Europe (×1,4), des Amériques (×1,5), Asie-Océanie (×1,5), appliqués à l'attractivité des espèces concernées. Construire autour d'un continent ou d'un type devient une stratégie, et l'influence permet de la servir.
- **Or des contrats** : l'or manquant pour un contrat s'achète en argent au moment de l'achat, au prix du marché (14 par or, le double du prix de revente). Les T3 coûtent environ 25 % d'argent de moins qu'avant (33 à 39, plus 2 à 3 or).

## 9.2 Rework du 04/11 (remplace les valeurs précédentes)
- **40 espèces, 4 continents** : 10 par continent. Trois raretés (commun, peu commun, rare), toutes disponibles dès le premier soir ; le marché montre toujours au moins un rare et un peu commun. Un rare coûte 40 argent et 2 or ; un peu commun apporte 12 d'attractivité (4 pour un commun, 14 pour un rare).
- **Effets des rares** : Aigle royal, Dauphin rose de l'Amazone, Panda géant et Lion donnent +5 d'attractivité par autre espèce de leur type (aérien, aquatique, herbivore, prédateur). Bison d'Europe : souvenirs +50 % de réputation. Pygargue : Kiosque +50 % de réputation. Tigre du Bengale : +1 carte par jour. Hippopotame : chaque nuit, échange d'un ouvrier contre un ouvrier de la rangée.
- **Enceinte** : une montagne sert de mur, et les murs se construisent sur l'eau.
- **Économie** : deck initial de 8, main de 4, récolte +25 %, chantiers −25 %. Une Maison loge un seul ouvrier (5 bois, 2 pierre, rapide). Légendaire au niveau 6. Centre de formation plus rapide à bâtir et à former. Traits accentués.
- **Maladie** : un animal guérit seul au bout de 2 nuits, ou plus vite avec un Soigneur.

- **Prestige politique** : chaque nuit, +3 pour le premier en influence, +1 pour le deuxième.
- **Cabinet de recrutement** : remplacer une carte coûte 12 (peu qualifié), 25 (qualifié) ou 50 (cadre).
- **Labels** : s'achètent en or à la Bourse des ressources, zoo ouvert ; le prix double sans Marchand déployé.

## 10. Réputation

**Lot S : plusieurs façons de gagner de la réputation** (objectif porté à **100**, fin forcée au jour 22) :
- **Fréquentation** : 0,3 × visiteurs présents en moyenne (inchangé).
- **Spectacles et boutique** : le Kiosque tenu rapporte 3 de réputation par journée (×2 avec un Animateur), la boutique 0,04 par unité d'argent de souvenirs.
- **Prestige politique** : chaque nuit, le premier en influence gagne +1, le deuxième +0,5 (avec au moins 1 d'influence).
- **Labels** (une fois chacun, en or, seulement avec un Marchand déployé) : Zoo certifié (8 or, +5), Club des mécènes (15 or, +10), Label d'excellence (25 or, +15).
- **Ouvriers légendaires** : un ouvrier qui atteint le niveau 5 rapporte +5 au parc.

- Points par espèce, selon le palier : T1 = 4, T2 = 8, T3 = 14 ❓ (voir le JSON, par espèce).
- Bonus de collection ❓ : 3 espèces du même biome → +5.

## 10 bis. Objectifs, presse (04/11)
- **Objectifs des actionnaires** : 3 objectifs tirés après le draft (`buildings.json > objectifs`), les mêmes pour tous. Chaque joueur qui en remplit un gagne **+10 de réputation**, une fois, à la fin de la journée.
- **Journaliste** (cadre, 12 d'embauche, 3 de salaire) : envoyé à l'extérieur, il part en reportage dans un parc rival. Le parc est sous **brouillard de guerre** : seules les cases à 6 cases ou moins de son chemin sont dévoilées, et elles le restent. Il se promène seul, ou va où on clique. **Article** (40, un par jour) : publicité du rival ×0,8 pendant 3 jours. **Accusation** (90, une par jour) : un collaborateur en vue est licencié d'office, s'il reste au rival plus de 3 collaborateurs ; un légendaire emporte ses 5 points de réputation.
- **Bonus retirés** : diversité et collection de biomes, voisinage. Bonus de type en enclos partagé retiré aussi. Restent les paliers de continent et les effets des rares.
- **Snack** : visites 50 % plus longues et 1 d'argent de plus par visiteur.

## 11. IA (prototype Godot)

- **Architecture** : `Match` porte l'horloge, le draft et le marché, qui sont partagés. Chaque joueur (`GameState`) a sa propre carte, générée avec la même graine. L'IA (`AIController`) n'utilise que les actions d'un joueur humain.
- **Jour** : l'IA choisit au premier jour un emplacement d'enceinte proche du camp, aux murs constructibles. Elle place ensuite par priorité une maison (si le logement est plein), les enclos des contrats (aménagements puis clôtures, partagées entre enclos voisins), l'enceinte et l'entrée, la boutique, la mine d'or puis la route. Les ouvriers vont au chantier le plus adapté à leur spécialité, sinon à la ressource qui manque. Les postes fixes (Lobbyiste, Vendeur, Soigneur, Marchand en fin de journée) sont respectés.
- **Emplacement du zoo (v5)** : l'IA choisit son emplacement **après son premier contrat** (ou au jour 3). Elle privilégie un terrain qui se prête déjà au motif de ses animaux, avec des murs constructibles et une entrée qu'une route peut rejoindre, sans s'éloigner du camp. Une part de hasard propre à chaque IA fait que toutes ne choisissent pas le même endroit.
- **Taille du parc** : stratégies Petit parc (12×10), Moyen (16×13), Grand parc (22×16) et **Parc évolutif**. Ce dernier commence par un petit parc collé au mur de l'entrée d'un grand parc prévu. Dès que le petit parc tourne (jour 6 ou 2 animaux), il construit l'enceinte du grand parc puis démolit les anciens murs intérieurs.
- **Trésorerie** : l'IA garde toujours de quoi payer une main complète et nourrir ses animaux. En dessous de ce seuil, elle passe en mode survie : aucun nouveau chantier, et la récolte est vendue le soir.
- **Nuit** : licenciement de la carte la plus faible (si le DRH a travaillé), achat du contrat avec le meilleur rapport réputation / coût s'il rentre dans l'enceinte, embauche si une place de logement est libre.
- **Stratégies** (réglages pour les simulations) : Équilibrée, Lobbying, Petits contrats, Gros contrats, Sans embauche, Économe. Les simulations se lancent avec `tests/balance_sim.gd` et écrivent un rapport dans `rapport_equilibrage.md`.
- **Robustesse** : le guichet et la boutique ne sont tenus qu'une fois le zoo ouvert. L'ouvrier déployé gratuitement est un ouvrier manuel. Quand l'équipe est réduite (2 ouvriers ou moins) et le zoo fermé, les chantiers passent avant les soins. Un contrat sans plan d'enclos possible ne bloque plus l'achat d'un autre.
- **Montées de niveau** : l'IA choisit d'abord de guérir un défaut, puis de renforcer sa spécialité, puis une amélioration de métier. Elle valorise l'Architecte, mais évite encore le Formateur, car elle ne construit pas de Centre de formation.

## 11 bis. IA (plan initial)

- IA à **règles et priorités** (utility AI) qui utilise exactement les mêmes commandes qu'un joueur.
- Boucle de décision du jour : toutes les 2 s, pour chaque ouvrier inactif, elle évalue des tâches candidates (ressource manquante pour un chantier prioritaire, etc.).
- Nuit : achats évalués sur une heuristique (biomes manquants, coût, faisabilité du terrain).
- Niveaux de difficulté : multiplicateur d'efficacité et qualité des heuristiques.

## 12. Architecture technique (recommandations)

- **Moteur** : Godot 4.7 (2D vu du dessus). Le projet est dans `game/`, les données dans `game/data/`. Le prototype navigateur (`prototype/`) est conservé pour référence mais n'évolue plus.
- **Simulation déterministe** à ticks fixes, séparée du rendu. Cela facilite l'IA, les tests, les rejeux et un futur multijoueur.
- **Données** dans `data/*.json`, chargées au démarrage.
- **Ordre de développement proposé** :
  1. Carte, déplacements et extraction (1 joueur, 1 jour).
  2. Cycle Jour/Nuit, deck, pioche et salaires.
  3. Construction, aménagement et enclos.
  4. Marchés, contrats et réputation.
  5. IA.
  6. Traits, niveaux et cadres.
  7. Graphismes.

## 13. Décisions prises (v0.2)

| # | Sujet | Décision |
|---|---|---|
| 1 | Nourriture des animaux | Oui, coût en argent chaque nuit selon le palier |
| 2 | Ressources pour construire | Stock global (livraison au chantier : à revoir plus tard) |
| 3 | Salaires | Payés au déploiement, uniquement pour les ouvriers déployés. Sans argent, pas de déploiement |
| 4 | Épuisement des ressources | Non en v1 (à revoir si besoin) |
| 5 | Achats par nuit | 1 contrat + 1 ouvrier |
| 6 | Limite de contrats | Aucune en v1 |
| 7 | Taille de la carte | 64×64 |
| 8 | Influence | Ne se dépense pas, cachée aux autres joueurs, seul l'ordre est révélé |
| 9 | Animal non nourri | Nourriture payée au début du jour, avant les salaires. Un animal non nourri ne compte pas ce tour-ci (ni réputation, ni visiteurs) |
| 10 | Égalité d'influence | Le zoo de plus grande superficie passe devant, puis tirage au sort |

## 14. Questions ouvertes restantes

1. Valeur exacte de l'objectif de réputation (100 proposé) : à fixer après les premiers tests.
2. Ordre de service de la nourriture quand l'argent manque : les plus chers d'abord (proposé), ou choix du joueur ?
