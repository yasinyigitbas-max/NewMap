extends SceneTree
## Piece n_wf_b2m (waterfront fill, block 2 MIDDLE: grid u 335-400): the hill's steep bank, 8 -> 3 m.
## WHO COMES HERE AND WHY: holiday flats on terraces stepping down the bank, every one with its sea-view deck (the
## reason people rent here), reached on foot by THE STEPS (the public walk from Vista Park down to the boats: stairs at
## every wall, a landing with benches turned to the bay on each terrace). On Pier St: the Pier Street Arcade (a surf
## cafe, a swimwear-and-sandals shop, a gallery of local painters), Tide Pool Books, and the Sunset Arcade (candy and
## fudge, beach outfitters, sunglasses, an espresso bar).
## THE GROUND: north street walk 8.9 -> 6.0, Pier St 4.9 -> 2.7; land 8 -> 2 across the bank. Three columns of terraces,
##   C (u 318-352, with n_wf_b2w): 8.40 / 6.80 / 5.80; D (352-386): 7.00 / 5.20 / 4.20; E (386-412, with n_wf_b2e):
##   5.80 / 3.80 / 3.00. Pier St pads: arcade 4.55, books 4.00, Sunset Arcade 3.20. The Steps: C2 -> D2 10 risers,
##   D2 -> E2 9 risers. A retaining face on every step, guard railings on the high side of every drop over 0.6 m.
## Run: GROUND_ONLY=1 for the ground alone (first check), then without. A draft until Yasin has seen it; never when locked.
const F := preload("res://tools/city/pilot/pieces/wf_fill_lib.gd")
const BW := preload("res://tools/city/pilot/pieces/n_wf_b2w.gd")
const BE := preload("res://tools/city/pilot/pieces/n_wf_b2e.gd")

func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := F.new("n_wf_b2m")
	ground(b)
	if OS.get_environment("GROUND_ONLY") == "1":
		b.finish(true); quit(); return
	life(b)
	polish(b)
	b.finish()
	quit()

func ground(b: F) -> void:
	b.band = 2.0
	BW.column_c(b)
	b.terrace(352.0, 11.2, 386.0, 55.0, 7.00, "wall", 0, "flats D1")
	b.terrace(352.0, 55.0, 386.0, 112.0, 5.20, "wall", 0, "flats D2")
	b.terrace(352.0, 112.0, 386.0, 168.0, 4.20, "wall", 0, "flats D3")
	BE.column_e(b)
	b.terrace(336.0, 168.0, 363.0, 188.8, 4.55, "wall", 0, "Pier Street Arcade")
	b.terrace(363.0, 168.0, 372.0, 188.8, 4.00, "wall", 0, "Tide Pool Books")
	b.terrace(372.0, 168.0, 399.2, 188.8, 3.20, "wall", 0, "Sunset Arcade")
	b.stairs(348.0, 104.0, 356.0, 108.0, "u", 6.80, 5.20)               # the Steps: C2 -> D2
	b.stairs(382.0, 104.0, 389.0, 108.0, "u", 5.20, 3.80)               # D2 -> E2
	b.paint(335.0, 9.2, 400.0, 11.2, "concrete"); b.paint(335.0, 186.0, 400.0, 190.8, "concrete")
	b.paint(335.0, 168.0, 336.0, 188.8, "mulch")
	b.paint(335.0, 104.0, 400.0, 108.0, "plaza")
	b.paint(335.0, 11.2, 400.0, 168.0, "grass")
	b.paint(336.0, 168.0, 400.0, 172.0, "concrete")

## ---------------------------------------------------------------- buildings, then props, each with its reason
func life(b: F) -> void:
	# ================= COLUMN C's decks (u 335-352): the flats in n_wf_b2w look east over these lawns ==================
	b.guard(351.8, 11.6, 351.8, 103.8, Vector2(-1, 0)); b.guard(351.8, 108.2, 351.8, 167.8, Vector2(-1, 0))   # C -> D (1.4-1.6 m)
	b.guard(335.0, 59.8, 339.8, 59.8, Vector2(0, -1)); b.guard(344.2, 59.8, 351.8, 59.8, Vector2(0, -1))
	b.guard(335.0, 114.8, 339.8, 114.8, Vector2(0, -1)); b.guard(344.2, 114.8, 351.8, 114.8, Vector2(0, -1))
	b.stairs(340.0, 57.0, 344.0, 63.0, "v", 8.40, 6.80); b.paint(340.0, 57.0, 344.0, 63.0, "concrete")      # C1 -> C2
	b.stairs(340.0, 112.0, 344.0, 118.0, "v", 6.80, 5.80); b.paint(340.0, 112.0, 344.0, 118.0, "concrete")  # C2 -> C3
	for a: Array in [[348.0, 30.0], [348.0, 32.0], [348.0, 76.0], [348.0, 78.0], [348.0, 88.0]]:
		b.add("prop_adirondack_wood", "worn", float(a[0]), float(a[1]), 90.0)            # deck chairs turned to the bay
	b.add("prop_patio_set_4", "worn", 341.0, 40.0, 0.0); b.add("prop_bbq_kettle", "worn", 338.0, 46.0, 0.0)
	b.add("prop_patio_set_4", "worn", 341.0, 84.0, 0.0); b.add("prop_beach_umbrella_closed", "worn", 343.2, 86.0, 0.0)
	b.add("prop_picnic_table", "worn", 342.0, 140.0, 90.0); b.add("prop_clothesline", "worn", 338.0, 152.0, 90.0)
	for t: Array in [["palm_queen_a", 346.0, 20.0], ["palm_mexican_fan_a", 346.0, 98.0], ["tree_coral_a", 346.0, 130.0], ["palm_queen_b", 338.0, 162.0]]:
		b.add(String(t[0]), "normal", float(t[1]), float(t[2]), float(t[1]) * 2.0)
	# ================= COLUMN D (u 352-386): flats facing east, decks, stairs between the levels ========================
	var d1 := b.bld("apartments/apt_spanish_white", 359.5, 32.0, 90.0, "casa_del_sol_flats", 0.55)
	var d2 := b.bld("apartments/apt_stucco3_cream", 360.0, 80.0, 90.0, "bayside_heights_flats", 0.55)
	var d3 := b.bld("apartments/apt_court_white", 358.5, 140.0, 90.0, "pelican_court_flats", 0.55)
	b.roof(d2, ["prop_ac_condenser", "prop_satellite_dish"])
	b.guard(385.8, 11.6, 385.8, 103.8, Vector2(-1, 0)); b.guard(385.8, 108.2, 385.8, 167.8, Vector2(-1, 0))   # D -> E (1.2-1.4 m)
	b.guard(352.0, 54.8, 365.8, 54.8, Vector2(0, -1)); b.guard(370.2, 54.8, 385.8, 54.8, Vector2(0, -1))     # D1 -> D2 (1.8 m)
	b.guard(352.0, 111.8, 365.8, 111.8, Vector2(0, -1)); b.guard(370.2, 111.8, 385.8, 111.8, Vector2(0, -1)) # D2 -> D3 (1.0 m)
	b.stairs(366.0, 52.0, 370.0, 58.0, "v", 7.00, 5.20); b.paint(366.0, 52.0, 370.0, 58.0, "concrete")
	b.stairs(366.0, 109.0, 370.0, 115.0, "v", 5.20, 4.20); b.paint(366.0, 109.0, 370.0, 115.0, "concrete")
	b.stairs(372.0, 11.2, 374.0, 15.0, "v", 7.40, 7.00); b.paint(372.0, 11.2, 374.0, 15.0, "concrete")      # the street gate to D1
	b.guard(371.8, 11.6, 335.0, 11.6, Vector2(0, -1)); b.guard(385.8, 11.6, 374.2, 11.6, Vector2(0, -1))
	b.add("prop_mailbox_post_metal", "worn", 375.6, 16.0, 0.0)
	for a2: Array in [[382.0, 26.0], [382.0, 28.0], [382.0, 74.0], [382.0, 76.0], [382.0, 86.0], [380.0, 134.0], [380.0, 136.0]]:
		b.add("prop_adirondack_white", "worn", float(a2[0]), float(a2[1]), 90.0)
	b.add("prop_patio_set_4", "worn", 374.0, 40.0, 0.0); b.add("prop_bbq_gas_cart", "worn", 371.0, 22.0, 90.0)
	b.add("prop_patio_set_4", "worn", 375.0, 92.0, 0.0); b.add("prop_beach_shower", "worn", 368.4, 66.0, 0.0)
	b.add("prop_picnic_table", "worn", 374.0, 152.0, 90.0); b.add("prop_bbq_kettle", "worn", 370.0, 158.0, 0.0)
	for t2: Array in [["palm_mexican_fan_b", 378.0, 18.0], ["tree_jacaranda_b", 376.0, 64.0], ["palm_queen_a", 380.0, 98.0], ["palm_canary_date_a", 376.0, 124.0], ["tree_magnolia_a", 372.0, 162.0]]:
		b.add(String(t2[0]), "normal", float(t2[1]), float(t2[2]), float(t2[1]) * 2.0)
	for d: Array in [d1, d2, d3]:
		for k in 3: b.at_bld(d, ["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -float(d[1]) * 0.5 - 0.55, -1.2 + k * 0.8, -90.0)   # against the north end wall (the back strip is too narrow)
	# ================= COLUMN E (u 386-400 of it; the rest in n_wf_b2e) ==================================================
	b.bld("houses/beach_blue", 392.0, 30.0, 90.0, "the_lookout_rental", 0.55)
	b.bld("apartments/apt_beach_condo", 392.5, 78.0, 90.0, "steps_end_flats", 0.55)
	b.bld("houses/beach_teal", 391.0, 132.0, 90.0, "cottage_sea_lavender", 0.55)
	b.bld("houses/beach_white", 391.0, 152.0, 90.0, "cottage_saltgrass", 0.55)
	b.guard(386.0, 49.8, 400.0, 49.8, Vector2(0, -1)); b.guard(386.2, 111.8, 400.0, 111.8, Vector2(0, -1))
	b.guard(400.0, 11.6, 386.2, 11.6, Vector2(0, -1))
	b.guard(335.0, 167.6, 400.0, 167.6, Vector2(0, -1))                        # the terraces' back wall over the Pier St shops (a parapet from above)
	# ================= THE STEPS: a landing on every terrace with a bench turned to the bay ============================
	b.add("prop_park_bench", "worn", 346.0, 103.4, 90.0); b.add("prop_lamp_globe", "worn", 346.0, 108.6, 0.0)
	b.add("prop_park_bench", "worn", 379.0, 103.4, 90.0); b.add("prop_lamp_globe", "worn", 379.0, 108.6, 0.0); b.add("prop_trash_receptacle", "worn", 377.4, 103.4, 0.0)
	b.add("prop_lamp_globe", "worn", 362.0, 108.6, 0.0)
	for bv: float in [58.0, 63.0, 95.0, 100.0]: b.add("plant_bougainvillea_wall", "normal", 352.6, bv, 90.0)    # on the C -> D wall face, clear of the flats
	for bv2: float in [55.0, 60.0, 92.0, 98.0]: b.add("plant_bougainvillea_wall", "normal", 386.6, bv2, 90.0)  # on the D -> E wall face
	# ================= PIER ST: Pier Street Arcade, Tide Pool Books, Sunset Arcade (yaw 0, fronts at v 186) ==============
	var arc := b.bld("commercial/com_spanish_arcade_block", 349.5, 178.0, 0.0, "pier_street_arcade", 0.7)   # doors u 344.4 / 346.6 / 354.6
	b.add("prop_bike_rack", "worn", 350.6, 187.8, 0.0); b.add("prop_trash_receptacle", "worn", 339.0, 187.4, 0.0)
	b.add("plant_potted_leafy", "normal", 358.0, 186.6, 0.0)
	b.roof(arc, ["prop_ac_condenser", "prop_ac_condenser_compact", "prop_vent_box"])
	var bk := b.bld("commercial/com_shallow_books", 367.5, 183.0, 0.0, "tide_pool_books", 0.7)   # door u 365.5
	b.add("prop_park_bench", "worn", 368.8, 187.6, 0.0)                   # reading on the bench by the door
	var sun := b.bld("commercial/com_orange_arcade_block", 386.0, 177.5, 0.0, "sunset_arcade", 0.7)   # doors u 378.4 / 380.6 / 391.4 / 393.6
	b.add("prop_newspaper_box_red", "worn", 386.0, 187.4, 0.0); b.add("prop_trash_receptacle", "dirty", 375.0, 187.4, 0.0)
	b.add("prop_bike_rack", "worn", 397.0, 187.8, 0.0)
	b.roof(sun, ["prop_ac_condenser", "prop_ac_condenser", "prop_vent_box"])
	b.building_wear()

## ---------------------------------------------------------------- POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
## quarters, both indoors and outdoors ... plenty of props and life"). Every spot below is chosen by hand with its reason;
## try_add() only refuses a spot that turns out taken (counted and printed), it decides nothing.
func polish(b: F) -> void:
	var T := func(base: String, cond: String, pts: Array, yaw := 0.0, surf: Array = []) -> void:
		for p: Vector2 in pts: b.try_add(base, cond, p.x, p.y, yaw, surf)
	# the flats' decks and gardens, column C (east part), D and E: deck chairs, umbrellas, barbecues, flowers, showers
	T.call("prop_adirondack_wood", "worn", [Vector2(348.0, 44.0), Vector2(348.0, 46.0), Vector2(348.0, 132.0), Vector2(348.0, 134.0)], 90.0)
	T.call("prop_beach_umbrella", "worn", [Vector2(345.0, 36.0), Vector2(344.0, 80.0), Vector2(345.0, 146.0)])
	T.call("prop_beach_umbrella", "worn", [Vector2(378.0, 34.0), Vector2(378.0, 80.0), Vector2(377.0, 140.0)])
	T.call("prop_adirondack_white", "worn", [Vector2(382.0, 40.0), Vector2(382.0, 42.0), Vector2(382.0, 146.0), Vector2(382.0, 148.0)], 90.0)
	T.call("prop_bbq_kettle", "worn", [Vector2(371.0, 98.0), Vector2(338.0, 102.0)])
	T.call("prop_beach_shower", "worn", [Vector2(337.6, 70.0), Vector2(369.0, 128.0)])
	T.call("prop_ice_chest", "worn", [Vector2(374.0, 44.6), Vector2(341.0, 151.0)])
	T.call("plant_bougainvillea_mound", "normal", [Vector2(337.0, 22.0), Vector2(371.0, 20.0), Vector2(337.0, 122.0), Vector2(383.0, 120.0)])
	T.call("plant_bird_of_paradise", "normal", [Vector2(366.0, 24.0), Vector2(367.0, 72.0), Vector2(366.0, 132.0), Vector2(388.4, 20.0)])
	T.call("plant_iceplant_patch", "normal", [Vector2(344.0, 68.0), Vector2(376.0, 62.0), Vector2(376.0, 118.0)])
	T.call("prop_hose_reel_cart", "worn", [Vector2(353.6, 50.0), Vector2(353.6, 106.0)], 90.0)
	T.call("prop_kayak_rack", "worn", [Vector2(397.0, 44.0), Vector2(397.0, 104.0)])       # the holidaymakers' own boats
	# the Steps' landings: a fountain halfway, bins, flower pots, and the walk worn by feet
	T.call("prop_drinking_fountain", "worn", [Vector2(362.0, 103.4)], 180.0)
	T.call("prop_trash_receptacle", "worn", [Vector2(344.4, 103.4)])
	T.call("plant_potted_leafy", "normal", [Vector2(357.4, 108.6), Vector2(380.4, 108.6), Vector2(390.0, 108.6)])
	for k in 9: b.mark(14, Vector2(338.0 + k * 7.0, 106.0), 90.0, 1.4, 5.0, Color(1, 1, 1, 0.3))
	# Pier St: plants, papers, a bin at each door group, umbrellas in front of the outfitters, a bench for the arcade
	T.call("plant_potted_succulent", "normal", [Vector2(341.0, 186.8), Vector2(362.0, 186.8), Vector2(372.6, 186.8), Vector2(399.0, 186.8)])
	T.call("prop_newspaper_box_blue", "worn", [Vector2(356.4, 187.6)])
	T.call("prop_trash_receptacle", "worn", [Vector2(361.0, 187.6), Vector2(381.6, 187.4)])
	T.call("prop_beach_umbrella_closed", "worn", [Vector2(383.4, 186.8), Vector2(384.2, 186.6)])
	T.call("prop_park_bench", "worn", [Vector2(343.0, 187.8)], 0.0)
	# behind the shops: bins and gas bottles for the cafes
	for k in 3: b.try_add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "dirty", 340.0 + k * 0.8, 168.9, 0.0)
	for k in 3: b.try_add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "dirty", 376.0 + k * 0.8, 168.9, 0.0)
	T.call("prop_propane_cylinder_100lb", "rusty", [Vector2(395.0, 168.8), Vector2(395.6, 169.0)])
	b.sand_drift(335.0, 186.0, 400.0, 188.8, 5)
	b.polish_report()
