"""Grading plan (17 Nov, road kit step 2): a level pad height for every junction of the locked street skeleton.

Junction pads are level (the road kit's junction pieces are flat), so a block's whole rise happens between two pads.
The kit's sloped legs rise H with a smoothstep across the 160 m between the junction tiles of a 200 m block: max
grade 1.5 H / 160 (H 8 m -> 7.5 %). This file:
  1. reads the locked skeleton (streets.py) and its final ground (approved hills + eased real ground),
  2. snaps every junction to a 2 m step (so blocks rise 0, 2, 4, 6 or 8 m: a small set of pieces),
  3. nudges junctions, 2 m at a time, until every block is at most 8 % (Yasin's limit) with the kit's profile:
     200 m blocks H <= 8 m; other lengths H <= 0.08 * (L - 40) / 1.5. Locked samples keep their junction where it is.
  4. writes map_dc/coronado/city_kit/zoning/grading.json (junction -> pad height, block -> rise) and prints what the
     road kit must provide (rise classes per street section).
Reads streets.py / plan.py (locked); writes only grading.json.
"""
import json, os, sys, collections
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "../../../../map_dc/coronado/city_kit/zoning/grading.json")
STEP = 2.0
GRADE = 0.08


def hmax(L):
    if abs(L - 200.0) < 1.0:
        return 8.0
    return max(0.0, np.floor(GRADE * (L - 40.0) / 1.5 / STEP) * STEP)


def main():
    sys.argv = ["x", "/dev/null"]
    import matplotlib
    matplotlib.use("Agg")
    src = open(os.path.join(HERE, "render_streets.py")).read().split("used = set()")[0]
    src = src.replace('OUT = os.path.join', 'OUT = "/dev/null" or os.path.join')
    ns = {}
    exec(src, ns)
    segs, nodes, section, h, ST = ns["segs"], ns["nodes"], ns["section"], ns["h"], ns["ST"]
    field = {n: float(h(np.array(n[0]), np.array(n[1]))) for n in nodes}
    H = {n: round(field[n] / STEP) * STEP for n in nodes}
    fixed = {tuple(map(float, ST.SNAP[k][0])) for k in ST.SNAP}
    lat = [s for s in segs if s["kind"] in ("lattice", "ring")]

    def length(s):
        a, b = s["a"], s["b"]
        if s["kind"] == "lattice":
            return abs(a[0] - b[0]) + abs(a[1] - b[1])
        p = np.array(s["pts"])
        return float(np.sum(np.hypot(*np.diff(p, axis=0).T)))

    # 1. continuous projection: every too-steep block pulls its two pads together (a locked sample's pad stays put),
    #    with a weak pull back toward the ground; many sweeps until no block exceeds its limit (minus a rounding margin)
    Hc = {n: field[n] for n in nodes}
    for it in range(3000):
        worst_ex = 0.0
        for s in lat:
            a, b = s["a"], s["b"]
            lim = max(hmax(length(s)) - 0.9, 0.0)
            dh = Hc[b] - Hc[a]
            ex = abs(dh) - lim
            if ex <= 0.0:
                continue
            worst_ex = max(worst_ex, ex)
            fa = (float(a[0]), float(a[1])) in fixed; fb = (float(b[0]), float(b[1])) in fixed
            sgn = 1.0 if dh > 0 else -1.0
            if fa and fb:
                continue
            if fa:
                Hc[b] -= sgn * ex
            elif fb:
                Hc[a] += sgn * ex
            else:
                Hc[b] -= sgn * ex * 0.5; Hc[a] += sgn * ex * 0.5
        for n in nodes:
            if (float(n[0]), float(n[1])) not in fixed:
                Hc[n] += 0.002 * (field[n] - Hc[n])
        if worst_ex < 1e-3 and it > 50:
            break
    # 2. snap to 2 m steps, then repair the few blocks the rounding broke (move the free pad that rounded the most)
    H = {n: round(Hc[n] / STEP) * STEP for n in nodes}
    for n in nodes:
        if (float(n[0]), float(n[1])) in fixed:
            H[n] = round(field[n] / STEP) * STEP
    moves = 0
    for _ in range(200):
        bad = [s for s in lat if abs(H[s["b"]] - H[s["a"]]) > hmax(length(s)) + 1e-6]
        if not bad:
            break
        s = bad[0]; a, b = s["a"], s["b"]
        hi, lo = (a, b) if H[a] > H[b] else (b, a)
        opts = []
        if (float(hi[0]), float(hi[1])) not in fixed: opts.append((H[hi] - Hc[hi], hi, -STEP))
        if (float(lo[0]), float(lo[1])) not in fixed: opts.append((Hc[lo] - H[lo], lo, STEP))
        if not opts:
            print("CANNOT FIX", s["name"], a, b); break
        _, n, d = max(opts, key=lambda t: t[0])
        H[n] += d; moves += 1
    # report
    worst = 0.0
    classes = collections.Counter()
    blocks = []
    for s in lat:
        a, b = s["a"], s["b"]
        L = length(s)
        dh = H[b] - H[a]
        g = 1.5 * abs(dh) / max(L - 40.0, 1.0)
        worst = max(worst, g)
        sec = section(s)
        std_len = abs(L - 200.0) < 1.0
        classes[(sec, "200" if std_len else "other", abs(dh))] += 1
        blocks.append({"a": list(a), "b": list(b), "name": s["name"], "kind": s["kind"], "section": sec,
                       "length": round(L, 1), "rise": dh, "grade_max": round(g, 4)})
    shift = [abs(H[n] - field[n]) for n in nodes]
    out = {"note": "grading plan: junction pad heights (2 m steps) and block rises; tools/city/pilot/zoning/grading.py",
           "step": STEP, "nodes": [{"u": n[0], "v": n[1], "pad": H[n], "ground": round(field[n], 2)} for n in nodes],
           "blocks": blocks}
    json.dump(out, open(OUT, "w"), indent=1)
    print("moves %d, steepest %.1f %%, pads off the ground: mean %.2f m, max %.2f m" % (moves, worst * 100, np.mean(shift), max(shift)))
    for k in sorted(classes):
        print("  %-9s %-5s rise %4.0f m : %d" % (k[0], k[1], k[2], classes[k]))


if __name__ == "__main__":
    main()
