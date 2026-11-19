extends SceneTree
## Piece n_hs_b6_garden (high street fill, block 6, part "Hilltop Courts"): u 146..240.8, v -100..-54, between the
## residential quarter r_q_250_m200_sw (north), B Ave (east), the residents' alley (south, v -60..-54, in this piece
## from u 146 to its mouth on B Ave) and Hillcrest Terraces (west, n_hs_b6_hill). Placed at grid [0, 4.0, 0], yaw 0.
## Run once; never when locked.
##
## WHY (planner): the hill top between the quarter and the 10th St houses: HILLTOP COURTS, two rows of townhouses (each
## with its own garage): the south row's garages open on the residents' alley (as the 10th St houses' do), the north
## row's on a short private drive, HILLTOP COURT, that leaves the alley through the residents' lot at the west end;
## small gardens behind the south row, a footpath from the drive's end to B Ave. The lot holds the visitors' and the
## second cars.
## LAND: rises 1 m north from the alley (10.0 - 10.4) to the quarter (10.2 - 11.3). Each townhouse on a level pad at its
## garage's apron height; the lot, the drive and the gardens follow the surface; r_q's stepped lot line met by an edge
## strip at its exact heights.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B6 := preload("res://tools/city/pilot/pieces/n_hs_b6_site.gd")

const X0 := 146.0
const X1 := 240.8
const ZN := -100.0
const ZA := -54.0
const DRIVE := [-83.0, -77.5]
const LOT := [148.0, -96.0, 168.5, -60.0]
const AISLE_U := [157.0, 163.0]
## [label, folder, centre u, row]   row "S": front on the alley (front v -61.4); "N": front on the drive (front v -83.0)
const UNITS := [
	["s1", "apartments/apt_townhouse_cays", 185.5, "S"], ["s2", "apartments/apt_townhouse_modern", 207.0, "S"], ["s3", "apartments/apt_townhouse_cays", 228.0, "S"],
	["n1", "apartments/apt_townhouse_modern", 185.5, "N"], ["n2", "apartments/apt_townhouse_cays", 207.0, "N"], ["n3", "apartments/apt_townhouse_modern", 228.0, "N"],
]
const FRONT := {"S": -61.4, "N": -83.0}

func _init() -> void: _run.call_deferred()

static func bb(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
static func unit_y(u: Array) -> float: return B6.g(float(u[2]), float(FRONT[String(u[3])]))
static func pad(u: Array) -> Array:
	var b := bb(String(u[1]))
	var fr: float = FRONT[String(u[3])]
	return [float(u[2]) + float(b[0][0]) - 0.3, fr - (float(b[1][2]) - float(b[0][2])) - 0.5, float(u[2]) + float(b[1][0]) + 0.3, fr]

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b6_garden"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b6_garden")
	var yf := B6.L(B6.g)
	# ================================================================ ground
	var holes: Array = H.edge_strip(g, "u", ZN, 2.0, B6.Lseg([[146.0, 146.75, 9.27, 9.27], [146.75, 168.25, 10.19, 10.19], [168.25, 190.0, 10.95, 10.95],
		[190.0, 195.25, 10.74, 10.834], [195.25, 204.0, 10.834, 10.834], [204.0, 238.6, 11.27, 11.27]]), yf, "grass", false)
	for un: Array in UNITS:
		var p := pad(un); holes.append([p[0], p[1], p[2], p[3], "-"])
	for k in 13:
		var v := LOT[1] + 1.0 + 2.7 * k
		holes.append([LOT[0], v - 0.05, AISLE_U[0], v + 0.05, "white"]); holes.append([AISLE_U[1], v - 0.05, LOT[2], v + 0.05, "white"])
	holes.append_array([
		[X0, B6.ALLEY[0], X1, ZA, "asphalt"],                          # the alley
		[238.6, ZN, X1, ZA, "concrete"],                               # band along B Ave
		[LOT[0], LOT[1], LOT[2], LOT[3], "asphalt"],                   # the residents' lot
		[LOT[2], DRIVE[0], 236.0, DRIVE[1], "asphalt"],                # Hilltop Court, the drive
		[236.0, -81.8, 238.6, -80.2, "plaza"],                         # the footpath to B Ave
	])
	H.paint(g, X0, ZN, X1, ZA, holes, "grass", yf)
	for un: Array in UNITS:
		var y := unit_y(un) - B6.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var p := pad(un)
		var fr: float = FRONT[String(un[3])]
		# the pad: a paved apron along the front (the garages, the doors), a garden behind
		H.paint(g, p[0], p[1], p[2], p[3], [[p[0], fr - 1.6, p[2], fr, "concrete"]], "grass", yp)
		for e: Array in [[p[0], p[1], p[2], p[1]], [p[0], p[3], p[2], p[3]], [p[0], p[1], p[0], p[3]], [p[2], p[1], p[2], p[3]]]:
			H.step_face(g, Vector2(e[0], e[1]), Vector2(e[2], e[3]), yp, yf)
	H.skirt(g, Vector2(X1, ZN), Vector2(X1, ZA), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	H.finish(root, g, props, dec, "n_hs_b6_garden")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var i := 0
	for un: Array in UNITS:
		var y := unit_y(un) - B6.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var b := bb(String(un[1]))
		var fr: float = FRONT[String(un[3])]
		var cu: float = un[2]
		var cv := fr - float(b[1][2])
		K.building(bl, String(un[1]), Vector3(cu, y, cv), 0.0, String(un[0]))
		var vb := cv + float(b[0][2])
		# behind each townhouse a small garden: a table or a grill, a tree in the grass; a condenser at the side
		var back := 1.6 if String(un[3]) == "S" else 1.0
		H.put(props, ["prop_patio_set_4", "prop_bbq_kettle", "prop_adirondack_white", "prop_patio_set_4", "prop_bbq_gas_cart", "prop_adirondack_wood"][i], "worn", cu - 4.0, vb - back, yf, 0.0)
		H.put(props, "prop_ac_condenser", "worn", cu + float(b[1][0]) - 1.0, vb - 0.8, yf, 0.0)
		P.call(["tree_coral_a", "tree_jacaranda_b", "palm_queen_a", "tree_magnolia_b", "tree_coral_b", "palm_mexican_fan_b"][i], "normal", cu + 5.0, vb - back - 0.4, float(i) * 33.0)
		# (no bins at the fronts: garage and front doors fill them; the courts share the dumpster at the lot)
		W.oil(dec, rr, Vector2(cu - 7.0, fr + 1.0), 0.0, yf, 0.5)
		W.oil(dec, rr, Vector2(cu + 3.0, fr + 1.0), 0.0, yf, 0.5)
		i += 1
	# ---- the residents' lot: wheel stops on both rows, a light, a dumpster for the courts' rubbish, a bench at the path
	for k in 12:
		var v := LOT[1] + 1.0 + 2.7 * k + 1.35
		P.call("prop_wheel_stop_concrete", "worn", LOT[0] + 0.7, v, 90.0)
		P.call("prop_wheel_stop_concrete", "worn", LOT[2] - 0.7, v, 90.0)
		if k % 3 == 0: W.oil(dec, rr, Vector2(LOT[0] + 2.5, v), 90.0, yf, 0.6)
	P.call("prop_lot_light_pole", "worn", 160.0, -96.6)
	P.call("prop_dumpster_3yd_green", "worn", 171.0, -96.0, 0.0)
	P.call("prop_recycling_receptacle", "worn", 171.0, -93.4, 0.0)
	# ---- the drive: lamps, the mailboxes in a cluster at its mouth, a tree at the turning end, the gate path to B Ave
	for x: float in [176.0, 196.3, 217.5]: P.call("prop_lamp_globe", "worn", x, DRIVE[1] + 0.5)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", 170.0 + 0.6 * k, DRIVE[1] + 0.6, 0.0)
	P.call("tree_torrey_pine_a", "normal", 237.4, -88.0, 15.0)
	P.call("prop_trash_receptacle", "worn", 237.6, -79.2)
	# ---- the alley
	W.lane_wear(dec, rr, -57.0, X0, X1, false, yf)
	dec.add(0, Vector2(200.0, -56.5), 30.0, 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
