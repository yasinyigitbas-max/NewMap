"""fe fill (claude/fill-high-street, 20 Nov): which business or service is behind which shop / civic door of the fe
pieces (n_fe_*). A hand list, one line per walk-in place, with the reason; the bay split comes from the building's
contract (room_contracts.json, the same rule as every other shop of the map: assign_all.bays). Writes
interiors/assignment_fe.json in assignment_all.json's format, for tools/city/rooms/room_gen_hp.gd
(--assign=assignment_fe.json --report=rooms_fe_report.json). The shared assignment files are not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_fe.py
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from assign_all import bays

# piece, label, model, local pos, yaw, door index, kind, name, sign style, pad (the piece's layout row height), why
SHOPS = [
    ("n_fe_b1e", "shops", "commercial/com_orange_row", (397.0, 1.0890, -976.83), 180.0, 0, "cleaners", "Crown Hill Laundry", "", 4.0,
     "the laundromat of the mews and the garden apartments (no washers of their own), on the strip's edge where they walk past"),
    ("n_fe_b1e", "shops", "commercial/com_orange_row", (397.0, 1.0890, -976.83), 180.0, 1, "cafe", "Hilltop Coffee", "", 4.0,
     "coffee while the washing turns, and for the drivers off the strip who park in the lot"),
    ("n_fe_b1e", "shops", "commercial/com_orange_row", (397.0, 1.0890, -976.83), 180.0, 2, "salon", "Corner Cuts Barbers", "", 4.0,
     "the neighbourhood's barber, next to the coffee"),
    ("n_fe_b1e", "corner", "commercial/com_orange_corner", (474.0, 0.3971, -976.83), 180.0, 0, "corner_shop", "Crown Hill Market", "", 4.0,
     "milk, bread and beer on the corner of the u 500 street, the nearest food shop for the mews and the apartments"),
    ("n_fe_b1e", "corner", "commercial/com_orange_corner", (474.0, 0.3971, -976.83), 180.0, 1, "pharmacy", "Hilltop Pharmacy", "", 4.0,
     "a pharmacy counter beside the market for the older residents of the band"),
    ("n_fe_b2", "trade", "ck/ck_svc_trade", (522.0, 0.2388, -975.0), -90.0, 0, "sport", "Ringside Bikes", "teal", 4.0,
     "bikes sold and mended at the start of the ring path, the island's bike loop"),
    ("n_fe_b2", "trade", "ck/ck_svc_trade", (522.0, 0.2388, -975.0), -90.0, 1, "cleaners", "Ringside Dry Cleaners", "navy", 4.0,
     "dry cleaning for the strip's motels and the apartment band, beside the bike shop"),
    ("n_fe_b2", "cafe", "commercial/com_cafe_seaside", (630.0, 0.1953, -972.0), 90.0, 0, "cafe", "Overlook Cafe", "", 4.0,
     "the park's cafe on the overlook (its CROWN CAFE sign painted on): coffee and ice tea with the bay in view"),
    ("n_fe_r5", "rec", "civic/civ_rec_center", (527.95, 2.1022, -510.0), -90.0, 0, "sport", "Glorietta Rec Center", "teal", 4.0,
     "the rec center's front desk on the u 500 street: court bookings, classes, rackets and balls to borrow"),
    ("n_fe_r1", "bakery", "commercial/com_bakery", (528.0, 0.1899, -23.17), 0.0, 0, "bakery", "Point Bakery", "", 4.0,
     "bread and pastries on the v 0 street for the people walking down to the waterfront"),
    ("n_fe_r1", "surf", "commercial/com_surf_shop", (540.0, 0.1851, -22.95), 0.0, 0, "sport", "Glorietta Surf Co.", "", 4.0,
     "boards, wetsuits and wax on the way to the bay beach"),
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
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(out), "rooms": out}, open(os.path.join(IN, "assignment_fe.json"), "w"), indent=1)
    print("assignment_fe.json: %d rooms" % len(out))
    for r in out:
        print("  %-34s %-10s %-30s bay %s signs %d" % (r["id"], r["kind"], r["name"], r["bay"], len(r["signs"])))


if __name__ == "__main__":
    main()
