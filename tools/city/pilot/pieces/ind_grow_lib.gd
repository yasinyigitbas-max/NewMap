extends RefCounted
## Industrial GROWTH helpers (18 Nov, Yasin: "start growing" the zones; variants of the locked industrial sample).
## The locked sample's blocks (i_ne / i_nw / i_se / i_sw) were built with ind_lib.gd on the sample's own truck streets
## (property line 8.7 m everywhere). The growth blocks stand on the road kit's streets instead: 1st St (the bay-front
## ring, property line 14.3 inland), 3rd St (the arterial, 14.3, tapering to the truck section by J Ave), and the
## truck avenues (8.7), each with its own kerb returns and driveway aprons. So a growth block MEASURES the street pieces
## around its site before it lays its ground: the block's floor starts exactly where the street's sidewalk ends (no gap,
## no overlap, no z-fight), and every gate sits on one of the street's aprons. ind_lib.gd is only called, never changed
## (locked pieces were built with it).
##
## Frame (as ind_lib): the piece origin is the junction centre; quadrant signs sx, sz; u = |x| along the cross street
## (the street on the junction's x axis), v = |z| along the avenue (the z axis). Every growth block is 100 x 100 m.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const LAYOUT := "res://map_dc/coronado/city_kit/city_grid_layout.json"
const LEN := 100.0
const R0 := 24.0       # beyond this the ground is a plain rectangle (no street edge reaches further in)

## Load every street piece (j_*, s_*) within reach of the site into a throw-away node (never saved), let physics see
## them, and measure: ex[i] = sidewalk depth from the cross street's axis at u = i * 0.5; ez[i] = the same from the
## avenue's axis at v = i * 0.5; c = where the corner's edge crosses the diagonal. 2 cm precision (bisection).
static func measure(tree: SceneTree, j: Vector3, sx: float, sz: float) -> Dictionary:
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var tmp := Node3D.new(); tree.get_root().add_child(tmp)
	for r: Dictionary in lay.instances:
		var pc := String(r.piece)
		if not (pc.begins_with("j_") or pc.begins_with("s_")): continue
		var p: Array = r.pos
		if absf(float(p[0]) - j.x) > 260.0 or absf(float(p[2]) - j.z) > 260.0: continue
		var path := "res://map_dc/coronado/city_kit/pieces/%s.scn" % pc
		if not ResourceLoader.exists(path): continue
		var n: Node3D = (load(path) as PackedScene).instantiate()
		n.position = Vector3(float(p[0]) - j.x, float(p[1]) - j.y, float(p[2]) - j.z); n.rotation.y = deg_to_rad(float(r.yaw))
		tmp.add_child(n)
	for k in 4: await tree.physics_frame
	var space := tmp.get_world_3d().direct_space_state
	var hit := func(u: float, v: float) -> bool:
		var q := PhysicsRayQueryParameters3D.create(Vector3(sx * u, 40.0, sz * v), Vector3(sx * u, -40.0, sz * v))
		return not space.intersect_ray(q).is_empty()
	# depth of the covered strip along a line: scan down from 30 m, then bisect the last step
	var depth := func(along_u: bool, s: float) -> float:
		var d := 30.0
		while d > 0.0:
			var cov: bool = hit.call(s, d) if along_u else hit.call(d, s)
			if cov: break
			d -= 0.25
		if d <= 0.0: return 0.0
		var lo := d; var hi := d + 0.25
		for it in 4:
			var m := (lo + hi) * 0.5
			var cov2: bool = hit.call(s, m) if along_u else hit.call(m, s)
			if cov2: lo = m
			else: hi = m
		return hi
	var ex := PackedFloat32Array(); var ez := PackedFloat32Array()
	for i in int(LEN * 2.0) + 1:
		ex.append(depth.call(true, i * 0.5)); ez.append(depth.call(false, i * 0.5))
	var t := 30.0
	while t > 0.0 and not hit.call(t, t): t -= 0.1
	var out := {"ex": ex, "ez": ez, "c": Vector2(t + 0.1, t + 0.1)}
	tmp.queue_free()
	for k in 2: await tree.process_frame
	print("MEASURE ex(30)=%.2f ex(60)=%.2f ex(95)=%.2f ez(30)=%.2f ez(60)=%.2f ez(95)=%.2f corner %.2f" % [ex[60], ex[120], ex[190], ez[60], ez[120], ez[190], t])
	return out

## sidewalk depth at u along the cross street / at v along the avenue (linear between the 0.5 m samples)
static func eu(m: Dictionary, u: float) -> float:
	var a: PackedFloat32Array = m.ex; var f := clampf(u * 2.0, 0.0, a.size() - 1.001); var i := int(f)
	return lerpf(a[i], a[i + 1], f - i)
static func ev(m: Dictionary, v: float) -> float:
	var a: PackedFloat32Array = m.ez; var f := clampf(v * 2.0, 0.0, a.size() - 1.001); var i := int(f)
	return lerpf(a[i], a[i + 1], f - i)
## front setback for a building on the cross street from s0 to s1: 0.5 m behind the deepest sidewalk over its span
static func front_x(m: Dictionary, s0: float, s1: float) -> float:
	var d := 0.0; var s := s0
	while s <= s1: d = maxf(d, eu(m, s)); s += 0.5
	return d + 0.5
static func front_z(m: Dictionary, s0: float, s1: float) -> float:
	var d := 0.0; var s := s0
	while s <= s1: d = maxf(d, ev(m, s)); s += 0.5
	return d + 0.5

## The block's ground: an L-shaped band that follows the measured street edge (polygon, smooth at the kerb returns:
## 0.5 m samples near the corner, 2 m on the straights, collinear points dropped) plus the inner rectangle R0..100,
## where the paints (gravel, grass, stall lines) go through painted_rect as in the sample.
static func floor(g: K.Ground, m: Dictionary, sx: float, sz: float, paints: Array, base := "asphalt") -> void:
	var c: Vector2 = m.c
	var pts: Array = [Vector2(LEN, R0), Vector2(LEN, eu(m, LEN))]
	var u := LEN - 2.0
	while u > c.x:
		pts.append(Vector2(u, eu(m, u))); u -= (2.0 if u > 30.0 else 0.5)
	pts.append(c)
	var v := c.y + 0.5
	while v < LEN:
		pts.append(Vector2(ev(m, v), v)); v += (2.0 if v > 30.0 else 0.5)
	pts.append(Vector2(ev(m, LEN), LEN)); pts.append(Vector2(R0, LEN)); pts.append(Vector2(R0, R0))
	var keep: Array = []
	for i in pts.size():
		var a: Vector2 = pts[(i - 1 + pts.size()) % pts.size()]; var b: Vector2 = pts[i]; var n: Vector2 = pts[(i + 1) % pts.size()]
		if absf((b - a).cross(n - b)) > 0.0004 or (b - a).length() < 0.001: keep.append(b)
	var pv := PackedVector2Array()
	for p: Vector2 in keep: pv.append(Vector2(sx * p.x, sz * p.y))
	g.poly(base, pv, S.walk_y)
	K.painted_rect(g, minf(sx * R0, sx * LEN), minf(sz * R0, sz * LEN), maxf(sx * R0, sx * LEN), maxf(sz * R0, sz * LEN), paints, S.walk_y, base)

## world point of a block-local (u, v)
static func q(sx: float, sz: float, u: float, v: float, y := 0.0) -> Vector3:
	return Vector3(sx * u, S.walk_y(0.0) + y, sz * v)

## a straight wall of 2.03 m panels (fence_cmu_wall / fence_stucco_wall / fence_graffiti_cmu_panel) from a to b
## (block-local u, v); `tag_every` puts a graffiti panel in (block walls by streets and yards get tagged)
static func wall(props: K.Props, sx: float, sz: float, a: Vector2, b: Vector2, base := "fence_cmu_wall", tag_every := 0, cond := "worn") -> void:
	var L := a.distance_to(b)
	if L < 1.0: return
	var n := maxi(1, int(round(L / 2.03)))
	var yaw := rad_to_deg(atan2(sx * (b.x - a.x), sz * (b.y - a.y))) + 90.0
	for i in n:
		var p := a.lerp(b, (i + 0.5) / n)
		var bb := "fence_graffiti_cmu_panel" if tag_every > 0 and i % tag_every == tag_every / 2 else base
		I.add(props, bb, cond, q(sx, sz, p.x, p.y), yaw)

## chain-link lot fence in block-local coordinates (ind_lib.lot_fence: a post at every 2 m joint)
static func chain(props: K.Props, sx: float, sz: float, a: Vector2, b: Vector2, barbed := false) -> void:
	I.lot_fence(props, Vector2(sx * a.x, sz * a.y), Vector2(sx * b.x, sz * b.y), barbed)

## frontage fence on the measured property line between `taken` spans (buildings) and `opens` (apron centres, 7 m
## open driveway each, ind_lib.OPEN_HALF): kind "chain" / "cmu" / "stucco" / "board". Gate leaves stand slid open
## inside the fence beside each opening (closed: `shut` lists apron centres whose leaf stands across the opening).
static func frontage(props: K.Props, m: Dictionary, sx: float, sz: float, axis: String, taken: Array, opens: Array, kind := "chain", s_from := 22.0, s_to := 99.8, shut: Array = [], leaf_after: Array = []) -> void:
	var cuts: Array = taken.duplicate()
	for o: float in opens: cuts.append([o - I.OPEN_HALF, o + I.OPEN_HALF])
	cuts.sort_custom(func(p: Array, r: Array) -> bool: return p[0] < r[0])
	var line := func(s0: float, s1: float) -> void:
		if s1 - s0 < 0.6: return
		# the property line may taper (3rd St by J Ave): split into 10 m pieces that follow it
		var nseg := maxi(1, int(ceil((s1 - s0) / 10.0)))
		for k in nseg:
			var a := lerpf(s0, s1, float(k) / nseg); var b := lerpf(s0, s1, float(k + 1) / nseg)
			var da := (eu(m, a) if axis == "x" else ev(m, a)) + 0.15; var db := (eu(m, b) if axis == "x" else ev(m, b)) + 0.15
			var pa := Vector2(a, da) if axis == "x" else Vector2(da, a); var pb := Vector2(b, db) if axis == "x" else Vector2(db, b)
			match kind:
				"chain": chain(props, sx, sz, pa, pb)
				"cmu": wall(props, sx, sz, pa, pb, "fence_cmu_wall", 5)
				"stucco": wall(props, sx, sz, pa, pb, "fence_stucco_wall")
				"board": _board(props, sx, sz, pa, pb)
	var cur := s_from
	for ct: Array in cuts:
		line.call(cur, float(ct[0])); cur = maxf(cur, float(ct[1]))
	line.call(cur, s_to)
	for o: float in opens:
		var d := (eu(m, o) if axis == "x" else ev(m, o)) + 0.15
		if o in shut:
			var p := Vector2(o, d) if axis == "x" else Vector2(d, o)
			I.add(props, "fence_gate_rolling_chainlink", "rusty", q(sx, sz, p.x, p.y), 0.0 if axis == "x" else 90.0)
		else:
			var go := o + I.OPEN_HALF + 3.0 if o in leaf_after else o - I.OPEN_HALF - 3.0     # the leaf slides away from a door
			var g := Vector2(go, d + 0.6) if axis == "x" else Vector2(d + 0.6, go)
			I.add(props, "fence_gate_rolling_chainlink", "worn", q(sx, sz, g.x, g.y), 0.0 if axis == "x" else 90.0)

## weathered board fence (2.0 m boards), no posts in the model's own panel ends: a privacy post at every joint
static func _board(props: K.Props, sx: float, sz: float, a: Vector2, b: Vector2) -> void:
	var L := a.distance_to(b)
	var n := maxi(1, int(ceil(L / 2.0 - 0.02)))
	var yaw := rad_to_deg(atan2(sx * (b.x - a.x), sz * (b.y - a.y))) + 90.0
	for i in n: I.add(props, "fence_weathered_board", "worn", q(sx, sz, a.lerp(b, (i + 0.5) / n).x, a.lerp(b, (i + 0.5) / n).y), yaw)
	for i in n + 1: I.add(props, "fence_post_privacy", "worn", q(sx, sz, a.lerp(b, float(i) / n).x, a.lerp(b, float(i) / n).y), yaw)

## sidewalk furniture of a frontage business, 1 m in from the measured back of the walk... no: 1 m out from the
## property line onto the walk, facing the street (block piece owns it: the reuse rule)
static func walk_prop(props: K.Props, m: Dictionary, sx: float, sz: float, axis: String, s: float, base: String, cond := "worn") -> void:
	if axis == "x": I.add(props, base, cond, q(sx, sz, s, eu(m, s) - 1.0), 0.0 if sz > 0.0 else 180.0)
	else: I.add(props, base, cond, q(sx, sz, ev(m, s) - 1.0, s), 90.0 if sx > 0.0 else -90.0)

## a column of 20 ft containers end to end along v (long side along z), stacked by `hts` (1-3 high per slot)
static func stack_col(props: K.Props, rr: RandomNumberGenerator, sx: float, sz: float, u: float, v0: float, hts: Array, reefer := false) -> void:
	var cols := ["prop_container_20ft_white"] if reefer else ["prop_container_20ft_red", "prop_container_20ft_blue", "prop_container_20ft_green", "prop_container_20ft_white"]
	for k in hts.size():
		for h in int(hts[k]):
			I.add(props, cols[rr.randi() % cols.size()], "dirty" if rr.randf() < 0.55 else "worn", q(sx, sz, u + rr.randf_range(-0.08, 0.08), v0 + k * 6.35, h * 2.59), rr.randf_range(-0.6, 0.6))

## parking stalls (2.7 m wide) in a row along u at depth v, cars nosing toward +v (nose = 1) or -v; rubber or concrete
## wheel stops at the nose; returns [x, z, yaw] rows for the "stalls" meta (the preview / game parks cars there)
static func stalls(props: K.Props, sx: float, sz: float, u0: float, n: int, v: float, nose: float, stop := "prop_wheel_stop_rubber", skip: Array = []) -> Array:
	var out: Array = []
	for k in n:
		if k in skip: continue
		var u := u0 + k * 2.7 + 1.35
		I.add(props, stop, "clean", q(sx, sz, u, v + nose * 2.4), 0.0, false)
		var yaw := 0.0 if sz * nose > 0.0 else 180.0
		out.append([sx * u, sz * v, yaw])
	return out
## stall lines for painted_rect (block-local -> paint rects): thin white lines between the stalls of a row
static func stall_paint(sx: float, sz: float, u0: float, n: int, v: float, nose: float) -> Array:
	var p: Array = []
	for k in n + 1:
		var u := u0 + k * 2.7
		var a := Vector2(sx * (u - 0.06), sz * (v - 2.6 * nose)); var b := Vector2(sx * (u + 0.06), sz * (v + 2.6 * nose))
		p.append([minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), "white"])
	return p

## a buffer to the houses on the block's far edge u = 100 (CITY_PLAN: "an alley, park or yard between industrial and
## residential, never a hard jump"): stucco wall at u = 92 (opaque: no see-through layers), bougainvillea on its
## house side, a grass strip with torrey pines and eucalyptus, mixed ages
static func house_buffer(props: K.Props, rr: RandomNumberGenerator, sx: float, sz: float, v0: float, v1: float) -> void:
	wall(props, sx, sz, Vector2(92.0, v0), Vector2(92.0, v1), "fence_stucco_wall", 0, "dirty")
	var v := v0 + 3.0
	while v < v1 - 2.0:
		I.add(props, "plant_bougainvillea_wall", "normal", q(sx, sz, 93.0, v), -90.0 * sx, false)
		v += rr.randf_range(5.0, 9.0)
	v = maxf(v0 + 6.0, 28.0)      # trees on the grass only (the strip in front of R0 is paved)
	var k := 0
	while v < v1 - 4.0:
		var sp: String = ["tree_torrey_pine_b", "tree_eucalyptus_a", "tree_torrey_pine_a", "tree_eucalyptus_b"][k % 4]
		props.add(sp, "normal", q(sx, sz, 96.0 + rr.randf_range(-0.6, 0.6), v), rr.randf_range(0, 360), true, rr.randf_range(0.8, 1.1))
		v += rr.randf_range(10.0, 14.0); k += 1

## ------------------------------------------------------------------ buildings by their REAL mesh, not the footprint
## Some kit models reach past their listed footprint: ext_marina_office carries a 20 m wooden jetty in front (18 Nov:
## it lay across 1st St, Yasin saw "wooden pieces on the road"), the car wash a 5 m canopy, the harbour office a 4 m
## porch, the warehouse and factory a 3.5 m dock apron. put / put_back measure the near mesh and set the building back
## so that its real front (or back) stands where the footprint's would.
static var _over := {}
static func overhang(folder: String) -> Vector2:
	if _over.has(folder): return _over[folder]
	var d: float = float(K.building_stats(folder).footprint_wd[1])
	var o := Vector2.ZERO
	var f := K._tier_file(K._bdir(folder), "near")
	if f != "":
		var inst: Node = (load(f) as PackedScene).instantiate()
		var mi := K._first_mesh(inst)
		if mi:
			var a: AABB = mi.transform * mi.get_aabb()
			o = Vector2(maxf(0.0, a.end.z - d * 0.5), maxf(0.0, -a.position.z - d * 0.5))
		inst.free()
	_over[folder] = o
	return o
static func put(bl: Node3D, props: K.Props, sx: float, sz: float, axis: String, s0: float, f: float, folder: String, label := "", services := true) -> Array:
	return I.put(bl, props, sx, sz, axis, s0, f + overhang(folder).x, folder, label, services)
static func put_back(bl: Node3D, props: K.Props, sx: float, sz: float, axis: String, s0: float, folder: String, label := "", back := 97.5) -> Array:
	var d: float = float(K.building_stats(folder).footprint_wd[1])
	return I.put(bl, props, sx, sz, axis, s0, back - d - overhang(folder).y, folder, label, true)

## ------------------------------------------------------------------ polish (Yasin 18 Nov: "run a polish pass on your
## part, lots of props ... think like an interior and exterior designer, customer and city planner"). place() puts ONE
## prop into a zone chosen for its purpose (a break spot behind the plant, the gate exit, the shed's rollups) at the
## first free spot of a seeded search: clear of every building (its real mesh outline), of every prop already placed
## (oriented footprints from the kit manifests, a 0.25 m gap), of 1.6 m round every building door, and of the `keep`
## rectangles (truck lanes, gate openings, stall rows). A prop that finds no free spot is left out, never forced.
static func _obb(c: Vector2, yaw: float, w: float, d: float) -> Array:
	var a := deg_to_rad(yaw); var ux := Vector2(cos(a), -sin(a)); var uz := Vector2(sin(a), cos(a))
	return [c, ux, uz, w * 0.5, d * 0.5]
static func _sep(A: Array, B: Array) -> bool:
	for ax: Vector2 in [A[1], A[2], B[1], B[2]]:
		var ra: float = float(A[3]) * absf(ax.dot(A[1])) + float(A[4]) * absf(ax.dot(A[2]))
		var rb: float = float(B[3]) * absf(ax.dot(B[1])) + float(B[4]) * absf(ax.dot(B[2]))
		if absf(ax.dot(Vector2(B[0]) - Vector2(A[0]))) > ra + rb: return true
	return false
static func _fp(base: String) -> Vector2:
	var m := K.manifest(base)
	return Vector2(float(m.get("footprint_w", 0.6)), float(m.get("footprint_d", 0.6)))
## world-space boxes of everything that is already there (buildings by their real mesh, doors with 1.6 m, props)
static func obstacles(bl: Node3D, props: K.Props, stalls: Array = []) -> Array:
	var out: Array = []
	for r: Array in stalls: out.append(_obb(Vector2(float(r[0]), float(r[1])), float(r[2]), 2.6, 5.4))     # parked cars
	for b: Node in bl.get_children():
		if not b.has_meta(&"kit"): continue
		var n := b as Node3D; var f := String(b.get_meta(&"kit"))
		var st := K.building_stats(f); var w: float = float(st.footprint_wd[0]); var d: float = float(st.footprint_wd[1])
		var o := overhang(f)
		var yaw := rad_to_deg(n.rotation.y)
		var lc := Vector3(0.0, 0.0, (o.x - o.y) * 0.5)
		var wc: Vector3 = n.transform * lc
		out.append(_obb(Vector2(wc.x, wc.z), yaw, w + 0.4, d + o.x + o.y + 0.4))
		for e: Array in st.get("doors_front", []):
			var dp: Vector3 = n.transform * Vector3(float(e[1]), 0.0, d * 0.5 + 0.8)
			out.append(_obb(Vector2(dp.x, dp.z), yaw, 3.2, 3.2))
	for key: String in props.items:
		var base := key.get_slice("|", 0)
		var f2 := _fp(base)
		for t: Transform3D in props.items[key]:
			if t.origin.y > S.walk_y(0.0) + 1.2: continue      # stacked boxes, wall-mounted things
			out.append(_obb(Vector2(t.origin.x, t.origin.z), rad_to_deg(t.basis.get_euler().y), f2.x + 0.25, f2.y + 0.25))
	return out
## one prop in the zone [u0..u1] x [v0..v1] (block-local), yaw = the zone's facing (+- jitter); keep = [[u0, v0, u1, v1]]
static func place(props: K.Props, obs: Array, rr: RandomNumberGenerator, sx: float, sz: float, base: String, cond: String, u0: float, v0: float, u1: float, v1: float, yaw: float, keep: Array = [], jitter := 8.0) -> bool:
	var f := _fp(base)
	for t in 60:
		var u := rr.randf_range(u0, u1); var v := rr.randf_range(v0, v1)
		var bad := false
		for k: Array in keep:
			if u > float(k[0]) - f.x * 0.6 and u < float(k[2]) + f.x * 0.6 and v > float(k[1]) - f.y * 0.6 and v < float(k[3]) + f.y * 0.6: bad = true; break
		if bad: continue
		var y := yaw + rr.randf_range(-jitter, jitter)
		var B := _obb(Vector2(sx * u, sz * v), y, f.x, f.y)
		for A: Array in obs:
			if not _sep(A, B): bad = true; break
		if bad: continue
		I.add(props, base, cond, q(sx, sz, u, v), y)
		obs.append(_obb(Vector2(sx * u, sz * v), y, f.x + 0.25, f.y + 0.25))
		return true
	return false
## a small set placed together (a break spot: table, bench, bin), each by place() inside the same zone
static func spot(props: K.Props, obs: Array, rr: RandomNumberGenerator, sx: float, sz: float, items: Array, u0: float, v0: float, u1: float, v1: float, yaw: float, keep: Array = []) -> int:
	var n := 0
	for it: Array in items:
		if place(props, obs, rr, sx, sz, String(it[0]), String(it[1]), u0, v0, u1, v1, yaw + float(it[2]) if it.size() > 2 else yaw, keep): n += 1
	return n

## ------------------------------------------------------------------ the rest of the zone (19 Nov, Yasin: "roll out to
## your whole zone"): blocks that are not 100 x 100 m corners on flat ground. measure_rows() reads the ground of EVERY
## piece around (streets and the neighbouring blocks) along rows 0.5 m apart, so a strip ending in the ring's rounded
## corner, or a block between a sloping street and flat neighbours, gets its exact free area; floor_rows() lays it as
## trapezoids between the rows (smooth edges, no stair steps) and drapes each vertex onto heights interpolated from
## the measured heights all round its edge (a Coons patch: the street's own walk on the street sides, the neighbour's
## ground on the others), so there is no step at any seam.
static func measure_rows(tree: SceneTree, j: Vector3, sx: float, sz: float, Lu: float, Lv: float, own: Array = []) -> Dictionary:
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var tmp := Node3D.new(); tree.get_root().add_child(tmp)
	for r: Dictionary in lay.instances:
		var pc := String(r.piece)
		if pc in own or pc.begins_with("w_") or pc.begins_with("x_"): continue
		var p: Array = r.pos
		if absf(float(p[0]) - j.x) > 320.0 or absf(float(p[2]) - j.z) > 320.0: continue
		var path := "res://map_dc/coronado/city_kit/pieces/%s.scn" % pc
		if not ResourceLoader.exists(path): continue
		var n: Node3D = (load(path) as PackedScene).instantiate()
		n.position = Vector3(float(p[0]) - j.x, float(p[1]) - j.y, float(p[2]) - j.z); n.rotation.y = deg_to_rad(float(r.yaw))
		tmp.add_child(n)
	for k in 4: await tree.physics_frame
	var space := tmp.get_world_3d().direct_space_state
	var ray := func(u: float, v: float) -> Dictionary:
		return space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(sx * u, 40.0, sz * v), Vector3(sx * u, -40.0, sz * v)))
	var free := func(u: float, v: float) -> bool: return (ray.call(u, v) as Dictionary).is_empty()
	var rows: Array = []      # [v, a, b]
	var v := 0.25
	while v <= Lv - 0.01:
		var a := -1.0; var b := -1.0
		var u := 0.125
		while u < Lu:
			if free.call(u, v):
				if a < 0.0: a = u
				b = u
			elif a >= 0.0: break
			u += 0.25
		if a >= 0.0:
			var lo := maxf(a - 0.25, 0.0); var hi := a
			for it in 5:
				var m := (lo + hi) * 0.5
				if free.call(m, v): hi = m
				else: lo = m
			a = 0.0 if a <= 0.13 else hi
			lo = b; hi = minf(b + 0.25, Lu)
			for it in 5:
				var m2 := (lo + hi) * 0.5
				if free.call(m2, v): lo = m2
				else: hi = m2
			b = Lu if b >= Lu - 0.13 else lo
			rows.append([v, a, b])
		v += 0.5
	# heights all round: just outside the free area on each side (street walk or neighbour ground); none -> pad
	var hy := func(u: float, v2: float) -> float:
		var h: Dictionary = ray.call(u, v2)
		return -999.0 if h.is_empty() else float((h.position as Vector3).y)      # nothing there: open land
	var hN := PackedFloat32Array(); var hF := PackedFloat32Array(); var hL := PackedFloat32Array(); var hR := PackedFloat32Array()
	var v_first: float = float(rows[0][0]) if not rows.is_empty() else 0.0
	# each edge height is read just OUTSIDE the free area at that point (on the walk or the neighbour's ground, never
	# on the road beyond): N/F at the first/last row holding u, L/R beside each row's ends; gaps take the nearest value
	var fill := func(arr: PackedFloat32Array, ok: Array) -> PackedFloat32Array:
		for i in arr.size():
			if ok[i]: continue
			for d in range(1, arr.size()):
				if i - d >= 0 and ok[i - d]: arr[i] = arr[i - d]; break
				if i + d < arr.size() and ok[i + d]: arr[i] = arr[i + d]; break
		return arr
	var okN: Array = []; var okF: Array = []; var okL: Array = []; var okR: Array = []
	for i in 21:
		var uu := clampf(Lu * i / 20.0, 0.3, Lu - 0.3)
		var vmin := INF; var vmax := -INF
		for rw: Array in rows:
			if uu >= float(rw[1]) and uu <= float(rw[2]): vmin = minf(vmin, float(rw[0])); vmax = maxf(vmax, float(rw[0]))
		var a1: float = hy.call(uu, vmin - 0.6) if vmin < INF else -999.0
		var a2: float = hy.call(uu, vmax + 0.6) if vmax > -INF else -999.0
		hN.append(a1); okN.append(a1 > -900.0); hF.append(a2); okF.append(a2 > -900.0)
	for i2 in 21:
		var vv := clampf(Lv * i2 / 20.0, 0.3, Lv - 0.3)
		var rw2 := []
		for rw: Array in rows: if absf(float(rw[0]) - vv) < 0.3: rw2 = rw
		var a3: float = hy.call(float(rw2[1]) - 0.6, vv) if not rw2.is_empty() else -999.0
		var a4: float = hy.call(float(rw2[2]) + 0.6, vv) if not rw2.is_empty() else -999.0
		hL.append(a3); okL.append(a3 > -900.0); hR.append(a4); okR.append(a4 > -900.0)
	# an edge with nothing beside it at all (open land: the terrain will be fitted to us) takes the straight line between
	# the neighbouring edges' ends, so no corner gets a step; a partly open edge takes its nearest measured value
	var none := func(ok: Array) -> bool: return not ok.has(true)
	if not none.call(okN): hN = fill.call(hN, okN)
	if not none.call(okF): hF = fill.call(hF, okF)
	if not none.call(okL): hL = fill.call(hL, okL)
	if not none.call(okR): hR = fill.call(hR, okR)
	var walk := S.walk_y(0.0)
	for i3 in 21:
		var t := i3 / 20.0
		if none.call(okL): hL[i3] = lerpf(hN[0] if not none.call(okN) else walk, hF[0] if not none.call(okF) else walk, t)
		if none.call(okR): hR[i3] = lerpf(hN[20] if not none.call(okN) else walk, hF[20] if not none.call(okF) else walk, t)
	for i4 in 21:
		var s4 := i4 / 20.0
		if none.call(okN): hN[i4] = lerpf(hL[0], hR[0], s4)
		if none.call(okF): hF[i4] = lerpf(hL[20], hR[20], s4)
	tmp.queue_free()
	for k in 2: await tree.process_frame
	print("MEASURE_ROWS rows %d, first v %.2f; heights N %.2f..%.2f F %.2f..%.2f L %.2f..%.2f R %.2f..%.2f" % [rows.size(), v_first, hN[0], hN[20], hF[0], hF[20], hL[0], hL[20], hR[0], hR[20]])
	return {"rows": rows, "Lu": Lu, "Lv": Lv, "hN": hN, "hF": hF, "hL": hL, "hR": hR}

## the ground height at block-local (u, v): a Coons patch of the four measured edge height lines
static func h_at(m: Dictionary, u: float, v: float) -> float:
	var Lu: float = m.Lu; var Lv: float = m.Lv
	var s := clampf(u / Lu, 0.0, 1.0); var t := clampf(v / Lv, 0.0, 1.0)
	var at := func(a: PackedFloat32Array, f: float) -> float:
		var x := f * 20.0; var i := mini(int(x), 19); return lerpf(a[i], a[i + 1], x - i)
	var hN: PackedFloat32Array = m.hN; var hF: PackedFloat32Array = m.hF; var hL: PackedFloat32Array = m.hL; var hR: PackedFloat32Array = m.hR
	var c00 := (hN[0] + hL[0]) * 0.5; var c10 := (hN[20] + hR[0]) * 0.5; var c01 := (hF[0] + hL[20]) * 0.5; var c11 := (hF[20] + hR[20]) * 0.5
	return (1.0 - s) * float(at.call(hL, t)) + s * float(at.call(hR, t)) + (1.0 - t) * float(at.call(hN, s)) + t * float(at.call(hF, s)) \
		- ((1.0 - s) * (1.0 - t) * c00 + s * (1.0 - t) * c10 + (1.0 - s) * t * c01 + s * t * c11)
## the drape offset (0 on flat ground) at block-local (u, v)
static func dh(m: Dictionary, u: float, v: float) -> float:
	return h_at(m, u, v) - S.walk_y(0.0)

## the floor as trapezoids between measured rows, its surface by paint rectangles [u0, v0, u1, v1, surface] (block-
## local, the first match wins, else `base`), heights already draped (the drape pass skips the ground)
static func floor_rows(g: K.Ground, m: Dictionary, sx: float, sz: float, paints: Array, base := "asphalt") -> void:
	var rows: Array = m.rows
	var surf_at := func(u: float, v: float) -> String:
		for p: Array in paints:
			if u >= float(p[0]) and u <= float(p[2]) and v >= float(p[1]) and v <= float(p[3]): return String(p[4])
		return base
	var y := func(u: float, v: float) -> float: return h_at(m, u, v)
	for i in rows.size() - 1:
		var r0: Array = rows[i]; var r1: Array = rows[i + 1]
		if float(r1[0]) - float(r0[0]) > 0.75: continue
		var cuts: Array = [0.0, 1.0]
		for p: Array in paints:
			for e: float in [float(p[0]), float(p[2])]:
				for rr2: Array in [r0, r1]:
					var f := (e - float(rr2[1])) / maxf(float(rr2[2]) - float(rr2[1]), 0.01)
					if f > 0.0 and f < 1.0: cuts.append(f)
		cuts.sort()
		for k in cuts.size() - 1:
			var f0: float = cuts[k]; var f1: float = cuts[k + 1]
			if f1 - f0 < 0.002: continue
			var a0 := lerpf(float(r0[1]), float(r0[2]), f0); var b0 := lerpf(float(r0[1]), float(r0[2]), f1)
			var a1 := lerpf(float(r1[1]), float(r1[2]), f0); var b1 := lerpf(float(r1[1]), float(r1[2]), f1)
			var vm := (float(r0[0]) + float(r1[0])) * 0.5
			var sfc: String = surf_at.call((a0 + b0 + a1 + b1) * 0.25, vm)
			var v0 := float(r0[0]) - (0.25 if i == 0 else 0.0); var v1 := float(r1[0]) + (0.25 if i == rows.size() - 2 else 0.0)
			var P := func(u: float, vv: float) -> Vector3: return Vector3(sx * u, float(y.call(u, vv)), sz * vv)
			g.quad(sfc, P.call(a0, v0), P.call(b0, v0), P.call(b1, v1), P.call(a1, v1))

## lay everything built flat onto the measured heights: props, decals, buildings (each at the lowest ground under
## its footprint, so no side floats); the ground from floor_rows is already draped
static func drape(m: Dictionary, sx: float, sz: float, props: K.Props, dec: K.Decals, bl: Node3D) -> void:
	for key: String in props.items:
		var arr: Array = props.items[key]
		for i in arr.size():
			var t: Transform3D = arr[i]
			t.origin.y += dh(m, sx * t.origin.x, sz * t.origin.z); arr[i] = t
	for i2 in props.col_items.size():
		var c: Array = props.col_items[i2]; var t2: Transform3D = c[2]
		t2.origin.y += dh(m, sx * t2.origin.x, sz * t2.origin.z); c[2] = t2
	var vv := dec.V
	for i3 in vv.size(): vv[i3].y += dh(m, sx * vv[i3].x, sz * vv[i3].z)
	dec.V = vv
	for b: Node in bl.get_children():
		var n := b as Node3D
		var st := K.building_stats(String(b.get_meta(&"kit", "")))
		var w: float = 4.0; var d: float = 4.0
		if not st.is_empty(): w = float(st.footprint_wd[0]); d = float(st.footprint_wd[1])
		var lo := INF
		for cx: float in [-0.5, 0.0, 0.5]:
			for cz: float in [-0.5, 0.0, 0.5]:
				var p3: Vector3 = n.transform * Vector3(cx * w, 0.0, cz * d)
				lo = minf(lo, dh(m, sx * p3.x, sz * p3.z))
		n.position.y += lo

## the free interval [a, b] of the measured row nearest to v (block-local u), or [] when the row is covered
static func row_at(mr: Dictionary, v: float) -> Array:
	var best: Array = []; var dv := 1e9
	for r: Array in mr.rows:
		if absf(float(r[0]) - v) < dv: dv = absf(float(r[0]) - v); best = r
	return best if dv < 0.6 else []
## a wall along the LEFT edge of the measured rows (a street side that curves, like the ring's corner), from v0 to v1,
## 0.2 m in from the street's walk; panels of 2.03 m following the edge, skipping the rows given in `gaps` [[v0, v1]]
static func wall_left(props: K.Props, mr: Dictionary, sx: float, sz: float, v0: float, v1: float, base := "fence_cmu_wall", tag_every := 0, gaps: Array = []) -> void:
	var pts: Array = []
	var v := v0
	while v <= v1:
		var r := row_at(mr, v)
		if not r.is_empty() and float(r[1]) < float(mr.Lu) - 1.0: pts.append(Vector2(float(r[1]) + 0.2, v))
		v += 0.5
	if pts.size() < 2: return
	# walk the polyline, a panel every 2.03 m of its length
	var acc := 0.0; var k := 0
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]; var b: Vector2 = pts[i + 1]
		var L := a.distance_to(b)
		var t := 0.0
		while acc + (L - t) >= 2.03:
			t += 2.03 - acc; acc = 0.0
			var c := a.lerp(b, t / L) - (b - a).normalized() * 1.015
			var skip := false
			for gp: Array in gaps: if c.y > float(gp[0]) and c.y < float(gp[1]): skip = true
			if not skip:
				var yaw := rad_to_deg(atan2(sx * (b.x - a.x), sz * (b.y - a.y))) + 90.0
				I.add(props, "fence_graffiti_cmu_panel" if tag_every > 0 and k % tag_every == tag_every / 2 else base, "worn", q(sx, sz, c.x, c.y), yaw)
			k += 1
		acc += L - t
