extends SceneTree
## Piece n_cc_b1_west (city-centre fill, block 1, C AVE SIDE; claude/fill-city-centre 19 Nov). Layout row (0, 6.0, -600),
## grid frame u = x, v = z - 600. Covers u -190.8..-140, v -790.3..-700: the C Ave x 6th corner, the church, alley B
## (u -146..-140, 6th St to the civic block's lane) and the west part of alley C (v -746..-740, from the C Ave apron).
## LAND: flat. Land 5.97..6.10 m; the C Ave walk, the 6th St walk, both aprons (6th at u -146..-140, C Ave at
## v -746..-740) and the civic block's lane end (v -700) measured at 6.15: one pad at 6.15, flush on every side.
## PLANNER: C Ave is a residential street (grass parkway): the centre steps DOWN here toward the houses west and the
## civic band south. The C Ave x 6th corner gets flats over a corner shop (people who work in the centre live here);
## the flats' garden court behind is closed to the street, open to the alleys only through gates. South of alley C, on
## C Ave across from the civic band: the old downtown church with its square (people wait there before services and
## weddings) and its churchyard (a few old graves, as Coronado's old churches keep them). Alley B carries the civic
## block's service lane on to 6th St (the street piece already has its apron at exactly u -146..-140).
## ARCHITECT: 3-4 storey flats (stucco corner block, a walk-up row on 6th, a garden apartment row on C Ave), the church
## 20 m high with its front set 4 m back from C Ave behind a paved square. EXTERIOR: the court (lawn, trees in grass,
## a play corner on bark, benches facing it, picnic table, grill, washing line, bins by the alley gate); the church
## square (trees in wells, benches facing the church door, a drinking fountain, lamps, a bike rack), the churchyard
## (rows of headstones in grass, pines and magnolias, iron fence with a gate from the square).
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b1_west")
	# ---- ground
	c.pad(-190.8, -190.8, -140.0, -100.0)              # 6th St's walk ends at v -790.8 here (measured vertex by vertex)
	c.paint("concrete", -190.8, -190.8, -146.0, -190.3)                # the 0.5 m to the flats' fronts reads as walk
	c.paint("concrete", -165.6, -147.4, -163.6, -146.0)            # court gate path from alley C
	c.paint("mulch", -158.0, -158.0, -150.0, -150.0)               # play corner on bark
	c.paint("grass", -179.2, -174.4, -146.4, -146.6)               # the flats' garden court
	c.paint("grass", -157.0, -129.4, -146.2, -113.2)               # garden behind the church
	c.paint("grass", -190.8, -112.4, -146.2, -100.0)               # churchyard
	for w: Vector2 in [Vector2(-180.0, -136.0), Vector2(-166.0, -136.0)]: c.well(w.x, w.y)
	c.paint("plaza", -190.8, -140.0, -157.0, -112.4)               # church square and forecourt
	c.build_floor(L.rect_edges(-190.8, -190.8, -140.0, -100.0))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b092_a", Vector3(-200, 6, -800), 90.0], ["s_rs_b032_a", Vector3(-200, 6, -800), 0.0], ["j_apt", Vector3(-200, 6, -800), -90.0],
		["s_civ", Vector3(-200, 6, -600), -180.0], ["v_ne", Vector3(-200, 6, -600), 0.0]], O)
	var y := c.y0
	# ---- flats on the corner
	var Q1 := c.bld("apartments/apt_stucco3_cream", Vector2(-180.38, -190.3), "n", false, "cave_corner_flats")
	var Q2 := c.bld("ck/ck_apt3_row3", Vector2(-160.87, -190.3), "n", false, "cave_walkup")
	var Q3 := c.bld("apartments/apt_garden_cream", Vector2(-190.8, -162.4), "w", false, "cave_garden_apts")
	# ---- the church, set back behind its square
	var CH := c.bld("civic/civ_church", Vector2(-186.8, -121.0), "w", false, "downtown_church")
	# ---- street side: door pots at the corner shop; the flats' gaps closed with iron and a gate
	for dr: Array in c.front_shops(Q1):
		if true:
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]: c.put("plant_potted_succulent", "normal", Vector3(dp.x + s * 1.08, y, dp.z - 0.4), 0.0, "corner shop: a pot either side of the door")
	_iron(c, Vector2(-151.6, -190.0), Vector2(-146.4, -190.0), "flats: iron fence closes the gap to 6th St")
	_iron(c, Vector2(-146.4, -190.0), Vector2(-146.4, -175.0), "flats: iron fence along alley B")
	_iron(c, Vector2(-146.4, -175.0), Vector2(-146.4, -146.6), "flats: iron fence along alley B")
	_iron(c, Vector2(-190.5, -150.8), Vector2(-190.5, -146.6), "flats: iron fence closes the court to C Ave")
	_iron(c, Vector2(-190.5, -146.6), Vector2(-166.15, -146.6), "flats: iron fence along alley C")
	c.put("fence_gate_wrought_iron", "worn", Vector3(-165.6, y, -146.6), 0.0, "flats: the residents' gate from alley C", false)
	_iron(c, Vector2(-165.05, -146.6), Vector2(-146.4, -146.6), "flats: iron fence along alley C")
	# ---- the flats' service sides (backs into the court) and the court
	c.services(Q1, 5.0, 2, true)
	c.services(Q2, 4.0, 1, true)
	c.services(Q3, -4.0, 1, true)
	for t: Array in [[-169.5, -167.5, "tree_jacaranda_a", 0.9], [-150.0, -171.0, "tree_ficus_b", 0.95], [-176.5, -150.0, "tree_magnolia_b", 1.0]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), y, float(t[1])), c.rr.randf_range(0, 360), "court: shade trees in the lawn", true, float(t[3]))
	c.put("prop_play_structure", "worn", Vector3(-154.0, y, -154.0), 0.0, "court: the flats' children play here, on bark")
	c.put("prop_park_bench", "worn", Vector3(-160.4, y, -154.0), 90.0, "court: a parent watches the play corner")
	c.put("prop_park_bench", "worn", Vector3(-166.0, y, -168.6), 0.0, "court: bench facing the lawn")
	c.put("prop_picnic_table", "worn", Vector3(-170.0, y, -160.0), 0.0, "court: residents eat out")
	c.put("prop_bbq_gas_cart", "worn", Vector3(-173.2, y, -157.4), 90.0, "court: the shared grill near the table")
	c.put("prop_clothesline", "worn", Vector3(-160.0, y, -171.4), 0.0, "court: washing dries in the sun")
	for k in 3: c.put(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", Vector3(-162.9 + k * 0.95, y, -148.3), c.rr.randf_range(-10, 10), "court: bins by the alley gate for collection day")
	c.put("plant_bougainvillea_mound", "normal", Vector3(-147.9, y, -162.0), 0.0, "court: planting against the alley fence", false)
	# ---- alleys B and C: wear, drains, tyre arcs where the alleys meet the streets and each other
	c.cracks(-145.6, -189.0, -140.4, -101.0, 14, 0.5)
	c.cracks(-189.5, -145.6, -146.0, -140.4, 8, 0.5)
	var z := -188.0
	while z < -102.0:
		c.dec.add(6, Vector2(-143.0 + c.rr.randf_range(-0.3, 0.3), z), 0.0, 0.9, c.rr.randf_range(4.0, 6.0), c.yf, Color(1, 1, 1, c.rr.randf_range(0.35, 0.5)))
		z += c.rr.randf_range(7.0, 11.0)
	c.tyre(Vector2(-143.0, -187.5), -20.0, 5.0, 0.35); c.tyre(Vector2(-188.5, -143.0), 70.0, 5.0, 0.35); c.tyre(Vector2(-142.0, -144.0), 45.0, 5.0, 0.35)
	c.put("prop_manhole_cover", "worn", Vector3(-143.0, y + 0.005, -160.0), 0.0, "sewer under alley B", false)
	c.put("prop_storm_drain_grate", "worn", Vector3(-143.0, y + 0.005, -125.0), 0.0, "alley B drains to its middle", false)
	c.put("prop_transformer_substation", "worn", Vector3(-150.0, y, -142.2), 0.0, "the corner flats' transformer, at the alley (underground wires)")
	# ---- the church square: people gather before services; the churchyard behind its fence
	for w2: Vector2 in [Vector2(-180.0, -136.0), Vector2(-166.0, -136.0)]:
		c.put("tree_magnolia_a" if w2.x < -170.0 else "tree_jacaranda_b", "normal", Vector3(w2.x, y - 0.06, w2.y), w2.x * 7.0, "church square: shade trees in wells", false)
	c.put("prop_park_bench", "worn", Vector3(-173.0, y, -138.8), 0.0, "church square: bench between the trees, facing the church")
	c.put("prop_park_bench", "worn", Vector3(-159.4, y, -134.5), -90.0, "church square: bench facing across the square to C Ave")
	c.put("prop_drinking_fountain", "worn", Vector3(-188.6, y, -138.6), 90.0, "church square: a fountain by the walk")
	c.put("prop_bike_rack", "worn", Vector3(-160.0, y, -139.0), 0.0, "church square: bikes along the alley edge, off the square")
	c.put("prop_lamp_globe", "worn", Vector3(-189.4, y, -131.0), 0.0, "church square: lamp at the square's street corner")
	c.put("prop_lamp_globe", "worn", Vector3(-189.4, y, -113.6), 0.0, "church square: lamp by the churchyard gate")
	c.put("prop_trash_receptacle", "worn", Vector3(-186.0, y, -139.2), 0.0, "church square: a bin where people pass")
	for s2: float in [-3.4, 3.4]: c.put("plant_potted_leafy", "normal", c.at(CH, s2, 16.6), 0.0, "church: planters either side of the steps")
	# churchyard: three rows of old graves facing west (toward the street, as old yards were laid out)
	var kinds := ["prop_headstone_upright", "prop_headstone_cross", "prop_headstone_flat"]
	var n := 0
	for row in 3:
		for k in 7:
			if (row * 7 + k) % 5 == 3: continue     # gaps: not every plot is marked
			var hx := -184.0 + k * 3.4 + c.rr.randf_range(-0.2, 0.2); var hz := -110.0 + row * 3.4
			c.put(kinds[(row + k) % 3], "worn", Vector3(hx, y, hz), -90.0 + c.rr.randf_range(-4, 4), "churchyard: old graves in rows", true); n += 1
	for t2: Array in [[-189.0, -102.5, "tree_torrey_pine_a", 0.9], [-160.0, -102.0, "tree_torrey_pine_b", 1.0], [-150.0, -110.0, "tree_magnolia_b", 0.85]]:
		c.put(String(t2[2]), "normal", Vector3(float(t2[0]), y, float(t2[1])), c.rr.randf_range(0, 360), "churchyard: old trees in the grass", true, float(t2[3]))
	c.put("prop_park_bench", "worn", Vector3(-150.0, y, -104.0), -90.0, "churchyard: a seat facing the graves")
	_iron(c, Vector2(-190.5, -112.6), Vector2(-188.9, -112.6), "churchyard: iron fence")
	c.put("fence_gate_wrought_iron", "worn", Vector3(-188.35, y, -112.6), 0.0, "churchyard: the gate from the square", false)
	_iron(c, Vector2(-187.8, -112.6), Vector2(-146.4, -112.6), "churchyard: iron fence along the church's side and its garden")
	_iron(c, Vector2(-190.5, -112.6), Vector2(-190.5, -100.4), "churchyard: iron fence on C Ave")
	_iron(c, Vector2(-190.5, -100.4), Vector2(-146.4, -100.4), "churchyard: iron fence to the civic block")
	_iron(c, Vector2(-146.4, -100.4), Vector2(-146.4, -129.6), "church garden: iron fence along alley B")
	_iron(c, Vector2(-157.0, -129.6), Vector2(-146.4, -129.6), "church garden: iron fence to the square")
	c.services(CH, -6.0, 1, false)
	c.put("plant_bird_of_paradise", "normal", Vector3(-149.0, y, -126.0), 0.0, "church garden: planting")
	c.put("prop_adirondack_wood", "worn", Vector3(-151.0, y, -118.0), -90.0, "church garden: the priest's chair in the shade")
	# people stand at the church door and on the square: scuffs; leaves never swept under the trees
	c.grime(Vector2(-188.8, -121.0), 90.0, 3.4, 2.2, 0.45)
	for w3: Vector2 in [Vector2(-173.0, -137.8), Vector2(-160.4, -134.5)]: c.grime(w3, 0.0, 2.0, 1.4, 0.4)
	c.roof_plant(Q1, [[-6.0, -2.0, "prop_ac_condenser_compact"], [0.0, -2.0, "prop_satellite_dish"], [6.0, -2.0, "prop_ac_condenser_compact"]], "roof plant (flats)")
	c.roof_plant(Q2, [[-5.0, 0.0, "prop_tv_antenna"], [4.0, 0.0, "prop_vent_plumbing"]], "roof plant (flats)")
	for r2: Dictionary in [Q1, Q2, Q3]:
		for dr2: Array in r2.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.4, 1.2, 0.35)
	c.finish()
	quit()

## wrought iron run from a to b: whole 1.98 m panels (never stretched), the overlap shared, a post at both ends and
## at every joint
static func _iron(c, a: Vector2, b: Vector2, reason: String) -> void:
	var L2 := a.distance_to(b); var n := maxi(1, int(ceil(L2 / 1.98)))
	var dir := (b - a).normalized()
	var yaw := rad_to_deg(atan2(dir.x, dir.y)) + 90.0
	var cs: Array[Vector2] = []
	for i in n:
		cs.append(a + dir * (0.99 + (L2 - 1.98) * float(i) / float(n - 1)) if n > 1 else a.lerp(b, 0.5))
	for m: Vector2 in cs: c.put("fence_wrought_iron", "worn", Vector3(m.x, c.y0, m.y), yaw, reason, false)
	var posts: Array[Vector2] = [a, b]
	for i in n - 1: posts.append((cs[i] + cs[i + 1]) * 0.5)
	for pp: Vector2 in posts: c.put("fence_post_wrought_iron", "worn", Vector3(pp.x, c.y0, pp.y), yaw, "fence post at every joint", false)
