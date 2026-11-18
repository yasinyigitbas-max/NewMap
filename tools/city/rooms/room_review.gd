extends SceneTree
## Room review: the corrections Yasin made to the shop rooms on 18 Nov, as checks (Yasin: "can you upgrade the checker
## with my corrections"). The indoor checker (interiors/rooms/check_rooms.gd) tests footprints, walking reach and door
## swings; these test what a customer and an interior designer see, each from one of his corrections:
##   REPEAT  "what are those shops filled with vending machines?" - the same appliance or rack too many times in a room
##           (vending machines more than once, spinners / brochure racks more than twice, fridges more than four
##           outside a food store)
##   DECO    "it looks as if you just filled every wall with paintings, its too repetitive" - more than two wall
##           decorations on one wall, or more than six in a room
##   WALL    "there are wall props overlapping each other" - two wall-hung items overlapping, or one behind a tall prop
##   WIN     "the wall prop is overlapping a window" - a wall-hung item over an opening of the room's building
##   LONE    "why is there a filing cabinet in the middle of nowhere" / "the bin is in the middle of the room" - a prop
##           that belongs against a wall (cabinets, shelves, fridges, machines, boards) standing free, or a bin far
##           from any wall, counter, desk or table
##   FACE    "chair is facing the wrong direction" - a desk chair with its desk behind it, or a seat facing a wall
##   SEAT    "there isnt room for benches for people to sit, table is pushed all the way against them" - less than
##           0.45 m of free floor in front of a seat (the table / desk / counter it belongs to excepted)
##   OUTSEAT "lube room bench looking out looks awkward" - a bench at a window turned to face the glass
##   BINSHOP "whats the shop on the left? trash store? it has 3 thrash bins inside" - bins and receptacles making up a
##           large share of a room's things
##   SPARSE  "the lube room is bare" (and "lots of props") - fewer than 1.2 things per 10 m2 of shop floor
## Not testable from the saved room: the dark marks of frames showing through a wall shared by two shops (Yasin's
## picture of the dry cleaner) - the strip generator now stands a shared wall 0.12 m inside each shop; a generator
## that builds rows bay by bay must do the same.
## Run (real renderer: MultiMesh data):
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan --resolution 320x180 \
##       -s res://tools/city/rooms/room_review.gd [-- --prefix=g_strip_] [--quiet]
## Prints one line per finding ("REVIEW <check> <room>: ..."), then "REVIEW_DONE n findings in m rooms".
const ROOMS := "res://map_dc/coronado/city_kit/interiors/rooms/"
const D := "res://map_dc/coronado/city_kit/interiors/"
const AGAINST_WALL := ["prop_filing_cabinet", "prop_wall_shelf", "prop_pegboard_wall", "prop_drinks_fridge", "prop_vending_soda",
	"prop_vending_snack", "prop_cigarette_cabinet", "prop_salon_product_shelf", "prop_pharmacy_shelf", "prop_shoe_wall",
	"prop_wine_backbar", "prop_bakery_shelf", "prop_kitchen_line", "prop_mirror_station", "prop_washer", "prop_dryer"]   # (bookcases and gondolas stand free in rows: not listed)
const SEATS := ["prop_waiting_bench", "prop_side_chair", "prop_office_chair", "prop_cafe_chair", "prop_booth_bench", "prop_bar_stool",
	"prop_barber_chair", "prop_park_bench"]
const SIT_AT := ["prop_cafe_table", "prop_restaurant_table", "prop_office_desk", "prop_nail_table", "prop_bar_counter", "prop_shop_counter",
	"prop_mirror_station", "prop_wash_basin", "prop_booth_bench", "prop_cash_register", "prop_espresso_machine", "prop_checkout_counter",
	"prop_laundry_counter", "prop_glass_display_case", "prop_pastry_case", "prop_display_table"]
const TABLES := ["prop_cafe_table", "prop_restaurant_table", "prop_office_desk", "prop_nail_table", "prop_bar_counter", "prop_shop_counter",
	"prop_checkout_counter", "prop_laundry_counter", "prop_display_table", "prop_glass_display_case", "prop_pastry_case", "prop_workbench"]
const DECOR := ["prop_gallery_frame", "prop_poster_case", "prop_menu_board"]
const BINS := ["prop_indoor_bin", "prop_recycling_receptacle", "prop_trash_receptacle", "prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"]
const FOOD := ["grocery", "corner_shop", "gas", "discount", "drive_thru", "fast_food", "diner", "taqueria", "pizza", "bakery", "cafe", "ice_cream", "bar", "restaurant"]
const LIMIT := {"prop_vending_soda": 1, "prop_vending_snack": 1, "prop_card_spinner": 2, "prop_brochure_rack": 2}

var man := {}
var findings := 0

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var prefix := ""; var quiet := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--prefix="): prefix = a.trim_prefix("--prefix=")
		if a == "--quiet": quiet = true
	for f in DirAccess.get_files_at("res://assets/coronado_kit/props/"):
		if f.begins_with("manifest_") and f.ends_with(".json"):
			var v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/props/" + f))
			var items: Array = v if v is Array else (v as Dictionary).values()
			for e in items:
				if e is Dictionary and (e as Dictionary).has("file_base"): man[String(e.file_base)] = e
	# room scene -> its building model and shop kind, from every assignment table (generated rooms g_<id>, strip g_strip_<id>,
	# hand-made rooms by their "built" name)
	var contracts := {}
	for cf in ["room_contracts.json", "room_contracts_strip.json"]:
		if FileAccess.file_exists(D + cf): contracts.merge(JSON.parse_string(FileAccess.get_file_as_string(D + cf)).models, true)
	var info := {}
	for f in DirAccess.get_files_at(D):
		if not (f.begins_with("assignment_") and f.ends_with(".json")): continue
		var v2: Variant = JSON.parse_string(FileAccess.get_file_as_string(D + f))
		if not (v2 is Dictionary): continue
		var rows: Variant = (v2 as Dictionary).get("rooms", [])
		if not (rows is Array): continue
		for e: Variant in rows:
			if not (e is Dictionary) or not (e as Dictionary).has("id"): continue
			var ed: Dictionary = e
			var names: Array = ["g_" + String(ed.id), "g_strip_" + String(ed.id)]
			if String(ed.get("built", "")) != "": names.append(String(ed.built))
			for nm in names: info[nm] = {"model": String(ed.get("model", "")), "kind": String(ed.get("kind", ""))}
	var n_rooms := 0
	for f in DirAccess.get_files_at(ROOMS):
		if not f.ends_with(".scn") or (prefix != "" and not f.begins_with(prefix)): continue
		n_rooms += 1
		var rname := f.get_basename()
		var room: Node3D = (load(ROOMS + f) as PackedScene).instantiate(); root.add_child(room)
		_review(rname, room, info.get(rname, {}), contracts, quiet)
		room.queue_free()
	print("REVIEW_DONE %d findings in %d rooms" % [findings, n_rooms])
	quit()

func _say(check: String, room: String, msg: String, quiet: bool) -> void:
	findings += 1
	if not quiet or findings < 400: print("REVIEW %-7s %s: %s" % [check, room, msg])

func _review(rname: String, room: Node3D, inf: Dictionary, contracts: Dictionary, quiet: bool) -> void:
	var fy := float(room.get_meta(&"floor_y", 0.0)) if room.has_meta(&"floor_y") else 0.0
	# the room's floor (room_lib records each floor rect) and its partitions
	var fl: Array = room.get_meta(&"floors", []) if room.has_meta(&"floors") else []
	var bx := [INF, INF, -INF, -INF]; var area := 0.0
	for r: Variant in fl:
		var ra: Array = r
		bx = [minf(bx[0], float(ra[0])), minf(bx[1], float(ra[1])), maxf(bx[2], float(ra[2])), maxf(bx[3], float(ra[3]))]
		area += absf((float(ra[2]) - float(ra[0])) * (float(ra[3]) - float(ra[1])))
		if ra.size() > 4: fy = float(ra[4])
	var solids: Array = room.get_meta(&"solids", []) if room.has_meta(&"solids") else []
	var items: Array = []      # [base, Transform3D (room frame), w, d, h, mount]
	for mmi: MultiMeshInstance3D in room.find_children("*", "MultiMeshInstance3D", true, false):
		var base := String(mmi.name)
		if not (base.begins_with("prop_") or base.begins_with("plant_")): base = "prop_" + base
		var e: Dictionary = man.get(base, {})
		for i in mmi.multimesh.instance_count:
			var t: Transform3D = mmi.transform * mmi.multimesh.get_instance_transform(i)
			items.append([base, t, float(e.get("footprint_w", 0.5)), float(e.get("footprint_d", 0.5)), float(e.get("height", 1.0)), String(e.get("mount", "ground"))])
	if items.is_empty(): return
	var kind := String(inf.get("kind", ""))
	# --- REPEAT
	var count := {}
	for it: Array in items: count[it[0]] = int(count.get(it[0], 0)) + 1
	for b: String in count:
		var lim := int(LIMIT.get(b, 99))
		if b == "prop_drinks_fridge" and not (kind in FOOD): lim = 4
		if int(count[b]) > lim: _say("REPEAT", rname, "%d x %s (a customer sees the same thing over and over)" % [count[b], b], quiet)
	# --- wall-hung items: on which wall, how high
	var deco: Array = []
	for it: Array in items:
		var t: Transform3D = it[1]
		if String(it[5]) == "wall" or (String(it[0]) in DECOR and t.origin.y - fy > 0.8): deco.append(it)
	var per_wall := {}
	var n_dec := 0
	for it: Array in deco:
		if not (String(it[0]) in DECOR): continue
		n_dec += 1
		var t: Transform3D = it[1]; var fw := t.basis.z.normalized()
		var key := "%d_%d" % [roundi(fw.x * 2), roundi(fw.z * 2)] + "_%d" % roundi((t.origin.x if absf(fw.x) > 0.5 else t.origin.z) * 2.0)
		per_wall[key] = int(per_wall.get(key, 0)) + 1
	for k: String in per_wall:
		if int(per_wall[k]) > 2: _say("DECO", rname, "%d wall decorations on one wall" % per_wall[k], quiet)
	if n_dec > 6: _say("DECO", rname, "%d wall decorations in the room" % n_dec, quiet)
	# --- WALL: wall items overlapping each other
	for a in deco.size():
		for c in range(a + 1, deco.size()):
			var A: Array = deco[a]; var C: Array = deco[c]
			var ta: Transform3D = A[1]; var tc: Transform3D = C[1]
			var fa := ta.basis.z.normalized()
			if fa.dot(tc.basis.z.normalized()) < 0.94: continue
			var d := tc.origin - ta.origin
			if absf(d.dot(fa)) > 0.3: continue
			if absf(d.dot(Vector3(fa.z, 0, -fa.x))) >= (float(A[2]) + float(C[2])) * 0.5 - 0.02: continue
			if ta.origin.y + float(A[4]) <= tc.origin.y + 0.02 or tc.origin.y + float(C[4]) <= ta.origin.y + 0.02: continue
			_say("WALL", rname, "%s at (%.2f, %.2f) overlaps %s at (%.2f, %.2f)" % [A[0], ta.origin.x, ta.origin.z, C[0], tc.origin.x, tc.origin.z], quiet)
	# --- WIN: wall items over the building's openings (rooms are authored in their building model's frame)
	var model := String(inf.get("model", ""))
	if contracts.has(model):
		for A2: Array in deco:
			var t2: Transform3D = A2[1]
			for o: Dictionary in (contracts[model] as Dictionary).get("openings", []):
				if int(o.floor) != 0: continue
				var fr := String(o.facade) == "front" or String(o.facade) == "back"
				var along := t2.origin.x if fr else t2.origin.z
				if absf((t2.origin.z if fr else t2.origin.x) - float(o.plane)) > 0.8: continue
				if absf(along - float(o.along)) > (float(o.w) + float(A2[2])) * 0.5: continue
				if t2.origin.y < float(o.y1) and t2.origin.y + float(A2[4]) > float(o.y0):
					_say("WIN", rname, "%s at (%.2f, %.2f) hangs over the %s opening at %.2f" % [A2[0], t2.origin.x, t2.origin.z, o.facade, float(o.along)], quiet)
	# --- distance from a point to the nearest wall (floor edges, partitions)
	var wall_d := func(p: Vector3) -> float:
		var dd := minf(minf(p.x - float(bx[0]), float(bx[2]) - p.x), minf(p.z - float(bx[1]), float(bx[3]) - p.z))
		for s: Variant in solids:
			var sa: Array = s
			var ex := maxf(maxf(float(sa[0]) - p.x, p.x - float(sa[2])), 0.0); var ez := maxf(maxf(float(sa[1]) - p.z, p.z - float(sa[3])), 0.0)
			dd = minf(dd, sqrt(ex * ex + ez * ez))
		return dd
	var ground: Array = []
	for it: Array in items:
		if String(it[5]) != "wall" and not (String(it[0]) in DECOR): ground.append(it)
	if is_finite(float(bx[0])):
		# --- LONE: wall pieces standing free (not against a wall, not back to back), bins in the open
		for it: Array in ground:
			var t: Transform3D = it[1]; var b := String(it[0])
			if b in AGAINST_WALL:
				var back := t.origin - t.basis.z.normalized() * (float(it[3]) * 0.5 + 0.35)
				if float(wall_d.call(back)) > 0.45 and float(wall_d.call(t.origin)) > float(it[3]) * 0.5 + 0.5:
					var paired := false
					for o2: Array in ground:
						if o2 != it and String(o2[0]) in AGAINST_WALL and (o2[1] as Transform3D).origin.distance_to(back) < 0.6: paired = true
					if not paired: _say("LONE", rname, "%s at (%.2f, %.2f) stands in the open with no wall behind it" % [b, t.origin.x, t.origin.z], quiet)
			if b == "prop_indoor_bin" and float(wall_d.call(t.origin)) > 1.0:
				var near := false
				for o3: Array in ground:
					if (String(o3[0]) in TABLES or String(o3[0]) in SEATS) and (o3[1] as Transform3D).origin.distance_to(t.origin) - maxf(float(o3[2]), float(o3[3])) * 0.5 < 0.9: near = true   # by its edge; a bin by a bench is placed too
				if not near: _say("LONE", rname, "bin at (%.2f, %.2f) stands in the middle of the floor" % [t.origin.x, t.origin.z], quiet)
	# --- FACE and SEAT and OUTSEAT
	for S: Array in ground:
		if not (String(S[0]) in SEATS): continue
		var ts: Transform3D = S[1]; var fw2 := ts.basis.z.normalized(); var sd := Vector3(fw2.z, 0, -fw2.x)
		if String(S[0]) == "prop_office_chair":
			var ahead := false; var behind := false
			for P: Array in ground:
				if String(P[0]) != "prop_office_desk": continue
				var dp := (P[1] as Transform3D).origin - ts.origin
				if dp.length() > 1.3: continue
				if dp.dot(fw2) > 0.2: ahead = true
				elif dp.dot(fw2) < -0.2: behind = true
			if behind and not ahead: _say("FACE", rname, "desk chair at (%.2f, %.2f) has its back to its desk" % [ts.origin.x, ts.origin.z], quiet)
		var front := ts.origin + fw2 * (float(S[3]) * 0.5 + 0.25)
		if is_finite(float(bx[0])) and float(wall_d.call(front)) < 0.05 and String(S[0]) != "prop_booth_bench":
			_say("FACE", rname, "%s at (%.2f, %.2f) faces a wall" % [S[0], ts.origin.x, ts.origin.z], quiet)
		for P2: Array in ground:
			if P2 == S or String(P2[0]) in SIT_AT or String(P2[0]) in ["prop_potted_plant", "prop_indoor_bin"]: continue
			var tp: Transform3D = P2[1]; var d4 := tp.origin - front; var px := tp.basis.x.normalized()
			var ex2 := absf(px.dot(sd)) * float(P2[2]) * 0.5 + absf(px.dot(fw2)) * float(P2[3]) * 0.5
			var ez2 := absf(px.dot(fw2)) * float(P2[2]) * 0.5 + absf(px.dot(sd)) * float(P2[3]) * 0.5
			if absf(d4.dot(sd)) < float(S[2]) * 0.4 + ex2 and absf(d4.dot(fw2)) < 0.225 + ez2:
				_say("SEAT", rname, "%s at (%.2f, %.2f) has %s right in front of it - no room to sit" % [S[0], ts.origin.x, ts.origin.z, P2[0]], quiet); break
		if String(S[0]) == "prop_waiting_bench" and contracts.has(model):
			for o4: Dictionary in (contracts[model] as Dictionary).get("openings", []):
				if int(o4.floor) != 0 or String(o4.facade) != "front" or not String(o4.region).begins_with("O_") or String(o4.region).contains("door"): continue
				if absf(ts.origin.x - float(o4.along)) < float(o4.w) * 0.5 and float(o4.plane) - ts.origin.z < 1.4 and fw2.z > 0.7:
					_say("OUTSEAT", rname, "bench at (%.2f, %.2f) faces the window glass at arm's length" % [ts.origin.x, ts.origin.z], quiet); break
	# --- BINSHOP and SPARSE
	var n_bins := 0
	for it: Array in items:
		if String(it[0]) in BINS: n_bins += 1
	if n_bins >= 2 and float(n_bins) / items.size() > 0.25: _say("BINSHOP", rname, "%d of its %d things are bins - it reads as a trash shop" % [n_bins, items.size()], quiet)
	if area > 12.0 and items.size() / area * 10.0 < 1.2: _say("SPARSE", rname, "%d things on %.0f m2 - it looks bare" % [items.size(), area], quiet)
