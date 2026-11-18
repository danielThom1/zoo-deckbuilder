"""Version anglaise : liste les textes français du jeu qui n'ont pas encore de traduction.

    python tools/traduction_extraire.py            # écrit game/lang/a_traduire.json (texte français → "")
    python tools/traduction_extraire.py --fusion   # verse game/lang/a_traduire.json (traductions remplies) dans en.json

Sources : les chaînes des scripts (hors tests, commentaires et messages de console) et les champs de texte des données
(noms, descriptions, répliques d'Hubert). Un morceau collé par « + » donne aussi son gabarit (« Pris par %s »).
Une entrée laissée vide reste en français dans le jeu. Voir game/scripts/traduction.gd.
"""
import json
import os
import re
import sys

RACINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game")
TABLE = os.path.join(RACINE, "lang", "en.json")
A_TRADUIRE = os.path.join(RACINE, "lang", "a_traduire.json")
LITTERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
# Mots isolés en minuscules affichés tels quels (ressources, terrains, jours…)
MOTS = ["bois", "pierre", "or", "argent", "influence", "gratuit", "lundi", "mardi", "mercredi", "jeudi", "vendredi",
        "samedi", "dimanche", "prairie", "forêt", "eau", "roche", "sable", "montagne", "jour", "jours", "nuit",
        "aujourd'hui", "hier", "demain", "partie", "parties", "animaux", "visiteurs", "collaborateurs", "aucun",
        "aucune", "oui", "non", "dernière", "herbivore", "prédateur", "aquatique", "aérien", "commun", "rare",
        "peu commun", "malade", "propre", "sale", "ouvert", "fermé", "en chantier", "terminé"]
# Clés des données dont la valeur est un texte affiché
CLES_TEXTE = {"nom", "nom_f", "texte", "capacite", "description", "titre", "effet_texte", "_note_effet", "desc", "court",
              "legende", "phrase", "slogan", "categorie_nom", "nom_court", "intitule", "consigne", "objet", "libelle"}


def _utile(s):
    if not re.search(r"[A-Za-zÀ-ÿ]", s):
        return False
    if s.startswith(("res://", "user://", "--", "ui_", "metier_", "ressource_", "batiment_", "ordre_")):
        return False
    if "/" in s and " " not in s:
        return False
    if re.fullmatch(r"[a-z0-9_]+", s):
        return s in MOTS
    if re.fullmatch(r"[A-Za-z0-9_]+", s) and "_" in s:
        return False
    if re.fullmatch(r"[A-Z0-9_]+", s) and len(s) < 4:
        return False
    return True


def depuis_scripts():
    out = {}
    for dp, _dn, fn in os.walk(RACINE):
        if any(x in dp for x in ("tests", ".godot", "lang")):
            continue
        for f in fn:
            if not f.endswith(".gd") or f == "traduction.gd":
                continue
            for ligne in open(os.path.join(dp, f), encoding="utf8"):
                l = ligne.strip()
                if l.startswith("#") or l.startswith(("print(", "push_error(", "push_warning(", "printerr(")):
                    continue
                for m in LITTERAL.finditer(l):
                    s = m.group(1).encode("utf8").decode("unicode_escape").encode("latin1").decode("utf8") \
                        if "\\" in m.group(1) else m.group(1)
                    if not _utile(s):
                        continue
                    out[s] = ""
                    apres = l[m.end():].lstrip()
                    avant = l[:m.start()].rstrip()
                    if apres.startswith("+") and not apres.startswith("+="):
                        out[s + "%s"] = "=" + s  # gabarit dérivé du morceau
                    if avant.endswith("+"):
                        out["%s" + s] = "=" + s
    return out


def _parcourir(x, out, cle=""):
    if isinstance(x, dict):
        for k, v in x.items():
            _parcourir(v, out, k)
    elif isinstance(x, list):
        for v in x:
            _parcourir(v, out, cle)
    elif isinstance(x, str):
        if cle.startswith("_note") and cle != "_note_effet":
            return
        if (cle in CLES_TEXTE or " " in x.strip() or re.search(r"[À-ÿ]", x)) and _utile(x) and "res://" not in x:
            out[x] = ""


def depuis_donnees():
    out = {}
    for f in ["animals.json", "workers.json", "buildings.json", "events.json", "hubert.json", "defis.json",
              "personnages.json"]:
        p = os.path.join(RACINE, "data", f)
        if os.path.exists(p):
            _parcourir(json.load(open(p, encoding="utf8")), out)
    return out


def main():
    table = json.load(open(TABLE, encoding="utf8")) if os.path.exists(TABLE) else {}
    if "--fusion" in sys.argv:
        nouveau = json.load(open(A_TRADUIRE, encoding="utf8"))
        n = 0
        for fr, en in nouveau.items():
            if en:
                table[fr] = en
                n += 1
        json.dump(dict(sorted(table.items())), open(TABLE, "w", encoding="utf8"), ensure_ascii=False, indent=0)
        print("%d traductions ajoutées, %d en tout" % (n, len(table)))
        return
    tout = depuis_scripts()
    tout.update({k: v for k, v in depuis_donnees().items() if k not in tout})
    manque = {}
    for fr, v in tout.items():
        if fr in table:
            continue
        if v.startswith("="):  # gabarit dérivé : se remplit seul si le morceau est traduit
            base = v[1:]
            if base in table:
                table[fr] = (table[base] + "%s") if fr.endswith("%s") else ("%s" + table[base])
            continue
        manque[fr] = ""
    json.dump(dict(sorted(table.items())), open(TABLE, "w", encoding="utf8"), ensure_ascii=False, indent=0)
    json.dump(manque, open(A_TRADUIRE, "w", encoding="utf8"), ensure_ascii=False, indent=0)
    print("%d textes sans traduction : %s" % (len(manque), A_TRADUIRE))


if __name__ == "__main__":
    main()
