extends SceneTree
## Rooms for the COMMERCIAL STRIP's new shops (claude/grow-strip, 18 Nov; Yasin: "do out and indoors together ... i want
## the shops to look different"; "look from the perspective of interior designer and the customers"). A copy of
## room_gen.gd (the shared generator is not changed): the same shell (the building's measured walls, real windows and
## see-through doors cut from room_contracts, the shop's sign on the building's boards), with the strip's OWN kinds.
## The strip's character, from the customer's side: roadside chains and family shops you drive to - bright, loud
## wall colours (the brand colour on every wall), flat bright panel light, hard wipe-clean floors, menu boards and
## posters, the till facing the door, and people WAITING: for a burger, for their car at the lube or the wash, for a tax
## form - so there are always seats facing the window where they can watch their car. Every kind is laid out for how
## its customers use it (KINDS below: the reason is written per kind). Lights are kept low (a strip has rooms in a row):
## at most 2 fixtures with real lights + the window daylight per room.
## Input: interiors/assignment_strip.json (tools/city/rooms/assign_strip.py), contracts room_contracts_strip.json.
## Output: interiors/rooms/g_strip_<id>.scn. Then interiors/rooms/check_rooms.gd (0 problems) and gen_shots.gd.
##   xvfb-run -a godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/rooms/room_gen_strip.gd -- [--only=ID,ID]
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")
const D := "res://map_dc/coronado/city_kit/interiors/"
const MAN := "res://assets/coronado_kit/props/"

## per kind: floor texture, light (pendant / panel), the counter row, what stands behind it, the side walls' items,
## the middle of the room, the window zone, back of house (kitchen / stock / none), extras
const KINDS := {
	# chicken / burger drive-thru: order at the long counter facing the door, the kitchen line in view behind it (people
	# like to see the food made), menu boards over it, a soda fountain on the customers' side to refill, booths along the
	# walls for families, two-tops in the window for the lone driver eating fast
	"drive_thru": {"floor": "Tiles074", "light": "panel", "counter": ["shop_counter", "shop_counter", "shop_counter"], "till": true, "behind": ["kitchen_line", "kitchen_line", "soda_fountain", "drinks_fridge"], "board": true, "walls": ["booth"], "centre": "table4", "window": "table2", "back": "kitchen", "frames": false, "posters": true, "tint": Color(0.98, 0.78, 0.62), "extra": ["soda_fountain", "indoor_bin"]},
	# taqueria: a small order counter with the menu board, the salsa bar in the middle, the drinks fridge by the door,
	# bright painted walls, a few tables; people stand in the queue looking at the board
	"taqueria": {"floor": "Tiles143", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["kitchen_line"], "board": true, "walls": ["drinks_fridge", "booth"], "centre": "salsa", "window": "table2", "back": "none", "frames": true, "tint": Color(1.0, 0.86, 0.5)},
	# roadside diner: the long counter with stools (truckers, regulars), the pie case at its end, booths along the
	# window wall, four-tops in the middle, the kitchen behind a pass-through
	"diner": {"floor": "Tiles101", "light": "pendant", "counter": ["bar_counter", "bar_counter", "pastry_case"], "stools": true, "till": false, "behind": ["soda_fountain", "espresso_machine", "wall_shelf"], "board": true, "walls": ["booth"], "centre": "table4", "window": "booths", "back": "kitchen", "frames": true, "tint": Color(0.97, 0.9, 0.82)},
	# car wash office: you pay and wait for the car: benches facing the window onto the bays, the vending machine, air
	# fresheners and car care on the wall behind the till, a drinks fridge
	"wash_office": {"max_d": 8.0, "floor": "Concrete047A", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["cigarette_cabinet", "wall_shelf", "wall_shelf"], "board": false, "walls": ["waiting_bench", "vending_soda", "waiting_bench", "drinks_fridge", "card_spinner"], "centre": "none", "window": "watch", "back": "none", "frames": false, "posters": true, "tint": Color(0.78, 0.92, 0.96)},
	# quick-lube waiting room: the service desk where you hand in the keys, filing behind it, coffee on a side counter,
	# chairs facing the window onto the bays (you watch your car go up), a brochure rack of upsells
	"lube": {"max_d": 8.5, "floor": "Concrete047A", "light": "panel", "counter": ["shop_counter", "shop_counter"], "till": true, "behind": ["filing_cabinet", "pegboard_wall", "filing_cabinet"], "board": false, "walls": ["waiting_bench", "drinks_fridge", "waiting_bench", "wall_shelf", "pegboard_wall", "brochure_rack"], "centre": "none", "cap": {"wall_shelf": 1, "pegboard_wall": 1}, "window": "watch", "back": "stock", "frames": false, "posters": true, "tint": Color(0.86, 0.88, 0.92)},
	# auto parts: the parts counter across the back (the parts are behind it, the clerk looks them up), aisles of oil,
	# wipers and bulbs in the middle, batteries and tools on pegboards on the walls, oil specials in the window
	"auto_parts": {"floor": "Tiles141", "light": "panel", "counter": ["shop_counter", "shop_counter"], "till": true, "behind": ["wall_shelf", "wall_shelf", "wall_shelf", "workbench"], "board": false, "walls": ["pegboard_wall", "wall_shelf", "pegboard_wall"], "centre": "rows", "window": "display", "back": "stock", "frames": false, "posters": true, "tint": Color(0.96, 0.88, 0.86)},
	# phone repair + vape: glass cases of phones and cases on both walls, the repair bench behind the counter (you
	# watch them open your phone), a spinner of chargers
	"phone": {"floor": "Terrazzo005", "light": "panel", "counter": ["glass_display_case", "shop_counter"], "till": true, "behind": ["workbench", "wall_shelf"], "board": false, "walls": ["glass_display_case", "card_spinner", "wall_shelf"], "centre": "none", "window": "cases", "back": "none", "frames": false, "posters": true, "tint": Color(0.86, 0.84, 0.96)},
	# tyre shop: the counter where you pick tyres off a catalogue, the fitting bay's door behind it, tyre-care and rims
	# on shelves along the walls, waiting benches facing the room, a fridge; loud yellow walls of a discount chain
	"tyre": {"max_d": 10.0, "floor": "Concrete047A", "light": "panel", "counter": ["shop_counter", "shop_counter"], "till": true, "behind": ["pegboard_wall", "wall_shelf", "workbench"], "board": false, "walls": ["wall_shelf", "waiting_bench", "drinks_fridge", "waiting_bench", "wall_shelf"], "centre": "none", "window": "display", "back": "stock", "frames": false, "posters": true, "cap": {"wall_shelf": 2}, "tint": Color(0.98, 0.92, 0.66)},
	# used-car sales office: one salesman's desk with the buyer's chair facing it, a coffee counter, key cabinet (a
	# filing cabinet), brochures and the "finance today" posters; the window looks onto the lot
	"car_sales": {"max_d": 10.0, "floor": "Tiles141", "light": "panel", "counter": [], "till": false, "behind": ["filing_cabinet", "filing_cabinet", "wall_shelf"], "board": false, "walls": ["brochure_rack", "drinks_fridge", "waiting_bench"], "centre": "none", "window": "waiting", "back": "none", "frames": false, "posters": true, "tint": Color(0.86, 0.9, 0.98)},
	# discount grocer: checkouts by the door (you queue to leave), long gondolas, fridges and freezers along the walls,
	# produce in the window, cheap bright signage
	"discount": {"floor": "Tiles141", "light": "panel", "counter": ["checkout_counter", "checkout_counter"], "till": false, "behind": ["wall_shelf", "cigarette_cabinet"], "board": false, "walls": ["drinks_fridge", "chest_freezer", "drinks_fridge", "grocery_shelf"], "centre": "rows", "window": "produce", "back": "stock", "frames": false, "posters": true, "cap": {"drinks_fridge": 4, "chest_freezer": 3}, "tint": Color(1.0, 0.94, 0.78)},
	# laundromat: washers along one wall, dryers along the other, the folding table in the middle, chairs in the window,
	# the attendant's counter and the soap machine
	"laundromat": {"floor": "Tiles143", "light": "panel", "counter": ["laundry_counter"], "till": false, "behind": ["vending_snack", "wall_shelf"], "board": false, "walls": ["washer", "washer", "dryer", "dryer"], "centre": "fold", "window": "waiting", "back": "none", "frames": false, "posters": true, "cap": {"washer": 8, "dryer": 8}, "tint": Color(0.84, 0.94, 0.98)},
	# nail salon: nail tables along both walls with a chair each side, the polish shelf, pedicure basins at the back
	"nails": {"floor": "Tiles012", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["salon_product_shelf", "wash_basin"], "board": false, "walls": ["nail", "salon_product_shelf", "nail", "waiting_bench", "nail", "salon_product_shelf"], "centre": "none", "window": "waiting", "cap": {"salon_product_shelf": 3, "waiting_bench": 2}, "back": "none", "frames": true, "tint": Color(1.0, 0.88, 0.92)},
	# dentist: reception counter, waiting chairs in the window, the treatment room behind the partition
	"dentist": {"max_d": 12.0, "floor": "Tiles012", "light": "panel", "counter": ["shop_counter"], "till": false, "behind": ["filing_cabinet", "filing_cabinet"], "board": false, "walls": ["waiting_bench", "brochure_rack"], "centre": "none", "window": "waiting", "back": "office", "frames": true, "tint": Color(0.9, 0.97, 0.96)},
	# slice pizza: order counter with the pizza case, ovens behind, two-tops and a booth
	"pizza": {"floor": "Tiles101", "light": "panel", "counter": ["pastry_case", "shop_counter"], "till": true, "behind": ["kitchen_line", "drinks_fridge"], "board": true, "walls": ["booth", "drinks_fridge"], "centre": "table2", "window": "table2", "back": "none", "frames": true, "tint": Color(0.98, 0.84, 0.7)},
	# dry cleaner: the counter at the front half, the garment rails filling the back, a waiting chair
	"dry_cleaner": {"floor": "Tiles143", "light": "panel", "counter": ["laundry_counter"], "till": true, "behind": ["garment_rail", "garment_rail", "garment_rail"], "board": false, "walls": ["garment_rail", "garment_rail"], "centre": "none", "window": "waiting", "back": "none", "frames": false, "cap": {"garment_rail": 6}, "tint": Color(0.94, 0.94, 0.98)},
	# credit union: teller counter across the back, a desk for loans, a waiting bench, brochures
	"bank": {"floor": "Terrazzo005", "light": "panel", "counter": ["shop_counter", "shop_counter", "shop_counter"], "till": false, "behind": ["filing_cabinet", "filing_cabinet", "filing_cabinet"], "board": false, "walls": ["brochure_rack", "waiting_bench"], "centre": "desks", "window": "waiting", "back": "office", "frames": true, "tint": Color(0.93, 0.92, 0.86)},
	# recycling booth: the attendant's scale counter, bins of sorted cans behind
	"recycling": {"floor": "Concrete047A", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["wall_shelf", "filing_cabinet"], "board": true, "walls": ["wall_shelf"], "centre": "none", "window": "none", "back": "none", "frames": false, "tint": Color(0.88, 0.94, 0.86)},
	# tax prep / insurance: a reception counter, two preparer desks with a client chair each, waiting chairs at the
	# window, filing cabinets, leaflets
	"tax": {"max_d": 10.0, "floor": "Carpet012", "light": "panel", "counter": ["shop_counter"], "till": false, "behind": ["filing_cabinet", "filing_cabinet"], "board": false, "walls": ["filing_cabinet", "brochure_rack"], "centre": "desks", "window": "waiting", "back": "office", "frames": true, "tint": Color(0.93, 0.95, 0.9)},
}
const WARM := ["diner", "taqueria"]
const DRESS := {"drive_thru": ["indoor_bin", "potted_plant", "drinks_fridge", "indoor_bin", "brochure_rack"],
	 "taqueria": ["drinks_fridge", "potted_plant", "indoor_bin"],
	 "diner": ["potted_plant", "indoor_bin", "drinks_fridge"],
	 "wash_office": ["potted_plant", "indoor_bin", "brochure_rack", "waiting_bench"],
	 "lube": ["potted_plant", "indoor_bin", "wall_shelf"],
	 "auto_parts": ["display_table", "indoor_bin", "potted_plant", "card_spinner"],
	 "phone": ["waiting_bench", "card_spinner", "potted_plant", "indoor_bin", "brochure_rack"],
	 "tax": ["potted_plant", "indoor_bin", "waiting_bench"],
	 "tyre": ["display_table", "potted_plant", "indoor_bin", "brochure_rack"],
	 "car_sales": ["potted_plant", "indoor_bin", "waiting_bench"],
	 "discount": ["chest_freezer", "produce_stand", "indoor_bin", "potted_plant", "card_spinner"],
	 "laundromat": ["dryer", "dryer", "vending_snack", "waiting_bench", "indoor_bin", "potted_plant"],
	 "nails": ["potted_plant", "indoor_bin", "waiting_bench"],
	 "dentist": ["potted_plant", "display_table", "indoor_bin", "brochure_rack"],
	 "pizza": ["indoor_bin", "potted_plant", "drinks_fridge"],
	 "dry_cleaner": ["waiting_bench", "garment_rail", "garment_rail", "potted_plant", "indoor_bin"],
	 "bank": ["potted_plant", "potted_plant", "indoor_bin", "waiting_bench"],
	 "recycling": ["potted_plant"]}
const CAP := {"vending_soda": 1, "drinks_fridge": 1, "waiting_bench": 3, "card_spinner": 1, "brochure_rack": 1, "glass_display_case": 3, "filing_cabinet": 3}
const WALL_TINTS := [Color(1.0, 0.95, 0.86), Color(0.94, 0.96, 0.98), Color(0.98, 0.92, 0.84), Color(0.9, 0.95, 0.92), Color(1.0, 0.97, 0.93), Color(0.93, 0.9, 0.86)]
const SHORT := {"cafe": "COFFEE", "bakery": "BAKERY", "bar": "BAR", "restaurant": "KITCHEN", "fast_food": "FOOD", "ice_cream": "ICE CREAM",
	"clothes": "CLOTHES", "shoes": "SHOES", "jewelry": "JEWELRY", "books": "BOOKS", "gallery": "GALLERY", "salon": "SALON", "pharmacy": "PHARMACY",
	"souvenir": "GIFTS", "office": "OFFICE", "corner_shop": "MARKET", "grocery": "GROCERY", "cleaners": "LAUNDRY", "store": "SUPPLY", "keys": "KEYS",
	"sport": "SPORT", "gas": "FUEL", "venue": "TICKETS", "drive_thru": "CHICKEN", "taqueria": "TACOS", "diner": "DINER",
	"wash_office": "CAR WASH", "lube": "OIL CHANGE", "auto_parts": "AUTO PARTS", "phone": "PHONES", "tax": "TAX", "tyre": "TIRES", "car_sales": "USED CARS", "discount": "MARKET", "laundromat": "LAUNDRY", "nails": "NAILS", "dentist": "DENTIST", "pizza": "PIZZA", "dry_cleaner": "CLEANERS", "bank": "CREDIT UNION", "recycling": "RECYCLING"}

var foot := {}      # base -> Vector2(w, d)
var tall := {}      # base -> height
var occ: Array = [] # [x0, z0, x1, z1, height]
var keep: Array = [] # [x0, z0, x1, z1] floor that stays free
var X0 := 0.0; var X1 := 0.0; var ZF := 0.0; var ZB := 0.0; var ZBp := 0.0; var F := 0.0
var rr: R
var report: Array = []
var wall_marks: Array = []   # [wall x, z] of every wall poster / frame already hung: the next keeps 1.6 m clear (Yasin 18 Nov: wall props overlapping)

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
	rc.merge(JSON.parse_string(FileAccess.get_file_as_string(D + "room_contracts_strip.json")).models, true)
	var asg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(D + "assignment_strip.json"))
	var n := 0
	for e: Dictionary in asg.rooms:
		if String(e.built) != "": continue
		if not only.is_empty() and not only.has(String(e.id)): continue
		if not kinds.is_empty() and not kinds.has(String(e.kind)): continue
		if n >= limit: break
		await _room(e, rc[String(e.model)])
		n += 1
	var fo := FileAccess.open(D + "rooms_strip_report.json", FileAccess.WRITE)
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
	var f := _fp(base, yaw)
	var x0 := x - f.x * 0.5; var x1 := x + f.x * 0.5; var z0 := z - f.y * 0.5; var z1 := z + f.y * 0.5
	if not _free(x0, z0, x1, z1, use_keep): return false
	rr.prop(base, x, z, yaw)
	occ.append([x0, z0, x1, z1, float(tall.get("prop_" + base, 1.0))])
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
	occ.append([b[0], b[1], b[2], b[3], ht])
	return true

func _table2(x: float, z: float) -> Array:
	return [["cafe_table", x, z, 0.0], ["cafe_chair", x - 0.58, z, 90.0], ["cafe_chair", x + 0.58, z, -90.0]]
func _table4(x: float, z: float) -> Array:
	return [["restaurant_table", x, z, 0.0], ["side_chair", x - 0.3, z - 0.62, 0.0], ["side_chair", x + 0.3, z - 0.62, 0.0], ["side_chair", x - 0.3, z + 0.62, 180.0], ["side_chair", x + 0.3, z + 0.62, 180.0]]

## ------------------------------------------------------------------------------------------------ one room
func _room(e: Dictionary, c: Dictionary) -> void:
	var kind := String(e.kind)
	var K: Dictionary = KINDS.get(kind, KINDS.tax)
	var id := "g_strip_" + String(e.id)
	var fl: Dictionary = c.floors[0]
	F = float(fl.y)
	X0 = maxf(float(e.bay[0]), float(fl.box_min[0])); X1 = minf(float(e.bay[1]), float(fl.box_max[0]))
	ZF = float(fl.box_max[2])
	# the room's front wall stands 0.25 m inside the door's facade plane (as the hand-made rooms: the reveal and frame
	# fill the depth); on most shop models the measured box reaches the facade itself
	for o: Dictionary in c.openings:
		if int(o.floor) == 0 and String(o.facade) == "front" and (String(o.region) == "O_shopdoor" or String(o.region) == "O_civic_door") and absf(float(o.along) - float(e.door_along)) < 0.6:
			ZF = minf(ZF, float(o.plane) - 0.25)
	var zb_bld := float(fl.box_min[2])
	ZB = maxf(zb_bld, ZF - float(K.get("max_d", 16.0)))   # deep buildings: the shop takes the front (an office, a waiting room: 8 m)
	var H := F + minf(float(fl.clear_h), 4.0)
	var depth := ZF - ZB; var width := X1 - X0
	var back := String(K.back)
	var ZP := ZB
	if depth >= 9.0 and back != "none": ZP = ZB + (2.9 if back == "kitchen" else 2.3)
	ZBp = ZP
	occ = []; keep = []; wall_marks = []
	rr = R.new(id, F)
	rr.world_xf = Transform3D(Basis(Vector3.UP, deg_to_rad(float(e.yaw))), Vector3(float(e.pos[0]), float(e.pos[1]), float(e.pos[2])))
	var hh := _h(id)
	var tint: Color = (K.get("tint", WALL_TINTS[hh % WALL_TINTS.size()]) as Color).lerp(WALL_TINTS[hh % WALL_TINTS.size()], 0.15)
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
	# a wall shared with the neighbouring shop (a row's bay boundary) stands 0.12 m inside THIS shop, so the two rooms
	# have a real wall between them: in one plane, whatever hangs on one side (frames, posters) showed its back on the
	# other as dark marks on a bare wall (Yasin 18 Nov, picture of the dry cleaner's wall)
	if not bool(outer.left): X0 += 0.12
	if not bool(outer.right): X1 -= 0.12
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
	for en: Dictionary in c.entrances:      # every other door of the same shop too (rows, drive-thrus have two)
		if int(en.floor) == 0 and String(en.facade) == "front" and float(en.along) > X0 and float(en.along) < X1:
			keep.append([float(en.along) - float(en.w) * 0.5 - 0.3, ZF - 1.7, float(en.along) + float(en.w) * 0.5 + 0.3, ZF])
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
	# ---- the lube waiting room's own corner (Yasin 18 Nov: "do that"): what a customer finds while the car is done -
	# free coffee on a side counter with a bin, the rack of oil, wipers and air filters next to the service desk (the
	# upsell), the specials table in front of it, the promo board where people look up from their phones
	if kind == "lube":
		var far_x := X1 if dx < (X0 + X1) * 0.5 else X0            # the side wall away from the door
		var inn4 := -1.0 if far_x == X1 else 1.0; var yw4 := -90.0 if far_x == X1 else 90.0
		var zcf := (zc + cd * 0.5 + ZF) * 0.5
		if _put("shop_counter", far_x + inn4 * 0.37, zcf, yw4):
			rr.prop("espresso_machine", far_x + inn4 * 0.4, zcf - 0.45, yw4 + 180.0, 0.964)       # staff side +Z: turned to face the room
			_put("indoor_bin", far_x + inn4 * 0.25, zcf + 1.25, yw4)
			rr.prop("poster_case", far_x + inn4 * 0.05, zcf, yw4, 1.1)                           # the promo board over the coffee (same line as the posters)
			wall_marks.append([far_x, zcf])
		var near_x := X0 if far_x == X1 else X1; var inn5 := -inn4
		_put("display_table", cx + (1.6 if far_x == X1 else -1.6), zc + cd * 0.5 + 2.2, 0.0)   # this week's oil specials, beside the queue
		_put("potted_plant", near_x + inn5 * 0.3, ZF - 1.1, -yw4)
	# ---- the used-car office: the salesman's desk is the room (he sits behind it facing the door, the buyers' two chairs
	# face him, the "finance today" board over his shoulder)
	if kind == "car_sales":
		var mx := (X0 + X1) * 0.5 + (0.6 if dx < (X0 + X1) * 0.5 else -0.6)
		var zm := zc + cd * 0.5 + 1.6
		_group([["office_desk", mx, zm, 180.0], ["office_chair", mx, zm - 0.75, 180.0], ["side_chair", mx - 0.4, zm + 0.8, 180.0], ["side_chair", mx + 0.4, zm + 0.8, 180.0]])
	if kind == "recycling":     # the attendant sits behind the scale counter, facing the window where people bring their bags
		_put("office_chair", cx, zc - cd * 0.5 - 0.35, 0.0, false)
	# ---- the side walls: the shop's goods / seats along them (low things only under the side windows)
	var sidewin := _side_windows(c)
	var used := {}         # per ROOM (not per wall): one soda machine, at most two fridges in the whole room
	for side: Array in [[X0, 90.0, "left"], [X1, -90.0, "right"]]:
		var wx := float(side[0]); var yaw := float(side[1]); var inn := 1.0 if yaw > 0.0 else -1.0
		var items: Array = K.walls
		var z := ZF - 0.45; var k := 0
		var tries := 0; var run := 0; var stations := 0
		while z > ZBp + 0.4 and tries < 60:
			tries += 1
			# no endless runs of one thing: after three a break (a plant in the gap), and a barber has three chairs a side
			if run >= 3:
				run = 0
				if _put("potted_plant", wx + inn * 0.3, z - 0.25, yaw): z -= 0.6
				else: z -= 0.3
				continue
			var it := String(items[k % items.size()])
			# nobody has four soda machines: appliances and racks appear once or twice a room, then the wall stays bare
			if int(used.get(it, 0)) >= int((K.get("cap", {}) as Dictionary).get(it, CAP.get(it, 99))):
				k += 1
				if k > items.size() * 3: break
				continue
			if it == "station" and stations >= 3: break
			if it == "frames_only" or it == "poster_wall": break
			if it == "booth":
				# as the waterfront cafe's booths: the table's long side out from the wall, a bench on each side of it
				var bxw := wx + inn * 0.72; var zt := z - 1.05
				if _group([["restaurant_table", bxw, zt, 0.0], ["booth_bench", bxw, zt + 0.73, 180.0], ["booth_bench", bxw, zt - 0.73, 0.0]]):
					z -= 2.25; k += 1; run += 1; continue
				z -= 0.3; continue
			if it == "nail":       # a nail table out from the wall, the client's chair on the room side, the tech's at the wall
				if X1 - X0 < 7.5 and absf(wx - dx) < absf((X0 + X1 - wx) - dx): k += 1; continue     # a narrow salon: tables along the wall AWAY from the door (the walk to the counter runs on the door side), shelves on the other
				var nx := wx + inn * 1.35     # the technician walks in behind the chair
				if _group([["nail_table", nx, z - 0.6, yaw], ["side_chair", nx + inn * 0.65, z - 0.6, yaw + 180.0], ["side_chair", nx - inn * 0.6, z - 0.6, yaw]]):
					z -= 1.5; run += 1; continue
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
			if _put(it, wx + inn * (f.x * 0.5 + 0.02), z - f.y * 0.5, yaw): z -= f.y + 0.06; k += 1; run += 1; used[it] = int(used.get(it, 0)) + 1
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
			for xx: float in _steps(X0 + 0.9, X1 - 0.9, 2.2): _put("display_table", xx, wz - 0.45, 0.0)
		"mannequins":
			for xx: float in _steps(X0 + 0.7, X1 - 0.7, 1.3): _put("mannequin", xx, wz - 0.35, 0.0)
		"cases":
			for xx: float in _steps(X0 + 0.9, X1 - 0.9, 2.0): _put("glass_display_case", xx, wz - 0.35, 180.0)
		"waiting":
			for xx: float in _steps(X0 + 1.0, X1 - 1.0, 2.4): _put("waiting_bench", xx, wz - 0.32, 180.0)
		"produce":
			for xx: float in _steps(X0 + 1.0, X1 - 1.0, 2.3): _put("produce_stand", xx, wz - 0.4, 0.0)
		"watch":      # benches under the window, their backs to it, facing the room
			for xx: float in _steps(X0 + 1.0, X1 - 1.0, 2.2): _put("waiting_bench", xx, wz - 0.75, 180.0)   # back to the window, facing the room (Yasin 18 Nov: facing out "looks awkward")
		"booths":     # diner booths along the window wall, the table's long side out from the glass
			for xx: float in _steps(X0 + 1.0, X1 - 1.0, 2.4):
				_group([["restaurant_table", xx, wz - 0.75, 90.0], ["booth_bench", xx - 0.73, wz - 0.75, 90.0], ["booth_bench", xx + 0.73, wz - 0.75, -90.0]])
		"brochures":
			for xx: float in _steps(X0 + 0.6, X1 - 0.6, 2.0): _put("brochure_rack", xx, wz - 0.3, 180.0)
	# ---- the middle of the shop
	var mz0 := zc + cd * 0.5 + 1.3; var mz1 := ZF - (1.6 if String(K.window) == "none" else 2.4)      # a walkway between the middle and the window display
	match String(K.centre):
		"table2":
			for zz: float in _steps(mz0 + 0.5, mz1 - 0.5, 1.8):
				for xx: float in _steps(IX0 + 0.95, IX1 - 0.95, 2.1): _group(_table2(xx, zz))
		"table4":
			for zz: float in _steps(mz0 + 0.8, mz1 - 0.8, 2.5):
				for xx: float in _steps(IX0 + 0.65, IX1 - 0.65, 2.3): _group(_table4(xx, zz))
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
		"lounge":     # waiting seats in the middle facing the window (where the car is), a side chair or two, a table of magazines
			for zz: float in _steps(mz0 + 0.4, mz1 - 0.2, 1.6):
				for xx: float in _steps(IX0 + 0.8, IX1 - 0.8, 2.0): _put("waiting_bench", xx, zz, 0.0)
			_put("display_table", IX0 + 0.75, mz1 + 0.2, 90.0)
		"fold":       # the folding tables down the middle of a laundromat
			for zz: float in _steps(mz0 + 0.5, mz1 - 0.5, 1.6): _put("display_table", (IX0 + IX1) * 0.5, zz, 90.0)
		"salsa":      # the salsa bar (a low display) in the middle, two-tops round it
			_put("display_table", (IX0 + IX1) * 0.5, (mz0 + mz1) * 0.5, 90.0)
			for zz: float in _steps(mz0 + 0.5, mz1 - 0.5, 1.8):
				for xx: float in [IX0 + 0.6, IX1 - 0.6]: _group(_table2(xx, zz))
		"desks":      # preparer desks: the preparer sits with the back to the side wall, the client faces them
			for zz: float in _steps(mz0 + 0.8, mz1 - 0.8, 2.6):
				for xx: float in _steps(IX0 + 0.8, IX1 - 0.8, 3.2):
					_group([["office_desk", xx, zz, 180.0], ["office_chair", xx, zz - 0.75, 0.0], ["side_chair", xx, zz + 0.75, 180.0]])
		"benches":
			for zz: float in _steps(mz0 + 0.4, mz1 - 0.4, 2.4):
				for xx: float in _steps(IX0 + 0.74, IX1 - 0.74, 2.6): _put("waiting_bench", xx, zz, 0.0)
	# ---- dressing: plants in the front corners, a bin by the counter end, prints on the bare walls
	_put("potted_plant", X0 + 0.3, ZF - 0.3); _put("potted_plant", X1 - 0.3, ZF - 0.3)
	_put("indoor_bin", cx + cw * 0.5 + 0.3, zc + cd * 0.5 + 0.25)
	if kind in ["office", "pharmacy", "souvenir", "venue", "gallery"]: _put("brochure_rack", dx + (1.3 if dx < (X0 + X1) * 0.5 else -1.3), ZF - 1.9, 180.0)
	# ---- wall decoration (Yasin 18 Nov: "it looks as if you just filled every wall with paintings, its too repetitive"):
	# only where art belongs (frames: true), at most TWO pieces per wall, never the same piece twice in a row, at a third
	# and two thirds of the wall's free run, all on one height line
	if bool(K.frames):
		var deco := ["gallery_frame", "poster_case", "gallery_frame", "menu_board"]
		var di := _h(id + "deco") % deco.size()
		for side2: Array in [[X0, 90.0, "left"], [X1, -90.0, "right"]]:
			var wx2 := float(side2[0]); var inn2 := 1.0 if float(side2[1]) > 0.0 else -1.0
			var span := ZF - 1.0 - (ZBp + 1.2)
			var placed2 := 0
			for t2: float in [0.33, 0.7]:
				if placed2 >= 2 or span < 1.5: break
				var zz := ZBp + 1.2 + span * t2
				if _under_window(sidewin, String(side2[2]), zz - 0.5, zz + 0.5, 1.2): continue
				var blocked := false
				for o: Array in occ:
					if float(o[4]) > 1.25 and zz > float(o[1]) - 0.4 and zz < float(o[3]) + 0.4 and absf((float(o[0]) + float(o[2])) * 0.5 - wx2) < 1.0: blocked = true
				for wm2: Array in wall_marks:
					if absf(float(wm2[0]) - wx2) < 0.5 and absf(float(wm2[1]) - zz) < 1.6: blocked = true
				if blocked: continue
				var piece := String(deco[di % deco.size()]); di += 1
				rr.prop(piece, wx2 + inn2 * 0.04, zz, float(side2[1]), 1.35 if piece == "gallery_frame" else (1.6 if piece == "menu_board" else 1.1))
				wall_marks.append([wx2, zz]); placed2 += 1
	# ---- strip chains: promo posters on the bare side walls, extras (refill station, bins) by the queue
	if bool(K.get("posters", false)):
		for side3: Array in [[X0, 90.0, "left"], [X1, -90.0, "right"]]:
			var wx3 := float(side3[0]); var inn3 := 1.0 if float(side3[1]) > 0.0 else -1.0
			for zz: float in [(zc + cd * 0.5 + 1.0 + ZF - 1.2) * 0.5]:     # ONE promo poster per wall, at its middle
				if _under_window(sidewin, String(side3[2]), zz - 0.5, zz + 0.5, 1.2): continue
				var blk := false
				for o: Array in occ:
					if float(o[4]) > 1.1 and zz > float(o[1]) - 0.5 and zz < float(o[3]) + 0.5 and absf((float(o[0]) + float(o[2])) * 0.5 - wx3) < 1.2: blk = true
				for wm: Array in wall_marks:
					if absf(float(wm[0]) - wx3) < 0.5 and absf(float(wm[1]) - zz) < 1.6: blk = true
				if not blk:
					rr.prop("poster_case", wx3 + inn3 * 0.05, zz, float(side3[1]), 1.1); wall_marks.append([wx3, zz])
	for ex: String in K.get("extra", []):
		var exs := _fp(ex, 180.0)
		for zz2: float in _steps(zc + cd * 0.5 + 1.4, ZF - 2.0, 0.6):
			var xx2 := X0 + exs.x * 0.5 + 0.05 if dx > (X0 + X1) * 0.5 else X1 - exs.x * 0.5 - 0.05
			if _put(ex, xx2, zz2, 90.0 if xx2 < (X0 + X1) * 0.5 else -90.0): break
	# ---- polish pass (Yasin 18 Nov: "lots of props ... think like an interior designer, customer"): what each shop still
	# lacks goes on the free wall space - against a side wall facing the room, from the back toward the window, never in
	# the walk from the door, the queue or a doorway (the same _put rules as everything else)
	for dz: String in DRESS.get(kind, []):
		var placed_d := false
		for side4: Array in [[X0, 90.0], [X1, -90.0]]:
			if placed_d: break
			var wx4 := float(side4[0]); var inn4b := 1.0 if float(side4[1]) > 0.0 else -1.0
			var f4 := _fp(dz, float(side4[1]))
			var z4 := ZBp + f4.y * 0.5 + 0.6
			while z4 < ZF - 0.8 and not placed_d:
				if _put(dz, wx4 + inn4b * (f4.x * 0.5 + 0.03), z4, float(side4[1])): placed_d = true
				z4 += 0.35
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
			if nl >= int(K.get("lights", 2)): break
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
