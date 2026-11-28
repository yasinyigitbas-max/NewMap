#!/usr/bin/env python3
"""THE HOLES (28 Nov night; Yasin: "There are holes which can show the emptiness below on the map", then "fix the holes in
the ground too", "make sure the patches blend in with whats around them perfectly").

What it is: one new piece, fx_holes, of ground patches in the places on the island where no piece has any ground (seams
between pieces, a block left empty). It never touches an existing piece. Each patch is the ground BESIDE it, carried on:
  - the material of the nearest ground triangle (paint, kerbs, walls and tactile strips are never copied: the ground
    under them is), its UVs carried on by that triangle's own UV mapping (the texture runs on across the seam, not just
    the same picture), its vertex colour (the fill's tint, a street's grime) taken at the nearest point;
  - heights smooth from the edges in (a membrane over the neighbours' heights: no step at the seam, no bump inside);
  - one cell (0.5 m) further under the neighbours, 4 cm lower, so no sliver of nothing is left where the edges meet and
    nothing flickers (the patch's own edge is 2 cm under the neighbour's, at most).
Holes are not filled where a building stands in them (unseen; its floor is its own), nor within 3 m of the sea (the
ferry slip and the like are water on purpose).

  python -I tools/city/fill/fill_holes.py plan     -> OUT/fill/holes_plan.npz, OUT/fill/holes_neighbours.txt, a report
  godot --headless --path . -s res://tools/city/fill/dump_ground_attr.gd -- --names=$(cat OUT/fill/holes_neighbours.txt)
  python -I tools/city/fill/fill_holes.py make     -> OUT/fill/pieces/fx_holes.json + .bin
  (after the build and a dump of fx_holes: python -I tools/city/fill/fill_holes.py check -> what is still open)
  godot --headless --path . -s res://tools/city/fill/build_holes.gd          -> pieces/fx_holes.scn
Reads the superchecker's ground read-outs (OUT/super/dump, tools/city/super/sc_dump.gd) and city_grid_layout.json.
"""
import hashlib, json, math, os, sys
import numpy as np
from scipy import ndimage
from scipy.spatial import cKDTree
import shapely
from shapely.geometry import Polygon
from PIL import Image

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../.."))
CK = os.path.join(ROOT, 'map_dc/coronado/city_kit')
DUMP = os.path.join(ROOT, 'OUT/super/dump')
OUT = os.path.join(ROOT, 'OUT/fill')
ATTR = os.path.join(OUT, 'attr')
RES = 0.5
X0, X1, Z0, Z1 = -1800.0, 1900.0, -1950.0, 900.0
W = int((X1 - X0) / RES); H = int((Z1 - Z0) / RES)
NO_COPY = {'white', 'yellow', 'tactile', 'curb', 'wall', ''}     # never carried into a patch
SEA_KEEP = 6          # cells (3 m): a hole this near the sea is left as it is
DROP = 0.04           # the ring under the neighbours, this much lower


def yaw_mat(deg):
    a = math.radians(deg); c = math.cos(a); s = math.sin(a)
    return np.array([[c, 0.0, s], [0.0, 1.0, 0.0], [-s, 0.0, c]])


def inside(Q, cx, cz, A, eps):
    r = np.ones(len(cx), bool)
    for k in range(3):
        a = Q[:, k]; b = Q[:, (k + 1) % 3]
        e = ((b[:, 0] - a[:, 0]) * (cz - a[:, 1]) - (b[:, 1] - a[:, 1]) * (cx - a[:, 0])) * A
        ln = np.hypot(b[:, 0] - a[:, 0], b[:, 1] - a[:, 1]) + 1e-9
        r &= e / ln >= -eps
    return r


def raster(T, lab, owner):
    """cells whose centre is inside a triangle (xz) get `owner`; T [n,3,3] city coords, top-down"""
    P = np.stack([(T[..., 0] - X0) / RES - 0.5, (T[..., 2] - Z0) / RES - 0.5], -1)
    e1 = P[:, 1] - P[:, 0]; e2 = P[:, 2] - P[:, 0]
    area = e1[:, 0] * e2[:, 1] - e1[:, 1] * e2[:, 0]
    keep = np.abs(area) > 1e-4
    P = P[keep]; area = area[keep]
    if not len(P): return
    lo = np.floor(P.min(1) - 0.01).astype(int); hi = np.ceil(P.max(1) + 0.01).astype(int)
    span = (hi - lo).max(1); eps = 0.02 / RES
    for small in (True, False):
        sel = span <= 12 if small else span > 12
        if not sel.any(): continue
        if small:
            Q = P[sel]; L = lo[sel]; A = np.sign(area[sel])
            for di in range(13):
                for dj in range(13):
                    cx = L[:, 0] + di; cz = L[:, 1] + dj
                    ok = inside(Q, cx, cz, A, eps) & (cx >= 0) & (cx < W) & (cz >= 0) & (cz < H)
                    lab[cz[ok], cx[ok]] = owner
        else:
            for q, l, h, a in zip(P[sel], lo[sel], hi[sel], np.sign(area[sel])):
                xs = np.arange(max(l[0], 0), min(h[0] + 1, W)); zs = np.arange(max(l[1], 0), min(h[1] + 1, H))
                if not len(xs) or not len(zs): continue
                XX, ZZ = np.meshgrid(xs, zs)
                ok = inside(np.repeat(q[None], XX.size, 0), XX.ravel(), ZZ.ravel(), np.full(XX.size, a), eps)
                lab[ZZ.ravel()[ok], XX.ravel()[ok]] = owner


def layout():
    return [r for r in json.load(open(os.path.join(CK, 'city_grid_layout.json')))['instances']]


def plan(check=False):
    lay = layout()
    lab = np.zeros((H, W), np.int32)
    bld = []; cache = {}
    for k, r in enumerate(lay):
        p = r['piece']
        if p.startswith('w_') or (p == 'fx_holes' and not check): continue
        if p not in cache:
            dj = os.path.join(DUMP, p + '.json')
            if not os.path.exists(dj): cache[p] = None; continue
            j = json.load(open(dj, encoding='utf-8'))
            f = np.fromfile(dj[:-5] + '.bin', '<f4')
            G = [f[s['off']:s['off'] + s['tris'] * 9].reshape(-1, 3, 3).astype(np.float64) for g in j['ground'] for s in g['surf'] if s['tris']]
            # (the parks' and ponds' own meshes are ground too: a tennis court, a pond. Their box's footprint, two triangles,
            # counts as covered: the first run laid paving under the courts, where it fought them)
            for m in j.get('meshes', []):
                if not ((m['path'].startswith('Parks/') and m['name'] == 'near') or m['name'].startswith('pond_')): continue
                a = m['aabb']; xf = np.array(m['xf'], float); B = xf[:9].reshape(3, 3).T; o = xf[9:12]   # (basis columns x, y, z)
                cs = [np.array([a[0] + dx * a[3], a[1], a[2] + dz * a[5]]) for dx, dz in ((0, 0), (1, 0), (1, 1), (0, 1))]
                cs = [B @ c + o for c in cs]
                G.append(np.array([[cs[0], cs[1], cs[2]], [cs[0], cs[2], cs[3]]], float))
            cache[p] = (np.concatenate(G) if G else None, [b['xf'][9:12] for b in j.get('buildings', [])])
        c = cache[p]
        if c is None: continue
        R = yaw_mat(float(r.get('yaw', 0))); pos = np.array(r.get('pos', [0, 0, 0]), float)
        for o in c[1]: bld.append(np.array(o) @ R.T + pos)
        if c[0] is not None: raster(c[0] @ R.T + pos, lab, k + 1)
    coast = json.load(open(os.path.join(CK, 'zoning/coast.json')))
    island = Polygon(coast['sea'][0]).buffer(0)
    xs = X0 + (np.arange(W) + 0.5) * RES; zs = Z0 + (np.arange(H) + 0.5) * RES
    XX, ZZ = np.meshgrid(xs, zs)
    land = shapely.contains_xy(island, XX, ZZ)
    sm = json.load(open(os.path.join(ROOT, 'tools/city/look/sea_map.json')))
    simg = np.array(Image.open(os.path.join(ROOT, 'tools/city/look/sea_map.png')).convert('RGB'))
    si = np.clip(np.round((XX - sm['x0']) / sm['step']).astype(int), 0, simg.shape[1] - 1)
    sj = np.clip(np.round((ZZ - sm['z0']) / sm['step']).astype(int), 0, simg.shape[0] - 1)
    water = simg[sj, si, 1] > 127
    empty = land & (lab == 0) & ~water
    near_sea = ndimage.binary_dilation(water | ~land, iterations=SEA_KEEP)
    cc, n = ndimage.label(empty, np.ones((3, 3)))
    bcell = set()
    for b in bld:
        i = int((b[0] - X0) / RES); j = int((b[2] - Z0) / RES)
        if 0 <= i < W and 0 <= j < H and cc[j, i]: bcell.add(cc[j, i])
    seaside = set(np.unique(cc[near_sea & (cc > 0)]))
    keep = np.zeros(n + 1, bool); keep[1:] = True
    for c in bcell | seaside: keep[c] = False
    holes = keep[cc] & (cc > 0)
    ring = ndimage.binary_dilation(holes, np.ones((3, 3))) & ~holes & (lab > 0)
    owners = np.unique(lab[ndimage.binary_dilation(holes, np.ones((3, 3)), iterations=4) & (lab > 0)]) - 1
    names = sorted(set(lay[o]['piece'] for o in owners))
    if check:       # (with fx_holes in: what is left)
        a = RES * RES; sizes = np.bincount(cc[holes].ravel()) if holes.any() else np.zeros(1)
        print('CHECK with fx_holes: %d places left, %.0f m2 (biggest %.1f m2)' % (int((sizes > 0).sum()), holes.sum() * a, sizes.max() * a))
        return
    os.makedirs(OUT, exist_ok=True)
    np.savez_compressed(os.path.join(OUT, 'holes_plan.npz'), holes=holes, ring=ring, lab=lab)
    open(os.path.join(OUT, 'holes_neighbours.txt'), 'w').write(','.join(names))
    a = RES * RES
    print('HOLES %d places, %.0f m2 to fill (%d left out: a building in them %d, by the sea %d); %d neighbouring pieces' % (
        n, holes.sum() * a, int((~keep[1:]).sum()), len(bcell), len(seaside), len(names)))


def tri_of_attr():
    """every copyable ground triangle of the neighbouring pieces, in city coords, per layout row"""
    lay = layout(); names = set(open(os.path.join(OUT, 'holes_neighbours.txt')).read().split(','))
    P, U, C, M, mats = [], [], [], [], []
    for r in lay:
        p = r['piece']
        if p not in names: continue
        jf = os.path.join(ATTR, p + '.json')
        if not os.path.exists(jf): continue
        j = json.load(open(jf)); f = np.fromfile(jf[:-5] + '.bin', '<f4')
        R = yaw_mat(float(r.get('yaw', 0))); pos = np.array(r.get('pos', [0, 0, 0]), float)
        for s in j['surfaces']:
            if s['tris'] == 0 or s['name'] in NO_COPY or not s['mat']: continue
            a = f[s['off']:s['off'] + s['tris'] * 24].reshape(-1, 3, 8).astype(np.float64)
            v = a[..., 0:3] @ R.T + pos
            nrm = np.cross(v[:, 1] - v[:, 0], v[:, 2] - v[:, 0]); ln = np.linalg.norm(nrm, axis=1) + 1e-12
            up = np.abs(nrm[:, 1]) / ln > 0.7          # (top faces only: no kerb faces, no walls)
            if not up.any(): continue
            if s['mat'] not in mats: mats.append(s['mat'])
            P.append(v[up]); U.append(a[up][..., 3:5]); C.append(a[up][..., 5:8]); M.append(np.full(up.sum(), mats.index(s['mat'])))
    return np.concatenate(P), np.concatenate(U), np.concatenate(C), np.concatenate(M), mats


def bary(t, x, z):
    """barycentric weights of (x, z) in the xz triangles t [n,3,3] (not clamped)"""
    a = t[:, 0, [0, 2]]; b = t[:, 1, [0, 2]]; c = t[:, 2, [0, 2]]
    v0 = b - a; v1 = c - a; v2 = np.stack([x, z], -1) - a
    d = v0[:, 0] * v1[:, 1] - v1[:, 0] * v0[:, 1]; d = np.where(np.abs(d) < 1e-12, 1e-12, d)
    w1 = (v2[:, 0] * v1[:, 1] - v1[:, 0] * v2[:, 1]) / d
    w2 = (v0[:, 0] * v2[:, 1] - v2[:, 0] * v0[:, 1]) / d
    return np.stack([1 - w1 - w2, w1, w2], -1)


def make():
    d = np.load(os.path.join(OUT, 'holes_plan.npz'))
    holes, ring = d['holes'], d['ring']
    T, TU, TC, TM, mats = tri_of_attr()
    cen = T.mean(1)
    tree = cKDTree(cen[:, [0, 2]])
    # the ground's height at each ring cell's centre: the top triangle under it
    cells = holes | ring
    J, I = np.nonzero(cells)
    cx = X0 + (I + 0.5) * RES; cz = Z0 + (J + 0.5) * RES
    k = 12
    dist, idx = tree.query(np.stack([cx, cz], -1), k=k)
    best = np.full(len(cx), -1); bestd = np.full(len(cx), 1e9); besty = np.full(len(cx), -1e9)
    for q in range(k):
        t = T[idx[:, q]]; w = bary(t, cx, cz)
        inside_t = (w >= -1e-3).all(1)
        y = (w * t[:, :, 1]).sum(1)
        # distance to the triangle in xz: 0 inside, else to its nearest vertex / edge (approximated by the clamped weights)
        wc = np.clip(w, 0, None); wc /= wc.sum(1, keepdims=True)
        px = (wc * t[:, :, 0]).sum(1); pz = (wc * t[:, :, 2]).sum(1)
        dd = np.where(inside_t, 0.0, np.hypot(px - cx, pz - cz))
        better = (dd < bestd - 1e-6) | ((np.abs(dd - bestd) <= 1e-6) & (y > besty))
        best = np.where(better, idx[:, q], best); bestd = np.where(better, dd, bestd); besty = np.where(better, np.where(inside_t, y, (wc * t[:, :, 1]).sum(1)), besty)
    src = np.full(cells.shape, -1, np.int64); src[J, I] = best
    hgt = np.full(cells.shape, np.nan); hgt[J, I] = besty
    # heights: the ring keeps its ground's own height (known); inside the holes a membrane from the edges in
    known = ring & (src >= 0)
    hh = np.where(known, hgt, np.nan)
    lab_h, nh = ndimage.label(holes, np.ones((3, 3)))
    for sl, comp in zip(ndimage.find_objects(lab_h), range(1, nh + 1)):
        sl2 = tuple(slice(max(s.start - 2, 0), min(s.stop + 2, n)) for s, n in zip(sl, holes.shape))
        m = lab_h[sl2] == comp; kn = known[sl2]; hv = hh[sl2].copy()
        if not kn.any(): continue
        start = np.nanmean(hv[kn]); hv[m] = start
        for _ in range(600 if m.sum() > 400 else 200):     # Jacobi: each hole cell the mean of its four neighbours
            p = np.pad(hv, 1, mode='edge')
            nb = np.stack([p[:-2, 1:-1], p[2:, 1:-1], p[1:-1, :-2], p[1:-1, 2:]])
            mv = np.nanmean(np.where(np.isnan(nb), np.nan, nb), 0)
            hv = np.where(m & ~np.isnan(mv), mv, hv)
        hh[sl2] = np.where(m, hv, hh[sl2])
    # corner heights: the mean of the cells round each corner (the ring 4 cm down)
    cell_h = np.where(ring, hh - DROP, hh)
    # the surface of each hole cell: its nearest copyable triangle
    out = {}      # mat index -> list of vertex rows (x y z nx ny nz u v r g b)
    Jc, Ic = np.nonzero(cells & ~np.isnan(cell_h))
    def corner(j, i):       # j, i: the corner at the cell (j, i)'s low-x low-z corner
        v = []
        for dj in (-1, 0):
            for di in (-1, 0):
                jj, ii = j + dj, i + di
                if 0 <= jj < cell_h.shape[0] and 0 <= ii < cell_h.shape[1] and not np.isnan(cell_h[jj, ii]): v.append(cell_h[jj, ii])
        return float(np.mean(v)) if v else None
    nq = 0
    for j, i in zip(Jc, Ic):
        t = int(src[j, i])
        if t < 0: continue
        corners = [(j, i), (j, i + 1), (j + 1, i + 1), (j + 1, i)]
        ys = [corner(a, b) for a, b in corners]
        if any(y is None for y in ys): continue
        P = np.array([[X0 + b * RES, y, Z0 + a * RES] for (a, b), y in zip(corners, ys)])
        tri = T[t]; w = bary(tri[None].repeat(4, 0), P[:, 0], P[:, 2])          # the triangle's own mapping, carried on
        uv = w @ TU[t]
        wc = np.clip(w, 0, None); wc /= wc.sum(1, keepdims=True); col = wc @ TC[t]   # its colour at the nearest point
        n_ = np.cross(P[2] - P[0], P[1] - P[0]); n_ = n_ / (np.linalg.norm(n_) + 1e-12)
        if n_[1] < 0: n_ = -n_
        rows = out.setdefault(int(TM[t]), [])
        for a in (0, 1, 2, 0, 2, 3):      # two triangles, (b-a)x(c-a) pointing down: facing up in Godot's winding (as kit_lib's tri())
            rows.append([*P[a], *n_, *uv[a], *col[a]])
        nq += 1
    blob = b''; surfs = []
    for m, rows in out.items():
        arr = np.asarray(rows, '<f4'); surfs.append({'mat': mats[m], 'offset': len(blob), 'count': len(rows)}); blob += arr.tobytes()
    os.makedirs(os.path.join(OUT, 'pieces'), exist_ok=True)
    open(os.path.join(OUT, 'pieces', 'fx_holes.bin'), 'wb').write(blob)
    json.dump({'surfaces': surfs, 'quads': nq}, open(os.path.join(OUT, 'pieces', 'fx_holes.json'), 'w'))
    by = {os.path.basename(mats[m]): len(r) // 6 for m, r in out.items()}
    print('HOLES fx_holes: %d patch cells (%.0f m2), %d materials: %s' % (nq, nq * RES * RES, len(out), by))


if __name__ == '__main__':
    {'plan': plan, 'make': make, 'check': lambda: plan(True)}[sys.argv[1]]()
