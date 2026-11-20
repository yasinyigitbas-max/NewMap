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
    ("n_w_i1", "boatworks"): [(None, None, "workshop", "Coronado Boatworks", "navy")],
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
    for m in missing: print("  no shop listed for", m)


if __name__ == "__main__":
    main()
