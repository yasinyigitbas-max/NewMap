extends SceneTree
## Piece j_strip (commercial strip sample): the signalized junction of the arterial (2+2 lanes, centre turn lane, bike
## lanes, along x) and a commercial side street (1+1 lanes, parking, along z). Covers |x| <= 22, |z| <= 26 out to the
## property lines. Mast arms carry the arterial heads on the far-right corners of its approaches (NW for westbound,
## SE for eastbound); post-mounted heads + street names serve the side street (NE, SW). Continental crosswalks on all
## four legs, ramps aligned with them, hydrants on the diagonal corners, kerb inlets upstream of the crosswalks.
## Heavy wear: a busy signal - braking marks at every stop bar, oil where the queue idles, turning arcs, a utility
## trench patch across the middle, gutter grime round the returns. Run once; never when locked.
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "j_strip"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("j_strip")
	var ry := S.road_y
	# ---- arterial carriageway through the junction, with the crosswalks across it and its stop bars
	var pa: Array = []
	for sx: float in [-1.0, 1.0]:
		var xa: float = L.XW_A[0]; var xb: float = L.XW_A[1]
		var z := -L.KERB_A + 0.3
		while z + 0.6 <= L.KERB_A - 0.3 + 1e-3:
			pa.append([minf(sx * xa, sx * xb), z, maxf(sx * xa, sx * xb), z + 0.6, "white"]); z += 1.2
	# westbound approach (east leg, z < 0, incl. its left-turn pocket in the centre lane) and eastbound (west leg)
	pa.append([L.STOP_A[0], -L.KERB_A, L.STOP_A[1], L.TL, "white"])
	pa.append([-L.STOP_A[1], -L.TL, -L.STOP_A[0], L.KERB_A, "white"])
	K.painted_rect(g, -L.JX, -L.KERB_A, L.JX, L.KERB_A, pa, ry)
	# ---- side street through the junction mouth (between the arterial kerb and the tile edge), crosswalks, stop bars
	for sz: float in [-1.0, 1.0]:
		var ps: Array = []
		var za: float = L.XW_S[0] * sz; var zb: float = L.XW_S[1] * sz
		var x := -L.KERB_S + 0.3
		while x + 0.6 <= L.KERB_S - 0.3 + 1e-3:
			ps.append([x, minf(za, zb), x + 0.6, maxf(za, zb), "white"]); x += 1.2
		# southbound uses x < 0 (north leg, sz -1); northbound x > 0 (south leg)
		if sz < 0: ps.append([-L.LANE_S, -L.STOP_S[1], 0.0, -L.STOP_S[0], "white"])
		else: ps.append([0.0, L.STOP_S[0], L.LANE_S, L.STOP_S[1], "white"])
		ps.append([-0.2, minf(sz * L.STOP_S[1], sz * L.JZ), -0.1, maxf(sz * L.STOP_S[1], sz * L.JZ), "yellow"])
		ps.append([0.1, minf(sz * L.STOP_S[1], sz * L.JZ), 0.2, maxf(sz * L.STOP_S[1], sz * L.JZ), "yellow"])
		K.painted_rect(g, -L.KERB_S, minf(sz * L.KERB_A, sz * L.JZ), L.KERB_S, maxf(sz * L.KERB_A, sz * L.JZ), ps, ry)
	# ---- corners
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_corner(g, props, dec, rr, sx, sz)
	# ---- signals: arterial mast arms (arm over the approach lanes, heads facing the arriving traffic)
	var poles := {}
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var c := Vector2(sx * (L.KERB_S + L.R), sz * (L.KERB_A + L.R))
			var dm := Vector2(-sx, -sz).normalized()
			var p := c + dm * (L.R - 1.3)
			poles[Vector2(sx, sz)] = Vector3(p.x, S.walk_y(0.0), p.y)
	# model: arm along -X, heads face +Z. NW corner: arm reaches +z over the westbound lanes, heads face +x (yaw 90)
	props.add("prop_signal_mast_arm", "worn", poles[Vector2(-1, -1)], 90.0)
	props.add("prop_signal_mast_arm", "worn", poles[Vector2(1, 1)], -90.0)
	# side street: post heads face the arriving traffic; street name signs on the same corners
	props.add("prop_signal_post", "worn", poles[Vector2(1, -1)], 0.0)
	props.add("prop_signal_post", "worn", poles[Vector2(-1, 1)], 180.0)
	for k: Vector2 in [Vector2(1, -1), Vector2(-1, 1)]:
		var ns: Vector3 = poles[k] + Vector3(k.x * 1.3, 0.0, 0.0)
		props.add("prop_sign_street_names", "worn", ns, 45.0)
	# hydrants (NE on the side street sidewalk, SW on the arterial sidewalk), kerb inlets upstream of the crosswalks
	I.add(props, "prop_hydrant_red", "worn", Vector3(L.KERB_S + 0.8, S.walk_y(0.0), -24.6), -90.0)
	I.add(props, "prop_hydrant_red", "worn", Vector3(-20.6, S.walk_y(0.0), L.KERB_A + 0.8), 0.0)
	props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(19.6, ry.call(0.0), -L.KERB_A), 180.0, false)
	props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(-19.6, ry.call(0.0), L.KERB_A), 0.0, false)
	props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(-L.KERB_S, ry.call(0.0), -23.9), 90.0, false)
	props.add("prop_manhole_cover", "worn", Vector3(-3.5, ry.call(0.0) + 0.002, 4.0), 0.0, false)
	props.add("prop_manhole_cover", "worn", Vector3(7.0, ry.call(0.0) + 0.002, -3.6), 0.0, false)
	# ---- wear: queues at every stop bar (braking marks in the wheel paths, oil where engines idle)
	for lane_z: float in [-(L.TL + L.L1) * 0.5, -(L.L1 + L.L2) * 0.5, 0.0]:
		for wp: float in [-0.8, 0.8]:
			dec.add(8, Vector2(21.5, lane_z + wp), 90.0, 0.45, 6.0, ry, Color(1, 1, 1, 0.5))
			dec.add(8, Vector2(-21.5, -lane_z + wp), 90.0, 0.45, 6.0, ry, Color(1, 1, 1, 0.5))
		W.oil(dec, rr, Vector2(20.4, lane_z), 90.0, ry, 0.7); W.oil(dec, rr, Vector2(-20.4, -lane_z), 90.0, ry, 0.7)
	W.oil(dec, rr, Vector2(-1.6, -25.0), 0.0, ry, 0.7); W.oil(dec, rr, Vector2(1.6, 25.0), 0.0, ry, 0.7)
	# left turners sweep across the middle; a trench patch where a duct crossing was cut
	for k in 4: dec.add(8, Vector2(rr.randf_range(-6, 6), rr.randf_range(-5, 5)), rr.randf_range(20, 70), 0.6, 9.0, ry, Color(1, 1, 1, 0.4))
	dec.add(3, Vector2(2.0, 0.0), 0.0, 1.4, 19.0, ry, Color(1, 1, 1, 0.9))
	W.cracks(dec, rr, -L.JX + 1.0, -L.KERB_A + 0.5, L.JX - 1.0, L.KERB_A - 0.5, 18, ry, 0.45)
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("j_strip: ground tris %d, props %d" % [g.tri_count(), props.count()])
	K.save_piece(root, "j_strip")
	quit()

## one corner: asphalt fill inside the kerb return, the kerb face, the corner sidewalk (two straight strips with the
## crosswalk ramps, the curved patch between them), grime and a root crack
func _corner(g: K.Ground, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, sx: float, sz: float) -> void:
	var ry := S.road_y
	var c := Vector2(sx * (L.KERB_S + L.R), sz * (L.KERB_A + L.R))
	var a0 := atan2(0.0, -sx); var a1 := atan2(-sz, 0.0)
	if a1 - a0 > PI: a1 -= TAU
	if a0 - a1 > PI: a1 += TAU
	var arc := K.arc(c, L.R, a0, a1, 14)          # from the side-street kerb tangent to the arterial kerb tangent
	var fil := arc.duplicate(); fil.append(Vector2(sx * L.KERB_S, sz * L.KERB_A)); g.poly("asphalt", fil, ry)
	var d := (arc[1] - arc[0]).normalized(); var left := Vector2(d.y, -d.x)
	g.wall_line("curb", arc, ry, S.walk_y, signf(left.dot((arc[0] - c).normalized())))
	# curved patch: arc, then along the strips' inner ends to the property corner
	var patch := arc.duplicate()
	patch.append(Vector2(sx * (L.KERB_S + L.R), sz * L.PROP_A))
	patch.append(Vector2(sx * L.PROP_S, sz * L.PROP_A))
	patch.append(Vector2(sx * L.PROP_S, sz * (L.KERB_A + L.R)))
	g.poly("concrete", patch, S.walk_y)
	var xc := (L.XW_A[0] + L.XW_A[1]) * 0.5; var zc := (L.XW_S[0] + L.XW_S[1]) * 0.5
	S.sidewalk_strip(g, "x", sz * L.KERB_A, sz * L.PROP_A, minf(sx * (L.KERB_S + L.R), sx * L.JX), maxf(sx * (L.KERB_S + L.R), sx * L.JX), [[sx * xc, 3.0]])
	S.sidewalk_strip(g, "z", sx * L.KERB_S, sx * L.PROP_S, minf(sz * (L.KERB_A + L.R), sz * L.JZ), maxf(sz * (L.KERB_A + L.R), sz * L.JZ), [[sz * zc, 3.0]])
	# people wait at the ramps; gutter grime round the return
	dec.add(14, Vector2(sx * xc, sz * (L.KERB_A + 2.0)), 0.0, 3.2, 2.4, S.walk_y, Color(1, 1, 1, 0.5))
	dec.add(14, Vector2(sx * (L.KERB_S + 1.5), sz * zc), 90.0, 3.2, 2.4, S.walk_y, Color(1, 1, 1, 0.5))
	for k in range(1, arc.size() - 1, 3):
		var p: Vector2 = arc[k] + (arc[k] - c).normalized() * 0.3
		dec.add(14, p, rad_to_deg(atan2((arc[k] - c).x, (arc[k] - c).y)) + 90.0, 0.5, 2.0, ry, Color(1, 1, 1, 0.55))
	var mid := c + Vector2(-sx, -sz).normalized() * (L.R - 2.2)
	dec.add(0, mid, rr.randf_range(0, 180), 1.6, 0.8, S.walk_y, Color(0.3, 0.29, 0.28, 0.8))
