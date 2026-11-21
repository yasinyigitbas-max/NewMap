#!/usr/bin/env python3
"""Footprints of everything the existing pieces draw besides their "ground" (21 Nov, Yasin's review of the fill: shrubs
on the tennis courts - a court is not a "ground" mesh, so the coverage audit read it as empty). MEASURES ONLY.
Reads tools/city/fill/foot_dump.gd's output and writes OUT/fill/foot.npz on the coverage frame (0.5 m):
  surf      low horizontal surfaces (normal up within ~45 deg, top under the fill's base + 1.2 m): courts, paving, decks,
            floors. fields.py counts them as covered (the fill tucks under their edge, never draws over them)
  surf_top  their highest point a cell (the fill's edge height there)
  occ       the top-down footprint of every other mesh triangle (walls, fences, buildings, wires) and of every MultiMesh
            instance's box (props, trees). make_fill.py keeps every prop clear of it.
What it cannot see: things built at bake time (not in the .scn), and the bounds of props whose mesh box is far larger
than the prop (then it keeps the fill's props further away than needed, never nearer).
  python3 tools/city/fill/footprints.py
"""
import os, numpy as np, cv2
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../..")
OUT = os.path.join(ROOT, 'OUT/fill')


def main():
    C = np.load(os.path.join(OUT, 'coverage.npz')); x0 = float(C['x0']); z0 = float(C['z0']); res = float(C['res'])
    H, W = C['cls'].shape
    base = np.load(os.path.join(OUT, 'fields.npz'))['base']
    surf = np.zeros((H, W), np.uint8); occ = np.zeros((H, W), np.uint8); top = np.full((H, W), -99.0, np.float32)
    T = np.memmap(os.path.join(OUT, 'foot_tri.bin'), '<f4', 'r').reshape(-1, 3, 3)
    n_s = n_o = 0
    for c0 in range(0, len(T), 500000):
        t = np.asarray(T[c0:c0 + 500000], np.float64)
        nrm = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0]); ln = np.linalg.norm(nrm, axis=1) + 1e-12
        ny = np.abs(nrm[:, 1]) / ln
        P = np.stack([(t[..., 0] - x0) / res, (t[..., 2] - z0) / res], -1)
        inb = (P[..., 0].max(1) >= 0) & (P[..., 0].min(1) < W) & (P[..., 1].max(1) >= 0) & (P[..., 1].min(1) < H)
        cen = P.mean(1); ci = np.clip(cen[:, 0].astype(int), 0, W - 1); cj = np.clip(cen[:, 1].astype(int), 0, H - 1)
        ymax = t[..., 1].max(1)
        low = (ny > 0.7) & (ymax < base[cj, ci] + 1.2)
        pts = np.round(P * 4).astype(np.int32)
        for k in np.nonzero(inb)[0]:
            if low[k]:
                cv2.fillConvexPoly(surf, pts[k], 1, lineType=cv2.LINE_8, shift=2); n_s += 1
            else:
                cv2.fillConvexPoly(occ, pts[k], 1, lineType=cv2.LINE_8, shift=2); n_o += 1
        ok = inb & low
        np.maximum.at(top, (cj[ok], ci[ok]), ymax[ok].astype(np.float32))
        print('footprints: %d / %d triangles' % (min(c0 + 500000, len(T)), len(T)), flush=True)
    B = np.fromfile(os.path.join(OUT, 'foot_box.bin'), '<f4').reshape(-1, 11)
    for b in B:
        q = np.round(np.stack([(b[0:8:2] - x0) / res, (b[1:8:2] - z0) / res], -1) * 4).astype(np.int32)
        cv2.fillConvexPoly(occ, q, 1, lineType=cv2.LINE_8, shift=2)
    # the top height where only the triangle centres reached: carried from the nearest cell that has one, inside surf
    from scipy import ndimage as ndi
    have = top > -98
    if have.any():
        _, (nj, ni) = ndi.distance_transform_edt(~have, return_indices=True)
        top = np.where(surf > 0, top[nj, ni], -99.0).astype(np.float32)
    np.savez_compressed(os.path.join(OUT, 'foot.npz'), surf=surf > 0, surf_top=top, occ=occ > 0)
    print('footprints: low surfaces %d tris, %.3f km2; other footprints %d tris + %d prop boxes, %.3f km2' % (
        n_s, (surf > 0).sum() * res * res / 1e6, n_o, len(B), (occ > 0).sum() * res * res / 1e6))


if __name__ == '__main__':
    main()
