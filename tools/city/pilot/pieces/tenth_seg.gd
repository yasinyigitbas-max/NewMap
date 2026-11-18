extends RefCounted
## Builds one 10th St street piece (one leg of the junction). Downtown section: 4 m sidewalk to the building line,
## parallel stalls with T marks, alley apron. Residential section (east leg, on the hill): grass parkway with a street
## tree per lot, concrete driveway aprons cut through the parkway, 1.5 m sidewalk. Used by s_10th_w / s_10th_e.

const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const STALL := 6.7

## sx: -1 west leg, +1 east leg. x_end: |x| where the leg stops. res_from: |x| where the residential section starts
## (> x_end for none). alley: [a, b] |x| range of the alley mouth. opts: "extra": [[base, cond, side z sign, |x|, offset from
## kerb, yaw]], "no_park": [[|x| a, |x| b]] extra no-stall ranges.
static func build(name: String, sx: float, x_end: float, res_from: float, alley: Array, opts: Dictionary) -> Node3D:
	var root := Node3D.new(); root.name = name
	var g := K.Ground.new(); var props := K.Props.new()
	var dec := K.Decals.new(); var rr := W.rng_for(name)
	var X := func(d: float) -> float: return sx * d
	var x0 := S.J_X; var x1 := x_end
	var drives: Array = []    # [side, centre |x|]
	for L: Dictionary in S.LOTS:
		if sx > 0 and float(L.drive) > 0.0: drives.append([float(L.side), float(L.drive)])
	for sz: float in [-1.0, 1.0]:
		# ---- road half with paint
		var paint: Array = []
		var y0 := 0.1 if sz > 0 else -0.2
		paint.append([minf(X.call(x0), X.call(x1)), y0, maxf(X.call(x0), X.call(x1)), y0 + 0.1, "yellow"])
		# stalls (downtown only): start 6 m past the crosswalk, stop clear of the alley mouth and the residential part
		var no_park: Array = [[alley[0] - 1.5, alley[1] + 1.5]]
		no_park.append_array(opts.get("no_park", []))
		var d := S.XW_T[1] + 6.0
		var stop_at := minf(res_from, x1)
		while d + STALL <= stop_at:
			var blocked := false
			for r: Array in no_park:
				if d + STALL > float(r[0]) and d < float(r[1]): blocked = true
			if not blocked:
				if rr.randf() < 0.7: W.oil(dec, rr, Vector2(X.call(d + STALL * 0.5), sz * (S.T_LANE + 1.2)), 90.0, S.road_y)
				for e: float in [d, d + STALL]:
					paint.append([X.call(e) - 0.05, minf(sz * S.T_LANE, sz * (S.T_LANE + 1.8)), X.call(e) + 0.05, maxf(sz * S.T_LANE, sz * (S.T_LANE + 1.8)), "white"])
				d += STALL
			else:
				d += 1.0
		W.lane_wear(dec, rr, sz * S.T_LANE * 0.5, X.call(x0), X.call(x1), false, S.road_y)
		# ageing: more cracks on the residential stretch (older, less traffic money), gutter grime, kerbside oil
		W.cracks(dec, rr, minf(X.call(x0 + 1.0), X.call(x1 - 1.0)), minf(0.3 * sz, sz * (S.T_LANE - 0.2)), maxf(X.call(x0 + 1.0), X.call(x1 - 1.0)), maxf(0.3 * sz, sz * (S.T_LANE - 0.2)), int(absf(x1 - x0) / 5.0), S.road_y, 0.35)
		var gx := x0 + 1.0
		while gx < x1 - 1.5:
			dec.add(14, Vector2(X.call(gx + 1.2), sz * (S.T_KERB - 0.28)), 90.0, 0.5, 2.4, S.road_y, Color(1, 1, 1, rr.randf_range(0.35, 0.6)))
			gx += rr.randf_range(4.0, 8.0)
		if res_from < x1:
			for k in 4: W.oil(dec, rr, Vector2(X.call(rr.randf_range(res_from + 4.0, x1 - 4.0)), sz * (S.T_LANE + 1.2)), 90.0, S.road_y, 0.55)
		# turning tyre marks at the alley mouth
		dec.add(8, Vector2(X.call((alley[0] + alley[1]) * 0.5), sz * 3.0), 35.0 * sz, 0.5, 6.0, S.road_y, Color(1, 1, 1, 0.4))
		K.painted_rect(g, minf(X.call(x0), X.call(x1)), minf(0.0, sz * S.T_KERB), maxf(X.call(x0), X.call(x1)), maxf(0.0, sz * S.T_KERB), paint, S.road_y)
		# ---- downtown sidewalk (to the building line) with the alley apron
		var dt1 := minf(res_from, x1)
		var ramps: Array = [[X.call((alley[0] + alley[1]) * 0.5), absf(alley[1] - alley[0])]]
		# tree wells are cut out of the slab (16 Nov: drawn on top they were hidden under it, trunks stood in concrete)
		var side_wells: Array = []
		for w0: Array in opts.get("wells", []):
			if float(w0[0]) == sz: side_wells.append(X.call(float(w0[1])))
		S.sidewalk_with_wells(g, "x", sz * S.T_KERB, sz * S.T_BLD, minf(X.call(x0), X.call(dt1)), maxf(X.call(x0), X.call(dt1)), ramps, side_wells, "concrete", 1.0, 0.6, 0.0)
		# ---- residential: parkway (grass) with aprons, then the sidewalk
		if res_from < x1:
			_parkway(g, sz, res_from, x1, drives)
			g.rect("concrete", res_from, minf(sz * S.T_PARKWAY, sz * S.T_PROP), x1, maxf(sz * S.T_PARKWAY, sz * S.T_PROP), S.walk_y)
	for x: Array in opts.get("extra", []):
		var zs: float = x[2]
		var px: float = X.call(float(x[3])); var pz: float = zs * (S.T_KERB + float(x[4]))
		var y := S.walk_y(px) - (0.06 if String(x[0]).begins_with("tree_") else 0.0)
		props.add(x[0], x[1], Vector3(px, y, pz), float(x[5]))
	# root cracks in the sidewalk beside the parkway trees; red kerb either side of the hydrant
	for x: Array in opts.get("extra", []):
		var bs: String = x[0]
		if bs.begins_with("tree_") and float(x[3]) > res_from and rr.randf() < 0.6:
			dec.add(rr.randi() % 2, Vector2(X.call(float(x[3]) + rr.randf_range(-0.8, 0.8)), float(x[2]) * (S.T_PARKWAY + 0.75)), rr.randf_range(-25, 25), 2.0, 1.0, S.walk_y, Color(1, 1, 1, 0.6))
		if bs.contains("hydrant"):
			var hx: float = X.call(float(x[3])); var kz: float = float(x[2]) * S.T_KERB
			W.red_kerb(dec, Vector2(hx - 4.5, kz), Vector2(hx + 4.5, kz), Vector2(0.0, -float(x[2])))
	# "walk_wear": busy city-centre sidewalk - dirt where people walk and wait, gum and drip stains, settlement cracks
	if opts.get("walk_wear", false):
		for sz: float in [-1.0, 1.0]:
			var wd := x0 + 0.5
			while wd < x1 - 1.0:
				var L := rr.randf_range(2.0, 5.0)
				dec.add(14, Vector2(X.call(wd + L * 0.5), sz * rr.randf_range(S.T_KERB + 2.0, S.T_BLD - 1.0)), 90.0, rr.randf_range(1.4, 2.4), L, S.walk_y, Color(1, 1, 1, rr.randf_range(0.3, 0.55)))
				wd += L + rr.randf_range(1.0, 4.0)
			for k in 6: dec.add(0, Vector2(X.call(rr.randf_range(x0 + 1.0, x1 - 1.0)), sz * rr.randf_range(S.T_KERB + 1.5, S.T_BLD - 0.5)), rr.randf_range(0, 180), rr.randf_range(1.2, 2.2), 0.8, S.walk_y, Color(0.3, 0.29, 0.28, 0.75))
	var wmi := dec.build()
	if wmi: root.add_child(wmi)
	# (wells: drawn by sidewalk_with_wells above)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("%s: ground tris %d, props %d" % [name, g.tri_count(), props.count()])
	return root

## grass parkway between the kerb (|z| 5.7) and the sidewalk (|z| 7.7), x a..b (east leg only), with a concrete apron
## at each driveway: it rises from the road at the kerb to the sidewalk, 0.5 m flares, the kerb face dropped there.
static func _parkway(g: K.Ground, sz: float, a: float, b: float, drives: Array) -> void:
	const W := 3.0
	const FL := 0.5
	var mine: Array = []
	for d: Array in drives:
		if float(d[0]) == sz: mine.append(float(d[1]))
	mine.sort()
	var cur := a
	var kerb_pts := PackedVector2Array([Vector2(a, sz * S.T_KERB)])
	var depth := S.T_PARKWAY - S.T_KERB
	for c: float in mine:
		var za := c - W * 0.5 - FL; var zb := c + W * 0.5 + FL
		g.rect("grass", cur, minf(sz * S.T_KERB, sz * S.T_PARKWAY), za, maxf(sz * S.T_KERB, sz * S.T_PARKWAY), S.walk_y)
		var ns := int(ceil((zb - za) / 0.35)); var nt := 6
		var drop := func(x: float, t: float) -> float:
			var ft := clampf(1.0 - t / depth, 0.0, 1.0)
			var ds := absf(x - c) - W * 0.5
			var fs := 1.0 if ds <= 0.0 else clampf(1.0 - ds / FL, 0.0, 1.0)
			return S.KERB_H * ft * fs
		for i in ns:
			for j in nt:
				var xa := lerpf(za, zb, float(i) / ns); var xb := lerpf(za, zb, float(i + 1) / ns)
				var ta := depth * float(j) / nt; var tb := depth * float(j + 1) / nt
				var p := func(x: float, t: float) -> Vector3: return Vector3(x, S.walk_y(x) - drop.call(x, t), sz * (S.T_KERB + t))
				g.quad("concrete", p.call(xa, ta), p.call(xb, ta), p.call(xb, tb), p.call(xa, tb))
		for i in ns + 1:
			kerb_pts.append(Vector2(lerpf(za, zb, float(i) / ns), sz * S.T_KERB))
		cur = zb
	g.rect("grass", cur, minf(sz * S.T_KERB, sz * S.T_PARKWAY), b, maxf(sz * S.T_KERB, sz * S.T_PARKWAY), S.walk_y)
	kerb_pts.append(Vector2(b, sz * S.T_KERB))
	# kerb face, its top lowered at the aprons (same drop function at t = 0)
	var top := func(x: float, _z: float) -> float:
		var dd := 0.0
		for c: float in mine:
			var ds := absf(x - c) - W * 0.5
			dd = maxf(dd, 1.0 if ds <= 0.0 else clampf(1.0 - ds / FL, 0.0, 1.0))
		return S.walk_y(x) - S.KERB_H * dd
	# densify the straight runs so the face follows the hill
	var dense := PackedVector2Array()
	for k in kerb_pts.size() - 1:
		var p0 := kerb_pts[k]; var p1 := kerb_pts[k + 1]
		var n := maxi(1, int(ceil(absf(p1.x - p0.x) / 4.0)))
		for i in n: dense.append(p0.lerp(p1, float(i) / n))
	dense.append(kerb_pts[kerb_pts.size() - 1])
	g.wall_line("curb", dense, S.road_y, top, sz)
