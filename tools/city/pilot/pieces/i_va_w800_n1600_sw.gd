extends SceneTree
## Piece i_va_w800_n1600_sw (industrial growth, VARIANT A "port", first dressing; 18 Nov, not locked).
## Site: SW corner of 1st St (bay-front ring) x J Ave, world (-900..-800, -1600..-1500); the locked sample's i_nw
## (Bayline distribution centre) is its south neighbour, the empty base-fence strip by Alameda Blvd its west edge.
## HARBOR FREIGHT STATION, a container freight station: boxes come off the navy pier and the bay barges, are stacked
## by the yard's crane (the kit's dock crane: unused until now) and unpacked in the devanning shed at the back.
## Planner's reasons:
##  - 1st St is the bay boulevard (palms, bike lane, bus stop, no aprons): no truck gate on it. Its frontage gets the
##    people's side of the business: the freight station's office in an old brick block (customs paperwork, drivers' check-in) and a ship
##    chandlery that sells to the boats across the road; the rest is a block wall (opaque: no see-through layers on the
##    boulevard, Redmi rule) with tags where the bus stop crowd waits.
##  - Trucks come in off J Ave at the street's own apron (82 m): gate booth, open rolling gate, a truck path to the stacks.
##  - The J Ave frontage holds the reefer repair shop (its counter is a walk-in place) and the packing shed.
##  - The south and the J Ave-side edges toward the sample already have i_nw's fences: none added there.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_va_w800_n1600_sw"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := -1.0; var sz := 1.0
	var m: Dictionary = await G.measure(self, Vector3(-800.0, 2.0, -1600.0), sx, sz)
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var stl: Array = []
	var paints: Array = G.stall_paint(sx, sz, 40.0, 5, 33.0, -1.0)
	paints.append_array([[-69.5, 91.0, -40.0, 99.8, "gravel"]])          # the empties' park at the back fence
	G.floor(g, m, sx, sz, paints)
	var B: Array = []
	var fx := G.front_x(m, 22.0, 52.0)
	B.append([G.put(bl, props, sx, sz, "x", 23.0, fx, "ck/ck_brk3_corner2", "hfs_office"), "ck/ck_brk3_corner2"])
	B.append([G.put(bl, props, sx, sz, "x", 39.0, fx, "ck/ck_svc_trade_1d", "bayside_chandlery"), "ck/ck_svc_trade_1d"])
	var fz := G.front_z(m, 22.0, 100.0)
	B.append([G.put(bl, props, sx, sz, "z", 31.5, fz, "industrial/ind_repair", "reefer_repair"), "industrial/ind_repair"])
	B.append([G.put(bl, props, sx, sz, "z", 50.0, fz, "modular/examples/mod_wh_shed", "packing_shed"), "modular/examples/mod_wh_shed"])
	B.append([G.put_back(bl, props, sx, sz, "x", 70.0, "industrial/ind_warehouse", "devanning_shed"), "industrial/ind_warehouse"])
	# ---- frontages: the boulevard wall, J Ave's fence with the gate at the 82 m apron
	G.frontage(props, m, sx, sz, "x", [[23.0, 35.0], [39.0, 51.0]], [], "cmu", 51.0, 99.8)
	G.frontage(props, m, sx, sz, "z", [[31.5, 49.5], [50.0, 74.0]], [82.0], "chain", 74.0, 99.8)
	# the west edge toward the empty base-fence strip: block wall (the strip is not built yet)
	# the west edge: a block wall toward the empties depot strip (i_va_w951_n1400_ne), with the depot's gate at 56-63 m
	# (19 Nov: the depot is reached only through this yard; its streets have no driveway)
	G.wall(props, sx, sz, Vector2(99.8, m.ex[199] + 0.2), Vector2(99.8, 56.0), "fence_cmu_wall", 7, "dirty")
	G.wall(props, sx, sz, Vector2(99.8, 63.0), Vector2(99.8, 99.6), "fence_cmu_wall", 7, "dirty")
	I.add(props, "fence_gate_rolling_chainlink", "worn", G.q(sx, sz, 99.2, 52.3), 90.0)
	I.truck_path(dec, rr, Vector2(sx * 99.8, sz * 59.5), Vector2(sx * 82.0, sz * 59.5))
	K.building(bl, "commercial/com_kiosk", G.q(sx, sz, 15.0, 90.0), 180.0, "gate_booth")   # its door to the driveway
	# ---- the stacks under the gantry: six columns along v (the crane travels along them), a truck lane in the middle
	I.add(props, "prop_dock_crane", "dirty", G.q(sx, sz, 62.0, 50.0), 90.0)    # its base and jib along the truck lane, between the stacks
	for col: Array in [[47.0, [2, 3, 2, 1, 2]], [51.0, [3, 3, 2, 2, 1]], [55.0, [1, 2, 3, 2, 2]], [69.0, [2, 2, 1, 3, 2]], [73.0, [3, 2, 2, 1, 1]], [77.0, [1, 1, 2, 2, 3]]]:
		G.stack_col(props, rr, sx, sz, float(col[0]), 36.0, col[1])
	# k-rails round the crane's pedestal (the kit's dock crane is a jib crane on a tower): trucks turn close to it
	for a: Array in [[62.0, 28.5, 0.0], [62.0, 71.5, 0.0]]:      # the lane under the crane is closed to trucks at both ends
		I.add(props, "prop_k_rail", "dirty", G.q(sx, sz, float(a[0]), float(a[1])), float(a[2]))
	# chassis line: boxes on their trailers waiting for a tractor, noses to the aisle, between the stacks and the empties
	for k in 7:
		if k == 3: continue
		I.add(props, ["prop_container_20ft_red", "prop_container_20ft_blue", "prop_container_20ft_white", "prop_container_20ft_green"][k % 4], "dirty" if k % 2 else "worn", G.q(sx, sz, 30.0 + k * 4.0, 90.0), 0.0)
	for k in 3: I.add(props, "prop_water_barrier_white", "dirty", G.q(sx, sz, 58.5, 87.0 + k * 1.9), 90.0)   # closes the chassis line's end
	# trailers at the devanning shed's rollups (two 20 ft boxes nose to tail = a 40 ft trailer), cones round a leak
	for k in 2:
		I.add(props, "prop_container_20ft_white", "dirty", G.q(sx, sz, 91.0 - k * 4.5, 66.5), 0.0)
		I.add(props, "prop_container_20ft_white", "worn", G.q(sx, sz, 91.0 - k * 4.5, 60.2), 0.0)
	for k in 4: I.add(props, "prop_cone_18in", "dirty", G.q(sx, sz, 82.0 + k * 0.9, 57.0 + (k % 2) * 0.6), k * 33.0)
	# empties waiting for collection at the back fence (gravel), one stacked
	G.stack_col(props, rr, sx, sz, 64.0, 94.0, [1]); G.stack_col(props, rr, sx, sz, 67.0, 94.0, [2])
	for p: Vector2 in [Vector2(40.0, 40.0), Vector2(62.0, 80.0), Vector2(38.0, 70.0), Vector2(90.0, 30.0)]:
		I.add(props, "prop_lot_light_pole", "dirty", G.q(sx, sz, p.x, p.y), 45.0)
	I.add(props, "prop_utility_pole_transformer", "dirty", G.q(sx, sz, 96.5, 40.0), 0.0)   # the crane's feed
	I.add(props, "prop_switch_rack", "worn", G.q(sx, sz, 95.5, 46.0), 90.0)
	I.add(props, "prop_transformer_substation", "dirty", G.q(sx, sz, 95.0, 52.0), 90.0)   # the crane's own supply
	# ---- staff parking behind the office and the chandlery (rubber stops: cars nose to the walls)
	stl.append_array(G.stalls(props, sx, sz, 40.0, 5, 33.0, -1.0))
	# ---- the back doors: office bins, chandlery's rope-and-gas corner, the repair shop's drums and the yard skip
	I.back_door_clutter(props, rr, G.q(sx, sz, 30.5, 34.0), 0.0, "shop")
	I.back_door_clutter(props, rr, G.q(sx, sz, 34.5, 36.5), 0.0, "gas")
	for k in 5: I.add(props, "prop_channelizer_drum", "dirty", G.q(sx, sz, 35.0, 52.0 + k * 0.85), 0.0)
	I.add(props, "prop_propane_tank_250gal", "rusty", G.q(sx, sz, 28.0, 46.0), 90.0)
	I.back_door_clutter(props, rr, G.q(sx, sz, 22.0, 95.5), 0.0, "yard")
	I.add(props, "prop_dumpster_3yd_blue", "rusty", G.q(sx, sz, 45.0, 96.5), 0.0)
	# ---- the sidewalk: the chandlery's paper box and a bin, the office's mailbox; the J Ave counter's bike rack
	G.walk_prop(props, m, sx, sz, "x", 44.0, "prop_newspaper_box_blue", "dirty"); G.walk_prop(props, m, sx, sz, "x", 37.8, "prop_trash_receptacle", "dirty")
	G.walk_prop(props, m, sx, sz, "x", 26.0, "prop_usps_collection_box", "worn")
	G.walk_prop(props, m, sx, sz, "z", 45.5, "prop_bike_rack", "rusty")
	# ---- wear: building feet, the truck path from the gate round the stacks to the shed, the most worn yard ground
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 82.0), Vector2(sx * 62.0, sz * 82.0))
	I.truck_path(dec, rr, Vector2(sx * 62.0, sz * 82.0), Vector2(sx * 62.0, sz * 74.0))
	I.truck_path(dec, rr, Vector2(sx * 62.0, sz * 72.0), Vector2(sx * 85.0, sz * 70.0))
	G.yard_wear(dec, rr, sx, sz, 36.0, 32.0, 99.0, 72.0, 1.8)
	G.yard_wear(dec, rr, sx, sz, 30.0, 72.0, 70.0, 99.0, 1.0)
	G.yard_wear(dec, rr, sx, sz, 28.0, 28.0, 99.0, 36.0, 0.8)
	# ---- POLISH (Yasin 18 Nov: "lots of props"; each with its reason; placed only where free, G.place)
	var obs := G.obstacles(bl, props, stl); var kp := [[8.0, 78.0, 64.0, 86.0], [59.0, 70.0, 65.0, 86.0]]
	G.place(props, obs, rr, sx, sz, "prop_sign_stop", "worn", 10.0, 73.0, 14.0, 77.5, 90.0 * sx, kp, 3.0)          # trucks leaving onto J Ave
	G.place(props, obs, rr, sx, sz, "prop_hydrant_red", "rusty", 64.0, 68.5, 69.5, 72.0, 0.0, kp)                 # the devanning shed's fire hydrant
	G.spot(props, obs, rr, sx, sz, [["prop_picnic_table", "worn"], ["prop_trash_receptacle", "dirty"], ["prop_vending_soda", "clean", 180.0]], 36.0, 52.0, 44.5, 68.0, 90.0 * sx, kp)   # the yard crew's lunch spot in the shed's shade, watching the stacks
	G.spot(props, obs, rr, sx, sz, [["prop_trash_cart_black", "worn"], ["prop_trash_cart_blue", "worn"], ["prop_bike_rack", "rusty", 90.0]], 23.0, 30.5, 37.0, 35.5, 180.0, kp)   # behind the office: its bins and the staff's bikes
	G.spot(props, obs, rr, sx, sz, [["prop_dumpster_3yd_green", "rusty"], ["prop_channelizer_drum", "dirty"], ["prop_channelizer_drum", "dirty"], ["prop_water_barrier_white", "dirty"], ["prop_cone_18in", "dirty"]], 82.0, 30.0, 98.0, 44.0, 0.0, kp)   # strapping, lashing bars and spill kit by the crane feed
	G.spot(props, obs, rr, sx, sz, [["prop_cone_28in", "dirty"], ["prop_cone_28in", "dirty"], ["prop_barricade_type1", "worn"]], 58.0, 27.0, 66.0, 30.0, 0.0, kp)   # the closed crane lane's end
	root.set_meta("stalls", stl)
	I.finish(root, g, props, dec, NAME)
	quit()
