# Menu principal, Statistiques, Défis : notes de conception

Direction « Le Comité », référence 1600 × 900. Les PNG sont dans `maquettes/`, leur version 1280 × 720 dans `maquettes/1280/`. Les sources HTML sont dans `sources/`, et chaque cote y figure en px. Jetons, polices, contours (2 / 2,5 px), rayons (6 / 10) et ombres pleines (0, 4) sont ceux de la feuille de style 90. Aucun flou : le voile derrière les fenêtres est un aplat `#14202B` à 55 %.

| Fichier | Écran et état |
|---|---|
| 10A_menu_chapitres | Menu, variante A (recommandée) : sans sauvegarde, Partie classique choisie |
| 10A2_menu_sauvegarde | Variante A : avec sauvegarde, « Dossier en cours » choisi |
| 10A3_menu_gestion_libre | Variante A : Gestion libre choisie (réglages réduits) |
| 10A4_menu_reserve | Variante A : Réserve naturelle choisie |
| 10B_menu_chemises | Menu, variante B (non retenue), pour comparaison |
| 20_stats_premier_lancement | Statistiques : aucune partie |
| 21 à 24_stats_* | Statistiques, joueur régulier (52 parties) : Résumé, Parties, Collection, Succès |
| 30_defis_hors_top10 | Défis : défi de la semaine choisi, joueur 14e sur 52 (**correction du 12/11 : pseudos du top 10 visibles**) |
| 31_defis_dans_top10 | Défis : Le delta sauvage choisi, joueur 3e sur 41 |
| 32_defis_jamais_joue | Défis : La vallée des Saules choisi, jamais joué |
| 33_defis_indisponible | Défis : hors ligne |
| 34_defis_chargement | Défis : rangs en cours de chargement |

Vérification 1280 × 720 : le jeu s'étire en `canvas_items` + `expand`, donc tout est mis à l'échelle 0,8 et rien ne déborde. Le plus petit corps de texte vaut 11 px (8,8 px affichés), ce qui respecte le minimum de la feuille de style. Seuls les exposants (« 14e ») sont plus petits.

---

## 1. Menu principal

### Les deux variantes

**A. Sommaire en chapitres, avec une fiche de mode agrafée (recommandée).** On garde la couverture du rapport annuel, mais le sommaire est découpé en trois chapitres numérotés en chiffres romains :

- I JOUER : Partie classique, Réserve naturelle, Gestion libre, Multijoueur ;
- II DÉFIS : Défi de la semaine, Défis permanents ;
- III APPRENDRE : Tutoriel, Règles et glossaire.

Les utilitaires (Statistiques, Réglages, Quitter) quittent le sommaire et descendent dans le pied de page, à côté de la fiche du joueur. La ligne choisie est jaune. Ce jaune file jusqu'au bord de la couverture, puis une **languette** rejoint la **fiche de mode**, posée à côté de la couverture : on voit tout de suite quels réglages vont avec quel mode. Le défi de la semaine a sa propre ligne, avec un badge de date, et une **note de service** épinglée sur la carte (compte à rebours, rang, vainqueur de la semaine passée). Quand une sauvegarde existe, un bloc « Dossier en cours » apparaît au-dessus du sommaire : il est sélectionné par défaut et sa fiche affiche l'état de la partie.

**B. Chemises de mode.** Six grandes cartes en forme de chemise cartonnée, posées sur la carte : Défi de la semaine, Défis permanents, Multijoueur, Partie classique, Réserve naturelle, Gestion libre. En dessous, un bandeau de réglages sur toute la largeur. La couverture se réduit au logo, à « Continuer » et aux annexes.

**Pourquoi A.**

- A garde le concept du rapport annuel (sommaire, pointillés, numéros), qui est la signature du menu, et laisse la moitié droite de la carte vivante visible. B la recouvre presque entièrement.
- La languette rend le lien entre le mode et ses réglages plus évident que dans B, où les réglages sont loin de certaines cartes.
- A demande moins de travail : le menu actuel est déjà une couverture et une fiche, il suffit de réorganiser la liste et de rapprocher la fiche.
- B présente mieux chaque mode (illustration, phrase de description). On peut en reprendre l'idée dans A en ajoutant une illustration au bandeau de la fiche.

### Ce qui change par rapport à l'état actuel

- Les 10 lignes au même niveau deviennent 3 chapitres de 8 lignes. Statistiques, Réglages et Quitter descendent dans le pied, avec la fiche du joueur (pseudo, parties, victoires, record).
- « Jouer contre l'IA » s'appelle maintenant **Partie classique**, pour la distinguer de la Réserve naturelle et des Défis, qui se jouent aussi contre des IA.
- La carte « Nouvelle filiale » devient une **fiche de mode** dont le contenu dépend de la ligne choisie :
  - **Partie classique** : règles en une phrase, pastilles (▲ Terrain aménageable, Objectif 120), adversaires, difficulté, carte, « Signer la prise de poste ».
  - **Réserve naturelle** : bandeau vert. La règle est illustrée par le motif de l'aigle royal (une grille 4 × 4 de `ColorRect`). Pastille ● Terrain tel quel. Mêmes réglages que la partie classique, avec un conseil sous la carte.
  - **Gestion libre** : bandeau marine. Pastilles Seul, 90 d'argent, Pas de maladie, Naissances. Adversaires et difficulté sont remplacés par une ligne en pointillé « Sans objet » (le pointillé signifie « indisponible » dans la feuille de style). Il ne reste que la carte. Le bouton devient « Ouvrir le parc ».
  - **Dossier en cours** (sauvegarde) : bandeau encre, vignette de la carte, jour et mini-classement de la réputation (logo, nom, forme, barre, chiffre), « Reprendre le dossier ».
  - **Multijoueur** (non dessiné) : deux blocs, « Héberger » (nombre de places 2 à 4, IA en complément, carte) et « Rejoindre » (champ adresse IP, bouton « Rejoindre »).
  - **Défi de la semaine** et **Défis permanents** (non dessinés) : la fiche montre le défi (vignette, mode, compte à rebours, rang) et un bouton « Ouvrir les défis », qui ouvre la page Défis (§ 3).
  - **Tutoriel** : Hubert, une phrase, la durée (~15 min), « Commencer ».
  - **Règles et glossaire** : la ligne ouvre directement la fenêtre, sans fiche.
- Quand une sauvegarde existe et qu'un autre mode est choisi, la fiche ajoute une ligne rouge avec un triangle : « Une nouvelle partie remplacera le dossier en cours (jour 6) ».
- Les boutons de développement se replient dans un bouton « DÉV. ▾ » en pointillé, en haut à droite, visible seulement dans l'éditeur.

### Cotes principales (variante A)

| Élément | Cotes |
|---|---|
| Couverture | x 60, l 520, h 900, marges internes 26 / 36. Logo l 236. Contour gauche et droit 2,5. Ombre pleine 10 px à 35 % |
| Chapitre | h 26, Barlow Condensed 800 12, interlettrage 0,1 em. Numéro romain en Plex Mono 11. Filet `#D5D9DE` |
| Ligne du sommaire | h 38, rayon 8, numéro Plex Mono 13, nom Barlow Condensed 800 21 en capitales, note Barlow 600 13 |
| Ligne choisie | fond `#FFC93C`, contour 2 encre. Elle s'étend jusqu'à x 582 (marge droite −38,5, bord droit ouvert), puis la languette va de x 582 à 612, h 38 + 2 × 2, avec des contours haut et bas, au-dessus de la fiche |
| Fiche de mode | x 604, l 452. Haut à y 238, ou 300 avec une sauvegarde. Bandeau h 40. Bloc de règles sur fond mémo, avec 2,5 de contour sous lui. Segments h 38. Vignette 104 × 104. Bouton principal h 52 |
| Bloc « Dossier en cours » | h 66, rayon 8, sur fond mémo, ou jaune s'il est choisi |
| Note de service | x 1120, y 548, l 420, rotation −1,5°, fond mémo, punaise Ø 20 `#B5452A` |
| Pied | fiche du joueur (blason 34) et « Statistiques › » ; Réglages et Quitter en deux boutons mini, demi-largeur ; citation d'Hubert ; tampon CONFIDENTIEL |

**Godot.** La languette est un `Panel` jaune positionné à l'ordonnée de la ligne choisie, que l'on recalcule à chaque changement de sélection. La ligne choisie et la languette se dessinent au-dessus du contour gauche de la fiche (`z_index`).

### Nouvelles briques

- Chapitre de sommaire.
- Ligne de sommaire avec badge (« 9/11 »).
- Languette de liaison.
- Fiche de mode : bandeau coloré par mode (sarcelle pour la partie classique, vert `#1F7A4A` pour la réserve, marine pour la gestion libre, encre pour le dossier en cours) et bloc de règles à pastilles.
- Pastille de mode, couleur plus forme : ▲ orange pour Aménagements, ● vert pour Réserve naturelle. Réutilisée dans les Défis et les Statistiques.
- Note de service épinglée.
- Ligne « indisponible » en pointillé.
- Bouton « DÉV. ».

---

## 2. Statistiques (« Dossier personnel »)

### Organisation

Une fenêtre centrée de 1280 × 700, avec 4 onglets en intercalaires de dossier. Chaque onglet indique son total : Résumé, Parties 52, Collection 27/40, Succès 9/12. L'onglet actif est sur fond papier, avec un filet jaune de 4 px en haut. Rien ne défile, sauf la liste des dernières parties.

- **Résumé** : ce qui compte, en un coup d'œil.
  - **Fiche signalétique** : photo d'identité (le blason ZooLife), pseudo modifiable, matricule, date d'entrée en poste (première partie), nombre de parties, grade, et un tampon d'évaluation.
  - **4 chiffres clés en grand** (Plex Mono 38) : victoires et taux, réputation record (avec le mode et la date), victoire la plus rapide, jour moyen d'ouverture du zoo comparé à celui des IA (▲ vert quand vous ouvrez plus tôt).
  - **Par mode** : tableau compact (forme du mode, parties, barre de taux de victoire, record).
  - **Courbe des 20 dernières parties** : ● plein pour une victoire, ○ creux pour une défaite, objectif 120 en tirets.
  - **D'où vient votre réputation** : une barre empilée, avec le pourcentage écrit dans chaque segment d'au moins 8 %, et une légende avec carré de couleur et pourcentage. La couleur n'est donc jamais seule.
  - **Collection et succès** : trois barres de progression et le dernier succès obtenu.
  - Une bulle d'Hubert.
- **Parties** :
  - le tableau complet par mode (8 colonnes, avec l'ouverture du zoo « jour 5,4 · IA 6,1 ») ;
  - la courbe en grand ;
  - les dernières parties : 8 visibles sur 20, avec une barre de défilement. La partie la plus récente est sur fond jaune clair, et le rang 1er est en vert gras.
- **Collection** :
  - 40 espèces en 4 colonnes (une par continent, avec le compte « 8/10 »), en tuiles de 50 px ;
  - la rareté est marquée par une forme au coin de chaque tuile : ● gris commun, ◆ bleu peu commun, ★ jaune rare ;
  - une espèce pas encore installée apparaît en silhouette dans une tuile en pointillé. On utilise le sprite du corps de l'animal (`animaux_v2/<id>.png`), avec un `modulate` noir à 22 %, parce que les têtes ont un fond carré ;
  - l'infobulle donne le nom, la rareté, le nombre d'installations et la dernière date ;
  - les 40 collaborateurs sont en portraits de 52 × 66, sur 2 rangées de 20, avec le même principe de silhouette.
- **Succès** : 12 cartes en grille 4 × 3.
  - Obtenu : médaille jaune à ruban sarcelle, carte pleine avec ombre, et « ✓ obtenu le … ».
  - Non obtenu : carte et médaille en pointillé gris, condition écrite, et barre de progression quand le succès se compte (Arche 27/40, Légende vivante niv. 5/6).
  - Hubert indique le succès le plus proche.
- **Premier lancement** :
  - grade Stagiaire, tampon « Période d'essai » ;
  - au lieu de tableaux de tirets, 3 **missions** : Tutoriel (bouton principal), Première partie, Défi de la semaine ;
  - un aperçu de la collection en silhouettes et 3 médailles à obtenir.

### Ce qui change par rapport à l'état actuel

- Une longue page défilante devient 4 onglets sans défilement, avec une hiérarchie claire : chiffres clés, puis détail, puis graphiques.
- La collection et les succès deviennent visuels (grilles d'images, médailles) au lieu de listes.
- Le premier lancement donne trois actions à faire, au lieu de tableaux vides.

### Données en plus

- Date de la première partie (déjà prévue).
- Matricule : c'est purement décoratif, on peut le dériver du pseudo.
- Grade : il se calcule à partir des victoires, par exemple Stagiaire (0), Cadre (3), Directeur adjoint (15), Directeur (30), Membre du comité (60).
- Pour chaque espèce, le nombre d'installations et la dernière date (pour l'infobulle). Si c'est trop coûteux, l'infobulle peut se limiter au nom et à la rareté.

### Nouvelles briques

- Onglets intercalaires avec compteur.
- Chiffre clé (KPI) de 108 px de haut.
- Fiche signalétique avec tampon.
- Tuile d'espèce (normale ou silhouette, avec la forme de rareté au coin).
- Portrait (normal ou silhouette).
- Médaille de succès (obtenue ou non).
- Carte de mission.
- Barre empilée avec légende.

### Cotes principales

| Élément | Cotes |
|---|---|
| Fenêtre | x 160, y 100, 1280 × 700, contour 2,5, rayon 12. En-tête h 78 |
| Onglets | à partir de x 260, h 44 (actif) ou 38 |
| Corps | marges 20. Colonne gauche l 330, colonne droite à x 370, l 870, gouttière 12 |
| Chiffres clés | 4 × 208 × 108 |
| Tableaux | lignes de 30, en-têtes Barlow Condensed 800 12 en capitales, filet 2 encre sous l'en-tête |

---

## 3. Défis et classements

### Organisation

Une fenêtre de 1280 × 700, coupée en deux colonnes.

- **Colonne gauche (l 740)** :
  - en haut, le **défi de la semaine** en grand :
    - bandeau jaune, date du prochain défi ;
    - vignette de la carte de 142 px, pastille du mode, numéro de carte ;
    - compte à rebours en Plex Mono 30 (« 3 j 03 h 14 min », jusqu'à dimanche 23 h 59) ;
    - record, parties, rang, bouton « Jouer le défi » ;
    - un pied sur fond mémo avec le vainqueur de la semaine passée et « ▶ Revoir sa partie », le seul replay public ;
  - en dessous, les **4 défis permanents** en cartes : vignette, nom, pastille du mode, record, parties, rang, boutons « Classement » et « Jouer ».
- **Colonne droite (l 462) : la cote** du défi choisi, qui s'ouvre à côté, au lieu d'une liste qui se déplie.
  - Bandeau encre (sélection) : nom du défi et nombre de participants.
  - Bloc « Votre rang » en grand (« 14e sur 52 ») et votre record.
  - Le top 10 façon cours de bourse : rang, avec un podium de pastilles or, argent et bronze **numérotées** (le chiffre double la couleur) ; pseudo ; score ; barre proportionnelle.
  - Une ligne « ⋯ », puis **votre ligne** sur fond jaune, toujours visible.
  - En pied, la règle de confidentialité en une phrase.
- **Lien entre le défi choisi et la cote** :
  - la carte (ou le défi de la semaine) choisie porte un anneau jaune de 4 px ;
  - son bouton « Classement » passe en encre ;
  - la cote reprend son nom dans le bandeau.

> **Correction de l'utilisateur (12/11), prioritaire sur les maquettes 30 et 32** : le top 10 est visible par tous, **avec les pseudos**, que le joueur y soit ou non. Ce qui reste privé, ce sont les joueurs hors du top 10 : chacun ne voit que sa propre ligne sous le « ⋯ », jamais celle des autres. La pastille « joueur masqué » ne sert donc plus, et le serveur ne renvoie jamais de ligne hors du top 10 en dehors de celle du joueur.

### États

| État | Ce qui s'affiche |
|---|---|
| Hors du top 10 | Le top 10 garde ses scores, mais chaque pseudo est remplacé par une pastille hachurée en pointillé « joueur masqué ». Votre ligne apparaît sous le « ⋯ ». À droite : « 6 points du top 10 » |
| Dans le top 10 | Les pseudos sont visibles. Votre ligne est jaune à sa place, avec « ✓ dans le top 10 : pseudos visibles » |
| Jamais joué | Le top 10 est masqué. Votre ligne, jaune clair, indique « — · pas encore classé » avec un bouton « Jouer › ». La carte affiche « Pas encore joué » et le nombre de participants |
| Indisponible | Une mention discrète dans l'en-tête de la fenêtre : ▲ « Hors ligne : classements indisponibles ». La cote affiche seulement le meilleur score local, puis un cadre en pointillé « Classement indisponible » avec la phrase « le score sera envoyé à la prochaine connexion » et « ↻ Réessayer ». Les rangs des cartes passent à « — » |
| Chargement | Des barres grisées (squelette) à la place des pseudos, des scores et des rangs, et « cotation en cours… ». Le podium et les numéros de rang restent en place, pour que rien ne saute quand les données arrivent (1 à 2 s) |

### Points d'implémentation

- **La confidentialité se fait côté serveur** : la fonction `classement` ne renvoie que le top 10 (avec pseudos) et la ligne du joueur lui-même.
- Le compte à rebours se calcule en heure locale jusqu'au dimanche 23 h 59 et se rafraîchit chaque minute.
- Le nombre de participants vient du serveur. Hors ligne, il disparaît.

### Nouvelles briques

- Carte de défi (vignette, pastille du mode, 3 lignes de chiffres, 2 boutons).
- Bandeau de défi de la semaine avec compte à rebours.
- Ligne de cote : rang ou podium, pseudo ou pastille masquée, score, barre.
- Ligne « vous ».
- Pastille « joueur masqué ».
- Squelette de chargement.
- Cadre « indisponible ».

### Cotes principales

| Élément | Cotes |
|---|---|
| Défi de la semaine | x 20, y 20 (dans le corps), 740 × 252. Bandeau h 40. Pied h 44 |
| Cartes de défi | à partir de y 314, 4 × 176 × 284, gouttière 12. Vignette h 76 |
| Cote | x 778, 462 × 579. Lignes h 33 avec une grille de colonnes 40 / 1fr / 54 / 92 |
