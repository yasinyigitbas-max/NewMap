extends SceneTree
## Piece i_life_w800_n1400 (industrial zone polish, 19 Nov, Yasin: "do a polish pass on the whole zone"; not locked).
## A LIFE OVERLAY for the locked industrial sample (i_ne, i_nw, i_se, i_sw at J Ave x 3rd St), the way d_pilot / d_cc
## serve their samples: the locked pieces are never touched; this piece loads them read-only and adds, where their own
## buildings, props, doors and parked cars leave room (G.place), what their businesses still lack:
##  - a stop sign inside every yard exit (trucks pull out onto the truck streets),
##  - a fire hydrant in each yard (the mill, the stockhouse and the warehouses need one by code),
##  - a workers' break spot per block (picnic table, bench, bin, a soda machine) behind the frontage buildings,
##  - bike racks and bins by the offices, cones and drums where the yards work.
## Same frame as the sample (junction at its origin). Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_life_w800_n1400"
const SAMPLE := ["i_ne", "i_nw", "i_se", "i_sw", "j_ind", "s_ind"]
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var tmp := Node3D.new(); get_root().add_child(tmp)
	var nodes: Array = []
	for pc: String in SAMPLE:
		var n: Node3D = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % pc) as PackedScene).instantiate()
		tmp.add_child(n); nodes.append(n)
	for k in 2: await process_frame
	var obs := G.obstacles_scene(nodes)
	tmp.queue_free()
	var root := Node3D.new(); root.name = NAME
	var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var n_in := 0; var tried := 0
	# per quadrant: [sx, sz, what the yard is for]
	for qd: Array in [[1.0, -1.0, "mill"], [-1.0, -1.0, "dc"], [1.0, 1.0, "fire"], [-1.0, 1.0, "paving"]]:
		var sx: float = qd[0]; var sz: float = qd[1]
		# the driveways (aprons at 40 / 75 m on both frontages) and their lanes into the yard stay clear
		var kp := [[35.5, 8.0, 44.5, 36.0], [70.5, 8.0, 79.5, 36.0], [8.0, 35.5, 36.0, 44.5], [8.0, 70.5, 36.0, 79.5]]
		var face_x := 0.0 if sz < 0.0 else 180.0       # facing the cross street (drivers leaving toward it)
		var face_z := -90.0 * sx                        # facing the side street
		for ap: float in [40.0, 75.0]:
			tried += 2
			if G.place(props, obs, rr, sx, sz, "prop_sign_stop", "dirty", ap + 3.8, 10.0, ap + 4.6, 13.0, face_x, [], 3.0): n_in += 1
			if G.place(props, obs, rr, sx, sz, "prop_sign_stop", "dirty", 10.0, ap + 3.8, 13.0, ap + 4.6, face_z, [], 3.0): n_in += 1
		tried += 1
		if G.place(props, obs, rr, sx, sz, "prop_hydrant_red", "rusty", 12.0, 12.0, 96.0, 96.0, 0.0, kp): n_in += 1
		var spot: Array = [["prop_picnic_table", "worn"], ["prop_trash_receptacle", "dirty"], ["prop_vending_soda", "clean"]]
		tried += spot.size(); n_in += G.spot(props, obs, rr, sx, sz, spot, 26.0, 26.0, 40.0, 40.0, 45.0, kp)
		var bins: Array = [["prop_bike_rack", "rusty"], ["prop_trash_cart_black", "worn"], ["prop_trash_cart_blue", "worn"], ["prop_recycling_receptacle", "worn"]]
		tried += bins.size(); n_in += G.spot(props, obs, rr, sx, sz, bins, 22.0, 24.0, 60.0, 34.0, 0.0, kp)
		var work: Array = [["prop_cone_28in", "dirty"], ["prop_cone_28in", "dirty"], ["prop_channelizer_drum", "dirty"], ["prop_channelizer_drum", "dirty"], ["prop_cone_18in", "dirty"]]
		if String(qd[2]) == "mill": work.append_array([["prop_dumpster_3yd_green", "rusty"], ["prop_k_rail", "dirty"]])
		if String(qd[2]) == "dc": work.append_array([["prop_container_20ft_white", "dirty"], ["prop_dumpster_3yd_blue", "rusty"]])
		if String(qd[2]) == "fire": work.append_array([["prop_hose_reel_cart", "worn"], ["prop_water_barrier_white", "dirty"]])
		if String(qd[2]) == "paving": work.append_array([["prop_barricade_type1", "worn"], ["prop_water_barrier_orange", "dirty"]])
		tried += work.size(); n_in += G.spot(props, obs, rr, sx, sz, work, 40.0, 40.0, 92.0, 92.0, 0.0, kp)
		# wear under the break spot: foot grime where people stand and sit
		dec.add(14, Vector2(sx * 33.0, sz * 33.0), 45.0, 4.0, 3.0, S.walk_y, Color(1, 1, 1, 0.35))
	print("LIFE %s: %d of %d items found a free spot" % [NAME, n_in, tried])
	var wm := dec.build()
	if wm: root.add_child(wm)
	props.build(root, K)
	root.set_meta("stalls", [])
	K.save_piece(root, NAME)
	quit()
