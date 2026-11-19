extends SceneTree
## Piece n_wf_b2e (waterfront fill, block 2 EAST: grid u 400 to the ring's curve at u 605, with the corner by the marina
## north of the sample quadrant f_ne (locked, flat 1.50)).
## WHO COMES HERE AND WHY: the foot of the hill, where the town works the boats: Glorietta Marine Supply (the chandlery
## and boat storage, in from the street's driveway at u 554-560) and its yard, the boatyard below it with boats on
## trailers and a repair shed (the sample's boat storage yard is next door in f_ne), Harbour Boatworks townhouses with
## their garages off a yard on the north street (driveway u 440-446), the public lot at the bottom of the Steps for the
## flats and for Pier St, and on Pier St the boat & bike hire and the harbour tours ticket kiosk.
## THE GROUND: north street walk 6.0 -> 4.15 (flat 4.15 east of u 480), Pier St 2.7 -> 1.5, the ring 4.15 -> 1.5 round
##   the corner, f_ne 1.50. Land 4.8 -> 1.5. Pads: flats column E (with n_wf_b2m) 5.80 / 3.80 / 3.00; foot yard 4.00 and
##   lot 2.00; marina corner yard 3.90 and boatyard 2.00; Pier St pads 2.20 / 1.75 / 1.56. The Steps: E2 -> lot 11 risers.
## Run: GROUND_ONLY=1 for the ground alone (first check), then without. A draft until Yasin has seen it; never when locked.
const F := preload("res://tools/city/pilot/pieces/wf_fill_lib.gd")

func _init() -> void: _run.call_deferred()
func _run() -> void:
	var b := F.new("n_wf_b2e")
	ground(b)
	if OS.get_environment("GROUND_ONLY") == "1":
		b.finish(true); quit(); return
	life(b)
	b.finish()
	quit()

## terraces of the flats column E (u 386-412), written identically in n_wf_b2m (the seam at u 400 crosses them)
static func column_e(b: F) -> void:
	b.terrace(386.0, 11.2, 412.0, 50.0, 5.80, "wall", 0, "flats E1")
	b.terrace(386.0, 50.0, 412.0, 112.0, 3.80, "wall", 0, "flats E2")
	b.terrace(386.0, 112.0, 412.0, 168.0, 3.00, "wall", 0, "flats E3")

func ground(b: F) -> void:
	b.band = 2.0
	column_e(b)
	b.terrace(412.0, 11.2, 470.0, 60.0, 4.00, "wall", 0, "foot yard (townhouses)")
	b.terrace(412.0, 60.0, 468.0, 168.0, 2.00, "wall", 0, "public lot")
	b.terrace(470.0, 11.2, 600.0, 40.0, 3.90, "wall", 0, "marine supply yard")
	b.terrace(468.0, 40.0, 600.0, 98.0, 2.00, "wall", 0, "boatyard")
	b.terrace(401.0, 168.0, 412.0, 188.8, 2.70, "wall", 0, "pocket plaza")
	b.terrace(413.0, 168.0, 427.0, 188.8, 2.20, "wall", 0, "boat & bike hire")
	b.terrace(427.0, 168.0, 446.0, 188.8, 1.85, "wall", 0, "harbour tours kiosk + seating")
	b.terrace(446.0, 168.0, 468.0, 188.8, 1.56, "wall", 0, "lot's way out to Pier St (walk)")
	b.stairs(406.0, 104.0, 414.0, 108.0, "u", 3.80, 2.00)               # the Steps: E2 -> the lot
	b.ramp(440.0, 11.2, 446.0, 24.0, "v", 4.62, 4.00, true)             # the foot yard's drive off the street's apron
	b.ramp(446.5, 60.0, 452.5, 80.0, "v", 4.00, 2.00, true)             # down from the yard to the lot (10 %)
	b.ramp(554.0, 11.2, 560.0, 22.0, "v", 4.15, 3.90, true)             # the marine supply's drive
	b.ramp(530.5, 40.0, 536.5, 58.0, "v", 3.90, 2.00, true)             # down to the boatyard (10.6 %)
	b.paint(400.0, 9.2, 607.0, 11.2, "concrete"); b.paint(400.0, 186.0, 470.0, 190.8, "concrete")
	b.paint(400.0, 104.0, 414.0, 108.0, "plaza")
	b.paint(386.0, 11.2, 412.0, 168.0, "grass")
	b.paint(400.0, 168.0, 470.0, 188.8, "plaza")
	b.paint(470.0, 40.0, 607.0, 100.0, "gravel")                        # the boatyard

## ---------------------------------------------------------------- buildings, then props, each with its reason
func life(b: F) -> void:
	# ================= COLUMN E's east part (u 400-412): decks over the foot, railings on the 1.0-2.0 m drops ==========
	b.guard(400.0, 49.8, 411.8, 49.8, Vector2(0, -1)); b.guard(400.0, 111.8, 411.8, 111.8, Vector2(0, -1))
	b.guard(411.8, 11.6, 411.8, 49.8, Vector2(-1, 0)); b.guard(411.8, 59.9, 411.8, 103.8, Vector2(-1, 0)); b.guard(411.8, 108.2, 411.8, 167.6, Vector2(-1, 0))
	b.guard(400.0, 167.6, 411.8, 167.6, Vector2(0, -1))
	b.guard(411.8, 11.6, 400.0, 11.6, Vector2(0, -1))
	b.add("prop_adirondack_wood", "worn", 408.0, 30.0, 90.0); b.add("prop_adirondack_wood", "worn", 408.0, 32.0, 90.0)
	b.add("prop_patio_set_4", "worn", 406.0, 76.0, 0.0); b.add("prop_adirondack_white", "worn", 409.0, 88.0, 90.0)
	b.add("prop_adirondack_white", "worn", 408.6, 132.0, 90.0); b.add("prop_beach_shower", "worn", 405.0, 144.0, 0.0)
	b.add("prop_park_bench", "worn", 409.0, 103.4, 90.0)                  # the Steps' last landing, over the lot
	# ================= THE FOOT YARD (G1 4.00): two townhouse rows with garages, in from the street at u 440-446 ======
	var t1 := b.bld("apartments/apt_townhouse_cays", 425.0, 22.4, 0.0, "boatworks_row_west", 0.6)   # garages open south to the yard
	var t2 := b.bld("apartments/apt_townhouse_cays", 456.4, 22.4, 0.0, "boatworks_row_east", 0.6)
	b.guard(439.8, 11.6, 412.2, 11.6, Vector2(0, -1)); b.guard(469.8, 11.6, 446.2, 11.6, Vector2(0, -1))
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 435.6, 28.0 + k * 0.8, 90.0)
	for k in 3: b.add(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 466.8, 28.0 + k * 0.8, -90.0)
	b.stalls_u(414.0, 9, 54.5, -1.0)                                      # guest stalls along the yard's south edge, noses to the rail
	b.stalls_u(454.0, 5, 54.5, -1.0)
	b.guard(412.0, 59.8, 446.3, 59.8, Vector2(0, -1)); b.guard(452.7, 59.8, 469.8, 59.8, Vector2(0, -1)); b.guard(469.8, 59.8, 469.8, 40.0, Vector2(-1, 0))   # 2.0 m down to the lot
	b.add("prop_boat_trailer", "worn", 432.0, 34.0, 0.0)                  # a boat on its trailer in front of a garage
	b.add("prop_lot_light_pole", "worn", 443.0, 40.0, 0.0)
	b.tyre_path(443.0, 11.4, 443.0, 30.0); b.yard_wear(412.2, 27.6, 469.8, 54.5, 0.7)
	# ================= THE PUBLIC LOT (G2 2.00): at the bottom of the Steps, for the flats, Pier St and the marina =====
	b.stalls_u(414.0, 12, 80.0, -1.0)                                     # west of the ramp's foot
	b.stalls_u(414.0, 20, 87.0, 1.0); b.stalls_u(414.0, 20, 98.0, -1.0)
	b.stalls_u(414.0, 20, 109.0, 1.0); b.stalls_u(414.0, 20, 120.0, -1.0)
	b.stalls_u(414.0, 20, 131.0, 1.0)
	b.paint(412.2, 141.0, 468.0, 168.0, "grass")                          # a planted strip and the walk out to Pier St
	b.paint(446.0, 141.0, 452.0, 168.0, "concrete")
	b.stairs(446.0, 162.0, 452.0, 168.0, "v", 2.00, 1.56)                 # down to the walk-out on Pier St (3 risers)
	for t3: Array in [["palm_queen_a", 420.0, 150.0], ["tree_coral_a", 432.0, 152.0], ["palm_mexican_fan_a", 460.0, 150.0], ["tree_magnolia_b", 440.0, 160.0]]:
		b.add(String(t3[0]), "normal", float(t3[1]), float(t3[2]), float(t3[1]) * 3.0)
	for lp: Vector2 in [Vector2(430.0, 140.0), Vector2(458.0, 140.0), Vector2(466.6, 92.5)]: b.add("prop_lot_light_pole", "worn", lp.x, lp.y, 0.0)
	b.add("prop_pay_station", "worn", 452.6, 141.6, 0.0)                  # where people walk out to Pier St
	b.add("prop_trash_receptacle", "worn", 445.4, 141.6, 0.0)
	b.stall_wear(0.6); b.yard_wear(412.2, 60.0, 468.0, 141.0, 0.8)
	# ================= PIER ST: boat & bike hire, the harbour tours kiosk, the pocket plaza (yaw 0) =====================
	var hire := b.bld("commercial/com_shallow_surf", 420.0, 182.5, 0.0, "bay_boat_and_bike_hire", 0.8)   # door u 423.3
	b.add("prop_bike_rack", "worn", 416.6, 187.8, 0.0); b.add("prop_kayak_rack", "worn", 420.0, 176.6, 0.0)   # rental kayaks behind it
	var tours := b.bld("commercial/com_kiosk", 436.0, 183.0, 0.0, "harbour_tours_kiosk", 0.8, false)   # walk-up window, front kept clear
	for bx: float in [440.6, 443.4]: b.add("prop_park_bench", "worn", bx, 186.8, 180.0)            # waiting for the tour boat shuttle, facing the kiosk side
	b.add("prop_bench_bus_stop", "worn", 430.4, 187.4, 0.0)
	b.add("prop_trash_receptacle", "worn", 432.0, 177.4, 0.0)
	b.add("prop_lamp_victorian", "worn", 402.0, 187.6, 0.0); b.add("prop_park_bench", "worn", 406.0, 175.0, 0.0)
	b.stairs(402.0, 162.0, 408.0, 168.0, "v", 3.00, 2.70); b.paint(402.0, 162.0, 408.0, 168.0, "concrete")   # E3's cottages to the plaza
	b.add("plant_potted_leafy", "normal", 410.8, 186.6, 0.0)
	# ================= GLORIETTA MARINE SUPPLY (L1 3.90): chandlery and boat storage, in from the street at u 554-560 ==
	var ms := b.bld("industrial/ind_warehouse", 484.0, 26.0, 90.0, "glorietta_marine_supply", 0.8)   # front east to its yard
	b.roof(ms, ["prop_ac_condenser", "prop_vent_box", "prop_solar_panel_x3", "prop_solar_panel_x3"])
	b.stalls_u(500.0, 20, 18.0, -1.0)                                     # customers, noses to the street wall
	b.stalls_u(540.0, 5, 34.0, 1.0)
	for k in 4: b.add("prop_boat_trailer", "worn", 503.0 + k * 4.4, 32.0, 0.0)        # boats for sale on their trailers, in the yard
	b.add("prop_kayak_rack", "worn", 498.6, 24.0, 90.0)                   # kayaks for sale against its wall
	b.add("prop_propane_cylinder_100lb", "rusty", 497.0, 34.6, 0.0); b.add("prop_propane_cylinder_100lb", "rusty", 497.6, 35.2, 0.0)
	b.guard(553.8, 11.6, 470.2, 11.6, Vector2(0, -1)); b.guard(600.0, 11.6, 560.2, 11.6, Vector2(0, -1))
	b.guard(469.8, 39.8, 530.3, 39.8, Vector2(0, -1)); b.guard(536.7, 39.8, 590.4, 39.8, Vector2(0, -1))
	b.fence("iron", 600.0, 11.6, 592.4, 34.0); b.fence("iron", 592.4, 34.0, 590.4, 39.8)   # round the ring's corner to the yard's rail   # 1.9 m down to the boatyard
	b.add("prop_lot_light_pole", "worn", 528.0, 26.0, 0.0)
	b.tyre_path(557.0, 11.4, 557.0, 26.0); b.tyre_path(533.5, 40.0, 533.5, 58.0)
	b.yard_wear(498.0, 18.0, 590.0, 40.0, 0.8)
	# ================= THE BOATYARD (L2 2.00, gravel): boats on trailers and stands, the repair shed ===================
	var sh := b.bld("industrial/ind_repair", 480.0, 70.0, 90.0, "harbour_boatworks", 0.9)   # rollups face east into the yard
	b.roof(sh, ["prop_vent_box"])
	for row: float in [52.0, 64.0, 76.0]:
		for k in 6: b.add("prop_boat_trailer", "worn", 498.0 + k * 4.6, row, 0.0)        # bows to the aisles
	for k in 3: b.add("prop_boat_trailer", "worn", 544.0 + k * 4.6, 88.0, 180.0)
	b.add("prop_container_20ft_blue", "rusty", 500.0, 90.0, 90.0); b.add("prop_container_20ft_white", "dirty", 507.0, 90.0, 90.0)   # parts and engines
	b.add("prop_dumpster_3yd_green", "rusty", 490.0, 93.6, 90.0)
	b.add("prop_lifering_stand", "worn", 552.0, 78.0, 0.0)
	b.add("prop_lot_light_pole", "worn", 528.0, 70.0, 0.0)
	b.yard_wear(470.0, 40.0, 560.0, 98.0, 0.9)
	b.building_wear()
