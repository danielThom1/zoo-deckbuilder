"""Découpe les 4 planches détourées en sprites individuels + manifeste."""
import json, os
import numpy as np
from PIL import Image
from scipy import ndimage as nd

ICI = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ICI, '..', 'pkg', 'game', 'assets', 'bd', 'sprites')
FEUILLES = {'s1': '../bd/assets_bd.png', 'an': 'animaux.png', 'g1': 'gens1.png', 'g2': 'gens2.png'}
IM = {k: Image.open(os.path.join(ICI, v)).convert('RGBA') for k, v in FEUILLES.items()}
manif = {}

def decoupe(f, box, cat, nom, garder_un=True, pied='bas', seul=False):
    x, y, w, h = box
    c = IM[f].crop((x, y, x + w, y + h))
    a = np.array(c)
    al = a[:, :, 3] > 40
    if garder_un:
        lab, n = nd.label(nd.binary_dilation(al, iterations=2))
        if n > 1:
            tailles = nd.sum(al, lab, range(1, n + 1))
            keep = lab == (1 + int(np.argmax(tailles)))
            # garde aussi les morceaux proches et gros (≥ 15 % du principal)
            for i, t in enumerate(tailles):
                if not seul and t >= 0.15 * tailles.max(): keep |= lab == i + 1
            a[~keep, 3] = 0
            al = a[:, :, 3] > 40
    ys, xs = np.nonzero(al)
    if len(xs) == 0: return
    a = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    img = Image.fromarray(a, 'RGBA')
    d = os.path.join(OUT, cat); os.makedirs(d, exist_ok=True)
    img.save(os.path.join(d, nom + '.png'), optimize=True)
    W, H = img.size
    manif[nom] = {'fichier': f'res://assets/bd/sprites/{cat}/{nom}.png', 'categorie': cat, 'taille': [W, H],
                  'pied': [W // 2, H if pied == 'bas' else H // 2]}

# ---------------------------------------------------------------- planche 1 (bâtiments, décor, objets)
S1 = json.load(open(os.path.join(ICI, '..', 'bd', 'sprites.json')))
CAT1 = {'maison': 'batiments', 'entrepot': 'batiments', 'marche': 'batiments', 'interim': 'batiments', 'mine': 'batiments', 'souvenirs': 'batiments',
        'restaurant': 'batiments', 'atelier': 'batiments', 'snack': 'batiments', 'scene': 'batiments', 'formation': 'batiments', 'entree': 'batiments',
        'entree2': 'batiments', 'mairie': 'batiments', 'camp1': 'batiments', 'camp2': 'batiments', 'camp3': 'batiments', 'chantier1': 'batiments', 'chantier2': 'batiments',
        'bassin': 'batiments', 'abri': 'batiments'}
for nom, box in S1.items():
    if nom in ('marche1', 'marche2') or nom.startswith(('tete', 'buste', 'ouvrier', 'bucheron', 'mineur', 'porteur', 'accroupi', 'soigneur', 'visiteur')) or nom in (
            'zebre', 'gazelle', 'autruche', 'girafe', 'lion', 'elephant', 'rhino', 'vautour', 'cerf', 'renard', 'loup', 'ours', 'lynx', 'perroquet', 'singe', 'tapir', 'tigre',
            'gorille', 'toucan', 'flamant', 'loutre', 'pingouin', 'phoque', 'hippo', 'croco', 'antilope', 'marmotte', 'panda_roux', 'bison', 'aigle', 'leopard_neiges',
            'suricate', 'fennec', 'chameau', 'chevre', 'varan'):
        continue   # versions plus détaillées dans les autres planches
    cat = CAT1.get(nom, 'objets' if nom in ('bois', 'pierre', 'or', 'coeurs', 'pieces', 'etoile', 'zzz', 'nuage') else 'decor')
    decoupe('s1', box, cat, ('icone_' + nom) if cat == 'objets' else nom, garder_un=cat != 'decor' or nom not in ('montagnes',),
            pied='centre' if nom in ('bassin', 'pont') else 'bas')
decoupe('s1', (1268, 433, 145, 72), 'batiments', 'pont', pied='centre')

# ---------------------------------------------------------------- animaux
for n1, n2 in [('vautour', 'vautour'), ('aigle', 'aigle_royal'), ('toucan', 'toucan')]:
    decoupe('s1', S1[n1], 'animaux', n2)
NA = {0: 'zebre_tete', 1: 'zebre', 2: 'zebre_broute', 3: 'girafe_tete', 4: 'girafe', 5: 'girafon', 6: 'lion_tete', 7: 'lionne', 8: 'lion', 9: 'elephant_tete',
      10: 'elephant_famille', 11: 'rhinoceros', 12: 'elephant', 13: 'rhinoceros_petit', 14: 'tigre_duo', 15: 'jaguar_tete', 16: 'jaguar', 17: 'jaguar_marche', 18: 'jaguar_duo', 19: 'panthere_noire_tete',
      20: 'panthere_noire', 21: 'panthere_neiges_tete', 22: 'tigre', 23: 'panthere_noire_petite', 24: 'panthere_neiges', 25: 'panthere_neiges_petite', 26: 'ours_brun', 27: 'ours_brun_marche', 28: 'loup_tete', 29: 'loup',
      30: 'loup_marche', 31: 'renard_tete', 32: 'renard', 33: 'renard_petit', 34: 'lynx_tete', 35: 'lynx', 36: 'lynx_couche', 37: 'panda_roux_tete', 38: 'panda_roux', 39: 'panda_roux_marche',
      40: 'panda_tete', 41: 'panda', 42: 'panda_marche', 43: 'gorille', 44: 'gorille_marche', 45: 'chimpanze_tete', 46: 'chimpanzes', 47: 'orang_outan_tete', 48: 'orang_outan', 49: 'chimpanze',
      50: 'mandrill_tete', 51: 'capucin', 52: 'capucin_petit', 53: 'cerf', 54: 'biche', 55: 'faon', 56: 'faon_petit', 58: 'gazelle', 59: 'chacal',
      60: 'addax', 61: 'addax_2', 62: 'sanglier_tete', 63: 'sanglier', 64: 'marmotte_grosse', 65: 'tapir', 66: 'tapir_petit', 67: 'marmotte', 68: 'antilope', 69: 'yak',
      70: 'mouton', 71: 'alpaga', 72: 'castor', 73: 'tapir_gris', 74: 'cheval', 75: 'cheval_2', 76: 'chevre', 77: 'mouton_2', 78: 'lama', 79: 'dromadaire',
      80: 'dromadaire_petit', 81: 'ane', 82: 'ane_petit', 83: 'autruche', 84: 'emeu', 85: 'flamant', 86: 'manchot', 87: 'manchot_2', 88: 'hamster', 89: 'phoque',
      90: 'phoque_2', 91: 'loutre_assise', 92: 'loutre', 93: 'loutre_petite', 94: 'hippopotame', 95: 'hippopotame_petit', 97: 'crocodile', 98: 'toucan_vol', 99: 'dragon_komodo',
      101: 'varan', 102: 'serpent', 103: 'tortue', 104: 'iguane', 105: 'crocodile_nage', 107: 'kangourou', 108: 'kangourou_2',
      110: 'rat_kangourou', 113: 'fennec', 114: 'chouette', 115: 'paon', 116: 'grue', 117: 'suricate', 118: 'porc_epic', 119: 'chinchilla'}
BA = json.load(open(os.path.join(ICI, 'animaux_boxes.json')))
for i, nom in NA.items():
    decoupe('an', BA[i], 'animaux', nom, garder_un=not nom.endswith(('duo', 'famille', 'chimpanzes')))
decoupe('an', BA[96], 'animaux', 'perroquet', seul=True)

# ---------------------------------------------------------------- personnes
G1 = json.load(open(os.path.join(ICI, 'gens1_boxes.json')))
N1 = {6: 'charpentier', 7: 'porteur_sac', 8: 'ouvrier_brouette_arret', 9: 'contremaitre', 10: 'bucheron', 11: 'paysagiste_fourche', 12: 'garde_forestier', 13: 'soigneur_2',
      14: 'cuisinier', 15: 'serveur', 16: 'guichetier', 17: 'cantonnier', 18: 'ouvrier_seau', 19: 'architecte', 20: 'mineur', 21: 'drh_2', 22: 'cadre_valise', 23: 'photographe_2',
      24: 'cameraman', 25: 'guide', 26: 'veterinaire', 27: 'infirmiere', 28: 'chimiste', 29: 'formateur', 30: 'formatrice', 31: 'apprenti', 32: 'peintre'}
MARCHE_OUV = [33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 51, 59, 61, 69]
MARCHE_VIS = [46, 47, 48, 49, 50, 52, 53, 54, 55, 56, 57, 60, 62, 63, 64, 65, 66, 67, 68]
for i, n in N1.items(): decoupe('g1', G1[i], 'personnes', n)
for k, i in enumerate(MARCHE_OUV): decoupe('g1', G1[i], 'personnes', f'ouvrier_marche_{k + 1:02d}')
decoupe('g1', G1[43], 'personnes', 'terrassier')
decoupe('g1', G1[38], 'personnes', 'ouvrier_brouette')
for k, i in enumerate(MARCHE_VIS): decoupe('g1', G1[i], 'personnes', f'visiteur_{k + 1:02d}')
G2 = json.load(open(os.path.join(ICI, 'gens2_boxes.json')))
N2 = {0: 'porteur', 1: 'manoeuvre', 2: 'macon', 3: 'paysagiste', 4: 'soigneur', 5: 'guide_fanion', 6: 'vendeur', 7: 'marchand', 8: 'photographe', 9: 'lobbyiste',
      10: 'drh', 11: 'pompier', 12: 'secouriste', 13: 'randonneur', 14: 'visiteuse_sac', 15: 'visiteur_sweat', 16: 'enfant_garcon', 17: 'enfant_fille'}
for i, n in N2.items(): decoupe('g2', G2[i], 'personnes', n)
decoupe('g2', (664, 800, 126, 212), 'personnes', 'visiteur_canne')

# ---------------------------------------------------------------- portraits (têtes en buste)
k = 0
for (f, rows, ncol) in [('g2', [(0, 183), (183, 360)], 10), ('g1', [(0, 183), (183, 345)], 11)]:
    cw = 1536 / ncol
    for (y0, y1) in rows:
        for c in range(ncol):
            k += 1
            decoupe(f, (int(c * cw), y0, int(cw), y1 - y0), 'portraits', f'portrait_{k:02d}')
for i, box in enumerate([S1[f'tete{j}'] for j in range(1, 8)]):
    pass

json.dump(manif, open(os.path.join(OUT, '..', 'sprites_bd.json'), 'w'), ensure_ascii=False, indent=1, sort_keys=True)
print(len(manif), 'sprites')
from collections import Counter
print(Counter(v['categorie'] for v in manif.values()))
