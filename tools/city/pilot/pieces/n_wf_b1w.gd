extends SceneTree
## Piece n_wf_b1w (waterfront fill, block 1 WEST: grid u 259.2-331, between Pier St (v 209.2) and the ring (v ~327-330)).
## Yasin 19 Nov: "two blocks next to water front will be waterfront area, not residental"; the proposal he answered
## ("hotel is good, there arent any landmarks there"): Pier St front stepping down to the pier, visitor parking tucked
## behind, holiday flats and cottages on the ring, a walk through to the beach.
##
## WHO COMES HERE AND WHY (city planner): Pier St is the way from town down to the pier and the beach; this west end is
## its quiet top, 6 m above the water, where people stay and set off: the Casa del Mar inn on the B Ave corner (guests
## arrive by car from B Ave, walk down to the beach), a bakery-coffee bar for the morning crowd, the bike hire that sends
## them down Pier St. Behind them the visitor lot (entered from the two driveway openings the streets already have: Pier
## St at u 304-310, B Ave at v 254-260). Behind the lot two blocks of holiday flats face the Beach Walk, a public lane
## that runs the length of the block down to Beach Lane and the sand; south of the lane holiday cottages face the ring.
##
## THE GROUND (land first): Pier St's walk falls 6.15 -> 5.11 m along this piece, B Ave's 6.15 -> 4.15, the ring's
## 4.15 -> 3.47; the land inside lies within 0.3 m of the harmonic fill of those edges (wf_fill_ground.py). Level pads,
## each at the street-front height of what stands on it; a retaining wall wherever two pads meet:
##   inn 6.15 | bakery 6.02 | bike hire 5.86 | drive ramp 5.73 -> 4.90 (3.3 %) | grill with its dining deck 5.47
##   lot 4.90 (B Ave ramp 5.47 -> 4.90, 4.3 %) | flats 4.60 | Beach Walk 4.41 -> 4.00 | cottages 4.15 / 4.15 / 4.08 / 3.95 / 3.78
##   a 2 m strip at the seam with n_wf_b1m (u 329-331) follows the base field, so both pieces share one height line.
## Run: GROUND_ONLY=1 for the ground alone (first check), then without. A draft until Yasin has seen it; never when locked.
const F := preload("res://tools/city/pilot/pieces/wf_fill_lib.gd")

## the ring's walk edge (a straight line on this stretch, measured) and the front of the 2 m band along it
static func ring_v(u: float) -> float: return 330.27 - (u - 259.2) * 0.045497
static func ring_band(u: float) -> float: return ring_v(u) - 2.05

func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := F.new("n_wf_b1w")
	ground(b)
	if OS.get_environment("GROUND_ONLY") == "1":
		b.finish(true); quit(); return
	life(b)
	polish(b)
	b.finish()
	quit()

func ground(b: F) -> void:
	b.band = 2.0
	# ---- Pier St front: one pad per building at its front's walk height (pads run back to v 230, the lot's edge)
	b.terrace(261.2, 211.2, 283.5, 230.0, 6.15, "wall", 0, "inn")
	b.terrace(283.5, 211.2, 295.5, 230.0, 6.02, "wall", 0, "bakery")
	b.terrace(295.5, 211.2, 303.5, 230.0, 5.86, "wall", 0, "bike hire")
	b.terrace(310.5, 211.2, 329.0, 230.0, 5.47, "wall", 0, "grill + dining deck")
	# ---- the visitor lot and the flats behind it
	b.terrace(261.2, 230.0, 331.0, 266.0, 4.90, "wall", 0, "lot (upper level)")
	b.terrace(261.2, 266.0, 329.0, 294.0, 4.60, "wall", 0, "holiday flats")
	# ---- cottages on the ring: each pad at its front walk's height, from the Beach Walk to the ring's band
	b.terrace(261.2, 298.0, 273.0, ring_band(273.0), 4.15, "wall", 0, "cottage 1")
	b.terrace(273.0, 298.0, 285.0, ring_band(285.0), 4.15, "wall", 0, "cottage 2")
	b.terrace(285.0, 298.0, 299.0, ring_band(299.0), 4.08, "wall", 0, "cottage 3")
	b.terrace(299.0, 298.0, 311.0, ring_band(311.0), 3.95, "wall", 0, "cottage 4")
	b.terrace(311.0, 298.0, 323.0, ring_band(323.0), 3.78, "wall", 0, "cottage 5")
	# ---- ramps (drawn after the pads: a slope wins over a pad where both lie)
	b.ramp(303.5, 211.2, 310.5, 236.0, "v", 5.73, 4.90, true)          # Pier St driveway down into the lot
	b.ramp(261.2, 253.5, 275.0, 260.5, "u", 5.47, 4.90, true)          # B Ave driveway (its apron at v 254-260)
	b.ramp(261.2, 294.0, 331.0, 298.0, "u", 4.41, 4.00)                # the Beach Walk, falling east to the beach
	# ---- surfaces of the ground (paint), first match wins
	b.paint(259.2, 209.2, 331.0, 211.2, "concrete")                    # the 2 m beside Pier St's walk, paved like it
	b.paint(259.2, 211.2, 261.2, 298.0, "concrete")                    # and beside B Ave's
	b.paint(329.0, 230.0, 331.0, 294.0, "grass")                       # seam strip beside the flats
	b.paint(261.2, 211.2, 283.5, 214.0, "plaza")                       # inn forecourt
	b.paint(283.5, 211.2, 303.5, 214.0, "concrete")                    # shop forecourts
	b.paint(310.5, 211.2, 329.0, 214.0, "concrete")
	b.paint(324.5, 214.0, 329.0, 228.0, "plaza")                      # the grill's dining deck
	b.paint(329.0, 211.2, 331.0, 230.0, "mulch")                       # planted gap at the seam
	b.paint(261.2, 214.0, 283.5, 230.0, "grass")                       # inn garden (the building stands on it)
	b.paint(261.2, 260.5, 331.0, 266.0, "grass")                       # planted strip between the lot and the flats
	b.paint(261.2, 266.0, 329.0, 294.0, "grass")                       # flats' gardens
	b.paint(261.2, 294.0, 331.0, 298.0, "plaza")                       # Beach Walk
	b.paint(261.2, 298.0, 329.0, 340.0, "grass")                       # cottage gardens
	b.paint(323.0, 298.0, 331.0, 340.0, "concrete")                    # the footpath down to the ring


## ---------------------------------------------------------------- buildings, then props, each with its reason
func life(b: F) -> void:
	var rb := func(u: float) -> float: return ring_band(u)
	# ================= PIER ST FRONT (fronts at v 214, facing north onto Pier St: yaw 180) =================
	# --- Casa del Mar inn: a two-storey Spanish guest house on the B Ave corner; guests walk out of the front gate onto
	#     Pier St and down to the beach; the back garden looks over the lot
	var inn := b.bld("apartments/apt_spanish_revival", 272.0, 219.0, 180.0, "casa_del_mar_inn", 0.6)
	b.add("plant_potted_leafy", "normal", 269.4, 213.1, 0.0)            # either side of the inn door (door at u 272)
	b.add("plant_potted_leafy", "normal", 274.6, 213.1, 0.0)
	b.add("prop_bench_bus_stop", "worn", 264.6, 212.6, 180.0)            # guests wait for their ride on the forecourt, facing the street
	b.add("prop_trash_receptacle", "worn", 262.3, 212.4, 0.0)
	b.at_bld(inn, "prop_porch_light_coach", "worn", -6.4 - 0.9, 5.02, 0.0, 2.1, false)   # by each flat door
	b.at_bld(inn, "prop_porch_light_coach", "worn", 6.4 + 0.9, 5.02, 0.0, 2.1, false)
	b.add("palm_queen_a", "normal", 262.4, 220.0, 30.0)                  # the corner garden, on grass, 1.4 m off the walls
	b.add("plant_bird_of_paradise", "normal", 282.4, 217.0, 0.0)
	# back garden: the guests' breakfast patio over the lot (a railing on the wall, 1.25 m drop)
	# railings on the pads' back edges over the lot (1.25 / 1.12 / 0.96 m drops), one run per pad meeting the next, closed
	# at both ends against the buildings
	b.fence("iron", 263.0, 224.3, 261.6, 229.7, "worn", 6.15)            # the return to the inn's back corner
	b.fence("iron", 261.6, 229.7, 283.5, 229.7, "worn", 6.15)
	b.fence("iron", 283.5, 229.7, 295.5, 229.7, "worn", 6.02)
	b.fence("iron", 295.5, 229.7, 303.0, 229.7, "worn", 5.86)
	b.fence("iron", 303.0, 229.7, 303.0, 222.0, "worn", 5.86)            # along the drive (it falls away beside the bike yard)
	for t: Vector2 in [Vector2(266.0, 227.0), Vector2(278.0, 227.0)]:
		b.add("prop_patio_set_4", "worn", t.x, t.y, 0.0)
	b.add("prop_beach_umbrella_closed", "worn", 269.6, 228.6, 0.0)       # the guests' parasol, furled by the patio
	b.add("prop_adirondack_white", "worn", 271.2, 227.8, 0.0)            # facing the bay view over the lot
	b.add("prop_adirondack_white", "worn", 272.8, 227.8, 0.0)
	b.add("plant_bougainvillea_mound", "normal", 282.0, 225.8, 40.0)
	# --- harbour bakery & coffee: the morning stop on the way down; one table out front, a bin at its corner
	var bak := b.bld("commercial/com_bakery", 289.5, 221.0, 180.0, "harbour_bakery", 0.7)
	b.add("prop_patio_set_4", "worn", 291.4, 212.5, 0.0)                  # door at u 286.2: the table sits 5 m east of it
	b.add("prop_trash_receptacle", "worn", 293.9, 213.3, 0.0)
	b.add("prop_newspaper_box_red", "worn", 284.0, 212.4, 180.0)          # in the gap between inn and bakery, facing the walk
	for k in 2: b.add(["prop_trash_cart_black", "prop_trash_cart_green"][k], "dirty", 285.6 + k * 0.8, 229.0, 180.0)   # behind, on its pad
	# --- Bay Bikes (hire): its rental bikes in racks along its front, parallel to the shopfront (door at u 297.7)
	var bik := b.bld("commercial/com_realty", 299.5, 221.0, 180.0, "bay_bike_hire", 0.7)
	b.add("prop_bike_rack", "worn", 301.0, 212.5, 0.0)
	b.add("prop_bike_rack", "worn", 301.0, 210.5, 0.0)
	b.add("prop_bike_rack", "worn", 297.0, 210.5, 0.0)
	b.at_bld(bik, "prop_hose_reel_wall", "worn", -2.2, -7.05, 180.0, 0.0, false)   # washing the sand off returned bikes, back wall
	# --- the driveway down into the lot (Pier St's apron, u 304-310): kept clear; tyre marks where cars turn in
	b.tyre_path(307.0, 211.4, 307.0, 234.0)
	b.add("prop_sign_no_parking", "worn", 311.0, 212.2, 90.0)             # at the drive's edge, facing traffic turning in
	# --- the Shoreline Grill: a family grill with a raised dining deck on its east side (door at u 313.2)
	var gr := b.bld("commercial/com_bistro", 318.0, 221.0, 180.0, "shoreline_grill", 0.7)
	for t2: float in [216.6, 221.0, 225.4]:
		b.add("prop_patio_set_4", "worn", 326.75, t2, 0.0)
	b.add("prop_shade_sail", "worn", 326.75, 221.0, 90.0, false)            # the deck's sail over the middle table
	b.add_at("fence_gate_wrought_iron", "worn", 324.95, 214.1, 5.47, 0.0)   # the deck's gate from the forecourt
	b.fence("iron", 325.5, 214.1, 328.9, 214.1, "worn", 5.47)            # deck railing toward the street (0.2-0.3 m over the walk)
	b.fence("iron", 328.9, 214.1, 328.9, 229.7, "worn", 5.47)            # and toward the planted gap (0.4 m drop)
	b.add("plant_potted_succulent", "normal", 311.2, 213.0, 0.0)         # marks the drive's edge at the grill's corner
	b.add("prop_trash_receptacle", "worn", 323.6, 213.2, 0.0)
	b.fence("iron", 311.5, 222.0, 311.5, 229.7, "worn", 5.47)            # along the drive
	b.fence("iron", 311.5, 229.7, 328.9, 229.7, "worn", 5.47)            # its back pad and deck over the lot
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "dirty", 313.0 + k * 0.8, 229.0, 180.0)
	b.roof(gr, ["prop_vent_box", "prop_ac_condenser_compact"])          # the kitchen extract
	b.roof(bak, ["prop_vent_box"])
	# ================= THE VISITOR LOT (upper level 4.90) =================
	# rows: A (230-235.5, noses to the wall), aisle 1, B + C back to back, aisle 2 (B Ave's apron), then a planted strip
	b.stalls_u(262.0, 15, 235.5, -1.0)                                    # row A west of the drive
	b.stalls_u(321.5, 3, 235.5, -1.0)                                     # row A east of the bins
	b.stalls_u(264.5, 11, 242.5, 1.0); b.stalls_u(264.5, 11, 253.5, -1.0)
	b.stalls_u(297.9, 12, 242.5, 1.0); b.stalls_u(297.9, 12, 253.5, -1.0)
	b.paint(261.2, 242.5, 264.5, 253.5, "grass")                          # end island (B Ave side)
	b.paint(293.5, 242.5, 297.5, 253.5, "grass")                          # mid island with the lot's light and a tree
	b.add("palm_mexican_fan_a", "normal", 262.85, 246.0, 10.0)
	b.add("plant_agave_americana_small", "normal", 262.85, 251.4, 0.0)
	b.add("tree_coral_a", "normal", 295.5, 250.0, 60.0)
	b.add("prop_lot_light_pole", "worn", 295.5, 244.6, 0.0)
	b.enclosure(317.5, 232.7, 0.0)                                       # the grill's and bakery's bins, at the lot's top
	b.add("prop_pay_station", "worn", 312.2, 234.4, 0.0)                 # by the Pier St way in, facing the aisle
	b.add("prop_pay_station", "worn", 277.5, 261.2, 180.0)               # by the B Ave way in, facing the aisle
	b.add("prop_sign_no_parking", "worn", 275.6, 261.1, 180.0)
	# the planted strip between the lot and the flats (v 260.5-266): trees in grass, the lot's south lights
	for t3: Array in [["palm_queen_b", 268.0], ["tree_magnolia_a", 284.0], ["palm_queen_a", 300.0], ["tree_coral_b", 316.0]]:
		b.add(String(t3[0]), "normal", float(t3[1]), 263.6, float(t3[1]) * 7.0)
	for lu: float in [276.0, 308.0]: b.add("prop_lot_light_pole", "worn", lu, 262.0, 180.0)
	b.add("prop_trash_receptacle", "worn", 290.0, 261.0, 0.0)            # where people get out and walk to the beach
	b.stall_wear(0.65)
	b.yard_wear(261.2, 230.0, 331.0, 260.5, 0.8)
	b.tyre_path(261.5, 257.0, 276.0, 257.0)                              # in from B Ave
	# ================= HOLIDAY FLATS (pad 4.60, fronts south onto the Beach Walk: yaw 0) =================
	var f1 := b.bld("apartments/apt_court_white", 272.0, 285.5, 0.0, "seabreeze_court", 0.6)
	var f2 := b.bld("apartments/apt_garden_cream", 300.0, 285.5, 0.0, "dune_garden_flats", 0.6)
	var f3 := b.bld("houses/beach_large", 320.5, 283.0, 0.0, "the_bayhouse_rental", 0.6)
	# steps from each front path down to the Beach Walk (the walk lies 0.2-0.6 m lower)
	for st: Array in [[270.5, 273.5], [298.5, 301.5], [317.0, 319.6]]:
		var uu := (float(st[0]) + float(st[1])) * 0.5
		b.stairs(float(st[0]), 292.0, float(st[1]), 294.0, "v", 4.60, b.y(uu, 295.5))
		b.paint(float(st[0]), 290.0, float(st[1]), 294.0, "concrete")
	for hb: Array in [[262.0, 270.0], [274.0, 298.0], [302.0, 316.6], [320.0, 328.5]]:
		var n := int((float(hb[1]) - float(hb[0])) / 2.1)
		for k in n: b.add("hedge_boxwood_low_2m", "normal", float(hb[0]) + 1.05 + k * 2.1, 293.4, 0.0)   # low front hedges, gaps at the paths
	for mb: Vector2 in [Vector2(275.0, 291.2), Vector2(303.0, 291.2), Vector2(316.1, 291.2)]: b.add("prop_mailbox_post_metal", "worn", mb.x, mb.y, 0.0)
	# the shared back gardens (between the flats and the lot's strip): a grill, a table, the washing, deck chairs
	b.add("prop_picnic_table", "worn", 268.0, 272.0, 90.0)
	b.add("prop_bbq_kettle", "worn", 271.5, 270.0, 0.0)
	b.add("prop_clothesline", "worn", 296.0, 271.0, 0.0)
	b.add("prop_adirondack_wood", "worn", 307.0, 272.5, 200.0); b.add("prop_adirondack_wood", "worn", 309.0, 272.5, 160.0)
	b.add("prop_patio_set_4", "worn", 322.0, 272.0, 0.0)
	b.add("prop_beach_umbrella_closed", "worn", 324.2, 270.6, 0.0)
	b.add("tree_magnolia_b", "normal", 284.0, 273.0, 120.0)
	b.add("palm_mexican_fan_b", "normal", 313.0, 270.0, 0.0)
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 281.6, 280.0 + k * 0.8, 90.0)   # by the court's side wall
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 311.6, 280.0 + k * 0.8, 90.0)
	b.add("prop_beach_shower", "worn", 326.5, 279.5, 0.0)               # rinse the sand off before going in
	# ================= THE BEACH WALK (public lane, 4.41 -> 4.00 m east) =================
	for lu2: float in [270.0, 298.0, 326.0]: b.add("prop_lamp_globe", "worn", lu2, 294.45, 0.0)
	b.add("prop_park_bench", "worn", 286.0, 294.5, 180.0)               # a rest on the lane, its back to the flats' hedge, facing the cottages
	b.add("prop_trash_receptacle", "worn", 288.0, 294.5, 0.0)
	b.add("prop_trash_receptacle", "worn", 330.2, 293.0, 0.0)           # where the footpath to the ring leaves the lane
	# ================= COTTAGES ON THE RING (fronts south to the ring: yaw 0; picket fronts, wood side fences) =================
	var cot: Array = [["houses/beach_white", 267.1, 319.0, "cottage_sandpiper", 261.2, 273.0, 4.15],
		["houses/beach_blue", 279.0, 319.0, "cottage_driftwood", 273.0, 285.0, 4.15],
		["houses/beach_large", 292.0, 316.0, "cottage_pelican", 285.0, 299.0, 4.08],
		["houses/beach_teal", 305.0, 319.0, "cottage_seaglass", 299.0, 311.0, 3.95],
		["houses/beach_white", 317.0, 318.5, "cottage_tidepool", 311.0, 323.0, 3.78]]
	for c: Array in cot:
		var hb2 := b.bld(String(c[0]), float(c[1]), float(c[2]), 0.0, String(c[3]), 0.55, false, false)
		b.back_of_house(hb2[0], hb2[1], hb2[2], true, true)
		var ua := float(c[4]); var ub := float(c[5]); var h := float(c[6])
		var vf: float = float(rb.call(ub)) - 0.25                                     # front fence just inside the pad
		var door_u: float = float(c[1]) + (float((K_DOORS[String(c[0])])))
		b.fence("picket", ua + 0.3, vf, door_u - 0.7, vf, "worn", h)
		b.fence("picket", door_u + 0.7, vf, ub - 0.3, vf, "worn", h)
		b.add("fence_gate_picket", "worn", door_u, vf, 0.0)
		b.paint(door_u - 0.6, float(c[2]) + float(hb2[2]) * 0.5, door_u + 0.6, vf, "concrete")   # the path to the door
		b.at_bld(hb2, "prop_porch_light_coach", "worn", float(K_DOORS[String(c[0])]) + 0.85, float(hb2[2]) * 0.5 + 0.02, 0.0, 2.0, false)
		b.add("prop_mailbox_post_wood", "worn", door_u + 1.1, vf - 0.35, 0.0)
		b.fence("privacy", ub, 298.4, ub, vf, "worn")                    # side fence on the lot line (stands at the lower pad)
		b.fence("picket", ua + 0.3, 298.4, ub - 0.3, 298.4, "worn", h)  # back fence on the lane's wall (the lane is 0.2-0.4 m higher)
	b.fence("privacy", 261.4, 298.4, 261.4, float(rb.call(273.0)) - 0.25, "worn")
	# back gardens, each its own: outdoor showers (sandy feet), a grill, deck chairs, a hammock spot under a palm
	b.add("prop_beach_shower", "worn", 271.8, 312.5, 0.0); b.add("prop_bbq_kettle", "worn", 264.0, 304.0, 0.0)
	b.add("prop_adirondack_wood", "worn", 266.5, 302.0, 180.0); b.add("palm_queen_b", "normal", 268.0, 306.5, 80.0)
	b.add("prop_patio_set_4", "worn", 279.0, 305.0, 0.0)
	b.add("prop_kayak_rack", "worn", 275.0, 300.6, 0.0)                 # their own kayaks, against the back fence
	b.add("prop_bbq_gas_cart", "worn", 289.0, 304.5, 0.0); b.add("prop_clothesline", "worn", 294.0, 302.0, 0.0)
	b.add("tree_coral_a", "normal", 297.5, 305.5, 10.0)
	b.add("prop_beach_shower", "worn", 309.8, 312.0, 0.0); b.add("prop_adirondack_white", "worn", 303.0, 303.0, 170.0); b.add("prop_adirondack_white", "worn", 305.0, 303.0, 190.0)
	b.add("palm_mexican_fan_c", "normal", 315.0, 304.0, 0.0); b.add("prop_bbq_kettle", "worn", 320.0, 302.5, 0.0)
	# front gardens: low planting by the fence, a palm or two (the ring's look)
	b.add("plant_bougainvillea_mound", "normal", 263.6, 325.4, 0.0); b.add("palm_queen_a", "normal", 284.0, 324.2, 15.0)
	b.add("plant_iceplant_patch", "normal", 297.0, 324.0, 0.0); b.add("plant_agave_americana", "normal", 309.0, 323.7, 30.0)
	b.add("plant_bird_of_paradise", "normal", 321.5, 323.4, 0.0)
	# the footpath from the Beach Walk down to the ring (u 323-331, the base field): a lamp at its top
	b.add("prop_lamp_globe", "worn", 323.6, 310.0, 0.0)
	b.building_wear()
	b.yard_wear(303.5, 211.2, 310.5, 236.0, 0.6)

## door offsets (local x, front) of the cottage models (kit stats doors_front)
const K_DOORS := {"houses/beach_white": -1.4, "houses/beach_blue": -1.4, "houses/beach_teal": 1.4, "houses/beach_large": -2.4}

## ---------------------------------------------------------------- POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
## quarters, both indoors and outdoors ... plenty of props and life"). Every spot below is chosen by hand with its reason;
## try_add() only refuses a spot that turns out taken (counted and printed), it decides nothing.
func polish(b: F) -> void:
	var T := func(base: String, cond: String, pts: Array, yaw := 0.0, surf: Array = []) -> void:
		for p: Vector2 in pts: b.try_add(base, cond, p.x, p.y, yaw, surf)
	# Pier St forecourts: the small things a busy shop front collects (plants, papers, a bin by every door group)
	T.call("plant_potted_succulent", "normal", [Vector2(266.6, 213.1), Vector2(282.6, 213.1), Vector2(295.0, 213.0)])
	T.call("prop_newspaper_box_blue", "worn", [Vector2(303.0, 212.4)], 180.0)
	T.call("prop_usps_collection_box", "worn", [Vector2(262.4, 210.6)], 180.0)           # the corner by B Ave: the inn's guests post cards
	T.call("plant_potted_leafy", "normal", [Vector2(324.0, 212.2), Vector2(310.9, 228.6)])
	# the guests' breakfast patio and the inn's garden: deck chairs, a shower for sandy feet, flowers by the walls
	T.call("plant_bird_of_paradise", "normal", [Vector2(262.6, 216.0), Vector2(262.6, 224.8), Vector2(282.6, 222.0)])
	T.call("prop_beach_shower", "worn", [Vector2(282.4, 228.2)])
	T.call("plant_bougainvillea_mound", "normal", [Vector2(262.8, 228.0)])
	# behind the shops: the grill's gas bottles, a hose cart, the bike hire's tools against its back wall
	T.call("prop_propane_cylinder_100lb", "rusty", [Vector2(321.6, 229.0), Vector2(322.2, 229.3)])
	T.call("prop_hose_reel_cart", "worn", [Vector2(300.8, 229.2), Vector2(288.4, 229.2)], 180.0)
	# the lot: drains in the aisles (it falls to them), oil and tyre arcs where cars turn at the aisle ends
	for d: Vector2 in [Vector2(283.0, 239.0), Vector2(316.0, 239.0), Vector2(283.0, 257.0), Vector2(316.0, 257.0)]:
		b.add("prop_storm_drain_grate", "dirty", d.x, d.y, 0.0, false, 0.002)
	for c: Vector2 in [Vector2(266.0, 239.0), Vector2(328.0, 239.0), Vector2(268.0, 257.0), Vector2(326.0, 257.0)]:
		b.mark(15, c, 30.0, 3.0, 2.0, Color(1, 1, 1, 0.45))
	# the planted strip between the lot and the flats: low planting under the trees (agave, bird of paradise, ice plant)
	T.call("plant_agave_americana_small", "normal", [Vector2(264.0, 262.6), Vector2(291.0, 262.6), Vector2(322.0, 262.6)])
	T.call("plant_iceplant_patch", "normal", [Vector2(273.0, 263.6), Vector2(306.0, 263.6)])
	T.call("plant_bird_of_paradise", "normal", [Vector2(279.6, 264.6), Vector2(311.6, 264.6), Vector2(327.6, 264.6)])
	# the flats' gardens: what holiday people leave out (chairs, a barbecue, a closed umbrella, flowers at the doors)
	T.call("prop_adirondack_wood", "worn", [Vector2(276.5, 272.4), Vector2(278.5, 272.4)], 160.0)
	T.call("prop_bbq_kettle", "worn", [Vector2(300.5, 269.4), Vector2(318.0, 268.6)])
	T.call("prop_beach_umbrella_closed", "worn", [Vector2(287.0, 269.0), Vector2(304.6, 270.0)])
	T.call("plant_bird_of_paradise", "normal", [Vector2(268.6, 291.6), Vector2(275.6, 291.6), Vector2(296.6, 291.6), Vector2(303.6, 291.6)])
	T.call("plant_potted_leafy", "normal", [Vector2(314.6, 291.6), Vector2(322.0, 291.6)])
	# the Beach Walk: a second rest and a bin by it, bike parking at the footpath
	T.call("prop_park_bench", "worn", [Vector2(312.0, 297.6)], 0.0, ["plaza"])
	T.call("prop_trash_receptacle", "worn", [Vector2(314.0, 297.6)], 0.0, ["plaza"])
	T.call("prop_bike_rack", "worn", [Vector2(327.0, 300.0)], 90.0)
	# the cottages' gardens: deck chairs, umbrellas, a hose cart, flowers in the front gardens, a cooler by the barbecue
	T.call("prop_adirondack_white", "worn", [Vector2(264.0, 309.0), Vector2(287.0, 304.0), Vector2(301.0, 307.0), Vector2(318.0, 307.0)], 180.0)
	T.call("prop_beach_umbrella", "worn", [Vector2(270.0, 302.0), Vector2(313.0, 302.5)])
	T.call("prop_hose_reel_cart", "worn", [Vector2(276.6, 312.6), Vector2(296.6, 312.0)], 90.0)
	T.call("plant_iceplant_patch", "normal", [Vector2(272.0, 325.6), Vector2(290.0, 324.8), Vector2(316.0, 323.8)])
	T.call("plant_bougainvillea_mound", "normal", [Vector2(278.0, 325.0), Vector2(302.6, 324.4)])
	T.call("prop_ice_chest", "worn", [Vector2(266.6, 304.6)])
	# the footpath to the ring: a bin at its foot, sand carried up on it
	T.call("prop_trash_receptacle", "worn", [Vector2(330.0, 320.0)])
	b.sand_drift(323.0, 298.0, 331.0, 324.0, 4); b.sand_drift(261.2, 294.0, 331.0, 298.0, 6)
	b.sand_drift(295.5, 211.2, 303.5, 214.0, 3)                          # off the returned hire bikes
	b.polish_report()
