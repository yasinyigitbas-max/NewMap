"""ec fill (claude/fill-high-street, 20 Nov): which business or service is behind which shop / civic door of the ec
pieces (n_ec_*, the east shore beyond the ring, v -500 .. 0). A hand list, one line per walk-in place, with the reason; the bay split comes from the building's
contract (room_contracts.json, the same rule as every other shop of the map: assign_all.bays). Writes
interiors/assignment_ec.json in assignment_all.json's format, for tools/city/rooms/room_gen_hp.gd
(--assign=assignment_ec.json --report=rooms_ec_report.json). The shared assignment files are not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_ec.py
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from assign_all import bays

# piece, label, model, local pos, yaw, door index, kind, name, sign style, pad (the piece's layout row height), why
SHOPS = [
    ("n_ec_dune_n", "snackbar", "commercial/com_cafe_seaside", (1099.8, 3.3722, -414.0), 90.0, 0, "fast_food", "Shoreline Snack Bar", "", 0.0,
     "hot dogs, fries, ice cream and cold drinks where the beach walk from the v -400 crossing meets the promenade; people eat on its terrace or carry it down to the sand"),
    ("n_ec_dune_s", "cafe", "commercial/com_cafe_seaside", (1062.8, 3.8299, -214.0), 90.0, 0, "cafe", "Dune Cafe", "", 0.0,
     "coffee, iced tea and sandwiches on the promenade where the beach walk from the v -200 crossing arrives; the terrace looks over the dune to the sea"),
    ("n_ec_dune_s", "rentals", "commercial/com_surf_shop", (983.05, 1.3580, -24.0), 90.0, 0, "sport", "South Beach Rentals", "", 0.0,
     "kayaks, paddle boards, umbrellas and boogie boards for hire at the south access, the one the people from the waterfront use; its racks stand in its yard and at the water"),
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
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(out), "rooms": out}, open(os.path.join(IN, "assignment_ec.json"), "w"), indent=1)
    print("assignment_ec.json: %d rooms" % len(out))
    for r in out:
        print("  %-34s %-10s %-30s bay %s signs %d" % (r["id"], r["kind"], r["name"], r["bay"], len(r["signs"])))


if __name__ == "__main__":
    main()
