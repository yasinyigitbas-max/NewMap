"""Faces under the growth blocks' edges wherever an edge stands over what lies beside it (19 Nov 2026).

Yasin, shown the "floating" block edges and a trial face under the worst wall: "Yes, add it"; then, on the first
version (faces only under wall feet measured at their two ends): "there are still big gaps, fill them".

Why: a growth block's ground ends at its edge as a thin sheet. Where that edge is higher than what is beside it - the
land, or a lower neighbouring block or street - you look under the block unless a wall stands there, and the blocks'
own retaining walls do not reach the ground everywhere and are missing where two blocks meet (3,123 m of jumps between
residential blocks). The blocks are LOCKED, so the faces go into an overlay piece of their own, `x_wall_feet` (as the
shore foam is `x_shore_foam`): no block is opened.

What this writes: map_dc/coronado/city_kit/zoning/wall_feet.json - per growth block the stretches of its ground's
outer edge (and the edges of holes in it) that stand more than 8 cm over the surface right outside, cut every metre,
each with the height to carry a face from the edge 30 cm INTO that surface. The face stands 2 cm inside the edge, so
where the block has its own wall the face is hidden behind it and only shows below the wall's foot. It decides
nothing: every stretch is measured from the block's own ground mesh (the dump of tools/city/audit/ground_dump.gd), the
other pieces' ground and the land (zoning/terrain_grid.npz). `tools/city/pilot/pieces/x_wall_feet.gd` builds the piece
from it in the walls' own material, as "ground" meshes (one per block): the runtime bake merges them into the cells'
ground and they cost no draw of their own.
Rerun both after the land or any piece beside a growth block changes.

  python -I tools/city/pilot/zoning/wall_feet.py OUT/ground [--write]        (dry run by default)
"""
import json, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lower_land_to_pieces as LL

OUT = os.path.normpath(os.path.join(HERE, '../../../../map_dc/coronado/city_kit/zoning/wall_feet.json'))
GAP = 0.08          # an edge this far over the surface outside gets a face (the land is tucked 5 cm under every piece)
DEEP = 0.30         # the face goes this far into the surface outside
INSET = 0.02        # and stands this far inside the edge
STEP = 1.0


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not args: sys.exit(__doc__)
    base = args[0]; write = '--write' in sys.argv
    recs = json.load(open(base + '.json', encoding='utf-8'))
    V = np.fromfile(base + '_v.bin', '<f4').reshape(-1, 3); I = np.fromfile(base + '_i.bin', '<i4')
    t = np.load(LL.GRID); H = t['heights'].astype(np.float64); U0 = float(t['u0']); V0 = float(t['v0']); S = float(t['step'])
    ny, nx = H.shape; n = int(round(S))
    G, WHO = LL.raster(recs, V, I, U0, V0, (nx - 1) * n, (ny - 1) * n)

    def land(x, z):
        """the land as drawn: the LOWER of the two ways a 4 m square can be split into triangles, and of the bilinear"""
        fx = (x - U0) / S; fz = (z - V0) / S
        i = np.clip(np.floor(fx).astype(int), 0, nx - 2); j = np.clip(np.floor(fz).astype(int), 0, ny - 2); a = fx - i; b = fz - j
        h00 = H[j, i]; h10 = H[j, i + 1]; h01 = H[j + 1, i]; h11 = H[j + 1, i + 1]
        t1 = np.where(a + b <= 1, h00 + a * (h10 - h00) + b * (h01 - h00), h11 + (1 - a) * (h01 - h11) + (1 - b) * (h10 - h11))
        t2 = np.where(a >= b, h00 + a * (h10 - h00) + b * (h11 - h10), h00 + b * (h01 - h00) + a * (h11 - h01))
        bl = (h00 * (1 - a) + h10 * a) * (1 - b) + (h01 * (1 - a) + h11 * a) * b
        return np.minimum(np.minimum(t1, t2), bl)

    blocks = {}; stat = {'m': 0.0, 'm15': 0.0, 'm50': 0.0, 'm100': 0.0, 'm_piece': 0.0, 'worst': 0.0, 'q': 0}
    for k, r in enumerate(recs):
        if not str(r.get('from', '')).startswith('grow_'): continue
        x = np.array(r['xf'], float); B = x[:9].reshape(3, 3).T; o = x[9:]
        tris = []
        for name, vo, vn, io, inn in r['surf']:
            v = V[vo:vo + vn].astype(np.float64) @ B.T + o
            T = v[I[io:io + inn]].reshape(-1, 3, 3)
            nr = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]); ln = np.linalg.norm(nr, axis=1); ok = ln >= 1e-6
            tris.append(T[ok][np.abs(nr[ok, 1]) / ln[ok] >= 0.5])              # the ground itself (not its wall faces)
        T = np.concatenate(tris)
        if not len(T): continue
        # the block's own ground on a 0.25 m raster of its own (inside / outside tests)
        mn = T.reshape(-1, 3).min(0); mx = T.reshape(-1, 3).max(0)
        wx0 = np.floor(mn[0]) - 3; wz0 = np.floor(mn[2]) - 3; Q = 4
        own = np.zeros((int((np.ceil(mx[2]) + 3 - wz0) * Q), int((np.ceil(mx[0]) + 3 - wx0) * Q)), bool)
        for a, b, c in T:
            lo = np.minimum(np.minimum(a, b), c); hi = np.maximum(np.maximum(a, b), c)
            i0 = int((lo[0] - wx0) * Q); i1 = int((hi[0] - wx0) * Q) + 1; j0 = int((lo[2] - wz0) * Q); j1 = int((hi[2] - wz0) * Q) + 1
            xs = wx0 + (np.arange(i0, i1) + 0.5) / Q; zs = wz0 + (np.arange(j0, j1) + 0.5) / Q
            X, Z = np.meshgrid(xs, zs)
            d = (b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2])
            if abs(d) < 1e-12: continue
            w0 = ((b[2] - c[2]) * (X - c[0]) + (c[0] - b[0]) * (Z - c[2])) / d; w1 = ((c[2] - a[2]) * (X - c[0]) + (a[0] - c[0]) * (Z - c[2])) / d
            own[j0:j1, i0:i1] |= (w0 >= -1e-6) & (w1 >= -1e-6) & (1 - w0 - w1 >= -1e-6)

        def inside(px, pz):
            i = np.clip(((px - wx0) * Q).astype(int), 0, own.shape[1] - 1); j = np.clip(((pz - wz0) * Q).astype(int), 0, own.shape[0] - 1)
            return own[j, i]
        # boundary edges of the welded ground: an edge only one triangle has
        P = T.reshape(-1, 3); key = np.round(P * 100).astype(np.int64)
        kid = (key[:, 0] + 400000) * 1_000_003 * 1_000_033 + (key[:, 1] + 100000) * 1_000_033 + (key[:, 2] + 400000)
        _, vid = np.unique(kid, return_inverse=True); vid = vid.reshape(-1, 3)
        e = np.concatenate([vid[:, [0, 1]], vid[:, [1, 2]], vid[:, [2, 0]]]); e.sort(axis=1)
        pa = np.concatenate([T[:, 0], T[:, 1], T[:, 2]]); pb = np.concatenate([T[:, 1], T[:, 2], T[:, 0]])
        ek = e[:, 0].astype(np.int64) * 4_000_037 + e[:, 1]
        _, first, cnt = np.unique(ek, return_index=True, return_counts=True)
        sel = first[cnt == 1]; A = pa[sel]; Bv = pb[sel]
        d2 = Bv[:, [0, 2]] - A[:, [0, 2]]; L = np.hypot(d2[:, 0], d2[:, 1]); kk = L > 0.05
        A = A[kk]; Bv = Bv[kk]; L = L[kk]; d2 = d2[kk] / L[:, None]
        nrm = np.c_[d2[:, 1], -d2[:, 0]]; mid = (A + Bv) / 2
        in_p = inside(mid[:, 0] + nrm[:, 0] * 0.4, mid[:, 2] + nrm[:, 1] * 0.4); in_m = inside(mid[:, 0] - nrm[:, 0] * 0.4, mid[:, 2] - nrm[:, 1] * 0.4)
        ok = in_p ^ in_m                                                       # ground on exactly one side: a real edge
        A = A[ok]; Bv = Bv[ok]; L = L[ok]; nrm = np.where(in_p[ok][:, None], -nrm[ok], nrm[ok])     # pointing OUT of the block
        rows = []
        for a, b, l, no in zip(A, Bv, L, nrm):
            m = max(1, int(np.ceil(l / STEP))); s = np.linspace(0.0, 1.0, m + 1)
            pts = a[None, :] + (b - a)[None, :] * s[:, None]
            ox = pts[:, 0] + no[0] * 0.5; oz = pts[:, 2] + no[1] * 0.5
            hl = land(ox, oz)
            hp = np.full(len(pts), -np.inf)
            for dist in (0.5, 1.1):                                            # another piece's ground right outside
                qx = pts[:, 0] + no[0] * dist; qz = pts[:, 2] + no[1] * dist
                ci = np.clip(np.floor(qx - U0).astype(int), 0, G.shape[1] - 1); cj = np.clip(np.floor(qz - V0).astype(int), 0, G.shape[0] - 1)
                oth = (WHO[cj, ci] >= 0) & (WHO[cj, ci] != k) & ~inside(qx, qz)
                hp = np.where(oth & ~np.isfinite(hp), G[cj, ci], hp)
            hout = np.maximum(hl, hp); gap = pts[:, 1] - hout
            need = gap > GAP
            bot = np.minimum(hout, pts[:, 1]) - DEEP
            tx = pts[:, 0] - no[0] * INSET; tz = pts[:, 2] - no[1] * INSET
            for q in range(m):
                if not (need[q] or need[q + 1]): continue
                rows.append([round(float(c), 3) for c in (tx[q], pts[q, 1], tz[q], tx[q + 1], pts[q + 1, 1], tz[q + 1], bot[q], bot[q + 1])])
                g_ = float(max(gap[q], gap[q + 1])); ll = l / m
                stat['m'] += ll; stat['m15'] += ll * (g_ > 0.15); stat['m50'] += ll * (g_ > 0.5); stat['m100'] += ll * (g_ > 1.0)
                stat['m_piece'] += ll * bool(np.isfinite(hp[q]) or np.isfinite(hp[q + 1])); stat['worst'] = max(stat['worst'], g_)
        if rows:
            blocks['%s#%d' % (r['piece'], r['id'])] = rows; stat['q'] += len(rows)
    print('WALL-FEET growth blocks with an edge standing over what is beside it: %d; faces %d (%d triangles, both sides)' % (len(blocks), stat['q'], stat['q'] * 4))
    print('  edge length that gets a face: %.0f m (over 15 cm: %.0f m, over 50 cm: %.0f m, over 1 m: %.0f m; the highest %.2f m); of it beside another piece: %.0f m, beside empty land: %.0f m' % (
        stat['m'], stat['m15'], stat['m50'], stat['m100'], stat['worst'], stat['m_piece'], stat['m'] - stat['m_piece']))
    for k_, v_ in sorted(blocks.items(), key=lambda e_: -len(e_[1]))[:6]: print('  %-28s %4d faces' % (k_, len(v_)))
    if write:
        json.dump({'note': __doc__.strip().split('\n')[0], 'row': '[ax, ay, az, bx, by, bz, a_bottom_y, b_bottom_y]: the top of the face a-b (2 cm inside the block edge) and how far down it goes',
                   'gap_min': GAP, 'deep': DEEP, 'blocks': blocks}, open(OUT, 'w', newline='\n'))
        print('written', OUT)
    else:
        print('dry run: nothing written')


if __name__ == '__main__':
    main()
