"""Terrain height map for the whole island (17 Nov, integration step; Python, CPU-light).

The ground the city kit sits on, on a 4 m grid in the grid frame (u, v), built from what is approved and locked:
  desired   the approved hill field with the snapped samples' flat aprons + the eased real ground (streets.height_fn,
            the same ground the skeleton and the grading plan were checked on); offshore: the real sea floor
  fixed     - every street at its exact profile: level junction tiles at the grading pads, blocks rising with the kit's
              smoothstep between the tiles, the corridor out to the property lines (ring blocks follow their polylines)
            - every locked sample's footprint at its pad (the waterfront at 1.35 m: its walk 1.5 m above the sea)
            - the sea (outside the smooth coast, coast.json) at its floor, the shore line itself at +0.3 m (beach)
  solve     terrain = desired + c, where c is harmonic (Laplace) between the fixed cells: the ground meets every street,
            pad and shore exactly with no step, and keeps the hills' shape inside the blocks
  surface   pieces cover the streets and samples; the terrain sits 5 cm under their road level there (no z-fight)
17 Nov, terrain step 2-3 (Yasin: "no jagged edges, elevations smooth, no jumps"):
  - fitted to the pieces AS BUILT (zoning/piece_ground.npz from piece_ground.gd): every node whose bilinear support
    touches a piece sits 5 cm under the lowest piece ground there, then fit_edges() raises the nodes beside the
    pieces as far as they allow, so the ground meets the walk / kerb edges flush (terrain_check.gd: 0 shows through)
  - the beach from the smooth coast POLYLINES (true distance), so the water line is a smooth curve, not 4 m steps
  - the box is 300 m wider on the land sides and its outer node rings take today's ground: the game bake
    (bake_game_terrain.py) joins today's terrain with no seam
Outputs map_dc/coronado/city_kit/zoning/terrain_grid.npz (u0, v0, step, heights [v, u], covered mask) and
zoning/terrain.png (hillshade, 1 m contours, streets, coast) and prints the checks (slopes off the streets, steps at
the fixed edges, the coast).
"""
import json, os, math, sys
import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla
import shapely
from shapely.geometry import Polygon, LineString

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(HERE, "../../../../map_dc/coronado/city_kit")
sys.path.insert(0, HERE)
STEP = 4.0
U0, U1, V0, V1 = -1600.0, 1700.0, -1900.0, 760.0      # 18 Nov: +300 m west, +700 m east (Yasin: the east bay shore gets our beach too, not the old steep bank)
HALF = {"res": 9.2, "std": 9.2, "hs": 16.0, "cc": 16.0, "couplet": 14.3, "ind": 8.7, "strip": 8.7, "ring": 14.3, "bridge": 12.0}
TILE = 20.0          # junction tile half size (the level pad)


def ss(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3 - 2 * t)


def fit_edges(Ht, R, pg, near, desired, fixed, free, idx, M, UU, VV):
    """Raise the nodes beside the pieces as far as the pieces allow, so the ground meets every walk / kerb edge flush.
    Constraint (every 1 m piece cell p): bilinear terrain(p) <= ground(p) - 0.05. Target per near node: the piece ground
    right at the node (its own 1 m cell, else the nearest within 4 m) - 0.05. Projected raising, 40 rounds, then the
    free nodes are re-solved (Laplace) against the new near nodes so the hills stay smooth."""
    from scipy.ndimage import distance_transform_edt
    ny, nx = Ht.shape
    pu0, pv0 = float(pg["u0"]), float(pg["v0"])
    fin = np.isfinite(R)
    _, (ij, ii) = distance_transform_edt(~fin, return_indices=True)
    nearestR = R[ij, ii]
    ci = np.clip(np.round(UU - pu0).astype(int), 0, R.shape[1] - 1); cj = np.clip(np.round(VV - pv0).astype(int), 0, R.shape[0] - 1)
    target = np.where(near, nearestR[cj, ci] - 0.05, Ht)
    # the piece cells: their 4 nodes + bilinear weights
    pj, pi = np.nonzero(fin)
    pu = pu0 + pi + 0.5; pv = pv0 + pj + 0.5
    fx = (pu - U0) / STEP; fy = (pv - V0) / STEP
    i0 = np.clip(np.floor(fx).astype(int), 0, nx - 2); j0 = np.clip(np.floor(fy).astype(int), 0, ny - 2)
    tx = fx - i0; ty = fy - j0
    nodes = [(j0, i0, (1 - tx) * (1 - ty)), (j0, i0 + 1, tx * (1 - ty)), (j0 + 1, i0, (1 - tx) * ty), (j0 + 1, i0 + 1, tx * ty)]
    lim = R[pj, pi] - 0.05
    T = Ht.copy()
    terr0 = sum(T[a, b] * w for a, b, w in nodes)
    print("edge fit: overshoot before %.3f m at %d cells" % ((terr0 - lim).max(), ((terr0 - lim) > 0.001).sum()))
    for it in range(40):
        terr = sum(T[a, b] * w for a, b, w in nodes)
        slack = lim - terr
        allow = np.full(T.shape, np.inf)
        for a, b, w in nodes:
            ok = w > 0.02
            np.minimum.at(allow, (a[ok], b[ok]), slack[ok] / w[ok])
        want = np.where(near, target - T, 0.0)
        step = np.clip(np.minimum(want, 0.25 * allow), 0.0, None)
        step[~near] = 0.0
        T += step
        if step.max() < 0.002:
            break
    terr = sum(T[a, b] * w for a, b, w in nodes)
    print("edge fit: %d rounds, max overshoot %.3f m (must be <= 0)" % (it + 1, (terr - lim).max()))
    # re-solve the free nodes against the raised near nodes
    n = int(free.sum())
    cfix = np.where(fixed, T - desired, 0.0)
    rhs = np.zeros(n)
    fy_, fx_ = np.nonzero(free); k = idx[fy_, fx_]
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        yy = fy_ + dy; xx = fx_ + dx
        ok = (yy >= 0) & (yy < ny) & (xx >= 0) & (xx < nx)
        yy2 = yy[ok]; xx2 = xx[ok]; k2 = k[ok]
        nb = ~free[yy2, xx2]
        np.add.at(rhs, k2[nb], cfix[yy2[nb], xx2[nb]])
    sol, info = spla.cg(M, rhs, rtol=1e-6, maxiter=4000)
    c = cfix.copy(); c[free] = sol
    return desired + c


def main():
    import streets as ST
    from load import terrain
    from grid import O, A, B
    sites = json.load(open(os.path.join(KIT, "review/sites.json")))
    coast = json.load(open(os.path.join(KIT, "zoning/coast.json")))
    us = np.arange(U0, U1 + 1e-6, STEP); vs = np.arange(V0, V1 + 1e-6, STEP)
    UU, VV = np.meshgrid(us, vs)
    ny, nx = UU.shape
    print("grid %d x %d = %d cells" % (nx, ny, nx * ny))
    # ---- desired ground: hills + eased real ground on land, the real sea floor offshore
    h = ST.height_fn()
    desired = h(UU, VV)
    m, Hraw, C = terrain()
    ox, oz = m["origin_xz"]
    X = O[0] + B[0] * UU + A[0] * VV; Z = O[1] + B[1] * UU + A[1] * VV
    real = Hraw[np.clip(((Z - oz) / 4).astype(int), 0, Hraw.shape[0] - 1), np.clip(((X - ox) / 4).astype(int), 0, Hraw.shape[1] - 1)]
    sea_poly = None
    lines = [np.array(l) for l in coast["sea"]]
    # the land: the largest closed region bounded by the sea lines and the box (build from the island polygon)
    land = np.zeros(UU.shape, bool)
    import matplotlib
    matplotlib.use("Agg")
    from matplotlib.path import Path
    pts = np.stack([UU.ravel(), VV.ravel()], 1)
    for l in lines:
        if len(l) > 50:
            # close an open line along the box edge on the land side is ambiguous: use the coast tracer's own mask
            pass
    # rebuild the smooth sea mask exactly as coast.py did (same smoothing), on this grid, for an unambiguous inside test
    import coast as CO
    cut = Polygon(__import__("plan").CUT)
    cls = C[np.clip(((Z - oz) / m["class_res"]).astype(int), 0, C.shape[0] - 1), np.clip(((X - ox) / m["class_res"]).astype(int), 0, C.shape[1] - 1)]
    seam = np.isin(cls, [0, 7]) | shapely.contains_xy(cut, X, Z)
    cut_line = LineString(list(cut.exterior.coords)[:6])
    dcut = shapely.distance(cut_line, shapely.points(X.ravel(), Z.ravel())).reshape(X.shape)
    s12 = CO.blur(seam.astype(float), 12.0 / STEP); s45 = CO.blur(seam.astype(float), 45.0 / STEP)
    w = np.clip((250.0 - dcut) / 150.0, 0.0, 1.0)
    seaf = s12 * (1 - w) + s45 * w
    sea = seaf > 0.5
    shore = (seaf > 0.35) & (seaf <= 0.5)          # the land band right at the water line
    # the sea floor: a beach runs into the water at about 8 % until it meets the real depth (no drop at the shore line)
    from scipy.ndimage import distance_transform_edt
    # (17 Nov, terrain step 2) the beach from the SMOOTH coast lines, not from the 4 m sea mask: the true distance to
    # the coast polylines (sign from the sea mask, unambiguous a few metres out) gives a beach profile whose water line
    # is a smooth curve (the mask distance stair-stepped it: Yasin "not minecraft")
    from shapely.geometry import MultiLineString
    cl = MultiLineString([[tuple(p) for p in l] for l in lines if len(l) > 1])
    dvec = shapely.distance(cl, shapely.points(UU.ravel(), VV.ravel())).reshape(UU.shape)
    sd = np.where(sea, -dvec, dvec)               # metres, land positive
    dshore = np.maximum(-sd, 0.0)
    # the sea floor: the beach runs on under the water at 8 %, then keeps deepening ~2 % (no flat shelf over the cut's
    # old land and no step down to the old sea floor: Yasin "the beach eases into the sea")
    desired = np.where(sea, np.maximum(np.minimum(real, -0.5 - 0.02 * dshore), 0.3 - 0.08 * dshore), desired)
    # ---- fixed cells
    fixed = np.zeros(UU.shape, bool); fval = np.zeros(UU.shape)
    covered = np.zeros(UU.shape, bool)       # under a piece: the terrain sits 5 cm under the road there
    def fix(mask, val, cover=True):
        nonlocal fixed, fval, covered
        fixed |= mask; fval = np.where(mask, val, fval)
        if cover: covered |= mask
    pad = {(round(n["u"], 1), round(n["v"], 1)): n["pad"] for n in sites["nodes"]}
    samp = {(round(n["u"], 1), round(n["v"], 1)): n["sample"] for n in sites["nodes"] if n.get("sample")}
    # samples: footprints at their pads (the waterfront at 1.35 m)
    for k, ((u, v), yaw, rect, legs) in ST.SNAP.items():
        x0, x1, z0, z1 = rect
        if k == "V": z1 = 360.0
        a = math.radians(yaw)
        poly = Polygon([(u + x * math.cos(a) + z * math.sin(a), v - x * math.sin(a) + z * math.cos(a)) for x, z in [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]])
        msk = shapely.contains_xy(poly, UU, VV)
        p = 1.35 if k == "W" else pad[(round(float(u), 1), round(float(v), 1))]
        if k == "P":
            # the pilot is not flat: its hill rows climb +5.9 m from x 40 to 150 (site.gd hill, the approved pilot)
            full = np.zeros(UU.shape); full[msk] = p + 5.9 * ss((UU[msk] - u - 40.0) / 110.0) - 0.05
            fix(msk, full)
        else:
            fix(msk, p - 0.05)
    # streets: each block's corridor at its profile; junction tiles level
    for b in sites["blocks"]:
        half = HALF.get(b["section"], 9.2)
        a_ = np.array(b["a"], float); c_ = np.array(b["b"], float)
        if b.get("rise_a_to_b") is None:
            continue          # a hero leg without a planned profile (the bridge off-ramp starts ON the approach): its piece sets it
        ha = pad.get((round(a_[0], 1), round(a_[1], 1)), 0.0); hb = ha + b["rise_a_to_b"]
        line = np.array(b["pts"], float) if b.get("pts") else np.array([a_, c_])
        ls = LineString(line)
        L = ls.length
        corr = ls.buffer(half, cap_style="flat")
        msk = shapely.contains_xy(corr, UU, VV) & ~sea
        if not msk.any():
            continue
        s = np.array([ls.project(shapely.Point(x, y)) for x, y in zip(UU[msk], VV[msk])])
        # the profile: smoothstep between the junction tiles; a locked sample's leg is flat (ROADKIT_SPEC 6), so the
        # rise happens between the sample leg's end (100 m; the pilot's 10th St east: its own hill to 150 m) and the
        # far tile
        sa = samp.get((round(a_[0], 1), round(a_[1], 1))); sb = samp.get((round(c_[0], 1), round(c_[1], 1)))
        s0 = 100.0 if sa else TILE; s1 = L - (100.0 if sb else TILE)
        prof = ha + (hb - ha) * ss((s - s0) / max(s1 - s0, 1.0))
        if sa == "P" and b["name"] == "10th St":
            pil = 5.9 * ss((s - 40.0) / 110.0)
            prof = np.where(s <= 150.0, ha + pil, ha + 5.9 + (hb - ha - 5.9) * ss((s - 150.0) / max(L - TILE - 150.0, 1.0)))
        full = np.zeros(UU.shape); full[msk] = prof - 0.05
        fix(msk, full)
    for n in sites["nodes"]:
        msk = (np.abs(UU - n["u"]) <= TILE + 2) & (np.abs(VV - n["v"]) <= TILE + 2) & ~sea
        fix(msk, n["pad"] - 0.05)
    # ---- the pieces AS BUILT (17 Nov, terrain step 2): piece_ground.npz = the lowest ground surface of every placed
    # piece per 1 m cell (tools/city/pilot/zoning/piece_ground.gd over city_grid_layout.json). A node whose bilinear
    # support (+-4 m) touches a piece sits 5 cm under the LOWEST piece ground in that support, so the terrain never
    # shows through a road, kerb or walk and meets the pieces' outer edges with no step. Where no piece is near (the
    # hero gaps the bridge and the ferry will fill), the planned street profiles above stay.
    pgf = os.path.join(KIT, "zoning/piece_ground.npz")
    if os.path.exists(pgf):
        from scipy.ndimage import minimum_filter, binary_dilation
        pg = np.load(pgf); R = pg["ground"].astype(float)
        # piece ground under the water (the waterfront's boat ramp toe) does not shape the shore: the beach keeps its
        # smooth water line, the submerged ramp end may sit under the sand
        from scipy.ndimage import binary_dilation as _bd
        sea_n = _bd(sea, iterations=2)                    # the sea + 8 m
        rj = np.clip(np.round((float(pg["v0"]) + 0.5 + np.arange(R.shape[0]) - V0) / STEP).astype(int), 0, sea.shape[0] - 1)
        ri = np.clip(np.round((float(pg["u0"]) + 0.5 + np.arange(R.shape[1]) - U0) / STEP).astype(int), 0, sea.shape[1] - 1)
        R = np.where((R < 0.1) & sea_n[rj[:, None], ri[None, :]], np.nan, R)
        Rf = np.where(np.isfinite(R), R, np.inf)
        mw = minimum_filter(Rf, size=9, mode="constant", cval=np.inf)
        ci = np.clip(np.round(UU - float(pg["u0"])).astype(int), 0, R.shape[1] - 1)
        cj = np.clip(np.round(VV - float(pg["v0"])).astype(int), 0, R.shape[0] - 1)
        mwn = mw[cj, ci]
        near = np.isfinite(mwn)
        far = ~binary_dilation(near, iterations=5)          # 20 m clear of every piece: the plan still rules there
        fixed &= far; covered &= far; fval = np.where(far, fval, 0.0)
        fixed |= near; fval = np.where(near, mwn - 0.05, fval); covered |= near
        print("pieces: %d nodes under / beside a piece; plan-only nodes kept %d" % (near.sum(), (fixed & far).sum()))
    # the box edges (17 Nov, terrain step 3): where the city's land meets the land the city kit does not cover (the
    # naval air station to the west, the Glorietta side to the east), the outermost 3 node rings take today's ground,
    # so the game bake joins the two with no seam; the solve blends them smoothly across the open land inside
    ring = np.zeros(UU.shape, bool); ring[:, :3] = True; ring[:, -3:] = True; ring[:3, :] = True; ring[-3:, :] = True
    edge_land = ring & ~sea & (real > 0.3) & ~covered
    fix(edge_land, real, cover=False)
    print("box edge nodes on today's ground: %d" % edge_land.sum())
    # the sea and the shore band
    fix(sea, desired, cover=False)
    # the land side of the beach: 0.3 m at the coast line (+4 % over its first 4 m); same smooth distance
    band = ~sea & (sd < 4.0) & ~covered      # only the water line itself: inland of it the solve ramps up to the pieces
    fix(band, 0.3 + 0.04 * np.clip(sd, 0.0, None), cover=False)
    # ---- solve the harmonic correction c (Laplace) with c = fval - desired on the fixed cells
    idx = -np.ones(UU.shape, int)
    free = ~fixed
    idx[free] = np.arange(free.sum())
    n = int(free.sum())
    print("fixed %d, free %d" % (fixed.sum(), n))
    cfix = np.where(fixed, fval - desired, 0.0)
    rows, cols, vals = [], [], []
    rhs = np.zeros(n)
    fy, fx = np.nonzero(free)
    k = idx[fy, fx]
    diag = np.zeros(n)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        yy = fy + dy; xx = fx + dx
        ok = (yy >= 0) & (yy < ny) & (xx >= 0) & (xx < nx)
        diag[ok] += 1.0
        yy2 = yy[ok]; xx2 = xx[ok]; k2 = k[ok]
        nb_free = free[yy2, xx2]
        rows.append(k2[nb_free]); cols.append(idx[yy2[nb_free], xx2[nb_free]]); vals.append(-np.ones(nb_free.sum()))
        np.add.at(rhs, k2[~nb_free], cfix[yy2[~nb_free], xx2[~nb_free]])
    rows.append(np.arange(n)); cols.append(np.arange(n)); vals.append(diag)
    M = sp.csr_matrix((np.concatenate(vals), (np.concatenate(rows), np.concatenate(cols))), shape=(n, n))
    sol, info = spla.cg(M, rhs, rtol=1e-6, maxiter=4000)
    print("cg info", info)
    c = cfix.copy(); c[free] = sol
    Ht = desired + c
    if os.path.exists(pgf):
        Ht = fit_edges(Ht, R, pg, near, desired, fixed, free, idx, M, UU, VV)
    # ---- checks
    gy, gx = np.gradient(Ht, STEP)
    slope = np.hypot(gx, gy)
    landfree = ~sea & ~covered
    print("slope off the streets / pads: p50 %.1f %%, p99 %.1f %%, max %.1f %%" % tuple(100 * np.percentile(slope[landfree], q) for q in (50, 99, 100)))
    edge = covered & ~np.roll(covered, 1, 0)
    print("land heights: min %.1f, max %.1f m; covered by pieces %.1f %%" % (Ht[~sea].min(), Ht[~sea].max(), 100 * covered.mean()))
    np.savez_compressed(os.path.join(KIT, "zoning/terrain_grid.npz"), u0=U0, v0=V0, step=STEP, heights=Ht.astype(np.float32), covered=covered, sea=sea)
    # ---- picture: hillshade + contours + streets + coast
    import matplotlib.pyplot as plt
    ls_ = np.clip(1.0 - (gx * 0.6 + gy * 0.6) * 4.0, 0.4, 1.4)
    rgb = np.dstack([np.where(sea, 0.47, 0.86), np.where(sea, 0.67, 0.84), np.where(sea, 0.80, 0.76)]) * ls_[..., None]
    rgb = np.clip(rgb, 0, 1)
    fig, ax = plt.subplots(figsize=(16, 18), dpi=100)
    ax.imshow(rgb, extent=[U0, U1, V1, V0])
    cs = ax.contour(us, vs, np.where(sea, np.nan, Ht), levels=np.arange(0, 30, 1.0), colors="#6d4c1f", linewidths=0.4)
    ax.clabel(cs, cs.levels[::2], fmt="%d m", fontsize=6)
    for b in sites["blocks"]:
        line = np.array(b["pts"], float) if b.get("pts") else np.array([b["a"], b["b"]])
        ax.plot(line[:, 0], line[:, 1], color="#333", lw=1.2)
    for l in lines:
        ax.plot(l[:, 0], l[:, 1], color="#1565c0", lw=1.2)
    ax.set_xlim(U0, U1); ax.set_ylim(V1, V0); ax.set_aspect("equal")
    ax.set_title("Terrain draft: streets and pads exact, hills kept in the blocks, smooth coast (grid frame, north up-left)")
    plt.savefig(os.path.join(KIT, "zoning/terrain.png"), bbox_inches="tight")
    print("ok")


if __name__ == "__main__":
    main()
