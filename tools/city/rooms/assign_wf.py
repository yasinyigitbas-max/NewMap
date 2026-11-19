"""Which shop is behind every shop door of the waterfront FILL pieces (n_wf_*, branch claude/fill-waterfront, 19 Nov;
Yasin, relayed: "use the indoor generator in the pilot and do them both together"). Hand-made: each business is chosen
in its block's design (the piece script's header says why it stands there); this table names them, splits rows into
bays at their doors and gives the shop the building's sign boards. No real brands.

Reads  map_dc/coronado/city_kit/interiors/wf_buildings.json (tools/city/rooms/list_buildings_wf.gd),
       room_contracts.json + room_contracts_strip.json (com_shallow_surf is only in the strip's list; both read-only)
Writes map_dc/coronado/city_kit/interiors/assignment_wf.json (fields of assignment_all.json; read by room_gen_wf.gd).
The shared assignment_all.json is not touched. Run from the repo root: python3 -I tools/city/rooms/assign_wf.py
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")

# (piece, building label) -> [(door along in the model frame, bay [x0, x1] or None = the whole floor, kind, name, style)]
SHOPS = {
    ("n_wf_b1w", "casa_del_mar_inn"): [(0.0, [-4.6, 4.6], "hotel", "Casa del Mar Inn", "sea")],      # the reception behind the middle door; the flats either side are guest rooms
    ("n_wf_b1w", "harbour_bakery"): [(3.26, None, "bakery", "Harbour Bakery & Coffee", "sun")],
    ("n_wf_b1w", "bay_bike_hire"): [(1.76, None, "rental", "Bay Bikes", "teal")],
    ("n_wf_b1w", "shoreline_grill"): [(4.76, None, "restaurant", "Shoreline Grill", "navy")],
    ("n_wf_b1m", "scoops_row"): [(-4.08, [-8.7, -3.0], "ice_cream", "Scoops Ice Cream", "red"),
                                 (-1.92, [-3.0, 3.0], "clothes", "Sandbar Swimwear", "sea"),
                                 (7.76, [3.0, 8.7], "souvenir", "Seashell Gifts", "teal")],
    ("n_wf_b1m", "tide_bar"): [(-3.26, None, "bar", "The Tide Bar", "black")],
    ("n_wf_b1m", "dive_surf_row"): [(-4.08, [-8.7, -3.0], "dive", "Deep Blue Dive", "navy"),
                                    (-1.92, [-3.0, 3.0], "shoes", "Sun & Sand Sandals", "sun"),
                                    (7.76, [3.0, 8.7], "rental", "Board Room Surf Rentals", "sea")],
    ("n_wf_b1e", "the_fish_house"): [(-2.92, [-11.7, 1.0], "restaurant", "The Fish House", "sea"),
                                     (5.08, [1.0, 11.7], "fast_food", "Pier Poke & Tacos", "red")],
    ("n_wf_b1e", "pier_bait_tackle"): [(3.3, None, "bait", "Pier Bait & Tackle", "green")],
    ("n_wf_b1e", "salt_water_surf"): [(-3.26, None, "sport", "Salt Water Surf", "sea")],
    ("n_wf_b1e", "bay_paddle_hire"): [(1.15, None, "rental", "Bay Paddle", "teal")],
}


def main():
    blds = json.load(open(os.path.join(IN, "wf_buildings.json")))["buildings"]
    rc = {}
    for f in ("room_contracts.json", "room_contracts_strip.json"):
        rc.update(json.load(open(os.path.join(IN, f)))["models"])
    rooms = []; missing = []; listed = 0
    for b in blds:
        key = (b["piece"], b["label"])
        if key not in SHOPS:
            continue                      # houses and flats: homes, no walk-in place
        listed += 1
        c = rc[b["model"]]
        fl = c["floors"][0]
        for k, (along, bay, kind, name, style) in enumerate(SHOPS[key]):
            ent = min([e for e in c["entrances"] if e["facade"] == "front" and e["floor"] == 0], key=lambda e: abs(e["along"] - along))
            bx = bay if bay is not None else [fl["box_min"][0], fl["box_max"][0]]
            signs = [{"facade": s["facade"], "along": s["along"], "w": s["w"]} for s in c.get("signs", [])
                     if (s["facade"] == "front" and bx[0] - 0.3 <= s["along"] <= bx[1] + 0.3) or (len(SHOPS[key]) == 1 and s["facade"] != "back")]
            rid = "wfa_%s__%s__%d" % (b["piece"][5:], b["label"], k)
            rooms.append({"id": rid, "piece": b["piece"], "label": b["label"], "model": b["model"], "pos": b["pos"], "yaw": b["yaw"],
                          "door_index": k, "door_along": ent["along"], "door_w": ent["w"], "bay": bx, "kind": kind, "name": name,
                          "style": style, "signs": signs, "source": "waterfront fill (hand-made shop list)", "built": ""})
    for key in SHOPS:
        if not any((b["piece"], b["label"]) == key for b in blds): missing.append(key)
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(rooms), "rooms": rooms}, open(os.path.join(IN, "assignment_wf.json"), "w"), indent=1)
    print("ASSIGN wf rooms=%d in %d buildings" % (len(rooms), listed))
    for m in missing: print("  listed but not built:", m)


if __name__ == "__main__":
    main()
