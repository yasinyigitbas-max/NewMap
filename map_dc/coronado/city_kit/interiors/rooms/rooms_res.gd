extends SceneTree
## The residential zone's shop rooms (18 Nov, zone growth; Yasin: "do out and indoors together ... i want the shops to
## look different"; "look from the perspective of interior designer and the customers when you design indoors").
## Three corner shops among the houses of the pilot area (tools/city/pilot/zoning/res_grow.py), each in its kit building
## behind its real door, seen through its real windows. Their character is the residential zone's own: quiet
## neighbourhood shops, run by the same people for years, a bit old-fashioned and lived-in - nothing of the high
## street's polish, the centre's chains or the strip's fluorescent boxes.
##   g_res_books  Hillside Books (com_shallow_books): a used bookshop - wall-to-wall cases, one island, the owner's
##                desk-counter by the right wall, a reading chair, the window full of local history and paperbacks
##   g_res_cafe   Ridge Coffee (com_shallow_cafe): the regulars' corner cafe - one booth, small tables in the window,
##                the pastry case and the espresso machine on a short counter, the notice board, the fridge you serve
##                yourself from
##   g_res_surf   Ocean Blvd Surf (com_surf_shop): a surf shop and ding-repair two blocks from the beach - boards up the
##                long wall, wetsuits and a changing room on the other, the rental quiver in the middle, the repair
##                bench in the back room behind the staff door
## The small shops' front doors are measured as house doors (O_apt_door, a closed leaf); a shop needs a glass door you
## can see through, so the room reads its contract from a COPY in memory with that door turned into a shop door (the
## same opening is cut; room_contracts.json is not changed). Building transforms come from the built quadrant pieces.
## Run with the real renderer: godot --path . --rendering-method mobile --resolution 320x180 -s <this>
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")
const RC := "res://map_dc/coronado/city_kit/interiors/room_contracts.json"
const ASG := "res://map_dc/coronado/city_kit/interiors/assignment_res.json"
var rc := {}
var asg := {}

func _init() -> void: _run.call_deferred()

func _run() -> void:
	rc = JSON.parse_string(FileAccess.get_file_as_string(RC)).models
	asg = JSON.parse_string(FileAccess.get_file_as_string(ASG))
	await _books(); await _cafe(); await _surf()
	quit()

func _entry(id: String) -> Dictionary:
	for e: Dictionary in asg.rooms:
		if String(e.built) == id: return e
	push_error("rooms_res: no entry " + id); return {}

## the contract with the front house-door turned into a shop door (in memory)
func _shop_contract(model: String) -> Dictionary:
	var c: Dictionary = (rc[model] as Dictionary).duplicate(true)
	for o: Dictionary in c.openings:
		if String(o.region) == "O_apt_door" and String(o.facade) == "front": o.region = "O_shopdoor"
	return c

func _start(id: String, F: float) -> Array:
	var e := _entry(id)
	var r := R.new(id, F)
	var p: Array = e.pos
	r.world_xf = Transform3D(Basis(Vector3.UP, deg_to_rad(float(e.yaw))), Vector3(float(p[0]), float(p[1]), float(p[2])))
	return [r, e]

func _mats(r: R, floor_tex: String, floor_tile: float, wall_tint: Color, floor_tint := Color(1, 1, 1)) -> void:
	r.mat("wall", "PaintedPlaster017", 2.0, wall_tint)
	r.mat("ceil", "Plaster001", 2.0, Color(0.95, 0.94, 0.92))
	r.mat("floor", floor_tex, floor_tile, floor_tint)
	r.mat("door", "Wood058", 1.0, Color(0.55, 0.42, 0.3))
	r.plain("skirt", Color(0.16, 0.14, 0.12), 0.5)
	r.plain("pendant_shade", Color(0.12, 0.2, 0.14), 0.35)
	r.plain("pendant_cord", Color(0.05, 0.05, 0.05), 0.5)
	r.plain("bulb", Color(1.0, 0.85, 0.6), 0.3, 6.0)
	r.plain("light_panel", Color(1.0, 0.97, 0.9), 0.3, 3.5)

func _daylight(r: R, x: float, y: float, z: float, e := 0.8, rng := 6.0) -> void:
	var d := OmniLight3D.new(); d.position = Vector3(x, y, z); d.light_color = Color(0.86, 0.92, 1.0); d.light_energy = e; d.omni_range = rng
	r.lights.add_child(d)

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

func _signs(r: R, c: Dictionary, e: Dictionary, short: String) -> void:
	for sg: Dictionary in c.signs:
		var txt := String(e.name).to_upper() if float(sg.w) >= 2.4 else short
		r.sign(c, String(sg.facade), float(sg.along), txt, String(e.style), "Nunito")

## ================================================================================================ Hillside Books
## com_shallow_books, inside 5.9 x 5.25. From the door (front left) you see down the left aisle to the back and, to the
## right, the owner at the desk-counter against the right wall (the till, a lamp-lit chair behind it). Cases run round
## the walls and one double-sided island stands in the middle; the window holds two low tables of local history and
## paperbacks for the street to see; leaflets of the neighbourhood by the door; old maps of the island on the walls.
func _books() -> void:
	var s := _start("g_res_books", 0.02); var r: R = s[0]; var e: Dictionary = s[1]
	var model := "commercial/com_shallow_books"
	var c := _shop_contract(model)
	_mats(r, "WoodFloor051", 2.0, Color(0.93, 0.89, 0.8))
	r.mat("wains", "Wood058", 1.0, Color(0.42, 0.3, 0.2))
	var X0 := -2.95; var X1 := 2.95; var ZB := -2.7; var ZF := 2.55; var F := 0.02; var H := 3.5
	r.flat("floor", X0, ZB, X1, ZF, F); r.flat("ceil", X0, ZB, X1, ZF, H, false)
	r.walls4(c, X0, X1, ZB, ZF, F, H)
	# the owner's counter across the back right, facing the room: the till on it, the stool and the files behind it
	r.prop("shop_counter", 1.75, -1.2, 0.0)
	r.prop("cash_register", 1.4, -1.25, 180.0, 0.964)
	r.prop("bar_stool", 1.75, -1.95, 0.0)
	# cases round the walls (the back door and the staff corner kept clear)
	r.prop("bookcase", 0.0, ZB + 0.2, 0.0)
	for bz: float in [-2.0, -1.0, 0.0]: r.prop("bookcase", X0 + 0.2, bz, 90.0)
	# the island: two cases back to back
	for iz: float in [-1.2, -0.2]:
		r.prop("bookcase", -0.82, iz, -90.0); r.prop("bookcase", -0.42, iz, 90.0)
	# the window: low tables the street can see over
	r.prop("display_table", 0.15, 1.85, 0.0); r.prop("display_table", 1.75, 1.85, 0.0)
	# by the door: the neighbourhood's leaflets; a bin at the counter's end; a plant where the light is
	r.prop("brochure_rack", X0 + 0.25, 0.76, 90.0)
	r.prop("indoor_bin", 2.8, -1.7)
	r.prop("potted_plant", 2.7, 1.9)
	# old maps and prints where nothing tall stands in front
	r.prop("gallery_frame", X1 - 0.04, 1.0, -90.0, 1.55)
	r.prop("gallery_frame", X1 - 0.04, -0.2, -90.0, 1.5)
	r.box("wains", Vector3(X1 - 0.015, F + 0.45, -0.4), Vector3(0.03, 0.9, 4.2))
	r.pendant(-1.6, -0.6, H, 0.7, Color(1.0, 0.78, 0.5), 1.2, 4.5)
	r.pendant(1.0, 0.6, H, 0.7, Color(1.0, 0.78, 0.5), 1.2, 4.5)
	_daylight(r, 1.0, 1.9, 2.0)
	_wear(r, F, [[-2.0, 1.6, 1.2, 1.6], [-1.75, -0.6, 1.0, 3.0], [0.9, -0.4, 1.0, 2.4], [0.0, 0.9, 2.4, 0.8]])
	_signs(r, c, e, "BOOKS")
	await r.make_signs(self)
	var root := r.build(); root.set_meta(&"shop", {"id": String(e.id), "kind": "books", "name": String(e.name)}); r.save("g_res_books")
	root.free()

## ================================================================================================ Ridge Coffee
## com_shallow_cafe, inside 6.9 x 5.75. The door is front right; straight ahead the short counter - the pastry case on
## the customer's side first, then the till and the espresso machine - with the staff behind it and the menu over the
## back shelf. The regulars' booth is on the left wall under the window, two small tables in the shop window, one in
## the middle; drinks in a fridge you serve yourself from on the right wall, the neighbourhood notice board beside it.
func _cafe() -> void:
	var s := _start("g_res_cafe", 0.02); var r: R = s[0]; var e: Dictionary = s[1]
	var model := "commercial/com_shallow_cafe"
	var c := _shop_contract(model)
	_mats(r, "Tiles101", 1.0, Color(0.96, 0.9, 0.78))
	r.mat("wains", "Wood058", 1.0, Color(0.5, 0.36, 0.24))
	var X0 := -3.45; var X1 := 3.45; var ZB := -2.95; var ZF := 2.8; var F := 0.02; var H := 3.5
	r.flat("floor", X0, ZB, X1, ZF, F); r.flat("ceil", X0, ZB, X1, ZF, H, false)
	r.walls4(c, X0, X1, ZB, ZF, F, H)
	# the counter
	r.prop("shop_counter", -1.1, -1.4, 0.0)
	r.prop("pastry_case", 0.5, -1.4, 0.0)
	r.prop("cash_register", -0.5, -1.45, 180.0, 0.964)
	r.prop("espresso_machine", -1.65, -1.5, 180.0, 0.964)
	r.prop("bakery_shelf", 1.35, ZB + 0.22, 0.0)
	r.prop("menu_board", -0.4, ZB + 0.06, 0.0, 1.75)
	r.prop("bar_stool", -1.1, -2.4, 0.0)
	# the booth on the left wall
	r.prop("restaurant_table", X0 + 0.66, -0.1, 0.0)
	r.prop("booth_bench", X0 + 0.66, 0.63, 180.0); r.prop("booth_bench", X0 + 0.66, -0.83, 0.0)
	# window tables and one in the middle
	# window tables: the chairs on the room side and toward the door, never wedged against the side wall
	r.prop("cafe_table", -2.5, 2.0); r.prop("cafe_chair", -2.5, 1.38, 0.0); r.prop("cafe_chair", -1.92, 2.0, -90.0)
	r.prop("cafe_table", -0.5, 2.0); r.prop("cafe_chair", -1.08, 2.0, 90.0); r.prop("cafe_chair", 0.08, 2.0, -90.0)
	r.prop("cafe_table", 0.0, 0.6); r.prop("cafe_chair", -0.58, 0.6, 90.0); r.prop("cafe_chair", 0.58, 0.6, -90.0)
	# self-serve fridge and the notice board on the right wall, a plant between them
	r.prop("drinks_fridge", X1 - 0.4, -1.5, -90.0)
	r.prop("poster_case", X1 - 0.06, 0.95, -90.0, 1.0)
	r.prop("potted_plant", X1 - 0.25, -0.55, 0.0)
	r.prop("plant_potted_leafy", 1.0, 2.2, 0.0)
	r.prop("indoor_bin", 1.6, 0.9)
	r.prop("gallery_frame", X0 + 0.04, -1.9, 90.0, 1.6)
	r.box("wains", Vector3(0.0, F + 0.45, ZF - 0.015), Vector3(X1 - X0, 0.9, 0.03))
	for px: float in [-2.2, 0.0, 2.2]: r.pendant(px, 0.4, H, 0.8, Color(1.0, 0.8, 0.55), 1.1, 4.5)
	_daylight(r, -1.0, 1.9, 2.2)
	_wear(r, F, [[2.4, 1.6, 1.2, 2.0], [1.2, -0.2, 2.6, 1.0], [-0.3, -0.75, 2.6, 0.9], [-2.6, 1.2, 1.0, 0.8]])
	_signs(r, c, e, "COFFEE")
	await r.make_signs(self)
	var root := r.build(); root.set_meta(&"shop", {"id": String(e.id), "kind": "cafe", "name": String(e.name)}); r.save("g_res_cafe")
	root.free()

## ================================================================================================ Ocean Blvd Surf
## com_surf_shop, inside 8.4 x 13.25. Door front left. Boards stand up the left wall in racks from the door to the back;
## wetsuits hang on the right wall with the changing room at its end; in the middle the rental quiver, tees on two
## racks, a table of wax, fins and leashes, a bench to try booties on; the counter across the back with the glass case
## of sunglasses and watches; a beach cruiser and a wetsuit on a mannequin in the window. Behind the partition (staff
## door lined up with the back door): the ding-repair bench and its pegboard, stock shelves, boards in for repair.
func _surf() -> void:
	var s := _start("g_res_surf", 0.02); var r: R = s[0]; var e: Dictionary = s[1]
	var model := "commercial/com_surf_shop"
	var c: Dictionary = rc[model]
	_mats(r, "Concrete047A", 2.0, Color(0.86, 0.93, 0.95))
	r.mat("kfloor", "Concrete034", 2.0)
	var X0 := -4.2; var X1 := 4.2; var ZB := -6.7; var ZF := 6.3; var F := 0.02; var H := 3.9; var ZP := -3.4    # front wall 0.25 m inside the door plane (6.55)
	r.flat("floor", X0, ZP, X1, ZF, F); r.flat("kfloor", X0, ZB, X1, ZP, F); r.flat("ceil", X0, ZB, X1, ZF, H, false)
	r.walls4(c, X0, X1, ZB, ZF, F, H)
	# partition with the staff door lined up with the back door (x -1.8)
	var d0 := -2.3; var d1 := -1.3
	r.box("wall", Vector3((X0 + d0) * 0.5, (F + H) * 0.5, ZP), Vector3(d0 - X0, H - F, 0.12))
	r.box("wall", Vector3((d1 + X1) * 0.5, (F + H) * 0.5, ZP), Vector3(X1 - d1, H - F, 0.12))
	r.box("wall", Vector3((d0 + d1) * 0.5, (F + 2.2 + H) * 0.5, ZP), Vector3(d1 - d0, H - F - 2.2, 0.12))
	r.solid_door("z", ZP, d0, d1, F, F + 2.2)
	# the counter and the case
	r.prop("shop_counter", 0.3, -2.2, 0.0)
	r.prop("glass_display_case", 1.8, -2.2, 0.0)
	r.prop("cash_register", 0.0, -2.25, 180.0, 0.964)
	r.prop("bar_stool", 0.6, -2.95, 0.0)
	r.prop("indoor_bin", -0.85, -2.0)
	# boards up the left wall
	for bz: float in [4.0, 3.2, 2.4, 1.6, 0.8, 0.0, -0.8, -1.6]: r.prop("surfboard_rack", X0 + 0.42, bz, 90.0)
	# wetsuits and booties on the right wall, the changing room at its back end
	r.prop("clothes_rack", X1 - 0.3, 3.2, -90.0); r.prop("clothes_rack", X1 - 0.3, 1.6, -90.0)
	r.prop("shoe_wall", X1 - 0.22, 0.0, -90.0)
	r.prop("fitting_room", X1 - 0.72, -2.25, -90.0)
	# the middle: rental quiver, tee racks, the wax table, the bench to try booties, stickers and tide charts
	r.prop("surfboard_rack", -1.6, -0.4, 0.0)
	r.prop("clothes_rack", -0.9, 2.0, 90.0); r.prop("clothes_rack", 1.1, 2.0, 90.0)
	r.prop("display_table", 0.1, -0.3, 0.0)
	r.prop("shoe_bench", 2.5, 0.9, 0.0)
	r.prop("card_spinner", 2.4, -0.6)
	# the window: a beach cruiser, a wetsuit on a mannequin, wax and fins on a low table
	r.prop("bike_stand", 3.2, 5.45, 90.0)
	r.prop("mannequin", -1.2, 5.8, 0.0)
	r.prop("display_table", 0.75, 5.75, 0.0)
	r.prop("potted_plant", X1 - 0.3, 4.2)
	r.prop("gallery_frame", -3.0, ZP + 0.1, 0.0, 1.5); r.prop("gallery_frame", -3.7, ZP + 0.1, 0.0, 1.5)
	# back room: the ding-repair bench and its pegboard, stock, boards in for repair
	r.prop("workbench", 1.4, ZB + 0.55, 0.0)
	r.prop("pegboard_wall", 1.4, ZB + 0.16, 0.0)
	r.prop("wall_shelf", -3.6, ZB + 0.16, 0.0); r.prop("wall_shelf", X0 + 0.16, -5.0, 90.0)
	r.prop("surfboard_rack", X1 - 0.42, -4.6, -90.0)
	r.prop("filing_cabinet", X1 - 0.4, -6.25, -90.0)
	for lz: float in [3.6, 0.4]:
		for lx: float in [-1.6, 1.6]: r.pendant(lx, lz, H, 0.0, Color(1.0, 0.97, 0.9), 1.2, 5.5, true)
	r.pendant(0.0, -5.0, H, 0.0, Color(0.95, 0.97, 1.0), 1.0, 4.5, true)
	_daylight(r, 1.0, 2.0, 5.8)
	_wear(r, F, [[-3.2, 4.2, 1.4, 2.2], [-2.4, 1.2, 1.2, 5.0], [0.5, -1.4, 3.2, 1.0], [-1.8, -5.0, 1.0, 2.6], [1.4, -5.6, 1.8, 1.0]])
	_signs(r, c, e, "SURF")
	await r.make_signs(self)
	var root := r.build(); root.set_meta(&"shop", {"id": String(e.id), "kind": "sport", "name": String(e.name)}); r.save("g_res_surf")
	root.free()
