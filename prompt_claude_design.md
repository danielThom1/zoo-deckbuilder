Bonjour ! Je développe un jeu vidéo et je cherche une **direction artistique**. Le jeu est jouable en prototype 2D très simple (rectangles de couleur, interface par défaut). Je voudrais que tu me proposes **plusieurs directions de design** et des maquettes des écrans principaux. Voici tout ce qu'il faut savoir.

## Le jeu en une phrase
Un jeu de gestion vu du dessus qui mélange **deckbuilding d'ouvriers** et **construction d'un zoo**. Chaque joueur recrute, forme et déploie des ouvriers (des cartes) pour extraire des ressources, aménager le terrain et bâtir le zoo le plus réputé. Titre provisoire : « Zoo Deckbuilder ».

## Technologie et cible visuelle
- **Moteur** : le prototype est sous Godot 4.7. La version finale sera probablement sous **Unreal Engine 5** (Lumen, Nanite, bibliothèque Quixel/Fab), en **3D vue du dessus avec une caméra inclinable**, qu'on peut tourner et zoomer, dans l'esprit de *Manor Lords* et de *Planet Zoo* : terrain naturel détaillé, végétation dense, lumière du jour qui évolue, grille visible seulement en mode construction.
- **Je veux un rendu riche et détaillé, pas une interface minimaliste ni du low-poly simpliste.** Références : *Manor Lords* (terrain, lumière, ambiance), *Planet Zoo* (animaux, enclos, foule), *Frostpunk* et *Anno 1800* (interfaces de gestion riches et élégantes), *Slay the Spire* et *Inscryption* (cartes à forte identité). Les maquettes doivent montrer des textures, de la matière, de l'éclairage, des cadres de cartes ouvragés et de vraies illustrations.
- Le développeur est **seul**, mais il peut s'appuyer sur des bibliothèques d'assets réalistes (Quixel, Fab, MetaHuman pour les ouvriers). Dis-moi ce qui demanderait des assets sur mesure.
- **Personnages modulaires** : chaque ouvrier doit être unique (tête, coiffure, tenue, couleurs) et son métier doit se lire au premier coup d'œil.
- **Portraits** : ils seront générés automatiquement en filmant le modèle 3D (caméra dédiée). Le style des portraits doit donc découler du style 3D.
- **Écran** : 16:9, conçu en 1600×900. L'interface est entièrement **en français**.
- **Partie** : environ 1 h, de 1 à 4 joueurs (humain contre IA). Chaque joueur a sa propre copie de la même carte.

## Déroulement d'une partie
1. **Draft serpent** : un pool de cartes ouvriers (70 % peu qualifiés, 20 % qualifiés, 10 % cadres) que les joueurs se partagent à tour de rôle jusqu'à 10 cartes chacun.
2. **Jour (temps réel, 5 minutes)** : on pioche 5 cartes. Déployer un ouvrier coûte son salaire ; un ouvrier par jour peut être déployé gratuitement, à 25 % de rendement. On sélectionne les ouvriers à la souris (clic gauche, sélection en rectangle) et on leur donne des ordres (clic droit) : extraire du bois ou de la pierre, construire, aménager le terrain, tenir un poste, partir en lobbying. Beaucoup de micro-gestion, avec un chronomètre visible.
3. **Nuit (tour par tour)** : revenus du zoo (visiteurs, billetterie, souvenirs), montées de niveau, licenciements, puis **marché partagé** dans l'ordre d'influence : 5 ouvriers à embaucher et 4 contrats d'animaux à acheter.
4. **Fin** : le premier zoo à 100 de réputation gagne.

## Les éléments à mettre en scène
- **Carte** : 64×64 cases. Terrains : prairie, forêt, eau (lacs et rivières), roche, sable, montagne, et 2 gisements d'or. Le camp de base est en bas au centre, relié au bord de la carte par une **route d'accès** (les ouvriers en lobbying sortent par là).
- **Ressources** : argent, bois, pierre, or, influence (cachée aux autres joueurs).
- **Ouvriers (cartes)** :
  - 7 métiers peu qualifiés : Manœuvre, Bûcheron, Maçon, Mineur, Terrassier, Porteur, Apprenti.
  - 4 métiers qualifiés : Charpentier, Paysagiste, Cantonnier, Soigneur.
  - 7 cadres : DRH, Lobbyiste, Marchand, Vendeur de souvenirs, Formateur, Contremaître, Architecte.
  - Chaque ouvrier a 0 à 2 qualités et 0 à 2 défauts, par exemple Costaud, Rapide, Charismatique (bonus de zone autour de lui), Lent, Paresseux, Col blanc (cadres uniquement)…
  - Un niveau de 1 à 4 : le salaire monte avec le niveau.
- **Bâtiments** : route, pont, maison d'ouvriers, entrepôt, mine d'or, segments d'enceinte du zoo, entrée du zoo, clôtures d'enclos, boutique de souvenirs, centre de formation.
- **Aménagement du terrain** : défricher, planter une forêt, creuser un bassin, combler, poser des rochers, ensabler, engazonner.
- **Animaux** : 35 espèces dans 6 biomes (Savane, Forêt, Jungle, Aquatique, Montagne, Désert), en 3 paliers T1, T2, T3 (du Suricate à l'Éléphant). Chaque espèce exige un **enclos fermé** d'une certaine taille avec un **motif de terrain**. Exemple : « Tigre : 8 cases, dont 3 de forêt, 2 d'eau, 1 de roche et 1 de prairie, avec au moins 3 paires eau/forêt côte à côte ». C'est un puzzle de terrain dans l'esprit du jeu de société *Harmonies*.
- **Personnel** : il faut quelqu'un au guichet et à la boutique pour encaisser. Les forêts et les roches s'épuisent, les mines d'or rapportent gros.
- **Événements aléatoires** (Pluie, Canicule, Journaliste, Épidémie…) chaque matin, et **bonus de nuit** à choisir dans l'ordre d'influence. À partir du milieu de partie, on peut améliorer ou licencier un ouvrier chaque nuit.
- **Zoo** : une enceinte fermée avec une entrée. Les visiteurs viennent selon le nombre d'espèces et de biomes ; la réputation vient de la diversité.

## Les écrans dont j'ai besoin
1. **Menu principal** (jouer contre l'IA, regarder des IA jouer).
2. **Draft** : une grille de cartes ouvriers à choisir, les choix de chaque joueur, à qui c'est le tour.
3. **Jeu de jour** :
   - barre du haut : jour, chrono, réputation, argent, bois, pierre, or, influence, logement, vitesse ;
   - **la main de 5 cartes** en bas (déployer / gratuit / sélectionner) ;
   - un menu de construction ;
   - un panneau d'information sur l'ouvrier ou le chantier sélectionné ;
   - des messages éphémères.
4. **Placement** : l'aperçu d'un bâtiment (valide ou non), et la **validation d'un enclos** au survol (zone détectée et exigences remplies ou manquantes).
5. **Écran de nuit** : le bilan de la journée, le classement de réputation, l'ordre de passage, le marché des ouvriers et des contrats, le licenciement.
6. **Fin de partie**.

## Ce que j'attends de toi
- **2 ou 3 directions artistiques** contrastées. Pour chacune : une ambiance (mots-clés et références), une palette, une typographie, le traitement de la lumière, des terrains et de l'eau, et ce que ça demanderait techniquement dans Godot.
- **Le design des cartes** : carte ouvrier (portrait, métier, catégorie, niveau, qualités et défauts, salaire, boutons) et carte contrat d'animal (biome, palier, motif de terrain requis, réputation, nourriture, coût).
- **Des maquettes** du jeu de jour, de l'écran de nuit et du draft, en 1600×900.
- **Les ouvriers** : comment différencier les métiers (silhouette, outils, couleurs) et les catégories (peu qualifié, qualifié, cadre), et comment montrer leur état (en train de porter une charge, en pause, inactif, hors carte).
- **Un langage visuel** pour les biomes et les terrains qui rende le puzzle des enclos lisible.
- **Des icônes** : ressources, métiers, qualités et défauts.

## Contraintes
- **Lisibilité avant tout** : c'est un jeu de gestion avec beaucoup d'informations, il faut pouvoir lire la carte, les cartes et l'interface d'un coup d'œil, même en vue éloignée.
- **Accessibilité** : qualités et défauts ne doivent pas reposer uniquement sur le vert et le rouge ; prévois un deuxième signe (icône, forme).
- Un ton **chaleureux et accueillant** (c'est un zoo), mais pas enfantin : la gestion est exigeante.
- Pour les maquettes : **produis des images travaillées** (matières, lumière, détails, illustrations de cartes), pas des schémas en aplats de couleur. Si un outil te limite à des formes simples, dis-le et décris précisément le rendu visé.

Si quelque chose n'est pas clair, pose-moi tes questions avant de te lancer.
