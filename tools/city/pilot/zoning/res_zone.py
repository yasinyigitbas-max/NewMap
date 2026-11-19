"""Residential growth, the WHOLE zone (19 Nov, Yasin: "roll out to your whole zone"): every quadrant of a lattice junction
that lies in the residential zone of the locked zoning map and can carry a residential variant:
  - its block is a lattice block (four lattice junctions, 200 m along v, 200 or 250 m along u), no ring junction;
  - both legs at its junction are measured as built (leg_measure.gd): the quadrant's lots start at each street's own
    property line (9.2 residential / standard, 14.3 the arterials, 16 Amber's divided stretch), and an alley meets a
    street only where it has an alley mouth (else bollards close it at the property line);
  - its centre lies in the residential zone and in no other zone (zones.py order: the other zones win);
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

def measured_legs():
    """the legs as built (leg_measure.gd -> zoning/legs_measured.json): (u, v, dir) -> leg row"""
    out = {}
    pth = os.path.join(KIT, "zoning/legs_measured.json")
    if not os.path.exists(pth):
        return out
    for l in json.load(open(pth))["legs"]:
        k = (l["u"], l["v"], round(l["dir"][0]), round(l["dir"][1]))
        if k not in out and max(l["prop_left"], l["prop_right"]) > 1.0:
            out[k] = l
    return out


def leg_side(leg, off):
    """property line and alley mouth of a measured leg on the side where the quadrant lies (off = unit offset)"""
    dx, dz = leg["dir"]
    right = (dz * off[0] - dx * off[1]) > 0.0       # the piece's local +x in the grid frame is (dz, -dx)
    return (leg["prop_right"], leg["apron_right"]) if right else (leg["prop_left"], leg["apron_left"])


PIECES = os.path.normpath(os.path.join(HERE, "../pieces"))

def leg_profiles():
    """the height profile each street block was BUILT with (the leg scripts' SPEC "prof": [[z0, z1, H], ...] from the
    leg's own junction), as seen from the block's end a; blocks served by the shared s_res_* legs keep the standard
    [20, L - 20, rise]"""
    import re
    out = {}
    for f in os.listdir(PIECES):
        m = re.match(r"s_[a-z]+_(b\d+)_([ab])\.gd$", f)
        if not m:
            continue
        src = open(os.path.join(PIECES, f)).read()
        mm = re.search(r'"prof": (\[\[.*?\]\])', src)
        if not mm:
            continue
        out.setdefault(m.group(1), {})[m.group(2)] = json.loads(mm.group(1))
    return out


def _ss(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3.0 - 2.0 * x)


def _eval(prof, z):
    return sum(q[2] * _ss((z - q[0]) / (q[1] - q[0])) for q in prof)


def edge_samples(block, from_a, LP):
    """the street's height along a block, from one end, every 1 m (relative to that end's pad): each half as its own
    leg piece builds it (the leg from end a carries t <= L/2, the leg from end b the rest), so the quadrant's ground meets
    the walk exactly; a block whose legs are the shared s_res_* pieces has the standard profile on both halves"""
    L = block["length"]; rise = block["rise_a_to_b"]
    p = LP.get(block["id"], {})
    std = [[20.0, L - 20.0, rise]]
    pa = p.get("a"); pb = p.get("b")
    if pa is None and pb is None: pa = std
    if pa is None: pa = [[L - q[1], L - q[0], -q[2]] for q in pb]
    if pb is None: pb = [[L - q[1], L - q[0], -q[2]] for q in pa]
    n = int(round(L))
    ha = []
    for i in range(n + 1):
        t = L * i / n
        ha.append(_eval(pa, t) if t <= L * 0.5 else rise + _eval(pb, L - t))
    if from_a:
        return [round(h, 4) for h in ha]
    return [round(h - rise, 4) for h in reversed(ha)]


def quadrants():
    d = json.load(open(os.path.join(KIT, "review/sites.json")))
    ML = measured_legs()
    LP = leg_profiles()
    blocks = {}
    for b in d["blocks"]:
        blocks[(tuple(b["a"]), tuple(b["b"]))] = (b, True); blocks[(tuple(b["b"]), tuple(b["a"]))] = (b, False)
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
                pass      # Amber's divided stretch and the arterials: their measured property lines (16 / 14.3) are used
                lu_leg = ML.get((u, v, int(sx), 0)); lv_leg = ML.get((u, v, 0, int(sz)))
                if not why and (lu_leg is None or lv_leg is None):
                    why = "leg not measured (ring piece / no ground)"
                if not why:
                    pv_line, apron_v = leg_side(lu_leg, (0.0, sz))        # the street along u: its line is a v
                    pu_line, apron_u = leg_side(lv_leg, (sx, 0.0))        # the street along v: its line is a u
                    if not (8.5 <= pu_line <= 16.5 and 8.5 <= pv_line <= 16.5):
                        why = "property line %.1f / %.1f" % (pu_line, pv_line)
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
                # the four streets round the block, each with its built profile from the quadrant's side
                prof = {}
                for key, a_, b_ in (("A", (u, v), (u2, v)), ("C", (u, v2), (u2, v2)), ("B", (u, v), (u, v2)), ("D", (u2, v), (u2, v2))):
                    bk = blocks.get((a_, b_))
                    prof[key] = edge_samples(bk[0], bk[1], LP) if bk else None
                out.append({"j": (u, v), "sx": sx, "sz": sz, "Lu": Lu, "Lv": Lv, "cell": (min(u, u2), min(v, v2)), "prof": prof,
                            "pu_line": pu_line, "pv_line": pv_line, "apron_u": apron_u, "apron_v": apron_v})
    return out, skipped

if __name__ == "__main__":
    q, sk = quadrants()
    print("residential quadrants that can be grown:", len(q), " blocks touched:", len({x["cell"] for x in q}))
    print("Lu 250:", sum(1 for x in q if x["Lu"] == 250.0))
    print("residential-zone quadrants skipped:", sk)
    for x in sorted(q, key=lambda x: (x["cell"], x["j"])): print(x["cell"], x["j"], x["sx"], x["sz"], x["Lu"])
