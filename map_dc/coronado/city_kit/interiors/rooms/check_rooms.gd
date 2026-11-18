extends SceneTree
## Indoor checker (17 Nov, Yasin: "do some of the props overlap? do we have an indoors checker?").
## For every saved room in interiors/rooms/*.scn it checks the floor-standing kit props (footprints from the kit
## manifests, oriented) against:
##   overlap   two props' footprints overlap (items standing ON something - lifted > 0.3 m - and wall-mounted prints
##             are not floor props; a lifted item must stand on a floor prop under it: "floating" otherwise)
##   wall      a prop sticks out of the room's floor or into a partition / wall box
##   door      a prop stands in an entrance's swing zone (the leaves swing 95 degrees inward, plus the step in)
##   reach     a prop no one can walk up to (0.25 m grid flood from the entrances, 0.45 m clearance for a body)
##   hidden    a wall-mounted print / board with a taller floor prop in front of it
##   pot       a garden plant without a pot standing on the indoor floor
##   squeeze   the walkway from the entrance to the room's deepest reachable floor narrows under 0.8 m
##   cover     (19 Nov, Yasin: "this thing is overlapping the door") a wall-mounted board, print, menu or shelf hangs
##             over a door or a window of its wall (rooms built since 19 Nov record their openings: meta "openings";
##             older rooms are skipped until they are rebuilt, and counted on the last line)
## Output like the city validator (tools/city/pilot/validate.gd): "CHECK <kind> ..." per problem, then
## "CHECKS n problems"; exit code 1 if any. Run it after every room build, next to validate / audit_trees / the lock test.
## Run with the real renderer (MultiMesh data): godot --path <preview> --rendering-method mobile -s <this>
const K := preload("res://tools/city/pilot/kit_lib.gd")
const DIR := "res://map_dc/coronado/city_kit/interiors/rooms/"
const MAN := "res://assets/coronado_kit/props/"
## decor no one needs to walk up to (pots in corners, bins): exempt from "reach"
const DECOR := ["prop_potted_plant", "prop_indoor_bin"]
const WALL_MOUNT := ["prop_gallery_frame", "prop_menu_board", "prop_pegboard_wall"]
var foot := {}
var tall := {}
var wallm := {}     # props the kit manifests mount on a wall (poster case, menu board ...)
var problems := 0
var no_openings := 0

func _init() -> void: _run.call_deferred()

func _run() -> void:
	for f in DirAccess.get_files_at(MAN):
		if f.begins_with("manifest_") and f.ends_with(".json"): _man(MAN + f)   # indoor kit + street kit props used indoors (vending, fountain)
	_man("res://assets/coronado_kit/foliage/manifest_foliage.json")
	var rooms: Array = []
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".scn"): rooms.append(f)
	print("CHECKS loaded %d rooms" % rooms.size())
	for f: String in rooms: _room(f.get_basename(), (load(DIR + f) as PackedScene).instantiate())
	print("CHECKS cover rule: %d rooms built before 19 Nov have no recorded openings (rebuild them to check)" % no_openings)
	print("CHECKS %d problems" % problems)
	quit(1 if problems else 0)

func _man(p: String) -> void:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	var items: Array = v if v is Array else (v as Dictionary).values()
	for e: Variant in items:
		if not (e is Dictionary and (e as Dictionary).has("file_base")): continue
		foot[String(e.file_base)] = Vector2(float(e.get("footprint_w", 0.5)), float(e.get("footprint_d", 0.5)))
		tall[String(e.file_base)] = float(e.get("height", 1.0))
		if String(e.get("mount", "")) == "wall": wallm[String(e.file_base)] = true

func _report(room: String, kind: String, msg: String) -> void:
	problems += 1
	print("CHECK %-8s %s: %s" % [kind, room, msg])

func _room(name: String, root: Node3D) -> void:
	root.name = name
	var floors: Array = root.get_meta(&"floors", [])
	var solids: Array = root.get_meta(&"solids", [])
	var doors: Array = root.get_meta(&"entrances", [])
	var fy := 0.0
	var props: Array = []      # [base, center Vector2, half Vector2, angle, lift]
	var pn := root.get_node_or_null("Props")
	if pn == null: return
	for mmi: MultiMeshInstance3D in pn.get_children():
		var base := String(mmi.name)
		var mm := mmi.multimesh
		var fp: Vector2 = foot.get(base, Vector2(0.4, 0.4))
		if base.begins_with("plant_"): fp = Vector2(minf(fp.x, 0.6), minf(fp.y, 0.6))   # pots: the pot, not the leaves
		for i in mm.instance_count:
			var t := mm.get_instance_transform(i)
			var ang := atan2(t.basis.z.x, t.basis.z.z)
			props.append([base, Vector2(t.origin.x, t.origin.z), fp * 0.5, ang, t.origin.y])
	if not floors.is_empty(): fy = 0.0
	var ground: Array = []
	var miny := INF
	for p: Array in props: miny = minf(miny, float(p[4]))
	for p: Array in props:
		if base_mounted(String(p[0])): continue
		if float(p[4]) - miny > 0.3:
			# an item ON something: it must stand on a floor prop
			var on := false
			for q: Array in props:
				if q == p or float(q[4]) - miny > 0.3: continue
				if _hit(p[1], Vector2(0.02, 0.02), 0.0, q[1], q[2], q[3]): on = true; break
			if not on and not String(p[0]).begins_with("plant_"): _report(name, "floating", "%s at %s stands %.2f m up on nothing" % [p[0], _v(p[1]), float(p[4]) - miny])
			continue
		ground.append(p)
	# overlaps
	for i in ground.size():
		for j in range(i + 1, ground.size()):
			var a: Array = ground[i]; var b: Array = ground[j]
			if (a[1] as Vector2).distance_to(b[1]) > (a[2] as Vector2).length() + (b[2] as Vector2).length(): continue
			if _tucked(String(a[0]), String(b[0])): continue      # a chair pushed in under its table or desk
			if _hit(a[1], (a[2] as Vector2) * 0.95, a[3], b[1], (b[2] as Vector2) * 0.95, b[3]):
				_report(name, "overlap", "%s at %s  x  %s at %s" % [a[0], _v(a[1]), b[0], _v(b[1])])
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
	# cover: a wall item over a door or window of the same wall (the room's recorded openings)
	var ops: Array = root.get_meta(&"openings", [])
	if not root.has_meta(&"openings"): no_openings += 1
	for m2: Array in props:
		if not base_mounted(String(m2[0])): continue
		var fwd2 := Vector2(sin(float(m2[3])), cos(float(m2[3])))
		var along_x := absf(fwd2.y) > absf(fwd2.x)            # faces +-z: hangs on a wall running along x (axis "z")
		var c2: Vector2 = m2[1]
		var hw := float((m2[2] as Vector2).x)
		var y0 := float(m2[4]) - miny; var y1 := y0 + float(tall.get(String(m2[0]), 0.5))
		for o: Array in ops:
			if (String(o[0]) == "z") != along_x: continue
			var dist := absf((c2.y if along_x else c2.x) - float(o[1]))
			if dist > 0.35: continue
			var a0 := (c2.x if along_x else c2.y) - hw; var a1 := (c2.x if along_x else c2.y) + hw
			if a0 < float(o[3]) - 0.03 and a1 > float(o[2]) + 0.03 and y0 < float(o[5]) - 0.03 and y1 > float(o[4]) + 0.03:
				_report(name, "cover", "%s at %s hangs over a %s (%.2f..%.2f along the wall, %.2f..%.2f m up)" % [m2[0], _v(c2), o[6], float(o[2]), float(o[3]), float(o[4]), float(o[5])])
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
	print("ROOM %s: %d props (%d on the floor), %d doors, %d of %d floor cells reachable" % [name, props.size(), ground.size(), doors.size(), nseen, nfree])

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
