"""The walk-in places of the industrial growth blocks (18 Nov, claude/grow-industrial; Yasin: "do out and indoors
together ... i want the shops to look different"). Every building in the six variant blocks that has a public door is
listed here by hand, with the place's kind, name, sign style and the reason it is there; the kinds are the industrial
ones of room_gen_ind.gd (bare, worn, functional, strip lights, steel shelving).

The bay of each door and the sign boards it claims come from the shared rules (assign_all.py bays(): the facade split
halfway between doors, never through an opening; front boards inside the bay, side boards at its ends), so a room
here fits its building the way every other room of the map does. Buildings without a public door (warehouses,
sheds, garages, the car wash, the kiosks) have no room: they are workplaces seen from the yard.

Reads interiors/buildings_ind.json (tools/city/rooms/list_buildings_ind.gd) and room_contracts.json;
writes interiors/assignment_ind.json.   python3 -I tools/city/rooms/assign_ind.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import assign_all as AA      # bays() only; its own main() does not run on import

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")

# (piece, building label, door along) -> kind, name, sign style, why; "extra" = more boards of the building to name
ROOMS = [
    ("i_va_w800_n1600_sw", "hfs_office", 4.9, "freight_office", "Harbor Freight Station", "navy",
     "drivers check in and brokers clear the boxes: the freight station's public counter on the boulevard"),
    ("i_va_w800_n1600_sw", "bayside_chandlery", -3.0, "trade_counter", "Bayside Chandlery", "green",
     "rope, paint, shackles and engine oil for the boats across 1st St"),
    ("i_va_w800_n1600_sw", "reefer_repair", -6.5, "parts_counter", "Cold Line Reefer Service", "teal",
     "the repair shop's parts counter on J Ave; the bays stay a service yard"),
    ("i_vb_w800_n1600_se", "public_works_office", 1.9, "permits", "Public Works Permits", "navy",
     "the city yard's civic face: the permits and complaints counter (the row's other two fronts are its offices)"),
    ("i_vb_w800_n1600_se", "workwear_store", 1.2, "workwear", "Harbor Workwear", "orange",
     "boots, hi-vis and gloves for the crews and the district's trades, by the bus stop"),
    ("i_vc_w600_n1600_sw", "dockside_fish_market", 4.8, "fish_counter", "Dockside Fish Market", "teal",
     "the catch landed across the road, sold over the counter and fried for the district's lunch"),
    ("i_vc_w600_n1600_sw", "pacific_seafood_sales", 1.8, "sales_office", "Pacific Seafood Co.", "navy",
     "the wholesaler's sales office: restaurants and markets place their orders here"),
    ("i_va_w600_n1600_se", "bay_boatworks_office", 0.0, "broker", "Bay Boatworks", "navy",
     "the boatyard's office and yacht broker: storage contracts, haul-outs, boats for sale"),
    ("i_va_w600_n1600_se", "marine_engines", -6.5, "parts_counter", "Tidewater Marine Engines", "green",
     "outboard and diesel parts over the counter; the bays work on the yard's boats"),
    ("i_vb_w600_n1400_nw", "truck_stop_diner", -4.8, "diner", "3rd St Truck Stop", "red",
     "the drivers' diner on the truck route: breakfast at 4 am, coffee all day"),
    ("i_vb_w600_n1400_nw", "truck_parts", -3.0, "trade_counter", "Bayline Truck Parts", "orange",
     "filters, belts and lights for the trucks serviced next door"),
    ("i_vc_w600_n1400_ne", "shift_canteen", -1.08, "canteen", "Shift Canteen", "cream",
     "the food wholesale block's canteen, open to the truck services across G Ave (both doors are its own)"),
    ("i_vc_w600_n1400_ne", "island_restaurant_supply", 3.0, "trade_counter", "Island Restaurant Supply", "green",
     "cash and carry for the island's kitchens: pans, gloves, boxes, dry goods"),
    ("i_vc_w600_n1400_ne", "island_restaurant_supply", -3.0, "uniform", "Shift Linen & Uniforms", "teal",
     "aprons, chef whites and shop towels washed and handed back over the counter"),
]
FULL = {("i_vc_w600_n1400_ne", "shift_canteen"), ("i_vb_w800_n1600_se", "workwear_store"), ("i_vb_w600_n1400_nw", "truck_stop_diner")}      # one place behind both of the building's shop doors
# the repair shops' counters take the office end only; the rollup bays stay a service yard behind a partition
BAY = {("i_va_w800_n1600_sw", "reefer_repair"): [-8.7, -2.6], ("i_va_w600_n1600_se", "marine_engines"): [-8.7, -2.6]}


def main():
    rc = json.load(open(os.path.join(IN, "room_contracts.json")))["models"]
    blds = {(b["piece"], b["label"]): b for b in json.load(open(os.path.join(IN, "buildings_ind.json")))["buildings"]}
    out = []
    for piece, label, along, kind, name, style, why in ROOMS:
        b = blds[(piece, label)]
        c = rc[b["kit"]]
        fl = c["floors"][0]
        bb = AA.bays(c)
        hit = [x for x in bb if abs(float(x[1]["along"]) - along) < 0.3]
        if not hit:
            raise SystemExit("no door at %.2f in %s (%s)" % (along, label, b["kit"]))
        i, e, a, z = hit[0]
        if (piece, label) in FULL:
            a, z = float(fl["box_min"][0]), float(fl["box_max"][0])
        if (piece, label) in BAY:
            a, z = BAY[(piece, label)]
        boards = []
        for sg in c.get("signs", []):
            if sg["facade"] == "front" and a - 0.05 <= sg["along"] <= z + 0.05:
                boards.append(sg)
            elif sg["facade"] == "left" and a <= float(fl["box_min"][0]) + 0.05:
                boards.append(sg)
            elif sg["facade"] == "right" and z >= float(fl["box_max"][0]) - 0.05:
                boards.append(sg)
        rid = "ind_%s__%s__%d" % (piece[2:], label, i)
        out.append({"id": rid, "piece": piece, "label": label, "model": b["kit"], "pos": b["pos"], "yaw": b["yaw"],
                    "door_index": i, "door_along": e["along"], "door_w": e["w"], "bay": [round(a, 3), round(z, 3)],
                    "kind": kind, "name": name, "style": style, "why": why, "source": "industrial growth", "built": "",
                    "signs": [{"facade": s["facade"], "along": s["along"], "w": s["w"]} for s in boards]})
    json.dump({"_doc": __doc__.strip().split("\n")[0] + " -> rooms g_<id> by tools/city/rooms/room_gen_ind.gd", "rooms": out},
              open(os.path.join(IN, "assignment_ind.json"), "w"), indent=1)
    for r in out:
        print("%-48s %-15s bay %s signs %d  %s" % (r["id"], r["kind"], r["bay"], len(r["signs"]), r["name"]))


if __name__ == "__main__":
    main()
