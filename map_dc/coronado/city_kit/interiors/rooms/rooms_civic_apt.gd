extends SceneTree
## The civic band's and the apartment band's rooms (17 Nov, Yasin: "make civic band and apartment band indoors too ...
## work like an interior designer and look at it from a customers perspective"). Visuals only. Each room in its kit
## building's model frame; openings come from room_contracts.json (never typed by hand). Rules: the service point in
## view from the door, the first 1.5 m inside the door clear, queue space at every counter, staff side reachable,
## aisles >= 1 m, seats face the room or a window, back of house behind a partition lined up with the back door.
## Run with the real renderer: godot --path <preview> --rendering-method mobile -s <this>
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")
const RC := "res://map_dc/coronado/city_kit/interiors/room_contracts.json"
var rc := {}

func _init() -> void: _run.call_deferred()

func _run() -> void:
	rc = JSON.parse_string(FileAccess.get_file_as_string(RC)).models
	_library(); _city_hall(); _rec_centre(); _police()
	await _market(); await _laundromat(); await _bar(); await _corner_cafe()
	quit()

func _mats(r: R, floor_tex: String, floor_tile: float, wall_tint: Color, floor_tint := Color(1, 1, 1)) -> void:
	r.mat("wall", "PaintedPlaster017", 2.0, wall_tint)
	r.mat("ceil", "Plaster001", 2.0, Color(0.95, 0.94, 0.92))
	r.mat("floor", floor_tex, floor_tile, floor_tint)
	r.mat("door", "Wood058", 1.0, Color(0.55, 0.42, 0.3))
	r.plain("skirt", Color(0.16, 0.14, 0.12), 0.5)
	r.plain("pendant_shade", Color(0.08, 0.09, 0.08), 0.35)
	r.plain("pendant_cord", Color(0.05, 0.05, 0.05), 0.5)
	r.plain("bulb", Color(1.0, 0.85, 0.6), 0.3, 6.0)
	r.plain("light_panel", Color(1.0, 0.97, 0.9), 0.3, 3.5)

func _shell(r: R, model: String, X0: float, X1: float, ZB: float, ZF: float, F: float, H: float, ceil_key := "ceil", outer := {}) -> void:
	r.flat("floor", X0, ZB, X1, ZF, F); r.flat(ceil_key, X0, ZB, X1, ZF, H, false)
	r.walls4(rc[model], X0, X1, ZB, ZF, F, H, outer)

## a full-height partition along x at z, from x0 to x1, with a doorway [d0, d1] (2.2 m) and a closed leaf in it
func _partition_x(r: R, z: float, x0: float, x1: float, d0: float, d1: float, F: float, H: float, leaf := false) -> void:
	r.box("wall", Vector3((x0 + d0) * 0.5, (F + H) * 0.5, z), Vector3(d0 - x0, H - F, 0.12))
	r.box("wall", Vector3((d1 + x1) * 0.5, (F + H) * 0.5, z), Vector3(x1 - d1, H - F, 0.12))
	r.box("wall", Vector3((d0 + d1) * 0.5, (F + 2.2 + H) * 0.5, z), Vector3(d1 - d0, H - F - 2.2, 0.12))
	if leaf: r.solid_door("z", z, d0, d1, F, F + 2.2)

func _panels(r: R, xs: Array, zs: Array, H: float, col := Color(0.98, 0.97, 0.92), e := 1.0, rng := 5.5) -> void:
	for x: float in xs:
		for z: float in zs: r.pendant(x, z, H, 0.0, col, e, rng, true)

func _daylight(r: R, x: float, y: float, z: float, e := 0.9, rng := 7.0) -> void:
	var d := OmniLight3D.new(); d.position = Vector3(x, y, z); d.light_color = Color(0.86, 0.92, 1.0); d.light_energy = e; d.omni_range = rng
	r.lights.add_child(d)

## floor wear where people walk / queue / work: [x, z, w, d]; a long spot is laid as a chain of ~1.3 m patches
## (one decal stretched over 6 m shows its edge as a hard white mark)
func _wear(r: R, F: float, spots: Array) -> void:
	var fy := func(_x: float, _z: float) -> float: return F
	for s: Array in spots:
		var w := float(s[2]); var d := float(s[3]); var c := Vector2(float(s[0]), float(s[1]))
		var nx := maxi(1, ceili(w / 1.4)); var nz := maxi(1, ceili(d / 1.4))
		for ix in nx:
			for iz in nz:
				var p := c + Vector2((ix + 0.5) * w / nx - w * 0.5, (iz + 0.5) * d / nz - d * 0.5)
				var j := float((ix * 7 + iz * 13) % 5) * 0.06
				r.dec.add(14, p + Vector2(j, -j), 90.0 * float((ix + iz) % 2), w / nx * 1.15, d / nz * 1.15, fy, Color(1, 1, 1, 0.3 + j * 0.5), 0.004)

## ================================================================================================ CIVIC BAND
## ---- Crownado Public Library (civ_library 24 x 16, floor 0.3, one tall volume)
## From the door: the circulation desk turned toward you on the right, new arrivals and the local-history case on the
## left of the open axis, the stacks in rows behind them, reading tables under the front windows, a reading room and
## study desks at the right-hand windows, a newspaper corner, public computers on the back wall.
func _library() -> void:
	var r := R.new("cv_library", 0.3); r.place("v_ne", "library")
	_mats(r, "Carpet012", 2.0, Color(0.97, 0.94, 0.86), Color(0.62, 0.66, 0.74))
	r.mat("wains", "Wood058", 1.0, Color(0.58, 0.44, 0.3))
	var X0 := -11.7; var X1 := 11.7; var ZB := -7.62; var ZF := 7.45; var F := 0.3; var H := 4.9
	_shell(r, "civic/civ_library", X0, X1, ZB, ZF, F, H)
	# circulation desk: two counters, two staff chairs, the reserve shelf and files behind
	r.prop("shop_counter", 2.9, 3.6); r.prop("shop_counter", 4.72, 3.6)
	r.prop("cash_register", 2.6, 3.55, 180.0, 0.964)
	r.prop("office_chair", 2.6, 2.75, 0.0); r.prop("office_chair", 4.5, 2.75, 0.0)
	r.prop("bookcase", 3.8, 1.75, 0.0); r.prop("filing_cabinet", 5.3, 1.75, 0.0)
	r.prop("indoor_bin", 6.0, 3.6)
	# first things you pass, left of the axis: leaflets by the door, new arrivals, the local-history case, staff picks
	r.prop("brochure_rack", -1.7, 7.0, 180.0); r.prop("brochure_rack", 1.7, 7.0, 180.0)
	r.prop("card_spinner", 1.7, 5.0)
	r.prop("display_table", -2.6, 4.6, 90.0)
	r.prop("glass_display_case", -2.6, 2.4, 90.0)
	r.prop("display_table", -2.6, 0.4, 90.0)
	# stacks: three double-sided rows running front to back, aisles 1.8 m
	for rx: float in [-9.6, -7.0, -4.4]:
		for i in 7:
			var z := -5.5 + i * 1.02
			r.prop("bookcase", rx - 0.18, z, -90.0); r.prop("bookcase", rx + 0.18, z, 90.0)
	# wall cases: left wall between its windows, back wall left of the windows, right wall between its windows
	for z2: float in [-4.0, -2.95, -1.9, 1.25, 2.3, 3.35, -6.9]: r.prop("bookcase", X0 + 0.18, z2, 90.0)
	for x2: float in [-7.8, -6.8, -5.8, -4.8]: r.prop("bookcase", x2, ZB + 0.18, 0.0)
	for z3: float in [1.6, 2.6, 3.6, -2.0, -3.0]: r.prop("bookcase", X1 - 0.18, z3, -90.0)
	# reading tables under the front-left windows
	for tx: float in [-9.0, -6.0]:
		r.prop("restaurant_table", tx, 5.2)
		for cx: float in [-0.32, 0.32]:
			r.prop("side_chair", tx + cx, 4.55, 0.0); r.prop("side_chair", tx + cx, 5.85, 180.0)
	# the reading room on the right: two long tables, chairs both sides
	for tz: float in [-1.6, -4.6]:
		for tx2: float in [6.0, 7.2]: r.prop("restaurant_table", tx2, tz)
		for cx2: float in [5.7, 6.6, 7.5]:
			r.prop("side_chair", cx2, tz - 0.65, 0.0); r.prop("side_chair", cx2, tz + 0.65, 180.0)
	# study desks under the right-hand windows: the reader faces the window
	for wz: float in [0.0, -5.4]:
		r.prop("office_desk", X1 - 0.42, wz, -90.0); r.prop("office_chair", X1 - 1.05, wz, 90.0)
	# public computers on the back wall between its windows
	for dx: float in [4.6, 6.2, 10.6]:
		r.prop("office_desk", dx, ZB + 0.42, 0.0); r.prop("office_chair", dx, ZB + 1.05, 180.0)
	# the newspaper corner: a bench under the front-right windows facing the room, the papers on a low table
	r.prop("waiting_bench", 7.6, 7.12, 180.0); r.prop("display_table", 7.6, 6.0, 0.0)
	r.prop("side_chair", 6.5, 6.0, 90.0); r.prop("side_chair", 8.7, 6.0, -90.0)
	# art and notices where nothing stands in front
	for fx: float in [-4.8, 4.8, -7.6]: r.prop("gallery_frame", fx, ZF - 0.04, 180.0, 1.6)
	for fx2: float in [-1.2, 1.2]: r.prop("gallery_frame", fx2, ZB + 0.04, 0.0, 1.5)
	r.prop("poster_case", 0.0, ZB + 0.06, 0.0, 0.9)
	r.prop("potted_plant", -11.3, 7.05); r.prop("plant_potted_leafy", 11.25, 7.0); r.prop("plant_potted_leafy", -1.6, 5.4)
	r.prop("potted_plant", 7.5, -7.25); r.prop("plant_potted_leafy", -3.4, -7.15)
	r.prop("indoor_bin", 2.4, 5.8); r.prop("indoor_bin", 9.4, -6.9); r.prop("recycling_receptacle", -5.0, 6.9)
	r.box("wains", Vector3(0, F + 0.45, ZB + 0.015), Vector3(X1 - X0, 0.9, 0.03))
	_panels(r, [-8.0, -4.0, 0.0, 4.0, 8.0], [-5.0, -1.0, 3.0], H, Color(1.0, 0.96, 0.88), 1.4, 7.0)
	_daylight(r, -5.0, 2.2, 6.6); _daylight(r, 6.0, 2.2, 6.6)
	_wear(r, F, [[0, 5.5, 1.6, 3.0], [0, 2.0, 1.4, 3.0], [3.8, 4.5, 3.0, 1.0], [-8.3, -1.6, 1.2, 6.0], [-5.7, -1.6, 1.2, 6.0], [6.6, -3.1, 3.0, 1.0], [7.6, 6.6, 1.6, 0.8]])
	r.build(); r.save("cv_library")

## ---- City Hall front desk (civ_city_hall 26 x 15, floor 0.3, ground floor 3.7 high)
## Through the door you face the service counter across the hall, a roped queue lane leading to it, waiting benches
## facing it on both sides of the aisle; the open-plan staff desks behind; a forms table and leaflets in the left wing,
## the city's plans and model in the right wing; past mayors on the front wall.
func _city_hall() -> void:
	var r := R.new("cv_city_hall", 0.3); r.place("v_ne", "city_hall")
	_mats(r, "Marble006", 2.0, Color(0.96, 0.93, 0.86))
	r.mat("wains", "Wood058", 1.0, Color(0.42, 0.3, 0.2))
	r.mat("ceil2", "OfficeCeiling002", 1.2)
	var X0 := -12.7; var X1 := 12.7; var ZB := -7.12; var ZF := 6.95; var F := 0.3; var H := 3.95
	_shell(r, "civic/civ_city_hall", X0, X1, ZB, ZF, F, H, "ceil2")
	for i in 6: r.prop("shop_counter", -4.55 + i * 1.82, -1.0)
	for rx: float in [-3.64, 0.0, 3.64]: r.prop("cash_register", rx, -1.05, 180.0, 0.964)
	for rx2: float in [-3.64, 0.0, 3.64]: r.prop("office_chair", rx2, -1.85, 0.0)
	for sz: float in [0.45, 1.35]:
		for sx: float in [-1.0, 1.0]: r.prop("stanchion", sx, sz, 0.0)
	for bz: float in [2.6, 4.1]:
		for bx: float in [-3.4, -5.1, 3.4, 5.1]: r.prop("waiting_bench", bx, bz, 180.0)
	# staff behind the counter: two rows of desks facing the public, cabinets on the back wall
	for dz: float in [-3.4, -5.4]:
		for dx: float in [-4.5, -1.5, 1.5, 4.5]:
			r.prop("office_desk", dx, dz, 180.0); r.prop("office_chair", dx, dz - 0.6, 0.0)
	for cx: float in [-7.6, -7.1, -6.6, -1.0, -0.5, 0.0, 0.5, 1.0, 6.6, 7.1]: r.prop("filing_cabinet", cx, ZB + 0.36, 0.0)
	r.prop("drinks_fridge", -12.3, -6.4, 90.0); r.prop("bookcase", 12.5, -3.6, -90.0)
	# left wing: the forms table, leaflets on the wall
	r.prop("restaurant_table", -9.5, 2.0)
	for cz: Array in [[-9.8, 1.35, 0.0], [-9.2, 1.35, 0.0], [-9.8, 2.65, 180.0], [-9.2, 2.65, 180.0]]: r.prop("side_chair", float(cz[0]), float(cz[1]), float(cz[2]))
	r.prop("brochure_rack", X0 + 0.25, 2.4, 90.0); r.prop("brochure_rack", X0 + 0.25, -2.4, 90.0)
	r.prop("waiting_bench", -9.5, -2.6, 180.0)
	# right wing: the plans on a table, the city model in a case, the maps on the wall
	r.prop("display_table", 9.6, 1.6, 0.0); r.prop("glass_display_case", 9.6, 3.6, 0.0)
	r.prop("waiting_bench", 9.6, -2.6, 180.0)
	for fz: float in [-2.5, 2.5]: r.prop("gallery_frame", X1 - 0.04, fz, -90.0, 1.4)
	# past mayors on the front wall, notices by the door
	for fx: float in [-6.7, 6.7]: r.prop("gallery_frame", fx, ZF - 0.04, 180.0, 1.5)
	for px: float in [-2.2, 2.2]: r.prop("poster_case", px, ZF - 0.06, 180.0, 0.9)
	r.prop("potted_plant", -1.6, 6.5); r.prop("potted_plant", 1.6, 6.5); r.prop("plant_potted_leafy", -12.25, 6.5); r.prop("plant_potted_leafy", 12.25, 6.5)
	r.prop("plant_potted_leafy", -6.0, -0.9); r.prop("plant_potted_leafy", 6.0, -0.9)
	r.prop("indoor_bin", -7.0, 5.9); r.prop("indoor_bin", 7.0, 5.9); r.prop("indoor_bin", 5.9, -6.7)
	r.prop("usps_collection_box", -11.0, 5.0, 90.0)                  # mail drop in the left wing
	r.box("wains", Vector3(0, F + 0.5, ZB + 0.015), Vector3(X1 - X0, 1.0, 0.03))
	_panels(r, [-9.0, -4.5, 0.0, 4.5, 9.0], [-4.5, 0.5, 4.5], H, Color(0.98, 0.97, 0.94), 1.1, 6.0)
	_daylight(r, 0.0, 2.0, 6.2)
	_wear(r, F, [[0, 5.0, 1.6, 3.0], [0, 1.0, 2.0, 2.6], [0, -0.2, 6.0, 0.8], [-3.0, -2.2, 8.0, 0.7], [-9.5, 2.0, 2.0, 2.0]])
	r.build(); r.save("cv_city_hall")

## ---- Rec centre / gym (civ_rec_center 24 x 14, floor 0.3)
## The reception desk on your left as you come in, the supplements case, a drinks fridge and a snack machine beside it;
## the weights floor on the right in front of a mirror wall; lockers and changing benches along the back left; towels
## on shelves and the class timetables on the left wall, a water fountain between them.
func _rec_centre() -> void:
	var r := R.new("cv_rec_center", 0.3); r.place("v_nw", "rec_center")
	_mats(r, "Concrete047A", 2.0, Color(0.93, 0.95, 0.96), Color(0.36, 0.37, 0.4))
	var X0 := -11.7; var X1 := 11.7; var ZB := -6.62; var ZF := 6.45; var F := 0.3; var H := 3.95
	_shell(r, "civic/civ_rec_center", X0, X1, ZB, ZF, F, H)
	r.prop("shop_counter", -2.7, 3.6); r.prop("shop_counter", -4.52, 3.6)
	r.prop("cash_register", -3.2, 3.55, 180.0, 0.964); r.prop("office_chair", -3.2, 2.75, 0.0); r.prop("office_chair", -4.6, 2.75, 0.0)
	r.prop("salon_product_shelf", -3.6, 1.75, 0.0)            # towels, shakers, gear for sale behind the desk
	r.prop("glass_display_case", -6.4, 3.6, 0.0)               # supplements, bars
	r.prop("drinks_fridge", -5.6, ZF - 0.42, 180.0); r.prop("vending_snack", -6.65, ZF - 0.72, 180.0)
	r.prop("brochure_rack", 2.4, 6.0, 180.0); r.prop("poster_case", -2.0, ZF - 0.06, 180.0, 0.9)
	r.prop("waiting_bench", 6.2, 5.95, 180.0)                  # members waiting for a class, under the window
	r.prop("glass_display_case", 2.3, 3.6, 0.0)                # the trophies
	# weights floor: benches in rows, the mirror wall between the right-hand windows
	for mz: float in [-2.8, -1.35, 1.35, 2.8]: r.prop("mirror_station", X1 - 0.22, mz, -90.0)
	for wx: float in [4.4, 6.8, 9.2]:
		for wz: float in [-3.4, -0.6, 2.2]: r.prop("weight_bench", wx, wz, -90.0)
	r.prop("indoor_bin", 10.9, -5.9); r.prop("waiting_bench", 6.8, -5.95, 0.0)
	# free weights mid-floor: two rows of benches facing a freestanding mirror pair
	for fx: float in [-1.4, 0.0, 1.4]:
		for fz: float in [-1.6, -3.6]: r.prop("weight_bench", fx, fz, 0.0)
	for mx: float in [-0.65, 0.65]: r.prop("mirror_station", mx, -5.0, 0.0)
	# lockers (metal cabinets) along the back left, the changing benches in front of them
	for i in 8: r.prop("filing_cabinet", -8.0 + i * 0.5, ZB + 0.36, 0.0)
	r.prop("waiting_bench", -6.6, -4.8, 180.0); r.prop("waiting_bench", -4.9, -4.8, 180.0)
	# the left wall: towels and mats on shelves, timetables over them, the water fountain between
	for sz: float in [-2.2, 2.2]: r.prop("salon_product_shelf", X0 + 0.2, sz, 90.0)
	for fz: float in [-2.2, 2.2]: r.prop("gallery_frame", X0 + 0.04, fz, 90.0, 2.3)
	r.prop("drinking_fountain", X0 + 0.28, -1.2, 90.0)
	r.prop("side_chair", -9.0, 1.0, 90.0); r.prop("side_chair", -9.0, -0.4, 90.0)
	r.prop("indoor_bin", -1.4, 4.4); r.prop("recycling_receptacle", 11.2, 5.9)
	r.prop("potted_plant", -1.6, 6.05); r.prop("potted_plant", 1.6, 6.05); r.prop("plant_potted_leafy", -11.25, 6.0)
	_panels(r, [-8.0, -4.0, 0.0, 4.0, 8.0], [-3.5, 0.5, 4.0], H, Color(0.95, 0.97, 1.0), 1.2, 6.0)
	_daylight(r, 0.0, 2.0, 5.8)
	_wear(r, F, [[0, 4.8, 1.6, 2.8], [6.8, -0.6, 6.4, 7.4], [-5.8, -5.1, 4.0, 1.0], [-3.6, 4.5, 2.0, 1.0], [X0 + 0.7, -1.2, 0.8, 0.8]])
	r.build(); r.save("cv_rec_center")

## ---- Police front desk (civ_police 22 x 14, floor 0.3)
## A waiting lobby with benches along the side walls and under the front windows, leaflets, the wanted case and
## notices; the front desk set into the partition ahead (the staff door at its right end); the officers' desks, a
## briefing table and the files behind it, seen through the side windows from the street.
func _police() -> void:
	var r := R.new("cv_police", 0.3); r.place("v_se", "police")
	_mats(r, "Tiles074", 1.0, Color(0.9, 0.92, 0.93))
	r.mat("ceil2", "OfficeCeiling002", 1.2)
	var X0 := -10.7; var X1 := 10.7; var ZB := -6.62; var ZF := 6.45; var F := 0.3; var H := 3.95; var ZP := 0.8
	_shell(r, "civic/civ_police", X0, X1, ZB, ZF, F, H, "ceil2")
	# the partition: wall, the counter opening (-2.73 .. 2.73, counters set into it, a header over it), the staff door
	var C0 := -2.73; var C1 := 2.73; var D0 := 5.6; var D1 := 6.6
	r.box("wall", Vector3((X0 + C0) * 0.5, (F + H) * 0.5, ZP), Vector3(C0 - X0, H - F, 0.12))
	r.box("wall", Vector3((C1 + D0) * 0.5, (F + H) * 0.5, ZP), Vector3(D0 - C1, H - F, 0.12))
	r.box("wall", Vector3((D1 + X1) * 0.5, (F + H) * 0.5, ZP), Vector3(X1 - D1, H - F, 0.12))
	r.box("wall", Vector3(0.0, (F + 2.45 + H) * 0.5, ZP), Vector3(C1 - C0, H - F - 2.45, 0.12))
	r.box("wall", Vector3((D0 + D1) * 0.5, (F + 2.2 + H) * 0.5, ZP), Vector3(D1 - D0, H - F - 2.2, 0.12))
	r.solid_door("z", ZP, D0, D1, F, F + 2.2)
	for i in 3: r.prop("shop_counter", -1.82 + i * 1.82, ZP + 0.1)
	r.prop("cash_register", 0.6, ZP + 0.05, 180.0, 0.964)
	for ox: float in [-1.2, 1.2]: r.prop("office_chair", ox, ZP - 0.75, 0.0)
	for sx: float in [-1.0, 1.0]: r.prop("stanchion", sx, 2.3, 0.0)
	# lobby
	r.prop("waiting_bench", X0 + 0.28, 2.6, 90.0); r.prop("waiting_bench", X1 - 0.28, 2.6, -90.0)
	for bx: float in [-7.55, 7.55]: r.prop("waiting_bench", bx, ZF - 0.3, 180.0)
	for mb: float in [-5.2, 5.2]: r.prop("waiting_bench", mb, 3.9, 180.0)
	r.prop("brochure_rack", -5.7, ZF - 0.25, 180.0); r.prop("poster_case", X0 + 0.06, 5.9, 90.0, 0.8)
	r.prop("poster_case", -7.0, ZP + 0.08, 0.0, 0.9)                                  # wanted
	for fx: float in [-4.6, 4.2]: r.prop("gallery_frame", fx, ZP + 0.08, 0.0, 1.5)     # notices on the partition
	r.prop("vending_snack", 8.6, ZP + 0.78, 0.0)
	r.prop("indoor_bin", 3.4, 4.2); r.prop("potted_plant", -1.6, 6.05); r.prop("potted_plant", 1.6, 6.05)
	r.prop("plant_potted_leafy", -9.2, 6.05); r.prop("plant_potted_leafy", 10.25, 6.0)
	# offices behind the partition
	for dz: float in [-1.6, -4.4]:
		for dx: float in [-7.5, -4.5, 4.5, 7.5]:
			r.prop("office_desk", dx, dz, 180.0); r.prop("office_chair", dx, dz - 0.6, 0.0)
			r.prop("side_chair", dx + 0.45, dz + 0.65, 180.0)              # a visitor's chair facing the officer
	r.prop("restaurant_table", 0.0, -3.4); r.prop("restaurant_table", 0.0, -4.6)                   # briefing table
	for bz: float in [-3.7, -4.3]:
		r.prop("side_chair", -0.85, bz, 90.0); r.prop("side_chair", 0.85, bz, -90.0)
	r.prop("gallery_frame", 0.0, ZB + 0.04, 0.0, 1.3)                                  # the briefing board
	for cx: float in [-5.4, -4.9, -4.4, 4.4, 4.9, 5.4, 9.4, 9.9]: r.prop("filing_cabinet", cx, ZB + 0.36, 0.0)
	r.prop("drinks_fridge", X0 + 0.42, -2.2, 90.0); r.prop("bookcase", X0 + 0.2, -3.15, 90.0)
	r.prop("gallery_frame", X1 - 0.04, -2.2, -90.0, 1.5); r.prop("indoor_bin", -2.6, -0.3); r.prop("indoor_bin", 9.5, -1.0)
	_panels(r, [-7.5, -3.0, 3.0, 7.5], [-4.0, -1.0, 3.5], H, Color(0.95, 0.97, 1.0), 1.1, 6.0)
	_daylight(r, 0.0, 2.0, 5.8)
	_wear(r, F, [[0, 4.5, 1.6, 3.0], [0, 1.9, 4.4, 0.8], [0, -1.5, 1.6, 3.0], [6.1, 1.4, 1.0, 1.0]])
	r.build(); r.save("cv_police")

## ================================================================================================ APARTMENT BAND
## ---- Park Lane Liquor & Deli, the corner market (com_orange_corner 12 x 14, both front doors open)
## The cashier stands by the right door and sees both doors, the cigarettes behind him, cards and lottery at his
## counter; fruit and flowers in the left window, the papers by the door; three aisles with end caps; shelves along
## the left wall; the ice cream freezer and the ice chest on the right; the fridges on the back wall pull people through.
func _market() -> void:
	var r := R.new("ap_corner_market"); r.place("a_ne", "corner_market")
	_mats(r, "Tiles012", 1.0, Color(0.96, 0.97, 0.96))
	var X0 := -5.7; var X1 := 5.7; var ZB := -6.62; var ZF := 6.3; var F := 0.0; var H := 3.7
	_shell(r, "commercial/com_orange_corner", X0, X1, ZB, ZF, F, H)
	r.prop("checkout_counter", 3.9, 4.0, 90.0)
	r.prop("cigarette_cabinet", X1 - 0.17, 4.0, -90.0); r.prop("pharmacy_shelf", X1 - 0.2, 2.2, -90.0)
	r.prop("card_spinner", 2.95, 5.6)
	r.prop("produce_stand", -3.95, 5.45, 180.0)
	r.prop("brochure_rack", -2.55, 5.9, 180.0)                  # the papers by the door
	for rx: float in [-3.7, -1.0, 1.7]:
		for i in 5:
			var z := 2.0 - i * 1.2
			r.prop("grocery_shelf", rx - 0.23, z, -90.0); r.prop("grocery_shelf", rx + 0.23, z, 90.0)
		r.prop("grocery_shelf", rx, 2.85, 0.0); r.prop("grocery_shelf", rx, -3.65, 180.0)   # end caps: offers
	for wz: float in [-5.4, -4.2, -3.0, -1.8, -0.6, 0.6, 1.8]: r.prop("grocery_shelf", X0 + 0.25, wz, 90.0)
	r.prop("pharmacy_shelf", X0 + 0.2, 3.0, 90.0)
	for fx: float in [-3.1, -2.3, 0.0, 0.8, 2.8, 3.6]: r.prop("drinks_fridge", fx, ZB + 0.4, 0.0)
	r.prop("chest_freezer", 4.6, 0.6, -90.0)                    # ice cream by the counter side
	r.prop("ice_chest", 5.05, -2.0, -90.0)
	r.prop("grocery_shelf", X1 - 0.25, -4.6, -90.0); r.prop("grocery_shelf", X1 - 0.25, -3.4, -90.0)
	r.prop("indoor_bin", 2.5, 5.9); r.prop("indoor_bin", 3.1, 2.6)
	_panels(r, [-3.6, 0.0, 3.6], [-4.0, -0.5, 3.0], H, Color(0.95, 0.98, 1.0), 1.1, 5.0)
	_daylight(r, 0.0, 2.0, 5.6)
	_wear(r, F, [[0, 5.0, 3.6, 1.6], [3.0, 4.0, 1.0, 2.2], [-2.35, -0.4, 1.0, 6.0], [0.35, -0.4, 1.0, 6.0], [0, -5.4, 8.0, 0.9], [4.8, 4.0, 0.8, 1.6]])
	# the kit paints VILLAGE THEATRE / CROWN CAFE on this model (15 models say VILLAGE THEATRE): the shop names it
	var c: Dictionary = rc["commercial/com_orange_corner"]
	r.sign(c, "front", -3.0, "PARK LANE LIQUOR & DELI", "red"); r.sign(c, "front", 3.0, "COLD BEER · DELI · GROCERIES", "red")
	r.sign(c, "right", 7.55, "DELI", "red"); r.sign(c, "left", 7.55, "DELI", "red"); r.sign(c, "right", 2.4, "PARK LANE LIQUOR & DELI", "red")
	await r.make_signs(self)
	r.build(); r.save("ap_corner_market")

## ---- Fox Laundry and Alterations, the laundromat (the right bay of mod_svc_row: x 0.15 .. 5.7)
## Washers along the party wall, dryers along the outer wall, folding tables down the middle, a bench in the window
## facing the machines, the soap machine and the soda machine; the attendant's counter at the back with the rail of
## finished alterations behind it.
func _laundromat() -> void:
	var r := R.new("ap_laundromat"); r.place("a_nw", "laundromat")
	_mats(r, "Tiles143", 1.0, Color(0.88, 0.96, 0.93))
	var X0 := 0.15; var X1 := 5.7; var ZB := -5.62; var ZF := 5.4; var F := 0.0; var H := 3.8
	_shell(r, "modular/examples/mod_svc_row", X0, X1, ZB, ZF, F, H, "ceil", {"front": true, "back": true, "right": true, "left": false})
	for i in 9: r.prop("washer", X0 + 0.38, 3.6 - i * 0.7, 90.0)
	for i in 7: r.prop("dryer", X1 - 0.41, 3.0 - i * 0.66, -90.0)
	for tz: float in [1.6, -0.6]: r.prop("display_table", 2.9, tz, 90.0)
	r.prop("waiting_bench", 1.9, 4.75, 180.0); r.prop("side_chair", 3.1, 4.75, 180.0)
	r.prop("vending_snack", X0 + 0.85, -3.0, 90.0)             # soap and softener
	r.prop("vending_soda", X1 - 0.72, -2.15, -90.0)
	r.prop("laundry_counter", 3.2, -3.75, 180.0); r.prop("garment_rail", 2.9, -5.2, 0.0)
	r.prop("cash_register", 3.7, -3.77, 180.0, 1.08); r.prop("office_chair", 2.9, -4.55, 0.0)
	r.prop("salon_product_shelf", X0 + 0.2, -4.85, 90.0)
	for fz: float in [-1.6, 1.2]: r.prop("gallery_frame", X0 + 0.04, fz, 90.0, 1.5)      # prices and rules
	r.prop("indoor_bin", 3.6, 3.4); r.prop("potted_plant", 0.55, 4.95); r.prop("indoor_bin", 3.9, -0.6)
	_panels(r, [2.9], [-3.5, 0.0, 3.0], H, Color(0.95, 0.98, 1.0), 1.2, 5.0)
	_daylight(r, 2.0, 2.0, 4.8)
	_wear(r, F, [[4.6, 4.2, 1.4, 2.0], [1.5, 0.5, 0.8, 6.0], [4.4, 0.0, 0.8, 5.0], [2.9, -2.9, 2.0, 0.8]])
	# the row's blank boards: this shop and its neighbour (Crownado Barbers, a real shop still without a home)
	var c: Dictionary = rc["modular/examples/mod_svc_row"]
	r.sign(c, "front", 3.0, "FOX LAUNDRY & ALTERATIONS", "teal"); r.sign(c, "front", -3.0, "CROWNADO BARBERS", "navy")
	await r.make_signs(self)
	r.build(); r.save("ap_laundromat")

## ---- Danni's Palm Bar and Grill, the corner bar (com_bar_crown 9 x 14)
## Warm and dim. The bar along the right wall with its stools, the back bar and the taps; booths along the left wall
## (back to back), two high tables mid-floor, two small tables in the window, gig posters and the menu on the walls;
## the grill kitchen behind a partition lined up with the back door.
func _bar() -> void:
	var r := R.new("ap_corner_bar"); r.place("a_se", "corner_bar")
	_mats(r, "WoodFloor051", 2.0, Color(0.55, 0.62, 0.5), Color(0.75, 0.62, 0.5))
	r.mat("kfloor", "Tiles143", 1.0)
	r.mat("wains", "Wood058", 1.0, Color(0.4, 0.27, 0.18))
	var X0 := -4.12; var X1 := 4.12; var ZB := -6.62; var ZF := 6.3; var F := 0.0; var H := 3.7; var ZP := -3.6
	r.flat("floor", X0, ZP, X1, ZF, F); r.flat("kfloor", X0, ZB, X1, ZP, F); r.flat("ceil", X0, ZB, X1, ZF, H, false)
	r.walls4(rc["commercial/com_bar_crown"], X0, X1, ZB, ZF, F, H)
	_partition_x(r, ZP, X0, X1, -2.3, -1.3, F, H)
	for bz: float in [0.4, -1.8]: r.prop("bar_counter", 2.3, bz, -90.0)
	r.prop("beer_taps", 2.45, -0.2, -90.0, 1.11); r.prop("beer_taps", 2.45, -2.2, -90.0, 1.11)
	r.prop("cash_register", 2.45, 1.1, 90.0, 1.11)
	for bz2: float in [0.4, -1.4]: r.prop("wine_backbar", X1 - 0.21, bz2, -90.0)
	for sz: float in [1.15, 0.4, -0.35, -1.1, -1.85, -2.6]: r.prop("bar_stool", 1.55, sz, 90.0)
	for tz: float in [2.8, 0.2, -2.4]:
		r.prop("restaurant_table", -3.35, tz); r.prop("booth_bench", -3.35, tz - 0.75, 0.0); r.prop("booth_bench", -3.35, tz + 0.75, 180.0)
	for hz: float in [1.6, -1.2]:
		r.prop("cafe_table", -0.9, hz); r.prop("bar_stool", -1.45, hz, 90.0); r.prop("bar_stool", -0.35, hz, -90.0)
	for wx: float in [0.2, 2.8]:
		r.prop("cafe_table", wx, 5.1); r.prop("bar_stool", wx - 0.55, 5.1, 90.0); r.prop("bar_stool", wx + 0.55, 5.1, -90.0)
	r.prop("menu_board", X0 + 0.06, 1.5, 90.0, 1.65)
	for fz: float in [3.5, -1.0]: r.prop("gallery_frame", X0 + 0.04, fz, 90.0, 1.55)
	r.prop("poster_case", X1 - 0.06, 2.9, -90.0, 0.9)                                  # the gig posters
	r.box("wains", Vector3(X0 + 0.015, 0.55, (ZP + ZF) * 0.5), Vector3(0.03, 1.1, ZF - ZP))
	r.prop("potted_plant", 3.75, 5.95); r.prop("plant_potted_leafy", -0.9, 5.95); r.prop("indoor_bin", 3.0, 1.9)
	# the kitchen
	r.prop("kitchen_line", 1.4, ZB + 0.43, 0.0); r.prop("chest_freezer", 3.3, ZB + 0.36, 0.0)
	r.prop("grocery_shelf", -3.4, ZP - 0.31, 180.0); r.prop("bakery_shelf", 0.4, ZP - 0.26, 180.0)
	r.prop("indoor_bin", -1.0, -6.3)
	for p: Vector2 in [Vector2(-3.35, 2.8), Vector2(-3.35, 0.2), Vector2(-3.35, -2.4), Vector2(2.3, 0.6), Vector2(2.3, -1.6), Vector2(1.5, 5.0), Vector2(-0.9, 0.2)]:
		r.pendant(p.x, p.y, H, 0.9, Color(1.0, 0.72, 0.45), 0.9, 4.0)
	r.pendant(1.0, -5.1, H, 0.0, Color(0.95, 0.97, 1.0), 1.1, 4.5, true)
	_daylight(r, 1.0, 1.9, 5.6, 0.6)
	_wear(r, F, [[-3.2, 5.3, 1.4, 1.6], [0.9, -0.7, 1.0, 4.4], [3.3, -0.7, 0.8, 4.0], [-1.8, -4.6, 1.0, 2.0], [-0.9, 0.2, 1.4, 3.6]])
	var c: Dictionary = rc["commercial/com_bar_crown"]
	r.sign(c, "front", 0.0, "DANNI'S PALM BAR & GRILL", "black"); r.sign(c, "left", 0.0, "DANNI'S PALM BAR", "black")
	r.sign(c, "right", 7.55, "BAR", "black"); r.sign(c, "left", 7.55, "BAR", "black")
	await r.make_signs(self)
	r.build(); r.save("ap_corner_bar")

## ---- Heave Ho Cafe, the corner cafe (the shop bay of ck_brk3_corner2: x 0 .. 5.7; the flat's entry is left of it)
## The door is in the right-front corner; the counter runs along the party wall on the left: the pastry case first
## (people decide there), the till, the grab-and-go fridge after it; the espresso machine, the menu and the bread shelf
## behind; a shared table down the middle, two-tops in the window and by the side window, a banquette on the right
## wall; the store room behind a partition at the back door.
func _corner_cafe() -> void:
	var r := R.new("ap_corner_cafe"); r.place("a_sw", "corner_cafe")
	_mats(r, "WoodFloor034", 2.0, Color(0.98, 0.9, 0.8))
	r.mat("kfloor", "Tiles143", 1.0)
	r.mat("brick", "Bricks066", 1.5, Color(0.85, 0.78, 0.72))
	var X0 := 0.0; var X1 := 5.7; var ZB := -6.62; var ZF := 6.35; var F := 0.0; var H := 2.95; var ZP := -3.6
	r.flat("floor", X0, ZP, X1, ZF, F); r.flat("kfloor", X0, ZB, X1, ZP, F); r.flat("ceil", X0, ZB, X1, ZF, H, false)
	r.walls4(rc["ck/ck_brk3_corner2"], X0, X1, ZB, ZF, F, H, {"front": true, "back": true, "right": true, "left": false})
	r.box("brick", Vector3(X0 + 0.02, (F + H) * 0.5, (ZP + ZF) * 0.5), Vector3(0.04, H - F, ZF - ZP))   # exposed brick party wall
	_partition_x(r, ZP, X0, X1, 2.5, 3.5, F, H)
	r.prop("pastry_case", 2.2, 0.62, 90.0); r.prop("shop_counter", 2.2, -1.0, 90.0)
	r.prop("cash_register", 2.25, -1.5, -90.0, 0.964)
	r.prop("drinks_fridge", 2.2, -2.45, 90.0)
	r.prop("espresso_machine", 0.47, -1.0, 90.0); r.prop("bakery_shelf", 0.21, -2.6, 90.0)
	r.prop("menu_board", X0 + 0.06, -0.6, 90.0, 1.5)
	r.prop("restaurant_table", 4.4, -0.2, 90.0); r.prop("restaurant_table", 4.4, 1.0, 90.0)
	for cz: float in [-0.5, 0.4, 1.3]: r.prop("cafe_chair", 3.75, cz, 90.0)
	for cz2: float in [-0.35, 1.15]: r.prop("cafe_chair", 5.05, cz2, -90.0)
	for wx: float in [1.2, 2.8]:
		r.prop("cafe_table", wx, 5.3); r.prop("cafe_chair", wx, 4.75, 0.0)   # one seat each, facing the window
	r.prop("waiting_bench", X1 - 0.28, 3.0, -90.0); r.prop("cafe_table", 4.75, 3.0); r.prop("cafe_chair", 4.1, 3.0, 90.0)
	r.prop("cafe_table", 4.9, -2.6); r.prop("cafe_chair", 4.35, -2.6, 90.0); r.prop("cafe_chair", 4.9, -2.05, 180.0)
	r.prop("cafe_table", 1.2, 2.6); r.prop("cafe_chair", 1.2, 2.05, 0.0); r.prop("cafe_chair", 1.2, 3.15, 180.0)
	for fz: float in [2.0, -2.0]: r.prop("gallery_frame", X1 - 0.04, fz, -90.0, 1.45)
	r.prop("gallery_frame", X0 + 0.04, 2.6, 90.0, 1.4)
	r.prop("brochure_rack", 0.35, 4.6, 90.0)                   # what's on in town
	r.prop("indoor_bin", 3.2, -2.2); r.prop("potted_plant", 0.45, 5.95); r.prop("plant_potted_leafy", 3.35, 5.95)
	# the store room
	r.prop("grocery_shelf", X0 + 0.25, -5.0, 90.0)
	r.prop("chest_freezer", 4.6, ZB + 0.36, 0.0); r.prop("bakery_shelf", 1.0, ZP - 0.28, 180.0)
	for p: Vector2 in [Vector2(4.4, 0.4), Vector2(2.0, 4.8), Vector2(1.6, -0.2), Vector2(4.8, 3.0), Vector2(1.2, 2.6)]:
		r.pendant(p.x, p.y, H, 0.6, Color(1.0, 0.8, 0.58), 1.0, 4.0)
	r.pendant(2.8, -5.1, H, 0.0, Color(0.95, 0.97, 1.0), 0.9, 4.0, true)
	_daylight(r, 2.2, 1.9, 5.7, 0.9)
	_wear(r, F, [[4.9, 4.6, 1.2, 2.2], [3.0, -0.2, 0.8, 3.0], [1.3, -0.2, 0.7, 2.6]])
	r.sign(rc["ck/ck_brk3_corner2"], "front", 2.4, "HEAVE HO CAFÉ", "cream", "Nunito")
	await r.make_signs(self)
	r.build(); r.save("ap_corner_cafe")
