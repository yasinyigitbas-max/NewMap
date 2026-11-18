extends SceneTree
## The waterfront sample's rooms (17 Nov, Yasin: "make waterfront interiors, as a test"; the harbor office 18 Nov). Visuals only.
## Each room is authored in its kit building's model frame (room_contracts.json gives the walls, door and windows)
## and saved to interiors/rooms/<name>.scn. Run with the real renderer (MultiMesh data):
##   godot --path <preview> --rendering-method mobile -s res://map_dc/coronado/city_kit/interiors/rooms/rooms_waterfront.gd
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")

func _init() -> void: _run.call_deferred()

func _run() -> void:
	await _cafe(); await _beach_shop(); await _marina(); await _harbor()
	quit()

func _common(r: R, floor_tex: String, wall_tint: Color) -> void:
	r.mat("wall", "PaintedPlaster017", 2.0, wall_tint)
	r.mat("ceil", "Plaster001", 2.0, Color(0.95, 0.94, 0.92))
	r.mat("floor", floor_tex, 2.0)
	r.mat("door", "Wood058", 1.0, Color(0.55, 0.42, 0.3))
	r.plain("skirt", Color(0.16, 0.14, 0.12), 0.5)
	r.plain("glass", Color(0.78, 0.86, 0.92), 0.1, 1.1)          # daylight in the window (kit glass is opaque from outside)
	r.plain("frame", Color(0.12, 0.12, 0.13), 0.4)
	r.plain("pendant_shade", Color(0.08, 0.09, 0.08), 0.35)
	r.plain("pendant_cord", Color(0.05, 0.05, 0.05), 0.5)
	r.plain("bulb", Color(1.0, 0.85, 0.6), 0.3, 6.0)
	r.plain("light_panel", Color(1.0, 0.97, 0.9), 0.3, 3.5)

## the room's four walls with every ground-floor opening of its building, exactly as measured (room_lib.openings)
const RC := "res://map_dc/coronado/city_kit/interiors/room_contracts.json"
static var _rc := {}
func _walls(r: R, model: String, X0: float, X1: float, ZB: float, ZF: float, F: float, H: float) -> void:
	if _rc.is_empty(): _rc = JSON.parse_string(FileAccess.get_file_as_string(RC)).models
	var holes: Dictionary = r.openings(_rc[model], {"front": ZF, "back": ZB, "left": X0, "right": X1})
	r.wall("wall", "z", ZF, X0, X1, F, H, -1.0, holes.front)
	r.wall("wall", "z", ZB, X0, X1, F, H, 1.0, holes.back)
	r.wall("wall", "x", X0, ZB, ZF, F, H, 1.0, holes.left)
	r.wall("wall", "x", X1, ZB, ZF, F, H, -1.0, holes.right)

## a closed door leaf standing in a hole
func _leaf(r: R, axis: String, at: float, s0: float, s1: float, y0: float, y1: float) -> void:
	var c := (s0 + s1) * 0.5
	if axis == "z": r.box("door", Vector3(c, (y0 + y1) * 0.5, at), Vector3(s1 - s0, y1 - y0, 0.05))
	else: r.box("door", Vector3(at, (y0 + y1) * 0.5, c), Vector3(0.05, y1 - y0, s1 - s0))

func _skirting(r: R, x0: float, x1: float, z0: float, z1: float, y: float, gaps: Array = []) -> void:
	for s: Array in [["z", z0, x0, x1, 1.0], ["z", z1, x0, x1, -1.0], ["x", x0, z0, z1, 1.0], ["x", x1, z0, z1, -1.0]]:
		var a := float(s[2]); var b := float(s[3]); var at := float(s[1]); var inn := float(s[4])
		var cuts: Array = []
		for g: Array in gaps:
			if String(g[0]) == String(s[0]) and absf(float(g[1]) - at) < 0.01: cuts.append([float(g[2]), float(g[3])])
		cuts.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
		var p0 := a
		for c: Array in cuts + [[b, b]]:
			var p1 := float(c[0])
			if p1 - p0 > 0.05:
				var mid := (p0 + p1) * 0.5
				if String(s[0]) == "z": r.box("skirt", Vector3(mid, y + 0.05, at + inn * 0.01), Vector3(p1 - p0, 0.1, 0.02))
				else: r.box("skirt", Vector3(at + inn * 0.01, y + 0.05, mid), Vector3(0.02, 0.1, p1 - p0))
			p0 = float(c[1])

## ------------------------------------------------------------------------------------------------- seaside cafe
## com_cafe_seaside: footprint 6 x 14, front door at x -1.76 (1.6 m bay), storefront glass x -0.41..2.45, two casement
## windows on the left wall (z 2.6, 5.0), a small window on the right (z 4.4), back door at x -1.2, a side door at
## the left wall's back (z -5.0). The room: 5.3 x 10 m of cafe, a 2.8 m kitchen behind a partition.
func _cafe() -> void:
	var r := R.new("wf_cafe"); r.place("f_ne", "seaside_cafe")
	_common(r, "WoodFloor034", Color(1.0, 0.94, 0.84))
	r.mat("kfloor", "Tiles143", 1.0)
	r.mat("wains", "Wood058", 1.0, Color(0.62, 0.48, 0.34))
	var X0 := -2.65; var X1 := 2.65; var ZF := 6.3; var ZB := -6.67; var H := 3.6; var ZP := -3.9
	r.flat("floor", X0, ZP, X1, ZF, 0.0); r.flat("kfloor", X0, ZB, X1, ZP, 0.0)
	r.flat("ceil", X0, ZB, X1, ZF, H, false)
	# front wall: the door and the storefront glass
	_walls(r, "commercial/com_cafe_seaside", X0, X1, ZB, ZF, 0.0, H)
	# partition to the kitchen, staff doorway on the left (lines up with the back door)
	r.box("wall", Vector3((-1.25 + X1) * 0.5, H * 0.5, ZP), Vector3(X1 + 1.25, H, 0.12))
	r.box("wall", Vector3((X0 - 2.15) * 0.5, H * 0.5, ZP), Vector3(-2.15 - X0, H, 0.12))
	r.box("wall", Vector3(-1.7, (2.2 + H) * 0.5, ZP), Vector3(0.9, H - 2.2, 0.12))
	# wainscot on the cafe's side walls (below the casement sills), skirting everywhere else
	r.box("wains", Vector3(X0 + 0.015, 0.47, (ZP + ZF) * 0.5), Vector3(0.03, 0.94, ZF - ZP))
	r.box("wains", Vector3(X1 - 0.015, 0.47, (ZP + ZF) * 0.5), Vector3(0.03, 0.94, ZF - ZP))
	_skirting(r, X0, X1, ZB, ZF, 0.0, [["z", ZF, -2.56, -0.96], ["z", ZB, -1.7, -0.7], ["x", X0, -5.5, -4.5]])
	# ---- the counter across the back: the pastry case first (people decide there), the till, the espresso machine
	# and the bread shelf behind against the partition, the menu over them; the staff walk in from the left end
	r.prop("pastry_case", 1.85, -1.7, 0.0)
	r.prop("shop_counter", 0.25, -1.7, 0.0)
	r.prop("cash_register", -0.25, -1.75, 180.0, 0.964)
	r.prop("espresso_machine", 0.15, -3.37, 0.0)
	r.prop("bakery_shelf", 1.75, -3.64, 0.0)
	r.prop("menu_board", 0.25, -3.81, 0.0, 1.75)
	r.prop("drinks_fridge", -2.27, -1.15, 90.0)
	# ---- booths along the right wall (benches face across their table), two-tops in the window
	for zc: float in [0.7, 2.9]:
		r.prop("restaurant_table", 2.0, zc, 0.0)
		r.prop("booth_bench", 2.0, zc - 0.75, 0.0)
		r.prop("booth_bench", 2.0, zc + 0.75, 180.0)
	r.prop("cafe_table", 1.9, 5.0); r.prop("cafe_chair", 1.9, 5.55, 180.0); r.prop("cafe_chair", 1.9, 4.45, 0.0)
	r.prop("cafe_table", 0.35, 4.2); r.prop("cafe_chair", -0.2, 4.2, 90.0); r.prop("cafe_chair", 0.9, 4.2, -90.0)
	r.prop("potted_plant", 2.35, 5.95); r.prop("potted_plant", -2.35, 2.0)
	r.prop("indoor_bin", -1.0, -1.0)      # where people drop their cups, beside the counter end
	# ---- dressing (17 Nov, "a bit dry"): framed prints over the booths and along the left wall, plants by the
	# counter end and in the window, succulents on the window ledge, a second menu by the till
	for z0: float in [0.7, 2.9]: r.prop("gallery_frame", 2.62, z0, -90.0, 1.35)
	for z1: float in [-2.2, 0.3, 1.3]: r.prop("gallery_frame", -2.62, z1, 90.0, 1.3)
	r.prop("plant_potted_leafy", -2.3, -3.3)
	r.prop("plant_potted_succulent", 2.2, 6.08, 0.0, 0.57); r.prop("plant_potted_succulent", 0.0, 6.08, 40.0, 0.57)
	r.prop("plant_potted_leafy", -2.3, -0.2)
	r.prop("indoor_bin", -2.4, 3.8)
	# ---- kitchen
	r.prop("kitchen_line", 0.9, -6.22, 0.0)
	r.prop("wall_shelf", -2.47, -5.6, 90.0); r.prop("wall_shelf", -2.47, -4.5, 90.0)
	# ---- light: pendants over the booths, the window tables and the counter; a kitchen panel; daylight at the window
	for p: Vector2 in [Vector2(2.0, 0.3), Vector2(2.0, 2.6), Vector2(1.1, 4.6), Vector2(0.2, -2.0), Vector2(1.8, -2.0)]:
		r.pendant(p.x, p.y, H, 0.9, Color(1.0, 0.8, 0.58), 1.3, 4.5)
	r.pendant(0.0, -5.3, H, 0.0, Color(0.95, 0.97, 1.0), 1.2, 4.5, true)
	var day := OmniLight3D.new(); day.position = Vector3(1.0, 1.9, 5.7); day.light_color = Color(0.86, 0.92, 1.0); day.light_energy = 0.9; day.omni_range = 5.0
	r.lights.add_child(day)
	# ---- wear: the walk from the door to the counter, the queue, behind the counter, the kitchen
	var fy := func(_x: float, _z: float) -> float: return 0.0
	for k in 6: r.dec.add(14, Vector2(-1.6 + k * 0.05, 5.6 - k * 1.25), 0.0, 1.0, 1.4, fy, Color(1, 1, 1, 0.35), 0.004)
	r.dec.add(14, Vector2(0.6, -1.5), 0.0, 2.6, 0.9, fy, Color(1, 1, 1, 0.45), 0.004)
	r.dec.add(14, Vector2(0.9, -2.9), 0.0, 3.4, 0.7, fy, Color(1, 1, 1, 0.5), 0.004)
	r.dec.add(6, Vector2(0.9, -5.6), 0.0, 1.8, 0.8, fy, Color(1, 1, 1, 0.35), 0.004)
	# the shop's own name over the kit's painted CROWN CAFE (eight kit models say CROWN CAFE)
	var c: Dictionary = _rc["commercial/com_cafe_seaside"]
	r.sign(c, "front", 0.0, "CROWNADO BEACH COFFEE", "sea"); r.sign(c, "left", 3.8, "BEACH COFFEE", "sea")
	await r.make_signs(self)
	r.build(); r.save("wf_cafe")

## ------------------------------------------------------------------------------------------------- beach shop
## com_surf_shop: footprint 9 x 14, front door at x -3.26, storefront glass x -1.98..4.05, small high windows on both
## sides (z -4.8 / 4.4), back door x -1.8, back window x 3.06. The shop: 8.3 x 10.3 m, a stock room behind.
func _beach_shop() -> void:
	var r := R.new("wf_beach_shop"); r.place("f_nw", "surf_shop")
	_common(r, "Terrazzo005", Color(0.93, 0.97, 1.0))
	var X0 := -4.15; var X1 := 4.15; var ZF := 6.3; var ZB := -6.67; var H := 3.6; var ZP := -4.0
	r.flat("floor", X0, ZB, X1, ZF, 0.0); r.flat("ceil", X0, ZB, X1, ZF, H, false)
	_walls(r, "commercial/com_surf_shop", X0, X1, ZB, ZF, 0.0, H)
	r.box("wall", Vector3((-1.35 + X1) * 0.5, H * 0.5, ZP), Vector3(X1 + 1.35, H, 0.12))
	r.box("wall", Vector3((X0 - 2.35) * 0.5, H * 0.5, ZP), Vector3(-2.35 - X0, H, 0.12))
	r.box("wall", Vector3(-1.85, (2.2 + H) * 0.5, ZP), Vector3(1.0, H - 2.2, 0.12))
	_skirting(r, X0, X1, ZB, ZF, 0.0, [["z", ZF, -4.06, -2.46], ["z", ZB, -2.3, -1.3]])
	# ---- the till by the door: the cashier stands between it and the left wall, sees everyone come in
	r.prop("shop_counter", -2.9, 2.6, 90.0)
	r.prop("cash_register", -2.9, 2.2, -90.0, 0.964)
	r.prop("card_spinner", -2.0, 4.3); r.prop("card_spinner", 2.1, 3.7)
	r.prop("brochure_rack", -3.85, 4.5, 90.0)
	# ---- sunscreen and cold drinks along the right wall
	r.prop("pharmacy_shelf", 3.94, 1.6, -90.0); r.prop("pharmacy_shelf", 3.94, 0.4, -90.0)
	r.prop("drinks_fridge", 3.76, -1.0, -90.0); r.prop("drinks_fridge", 3.76, -1.85, -90.0)
	# ---- beachwear in the middle, two mannequins dressing the window
	r.prop("clothes_rack", 0.5, 2.2); r.prop("clothes_rack", 0.5, 0.3); r.prop("clothes_rack", -1.6, -1.2, 90.0)
	r.prop("mannequin", 2.9, 5.55, 180.0); r.prop("mannequin", 0.6, 5.65, 165.0)
	r.prop("shoe_wall", -3.97, -0.4, 90.0); r.prop("shoe_wall", -3.97, -1.6, 90.0)     # flip-flops and sandals
	# ---- boards and boogie boards along the back
	for bx: float in [-0.3, 0.9, 2.1, 3.3]: r.prop("surfboard_rack", bx, -3.5)
	r.prop("potted_plant", -3.8, 0.9); r.prop("indoor_bin", -2.2, 2.0)
	# ---- dressing: sunglasses and watches in a glass case beside the till, a table of folded beach towels and hats
	# by the window, a freezer of ice pops, posters over the shoe walls, plants at the window corners
	r.prop("glass_display_case", -2.9, 0.6, 90.0)
	r.prop("display_table", -0.9, 4.3, 0.0)
	r.prop("chest_freezer", -3.75, -3.05, 90.0)
	for z2: float in [1.2, -1.0]: r.prop("gallery_frame", -4.12, z2, 90.0, 2.1)
	r.prop("plant_potted_leafy", 3.75, 5.85); r.prop("plant_potted_leafy", -1.6, 5.95)
	r.prop("shoe_bench", -2.6, -1.0, 90.0)
	# ---- stock room
	for gx: float in [0.6, 1.9, 3.2]: r.prop("gondola_aisle", gx, -6.35)
	r.prop("wall_shelf", -3.97, -5.6, 90.0)
	for p: Vector2 in [Vector2(-1.8, 4.0), Vector2(1.8, 4.0), Vector2(-1.8, 1.0), Vector2(1.8, 1.0), Vector2(-1.8, -2.2), Vector2(1.8, -2.2)]:
		r.pendant(p.x, p.y, H, 0.0, Color(1.0, 0.96, 0.88), 1.0, 4.8, true)
	r.pendant(1.0, -5.3, H, 0.0, Color(0.95, 0.97, 1.0), 0.9, 4.5, true)
	var day := OmniLight3D.new(); day.position = Vector3(1.0, 1.9, 5.7); day.light_color = Color(0.86, 0.92, 1.0); day.light_energy = 1.0; day.omni_range = 6.0
	r.lights.add_child(day)
	var fy := func(_x: float, _z: float) -> float: return 0.0
	for k in 5: r.dec.add(14, Vector2(-3.2 + k * 0.4, 5.4 - k * 1.3), 20.0, 1.2, 1.5, fy, Color(0.95, 0.88, 0.72, 0.4), 0.004)   # sand off feet
	r.dec.add(14, Vector2(-2.3, 2.6), 90.0, 1.8, 0.9, fy, Color(1, 1, 1, 0.4), 0.004)
	var c: Dictionary = _rc["commercial/com_surf_shop"]
	r.sign(c, "front", 0.0, "LITTLE SAM'S BEACH FUN", "sun"); r.sign(c, "right", 2.4, "LITTLE SAM'S BEACH FUN", "sun")
	r.sign(c, "right", 7.55, "BEACH FUN", "sun"); r.sign(c, "left", 7.55, "BEACH FUN", "sun")
	await r.make_signs(self)
	r.build(); r.save("wf_beach_shop")

## ------------------------------------------------------------------------------------------------- marina office
## ext_marina_office: footprint 14 x 10, floor at 0.3, a centre door (1.8 m bay), two front windows (x +-3.7), two on
## each side (z +-2.4), three at the back, the back door at x -4.0. One room, 13.3 x 9.1 m.
func _marina() -> void:
	var r := R.new("wf_marina_office", 0.3); r.place("f_se", "marina_office")
	_common(r, "WoodFloor051", Color(0.96, 0.95, 0.9))
	r.mat("wains", "WoodSiding008", 1.5, Color(0.75, 0.82, 0.86))
	r.mat("ceil", "OfficeCeiling002", 1.2)
	var X0 := -6.65; var X1 := 6.65; var ZF := 4.45; var ZB := -4.67; var F := 0.3; var H := F + 3.8
	r.flat("floor", X0, ZB, X1, ZF, F); r.flat("ceil", X0, ZB, X1, ZF, H, false)
	_walls(r, "extras/ext_marina_office", X0, X1, ZB, ZF, F, H)
	# wainscot (nautical boards) below the windows all round, cut at the doors
	for seg: Array in [["x", X0 + 0.015, ZB, ZF], ["x", X1 - 0.015, ZB, ZF], ["z", ZB + 0.015, X0, -4.55], ["z", ZB + 0.015, -3.45, X1], ["z", ZF - 0.015, X0, -0.95], ["z", ZF - 0.015, 0.95, X1]]:
		var a := float(seg[2]); var b := float(seg[3])
		if String(seg[0]) == "x": r.box("wains", Vector3(float(seg[1]), F + 0.55, (a + b) * 0.5), Vector3(0.03, 1.1, b - a))
		else: r.box("wains", Vector3((a + b) * 0.5, F + 0.55, float(seg[1])), Vector3(b - a, 1.1, 0.03))
	# ---- the rental counter facing the door; the desk and files behind it
	r.prop("shop_counter", -0.92, -2.4); r.prop("shop_counter", 0.92, -2.4)
	r.prop("cash_register", 0.5, -2.45, 180.0, 0.964)
	r.prop("office_desk", 2.6, -3.1, 180.0); r.prop("office_chair", 2.6, -3.6, 0.0)
	r.prop("filing_cabinet", -1.2, -4.33); r.prop("filing_cabinet", -0.6, -4.33)
	r.prop("brochure_rack", 3.0, 3.9, 180.0)
	# ---- paddle boards for rent along the right wall
	for bz: float in [3.0, 1.0, -0.4, -1.8]: r.prop("surfboard_rack", 6.15, bz, -90.0)
	# ---- waiting along the left wall, tide charts and photos over it
	r.prop("waiting_bench", -6.32, 0.4, 90.0); r.prop("waiting_bench", -6.32, -1.4, 90.0)
	r.prop("gallery_frame", -6.6, 0.4, 90.0, 1.3); r.prop("gallery_frame", -6.6, -1.4, 90.0, 1.3); r.prop("gallery_frame", -6.6, -2.6, 90.0, 1.3)
	r.prop("potted_plant", -6.25, 4.05); r.prop("potted_plant", 6.25, 4.05); r.prop("indoor_bin", -2.4, 4.05)
	r.prop("drinks_fridge", -6.22, -3.6, 90.0)
	# board repairs in the back-right corner: the bench where dings get fixed, its tool wall, a board waiting on it
	r.prop("workbench", 5.4, -4.05, 0.0); r.prop("pegboard_wall", 5.4, -4.52, 0.0, 0.0)
	r.prop("surfboard_rack", 3.9, -3.9, 0.0)
	# the waiting corner by the left windows: chairs round a low table for people filling in rental forms
	r.prop("restaurant_table", -4.4, 2.3, 90.0)
	for cz: Array in [[-4.4, 3.05, 180.0], [-4.4, 1.55, 0.0], [-3.65, 2.3, -90.0]]: r.prop("side_chair", float(cz[0]), float(cz[1]), float(cz[2]))
	# maps, tide tables and harbour leaflets in the middle where people wait their turn
	r.prop("display_table", -1.6, 1.2, 0.0); r.prop("card_spinner", 1.9, 1.0)
	r.prop("potted_plant", -6.25, -4.3); r.prop("potted_plant", 2.2, 4.05)
	# ---- dressing: plants either side of the door, harbour prints on the back wall and over the board racks, a bin
	# by the benches (the rental clerk stands: a chair behind the counter blocked the walk to the desk - indoor checker)
	r.prop("plant_potted_leafy", -1.45, 3.9); r.prop("plant_potted_leafy", 1.45, 3.9)
	r.prop("gallery_frame", 0.0, -4.62, 0.0, 1.4); r.prop("gallery_frame", 3.36, -4.62, 0.0, 1.65)   # the second over the board rack
	r.prop("gallery_frame", 6.62, 0.3, -90.0, 1.7)
	r.prop("indoor_bin", -6.3, -0.5)
	for p: Vector2 in [Vector2(-3.5, 2.0), Vector2(0.0, 2.0), Vector2(3.5, 2.0), Vector2(-3.5, -2.0), Vector2(0.0, -2.0), Vector2(3.5, -2.0)]:
		r.pendant(p.x, p.y, H, 0.0, Color(0.98, 0.97, 0.92), 1.0, 5.0, true)
	var day := OmniLight3D.new(); day.position = Vector3(0.0, F + 2.0, 3.8); day.light_color = Color(0.86, 0.92, 1.0); day.light_energy = 0.9; day.omni_range = 6.0
	r.lights.add_child(day)
	var fy := func(_x: float, _z: float) -> float: return F
	for k in 5: r.dec.add(14, Vector2(0.0, 3.6 - k * 1.2), 0.0, 1.4, 1.3, fy, Color(1, 1, 1, 0.35), 0.004)
	r.dec.add(14, Vector2(5.2, 0.6), 90.0, 4.6, 1.4, fy, Color(0.9, 0.85, 0.72, 0.35), 0.004)   # boards carried in and out
	r.dec.add(14, Vector2(5.4, -3.4), 0.0, 2.2, 1.2, fy, Color(1, 1, 1, 0.45), 0.004)   # resin and sanding dust at the bench
	r.dec.add(14, Vector2(0.0, -1.7), 0.0, 3.6, 0.9, fy, Color(1, 1, 1, 0.4), 0.004)    # the queue at the counter
	var c: Dictionary = _rc["extras/ext_marina_office"]
	r.sign(c, "front", 0.0, "THE SUP & SADDLEBAG", "navy"); r.sign(c, "back", 0.0, "THE SUP & SADDLEBAG", "navy")
	await r.make_signs(self)
	r.build(); r.save("wf_marina_office")

## ------------------------------------------------------------------------------------------------- harbor office
## civ_harbor_office (f_ne): 16 x 12, floor at 0.3, ground storey 3.4 clear, the door in the middle of the front, two
## front windows, two on each side, three at the back, the back door at x -5. The kit's own sign says HARBOR OFFICE.
## (Yasin 18 Nov: "just make the harbor office for now".) From a boater's side: come in to pay a slip fee, get a
## permit or check the tides - the counter faces the door, people wait on benches under the front windows or at the
## chart table, tide tables / charts / leaflets where they wait; behind the counter the staff desks, the radio desk
## on the back wall under the harbour board, files, binders and the life-jacket box.
func _harbor() -> void:
	var r := R.new("wf_harbor_office", 0.3); r.place("f_ne", "civ_harbor_office")
	if _rc.is_empty(): _rc = JSON.parse_string(FileAccess.get_file_as_string(RC)).models
	_common(r, "WoodFloor034", Color(0.93, 0.96, 0.98))
	r.mat("wains", "WoodSiding008", 1.5, Color(0.5, 0.64, 0.76))
	r.mat("ceil", "OfficeCeiling002", 1.2)
	var X0 := -7.6; var X1 := 7.6; var ZF := 5.45; var ZB := -5.62; var F := 0.3; var H := 3.7
	r.flat("floor", X0, ZB, X1, ZF, F); r.flat("ceil", X0, ZB, X1, ZF, H, false)
	r.walls4(_rc["civic/civ_harbor_office"], X0, X1, ZB, ZF, F, H)
	# nautical boards below the sills all round, cut at the two doors
	for seg: Array in [["x", X0 + 0.015, ZB, ZF], ["x", X1 - 0.015, ZB, ZF], ["z", ZB + 0.015, X0, -5.55], ["z", ZB + 0.015, -4.45, X1], ["z", ZF - 0.015, X0, -0.95], ["z", ZF - 0.015, 0.95, X1]]:
		var a := float(seg[2]); var b := float(seg[3])
		if String(seg[0]) == "x": r.box("wains", Vector3(float(seg[1]), F + 0.45, (a + b) * 0.5), Vector3(0.03, 0.9, b - a))
		else: r.box("wains", Vector3((a + b) * 0.5, F + 0.45, float(seg[1])), Vector3(b - a, 0.9, 0.03))
	# ---- the counter facing the door: three counters, two tills turned to the staff, two clerks
	for cx: float in [-1.82, 0.0, 1.82]: r.prop("shop_counter", cx, 0.6)
	for rx: float in [-1.82, 1.82]: r.prop("cash_register", rx, 0.55, 180.0, 0.964)
	for ox: float in [-1.82, 1.82]: r.prop("office_chair", ox, -0.25, 0.0)
	# ---- the lobby: benches under the front windows facing the counter, plants by the door
	for bx: float in [-4.2, 4.2]: r.prop("waiting_bench", bx, ZF - 0.3, 180.0)
	r.prop("plant_potted_leafy", -1.5, 5.05); r.prop("plant_potted_leafy", 1.5, 5.05); r.prop("indoor_bin", 2.3, 5.1)
	# left: the chart table to fill in forms at, tide tables and a chart on the wall, the water fountain in the corner
	r.prop("display_table", -4.6, 2.6, 90.0)
	r.prop("side_chair", -3.85, 2.2, -90.0); r.prop("side_chair", -3.85, 3.0, -90.0)
	r.prop("poster_case", X0 + 0.06, 1.6, 90.0, 0.9)
	r.prop("gallery_frame", X0 + 0.04, 4.8, 90.0, 1.45)
	r.prop("drinking_fountain", X0 + 0.28, 5.0, 90.0)
	# right: the ship model in its case, leaflets (permits, launch rules), the life ring on the wall
	r.prop("glass_display_case", 4.6, 2.6, -90.0)
	r.prop("brochure_rack", X1 - 0.25, 1.6, -90.0)
	r.prop("lifering_stand", X1 - 0.2, 4.8, -90.0)
	r.prop("potted_plant", 7.2, 0.6)
	# ---- behind the counter: four desks facing the public, the radio desk under the harbour board, files and binders
	for dx: float in [-4.8, -1.8, 1.8, 4.8]:
		r.prop("office_desk", dx, -2.3, 180.0); r.prop("office_chair", dx, -2.9, 0.0)
	r.prop("office_desk", 0.0, ZB + 0.42, 0.0); r.prop("office_chair", 0.0, ZB + 1.05, 180.0)
	r.prop("gallery_frame", 0.0, ZB + 0.04, 0.0, 1.3)
	for fx: float in [-3.9, -3.4]: r.prop("filing_cabinet", fx, ZB + 0.36, 0.0)
	r.prop("bookcase", 3.6, ZB + 0.2, 0.0)
	r.prop("bookcase", X0 + 0.2, -1.5, 90.0); r.prop("bookcase", X0 + 0.2, -5.0, 90.0)
	r.prop("drinks_fridge", X0 + 0.42, -0.3, 90.0)
	r.prop("dock_box", X1 - 0.4, -4.7, -90.0)                  # life jackets and fenders for the patrol boat
	r.prop("gallery_frame", X1 - 0.04, -1.5, -90.0, 1.4)
	r.prop("indoor_bin", -2.9, -0.5); r.prop("plant_potted_leafy", 7.15, -2.2)
	for p: Vector2 in [Vector2(-4.5, 2.8), Vector2(0.0, 2.8), Vector2(4.5, 2.8), Vector2(-4.5, -2.6), Vector2(0.0, -2.6), Vector2(4.5, -2.6)]:
		r.pendant(p.x, p.y, H, 0.0, Color(0.98, 0.97, 0.92), 1.0, 5.5, true)
	var day := OmniLight3D.new(); day.position = Vector3(0.0, F + 2.0, 4.8); day.light_color = Color(0.86, 0.92, 1.0); day.light_energy = 0.9; day.omni_range = 6.5
	r.lights.add_child(day)
	var fy := func(_x: float, _z: float) -> float: return F
	for k in 3: r.dec.add(14, Vector2(0.05 * k, 4.6 - k * 1.25), 90.0 * (k % 2), 1.3, 1.3, fy, Color(1, 1, 1, 0.33), 0.004)   # door to counter
	for k2 in 3: r.dec.add(14, Vector2(-1.82 + k2 * 1.82, 1.5), 90.0 * (k2 % 2), 1.3, 1.0, fy, Color(1, 1, 1, 0.4), 0.004)   # at the counter
	r.dec.add(14, Vector2(-4.4, 2.6), 0.0, 1.3, 1.3, fy, Color(1, 1, 1, 0.3), 0.004)                                            # the chart table
	for k3 in 2: r.dec.add(14, Vector2(-1.0 + k3 * 2.0, -1.2), 90.0 * k3, 1.3, 1.0, fy, Color(1, 1, 1, 0.3), 0.004)          # staff side
	await r.make_signs(self)      # the kit's HARBOR OFFICE sign already names it
	r.build(); r.save("wf_harbor_office")
