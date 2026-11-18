"""Road kit site inventory (17 Nov, fleet for groups 2-5). Reads the locked street skeleton (streets.py), the locked
grading plan (grading.json) and the zones, and writes map_dc/coronado/city_kit/review/sites.json:

  nodes:  every junction (lattice crossing or where a street meets the ring): grid u, v, pad height, kind, its legs
          (direction as a grid vector, the street's section, the block it belongs to), the locked sample on it (if any)
          and the FAMILY that owns the junction piece
  blocks: every street between two junctions: ends, section, street name, length, rise (grading), owner family

Owner families (one agent each):
  ring    anything touching the ring boulevard: ring pieces, ring T-junctions, the stubs from the last lattice junction
  amber   Amber Ave (u = 0) junctions and blocks (high street, centre, the avenue through the residential zones)
  art     3rd / 4th St (two-way arterials on the strip cross-section) and truck / strip streets
  resstd  residential and standard (s_apt cross-section) streets and their junctions
  sample  a locked sample's own junction (its pieces exist)

Sections (from the zones, as in the approved picture): res, std, hs, cc, couplet (3rd/4th), ind, strip, ring, bridge.
Grid frame: u along 10th St toward ESE, v along Amber toward SSW, origin Amber x 10th (grid.py). Pieces are authored in
a local frame where legs run along +z; place them with yaw so +z follows the leg.
"""
import json, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "../../../../map_dc/coronado/city_kit/review/sites.json")
KIT = os.path.join(HERE, "../../../../map_dc/coronado/city_kit")


def main():
    sys.argv = ["x", "/dev/null"]
    import matplotlib
    matplotlib.use("Agg")
    src = open(os.path.join(HERE, "render_streets.py")).read().split("used = set()")[0]
    src = src.replace('OUT = os.path.join', 'OUT = "/dev/null" or os.path.join')
    ns = {}
    exec(src, ns)
    segs, nodes, section, ST = ns["segs"], ns["nodes"], ns["section"], ns["ST"]
    gr = json.load(open(os.path.join(HERE, "../../../../map_dc/coronado/city_kit/zoning/grading.json")))
    pad = {(round(n["u"], 1), round(n["v"], 1)): n["pad"] for n in gr["nodes"]}
    rise = {}
    for b in gr["blocks"]:
        a = (round(b["a"][0], 1), round(b["a"][1], 1)); c = (round(b["b"][0], 1), round(b["b"][1], 1))
        rise[(a, c)] = b["rise"]; rise[(c, a)] = -b["rise"]
    key = lambda n: (round(float(n[0]), 1), round(float(n[1]), 1))
    sample_at = {key(ST.SNAP[k][0]): k for k in ST.SNAP}

    def sec_of(s):
        if s["kind"] == "ring":
            return "ring"
        if s["kind"] == "bridge":
            return "bridge"
        if s["name"] in ("3rd St", "4th St"):
            return "couplet"
        return section(s)

    def block_owner(s, sec):
        if s["kind"] in ("ring", "bridge") or nodes.get(s["a"]) in ("ring", "bridge", "bridge end") or nodes.get(s["b"]) in ("ring", "bridge", "bridge end"):
            return "ring"
        if s["name"] == "Amber Ave":
            return "amber"
        if sec in ("couplet", "ind", "strip"):
            return "art"
        return "resstd"

    blocks = []
    legs = {key(n): [] for n in nodes}
    for i, s in enumerate(segs):
        sec = sec_of(s)
        p = np.array(s["pts"], float)
        L = float(np.sum(np.hypot(*np.diff(p, axis=0).T)))
        a, b = key(s["a"]), key(s["b"])
        bid = "b%03d" % i
        blocks.append({"id": bid, "a": list(a), "b": list(b), "kind": s["kind"], "name": s["name"], "section": sec,
                       "length": round(L, 1), "rise_a_to_b": rise.get((a, b), 0.0), "owner": block_owner(s, sec),
                       "pts": [[round(x, 2), round(y, 2)] for x, y in s["pts"]] if s["kind"] != "lattice" else None})
        for end, other_pts in ((a, p[1]), (b, p[-2])):
            d = other_pts - np.array(end)
            d = d / (np.linalg.norm(d) or 1.0)
            legs[end].append({"dir": [round(float(d[0]), 4), round(float(d[1]), 4)], "section": sec, "name": s["name"], "block": bid})
    out_nodes = []
    for n, t in nodes.items():
        k = key(n)
        lg = legs[k]
        secs = {l["section"] for l in lg}
        names = {l["name"] for l in lg}
        if k in sample_at:
            owner = "sample"
        elif t in ("ring", "bridge", "bridge end") or "ring" in secs or "bridge" in secs:
            owner = "ring"
        elif "Amber Ave" in names:
            owner = "amber"
        elif secs & {"couplet", "ind", "strip"}:
            owner = "art"
        else:
            owner = "resstd"
        out_nodes.append({"u": k[0], "v": k[1], "kind": t, "pad": pad.get(k), "legs": lg, "n_legs": len(lg),
                          "sample": sample_at.get(k), "owner": owner})
    hero_overrides(out_nodes, blocks)
    json.dump({"note": __doc__.strip().split("\n")[0], "nodes": out_nodes, "blocks": blocks}, open(OUT, "w"), indent=1)
    import collections
    print("nodes by owner", dict(collections.Counter(n["owner"] for n in out_nodes)))
    print("blocks by owner", dict(collections.Counter(b["owner"] for b in blocks)))
    print("missing pads", sum(1 for n in out_nodes if n["pad"] is None))
    jt = collections.Counter((n["owner"], n["n_legs"], tuple(sorted(l["section"] for l in n["legs"]))) for n in out_nodes)
    for k2, c in sorted(jt.items()):
        print("  %-7s %d legs %-40s %d" % (k2[0], k2[1], ",".join(k2[2]), c))


def hero_overrides(nodes, blocks):
    """Decisions taken after the skeleton (kept here so regenerating never drops them):
      - the waterfront sample (570, 200) sits at 1.35 m (its walk 1.5 m above the sea), not its grading pad
      - bridge option A (Yasin 17 Nov): no bridge node on the ring at (660, -1100) (the ring runs straight through);
        the approach (zoning/hero_geom.json "approach") meets the ring at 4th St (660, -1200) as its east leg and the
        one-way off-ramp ("ramp") meets 3rd St (660, -1400) as its east leg; the deck end (1180, -905) is 6.9 m up"""
    import math
    N = {(n["u"], n["v"]): n for n in nodes}
    wn = N.get((570.0, 200.0))
    if wn is not None:
        wn["pad"] = 1.35; wn["pad_note"] = "waterfront: its walk 1.5 m above the game's sea (y 0); grading's 2 m step overridden (17 Nov)"
    hg = json.load(open(os.path.join(KIT, "zoning/hero_geom.json")))
    old = N.get((660.0, -1100.0))
    if old is not None:
        old["kind"] = "ring"
        old["legs"] = [l for l in old["legs"] if l["section"] != "bridge"]; old["n_legs"] = len(old["legs"])
    nodes[:] = [n for n in nodes if n["kind"] != "bridge end"]
    blocks[:] = [b for b in blocks if b["kind"] != "bridge"]
    appr = [list(map(float, q)) for q in hg["approach"]][::-1]       # ring -> deck
    ramp = [list(map(float, q)) for q in hg["ramp"]]                  # diverge -> ring
    def leg(p0, p1, name, bid):
        d = (p1[0] - p0[0], p1[1] - p0[1]); L = math.hypot(*d)
        return {"dir": [round(d[0] / L, 4), round(d[1] / L, 4)], "section": "bridge", "name": name, "block": bid}
    N[(660.0, -1200.0)]["legs"].append(leg(appr[0], appr[3], "bridge approach", "b160"))
    N[(660.0, -1400.0)]["legs"].append(leg(ramp[-1], ramp[-4], "bridge off-ramp", "b164"))
    for k in ((660.0, -1200.0), (660.0, -1400.0)):
        N[k]["n_legs"] = len(N[k]["legs"])
    end = {"u": 1180.0, "v": -905.0, "kind": "bridge end", "pad": 6.9, "legs": [leg(appr[-1], appr[-4], "bridge approach", "b160")],
           "n_legs": 1, "sample": None, "owner": "ring"}
    nodes.append(end)
    def length(pts):
        return sum(math.hypot(pts[i + 1][0] - pts[i][0], pts[i + 1][1] - pts[i][1]) for i in range(len(pts) - 1))
    blocks.append({"id": "b160", "a": [660.0, -1200.0], "b": [1180.0, -905.0], "kind": "bridge", "name": "bridge approach",
                   "section": "bridge", "length": round(length(appr), 1), "rise_a_to_b": round(6.9 - N[(660.0, -1200.0)]["pad"], 2),
                   "owner": "ring", "pts": [[round(a, 2), round(b, 2)] for a, b in appr]})
    blocks.append({"id": "b164", "a": [round(ramp[0][0], 2), round(ramp[0][1], 2)], "b": [660.0, -1400.0], "kind": "bridge",
                   "name": "bridge off-ramp", "section": "bridge", "length": round(length(ramp), 1), "rise_a_to_b": None,
                   "owner": "ring", "pts": [[round(a, 2), round(b, 2)] for a, b in ramp]})
    pad = {(n["u"], n["v"]): n["pad"] for n in nodes}
    for b in blocks:
        ka = (float(b["a"][0]), float(b["a"][1])); kb = (float(b["b"][0]), float(b["b"][1]))
        if (wn is not None) and ((570.0, 200.0) in (ka, kb)) and ka in pad and kb in pad:
            b["rise_a_to_b"] = round(pad[kb] - pad[ka], 2)


if __name__ == "__main__":
    main()
