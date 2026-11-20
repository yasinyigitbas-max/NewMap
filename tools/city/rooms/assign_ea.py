"""ea fill (claude/fill-high-street, 20 Nov): which business is behind which shop door of the ea pieces (n_ea_*, the
east shore north of v -1100). A hand list, one line per walk-in place, with the reason; the bay split comes from the
building's contract (room_contracts.json, the same rule as every other shop of the map: assign_all.bays). Writes
interiors/assignment_ea.json in assignment_all.json's format, for tools/city/rooms/room_gen_hp.gd
(--assign=assignment_ea.json --report=rooms_ea_report.json). The shared assignment files are not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_ea.py
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from assign_all import bays

# piece, label, model, local pos, yaw, door index, kind, name, sign style, pad (the piece's layout row height), why
SHOPS = [
    ("n_ea_cape", "rent", "commercial/com_surf_shop", (548.0, 2.0861, -1630.0), 180.0, 0, "sport", "North Beach Rentals", "", 0.0,
     "kayaks, paddle boards, wetsuits and beach bikes to hire at the first beach access by the u 500 junction (its kayak racks on the sand)"),
    ("n_ea_cape", "cafe", "commercial/com_cafe_seaside", (578.0, 1.9691, -1630.0), 180.0, 0, "cafe", "North Beach Cafe", "", 0.0,
     "coffee, iced tea and sandwiches on the forecourt for the beach and for the hospital's staff on their breaks across the ring"),
    ("n_ea_shore", "scoops", "commercial/com_surf_shop", (970.5, 3.7409, -1170.0), -90.0, 0, "ice_cream", "Bridge Point Scoops", "", 0.0,
     "ice cream on the promenade where the beach is busiest, between the crest lookout and the dog beach"),
]


def main():
    rc = json.load(open(os.path.join(IN, "room_contracts.json")))["models"]
    rc.update(json.load(open(os.path.join(IN, "room_contracts_hp.json")))["models"])
    out = []
    for piece, label, model, pos, yaw, di, kind, name, style, pad, why in SHOPS:
        c = rc[model]
        i, e, a, b = bays(c)[di]
        boards = []
        if style:
            for sg in c.get("signs", []):
                if sg["facade"] == "front" and a - 0.05 <= sg["along"] <= b + 0.05: boards.append(sg)
                elif sg["facade"] == "left" and i == 0: boards.append(sg)
                elif sg["facade"] == "right" and b >= float(c["floors"][0]["box_max"][0]) - 0.05: boards.append(sg)
        rid = "%s_%s_%s_%d" % (piece[2:4], piece[5:], label, i)
        out.append({"id": rid, "piece": piece, "label": label, "model": model, "pos": [pos[0], pos[1] + pad, pos[2]], "yaw": yaw,
                    "door_index": i, "door_along": e["along"], "door_w": e["w"], "bay": [round(a, 3), round(b, 3)],
                    "kind": kind, "name": name, "style": style or "green", "font": "Overpass", "built": "", "why": why,
                    "signs": [{"facade": x["facade"], "along": x["along"], "w": x["w"]} for x in boards]})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(out), "rooms": out}, open(os.path.join(IN, "assignment_ea.json"), "w"), indent=1)
    print("assignment_ea.json: %d rooms" % len(out))
    for r in out:
        print("  %-34s %-10s %-30s bay %s signs %d" % (r["id"], r["kind"], r["name"], r["bay"], len(r["signs"])))


if __name__ == "__main__":
    main()
