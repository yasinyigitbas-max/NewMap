extends SceneTree
## Piece v_sw (civic + parks band, SW): COMMUNITY. A (corner): the community centre with its forecourt and, beside it,
## the succulent garden (kit park, worn) the centre's volunteers keep. B (avenue): the elementary school wing; its
## fenced school yard behind (play structure, swings, picnic tables under a sail, one gate), the drop-off line on the
## lane. C (side street): the mission church facing the street, its garden, and behind it the old churchyard -
## headstones in rows, the obelisk, an iron fence with the cemetery gate. D (inside): the shared lot (church on
## Sunday, school parents on weekdays). Run once; never when locked.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var sx := -1.0; var sz := 1.0
	var ctx := C.begin("v_sw", sx, sz)
	var props = ctx.props; var paints: Array = ctx.paints; var rr: RandomNumberGenerator = ctx.rr; var dec = ctx.dec
	# ---- A: community centre + succulent garden
	C.bld(ctx, "civic/civ_community_center", 23.0, 22.2, "-v", "community_center", A.PROP, 6.0)
	C.park(ctx, "park_succulent_garden", 23.0, 42.0, "+v")
	for k in 2: I.add(props, "prop_bike_rack", "worn", A.q(sx, sz, 40.0 + k * 3.2, 13.5), 0.0)
	I.add(props, "prop_hose_reel_cart", "worn", A.q(sx, sz, 40.0, 30.5), 30.0)
	I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 44.0, 38.0), 90.0 if sx < 0 else -90.0)
	# ---- B: school wing + fenced yard
	C.bld(ctx, "civic/civ_school_wing", 80.0, 21.2, "-v", "school", A.PROP, 6.0)
	I.add(props, "prop_sign_school", "worn", A.q(sx, sz, 63.0, 10.0), 0.0)
	I.add(props, "prop_bike_rack", "worn", A.q(sx, sz, 92.0, 13.5), 0.0)
	for seg: Array in [[61.0, 30.0, 99.0, 30.0], [99.0, 30.0, 99.0, 53.0], [99.0, 53.0, 81.2, 53.0], [78.8, 53.0, 61.0, 53.0], [61.0, 53.0, 61.0, 30.0]]:
		A.privacy(props, Vector2(sx * float(seg[0]), sz * float(seg[1])), Vector2(sx * float(seg[2]), sz * float(seg[3])), "fence_chainlink", "fence_chainlink_post")
	I.add(props, "fence_gate_wrought_iron", "worn", A.q(sx, sz, 80.6, 53.5), 45.0)
	paints.insert(0, A.rect(sx, sz, 62.0, 31.0, 98.0, 42.0, "asphalt"))      # the blacktop where they play ball
	I.add(props, "prop_play_structure", "worn", A.q(sx, sz, 70.0, 47.0), 0.0)
	I.add(props, "prop_swing_set", "worn", A.q(sx, sz, 88.0, 47.0), 90.0)
	for k in 2: I.add(props, "prop_picnic_table", "worn", A.q(sx, sz, 72.0 + k * 7.0, 36.0), 0.0)
	for k in 2: I.add(props, "prop_shade_sail", "worn", A.q(sx, sz, 72.0 + k * 7.0, 36.0), 0.0)   # one sail OVER each table (Yasin 17 Nov: one sail between two tables shaded neither)
	I.add(props, "prop_drinking_fountain", "worn", A.q(sx, sz, 63.0, 40.0), 0.0)
	I.add(props, "prop_trash_receptacle", "worn", A.q(sx, sz, 63.0, 42.0), 0.0)
	for k in 12: dec.add(14, Vector2(sx * rr.randf_range(64.0, 96.0), sz * rr.randf_range(32.0, 51.0)), rr.randf_range(0, 180), 2.0, 2.0, S.walk_y, Color(1, 1, 1, 0.45))
	# ---- C: church + churchyard
	C.bld(ctx, "civic/civ_church", 28.2, 77.0, "-u", "mission_church", A.PROP, 5.0)
	for p: Vector2 in [Vector2(14.0, 64.0), Vector2(14.0, 96.0)]: I.add(props, "palm_mexican_fan_a", "normal", A.q(sx, sz, p.x, p.y), p.y * 3.0)
	for row in 3:
		for k in 6:
			var hs: String = ["prop_headstone_upright", "prop_headstone_cross", "prop_headstone_flat"][(row + k) % 3]
			I.add(props, hs, "dirty" if (row * 6 + k) % 3 == 0 else "worn", A.q(sx, sz, 45.0 + row * 2.6, 64.0 + k * 3.2), 90.0 if sx < 0 else -90.0)
	I.add(props, "prop_obelisk_monument", "dirty", A.q(sx, sz, 46.0, 95.0), 0.0)
	A.privacy(props, Vector2(sx * 43.0, sz * 61.5), Vector2(sx * 53.0, sz * 61.5), "fence_wrought_iron", "fence_post_wrought_iron")
	A.privacy(props, Vector2(sx * 53.0, sz * 61.5), Vector2(sx * 53.0, sz * 98.5), "fence_wrought_iron", "fence_post_wrought_iron")
	A.privacy(props, Vector2(sx * 53.0, sz * 98.5), Vector2(sx * 43.0, sz * 98.5), "fence_wrought_iron", "fence_post_wrought_iron")
	I.add(props, "prop_cemetery_gate", "worn", A.q(sx, sz, 43.0, 80.0), 90.0)
	A.privacy(props, Vector2(sx * 43.0, sz * 61.5), Vector2(sx * 43.0, sz * 77.2), "fence_wrought_iron", "fence_post_wrought_iron")
	A.privacy(props, Vector2(sx * 43.0, sz * 82.8), Vector2(sx * 43.0, sz * 98.5), "fence_wrought_iron", "fence_post_wrought_iron")
	I.add(props, "tree_torrey_pine_a", "normal", A.q(sx, sz, 50.0, 90.0), 30.0)
	# ---- D: shared lot
	# audit fix (17 Nov, Yasin: parking in garages, not open lots): the shared lot becomes the school's playing field
	# (lawn with a use): a lined pitch, chain-link with ONE gate toward the school across the lane, a bench row for
	# parents, bins, worn goal mouths. Sunday church-goers and school parents park in the civic garage (v_ne D).
	var lw := 0.12
	var f0 := Vector2(64.0, 66.0); var f1 := Vector2(96.0, 94.0)
	var lines: Array = [[f0.x, f0.y, f1.x, f0.y + lw], [f0.x, f1.y - lw, f1.x, f1.y], [f0.x, f0.y, f0.x + lw, f1.y], [f1.x - lw, f0.y, f1.x, f1.y],
		[(f0.x + f1.x) * 0.5 - lw * 0.5, f0.y, (f0.x + f1.x) * 0.5 + lw * 0.5, f1.y]]
	for gx: float in [f0.x, f1.x - 6.0]:     # goal boxes at both ends
		var bx0 := gx; var bx1 := gx + 6.0
		lines.append([bx0, 75.0, bx1, 75.0 + lw]); lines.append([bx0, 85.0 - lw, bx1, 85.0])
		lines.append([(bx1 - lw) if gx == f0.x else bx0, 75.0, (bx1) if gx == f0.x else (bx0 + lw), 85.0])
	for l: Array in lines: paints.insert(0, A.rect(sx, sz, float(l[0]), float(l[1]), float(l[2]), float(l[3]), "white"))
	for seg: Array in [[62.0, 62.5, 98.5, 62.5], [98.5, 62.5, 98.5, 98.5], [98.5, 98.5, 62.0, 98.5], [62.0, 98.5, 62.0, 81.1], [62.0, 78.9, 62.0, 62.5]]:
		A.privacy(props, Vector2(sx * float(seg[0]), sz * float(seg[1])), Vector2(sx * float(seg[2]), sz * float(seg[3])), "fence_chainlink", "fence_chainlink_post")
	# (Yasin 17 Nov: the gate did not line up with the fence) a closed double gate IN the fence line: two 1.09 m leaves
	# fill the 2.2 m gap between the end posts
	# each leaf's own post (local x -0.55) sits on the fence's end post, the leaves meet in the middle
	I.add(props, "fence_gate_wrought_iron", "worn", A.q(sx, sz, 62.0, 78.9 + 0.55), -90.0)
	I.add(props, "fence_gate_wrought_iron", "worn", A.q(sx, sz, 62.0, 81.1 - 0.55), 90.0)
	for k in 3: I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 70.0 + k * 10.0, 63.6), 0.0 if sz < 0 else 180.0)   # facing the pitch
	for bp: Vector2 in [Vector2(64.0, 64.0), Vector2(96.0, 64.0)]: I.add(props, "prop_trash_receptacle", "worn", A.q(sx, sz, bp.x, bp.y), 0.0)
	for gm: float in [f0.x + 1.5, f1.x - 1.5]:     # worn goal mouths, the centre spot
		dec.add(14, Vector2(sx * gm, sz * 80.0), 0.0, 3.0, 5.0, S.walk_y, Color(1, 1, 1, 0.55))
	dec.add(14, Vector2(sx * 80.0, sz * 80.0), 0.0, 3.0, 3.0, S.walk_y, Color(1, 1, 1, 0.4))
	_done_keep_pitch_clear(ctx, Vector2(62.0, 62.5), Vector2(98.5, 98.5))
	quit()

## C.done, but the shade groves (which plant any open lawn) stay off the playing field
func _done_keep_pitch_clear(ctx: Dictionary, a: Vector2, b: Vector2) -> void:
	A.fill_open(ctx)
	var props: K.Props = ctx.props
	var before := {}
	for k0: String in props.items: before[k0] = (props.items[k0] as Array).size()
	var ncol := props.col_items.size()
	C.groves(ctx)
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var r := Rect2(Vector2(minf(sx * a.x, sx * b.x), minf(sz * a.y, sz * b.y)), Vector2(absf(b.x - a.x), absf(b.y - a.y))).grow(1.0)
	for k: String in props.items.keys():     # only what the groves just added (trees, their benches and bins)
		var arr: Array = props.items[k]
		var keep: Array = arr.slice(0, int(before.get(k, 0)))
		for t: Transform3D in arr.slice(int(before.get(k, 0))):
			if not r.has_point(Vector2(t.origin.x, t.origin.z)): keep.append(t)
		props.items[k] = keep
	var cols: Array = props.col_items.slice(0, ncol)
	for c: Array in props.col_items.slice(ncol):
		var t2: Transform3D = c[2]
		if not r.has_point(Vector2(t2.origin.x, t2.origin.z)): cols.append(c)
	props.col_items = cols
	SL.wheel_stops(ctx.props, ctx.rr, ctx.stalls)
	var g: K.Ground = ctx.g
	var p0 := Vector2(sx * A.PROP, sz * A.PROP); var p1 := Vector2(sx * A.LEN, sz * A.LEN)
	K.painted_rect(g, minf(p0.x, p1.x), minf(p0.y, p1.y), maxf(p0.x, p1.x), maxf(p0.y, p1.y), ctx.paints, S.walk_y, "grass")
	A.finish(ctx.root, g, ctx.props, ctx.dec, String(ctx.name), ctx.stalls, ctx.poles)
