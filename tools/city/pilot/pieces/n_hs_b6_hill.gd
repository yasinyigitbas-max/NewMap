extends SceneTree
## Piece n_hs_b6_hill (high street fill, block 6, part "Hillcrest Terraces"): u 50..146, v -146..-51.2 (not u 125..146
## north of v -100: the residential quarter r_q), between the 9th St piece (north, its stalls on this piece's aisle),
## r_q (north-east), the hilltop courts (east, n_hs_b6_garden), the pilot's hill row r_n (south) and the pilot's b_ne /
## the Amber shops (west). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner / architect): the hill between Amber and the quarter is housing, as the hill is everywhere else, but on
## ground this steep (5 m over 70 m west to east) houses in a row would stand on 1.5 m walls each. So: HILLCREST
## TERRACES - three level terraces stepping up the hill, each with two small apartment houses facing WEST (the view down
## Amber to the ocean), front gardens on the terrace's west part, a court between the two houses; a stair walk climbs
## across all three from the shops' lane to the top. The residents park in a row of stalls off the residents' alley
## behind the r_n houses; the lane runs from the alley beside b_ne to the shops' rear lot and on to the 9th St aisle.
## LAND: each terrace level at its middle's height, retaining walls (1 - 1.6 m) between them with a planted strip,
## stairs where the walk crosses a wall; the stalls, the lane, the alley and the planted strips follow the surface; r_n's
## and r_q's stepped lot lines met by edge strips at their exact heights.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B6 := preload("res://tools/city/pilot/pieces/n_hs_b6_site.gd")

const X0 := 50.0
const X1 := 146.0
const ZN := -146.0
const ZS := -51.2
const LANE := [50.0, 56.0]
const AISLE := [-146.0, -140.0]
const STALLS := [-66.0, -60.0]       # nose-in off the alley (stops at the north end)
const WALK := [-101.2, -98.8]        # the stair walk across the terraces
## terraces [u0, v0, u1, v1]; two houses each [folder, centre v, model z max]   yaw -90 (face west, model x -> +v)
const TERR := [
	[58.0, -136.0, 79.0, -68.0],
	[82.0, -136.0, 103.0, -68.0],
	[106.0, -136.0, 123.0, -68.0],
]
const HOUSES := [
	[["apartments/apt_spanish_white", -121.0, 6.5], ["apartments/apt_spanish_revival", -82.0, 6.5]],
	[["ck/ck_apt3_row3", -121.0, 6.0], ["ck/ck_apt3_row3", -82.0, 6.0]],
	[["ck/ck_apt3_row2", -121.0, 6.0], ["ck/ck_apt3_row2", -82.0, 6.0]],
]
const FRONT_OFF := [6.0, 6.0, 4.6]   # a house's front this far inside its terrace's west edge (the narrow top terrace less)

func _init() -> void: _run.call_deferred()

static func ter_y(t: Array) -> float: return B6.g((float(t[0]) + float(t[2])) * 0.5, (float(t[1]) + float(t[3])) * 0.5)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b6_hill"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b6_hill")
	var yf := B6.L(B6.g)
	# ================================================================ ground
	var holes: Array = H.edge_strip(g, "u", ZS, -2.0, B6.Lseg(B6.RN_SEGS), yf, "grass", true)
	holes.append_array(H.edge_strip(g, "u", -100.0, 2.0, [[125.0, 146.0, 5.27, 5.27]], yf, "grass", false))
	holes.append_array(H.edge_strip(g, "v", 125.0, -2.0, B6.Lseg([[ZN, -140.0, 8.776, 8.754], [-140.0, -100.0, 9.27, 9.27]]), yf, "grass", false))
	holes.append([125.0, ZN, X1, -100.0, "-"])                                   # r_q (not mine)
	for t: Array in TERR: holes.append([t[0], t[1], t[2], t[3], "-"])
	for k in 25: holes.append([58.0 + 2.7 * k - 0.05, STALLS[0] + 0.4, 58.0 + 2.7 * k + 0.05, STALLS[1], "white"])
	holes.append_array([
		[X0, B6.ALLEY[0], X1, B6.ALLEY[1], "asphalt"],                            # the residents' alley
		[LANE[0], ZN, LANE[1], B6.ALLEY[0], "asphalt"],                           # the lane
		[LANE[1], AISLE[0], 121.0, AISLE[1], "asphalt"],                          # the 9th St houses' aisle
		[58.0, STALLS[0], 125.0, STALLS[1], "asphalt"],                           # the residents' stalls
		[LANE[1], WALK[0], 125.0, WALK[1], "plaza"],                              # the stair walk (between the terraces)
	])
	H.paint(g, X0, ZN, X1, ZS, holes, "grass", yf)
	# the terraces: front gardens, the houses' paths, the court, the walk across; walls to the field; stairs where the
	# walk crosses a wall (west side down, east side up)
	for ti in TERR.size():
		var t: Array = TERR[ti]
		var y := ter_y(t) - B6.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var u0: float = t[0]; var v0: float = t[1]; var u1: float = t[2]; var v1: float = t[3]
		var fo: float = FRONT_OFF[ti]
		var yw0 := float(yf.call(u0, -100.0)); var yw1 := float(yf.call(u1, -100.0))
		var n0 := maxi(1, ceili(absf(y - yw0) / 0.17)); var n1 := maxi(1, ceili(absf(y - yw1) / 0.17))
		var s0 := u0 + 0.3 * n0; var s1 := u1 - 0.3 * n1
		# the stairs inside the terrace at both ends of the walk (cut into it where it is higher than the strip, standing
		# on it where it is lower); the front garden; the houses' paths; the court
		var tp: Array = [[u0, WALK[0], s0, WALK[1], "-"], [s1, WALK[0], u1, WALK[1], "-"], [u0, WALK[0], u1, WALK[1], "plaza"],
			[u0 + 1.0, v0 + 1.0, u0 + fo - 0.6, v1 - 1.0, "-"]]
		for hh: Array in HOUSES[ti]:
			tp.append([u0, float(hh[1]) - 0.7, u0 + fo, float(hh[1]) + 0.7, "concrete"])
		tp.append([u0 + fo + 0.2, -110.0, u1 - 0.6, -92.0, "plaza"])
		H.paint(g, u0, v0, u1, v1, tp, "concrete", yp)
		var gp: Array = []
		if s0 > u0 + 1.0: gp.append([u0 + 1.0, WALK[0], s0, WALK[1], "-"])
		for hh2: Array in HOUSES[ti]: gp.append([u0 + 1.0, float(hh2[1]) - 0.7, u0 + fo - 0.6, float(hh2[1]) + 0.7, "concrete"])
		gp.append([u0 + 1.0, WALK[0], u0 + fo - 0.6, WALK[1], "plaza"])
		H.paint(g, u0 + 1.0, v0 + 1.0, u0 + fo - 0.6, v1 - 1.0, gp, "grass", yp)
		for e: Array in [[u0, v0, u1, v0], [u0, v1, u1, v1]]:
			H.step_face(g, Vector2(e[0], e[1]), Vector2(e[2], e[3]), yp, yf)
		H.step_face(g, Vector2(u0, v0), Vector2(u0, WALK[0]), yp, yf)
		H.step_face(g, Vector2(u0, WALK[1]), Vector2(u0, v1), yp, yf)
		H.step_face(g, Vector2(u1, v0), Vector2(u1, WALK[0]), yp, yf)
		H.step_face(g, Vector2(u1, WALK[1]), Vector2(u1, v1), yp, yf)
		H.steps_x(g, -100.0, WALK[1] - WALK[0], u0, s0, yw0, y)
		H.steps_x(g, -100.0, WALK[1] - WALK[0], u1, s1, yw1, y)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	H.finish(root, g, props, dec, "n_hs_b6_hill")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var trees := [["palm_mexican_fan_a", "tree_jacaranda_a"], ["tree_coral_b", "palm_queen_b"], ["tree_magnolia_a", "palm_mexican_fan_c"]]
	for ti in TERR.size():
		var t: Array = TERR[ti]
		var y := ter_y(t) - B6.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var u0: float = t[0]; var u1: float = t[2]
		var hi := 0
		for hh: Array in HOUSES[ti]:
			var cu := u0 + float(FRONT_OFF[ti]) + float(hh[2])
			K.building(bl, String(hh[0]), Vector3(cu, y, float(hh[1])), -90.0, "t%d_%d" % [ti, hi])
			# the front garden: a tree, planting, a bench facing the view; the mailbox at the path
			H.put(props, String(trees[ti][hi]), "normal", u0 + 3.0, float(hh[1]) + (7.0 if hi == 0 else -7.0), yp, float(ti * 2 + hi) * 40.0)
			H.put(props, "plant_bird_of_paradise", "normal", u0 + 4.6, float(hh[1]) - 2.2, yp, 0.0, false)
			H.put(props, "plant_agave_americana_small", "normal", u0 + 4.6, float(hh[1]) + 2.4, yp, 0.0, false)
			H.put(props, "prop_mailbox_post_metal", "worn", u0 + 1.5, float(hh[1]) + 1.2, yp, -90.0)
			var st := K.building_stats(String(hh[0]))
			var half: float = float((st.near as Dictionary).bbox[1][0]) if st.has("near") else float(st.footprint_wd[0]) * 0.5
			H.put(props, "prop_ac_condenser", "worn", cu, float(hh[1]) + (half + 0.8) * (-1.0 if hi == 0 else 1.0), yp, 0.0)
			hi += 1
		# the court between the houses: tables, a grill, washing, a tree; bins by the walk
		var fo2: float = FRONT_OFF[ti]
		H.put(props, "prop_picnic_table", "worn", u0 + fo2 + 5.0, -104.0, yp, 0.0)
		H.put(props, "prop_bbq_kettle", "worn", u0 + fo2 + 8.0, -106.4, yp, 0.0)
		H.put(props, "prop_clothesline", "worn", u0 + fo2 + 6.0, -95.0, yp, 90.0)
		H.put(props, "prop_park_bench", "worn", u0 + 2.0, -104.0, yp, -90.0)
		for k in 3: H.put(props, ["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", u1 - 0.8, -96.5 + 0.8 * k, yp, -90.0)
		H.put(props, "prop_lamp_globe", "worn", u0 + 0.6, -102.0, yp)
	# ---- the planted strips between the terraces (the walls' feet): shrubs and a tree each, in the grass
	for s: Array in [[56.5, "tree_ficus_b"], [80.5, "tree_coral_a"], [104.5, "tree_jacaranda_b"]]:
		P.call(String(s[1]), "normal", float(s[0]) + (0.0 if float(s[0]) > 60.0 else 0.6), -124.0, float(s[0]) * 5.0)
	P.call("tree_torrey_pine_a", "normal", 124.0, -78.0, 20.0)
	# ---- the residents' stalls off the alley: wheel stops, a light, oil; the lane: a drain, a light
	for k in 24:
		var xc := 58.0 + 2.7 * k + 1.35
		P.call("prop_wheel_stop_concrete", "worn", xc, STALLS[0] + 0.9, 0.0)
		if k % 3 != 1: W.oil(dec, rr, Vector2(xc, STALLS[0] + 2.6), 0.0, yf, 0.6)
	P.call("prop_lot_light_pole", "worn", 90.0, STALLS[0] - 0.6)
	P.call("prop_lot_light_pole", "worn", 56.6, -100.0)
	P.call("prop_storm_drain_grate", "worn", 53.0, -98.0, 0.0, false)
	W.lane_wear(dec, rr, -57.0, X0, X1, false, yf)
	W.lane_wear(dec, rr, 53.0, ZN, B6.ALLEY[0], true, yf)
	dec.add(0, Vector2(90.0, -143.0), 20.0, 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
