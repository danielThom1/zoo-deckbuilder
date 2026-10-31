# Zoo Deckbuilder — notes pour Claude Code

Jeu de gestion vu du dessus : deckbuilding d'ouvriers + construction d'un zoo. Prototype **Godot 4.7.2** dans `game/` (ouvrir `game/project.godot`). Tout le texte du jeu est en **français**. Écran de référence 1600×900.

## Où en est le projet (30/10/2026)
- Règles, IA et simulations d'équilibrage : faits (`GDD.md`, `game/scripts/match.gd`, `game_state.gd`, `ai_controller.gd`, rapports `rapport_equilibrage*.md`).
- **Direction artistique « Émeraude » — étape 1 faite** (commit `490dfe0`) : `game/scripts/ui_tokens.gd` (jetons + `build_theme()`), panneaux émeraude à filet doré, boutons dorés, qualités cercle bleu / défauts carré orange, couleurs du monde, écussons d'ouvriers, placement invalide hachuré, menu restylé.
- **Étape 2 faite (jalons 1–2 du HANDOFF)** :
  - 76 icônes dans `game/ui/icones/` (import `svg/scale=2.0` + mipmaps) → `UiTokens.icone("ressource_bois")`, à teinter par `modulate`.
  - Polices dans `game/ui/fonts/` : `MarcellusSC-Regular.ttf` (titres) et `SourceSans3-VF.ttf` (variable, graisses via `UiTokens.police_corps(400|600|700|800)`).
  - Thème : variations `TitreEcran`, `TitrePanneau`, `NomCarte`, `Compteur`, `TexteSecondaire`, `PanneauEmeraude`, `EnteteEmeraude`, `BoutonPrincipal`, `BoutonSecondaire`, `BoutonOrdre` (boutons en pilule).
  - Couleurs catégories / ressources / biomes / tuiles alignées sur `tokens.json` (les couleurs du **monde** `TERRAINS` gardent les valeurs de l'étape 1).
  - Galerie `game/ui/galerie_composants.tscn` : reproduit `captures/07` (carte ouvrier et ses 6 états, contrat, jetons, ordres, tuiles de motif). Les composants y sont des fonctions (`carte_ouvrier()`, `carte_contrat()`…) à extraire en scènes réutilisables.
  - Corrigé : `build_theme()` appelait `Theme.add_type_variation` (inexistant en Godot 4 → `set_type_variation`) ; le thème n'était donc jamais appliqué avant.
- **Draft par tours** (remplace le draft serpent) : 10 tours de 4 cartes révélées, une chacun à tour de rôle, la dernière revient d'office au dernier joueur (à 4), le premier à choisir tourne (`match.gd`, `cartes_par_tour` dans `workers.json`, GDD §3.1).
- Le thème est appliqué au HUD en jeu (`_build_ui`), pas seulement au menu.
- **Lot A (rythme) fait** : ouvriers −30 % (`regles.vitesse_ouvriers`), chantiers ~×2, visiteurs par groupes avec courbe journalière, capacité 1 visiteur / 3 cases, visite 3 min ± 1,5, réputation 0,3 × visiteurs moyens (voir GDD §7.3). IA : pourtour du petit parc évolutif vérifié, réserve d'argent levée pour le premier enclos.
- Nourriture payée seulement une fois le zoo ouvert (`GameState.food_due()`), contre le piège de pauvreté avant l'ouverture.
- **Lot B (cohérence) fait** : XP en jours (`Card.xp`, `gain_xp`, Apprenti ×2, Bon élève ×1,5), Centre de formation (poste « formation », ×2 avec Formateur), amélioration gratuite au choix à chaque niveau (`level_choices`, `choose_level_upgrade`, Têtu : 2), améliorations de métier (`effet.capacite`, `has_capacity`), seconde spécialité, Architecte et Débrouillard (`Site.savings`, remboursement en fin de chantier), Matinal, Casanier, Peureux. Voir GDD §6.4.
- **Lot C (vie du zoo), première partie faite** : réserve de rations par animal (`Animal.food`, `_animals_eat`), tâche `feed` depuis la Cuisine (`_update_feed`), propreté du parc (`proprete`, tâche `clean`, `_sweep`, `cleanliness_mult`), Snack (`snack_mult`), Kiosque (`kiosque_bonus`), métiers Animalier, Agent d'entretien et Animateur. L'IA gère la cuisine, les nourrisseurs et l'entretien (`_park_spot`, `_ensure_job`). Sans aménageur, elle n'achète que des contrats au motif déjà présent (`_natural_fit`). Voir GDD §7.4.
- **Robustesse de l'IA (31/10)** : `balance_sim --detail` écrit une ligne `ETAT|…` par IA (réputation, argent, murs, raison de fermeture, contrats avec ou sans plan). Corrigé : guichet et boutique tenus seulement zoo ouvert (le dernier ouvrier restait au guichet d'un zoo fermé) ; ouvrier gratuit choisi parmi les manuels ; en équipe réduite, les chantiers passent avant les soins ; contrats sans plan exclus de la limite de contrats. Résultat sur 32 parties : 17 IA sur 128 à 0 (40 avant), 31 parties sur 32 atteignent 60, fin vers les jours 12-13. Restent faibles : Petit parc (0 %), Parc évolutif (6 %), Lobbying (6 %).
- **31/10, suite** : bonus de nuit choisi par le seul premier en influence et appliqué à tous (`Match.bonus_choice`, `influence_leader`). Marché du soir consultable en journée (bouton, `_rebuild_market_preview`, argument `--marche`). T3 : aménagements en deux étapes pour l'IA (`_conversion_steps`, `_conversion_step`), « Dérocher », T3 au jour 7, l'IA garde son or et privilégie la réputation quand l'argent abonde. Lot D en partie : évolution des cartes (`evolutions`, option `evolution`), cartes d'action (`Card.action`, `play_action`, `buy_action`, `Match.market_actions`, `action_fx`, `prime_left`). `all_employees()` exclut les cartes d'action.
- **v6** : animaux avec `continent` et `type` (38 espèces), affinités (`affinity_bonus`, +5 % par espèce supplémentaire d'un même continent), bonus de nuit par type ou continent (`attractivite_type`, `attractivite_continent`), or manquant des contrats acheté en argent (`contract_payment`), améliorations du camp `camp_n2` et `camp_n3` (`hand_size()`, `sur: camp`), stratégies IA « Camp amélioré » et « Grand camp » (`strat.camp`).
- **Lot E (graphismes) fait** :
  - `game/ui/composants/composants.gd` (`class_name Composants`) : `carte_ouvrier()` (main, draft, marché ; états normale, non abordable, déployée, hors carte), `carte_action()`, `jeton_ressource()`, pastilles, icônes de métiers, traits et bâtiments.
  - HUD de jour (`_build_ui`) : jetons de ressources et course en haut, panneau Construire en onglets (Bâtiments, Zoo, Terrain), panneau du zoo à droite, pioche, main en cartes Émeraude, médaillon du jour (`_draw_medallion`), bouton « Terminer la journée ».
  - Draft, marché du soir et nuit utilisent les mêmes cartes ; les contrats ont un bandeau de biome (`_contract_widget`).
  - Monde : terrain calculé par le shader `game/ui/terrain.gdshader` (deux textures 64×64 : type de case, et distance au rivage pour l'eau), avec bords organiques, arbres et rochers en relief, pics enneigés, eau animée. `_fill_terrain_images()` / `_refresh_terrain(force)` les mettent à jour après un aménagement.
  - Bâtiments à toit et marqueur d'icône (`_draw_building`, `_draw_pin`), enceinte blanche et palissade (`_draw_fence`), entrée, ponts, chemins arrondis, camp en tentes (une de plus par agrandissement), animaux qui déambulent, visiteurs colorés, écussons d'ouvriers avec l'icône du métier.
  - Panneau de l'ouvrier sélectionné en bas à gauche (`_build_unit_panel`, `_update_unit_panel`) : portrait, niveau en étoiles, traits, tâche et progression, ordres rapides vers la ressource la plus proche (`_nearest_resource`), lobbying, retour au camp. Il décale la pioche et la main.
  - Nuit (capture 05, `_build_night_ui`, `_rebuild_night`) : en-tête à étapes (Revenus › Niveaux › Bonus › Marché › Améliorer/licencier › Jour N), colonne gauche bilan (salaires et rations comptés dans `day_stats`), montées de niveau, améliorer ↑ / licencier ✕ ; centre ordre d'influence, ouvriers, contrats (204 px), cartes d'action ; droite classement de réputation, bonus de nuit, journal. Le HUD de jour (`day_hud`) est masqué la nuit.
  - Fin de partie (capture 06, `_rebuild_end`) : bandeau, podium, chiffres clés, courbes de réputation (`Match.history`, marqueur de forme par joueur), biomes ouverts, boutons Rejouer / Revoir la carte / Menu (`_restart`, `static var relance`).
- **Équilibrage repoussé** à la fin des fonctionnalités (demande du 31/10) : ne lancer que `sim_test` et des captures d'ici là.
- Pièges Godot rencontrés : `TextureRect` → régler `expand_mode` **avant** `texture`/`size` (sinon taille native 96 px) ; `FontVariation.variation_opentype` attend la clé `name_to_tag("wght")`, pas la chaîne `"wght"`.

## Référence visuelle
`docs/handoff_emeraude/` :
- `HANDOFF.md` — spécification complète (principes, cotes de chaque écran, composants, jalons §12).
- `captures/` — les 8 maquettes de référence (menu, draft, jour, construction, nuit, fin, cartes, système).
- `tokens.json` — valeurs exactes ; `icones/` — 76 SVG au trait blanc à teinter.
- `godot/` — points de départ non testés. ⚠️ `docs/handoff_emeraude/godot/ui_tokens.gd` déclare aussi `class_name UiTokens` : ne pas le copier dans `game/`, la version du jeu est `game/scripts/ui_tokens.gd`. Il est hors du projet Godot (`game/`), donc sans conflit tant qu'il reste dans `docs/`.

Note : le jeu est en 2D vu du dessus (`main.gd` dessine la carte, `game/ui/terrain.gdshader` le terrain) ; les parties « monde 3D » du HANDOFF (§7) visent la version finale et ne s'appliquent pas telles quelles.

## Feuille de route
`docs/propositions_ameliorations.md` (30/10/2026) : récapitulatif des métiers (avec ce qui est réellement codé), écart avec les maquettes, propositions chiffrées (rythme, visiteurs, entretien des animaux, formation, fin de partie, deckbuilding) et ordre des lots A à E. À valider avec l'utilisateur avant de coder un lot.

## Prochaines étapes suggérées
1. Fonctionnalités restantes des lots C et D (usure, Vétérinaire, grands projets, cadres jouables, fatigue, carte gardée, synergies).
2. Équilibrage complet avec `balance_sim` une fois tout en place.
3. Garder le double codage couleur + forme partout ; vérifier avec la check-list §9 du HANDOFF.

## Commandes
Godot n'est pas dans le PATH : l'exécutable est `C:\Users\danie\zoodeck\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` (noté `godot` ci-dessous).
```
godot --headless --path game --script res://tests/sim_test.gd                        # ~40 s
godot --headless --path game --script res://tests/balance_sim.gd -- --parties=32 --dt=1.0   # ~7 min (4 processus en parallèle, --jobs=N pour changer)
godot --headless --path game --import                               # après ajout d'assets
godot --path game res://ui/galerie_composants.tscn -- --capture     # capture_galerie.png (rendu réel, pas --headless)
godot --path game -- --joueurs=4 --seed=7 --autodraft --shot=C:/chemin/capture.png          # capture du jour 1 (ajouter --marche, --zoom=3, ou --autoplay --un --sim=30 pour le panneau d'ouvrier, --autoplay --sim=60 --endday pour la nuit)
godot --path game -- --spectateur --seed=7 --jours=8 --zoom=2.4 --shot=C:/chemin/zoo.png     # zoo d'une IA au jour 8 (--jours=30 : écran de fin)
```
Lancer les tests après chaque modification de `game_state.gd`, `match.gd` ou `ai_controller.gd`.

Performance (mesures du 30/10/2026) :
- Générer une carte coûte ~0,5 s : `Match` la génère une fois et la copie pour chaque joueur (`GameMap.copy()`). Dans les tests, ne pas créer une partie juste pour tirer des cartes.
- À `--dt=1.0`, l'IA domine (elle réfléchit toutes les 2 s de jeu). `_wants()` est rappelé à chaque réflexion et pour chaque ouvrier inactif : les recherches coûteuses passent par `AIController._cached()` (invalidé par `g.version` et le plan du zoo).
- Piste connue : l'IA retente chaque réflexion des chantiers impossibles (~99 % des `g.place()` échouent).
