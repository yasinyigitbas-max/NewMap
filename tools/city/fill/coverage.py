#!/usr/bin/env python3
"""Fill audit (21 Nov, Yasin: "fill all of the empty space in the map ... places that doesn't have ground or any
objects in it ... cover around the island with sand, rock beaches and sea ... find the tiny gaps").
MEASURES ONLY. Rasterises every piece's ground mesh of the assembled city (tools/city/audit/ground_dump.gd output) at
RES m a cell (top-down, the highest ground wins) and compares it with the island outline (zoning/coast.json "sea") and
the sea surface (tools/city/look/sea_map.png, G = water laid). Classes:
  1 ground (a piece covers it)   2 sea (water laid, no ground)   0 EMPTY: on the island, no ground, no water: the
  game shows its flat backstop plane 2 m under the sea there (a green pit), or the sky through a hole.
Writes <out>/coverage.npz (cls, top height, frame) and prints the totals.
  python3 tools/city/fill/coverage.py OUT/ground_fill OUT/fill
"""
import json, os, sys
import numpy as np, cv2, shapely
from shapely.geometry import Polygon
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../..")
KIT = os.path.join(ROOT, "map_dc/coronado/city_kit")
X0, X1, Z0, Z1 = -1800.0, 1900.0, -1950.0, 900.0    # the sea map's frame (make_sea.py)
RES = 0.5
MATS = {}


def main():
    base, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    W = int((X1 - X0) / RES); H = int((Z1 - Z0) / RES)
    recs = json.load(open(base + '.json'))
    V = np.fromfile(base + '_v.bin', '<f4').reshape(-1, 3); I = np.fromfile(base + '_i.bin', '<i4')
    cov = np.zeros((H, W), np.uint8)
    top = np.full((H, W), -99.0, np.float32)
    road = np.zeros((H, W), np.uint8); mat = np.zeros((H, W), np.uint8); scratch = np.zeros((H, W), np.uint8)
    for r in recs:
        x = np.array(r['xf'], dtype=np.float64); B = x[:9].reshape(3, 3).T; o = x[9:]
        isroad = r['piece'].startswith(('j_', 's_', 'x_', 'w_'))
        for name, vo, vn, io, inn in r['surf']:
            v = V[vo:vo + vn].astype(np.float64) @ B.T + o
            T = v[I[io:io + inn]].reshape(-1, 3, 3)
            P = np.stack([(T[..., 0] - X0) / RES, (T[..., 2] - Z0) / RES], -1)
            # skip vertical faces (walls / skirts): their top-down footprint is a line
            e1 = P[:, 1] - P[:, 0]; e2 = P[:, 2] - P[:, 0]
            area = np.abs(e1[:, 0] * e2[:, 1] - e1[:, 1] * e2[:, 0])
            keep = area > 1e-3
            if not keep.any(): continue
            pts = np.round(P[keep] * 4).astype(np.int32)      # 2 bits of sub-cell precision
            hy = T[keep][..., 1].max(1)
            mid = MATS.setdefault(name, len(MATS) + 1)
            # one triangle at a time: cv2.fillPoly with many polygons fills by parity, so two overlapping triangles
            # (a well's soil over the paving) cancel and read as a hole
            for t, y in zip(pts, hy):
                cv2.fillConvexPoly(cov, t, 1, lineType=cv2.LINE_8, shift=2)
                cv2.fillConvexPoly(scratch, t, 1, lineType=cv2.LINE_8, shift=2)
            bb = pts.reshape(-1, 2) >> 2
            i0, j0 = max(bb[:, 0].min() - 1, 0), max(bb[:, 1].min() - 1, 0); i1, j1 = min(bb[:, 0].max() + 2, W), min(bb[:, 1].max() + 2, H)
            sub = scratch[j0:j1, i0:i1] > 0
            if isroad: road[j0:j1, i0:i1][sub] = 1
            mat[j0:j1, i0:i1][sub] = mid
            # heights: the highest vertex of the surface's triangles per cell, from the triangle centres (coarse,
            # enough to grade a fill against its neighbours)
            C = T[keep].mean(1)
            ci = ((C[:, 0] - X0) / RES).astype(int); cj = ((C[:, 2] - Z0) / RES).astype(int)
            ok = (ci >= 0) & (ci < W) & (cj >= 0) & (cj < H)
            np.maximum.at(top, (cj[ok], ci[ok]), hy[ok].astype(np.float32))
            scratch[j0:j1, i0:i1] = 0
    coast = json.load(open(os.path.join(KIT, 'zoning/coast.json')))
    island = Polygon(coast['sea'][0]).buffer(0)
    xs = X0 + (np.arange(W) + 0.5) * RES; zs = Z0 + (np.arange(H) + 0.5) * RES
    XX, ZZ = np.meshgrid(xs, zs)
    land = shapely.contains_xy(island, XX, ZZ)
    sm = json.load(open(os.path.join(ROOT, 'tools/city/look/sea_map.json')))
    simg = np.array(Image.open(os.path.join(ROOT, 'tools/city/look/sea_map.png')).convert('RGB'))
    si = np.clip(np.round((XX - sm['x0']) / sm['step']).astype(int), 0, simg.shape[1] - 1)
    sj = np.clip(np.round((ZZ - sm['z0']) / sm['step']).astype(int), 0, simg.shape[0] - 1)
    water = simg[sj, si, 1] > 127
    depth = simg[sj, si, 0] / 255.0 * sm['deep']
    cls = np.where(cov > 0, 1, np.where(water, 2, 0)).astype(np.uint8)
    np.savez_compressed(os.path.join(out, 'coverage.npz'), cls=cls, top=top, land=land, road=road, mat=mat, mats=json.dumps(MATS), depth=depth.astype(np.float32),
                        x0=X0, z0=Z0, res=RES)
    a = RES * RES
    print('COVERAGE frame %.0f..%.0f x %.0f..%.0f at %.1f m' % (X0, X1, Z0, Z1, RES))
    print('  island land %.2f km2; ground on it %.2f km2; water on it (the 25 m onto the land) %.2f km2' % (land.sum() * a / 1e6, (land & (cls == 1)).sum() * a / 1e6, (land & (cls == 2)).sum() * a / 1e6))
    print('  EMPTY on the island: %.3f km2' % ((land & (cls == 0)).sum() * a / 1e6))
    print('  EMPTY off the island (no water laid, no ground): %.3f km2' % ((~land & (cls == 0)).sum() * a / 1e6))


main()
