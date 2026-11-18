"""Hero sites on paper (17 Nov): the bridge landing and the ferry landing, over the locked skeleton. Draws
map_dc/coronado/city_kit/zoning/hero_sketch.png in the grid frame (u right, v down = SSW; north is up-left)."""
import json, os, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MP, Patch
from matplotlib.lines import Line2D
from hstat import cls
HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(HERE, "../../../../map_dc/coronado/city_kit")
sites = json.load(open(os.path.join(KIT, "review/sites.json")))
u0, u1, v0, v1 = 100, 1350, -1820, -820
# smooth land / sea (Yasin: "it looks like minecraft now"): the water mask at 2.5 m, Gaussian-blurred (sigma 12 m),
# filled at 0.5 - the same smoothing the terrain step uses for the coast; parks drawn the same way
step = 2.5
us = np.arange(u0, u1, step); vs = np.arange(v0, v1, step)
C = np.array([[cls(u, v) for u in us] for v in vs])
def blur(a, sig_m):
    sig = sig_m / step; r = int(3 * sig); k = np.exp(-0.5 * (np.arange(-r, r + 1) / sig) ** 2); k /= k.sum()
    a = np.apply_along_axis(lambda m: np.convolve(np.pad(m, r, mode="edge"), k, mode="valid"), 0, a)
    return np.apply_along_axis(lambda m: np.convolve(np.pad(m, r, mode="edge"), k, mode="valid"), 1, a)
water = blur(np.isin(C, [0, 7, 9]).astype(float), 12.0)
park = blur(np.isin(C, [3, 10]).astype(float), 10.0)
fig, ax = plt.subplots(figsize=(15, 12), dpi=100)
ax.set_facecolor((0.93, 0.92, 0.9))
ax.contourf(us, vs, park, levels=[0.5, 2], colors=[(0.8, 0.88, 0.72)], zorder=0)
ax.contourf(us, vs, water, levels=[0.5, 2], colors=[(0.47, 0.67, 0.8)], zorder=1)
ax.contour(us, vs, water, levels=[0.5], colors=["#2f5f80"], linewidths=1.2, zorder=1)
for b in sites["blocks"]:
    pts = np.array(b["pts"]) if b.get("pts") else np.array([b["a"], b["b"]])
    col = {"ring": "#00838f", "couplet": "#ad1457", "bridge": "#888"}.get(b["section"], "#555")
    ax.plot(pts[:, 0], pts[:, 1], color=col, lw=6 if b["section"] in ("ring", "couplet") else 3, alpha=0.5 if b["section"] == "bridge" else 0.9, zorder=2)
for n in sites["nodes"]:
    if u0 < n["u"] < u1 and v0 < n["v"] < v1:
        ax.plot(n["u"], n["v"], "o", color="k", ms=5, zorder=3)
        ax.text(n["u"] + 8, n["v"] - 8, "%s %.0f m" % (n["kind"][0].upper(), n["pad"]), fontsize=7, zorder=4)
# the real bridge deck end (OSM 4th Street motorway, y 6.9 at the shore, 24 m out over the bay)
ax.plot([1180, 1598], [-905, -925], color="#37474f", lw=9, zorder=2); ax.text(1185, -880, "real bridge deck\nends here, 6.9 m up", fontsize=8)
# OPTION A (recommended): divided approach on 4th St's axis + an off-ramp branch to 3rd St
G = json.load(open(os.path.join(KIT, "zoning/hero_geom.json")))
A = np.array(G["approach"]); B3 = np.array(G["ramp"])
ax.plot(A[:, 0], A[:, 1], color="#e65100", lw=7, zorder=5, solid_capstyle="round")
ax.plot(B3[:, 0], B3[:, 1], color="#ff9800", lw=4, zorder=5, solid_capstyle="round")
ax.text(980, -1060, "A (approved): bridge approach (2+2, median palms),\nreverse curve R %.0f m, lands on 4th St at the ring:\na 4-way signal, the island's gateway" % G["approach_radius_m"], fontsize=9, color="#bf360c", fontweight="bold")
ax.text(760, -1330, "one-way off-ramp to 3rd St\nR %.0f / %.0f m" % tuple(G["ramp_radii_m"]), fontsize=8, color="#e65100")
ax.plot(660, -1100, "x", color="#c62828", ms=14, mew=3, zorder=6); ax.text(560, -1080, "skeleton bridge node:\nnot needed in A", fontsize=8, color="#c62828")
# ferry landing plan (u 230..470 between 1st St at v -1600 and the shore at ~-1750)
def box(c, w, h, col, lab):
    ax.add_patch(MP([(c[0]-w/2, c[1]-h/2), (c[0]+w/2, c[1]-h/2), (c[0]+w/2, c[1]+h/2), (c[0]-w/2, c[1]+h/2)], fc=col, ec="k", lw=1, alpha=0.8, zorder=5))
    ax.text(c[0], c[1], lab, fontsize=7, ha="center", va="center", zorder=6)
box((300, -1640), 90, 50, "#ffe082", "ferry terminal\n+ shops")
box((410, -1650), 70, 60, "#ffd54f", "MUSEUM\n(maritime +\nnaval air)")
box((350, -1700), 230, 40, "#fff3e0", "seawall promenade: benches\nfacing the San Diego skyline")
ax.plot([350, 350], [-1725, -1800], color="#795548", lw=6, zorder=6); ax.text(356, -1795, "ferry pier + float", fontsize=8)
box((220, -1640), 60, 50, "#cfd8dc", "commuter\nlot")
ax.text(240, -1585, "1st St: bus stops both ways,\ntaxi / drop-off bay, bike racks", fontsize=8, color="#004d40")
ax.legend(handles=[Line2D([], [], color="#e65100", lw=6, label="A: bridge approach onto 4th St"), Line2D([], [], color="#ff9800", lw=3, label="A: off-ramp to 3rd St"),
                   Line2D([], [], color="#00838f", lw=5, label="ring boulevard"), Line2D([], [], color="#ad1457", lw=5, label="3rd / 4th St arterials"),
                   Patch(fc=(0.8, 0.88, 0.72), label="park at the bridge foot"), Line2D([], [], marker="o", ls="", color="k", label="junction (R ring, L lattice, B bridge) + pad height")],
          loc="lower left", fontsize=9)
ax.set_xlim(u0, u1); ax.set_ylim(v1, v0); ax.set_aspect("equal")
ax.set_title("Hero sites, smooth geometry (option A approved, ferry landing approved) (grid frame: u right, v down = toward the south-west; north is to the upper left)", fontsize=12)
plt.savefig(os.path.join(KIT, "zoning/hero_sketch.png"), bbox_inches="tight"); print("ok")
