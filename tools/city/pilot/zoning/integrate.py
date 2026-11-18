"""Integration plan (17 Nov): assemble the WHOLE city as one layout in the grid frame, from what is locked and approved.

  1. The locked samples (city_layout.json rows) move from their preview spots to their junctions on the locked street
     skeleton (streets.py SNAP), at the grading plan's pad height (grading.json). Rows keep their offsets from the
     sample's origin; a sample with a yaw (the waterfront, 90) turns about its origin. Wire pieces (w_*) and the life
     overlays (d_*) are built in the PREVIEW frame at pos [0,0,0]: they get the same move as their sample.
  2. The road pieces come from the families' integration tables (map_dc/coronado/city_kit/review/*_sites.json, written
     by the road kit fleet). Accepted entry shapes (one row each): {"piece", "yaw", and either "pos": [x, y, z] in the
     grid frame, or "u", "v" (+ "y" / "pad")}; a table may be a list, or {"rows": [...]} / {"sites": [...]} / {"instances": [...]},
     an entry may also carry "pieces": [ {piece, yaw, pos|u,v,y}, ... ] for a site served by several pieces.
  3. Coverage: every junction and block of the skeleton (review/sites.json) must be served by a sample or a family
     row; the gaps are listed.

Output: map_dc/coronado/city_kit/city_grid_layout.json ({"note", "frame", "instances", "coverage"}). The grid frame is
x = u (along 10th St toward ESE), z = v (along Amber toward SSW), y = metres above the game's datum (the grading
plan's heights). The game placement (rotate by Amber's 26 deg bearing, offset to the world) and the terrain under it
are the next integration steps. Preview-only rows (zz_*, the review streets at x >= 800) are never copied.
Check it in the preview: CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/city_grid_layout.json
"""
import glob, json, math, os, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.normpath(os.path.join(HERE, "../../../../map_dc/coronado/city_kit"))
sys.path.insert(0, HERE)

# preview origin of each locked sample in city_layout.json -> skeleton sample key (streets.py SNAP)
PREVIEW = {(0.0, 0.0): "P", (0.0, 400.0): "C", (0.0, -400.0): "I", (-400.0, 0.0): "M", (400.0, 0.0): "A",
           (400.0, 400.0): "V", (400.0, 600.0): "V", (400.0, -400.0): "G", (-400.0, 400.0): "W"}
# pieces built in the preview frame at pos [0,0,0], and the sample they belong to
FRAME_PIECES = {"w_power": "P", "d_pilot": "P", "w_ind": "I", "w_strip": "M", "w_apt": "A", "w_civ": "V",
                "w_grt": "G", "w_wf": "W"}
SAMPLE_ORIGIN = {"P": (0.0, 0.0), "C": (0.0, 400.0), "I": (0.0, -400.0), "M": (-400.0, 0.0), "A": (400.0, 0.0),
                 "V": (400.0, 400.0), "G": (400.0, -400.0), "W": (-400.0, 400.0)}


def rot(x, z, yaw_deg):
    # Godot yaw about +Y: x' = x cos + z sin, z' = -x sin + z cos
    a = math.radians(yaw_deg)
    return x * math.cos(a) + z * math.sin(a), -x * math.sin(a) + z * math.cos(a)


def load_skeleton():
    import streets as ST
    gr = json.load(open(os.path.join(KIT, "zoning/grading.json")))
    pad = {(round(n["u"], 1), round(n["v"], 1)): n["pad"] for n in gr["nodes"]}
    return ST, pad


def samples(ST, pad):
    lay = json.load(open(os.path.join(KIT, "city_layout.json")))
    out = []
    for r in lay["instances"]:
        p = r["pos"]; piece = r["piece"]
        if piece.startswith("zz_") or float(p[0]) >= 800.0:
            continue      # preview-only ground / the group-1 review streets
        if piece in FRAME_PIECES:
            key = FRAME_PIECES[piece]
            ox, oz = SAMPLE_ORIGIN[key]
            local = (float(p[0]) - ox, float(p[2]) - oz)
        elif piece == "d_cc":
            key = "C"; local = (float(p[0]) - 0.0, float(p[2]) - 400.0)
        else:
            key = PREVIEW.get((float(p[0]), float(p[2])))
            if key is None:
                print("UNPLACED row", r); continue
            ox, oz = SAMPLE_ORIGIN[key]
            local = (float(p[0]) - ox, float(p[2]) - oz)
        (u, v), yaw_s, _rect, _legs = ST.SNAP[key]
        y = 1.35 if key == "W" else pad[(round(float(u), 1), round(float(v), 1))]     # waterfront: walk 1.5 m above the sea
        lx, lz = rot(local[0], local[1], yaw_s)
        out.append({"piece": piece, "pos": [round(u + lx, 3), round(float(p[1]) + y, 3), round(v + lz, 3)],
                    "yaw": (float(r.get("yaw", 0)) + yaw_s + 180.0) % 360.0 - 180.0, "from": "sample " + key})
    return out


def family_rows():
    """every object in a family table that names a piece and a place becomes a layout row. Accepted place fields:
    "pos" [x, y, z]; or "at" / "site" [u, v] (or "u", "v") with "y" / "pad" (inherited from the enclosing site entry);
    "yaw" defaults to 0. Each piece is placed once per distinct (piece, pos, yaw)."""
    rows = []; seen = set()

    def place(o, ctx):
        pos = None
        if isinstance(o.get("pos"), list) and len(o["pos"]) == 3:
            pos = [float(c) for c in o["pos"]]
        else:
            uv = o.get("at") if isinstance(o.get("at"), list) else (o.get("site") if isinstance(o.get("site"), list) else None)
            if uv is None and "u" in o and "v" in o:
                uv = [o["u"], o["v"]]
            if uv is None:
                uv = ctx.get("uv")
            y = o.get("y", o.get("pad", ctx.get("y")))
            if uv is not None and y is not None:
                pos = [float(uv[0]), float(y), float(uv[1])]
        return pos

    def walk(o, fam, ctx):
        if isinstance(o, dict):
            c = dict(ctx)
            if isinstance(o.get("site"), list): c["uv"] = o["site"]
            elif isinstance(o.get("at"), list): c["uv"] = o["at"]
            if "pad" in o: c["y"] = o["pad"]
            if isinstance(o.get("site"), str) or "id" in o: c["sid"] = o.get("id", o.get("site"))
            if isinstance(o.get("piece"), str) and (o["piece"].startswith(("j_", "s_")) or o.get("block") is True):   # block: zone growth tables (18 Nov)
                pos = place(o, c)
                if pos is not None:
                    key = (o["piece"], round(pos[0], 2), round(pos[1], 2), round(pos[2], 2), round(float(o.get("yaw", 0.0)), 1))
                    if key not in seen:
                        seen.add(key)
                        rows.append({"piece": o["piece"], "pos": pos, "yaw": float(o.get("yaw", 0.0)), "from": fam, "site": c.get("sid")})
            for k, v in o.items():
                if k in ("pieces",) and isinstance(v, dict):
                    continue          # a catalogue (piece -> description), not placements
                walk(v, fam, c)
        elif isinstance(o, list):
            for v in o:
                walk(v, fam, ctx)

    for f in sorted(glob.glob(os.path.join(KIT, "review/*_sites.json"))):
        if os.path.basename(f) in ("sites.json", "ring_sites.json"):
            continue      # ring_sites.json = the ring core's examples, superseded by ring_nw / ring_se (which list the core pieces they keep)
        fam = os.path.basename(f)[:-len("_sites.json")]
        walk(json.load(open(f)), fam, {})
    return rows


def coverage(rows):
    sites = json.load(open(os.path.join(KIT, "review/sites.json")))
    at = collections.defaultdict(list)
    for r in rows:
        at[(round(r["pos"][0]), round(r["pos"][2]))].append(r)
    gaps = {"nodes": [], "blocks": []}
    for n in sites["nodes"]:
        if n["owner"] == "sample":
            continue
        if not at.get((round(n["u"]), round(n["v"]))):
            gaps["nodes"].append({"u": n["u"], "v": n["v"], "owner": n["owner"], "legs": [l["section"] for l in n["legs"]]})
    served_sites = {str(r.get("site")) for r in rows if r.get("site") is not None}
    for b in sites["blocks"]:
        if b["id"] in served_sites:
            continue
        # a block is served when a row sits at one of its ends with a yaw pointing along it (a leg), or it is named
        ok = False
        for end, other in ((b["a"], b["b"]), (b["b"], b["a"])):
            for r in at.get((round(end[0]), round(end[1])), []):
                if r["piece"].startswith("j_"):
                    continue
                dx, dz = other[0] - end[0], other[1] - end[1]
                if b["kind"] != "lattice":
                    ok = True; break
                fx, fz = math.sin(math.radians(r["yaw"])), math.cos(math.radians(r["yaw"]))
                if fx * dx + fz * dz > 0.7 * math.hypot(dx, dz):
                    ok = True; break
            if ok:
                break
        if not ok:
            gaps["blocks"].append({"id": b["id"], "name": b["name"], "owner": b["owner"], "section": b["section"],
                                   "a": b["a"], "b": b["b"], "rise": b["rise_a_to_b"]})
    return gaps


def main():
    ST, pad = load_skeleton()
    srows = samples(ST, pad)
    frows = family_rows()
    rows = srows + frows
    # whole-city pieces built in the grid frame itself (17 Nov): the shore foam along every beach (x_shore_foam.gd)
    for piece in ("x_shore_foam",):
        if os.path.exists(os.path.join(KIT, "pieces", piece + ".scn")):
            rows.append({"piece": piece, "pos": [0.0, 0.0, 0.0], "yaw": 0.0, "from": "grid frame"})
    gaps = coverage(rows)
    out = {"note": __doc__.strip().split("\n")[0], "frame": "grid: x = u (ESE along 10th), z = v (SSW along Amber), y = datum m",
           "instances": rows, "coverage": {"sample_rows": len(srows), "family_rows": len(frows),
                                           "gap_nodes": len(gaps["nodes"]), "gap_blocks": len(gaps["blocks"]), "gaps": gaps}}
    json.dump(out, open(os.path.join(KIT, "city_grid_layout.json"), "w"), indent=1)
    print("sample rows %d, family rows %d" % (len(srows), len(frows)))
    print("gaps: %d junctions, %d blocks" % (len(gaps["nodes"]), len(gaps["blocks"])))
    for k, c in collections.Counter(g["owner"] for g in gaps["nodes"]).items():
        print("  junction gaps owner %-7s %d" % (k, c))
    for k, c in collections.Counter(g["owner"] for g in gaps["blocks"]).items():
        print("  block gaps    owner %-7s %d" % (k, c))


if __name__ == "__main__":
    main()
