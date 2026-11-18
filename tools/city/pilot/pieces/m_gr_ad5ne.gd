extends SceneTree
## Piece m_gr_ad5ne (commercial strip growth, VARIANT A "car care corner", 18 Nov): the block between the strip sample's
## grocery yard and 5th St, from Adela Ave to Glorietta Blvd (grid u 508.7-645.7, v -1100 to -1014.3), placed at the
## Adela x 5th junction (500, 4, -1000). Flat (pad 4).
## Why this mix (city planner): 5th St east of Adela is the strip's spur to the ring and the golf course; drivers coming
## off the bridge loop round here. Car care clusters on such a corner in every American strip - a tunnel car wash on the
## ring corner (seen from Glorietta Blvd and 5th St), a quick-lube with its bays to the lot, and the businesses people
## wait in while their car is done: a chicken drive-thru on the signalised corner pad, a mattress outlet and a phone /
## vape shop in a small retail row, a taqueria and a tax office on Adela's walk. 5th St east has a palm parkway and no
## driveway aprons (road kit), the ring none either: the lot is entered from Adela's two standard aprons (45 / 80 m),
## the other frontages get a landscape strip with the pylon signs, so nothing drives over a kerb.
## Variant differences from the sample (m_*): car wash (svc_carwash, never used before), rubber wheel stops (a newer lot),
## white vinyl rail along the landscape strip, a stucco screen wall with bougainvillea round the wash's vacuum bays,
## solar panels and vents on the flat roofs, compact AC units, torrey pines in the islands, cones in the wash lane.
## Run once (tools/city/run/build.sh m_gr_ad5ne); never when locked.
const G := preload("res://tools/city/pilot/pieces/strip_grow_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const L := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const PALMS := ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c", "palm_queen_a"]
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := G.new("m_gr_ad5ne", "A car care corner")
	# ---------------------------------------------------------------- back row: retail row + quick-lube
	var row := b.bld("commercial/com_orange_row", 56.0, -92.0, 0.0, "crown_car_care_row", 0.8)
	b.paints.append(b.rect(46.0, -85.0, 66.0, -83.0, "concrete"))            # walk in front of the doors
	for e: Array in [[48.2, "prop_trash_receptacle"], [57.4, "prop_bike_rack"], [61.2, "prop_newspaper_box_blue"]]:
		b.add(String(e[1]), "worn", float(e[0]), -83.6, 0.0)                   # between the doors (doors at x 52, 54, 64)
	b.add("plant_potted_succulent", "normal", 50.3, -84.4); b.add("plant_potted_succulent", "normal", 65.4, -84.4)
	var lube := b.bld("industrial/ind_repair", 79.0, -91.0, 0.0, "quick_lube", 0.85)
	b.paints.append(b.rect(70.0, -83.0, 88.0, -77.5, "concrete"))            # bay apron: cars wait nose to the doors
	for k in 3: b.add("prop_channelizer_drum", "dirty", 89.0, -97.0 + k * 0.85, 0.0)   # used oil
	b.add("prop_dumpster_rolloff_20yd", "rusty", 95.5, -94.0, 90.0)           # old filters and tyres
	b.add("prop_cone_18in", "worn", 72.5, -80.0, 0.0); b.add("prop_cone_18in", "worn", 85.5, -80.0, 0.0)
	b.add("prop_sign_no_parking", "worn", 69.4, -82.6, 0.0)
	b.enclosure(42.0, -95.5, 180.0)                                            # the row's bins, on its west end
	# ---------------------------------------------------------------- Adela walk: taqueria + tax office (shops on the sidewalk)
	b.bld("commercial/com_shallow_surf", 12.7, -62.0, -90.0, "taqueria_adela", 0.75)
	b.add("prop_picnic_table", "worn", 18.6, -60.0, 0.0); b.add("prop_beach_umbrella", "worn", 18.6, -60.0, 0.0)  # two tables at the window
	b.add("prop_picnic_table", "worn", 18.6, -64.6, 0.0); b.add("prop_beach_umbrella_closed", "worn", 18.6, -64.6, 0.0)
	b.paints.append(b.rect(16.2, -67.0, 22.0, -57.0, "concrete"))
	b.add("prop_trash_receptacle", "dirty", 16.8, -56.6, 0.0)
	b.bld("commercial/com_realty", 16.2, -94.0, -90.0, "tax_office", 0.7)
	b.add("prop_mailbox_post_metal", "worn", 9.6, -88.6, -90.0)
	# ---------------------------------------------------------------- the lot (entered from Adela's aprons at 45 / 80 m)
	b.stalls_x(46.5, 7, -77.5, -1.0)                                           # nose-in at the retail row
	b.stalls_x(46.5, 7, -70.5, 1.0); b.stalls_x(46.5, 7, -59.5, -1.0)        # a double row ...
	b.island(65.6, -70.4, 68.4, -59.6, 1, ["tree_torrey_pine_b"])            # ... broken by a torrey pine island
	b.stalls_x(68.5, 13, -70.5, 1.0); b.stalls_x(68.5, 13, -59.5, -1.0)
	b.island(103.7, -70.4, 106.5, -59.6, 1, ["palm_queen_b"])
	b.island(43.6, -70.4, 46.4, -59.6, 1, ["tree_coral_a"])                  # planted row ends: shade, and the
	b.island(43.6, -83.0, 46.4, -77.6, 0, PALMS)                              # turning cars keep off the end stalls
	b.island(41.0, -52.4, 46.4, -47.0, 1, ["tree_jacaranda_a"])
	b.island(70.4, -52.4, 72.4, -47.0, 0, PALMS); b.island(87.6, -52.4, 89.9, -47.0, 0, PALMS)
	b.island(106.3, -52.4, 108.0, -47.0, 0, PALMS)
	for p: Vector2 in [Vector2(67.0, -65.0), Vector2(105.1, -65.0), Vector2(30.0, -72.0), Vector2(60.0, -40.0), Vector2(100.0, -40.0)]:
		b.add("prop_lot_light_pole", "worn", p.x, p.y, 0.0)
	b.stalls_x(46.5, 9, -52.5, 1.0); b.stalls_x(90.0, 6, -52.5, 1.0)                                           # south side of aisle B: diner / chicken customers
	# ---------------------------------------------------------------- the chicken drive-thru on the corner pad
	var ck := b.bld("ck/mod_fastfood", 26.0, -30.0, 0.0, "chicken_drive", 0.75)
	b.paints.append(b.rect(19.0, -24.0, 33.0, -22.4, "concrete"))
	# drive-thru: in from the lot down the WEST side (window on the driver's left), across the front, back up the east side
	b.paints.append(b.rect(12.0, -41.5, 12.15, -21.0, "white")); b.paints.append(b.rect(12.0, -21.15, 37.5, -21.0, "white"))
	b.paints.append(b.rect(37.35, -41.5, 37.5, -21.0, "white"))
	b.arrow_z(15.5, -38.0, -34.0); b.arrow_z(15.5, -30.0, -26.0); b.arrow_x(-19.2, 22.0, 27.0); b.arrow_z(35.3, -26.0, -30.0)
	b.paints.append(b.rect(17.6, -40.2, 19.4, -36.6, "concrete"))            # menu-board island before the window
	b.add("prop_drive_thru_menu", "worn", 18.5, -38.4, 90.0)                  # faces the lane (west)
	b.add("prop_bollard_steel", "worn", 18.8, -36.0, 0.0); b.add("prop_bollard_steel", "worn", 18.8, -40.9, 0.0)
	b.add("prop_trash_receptacle", "dirty", 33.6, -22.9, 0.0); b.add("prop_bench_bus_stop", "worn", 30.0, -22.9, 180.0)   # a bench by the door
	b.enclosure(26.0, -41.5, 180.0, false)
	# ---------------------------------------------------------------- the car wash on the ring corner
	# (the kit model: office at its south end, three self-serve bays under the canopy and the automatic tunnel at the
	# north end, all open to its FRONT, which faces Glorietta Blvd so drivers see the bays; cars queue down the front
	# lane from the lot's north aisle, drive through and leave out of the back to the vacuum bays)
	var cw := b.bld("services/svc_carwash", 124.0, -52.0, 90.0, "bayside_express_wash", 0.7)
	b.paints.append(b.rect(133.0, -77.5, 142.6, -36.0, "asphalt"))
	b.paints.append(b.rect(137.4, -76.0, 137.55, -66.0, "white"))           # two pay lanes, a pay station each
	b.add("prop_pay_station", "worn", 137.5, -68.5, 90.0)
	b.paints.append(b.rect(136.6, -68.0, 138.4, -66.0, "concrete"))
	b.arrow_z(135.2, -75.0, -71.0); b.arrow_z(140.0, -75.0, -71.0); b.arrow_z(137.5, -60.0, -56.0)
	for k in 5: b.add("prop_cone_18in", "worn", 142.0, -64.0 + k * 3.0, 0.0)  # keep the queue off the planting
	b.add("prop_sign_no_parking", "worn", 142.2, -76.5, -90.0)
	b.arrow_z(112.0, -60.0, -50.0)                                             # out of the back, south to the vacuums
	b.paints.append(b.rect(108.0, -64.0, 115.0, -30.0, "asphalt"))
	b.stalls_x(108.0, 6, -30.0, 1.0, 3.4)                                     # vacuum bays along a stucco screen wall
	var wx := 107.0
	while wx < 129.0:
		b.add("fence_stucco_wall", "worn", wx + 1.0, -23.3, 0.0); wx += 2.03
	b.add("plant_bougainvillea_wall", "normal", 113.0, -23.0, 180.0); b.add("plant_bougainvillea_wall", "normal", 122.0, -23.0, 180.0)
	for k in 6: b.add("prop_trash_receptacle", "worn", 108.0 + 3.4 * k + 1.7, -24.2, 0.0)   # one bin per vacuum bay
	b.add("prop_vending_soda", "worn", 133.6, -37.5, 90.0); b.add("prop_ice_chest", "worn", 133.8, -35.4, 90.0)   # drinks + bagged ice by the office
	b.add("prop_hose_reel_cart", "worn", 114.8, -42.0, 0.0)                   # the attendant's pre-soak hose
	for k in 3: b.add("prop_bollard_iron", "worn", 132.6, -63.0 + k * 1.2, 0.0)   # guards the tunnel's door frame
	# ---------------------------------------------------------------- the diner pad in the middle of the frontage
	var dn := b.bld("commercial/com_bistro", 80.0, -36.0, 0.0, "route_75_diner", 0.75)
	b.paints.append(b.rect(73.5, -29.0, 86.5, -27.0, "concrete"))
	b.stalls_z(-42.0, 5, 72.5, -1.0); b.stalls_z(-42.0, 5, 87.5, 1.0)       # side rows at the diner
	b.add("prop_newspaper_box_red", "worn", 74.2, -27.6, 0.0); b.add("prop_newspaper_box_blue", "worn", 75.0, -27.6, 0.0)
	b.add("prop_park_bench", "worn", 82.0, -27.5, 0.0)                          # people wait for a table, facing the street
	b.add("plant_potted_leafy", "normal", 86.0, -27.5, 0.0)
	b.enclosure(80.0, -45.5, 180.0)
	# ---------------------------------------------------------------- landscape strip on 5th St and the ring, pylons, billboard
	b.island(10.0, -17.3, 106.0, -14.6, 9, PALMS + ["tree_torrey_pine_b"])
	var vx := 40.0
	while vx < 104.0:                                                          # white rail along the strip (a newer lot)
		b.add("fence_vinyl_canal_rail", "clean", vx + 1.0, -17.6, 0.0); vx += 2.015
	b.island(142.9, -98.0, 145.5, -78.0, 2, PALMS); b.island(142.9, -34.0, 145.5, -14.6, 2, PALMS)
	b.add("prop_pylon_sign", "worn", 44.0, -15.95, 0.0)                     # CAR CARE CENTER tenants, facing 5th St
	b.add("prop_pylon_sign", "worn", 144.2, -26.0, 90.0)                     # the wash, facing the ring
	b.add("prop_billboard", "worn", 92.0, -97.5, 180.0)                       # over the lube's yard, facing 5th St traffic
	# ---------------------------------------------------------------- polish: drains, roof plant, back of house, bins
	for p2: Vector2 in [Vector2(80.0, -74.0), Vector2(55.0, -56.0), Vector2(90.0, -49.0), Vector2(30.0, -46.0), Vector2(125.0, -27.0)]:
		b.add("prop_storm_drain_grate", "dirty", p2.x, p2.y, 0.0, false, 0.002)
	b.roof(row, ["prop_solar_panel_x3", "prop_solar_panel_x3", "prop_vent_plumbing", "prop_ac_condenser_compact"])
	b.roof(lube, ["prop_vent_turbine", "prop_vent_turbine", "prop_ac_condenser"])
	b.roof(ck, ["prop_vent_box", "prop_vent_box", "prop_ac_condenser", "prop_vent_plumbing"])     # kitchen exhaust
	b.roof(dn, ["prop_vent_box", "prop_ac_condenser"])
	b.roof(cw, ["prop_vent_box", "prop_solar_panel_x3", "prop_solar_panel_x3", "prop_solar_panel_x3"])
	b.add("prop_ac_condenser_compact", "worn", 41.2, -88.0, 90.0)
	b.add("prop_golf_cart_blue", "worn", 98.5, -88.0, 0.0)                    # lube shop runner
	# ---------------------------------------------------------------- filling the north-east corner (Yasin 18 Nov: "okay go ahead")
	# a tyre shop next to the lube (the two feed each other: the lube sends worn tyres next door), its customers' row in
	# front, its stock in a fenced yard of storage containers against the ring road, a planted strip and a torrey
	# pine at the yard's street side
	var tyre := b.bld("ck/ck_svc_trade", 112.0, -91.0, 0.0, "bridge_tire_pros", 0.85)
	b.roof(tyre, ["prop_vent_turbine", "prop_ac_condenser"])
	b.paints.append(b.rect(106.0, -85.0, 118.0, -83.0, "concrete"))
	b.stalls_x(100.0, 7, -77.5, -1.0)                                         # customers nose to the shop, cars waiting for fitting
	b.add("prop_trash_receptacle", "worn", 105.0, -83.6, 0.0); b.add("prop_newspaper_box_red", "worn", 118.7, -83.6, 0.0)
	b.add("plant_potted_succulent", "normal", 106.6, -84.4); b.add("plant_potted_succulent", "normal", 117.4, -84.4)
	b.fence("chain", 121.0, -98.5, 141.5, -98.5); b.fence("chain", 141.5, -98.5, 141.5, -84.0)
	b.fence("chain", 121.0, -84.0, 128.0, -84.0); b.fence("chain", 134.0, -84.0, 141.5, -84.0)
	b.fence("chain", 121.0, -98.5, 121.0, -84.0)
	b.add("fence_gate_rolling_chainlink", "worn", 130.0, -83.6, 0.0)          # open, slid back along the fence
	for k in 4:
		b.add(["prop_container_20ft_white", "prop_container_20ft_blue", "prop_container_20ft_green", "prop_container_20ft_red"][k], "dirty" if k % 2 == 0 else "worn", 124.5 + k * 2.6, -92.0, 90.0)
	b.add("prop_dumpster_rolloff_20yd", "rusty", 137.0, -91.0, 0.0)          # scrap tyres to the recycler
	b.add("prop_water_barrier_orange", "dirty", 138.5, -86.0, 30.0)
	b.island(142.9, -78.0, 145.5, -66.0, 1, ["tree_torrey_pine_b"])
	# staff parking along the car wash's north wall (the attendants park out of the queue's way)
	b.stalls_x(116.5, 5, -70.6, 1.0)
	b.add("prop_sign_no_parking", "worn", 115.8, -70.4, 0.0)
	# the west part of the lot (taqueria / tax office customers) and the frontage rows facing 5th St
	b.stalls_x(27.5, 6, -70.5, 1.0); b.stalls_x(27.5, 6, -59.5, -1.0)
	b.island(24.7, -70.4, 27.5, -59.6, 1, ["palm_mexican_fan_b"])
	b.stalls_x(46.5, 8, -36.0, -1.0); b.island(68.2, -41.4, 70.2, -36.1, 0, PALMS)
	b.stalls_x(46.5, 8, -24.0, 1.0); b.stalls_x(90.5, 6, -24.0, 1.0)
	b.island(43.6, -24.0, 46.4, -18.6, 1, ["tree_coral_a"]); b.island(87.6, -24.0, 90.4, -18.6, 0, PALMS)
	# more shade and light in the lot
	b.island(98.5, -52.4, 100.5, -47.0, 1, ["tree_coral_b"])
	for p3: Vector2 in [Vector2(118.0, -80.5), Vector2(96.0, -80.5), Vector2(36.0, -60.0)]:
		b.add("prop_lot_light_pole", "worn", p3.x, p3.y, 0.0)
	# ---------------------------------------------------------------- wear
	b.building_wear()
	b.stall_wear(0.6)
	b.tyre_path(20.0, -80.0, 60.0, -74.0); b.tyre_path(20.0, -45.0, 60.0, -49.0)
	b.tyre_path(137.5, -77.0, 137.5, -40.0); b.tyre_path(112.0, -62.0, 112.0, -31.0)
	for k in 10: W.oil(b.dec, b.rr, Vector2(b.rr.randf_range(71.0, 87.0), b.rr.randf_range(-83.0, -78.0)), 0.0, b.yfn, 0.95)   # lube bays
	for k in 6: b.dec.add(14, Vector2(b.rr.randf_range(108.0, 116.0), b.rr.randf_range(-62.0, -40.0)), b.rr.randf_range(0, 180), 3.0, 3.0, b.yfn, Color(1, 1, 1, 0.55))  # wash water
	b.yard_wear(10.0, -99.0, 108.0, -18.0, 0.9)
	b.yard_wear(108.0, -99.0, 142.0, -24.0, 1.2)
	b.tyre_path(131.0, -77.0, 131.0, -86.0)                                   # trucks into the tyre yard
	b.finish("prop_wheel_stop_rubber")
	quit()

