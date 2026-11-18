extends SceneTree
## Piece s_ind (industrial sample): one truck-street leg, from the junction tile (22 m) to 100 m, running along +z.
## Reused on all four legs by rotation, so it carries only street things: lanes, shoulders, the standard aprons
## (10 m at 40 m and 75 m, both sides: plots put their gates there), utility poles on one side (overhead power is
## normal in industrial areas), a cobra lamp on the other, kerb inlets, a hydrant, no-parking signs at the aprons.
## Heavy wear: truck lane wear, cracks, dark trench patches, pale concrete pads where trucks turn in, shoulder oil.
## Run once; never when locked.
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var root := Node3D.new(); root.name = "s_ind"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("s_ind")
	var ry := S.road_y
	var z0 := I.J; var z1 := I.LEN
	var paint: Array = [[-0.2, z0, -0.1, z1, "yellow"], [0.1, z0, 0.2, z1, "yellow"]]
	for sx: float in [-1.0, 1.0]:
		# edge line between lane and shoulder, broken across every apron
		var cur := z0
		for a: float in I.APRONS:
			paint.append([sx * I.LANE - 0.06, cur, sx * I.LANE + 0.06, a - I.APRON_W * 0.5, "white"]); cur = a + I.APRON_W * 0.5
		paint.append([sx * I.LANE - 0.06, cur, sx * I.LANE + 0.06, z1, "white"])
	K.painted_rect(g, -I.KERB, z0, I.KERB, z1, paint, ry)
	for sx: float in [-1.0, 1.0]:
		var ramps: Array = []
		for a: float in I.APRONS: ramps.append([a, I.APRON_W])
		S.sidewalk_strip(g, "z", sx * I.KERB, sx * I.PROP, z0, z1, ramps, "concrete", 2.0, 1.5, 0.0)
		# wear: truck lanes, shoulders where trucks park and drip, pale concrete pads where they swing in
		W.lane_wear(dec, rr, sx * I.LANE * 0.5, z0, z1, true, ry)
		for k in 6: W.oil(dec, rr, Vector2(sx * (I.LANE + 1.25), rr.randf_range(z0 + 3.0, z1 - 3.0)), 0.0, ry, 0.85)
		for a: float in I.APRONS:
			dec.add(4 + rr.randi() % 2, Vector2(sx * (I.LANE + 1.3), a), 0.0, 2.6, I.APRON_W - 1.0, ry, Color(0.5, 0.49, 0.47, 0.75))   # tinted grey (17 Nov audit: untinted tiles 4/5 read as white smears)
			dec.add(8, Vector2(sx * 3.2, a + 4.0), sx * 30.0, 0.7, 8.0, ry, Color(1, 1, 1, 0.55))
			dec.add(8, Vector2(sx * 3.2, a - 4.0), -sx * 30.0, 0.7, 8.0, ry, Color(1, 1, 1, 0.55))
			props.add("prop_sign_no_parking", "dirty", Vector3(sx * (I.KERB + 0.5), S.walk_y(0.0), a - I.APRON_W * 0.5 - 1.0), -90.0 * sx)
		# sidewalk: nobody sweeps an industrial sidewalk - dust and tyre dirt carried from the driveways, settlement
		# cracks in the slabs, dark stains under the poles where rust and bird mess run down
		var sw := sx * (I.KERB + I.PROP) * 0.5
		var wz := z0 + 0.5
		while wz < z1 - 1.0:
			var L := rr.randf_range(2.0, 5.0)
			dec.add(14, Vector2(sw + rr.randf_range(-0.4, 0.4), wz + L * 0.5), 0.0, rr.randf_range(1.2, 1.9), L, S.walk_y, Color(1, 1, 1, rr.randf_range(0.35, 0.65)))
			wz += L + rr.randf_range(0.5, 4.0)
		for a: float in I.APRONS:
			for o: float in [-3.0, 3.0]: dec.add(14, Vector2(sw, a + o), 0.0, 2.0, 3.0, S.walk_y, Color(1, 1, 1, 0.7))
		for k in 7: dec.add(0, Vector2(sw + rr.randf_range(-0.6, 0.6), rr.randf_range(z0 + 2.0, z1 - 2.0)), rr.randf_range(60, 120), rr.randf_range(1.2, 2.0), rr.randf_range(0.6, 1.0), S.walk_y, Color(0.3, 0.29, 0.28, 0.8))
		var gz := z0 + 1.0
		while gz < z1 - 2.0:
			dec.add(14, Vector2(sx * (I.KERB - 0.3), gz + 1.5), 0.0, 0.6, 3.0, ry, Color(1, 1, 1, 0.65)); gz += rr.randf_range(3.0, 6.0)
		props.add("prop_storm_drain_curb_inlet", "dirty", Vector3(sx * I.KERB, ry.call(0.0, 0.0), 25.0), 90.0 * -sx, false)
	W.cracks(dec, rr, -I.LANE, z0 + 1.0, I.LANE, z1 - 1.0, 22, ry, 0.35)
	for k in 4: dec.add(2 + k % 2, Vector2(rr.randf_range(-3.0, 3.0), rr.randf_range(z0 + 5.0, z1 - 5.0)), 90.0, rr.randf_range(2.5, 6.0), rr.randf_range(1.5, 3.0), ry, Color(1, 1, 1, 0.9))
	# power on the +x side (cross-arm across the line: line along z -> yaw 0), between the aprons; lamp opposite
	for pz: float in [28.0, 58.0, 88.0]:
		props.add("prop_utility_pole", "worn", Vector3(I.KERB + 1.3, S.walk_y(0.0), pz), 0.0)
	props.add("prop_lamp_cobra", "rusty", Vector3(-I.KERB - 1.0, S.walk_y(0.0), 57.0), 90.0)
	props.add("prop_lamp_cobra", "rusty", Vector3(-I.KERB - 1.0, S.walk_y(0.0), 93.0), 90.0)
	props.add("prop_hydrant_red", "rusty", Vector3(-I.KERB - 0.7, S.walk_y(0.0), 31.0), 90.0)   # clear of the kerb inlet at 25 m
	# bus stop for the shift workers (17 Nov: a stop each way in every area): departure side (-x), between the
	# driveways; the bus stops in the shoulder. A bench at the back of the sidewalk (a 1.9 m shelter would fill this
	# 2 m sidewalk and block it), a bin, red kerb.
	props.add("prop_bench_bus_stop", "worn", Vector3(-(I.PROP - 0.45), S.walk_y(0.0), 62.0), 90.0)
	I.add(props, "prop_bus_stop_sign", "worn", Vector3(-(I.KERB + 0.45), S.walk_y(0.0), 57.0), 90.0)
	props.add("prop_trash_receptacle", "dirty", Vector3(-(I.KERB + 0.5), S.walk_y(0.0), 65.6), 0.0)
	W.red_kerb(dec, Vector2(-I.KERB, 50.0), Vector2(-I.KERB, 68.0), Vector2(1.0, 0.0))
	dec.add(14, Vector2(-(I.KERB + 1.0), 62.0), 0.0, 1.6, 5.0, S.walk_y, Color(1, 1, 1, 0.6))
	W.red_kerb(dec, Vector2(-I.KERB, 26.5), Vector2(-I.KERB, 34.0), Vector2(1.0, 0.0))
	var wm := dec.build()
	if wm: root.add_child(wm)
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = g.build(); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"; var cs := CollisionShape3D.new(); cs.shape = mi.mesh.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	props.build(root, K)
	print("s_ind: ground tris %d, props %d" % [g.tri_count(), props.count()])
	K.save_piece(root, "s_ind")
	quit()
