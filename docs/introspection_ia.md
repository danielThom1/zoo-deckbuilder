# Introspection de l'IA en jeu (11/11/2026)

Constat de départ : un joueur humain gagne vers le jour 9 ou 10 (une fois au jour 8) contre les IA difficiles, qui gagnent plutôt vers le jour 12. Mesures faites avec `tests/mesure_ia.gd` (8 parties à 4 IA difficiles, `ia_niveaux.json` du 09/11).

## Comment l'IA joue aujourd'hui

`scripts/ai_controller.gd` (3 200 lignes, 160 fonctions) est une IA à règles, sans planification :
- **Toutes les 2 s** (`THINK_EVERY`), elle refait une liste de souhaits de chantiers par ordre de priorité (`_wants` : route, mine, enceinte, enclos, bâtiments), pose ce qu'elle peut payer, poste les collaborateurs (`_staff_posts`) et donne une tâche à chaque inactif (`_assign` : chantier le plus proche selon une note, sinon récolte de ce qui manque).
- **Toutes les 30 s**, elle répartit l'équipe entre bâtisseurs et récolteurs (`_repartir`).
- **La nuit**, elle note chaque contrat (réputation attendue d'ici la fin moins le travail) et achète le meilleur ; embauches et cartes par règles.
- **En fin de partie**, depuis le 07/11, elle compare quelques dépenses par rentabilité (`_rendements`).
- Les réglages de stratégie (taille du parc, rush or, camp, etc.) viennent de l'étude (`ia_niveaux.json`).

## Ce que montrent les mesures

| Mesure (moyenne de 32 IA) | Valeur | Commentaire |
|---|---|---|
| Temps passé à marcher | **33 %** | Un tiers de la journée de chaque collaborateur part en trajets. |
| Temps à travailler | 62 % | |
| Inactifs | 0 % | Personne n'attend : le problème n'est pas l'oisiveté mais l'efficacité. |
| Jour d'ouverture du zoo | **5,8** (4 à 8) | Le zoo ouvre le jour où le premier animal arrive. Un joueur ouvre vers le jour 3. |
| Allers-retours en moins d'une minute | 15 à 250 par partie | Corrigé (voir ci-dessous) : 10 à 15 restants. |

## Causes trouvées, par ordre d'importance

1. **Les IA difficiles bâtissent toutes un grand parc.** Les 4 stratégies apprises du niveau difficile ont `taille_zoo: grand` (22 × 16, 72 cases de mur contre 40 pour un petit parc). Il faut environ deux fois plus de pierre et de marche avant d'ouvrir. L'étude les a sélectionnées parce qu'elles battent les autres IA, toutes lentes, sur la durée. Face à un joueur qui ouvre au jour 3, ce démarrage lent coûte la partie. **C'est sans doute la cause principale.**
2. **Un tiers du temps en marche.** Chaque matin, tout le monde repart du camp ; les récolteurs font des allers-retours camp ↔ ressource ; l'entrepôt près des récoltes vient tard (ex. le jour 4 près de la mine).
3. **Hésitations** (votre capture pj5) : un collaborateur posté au nettoyage était libéré pour les chantiers puis reposté au tour suivant, jusqu'à 250 fois par partie. **Corrigé** : il n'est libéré que si le parc est presque propre (85 %).
4. **Aucune planification de la journée** : l'IA décide toutes les 2 s, au plus près. D'où les traversées de carte en fin de journée et les trajets vers un chantier déjà presque fini (corrigés le 11/11), et l'absence d'anticipation (poser l'entrepôt avant d'en avoir besoin, regrouper les chantiers proches).
5. **Le premier contrat arrive tard.** L'enceinte doit être fermée avant toute installation ; l'IA achète son premier animal quand les murs sont à 60 %, puis bâtit l'enclos ensuite. Un joueur prépare l'enclos pendant que l'enceinte se ferme.

## Pistes d'amélioration, par effet attendu

| Piste | Effet attendu | Effort |
|---|---|---|
| **A. Démarrage rapide** : premier parc petit ou moyen pour toutes les IA, agrandi ensuite (l'agrandissement existe déjà) ; enclos prévu en même temps que les murs ; premier contrat acheté dès la nuit 1 si son motif est déjà dans le parc. | Ouverture vers le jour 3 ou 4 au lieu de 5,8 : plusieurs jours de réputation gagnés. | Moyen |
| **B. Étude contre un adversaire rapide** : ajouter à l'étude une stratégie écrite « ouverture éclair » comme adversaire fixe, pour que les stratégies apprises soient jugées contre un rythme humain. | Les niveaux d'IA cessent de sélectionner les démarrages lents. | Faible |
| **C. Moins de marche** : entrepôt posé dès qu'une zone de récolte est loin (anticipé), récolteurs envoyés vers la ressource la plus proche du dépôt, bâtisseurs qui enchaînent les chantiers voisins. | De 33 % de marche à environ 25 % : environ 10 % de travail en plus. | Moyen |
| **D. Plan de journée** : chaque matin, une liste ordonnée de chantiers pour la journée et un bâtisseur affecté à chacun, révisée seulement si un chantier finit ou bloque. | Moins d'hésitations, de trajets inutiles et de chantiers oubliés. | Élevé |
| **E. Règles de fin de partie** : s'appuyer davantage sur `_rendements` (Bureau des acquisitions plus tôt, campagnes, Portes ouvertes au bon moment). | Quelques points par partie. | Faible |

Recommandation : **A puis B**, qui s'attaquent à la cause principale (démarrage lent), puis **C**. Mesurer chaque étape avec `tests/mesure_ia.gd` (jour d'ouverture, part de marche) et une étude courte.
