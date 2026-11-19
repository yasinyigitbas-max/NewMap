"""Which shop is behind every shop door of the CITY-CENTRE FILL (claude/fill-city-centre, 19 Nov; Yasin via the
session that started this one: "use the indoor generator in the pilot and do them both together"). A copy of
assign_strip.py. Hand-made: each building's businesses are chosen as part of its block's design (the piece script's
header says why); this table names them, splits rows into bays at their doors, and claims the sign boards. No real
brands.

Reads  map_dc/coronado/city_kit/interiors/cc_buildings.json, room_contracts_cc.json (room_contracts_cc.gd)
Writes map_dc/coronado/city_kit/interiors/assignment_cc.json (read by tools/city/rooms/room_gen_cc.gd). The shared
       assignment_all.json is not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_cc.py
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")

# (piece, building label) -> list of shops: (door along of the shop's main entrance, bay [x0, x1] in the model frame or
# None = the whole floor, kind of room_gen_strip.KINDS, shop name, sign style)
SHOPS = {
    # Amber wall (n_cc_b1_am): the centre's main street, offices over shops
    ("n_cc_b1_am", "amber6_tower"): [(-4.0, None, "lobby", "Sixth & Amber Building", "black")],
    ("n_cc_b1_am", "amber_bank"): [(6.8, None, "bank", "Amber Savings Bank", "navy")],
    ("n_cc_b1_am", "amber_deli_row"): [(-4.1, [-8.7, -1.1], "restaurant", "Marlowe's Deli", "red"),
                                       (1.9, [-1.1, 4.9], "clothes", "Ferris Tailors", "navy"),
                                       (7.9, [4.9, 8.7], "keys", "Fix-It Phone Repair", "black")],
    ("n_cc_b1_am", "amber_barber_fe"): [(-1.1, [-5.7, 2.2], "salon", "Seventh Wave Barbers", "red")],
    ("n_cc_b1_am", "amber_books"): [(-1.1, [-5.7, 2.2], "books", "Amber Books", "green")],
    ("n_cc_b1_am", "amber_corner_cafe"): [(4.9, [-1.8, 5.7], "cafe", "Court Side Coffee", "teal")],
    # 6th St row (n_cc_b1_n): the neighbourhood's daily errands
    ("n_cc_b1_n", "sixth_corner_shop"): [(4.9, [-1.8, 5.7], "corner_shop", "Sixth St Market", "sun")],
    ("n_cc_b1_n", "sixth_brick_row"): [(-4.1, [-8.7, -1.1], "store", "Island Hardware", "red"),
                                       (1.9, [-1.1, 4.9], "cleaners", "Sixth St Laundromat", "sea"),
                                       (7.9, [4.9, 8.7], "jewelry", "Watch & Jewel Repair", "black")],
    ("n_cc_b1_n", "sixth_diner_block"): [(0.0, [-5.4, 5.4], "restaurant", "Sixth Street Diner", "teal")],
    ("n_cc_b1_n", "sixth_pharmacy"): [(-1.1, [-5.7, 2.2], "pharmacy", "Downtown Pharmacy", "green")],
    # C Ave (n_cc_b1_west)
    ("n_cc_b1_west", "cave_corner_flats"): [(0.0, [-5.4, 5.4], "bakery", "C Avenue Bakery", "sun")],
    ("n_cc_b1_west", "downtown_church"): [(0.0, None, "church", "Sacred Heart Church", "navy")],
    # courthouse block (n_cc_b1_court)
    ("n_cc_b1_court", "courthouse"): [(0.0, None, "court", "Coronado County Courthouse", "navy")],
    ("n_cc_b1_court", "law_office_n"): [(-1.1, [-5.7, 2.2], "law", "Hale & Ortiz Attorneys", "navy")],
    ("n_cc_b1_court", "law_office_s"): [(-1.1, [-5.7, 2.2], "bail", "Bayview Bail Bonds", "red")],
    ("n_cc_b1_court", "legal_aid"): [(-1.1, [-5.7, 2.2], "office", "Island Legal Aid", "teal")],
}
# not walk-in (no room): the kiosk (a walk-up window), the garage, every flat (homes are not entered in this pass)


def main():
    blds = json.load(open(os.path.join(IN, "cc_buildings.json")))["buildings"]
    rc = json.load(open(os.path.join(IN, "room_contracts_cc.json")))["models"]
    rooms = []; missing = []
    for b in blds:
        key = (b["piece"], b["label"])
        if key not in SHOPS:
            missing.append(key); continue
        c = rc[b["model"]]
        fl = c["floors"][0]
        for k, (along, bay, kind, name, style) in enumerate(SHOPS[key]):
            if kind is None: continue        # a second door of the shop before it
            ent = min([e for e in c["entrances"] if e["facade"] == "front" and e["floor"] == 0], key=lambda e: abs(e["along"] - along))
            bx = bay if bay is not None else [fl["box_min"][0], fl["box_max"][0]]
            # the shop's boards: every front board over its bay; a building with one shop also takes its side boards
            signs = [{"facade": s["facade"], "along": s["along"], "w": s["w"]} for s in c.get("signs", [])
                     if (s["facade"] == "front" and bx[0] - 0.3 <= s["along"] <= bx[1] + 0.3) or (len(SHOPS[key]) == 1 and s["facade"] != "back")]
            rid = "cc_%s__%s__%d" % (b["piece"][5:], b["label"], k)
            rooms.append({"id": rid, "piece": b["piece"], "label": b["label"], "model": b["model"], "pos": b["pos"], "yaw": b["yaw"],
                          "door_index": k, "door_along": ent["along"], "door_w": ent["w"], "bay": bx, "kind": kind, "name": name,
                          "style": style, "signs": signs, "source": "city-centre fill (hand-made shop list)", "built": ""})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(rooms), "rooms": rooms}, open(os.path.join(IN, "assignment_cc.json"), "w"), indent=1)
    print("ASSIGN cc rooms=%d" % len(rooms))
    for m in missing: print("  no shop listed for", m)


if __name__ == "__main__":
    main()
