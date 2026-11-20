"""Which shop is behind every shop door of the WEST FILL (University session, 20 Nov; copy of assign_un.py) (claude/fill-city-centre, 19 Nov; Yasin via the
session that started this one: "use the indoor generator in the pilot and do them both together"). A copy of
assign_strip.py. Hand-made: each building's businesses are chosen as part of its block's design (the piece script's
header says why); this table names them, splits rows into bays at their doors, and claims the sign boards. No real
brands.

Reads  map_dc/coronado/city_kit/interiors/w_buildings.json, room_contracts_w.json (room_contracts_cc.gd)
Writes map_dc/coronado/city_kit/interiors/assignment_w.json (read by tools/city/rooms/room_gen_cc.gd). The shared
       assignment_all.json is not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_cc.py
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")

# (piece, building label) -> list of shops: (door along of the shop's main entrance, bay [x0, x1] in the model frame or
# None = the whole floor, kind of room_gen_strip.KINDS, shop name, sign style)
SHOPS = {
    # ---- n_w_i1: marine trades
    ("n_w_i1", "boatworks"): [(None, None, "store", "Coronado Boatworks Chandlery", "navy")],
    ("n_w_i1", "marine_engines"): [(None, None, "workshop", "Bay Marine Engines", "teal")],
    ("n_w_i1", "marine_supply"): [(None, None, "store", "Coronado Marine Supply", "navy")],
    # ---- n_w_i2: industry to the gritty edge
    ("n_w_i2", "building_supply"): [(None, None, "store", "Pacific Building Supply", "green")],
    ("n_w_i2", "tire_brake"): [(None, None, "workshop", "Strand Tire & Brake", "sun")],
    ("n_w_i2", "liquor_deli"): [(None, None, "corner_shop", "Strand Liquor & Deli", "sun")],
    # ---- n_w_g1: the gritty edge's east half
    ("n_w_g1", "anchor_bar"): [(None, None, "bar", "The Anchor", "navy")],
    ("n_w_g1", "laundry_pawn"): [(None, None, "cleaners", "Coin Laundry", "teal")],
    ("n_w_g1", "thrift_row"): [(None, None, "clothes", "Second Chance Thrift", "green")],
    ("n_w_g1", "corner_market"): [(None, None, "corner_shop", "Strand Corner Market", "sun")],
    # ---- the rest of the west fill (20 Nov)
    ("n_w_c1", "fire_station"): [(None, None, "office", "Fire Station 2", "navy")],
    ("n_w_c1", "post_office"): [(None, None, "bank", "Coronado Post Office", "navy")],
    ("n_w_c1", "church"): [(None, None, "church", "St. Andrew's", "navy")],
    ("n_w_c3", "senior_center"): [(None, None, "venue", "Ridge Senior Center", "teal")],
    ("n_w_c6", "child_care"): [(None, None, "lobby", "Bright Start Child Care", "sun")],
    ("n_w_c8", "team_store"): [(None, None, "clothes", "Stadium Team Store", "navy")],
    ("n_w_c8", "bullpen_bar"): [(None, None, "bar", "The Bullpen", "sun")],
    ("n_w_c8", "touchdown_diner"): [(None, None, "restaurant", "Touchdown Diner", "sun")],
    ("n_w_c9", "arcade"): [(None, None, "store", "Amber Arcade Gifts", "teal")],
    ("n_w_c9", "bakery"): [(None, None, "bakery", "Amber Bakery", "sun")],
    ("n_w_c9", "shop_row"): [(None, None, "shoes", "Amber Shoes", "navy")],
    ("n_w_c9", "amber_diner"): [(None, None, "restaurant", "Amber Diner", "sun")],
    ("n_w_c9", "boutiques"): [(None, None, "clothes", "Ridge Boutique", "green")],
    ("n_w_c9", "surf_shop"): [(None, None, "sport", "Strand Surf", "teal")],
    ("n_w_c9", "corner_shop"): [(None, None, "corner_shop", "Amber Market", "sun")],
    ("n_w_c5", "boutiques"): [(None, None, "jewelry", "Bay Jewelers", "navy")],
    ("n_w_c5", "bakery"): [(None, None, "ice_cream", "Scoops", "sun")],
    ("n_w_c5", "corner_shop"): [(None, None, "pharmacy", "Amber Pharmacy", "green")],
    ("n_w_c5", "realty"): [(None, None, "office", "Ridge Realty", "navy")],
    ("n_w_c5", "cafe"): [(None, None, "cafe", "Amber Coffee", "teal")],
    ("n_w_s1", "gate_pizza"): [(None, None, "restaurant", "Gate Pizza", "sun")],
    ("n_w_s1", "campus_cycles"): [(None, None, "bike", "Campus Cycles", "green")],
    ("n_w_s1", "gatehouse_pub"): [(None, None, "bar", "The Gatehouse", "navy")],
    ("n_w_s1", "housing_office"): [(None, None, "office", "Student Housing Office", "teal")],
    ("n_w_s2a", "campus_market"): [(None, None, "grocery", "Campus Market", "green")],
    ("n_w_s2b", "print_boba"): [(None, None, "print", "Print & Copy", "navy")],
    ("n_w_s2b", "burrito_books"): [(None, None, "fast_food", "Burrito Bar", "sun")],
    ("n_w_s2b", "quad_pub"): [(None, None, "bar", "The Quad Pub", "navy")],
    ("n_w_s2b", "corner_deli"): [(None, None, "corner_shop", "Corner Deli", "sun")],
    ("n_w_w4", "school_a"): [(None, None, "lecture", "Ridgeview Elementary", "teal")],
    ("n_w_w4", "school_b"): [(None, None, "lecture", "Ridgeview Elementary - Library", "teal")],
    ("n_w_w6", "ridge_church"): [(None, None, "church", "Ridge Community Church", "navy")],
    ("n_w_e4", "surf_shack"): [(None, None, "sport", "Surf Shack", "teal")],
    ("n_w_e4", "beach_bean"): [(None, None, "cafe", "Beach Bean", "sun")],
}
# not walk-in (no room): homes (walk-ups, court apartments, townhouses, houses) are not entered in this pass


def main():
    blds = json.load(open(os.path.join(IN, "w_buildings.json")))["buildings"]
    rc = json.load(open(os.path.join(IN, "room_contracts_w.json")))["models"]
    rooms = []; missing = []
    for b in blds:
        key = (b["piece"], b["label"])
        if key not in SHOPS:
            missing.append(key); continue
        c = rc[b["model"]]
        fl = c["floors"][0]
        for k, (along, bay, kind, name, style) in enumerate(SHOPS[key]):
            if kind is None: continue        # a second door of the shop before it
            fronts = [e for e in c["entrances"] if e["facade"] == "front" and e["floor"] == 0 and e["kind"] in ("shop", "civic", "residential")]
            if not fronts:
                print("  no front entrance (no room):", key, b["model"]); break
            ent = fronts[0] if along is None else min(fronts, key=lambda e: abs(e["along"] - along))
            bx = bay if bay is not None else [fl["box_min"][0], fl["box_max"][0]]
            # the shop's boards: every front board over its bay; a building with one shop also takes its side boards
            signs = [{"facade": s["facade"], "along": s["along"], "w": s["w"]} for s in c.get("signs", [])
                     if (s["facade"] == "front" and bx[0] - 0.3 <= s["along"] <= bx[1] + 0.3) or (len(SHOPS[key]) == 1 and s["facade"] != "back")]
            rid = "w_%s__%s__%d" % (b["piece"][4:], b["label"], k)
            rooms.append({"id": rid, "piece": b["piece"], "label": b["label"], "model": b["model"], "pos": b["pos"], "yaw": b["yaw"],
                          "door_index": k, "door_along": ent["along"], "door_w": ent["w"], "bay": bx, "kind": kind, "name": name,
                          "style": style, "signs": signs, "source": "west fill (hand-made room list)", "built": ""})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(rooms), "rooms": rooms}, open(os.path.join(IN, "assignment_w.json"), "w"), indent=1)
    print("ASSIGN cc rooms=%d" % len(rooms))
    print("  homes and kiosks without a room:", len(missing))


if __name__ == "__main__":
    main()
