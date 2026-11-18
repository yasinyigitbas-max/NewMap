extends SceneTree
## Piece s_strip_art (commercial strip sample): one arterial leg from the junction tile (|x| 22) to 100 m, along +x.
## Used on both legs (yaw 0 east, yaw 180 west), so it carries only street things. Cross-section: centre two-way
## left-turn lane (yellow solid + dashed edges), 2 lanes each way, bike lanes, kerb, a palm parkway (Mexican fan palms:
## the arterial's signature), 2 m sidewalk. Approaching the junction (north half, westbound) the centre lane becomes a
## 30 m left-turn pocket with arrows. Driveway aprons at 45 m and 80 m on both sides (the lots' entrances), power on
## the north side (poles in the parkway, carrying the line the lots' service drops hang from), cobra lamps on both
## sides, a far-side bus stop on the south side. Wear: wheel paths, oil in the pocket and the queue, cracks, trench
## patches, gutter grime, bike-lane debris, a scuffed bus stop. Run once; never when locked.
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const X0 := 22.0
const X1 := 100.0
const POCKET := 52.0
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "s_strip_art"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("s_strip_art")
	var ry := S.road_y
	var p: Array = []
	# ---- centre lane: south edge solid yellow all along; north edge solid white along the pocket, solid yellow after;
	# inner dashed yellow lines (two-way turn lane) beyond the pocket taper
	p.append([X0, L.TL - 0.15, X1, L.TL - 0.05, "yellow"])
	p.append([X0, -L.TL + 0.05, POCKET, -L.TL + 0.2, "white"])
	p.append([POCKET, -L.TL + 0.05, X1, -L.TL + 0.15, "yellow"])
	var d := POCKET + 6.0
	while d + 3.0 <= X1:
		p.append([d, L.TL - 0.42, d + 3.0, L.TL - 0.32, "yellow"]); p.append([d, -L.TL + 0.32, d + 3.0, -L.TL + 0.42, "yellow"]); d += 9.0
	# pocket arrows (left turn for westbound: the driver's left is +z)
	var arrows: Array = []   # smooth polygon arrows: holes in the paint grid, filled after it
	for ax: float in [X0 + 6.0, X0 + 18.0]: arrows.append(S.arrow2("right", 0.0, ax + 4.5, ax, true))   # mirrored by the transposition: draws the westbound LEFT turn
	# ---- lane lines (dashed; solid for the last 15 m on the approach side), bike lane lines broken across the aprons
	for sz: float in [-1.0, 1.0]:
		var approach := sz < 0.0
		var solid_to := X0 + 15.0 if approach else X0
		if approach: p.append([X0, sz * L.L1 - 0.06, solid_to, sz * L.L1 + 0.06, "white"])
		d = solid_to + 6.0
		while d + 3.0 <= X1:
			p.append([d, sz * L.L1 - 0.06, d + 3.0, sz * L.L1 + 0.06, "white"]); d += 12.0
		var cur := X0
		for a: float in L.APR_A:
			var a0: float = a - L.APR_A_W * 0.5; var a1: float = a + L.APR_A_W * 0.5
			p.append([cur, sz * L.L2 - 0.08, a0, sz * L.L2 + 0.08, "white"])
			var k := a0
			while k + 1.0 <= a1: p.append([k, sz * L.L2 - 0.08, k + 1.0, sz * L.L2 + 0.08, "white"]); k += 2.0
			cur = a1
		p.append([cur, sz * L.L2 - 0.08, X1, sz * L.L2 + 0.08, "white"])
		if approach:
			# lane arrows before the stop bar (lanes run -x here: through / through-right seen by the driver)
			for ln: Array in [[-(L.TL + L.L1) * 0.5, "through"], [-(L.L1 + L.L2) * 0.5, "through_right"]]:
				arrows.append(S.arrow2(String(ln[1]) if ln[1] == "through" else "left_through", float(ln[0]), X0 + 10.5, X0 + 6.0, true))   # along x: the transposition mirrors, so "left_through" draws through-right
	for a2: Dictionary in arrows: p.insert(0, (a2.box as Array) + ["-"])
	K.painted_rect(g, X0, -L.KERB_A, X1, L.KERB_A, p, ry)
	for a2: Dictionary in arrows: K.fill_arrow(g, a2, ry)
	# ---- kerbs, parkway (grass, concrete through the aprons), sidewalk
	for sz: float in [-1.0, 1.0]:
		var cur := X0
		for a: float in L.APR_A:
			var a0: float = a - L.APR_A_W * 0.5 - 1.5; var a1: float = a + L.APR_A_W * 0.5 + 1.5
			S.sidewalk_strip(g, "x", sz * L.KERB_A, sz * L.PKW, cur, a0, [], "grass")
			S.sidewalk_strip(g, "x", sz * L.KERB_A, sz * L.PKW, a0, a1, [[a, L.APR_A_W]], "concrete", 2.0, 1.5, 0.0)
			cur = a1
		S.sidewalk_strip(g, "x", sz * L.KERB_A, sz * L.PKW, cur, X1, [], "grass")
		g.rect("concrete", X0, minf(sz * L.PKW, sz * L.PROP_A), X1, maxf(sz * L.PKW, sz * L.PROP_A), S.walk_y)
	# ---- street furniture
	var taken: Array = []   # [x, side] spots used in the parkway
	for px: float in [30.0, 62.0, 94.0]:
		props.add("prop_utility_pole", "worn", Vector3(px, S.walk_y(0.0), -(L.KERB_A + 1.0)), 90.0)   # cross-arm (model X) across the line: line along x -> yaw 90
		taken.append([px, -1.0])
	for lx: float in [36.0, 70.0]:
		props.add("prop_lamp_cobra", "rusty", Vector3(lx, S.walk_y(0.0), L.KERB_A + 0.9), 180.0)    # arm +Z -> over the road
		taken.append([lx, 1.0])
	for lx: float in [54.0, 88.0]:
		props.add("prop_lamp_cobra", "rusty", Vector3(lx, S.walk_y(0.0), -(L.KERB_A + 0.9)), 0.0)
		taken.append([lx, -1.0])
	# far-side bus stop (eastbound departs on the south side): bench on the sidewalk facing the road, bin, red kerb
	props.add("prop_bench_bus_stop", "worn", Vector3(30.0, S.walk_y(0.0), L.PROP_A - 0.55), 180.0)
	I.add(props, "prop_bus_stop_sign", "worn", Vector3(26.0, S.walk_y(0.0), L.PKW + 0.4), 180.0)
	props.add("prop_trash_receptacle", "dirty", Vector3(33.2, S.walk_y(0.0), L.PROP_A - 0.5), 0.0)
	W.red_kerb(dec, Vector2(24.0, L.KERB_A), Vector2(38.0, L.KERB_A), Vector2(0.0, -1.0))
	dec.add(14, Vector2(30.0, L.PROP_A - 1.0), 90.0, 2.0, 5.0, S.walk_y, Color(1, 1, 1, 0.6))
	taken.append([30.0, 1.0])
	# palms down both parkways, every ~11 m, clear of aprons, poles and lamps
	for sz: float in [-1.0, 1.0]:
		var x := X0 + 4.0
		while x < X1 - 2.0:
			var ok := true
			for a: float in L.APR_A:
				if absf(x - a) < L.APR_A_W * 0.5 + 2.5: ok = false
			for t: Array in taken:
				if float(t[1]) == sz and absf(x - float(t[0])) < 3.0: ok = false
			if ok:
				props.add(["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"][int(x) % 3], "normal", Vector3(x, S.walk_y(0.0), sz * (L.KERB_A + 1.0)), x * 37.0)
				x += 11.0
			else:
				x += 1.0
	props.add("prop_hydrant_red", "rusty", Vector3(58.0, S.walk_y(0.0), L.KERB_A + 1.0), 0.0)
	W.red_kerb(dec, Vector2(54.0, L.KERB_A), Vector2(62.0, L.KERB_A), Vector2(0.0, -1.0))
	for sz: float in [-1.0, 1.0]:
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(73.0, ry.call(0.0), sz * L.KERB_A), 180.0 if sz < 0 else 0.0, false)
	props.add("prop_manhole_cover", "worn", Vector3(48.0, ry.call(0.0) + 0.002, -(L.L1 + 1.6)), 0.0, false)
	props.add("prop_manhole_cover", "worn", Vector3(84.0, ry.call(0.0) + 0.002, L.TL + 1.7), 0.0, false)
	# ---- wear
	for sz: float in [-1.0, 1.0]:
		for lc: float in [sz * (L.TL + L.L1) * 0.5, sz * (L.L1 + L.L2) * 0.5]:
			W.lane_wear(dec, rr, lc, X0, X1, false, ry)
		W.cracks(dec, rr, X0 + 1.0, minf(sz * L.TL, sz * L.L2), X1 - 1.0, maxf(sz * L.TL, sz * L.L2), 16, ry, 0.45)
		var gx := X0 + 1.0
		while gx < X1 - 1.5:   # gutter grime and grit in the bike lane
			dec.add(14, Vector2(gx + 1.2, sz * (L.KERB_A - 0.3)), 90.0, 0.6, 2.4, ry, Color(1, 1, 1, rr.randf_range(0.4, 0.65)))
			gx += rr.randf_range(3.0, 7.0)
		for a: float in L.APR_A:   # cars swing in and out of the lots
			dec.add(8, Vector2(a - 3.0, sz * (L.L2 - 1.5)), 90.0 + sz * 25.0, 0.6, 7.0, ry, Color(1, 1, 1, 0.5))
			dec.add(8, Vector2(a + 3.0, sz * (L.L2 - 1.5)), 90.0 - sz * 25.0, 0.6, 7.0, ry, Color(1, 1, 1, 0.5))
			W.oil(dec, rr, Vector2(a, sz * (L.KERB_A + 2.6)), 90.0, S.walk_y, 0.6)
		var sx2 := X0 + 1.0
		while sx2 < X1 - 1.0:   # sidewalk: nobody walks here much - dust blown off the lots, weeds' dirt at the joints
			var Ls := rr.randf_range(2.0, 6.0)
			dec.add(14, Vector2(sx2 + Ls * 0.5, sz * (L.PKW + 1.0)), 90.0, 1.4, Ls, S.walk_y, Color(1, 1, 1, rr.randf_range(0.3, 0.55)))
			sx2 += Ls + rr.randf_range(2.0, 6.0)
	for k in 6: W.oil(dec, rr, Vector2(rr.randf_range(X0 + 2.0, POCKET), rr.randf_range(-1.0, 1.0)), 90.0, ry, 0.8)   # the turn queue
	dec.add(2, Vector2(66.0, -(L.TL + L.L1) * 0.5), 0.0, 1.5, 7.0, ry, Color(1, 1, 1, 0.9))     # utility cut
	dec.add(3, Vector2(91.0, 0.0), 90.0, 1.6, 2.0 * L.L2, ry, Color(1, 1, 1, 0.85))               # trench across
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("s_strip_art: ground tris %d, props %d" % [g.tri_count(), props.count()])
	K.save_piece(root, "s_strip_art")
	quit()

## a left-turn arrow running along x (from xt to xh, driving -x on this leg), lane centre z = cz; the driver's left
## when moving -x is +z. Shaft to the bend, then the arm and a stepped head pointing +z.
func _left_arrow(cz: float, xt: float, xh: float) -> Array:
	var out: Array = []
	var dx := signf(xh - xt)
	var bend := xh
	out.append([minf(xt, bend), cz - 0.08, maxf(xt, bend), cz + 0.08, "white"])
	var arm_x0 := bend - dx * 0.16
	out.append([minf(arm_x0, bend), cz - 0.08, maxf(arm_x0, bend), cz + 1.1, "white"])
	for i in 6:
		var w := 0.45 * (1.0 - float(i) / 6.0)
		var za := cz + 1.1 + 0.9 * float(i) / 6.0; var zb := cz + 1.1 + 0.9 * float(i + 1) / 6.0
		var xc := (arm_x0 + bend) * 0.5
		out.append([xc - w, za, xc + w, zb, "white"])
	return out
