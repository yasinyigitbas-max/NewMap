"""Hero geometry (17 Nov, Yasin: "A, but make sure that the resulting roads arent jagged ... and curve smoothly, that
includes the shore above the bridge too, it looks like minecraft now"). Pure geometry, no Godot:
  - the bridge approach (option A): straight off the deck, a reverse curve of two circular arcs (equal radius, tangent
    to each other), a straight run into the 4th St signal at the ring; the one-way off-ramp to 3rd St: a tangent
    diverge from the approach, a reverse curve, a straight run into the ring at 3rd St. Every join is tangent (G1),
    radii are reported (no kinks, no polyline corners: the pieces will sample these arcs every 2 m).
  - the coast: the water edge traced from the land-use raster (2.5 m cells) and smoothed into a vector line
    (Gaussian along the arc length), so the shore is a curve, not stair-steps. The terrain step bakes from this line.
Writes map_dc/coronado/city_kit/zoning/hero_geom.json and returns the curves for hero_sketch.py."""
import json, math, os
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.join(HERE, "../../../../map_dc/coronado/city_kit")


def arc_pts(c, r, a0, a1, step=2.0):
    n = max(2, int(abs(a1 - a0) * r / step) + 1)
    return [(c[0] + r * math.cos(a), c[1] + r * math.sin(a)) for a in np.linspace(a0, a1, n)]


def reverse_curve(p0, h0, p1, h1, straight0=0.0, straight1=0.0):
    """p0 heading h0 (radians) -> p1 heading h1 with h1 == h0 (parallel): a straight, two equal tangent arcs, a straight.
    Returns (points, radius, turn angle). The lateral offset is taken across the heading."""
    d = np.array(p1) - np.array(p0)
    t = np.array([math.cos(h0), math.sin(h0)]); nrm = np.array([-t[1], t[0]])
    along = float(d @ t) - straight0 - straight1
    off = float(d @ nrm)
    half = math.atan2(abs(off), along)           # tan(theta / 2) = off / along for two equal arcs
    theta = 2.0 * half
    R = along / (2.0 * math.sin(theta))
    s = 1.0 if off > 0 else -1.0
    q0 = np.array(p0) + t * straight0
    # first arc turns toward the offset side, second turns back
    c1 = q0 + nrm * s * R
    a_start = math.atan2(q0[1] - c1[1], q0[0] - c1[0])
    a_end = a_start + s * theta
    pts = [tuple(p0), tuple(q0)] + arc_pts(c1, R, a_start, a_end)[1:]
    mid = np.array(pts[-1])
    h_mid = h0 + s * theta
    nm = np.array([-math.sin(h_mid), math.cos(h_mid)])
    c2 = mid - nm * s * R
    b_start = math.atan2(mid[1] - c2[1], mid[0] - c2[0])
    pts += arc_pts(c2, R, b_start, b_start - s * theta)[1:]
    pts.append(tuple(p1))
    return pts, R, math.degrees(theta)


def heading_check(pts):
    """max change of heading between successive segments (deg): proves there is no kink"""
    hs = [math.atan2(b[1] - a[1], b[0] - a[0]) for a, b in zip(pts, pts[1:]) if math.hypot(b[0] - a[0], b[1] - a[1]) > 1e-6]
    return max(abs((h2 - h1 + math.pi) % (2 * math.pi) - math.pi) for h1, h2 in zip(hs, hs[1:])) * 180 / math.pi


def coast(u0=100, u1=1350, v0=-1820, v1=-820, sigma=12.0):
    """smooth water edge in the box, in grid coordinates"""
    from hstat import cls
    step = 2.5
    us = np.arange(u0, u1, step); vs = np.arange(v0, v1, step)
    W = np.array([[1.0 if cls(u, v) in (0, 7, 9) else 0.0 for u in us] for v in vs])
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    cs = plt.contour(us, vs, W, levels=[0.5])
    paths = cs.allsegs[0]
    plt.close("all")
    out = []
    for p in paths:
        if len(p) < 40:
            continue
        p = np.asarray(p)
        # resample by arc length every 2 m, then Gaussian-smooth x and y along it (closed ends kept)
        seg = np.hypot(*np.diff(p, axis=0).T); s = np.concatenate([[0], np.cumsum(seg)])
        ss = np.arange(0, s[-1], 2.0)
        x = np.interp(ss, s, p[:, 0]); y = np.interp(ss, s, p[:, 1])
        k = int(3 * sigma / 2.0); g = np.exp(-0.5 * (np.arange(-k, k + 1) * 2.0 / sigma) ** 2); g /= g.sum()
        xs = np.convolve(np.pad(x, k, mode="edge"), g, mode="valid"); ys = np.convolve(np.pad(y, k, mode="edge"), g, mode="valid")
        out.append(np.stack([xs, ys], 1))
    return out


def main():
    deck = (1180.0, -905.0); deck_dir = math.atan2(-905.0 + 925.0, 1180.0 - 1598.0)   # heading off the deck, toward the island
    gate = (660.0, -1200.0)
    # approach: lands heading due -u (onto 4th St westward); the deck heads nearly -u too: straight 30 m off the deck,
    # a reverse curve, 45 m straight into the signal
    appr, R1, th1 = reverse_curve(deck, math.pi, gate, math.pi, straight0=40.0, straight1=45.0)
    # off-ramp (right-hand traffic: westbound drivers exit to their RIGHT = north): it diverges tangentially from the
    # approach inside its first curve, turns north MORE sharply than the approach (so it separates outward), then
    # back to due -u into 3rd St (660, -1400) with 35 m of straight before the ring; it must stay >= 12 m (centreline
    # to centreline) from the approach after the 30 m gore. Search the diverge point and both radii; keep the largest
    # smallest radius.
    hs = [math.atan2(b[1] - a[1], b[0] - a[0]) for a, b in zip(appr, appr[1:])]
    A = np.array(appr)
    OFF = 12.0       # deceleration lane alongside, then the gore: the ramp's centre line starts 12 m right of the approach's
    def clear(pts):
        R = np.array(pts)
        return min(float(np.min(np.hypot(A[:, 0] - q[0], A[:, 1] - q[1]))) for q in R[::3]) >= OFF - 0.3
    best = None
    for i in range(6, len(appr) - 60, 4):
        h_div = hs[i]
        turned = ((h_div - math.pi + math.pi) % (2 * math.pi)) - math.pi
        if not (math.radians(3) < turned < math.radians(th1) * 0.9):
            continue
        right = np.array([-math.sin(h_div), math.cos(h_div)])     # right of the travel direction (u right, v down = south: facing west, right is north)
        p_start = tuple(np.array(appr[i]) + right * OFF)
        try:
            ramp_i, radii, _ = fit_two_arcs(p_start, h_div, (660.0, -1400.0), math.pi, straight1=35.0, s1_only=1.0, rmax=600.0, accept=clear)
        except RuntimeError:
            continue
        sc = min(radii)
        if best is None or sc > best[0]:
            # the deceleration-lane taper: from the approach centre line, the offset grows with a smoothstep to OFF over
            # 90 m that ends at the curve's start (tangent at both ends: no kink)
            tap = []
            j0 = max(0, i - 45)
            for j in range(j0, i + 1):
                t = (j - j0) / max(1, i - j0); o = OFF * t * t * (3 - 2 * t)
                hj = hs[min(j, len(hs) - 1)]
                tap.append(tuple(np.array(appr[j]) + np.array([-math.sin(hj), math.cos(hj)]) * o))
            best = (sc, i, tap[:-1] + ramp_i, radii, OFF)
    if best is None:
        raise RuntimeError("no off-ramp fits")
    _, i, ramp, R2, dmin = best
    print("ramp diverges at approach point %d, clearance %.1f m" % (i, dmin))
    sh = coast()
    res = {"approach": [list(map(float, p)) for p in appr], "approach_radius_m": round(R1, 1), "approach_turn_deg": round(th1, 1),
           "approach_max_kink_deg": round(heading_check(appr), 2),
           "ramp": [list(map(float, p)) for p in ramp], "ramp_radii_m": [round(r, 1) for r in R2], "ramp_max_kink_deg": round(heading_check(ramp), 2),
           "coast": [c.round(2).tolist() for c in sh]}
    json.dump(res, open(os.path.join(KIT, "zoning/hero_geom.json"), "w"))
    print("approach: R %.0f m, turn %.1f deg, max kink %.2f deg" % (R1, th1, res["approach_max_kink_deg"]))
    print("ramp: radii %s m, max kink %.2f deg" % (res["ramp_radii_m"], res["ramp_max_kink_deg"]))
    print("coast lines:", len(sh))
    return res


def fit_two_arcs(p0, h0, p1, h1, straight1=0.0, step=2.0, s1_only=None, rmax=400.0, accept=None):
    """G1 path p0 (heading h0) -> p1 (heading h1): two circular arcs turning in opposite senses (first s1), then a
    straight of length straight1 into p1. For each first radius r1 the first arc's sweep is solved exactly (the second
    arc must end tangent to the final straight: its chord must point along hm + turn / 2), by a fine scan + bisection.
    Returns (points, [r1, r2], total turn deg); the choice maximises the smaller radius."""
    q1 = np.array(p1) - straight1 * np.array([math.cos(h1), math.sin(h1)])
    wrap = lambda a: (a + math.pi) % (2 * math.pi) - math.pi
    best = None
    for s1 in ((s1_only,) if s1_only else (1.0, -1.0)):
        for r1 in np.arange(60.0, rmax, 5.0):
            c1 = np.array(p0) + s1 * r1 * np.array([-math.sin(h0), math.cos(h0)])
            a0 = math.atan2(p0[1] - c1[1], p0[0] - c1[0])
            def state(sw):
                a = a0 + s1 * sw
                m = c1 + r1 * np.array([math.cos(a), math.sin(a)])
                hm = h0 + s1 * sw
                turn = wrap(h1 - hm)
                ch = q1 - m
                return m, hm, turn, wrap(math.atan2(ch[1], ch[0]) - (hm + turn / 2.0)), float(np.linalg.norm(ch))
            sws = np.radians(np.arange(0.5, 150.0, 0.25))
            prev = None
            for sw in sws:
                m, hm, turn, e, L = state(sw)
                ok = turn * (-s1) > math.radians(1.0)
                if prev is not None and ok and prev[1] and np.sign(e) != np.sign(prev[2]) and abs(e - prev[2]) < 1.0:
                    lo, hi = prev[0], sw
                    for _ in range(40):
                        mid = 0.5 * (lo + hi)
                        if np.sign(state(mid)[3]) == np.sign(state(lo)[3]): lo = mid
                        else: hi = mid
                    m, hm, turn, e, L = state(0.5 * (lo + hi))
                    r2 = L / (2.0 * math.sin(abs(turn) / 2.0))
                    if 60.0 <= r2 <= rmax:
                        sc = min(r1, r2)
                        cand = (sc, s1, r1, 0.5 * (lo + hi), r2, turn, c1, a0, m, hm)
                        if (best is None or sc > best[0]) and (accept is None or accept(_build(cand, p1, step))):
                            best = cand
                prev = (sw, ok, e)
    if best is None:
        raise RuntimeError("no two-arc fit")
    _, s1, r1, sweep, r2, turn, c1, a0, m, hm = best
    return _build(best, p1, step), [r1, r2], math.degrees(sweep + abs(turn))


def _build(cand, p1, step):
    _, s1, r1, sweep, r2, turn, c1, a0, m, hm = cand
    pts = arc_pts(c1, r1, a0, a0 + s1 * sweep, step)
    c2 = m + (-s1) * r2 * np.array([-math.sin(hm), math.cos(hm)])
    b0 = math.atan2(m[1] - c2[1], m[0] - c2[0])
    pts += arc_pts(c2, r2, b0, b0 + turn, step)[1:]
    pts.append(tuple(p1))
    return pts


if __name__ == "__main__":
    main()
