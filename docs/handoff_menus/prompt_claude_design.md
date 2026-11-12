# Prompt pour Claude Design : menu principal, statistiques, défis et classements

À joindre au prompt :
- les captures de l'état actuel : `docs/handoff_menus/etat_actuel/menu.png`, `statistiques.png`, `defis.png` ;
- la feuille de style et les briques de l'interface en vigueur : `docs/handoff_comite/maquettes/90_feuille_de_style.png`, `91_briques.png`, et la maquette du menu déjà faite `10_menu.png` ;
- pour l'ambiance du rapport aux actionnaires : `docs/handoff_comite/maquettes/11a_fin_victoire.png`.

---

## Le prompt

Tu as déjà conçu l'interface « Le Comité » de **ZooLife**, un jeu de gestion de zoo vu du dessus (deckbuilding de collaborateurs + construction), en français, sur un écran de référence 1600 × 900, joué à la souris. Je te joins ta feuille de style, tes briques, ta maquette de menu et des captures de ce que le jeu affiche aujourd'hui. J'aimerais que tu retravailles **trois écrans** dans ce même style : le **menu principal** (surtout l'organisation des modes de jeu), la page **Statistiques**, et la page **Défis** avec ses **classements en ligne**.

### Le ton et le style à garder
- Satire d'entreprise : le joueur est un cadre de ZooLife™, multinationale du divertissement animalier. Le menu est un « rapport annuel », la nuit un conseil d'administration, la fin un rapport aux actionnaires. Hubert de la Marge, son supérieur, commente en bulles de BD.
- Carte du monde illustrée en style BD ligne claire en fond du menu (vivante, avec visiteurs et animaux).
- Jetons : encre `#14202B`, papier `#FFFFFF`, fond de fenêtre `#F7F8F9`, mémo `#F3F1EA`, sarcelle `#13867F` (en-têtes), en-tête clair `#BFE6DF`, accent sélection jaune `#FFC93C`, orange d'action forte `#F07F2A`, positif `#1F7A4A`, négatif `#B5452A`, filets `#D5D9DE`, texte secondaire `#4A5664`. Couleurs des joueurs : `#13867F`, `#F0A020`, `#3A6AE0`, `#E04A8A`.
- Polices : Barlow / Barlow Condensed (titres en capitales condensées), IBM Plex Mono pour les chiffres, sur-titres et mentions « administratives », Bangers seulement pour les noms sur la carte.
- Double codage couleur + forme partout (pas d'information portée par la couleur seule). Coche « ✓ », pas « ✔ ».
- Les écrans sont refaits en code dans Godot (Control, conteneurs, StyleBoxFlat, textures) : évite ce qui ne s'y traduit pas (flou d'arrière-plan, typographie variable sur un même mot, dégradés complexes sur du texte). Donne les cotes.

### 1. Menu principal : réorganiser les modes de jeu

**Aujourd'hui** (capture `menu.png`) : une colonne « Sommaire » de 10 lignes au même niveau : Jouer contre l'IA, Réserve naturelle, Gestion libre, Défis, Multijoueur, Tutoriel, Règles et glossaire, Statistiques, Réglages, Quitter (plus « Continuer » quand une sauvegarde existe). À droite, une carte « Nouvelle filiale » (adversaires 1 à 3, difficulté Facile / Moyen / Difficile, graine de carte avec aperçu et « Autre carte », bouton « Signer la prise de poste »). Problèmes :
- les modes de jeu sont mélangés avec les utilitaires (règles, réglages, quitter) ;
- la carte « Nouvelle filiale » ne s'applique visiblement qu'à « Jouer contre l'IA », alors que la Réserve naturelle utilise aussi les adversaires, la difficulté et la carte ; la Gestion libre n'utilise ni adversaires ni difficulté ;
- les Défis, le Multijoueur et le Tutoriel ouvrent chacun autre chose (fenêtre, salon, partie guidée), sans que le menu le laisse deviner ;
- rien ne met en avant le défi de la semaine ni la reprise d'une partie.

**Ce que contient le jeu** (à organiser comme tu le juges le mieux) :
- **Continuer** (s'il y a une sauvegarde) : « Jour 6 · 4 joueurs ».
- **Partie classique** (« course ») : vous + 1 à 3 IA, premier à 120 de réputation, ~14 jours, terrain aménageable (creuser des bassins, planter, dérocher).
- **Réserve naturelle** : mêmes réglages, mais pas d'aménagement de terrain : il faut trouver sur la carte les endroits où le motif de chaque animal existe déjà.
- **Gestion libre** : seul, sans fin ni objectif, 90 d'argent, pas de maladie ; naissances d'animaux et livre d'or des visiteurs.
- **Défis** : la même partie pour tous, seul contre les 3 meilleures IA, 10 jours, score = réputation au soir du jour 10 ; 4 défis fixes + 1 défi de la semaine, classement en ligne (voir §3).
- **Multijoueur** : 2 à 4 humains (un héberge, les autres rejoignent par adresse IP), IA en complément.
- **Tutoriel** : partie guidée par Hubert.
- Utilitaires : Règles et glossaire, Statistiques, Réglages, Quitter.
- Réglages d'une nouvelle partie : nombre d'adversaires (1 à 3, noms et logos des groupes rivaux : PanZoo, Safari Capital, BioLand), difficulté (Facile, Moyen, Difficile), carte (numéro de graine, aperçu en vignette, « Autre carte », proportions forêt / eau / roche).
- Le pseudo du joueur (saisi au premier lancement) et, pourquoi pas, un petit rappel de ses statistiques.
- En haut, une rangée de boutons de développement (« Essai : vue isométrique », « Dév. : … ») : ils n'existent que dans l'éditeur, ignore-les ou réserve-leur un coin discret.

**Ce que je te demande** : une organisation claire des modes (par exemple des familles « Jouer », « Défis », « Apprendre », « Outils », ou des cartes de mode avec un panneau de réglages qui s'adapte au mode choisi : à toi de proposer), le défi de la semaine mis en avant, Continuer bien visible quand il existe, et une liaison évidente entre le mode choisi et ses réglages. Garde l'esprit « rapport annuel » (sommaire, mention CONFIDENTIEL, citation d'Hubert en bas) et la carte vivante en fond. Propose **2 variantes** d'organisation, puis développe celle que tu recommandes.

États à montrer : sans sauvegarde ; avec sauvegarde ; mode Gestion libre choisi (réglages réduits) ; mode Réserve naturelle choisi.

### 2. Statistiques (« Dossier personnel »)

**Aujourd'hui** (capture `statistiques.png`) : une fenêtre défilante qui empile des tableaux : pseudo modifiable et nombre de parties ; tableau par mode ; tableau des défis ; courbe des dernières parties ; tableau des dernières parties ; barres « D'où vient votre réputation » ; collection ; succès. C'est lisible mais plat, sans hiérarchie, et le bas de la page n'est jamais vu.

**Données disponibles** :
- Profil : pseudo (3 à 16 caractères, modifiable), nombre total de parties, date de la première partie.
- **Par mode** (classique, Réserve naturelle, Gestion libre, Défis, Multijoueur) : parties, victoires et taux, victoire la plus rapide (jour), réputation record, réputation moyenne, jour moyen d'ouverture du zoo comparé à celui des IA (« jour 6,0 — IA : 6,3 »).
- **Défis** : pour chacun des 5, parties jouées, meilleur score, date ; rang en ligne si disponible.
- **Dernières parties** (jusqu'à 200 gardées, 20 montrées) : date, mode, rang final (1er / 4), jour de fin, réputation finale, nombre d'animaux ; une courbe de la réputation finale partie après partie.
- **Sources de réputation** cumulées, en pourcentage : fréquentation, spectacles, boutique, prestige politique, labels, objectifs, beauté du parc, collaborateurs légendaires.
- **Collection** : espèces installées au moins une fois (40 espèces, 4 continents, 3 raretés : commun, peu commun, rare ; une image par espèce) et collaborateurs recrutés (40 personnages, un portrait chacun).
- **12 succès** : Première concession (gagner une partie), Garde forestier (gagner en Réserve naturelle), Promotion éclair (gagner avant le jour 10), Portes ouvertes (ouvrir son zoo au jour 3 ou avant), Le terrain tel qu'il est (gagner une course sans Terrassier ni Paysagiste), Spécialiste (4 espèces du même continent), Tour du monde (4 continents dans un zoo), Heureux événement (2 petits chez un même animal), Actionnaire satisfait (100 dans un défi), Collectionneur (10 espèces), Arche de ZooLife (toutes les espèces), Légende vivante (un collaborateur au niveau 6).

**Ce que je te demande** : une page qui se lise comme un dossier d'employé ou une évaluation annuelle (fiche signalétique, chiffres clés en grand, graphiques, médailles), avec une hiérarchie : d'abord les chiffres qui comptent, puis le détail. Onglets ou sections : à toi de voir (par exemple « Résumé », « Parties », « Collection », « Succès »). Collection en grille d'images avec les espèces non découvertes en silhouette ; succès en badges, obtenus ou non. États : premier lancement (aucune partie : page encourageante, pas un tableau de tirets) ; joueur régulier (une cinquantaine de parties).

### 3. Défis et classements en ligne

**Aujourd'hui** (capture `defis.png`) : une fenêtre avec une phrase d'explication, 5 lignes (nom, mode, numéro de carte, meilleur score ou « Pas encore joué », rang en ligne, bouton « Top 10 » qui déplie une liste, bouton « Jouer »), le défi de la semaine en jaune. En bas, le vainqueur de la semaine passée et « Revoir sa partie ».

**Règles du classement, à respecter dans la maquette** :
- Chaque défi a son classement. Le joueur voit **toujours son rang** (« 14e sur 52 ») et son meilleur score.
- Le **top 10** est toujours visible en scores, mais **les pseudos n'y sont visibles que si le joueur est lui-même dans le top 10** ; sinon les lignes montrent « joueur masqué ». La ligne du joueur est toujours repérable (« vous »).
- Les replays des joueurs sont privés. Seul le **vainqueur du défi de la semaine précédente** peut être revu par tous (« Revoir sa partie »).
- Le défi de la semaine change chaque lundi et finit dimanche soir ; son mode alterne (classique / Réserve naturelle).
- Le classement peut être indisponible (pas de réseau) : seul le meilleur score local est alors montré, avec une mention discrète.
- Chargement : les rangs arrivent une à deux secondes après l'ouverture.
- À la fin d'un défi, le score part tout seul ; le rapport de fin affiche « Classement en ligne : 3e sur 12 » (pas à refaire ici, mais garde la cohérence).

**Données d'un défi** : nom (« La vallée des Saules », « Le plateau des Roches », « Le delta sauvage », « Monts et marais », « Défi de la semaine du 9/11 »), mode, numéro de carte (on peut montrer un aperçu de la carte en vignette), nombre de jours (10), meilleur score personnel et nombre de parties, rang, total de participants, top 10 (rang, pseudo ou masqué, score).

**Ce que je te demande** : une page Défis qui donne envie de jouer et de revenir : le défi de la semaine en tête (compte à rebours jusqu'à dimanche soir, vainqueur de la semaine passée et son replay), les 4 défis fixes en cartes avec vignette de la carte, et un **classement** lisible (tableau de cotation façon bourse, podium, ou autre : à toi de voir), qui peut s'ouvrir à côté du défi choisi plutôt qu'en dépliant une liste. États : défi jamais joué ; joueur hors du top 10 (pseudos masqués, sa position montrée sous le top 10) ; joueur dans le top 10 (pseudos visibles) ; classement indisponible ; chargement.

### Livrables
- Une maquette PNG 1600 × 900 par écran et par état demandé, et le source HTML de chacune avec les cotes (comme pour le paquet « Le Comité »).
- Une note courte par écran : ce qui change par rapport à l'état actuel, et les composants nouveaux à ajouter aux briques.
- Vérifie que tout tient aussi en 1280 × 720 (le jeu s'étire en `canvas_items`, aspect `expand`).
