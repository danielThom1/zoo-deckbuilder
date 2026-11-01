"""Redécoupe les 42 portraits depuis les planches d'origine. La grille fixe coupait les visages : chaque limite est
déplacée vers la colonne la plus vide à hauteur des têtes (les épaules peuvent se toucher), près de la limite théorique."""
import sys, os
import numpy as np
from PIL import Image

src = sys.argv[1]
dst = sys.argv[2]
k = 0
for (f, rows, ncol) in [('g2', [(0, 183), (183, 360)], 10), ('g1', [(0, 183), (183, 345)], 11)]:
    im = np.array(Image.open(os.path.join(src, f + '.png')).convert('RGBA'))
    W = im.shape[1]
    cw = W / ncol
    for (y0, y1) in rows:
        band = im[y0:y1]
        al = band[:, :, 3] > 40
        h = y1 - y0
        head = al[: int(h * 0.62)].sum(axis=0).astype(float)
        full = al.sum(axis=0).astype(float)
        cuts = [0]
        for i in range(1, ncol):
            lo, hi = int(i * cw - cw * 0.38), int(i * cw + cw * 0.38)
            xs = range(max(lo, cuts[-1] + 20), min(hi, W - 1))
            cuts.append(min(xs, key=lambda x: (head[x], full[x], abs(x - i * cw))))
        cuts.append(W)
        for c in range(ncol):
            k += 1
            a = band[:, cuts[c]:cuts[c + 1]].copy()
            m = a[:, :, 3] > 40
            ys, xs = np.nonzero(m)
            Image.fromarray(a[ys.min():ys.max() + 1, xs.min():xs.max() + 1], 'RGBA').save(os.path.join(dst, 'portrait_%02d.png' % k))
        print(f, y0, 'coupes :', cuts, 'têtes aux coupes :', [int(head[x]) for x in cuts[1:-1]])
print(k, 'portraits')
