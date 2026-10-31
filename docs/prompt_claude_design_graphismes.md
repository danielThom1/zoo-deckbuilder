# Prompt pour Claude Design : jeu complet d'images 2D pour « Zoo Deckbuilder »

Copiez tout le texte du bloc ci-dessous dans Claude Design. Les images qu'il produit seront intégrées dans le jeu Godot.
Le prompt demande des fichiers séparés, nommés et cotés, faute de quoi l'intégration devient du découpage à la main.

```
Tu réalises la direction artistique et les images 2D d'un jeu vidéo de gestion, « Zoo Deckbuilder »
(Godot 4, vue de dessus). Le joueur recrute des ouvriers (cartes), récolte bois, pierre et or, construit
une enceinte, des enclos et des bâtiments, puis installe des animaux pour attirer des visiteurs.

STYLE
- Charte « Émeraude » déjà en place dans l'interface : verts émeraude profonds (#0D433D, #1C7468),
  or chaud (#E2AE62), crème (#F4FAEE). Le monde est lumineux et chaleureux : herbe #62AE34 à #8DC94A,
  sable #F2D684, eau turquoise à bleu profond (#46CCD0 → #1E6BC4), roche #A8A296.
- Illustration lisible et douce, contours d'encre fins (1 px à l'échelle 1, couleur #2A1E14 à 80 %),
  aplats avec un léger dégradé, lumière venant d'en haut à gauche, ombres portées vers le bas à droite.
- Vue de dessus légèrement plongeante (on voit le toit et un peu de la façade sud des bâtiments).
- Tout doit rester lisible quand on dézoome : silhouettes nettes, pas de détails de moins de 2 px.

FORMAT TECHNIQUE (impératif)
- Grille de jeu : 1 case = 32 × 32 px à l'échelle 1. Livrer chaque image à l'échelle 2 (64 px par case).
- SVG de préférence (sinon PNG 32 bits), fond transparent, un fichier par élément.
- L'emprise au sol d'un bâtiment occupe exactement sa taille en cases ; l'image peut dépasser
  vers le HAUT de 14 px (échelle 1) pour le volume (toit, cheminée, drapeau). Rien ne dépasse sur les côtés ni en bas.
- Ombre portée incluse dans l'image, à 25 % de noir, décalée de 3 px vers le bas à droite.
- Animations : planches horizontales (sprite sheets), images de même taille côte à côte, 4 images par
  animation sauf mention contraire. Nommer les fichiers en minuscules, sans accent, avec des underscores.
- Fournir aussi une planche de contrôle (toutes les images sur un fond d'herbe, à l'échelle 1).

À PRODUIRE

1. Bâtiments (taille en cases largeur × hauteur, nom de fichier)
   maison 2×2, entrepot 2×2, comptoir (marché couvert) 2×2, agence (agence d'intérim) 2×2,
   mine (entrée de mine d'or avec étais en bois) 2×2, boutique (souvenirs) 2×2, cuisine (des animaux) 2×2,
   entretien (local, balais et seaux) 2×2, snack 2×2, kiosque (d'animation, petite scène) 2×2,
   formation (centre de formation, style école) 3×2, entree (portique d'entrée du zoo) 2×1 ET entree_v 1×2
   (la même entrée tournée d'un quart de tour), mairie (petite mairie de ville, drapeau violet) 3×2,
   camp_1, camp_2, camp_3 (camp de base de 3×3 : 2 tentes et un feu, puis 3 tentes et une palissade,
   puis 4 tentes, palissade et mât), chantier_2x2 et chantier_3x2 (échafaudage, planches, sacs : un
   bâtiment en construction, posé par-dessus l'emprise).

2. Aménagements d'enclos (1×1) : grand_arbre, rocher_obs (rocher d'observation plat), bassin_profond
   (bassin bordé de pierres), abri_chaud (petite cabane chauffée).

3. Clôtures en pièces assemblables (1×1 chacune, vues de dessus, raccords au milieu des bords)
   - mur_ : mur d'enceinte en pierre claire. Pièces : droit_h, droit_v, angle_ne, angle_no, angle_se,
     angle_so, t_n, t_s, t_e, t_o, croix, bout_n, bout_s, bout_e, bout_o, pilier_seul.
   - palissade_ : palissade d'enclos en bois (deux lisses et des poteaux ronds), mêmes pièces.
   - Une version « en chantier » de chaque famille : poteaux plantés et lisses en pointillé (chantier_mur_*, chantier_palissade_*), ou une seule superposition générique par famille.

4. Routes en pièces assemblables (1×1) : chemin_ (terre battue) et allee_ (dalles claires, à
   l'intérieur du zoo), avec les 16 combinaisons de raccords : isole, bout_n/s/e/o, droit_h, droit_v,
   angle_ne/no/se/so, t_n/s/e/o, croix. Plus pont_h et pont_v (planches sur l'eau).

5. Ressources de la carte (objets posés sur le sol, le sol lui-même reste généré par le jeu)
   - arbres : feuillu_1 à feuillu_4 et sapin_1 à sapin_3 (couronne de 0,8 case, vue de dessus).
   - rochers : rocher_1 à rocher_4 (blocs gris à facettes, 0,4 à 0,6 case).
   - or : filon_1 et filon_2 (rochers veinés d'or), plus scintillement (4 images, petite étoile).
   - montagne_1 à montagne_3 : massifs de 1 case de base qui montent de 1,5 case (2 ou 3 pics enneigés).
   - souche (arbre coupé) et trou (roche épuisée), 1×1.

6. Personnages ouvriers (32 × 40 px à l'échelle 1, pieds au bas de l'image)
   - Un corps neutre en calques à recolorer par le jeu : peau, vêtement principal, vêtement secondaire,
     cheveux (6 coiffures : court, long, afro, chignon, rasé, tresses), chapeaux (casque de chantier,
     chapeau de paille, bonnet, casquette, voile).
   - Animations par direction (face, dos, profil) : marche (4 images), et travail (4 images) avec
     chaque outil : hache, pioche, marteau, pelle, balai, seau. Le profil sera retourné par le jeu.
   - Inactif : assis ou appuyé, 2 images.

7. Visiteurs (16 × 24 px) : adulte et enfant, 3 tenues, marche face et dos (4 images).

8. Animaux (vue de profil, tournés vers la droite, 2 images de marche + 1 au repos) pour les 38 espèces :
   zebre, gazelle, autruche, girafe, lion, elephant, rhinoceros, vautour, cerf, renard, sanglier,
   loup, ours_brun, lynx, perroquet, capucin, tapir, jaguar, tigre, gorille, toucan, flamant, loutre,
   manchot, phoque, hippopotame, crocodile, chevre, marmotte, panda_roux, yak, aigle_royal,
   panthere_neiges, suricate, fennec, dromadaire, addax, dragon_komodo.
   Hauteur selon la taille réelle : petits animaux 0,6 case, moyens 1 case, grands 1,6 case (girafe 2 cases).

9. Effets (petites planches de 4 images) : copeaux de bois, poussière de pierre, éclats d'or, cœurs
   (soins), pièces (vente), étoiles (formation), « zzz » (ouvrier inactif), fumée de cheminée.

Commence par une planche de style avec 1 bâtiment (maison), 1 pièce de mur et de palissade,
1 arbre, 1 rocher, 1 ouvrier de face et 1 animal (zèbre), pour validation avant la série complète.
```

## Ce que le jeu fera de ces images

- Bâtiments et aménagements : remplacent les dessins actuels (`_draw_building_image`, `_draw_decor`).
- Clôtures et routes : chaque case choisit sa pièce selon ses voisines (la logique de raccord existe déjà).
- Arbres, rochers, or, montagnes : posés par-dessus le sol du shader, à la place des formes dessinées par le shader.
- Ouvriers et visiteurs : les planches remplacent `PersoDessin`. Les couleurs de peau, de vêtement et de cheveux de chaque personnage sont appliquées aux calques.
- Animaux : remplacent les illustrations au trait (`ui/animaux/`).
