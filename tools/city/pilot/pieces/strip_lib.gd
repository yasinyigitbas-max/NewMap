extends RefCounted
## Commercial strip sample helpers (j_strip, s_strip_art, s_strip_side, m_ne / m_nw / m_se / m_sw, w_strip).
## Frame: the junction centre. The ARTERIAL runs along x (4 lanes + a centre two-way left-turn lane + bike lanes,
## palm parkway, narrow sidewalk: built for cars, the strip's whole character). The SIDE STREET runs along z
## (1+1 lanes, parallel parking, 3 m sidewalk). Flat ground. Lots: buildings set BACK behind their parking, as on a real
## car-oriented strip; pads on the corners (gas, fast food, bank, coffee) where drivers see them from both streets.
## Quadrant coordinates: u = |x| (along the arterial), v = |z| (along the side street), both from the junction.
## Parking stalls are stored on the piece (meta "stalls": [x, z, yaw_deg] per stall) so the game's parked-car layer can
## fill them later; the preview draws cars on ~3 in 4 of them.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")

# arterial cross-section (half widths, from the centre line)
const TL := 1.8          # centre two-way left-turn lane, half width
const L1 := 5.3          # inner through lane outer edge
const L2 := 8.8          # outer through lane outer edge
const KERB_A := 10.3     # kerb (bike lane 8.8 - 10.3)
const PKW := 12.3        # palm parkway 10.3 - 12.3
const PROP_A := 14.3     # sidewalk 12.3 - 14.3, then the lots
# side street
const LANE_S := 3.3
const KERB_S := 5.7      # parking lane 3.3 - 5.7
const PROP_S := 8.7      # sidewalk 5.7 - 8.7
const R := 8.0           # kerb return radius
const JX := 22.0         # junction tile: |x| <= JX along the arterial
const JZ := 26.0         # and |z| <= JZ along the side street
const XW_A := [14.2, 17.2]   # crosswalk across the arterial, |x| range
const STOP_A := [18.4, 19.0] # stop bars on the arterial approaches, |x|
const XW_S := [18.8, 21.8]   # crosswalk across the side street, |z| range
const STOP_S := [23.0, 23.6]
const LEN := 100.0
const APR_A := [45.0, 80.0]  # driveway aprons on the arterial legs (centres, |x|), 9 m wide
const APR_S := [45.0, 80.0]  # on the side street legs (|z|), 7 m wide
const APR_A_W := 9.0
const APR_S_W := 7.0
const STALL_W := 2.7
const STALL_D := 5.5
const AISLE := 7.0

static func q(sx: float, sz: float, u: float, v: float, y := 0.0) -> Vector3:
	return Vector3(sx * u, S.walk_y(0.0) + y, sz * v)

## world rect [x0, z0, x1, z1, mat] from quadrant u/v ranges
static func rect(sx: float, sz: float, u0: float, v0: float, u1: float, v1: float, mat: String) -> Array:
	var a := Vector2(sx * u0, sz * v0); var b := Vector2(sx * u1, sz * v1)
	return [minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), mat]

## A row of 90-degree stalls side by side along u (n stalls from u0), their depth along v from v_edge (the aisle
## edge) going `dir` (+1 = to larger v). Paints the stall lines, records the stalls (cars nose in, away from the aisle).
static func stalls_u(paints: Array, stalls: Array, sx: float, sz: float, u0: float, n: int, v_edge: float, dir: float) -> void:
	var v1 := v_edge + dir * STALL_D
	for k in n + 1:
		var u := u0 + k * STALL_W
		paints.append(rect(sx, sz, u - 0.05, minf(v_edge, v1), u + 0.05, maxf(v_edge, v1) - 0.3, "white"))
	for k in n:
		var c := Vector2(sx * (u0 + (k + 0.5) * STALL_W), sz * (v_edge + dir * STALL_D * 0.5))
		stalls.append([c.x, c.y, 0.0 if sz * dir > 0.0 else 180.0])

## same with the stalls side by side along v, depth along u
static func stalls_v(paints: Array, stalls: Array, sx: float, sz: float, v0: float, n: int, u_edge: float, dir: float) -> void:
	var u1 := u_edge + dir * STALL_D
	for k in n + 1:
		var v := v0 + k * STALL_W
		paints.append(rect(sx, sz, minf(u_edge, u1), v - 0.05, maxf(u_edge, u1) - 0.3, v + 0.05, "white"))
	for k in n:
		var c := Vector2(sx * (u_edge + dir * STALL_D * 0.5), sz * (v0 + (k + 0.5) * STALL_W))
		stalls.append([c.x, c.y, 90.0 if sx * dir > 0.0 else -90.0])

## oil under the stalls cars use most (the ones nearest the door), a few cracks in the aisles: lots age from the door out
static func stall_wear(dec: K.Decals, rr: RandomNumberGenerator, stalls: Array, share := 0.6) -> void:
	for s: Array in stalls:
		if rr.randf() < share: W.oil(dec, rr, Vector2(float(s[0]), float(s[1])), float(s[2]), S.walk_y, rr.randf_range(0.5, 0.9))

## a dumpster enclosure: CMU walls on three sides (open toward `yaw`), two dumpsters inside (trash + recycling)
static func enclosure(props: K.Props, at: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	for lx: float in [-2.03, 0.0, 2.03]:
		I.add(props, "fence_cmu_wall", "worn", at + b * Vector3(lx, 0, -1.6), yaw)
	for side: float in [-1.0, 1.0]:
		I.add(props, "fence_cmu_wall", "worn", at + b * Vector3(side * 3.15, 0, -0.55), yaw + 90.0)
		I.add(props, "fence_cmu_wall", "worn", at + b * Vector3(side * 3.15, 0, 1.45), yaw + 90.0)
	I.add(props, "prop_dumpster_3yd_green", "rusty", at + b * Vector3(-1.2, 0, 0.0), yaw)
	I.add(props, "prop_dumpster_3yd_blue", "rusty", at + b * Vector3(1.2, 0, 0.0), yaw)

## the overflow that always sits outside an enclosure: a flattened-box pile is not in the kit, so a cart and a cone
static func enclosure_mess(props: K.Props, rr: RandomNumberGenerator, at: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	I.add(props, "prop_trash_cart_black", "worn", at + b * Vector3(3.9, 0, 2.6), yaw + rr.randf_range(-25, 25))
	I.add(props, "prop_cone_28in", "dirty", at + b * Vector3(-3.9, 0, 2.8), rr.randf_range(0, 90))

## lot light pole on a small concrete base (overhead part: the validator checks its post only)
static func lot_light(props: K.Props, sx: float, sz: float, u: float, v: float, yaw := 0.0) -> void:
	I.add(props, "prop_lot_light_pole", "worn", q(sx, sz, u, v), yaw)

## a planted island (grass paint) with a palm or two and low shrubs at its ends
static func island(paints: Array, props: K.Props, rr: RandomNumberGenerator, sx: float, sz: float, u0: float, v0: float, u1: float, v1: float, palms := 1) -> void:
	paints.append(rect(sx, sz, u0, v0, u1, v1, "grass"))
	var long_u := absf(u1 - u0) > absf(v1 - v0)
	if palms == 0:
		return     # a light island: grass only, the lot light stands in its middle
	for k in palms:
		var t := (k + 1.0) / (palms + 1.0)
		var uu := lerpf(u0, u1, t) if long_u else (u0 + u1) * 0.5
		var vv := (v0 + v1) * 0.5 if long_u else lerpf(v0, v1, t)
		I.add(props, ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"][rr.randi() % 3], "normal", q(sx, sz, uu, vv), rr.randf_range(0, 360))
	var ends: Array = [[u0 + 0.9, (v0 + v1) * 0.5], [u1 - 0.9, (v0 + v1) * 0.5]] if long_u else [[(u0 + u1) * 0.5, v0 + 0.9], [(u0 + u1) * 0.5, v1 - 0.9]]
	for e: Array in ends:
		I.add(props, "plant_agave_americana_small" if rr.randf() < 0.5 else "plant_bird_of_paradise", "normal", q(sx, sz, float(e[0]), float(e[1])), rr.randf_range(0, 360))

static func finish(root: Node3D, g: K.Ground, props: K.Props, dec: K.Decals, name: String, stalls: Array) -> void:
	root.set_meta("stalls", stalls)
	if name.begins_with("m_"): wheel_stops(props, W.rng_for(name + "_ws"), stalls)   # kit batch 2 (17 Nov)
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d, buildings %d, stalls %d" % [name, g.tri_count(), props.count(), root.get_node("Buildings").get_child_count() if root.has_node("Buildings") else 0, stalls.size()])
	K.save_piece(root, name)

## ---------------------------------------------------------------- polish (Yasin 16 Nov: "more relevant props and polish")
## storm drain grates in a lot (every lot drains to a few low points in its aisles)
static func drains(props: K.Props, sx: float, sz: float, pts: Array) -> void:
	for p: Vector2 in pts:
		props.add("prop_storm_drain_grate", "dirty", q(sx, sz, p.x, p.y, 0.002), 0.0, false)

## bollards (concrete in front of shop doors against cars nosing in; steel round gas / propane)
static func bollards(props: K.Props, sx: float, sz: float, pts: Array, kind := "prop_bollard_concrete") -> void:
	for p: Vector2 in pts: I.add(props, kind, "worn", q(sx, sz, p.x, p.y), 0.0)

## a painted crossing over a lot drive lane: bars parallel to the traffic (along u), u0..u1, stepping across v0..v1
static func crossing(paints: Array, sx: float, sz: float, u0: float, u1: float, v0: float, v1: float) -> void:
	var v := v0 + 0.3
	while v + 0.5 <= v1 - 0.2:
		paints.append(rect(sx, sz, u0, v, u1, v + 0.5, "white")); v += 1.0

## an aisle's life: polished wheel paths down its middle and turning marks at both ends (cars swing into the stalls)
static func aisle_wear(dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float, u0: float, u1: float, v: float) -> void:
	var u := u0 + 1.0
	while u < u1 - 2.0:
		var Ls := minf(rr.randf_range(4.0, 7.0), u1 - 1.0 - u)
		for o: float in [-0.9, 0.9]:
			dec.add(14, Vector2(sx * (u + Ls * 0.5), sz * (v + o)), 90.0, 0.6, Ls, S.walk_y, Color(1, 1, 1, 0.3))
		u += Ls + rr.randf_range(1.0, 3.0)
	for e: float in [u0 + 2.0, u1 - 2.0]:
		dec.add(8, Vector2(sx * e, sz * v), rr.randf_range(30, 60), 0.6, 5.0, S.walk_y, Color(1, 1, 1, 0.45))

## a pylon sign in the arterial planting strip at u, facing the arterial (drivers read it from the road)
static func pylon(props: K.Props, sx: float, sz: float, u: float) -> void:
	I.add(props, "prop_pylon_sign", "worn", q(sx, sz, u, 15.95), 0.0 if sz < 0.0 else 180.0)

## wheel stops at the head of recorded lot stalls (17 Nov, kit batch 2): concrete in old lots, rubber in new ones;
## one in five cracked out of line (dirty). stalls: [x, z, yaw_deg] with the car facing +Z turned by yaw.
static func wheel_stops(props: K.Props, rr: RandomNumberGenerator, stalls: Array, kind := "prop_wheel_stop_concrete") -> void:
	for st: Array in stalls:
		var yaw := float(st[2])
		var fwd := Vector3(sin(deg_to_rad(yaw)), 0.0, cos(deg_to_rad(yaw)))
		var p := Vector3(float(st[0]), S.walk_y(0.0) + 0.002, float(st[1])) + fwd * (STALL_D * 0.5 - 0.55)
		var off := rr.randf() < 0.2
		I.add(props, kind, "dirty" if off else "worn", p, yaw + (rr.randf_range(-12, 12) if off else 0.0), false)
