extends SceneTree
## Piece n_cc_b2_n (city-centre fill, block 2, 6TH STREET ROW AND THE PLAY GARDEN; claude/fill-city-centre 19 Nov).
## Layout row (0, 6.0, -600), grid frame u = x, v = z - 600. Covers u 50..190, v -790.8..-740: the 6th St frontage
## between alley A2 and alley B2, the court behind it, the back row on alley C2, and alley C2 itself (v -746..-740).
## LAND: flat. Land 5.95..6.11 m; the 6th St walk (s_rs_b093_a/b: edge v -790.3, easing to -790.8 east of u 178 -
## the ground follows it vertex by vertex), both alley aprons and the neighbours at 6.15: one pad at 6.15, flush.
## PLANNER: the same daily-errand street as block 1's 6th St, across the junction: shops with flats over them, a
## continuous wall, corner shops at both alley mouths (a cafe on the west, a bar on the east where the apartment band's
## people walk in). The block's children live in these flats and the apartment band next door: the middle of the court
## is a fenced PLAY GARDEN (one gate, on alley C2), with seats where parents can watch, a shaded table, a fountain.
## The back row on alley C2: flats, a small upholstery workshop, a row of lock-ups (people in flats have no garages).
## ARCHITECT: 3-4 storeys of brick and stucco on 6th; 2-3 storeys on the alley. EXTERIOR: door pots, a paved pocket
## with a bench and racks at alley B2's mouth, the garden (bark pad with three play items, benches, a table under a
## sail, trees in the grass, lamps), bins by back doors, the alley worn.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b2_n")
	c.pad(50.0, -190.3, 190.0, -140.0)
	# 6th St's walk edge eases from v -790.3 (u 178) to -790.8 (u 188.5): the street's own vertices, to the millimetre
	var tp := PackedVector2Array([Vector2(178.0, -190.3)])
	for e: Vector2 in [Vector2(178.000, -190.3098), Vector2(178.500, -190.3215), Vector2(179.000, -190.3370), Vector2(179.500, -190.3561), Vector2(180.000, -190.3781), Vector2(180.500, -190.4028), Vector2(181.000, -190.4296), Vector2(181.500, -190.4582), Vector2(182.000, -190.4881), Vector2(182.500, -190.5188), Vector2(183.000, -190.5500), Vector2(183.500, -190.5812), Vector2(184.000, -190.6119), Vector2(184.500, -190.6418), Vector2(185.000, -190.6704), Vector2(185.500, -190.6972), Vector2(186.000, -190.7219), Vector2(186.500, -190.7439), Vector2(187.000, -190.7630), Vector2(187.500, -190.7785), Vector2(188.000, -190.7902), Vector2(188.500, -190.7975), Vector2(189.000, -190.8000), Vector2(190.000, -190.8000), Vector2(190.000, -190.3000)]: tp.append(e)
	c.edge_poly("plaza", tp)
	c.paint("plaza", 183.6, -190.3, 190.0, -180.0)            # the pocket at alley B2's mouth
	c.paint("mulch", 101.0, -166.0, 119.0, -153.0)            # the play pad, on bark
	c.paint("concrete", 109.6, -153.0, 111.4, -146.0)         # the path from the gate to the pad
	c.paint("grass", 87.0, -172.6, 134.8, -146.8)             # the garden
	c.build_floor(L.rect_edges(50.0, -190.3, 190.0, -140.0))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b093_a", Vector3(0, 6, -800), 90.0], ["s_rs_b093_b", Vector3(250, 6, -800), -90.0]], O)
	var y := c.y0
	# ---- the 6th St wall (faces north), real fronts on the property line
	var R := c.row(["ck/ck_brk3_corner2", "apartments/apt_stucco3_cream", "urban/urb_brick_row", "ck/ck_apt3_row3", "modular/examples/mod_brk_row", "apartments/apt_stucco3_peach", "ck/ck_brk3_row2", "ck/ck_brk3_corner2"],
		["sixth_e_corner_cafe", "sixth_e_thai_block", "sixth_e_brick_row", "sixth_e_walkup", "sixth_e_shop_row", "sixth_e_corner_store_block", "sixth_e_dentist", "sixth_e_corner_bar"], 50.1, 1.0, "n", -190.3)
	# ---- the back row on alley C2 (faces south), real fronts at v -746 (z -146)
	var BW := c.row(["ck/ck_apt3_row3", "modular/examples/mod_apt_row"], ["alleyc2_walkup", "alleyc2_apt_row"], 50.1, 1.0, "s", -146.0)
	var BE := c.row(["ck/ck_svc_trade", "ck/mod_stg_row_roofed"], ["alleyc2_upholstery", "alleyc2_lockups"], 135.1, 1.0, "s", -146.0)
	# ---- 6th St side: pots at the shop doors, the pocket at alley B2's mouth
	for r: Dictionary in R:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]: c.put("plant_potted_succulent", "normal", Vector3(dp.x + s * 1.08, y, dp.z - 0.4), 0.0, "shops: a pot either side of the door")
	c.put("prop_park_bench", "worn", Vector3(188.6, y, -185.0), -90.0, "pocket: a seat facing the corner bar and the street")
	c.put("prop_bike_rack", "worn", Vector3(185.0, y, -181.0), 0.0, "pocket: bikes off the walk")
	c.put("prop_trash_receptacle", "worn", Vector3(188.6, y, -188.4), 0.0, "pocket: a bin at the corner")
	c.put("plant_potted_leafy", "normal", Vector3(188.8, y, -181.2), 0.0, "pocket: a planter closes it toward the alley")
	# ---- service sides (backs into the court strip) and the back row's
	for r2: Dictionary in R: c.services(r2, 4.0, 1, String(r2.folder).contains("apt") or String(r2.folder).contains("stucco") or String(r2.folder).contains("brk3"))
	for r3: Dictionary in BW: c.services(r3, 4.0, 1, true)
	c.services(BE[0], 3.0, 0, false)     # no condenser: it would stand on the garden fence
	# service yard east of the lock-ups, off alley C2 and B2: the row's waste, a van
	c.put("prop_dumpster_3yd_green", "worn", Vector3(170.4, y, -147.6), 0.0, "6th St shops: waste by alley C2")
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(173.4, y, -147.6), 0.0, "6th St shops: cardboard")
	c.put("prop_dumpster_3yd_green", "rusty", Vector3(176.4, y, -147.6), 0.0, "corner bar: bottles and kitchen waste")
	c.put("prop_transformer_substation", "worn", Vector3(186.8, y, -152.0), 90.0, "the row's transformer (underground wires)")
	c.stalls.append([178.0, -160.0, 0.0]); c.oil(Vector2(178.0, -160.0), 0.0)
	c.put("prop_hose_reel_cart", "worn", Vector3(168.4, y, -166.0), 0.0, "staff hose the yard")
	c.put("prop_propane_cylinder_100lb", "worn", Vector3(57.0, y, -166.8), 0.0, "corner cafe: propane for its kitchen")
	# ---- the play garden (fenced, one gate on alley C2)
	c.put("prop_play_structure", "worn", Vector3(110.0, y, -160.4), 0.0, "garden: climbing frame on the bark pad")
	c.put("prop_slide", "worn", Vector3(104.6, y, -156.4), 90.0, "garden: slide on the bark pad")
	c.put("prop_swing_set", "worn", Vector3(115.6, y, -156.0), 90.0, "garden: swings on the bark pad")
	for b: Array in [[99.4, -161.0, 90.0], [120.6, -161.0, -90.0], [110.0, -169.4, 0.0]]:
		c.put("prop_park_bench", "worn", Vector3(float(b[0]), y, float(b[1])), float(b[2]), "garden: parents watch the play pad")
	c.put("prop_picnic_table", "worn", Vector3(127.6, y, -166.0), 0.0, "garden: table for birthdays and lunches")
	c.put("prop_shade_sail", "worn", Vector3(127.6, y, -166.0), 0.0, "garden: the sail over the table it shades", false)
	c.put("prop_drinking_fountain", "worn", Vector3(112.8, y, -147.8), 0.0, "garden: a fountain by the gate path")
	c.put("prop_trash_receptacle", "worn", Vector3(107.4, y, -147.8), 0.0, "garden: a bin by the gate")
	for lp: Vector2 in [Vector2(96.0, -150.0), Vector2(125.0, -150.0)]: c.put("prop_lamp_globe", "worn", Vector3(lp.x, y, lp.y), 0.0, "garden: lamps for winter evenings")
	for t: Array in [[92.0, -168.0, "tree_ficus_a", 0.9], [131.0, -153.0, "tree_jacaranda_b", 0.9], [91.0, -151.0, "tree_coral_b", 0.85], [128.0, -171.0, "tree_magnolia_a", 0.8]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "garden: shade trees in the grass", true, float(t[3]))
	c.put("plant_bird_of_paradise", "normal", Vector3(88.4, y, -160.0), 0.0, "garden: planting along the fence")
	c.put("plant_agave_americana_small", "normal", Vector3(133.4, y, -160.8), 0.0, "garden: planting along the fence")
	c.iron(Vector2(86.8, -146.6), Vector2(109.45, -146.6), "garden: iron fence on alley C2")
	c.put("fence_gate_wrought_iron", "worn", Vector3(110.0, y, -146.6), 0.0, "garden: its one gate, on alley C2", false)
	c.iron(Vector2(110.55, -146.6), Vector2(134.9, -146.6), "garden: iron fence on alley C2")
	c.iron(Vector2(86.8, -173.3), Vector2(86.8, -146.6), "garden: iron fence to the west strip")
	c.iron(Vector2(134.9, -173.4), Vector2(134.9, -146.6), "garden: iron fence to the east yard")
	for k in 4: c.grime(Vector2(104.0 + k * 4.0, -159.0), 0.0, 2.4, 2.4, 0.4)
	# ---- alley C2: wear, drains, tyre arcs where it meets A2 and B2
	c.alley_wear(50.0, -146.0, 190.0, -140.0, false)
	c.tyre(Vector2(52.5, -143.4), 60.0, 5.0, 0.4); c.tyre(Vector2(187.5, -143.0), -60.0, 5.0, 0.4)
	c.put("prop_storm_drain_grate", "worn", Vector3(120.0, y + 0.005, -143.0), 0.0, "alley C2 drains to its middle", false)
	c.put("prop_manhole_cover", "worn", Vector3(75.0, y + 0.005, -143.0), 0.0, "sewer under alley C2", false)
	c.cracks(51.0, -172.0, 86.0, -161.5, 6, 0.4); c.cracks(166.0, -172.0, 189.0, -147.0, 8, 0.5)
	# ---- roofs (pitched stucco and apartment-row roofs are refused by the flat test)
	for r4: Dictionary in R: c.roof_plant(r4, [[-4.0, -3.0, "prop_ac_condenser_compact"], [3.0, -3.0, "prop_vent_plumbing"], [0.0, 2.0, "prop_tv_antenna"]], "roof plant (shops and flats)")
	c.roof_plant(BE[0], [[-3.0, -2.0, "prop_vent_box"], [3.0, -2.0, "prop_ac_condenser"]], "roof plant (workshop)")
	for r5: Array in [R, BW, BE]:
		for r6: Dictionary in r5:
			for dr2: Array in r6.doors:
				var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
				c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
