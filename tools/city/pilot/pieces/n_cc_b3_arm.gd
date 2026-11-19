extends SceneTree
## Piece n_cc_b3_arm (city-centre fill, block 3, THE 7TH STREET ARM SOUTH SIDE; claude/fill-city-centre 19 Nov). Layout
## row (0, 6.0, -600), grid frame u = x, v = z - 600. Covers u 50..150, v -590.3..-500: between c_se (west, its alley
## at u 44..50) and the apartment sample a_sw (east), from 7th St to the block's main part, with alley D3.
## LAND: flat. Land 6.09..6.12; 7th St's south walk (s_rs_b099_fill: v -590.3, easing to -590.8 east of u 137, followed
## vertex by vertex), c_se's alley, a_sw's edge and lane: all 6.15. One pad at 6.15.
## PLANNER: the south side of 7th St's shopping run, facing block 2's department store: a brick corner (a newsagent and
## tobacconist by c_se's alley), a stucco block with a pizzeria under flats, a two-storey Spanish arcade of small shops
## (a cobbler, a phone shop, a travel agent) whose arcade is the street's shade, a brick row (a toy shop, a music shop,
## a watch repairer) and a brick shop-and-flat with fire escapes (a laundromat). Alley D3 (v -546..-540) carries a_sw's
## lane through to c_se's alley. Built up on both sides: a print shop and a pharmacy depot face it from the north, two
## workshops and walk-up flats from the south; behind them a residents' pergola garden.
## EXTERIOR: pots, racks, papers; the pocket at a_sw's corner; service yards; the garden (arbor, tables, trees).
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b3_arm")
	c.pad(50.0, 9.7, 150.0, 100.0)
	# 7th St's south walk edge eases from v -590.3 (u 137) to -590.8 (u 147.5): the street's own vertices, to the millimetre
	var tp := PackedVector2Array([Vector2(136.5, 9.7)])
	for e: Vector2 in [Vector2(137.000, 9.6902), Vector2(137.500, 9.6785), Vector2(138.000, 9.6630), Vector2(138.500, 9.6439), Vector2(139.000, 9.6219), Vector2(139.500, 9.5972), Vector2(140.000, 9.5704), Vector2(140.500, 9.5418), Vector2(141.000, 9.5119), Vector2(141.500, 9.4812), Vector2(142.000, 9.4500), Vector2(142.500, 9.4188), Vector2(143.000, 9.3881), Vector2(143.500, 9.3582), Vector2(144.000, 9.3296), Vector2(144.500, 9.3028), Vector2(145.000, 9.2781), Vector2(145.500, 9.2561), Vector2(146.000, 9.2370), Vector2(146.500, 9.2215), Vector2(147.000, 9.2098), Vector2(147.500, 9.2025), Vector2(148.000, 9.2000), Vector2(150.000, 9.2000), Vector2(150.000, 9.2000)]: tp.append(e)
	tp.append(Vector2(150.0, 9.7))
	c.edge_poly("concrete", tp)
	c.paint("plaza", 139.0, 9.7, 150.0, 21.0)               # the pocket at a_sw's corner
	c.paint("grass", 97.0, 62.0, 149.4, 99.4)               # the pergola garden
	c.paint("concrete", 97.0, 79.2, 149.4, 80.8)            # its path
	c.build_floor(L.rect_edges(50.0, 9.7, 150.0, 100.0))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["c_se", Vector3(0, 6, -600), 0.0], ["d_cc", Vector3(0, 6, -600), 0.0], ["a_sw", Vector3(250, 6, -600), 0.0], ["s_rs_b099_fill", Vector3(0, 6, -600), 90.0], ["s_cc_10th", Vector3(0, 6, -600), -180.0], ["s_apt", Vector3(250, 6, -600), -90.0]], O)
	var y := 0.15
	var S := c.row(["ck/ck_brk3_corner2", "apartments/apt_stucco3_peach", "commercial/com_spanish_arcade_block", "urban/urb_brick_row", "ck/ck_brk3_row2_fe"],
		["seventh_s_newsagent", "seventh_s_pizza_block", "seventh_s_arcade", "seventh_s_brick_row", "seventh_s_laundry_fe"], 50.1, 1.0, "n", 9.7)
	var DN := c.row(["modular/examples/mod_svc_row", "ck/ck_svc_bank_pharm"], ["alleyd3_print", "alleyd3_pharm_depot"], 58.0, 1.0, "s", 54.0)
	var DS := c.row(["ck/ck_svc_trade_1d", "modular/examples/mod_svc_row", "ck/ck_apt3_row3"], ["alleyd3_bike_works", "alleyd3_sign_shop", "alleyd3_walkup"], 50.1, 1.0, "n", 60.0)
	for r: Dictionary in S:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]: c.put("plant_potted_succulent", "normal", Vector3(dp.x + s * 1.08, y, dp.z - 0.4), 0.0, "shops: a pot either side of the door")
	c.put("prop_newspaper_box_red", "worn", Vector3(56.6, y, 10.3), 180.0, "newsagent: papers beside its door, off the door's way")
	c.put("prop_newspaper_box_blue", "worn", Vector3(55.8, y, 10.3), 180.0, "newsagent: papers beside its door, off the door's way")
	c.put("prop_bike_rack", "worn", Vector3(144.0, y, 12.6), 0.0, "pocket: bikes off the walk (laundromat, music shop)")
	c.put("prop_park_bench", "worn", Vector3(148.8, y, 16.0), -90.0, "pocket: a seat facing the street")
	c.put("prop_trash_receptacle", "worn", Vector3(148.8, y, 12.0), 0.0, "pocket: a bin at the corner")
	c.put("plant_potted_leafy", "normal", Vector3(148.8, y, 20.0), 0.0, "pocket: a planter closes it toward the yard")
	# ---- service sides, yards
	for r2: Dictionary in S + DS: c.services(r2, 4.0, 1, String(r2.folder).contains("brk3") or String(r2.folder).contains("stucco") or String(r2.folder).contains("apt"))
	c.services(DN[0], -4.0, 1, false)     # the print shop's meters clear of its back windows
	c.services(DN[1], 0.6, 1, false)
	c.put("prop_dumpster_3yd_green", "worn", Vector3(51.6, y, 33.0), 90.0, "pizzeria / newsagent: waste, collected from c_se's alley")
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(51.6, y, 36.0), 90.0, "shops: cardboard")
	c.put("prop_dumpster_3yd_green", "rusty", Vector3(130.0, y, 52.4), 0.0, "arcade and row shops: waste by alley D3")
	c.put("prop_propane_cylinder_100lb", "worn", Vector3(72.0, y, 27.4), 0.0, "pizzeria: oven propane by its back door")
	c.put("prop_transformer_substation", "worn", Vector3(114.0, y, 38.0), 0.0, "the arm's transformer (underground wires)")
	c.stalls.append([100.0, 40.0, 90.0]); c.oil(Vector2(100.0, 40.0), 90.0)
	c.cracks(51.0, 27.0, 149.0, 52.0, 18, 0.5)
	# ---- the pergola garden (for the walk-up flats and the shop flats): arbor over a table, trees, benches
	c.put("prop_garden_arbor", "worn", Vector3(122.0, y, 88.0), 0.0, "garden: the pergola, a shaded walk-through on the lawn")
	c.put("prop_picnic_table", "worn", Vector3(113.0, y, 88.0), 0.0, "garden: the residents' table beside the pergola")
	for t: Array in [[102.0, 68.0, "tree_jacaranda_b", 0.85], [144.0, 68.0, "tree_ficus_a", 0.85], [105.0, 94.0, "palm_queen_b", 1.0], [140.0, 95.0, "tree_magnolia_b", 0.85]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "garden: trees in the grass", true, float(t[3]))
	for b: Array in [[112.0, 77.6, 180.0], [132.0, 77.6, 180.0]]: c.put("prop_park_bench", "worn", Vector3(float(b[0]), y, float(b[1])), float(b[2]), "garden: bench on the path facing the lawn")
	c.put("prop_bbq_kettle", "worn", Vector3(127.0, y, 92.4), 0.0, "garden: the shared grill by the pergola")
	c.put("plant_bird_of_paradise", "normal", Vector3(98.4, y, 98.0), 0.0, "garden: planting in the corner")
	c.iron(Vector2(96.8, 60.6), Vector2(118.45, 60.6), "garden: iron fence on alley D3")
	c.put("fence_gate_wrought_iron", "worn", Vector3(119.0, y, 60.6), 0.0, "garden: its gate on alley D3", false)
	c.iron(Vector2(119.55, 60.6), Vector2(149.4, 60.6), "garden: iron fence on alley D3")
	c.iron(Vector2(149.4, 60.6), Vector2(149.4, 99.4), "garden: iron fence to the apartment sample's lawn")
	c.iron(Vector2(149.4, 99.4), Vector2(96.8, 99.4), "garden: iron fence below the north yards' retaining wall")
	c.iron(Vector2(96.8, 99.4), Vector2(96.8, 60.6), "garden: iron fence beside the walk-up's yard")
	# ---- alley D3
	c.alley_wear(50.0, 54.0, 150.0, 60.0, false)
	c.tyre(Vector2(52.5, 57.4), -60.0, 5.0, 0.4); c.tyre(Vector2(147.5, 57.0), 60.0, 5.0, 0.4)
	c.put("prop_storm_drain_grate", "worn", Vector3(90.0, y + 0.005, 57.0), 0.0, "alley D3 drains to its middle", false)
	for r4: Dictionary in S: c.roof_plant(r4, [[-4.0, -3.0, "prop_ac_condenser_compact"], [3.0, -3.0, "prop_vent_plumbing"], [0.0, 2.0, "prop_vent_turbine"]], "roof plant")
	for r5: Dictionary in DN + DS: c.roof_plant(r5, [[0.0, -2.0, "prop_ac_condenser_compact"]], "roof plant")
	for r6: Dictionary in S + DN + DS:
		for dr2: Array in r6.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
