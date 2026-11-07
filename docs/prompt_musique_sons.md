# Textes pour les générateurs de son : musiques et bruitages de ZooLife

Aujourd'hui, tout le son du jeu est synthétisé par `tools/audio.py` (3 musiques, 17 bruitages). Ce fichier donne un texte par morceau et par bruitage pour les remplacer par des sons générés par IA.

## Quels outils

- **Musiques** : Suno ou Udio, en mode **instrumental** (pas de paroles). Collez le texte dans le champ « style » ou « description ».
- **Bruitages** : ElevenLabs Sound Effects (ou Stable Audio). Réglez la durée indiquée ; pour une ambiance en boucle, cochez l'option « loop » si elle existe.
- **Licence** : l'usage commercial demande en général un abonnement payant **au moment de la génération** (Suno Pro ou Premier, ElevenLabs payant). Vérifiez les conditions de chaque site avant de publier le jeu.

## Rendre les fichiers

- Format **.ogg** de préférence (sinon .mp3 ou .wav). Nom de fichier : celui indiqué entre parenthèses, en minuscules.
- Déposez-les dans un même dossier et prévenez Claude : il coupe les silences, règle les volumes, fait boucler proprement les musiques (fondu de raccord) et les range dans `game/assets/audio/`. Le jeu préfère le .ogg au .wav du même nom, et les anciens sons restent en secours.
- **Variantes** : pour un bruitage joué souvent (chantier, pièce, carte), générez 2 ou 3 versions et nommez-les `chantier`, `chantier_2`, `chantier_3` : le jeu en tire une au hasard, l'oreille se lasse moins vite.
- Générez 3 ou 4 essais par texte et gardez le meilleur : la qualité varie beaucoup d'un essai à l'autre.

## Le ton

Satire d'entreprise douce, bande dessinée, zoo. Tout doit rester léger, un peu kitsch, jamais angoissant. Les musiques passent des heures en fond : pas de mélodie trop insistante, pas de chant, pas de batterie lourde.

---

## 1. Musiques (Suno ou Udio, instrumental)

Durée visée : 2 à 3 minutes, sans fin marquée (elles bouclent). Si l'outil ajoute une fin en fondu, ce n'est pas grave, Claude la coupera.

### Menu principal (`musique_menu`)

```text
Instrumental, corporate elevator music parody, cheerful and slightly cheesy, bossa nova groove, soft electric piano, muted trumpet, vibraphone, light shaker, a catchy 4-note jingle motif like a company logo theme, warm and polished like a 1990s corporate training video, gentle tempo 100 bpm, no vocals, seamless loop, no big ending
```

### Journée au zoo (`musique_jour`)

```text
Instrumental, light playful adventure music for a cozy zoo management game, ukulele and marimba lead, pizzicato strings, a whistled melody, soft hand percussion and bongos, bright and sunny, bouncy but calm enough for long listening, hints of jungle exotica, comic book cartoon mood, tempo 110 bpm, no vocals, no heavy drums, seamless loop
```

### Journée au zoo, variante (`musique_jour_2`)

Pour alterner d'un jour à l'autre (le jeu prend l'une ou l'autre).

```text
Instrumental, cheerful building and gardening music for a cozy management game, acoustic guitar picking, glockenspiel, clarinet melody, light woodblock and tambourine, a feeling of busy workers and sunshine, slightly whimsical like a French comic book animation, tempo 105 bpm, no vocals, seamless loop
```

### Nuit : le conseil d'administration (`musique_nuit`)

```text
Instrumental, smooth late-night lounge jazz in a corporate boardroom, upright bass walking line, brushed drums, soft piano chords, muted trumpet phrases, a hint of comic suspense like a heist movie parody, relaxed and classy, tempo 85 bpm, no vocals, seamless loop
```

### Fin de partie, victoire (`victoire`, 8 à 10 s)

```text
Short kitschy corporate victory fanfare, brass and timpani, cymbal crash, a cheesy company jingle resolved in a big major chord, then light applause, comic and triumphant, 8 seconds, no vocals
```

### Fin de partie, défaite (`defaite`, 5 à 7 s)

```text
Short comic failure jingle, sad descending trombone "wah wah wah wah", followed by the sound of a paper shredder, cartoon style, 6 seconds, no vocals
```

---

## 2. Moments de la partie (ElevenLabs, courts)

| Fichier | Durée | Quand | Texte |
|---|---|---|---|
| `matin` | 2 s | Le jour se lève | `Short cheerful morning sting: a rooster crow mixed with a bright corporate xylophone chime, cartoon style` |
| `nuit` | 2 s | Fin de journée, le conseil s'ouvre | `Short evening sting: a wooden gavel knock followed by a soft door closing and a low jazzy double bass note` |
| `niveau` | 1,5 s | Un collaborateur monte de niveau | `Short level up sound: rising harp glissando with a sparkle and a tiny trumpet toot, cheerful cartoon` |
| `objectif` | 2 s | Objectif réussi | `Short achievement sound: a rubber stamp hitting paper followed by a small brass fanfare of three notes` |
| `animal` | 1,5 s | Un animal arrive au zoo | `Short happy arrival jingle: a little marimba run and a friendly animal call, cartoon zoo game` |

---

## 3. Bruitages d'interface et d'actions (ElevenLabs)

| Fichier | Durée | Quand | Texte |
|---|---|---|---|
| `clic` | 0,1 s | Tous les boutons | `Soft short UI click, wooden and paper-like, very short, not harsh` |
| `erreur` | 0,4 s | Action refusée | `Short soft UI error buzz, two low muted notes, comic and gentle, not alarming` |
| `valide` | 0,5 s | Choix validé | `Short positive UI confirmation, two rising soft bell notes` |
| `carte` | 0,4 s | Mobiliser un collaborateur, jouer une carte | `A single playing card being flicked and slapped onto a wooden table` |
| `pose` | 0,5 s | Poser un chantier | `A wooden stake hammered once into the ground, short, with a little dirt` |
| `achat` | 0,8 s | Contrat signé, embauche | `A rubber stamp firmly hitting paper followed by a quick pen signature scribble` |
| `piece` | 0,6 s | Vente, achat de ressources | `Old cash register ka-ching with coins dropping, short and bright` |
| `presse` | 1 s | Article du journaliste | `Camera flash pop and a newspaper being snapped open` |
| `hubert` | 1,2 s | La bulle d'Hubert s'affiche | `Comic mumbled gibberish voice of a pompous middle-aged manager clearing his throat, like an animated character babble, no real words` |
| `chantier` | 1 s | Un chantier se termine | `Construction finished: a last hammer hit, a satisfied wooden creak, and a short ding` |

Pour `hubert`, faites 3 variantes (`hubert`, `hubert_2`, `hubert_3`) : contrarié, content, moqueur. Le baragouin doit ressembler à une voix de dessin animé, sans aucun vrai mot.

---

## 4. Nouveaux sons (Claude les branche à réception)

Ceux-là n'existent pas encore dans le jeu. Ils donneraient beaucoup de vie au zoo.

### Gestes de travail (joués près de la caméra, discrets)

| Fichier | Durée | Texte |
|---|---|---|
| `geste_hache` | 0,5 s | `Single axe chop into a log, wood cracking, outdoors` |
| `geste_pioche` | 0,5 s | `Single pickaxe strike on rock, small stones falling` |
| `geste_pelle` | 0,6 s | `Single shovel digging into soil and throwing dirt` |
| `geste_marteau` | 0,4 s | `Single hammer hitting a nail into wood` |
| `geste_scie` | 1 s | `Short hand saw cutting through a plank, two strokes` |

### Cris d'animaux, un par type (le jeu en a quatre)

| Fichier | Durée | Texte |
|---|---|---|
| `cri_herbivore` | 1,5 s | `Distant friendly zoo herbivore call, an elephant trumpet softened, outdoor zoo ambience` |
| `cri_predateur` | 1,5 s | `Distant lion roar, not scary, heard across a sunny zoo` |
| `cri_aquatique` | 1,5 s | `Playful sea lion barks and a water splash` |
| `cri_aerien` | 1,5 s | `Exotic bird calls, a parrot squawk and wing flaps` |

Si le cœur vous en dit, un cri par espèce plus tard (40 fichiers `cri_<espèce>`).

### Ambiances en boucle (30 s, option « loop »)

| Fichier | Quand | Texte |
|---|---|---|
| `ambiance_nature` | Jour, toujours, très bas | `Seamless loop of a calm sunny countryside: birdsong, light wind in trees, distant stream, no people` |
| `ambiance_foule` | Jour, volume selon le nombre de visiteurs | `Seamless loop of a cheerful zoo crowd at a distance: families chatting, children laughing, footsteps on gravel, no clear words` |
| `ambiance_conseil` | Nuit, très bas sous la musique | `Seamless loop of a quiet corporate boardroom at night: a ticking wall clock, paper shuffling, a pen tapping, air conditioning hum` |

### Petits plus

| Fichier | Durée | Quand | Texte |
|---|---|---|---|
| `tic_tac` | 2 s | Nuit, c'est votre tour de choisir | `A wall clock ticking, four ticks, slightly comic and impatient` |
| `pioche_carte` | 0,6 s | Pioche du matin | `A deck of cards being shuffled briefly then cards dealt onto a table` |
| `porte_zoo` | 1,5 s | Ouverture du zoo | `A creaky wooden gate opening followed by a small crowd cheer and a bicycle bell` |
| `maladie` | 1 s | Un animal tombe malade | `A comic sick animal groan followed by a short sad tuba note` |
| `greve` | 1,5 s | Événement grève | `A short protest whistle blow and a distant crowd chanting without clear words` |

---

## Ordre conseillé

1. Les 4 musiques et les 2 jingles de fin : ce qu'on entend le plus.
2. `clic`, `carte`, `piece`, `achat`, `hubert` : joués des centaines de fois par partie.
3. Les ambiances et les gestes de travail : ils font vivre le zoo.
4. Le reste au fil de l'eau.
