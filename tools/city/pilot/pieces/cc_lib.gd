extends RefCounted
## City centre sample helpers (c_nw, c_ne, c_se, c_sw). Flat ground (S.hill_on = false), whole-block street walls,
## the alley side built up too, service courts instead of open parking, wires underground (substation boxes, no poles).
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const B := preload("res://tools/city/pilot/pieces/block_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")

## the whole quadrant floor at walk level: asphalt service courts by default, `paints` = [x0, z0, x1, z1, mat] areas
## (plaza paving, construction dirt, garden lawn) cut into the same plane; plus the alley; plus wear
static func floor(g: K.Ground, sx: float, sz: float, paints: Array) -> void:
	var x0 := sx * S.A_BLD; var x1 := sx * S.ALLEY_E[0]; var z0 := sz * S.T_BLD; var z1 := sz * 97.5
	K.painted_rect(g, minf(x0, x1), minf(z0, z1), maxf(x0, x1), maxf(z0, z1), paints, S.walk_y)
	B.alley(g, sx * S.ALLEY_E[0], sx * S.ALLEY_E[1], z0, z1)
	# the centre's courts and alley take the hardest use: delivery trucks idle, bins drip, nobody sweeps behind
	W.cracks(B.dec, B.rr, minf(x0, x1) + 1.0, minf(z0, z1) + 1.0, maxf(x0, x1) - 1.0, maxf(z0, z1) - 1.0, 16, S.walk_y, 0.45)
	var xa := sx * (S.ALLEY_E[0] + S.ALLEY_E[1]) * 0.5
	var z := minf(z0, z1) + 4.0
	while z < maxf(z0, z1) - 4.0:
		W.oil(B.dec, B.rr, Vector2(xa, z), 0.0, S.walk_y, 0.8)
		B.dec.add(14, Vector2(sx * (S.ALLEY_E[0] - 0.6), z + 3.0), 0.0, 1.2, 4.0, S.walk_y, Color(1, 1, 1, 0.65))
		z += B.rr.randf_range(6.0, 10.0)
	for k in 3: B.dec.add(2 + k % 2, Vector2(xa, B.rr.randf_range(minf(z0, z1) + 6.0, maxf(z0, z1) - 6.0)), 90.0, 2.6, 3.4, S.walk_y, Color(1, 1, 1, 0.9))

## Back-of-house life on a placed building's rear wall (the side nobody designs, and the side that shows a city is
## used): an electric meter bank and a gas meter on the wall, AC condensers on the ground, bin carts for residents.
## at_front: the building's back touches another building (alley rows): its services go on the alley-facing front
static func back_of_house(props: K.Props, node: Node3D, folder: String, residential := false, at_front := false) -> void:
	var st := K.building_stats(folder)
	if st.is_empty(): return
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var yaw := rad_to_deg(node.rotation.y) + (0.0 if at_front else 180.0)
	var zs := -1.0 if at_front else 1.0       # flips "behind the back wall" to "in front of the front wall"
	var at := func(lx: float, ly: float, lz: float) -> Vector3:
		var p: Vector3 = node.transform * Vector3(lx, 0.0, lz * zs)
		return Vector3(p.x, S.walk_y(0.0) + ly, p.z)
	var x0 := -w * 0.5 + 1.6
	for k in 3: props.add("prop_meter_electric", "worn", at.call(x0 + k * 0.42, 1.05, -d * 0.5 - 0.02), yaw)
	props.add("prop_meter_gas", "rusty", at.call(x0 + 1.7, 0.2, -d * 0.5 - 0.02), yaw)
	var n_ac := 1 if w < 14.0 else 2
	for k in n_ac: props.add("prop_ac_condenser", "worn", at.call(x0 + 3.4 + k * 1.3, 0.0, -d * 0.5 - 0.75), yaw)
	if residential:
		for k in 3: props.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", at.call(w * 0.5 - 1.5 - k * 0.8, 0.0, -d * 0.5 - 0.75), yaw)

## a straight run of temporary construction fence (3.3 m screened panels on stands) from a to b
static func site_fence(props: K.Props, a: Vector2, b: Vector2) -> void:
	var L := a.distance_to(b); var n := maxi(1, int(round(L / 3.3)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	for i in n:
		var m := a.lerp(b, (i + 0.5) / n)
		props.add("fence_temp_fence_panel_screen", "worn", Vector3(m.x, S.walk_y(0.0), m.y), yaw)

## facing for a building whose front is on Amber at side sx: yaw 90 (west side faces +x) / -90
static func amber_yaw(sx: float) -> float: return 90.0 if sx < 0 else -90.0
