extends SceneTree
## Piece i_vc_w600_n1400_ne (industrial growth, VARIANT C "cold chain", second dressing; 18 Nov, not locked).
## Site: NE corner of 3rd St (the arterial) x G Ave, world (-600..-500, -1500..-1400): the zone's east end on 3rd St,
## next to the houses (u = 100, the transition edge, as the boatyard north of it).
## 3RD STREET FOOD WHOLESALE: where the island's restaurants, diners and corner shops stock up. There is a cash-and-
## carry restaurant supply (walk-in, two counters), a produce hall and a meat packer, and the shift canteen on the corner
## (walk-in) feeds both this block and the truck services across G Ave.
## Planner's reasons:
##  - Customers come by van and car: they turn in at 3rd St's apron (62 m) to a small lot behind the store, with a cart
##    corral. Deliveries use G Ave's gates (44, 79 m) to the meat packer's dock and the produce hall's back.
##  - The east edge is the house buffer (stucco wall, bougainvillea, trees on grass), continuing the boatyard's.
##  - The north edge is this block's block wall, which the boatyard shares and does not double.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_vc_w600_n1400_ne"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := -1.0
	var m: Dictionary = await G.measure(self, Vector3(-600.0, 2.0, -1400.0), sx, sz)
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var stl: Array = []
	var paints: Array = G.stall_paint(sx, sz, 37.0, 8, 35.5, -1.0)
	paints.append_array(G.stall_paint(sx, sz, 37.0, 8, 47.3, 1.0))
	paints.append([92.2, -99.8, 99.8, -24.0, "grass"])
	G.floor(g, m, sx, sz, paints)
	var B: Array = []
	var fx := G.front_x(m, 22.0, 92.0)
	B.append([G.put(bl, props, sx, sz, "x", 23.0, fx, "commercial/com_orange_corner", "shift_canteen"), "commercial/com_orange_corner"])
	B.append([G.put(bl, props, sx, sz, "x", 37.0, fx, "ck/ck_svc_trade", "island_restaurant_supply"), "ck/ck_svc_trade"])
	B.append([G.put(bl, props, sx, sz, "x", 66.0, fx, "industrial/ind_warehouse", "produce_hall"), "industrial/ind_warehouse"])
	var fz := G.front_z(m, 22.0, 100.0)
	B.append([G.put(bl, props, sx, sz, "z", 48.0, fz, "modular/examples/mod_wh_shed", "meat_packers"), "modular/examples/mod_wh_shed"])
	G.frontage(props, m, sx, sz, "x", [[23.0, 35.0], [37.0, 49.0], [66.0, 90.0]], [62.0], "chain", 49.0, 91.8)
	G.frontage(props, m, sx, sz, "z", [[48.0, 72.0]], [44.0, 79.0], "chain", 30.0, 99.8)
	G.wall(props, sx, sz, Vector2(G.ev(m, 99.8) + 0.2, 99.8), Vector2(91.8, 99.8), "fence_cmu_wall", 5)
	G.house_buffer(props, rr, sx, sz, G.eu(m, 92.0) + 0.3, 99.8)
	# ---- customers' lot behind the store: two facing rows, cart corral, carts left out
	stl.append_array(G.stalls(props, sx, sz, 37.0, 8, 35.5, -1.0, "prop_wheel_stop_concrete"))
	stl.append_array(G.stalls(props, sx, sz, 37.0, 8, 47.3, 1.0, "prop_wheel_stop_concrete", [3]))
	I.add(props, "prop_cart_corral", "clean", G.q(sx, sz, 46.45, 47.9), 90.0)
	for k in 3: I.add(props, "prop_shopping_cart", "clean", G.q(sx, sz, 57.0 + k * 1.3, 40.6 + k * 0.6), 70.0 + k * 25.0, false)
	# ---- the meat packer's dock (reefer trailers at the doors) and the produce hall's yard door (pallet bins = ice chests)
	for k in 5: I.add(props, "prop_container_20ft_white", "dirty" if k % 2 else "worn", G.q(sx, sz, 39.5, 52.0 + k * 3.6), 90.0)
	for k in 4: I.add(props, "prop_ice_chest", "clean", G.q(sx, sz, 72.0 + k * 1.9, 44.5), 0.0)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", G.q(sx, sz, 80.0, 52.0), 0.0)          # spoiled produce, crates
	for k in 4: I.add(props, "prop_trash_cart_green", "dirty", G.q(sx, sz, 84.0 + k * 0.8, 44.8), 180.0)
	I.add(props, "prop_dumpster_3yd_green", "rusty", G.q(sx, sz, 36.0, 76.5), 90.0)            # the packer's bone bin
	# ---- the canteen's back: gas, bins; a soda machine by its side door for the night shift
	I.back_door_clutter(props, rr, G.q(sx, sz, 28.5, 31.6), 180.0, "gas")
	I.back_door_clutter(props, rr, G.q(sx, sz, 43.0, 31.4), 180.0, "shop")
	I.add(props, "prop_vending_soda", "clean", G.q(sx, sz, 22.3, 24.0), -90.0)
	I.add(props, "prop_vending_snack", "clean", G.q(sx, sz, 22.3, 25.3), -90.0)
	for bv: float in [23.0, 26.6]: I.add(props, "prop_bollard_steel", "rusty", G.q(sx, sz, 20.9, bv), 0.0)    # cars park by the machines
	for p: Vector2 in [Vector2(54.0, 40.0), Vector2(60.0, 66.0), Vector2(86.0, 70.0)]:
		I.add(props, "prop_lot_light_pole", "dirty", G.q(sx, sz, p.x, p.y), 0.0)
	I.add(props, "prop_utility_pole_transformer", "dirty", G.q(sx, sz, 88.0, 92.0), 0.0)
	for k in 3: I.add(props, "prop_cone_28in", "dirty", G.q(sx, sz, 64.0 + k * 1.3, 56.0), k * 40.0)
	# ---- sidewalk: canteen's bin and paper boxes, a bike rack for the shift workers, the store's bin
	G.walk_prop(props, m, sx, sz, "x", 26.0, "prop_trash_receptacle", "dirty")
	G.walk_prop(props, m, sx, sz, "x", 33.5, "prop_newspaper_box_blue", "worn"); G.walk_prop(props, m, sx, sz, "x", 34.4, "prop_newspaper_box_red", "dirty")
	G.walk_prop(props, m, sx, sz, "z", 26.0, "prop_bike_rack", "worn")
	G.walk_prop(props, m, sx, sz, "x", 47.0, "prop_trash_receptacle", "worn")
	# ---- wear: car park oil, carts' wheel streaks, the dock's melt-water and grime
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	for r: Array in stl: W.oil(dec, rr, Vector2(float(r[0]), float(r[1])), float(r[2]), S.walk_y, 0.7)
	I.truck_path(dec, rr, Vector2(sx * 62.0, sz * 14.0), Vector2(sx * 62.0, sz * 40.0))
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 44.0), Vector2(sx * 33.0, sz * 44.0))
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 79.0), Vector2(sx * 70.0, sz * 60.0))
	G.yard_wear(dec, rr, sx, sz, 34.0, 30.0, 91.0, 99.0, 1.3)
	G.yard_wear(dec, rr, sx, sz, 22.0, 72.0, 34.0, 99.0, 0.8)
	# ---- POLISH (Yasin 18 Nov: "lots of props"; each with its reason; placed only where free, G.place)
	var obs := G.obstacles(bl, props, stl); var kp := [[36.0, 37.5, 60.0, 45.5], [58.5, 13.0, 65.5, 41.0], [8.0, 41.0, 34.0, 47.0], [8.0, 58.0, 72.0, 82.0]]
	G.place(props, obs, rr, sx, sz, "prop_sign_stop", "worn", 65.8, 15.0, 67.5, 18.0, 180.0, kp, 3.0)             # customers leaving onto 3rd St
	G.place(props, obs, rr, sx, sz, "prop_hydrant_red", "rusty", 88.0, 46.0, 91.0, 54.0, 0.0, kp)                 # the produce hall's fire hydrant
	G.spot(props, obs, rr, sx, sz, [["prop_picnic_table", "worn"], ["prop_picnic_table", "worn"], ["prop_trash_receptacle", "worn"], ["prop_recycling_receptacle", "worn"]], 22.5, 31.5, 35.5, 40.5, 0.0, kp)   # the canteen's outdoor tables for the shift
	G.spot(props, obs, rr, sx, sz, [["prop_ice_chest", "clean"], ["prop_ice_chest", "clean"], ["prop_ice_chest", "clean"]], 44.0, 52.0, 58.0, 57.0, 0.0, kp)   # pallet bins waiting at the meat packer's dock
	G.spot(props, obs, rr, sx, sz, [["prop_shopping_cart", "clean"], ["prop_shopping_cart", "clean"]], 50.0, 30.0, 58.0, 37.0, 30.0, kp)   # carts left at the store's door
	G.spot(props, obs, rr, sx, sz, [["prop_trash_cart_green", "dirty"], ["prop_trash_cart_black", "worn"]], 50.0, 29.5, 56.0, 32.0, 180.0, kp)   # the store's bins
	root.set_meta("stalls", stl)
	I.finish(root, g, props, dec, NAME)
	quit()
