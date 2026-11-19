extends RefCounted
## Waterfront FILL pieces (n_wf_*, branch claude/fill-waterfront, 19 Nov 2026): the two empty blocks west of the
## waterfront sample (Yasin 19 Nov: "two blocks next to water front will be waterfront area, not residental").
## This file is a set of TOOLS, not a recipe: it decides nothing about what stands where. Every building, terrace, stair
## and prop is written by hand, with its reason, in the piece's own script (n_wf_<site>.gd). It copies the helpers of
## the waterfront sample's libraries (wf_lib, ind_lib, strip_lib, cc_lib, kit_lib) and of the strip growth's builder,
## changed to take every height from this block's own ground. No shared library is edited.
##
## Frame: grid frame shifted to the piece's origin (x = u - ox, z = v - oz), y = ABSOLUTE datum metres; the layout row
## is [ox, 0, oz], yaw 0 (review/grow_wf_blocks.json).
##
## THE GROUND (land first, super-builder skill):
##  * base field: wf_fill_ground.json (tools/city/pilot/zoning/wf_fill_ground.py) - a smooth surface over the piece's
##    rectangle whose edges are the street walks (and neighbouring pieces' edges) measured just outside, so every edge
##    meets its neighbour flush. Inside it is a harmonic fill (no bumps of its own).
##  * frontage band: within `band[side]` metres of an edge the ground IS the base field (the walk carries on flush).
##  * terraces: level pads written by hand (terrace()); "wall" = a retaining wall at its edge (a vertical face where it
##    meets lower or higher ground), "ease" = blended back into the field over `blend` m (lawn banks).
##  * ramps and stairs between terraces (ramp(), stairs()), written by hand.
##  * the floor mesh is cut on every terrace / ramp / stair / paint edge (no slanted cell across a step) and every
##    height jump between two neighbouring cells gets a vertical face (retaining wall, riser, kerb): no see-through gaps.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const GROUND := "res://tools/city/pilot/pieces/wf_fill_ground.json"
const STALL_W := 2.6
const STALL_D := 5.5
const CELL := 4.0            # largest floor cell (field areas are smooth; terraces are flat)

var name := ""
var ox := 0.0; var oz := 0.0
var x0 := 0.0; var z0 := 0.0; var x1 := 0.0; var z1 := 0.0
var fnx := 0; var fnz := 0; var fst := 2.0; var fy: PackedFloat32Array
var band := {"n": 0.0, "s": 0.0, "w": 0.0, "e": 0.0}    # frontage band per side (n = z0 edge, s = z1, w = x0, e = x1)
var terr: Array = []          # [x0, z0, x1, z1, y, kind ("wall" / "ease"), blend, label]
var slopes: Array = []        # [x0, z0, x1, z1, axis ("x"/"z"), ya (at the low coordinate), yb, n_steps (0 = ramp)]
var root: Node3D; var bl: Node3D
var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
var rr: RandomNumberGenerator
var paints: Array = []; var stalls: Array = []; var B: Array = []; var shops: Array = []
var walls_m := 0.0            # metres of retaining face built (report)
var yfn: Callable

func _init(piece: String) -> void:
	name = piece
	S.hill_on = false
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GROUND)).pieces[piece]
	ox = float(d.ox); oz = float(d.oz)
	x0 = float(d.x0); z0 = float(d.z0); x1 = float(d.x1); z1 = float(d.z1)
	fnx = int(d.nx); fnz = int(d.nz); fst = float(d.step); fy = PackedFloat32Array(d.y)
	root = Node3D.new(); root.name = piece
	bl = Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	rr = W.rng_for(piece)
	yfn = func(x: float, z: float) -> float: return y(x, z)

## ---------------------------------------------------------------- ground
## the measured base field (bilinear on its 2 m grid; the grid's first node sits on (x0, z0))
func field(x: float, z: float) -> float:
	var fx := clampf((x - x0) / fst, 0.0, fnx - 1.001); var fz := clampf((z - z0) / fst, 0.0, fnz - 1.001)
	var i := int(fx); var j := int(fz); var tx := fx - i; var tz := fz - j
	var a := fy[j * fnx + i]; var b := fy[j * fnx + i + 1]; var c := fy[(j + 1) * fnx + i]; var e := fy[(j + 1) * fnx + i + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, e, tx), tz)

func in_band(x: float, z: float) -> bool:
	return z - z0 < float(band.n) or z1 - z < float(band.s) or x - x0 < float(band.w) or x1 - x < float(band.e)

func y(x: float, z: float) -> float:
	if in_band(x, z): return field(x, z)
	for k in range(slopes.size() - 1, -1, -1):
		var s: Array = slopes[k]
		if x >= float(s[0]) and x <= float(s[2]) and z >= float(s[1]) and z <= float(s[3]):
			var t := (x - float(s[0])) / maxf(float(s[2]) - float(s[0]), 0.01) if String(s[4]) == "x" else (z - float(s[1])) / maxf(float(s[3]) - float(s[1]), 0.01)
			var n := int(s[7])
			if n > 0: t = minf(floor(t * n + 1e-4), n - 1.0) / (n - 1.0) if n > 1 else 0.0   # treads: first at ya, last at yb
			return lerpf(float(s[5]), float(s[6]), t)
	var h := field(x, z)
	var blended := false
	for k in range(terr.size() - 1, -1, -1):
		var p: Array = terr[k]
		var dx := maxf(maxf(float(p[0]) - x, x - float(p[2])), 0.0)
		var dz := maxf(maxf(float(p[1]) - z, z - float(p[3])), 0.0)
		var dd := sqrt(dx * dx + dz * dz)
		if dd <= 0.0: return float(p[4])
		if String(p[5]) == "ease" and dd < float(p[6]) and not blended:
			var t := dd / float(p[6]); t = t * t * (3.0 - 2.0 * t)
			h = lerpf(float(p[4]), h, t); blended = true
	return h

## a level terrace (hand-placed): kind "wall" = retaining face at its edge, "ease" = lawn bank blended over `blend` m
func terrace(ax: float, az: float, bx: float, bz: float, h: float, kind := "wall", blend := 4.0, label := "") -> float:
	terr.append([minf(ax, bx), minf(az, bz), maxf(ax, bx), maxf(az, bz), h, kind, blend, label])
	return h

## a ramp from ya (at the low coordinate of its axis) to yb; checks the grade (8.3 % walk ramp, 12 % drive)
func ramp(ax: float, az: float, bx: float, bz: float, axis: String, ya: float, yb: float, drive := false) -> void:
	var run := (maxf(ax, bx) - minf(ax, bx)) if axis == "x" else (maxf(az, bz) - minf(az, bz))
	var gr := absf(yb - ya) / maxf(run, 0.01)
	if gr > (0.12 if drive else 0.0834): print("WARNING %s: ramp %.1f %% steeper than allowed" % [name, gr * 100.0])
	slopes.append([minf(ax, bx), minf(az, bz), maxf(ax, bx), maxf(az, bz), axis, ya, yb, 0])

## a flight of steps: risers of at most 17 cm, treads at least 30 cm; ya at the low coordinate of the axis
func stairs(ax: float, az: float, bx: float, bz: float, axis: String, ya: float, yb: float) -> int:
	var n := maxi(2, int(ceil(absf(yb - ya) / 0.17)) + 1)
	var run := (maxf(ax, bx) - minf(ax, bx)) if axis == "x" else (maxf(az, bz) - minf(az, bz))
	if run / n < 0.29: print("WARNING %s: stair treads %.2f m (too short)" % [name, run / n])
	slopes.append([minf(ax, bx), minf(az, bz), maxf(ax, bx), maxf(az, bz), axis, ya, yb, n])
	return n - 1

## ---------------------------------------------------------------- placing
func p3(x: float, z: float, lift := 0.0) -> Vector3: return Vector3(x, y(x, z) + lift, z)

func add(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true, lift := 0.0) -> void:
	I.add(props, base, cond, p3(x, z, lift), yaw, collide)

## a kit building centred at (x, z), front (+Z) turned by yaw, standing at height h (a terrace it must stand on; the
## four corners and the centre are checked: a building is never left on a slope)
func bld(folder: String, x: float, z: float, yaw: float, label: String, wear := 0.75, services := true, shop := true) -> Array:
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var h := y(x, z)
	for c: Vector3 in [Vector3(-w, 0, -d), Vector3(w, 0, -d), Vector3(w, 0, d), Vector3(-w, 0, d)]:
		var p: Vector3 = Vector3(x, 0, z) + b * (c * 0.49)
		if absf(y(p.x, p.z) - h) > 0.02: print("WARNING %s: building %s corner off its terrace by %.2f m" % [name, label, y(p.x, p.z) - h])
	var n := K.building(bl, folder, Vector3(x, h, z), yaw, label, wear)
	n.set_meta(&"label", label)
	if services: back_of_house(n, w, d, false)
	B.append([n, w, d, folder])
	if shop and not (st.get("doors_front", []) as Array).is_empty(): shops.append([label, folder])
	return [n, w, d]

## meters, gas meter, AC condensers on the rear wall at the building's own floor (cc_lib.back_of_house on this ground)
func back_of_house(node: Node3D, w: float, d: float, compact := false, residential := false) -> void:
	var yaw := rad_to_deg(node.rotation.y) + 180.0
	var at := func(lx: float, ly: float, lz: float) -> Vector3:
		var p: Vector3 = node.transform * Vector3(lx, 0.0, lz)
		return Vector3(p.x, node.position.y + ly, p.z)
	var xa := -w * 0.5 + 1.6
	for k in 3: props.add("prop_meter_electric", "worn", at.call(xa + k * 0.42, 1.05, -d * 0.5 - 0.02), yaw)
	props.add("prop_meter_gas", "rusty", at.call(xa + 1.7, 0.2, -d * 0.5 - 0.02), yaw)
	var n_ac := 1 if w < 14.0 else 2
	for k in n_ac:
		props.add("prop_ac_condenser_compact" if compact else "prop_ac_condenser", "worn", at.call(xa + 3.4 + k * 1.3, 0.0, -d * 0.5 - (0.47 if compact else 0.75)), yaw)
	if residential:
		for k in 3: props.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", at.call(w * 0.5 - 1.5 - k * 0.8, 0.0, -d * 0.5 - 0.75), yaw)

## a world point on a building: local (lx, lz) of its footprint at its floor (+ly)
func on_bld(b: Array, lx: float, lz: float, ly := 0.0) -> Vector3:
	var n: Node3D = b[0]
	var p: Vector3 = n.transform * Vector3(lx, 0.0, lz)
	return Vector3(p.x, n.position.y + ly, p.z)

func bld_yaw(b: Array, dyaw := 0.0) -> float: return rad_to_deg((b[0] as Node3D).rotation.y) + dyaw

## a prop against a building: local (lx, lz), facing out of the front (+Z) turned by dyaw, at the building's floor
func at_bld(b: Array, base: String, cond: String, lx: float, lz: float, dyaw := 0.0, ly := 0.0, collide := true) -> void:
	I.add(props, base, cond, on_bld(b, lx, lz, ly), bld_yaw(b, dyaw), collide)

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
		var wp: Vector3 = n.transform * s
		I.add(props, String(items[placed]), "worn" if rr.randf() < 0.7 else "rusty", wp, rad_to_deg(n.rotation.y) + 90.0 * (rr.randi() % 2), false)
		used.append(s); placed += 1
	if placed < items.size(): print("%s: roof of %s took %d of %d items (no more flat spots)" % [name, n.name, placed, items.size()])
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
func rect(ax: float, az: float, bx: float, bz: float, mat: String) -> Array:
	return [minf(ax, bx), minf(az, bz), maxf(ax, bx), maxf(az, bz), mat]

func paint(ax: float, az: float, bx: float, bz: float, mat: String) -> void: paints.append(rect(ax, az, bx, bz, mat))

## n stalls side by side along x from xs, the aisle edge at z = ze, nose toward dir (+1 = larger z)
func stalls_x(xs: float, n: int, ze: float, dir: float, w := STALL_W) -> void:
	var za := ze + dir * STALL_D
	for k in n + 1:
		paints.insert(0, rect(xs + k * w - 0.05, minf(ze, za) + (0.3 if dir < 0 else 0.0), xs + k * w + 0.05, maxf(ze, za) - (0.3 if dir > 0 else 0.0), "white"))
	for k in n:
		var cx := xs + (k + 0.5) * w; var cz := ze + dir * STALL_D * 0.5
		var yaw := 0.0 if dir > 0.0 else 180.0
		stalls.append([cx, cz, yaw, y(cx, cz), _grade(cx, cz, yaw)])

## n stalls side by side along z from zs, the aisle edge at x = xe, nose toward dir (+1 = larger x)
func stalls_z(zs: float, n: int, xe: float, dir: float, w := STALL_W) -> void:
	var xa := xe + dir * STALL_D
	for k in n + 1:
		paints.insert(0, rect(minf(xe, xa) + (0.3 if dir < 0 else 0.0), zs + k * w - 0.05, maxf(xe, xa) - (0.3 if dir > 0 else 0.0), zs + k * w + 0.05, "white"))
	for k in n:
		var cz := zs + (k + 0.5) * w; var cx := xe + dir * STALL_D * 0.5
		var yaw := 90.0 if dir > 0.0 else -90.0
		stalls.append([cx, cz, yaw, y(cx, cz), _grade(cx, cz, yaw)])

func _grade(x: float, z: float, yaw: float) -> float:
	var f := Vector2(sin(deg_to_rad(yaw)), cos(deg_to_rad(yaw)))
	return snappedf((y(x + f.x * 2.0, z + f.y * 2.0) - y(x - f.x * 2.0, z - f.y * 2.0)) / 4.0, 0.001)

## wheel stops at the head of every stall
func wheel_stops(kind := "prop_wheel_stop_concrete") -> void:
	var r2 := W.rng_for(name + "_ws")
	for st: Array in stalls:
		var yaw := float(st[2])
		var f := Vector2(sin(deg_to_rad(yaw)), cos(deg_to_rad(yaw)))
		var px := float(st[0]) + f.x * (STALL_D * 0.5 - 0.55); var pz := float(st[1]) + f.y * (STALL_D * 0.5 - 0.55)
		var off := r2.randf() < 0.15
		I.add(props, kind, "dirty" if off else "worn", p3(px, pz, 0.002), yaw + (r2.randf_range(-10, 10) if off else 0.0), false)

## ---------------------------------------------------------------- fences, walls, railings (a post at every joint)
const FENCE := {"chain": ["fence_chainlink_lot", "fence_chainlink_lot_post", 2.0], "cmu": ["fence_cmu_wall", "", 2.03],
	"stucco": ["fence_stucco_wall", "", 2.0], "privacy": ["fence_wood_privacy", "fence_post_privacy", 2.4],
	"iron": ["fence_wrought_iron", "fence_post_wrought_iron", 1.98], "board": ["fence_weathered_board", "fence_post_privacy", 2.4],
	"vinyl": ["fence_vinyl_canal_rail", "fence_post_vinyl", 2.4], "picket": ["fence_picket_white", "fence_post_picket", 2.0],
	"brick": ["fence_brick_wall", "", 2.0]}
## a straight run a -> b; each panel stands at the LOWEST ground under its length (-3 cm: a panel on a slope never
## floats at its downhill end), or at `at` when given (a railing on a terrace edge stands on the terrace)
func fence(kind: String, ax: float, az: float, bx: float, bz: float, cond := "worn", at := NAN) -> void:
	var a := Vector2(ax, az); var b := Vector2(bx, bz)
	var ln := a.distance_to(b)
	if ln < 0.5: return
	var f: Array = FENCE[kind]
	var pl := float(f[2])
	var e := K.manifest(String(f[0]))
	if e.has("footprint_w"): pl = float(e.footprint_w)
	var n := maxi(1, int(ceil(ln / pl - 0.02)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	var low := func(p: Vector2, q: Vector2) -> float:
		if not is_nan(at): return at
		var m := INF
		for t in 5: var r := p.lerp(q, t / 4.0); m = minf(m, y(r.x, r.y))
		return m - 0.03
	for i in n:
		var p0 := a.lerp(b, float(i) / n); var p1 := a.lerp(b, float(i + 1) / n); var m := (p0 + p1) * 0.5
		I.add(props, String(f[0]), cond, Vector3(m.x, low.call(p0, p1), m.y), yaw)
	if String(f[1]) != "":
		for i in n + 1:
			var q := a.lerp(b, float(i) / n)
			I.add(props, String(f[1]), cond, Vector3(q.x, (at if not is_nan(at) else y(q.x, q.y) - 0.03), q.y), yaw)

## a dumpster enclosure (strip_lib.enclosure on this ground) with its two gate leaves; open toward yaw
func enclosure(x: float, z: float, yaw: float, mess := true) -> void:
	L.enclosure(props, p3(x, z), yaw)
	var bq := Basis(Vector3.UP, deg_to_rad(yaw))
	var gl := float(K.manifest("fence_gate_privacy").get("footprint_w", 1.105))
	for side: float in [-1.0, 1.0]:
		var gp: Vector3 = p3(x, z) + bq * Vector3(side * (3.15 - gl * 0.5), 0, 2.46)
		I.add(props, "fence_gate_privacy", "worn", Vector3(gp.x, y(gp.x, gp.z), gp.z), yaw)
	if mess: L.enclosure_mess(props, rr, p3(x, z), yaw)

## ---------------------------------------------------------------- wear (every mark on this ground)
func building_wear() -> void:
	for b: Array in B:
		var n: Node3D = b[0]; var w: float = b[1]; var d: float = b[2]
		var t := n.transform
		var pt := func(lx: float, lz: float) -> Vector2:
			var v: Vector3 = t * Vector3(lx, 0.0, lz); return Vector2(v.x, v.z)
		wall_grime(pt.call(-w * 0.5, d * 0.5 + 0.5), pt.call(w * 0.5, d * 0.5 + 0.5))
		wall_grime(pt.call(-w * 0.5, -d * 0.5 - 0.6), pt.call(w * 0.5, -d * 0.5 - 0.6))

## dirt and salt along a wall's foot (ind_lib.wall_grime on this ground)
func wall_grime(a: Vector2, b: Vector2) -> void:
	var ln := a.distance_to(b); var dir := (b - a) / maxf(ln, 0.01)
	var yaw := rad_to_deg(atan2(dir.x, dir.y)) + 90.0
	var s := 0.0
	while s < ln:
		var seg := minf(rr.randf_range(2.0, 4.0), ln - s)
		dec.add(14, a + dir * (s + seg * 0.5), yaw, seg, rr.randf_range(0.6, 1.0), yfn, Color(1, 1, 1, rr.randf_range(0.35, 0.6)))
		s += seg + rr.randf_range(0.0, 2.0)

## ageing over a paved rect: cracks (half sealed), dark patches, pale repairs, oil where cars stood, puddle stains
func yard_wear(ax: float, az: float, bx: float, bz: float, density := 1.0, oil := true) -> void:
	var area := absf((bx - ax) * (bz - az)); var n := int(area / 35.0 * density)
	var lo := Vector2(minf(ax, bx), minf(az, bz)); var hi := Vector2(maxf(ax, bx), maxf(az, bz))
	W.cracks(dec, rr, lo.x, lo.y, hi.x, hi.y, n, yfn, 0.45)
	var rp := func() -> Vector2: return Vector2(rr.randf_range(lo.x, hi.x), rr.randf_range(lo.y, hi.y))
	for k in int(n * 0.25): dec.add(2 + k % 2, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.5, 6.0), rr.randf_range(1.5, 4.0), yfn, Color(1, 1, 1, 0.85))
	for k in int(n * 0.15): W.pale_patch(dec, rr, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.0, 4.0), rr.randf_range(2.0, 4.0), yfn)
	if oil:
		for k in int(n * 0.4): W.oil(dec, rr, rp.call(), rr.randf_range(0, 180), yfn, rr.randf_range(0.5, 0.9))
	for k in int(n * 0.25): dec.add(14, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.0, 5.0), rr.randf_range(2.0, 5.0), yfn, Color(1, 1, 1, rr.randf_range(0.4, 0.7)))

## sand carried up from the beach on feet and wind (pale sand-tinted patches) over a rect
func sand_drift(ax: float, az: float, bx: float, bz: float, n: int) -> void:
	for k in n:
		dec.add(4 + k % 2, Vector2(rr.randf_range(minf(ax, bx), maxf(ax, bx)), rr.randf_range(minf(az, bz), maxf(az, bz))), rr.randf_range(0, 180), rr.randf_range(1.2, 3.0), rr.randf_range(0.6, 1.4), yfn, Color(0.86, 0.79, 0.64, 0.55))

func stall_wear(share := 0.6) -> void:
	for s: Array in stalls:
		if rr.randf() < share: W.oil(dec, rr, Vector2(float(s[0]), float(s[1])), float(s[2]), yfn, rr.randf_range(0.5, 0.9))

## tyre marks where cars turn in (a drive mouth): two lines and oil where they stop (asphalt only)
func tyre_path(ax: float, az: float, bx: float, bz: float) -> void:
	var a := Vector2(ax, az); var b := Vector2(bx, bz)
	var ln := a.distance_to(b); var dir := (b - a) / maxf(ln, 0.01); var side := Vector2(-dir.y, dir.x)
	var yaw := rad_to_deg(atan2(dir.x, dir.y)); var s := 0.0
	while s < ln:
		var seg := minf(6.0, ln - s)
		for o: float in [-0.9, 0.9]:
			dec.add(8, a + dir * (s + seg * 0.5) + side * o, yaw + rr.randf_range(-4, 4), 0.6, seg, yfn, Color(1, 1, 1, rr.randf_range(0.35, 0.55)))
		s += seg

## ---------------------------------------------------------------- checks used while placing
func half(base: String) -> float:
	var e := K.manifest(base)
	return maxf(float(e.get("footprint_w", 0.6)), float(e.get("footprint_d", 0.6))) * 0.5

## the ground's material at a point (first paint wins, as in K.painted_rect), asphalt otherwise
func mat_at(x: float, z: float) -> String:
	for p: Array in paints:
		if x > float(p[0]) and x < float(p[2]) and z > float(p[1]) and z < float(p[3]): return String(p[4]) if String(p[4]) != "-" else "asphalt"
	return "asphalt"

## ---------------------------------------------------------------- floor
## breakpoints: rect edges, every terrace / slope / paint edge, every stair riser, and a global CELL grid
func _breaks() -> Array:
	var xs := {x0: true, x1: true}; var zs := {z0: true, z1: true}
	var addx := func(v: float) -> void:
		if v > x0 + 1e-3 and v < x1 - 1e-3: xs[snappedf(v, 0.001)] = true
	var addz := func(v: float) -> void:
		if v > z0 + 1e-3 and v < z1 - 1e-3: zs[snappedf(v, 0.001)] = true
	var v := x0 + CELL
	while v < x1 - 0.5: addx.call(v); v += CELL
	v = z0 + CELL
	while v < z1 - 0.5: addz.call(v); v += CELL
	for b: String in ["n", "s", "w", "e"]:
		var d := float(band[b])
		if d <= 0.0: continue
		if b == "n": addz.call(z0 + d)
		elif b == "s": addz.call(z1 - d)
		elif b == "w": addx.call(x0 + d)
		else: addx.call(x1 - d)
	for p: Array in terr + paints:
		addx.call(float(p[0])); addx.call(float(p[2])); addz.call(float(p[1])); addz.call(float(p[3]))
	for s: Array in slopes:
		addx.call(float(s[0])); addx.call(float(s[2])); addz.call(float(s[1])); addz.call(float(s[3]))
		var n := int(s[7])
		for k in range(1, n):
			if String(s[4]) == "x": addx.call(lerpf(float(s[0]), float(s[2]), float(k) / n))
			else: addz.call(lerpf(float(s[1]), float(s[3]), float(k) / n))
	var xa: Array = xs.keys(); xa.sort(); var za: Array = zs.keys(); za.sort()
	return [xa, za]

func _material(cx: float, cz: float) -> String:
	var m := mat_at(cx, cz)
	return "asphalt" if m == "-" else m

## builds the floor: every cell its own quad, heights read a hair inside the cell (so a terrace edge is a clean step),
## then a vertical face wherever two neighbouring cells' edges do not meet (retaining walls, risers, kerbs) and a 0.3 m
## skirt under the outer edge
func floor() -> void:
	var br := _breaks(); var xa: Array = br[0]; var za: Array = br[1]
	var nx := xa.size() - 1; var nz := za.size() - 1
	var hy := PackedFloat32Array(); hy.resize(nx * nz * 4)       # per cell: corner heights (x0z0, x1z0, x1z1, x0z1)
	var mats: Array = []; mats.resize(nx * nz)
	var E := 0.004
	for i in nx:
		for j in nz:
			var a := float(xa[i]); var b := float(xa[i + 1]); var c := float(za[j]); var d := float(za[j + 1])
			var cx := (a + b) * 0.5; var cz := (c + d) * 0.5
			var m := _material(cx, cz); mats[i * nz + j] = m
			var hs := [y(a + E, c + E), y(b - E, c + E), y(b - E, d - E), y(a + E, d - E)]
			for k in 4: hy[(i * nz + j) * 4 + k] = hs[k]
			g.quad(m, Vector3(a, hs[0], c), Vector3(b, hs[1], c), Vector3(b, hs[2], d), Vector3(a, hs[3], d))
	# faces between neighbours
	for i in nx:
		for j in nz:
			var k0 := (i * nz + j) * 4
			if i + 1 < nx:      # shared edge at x = xa[i+1]: this cell's (1,2) against the next cell's (0,3)
				var k1 := ((i + 1) * nz + j) * 4
				_face(Vector2(xa[i + 1], za[j]), Vector2(xa[i + 1], za[j + 1]), hy[k0 + 1], hy[k0 + 2], hy[k1 + 0], hy[k1 + 3], mats[i * nz + j], mats[(i + 1) * nz + j], Vector2(1, 0))
			if j + 1 < nz:      # shared edge at z = za[j+1]: this cell's (3,2) against the next cell's (0,1)
				var k2 := (i * nz + j + 1) * 4
				_face(Vector2(xa[i], za[j + 1]), Vector2(xa[i + 1], za[j + 1]), hy[k0 + 3], hy[k0 + 2], hy[k2 + 0], hy[k2 + 1], mats[i * nz + j], mats[i * nz + j + 1], Vector2(0, 1))
	# skirt under the outer edge (0.3 m, in the edge's own surface)
	var down := func(x: float, z: float) -> float: return field(x, z) - 0.3
	var top := func(x: float, z: float) -> float: return field(x, z)
	for e: Array in [[Vector2(x0, z0), Vector2(x1, z0)], [Vector2(x1, z0), Vector2(x1, z1)], [Vector2(x1, z1), Vector2(x0, z1)], [Vector2(x0, z1), Vector2(x0, z0)]]:
		var a2: Vector2 = e[0]; var c2: Vector2 = e[1]
		var n := int(ceil(a2.distance_to(c2)))
		for k in n:
			var p0 := a2.lerp(c2, float(k) / n); var p1 := a2.lerp(c2, float(k + 1) / n)
			var mid := (p0 + p1) * 0.5 + (Vector2(x0 + x1, z0 + z1) * 0.5 - (p0 + p1) * 0.5).normalized() * 0.05
			var m2 := _material(mid.x, mid.y)
			if m2 in ["white", "yellow", "red", "sand"]: m2 = "concrete"
			g.wall_line(m2, PackedVector2Array([p0, p1]), down, top, 1.0)

## one vertical face along a shared cell edge p -> q where side A (heights a0 at p, a1 at q) and side B (b0, b1) differ
func _face(p: Vector2, q: Vector2, a0: float, a1: float, b0: float, b1: float, ma: String, mb: String, to_b: Vector2) -> void:
	if absf(a0 - b0) < 0.01 and absf(a1 - b1) < 0.01: return
	var hi_a := (a0 + a1) > (b0 + b1)
	var m := "wall"
	var drop := absf((a0 + a1) - (b0 + b1)) * 0.5
	if drop < 0.22: m = "concrete" if not (ma in ["grass", "mulch", "sand"] and mb in ["grass", "mulch", "sand"]) else "wall"     # a riser or a kerb
	var t0 := maxf(a0, b0); var t1 := maxf(a1, b1); var l0 := minf(a0, b0); var l1 := minf(a1, b1)
	var out := to_b if hi_a else -to_b        # the face looks toward the LOWER side
	g.quad(m, Vector3(p.x, l0, p.y), Vector3(q.x, l1, q.y), Vector3(q.x, t1, q.y), Vector3(p.x, t0, p.y), Vector3(out.x, 0, out.y), true)
	if m == "wall": walls_m += p.distance_to(q)

## ---------------------------------------------------------------- finish
## keep each ground wear mark only where its whole quad lies on a surface it belongs to (strip builder's rule): no
## wear on grass, mulch or sand, nothing over the block edge, and no mark across a terrace step
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
			var sand_ok := tile in [4, 5, 14]       # sand drift and footpaths on sand
			var pts: Array[Vector3] = [dec.V[q], dec.V[q + 1], dec.V[q + 2], dec.V[q + 5]]
			var cen := (pts[0] + pts[2]) * 0.5
			pts.append(cen)
			var ys: Array = []
			for pt: Vector3 in pts:
				if pt.x < x0 + 0.05 or pt.x > x1 - 0.05 or pt.z < z0 + 0.05 or pt.z > z1 - 0.05: ok = false; break
				var m := mat_at(pt.x, pt.z)
				if not (m in PAVE or (m == "gravel" and on_gravel_ok) or (m == "sand" and sand_ok)): ok = false; break
				ys.append(y(pt.x, pt.z))
			if ok and (ys.max() - ys.min()) > 0.12: ok = false       # across a step
		if ok:
			for k in 6: nv.append(dec.V[q + k]); nn.append(dec.N[q + k]); nuv.append(dec.UV[q + k]); nc.append(dec.C[q + k])
			kept += 1
		else: dropped += 1
	dec.V = nv; dec.N = nn; dec.UV = nuv; dec.C = nc; dec.count = kept
	print("%s: wear marks kept %d, dropped %d (off their surface)" % [name, kept, dropped])

func finish(stops := "prop_wheel_stop_concrete") -> void:
	root.set_meta(&"stalls", stalls)
	var sl: Array = []
	for s in shops: sl.append(s[0])
	root.set_meta(&"shops", sl)
	if not stalls.is_empty(): wheel_stops(stops)
	floor()
	wear_on_paving()
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, retaining faces %.0f m, props %d, buildings %d, stalls %d, shops %d" % [name, g.tri_count(), walls_m, props.count(), bl.get_child_count(), stalls.size(), shops.size()])
	K.save_piece(root, name)
