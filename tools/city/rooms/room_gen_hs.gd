extends SceneTree
## HIGH STREET FILL COPY (claude/fill-high-street, 19 Nov): reads interiors/assignment_hs.json (tools/city/rooms/assign_hs.py), writes g_hs_*.scn and rooms_hs_report.json; otherwise the pilot generator unchanged.
## Rooms for every shop of the map (18 Nov; Yasin: "i want them on all shops": real windows, see-through doors, the
## shop's sign). For each shop of interiors/assignment_all.json that has no hand-made room yet, a room of its kind is
## built with the interiors' own room library (interiors/rooms/room_lib.gd: walls with the building's real openings,
## glass doors, windows, signs) and fitted to the building's measured walls, door and windows (room_contracts.json).
## The layout follows the interior-design rules of the interiors skill: the service point in view from the door, the
## first 1.5 m inside the door clear, queue space in front of the counter and staff space behind it, aisles of 1 m and
## more, a low display or seats in the window, back of house behind a partition with a staff doorway, plants, bins,
## prints, wear where people walk. Saved as interiors/rooms/g_<id>.scn (the hand-made rooms are not touched).
##   xvfb-run -a godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/rooms/room_gen.gd -- [--only=ID,ID] [--kinds=cafe,bar] [--limit=N]
## then: interiors/rooms/check_rooms.gd (0 problems), tools/city/rooms/gen_shots.gd (pictures).
## CAREFUL (19 Nov): zone sessions make their own shops' rooms with this tool; run it with --only= for your own shops.
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")
const D := "res://map_dc/coronado/city_kit/interiors/"
const MAN := "res://assets/coronado_kit/props/"

## per kind: floor texture, light (pendant / panel), the counter row, what stands behind it, the side walls' items,
## the middle of the room, the window zone, back of house (kitchen / stock / none), extras
## (hs, 19 Nov: the bakery's shelves are stocked models: the kit's bakery_shelf ships empty, check_rooms "bare")
const KINDS := {
	"cafe": {"floor": "WoodFloor034", "light": "pendant", "counter": ["pastry_case", "shop_counter"], "till": true, "behind": ["bakery_shelf", "espresso_machine"], "board": true, "walls": ["booth", "drinks_fridge"], "centre": "table2", "window": "table2", "back": "kitchen", "frames": true},
	"bakery": {"floor": "Tiles143", "light": "pendant", "counter": ["pastry_case", "shop_counter", "pastry_case"], "till": true, "behind": ["wall_shelf", "wall_shelf", "wall_shelf"], "board": true, "walls": ["grocery_shelf", "drinks_fridge"], "centre": "table2", "window": "display", "back": "kitchen", "frames": true},
	"bar": {"floor": "WoodFloor051", "light": "pendant", "counter": ["bar_counter", "bar_counter"], "stools": true, "behind": ["wine_backbar", "wine_backbar"], "board": false, "walls": ["booth"], "centre": "table4", "window": "table2", "back": "stock", "frames": true},
	"restaurant": {"floor": "WoodFloor034", "light": "pendant", "counter": ["shop_counter"], "till": true, "behind": ["wine_backbar"], "board": false, "walls": ["booth"], "centre": "table4", "window": "table2", "back": "kitchen", "frames": true},
	"fast_food": {"floor": "Tiles074", "light": "panel", "counter": ["shop_counter", "shop_counter"], "till": true, "behind": ["soda_fountain", "kitchen_line"], "board": true, "walls": ["booth"], "centre": "table4", "window": "table2", "back": "kitchen", "frames": false},
	"ice_cream": {"floor": "Tiles141", "light": "panel", "counter": ["gelato_case", "shop_counter"], "till": true, "behind": ["drinks_fridge", "wall_shelf"], "board": true, "walls": ["drinks_fridge"], "centre": "table2", "window": "table2", "back": "none", "frames": true},
	"clothes": {"floor": "WoodFloor051", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["wall_shelf", "fitting_room"], "board": false, "walls": ["garment_rail", "garment_rail", "clothes_rack"], "centre": "racks", "window": "mannequins", "back": "stock", "frames": false},
	"shoes": {"floor": "WoodFloor034", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["wall_shelf"], "board": false, "walls": ["shoe_wall"], "centre": "shoes", "window": "display", "back": "stock", "frames": false},
	"jewelry": {"floor": "Terrazzo005", "light": "panel", "counter": ["glass_display_case", "shop_counter"], "till": true, "behind": ["glass_display_case", "wall_shelf"], "board": false, "walls": ["glass_display_case", "wall_shelf"], "centre": "cases", "window": "cases", "back": "stock", "frames": true},
	"books": {"floor": "WoodFloor051", "light": "pendant", "counter": ["shop_counter"], "till": true, "behind": ["bookcase", "bookcase"], "board": false, "walls": ["bookcase"], "centre": "display", "window": "display", "back": "stock", "frames": false},
	"gallery": {"floor": "Terrazzo005", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["filing_cabinet"], "board": false, "walls": ["frames_only"], "centre": "benches", "window": "display", "back": "none", "frames": true},
	"salon": {"floor": "Tiles012", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["salon_product_shelf", "wash_basin"], "board": false, "walls": ["station"], "centre": "none", "window": "waiting", "back": "none", "frames": true},
	"pharmacy": {"floor": "Tiles012", "light": "panel", "counter": ["shop_counter", "shop_counter"], "till": true, "behind": ["pharmacy_shelf", "pharmacy_shelf", "filing_cabinet"], "board": false, "walls": ["pharmacy_shelf"], "centre": "rows", "window": "brochures", "back": "stock", "frames": false},
	"souvenir": {"floor": "Terrazzo005", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["wall_shelf", "wall_shelf"], "board": false, "walls": ["wall_shelf", "card_spinner"], "centre": "gifts", "window": "display", "back": "none", "frames": true},
	"office": {"floor": "Carpet012", "light": "panel", "counter": ["shop_counter", "shop_counter"], "till": false, "behind": ["office_desk", "filing_cabinet", "filing_cabinet"], "board": false, "walls": ["waiting_bench", "brochure_rack"], "centre": "none", "window": "waiting", "back": "office", "frames": true},
	"corner_shop": {"floor": "Tiles074", "light": "panel", "counter": ["checkout_counter"], "till": false, "behind": ["cigarette_cabinet", "wall_shelf"], "board": false, "walls": ["grocery_shelf", "drinks_fridge"], "centre": "rows", "window": "produce", "back": "stock", "frames": false},
	"grocery": {"floor": "Tiles141", "light": "panel", "counter": ["checkout_counter", "checkout_counter"], "till": false, "behind": ["wall_shelf"], "board": false, "walls": ["grocery_shelf", "drinks_fridge", "chest_freezer"], "centre": "rows", "window": "produce", "back": "stock", "frames": false},
	"cleaners": {"floor": "Tiles143", "light": "panel", "counter": ["laundry_counter"], "till": false, "behind": ["garment_rail", "garment_rail"], "board": false, "walls": ["washer", "dryer"], "centre": "none", "window": "waiting", "back": "none", "frames": false},
	"store": {"floor": "Concrete047A", "light": "panel", "counter": ["checkout_counter"], "till": false, "behind": ["pegboard_wall", "wall_shelf"], "board": false, "walls": ["wall_shelf", "pegboard_wall"], "centre": "rows", "window": "display", "back": "stock", "frames": false},
	"keys": {"floor": "Concrete047A", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["workbench", "pegboard_wall"], "board": false, "walls": ["wall_shelf"], "centre": "none", "window": "display", "back": "none", "frames": false},
	"sport": {"floor": "Concrete047A", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["wall_shelf", "wall_shelf"], "board": false, "walls": ["surfboard_rack", "clothes_rack", "bike_stand"], "centre": "racks", "window": "display", "back": "stock", "frames": false},
	"gas": {"floor": "Tiles074", "light": "panel", "counter": ["checkout_counter"], "till": false, "behind": ["cigarette_cabinet"], "board": false, "walls": ["drinks_fridge", "grocery_shelf"], "centre": "rows", "window": "none", "back": "none", "frames": false},
	# high street copy: the town library (a circulation desk, wall bookcases, book stacks back to back with reading
	# tables between them, reading tables in the windows, carpet, warm pendants)
	"library": {"floor": "Carpet012", "light": "pendant", "counter": ["shop_counter", "shop_counter"], "till": false, "behind": ["bookcase", "filing_cabinet"], "board": false, "walls": ["bookcase"], "centre": "stacks", "window": "table2", "back": "office", "frames": true},
	# high street copy: a bank hall (teller counter, officers' desks with a customer chair each, waiting benches) and a
	# community hall (reception desk, meeting tables, a kitchen behind)
	"bank": {"floor": "Terrazzo005", "light": "panel", "counter": ["shop_counter", "shop_counter", "shop_counter"], "till": false, "behind": ["filing_cabinet", "filing_cabinet"], "board": false, "walls": ["waiting_bench", "brochure_rack"], "centre": "desks", "window": "waiting", "back": "office", "frames": true},
	"hall": {"floor": "WoodFloor051", "light": "panel", "counter": ["shop_counter"], "till": false, "behind": ["filing_cabinet"], "board": false, "walls": ["waiting_bench"], "centre": "table4", "window": "table2", "back": "kitchen", "frames": true},
	# high street copy: a realty office (agents' desks each with a client chair, listings displayed in the window)
	"realty": {"floor": "Carpet012", "light": "panel", "counter": ["shop_counter"], "till": false, "behind": ["filing_cabinet", "filing_cabinet"], "board": false, "walls": ["brochure_rack"], "centre": "desks", "window": "display", "back": "office", "frames": true},
	"venue": {"floor": "Carpet012", "light": "pendant", "counter": ["shop_counter", "soda_fountain"], "till": true, "behind": ["drinks_fridge"], "board": true, "walls": ["poster_wall"], "centre": "benches", "window": "waiting", "back": "none", "frames": false},
}
const WARM := ["cafe", "bakery", "bar", "restaurant", "books", "venue", "library"]
const WALL_TINTS := [Color(1.0, 0.95, 0.86), Color(0.94, 0.96, 0.98), Color(0.98, 0.92, 0.84), Color(0.9, 0.95, 0.92), Color(1.0, 0.97, 0.93), Color(0.93, 0.9, 0.86)]
const SHORT := {"cafe": "COFFEE", "bakery": "BAKERY", "bar": "BAR", "restaurant": "KITCHEN", "fast_food": "FOOD", "ice_cream": "ICE CREAM",
	"clothes": "CLOTHES", "shoes": "SHOES", "jewelry": "JEWELRY", "books": "BOOKS", "gallery": "GALLERY", "salon": "SALON", "pharmacy": "PHARMACY",
	"souvenir": "GIFTS", "office": "OFFICE", "corner_shop": "MARKET", "grocery": "GROCERY", "cleaners": "LAUNDRY", "store": "SUPPLY", "keys": "KEYS",
	"sport": "SPORT", "gas": "FUEL", "venue": "TICKETS", "library": "LIBRARY", "bank": "BANK", "hall": "HALL", "realty": "REALTY"}

var foot := {}      # base -> Vector2(w, d)
var tall := {}      # base -> height
var occ: Array = [] # [x0, z0, x1, z1, height]
## high street copy: the indoor checker's limits (check_rooms "repeat"): no more of one thing than this in a room
const CAPS := {"brochure_rack": 2, "card_spinner": 2, "vending_snack": 1, "vending_soda": 1, "drinks_fridge": 4}
var cnt := {}
var keep: Array = [] # [x0, z0, x1, z1] floor that stays free
var X0 := 0.0; var X1 := 0.0; var ZF := 0.0; var ZB := 0.0; var ZBp := 0.0; var F := 0.0
var rr: R
var rng := RandomNumberGenerator.new()   # (hs polish, 19 Nov) one per room, seeded by its id: every shop laid out differently
var report: Array = []

func _init() -> void: _run.call_deferred()

func _man(p: String) -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (d is Dictionary): return
	for k: String in d:
		var e: Variant = d[k]
		if e is Dictionary and (e as Dictionary).has("file_base"):
			var ed: Dictionary = e
			foot[String(ed.file_base)] = Vector2(float(ed.get("footprint_w", 0.5)), float(ed.get("footprint_d", 0.5)))
			tall[String(ed.file_base)] = float(ed.get("height", 1.0))

func _h(s: String) -> int: return absi(hash(s))

func _run() -> void:
	var only := PackedStringArray(); var kinds := PackedStringArray(); var limit := 100000
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="): only = a.trim_prefix("--only=").split(",", false)
		if a.begins_with("--kinds="): kinds = a.trim_prefix("--kinds=").split(",", false)
		if a.begins_with("--limit="): limit = int(a.trim_prefix("--limit="))
	for f in DirAccess.get_files_at(MAN):
		if f.begins_with("manifest_") and f.ends_with(".json"): _man(MAN + f)
	var rc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(D + "room_contracts.json")).models
	var asg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(D + "assignment_hs.json"))
	var n := 0
	for e: Dictionary in asg.rooms:
		if String(e.built) != "": continue
		if not only.is_empty() and not only.has(String(e.id)): continue
		if not kinds.is_empty() and not kinds.has(String(e.kind)): continue
		if n >= limit: break
		await _room(e, rc[String(e.model)])
		n += 1
	var fo := FileAccess.open(D + "rooms_hs_report.json", FileAccess.WRITE)
	fo.store_string(JSON.stringify({"rooms": report}, " ")); fo.close()
	print("GEN_DONE rooms=%d" % n)
	quit()

## ------------------------------------------------------------------------------------------------ placement
func _fp(base: String, yaw: float) -> Vector2:
	var f: Vector2 = foot.get("prop_" + base, Vector2(0.5, 0.5))
	return f if absf(fmod(absf(yaw), 180.0)) < 1.0 else Vector2(f.y, f.x)

func _free(x0: float, z0: float, x1: float, z1: float, use_keep := true) -> bool:
	if x0 < X0 + 0.02 or x1 > X1 - 0.02 or z0 < ZBp + 0.02 or z1 > ZF - 0.02: return false
	for o: Array in occ:
		if x0 < float(o[2]) + 0.04 and x1 > float(o[0]) - 0.04 and z0 < float(o[3]) + 0.04 and z1 > float(o[1]) - 0.04: return false
	if use_keep:
		for k: Array in keep:
			if x0 < float(k[2]) and x1 > float(k[0]) and z0 < float(k[3]) and z1 > float(k[1]): return false
	return true

## put a prop centred at (x, z) facing yaw if its footprint is free; true when placed
func _put(base: String, x: float, z: float, yaw := 0.0, use_keep := true) -> bool:
	if CAPS.has(base) and int(cnt.get(base, 0)) >= int(CAPS[base]): return false
	var f := _fp(base, yaw)
	var x0 := x - f.x * 0.5; var x1 := x + f.x * 0.5; var z0 := z - f.y * 0.5; var z1 := z + f.y * 0.5
	if not _free(x0, z0, x1, z1, use_keep): return false
	rr.prop(base, x, z, yaw)
	occ.append([x0, z0, x1, z1, float(tall.get("prop_" + base, 1.0)), base])
	cnt[base] = int(cnt.get(base, 0)) + 1
	return true

## a group (table + chairs, booth) placed whole or not at all
func _group(items: Array, use_keep := true) -> bool:
	var rects: Array = []
	for it: Array in items:
		var f := _fp(String(it[0]), float(it[3]))
		rects.append([float(it[1]) - f.x * 0.5, float(it[2]) - f.y * 0.5, float(it[1]) + f.x * 0.5, float(it[2]) + f.y * 0.5])
	var b: Array = rects[0].duplicate()
	for q: Array in rects: b = [minf(b[0], q[0]), minf(b[1], q[1]), maxf(b[2], q[2]), maxf(b[3], q[3])]
	if not _free(b[0], b[1], b[2], b[3], use_keep): return false
	for it: Array in items: rr.prop(String(it[0]), float(it[1]), float(it[2]), float(it[3]))
	var ht := 0.0
	for it: Array in items: ht = maxf(ht, float(tall.get("prop_" + String(it[0]), 1.0)))
	occ.append([b[0], b[1], b[2], b[3], ht, String(items[0][0])])
	return true

func _table2(x: float, z: float) -> Array:
	return [["cafe_table", x, z, 0.0], ["cafe_chair", x - 0.58, z, 90.0], ["cafe_chair", x + 0.58, z, -90.0]]
func _table4(x: float, z: float) -> Array:
	return [["restaurant_table", x, z, 0.0], ["side_chair", x - 0.3, z - 0.62, 0.0], ["side_chair", x + 0.3, z - 0.62, 0.0], ["side_chair", x - 0.3, z + 0.62, 180.0], ["side_chair", x + 0.3, z + 0.62, 180.0]]

## ------------------------------------------------------------------------------------------------ mixed shop floors
## (hs polish, 19 Nov; Yasin: "most shops look like copy pasted lines of props, have variety") the middle of a shop as
## a mix of units, chosen per room from its kind's list (never the same unit twice in a row), on staggered rows with
## uneven spacing and turned differently; a unit that does not fit gives way to a plant or to nothing.
const MIX := {
	"clothes": [["rack", "rail", "mann", "dtable", "rack", "plant"], 2.1, 2.2],
	"sport": [["rack", "bike", "surf", "weights", "dtable", "rail"], 2.3, 2.3],
	"shoes": [["shoebench", "dtable", "shoebench", "case", "plant"], 2.2, 2.0],
	"books": [["books", "dtable", "reading", "books", "plant"], 2.3, 2.4],
	"souvenir": [["dtable", "spinner", "case", "dtable", "plant"], 2.2, 2.1],
	"gallery": [["bench", "plant", "case", "bench"], 2.8, 2.6],
	"jewelry": [["case", "case2", "plant", "mann"], 2.2, 2.2],
	"pharmacy": [["gondola2", "case", "gondola2", "spinner"], 1.8, 2.8],
	"corner_shop": [["gondola2", "produce", "gondola2", "freezer"], 1.9, 2.8],
	"grocery": [["gondola2", "produce", "freezer", "gondola2"], 1.9, 2.8],
	"store": [["gondola2", "dtable", "gondola2", "workbench"], 1.9, 2.8],
	"cafe": [["t2", "t2", "t4", "plant"], 2.1, 2.0],
	"bakery": [["t2", "t2", "plant"], 2.1, 2.0],
	"ice_cream": [["t2", "t2", "plant", "t2"], 2.0, 1.9],
	"restaurant": [["t4", "t2", "t4", "plant"], 2.4, 2.5],
	"bar": [["t4", "t2", "t2", "plant"], 2.4, 2.4],
	"fast_food": [["t4", "t2", "t4"], 2.3, 2.4],
	"bank": [["desk", "bench", "desk", "plant"], 2.9, 2.7],
	"realty": [["desk", "desk", "plant", "bench"], 2.9, 2.7],
	"venue": [["bench", "stanchion", "bench", "plant"], 2.6, 2.4],
	"salon": [["basin", "nail", "plant"], 2.2, 2.2],
}
const FILL := {
	"clothes": ["mannequin", "potted_plant", "display_table", "garment_rail"], "shoes": ["display_table", "potted_plant", "shoe_bench"],
	"books": ["display_table", "potted_plant", "card_spinner"], "souvenir": ["card_spinner", "display_table", "potted_plant", "glass_display_case"],
	"jewelry": ["glass_display_case", "potted_plant", "mannequin"], "pharmacy": ["card_spinner", "potted_plant", "glass_display_case"],
	"corner_shop": ["produce_stand", "chest_freezer", "potted_plant"], "grocery": ["produce_stand", "chest_freezer", "potted_plant"],
	"store": ["display_table", "potted_plant", "workbench", "gondola_aisle"], "sport": ["surfboard_rack", "bike_stand", "weight_bench", "mannequin", "clothes_rack"],
	"gallery": ["glass_display_case", "potted_plant", "stanchion"], "bank": ["potted_plant", "brochure_rack"],
	"realty": ["potted_plant", "brochure_rack"], "venue": ["stanchion", "potted_plant", "brochure_rack"], "salon": ["potted_plant", "wash_basin"],
	"cleaners": ["garment_rail", "potted_plant"], "cafe": ["potted_plant"], "bakery": ["potted_plant"], "ice_cream": ["potted_plant"],
	"restaurant": ["potted_plant"], "bar": ["potted_plant"], "fast_food": ["potted_plant"],
}
func _unit(u: String, x: float, z: float) -> Array:
	var alt := rng.randf() < 0.5
	match u:
		"rack": return [["clothes_rack", x, z, 90.0 if alt else 0.0]]
		"rail": return [["garment_rail", x, z, 0.0 if alt else 90.0]]
		"mann": return [["mannequin", x - 0.35, z, rng.randf_range(-35.0, 35.0)], ["mannequin", x + 0.35, z + 0.2, rng.randf_range(-35.0, 35.0)]]
		"dtable": return [["display_table", x, z, 90.0 if alt else 0.0]]
		"case": return [["glass_display_case", x, z, 180.0 if alt else 0.0]]
		"case2": return [["glass_display_case", x - 0.62, z, 90.0], ["glass_display_case", x + 0.62, z, -90.0]]
		"spinner": return [["card_spinner", x, z, rng.randf_range(0.0, 90.0)]]
		"gondola2": return [["gondola_aisle", x, z - 0.62, 90.0], ["gondola_aisle", x, z + 0.62, 90.0]]
		"freezer": return [["chest_freezer", x, z, 90.0]]
		"produce": return [["produce_stand", x, z, 90.0 if alt else 0.0]]
		"workbench": return [["workbench", x, z, 90.0]]
		"shoebench": return [["shoe_bench", x, z - 0.25, 180.0], ["shoe_bench", x, z + 0.25, 0.0]]
		"plant": return [["potted_plant", x + rng.randf_range(-0.3, 0.3), z, rng.randf_range(0.0, 360.0)]]
		"t2": return _table2(x, z)
		"t4": return _table4(x, z)
		"bench": return [["waiting_bench", x, z, 180.0 if alt else 0.0]]
		"bike": return [["bike_stand", x, z, 90.0 if alt else 0.0]]
		"surf": return [["surfboard_rack", x - 0.4, z, 0.0], ["surfboard_rack", x + 0.4, z, 0.0]]
		"weights": return [["weight_bench", x, z, 90.0 if alt else 0.0]]
		"books": return [["bookcase", x - 0.52, z - 0.2, 180.0], ["bookcase", x + 0.52, z - 0.2, 180.0], ["bookcase", x - 0.52, z + 0.2, 0.0], ["bookcase", x + 0.52, z + 0.2, 0.0]]
		"reading": return [["display_table", x, z, 0.0], ["side_chair", x - 0.3, z - 0.65, 0.0], ["side_chair", x + 0.3, z + 0.65, 180.0]]
		"desk": return [["office_desk", x, z, 180.0], ["office_chair", x, z - 0.66, 0.0], ["side_chair", x - 0.3, z + 0.7, 180.0], ["side_chair", x + 0.3, z + 0.7, 180.0]]
		"stanchion": return [["stanchion", x - 0.6, z, 0.0], ["stanchion", x + 0.6, z, 0.0]]
		"basin": return [["wash_basin", x, z, 180.0 if alt else 0.0]]
		"nail": return [["nail_table", x, z, 0.0], ["side_chair", x, z - 0.6, 0.0], ["side_chair", x, z + 0.6, 180.0]]
	return []

func _mix_centre(kind: String, ix0: float, ix1: float, mz0: float, mz1: float) -> bool:
	if not MIX.has(kind): return false
	var spec: Array = MIX[kind]
	var units: Array = spec[0]; var cw: float = spec[1]; var cd: float = spec[2]
	if ix1 - ix0 < cw * 0.9 or mz1 - mz0 < cd * 0.8: return true          # too small a middle: leave it open
	var prev := ""
	var spinners := 0
	var z := mz1 - cd * 0.5
	var row := 0
	while z > mz0 + cd * 0.4:
		var off := cw * 0.5 if row % 2 == 1 and ix1 - ix0 > cw * 1.6 else 0.0
		var xs: Array = _steps(ix0 + cw * 0.5 + off * 0.5, ix1 - cw * 0.5 + off * 0.5, cw * rng.randf_range(0.95, 1.15))
		for xx: float in xs:
			var u := String(units[rng.randi() % units.size()])
			var tries := 0
			while (u == prev or (u == "spinner" and spinners >= 2)) and tries < 6:
				u = String(units[rng.randi() % units.size()]); tries += 1
			var jx := rng.randf_range(-0.15, 0.15); var jz := rng.randf_range(-0.15, 0.15)
			if _group(_unit(u, xx + jx, z + jz)):
				prev = u
				if u == "spinner": spinners += 1
			elif u != "plant" and rng.randf() < 0.5:
				_group(_unit("plant", xx, z))
		z -= cd * rng.randf_range(0.95, 1.12)
		row += 1
	return true

## ------------------------------------------------------------------------------------------------ one room
func _room(e: Dictionary, c: Dictionary) -> void:
	var kind := String(e.kind)
	var K: Dictionary = KINDS.get(kind, KINDS.office)
	var id := "g_" + String(e.id)
	var fl: Dictionary = c.floors[0]
	F = float(fl.y)
	X0 = maxf(float(e.bay[0]), float(fl.box_min[0])); X1 = minf(float(e.bay[1]), float(fl.box_max[0]))
	ZF = float(fl.box_max[2])
	# the room's front wall stands 0.25 m inside the door's facade plane (as the hand-made rooms: the reveal and frame
	# fill the depth); on most shop models the measured box reaches the facade itself
	for o: Dictionary in c.openings:
		if int(o.floor) == 0 and String(o.facade) == "front" and (String(o.region) == "O_shopdoor" or String(o.region) == "O_civic_door") and absf(float(o.along) - float(e.door_along)) < 0.6:
			ZF = minf(ZF, float(o.plane) - 0.25)
			# (hs, 19 Nov) a shop door with a raised sill (pub_skate_shed: 0.2 m over the floor the contract derives from
			# its roll-up): the room's floor at the sill, so nothing of the build stands in the passage
			if String(o.region) == "O_shopdoor" and float(o.y0) - F > 0.05 and float(o.y0) - F <= 0.35: F = float(o.y0)
	var zb_bld := float(fl.box_min[2])
	ZB = maxf(zb_bld, ZF - 16.0)                         # very deep buildings: the shop takes the front 16 m
	var H := F + minf(float(fl.clear_h), 4.0)
	var depth := ZF - ZB; var width := X1 - X0
	var back := String(K.back)
	var ZP := ZB
	if depth >= 9.0 and back != "none": ZP = ZB + (2.9 if back == "kitchen" else 2.3)
	ZBp = ZP
	occ = []; keep = []; cnt = {}
	rr = R.new(id, F)
	rng.seed = _h(id + "_mix")
	rr.world_xf = Transform3D(Basis(Vector3.UP, deg_to_rad(float(e.yaw))), Vector3(float(e.pos[0]), float(e.pos[1]), float(e.pos[2])))
	var hh := _h(id)
	var tint: Color = WALL_TINTS[hh % WALL_TINTS.size()]
	rr.mat("wall", "PaintedPlaster017", 2.0, tint)
	var warm := kind in WARM
	rr.mat("ceil", "Plaster001" if warm else "OfficeCeiling002", 2.0 if warm else 1.2, Color(0.95, 0.94, 0.92))
	rr.mat("floor", String(K.floor), 2.0)
	rr.mat("kfloor", "Tiles143", 1.0)
	rr.mat("door", "Wood058", 1.0, Color(0.55, 0.42, 0.3))
	rr.plain("skirt", Color(0.16, 0.14, 0.12), 0.5)
	rr.plain("glass", Color(0.78, 0.86, 0.92), 0.1, 1.1)
	rr.plain("frame", Color(0.12, 0.12, 0.13), 0.4)
	rr.plain("pendant_shade", Color(0.08, 0.09, 0.08), 0.35)
	rr.plain("pendant_cord", Color(0.05, 0.05, 0.05), 0.5)
	rr.plain("bulb", Color(1.0, 0.85, 0.6), 0.3, 6.0)
	rr.plain("light_panel", Color(1.0, 0.97, 0.9), 0.3, 3.5)
	# shell: floor, ceiling, the four walls with the building's real openings (outer walls only), the partition
	rr.flat("floor", X0, ZP, X1, ZF, F)
	if ZP > ZB + 0.01: rr.flat("kfloor", X0, ZB, X1, ZP, F)
	rr.flat("ceil", X0, ZB, X1, ZF, H, false)
	var outer := {"front": true, "back": ZB <= zb_bld + 0.01, "left": X0 <= float(fl.box_min[0]) + 0.01, "right": X1 >= float(fl.box_max[0]) - 0.01}
	# the walls with every opening of the building inside the room (room_lib.walls4, with a bounds 0.15 m wider at the
	# building's outer walls: some kit openings run a few cm past the measured box at the corners and were left shut)
	var bnd := [X0 - (0.15 if bool(outer.left) else 0.0), ZB - (0.15 if bool(outer.back) else 0.0), X1 + (0.15 if bool(outer.right) else 0.0), ZF + 0.4]
	var holes: Dictionary = rr.openings(c, {"front": ZF, "back": ZB, "left": X0, "right": X1}, bnd, outer)
	rr.wall("wall", "z", ZF, X0, X1, F, H, -1.0, holes.front)
	rr.wall("wall", "z", ZB, X0, X1, F, H, 1.0, holes.back)
	rr.wall("wall", "x", X0, ZB, ZF, F, H, 1.0, holes.left)
	rr.wall("wall", "x", X1, ZB, ZF, F, H, -1.0, holes.right)
	var dx := float(e.door_along); var dw := float(e.door_w)
	var staff_x := X1 - 0.75 if dx < (X0 + X1) * 0.5 else X0 + 0.75      # the staff end: away from the door side
	if ZP > ZB + 0.01:
		var s0 := staff_x - 0.45; var s1 := staff_x + 0.45
		if s0 - X0 > 0.05: rr.box("wall", Vector3((X0 + s0) * 0.5, (F + H) * 0.5, ZP), Vector3(s0 - X0, H - F, 0.12))
		if X1 - s1 > 0.05: rr.box("wall", Vector3((s1 + X1) * 0.5, (F + H) * 0.5, ZP), Vector3(X1 - s1, H - F, 0.12))
		rr.box("wall", Vector3(staff_x, (F + 2.2 + H) * 0.5, ZP), Vector3(0.9, H - F - 2.2, 0.12))
	# kept free: the door swing and the step in, and the straight walk from the door to the counter
	keep.append([dx - dw * 0.5 - 0.2, ZF - 1.6, dx + dw * 0.5 + 0.2, ZF])
	# ---- the counter: across the back of the shop, its staff end away from the door, staff space behind it
	var row: Array = K.counter
	var cw := 0.0; var cd := 0.0
	for p: String in row: cw += _fp(p, 0.0).x; cd = maxf(cd, _fp(p, 0.0).y)
	cw = minf(cw, width - 1.0)
	var pub_d := ZF - ZBp
	var walk := 0.95 if pub_d > 6.5 else 0.8
	var behind_d := 0.45
	var zc := ZBp + behind_d + walk + cd * 0.5
	var cx := clampf((X0 + X1) * 0.5 + (0.45 if staff_x < dx else -0.45), X0 + cw * 0.5 + 0.95, X1 - cw * 0.5 - 0.95) if width > cw + 1.9 else (X0 + X1) * 0.5
	if staff_x < cx: cx = maxf(cx, X0 + 0.95 + cw * 0.5)
	var x := cx - cw * 0.5
	var placed_counter: Array = []
	for p: String in row:
		var w := _fp(p, 0.0).x
		if x + w > cx + cw * 0.5 + 0.01: break
		if _put(p, x + w * 0.5, zc, 0.0, false): placed_counter.append([p, x + w * 0.5])
		x += w
	for pc: Array in placed_counter:
		if String(pc[0]) == "shop_counter" and bool(K.get("till", false)): rr.prop("cash_register", float(pc[1]) - 0.3, zc - 0.05, 180.0, 0.964); break
	if bool(K.get("stools", false)):
		for pc: Array in placed_counter:
			for k in 3: _put("bar_stool", float(pc[1]) - 0.7 + k * 0.7, zc + cd * 0.5 + 0.35, 180.0, false)
	# the queue in front of the counter, the staff walk behind it
	keep.append([cx - cw * 0.5, zc + cd * 0.5, cx + cw * 0.5, zc + cd * 0.5 + 1.2])
	keep.append([X0, ZBp + behind_d, X1, zc - cd * 0.5])
	keep.append([dx - 0.5, zc + cd * 0.5, dx + 0.5, ZF])
	# behind the counter, against the back wall / partition (the staff doorway kept free)
	keep.append([staff_x - 0.5, ZBp, staff_x + 0.5, ZBp + 1.0])
	var bx := cx - cw * 0.5
	var low_x := -999.0
	for p: String in K.behind:
		var f := _fp(p, 0.0)
		while bx + f.x <= cx + cw * 0.5 + 0.01:
			if _put(p, bx + f.x * 0.5, ZBp + f.y * 0.5 + 0.09, 0.0):
				if float(tall.get("prop_" + p, 2.0)) < 1.5: low_x = bx + f.x * 0.5
				bx += f.x + 0.05; break
			bx += 0.25
	if bool(K.get("board", false)):
		var mx := low_x if low_x > -900.0 else cx
		var free_board := true
		for o: Array in occ:
			if float(o[4]) > 1.7 and mx > float(o[0]) - 0.85 and mx < float(o[2]) + 0.85 and float(o[1]) < ZBp + 0.6: free_board = false
		if free_board: rr.prop("menu_board", mx, ZBp + 0.06, 0.0, 1.75)
	# ---- the side walls: the shop's goods / seats along them (low things only under the side windows)
	var sidewin := _side_windows(c)
	for side: Array in [[X0, 90.0, "left"], [X1, -90.0, "right"]]:
		var wx := float(side[0]); var yaw := float(side[1]); var inn := 1.0 if yaw > 0.0 else -1.0
		var items: Array = K.walls
		var z := ZF - 0.45; var k := rng.randi() % maxi(1, (K.walls as Array).size())
		var brk := 2 + rng.randi() % 3
		var tries := 0; var run := 0; var stations := 0
		while z > ZBp + 0.4 and tries < 60:
			tries += 1
			# no endless runs of one thing: after three a break (a plant in the gap), and a barber has three chairs a side
			if run >= brk:
				brk = 2 + rng.randi() % 3
				run = 0
				var acc := "side_chair" if rng.randf() < 0.35 and not kind in ["library", "hall", "venue"] else "potted_plant"
				if _put(acc, wx + inn * 0.32, z - 0.28, yaw): z -= 0.65
				else: z -= 0.3
				continue
			var it := String(items[k % items.size()])
			if it == "station" and stations >= 3: break
			if it == "frames_only" or it == "poster_wall": break
			if it == "booth":
				# as the waterfront cafe's booths: the table's long side out from the wall, a bench on each side of it
				var bxw := wx + inn * 0.72; var zt := z - 1.05
				if _group([["restaurant_table", bxw, zt, 0.0], ["booth_bench", bxw, zt + 0.73, 180.0], ["booth_bench", bxw, zt - 0.73, 0.0]]):
					z -= 2.25; k += 1; run += 1; continue
				z -= 0.3; continue
			if it == "station":
				var sx := wx + inn * 0.24
				if _put("mirror_station", sx, z - 0.6, yaw) and _put("barber_chair", wx + inn * 1.05, z - 0.6, yaw + 180.0):
					z -= 1.45; stations += 1; run += 1; continue
				z -= 0.3; continue
			var f := _fp(it, yaw)
			var ht := float(tall.get("prop_" + it, 1.0))
			if _under_window(sidewin, String(side[2]), z - f.y, z, ht):
				z -= 0.3; continue
			if _put(it, wx + inn * (f.x * 0.5 + 0.02), z - f.y * 0.5, yaw): z -= f.y + 0.06; k += 1; run += 1
			else: z -= 0.3
	# how far the side walls' goods reach into the room: the middle keeps a 1 m aisle clear of them
	var sl := X0; var sr := X1
	for o: Array in occ:
		if float(o[0]) <= X0 + 0.1 and float(o[1]) > zc + cd * 0.5: sl = maxf(sl, float(o[2]))
		if float(o[2]) >= X1 - 0.1 and float(o[1]) > zc + cd * 0.5: sr = minf(sr, float(o[0]))
	var IX0 := sl + 1.05; var IX1 := sr - 1.05
	# ---- the window: a low display or seats behind the glass, nothing tall
	var wz := ZF - 0.4
	match String(K.window):
		"table2":
			for xx: float in _steps(X0 + 1.0, X1 - 1.0, 2.7): _group(_table2(xx, wz - 0.45))
		"display":
			var wi := rng.randi() % 3
			for xx: float in _steps(X0 + 1.9, X1 - 1.9, 2.0 + rng.randf() * 0.5):      # (clear of the side walls' goods)
				var wu: String = (["display_table", "potted_plant", "glass_display_case"][wi % 3] if kind != "books" else ["display_table", "potted_plant"][wi % 2])
				if not _put(wu, xx, wz - 0.45, 0.0 if wu != "glass_display_case" else 180.0): _put("potted_plant", xx, wz - 0.3, 0.0)
				wi += 1 + rng.randi() % 2
		"mannequins":
			var mi := 0
			for xx: float in _steps(X0 + 0.7, X1 - 0.7, 1.35 + rng.randf() * 0.4):
				if mi % 3 == 2: _put("display_table", xx, wz - 0.45, 90.0)
				else: _put("mannequin", xx + rng.randf_range(-0.12, 0.12), wz - 0.35, rng.randf_range(-30.0, 30.0))
				mi += 1
		"cases":
			for xx: float in _steps(X0 + 0.9, X1 - 0.9, 2.0): _put("glass_display_case", xx, wz - 0.35, 180.0)
		"waiting":
			for xx: float in _steps(X0 + 1.0, X1 - 1.0, 2.4): _put("waiting_bench", xx, wz - 0.32, 180.0)
		"produce":
			for xx: float in _steps(X0 + 1.0, X1 - 1.0, 2.3): _put("produce_stand", xx, wz - 0.4, 0.0)
		"brochures":
			for xx: float in _steps(X0 + 0.6, X1 - 0.6, 2.0): _put("brochure_rack", xx, wz - 0.3, 180.0)
	# ---- the middle of the shop
	var mz0 := zc + cd * 0.5 + 1.3; var mz1 := ZF - (1.6 if String(K.window) == "none" else 2.4)      # a walkway between the middle and the window display
	var mixed := _mix_centre(kind, IX0, IX1, mz0, mz1)
	match ("_mixed" if mixed else String(K.centre)):
		"table2":
			for zz: float in _steps(mz0 + 0.5, mz1 - 0.5, 1.8):
				for xx: float in _steps(IX0 + 0.95, IX1 - 0.95, 2.1): _group(_table2(xx, zz))
		"table4":
			for zz: float in _steps(mz0 + 0.8, mz1 - 0.8, 2.5):
				for xx: float in _steps(IX0 + 0.65, IX1 - 0.65, 2.3): _group(_table4(xx, zz))
		"desks":
			for zz: float in _steps(mz0 + 1.0, mz1 - 1.0, 2.6):
				for xx: float in _steps(IX0 + 1.0, IX1 - 1.0, 2.8):
					_group([["office_desk", xx, zz, 180.0], ["office_chair", xx, zz - 0.66, 0.0], ["side_chair", xx, zz + 0.7, 180.0]])
		"stacks":
			var ri := 0
			for zz: float in _steps(mz0 + 0.8, mz1 - 0.8, 2.6):
				for xx: float in _steps(IX0 + 0.8, IX1 - 0.8, 2.3):
					if ri % 2 == 0:
						_group([["bookcase", xx - 0.52, zz - 0.18, 180.0], ["bookcase", xx + 0.52, zz - 0.18, 180.0], ["bookcase", xx - 0.52, zz + 0.18, 0.0], ["bookcase", xx + 0.52, zz + 0.18, 0.0]])
					else:
						_group(_table4(xx, zz))
				ri += 1
		"rows":
			for xx: float in _steps(IX0 + 0.27, IX1 - 0.27, 1.65):
				var zz := mz1 - 0.65
				while zz - 0.61 > mz0:
					if not _put("gondola_aisle", xx, zz, 90.0): pass
					zz -= 1.24
		"racks":
			for xx: float in _steps(IX0 + 0.24, IX1 - 0.24, 1.7):
				for zz: float in _steps(mz0 + 0.8, mz1 - 0.8, 1.9): _put("clothes_rack", xx, zz, 90.0)
		"display":
			for zz: float in _steps(mz0 + 0.5, mz1 - 0.5, 2.0):
				for xx: float in _steps(IX0 + 0.68, IX1 - 0.68, 2.5): _put("display_table", xx, zz, 0.0)
		"shoes":
			for zz: float in _steps(mz0 + 0.4, mz1 - 0.4, 1.8):
				for xx: float in _steps(IX0 + 0.55, IX1 - 0.55, 2.3): _put("shoe_bench", xx, zz, 0.0)
		"cases":
			for zz: float in _steps(mz0 + 0.4, mz1 - 0.4, 1.8):
				for xx: float in _steps(IX0 + 0.62, IX1 - 0.62, 2.3): _put("glass_display_case", xx, zz, 0.0)
		"gifts":
			for zz: float in _steps(mz0 + 0.5, mz1 - 0.5, 1.9):
				var t := 0
				for xx: float in _steps(IX0 + 0.68, IX1 - 0.68, 2.2):
					_put("display_table" if t % 2 == 0 else "card_spinner", xx, zz, 0.0); t += 1
		"benches":
			for zz: float in _steps(mz0 + 0.4, mz1 - 0.4, 2.4):
				for xx: float in _steps(IX0 + 0.74, IX1 - 0.74, 2.6): _put("waiting_bench", xx, zz, 0.0)
	# ---- (hs polish) fill: the shop's own small things in the free floor left, scattered (never the door path, the
	# queue or the aisles the layouts keep), so no shop stands half empty
	if FILL.has(kind):
		var fl_items: Array = FILL[kind]
		var nsp := 0; var nbr := 0
		for o: Array in occ:
			if String(o[5]) == "card_spinner": nsp += 1
			if String(o[5]) == "brochure_rack": nbr += 1
		var fz := mz1 - 0.5
		while fz > zc + cd * 0.5 + 1.0:
			for fx: float in _steps(X0 + 0.7 + rng.randf() * 0.3, X1 - 0.7, 1.25):
				if rng.randf() > 0.8: continue
				var fi := String(fl_items[rng.randi() % fl_items.size()])
				if (fi == "card_spinner" and nsp >= 2) or (fi == "brochure_rack" and nbr >= 2): fi = "potted_plant"
				var fyaw := float(rng.randi() % 4) * 90.0                      # bulky things square to the room
				if fi in ["potted_plant", "card_spinner", "mannequin"]: fyaw = rng.randf_range(0.0, 360.0)
				var fxx := fx + rng.randf_range(-0.2, 0.2)
				var ff := _fp(fi, fyaw)
				if fxx - ff.x * 0.5 < sl + 0.7 or fxx + ff.x * 0.5 > sr - 0.7: continue     # the walk along the wall goods stays open
				if _put(fi, fxx, fz + rng.randf_range(-0.2, 0.2), fyaw):
					if fi == "card_spinner": nsp += 1
					if fi == "brochure_rack": nbr += 1
			fz -= 1.2 + rng.randf() * 0.3
	# ---- dressing: plants in the front corners, a bin by the counter end, prints on the bare walls
	_put("potted_plant", X0 + 0.3, ZF - 0.3); _put("potted_plant", X1 - 0.3, ZF - 0.3)
	if not kind in ["library", "bank", "hall"] and X1 - (cx + cw * 0.5 + 0.3) < 1.2: _put("indoor_bin", cx + cw * 0.5 + 0.3, zc + cd * 0.5 + 0.25)      # (high street copy: only where the counter end meets a wall; check_rooms "lone")      # (high street copy: the library desk stands free of walls: no bin beside it)
	if kind in ["office", "pharmacy", "souvenir", "venue", "gallery"]: _put("brochure_rack", dx + (1.3 if dx < (X0 + X1) * 0.5 else -1.3), ZF - 1.9, 180.0)
	if bool(K.frames) or String(K.walls[0]) in ["frames_only", "poster_wall"]:
		var mount := "poster_case" if String(K.walls[0]) == "poster_wall" else "gallery_frame"
		var nroom := 0
		for side2: Array in [[X0, 90.0, "left"], [X1, -90.0, "right"]]:
			var wx2 := float(side2[0]); var inn2 := 1.0 if float(side2[1]) > 0.0 else -1.0
			var nwall := 0
			for zz: float in _steps(ZBp + 1.2, ZF - 1.0, 1.6 if mount == "gallery_frame" else 1.4):
				if nwall >= 2 or nroom >= 4: break                                    # check_rooms "deco": 2 a wall, 6 a room
				if _under_window(sidewin, String(side2[2]), zz - 0.6, zz + 0.6, 99.0): continue   # no frame over a window at any height
				var blocked := false
				for o: Array in occ:
					if float(o[4]) > 1.25 and zz > float(o[1]) - 0.4 and zz < float(o[3]) + 0.4 and absf((float(o[0]) + float(o[2])) * 0.5 - wx2) < 1.0: blocked = true
				if not blocked: rr.prop(mount, wx2 + inn2 * 0.04, zz, float(side2[1]), 1.35); nwall += 1; nroom += 1
	# ---- back of house
	if ZP > ZB + 0.01:
		var kx := X0 + 0.2
		var stuff: Array = ["kitchen_line", "wall_shelf"] if back == "kitchen" else (["office_desk", "filing_cabinet", "filing_cabinet"] if back == "office" else ["wall_shelf", "wall_shelf", "wall_shelf"])
		var save_zbp := ZBp; ZBp = ZB
		var saved_keep := keep; keep = [[staff_x - 0.55, ZP - 1.1, staff_x + 0.55, ZP]]
		for p2: String in stuff:
			var f2 := _fp(p2, 0.0)
			while kx + f2.x < X1 - 0.2:
				if _put(p2, kx + f2.x * 0.5, ZB + f2.y * 0.5 + 0.03, 0.0): kx += f2.x + 0.1; break
				kx += 0.3
		if back == "office": _put("office_chair", X0 + 0.2 + _fp("office_desk", 0.0).x * 0.5, ZB + 0.95, 180.0)
		keep = saved_keep; ZBp = save_zbp
	# ---- light: fixtures over the shop floor (at most four real lights), one in the back, daylight at the window
	var nl := 0
	var lz: Array = _steps(ZBp + 1.2, ZF - 1.2, 3.6); var lx: Array = _steps(X0 + 1.2, X1 - 1.2, 3.8)
	for zz: float in lz:
		for xx: float in lx:
			if nl >= 4: break
			if String(K.light) == "pendant" and H - F > 3.2: rr.pendant(xx, zz, H, 0.8, Color(1.0, 0.8, 0.58), 1.3, 5.0)
			else: rr.pendant(xx, zz, H, 0.0, Color(1.0, 0.96, 0.9), 1.2, 5.5, true)
			nl += 1
	if ZP > ZB + 0.01: rr.pendant((X0 + X1) * 0.5, (ZB + ZP) * 0.5, H, 0.0, Color(0.95, 0.97, 1.0), 1.0, 4.0, true)
	var day := OmniLight3D.new(); day.position = Vector3(dx, F + 1.9, ZF - 0.7); day.light_color = Color(0.86, 0.92, 1.0); day.light_energy = 0.8; day.omni_range = 5.0
	rr.lights.add_child(day)
	# ---- wear: the walk from the door to the counter and the queue
	var fy := func(_x: float, _z: float) -> float: return F
	var steps := maxi(2, int((ZF - zc) / 1.3))
	for k2 in steps: rr.dec.add(14, Vector2(lerpf(dx, cx, float(k2) / steps), ZF - 0.6 - k2 * 1.25), 0.0, 1.0, 1.4, fy, Color(1, 1, 1, 0.3), 0.004)
	rr.dec.add(14, Vector2(cx, zc + cd * 0.5 + 0.6), 0.0, cw, 0.9, fy, Color(1, 1, 1, 0.4), 0.004)
	# ---- the shop's own name on the building's boards
	for sg: Dictionary in e.signs:
		var txt := String(e.name).to_upper() if float(sg.w) >= 2.4 else String(SHORT.get(kind, "SHOP"))
		rr.sign(c, String(sg.facade), float(sg.along), txt, String(e.style))
	await rr.make_signs(self)
	var root := rr.build()
	root.set_meta(&"shop", {"id": String(e.id), "kind": kind, "name": String(e.name)})
	var path := rr.save(id)
	var props := 0
	for pn: MultiMeshInstance3D in root.get_node("Props").get_children(): props += pn.multimesh.instance_count
	report.append({"id": id, "kind": kind, "name": e.name, "w": snappedf(width, 0.01), "d": snappedf(depth, 0.01), "props": props, "lights": root.get_node("Lights").get_child_count(), "file": path})
	print("GEN %s %s '%s' %.1f x %.1f m, %d props" % [id, kind, e.name, width, depth, props])
	root.free()

func _steps(a: float, b: float, pitch: float) -> Array:
	var out: Array = []
	if b < a: return out
	var n := maxi(1, int(floor((b - a) / pitch)) + 1)
	var span := (n - 1) * pitch
	var s := (a + b) * 0.5 - span * 0.5
	for i in n: out.append(s + i * pitch)
	return out

## the ground-floor windows of the side walls: [facade, z0, z1, sill height]
func _side_windows(c: Dictionary) -> Array:
	var out: Array = []
	for o: Dictionary in c.openings:
		if int(o.floor) != 0: continue
		var fac := String(o.facade)
		if fac != "left" and fac != "right": continue
		out.append([fac, float(o.along) - float(o.w) * 0.5 - 0.1, float(o.along) + float(o.w) * 0.5 + 0.1, float(o.y0) - F])
	return out

func _under_window(sw: Array, side: String, z0: float, z1: float, height: float) -> bool:
	for w: Array in sw:
		if String(w[0]) == side and z0 < float(w[2]) and z1 > float(w[1]) and height > float(w[3]) - 0.05: return true
	return false
