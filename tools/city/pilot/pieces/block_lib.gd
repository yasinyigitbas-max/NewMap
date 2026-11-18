extends RefCounted
## Helpers for the downtown block pieces (b_nw, b_ne, b_se, b_sw). Each block script lists its buildings and
## furniture by hand; this file only turns "front on Amber at the building line, from z0 to z1" into a transform.

const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")

## wear marks of the block being built (begin() starts them, rear_lot / alley add to them, finish() draws them)
static var dec: K.Decals = null
static var rr: RandomNumberGenerator = null
static var _pots: Array = []
static func begin(name: String) -> void:
	dec = K.Decals.new(); rr = W.rng_for(name); _pots = []

## potted plants either side of the doors of a placed building (cafes, bakeries, bars: places that dress their front)
static func door_pots(props: K.Props, node: Node3D, folder: String) -> void:
	var st := K.building_stats(folder)
	var d: float = st.footprint_wd[1]
	for e: Array in st.get("doors_front", []):
		if not String(e[0]).begins_with("shopdoor") and not String(e[0]).begins_with("apt_door"): continue
		for side: float in [-1.0, 1.0]:
			var p: Vector3 = node.transform * Vector3(float(e[1]) + side * 1.15, 0.0, d * 0.5 + 0.35)
			var taken := false
			for q0: Vector3 in _pots:
				if q0.distance_to(p) < 1.0: taken = true      # two doors share the gap: one pot is enough
			if taken: continue
			_pots.append(p)
			props.add("plant_potted_succulent", "normal", Vector3(p.x, S.walk_y(p.x), p.z), 0.0)
		# people stand and wait at the door: scuffed paving
		var q: Vector3 = node.transform * Vector3(float(e[1]), 0.0, d * 0.5 + 1.0)
		if dec: dec.add(14, Vector2(q.x, q.z), rad_to_deg(node.rotation.y), 2.2, 1.6, S.walk_y, Color(1, 1, 1, 0.45))

## Kit buildings face +Z. Facing a street: +X (west side of Amber) yaw 90, -X yaw -90, +Z yaw 0, -Z yaw 180.
## Places a building whose FRONT lies on the line x = front_x (Amber frontage), spanning z from za to zb.
## Returns [node, width, depth]. Width = stats footprint w (along the front), depth = d.
static func on_amber(parent: Node3D, folder: String, side: float, front_x: float, za: float, label := "") -> Array:
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var zc := za + signf(za) * w * 0.5 if za != 0.0 else w * 0.5
	var xc := front_x + side * d * 0.5
	var y := S.walk_y(xc)
	var node := K.building(parent, folder, Vector3(xc, y, zc), 90.0 if side < 0 else -90.0, label)
	return [node, w, d]

## Building whose front lies on the line z = front_z (10th St frontage), centred at x = xc. facing = +1 (south) / -1 (north).
static func on_tenth(parent: Node3D, folder: String, facing: float, front_z: float, xc: float, label := "") -> Array:
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var zc := front_z - facing * d * 0.5
	var node := K.building(parent, folder, Vector3(xc, S.walk_y(xc), zc), 0.0 if facing > 0 else 180.0, label)
	return [node, w, d]

## Door positions of a placed building in piece coordinates (for checks: nothing may stand in front of a door).
static func doors(node: Node3D, folder: String) -> Array:
	var out: Array = []
	var st := K.building_stats(folder)
	var d: float = st.footprint_wd[1]
	for e: Array in st.get("doors_front", []):
		var local := Vector3(float(e[1]), 0.0, d * 0.5)
		out.append([String(e[0]), node.transform * local])
	return out

## Rear service lot between building backs and the alley: asphalt at walk level with perpendicular stalls
## (2.7 m wide, 5.0 m long) along the alley edge, every stall line painted. x0..x1 is the lot, alley on the x1 side.
static func rear_lot(g: K.Ground, x0: float, x1: float, z0: float, z1: float, stalls := true) -> void:
	var paint: Array = []
	if stalls and absf(x1 - x0) > 11.0:
		var sx := signf(x1 - x0)
		var lx0 := x1 - sx * 5.0
		var z := minf(z0, z1) + 1.5
		while z <= maxf(z0, z1) - 1.5:
			paint.append([minf(lx0, x1), z - 0.05, maxf(lx0, x1), z + 0.05, "white"]); z += 2.7
	K.painted_rect(g, minf(x0, x1), minf(z0, z1), maxf(x0, x1), maxf(z0, z1), paint, S.walk_y)
	if dec == null: return
	# ageing: oil in most stalls (people park here every day), cracks, a patch, tyre marks where cars swing in
	if stalls and absf(x1 - x0) > 11.0:
		var sx2 := signf(x1 - x0)
		var z := minf(z0, z1) + 1.5 + 1.35
		while z <= maxf(z0, z1) - 2.8:
			if rr.randf() < 0.6: W.oil(dec, rr, Vector2(x1 - sx2 * 2.6, z), 90.0, S.walk_y, 0.7)
			z += 2.7
		for k in 3: dec.add(8, Vector2(x1 - sx2 * rr.randf_range(6.0, 8.0), rr.randf_range(minf(z0, z1) + 3.0, maxf(z0, z1) - 3.0)), rr.randf_range(-30, 30), 0.5, 7.0, S.walk_y, Color(1, 1, 1, 0.35))
	W.cracks(dec, rr, minf(x0, x1) + 1.0, minf(z0, z1) + 1.0, maxf(x0, x1) - 1.0, maxf(z0, z1) - 1.0, int(absf((x1 - x0) * (z1 - z0)) / 160.0) + 1, S.walk_y, 0.35)

## The 6 m service alley (asphalt, flush at walk level; the 10th St pieces drop it to the street with an apron).
static func alley(g: K.Ground, x0: float, x1: float, z0: float, z1: float) -> void:
	g.rect("asphalt", minf(x0, x1), minf(z0, z1), maxf(x0, x1), maxf(z0, z1), S.walk_y)
	if dec == null: return
	# ageing: an old alley: many cracks, two trench patches, dirt along the middle where the water runs
	var xc := (x0 + x1) * 0.5
	W.lane_wear(dec, rr, xc, z0, z1, true, S.walk_y)
	W.cracks(dec, rr, minf(x0, x1) + 0.6, minf(z0, z1) + 1.0, maxf(x0, x1) - 0.6, maxf(z0, z1) - 1.0, int(absf(z1 - z0) / 8.0), S.walk_y, 0.3)
	for k in 2: dec.add(2 + k, Vector2(xc + rr.randf_range(-1.0, 1.0), rr.randf_range(minf(z0, z1) + 5.0, maxf(z0, z1) - 5.0)), 90.0, 2.4, 3.5, S.walk_y, Color(1, 1, 1, 0.85))
	var z2 := minf(z0, z1) + 2.0
	while z2 < maxf(z0, z1) - 2.0:
		dec.add(14, Vector2(xc, z2), 0.0, 1.0, 3.0, S.walk_y, Color(1, 1, 1, 0.5)); z2 += rr.randf_range(5.0, 9.0)

static func finish(root: Node3D, g: K.Ground, props: K.Props, name: String) -> void:
	if dec:
		# grime and drips under every dumpster and bin (they leak, people miss them)
		for k: String in props.items:
			if k.contains("dumpster") or k.contains("recycling") or k.contains("trash_cart"):
				for t: Transform3D in props.items[k]:
					dec.add(14, Vector2(t.origin.x, t.origin.z), rad_to_deg(t.basis.get_euler().y), 3.0 if k.contains("dumpster") else 1.4, 2.4 if k.contains("dumpster") else 1.2, S.walk_y, Color(1, 1, 1, 0.7))
		var wm := dec.build()
		if wm: root.add_child(wm)
		dec = null
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d, buildings %d" % [name, g.tri_count(), props.count(), root.get_node("Buildings").get_child_count() if root.has_node("Buildings") else 0])
	K.save_piece(root, name)
