# Zoo Deckbuilder (prototype)

Jeu de gestion vu du dessus qui mélange **deckbuilding d'ouvriers** et **construction d'un zoo**. Prototype jouable sous **Godot 4.7.2**, contre 1 à 3 IA.

## Lancer le jeu
1. Télécharger Godot 4.7.2 (version standard, pas .NET) sur https://godotengine.org/download/archive/4.7.2-stable/
2. Godot → **Importer** → `game/project.godot`
3. **F5** : menu principal (« Jouer contre 3 IA » ou « Regarder 4 IA jouer »)

## Contenu
| Chemin | Rôle |
|---|---|
| `GDD.md` | Document de conception (règles à jour) |
| `game/data/*.json` | Toutes les valeurs d'équilibrage (animaux, ouvriers, bâtiments, événements) |
| `game/scripts/match.gd` | Partie : horloge, draft, marché, événements, bonus de nuit |
| `game/scripts/game_state.gd` | État et simulation d'un joueur (ouvriers, chantiers, visiteurs…) |
| `game/scripts/ai_controller.gd` | IA (mêmes actions qu'un joueur) |
| `game/scripts/main.gd` | Affichage, interface et commandes |
| `game/tests/sim_test.gd` | Tests automatiques |
| `game/tests/balance_sim.gd` | Parties IA contre IA → `rapport_equilibrage.md` |
| `prototype/` | Tout premier prototype navigateur (archivé) |
| `prompt_claude_design.md` | Prompt de direction artistique |

## Tests et simulations
```
godot --headless --path game --script res://tests/sim_test.gd
godot --headless --path game --script res://tests/balance_sim.gd -- --parties=32 --dt=1.0
```
