extends SceneTree
## Piece b_sw: downtown block west of Amber, south of 10th (x -50..-16, z 9.7..97.5). Run once; never when locked.
## The corner is a pocket park (26.5 m): bandstand facing the junction, a ring path with benches facing it, globe
## lamps, magnolias, a low hedge (under 1 m, keeps the corner open to view), drinking fountain, paths from the corner,
## from Amber and from 10th. Then the bistro (set back 3 m for its terrace tables), a mixed-use stucco block (shops +
## flats), and the hotel tower. Behind: parking, dumpsters behind the bistro and the hotel kitchen.
const B := preload("res://tools/city/pilot/pieces/block_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const PARK_Z1 := 36.2
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var root := Node3D.new(); root.name = "b_sw"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	B.begin(root.name)
	var g := K.Ground.new(); var props := K.Props.new()
	# ---- pocket park: x -44..-16, z 9.7..36.2
	var c := Vector2(-30.0, (S.T_BLD + PARK_Z1) * 0.5)
	_park(g, props, c)
	# ---- buildings
	var bis := B.on_amber(bl, "commercial/com_bistro", -1.0, -S.A_BLD - 3.0, PARK_Z1)
	props.add("plant_potted_succulent", "normal", Vector3(-S.A_BLD - 2.65, S.walk_y(0.0), 40.1), 0.0)   # one pot by the bistro door (the other side is the park fence)
	var z := PARK_Z1 + float(bis[1])
	for f: String in ["apartments/apt_stucco3_cream", "urban/twr_hotel"]:
		var r := B.on_amber(bl, f, -1.0, -S.A_BLD, z)
		z += float(r[1])
	# bistro terrace (3 m, paved) with tables away from its door (door is at the park end)
	g.rect("paving", -S.A_BLD - 3.0, PARK_Z1, -S.A_BLD, PARK_Z1 + float(bis[1]), S.walk_y)
	for tz: float in [42.4, 46.4]:
		props.add("prop_patio_set_4", "worn", Vector3(-S.A_BLD - 1.5, S.walk_y(0.0), tz), 0.0)
	props.add("plant_potted_succulent", "normal", Vector3(-S.A_BLD - 0.4, S.walk_y(0.0), PARK_Z1 + float(bis[1]) - 0.6), 0.0)
	# ---- rear lot, alley, back of house
	B.rear_lot(g, -S.A_BLD - 3.0 - float(bis[2]), S.ALLEY_W[1], PARK_Z1, PARK_Z1 + float(bis[1]), false)
	B.rear_lot(g, -S.A_BLD, S.ALLEY_W[1], PARK_Z1 + float(bis[1]), 97.5)
	B.alley(g, S.ALLEY_W[0], S.ALLEY_W[1], S.T_BLD, 97.5)
	props.add("prop_dumpster_3yd_green", "worn", Vector3(-38.5, S.walk_y(0.0), 44.0), -90.0)     # bistro
	props.add("prop_dumpster_3yd_green", "worn", Vector3(-36.5, S.walk_y(0.0), 80.0), -90.0)     # hotel kitchen
	props.add("prop_dumpster_3yd_blue", "worn", Vector3(-36.5, S.walk_y(0.0), 83.0), -90.0)
	for zp: float in [20.0, 53.0, 86.0]:
		props.add("prop_utility_pole_transformer" if zp == 86.0 else "prop_utility_pole", "worn", Vector3(S.ALLEY_W[1] - 0.4, S.walk_y(0.0), zp), 0.0)
	B.finish(root, g, props, "b_sw")
	quit()

func _park(g: K.Ground, props: K.Props, c: Vector2) -> void:
	# Yasin 16 Nov: no jagged path edges, a fence around the park, the hedge closed with ONE clear entrance, grass
	# tufts, and signs that people use it. Exact shapes (no grid): plaza disc, planted ring, paved ring path, one
	# entrance path from the corner that faces the junction (where everyone arrives from), lawn = everything else.
	var x0 := -44.0; var x1 := -S.A_BLD; var z0 := S.T_BLD; var z1 := PARK_Z1
	var R_PLAZA := 7.0; var R_BED := 9.0; var R_RING := 11.4; var H := 1.2
	var gate := Vector2(x1, z0)                          # the corner at the junction
	var dir := (gate - c).normalized(); var nrm := Vector2(-dir.y, dir.x)
	var rect := [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
	var ang := func(p: Vector2) -> float: return atan2(p.y - c.y, p.x - c.x)
	var on_circle := func(r: float, side: float) -> Vector2: return c + dir * sqrt(r * r - H * H) + nrm * H * side
	var arc_pts := func(r: float, a0: float, a1: float, step_deg := 4.0) -> PackedVector2Array:
		var out := PackedVector2Array()
		var n := maxi(2, int(ceil(absf(a1 - a0) / deg_to_rad(step_deg))))
		for i in n + 1: out.append(c + Vector2(cos(lerpf(a0, a1, float(i) / n)), sin(lerpf(a0, a1, float(i) / n))) * r)
		return out
	var wy := S.walk_y
	# angles of the path edges on each circle (left edge = +nrm side); the lawn / bed wrap from left round to right
	var a_l := func(r: float) -> float: return ang.call(on_circle.call(r, 1.0))
	var a_r := func(r: float) -> float:
		var a: float = ang.call(on_circle.call(r, -1.0))
		var l: float = a_l.call(r)
		while a <= l: a += TAU
		return a
	# 1) plaza
	g.poly("paving", arc_pts.call(R_PLAZA, 0.0, TAU * 0.999, 6.0), wy)
	# 2) planted bed ring (mulch) between plaza and ring path, cut by the entrance path
	var bed: PackedVector2Array = arc_pts.call(R_BED, a_l.call(R_BED), a_r.call(R_BED))
	var inner: PackedVector2Array = arc_pts.call(R_PLAZA, a_l.call(R_PLAZA), a_r.call(R_PLAZA)); inner.reverse()
	bed.append_array(inner); g.poly("mulch", bed, wy)
	# 3) ring path
	var ring: PackedVector2Array = arc_pts.call(R_RING, 0.0, TAU, 3.0); var ring_in: PackedVector2Array = arc_pts.call(R_BED, 0.0, TAU, 3.0)
	for i in ring.size() - 1:
		var a := ring_in[i]; var b := ring_in[i + 1]; var cc := ring[i + 1]; var d := ring[i]
		g.quad("paving", Vector3(a.x, wy.call(a.x, a.y), a.y), Vector3(b.x, wy.call(b.x, b.y), b.y), Vector3(cc.x, wy.call(cc.x, cc.y), cc.y), Vector3(d.x, wy.call(d.x, d.y), d.y))
	# 4) entrance path: from the plaza edge to the gate corner (two straight edges, ends on the circles)
	var ent := PackedVector2Array()
	ent.append_array(arc_pts.call(R_PLAZA, a_r.call(R_PLAZA) - TAU, a_l.call(R_PLAZA), 4.0))
	ent.append(_ray_rect(on_circle.call(R_PLAZA, 1.0), dir, x0, x1, z0, z1))
	ent.append(gate)
	ent.append(_ray_rect(on_circle.call(R_PLAZA, -1.0), dir, x0, x1, z0, z1))
	g.poly("paving", ent, wy)
	# 5) lawn: from the path's left edge on the ring, round the ring to its right edge, out along the right edge to
	#    the boundary, round the boundary corners back to the left edge
	var lawn: PackedVector2Array = arc_pts.call(R_RING, a_l.call(R_RING), a_r.call(R_RING))
	var qr: Vector2 = _ray_rect(on_circle.call(R_RING, -1.0), dir, x0, x1, z0, z1)
	var ql: Vector2 = _ray_rect(on_circle.call(R_RING, 1.0), dir, x0, x1, z0, z1)
	lawn.append(qr)
	var corners: Array = []
	for q: Vector2 in rect:
		if q.distance_to(gate) > 0.1: corners.append(q)
	var aq: float = ang.call(qr)
	# the lawn arc ran counter-clockwise from the left edge to the right edge: walk the boundary back clockwise
	corners.sort_custom(func(p: Vector2, q: Vector2) -> bool: return fposmod(aq - float(ang.call(p)), TAU) < fposmod(aq - float(ang.call(q)), TAU))
	for q: Vector2 in corners: lawn.append(q)
	lawn.append(ql)
	g.poly("grass", lawn, wy)
	# ---------------------------------------------------------------- enclosure: fence on the line, hedge just inside
	var gap := 3.2   # the gate opening each side of the corner (path is 2.4 wide, diagonal)
	_fence_run(props, Vector2(x1 - gap, z0 + 0.12), Vector2(x0 + 0.12, z0 + 0.12))   # along 10th
	_fence_run(props, Vector2(x0 + 0.12, z0 + 0.12), Vector2(x0 + 0.12, z1 - 0.12))   # alley side
	_fence_run(props, Vector2(x0 + 0.12, z1 - 0.12), Vector2(x1 - 0.12, z1 - 0.12))   # bistro side
	_fence_run(props, Vector2(x1 - 0.12, z1 - 0.12), Vector2(x1 - 0.12, z0 + gap))   # along Amber
	props.add("fence_gate_wrought_iron", "worn", Vector3(x1 - gap - 0.55, wy.call(0.0, 0.0), z0 + 0.12), 0.0)   # gate leaves stand open, swung back against the fence
	props.add("fence_gate_wrought_iron", "worn", Vector3(x1 - 0.12, wy.call(0.0, 0.0), z0 + gap + 0.55), 90.0)
	var hz := 0.9      # hedge line inset
	_hedge_run(props, Vector2(x1 - gap - 0.2, z0 + hz), Vector2(x0 + hz, z0 + hz))
	_hedge_run(props, Vector2(x0 + hz, z0 + hz + 1.0), Vector2(x0 + hz, z1 - hz))
	_hedge_run(props, Vector2(x0 + hz + 1.0, z1 - hz), Vector2(x1 - hz, z1 - hz))
	_hedge_run(props, Vector2(x1 - hz, z1 - hz - 1.0), Vector2(x1 - hz, z0 + gap + 0.2))
	# ---------------------------------------------------------------- what is inside
	props.add("prop_bandstand", "worn", Vector3(c.x, wy.call(0.0, 0.0), c.y), rad_to_deg(atan2(dir.x, dir.y)))
	# benches on the ring's outer edge facing the bandstand, none across the entrance path
	for a_deg: float in [100.0, 145.0, 190.0, 235.0, 280.0, 325.0]:
		var a := deg_to_rad(a_deg)
		var p2 := c + Vector2(sin(a), cos(a)) * (R_RING + 0.55)
		if (p2 - c).normalized().dot(dir) > 0.85: continue
		if p2.x < x0 + 2.2 or p2.x > x1 - 2.2 or p2.y < z0 + 2.2 or p2.y > z1 - 2.2: continue   # no room before the hedge
		props.add("prop_park_bench", "worn", Vector3(p2.x, wy.call(0.0, 0.0), p2.y), a_deg + 180.0)
	for a_deg: float in [80.0, 170.0, 260.0, 350.0]:
		var a2 := deg_to_rad(a_deg)
		var p3 := c + Vector2(sin(a2), cos(a2)) * (R_BED + 0.4)
		props.add("prop_lamp_globe", "worn", Vector3(p3.x, wy.call(0.0, 0.0), p3.y), 0.0)
	# planted bed: bird of paradise and agave in alternation round the bandstand, kept off the entrance
	for k in 12:
		var a3 := TAU * k / 12.0
		var p4 := c + Vector2(cos(a3), sin(a3)) * ((R_PLAZA + R_BED) * 0.5)
		if (p4 - c).normalized().dot(dir) > 0.8: continue
		props.add("plant_bird_of_paradise" if k % 2 == 0 else "plant_agave_americana", "normal", Vector3(p4.x, wy.call(0.0, 0.0), p4.y), k * 30.0, false)
	# shade trees in the lawn corners, a picnic table under the far one, a fountain and bins by the entrance
	for q: Vector2 in [Vector2(-40.0, 13.6), Vector2(-40.0, 32.3), Vector2(-20.2, 32.3)]:
		props.add("tree_magnolia_a" if q.y > 20.0 else "tree_magnolia_b", "normal", Vector3(q.x, wy.call(0.0, 0.0), q.y), q.x * 7.0)
	props.add("prop_picnic_table", "worn", Vector3(-37.0, wy.call(0.0, 0.0), 30.2), 40.0)
	var e1 := c + dir * (R_RING + 2.2) + nrm * 2.3
	var e2 := c + dir * (R_RING + 2.2) - nrm * 2.3
	props.add("prop_drinking_fountain", "worn", Vector3(e1.x, wy.call(0.0, 0.0), e1.y), rad_to_deg(atan2(-nrm.x, -nrm.y)))
	props.add("prop_trash_receptacle", "worn", Vector3(e2.x, wy.call(0.0, 0.0), e2.y), 0.0)
	props.add("prop_recycling_receptacle", "worn", Vector3(e2.x - nrm.x * 0.9, wy.call(0.0, 0.0), e2.y - nrm.y * 0.9), 0.0)
	# ---------------------------------------------------------------- lived in: worn grass where people walk and cut corners
	var rr := RandomNumberGenerator.new(); rr.seed = 1610
	var placed := 0; var tries := 0
	while placed < 46 and tries < 2000:
		tries += 1
		var p5 := Vector2(rr.randf_range(x0 + 1.5, x1 - 1.5), rr.randf_range(z0 + 1.5, z1 - 1.5))
		var r := p5.distance_to(c)
		if r < R_RING + 1.6: continue
		if absf((p5 - c).dot(nrm)) < H + 1.6 and (p5 - c).dot(dir) > 0.0: continue
		var worn := r < R_RING + 2.6 or absf((p5 - c).dot(nrm)) < H + 2.4
		if worn:   # trodden grass next to the paths: a soft brown wear mark, not a mat
			B.dec.add(14, p5, rr.randf_range(0, 360), rr.randf_range(1.6, 2.6), rr.randf_range(1.2, 2.0), wy, Color(0.78, 0.7, 0.48, 0.5))
		else:
			continue   # no grass tufts (Yasin: they look terrible); untrodden lawn stays plain
		placed += 1
	# the shortcut everyone takes from the entrance path onto the ring, both sides: worn grass, a desire line
	for side: float in [-1.0, 1.0]:
		var p6 := c + dir * (R_RING + 1.2) + nrm * side * (H + 1.0)
		B.dec.add(14, p6, rad_to_deg(atan2(dir.x, dir.y)) + side * 40.0, 1.2, 3.2, wy, Color(0.62, 0.52, 0.36, 0.75))
		B.dec.add(14, p6, 0.0, 2.4, 2.4, wy, Color(0.78, 0.7, 0.48, 0.5))

## ray from p (inside the rect) along d: where it leaves the rectangle
static func _ray_rect(p: Vector2, d: Vector2, x0: float, x1: float, z0: float, z1: float) -> Vector2:
	var t := 1e9
	if d.x > 1e-6: t = minf(t, (x1 - p.x) / d.x)
	if d.x < -1e-6: t = minf(t, (x0 - p.x) / d.x)
	if d.y > 1e-6: t = minf(t, (z1 - p.y) / d.y)
	if d.y < -1e-6: t = minf(t, (z0 - p.y) / d.y)
	return p + d * t

## 2 m wrought-iron panels from a to b with posts at both ends (a straight run along x or z)
static func _fence_run(props: K.Props, a: Vector2, b: Vector2) -> void:
	var L := a.distance_to(b); var n := maxi(1, int(round(L / 2.0)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	for i in n:
		var m := a.lerp(b, (i + 0.5) / n)
		props.add("fence_wrought_iron", "worn", Vector3(m.x, S.walk_y(0.0), m.y), yaw)
	for e: Vector2 in [a, b]:
		props.add("fence_post_wrought_iron", "worn", Vector3(e.x, S.walk_y(0.0), e.y), 0.0)

## 2 m boxwood hedge panels from a to b
static func _hedge_run(props: K.Props, a: Vector2, b: Vector2) -> void:
	var L := a.distance_to(b); var n := maxi(1, int(floor(L / 2.0)))
	var yaw := rad_to_deg(atan2(b.x - a.x, b.y - a.y)) + 90.0
	for i in n:
		var m := a.lerp(b, (i + 0.5) / n)
		props.add("hedge_boxwood_low_2m", "normal", Vector3(m.x, S.walk_y(0.0), m.y), yaw)

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a; var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
