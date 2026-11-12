# Paquet : menu principal, statistiques, défis

- `NOTES.md` : choix de conception, ce qui change par rapport à l'état actuel, nouvelles briques et cotes, écran par écran.
- `maquettes/` : les PNG à 1600 × 900 ; `maquettes/1280/` : les mêmes à 1280 × 720 (mise à l'échelle 0,8, comme le jeu).
- `sources/` : le HTML de chaque maquette (cotes en px), `commun.css` (jetons et briques), les polices et les images.
  Pour les voir : ouvrir directement un fichier `.html` dans un navigateur.
- `sources/_generateurs/` : les scripts qui produisent le HTML et les PNG (`python gen_menu.py`, `gen_stats.py`, `gen_defis.py`, puis `node rendre.js . sortie`).

## Prompt à donner à Claude Code

> Lis `CLAUDE.md`, puis `docs/handoff_menus/NOTES.md`. Regarde les PNG de `docs/handoff_menus/maquettes/` et compare-les aux captures de `docs/handoff_menus/etat_actuel/`.
> Implémente, dans l'ordre et avec un commit par jalon :
> 1. le menu principal, variante A (fichiers `10A*`) : sommaire en chapitres, fiche de mode qui s'adapte au mode choisi et sa languette, bloc « Dossier en cours », note de service du défi de la semaine, pied avec Statistiques, Réglages et Quitter ;
> 2. la page Défis (`30` à `34`) avec ses 5 états. Le masquage des pseudos hors du top 10 se fait côté serveur (voir NOTES.md § 3) ;
> 3. la page Statistiques (`20` à `24`) avec ses 4 onglets et l'état de premier lancement.
> Pour chaque écran, lis le source HTML dans `sources/` pour les cotes exactes. Ajoute les nouvelles briques à `Composants` et aux jetons existants. Fais une capture du jeu, compare-la à la maquette et corrige les écarts. Vérifie aussi à 1280 × 720.
> Ne modifie ni les règles, ni l'IA, ni les JSON de `data/`. Lance `sim_test`, `replay_test` et le tutoriel automatique après chaque jalon. Mets à jour `CLAUDE.md` à la fin.
