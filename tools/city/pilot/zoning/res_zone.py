"""Residential growth, the WHOLE zone (19 Nov, Yasin: "roll out to your whole zone"): every quadrant of a lattice junction
that lies in the residential zone of the locked zoning map and can carry a residential variant:
  - its block is a lattice block (four lattice junctions, 200 m along v, 200 or 250 m along u), no ring junction;
  - both legs at its junction are residential-section streets (res / std: kerb 5.7, property line 9.2, alley mouth 54-60);
  - its centre lies in the residential zone and in no other zone (zones.py order: the other zones win);
  - neither leg is Amber Ave (the amber family builds it as the divided avenue even where the section is "res": its
    road runs past the 9.2 m property line);
  - it is not a locked sample's quadrant, and it is clear of the pilot's hill rows (x 0-150 along 10th St).
Read-only; prints the list and a summary. Used by res_grow.py.
"""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
KIT = os.path.normpath(os.path.join(HERE, "../../../../map_dc/coronado/city_kit"))
from zones import Z
from matplotlib.path import Path
OK_SECTIONS = {"res", "std"}

def zone_of(u, v):
    for k in Z:
        if k == "res":
            continue
        for poly in Z[k][2]:
            if Path(poly).contains_point((u, v)):
                return k
    for poly in Z["res"][2]:
        if Path(poly).contains_point((u, v)):
            return "res"
    return None

def quadrants():
    d = json.load(open(os.path.join(KIT, "review/sites.json")))
    nodes = {(n["u"], n["v"]): n for n in d["nodes"]}
    us = sorted({n["u"] for n in d["nodes"] if n["kind"] == "lattice"})
    out = []; skipped = {}
    for (u, v), n in nodes.items():
        if n["kind"] != "lattice":
            continue
        for sx in (-1.0, 1.0):
            for sz in (-1.0, 1.0):
                why = None
                # the neighbouring lattice junctions of the block
                cand = [x for x in us if (x - u) * sx > 0]
                if not cand:
                    continue
                u2 = min(cand, key=lambda x: abs(x - u)); v2 = v + 200.0 * sz
                Lu = abs(u2 - u); Lv = 200.0
                corners = [(u2, v), (u, v2), (u2, v2)]
                if any(c not in nodes or nodes[c]["kind"] != "lattice" for c in corners):
                    why = "ring / no lattice block"
                legs = {tuple(l["dir"]): l["section"] for l in n["legs"]}
                owners = {b["id"]: b["owner"] for b in d["blocks"]}
                leg_own = {tuple(l["dir"]): owners.get(l["block"]) for l in n["legs"]}
                if not why and "amber" in (leg_own.get((sx, 0.0)), leg_own.get((0.0, sz))):
                    why = "Amber Ave leg (divided avenue, wider than the residential section)"
                if not why and (legs.get((sx, 0.0)) not in OK_SECTIONS or legs.get((0.0, sz)) not in OK_SECTIONS):
                    why = "leg section %s / %s" % (legs.get((sx, 0.0)), legs.get((0.0, sz)))
                cu, cv = u + sx * Lu / 4, v + sz * Lv / 4
                z = zone_of(cu, cv)
                if not why and z != "res":
                    why = "zone %s" % z
                if not why and n.get("owner") == "sample":
                    why = "sample junction"
                if not why and u == 250.0 and v == 0.0 and sx < 0:
                    why = "pilot hill rows"
                if not why and Lu not in (200.0, 250.0):
                    why = "block %g m" % Lu
                if why:
                    if z == "res": skipped[why] = skipped.get(why, 0) + 1
                    continue
                out.append({"j": (u, v), "sx": sx, "sz": sz, "Lu": Lu, "Lv": Lv, "cell": (min(u, u2), min(v, v2))})
    return out, skipped

if __name__ == "__main__":
    q, sk = quadrants()
    print("residential quadrants that can be grown:", len(q), " blocks touched:", len({x["cell"] for x in q}))
    print("Lu 250:", sum(1 for x in q if x["Lu"] == 250.0))
    print("residential-zone quadrants skipped:", sk)
    for x in sorted(q, key=lambda x: (x["cell"], x["j"])): print(x["cell"], x["j"], x["sx"], x["sz"], x["Lu"])
