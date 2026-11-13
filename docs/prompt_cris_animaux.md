# Textes pour le générateur de sons : un cri par espèce (40 fichiers)

Aujourd'hui le jeu joue un cri par **type** d'animal (`cri_herbivore`, `cri_predateur`, `cri_aquatique`, `cri_aerien`). Depuis le 13/11, il cherche d'abord un fichier **`cri_<espèce>`** : dès qu'un fichier existe, l'espèce a sa voix ; sinon le cri de son type reste en secours. Vous pouvez donc les livrer petit à petit.

## Comment faire

- **Outil** : ElevenLabs Sound Effects (ou Stable Audio). Durée **2 secondes** (1,5 à 3 s suffit), sans boucle.
- **Licence** : l'usage commercial demande en général un abonnement payant au moment de la génération. Vérifiez les conditions avant de publier le jeu.
- **Fichiers** : nommez-les exactement comme indiqué (`cri_lion.mp3`, `cri_ara.ogg`…), .ogg de préférence, sinon .mp3 ou .wav. Déposez-les dans un même dossier et prévenez Claude : il coupe les silences, égalise les volumes et les range dans `game/assets/audio/`.
- **Variantes** : les cris reviennent toutes les 7 à 16 secondes. Pour les espèces que vous aimez beaucoup, faites 2 versions (`cri_lion`, `cri_lion_2`) : le jeu en tire une au hasard.
- Générez 3 ou 4 essais par texte et gardez le meilleur.

## Le ton commun

Le cri est entendu **de loin**, dans un zoo ensoleillé de bande dessinée : léger, reconnaissable, **jamais effrayant ni violent**, sans musique ni voix humaine. Chaque texte se termine par la même consigne, déjà incluse ci-dessous. Certains animaux sont presque muets dans la réalité (carpe koï, salamandre, girafe…) : on leur donne un petit bruit de vie (eau, souffle, mâchonnement) plutôt qu'un cri inventé.

---

## Europe

| Fichier | Espèce | Texte à coller |
|---|---|---|
| `cri_aigle_royal` | Aigle royal | `Golden eagle high-pitched yelping call, two short cries echoing over mountain cliffs, a soft wing flap, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_bison_europe` | Bison d'Europe | `European bison low grunting snort and a short deep rumble, hooves shuffling on dry earth, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_lynx` | Lynx boréal | `Eurasian lynx short meowing call and a soft growl, like a big cat purring then chirping, forest ambience, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_loutre_europe` | Loutre d'Europe | `Eurasian otter high whistling squeaks and playful chirps, a small splash in a river, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_loup` | Loup gris | `Grey wolf single long howl, soft and melodic, slightly distant, one short answering yip, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_phoque` | Phoque gris | `Grey seal moaning wail and a playful snort, water lapping on rocks, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_mesange` | Mésange charbonnière | `Great tit cheerful two-note song "tea-cher tea-cher", bright and repeated three times, garden birdsong, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |
| `cri_faucon` | Faucon pèlerin | `Peregrine falcon rapid harsh "kak-kak-kak" call, a quick wing whoosh, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_cerf` | Cerf élaphe | `Red deer stag short bellowing roar, low and resonant, single call in a quiet forest, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_bouquetin` | Bouquetin des Alpes | `Alpine ibex short bleat and sharp whistle, hooves clicking on rocks, a small pebble falling, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |

## Amérique

| Fichier | Espèce | Texte à coller |
|---|---|---|
| `cri_dauphin_rose` | Dauphin rose de l'Amazone | `River dolphin playful clicks and high squeaky whistles, a gentle splash and blowhole puff, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |
| `cri_pygargue` | Pygargue à tête blanche | `Bald eagle chirping piping call, a series of high twittering notes, wing flap, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_puma` | Puma | `Cougar soft chirping whistle and a short purr, gentle big cat call, rocky hillside ambience, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_capybara` | Capybara | `Capybara soft clicking purrs and gentle whistles, calm contented chatter, water lapping, heard from a distance in a sunny zoo, light and natural, cute, no music, no human voice` |
| `cri_alligator` | Alligator américain | `American alligator low rumbling bellow, deep and short, water vibrating, a lazy splash, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_jaguar` | Jaguar | `Jaguar short rough grunting call, like a hand saw rasping three times, jungle ambience, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_ocelot` | Ocelot | `Ocelot small cat meow and soft yowl, playful, rustling leaves, heard from a distance in a sunny zoo, light and natural, cute, not scary, no music, no human voice` |
| `cri_ara` | Ara rouge | `Scarlet macaw loud raucous squawk, two cheerful parrot screeches, wings flapping, tropical ambience, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |
| `cri_bison_amerique` | Bison d'Amérique | `American bison deep grunting bellow, a low rolling growl and a snort, prairie wind, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_tapir` | Tapir de Baird | `Tapir high-pitched squeaky whistle, a short shrill call, then soft munching of leaves, heard from a distance in a sunny zoo, light and natural, cute, no music, no human voice` |

## Asie

| Fichier | Espèce | Texte à coller |
|---|---|---|
| `cri_tigre` | Tigre du Bengale | `Bengal tiger friendly chuffing "prusten" greeting, soft puffing snorts, then one short distant roar, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_panda` | Panda géant | `Giant panda soft bleating bleat and gentle huffing, bamboo stalk snapping and chewing, heard from a distance in a sunny zoo, light and natural, cute, no music, no human voice` |
| `cri_leopard_neiges` | Léopard des neiges | `Snow leopard soft chuffing and a short mewing yowl, cold mountain wind, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_loutre_cendree` | Loutre cendrée | `Asian small-clawed otters chirping and squeaking chatter, playful group calls, small splashes, heard from a distance in a sunny zoo, light and natural, cute, no music, no human voice` |
| `cri_paon` | Paon bleu | `Indian peafowl loud piercing "may-awe" call, two cries, rustle of tail feathers shaking, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |
| `cri_koi` | Carpe koï | `Koi pond ambience, a fish gently breaking the surface with a soft plop and gulp, small water ripples, a tiny bubble sound, heard from a distance in a sunny zoo, calm and natural, no music, no human voice` |
| `cri_salamandre` | Salamandre géante | `Giant salamander in a stream, a soft wet slosh, a slow bubbling breath and gentle stream water, heard from a distance in a sunny zoo, calm and natural, not scary, no music, no human voice` |
| `cri_calao` | Calao bicorne | `Great hornbill loud honking bark call, two hoarse "kok" calls, heavy whooshing wingbeats, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |
| `cri_grue_japon` | Grue du Japon | `Red-crowned crane bugling duet, clear trumpeting calls, elegant and resonant, marsh ambience, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |
| `cri_yak` | Yak | `Yak low grunting snort, a short deep grunt and a bell clinking softly, mountain meadow wind, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |

## Afrique

| Fichier | Espèce | Texte à coller |
|---|---|---|
| `cri_lion` | Lion | `Lion roar heard from far away across a sunny savanna, deep but soft and majestic, followed by a few low grunts, not aggressive, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_hippopotame` | Hippopotame | `Hippopotamus deep honking wheeze-honk laugh, a big bubbling snort in water and a splash, comical, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |
| `cri_guepard` | Guépard | `Cheetah high-pitched chirp like a bird, two short chirps and a soft purr, savanna grass, heard from a distance in a sunny zoo, light and natural, cute, no music, no human voice` |
| `cri_girafe` | Girafe | `Giraffe soft low humming at night and leaves rustling as it eats from a tree, gentle munching, heard from a distance in a sunny zoo, calm and natural, no music, no human voice` |
| `cri_manchot` | Manchot du Cap | `African penguin donkey-like braying call, a loud "hee-haw" bray from a colony, small splash, heard from a distance in a sunny zoo, light and natural, comical, no music, no human voice` |
| `cri_loutre_joues_blanches` | Loutre à joues blanches | `Cape clawless otter soft whistles and chattering squeaks, a splash in a stream, heard from a distance in a sunny zoo, light and natural, cute, no music, no human voice` |
| `cri_hyene` | Hyène tachetée | `Spotted hyena rising "whoop" call, two whoops and a short giggle, comical, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |
| `cri_zebre` | Zèbre | `Zebra barking whinny, a high bray mixed with a yip, like a donkey and a horse together, hooves on dry ground, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |
| `cri_grue_couronnee` | Grue couronnée | `Grey crowned crane honking two-note call, soft booming "oo-wah", wetland ambience, heard from a distance in a sunny zoo, light and natural, no music, no human voice` |
| `cri_messager` | Messager sagittaire | `Secretary bird deep croaking call and loud stomping footsteps on dry grass, a quick wing flap, heard from a distance in a sunny zoo, light and natural, not scary, no music, no human voice` |

---

## Après la livraison

Rien à changer dans le jeu : il prend `cri_<espèce>` dès que le fichier est dans `game/assets/audio/` (repli sur le cri du type sinon). Claude règle seulement les volumes pour qu'un cri d'oiseau ne couvre pas un lion lointain.
