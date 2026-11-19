"""Lower the land where it lies over a piece's ground (19 Nov 2026; Yasin: "half of the city is sunk",
then, after the one-block and the eight-block test pictures: "go to repo apply the fix map wide").

What it does, and nothing else:
  - reads every piece's ground as built (the dump of tools/city/audit/ground_dump.gd) and the land grid
    (zoning/terrain_grid.npz, 4 m nodes);
  - finds the 1 m cells where the land is not at least 5 cm under the piece's lowest ground (the rule terrain.py fits
    to: "the terrain sits 5 cm under the pieces");
  - lowers ONLY the land nodes those cells rest on, each to 5 cm under the lowest piece ground within its own 4 m
    reach. A node is never raised. A node no such cell rests on is not touched. Sea nodes are not touched.
It reads no piece for writing: no .scn, no layout row, no lock entry changes. It does not re-solve the island, so the
land away from the pieces keeps its shape exactly (terrain.py would re-solve everything).

What it does NOT mend (measure with tools/city/audit/ground_check.py): a jump where two pieces meet at different
heights (that needs a retaining wall or a piece fix), and the bank it leaves where a lowered node sits beside
untouched land with nothing built on it.

  python -I tools/city/pilot/zoning/lower_land_to_pieces.py OUT/ground                 dry run: numbers only
  python -I tools/city/pilot/zoning/lower_land_to_pieces.py OUT/ground --out=<npz>     write the result somewhere else
  python -I tools/city/pilot/zoning/lower_land_to_pieces.py OUT/ground --write         write zoning/terrain_grid.npz
  --fit       after the lowering, bring the land back up to the growth pieces as far as every piece allows (see
              fit_up()): a block's edge does not stand over the land, the land does not cover a piece
  --ease-from=<npz>   also ease the banks beside the lowered land (see ease()); <npz> is the land grid from BEFORE
              the lowering:  git show bac444bc:map_dc/coronado/city_kit/zoning/terrain_grid.npz > OUT/terrain_grid_before_lowering.npz
  --only=grow_apt[,..]   of the growth zones, only these families ask and are fitted
  --ask=all   let every family's ground ask (default: only the growth zones, from 'grow_*' layout rows; the road kit
              and the approved samples keep the land terrain.py fitted to them)
After --write: python -I tools/city/pilot/zoning/bake_game_terrain.py (the game-format land, data_citykit).
"""
import collections, json, os, sys
import numpy as np
from scipy.ndimage import minimum_filter

HERE = os.path.dirname(os.path.abspath(__file__))
GRID = os.path.normpath(os.path.join(HERE, '../../../../map_dc/coronado/city_kit/zoning/terrain_grid.npz'))
UNDER = 0.05        # the land sits this far under the lowest piece ground (terrain.py's rule)


def family(piece, frm):
    if frm.startswith('grow_'): return frm
    if frm.startswith('sample'): return 'sample street' if piece[:2] in ('j_', 's_') else 'sample block'
    return 'road kit (%s)' % frm if frm else 'other'


def raster(recs, V, I, U0, V0, NX, NY):
    """per 1 m cell the LOWEST up-facing ground (cell centre and every triangle vertex, as piece_ground.gd), and the
    index of the record that gives it; inf / -1 where no piece is"""
    g = np.full(NX * NY, np.inf); who = np.full(NX * NY, -1, np.int32)

    def put(idx, y, k):
        if len(idx) == 0: return
        o = np.lexsort((y, idx)); idx = idx[o]; y = y[o]
        first = np.ones(len(idx), bool); first[1:] = idx[1:] != idx[:-1]
        idx = idx[first]; y = y[first]
        m = y < g[idx]
        g[idx[m]] = y[m]; who[idx[m]] = k

    for k, r in enumerate(recs):
        x = np.array(r['xf'], dtype=np.float64); B = x[:9].reshape(3, 3).T; o = x[9:]
        tris = []
        for name, vo, vn, io, inn in r['surf']:
            v = V[vo:vo + vn].astype(np.float64) @ B.T + o
            tris.append(v[I[io:io + inn]].reshape(-1, 3, 3))
        if not tris: continue
        T = np.concatenate(tris)
        nrm = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0]); ln = np.linalg.norm(nrm, axis=1)
        ok = ln >= 1e-6
        T = T[ok]; T = T[np.abs(nrm[ok, 1]) / ln[ok] >= 0.5]          # ground, not wall faces
        if len(T) == 0: continue
        P = T.reshape(-1, 3)
        i = np.floor(P[:, 0] - U0).astype(np.int64); j = np.floor(P[:, 2] - V0).astype(np.int64)
        m = (i >= 0) & (i < NX) & (j >= 0) & (j < NY)
        put((j * NX + i)[m], P[m, 1], k)
        a, b, c = T[:, 0], T[:, 1], T[:, 2]
        i0 = np.maximum(0, np.floor(np.minimum.reduce([a[:, 0], b[:, 0], c[:, 0]]) - U0).astype(np.int64))
        i1 = np.minimum(NX - 1, np.floor(np.maximum.reduce([a[:, 0], b[:, 0], c[:, 0]]) - U0).astype(np.int64))
        j0 = np.maximum(0, np.floor(np.minimum.reduce([a[:, 2], b[:, 2], c[:, 2]]) - V0).astype(np.int64))
        j1 = np.minimum(NY - 1, np.floor(np.maximum.reduce([a[:, 2], b[:, 2], c[:, 2]]) - V0).astype(np.int64))
        d = (b[:, 0] - a[:, 0]) * (c[:, 2] - a[:, 2]) - (c[:, 0] - a[:, 0]) * (b[:, 2] - a[:, 2])
        good = (np.abs(d) >= 1e-9) & (i1 >= i0) & (j1 >= j0)
        key = (i1 - i0 + 1) * 100000 + (j1 - j0 + 1)
        for kk in np.unique(key[good]):
            sel = np.nonzero(good & (key == kk))[0]
            oi, oj = np.meshgrid(np.arange(int(kk // 100000)), np.arange(int(kk % 100000)))
            oi = oi.reshape(-1); oj = oj.reshape(-1)
            step = max(1, 400000 // len(oi))
            for s0 in range(0, len(sel), step):
                q = sel[s0:s0 + step]
                ci = i0[q, None] + oi[None, :]; cj = j0[q, None] + oj[None, :]
                px = U0 + ci + 0.5; pz = V0 + cj + 0.5
                A = a[q][:, None, :]; Bq = b[q][:, None, :]; C = c[q][:, None, :]; dq = d[q][:, None]
                l1 = ((Bq[..., 0] - px) * (C[..., 2] - pz) - (C[..., 0] - px) * (Bq[..., 2] - pz)) / dq
                l2 = ((C[..., 0] - px) * (A[..., 2] - pz) - (A[..., 0] - px) * (C[..., 2] - pz)) / dq
                l3 = 1.0 - l1 - l2
                ins = (l1 >= -1e-4) & (l2 >= -1e-4) & (l3 >= -1e-4)
                y = A[..., 1] * l1 + Bq[..., 1] * l2 + C[..., 1] * l3
                put((cj * NX + ci)[ins], y[ins], k)
    return g.reshape(NY, NX), who.reshape(NY, NX)


def fit_up(H, G, has, j0, i0, ax, az, g, may, SEA, n):
    """Bring the land back UP to the pieces as far as they allow (Yasin: "make sure all land is under blocks but blocks
    dont float too"). The lowering puts a node 5 cm under the LOWEST ground within its reach, which is safe but leaves
    a block's edge standing over the land where a lower terrace lies within those 4 m, and some blocks stood over the
    land before any of this. Here every node a GROWTH cell rests on is raised toward the piece ground right at the
    node (the lowest of the four 1 m cells that touch it, else the nearest piece ground) minus 5 cm, but never past
    what every piece cell it carries allows: land(cell) <= ground(cell) - 5 cm stays true for the cells of EVERY
    family, roads included. Half steps, four colours of nodes in turn (two nodes of one colour share no cell), so the
    land stays under the pieces at every moment. A node is never lowered here."""
    from scipy.ndimage import distance_transform_edt
    ny, nx = H.shape; H = H.copy(); NYc, NXc = G.shape
    elig = np.zeros(H.shape, bool)
    for dj, di in ((0, 0), (0, 1), (1, 0), (1, 1)): elig[j0[may] + dj, i0[may] + di] = True
    elig &= ~SEA; elig[:2, :] = False; elig[-2:, :] = False; elig[:, :2] = False; elig[:, -2:] = False
    Gp = np.pad(G, ((1, 1), (1, 1)), constant_values=np.inf)
    Jn = np.arange(ny) * n; In = np.arange(nx) * n
    t4 = np.minimum.reduce([Gp[np.ix_(Jn, In)], Gp[np.ix_(Jn + 1, In)], Gp[np.ix_(Jn, In + 1)], Gp[np.ix_(Jn + 1, In + 1)]])
    _, (nj, ni) = distance_transform_edt(~has, return_indices=True)
    cjn = np.clip(Jn, 0, NYc - 1); cin = np.clip(In, 0, NXc - 1)
    near = G[nj[np.ix_(cjn, cin)], ni[np.ix_(cjn, cin)]]
    target = np.where(np.isfinite(t4), t4, near) - UNDER
    off = ((0, 0), (0, 1), (1, 0), (1, 1))
    w = [(1 - ax) * (1 - az), ax * (1 - az), (1 - ax) * az, ax * az]
    nf = [(j0 + dj) * nx + (i0 + di) for dj, di in off]
    use = np.zeros(len(g), bool)
    ef = elig.reshape(-1)
    for c in range(4): use |= ef[nf[c]]
    w = [x[use] for x in w]; nf = [x[use] for x in nf]; gg = g[use] - UNDER
    par = [((j0[use] + dj) % 2) * 2 + ((i0[use] + di) % 2) for dj, di in off]
    JJ, II = np.meshgrid(np.arange(ny), np.arange(nx), indexing='ij'); colour = (JJ % 2) * 2 + (II % 2)
    H_in = H.copy(); rounds = 0
    for rnd in range(80):
        moved = 0.0
        for col in range(4):
            Hf = H.reshape(-1)
            bil = w[0] * Hf[nf[0]] + w[1] * Hf[nf[1]] + w[2] * Hf[nf[2]] + w[3] * Hf[nf[3]]
            allowed = np.full(ny * nx, np.inf)
            for c in range(4):
                m = par[c] == col
                np.minimum.at(allowed, nf[c][m], (gg[m] - (bil[m] - w[c][m] * Hf[nf[c][m]])) / w[c][m])
            new = np.minimum(target, allowed.reshape(ny, nx))
            up = elig & (colour == col) & (new > H + 1e-4)
            step = np.where(up, (new - H) * (0.5 if rnd < 70 else 1.0), 0.0)
            H += step; moved = max(moved, float(step.max()))
        rounds = rnd + 1
        if moved < 0.002 and rnd >= 4: break
    r = H - H_in
    print('FIT-UP nodes a growth cell rests on: %d; raised %d, usual %.2f m, largest %.2f m; lowered %d; rounds %d' % (
        int(elig.sum()), int((r > 0.005).sum()), float(np.median(r[r > 0.005])) if (r > 0.005).any() else 0.0, float(r.max()), int((r < -1e-9).sum()), rounds))
    return H


def ease(Hn, Hold, reach, SEA):
    """Ease the banks the lowering left (Yasin, on the picture of a block in a notch of the hillside: "lower the land
    in the places that go above the blocks"). The land nodes NO piece rests on are lowered so the drop the lowering
    made spreads smoothly through the empty land beside it: on those nodes new = old + d, where d equals the lowering
    on every node a piece rests on (0 where nothing was lowered: roads, samples, the sea, the box edge) and is harmonic
    (Laplace) between them, as terrain.py's own correction is. So the land still meets every road and every piece
    exactly as before (their nodes do not move), nothing is raised, and the empty land keeps its shape, only lower."""
    import scipy.sparse as sp
    import scipy.sparse.linalg as spla
    ny, nx = Hn.shape
    fixed = reach | SEA
    fixed[:2, :] = True; fixed[-2:, :] = True; fixed[:, :2] = True; fixed[:, -2:] = True
    free = ~fixed
    delta = np.where(fixed, Hn - Hold, 0.0)
    idx = np.full(Hn.shape, -1, np.int64); idx[free] = np.arange(int(free.sum()))
    jj, ii = np.nonzero(free); k = idx[jj, ii]
    rows = [k]; cols = [k]; vals = [np.full(len(k), 4.0)]; rhs = np.zeros(len(k))
    for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        a = jj + dj; b = ii + di; f = free[a, b]
        rows.append(k[f]); cols.append(idx[a[f], b[f]]); vals.append(np.full(int(f.sum()), -1.0))
        np.add.at(rhs, k[~f], delta[a[~f], b[~f]])
    A = sp.csc_matrix((np.concatenate(vals), (np.concatenate(rows), np.concatenate(cols))), shape=(len(k), len(k)))
    d = spla.spsolve(A, rhs)
    d[np.abs(d) < 0.005] = 0.0
    H2 = Hn.copy(); H2[jj, ii] = Hold[jj, ii] + d
    Hb = Hn.copy(); Hb[jj, ii] = Hold[jj, ii]              # the land with the banks, for the comparison

    def rim(H):
        st = []
        pj, pi = np.nonzero(reach & ~SEA)
        for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a = np.clip(pj + dj, 0, ny - 1); b = np.clip(pi + di, 0, nx - 1); m = free[a, b]
            st.append(H[a[m], b[m]] - H[pj[m], pi[m]])
        return np.concatenate(st)
    r0 = rim(Hb); r1 = rim(H2)
    print('EASE empty-land nodes %d, lowered %d (%.2f %% of the land): usual %.2f m, largest %.2f m; raised %d: usual %.2f m, largest %.2f m' % (
        len(k), int((d < 0).sum()), 100.0 * (d < 0).sum() / max(1, int((~SEA).sum())), float(np.median(-d[d < 0])) if (d < 0).any() else 0.0, float(-d.min()) if len(d) else 0.0,
        int((d > 0).sum()), float(np.median(d[d > 0])) if (d > 0).any() else 0.0, float(d.max()) if len(d) else 0.0))
    print('step from a node a piece rests on up to the empty land beside it (4 m away): over 0.5 m %d -> %d, over 1 m %d -> %d, over 2 m %d -> %d, largest %.2f -> %.2f m' % (
        int((r0 > 0.5).sum()), int((r1 > 0.5).sum()), int((r0 > 1.0).sum()), int((r1 > 1.0).sum()), int((r0 > 2.0).sum()), int((r1 > 2.0).sum()), float(r0.max()), float(r1.max())))
    print('the same step DOWN to the empty land (a piece edge standing over the land): over 0.5 m %d -> %d, over 1 m %d -> %d, largest %.2f -> %.2f m' % (
        int((r0 < -0.5).sum()), int((r1 < -0.5).sum()), int((r0 < -1.0).sum()), int((r1 < -1.0).sum()), float(-r0.min()), float(-r1.min())))
    gx = np.abs(np.diff(H2, axis=1))[:, :][free[:, 1:] & free[:, :-1]]; gz = np.abs(np.diff(H2, axis=0))[free[1:, :] & free[:-1, :]]
    g = np.concatenate([gx, gz]) / 4.0 * 100.0
    gx0 = np.abs(np.diff(Hb, axis=1))[free[:, 1:] & free[:, :-1]]; gz0 = np.abs(np.diff(Hb, axis=0))[free[1:, :] & free[:-1, :]]
    g0 = np.concatenate([gx0, gz0]) / 4.0 * 100.0
    print('slope inside the empty land: steeper than 25 %% on %d -> %d node pairs, steepest %.0f -> %.0f %%' % (int((g0 > 25).sum()), int((g > 25).sum()), float(g0.max()), float(g.max())))
    return H2


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not args: sys.exit(__doc__)
    base = args[0]; write = '--write' in sys.argv
    out = next((a.split('=', 1)[1] for a in sys.argv[1:] if a.startswith('--out=')), None)
    recs = json.load(open(base + '.json', encoding='utf-8'))
    V = np.fromfile(base + '_v.bin', '<f4').reshape(-1, 3); I = np.fromfile(base + '_i.bin', '<i4')
    need_v = max(s[1] + s[2] for r in recs for s in r['surf']); need_i = max(s[3] + s[4] for r in recs for s in r['surf'])
    if len(V) != need_v or len(I) != need_i: sys.exit('the ground dump is cut short (%d of %d vertices): dump again' % (len(V), need_v))
    t = np.load(GRID); keep = {k: t[k] for k in t.files}
    H0 = t['heights'].astype(np.float64); SEA = t['sea'].astype(bool); U0 = float(t['u0']); V0 = float(t['v0']); S = float(t['step'])
    ny, nx = H0.shape; n = int(round(S)); NX = (nx - 1) * n; NY = (ny - 1) * n
    G, WHO = raster(recs, V, I, U0, V0, NX, NY)
    has = np.isfinite(G)
    fam = [family(r['piece'], str(r.get('from', ''))) for r in recs]

    cj, ci = np.nonzero(has)
    j0 = cj // n; i0 = ci // n; az = (cj + 0.5) / n - j0; ax = (ci + 0.5) / n - i0

    def land_at(H):
        return (H[j0, i0] * (1 - ax) + H[j0, i0 + 1] * ax) * (1 - az) + (H[j0 + 1, i0] * (1 - ax) + H[j0 + 1, i0 + 1] * ax) * az

    g = G[cj, ci]; who = WHO[cj, ci]
    seacell = SEA[np.clip(np.round((cj + 0.5) / n).astype(int), 0, ny - 1), np.clip(np.round((ci + 0.5) / n).astype(int), 0, nx - 1)]
    d0 = land_at(H0) - g
    over = (d0 > -UNDER + 1e-3) & ~seacell                 # the land is not 5 cm under this cell's ground
    fams = sorted(set(fam)); fi = np.array([fams.index(f) for f in fam])[who]
    # who may ask for a node to be lowered: by default only the growth zones (the pieces built after the land was last
    # fitted). The road kit and the approved samples were fitted by terrain.py and stay as they are: their cells
    # within 5 cm are raster noise, and the waterfront sample's ground reaches under the sea level.
    askall = '--ask=all' in sys.argv
    # --only=grow_apt[,grow_wf]: of the growth zones, only these families ask and are fitted (19 Nov evening: the
    # apartment fill was merged with its ground under the land; the other zones were fitted that morning)
    only = next((a.split('=', 1)[1].split(',') for a in sys.argv[1:] if a.startswith('--only=')), None)
    may = np.array([askall or (f.startswith('grow_') and (only is None or any(f.startswith(o) for o in only))) for f in fams])[fi]
    not_asked = over & ~may
    over = over & may
    # the nodes those cells rest on
    mark = np.zeros(H0.shape, bool)
    for dj, di in ((0, 0), (0, 1), (1, 0), (1, 1)): mark[j0[over] + dj, i0[over] + di] = True
    mark &= ~SEA
    # lowest piece ground within a node's own reach: the 2n x 2n cells round it
    Gp = np.pad(G, ((0, n), (0, n)), constant_values=np.inf)
    lo = minimum_filter(Gp, size=2 * n, mode='constant', cval=np.inf)[::n, ::n][:ny, :nx]      # window k-n .. k+n-1
    chk = np.full((1, 6 * n), np.inf); chk[0, n - 1] = 1.0; chk[0, 2 * n] = 2.0
    c2 = minimum_filter(np.pad(chk, ((0, 0), (0, n)), constant_values=np.inf), size=(1, 2 * n), mode='constant', cval=np.inf)[0, ::n]
    assert c2[0] == 1.0 and c2[1] == 1.0 and c2[2] == 2.0 and c2[3] == 2.0 and not np.isfinite(c2[4]), 'window convention'
    new = lo - UNDER
    change = mark & np.isfinite(lo) & (new < H0 - 1e-9)
    H1 = np.where(change, new, H0)
    d1 = land_at(H1) - g
    left = (d1 > -UNDER + 1e-3) & ~seacell
    over_all = (d0 > -UNDER + 1e-3) & ~seacell

    land = ~SEA; cut = H0 - H1
    print('LOWER-LAND %d ground meshes, %d m2 of piece ground; land nodes %d' % (len(recs), int(has.sum()), int(land.sum())))
    print('family                     pieces |  before: not 5 cm under   >5 cm over  >30 cm over   >1 m over |  after: not 5 cm under  >5 cm over')
    npieces = collections.Counter(fam)
    for q, f in enumerate(fams):
        m = fi == q
        print('%-26s %6d | %22d %12d %12d %11d | %21d %11d' % (f, npieces[f], int((over_all & m).sum()), int(((d0 > 0.05) & m & ~seacell).sum()), int(((d0 > 0.30) & m & ~seacell).sum()),
                                                            int(((d0 > 1.0) & m & ~seacell).sum()), int((left & m).sum()), int(((d1 > 0.05) & m & ~seacell).sum())))
    print('%-26s %6d | %22d %12d %12d %11d | %21d %11d' % ('ALL', len(recs), int(over_all.sum()), int(((d0 > 0.05) & ~seacell).sum()), int(((d0 > 0.30) & ~seacell).sum()), int(((d0 > 1.0) & ~seacell).sum()),
                                                        int(left.sum()), int(((d1 > 0.05) & ~seacell).sum())))
    print('asked by: %s; cells of the other families left as they are: %d' % ('every family' if askall else 'the growth zones only', int(not_asked.sum())))
    print('land nodes that were above the sea level (0 m) and are under it now: %d; above the beach line (0.3 m) before and under it now: %d' % (
        int((land & (H0 > 0.0) & (H1 <= 0.0)).sum()), int((land & (H0 > 0.3) & (H1 <= 0.3)).sum())))
    print('island (land nodes) lowest %.2f m highest %.2f m before; lowest %.2f m highest %.2f m after' % (H0[land].min(), H0[land].max(), H1[land].min(), H1[land].max()))
    print('land nodes changed %d of %d (%.2f %%); lowered by: usual %.2f m, largest %.2f m; raised: %d; sea nodes changed: %d' % (
        int(change.sum()), int(land.sum()), 100.0 * change.sum() / land.sum(), float(np.median(cut[change])) if change.any() else 0.0, float(cut.max()), int((H1 > H0).sum()), int((change & SEA).sum())))
    # which family's cells asked for each changed node (a node can be asked by several)
    ask = collections.Counter()
    for q, f in enumerate(fams):
        mk = np.zeros(H0.shape, bool); m = over & (fi == q)
        for dj, di in ((0, 0), (0, 1), (1, 0), (1, 1)): mk[j0[m] + dj, i0[m] + di] = True
        ask[f] = int((mk & change).sum())
    print('changed nodes by the family whose ground asked for it: ' + ', '.join('%s %d' % (f, c) for f, c in sorted(ask.items(), key=lambda e: -e[1]) if c))
    # the bank at the rim: a changed node beside an unchanged land node
    bank = []; onp = []
    jj, ii = np.nonzero(change)
    for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        a = np.clip(jj + dj, 0, ny - 1); b = np.clip(ii + di, 0, nx - 1)
        m = ~change[a, b] & land[a, b]
        bank.append(np.abs(H1[a[m], b[m]] - H1[jj[m], ii[m]]))
        onp.append(np.isfinite(lo[a[m], b[m]]))
    bank = np.concatenate(bank) if bank else np.array([0.0]); onp = np.concatenate(onp) if onp else np.array([False])
    if len(bank):
        print('rim of the lowered land: %d spots, usual step to the untouched node %.2f m, largest %.2f m; over 0.5 m: %d, over 1 m: %d (beside a piece %d, beside empty land %d)' % (
            len(bank), float(np.median(bank)), float(bank.max()), int((bank > 0.5).sum()), int((bank > 1.0).sum()), int(((bank > 1.0) & onp).sum()), int(((bank > 1.0) & ~onp).sum())))
    # a block edge beside empty land that stands over the land ("floats"): the measure of ground_check.py
    hp = np.pad(has, 1, constant_values=True)
    edge = (~hp[1:-1, :-2] | ~hp[1:-1, 2:] | ~hp[:-2, 1:-1] | ~hp[2:, 1:-1])[cj, ci]

    def floats(H, txt):
        dd = g - land_at(H)
        print('%s: edge cells beside empty land standing over the land by more than 30 cm: growth %d, roads and samples %d; by more than 1 m: growth %d; largest %.2f m' % (
            txt, int((edge & may & (dd > 0.30) & ~seacell).sum()), int((edge & ~may & (dd > 0.30) & ~seacell).sum()), int((edge & may & (dd > 1.0) & ~seacell).sum()),
            float(dd[edge & may & ~seacell].max()) if (edge & may & ~seacell).any() else 0.0))
    floats(H1, 'floating, before the fit')
    if '--fit' in sys.argv:
        H1 = fit_up(H1, G, has, j0, i0, ax, az, g, may, SEA, n)
        floats(H1, 'floating, after the fit')
        d2 = land_at(H1) - g
        print('after the fit: cells with the land not 5 cm under: growth %d, roads and samples %d (before the fit %d)' % (
            int(((d2 > -UNDER + 1e-3) & ~seacell & may).sum()), int(((d2 > -UNDER + 1e-3) & ~seacell & ~may).sum()), int(not_asked.sum())))
    ease_from = next((a.split('=', 1)[1] for a in sys.argv[1:] if a.startswith('--ease-from=')), None)
    if ease_from:
        H1 = ease(H1, np.load(ease_from)['heights'].astype(np.float64), np.isfinite(lo), SEA)
        d2 = land_at(H1) - g
        print('after easing: piece cells with the land not 5 cm under, growth zones: %d; island lowest %.2f m highest %.2f m' % (int(((d2 > -UNDER + 1e-3) & ~seacell & may).sum()), H1[land].min(), H1[land].max()))
    if out or write:
        keep['heights'] = H1.astype(t['heights'].dtype)
        np.savez_compressed(GRID if write else out, **keep)
        print('written', GRID if write else out)
    else:
        print('dry run: nothing written')


if __name__ == '__main__':
    main()
