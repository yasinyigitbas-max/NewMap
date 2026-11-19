extends SceneTree
## Piece n_cc_b1_n (city-centre fill, block 1, 6TH STREET ROW; claude/fill-city-centre 19 Nov). Layout row (0, 6.0, -600),
## grid frame u = x, v = z - 600. Covers u -140..-50, v -790.3..-740: the 6th St frontage between alley B and alley A,
## its residents' court, the back row on alley C, and alley C itself (v -746..-740) from alley B to alley A.
## LAND: flat. Land 5.97..6.10 m, the 6th St walk and both alley aprons measured at 6.15: one pad at 6.15, flush.
## PLANNER: 6th St is a quieter cross street of the centre: people LIVE here, over the shops, two minutes from Amber.
## A continuous 3-storey wall of shops with flats over them (no gaps on the street); the back row faces alley C (people
## live over the service lane too, as in c_nw); between the two rows a residents' garden court (light and air for the
## flats, a place to sit). The court is entered from alley C through a gate, never from 6th St. Alley C is the block's
## east-west service lane: it links the C Ave apron (u -190.8) through alley B to alley A, so trucks never reverse.
## ARCHITECT: corner shop-and-flats at the alley B mouth (its shop door on the corner), a 3-storey walk-up, a 3-storey
## brick row (hardware, laundromat), a stucco 4-storey with a diner under balconies, a brick shop-and-flat, and a
## newsstand kiosk on the little paved corner by alley A's mouth. Back row: a 3-storey apartment row and a 2-unit one.
## EXTERIOR: door pots, a bench and bike rack at the kiosk corner, the court with lawn, trees in the grass, benches
## facing the lawn, a clothesline, a barbecue and table; bins where the residents put them out (the alley side).
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b1_n")
	# ---- ground
	c.pad(-140.0, -190.3, -50.0, -140.0)
	c.paint("plaza", -57.0, -190.3, -50.0, -180.0)                 # the paved corner at the kiosk
	c.paint("concrete", -127.0, -167.8, -91.0, -166.2)             # the court's path
	c.paint("grass", -127.0, -172.8, -91.0, -162.0)                # the residents' lawn (backs at -175.3 / -173.6, back row at -161)
	c.paint("concrete", -107.5, -162.0, -105.8, -146.0)            # the gate path from alley C into the court
	# 6th St's walk edge is not straight at the west end: v -790.8 at u -139, easing to -790.3 at u -127 (measured)
	var tp := PackedVector2Array([Vector2(-140.0, -190.3), Vector2(-127.0, -190.3)])
	for e: Vector2 in [Vector2(-127.0, -190.3), Vector2(-128.0, -190.31), Vector2(-129.0, -190.337), Vector2(-130.0, -190.378), Vector2(-131.0, -190.43), Vector2(-132.0, -190.488), Vector2(-133.0, -190.55), Vector2(-134.0, -190.612), Vector2(-135.0, -190.67), Vector2(-136.0, -190.722), Vector2(-137.0, -190.763), Vector2(-138.0, -190.79), Vector2(-139.0, -190.8), Vector2(-140.0, -190.8)]: tp.append(e)
	tp.remove_at(1)
	c.edge_poly("concrete", tp)
	c.build_floor(L.rect_edges(-140.0, -190.3, -50.0, -140.0))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b092_a", Vector3(-200, 6, -800), 90.0], ["s_rs_b092_b", Vector3(0, 6, -800), -90.0]], O)
	var y := c.y0
	# ---- the 6th St wall (faces north), real fronts on the property line v -790.3 (z -190.3)
	var A1 := c.bld("ck/ck_brk3_corner2", Vector2(-133.8, -190.3), "n", false, "sixth_corner_shop")
	var A2 := c.bld("ck/ck_apt3_row3", Vector2(-118.36, -190.3), "n", false, "sixth_walkup")
	var A3 := c.bld("modular/examples/mod_brk_row", Vector2(-99.93, -190.3), "n", false, "sixth_brick_row")
	var A4 := c.bld("apartments/apt_stucco3_peach", Vector2(-80.37, -190.3), "n", false, "sixth_diner_block")
	var A5 := c.bld("ck/ck_brk3_row2", Vector2(-63.81, -190.3), "n", false, "sixth_pharmacy")
	var KI := c.bld("commercial/com_kiosk", Vector2(-53.8, -184.5), "n", false, "sixth_kiosk")
	# ---- the back row on alley C (faces south onto the alley), real fronts at v -746 (z -146)
	var B1 := c.bld("modular/examples/mod_apt_row", Vector2(-118.36, -146.0), "s", false, "alleyc_apt_row")
	var B2 := c.bld("ck/ck_apt3_row2", Vector2(-96.0, -146.0), "s", false, "alleyc_apt2")
	# ---- street side of 6th (a 6.4 m walk, no parkway): door pots, the kiosk corner
	for r: Dictionary in [A1, A3, A4, A5]:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]:
				c.put("plant_potted_succulent", "normal", Vector3(dp.x + s * 1.08, y, dp.z - 0.4), 0.0, "shops: a pot either side of the door")
	c.put("prop_newspaper_box_red", "worn", Vector3(-56.4, y, -189.6), 180.0, "kiosk corner: papers")
	c.put("prop_newspaper_box_blue", "worn", Vector3(-55.6, y, -189.6), 180.0, "kiosk corner: papers")
	c.put("prop_trash_receptacle", "worn", Vector3(-56.6, y, -187.4), 0.0, "kiosk corner: a bin for wrappers, beside the queue")
	c.put("prop_bike_rack", "worn", Vector3(-52.2, y, -189.5), 0.0, "kiosk corner: bikes parallel to 6th St, beside the kiosk's queue")
	c.grime(Vector2(-53.8, -187.2), 0.0, 3.0, 2.0, 0.5)
	# ---- service sides: shops' backs face the court strip (z -175..-162): meters, condensers, bins at their doors
	c.services(A1, -2.0, 1, true)
	c.services(A2, 4.0, 1, true)
	c.services(A3, 4.0, 2, false)
	c.services(A4, 4.0, 2, true)
	c.services(A5, -2.0, 1, true)
	c.services(B1, 5.0, 1, true)
	c.services(B2, 3.0, 1, true)
	# diner (A3 east door) and laundromat: their waste goes out to the alley C side, east of the court (service strip)
	c.put("prop_dumpster_3yd_green", "worn", Vector3(-85.0, y, -149.0), 0.0, "diner (the stucco building's shop): food waste by alley C")
	c.put("prop_dumpster_3yd_blue", "worn", Vector3(-81.6, y, -149.0), 0.0, "shops: cardboard recycling by alley C")
	c.put("prop_dumpster_3yd_green", "rusty", Vector3(-62.0, y, -149.0), 0.0, "brick row shops: waste by alley C")
	c.put("prop_transformer_substation", "worn", Vector3(-74.0, y, -150.0), 0.0, "the block's transformer (underground wires)")
	c.put("prop_hose_reel_cart", "worn", Vector3(-68.5, y, -150.0), 0.0, "staff hose the service strip")
	c.put("prop_ice_chest", "worn", Vector3(-88.4, y, -163.6), 180.0, "diner: ice chest by its back door")
	c.stalls.append([-70.0, -162.0, 90.0])    # the diner's delivery van, parked in the service strip off alley C
	c.oil(Vector2(-70.0, -162.0), 90.0)
	# ---- the residents' court (lawn x -127..-91, z -172.8..-162): who: the flats on both rows
	for t: Array in [[-123.0, -170.4, "tree_magnolia_a", 0.95], [-98.0, -170.6, "tree_coral_a", 1.0], [-112.5, -163.6, "tree_jacaranda_b", 0.85]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "court: shade trees in the lawn", true, float(t[3]))
	c.put("prop_park_bench", "worn", Vector3(-117.0, y, -164.4), 180.0, "court: bench facing the lawn")
	c.put("prop_park_bench", "worn", Vector3(-104.0, y, -170.9), 0.0, "court: bench facing the lawn")
	c.put("prop_picnic_table", "worn", Vector3(-114.0, y, -170.6), 90.0, "court: residents eat out on summer evenings")
	c.put("prop_bbq_kettle", "worn", Vector3(-117.4, y, -171.9), 0.0, "court: the shared grill beside the table")
	c.put("prop_clothesline", "worn", Vector3(-100.5, y, -164.2), 0.0, "court: washing dries in the sun (flats have no dryers)")
	c.put("plant_bird_of_paradise", "normal", Vector3(-92.4, y, -168.9), 0.0, "court: planting in the lawn's corner")
	c.put("plant_agave_americana_small", "normal", Vector3(-125.6, y, -171.8), 0.0, "court: planting in the lawn's corner")
	# court enclosure: the two rows' back walls close it north and south; wrought iron closes the two ends and the gap
	# between the back-row buildings, with the residents' gate on alley C; a post at every joint
	_iron(c, Vector2(-127.6, -175.3), Vector2(-127.6, -161.2))
	_iron(c, Vector2(-90.6, -173.5), Vector2(-90.6, -161.2))
	_iron(c, Vector2(-109.2, -160.9), Vector2(-107.2, -160.9))
	c.put("fence_gate_wrought_iron", "worn", Vector3(-106.65, y, -160.9), 0.0, "court: the residents' gate from alley C", false)
	_iron(c, Vector2(-106.1, -160.9), Vector2(-102.2, -160.9))
	# ---- alley C: cracks, lane wear, tyre arcs where it meets alley A (turning), oil where vans idle
	c.cracks(-139.0, -145.6, -51.0, -140.4, 18, 0.5)
	var x := -138.0
	while x < -52.0:
		c.dec.add(6, Vector2(x, -143.0 + c.rr.randf_range(-0.3, 0.3)), 90.0, 0.9, c.rr.randf_range(4.0, 6.0), c.yf, Color(1, 1, 1, c.rr.randf_range(0.35, 0.5)))
		x += c.rr.randf_range(7.0, 11.0)
	c.tyre(Vector2(-53.0, -143.4), 60.0, 5.0, 0.4); c.tyre(Vector2(-136.5, -143.0), -60.0, 5.0, 0.35)
	c.put("prop_storm_drain_grate", "worn", Vector3(-95.0, y + 0.005, -143.0), 0.0, "alley C drains to its middle", false)
	c.dec.add(2, Vector2(-120.0, -143.0), 0.0, 1.4, 5.0, c.yf, Color(1, 1, 1, 0.85))
	# ---- roofs
	c.roof_plant(A1, [[-3.0, -3.0, "prop_ac_condenser_compact"], [3.0, 2.0, "prop_tv_antenna"]], "roof plant (flats)")
	c.roof_plant(A2, [[-6.0, -2.0, "prop_ac_condenser_compact"], [0.0, -2.0, "prop_satellite_dish_round"], [6.0, -2.0, "prop_vent_plumbing"]], "roof plant (flats)")
	c.roof_plant(A3, [[-6.0, -3.0, "prop_vent_box"], [0.0, -3.0, "prop_ac_condenser"], [5.0, -3.0, "prop_ac_condenser"], [3.0, 3.0, "prop_vent_turbine"]], "roof plant (diner exhaust, shops' AC)")
	# (A4, the stucco block, and B1, the apartment row, have pitched tile roofs: no roof plant; their units stand behind)
	c.roof_plant(A5, [[-3.0, -3.0, "prop_vent_plumbing"], [2.5, 2.0, "prop_tv_antenna"]], "roof plant (flats)")
	c.roof_plant(B2, [[-2.0, 0.0, "prop_tv_antenna"], [2.5, 0.0, "prop_vent_plumbing"]], "roof plant (flats)")
	for r2: Dictionary in [A1, A2, A3, A4, A5, B1, B2, KI]:
		for dr2: Array in r2.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()

## wrought iron run from a to b: whole 1.98 m panels (never stretched), the overlap shared in the middle, a post at
## both ends and at every joint between two panels
static func _iron(c, a: Vector2, b: Vector2) -> void:
	var L2 := a.distance_to(b); var n := maxi(1, int(ceil(L2 / 1.98)))
	var dir := (b - a).normalized()
	var yaw := rad_to_deg(atan2(dir.x, dir.y)) + 90.0
	var cs: Array[Vector2] = []
	for i in n:
		cs.append(a + dir * (0.99 + (L2 - 1.98) * float(i) / float(n - 1)) if n > 1 else a.lerp(b, 0.5))
	for m: Vector2 in cs: c.put("fence_wrought_iron", "worn", Vector3(m.x, c.y0, m.y), yaw, "court: wrought iron fence", false)
	var posts: Array[Vector2] = [a, b]
	for i in n - 1: posts.append((cs[i] + cs[i + 1]) * 0.5)
	for pp: Vector2 in posts: c.put("fence_post_wrought_iron", "worn", Vector3(pp.x, c.y0, pp.y), yaw, "court: fence post at every joint", false)
