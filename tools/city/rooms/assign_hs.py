"""High street fill (claude/fill-high-street, 19 Nov): which business is behind which door of the new high street
blocks. A hand list, one line per walk-in place, with the reason; the bay split comes from the building's contract
(room_contracts.json, the same rule as every other shop of the map: assign_all.bays). Writes
interiors/assignment_hs.json in assignment_all.json's format, for tools/city/rooms/room_gen_hs.gd (a copy of the pilot's
room_gen.gd that reads this file). The shared assignment_all.json is not touched.
Run from the repo root: python3 -I tools/city/rooms/assign_hs.py
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from assign_all import bays

PAD = 4.0   # the pieces' layout row height (grid frame); building positions below are piece-local

# piece, label, model, local pos, yaw, door index, kind, name, sign style, why
SHOPS = [
    ("n_hs_b1_amber", "brick_row", "urban/urb_brick_row", (-23.0, 0.15, 106.88), 90.0, 0, "pharmacy", "Amber Drug", "green",
     "block 1: a high street needs its chemist; next to the hotel, where visitors ask for one"),
    ("n_hs_b1_amber", "brick_row", "urban/urb_brick_row", (-23.0, 0.15, 106.88), 90.0, 1, "restaurant", "Amber Deli", "cream",
     "block 1: lunch for the shops' staff and the library's readers; its green dumpster is behind it on the rear lot"),
    ("n_hs_b1_amber", "brick_row", "urban/urb_brick_row", (-23.0, 0.15, 106.88), 90.0, 2, "shoes", "Sole Coronado", "navy",
     "block 1: the paseo from the garage passes its door"),
    ("n_hs_b1_amber", "library", "civic/civ_library", (-30.0, 0.15, 131.31), 90.0, 0, "library", "Coronado Public Library", "",
     "block 1's landmark: the town library on its main street; the painted PUBLIC LIBRARY sign stays"),
    ("n_hs_b1_amber", "orange_row", "commercial/com_orange_row", (-23.0, 0.15, 153.48), 90.0, 0, "souvenir", "Ferry Landing Gifts", "sun",
     "block 1: visitors walking from the hotel to the beach road"),
    ("n_hs_b1_amber", "orange_row", "commercial/com_orange_row", (-23.0, 0.15, 153.48), 90.0, 1, "clothes", "Tide Threads", "teal",
     "block 1: a boutique in the shop row (its blue dumpster for boxes behind)"),
    ("n_hs_b1_amber", "orange_row", "commercial/com_orange_row", (-23.0, 0.15, 153.48), 90.0, 2, "jewelry", "Coral & Pearl", "navy",
     "block 1: the shop row's jeweller, next to the coffee house"),
    ("n_hs_b1_amber", "cafe", "commercial/com_cafe_seaside", (-23.0, 0.15, 166.70), 90.0, 0, "cafe", "Library Grounds Coffee", "cream",
     "block 1: coffee next to the library; newspaper boxes and pots at its door, its dumpster behind"),
    ("n_hs_b1_amber", "corner", "urban/urb_brick_corner", (-24.0, 0.15, 181.07), 90.0, 0, "sport", "South Beach Surf", "teal",
     "block 1: the corner on 11th St, the road down to the beach: boards, wetsuits, bikes"),
    ("n_hs_b1_tenth", "market", "apartments/apt_stucco3_peach", (-61.22, 0.15, 20.3), 180.0, 0, "corner_shop", "Tenth Street Market", "red",
     "block 1: the neighbourhood's market for the court's flats and the houses west; ice chest and papers on its forecourt"),
    ("n_hs_b2_amber", "stucco", "apartments/apt_stucco3_cream", (-22.6, 0.2013, -107.92), 90.0, 0, "fast_food", "Rosa's Taqueria", "red",
     "block 2: tacos at the foot of the rise for the shops' staff and the park's families, flats above it (a salon was tried: the wide, shallow room stayed bare)"),
    ("n_hs_b2_amber", "bank", "commercial/com_bank", (-23.6, 0.6124, -125.69), 90.0, 0, "bank", "Crownado Savings", "",
     "block 2: the town's savings bank (its painted CROWNADO SAVINGS sign stays)"),
    ("n_hs_b2_amber", "shops", "commercial/com_orange_corner", (-23.6, 1.7514, -158.85), 90.0, 0, "ice_cream", "Hilltop Scoops", "cream",
     "block 2: ice cream after church and for the park's families"),
    ("n_hs_b2_amber", "shops", "commercial/com_orange_corner", (-23.6, 1.7514, -158.85), 90.0, 1, "gallery", "Amber Art Co", "black",
     "block 2: a small gallery by the church walk"),
    ("n_hs_b2_amber", "hardware", "ck/ck_brk3_row2_fe", (-23.6, 2.0309, -171.4), 90.0, 0, "store", "Amber Hardware", "red",
     "block 2: every main street keeps its hardware store; the propane exchange by its door"),
    ("n_hs_b2_amber", "corner", "ck/ck_brk3_corner2", (-23.6, 2.1500, -183.5), 90.0, 0, "books", "Ninth Street Books", "green",
     "block 2: the bookshop on the 9th St corner, papers at its door"),
    ("n_hs_b2_ninth", "hall", "civic/civ_community_center", (-75.0, 2.15, -179.55), 180.0, 0, "hall", "Christ Church Community Center", "",
     "block 2: the church's hall on 9th St (office, meetings); its painted COMMUNITY CENTER sign stays"),
    ("n_hs_b3_amber", "corner", "commercial/com_orange_corner", (-23.60, 0.1496, 216.45), 90.0, 0, "corner_shop", "Beach Market", "green",
     "block 3: drinks, snacks and sun cream on the corner where 11th St meets Amber, the way to the beach"),
    ("n_hs_b3_amber", "corner", "commercial/com_orange_corner", (-23.60, 0.1496, 216.45), 90.0, 1, "salon", "Shore Cuts", "navy",
     "block 3: a barber beside the corner market (a key shop was tried: its pegboard covered the back door)"),
    ("n_hs_b3_amber", "condo", "apartments/apt_beach_condo", (-22.10, 0.0021, 233.10), 90.0, 0, "clothes", "Swim & Sun", "teal",
     "block 3: swimwear and beach clothes under the condos"),
    ("n_hs_b3_amber", "surf", "commercial/com_surf_shop", (-23.60, -0.4299, 248.25), 90.0, 0, "sport", "Coronado Surf Co.", "teal",
     "block 3: boards and wetsuits a block from the sand"),
    ("n_hs_b3_amber", "cafe", "commercial/com_cafe_seaside", (-23.60, -0.6510, 257.12), 90.0, 0, "cafe", "Beach Break Cafe", "cream",
     "block 3: coffee on the way down to the beach; its pots by the door, its dumpster behind"),
    ("n_hs_b3_amber", "realty", "commercial/com_realty", (-23.60, -0.7902, 265.14), 90.0, 0, "realty", "Ocean Realty", "navy",
     "block 3: vacation rentals and sales, listings in the window"),
    ("n_hs_b3_amber", "burger", "ck/mod_fastfood", (-22.60, -1.1370, 274.54), 90.0, 1, "fast_food", "Ocean Burger", "red",
     "block 3: the burger stand at the beach end of the high street"),
    ("n_hs_b3_motel", "condo", "apartments/apt_beach_condo", (-74.0, -1.8135, 296.8), 0.0, 0, "sport", "Beach Rentals", "sun",
     "block 3: bikes, kayaks and umbrellas for hire on Ocean Blvd; its forecourt shows them"),
    ("n_hs_b4_amber", "arcade", "commercial/com_spanish_arcade_block", (24.6, 0.161, 222.2), -90.0, 0, "books", "Arcade Books", "navy",
     "block 4: the 11th St corner under the arches, across from the library side of the street; readers sit in the shade"),
    ("n_hs_b4_amber", "arcade", "commercial/com_spanish_arcade_block", (24.6, 0.161, 222.2), -90.0, 1, "cafe", "Arches Coffee", "cream",
     "block 4: the arcade's middle shop, tables in the shade of the arches; its green dumpster behind on the rear lot"),
    ("n_hs_b4_amber", "arcade", "commercial/com_spanish_arcade_block", (24.6, 0.161, 222.2), -90.0, 2, "gallery", "Shoreline Gallery", "teal",
     "block 4: beach painters' work in the arcade, between the books and the flats"),
    ("n_hs_b4_amber", "stucco", "apartments/apt_stucco3_peach", (22.6, -0.2601, 245.32), -90.0, 0, "pharmacy", "Ocean Pharmacy", "green",
     "block 4: sun cream and plasters on the beach end of the high street (Amber Drug is up by the hotel); flats above"),
    ("n_hs_b4_amber", "pub", "commercial/com_bar_crown", (23.6, -0.6284, 261.34), -90.0, 0, "bar", "The Crown & Anchor", "red",
     "block 4: the evening after the beach; its kitchen dumpster behind on the rear lot"),
    ("n_hs_b4_amber", "cinema", "ck/ck_svc_cinema_fast", (22.6, -1.0561, 272.76), -90.0, 0, "venue", "Beach Cinema", "sun",
     "block 4: the small two-screen cinema of a beach town, its ticket hall"),
    ("n_hs_b4_amber", "cinema", "ck/ck_svc_cinema_fast", (22.6, -1.0561, 272.76), -90.0, 1, "fast_food", "Cinema Snacks", "red",
     "block 4: the cinema's snack bar (popcorn, sodas) with its own door on Amber; its recycling behind"),
    ("n_hs_b4_amber", "bakery", "commercial/com_bakery", (24.77, -1.4887, 283.91), -90.0, 0, "bakery", "Sunrise Bakery", "cream",
     "block 4: by the bus stop: coffee and pastries for those waiting and for the beach in the morning"),
    ("n_hs_b4_ocean", "skate", "public/pub_skate_shed", (128.0, -0.317, 273.5), 0.0, 0, "sport", "Ocean Park Skate", "teal",
     "block 4: the skate shop of Ocean Park: boards for sale and rent, on its own plaza; the roll-up side is its store"),
]


def main():
    rc = json.load(open(os.path.join(IN, "room_contracts.json")))["models"]
    out = []
    for piece, label, model, pos, yaw, di, kind, name, style, why in SHOPS:
        c = rc[model]
        i, e, a, b = bays(c)[di]
        boards = []
        if style:
            for sg in c.get("signs", []):
                if sg["facade"] == "front" and a - 0.05 <= sg["along"] <= b + 0.05: boards.append(sg)
                elif sg["facade"] == "left" and i == 0: boards.append(sg)
                elif sg["facade"] == "right" and b >= float(c["floors"][0]["box_max"][0]) - 0.05: boards.append(sg)
        rid = "hs_%s_%s_%d" % (piece[5:], label, i)
        out.append({"id": rid, "piece": piece, "label": label, "model": model, "pos": [pos[0], pos[1] + PAD, pos[2]], "yaw": yaw,
                    "door_index": i, "door_along": e["along"], "door_w": e["w"], "bay": [round(a, 3), round(b, 3)],
                    "kind": kind, "name": name, "style": style or "green", "font": "Overpass", "built": "", "why": why,
                    "signs": [{"facade": x["facade"], "along": x["along"], "w": x["w"]} for x in boards]})
    json.dump({"_doc": __doc__.strip().split("\n")[0], "count": len(out), "rooms": out}, open(os.path.join(IN, "assignment_hs.json"), "w"), indent=1)
    print("assignment_hs.json: %d rooms" % len(out))
    for r in out:
        print("  %-34s %-12s %-24s bay %s signs %d" % (r["id"], r["kind"], r["name"], r["bay"], len(r["signs"])))


if __name__ == "__main__":
    main()
