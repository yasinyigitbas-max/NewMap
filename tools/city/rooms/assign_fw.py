"""North-west column (fw; claude/fill-high-street, 20 Nov): which business or service is behind which shop / civic door
of the n_fw_* pieces. A hand list, one line per walk-in place, with the reason; the bay split from the building's
contract (room_contracts.json, assign_all.bays). Writes interiors/assignment_fw.json (assignment_all.json's format) for
tools/city/rooms/room_gen_hp.gd. The shared assignment files are not touched. (Copy of assign_hp.py.)
Run from the repo root: python3 -I tools/city/rooms/assign_fw.py
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from assign_all import bays

# piece, label, model, local pos, yaw, door index, kind, name, sign style, pad (the piece's layout row height), why
SHOPS = [
    ("n_fw_bay", "condo", "apartments/apt_beach_condo", (-300.0, 2.3084, -1566.4), 180.0, 0, "cafe", "Bayfront Cafe", "", 0.0,
     "the beach condo's ground-floor front door on the bay walk: coffee for the people walking the bay, tables on its terrace"),
    ("n_fw_slope", "market", "commercial/com_orange_corner", (-370.0, 2.4682, -1371.83), 180.0, 0, "corner_shop", "Hilltop Market", "green", 0.0,
     "the neighbourhood's corner store at the slope's low corner on the arterial: milk, bread, the day's things for the apartments above"),
    ("n_fw_slope", "market", "commercial/com_orange_corner", (-370.0, 2.4682, -1371.83), 180.0, 1, "cleaners", "Suds Laundromat", "teal", 0.0,
     "the laundromat next door: walk-up apartments have no machines; people wash while they shop"),
    ("n_fw_slope", "coffee", "commercial/com_cafe_seaside", (-222.0, 4.3255, -1371.83), 180.0, 0, "cafe", "Crown Hill Coffee", "", 0.0,
     "coffee at the NE corner where the walk down from Crown Hill meets the arterial to the bay"),
    ("n_fw_crest", "bakery", "commercial/com_bakery", (-222.0, 10.1416, -1171.83), 180.0, 0, "bakery", "Crest Bakery", "", 0.0,
     "bread at the crest, the busiest and highest corner of the slope; its tables on the corner terrace"),
    ("n_fw_crest", "salon", "ck/ck_svc_trade_1d", (-240.0, 9.9925, -1174.0), 180.0, 0, "salon", "Crest Cuts", "navy", 0.0,
     "the hill's hair salon beside the bakery, for the apartments round the crest"),
    ("n_fw_court", "community", "civic/civ_community_center", (-369.0, 6.2661, -826.95), 0.0, 0, "hall", "Crown Hill Community Center", "", 0.0,
     "the neighbourhood's hall on the civic band's edge: meetings, classes, the residents' association, by the park"),
    ("n_fw_court", "pharmacy", "ck/ck_svc_trade_1d", (-228.0, 6.2537, -822.0), 0.0, 0, "pharmacy", "Crown Hill Pharmacy", "green", 0.0,
     "prescriptions for the apartments on the hill and the civic band's walkers, at the SE corner"),
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
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(out), "rooms": out}, open(os.path.join(IN, "assignment_fw.json"), "w"), indent=1)
    print("assignment_fw.json: %d rooms" % len(out))
    for r in out:
        print("  %-34s %-10s %-30s bay %s signs %d" % (r["id"], r["kind"], r["name"], r["bay"], len(r["signs"])))


if __name__ == "__main__":
    main()
