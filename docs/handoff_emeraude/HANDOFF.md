# Zoo Deckbuilder — Handoff direction artistique « Émeraude »

Spécification d'implémentation pour Claude Code (ou un développeur). Tout ce qui est visible à l'écran est en **français**. Référence d'écran : **1600 × 900**.

---

## 1. Objet et hypothèses

- **Cible principale : prototype Godot 4.x** (testé mentalement sur 4.3+ ; aucun fichier n'a été compilé dans un vrai projet). Une table de correspondance UE5 est donnée en §13 pour la version finale.
- Les maquettes sont la **source de vérité visuelle** pour l'interface (HUD, cartes, écrans). Le monde 3D des maquettes est une **illustration en SVG** : il indique couleurs, lisibilité et ambiance, pas une géométrie à reproduire au pixel.
- Les valeurs de jeu affichées (prix, salaires, récompenses, stats de fin) sont des **valeurs factices** (§11).
- Projet : `Project Settings > Display > Window` → viewport 1600×900, `stretch/mode = canvas_items`, `stretch/aspect = expand`. Toutes les cotes ci-dessous sont en px à cette taille.

## 2. Contenu du dossier

| Chemin | Contenu |
|---|---|
| `captures/01…08_*.png` | Captures de référence des 8 planches (1600×900, système 1600×1100) |
| `maquettes_source/*.dc.html` | Sources des maquettes (HTML/SVG). `Vif.dc.html` contient le monde, le HUD et la main ; les `E_*` sont les écrans |
| `tokens.json` | Tous les jetons : couleurs, dégradés, états, catégories, ressources, biomes, terrains, typo, formes, tailles de composants, caméra/lumière |
| `icones/*.svg` | 76 icônes au trait, viewBox 24, trait blanc 2 px, à teinter par `modulate` |
| `godot/ui_tokens.gd` | Jetons en constantes GDScript (`class_name UiTokens`) |
| `godot/construire_theme.gd` | EditorScript qui génère `res://ui/theme_emeraude.tres` (variations de type) |
| `godot/grille_construction.gdshader` | Grille du mode construction en espace monde |
| `godot/eau.gdshader` | Eau stylisée (profondeur → couleur, écume de berge) |

Correspondance captures ↔ sources :

| Capture | Source | Contenu |
|---|---|---|
| 01_menu | E_Menu.dc.html | Menu principal + carte « Nouvelle partie » |
| 02_draft | E_Draft.dc.html | Draft serpent initial |
| 03_jour | E_Jour.dc.html → Vif (mode `jour`) | HUD de jour, main, panneau d'unité |
| 04_placement | E_Placement.dc.html → Vif (mode `placement`) | Mode construction, enclos, fantômes |
| 05_nuit | E_Nuit.dc.html → Vif (mode `nuit`) | Phase de nuit : marché, contrats, bonus |
| 06_fin | E_Fin.dc.html | Fin de partie : podium, courbes, stats |
| 07_composants_cartes | E_Cartes.dc.html | Anatomie carte ouvrier, 6 états, contrat, tuiles |
| 08_composants_systeme | E_Systeme.dc.html | Système complet : couleurs, typo, boutons, icônes, écussons |

## 3. Principes (à respecter à chaque écran)

1. **Lisibilité d'abord.** Le monde est saturé et chaud ; l'interface est un cadre sombre émeraude à filet doré qui ne concurrence jamais la carte. Texte clair `#F4FAEE` sur panneau sombre, jamais de texte sur le monde sans plaque.
2. **Jamais vert/rouge seuls.** Qualité = **cercle bleu `#3A8AE8` + « + »**. Défaut = **carré orange `#E8782A` (rayon 3) + « − »**. Exigence remplie / manquante suivent le même code (icônes `ui_valide` / `ui_invalide`). Placement invalide = contour orange **+ hachures 45°**. Chaque catégorie d'ouvrier a une couleur **et** une forme (chevron / double chevron / étoile).
3. **Chaleureux, pas enfantin.** Titres en Marcellus SC (capitales gravées), chiffres en Source Sans 3 très gras, bords dorés, portraits peints.
4. **Une seule graisse pour Marcellus SC (400).** Ne jamais activer de gras synthétique dessus.
5. **L'influence est privée** : jamais affichée pour les adversaires.
6. **Faisable seul** : tout le HUD = `PanelContainer` + `StyleBox` + icônes SVG teintées. Pas d'animation obligatoire hors levée de carte et pulsation de sélection.

## 4. Jetons, polices, styles

### 4.1 Couleurs
Voir `tokens.json` (source unique) et `godot/ui_tokens.gd`. Les essentielles :

| Rôle | Valeur |
|---|---|
| Panneau (dégradé vertical) | `#11564E` → `#08302C` |
| En-tête de panneau | `#1C7468` → `#10483F`, filet bas 1 px `#E2AE62` |
| Or / or sombre / or clair | `#E2AE62` / `#6A4418` / `#FFF0B8` |
| Bouton principal | `#FFD89A` → `#C88A3A`, texte `#1E1406` |
| Texte / secondaire | `#F4FAEE` / `#A6D4C8` |
| Sélection, focus | `#FFD45A` |
| Joueur / IA | `#18A88A` / `#E8A020` / `#3A6AE0` / `#E04A8A` |

### 4.2 Polices (licence OFL, Google Fonts)
- **Marcellus SC** Regular → `res://ui/fonts/MarcellusSC-Regular.ttf` (titres, noms de cartes, en-têtes).
- **Source Sans 3** Regular, SemiBold, Bold, ExtraBold → `res://ui/fonts/SourceSans3-*.ttf` (corps, chiffres).
- Télécharger depuis fonts.google.com. Dans l'import : `antialiasing = LCD` off, `hinting = Light`, `msdf` activé pour les tailles > 30 px (titre du menu).

Échelle : titre d'écran 30–46 px (interlettrage 0,08 em) ; en-tête panneau 16–18 ; nom de carte 12,5 en capitales ; compteurs 18 ExtraBold ; corps 14–15 ; légende 12–13, **minimum 11,5**.

### 4.3 Panneaux et bordures dorées
`StyleBoxFlat` ne fait ni dégradé de fond ni dégradé de bordure. Trois options, par ordre de préférence :
1. **Prototype** : `StyleBoxFlat` à plat (`PANNEAU_MILIEU`, bord `OR` 2 px, rayon 10) — ce que génère `construire_theme.gd`.
2. **Fidèle** : un `StyleBoxTexture` 9-patch peint (PNG 64×64, marges 12) contenant dégradé + bord doré biseauté. Un seul fichier réutilisé partout.
3. Shader `canvas_item` sur un `Panel` pour un dégradé paramétrable (à éviter dans des listes longues).

Ombre de panneau : `0 10 24 rgba(0,0,0,.40)` → `shadow_size 12, offset (0,6)`.

### 4.4 Variations de type du thème
`PanneauEmeraude`, `EnteteEmeraude`, `TitrePanneau`, `TexteSecondaire`, `BoutonPrincipal`, `BoutonSecondaire`, `BoutonOrdre`. Exécuter `godot/construire_theme.gd`, puis assigner `theme_emeraude.tres` à la racine `CanvasLayer/HUD` (Control) et dans `Project Settings > GUI > Theme > Custom`.

### 4.5 Icônes
- 76 SVG au trait blanc → import Godot en `Texture2D` avec `svg/scale = 2.0` (net en 48 px). Teinter avec `modulate` / `self_modulate`.
- Nommage `famille_nom` : `ressource_`, `metier_`, `categorie_`, `qualite_`, `defaut_`, `etat_`, `ordre_`, `batiment_`, `biome_`, `terrain_`, `evenement_`, `ui_`.
- Pastille d'icône standard : disque de la couleur de la ressource (`tokens.ressources.*.couleur`) avec reflet radial (`reflet`), icône blanche centrée à 60 %.

## 5. Architecture Godot

```
res://
  ui/
    fonts/  icones/ (copie de icones/)  theme_emeraude.tres
    composants/
      CarteOuvrier.tscn      # tailles MAIN / DRAFT / MARCHE (export enum)
      CarteContrat.tscn
      JetonRessource.tscn    # icône + valeur + delta
      BoutonOrdre.tscn       # rond 46 px + infobulle
      EcussonOuvrier.tscn    # Sprite3D billboard au-dessus des ouvriers
      PanneauEmeraude.tscn   # PanelContainer + en-tête optionnel
      MedaillonJour.tscn     # TextureProgressBar radial + icône soleil/lune
      Notification.tscn
      TuileTerrain.tscn      # carré 18–24 px à motif
    ecrans/
      MenuPrincipal.tscn  Draft.tscn  HudJour.tscn  Nuit.tscn  FinPartie.tscn
  monde/
    Monde.tscn  CameraRTS.gd  GrilleConstruction (MeshInstance3D + grille_construction.gdshader)
    eau.gdshader  Enclos.gd  FantomePlacement.gd
  autoload/ UiTokens.gd (ou class_name seulement)  Jeu.gd (état, signaux)
```

Règles :
- Les écrans **ne lisent pas** l'état directement : ils reçoivent des `Resource` (`DonneesOuvrier`, `DonneesContrat`…) et écoutent des signaux de `Jeu`.
- `CarteOuvrier` expose `etat: enum {NORMAL, SURVOL, SELECTION, DEPLOYEE, BLOQUEE, NOUVELLE}` (cf. capture 07) et `taille: enum {MAIN, DRAFT, MARCHE}`.
- Portraits : `SubViewport` 3D partagé (un personnage posé, éclairage studio) rendu dans une `ViewportTexture` mise en cache par ouvrier ; en prototype, une image peinte suffit. Fond du portrait = `CAT_FOND_PORTRAIT[categorie]`.

### 5.1 Composant CarteOuvrier (voir capture 07, 8 repères)
Taille main 136×216, rayon 10, bord doré dégradé (`bordure_or_carte`).
1. **Badge catégorie + niveau** en haut à gauche : pastille couleur de catégorie + icône forme (chevron / double chevron / étoile) + `N1`…`N3` (libellés longs `PEU QUAL.`, `QUALIFIÉ`, `CADRE` dans les infobulles et le panneau détail).
2. **Pièce de salaire** en haut à droite, Ø 32, dégradé radial `piece_or`, chiffre 800 sombre.
3. **Portrait** hauteur 98 (main) / 86 (draft) / 88 (marché), fond = couleur portrait de catégorie.
4. **Niveau** : étoiles dorées sous le portrait (1 à 3).
5. **Nom du métier** Marcellus SC 12,5 capitales.
6. **Qualités / défauts** : pastilles cercle bleu « + » / carré orange « − » + nom court.
7. **Capacité / ordres** : icônes `ordre_*` 18 px.
8. **Actions** (main seulement) : bouton `Déployer` (principal) + bouton `25 %` (secondaire, `nowrap`).

États : survol = +8 px, contour `#FFD45A` ; sélection = levée 26 px + halo `#FFD45A` pulsant 1,2 s ; déployée = désaturée 60 % + badge « SUR LE TERRAIN » centré à `top 72` ; bloquée = voile sombre + icône `ui_invalide` sur carré orange ; nouvelle = ruban or « NOUVEAU ».

### 5.2 Composant CarteContrat (204×292)
Bandeau biome 30 px (couleur biome + icône), illustration de l'espèce 86 px, nom de l'espèce, **exigences** en rangée de tuiles terrain 18 px (motifs : prairie = traits verticaux, forêt = triangles blancs, eau = vagues, roche = triangles sombres, sable = points, montagne = pics, or = losange), chacune avec cercle bleu ✓ ou carré orange ✗, puis récompense (réputation, argent) et coût.

### 5.3 Écusson d'ouvrier (monde)
`Sprite3D` billboard, `fixed_size = true`, `pixel_size ≈ 0.0008`, rendu dans un `SubViewport` 64×64 ou atlas pré-généré : écusson 34×40 (sélection 44×50), fond couleur catégorie, icône métier blanche, liseré couleur joueur. Pastille d'état en coin : inactif `#E8B020` (icône `etat_inactif`), pause `#7A8A88` (icône `etat_pause`). Masquer au-delà d'une distance caméra configurable ; ne garder que ceux du joueur + sélection en zoom arrière.

## 6. Écrans (cotes à 1600×900)

### 6.1 HUD de jour — capture 03
| Élément | Position / taille | Détails |
|---|---|---|
| Barre du haut | x 0, y 0, plein écran, h 52 | Jetons ressource h 40 (icône 32 + valeur 18 ExtraBold + delta vert/orange **avec flèche ▲/▼**), à droite jour + phase + bouton pause |
| Panneau Construire | x 14, y 64, l 238 | Lignes h 54 : icône bâtiment, nom, coût en jetons ; ligne survolée = fond `rgba(255,255,255,.12)` + filet or à gauche |
| Panneau Zoo | droite 14, y 64, l 262 | Réputation, visiteurs, billetterie, enclos et leur état |
| Panneau d'unité | x 14, bas 14, l 344, h min 186 | Portrait 112, nom, métier, qualités/défauts, rangée de `BoutonOrdre` 46 px |
| Pioche / défausse | x 372, l 86 | Pile de dos de cartes + compteurs |
| Main | x 474 → , bas −34 (les cartes dépassent de 34 px), cartes 136×216, écart 8 | Éventail léger (±2°) optionnel |
| Notifications | droite 22, bas 186 | Bulles Ø 40–46, empilées vers le haut, icône événement |
| Médaillon jour | droite, Ø 164, anneau 8 | `TextureProgressBar` radial, soleil → lune, bouton `Terminer la journée` dessous |

### 6.2 Mode construction — capture 04
- Bandeau central haut « MODE CONSTRUCTION » (Marcellus 18, plaque émeraude) + rappel `Échap pour annuler`.
- Main **repliée** (seuls les 40 px du haut des cartes visibles).
- Grille monde via `grille_construction.gdshader`, `opacite` interpolée 0 → 1 en 0,15 s.
- **Enclos survolé** : chaque case teintée par son terrain en **motif** (les mêmes motifs que les tuiles UI), liens d'appariement eau/forêt dessinés en traits or. Panneau « Enclos survolé » à droite (l 300) : liste des exigences de l'espèce avec cercle bleu ✓ / carré orange ✗, et l'enceinte (fermée / segment manquant).
- **Fantôme valide** : maquette transparente + contour `#FFD45A`, remplissage `rgba(255,212,90,.32)`.
- **Fantôme invalide** : contour `#E8782A` + hachures 45° (pas 14 px) + étiquette de raison (ex. « Chevauche l'enceinte »). Jamais rouge seul.
- Segment de clôture manquant : pointillés orange clignotants + icône `ui_invalide`.

### 6.3 Draft — capture 02
Monde flouté 6 px + voile 84 %. En-tête h 76 : titre, **ordre serpent** (pastilles des joueurs avec flèche aller/retour, joueur courant agrandi et cerclé `#FFD45A`), minuteur. Filtres en onglets (Tous / Peu qualifiés / Qualifiés / Cadres, avec compteurs). Grille de cartes 146×196, 7 colonnes × 3 rangées visibles (21), le reste en défilement vertical, écart 12, origine (32, 96). Carte survolée/choisie : contour or + levée. Légende en bas (qualité, défaut, pastille de salaire). Panneau Équipes à droite l 420 : une ligne par joueur avec ses recrues en miniatures ; en bas, encadré détail de la carte survolée + bouton `Recruter`.

### 6.4 Nuit — capture 05
Monde en mode nuit (voile `rgba(6,14,34,.42)`, lampes `#FFAA50`). En-tête : étapes `Revenus › Niveaux › Bonus › Marché › Améliorer/licencier › Jour 4`, étape courante en or.
- Colonne gauche x 20, l 330 : bilan du jour, montées de niveau, améliorer / licencier.
- Centre x 372, l 852 : ordre d'**INFLUENCE** (puces `nowrap`), 5 cartes marché 160×236, 4 contrats 204×292 (tigre, zèbre, ours brun, fennec), tuiles d'exigence 18 px.
- Colonne droite l 340 : réputation, bonus de nuit, événement du lendemain.

### 6.5 Menu — capture 01
Monde en mode décor flouté. Médaillon patte + titre « ZOO / DECKBUILDER » en (96, 96), Marcellus 46, accroche en dessous. Boutons empilés en (96, 340), l 380, chacun avec icône, libellé et sous-titre : `Jouer contre l'IA` (principal doré), `Regarder des IA jouer`, `Didacticiel`, `Options`, `Quitter`. Carte « Nouvelle partie » l 420 en bas à droite (droite 64, bas 64) : nombre d'adversaires (1/2/3), adversaires (pastille couleur + nom + style : Bâtisseuse, Marchande, Prudente), difficulté (Facile/Normale/Difficile), carte + graine, bouton `Lancer le draft`.

### 6.6 Fin de partie — capture 06
Bandeau de victoire, podium (origine 120, 190) avec couleurs joueurs, panneau stats l 620, courbes de réputation par joueur (une `Line2D` par joueur, **marqueurs de forme différente** par joueur en plus de la couleur), biomes réalisés, boutons `Rejouer` / `Menu principal`.

## 7. Monde 3D

- **Caméra RTS** : inclinaison 48°, FOV vertical 33° en vue par défaut ; zoom (molette) entre 35° et 65° d'inclinaison ; rotation par pas de 45° (Q/E) ou libre (clic milieu) ; déplacement ZQSD + bord d'écran.
- **Carte** : 64×64 cases de 1 m. Hors limites : assombri `rgba(10,26,48,.30)`.
- **Terrains** (couleurs monde dans `tokens.terrains`) : prairie `#62AE34` (variante `#74BE40`), forêt canopée 3 tons, roche `#A8A296`, sable `#F2D684`, montagne `#8E7E6C` + neige, filon d'or éclats `#FFE04A`. Chemins `#D6A866`, allées du zoo `#F4E6C4`.
- **Eau** : `eau.gdshader` (profond `#0A3E8A` → berge `#46E0D8`, écume blanche).
- **Lumière** : `DirectionalLight3D` azimut 340°, élévation 30°, ombres douces ; `WorldEnvironment` avec ajustement saturation 1,25, contraste 1,06, brouillard d'horizon clair `rgba(220,252,240,.85)` faible densité.
- **Nuit** : interpoler l'énergie de la lumière vers 0,25 et sa couleur vers `#0A1838`, allumer des `OmniLight3D` `#FFAA50` sur les lampadaires, enclos et bâtiments.
- **Sélection** : anneau décalque `#FFD45A` au sol sous l'unité, pulsation lente.
- Richesse du rendu (version finale) : herbe en instances, arbres détaillés, personnages animés ; le prototype peut utiliser des primitives **tant que les couleurs et la lisibilité suivent les captures**.

## 8. Personnages et portraits
Silhouettes adultes réalistes-stylisées, proportions normales (pas de chibi). Tenue = couleur de catégorie en accent (gilet, casquette). Portrait de carte : buste 3/4, fond uni couleur portrait de catégorie, léger vignettage. Le métier doit se lire par un **accessoire** (hache, truelle, carnet, seau…), pas seulement par la couleur.

## 9. Accessibilité — check-list d'acceptation
- [ ] Aucune information portée uniquement par vert/rouge (qualités, défauts, exigences, placement, deltas avec flèches).
- [ ] Contraste texte ≥ 4,5:1 (corps), ≥ 3:1 (≥ 18 px). Texte secondaire `#A6D4C8` sur `#08302C` OK.
- [ ] Taille de texte min 11,5 px à 1600×900 ; option « Taille de l'interface » 90–130 % (facteur `content_scale_factor`).
- [ ] Zones cliquables ≥ 44 px ; focus clavier visible (anneau `#FFD45A` 2 px décalé de 3).
- [ ] Chaque icône d'ordre a une infobulle française et un raccourci (1–7).
- [ ] Test avec un filtre deutéranopie/protanopie (shader plein écran de debug).

## 10. Libellés et ton
Tout en français, vouvoiement dans les tutoriels, verbes à l'infinitif sur les boutons (`Déployer`, `Recruter`, `Terminer la journée`, `Améliorer`, `Licencier`). Espaces insécables avant `%`, `:`, `!`, `?` (ex. `25 %`).

## 11. Valeurs factices à remplacer
- Prix, salaires, coûts de construction, récompenses et valeurs des contrats.
- Le défaut « Maladroit » (nom et effet à confirmer).
- La liste et les effets des bonus de nuit.
- L'événement du lendemain (canicule / pluie) et ses effets.
- Les stats et courbes de l'écran de fin.
- Les noms et personnalités des IA (Bâtisseuse, Marchande, Prudente).

## 12. Jalons et critères d'acceptation

| # | Jalon | Fini quand… |
|---|---|---|
| 1 | Socle : projet 1600×900, polices, icônes importées, `UiTokens`, thème généré | Une scène de test affiche chaque variation de type ; capture comparée à 08 |
| 2 | Composants : CarteOuvrier (3 tailles, 6 états), CarteContrat, JetonRessource, BoutonOrdre, Médaillon | Une galerie reproduit la capture 07 |
| 3 | HUD de jour (sur un monde gris placeholder) | Superposition de la capture 03 à 50 % : écarts < 4 px sur les panneaux |
| 4 | Monde : caméra RTS, terrains colorés, eau, lumière jour | Vue par défaut proche de la capture 03 en couleurs et lisibilité |
| 5 | Mode construction : grille, fantômes, enclos à motifs, panneau de validation | Comportement et visuels de la capture 04 ; aucun état porté par la couleur seule |
| 6 | Nuit (éclairage + écran) | Capture 05 |
| 7 | Draft, Menu, Fin | Captures 02, 01, 06 |
| 8 | Accessibilité | Check-list §9 cochée |

Méthode de contrôle : faire une capture Godot à 1600×900 (`get_viewport().get_texture().get_image().save_png()`), la superposer à la capture de référence et noter les écarts.

## 13. Correspondance UE5 (version finale)
| Godot | UE5 |
|---|---|
| Theme + variations de type | Common UI : `CommonButtonStyle`, `CommonTextStyle`, `CommonBorderStyle` |
| StyleBox 9-patch | Slate Brush en mode `Box` (marges 12) |
| `UiTokens` | Data Asset ou `UDeveloperSettings` + table de couleurs |
| CarteOuvrier.tscn | Widget Blueprint `WBP_CarteOuvrier` avec enum d'état |
| Écusson `Sprite3D` | Widget Component en espace `Screen` |
| `grille_construction.gdshader` | Matériau de décalque / post-process avec `WorldPosition` + `Frac` |
| `eau.gdshader` | Matériau translucide avec `DepthFade` / `SceneDepth` |
| WorldEnvironment | Post Process Volume (saturation 1,25, contraste 1,06) |

## 14. Questions ouvertes
- Nombre de cartes en main maximum (la main est calibrée pour 7 à 1600 px).
- Rotation libre de la caméra ou par pas de 45° ?
- Les adversaires voient-ils vos contrats pris pendant la nuit ?
- Faut-il un mode daltonien supplémentaire (palette alternative) ou le double codage suffit-il ?
