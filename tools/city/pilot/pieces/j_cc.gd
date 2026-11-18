extends SceneTree
## Piece j_cc (city centre): the j_amber_10th junction with the city-centre cross-section - no parking lanes, kerbs on
## the lane edges, sidewalks 6.9 m (Amber) and 6.4 m (10th) wide (Yasin 16 Nov: "widen the sidewalks in the city
## center with tall blocks"). Same paint, signals and furniture logic; the corner radius stays 6 m.
## Original: the signalized junction of Amber Ave (divided, 2+2 lanes) and 10th St (1+1 lanes).
## Authoring script: run ONCE in the preview project, writes map_dc/coronado/city_kit/pieces/j_cc.scn.
## Never re-run once the piece is locked (map_dc/coronado/city_kit/locked.json).
## Covers |z| <= 17.5 along Amber and |x| <= 23.5 along 10th, out to the building lines.

const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")

func _init() -> void: _run.call_deferred()

func _run() -> void:
	S.hill_on = false
	S.A_KERB = S.A_LANE; S.T_KERB = S.T_LANE      # city centre: no parking lanes
	var root := Node3D.new(); root.name = "j_cc"
	var g := K.Ground.new()
	var ry := S.road_y
	# --- asphalt with paint, cut exactly (one plane)
	var paint: Array = []
	# continental crosswalk bars across Amber (bars run with the traffic, 0.6 m wide, 0.6 m gaps)
	for sz in [-1.0, 1.0]:
		var z0: float = S.XW_A[0] * sz; var z1: float = S.XW_A[1] * sz
		var x := -S.A_KERB + 0.3
		while x + 0.6 <= S.A_KERB - 0.3 + 1e-3:
			paint.append([x, minf(z0, z1), x + 0.6, maxf(z0, z1), "white"]); x += 1.2
	# stop bars on Amber: southbound (west half, north leg), northbound (east half, south leg)
	paint.append([-S.A_LANE, -S.STOP_A[1], -S.A_MED, -S.STOP_A[0], "white"])
	paint.append([S.A_MED, S.STOP_A[0], S.A_LANE, S.STOP_A[1], "white"])
	K.painted_rect(g, -S.A_KERB, -S.J_Z, S.A_KERB, S.J_Z, paint, ry)
	# 10th legs
	for sx in [-1.0, 1.0]:
		var p2: Array = []
		var xa: float = S.XW_T[0] * sx; var xb: float = S.XW_T[1] * sx
		var n := 9; var span := S.T_KERB * 2.0 - 0.6; var used := n * 0.6 + (n - 1) * 0.6; var z := -S.T_KERB + 0.3 + (span - used) * 0.5
		for i in n:
			p2.append([minf(xa, xb), z, maxf(xa, xb), z + 0.6, "white"]); z += 1.2
		# stop bar: eastbound uses the south half (z > 0) of the west leg, westbound the north half of the east leg
		if sx < 0: p2.append([-S.STOP_T[1], 0.0, -S.STOP_T[0], S.T_LANE, "white"])
		else: p2.append([S.STOP_T[0], -S.T_LANE, S.STOP_T[1], 0.0, "white"])
		# double yellow centre line from the crosswalk outward
		var c0: float = (S.XW_T[1] + 0.3); var c1: float = S.J_X
		p2.append([minf(c0 * sx, c1 * sx), -0.2, maxf(c0 * sx, c1 * sx), -0.1, "yellow"])
		p2.append([minf(c0 * sx, c1 * sx), 0.1, maxf(c0 * sx, c1 * sx), 0.2, "yellow"])
		K.painted_rect(g, minf(S.A_KERB * sx, S.J_X * sx), -S.T_KERB, maxf(S.A_KERB * sx, S.J_X * sx), S.T_KERB, p2, ry)
	# --- the four corners: asphalt fillet, kerb return, corner sidewalk, two directional ramps each
	var props := K.Props.new()
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_corner(g, props, sx, sz)
	# ageing: turning tyre arcs through the box, scuffed crosswalk bars in the wheel paths, cracks, one patch,
	# scuffed ramp landings where everyone waits for the light
	var dec := K.Decals.new(); var rr := W.rng_for("j_cc")
	for q: Array in [[-6.0, -4.0, 35.0], [6.0, 4.0, 35.0], [-5.0, 4.5, -40.0], [5.0, -4.5, -40.0], [-1.5, 0.0, 10.0], [1.5, 0.0, -10.0]]:
		dec.add(8, Vector2(q[0], q[1]), q[2], 0.5, 8.0, S.road_y, Color(1, 1, 1, 0.35))
	for zc: float in [-14.0, 14.0]:
		for lx: float in [-7.45, -4.15, 4.15, 7.45]:
			for wp: float in [-0.8, 0.8]:
				dec.add(14, Vector2(lx + wp, zc), 0.0, 0.7, 3.2, S.road_y, Color(1, 1, 1, 0.7))
	W.cracks(dec, rr, -10.0, -5.0, 10.0, 5.0, 10, S.road_y, 0.5)
	for lx: float in [-7.45, -4.15, 4.15, 7.45]: W.lane_wear(dec, rr, lx, -S.J_Z, S.J_Z, true, S.road_y)
	for lz: float in [-1.65, 1.65]: W.lane_wear(dec, rr, lz, -S.J_X, S.J_X, false, S.road_y)
	dec.add(2, Vector2(3.2, -1.5), 12.0, 2.4, 2.0, S.road_y, Color(1, 1, 1, 0.85))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			dec.add(14, Vector2(sx * (S.A_KERB + 1.6), sz * 14.0), 0.0, 2.6, 3.4, S.walk_y, Color(1, 1, 1, 0.45))
			dec.add(14, Vector2(sx * 19.8, sz * (S.T_KERB + 1.6)), 90.0, 2.6, 3.4, S.walk_y, Color(1, 1, 1, 0.45))
	root.add_child(dec.build())
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("j_cc: ground tris %d, props %d" % [g.tri_count(), props.count()])
	K.save_piece(root, "j_cc")
	quit()

func _corner(g: K.Ground, props: K.Props, sx: float, sz: float) -> void:
	var r := S.R_CORNER
	var tz := S.T_KERB + r      # where the Amber kerb stops being straight
	var tx := S.A_KERB + r      # where the 10th kerb stops being straight
	var c := Vector2(sx * tx, sz * tz)
	var a0 := atan2(0.0, -sx); var a1 := atan2(-sz, 0.0)
	if a1 - a0 > PI: a1 -= TAU
	if a0 - a1 > PI: a1 += TAU
	var ap := K.arc(c, r, a0, a1, 12)
	# asphalt fillet between the arc and the junction box corner
	var fil := ap.duplicate(); fil.append(Vector2(sx * S.A_KERB, sz * S.T_KERB))
	g.poly("asphalt", fil, S.road_y)
	# kerb face along the return, facing the road (away from the arc centre)
	var d := (ap[1] - ap[0]).normalized(); var left := Vector2(d.y, -d.x)
	var out := signf(left.dot((ap[0] - c).normalized()))
	g.wall_line("curb", ap, S.road_y, S.walk_y, out)
	# corner sidewalk polygon (arc, then out to the building corner)
	var sp := ap.duplicate()
	sp.append(Vector2(sx * tx, sz * S.T_BLD)); sp.append(Vector2(sx * S.A_BLD, sz * S.T_BLD)); sp.append(Vector2(sx * S.A_BLD, sz * tz))
	g.poly("concrete", sp, S.walk_y)
	# straight sidewalk strips inside the tile, each with the ramp that serves its crosswalk
	var zc := (S.XW_A[0] + S.XW_A[1]) * 0.5
	S.sidewalk_strip(g, "z", sx * S.A_KERB, sx * S.A_BLD, minf(sz * tz, sz * S.J_Z), maxf(sz * tz, sz * S.J_Z), [[sz * zc, 1.8]])
	var xc := (S.XW_T[0] + S.XW_T[1]) * 0.5
	S.sidewalk_strip(g, "x", sz * S.T_KERB, sz * S.T_BLD, minf(sx * tx, sx * S.J_X), maxf(sx * tx, sx * S.J_X), [[sx * xc, 1.8]])
	# --- corner furniture
	# signal pole on the corner sidewalk, 1 m behind the kerb return, clear of both ramps. The arc's centre c lies inside
	# the block, so the sidewalk is between c and the arc: r - 1 (17 Nov audit: r + 1 stood it on the asphalt fillet)
	var mid := c + Vector2(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5)) * (r - 1.0)
	var pole := Vector3(mid.x, S.walk_y(mid.x), mid.y)
	# mast arms carry the Amber heads on the far-right corner of each Amber approach: SW (southbound) and NE (northbound);
	# 10th St gets post-mounted heads on NW (westbound) and SE (eastbound), plus the street name signs there.
	var amber_corner := (sx < 0 and sz > 0) or (sx > 0 and sz < 0)
	if amber_corner:
		# the arm reaches over Amber: from the SW corner east (+X, heads face north), from the NE corner west (heads face south)
		props.add("prop_signal_mast_arm", "worn", pole, 180.0 if sx < 0 else 0.0)   # model arm points -X, heads face +Z
	else:
		props.add("prop_signal_post", "worn", pole, 90.0 if sx < 0 else -90.0)   # heads face the 10th St traffic arriving
		var ns := pole + Vector3(0.0, 0.0, sz * 1.2)
		props.add("prop_sign_street_names", "clean", ns, 45.0 * sx * sz)
	# hydrant on two diagonal corners (NE, SW), 1 m behind the 10th kerb, past the ramp
	if amber_corner:
		var hx := sx * 22.6; var hz := sz * (S.T_KERB + 1.0)
		props.add("prop_hydrant_red", "worn", Vector3(hx, S.walk_y(hx), hz), 0.0 if sz > 0 else 180.0)
	# kerb inlet on Amber just upstream of the crosswalk; on 10th at the foot of the hill (east leg)
	var iz := sz * 16.6
	props.add("prop_storm_drain_curb_inlet", "worn", Vector3(sx * S.A_KERB, S.road_y(sx * S.A_KERB), iz), -90.0 * sx, false)
	if sx > 0:
		props.add("prop_storm_drain_curb_inlet", "worn", Vector3(23.2, S.road_y(23.2), sz * S.T_KERB), 0.0 if sz < 0 else 180.0, false)
