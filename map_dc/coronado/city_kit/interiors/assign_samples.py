"""Shop assignment for the 8 locked city-kit samples (17 Nov, interiors session).

Hand-made choices (the table below) + the generated room contracts -> assignment_samples.json and labels for the
top-view pictures. Each row: sample, piece, building label, which public door (index of the building's ground-floor
shop / civic doors, ordered along the facade), the room set (shops/interior/layouts), the shop (a key of today's
shops.json, so its name, goods and hours carry over; or a new name when no shop of that type exists) and the reason.

Rules applied (Yasin): fewer shops, spread out, 60-80 enterable citywide, a corner shop in every neighbourhood, one
of each type per district; the rest are non-enterable fronts, offices or flats. The samples get 52 rooms here so the
city that grows round them keeps room for its own corner shops and the hero sites.

Run from the repo root: python -I map_dc/coronado/city_kit/interiors/assign_samples.py
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))

# sample, piece, building label, door index, room set, shops.json key or "new:<name>|<type>", reason
T = [
    # ---- pilot high street (Amber Ave): the town's shopping street, most of today's named shops come from here
    ("pilot_high_street", "b_nw", "urb_brick_corner", 0, "cafe", "x:trident_coffee_942", "the corner cafe at the main junction: first coffee on the way to work, people watch the crossing"),
    ("pilot_high_street", "b_nw", "com_bakery", 0, "bakery", "x:villa_nueva_bakery_cafe_956", "a bakery building on the main street keeps its bakery, the Amber Ave bakery moves in"),
    ("pilot_high_street", "b_nw", "com_bar_crown", 0, "bar", "n4360771592", "the pub of the high street, mid-block, its back door on the alley for the deliveries"),
    ("pilot_high_street", "b_nw", "com_orange_row", 1, "clothes", "x:coronado_beach_wear_1111", "the middle bay of the row: clothes need the window frontage on the busiest walk"),
    ("pilot_high_street", "b_nw", "com_surf_shop", 0, "sport", "x:emerald_city_surf_shop_1118", "the surf-shop building, the real Amber Ave surf shop"),
    ("pilot_high_street", "b_ne", "lmk_village_theatre", 0, "venue", "w741656926", "the landmark theatre is the town cinema (Villager Theatre); its lobby is the room, the auditorium stays behind the auditorium door"),
    ("pilot_high_street", "b_ne", "com_spanish_arcade_block", 0, "salon", "x:crown_barber_shop_947", "a barber under the arcade, on the corner where men wait on the bench outside"),
    ("pilot_high_street", "b_ne", "com_orange_arcade_block", 1, "jewelry", "x:lumo_jewelry_co_940", "jewellery behind the arcade: shaded windows, near the theatre crowd"),
    ("pilot_high_street", "b_ne", "urb_brick_row", 0, "ice_cream", "n7606558951", "ice cream across from the theatre: after the film, families walk over"),
    ("pilot_high_street", "b_se", "civ_post_office", 0, "office", "n358860772", "the town's post office keeps its building and its forecourt with the collection boxes"),
    ("pilot_high_street", "b_se", "com_boutique_row", 1, "shoes", "x:sweet_soles_957", "shoes in the middle of the boutique row, next to the clothes customers"),
    ("pilot_high_street", "b_se", "com_boutique_row", 2, "souvenir", "x:the_bay_company_1106", "the gift shop on the end bay, closest to the hotel and the visitors"),
    ("pilot_high_street", "b_sw", "com_bistro", 0, "restaurant", "n10942435106", "the bistro with its terrace by the pocket park: the high street's one sit-down restaurant"),
    # ---- city centre: offices, the bank, a pharmacy, the cinema / fast-food row
    ("city_centre", "c_nw", "urb_brick_row", 0, "clothes", "x:paris_me_boutique_1154", "a boutique in the brick row: office workers shop at lunch"),
    ("city_centre", "c_nw", "com_cafe_seaside", 0, "cafe", "x:better_buzz_coffee_1305", "the corner cafe of the centre, at the end of the Amber frontage"),
    ("city_centre", "c_ne", "urb_brick_corner", 0, "restaurant", "x:stake_chophouse_bar_1309", "the steakhouse on the plaza corner: business lunches, after-work dinners"),
    ("city_centre", "c_se", "mod_twr_office", 0, "pharmacy", "w1388008879", "the pharmacy in the office tower's ground floor, where the people are"),
    ("city_centre", "c_sw", "com_bank", 0, "office", "w62044197", "the bank building is the bank (Shore Bank)"),
    ("city_centre", "c_sw", "ck_svc_cinema_fast", 0, "venue", "w1169419989", "the centre's small cinema faces 10th"),
    ("city_centre", "c_sw", "ck_svc_cinema_fast", 1, "fast_food", "n4576223949", "fast food next to the cinema: the queue before the film"),
    # ---- industrial: the workers' places
    ("industrial", "i_ne", "harbor_diner", 0, "restaurant", "w620973873", "the workers' diner on the corner (Clay's Diner): breakfast at 6, lunch for the whole district"),
    ("industrial", "i_ne", "truck_repair", 0, "cleaners", "w1169419952", "the repair shop's customer counter (the bays stay a non-enterable service yard)"),
    ("industrial", "i_se", "auto_parts", 0, "store", "x:coronado_hardware_140", "the trade counter sells parts and hardware to the trades around it"),
    ("industrial", "i_sw", "dive_bar", 0, "bar", "n10936222136", "the shift workers' dive bar on the corner"),
    ("industrial", "i_sw", "locksmith", 0, "keys", "w1281135763", "the locksmith keeps its plot (Crownado Lock & Key)"),
    # ---- commercial strip: car-oriented, one of each
    ("commercial_strip", "m_ne", "crown_fuel", 0, "gas", "x:shell_900", "the gas station kiosk on the corner pad"),
    ("commercial_strip", "m_ne", "burger_barn", 0, "fast_food", "w1271545004", "the drive-thru burger place also lets you walk in"),
    ("commercial_strip", "m_ne", "bank_pharmacy", 0, "office", "x:wells_fargo_829", "the bank half of the bank + pharmacy row, on the side street"),
    ("commercial_strip", "m_ne", "corner_bakery", 0, "bakery", "n10962387605", "the bakery that replaced the 5th Crown bar keeps its trade"),
    ("commercial_strip", "m_nw", "crown_plaza", 1, "salon", "x:fashion_nails_861", "a nail bar in the strip mall"),
    ("commercial_strip", "m_nw", "crown_plaza", 4, "cafe", "w1166006920", "the chain coffee in the middle of the strip mall, by the benches where people wait for rides"),
    ("commercial_strip", "m_nw", "crown_plaza", 7, "cleaners", "x:laundry_lounge_coronado_1007", "the laundromat at the far end of the mall"),
    ("commercial_strip", "m_se", "crown_grocery", 1, "grocery", "w532622710", "the big-box grocery is the supermarket; one of its four doors is the entrance (the rest stay closed: exits)"),
    ("commercial_strip", "m_se", "thrift_store", 0, "store", "n6504169566", "the thrift store on the side street"),
    ("commercial_strip", "m_se", "pho_house", 0, "restaurant", "x:swaddee_thai_1001", "the pho house becomes the Thai kitchen: the strip's restaurant"),
    # ---- apartment band: one corner shop per quarter
    ("apartment_band", "a_ne", "corner_market", 0, "corner_shop", "w62044203", "the corner market (Park Lane Liquor & Deli): milk, beer, the paper"),
    ("apartment_band", "a_nw", "laundromat", 1, "cleaners", "x:fox_cleaners_and_alterations_1015", "the laundromat on the corner: people in flats without machines"),
    ("apartment_band", "a_se", "corner_bar", 0, "bar", "n365317713", "the neighbourhood bar on its corner"),
    ("apartment_band", "a_sw", "corner_cafe", 0, "cafe", "x:heave_ho_coffee_co_1019", "the corner cafe with its tables out front"),
    # ---- civic band: the public rooms
    ("civic_band", "v_ne", "library", 0, "office", "new:Crownado Public Library|library", "the library (needs a library room: the public-room system has one; office set until then)"),
    ("civic_band", "v_ne", "city_hall", 0, "office", "new:City Hall Front Desk|town_hall", "city hall's front desk and waiting room; the offices upstairs are not enterable"),
    ("civic_band", "v_nw", "rec_center", 0, "sport", "x:sweat_circuit_coronado_1007", "the rec centre is the gym"),
    ("civic_band", "v_se", "police", 0, "office", "new:Crownado Police Front Desk|police", "the police front desk (the cells and offices behind are not enterable)"),
    # ---- gritty edge
    ("gritty_edge", "g_ne", "corner_market", 0, "grocery", "w130008070", "the corner market building is big enough for the neighbourhood's grocer"),
    ("gritty_edge", "g_ne", "brick_shops", 1, "salon", "x:island_barbers_857", "a barber in the brick row, between the dead front and the bar"),
    ("gritty_edge", "g_nw", "pawn_laundry_row", 0, "jewelry", "x:coronado_vintage_859", "the pawn shop (jewelry set: cases, a counter behind bars) - Crownado Vintage"),
    ("gritty_edge", "g_nw", "pawn_laundry_row", 1, "cleaners", "n11044502847", "the edge's one laundromat"),
    ("gritty_edge", "g_se", "pawn_chicken", 1, "fast_food", "x:crack_taco_shop_1009", "the fast-food half of the row on the corner: open late"),
    ("gritty_edge", "g_sw", "corner_liquor", 0, "corner_shop", "x:high_tide_bottle_shop_kitchen_933", "the corner liquor store under the walk-up"),
    # ---- waterfront
    ("waterfront", "f_ne", "seaside_cafe", 0, "cafe", "x:coronado_beach_coffee_828", "the seaside cafe facing the marina"),
    ("waterfront", "f_nw", "surf_shop", 0, "souvenir", "x:little_sam_s_island_beach_fun_1343", "the beach shop on the corner across from the beach: buckets, towels, sunscreen"),
    ("waterfront", "f_se", "marina_office", 0, "sport", "w338830932", "the marina office rents the paddle boards and bikes (The SUP & Saddlebag)"),
]


def main():
    rc = json.load(open(os.path.join(HERE, "room_contracts.json"), encoding="utf-8"))["models"]
    sb = json.load(open(os.path.join(HERE, "sample_buildings.json"), encoding="utf-8"))["buildings"]
    shops = {f["key"]: f for f in json.load(open(os.path.join(ROOT, "map_dc/coronado/shops/data/shops.json"), encoding="utf-8"))["fronts"]}
    lay = {}
    for f in os.listdir(os.path.join(ROOT, "map_dc/coronado/shops/interior/layouts")):
        if f.endswith(".json"):
            d = json.load(open(os.path.join(ROOT, "map_dc/coronado/shops/interior/layouts", f), encoding="utf-8"))
            lay[d["set"]] = d.get("room", {})
    by = {(b["piece"], b["label"]): b for b in sb}
    out, labels, problems, used_keys = [], [], [], set()
    per_sample = {}
    for sample, piece, label, di, rset, key, why in T:
        b = by.get((piece, label))
        if b is None:
            problems.append(f"{piece}/{label}: building not found"); continue
        c = rc[b["model"]]
        ents = sorted([e for e in c.get("entrances", []) if e["kind"] in ("shop", "civic") and e["floor"] == 0], key=lambda e: e["along"])
        if di >= len(ents):
            problems.append(f"{piece}/{label}: door {di} of {len(ents)}"); continue
        e = ents[di]
        # the same door in world coordinates
        wd = [d for d in b["doors"] if d["kind"] in ("shop", "civic") and d["floor"] == 0 and d["facade"] == e["facade"]]
        wd.sort(key=lambda d: d["local"][0] if e["facade"] in ("front", "back") else d["local"][2])
        wdoor = wd[[x["along"] for x in ents if x["facade"] == e["facade"]].index(e["along"])] if wd else None
        if rset not in e.get("fits", []):
            problems.append(f"{piece}/{label}: set {rset} does not fit the {e.get('bay_w')} x {e.get('bay_d')} bay")
        lim = lay.get(rset, {})
        room_w = min(float(lim.get("max_w", 9)), float(e.get("bay_w", 0)))
        room_d = min(float(lim.get("max_d", 10)), float(e.get("bay_d", 0)))
        if key.startswith("new:"):
            name, typ = key[4:].split("|"); shop = {"key": None, "name": name, "type": typ, "new": True}
        else:
            s = shops.get(key)
            if s is None:
                problems.append(f"{piece}/{label}: shop key {key} not in shops.json"); continue
            if key in used_keys: problems.append(f"{key} used twice")
            used_keys.add(key)
            shop = {"key": key, "name": s["name"], "type": s["type"], "goods": s.get("goods"), "opening_hours": s.get("opening_hours"), "was_on": s.get("addr_street")}
        row = {"sample": sample, "piece": piece, "building": label, "model": b["model"], "door": {"index": di, "facade": e["facade"], "along": e["along"],
               "w": e["w"], "world": wdoor["world"] if wdoor else None, "out": wdoor["out"] if wdoor else None},
               "room": {"set": rset, "w": round(room_w, 2), "d": round(room_d, 2), "bay_w": e.get("bay_w"), "bay_d": e.get("bay_d"), "floor_y_local": c["floors"][0]["y"]},
               "shop": shop, "why": why}
        out.append(row)
        per_sample[sample] = per_sample.get(sample, 0) + 1
        if wdoor:
            labels.append([f"{shop['name']} ({rset})", wdoor["world"][0], wdoor["world"][1] + 3.0, wdoor["world"][2]])
    # duplicate types per district (Yasin: one of each type per district)
    dup = {}
    for r in out:
        # public rooms on the office set until they get their own room types count by their own type
        k = (r["sample"], r["shop"]["type"] if r["shop"].get("new") else r["room"]["set"]); dup[k] = dup.get(k, 0) + 1
    for k, n in dup.items():
        if n > 1: problems.append(f"{k[0]}: {n} rooms of set {k[1]}")
    doc = {"_doc": "Enterable rooms for the 8 locked samples. Door = index of the building's ground-floor shop / civic doors ordered along the facade (room_contracts.json entrances). room w/d = the set's max size clipped to the door's bay. shop = today's shops.json entry (name, goods, hours) or a new name. Not placed in the game yet.",
           "count": len(out), "per_sample": per_sample, "rooms": out, "problems": problems,
           "not_rehomed": sorted(k for k in shops if k not in used_keys)}
    json.dump(doc, open(os.path.join(HERE, "assignment_samples.json"), "w", encoding="utf-8", newline="\n"), indent=1, ensure_ascii=False)
    json.dump(labels, open(os.path.join(HERE, "assignment_labels.json"), "w", encoding="utf-8", newline="\n"), ensure_ascii=False)
    print("rooms", len(out), per_sample)
    print("problems", problems)


main()
