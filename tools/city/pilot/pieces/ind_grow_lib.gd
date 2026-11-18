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
static func frontage(props: K.Props, m: Dictionary, sx: float, sz: float, axis: String, taken: Array, opens: Array, kind := "chain", s_from := 22.0, s_to := 99.8, shut: Array = []) -> void:
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
			var g := Vector2(o - I.OPEN_HALF - 3.0, d + 0.6) if axis == "x" else Vector2(d + 0.6, o - I.OPEN_HALF - 3.0)
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
		I.add(props, "plant_bougainvillea_wall", "normal", q(sx, sz, 92.45, v), -90.0 * sx, false)
		v += rr.randf_range(5.0, 9.0)
	v = v0 + 6.0
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
