extends SceneTree
## Piece n_cc_b2_e (city-centre fill, block 2, B AVE SIDE; claude/fill-city-centre 19 Nov). Layout row (0, 6.0, -600),
## grid frame u = x, v = z - 600. Covers u 190..240.8, v -790.8..-700: alley B2 (the apartment sample's lane carried on
## to the 6th St apron at u 190..196), the 6th St x B Ave corner, the B Ave frontage, and alley C2's east end (from the
## B Ave apron at v -746..-740).
## LAND: flat. Land 5.95..6.11 m; the 6th St walk (edge v -790.8 here), the B Ave walk (s_apt, edge u 240.8), both
## aprons and the apartment sample's edge (v -700) at 6.15: one pad at 6.15, flush.
## PLANNER: B Ave is the apartment band's street: the centre steps down to it. The 6th x B Ave corner keeps a 4-storey
## brick corner block (a restaurant on the ground floor, the corner people meet at); beside it a beach-style condo with
## an ice cream shop. Along B Ave: walk-up flats and Spanish-style garden apartments, each group round its own small
## garden (washing, a bench, bins by the back door). Alley B2 brings the apartment band's service lane to 6th St.
## ARCHITECT: 13.5 m corner, 10.7 m condo, 10 m walk-ups, 7.7 m Spanish garden flats: the height falls toward the band.
## EXTERIOR: pots at shop doors, a paved pocket at alley B2's mouth, the gardens, bins, the alleys worn.
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b2_e")
	c.pad(190.0, -190.8, 240.8, -100.0)
	c.paint("plaza", 196.0, -190.8, 203.0, -180.5)          # the pocket at alley B2's east side
	c.paint("grass", 197.0, -171.0, 225.0, -147.0)          # the corner flats' garden
	c.paint("grass", 197.0, -139.0, 226.5, -101.0)          # the B Ave garden flats' garden
	c.build_floor(L.rect_edges(190.0, -190.8, 240.8, -100.0))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b093_b", Vector3(250, 6, -800), -90.0], ["j_rs_3l1r_c", Vector3(250, 6, -800), -90.0], ["s_apt", Vector3(250, 6, -800), 0.0],
		["a_nw", Vector3(250, 6, -600), 0.0], ["s_apt", Vector3(250, 6, -600), -180.0]], O)
	var y := c.y0
	# ---- the 6th St corner (faces north), from the B Ave corner westward
	var N := c.row(["urban/urb_brick_corner", "apartments/apt_beach_condo"], ["sixth_bave_corner", "sixth_bave_condo"], 240.7, -1.0, "n", -190.8)
	# ---- B Ave (faces east), real fronts on u 240.8: behind the corner block to alley C2, then south of it to v -700
	var BA := c.row(["ck/ck_apt3_row3"], ["bave_walkup_n"], -171.8, 1.0, "e", 240.8)
	var BS := c.row(["apartments/apt_spanish_revival", "ck/ck_apt3_row2"], ["bave_spanish_flats", "bave_walkup_s"], -139.9, 1.0, "e", 240.8)
	for r: Dictionary in N:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]: c.put("plant_potted_succulent", "normal", Vector3(dp.x + s * 1.08, y, dp.z - 0.4), 0.0, "shops: a pot either side of the door")
	c.put("prop_bike_rack", "worn", Vector3(199.5, y, -183.0), 0.0, "pocket: bikes off the walk (ice cream customers)")
	c.put("prop_park_bench", "worn", Vector3(197.2, y, -186.0), 90.0, "pocket: a seat facing the condo's ice cream window")
	c.put("prop_trash_receptacle", "worn", Vector3(197.2, y, -189.2), 0.0, "pocket: a bin by the corner")
	# ---- service sides
	for r2: Dictionary in N + BA + BS: c.services(r2, 4.0, 1, not String(r2.folder).contains("corner"))
	c.put("prop_dumpster_3yd_green", "worn", Vector3(198.6, y, -178.5), 0.0, "corner restaurant: kitchen waste and cardboard, by its back corner, collected from alley B2")
	c.put("prop_propane_cylinder_100lb", "worn", Vector3(218.6, y, -171.6), 0.0, "corner restaurant: propane for the kitchen")
	# ---- the corner flats' garden and the garden flats' garden: lawn, a bench, washing, trees
	for t: Array in [[203.0, -165.0, "tree_jacaranda_a", 0.85], [219.0, -151.0, "tree_ficus_b", 0.85], [205.0, -110.0, "tree_magnolia_a", 0.9], [222.0, -128.0, "tree_coral_a", 0.85], [201.0, -133.0, "palm_queen_b", 1.0]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "gardens: trees in the grass", true, float(t[3]))
	c.put("prop_park_bench", "worn", Vector3(211.0, y, -149.0), 180.0, "corner garden: a bench facing the lawn")
	c.put("prop_clothesline", "worn", Vector3(212.0, y, -160.0), 0.0, "corner garden: washing in the sun")
	c.put("prop_clothesline", "worn", Vector3(212.0, y, -118.0), 0.0, "garden flats: washing in the sun")
	c.put("prop_picnic_table", "worn", Vector3(210.0, y, -106.0), 0.0, "garden flats: the residents' table")
	c.put("prop_bbq_kettle", "worn", Vector3(214.0, y, -104.6), 0.0, "garden flats: the shared grill by the table")
	c.put("prop_park_bench", "worn", Vector3(199.2, y, -122.0), 90.0, "garden flats: a bench facing the lawn")
	c.put("plant_bird_of_paradise", "normal", Vector3(199.0, y, -103.0), 0.0, "garden flats: planting in the corner")
	# gardens closed to the alleys: iron with a gate each
	c.iron(Vector2(196.6, -176.3), Vector2(201.1, -176.3), "corner garden: iron fence to the condo's back corner")
	c.iron(Vector2(196.6, -176.3), Vector2(196.6, -158.6), "corner garden: iron fence on alley B2")
	c.put("fence_gate_wrought_iron", "worn", Vector3(196.6, y, -158.05), 90.0, "corner garden: the residents' gate", false)
	c.iron(Vector2(196.6, -157.5), Vector2(196.6, -146.6), "corner garden: iron fence on alley B2")
	c.iron(Vector2(196.6, -146.6), Vector2(240.4, -146.6), "corner garden: iron fence on alley C2, to B Ave")
	c.iron(Vector2(240.4, -146.6), Vector2(240.4, -153.5), "corner garden: iron fence to B Ave, beside the walk-up")
	c.iron(Vector2(196.6, -139.4), Vector2(227.9, -139.4), "garden flats: iron fence on alley C2, to the Spanish flats' back")
	c.iron(Vector2(196.6, -139.4), Vector2(196.6, -121.6), "garden flats: iron fence on alley B2")
	c.put("fence_gate_wrought_iron", "worn", Vector3(196.6, y, -121.05), 90.0, "garden flats: the residents' gate", false)
	c.iron(Vector2(196.6, -120.5), Vector2(196.6, -100.4), "garden flats: iron fence on alley B2")
	c.iron(Vector2(196.6, -100.4), Vector2(240.4, -100.4), "garden flats: iron fence to the apartment sample's lawn")
	c.iron(Vector2(240.4, -100.4), Vector2(240.4, -108.2), "garden flats: iron fence to B Ave, beside the walk-up")
	# ---- alleys B2 and C2: wear, a drain, tyre arcs at the mouths and the crossing
	c.alley_wear(190.0, -190.3, 196.0, -100.0, true)
	c.alley_wear(196.0, -146.0, 240.8, -140.0, false)
	c.tyre(Vector2(193.0, -187.6), 20.0, 5.0, 0.4); c.tyre(Vector2(237.5, -143.0), 70.0, 5.0, 0.4); c.tyre(Vector2(194.0, -142.0), 45.0, 5.0, 0.35)
	c.put("prop_manhole_cover", "worn", Vector3(193.0, y + 0.005, -160.0), 0.0, "sewer under alley B2", false)
	c.put("prop_storm_drain_grate", "worn", Vector3(193.0, y + 0.005, -118.0), 0.0, "alley B2 drains to its middle", false)
	c.roof_plant(N[0], [[-5.0, -4.0, "prop_ac_condenser"], [0.0, -4.0, "prop_vent_box"], [5.0, -4.0, "prop_ac_condenser"], [-3.0, 3.0, "prop_vent_turbine"]], "roof plant (corner restaurant)")
	for r3: Dictionary in BA + BS: c.roof_plant(r3, [[-3.0, 0.0, "prop_tv_antenna"], [3.0, 0.0, "prop_vent_plumbing"]], "roof plant (flats)")
	for r4: Dictionary in N + BA + BS:
		for dr2: Array in r4.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
