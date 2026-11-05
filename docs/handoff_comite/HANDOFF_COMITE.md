# Interface « Le Comité » — spécification d'intégration

Direction retenue le 05/11/2026 par l'utilisateur, à partir du brief `docs/prompt_redesign_interface/PROMPT.md`.
Idée : **la carte occupe tout l'écran**. Tout le reste tient dans un bandeau fin en haut, un dock en bas et des volets qu'on ouvre à la demande. Le ton reste celui d'une satire d'entreprise : le bandeau ressemble à des cotations boursières, la nuit à un conseil d'administration, la fin de partie à un rapport aux actionnaires.

Ne touche ni aux règles, ni à l'IA, ni aux JSON (`game_state.gd`, `match.gd`, `ai_controller.gd`, `data/*.json`). Les sprites, portraits, logos et têtes d'Hubert restent tels quels.

## 0. Ce qui est déjà fait (commit « Interface Comité : fondations et écran de jour »)

| Élément | Où | État |
|---|---|---|
| Jetons Comité (couleurs, `H_BANDEAU`, `H_DOCK`), `panneau()`, `entete()`, `police_mono()`, `police_italique()`, Barlow 600 | `scripts/ui_tokens.gd` | fait |
| Variations de thème `BoutonBandeau`, `BoutonOutil`, `BoutonSeance`, `Chiffre`, `EnteteComite` ; infobulle encre et texte blanc ; ombres pleines verticales (0, 4) | `ui_tokens.gd > build_theme()` | fait |
| Polices IBM Plex Mono 500/600 (OFL) et Barlow 600 normal/italique | `assets/bd/polices/` | fait |
| `Composants.jeton_dock()`, `badge_ouvrier()`, `badge_action()`, `entete_comite()` | `ui/composants/composants.gd` (fin du fichier) | fait |
| Bandeau du haut : course à 100 avec logos, réputation et variation depuis le matin, flash d'événement (`event_label`), vitesses II ×1 ×2 ×4 ×8 ×16, aide, réglages, menu | `main.gd > _build_ui()` | fait |
| Dock : 6 ressources (2 × 3), pioche et défausse cliquables, Tout mobiliser, horloge (`_draw_horloge`, remplace le médaillon), « LEVER LA SÉANCE » | `main.gd > _build_ui()` | fait |
| Main en badges de 132 × 176 px qui montent de 44 px au survol ; états à mobiliser, manque d'argent, peut jouer (cadre), sur le terrain, sélectionné, hors carte ; cartes d'action | `main.gd > _rebuild_hand()` | fait |
| Colonne d'outils (Bâtir, Zoo, Bourse, Pub, Marché) ; volets au même emplacement (`ouvrir_outil()`, `_appliquer_outils()`) ; widget du zoo quand aucun volet n'est ouvert | `main.gd` (fin du fichier) | fait |
| Ordre du jour en haut à gauche : plan de lancement (zoo fermé), puis alertes à traiter et objectifs ; les contrats à installer y sont déplacés | `_build_ordre_du_jour()`, `_update_ordre_du_jour()` | fait, à enrichir (§2.1) |
| Option de capture `--outil=construire\|zoo\|bourse\|pub` | `main.gd` | fait |
| Tutoriel : `_onglet()` et `_bourse()` ouvrent le bon volet | `scripts/tutoriel.gd` | fait, le tutoriel automatique va au bout (58 étapes) |
| `sim_test` et `replay_test` | — | passent |

Captures de l'état actuel : `etat_actuel/*.jpg`. Les cibles sont dans `maquettes/*.png`.

**Reste à faire : tout le §2.** La nuit, le marché, le menu, la fin et la pose d'enclos sont encore dans l'ancien style.

## 1. Références

- `maquettes/` : les cibles à 1600 × 900, exportées depuis le canevas validé par l'utilisateur. Les chiffres et les textes sont des exemples, ce sont les valeurs du jeu qui comptent.
- `sources/` : le source HTML de chaque maquette. Ouvre-le pour lire une cote, une couleur ou une taille exacte. Pour les voir rendues : `cd docs/handoff_comite/sources && python -m http.server 8765`, puis `http://localhost:8765/C1_Debut_A.dc.html`.
- `maquettes/90_feuille_de_style.png` et `91_briques.png` : les jetons et tous les états.

### Règles transversales (à vérifier sur chaque écran)
1. **La carte d'abord.** En journée, rien de permanent en dehors du bandeau (34 px), du dock (96 px), de l'ordre du jour (320 px, haut gauche) et de la colonne d'outils (48 px, haut droite). Tout le reste s'ouvre en volet et se referme.
2. **Pas de défilement pour l'essentiel.** Un panneau trop long passe en onglets ou en fenêtre.
3. **Jamais la couleur seule** : qualité = cercle bleu, défaut = carré orange ; gain ▲ et perte ▼ toujours avec le signe ; terrains du motif avec leur lettre (P, F, E, R, S) ; indisponible = pointillé + raison écrite (« Manque 2 or »).
4. **Chiffres en IBM Plex Mono** (`UiTokens.police_mono()`, variation `Chiffre`) : ressources, coûts, heures, scores. Argent : icône grise et chiffre à l'encre. Or : chiffre `OR_TEXTE` (#8A6400).
5. **Vocabulaire** : collaborateurs, mobiliser, céder sa journée, lever la séance, signer (un contrat), ordre du jour.
6. **Textes longs** : prévois les libellés « Vendeuse de souvenirs », « Seconde spécialité : Construction en pierre », « Cabinet de recrutement ». Utilise `autowrap` dans les fiches, et `OVERRUN_TRIM_ELLIPSIS` + infobulle sur les badges.
7. **Ancrages** (planche `90`) : bandeau `TOP_WIDE` ; dock `BOTTOM_WIDE` ; ordre du jour `TOP_LEFT` ; outils et volets `TOP_RIGHT` / `RIGHT_WIDE` (hauteur = écran − bandeau − dock − 28) ; fenêtres centrées (1280 × 700 maximum, à réduire sous 1400 px de large). À 1280 × 720, le dock garde ses 2 × 3 ressources, et la main défile dans `hand_scroll`.

## 2. Écran par écran

### 2.1 Jour — début, zoo fermé · `maquettes/01_jour_debut_zoo_ferme.png`
Fait : plan de lancement, bandeau, dock, badges. À faire :
- [ ] Un bouton **« Montrer »** sur chaque étape : il centre la caméra sur l'emplacement utile (entrée proposée, bord de l'enceinte à fermer) et pose un **repère numéroté** sur la carte (goutte jaune cernée, numéro en mono). Le dessin se fait dans `_draw()` de main.gd.
- [ ] Ajouter une étape **« Relier l'entrée à la ville »** (route) si la règle l'exige. Elle n'est pas dans `zoo_status()` : vérifie la condition qu'utilisent les visiteurs.
- [ ] Le 1er jour, une **infobulle encre** pointe le badge survolé : « Mobiliser : payez son salaire… / +4 : il cède sa journée ». Elle s'affiche une fois, puis jamais plus (`Reglages` ou `user://`).
- [ ] La petite bulle d'Hubert (`BulleHubert`, ancrée sur `hand_box`) doit rester au-dessus de la main, à gauche des badges, sans recouvrir l'ordre du jour. La grande bulle d'événement ne doit pas cacher l'ordre du jour : décale-la au centre, sous le bandeau.

### 2.2 Jour — collaborateur sélectionné · `02_jour_selection_inspecteur.png`
Le volet de droite affiche déjà la fiche existante (`_rendre_fiche`, `_fiche_ouvrier`). À mettre au style de la maquette :
- [ ] En-tête encre « SÉLECTION · 1 sur 4 », avec ‹ › pour passer d'un collaborateur sélectionné à l'autre et « — » pour réduire le volet.
- [ ] Bloc d'identité sur fond `CATEGORIES[cat].portrait` : portrait 78 × 92, nom en Barlow Condensed 28, métier, pastilles « Cadre » et « Niveau 3 / 6 », barre d'expérience en mono.
- [ ] Trois onglets : **Fiche** (le métier en une phrase lisible sans survol, les traits avec leur effet, la tâche en cours avec sa barre et ce qu'elle rapporte, la grille de 6 ordres avec leur touche de raccourci, le salaire), **Rendement** (les coefficients actuels), **Carrière** (expérience, améliorations).
- [ ] Les **ordres en file** (Maj + clic droit) se dessinent sur la carte en pointillés jaunes, avec une étiquette encre « Ordre en file : Boutique → Construire ».
- [ ] Fiches bâtiment et animal : même gabarit (en-tête encre, bloc d'identité, contenu, boutons d'action en bas : Démolir, Échange d'intérim…).

### 2.3 Jour — pose d'un enclos · `03_jour_pose_enclos.png`
S'appuyer sur `_compute_animal_hints`, `_propose_enclosure`, `_build_proposal_box` et `_build_proposal`.
- [ ] **Bandeau de contrat** centré sous le bandeau du haut (940 px de large) : illustration, « CONTRAT À INSTALLER · 1 sur 2 », nom, aménagement requis, **motif en cases lettrées**, puis les boutons « Valider · Entrée », « Autre ⇥ » (emplacement proposé suivant), « Tourner R » et « Annuler ».
- [ ] **Voile** `ENCRE` à 28 % sur la carte. Sur l'emplacement proposé : gabarit en cases, motif teinté et lettré, contour blanc en pointillés sur un trait d'encre. Une case impossible est hachurée orange avec un ✕.
- [ ] Une étiquette sarcelle « ✔ Motif trouvé · emplacement proposé 1 sur 3 » et une autre encre avec le coût de la clôture.
- [ ] **Légende du motif** en bas à gauche, au-dessus du dock.
- [ ] Les contrats à installer de l'ordre du jour déclenchent ce mode (c'est déjà le cas via `_set_build({"kind": "animal"…})`).

### 2.4 Marché du soir consulté en journée · `04a_marche_contrats.png`, `04b_marche_collaborateurs.png`, `04c_marche_cartes.png`
Remplacer le contenu de `_rebuild_market_preview()` (fenêtre `market_root`). L'utilisateur veut **un écran par catégorie**.
- [ ] Fenêtre 1280 × 700 centrée, fond `FOND_FENETRE`, voile `ENCRE` à 55 % sur la carte. Le jeu continue pendant ce temps : affiche « APERÇU · LE JEU CONTINUE ».
- [ ] En-tête : titre « Marché de ce soir », **onglets Contrats 5 · Collaborateurs 5 · Cartes d'action 3**, « [logo] PanZoo choisira avant vous » (premier en influence, sans afficher la valeur, l'influence est cachée), bouton ✕.
- [ ] Contrats : 5 fiches identiques (illustration ; Prix, Attractivité, Nourriture, Motif, Aménagement en lignes alignées ; « ✔ tient dans votre zoo » ou « ✕ manque 3 cases de forêt », à calculer avec les fonctions de motif existantes).
- [ ] Collaborateurs : 5 badges (même brique que la nuit, voir 2.6) et l'alerte « Logement plein (8/8) » quand c'est le cas.
- [ ] Cartes : 3 grandes cartes et un encart « Votre deck » (une case par carte, collaborateurs en sarcelle, actions en jaune ; probabilité de piocher une action demain = actions / taille du deck, arrondie).
- [ ] Pied de fenêtre : « ‹ précédent », « Nuit dans m:ss », « suivant › » (le dernier écran affiche « Retour au jeu »).
- [ ] **Suivre ☆ / ★** (nouveau, côté interface seulement) : `var suivis := {}` dans main.gd. Un élément suivi apparaît dans le flash du bandeau ; s'il est pris par un rival, un toast l'annonce. Ne change aucune règle.

### 2.5 Nuit — structure commune
Toutes les étapes de la nuit (`mt.night_stage` ∈ contrats, ouvriers, cartes, bonus, equipe) partagent la même structure. Refaire `_build_night_ui()` et `_rebuild_night()` :
- [ ] **Colonne « Ordre du jour »** à gauche, 270 px, fond encre (`maquettes/94_ordre_du_jour_nuit.png`, source `Agenda.dc.html`) : logo, « CONSEIL · NUIT n » ; les 5 points (fait = ✔ gris, en cours = jaune) ; « Levée de séance · jour n+1 » ; **tour de parole** dans l'ordre d'influence (a joué ✔ / décision attendue / attend) ; en bas, « Voir mon zoo » et « Classement · Objectifs · Journal ».
- [ ] **Diapositive** blanche à droite (1312 × 864, rayon 14) : sur-titre mono « POINT n / 5 · … », titre en Barlow Condensed 34, et à droite l'argent, l'or, le logement et « Passer › ». Les IA jouent l'une après l'autre : la colonne et les éléments « Pris par … » se mettent à jour en direct.
- [ ] Le bandeau du jour et le dock sont masqués la nuit (c'est déjà le cas via `day_hud`).
- [ ] **Note de direction** (bilan du jour) : bande « COMPTE DE RÉSULTAT » au bas du point 1 (barres recettes / dépenses en aplats, total en mono ▲/▼, réplique d'Hubert, tampon CONFIDENTIEL). Le détail ligne à ligne s'affiche au survol ou via « Journal ».

### 2.6 Nuit — étapes
- **Contrats · `05_nuit_contrats.png`** : un **tableau comparatif** avec une colonne par animal et une ligne par critère (Coût, Attractivité, Nourriture / jour, Motif lettré + « ✔ tient / ✕ pas de forêt », Aménagement, Origine · type, Rareté ◆◇◇), et « Signer · 12 » dans la dernière ligne. La meilleure valeur d'une ligne porte une pastille écrite (« ▼ moins cher », « ▲ meilleur »). Un contrat pris par un rival : colonne grisée avec « [logo] Pris par PanZoo ». Un achat impossible : bouton en pointillé avec la raison (`_short_reason`).
- **Collaborateurs · `06_nuit_collaborateurs.png`** : trombinoscope de 5 grands badges avec cordon (photo 150 px, nom, métier, niveau, catégorie et salaire, **phrase du métier en clair**, traits avec leur effet, « Embaucher · n »). « Nouveau métier » s'affiche si personne ne l'exerce dans l'équipe. Un collaborateur pris : badge gris, tampon « PRIS PAR … ». En plus de la maquette : le bouton « Remplacer une carte · Cabinet 1/1 » quand le Cabinet de recrutement est construit, et l'alerte de logement plein.
- **Cartes · `07_nuit_cartes.png`** : 4 grandes cartes (icône, nom, effet, « ◎ choisir une cible » ou « sans cible », « Acheter · n ») et la bande « Votre deck après achat » avec la probabilité.
- **Bonus**, deux cas :
  - `08a_nuit_bonus_rival.png` : **un rival préside. Le joueur n'a aucune action à faire.** L'écran annonce seulement la décision : bloc « [logo] PANZOO PRÉSIDE » à gauche, et à droite la résolution adoptée en grand, « s'applique demain à toutes les filiales », avec l'effet pour le joueur (« ✔ épargné » ou « ▼ touché »). Les résolutions non retenues sont listées en pointillé. Aucun bouton : l'étape passe seule après 3 s (barre de progression « Point suivant dans 3 s »).
  - `08b_nuit_bonus_vous.png` : vous présidez. 3 lignes de résolution (n°, nom, effet, « Pour vous : … », « Adopter »), puis « Rejeter les trois résolutions ». Le « Pour vous » ne donne que des informations connues du joueur : rien sur l'état caché des rivaux.
- **Équipe · `09_nuit_equipe.png`** : organigramme avec Direction en haut et trois colonnes Cadres, Qualifiés et Peu qualifiés (mini-badges avec le niveau). Une montée de niveau à choisir porte l'étiquette « ▲ NIVEAU n À CHOISIR ». La fiche à droite propose les améliorations (`level_choices`, `choose_level_upgrade`), Former (coût) et Licencier (coût, ou « gratuit avec un DRH »). « Passer au jour n › » en haut.

### 2.7 Menu principal · `10_menu.png`
Restyler `scripts/menu_principal.gd` sans changer ses signaux.
- [ ] Fond : le paysage illustré `assets/bd/menu_fond.jpg`.
- [ ] **Couverture de rapport** : bande blanche de 520 px à x = 60, pleine hauteur. En haut « RAPPORT ANNUEL · EXERCICE <année> » en mono, puis le logo ZooLife, le slogan, et « SOMMAIRE ».
- [ ] Chaque entrée de menu est une ligne de sommaire : numéro en mono, titre en Barlow Condensed 22, points de conduite, note à droite (« Jour 4 · il y a 2 h » pour Continuer). Entrée active en jaune. Tampon CONFIDENTIEL en pied.
- [ ] Panneau « NOUVELLE FILIALE » (440 px, à droite) : adversaires 1 / 2 / 3 avec les logos des rivaux, difficulté, carte (aperçu, graine, « ↻ Autre carte »), puis « SIGNER LA PRISE DE POSTE › ».
- [ ] Les boutons de développement restent réservés à l'éditeur (déjà le cas).

### 2.8 Fin de partie · `11a_fin_victoire.png`, `11b_fin_defaite.png`
Refaire `_rebuild_end()`. La même mise en page sert à la victoire et à la défaite :
- [ ] **Bandeau** « CONCESSION REMPORTÉE » (fond jaune) ou « FILIALE LIQUIDÉE » (fond orange) ; sur-titre « RAPPORT AUX ACTIONNAIRES · CLÔTURE AU SOIR DU JOUR n » ; tampon « APPROUVÉ » (sarcelle) ou « LIQUIDÉ » (rouge `B3361F`).
- [ ] **Podium** (600 px) dans l'ordre 2-1-3-4, marches de 270 / 220 / 180 / 150 px : logo, nom, réputation en mono, rang ; « Voir son zoo » sous chaque joueur, « Revoir sa partie » sous chaque IA (`_voir_replay`, `_replay_disponible`). La marche du joueur est sarcelle en victoire, orange clair en défaite.
- [ ] **Courbes de réputation** jour par jour (`Match.history`) : ligne pointillée à 100 ; chaque joueur a son **motif de trait** (plein, tirets, points, tiret-point) et une étiquette au bout de sa ligne, pas seulement une couleur.
- [ ] 4 **chiffres clés** et une barre empilée « Votre réputation par source », avec sa légende écrite.
- [ ] Réplique d'Hubert (tête contente ou furieuse) et boutons Menu principal, Revoir la carte finale, REJOUER.

## 3. Écrans sans maquette (priorité 2)
Appliquer les mêmes briques. **Toute fenêtre** reprend le modèle du marché : panneau `FOND_FENETRE` centré, en-tête blanc (sur-titre mono, titre en condensé 30, onglets éventuels, ✕), pied blanc avec les actions, voile encre à 55 %.
- Draft (`_rebuild_draft`) : fenêtre, rangée de 4 grands badges (format du trombinoscope), ordre de passage en « tour de parole ».
- Visiteurs (`_open_visiteurs`), pioche et défausse (`_open_pile` : deux colonnes de mini-badges), reportage (`scripts/reportage.gd`), réglages (`reglages.gd`), aide et glossaire (`aide.gd`), salon multijoueur (`salon.gd`).
- Replay : dans le bandeau, marque « REPLAY » en orange et boutons de joueur regardé (déjà présents en mode spectateur).
- Choix d'une cible (`_open_picker`, `_open_action_picker`) : petite fenêtre.

## 4. Ordre de travail conseillé (un commit par jalon)
1. **Nuit** : structure commune (§2.5), puis les 5 étapes (§2.6).
2. **Marché du soir** (§2.4).
3. **Fin de partie** (§2.8), puis **menu** (§2.7).
4. **Pose d'enclos** (§2.3), puis **fiche de sélection** (§2.2), puis les compléments du jour (§2.1).
5. Écrans de priorité 2 (§3).
6. Mettre à jour `ui/galerie_composants.tscn` avec les briques Comité (badge dans ses 8 états, boutons, jetons, infobulle, bulles), comparer à `91_briques.png`, et noter le résultat dans `CLAUDE.md`.

## 5. Contrôle
```
godot --headless --path game --script res://tests/sim_test.gd
godot --headless --path game --script res://tests/replay_test.gd
godot --path game -- --seed=404283 --autodraft --shot=jour.png                                  # 01
godot --path game -- --seed=404283 --autodraft --autoplay --sim=240 --autozoo --un --shot=un.png   # 02
godot --path game -- --seed=404283 --autodraft --autoplay --sim=240 --autozoo --contrat=girafe --shot=enclos.png  # 03
godot --path game -- --seed=404283 --autodraft --autoplay --sim=240 --autozoo --marche --shot=marche.png          # 04
godot --path game -- --seed=404283 --autodraft --autoplay --sim=240 --autozoo --endday --shot=nuit.png            # 05
godot --path game -- --seed=404283 --autodraft --outil=construire --shot=construire.png
godot --path game -- --demo-fin --shot=fin.png ; godot --path game -- --defaite --shot=defaite.png
godot --path game -- --tutoriel --tuto-auto --tuto-dossier=C:/chemin   # le tutoriel doit aller au bout
```
Critères d'acceptation, pour chaque écran :
- la capture se superpose à la maquette à quelques pixels près pour les gabarits (positions, largeurs, hauteurs) ;
- aucun texte coupé ni chevauchant à 1600 × 900, ni à 1280 × 720 (`--resolution 1280x720`) ;
- aucune information portée par la couleur seule ;
- `sim_test` et `replay_test` passent, et le tutoriel automatique va au bout.

## 6. Pièges connus
- `tutoriel.gd` vise des nœuds de main.gd : `res_chips[x]["racine"]`, `race_labels[i][0]`, `build_tabs`, `hand_box`, `deploy_all_btn`, `end_day_btn`, `contracts_box`, `trade_card`. Garde ces noms ou mets à jour le tutoriel.
- `res_chips["reputation"]` pointe désormais sur le segment du joueur dans le bandeau. `race_labels[i]` = [segment, valeur, delta].
- `day_hud` est rendu visible à chaque image : un volet qui doit rester fermé passe par `_appliquer_outils()`, pas par `day_hud`.
- `_update_unit_panel()` ne déplace plus la pioche ni la main : ne remets pas ces décalages.
- Les badges dépassent du dock. `hand_scroll` doit donc rester au-dessus du dock dans l'ordre des enfants de `ui`, avec une hauteur de `Composants.BADGE.y`.
- En `--headless`, une erreur de script bloque le processus : lance toujours avec `timeout`.
