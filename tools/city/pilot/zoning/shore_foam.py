"""Shore foam along every beach (17 Nov, Yasin: "all the shores should have the bubbles of waterfront").

The waterfront sample's foam strip (f_sw.gd, city_kit/shaders/shore_foam.gdshader) along the WHOLE island's water line:
  - the line = the 0 m contour of the final terrain (terrain_grid.npz; the game's sea plane is at 0), lightly smoothed
    and resampled every 1 m, so the foam sits exactly where the water meets the sand
  - skipped where a piece meets the water (seawalls, piers, 1st St, the waterfront's own foam beach: any piece ground
    within 7 m) and on scraps shorter than 25 m
  - the strip: 3 m up the sand to 4.5 m out (13 rows), y = max(terrain, sea) + 2 cm, UV like f_sw (UV.y 0 sand -> 1 sea,
    still-water line at 3 / 7.5; UV.x fades only over the first / last 6 m of a run)
  - chunks of ~120 m (one draw each, culled at 220 m like f_sw)
Output: map_dc/coronado/city_kit/zoning/shore_foam.json (grid frame); the piece x_shore_foam (pieces/x_shore_foam.gd)
builds the meshes from it. Rerun after terrain.py.
"""
import json, os
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.normpath(os.path.join(HERE, "../../../../map_dc/coronado/city_kit"))
ROWS = np.linspace(-3.0, 4.5, 13)       # metres along the seaward normal
CHUNK = 120.0
FADE = 6.0


def main():
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    b = np.load(os.path.join(KIT, "zoning/terrain_grid.npz"))
    H = b["heights"].astype(float); u0 = float(b["u0"]); v0 = float(b["v0"]); st = float(b["step"])
    ny, nx = H.shape
    us = u0 + st * np.arange(nx); vs = v0 + st * np.arange(ny)
    pg = np.load(os.path.join(KIT, "zoning/piece_ground.npz")); R = pg["ground"]; pu0 = float(pg["u0"]); pv0 = float(pg["v0"])
    from scipy.ndimage import binary_dilation
    pmask = binary_dilation(np.isfinite(R), iterations=7)

    def hs(u, v):
        fx = np.clip((u - u0) / st, 0, nx - 1.001); fy = np.clip((v - v0) / st, 0, ny - 1.001)
        i = fx.astype(int); j = fy.astype(int); tx = fx - i; ty = fy - j
        return H[j, i] * (1 - tx) * (1 - ty) + H[j, i + 1] * tx * (1 - ty) + H[j + 1, i] * (1 - tx) * ty + H[j + 1, i + 1] * tx * ty

    def near_piece(u, v):
        i = np.clip((u - pu0).astype(int), 0, R.shape[1] - 1); j = np.clip((v - pv0).astype(int), 0, R.shape[0] - 1)
        return pmask[j, i]

    cs = plt.contour(us, vs, H, levels=[0.0])
    runs = []
    for seg in cs.allsegs[0]:
        if len(seg) < 10:
            continue
        # resample every 1 m, then smooth (moving average over 9 m) and resample again
        d = np.r_[0, np.cumsum(np.hypot(*np.diff(seg, axis=0).T))]
        if d[-1] < 25:
            continue
        s = np.arange(0, d[-1], 1.0)
        p = np.c_[np.interp(s, d, seg[:, 0]), np.interp(s, d, seg[:, 1])]
        k = np.ones(9) / 9.0
        if len(p) > 20:
            p = np.c_[np.convolve(np.pad(p[:, 0], 4, mode="edge"), k, "valid"), np.convolve(np.pad(p[:, 1], 4, mode="edge"), k, "valid")]
        # keep the stretches away from pieces and inside the terrain box
        ok = ~near_piece(p[:, 0], p[:, 1]) & (p[:, 0] > u0 + 8) & (p[:, 0] < us[-1] - 8) & (p[:, 1] > v0 + 8) & (p[:, 1] < vs[-1] - 8)
        cur = []
        for q, o in zip(p, ok):
            if o:
                cur.append(q)
            elif cur:
                runs.append(np.array(cur)); cur = []
        if cur:
            runs.append(np.array(cur))
    runs = [r for r in runs if len(r) >= 25]
    chunks = []
    total = 0.0
    for r in runs:
        t = np.gradient(r, axis=0); t /= np.linalg.norm(t, axis=1)[:, None]
        n = np.c_[t[:, 1], -t[:, 0]]
        # orient the normal seaward (terrain falls along it)
        probe = hs(r[:, 0] + 3 * n[:, 0], r[:, 1] + 3 * n[:, 1]) - hs(r[:, 0] - 3 * n[:, 0], r[:, 1] - 3 * n[:, 1])
        if np.median(probe) > 0:
            n = -n
        L = len(r) - 1.0
        total += L
        ux = np.where(np.arange(len(r)) < FADE, np.arange(len(r)) / FADE * 0.03,
                      np.where(np.arange(len(r)) > L - FADE, 1.0 - (L - np.arange(len(r))) / FADE * 0.03, 0.5))
        verts = np.zeros((len(r), len(ROWS), 3))
        for k_, o in enumerate(ROWS):
            pu = r[:, 0] + o * n[:, 0]; pv = r[:, 1] + o * n[:, 1]
            verts[:, k_, 0] = pu; verts[:, k_, 2] = pv
            verts[:, k_, 1] = np.maximum(hs(pu, pv), 0.0) + 0.02
        step = int(CHUNK)
        for a in range(0, len(r) - 1, step):
            bnd = min(a + step, len(r) - 1)
            chunks.append({"n": bnd - a + 1, "rows": len(ROWS),
                           "v": [round(float(x), 3) for x in verts[a:bnd + 1].ravel()],
                           "ux": [round(float(x), 4) for x in ux[a:bnd + 1]]})
    out = {"note": __doc__.strip().split("\n")[0], "rows_v": [round(float((o - ROWS[0]) / (ROWS[-1] - ROWS[0])), 4) for o in ROWS],
           "shore_v": 3.0 / 7.5, "chunks": chunks}
    json.dump(out, open(os.path.join(KIT, "zoning/shore_foam.json"), "w"))
    print("shore foam: %d runs, %.0f m of beach, %d chunks" % (len(runs), total, len(chunks)))


if __name__ == "__main__":
    main()
