"""Smooth island coastline (17 Nov, Yasin: the shore "looks like minecraft now"). The terrain step bakes the coast
(land-use classes, beach, seawall, sea floor) from these vector lines, never from the 2.5 m land-use grid.
  - water = the land-use classes sea / bay / inland water, plus everything inside the approved coast cut (plan.CUT)
  - the mask is Gaussian-blurred: sigma 12 m along the real coast, 45 m near the cut line (Yasin drew a line across
    the Strand: it becomes a natural rounded beach, not a straight edge), then traced at 0.5 into polylines
  - polylines are resampled every 2 m; tiny islands / ponds under 600 m2 are dropped (golf ponds keep sigma 4 m)
Writes map_dc/coronado/city_kit/zoning/coast.json (grid frame: [u, v] points per line) and zoning/coast.png
(before / after: the raw grid edge in red, the smooth line in blue, over the island and two close-ups).
CPU-light: numpy + matplotlib only."""
import json, os, math
import numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import shapely
from shapely.geometry import Polygon, LineString
from load import terrain
from grid import O, A, B, to_grid, to_world
import plan

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(HERE, "../../../../map_dc/coronado/city_kit")
STEP = 2.5
U0, U1, V0, V1 = -1800.0, 1900.0, -1950.0, 900.0      # 17 Nov: covers the terrain box (+300 m west, +700 m east) with margin


def blur(a, sig_cells):
    r = max(1, int(3 * sig_cells))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sig_cells) ** 2); k /= k.sum()
    a = np.apply_along_axis(lambda m: np.convolve(np.pad(m, r, mode="edge"), k, mode="valid"), 0, a)
    return np.apply_along_axis(lambda m: np.convolve(np.pad(m, r, mode="edge"), k, mode="valid"), 1, a)


def main():
    m, H, C = terrain()
    ox, oz = m["origin_xz"]; cr = m["class_res"]
    us = np.arange(U0, U1, STEP); vs = np.arange(V0, V1, STEP)
    UU, VV = np.meshgrid(us, vs)
    X = O[0] + B[0] * UU + A[0] * VV; Z = O[1] + B[1] * UU + A[1] * VV
    ci = np.clip(((Z - oz) / cr).astype(int), 0, C.shape[0] - 1); cj = np.clip(((X - ox) / cr).astype(int), 0, C.shape[1] - 1)
    cls = C[ci, cj]
    cut = Polygon(plan.CUT)
    incut = shapely.contains_xy(cut, X, Z)
    sea = np.isin(cls, [0, 7]) | incut
    inland = (cls == 9) & ~sea
    # variable smoothing: 12 m along the real coast, 45 m within 250 m of the cut line (a natural beach there)
    cut_line = LineString(list(cut.exterior.coords)[:6])
    dcut = shapely.distance(cut_line, shapely.points(X.ravel(), Z.ravel())).reshape(X.shape)
    s12 = blur(sea.astype(float), 12.0 / STEP); s45 = blur(sea.astype(float), 45.0 / STEP)
    w = np.clip((250.0 - dcut) / 150.0, 0.0, 1.0)
    W = s12 * (1 - w) + s45 * w
    P = blur(inland.astype(float), 4.0 / STEP)
    out = {"note": __doc__.strip().split("\n")[0], "frame": "grid [u, v]", "sea": [], "ponds": []}
    fig, ax = plt.subplots(1, 3, figsize=(24, 9), dpi=100)
    for key, field in (("sea", W), ("ponds", P)):
        cs = ax[0].contour(us, vs, field, levels=[0.5], colors=["#1565c0"], linewidths=1.0)
        for seg in cs.allsegs[0]:
            seg = np.asarray(seg)
            if len(seg) < 4:
                continue
            closed = np.allclose(seg[0], seg[-1])
            if closed and Polygon(seg).area < 600.0:
                continue
            L = np.concatenate([[0], np.cumsum(np.hypot(*np.diff(seg, axis=0).T))])
            ss = np.arange(0, L[-1], 2.0)
            rs = np.stack([np.interp(ss, L, seg[:, 0]), np.interp(ss, L, seg[:, 1])], 1)
            out[key].append(rs.round(2).tolist())
    json.dump(out, open(os.path.join(KIT, "zoning/coast.json"), "w"))
    # pictures: the whole island (smooth), the bridge-foot shore and the cut, each with the raw grid edge in red
    raw = sea.astype(float)
    for i, (box, title) in enumerate((((U0, U1, V0, V1), "whole island: smooth coast (blue)"),
                                      ((700, 1350, -1500, -850), "bridge-foot shore: raw grid edge (red) vs smooth (blue)"),
                                      ((-400, 900, 150, 800), "the coast cut south of the hotel: a rounded beach"))):
        a = ax[i]
        if i > 0:
            a.contour(us, vs, raw, levels=[0.5], colors=["#d32f2f"], linewidths=0.8)
        for line in out["sea"]:
            q = np.array(line); a.plot(q[:, 0], q[:, 1], color="#1565c0", lw=1.6)
        for line in out["ponds"]:
            q = np.array(line); a.plot(q[:, 0], q[:, 1], color="#4fc3f7", lw=1.0)
        a.set_xlim(box[0], box[1]); a.set_ylim(box[3], box[2]); a.set_aspect("equal"); a.set_title(title, fontsize=11)
    plt.tight_layout(); plt.savefig(os.path.join(KIT, "zoning/coast.png"), bbox_inches="tight")
    print("sea lines %d (%d points), ponds %d" % (len(out["sea"]), sum(len(l) for l in out["sea"]), len(out["ponds"])))


if __name__ == "__main__":
    main()
