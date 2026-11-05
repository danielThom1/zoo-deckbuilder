# Redesign de l'interface de ZooLife

Joins à ce message tout le dossier `captures/` (état actuel du jeu, écran par écran) et le dossier `elements_a_conserver/`.

---

Tu es directeur artistique et UX designer de jeux vidéo. Je te demande un **redesign complet de l'interface** de ZooLife : écrans de jour et de nuit, menu principal et écran de fin.

**Tu ne touches ni aux sprites ni aux graphismes.** La carte, les personnages, les animaux, les bâtiments, les portraits, les logos et les têtes d'Hubert restent tels quels, et tu les réutilises. Tu travailles sur ce qui les entoure : disposition, hiérarchie, panneaux, cartes, boutons, typographie, couleurs de l'interface, états, lisibilité.

Ne reproduis pas l'existant en plus joli. Les captures montrent ce que le jeu doit afficher, pas comment il doit l'afficher : tu peux tout réorganiser, fusionner des panneaux, passer des informations au survol ou en créer de nouvelles vues.

## 1. Le jeu

**ZooLife** est un jeu de gestion en 2D vu du dessus, entre deck-building et construction de zoo. De 2 à 4 joueurs (humains ou IA) dirigent chacun leur zoo sur une copie de la même carte, sans s'y croiser. **Le premier à 100 de réputation gagne**, le soir où il les atteint. Une partie dure environ 14 jours de jeu, et une journée dure 5 minutes à vitesse normale (de ×1 à ×16, avec pause).

**Le ton** est une satire d'entreprise. Le joueur dirige une filiale de ZooLife™ sous les ordres d'Hubert de la Marge, « Directeur des Ressources, Humaines et Autres », cynique et drôle, qui commente la partie dans des bulles de BD. Les ouvriers s'appellent des « collaborateurs », l'écran de défaite annonce « Filiale liquidée », celui de victoire « Concession remportée », et le bilan du soir est une note de direction. Les rivaux sont PanZoo Holdings, Safari Capital et BioLand Group. Le style graphique est une **BD néo ligne claire** : encre marine, papier blanc, sarcelle, accent jaune.

### Déroulement
1. **Draft (une fois, au début).** 10 tours de 4 cartes révélées : les joueurs en choisissent une chacun à tour de rôle. Chacun finit avec 8 collaborateurs.
2. **Jour (temps réel).** On pioche une main de 4 cartes (plus avec les améliorations du camp). On mobilise des collaborateurs en payant leur salaire, on leur donne des ordres sur la carte, on construit.
3. **Nuit (par étapes, au tour par tour).** Revenus et bilan, achat de contrats d'animaux, de collaborateurs et de cartes dans l'ordre d'influence, choix du bonus du lendemain, gestion de l'équipe. Puis jour suivant.

### Les ressources (toujours visibles)
Argent (gris neutre), bois, pierre, or (jaune), influence (privée, cachée aux autres), logement (occupé / total), réputation sur 100. S'y ajoutent l'heure et le jour, et la course à 100 avec les quatre joueurs.

### Les cartes de collaborateurs
C'est l'objet central du jeu. Une carte affiche : portrait, prénom, métier, catégorie, niveau (1 à 6 ; le 6 est « légendaire »), salaire, qualités et défauts, améliorations.
- **23 métiers en 3 catégories.** Peu qualifiés (Manœuvre, Bûcheron, Maçon, Mineur, Terrassier, Porteur, Guichetier, Animalier, Agent d'entretien, Apprenti), qualifiés (Charpentier, Paysagiste, Cantonnier, Soigneur), cadres (DRH, Lobbyiste, Marchand, Vendeur de souvenirs, Formateur, Journaliste, Animateur, Contremaître, Architecte).
- **Qualités** (10, cercle bleu) et **défauts** (10, carré orange). Ce double codage couleur et forme est obligatoire, il doit survivre au redesign. Les personnages féminins ont leurs intitulés accordés.
- **Actions sur une carte en main :** Mobiliser (paie le salaire et pose le collaborateur sur le camp), **+4** (cède sa journée contre 4 d'argent, elle part à la défausse), et pour la plupart des cadres **Jouer** (leur action, à la place de travailler).
- **États d'une carte :** normale, survolée, salaire trop élevé (« Manque 2 »), sur le terrain (bouton Localiser), hors de la carte (lobbying, reportage ; bouton Rappeler), prise par un rival au marché du soir.
- **Cartes d'action** à usage unique (Heures sup, Prime, Portes ouvertes, Livraison, Recrutement express, Formation express, Rupture de contrat, Promotion), mélangées dans le deck. Certaines demandent de choisir une cible.

### Le jour
- **Ordres :** clic gauche pour sélectionner (glisser pour plusieurs), clic droit pour envoyer récolter, construire, tenir un poste. Maj + clic droit enchaîne des ordres. Ctrl + glisser sélectionne des bâtiments, double-clic sélectionne tout un tracé.
- **Construire :** 24 bâtiments dans des onglets (Bâtiments, Zoo, Terrain) avec coût et temps de travail. Enceinte et clôtures se peignent en glissant ; un bâtiment non carré se tourne avec R ; un placement invalide doit se voir.
- **Aménager le terrain** (seuls Paysagiste et Terrassier) : défricher, planter, creuser, ensabler…
- **Enclos et animaux :** chaque contrat a un **motif de terrain** (une petite forme de cases Prairie, Forêt, Eau, Roche, Sable) qui doit exister dans l'enclos. Le jeu propose un emplacement, et peut demander un aménagement précis (Grand arbre, Rocher d'observation, Bassin profond, Abri chauffé).
- **Le zoo :** enceinte fermée, entrée, route, au moins un animal pour ouvrir. Il faut ensuite tenir le guichet, nourrir, nettoyer, soigner ; les visiteurs arrivent selon l'attractivité. Un état « Zoo fermé » doit expliquer ce qui manque.
- **Panneaux à droite aujourd'hui :** état du zoo, objectifs des actionnaires (3 par partie, +10 chacun), bonus du jour, événement du jour, bourse des ressources (vendre ou acheter avec une quantité), labels (achetés en or), publicité (3 campagnes), fiche de ce qui est sélectionné.
- **Fiches de sélection :** collaborateur (portrait, tâche et progression, traits, ordres rapides), bâtiment (avec ses boutons : Démolir, Échange d'intérim…), animal (faim, santé, propreté, effets).
- **Fenêtres :** marché du soir consultable en journée, détail des visiteurs, reportage du Journaliste (le parc d'un rival sous brouillard de guerre, article, accusation), pioche et défausse, choix d'une cible.
- **Hubert :** petite bulle qui ne bloque pas, au-dessus de la main ; grande bulle en haut pour l'événement du jour ; son humeur change.

### La nuit
En-tête à étapes : **Contrats › Collaborateurs › Cartes › Bonus › Équipe › Jour suivant**. À chaque étape, on voit qui joue (ordre d'influence), et les IA jouent une par une. Une carte achetée par un rival reste affichée, grisée, « Pris par … ».
- **Note de direction :** recettes et dépenses du jour (billets, boutique, salaires, rations, journées cédées…), réaction d'Hubert, humeur, tampon CONFIDENTIEL.
- **Contrats :** 5 animaux (40 espèces ; communs, peu communs, rares), avec illustration, motif, continent, type, coût, réputation, aménagement requis, et la raison d'un achat impossible. **Il faut pouvoir comparer les 5 d'un coup d'œil.**
- **Collaborateurs :** rangée à embaucher ; remplacer une carte si on a le Cabinet de recrutement.
- **Cartes :** cartes d'action à acheter.
- **Bonus :** seul le premier en influence choisit parmi 3 bonus, ou refuse ; il s'applique à tous le lendemain.
- **Équipe :** choix d'amélioration aux montées de niveau, améliorer ou licencier (payant, ou gratuit avec le DRH).
- **Toujours accessibles :** classement de réputation, objectifs, journal, et « Voir mon zoo », qui montre la carte et les motifs des contrats sans quitter la nuit.

### L'écran de fin
Bandeau (Concession remportée, Filiale liquidée), rapport aux actionnaires, podium de 2 à 4 joueurs avec logos et réputation, chiffres clés, réputation par source, courbes de réputation jour par jour. Une réplique d'Hubert. Sous chaque joueur : **Voir son zoo**, et sous chaque IA : **Revoir sa partie** (le replay complet). Boutons Rejouer, Revoir la carte finale, Menu principal.

### Le menu principal
Logo ZooLife, slogan, choix Jouer contre l'IA, Continuer (si sauvegarde), Multijoueur, Tutoriel, Règles et glossaire, Réglages, Quitter. Panneau de nouvelle partie : 1 à 3 adversaires, difficulté, graine de carte avec aperçu. **Les boutons de développement (« Dév. : … ») ne font pas partie du produit : ignore-les.** Le jeu n'affiche pas « Regarder des IA jouer » pour les joueurs.

### Ce qui existe aussi
Salon multijoueur (héberger, rejoindre, préparation de 20 secondes chaque matin, « Je suis prêt », délais), réglages (volumes, résolution, plein écran), règles et glossaire, tutoriel raconté par Hubert (bulles, voile sombre percé autour de l'élément montré), mode replay (joueur regardé, vitesse, marque REPLAY).

## 2. Ce que je te demande

**Priorité 1, des maquettes à 1600 × 900 :**
1. Jour, écran principal, zoo fermé en début de partie.
2. Jour, zoo ouvert en milieu de partie, avec un collaborateur sélectionné.
3. Jour, pose d'un enclos (contrat à placer, motif visible, emplacement proposé).
4. Jour, fenêtre du marché du soir.
5. Nuit, chaque étape : Contrats, Collaborateurs, Cartes, Bonus, Équipe.
6. Menu principal.
7. Écran de fin, victoire et défaite.

**Priorité 2, si tu as la place :** draft, fiche bâtiment et fiche animal, visiteurs, reportage, pioche et défausse, réglages, salon, replay.

**Et les briques réutilisables :** carte de collaborateur avec tous ses états, carte de contrat, carte d'action, bouton et ses états, panneau, jeton de ressource, infobulle, bulle d'Hubert, ainsi qu'une feuille de style : couleurs en hexadécimal, typographies et tailles, espacements, rayons, ombres et contours.

Pour chaque écran, explique en deux ou trois phrases tes choix : ce qui est toujours visible, ce qui passe au survol, ce que le joueur regarde en premier.

## 3. Contraintes

- **Jeu Godot 4.** L'interface est faite de nœuds Control et de StyleBox (aplats, dégradés simples, contours, ombres, coins arrondis). Évite ce qui demanderait des shaders lourds : flou d'arrière-plan, verre dépoli, animations complexes.
- **Écran de référence 1600 × 900,** mais le jeu s'adapte de 1280 × 720 à la 4K et aux formats larges : indique ce qui s'ancre où.
- **La carte est le jeu.** Le joueur doit voir un maximum de sa carte en journée : c'est là qu'il donne ses ordres. Aujourd'hui, l'interface en cache beaucoup.
- **Tout en français,** et les textes peuvent être longs. Prévois par exemple « Seconde spécialité : Construction en pierre », « Vendeuse de souvenirs » ou « Cabinet de recrutement ».
- **Lisibilité :** jamais la couleur seule pour porter un sens (qualité et défaut, gain et perte, terrains du motif). Texte lisible sur une carte très chargée et colorée.
- **Vocabulaire :** collaborateurs, mobiliser, céder sa journée. L'argent est gris neutre et l'or jaune, pour ne pas les confondre.
- **Licences libres** pour les polices. Celles du jeu aujourd'hui : Barlow et Barlow Condensed pour l'interface, Bangers pour les noms sur la carte. Tu peux en proposer d'autres.
- **L'ambiance reste celle d'une BD satirique sur le monde de l'entreprise :** ne la rends pas générique. Les éléments de la « paperasse » (mémo, tampon, rapport aux actionnaires) sont un bon terrain de jeu.

## 4. Défauts connus de l'interface actuelle

- Le panneau de droite empile trop de choses et devient long : il faut faire défiler pour atteindre la bourse, les labels et la publicité.
- Les panneaux de gauche et de droite et la main prennent beaucoup de carte.
- La barre du haut est pleine et déborde vite dès qu'on y ajoute un élément.
- La nuit, tout tient dans trois colonnes étroites, et les 5 contrats sont serrés.
- Le chemin principal n'est pas assez clair : le joueur ne sait pas toujours quoi faire ensuite ni où regarder.
- Les informations détaillées d'une carte (ce que fait le métier, les traits) sont cachées dans des infobulles difficiles à découvrir.
- Certains textes ont débordé ou se sont superposés quand ils étaient longs : la mise en page doit les supporter.

## 5. Les pièces jointes

**`captures/`, l'état actuel à 1600 × 900 :**

| Fichier | Écran |
|---|---|
| `01_menu` | Menu principal (les boutons « Dév. » en haut à droite n'existent que pour moi) |
| `02_draft` | Draft |
| `03_jour_debut` | Début de journée, zoo fermé, main de cartes |
| `04_jour_zoo_ouvert` | Zoo construit |
| `05_jour_collaborateur_selectionne` | Collaborateur sélectionné, fiche avec un texte long |
| `06_jour_contrat_a_placer` | Contrat à placer, aide au placement |
| `07_jour_marche_du_soir` | Marché du soir consulté en journée |
| `08_jour_visiteurs` | Détail des visiteurs |
| `09_jour_reportage_journaliste` | Reportage chez un rival |
| `10_jour_pioche_defausse` | Pioche et défausse |
| `11` à `15_nuit_…` | Nuit : contrats, collaborateurs, cartes, bonus, équipe |
| `16_nuit_voir_mon_zoo` | « Voir mon zoo » pendant la nuit |
| `17_ecran_de_fin` | Écran de fin (défaite) |
| `18_aide_regles`, `19_aide_glossaire` | Règles et glossaire |
| `20_reglages` | Réglages |
| `21_multijoueur_salon` | Salon multijoueur |
| `22_bulle_hubert` | Grande bulle d'Hubert (événement du jour) |

Sur ces captures, la grande bulle d'Hubert est souvent visible en haut, même la nuit : elles ont été prises juste après un événement. En jeu, elle s'efface seule au bout de quelques secondes.

**`elements_a_conserver/`, à réutiliser sans les modifier :** logos de ZooLife et des rivaux, têtes d'Hubert selon son humeur, exemples de portraits de collaborateurs, animaux et bâtiments, et les icônes de l'interface utilisées aujourd'hui.

Commence par me dire ce qui, selon toi, pose le plus problème dans l'interface actuelle et ta direction générale, puis produis les maquettes.
