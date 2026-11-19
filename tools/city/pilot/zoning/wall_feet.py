"""Faces under the growth blocks' outer walls where the wall's foot stops above the land (19 Nov 2026).

Yasin, shown the "floating" block edges and a trial picture of a face under the worst wall: "Yes, add it".

Why: a growth block's edge beside empty land is a retaining wall (rv_lib / the grow libs: "retaining faces"). After
the land was fitted to the blocks (lower_land_to_pieces.py) the land meets most wall feet, but where a lower piece of
ground lies within the same 4 m of land grid the land cannot rise to the foot: a sliver of air shows under the wall
(24 m of wall with more than 15 cm, 322 m with more than 5 cm, at most 32 cm). The blocks are LOCKED, so the faces go
into an overlay piece of their own, `x_wall_feet` (as the shore foam is `x_shore_foam`): no block is opened.

What this writes: map_dc/coronado/city_kit/zoning/wall_feet.json - per growth block the stretches of outer wall foot
that stand more than 3 cm over the land as drawn, each with the depth to carry the face 30 cm INTO the land. It decides
nothing: every stretch is measured from the block's own wall faces (the dump of tools/city/audit/ground_dump.gd) and
the land (zoning/terrain_grid.npz). `tools/city/pilot/pieces/x_wall_feet.gd` builds the piece from it, in the walls'
own material ("wall"), as "ground" meshes (one per block), so the runtime bake merges them into the cells' ground and
they cost no draw of their own.
Rerun both after the land or a growth block changes.

  python -I tools/city/pilot/zoning/wall_feet.py OUT/ground [--write]        (dry run by default)
"""
import json, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lower_land_to_pieces as LL

OUT = os.path.normpath(os.path.join(HERE, '../../../../map_dc/coronado/city_kit/zoning/wall_feet.json'))
GAP = 0.03          # a foot this far over the land gets a face
DEEP = 0.30         # the face goes this far into the land


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not args: sys.exit(__doc__)
    base = args[0]; write = '--write' in sys.argv
    recs = json.load(open(base + '.json', encoding='utf-8'))
    V = np.fromfile(base + '_v.bin', '<f4').reshape(-1, 3); I = np.fromfile(base + '_i.bin', '<i4')
    t = np.load(LL.GRID); H = t['heights'].astype(np.float64); U0 = float(t['u0']); V0 = float(t['v0']); S = float(t['step'])
    ny, nx = H.shape; n = int(round(S))
    G, _ = LL.raster(recs, V, I, U0, V0, (nx - 1) * n, (ny - 1) * n)
    has = np.isfinite(G)

    def land(x, z):
        """the land as drawn: the LOWER of the two ways a 4 m square can be split into triangles, and of the bilinear"""
        fx = (x - U0) / S; fz = (z - V0) / S
        i = np.clip(np.floor(fx).astype(int), 0, nx - 2); j = np.clip(np.floor(fz).astype(int), 0, ny - 2); a = fx - i; b = fz - j
        h00 = H[j, i]; h10 = H[j, i + 1]; h01 = H[j + 1, i]; h11 = H[j + 1, i + 1]
        t1 = np.where(a + b <= 1, h00 + a * (h10 - h00) + b * (h01 - h00), h11 + (1 - a) * (h01 - h11) + (1 - b) * (h10 - h11))
        t2 = np.where(a >= b, h00 + a * (h10 - h00) + b * (h11 - h10), h00 + b * (h01 - h00) + a * (h11 - h01))
        bl = (h00 * (1 - a) + h10 * a) * (1 - b) + (h01 * (1 - a) + h11 * a) * b
        return np.minimum(np.minimum(t1, t2), bl)

    def beside_empty(x, z):
        o = np.zeros(len(x), bool)
        for dx in (-1.5, 0.0, 1.5):
            for dz in (-1.5, 0.0, 1.5):
                i = np.clip(np.floor(x + dx - U0).astype(int), 0, G.shape[1] - 1); j = np.clip(np.floor(z + dz - V0).astype(int), 0, G.shape[0] - 1)
                o |= ~has[j, i]
        return o

    blocks = {}; tot_m = 0.0; tot_m15 = 0.0; worst = 0.0; nq = 0
    for r in recs:
        if not str(r.get('from', '')).startswith('grow_'): continue
        x = np.array(r['xf'], float); B = x[:9].reshape(3, 3).T; o = x[9:]
        tris = []
        for name, vo, vn, io, inn in r['surf']:
            v = V[vo:vo + vn].astype(np.float64) @ B.T + o
            T = v[I[io:io + inn]].reshape(-1, 3, 3)
            nr = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]); ln = np.linalg.norm(nr, axis=1); ok = ln >= 1e-6
            tris.append(T[ok][np.abs(nr[ok, 1]) / ln[ok] < 0.5])               # steep faces: walls
        T = np.concatenate(tris)
        if not len(T): continue
        # a wall's FOOT vertices: the lowest of the wall vertices standing over the same point
        P = T.reshape(-1, 3); key = np.round(P[:, [0, 2]] * 50).astype(np.int64); kk = key[:, 0] * 10_000_019 + key[:, 1]
        u, inv = np.unique(kk, return_inverse=True)
        ymin = np.full(len(u), np.inf); ymax = np.full(len(u), -np.inf); np.minimum.at(ymin, inv, P[:, 1]); np.maximum.at(ymax, inv, P[:, 1])
        foot = ((P[:, 1] <= ymin[inv] + 0.01) & (ymax[inv] > ymin[inv] + 0.05)).reshape(-1, 3)
        seen = set(); rows = []
        for a, b in ((0, 1), (1, 2), (0, 2)):
            m = foot[:, a] & foot[:, b]
            A = T[m, a]; Bv = T[m, b]
            if not len(A): continue
            L = np.hypot(Bv[:, 0] - A[:, 0], Bv[:, 2] - A[:, 2]); k = L > 0.05
            A = A[k]; Bv = Bv[k]; L = L[k]
            mid = (A + Bv) / 2; k = beside_empty(mid[:, 0], mid[:, 2])
            A = A[k]; Bv = Bv[k]; L = L[k]
            la = land(A[:, 0], A[:, 2]); lb = land(Bv[:, 0], Bv[:, 2]); ga = A[:, 1] - la; gb = Bv[:, 1] - lb
            for q in np.nonzero(np.maximum(ga, gb) > GAP)[0]:
                e = tuple(sorted([tuple(np.round(A[q], 2)), tuple(np.round(Bv[q], 2))]))
                if e in seen: continue                                       # both faces of one wall
                seen.add(e)
                rows.append([round(float(c), 3) for c in (A[q, 0], A[q, 1], A[q, 2], Bv[q, 0], Bv[q, 1], Bv[q, 2], min(la[q], A[q, 1]) - DEEP, min(lb[q], Bv[q, 1]) - DEEP)])
                g_ = max(ga[q], gb[q]); tot_m += L[q]; tot_m15 += L[q] if g_ > 0.15 else 0.0; worst = max(worst, g_)
        if rows:
            blocks['%s#%d' % (r['piece'], r['id'])] = rows; nq += len(rows)
    print('WALL-FEET growth blocks with a wall foot over the land: %d; stretches %d; %.0f m of wall foot (more than 15 cm over the land: %.0f m); largest gap %.2f m' % (
        len(blocks), nq, tot_m, tot_m15, worst))
    for k_, v_ in sorted(blocks.items(), key=lambda e: -len(e[1]))[:8]: print('  %-28s %3d stretches' % (k_, len(v_)))
    if write:
        json.dump({'note': __doc__.strip().split('\n')[0], 'row': '[ax, ay, az, bx, by, bz, a_bottom_y, b_bottom_y]: the wall foot a-b and how far down the face goes', 'gap_min': GAP, 'deep': DEEP, 'blocks': blocks},
                  open(OUT, 'w', newline='\n'))
        print('written', OUT)
    else:
        print('dry run: nothing written')


if __name__ == '__main__':
    main()
