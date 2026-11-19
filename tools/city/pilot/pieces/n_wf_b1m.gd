extends SceneTree
## Piece n_wf_b1m (waterfront fill, block 1 MIDDLE: grid u 331-404, between Pier St and the ring).
## WHO COMES HERE AND WHY: the middle of Pier St, where the walk down to the pier gets busy: an ice-cream parlour with a
## swimwear shop and a gift shop in one row, the Pier Steps (a public ramp from Pier St down into the lot and on to the
## Beach Walk: the way drivers walk to the pier), the Tide Bar with its raised deck, and the dive & surf row. Behind: the
## middle of the visitor lot (its ramps take cars down from the upper level), holiday flats, the Beach Walk, cottages.
## THE GROUND: Pier St falls 5.11 -> 2.72 m here, the ring 3.47 -> 1.92. Pads:
##   ice cream row 4.67 | Pier Steps ramp 4.27 -> 3.60 (3.5 %) | Tide Bar with deck 3.88 | dive & surf row 3.17
##   lot: upper level 4.90 continues to u 343, ramps on both aisles 4.90 -> 3.60 (8.1 %), lower-middle level 3.60;
##   planted beds beside the ramps at 3.60 | flats 3.45 | Beach Walk 4.00 -> 2.55 | cottages 3.35 / 2.92 / 2.65 / 2.38 / 2.10
##   2 m strips at both seams follow the base field (shared height lines with n_wf_b1w and n_wf_b1e).
## Run: GROUND_ONLY=1 for the ground alone (first check), then without. A draft until Yasin has seen it; never when locked.
const F := preload("res://tools/city/pilot/pieces/wf_fill_lib.gd")

static func ring_v(u: float) -> float: return 330.27 - (u - 259.2) * 0.045497
static func ring_band(u: float) -> float: return ring_v(u) - 2.05

func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := F.new("n_wf_b1m")
	ground(b)
	if OS.get_environment("GROUND_ONLY") == "1":
		b.finish(true); quit(); return
	life(b)
	polish(b)
	b.finish()
	quit()

func ground(b: F) -> void:
	b.band = 2.0
	# ---- Pier St front
	b.terrace(333.0, 211.2, 353.6, 230.0, 4.67, "wall", 0, "ice cream row")
	b.terrace(360.0, 211.2, 378.0, 230.0, 3.88, "wall", 0, "Tide Bar + deck")
	b.terrace(378.0, 211.2, 401.0, 230.0, 3.17, "wall", 0, "dive & surf row")
	# ---- the lot: upper level (from n_wf_b1w) to u 343, lower-middle level beyond; beds beside the ramps
	b.terrace(331.0, 230.0, 343.0, 266.0, 4.90, "wall", 0, "lot upper level")
	b.terrace(343.0, 230.0, 404.0, 266.0, 3.60, "wall", 0, "lot middle level")
	b.terrace(333.0, 266.0, 401.0, 294.0, 3.45, "wall", 0, "holiday flats")
	b.terrace(333.0, 298.0, 355.0, ring_band(355.0), 3.35, "wall", 0, "holiday flats on the ring")
	b.terrace(355.0, 298.0, 366.0, ring_band(366.0), 2.92, "wall", 0, "cottage 6")
	b.terrace(366.0, 298.0, 378.0, ring_band(378.0), 2.65, "wall", 0, "cottage 7")
	b.terrace(378.0, 298.0, 392.0, ring_band(392.0), 2.38, "wall", 0, "cottage 8")
	b.terrace(392.0, 298.0, 401.0, ring_band(401.0), 2.10, "wall", 0, "cottage 9")
	# ---- ramps
	b.ramp(353.6, 211.2, 360.0, 230.0, "v", 4.30, 3.60)                 # the Pier Steps (a ramp: prams, bikes, beach carts)
	b.ramp(343.0, 235.5, 359.0, 242.5, "u", 4.90, 3.60, true)           # aisle 1 down a level
	b.ramp(343.0, 253.5, 359.0, 260.5, "u", 4.90, 3.60, true)           # aisle 2 down a level
	b.ramp(331.0, 294.0, 404.0, 298.0, "u", 4.00, 2.55)                 # the Beach Walk
	# ---- surfaces
	b.paint(331.0, 209.2, 404.0, 211.2, "concrete")
	b.paint(331.0, 230.0, 333.0, 294.0, "grass"); b.paint(401.0, 266.0, 404.0, 294.0, "grass")
	b.paint(331.0, 211.2, 333.0, 230.0, "mulch")
	b.paint(401.0, 211.2, 404.0, 230.0, "mulch")
	b.paint(333.0, 211.2, 401.0, 214.0, "concrete")
	b.paint(353.6, 211.2, 360.0, 230.0, "plaza")
	b.paint(371.5, 214.0, 378.0, 228.0, "plaza")                       # the bar's deck
	b.paint(343.0, 230.0, 359.0, 235.5, "mulch"); b.paint(343.0, 242.5, 359.0, 253.5, "mulch")   # beds beside the ramps
	b.paint(331.0, 260.5, 404.0, 266.0, "grass")
	b.paint(331.0, 266.0, 404.0, 294.0, "grass")
	b.paint(331.0, 294.0, 404.0, 298.0, "plaza")
	b.paint(331.0, 298.0, 404.0, 340.0, "grass")


const K_DOORS := {"houses/beach_white": -1.4, "houses/beach_blue": -1.4, "houses/beach_teal": 1.4, "houses/beach_large": -2.4, "apartments/apt_beach_condo": 0.0}

## ---------------------------------------------------------------- buildings, then props, each with its reason
func life(b: F) -> void:
	# ================= PIER ST FRONT (fronts at v 214, facing Pier St: yaw 180) =================
	# --- the ice-cream row: Scoops (door u 348.6), Sandbar swimwear (346.4), Seashell gifts (336.7)
	var row := b.bld("commercial/com_orange_row", 344.5, 221.0, 180.0, "scoops_row", 0.7)
	b.add("prop_park_bench", "worn", 351.6, 212.6, 180.0)                # ice cream eaten on the bench, facing the street
	b.add("prop_trash_receptacle", "dirty", 354.4, 212.2, 0.0)           # the cones' napkins end here, at the top of the Pier Steps
	b.add("prop_newspaper_box_blue", "worn", 340.2, 212.5, 180.0)
	b.add("plant_potted_succulent", "normal", 343.2, 213.2, 0.0)
	b.fence("iron", 343.2, 228.4, 343.2, 229.7, "worn", 4.67)            # its back pad over the lower lot (1.1 m drop),
	b.fence("iron", 343.2, 229.7, 353.5, 229.7, "worn", 4.67)            # from the building's back to its corner
	b.fence("iron", 353.5, 229.7, 353.5, 228.3, "worn", 4.67)
	b.roof(row, ["prop_ac_condenser", "prop_vent_box", "prop_ac_condenser_compact"])
	# --- the Pier Steps: a public ramp from Pier St down to the lot and the Beach Walk; a lamp at its top and foot
	b.add("prop_lamp_globe", "worn", 359.6, 212.6, 0.0)
	b.add("prop_lamp_globe", "worn", 356.4, 229.0, 0.0)
	# --- the Tide Bar with its raised deck on the east side (door at u 369.8)
	var bar := b.bld("commercial/com_bar_crown", 366.5, 221.0, 180.0, "tide_bar", 0.75)
	for t2: float in [216.6, 221.0, 225.4]:
		b.add("prop_patio_set_4", "worn", 374.75, t2, 0.0)
	b.add("prop_shade_sail", "worn", 374.75, 221.0, 90.0, false)            # the deck's sail over the middle table
	b.fence("iron", 371.4, 214.1, 377.9, 214.1, "worn", 3.88)
	b.fence("iron", 377.9, 214.1, 377.9, 228.4, "worn", 3.88)            # 0.7 m over the dive row's pad
	b.fence("iron", 377.9, 228.4, 380.3, 228.4, "worn")                   # closing on the dive row's back corner
	b.add("prop_trash_receptacle", "worn", 362.3, 213.2, 0.0)
	b.roof(bar, ["prop_vent_box"])
	for k in 2: b.add(["prop_trash_cart_black", "prop_trash_cart_blue"][k], "dirty", 362.8 + k * 0.8, 229.2, 180.0)
	# --- the dive & surf row: Deep Blue Dive (door u 393.6), Sun & Sand (391.4), Salt Surf Co. (381.7)
	var dv := b.bld("commercial/com_boutique_row", 389.5, 221.0, 180.0, "dive_surf_row", 0.75)
	b.add("prop_bike_rack", "worn", 386.8, 212.5, 0.0)                   # parallel to the shopfront, between two doors
	b.add("prop_trash_receptacle", "worn", 397.0, 213.3, 0.0)
	b.add("prop_kayak_rack", "worn", 399.6, 223.0, 90.0)                 # the surf shop's rental boards, at its side wall
	b.roof(dv, ["prop_ac_condenser", "prop_ac_condenser_compact"])
	# ================= THE LOT: upper level to u 343, ramps on both aisles, middle level 3.60 =================
	b.stalls_u(331.4, 4, 235.5, -1.0); b.stalls_u(331.4, 4, 242.5, 1.0); b.stalls_u(331.4, 4, 253.5, -1.0)
	b.stalls_u(360.4, 16, 235.5, -1.0)
	b.stalls_u(359.2, 7, 242.5, 1.0); b.stalls_u(359.2, 7, 253.5, -1.0)
	b.stalls_u(381.4, 8, 242.5, 1.0); b.stalls_u(381.4, 8, 253.5, -1.0)
	b.paint(377.4, 242.5, 381.4, 253.5, "grass")
	b.add("tree_magnolia_a", "normal", 379.4, 250.6, 40.0); b.add("prop_lot_light_pole", "worn", 379.4, 244.6, 0.0)
	# beds beside the ramps (lower than the ramps): planting, and steel bollards along the ramp edges
	for bu: float in [344.6, 349.0, 353.4, 357.8]:
		b.add("prop_bollard_steel", "worn", bu, 235.75, 0.0); b.add("prop_bollard_steel", "worn", bu, 242.25, 0.0)
		b.add("prop_bollard_steel", "worn", bu, 253.75, 0.0); b.add("prop_bollard_steel", "worn", bu, 260.25, 0.0)
	b.add("plant_bougainvillea_mound", "normal", 349.0, 232.6, 0.0); b.add("plant_agave_americana", "normal", 354.0, 232.8, 20.0)
	b.add("tree_coral_b", "normal", 351.0, 248.0, 0.0); b.add("prop_lot_light_pole", "worn", 346.0, 248.0, 0.0)
	b.add("plant_iceplant_patch", "normal", 356.5, 246.0, 0.0)
	b.add("prop_trash_receptacle", "worn", 358.4, 231.0, 0.0)           # at the foot of the Pier Steps
	for t3: Array in [["palm_queen_a", 340.0], ["tree_magnolia_b", 362.0], ["palm_mexican_fan_a", 384.0]]:
		b.add(String(t3[0]), "normal", float(t3[1]), 263.6, float(t3[1]) * 3.0)
	b.add("prop_lot_light_pole", "worn", 397.0, 262.0, 180.0)
	b.stall_wear(0.65)
	b.yard_wear(359.0, 230.0, 404.0, 260.5, 0.8)
	b.yard_wear(331.0, 230.0, 343.0, 260.5, 0.8)
	# ================= HOLIDAY FLATS (pad 3.45, fronts south to the Beach Walk) =================
	var f1 := b.bld("apartments/apt_stucco3_cream", 344.0, 284.0, 0.0, "harbour_view_flats", 0.6)
	var f2 := b.bld("apartments/apt_garden_mint", 368.0, 285.5, 0.0, "seagrass_flats", 0.6)
	var f3 := b.bld("apartments/apt_spanish_white", 390.5, 285.0, 0.0, "casa_azul_flats", 0.6)
	for st: Array in [[342.5, 345.5], [366.5, 369.5], [389.0, 392.0]]:
		var uu := (float(st[0]) + float(st[1])) * 0.5
		b.stairs(float(st[0]), 292.0, float(st[1]), 294.0, "v", 3.45, b.y(uu, 295.5))
		b.paint(float(st[0]), 290.0, float(st[1]), 294.0, "concrete")
	for hb: Array in [[334.0, 342.0], [346.0, 366.0], [370.0, 388.6], [392.4, 400.6]]:
		var n := int((float(hb[1]) - float(hb[0])) / 2.1)
		for k in n: b.add("hedge_boxwood_low_2m", "normal", float(hb[0]) + 1.05 + k * 2.1, 293.4, 0.0)
	for mb: Vector2 in [Vector2(347.0, 291.4), Vector2(371.0, 291.4), Vector2(393.6, 291.4)]: b.add("prop_mailbox_post_metal", "worn", mb.x, mb.y, 0.0)
	b.add("prop_picnic_table", "worn", 340.0, 271.0, 90.0); b.add("prop_bbq_gas_cart", "worn", 344.0, 269.2, 0.0)
	b.add("prop_clothesline", "worn", 368.0, 272.0, 0.0)
	b.add("prop_patio_set_4", "worn", 386.0, 272.0, 0.0)
	b.add("tree_jacaranda_a", "normal", 356.5, 272.5, 0.0); b.add("palm_queen_b", "normal", 397.5, 272.0, 0.0)
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 355.2, 281.0 + k * 0.8, 90.0)
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 380.2, 281.0 + k * 0.8, 90.0)
	b.roof(f1, ["prop_ac_condenser", "prop_ac_condenser", "prop_satellite_dish"])
	# ================= THE BEACH WALK =================
	for lu2: float in [345.0, 372.0, 399.0]: b.add("prop_lamp_globe", "worn", lu2, 294.45, 0.0)
	b.add("prop_park_bench", "worn", 380.0, 294.5, 180.0); b.add("prop_trash_receptacle", "worn", 382.0, 294.5, 0.0)
	b.add("prop_drinking_fountain", "worn", 356.0, 294.5, 180.0)        # halfway down, for people coming up from the beach
	# ================= ON THE RING: holiday flats and cottages (fronts south: yaw 0) =================
	var cot: Array = [["apartments/apt_beach_condo", 344.0, 314.4, "ringside_holiday_flats", 333.0, 355.0, 3.35],
		["houses/beach_teal", 360.5, 315.4, "cottage_sand_dollar", 355.0, 366.0, 2.92],
		["houses/beach_blue", 372.0, 314.3, "cottage_starfish", 366.0, 378.0, 2.65],
		["houses/beach_large", 385.0, 310.9, "cottage_osprey", 378.0, 392.0, 2.38],
		["houses/beach_white", 396.5, 313.2, "cottage_conch", 392.0, 401.0, 2.10]]
	for c: Array in cot:
		var big := String(c[0]).begins_with("apartments")
		var hb2 := b.bld(String(c[0]), float(c[1]), float(c[2]), 0.0, String(c[3]), 0.55, big, false)
		if not big: b.back_of_house(hb2[0], hb2[1], hb2[2], true, true)
		var ua := float(c[4]); var ub := float(c[5]); var h := float(c[6])
		var vf: float = ring_band(ub) - 0.25
		var door_u: float = float(c[1]) + float(K_DOORS[String(c[0])])
		b.fence("picket", ua + 0.3, vf, door_u - 0.7, vf, "worn", h)
		b.fence("picket", door_u + 0.7, vf, ub - 0.3, vf, "worn", h)
		b.add("fence_gate_picket", "worn", door_u, vf, 0.0)
		b.paint(door_u - 0.6, float(c[2]) + float(hb2[2]) * 0.5, door_u + 0.6, vf, "concrete")
		if not big: b.at_bld(hb2, "prop_porch_light_coach", "worn", float(K_DOORS[String(c[0])]) + 0.85, float(hb2[2]) * 0.5 + 0.02, 0.0, 2.0, false)
		b.add("prop_mailbox_post_wood", "worn", door_u + 1.1, vf - 0.35, 0.0)
		if ub < 400.0: b.fence("privacy", ub, 298.4, ub, vf, "worn")
		b.fence("picket", ua + 0.3, 298.4, ub - 0.3, 298.4, "worn", h)
	b.fence("privacy", 333.2, 298.4, 333.2, ring_band(355.0) - 0.25, "worn")
	b.fence("privacy", 400.8, 298.4, 400.8, ring_band(401.0) - 0.25, "worn")
	# the ringside flats' shared yard: a pool-less sun patch with loungers, their bikes, the bins
	b.add("prop_adirondack_white", "worn", 337.5, 302.5, 160.0); b.add("prop_adirondack_white", "worn", 339.5, 302.5, 200.0)
	b.add("prop_bike_rack", "worn", 350.0, 299.6, 0.0); b.add("prop_beach_shower", "worn", 353.6, 305.0, 0.0)
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 334.4, 306.0 + k * 0.8, 90.0)
	b.add("prop_bbq_kettle", "worn", 358.0, 301.5, 0.0); b.add("palm_mexican_fan_b", "normal", 363.0, 303.0, 0.0)
	b.add("prop_beach_shower", "worn", 376.6, 306.0, 0.0); b.add("prop_patio_set_4", "worn", 370.0, 302.5, 0.0)
	b.add("prop_clothesline", "worn", 382.0, 300.6, 0.0); b.add("tree_coral_a", "normal", 389.5, 302.5, 0.0)
	b.add("prop_adirondack_wood", "worn", 396.0, 302.0, 180.0); b.add("prop_kayak_rack", "worn", 393.2, 303.0, 90.0)
	b.add("plant_bougainvillea_mound", "normal", 336.0, 322.0, 0.0); b.add("palm_queen_a", "normal", 352.0, 321.4, 0.0)
	b.add("plant_bird_of_paradise", "normal", 364.0, 320.8, 0.0); b.add("plant_iceplant_patch", "normal", 376.0, 320.4, 0.0)
	b.add("plant_agave_americana", "normal", 390.6, 320.0, 0.0)
	b.building_wear()

## ---------------------------------------------------------------- POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
## quarters, both indoors and outdoors ... plenty of props and life"). Every spot below is chosen by hand with its reason;
## try_add() only refuses a spot that turns out taken (counted and printed), it decides nothing.
func polish(b: F) -> void:
	var T := func(base: String, cond: String, pts: Array, yaw := 0.0, surf: Array = []) -> void:
		for p: Vector2 in pts: b.try_add(base, cond, p.x, p.y, yaw, surf)
	# Pier St forecourts: plants, papers, a bin by each door group, a bench at the Pier Steps' top
	T.call("plant_potted_leafy", "normal", [Vector2(334.2, 213.0), Vector2(361.2, 213.0), Vector2(379.0, 213.0), Vector2(399.6, 213.0)])
	T.call("prop_newspaper_box_red", "worn", [Vector2(384.0, 212.4)], 180.0)
	T.call("prop_recycling_receptacle", "worn", [Vector2(355.6, 212.2)])
	T.call("prop_sign_ped_crossing", "worn", [Vector2(359.8, 214.2)], 180.0)            # the Pier Steps cross the shops' back strip
	# the bar's deck: plants at its corners
	T.call("plant_potted_succulent", "normal", [Vector2(372.0, 227.4), Vector2(377.2, 227.4)])
	# behind the shops: kegs and gas bottles behind the bar, the dive shop's tank cylinders, bins for the row
	T.call("prop_propane_cylinder_100lb", "rusty", [Vector2(369.0, 229.2), Vector2(369.6, 229.4)])
	T.call("prop_propane_cylinder_100lb", "worn", [Vector2(392.4, 229.2), Vector2(393.0, 229.4), Vector2(393.6, 229.2)])
	for k in 3: b.try_add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "dirty", 397.0 + k * 0.8, 229.1, 180.0)
	for k in 3: b.try_add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "dirty", 337.0 + k * 0.8, 229.1, 180.0)
	# the lot's drains and the turning arcs at the aisles' ends
	for d: Vector2 in [Vector2(372.0, 239.0), Vector2(395.0, 239.0), Vector2(372.0, 257.0), Vector2(395.0, 257.0)]:
		b.add("prop_storm_drain_grate", "dirty", d.x, d.y, 0.0, false, 0.002)
	for c: Vector2 in [Vector2(401.0, 239.0), Vector2(401.0, 257.0)]: b.mark(15, c, -30.0, 3.0, 2.0, Color(1, 1, 1, 0.45))
	# the beds beside the ramps and the strip before the flats: more planting
	T.call("plant_bird_of_paradise", "normal", [Vector2(345.0, 233.6), Vector2(345.0, 251.4), Vector2(357.0, 251.4)])
	T.call("plant_agave_americana_small", "normal", [Vector2(350.0, 262.6), Vector2(373.0, 262.6), Vector2(391.0, 262.6)])
	T.call("plant_iceplant_patch", "normal", [Vector2(335.0, 263.4), Vector2(356.0, 263.6), Vector2(402.0, 263.4)])
	# the flats' gardens: chairs, barbecues, a closed umbrella, a shower, flowers at the paths
	T.call("prop_adirondack_wood", "worn", [Vector2(352.5, 269.4), Vector2(354.5, 269.4), Vector2(395.0, 269.2)], 160.0)
	T.call("prop_bbq_kettle", "worn", [Vector2(363.0, 270.2), Vector2(399.4, 276.0)])
	T.call("prop_beach_umbrella_closed", "worn", [Vector2(374.6, 270.0)])
	T.call("prop_beach_shower", "worn", [Vector2(381.0, 277.6), Vector2(355.6, 279.0)])
	T.call("plant_bird_of_paradise", "normal", [Vector2(340.6, 291.6), Vector2(347.4, 291.6), Vector2(364.6, 291.6), Vector2(372.6, 291.6), Vector2(387.0, 291.6), Vector2(394.0, 291.6)])
	# the Beach Walk: another bench, bike parking
	T.call("prop_park_bench", "worn", [Vector2(346.0, 297.6), Vector2(392.0, 297.6)], 0.0, ["plaza"])
	T.call("prop_bike_rack", "worn", [Vector2(360.0, 294.5)], 0.0)
	# the cottages and ringside flats: deck chairs, umbrellas, a hose cart, a cooler, flowers out front
	T.call("prop_adirondack_white", "worn", [Vector2(345.0, 303.0), Vector2(366.0, 301.6), Vector2(390.0, 301.4)], 180.0)
	T.call("prop_beach_umbrella", "worn", [Vector2(347.0, 300.5), Vector2(395.4, 304.2)])
	T.call("prop_hose_reel_cart", "worn", [Vector2(357.0, 307.0), Vector2(380.0, 305.0)], 90.0)
	T.call("prop_ice_chest", "worn", [Vector2(360.0, 301.0)])
	T.call("plant_bougainvillea_mound", "normal", [Vector2(344.0, 321.4), Vector2(370.0, 320.2), Vector2(398.0, 319.6)])
	T.call("plant_iceplant_patch", "normal", [Vector2(358.0, 320.6), Vector2(383.0, 320.2)])
	b.sand_drift(331.0, 294.0, 404.0, 298.0, 7); b.sand_drift(353.6, 220.0, 360.0, 230.0, 3)
	b.polish_report()
