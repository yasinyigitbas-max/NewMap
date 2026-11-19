extends SceneTree
## GRITTY EDGE shop rooms (18 Nov, claude/grow-gritty): a copy of room_gen.gd (the shared generator is not edited) for
## the new shops of the gritty edge's variants and pilot area (interiors/assignment_grt.json, tools/city/rooms/
## assign_grt.py). The tool part is the same: the room is fitted to the building's measured walls, its real door,
## windows and sign boards (room_lib.gd). The inside is this zone's own, designed from the customer's side:
## - the service point in view from the door, the first 1.5 m clear, queue space and staff space as everywhere;
## - but it is the gritty edge (no cages over the counters: Yasin 18 Nov, "they arent prison cells"): a wall of goods pressed to the ceiling, chairs that never matched, fluorescent tubes (warm
##   bulbs only in the bar and the diner), walls that were white once, floors worn grey where people stand, scuffs,
##   cracked tiles, hand-painted plates outside in faded colours;
## - two shops of one kind are never alike: the staff end, the order of the goods on the walls, the floor and the
##   wall paint change with the shop.
## Saved as interiors/rooms/g_<id>.scn (ids start with grt_). The 12 hand-made and the 150 generated rooms are not touched.
##   xvfb-run -a godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/rooms/room_gen_grt.gd -- [--only=ID,ID]
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")
const D := "res://map_dc/coronado/city_kit/interiors/"
const MAN := "res://assets/coronado_kit/props/"

## per kind: floor texture, light (pendant / panel), the counter row, what stands behind it, the side walls' items,
## the middle of the room, the window zone, back of house (kitchen / stock / none), extras
const KINDS := {
	"pawn": {"floor": "Tiles074", "light": "panel", "counter": ["glass_display_case", "glass_display_case"], "till": false, "behind": ["pegboard_wall", "wall_shelf", "wall_shelf"], "board": false, "walls": ["glass_display_case", "bike_stand", "wall_shelf", "weight_bench", "pegboard_wall", "surfboard_rack"], "centre": "cases", "window": "cases", "back": "stock", "frames": false},
	"cash": {"floor": "Carpet012", "light": "panel", "counter": ["shop_counter", "shop_counter"], "till": true, "behind": ["filing_cabinet", "filing_cabinet", "office_desk"], "board": false, "walls": ["waiting_bench", "brochure_rack"], "centre": "benches", "window": "waiting", "back": "office", "frames": false},
	"liquor": {"floor": "Tiles074", "light": "panel", "counter": ["checkout_counter"], "till": false, "behind": ["cigarette_cabinet", "wall_shelf", "cigarette_cabinet"], "board": false, "walls": ["drinks_fridge", "drinks_fridge", "grocery_shelf"], "centre": "rows", "window": "none", "back": "stock", "frames": false},
	"bodega": {"floor": "Tiles141", "light": "panel", "counter": ["checkout_counter"], "till": false, "behind": ["cigarette_cabinet", "wall_shelf"], "board": false, "walls": ["grocery_shelf", "drinks_fridge", "grocery_shelf", "chest_freezer"], "centre": "rows", "window": "produce", "back": "stock", "frames": false},
	"diner": {"floor": "Tiles143", "light": "pendant", "counter": ["bar_counter", "bar_counter"], "stools": true, "behind": ["soda_fountain", "espresso_machine", "wall_shelf"], "board": true, "walls": ["booth"], "centre": "table4", "window": "table2", "back": "kitchen", "frames": true, "mix": true},
	"takeout": {"floor": "Tiles074", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["soda_fountain", "kitchen_line"], "board": true, "walls": ["drinks_fridge", "booth"], "centre": "table2", "window": "table2", "back": "kitchen", "frames": false, "mix": true},
	"bar": {"floor": "WoodFloor051", "light": "pendant", "counter": ["bar_counter", "bar_counter"], "stools": true, "behind": ["wine_backbar", "drinks_fridge"], "board": false, "walls": ["booth"], "centre": "table2", "window": "table2", "back": "stock", "frames": true, "mix": true},
	"laundry": {"floor": "Tiles143", "light": "panel", "counter": ["laundry_counter"], "till": false, "behind": ["garment_rail", "wall_shelf"], "board": false, "walls": ["washer", "washer", "dryer", "dryer"], "centre": "folding", "window": "waiting", "back": "none", "frames": false},
	"barber": {"floor": "Tiles012", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["salon_product_shelf", "wash_basin"], "board": false, "walls": ["station"], "centre": "none", "window": "waiting", "back": "none", "frames": true},
	"tattoo": {"floor": "Concrete047A", "light": "panel", "counter": ["glass_display_case", "shop_counter"], "till": true, "behind": ["wall_shelf", "filing_cabinet"], "board": false, "walls": ["station"], "centre": "none", "window": "waiting", "back": "none", "frames": true},
	"thrift": {"floor": "WoodFloor034", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["wall_shelf", "bookcase"], "board": false, "walls": ["garment_rail", "bookcase", "shoe_wall", "bike_stand", "clothes_rack", "weight_bench"], "centre": "racks", "window": "mannequins", "back": "stock", "frames": false},
	"botanica": {"floor": "Tiles074", "light": "panel", "counter": ["glass_display_case", "shop_counter"], "till": true, "behind": ["wall_shelf", "wall_shelf"], "board": false, "walls": ["wall_shelf", "bookcase"], "centre": "display", "window": "display", "back": "none", "frames": true},
	"tyres": {"floor": "Concrete047A", "light": "panel", "counter": ["shop_counter"], "till": true, "behind": ["pegboard_wall", "wall_shelf"], "board": false, "walls": ["wall_shelf", "pegboard_wall", "workbench"], "centre": "none", "window": "waiting", "back": "none", "frames": false},
	"panaderia": {"floor": "Tiles143", "light": "panel", "counter": ["pastry_case", "shop_counter"], "till": true, "behind": ["grocery_shelf", "grocery_shelf"], "board": true, "walls": ["grocery_shelf", "drinks_fridge"], "centre": "display", "window": "display", "back": "kitchen", "frames": false},
	"phones": {"floor": "Tiles074", "light": "panel", "counter": ["glass_display_case", "shop_counter"], "till": true, "behind": ["pegboard_wall", "wall_shelf"], "board": false, "walls": ["glass_display_case", "wall_shelf"], "centre": "none", "window": "waiting", "back": "none", "frames": false},
	"parts": {"floor": "Concrete047A", "light": "panel", "counter": ["shop_counter", "shop_counter"], "till": true, "behind": ["pegboard_wall", "wall_shelf", "wall_shelf"], "board": false, "walls": ["wall_shelf", "pegboard_wall", "wall_shelf"], "centre": "rows", "window": "display", "back": "stock", "frames": false},
}
const ALT_FLOOR := {"Tiles074": "Tiles143", "Tiles143": "Tiles141", "Tiles141": "Tiles074", "Carpet012": "Tiles012", "Concrete047A": "Tiles074", "WoodFloor034": "WoodFloor051", "WoodFloor051": "WoodFloor034", "Tiles012": "Tiles143"}
const WARM := ["bar", "diner"]
const WALL_TINTS := [Color(0.86, 0.82, 0.7), Color(0.78, 0.8, 0.74), Color(0.84, 0.76, 0.66), Color(0.72, 0.78, 0.8), Color(0.88, 0.84, 0.76), Color(0.8, 0.72, 0.62)]
const SHORT := {"pawn": "PAWN", "cash": "CHECKS CASHED", "liquor": "LIQUOR", "bodega": "MARKET", "diner": "DINER", "takeout": "TO GO",
	"bar": "COCKTAILS", "laundry": "COIN LAUNDRY", "barber": "BARBER", "tattoo": "TATTOO", "thrift": "THRIFT", "botanica": "BOTANICA",
	"tyres": "TIRES", "parts": "AUTO PARTS", "panaderia": "PANADERIA", "phones": "PHONE REPAIR"}

var foot := {}      # base -> Vector2(w, d)
var tall := {}      # base -> height
var occ: Array = [] # [x0, z0, x1, z1, height]
var keep: Array = [] # [x0, z0, x1, z1] floor that stays free
var X0 := 0.0; var X1 := 0.0; var ZF := 0.0; var ZB := 0.0; var ZBp := 0.0; var F := 0.0
var rr: R
var HC := 0.0             # the room's ceiling height
var CON := {}             # the building's contract
var wall_items: Array = [] # [wall, s0, s1, y0, y1]: everything hung on a wall so far
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
	var asg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(D + "assignment_grt.json"))
	var n := 0
	for e: Dictionary in asg.rooms:
		if String(e.built) != "": continue
		if not only.is_empty() and not only.has(String(e.id)): continue
		if not kinds.is_empty() and not kinds.has(String(e.kind)): continue
		if n >= limit: break
		await _room(e, rc[String(e.model)])
		n += 1
	var fo := FileAccess.open(D + "rooms_grt_report.json", FileAccess.WRITE)
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
## a customer should not see the same thing over and over (Yasin, to the strip rooms: "shops filled with vending
## machines"): at most this many of one kind in a room
const LIMIT := {"brochure_rack": 2, "card_spinner": 2, "vending_soda": 1, "vending_snack": 1}
var counts := {}
func _put(base: String, x: float, z: float, yaw := 0.0, use_keep := true) -> bool:
	if LIMIT.has(base) and int(counts.get(base, 0)) >= int(LIMIT[base]): return false
	if base == "drinks_fridge" and not FOOD.has(cur_kind) and int(counts.get(base, 0)) >= 4: return false
	var f := _fp(base, yaw)
	var x0 := x - f.x * 0.5; var x1 := x + f.x * 0.5; var z0 := z - f.y * 0.5; var z1 := z + f.y * 0.5
	if not _free(x0, z0, x1, z1, use_keep): return false
	rr.prop(base, x, z, yaw)
	occ.append([x0, z0, x1, z1, float(tall.get("prop_" + base, 1.0))])
	counts[base] = int(counts.get(base, 0)) + 1
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

const FOOD := ["liquor", "bodega", "diner", "takeout", "bar", "panaderia"]
var cur_kind := ""
var mix := false
var _mixn := 0
## chairs that never matched (gritty rooms with "mix"): every other seat is the other kind
func _ch(a: String) -> String:
	_mixn += 1
	if not mix: return a
	return ("side_chair" if a == "cafe_chair" else "cafe_chair") if _mixn % 3 == 0 else a
func _table2(x: float, z: float) -> Array:
	return [["cafe_table", x, z, 0.0], [_ch("cafe_chair"), x - 0.58, z, 90.0], [_ch("cafe_chair"), x + 0.58, z, -90.0]]
func _table4(x: float, z: float) -> Array:
	return [["restaurant_table", x, z, 0.0], [_ch("side_chair"), x - 0.3, z - 0.62, 0.0], [_ch("side_chair"), x + 0.3, z - 0.62, 0.0], [_ch("side_chair"), x - 0.3, z + 0.62, 180.0], [_ch("side_chair"), x + 0.3, z + 0.62, 180.0]]

## ------------------------------------------------------------------------------------------------ one room
func _room(e: Dictionary, c: Dictionary) -> void:
	var kind := String(e.kind)
	var K: Dictionary = (KINDS.get(kind, KINDS.cash) as Dictionary).duplicate(true)
	var hv := _h(String(e.id))
	if hv % 2 == 1: K.floor = ALT_FLOOR.get(String(K.floor), String(K.floor))
	var wl: Array = K.walls
	if wl.size() > 1:
		var rot := hv % wl.size()
		K.walls = wl.slice(rot) + wl.slice(0, rot)
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
	var zb_bld := float(fl.box_min[2])
	ZB = maxf(zb_bld, ZF - float(e.get("depth", 16.0)))   # very deep buildings: the shop takes the front 16 m (a tyre shop: its counter office only)
	var H := F + minf(float(fl.clear_h), 4.0)
	HC = H
	var depth := ZF - ZB; var width := X1 - X0
	var back := String(K.back)
	var ZP := ZB
	if depth >= 9.0 and back != "none": ZP = ZB + (2.9 if back == "kitchen" else 2.3)
	ZBp = ZP
	occ = []; keep = []; wall_items = []; CON = c; counts = {}; cur_kind = kind
	mix = bool(K.get("mix", false)); _mixn = hv % 3
	seed(hv)     # the wear below is the same on every rebuild
	rr = R.new(id, F)
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
	if absf(dx - (X0 + X1) * 0.5) < 0.8 and (hv / 7) % 2 == 1: staff_x = X0 + 0.75    # a door in the middle: either end
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
			if ZBp <= ZB + 0.01 and _over_opening("back", bx + f.x * 0.5, f.x * 0.5, float(tall.get("prop_" + p, 2.0))): bx += 0.25; continue
			if _put(p, bx + f.x * 0.5, ZBp + f.y * 0.5 + 0.09, 0.0):
				if float(tall.get("prop_" + p, 2.0)) < 1.5: low_x = bx + f.x * 0.5
				bx += f.x + 0.05; break
			bx += 0.25
	if bool(K.get("board", false)):
		var mx := low_x if low_x > -900.0 else cx
		var free_board := true
		for o: Array in occ:
			if float(o[4]) > 1.7 and mx > float(o[0]) - 0.85 and mx < float(o[2]) + 0.85 and float(o[1]) < ZBp + 0.6: free_board = false
		if free_board: _wall_put("menu_board", "back" if ZBp <= ZB + 0.01 else "", mx, mx, ZBp + 0.06, 0.0, 1.75, 0.93, 0.85, 1.3)
	# ---- the side walls: the shop's goods / seats along them (low things only under the side windows)
	var sidewin := _side_windows(c)
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
			for xx: float in _steps(X0 + 0.9, X1 - 0.9, 2.2): _put("display_table", xx, wz - 0.45, 0.0)
		"mannequins":
			for xx: float in _steps(X0 + 0.7, X1 - 0.7, 1.3): _put("mannequin", xx, wz - 0.35, 0.0)
		"cases":
			for xx: float in _steps(X0 + 0.9, X1 - 0.9, 2.0): _put("glass_display_case", xx, wz - 0.35, 180.0)
		"waiting":     # clear of the corners: a side-wall seat must keep its leg room
			for xx: float in _steps(X0 + 1.7, X1 - 1.7, 2.4): _put("waiting_bench", xx, wz - 0.32, 180.0)
		"produce":
			for xx: float in _steps(X0 + 1.0, X1 - 1.0, 2.3): _put("produce_stand", xx, wz - 0.4, 0.0)
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
		"folding":     # laundromat: folding tables down the middle, a bench at each end to wait on
			for zz: float in _steps(mz0 + 0.5, mz1 - 0.5, 2.0):
				var t2 := 0
				for xx: float in _steps(IX0 + 0.75, IX1 - 0.75, 2.4):
					_put("display_table" if t2 % 2 == 0 else "waiting_bench", xx, zz, 0.0); t2 += 1
		"benches":
			for zz: float in _steps(mz0 + 0.4, mz1 - 0.4, 2.4):
				for xx: float in _steps(IX0 + 0.74, IX1 - 0.74, 2.6): _put("waiting_bench", xx, zz, 0.0)
	# ---- dressing: plants in the front corners, a bin by the counter end, prints on the bare walls
	_put("potted_plant", X0 + 0.3, ZF - 0.3); _put("potted_plant", X1 - 0.3, ZF - 0.3)
	# ---- the staff stool at the counter's staff end (people stand all day here; the owner sits)
	var stx := clampf(staff_x, cx - cw * 0.5 + 0.3, cx + cw * 0.5 - 0.3)
	var behind_tall := false        # never in front of the goods on the back wall (a stool hides the pegboard)
	for o5: Array in occ:
		if float(o5[4]) > 1.3 and float(o5[1]) < ZBp + 0.8 and stx > float(o5[0]) - 0.6 and stx < float(o5[2]) + 0.6: behind_tall = true
	if not behind_tall: _put("bar_stool" if kind in ["bar", "diner", "takeout", "pawn", "liquor", "bodega"] else "office_chair", stx, zc - cd * 0.5 - 0.35, 0.0, false)
	# ---- gritty clutter (a first draft already looks used): the lottery / card rack and the bin at the counter end,
	# a second bin and a stack of leaflets by the door, a bench or chairs to wait on, more stock where there is wall
	if kind in ["liquor", "bodega", "cash", "pawn"]: _put("card_spinner", cx + cw * 0.5 + 0.55, zc + cd * 0.5 + 0.55)
	_put("indoor_bin", dx + (1.25 if dx < (X0 + X1) * 0.5 else -1.25), ZF - 0.35)
	if kind in ["cash", "barber", "tattoo", "laundry", "tyres", "takeout"]:
		_put("brochure_rack", dx + (-1.2 if dx < (X0 + X1) * 0.5 else 1.2), ZF - 0.4, 180.0)
		for zz2: float in _steps(ZBp + 2.6, ZF - 2.2, 1.7): _put(_ch("side_chair"), X1 - 0.35 if dx < (X0 + X1) * 0.5 else X0 + 0.35, zz2, -90.0 if dx < (X0 + X1) * 0.5 else 90.0)
	if kind in ["bodega", "liquor", "takeout", "laundry"]: _put("chest_freezer" if kind != "laundry" else "waiting_bench", (X0 + X1) * 0.5, ZF - 2.0, 0.0)
	if kind in ["pawn", "thrift", "parts", "botanica", "tyres"]:
		for zz3: float in _steps(ZBp + 1.0, ZF - 1.6, 1.1): _put("wall_shelf", X0 + 0.17, zz3, 90.0); _put("wall_shelf", X1 - 0.17, zz3, -90.0)
	# hand-written notices taped on the bare walls (poster cases: NO CHECKS, RESTROOM FOR CUSTOMERS ONLY, ...)
	for side3: Array in [[X0, 90.0, "left"], [X1, -90.0, "right"]]:
		var wx3 := float(side3[0]); var inn3 := 1.0 if float(side3[1]) > 0.0 else -1.0
		for zz4: float in _steps(ZBp + 0.9, ZF - 0.8, 1.5):
			if _under_window(sidewin, String(side3[2]), zz4 - 0.5, zz4 + 0.5, 1.4): continue
			var blk := false
			for o4: Array in occ:
				if float(o4[4]) > 1.2 and zz4 > float(o4[1]) - 0.5 and zz4 < float(o4[3]) + 0.5 and absf((float(o4[0]) + float(o4[2])) * 0.5 - wx3) < 1.0: blk = true
			if not blk: _wall_put("poster_case", String(side3[2]), zz4, wx3 + inn3 * 0.04, zz4, float(side3[1]), 1.15, 1.2, 0.42, 0.85)
	# (no bin at the counter end: it stood in the middle of the floor - "the bin is in the middle of the room")
	if kind in ["office", "pharmacy", "souvenir", "venue", "gallery"]: _put("brochure_rack", dx + (1.3 if dx < (X0 + X1) * 0.5 else -1.3), ZF - 1.9, 180.0)
	if bool(K.frames) or String(K.walls[0]) in ["frames_only", "poster_wall"]:
		var mount := "poster_case" if String(K.walls[0]) == "poster_wall" else "gallery_frame"
		for side2: Array in [[X0, 90.0, "left"], [X1, -90.0, "right"]]:
			var wx2 := float(side2[0]); var inn2 := 1.0 if float(side2[1]) > 0.0 else -1.0
			for zz: float in _steps(ZBp + 1.2, ZF - 1.0, 1.6 if mount == "gallery_frame" else 1.4):
				if _under_window(sidewin, String(side2[2]), zz - 0.5, zz + 0.5, 1.2): continue
				var blocked := false
				for o: Array in occ:
					if float(o[4]) > 1.25 and zz > float(o[1]) - 0.4 and zz < float(o[3]) + 0.4 and absf((float(o[0]) + float(o[2])) * 0.5 - wx2) < 1.0: blocked = true
				if not blocked: _wall_put(mount, String(side2[2]), zz, wx2 + inn2 * 0.04, zz, float(side2[1]), 1.35, 1.2 if mount == "poster_case" else 0.9, 0.42 if mount == "poster_case" else 0.36, 1.0)
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
			if nl >= 3: break
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
	# ---- gritty wear: the floor worn grey where people stand and walk, scuffs along the walls, cracked tiles
	for k3 in 6: rr.dec.add(14, Vector2(randf_range(X0 + 0.6, X1 - 0.6), randf_range(ZBp + 0.6, ZF - 0.6)), randf_range(0, 180), randf_range(0.8, 1.8), randf_range(0.8, 1.8), fy, Color(1, 1, 1, 0.45), 0.004)
	for k4 in 4: rr.dec.add(0, Vector2(randf_range(X0 + 0.5, X1 - 0.5), randf_range(ZBp + 0.5, ZF - 0.5)), randf_range(0, 180), 0.9, 0.9, fy, Color(0.4, 0.4, 0.4, 0.5), 0.004)
	rr.dec.add(14, Vector2(dx, ZF - 0.5), 0.0, dw + 0.6, 1.0, fy, Color(1, 1, 1, 0.6), 0.004)     # the doormat that wore through
	# _stock(hv)     # off since the kit indoor set dd8d53a (18 Nov): its shelves come stocked
	# ---- the shop's own name on the building's boards
	for sg: Dictionary in e.signs:
		var txt := String(e.name).to_upper() if float(sg.w) >= 2.4 else String(SHORT.get(kind, "SHOP"))
		rr.sign(c, String(sg.facade), float(sg.along), txt, String(e.style), String(e.get("font", "Overpass")))
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

## ------------------------------------------------------------------------------------------------ stock on the shelves
## the kit's shelves come empty: boxes, bottles and books of the shop's goods on every level (levels measured from the
## models: wall shelf 0.30 / 0.74 / 1.18 / 1.62, gondola 0.40 / 0.84 / 1.28 both faces, bookcase every 0.36 from 0.30),
## crammed, uneven, with the odd gap where something sold out; three faded colours (3 draws a room)
const SHELF_LEVELS := {"prop_wall_shelf": [[0.30, 0.74, 1.18, 1.62], [-0.12, 0.12]], "prop_gondola_aisle": [[0.40, 0.84, 1.28], [-0.25, -0.04, 0.04, 0.25]],
	"prop_bookcase": [[0.30, 0.66, 1.02, 1.38, 1.74], [-0.12, 0.12]]}
func _stock(hv: int) -> void:
	rr.plain("stock_a", Color(0.55, 0.22, 0.18), 0.7)
	rr.plain("stock_b", Color(0.78, 0.66, 0.42), 0.75)
	rr.plain("stock_c", Color(0.26, 0.34, 0.46), 0.7)
	var mats := ["stock_a", "stock_b", "stock_c", "stock_b"]
	var rng := RandomNumberGenerator.new(); rng.seed = hv
	var props: Dictionary = rr._props
	for base: String in SHELF_LEVELS:
		if not props.has(base): continue
		var lv: Array = SHELF_LEVELS[base][0]; var zr: Array = SHELF_LEVELS[base][1]
		var half := _fp(base.trim_prefix("prop_"), 0.0).x * 0.5 - 0.06
		for t: Transform3D in props[base]:
			var yaw_q := int(round(rad_to_deg(t.basis.get_euler().y) / 90.0)) % 2
			for li in lv.size():
				var y0 := float(lv[li]) + 0.005
				var room_h := (float(lv[li + 1]) - float(lv[li]) - 0.08) if li + 1 < lv.size() else 0.32
				for zi in range(0, zr.size(), 2):
					var z0 := float(zr[zi]); var z1 := float(zr[zi + 1])
					var x := -half
					while x < half - 0.1:
						var bw := rng.randf_range(0.1, 0.34)
						if rng.randf() < 0.09: x += rng.randf_range(0.2, 0.45); continue      # sold out
						bw = minf(bw, half - x)
						var bh := rng.randf_range(0.45, 0.95) * room_h
						var bd := rng.randf_range(0.6, 1.0) * (z1 - z0)
						var lc := Vector3(x + bw * 0.5, y0 + bh * 0.5, (z0 + z1) * 0.5)
						var wc := t * lc
						var sz := Vector3(bw - 0.015, bh, bd) if yaw_q == 0 else Vector3(bd, bh, bw - 0.015)
						rr.box(mats[rng.randi() % mats.size()], wc, sz)
						x += bw + rng.randf_range(0.005, 0.04)

## hang a wall prop (frame, notice, menu board) only where it really fits (Yasin 18 Nov: "many on the wall props overlap,
## some of them are on windows, some of them are inside the ceiling"): its top 8 cm under the ceiling (lowered to fit,
## never under min_lift), clear of every door and window of that wall (any height: the high side windows of the trade
## rows too) and of everything already hung there. wall = "front" / "back" / "left" / "right" ("" = an inner
## partition: no openings), s = position along the wall (x on front / back, z on the sides). false when it does not fit.
func _wall_put(base: String, wall: String, s: float, x: float, z: float, yaw: float, lift: float, h: float, half: float, min_lift: float) -> bool:
	# at most 2 decorations on a wall and 6 in the room ("you just filled every wall with paintings")
	if base in ["gallery_frame", "poster_case", "menu_board"]:
		var on_wall := 0; var in_room := 0
		for it0: Array in wall_items:
			if bool(it0[5]): in_room += 1
			if bool(it0[5]) and String(it0[0]) == wall: on_wall += 1
		if on_wall >= 2 or in_room >= 6: return false
	var y0 := minf(lift, HC - F - 0.08 - h)
	if y0 < min_lift: return false
	var y1 := y0 + h
	if wall != "":
		for o: Dictionary in CON.get("openings", []):
			if int(o.floor) != 0 or String(o.facade) != wall: continue
			if absf(s - float(o.along)) < half + float(o.w) * 0.5 + 0.12 and F + y0 < float(o.y1) + 0.08 and F + y1 > float(o.y0) - 0.08: return false
	for o2: Array in occ:      # nothing standing against that stretch of wall (a fridge, a freezer, a shelf)
		var ox := (float(o2[0]) + float(o2[2])) * 0.5; var oz := (float(o2[1]) + float(o2[3])) * 0.5
		if wall == "left" or wall == "right":
			if absf(ox - x) < 0.95 and s - half < float(o2[3]) and s + half > float(o2[1]): return false
		elif absf(oz - z) < 0.95 and s - half < float(o2[2]) and s + half > float(o2[0]): return false
	for it: Array in wall_items:
		if String(it[0]) == wall and wall != "" and s - half < float(it[2]) + 0.15 and s + half > float(it[1]) - 0.15 and y0 < float(it[4]) + 0.1 and y1 > float(it[3]) - 0.1: return false
	wall_items.append([wall, s - half, s + half, y0, y1, base in ["gallery_frame", "poster_case", "menu_board"]])
	rr.prop(base, x, z, yaw, y0)
	return true

## true when an item of half width `half` and height `h` at `s` along the outer wall `wall` covers one of its openings
## (a back door, a window: the room records them, the building's contract has them)
func _over_opening(wall: String, s: float, half: float, h: float) -> bool:
	for o: Dictionary in CON.get("openings", []):
		if int(o.floor) != 0 or String(o.facade) != wall: continue
		if absf(s - float(o.along)) < half + float(o.w) * 0.5 + 0.1 and float(o.y0) - F < h: return true
	return false
