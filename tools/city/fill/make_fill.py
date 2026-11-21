#!/usr/bin/env python3
"""THE FILL (21 Nov 2026, Yasin: "fill all of the empty space in the map somehow, that places that doesn't have ground or
any objects in it. Both in and out of the ring road ... cover around the island with sand, rock beaches and sea. And find
the tiny gaps without anything on them and fill them"; then "no pilot ... do the full fill straight through").

What it is (said plainly, see coronado-super-builder law 1): a GENERATOR for the ground and its dressing of the empty land
only. Yasin asked for 2.3 km2 at once; one hand-written line per prop was not possible in one sitting. It never touches,
moves or re-runs an existing piece: new pieces fl_<cx>_<cz>, one per 200 m cell of the grid (the bake's cell), in world
coordinates (layout pos [0, 0, 0]). Their rules and reasons are below, per surface and per prop kind. Run once; a fix to
one piece later is a hand change to that piece (the superchecker's way), not a re-run.

Reads OUT/fill/fields.npz (tools/city/fill/fields.py) and writes OUT/fill/pieces/<name>.json + .bin (meshes, props, the
lagoons' water), which tools/city/fill/build_fill.gd turns into pieces/fl_*.scn.

THE GROUND (one draw a cell in the bake; materials g_fill_*, the kit's ground textures + 2 new layers of the ground
array: gray_rocks (a cobble beach) and rock030 (bluff rock)):
  - the shore: SAND from below the water (follows the terrain under the sea to ~1.5 m deep, so the sea at 0 m cuts it on
    the terrain's 0 m line, where the locked foam strip lies) up to the dunes, 26-62 m wide (low-frequency noise), only
    where the land is under 3 m; darker wet sand along the water (tint). COBBLE / RIPRAP where the ring road or a street
    comes within ~70 m of the water (a revetment protects the road, as on the real Coronado bay side) and on the west
    point (the island's exposed end), with rock boulders on it; ROCK on the steep bluff faces (slope over 1 : 4).
  - inland: one GRASS ground (grass004) whose colour runs smoothly from green (by the streets, in the city gaps) to dry
    straw (wide noise, and toward the dunes) by the vertex tint (polish 1: the old lawn / meadow texture cut read as
    blotches from the air), decomposed-granite TRAILS (gravel tint): one
    coastal path along the dunes and cross paths from the ring road's corners to the beaches.
  - the lagoons (zoning/coast.json ponds in the empty west): a bowl under a still water surface, reeds of dry tufts.
  - the small gaps inside the city: LAWN, eased to the neighbours' edges (4 cm under them, tucked 0.35 m under).
  - every vertex: smooth normals from the height field; a tint from three scales of noise, so a lawn or a meadow is
    never one flat colour and the texture's tiling breaks up.
"""
import json, os, sys, math, zlib
import numpy as np, shapely
from shapely.geometry import LineString, Polygon, Point
from scipy import ndimage as ndi

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../.."))
OUT = os.path.join(ROOT, "OUT/fill")
CELL = 200.0
GRID = 2.0
RNG = np.random.default_rng(2111)

MATS = {   # name: [texture, tile m, roughness, tint]
    "lawn": ["res://map_dc/coronado/terrain/textures/grass004/grass_albedo.jpg", 3.0, 0.95, [0.85, 0.95, 0.8]],
    "meadow": ["res://map_dc/coronado/terrain/textures/ground037/dry_albedo.jpg", 4.0, 0.97, [0.95, 0.97, 0.86]],
    "sand": ["res://map_dc/coronado/terrain/textures/ground054/sand_albedo.jpg", 3.0, 0.97, [0.93, 0.87, 0.74]],
    "cobble": ["res://map_dc/coronado/terrain/textures/gray_rocks/gray_rocks_diff_1k.jpg", 2.5, 0.9, [0.86, 0.84, 0.8]],
    "rock": ["res://map_dc/coronado/terrain/textures/rock030/rock_albedo.jpg", 5.0, 0.92, [0.82, 0.78, 0.72]],
    "trail": ["res://map_dc/coronado/terrain/textures/gravel022/gravel_albedo.jpg", 2.0, 0.95, [0.97, 0.86, 0.7]],
}

# trails (grid frame), from the ring road's west and south corners to the beaches; Chaikin-smoothed
TRAILS = [
    [(-1003, -1400), (-1150, -1385), (-1350, -1335), (-1550, -1300), (-1690, -1280)],
    [(-1003, -800), (-1200, -765), (-1420, -705), (-1600, -650), (-1720, -630)],
    [(-1003, -200), (-1180, -240), (-1380, -185), (-1560, -125), (-1735, -95)],
    [(-1003, 200), (-1150, 262), (-1300, 380), (-1400, 500), (-1450, 600)],
    [(-500, 337), (-520, 450), (-485, 575)],
    [(150, 347), (170, 460), (140, 565)],
]


def chaikin(p, n=3):
    p = np.asarray(p, float)
    for _ in range(n):
        q = np.empty((2 * len(p) - 2, 2)); q[0::2] = 0.75 * p[:-1] + 0.25 * p[1:]; q[1::2] = 0.25 * p[:-1] + 0.75 * p[1:]
        p = np.vstack([p[:1], q, p[-1:]])
    return p


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)


class Raster:
    def __init__(self, a, x0, z0, res): self.a = a.astype(np.float32); self.x0 = x0; self.z0 = z0; self.res = res

    def __call__(self, p):
        fx = (p[:, 0] - self.x0) / self.res - 0.5; fz = (p[:, 1] - self.z0) / self.res - 0.5
        H, W = self.a.shape
        fx = np.clip(fx, 0, W - 1.001); fz = np.clip(fz, 0, H - 1.001)
        i = fx.astype(int); j = fz.astype(int); tx = fx - i; tz = fz - j
        a = self.a
        return a[j, i] * (1 - tx) * (1 - tz) + a[j, i + 1] * tx * (1 - tz) + a[j + 1, i] * (1 - tx) * tz + a[j + 1, i + 1] * tx * tz


def noise(shape, sigma, seed):
    r = np.random.default_rng(seed).standard_normal(shape).astype(np.float32)
    r = ndi.gaussian_filter(r, sigma, mode='wrap')
    r /= r.std() + 1e-9
    return 0.5 + 0.5 * np.tanh(r * 0.8)          # ~0..1, mean 0.5


def split(tris, f):
    """cut a triangle soup (N,3,2) along f = 0 (f evaluated per vertex, roots by linear interpolation); returns (pos, neg)"""
    if len(tris) == 0: return tris, tris
    v = f(tris.reshape(-1, 2)).reshape(-1, 3)
    pos = v > 0; n = pos.sum(1)
    P = [tris[n == 3]]; N = [tris[n == 0]]
    for k, lone_pos in ((1, True), (2, False)):
        m = n == k
        if not m.any(): continue
        T = tris[m]; V = v[m]; S = pos[m]
        lone = np.argmax(S, 1) if lone_pos else np.argmin(S, 1)
        idx = (lone[:, None] + np.arange(3)[None, :]) % 3
        T = np.take_along_axis(T, idx[:, :, None], 1); V = np.take_along_axis(V, idx, 1)
        a, b, c = T[:, 0], T[:, 1], T[:, 2]; va, vb, vc = V[:, 0:1], V[:, 1:2], V[:, 2:3]
        pab = a + (va / (va - vb)) * (b - a); pac = a + (va / (va - vc)) * (c - a)
        t1 = np.stack([a, pab, pac], 1)
        q1 = np.stack([pab, b, c], 1); q2 = np.stack([pab, c, pac], 1)
        (P if lone_pos else N).append(t1); (N if lone_pos else P).extend([q1, q2])
    P = np.concatenate(P); N = np.concatenate(N)
    return _clean(P), _clean(N)


def _clean(T):
    if len(T) == 0: return T
    e1 = T[:, 1] - T[:, 0]; e2 = T[:, 2] - T[:, 0]
    return T[np.abs(e1[:, 0] * e2[:, 1] - e1[:, 1] * e2[:, 0]) > 2e-4]


def subdivide(T):
    a, b, c = T[:, 0], T[:, 1], T[:, 2]; ab = (a + b) / 2; bc = (b + c) / 2; ca = (c + a) / 2
    return np.concatenate([np.stack([a, ab, ca], 1), np.stack([ab, b, bc], 1), np.stack([ca, bc, c], 1), np.stack([ab, bc, ca], 1)])


def main():
    F = np.load(os.path.join(OUT, 'fields.npz'))
    x0 = float(F['x0']); z0 = float(F['z0']); res = float(F['res'])
    dom = F['dom']; H, W = dom.shape
    print('make_fill: fields loaded', flush=True)
    dsd = (ndi.distance_transform_edt(dom) - ndi.distance_transform_edt(~dom)).astype(np.float32) * res
    R = lambda a: Raster(a, x0, z0, res)
    f_dom = R(dsd); f_h = R(F['h']); f_d0 = R(F['d0']); f_sd = R(F['sd']); f_road = R(F['droad'])
    gap = (F['gapid'] > 0)
    f_gap = R(ndi.gaussian_filter(gap.astype(np.float32), 2))
    # noise at 2 m (a 4 m and 1 m version by sampling); seeded, so a re-run gives the same island
    s2 = (H // 4 + 1, W // 4 + 1)
    R2 = lambda a: Raster(a, x0, z0, 2.0)
    n_low = R2(noise(s2, 40, 1)); n_mid = R2(noise(s2, 9, 2)); n_fine = R2(noise(s2, 2.0, 3)); n_grove = R2(noise(s2, 30, 4)); n_rock = R2(noise(s2, 25, 5))
    n_px = Raster(noise((H // 2 + 1, W // 2 + 1), 1.2, 6), x0, z0, 1.0)
    # rock zones: a street within 70 m of the water (revetment), the west point, outcrops by noise along the shore
    d0a = F['d0']; road_m = F['droad']
    XX0 = x0 + (np.arange(W) + 0.5) * res
    ZZ0 = z0 + (np.arange(H) + 0.5) * res
    rz = ((road_m < 70) & (d0a < 45) & (d0a > -20)).astype(np.float32)
    wp = ((ZZ0[:, None] > -930) & (ZZ0[:, None] < -400) & (XX0[None, :] < -1660)).astype(np.float32)
    rz = np.maximum(rz, wp)
    rz = ndi.gaussian_filter(rz[::4, ::4], 4)
    f_rz = R2(rz)
    print('make_fill: rasters ready', flush=True)
    trails = [LineString(chaikin(t, 4)) for t in TRAILS]
    ponds = json.load(open(os.path.join(OUT, 'ponds.json')))
    pond_polys = [(p['id'], Polygon(p['poly']), p['level']) for p in ponds]

    def trail_dist(p):
        pts = shapely.points(p[:, 0], p[:, 1])
        d = np.full(len(p), 1e9)
        for t in trails: d = np.minimum(d, shapely.distance(t, pts))
        return d

    def d0s(p): return f_d0(p)

    def beach_w(p): return 26 + 36 * n_low(p) + 5 * (n_mid(p) - 0.5)

    def slope(p):
        e = 0.75
        gx = (f_h(p + [e, 0]) - f_h(p - [e, 0])) / (2 * e); gz = (f_h(p + [0, e]) - f_h(p - [0, e])) / (2 * e)
        return np.hypot(gx, gz)

    def relief_amp(p):
        # rock relief: the bluff faces and the cobble / riprap, fading out at their edges (continuous everywhere)
        sl = slope(p)
        d0 = d0s(p)
        a_rock = 0.35 * smoothstep(0.16, 0.3, sl) * smoothstep(80, 60, d0)
        a_cob = 0.07 * smoothstep(0.35, 0.65, f_rz(p)) * smoothstep(-6, -1, d0) * (1 - smoothstep(10, 18, d0))
        return a_rock + a_cob

    def height(p):
        return f_h(p) + relief_amp(p) * (n_px(p) - 0.5) * 2.0

    # the coastal path: the line 70 m in from the water, where the land is wide enough; as a distance field
    def coast_path(p):
        d0 = d0s(p); sd = f_sd(p)
        return np.where((sd > 10), np.abs(d0 - (beach_w(p) + 22)), 1e9)

    def label_fields():
        return {
            'keep': lambda p: f_dom(p),
            'gap': lambda p: f_gap(p) - 0.5,
            'coast': lambda p: np.minimum(beach_w(p) - d0s(p) + 6 * (n_fine(p) - 0.5), (3.0 - f_h(p)) * 8),
            'cobble': lambda p: np.minimum(f_rz(p) - 0.5 + 0.2 * (n_mid(p) - 0.5), 14 + 4 * n_fine(p) - d0s(p)),
            'rock': lambda p: np.minimum(slope(p) - 0.25, 0.02 * (80 - d0s(p))),      # (rock faces only on the coast's bluffs)
            'trail': lambda p: 1.3 - np.minimum(trail_dist(p), coast_path(p)) + np.where(f_sd(p) < 3, -9, 0),
            'lawn': lambda p: np.maximum(0.62 - n_grove(p) * 0.4 - n_mid(p) * 0.6 + 0.25 * smoothstep(20, 0, f_road(p)), 0.3 - n_low(p)) - 0.12,
            'pond_edge': None,
        }

    L = label_fields()
    # the cells that need a piece
    cells = set()
    jj, ii = np.nonzero(dom[::8, ::8])
    for j, i in zip(jj, ii):
        cx = math.floor((x0 + (i * 8 + 0.5) * res) / CELL); cz = math.floor((z0 + (j * 8 + 0.5) * res) / CELL)
        cells.add((cx, cz))
    # tiny gaps (under 8 cells of 4 m) are caught by the full-resolution test
    jj, ii = np.nonzero(dom & gap)
    for j, i in zip(jj[::50], ii[::50]):
        cells.add((math.floor((x0 + (i + 0.5) * res) / CELL), math.floor((z0 + (j + 0.5) * res) / CELL)))
    cells = sorted(cells)
    print('make_fill: %d cells' % len(cells), flush=True)
    summary = []
    for (cx, cz) in cells:
        name = 'fl_%s_%s' % (('m%d' % -cx) if cx < 0 else cx, ('m%d' % -cz) if cz < 0 else cz)
        X0, Z0 = cx * CELL, cz * CELL
        xs = np.arange(X0, X0 + CELL + 0.01, GRID); zs = np.arange(Z0, Z0 + CELL + 0.01, GRID)
        gx, gz = np.meshgrid(xs, zs)
        n = len(xs)
        A = np.stack([gx, gz], -1)
        a = A[:-1, :-1].reshape(-1, 2); b = A[:-1, 1:].reshape(-1, 2); c = A[1:, 1:].reshape(-1, 2); d = A[1:, :-1].reshape(-1, 2)
        T = np.concatenate([np.stack([a, b, c], 1), np.stack([a, c, d], 1)])
        # quick reject: triangles whose vertices are all well outside the domain
        v = f_dom(T.reshape(-1, 2)).reshape(-1, 3)
        T = T[v.max(1) > -2.5]
        if len(T) == 0: continue
        # finer (1 m, then 0.5 m) near the domain's edge (the tuck under the neighbours), on rock, and in the small gaps
        cen = T.mean(1)
        fine = (np.abs(f_dom(cen)) < 3) | (relief_amp(cen) > 0.02) | (f_gap(cen) > 0.05)
        T = np.concatenate([T[~fine], subdivide(T[fine])])
        cen = T.mean(1)
        fine2 = (np.abs(f_dom(cen)) < 1.2) & (f_gap(cen) > 0.05)
        T = np.concatenate([T[~fine2], subdivide(T[fine2])])
        T, _ = split(T, L['keep'])
        if len(T) == 0: continue
        out = {}
        G, T = split(T, L['gap'])
        out['lawn_g'] = G
        C, I = split(T, L['coast'])
        # the coast: cobble where the rock zone is, else sand; rock faces on the steep parts
        CB, CS = split(C, L['cobble'])
        RK1, CB = split(CB, L['rock']); RK2, CS = split(CS, L['rock'])
        RK3, I = split(I, L['rock'])
        TR, I = split(I, L['trail'])
        # polish 1 (21 Nov): no lawn / meadow cut any more (two textures meeting on a hard noise line read as blotches
        # from the air); one grass ground, its green .. dry straw drawn by the vertex tint below (smooth, 2 m vertices)
        surf = {'sand': CS, 'cobble': CB, 'rock': np.concatenate([RK1, RK2, RK3]), 'trail': TR, 'lawn': np.concatenate([I, G])}
        total = sum(len(s) for s in surf.values())
        if total == 0: continue
        bins = []; meta = {'name': name, 'cell': [cx, cz], 'surfaces': [], 'props': [], 'ponds': []}
        for m, S in surf.items():
            if len(S) == 0: continue
            P = S.reshape(-1, 2)
            y = height(P)
            e = 0.5
            gxh = (height(P + [e, 0]) - height(P - [e, 0])) / (2 * e); gzh = (height(P + [0, e]) - height(P - [0, e])) / (2 * e)
            N = np.stack([-gxh, np.ones_like(gxh), -gzh], 1); N /= np.linalg.norm(N, axis=1)[:, None]
            tile = MATS[m][1]
            UV = P / tile
            # the tint: three scales of noise; wet sand darker near the water; meadow greener in the hollows
            nl = n_low(P); nm = n_mid(P); nf = n_fine(P)
            k = 1.0 + 0.16 * (nl - 0.5) + 0.20 * (nm - 0.5) + 0.12 * (nf - 0.5)      # (polish 2: more mid / fine variation, flat grass read plain)
            col = np.stack([k, k, k], 1)
            if m in ('meadow', 'lawn'):
                # dryness: wide soft noise, drier toward the beach and on the bluffs, greener by the streets and in the
                # small city gaps (watered); the result goes green (0) .. straw (1) by a smooth ramp, no edges
                d0 = d0s(P); fr = f_road(P)
                dry = smoothstep(0.30, 0.78, 0.65 * nl + 0.35 * nm)
                dry = np.maximum(dry, 0.85 * smoothstep(beach_w(P) + 40, beach_w(P) + 4, d0))
                dry = dry * (1 - 0.75 * smoothstep(30, 6, fr)) * (1 - f_gap(P).clip(0, 1))
                dry = np.clip(dry + 0.10 * (nf - 0.5), 0, 1)
                green = np.array([1.0, 1.0, 1.0]); straw = np.array([1.25, 1.02, 0.74])      # (x the material's tint)
                col *= green[None, :] * (1 - dry)[:, None] + straw[None, :] * dry[:, None]
            if m == 'sand':
                d0 = d0s(P); wet = smoothstep(9, 0, d0) * 0.22 + smoothstep(0, -3, d0) * 0.1
                col *= (1 - wet)[:, None]; col[:, 2] *= 1 - 0.05 * wet
            if m == 'cobble':
                d0 = d0s(P); col *= (1 - 0.25 * smoothstep(6, -1, d0))[:, None]
            col = np.clip(col, 0.5, 1.25)
            V3 = np.stack([P[:, 0], y, P[:, 1]], 1)
            # winding: Godot front faces are clockwise seen from the front (from above: (b-a)x(c-a) points down)
            V3t = V3.reshape(-1, 3, 3)
            nrm = np.cross(V3t[:, 1] - V3t[:, 0], V3t[:, 2] - V3t[:, 0])
            flip = nrm[:, 1] > 0
            V3t[flip] = V3t[flip][:, [0, 2, 1]]
            idxs = np.arange(len(V3t) * 3).reshape(-1, 3)
            order = np.where(flip[:, None], [0, 2, 1], [0, 1, 2])
            perm = np.take_along_axis(idxs, order, 1).reshape(-1)
            V3 = V3t.reshape(-1, 3); N = N[perm]; UV = UV[perm]; col = col[perm]
            # index identical vertices (shared grid points): the builder indexes again; keep it simple here
            off = sum(len(b) for b in bins)
            blob = np.concatenate([V3, N, UV, col], 1).astype('<f4').tobytes()
            meta['surfaces'].append({'mat': m, 'count': len(V3), 'offset': off})
            bins.append(blob)
        # ---- the lagoons whose centre is in this cell
        for pid, poly, lvl in pond_polys:
            cc = poly.centroid
            if X0 <= cc.x < X0 + CELL and Z0 <= cc.y < Z0 + CELL:
                meta['ponds'].append({'id': pid, 'level': lvl, 'poly': [list(q) for q in poly.buffer(1.5).simplify(0.4).exterior.coords]})
        meta['props'] = props_for(name, X0, Z0, height, f_dom, f_sd, f_d0, f_road, f_gap, n_grove, n_mid, n_fine, beach_w, slope, f_rz, trails, pond_polys, f_h)
        with open(os.path.join(OUT, 'pieces', name + '.bin'), 'wb') as fh:
            for b_ in bins: fh.write(b_)
        meta['tris'] = total
        json.dump(meta, open(os.path.join(OUT, 'pieces', name + '.json'), 'w'))
        summary.append((name, total, len(meta['props']), len(meta['ponds'])))
        print('make_fill: %s tris %d props %d ponds %d' % summary[-1], flush=True)
    json.dump({'pieces': [s[0] for s in summary], 'rows': summary}, open(os.path.join(OUT, 'pieces', 'index.json'), 'w'))
    print('make_fill: %d pieces, %d ground triangles, %d props' % (len(summary), sum(s[1] for s in summary), sum(s[2] for s in summary)))


def props_for(name, X0, Z0, height, f_dom, f_sd, f_d0, f_road, f_gap, n_grove, n_mid, n_fine, beach_w, slope, f_rz, trails, pond_polys, f_h):
    """the dressing of one cell; every kind with its reason. Seeded by the cell, so a cell's props do not depend on
    another cell. Each prop stands on the lowest of its footprint's corners (never floats), 3 cm in."""
    rng = np.random.default_rng(zlib.crc32(name.encode()))
    out = []

    def put(base, cond, x, z, yaw, collide=True, scale=1.0, r=0.6):
        # polish 2 render review: the kit's lawn patch has a rectangular perimeter, visible as black frames at grazing
        # angles; omit that prop rather than cover the island in frames. Iceplant is a small dune mat, not a giant bush.
        if base == 'plant_lawn_patch': return
        if base == 'plant_iceplant_patch': scale *= 0.4
        p = np.array([[x, z], [x + r, z], [x - r, z], [x, z + r], [x, z - r]])
        y = float(height(p).min()) - 0.03
        out.append([base, cond, round(float(x), 3), round(y, 3), round(float(z), 3), round(float(yaw), 1), bool(collide), round(float(scale), 3)])

    def cand(nper, margin):
        """candidate points: a jittered grid, nper per 10,000 m2, at least `margin` m inside the fill and off every piece"""
        k = max(1, int(nper))
        s = 100.0 / math.sqrt(k)
        g = np.arange(s / 2, CELL, s)
        gx, gz = np.meshgrid(g, g)
        P = np.stack([X0 + gx.ravel() + rng.uniform(-s * 0.45, s * 0.45, gx.size), Z0 + gz.ravel() + rng.uniform(-s * 0.45, s * 0.45, gx.size)], 1)
        ok = (f_dom(P) > margin) & (f_sd(P) > margin + 0.5)
        return P[ok]

    def near_trail(P, w):
        pts = shapely.points(P[:, 0], P[:, 1]); d = np.full(len(P), 1e9)
        for t in trails: d = np.minimum(d, shapely.distance(t, pts))
        return d < w

    # TREES: groves of Torrey pine (native to the San Diego coast) and eucalyptus (planted windbreaks, everywhere in
    # Coronado's parks) on the meadow, in the noise's "grove" patches, at least 60 m from any street (the in-view cap:
    # no more than 12 trees within 60 m of a street point is kept by staying away), never on the sand or a trail; a
    # few lone pines nearer the streets, 30 m apart at least.
    P = cand(110, 4.0)
    if len(P):
        d0 = f_d0(P); rd = f_road(P); gv = n_grove(P)
        ok = (d0 > beach_w(P) + 14) & (gv > 0.66) & (rd > 60) & ~near_trail(P, 4.0) & (slope(P) < 0.15) & (f_gap(P) < 0.05)
        for x, z in P[ok]:
            sp = rng.random()
            base = 'tree_torrey_pine_a' if sp < 0.38 else 'tree_torrey_pine_b' if sp < 0.66 else 'tree_eucalyptus_a' if sp < 0.85 else 'tree_eucalyptus_b'
            put(base, 'normal', x, z, rng.uniform(0, 360), True, rng.uniform(0.8, 1.15), 0.8)
    P = cand(4, 5.0)
    if len(P):
        d0 = f_d0(P); rd = f_road(P)
        ok = (d0 > beach_w(P) + 14) & (rd > 18) & (rd <= 60) & ~near_trail(P, 4.0) & (slope(P) < 0.15) & (f_gap(P) < 0.05)
        for x, z in P[ok][:2]:
            put('tree_torrey_pine_a' if rng.random() < 0.5 else 'tree_torrey_pine_b', 'normal', x, z, rng.uniform(0, 360), True, rng.uniform(0.75, 1.0), 0.8)
    # MEADOW TUFTS: dry tufts and green tufts break the ground's flatness at eye height (lawn patch, no collider)
    P = cand(70, 1.5)
    if len(P):
        d0 = f_d0(P); ok = (d0 > beach_w(P) + 4) & ~near_trail(P, 2.0) & (f_gap(P) < 0.05) & (f_road(P) > 4)
        for x, z in P[ok]:
            put('plant_lawn_patch', 'dry' if n_mid(np.array([[x, z]]))[0] > 0.45 else 'normal', x, z, rng.uniform(0, 360), False, rng.uniform(0.8, 1.3), 1.5)
    # DUNES: iceplant mats and agaves where the meadow meets the sand (the planted dune edge of the Coronado beaches)
    P = cand(380, 1.2)
    if len(P):
        d0 = f_d0(P); bw = beach_w(P)
        ok = (d0 > bw - 8) & (d0 < bw + 16) & ~near_trail(P, 2.0) & (n_fine(P) > 0.38) & (f_rz(P) < 0.4)
        for x, z in P[ok]:
            r = rng.random()
            if r < 0.84: put('plant_iceplant_patch', 'normal', x, z, rng.uniform(0, 360), False, rng.uniform(0.9, 1.6), 1.2)
            elif r < 0.96: put('plant_agave_americana_small', 'normal', x, z, rng.uniform(0, 360), True, rng.uniform(0.8, 1.2), 0.6)
            else: put('plant_agave_americana', 'normal', x, z, rng.uniform(0, 360), True, rng.uniform(0.8, 1.1), 0.8)
    # RIPRAP: boulders and piles on the cobble / revetment, densest at the waterline (the sea's edge is armoured)
    P = cand(1100, 0.8)
    if len(P):
        d0 = f_d0(P); rz = f_rz(P)
        ok = (rz > 0.55) & (d0 > -4) & (d0 < 12 + 4 * n_fine(P))
        for x, z in P[ok]:
            r = rng.random(); sc = rng.uniform(1.1, 2.4) if f_d0(np.array([[x, z]]))[0] < 5 else rng.uniform(0.9, 1.6)
            base = 'prop_riprap_boulder' if r < 0.55 else 'prop_riprap_pile' if r < 0.85 else 'prop_riprap_slope'
            put(base, 'dirty' if rng.random() < 0.6 else 'worn', x, z, rng.uniform(0, 360), True, sc, 0.9 * sc)
    # THE BEACH: where a trail reaches the sand, a lifeguard tower facing the water, the rules sign and the rip sign
    # beside it, and a bench on the dune looking out (people come down the trail to swim here)
    for t in trails:
        coords = np.array(t.coords)
        end = coords[-1]
        if not (X0 <= end[0] < X0 + CELL and Z0 <= end[1] < Z0 + CELL): continue
        # walk back along the trail to the point ~32 m from the water on the sand, and 60 m (dune top)
        dist = np.r_[0, np.cumsum(np.hypot(*np.diff(coords, axis=0).T))]
        s = np.linspace(0, dist[-1], 400)
        pts = np.c_[np.interp(s, dist, coords[:, 0]), np.interp(s, dist, coords[:, 1])]
        d0 = f_d0(pts)
        sea = pts[-1] - pts[-12]; yaw_sea = math.degrees(math.atan2(sea[0], sea[1]))
        side = np.array([sea[1], -sea[0]]) / (np.linalg.norm(sea) + 1e-9)
        k = int(np.argmin(np.abs(d0 - 30)))
        if abs(d0[k] - 30) < 6:
            p = pts[k] + side * 9
            put('prop_lifeguard_tower', 'worn', p[0], p[1], yaw_sea, True, 1.0, 2.0)
            q = p + side * 3.2; put('prop_beach_sign_rip', 'worn', q[0], q[1], yaw_sea + 180, True)
            q = pts[k] - side * 3.0; put('prop_beach_sign_rules', 'worn', q[0], q[1], yaw_sea + 180, True)
        k = int(np.argmin(np.abs(d0 - (beach_w(pts[k:k + 1])[0] + 10))))
        for o in (-4.5, 4.5):
            q = pts[k] + side * o
            if f_sd(q[None])[0] > 3: put('prop_park_bench', 'worn', q[0], q[1], yaw_sea, True)
    # THE SMALL GAPS in the city: a lawn with low planting along it (agave, bougainvillea), nothing tall
    P = cand(600, 0.6)
    if len(P):
        ok = (f_gap(P) > 0.6)
        for x, z in P[ok]:
            if rng.random() < 0.5: continue
            r = rng.random()
            if r < 0.5: put('plant_agave_americana_small', 'normal', x, z, rng.uniform(0, 360), True, 1.0, 0.6)
            elif r < 0.7: put('plant_bougainvillea_mound', 'normal', x, z, rng.uniform(0, 360), True, rng.uniform(0.7, 1.0), 1.4)
            else: put('plant_lawn_patch', 'normal', x, z, rng.uniform(0, 360), False, 1.0, 1.5)
    # THE LAGOONS: dry tufts as reeds round the water, iceplant on the banks
    for pid, poly, lvl in pond_polys:
        if not poly.intersects(Polygon([(X0, Z0), (X0 + CELL, Z0), (X0 + CELL, Z0 + CELL), (X0, Z0 + CELL)])): continue
        ring = poly.buffer(2.5).exterior
        L = ring.length
        for s in np.arange(0, L, 2.2):
            q = ring.interpolate(s + rng.uniform(-0.6, 0.6)); x, z = q.x, q.y
            if not (X0 <= x < X0 + CELL and Z0 <= z < Z0 + CELL): continue
            if f_dom(np.array([[x, z]]))[0] < 1: continue
            if rng.random() < 0.8: put('plant_lawn_patch', 'dry', x, z, rng.uniform(0, 360), False, rng.uniform(0.9, 1.4), 1.2)
            else: put('plant_iceplant_patch', 'normal', x, z, rng.uniform(0, 360), False, 1.2, 1.2)
    return out


if __name__ == '__main__':
    main()
