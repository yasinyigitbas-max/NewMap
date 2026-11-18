extends SceneTree
## Piece m_gr_ad5nw (commercial strip growth, VARIANT C "neighbourhood centre", 18 Nov): the block between the strip
## sample's parking garage / storage yard and 5th St, west of Adela Ave (grid u 400-491.3, v -1100 to -1009.2), placed
## at the Adela x 5th junction (500, 4, -1000). Nearly flat (5th St west rises 0.6 m to the west: the lot follows it).
## Why this use (city planner): this is where the strip meets the houses - 5th St west of Adela is a residential street,
## the Crown Hill houses come up to the block's west edge. Not drive-by trade any more: a small L-shaped neighbourhood
## centre people walk or drive to from their homes - a discount grocer anchoring the corner of the L, a laundromat, a
## nail salon and a dentist in the inline row, a slice pizza and a dry cleaner in the corner unit, a credit union on
## the corner pad at the signal, and a bottle-and-can recycling booth (California's deposit: people bring bags of cans
## on foot and by cart). Toward the houses it is softened: a CMU wall with a eucalyptus buffer on the west edge (the
## grocer's loading yard is beside it), a stucco garden wall with privet and magnolias along 5th St; lot entrances only
## from Adela's two standard aprons, none on the residential street.
## Variant differences: an L-shaped centre (the sample has a straight strip mall), stucco garden wall, privet hedge,
## magnolias / torrey pines instead of palms, the recycling booth, a cart corral, concrete wheel stops (an older centre).
## Run once (tools/city/run/build.sh m_gr_ad5nw); never when locked.
const G := preload("res://tools/city/pilot/pieces/strip_grow_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := G.new("m_gr_ad5nw", "C neighbourhood centre")
	# ---------------------------------------------------------------- the L: grocer on the west leg, the row on the north leg
	var gro := b.bld("extras/ext_grocery_market", -86.0, -84.0, 90.0, "dollar_plus_market", 0.8)     # front faces +x (the lot)
	b.paints.append(b.rect(-74.0, -99.0, -72.0, -69.0, "concrete"))          # the grocer's walk
	b.add("prop_cart_corral", "worn", -73.0, -72.5, 90.0)
	for k in 3: b.add("prop_shopping_cart", "worn", -72.6, -90.0 + k * 0.9, 90.0)
	b.add("prop_ice_chest", "worn", -73.2, -76.6, 90.0); b.add("prop_propane_cylinder_100lb", "rusty", -73.0, -78.6, 0.0)
	var row := b.bld("commercial/com_boutique_row", -63.0, -92.0, 0.0, "adela_plaza_row", 0.8)
	var cor := b.bld("commercial/com_orange_corner", -46.0, -92.0, 0.0, "adela_plaza_corner", 0.8)
	b.paints.append(b.rect(-72.0, -85.0, -40.0, -83.0, "concrete"))          # covered walk along the row
	for e: Array in [[-70.6, "prop_park_bench"], [-62.6, "prop_trash_receptacle"], [-59.5, "prop_bike_rack"], [-50.0, "prop_newspaper_box_blue"], [-41.4, "prop_trash_receptacle"]]:
		b.add(String(e[1]), "worn", float(e[0]), -83.6, 0.0)
	b.add("plant_potted_leafy", "normal", -57.2, -84.3); b.add("plant_potted_succulent", "normal", -52.2, -84.4)
	b.add("prop_usps_collection_box", "worn", -39.0, -83.4, 0.0)
	b.roof(gro, ["prop_ac_condenser", "prop_ac_condenser", "prop_vent_box", "prop_solar_panel_x3", "prop_solar_panel_x3"])
	b.roof(row, ["prop_ac_condenser_compact", "prop_vent_plumbing", "prop_satellite_dish_round"])
	b.roof(cor, ["prop_vent_box", "prop_ac_condenser_compact"])                # the pizza oven's exhaust
	# ---------------------------------------------------------------- the lot (entered from Adela at 45 / 80 m)
	b.stalls_x(-68.0, 15, -77.0, -1.0)                                        # nose-in at the row
	b.stalls_x(-68.0, 16, -69.5, 1.0); b.stalls_x(-68.0, 16, -58.5, -1.0)
	b.island(-24.8, -69.4, -22.0, -58.6, 1, ["tree_magnolia_a"])
	b.stalls_x(-68.0, 11, -51.5, 1.0)
	b.island(-38.3, -51.4, -35.5, -46.1, 1, ["tree_magnolia_b"])
	for p: Vector2 in [Vector2(-23.4, -61.0), Vector2(-46.0, -64.0), Vector2(-70.0, -55.0), Vector2(-25.0, -81.0)]:
		b.add("prop_lot_light_pole", "worn", p.x, p.y, 0.0)
	# ---------------------------------------------------------------- the credit union on the corner pad at the signal
	var cu := b.bld("commercial/com_bank", -29.0, -31.0, 0.0, "community_credit_union", 0.7)
	b.paints.append(b.rect(-36.5, -24.0, -21.5, -22.0, "concrete"))
	b.stalls_z(-40.5, 5, -38.0, -1.0)                                         # its own short row on the west side
	b.add("prop_trash_receptacle", "worn", -21.9, -22.6, 0.0); b.add("plant_potted_succulent", "normal", -35.8, -22.6)
	b.roof(cu, ["prop_ac_condenser", "prop_vent_plumbing"])
	# ---------------------------------------------------------------- recycling booth + the grocer's loading yard (west side)
	var bo := b.bld("commercial/com_kiosk", -80.0, -44.0, 90.0, "recycling_booth", 0.85)
	for k in 3: b.add(["prop_dumpster_3yd_blue", "prop_dumpster_3yd_blue", "prop_dumpster_3yd_green"][k], "rusty", -91.0, -50.0 + k * 3.4, 90.0)
	for k in 4: b.add("prop_recycling_receptacle", "dirty", -76.0, -49.5 + k * 0.9, 90.0)
	b.add("prop_container_20ft_white", "dirty", -88.0, -33.0, 0.0)            # baled cans wait for the truck
	b.add("prop_shopping_cart", "dirty", -74.5, -41.0, 35.0); b.add("prop_shopping_cart", "dirty", -75.2, -38.2, -20.0)
	b.paints.append(b.rect(-98.0, -69.0, -72.0, -56.0, "asphalt"))
	b.enclosure(-92.0, -64.0, 90.0)                                           # the grocer's bins at its loading side
	b.add("prop_dumpster_rolloff_20yd", "rusty", -84.0, -61.5, 0.0)          # cardboard
	b.add("prop_k_rail", "worn", -77.0, -63.0, 90.0)
	# ---------------------------------------------------------------- toward the houses: CMU wall + eucalyptus, stucco garden wall
	b.fence("cmu", -99.6, -99.5, -99.6, -10.0, "worn", 5)
	b.paints.append(b.rect(-99.3, -55.0, -95.0, -20.0, "grass"))            # the buffer strip beside the wall (trees stand in grass)
	for k in 3: b.add(["tree_eucalyptus_a", "tree_eucalyptus_b"][k % 2], "normal", -97.2, -51.0 + k * 13.0, k * 47.0)
	var x := -97.0
	while x < -12.0:
		if absf(x + 46.0) > 2.2: b.add("fence_stucco_wall", "worn", x + 1.0, -11.2, 0.0)   # a gap for the walk-in path from the houses
		x += 2.03
	b.paints.append(b.rect(-95.0, -20.0, -12.0, -9.2, "grass"))
	for hx: float in [-92.0, -82.0, -72.0, -62.0, -54.0, -38.0, -28.0, -18.0]: b.add("hedge_privet_2m", "normal", hx, -12.6, 0.0)
	for t: Array in [["tree_magnolia_a", -86.0], ["tree_torrey_pine_b", -66.0], ["tree_magnolia_b", -34.0], ["tree_torrey_pine_a", -18.0]]:
		b.add(String(t[0]), "normal", float(t[1]), -16.5, float(t[1]) * 7.0)
	b.paints.append(b.rect(-48.0, -20.0, -44.0, -11.6, "concrete"))          # the path from 5th St into the lot
	b.add("plant_bougainvillea_wall", "normal", -56.0, -10.5, 0.0); b.add("plant_bougainvillea_wall", "normal", -30.0, -10.5, 0.0)   # on the street side of the wall
	b.island(-12.0, -74.0, -9.0, -52.0, 1, ["palm_queen_a"])               # planting on Adela between the two entrances
	b.add("prop_pylon_sign", "worn", -10.5, -66.0, 90.0)                     # ADELA PLAZA tenants, facing Adela
	# ---------------------------------------------------------------- polish pass (lots of props, a neighbourhood centre's life)
	var tries := func(base: String, cond: String, x: float, z: float, yaw: float) -> void:
		if b.free_at(x, z, b.half(base)): b.add(base, cond, x, z, yaw)
	b.door_life()
	b.fire_lane(-72.0, -83.0, -40.0, -83.0, Vector2(0, 1)); b.fire_lane(-72.0, -99.0, -72.0, -69.0, Vector2(1, 0))
	b.pole_line(-98.3, -54.0, -98.3, -22.0, 16.0)                             # power along the back fence, in the buffer strip
	for m: Vector2 in [Vector2(-50.0, -55.0), Vector2(-30.0, -73.0), Vector2(-62.0, -45.0)]:
		b.add("prop_manhole_cover", "dirty", m.x, m.y, 0.0, false, 0.002)
	tries.call("prop_cart_corral", "worn", -44.0, -48.7, 0.0)               # a corral at the far rows: people park and walk
	for c: Vector3 in [Vector3(-56.0, -61.5, 25.0), Vector3(-33.0, -55.0, -70.0), Vector3(-66.0, -49.0, 110.0)]:
		tries.call("prop_shopping_cart", "dirty", c.x, c.y, c.z)            # the ones nobody brought back
	tries.call("prop_park_bench", "worn", -42.0, -22.9, 0.0)               # by the walk-in path: grandparents wait for the laundry
	tries.call("prop_bike_rack", "worn", -50.5, -22.9, 0.0)
	tries.call("prop_newspaper_box_red", "worn", -21.8, -24.6, -90.0)
	tries.call("prop_mailbox_post_metal", "worn", -37.4, -22.6, 0.0)
	tries.call("prop_vending_soda", "worn", -73.4, -80.6, 90.0)            # outside the grocer, by the ice chest
	tries.call("prop_trash_receptacle", "dirty", -73.2, -70.8, 90.0)
	tries.call("prop_cone_28in", "dirty", -78.0, -58.0, 0.0)
	# ---------------------------------------------------------------- polish, wear
	for p2: Vector2 in [Vector2(-50.0, -73.0), Vector2(-30.0, -55.0), Vector2(-60.0, -45.0), Vector2(-80.0, -66.5)]:
		b.add("prop_storm_drain_grate", "dirty", p2.x, p2.y, 0.0, false, 0.002)
	b.building_wear()
	b.stall_wear(0.7)
	b.tyre_path(-9.0, -80.0, -40.0, -73.0); b.tyre_path(-9.0, -45.0, -40.0, -55.0); b.tyre_path(-60.0, -55.0, -84.0, -60.0)
	for k in 10: b.dec.add(14, Vector2(b.rr.randf_range(-92.0, -74.0), b.rr.randf_range(-52.0, -30.0)), b.rr.randf_range(0, 180), 2.5, 2.5, b.yfn, Color(1, 1, 1, 0.6))   # spilt soda round the recycling
	b.yard_wear(-99.0, -99.0, -10.0, -20.0, 1.1)
	b.finish("prop_wheel_stop_concrete")
	quit()
