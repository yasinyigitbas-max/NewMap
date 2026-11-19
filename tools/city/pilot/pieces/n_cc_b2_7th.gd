extends SceneTree
## Piece n_cc_b2_7th (city-centre fill, block 2, THE 7TH STREET ARM; claude/fill-city-centre 19 Nov). Layout row (0,
## 6.0, -600), grid frame u = x, v = z - 600. Covers u 50..150, v -700..-609.2: between c_ne (west, its alley at
## u 44..50) and the apartment sample a_nw (east), from the garage block down to 7th St, with alley D2 (v -660..-654).
## LAND: flat. Land 5.95..6.11 m; the 7th St walk (s_rs_b099_fill: edge v -609.7, easing to -609.2 east of u 137 - the
## ground follows it vertex by vertex), c_ne's alley and floor, the apartment sample's edge and lane: all 6.15.
## PLANNER: 7th St runs from the centre's core (Amber) to the apartment band: a shopping street. Its anchor is a
## DEPARTMENT STORE (the centre's second; people walk to it from the block's garage along a public walk through the
## block, then a passage to 7th St). Beside it: a corner insurance office by c_ne's alley, a burger place under flats,
## a brick row (sports shop, hardware, a gallery). Alley D2 links c_ne's alley with the apartment sample's lane, so
## the department store's trucks load behind it and leave without reversing. North of D2: flats facing the alley and
## a small garden; south of D2: three workshops face the alley (a pawn shop, a locksmith, a tailor).
## ARCHITECT: 4-storey brick corner, 4-storey stucco, 3-storey brick row, the 10.5 m department store; 2-3 storeys on
## the alley. EXTERIOR: pots at doors, racks along the fronts, the walk (lamps, trees in the grass beside it),
## the loading yard (rolloff, dumpsters, a delivery truck's stall, oil), bins by back doors, the alleys worn.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b2_7th")
	c.pad(50.0, -100.0, 150.0, -9.7)
	# 7th St's walk edge eases from v -609.7 (u 137) to -609.2 (u 147.5) (measured)
	var tp := PackedVector2Array([Vector2(136.5, -9.7)])
	for e: Vector2 in [Vector2(137.000, -9.6902), Vector2(137.500, -9.6785), Vector2(138.000, -9.6630), Vector2(138.500, -9.6439), Vector2(139.000, -9.6219), Vector2(139.500, -9.5972), Vector2(140.000, -9.5704), Vector2(140.500, -9.5418), Vector2(141.000, -9.5119), Vector2(141.500, -9.4812), Vector2(142.000, -9.4500), Vector2(142.500, -9.4188), Vector2(143.000, -9.3881), Vector2(143.500, -9.3582), Vector2(144.000, -9.3296), Vector2(144.500, -9.3028), Vector2(145.000, -9.2781), Vector2(145.500, -9.2561), Vector2(146.000, -9.2370), Vector2(146.500, -9.2215), Vector2(147.000, -9.2098), Vector2(147.500, -9.2025), Vector2(148.000, -9.2000), Vector2(150.000, -9.2000), Vector2(150.000, -9.2000), Vector2(150.000, -9.7000)]: tp.append(e)
	c.edge_poly("concrete", tp)
	c.paint("plaza", 108.6, -100.0, 112.4, -60.0)            # the public walk from the garage to alley D2
	c.paint("plaza", 108.6, -54.0, 112.4, -9.7)              # and the passage on to 7th St
	c.paint("grass", 88.6, -99.0, 108.0, -63.0)              # garden west of the walk
	c.paint("grass", 50.6, -100.0, 86.6, -76.0)              # the court behind the west flats (continues the one north of it)
	c.paint("grass", 113.0, -100.0, 143.6, -76.0)            # the court behind the east flats
	c.paint("grass", 143.8, -99.0, 149.4, -63.0)             # garden east of the flats
	c.build_floor(L.rect_edges(50.0, -100.0, 150.0, -9.7))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["c_ne", Vector3(0, 6, -600), 0.0], ["d_cc", Vector3(0, 6, -600), 0.0], ["a_nw", Vector3(250, 6, -600), 0.0], ["s_rs_b099_fill", Vector3(0, 6, -600), 90.0], ["s_cc_10th", Vector3(0, 6, -600), -180.0], ["s_apt", Vector3(250, 6, -600), -90.0]], O)
	var y := c.y0
	# ---- 7th St row (faces south), real fronts on the property line v -609.7 (z -9.7); the passage at u 108.6..112.4
	var S := c.row(["urban/urb_brick_corner", "apartments/apt_stucco3_cream", "modular/examples/mod_brk_row"], ["seventh_insurance", "seventh_burger_block", "seventh_brick_row"], 50.1, 1.0, "s", -9.7)
	var DS := c.bld("urban/urb_dept_store", Vector2(130.6, -9.7), "s", false, "seventh_dept_store")
	# ---- alley D2, its south side: three workshops facing it (front at v -654 -> z -54); north side: flats (front z -60)
	var WS := c.row(["modular/examples/mod_svc_row", "ck/ck_svc_pawn_fast", "ck/ck_svc_trade_1d"], ["alleyd2_tailor", "alleyd2_pawn", "alleyd2_locksmith"], 50.1, 1.0, "n", -54.0)
	var FN := c.row(["ck/ck_apt3_row3", "modular/examples/mod_apt_row"], ["alleyd2_walkup_w", "alleyd2_apt_row"], 50.1, 1.0, "s", -60.0)
	var FE := c.row(["ck/ck_apt3_row3", "ck/ck_apt3_row2"], ["alleyd2_walkup_e", "alleyd2_walkup_e2"], 113.0, 1.0, "s", -60.0)
	# ---- 7th St side: pots, racks, papers
	for r: Dictionary in S + [DS]:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]: c.put("plant_potted_succulent", "normal", Vector3(dp.x + s * 1.08, y, dp.z + 0.4), 0.0, "shops: a pot either side of the door")
	c.put("prop_bike_rack", "worn", Vector3(98.1, y, -10.4), 0.0, "brick row: bikes parallel to the fronts (sports shop)")
	c.put("prop_bike_rack", "worn", Vector3(144.0, y, -10.6), 0.0, "department store: bikes parallel to the front")
	c.put("prop_newspaper_box_red", "worn", Vector3(113.6, y, -10.4), 0.0, "passage mouth: papers where people come through")
	c.put("prop_newspaper_box_blue", "worn", Vector3(114.4, y, -10.4), 0.0, "passage mouth: papers where people come through")
	# ---- the walk and the passage
	for lp: Vector2 in [Vector2(108.2, -90.0), Vector2(112.8, -72.0), Vector2(108.2, -40.0)]:
		c.put("prop_lamp_globe", "worn", Vector3(lp.x, y, lp.y), 0.0, "walk: lit at night (people go to the garage after dark)")
	c.put("prop_trash_receptacle", "worn", Vector3(108.3, y, -62.0), 0.0, "walk: a bin where it crosses the alley")
	# ---- gardens north of D2 (for the flats): lawn, trees, a bench, washing
	for t: Array in [[94.0, -90.0, "tree_magnolia_b", 0.85], [103.0, -70.0, "tree_ficus_b", 0.85], [146.6, -88.0, "tree_jacaranda_a", 0.85], [147.0, -76.0, "palm_queen_a", 0.95]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "gardens: trees in the grass", true, float(t[3]))
	c.put("prop_park_bench", "worn", Vector3(106.6, y, -82.0), -90.0, "garden: a bench by the walk, facing the lawn")
	c.put("prop_clothesline", "worn", Vector3(96.0, y, -76.0), 90.0, "garden: washing for the flats")
	c.put("prop_picnic_table", "worn", Vector3(128.0, y, -90.0), 90.0, "east court: the flats' table")
	for t3: Array in [[60.0, -92.0, "tree_jacaranda_b", 0.85], [78.0, -86.0, "tree_magnolia_b", 0.8], [120.0, -84.0, "tree_coral_b", 0.85]]:
		c.put(String(t3[2]), "normal", Vector3(float(t3[0]), y, float(t3[1])), c.rr.randf_range(0, 360), "courts: trees in the flats' lawns", true, float(t3[3]))
	c.put("prop_clothesline", "worn", Vector3(68.0, y, -96.0), 0.0, "west court: washing for the flats")
	# (the two gardens are left open: the west one is a small public green beside the walk, the east one runs into the
	# apartment sample's lawn; a fence along the alley would end in the open)
	# ---- service sides, the loading yard behind the department store
	for r2: Dictionary in S + FN + FE: c.services(r2, 4.0, 1, String(r2.folder).contains("apt") or String(r2.folder).contains("stucco"))
	for r2b: Dictionary in WS: c.services(r2b, 0.6, 1, false)     # the workshops' small back windows are further out
	c.services(DS, -10.0, 3, false)
	c.put("prop_dumpster_rolloff_20yd", "worn", Vector3(146.4, y, -46.0), 0.0, "department store: the rolloff for packaging")
	c.put("prop_dumpster_3yd_green", "worn", Vector3(116.0, y, -52.6), 0.0, "department store: waste")
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(119.0, y, -52.6), 0.0, "department store: cardboard")
	c.stalls.append([132.0, -46.0, 90.0]); c.oil(Vector2(132.0, -46.0), 90.0, 0.8)     # the delivery truck at the dock
	c.put("prop_dumpster_3yd_green", "rusty", Vector3(51.6, y, -33.0), 90.0, "burger place / insurance: waste, collected from c_ne's alley")
	c.put("prop_transformer_substation", "worn", Vector3(104.0, y, -37.0), 0.0, "the arm's transformer (underground wires)")
	c.cracks(51.0, -40.0, 108.0, -27.0, 10, 0.5); c.cracks(113.0, -52.0, 149.0, -36.0, 10, 0.5)
	# ---- alley D2
	c.alley_wear(50.0, -60.0, 150.0, -54.0, false)
	c.tyre(Vector2(52.5, -57.4), 60.0, 5.0, 0.4); c.tyre(Vector2(147.5, -57.0), -60.0, 5.0, 0.4)
	c.put("prop_storm_drain_grate", "worn", Vector3(80.0, y + 0.005, -57.0), 0.0, "alley D2 drains to its middle", false)
	c.roof_plant(S[0], [[-5.0, -4.0, "prop_ac_condenser"], [0.0, -4.0, "prop_vent_box"], [5.0, -4.0, "prop_ac_condenser"]], "roof plant (corner block)")
	c.roof_plant(S[2], [[-6.0, -3.0, "prop_vent_box"], [0.0, -3.0, "prop_ac_condenser"], [6.0, -3.0, "prop_ac_condenser_compact"]], "roof plant (brick row)")
	c.roof_plant(DS, [[-12.0, -6.0, "prop_ac_condenser"], [-6.0, -6.0, "prop_ac_condenser"], [0.0, -6.0, "prop_ac_condenser"], [6.0, -6.0, "prop_ac_condenser"], [12.0, -6.0, "prop_vent_box"], [-8.0, 4.0, "prop_solar_panel_x3"], [0.0, 4.0, "prop_solar_panel_x3"], [8.0, 4.0, "prop_solar_panel_x3"]], "roof plant (department store: HVAC, solar)")
	for r3: Dictionary in WS: c.roof_plant(r3, [[0.0, -2.0, "prop_ac_condenser_compact"]], "roof plant (workshops)")
	for r4: Dictionary in S + [DS] + WS + FN + FE:
		for dr2: Array in r4.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
