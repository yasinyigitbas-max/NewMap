"""Hospital zone and university campus (claude/fill-high-street, 19 Nov): which business or service is behind which
door of the new hospital-zone / campus pieces. A hand list, one line per walk-in place, with the reason; the bay split
comes from the building's contract (room_contracts.json or room_contracts_hp.json, the same rule as every other shop of
the map: assign_all.bays). Writes interiors/assignment_hp.json in assignment_all.json's format, for
tools/city/rooms/room_gen_hp.gd. The shared assignment files are not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_hp.py
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from assign_all import bays

# piece, label, model, local pos, yaw, door index, kind, name, sign style, pad (the piece's layout row height), why
SHOPS = [
    ("n_hp_main", "hospital", "public/pub_hospital", (541.0, 0.15, -1482.46), 0.0, 0, "clinic", "Island Hospital Main Lobby", "", 2.0,
     "the hospital's front door on the drop-off forecourt: reception and admissions desks, waiting seats, the way to the wards"),
    ("n_hp_main", "hospital", "public/pub_hospital", (541.0, 0.15, -1482.46), 0.0, 1, "cafe", "Atrium Cafe", "", 2.0,
     "the hospital's second front door: coffee and sandwiches for visitors and the night shift, next to the lobby"),
    ("n_hp_main", "er_wing", "extras/ext_hospital", (590.0, 0.15, -1483.57), 0.0, 1, "clinic", "Emergency Department", "", 2.0,
     "the ER's front door on the ambulance bay (EMERGENCY painted over it): triage desk, the waiting room"),
    ("n_hp_transit", "transit_hall", "civic/civ_post_office", (548.0, 0.15, -1428.55), 180.0, 0, "transit", "Island Transit Center", "navy", 2.0,
     "Yasin: 'Place a bus station at hospital': the waiting hall on the bus platform: ticket windows, timetables, benches, vending"),
    ("n_hp_west", "tower", "urban/twr_office", (471.0, 0.15, -1432.0), 90.0, 0, "clinic", "Bay Medical Plaza Urgent Care", "teal", 2.0,
     "the medical office tower's door on Adela, facing the hospital: the walk-in clinic for what is not an emergency"),
    ("n_hp_west", "pharmacy", "ck/ck_svc_trade_1d", (427.0, 0.15, -1425.5), 0.0, 0, "pharmacy", "Island Pharmacy", "green", 2.0,
     "prescriptions for the people leaving the hospital and the clinic, on 3rd St between the tower and the bus station"),
    ("n_hp_west", "bistro", "commercial/com_bistro", (410.0, 0.15, -1427.67), 0.0, 0, "restaurant", "Isla Bistro", "", 2.0,
     "lunch for the hospital's staff and visitors (its ISLA BISTRO sign painted on); its tables on the 3rd St forecourt"),
    ("n_hp_west", "wellness", "civic/civ_community_center", (476.05, 0.15, -1535.0), 90.0, 0, "hall", "Bayview Wellness Center", "", 2.0,
     "the care residences' day center (its COMMUNITY CENTER sign painted on): classes, meals, visitors; door on Adela for the bus riders"),
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
        rid = "hp_%s_%s_%d" % (piece[5:], label, i)
        out.append({"id": rid, "piece": piece, "label": label, "model": model, "pos": [pos[0], pos[1] + pad, pos[2]], "yaw": yaw,
                    "door_index": i, "door_along": e["along"], "door_w": e["w"], "bay": [round(a, 3), round(b, 3)],
                    "kind": kind, "name": name, "style": style or "green", "font": "Overpass", "built": "", "why": why,
                    "signs": [{"facade": x["facade"], "along": x["along"], "w": x["w"]} for x in boards]})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(out), "rooms": out}, open(os.path.join(IN, "assignment_hp.json"), "w"), indent=1)
    print("assignment_hp.json: %d rooms" % len(out))
    for r in out:
        print("  %-34s %-10s %-30s bay %s signs %d" % (r["id"], r["kind"], r["name"], r["bay"], len(r["signs"])))


if __name__ == "__main__":
    main()
