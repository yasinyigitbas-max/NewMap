extends RefCounted
## Industrial cluster sample helpers (j_ind, s_ind, i_*). Flat ground. Truck streets: one 4.2 m lane each way, a
## 2.5 m shoulder (trucks wait / park), kerb, 2 m sidewalk, property line; no street trees, no meters; 12 m kerb
## returns so a semi can turn. Driveway aprons are STANDARD: 10 m wide at 40 m and 75 m from the junction on both
## sides of every leg, so a plot's gate always lines up with one (the leg piece is reused on all four legs).
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")

const LANE := 4.2        # lane outer edge (from the centre line)
const KERB := 6.7        # kerb line (shoulder 4.2 - 6.7)
const PROP := 8.7        # property line (sidewalk 6.7 - 8.7)
const R := 12.0          # kerb return radius
const J := 22.0          # junction tile half size
const LEN := 100.0       # legs and quadrants reach 100 m from the junction
const APRONS := [40.0, 75.0]
const APRON_W := 10.0
const GATE_W := 6.0

## chain-link lot fence from a to b (2 m panels, posts at the ends); barbed = a barbed wire strand on top
static func lot_fence(props: K.Props, a: Vector2, b: Vector2, barbed := false, cond := "worn") -> void:
	var L := a.distance_to(b)
	if L < 0.5: return
	# panels are 2.0 m: never stretch them apart (gaps), let them close up a little instead; a post at EVERY joint
	# (16 Nov: posts only at the run ends left the panels floating, "fences look bad")
	var n := maxi(1, int(ceil(L / 2.0 - 0.02)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	for i in n:
		var m := a.lerp(b, (i + 0.5) / n)
		props.add("fence_chainlink_lot", cond, Vector3(m.x, S.walk_y(0.0), m.y), yaw)
		if barbed: props.add("fence_barbed_wire", "rusty", Vector3(m.x, S.walk_y(0.0) + 1.86, m.y), yaw, false)
	for i in n + 1:
		var e := a.lerp(b, float(i) / n)
		props.add("fence_chainlink_lot_post", cond, Vector3(e.x, S.walk_y(0.0), e.y), yaw)

## a fence along a street frontage (straight line from s0 to s1 at constant x or z) with rolling gates at the
## standard aprons. along_z: the line runs along z at x = c. Gates stand open, slid back inside the fence.
static func frontage(props: K.Props, along_z: bool, c: float, s0: float, s1: float, inward: float, gates: Array, barbed := false) -> void:
	var sgn := signf(s1 - s0)
	var cuts: Array = []
	for g: float in gates: cuts.append([g - GATE_W * 0.5, g + GATE_W * 0.5])
	cuts.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	var a := minf(s0, s1); var b := maxf(s0, s1)
	var cur := a
	var pt := func(s: float) -> Vector2: return Vector2(c, s) if along_z else Vector2(s, c)
	for ct: Array in cuts:
		lot_fence(props, pt.call(cur), pt.call(float(ct[0])), barbed)
		# the gate leaf, slid open behind the fence on the inside
		var gm: float = float(ct[0]) - GATE_W * 0.5
		var gp: Vector2 = pt.call(gm)
		var off := Vector2(inward, 0.0) if along_z else Vector2(0.0, inward)
		props.add("fence_gate_rolling_chainlink", "worn", Vector3(gp.x + off.x * 0.4, S.walk_y(0.0), gp.y + off.y * 0.4), 90.0 if along_z else 0.0)
		cur = float(ct[1])
	lot_fence(props, pt.call(cur), pt.call(b), barbed)

## a quadrant's floor: everything between the property lines and LEN, minus the junction's corner square
static func quad_floor(g: K.Ground, sx: float, sz: float, paints: Array, base := "asphalt") -> void:
	var r1 := [sx * PROP, sz * J, sx * LEN, sz * LEN]
	var r2 := [sx * J, sz * PROP, sx * LEN, sz * J]
	for r: Array in [r1, r2]:
		K.painted_rect(g, minf(r[0], r[2]), minf(r[1], r[3]), maxf(r[0], r[2]), maxf(r[1], r[3]), paints, S.walk_y, base)

static func finish(root: Node3D, g: K.Ground, props: K.Props, dec: K.Decals, name: String) -> void:
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d, buildings %d" % [name, g.tri_count(), props.count(), root.get_node("Buildings").get_child_count() if root.has_node("Buildings") else 0])
	K.save_piece(root, name)

## ------------------------------------------------------------------ perimeter lots (density pass, Yasin 16 Nov:
## "definitely very very empty"). An industrial quadrant is a PERIMETER BLOCK, as in an old port district: buildings
## stand shoulder to shoulder on both street frontages (fronts 0.5 m behind the property line), broken only by the
## open driveways at the standard aprons; a back row of big sheds stands on the far edges facing in; the middle is the
## shared working yard where trucks load. The frontage fence only fills the gaps between buildings.
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const FRONT := PROP + 0.5
const OPEN_HALF := 3.5          # open driveway: apron centre +- 3.5 m (no gate leaf: buildings flank it)
const BACK := 97.5              # back rows: back wall here (services behind it stay inside the piece)

## Industrial facades weather harder than the high street (0.85: soot, rain streaks, dirt at the foot).
## Place a kit building on a quadrant. axis "x": along the cross street (z = 0), its front facing the street; axis "z":
## along the side street (x = 0). s0 = where it starts, measured from the junction along the axis; f = distance of its
## front from the street axis. Every building faces the junction side. Returns [node, width, depth].
static func put(bl: Node3D, props: K.Props, sx: float, sz: float, axis: String, s0: float, f: float, folder: String, label := "", services := true, wear := 0.85) -> Array:
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var pos: Vector3; var yaw: float
	if axis == "x":
		pos = Vector3(sx * (s0 + w * 0.5), S.walk_y(0.0), sz * (f + d * 0.5)); yaw = 0.0 if sz < 0.0 else 180.0
	else:
		pos = Vector3(sx * (f + d * 0.5), S.walk_y(0.0), sz * (s0 + w * 0.5)); yaw = -90.0 if sx > 0.0 else 90.0
	var n := K.building(bl, folder, pos, yaw, label, wear)
	if services: CC.back_of_house(props, n, folder)
	return [n, w, d]

## back-row building: its back wall on BACK, facing the yard (and the junction)
static func put_back(bl: Node3D, props: K.Props, sx: float, sz: float, axis: String, s0: float, folder: String, label := "", back := BACK) -> Array:
	var st := K.building_stats(folder)
	return put(bl, props, sx, sz, axis, s0, back - float(st.footprint_wd[1]), folder, label, true)

## frontage fence: chain-link on the property line in every gap between [s_from, s_to] that is not a building
## (`taken` = [[s0, s1], ...]) or an open driveway (apron centres in `opens`)
static func street_fence(props: K.Props, sx: float, sz: float, axis: String, taken: Array, opens: Array, s_from := J, s_to := LEN - 0.2, barbed := false) -> void:
	var cuts: Array = taken.duplicate()
	for o: float in opens: cuts.append([o - OPEN_HALF, o + OPEN_HALF])
	cuts.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	var c := PROP + 0.15
	var pt := func(s: float) -> Vector2: return Vector2(sx * s, sz * c) if axis == "x" else Vector2(sx * c, sz * s)
	var cur := s_from
	for ct: Array in cuts:
		if float(ct[0]) - cur > 0.6: lot_fence(props, pt.call(cur), pt.call(float(ct[0])), barbed)
		cur = maxf(cur, float(ct[1]))
	if s_to - cur > 0.6: lot_fence(props, pt.call(cur), pt.call(s_to), barbed)

## a prop with a condition the kit actually has for it (falls back to the nearest one the manifest lists)
static func add(props: K.Props, base: String, cond: String, pos: Vector3, yaw := 0.0, collide := true) -> void:
	if cond == "iron" or cond == "net":     # shader looks over the clean model (kit_lib Props.build)
		props.add(base, cond, pos, yaw, collide); return
	var conds: Array = K.manifest(base).get("conds", [])
	var c := cond
	if conds == ["clean"]: c = cond if cond in ["clean", "worn", "dirty", "rusty", "iron"] else "clean"   # clean-only batch: wear (or black iron) by shader
	elif not conds.is_empty() and not (c in conds):
		var pref := {"rusty": ["dirty", "worn"], "dirty": ["rusty", "worn"], "worn": ["dirty", "clean"], "clean": ["worn"]}
		c = String(conds[0])
		for alt: String in pref.get(cond, []):
			if alt in conds: c = alt; break
	props.add(base, c, pos, yaw, collide)

## world point of a quadrant-local (s along x, t along z) pair; both measured from the junction, positive into the lot
static func q(sx: float, sz: float, u: float, v: float, y := 0.0) -> Vector3:
	return Vector3(sx * u, S.walk_y(0.0) + y, sz * v)

## a block of 20 ft containers in a row (long side along z when along_z), some stacked 2 high
static func containers(props: K.Props, sx: float, sz: float, u: float, v: float, n: int, along_z: bool, rr: RandomNumberGenerator, stack_share := 0.6) -> void:
	var cols := ["prop_container_20ft_red", "prop_container_20ft_blue", "prop_container_20ft_green", "prop_container_20ft_white"]
	for k in n:
		var uu := u + (0.0 if along_z else k * 2.6); var vv := v + (k * 2.6 if along_z else 0.0)
		# along_z: containers side by side along z, so each one's long side runs along x
		var yaw := 90.0 if along_z else 0.0
		add(props, cols[rr.randi() % 4], "dirty" if rr.randf() < 0.5 else "worn", q(sx, sz, uu, vv), yaw)
		if rr.randf() < stack_share: add(props, cols[rr.randi() % 4], "worn" if rr.randf() < 0.5 else "dirty", q(sx, sz, uu, vv, 2.59), yaw)

## grime along the foot of a wall from a to b (yard side): water off the roof, dirt kicked up by trucks
static func wall_grime(dec: K.Decals, a: Vector2, b: Vector2, rr: RandomNumberGenerator) -> void:
	var L := a.distance_to(b); var dir := (b - a) / maxf(L, 0.01)
	var yaw := rad_to_deg(atan2(dir.x, dir.y))
	var s := 1.0
	while s < L - 1.0:
		var seg := minf(rr.randf_range(3.0, 6.0), L - s)
		dec.add(14, a + dir * (s + seg * 0.5), yaw, 1.4, seg, S.walk_y, Color(1, 1, 1, rr.randf_range(0.45, 0.7)))
		s += seg + rr.randf_range(0.5, 2.5)

## wear around one building: grime at the foot of the front and back walls, oil + tyre marks in front of its rollup
## doors (trucks stand there with engines running), a crack or two where the slab meets the yard
static func bld_wear(dec: K.Decals, rr: RandomNumberGenerator, n: Node3D, w: float, d: float, folder: String) -> void:
	var t := n.transform
	var p := func(lx: float, lz: float) -> Vector2:
		var v: Vector3 = t * Vector3(lx, 0.0, lz); return Vector2(v.x, v.z)
	wall_grime(dec, p.call(-w * 0.5, d * 0.5 + 0.5), p.call(w * 0.5, d * 0.5 + 0.5), rr)
	wall_grime(dec, p.call(-w * 0.5, -d * 0.5 - 0.6), p.call(w * 0.5, -d * 0.5 - 0.6), rr)
	var yaw := rad_to_deg(n.rotation.y)
	for e: Array in K.building_stats(folder).get("doors_front", []):
		if String(e[0]) != "rollup": continue
		var c: Vector2 = p.call(float(e[1]), d * 0.5 + 3.0)
		W.oil(dec, rr, c, yaw, S.walk_y, 0.95)
		dec.add(8, p.call(float(e[1]) - 1.0, d * 0.5 + 5.0), yaw + rr.randf_range(-8, 8), 0.8, 7.0, S.walk_y, Color(1, 1, 1, 0.55))
		dec.add(8, p.call(float(e[1]) + 1.0, d * 0.5 + 5.0), yaw + rr.randf_range(-8, 8), 0.8, 7.0, S.walk_y, Color(1, 1, 1, 0.55))

## general yard ageing over a rectangle (quadrant-local u, v): cracks (half sealed), dark trench patches, pale concrete
## repairs, oil drips scattered where vehicles stood, grime puddle stains where water sits
static func yard_wear(dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float, u0: float, v0: float, u1: float, v1: float, density := 1.0) -> void:
	var area := absf((u1 - u0) * (v1 - v0))
	var n := int(area / 35.0 * density)
	var a := Vector2(sx * u0, sz * v0); var b := Vector2(sx * u1, sz * v1)
	W.cracks(dec, rr, minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), n, S.walk_y, 0.45)
	var rp := func() -> Vector2: return Vector2(rr.randf_range(minf(a.x, b.x), maxf(a.x, b.x)), rr.randf_range(minf(a.y, b.y), maxf(a.y, b.y)))
	for k in int(n * 0.3): dec.add(2 + k % 2, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.5, 6.0), rr.randf_range(1.5, 4.0), S.walk_y, Color(1, 1, 1, 0.9))
	# pale concrete repairs, tinted to weathered grey: untinted they read as white squares on dark asphalt
	for k in int(n * 0.15): dec.add(4 + k % 2, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.0, 4.0), rr.randf_range(2.0, 4.0), S.walk_y, Color(0.5, 0.49, 0.47, 0.75))
	for k in int(n * 0.5): W.oil(dec, rr, rp.call(), rr.randf_range(0, 180), S.walk_y, rr.randf_range(0.5, 0.9))
	for k in int(n * 0.25): dec.add(14, rp.call(), rr.randf_range(0, 180), rr.randf_range(2.0, 5.0), rr.randf_range(2.0, 5.0), S.walk_y, Color(1, 1, 1, rr.randf_range(0.4, 0.7)))

## a truck path from a driveway into the yard: two tyre lines (tile 8), with oil where trucks stop
static func truck_path(dec: K.Decals, rr: RandomNumberGenerator, a: Vector2, b: Vector2) -> void:
	var L := a.distance_to(b); var dir := (b - a) / maxf(L, 0.01); var side := Vector2(-dir.y, dir.x)
	var yaw := rad_to_deg(atan2(dir.x, dir.y))
	var s := 0.0
	while s < L:
		var seg := minf(6.0, L - s)
		for o: float in [-1.0, 1.0]:
			dec.add(8, a + dir * (s + seg * 0.5) + side * o * 1.0, yaw + rr.randf_range(-4, 4), 0.7, seg, S.walk_y, Color(1, 1, 1, rr.randf_range(0.4, 0.6)))
		s += seg
	W.oil(dec, rr, b, yaw, S.walk_y, 0.9)

## the kind of clutter that collects by a working back door: bins, a pallet of gas cylinders, cones, a broken barrier
static func back_door_clutter(props: K.Props, rr: RandomNumberGenerator, at: Vector3, yaw: float, kind := "shop") -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var put := func(base: String, cond: String, lx: float, lz: float, dyaw := 0.0) -> void:
		add(props, base, cond, at + b * Vector3(lx, 0, lz), yaw + dyaw)
	match kind:
		"shop":
			put.call("prop_dumpster_3yd_green" if rr.randf() < 0.5 else "prop_dumpster_3yd_blue", "rusty", 0.0, 0.0)
			put.call("prop_trash_cart_black", "worn", 2.2, 0.2, rr.randf_range(-20, 20))
			put.call("prop_cone_28in", "dirty", -1.9, 0.6, rr.randf_range(0, 90))
		"yard":
			put.call("prop_dumpster_rolloff_20yd", "rusty", 0.0, 0.0)
			put.call("prop_channelizer_drum", "dirty", 3.6, -1.0)
			put.call("prop_channelizer_drum", "dirty", 4.4, 0.0)
			put.call("prop_water_barrier_orange", "dirty", -4.2, 0.5, rr.randf_range(-20, 20))
		"gas":
			for k in 4: put.call("prop_propane_cylinder_100lb", "rusty", k * 0.45, 0.0)
			put.call("prop_trash_cart_blue", "worn", 2.6, 0.0)

## sidewalk furniture that belongs to a frontage business (reuse rule: it lives in the block piece, not the street
## piece): s = position along the frontage, on the sidewalk 1 m in from the kerb, facing the street
static func walk_prop(props: K.Props, sx: float, sz: float, axis: String, s: float, base: String, cond := "worn") -> void:
	var off := KERB + 1.0
	if axis == "x": add(props, base, cond, Vector3(sx * s, S.walk_y(0.0), sz * off), 0.0 if sz > 0.0 else 180.0)
	else: add(props, base, cond, Vector3(sx * off, S.walk_y(0.0), sz * s), 90.0 if sx > 0.0 else -90.0)
