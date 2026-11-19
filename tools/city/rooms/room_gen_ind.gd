extends SceneTree
## INDUSTRIAL rooms (18 Nov, claude/grow-industrial; Yasin: "do out and indoors together ... i want the shops to look
## different"). A copy of tools/city/rooms/room_gen.gd (the shared generator is not edited) with the industrial zone's
## own kinds and character: bare and worn, functional, nothing decorative. Floors are sealed concrete or quarry tile,
## the ceilings drop-in panels, the light comes from cool fluorescent strips, and the fittings are steel shelving,
## pegboard, filing cabinets (stocked shelving: the kit's indoor props of dd8d53a; Yasin 18 Nov: "most shelves are empty"), a workbench behind the parts counters, a soda machine for the drivers, stock on the floor
## and the notices board. Only the places of interiors/assignment_ind.json are built (tools/city/rooms/assign_ind.py),
## saved as interiors/rooms/g_ind_<...>.scn; no other room is touched.
##   xvfb-run -a godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/rooms/room_gen_ind.gd -- [--only=ID,ID]
## then: interiors/rooms/check_rooms.gd (0 problems), tools/city/rooms/gen_shots.gd (pictures).
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")
const D := "res://map_dc/coronado/city_kit/interiors/"
const MAN := "res://assets/coronado_kit/props/"

## per kind: floor texture, light (pendant / panel), the counter row, what stands behind it, the side walls' items,
## the middle of the room, the window zone, back of house (kitchen / stock / none), extras
const KINDS := {
	"freight_office": {"floor": "Concrete047A", "light": "strip", "counter": ["shop_counter", "shop_counter"], "till": false, "behind": ["office_desk", "filing_cabinet", "filing_cabinet"], "board": true, "walls": ["waiting_bench", "vending_soda", "filing_cabinet"], "centre": "none", "window": "waiting", "back": "office", "frames": true, "stock": ["indoor_bin"], "extras": ["potted_plant", "indoor_bin", "drinks_fridge", "brochure_rack", "waiting_bench", "filing_cabinet", "potted_plant"]},
	"trade_counter": {"floor": "Concrete047A", "light": "strip", "counter": ["shop_counter", "shop_counter"], "till": true, "behind": ["pegboard_wall", "pharmacy_shelf", "grocery_shelf"], "board": false, "walls": ["grocery_shelf", "wall_shelf", "pegboard_wall", "pharmacy_shelf"], "centre": "rows", "window": "display", "back": "stock", "frames": true, "stock": ["cone_28in", "channelizer_drum"], "extras": ["display_table", "cone_28in", "channelizer_drum", "indoor_bin", "potted_plant", "wall_shelf"]},
	"parts_counter": {"floor": "Concrete047A", "light": "strip", "counter": ["shop_counter"], "till": true, "behind": ["workbench", "pegboard_wall", "pharmacy_shelf"], "board": false, "walls": ["wall_shelf", "drinks_fridge", "grocery_shelf"], "centre": "none", "window": "waiting", "back": "none", "frames": true, "stock": ["channelizer_drum", "propane_cylinder_100lb"], "extras": ["display_table", "propane_cylinder_100lb", "cone_18in", "cone_18in", "indoor_bin", "waiting_bench", "vending_snack"]},
	"permits": {"floor": "Tiles012", "light": "strip", "counter": ["shop_counter", "shop_counter"], "till": false, "behind": ["office_desk", "filing_cabinet", "filing_cabinet"], "board": true, "walls": ["waiting_bench", "brochure_rack", "vending_snack"], "centre": "benches", "window": "brochures", "back": "office", "frames": true, "stock": ["cone_28in"], "extras": ["drinking_fountain", "potted_plant", "indoor_bin", "brochure_rack", "waiting_bench", "filing_cabinet"]},
	"workwear": {"floor": "Concrete047A", "light": "strip", "counter": ["checkout_counter"], "till": false, "behind": ["shoe_wall", "pharmacy_shelf"], "board": false, "walls": ["garment_rail", "shoe_wall", "grocery_shelf"], "centre": "racks", "window": "mannequins", "back": "stock", "frames": true, "stock": [], "extras": ["clothes_rack", "shoe_bench", "mannequin", "display_table", "fitting_room", "indoor_bin", "potted_plant"]},
	"fish_counter": {"floor": "Tiles143", "light": "strip", "counter": ["chest_freezer", "shop_counter", "chest_freezer"], "till": true, "behind": ["drinks_fridge", "grocery_shelf"], "board": true, "walls": ["chest_freezer", "drinks_fridge"], "centre": "table4", "window": "table2", "back": "kitchen", "frames": true, "stock": ["ice_chest"], "extras": ["ice_chest", "chest_freezer", "indoor_bin", "potted_plant", "drinks_fridge"]},
	"sales_office": {"floor": "Carpet012", "light": "strip", "counter": ["shop_counter"], "till": false, "behind": ["office_desk", "filing_cabinet"], "board": false, "walls": ["filing_cabinet", "waiting_bench"], "centre": "none", "window": "waiting", "back": "none", "frames": true, "stock": ["ice_chest"], "extras": ["potted_plant", "filing_cabinet", "indoor_bin", "drinks_fridge", "brochure_rack"]},
	"broker": {"floor": "WoodFloor051", "light": "strip", "counter": ["shop_counter"], "till": false, "behind": ["office_desk", "filing_cabinet", "filing_cabinet"], "board": true, "walls": ["brochure_rack", "waiting_bench", "filing_cabinet"], "centre": "none", "window": "display", "back": "office", "frames": true, "stock": [], "extras": ["display_table", "lifering_stand", "potted_plant", "indoor_bin", "brochure_rack", "waiting_bench"]},
	"diner": {"floor": "Tiles074", "light": "strip", "counter": ["bar_counter", "bar_counter"], "stools": true, "till": false, "behind": ["kitchen_line", "soda_fountain"], "board": true, "walls": ["booth"], "centre": "table4", "window": "table2", "back": "kitchen", "frames": true, "stock": ["vending_soda"], "extras": ["vending_soda", "indoor_bin", "potted_plant", "drinks_fridge"]},
	"canteen": {"floor": "Tiles141", "light": "strip", "counter": ["shop_counter", "soda_fountain"], "till": true, "behind": ["kitchen_line", "drinks_fridge"], "board": true, "walls": ["drinks_fridge", "booth"], "centre": "table4", "window": "table2", "back": "kitchen", "frames": true, "stock": ["vending_snack"], "extras": ["vending_soda", "indoor_bin", "drinks_fridge", "potted_plant"]},
	"taproom": {"floor": "Concrete047A", "light": "strip", "counter": ["bar_counter", "bar_counter"], "stools": true, "till": false, "behind": ["beer_taps", "drinks_fridge"], "board": true, "walls": ["booth"], "centre": "table4", "window": "table2", "back": "stock", "frames": true, "stock": [], "extras": ["indoor_bin", "potted_plant", "drinks_fridge"]},
	"uniform": {"floor": "Tiles143", "light": "strip", "counter": ["laundry_counter"], "till": false, "behind": ["garment_rail", "garment_rail"], "board": false, "walls": ["washer", "dryer"], "centre": "none", "window": "waiting", "back": "none", "frames": true, "stock": ["indoor_bin"], "extras": ["garment_rail", "waiting_bench", "indoor_bin", "potted_plant", "garment_rail"]},
}
const WARM := []     # nothing warm and plastered in the industrial zone: drop-in ceilings everywhere
const WALL_TINTS := [Color(0.80, 0.83, 0.78), Color(0.84, 0.84, 0.82), Color(0.86, 0.84, 0.76), Color(0.76, 0.8, 0.82), Color(0.82, 0.8, 0.76)]   # institutional greens, greys, nicotine cream
const SHORT := {"freight_office": "FREIGHT", "trade_counter": "SUPPLY", "parts_counter": "PARTS", "permits": "PERMITS", "workwear": "WORKWEAR",
	"fish_counter": "FISH", "sales_office": "SEAFOOD", "broker": "BOATS", "diner": "DINER", "canteen": "CANTEEN", "uniform": "LINEN", "taproom": "TAPROOM"}

var foot := {}      # base -> Vector2(w, d)
var tall := {}      # base -> height
var occ: Array = [] # [x0, z0, x1, z1, height]
var keep: Array = [] # [x0, z0, x1, z1] floor that stays free
var X0 := 0.0; var X1 := 0.0; var ZF := 0.0; var ZB := 0.0; var ZBp := 0.0; var F := 0.0
var rr: R
var report: Array = []
var cnt := {}      # props placed per type in this room
## the combined checker's "repeat" rule (Yasin 19 Nov: a customer sees the same thing over and over): at most this many
const CAP := {"vending_soda": 1, "vending_snack": 1, "card_spinner": 2, "brochure_rack": 2, "drinks_fridge": 4}

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
	var asg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(D + "assignment_ind.json"))
	var n := 0
	for e: Dictionary in asg.rooms:
		if String(e.built) != "": continue
		if not only.is_empty() and not only.has(String(e.id)): continue
		if not kinds.is_empty() and not kinds.has(String(e.kind)): continue
		if n >= limit: break
		await _room(e, rc[String(e.model)])
		n += 1
	var fo := FileAccess.open(D + "rooms_gen_ind_report.json", FileAccess.WRITE)
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
	if CAP.has(base) and int(cnt.get(base, 0)) >= int(CAP[base]): return false
	var f := _fp(base, yaw)
	var x0 := x - f.x * 0.5; var x1 := x + f.x * 0.5; var z0 := z - f.y * 0.5; var z1 := z + f.y * 0.5
	if not _free(x0, z0, x1, z1, use_keep): return false
	rr.prop(base, x, z, yaw)
	occ.append([x0, z0, x1, z1, float(tall.get("prop_" + base, 1.0))])
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
	occ.append([b[0], b[1], b[2], b[3], ht])
	return true

func _table2(x: float, z: float) -> Array:
	return [["cafe_table", x, z, 0.0], ["cafe_chair", x - 0.58, z, 90.0], ["cafe_chair", x + 0.58, z, -90.0]]
func _table4(x: float, z: float) -> Array:
	return [["restaurant_table", x, z, 0.0], ["side_chair", x - 0.3, z - 0.62, 0.0], ["side_chair", x + 0.3, z - 0.62, 0.0], ["side_chair", x - 0.3, z + 0.62, 180.0], ["side_chair", x + 0.3, z + 0.62, 180.0]]

## ------------------------------------------------------------------------------------------------ one room
func _room(e: Dictionary, c: Dictionary) -> void:
	var kind := String(e.kind)
	var K: Dictionary = KINDS.get(kind, KINDS.freight_office)
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
	ZB = maxf(zb_bld, ZF - 16.0)                         # very deep buildings: the shop takes the front 16 m
	var H := F + minf(float(fl.clear_h), 4.0)
	var depth := ZF - ZB; var width := X1 - X0
	var back := String(K.back)
	var ZP := ZB
	if depth >= 9.0 and back != "none": ZP = ZB + (2.9 if back == "kitchen" else 2.3)
	ZBp = ZP
	occ = []; keep = []; cnt = {}
	rr = R.new(id, F)
	seed(_h(id))        # the wear scatter below is the same on every run
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
	rr.plain("light_panel", Color(0.93, 0.98, 1.0), 0.3, 4.0)
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
	# every other public door inside this room keeps its swing free too (a canteen behind both of a building's doors)
	for o2: Dictionary in c.openings:
		if int(o2.floor) == 0 and String(o2.facade) == "front" and (String(o2.region) == "O_shopdoor" or String(o2.region) == "O_civic_door"):
			var oa := float(o2.along); var ow := float(o2.w)
			if oa > X0 and oa < X1 and absf(oa - dx) > 0.6: keep.append([oa - ow * 0.5 - 0.3, ZF - 1.7, oa + ow * 0.5 + 0.3, ZF])
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
		# the side walls' goods start behind the window zone (seats / displays there), so every shelf can be walked up to
		var z := ZF - (1.7 if String(K.window) != "none" else 0.45); var k := 0
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
		"waiting":
			for xx: float in _steps(X0 + 1.0, X1 - 1.0, 2.4): _put("waiting_bench", xx, wz - 0.32, 180.0)
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
					# the kit's gondola is stocked on both faces since the indoor props of dd8d53a
					_put("gondola_aisle", xx, zz, 90.0)
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
	# ---- industrial clutter: the stock that does not fit on a shelf stands on the floor along the walls, a second
	# the floor stock is what the place sells or uses (cones, drums, gas bottles, ice chests, a vending machine)
	var stock: Array = K.get("stock", [])
	var sz2 := ZBp + 1.6
	for st: String in stock:
		var placed := false
		for side3: Array in [[X0, 90.0], [X1, -90.0]]:
			if placed: break
			var f3 := _fp(st, float(side3[1])); var inn3 := 1.0 if float(side3[1]) > 0.0 else -1.0
			var zz3 := sz2
			while zz3 < ZF - 1.8 and not placed:
				placed = _put(st, float(side3[0]) + inn3 * (f3.x * 0.5 + 0.05), zz3, float(side3[1]))
				zz3 += 0.4
	# ---- polish (Yasin 18 Nov: "lots of props ... think like an interior designer and the customer"): what this
	# kind of place still needs, set on free floor along the walls (side walls front to back, then the back wall),
	# facing into the room; low things only under side windows; doors, queues and aisles stay free (keep)
	for it2: String in K.get("extras", []):
		var placed2 := false
		var f4 := _fp(it2, 90.0); var ht2 := float(tall.get("prop_" + it2, 1.0))
		for side4: Array in [[X0, 90.0, "left"], [X1, -90.0, "right"]]:
			if placed2: break
			var inn4 := 1.0 if float(side4[1]) > 0.0 else -1.0
			var zz4 := ZF - 1.9
			while zz4 > ZBp + 0.5 and not placed2:
				if not _under_window(sidewin, String(side4[2]), zz4 - f4.y * 0.5, zz4 + f4.y * 0.5, ht2):
					placed2 = _put(it2, float(side4[0]) + inn4 * (f4.x * 0.5 + 0.05), zz4, float(side4[1]))
				zz4 -= 0.35
		if not placed2:
			var f5 := _fp(it2, 0.0); var xx5 := X0 + 0.4 + f5.x * 0.5
			while xx5 < X1 - 0.4 - f5.x * 0.5 and not placed2:
				placed2 = _put(it2, xx5, ZBp + f5.y * 0.5 + 0.06, 0.0)
				xx5 += 0.35
	# ---- dressing: plants in the front corners, a bin by the counter end, prints on the bare walls
	_put("potted_plant", X0 + 0.3, ZF - 0.3); _put("potted_plant", X1 - 0.3, ZF - 0.3)
	if kind in ["office", "pharmacy", "souvenir", "venue", "gallery"]: _put("brochure_rack", dx + (1.3 if dx < (X0 + X1) * 0.5 else -1.3), ZF - 1.9, 180.0)
	if bool(K.frames) or String(K.walls[0]) in ["frames_only", "poster_wall"]:
		var mount := "poster_case"      # industrial: notice and safety boards, never gallery prints
		var n_deco := 1 if bool(K.get("board", false)) else 0
		for side2: Array in [[X0, 90.0, "left"], [X1, -90.0, "right"]]:
			var wx2 := float(side2[0]); var inn2 := 1.0 if float(side2[1]) > 0.0 else -1.0
			var on_wall := 0
			for zz: float in _steps(ZBp + 1.2, ZF - 1.0, 1.6 if mount == "gallery_frame" else 1.4):
				if on_wall >= 2 or n_deco >= 5: break       # the checker's "deco": 2 a wall, 6 a room
				if _under_window(sidewin, String(side2[2]), zz - 0.6, zz + 0.6, 99.0): continue   # high windows too
				var blocked := false
				for o: Array in occ:
					if float(o[4]) > 0.5 and zz > float(o[1]) - 0.5 and zz < float(o[3]) + 0.5 and absf((float(o[0]) + float(o[2])) * 0.5 - wx2) < 1.4: blocked = true
				if not blocked:
					rr.prop(mount, wx2 + inn2 * 0.04, zz, float(side2[1]), 1.35); on_wall += 1; n_deco += 1
	# ---- back of house
	if ZP > ZB + 0.01:
		var kx := X0 + 0.2
		var stuff: Array = ["kitchen_line", "grocery_shelf"] if back == "kitchen" else (["office_desk", "filing_cabinet", "filing_cabinet"] if back == "office" else ["grocery_shelf", "pharmacy_shelf", "grocery_shelf"])
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
			_strip(xx, zz, H)
			nl += 1
	if ZP > ZB + 0.01: _strip((X0 + X1) * 0.5, (ZB + ZP) * 0.5, H, 0.8)
	var day := OmniLight3D.new(); day.position = Vector3(dx, F + 1.9, ZF - 0.7); day.light_color = Color(0.86, 0.92, 1.0); day.light_energy = 0.8; day.omni_range = 5.0
	rr.lights.add_child(day)
	# ---- wear: the walk from the door to the counter and the queue (heavier than a high-street shop: boots, grit)
	for k3 in 6: rr.dec.add(14, Vector2(randf_range(X0 + 0.5, X1 - 0.5), randf_range(ZBp + 0.5, ZF - 0.6)), randf_range(0, 180), 1.4, 1.4, func(_x: float, _z: float) -> float: return F, Color(1, 1, 1, 0.35), 0.004)
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

## a fluorescent strip: a long thin emissive box flush with the ceiling and one cool, plain real light under it
func _strip(x: float, z: float, ceil_y: float, energy := 1.15) -> void:
	rr.box("light_panel", Vector3(x, ceil_y - 0.03, z), Vector3(1.5, 0.05, 0.16))
	var l := OmniLight3D.new(); l.position = Vector3(x, ceil_y - 0.2, z); l.light_color = Color(0.9, 0.96, 1.0); l.light_energy = energy
	l.omni_range = 5.5; l.omni_attenuation = 1.3; l.shadow_enabled = false
	rr.lights.add_child(l)

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
