extends SceneTree
## Piece i_vb_w800_n1600_se (industrial growth, VARIANT B "fleet", first dressing; 18 Nov, not locked).
## Site: SE corner of 1st St (bay-front ring) x J Ave, world (-800..-700, -1600..-1500); the sample's i_ne (Harbor
## Steel works) is its south neighbour.
## CITY YARD: the town's public works and fleet depot - the trucks, vans and sweepers of the city park here overnight,
## fill up at their own diesel island, go through the wash, and the parks and signs crews keep their gear in lock-ups.
## Planner's reasons:
##  - On the bay boulevard the city shows its civic face: the public works office (permits counter, walk-in) and a
##    workwear store that kits out the crews and the district's trades (walk-in); then a stucco wall (opaque) - the city
##    does not put chain-link on its own boulevard. The bus stop on 1st St in front of the store is left clear.
##  - Vehicles in and out at J Ave's own apron (82 m), under the eyes of the gate booth; the J Ave fence is chain-link
##    on purpose (security sees the street) and it is the only see-through run in the block (behind it: parked trucks,
##    the opaque wash hall and garages, so no fence stacks behind it).
##  - Fuel island in the middle of the yard (bollards guard the pumps from swinging trailers), the wash at the back,
##    the lock-ups along the east edge facing the yard (their backs are the edge: no fence there).
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_vb_w800_n1600_se"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := 1.0
	var m: Dictionary = await G.measure(self, Vector3(-800.0, 2.0, -1600.0), sx, sz)
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var stl: Array = []
	var paints: Array = []
	paints.append_array(G.stall_paint(sx, sz, 24.0, 13, 36.0, -1.0))
	paints.append_array(G.stall_paint(sx, sz, 48.0, 13, 50.0, 1.0))
	paints.append_array(G.stall_paint(sx, sz, 48.0, 13, 55.6, -1.0))
	paints.append([sx * 29.0, sz * 62.5, sx * 41.0, sz * 66.5, "concrete"])        # the fuel island's slab
	G.floor(g, m, sx, sz, paints)
	var B: Array = []
	var fx := G.front_x(m, 22.0, 56.0)
	B.append([G.put(bl, props, sx, sz, "x", 23.0, fx, "modular/examples/mod_brk_row", "public_works_office"), "modular/examples/mod_brk_row"])
	B.append([G.put(bl, props, sx, sz, "x", 43.0, fx, "ck/ck_svc_pawn_fast", "workwear_store"), "ck/ck_svc_pawn_fast"])   # not ck_grt_row2: its painted windows and the room's storefront band across its door (Yasin 18 Nov)
	var fz := G.front_z(m, 22.0, 100.0)
	B.append([G.put(bl, props, sx, sz, "z", 32.0, fz, "ck/mod_stg_row_roofed", "salt_and_sign_store"), "ck/mod_stg_row_roofed"])
	B.append([G.put_back(bl, props, sx, sz, "x", 62.0, "services/svc_carwash", "fleet_wash"), "services/svc_carwash"])
	# lock-ups along the east edge, doors to the yard (parks crew, signs, the sweeper's brushes); no services behind them
	var gv := 24.0; var k := 0
	while gv < 66.0:
		var gf: String = "garages/single_stucco_flat" if k % 4 != 3 else "garages/single_stucco_clay"
		G.put(bl, props, sx, sz, "z", gv, 93.6, gf, "lockup_%d" % k, false)
		gv += 3.6; k += 1
	# ---- frontages
	G.frontage(props, m, sx, sz, "x", [[23.0, 41.0], [43.0, 55.0]], [], "stucco", 55.0, 99.8)
	G.frontage(props, m, sx, sz, "z", [[32.0, 50.0]], [82.0], "chain", 22.0, 99.8)
	G.wall(props, sx, sz, Vector2(99.8, G.eu(m, 99.8) + 0.2), Vector2(99.8, 23.8), "fence_cmu_wall", 0)
	G.wall(props, sx, sz, Vector2(99.8, 67.6), Vector2(99.8, 99.6), "fence_cmu_wall", 6)
	K.building(bl, "commercial/com_kiosk", G.q(sx, sz, 15.0, 90.0), 180.0, "gate_booth")
	# ---- fleet stalls (trucks and vans overnight: the preview parks cars here), staff row behind the office
	stl.append_array(G.stalls(props, sx, sz, 24.0, 13, 36.0, -1.0, "prop_wheel_stop_concrete"))
	stl.append_array(G.stalls(props, sx, sz, 48.0, 13, 50.0, 1.0))
	stl.append_array(G.stalls(props, sx, sz, 48.0, 13, 55.6, -1.0, "prop_wheel_stop_rubber", [4, 9]))
	# ---- the diesel island: two pumps, iron bollards at both ends and between, the tank behind a k-rail
	for k2 in 2: I.add(props, "prop_fuel_pump", "clean", G.q(sx, sz, 32.0 + k2 * 6.0, 64.5), 0.0)
	for bu: float in [29.6, 35.0, 40.4]:
		for bv: float in [63.0, 66.0]: I.add(props, "prop_bollard_iron", "rusty", G.q(sx, sz, bu, bv), 0.0)
	I.add(props, "prop_tank_vertical", "dirty", G.q(sx, sz, 21.5, 72.0), 0.0)          # 9 m across
	I.add(props, "prop_k_rail", "dirty", G.q(sx, sz, 28.5, 77.4), 0.0)                 # the tank's corner, by the truck path
	# ---- the wash's apron: grime runs off it, a hose reel, drums of soap
	for k3 in 3: I.add(props, "prop_channelizer_drum", "dirty", G.q(sx, sz, 92.5, 74.0 + k3 * 0.9), 0.0)
	I.add(props, "prop_hose_reel_cart", "worn", G.q(sx, sz, 60.0, 80.0), 90.0)
	# ---- crew gear: sweeper brooms and cones by the lock-ups, a rolloff for street sweepings, the signs crew's stock
	for k4 in 8: I.add(props, "prop_cone_28in", "dirty", G.q(sx, sz, 88.0 + (k4 % 2) * 0.6, 26.0 + (k4 / 2) * 0.7), k4 * 41.0)
	for k5 in 4: I.add(props, "prop_barricade_type1", "worn", G.q(sx, sz, 89.0, 39.0 + k5 * 1.8), 90.0)
	for k6 in 4: I.add(props, "prop_water_barrier_orange", "dirty", G.q(sx, sz, 88.5, 47.0 + k6 * 2.1), 90.0)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", G.q(sx, sz, 56.0, 92.0), 0.0)
	I.add(props, "prop_temp_fence_stand", "worn", G.q(sx, sz, 85.0, 60.0), 0.0)
	for k9 in 3: I.add(props, "prop_barricade_type3", "worn", G.q(sx, sz, 88.0, 67.5 + k9 * 2.8), 90.0)     # road-closure stock
	for k9 in 2: I.add(props, "fence_temp_fence_panel_screen", "rusty", G.q(sx, sz, 82.5, 61.0 + k9 * 0.3), 90.0, false)
	for k7 in 3: I.add(props, "fence_temp_fence_panel", "worn", G.q(sx, sz, 84.0, 61.5 + k7 * 0.3), 90.0, false)
	for p: Vector2 in [Vector2(36.0, 44.0), Vector2(70.0, 44.0), Vector2(46.0, 70.0), Vector2(80.0, 66.0)]:
		I.add(props, "prop_lot_light_pole", "dirty", G.q(sx, sz, p.x, p.y), 0.0)
	# ---- back doors: office bins and recycling, the store's cardboard skip
	I.back_door_clutter(props, rr, G.q(sx, sz, 42.0, 32.0), 180.0, "shop")
	I.add(props, "prop_trash_cart_blue", "worn", G.q(sx, sz, 30.0, 31.7), 180.0)
	I.add(props, "prop_dumpster_3yd_green", "rusty", G.q(sx, sz, 61.5, 30.5), 180.0)
	# ---- sidewalk: a USPS box and a paper box by the office (people come for permits); the bus stop stays clear
	G.walk_prop(props, m, sx, sz, "x", 27.0, "prop_usps_collection_box", "worn")
	G.walk_prop(props, m, sx, sz, "x", 31.5, "prop_newspaper_box_red", "dirty")
	G.walk_prop(props, m, sx, sz, "z", 31.0, "prop_trash_receptacle", "dirty")
	# ---- wear: fleet yard = oil at every stall, the fuel island's stains, soap and grime off the wash
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	for r: Array in stl: W.oil(dec, rr, Vector2(float(r[0]), float(r[1])), float(r[2]), S.walk_y, 0.85)
	for k8 in 6: W.oil(dec, rr, Vector2(sx * (30.0 + k8 * 2.0), sz * (64.5 + rr.randf_range(-1.5, 1.5))), 0.0, S.walk_y, 0.95)
	dec.add(14, Vector2(sx * 75.0, sz * 78.0), 0.0, 14.0, 6.0, S.walk_y, Color(1, 1, 1, 0.6))
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 82.0), Vector2(sx * 75.0, sz * 76.0))
	I.truck_path(dec, rr, Vector2(sx * 40.0, sz * 76.0), Vector2(sx * 35.0, sz * 64.5))
	I.yard_wear(dec, rr, sx, sz, 22.0, 36.0, 92.0, 99.0, 1.4)
	I.yard_wear(dec, rr, sx, sz, 56.0, 22.0, 92.0, 36.0, 1.0)
	root.set_meta("stalls", stl)
	I.finish(root, g, props, dec, NAME)
	quit()
