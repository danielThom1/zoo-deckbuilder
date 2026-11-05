# Sources des maquettes

Chaque `*.dc.html` est une maquette du canevas validé, au format « Design Component » : un gabarit HTML avec des trous `{{…}}`, `<sc-for>`, `<sc-if>` et `<dc-import>` pour les briques (`Ticker`, `Dock`, `Agenda`). `support.js` est un petit moteur de rendu local écrit pour ce paquet.

Pour voir une maquette :
```
cd docs/handoff_comite/sources
python -m http.server 8765
# puis ouvrir http://localhost:8765/C1_Debut_A.dc.html (ou un autre fichier)
```
Les images sont dans `_blob/` (nom = identifiant d'origine, voir `_blob/correspondance.json`), et les polices dans `fonts/` (OFL).

Correspondance avec les PNG de `../maquettes/` :
C1_Debut_A → 01, C2_Selection_A → 02, C3_Enclos_A → 03, C4_Marche_Contrats/Collab/Cartes → 04a/b/c, C_Nuit → 05, C5_Collab_B → 06, C6_Cartes_A → 07, C7_Bonus_B → 08a, C7_Bonus_Vous → 08b, C8_Equipe_A → 09, C9_Menu_A → 10, C10_Fin_Victoire / C10_Fin_Defaite → 11a/b, Feuille_de_style → 90, Briques → 91, Ticker → 92, Dock → 93, Agenda → 94.
