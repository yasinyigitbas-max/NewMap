"""Picture of the street skeleton (streets.py) over Coronado, north up. Output: map_dc/coronado/city_kit/zoning/."""
import os, sys, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MP, Patch
from matplotlib.lines import Line2D
import shapely
from shapely.geometry import Polygon, LineString, Point
from load import terrain, roads
from grid import to_world, to_grid, O, A, B
import plan
from plan import CUT
from zones import Z, MUST, HERO
import streets as ST

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../../map_dc/coronado/city_kit/zoning/",
                   sys.argv[1] if len(sys.argv) > 1 else "streets_map.png")
m, H, C = terrain(); d = roads(); ox, oz = m["origin_xz"]; cr = m["class_res"]
x0, x1, z0, z1 = -3150, -350, 1400, 4120
W2 = lambda pts: [to_world(u, v) for u, v in pts]
fig, ax = plt.subplots(figsize=(20, 20 * (z1 - z0) / (x1 - x0)), dpi=110)
# ---- base: land use with the coast cut
Cc = C[int((z0 - oz) / cr):int((z1 - oz) / cr), int((x0 - ox) / cr):int((x1 - ox) / cr)].copy()
cut = Polygon(CUT)
gx = np.linspace(x0, x1, Cc.shape[1], endpoint=False) + cr / 2; gz = np.linspace(z0, z1, Cc.shape[0], endpoint=False) + cr / 2
GX, GZ = np.meshgrid(gx, gz); Cc[shapely.contains_xy(cut, GX, GZ)] = 0
pal = np.array([[120, 170, 205], [240, 238, 232], [240, 226, 175], [214, 230, 196], [196, 222, 176], [222, 220, 228], [212, 212, 212],
                [120, 170, 205], [180, 214, 162], [120, 170, 205], [205, 228, 190], [222, 224, 205], [210, 200, 190], [196, 222, 176],
                [215, 215, 215], [232, 229, 220]], dtype=np.uint8)
ax.imshow(pal[Cc], extent=[x0, x1, z1, z0], zorder=0)
# ---- zones, very light
for k, (lab, col, polys) in Z.items():
    for p in polys:
        g = Polygon(W2(p)).difference(cut)
        for gg in getattr(g, "geoms", [g]):
            if not gg.is_empty:
                ax.add_patch(MP(list(gg.exterior.coords), closed=True, fc=col, ec="none", alpha=0.16, zorder=1))
# ---- today's OSM streets, faint, for comparison
for e in d["edges"]:
    if e["region"] != "coronado" or e["hw"] == "service":
        continue
    p = np.array(e["pts"])
    if p[:, 0].max() < x0 or p[:, 0].min() > x1 or p[:, 2].max() < z0 or p[:, 2].min() > z1:
        continue
    keep = ~shapely.contains_xy(cut, p[:, 0], p[:, 2])
    p = np.where(keep[:, None], p, np.nan)
    ax.plot(p[:, 0], p[:, 2], color="#b9b4aa", lw=0.6, zorder=2)
# ---- final ground contours (hills with the snapped aprons + eased real ground), every 2 m
h = ST.height_fn()
U, V = np.meshgrid(np.arange(-1150, 800, 10.0), np.arange(-1750, 450, 10.0))
F = h(U, V)
ring, nodes, segs, sb = ST.build()
RES = ST.check(nodes, segs, sb, h)          # also stores each street's grade
inside = shapely.contains_xy(ring.buffer(30), U, V)
F = np.where(inside, F, np.nan)
X = O[0] + B[0] * U + A[0] * V; Zw = O[1] + B[1] * U + A[1] * V
lv = np.arange(np.floor(np.nanmin(F)), np.nanmax(F) + 1, 2.0)
cs = ax.contour(X, Zw, F, levels=lv, colors="#8a6a3a", linewidths=0.6, alpha=0.75, zorder=3)
ax.clabel(cs, fmt="%d m", fontsize=6.5, colors="#6d4c1f", inline_spacing=2)
# ---- street sections by zone
SEC = {
    "cc": ("centre: 6.4-6.9 m sidewalks, no parking (s_cc_*)", "#c0392b", 4.2),
    "hs": ("high street: parking lanes (s_amber_*)", "#e67e22", 4.2),
    "strip": ("arterial: turn lane + bike lanes (s_strip_art)", "#d81b8c", 4.0),
    "couplet": ("3rd / 4th: one-way bridge couplet (arterial)", "#ad1457", 4.0),
    "ind": ("truck street, 4 lanes (s_ind)", "#546e7a", 3.6),
    "std": ("standard: parkway + alleys (s_apt)", "#7e57c2", 2.6),
    "res": ("residential: parkway trees (s_10th_e)", "#7c8a2a", 2.4),
    "ring": ("boulevard round the island (NEW curved pieces)", "#00838f", 4.0),
    "bridge": ("bridge ramp (kept)", "#37474f", 4.5),
}
ZPRI = ["cc", "hs", "strip", "ind", "hosp", "grt", "apt", "civ", "uni", "wf", "res"]
zpolys = {k: [Polygon(p) for p in Z[k][2]] for k in Z}


def section(s):
    if s["kind"] == "ring":
        return "ring"
    if s["kind"] == "bridge":
        return "bridge"
    if s["name"] in ("3rd St", "4th St"):
        return "couplet"
    mid = LineString(s["pts"]).interpolate(0.5, normalized=True)
    for k in ZPRI:
        if any(p.contains(mid) for p in zpolys[k]):
            return {"cc": "cc", "hs": "hs", "strip": "strip", "ind": "ind", "res": "res"}.get(k, "std")
    return "res"


used = set()
for s in segs:
    k = section(s); used.add(k)
    lab, col, lw = SEC[k]
    P = np.array(W2(s["pts"]))
    ax.plot(P[:, 0], P[:, 1], color="white", lw=lw + 2.2, solid_capstyle="round", zorder=4)
    ax.plot(P[:, 0], P[:, 1], color=col, lw=lw, solid_capstyle="round", zorder=5)
    g = s.get("grade", 0.0)
    if g >= 0.045:
        mp = LineString(P).interpolate(0.5, normalized=True)
        ax.text(mp.x, mp.y, ("%.1f%%" if g >= 0.0695 else "%.0f%%") % (g * 100), fontsize=7.5, fontweight="bold", ha="center", va="center", zorder=9,
                color="#b71c1c" if g >= 0.07 else "#e65100", bbox=dict(fc="white", ec="none", alpha=0.85, pad=0.6))
# ---- junction types
deg = ST.degree(nodes, segs)
for n, k in deg.items():
    x, z = to_world(*n)
    if k >= 4:
        ax.plot(x, z, "o", ms=4.2, mfc="#111", mec="white", mew=0.8, zorder=7)
    elif k == 3:
        ax.plot(x, z, "^", ms=5.0, mfc="#fff", mec="#111", mew=1.0, zorder=7)
# ---- superblocks
for nm, p in ST.SUPERBLOCKS.items():
    pc = Polygon(p).intersection(ring)
    ax.add_patch(MP(W2(list(pc.exterior.coords)), closed=True, fill=False, ec="#333", lw=1.3, ls=(0, (5, 3)), zorder=6))
    cu = np.mean([q[0] for q in p]); cv = np.mean([q[1] for q in p])
    if nm != "stadium":
        x, z = to_world(cu, cv)
        x, z = to_world(cu, cv + 70)
        ax.text(x, z, nm + "\n(own internal roads)", fontsize=8, ha="center", va="center", style="italic", zorder=8,
                bbox=dict(fc="white", ec="none", alpha=0.7, pad=1))
# ---- locked samples at their snapped junctions
for smp in ST.snapped_samples():
    poly = W2(plan.rect_g(smp))
    ax.add_patch(MP(poly, closed=True, fc="white", ec="#111", lw=2.0, alpha=0.55, hatch="///", zorder=6))
    k = smp[0]; (u, v) = smp[1]
    lab = ST.LABEL[k] + ("\n+ STADIUM" if k == "V" else "")
    cx, cz = to_world(*(plan.s2g(smp, 0, 60) if k == "V" else (u, v)))
    ax.text(cx, cz + (0 if k != "W" else 0), lab, fontsize=8, fontweight="bold", ha="center", va="center", zorder=10,
            bbox=dict(fc="#fffbe6", ec="#111", lw=0.8, alpha=0.95, pad=1.5))
# ---- MUST / hero sites (zoning positions)
for nm, txt, (u, v) in MUST:
    if nm == "UNIVERSITY":
        u, v = -600, -600
    if nm == "HOSPITAL":
        u, v = 575, -1500
    x, z = to_world(u, v)
    ax.plot(x, z, marker="*", ms=20, mfc="#ffd400", mec="#b00", mew=1.4, zorder=11)
    ax.text(x + 28, z - 18, nm, fontsize=8, color="#900", fontweight="bold", zorder=11,
            bbox=dict(fc="white", ec="none", alpha=0.8, pad=1))
for nm, (u, v) in HERO:
    x, z = to_world(u, v)
    ax.plot(x, z, marker="D", ms=9, mfc="#fff", mec="#000", zorder=11)
# ---- ferry landing, bridge label
fx, fz = zip(*W2(ST.FERRY)); ax.plot(fx, fz, color="#00838f", lw=3, ls=":", zorder=5)
x, z = to_world(330, -1730); ax.text(x, z, "ferry landing", fontsize=8, style="italic", zorder=8)
x, z = to_world(1000, -1060); ax.text(x, z, "bridge to San Diego\n(Y split onto 3rd / 4th)", fontsize=8, style="italic", zorder=8)
# ---- street names (once each, at a quiet spot)
NAMEPOS = {"Amber Ave": (0, -1470), "1st St (bay front)": (-450, -1600), "3rd St": (-430, -1400), "4th St": (-430, -1200),
           "6th St": (-930, -800), "7th St": (120, -600), "8th St": (380, -400), "9th St": (120, -200), "10th St": (-350, 0),
           "11th St": (-350, 200), "J Ave": (-800, -1150), "G Ave": (-600, -1300), "E Ave": (-400, -1300), "C Ave": (-200, -1300),
           "B Ave": (250, -900), "Adela Ave": (500, -800), "5th St": (-930, -1000)}
for nm, (u, v) in NAMEPOS.items():
    x, z = to_world(u, v)
    rot = -63.6 if nm.endswith("Ave") else -26.4
    ax.text(x, z, nm, fontsize=7.5, rotation=rot, ha="center", va="center", zorder=9, color="#111",
            bbox=dict(fc="white", ec="none", alpha=0.75, pad=0.5))
for nm, (u, v) in {"Ocean Blvd": (-500, 318), "Glorietta Blvd": (690, -700), "Alameda Blvd": (-1040, -400)}.items():
    x, z = to_world(u, v)
    ax.text(x, z, nm, fontsize=8, rotation=-26.4 if nm == "Ocean Blvd" else -63.6, ha="center", va="center", zorder=9,
            color="#00616a", fontweight="bold")
# ---- legend
hd = [Line2D([], [], color=SEC[k][1], lw=SEC[k][2], label=SEC[k][0]) for k in SEC if k in used]
hd += [Line2D([], [], marker="o", ls="", ms=6, mfc="#111", mec="white", label="crossroads (%d)" % sum(1 for k in deg.values() if k >= 4)),
       Line2D([], [], marker="^", ls="", ms=7, mfc="#fff", mec="#111", label="T junction (%d)" % sum(1 for k in deg.values() if k == 3)),
       Patch(fc="white", ec="#111", hatch="///", label="locked sample on its junction (snapped)"),
       Line2D([], [], color="#333", ls=(0, (5, 3)), label="superblock: no through street"),
       Line2D([], [], color="#8a6a3a", lw=0.8, label="ground height every 2 m (hills + eased real ground)"),
       Line2D([], [], color="#b9b4aa", lw=1, label="today's OSM streets (for comparison)"),
       Line2D([], [], ls="", marker="$8\\%$", ms=14, color="#b71c1c", label="street grade, shown from 5 % (max 8 %)")]
ax.legend(handles=hd, loc="lower left", fontsize=8.5, framealpha=0.94)
ax.annotate("N", xy=(x1 - 110, z0 + 60), xytext=(x1 - 110, z0 + 220), ha="center", fontsize=14, fontweight="bold",
            arrowprops=dict(arrowstyle="-|>", lw=2))
ax.plot([x1 - 650, x1 - 150], [z1 - 70, z1 - 70], color="k", lw=4); ax.text(x1 - 400, z1 - 95, "500 m", ha="center", fontsize=10)
km = sum(LineString(s["pts"]).length for s in segs) / 1000
ax.set_title("Coronado street skeleton (APPROVED 17 Nov, locked): 200 m junction grid on Amber's bearing, samples snapped, boulevard round the "
             "island (%.1f km of street)" % km, fontsize=13)
ax.set_xlim(x0, x1); ax.set_ylim(z1, z0); ax.set_aspect("equal"); ax.set_xticks([]); ax.set_yticks([])
plt.savefig(OUT, bbox_inches="tight")
print("ok", OUT)
