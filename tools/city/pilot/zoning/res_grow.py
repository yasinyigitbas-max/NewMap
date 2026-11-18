"""Residential growth, pilot area (18 Nov, zone session "grow residential"). Writes, for ONE connected area of the
residential zone, a quadrant piece script per junction corner (tools/city/pilot/pieces/r_q_*.gd, built by rv_lib.gd with a
design from rv_designs.gd) and this zone's own placement table map_dc/coronado/city_kit/review/grow_res_blocks.json
(read by integrate.py grow_rows(), the zone sessions' review/grow_*_blocks.json convention).

THE AREA: the six blocks between J, G, E and C Ave (u -800 .. -200) and 9th, 10th and 11th St (v -200 .. 200), on
Country Club Ridge (junction pads 2 - 12 m). Why there: it is the largest stretch of the residential zone on the zoning
map with plain 200 m residential lattice blocks on every side (no ring, no 250 m pitch, no other zone inside); every
street round it is a residential leg already built (resstd family); it holds the hill the zoning map put there (rises of
0 - 8 m per block, so the sloped variants are tested for real); it lies between the high street (C Ave edge) and the
ocean ring, so the drive along 10th St from the pilot runs straight into it. The two middle blocks (G - E Ave) have
filled blocks west, east and on the other side of 10th St.

Designs are spread so that every block holds all four and no two quadrants that face each other across a street or a
junction carry the same design. Three corner shops (a used bookshop, a cafe, a surf shop) spread over the area.
Run from the repo root: python3 -I tools/city/pilot/zoning/res_grow.py
"""
import itertools, json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../.."))
KIT = os.path.join(ROOT, "map_dc/coronado/city_kit")
PIECES = os.path.join(ROOT, "tools/city/pilot/pieces")

CU = [-800.0, -600.0, -400.0]       # block west edges (u)
CV = [-200.0, 0.0]                  # block north edges (v)
DES = ["V1", "V2", "V3", "V4"]
# corner shops: (junction u, v, sx, sz) -> [model, label, room kind]
SHOPS = {(-400.0, 0.0, 1.0, 1.0): ["commercial/com_shallow_books", "r_shop_books", "books"],
         (-600.0, -200.0, 1.0, 1.0): ["commercial/com_shallow_cafe", "r_shop_cafe", "cafe"],
         (-800.0, 200.0, 1.0, -1.0): ["commercial/com_surf_shop", "r_shop_surf", "sport"]}
SHOPS[(250.0, -200.0, 1.0, 1.0)] = ["commercial/com_realty", "r_shop_wash", "cleaners"]      # Glorietta Heights
SHOPS[(-200.0, -1000.0, 1.0, 1.0)] = ["commercial/com_bakery", "r_shop_market", "corner_shop"]  # Crown Hill
SHOP_DES = {"r_shop_books": "V1", "r_shop_cafe": "V4", "r_shop_surf": "V3", "r_shop_wash": "V1", "r_shop_market": "V2"}


def pads():
    gr = json.load(open(os.path.join(KIT, "zoning/grading.json")))
    return {(round(n["u"], 1), round(n["v"], 1)): float(n["pad"]) for n in gr["nodes"]}


def quadrants():
    """every growable residential quadrant of the zone (res_zone.py); the pilot area's 24 come first"""
    import res_zone
    qs, _ = res_zone.quadrants()
    out = [dict(q) for q in qs]
    return out


def neighbours(qs):
    """pairs of quadrants that face each other across a street (same junction, mirrored in one axis) or a junction"""
    pairs = []
    for a, b in itertools.combinations(range(len(qs)), 2):
        A, B = qs[a], qs[b]
        if A["j"] == B["j"]:
            pairs.append((a, b))
    return pairs


def assign(qs):
    pairs = neighbours(qs)
    # designs already built (the pilot area, 18 Nov) stay as they are
    try:
        old = {r["piece"]: r["design"] for r in json.load(open(os.path.join(KIT, "review/grow_res_blocks.json")))["rows"] if r.get("design")}
    except Exception:
        old = {}
    cells = sorted({q["cell"] for q in qs})
    fixed = {}
    for i, q in enumerate(qs):
        k = (q["j"][0], q["j"][1], q["sx"], q["sz"])
        if k in SHOPS:
            fixed[i] = SHOP_DES[SHOPS[k][1]]
        nm = name_of(q)
        if nm in old:
            fixed[i] = old[nm]
    # backtracking: every cell holds all four designs, faced quadrants differ
    order = sorted(range(len(qs)), key=lambda i: (qs[i]["cell"], qs[i]["sx"], qs[i]["sz"]))
    res = {}

    def ok(i, d):
        if i in fixed and fixed[i] != d:
            return False
        for j, dj in res.items():
            if qs[j]["cell"] == qs[i]["cell"] and dj == d:
                return False
            if ((i, j) in pairs or (j, i) in pairs) and dj == d:
                return False
        return True

    def go(k):
        if k == len(order):
            return True
        i = order[k]
        start = (k * 3) % 4
        for t in range(4):
            d = DES[(start + t) % 4]
            if ok(i, d):
                res[i] = d
                if go(k + 1):
                    return True
                del res[i]
        return False

    assert go(0), "no assignment"
    return [res[i] for i in range(len(qs))]


def name_of(q):
    ju, jv = q["j"]; sx, sz = q["sx"], q["sz"]
    return "r_q_%s_%s_%s" % (tag(ju), tag(jv), ("s" if sz > 0 else "n") + ("e" if sx > 0 else "w"))


def tag(x):
    return ("m%d" % -x if x < 0 else "%d" % x)


def main():
    P = pads()
    qs = quadrants()
    des = assign(qs)
    rows = []
    for q, d in zip(qs, des):
        ju, jv = q["j"]; sx, sz = q["sx"], q["sz"]
        corner = ("s" if sz > 0 else "n") + ("e" if sx > 0 else "w")
        name = "r_q_%s_%s_%s" % (tag(ju), tag(jv), corner)
        Lu, Lv = q["Lu"], q["Lv"]
        site = {"j": [ju, jv], "sx": sx, "sz": sz, "p0": P[(ju, jv)], "pu": P[(ju + Lu * sx, jv)],
                "pv": P[(ju, jv + Lv * sz)], "puv": P[(ju + Lu * sx, jv + Lv * sz)], "Lu": Lu, "Lv": Lv,
                "pu_line": q["pu_line"], "pv_line": q["pv_line"], "apron_u": q["apron_u"], "apron_v": q["apron_v"]}
        shop = SHOPS.get((ju, jv, sx, sz))
        if shop:
            site["shop"] = shop
        rise_u = site["pu"] - site["p0"]; rise_v = site["pv"] - site["p0"]
        twist = site["puv"] - site["pu"] - site["pv"] + site["p0"]
        doc = ("## Piece %s (residential growth, 18-19 Nov): the %s quadrant of junction (%g, %g), design %s.\n"
               "## Hill: pad %.1f m; the block rises %+.1f m along u, %+.1f m along v (twist %+.1f) - the quadrant follows it.\n"
               "## Built by rv_lib.gd (every rule and its reason is there). Run once; never when locked.\n") % (
            name, corner.upper(), ju, jv, d, site["p0"], rise_u, rise_v, twist)
        if shop:
            doc += "## Corner shop: %s (%s), its room is in interiors/assignment_res.json.\n" % (shop[1], shop[2])
        src = ("extends SceneTree\n" + doc +
               "const RV := preload(\"res://tools/city/pilot/pieces/rv_lib.gd\")\n"
               "const D := preload(\"res://tools/city/pilot/pieces/rv_designs.gd\")\n"
               "const SITE := %s\n"
               "func _init() -> void: _run.call_deferred()\n"
               "func _run() -> void:\n"
               "\tRV.new().build(\"%s\", SITE, D.get_design(\"%s\"))\n"
               "\tquit()\n") % (json.dumps(site), name, d)
        open(os.path.join(PIECES, name + ".gd"), "w", newline="\n").write(src)
        rows.append({"piece": name, "pos": [ju, site["p0"], jv], "yaw": 0.0, "design": d, "cell": list(q["cell"]),
                     "rise_u": rise_u, "rise_v": rise_v, "twist": twist, "shop": shop[1] if shop else ""})
    # the area's overhead lines (w_rv.gd): built in the grid frame from the quadrants' poles, row at the origin
    rows.append({"piece": "w_rv", "pos": [0.0, 0.0, 0.0], "yaw": 0.0, "design": "", "cell": [], "rise_u": 0, "rise_v": 0, "twist": 0, "shop": ""})
    tab = {"note": "Residential growth (res_grow.py): one quadrant piece per junction corner of the residential zone that "
                   "the variants can carry (res_zone.py), pos = the junction centre at its pad, yaw 0 (each piece is built "
                   "for its own corner). The pilot area (u -800..-200, v -200..200) came first (18 Nov); the rest of the "
                   "zone 19 Nov (Yasin: 'roll out to your whole zone').",
           "pilot_area": {"u": [-800, -200], "v": [-200, 200], "blocks": 6, "quadrants": 24}, "quadrants": len(rows), "grow": True, "rows": rows}
    json.dump(tab, open(os.path.join(KIT, "review/grow_res_blocks.json"), "w"), indent=1)
    for r in rows[:-1]:
        print(r["piece"], r["design"], "rise u %+.0f v %+.0f twist %+.0f" % (r["rise_u"], r["rise_v"], r["twist"]), r["shop"])


if __name__ == "__main__":
    main()
