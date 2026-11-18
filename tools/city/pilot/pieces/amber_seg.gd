extends RefCounted
## Builds one Amber Ave street piece (one leg of the junction): median, 2+2 lanes, parking, sidewalks to the building
## lines, and the street furniture. Used by s_amber_n.gd and s_amber_s.gd, each with its own frontage list.
## sz = -1 north leg (z from -17.5 to -97.5), +1 south leg (z from 17.5 to 97.5).

const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const Z0 := 17.5
const Z1 := 97.5
const STALL := 6.7

## opts:
##  "bus": true -> far-side bus zone (25 m, no stalls) on the departure side with a shelter
##  "trees": z distances (positive, from the junction) of the round tree wells, both sides
##  "lamps": z distances of the post lamps, both sides
##  "no_parking": true -> city-centre section: no parking lane (kerb on the lane edge, set S.A_KERB = S.A_LANE first),
##                        so no edge line, stalls, meters or parked-car oil
##  "extra": Array of [base, cond, side x sign, |z|, offset from kerb, yaw] placed on the sidewalk
static func build(name: String, sz: float, opts: Dictionary) -> Node3D:
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new()
	var dec := K.Decals.new(); var rr := W.rng_for(name)
	var zz := func(d: float) -> float: return sz * d      # distance from junction -> local z
	var lo := func(a: float, b: float) -> float: return minf(a, b)
	var hi := func(a: float, b: float) -> float: return maxf(a, b)
	# right-hand traffic: on the north leg (sz -1) the lanes coming TO the junction are the southbound ones, west half
	# (x < 0); on the south leg (sz +1) the northbound ones, east half. So the approach side is x sign = sz.
	var app := sz      # x side of the lanes that approach the junction on this leg
	var dep := -sz     # x side of the lanes leaving it (far-side bus stop goes here)
	# ---------------------------------------------------------------- median (raised, planted) with a round nose
	var nose_c := Vector2(0.0, zz.call(Z0 + S.A_MED))
	var outline := PackedVector2Array()
	var a0 := atan2(-sz, 0.0)
	for p in K.arc(nose_c, S.A_MED, a0 - PI * 0.5, a0 + PI * 0.5, 12): outline.append(p)
	g.poly("grass", outline, S.walk_y)
	# asphalt in the two corners between the round nose and the straight lane edges (from the tile edge to the nose)
	for hx: float in [-1.0, 1.0]:
		var fill := PackedVector2Array([Vector2(0.0, zz.call(Z0)), Vector2(hx * S.A_MED, zz.call(Z0)), Vector2(hx * S.A_MED, zz.call(Z0 + S.A_MED))])
		var q := K.arc(nose_c, S.A_MED, atan2(0.0, hx), a0, 8)
		for i in range(1, q.size() - 1): fill.append(q[i])   # skip both ends: they repeat fill points
		g.poly("asphalt", fill, S.road_y)
	g.rect("grass", -S.A_MED, lo.call(zz.call(Z0 + S.A_MED), zz.call(Z1)), S.A_MED, hi.call(zz.call(Z0 + S.A_MED), zz.call(Z1)), S.walk_y)
	# walk the outline: far end -> one long side -> nose -> other long side -> far end
	var side_a := PackedVector2Array([Vector2(S.A_MED, zz.call(Z1)), Vector2(S.A_MED, zz.call(Z0 + S.A_MED))])
	var side_b := PackedVector2Array([Vector2(-S.A_MED, zz.call(Z0 + S.A_MED)), Vector2(-S.A_MED, zz.call(Z1))])
	_kerb_out(g, side_a, Vector2.ZERO); _kerb_out(g, side_b, Vector2.ZERO)
	_kerb_out(g, outline, nose_c)
	# queen palms down the median, first one clear of the junction sight lines
	for d in range(26, 96, 12):
		props.add("palm_queen_a" if (d / 12) % 2 == 0 else "palm_queen_b", "normal", Vector3(0.0, S.walk_y(0.0), zz.call(float(d))), float(d * 37 % 360))
	# ---------------------------------------------------------------- carriageways with paint
	var bus: bool = opts.get("bus", false)
	for xs: float in [-1.0, 1.0]:
		var paint: Array = []
		var approach: bool = xs == app
		var lane_line := xs * (S.A_MED + 3.3)
		# lane line between the two lanes: solid for the last 20 m before the stop bar, then 3 m dashes every 12 m
		var solid_to := Z0 + 20.0 if approach else Z0
		if approach: paint.append([lane_line - 0.06, lo.call(zz.call(Z0), zz.call(solid_to)), lane_line + 0.06, hi.call(zz.call(Z0), zz.call(solid_to)), "white"])
		var d := solid_to + 9.0
		while d + 3.0 <= Z1:
			paint.append([lane_line - 0.06, lo.call(zz.call(d), zz.call(d + 3.0)), lane_line + 0.06, hi.call(zz.call(d), zz.call(d + 3.0)), "white"]); d += 12.0
		# edge line between traffic lanes and the parking lane
		var e := xs * S.A_LANE
		var no_parking: bool = opts.get("no_parking", false)
		if not no_parking: paint.append([e - 0.06, lo.call(zz.call(Z0), zz.call(Z1)), e + 0.06, hi.call(zz.call(Z0), zz.call(Z1)), "white"])
		# parking stalls: none within 6 m of the crosswalk (it ends at 15.5 m); a 25 m bus zone on the departure side
		var s0 := 21.5 + (25.0 if (bus and not approach) else 0.0)
		var stalls: Array = []
		var z := s0
		while z + STALL <= Z1 + 1e-3 and not no_parking:
			stalls.append(z); z += STALL
		if not no_parking: stalls.append(z)
		for si in stalls.size():
			var sb: float = stalls[si]
			if sb > Z1: continue
			# oil under the engines of the cars that park here most (about 7 stalls in 10)
			if sb + STALL <= Z1 and rr.randf() < 0.7:
				W.oil(dec, rr, Vector2(xs * (S.A_LANE + 1.2), zz.call(sb + STALL * (0.3 if sz < 0 else 0.7))), 0.0, S.road_y)
			# T mark: a short line across the parking lane at each stall end
			paint.append([lo.call(e, xs * (S.A_LANE + 1.8)), lo.call(zz.call(sb - 0.05), zz.call(sb + 0.05)), hi.call(e, xs * (S.A_LANE + 1.8)), hi.call(zz.call(sb - 0.05), zz.call(sb + 0.05)), "white"])
			# parking meter at each stall end, 0.55 m behind the kerb face, facing the car
			if sb >= s0 and sb <= Z1 - 0.5:
				props.add("prop_parking_meter", "worn", Vector3(xs * (S.A_KERB + 0.55), S.walk_y(0.0), zz.call(sb)), 90.0 * -xs)
		for lc0: float in [S.A_MED + 1.65, S.A_MED + 4.95]:
			W.lane_wear(dec, rr, xs * lc0, zz.call(Z0), zz.call(Z1), true, S.road_y)
		# ageing: cracks (half already sealed), gutter grime where rain carries dirt to the kerb
		W.cracks(dec, rr, minf(xs * (S.A_MED + 0.3), xs * (S.A_LANE - 0.3)), minf(zz.call(Z0 + 3.0), zz.call(Z1)), maxf(xs * (S.A_MED + 0.3), xs * (S.A_LANE - 0.3)), maxf(zz.call(Z0 + 3.0), zz.call(Z1)), 12, S.road_y, 0.5)
		var gz := Z0 + 1.0
		while gz < Z1 - 1.0:
			dec.add(14, Vector2(xs * (S.A_KERB - 0.28), zz.call(gz + 1.2)), 0.0, 0.5, 2.4, S.road_y, Color(1, 1, 1, rr.randf_range(0.35, 0.6)))
			gz += rr.randf_range(4.0, 8.0)
		if approach:
			# the queue at the light: braking marks in both wheel paths of both lanes, oil where engines idle
			for lc: float in [xs * (S.A_MED + 1.65), xs * (S.A_MED + 4.95)]:
				for wp: float in [-0.8, 0.8]:
					dec.add(8, Vector2(lc + wp, zz.call(Z0 + 7.0)), 0.0, 0.45, 9.0, S.road_y, Color(1, 1, 1, 0.45))
				W.oil(dec, rr, Vector2(lc, zz.call(Z0 + 2.8)), 0.0, S.road_y, 0.6)
				W.oil(dec, rr, Vector2(lc, zz.call(Z0 + 9.5)), 0.0, S.road_y, 0.45)
		# trench patch around the manhole (the sewer was opened at least once)
		dec.add(2 + rr.randi() % 2, Vector2(xs * (S.A_MED + 3.3 + 1.6), zz.call(40.0 if xs < 0 else 70.0)), rr.randf_range(-8, 8), 2.6, 2.2, S.road_y, Color(1, 1, 1, 0.85))
		# turn arrows on the approach, about 8 m before the stop bar
		var arrows: Array = []
		if approach:   # smooth polygon arrows (holes in the paint grid, filled after it)
			var inner := xs * (S.A_MED + 1.65); var outer := xs * (S.A_MED + 4.95)
			arrows.append(S.arrow2("left_through", inner, zz.call(Z0 + 13.0), zz.call(Z0 + 8.5)))
			arrows.append(S.arrow2("through_right", outer, zz.call(Z0 + 13.0), zz.call(Z0 + 8.5)))
			for a2: Dictionary in arrows: paint.insert(0, (a2.box as Array) + ["-"])
		K.painted_rect(g, lo.call(xs * S.A_MED, xs * S.A_KERB), lo.call(zz.call(Z0), zz.call(Z1)), hi.call(xs * S.A_MED, xs * S.A_KERB), hi.call(zz.call(Z0), zz.call(Z1)), paint, S.road_y)
		for a2: Dictionary in arrows: K.fill_arrow(g, a2, S.road_y)
		# sewer manholes in the lanes, every 60 m, alternating
		props.add("prop_manhole_cover", "worn", Vector3(xs * (S.A_MED + 3.3 + 1.6 * xs * xs), S.road_y(0.0) + 0.002, zz.call(40.0 if xs < 0 else 70.0)), 0.0, false)
	# ---------------------------------------------------------------- sidewalks, trees, lamps
	var trees: Array = opts.get("trees", [])
	var lamps: Array = opts.get("lamps", [])
	for xs: float in [-1.0, 1.0]:
		var wells: Array = []
		for t: float in trees: wells.append(zz.call(t))
		S.amber_sidewalk(g, xs, lo.call(zz.call(Z0), zz.call(Z1)), hi.call(zz.call(Z0), zz.call(Z1)), wells)
		# 17 Nov audit #12: the kit jacaranda's crown starts at 2.3-2.9 m, so a continuous row hid the shop signs and hung
		# low over the parking lane. Every second well gets a queen palm (crown at 7.3 m): the sign bands read between
		# the jacarandas. (A street-pruned jacaranda, crown >= 4.5 m over the road, is on Yasin's asset wish list.)
		for ti in trees.size():
			var t: float = trees[ti]
			var sp := ("tree_jacaranda_a" if int(t) % 2 == 0 else "tree_jacaranda_b") if ti % 2 == 0 else ("palm_queen_a" if int(t) % 2 == 0 else "palm_queen_b")
			props.add(sp, "normal", Vector3(xs * (S.A_KERB + 0.75), S.walk_y(0.0) - 0.06, zz.call(t)), t * 53.0)
		for l: float in lamps:
			props.add("prop_lamp_victorian", "worn", Vector3(xs * (S.A_KERB + 0.6), S.walk_y(0.0), zz.call(l)), 90.0)
		# a trash + recycling pair just past the corner and one mid-block
		for zt: float in [19.0, 56.0]:
			props.add("prop_trash_receptacle", "worn", Vector3(xs * (S.A_KERB + 0.75), S.walk_y(0.0), zz.call(zt)), 0.0)
			props.add("prop_recycling_receptacle", "worn", Vector3(xs * (S.A_KERB + 0.75), S.walk_y(0.0), zz.call(zt + 0.8)), 0.0)
	# bus stop: shelter near the downstream end of the zone, open side to the street, plus a no-parking sign
	if bus:
		var bx := dep * (S.A_BLD - 0.95)     # shelter at the back of the sidewalk: kerb stays free for boarding
		var bz: float = opts.get("bus_at", 43.5)
		props.add("prop_bus_shelter", "worn", Vector3(bx, S.walk_y(0.0), zz.call(bz)), -90.0 * dep)
		props.add("prop_bus_stop_sign", "worn", Vector3(dep * (S.A_KERB + 0.45), S.walk_y(0.0), zz.call(bz - 3.6)), -90.0 * dep)   # kit batch 2: the stop's pole sign, at the kerb
		props.add("prop_sign_no_parking", "worn", Vector3(dep * (S.A_KERB + 0.4), S.walk_y(0.0), zz.call(22.0)), -90.0 * dep)
		props.add("prop_trash_receptacle", "worn", Vector3(dep * (S.A_KERB + 0.75), S.walk_y(0.0), zz.call(bz - 2.9)), 0.0)
	for x: Array in opts.get("extra", []):
		var xs2: float = x[2]
		props.add(x[0], x[1], Vector3(xs2 * (S.A_KERB + float(x[4])), S.walk_y(0.0), zz.call(float(x[3]))), float(x[5]))
	# one service trench across the west lanes (a water line was renewed): long patch, square ends
	dec.add(3, Vector2(-(S.A_MED + S.A_LANE) * 0.5, zz.call(58.0)), 90.0, 1.3, 6.4, S.road_y, Color(1, 1, 1, 0.9))
	# sidewalks: scuffed where the bus riders wait, root cracks next to some trees
	if bus:
		dec.add(14, Vector2(dep * (S.A_KERB + 1.6), zz.call(opts.get("bus_at", 43.5))), 0.0, 2.8, 5.0, S.walk_y, Color(1, 1, 1, 0.55))
		W.red_kerb(dec, Vector2(dep * S.A_KERB, zz.call(21.5)), Vector2(dep * S.A_KERB, zz.call(46.5)), Vector2(-dep, 0.0))
	for xs: float in [-1.0, 1.0]:
		# red kerb on the no-parking approach to each crosswalk
		W.red_kerb(dec, Vector2(xs * S.A_KERB, zz.call(Z0)), Vector2(xs * S.A_KERB, zz.call(21.5)), Vector2(-xs, 0.0))
		for t: float in trees:
			if rr.randf() < 0.35:
				dec.add(rr.randi() % 2, Vector2(xs * (S.A_KERB + 2.0), zz.call(t + rr.randf_range(-0.6, 0.6))), rr.randf_range(60, 120), 2.2, 0.9, S.walk_y, Color(1, 1, 1, 0.55))
		for k in 5:
			dec.add(14, Vector2(xs * (S.A_KERB + rr.randf_range(2.2, 4.0)), zz.call(rr.randf_range(Z0 + 2.0, Z1 - 2.0))), rr.randf_range(0, 360), rr.randf_range(1.5, 2.5), rr.randf_range(1.0, 1.8), S.walk_y, Color(1, 1, 1, 0.3))
	var wmi := dec.build()
	if wmi: root.add_child(wmi)
	# ---------------------------------------------------------------- output
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d" % [name, g.tri_count(), props.count()])
	return root

## median kerb faces: facing away from the median centre line (or from the nose centre for the round end)
static func _kerb_out(g: K.Ground, pts: PackedVector2Array, centre: Vector2) -> void:
	if pts.size() < 2: return
	var d := (pts[1] - pts[0]).normalized(); var left := Vector2(d.y, -d.x)
	var ref := pts[0] - (centre if centre != Vector2.ZERO else Vector2(0.0, pts[0].y))
	var out := signf(left.dot(ref))
	g.wall_line("curb", pts, S.road_y, S.walk_y, out)
