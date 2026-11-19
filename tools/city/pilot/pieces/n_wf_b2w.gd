extends SceneTree
## Piece n_wf_b2w (waterfront fill, block 2 WEST: grid u 259.2-335, between the residential street (v 9.2), B Ave
## (u 259.2) and Pier St (v 190.8)). Yasin 19 Nov: waterfront area, "hotel is good" (the LOW inn, his answer), "there
## arent any landmarks there", "CONSIDER THE ELEVATION".
## WHO COMES HERE AND WHY: the top shelf of the hill, 8-10 m up with the bay in view over the roofs: the Bayview Inn (a
## low two-storey courtyard inn) with its guests' parking (in from the residential street's driveway opening at u 304-310)
## and its garden lawn on the next level down, chairs turned to the bay; below it Vista Park, the neighbourhood's
## lookout lawn at the top of the bank (benches facing the water, picnic tables, palms), level with B Ave at its gate,
## where THE STEPS start - the public walk down the hill to the boats. On Pier St (the street down to the pier) the
## top of the shopping street: the Salty Dog pub on the corner, a holiday-rentals office, a juice bar, the Blue Pelican
## bistro, the park's stairs up from the street, and the Cove deli with a wine & cheese shop. East of u 318 the first column of holiday flats (with n_wf_b2m).
## THE GROUND: north street walk 10.15 -> 9.36, B Ave 10.15 -> 6.15, Pier St 6.15 -> 5.0; land 10 -> 7 on the shelf.
##   inn + parking 9.60 | inn garden 8.60 | Vista Park 7.00 (B Ave gate level, 6.8) | Pier St pads 6.15 / 6.12 / 6.04 / 5.80 / 5.20 (deli and wine shop),
##   park stairs 7.00 -> 5.50 (10 risers) | flats column C: 8.40 / 6.80 / 5.80 (shared with n_wf_b2m to u 352)
##   the Steps: B Ave 7.9 -> park 7.0 (ramp 7.6 %), park -> C2 (2 risers). A retaining face on every step.
## Run: GROUND_ONLY=1 for the ground alone (first check), then without. A draft until Yasin has seen it; never when locked.
const F := preload("res://tools/city/pilot/pieces/wf_fill_lib.gd")

func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := F.new("n_wf_b2w")
	ground(b)
	if OS.get_environment("GROUND_ONLY") == "1":
		b.finish(true); quit(); return
	life(b)
	polish(b)
	b.finish()
	quit()

## terraces of the flats column C (u 318-352), written identically in n_wf_b2m (the seam at u 335 crosses them)
static func column_c(b: F) -> void:
	b.terrace(318.0, 11.2, 352.0, 60.0, 8.40, "wall", 0, "flats C1")
	b.terrace(318.0, 60.0, 352.0, 115.0, 6.80, "wall", 0, "flats C2")
	b.terrace(318.0, 115.0, 352.0, 168.0, 5.80, "wall", 0, "flats C3")

func ground(b: F) -> void:
	b.band = 2.0
	b.terrace(261.2, 11.2, 318.0, 55.0, 9.60, "wall", 0, "inn + parking")
	b.terrace(261.2, 55.0, 318.0, 100.0, 8.60, "wall", 0, "inn garden")
	b.terrace(261.2, 100.0, 318.0, 168.0, 7.00, "wall", 0, "Vista Park")
	column_c(b)
	# Pier St front (fronts at v 186 facing Pier St: yaw 0); pads to v 168 (the park's wall behind)
	b.terrace(261.2, 168.0, 273.5, 188.8, 6.15, "wall", 0, "pub")
	b.terrace(273.5, 168.0, 282.5, 188.8, 6.12, "wall", 0, "rentals office")
	b.terrace(282.5, 168.0, 291.5, 188.8, 6.04, "wall", 0, "juice bar")
	b.terrace(291.5, 168.0, 305.5, 188.8, 5.80, "wall", 0, "bistro")
	b.terrace(305.5, 176.0, 318.0, 188.8, 5.50, "wall", 0, "park stairs' plaza")
	b.terrace(318.0, 168.0, 333.5, 188.8, 5.20, "wall", 0, "deli + wine shop corner")
	# slopes
	b.stairs(306.0, 168.0, 317.5, 176.0, "v", 7.00, 5.50)               # Vista Park's stairs down to Pier St
	b.ramp(261.2, 104.0, 273.0, 108.0, "u", 7.90, 7.00)                 # the Steps: in from B Ave
	b.stairs(316.0, 104.0, 320.0, 108.0, "u", 7.00, 6.80)               # park -> flats terrace C2
	b.ramp(304.0, 11.2, 310.0, 22.0, "v", 9.70, 9.60, true)             # the inn's drive off the north street's apron
	# surfaces
	b.paint(259.2, 9.2, 335.0, 11.2, "concrete"); b.paint(259.2, 186.0, 335.0, 190.8, "concrete")
	b.paint(259.2, 11.2, 261.2, 186.0, "concrete")
	b.paint(306.0, 168.0, 317.5, 176.0, "concrete"); b.paint(305.5, 176.0, 318.0, 188.8, "plaza")
	b.paint(261.2, 104.0, 352.0, 108.0, "plaza")                        # the Steps' walk across the park and C2
	b.paint(261.2, 55.0, 318.0, 100.0, "grass")                         # the inn's garden
	b.paint(261.2, 100.0, 318.0, 168.0, "grass")                        # Vista Park
	b.paint(318.0, 11.2, 352.0, 168.0, "grass")                         # the flats' gardens
	b.paint(261.2, 168.0, 333.5, 172.0, "concrete")                     # the shops' back strip
	b.paint(333.5, 168.0, 335.0, 188.8, "mulch")                        # planted gap at the seam

## ---------------------------------------------------------------- buildings, then props, each with its reason
func life(b: F) -> void:
	# ================= THE BAYVIEW INN (low two-storey courtyard inn, A1 9.60, its rooms facing south to the garden) =====
	var inn := b.bld("extras/motel_inn_court", 285.0, 46.0, 0.0, "bayview_inn", 0.55)   # office door at u 298.3 (east end)
	b.roof(inn, ["prop_ac_condenser", "prop_ac_condenser", "prop_vent_box"])
	b.add("plant_potted_leafy", "normal", 265.9, 51.9, 0.0)               # at the walkway's west end (the doors and sliders fill the rest)
	b.add("prop_bench_bus_stop", "worn", 301.4, 52.4, 0.0)               # by the office: guests waiting for a taxi to the beach
	b.add("prop_trash_receptacle", "worn", 302.9, 52.4, 0.0)
	# the guests' parking court (in from the residential street's driveway at u 304-310), noses to the garden wall
	b.stalls_u(263.5, 15, 18.0, -1.0)
	b.stalls_u(263.5, 20, 25.0, 1.0)
	b.add("prop_lot_light_pole", "worn", 284.0, 31.2, 0.0); b.add("prop_lot_light_pole", "worn", 306.0, 31.2, 0.0)
	b.paint(261.2, 30.5, 318.0, 41.0, "grass")                            # the strip behind the inn: its services, two trees
	b.add("tree_magnolia_a", "normal", 263.8, 36.0, 10.0); b.add("palm_queen_a", "normal", 314.0, 36.5, 40.0)
	b.enclosure(311.0, 33.6, 180.0)                                      # the inn's bins, at the court's east end, open to the aisle
	b.stall_wear(0.5); b.yard_wear(261.2, 11.2, 318.0, 30.5, 0.6)
	b.tyre_path(307.0, 11.4, 307.0, 21.5)
	# the stucco garden wall along the residential street (the inn's privacy), a gap at the drive; along B Ave too
	b.guard(304.0, 11.6, 261.4, 11.6, Vector2(0, -1)); b.guard(317.9, 11.6, 310.0, 11.6, Vector2(0, -1))
	b.guard(261.6, 99.6, 261.6, 11.4, Vector2(-1, 0))
	for k in 3: b.add("plant_bougainvillea_wall", "normal", 270.0 + k * 12.0, 12.0, 0.0)
	# ================= THE INN'S GARDEN (A2 8.60): lawn at the top of the bank, chairs turned to the bay ===============
	b.stairs(284.0, 55.0, 288.0, 61.0, "v", 9.60, 8.60)                  # from the rooms' walkway down to the lawn
	b.paint(284.0, 55.0, 288.0, 61.0, "concrete")
	b.guard(261.6, 54.8, 283.8, 54.8, Vector2(0, -1)); b.guard(288.2, 54.8, 317.8, 54.8, Vector2(0, -1))
	b.guard(317.8, 11.6, 317.8, 99.8, Vector2(-1, 0))                     # its east edge over the flats (1.2-1.8 m)
	b.guard(261.6, 99.8, 317.8, 99.8, Vector2(0, -1))                     # and over Vista Park (1.6 m)
	for a: Array in [[309.0, 66.0], [311.0, 66.0], [309.0, 80.0], [311.0, 80.0], [313.0, 92.0], [315.0, 92.0]]:
		b.add("prop_adirondack_white", "worn", float(a[0]), float(a[1]), 90.0)        # facing east: the bay
	b.add("prop_patio_set_4", "worn", 296.0, 70.0, 0.0); b.add("prop_patio_set_4", "worn", 296.0, 86.0, 0.0)
	b.add("prop_shade_sail", "worn", 296.0, 78.0, 0.0, false)             # one sail over the two breakfast tables
	b.add("prop_garden_arbor", "worn", 286.0, 63.4, 0.0)                  # at the foot of the stairs, the garden's way in
	b.add("prop_bbq_gas_cart", "worn", 266.0, 90.0, 90.0); b.add("prop_picnic_table", "worn", 270.0, 86.0, 0.0)
	for t: Array in [["palm_canary_date_a", 300.0, 62.0], ["tree_jacaranda_b", 270.0, 70.0], ["palm_queen_b", 304.0, 96.0], ["tree_coral_b", 278.0, 94.0]]:
		b.add(String(t[0]), "normal", float(t[1]), float(t[2]), float(t[1]) * 5.0)
	for k in 4: b.add("plant_bird_of_paradise", "normal", 263.4, 60.0 + k * 9.0, k * 40.0)
	b.add("prop_beach_shower", "worn", 263.8, 57.6, 0.0)                 # the sand off before the rooms
	# ================= VISTA PARK (B 7.00): the neighbourhood's lookout lawn, where the Steps begin =====================
	b.guard(317.8, 100.2, 317.8, 103.8, Vector2(-1, 0)); b.guard(317.8, 108.2, 317.8, 167.8, Vector2(-1, 0))
	b.guard(261.6, 167.6, 305.8, 167.6, Vector2(0, -1))                        # the park's back wall over the shops (a 1 m parapet from the park)
	b.fence("iron", 261.6, 100.2, 261.6, 103.8); b.fence("iron", 261.6, 108.2, 261.6, 139.0); b.fence("iron", 261.6, 145.0, 261.6, 167.6)   # along B Ave: gaps for the Steps and the gate
	b.guard(305.8, 167.6, 305.8, 175.4, Vector2(1, 0)); b.fence("iron", 305.8, 175.8, 304.2, 175.8, "worn", 5.80)   # the park stairs' sides,
	b.guard(317.7, 167.8, 317.7, 175.4, Vector2(-1, 0)); b.fence("iron", 317.7, 175.8, 319.3, 175.8, "worn", 5.20)  # closed on the shops' walls
	for bv: float in [116.0, 128.0, 140.0, 152.0]:
		b.add("prop_park_bench", "worn", 315.6, bv, 90.0)                 # at the edge, facing the bay
		b.add("prop_trash_receptacle", "worn", 315.6, bv + 1.6, 0.0)
	for pt: Vector2 in [Vector2(290.0, 124.0), Vector2(290.0, 148.0)]:
		b.add("prop_picnic_table", "worn", pt.x, pt.y, 90.0); b.add("prop_shade_sail", "worn", pt.x, pt.y, 90.0, false)
	b.add("prop_drinking_fountain", "worn", 276.0, 109.2, 180.0)         # beside the Steps' walk
	b.add("prop_lamp_globe", "worn", 268.0, 109.0, 0.0); b.add("prop_lamp_globe", "worn", 300.0, 109.0, 0.0); b.add("prop_lamp_globe", "worn", 300.0, 160.0, 0.0)
	b.paint(261.2, 139.0, 280.0, 145.0, "plaza")                          # the gate from B Ave (level with the walk) and its path
	b.add("prop_lamp_globe", "worn", 262.4, 147.2, 0.0)
	for t2: Array in [["tree_jacaranda_a", 274.0, 122.0], ["palm_queen_a", 300.0, 120.0], ["tree_coral_a", 278.0, 158.0], ["palm_mexican_fan_b", 305.0, 136.0], ["tree_magnolia_b", 270.0, 130.5], ["palm_canary_date_b", 288.0, 136.0]]:
		b.add(String(t2[0]), "normal", float(t2[1]), float(t2[2]), float(t2[1]) * 3.0)
	for k in 5: b.add("plant_bougainvillea_wall", "normal", 268.0 + k * 10.0, 100.4, 0.0)   # on the inn garden's wall face, park side
	b.add("prop_beach_sign_dog", "worn", 263.0, 135.2, 90.0)              # "dogs on leash" at the gate
	# ================= PIER ST: pub, holiday rentals, juice bar, bistro, the park stairs, deli & wine (yaw 0) ==========
	var pub := b.bld("commercial/com_bar_crown", 267.5, 179.0, 0.0, "salty_dog_pub", 0.8)          # door u 264.2
	b.add("prop_park_bench", "worn", 270.4, 187.6, 0.0); b.add("prop_trash_receptacle", "dirty", 272.6, 187.4, 0.0)
	var ren := b.bld("commercial/com_realty", 278.0, 179.0, 0.0, "shores_holiday_rentals", 0.65)   # door u 279.8
	b.add("plant_potted_leafy", "normal", 276.0, 186.6, 0.0)
	var jui := b.bld("commercial/com_cafe_seaside", 287.0, 179.0, 0.0, "sea_breeze_juice", 0.65)   # door u 285.2
	b.add("prop_patio_set_4", "worn", 288.6, 187.5, 0.0)                  # one table out front, east of the door
	var bis := b.bld("commercial/com_bistro", 298.5, 179.0, 0.0, "blue_pelican_bistro", 0.7)      # door u 303.3
	b.add("prop_patio_set_4", "worn", 294.6, 187.5, 0.0); b.add("prop_patio_set_4", "worn", 298.6, 187.5, 0.0)
	b.add("plant_potted_succulent", "normal", 301.2, 186.6, 0.0)
	for bb: Array in [[pub, ["prop_vent_box"]], [jui, ["prop_ac_condenser_compact"]], [bis, ["prop_vent_box", "prop_ac_condenser_compact"]]]:
		b.roof(bb[0], bb[1])
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "dirty", 289.2 + k * 0.8, 168.9, 0.0)
	# the park's stairs and their little plaza on Pier St
	b.add("prop_lamp_victorian", "worn", 306.2, 186.0, 0.0); b.add("prop_lamp_victorian", "worn", 317.2, 186.0, 0.0)
	b.add("plant_potted_leafy", "normal", 307.0, 177.0, 0.0); b.add("plant_potted_leafy", "normal", 316.6, 177.0, 0.0)
	b.add("prop_bike_rack", "worn", 311.8, 187.8, 0.0)                    # parallel to the walk
	var del := b.bld("commercial/com_orange_corner", 325.5, 179.0, 0.0, "cove_deli_and_wine", 0.7)  # doors u 324.4 / 326.6
	b.add("prop_newspaper_box_blue", "worn", 320.4, 187.4, 0.0); b.add("prop_trash_receptacle", "worn", 330.8, 187.4, 0.0)
	b.roof(del, ["prop_ac_condenser"])
	# ================= FLATS, COLUMN C (u 318-335 of it; decks and gardens east in n_wf_b2m) ==========================
	b.bld("apartments/apt_beach_condo", 326.0, 35.0, 90.0, "crest_flats", 0.55)
	b.bld("apartments/apt_stucco3_peach", 326.0, 82.0, 90.0, "seaview_terrace_flats", 0.55)
	b.bld("apartments/apt_garden_cream", 325.0, 140.0, 90.0, "lower_terrace_flats", 0.55)
	b.guard(318.0, 59.8, 335.0, 59.8, Vector2(0, -1)); b.guard(318.0, 114.8, 335.0, 114.8, Vector2(0, -1))
	b.guard(318.0, 167.6, 335.0, 167.6, Vector2(0, -1))                        # the back wall over the deli (C3 is 0.6 m higher)
	b.stairs(322.0, 11.2, 324.0, 15.0, "v", 9.20, 8.40)                  # a gate from the street down to the C1 flats
	b.guard(321.8, 11.6, 318.2, 11.6, Vector2(0, -1)); b.guard(335.0, 11.6, 324.2, 11.6, Vector2(0, -1))
	b.add("prop_mailbox_post_metal", "worn", 325.0, 16.0, 0.0)
	b.building_wear()

## ---------------------------------------------------------------- POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
## quarters, both indoors and outdoors ... plenty of props and life"). Every spot below is chosen by hand with its reason;
## try_add() only refuses a spot that turns out taken (counted and printed), it decides nothing.
func polish(b: F) -> void:
	var T := func(base: String, cond: String, pts: Array, yaw := 0.0, surf: Array = []) -> void:
		for p: Vector2 in pts: b.try_add(base, cond, p.x, p.y, yaw, surf)
	# the inn's parking court: drains, turning arcs at the aisle ends, a bike rack for guests who ride
	for d: Vector2 in [Vector2(282.0, 21.5), Vector2(300.0, 21.5)]: b.add("prop_storm_drain_grate", "dirty", d.x, d.y, 0.0, false, 0.002)
	for c: Vector2 in [Vector2(265.0, 21.5), Vector2(315.0, 21.5)]: b.mark(15, c, 30.0, 3.0, 2.0, Color(1, 1, 1, 0.45))
	T.call("prop_bike_rack", "worn", [Vector2(270.0, 32.0), Vector2(296.0, 32.0)], 0.0)
	T.call("prop_kayak_rack", "worn", [Vector2(279.0, 33.6)])                             # the inn lends kayaks
	# the rooms' walkway and the garden: flowers, chairs by the doors, umbrellas, a cooler, a hammock-less shade tree
	T.call("plant_potted_succulent", "normal", [Vector2(282.0, 53.6), Vector2(290.5, 53.6), Vector2(299.6, 53.4)])
	T.call("prop_adirondack_white", "worn", [Vector2(274.0, 64.0), Vector2(276.0, 64.0), Vector2(304.0, 74.0), Vector2(306.0, 74.0)], 90.0)
	T.call("prop_beach_umbrella", "worn", [Vector2(275.0, 66.8), Vector2(305.0, 76.8)])
	T.call("prop_ice_chest", "worn", [Vector2(267.4, 93.6)])
	T.call("plant_bougainvillea_mound", "normal", [Vector2(263.4, 75.0), Vector2(316.0, 58.0), Vector2(316.0, 88.0)])
	T.call("plant_iceplant_patch", "normal", [Vector2(285.0, 96.6), Vector2(296.0, 58.0)])
	# Vista Park: more benches along the bank's edge, a second fountain, low planting in drifts, bins at the paths
	T.call("prop_park_bench", "worn", [Vector2(315.6, 122.0), Vector2(315.6, 134.0), Vector2(315.6, 146.0), Vector2(315.6, 158.0)], 90.0)
	T.call("prop_park_bench", "worn", [Vector2(282.0, 103.0), Vector2(296.0, 103.0)], 180.0)       # beside the Steps' walk, facing the lawn
	T.call("prop_drinking_fountain", "worn", [Vector2(276.0, 146.8)], 180.0)
	T.call("prop_trash_receptacle", "worn", [Vector2(263.0, 146.8), Vector2(306.2, 165.6), Vector2(290.0, 109.4)])
	T.call("plant_iceplant_patch", "normal", [Vector2(266.0, 156.0), Vector2(300.0, 128.0), Vector2(283.0, 162.0)])
	T.call("plant_agave_americana", "normal", [Vector2(264.0, 117.0), Vector2(310.0, 112.0), Vector2(296.0, 160.0)])
	T.call("plant_bird_of_paradise", "normal", [Vector2(266.0, 110.0), Vector2(308.0, 152.0)])
	T.call("prop_beach_sign_rules", "worn", [Vector2(274.0, 110.4)], 180.0)                 # park rules where the Steps come in from B Ave
	# Pier St: plants, papers, a bin at each door group, the pub's bench pair, mail at the park stairs
	T.call("plant_potted_leafy", "normal", [Vector2(262.4, 186.8), Vector2(283.2, 186.8), Vector2(291.0, 186.8), Vector2(332.6, 186.8)])
	T.call("prop_newspaper_box_red", "worn", [Vector2(273.2, 187.6)])
	T.call("prop_usps_collection_box", "worn", [Vector2(316.8, 187.8)])
	T.call("prop_trash_receptacle", "worn", [Vector2(305.2, 187.6), Vector2(281.8, 187.6)])
	T.call("prop_recycling_receptacle", "worn", [Vector2(320.0, 187.0)])
	# behind the shops: kegs' gas, bins for each kitchen, hose carts
	T.call("prop_propane_cylinder_100lb", "rusty", [Vector2(264.4, 170.8), Vector2(265.0, 171.0), Vector2(302.0, 170.8)])
	for k in 3: b.try_add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "dirty", 266.0 + k * 0.8, 168.9, 0.0)
	for k in 3: b.try_add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "dirty", 321.0 + k * 0.8, 168.9, 0.0)
	T.call("prop_hose_reel_cart", "worn", [Vector2(296.0, 169.2)])
	# the C flats on this side: chairs on the decks, barbecues, flowers
	T.call("prop_adirondack_wood", "worn", [Vector2(333.6, 28.0), Vector2(333.6, 72.0), Vector2(333.6, 134.0)], 90.0)
	T.call("prop_bbq_kettle", "worn", [Vector2(321.0, 50.0), Vector2(321.0, 98.0), Vector2(321.0, 156.0)])
	T.call("plant_bird_of_paradise", "normal", [Vector2(320.0, 20.0), Vector2(320.0, 66.0), Vector2(320.0, 120.0)])
	b.sand_drift(261.2, 186.0, 335.0, 188.8, 5)
	b.polish_report()
