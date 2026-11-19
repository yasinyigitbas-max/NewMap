extends RefCounted
## Waterfront FILL pieces (n_wf_*, branch claude/fill-waterfront, 19 Nov 2026): the two empty blocks west of the
## waterfront sample (Yasin 19 Nov: "two blocks next to water front will be waterfront area, not residental").
## This file is a set of TOOLS, not a recipe: it decides nothing about what stands where. Every building, terrace, stair
## and prop is written by hand, with its reason, in the piece's own script (n_wf_<site>.gd). It copies helpers of the
## waterfront sample's libraries (wf_lib, ind_lib, strip_lib, cc_lib, kit_lib) and of the strip growth's builder,
## changed to take every height from this block's own ground. No shared library is edited.
##
## COORDINATES: a piece script writes everything in the GRID frame (u = x, v = z, metres, as measured on the map) and
## absolute heights (datum metres). The piece itself is saved in its own frame (x = u - ox, z = v - oz); its layout row
## is [ox, 0, oz], yaw 0 (review/grow_wf_blocks.json). The conversion happens only here, at the output.
##
## THE GROUND (land first, super-builder skill):
##  * outline and base field: wf_fill_ground.json (tools/city/pilot/zoning/wf_fill_ground.py). The outline is the free
##    ground between the neighbours' meshes; along it the height IS the neighbour's edge (measured every metre), so
##    every edge meets its street walk / quadrant flush. Inside, a harmonic fill of those edges (no bump of its own).
##  * frontage band: within `band` metres of a neighbour edge the ground is the base field (the walk carries on).
##  * terraces: level pads written by hand (terrace()). "wall" = a retaining face where it meets other ground; "ease" =
##    blended back over `blend` m (a lawn bank).
##  * ramps and stairs between them (ramp(), stairs()), written by hand.
##  * the floor is cut on every terrace / ramp / stair / paint edge; every height jump between two neighbouring cells
##    gets a vertical face (retaining wall over 22 cm, riser or kerb below): no see-through gaps.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const GROUND := "res://tools/city/pilot/pieces/wf_fill_ground.json"
const STALL_W := 2.6
const STALL_D := 5.5
const CELL := 4.0            # largest floor cell (the field is smooth; terraces are flat)

var name := ""
var ox := 0.0; var oz := 0.0
var u0 := 0.0; var v0 := 0.0; var u1 := 0.0; var v1 := 0.0          # bounds of the outline (grid)
var outline := PackedVector2Array(); var oy := PackedFloat32Array(); var okind: Array = []
var fu0 := 0.0; var fv0 := 0.0; var fnx := 0; var fnz := 0; var fst := 1.0
var fy: PackedFloat32Array; var fd: PackedFloat32Array
var band := 2.0
var terr: Array = []          # [u0, v0, u1, v1, y, kind ("wall" / "ease"), blend, label]
var slopes: Array = []        # [u0, v0, u1, v1, axis ("u"/"v"), ya (at the low coordinate), yb, n_treads (0 = ramp)]
var seg_hash := {}            # 4 m cell -> outline segment indices (exact edge heights)
var root: Node3D; var bl: Node3D
var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
var rr: RandomNumberGenerator
var paints: Array = []; var stalls: Array = []; var B: Array = []; var shops: Array = []
var walls_m := 0.0
var yl: Callable              # height at a piece-LOCAL point (decals, kit helpers)

func _init(piece: String) -> void:
	name = piece
	S.hill_on = false
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GROUND)).pieces[piece]
	ox = float(d.ox); oz = float(d.oz)
	u0 = INF; v0 = INF; u1 = -INF; v1 = -INF
	for e: Array in d.outline:
		var p := Vector2(float(e[0]) + ox, float(e[1]) + oz)
		outline.append(p); oy.append(float(e[2]))
		u0 = minf(u0, p.x); v0 = minf(v0, p.y); u1 = maxf(u1, p.x); v1 = maxf(v1, p.y)
	okind = d.kinds
	fu0 = float(d.fx0) + ox; fv0 = float(d.fz0) + oz; fnx = int(d.nx); fnz = int(d.nz); fst = float(d.step)
	fy = PackedFloat32Array(d.y); fd = PackedFloat32Array(d.d)
	for k in outline.size():
		var a := outline[k]; var b := outline[(k + 1) % outline.size()]
		for cu in range(int(floor(minf(a.x, b.x) / 4.0)) - 1, int(floor(maxf(a.x, b.x) / 4.0)) + 2):
			for cv in range(int(floor(minf(a.y, b.y) / 4.0)) - 1, int(floor(maxf(a.y, b.y) / 4.0)) + 2):
				var key := Vector2i(cu, cv)
				if not seg_hash.has(key): seg_hash[key] = []
				seg_hash[key].append(k)
	root = Node3D.new(); root.name = piece
	bl = Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	rr = W.rng_for(piece)
	yl = func(x: float, z: float) -> float: return y(x + ox, z + oz)

## ---------------------------------------------------------------- frame
func O() -> Vector3: return Vector3(ox, 0.0, oz)
## a grid point (u, v) at height h -> the piece's own frame
func loc(u: float, v: float, h: float) -> Vector3: return Vector3(u - ox, h, v - oz)
func loc2(p: Vector2) -> Vector2: return Vector2(p.x - ox, p.y - oz)

## ---------------------------------------------------------------- ground
func _bil(arr: PackedFloat32Array, u: float, v: float) -> float:
	var fx := clampf((u - fu0) / fst, 0.0, fnx - 1.001); var fz := clampf((v - fv0) / fst, 0.0, fnz - 1.001)
	var i := int(fx); var j := int(fz); var tx := fx - i; var tz := fz - j
	return lerpf(lerpf(arr[j * fnx + i], arr[j * fnx + i + 1], tx), lerpf(arr[(j + 1) * fnx + i], arr[(j + 1) * fnx + i + 1], tx), tz)

## the measured edge height where (u, v) lies on a neighbour edge (within 2 cm), else NAN
func edge_y(u: float, v: float) -> float:
	var key := Vector2i(int(floor(u / 4.0)), int(floor(v / 4.0)))
	if not seg_hash.has(key): return NAN
	var p := Vector2(u, v)
	for k: int in seg_hash[key]:
		if String(okind[k]) != "nb": continue
		var a := outline[k]; var b := outline[(k + 1) % outline.size()]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		if q.distance_to(p) < 0.02:
			var t := 0.0 if a.distance_to(b) < 1e-6 else a.distance_to(q) / a.distance_to(b)
			return lerpf(oy[k], oy[(k + 1) % outline.size()], t)
	return NAN

func field(u: float, v: float) -> float:
	var e := edge_y(u, v)
	return e if not is_nan(e) else _bil(fy, u, v)

func edge_dist(u: float, v: float) -> float: return _bil(fd, u, v)

func y(u: float, v: float) -> float:
	if edge_dist(u, v) < band: return field(u, v)
	for k in range(slopes.size() - 1, -1, -1):
		var s: Array = slopes[k]
		if u >= float(s[0]) and u <= float(s[2]) and v >= float(s[1]) and v <= float(s[3]):
			var t := (u - float(s[0])) / maxf(float(s[2]) - float(s[0]), 0.01) if String(s[4]) == "u" else (v - float(s[1])) / maxf(float(s[3]) - float(s[1]), 0.01)
			var n := int(s[7])
			if n > 0: t = minf(floor(t * n + 1e-4), n - 1.0) / (n - 1.0)     # treads: first at ya, last at yb
			return lerpf(float(s[5]), float(s[6]), t)
	var h := field(u, v)
	var blended := false
	for k in range(terr.size() - 1, -1, -1):
		var p: Array = terr[k]
		var dx := maxf(maxf(float(p[0]) - u, u - float(p[2])), 0.0)
		var dz := maxf(maxf(float(p[1]) - v, v - float(p[3])), 0.0)
		var dd := sqrt(dx * dx + dz * dz)
		if dd <= 0.0: return float(p[4])
		if String(p[5]) == "ease" and dd < float(p[6]) and not blended:
			var t := dd / float(p[6]); t = t * t * (3.0 - 2.0 * t)
			h = lerpf(float(p[4]), h, t); blended = true
	return h

## a level terrace: kind "wall" = retaining face at its edge, "ease" = lawn bank blended over `blend` m
func terrace(au: float, av: float, bu: float, bv: float, h: float, kind := "wall", blend := 4.0, label := "") -> float:
	terr.append([minf(au, bu), minf(av, bv), maxf(au, bu), maxf(av, bv), h, kind, blend, label])
	return h

## a ramp from ya (at the low coordinate of its axis) to yb; walk ramps at most 8.3 %, drives 12 %
func ramp(au: float, av: float, bu: float, bv: float, axis: String, ya: float, yb: float, drive := false) -> void:
	var run := (maxf(au, bu) - minf(au, bu)) if axis == "u" else (maxf(av, bv) - minf(av, bv))
	var gr := absf(yb - ya) / maxf(run, 0.01)
	if gr > (0.12 if drive else 0.0834): print("WARNING %s: ramp at %.1f %% (%.1f, %.1f)" % [name, gr * 100.0, au, av])
	slopes.append([minf(au, bu), minf(av, bv), maxf(au, bu), maxf(av, bv), axis, ya, yb, 0])

## a flight of steps between ya (at the low coordinate of its axis) and yb: risers at most 17 cm, treads 30 cm or more
func stairs(au: float, av: float, bu: float, bv: float, axis: String, ya: float, yb: float) -> int:
	var n := maxi(2, int(ceil(absf(yb - ya) / 0.17)) + 1)
	var run := (maxf(au, bu) - minf(au, bu)) if axis == "u" else (maxf(av, bv) - minf(av, bv))
	if run / n < 0.29: print("WARNING %s: stair treads %.2f m at (%.1f, %.1f)" % [name, run / n, au, av])
	slopes.append([minf(au, bu), minf(av, bv), maxf(au, bu), maxf(av, bv), axis, ya, yb, n])
	return n - 1

func inside(u: float, v: float) -> bool: return Geometry2D.is_point_in_polygon(Vector2(u, v), outline)

## ---------------------------------------------------------------- placing (grid in, piece frame out)
func p3(u: float, v: float, lift := 0.0) -> Vector3: return loc(u, v, y(u, v) + lift)

func add(base: String, cond: String, u: float, v: float, yaw := 0.0, collide := true, lift := 0.0) -> void:
	if not inside(u, v): print("WARNING %s: %s at (%.1f, %.1f) outside the block" % [name, base, u, v])
	I.add(props, base, cond, p3(u, v, lift), yaw, collide)

## at an explicit height (wall-hung things, railings on a terrace edge, things on a deck)
func add_at(base: String, cond: String, u: float, v: float, h: float, yaw := 0.0, collide := true) -> void:
	I.add(props, base, cond, loc(u, v, h), yaw, collide)

## a kit building centred at (u, v), front (+Z) turned by yaw, at the ground height there. Its four corners and centre
## must lie on one level (a terrace): a building is never left on a slope (printed as a WARNING).
func bld(folder: String, u: float, v: float, yaw: float, label: String, wear := 0.75, services := true, shop := true, compact := false) -> Array:
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var h := y(u, v)
	for c: Vector3 in [Vector3(-w, 0, -d), Vector3(w, 0, -d), Vector3(w, 0, d), Vector3(-w, 0, d)]:
		var p: Vector3 = Vector3(u, 0, v) + b * (c * 0.49)
		if absf(y(p.x, p.z) - h) > 0.02: print("WARNING %s: building %s corner off its terrace by %.2f m" % [name, label, y(p.x, p.z) - h])
	var n := K.building(bl, folder, loc(u, v, h), yaw, label, wear)
	n.set_meta(&"label", label)
	if services: back_of_house(n, w, d, compact)
	B.append([n, w, d, folder])
	if shop and not (st.get("doors_front", []) as Array).is_empty(): shops.append([label, folder])
	return [n, w, d, folder]

## meters, gas meter, AC condensers on the rear wall at the building's own floor (cc_lib.back_of_house on this ground).
## Unlike the sample's helper they are slid along the back wall to a stretch with NO opening (the measured openings of
## interiors/room_contracts.json, the same list check_life reads): a meter never hangs over a back window or door, an AC
## unit never stands in front of a back door. Where the wall has no free stretch, that item is left out (printed).
static var _rc := {}
func openings(folder: String, facade: String) -> Array:
	if _rc.is_empty():
		for f: String in ["room_contracts.json", "room_contracts_res.json"]:     # the same two lists check_life reads
			var pth := "res://map_dc/coronado/city_kit/interiors/" + f
			if FileAccess.file_exists(pth): _rc.merge(JSON.parse_string(FileAccess.get_file_as_string(pth)).models)
	var out: Array = []
	for o: Dictionary in (_rc.get(folder, {}) as Dictionary).get("openings", []):
		if String(o.facade) == facade: out.append([float(o.along) - float(o.w) * 0.5, float(o.along) + float(o.w) * 0.5, float(o.y0), float(o.y1)])
	for e: Dictionary in (_rc.get(folder, {}) as Dictionary).get("entrances", []):
		if String(e.facade) == facade: out.append([float(e.along) - float(e.w) * 0.5, float(e.along) + float(e.w) * 0.5, 0.0, 2.3])
	return out

## first x (from x_from toward x_to) where [x, x + span] on that wall is clear of every opening below y_top (+15 cm)
func free_x(ops: Array, x_from: float, x_to: float, span: float, y_top: float) -> float:
	var x := x_from
	while x + span <= x_to:
		var ok := true
		for o: Array in ops:
			if float(o[2]) < y_top and x < float(o[1]) + 0.15 and x + span > float(o[0]) - 0.15: ok = false; break
		if ok: return x
		x += 0.1
	return NAN

func back_of_house(node: Node3D, w: float, d: float, compact := false, residential := false) -> void:
	var yaw := rad_to_deg(node.rotation.y) + 180.0
	var folder := String(node.get_meta(&"kit", ""))
	var ops := openings(folder, "back")
	# the back facade seen from behind runs the other way: openings' "along" is the building's local x
	var at := func(lx: float, ly: float, lz: float) -> Vector3:
		var p: Vector3 = node.transform * Vector3(lx, 0.0, lz)
		return Vector3(p.x, node.position.y + ly, p.z)
	var lo := -w * 0.5 + 0.6; var hi := w * 0.5 - 0.6
	var xm := free_x(ops, lo, hi, 2.0, 2.3)           # meter bank (tops at about 1.9 m; small high windows start at 1.8) (3 x 0.42) and the gas meter 1.7 m along
	if is_nan(xm):
		# no room on the back wall: the side walls, back half first (the meter reader comes round the side)
		var placed := false
		for side: float in [1.0, -1.0]:
			var sops := openings(folder, "right" if side > 0 else "left")
			var zm := free_x(sops, -d * 0.5 + 0.6, d * 0.5 - 0.6, 2.0, 2.3)
			if is_nan(zm): continue
			var syaw := rad_to_deg(node.rotation.y) + 90.0 * side
			for k in 3: props.add("prop_meter_electric", "worn", at.call(side * (w * 0.5 + 0.02), 1.05, zm + 0.2 + k * 0.42), syaw)
			props.add("prop_meter_gas", "rusty", at.call(side * (w * 0.5 + 0.02), 0.2, zm + 1.8), syaw)
			placed = true; break
		if not placed: print("%s: no free stretch for meters on %s (left out)" % [name, node.name])
	else:
		for k in 3: props.add("prop_meter_electric", "worn", at.call(xm + 0.2 + k * 0.42, 1.05, -d * 0.5 - 0.02), yaw)
		props.add("prop_meter_gas", "rusty", at.call(xm + 1.8, 0.2, -d * 0.5 - 0.02), yaw)
	var n_ac := 1 if w < 14.0 else 2
	var ops2 := ops.duplicate()
	if not is_nan(xm): ops2.append([xm, xm + 2.0, 0.0, 9.0])
	var xa := lo
	for k in n_ac:
		var xs := free_x(ops2, xa, hi, 1.1, 0.4)       # in front of no door (sills over 0.4 m are windows: an AC may stand under one)
		if is_nan(xs): break
		props.add("prop_ac_condenser_compact" if compact else "prop_ac_condenser", "worn", at.call(xs + 0.55, 0.0, -d * 0.5 - (0.47 if compact else 0.75)), yaw)
		ops2.append([xs, xs + 1.1, 0.0, 9.0]); xa = xs + 1.2
	if residential:
		for k in 3: props.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", at.call(w * 0.5 - 0.6 - k * 0.8, 0.0, -d * 0.5 - 2.2), yaw)   # in the back garden, clear of the AC units

## a GRID point on a building: local (lx, lz) of its footprint (front = +lz)
func on_bld(b: Array, lx: float, lz: float) -> Vector2:
	var p: Vector3 = (b[0] as Node3D).transform * Vector3(lx, 0.0, lz)
	return Vector2(p.x + ox, p.z + oz)

func bld_h(b: Array) -> float: return (b[0] as Node3D).position.y
func bld_yaw(b: Array, dyaw := 0.0) -> float: return rad_to_deg((b[0] as Node3D).rotation.y) + dyaw

## a prop against a building at its floor height (+ly): local (lx, lz), facing out of the front turned by dyaw
func at_bld(b: Array, base: String, cond: String, lx: float, lz: float, dyaw := 0.0, ly := 0.0, collide := true) -> void:
	var p := on_bld(b, lx, lz)
	I.add(props, base, cond, loc(p.x, p.y, bld_h(b) + ly), bld_yaw(b, dyaw), collide)

## roof plant on a FLAT roof (the strip builder's raycast rule): items in order, one per spot, 3 m apart
func roof(b: Array, items: Array) -> int:
	var n: Node3D = b[0]
	var near := n.get_node_or_null("near") as MeshInstance3D
	if near == null: return 0
	var tm := near.mesh.generate_triangle_mesh()
	var w: float = b[1]; var d: float = b[2]
	var spots: Array = []
	var lx := -w * 0.5 + 2.0
	while lx <= w * 0.5 - 2.0:
		var lz := -d * 0.5 + 2.0
		while lz <= d * 0.5 - 2.0:
			var h := _roof_hit(tm, near.transform, Vector3(lx, 0, lz))
			if h > 2.4:
				var ok := true
				for o: Vector3 in [Vector3(1.2, 0, 0), Vector3(-1.2, 0, 0), Vector3(0, 0, 1.2), Vector3(0, 0, -1.2)]:
					if absf(_roof_hit(tm, near.transform, Vector3(lx, 0, lz) + o) - h) > 0.01: ok = false
				if ok: spots.append(Vector3(lx, h, lz))
			lz += 3.0
		lx += 3.0
	var placed := 0; var used: Array = []; var k := 0
	for s: Vector3 in spots:
		if placed >= items.size(): break
		k += 1
		if k % 2 == 0: continue
		var clear := true
		for u: Vector3 in used:
			if u.distance_to(s) < 3.0: clear = false
		if not clear: continue
		I.add(props, String(items[placed]), "worn" if rr.randf() < 0.7 else "rusty", n.transform * s, rad_to_deg(n.rotation.y) + 90.0 * (rr.randi() % 2), false)
		used.append(s); placed += 1
	if placed < items.size(): print("%s: roof of %s took %d of %d items" % [name, n.name, placed, items.size()])
	return placed

func _roof_hit(tm: TriangleMesh, mxf: Transform3D, lp: Vector3) -> float:
	var o := mxf.affine_inverse() * Vector3(lp.x, 60.0, lp.z)
	var dir := (mxf.affine_inverse().basis * Vector3.DOWN).normalized()
	var r: Dictionary = tm.intersect_ray(o, dir)
	if r.is_empty(): return -1.0
	var nrm: Vector3 = (mxf.basis * Vector3(r.normal)).normalized()
	if absf(nrm.y) < 0.97: return -1.0
	return (mxf * Vector3(r.position)).y

## ---------------------------------------------------------------- paint, parking
func rect(au: float, av: float, bu: float, bv: float, mat: String) -> Array:
	return [minf(au, bu), minf(av, bv), maxf(au, bu), maxf(av, bv), mat]

func paint(au: float, av: float, bu: float, bv: float, mat: String) -> void: paints.append(rect(au, av, bu, bv, mat))

## n stalls side by side along u from us, the aisle edge at v = ve, nose toward dir (+1 = larger v)
func stalls_u(us: float, n: int, ve: float, dir: float, w := STALL_W) -> void:
	var va := ve + dir * STALL_D
	for k in n + 1:
		paints.insert(0, rect(us + k * w - 0.05, minf(ve, va) + (0.3 if dir < 0 else 0.0), us + k * w + 0.05, maxf(ve, va) - (0.3 if dir > 0 else 0.0), "white"))
	for k in n:
		var cu := us + (k + 0.5) * w; var cv := ve + dir * STALL_D * 0.5
		var yaw := 0.0 if dir > 0.0 else 180.0
		stalls.append([cu - ox, cv - oz, yaw, y(cu, cv), _grade(cu, cv, yaw)])

## n stalls side by side along v from vs, the aisle edge at u = ue, nose toward dir (+1 = larger u)
func stalls_v(vs: float, n: int, ue: float, dir: float, w := STALL_W) -> void:
	var ua := ue + dir * STALL_D
	for k in n + 1:
		paints.insert(0, rect(minf(ue, ua) + (0.3 if dir < 0 else 0.0), vs + k * w - 0.05, maxf(ue, ua) - (0.3 if dir > 0 else 0.0), vs + k * w + 0.05, "white"))
	for k in n:
		var cv := vs + (k + 0.5) * w; var cu := ue + dir * STALL_D * 0.5
		var yaw := 90.0 if dir > 0.0 else -90.0
		stalls.append([cu - ox, cv - oz, yaw, y(cu, cv), _grade(cu, cv, yaw)])

func _grade(u: float, v: float, yaw: float) -> float:
	var f := Vector2(sin(deg_to_rad(yaw)), cos(deg_to_rad(yaw)))
	return snappedf((y(u + f.x * 2.0, v + f.y * 2.0) - y(u - f.x * 2.0, v - f.y * 2.0)) / 4.0, 0.001)

## wheel stops at the head of every stall (one in seven knocked askew)
func wheel_stops(kind := "prop_wheel_stop_concrete") -> void:
	var r2 := W.rng_for(name + "_ws")
	for st: Array in stalls:
		var yaw := float(st[2])
		var f := Vector2(sin(deg_to_rad(yaw)), cos(deg_to_rad(yaw)))
		var pu := float(st[0]) + ox + f.x * (STALL_D * 0.5 - 0.55); var pv := float(st[1]) + oz + f.y * (STALL_D * 0.5 - 0.55)
		var off := r2.randf() < 0.15
		I.add(props, kind, "dirty" if off else "worn", p3(pu, pv, 0.002), yaw + (r2.randf_range(-10, 10) if off else 0.0), false)

## ---------------------------------------------------------------- fences, walls, railings (a post at every joint)
const FENCE := {"chain": ["fence_chainlink_lot", "fence_chainlink_lot_post", 2.0], "cmu": ["fence_cmu_wall", "", 2.03],
	"stucco": ["fence_stucco_wall", "", 2.0], "privacy": ["fence_wood_privacy", "fence_post_privacy", 2.4],
	"iron": ["fence_wrought_iron", "fence_post_wrought_iron", 1.98], "board": ["fence_weathered_board", "fence_post_privacy", 2.4],
	"vinyl": ["fence_vinyl_canal_rail", "fence_post_vinyl", 2.4], "picket": ["fence_picket_white", "fence_post_picket", 2.0],
	"brick": ["fence_brick_wall", "", 2.0]}
## a straight run a -> b; each panel stands at the LOWEST ground under its length (-3 cm, so a panel on a slope never
## floats at its downhill end), or at `at` when given (a railing on a terrace edge stands on the terrace)
func fence(kind: String, au: float, av: float, bu: float, bv: float, cond := "worn", at := NAN) -> void:
	var a := Vector2(au, av); var b := Vector2(bu, bv)
	var ln := a.distance_to(b)
	if ln < 0.5: return
	var f: Array = FENCE[kind]
	var pl := float(f[2])
	var e := K.manifest(String(f[0]))
	if e.has("footprint_w"): pl = float(e.footprint_w)
	var n := maxi(1, int(ceil(ln / pl - 0.02)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	# panels are never stretched: the end panels sit flush with the run's ends, the overlap is shared in the middle;
	# a post at the run's ends and at every joint (the midpoint between two panels' centres)
	var dir := (b - a) / ln
	var cs: Array = []
	if n == 1: cs.append((a + b) * 0.5)
	else:
		for i in n: cs.append(a + dir * (pl * 0.5 + float(i) * (ln - pl) / (n - 1)))
	for i in n:
		var m: Vector2 = cs[i]; var p0 := m - dir * pl * 0.5; var p1 := m + dir * pl * 0.5
		var h := at
		if is_nan(h):
			h = INF
			for t in 5: var r := p0.lerp(p1, t / 4.0); h = minf(h, y(r.x, r.y))
			h -= 0.03
		I.add(props, String(f[0]), cond, loc(m.x, m.y, h), yaw)
	if String(f[1]) != "":
		var posts: Array = [a, b]
		for i in n - 1: posts.append(((cs[i] as Vector2) + (cs[i + 1] as Vector2)) * 0.5)
		for q: Vector2 in posts:
			I.add(props, String(f[1]), cond, loc(q.x, q.y, at if not is_nan(at) else y(q.x, q.y) - 0.03), yaw)

## an iron guard railing along a straight terrace edge a -> b, standing on the HIGHER side (to_high points to it, 0.3 m
## in): the line is split wherever that side's height changes, each run on its own height, the runs meeting end to end
func guard(au: float, av: float, bu: float, bv: float, to_high: Vector2, cond := "worn") -> void:
	var a := Vector2(au, av); var b := Vector2(bu, bv)
	var ln := a.distance_to(b); var n := maxi(1, int(ln / 0.5))
	var start := a; var hs := y(a.x + to_high.x * 0.3, a.y + to_high.y * 0.3)
	for i in range(1, n + 1):
		var p := a.lerp(b, float(i) / n)
		var h := y(p.x + to_high.x * 0.3, p.y + to_high.y * 0.3)
		if absf(h - hs) > 0.02 or i == n:
			var e := p if i == n else a.lerp(b, (float(i) - 0.5) / n)
			if start.distance_to(e) > 0.5: fence("iron", start.x, start.y, e.x, e.y, cond, hs)
			start = e; hs = h

## a dumpster enclosure (strip_lib.enclosure on this ground) with its two gate leaves; open toward yaw
func enclosure(u: float, v: float, yaw: float, mess := true) -> void:
	L.enclosure(props, p3(u, v), yaw)
	var bq := Basis(Vector3.UP, deg_to_rad(yaw))
	var gl := float(K.manifest("fence_gate_privacy").get("footprint_w", 1.105))
	for side: float in [-1.0, 1.0]:
		var gp: Vector3 = Vector3(u, 0, v) + bq * Vector3(side * (3.15 - gl * 0.5), 0, 2.46)
		I.add(props, "fence_gate_privacy", "worn", p3(gp.x, gp.z), yaw)
	if mess: L.enclosure_mess(props, rr, p3(u, v), yaw)

## ---------------------------------------------------------------- wear (every mark on this ground; grid in)
func mark(tile: int, c: Vector2, yaw: float, sx: float, sz: float, tint := Color(1, 1, 1, 0.8)) -> void:
	dec.add(tile, loc2(c), yaw, sx, sz, yl, tint)

func oil(c: Vector2, yaw := 0.0, strength := 0.75) -> void: W.oil(dec, rr, loc2(c), yaw, yl, strength)

func building_wear() -> void:
	for b: Array in B:
		var w: float = b[1]; var d: float = b[2]
		wall_grime(on_bld(b, -w * 0.5, d * 0.5 + 0.5), on_bld(b, w * 0.5, d * 0.5 + 0.5))
		wall_grime(on_bld(b, -w * 0.5, -d * 0.5 - 0.6), on_bld(b, w * 0.5, -d * 0.5 - 0.6))

## dirt and salt along a wall's foot (ind_lib.wall_grime on this ground)
func wall_grime(a: Vector2, b: Vector2) -> void:
	var ln := a.distance_to(b); var dir := (b - a) / maxf(ln, 0.01)
	var yaw := rad_to_deg(atan2(dir.x, dir.y)) + 90.0
	var s := 0.0
	while s < ln:
		var seg := minf(rr.randf_range(2.0, 4.0), ln - s)
		mark(14, a + dir * (s + seg * 0.5), yaw, seg, rr.randf_range(0.6, 1.0), Color(1, 1, 1, rr.randf_range(0.35, 0.6)))
		s += seg + rr.randf_range(0.0, 2.0)

## ageing over a paved rect: cracks (half sealed), dark patches, pale repairs, oil where cars stood, puddle stains
func yard_wear(au: float, av: float, bu: float, bv: float, density := 1.0, with_oil := true) -> void:
	var area := absf((bu - au) * (bv - av)); var n := int(area / 35.0 * density)
	var lo := Vector2(minf(au, bu), minf(av, bv)); var hi := Vector2(maxf(au, bu), maxf(av, bv))
	W.cracks(dec, rr, lo.x - ox, lo.y - oz, hi.x - ox, hi.y - oz, n, yl, 0.45)
	var rp := func() -> Vector2: return Vector2(rr.randf_range(lo.x, hi.x), rr.randf_range(lo.y, hi.y))
	for k in int(n * 0.25): mark(2 + k % 2, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.5, 6.0), rr.randf_range(1.5, 4.0), Color(1, 1, 1, 0.85))
	for k in int(n * 0.15): W.pale_patch(dec, rr, loc2(rp.call()), rr.randf_range(0, 180), rr.randf_range(2.0, 4.0), rr.randf_range(2.0, 4.0), yl)
	if with_oil:
		for k in int(n * 0.4): oil(rp.call(), rr.randf_range(0, 180), rr.randf_range(0.5, 0.9))
	for k in int(n * 0.25): mark(14, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.0, 5.0), rr.randf_range(2.0, 5.0), Color(1, 1, 1, rr.randf_range(0.4, 0.7)))

## sand carried up from the beach on feet and wind (pale sand-tinted patches) over a rect
func sand_drift(au: float, av: float, bu: float, bv: float, n: int) -> void:
	for k in n:
		mark(4 + k % 2, Vector2(rr.randf_range(minf(au, bu), maxf(au, bu)), rr.randf_range(minf(av, bv), maxf(av, bv))), rr.randf_range(0, 180), rr.randf_range(1.2, 3.0), rr.randf_range(0.6, 1.4), Color(0.86, 0.79, 0.64, 0.55))

func stall_wear(share := 0.6) -> void:
	for s: Array in stalls:
		if rr.randf() < share: W.oil(dec, rr, Vector2(float(s[0]), float(s[1])), float(s[2]), yl, rr.randf_range(0.5, 0.9))

## tyre marks where cars turn in at a drive mouth (asphalt only): two lines
func tyre_path(au: float, av: float, bu: float, bv: float) -> void:
	var a := Vector2(au, av); var b := Vector2(bu, bv)
	var ln := a.distance_to(b); var dir := (b - a) / maxf(ln, 0.01); var side := Vector2(-dir.y, dir.x)
	var yaw := rad_to_deg(atan2(dir.x, dir.y)); var s := 0.0
	while s < ln:
		var seg := minf(6.0, ln - s)
		for o: float in [-0.9, 0.9]:
			mark(8, a + dir * (s + seg * 0.5) + side * o, yaw + rr.randf_range(-4, 4), 0.6, seg, Color(1, 1, 1, rr.randf_range(0.35, 0.55)))
		s += seg

## ---------------------------------------------------------------- checks used while placing
func half(base: String) -> float:
	var e := K.manifest(base)
	return maxf(float(e.get("footprint_w", 0.6)), float(e.get("footprint_d", 0.6))) * 0.5

## the ground's material at a grid point (first paint wins, as in K.painted_rect), asphalt otherwise
func mat_at(u: float, v: float) -> String:
	for p: Array in paints:
		if u > float(p[0]) and u < float(p[2]) and v > float(p[1]) and v < float(p[3]): return String(p[4]) if String(p[4]) != "-" else "asphalt"
	return "asphalt"

## ---------------------------------------------------------------- floor
func _breaks() -> Array:
	var us := {}; var vs := {}
	var addu := func(x: float) -> void:
		if x > u0 + 1e-3 and x < u1 - 1e-3: us[snappedf(x, 0.001)] = true
	var addv := func(x: float) -> void:
		if x > v0 + 1e-3 and x < v1 - 1e-3: vs[snappedf(x, 0.001)] = true
	us[u0] = true; us[u1] = true; vs[v0] = true; vs[v1] = true
	var x := ceilf(u0 / CELL) * CELL
	while x < u1: addu.call(x); x += CELL
	x = ceilf(v0 / CELL) * CELL
	while x < v1: addv.call(x); x += CELL
	for k in outline.size():
		if String(okind[k]) == "cut":       # seams with the next fill piece: straight lines u = const
			addu.call(outline[k].x)
	for p: Array in terr + paints:
		addu.call(float(p[0])); addu.call(float(p[2])); addv.call(float(p[1])); addv.call(float(p[3]))
	for s: Array in slopes:
		addu.call(float(s[0])); addu.call(float(s[2])); addv.call(float(s[1])); addv.call(float(s[3]))
		var n := int(s[7])
		for k in range(1, n):
			if String(s[4]) == "u": addu.call(lerpf(float(s[0]), float(s[2]), float(k) / n))
			else: addv.call(lerpf(float(s[1]), float(s[3]), float(k) / n))
	var ua: Array = us.keys(); ua.sort(); var va: Array = vs.keys(); va.sort()
	return [ua, va]

func _gq(m: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, up := Vector3.UP, wall_uv := false) -> void:
	g.quad(m, a - O(), b - O(), c - O(), d - O(), up, wall_uv)

## builds the floor inside the outline: every cell its own quad (cells cut by the outline are clipped to it), heights
## read a hair inside the cell (so a terrace edge is a clean step), a vertical face wherever two neighbouring cells do
## not meet, and a 0.3 m skirt under every neighbour edge
func build_floor() -> void:
	var br := _breaks(); var ua: Array = br[0]; var va: Array = br[1]
	var nx := ua.size() - 1; var nz := va.size() - 1
	var full := PackedByteArray(); full.resize(nx * nz)
	var hy := PackedFloat32Array(); hy.resize(nx * nz * 4)
	var mats: Array = []; mats.resize(nx * nz)
	var E := 0.004
	for i in nx:
		for j in nz:
			var a := float(ua[i]); var b := float(ua[i + 1]); var c := float(va[j]); var d := float(va[j + 1])
			var cell := PackedVector2Array([Vector2(a, c), Vector2(b, c), Vector2(b, d), Vector2(a, d)])
			var all_in := true
			for p: Vector2 in cell:
				if not Geometry2D.is_point_in_polygon(p, outline) and not _on_outline(p): all_in = false; break
			if all_in:
				for p: Vector2 in outline:
					if p.x > a + 1e-3 and p.x < b - 1e-3 and p.y > c + 1e-3 and p.y < d - 1e-3: all_in = false; break
			var cu := (a + b) * 0.5; var cv := (c + d) * 0.5
			var m := mat_at(cu, cv)
			mats[i * nz + j] = m
			if all_in:
				full[i * nz + j] = 1
				var hs := [y(a + E, c + E), y(b - E, c + E), y(b - E, d - E), y(a + E, d - E)]
				for k in 4: hy[(i * nz + j) * 4 + k] = hs[k]
				_gq(m, Vector3(a, hs[0], c), Vector3(b, hs[1], c), Vector3(b, hs[2], d), Vector3(a, hs[3], d))
			else:
				for poly: PackedVector2Array in Geometry2D.intersect_polygons(cell, outline):
					if poly.size() < 3: continue
					var cen := Vector2.ZERO
					for p: Vector2 in poly: cen += p
					cen /= poly.size()
					var m2 := mat_at(cen.x, cen.y)
					var idx := Geometry2D.triangulate_polygon(poly)
					for t in range(0, idx.size(), 3):
						var pts: Array[Vector3] = []
						for q in 3:
							var p: Vector2 = poly[idx[t + q]]
							var pin := p + (cen - p).normalized() * E if p.distance_to(cen) > E else p
							var h := edge_y(p.x, p.y)
							if is_nan(h): h = y(pin.x, pin.y)
							pts.append(Vector3(p.x, h, p.y) - O())
						g.tri(m2, pts[0], pts[1], pts[2])
	for i in nx:
		for j in nz:
			if full[i * nz + j] == 0: continue
			var k0 := (i * nz + j) * 4
			if i + 1 < nx and full[(i + 1) * nz + j] == 1:
				var k1 := ((i + 1) * nz + j) * 4
				_face(Vector2(ua[i + 1], va[j]), Vector2(ua[i + 1], va[j + 1]), hy[k0 + 1], hy[k0 + 2], hy[k1 + 0], hy[k1 + 3], mats[i * nz + j], mats[(i + 1) * nz + j], Vector2(1, 0))
			if j + 1 < nz and full[i * nz + j + 1] == 1:
				var k2 := (i * nz + j + 1) * 4
				_face(Vector2(ua[i], va[j + 1]), Vector2(ua[i + 1], va[j + 1]), hy[k0 + 3], hy[k0 + 2], hy[k2 + 0], hy[k2 + 1], mats[i * nz + j], mats[i * nz + j + 1], Vector2(0, 1))
	# skirt under every neighbour edge (0.3 m, in the edge's own surface)
	for k in outline.size():
		if String(okind[k]) != "nb": continue
		var a2 := outline[k]; var c2 := outline[(k + 1) % outline.size()]
		var h0 := oy[k]; var h1 := oy[(k + 1) % outline.size()]
		var mid := (a2 + c2) * 0.5
		var into := Vector2(-(c2 - a2).y, (c2 - a2).x).normalized()
		if not Geometry2D.is_point_in_polygon(mid + into * 0.05, outline): into = -into
		var m3 := mat_at(mid.x + into.x * 0.3, mid.y + into.y * 0.3)
		if m3 in ["white", "yellow", "red", "sand"]: m3 = "concrete"
		_gq(m3, Vector3(a2.x, h0 - 0.3, a2.y), Vector3(c2.x, h1 - 0.3, c2.y), Vector3(c2.x, h1, c2.y), Vector3(a2.x, h0, a2.y), Vector3(-into.x, 0, -into.y), true)

func _on_outline(p: Vector2) -> bool:
	return not is_nan(edge_y(p.x, p.y)) or _on_cut(p)

func _on_cut(p: Vector2) -> bool:
	for k in outline.size():
		if String(okind[k]) != "cut": continue
		var q := Geometry2D.get_closest_point_to_segment(p, outline[k], outline[(k + 1) % outline.size()])
		if q.distance_to(p) < 0.01: return true
	return false

## one vertical face along a shared cell edge p -> q where side A (a0 at p, a1 at q) and side B (b0, b1) differ;
## to_b = the direction from A to B
func _face(p: Vector2, q: Vector2, a0: float, a1: float, b0: float, b1: float, ma: String, mb: String, to_b: Vector2) -> void:
	if absf(a0 - b0) < 0.01 and absf(a1 - b1) < 0.01: return
	var hi_a := (a0 + a1) > (b0 + b1)
	var drop := absf((a0 + a1) - (b0 + b1)) * 0.5
	var m := "wall"
	if drop < 0.22 and not (ma in ["grass", "mulch", "sand"] and mb in ["grass", "mulch", "sand"]): m = "concrete"   # a riser or a kerb
	var out := to_b if hi_a else -to_b
	_gq(m, Vector3(p.x, minf(a0, b0), p.y), Vector3(q.x, minf(a1, b1), q.y), Vector3(q.x, maxf(a1, b1), q.y), Vector3(p.x, maxf(a0, b0), p.y), Vector3(out.x, 0, out.y), true)
	if m == "wall": walls_m += p.distance_to(q)

## ---------------------------------------------------------------- finish
## keep each ground wear mark only where its whole quad lies on a surface it belongs to (strip builder's rule): no
## wear on grass or mulch, nothing over the outline, no mark across a step
func wear_on_paving() -> void:
	const PAVE := ["asphalt", "concrete", "white", "yellow", "red", "paving", "plaza"]
	var nv := PackedVector3Array(); var nn := PackedVector3Array(); var nuv := PackedVector2Array(); var nc := PackedColorArray()
	var kept := 0; var dropped := 0
	for q in range(0, dec.V.size(), 6):
		var ok := true
		if dec.N[q].is_equal_approx(Vector3.UP):
			var uv0 := dec.UV[q]
			for k in 6: uv0 = uv0.min(dec.UV[q + k])
			var tile := int(uv0.x * 4.0) + 4 * int(uv0.y * 4.0)
			var on_gravel_ok := tile in [6, 7, 8, 14, 15]
			var sand_ok := tile in [4, 5, 14]
			var pts: Array[Vector3] = [dec.V[q], dec.V[q + 1], dec.V[q + 2], dec.V[q + 5]]
			pts.append((pts[0] + pts[2]) * 0.5)
			var ys: Array = []
			for pt: Vector3 in pts:
				var u := pt.x + ox; var v := pt.z + oz
				if not Geometry2D.is_point_in_polygon(Vector2(u, v), outline): ok = false; break
				var m := mat_at(u, v)
				if not (m in PAVE or (m == "gravel" and on_gravel_ok) or (m == "sand" and sand_ok)): ok = false; break
				ys.append(y(u, v))
			if ok and (ys.max() - ys.min()) > 0.12: ok = false
		if ok:
			for k in 6: nv.append(dec.V[q + k]); nn.append(dec.N[q + k]); nuv.append(dec.UV[q + k]); nc.append(dec.C[q + k])
			kept += 1
		else: dropped += 1
	dec.V = nv; dec.N = nn; dec.UV = nuv; dec.C = nc; dec.count = kept
	print("%s: wear marks kept %d, dropped %d (off their surface)" % [name, kept, dropped])

func finish(ground_only := false, stops := "prop_wheel_stop_concrete") -> void:
	root.set_meta(&"stalls", stalls)
	var sl: Array = []
	for s in shops: sl.append(s[0])
	root.set_meta(&"shops", sl)
	if not stalls.is_empty() and not ground_only: wheel_stops(stops)
	build_floor()
	if not ground_only:
		wear_on_paving()
		var wm := dec.build()
		if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	if not ground_only: props.build(root, K)
	print("%s: ground tris %d, retaining faces %.0f m, props %d, buildings %d, stalls %d, shops %d%s" % [name, g.tri_count(), walls_m, props.count(), bl.get_child_count(), stalls.size(), shops.size(), " (GROUND ONLY)" if ground_only else ""])
	K.save_piece(root, name)
