"""Street skeleton over the approved zoning map (step 2, 17 Nov).

The kit's street pieces run 100 m from a junction (apt_lib / ind_lib LEN = 100) and a sample's quadrants reach the
same 100 m, so samples tile on a 200 m junction lattice. This file snaps the locked samples onto the lattice, lays the
lattice over Coronado's grid (Amber Ave = u 0, 10th St = v 0, grid frame of grid.py), closes it with a ring of
boundary roads along the coast and the base fence, and checks it: every sample's node exists with its four legs, no
other street runs through a locked sample, neighbours leave room for each sample's street pieces, grades <= 8 %.
Reads the locked zoning files (plan.py, zones.py) and never writes them; the hill field is evaluated with the
SNAPPED sample positions (flat aprons follow the samples).
"""
import numpy as np, shapely
from shapely.geometry import LineString, Polygon, Point
from shapely.ops import unary_union
import plan
from plan import ss, CUT
from grid import to_world, to_grid

# ---- lattice lines (u across Amber toward ESE, v along Amber toward SSW)
U_LINES = {-800: "J Ave", -600: "G Ave", -400: "E Ave", -200: "C Ave", 0: "Amber Ave", 250: "B Ave", 500: "Adela Ave"}
V_LINES = {-1600: "1st St (bay front)", -1400: "3rd St", -1200: "4th St", -1000: "5th St", -800: "6th St",
           -600: "7th St", -400: "8th St", -200: "9th St", 0: "10th St", 200: "11th St"}
# real numbered streets are 176 m apart (10 of them); at 200 m nine fit: 2nd St is dropped, 3rd / 4th stay the bridge
# couplet (one-way pair), every name keeps its order. East of Amber the first line is 250 m out: the pilot's hill rows
# reach x 146 (r_n / r_s), so the next junction's quadrants start at 150. The next one is 250 m further (500): the
# strip there keeps Crown Hill's east flank (crest at u 0) under 8 % and leaves the bridge ramp 60 m to land.

# ---- locked samples snapped to lattice nodes: name -> (node u, v, yaw, rect in sample frame, legs [(dir, length)])
#   legs: directions in GRID terms (+u, -u, +v, -v) and how far the sample's own street pieces run from its junction
SNAP = {
    "P": ((0, 0), 0, (-56, 150, -100, 100), {"+u": 150, "-u": 56, "+v": 100, "-v": 100}),
    "C": ((0, -600), 0, (-59, 59, -100, 100), {"+u": 59, "-u": 59, "+v": 100, "-v": 100}),
    "A": ((250, -600), 0, (-100, 100, -100, 100), {"+u": 100, "-u": 100, "+v": 100, "-v": 100}),
    "V": ((-200, -600), 0, (-100, 100, -100, 100), {"+u": 100, "-u": 100, "+v": 100, "-v": 100}),
    "G": ((-600, -1000), 0, (-100, 100, -100, 100), {"+u": 100, "-u": 100, "+v": 100, "-v": 100}),
    "I": ((-800, -1400), 0, (-100, 100, -100, 100), {"+u": 100, "-u": 100, "+v": 100, "-v": 100}),
    "M": ((500, -1200), 0, (-100, 100, -100, 100), {"+u": 100, "-u": 100, "+v": 100, "-v": 100}),
    # yaw 90: sample +z (the pier plaza leg into the water) points +u, sample +x points -v
    "W": ((570, 200), 90, (-100, 100, -100, 40), {"+u": 0, "-u": 100, "+v": 100, "-v": 100}),
}
LABEL = {"P": "PILOT", "C": "CITY CENTRE", "A": "APARTMENTS", "V": "CIVIC", "G": "GRITTY", "I": "INDUSTRIAL",
         "M": "STRIP", "W": "WATERFRONT"}
# the stadium hangs off the civic sample's south leg (layout: civic (400,400), stadium site x 293..508, z 498..760)
STADIUM = (-200 - 107, -600 + 98, -200 + 108, -600 + 360)     # u0, v0, u1, v1
SUPERBLOCKS = {
    "stadium": [(STADIUM[0], STADIUM[1]), (STADIUM[2], STADIUM[1]), (STADIUM[2], STADIUM[3]), (STADIUM[0], STADIUM[3])],
    "university campus": [(-800, -800), (-400, -800), (-400, -400), (-800, -400)],   # 2 x 2 cells, own campus roads
    "hospital campus": [(500, -1600), (640, -1600), (660, -1400), (500, -1400)],
}
# ---- boundary ring: base fence (west), beach (south, Ocean Blvd ~75 m behind the top of the sand), Glorietta Bay +
#      golf (east, Glorietta Blvd), the bay (north, 1st St). Control points, then smoothed (no corners, no jags).
RING_CP = [(-950, -1600), (560, -1600), (640, -1545), (660, -1430), (660, -1000), (652, -400), (645, -120), (625, 10),
           (570, 100), (570, 300), (470, 335), (250, 345), (0, 340), (-300, 322), (-600, 302), (-900, 282),
           (-985, 250), (-1000, 150), (-1000, -980), (-975, -1060), (-952, -1150)]
BRIDGE = [(1320, -940), (1050, -985), (840, -1040), (700, -1090), (660, -1100)]   # lands between the couplet: Y split
FERRY = [(350, -1600), (350, -1690)]                                               # ferry landing plaza + pier root


def chaikin(pts, n=3, closed=True):
    p = np.array(pts, float)
    for _ in range(n):
        q = []
        m = len(p) if closed else len(p) - 1
        for i in range(m):
            a, b = p[i], p[(i + 1) % len(p)]
            q += [0.75 * a + 0.25 * b, 0.25 * a + 0.75 * b]
        p = np.array(q if closed else [p[0]] + q + [p[-1]])
    return [tuple(x) for x in p]


def snapped_samples():
    out = []
    for k, ((u, v), yaw, rect, _legs) in SNAP.items():
        x0, x1, z0, z1 = rect
        if k == "V":
            z1 = 360.0          # the stadium below the civic band
        if k == "W":
            z0, z1 = -102.0, 40.0
        out.append((k, (u, v), yaw, (x0, x1, z0, z1), LABEL[k]))
    return out


APRON = (40.0, 180.0)    # flat margin round every sample, then the hills / real ground ease in (as in the zoning map)
REAL_SIGMA = 500.0       # the real ground under the town is eased (gaussian, metres): Coronado's own relief is ~5 m;
                         # its local slopes (golf edge, the dome's flanks) would add to the hills. The hills are unchanged.


def blur(a, sig):
    """separable gaussian (edge-clamped), no scipy"""
    r = int(3 * sig)
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sig) ** 2); k /= k.sum()
    for ax in (0, 1):
        pad = [(0, 0), (0, 0)]; pad[ax] = (r, r)
        b = np.pad(a, pad, mode="edge")
        a = np.apply_along_axis(lambda m: np.convolve(m, k, mode="valid"), ax, b)
    return a


def height_fn():
    """final ground for the checks: real ground (smoothed over ~120 m) LEVELLED to each sample's pad (median of the
    real ground under it) inside its flat margin and eased back over APRON, plus the approved hill field evaluated with
    the SNAPPED sample positions and the same APRON"""
    from load import terrain
    m, H, C = terrain()
    ox, oz = m["origin_xz"]
    Hs = blur(H.astype(np.float64), REAL_SIGMA / 4.0)
    saved = plan.SAMPLES, plan.BUF0, plan.BUF1
    plan.SAMPLES = snapped_samples()
    plan.BUF0, plan.BUF1 = APRON
    from grid import O, A, B

    def real(u, v):
        xs = O[0] + B[0] * u + A[0] * v; zs = O[1] + B[1] * u + A[1] * v
        i = np.clip(((zs - oz) / 4).astype(int), 0, Hs.shape[0] - 1); j = np.clip(((xs - ox) / 4).astype(int), 0, Hs.shape[1] - 1)
        return Hs[i, j]
    pads = []
    for smp in plan.SAMPLES:
        x0, x1, z0, z1 = smp[3]
        xs, zs = np.meshgrid(np.arange(x0, x1 + 1, 8.0), np.arange(z0, z1 + 1, 8.0))
        uu, vv = plan.s2g(smp, xs, zs)
        pads.append((smp, float(np.median(real(uu, vv)))))

    def h(u, v):
        u = np.asarray(u, float); v = np.asarray(v, float)
        g = real(u, v)
        for smp, pad in pads:
            w = 1.0 - ss(APRON[0], APRON[1], plan.dist_rect(smp, u, v))
            g = g * (1.0 - w) + pad * w
        return g + plan.field(u, v)
    h.pads = {smp[0]: pad for smp, pad in pads}
    def restore():
        plan.SAMPLES, plan.BUF0, plan.BUF1 = saved
    h.restore = restore
    return h


def build():
    # straight edges, every corner rounded with a 45 m radius (convex and concave): no jags, no corner cutting
    ring = Polygon(RING_CP).buffer(45, join_style="round").buffer(-90, join_style="round").buffer(45, join_style="round")
    ring_line = LineString(list(ring.exterior.coords))
    sb = {k: Polygon(p) for k, p in SUPERBLOCKS.items()}
    blocked = unary_union(list(sb.values()))
    # lattice lines clipped to the ring interior, minus superblocks
    lines = []
    for u, nm in U_LINES.items():
        g = LineString([(u, -2000), (u, 800)]).intersection(ring)
        lines.append((nm, "u", u, g))
    for v, nm in V_LINES.items():
        g = LineString([(-1200, v), (900, v)]).intersection(ring)
        lines.append((nm, "v", v, g))
    # nodes: lattice crossings inside the ring + where lattice lines meet the ring
    nodes = {}
    for u in U_LINES:
        for v in V_LINES:
            p = Point(u, v)
            if ring.contains(p) and not blocked.contains(p):
                nodes[(u, v)] = "lattice"
    for nm, ax, c, g in lines:
        for seg in getattr(g, "geoms", [g]):
            if seg.is_empty:
                continue
            for e in (seg.coords[0], seg.coords[-1]):
                if ring_line.distance(Point(e)) < 1.0:
                    nodes[(round(e[0], 1), round(e[1], 1))] = "ring"
    # the bridge lands on the ring between the couplet; the ferry landing leaves 1st St
    nodes[(660.0, -1100.0)] = "bridge"
    # no junction inside a locked sample (other than its own)
    rects = sample_rects()
    for n in list(nodes):
        for k, r in rects.items():
            if n != SNAP[k][0] and r.contains(Point(n)):
                nodes.pop(n, None)
    # segments along lattice lines between consecutive nodes on the line, skipping superblocks
    segs = []
    for nm, ax, c, g in lines:
        on = sorted([n for n in nodes if (abs(n[0] - c) < 0.5 if ax == "u" else abs(n[1] - c) < 0.5)],
                    key=lambda n: n[1] if ax == "u" else n[0])
        for a, b in zip(on, on[1:]):
            ls = LineString([a, b])
            if ls.length < 1 or not ring.buffer(1.0).contains(ls):
                continue
            if ls.intersection(blocked.buffer(-1.0)).length > 1.0:     # through a superblock (its edges stay streets)
                continue
            if ring_line.distance(ls.interpolate(0.5, normalized=True)) < 2.0:   # runs along the ring: the ring has it
                continue
            if any(ls.intersection(r).length > 2.0 and SNAP[k][0] not in (a, b) for k, r in rects.items()):
                continue
            segs.append({"a": a, "b": b, "name": nm, "kind": "lattice", "pts": [a, b]})
    # ring road pieces between consecutive ring nodes (named by side)
    rc = list(ring.exterior.coords)
    ring_nodes = [n for n, t in nodes.items() if t in ("ring", "bridge")]
    pos = sorted(((ring_line.project(Point(n)), n) for n in ring_nodes))
    L = ring_line.length
    for i in range(len(pos)):
        d0, n0 = pos[i]; d1, n1 = pos[(i + 1) % len(pos)]
        if d1 <= d0:
            d1 += L
        pts = [ring_line.interpolate(d % L).coords[0] for d in np.linspace(d0, d1, max(2, int((d1 - d0) / 8)))]
        mid = Point(pts[len(pts) // 2])
        nm = ("1st St (bay front)" if mid.y < -1500 else "Glorietta Blvd" if mid.x > 500 and mid.y < 60 else
              "W leg" if mid.x > 540 else "Ocean Blvd" if mid.y > 200 else "Alameda Blvd (base fence)")
        segs.append({"a": n0, "b": n1, "name": nm, "kind": "ring", "pts": pts})
    # the bridge ramp: third leg of the Y where the couplet meets the ring
    segs.append({"a": (660.0, -1100.0), "b": tuple(BRIDGE[0]), "name": "bridge ramp", "kind": "bridge",
                 "pts": chaikin(BRIDGE[::-1], 2, closed=False)})
    nodes[tuple(BRIDGE[0])] = "bridge end"
    # ring nodes left with only the two ring pieces are not junctions: merge them away
    changed = True
    while changed:
        changed = False
        for n in [n for n, t in nodes.items() if t in ("ring",)]:
            at = [s for s in segs if n in (s["a"], s["b"])]
            if len(at) == 2 and all(s["kind"] == "ring" for s in at):
                s0, s1 = at
                p0 = s0["pts"] if s0["b"] == n else s0["pts"][::-1]
                p1 = s1["pts"] if s1["a"] == n else s1["pts"][::-1]
                a = s0["a"] if s0["b"] == n else s0["b"]
                b = s1["b"] if s1["a"] == n else s1["a"]
                segs.remove(s0); segs.remove(s1); nodes.pop(n)
                segs.append({"a": a, "b": b, "name": s0["name"], "kind": "ring", "pts": list(p0) + list(p1[1:])})
                changed = True
                break
    return ring, nodes, segs, sb


def sample_rects(shrink=1.0):
    out = {}
    for k, ((u, v), yaw, rect, legs) in SNAP.items():
        x0, x1, z0, z1 = rect
        if k == "V":
            z1 = 360.0
        a = np.radians(yaw)
        cs = [(u + x * np.cos(a) + z * np.sin(a), v - x * np.sin(a) + z * np.cos(a)) for x, z in [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]]
        out[k] = Polygon(cs).buffer(-shrink)
    return out


MAIN_LIMIT = 0.0615   # Amber, the 3rd / 4th couplet, the ring, the bridge ramp: the plan suggested <= 6 %; above = a NOTE


def is_main(s):
    return s["kind"] in ("ring", "bridge") or s["name"] in ("Amber Ave", "3rd St", "4th St")


def degree(nodes, segs):
    d = {n: 0 for n in nodes}
    for s in segs:
        d[s["a"]] = d.get(s["a"], 0) + 1; d[s["b"]] = d.get(s["b"], 0) + 1
    return d


def check(nodes, segs, sb, h):
    """returns list of (severity, text)"""
    out = []
    deg = degree(nodes, segs)
    # 1. samples: node exists, 4 legs (W: its pier leg is the 4th), legs fit before the next junction
    for k, ((u, v), yaw, rect, legs) in SNAP.items():
        n = (u, v)
        if n not in nodes:
            out.append(("FAIL", f"{k}: its junction ({u},{v}) is not on the skeleton"))
            continue
        need = 3 if k == "W" else 4
        if k == "V":
            need = 3      # its south leg is the stadium entry (the stadium is a superblock)
        if deg[n] < need:
            out.append(("FAIL", f"{k}: junction ({u},{v}) has {deg[n]} legs, needs {need}"))
        for s in segs:
            if n not in (s["a"], s["b"]):
                continue
            o = s["b"] if s["a"] == n else s["a"]
            du, dv = o[0] - u, o[1] - v
            dr = ("+u" if du > 0 else "-u") if abs(du) > abs(dv) else ("+v" if dv > 0 else "-v")
            need_len = legs.get(dr, 100) + 20.0       # own piece + the neighbour junction's box
            dist = abs(du) + abs(dv) if s["kind"] == "lattice" else LineString(s["pts"]).length
            if dist + 0.5 < need_len:
                out.append(("FAIL", f"{k}: leg {dr} is {dist:.0f} m, its street piece needs {need_len:.0f} m"))
    # 2. no other street runs through a locked sample (its own legs excepted)
    rects = {}
    for k, ((u, v), yaw, rect, legs) in SNAP.items():
        x0, x1, z0, z1 = rect
        a = np.radians(yaw)
        cs = [(u + x * np.cos(a) + z * np.sin(a), v - x * np.sin(a) + z * np.cos(a)) for x, z in [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]]
        rects[k] = Polygon(cs).buffer(-1.0)
    for s in segs:
        ls = LineString(s["pts"])
        for k, r in rects.items():
            n = SNAP[k][0]
            own = n in (s["a"], s["b"])
            if own:
                continue
            if ls.intersection(r).length > 2.0:
                out.append(("FAIL", f"{s['name']} {s['a']}->{s['b']} runs through locked {k}"))
    # 3. junctions too close to a locked sample: a lattice node inside a sample (other than its own)
    for n in nodes:
        for k, r in rects.items():
            if n != SNAP[k][0] and r.contains(Point(n)):
                out.append(("FAIL", f"junction {n} sits inside locked {k}"))
    # 4. grades (junction pads 15 m flat each end)
    worst = 0.0
    for s in segs:
        ls = LineString(s["pts"]); L = ls.length
        if L < 40:
            continue
        ds = np.linspace(0, L, max(3, int(L / 5)))
        P = np.array([ls.interpolate(d).coords[0] for d in ds])
        hh = h(P[:, 0], P[:, 1])
        g_end = abs(hh[-1] - hh[0]) / max(L - 30.0, 1.0)
        g_loc = np.max(np.abs(np.diff(hh)) / np.diff(ds)) if len(ds) > 2 else 0.0
        s["grade"] = max(g_end, g_loc)
        worst = max(worst, s["grade"])
        if s["grade"] > 0.0815:     # Yasin: max ~8 % (the pilot's built hill rows are 8.05 %)
            out.append(("FAIL", f"{s['name']} {s['a']}->{s['b']} grade {s['grade'] * 100:.1f} %"))
        elif is_main(s) and s["grade"] > MAIN_LIMIT:
            out.append(("NOTE", f"main road {s['name']} {s['a']}->{s['b']} grade {s['grade'] * 100:.1f} % (> 6 %: Yasin decides)"))
    out.append(("INFO", f"steepest street {worst * 100:.1f} %"))
    return out


if __name__ == "__main__":
    ring, nodes, segs, sb = build()
    h = height_fn()
    res = check(nodes, segs, sb, h)
    deg = degree(nodes, segs)
    import collections
    print("nodes", len(nodes), "segments", len(segs), "junction legs:", dict(collections.Counter(deg.values())))
    km = sum(LineString(s["pts"]).length for s in segs) / 1000
    print("street length %.1f km" % km)
    for sev, t in res:
        print(sev, t)
