"""Génère la musique et les bruitages du jeu (assets/audio/*.wav), de façon déterministe, sans fichier extérieur.
Tout est synthétisé : à remplacer un jour par de vrais enregistrements, avec les mêmes noms de fichiers.
    python tools/audio.py        puis    godot --headless --path game --import
"""
import os, wave
import numpy as np

SR = 22050
SORTIE = os.path.join(os.path.dirname(__file__), '..', 'game', 'assets', 'audio')


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def enveloppe(n, attaque, chute):
    t = np.arange(n) / SR
    a = np.minimum(t / max(attaque, 1e-4), 1.0)
    return a * np.exp(-t / max(chute, 1e-4))


def marimba(midi, duree=0.7):
    n = int(duree * SR)
    t = np.arange(n) / SR
    f = freq(midi)
    return (np.sin(2 * np.pi * f * t) * enveloppe(n, 0.002, 0.22)
            + 0.35 * np.sin(2 * np.pi * f * 4 * t) * enveloppe(n, 0.001, 0.05)
            + 0.12 * np.sin(2 * np.pi * f * 10 * t) * enveloppe(n, 0.001, 0.015))


def piano(midi, duree=1.6):
    n = int(duree * SR)
    t = np.arange(n) / SR
    f = freq(midi)
    s = np.zeros(n)
    for h, (amp, c) in enumerate([(1.0, 0.7), (0.45, 0.45), (0.2, 0.3), (0.1, 0.2), (0.05, 0.12)], 1):
        s += amp * np.sin(2 * np.pi * f * h * (1 + 0.0004 * h * h) * t) * enveloppe(n, 0.003, c)
    return s


def celesta(midi, duree=1.4):
    n = int(duree * SR)
    t = np.arange(n) / SR
    f = freq(midi)
    return np.sin(2 * np.pi * f * t) * enveloppe(n, 0.002, 0.5) + 0.3 * np.sin(2 * np.pi * f * 3.01 * t) * enveloppe(n, 0.001, 0.12)


def vibraphone(midi, duree=1.6):
    n = int(duree * SR)
    t = np.arange(n) / SR
    f = freq(midi)
    trem = 1 + 0.25 * np.sin(2 * np.pi * 4.5 * t)
    return (np.sin(2 * np.pi * f * t) + 0.2 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t / 0.1)) * enveloppe(n, 0.003, 0.7) * trem


def pincee(midi, duree=0.5):
    """Corde pincée (Karplus-Strong) : ukulélé ou guitare."""
    rng = np.random.default_rng(midi)
    p = max(2, int(SR / freq(midi)))
    n = int(duree * SR)
    buf = rng.uniform(-1, 1, p)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]
        buf[i % p] = 0.497 * (buf[i % p] + buf[(i + 1) % p])
    return out * enveloppe(n, 0.001, 0.3)


def basse(midi, duree=0.6):
    n = int(duree * SR)
    t = np.arange(n) / SR
    f = freq(midi)
    return (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2 * t)) * enveloppe(n, 0.006, 0.28)


def nappe(midis, duree):
    n = int(duree * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for m in midis:
        f = freq(m)
        for d in (-0.002, 0.002):
            s += np.sin(2 * np.pi * f * (1 + d) * t) + 0.2 * np.sin(2 * np.pi * 2 * f * (1 + d) * t)
    a = np.minimum(np.minimum(t / 0.6, 1.0), np.minimum((duree - t) / 0.6, 1.0))
    return s * a / (2 * len(midis))


def bruit(duree, chute, grave=False, graine=1):
    rng = np.random.default_rng(graine)
    n = int(duree * SR)
    s = rng.uniform(-1, 1, n)
    if not grave:
        s = np.diff(s, prepend=0.0)
    return s * enveloppe(n, 0.001, chute)


def grosse_caisse():
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * (55 + 60 * np.exp(-t / 0.03)) * t) * np.exp(-t / 0.09)


class Piste:
    """Mixage en boucle : ce qui dépasse la fin revient au début."""
    def __init__(self, duree):
        self.n = int(duree * SR)
        self.g = np.zeros(self.n)
        self.d = np.zeros(self.n)

    def poser(self, debut, son, gain=1.0, pan=0.0):
        i = (int(debut * SR) + np.arange(len(son))) % self.n
        np.add.at(self.g, i, son * gain * np.sqrt((1 - pan) / 2))
        np.add.at(self.d, i, son * gain * np.sqrt((1 + pan) / 2))

    def ecrire(self, nom, crete=0.75):
        m = np.stack([self.g, self.d], axis=1)
        # Un peu de réverbération en boucle, qui colle les instruments
        for retard, g in [(0.083, 0.16), (0.137, 0.11), (0.211, 0.07)]:
            m += np.roll(m, int(retard * SR), axis=0)[:, ::-1] * g
        m *= crete / np.abs(m).max()
        ecrire_wav(nom, m)
        return m


def ecrire_wav(nom, m):
    os.makedirs(SORTIE, exist_ok=True)
    data = (np.clip(m, -1, 1) * 32767).astype('<i2')
    with wave.open(os.path.join(SORTIE, nom + '.wav'), 'wb') as f:
        f.setnchannels(2 if data.ndim == 2 else 1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data.tobytes())
    print(nom, round(len(data) / SR, 1), 's', os.path.getsize(os.path.join(SORTIE, nom + '.wav')) // 1024, 'Ko')


def musique_jour():
    """Journée : marimba et ukulélé, bonne humeur de brochure d'entreprise. Fa majeur, 112 à la noire."""
    noire = 60.0 / 112
    rng = np.random.default_rng(7)
    grille = [(53, [0, 4, 7, 9]), (50, [0, 3, 7, 10]), (46, [0, 4, 7, 9]), (48, [0, 4, 7, 10])] * 2 \
        + [(46, [0, 4, 7, 11]), (45, [0, 3, 7, 10]), (50, [0, 3, 7, 10]), (48, [0, 4, 7, 10])] \
        + [(53, [0, 4, 7, 9]), (50, [0, 3, 7, 10]), (46, [0, 4, 7, 9]), (48, [0, 4, 7, 10])]
    grille = [g for g in grille for _ in (0, 1)]
    p = Piste(len(grille) * 4 * noire)
    theme = [0, 2, 4, 2, 7, 4, 2, 0]
    for mes, (fond, acc) in enumerate(grille):
        t0 = mes * 4 * noire
        for b, m in enumerate([0, 7, 12, 7]):
            p.poser(t0 + b * noire, basse(fond - 12 + m if m != 12 else fond, noire * 1.1), 0.55)
        for b in range(4):
            contre = t0 + (b + 0.5) * noire + 0.012
            for k, a in enumerate(acc):
                p.poser(contre + k * 0.006, pincee(fond + 12 + a, 0.4), 0.13, -0.35)
            p.poser(t0 + b * noire, bruit(0.05, 0.015, graine=b), 0.05, 0.3)
            p.poser(t0 + (b + 0.5) * noire, bruit(0.04, 0.012, graine=b + 9), 0.09, 0.3)
        p.poser(t0, grosse_caisse(), 0.22)
        p.poser(t0 + 2 * noire, grosse_caisse(), 0.16)
        # Mélodie : les notes de l'accord, un motif qui revient toutes les 4 mesures
        gamme = [fond + 24 + a for a in acc] + [fond + 36]
        if mes % 8 < 4:
            for i, d in enumerate(theme):
                note = gamme[(d + mes) % len(gamme)]
                p.poser(t0 + i * noire * 0.5, marimba(note), 0.5 if i % 2 == 0 else 0.33, 0.25)
        elif mes % 2 == 0:
            for i in range(4):
                if rng.random() < 0.75:
                    p.poser(t0 + i * noire, marimba(gamme[int(rng.integers(0, len(gamme)))]), 0.42, 0.25)
    p.ecrire('musique_jour', 0.7)


def musique_nuit():
    """Nuit : piano lent et célesta, le bureau de la direction après les heures. La mineur, 66 à la noire."""
    noire = 60.0 / 66
    rng = np.random.default_rng(11)
    grille = [(45, [0, 3, 7, 10]), (41, [0, 4, 7, 11]), (48, [0, 4, 7, 11]), (43, [0, 4, 7, 10])] * 4
    p = Piste(len(grille) * 4 * noire)
    for mes, (fond, acc) in enumerate(grille):
        t0 = mes * 4 * noire
        p.poser(t0, nappe([fond + 12 + a for a in acc[:3]], 4 * noire + 0.8), 0.22)
        p.poser(t0, basse(fond - 12, 3.0) * 0.8, 0.4)
        motif = [0, 2, 1, 3, 2, 1, 2, 3]
        for i, d in enumerate(motif):
            p.poser(t0 + i * noire * 0.5 + 0.01 * i % 0.02, piano(fond + 24 + acc[d]), 0.26 if i % 4 == 0 else 0.17, -0.2)
        if mes % 2 == 1:
            for i in (1.5, 2.5, 3.0):
                if rng.random() < 0.7:
                    p.poser(t0 + i * noire, celesta(fond + 36 + acc[int(rng.integers(0, 4))]), 0.2, 0.4)
    p.ecrire('musique_nuit', 0.6)


def musique_menu():
    """Menu : vibraphone et balais, musique d'ascenseur de siège social. Si bémol majeur, 92 à la noire."""
    noire = 60.0 / 92
    rng = np.random.default_rng(3)
    grille = [(46, [0, 4, 7, 11]), (43, [0, 3, 7, 10]), (48, [0, 3, 7, 10]), (41, [0, 4, 7, 10])] * 4
    p = Piste(len(grille) * 4 * noire)
    for mes, (fond, acc) in enumerate(grille):
        t0 = mes * 4 * noire
        for b in range(4):
            p.poser(t0 + b * noire, basse(fond - 12 + [0, 7, 12, 7][b], noire), 0.5)
            p.poser(t0 + b * noire, bruit(0.14, 0.05, graine=b + mes), 0.05, 0.4)
            p.poser(t0 + (b + 0.66) * noire, bruit(0.05, 0.02, graine=b + 30), 0.05, 0.4)
        for b in (1, 2.66):
            for k, a in enumerate(acc):
                p.poser(t0 + b * noire + k * 0.005, piano(fond + 12 + a, 0.8), 0.13, -0.3)
        gamme = [fond + 24 + a for a in acc]
        for i in range(8):
            if rng.random() < (0.8 if i % 2 == 0 else 0.3):
                p.poser(t0 + i * noire * 0.5, vibraphone(gamme[(i + mes * 2) % 4] + (12 if rng.random() < 0.2 else 0)), 0.33, 0.25)
    p.ecrire('musique_menu', 0.65)


def ton(f0, f1, duree, chute, forme='sin'):
    n = int(duree * SR)
    t = np.arange(n) / SR
    f = f0 + (f1 - f0) * t / duree
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph) if forme == 'sin' else np.sign(np.sin(ph)) * 0.5
    return s * enveloppe(n, 0.002, chute)


def suite(*sons, ecart=0.08):
    n = int(ecart * SR * (len(sons) - 1)) + max(len(s) for s in sons)
    out = np.zeros(n)
    for i, s in enumerate(sons):
        d = int(ecart * SR * i)
        out[d:d + len(s)] += s
    return out


def plus(a, b):
    n = max(len(a), len(b))
    out = np.zeros(n)
    out[:len(a)] += a
    out[:len(b)] += b
    return out


def effet(nom, s, gain=0.7):
    s = s / max(1e-6, np.abs(s).max()) * gain
    ecrire_wav(nom, s)


def bruitages():
    effet('clic', ton(900, 600, 0.05, 0.015), 0.35)
    effet('valide', suite(ton(660, 660, 0.09, 0.05), ton(880, 880, 0.14, 0.07), ecart=0.07), 0.5)
    effet('erreur', suite(ton(220, 200, 0.12, 0.07, 'carre'), ton(180, 160, 0.16, 0.08, 'carre'), ecart=0.11), 0.4)
    effet('carte', plus(bruit(0.1, 0.03, graine=4) * 0.6, ton(420, 520, 0.08, 0.03) * 0.5), 0.45)
    effet('pose', plus(bruit(0.08, 0.02, True, 5) * 0.5, ton(180, 110, 0.09, 0.03) * 0.7), 0.5)
    effet('piece', suite(ton(1760, 1760, 0.12, 0.05), ton(2350, 2350, 0.25, 0.1), ecart=0.06), 0.4)
    effet('achat', suite(ton(1320, 1320, 0.1, 0.05), ton(1760, 1760, 0.1, 0.05), ton(2350, 2350, 0.3, 0.12), ecart=0.06), 0.45)
    effet('chantier', suite(bruit(0.07, 0.015, True, 6) + ton(320, 160, 0.07, 0.02), bruit(0.07, 0.015, True, 7) + ton(320, 160, 0.07, 0.02),
                            bruit(0.1, 0.03, True, 8) + ton(420, 200, 0.1, 0.03), ecart=0.13), 0.55)
    effet('niveau', suite(*[marimba(m, 0.5) for m in (72, 76, 79, 84)], ecart=0.09), 0.6)
    effet('objectif', suite(*[vibraphone(m, 1.0) for m in (67, 72, 76, 79, 84)], ecart=0.1), 0.6)
    effet('animal', suite(ton(300, 520, 0.25, 0.12), ton(520, 340, 0.3, 0.14), ecart=0.18), 0.5)
    effet('hubert', suite(ton(240, 200, 0.05, 0.02, 'carre'), ton(300, 240, 0.05, 0.02, 'carre'), ton(220, 180, 0.07, 0.03, 'carre'), ecart=0.06), 0.25)
    effet('nuit', suite(piano(45, 2.0), piano(52, 2.0), piano(57, 2.0), ecart=0.18) + 0, 0.5)
    effet('matin', suite(*[marimba(m, 0.6) for m in (65, 69, 72, 77)], ecart=0.12), 0.55)
    effet('presse', plus(bruit(0.16, 0.06, graine=12) * 0.6, ton(700, 500, 0.1, 0.04) * 0.3), 0.45)
    effet('victoire', suite(*[piano(m, 1.8) for m in (60, 64, 67, 72, 76, 79, 84)], ecart=0.13), 0.7)
    effet('defaite', suite(*[piano(m, 2.0) for m in (60, 56, 53, 48)], ecart=0.3), 0.6)


if __name__ == '__main__':
    musique_jour()
    musique_nuit()
    musique_menu()
    bruitages()
