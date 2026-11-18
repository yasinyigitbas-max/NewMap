extends SceneTree
## Piece i_vc_w600_n1600_sw (industrial growth, VARIANT C "cold chain", first dressing; 18 Nov, not locked).
## Site: SW corner of 1st St (bay-front ring) x G Ave, world (-700..-600, -1600..-1500); the city yard
## (i_vb_w800_n1600_se) is its west neighbour, the truck services block (i_vb_w600_n1400_nw) its south neighbour.
## PACIFIC SEAFOOD AND THE BAY ICE PLANT: the boats across the road land their catch here. It is iced, packed and
## held cold, then trucked out at night. The ice plant at the back makes the ice, and its ammonia tanks stand behind it.
## Planner's reasons:
##  - The boulevard frontage has the walk-in places: the fish market (a counter that also does lunch for the whole
##    district) on the corner, the wholesaler's sales office, and then the packing hall. The packing hall's blank side faces
##    the bay because the trucks load on the yard side. The rest is a block wall, so there is no see-through fence on
##    the boulevard.
##  - G Ave carries both truck gates at the street's aprons (51, 86 m): the dry store and the cold store line it, their
##    rollups on the shoulder as in the sample.
##  - Reefer boxes stand plugged in along the ice plant's front; staff park behind the packing hall.
##  - The west edge (the city yard's wall) and the south edge (the truck services block's wall) are built by those blocks.
##    None is added here, so there is never a double fence.
## Run once; never when locked.
const G := preload("res://tools/city/pilot/pieces/ind_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const NAME := "i_vc_w600_n1600_sw"
func _init() -> void: _run.call_deferred()
func _run() -> void:
	S.hill_on = false
	var sx := -1.0; var sz := 1.0
	var m: Dictionary = await G.measure(self, Vector3(-600.0, 2.0, -1600.0), sx, sz)
	var root := Node3D.new(); root.name = NAME
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new(); var rr := W.rng_for(NAME)
	var stl: Array = []
	var paints: Array = G.stall_paint(sx, sz, 44.0, 9, 44.5, -1.0)
	paints.append([-99.8, 72.0, -78.0, 99.8, "gravel"])            # the tank farm
	G.floor(g, m, sx, sz, paints)
	var B: Array = []
	var fx := G.front_x(m, 22.0, 70.0)
	B.append([G.put(bl, props, sx, sz, "x", 23.0, fx, "commercial/com_bistro", "dockside_fish_market"), "commercial/com_bistro"])
	B.append([G.put(bl, props, sx, sz, "x", 37.0, fx, "commercial/com_realty", "pacific_seafood_sales"), "commercial/com_realty"])
	B.append([G.put(bl, props, sx, sz, "x", 46.0, fx, "modular/examples/mod_wh_shed", "fish_packing_hall"), "modular/examples/mod_wh_shed"])
	var fz := G.front_z(m, 22.0, 100.0)
	B.append([G.put(bl, props, sx, sz, "z", 31.0, fz, "ck/mod_stg_row_roofed", "dry_store"), "ck/mod_stg_row_roofed"])
	B.append([G.put(bl, props, sx, sz, "z", 56.0, fz, "industrial/ind_warehouse", "cold_store"), "industrial/ind_warehouse"])
	B.append([G.put_back(bl, props, sx, sz, "x", 40.0, "industrial/ind_factory", "bay_ice_plant"), "industrial/ind_factory"])
	# ---- frontages: the boulevard wall after the packing hall; G Ave chain-link between the buildings and gates
	G.frontage(props, m, sx, sz, "x", [[23.0, 35.0], [37.0, 43.0], [46.0, 70.0]], [], "cmu", 70.0, 99.8)
	G.frontage(props, m, sx, sz, "z", [[31.0, 49.0], [56.0, 80.0]], [51.0, 86.0], "chain", 29.0, 99.8)
	# ---- reefers plugged in along the ice plant's front (power from the plant's wall), white boxes side by side
	for k in 9:
		if k == 4: continue
		I.add(props, "prop_container_20ft_white", "dirty" if k % 3 else "worn", G.q(sx, sz, 44.0 + k * 3.1, 65.5), 0.0)
	# ---- the ammonia tank farm behind a barbed fence on the gravel (refrigerant: kept apart, one gate off the yard)
	I.add(props, "prop_tank_vertical", "dirty", G.q(sx, sz, 83.0, 80.0), 0.0)
	I.add(props, "prop_tank_vertical", "worn", G.q(sx, sz, 83.0, 90.0), 0.0)
	I.add(props, "prop_tank_horizontal_propane", "rusty", G.q(sx, sz, 92.0, 78.0), 0.0)
	I.add(props, "prop_tank_horizontal_propane", "dirty", G.q(sx, sz, 92.0, 88.0), 0.0)
	G.chain(props, sx, sz, Vector2(78.0, 72.0), Vector2(78.0, 99.6), true)
	G.chain(props, sx, sz, Vector2(78.0, 72.0), Vector2(84.0, 72.0), true)
	G.chain(props, sx, sz, Vector2(90.0, 72.0), Vector2(99.6, 72.0), true)
	I.add(props, "fence_gate_rolling_chainlink", "rusty", G.q(sx, sz, 87.0, 72.0), 0.0)
	I.add(props, "prop_switch_rack", "worn", G.q(sx, sz, 96.0, 96.0), 0.0)
	# ---- the fish market's back: ice chests (the catch comes in iced), fish-waste carts, the gas for the fryer
	for k2 in 3: I.add(props, "prop_ice_chest", "clean", G.q(sx, sz, 25.0 + k2 * 1.9, 31.0), 0.0)
	for k3 in 3: I.add(props, "prop_trash_cart_green", "dirty", G.q(sx, sz, 31.5 + k3 * 0.8, 31.0), 180.0)
	I.back_door_clutter(props, rr, G.q(sx, sz, 40.0, 30.5), 0.0, "gas")
	I.add(props, "prop_dumpster_3yd_green", "rusty", G.q(sx, sz, 72.0, 42.2), 0.0)
	# ---- the packing hall's yard door: pallets of ice chests waiting, cones round a wet patch
	for k4 in 4: I.add(props, "prop_ice_chest", "clean", G.q(sx, sz, 72.5, 45.0 + k4 * 1.5), 90.0)
	for k5 in 3: I.add(props, "prop_cone_18in", "dirty", G.q(sx, sz, 62.0 + k5 * 1.2, 50.0), k5 * 50.0)
	for p: Vector2 in [Vector2(38.0, 56.0), Vector2(62.0, 56.0), Vector2(90.0, 50.0)]:
		I.add(props, "prop_lot_light_pole", "dirty", G.q(sx, sz, p.x, p.y), 0.0)
	I.add(props, "prop_utility_pole_transformer", "dirty", G.q(sx, sz, 98.5, 48.0), 0.0)
	I.add(props, "prop_water_tower", "dirty", G.q(sx, sz, 90.0, 60.0), 20.0)    # the ice plant's own water, seen from the bay
	stl.append_array(G.stalls(props, sx, sz, 44.0, 9, 44.5, -1.0))
	# ---- the market's sidewalk: a bench facing the street for the lunch crowd, its bin, the paper box
	G.walk_prop(props, m, sx, sz, "x", 33.0, "prop_trash_receptacle", "dirty")
	G.walk_prop(props, m, sx, sz, "x", 24.5, "prop_newspaper_box_blue", "dirty")
	G.walk_prop(props, m, sx, sz, "z", 26.0, "prop_bike_rack", "rusty")
	# ---- wear: melt water and fish scales: dark grime round the market and the hall's door, oil on the truck court
	for b: Array in B: I.bld_wear(dec, rr, b[0][0], b[0][1], b[0][2], b[1])
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 51.0), Vector2(sx * 60.0, sz * 52.0))
	I.truck_path(dec, rr, Vector2(sx * 9.0, sz * 86.0), Vector2(sx * 38.0, sz * 86.0))
	I.truck_path(dec, rr, Vector2(sx * 60.0, sz * 52.0), Vector2(sx * 56.4, sz * 70.0))
	for k6 in 5: dec.add(14, Vector2(sx * rr.randf_range(64.0, 76.0), sz * rr.randf_range(40.0, 52.0)), rr.randf_range(0, 180), 3.5, 2.5, S.walk_y, Color(1, 1, 1, 0.6))
	I.yard_wear(dec, rr, sx, sz, 34.0, 39.0, 99.0, 72.0, 1.6)
	I.yard_wear(dec, rr, sx, sz, 22.0, 80.0, 40.0, 99.0, 1.0)
	root.set_meta("stalls", stl)
	I.finish(root, g, props, dec, NAME)
	quit()
