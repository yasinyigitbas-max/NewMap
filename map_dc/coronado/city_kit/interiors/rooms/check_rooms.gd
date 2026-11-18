extends SceneTree
## Indoor checker (17 Nov, Yasin: "do some of the props overlap? do we have an indoors checker?").
## For every saved room in interiors/rooms/*.scn it checks the kit props (footprints and heights from the kit
## manifests, oriented) and the room's own build:
##   overlap   two floor props' footprints overlap (a chair pushed under its table is allowed)
##   floating  an item lifted more than 0.3 m stands on nothing (wall-mounted items are not floor props)
##   wall      a prop sticks out of the room's floor or into a partition / wall box
##   door      a prop stands in an entrance's swing zone (the leaves swing 95 degrees inward, plus the step in)
##   reach     a prop no one can walk up to (0.25 m grid flood from the entrances, 0.45 m clearance for a body)
##   hidden    a wall-mounted print / board with a taller floor prop in front of it
##   pot       a garden plant without a pot standing on the indoor floor
##   squeeze   the walkway from the entrance to the room's deepest reachable floor narrows under 0.8 m
## 18 Nov, from the gritty zone session (Yasin: "many on the wall props overlap, some of them are on windows, some of
## them are inside the ceiling"), for every wall-mounted item (prints, notices, menu boards, pegboards):
##   ceiling   its top reaches into the ceiling (the lowest ceiling face over it, from the room's own mesh)
##   window    it hangs over a window or a door of its wall (glass panes and door leaves within 0.6 m of its wall
##             plane, and the entrances the room records)
##   wallover  it overlaps another wall item on the same wall
##   behind    (19 Nov, Yasin: "there is a painting behind the mirror") it hangs behind a piece of furniture standing
##             within 0.8 m of its wall (a mirror station, a shelf, a fridge) that covers part of it along the wall and
##             is taller than its lower edge. "hidden" (0.45 m) stays as it was; "behind" reports what it misses.
## 18 Nov, from the industrial zone session:
##   doorway   (Yasin: "something blocking the door", "a thick seam like object") any part of the room's own build -
##             a storefront bulkhead, a plinth, a wall, a frame, a fixed pane - inside a door's passage: the door's
##             width (less 0.12 m at each jamb), 0.06 to 2.0 m above the floor, from 0.25 m inside the room's wall
##             through the facade to 0.9 m outside (the step slab, lower than 0.06 m, is allowed; the door leaves are
##             not tested)
##   bare      (Yasin: "most shelves are empty") a shelf, gondola, bookcase or back bar the kit ships without goods
## 19 Nov, the two merged and widened by the PC session (Yasin: "send back an even better version"):
##   ceiling   now for EVERY prop: a tall shelf or fridge through the ceiling is the same fault as a frame in it
##   stack     two items standing ON furniture (a register, a machine) overlap each other
##   offwall   a wall-mounted item with no wall behind it (more than 0.35 m from every wall of the room)
##   doorway   says what it found: "blocked from X m up" (a bulkhead, a plinth, a pane) or "low head at X m" (only the
##             top of the passage is touched: a lintel or transom under 2 m), so the two are not mixed up; it reads
##             every mesh of the room's build, not only the top-level shell
##   One pass reads the room's meshes for all of these.
##   window    ONE rule from the three the zone sessions wrote (gritty "window", residential "cover", strip "WIN"):
##             a wall item over a door or window of its wall, from every source there is: the openings the room
##             records (meta "openings", rooms built since 19 Nov: exact), the room's own glass panes and door
##             leaves, the entrances, and the building's contract openings at the item's hanging height. The message
##             says which source found it.
## 19 Nov, from the strip zone session (tools/city/rooms/room_review.gd, Yasin's corrections to the shop rooms), now
## part of this checker; what a customer sees:
##   repeat    "shops filled with vending machines": the same appliance or rack too often (vending more than 1,
##             spinners / brochure racks more than 2, fridges more than 4 outside a food store)
##   deco      "you just filled every wall with paintings": more than 2 wall decorations on one wall, more than 6 a room
##   lone      "a filing cabinet in the middle of nowhere", "the bin is in the middle of the room": a piece that belongs
##             against a wall standing free (not back to back with another), or a bin far from any wall, table or seat
##   face      "chair is facing the wrong direction": a desk chair with its back to its desk, a seat facing a wall
##   seat      "no room for benches for people to sit": less than 0.45 m of free floor in front of a seat (the table,
##             desk or counter it belongs to excepted)
##   outseat   "bench looking out looks awkward": a waiting bench turned to face a window at arm's length
##   binshop   "trash store?": bins making up more than a quarter of a room's things
##   sparse    "bare": fewer than 1.2 things per 10 m2 of floor
##   (--no-review leaves these eight out.)
##   unheld    (19 Nov, the gritty session's rule; Yasin: "whats that thing flying there?") a part of the room's OWN
##             build hangs in the air: a box (room_lib.box: bars, shelves, panels, fittings) that stands on no floor,
##             leans on no wall or partition, reaches no ceiling, sits on no prop and touches no other part that is
##             held. Needs the boxes room_lib records since 19 Nov (meta "boxes"): older rooms are counted, not tested.
## A LOCKED room (locked.json "files"): faults of the kinds added after it was locked (NEW_KINDS) are printed as NOTE
## and not counted: a locked room changes only with Yasin's word.
## Output like the city validator (tools/city/pilot/validate.gd): "CHECK <kind> room: ..." per problem, a table of
## kinds, then "CHECKS n problems"; exit code 1 if any. Run it after every room build.
##   godot --path . --rendering-method mobile -s res://map_dc/coronado/city_kit/interiors/rooms/check_rooms.gd
##   options after --:  --only=g_grt_,wf_cafe   rooms whose name starts with one of these
##                      --kinds=doorway,bare    only these kinds are reported and counted
##                      --json=OUT/rooms.json   every finding as a list, to compare two runs
##                      --quiet                 no "ROOM ..." line per room
##                      --no-review             only the hard faults, not the eight customer's-eye kinds
## Needs the real renderer (MultiMesh data).
const K := preload("res://tools/city/pilot/kit_lib.gd")
const DIR := "res://map_dc/coronado/city_kit/interiors/rooms/"
const MAN := "res://assets/coronado_kit/props/"
## decor no one needs to walk up to (pots in corners, bins): exempt from "reach"
const DECOR := ["prop_potted_plant", "prop_indoor_bin"]
const WALL_MOUNT := ["prop_gallery_frame", "prop_menu_board", "prop_pegboard_wall"]
const STORAGE := ["shelf", "gondola", "bookcase", "backbar"]
## kinds that did not exist when the hand-made rooms were locked
const REVIEW_KINDS := ["repeat", "deco", "lone", "face", "seat", "outseat", "binshop", "sparse"]
const NEW_KINDS := ["unheld", "behind", "ceiling", "window", "wallover", "doorway", "bare", "stack", "offwall", "repeat", "deco", "lone", "face", "seat", "outseat", "binshop", "sparse"]
const INTERIORS := "res://map_dc/coronado/city_kit/interiors/"
## the review's lists (from room_review.gd)
const AGAINST_WALL := ["prop_filing_cabinet", "prop_wall_shelf", "prop_pegboard_wall", "prop_drinks_fridge", "prop_vending_soda",
	"prop_vending_snack", "prop_cigarette_cabinet", "prop_salon_product_shelf", "prop_pharmacy_shelf", "prop_shoe_wall",
	"prop_wine_backbar", "prop_bakery_shelf", "prop_kitchen_line", "prop_mirror_station", "prop_washer", "prop_dryer"]   # (bookcases and gondolas stand free in rows: not listed)
const REV_SEATS := ["prop_waiting_bench", "prop_side_chair", "prop_office_chair", "prop_cafe_chair", "prop_booth_bench", "prop_bar_stool",
	"prop_barber_chair", "prop_park_bench"]
const SIT_AT := ["prop_cafe_table", "prop_restaurant_table", "prop_office_desk", "prop_nail_table", "prop_bar_counter", "prop_shop_counter",
	"prop_mirror_station", "prop_wash_basin", "prop_booth_bench", "prop_cash_register", "prop_espresso_machine", "prop_checkout_counter",
	"prop_laundry_counter", "prop_glass_display_case", "prop_pastry_case", "prop_display_table"]
const REV_TABLES := ["prop_cafe_table", "prop_restaurant_table", "prop_office_desk", "prop_nail_table", "prop_bar_counter", "prop_shop_counter",
	"prop_checkout_counter", "prop_laundry_counter", "prop_display_table", "prop_glass_display_case", "prop_pastry_case", "prop_workbench"]
const DECO_ITEMS := ["prop_gallery_frame", "prop_poster_case", "prop_menu_board"]
const BINS := ["prop_indoor_bin", "prop_recycling_receptacle", "prop_trash_receptacle", "prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"]
const FOOD := ["grocery", "corner_shop", "gas", "discount", "drive_thru", "fast_food", "diner", "taqueria", "pizza", "bakery", "cafe", "ice_cream", "bar", "restaurant"]
const LIMIT := {"prop_vending_soda": 1, "prop_vending_snack": 1, "prop_card_spinner": 2, "prop_brochure_rack": 2}
var foot := {}
var tall := {}
var wallm := {}     # props the kit manifests mount on a wall (poster case, menu board ...)
var goods := {}     # base -> true when the kit model carries goods (a tg_* trim in its manifest)
var problems := 0
var notes := 0
var locked := {}     # res:// paths of locked room files
var cur_locked := false
var by_kind := {}    # kind -> [problems, notes]
var by_room := {}    # room -> problems
var found: Array = []      # [room, kind, message, "CHECK" | "NOTE"]
var only: PackedStringArray = []
var kinds_only: PackedStringArray = []
var json_out := ""
var quiet := false
var no_review := false
var info := {}          # room name -> {model, kind} from every interiors/assignment_*.json
var contracts := {}     # building model -> its contract (openings ...) from every interiors/room_contracts*.json
var no_openings := 0    # rooms that do not record their openings (built before 19 Nov)
var no_boxes := 0       # rooms that do not record their boxes (built before the "unheld" rule)

func _init() -> void: _run.call_deferred()

func _run() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="): only = a.trim_prefix("--only=").split(",", false)
		if a.begins_with("--kinds="): kinds_only = a.trim_prefix("--kinds=").split(",", false)
		if a.begins_with("--json="): json_out = a.trim_prefix("--json=")
		if a == "--quiet": quiet = true
		if a == "--no-review": no_review = true
	for f in DirAccess.get_files_at(MAN):
		if f.begins_with("manifest_") and f.ends_with(".json"): _man(MAN + f)   # indoor kit + street kit props used indoors (vending, fountain)
	_man("res://assets/coronado_kit/foliage/manifest_foliage.json")
	var lk: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/locked.json"))
	if lk is Dictionary:
		var fl: Variant = (lk as Dictionary).get("files", {})
		for k: Variant in (fl as Dictionary).keys() if fl is Dictionary else (fl as Array): locked[String(k).trim_prefix("res://")] = true
	# which building model and what kind of shop each room is (for the contract openings and the review)
	for f in DirAccess.get_files_at(INTERIORS):
		if f.begins_with("room_contracts") and f.ends_with(".json"):
			var cv: Variant = JSON.parse_string(FileAccess.get_file_as_string(INTERIORS + f))
			if cv is Dictionary and (cv as Dictionary).get("models") is Dictionary: contracts.merge((cv as Dictionary).models, true)
		if f.begins_with("assignment_") and f.ends_with(".json"):
			var zone := f.trim_prefix("assignment_").trim_suffix(".json")
			var av: Variant = JSON.parse_string(FileAccess.get_file_as_string(INTERIORS + f))
			var rows: Variant = (av as Dictionary).get("rooms", []) if av is Dictionary else []
			if rows is Array:
				for e: Variant in rows:
					if not (e is Dictionary) or not (e as Dictionary).has("id"): continue
					var ed: Dictionary = e
					var names: Array = ["g_" + String(ed.id), "g_%s_%s" % [zone, String(ed.id)]]
					if String(ed.get("built", "")) != "": names.append(String(ed.built))
					for nm: String in names:
						if not info.has(nm): info[nm] = {"model": String(ed.get("model", "")), "kind": String(ed.get("kind", ""))}
	var rooms: Array = []
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".scn"): continue
		var keep := only.is_empty()
		for o: String in only:
			if f.begins_with(o): keep = true
		if keep: rooms.append(f)
	rooms.sort()
	print("CHECKS loaded %d rooms" % rooms.size())
	for f: String in rooms:
		cur_locked = locked.has((DIR + f).trim_prefix("res://"))
		var inst: Node3D = (load(DIR + f) as PackedScene).instantiate()
		_room(f.get_basename(), inst)
		inst.free()
	# the table: what kinds, how many, where
	var kk: Array = by_kind.keys(); kk.sort()
	for k2: String in kk: print("CHECKS-KIND %-9s %4d problems%s" % [k2, int(by_kind[k2][0]), ("  (+%d notes in locked rooms)" % int(by_kind[k2][1])) if int(by_kind[k2][1]) > 0 else ""])
	var rr: Array = by_room.keys()
	rr.sort_custom(func(a: String, b: String) -> bool: return int(by_room[a]) > int(by_room[b]))
	if not rr.is_empty(): print("CHECKS-ROOMS %d of %d rooms have problems; most: %s" % [rr.size(), rooms.size(), ", ".join(rr.slice(0, 8).map(func(r: String) -> String: return "%s (%d)" % [r, int(by_room[r])]))])
	if no_openings > 0: print("CHECKS-INFO %d rooms do not record their openings (built before 19 Nov): for them 'window' relies on their glass, their entrances and the building's contract; a rebuild makes it exact" % no_openings)
	if no_boxes > 0: print("CHECKS-INFO %d rooms do not record the boxes of their own build: 'unheld' (a part hanging in the air) is not tested in them until they are rebuilt" % no_boxes)
	if notes > 0: print("CHECKS-NOTE %d faults of the newer kinds in LOCKED rooms (not counted: they change only with Yasin's word)" % notes)
	if json_out != "":
		var jf := FileAccess.open(json_out, FileAccess.WRITE)
		if jf: jf.store_string(JSON.stringify(found, " ")); jf.close()
	print("CHECKS %d problems" % problems)
	quit(1 if problems else 0)

func _man(p: String) -> void:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if v == null: return
	var items: Array = v if v is Array else (v as Dictionary).values()
	for e: Variant in items:
		if not (e is Dictionary and (e as Dictionary).has("file_base")): continue
		foot[String(e.file_base)] = Vector2(float(e.get("footprint_w", 0.5)), float(e.get("footprint_d", 0.5)))
		tall[String(e.file_base)] = float(e.get("height", 1.0))
		if String(e.get("mount", "")) == "wall": wallm[String(e.file_base)] = true
		var tr: Variant = e.get("trim", {})
		if tr is Dictionary:
			for tk: String in (tr as Dictionary):
				if tk.begins_with("tg_"): goods[String(e.file_base)] = true

func _report(room: String, kind: String, msg: String) -> void:
	if not kinds_only.is_empty() and not (kind in kinds_only): return
	if no_review and kind in REVIEW_KINDS: return
	if not by_kind.has(kind): by_kind[kind] = [0, 0]
	if cur_locked and kind in NEW_KINDS:
		notes += 1; by_kind[kind][1] = int(by_kind[kind][1]) + 1
		found.append([room, kind, msg, "NOTE"])
		print("NOTE  %-8s %s (locked): %s" % [kind, room, msg]); return
	problems += 1; by_kind[kind][0] = int(by_kind[kind][0]) + 1
	by_room[room] = int(by_room.get(room, 0)) + 1
	found.append([room, kind, msg, "CHECK"])
	print("CHECK %-8s %s: %s" % [kind, room, msg])

## Every triangle of the room's own build (not the props), room-local: [a, b, c, what] with what = 0 solid, 1 a fixed
## glass pane, 2 a door leaf. Read once per room, used by ceiling, window and doorway.
func _shell(root: Node3D) -> Array:
	var out: Array = []
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null: continue
		var under_props := false
		var xf := mi.transform
		var par := mi.get_parent()
		var is_leaf := mi.has_meta(&"hinge_axis")
		while par != null and par != root:
			if String(par.name) == "Props" or String(par.name) == "Lights": under_props = true
			if par.has_meta(&"hinge_axis") or String(par.name).begins_with("DoorLeaf"): is_leaf = true
			if par is Node3D: xf = (par as Node3D).transform * xf
			par = par.get_parent()
		if under_props or String(mi.name) == "wear" or String(mi.name) == "Signs": continue      # floor wear and signs are skins, not build
		for si in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(si)
			var glass := (mat is BaseMaterial3D and (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED) or String(mi.mesh.surface_get_name(si)).contains("glass")
			var what := 2 if is_leaf else (1 if glass else 0)
			var arr := mi.mesh.surface_get_arrays(si)
			var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ii: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var n := ii.size() if ii.size() > 0 else vv.size()
			for k in range(0, n - 2, 3):
				out.append([xf * vv[ii[k] if ii.size() > 0 else k], xf * vv[ii[k + 1] if ii.size() > 0 else k + 1], xf * vv[ii[k + 2] if ii.size() > 0 else k + 2], what])
	return out

func _room(name: String, root: Node3D) -> void:
	root.name = name
	var floors: Array = root.get_meta(&"floors", [])
	var solids: Array = root.get_meta(&"solids", [])
	var doors: Array = root.get_meta(&"entrances", [])
	var props: Array = []      # [base, center Vector2, half Vector2, angle, lift]
	var pn := root.get_node_or_null("Props")
	if pn == null: return
	for ch: Node in pn.get_children():
		if not (ch is MultiMeshInstance3D): continue
		var mmi := ch as MultiMeshInstance3D
		var base := String(mmi.name)
		var mm := mmi.multimesh
		if mm == null: continue
		var fp: Vector2 = foot.get(base, Vector2(0.4, 0.4))
		if base.begins_with("plant_"): fp = Vector2(minf(fp.x, 0.6), minf(fp.y, 0.6))   # pots: the pot, not the leaves
		for i in mm.instance_count:
			var t := mm.get_instance_transform(i)
			var ang := atan2(t.basis.z.x, t.basis.z.z)
			props.append([base, Vector2(t.origin.x, t.origin.z), fp * 0.5, ang, t.origin.y])
	var ground: Array = []
	var lifted: Array = []
	var miny := INF
	for p: Array in props: miny = minf(miny, float(p[4]))
	if miny == INF: miny = 0.0
	for p: Array in props:
		if base_mounted(String(p[0])): continue
		if float(p[4]) - miny > 0.3:
			# an item ON something: it must stand on a floor prop
			var on := false
			for q: Array in props:
				if q == p or float(q[4]) - miny > 0.3: continue
				if _hit(p[1], Vector2(0.02, 0.02), 0.0, q[1], q[2], q[3]): on = true; break
			if not on and not String(p[0]).begins_with("plant_"): _report(name, "floating", "%s at %s stands %.2f m up on nothing" % [p[0], _v(p[1]), float(p[4]) - miny])
			lifted.append(p)
			continue
		ground.append(p)
	# overlaps on the floor
	for i in ground.size():
		for j in range(i + 1, ground.size()):
			var a: Array = ground[i]; var b: Array = ground[j]
			if (a[1] as Vector2).distance_to(b[1]) > (a[2] as Vector2).length() + (b[2] as Vector2).length(): continue
			if _tucked(String(a[0]), String(b[0])): continue      # a chair pushed in under its table or desk
			if _hit(a[1], (a[2] as Vector2) * 0.95, a[3], b[1], (b[2] as Vector2) * 0.95, b[3]):
				_report(name, "overlap", "%s at %s  x  %s at %s" % [a[0], _v(a[1]), b[0], _v(b[1])])
	# stack: two items standing on furniture at the same height overlap each other
	for i in lifted.size():
		for j in range(i + 1, lifted.size()):
			var la: Array = lifted[i]; var lb: Array = lifted[j]
			if absf(float(la[4]) - float(lb[4])) > 0.3: continue
			if (la[1] as Vector2).distance_to(lb[1]) > (la[2] as Vector2).length() + (lb[2] as Vector2).length(): continue
			if _hit(la[1], (la[2] as Vector2) * 0.9, la[3], lb[1], (lb[2] as Vector2) * 0.9, lb[3]):
				_report(name, "stack", "%s at %s  x  %s at %s, both %.2f m up" % [la[0], _v(la[1]), lb[0], _v(lb[1]), float(la[4]) - miny])
	# hidden: a wall-mounted print / board with a floor prop standing in front of it, taller than its bottom edge
	for m: Array in props:
		if not base_mounted(String(m[0])): continue
		var fwd := Vector2(sin(float(m[3])), cos(float(m[3])))     # the print faces +Z (into the room)
		var zone_c: Vector2 = (m[1] as Vector2) + fwd * 0.45
		var bottom := float(m[4]) - miny
		for g: Array in ground:
			if float(tall.get(String(g[0]), 1.0)) <= bottom: continue
			if String(m[0]) == "prop_pegboard_wall" and String(g[0]) == "prop_workbench": continue   # the tool board over its bench
			if _hit(zone_c, Vector2(float((m[2] as Vector2).x), 0.45), float(m[3]), g[1], g[2], g[3]):
				_report(name, "hidden", "%s at %s is covered by %s at %s" % [m[0], _v(m[1]), g[0], _v(g[1])])
	var shell := _shell(root)
	var ops := _openings(name, root, miny)
	_wall_items(name, root, props, miny, shell, floors, solids, ops)
	_review(name, props, ground, miny, floors, solids, ops)
	_unheld(name, root, props, miny, floors, solids, shell)
	_ceiling_all(name, props, miny, shell)
	# pot: indoors a plant stands in a pot - a garden plant (no pot in its model) cannot grow out of the floor
	for g2: Array in ground:
		var b2 := String(g2[0])
		if (b2.begins_with("plant_") or b2.begins_with("tree_") or b2.begins_with("palm_")) and not b2.contains("potted"):
			_report(name, "pot", "%s at %s grows out of the floor (no pot)" % [b2, _v(g2[1])])
	# walls: every corner on the floor, nothing inside a partition
	for p: Array in ground:
		for c: Vector2 in _corners(p[1], p[2], p[3]):
			var inside := false
			for r: Array in floors:
				if c.x >= float(r[0]) - 0.02 and c.x <= float(r[2]) + 0.02 and c.y >= float(r[1]) - 0.02 and c.y <= float(r[3]) + 0.02: inside = true; break
			if not inside: _report(name, "wall", "%s at %s sticks out of the room (corner %s)" % [p[0], _v(p[1]), _v(c)]); break
		for s: Array in solids:
			var sc := Vector2((float(s[0]) + float(s[2])) * 0.5, (float(s[1]) + float(s[3])) * 0.5)
			var sh := Vector2((float(s[2]) - float(s[0])) * 0.5, (float(s[3]) - float(s[1])) * 0.5) - Vector2(0.01, 0.01)
			if sh.x <= 0 or sh.y <= 0: continue
			if _hit(p[1], (p[2] as Vector2) * 0.95, p[3], sc, sh, 0.0): _report(name, "wall", "%s at %s stands in a partition at %s" % [p[0], _v(p[1]), _v(sc)])
	# door swing zones: the opening's width, 1.4 m in (95-degree leaves + the step in)
	var zones: Array = []
	for d: Array in doors:
		var inward := -signf(float(d[4]) - float(d[1]))
		var s0 := float(d[2]); var s1 := float(d[3]); var at := float(d[1])
		var z0 := at; var z1 := at + inward * 1.4
		var r := Rect2(Vector2(s0 - 0.1, minf(z0, z1)), Vector2(s1 - s0 + 0.2, 1.4)) if d[0] == "z" else Rect2(Vector2(minf(z0, z1), s0 - 0.1), Vector2(1.4, s1 - s0 + 0.2))
		zones.append(r)
		for p: Array in ground:
			if _hit(p[1], p[2], p[3], r.get_center(), r.size * 0.5, 0.0): _report(name, "door", "%s at %s stands in the door swing at %s" % [p[0], _v(p[1]), _v(r.get_center())])
	# bare: shelving the kit ships empty
	var seen_bare := {}
	for p: Array in props:
		var bp := String(p[0])
		var is_store := false
		for w: String in STORAGE:
			if bp.contains(w): is_store = true
		if is_store and not goods.has(bp) and not seen_bare.has(bp):
			seen_bare[bp] = true
			_report(name, "bare", "%s at %s is an empty shelf model (no goods in the kit)" % [bp, _v(p[1])])
	_doorways(name, doors, miny, shell)
	# reach: walkable grid flood from the door zones
	if floors.is_empty() or zones.is_empty(): return
	var bb := Rect2(Vector2(floors[0][0], floors[0][1]), Vector2.ZERO)
	for r2: Array in floors: bb = bb.expand(Vector2(r2[0], r2[1])).expand(Vector2(r2[2], r2[3]))
	var G := 0.25; var nx := int(ceil(bb.size.x / G)); var nz := int(ceil(bb.size.y / G))
	var free := PackedByteArray(); free.resize(nx * nz)
	for ix in nx:
		for iz in nz:
			var c := bb.position + Vector2((ix + 0.5) * G, (iz + 0.5) * G)
			var ok := true
			for off: Vector2 in [Vector2(0.2, 0), Vector2(-0.2, 0), Vector2(0, 0.2), Vector2(0, -0.2), Vector2.ZERO]:
				var pin := false
				for r3: Array in floors:
					var pp := c + off
					if pp.x > float(r3[0]) and pp.x < float(r3[2]) and pp.y > float(r3[1]) and pp.y < float(r3[3]): pin = true; break
				if not pin: ok = false; break
			if ok:
				for s2: Array in solids:
					if c.x > float(s2[0]) - 0.22 and c.x < float(s2[2]) + 0.22 and c.y > float(s2[1]) - 0.22 and c.y < float(s2[3]) + 0.22: ok = false
			if ok:
				for p: Array in ground:
					if _hit(c, Vector2(0.22, 0.22), 0.0, p[1], p[2], p[3]): ok = false; break
			free[ix * nz + iz] = 1 if ok else 0
	var seen := PackedByteArray(); seen.resize(nx * nz)
	var q: Array = []
	for r4: Rect2 in zones:
		for ix in nx:
			for iz in nz:
				var c2 := bb.position + Vector2((ix + 0.5) * G, (iz + 0.5) * G)
				if r4.has_point(c2) and free[ix * nz + iz] == 1: seen[ix * nz + iz] = 1; q.append(Vector2i(ix, iz))
	while not q.is_empty():
		var cur: Vector2i = q.pop_back()
		for dd: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := cur + dd
			if n.x < 0 or n.y < 0 or n.x >= nx or n.y >= nz: continue
			var k := n.x * nz + n.y
			if free[k] == 1 and seen[k] == 0: seen[k] = 1; q.append(n)
	for p: Array in ground:
		var reach := false
		for ix in nx:
			for iz in nz:
				if seen[ix * nz + iz] == 0: continue
				var c3 := bb.position + Vector2((ix + 0.5) * G, (iz + 0.5) * G)
				if _hit(c3, Vector2(0.6, 0.6), 0.0, p[1], p[2], p[3]): reach = true; break
			if reach: break
		if not reach and not (String(p[0]) in DECOR or String(p[0]).begins_with("plant_")): _report(name, "reach", "%s at %s cannot be walked up to" % [p[0], _v(p[1])])
	var nfree := 0; var nseen := 0
	for k2 in free.size(): nfree += int(free[k2]); nseen += int(seen[k2])
	if nseen < nfree * 0.8: _report(name, "reach", "only %d of %d walkable floor cells reachable from the doors" % [nseen, nfree])
	if not quiet: print("ROOM %s: %d props (%d on the floor), %d doors, %d of %d floor cells reachable" % [name, props.size(), ground.size(), doors.size(), nseen, nfree])

## the lowest ceiling face over a point (INF if none): downward- or upward-facing solid faces more than 1.8 m up
func _ceiling_over(shell: Array, at: Vector2, miny: float) -> float:
	var c_y := INF
	for t: Array in shell:
		if int(t[3]) != 0: continue
		var a: Vector3 = t[0]; var b: Vector3 = t[1]; var c: Vector3 = t[2]
		var cy := (a.y + b.y + c.y) / 3.0
		if cy <= miny + 1.8 or cy >= c_y: continue
		var nn := (b - a).cross(c - a)
		if nn.length_squared() < 1e-10 or absf(nn.normalized().y) < 0.9: continue
		if Geometry2D.point_is_inside_triangle(at, Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)): c_y = cy
	return c_y

## ceiling, for every prop that is not on a wall (the wall items have their own, with their width): the top of the
## model against the lowest ceiling face over its middle
func _ceiling_all(name: String, props: Array, miny: float, shell: Array) -> void:
	var done := {}
	for p: Array in props:
		var bs := String(p[0])
		if base_mounted(bs) or bs.begins_with("plant_") or bs.begins_with("tree_") or bs.begins_with("palm_"): continue      # leaves may brush a ceiling
		var top := float(p[4]) + float(tall.get(bs, 1.0))
		if top - miny < 1.8: continue
		var c_y := _ceiling_over(shell, p[1], miny)
		if c_y < INF and top > c_y + 0.02 and not done.has(bs):
			done[bs] = true
			_report(name, "ceiling", "%s at %s reaches %.2f m, the ceiling is at %.2f m" % [bs, _v(p[1]), top - miny, c_y - miny])

## the wall items' own checks (ceiling / window / wallover / offwall, see the header)
func _wall_items(name: String, root: Node3D, props: Array, miny: float, shell: Array, floors: Array, solids: Array, ops: Array) -> void:
	var open_t: Array = []      # glass panes and door leaves: upright faces
	for t: Array in shell:
		if int(t[3]) == 0: continue
		var nn := ((t[1] as Vector3) - (t[0] as Vector3)).cross((t[2] as Vector3) - (t[0] as Vector3))
		if nn.length_squared() < 1e-10: continue
		if absf(nn.normalized().y) < 0.3: open_t.append(t)
	var doors: Array = root.get_meta(&"entrances", [])
	var items: Array = []      # [base, centre Vector2, half width, y0, y1, facing Vector2]
	for p: Array in props:
		var bs := String(p[0])
		if not base_mounted(bs): continue
		var fw := float((p[2] as Vector2).x) * 2.0
		var h := float(tall.get(bs, 1.0))
		var y0 := float(p[4]); var y1 := y0 + h
		var fwd := Vector2(sin(float(p[3])), cos(float(p[3])))
		var side := Vector2(fwd.y, -fwd.x)
		items.append([bs, p[1], fw * 0.5, y0, y1, fwd])
		# ceiling: the lowest ceiling face within the item's width over it
		var c_y := INF
		for sgn: float in [-0.9, 0.0, 0.9]: c_y = minf(c_y, _ceiling_over(shell, (p[1] as Vector2) + side * fw * 0.5 * sgn + fwd * 0.15, miny))
		if c_y < INF and y1 > c_y - 0.01: _report(name, "ceiling", "%s at %s reaches %.2f m, the ceiling is at %.2f m" % [bs, _v(p[1]), y1 - miny, c_y - miny])
		# windows and doors in its wall: glass / door-leaf faces within 0.6 m of its plane, overlapping its rectangle
		var hit_open := false
		var src := "the room's glass"
		# 1. the openings on record (the room's own, the entrances, the building's contract), at the item's height
		var along_x := absf(fwd.y) > absf(fwd.x)      # faces +-z: it hangs on a wall running along x (axis "z")
		var ia := (p[1] as Vector2).x if along_x else (p[1] as Vector2).y
		var iw := (p[1] as Vector2).y if along_x else (p[1] as Vector2).x
		for o: Array in ops:
			if (String(o[0]) == "z") != along_x: continue
			if absf(iw - float(o[1])) > float(o[8]): continue
			if ia - fw * 0.5 < float(o[3]) - 0.03 and ia + fw * 0.5 > float(o[2]) + 0.03 and y0 - miny < float(o[5]) - 0.03 and y1 - miny > float(o[4]) + 0.03:
				hit_open = true; src = "%s %s, %.2f..%.2f along the wall, %.2f..%.2f m up" % [o[7], o[6], float(o[2]), float(o[3]), float(o[4]), float(o[5])]; break
		# 2. the room's own glass panes and door leaves
		for t2: Array in open_t:
			if hit_open: break
			var tc: Vector3 = ((t2[0] as Vector3) + (t2[1] as Vector3) + (t2[2] as Vector3)) / 3.0
			var d2 := Vector2(tc.x, tc.z) - (p[1] as Vector2)
			if absf(d2.dot(fwd)) > 0.6: continue
			var a0 := INF; var a1 := -INF; var ty0 := INF; var ty1 := -INF
			for v3: Vector3 in [t2[0], t2[1], t2[2]]:
				var al := (Vector2(v3.x, v3.z) - (p[1] as Vector2)).dot(side)
				a0 = minf(a0, al); a1 = maxf(a1, al); ty0 = minf(ty0, v3.y); ty1 = maxf(ty1, v3.y)
			if a1 > -fw * 0.5 + 0.02 and a0 < fw * 0.5 - 0.02 and ty1 > y0 + 0.02 and ty0 < y1 - 0.02: hit_open = true; break
		if hit_open: _report(name, "window", "%s at %s hangs over a window or door of its wall (%s)" % [bs, _v(p[1]), src])
		# offwall: a wall item needs a wall behind it: the edge of a floor rectangle that is not shared with another
		# floor rectangle, or the face of a partition
		if not floors.is_empty():
			var near := _wall_dist(p[1], floors, solids)
			if near > 0.35 and near < INF: _report(name, "offwall", "%s at %s has no wall behind it (the nearest is %.2f m away)" % [bs, _v(p[1]), near])
	# behind furniture: a floor prop within 0.8 m of the item's wall whose footprint overlaps the item along the wall
	# and whose top is above the item's lower edge (not reported again where "hidden" already has the pair)
	for it: Array in items:
		var fw2 := it[5] as Vector2; var sd2 := Vector2(fw2.y, -fw2.x)
		for g: Array in props:
			if base_mounted(String(g[0])) or float(g[4]) - miny > 0.3: continue
			var gb := String(g[0])
			if float(tall.get(gb, 1.0)) <= float(it[3]) - miny + 0.02: continue
			if gb == "prop_workbench" and String(it[0]) == "prop_pegboard_wall": continue
			var rel := (g[1] as Vector2) - (it[1] as Vector2)
			var depth := rel.dot(fw2)
			var ghalf := g[2] as Vector2
			var ga := float(g[3])
			var ext_along := absf(ghalf.x * Vector2(cos(ga), -sin(ga)).dot(sd2)) + absf(ghalf.y * Vector2(sin(ga), cos(ga)).dot(sd2))
			var ext_out := absf(ghalf.x * Vector2(cos(ga), -sin(ga)).dot(fw2)) + absf(ghalf.y * Vector2(sin(ga), cos(ga)).dot(fw2))
			if depth - ext_out > 0.8 or depth + ext_out < 0.0: continue
			if absf(rel.dot(sd2)) >= float(it[2]) + ext_along - 0.03: continue
			var ang_it := atan2(fw2.x, fw2.y)
			if _hit((it[1] as Vector2) + fw2 * 0.45, Vector2(float(it[2]), 0.45), ang_it, g[1], g[2], g[3]): continue      # "hidden" has it
			_report(name, "behind", "%s at %s hangs behind %s at %s" % [it[0], _v(it[1]), gb, _v(g[1])])
	# two wall items on one wall overlapping
	for i in items.size():
		for j in range(i + 1, items.size()):
			var A: Array = items[i]; var B: Array = items[j]
			if (A[5] as Vector2).dot(B[5]) < 0.95: continue
			var dd := (B[1] as Vector2) - (A[1] as Vector2)
			if absf(dd.dot(A[5])) > 0.3: continue
			var sd := Vector2((A[5] as Vector2).y, -(A[5] as Vector2).x)
			if absf(dd.dot(sd)) < float(A[2]) + float(B[2]) - 0.02 and float(A[3]) < float(B[4]) - 0.02 and float(B[3]) < float(A[4]) - 0.02:
				_report(name, "wallover", "%s at %s overlaps %s at %s on the same wall" % [A[0], _v(A[1]), B[0], _v(B[1])])

## unheld: every box of the room's own build must be held by something. Held = on the floor, or against a wall or
## partition (a side within 3 cm of one, or beyond the floor's edge), or up at the ceiling, or on a prop's top; and
## whatever touches a held box is held too (a shelf board on its bracket).
func _unheld(name: String, root: Node3D, props: Array, miny: float, floors: Array, solids: Array, shell: Array) -> void:
	if not root.has_meta(&"boxes"): no_boxes += 1; return
	var boxes: Array = root.get_meta(&"boxes", [])
	if boxes.is_empty() or floors.is_empty(): return
	var held := PackedByteArray(); held.resize(boxes.size())
	var bb: Array = []
	for i in boxes.size():
		var b: Array = boxes[i]
		var c := Vector3(float(b[0]), float(b[1]), float(b[2])); var h := Vector3(float(b[3]), float(b[4]), float(b[5])) * 0.5
		bb.append(AABB(c - h, h * 2.0))
		var ok := c.y - h.y <= miny + 0.03      # on the floor
		if not ok:      # up at the ceiling: the highest face of the room over its middle
			var top := -INF
			for t: Array in shell:
				if int(t[3]) != 0: continue
				var ta: Vector3 = t[0]; var tb: Vector3 = t[1]; var tc: Vector3 = t[2]
				var ty := (ta.y + tb.y + tc.y) / 3.0
				if ty <= top or ty < c.y + h.y - 0.001: continue
				var nn := (tb - ta).cross(tc - ta)
				if nn.length_squared() < 1e-10 or absf(nn.normalized().y) < 0.9: continue
				if Geometry2D.point_is_inside_triangle(Vector2(c.x, c.z), Vector2(ta.x, ta.z), Vector2(tb.x, tb.z), Vector2(tc.x, tc.z)): top = ty
			# its own top face is the lowest candidate; anything within 3 cm above it means it reaches the ceiling
			ok = top > -INF and top - (c.y + h.y) <= 0.03 and top > miny + 1.8 and _is_room_top(shell, Vector2(c.x, c.z), top)
		if not ok:      # against a wall or partition
			for q: Vector2 in [Vector2(c.x - h.x, c.z), Vector2(c.x + h.x, c.z), Vector2(c.x, c.z - h.z), Vector2(c.x, c.z + h.z)]:
				if not _on_floor(q, floors, []) or _wall_dist(q, floors, solids) <= 0.03: ok = true; break
		if not ok:      # on a prop
			for p: Array in props:
				var ptop := float(p[4]) + float(tall.get(String(p[0]), 1.0))
				if absf((c.y - h.y) - ptop) <= 0.05 and _hit(Vector2(c.x, c.z), Vector2(h.x, h.z), 0.0, p[1], p[2], p[3]): ok = true; break
		held[i] = 1 if ok else 0
	var changed := true
	while changed:      # what touches a held part is held
		changed = false
		for i in boxes.size():
			if held[i] == 1: continue
			for j in boxes.size():
				if held[j] == 1 and (bb[i] as AABB).grow(0.03).intersects(bb[j]): held[i] = 1; changed = true; break
	var said := 0
	for i in boxes.size():
		if held[i] == 1: continue
		var b2: Array = boxes[i]
		said += 1
		if said <= 4: _report(name, "unheld", "a part of the room's build (%s, %.2f x %.2f x %.2f m) at (%.2f, %.2f), %.2f..%.2f m up, hangs in the air: it touches no floor, wall, ceiling, prop or held part" % [b2[6], float(b2[3]), float(b2[4]), float(b2[5]), float(b2[0]), float(b2[2]), float(b2[1]) - float(b2[4]) * 0.5 - miny, float(b2[1]) + float(b2[4]) * 0.5 - miny])
	if said > 4: _report(name, "unheld", "and %d more parts of the room's build hang in the air" % (said - 4))

## true if no solid face of the room lies more than 3 cm above `y` over the point: `y` is the room's top there
func _is_room_top(shell: Array, at: Vector2, y: float) -> bool:
	for t: Array in shell:
		if int(t[3]) != 0: continue
		var a: Vector3 = t[0]; var b: Vector3 = t[1]; var c: Vector3 = t[2]
		if (a.y + b.y + c.y) / 3.0 <= y + 0.03: continue
		var nn := (b - a).cross(c - a)
		if nn.length_squared() < 1e-10 or absf(nn.normalized().y) < 0.9: continue
		if Geometry2D.point_is_inside_triangle(at, Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)): return false
	return true

## How far a point is from the nearest wall of the room: an edge of a floor rectangle that is not shared with
## another floor rectangle (so the join of an L-shaped room is no wall), or the face of a partition. INF if the point
## is on no floor.
func _wall_dist(c: Vector2, floors: Array, solids: Array) -> float:
	var near := INF
	for r: Array in floors:
		var x0 := float(r[0]); var z0 := float(r[1]); var x1 := float(r[2]); var z1 := float(r[3])
		if c.x < x0 - 0.5 or c.x > x1 + 0.5 or c.y < z0 - 0.5 or c.y > z1 + 0.5: continue
		for e: Array in [[absf(c.x - x0), Vector2(x0 - 0.2, c.y)], [absf(c.x - x1), Vector2(x1 + 0.2, c.y)], [absf(c.y - z0), Vector2(c.x, z0 - 0.2)], [absf(c.y - z1), Vector2(c.x, z1 + 0.2)]]:
			var beyond: Vector2 = e[1]
			var open_side := false      # the far side of this edge is another floor rectangle: no wall there
			for r2: Array in floors:
				if r2 != r and beyond.x > float(r2[0]) and beyond.x < float(r2[2]) and beyond.y > float(r2[1]) and beyond.y < float(r2[3]): open_side = true; break
			if not open_side: near = minf(near, float(e[0]))
	for s: Array in solids:
		var dx := maxf(maxf(float(s[0]) - c.x, c.x - float(s[2])), 0.0); var dz := maxf(maxf(float(s[1]) - c.y, c.y - float(s[3])), 0.0)
		near = minf(near, Vector2(dx, dz).length())
	return near

func _on_floor(c: Vector2, floors: Array, solids: Array) -> bool:
	var inside := false
	for r: Array in floors:
		if c.x > float(r[0]) and c.x < float(r[2]) and c.y > float(r[1]) and c.y < float(r[3]): inside = true; break
	if not inside: return false
	for s: Array in solids:
		if c.x > float(s[0]) and c.x < float(s[2]) and c.y > float(s[1]) and c.y < float(s[3]): return false
	return true

## Every door and window of the room's walls that is on record, heights from the floor:
## [axis ("z" = a wall running along x), at, s0, s1, y0, y1, "door" | "window", source, how near the wall plane counts].
## Sources: the room's own record (meta "openings", exact), its entrances (to 2.3 m), and the contract of the building
## it is in (ground floor; the room is authored in its building model's frame, its wall stands inside the facade).
func _openings(name: String, root: Node3D, miny: float) -> Array:
	var out: Array = []
	if root.has_meta(&"openings"):
		for o: Array in root.get_meta(&"openings", []):
			if o.size() >= 7: out.append([String(o[0]), float(o[1]), float(o[2]), float(o[3]), float(o[4]), float(o[5]), String(o[6]), "the room's recorded", 0.35])
	else: no_openings += 1
	for d: Array in root.get_meta(&"entrances", []):
		out.append([String(d[0]), float(d[1]), float(d[2]), float(d[3]), 0.0, 2.3, "door", "the room's entrance", 0.6])
	var model := String((info.get(name, {}) as Dictionary).get("model", ""))
	if contracts.has(model):
		for o2: Variant in (contracts[model] as Dictionary).get("openings", []):
			if not (o2 is Dictionary) or int((o2 as Dictionary).get("floor", 0)) != 0: continue
			var od: Dictionary = o2
			if not (od.has("along") and od.has("w") and od.has("plane") and od.has("y0") and od.has("y1")): continue
			var fr := String(od.get("facade", "")) in ["front", "back"]
			var a := float(od.along); var w := float(od.w)
			out.append(["z" if fr else "x", float(od.plane), a - w * 0.5, a + w * 0.5, float(od.y0) - miny, float(od.y1) - miny, "door" if String(od.get("region", "")).contains("door") else "window", "the building's %s" % String(od.get("facade", "")), 0.8])
	return out

## The customer's-eye review (the strip session's room_review.gd, Yasin's corrections): see the header.
func _review(name: String, props: Array, ground: Array, miny: float, floors: Array, solids: Array, ops: Array) -> void:
	if no_review or props.is_empty(): return
	var shop := String((info.get(name, {}) as Dictionary).get("kind", ""))
	# repeat
	var count := {}
	for p: Array in props: count[p[0]] = int(count.get(p[0], 0)) + 1
	for b: String in count:
		var lim := int(LIMIT.get(b, 99))
		if b == "prop_drinks_fridge" and not (shop in FOOD): lim = 4
		if int(count[b]) > lim: _report(name, "repeat", "%d x %s (a customer sees the same thing over and over; at most %d)" % [int(count[b]), b, lim])
	# deco: wall decorations per wall and per room
	var per_wall := {}; var n_dec := 0
	for p: Array in props:
		if not (String(p[0]) in DECO_ITEMS) or not (base_mounted(String(p[0])) or float(p[4]) - miny > 0.8): continue
		n_dec += 1
		var fw := Vector2(sin(float(p[3])), cos(float(p[3])))
		var key := "%d_%d_%d" % [roundi(fw.x * 2), roundi(fw.y * 2), roundi(((p[1] as Vector2).x if absf(fw.x) > 0.5 else (p[1] as Vector2).y) * 2.0)]
		per_wall[key] = int(per_wall.get(key, 0)) + 1
	for k: String in per_wall:
		if int(per_wall[k]) > 2: _report(name, "deco", "%d wall decorations on one wall (at most 2)" % int(per_wall[k]))
	if n_dec > 6: _report(name, "deco", "%d wall decorations in the room (at most 6)" % n_dec)
	if not floors.is_empty():
		# lone: wall pieces standing free, bins in the open
		for p: Array in ground:
			var b2 := String(p[0]); var c: Vector2 = p[1]
			var fwd := Vector2(sin(float(p[3])), cos(float(p[3])))
			var depth := float((p[2] as Vector2).y) * 2.0
			if b2 in AGAINST_WALL:
				var back := c - fwd * (depth * 0.5 + 0.35)
				var behind_wall := not _on_floor(back, floors, solids) or _wall_dist(back, floors, solids) <= 0.45
				if not behind_wall and _wall_dist(c, floors, solids) > depth * 0.5 + 0.5:
					var paired := false
					for o: Array in ground:
						if o != p and String(o[0]) in AGAINST_WALL and (o[1] as Vector2).distance_to(back) < 0.6: paired = true; break
					if not paired: _report(name, "lone", "%s at %s stands in the open with no wall behind it" % [b2, _v(c)])
			if b2 == "prop_indoor_bin" and _wall_dist(c, floors, solids) > 1.0:
				var by := false
				for o3: Array in ground:
					if (String(o3[0]) in REV_TABLES or String(o3[0]) in REV_SEATS) and (o3[1] as Vector2).distance_to(c) - maxf(float((o3[2] as Vector2).x), float((o3[2] as Vector2).y)) < 0.9: by = true; break
				if not by: _report(name, "lone", "bin at %s stands in the middle of the floor" % _v(c))
		# face, seat, outseat
		for S: Array in ground:
			var sb := String(S[0])
			if not (sb in REV_SEATS): continue
			var sc: Vector2 = S[1]
			var sf := Vector2(sin(float(S[3])), cos(float(S[3])))
			var sdepth := float((S[2] as Vector2).y) * 2.0
			if sb == "prop_office_chair":
				var ahead := false; var behind := false
				for P: Array in ground:
					if String(P[0]) != "prop_office_desk": continue
					var dp := (P[1] as Vector2) - sc
					if dp.length() > 1.3: continue
					if dp.dot(sf) > 0.2: ahead = true
					elif dp.dot(sf) < -0.2: behind = true
				if behind and not ahead: _report(name, "face", "desk chair at %s has its back to its desk" % _v(sc))
			var front := sc + sf * (sdepth * 0.5 + 0.25)
			if sb != "prop_booth_bench" and (not _on_floor(front, floors, solids) or _wall_dist(front, floors, solids) < 0.05):
				_report(name, "face", "%s at %s faces a wall" % [sb, _v(sc)])
			for P2: Array in ground:
				if P2 == S or String(P2[0]) in SIT_AT or String(P2[0]) in ["prop_potted_plant", "prop_indoor_bin"]: continue
				if _hit(front, Vector2(float((S[2] as Vector2).x) * 0.8, 0.225), float(S[3]), P2[1], P2[2], P2[3]):
					_report(name, "seat", "%s at %s has %s right in front of it: no room to sit" % [sb, _v(sc), P2[0]]); break
			if sb == "prop_waiting_bench":
				for o4: Array in ops:
					if String(o4[6]) != "window" or float(o4[4]) > 1.3: continue      # high windows are not looked out of
					var along := sc.x if String(o4[0]) == "z" else sc.y
					var across := sc.y if String(o4[0]) == "z" else sc.x
					var toward := (sf.y if String(o4[0]) == "z" else sf.x) * signf(float(o4[1]) - across)
					if along > float(o4[2]) and along < float(o4[3]) and absf(float(o4[1]) - across) < 1.4 + float(o4[8]) and toward > 0.7:
						_report(name, "outseat", "bench at %s faces the window glass at arm's length" % _v(sc)); break
	# binshop and sparse
	var n_bins := 0
	for p: Array in props:
		if String(p[0]) in BINS: n_bins += 1
	if n_bins >= 2 and float(n_bins) / props.size() > 0.25: _report(name, "binshop", "%d of its %d things are bins: it reads as a trash shop" % [n_bins, props.size()])
	var area := 0.0
	for r: Array in floors: area += absf((float(r[2]) - float(r[0])) * (float(r[3]) - float(r[1])))
	if area > 12.0 and props.size() / area * 10.0 < 1.2: _report(name, "sparse", "%d things on %.0f m2: it looks bare" % [props.size(), area])

## doorway: the room's own build (solid faces and fixed panes, not the door leaves) inside a door's passage
func _doorways(name: String, doors: Array, miny: float, shell: Array) -> void:
	for d: Array in doors:
		var s0 := float(d[2]) + 0.12; var s1 := float(d[3]) - 0.12
		if s1 <= s0: continue
		var at := float(d[1]); var pl := float(d[4])
		var outward := signf(pl - at)
		var t0 := minf(at - outward * 0.25, pl + outward * 0.9); var t1 := maxf(at - outward * 0.25, pl + outward * 0.9)
		var box := AABB(Vector3(s0, miny + 0.06, t0), Vector3(s1 - s0, 1.94, t1 - t0)) if d[0] == "z" else AABB(Vector3(t0, miny + 0.06, s0), Vector3(t1 - t0, 1.94, s1 - s0))
		var low := INF; var high := -INF; var n_in := 0
		for t: Array in shell:
			if int(t[3]) == 2: continue
			var a: Vector3 = t[0]; var b: Vector3 = t[1]; var c: Vector3 = t[2]
			if not AABB(a, Vector3.ZERO).expand(b).expand(c).intersects(box): continue
			for i in 9:
				for j in 9 - i:
					var u := (i + 0.5) / 9.0; var v := (j + 0.5) / 9.0
					if u + v > 1.0: continue
					var pnt := a + (b - a) * u + (c - a) * v
					if box.has_point(pnt): n_in += 1; low = minf(low, pnt.y); high = maxf(high, pnt.y)
		if n_in == 0: continue
		var where := "%.2f..%.2f (%s %.2f)" % [float(d[2]), float(d[3]), d[0], at]
		if low - miny >= 1.75: _report(name, "doorway", "low head at %.2f m in the door at %s: a lintel or transom under 2 m" % [low - miny, where])
		else: _report(name, "doorway", "blocked from %.2f m to %.2f m up in the door at %s: the room's build stands in the passage" % [low - miny, high - miny, where])

func base_mounted(b: String) -> bool: return b in WALL_MOUNT or wallm.has(b)

const SEATS := ["prop_cafe_chair", "prop_side_chair", "prop_office_chair", "prop_bar_stool", "prop_barber_chair"]
const TABLES := ["prop_cafe_table", "prop_restaurant_table", "prop_office_desk", "prop_nail_table", "prop_bar_counter", "prop_display_table"]
func _tucked(a: String, b: String) -> bool: return (a in SEATS and b in TABLES) or (b in SEATS and a in TABLES)

func _corners(c: Vector2, h: Vector2, a: float) -> Array:
	var ax := Vector2(cos(a), -sin(a)); var az := Vector2(sin(a), cos(a))
	return [c + ax * h.x + az * h.y, c - ax * h.x + az * h.y, c + ax * h.x - az * h.y, c - ax * h.x - az * h.y]

func _hit(ca: Vector2, ha: Vector2, aa: float, cb: Vector2, hb: Vector2, ab: float) -> bool:
	var axes := [Vector2(cos(aa), -sin(aa)), Vector2(sin(aa), cos(aa)), Vector2(cos(ab), -sin(ab)), Vector2(sin(ab), cos(ab))]
	var d := cb - ca
	for ax: Vector2 in axes:
		var ra := ha.x * absf(Vector2(cos(aa), -sin(aa)).dot(ax)) + ha.y * absf(Vector2(sin(aa), cos(aa)).dot(ax))
		var rb := hb.x * absf(Vector2(cos(ab), -sin(ab)).dot(ax)) + hb.y * absf(Vector2(sin(ab), cos(ab)).dot(ax))
		if absf(d.dot(ax)) > ra + rb: return false
	return true

func _v(p: Vector2) -> String: return "(%.2f, %.2f)" % [p.x, p.y]
