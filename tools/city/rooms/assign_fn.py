"""The north end (fill_east, prefix fn; 20 Nov): which business or service is behind which door of the n_fn_* pieces.
A hand list, one line per walk-in place, with the reason; the bay split comes from the building's contract
(room_contracts.json, the same rule as every other shop of the map: assign_all.bays). Writes
interiors/assignment_fn.json in assignment_all.json's format, for tools/city/rooms/room_gen_hp.gd. Copy of assign_hp.py;
the shared assignment files are not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_fn.py
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from assign_all import bays

# piece, label, model, local pos, yaw, door index, kind, name, sign style, pad (the piece's layout row height), why
SHOPS = [
    # (the inn: its one shop door opens on the whole 35 m ground floor; a room there checks "sparse" (25 things on
    #  324 m2) - left out, said in the README: it needs its own contract with an office bay)
    ("n_fn_east", "fish_house", "commercial/com_bistro", (311.83, 0.159054, -1572.0), 90.0, 0, "restaurant", "Pier Fish House", "", 2.0,
     "fish and chips on Ferry Plaza for the boat crowd; its tables out on the plaza"),
    ("n_fn_east", "ferry_office", "civic/civ_harbor_office", (350.0, 0.121545, -1552.05), 180.0, 0, "transit", "Coronado Ferry Tickets", "navy", 2.0,
     "the ferry ticket office facing the gap where the boats land: ticket windows, timetables, benches"),
    ("n_fn_east", "rental", "commercial/com_surf_shop", (389.95, 0.151991, -1574.0), -90.0, 0, "sport", "Bay Kayak & Bike Rental", "", 2.0,
     "kayaks and cruisers for the day-trippers off the ferry; its racks out on the plaza"),
    ("n_fn_east", "corner", "commercial/com_orange_corner", (268.0, 0.156755, -1427.67), 0.0, 0, "corner_shop", "North End Market", "", 2.0,
     "the corner market at B Ave x 3rd for the houses on Crown Hill and the park and ride"),
    ("n_fn_east", "corner", "commercial/com_orange_corner", (268.0, 0.156755, -1427.67), 0.0, 1, "cleaners", "Ferry Cleaners", "", 2.0,
     "drop the shirts on the way to the boat, pick them up on the way home"),
    ("n_fn_east", "boutiques", "commercial/com_boutique_row", (286.0, 0.153382, -1427.67), 0.0, 0, "clothes", "Bayline Outfitters", "", 2.0,
     "clothes on 3rd St, the route to the bridge"),
    ("n_fn_east", "boutiques", "commercial/com_boutique_row", (286.0, 0.153382, -1427.67), 0.0, 1, "souvenir", "Ferry Landing Gifts", "", 2.0,
     "gifts for the visitors walking up Ferry Walk from the boats"),
    ("n_fn_east", "boutiques", "commercial/com_boutique_row", (286.0, 0.153382, -1427.67), 0.0, 2, "salon", "Tides Salon", "", 2.0,
     "a neighbourhood hair salon"),
    ("n_fn_east", "bakery", "commercial/com_bakery", (309.0, 0.149791, -1427.67), 0.0, 0, "bakery", "Ferry Landing Bakery", "", 2.0,
     "morning bread and coffee where Ferry Walk meets 3rd St"),
    ("n_fn_east", "shop_row", "commercial/com_orange_row", (325.5, 0.151712, -1427.67), 0.0, 0, "books", "Harbor Books", "", 2.0,
     "a bookshop for the ride across"),
    ("n_fn_east", "shop_row", "commercial/com_orange_row", (325.5, 0.151712, -1427.67), 0.0, 1, "jewelry", "Sea Glass Jewelry", "", 2.0,
     "small jewelry shop on the shop row"),
    ("n_fn_east", "shop_row", "commercial/com_orange_row", (325.5, 0.151712, -1427.67), 0.0, 2, "keys", "North End Keys", "", 2.0,
     "keys cut and shoes mended for the neighbourhood"),
    ("n_fn_east", "pub", "commercial/com_bar_crown", (342.0, 0.148391, -1427.45), 0.0, 0, "bar", "The Ferryman", "", 2.0,
     "the pub for the ferry crews and the hospital night shift next door"),
    ("n_fn_east", "realty", "commercial/com_realty", (352.0, 0.150975, -1427.67), 0.0, 0, "realty", "North End Realty", "", 2.0,
     "the agent for the new bayfront condos and townhouses"),
    ("n_fn_east", "coffee", "commercial/com_cafe_seaside", (360.0, 0.151637, -1427.67), 0.0, 0, "cafe", "Third Street Coffee", "", 2.0,
     "coffee for the hospital staff and the bus riders on 3rd St"),
    ("n_fn_mid", "cafe", "commercial/com_cafe_seaside", (24.0, 0.467078, -1569.83), 180.0, 0, "cafe", "Amber Corner Cafe", "", 2.0,
     "the cafe at the foot of Amber on the bay, its tables on the corner plaza"),
    ("n_fn_mid", "icecream", "commercial/com_surf_shop", (35.0, 0.55328, -1570.05), 180.0, 0, "ice_cream", "Bay Scoops", "", 2.0,
     "ice cream for the people who walked down Amber to the water"),
    ("n_fn_west", "deli", "commercial/com_orange_corner", (-30.0, 6.135275, -1427.67), 0.0, 0, "corner_shop", "Crown Hill Deli", "", 2.0,
     "the hilltop corner at Amber x 3rd: sandwiches and groceries for the bus riders and the lane"),
    ("n_fn_west", "deli", "commercial/com_orange_corner", (-30.0, 6.135275, -1427.67), 0.0, 1, "store", "Hilltop Flowers", "", 2.0,
     "a florist beside the deli on the corner"),
]


def main():
    rc = json.load(open(os.path.join(IN, "room_contracts.json")))["models"]
    
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
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(out), "rooms": out}, open(os.path.join(IN, "assignment_fn.json"), "w"), indent=1)
    print("assignment_fn.json: %d rooms" % len(out))
    for r in out:
        print("  %-34s %-10s %-30s bay %s signs %d" % (r["id"], r["kind"], r["name"], r["bay"], len(r["signs"])))


if __name__ == "__main__":
    main()
