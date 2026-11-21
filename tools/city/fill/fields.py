#!/usr/bin/env python3
"""Fill fields (21 Nov, Yasin: "fill all of the empty space in the map ... cover around the island with sand, rock
beaches and sea"). MEASURES and DERIVES only (never touches a piece). From the coverage (coverage.py), the ground dump
(ground_dump.gd), the terrain (zoning/terrain_grid.npz) and the island outline (zoning/coast.json) it writes, on the
sea map's frame at 0.5 m (OUT/fill/fields.npz):
  dom   where fill ground goes: on the island (with the west end closed by a new coast, WEST_COAST below), not under
        any piece's ground (0.35 m tucked under their edges), down to ~1.5 m under the sea along the shore
  h     the fill's height: the terrain (+5 cm, eased to 0 at the water line, so the sea at 0 m and the locked foam strip
        meet it as on the east shore), eased to each neighbouring piece's ground edge (its exact height, 4 cm under it)
  d0    metres from the water line (+ inland), sd metres from the nearest piece ground (+ away), droad from a street
  edge  the neighbour's edge height, gapid the small gaps inside the city (component id, 0 elsewhere), nmat nearest
        neighbour material id
The island's outline stops at the sea map's west frame (x -1800) and the terrain at x -1600: west of the ring the land
just ran off the map. WEST_COAST closes it with a beach (a sand bar in front of the westernmost lagoon).
"""
import json, os, sys
import numpy as np, shapely
from shapely.geometry import Polygon
from scipy import ndimage as ndi

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../.."))
KIT = os.path.join(ROOT, "map_dc/coronado/city_kit")
OUT = os.path.join(ROOT, "OUT/fill")
# the new west coast, north to south (grid frame); everything west of it is sea
WEST_COAST = [(-1560, -1760), (-1600, -1660), (-1650, -1590), (-1705, -1510), (-1745, -1400), (-1768, -1250), (-1778, -1050),
              (-1774, -860), (-1784, -660), (-1790, -460), (-1787, -260), (-1792, -60), (-1795, 110), (-1797, 235),
              (-1793, 345), (-1779, 450), (-1754, 560), (-1726, 650), (-1708, 705), (-1700, 760), (-1700, 900)]


def chaikin(p, n=3):
    p = np.asarray(p, float)
    for _ in range(n):
        q = np.empty((2 * len(p) - 2, 2)); q[0::2] = 0.75 * p[:-1] + 0.25 * p[1:]; q[1::2] = 0.25 * p[:-1] + 0.75 * p[1:]
        p = np.vstack([p[:1], q, p[-1:]])
    return p


def west_sea_polygon():
    c = chaikin(WEST_COAST, 4)
    return Polygon(list(map(tuple, c)) + [(-2600, 900), (-2600, -1760)]).buffer(0), c


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)


def edge_heights(base, need, x0, z0, res, W, H):
    """exact top height of the piece ground at the centre of every cell in `need` (max over all ground triangles)"""
    recs = json.load(open(base + '.json'))
    V = np.fromfile(base + '_v.bin', '<f4').reshape(-1, 3); I = np.fromfile(base + '_i.bin', '<i4')
    out = np.full((H, W), -np.inf, np.float32)
    integ = np.pad(need.astype(np.int32).cumsum(0).cumsum(1), ((1, 0), (1, 0)))
    for r in recs:
        x = np.array(r['xf'], dtype=np.float64); B = x[:9].reshape(3, 3).T; o = x[9:]
        for name, vo, vn, io, inn in r['surf']:
            v = V[vo:vo + vn].astype(np.float64) @ B.T + o
            T = v[I[io:io + inn]].reshape(-1, 3, 3)
            px = (T[..., 0] - x0) / res - 0.5; pz = (T[..., 2] - z0) / res - 0.5     # cell centres at integer coords
            i0 = np.clip(np.ceil(px.min(1)).astype(int), 0, W); i1 = np.clip(np.floor(px.max(1)).astype(int) + 1, 0, W)
            j0 = np.clip(np.ceil(pz.min(1)).astype(int), 0, H); j1 = np.clip(np.floor(pz.max(1)).astype(int) + 1, 0, H)
            ok = (i1 > i0) & (j1 > j0)
            cnt = np.zeros(len(T), np.int64)
            cnt[ok] = integ[j1[ok], i1[ok]] - integ[j0[ok], i1[ok]] - integ[j1[ok], i0[ok]] + integ[j0[ok], i0[ok]]
            for t in np.nonzero(cnt > 0)[0]:
                ii, jj = np.meshgrid(np.arange(i0[t], i1[t]), np.arange(j0[t], j1[t]))
                m = need[jj, ii]
                qx = ii[m].astype(float); qz = jj[m].astype(float)
                ax, bx, cx = px[t]; az, bz, cz = pz[t]
                d = (bz - cz) * (ax - cx) + (cx - bx) * (az - cz)
                if abs(d) < 1e-9: continue
                l1 = ((bz - cz) * (qx - cx) + (cx - bx) * (qz - cz)) / d
                l2 = ((cz - az) * (qx - cx) + (ax - cx) * (qz - cz)) / d
                l3 = 1 - l1 - l2
                inside = (l1 >= -1e-6) & (l2 >= -1e-6) & (l3 >= -1e-6)
                if not inside.any(): continue
                y = l1 * T[t, 0, 1] + l2 * T[t, 1, 1] + l3 * T[t, 2, 1]
                np.maximum.at(out, (jj[m][inside], ii[m][inside]), y[inside].astype(np.float32))
    return out


def main():
    D = np.load(os.path.join(OUT, 'coverage.npz'))
    cls = D['cls']; road = D['road'] > 0; mat = D['mat']; x0 = float(D['x0']); z0 = float(D['z0']); res = float(D['res'])
    H, W = cls.shape
    cov = cls == 1
    xs = x0 + (np.arange(W) + 0.5) * res; zs = z0 + (np.arange(H) + 0.5) * res
    g = np.load(os.path.join(KIT, 'zoning/terrain_grid.npz')); T = g['heights'].astype(np.float32); tu0 = float(g['u0']); tv0 = float(g['v0']); ts = float(g['step'])
    fx = np.clip((xs - tu0) / ts, 0, T.shape[1] - 1.001); fz = np.clip((zs - tv0) / ts, 0, T.shape[0] - 1.001)
    ix = fx.astype(int); iz = fz.astype(int); tx = (fx - ix)[None, :]; tz = (fz - iz)[:, None]
    Ht = (T[iz][:, ix] * (1 - tx) * (1 - tz) + T[iz][:, ix + 1] * tx * (1 - tz) + T[iz + 1][:, ix] * (1 - tx) * tz + T[iz + 1][:, ix + 1] * tx * tz).astype(np.float32)
    # west of the terrain's data (x < -1600) its last column carried on, smoothed along z (80 m) so a pond or a dip at
    # the edge does not run on west as a stripe; blended into the real terrain over its first 100 m
    col = ndi.gaussian_filter1d(T[:, 0].astype(np.float64), 20, mode='nearest')
    cz = np.clip((zs - tv0) / ts, 0, T.shape[0] - 1.001); ci = cz.astype(int); ct = cz - ci
    cs = (col[ci] * (1 - ct) + col[np.minimum(ci + 1, T.shape[0] - 1)] * ct).astype(np.float32)[:, None]
    bt = smoothstep(tu0, tu0 + 100, xs)[None, :].astype(np.float32)
    Ht = (cs * (1 - bt) + Ht * bt).astype(np.float32)
    wsea, wline = west_sea_polygon()
    XX, ZZ = np.meshgrid(xs, zs)
    in_wsea = shapely.contains_xy(wsea, XX, ZZ)
    dw = (ndi.distance_transform_edt(~in_wsea) - ndi.distance_transform_edt(in_wsea)).astype(np.float32) * res
    prof = np.where(dw < 0, np.maximum(dw / 8.0, -3.5), np.where(dw < 40, dw / 30.0, 40 / 30.0 + (dw - 40) * 0.06)).astype(np.float32)
    k = 1.5
    Hb = np.where(dw < 400, -k * np.logaddexp(-Ht / k, -prof / k), Ht).astype(np.float32)
    del prof, dw
    coast = json.load(open(os.path.join(KIT, 'zoning/coast.json')))
    island = Polygon(coast['sea'][0]).buffer(0).difference(wsea)
    land0 = Hb > 0
    d0 = (ndi.distance_transform_edt(land0) - ndi.distance_transform_edt(~land0)).astype(np.float32) * res
    sd = (ndi.distance_transform_edt(~cov) - ndi.distance_transform_edt(cov)).astype(np.float32) * res
    on_isl = shapely.contains_xy(island.buffer(30), XX, ZZ)
    isl0 = shapely.contains_xy(island, XX, ZZ)
    # (d0 > -14 | on the island: a low spot inside the outline, under 0 m but with no water laid on it, gets wet sand)
    dom = (sd > -0.35) & on_isl & ((d0 > -14) | isl0) & (Hb > -1.8)
    del isl0
    isl = shapely.contains_xy(island, XX, ZZ)
    lab, n = ndi.label((~cov) & isl & (d0 > 30))
    sizes = np.bincount(lab.ravel()); big = list(set(np.nonzero(sizes * res * res > 20000)[0]) - {0})
    gapid = np.where(np.isin(lab, big) | (lab == 0), 0, lab).astype(np.int32)
    del lab
    need = cov & ndi.binary_dilation(dom & ~cov, iterations=3)
    print('fields: exact edge heights at', int(need.sum()), 'cells', flush=True)
    eh = edge_heights(os.path.join(ROOT, 'OUT/ground_fill'), need, x0, z0, res, W, H)
    have = np.isfinite(eh)
    print('fields: edge cells with a height', int(have.sum()), flush=True)
    _, (nj, ni) = ndi.distance_transform_edt(~have, return_indices=True)
    edge = eh[nj, ni]
    edge = ndi.minimum_filter(edge, size=5)
    nmat = mat[nj, ni]
    del nj, ni, eh
    lift = 0.05 * smoothstep(0, 10, d0)
    # polish 2 (21 Nov): inland the zoning terrain keeps the pads and steps of lots never built (1 m steps with steep
    # sides drew dark rock outlines on the grass); away from the shore and the neighbours the ground is the terrain
    # smoothed over ~6 m (sigma), so a step becomes a soft swell; the coast and every neighbour edge keep the exact one
    wsm = (smoothstep(20, 45, d0) * smoothstep(12, 35, sd)).astype(np.float32)
    Hs = ndi.gaussian_filter(Hb, 6.0 / res, mode='nearest').astype(np.float32)
    Hb = (Hb * (1 - wsm) + Hs * wsm).astype(np.float32)
    del Hs, wsm
    base = (Hb + lift).astype(np.float32)
    # the lagoons (coast.json "ponds", all in the empty west but the east shore's): a bowl 0.9 m deep under a still
    # surface 0.18 m below the lowest point of the rim; the ground eases down to it over the 6 m inside the rim
    ponds = []
    for pk, pp in enumerate(coast['ponds']):
        P = Polygon(pp).buffer(0)
        bx0, bz0, bx1, bz1 = P.bounds
        if bx1 > -900: continue                       # the east shore's ponds lie under locked pieces
        i0 = max(int((bx0 - 12 - x0) / res), 0); i1 = min(int((bx1 + 12 - x0) / res) + 1, W)
        j0 = max(int((bz0 - 12 - z0) / res), 0); j1 = min(int((bz1 + 12 - z0) / res) + 1, H)
        sx = XX[j0:j1, i0:i1]; sz = ZZ[j0:j1, i0:i1]
        inside = shapely.contains_xy(P, sx, sz)
        if not inside.any(): continue
        din = ndi.distance_transform_edt(inside) * res
        rim = ndi.binary_dilation(inside, iterations=2) & ~inside
        lvl = float(base[j0:j1, i0:i1][rim].min()) - 0.18
        bowl = lvl + 0.18 - 0.9 * smoothstep(0, 6, din) - 0.25 * smoothstep(6, 25, din)
        sub = base[j0:j1, i0:i1]
        base[j0:j1, i0:i1] = np.where(inside, np.minimum(sub, bowl), sub)
        ponds.append({'id': pk, 'level': round(lvl, 3), 'poly': [[round(a, 2), round(b, 2)] for a, b in P.exterior.coords]})
    json.dump(ponds, open(os.path.join(OUT, 'ponds.json'), 'w'))
    print('fields: ponds', [(p['id'], p['level']) for p in ponds])
    dh = np.abs(edge - base)
    Lb = np.clip(6 * dh, 4, 40)
    t = smoothstep(0, Lb, np.maximum(sd, 0))
    e0 = edge - 0.04
    h = np.where(sd < 0, e0 + 0.25 * sd, e0 * (1 - t) + base * t).astype(np.float32)
    h = np.where(np.isfinite(h) & (sd < 45), h, base).astype(np.float32)
    droad = (ndi.distance_transform_edt(~road) * res).astype(np.float32)
    np.savez(os.path.join(OUT, 'fields.npz'), dom=dom, h=h, base=base, d0=d0, sd=sd, droad=droad, edge=edge.astype(np.float32),
             gapid=gapid, nmat=nmat, x0=x0, z0=z0, res=res, wline=wline, isl=isl)
    a = res * res
    print('fields: domain %.3f km2 (on land %.3f), small city gaps %d (%.0f m2)' % (dom.sum() * a / 1e6, (dom & (d0 > 0)).sum() * a / 1e6, len(set(np.unique(gapid)) - {0}), (gapid > 0).sum() * a))


if __name__ == "__main__":
    main()
