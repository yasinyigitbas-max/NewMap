"""Ground for the commercial strip's growth blocks (claude/grow-strip, 18 Nov). Yasin's rule: no jumps, smooth heights,
the ground meets every piece edge flush.

Each new strip block (m_gr_*) fills an empty rectangle between existing pieces (the sample, the road kit's legs,
junctions and the ring). The streets round it are graded (3rd St at pad 2, the sample at 4, Adela's north leg and the
ring rising between them), so the lot's ground must take the height of the walk on every side it touches. This takes
the built ground of the assembled city (zoning/piece_ground.npz, 1 m raster of every piece's ground) and solves a
smooth (harmonic) surface over each rectangle: fixed where a neighbour's ground lies just outside the edge, free
(no slope across the edge) where nothing is built yet. Builders then level each building's pad on it
(strip_grow_lib.gd) and blend back over a few metres.

Writes tools/city/pilot/pieces/strip_grow_ground.json: per block the rectangle (grid u, v), the piece origin and pad,
and the surface on a 1 m grid in PIECE coordinates (y = height above the pad).
Run from the repo root: python3 -I tools/city/pilot/zoning/strip_grow_ground.py
"""
import json, os
import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
KIT = os.path.join(ROOT, "map_dc/coronado/city_kit")
OUT = os.path.join(ROOT, "tools/city/pilot/pieces/strip_grow_ground.json")

# name: (u0, v0, u1, v1 grid rectangle, origin junction (u, v), pad) - measured on piece_ground.npz (property lines of
# the neighbours: Adela 8.7, 4th / 3rd / 5th St east 14.3, 5th St west 9.2, ring inland 14.3 from its centre line)
BLOCKS = {
    "m_gr_ad5ne": (508.7, -1100.0, 645.7, -1014.3, (500.0, -1000.0), 4.0),
    "m_gr_e4s": (600.0, -1185.7, 645.7, -1100.0, (500.0, -1200.0), 4.0),
    "m_gr_ad5nw": (400.0, -1100.0, 491.3, -1009.2, (500.0, -1000.0), 4.0),
    "m_gr_e4n": (600.0, -1300.0, 645.7, -1214.3, (500.0, -1200.0), 4.0),
    "m_gr_ad3se": (508.7, -1385.7, 645.7, -1300.0, (500.0, -1400.0), 2.0),
    "m_gr_ad3sw": (400.0, -1385.7, 491.3, -1300.0, (500.0, -1400.0), 2.0),
}


def main():
    """one solve over the whole strip area, so two new blocks that touch share their seam exactly"""
    b = np.load(os.path.join(KIT, "zoning/piece_ground.npz"))
    g = b["ground"]; gu0 = float(b["u0"]); gv0 = float(b["v0"])
    U0, V0, U1, V1 = 390, -1395, 656, -1000          # the strip area (1 m cells, cell centres on whole metres)
    sub = g[int(V0 - gv0):int(V1 - gv0) + 1, int(U0 - gu0):int(U1 - gu0) + 1].astype(float)
    known = np.isfinite(sub) & (sub > -100)
    free = np.zeros_like(known)
    corners = []
    for (u0, v0, u1, v1, _o, _p) in BLOCKS.values():
        free[int(np.floor(v0 - V0)) + 1:int(np.ceil(v1 - V0)), int(np.floor(u0 - U0)) + 1:int(np.ceil(u1 - U0))] = True
        corners += [(u0, v0), (u1, v0), (u0, v1), (u1, v1)]
    free &= ~known
    # a neighbour cell only fixes the surface where it is a walk or a lot: within 2.5 m of a block corner the cell
    # across the corner can be the kerb return's asphalt (0.15 m lower), so those are left to the solve
    fixed = known.copy()
    for (cu, cv) in corners:
        i0 = int(round(cv - V0)); j0 = int(round(cu - U0))
        for i in range(i0 - 3, i0 + 4):
            for j in range(j0 - 3, j0 + 4):
                if 0 <= i < sub.shape[0] and 0 <= j < sub.shape[1] and fixed[i, j] and not free[i, j]:
                    nb = [sub[a, c] for a, c in ((i-1, j), (i+1, j), (i, j-1), (i, j+1)) if 0 <= a < sub.shape[0] and 0 <= c < sub.shape[1] and known[a, c]]
                    if nb and max(nb) - sub[i, j] > 0.1: fixed[i, j] = False
    H = np.where(known, sub, np.nan)
    H[free] = np.nanmean(sub[known & ~free])
    act = free | (known & ~fixed)
    H[np.isnan(H)] = np.nanmean(sub[known])
    useful = free | fixed        # unknown cells outside the blocks act as no-flux (mirror the active cell)
    for _ in range(8000):
        P = np.pad(H, 1, mode="edge"); M = np.pad(useful, 1, mode="constant")
        acc = np.zeros_like(H); cnt = np.zeros_like(H)
        for di, dj in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nbh = P[1 + di:1 + di + H.shape[0], 1 + dj:1 + dj + H.shape[1]]
            ok = M[1 + di:1 + di + H.shape[0], 1 + dj:1 + dj + H.shape[1]]
            acc += np.where(ok, nbh, 0.0); cnt += ok
        N = np.where(cnt > 0, acc / np.maximum(cnt, 1), H)
        H = np.where(act, N, H)
    out = {"_doc": __doc__.strip().split("\n")[0], "blocks": {}}
    for name, (u0, v0, u1, v1, (ou, ov), pad) in BLOCKS.items():
        nx = int(np.ceil(u1 - u0)) + 1; nz = int(np.ceil(v1 - v0)) + 1
        us = np.linspace(u0, u1, nx); vs = np.linspace(v0, v1, nz)
        Y = np.zeros((nz, nx))
        for i, v in enumerate(vs):
            for j, u in enumerate(us):      # bilinear in the solved raster
                fu = min(max(u - U0, np.floor(u0 - U0) + 1), np.ceil(u1 - U0) - 1); fv = min(max(v - V0, np.floor(v0 - V0) + 1), np.ceil(v1 - V0) - 1);   # inside the solved cells (the raster row ON a piece edge is half hits)
                j0 = min(int(np.floor(fu)), H.shape[1] - 2); i0 = min(int(np.floor(fv)), H.shape[0] - 2); tu = fu - j0; tv = fv - i0
                Y[i, j] = (H[i0, j0] * (1 - tu) * (1 - tv) + H[i0, j0 + 1] * tu * (1 - tv) + H[i0 + 1, j0] * (1 - tu) * tv + H[i0 + 1, j0 + 1] * tu * tv)
        out["blocks"][name] = {"rect": [u0, v0, u1, v1], "origin": [ou, pad, ov], "x0": u0 - ou, "z0": v0 - ov,
                               "nx": nx, "nz": nz, "step": float(us[1] - us[0]), "stepz": float(vs[1] - vs[0]),
                               "y": [round(float(h) - pad, 3) for h in Y.ravel()]}
        print("%-12s %5.1f x %5.1f m  y %.2f..%.2f above pad %.0f" % (name, u1 - u0, v1 - v0, Y.min() - pad, Y.max() - pad, pad))
    json.dump(out, open(OUT, "w"))


if __name__ == "__main__":
    main()
