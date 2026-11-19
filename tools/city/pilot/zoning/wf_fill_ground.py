"""Waterfront fill (branch claude/fill-waterfront, 19 Nov 2026): MEASURE the two empty blocks west of the waterfront
sample and write the base ground the fill pieces stand on. A measuring tool: it places nothing and decides nothing
about what is built; the pieces' own scripts do that by hand (tools/city/pilot/pieces/n_wf_*.gd).

Input: a ground dump of the area round the blocks (tools/city/audit/ground_dump.gd run on an area layout: every road,
junction and sample piece touching the blocks), e.g. OUT/wf/ground.
  1. outline: the block = the free ground between the neighbours' ground meshes (exact, from their triangles), so the
     block edge IS the neighbour's edge (Pier St / B Ave / the ring walks, the locked quadrants f_ne / f_nw).
  2. edge heights: the neighbour's ground height 5 cm outside the outline, every metre and at every outline vertex.
  3. base field: a harmonic fill (Laplace, 1 m grid) inside the block with those edge heights, so the ground meets
     every neighbour flush and has no bump of its own. The pieces cut terraces into it by hand.
  4. pieces: each block is cut into pieces along lines u = const (CUTS below, chosen by hand where both sides share
     one height line); each piece gets its outline (with the edge kind: "nb" = a neighbour's edge, "cut" = the seam
     with the next fill piece) and its part of the field.
Output: tools/city/pilot/pieces/wf_fill_ground.json

  python -I tools/city/pilot/zoning/wf_fill_ground.py OUT/wf/ground
"""
import json, sys
import numpy as np
from shapely.geometry import Polygon, Point, box, LineString
from shapely.ops import unary_union
from scipy.ndimage import distance_transform_edt

# piece name -> (block, u from, u to, origin u, origin v). Cuts chosen by hand (see the piece scripts' headers).
PIECES = {
    'n_wf_b1w': ('b1', 259.0, 331.0, 295.0, 270.0),
    'n_wf_b1m': ('b1', 331.0, 404.0, 367.0, 270.0),
    'n_wf_b1e': ('b1', 404.0, 562.0, 470.0, 270.0),
    'n_wf_b2w': ('b2', 259.0, 335.0, 297.0, 100.0),
    'n_wf_b2m': ('b2', 335.0, 400.0, 367.0, 100.0),
    'n_wf_b2e': ('b2', 400.0, 607.0, 470.0, 60.0),
}
SEEDS = {'b1': (360.0, 265.0), 'b2': (360.0, 100.0)}
STEP = 1.0


def load(base):
    recs = json.load(open(base + '.json', encoding='utf-8'))
    V = np.fromfile(base + '_v.bin', '<f4').reshape(-1, 3); I = np.fromfile(base + '_i.bin', '<i4')
    tris = []
    for r in recs:
        if r['piece'].startswith('n_wf_'):
            continue                      # our own pieces are not neighbours
        x = np.array(r['xf']); B = x[:9].reshape(3, 3).T; o = x[9:]
        for name, vo, vn, io, inn in r['surf']:
            v = V[vo:vo + vn].astype(np.float64) @ B.T + o
            T = v[I[io:io + inn]].reshape(-1, 3, 3)
            nr = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
            T = T[np.abs(nr[:, 1]) > 0.3 * np.linalg.norm(nr, axis=1)]
            T = T[(T[:, :, 0].max(1) > 240) & (T[:, :, 0].min(1) < 620) & (T[:, :, 2].max(1) > -10) & (T[:, :, 2].min(1) < 345)]
            tris.append(T)
    return np.concatenate(tris)


def height_at(tris, x, z):
    """highest neighbour ground containing (x, z), or None"""
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    d = (b[:, 2] - c[:, 2]) * (a[:, 0] - c[:, 0]) + (c[:, 0] - b[:, 0]) * (a[:, 2] - c[:, 2])
    ok = np.abs(d) > 1e-12
    l1 = np.where(ok, ((b[:, 2] - c[:, 2]) * (x - c[:, 0]) + (c[:, 0] - b[:, 0]) * (z - c[:, 2])) / np.where(ok, d, 1), -1)
    l2 = np.where(ok, ((c[:, 2] - a[:, 2]) * (x - c[:, 0]) + (a[:, 0] - c[:, 0]) * (z - c[:, 2])) / np.where(ok, d, 1), -1)
    l3 = 1 - l1 - l2
    m = (l1 >= -1e-4) & (l2 >= -1e-4) & (l3 >= -1e-4)
    if not m.any():
        return None
    h = l1[m] * a[m, 1] + l2[m] * b[m, 1] + l3[m] * c[m, 1]
    return float(h.max())


def main():
    tris = load(sys.argv[1])
    U = unary_union([Polygon(t[:, [0, 2]]) for t in tris if Polygon(t[:, [0, 2]]).area > 1e-6])
    free = box(245, -5, 615, 340).difference(U)
    out = {'_doc': __doc__.split('\n\n')[0], 'pieces': {}, 'blocks': {}}
    for bn, seed in SEEDS.items():
        g = [p for p in getattr(free, 'geoms', [free]) if p.contains(Point(seed))][0]
        g = g.buffer(-0.03, join_style='mitre').buffer(0.03, join_style='mitre').simplify(0.01)
        if g.geom_type != 'Polygon':
            g = max(g.geoms, key=lambda q: q.area)
        g = g.normalize()       # exterior clockwise in (x, z)
        ring = list(g.exterior.coords)[:-1]
        # densify every metre and measure the neighbour 5 cm outside
        pts = []
        for k in range(len(ring)):
            p = np.array(ring[k]); q = np.array(ring[(k + 1) % len(ring)])
            n = max(1, int(np.ceil(np.linalg.norm(q - p) / 1.0)))
            for i in range(n):
                pts.append(p + (q - p) * i / n)
        hs = []
        for p in pts:
            best = None
            for ang in np.linspace(0, 2 * np.pi, 16, endpoint=False):
                o = p + 0.05 * np.array([np.cos(ang), np.sin(ang)])
                if g.contains(Point(o)):
                    continue
                h = height_at(tris, o[0], o[1])
                if h is not None:
                    best = h if best is None else max(best, h)
            hs.append(best)
        hs = np.array([np.nan if h is None else h for h in hs])
        if np.isnan(hs).any():
            good = np.nonzero(~np.isnan(hs))[0]
            for i in np.nonzero(np.isnan(hs))[0]:
                hs[i] = hs[good[np.argmin(np.abs(good - i))]]
            print(bn, 'edge points without a neighbour (took the nearest):', int(np.isnan(hs).sum()))
        # harmonic fill on a 1 m grid over the bounds
        u0, v0, u1, v1 = [float(np.floor(b)) - 1 for b in g.bounds[:2]] + [float(np.ceil(b)) + 1 for b in g.bounds[2:]]
        nx = int((u1 - u0) / STEP) + 1; nz = int((v1 - v0) / STEP) + 1
        gx, gz = np.meshgrid(u0 + np.arange(nx) * STEP, v0 + np.arange(nz) * STEP)
        from shapely import contains_xy
        inside = contains_xy(g, gx, gz)
        # Dirichlet: every grid node outside (or within 0.5 m of the edge) takes the nearest edge point's height
        P = np.array(pts)
        fixed = ~inside
        bd = LineString(list(g.exterior.coords))
        from shapely import distance as sdist, points as spoints
        dist = sdist(bd, spoints(gx.ravel(), gz.ravel())).reshape(gx.shape)
        fixed |= dist < 0.5
        F = np.zeros(gx.shape)
        idx = np.nonzero(fixed)
        for j, i in zip(*idx):
            k = np.argmin((P[:, 0] - gx[j, i]) ** 2 + (P[:, 1] - gz[j, i]) ** 2)
            F[j, i] = hs[k]
        free_n = ~fixed
        # Laplace with the edge as boundary: one sparse solve (exact, no sweeps)
        from scipy.sparse import lil_matrix
        from scipy.sparse.linalg import spsolve
        ids = -np.ones(gx.shape, int); fj, fi = np.nonzero(free_n); ids[fj, fi] = np.arange(len(fj))
        A = lil_matrix((len(fj), len(fj))); rhs = np.zeros(len(fj))
        for n_, (j, i) in enumerate(zip(fj, fi)):
            A[n_, n_] = 4.0
            for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                jj, ii = j + dj, i + di
                if ids[jj, ii] >= 0: A[n_, ids[jj, ii]] = -1.0
                else: rhs[n_] += F[jj, ii]
        F[fj, fi] = spsolve(A.tocsr(), rhs)
        it = 1
        print(bn, 'outline', len(ring), 'vertices, area %.0f m2, edge heights %.2f..%.2f, field solved (%d sparse solve)' % (g.area, hs.min(), hs.max(), it))
        out['blocks'][bn] = {'outline': [[round(float(x), 4), round(float(z), 4)] for x, z in ring],
                             'edge': [[round(float(p[0]), 4), round(float(p[1]), 4), round(float(h), 4)] for p, h in zip(pts, hs)]}
        for pn, (blk, ua, ub, ox, oz) in PIECES.items():
            if blk != bn:
                continue
            cut = g.intersection(box(ua, -1000, ub, 1000))
            if cut.geom_type != 'Polygon':
                cut = max(cut.geoms, key=lambda q: q.area)
            cut = cut.normalize()
            cr = list(cut.exterior.coords)[:-1]
            kinds = []
            for k in range(len(cr)):
                p = cr[k]; q = cr[(k + 1) % len(cr)]
                on_cut = (abs(p[0] - q[0]) < 1e-6) and (abs(p[0] - ua) < 1e-6 or abs(p[0] - ub) < 1e-6) and not (abs(p[0] - g.bounds[0]) < 1e-3 or abs(p[0] - g.bounds[2]) < 1e-3)
                kinds.append('cut' if on_cut else 'nb')
            # edge heights at the piece outline's vertices (from the block's edge measure; cut vertices from the field)
            def eh(x, z):
                d2 = (P[:, 0] - x) ** 2 + (P[:, 1] - z) ** 2
                k = np.argmin(d2)
                if d2[k] < 0.25:
                    return float(hs[k])
                fx = (x - u0) / STEP; fz = (z - v0) / STEP; i = min(int(fx), nx - 2); j = min(int(fz), nz - 2); tx = fx - i; tz = fz - j
                return float((F[j, i] * (1 - tx) + F[j, i + 1] * tx) * (1 - tz) + (F[j + 1, i] * (1 - tx) + F[j + 1, i + 1] * tx) * tz)
            # densify the neighbour edges (1 m) so their heights are exact along the street's own line
            dense = []; dk = []
            for k in range(len(cr)):
                p = np.array(cr[k]); q = np.array(cr[(k + 1) % len(cr)])
                n = 1 if kinds[k] == 'cut' else max(1, int(np.ceil(np.linalg.norm(q - p) / 1.0)))
                for i in range(n):
                    r = p + (q - p) * i / n
                    dense.append([round(float(r[0]) - ox, 4), round(float(r[1]) - oz, 4), round(eh(r[0], r[1]), 4)]); dk.append(kinds[k])
            bx0, bz0, bx1, bz1 = cut.bounds
            i0 = int(np.floor((bx0 - u0) / STEP)) - 1; i1 = int(np.ceil((bx1 - u0) / STEP)) + 1
            j0 = int(np.floor((bz0 - v0) / STEP)) - 1; j1 = int(np.ceil((bz1 - v0) / STEP)) + 1
            i0 = max(i0, 0); j0 = max(j0, 0); i1 = min(i1, nx - 1); j1 = min(j1, nz - 1)
            sub = F[j0:j1 + 1, i0:i1 + 1]
            # distance of every field node to the piece's NEIGHBOUR edges (the frontage band is measured from them)
            from shapely.geometry import MultiLineString
            nbl = MultiLineString([[cr[k], cr[(k + 1) % len(cr)]] for k in range(len(cr)) if kinds[k] == 'nb'])
            sgx = gx[j0:j1 + 1, i0:i1 + 1]; sgz = gz[j0:j1 + 1, i0:i1 + 1]
            sd = sdist(nbl, spoints(sgx.ravel(), sgz.ravel()))
            out['pieces'][pn] = {'block': bn, 'ox': ox, 'oz': oz,
                                 'outline': dense, 'kinds': dk,
                                 'fx0': u0 + i0 * STEP - ox, 'fz0': v0 + j0 * STEP - oz, 'nx': int(sub.shape[1]), 'nz': int(sub.shape[0]), 'step': STEP,
                                 'y': [round(float(v), 4) for v in sub.ravel()],
                                 'd': [round(float(v), 3) for v in sd]}
            print(' ', pn, 'u %.1f..%.1f' % (cut.bounds[0], cut.bounds[2]), 'outline points', len(dense), 'cut edges', dk.count('cut'), 'area %.0f m2' % cut.area)
    json.dump(out, open('tools/city/pilot/pieces/wf_fill_ground.json', 'w'), separators=(',', ':'))
    print('wrote tools/city/pilot/pieces/wf_fill_ground.json')


if __name__ == '__main__':
    main()
