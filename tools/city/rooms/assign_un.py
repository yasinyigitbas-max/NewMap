"""Which shop is behind every shop door of the CITY-CENTRE FILL (claude/fill-city-centre, 19 Nov; Yasin via the
session that started this one: "use the indoor generator in the pilot and do them both together"). A copy of
assign_strip.py. Hand-made: each building's businesses are chosen as part of its block's design (the piece script's
header says why); this table names them, splits rows into bays at their doors, and claims the sign boards. No real
brands.

Reads  map_dc/coronado/city_kit/interiors/un_buildings.json, room_contracts_un.json (room_contracts_cc.gd)
Writes map_dc/coronado/city_kit/interiors/assignment_un.json (read by tools/city/rooms/room_gen_cc.gd). The shared
       assignment_all.json is not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_cc.py
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")

# (piece, building label) -> list of shops: (door along of the shop's main entrance, bay [x0, x1] in the model frame or
# None = the whole floor, kind of room_gen_strip.KINDS, shop name, sign style)
SHOPS = {
    # ---- campus NE quarter (n_un_ne): the front of the university, by the bus station
    ("n_un_ne", "uni_hall"): [(None, None, "campus_hall", "Coronado University - Founders Hall", "navy")],
    ("n_un_ne", "uni_library"): [(0.0, None, "books", "University Library", "navy")],
    ("n_un_ne", "uni_lecture_west"): [(0.0, None, "lecture", "Lecture Halls West", "navy")],
    ("n_un_ne", "uni_science"): [(0.0, None, "lecture", "Science Building", "teal")],
    ("n_un_ne", "uni_gate_cafe"): [(2.5, None, "cafe", "Gate Coffee", "teal")],
    ("n_un_ne", "uni_gate_books"): [(-2.0, None, "books", "Campus Books", "green")],
    ("n_un_ne", "uni_bus_kiosk"): [(None, None, "souvenir", "Bus Tickets & Snacks", "sun")],
}
# not walk-in (no room): the coffee kiosk (a walk-up window), the garage, every flat (homes are not entered in this pass)


def main():
    blds = json.load(open(os.path.join(IN, "un_buildings.json")))["buildings"]
    rc = json.load(open(os.path.join(IN, "room_contracts_un.json")))["models"]
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
            ent = fronts[0] if along is None else min(fronts, key=lambda e: abs(e["along"] - along))
            bx = bay if bay is not None else [fl["box_min"][0], fl["box_max"][0]]
            # the shop's boards: every front board over its bay; a building with one shop also takes its side boards
            signs = [{"facade": s["facade"], "along": s["along"], "w": s["w"]} for s in c.get("signs", [])
                     if (s["facade"] == "front" and bx[0] - 0.3 <= s["along"] <= bx[1] + 0.3) or (len(SHOPS[key]) == 1 and s["facade"] != "back")]
            rid = "un_%s__%s__%d" % (b["piece"][5:], b["label"], k)
            rooms.append({"id": rid, "piece": b["piece"], "label": b["label"], "model": b["model"], "pos": b["pos"], "yaw": b["yaw"],
                          "door_index": k, "door_along": ent["along"], "door_w": ent["w"], "bay": bx, "kind": kind, "name": name,
                          "style": style, "signs": signs, "source": "university campus (hand-made room list)", "built": ""})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(rooms), "rooms": rooms}, open(os.path.join(IN, "assignment_un.json"), "w"), indent=1)
    print("ASSIGN cc rooms=%d" % len(rooms))
    for m in missing: print("  no shop listed for", m)


if __name__ == "__main__":
    main()
