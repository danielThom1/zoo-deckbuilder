# Paquet d'intégration — style BD néo ligne claire

**Installation** : copier le contenu de ce paquet à la racine du dépôt `zoo-deckbuilder` (les dossiers `game/` et `docs/` se fusionnent avec les existants ; aucun fichier existant n'est écrasé, sauf `CLAUDE.md`, mis à jour).

## Prompt à donner à Claude Code

> Lis `CLAUDE.md` puis `docs/handoff_bd/HANDOFF_BD.md` et regarde les images de `docs/handoff_bd/captures/`.
> Réalise l'**étape 1** (§3) : branche `CarteBD` et `SpritesBD` dans `game/scripts/main.gd` en t'inspirant de `docs/handoff_bd/patch_main_reference.diff` (écrit sur une version plus ancienne de `main.gd` : adapte-le au code actuel), supprime l'ancien rendu du terrain, des routes et des ponts, et remplace les formes des bâtiments, chantiers, clôtures, ouvriers, visiteurs, animaux et du camp par les sprites.
> Lance `tests/capture_bd.gd` (vue normale et `--zoom=3.2`) et `tests/sim_test.gd`, compare tes captures à `resultat_jeu.png` / `resultat_jeu_zoom.png`, coche les critères d'acceptation du §3.3 et corrige les écarts.
> Ne touche pas aux règles ni aux JSON. Fais un commit à la fin de l'étape 1.
> Ensuite seulement, réalise l'**étape 2** (§6, interface Néo ligne claire) avec `cible_interface.png` comme référence, puis un second commit.
