# Paquet d'intégration : interface « Le Comité »

Contenu :
- `HANDOFF_COMITE.md` : la spécification, écran par écran, avec ce qui est déjà fait et ce qui reste.
- `maquettes/` : les cibles PNG à 1600 × 900 (écrans retenus, feuille de style, briques).
- `sources/` : le source HTML de chaque maquette, pour lire les cotes exactes. Lancer `python -m http.server 8765` dans ce dossier pour les voir rendues.
- `etat_actuel/` : des captures du jeu après le premier commit (écran de jour Comité ; la nuit est encore à l'ancien style).

## Prompt à donner à Claude Code

> Lis `CLAUDE.md`, puis `docs/handoff_comite/HANDOFF_COMITE.md`. Regarde les images de `docs/handoff_comite/maquettes/` et de `docs/handoff_comite/etat_actuel/`.
> Les fondations et l'écran de jour sont déjà faits (§0). Réalise le §2 dans l'ordre du §4, avec un commit par jalon : nuit, marché du soir, fin de partie, menu, pose d'enclos, fiche de sélection, compléments du jour, puis les écrans de priorité 2 (§3).
> Pour chaque écran, lis la maquette PNG et son source dans `sources/` pour les cotes exactes. Fais une capture du jeu avec les commandes du §5, compare-la à la maquette et corrige les écarts. Vérifie aussi à 1280 × 720.
> Ne modifie ni les règles, ni l'IA, ni les JSON. Lance `sim_test`, `replay_test` et le tutoriel automatique après chaque jalon. Mets à jour `CLAUDE.md` à la fin.
