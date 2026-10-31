# Handoff — Zoo Deckbuilder, thème Émeraude

1. Lire `HANDOFF.md` (spécification complète).
2. Ouvrir les `captures/` : ce sont les références visuelles à reproduire.
3. Les valeurs exactes sont dans `tokens.json` ; les départs de code Godot dans `godot/` (non testés).

## Prompt suggéré pour Claude Code

Copier ce dossier à la racine du projet Godot (par exemple `docs/handoff_emeraude/`), puis :

> Lis `docs/handoff_emeraude/HANDOFF.md`, `tokens.json` et regarde les images de `captures/`.
> Implémente le jalon 1 puis le jalon 2 du §12 dans ce projet Godot : polices, import des icônes de `icones/` dans `res://ui/icones/`, `UiTokens`, génération du thème avec `godot/construire_theme.gd`, puis les composants CarteOuvrier (3 tailles, 6 états), CarteContrat, JetonRessource, BoutonOrdre et MedaillonJour.
> Construis une scène `res://ui/galerie_composants.tscn` qui reproduit `captures/07_composants_cartes.png`, fais-en une capture à 1600×900 et compare-la à la référence.
> Respecte le double codage couleur + forme (qualité = cercle bleu « + », défaut = carré orange « − ») et tout le texte en français. Signale toute valeur factice plutôt que de l'inventer.

Enchaîner ensuite jalon par jalon (3 → 8), avec une capture de contrôle à chaque fois.
