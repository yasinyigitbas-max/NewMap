extends SceneTree
## Piece s_strip_side (commercial strip sample): one side-street leg from the junction tile (|z| 26) to 100 m, along +z.
## Used on both legs (yaw 0 south, yaw 180 north): street things only. 1+1 lanes, double yellow, parallel parking with
## T marks (free, no meters: the strip's customers park in the lots, the side street serves the small shops and the
## workers), kerb, 3 m sidewalk with jacarandas in round wells, cobra lamps, driveway aprons at 45 m and 80 m on both
## sides, a hydrant with its red kerb, kerb inlets. Wear: wheel paths, oil under the stalls, cracks, gutter grime,
## sidewalk dirt. Run once; never when locked.
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const Z0 := 26.0
const Z1 := 100.0
const STALL := 6.7
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "s_strip_side"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("s_strip_side")
	var ry := S.road_y
	var p: Array = [[-0.2, Z0, -0.1, Z1, "yellow"], [0.1, Z0, 0.2, Z1, "yellow"]]
	var hydrant := 62.0
	for sx: float in [-1.0, 1.0]:
		# stalls: from 6 m past the crosswalk, clear of the aprons (1.5 m either side) and the hydrant (east side, 4.5 m)
		var blocked: Array = []
		for a: float in L.APR_S: blocked.append([a - L.APR_S_W * 0.5 - 1.5, a + L.APR_S_W * 0.5 + 1.5])
		if sx > 0: blocked.append([hydrant - 4.5, hydrant + 4.5])
		var d := Z0 + 4.0
		while d + STALL <= Z1:
			var bad := false
			for r: Array in blocked:
				if d + STALL > float(r[0]) and d < float(r[1]): bad = true
			if bad:
				d += 1.0; continue
			for e: float in [d, d + STALL]:
				p.append([minf(sx * L.LANE_S, sx * (L.LANE_S + 1.8)), e - 0.05, maxf(sx * L.LANE_S, sx * (L.LANE_S + 1.8)), e + 0.05, "white"])
			if rr.randf() < 0.75: W.oil(dec, rr, Vector2(sx * (L.LANE_S + 1.2), d + STALL * 0.5), 0.0, ry, 0.8)
			d += STALL
		W.lane_wear(dec, rr, sx * L.LANE_S * 0.5, Z0, Z1, true, ry)
		W.cracks(dec, rr, minf(sx * 0.3, sx * L.KERB_S), Z0 + 1.0, maxf(sx * 0.3, sx * L.KERB_S), Z1 - 1.0, 12, ry, 0.4)
		var gz := Z0 + 1.0
		while gz < Z1 - 1.5:
			dec.add(14, Vector2(sx * (L.KERB_S - 0.3), gz + 1.2), 0.0, 0.5, 2.4, ry, Color(1, 1, 1, rr.randf_range(0.4, 0.6)))
			gz += rr.randf_range(4.0, 8.0)
	K.painted_rect(g, -L.KERB_S, Z0, L.KERB_S, Z1, p, ry)
	# ---- sidewalks with the apron ramps, tree wells, furniture
	var wells := [34.0, 58.0, 70.0, 92.0]
	for sx: float in [-1.0, 1.0]:
		var ramps: Array = []
		for a: float in L.APR_S: ramps.append([a, L.APR_S_W])
		var side_wells: Array = []
		for wz0: float in wells:
			if not (sx > 0 and absf(wz0 - hydrant) < 3.0): side_wells.append(wz0)
		S.sidewalk_with_wells(g, "z", sx * L.KERB_S, sx * L.PROP_S, Z0, Z1, ramps, side_wells, "concrete", 1.5, 1.2, 0.0)
		for wz: float in side_wells:
			props.add("tree_jacaranda_a" if int(wz + sx) % 2 == 0 else "tree_jacaranda_b", "normal", Vector3(sx * (L.KERB_S + 0.75), S.walk_y(0.0) - 0.06, wz), wz * 41.0 + sx * 90.0)
			if rr.randf() < 0.5: dec.add(rr.randi() % 2, Vector2(sx * (L.KERB_S + 1.9), wz + rr.randf_range(-0.6, 0.6)), rr.randf_range(60, 120), 1.8, 0.8, S.walk_y, Color(1, 1, 1, 0.55))
		props.add("prop_lamp_cobra", "rusty", Vector3(sx * (L.KERB_S + 0.6), S.walk_y(0.0), 52.0 if sx < 0 else 86.0), -90.0 * sx)
		var wz2 := Z0 + 0.5
		while wz2 < Z1 - 1.0:
			var Lw := rr.randf_range(2.0, 5.0)
			dec.add(14, Vector2(sx * (L.KERB_S + rr.randf_range(1.0, 2.2)), wz2 + Lw * 0.5), 0.0, 1.4, Lw, S.walk_y, Color(1, 1, 1, rr.randf_range(0.3, 0.55)))
			wz2 += Lw + rr.randf_range(1.0, 5.0)
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * L.KERB_S, ry.call(0.0), 74.0), -90.0 * sx, false)
		props.add("prop_trash_receptacle", "worn", Vector3(sx * (L.KERB_S + 0.75), S.walk_y(0.0), 30.0), 0.0)
	props.add("prop_hydrant_red", "rusty", Vector3(L.KERB_S + 0.8, S.walk_y(0.0), hydrant), -90.0)
	W.red_kerb(dec, Vector2(L.KERB_S, hydrant - 4.5), Vector2(L.KERB_S, hydrant + 4.5), Vector2(-1.0, 0.0))
	props.add("prop_sign_no_parking", "worn", Vector3(-(L.KERB_S + 0.4), S.walk_y(0.0), 40.0), 90.0)
	props.add("prop_manhole_cover", "worn", Vector3(-1.6, ry.call(0.0) + 0.002, 66.0), 0.0, false)
	dec.add(2, Vector2(1.6, 47.0), 0.0, 2.4, 2.2, ry, Color(1, 1, 1, 0.85))
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("s_strip_side: ground tris %d, props %d" % [g.tri_count(), props.count()])
	K.save_piece(root, "s_strip_side")
	quit()
