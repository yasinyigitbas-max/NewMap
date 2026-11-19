extends SceneTree
## Piece n_apt_b1_7th - apartment band fill, BLOCK 1, its SOUTH part on 7th St: 7th St x Adela Ave.
## Layout row: pos [250, 6, -600], yaw 0 (the apartment sample's junction frame). Quadrant coordinates: u = east of
## B Ave's centre line, v = north of 7th St's centre line (sx = +1, sz = -1). Outline: u 100-240.8 (lot line with the
## sample's a_ne to Adela's property line), v 9.2-100 (7th St's property line to the lot line with n_apt_b1_be).
##
## LAND: 6.10-6.40 m under it (the hump's south slope, u 120-200), 7th St and Adela built at pad 6.0, walk 6.15, a_ne
## at 6.15. One level floor at the walk height, flush with both streets and a_ne; the trial land fit lowers the hump
## (at most 25 cm) 5 cm under it.
##
## WHO LIVES HERE AND WHY:
## 7th St is the band's busy street: it runs from the city centre out to the ring road, the buses use it, and people
## walk it to the corner market at B Ave (a_ne). So this side has its working shops and the older, cheaper flats:
##  S5 (u 100-190, v 9.2-54): on 7th St a brick walk-up with a fire escape and a DRY CLEANER downstairs, a garden
##     apartment, a BOARDED walk-up (the owner died; a roll-off and a fenced yard say the renovation is starting) and
##     a three-storey stucco block. Behind them their stalls on the u-alley, three double garages, the yards.
##  S8 corner (u 196-240.8, v 9.2-54): a row of three small shops on the corner of 7th and Adela (a pharmacy-and-
##     post counter, a tax office, a donut shop: people catch the bus outside) and a COFFEE WINDOW beside it; a walk-up
##     on Adela behind; customers' stalls and the shops' bins enclosure off the v-alley.
##  S4s (u 100-190, v 60-100): CARPORTS on the u-alley for the 7th St flats; the block's SKATE PAD (concrete, a
##     quarter pipe, a funbox, a rail, a bowl corner, chain-link with one gate) for the teenagers - the small ones have
##     a_ne's playground right next door, the older ones had nowhere; the old residents' benches in the shade facing
##     it; stalls off the v-alley.
##  S7s (u 196-240.8, v 60-100): a stucco block and a brick walk-up with the LAUNDERETTE downstairs on Adela (a bench
##     outside, the rack: people wait for the wash), stalls off the v-alley, their yards.
## Alleys: u-alley v 54-60 (continues a_ne's to Adela's apron at v -654..-660 m), v-alley u 190-196 (7th St's apron at
## u 440-446).
## Walk-in places (rooms pass, NOT built here): the dry cleaner, the three corner shops, the coffee window, the
## launderette; the stucco blocks' lobbies.
## Built once by its own script; a draft until Yasin has seen it. Never re-run after that.
const F := preload("res://tools/city/pilot/pieces/apt_fill_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const NAME := "n_apt_b1_7th"
func _init() -> void: _run.call_deferred()

func _run() -> void:
	var sx := 1.0; var sz := -1.0
	var ctx := F.begin(NAME, sx, sz)
	var bl: Node3D = ctx.bl; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec
	var rr: RandomNumberGenerator = ctx.rr; var paints: Array = ctx.paints; var stalls: Array = ctx.stalls
	var poles: Array = ctx.poles; var blds: Array = ctx.blds; var stops: Array = ctx.stops
	# ---------------------------------------------------------------- alleys (ground first)
	F.alley(paints, props, dec, rr, sx, sz, true, 54.0, 100.0, 240.8, poles, [[130.0, 60.7], [160.0, 60.7], [215.0, 53.3]], NAN, [1])
	F.alley(paints, props, dec, rr, sx, sz, false, 190.0, 9.2, 100.0, poles, [[30.0, 189.3], [80.0, 196.7]], NAN, [])
	if OS.get_environment("APT_GROUND_ONLY") == "1":
		F.finish(ctx, 100.0, 9.2, 240.8, 100.0); quit(); return

	# ================================================================ S5 (u 100-190, v 9.2-54)
	# the dry cleaner's brick walk-up stands 2.5 m back behind its own paved forecourt (the shop's bench and bin there)
	var dc := F.place(bl, sx, sz, "ck/ck_brk3_row2_fe", 110.3, 18.7, "-v", "dry_cleaner", 0.8)
	paints.append(F.rect(sx, sz, 101.0, 9.2, 118.0, 11.7, "concrete"))
	F.back_of_house(props, dc, true); blds.append(dc)
	F.wall(props, dc, "prop_porch_light_coach", "worn", "front", -1.1 - 0.9, 2.25, 0.05)
	F.wall(props, dc, "prop_mailbox_wall_brass", "worn", "front", 3.0 + 1.1, 1.3, 0.05)
	F.put(props, "prop_trash_receptacle", "worn", sx, sz, 102.0, 10.6)
	F.put(props, "prop_newspaper_box_blue", "worn", sx, sz, 116.8, 10.8, 0.0)     # papers for the bus queue
	I.add(props, "plant_potted_leafy", "normal", F.at(dc, -4.6, 7.5), 0.0)
	F.grime(dec, Vector2(101.0, -11.2), Vector2(118.0, -11.2), rr)
	var gcr := F.place(bl, sx, sz, "apartments/apt_garden_cream", 131.2, 16.7, "-v", "garden_7th")
	F.dress(gcr, paints, props, dec, rr, sx, sz, 9.2, true, true)
	blds.append(gcr)
	# the boarded walk-up: no pots, no lights, no dish; a dumpster for the gutting already in its yard
	var bo := F.place(bl, sx, sz, "ck/ck_apt3_row3_boarded", 155.8, 18.2, "-v", "boarded_7th", 0.95)
	F.back_of_house(props, bo, false); blds.append(bo)
	for k in 3: dec.add(14, Vector2(149.0 + k * 6.0, -10.8), 0.0, 1.6, 3.0, F.GY, Color(1, 1, 1, 0.5))   # the front walk gone to dirt
	F.put(props, "prop_dumpster_rolloff_20yd", "dirty", sx, sz, 156.0, 37.5, 0.0)
	for k in 5: F.put(props, "fence_temp_fence_panel_screen", "dirty", sx, sz, 148.6 + k * 3.31, 44.4, 0.0)   # the builder's screen on the yard line
	F.put(props, "prop_cone_28in", "dirty", sx, sz, 162.4, 33.0, 0.0)
	F.put(props, "prop_cone_18in", "dirty", sx, sz, 149.2, 33.4, 30.0)
	var stc := F.place(bl, sx, sz, "apartments/apt_stucco3_cream", 178.5, 18.2, "-v", "stucco_7th")
	F.dress(stc, paints, props, dec, rr, sx, sz, 9.2, true, true)
	blds.append(stc)
	# stalls on the u-alley for the dry cleaner's flats and the garden apartment, the garages for the stucco block
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, true, 101.0, 145.0, 54.0, -1.0))
	for k in 3:
		var gb := F.place(bl, sx, sz, ["garages/double_stucco_comp", "garages/double_siding_comp", "garages/double_stucco_clay"][k], 152.0 + k * 6.3, 50.6, "+v", "garage_7th_%d" % k, 0.85)
		blds.append(gb)
		W.oil(dec, rr, Vector2(152.0 + k * 6.3, -55.6), 90.0, F.GY, 0.6)
	paints.append(F.rect(sx, sz, 148.8, 53.6, 171.8, 54.0, "concrete"))
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, true, 172.0, 188.0, 54.0, -1.0))
	F.fence_gate(props, sx, sz, 100.4, 47.4, 145.4, 47.4, 22.0)
	F.fence_uv(props, sx, sz, 100.4, 25.7, 100.4, 47.4)                            # lot line with a_ne
	F.fence_uv(props, sx, sz, 100.4, 25.7, 104.1, 25.7)
	F.fence_uv(props, sx, sz, 145.4, 47.4, 148.6, 47.4)
	F.fence_uv(props, sx, sz, 167.8, 47.4, 188.0, 47.4)
	F.fence_uv(props, sx, sz, 188.0, 47.4, 188.0, 24.4)
	for g: Array in [[116.5, 120.2], [142.2, 146.6], [165.0, 168.8]]:      # across the gaps between the 7th St buildings, mid-depth
		F.fence_gate(props, sx, sz, float(g[0]), 18.0, float(g[1]), 18.0, (float(g[1]) - float(g[0])) * 0.5)
	F.put(props, "tree_ficus_b", "normal", sx, sz, 122.0, 38.0, 80.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 113.0, 36.5, 0.0)
	F.put(props, "tree_magnolia_a", "normal", sx, sz, 184.0, 38.0, 200.0)
	# the dry cleaner's staff eat at the back door (steam and heat inside): a table under a sail, a kettle grill
	F.put(props, "prop_picnic_table", "worn", sx, sz, 108.5, 41.5, 0.0)
	F.put(props, "prop_shade_sail", "worn", sx, sz, 108.5, 41.5, 0.0)
	F.put(props, "prop_bbq_kettle", "worn", sx, sz, 104.0, 44.0, 0.0)
	# the garden apartment's older tenants keep a vegetable bed and sit under the arbor beside it
	paints.insert(0, F.rect(sx, sz, 124.0, 39.0, 134.0, 42.5, "mulch"))
	for k in 4: F.put(props, ["plant_agave_americana_small", "plant_bird_of_paradise", "plant_potted_leafy", "plant_bougainvillea_mound"][k], "normal", sx, sz, 125.4 + k * 2.4, 40.75, k * 37.0)
	F.put(props, "prop_garden_arbor", "worn", sx, sz, 139.0, 41.0, 0.0)
	F.put(props, "prop_adirondack_wood", "worn", sx, sz, 138.2, 39.4, 160.0)
	F.put(props, "prop_adirondack_white", "worn", sx, sz, 140.2, 39.6, 200.0)
	# the stucco block's children: a swing on a bark pad behind their building, the mother's bench facing it
	paints.insert(0, F.rect(sx, sz, 171.0, 31.0, 181.0, 38.5, "mulch"))
	F.put(props, "prop_swing_set", "worn", sx, sz, 176.0, 35.5, 0.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 176.0, 41.2, 180.0)
	dec.add(14, Vector2(176.0, -35.5), 0.0, 3.0, 2.2, F.GY, Color(1, 1, 1, 0.55))

	# ================================================================ S8: the corner (u 196-240.8, v 9.2-54)
	var shops := F.place(bl, sx, sz, "commercial/com_boutique_row", 231.8, 18.7, "-v", "corner_shops_7th", 0.75)
	var cafe := F.place(bl, sx, sz, "commercial/com_cafe_seaside", 218.8, 18.7, "-v", "coffee_window", 0.7)
	paints.append(F.rect(sx, sz, 215.8, 9.2, 240.8, 11.7, "concrete"))
	for b: Dictionary in [shops, cafe]:
		F.back_of_house(props, b, false); blds.append(b)
	# doors at u 227.7, 229.9, 239.6 (shops) and 217.0 (coffee): the bench between the second and third shop door
	# (bus riders wait there), a bin by the coffee window, the rack against the coffee shop's west end, papers
	F.put(props, "prop_park_bench", "worn", sx, sz, 234.6, 10.6, 0.0)
	F.put(props, "prop_trash_receptacle", "dirty", sx, sz, 221.4, 10.5)
	F.put(props, "prop_recycling_receptacle", "worn", sx, sz, 222.2, 10.5)
	F.put(props, "prop_bike_rack", "rusty", sx, sz, 213.4, 12.6, 90.0)          # beside the forecourt, along the cafe's side wall
	F.put(props, "prop_newspaper_box_red", "worn", sx, sz, 232.2, 10.4, 0.0)
	F.put(props, "prop_usps_collection_box", "worn", sx, sz, 225.0, 10.5, 0.0)    # the pharmacy keeps the post counter
	dec.add(14, Vector2(217.0, -10.4), 0.0, 2.4, 1.8, F.GY, Color(1, 1, 1, 0.6))  # the queue at the coffee window
	F.grime(dec, Vector2(215.8, -11.2), Vector2(240.8, -11.2), rr)
	var wa := F.place(bl, sx, sz, "ck/ck_apt3_row2", 231.8, 42.0, "+u", "walkup_adela_s")
	F.dress(wa, paints, props, dec, rr, sx, sz, 240.8, true, true)
	blds.append(wa)
	paints.append(F.rect(sx, sz, 196.0, 16.0, 202.3, 28.4, "asphalt"))
	F.enclosure(props, F.q(sx, sz, 199.5, 22.0), -90.0)                           # shops' bins, open to the alley
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 28.5, 52.5, 196.0, 1.0))
	F.fence_gate(props, sx, sz, 202.6, 26.0, 202.6, 52.4, 12.0)
	F.fence_uv(props, sx, sz, 202.6, 26.0, 215.6, 26.0)
	F.fence_uv(props, sx, sz, 202.6, 52.4, 237.6, 52.4)
	F.fence_uv(props, sx, sz, 237.6, 52.4, 237.6, 48.2)
	F.fence_gate(props, sx, sz, 238.0, 25.9, 238.0, 35.8, 5.0)                    # shop staff out to Adela
	# the shops' back yard: delivery cartons go to the enclosure, the staff sit at the back door at lunch
	F.put(props, "prop_picnic_table", "worn", sx, sz, 212.0, 33.0, 90.0)
	F.put(props, "tree_coral_a", "normal", sx, sz, 208.0, 40.0, 65.0)
	F.put(props, "palm_queen_b", "normal", sx, sz, 207.0, 16.0, 20.0)             # the corner lawn west of the coffee window
	F.put(props, "palm_queen_a", "normal", sx, sz, 205.5, 22.5, 130.0)

	# ================================================================ S4s (u 100-190, v 60-100)
	# carports on the u-alley (the 7th St flats' cars): one stall under each, no wheel stop (nose to the back post)
	for k in 8:
		var cu := 101.9 + k * 3.05
		var cp := F.place(bl, sx, sz, "garages/carport_clay" if k % 3 != 1 else "garages/carport_comp", cu, 63.15, "-v", "carport_%d" % k, 0.85)
		blds.append(cp)
		stalls.append([cu, -63.15, 180.0, F.gy(cu, -63.15)])
		if rr.randf() < 0.7: W.oil(dec, rr, Vector2(cu, -63.4), 0.0, F.GY, rr.randf_range(0.6, 0.9))
	paints.append(F.rect(sx, sz, 100.4, 60.0, 125.3, 66.2, "asphalt"))
	# the skate pad: concrete, chain-link 1 m outside it, ONE gate on the alley side (kids come from the carports)
	paints.insert(0, F.rect(sx, sz, 136.0, 70.0, 166.0, 94.0, "concrete"))
	F.fence_gate(props, sx, sz, 135.0, 69.0, 167.0, 69.0, 6.0, "fence_chainlink", "fence_chainlink_post", "fence_gate_wrought_iron")
	F.fence_uv(props, sx, sz, 167.0, 69.0, 167.0, 95.0, "fence_chainlink", "fence_chainlink_post")
	F.fence_uv(props, sx, sz, 167.0, 95.0, 135.0, 95.0, "fence_chainlink", "fence_chainlink_post")
	F.fence_uv(props, sx, sz, 135.0, 95.0, 135.0, 69.0, "fence_chainlink", "fence_chainlink_post")
	F.put(props, "prop_skate_quarter_pipe", "worn", sx, sz, 139.4, 83.0, 90.0)    # ramp faces into the pad
	F.put(props, "prop_skate_quarter_pipe", "dirty", sx, sz, 162.6, 83.0, -90.0)
	F.put(props, "prop_skate_funbox", "worn", sx, sz, 151.0, 83.0, 90.0)
	F.put(props, "prop_skate_grind_rail", "worn", sx, sz, 151.0, 75.2, 0.0)
	F.put(props, "prop_skate_bowl_section", "worn", sx, sz, 161.0, 90.0, 0.0)
	F.put(props, "prop_park_bench", "worn", sx, sz, 141.5, 92.8, 0.0)            # on the pad's edge, where the boards drop
	F.put(props, "prop_trash_receptacle", "dirty", sx, sz, 138.0, 71.4)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 164.8, 71.2)
	for k in 6: dec.add(8, Vector2(rr.randf_range(140, 162), -rr.randf_range(72, 92)), rr.randf_range(0, 180), 0.5, 3.5, F.GY, Color(1, 1, 1, 0.35))   # wheel scuffs on the concrete
	dec.add(14, Vector2(141.0, -67.0), 90.0, 1.2, 6.0, F.GY, Color(1, 1, 1, 0.5))  # the path worn from the carports to the gate
	# the old residents' shade: two benches facing the pad from under the trees, a fountain
	for e: Array in [[172.0, 76.0], [172.0, 88.0]]:
		F.put(props, "prop_park_bench", "worn", sx, sz, float(e[0]), float(e[1]), -90.0)
	F.put(props, "tree_ficus_a", "normal", sx, sz, 176.5, 76.0, 10.0)
	F.put(props, "tree_jacaranda_b", "normal", sx, sz, 176.5, 88.0, 100.0)
	F.put(props, "prop_drinking_fountain", "worn", sx, sz, 171.8, 82.0, -90.0)
	F.put(props, "tree_coral_b", "normal", sx, sz, 130.0, 80.0, 50.0)            # between the carports and the pad
	F.put(props, "prop_picnic_table", "worn", sx, sz, 129.5, 89.0, 0.0)
	F.put(props, "prop_shade_sail", "worn", sx, sz, 129.5, 89.0, 0.0)            # over the table: the lawn has no other shade at noon
	F.put(props, "prop_bbq_gas_cart", "worn", sx, sz, 124.6, 92.4, 90.0)
	F.put(props, "prop_adirondack_wood", "worn", sx, sz, 118.0, 83.0, 120.0)
	F.put(props, "prop_adirondack_wood", "worn", sx, sz, 118.4, 85.4, 70.0)
	F.put(props, "prop_lamp_globe", "worn", sx, sz, 121.0, 75.0)
	F.put(props, "tree_jacaranda_a", "normal", sx, sz, 111.0, 74.0, 300.0)       # shade over the carport walk
	F.put(props, "tree_ficus_b", "normal", sx, sz, 106.0, 92.0, 45.0)
	F.put(props, "prop_sprinkler_impact", "worn", sx, sz, 112.0, 84.0, 0.0, false)
	dec.add(14, Vector2(116.0, -70.0), 70.0, 1.0, 12.0, F.GY, Color(1, 1, 1, 0.45))  # the short cut from the carports to the playground fence
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 61.0, 99.0, 190.0, -1.0))
	F.fence_gate(props, sx, sz, 183.4, 60.6, 183.4, 100.3, 20.0)                  # behind the stalls, up to n_apt_b1_be's lot-line fence
	F.fence_uv(props, sx, sz, 183.4, 60.6, 167.0, 60.6)                            # along the alley to the skate fence
	F.fence_uv(props, sx, sz, 167.0, 60.6, 167.0, 69.0)

	# ================================================================ S7s (u 196-240.8, v 60-100)
	var sp := F.place(bl, sx, sz, "apartments/apt_stucco3_peach", 231.8, 71.5, "+u", "stucco_adela")
	F.dress(sp, paints, props, dec, rr, sx, sz, 240.8, true, true, [-1.0])
	blds.append(sp)
	var la := F.place(bl, sx, sz, "ck/ck_brk3_row2", 231.3, 90.5, "+u", "launderette", 0.8)
	paints.append(F.rect(sx, sz, 238.3, 84.5, 240.8, 96.5, "concrete"))
	F.back_of_house(props, la, true); blds.append(la)
	F.wall(props, la, "prop_porch_light_coach_bronze", "worn", "front", -1.1 - 0.9, 2.25, 0.05)
	F.put(props, "prop_park_bench", "worn", sx, sz, 239.5, 86.4, 90.0)            # waiting for the wash, back to the window, clear of both doors
	F.put(props, "prop_trash_receptacle", "dirty", sx, sz, 239.6, 95.8)
	F.put(props, "prop_bike_rack", "rusty", sx, sz, 236.8, 98.4, 0.0)             # in the side yard, parallel to the lot line
	F.grime(dec, Vector2(238.8, -84.5), Vector2(238.8, -96.5), rr)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 61.0, 77.0, 196.0, 1.0))
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 83.0, 99.0, 196.0, 1.0))
	F.fence_gate(props, sx, sz, 202.6, 60.4, 202.6, 99.6, 20.0)
	F.fence_uv(props, sx, sz, 202.6, 60.4, 225.6, 60.4)
	F.fence_uv(props, sx, sz, 225.6, 60.4, 225.6, 61.8)
	F.fence_uv(props, sx, sz, 225.6, 81.2, 224.1, 81.2)                             # from the stucco block's side wall
	F.fence_gate(props, sx, sz, 224.1, 81.2, 224.1, 84.3, 1.55)                     # to the launderette's back corner
	F.fence_uv(props, sx, sz, 224.1, 96.7, 224.1, 100.2)
	F.put(props, "tree_ficus_b", "normal", sx, sz, 208.0, 90.0, 210.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 214.0, 69.5, 90.0)

	# ================================================================ POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
	# quarters ... plenty of props"): only ADDS, with its own random sequence, after everything above (which stays identical):
	# every building's downspouts, house numbers, vine or dish, back-wall grime; and the spots chosen here, each a cluster
	# whose items go in only where their own spot is free (apt_fill_lib.polish_*)
	var prr := W.rng_for(NAME + "_polish")
	var prect := Rect2(100.0, -100.0, 140.8, 90.8)
	for pb: Dictionary in blds: F.polish_building(ctx, pb, prr, prect)
	for psp: Array in [["sit", 133, 32, 0], ["garden", 160, 30, 0], ["tools", 186, 30, 90], ["sit", 105, 80, 0], ["garden", 125, 96, 0], ["garden", 208, 30, 0], ["bins", 204, 48, 90], ["sit", 213, 80, 0], ["garden", 208, 96, 0], ["lounge", 220, 66, 90], ["shade", 180, 70, 0]]:
		F.polish_spot(ctx, String(psp[0]), float(psp[1]), float(psp[2]), float(psp[3]), prr, prect)

	F.finish(ctx, 100.0, 9.2, 240.8, 100.0)
	quit()
