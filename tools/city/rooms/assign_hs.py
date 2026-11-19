"""High street fill (claude/fill-high-street, 19 Nov): which business is behind which door of the new high street
blocks. A hand list, one line per walk-in place, with the reason; the bay split comes from the building's contract
(room_contracts.json, the same rule as every other shop of the map: assign_all.bays). Writes
interiors/assignment_hs.json in assignment_all.json's format, for tools/city/rooms/room_gen_hs.gd (a copy of the pilot's
room_gen.gd that reads this file). The shared assignment_all.json is not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_hs.py
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from assign_all import bays

PAD = 4.0   # the pieces' layout row height (grid frame); building positions below are piece-local

# piece, label, model, local pos, yaw, door index, kind, name, sign style, why
SHOPS = [
    ("n_hs_b1_amber", "brick_row", "urban/urb_brick_row", (-23.0, 0.15, 106.88), 90.0, 0, "pharmacy", "Amber Drug", "green",
     "block 1: a high street needs its chemist; next to the hotel, where visitors ask for one"),
    ("n_hs_b1_amber", "brick_row", "urban/urb_brick_row", (-23.0, 0.15, 106.88), 90.0, 1, "restaurant", "Amber Deli", "cream",
     "block 1: lunch for the shops' staff and the library's readers; its green dumpster is behind it on the rear lot"),
    ("n_hs_b1_amber", "brick_row", "urban/urb_brick_row", (-23.0, 0.15, 106.88), 90.0, 2, "shoes", "Sole Coronado", "navy",
     "block 1: the paseo from the garage passes its door"),
    ("n_hs_b1_amber", "library", "civic/civ_library", (-30.0, 0.15, 131.31), 90.0, 0, "library", "Coronado Public Library", "",
     "block 1's landmark: the town library on its main street; the painted PUBLIC LIBRARY sign stays"),
    ("n_hs_b1_amber", "orange_row", "commercial/com_orange_row", (-23.0, 0.15, 153.48), 90.0, 0, "souvenir", "Ferry Landing Gifts", "sun",
     "block 1: visitors walking from the hotel to the beach road"),
    ("n_hs_b1_amber", "orange_row", "commercial/com_orange_row", (-23.0, 0.15, 153.48), 90.0, 1, "clothes", "Tide Threads", "teal",
     "block 1: a boutique in the shop row (its blue dumpster for boxes behind)"),
    ("n_hs_b1_amber", "orange_row", "commercial/com_orange_row", (-23.0, 0.15, 153.48), 90.0, 2, "jewelry", "Coral & Pearl", "navy",
     "block 1: the shop row's jeweller, next to the coffee house"),
    ("n_hs_b1_amber", "cafe", "commercial/com_cafe_seaside", (-23.0, 0.15, 166.70), 90.0, 0, "cafe", "Library Grounds Coffee", "cream",
     "block 1: coffee next to the library; newspaper boxes and pots at its door, its dumpster behind"),
    ("n_hs_b1_amber", "corner", "urban/urb_brick_corner", (-24.0, 0.15, 181.07), 90.0, 0, "sport", "South Beach Surf", "teal",
     "block 1: the corner on 11th St, the road down to the beach: boards, wetsuits, bikes"),
    ("n_hs_b1_tenth", "market", "apartments/apt_stucco3_peach", (-61.22, 0.15, 20.3), 180.0, 0, "corner_shop", "Tenth Street Market", "red",
     "block 1: the neighbourhood's market for the court's flats and the houses west; ice chest and papers on its forecourt"),
]


def main():
    rc = json.load(open(os.path.join(IN, "room_contracts.json")))["models"]
    out = []
    for piece, label, model, pos, yaw, di, kind, name, style, why in SHOPS:
        c = rc[model]
        i, e, a, b = bays(c)[di]
        boards = []
        if style:
            for sg in c.get("signs", []):
                if sg["facade"] == "front" and a - 0.05 <= sg["along"] <= b + 0.05: boards.append(sg)
                elif sg["facade"] == "left" and i == 0: boards.append(sg)
                elif sg["facade"] == "right" and b >= float(c["floors"][0]["box_max"][0]) - 0.05: boards.append(sg)
        rid = "hs_%s_%s_%d" % (piece[5:], label, i)
        out.append({"id": rid, "piece": piece, "label": label, "model": model, "pos": [pos[0], pos[1] + PAD, pos[2]], "yaw": yaw,
                    "door_index": i, "door_along": e["along"], "door_w": e["w"], "bay": [round(a, 3), round(b, 3)],
                    "kind": kind, "name": name, "style": style or "green", "font": "Overpass", "built": "", "why": why,
                    "signs": [{"facade": x["facade"], "along": x["along"], "w": x["w"]} for x in boards]})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(out), "rooms": out}, open(os.path.join(IN, "assignment_hs.json"), "w"), indent=1)
    print("assignment_hs.json: %d rooms" % len(out))
    for r in out:
        print("  %-34s %-12s %-24s bay %s signs %d" % (r["id"], r["kind"], r["name"], r["bay"], len(r["signs"])))


if __name__ == "__main__":
    main()
