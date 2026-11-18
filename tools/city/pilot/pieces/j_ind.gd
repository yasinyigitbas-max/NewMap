extends SceneTree
## Piece j_ind (industrial sample): 4-way stop of two truck streets. No signals (low traffic), a stop sign and stop bar
## on every approach (right-hand corner), 12 m kerb returns for semis, no crosswalks (nobody walks here much: the
## sidewalks stay, narrow). Each corner lot is rounded to the kerb return and fenced with chain-link (lots run to the
## corner). Heavy wear: truck turning arcs, oil where trucks wait at the stop bars. Run once; never when locked.
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "j_ind"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("j_ind")
	var ry := S.road_y
	# stop bars on the right-hand half of every approach, 0.6 m wide, at 20.0 - 20.6 m
	var bars := [[0.0, 20.0, I.LANE, 20.6, "white"], [-I.LANE, -20.6, 0.0, -20.0, "white"]]
	K.painted_rect(g, -I.KERB, -I.J, I.KERB, I.J, bars, ry)
	K.painted_rect(g, I.KERB, -I.KERB, I.J, I.KERB, [[20.0, -I.LANE, 20.6, 0.0, "white"]], ry)
	K.painted_rect(g, -I.J, -I.KERB, -I.KERB, I.KERB, [[-20.6, 0.0, -20.0, I.LANE, "white"]], ry)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var c := Vector2(sx * (I.KERB + I.R), sz * (I.KERB + I.R))
			var a0 := atan2(0.0, -sx); var a1 := atan2(-sz, 0.0)
			if a1 - a0 > PI: a1 -= TAU
			if a0 - a1 > PI: a1 += TAU
			var outer := K.arc(c, I.R, a0, a1, 14)
			var inner := K.arc(c, I.R - (I.PROP - I.KERB), a0, a1, 14)
			var fil := outer.duplicate(); fil.append(Vector2(sx * I.KERB, sz * I.KERB)); g.poly("asphalt", fil, ry)
			var d := (outer[1] - outer[0]).normalized(); var left := Vector2(d.y, -d.x)
			g.wall_line("curb", outer, ry, S.walk_y, signf(left.dot((outer[0] - c).normalized())))
			var sw := outer.duplicate(); var inr := inner.duplicate(); inr.reverse(); sw.append_array(inr); g.poly("concrete", sw, S.walk_y)
			# the corner lot between the rounded property line and the tile edges (gravel yard)
			var lot := inner.duplicate()
			lot.append(Vector2(sx * I.J, sz * I.PROP)); lot.append(Vector2(sx * I.J, sz * I.J)); lot.append(Vector2(sx * I.PROP, sz * I.J))
			g.poly("gravel", lot, S.walk_y)
			# straight sidewalk ends inside the tile
			S.sidewalk_strip(g, "z", sx * I.KERB, sx * I.PROP, minf(sz * (I.KERB + I.R), sz * I.J), maxf(sz * (I.KERB + I.R), sz * I.J), [], "concrete")
			S.sidewalk_strip(g, "x", sz * I.KERB, sz * I.PROP, minf(sx * (I.KERB + I.R), sx * I.J), maxf(sx * (I.KERB + I.R), sx * I.J), [], "concrete")
			# chain-link along the rounded lot corner
			for k in inner.size() - 1:
				I.lot_fence(props, inner[k] + (inner[k] - c).normalized() * -0.25, inner[k + 1] + (inner[k + 1] - c).normalized() * -0.25)
			# corner sidewalk dirt: the slab nobody sweeps, darker where people wait to cross and where trucks cut the kerb
			var midr := I.R - (I.PROP - I.KERB) * 0.5
			for k in 5:
				var t := (k + 0.5) / 5.0; var ang := lerpf(a0, a1, t)
				dec.add(14, c + Vector2(cos(ang), sin(ang)) * midr, rad_to_deg(-ang), 1.6, rr.randf_range(2.0, 3.2), S.walk_y, Color(1, 1, 1, rr.randf_range(0.4, 0.7)))
			dec.add(0, c + Vector2(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5)) * midr, rr.randf_range(0, 180), 1.6, 0.8, S.walk_y, Color(0.3, 0.29, 0.28, 0.8))
			# truck turning arc and oil from trucks waiting at the stop bar
			var mid := c + Vector2(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5)) * (I.R + 3.0)
			dec.add(8, mid, rad_to_deg((a0 + a1) * 0.5) + 90.0, 0.7, 11.0, ry, Color(1, 1, 1, 0.55))
	# stop signs at the right-hand corner of each approach, facing the arriving traffic
	props.add("prop_sign_stop", "worn", Vector3(I.KERB + 0.6, S.walk_y(0.0), 21.2), 0.0)       # northbound, arrives from +z
	props.add("prop_sign_stop", "worn", Vector3(-I.KERB - 0.6, S.walk_y(0.0), -21.2), 180.0)
	props.add("prop_sign_stop", "worn", Vector3(21.2, S.walk_y(0.0), -I.KERB - 0.6), 90.0)      # westbound, arrives from +x
	props.add("prop_sign_stop", "worn", Vector3(-21.2, S.walk_y(0.0), I.KERB + 0.6), -90.0)
	for q: Vector2 in [Vector2(2.1, 18.0), Vector2(-2.1, -18.0), Vector2(18.0, -2.1), Vector2(-18.0, 2.1)]:
		W.oil(dec, rr, q, 0.0 if absf(q.y) > absf(q.x) else 90.0, ry, 0.8)
	W.cracks(dec, rr, -I.KERB, -I.KERB, I.KERB, I.KERB, 12, ry, 0.4)
	for k in 3: dec.add(2 + k % 2, Vector2(rr.randf_range(-5, 5), rr.randf_range(-5, 5)), rr.randf_range(0, 90), 3.5, 2.5, ry, Color(1, 1, 1, 0.9))
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("j_ind: ground tris %d, props %d" % [g.tri_count(), props.count()])
	K.save_piece(root, "j_ind")
	quit()
