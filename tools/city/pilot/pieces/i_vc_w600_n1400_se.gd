extends SceneTree
## Piece i_vc_w600_n1400_se (industrial growth, VARIANT C "cold chain", third dressing; 19 Nov, Yasin: "roll out to
## your whole zone"; not locked). Site: SE corner of 3rd St x G Ave, world (-600..-500, -1400..-1300): the zone's
## south-east corner. G Ave here is a residential street rising 1 m to mid-block (alley mouth at 54-60 m); the houses
## begin east of u = 100 and the gritty edge south of it. Draped onto the slope (G.measure_rows, G.drape).
## CORONADO BREWING CO.: the island's brewery. Four fermenters stand in the yard behind the 3rd St wall (they are the
## block's landmark), the brewhouse is at the back, the kegs wait in their store, and the TAPROOM (walk-in) on the
## 3rd St corner has a beer garden behind it. A brewery is the friendliest industry to put next to houses and the
## gritty edge's bars.
## Planner's reasons:
##  - Malt in and kegs out at 3rd St's own aprons (45, 80 m). The keg store's vans use the alley mouth on G Ave.
##  - Toward the houses' street (G Ave) a planted edge. East edge: the house buffer (stucco wall, bougainvillea, trees),
##    continuing the food wholesaler's to the north. South edge (the gritty block leaves it open): this block's wall.
##  - 3rd St frontage: the taproom, then a block wall (opaque) with the fermenters showing over it, no chain-link.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_vc_w600_n1400_se"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := 1.0; var sz := 1.0
	var J := Vector3(-600.0, 2.0, -1400.0)
	var m: Dictionary = await G.measure(self, J, sx, sz)
	var mr: Dictionary = await G.measure_rows(self, J, sx, sz, 100.0, 100.0, [NAME])
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var stl: Array = []
	var B: Array = []
	var fx := G.front_x(m, 22.0, 36.0)
	B.append([G.put(bl, props, sx, sz, "x", 23.0, fx, "ck/ck_brk3_row2", "brewery_taproom"), "ck/ck_brk3_row2"])
	B.append([G.put_back(bl, props, sx, sz, "x", 50.0, "industrial/ind_factory", "brewhouse"), "industrial/ind_factory"])
	var ks := K.building(bl, "ck/mod_stg_row_roofed", G.q(sx, sz, 26.0, 75.0), 90.0, "keg_store", 0.85)
	B.append([[ks, 18.0, 12.0], "ck/mod_stg_row_roofed"])
	# ---- edges: 3rd St wall with the two gates, the planted G Ave side with the alley gate, the south wall, the buffer
	G.frontage(props, m, sx, sz, "x", [[23.0, 35.0]], [45.0, 80.0], "cmu", 35.0, 91.8)
	G.wall(props, sx, sz, Vector2(16.0, G.eu(m, 16.0) + 0.3), Vector2(16.0, 54.0), "fence_stucco_wall", 0, "worn")
	G.wall(props, sx, sz, Vector2(16.0, 60.0), Vector2(16.0, 99.4), "fence_stucco_wall", 0, "worn")
	I.add(props, "fence_gate_rolling_chainlink", "worn", G.q(sx, sz, 16.6, 63.0), 90.0)
	G.wall(props, sx, sz, Vector2(16.2, 99.3), Vector2(91.8, 99.3), "fence_cmu_wall", 6, "dirty")
	G.house_buffer(props, rr, sx, sz, G.eu(m, 92.0) + 0.3, 99.8)
	var v := 30.0; var kt := 0
	while v < 96.0:
		if absf(v - 57.0) > 6.0:
			props.add(["tree_torrey_pine_b", "tree_eucalyptus_a", "tree_torrey_pine_a", "tree_eucalyptus_b"][kt % 4], "normal", G.q(sx, sz, 12.5 + rr.randf_range(-0.5, 0.5), v), rr.randf_range(0, 360), true, rr.randf_range(0.8, 1.1))
			kt += 1
		v += rr.randf_range(11.0, 14.0)
	# ---- the fermenters (the kit's 9 m vertical tanks), CO2 tanks, the court in front of the brewhouse
	for t: Vector2 in [Vector2(57.5, 30.0), Vector2(69.5, 30.0), Vector2(57.5, 43.0), Vector2(69.5, 43.0)]:
		I.add(props, "prop_tank_vertical", "clean" if t.y < 35.0 else "worn", G.q(sx, sz, t.x, t.y), 0.0)
	I.add(props, "prop_tank_horizontal_propane", "worn", G.q(sx, sz, 86.5, 27.5), 0.0)
	I.add(props, "prop_tank_horizontal_propane", "dirty", G.q(sx, sz, 86.5, 31.0), 0.0)
	# ---- the beer garden behind the taproom: tables under shade sails (each sail over its table), bins, a bench
	for t2: Vector2 in [Vector2(25.5, 37.0), Vector2(32.5, 37.0), Vector2(25.5, 43.5), Vector2(32.5, 43.5)]:
		I.add(props, "prop_picnic_table", "worn", G.q(sx, sz, t2.x, t2.y), 0.0)
	for t3: Vector2 in [Vector2(25.5, 37.0), Vector2(32.5, 43.5)]:
		I.add(props, "prop_shade_sail", "clean", G.q(sx, sz, t3.x, t3.y), 0.0, false)
	# keg boxes, the spent-grain skip a farmer collects, lights, power
	for k3 in 3: I.add(props, "prop_container_20ft_white", "worn" if k3 % 2 else "dirty", G.q(sx, sz, 40.0, 84.0 + k3 * 0.0 + k3 * 2.7), 90.0)
	I.add(props, "prop_dumpster_rolloff_20yd", "rusty", G.q(sx, sz, 89.0, 62.0), 0.0)
	for p: Vector2 in [Vector2(39.0, 52.0), Vector2(88.5, 48.0), Vector2(46.0, 92.0)]:
		I.add(props, "prop_lot_light_pole", "worn", G.q(sx, sz, p.x, p.y), 0.0)
	I.add(props, "prop_utility_pole_transformer", "dirty", G.q(sx, sz, 89.5, 40.0), 0.0)
	stl.append_array(G.stalls(props, sx, sz, 18.0, 6, 91.0, 1.0))
	G.walk_prop(props, m, sx, sz, "x", 33.5, "prop_trash_receptacle", "worn"); G.walk_prop(props, m, sx, sz, "z", 33.0, "prop_bike_rack", "worn")
	# ---- POLISH: each with its reason; placed only where free (G.place)
	var obs := G.obstacles(bl, props, stl); var kp := [[41.0, 13.0, 49.0, 70.0], [76.0, 13.0, 84.0, 70.0], [16.0, 54.0, 50.0, 61.0], [49.0, 47.5, 92.0, 68.0]]
	G.place(props, obs, rr, sx, sz, "prop_sign_stop", "worn", 49.0, 15.5, 51.0, 18.0, 180.0, kp, 3.0)                 # trucks leaving onto 3rd St
	G.place(props, obs, rr, sx, sz, "prop_hydrant_red", "rusty", 46.0, 72.0, 49.0, 82.0, 0.0, kp)
	G.spot(props, obs, rr, sx, sz, [["prop_trash_receptacle", "worn"], ["prop_recycling_receptacle", "worn"]], 21.0, 33.0, 37.0, 47.0, 0.0, kp)   # the beer garden's bins and a bench facing the tables
	G.spot(props, obs, rr, sx, sz, [["prop_hose_reel_cart", "worn"], ["prop_channelizer_drum", "dirty"], ["prop_channelizer_drum", "dirty"]], 76.0, 36.0, 90.0, 47.0, 0.0, kp)   # cleaning chemicals and the wash-down hose by the tanks
	G.spot(props, obs, rr, sx, sz, [["prop_trash_cart_black", "worn"], ["prop_trash_cart_green", "worn"]], 36.0, 18.0, 40.0, 30.0, 90.0, kp)   # the taproom's bins
	# ---- wear
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	I.truck_path(dec, rr, Vector2(sx * 45.0, sz * 14.0), Vector2(sx * 45.0, sz * 60.0))
	I.truck_path(dec, rr, Vector2(sx * 80.0, sz * 14.0), Vector2(sx * 80.0, sz * 60.0))
	I.truck_path(dec, rr, Vector2(sx * 16.0, sz * 57.0), Vector2(sx * 33.0, sz * 64.0))
	G.yard_wear(dec, rr, sx, sz, 40.0, 20.0, 91.0, 70.0, 1.2)
	# level pads under the buildings (Yasin 19 Nov: "shop is sunk"), then the floor, then everything onto the ground
	for b: Array in B: G.pad(mr, sx, sz, b[0][0], b[1])
	G.floor_rows(g, mr, sx, sz, [[9.0, 22.0, 16.0, 100.0, "grass"], [92.2, 24.0, 100.0, 100.0, "grass"], [21.0, 33.0, 37.0, 47.0, "gravel"]])
	G.drape(mr, sx, sz, props, dec, bl)
	var st2: Array = []
	for r: Array in stl: st2.append([r[0], r[1], r[2], G.h_at(mr, sx * float(r[0]), sz * float(r[1])), 0.0])
	root.set_meta("stalls", st2)
	I.finish(root, g, props, dec, NAME)
	quit()
