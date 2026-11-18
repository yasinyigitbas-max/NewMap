extends SceneTree
## Piece j_apt (apartment band sample): all-way stop of two residential streets (the band's streets are quiet enough
## for stop signs, busy enough on foot for continental crosswalks on every leg). Tile |x|,|z| <= 20 out to the
## property lines; 6 m kerb returns; the grass parkway runs up to each crosswalk ramp. A stop sign and stop bar on
## every approach, street names on two corners, a hydrant, kerb inlets upstream of the crosswalks, the mailbox on a
## corner (where people pass), a bus bench on the far side of one approach. Wear: braking marks at the bars, oil
## where cars wait, worn crosswalk bars, a patch across the middle, corner sidewalk grime. Run once; never when locked.
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const XW := [12.6, 15.6]
const STOP := [16.6, 17.1]
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "j_apt"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("j_apt")
	var ry := S.road_y
	var J := A.J; var KB := A.KERB
	# ---- the crossing square plus the avenue mouths (|x| KB..J), with crosswalks across the avenue
	var pa: Array = []
	for sx: float in [-1.0, 1.0]:
		var z := -KB + 0.3
		while z + 0.6 <= KB - 0.3 + 1e-3:
			pa.append([minf(sx * XW[0], sx * XW[1]), z, maxf(sx * XW[0], sx * XW[1]), z + 0.6, "white"]); z += 1.2
	pa.append([STOP[0], -A.LANE, STOP[1], 0.0, "white"])        # westbound (east leg, arrives on z < 0)
	pa.append([-STOP[1], 0.0, -STOP[0], A.LANE, "white"])        # eastbound
	for sx: float in [-1.0, 1.0]:
		var a0 := minf(sx * STOP[1], sx * J); var a1 := maxf(sx * STOP[1], sx * J)
		pa.append([a0, -0.2, a1, -0.1, "yellow"]); pa.append([a0, 0.1, a1, 0.2, "yellow"])
	K.painted_rect(g, -J, -KB, J, KB, pa, ry)
	# ---- side street mouths (|z| KB..J)
	for sz: float in [-1.0, 1.0]:
		var ps: Array = []
		var x := -KB + 0.3
		while x + 0.6 <= KB - 0.3 + 1e-3:
			ps.append([x, minf(sz * XW[0], sz * XW[1]), x + 0.6, maxf(sz * XW[0], sz * XW[1]), "white"]); x += 1.2
		if sz < 0: ps.append([-A.LANE, -STOP[1], 0.0, -STOP[0], "white"])   # southbound, arrives from z < 0
		else: ps.append([0.0, STOP[0], A.LANE, STOP[1], "white"])
		var b0 := minf(sz * STOP[1], sz * J); var b1 := maxf(sz * STOP[1], sz * J)
		ps.append([-0.2, b0, -0.1, b1, "yellow"]); ps.append([0.1, b0, 0.2, b1, "yellow"])
		K.painted_rect(g, -KB, minf(sz * KB, sz * J), KB, maxf(sz * KB, sz * J), ps, ry)
	# ---- corners
	var xc := (XW[0] + XW[1]) * 0.5
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var c := Vector2(sx * (KB + A.R), sz * (KB + A.R))
			var a0 := atan2(0.0, -sx); var a1 := atan2(-sz, 0.0)
			if a1 - a0 > PI: a1 -= TAU
			if a0 - a1 > PI: a1 += TAU
			var arc := K.arc(c, A.R, a0, a1, 12)
			var fil := arc.duplicate(); fil.append(Vector2(sx * KB, sz * KB)); g.poly("asphalt", fil, ry)
			var dd := (arc[1] - arc[0]).normalized(); var left := Vector2(dd.y, -dd.x)
			g.wall_line("curb", arc, ry, S.walk_y, signf(left.dot((arc[0] - c).normalized())))
			var patch := arc.duplicate()
			patch.append(Vector2(sx * (KB + A.R), sz * A.PROP)); patch.append(Vector2(sx * A.PROP, sz * A.PROP)); patch.append(Vector2(sx * A.PROP, sz * (KB + A.R)))
			g.poly("concrete", patch, S.walk_y)
			# straight parts: parkway (grass, concrete ramp at the crosswalk) + sidewalk, along both streets
			var t := KB + A.R
			_pkw(g, "x", sz * KB, sz * A.PKW, sx * t, sx * J, sx * xc)
			g.rect("concrete", minf(sx * t, sx * J), minf(sz * A.PKW, sz * A.PROP), maxf(sx * t, sx * J), maxf(sz * A.PKW, sz * A.PROP), S.walk_y)
			_pkw(g, "z", sx * KB, sx * A.PKW, sz * t, sz * J, sz * xc)
			g.rect("concrete", minf(sx * A.PKW, sx * A.PROP), minf(sz * t, sz * J), maxf(sx * A.PKW, sx * A.PROP), maxf(sz * t, sz * J), S.walk_y)
			# people wait at the ramps; the corner gets the dirt of every walker
			dec.add(14, Vector2(sx * xc, sz * (KB + 1.6)), 0.0, 3.0, 2.2, S.walk_y, Color(1, 1, 1, 0.5))
			dec.add(14, Vector2(sx * (KB + 1.6), sz * xc), 90.0, 3.0, 2.2, S.walk_y, Color(1, 1, 1, 0.5))
			var mid := c + Vector2(-sx, -sz).normalized() * (A.R - 1.0)
			dec.add(14, mid, 45.0, 2.6, 2.6, S.walk_y, Color(1, 1, 1, 0.45))
	# ---- stop signs at the right-hand corner of each approach, facing the arriving traffic
	props.add("prop_sign_stop", "worn", Vector3(-(KB + 0.6), S.walk_y(0.0), -(STOP[1] + 0.3)), 180.0)    # southbound
	props.add("prop_sign_stop", "worn", Vector3(KB + 0.6, S.walk_y(0.0), STOP[1] + 0.3), 0.0)             # northbound
	props.add("prop_sign_stop", "worn", Vector3(STOP[1] + 0.3, S.walk_y(0.0), -(KB + 0.6)), 90.0)         # westbound
	props.add("prop_sign_stop", "worn", Vector3(-(STOP[1] + 0.3), S.walk_y(0.0), KB + 0.6), -90.0)        # eastbound
	props.add("prop_sign_street_names", "worn", Vector3(KB + 2.4, S.walk_y(0.0), -(KB + 2.4)), 45.0)
	props.add("prop_sign_street_names", "worn", Vector3(-(KB + 2.4), S.walk_y(0.0), KB + 2.4), 45.0)
	I.add(props, "prop_hydrant_red", "rusty", Vector3(-(KB + 0.7), S.walk_y(0.0), -16.2), 90.0)
	W.red_kerb(dec, Vector2(-KB, -J), Vector2(-KB, -(KB + A.R)), Vector2(1.0, 0.0))
	I.add(props, "prop_usps_collection_box", "worn", Vector3(A.PROP - 0.6, S.walk_y(0.0), 18.4), 90.0)
	for e: Array in [[19.4, -KB, 180.0], [-19.4, KB, 0.0], [KB, 19.4, -90.0], [-KB, -19.4, 90.0]]:
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(float(e[0]), ry.call(0.0), float(e[1])), float(e[2]), false)
	props.add("prop_manhole_cover", "worn", Vector3(1.8, ry.call(0.0) + 0.002, -1.8), 0.0, false)
	# ---- wear: stopping and starting at every bar
	for q: Array in [[18.5, -A.LANE * 0.5, 90.0], [-18.5, A.LANE * 0.5, 90.0], [A.LANE * 0.5, 18.5, 0.0], [-A.LANE * 0.5, -18.5, 0.0]]:
		for wp: float in [-0.8, 0.8]:
			var o := Vector2(wp, 0.0) if float(q[2]) == 0.0 else Vector2(0.0, wp)
			dec.add(8, Vector2(float(q[0]), float(q[1])) + o, float(q[2]), 0.45, 4.0, ry, Color(1, 1, 1, 0.45))
		W.oil(dec, rr, Vector2(float(q[0]), float(q[1])), float(q[2]), ry, 0.7)
	dec.add(3, Vector2(0.0, 2.0), 90.0, 1.3, 2.0 * KB, ry, Color(1, 1, 1, 0.9))
	W.cracks(dec, rr, -KB, -KB, KB, KB, 10, ry, 0.45)
	for k in 6:   # crosswalk bars worn in the wheel paths
		var sx2 := -1.0 if k % 2 == 0 else 1.0
		dec.add(14, Vector2(sx2 * xc, rr.randf_range(-KB + 0.8, KB - 0.8)), 0.0, 3.0, 0.9, ry, Color(1, 1, 1, 0.35))
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("j_apt: ground tris %d, props %d" % [g.tri_count(), props.count()])
	K.save_piece(root, "j_apt")
	quit()

## parkway strip between the tangent point and the tile edge: grass, with a concrete ramp across it at the crosswalk
func _pkw(g: K.Ground, along: String, kerb: float, pkw: float, a: float, b: float, c: float) -> void:
	var lo := minf(a, b); var hi := maxf(a, b)
	var r0 := c - 1.5; var r1 := c + 1.5
	if r0 > lo: S.sidewalk_strip(g, along, kerb, pkw, lo, r0, [], "grass")
	S.sidewalk_strip(g, along, kerb, pkw, maxf(lo, r0), minf(hi, r1), [[c, 3.0]], "concrete", 1.4, 0.0, 0.6)
	if hi > r1: S.sidewalk_strip(g, along, kerb, pkw, r1, hi, [], "grass")
