extends SceneTree
## Piece i_se (industrial sample, SE): the district's fire station and the trades around it, as a perimeter block.
## Cross street: an auto-parts counter, an auto repair shop, Fire Station 1 (its engine bays open onto the standard
## 75 m apron - the station's own driveway, painted keep-clear), a small electrical contractor. Side street: a
## wholesale bakery on the corner (bread vans out at 4 am), a fabrication shed, a plumbing supply. Back row: a line of
## self-storage blocks facing the yard. In the middle, a salvage yard behind its own barbed fence. The south edge
## faces the houses: a block wall, grass and eucalyptus screen it (transition rule). Run once; never when locked.
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := 1.0
	var root := Node3D.new(); root.name = "i_se"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("i_se")
	I.quad_floor(g, sx, sz, [[40.0, 60.0, 74.0, 90.0, "gravel"], [I.PROP, 92.0, 100.0, 100.0, "grass"]])
	var B: Array = []
	var f := I.FRONT
	B.append([I.put(bl, props, sx, sz, "x", 22.5, f, "ck/ck_svc_trade", "auto_parts"), "ck/ck_svc_trade"])  # audit fix 17 Nov (#9): was mod_svc_row, whose pharmacy + laundromat fronts repeated 13 times
	B.append([I.put(bl, props, sx, sz, "x", 44.5, f, "industrial/ind_repair", "auto_repair"), "industrial/ind_repair"])
	B.append([I.put(bl, props, sx, sz, "x", 65.0, f, "civic/civ_fire_station", "fire_station_1"), "civic/civ_fire_station"])
	B.append([I.put(bl, props, sx, sz, "x", 86.0, f, "ck/ck_grt_row2", "electrical_contractor"), "ck/ck_grt_row2"])  # audit fix 17 Nov (#9): was mod_svc_row, whose pharmacy + laundromat fronts repeated 13 times
	B.append([I.put(bl, props, sx, sz, "z", 24.0, f, "commercial/com_bakery", "wholesale_bakery"), "commercial/com_bakery"])
	B.append([I.put(bl, props, sx, sz, "z", 45.5, f, "modular/examples/mod_wh_shed", "fabrication"), "modular/examples/mod_wh_shed"])
	B.append([I.put(bl, props, sx, sz, "z", 78.5, f, "ck/ck_svc_trade_1d", "plumbing_supply"), "ck/ck_svc_trade_1d"])  # audit fix 17 Nov (#9): was mod_svc_row, whose pharmacy + laundromat fronts repeated 13 times
	for k in 3:
		B.append([I.put_back(bl, props, sx, sz, "z", 32.0 + k * 19.0, "ck/mod_stg_row_roofed", "storage_%d" % k, 91.0), "ck/mod_stg_row_roofed"])
	# fences: the fire station's apron stays open; everything else between buildings is chain-link
	I.street_fence(props, sx, sz, "x", [[22.5, 34.5], [44.5, 62.5], [65.0, 85.0], [86.0, 98.0]], [40.0])
	I.street_fence(props, sx, sz, "z", [[24.0, 33.0], [45.5, 69.5], [78.5, 90.5]], I.APRONS, I.J, 91.5)
	I.lot_fence(props, Vector2(99.8, I.PROP), Vector2(99.8, 91.5))
	# keep-clear box in front of the engine bays (paint on the apron's sidewalk edge is not possible: decals)
	W.red_kerb(dec, Vector2(70.0, I.KERB), Vector2(80.0, I.KERB), Vector2(0.0, -1.0))
	# ---- salvage yard (u 40-80, v 60-90): barbed fence, gate facing the open yard, rusted stock
	I.lot_fence(props, Vector2(40.0, 60.0), Vector2(40.0, 90.0), true)
	I.lot_fence(props, Vector2(74.0, 60.0), Vector2(74.0, 90.0), true)
	I.lot_fence(props, Vector2(40.0, 90.0), Vector2(74.0, 90.0), true)
	I.lot_fence(props, Vector2(40.0, 60.0), Vector2(55.0, 60.0), true); I.lot_fence(props, Vector2(63.0, 60.0), Vector2(74.0, 60.0), true)
	I.add(props, "fence_gate_rolling_chainlink", "rusty", I.q(sx, sz, 66.5, 60.4), 0.0)
	I.containers(props, sx, sz, 44.0, 64.0, 3, true, rr, 0.5)
	I.containers(props, sx, sz, 44.0, 78.0, 3, true, rr, 0.3)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", I.q(sx, sz, 58.0, 72.0), 90.0)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", I.q(sx, sz, 58.0, 82.0), 80.0)
	for k in 5: I.add(props, "prop_water_barrier_orange", "dirty", I.q(sx, sz, 60.0 + k * 2.0, 87.0), rr.randf_range(-25, 25))
	for k in 4: I.add(props, "prop_barricade_type3", "dirty", I.q(sx, sz, 71.0, 66.0 + k * 3.0), 90.0 + rr.randf_range(-10, 10))
	I.add(props, "prop_propane_tank_250gal", "rusty", I.q(sx, sz, 65.0, 66.0), 0.0)
	I.add(props, "prop_k_rail", "dirty", I.q(sx, sz, 64.0, 76.0), 20.0)
	I.add(props, "prop_k_rail", "dirty", I.q(sx, sz, 65.0, 80.0), 35.0)
	I.add(props, "prop_lot_light_pole", "dirty", I.q(sx, sz, 60.0, 64.0), 0.0)
	# ---- the open yard (u 34-80, v 27-58): repair cars waiting (their oil), the bakery's vans, pallets of bins
	I.add(props, "prop_lot_light_pole", "dirty", I.q(sx, sz, 50.0, 40.0), 90.0)
	I.add(props, "prop_utility_pole_transformer", "dirty", I.q(sx, sz, 38.0, 56.0), 90.0)
	I.back_door_clutter(props, rr, I.q(sx, sz, 30.0, 25.5), 180.0, "shop")
	I.back_door_clutter(props, rr, I.q(sx, sz, 55.0, 30.5), 180.0, "yard")
	I.back_door_clutter(props, rr, I.q(sx, sz, 90.0, 25.0), 180.0, "shop")
	I.back_door_clutter(props, rr, I.q(sx, sz, 26.0, 36.5), -90.0, "gas")
	I.back_door_clutter(props, rr, I.q(sx, sz, 26.0, 84.0), -90.0, "shop")
	for k in 6: W.oil(dec, rr, Vector2(36.0 + k * 3.2, 33.0), 0.0, S.walk_y, 0.95)   # cars parked nose-in awaiting repair
	for k in 3: I.add(props, "prop_cone_28in", "dirty", I.q(sx, sz, 60.0 + k * 1.5, 52.0), k * 30.0)
	# ---- the bakery's outlet counter on the sidewalk side: a bin and a paper box; a hydrant by the fire station
	I.walk_prop(props, sx, sz, "z", 26.0, "prop_trash_receptacle", "dirty"); I.walk_prop(props, sx, sz, "z", 34.5, "prop_newspaper_box_blue")
	# ---- buffer to the houses: block wall (tagged on the yard side) and eucalyptus
	var x := I.PROP + 1.0
	var k2 := 0
	while x < 99.0:
		I.add(props, "fence_graffiti_cmu_panel" if k2 % 5 == 2 else "fence_cmu_wall", "worn", Vector3(x + 1.0, S.walk_y(0.0), 99.6), 0.0)
		x += 2.03; k2 += 1
	for ex in range(16, 100, 12): I.add(props, "tree_eucalyptus_a" if ex % 24 == 16 else "tree_eucalyptus_b", "normal", Vector3(float(ex), S.walk_y(0.0), 95.5), ex * 13.0)
	# ---- wear
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	I.truck_path(dec, rr, Vector2(40.0, I.PROP), Vector2(40.0, 50.0))
	I.truck_path(dec, rr, Vector2(I.PROP, 40.0), Vector2(60.0, 40.0))
	I.truck_path(dec, rr, Vector2(I.PROP, 75.0), Vector2(34.0, 75.0))
	I.truck_path(dec, rr, Vector2(60.0, 45.0), Vector2(66.5, 64.0))
	I.yard_wear(dec, rr, sx, sz, 34.0, 26.0, 78.0, 60.0, 1.6)
	I.yard_wear(dec, rr, sx, sz, 40.0, 60.0, 74.0, 90.0, 1.4)
	I.yard_wear(dec, rr, sx, sz, 10.0, 34.0, 34.0, 91.0, 0.8)
	I.finish(root, g, props, dec, "i_se")
	quit()
