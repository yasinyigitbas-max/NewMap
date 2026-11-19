extends SceneTree
## Piece n_cc_b2_s (city-centre fill, block 2, ALLEY C2 SOUTH SIDE AND THE GARAGE; claude/fill-city-centre 19 Nov).
## Layout row (0, 6.0, -600), grid frame u = x, v = z - 600. Covers u 50..190, v -740..-700: the south side of alley C2,
## between alley A2 / c_ne's alley (u 50) and alley B2 (u 190), north of the arm and of the apartment sample.
## LAND: flat. Land 5.95..6.11 m; every neighbouring surface at 6.15: one pad at 6.15.
## PLANNER: block 2 has no parking lane round it and no open lots: its cars go in a GARAGE on alley C2 (entered from 6th
## St or B Ave down the alleys), which also serves 7th St's department store and the apartment band; a walk from its
## back door runs south through the arm to 7th St. Either side of it the alley is built up: an architects' office and
## walk-up flats on the west, flats on the east, a small residents' yard by alley B2.
## ARCHITECT: garage 14 m; 3-storey brick and apartment rows on the alley. EXTERIOR: the garage mouth (pay station,
## bollards, no-stopping sign, tyre marks and oil on the asphalt), bins by back doors, the yard (trees, a bench, bins).
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b2_s")
	c.pad(50.0, -140.0, 190.0, -100.0)
	c.paint("plaza", 82.0, -107.6, 120.0, -100.0)            # the garage walk behind the garage
	c.paint("grass", 153.0, -138.6, 189.4, -101.0)           # the residents' yard by alley B2
	c.paint("grass", 50.6, -122.6, 81.0, -100.0)             # the court behind the west rows (was bare asphalt: read as a lot)
	c.paint("grass", 120.6, -122.6, 151.0, -100.0)           # the court behind the east rows
	c.build_floor(L.rect_edges(50.0, -140.0, 190.0, -100.0))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["a_nw", Vector3(250, 6, -600), 0.0], ["c_ne", Vector3(0, 6, -600), 0.0]], O)
	var y := c.y0
	var W := c.row(["ck/ck_brk3_row2", "ck/ck_apt3_row3"], ["alleyc2s_architects", "alleyc2s_walkup"], 50.1, 1.0, "n", -140.0)
	var G := c.bld("extras/ext_parking_garage", Vector2(100.5, -139.0), "n", false, "block2_garage")
	var E := c.row(["modular/examples/mod_apt_row", "ck/ck_apt3_row2"], ["alleyc2s_apt_row", "alleyc2s_walkup_e"], 120.4, 1.0, "n", -140.0)
	# ---- garage mouth
	c.put("prop_pay_station", "worn", Vector3(108.6, y, -139.5), 180.0, "garage: pay station by the way out on foot")
	for bx: float in [95.3, 105.7]: c.put("prop_bollard_concrete", "worn", Vector3(bx, y, -139.5), 0.0, "garage: bollards guard the door frame")
	c.put("prop_sign_no_parking", "worn", Vector3(110.6, y, -139.6), 180.0, "garage: no stopping in front of the gate")
	for k in 3: c.tyre(Vector2(99.0 + k * 1.6, -139.5), 10.0 - k * 10.0, 3.0, 0.4)
	c.oil(Vector2(100.5, -139.5), 0.0, 0.6)
	c.services(G, -12.0, 2, false, "left")
	# ---- the garage walk (people from the garage to 7th St and the apartment band)
	for bx2: float in [86.0, 91.0]: c.put("prop_bike_rack", "worn", Vector3(bx2, y, -101.0), 0.0, "garage walk: bikes along the edge")
	c.put("prop_lamp_globe", "worn", Vector3(84.0, y, -104.0), 0.0, "garage walk: lit at night")
	c.put("prop_lamp_globe", "worn", Vector3(117.0, y, -104.0), 0.0, "garage walk: lit at night")
	c.put("prop_trash_receptacle", "worn", Vector3(119.0, y, -101.0), 0.0, "garage walk: a bin")
	# ---- service sides and the residents' yard
	for r: Dictionary in W + E: c.services(r, 4.0, 1, String(r.folder).contains("apt"))
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(51.6, y, -112.0), 90.0, "architects: paper, collected from c_ne's alley")
	for t: Array in [[160.0, -132.0, "tree_ficus_a", 0.9], [178.0, -112.0, "tree_jacaranda_b", 0.9], [184.0, -133.0, "palm_queen_a", 1.0]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "yard: shade trees in the grass", true, float(t[3]))
	c.put("prop_park_bench", "worn", Vector3(170.0, y, -103.0), 180.0, "yard: a bench facing the lawn")
	c.put("prop_picnic_table", "worn", Vector3(168.0, y, -124.0), 90.0, "yard: residents' table")
	c.put("prop_clothesline", "worn", Vector3(176.0, y, -122.0), 90.0, "yard: washing")
	c.iron(Vector2(151.1, -139.4), Vector2(189.4, -139.4), "yard: iron fence on alley C2")
	c.iron(Vector2(151.1, -124.6), Vector2(151.1, -100.4), "yard: iron fence behind the flats")
	c.iron(Vector2(151.1, -100.4), Vector2(189.4, -100.4), "yard: iron fence to the apartment sample's lawn")
	c.iron(Vector2(189.4, -139.4), Vector2(189.4, -126.6), "yard: iron fence on alley B2")
	c.put("fence_gate_wrought_iron", "worn", Vector3(189.4, y, -126.05), 90.0, "yard: the residents' gate", false)
	c.iron(Vector2(189.4, -125.5), Vector2(189.4, -100.4), "yard: iron fence on alley B2")
	for t2: Array in [[58.0, -106.0, "tree_magnolia_a", 0.85], [74.0, -110.0, "tree_coral_a", 0.85], [128.0, -106.0, "tree_ficus_a", 0.85], [144.0, -112.0, "palm_queen_b", 1.0]]:
		c.put(String(t2[2]), "normal", Vector3(float(t2[0]), y, float(t2[1])), c.rr.randf_range(0, 360), "courts: trees in the flats' lawns", true, float(t2[3]))
	c.put("prop_park_bench", "worn", Vector3(66.0, y, -101.2), 0.0, "west court: a bench facing the lawn")
	c.put("prop_park_bench", "worn", Vector3(136.0, y, -101.2), 0.0, "east court: a bench facing the lawn")
	c.put("prop_clothesline", "worn", Vector3(136.0, y, -116.0), 0.0, "east court: washing for the flats")
	c.roof_plant(G, [[-14.0, -12.0, "prop_vent_box"], [14.0, -12.0, "prop_vent_box"]], "garage: stair-tower exhaust")
	c.roof_plant(W[0], [[-3.0, -3.0, "prop_ac_condenser_compact"], [3.0, -3.0, "prop_vent_plumbing"], [0.0, 2.0, "prop_vent_turbine"]], "roof plant (brick offices)")
	for r2: Dictionary in W + E + [G]:
		for dr2: Array in r2.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
