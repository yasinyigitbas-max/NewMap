#!/usr/bin/env python3
"""Checks of the fill (21 Nov, Yasin's review). MEASURES ONLY. Prints:
  1. props: fill props closer to an existing piece (footprints.py: low surfaces, other meshes, prop / tree boxes) or to
     a piece's ground than their clearance (tree 3 m, others radius + 1 m), and any on another piece's ground at all
  2. ground: fill ground triangles (centre) over an existing low surface (court, paving) or another piece's ground
  3. trees: the street cap - trees within 60 m of each street point (road cells of the before audit, every 4 m), the
     existing city's trees alone and with the fill's
What it cannot see: things the bake adds; a prop's real outline (a disc of its radius is assumed); trees out of sight
behind a building still count.
  python3 tools/city/fill/check_fill.py
"""
import os, json, glob, numpy as np
from scipy import ndimage as ndi
from scipy.spatial import cKDTree
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../..")
OUT = os.path.join(ROOT, 'OUT/fill')
C = np.load(os.path.join(OUT, 'coverage.npz')); x0 = float(C['x0']); z0 = float(C['z0']); res = float(C['res'])
FP = np.load(os.path.join(OUT, 'foot.npz'))
other = FP['occ'] | FP['surf']; ground = (C['cls'] == 1) | FP['surf']
d_other = ndi.distance_transform_edt(~other) * res; d_ground = ndi.distance_transform_edt(~ground) * res
H, W = other.shape
def at(a, P):
    i = np.clip(((P[:, 0] - x0) / res).astype(int), 0, W - 1); j = np.clip(((P[:, 1] - z0) / res).astype(int), 0, H - 1)
    return a[j, i]
topref = np.where(FP['surf'], np.maximum(FP['surf_top'], -99), C['top'])
props = []; tris_bad = 0; tris = 0; v_in = 0; v_above = 0; above_pts = []
for f in sorted(glob.glob(os.path.join(OUT, 'pieces', 'fl_*.json'))):
    m = json.load(open(f)); props += m['props']
    V = np.fromfile(f[:-5] + '.bin', '<f4').reshape(-1, 11)
    cen = V[:, [0, 2]].reshape(-1, 3, 2).mean(1)
    tris += len(cen); tris_bad += int((at(ground, cen) & (at(d_ground, cen) == 0)).sum())
    # under a neighbour (the tuck), the fill must stay below the neighbour's surface there: never drawn over it
    XZ = V[:, [0, 2]]; ins = at(ground, XZ) & (at(topref, XZ) > -98)
    up = ins & (V[:, 1] > at(topref, XZ) + 0.02)
    v_in += int(ins.sum()); v_above += int(up.sum())
    if up.any(): above_pts.append(XZ[up][:3])
P = np.array([[p[2], p[4]] for p in props]); names = [p[0] for p in props]; sc = np.array([p[7] for p in props])
clear = np.array([3.0 if n.startswith('tree_') else 0.6 * s + 1.0 for n, s in zip(names, sc)])
do = at(d_other, P); dg = at(d_ground, P)
bad = (do < clear - 0.5) | (dg < clear - 0.5)
print('CHECK 1 props: %d fill props; %d nearer an existing piece than their clearance (-0.5 m raster slack); %d ON another piece (0 m)' % (len(P), int(bad.sum()), int(((do == 0) | (dg == 0)).sum())))
print('CHECK 2b ground: %d fill vertices under a neighbour\'s footprint; %d of them above its surface (+2 cm)' % (v_in, v_above))
if above_pts: print('   e.g.', np.concatenate(above_pts)[:6].round(1).tolist())
print('CHECK 2 ground: %d fill triangles; %d with their centre on another piece\'s ground or a court / paving (the 0.35 m tuck under edges counts here)' % (tris, tris_bad))
B = np.fromfile(os.path.join(OUT, 'foot_box.bin'), '<f4').reshape(-1, 11)
old_t = np.stack([B[B[:, 10] > 0][:, 0:8:2].mean(1), B[B[:, 10] > 0][:, 1:8:2].mean(1)], 1)
old_t = np.unique(np.round(old_t, 1), axis=0)
new_t = P[[n.startswith('tree_') for n in names]]
road = C['road'] > 0
jj, ii = np.nonzero(road[::8, ::8]); S = np.stack([x0 + (ii * 8 + 0.5) * res, z0 + (jj * 8 + 0.5) * res], 1)
k_old = np.array([len(r) for r in cKDTree(old_t).query_ball_point(S, 60.0)])
k_all = k_old + np.array([len(r) for r in cKDTree(new_t).query_ball_point(S, 60.0)])
print('CHECK 3 trees: %d existing trees, %d fill trees; %d street points' % (len(old_t), len(new_t), len(S)))
print('  existing only: max %d within 60 m, %d points over 12' % (k_old.max(), int((k_old > 12).sum())))
print('  with the fill: max %d within 60 m, %d points over 12, %d points the fill made go over 12 (were 12 or under)' % (
    k_all.max(), int((k_all > 12).sum()), int(((k_all > 12) & (k_old <= 12)).sum())))
w = np.nonzero((k_all > 12) & (k_old <= 12))[0]
for q in w[:10]: print('   over by the fill at', S[q].round(1), 'existing', k_old[q], 'with fill', k_all[q])
