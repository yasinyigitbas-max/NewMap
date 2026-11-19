"""Which shop is behind every shop door of the apartment band FILL blocks (claude/fill-apartments, 19 Nov; Yasin, relayed:
"use the indoor generator in the pilot and do them both together"). Hand-made: each shop is chosen as part of its
block's design (the piece script's header says why each business is there); this table names them, splits rows into
bays at their doors, and claims the building's sign boards for the shop behind them. No real brands.

Reads  map_dc/coronado/city_kit/interiors/apt_buildings.json (tools/city/rooms/list_buildings_apt.gd), room_contracts.json
Writes map_dc/coronado/city_kit/interiors/assignment_apt.json (same fields as assignment_all.json, read by
       tools/city/rooms/room_gen_apt.gd, a copy of room_gen_strip.gd). The shared assignment_all.json is not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_apt.py
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")

# (piece, building label) -> list of shops: (door along of the shop's entrance, bay [x0, x1] in the model frame or None =
# the whole floor, kind of room_gen_apt.KINDS, shop name, sign style, why it is there)
# The brick walk-ups (ck_brk3_row2*) have the shop door at -1.1 and the flats' stair door at 3.0: the shop's bay stops
# short of the stair door (x <= 2.2), the stair stays the tenants'.
SHOPS = {
    ("n_apt_b1_bw", "bakery"): [(3.26, None, "bakery", "B Avenue Bakery", "sun", "8th St is the walk into the centre: bread and coffee on the way to work")],
    ("n_apt_b1_bw", "barber"): [(-1.1, [-5.7, 2.2], "barber", "Eighth Street Barbers", "navy", "a two-chair barber under a flat, next to the bakery the same walkers pass")],
    ("n_apt_b1_be", "taqueria"): [(4.76, None, "taqueria", "Taqueria La Esquina", "sun", "the corner of 8th and Adela: golfers and the ring road's traffic stop for lunch")],
    ("n_apt_b1_be", "nail_salon"): [(1.76, None, "nails", "Polished Nail Studio", "red", "a small nail salon beside the taqueria: nurses and sailors off shift")],
    ("n_apt_b1_7th", "dry_cleaner"): [(-1.1, [-5.7, 2.2], "dry_cleaner", "Seventh Street Cleaners", "teal", "7th St is the bus street to the centre: shirts dropped on the way")],
    ("n_apt_b1_7th", "corner_shops_7th"): [(-4.08, [-8.7, -3.0], "pharmacy", "Adela Pharmacy & Post", "green", "the band's chemist with the post counter, at the bus stop corner"),
                                           (-1.92, [-3.0, 3.0], "tax", "Island Tax Service", "navy", "the tax office every neighbourhood has, in the middle unit"),
                                           (7.76, [3.0, 8.7], "donuts", "Sunrise Donuts", "red", "the donut shop on the corner, for the bus riders and the night shift")],
    ("n_apt_b1_7th", "coffee_window"): [(-1.76, None, "coffee", "The Coffee Window", "black", "a narrow coffee bar beside the corner shops: the queue outside in the morning")],
    ("n_apt_b2_7th", "church_7th"): [(0.0, None, "chapel", "Seventh Street Community Church", "navy", "the band's church on the bus street; its lot doubles as the flats' overflow parking")],
    ("n_apt_b2_7th", "corner_market"): [(4.9, [-1.2, 5.7], "discount", "Adela Corner Market", "red", "everyday shopping at 7th and Adela, facing the pharmacy corner; the flat above is the shopkeeper's")],
    ("n_apt_b2_be", "bike_shop"): [(-3.3, None, "bikes", "Hill Street Bikes", "teal", "the hill's families and the beach riders: repairs and kids' bikes on the corner of 6th and Adela")],
    ("n_apt_b2_bw", "community_room"): [(0.0, None, "community", "Glorietta Hill Community Room", "green", "the apartments' association hall: meetings at night, the preschool in the day, its play yard behind")],
    ("n_apt_b1_7th", "launderette"): [(-1.1, [-5.7, 2.2], "laundromat", "Adela Wash & Fold", "sea", "the walk-ups have no machines: the launderette under the flats on Adela")],
}


def main():
    blds = json.load(open(os.path.join(IN, "apt_buildings.json")))["buildings"]
    rc = json.load(open(os.path.join(IN, "room_contracts.json")))["models"]
    rooms = []; seen = set()
    for b in blds:
        key = (b["piece"], b["label"])
        if key not in SHOPS: continue
        seen.add(key)
        c = rc[b["model"]]
        fl = c["floors"][0]
        for k, (along, bay, kind, name, style, why) in enumerate(SHOPS[key]):
            ent = min([e for e in c["entrances"] if e["facade"] == "front" and e["floor"] == 0], key=lambda e: abs(e["along"] - along))
            bx = bay if bay is not None else [fl["box_min"][0], fl["box_max"][0]]
            signs = [{"facade": s["facade"], "along": s["along"], "w": s["w"]} for s in c.get("signs", [])
                     if (s["facade"] == "front" and bx[0] - 0.3 <= s["along"] <= bx[1] + 0.3) or (len(SHOPS[key]) == 1 and s["facade"] != "back")]
            rid = "apt_%s__%s__%d" % (b["piece"].replace("n_apt_", ""), b["label"], k)
            rooms.append({"id": rid, "piece": b["piece"], "label": b["label"], "model": b["model"], "pos": b["pos"], "yaw": b["yaw"],
                          "door_index": k, "door_along": ent["along"], "door_w": ent["w"], "bay": bx, "kind": kind, "name": name,
                          "style": style, "signs": signs, "why": why, "source": "apartment fill (hand-made shop list)", "built": ""})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(rooms), "rooms": rooms}, open(os.path.join(IN, "assignment_apt.json"), "w"), indent=1)
    print("ASSIGN apt rooms=%d" % len(rooms))
    for key in SHOPS:
        if key not in seen: print("  building not found:", key)


if __name__ == "__main__":
    main()
