"""Which shop is behind every shop door of the map (18 Nov; Yasin: "i want them on all shops" - real rooms, signs,
see-through doors). Extends the samples' hand-made assignment (interiors/assignment_samples.json, kept as it is) to
every other ground-floor shop door of the baked city.

For each door, in order along the street:
  - the kinds the building can hold (room_contracts.json "fits"), cut to what the district sells (DISTRICT below:
    the nearest sample zone gives the character: high street, centre, apartments, industrial, strip, gritty, waterfront)
    and to what fits the bay (small bays: no supermarket; a gas station only in a gas-station model);
  - the kind least seen within 150 m wins (ties: least seen in the whole city, then a fixed hash), so a street gets a
    mix and the same kind is not next door twice;
  - a name made from the kind and local words (no real brands), unique in the city.
Writes map_dc/coronado/city_kit/interiors/assignment_all.json (doors, bays, kinds, names, signs, reasons).
Run from the repo root after tools/city/rooms/list_buildings.gd:   python3 -I tools/city/rooms/assign_all.py
"""
import hashlib
import json
import math
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
IN = os.path.join(ROOT, "map_dc/coronado/city_kit/interiors")

# sample zone centres (city_grid_layout.json "sample X") and what each district sells
DISTRICTS = {
    "high_street": ((0, 0), ["cafe", "restaurant", "clothes", "shoes", "jewelry", "books", "gallery", "salon", "pharmacy", "ice_cream", "bakery", "bar", "souvenir", "office"]),
    "centre": ((0, -600), ["cafe", "restaurant", "clothes", "office", "pharmacy", "fast_food", "books", "jewelry", "bar", "salon", "shoes", "gallery", "bakery"]),
    "apartments": ((250, -600), ["corner_shop", "cafe", "cleaners", "salon", "bakery", "pharmacy", "bar", "fast_food", "grocery", "books"]),
    "civic": ((-200, -600), ["cafe", "office", "books", "pharmacy", "bakery", "gallery", "restaurant"]),
    "industrial": ((-800, -1400), ["store", "keys", "fast_food", "bar", "cleaners", "office", "restaurant"]),
    "strip": ((500, -1200), ["fast_food", "grocery", "salon", "cleaners", "store", "office", "cafe", "pharmacy", "sport", "restaurant"]),
    "gritty": ((-600, -1000), ["corner_shop", "fast_food", "bar", "cleaners", "salon", "store", "jewelry", "keys"]),
    "waterfront": ((570, 200), ["cafe", "souvenir", "restaurant", "ice_cream", "sport", "bar", "clothes"]),
}
BIG = {"grocery", "store", "sport", "venue"}                    # need a big floor
SMALL_OK = {"keys", "salon", "ice_cream", "cafe", "souvenir", "office", "jewelry", "bakery", "books", "gallery", "shoes", "corner_shop", "pharmacy", "cleaners", "bar", "fast_food", "clothes", "restaurant"}

WORDS = ["Island", "Harbor", "Bayview", "Orange", "Crown", "Pelican", "Tidewater", "Palm", "Silver Strand", "Ferry", "Marina",
         "Seabreeze", "Sandpiper", "Dune", "Ocean", "Driftwood", "Coral", "Mariner", "Pacific", "Shoreline", "Lighthouse",
         "Starfish", "Gull", "Breakwater", "Sunset", "Bluewater", "Anchor", "Compass", "Saltwater", "Lantern", "Tern",
         "Kelp", "Seaglass", "Halyard", "Buoy", "Jetty", "Cove", "Isle", "Juniper", "Bougainvillea"]
OWNERS = ["Rosa's", "Nguyen's", "Bill's", "Marta's", "Sal's", "Hank's", "Lupe's", "Ike's", "Dot's", "Tomas'", "Gina's", "Abe's",
          "Mei's", "Omar's", "June's", "Rudy's", "Vera's", "Kenji's", "Lola's", "Frank's", "Ines'", "Theo's", "Pia's", "Gus'"]
NAMES = {
    "cafe": ["{w} Coffee", "{w} Cafe", "The {w} Bean", "{o} Coffee Bar", "{w} Roasters"],
    "bakery": ["{w} Bakery", "{o} Bakery", "{w} Bread Co.", "The {w} Oven"],
    "bar": ["The {w} Tavern", "{w} Bar", "{o} Place", "The {w} Room", "{w} Taproom"],
    "restaurant": ["{w} Kitchen", "{o} Diner", "{w} Grill", "The {w} Table", "{o} Trattoria", "{w} Bistro"],
    "fast_food": ["{w} Burgers", "{o} Tacos", "{w} Fish & Chips", "{o} Pizza", "{w} Subs"],
    "ice_cream": ["{w} Creamery", "{o} Gelato", "{w} Scoops"],
    "clothes": ["{w} Outfitters", "{o} Boutique", "{w} Threads", "{w} Apparel"],
    "shoes": ["{w} Shoes", "{o} Footwear", "{w} Soles"],
    "jewelry": ["{w} Jewelers", "{o} Fine Jewelry", "{w} Pawn & Gold"],
    "books": ["{w} Books", "{o} Bookshop", "{w} Pages"],
    "gallery": ["{w} Gallery", "{o} Art House", "{w} Prints"],
    "salon": ["{w} Barbers", "{o} Hair Studio", "{w} Nails", "{o} Salon"],
    "pharmacy": ["{w} Pharmacy", "{o} Drugstore", "{w} Rx"],
    "souvenir": ["{w} Gifts", "{w} Souvenirs", "{o} Beach Shop"],
    "office": ["{w} Realty", "{w} Insurance", "{w} Travel", "{w} Credit Union", "{o} Tax Office"],
    "corner_shop": ["{w} Market", "{o} Corner Store", "{w} Deli & Liquor", "{o} Mini Mart"],
    "grocery": ["{w} Grocers", "{w} Foods", "{o} Market"],
    "cleaners": ["{w} Laundry", "{o} Cleaners", "{w} Wash & Fold"],
    "store": ["{w} Hardware", "{o} Supply", "{w} Thrift", "{w} Home & Garden"],
    "keys": ["{w} Lock & Key", "{o} Keys & Repairs"],
    "sport": ["{w} Surf & Sport", "{o} Bikes", "{w} Fitness"],
    "gas": ["{w} Fuel"],
    "venue": ["{w} Cinema", "{w} Playhouse"],
}
STYLE = {"cafe": ["sea", "cream", "green"], "bakery": ["cream", "red"], "bar": ["black", "green"], "restaurant": ["red", "black", "cream"],
         "fast_food": ["red", "sun"], "ice_cream": ["teal", "cream"], "clothes": ["navy", "black", "cream"], "shoes": ["navy", "black"],
         "jewelry": ["black"], "books": ["green", "cream"], "gallery": ["black", "cream"], "salon": ["navy", "teal"], "pharmacy": ["teal", "green"],
         "souvenir": ["sun", "sea"], "office": ["navy", "green"], "corner_shop": ["green", "red"], "grocery": ["green"], "cleaners": ["teal", "navy"],
         "store": ["red", "navy"], "keys": ["sun", "black"], "sport": ["sea", "sun"], "gas": ["red"], "venue": ["red", "black"]}
WHY = {"cafe": "coffee where people walk past", "bakery": "bread for the street in the morning", "bar": "an evening place for the block",
       "restaurant": "a sit-down meal for the district", "fast_food": "a quick bite, open late", "ice_cream": "families on a warm walk",
       "clothes": "window frontage for clothes", "shoes": "next to the clothes trade", "jewelry": "a small, secure front",
       "books": "a quiet shop between the busy ones", "gallery": "local art for visitors", "salon": "a regular trade, the same faces every week",
       "pharmacy": "the neighbourhood's medicine", "souvenir": "visitors' gifts", "office": "a service counter (bank, realty, travel)",
       "corner_shop": "milk, beer and the paper for the flats around", "grocery": "the district's food shopping", "cleaners": "people in flats without machines",
       "store": "the trades and homes around need supplies", "keys": "keys cut and repairs", "sport": "surf, bikes and gym gear",
       "gas": "the fuel station's kiosk", "venue": "a night out"}


# a street takes more than one cafe or bar, but not three ice-cream shops: near repeats of these count extra
RARE = {"ice_cream": 3, "venue": 3, "gas": 3, "gallery": 2, "jewelry": 2, "souvenir": 2, "books": 2, "shoes": 2, "pharmacy": 2,
        "grocery": 2, "keys": 2, "corner_shop": 2, "sport": 2}

# the rooms already built by hand (interiors/rooms/*.scn, locked): they stay as they are
BUILT = {("f_ne", "seaside_cafe"): "wf_cafe", ("f_nw", "surf_shop"): "wf_beach_shop", ("f_se", "marina_office"): "wf_marina_office",
         ("f_ne", "civ_harbor_office"): "wf_harbor_office", ("v_ne", "library"): "cv_library", ("v_ne", "city_hall"): "cv_city_hall",
         ("v_nw", "rec_center"): "cv_rec_center", ("v_se", "police"): "cv_police", ("a_ne", "corner_market"): "ap_corner_market",
         ("a_nw", "laundromat"): "ap_laundromat", ("a_se", "corner_bar"): "ap_corner_bar", ("a_sw", "corner_cafe"): "ap_corner_cafe"}


# what a building's own name says it is (the kit model or the piece's label): that kind first, if it fits
HINTS = [("cafe", "cafe"), ("coffee", "cafe"), ("diner", "restaurant"), ("bistro", "restaurant"), ("pho", "restaurant"), ("bakery", "bakery"),
         ("bar_", "bar"), ("pub", "bar"), ("tavern", "bar"), ("laundr", "cleaners"), ("books", "books"), ("surf", "sport"), ("bank", "office"),
         ("realty", "office"), ("pharm", "pharmacy"), ("grocery", "grocery"), ("market", "corner_shop"), ("liquor", "corner_shop"),
         ("burger", "fast_food"), ("taco", "fast_food"), ("pizza", "fast_food"), ("chicken", "fast_food"), ("pawn", "jewelry"),
         ("lock", "keys"), ("hardware", "store"), ("parts", "store"), ("thrift", "store"), ("boutique", "clothes"), ("salon", "salon"),
         ("barber", "salon"), ("gallery", "gallery"), ("cinema", "venue"), ("theatre", "venue"), ("fuel", "gas"), ("gas_station", "gas")]


def hint(label, kit):
    t = (label + " " + kit).lower()
    for w, k in HINTS:
        if w in t:
            return k
    return ""


def h(s):
    return int(hashlib.md5(s.encode()).hexdigest()[:8], 16)


def district(x, z):
    best = None
    for k, (c, _) in DISTRICTS.items():
        d = math.hypot(x - c[0], z - c[1])
        if best is None or d < best[0]:
            best = (d, k)
    return best[1]


def bays(contract):
    """bounds [x0, x1] of each ground-floor shop / civic door's bay: the facade split halfway between doors"""
    fl = contract["floors"][0]
    x0, x1 = float(fl["box_min"][0]), float(fl["box_max"][0])
    doors = sorted([e for e in contract.get("entrances", []) if e["kind"] in ("shop", "civic") and e.get("floor", 0) == 0], key=lambda e: e["along"])
    out = []
    for i, e in enumerate(doors):
        a = x0 if i == 0 else (doors[i - 1]["along"] + e["along"]) * 0.5
        b = x1 if i == len(doors) - 1 else (e["along"] + doors[i + 1]["along"]) * 0.5
        out.append((i, e, a, b))
    return out


def main():
    allb = json.load(open(os.path.join(IN, "all_buildings.json")))["buildings"]
    rc = json.load(open(os.path.join(IN, "room_contracts.json")))["models"]
    samples = json.load(open(os.path.join(IN, "assignment_samples.json")))
    sample_key = {}
    for r in samples["rooms"]:
        sample_key[(r["piece"], r["building"], r["door"]["index"])] = r
    rows = []
    for b in allb:
        c = rc[b["kit"]]
        for i, e, a, bb in bays(c):
            if e["kind"] != "shop" and (b["piece"], b["label"], i) not in sample_key:
                continue                      # civic doors: only the ones the samples made rooms for
            yaw = math.radians(b["yaw"])
            wx = b["pos"][0] + math.cos(yaw) * e["along"] + math.sin(yaw) * float(c["floors"][0]["box_max"][2])
            wz = b["pos"][2] - math.sin(yaw) * e["along"] + math.cos(yaw) * float(c["floors"][0]["box_max"][2])
            rows.append({"building": b, "door_index": i, "entrance": e, "bay": [a, bb], "world": [wx, wz]})
    rows.sort(key=lambda r: (r["world"][1], r["world"][0]))
    # a sample shop that fills its whole building (the supermarket, a burger bar): the building's other doors are its
    # side doors / exits, not more shops
    whole = {}
    for sr in samples["rooms"]:
        m = rc[sr["model"]]
        if float(sr["room"]["bay_w"]) >= 0.9 * float(m["floors"][0]["inner_wd"][0]) or "bigbox" in sr["model"]:
            whole[(sr["piece"], sr["building"])] = sr["shop"]["name"]
    kinds_of = {}
    for sr in samples["rooms"]:
        kinds_of.setdefault((sr["piece"], sr["building"]), set()).add(sr["room"]["set"])
    placed = []          # (x, z, kind): the samples' shops count as neighbours from the start
    names = set()
    count = {}
    for r in rows:
        k2 = (r["building"]["piece"], r["building"]["label"], r["door_index"])
        if k2 in sample_key:
            kk = sample_key[k2]["room"]["set"]
            placed.append((r["world"][0], r["world"][1], kk)); count[kk] = count.get(kk, 0) + 1
    out = []
    for r in rows:
        b = r["building"]; e = r["entrance"]; c = rc[b["kit"]]
        key = (b["piece"], b["label"], r["door_index"])
        bay_w = r["bay"][1] - r["bay"][0]
        depth = float(c["floors"][0]["inner_wd"][1])
        rid = "%s__%s__%d" % (b["piece"], b["label"], r["door_index"])
        if key not in sample_key and (b["piece"], b["label"]) in whole:
            continue
        if key in sample_key:
            s = sample_key[key]
            kind = s["room"]["set"]
            name = s["shop"]["name"]; why = "(sample) " + s["why"]; src = "sample"
        else:
            dist = district(*r["world"])
            fits = [k for k in e.get("fits", []) if k in DISTRICTS[dist][1]]
            small = bay_w < 5.0 or depth < 7.0
            if small:
                fits = [k for k in fits if k in SMALL_OK and k not in BIG]
            if not ("gas" in b["kit"] or "fuel" in b["kit"]):
                fits = [k for k in fits if k != "gas"]
            if not fits:
                fits = ["office"]
            same_bld = {o["kind"] for o in out if o["piece"] == b["piece"] and o["label"] == b["label"]} | kinds_of.get((b["piece"], b["label"]), set())
            hk = hint(b["label"], b["kit"])
            def score(k):
                near = sum(1 for (x, z, kk) in placed if kk == k and math.hypot(x - r["world"][0], z - r["world"][1]) < 150.0)
                # the building's own name first (first door only); never the same kind twice in one building
                return (0 if (k == hk and not same_bld) else 1, 1 if k in same_bld else 0, near * RARE.get(k, 1), count.get(k, 0), h(rid + k) % 1000)
            if hk and hk not in fits and hk in e.get("fits", []) and not same_bld:
                fits.append(hk)
            kind = min(fits, key=score)
            pat = NAMES.get(kind, ["{w} " + kind.title()])
            name = None
            for t in range(60):
                p = pat[(h(rid) + t) % len(pat)]
                n = p.format(w=WORDS[(h(rid + "w") + t * 7) % len(WORDS)], o=OWNERS[(h(rid + "o") + t * 5) % len(OWNERS)])
                if n not in names:
                    name = n; break
            why = "%s (%s)" % (WHY.get(kind, kind), dist); src = "new"
        names.add(name)
        if src == "new":
            count[kind] = count.get(kind, 0) + 1
            placed.append((r["world"][0], r["world"][1], kind))
        # the building's sign boards that belong to this bay: front boards inside it, side boards at its end
        boards = []
        for sg in c.get("signs", []):
            if sg["facade"] == "front" and r["bay"][0] - 0.05 <= sg["along"] <= r["bay"][1] + 0.05:
                boards.append(sg)
            elif sg["facade"] == "left" and r["door_index"] == 0:
                boards.append(sg)
            elif sg["facade"] == "right" and r["bay"][1] >= float(c["floors"][0]["box_max"][0]) - 0.05:
                boards.append(sg)
        style = STYLE.get(kind, ["green"])[h(rid + "s") % len(STYLE.get(kind, ["green"]))]
        out.append({"id": rid, "piece": b["piece"], "label": b["label"], "model": b["kit"], "cell": b["cell"],
                    "pos": b["pos"], "yaw": b["yaw"], "door_index": r["door_index"], "door_along": e["along"], "door_w": e["w"],
                    "bay": [round(r["bay"][0], 3), round(r["bay"][1], 3)], "kind": kind, "name": name, "style": style,
                    "why": why, "source": src, "built": BUILT.get((b["piece"], b["label"]), "") if src == "sample" else "",
                    "signs": [{"facade": s["facade"], "along": s["along"], "w": s["w"]} for s in boards]})
    have = {o["built"] for o in out}
    missing = [v for v in BUILT.values() if v not in have]
    doc = {"_doc": "Every shop door of the map with the shop behind it (tools/city/rooms/assign_all.py). source 'sample' = the "
                   "samples' hand-made choice (assignment_samples.json), 'new' = chosen by district, fit and neighbours. bay = "
                   "[x0, x1] of the room in the building's model frame. signs = the building's boards this shop claims.",
           "built_not_listed": missing,
           "count": len(out), "kinds": dict(sorted(count.items(), key=lambda kv: -kv[1])), "rooms": out}
    json.dump(doc, open(os.path.join(IN, "assignment_all.json"), "w"), indent=1)
    print("ASSIGN doors=%d new=%d sample=%d kinds=%s" % (len(out), sum(1 for o in out if o["source"] == "new"),
          sum(1 for o in out if o["source"] == "sample"), doc["kinds"]))


if __name__ == "__main__":
    main()
