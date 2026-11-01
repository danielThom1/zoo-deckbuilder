# Zoo Deckbuilder — Intégration du style « BD néo ligne claire »

Document pour Claude Code. Tout est fourni : assets découpés, décor et textures déjà rendus, code Godot **testé dans le jeu** (Godot 4.7.2, version GitHub `490dfe0`), patch de référence, captures cibles et captures obtenues. Texte du jeu : **français**. Écran de référence 1600×900.

> Le dépôt local a évolué depuis `490dfe0` (le rendu du terrain a changé). Le code fourni est **autonome** (nouveaux fichiers) ; seuls quelques points de `main.gd` sont à brancher. Le patch `patch_main_reference.diff` montre comment c'est fait sur `490dfe0` : **adapter au code actuel**, ne pas l'appliquer aveuglément.

---

## 1. Décisions de direction artistique (validées par l'auteur)

- **Carte** : rendu « 6 · votre carte redessinée » → `captures/cible_carte.png` (et `cible_zoo.png` pour un zoo avancé). Semi-perspective : plateaux de montagne à falaises, berges visibles au-dessus de l'eau, arbres/rochers/pics dessinés et triés en profondeur, prairie très détaillée (brins, touffes, trèfle, fleurs, cailloux), eau en paliers de profondeur avec écume et reflets, sable ondulé, rocaille caillouteuse. Encre marine `#14202B` partout.
- **Sprites** : bâtiments, personnages, animaux et portraits des planches de l'auteur (style BD semi-réaliste) → tout est dans `game/assets/bd/sprites/`.
- **Interface** : variante C « Néo ligne claire » → `captures/cible_interface.png` (panneaux blancs, cerne d'encre 3 px, ombre nette décalée 4 px, en-têtes sarcelle tramés, accent jaune `#FFC93C`, Barlow / Barlow Condensed). C'est l'**étape 2** (voir §6) : à faire après la carte.
- Accessibilité inchangée : jamais la couleur seule (qualité = cercle bleu « + », défaut = carré orange « − », catégories = couleur + forme › » ★, placement invalide = contour + hachures).

## 2. Contenu du paquet

| Chemin | Rôle |
|---|---|
| `game/assets/bd/sprites/{batiments,personnes,animaux,portraits,decor,objets}/*.png` | 283 sprites détourés, recadrés au plus juste |
| `game/assets/bd/sprites_bd.json` | Manifeste : `nom → {fichier, categorie, taille, pied}` (pied = point posé au sol, en px du PNG) |
| `game/assets/bd/decor/*.png` + `decor_bd.json` | 77 éléments de décor dessinés (feuillus ×5 essences, pins, sapins, bouleaux, saules, acacias, baobabs, buissons, rochers, filons d'or, pics, roseaux, herbes, fougères, termitières, souches, rondins, tentes, feu). Échelle : `px_par_case = 120` |
| `game/assets/bd/textures/*_details.png` | Textures de détail **raccordables** (4×4 cases, 512 px, fond transparent) : herbe, sable, roche, eau, falaise |
| `game/assets/bd/polices/` | Barlow 500/700/800, Barlow Condensed 700/800 (latin + latin étendu), licence OFL |
| `game/scripts/rendu/carte_bd.gd` | `CarteBD` : nœud qui rend toute la carte (sol + routes + décor), surveille seul les changements |
| `game/scripts/rendu/sol_bd.gdshader` | Shader du sol (masques 1 texel = 1 case, bords organiques, encre à épaisseur constante, falaises, berges) |
| `game/scripts/rendu/routes_bd.gd` | `RoutesBD` : chemins continus (diagonales comprises) et ponts en planches |
| `game/scripts/rendu/decor_bd.gd` | `DecorBD` : sprites de décor triés en Y, placement déterministe par case |
| `game/scripts/rendu/sprites_bd.gd` | `SpritesBD` : chargement des sprites, tables métier/bâtiment/animal → sprite, dessin dans `_draw()`, clôtures en perspective |
| `game/tests/capture_bd.gd` | Capture de contrôle (vue normale ou zoomée) |
| `docs/handoff_bd/patch_main_reference.diff` | Branchement dans `main.gd` tel que testé sur `490dfe0` |
| `docs/handoff_bd/captures/` | `cible_*.png` (maquettes), `resultat_jeu*.png` (obtenu dans Godot), `planche_tous_les_sprites.png` (tous les noms) |
| `docs/handoff_bd/godot/ui_tokens_neo.gd` | Jetons + thème de l'interface C (étape 2) — **même API** que `scripts/ui_tokens.gd` |
| `docs/handoff_bd/generateurs/` | Scripts Python qui ont produit décor, textures et sprites + planches sources (pour régénérer) |

## 3. Étape 1 — la carte et le monde (à faire en premier)

### 3.1 Copier les fichiers
Copier `game/assets/bd/`, `game/scripts/rendu/`, `game/tests/capture_bd.gd` dans le projet. Ouvrir l'éditeur une fois (ou `godot --headless --path game --import`) pour importer ~370 images.

### 3.2 Brancher dans `main.gd` (5 points)
1. **Créer la carte** à l'endroit où le terrain est construit aujourd'hui (fonction qui crée l'`Image`/`Sprite2D` du terrain) :
   ```gdscript
   var carte: CarteBD
   # ...
   carte = CarteBD.new()
   add_child(carte)
   move_child(carte, 0)                       # derrière tout le reste
   carte.construire(game.map, TILE, game.seed_value)
   ```
   `CarteBD` a `show_behind_parent = true` : tout ce que `main.gd` dessine dans `_draw()` (bâtiments, ouvriers, sélection, aperçus) reste **au-dessus** du décor. Supprimer (ou ne plus appeler) l'ancien rendu du terrain.
2. **Rafraîchissement** : rien à faire. `CarteBD._process()` compare `map.tiles`, `map.road`, `map.bridge` à sa copie et ne redessine que les cases changées (forêt abattue, roche épuisée, aménagement, route, pont). L'ancien `_refresh_terrain()` peut se contenter de vider `game.terrain_changed`.
3. **Changement de joueur affiché** (mode spectateur) : `carte.construire(game.map, TILE, game.seed_value)`.
4. **Ne plus dessiner** routes et ponts dans `_draw()` (c'est `RoutesBD`), ni les rectangles des gisements d'or (c'est le décor `rocher_or`).
5. **Remplacer les formes par les sprites** dans `_draw()` (voir le patch) :
   - bâtiment terminé : `SpritesBD.dessiner_largeur(self, SpritesBD.BATIMENTS[id], Vector2(r.get_center().x, r.end.y), r.size.x * SpritesBD.LARGEUR_BATIMENT)` ; repli sur l'ancien rectangle si l'id n'a pas de sprite ;
   - chantier (sauf clôtures/routes/ponts) : sprite `chantier1`/`chantier2` + barre de progression existante ;
   - clôtures : `SpritesBD.cloture(self, centre, dirs, "pierre" | "bois", TILE)` avec `centre = (case + (0.5, 0.8)) * TILE` et `dirs` = voisins du même type terminés ;
   - ouvriers : `SpritesBD.dessiner(self, SpritesBD.pour_metier(metier_id), pied, TILE * SpritesBD.HAUTEUR_PERSONNE, miroir)`, avec un anneau couleur du joueur au sol et un **badge catégorie couleur + forme** (› » ★) ; garder pastilles d'état, barre de charge et « 25 % » ;
   - visiteurs : `SpritesBD.visiteur(indice)` à `0.9–0.95 × TILE` ;
   - animaux : `SpritesBD.ANIMAUX[espece] = [sprite, hauteur_en_cases, tête]` ; garder l'étiquette ;
   - camp : `SpritesBD.dessiner_largeur(self, "camp3", bas_centre_du_camp, largeur_camp * 1.1)` ;
   - trier les bâtiments par `rect.end.y` avant de les dessiner.

### 3.3 Vérifier
```
godot --path game --script res://tests/capture_bd.gd -- --seed=4242 --autodraft --autoplay --sim=240 --autozoo --sortie=/tmp/vue.png
godot --path game --script res://tests/capture_bd.gd -- --seed=4242 --autodraft --autoplay --sim=240 --autozoo --zoom=3.2 --sortie=/tmp/zoom.png
godot --headless --path game --script res://tests/sim_test.gd          # la logique ne doit pas bouger
```
Comparer à `captures/resultat_jeu.png` et `resultat_jeu_zoom.png`. (Si `--autoplay`/`--autozoo` n'existent plus, lancer une partie et utiliser la capture du jeu.)

**Critères d'acceptation**
- [ ] Le sol ressemble à `cible_carte.png` : bords de terrains arrondis et cernés d'encre, prairie détaillée, eau en paliers avec berge au nord et écume, montagnes sur plateau à falaise, sable et rocaille texturés.
- [ ] Forêts denses d'essences variées, pics sur les montagnes, roseaux au bord de l'eau, filons d'or dessinés.
- [ ] Abattre une forêt / épuiser une roche / construire une route ou un pont met la carte à jour **sans action** de `main.gd`.
- [ ] Chemins continus, y compris en diagonale ; ponts en planches avec garde-corps.
- [ ] Bâtiments, chantiers, camp, ouvriers (par métier), visiteurs et animaux en sprites ; enceinte de pierre et clôtures d'enclos en perspective.
- [ ] Badge de catégorie visible au-dessus de chaque ouvrier (couleur + forme), sélection et pastilles d'état inchangées.
- [ ] 60 i/s sur une carte 64×64 (≈ 3 500 sprites de décor). Sinon : voir §5.
- [ ] `sim_test.gd` passe ; aucun changement de règles.

## 4. API des modules

**CarteBD** (`Node2D`) — `construire(map, taille_case, graine := 0)`, `rafraichir(cases: Array)` (facultatif), enfants `Sol` (Sprite2D + shader), `Routes` (RoutesBD), `Decor` (DecorBD).
Masques envoyés au shader : `masque_a` = R eau, G forêt, B roche, A sable ; `masque_b` = R montagne, G or (B et A libres) ; `masque_c` = R profondeur d'eau (distance à la rive / 4).
Réglages du shader (`sol.material.set_shader_parameter`) : `hauteur_falaise` (0.55 case, **à garder égal** à `DecorBD.HAUTEUR_FALAISE`), `decalage_eau` (0.22), `epaisseur_encre` (1.25 px écran), couleurs en constantes en tête du shader.

**DecorBD** (`Node2D`, `y_sort_enabled`) — mélanges par terrain en constantes (`FORET`, `PRAIRIE_RARE`, `SABLE`, `ROCHE`) ; une « famille » = tous les fichiers `famille_N` de `decor/`. Placement déterministe `hash(x, y, graine)`. Densités dans `_peupler()`.

**RoutesBD** (`Node2D`) — trace les segments entre cases de route/pont voisines (4-voisinage, diagonale si pas de lien orthogonal).

**SpritesBD** (statique) — `texture(nom)`, `existe(nom)`, `pied(nom)`, `dessiner(ci, nom, pied_monde, hauteur, miroir, teinte)`, `dessiner_largeur(...)`, `cloture(ci, centre, dirs, type, tile)`, `pour_metier(id)`, `visiteur(i)`, `portrait(cle)` (42 portraits, pour les cartes d'ouvrier). Tables `BATIMENTS`, `METIERS`, `ANIMAUX`, `VISITEURS` : **compléter ici** quand un bâtiment, un métier ou une espèce est ajouté (noms disponibles : `captures/planche_tous_les_sprites.png`).
Bâtiments déjà dessinés sans id de jeu : `marche`, `interim`, `restaurant`, `snack`, `atelier`, `mairie`, `scene`, `abri`, `bassin`, `entree2`, `camp1`, `camp2`.

## 5. Points d'attention

- **Ordre d'affichage** : le décor (arbres) est toujours **sous** ce que dessine `_draw()` ; les ouvriers restent donc visibles en forêt. C'est voulu (lisibilité).
- **Perspective** : le dessus d'un plateau de montagne est dessiné 0,55 case plus haut que sa case ; il recouvre visuellement le bas de la case au nord. Les montagnes étant infranchissables, aucune règle n'est touchée ; l'infobulle de case reste celle de la grille.
- **Performances** : ~3 500 `Sprite2D` (batchés par texture). Si besoin : passer les familles nombreuses (feuillus, pins) en `MultiMeshInstance2D` par texture, en gardant le tri Y par rangée.
- **Polices** : `.woff2` importées nativement par Godot 4 ; le fichier « latin-ext » sert de repli pour œ, ’, − (déjà câblé dans `ui_tokens_neo.gd`).
- **Sprites imparfaits** (détourage de planches générées) : `chevre` a des trous blancs, `yak` ressemble à un mouton, quelques `portrait_NN` gardent un liseré du voisin, `tigre_duo`/`jaguar_duo`/`elephant_famille`/`chimpanzes` contiennent deux animaux. À redemander à l'auteur sur fond uni si gênant ; ne pas les retoucher au hasard.
- **Valeurs du jeu** : aucune donnée de `data/*.json` n'est modifiée.

## 6. Étape 2 — l'interface « Néo ligne claire » (après validation de l'étape 1)

Cible : `captures/cible_interface.png`. `docs/handoff_bd/godot/ui_tokens_neo.gd` remplace `scripts/ui_tokens.gd` (**mêmes noms de constantes et de fonctions** + `ENCRE`, `PAPIER`, `PAPIER_2`, `ENTETE_FORT`, `MARINE`, `TEXTE_CLAIR`, `POSITIF`, `NEGATIF`, `police(graisse, condensee)`, variation `TitreBD`).

**Attention, test fait** : remplacer seulement le fichier ne suffit pas. L'interface de `main.gd` crée ses propres styles et couleurs (cartes de main sombres, barre du haut, BBCode `[color=#…]`) → texte clair sur fond blanc. Procédure :
1. Appliquer `UiTokens.build_theme()` sur la **racine de toute l'interface en jeu** (pas seulement le menu).
2. Chercher les couleurs codées en dur : `grep -nE 'Color\("|color=#|Color\(1, 1, 1|Color.WHITE' game/scripts/main.gd` et les remplacer par des jetons : texte clair → `UiTokens.TEXTE`, gris → `TEXTE_SECONDAIRE`, vert « positif » `#7fc97f` → `POSITIF` (toujours avec signe/flèche), rouge `#f08080` → `NEGATIF`, or `#e9b949` → `SELECTION` ou `ENTETE_FORT` selon le contraste. Les étiquettes **dessinées sur la carte** (`_label`) gardent blanc + contour sombre.
3. Composants selon la maquette : barre du haut en **pastilles blanches flottantes** (ressources avec icônes `icone_bois`, `icone_pierre`, `icone_pieces`, `icone_or`, `icone_etoile`…), panneau « Construire » avec vignettes de bâtiments (sprites), cartes de main blanches 146×216 avec portrait (`SpritesBD.portrait(card.id)` sur fond `CATEGORIES[cat].portrait`), badge catégorie, pièce de salaire jaune, bouton « Déployer » jaune ; panneau ouvrier avec ordres en grille d'icônes ; cadran du jour segmenté ; bouton « Terminer la journée » orange `#F07F2A` en capitales condensées.
4. Titres de panneaux : Barlow Condensed 800, **capitales**, sur bandeau `ENTETE_FORT` texte blanc, ou `ENTETE` texte encre.
5. Contraste ≥ 4,5:1 partout (encre sur blanc, blanc sur sarcelle `#13867F`, encre sur jaune).

## 7. Régénérer ou étendre les assets
`docs/handoff_bd/generateurs/` (Python 3, `numpy scipy scikit-image pillow playwright` + Chromium) :
- `export_sprites.py` découpe `planches/*.png` (déjà détourées) → `sprites/` + manifeste ; tables de noms par indice en tête.
- `export_decor.py` dessine les éléments de décor (fonctions de `persp.py`) → `decor/` + `decor_bd.json`.
- `export_textures.py` → textures raccordables.
- `persp.py`, `monde.py`, `carte.py` : générateurs des maquettes (référence visuelle).
Nouvelle planche de l'auteur : la détourer comme les autres (fond gris uni retiré), ajouter ses boîtes et noms dans `export_sprites.py`, relancer, puis compléter les tables de `SpritesBD`.

## 8. À ne pas faire
- Ne pas modifier la logique (`game_state.gd`, `match.gd`, `ai_controller.gd`) ni les JSON d'équilibrage.
- Ne pas renommer les sprites (le manifeste et les tables en dépendent).
- Ne pas remplacer `ui_tokens.gd` par la version Néo avant l'étape 2 complète.
- Ne pas peindre le terrain dans une `Image` pixel par pixel : le shader fait tout.
