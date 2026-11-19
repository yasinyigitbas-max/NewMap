extends SceneTree
## Piece n_hs_b5_hill (high street fill, block 5, part "the hillside"): u 50..146, v 51.2..156 (not u 125..146 below
## v 100: the residential quarter r_q), between the pilot's hill row r_s (north), the school (east, n_hs_b5_school),
## r_q (south-east), the 11th St piece (south, n_hs_b5_eleventh) and the pilot's b_se / the Amber shops (west).
## Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner / landscape): the hill between Amber and the school is the steepest ground of the high street (5.5 m
## over 96 m west to east, 4 m over 40 m at its top). It is not built on: it becomes HILLSIDE PARK, the hill's green
## between downtown and the houses. At its top, at the residents' alley, the LOOKOUT terrace (benches and a railing
## over its wall, the view down Amber to the ocean); a path across the slope from the shops' lane to the lookout; a
## path down the hill from the alley past the lawns to the tennis courts and the 11th St apartments' parking. The
## residents' alley runs behind the r_s houses from the school to the shops' lane, the lane down beside b_se to the
## Amber shops' rear lot and on to the apartments' parking aisle.
## LAND: the lawns, the paths and the alley follow the slope (one surface, n_hs_b5_site.gd); level ground only where
## it is needed: the lookout (a terrace at the alley's height, a ~1 m wall below it), the tennis courts (a pad at their
## middle's height, faces under 0.5 m). r_s's and r_q's stepped lot lines are met by edge strips at their exact
## heights.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B5 := preload("res://tools/city/pilot/pieces/n_hs_b5_site.gd")

const X0 := 50.0
const X1 := 146.0
const ZN := 51.2
const ZS := 156.0
const LANE := [50.0, 56.0]
const AISLE := [150.0, 156.0]
const LOOK := [124.0, 61.5, 145.4, 72.0]
const TENNIS := [60.0, 105.0, 100.0, 141.0]
const PATH_EW := [77.0, 79.4]        # across the slope, from the lane to the lookout's steps
const PATH_NS := [104.0, 106.4]      # down the hill, from the alley to the parking aisle
const STEPS_U := [128.0, 130.4]      # the lookout's steps (from the path up its wall)

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["tree_coral_b", "normal", 114.8, 98.0, 17.0],
	["prop_picnic_table", "worn", 101.8, 98.0, 168.0],
	["palm_queen_a", "normal", 89.8, 98.0, 123.0],
	["prop_picnic_table", "worn", 74.2, 98.5, 62.0],
	["tree_jacaranda_b", "normal", 61.8, 98.5, 229.0],
	["prop_picnic_table", "worn", 123.8, 96.5, 136.0],
	["tree_magnolia_b", "normal", 140.8, 92.5, 335.0],
	["prop_picnic_table", "worn", 131.8, 92.0, 30.0],
	["prop_sprinkler_popup", "worn", 108.8, 98.0, 213.0, false],
	["plant_agave_americana", "normal", 120.2, 98.0, 284.0, false],
	["plant_bird_of_paradise", "normal", 95.8, 98.0, 355.0, false],
	["plant_bougainvillea_mound", "normal", 68.2, 98.5, 66.0, false],
	["plant_iceplant_patch", "normal", 79.2, 98.5, 137.0, false],
	["prop_sprinkler_popup", "worn", 84.2, 98.0, 208.0, false],
	["plant_agave_americana", "normal", 58.2, 102.5, 279.0, false],
	["plant_bird_of_paradise", "normal", 98.2, 102.5, 350.0, false],
	["plant_bougainvillea_mound", "normal", 111.2, 102.5, 61.0, false],
	["plant_iceplant_patch", "normal", 86.8, 102.5, 132.0, false],
	["plant_potted_leafy", "normal", 136.8, 64.0, 270.0, false],
	["prop_park_bench", "worn", 131.8, 65.5, 90.0],
	["prop_bike_rack", "worn", 135.8, 69.0, 180.0],
	["plant_potted_succulent", "normal", 127.8, 69.5, 270.0, false],
	["prop_trash_receptacle", "worn", 105.2, 78.0, 0.0],
]

func _init() -> void: _run.call_deferred()

static func look_y() -> float: return B5.g(134.7, 60.0)
static func tennis_y() -> float: return B5.g(80.0, 123.0)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b5_hill"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b5_hill")
	var yf := B5.L(B5.g)
	var yl := look_y() - B5.PAD_Y
	var ylp := func(_x: float, _z: float) -> float: return yl
	var yt := tennis_y() - B5.PAD_Y
	var ytp := func(_x: float, _z: float) -> float: return yt
	# ================================================================ ground
	var rs := B5.Lseg(B5.RS_SEGS); rs[0][0] = 50.6
	var holes: Array = H.edge_strip(g, "u", ZN, 2.0, rs, yf, "grass", true)
	holes.append_array(H.edge_strip(g, "u", 100.0, -2.0, [[125.0, 146.0, 1.98, 1.98]], yf, "grass", false))
	holes.append_array(H.edge_strip(g, "v", 125.0, -2.0, B5.Lseg([[100.0, 140.0, 5.98, 5.98], [140.0, 145.5, 5.772, 5.62], [145.5, 154.0, 5.61, 5.61], [154.0, ZS, 5.22, 5.22]]), yf, "grass", false))
	var nst := ceili(absf(yl - float(yf.call(129.2, LOOK[3]))) / 0.17)
	holes.append_array([
		[125.0, 100.0, X1, ZS, "-"],                                          # r_q (not mine)
		[LOOK[0], LOOK[1], LOOK[2], LOOK[3], "-"], [TENNIS[0], TENNIS[1], TENNIS[2], TENNIS[3], "-"],
		[STEPS_U[0], LOOK[3], STEPS_U[1], LOOK[3] + 0.3 * nst, "-"],
		[X0, B5.ALLEY[0], X1, B5.ALLEY[1], "asphalt"],                        # the residents' alley
		[LANE[0], B5.ALLEY[1], LANE[1], ZS, "asphalt"],                       # the lane down to the shops' lot and the aisle
		[LANE[1], AISLE[0], 121.0, AISLE[1], "asphalt"],                      # the apartments' parking aisle
		[LANE[1], PATH_EW[0], 131.0, PATH_EW[1], "plaza"],
		[STEPS_U[0], LOOK[3], STEPS_U[1], PATH_EW[0], "plaza"],
		[PATH_NS[0], B5.ALLEY[1], PATH_NS[1], AISLE[0], "plaza"],
		[100.0, 121.8, PATH_NS[0], 124.2, "plaza"],                           # to the courts' gate
	])
	H.paint(g, X0, ZN, X1, ZS, holes, "grass", yf)
	# the lookout terrace: paved, its tree bed; the wall below it
	H.paint(g, LOOK[0], LOOK[1], LOOK[2], LOOK[3], [[139.0, 64.0, 143.0, 68.0, "grass"]], "plaza", ylp)
	for e: Array in [[LOOK[0], LOOK[1], LOOK[2], LOOK[1]], [LOOK[0], LOOK[1], LOOK[0], LOOK[3]], [LOOK[2], LOOK[1], LOOK[2], LOOK[3]]]:
		H.step_face(g, Vector2(e[0], e[1]), Vector2(e[2], e[3]), ylp, yf)
	H.step_face(g, Vector2(LOOK[0], LOOK[3]), Vector2(STEPS_U[0], LOOK[3]), ylp, yf)
	H.step_face(g, Vector2(STEPS_U[1], LOOK[3]), Vector2(LOOK[2], LOOK[3]), ylp, yf)
	H.steps_z(g, (STEPS_U[0] + STEPS_U[1]) * 0.5, STEPS_U[1] - STEPS_U[0], LOOK[3] + 0.3 * nst, LOOK[3], float(yf.call(129.2, LOOK[3] + 0.3 * nst)), yl)
	# the tennis courts: two courts on one pad, their lines
	var tl: Array = []
	for cx: float in [70.0, 90.0]:
		for lx: float in [-5.485, -4.115, 4.115, 5.485]: tl.append([cx + lx - 0.04, 111.115, cx + lx + 0.04, 134.885, "white"])
		for lz: float in [111.115, 134.885]: tl.append([cx - 5.485, lz - 0.04, cx + 5.485, lz + 0.04, "white"])
		for lz2: float in [116.6, 129.4]: tl.append([cx - 4.115, lz2 - 0.04, cx + 4.115, lz2 + 0.04, "white"])
		tl.append([cx - 0.04, 116.6, cx + 0.04, 129.4, "white"])
		tl.append([cx - 6.2, 109.5, cx + 6.2, 136.5, "asphalt"])
	H.paint(g, TENNIS[0], TENNIS[1], TENNIS[2], TENNIS[3], tl, "concrete", ytp, 1.0)
	for e2: Array in [[TENNIS[0], TENNIS[1], TENNIS[2], TENNIS[1]], [TENNIS[0], TENNIS[3], TENNIS[2], TENNIS[3]], [TENNIS[0], TENNIS[1], TENNIS[0], TENNIS[3]], [TENNIS[2], TENNIS[1], TENNIS[2], TENNIS[3]]]:
		H.step_face(g, Vector2(e2[0], e2[1]), Vector2(e2[2], e2[3]), ytp, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf, ylp, ytp)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b5_hill")
	quit()

func _build(_bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, ylp: Callable, ytp: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	# ---- the lookout: the railing on its wall (south and west), benches facing the view (west, down Amber to the
	# ocean), the tree in its bed, a lamp, a bin, the bike rack by the alley
	var rails: Array = [126.0]
	for k in 7: rails.append(131.62 + 2.045 * k)
	for x: float in rails: H.put(props, "prop_prom_rail_wall", "clean", x, LOOK[3] - 0.2, ylp, 0.0)     # (open at the steps)
	for k in 4: H.put(props, "prop_prom_rail_wall", "clean", LOOK[0] + 0.2, LOOK[1] + 3.0 + 2.045 * k, ylp, 90.0)
	for b: Array in [[126.4, 64.5], [126.4, 68.0], [133.0, 70.4]]: H.put(props, "prop_park_bench", "worn", float(b[0]), float(b[1]), ylp, -90.0 if float(b[0]) < 130.0 else 0.0)
	H.put(props, "tree_jacaranda_a", "normal", 141.0, 66.0, ylp, 70.0)
	H.put(props, "prop_lamp_victorian", "worn", 136.0, 62.2, ylp)
	H.put(props, "prop_trash_receptacle", "worn", 131.2, 62.4, ylp)
	H.put(props, "prop_bike_rack", "worn", 144.6, 70.0, ylp, 90.0)
	# ---- the lawns: trees in the grass (flowering trees and palms; a Torrey pine as the hill's own), benches along
	# the paths, picnic tables on the gentler lower lawn
	for t: Array in [["palm_mexican_fan_a", 62.0, 66.0], ["tree_coral_a", 72.0, 88.0], ["tree_jacaranda_b", 88.0, 70.0], ["tree_torrey_pine_a", 96.0, 90.0],
			["palm_queen_b", 112.0, 66.0], ["tree_magnolia_b", 116.0, 88.0], ["tree_coral_b", 138.0, 86.0], ["tree_jacaranda_a", 82.0, 96.0],
			["palm_mexican_fan_c", 64.0, 96.0], ["tree_ficus_b", 112.0, 112.0], ["tree_coral_a", 116.0, 136.0], ["palm_queen_a", 110.0, 146.0]]:
		P.call(String(t[0]), "normal", float(t[1]), float(t[2]), float(t[1]) * 3.0)
	for b2: Array in [[68.0, 80.2, 180.0], [92.0, 80.2, 180.0], [116.0, 80.2, 180.0], [107.2, 70.0, -90.0], [107.2, 92.0, -90.0], [103.2, 132.0, 90.0]]:
		P.call("prop_park_bench", "worn", float(b2[0]), float(b2[1]), float(b2[2]))
	for t2: Array in [[114.0, 120.0], [118.0, 128.0]]: P.call("prop_picnic_table", "worn", float(t2[0]), float(t2[1]), 20.0)
	for l: Array in [[60.0, 76.6], [80.0, 76.6], [100.0, 76.6], [124.0, 76.6], [106.9, 64.0], [106.9, 100.0], [106.9, 140.0]]:
		P.call("prop_lamp_globe", "worn", float(l[0]), float(l[1]))
	P.call("prop_trash_receptacle", "worn", 103.4, 80.0)
	P.call("prop_drinking_fountain", "worn", 103.4, 100.0, -90.0)
	# ---- the tennis courts: nets, chain-link round the pad (a post at every joint; the gate opening on the path side),
	# benches by the gate
	for cx: float in [70.0, 90.0]: H.put(props, "prop_tennis_net", "worn", cx, 123.0, ytp, 0.0)
	var f := func(a: Vector2, b: Vector2) -> void: H.fence(props, "fence_chainlink", "fence_chainlink_post", a, b, ytp, 2.0)
	f.call(Vector2(TENNIS[0] + 0.3, TENNIS[1] + 0.3), Vector2(TENNIS[2] - 0.3, TENNIS[1] + 0.3))
	f.call(Vector2(TENNIS[0] + 0.3, TENNIS[3] - 0.3), Vector2(TENNIS[2] - 0.3, TENNIS[3] - 0.3))
	f.call(Vector2(TENNIS[0] + 0.3, TENNIS[1] + 0.3), Vector2(TENNIS[0] + 0.3, TENNIS[3] - 0.3))
	f.call(Vector2(TENNIS[2] - 0.3, TENNIS[1] + 0.3), Vector2(TENNIS[2] - 0.3, 121.6))
	f.call(Vector2(TENNIS[2] - 0.3, 124.4), Vector2(TENNIS[2] - 0.3, TENNIS[3] - 0.3))
	H.put(props, "prop_park_bench", "worn", 98.4, 118.0, ytp, -90.0)
	H.put(props, "prop_park_bench", "worn", 98.4, 128.0, ytp, -90.0)
	# ---- the alley and the lane: a light at the corner, a drain at the low end, wear
	P.call("prop_lot_light_pole", "worn", 56.6, 61.0)
	P.call("prop_storm_drain_grate", "worn", 53.0, 98.0, 0.0, false)
	W.lane_wear(dec, rr, 57.0, X0, X1, false, yf)
	W.lane_wear(dec, rr, 53.0, B5.ALLEY[1], ZS, true, yf)
	dec.add(0, Vector2(90.0, 152.5), 20.0, 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
