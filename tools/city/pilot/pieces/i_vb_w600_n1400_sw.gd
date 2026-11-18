extends SceneTree
## Piece i_vb_w600_n1400_sw (industrial growth, VARIANT B "fleet", third dressing; 19 Nov, Yasin: "roll out to your
## whole zone"; not locked). Site: SW corner of 3rd St x G Ave, world (-700..-600, -1400..-1300). The sample's i_se
## (fire station block) is its west neighbour, the gritty edge's g_v2_g4nw its south one. G Ave here is a RESIDENTIAL
## street rising 1 m to mid-block, with an alley mouth at 54-60 m: the block is draped onto that slope (G.measure_rows,
## G.drape), and its street side is a planted edge, not a yard fence.
## ISLAND MOVERS AND SELF STORAGE: a moving company and its storage. People come to the office on 3rd St (walk-in) to
## book a move or rent a unit. The vans load at the warehouse, and the storage rows and lock-ups line the yard.
## Planner's reasons:
##  - The office holds the 3rd St corner. The vans use 3rd St's own apron (38 m). Customers with cars come in at the
##    alley mouth on G Ave (a residential street has no driveways) and drive down the storage lane.
##  - Facing the houses' street: a grass strip with eucalyptus and torrey pines behind a stucco wall, the alley gate in it.
##  - South edge (the gritty block leaves its inner edges open): this block's block wall, opaque. West edge: the
##    sample's chain-link, nothing doubled. 3rd St: chain-link between buildings, with the storage sheds (opaque) behind.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_vb_w600_n1400_sw"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := -1.0; var sz := 1.0
	var J := Vector3(-600.0, 2.0, -1400.0)
	var m: Dictionary = await G.measure(self, J, sx, sz)
	var mr: Dictionary = await G.measure_rows(self, J, sx, sz, 100.0, 100.0, [NAME])
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var stl: Array = []
	G.floor_rows(g, mr, sx, sz, [[9.0, 22.0, 16.0, 100.0, "grass"], [17.0, 64.0, 43.0, 99.0, "gravel"]])
	var B: Array = []
	var fx := G.front_x(m, 22.0, 36.0)
	B.append([G.put(bl, props, sx, sz, "x", 23.0, fx, "ck/ck_svc_bank_pharm", "island_movers_office"), "ck/ck_svc_bank_pharm"])
	# storage rows: three sheds facing the 3rd St side lane, three back to back facing the middle lane
	for k in 3:
		B.append([G.put(bl, props, sx, sz, "x", 45.0 + k * 18.2, 24.0, "ck/mod_stg_row_roofed", "storage_n%d" % k, false), "ck/mod_stg_row_roofed"])
		var nb := K.building(bl, "ck/mod_stg_row_roofed", G.q(sx, sz, 54.0 + k * 18.2, 42.5), 0.0, "storage_s%d" % k, 0.85)
		B.append([[nb, 18.0, 12.0], "ck/mod_stg_row_roofed"])
	# lock-ups along the south: two rows back to back (doors to the lane, doors to the van park)
	var gu := 45.0; var k2 := 0
	while gu < 96.0:
		var fold := "garages/single_stucco_flat" if k2 % 5 != 2 else "garages/single_stucco_clay"
		var n1 := K.building(bl, fold, G.q(sx, sz, gu + 1.75, 67.0), 180.0, "lockup_n%d" % k2, 0.8)
		B.append([[n1, 3.5, 6.0], fold])
		var n2 := K.building(bl, fold, G.q(sx, sz, gu + 1.75, 73.0), 0.0, "lockup_s%d" % k2, 0.8)
		B.append([[n2, 3.5, 6.0], fold])
		gu += 3.6; k2 += 1
	# the moving warehouse at the back corner, its rollups to the van park
	B.append([G.put_back(bl, props, sx, sz, "x", 18.0, "modular/examples/mod_wh_shed", "moving_warehouse", 97.5), "modular/examples/mod_wh_shed"])
	# ---- edges
	G.frontage(props, m, sx, sz, "x", [[23.0, 35.0]], [38.0], "chain", 35.0, 99.8)     # the storage sheds stand 10 m back: opaque behind the one chain-link run
	G.wall(props, sx, sz, Vector2(16.0, G.eu(m, 16.0) + 0.3), Vector2(16.0, 54.0), "fence_stucco_wall", 0, "worn")       # the houses' street side
	G.wall(props, sx, sz, Vector2(16.0, 60.0), Vector2(16.0, 99.4), "fence_stucco_wall", 0, "worn")
	I.add(props, "fence_gate_rolling_chainlink", "worn", G.q(sx, sz, 16.6, 63.0), 90.0)                               # the alley gate, slid open
	G.wall(props, sx, sz, Vector2(16.2, 99.3), Vector2(99.6, 99.3), "fence_cmu_wall", 6, "dirty")                      # the south edge
	var v := 30.0; var kt := 0
	while v < 96.0:
		if absf(v - 57.0) > 6.0:
			props.add(["tree_eucalyptus_a", "tree_torrey_pine_b", "tree_eucalyptus_b", "tree_torrey_pine_a"][kt % 4], "normal", G.q(sx, sz, 12.5 + rr.randf_range(-0.5, 0.5), v), rr.randf_range(0, 360), true, rr.randf_range(0.8, 1.1))
			kt += 1
		v += rr.randf_range(11.0, 14.0)
	# ---- moving vans / customers' cars: the van park by the warehouse and the lane's visitor bays
	stl.append_array(G.stalls(props, sx, sz, 46.0, 18, 85.0, 1.0, "prop_wheel_stop_concrete", [6]))
	stl.append_array(G.stalls(props, sx, sz, 66.0, 8, 52.5, 1.0))
	# storage pods (white boxes) waiting to go out, a rolloff for what people leave behind, lights
	for k3 in 5: I.add(props, "prop_container_20ft_white", "worn" if k3 % 2 else "dirty", G.q(sx, sz, 20.5, 30.0 + k3 * 6.4), 0.0)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", G.q(sx, sz, 26.0, 68.2), 90.0)
	for p: Vector2 in [Vector2(43.5, 20.0), Vector2(42.5, 78.0), Vector2(99.0, 61.0), Vector2(99.0, 90.0)]:
		I.add(props, "prop_lot_light_pole", "dirty", G.q(sx, sz, p.x, p.y), 0.0)
	I.add(props, "prop_utility_pole_transformer", "dirty", G.q(sx, sz, 99.2, 50.0), 0.0)
	I.back_door_clutter(props, rr, G.q(sx, sz, 29.0, 31.0), 0.0, "shop")
	G.walk_prop(props, m, sx, sz, "x", 30.0, "prop_newspaper_box_blue", "dirty")
	# ---- POLISH: each with its reason; placed only where free (G.place)
	var obs := G.obstacles(bl, props, stl); var kp := [[33.0, 13.0, 43.0, 100.0], [16.0, 54.0, 100.0, 61.0]]
	G.place(props, obs, rr, sx, sz, "prop_sign_stop", "worn", 34.0, 16.0, 36.0, 20.0, 180.0, kp, 3.0)                 # vans leaving onto 3rd St
	G.place(props, obs, rr, sx, sz, "prop_hydrant_red", "rusty", 17.0, 40.0, 22.0, 50.0, 0.0, kp)
	G.spot(props, obs, rr, sx, sz, [["prop_picnic_table", "worn"], ["prop_trash_receptacle", "worn"], ["prop_vending_soda", "clean"]], 17.0, 75.0, 30.0, 82.0, 0.0, kp)   # the movers wait for their next job here
	G.spot(props, obs, rr, sx, sz, [["prop_trash_cart_black", "worn"], ["prop_trash_cart_blue", "worn"], ["prop_recycling_receptacle", "worn"]], 23.0, 28.0, 33.0, 31.5, 180.0, kp)
	G.spot(props, obs, rr, sx, sz, [["prop_cone_28in", "dirty"], ["prop_cone_28in", "dirty"], ["prop_channelizer_drum", "dirty"]], 44.0, 76.0, 98.0, 81.0, 0.0, kp)
	# ---- wear
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	for r: Array in stl: W.oil(dec, rr, Vector2(float(r[0]), float(r[1])), float(r[2]), S.walk_y, 0.8)
	I.truck_path(dec, rr, Vector2(sx * 38.0, sz * 14.0), Vector2(sx * 38.0, sz * 80.0))
	I.truck_path(dec, rr, Vector2(sx * 16.0, sz * 57.0), Vector2(sx * 98.0, sz * 57.0))
	I.yard_wear(dec, rr, sx, sz, 17.0, 20.0, 99.0, 99.0, 1.0)
	G.drape(mr, sx, sz, props, dec, bl)
	root.set_meta("stalls", _draped_stalls(stl, mr, sx, sz))
	I.finish(root, g, props, dec, NAME)
	quit()

## stalls on a slope: [x, z, yaw, y, grade] (the preview tilts the cars)
func _draped_stalls(stl: Array, mr: Dictionary, sx: float, sz: float) -> Array:
	var out: Array = []
	for r: Array in stl:
		var u := sx * float(r[0]); var v := sz * float(r[1])
		out.append([r[0], r[1], r[2], G.h_at(mr, u, v), 0.0])
	return out
