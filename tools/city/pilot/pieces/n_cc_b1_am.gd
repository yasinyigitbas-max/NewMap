extends SceneTree
## Piece n_cc_b1_am (city-centre fill, block 1, AMBER WALL; claude/fill-city-centre 19 Nov). Layout row (0, 6.0, -600),
## grid frame u = x, v = z - 600. Covers u -50..-16, v -790.3..-697.5: the Amber frontage north of the locked c_nw up
## to 6th St, and alley A behind it.
## LAND: flat. Land under it 5.97..6.10 m; every street edge round it (Amber walk, 6th St walk, the 6th St alley
## apron at u -50..-44) measured at 6.15 on the 19 Nov ground dump. One pad at walk level (6.15), flush on all sides.
## PLANNER: Amber is the centre's main street: the street wall continues c_nw's (built to the property line, shops on
## the ground floor, offices / flats over them). Amber x 6th is the centre's north gateway, a KEY CORNER: the office
## tower stands there (the address people give). Alley A (u -50..-44) carries c_nw's service alley on to 6th St, where
## the street piece already has its alley apron at exactly u -50..-44: delivery trucks come in from 6th, never from
## Amber. Between the building backs and the alley: the service yard every downtown block has (bins, meters, plant).
## ARCHITECT (Yasin 19 Nov: "add one very tall building to every block you make, alternative in between them"; block 1
## takes the 59 m glass tower, the next blocks alternate it with the 50 m condo tower): the glass tower on the corner,
## then a 4 m paved pocket exactly where Amber's bus shelter stands (passengers wait there, no shop door behind the
## shelter), a 4-storey brick corner block (a bank branch), a 3-storey brick row (deli, tailor, phone repair), a brick
## shop-and-flat with fire escapes (barber), and a brick corner building at the gap to c_nw (corner cafe). Heights step
## 59 / 13 / 10 / 10 / 10 m. EXTERIOR: planters at the doors, a bike rack parallel to the shopfronts, newspaper boxes at
## the tower door; the yard is worn hardest: oil, cracks, grime; the tower's bins and transformer stand in the bank's
## yard (the tower fills its lot to 2.5 m from the alley).
## Run with CCF_STAGE=ground first (ground only, checked against the land), then without. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b1_am")
	# ---- ground: one pad, the alley, the 1.4 m walk between the corner building and c_nw's cafe gap
	c.pad(-50.0, -190.3, -16.0, -97.5)
	c.paint("concrete", -44.0, -98.9, -16.0, -97.5)
	c.paint("plaza", -44.0, -165.9, -16.0, -161.7)          # the pocket by the bus stop
	c.build_floor(L.rect_edges(-50.0, -190.3, -16.0, -97.5))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_am_b040_a", Vector3(0, 6, -800), 0.0], ["j_am_6th", Vector3(0, 6, -800), 0.0], ["s_rs_b092_b", Vector3(0, 6, -800), -90.0],
		["c_nw", Vector3(0, 6, -600), 0.0], ["d_cc", Vector3(0, 6, -600), 0.0], ["s_am_fill_cc", Vector3(0, 6, -600), 180.0], ["s_cc_amber_n", Vector3(0, 6, -600), 0.0]], O)
	# ---- buildings on Amber (face east), stats facade on the property line u -16 as c_nw stands
	var T := c.bld("urban/twr_glass", Vector2(-16.0, -178.1), "e", true, "amber6_tower")
	# the pocket (v -765.9..-761.7) sits in front of Amber's bus shelter at v -764: no door behind the shelter
	var R4 := c.bld("urban/urb_brick_corner", Vector2(-16.0, -151.38), "e", true, "amber_bank")
	var R1 := c.bld("urban/urb_brick_row", Vector2(-16.0, -132.9), "e", true, "amber_deli_row")
	var R2 := c.bld("ck/ck_brk3_row2_fe", Vector2(-16.0, -117.48), "e", true, "amber_barber_fe")
	var R5 := c.bld("ck/ck_brk3_corner2", Vector2(-16.0, -105.06), "e", true, "amber_corner_cafe")
	var y := c.y0
	# ---- the street side (on Amber's 4.5 m walk: only things that stand against the front, the walk stays clear)
	for d: float in [-3.4, 3.4]:     # tower lobby (one door, centred): a big planter either side
		c.put("plant_potted_leafy", "normal", c.at(T, d, 12.6), 0.0, "tower lobby: planters at the doors")
	c.put("prop_newspaper_box_red", "worn", c.at(T, -6.6, 12.4), 90.0, "tower: papers where office staff walk in")
	c.put("prop_newspaper_box_blue", "worn", c.at(T, -7.4, 12.4), 90.0, "tower: papers where office staff walk in")
	for r: Dictionary in [R1, R2, R5]:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]:
				c.put("plant_potted_succulent", "normal", Vector3(dp.x + 0.4, y, dp.z + s * 1.08), 0.0, "shops: a pot either side of the door")
	c.put("prop_bike_rack", "worn", Vector3(-27.0, y, -162.4), 0.0, "pocket: bike rack along the bank's side wall, off the walk")
	c.put("prop_trash_receptacle", "worn", Vector3(-19.5, y, -165.2), 0.0, "pocket: a bin where people wait for the bus")
	c.put("plant_potted_leafy", "normal", Vector3(-42.0, y, -163.8), 0.0, "pocket: a planter closes it toward the yard")
	c.put("prop_bike_rack", "worn", c.at(R4, -6.0, 8.4), 90.0, "bank: bike rack parallel to the front")
	c.put("prop_trash_receptacle", "worn", c.at(R5, -5.6, 7.5), 90.0, "corner cafe: a bin by the door for cups")
	# ---- alley A and the service yard (wear first, then what stands there)
	W_alley(c)
	# tower: its 2.5 m strip on the alley carries only its meters and condensers; its bins and transformer stand in the
	# bank's yard (reached from alley A, as every bin here)
	c.services(T, -5.5, 3, false)
	c.put("prop_dumpster_3yd_green", "worn", Vector3(-42.6, y, -158.4), 90.0, "tower: office waste, collected from alley A")
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(-42.6, y, -155.4), 90.0, "tower: paper recycling")
	c.put("prop_transformer_substation", "worn", Vector3(-39.2, y, -144.6), 90.0, "tower: its transformer (wires run underground in the centre)")
	c.put("prop_bollard_steel", "worn", Vector3(-41.6, y, -146.8), 0.0, "protects the transformer from trucks turning")
	c.put("prop_bollard_steel", "worn", Vector3(-41.6, y, -142.4), 0.0, "protects the transformer from trucks turning")
	# deli (R1): kitchen waste, its owner's car in the yard (a stall), propane for the grill
	c.services(R1, 4.0, 2, false)
	c.put("prop_dumpster_3yd_green", "rusty", Vector3(-42.6, y, -138.0), 90.0, "deli: food waste, collected from the alley")
	c.put("prop_propane_cylinder_100lb", "worn", Vector3(-32.2, y, -130.0), 0.0, "deli: grill propane between the back doors")
	c.stalls.append([-38.0, -127.0, 90.0])
	c.oil(Vector2(-38.0, -127.0), 90.0)
	# R2: flats over the barber (apartment door): bin carts, meters, condensers
	c.services(R2, -2.0, 1, true)
	c.put("prop_hose_reel_cart", "worn", Vector3(-33.2, y, -117.5), 90.0, "tenants hose the yard down")
	# bank (R4): no food waste: its condensers, a camera-watched back door kept clear
	c.services(R4, -6.0, 2, false)
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(-42.6, y, -152.2), 90.0, "bank: paper recycling")
	# corner cafe (R5): grease, cups
	c.services(R5, 1.5, 1, false)
	c.put("prop_dumpster_3yd_green", "worn", Vector3(-42.6, y, -106.0), 90.0, "cafe: food waste")
	c.put("prop_recycling_receptacle", "worn", Vector3(-34.2, y, -101.4), 90.0, "cafe: bottles and cans by the back door")
	c.put("prop_storm_drain_grate", "worn", Vector3(-47.0, y + 0.005, -150.0), 0.0, "the alley drains to its middle", false)
	c.put("prop_manhole_cover", "worn", Vector3(-47.0, y + 0.005, -118.0), 0.0, "sewer under the alley", false)
	c.put("prop_manhole_cover", "worn", Vector3(-47.0, y + 0.005, -176.0), 0.0, "sewer under the alley", false)
	# ---- roofs: the plant every flat downtown roof carries (condensers, exhaust boxes over kitchens, vents)
	c.roof_plant(T, [[-6.0, -6.0, "prop_ac_condenser"], [0.0, -6.0, "prop_ac_condenser"], [6.0, -6.0, "prop_ac_condenser"], [-5.0, 5.0, "prop_vent_box"], [5.0, 5.0, "prop_vent_plumbing"], [0.0, 1.0, "prop_satellite_dish"]], "roof plant (tower)")
	c.roof_plant(R1, [[-6.0, -3.0, "prop_vent_box"], [-1.0, -4.0, "prop_ac_condenser"], [5.0, -3.0, "prop_ac_condenser"], [2.0, 2.0, "prop_vent_turbine"], [-5.0, 2.0, "prop_vent_plumbing"]], "roof plant (old brick: turbines, kitchen exhaust)")
	c.roof_plant(R2, [[-3.0, -3.0, "prop_ac_condenser_compact"], [2.5, -3.0, "prop_tv_antenna"], [0.0, 2.0, "prop_vent_plumbing"]], "roof plant (flats: aerial, compact AC)")
	c.roof_plant(R4, [[-5.0, -4.0, "prop_ac_condenser"], [-1.0, -4.0, "prop_ac_condenser"], [4.0, 0.0, "prop_vent_box"], [-4.0, 3.0, "prop_vent_turbine"]], "roof plant (bank)")
	c.roof_plant(R5, [[-2.0, -3.0, "prop_vent_box"], [2.5, -3.0, "prop_ac_condenser_compact"], [0.0, 2.0, "prop_tv_antenna"]], "roof plant (cafe kitchen exhaust, flat's aerial)")
	# ---- wear where it happens: people waiting at doors, the tower's taxi drop-off scuffs
	for r2: Dictionary in [T, R1, R2, R4, R5]:
		for dr2: Array in r2.doors:
			var q: Vector3 = dr2[1]
			c.grime(Vector2(q.x + 0.9, q.z), 90.0, 1.8, 1.4, 0.4)
	c.finish()
	quit()

## alley A: lane wear down the middle, cracks, a trench patch, grime along the walls; tyre arcs where trucks turn in
## from 6th St (asphalt, at the mouth) and oil where they idle while unloading
static func W_alley(c) -> void:
	c.cracks(-49.4, -189.0, -32.0, -99.0, 26, 0.5)
	var z := -188.0
	while z < -100.0:
		c.dec.add(6, Vector2(-47.0 + c.rr.randf_range(-0.3, 0.3), z), 0.0, 0.9, c.rr.randf_range(4.0, 6.5), c.yf, Color(1, 1, 1, c.rr.randf_range(0.35, 0.55)))
		c.grime(Vector2(-44.6, z + 2.0), 0.0, 1.0, 3.5, 0.5)
		z += c.rr.randf_range(7.0, 10.0)
	c.dec.add(2, Vector2(-47.0, -130.0), 90.0, 1.4, 6.0, c.yf, Color(1, 1, 1, 0.85))     # trench patch across the alley
	c.dec.add(3, Vector2(-46.5, -160.0), 0.0, 1.2, 9.0, c.yf, Color(1, 1, 1, 0.8))     # service line along it
	c.tyre(Vector2(-46.0, -187.0), 25.0, 5.0, 0.4); c.tyre(Vector2(-48.2, -186.5), 15.0, 5.0, 0.35)
	for zz: float in [-168.0, -147.0, -112.0]: c.oil(Vector2(-47.0, zz), 0.0, 0.8)
