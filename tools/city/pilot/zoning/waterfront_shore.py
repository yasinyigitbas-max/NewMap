"""The shore line at the waterfront sample's pier and beach (19 Nov 2026).

Yasin, on the bird's-eye view of the waterfront: "can you erase the sand under the pier and that irregularity on the
second shot, make it smooth"; then, with two red lines drawn on the picture (one from the pier's T-head down to the
beach block's water line, one from the beach block's south corner to the coast south of it): "Yes, sand to the lines",
"make them approach smoothly like this", "and make the foam follow that line"; then, on the first result: "make the
bubbles follow sand better and unifiy it, i can see patches on it".

What was wrong: the smooth coast (coast.json, 17 Nov) ran ACROSS the beach block f_sw's own shallow water, so the
land's shore line stood as a sand bar in front of the beach with a lagoon behind it, and south of the block's corner
the bar's last nodes made a wobbly edge.

What this does (the LAND and the foam strip only; no piece but the unlocked foam strip x_shore_foam is rebuilt):
  the water line (0 m) becomes one smooth curve
    A  from the north beach's water line as it is (the foam strip's station at z ~ 190, with its own direction) to the
       beach block's OWN water line (f_sw.gd _shore_z, wavy) at z 258, arriving on it and parallel to it (a cubic);
    -  the beach block's own water line from z 258 to 299;
    B  from there, leaving parallel, to the coast's water line as it is at z ~ 326 (again a cubic).
  Land: along A and B ONE even beach face through the water line (7.5 % both ways; above 0.5 m it flattens to 2.5 %,
  under water it runs down to the sea bed), so the sand's edge is a clean line under the foam and not a saw of 4 m
  teeth. Landward it is never lower than the land there was. Where f_sw's shallow water lies landward of curve A the
  land now covers it with sand ("sand to the lines": it counts as "land over a piece" in ground_check.py from now on,
  on purpose); under water the beach face also lies over f_sw's sea bed along A (not seen). Along f_sw's own water
  line the land stays 5 cm under the block. Nodes another piece alone rests on (the quay and plaza of s_wf, f_se) and
  f_sw's dry beach are not touched. Sea flags follow the new line.
  Foam (zoning/shore_foam.json, the format of shore_foam.py): the north beach's run now follows curve A and ends ON
  the beach block's own foam line (3 m of overlap, 1 cm higher, fading out); the south coast's run now starts on the
  beach block's foam line exactly where that foam fades out (its last 2.6 m) and fades in over the same metres, so
  the two add up to one strip, then follows curve B.
Still two strips where the block's own foam comes out from under the new sand (about z 236..258): the block's foam is
part of the LOCKED piece f_sw; taking it out there needs Yasin's word.
Not changed: coast.json (terrain.py would bring the old line back: do not run it).

  python -I tools/city/pilot/zoning/waterfront_shore.py OUT/ground [--outdir=<dir> | --write]     (dry run by default)
After --write: rebuild the foam strip (pieces/x_shore_foam.gd), then bake_game_terrain.py.
"""
import json, os, sys
import numpy as np
from scipy.ndimage import minimum_filter, maximum_filter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lower_land_to_pieces as LL          # raster(), GRID, UNDER

FOAM = os.path.normpath(os.path.join(HERE, '../../../../map_dc/coronado/city_kit/zoning/shore_foam.json'))
FSW_X, FSW_Z = 570.0, 200.0          # f_sw in the layout: pos (570, 1.35, 200), yaw 90: grid x = 570 + local z, grid z = 200 - local x
FOAM_Z0, FOAM_Z1 = 212.5, 298.5      # f_sw's own foam strip (local x -12.5 .. -98.5); UV.x = 0 at z 298.5, fades over 3 %
A_Z0, A_Z1 = 190.0, 258.0            # curve A: north beach -> beach block
B_Z0, B_Z1 = 299.0, 326.0            # curve B: beach block -> south coast
SLOPE, BED = 0.075, -2.2
ROWS = np.linspace(-3.0, 4.5, 13); FADE = 6.0
WX0, WX1 = 596.0, 684.0


def sstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def beach_x(z):
    """f_sw's own water line in the grid frame (f_sw.gd _shore_z)"""
    lx = FSW_Z - np.asarray(z, float)
    w = sstep(-11.0, -24.0, lx) * sstep(-100.0, -88.0, lx)
    return FSW_X + 21.0 + 1.5 / 0.08 + w * (2.2 + 1.8 * np.sin(lx * 0.15 + 0.7) + 0.9 * np.sin(lx * 0.37 + 2.1))


def hermite(z, z0, x0, s0, z1, x1, s1):
    L = z1 - z0; t = np.clip((z - z0) / L, 0.0, 1.0)
    return (2 * t ** 3 - 3 * t ** 2 + 1) * x0 + (t ** 3 - 2 * t ** 2 + t) * s0 * L + (-2 * t ** 3 + 3 * t ** 2) * x1 + (t ** 3 - t ** 2) * s1 * L


def stations(c):
    """a foam chunk's stations (the 0 m line): row 0 lies 3 m landward along the normal"""
    v = np.array(c['v'], float).reshape(c['n'], c['rows'], 3)
    nrm = (v[:, -1, :] - v[:, 0, :]) / (ROWS[-1] - ROWS[0])
    p = v[:, 0, :] - ROWS[0] * nrm
    return p[:, [0, 2]]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not args: sys.exit(__doc__)
    base = args[0]; write = '--write' in sys.argv
    outdir = next((a.split('=', 1)[1] for a in sys.argv[1:] if a.startswith('--outdir=')), None)
    recs = json.load(open(base + '.json', encoding='utf-8'))
    V = np.fromfile(base + '_v.bin', '<f4').reshape(-1, 3); I = np.fromfile(base + '_i.bin', '<i4')
    t = np.load(LL.GRID); keep = {k: t[k] for k in t.files}
    H0 = t['heights'].astype(np.float64); SEA0 = t['sea'].astype(bool); U0 = float(t['u0']); V0 = float(t['v0']); S = float(t['step'])
    ny, nx = H0.shape; n = int(round(S))
    foam = json.load(open(FOAM, encoding='utf-8')); chunks = foam['chunks']

    # ---- the two foam runs that end / start at the beach block, and the curves' anchors on them
    ends = [stations(c) for c in chunks]
    kn = min(range(len(chunks)), key=lambda k: np.hypot(ends[k][-1, 0] - 639.0, ends[k][-1, 1] - 204.0))
    ks = min(range(len(chunks)), key=lambda k: np.hypot(ends[k][0, 0] - 605.0, ends[k][0, 1] - 309.0))
    PN, PS = ends[kn], ends[ks]
    if np.hypot(PN[-1, 0] - 639.0, PN[-1, 1] - 204.0) > 6 or np.hypot(PS[0, 0] - 605.0, PS[0, 1] - 309.0) > 6:
        sys.exit('the foam runs at the pier / the south corner are not where they were: already applied? (git checkout the land and shore_foam.json first)')
    icut = int(np.argmax(PN[:, 1] >= A_Z0))
    a0 = PN[icut - 1]; sa = np.polyfit(PN[icut - 8:icut, 1], PN[icut - 8:icut, 0], 1)[0]
    jj = int(np.argmax(PS[:, 1] >= B_Z1)); b1 = PS[jj]; sb = np.polyfit(PS[jj:jj + 8, 1], PS[jj:jj + 8, 0], 1)[0]
    az0 = float(a0[1]); bz1 = float(b1[1])
    dbx = lambda z: float(beach_x(z + 0.25) - beach_x(z - 0.25)) / 0.5

    def xs(z):
        z = np.asarray(z, float)
        return np.where(z <= A_Z1, hermite(z, az0, a0[0], sa, A_Z1, float(beach_x(A_Z1)), dbx(A_Z1)),
                        np.where(z < B_Z0, beach_x(z), hermite(z, B_Z0, float(beach_x(B_Z0)), dbx(B_Z0), bz1, b1[0], sb)))

    # ---- land
    G, WHO = LL.raster(recs, V, I, U0, V0, (nx - 1) * n, (ny - 1) * n)
    k_fsw = [r['piece'] for r in recs].index('f_sw')
    lo = minimum_filter(np.pad(G, ((0, n), (0, n)), constant_values=np.inf), size=2 * n, mode='constant', cval=np.inf)[::n, ::n][:ny, :nx]
    r_fsw = maximum_filter(np.pad((WHO == k_fsw).astype(np.uint8), ((0, n), (0, n))), size=2 * n, mode='constant', cval=0)[::n, ::n][:ny, :nx] > 0
    r_oth = maximum_filter(np.pad(((WHO >= 0) & (WHO != k_fsw)).astype(np.uint8), ((0, n), (0, n))), size=2 * n, mode='constant', cval=0)[::n, ::n][:ny, :nx] > 0
    XX = U0 + S * np.arange(nx)[None, :] + 0 * np.arange(ny)[:, None]; ZZ = V0 + S * np.arange(ny)[:, None] + 0 * np.arange(nx)[None, :]
    inz = (ZZ > az0) & (ZZ < bz1) & (XX >= WX0) & (XX <= WX1)
    x_s = xs(ZZ); dxs = (xs(ZZ + 0.5) - xs(ZZ - 0.5)); cosn = 1.0 / np.sqrt(1.0 + dxs * dxs)
    d = (XX - x_s) * cosn                                         # metres seaward of the water line
    tsea = np.maximum(-SLOPE * d, np.minimum(H0, BED))            # the beach face going on under the water
    a_ = -d; tland = np.minimum(SLOPE * a_, 0.35 + 0.025 * a_)
    H1 = H0.copy()
    curve = (ZZ <= A_Z1) | (ZZ >= B_Z0)                           # along A / B (not along f_sw's own water line)
    sea_side = d >= 0
    free = inz & ~r_fsw & ~r_oth
    H1[free & sea_side] = tsea[free & sea_side]
    m = free & ~sea_side; H1[m] = np.maximum(tland[m], H0[m])
    fs = inz & r_fsw & (XX >= 611.0)                              # f_sw rests on it; the node columns from x 612 seaward
    m = fs & sea_side & curve; H1[m] = tsea[m]                    # one even beach face under the water too (no teeth)
    m = fs & sea_side & ~curve; H1[m] = np.minimum(tsea[m], lo[m] - LL.UNDER)
    m = fs & ~sea_side & curve; H1[m] = np.maximum(tland[m], np.minimum(H0[m], lo[m] - LL.UNDER))
    m = fs & ~sea_side & ~curve; H1[m] = np.minimum(H0[m], lo[m] - LL.UNDER)      # along f_sw's own line the land stays under it
    touched = free | fs
    SEA1 = np.where(touched, d >= -4.0, SEA0)                     # as elsewhere: the flag starts at the +0.3 m line
    ch = np.abs(H1 - H0) > 1e-9
    print('WATERFRONT-SHORE anchors: north (%.1f, %.1f) direction %.2f -> beach line (%.1f, %.1f) direction %.2f; beach line (%.1f, %.1f) -> south (%.1f, %.1f) direction %.2f' % (
        a0[0], a0[1], sa, float(beach_x(A_Z1)), A_Z1, dbx(A_Z1), float(beach_x(B_Z0)), B_Z0, b1[0], b1[1], sb))
    print('land nodes changed %d: lowered %d (largest %.2f m), raised %d (largest %.2f m); nodes another piece alone rests on changed: %d; sea flags changed: %d' % (
        int(ch.sum()), int((H1 < H0 - 1e-9).sum()), float((H0 - H1).max()), int((H1 > H0 + 1e-9).sum()), float((H1 - H0).max()), int((ch & r_oth & ~r_fsw).sum()), int((SEA1 != SEA0).sum())))
    cj, ci = np.nonzero(WHO == k_fsw); j0 = cj // n; i0 = ci // n; az = (cj + 0.5) / n - j0; ax = (ci + 0.5) / n - i0

    def land(H):
        return (H[j0, i0] * (1 - ax) + H[j0, i0 + 1] * ax) * (1 - az) + (H[j0 + 1, i0] * (1 - ax) + H[j0 + 1, i0 + 1] * ax) * az
    g = G[cj, ci]; cx = U0 + ci + 0.5; cz = V0 + cj + 0.5; dry = cx < xs(cz)
    print('f_sw ground cells %d. Land over the ground by more than 5 cm: %d -> %d; of those ABOVE the water (the sand the lines ask for): %d -> %d' % (
        len(g), int((land(H0) - g > 0.05).sum()), int((land(H1) - g > 0.05).sum()), int(((land(H0) - g > 0.05) & (land(H0) > 0)).sum()), int(((land(H1) - g > 0.05) & (land(H1) > 0)).sum())))
    # how even is the sand's edge: the land along the water line itself should be 0
    zz = np.arange(az0 + 2, bz1 - 2, 0.5); xl = xs(zz)
    fx = (xl - U0) / S; fz = (zz - V0) / S; i_ = fx.astype(int); j_ = fz.astype(int); tx = fx - i_; ty = fz - j_
    hl = lambda H: H[j_, i_] * (1 - tx) * (1 - ty) + H[j_, i_ + 1] * tx * (1 - ty) + H[j_ + 1, i_] * (1 - tx) * ty + H[j_ + 1, i_ + 1] * tx * ty
    cu = (zz <= A_Z1) | (zz >= B_Z0)
    print('land height ON the new water line along A and B: usual %.2f m, worst %.2f m (0 = the sand ends exactly under the foam)' % (float(np.median(np.abs(hl(H1)[cu]))), float(np.abs(hl(H1)[cu]).max())))

    # ---- foam: the north run's new tail along curve A, the south run's new head along curve B
    def hs(u, v):
        fx = np.clip((u - U0) / S, 0, nx - 1.001); fy = np.clip((v - V0) / S, 0, ny - 1.001)
        i = fx.astype(int); j = fy.astype(int); tx = fx - i; ty = fy - j
        return H1[j, i] * (1 - tx) * (1 - ty) + H1[j, i + 1] * tx * (1 - ty) + H1[j + 1, i] * (1 - tx) * ty + H1[j + 1, i + 1] * tx * ty

    def resample(z0, z1):
        zs_ = np.linspace(z0, z1, 3000); p = np.c_[xs(zs_), zs_]
        dd = np.r_[0, np.cumsum(np.hypot(*np.diff(p, axis=0).T))]
        s = np.arange(0.0, dd[-1], 1.0)
        return np.c_[np.interp(s, dd, p[:, 0]), np.interp(s, dd, p[:, 1])]

    def strip(r, lift):
        tg = np.gradient(r, axis=0); tg /= np.linalg.norm(tg, axis=1)[:, None]
        nr = np.c_[tg[:, 1], -tg[:, 0]]
        if np.median(nr[:, 0]) < 0: nr = -nr                       # seaward is east here
        verts = np.zeros((len(r), len(ROWS), 3))
        for k_, o in enumerate(ROWS):
            pu = r[:, 0] + o * nr[:, 0]; pv = r[:, 1] + o * nr[:, 1]
            verts[:, k_, 0] = pu; verts[:, k_, 2] = pv; verts[:, k_, 1] = np.maximum(hs(pu, pv), 0.0) + 0.02 + lift
        return verts
    cn, cs = chunks[kn], chunks[ks]
    vn = np.array(cn['v'], float).reshape(cn['n'], cn['rows'], 3); vs = np.array(cs['v'], float).reshape(cs['n'], cs['rows'], 3)
    # north: old stations up to z 190, then curve A, then 3 m ON the block's own foam line (1 cm higher: no flicker), fading out
    newA = resample(az0, A_Z1 + 3.0)[1:]
    rA = np.r_[PN[max(0, icut - 6):icut], newA]; k0 = min(6, icut)
    vA = strip(rA, np.where(rA[:, 1] > A_Z1 - 6.0, 0.01, 0.0))[k0:]
    vN = np.concatenate([vn[:icut], vA]); L = len(vN) - 1
    uxN = np.r_[np.array(cn['ux'][:icut], float), np.full(len(vA), 0.5)]
    idx = np.arange(len(vN)); uxN = np.where(idx > L - FADE, 1.0 - (L - idx) / FADE * 0.03, uxN)
    # south: starts ON the block's foam line where that foam fades out (its UV.x 0.03 .. 0: z 295.92 .. 298.5) and fades in
    # over the same metres (the two smoothsteps add up to 1), then curve B, then the old stations from z ~ 326
    fz0 = FOAM_Z1 - 0.03 * (FOAM_Z1 - FOAM_Z0)
    newB = resample(fz0, bz1)[:-1]
    rB = np.r_[newB, PS[jj:jj + 6]]
    vB = strip(rB, np.where(rB[:, 1] < FOAM_Z1 + 1.0, 0.01, 0.0))[:len(newB)]
    vS = np.concatenate([vB, vs[jj:]])
    uxS = np.r_[np.clip((newB[:, 1] - fz0) / (FOAM_Z1 - fz0), 0.0, 1.0) * 0.03, np.array(cs['ux'][jj:], float)]
    uxS = np.where((uxS >= 0.03) & (np.arange(len(uxS)) < len(newB)), 0.5, uxS)
    for c, v_, ux_ in ((cn, vN, uxN), (cs, vS, uxS)):
        c['n'] = int(len(v_)); c['v'] = [round(float(x), 3) for x in v_.ravel()]; c['ux'] = [round(float(x), 4) for x in ux_]
    print('foam: north run chunk %d: %d -> %d stations, now ends at (%.1f, %.1f); south run chunk %d: %d -> %d stations, now starts at (%.1f, %.1f)' % (
        kn, len(vn), len(vN), newA[-1, 0], newA[-1, 1], ks, len(vs), len(vS), newB[0, 0], newB[0, 1]))
    if outdir or write:
        keep['heights'] = H1.astype(t['heights'].dtype); keep['sea'] = SEA1.astype(t['sea'].dtype)
        gp = LL.GRID if write else os.path.join(outdir, 'terrain_grid.npz'); fp = FOAM if write else os.path.join(outdir, 'shore_foam.json')
        np.savez_compressed(gp, **keep); json.dump(foam, open(fp, 'w'))
        print('written', gp, 'and', fp)
    else:
        print('dry run: nothing written')


if __name__ == '__main__':
    main()
