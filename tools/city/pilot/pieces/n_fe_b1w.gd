extends SceneTree
## Piece n_fe_b1w (fe fill, block 1 west): CROWN HILL GARDENS, garden apartments round a court.
## u 259 (the u 250 street's east walk) .. 375 (n_fe_b1e), v -900 (the residential quadrant r_q_250_m1000_se) .. -809
## (the -800 street's north walk). Placed at grid [0, 4.0, 0], yaw 0. Run once.
##
## WHY (planner): the apartment band (ZONING.md "apt", v -880 .. -300) begins here, across the -800 street from the
## apartment blocks n_apt_b1_*; north of it are the houses of the residential quadrant. So: low garden apartments (two
## storeys, the height of the houses behind) for the people who work in the strip and the hospital, a short walk from
## both. Who comes: residents (cars, bikes, on foot to the u 250 street's bus side), their visitors, the bin lorry.
## Cars in ONLY at the two existing aprons: the u 250 street's (v -860 .. -854) and the -800 street's (u 304 .. 310).
## They meet in a T of drives with the residents' stalls on both sides; the bin enclosure stands at the drive's end.
##  - SOUTH ROW on the -800 street (fronts and front gardens to the street, like the apartments across it):
##    A1 apt_garden_cream, A2 apt_garden_mint, A3 apt_court_white
##  - NORTH ROW on the drive (fronts to the stalls, backs to the houses' yards): N1 apt_spanish_revival, N2 apt_spanish_white
##  - THE COURT between the rows: lawn, picnic tables and grills, washing lines, benches; the residents' TOT LOT in the
##    north-east corner (swings, slide, play structure on bark under a sail), where parents on the court can see it.
## LAND (Yasin: "DONT FORGET TO TAKE THE LAND INTO CONSIDERATION"): 5.6 .. 6.1 here, falling gently to the north-east;
## the ground follows it (n_fe_site.g "b1"), eased onto every walk; each building on a level pad at the highest ground
## under it, the field graded up to it at 6 %.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fe_site.gd")

const X0 := 259.0
const X1 := 375.0
const Z0 := -900.0
const Z1 := -809.0
## [label, folder, centre u, centre v, yaw]
const B := [
	["a1", "apartments/apt_garden_cream", 279.0, -820.1, 0.0],        # front on the -800 street at v -814
	["a2", "apartments/apt_garden_mint", 333.0, -820.1, 0.0],
	["a3", "apartments/apt_court_white", 361.0, -820.1, 0.0],
	["n1", "apartments/apt_spanish_revival", 283.0, -875.0, 0.0],     # front on the stalls at v -868.5
	["n2", "apartments/apt_spanish_white", 325.0, -875.0, 0.0],
]
const DRIVE := [-861.0, -853.0]          # the east-west drive from the u 250 street's apron (v)
const LEG := [303.0, 311.0]              # the leg from the -800 street's apron (u)
const TOT := [349.0, -897.0, 373.0, -870.0]   # the tot lot's bark (u0, v0, u1, v1)

## ITEMS: [base, cond, u, v, yaw(, collide)] standing on the ground as built; each group with its reason
const ITEMS := [
	# the court (behind the south row): two picnic tables with a kettle grill each, where the back doors open; washing
	# lines on the lawn's sunny middle; benches on the court path facing the lawn
	["prop_picnic_table", "worn", 276.0, -836.0, 90.0], ["prop_bbq_kettle", "worn", 276.0, -839.2, 0.0],
	["prop_picnic_table", "worn", 330.0, -836.0, 90.0], ["prop_bbq_gas_cart", "worn", 333.6, -836.0, 90.0],
	["prop_clothesline", "worn", 292.0, -840.0, 0.0], ["prop_clothesline", "worn", 352.0, -840.0, 0.0],
	["prop_park_bench", "worn", 287.0, -833.2, 0.0], ["prop_park_bench", "worn", 344.0, -833.2, 0.0],
	["prop_adirondack_wood", "worn", 365.0, -836.0, 200.0], ["prop_adirondack_white", "worn", 367.4, -837.2, 160.0],
	["prop_sprinkler_impact", "normal", 300.0, -838.0, 0.0, false], ["prop_sprinkler_impact", "normal", 320.0, -840.0, 0.0, false],
	# the tot lot: play structure, swings and slide on the bark, a shade sail over the sand-pit side, benches for the
	# parents on its west edge facing in, a bin against the enclosure fence
	["prop_play_structure", "worn", 361.0, -886.0, 0.0], ["prop_swing_set", "worn", 366.5, -876.5, 0.0],
	["prop_slide", "worn", 354.5, -890.5, 90.0],
	["prop_park_bench", "worn", 346.6, -884.0, 90.0], ["prop_park_bench", "worn", 346.6, -877.0, 90.0],
	# the back gardens of the north row (lawn to the quadrant's yards): chairs and a grill by the back doors
	["prop_adirondack_wood", "worn", 279.0, -886.0, 180.0], ["prop_adirondack_white", "worn", 281.4, -886.6, 200.0],
	["prop_bbq_kettle", "worn", 330.0, -885.5, 0.0], ["prop_patio_set_4", "worn", 321.0, -886.5, 0.0],
	["prop_sprinkler_impact", "normal", 300.0, -892.0, 0.0, false],
	# front gardens on the -800 street: low planting between the door paths
	["plant_bird_of_paradise", "normal", 275.0, -811.8, 0.0], ["plant_agave_americana_small", "normal", 283.0, -811.8, 0.0],
	["plant_bird_of_paradise", "normal", 329.0, -811.8, 0.0], ["plant_agave_americana_small", "normal", 337.0, -811.8, 0.0],
	["plant_iceplant_patch", "normal", 352.6, -811.8, 0.0, false], ["plant_iceplant_patch", "normal", 369.4, -811.8, 0.0, false],
]

const SC := {"out": [], "turn": [], "decals": [], "boxes": []}

var PY: Array = []

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
## footprint [u0, v0, u1, v1] of one row of B (yaw 0 / 90 / 180 / -90)
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]   # yaw -90

func _run() -> void:
	var root := Node3D.new(); root.name = "n_fe_b1w"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fe_b1w")
	var yb := func(x: float, z: float) -> float: return S.y("b1", x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yf := H.graded(yb, pe)
	# the stall rows as their own patches (their lines cut only their own cells): north row u 266 .. 344.6, south row
	# u 266 .. 301.1 and 312.9 .. 344.6 (the leg between)
	var ln: Array = []; var ls: Array = []
	for k in 30: ln.append([266.0 + 2.7 * k - 0.05, -866.5, 266.0 + 2.7 * k + 0.05, -861.0, "white"])
	for k in 14: ls.append([266.0 + 2.7 * k - 0.05, -853.0, 266.0 + 2.7 * k + 0.05, -847.5, "white"])
	for k in 12: ls.append([312.9 + 2.7 * k - 0.05, -853.0, 312.9 + 2.7 * k + 0.05, -847.5, "white"])
	var regions := [[266.0, -866.5, 344.6, -861.0, "asphalt", ln], [266.0, -853.0, 301.1, -847.5, "asphalt", ls.slice(0, 14)],
		[312.9, -853.0, 344.6, -847.5, "asphalt", ls.slice(14)]]
	var paints: Array = []
	for r: Array in regions: paints.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append_array([
		[TOT[0], TOT[1], TOT[2], TOT[3], "mulch"],              # the tot lot's bark
		[X0, -861.5, 262.0, -852.5, "concrete"],                 # the drive's mouth at the apron (flares)
		[X0, DRIVE[0], 346.0, DRIVE[1], "asphalt"],              # the drive
		[LEG[0], DRIVE[1], LEG[1], Z1, "asphalt"],               # the leg to the -800 street's apron
		[346.0, -862.0, 353.0, -852.0, "concrete"],              # the bin enclosure's pad at the drive's end
		[264.0, -868.5, 346.0, -866.5, "plaza"],                 # the north row's front walk (stall heads)
		[262.0, -847.5, 346.0, -845.5, "plaza"],                 # the court walk behind the south stalls
		[X0, -847.5, 262.0, -824.0, "plaza"],                    # the walk from the u 250 street into the court
		[311.0, -845.5, 313.0, -826.0, "plaza"],                 # the court walk along the leg
		[262.0, -832.0, 372.0, -830.5, "plaza"],                 # the court's east-west path (back doors)
		[358.0, -870.0, 360.0, -845.5, "plaza"],                 # the walk up to the tot lot (east of the bin pad)
		[X0, -811.0, X1, -809.0, "plaza"],                       # the front walk along the -800 street
	])
	# front paths from the -800 street to the south row's doors (door pairs at along -7.2 / 0 / 7.2; court_white -4.2 / 4.2)
	for cu: float in [279.0, 333.0]:
		for a: float in [-7.2, 0.0, 7.2]: paints.append([cu + a - 1.0, -814.0, cu + a + 1.0, -811.0, "plaza"])
	for a: float in [-4.2, 4.2]: paints.append([361.0 + a - 1.0, -814.0, 361.0 + a + 1.0, -811.0, "plaza"])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	H.paint(g, X0, Z0, X1, Z1, paints, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fe_b1w")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the drives: wheel stops at every stall head, a lot light each side, stop signs where cars leave at the aprons,
	#      no-parking on the leg (the bin lorry's way)
	for k in 29: P.call("prop_wheel_stop_concrete", "worn", 267.35 + 2.7 * k, -865.9, 0.0)
	for k in 13: P.call("prop_wheel_stop_concrete", "worn", 267.35 + 2.7 * k, -848.1, 0.0)
	for k in 11: P.call("prop_wheel_stop_concrete", "worn", 314.25 + 2.7 * k, -848.1, 0.0)
	P.call("prop_lot_light_pole", "worn", 263.0, -864.0, 90.0)       # on the grass at the stall row's west end
	P.call("prop_lot_light_pole", "worn", 302.0, -850.0, 0.0)        # on the grass strip beside the leg
	P.call("prop_sign_stop", "worn", 261.0, -852.1, -90.0)          # leaving at the u 250 street's apron
	P.call("prop_sign_stop", "worn", 312.0, -811.6, 180.0)          # leaving at the -800 street's apron
	P.call("prop_sign_no_parking", "worn", 302.2, -840.0, 90.0)
	for xx: float in [275.45, 299.75, 334.85]: W.oil(dec, rr, Vector2(xx, -863.75), 0.0, yf, 0.5)
	for xx: float in [280.85, 327.75]: W.oil(dec, rr, Vector2(xx, -850.25), 0.0, yf, 0.5)
	W.lane_wear(dec, rr, -857.0, 262.0, 344.0, false, yf)
	# ---- the bin pad at the drive's end, where the lorry turns: the residents' dumpster and recycling
	P.call("prop_dumpster_3yd_green", "worn", 350.6, -858.8, -90.0)
	P.call("prop_dumpster_3yd_blue", "worn", 350.6, -855.6, -90.0)
	# ---- the mailboxes for all five buildings where everyone passes: on the leg's court walk, by the -800 street
	for k in 4: P.call("prop_mailbox_post_metal", "worn", 313.8, -826.6 - 0.6 * k, 90.0)
	# ---- the buildings: condensers at the ends of each, bike racks by the north row's lobbies, a bin and lamps on walks
	P.call("prop_ac_condenser", "worn", 265.6, -822.0, 90.0); P.call("prop_ac_condenser", "worn", 292.4, -822.0, -90.0)
	P.call("prop_ac_condenser", "worn", 319.6, -822.0, 90.0); P.call("prop_ac_condenser", "worn", 349.0, -822.0, 90.0)
	P.call("prop_ac_condenser", "worn", 271.0, -879.0, 90.0); P.call("prop_ac_condenser", "worn", 337.6, -879.0, -90.0)
	P.call("prop_bike_rack", "worn", 270.4, -873.0, 90.0); P.call("prop_bike_rack", "worn", 338.0, -873.0, 90.0)
	P.call("prop_trash_receptacle", "worn", 346.0, -832.6, 0.0)
	for x: float in [272.0, 300.0, 340.0]: P.call("prop_lamp_globe", "worn", x, -844.8)
	for x: float in [288.0, 318.0, 352.0]: P.call("prop_lamp_globe", "worn", x, -829.8)
	P.call("prop_lamp_victorian", "worn", 300.0, -811.6); P.call("prop_lamp_victorian", "worn", 348.0, -811.6)
