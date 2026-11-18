"""Ferry landing site plan (17 Nov, hero site, HERO_DESIGN.md; Yasin: "landing is a go"). Picture for Yasin before the
hand-made build: zoning/ferry_plan.png. Grid frame (u, v): the bay to the north (up), 1st St (the ring, at +2 m since
17 Nov) along the bottom. Heights: the quay walk 1.5 m over the sea (as at the waterfront sample), rising 0.65 m to
1st St's walk over ~130 m (0.5 %, no steps)."""
import json, os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyBboxPatch, Circle, Polygon

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.normpath(os.path.join(HERE, "../../../../map_dc/coronado/city_kit"))

QUAY = -1748.0           # seawall water face (straight, between u 190 and 480)
ST_EDGE = -1619.0        # 1st St bay-side walk edge (the ring pieces)

# [label, u0, v0, u1, v1, colour]
AREAS = [
    ["1st St (ring, +2 m)", 150, -1619, 520, -1581, "#555"],
    ["commuter lot ~110 stalls", 200, -1732, 318, -1630, "#8a8a8a"],
    ["plaza", 325, -1736, 375, -1720, "#e6dcc6"],
    ["museum plaza", 398, -1690, 436, -1640, "#e6dcc6"],
    ["market lane", 385, -1703, 470, -1695, "#e6dcc6"],
]
BUILD = [
    ["TERMINAL\n(civ_harbor_office)", 350, -1712, 16, 12],
    ["MUSEUM\n(civ_museum)", 455, -1665, 15, 24],
    ["bistro", 394, -1712, 12, 14], ["cafe", 409, -1712, 6, 14], ["surf", 420, -1712, 9, 14],
    ["books", 431, -1715, 6.5, 6], ["cafe", 440, -1715, 7.5, 6.5], ["surf", 451, -1715, 9, 7], ["kiosk", 462, -1715, 4, 6],
]


def main():
    tg = np.load(os.path.join(KIT, "zoning/terrain_grid.npz"))
    H = tg["heights"]; u0 = float(tg["u0"]); v0 = float(tg["v0"])
    us = u0 + 4 * np.arange(H.shape[1]); vs = v0 + 4 * np.arange(H.shape[0])
    fig, ax = plt.subplots(figsize=(14, 8.5), dpi=110)
    ax.set_facecolor("#9fc8d9")
    land = np.where(H > 0, 1.0, np.nan)
    ax.contourf(us, vs, H, levels=[0, 50], colors=["#cfdcae"])
    ax.contour(us, vs, H, levels=[0.0], colors="#1565c0", linewidths=1.0)
    # (Yasin 17 Nov: "some of the promenade is ahead of shoreline") the seawall follows the smooth water line 2 m
    # inland (the terrain's 0 m contour, smoothed over 40 m), the promenade is the 10 m band behind it
    cs = plt.contour(us, vs, H, levels=[0.0], alpha=0)
    pts = np.concatenate([sg for sg in cs.allsegs[0] if len(sg) > 50])
    pts = pts[(pts[:, 0] > 150) & (pts[:, 0] < 520) & (pts[:, 1] < -1700) & (pts[:, 1] > -1800)]
    uq = np.arange(190, 481, 2.0)
    order = np.argsort(pts[:, 0]); vq = np.interp(uq, pts[order, 0], pts[order, 1])
    k = np.ones(21) / 21.0; vq = np.convolve(np.pad(vq, 10, mode="edge"), k, "valid") + 2.0
    np.save(os.path.join(KIT, "zoning/ferry_quay.npy"), np.c_[uq, vq])
    ax.fill_between(uq, vq, vq + 10.0, color="#d9cfb8", zorder=2)
    ax.plot(uq, vq, color="#444", lw=2.5, zorder=5)
    ax.text(200, vq[5] + 5, "promenade (seawall follows the shore; benches face the bay)", fontsize=6.5, va="center", zorder=6)
    for bu in range(200, 481, 22):
        ax.plot(bu, np.interp(bu, uq, vq) + 7, "o", color="#5d4037", ms=2.2, zorder=6)
    QV = lambda u: float(np.interp(u, uq, vq))
    for lab, a, b, c, d, col in AREAS:
        ax.add_patch(Rectangle((a, b), c - a, d - b, color=col, alpha=0.9, zorder=2))
        ax.text((a + c) / 2, (b + d) / 2, lab, ha="center", va="center", fontsize=7, zorder=5,
                color="white" if col in ("#555", "#8a8a8a") else "#333")
    # lot aisles
    for k in range(4):
        y = -1720 + k * 26
        ax.add_patch(Rectangle((206, y), 106, 6, color="#6c6c6c", zorder=3))
    # the entry drive + drop-off loop with a planted island
    ax.add_patch(Rectangle((343, -1660), 14, 41, color="#555", zorder=3))
    ax.add_patch(FancyBboxPatch((322, -1700), 56, 42, boxstyle="round,pad=0,rounding_size=14", color="#555", zorder=3))
    ax.add_patch(FancyBboxPatch((334, -1690), 32, 22, boxstyle="round,pad=0,rounding_size=8", color="#7ea35b", zorder=4))
    ax.text(350, -1679, "palms, flag,\nwelcome sign", ha="center", va="center", fontsize=6, zorder=5)
    ax.text(318, -1693, "taxi\nbay", ha="right", fontsize=6, zorder=5)
    ax.text(382, -1693, "drop-off", ha="left", fontsize=6, zorder=5)
    ax.add_patch(Rectangle((300, -1650), 43, 6, color="#555", zorder=3))      # lot entrance off the drive
    for lab, cu, cv, w, d in BUILD:
        ax.add_patch(Rectangle((cu - w / 2, cv - d / 2), w, d, color="#b5651d" if "MUSEUM" in lab or "TERMINAL" in lab else "#c98f5a", zorder=4))
        ax.text(cu, cv, lab, ha="center", va="center", fontsize=6 if len(lab) < 8 else 6.5, color="white", zorder=6)
    # the quay line, the ferry pier, T-head, float and the ferry
    ax.add_patch(Rectangle((347.6, -1778), 4.8, QV(350) + 1778, color="#8d6e4a", zorder=5))
    ax.add_patch(Rectangle((341, -1786), 18, 8, color="#8d6e4a", zorder=5))
    ax.add_patch(Rectangle((322, -1786), 14, 3.2, color="#a1887f", zorder=5))
    ax.add_patch(Polygon([(318, -1792), (338, -1792), (342, -1789.5), (338, -1787), (318, -1787)], color="white", ec="#333", zorder=6))
    ax.text(330, -1795, "ferry (float, gangway)", ha="center", fontsize=6.5, zorder=6)
    ax.text(362, -1784, "T-head: fishing,\nbenches to the skyline", fontsize=6, zorder=6)
    # 1st St: the entrance signal + crosswalk in the 45 m ring gap, bus stops both ways
    ax.add_patch(Rectangle((327.5, -1619), 45, 38, fill=False, ec="yellow", lw=1.5, ls="--", zorder=6))
    ax.text(350, -1575, "45 m ring gap: signalised T + crosswalk", ha="center", fontsize=6.5, color="#333", zorder=6)
    for u_, lab in ((312, "bus (east-bound)"), (388, "bus (west-bound)")):
        ax.plot(u_, -1617 if u_ < 350 else -1583, "s", color="#e53935", ms=5, zorder=7)
        ax.text(u_, -1611 if u_ < 350 else -1589, lab, fontsize=5.5, ha="center", zorder=7)
    ax.text(470, -1765, "BAY - San Diego skyline", fontsize=8, color="#0d47a1", ha="right")
    ax.set_xlim(150, 520); ax.set_ylim(-1560, -1810)
    ax.set_aspect("equal")
    ax.set_title("Ferry landing site plan (draft): terminal on the entrance axis, market + museum east, commuter lot west,\n"
                 "seawall promenade along the bay, pier + float to the ferry; heights 1.5 m (quay) -> 2.15 m (1st St walk), 0.5 %", fontsize=9)
    ax.set_xlabel("u (m, along 1st St)"); ax.set_ylabel("v (m): bay up")
    plt.savefig(os.path.join(KIT, "zoning/ferry_plan.png"), bbox_inches="tight")
    print("ok")


if __name__ == "__main__":
    main()
