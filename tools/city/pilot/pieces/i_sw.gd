extends SceneTree
## Piece i_sw (industrial sample, SW): the district's power substation and a road contractor, as a perimeter block.
## Cross street: a dive bar on the corner (shift workers, GTA IV's kind of place), Coastline Paving's equipment shed,
## an old brick print works. Side street: a cash-and-carry counter, the substation behind barbed chain-link right on
## the street (its gate off the 40 m driveway lane), a locksmith / key cutter. Back row facing the yard: a storage shed
## and a bus repair shop. Yard: the contractor's stock (k-rails, water barriers, drums, barricades, sign stands), a
## container depot behind. The south edge faces the houses: block wall + eucalyptus. Run once; never when locked.
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := -1.0; var sz := 1.0
	var root := Node3D.new(); root.name = "i_sw"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for("i_sw")
	I.quad_floor(g, sx, sz, [[-38.0, 44.0, -I.PROP, 72.0, "gravel"], [-72.0, 66.0, -42.0, 90.0, "gravel"], [-100.0, 92.0, -I.PROP, 100.0, "grass"]])
	var B: Array = []
	var f := I.FRONT
	B.append([I.put(bl, props, sx, sz, "x", 23.0, f, "commercial/com_bar_crown", "dive_bar"), "commercial/com_bar_crown"])
	B.append([I.put(bl, props, sx, sz, "x", 45.5, f, "industrial/ind_warehouse", "coastline_paving"), "industrial/ind_warehouse"])
	B.append([I.put(bl, props, sx, sz, "x", 79.0, f, "modular/examples/mod_brk_row", "print_works"), "modular/examples/mod_brk_row"])
	B.append([I.put(bl, props, sx, sz, "z", 23.5, f, "ck/ck_svc_trade", "cash_and_carry"), "ck/ck_svc_trade"])  # audit fix 17 Nov (#9): was mod_svc_row, whose pharmacy + laundromat fronts repeated 13 times
	B.append([I.put(bl, props, sx, sz, "z", 78.5, f, "ck/ck_svc_pawn_fast", "locksmith"), "ck/ck_svc_pawn_fast"])  # audit fix 17 Nov (#9): was mod_svc_row, whose pharmacy + laundromat fronts repeated 13 times
	B.append([I.put_back(bl, props, sx, sz, "z", 36.0, "modular/examples/mod_wh_shed", "paving_store"), "modular/examples/mod_wh_shed"])
	B.append([I.put_back(bl, props, sx, sz, "z", 64.0, "industrial/ind_repair", "bus_repair", 91.0), "industrial/ind_repair"])
	I.street_fence(props, sx, sz, "x", [[23.0, 32.0], [45.5, 69.5], [79.0, 97.0]], I.APRONS)
	I.street_fence(props, sx, sz, "z", [[23.5, 35.5], [44.0, 72.0], [78.5, 90.5]], I.APRONS, I.J, 91.5)
	I.lot_fence(props, Vector2(-99.8, I.PROP), Vector2(-99.8, 91.5))
	# ---- substation compound (u 8.85-38, v 44-72): barbed all round, its gate on the 40 m driveway lane
	var c := I.PROP + 0.15
	I.lot_fence(props, Vector2(-c, 44.0), Vector2(-c, 72.0), true)
	I.lot_fence(props, Vector2(-38.0, 44.0), Vector2(-38.0, 72.0), true)
	I.lot_fence(props, Vector2(-c, 72.0), Vector2(-38.0, 72.0), true)
	I.lot_fence(props, Vector2(-c, 44.0), Vector2(-19.0, 44.0), true); I.lot_fence(props, Vector2(-25.0, 44.0), Vector2(-38.0, 44.0), true)
	I.add(props, "fence_gate_rolling_chainlink", "rusty", I.q(sx, sz, 22.0, 44.0), 0.0)
	for k in 2: I.add(props, "prop_transformer_substation", "dirty", I.q(sx, sz, 17.0 + k * 11.0, 52.0), 0.0)
	for k in 3: I.add(props, "prop_switch_rack", "worn", I.q(sx, sz, 15.0 + k * 7.5, 63.5), 0.0)
	K.building(bl, "commercial/com_kiosk", I.q(sx, sz, 34.0, 50.0), 90.0, "control_hut")
	I.add(props, "prop_lot_light_pole", "worn", I.q(sx, sz, 32.0, 68.0), 0.0)
	# ---- contractor yard (u 40-72, v 35-64): stock stored in rows, ready to load
	for row in 3:
		for k in 4: I.add(props, "prop_k_rail", "dirty" if (row + k) % 2 else "worn", I.q(sx, sz, 44.0 + k * 4.3, 38.0 + row * 1.2), 0.0)
	for row in 2:
		for k in 5: I.add(props, "prop_water_barrier_orange" if (row + k) % 3 else "prop_water_barrier_white", "dirty", I.q(sx, sz, 44.0 + k * 2.3, 44.0 + row * 1.0), 0.0)
	for k in 9: I.add(props, "prop_channelizer_drum", "dirty" if k % 3 else "worn", I.q(sx, sz, 58.0 + (k % 3) * 0.9, 44.0 + (k / 3) * 0.9), 0.0)
	for k in 4: I.add(props, "prop_barricade_type3", "dirty", I.q(sx, sz, 63.5, 41.0 + k * 2.6), 90.0)
	for k in 6: I.add(props, "prop_barricade_type1", "worn", I.q(sx, sz, 67.5, 41.0 + k * 1.2), 90.0)
	for k in 8: I.add(props, "prop_cone_28in", "dirty", I.q(sx, sz, 44.0 + (k % 4) * 0.8, 49.0 + (k / 4) * 0.8), k * 23.0)
	for k in 4: I.add(props, "fence_temp_fence_panel", "rusty", I.q(sx, sz, 50.0, 52.0 + k * 0.35), 0.0, false)   # panels stacked flat-ish
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", I.q(sx, sz, 50.0, 58.5), 0.0)
	I.add(props, "prop_lot_light_pole", "dirty", I.q(sx, sz, 64.0, 56.0), 0.0)
	I.add(props, "prop_utility_pole_transformer", "dirty", I.q(sx, sz, 41.0, 62.0), 0.0)
	# ---- container depot (u 44-72, v 68-90)
	I.containers(props, sx, sz, 46.0, 70.0, 6, false, rr, 0.6)
	I.containers(props, sx, sz, 46.0, 79.0, 6, false, rr, 0.5)
	I.add(props, "prop_lot_light_pole", "dirty", I.q(sx, sz, 66.0, 88.0), 90.0)
	# ---- back doors: the bar's kegs-and-bins corner, the print works' paper skip, the counter's dumpster
	I.back_door_clutter(props, rr, I.q(sx, sz, 27.5, 25.8), 180.0, "gas")
	I.back_door_clutter(props, rr, I.q(sx, sz, 88.0, 25.8), 180.0, "shop")
	I.back_door_clutter(props, rr, I.q(sx, sz, 25.0, 31.0), 90.0, "shop")
	I.back_door_clutter(props, rr, I.q(sx, sz, 26.0, 86.0), 90.0, "shop")
	# ---- the bar's sidewalk: an overflowing bin, a bike rack, the paper box nobody empties
	I.walk_prop(props, sx, sz, "x", 33.8, "prop_trash_receptacle", "dirty"); I.walk_prop(props, sx, sz, "x", 30.5, "prop_bike_rack", "rusty")
	I.walk_prop(props, sx, sz, "z", 29.0, "prop_newspaper_box_blue", "dirty")
	# ---- buffer to the houses
	var x := -I.PROP - 1.0
	var k2 := 0
	while x > -99.0:
		I.add(props, "fence_graffiti_cmu_panel" if k2 % 6 == 3 else "fence_cmu_wall", "worn", Vector3(x - 1.0, S.walk_y(0.0), 99.6), 0.0)
		x -= 2.03; k2 += 1
	for ex in range(16, 100, 12): I.add(props, "tree_eucalyptus_b" if ex % 24 == 16 else "tree_eucalyptus_a", "normal", Vector3(-float(ex), S.walk_y(0.0), 95.5), ex * 17.0)
	# ---- wear
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	I.truck_path(dec, rr, Vector2(-40.0, I.PROP), Vector2(-40.0, 40.0))
	I.truck_path(dec, rr, Vector2(-75.0, I.PROP), Vector2(-75.0, 34.0))
	I.truck_path(dec, rr, Vector2(-I.PROP, 40.0), Vector2(-55.0, 40.0))
	I.truck_path(dec, rr, Vector2(-I.PROP, 75.0), Vector2(-50.0, 75.0))
	I.yard_wear(dec, rr, sx, sz, 38.0, 34.0, 73.0, 66.0, 1.8)
	I.yard_wear(dec, rr, sx, sz, 42.0, 66.0, 73.0, 91.0, 1.2)
	I.yard_wear(dec, rr, sx, sz, 10.0, 36.0, 40.0, 44.0, 1.5)
	I.yard_wear(dec, rr, sx, sz, 10.0, 72.0, 42.0, 91.0, 1.0)
	I.finish(root, g, props, dec, "i_sw")
	quit()
