extends SceneTree
## Piece n_hs_b5_school (high street fill, block 5, part "Hilltop School"): u 146..240.8, v 54..100, between the
## residents' alley (north, v 54..60, in this piece from u 146 to its mouth on B Ave), B Ave (east), the residential
## quarter r_q_250_200_nw (south) and the hillside park (west, n_hs_b5_hill). Placed at grid [0, 4.0, 0], yaw 0. Run
## once; never when locked.
##
## WHY (planner / architect): the hill's houses (the pilot rows, the residential quarter, the new 10th St lots) need
## their primary school within walking distance: HILLTOP ELEMENTARY on B Ave, the residential street. Two wings in an L:
## the main wing faces B Ave with its forecourt (the parents' drop-off is the street, a bike rack, the flag), the
## classroom wing along the alley; between them, sheltered, the playground (swings, slides, tables, shade trees). West
## of the campus, on the slope down to the park, the school garden (a lawn with trees and benches, where classes sit
## out); the staff park off the alley.
## LAND: the hill top falls 1.5 m to the east (B Ave) and 2 - 3.6 m to the south (to r_q's back yards). The campus
## stands on ONE level platform at the main door's walk height (B Ave at v 79.5); retaining walls round it (0.5 - 0.9 m,
## with a fence or a hedge on top); the garden follows the slope; r_q's stepped lot line is met by an edge strip at its
## exact heights; the staff parking is a level shelf at the alley.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B5 := preload("res://tools/city/pilot/pieces/n_hs_b5_site.gd")

const X0 := 146.0
const X1 := 240.8
const ZA := 54.0
const ZS := 100.0
const P1 := [185.0, 61.0, 238.6, 81.0]      # the platform, north part (classroom wing, the main wing's north end)
const P2 := [192.0, 81.0, 238.6, 96.0]      # the platform, south part (playground, the main wing's south end)
const WING_A := Vector2(224.85, 79.5)       # main wing, yaw 90 (faces B Ave; door at v 79.5)
const WING_B := Vector2(201.4, 70.0)        # classroom wing, yaw 0 (faces the playground, back to the alley)
const STAFF := [150.0, 60.0, 182.0, 65.5]   # the staff parking shelf (nose-in off the alley)

func _init() -> void: _run.call_deferred()

static func plat_y() -> float: return B5.bave(79.5)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b5_school"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b5_school")
	var yf := B5.L(B5.g)
	var y := plat_y() - B5.PAD_Y
	var yp := func(_x: float, _z: float) -> float: return y
	var ys := B5.alley(166.0, 60.0) - B5.PAD_Y
	var ysp := func(_x: float, _z: float) -> float: return ys
	# ================================================================ ground
	var rq := B5.Lseg(B5.RQN_SEGS); rq[rq.size() - 1][1] = 238.6          # (the band along B Ave beyond it)
	var holes: Array = H.edge_strip(g, "u", ZS, -2.0, rq, yf, "grass", false)
	holes.append_array([[P1[0], P1[1], P1[2], P1[3], "-"], [P2[0], P2[1], P2[2], P2[3], "-"], [STAFF[0], STAFF[1], STAFF[2], STAFF[3], "-"]])
	for k in 12: holes.append([STAFF[0] + 0.5 + 2.7 * k - 0.05, STAFF[1] + 0.6, STAFF[0] + 0.5 + 2.7 * k + 0.05, STAFF[3], "white"])
	holes.append_array([
		[X0, ZA, X1, B5.ALLEY[1], "asphalt"],              # the alley
		[238.6, ZA, X1, ZS, "concrete"],                   # band along B Ave (2.2 m: the platform's wall away from the walk)
		[164.0, 66.0, 166.4, 97.0, "plaza"],               # the garden path down the slope
	])
	H.paint(g, X0, ZA, X1, ZS, holes, "grass", yf)
	# the platform: forecourt and walks paved, the playground's grass and its tree beds
	var pp1: Array = [[234.8, P1[1], P1[2], P1[3], "concrete"], [192.0, 79.95, 217.0, P1[3], "concrete"]]
	H.paint(g, P1[0], P1[1], P1[2], P1[3], pp1, "plaza", yp)
	var pp2: Array = [[234.8, P2[1], P2[2], P2[3], "concrete"], [194.0, 84.0, 205.0, 94.5, "mulch"], [207.0, 88.0, 215.5, 94.5, "grass"]]
	H.paint(g, P2[0], P2[1], P2[2], P2[3], pp2, "plaza", yp)
	H.step_face(g, Vector2(P1[0], P1[1]), Vector2(P1[2], P1[1]), yp, yf)
	H.step_face(g, Vector2(P1[0], P1[1]), Vector2(P1[0], P1[3]), yp, yf)
	H.step_face(g, Vector2(P1[0], P1[3]), Vector2(P2[0], P1[3]), yp, yf)
	H.step_face(g, Vector2(P2[0], P2[1]), Vector2(P2[0], P2[3]), yp, yf)
	H.step_face(g, Vector2(P2[0], P2[3]), Vector2(P2[2], P2[3]), yp, yf)
	H.step_face(g, Vector2(P1[2], P1[1]), Vector2(P1[2], P2[3]), yp, yf)
	H.paint(g, STAFF[0], STAFF[1], STAFF[2], STAFF[3], [], "asphalt", ysp)
	H.step_face(g, Vector2(STAFF[0], STAFF[1]), Vector2(STAFF[0], STAFF[3]), ysp, yf)
	H.step_face(g, Vector2(STAFF[2], STAFF[1]), Vector2(STAFF[2], STAFF[3]), ysp, yf)
	H.step_face(g, Vector2(STAFF[0], STAFF[3]), Vector2(STAFF[2], STAFF[3]), ysp, yf)
	H.step_face(g, Vector2(STAFF[0], STAFF[1]), Vector2(STAFF[2], STAFF[1]), ysp, yf)
	H.skirt(g, Vector2(X1, ZA), Vector2(X1, ZS), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf, yp, ysp)
	H.finish(root, g, props, dec, "n_hs_b5_school")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, yp: Callable, ysp: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var Q := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yp, yaw, collide)
	var y := float(yp.call(0.0, 0.0))
	K.building(bl, "civic/civ_school_wing", Vector3(WING_A.x, y, WING_A.y), 90.0, "school_main")
	K.building(bl, "civic/civ_school_wing", Vector3(WING_B.x, y, WING_B.y), 0.0, "school_classes")
	# ---- the forecourt on B Ave: the flag, bike racks, a bench for waiting parents, lamps, a bin
	Q.call("prop_bike_rack", "worn", 236.5, 66.0, 90.0)
	Q.call("prop_bike_rack", "worn", 236.5, 70.0, 90.0)
	Q.call("prop_park_bench", "worn", 235.6, 88.0, -90.0)
	Q.call("prop_trash_receptacle", "worn", 236.0, 84.0)
	Q.call("prop_drinking_fountain", "worn", 235.5, 74.5, 90.0)
	for v: float in [63.5, 94.0]: Q.call("prop_lamp_globe", "worn", 236.6, v)
	Q.call("plant_potted_succulent", "normal", 235.4, 77.6, 0.0, false)
	Q.call("plant_potted_succulent", "normal", 235.4, 81.4, 0.0, false)
	# the walls along B Ave where the platform is below (north) / above (south) the walk: a hedge on the high side
	H.hedge(props, Vector2(238.2, 85.0), Vector2(238.2, 95.4), yp)
	H.hedge(props, Vector2(239.2, 61.6), Vector2(239.2, 73.0), yf)
	# ---- the playground between the wings: swings and slides on the mulch, tables, shade trees in their grass bed,
	# benches for the teachers on duty
	for k in 2: Q.call("prop_swing_set", "worn", 197.0 + 4.0 * k, 87.0, 0.0)
	Q.call("prop_slide", "worn", 197.0, 92.0, 90.0)
	Q.call("prop_slide", "worn", 202.5, 92.0, 90.0)
	Q.call("tree_coral_a", "normal", 209.5, 91.0, 30.0)
	Q.call("tree_jacaranda_b", "normal", 213.5, 91.0, 120.0)
	for t: Array in [[210.5, 84.6], [214.2, 84.6]]: Q.call("prop_picnic_table", "worn", float(t[0]), float(t[1]), 0.0)
	Q.call("prop_park_bench", "worn", 206.0, 84.6, 90.0)
	Q.call("prop_trash_receptacle", "worn", 216.4, 82.4)
	Q.call("prop_recycling_receptacle", "worn", 217.2, 82.4)
	Q.call("prop_drinking_fountain", "worn", 192.8, 82.0, 90.0)
	# the playground closed by chain-link from wing to wing (a post at every joint), over the walls above the garden
	# and r_q's yards; hedges along the platform's other walls (and on the alley's side above the cut)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(192.2, 95.0), Vector2(218.5, 95.0), yp, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(192.2, 76.5), Vector2(192.2, 95.0), yp, 2.0)
	H.hedge(props, Vector2(185.5, 80.5), Vector2(191.9, 80.5), yp)
	H.hedge(props, Vector2(185.0, 60.5), Vector2(238.4, 60.5), yf)
	H.hedge(props, Vector2(235.2, 95.6), Vector2(238.2, 95.6), yp)
	# ---- the school garden on the slope: trees in the grass, benches along its path facing the view west, a table
	for t2: Array in [["tree_magnolia_a", 152.0, 74.0], ["tree_coral_b", 158.0, 88.0], ["tree_jacaranda_a", 172.0, 78.0], ["tree_ficus_b", 178.0, 92.0],
			["palm_queen_a", 160.0, 70.0], ["tree_torrey_pine_a", 152.0, 92.0]]:
		P.call(String(t2[0]), "normal", float(t2[1]), float(t2[2]), float(t2[1]) * 2.0)
	for b: Array in [[163.2, 74.0], [163.2, 84.0], [167.2, 90.0]]: P.call("prop_park_bench", "worn", float(b[0]), float(b[1]), -90.0 if float(b[0]) < 165.0 else 90.0)
	P.call("prop_picnic_table", "worn", 172.0, 70.0, 0.0)
	# ---- the staff parking shelf: wheel stops, a light, oil; the dumpster by the classroom wing's back
	for k in 11:
		H.put(props, "prop_wheel_stop_concrete", "worn", STAFF[0] + 0.5 + 2.7 * k + 1.35, STAFF[3] - 0.6, ysp, 0.0)
		if k % 3 == 0: W.oil(dec, rr, Vector2(STAFF[0] + 0.5 + 2.7 * k + 1.35, 63.0), 0.0, ysp, 0.5)
	P.call("prop_lot_light_pole", "worn", 166.0, 60.4)
	P.call("prop_dumpster_3yd_green", "worn", 183.0, 62.6, 0.0)
	P.call("prop_recycling_receptacle", "worn", 181.0, 66.6, 0.0)
	# ---- the alley
	W.lane_wear(dec, rr, 57.0, X0, X1, false, yf)
	dec.add(0, Vector2(205.0, 57.5), 40.0, 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
