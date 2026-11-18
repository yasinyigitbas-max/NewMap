"""Which shop is behind every shop door of the commercial strip's GROWTH blocks (claude/grow-strip, 18 Nov; Yasin:
"do out and indoors together"). Hand-made: each new strip building's shops are chosen as part of its block's design
(the block script's header says why each business is there); this table names them, splits rows into bays at their
doors, and claims the building's sign boards for the shop behind them. No real brands.

Reads  map_dc/coronado/city_kit/interiors/strip_buildings.json, room_contracts_strip.json (room_contracts_strip.gd)
Writes map_dc/coronado/city_kit/interiors/assignment_strip.json (same fields as assignment_all.json, read by
       tools/city/rooms/room_gen_strip.gd). The shared assignment_all.json is not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_strip.py
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")

# (piece, building label) -> list of shops: (door along of the shop's main entrance, bay [x0, x1] in the model frame or
# None = the whole floor, kind of room_gen_strip.KINDS, shop name, sign style)
SHOPS = {
    ("m_gr_ad5ne", "crown_car_care_row"): [(-4.08, [-8.7, 3.0], "auto_parts", "Strand Auto Parts", "red"),
                                           (7.76, [3.0, 8.7], "phone", "Bridge Cell & Vape", "black")],
    ("m_gr_ad5ne", "quick_lube"): [(-6.5, [-8.7, -3.4], "lube", "Ten Minute Lube", "sun")],
    ("m_gr_ad5ne", "taqueria_adela"): [(3.3, None, "taqueria", "Tacos El Puente", "sun")],
    ("m_gr_ad5ne", "tax_office"): [(1.8, None, "tax", "Island Tax & Insurance", "navy")],
    ("m_gr_ad5ne", "chicken_drive"): [(1.2, None, "drive_thru", "Coop & Go Chicken", "red")],
    ("m_gr_ad5ne", "route_75_diner"): [(4.8, None, "diner", "Route 75 Diner", "teal")],
    ("m_gr_ad5ne", "bayside_express_wash"): [(-10.5, [-12.8, -7.4], "wash_office", "Bayside Express Wash", "sea")],
}


def main():
    blds = json.load(open(os.path.join(IN, "strip_buildings.json")))["buildings"]
    rc = json.load(open(os.path.join(IN, "room_contracts_strip.json")))["models"]
    rooms = []; missing = []
    for b in blds:
        key = (b["piece"], b["label"])
        if key not in SHOPS:
            missing.append(key); continue
        c = rc[b["model"]]
        fl = c["floors"][0]
        for k, (along, bay, kind, name, style) in enumerate(SHOPS[key]):
            ent = min([e for e in c["entrances"] if e["facade"] == "front" and e["floor"] == 0], key=lambda e: abs(e["along"] - along))
            bx = bay if bay is not None else [fl["box_min"][0], fl["box_max"][0]]
            # the shop's boards: every front board over its bay; a building with one shop also takes its side boards
            signs = [{"facade": s["facade"], "along": s["along"], "w": s["w"]} for s in c.get("signs", [])
                     if (s["facade"] == "front" and bx[0] - 0.3 <= s["along"] <= bx[1] + 0.3) or (len(SHOPS[key]) == 1 and s["facade"] != "back")]
            rid = "%s__%s__%d" % (b["piece"], b["label"], k)
            rooms.append({"id": rid, "piece": b["piece"], "label": b["label"], "model": b["model"], "pos": b["pos"], "yaw": b["yaw"],
                          "door_index": k, "door_along": ent["along"], "door_w": ent["w"], "bay": bx, "kind": kind, "name": name,
                          "style": style, "signs": signs, "source": "strip growth (hand-made shop list)", "built": ""})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(rooms), "rooms": rooms}, open(os.path.join(IN, "assignment_strip.json"), "w"), indent=1)
    print("ASSIGN strip rooms=%d" % len(rooms))
    for m in missing: print("  no shop listed for", m)


if __name__ == "__main__":
    main()
