# ZooLife : manuel du projet

*État au 14/11/2026, branche `interface-comite`.*

Ce document rassemble ce qu'il faut savoir pour jouer, maintenir et faire évoluer ZooLife : règles, Godot, organisation du code, IA, études, multijoueur, classement en ligne, ressources graphiques et sonores, et publication sur Steam. Pour le détail de chaque lot, voir `CLAUDE.md` (journal technique) et `GDD.md` (règles de conception).

---

## 1. Le jeu en bref

ZooLife est un jeu de gestion vu du dessus. Il mêle deux mécaniques :
- un **paquet de cartes de collaborateurs** : on pioche une main chaque matin, on paie le salaire de ceux qu'on mobilise, on recrute et on améliore ;
- la **construction d'un zoo** sur une carte générée.

On joue de 1 à 4, contre des IA ou entre humains. La carte est la même pour tous, et chacun construit sur sa propre copie. Le récit est celui d'une parodie d'entreprise. Hubert de la Marge, cadre de ZooLife™, commente la partie. La nuit est un conseil d'administration, et la fin un rapport aux actionnaires.

### Modes de jeu
| Mode | Principe |
|---|---|
| **Partie classique** (`course`) | Le premier à **120 de réputation** gagne. Fin forcée au jour 22. |
| **Réserve naturelle** (`nature`) | On ne modifie pas le terrain : pas de Terrassier ni de Paysagiste, pas d'aménagement. Un animal ne s'installe que là où son motif existe déjà. Les enclos sont plus grands (60 cases). |
| **Gestion libre** (`cozy`) | En solo, sans objectif ni fin, sans maladie. 90 d'argent au départ, des naissances, et un livre d'or. |
| **Défis** | 10 jours contre 3 IA fixes, avec un marché identique pour tous. Le score est la réputation du jour 10. 4 défis permanents, plus un défi de la semaine, avec un classement en ligne. |
| **Multijoueur** | De 2 à 4 humains, complétés par des IA. |
| **Tutoriel** | Une partie guidée par Hubert. |

### Déroulement d'une partie
1. **Draft** : 10 tours. À chaque tour, il y a une carte de plus que de joueurs, et chacun en prend une à tour de rôle. Les premiers tours donnent des cartes plus faibles. Les objectifs de la partie sont tirés avant le draft.
2. **Jour** : 5 minutes en temps réel, en pas de temps fixes (10 par seconde).
   - Au matin, on pioche 4 cartes. Mobiliser une carte coûte son salaire. Le bouton **+4** cède la journée d'une carte contre 4 d'argent.
   - On donne des ordres par clic droit : récolter du bois, de la pierre ou de l'or, construire, aménager le terrain, tenir un poste (guichet, cuisine, boutique…), faire du lobbying à la Mairie.
   - Un événement peut toucher tous les zoos pour la journée.
3. **Nuit** : un conseil en étapes, chacun jouant à son tour dans l'**ordre d'influence**.
   - Achats : **contrats d'animaux**, puis **collaborateurs**, puis **cartes d'action**.
   - **Bonus** : le premier en influence choisit un bonus du lendemain, appliqué à tous les zoos.
   - **Équipe** : montées de niveau, puis une amélioration ou un licenciement.
4. **Fin** : un rapport aux actionnaires, avec podium, courbes, sources de réputation et replays des IA.

### Règles essentielles (chiffres dans `game/data/*.json`)
- **Départ** : 30 d'argent, 15 bois, 15 pierre, un paquet de 8 cartes, une main de 4, et un camp en bas de la carte relié à l'Accès.
- **Ouvrir le zoo** demande quatre choses :
  - une **enceinte** fermée (murs, montagnes ou eau avec ponton) ;
  - une **entrée** ;
  - au moins un **animal** installé ;
  - un accès depuis la route.

  Aucun animal ne peut arriver tant que l'enceinte n'est pas fermée.
- **Animaux** (40 espèces sur 4 continents, de 4 types : herbivore, prédateur, aquatique, aérien ; 3 paliers : commun, peu commun, rare) :
  - on achète un contrat la nuit ;
  - l'animal demande un **motif de terrain** (prairie, forêt, eau, rocher, sable), comme dans *Harmonies*, et parfois un aménagement (grand arbre, bassin…) ;
  - on lui construit un enclos (clôtures, ou mur du parc) qui contient ce motif ;
  - les rares ont un effet particulier.
- **Réputation** : surtout les visiteurs, selon l'attractivité des animaux, avec les affinités de continent, et selon la propreté. S'y ajoutent :
  - les spectacles du Kiosque et la boutique ;
  - le prestige politique (+3 et +1 pour les deux premiers en influence) ;
  - les labels achetés en or ;
  - les collaborateurs légendaires (niveau 6) ;
  - les objectifs ;
  - la beauté (décorations de l'Intendance).
- **Capacité** : un visiteur pour 3 cases du parc.
- **Entretien** :
  - la nourriture est payée chaque matin, une fois le zoo ouvert ;
  - la propreté s'entretient (Agent d'entretien) ;
  - les maladies se soignent (Soigneur) ou guérissent seules en 2 nuits.
- **Influence** : du lobbying à la Mairie, efficace à 100 % pour le Lobbyiste et à 60 % pour les autres. Le Journaliste n'en fait pas, et un Journaliste rival en visite retire 1 d'influence par minute. À égalité, l'ordre est tiré au hasard.
- **Plan de relance** : un joueur en retard en réputation a une remise de 1 % par point de retard, 30 % au plus.
- **Contrats** : leur prix augmente de 4 % par jour, et le marché ne se renouvelle que lorsqu'un contrat est acheté.
- **Cartes d'action** : à usage unique, elles prennent une place dans la main. **Cadres** : certains collaborateurs ont une action « Jouer », une fois par jour.
- **Progression** : de l'expérience en jours de travail, un choix d'amélioration à chaque niveau, et le statut légendaire au niveau 6.

---

## 2. Le projet sur le disque

```
C:\Users\danie\Godot\
├─ game\                 projet Godot (ouvrir game\project.godot)
│  ├─ scripts\           code GDScript (voir §4)
│  │  └─ rendu\          rendu BD de la carte (sol, décors, sprites, vie)
│  ├─ data\              règles chiffrées en JSON (voir §5)
│  ├─ assets\bd\         sprites, décors, polices, logos, Hubert
│  ├─ assets\audio\      musiques, bruitages, cris d'animaux
│  ├─ assets\vitrine\    partie enregistrée du fond vivant du menu
│  ├─ ui\                composants, icônes, polices, galerie
│  └─ tests\             tests, mesures, études, outils de capture
├─ docs\                 maquettes (handoff_*), prompts d'images et de sons, SQL, rapports
├─ tools\                anciens générateurs Python (ne plus lancer, voir §10)
├─ GDD.md                document de conception
├─ CLAUDE.md             journal technique (à lire en premier)
├─ lancer_etude.bat      lance une étude des IA
└─ rapport_*.md          rapports d'équilibrage et d'étude
```

Fichiers locaux **à ne jamais commiter** :
- `game/export_presets.cfg` ;
- les `.bundle` ;
- les `.exe` ;
- `etude_reprise.json` ;
- `ia_niveaux_candidat.json`.

---

## 3. Godot

- **Version** : Godot **4.7.2** (pas d'autre version : le format des scènes et l'import en dépendent).
- **Exécutable** (Godot n'est pas dans le PATH) :
  - PC fixe : `C:\Users\danie\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` ;
  - PC portable : `C:\Users\danie\zoodeck\…\Godot_v4.7.2-stable_win64_console.exe`.
- **Écran de référence** : 1600 × 900, en `stretch canvas_items` et aspect `expand`. L'interface s'adapte aux autres résolutions.
- **Lancer le jeu depuis l'éditeur** : F5. Certaines fonctions n'existent que dans l'éditeur :
  - regarder des IA (spectateur) ;
  - le bouton « DÉV. ▾ » du menu ;
  - le replay d'étude.

### Commandes utiles
Remplacez `godot` par le chemin de l'exécutable.
```
godot --headless --path game --import                                  # après tout ajout d'image, de son ou de class_name
godot --headless --path game --script res://tests/sim_test.gd          # test des règles (~40 s)
godot --headless --path game --script res://tests/replay_test.gd       # les replays restent fidèles
godot --headless --path game --script res://tests/modes_test.gd        # modes de partie
godot --headless --path game --script res://tests/defi_test.gd         # tirages identiques des défis
godot --path game --resolution 1600x900 -- --tutoriel --tuto-auto --tuto-dossier=C:/chemin   # tutoriel joué seul
godot --path game -- --seed=7 --autodraft --shot=C:/chemin/capture.png # capture d'écran
```
Les options de capture (`--menu=`, `--defis`, `--statistiques`, `--aide=`, `--conseil=`, `--marche`, `--endday --etape=…`, `--zoom=`…) sont listées dans `CLAUDE.md`.

### Pièges connus
- En `--headless`, une erreur de script **bloque** le processus au lieu de quitter. Lancez les tests avec un délai maximal (`timeout 240 godot …`).
- Après l'ajout d'une `class_name` ou d'une image, relancez `--import`.
- Typage : dans une lambda, `:=` ne déduit pas toujours le type, et un `match` n'y est pas permis.
- `TextureRect` : réglez `expand_mode` **avant** `texture`.
- Pour les règles, gardez `PackedFloat64Array` (`PackedFloat32Array` arrondit et casse les replays).
- Le « É » écrasé en capitales vient de la police Barlow Condensed. Ce n'est pas un bug.

### Export
L'export Windows utilise `game/export_presets.cfg`, un fichier **local, non commité**. Son filtre d'inclusion doit contenir `assets/vitrine/*.txt`, sinon le fond vivant du menu manque. On distribue le `.exe` avec son `.pck`, ou un `.exe` qui embarque le pck. Aucun installateur n'est nécessaire.

---

## 4. Organisation du code

### Le cœur (sans interface, partagé par le jeu, les tests et les études)
| Fichier | Rôle |
|---|---|
| `game_data.gd` | Charge les JSON de `data/`. |
| `map_generator.gd`, `game_map.gd` | Génèrent la carte à partir d'une graine, puis gèrent le terrain, les chemins (A*) et la praticabilité. |
| `match.gd` (`Match`) | La partie : draft, jours, nuit en étapes, marchés, bonus, objectifs, fin, journal pour les replays. |
| `game_state.gd` (`GameState`) | Le zoo d'un joueur : argent, stock, paquet, collaborateurs, chantiers, animaux, visiteurs, réputation, toutes les actions possibles (`deploy`, `place`, `order`, `install_animal`…). |
| `ai_controller.gd` (`AIController`) | L'IA d'un joueur (voir §6). |
| `modes.gd` (`ModesPartie`) | Ajuste une copie des données pour un mode. |
| `defis.gd` (`Defis`) | Défis fixes et défi de la semaine. |
| `commandes.gd` (`Commandes`) | Codage des ordres du joueur, liste blanche, empreinte d'état. |
| `replay.gd`, `sauvegarde.gd` | Replays et sauvegardes (voir §8). |

### L'interface
| Fichier | Rôle |
|---|---|
| `main.gd` | La scène de jeu : dessin de la carte, entrées souris et clavier, HUD de jour, sons du monde, Hubert, conseils, vitrine du menu. **Tout ordre du joueur passe par `_cmd`.** |
| `menu_principal.gd` | Menu (sommaire, fiches de mode, note du défi, fond vivant). |
| `draft_comite.gd`, `conseil.gd`, `marche_soir.gd`, `fin_comite.gd` | Draft, nuit, marché consultable de jour, rapport de fin. |
| `aide.gd`, `tutoriel.gd`, `conseils.gd`, `bulle_hubert.gd` | Glossaire, tutoriel, conseils d'Hubert, bulles. |
| `fenetre_defis.gd`, `classement.gd`, `statistiques.gd`, `fenetre_pseudo.gd` | Défis, classement en ligne, statistiques et succès. |
| `reglages.gd`, `sons.gd` | Réglages (`user://reglages.cfg`), musique et effets. |
| `reseau.gd`, `salon.gd` | Multijoueur (voir §9). |
| `ui_tokens.gd`, `ui/composants/composants.gd` | Couleurs, polices, thème, composants communs. |
| `rendu/*` | Carte en style BD : `CarteBD` (sol en shader), `RoutesBD`, `DecorBD`, `SpritesBD`, `VieBD`, et l'essai isométrique `Vue25D` (F2). |

### Règle d'or du déterminisme
Une partie se rejoue à l'identique à partir de sa graine et de son journal d'ordres. C'est la base des replays, du multijoueur et de la vérification des scores. Donc :
- une règle n'utilise jamais le temps réel ni un hasard autre que les flux de la partie (`rng`, flux du marché, flux du jour) ;
- l'interface ne modifie jamais l'état de la partie autrement que par `_cmd` ;
- tout ce qui fait avancer une partie solo est noté dans le journal (`Match.noter`).

Après une modification de règle, `replay_test` doit passer, et les anciens replays d'étude cessent d'être fidèles. C'est normal.

---

## 5. Données (`game/data/`)

| Fichier | Contenu |
|---|---|
| `buildings.json` | Terrains, extraction, aménagements, bâtiments, marché, zoo (maladie, naissances, enclos), sources de réputation, objectifs, presse, **partie** (argent de départ, objectif 120, jour max 22). |
| `workers.json` | Règles des collaborateurs (main, paquet, expérience, lobbying), métiers (24), traits, améliorations, évolutions, cartes d'action. |
| `animals.json` | 40 espèces : motif, palier, continent, type, prix, attractivité, effets des rares. |
| `events.json` | Événements du matin. |
| `hubert.json` | Répliques d'Hubert par moment, expressions, slogans, rivaux. |
| `personnages.json` | Les 40 personnages (prénom, genre, feuille de sprites). |
| `ia_niveaux.json` | Stratégies des niveaux d'IA, écrites par l'étude. |
| `ia_evolution.json` | Dernière génération d'une étude. |
| `ia_difficile.json` | Ancien repli. |
| `defis.json` | Les défis fixes et leurs IA figées. |
| `classement.json` | Adresse Supabase et **clé publique** uniquement. |

Équilibrer, c'est d'abord modifier ces fichiers. Ensuite, on relance `sim_test`, puis une mesure (`mesure_niveaux`, `balance_sim`), voire une étude.

---

## 6. L'IA

### Comment elle joue
Chaque IA est un `AIController` attaché à un `GameState`. Elle réfléchit toutes les 2 secondes de jeu, et reçoit des appels au matin (`on_day_start`) et aux étapes de la nuit (`on_night_stage`, `on_night_bonus`, `on_night_team`).

- **Choix du parc** dès le jour 1 (`_zoo_score`) : la taille vient de la stratégie, le score tient compte des motifs du marché. En Réserve naturelle, il ne compte que les motifs exacts.
- **Plan de chantier** : murs de l'enceinte de proche en proche, entrée, route des visiteurs, premier enclos.
- **Répartition** (`_repartir`, toutes les 30 s) : les collaborateurs sont partagés entre bâtisseurs et récolteurs pour finir au plus tôt.
- **Postes** une fois le zoo ouvert (guichet, cuisine, entretien, soins), en gardant des bras pour les chantiers (`_builders_needed`, `_release_posts`).
- **Contrats** (`_contract_score`) : la réputation attendue d'ici la fin, moins le travail nécessaire selon l'équipe. Un contrat s'achète s'il a une place dans le parc ou après un agrandissement (`_can_extend_for`), avec une épargne possible pour un meilleur contrat.
- **Embauches** : selon les besoins du plan (`_besoin_bonus`).
- **Cartes d'action** : achetées si leur gain dépasse leur prix, en comptant la journée d'un collaborateur qu'elles remplacent en main (`_cout_place_en_main`).
- **Fin de partie** (`_fin_de_partie`) : les dépenses sont comparées en rendement (Kiosque, Snack, Intendance, Bureau des acquisitions, campagnes) au meilleur contrat du marché.
- **Agence d'intérim** : pour faire venir un aménageur, seulement si c'est rentable (`_agence_rentable`).

### Les stratégies
Une stratégie est un dictionnaire de réglages : taille du parc, `rush_or`, `camp`, `lobbying`, `spectacle`, `eclair`, `agrandir`, cibles de continent ou de type, `explore`… Elle contient aussi des préférences apprises : poids des métiers, traits, animaux, cartes et améliorations. La valeur par défaut est `DEFAULT_STRATEGY` dans `ai_controller.gd`.

### Les niveaux
`Main.strategies_du_niveau` lit `ia_niveaux.json` et décale les niveaux :
- **Facile** = l'ancien Moyen ;
- **Moyen** = l'ancien Difficile ;
- **Difficile** = l'ancien Difficile avec 50 d'argent au départ (`argent_depart`).

Le joueur humain part toujours à 30. Les Défis gardent leurs IA figées (`defis.json`).

### Outils de diagnostic (`game/tests/`)
| Outil | Usage |
|---|---|
| `mesure_niveaux.gd -- --niveau=difficile --graines=1-30 [--argent=N] [--adverses=f.json]` | Jour moyen de victoire, ou duel contre d'autres stratégies. |
| `mesure_ia.gd -- --graines=… [--mixte=reglage] [--niveaux2=f.json]` | Marche par tâche, chantiers quittés, ouverture, duels de réglages. |
| `trace_ia.gd -- --gi=N --joueur=J` | Une IA jour par jour. |
| `nature_trace.gd -- --graine=3 --joueur=0 [--mode=course] [--marche]` | Chaque soir : parc, contrats, chantiers, stock, tâches à midi, et place de chaque contrat du marché. |
| `nature_ia.gd -- --graines=… --modes=…` | Bilan de la Réserve naturelle. |
| `trace_equipe.gd -- --graines=1-6` | Pourquoi une IA mobilise peu de collaborateurs. |
| `balance_sim.gd -- --parties=32` | Comparaison des 29 stratégies écrites. |

### Faiblesses connues
- La **marche** pèse lourd : environ 38 % du temps des collaborateurs. Réduire ce temps perdu est la piste la plus prometteuse pour gagner un ou deux jours.
- Des contrats attendent un Paysagiste ou un Terrassier qui n'est pas pioché.
- **Réserve naturelle** : l'IA installe moins d'animaux (1,5 contre 2,5 à 3,3 en partie classique), et ses contrats achetés attendent leur enclos.
- Les objectifs « 120 visiteurs », « collaborateurs au niveau 5 », « cadres » et « effectif » sont ignorés.

### Piste de travail : comparer l'IA à un joueur humain (Réserve naturelle)
Un bon joueur sait déjà où sont les motifs et choisit son enceinte en conséquence. Pour voir ce qui manque à l'IA :
1. Jouer quelques parties en Réserve naturelle **à graine connue** (`--seed=N --mode=nature`), en solo contre des IA. Le journal de la partie est gardé : c'est le replay de l'écran de fin.
2. Écrire un outil qui rejoue la partie humaine et sort, jour par jour, les mêmes relevés que `nature_trace.gd` :
   - jour d'ouverture ;
   - forme et taille de l'enceinte ;
   - contrats achetés et nuit d'arrivée de chaque animal ;
   - temps passé par tâche ;
   - embauches.
3. Lancer `nature_trace.gd` sur la même graine pour les IA, puis comparer les écarts : choix du parc, ordre des achats, enclos posés près des motifs, part de la marche.

Les écarts montreront les décisions à changer dans `_zoo_score`, `_pattern_fit_maps` et `_night_contracts`.

---

## 7. Les études (entraînement des IA)

Une étude fait évoluer des « génomes » (stratégies et préférences) en les faisant s'affronter. Environ 90 % des parties servent à l'évolution, et 10 % à une finale entre stratégies écrites et apprises.

- **Lancement** : `lancer_etude.bat` à la racine. Il demande :
  - le nombre de parties ;
  - l'heure de fin ;
  - la reprise éventuelle ;
  - l'argent de départ (50 par défaut) ;
  - la mise à jour des niveaux (`auto`, `oui` ou `non`).

  Le script utilise tous les cœurs sauf 2, pour environ 500 parties par heure.
- **Ce qu'elle écrit** :
  - `rapport_etude.md` (forts et faibles, métiers, traits, cartes, animaux, sources de réputation, rattrapage) ;
  - `game/data/ia_evolution.json` à chaque génération ;
  - `etude_reprise.json` (pour reprendre, non commité) ;
  - après la finale, `ia_niveaux.json`. En mode `auto`, ce fichier n'est remplacé que si la finale a au moins 80 % des parties de la précédente ; sinon le résultat va dans `ia_niveaux_candidat.json` ;
  - les replays `replay_plus_courte.json` et `replay_ia_a_zero_N.json`.
- **Règles de prudence** :
  - **Ne modifiez aucun fichier du jeu pendant une étude** : ses processus relisent scripts et données à chaque génération.
  - **Ne lancez jamais `evolution.gd -- --total=0`** pour vérifier que le code compile : cela efface les `replay_ia_a_zero_*.json`.
  - Un message « Parse JSON failed » isolé est sans conséquence.
- **Après une étude** : comparez les nouveaux niveaux aux anciens avec `mesure_niveaux --adverses=…` avant de les garder.

---

## 8. Replays, sauvegardes, statistiques

- **Replay** : la partie est rejouée, rien n'est filmé (graine, paramètres, journal d'ordres). « Revoir sa partie » existe sous chaque IA à la fin d'une partie solo, sauf après une reprise de sauvegarde. Un replay n'est fidèle qu'à la version des règles qui l'a produit.
- **Sauvegarde** : `user://sauvegarde.txt`, enregistrée chaque matin et au retour au menu. Au chargement, la journée est rattrapée au point exact, empreinte vérifiée. Il n'y a pas de sauvegarde en multijoueur. Si `Sauvegarde.VERSION` change, il faut réenregistrer la partie du fond de menu (`tests/vitrine_fond.gd`).
- **Fichiers du joueur** (`%APPDATA%\Godot\app_userdata\…`) : `reglages.cfg` (réglages et conseils vus), `statistiques.json` (pseudo, parties, collection, succès), `cartes/` (vignettes). Ne les supprimez jamais sans l'accord du joueur.

---

## 9. Multijoueur

- **Principe** : chaque machine fait tourner la même partie, avec la même graine et des pas fixes, et **seuls les ordres circulent**.
  - L'hôte envoie 10 trames par seconde.
  - Chaque matin, 20 s de préparation, sans pause ; la vitesse est celle du plus lent.
  - Les empreintes d'état sont comparées toutes les 5 s. Une désynchronisation affiche une alerte, sans resynchronisation.
- **Connexion actuelle** : ENet en UDP sur le port 7777. Il faut une adresse IP directe ou un VPN (type Radmin, ZeroTier).
- **Ajouter un ordre** : l'ajouter à la liste blanche `Commandes.ORDRES` et le faire passer par `_cmd`.
- **Abandon** : un joueur qui part est remplacé par une IA (`Match.remplacer_par_ia`).
- **Test local** : `godot --headless --path game -- --mp-hote --mp-jours=3`, et dans une autre fenêtre `-- --mp-rejoindre=127.0.0.1 --mp-jours=3`.
- **Pour Steam** : passer par le réseau de Steam (invitation d'un ami, relais), ce qui supprime IP et VPN. Seule la couche de transport change, le reste est déjà déterministe.

---

## 10. Classement en ligne (Supabase)

- **Base** : `docs/supabase_classement.sql` crée la table `scores` (sans lecture directe) et les fonctions `soumettre_score`, `classement`, `replay_semaine_precedente` et `vainqueur_semaine_precedente`. Après chaque modification, relancez le script dans l'éditeur SQL de Supabase.
- **Visibilité** : le top 10 est visible par tous, avec les pseudos. Un joueur hors du top 10 ne voit que sa propre ligne, jamais celle des autres.
- **Connexion** : anonyme. `game/data/classement.json` contient l'adresse et la **clé publique**, jamais la clé secrète.
- **Vérifier un score suspect** : copiez la colonne `replay` dans un fichier, puis lancez `tests/verifier_score.gd -- --fichier=…`, et cochez `verifie` ou `exclu`.
- **Semaine** : elle se termine le lundi à 0 h en temps universel.

---

## 11. Graphismes, sons, textes

- **Style** : « BD néo ligne claire », avec une interface « Le Comité ». Les maquettes de Claude Design sont dans `docs/handoff_bd`, `docs/handoff_comite` et `docs/handoff_menus`.
- **Images** : elles sont générées par IA à partir des prompts de `docs/prompt_*.md`, puis découpées par les scripts de `docs/handoff_bd/generateurs/` :

  | Script | Contenu |
  |---|---|
  | `personnages_planches.py` | 40 personnages, 8 gestes, marche de biais |
  | `animaux_planches.py` | animaux |
  | `batiments_planches.py` | bâtiments |
  | `clotures_planches.py` | clôtures |
  | `hubert_logos.py` | Hubert et logos |

  Après un découpage, relancez `--import`.
- **Scripts à ne plus lancer** : `tools/personnages.py` (il écraserait `personnages.json`), `tools/audio.py` (il écraserait les sons), `hubert_logos.py` pour le logo (il réintroduirait la faute de « mérite »).
- **Sons** (`assets/audio/`) : musiques, bruitages et 40 cris `cri_<espèce>`, avec repli sur `cri_<type>`. Ils sont générés par IA et préparés par des scripts (mono, silences coupés, volume égalisé). `Sons.effet`, `Sons.musique` et `Sons.ambiance` acceptent .ogg, .mp3 et .wav, ainsi que les variantes `nom_2`.
- **Polices** : Barlow, Barlow Condensed, IBM Plex Mono, Bangers, toutes sous licence OFL.
- **Textes** : tout est en français, écrit en dur dans le code et dans `hubert.json`. Le vocabulaire visible parle de « collaborateurs » et de « mobiliser » ; les identifiants du code restent `ouvriers`, `deploy`.

### Ajouter du contenu (liste de contrôle)
- **Une espèce** :
  - la décrire dans `animals.json` ;
  - préparer la planche de sprites (`animaux_planches.py`) ;
  - l'ajouter à la table `ANIMAUX` de `SpritesBD` ;
  - ajouter un cri `cri_<id>` ;
  - le glossaire se met à jour seul.
- **Un métier** :
  - le décrire dans `workers.json` (avec `nom_f`) ;
  - l'ajouter aux tables `METIERS` de `SpritesBD` ;
  - ajouter son texte dans `Aide.POSTES` s'il tient un poste ;
  - le prendre en compte dans l'IA (`poids_metiers`, postes) ;
  - les génomes repris sont complétés seuls.
- **Un bâtiment** :
  - le décrire dans `buildings.json` ;
  - préparer le sprite (et ses vues de biais si besoin) ;
  - l'ajouter à la table `BATIMENTS` ;
  - l'ajouter à l'IA si elle doit le construire.
- **Un ordre du joueur** : l'ajouter à `Commandes.ORDRES`, le faire passer par `_cmd`, et éventuellement lui associer un son dans `SONS_ORDRES`.
- **Une réplique d'Hubert** : l'ajouter dans `hubert.json > repliques.<moment>`, puis l'appeler par `GameState.annonce(moment, args, repli)`.

---

## 12. Maintenance : règles de travail

1. **Après toute modification** de `game_state.gd`, `match.gd` ou `ai_controller.gd` :
   - lancez `sim_test` et `replay_test` ;
   - relancez le tutoriel automatique si la partie guidée est concernée.
2. **Captures** : vérifiez l'écran modifié par une capture (`--shot`) à 1600 × 900, et à une autre résolution s'il s'agit de l'interface.
3. **Commits** : un commit par lot, poussé sur `origin`. Ne commitez jamais `export_presets.cfg`, les `.bundle`, les `.exe` ni `etude_reprise.json`.
4. **Pendant une étude** : ne touchez à rien dans `game/`.
5. **Secrets** : seule la clé publique de Supabase va dans le jeu.
6. **Journal** : notez chaque lot dans `CLAUDE.md` (ce qui change, les noms de fonctions, les mesures).
7. **Équilibrage** : il est volontairement repoussé à la fin des fonctionnalités. Il se fait par des mesures chiffrées (`mesure_niveaux`, `balance_sim`, études), jamais à l'intuition seule.

---

## 13. Publication sur Steam

### Avant la sortie
**Indispensable**
- **Une version anglaise.** Le chantier est important : il faut sortir les textes du code (`tr()` et fichiers de traduction de Godot), puis traduire en gardant l'humour d'Hubert. L'allemand, l'espagnol et le chinois peuvent suivre.
- **L'intégration Steam** (extension GodotSteam) :
  - les 12 succès en succès Steam ;
  - la sauvegarde dans le nuage (`user://`) ;
  - éventuellement le classement des défis par Steam ;
  - le multijoueur par invitation et relais Steam.
- **L'équilibrage complet**, et une IA plus homogène, surtout en Réserve naturelle.
- **La solidité** :
  - un rapport de plantage ;
  - des sauvegardes compatibles d'une version à l'autre ;
  - un essai sur un PC modeste (la carte coûte environ 13 ms à dessiner).

**Formalités**
- **Compte Steamworks** : 100 $ de frais par jeu, plus les formulaires fiscaux et bancaires.
- **Déclaration du contenu généré par IA** : images, sons, musiques. Le code n'est pas concerné.
- **Licences** : vérifiez que les générations Suno et ElevenLabs ont été faites avec un abonnement qui autorise l'usage commercial. Les polices, sous licence OFL, ne posent pas de problème.
- **Nom « ZooLife »** : vérifiez qu'il n'est pas déjà pris comme marque ou comme nom de jeu.

**Se faire connaître (le plus tôt possible)**
- **Une page « À paraître »** pour accumuler des listes de souhaits. Elle demande :
  - une image de couverture, faite par un humain de préférence ;
  - 5 à 10 captures ;
  - une bande-annonce de 60 à 90 s.
- **Une démo** (tutoriel et quelques jours), présentée au Steam Next Fest.
- **La bêta** par Steam Playtest, qui remplace l'envoi du `.exe`.

**Finitions**
- Touches modifiables, taille de l'interface, essai sur Steam Deck.
- Plus de contenu pour des captures variées.

### Prix
| Formule | Prix |
|---|---|
| Comparables (gestion ou construction de paquet indépendants) | 15 à 20 € |
| Sortie complète conseillée | **14,99 €** |
| Accès anticipé | 12,99 €, puis 14,99 à 17,99 € à la sortie complète |
| Lancement | 10 à 15 % de remise la première semaine |

Steam prend 30 %, et la TVA ainsi que les prix régionaux réduisent encore la part reçue. Comptez environ 8 à 9 € par vente à 14,99 €. Les ventes dépendent surtout des listes de souhaits accumulées avant la sortie.

---

## 14. Chantiers ouverts

- IA :
  - réduire le temps de marche ;
  - installer plus vite les contrats qui attendent un aménageur ;
  - jouer la Réserve naturelle (voir §6) ;
  - viser les objectifs aujourd'hui ignorés.
- Règle d'égalité d'influence, aujourd'hui tirée au hasard : à décider.
- Influence retirée par un Journaliste rival (1 par minute) : peut-être trop forte.
- Glossaire : l'italique « Pour qui » n'est pas rendu.
- Code mort à nettoyer : `deploy(card, true)`, `unpaid` et `deploiement_gratuit`, toujours utilisés par les tests.
- Fonctionnalités des lots C et D non faites : usure, grands projets, fatigue, synergies.
- Équilibrage complet, puis la feuille de route Steam (§13).
