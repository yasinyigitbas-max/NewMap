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
    may = np.array([askall or f.startswith('grow_') for f in fams])[fi]
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
    if out or write:
        keep['heights'] = H1.astype(t['heights'].dtype)
        np.savez_compressed(GRID if write else out, **keep)
        print('written', GRID if write else out)
    else:
        print('dry run: nothing written')


main()
