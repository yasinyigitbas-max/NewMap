extends SceneTree
## Piece n_hs_b3_motel (high street fill, block 3, part "Ocean Blvd"): u -140..-50, v 254..Ocean Blvd, between the
## cottages' service alley (west), the residents' alley (north, v 254..260, carried on to the high street's rear lot),
## the beach plaza's rear lot (east) and Ocean Blvd (south). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when
## locked.
##
## WHY (planner): facing the beach across Ocean Blvd, the SEABREEZE MOTEL: its rooms open south onto a lawn with palms,
## loungers and umbrellas, the guests' cars parked behind it off the alley (the boulevard has no driveways). Beside it a
## beach condo with the BEACH RENTALS shop below (bikes, kayaks, umbrellas out on its forecourt), and a public walk
## from the neighbourhood's alley straight down to the beach crossing.
## LAND: falls about 1 m from the high street side to the cottages and 0.5 m to the boulevard (about 1 %); the motel and
## the condo stand on level pads at their fronts' height, the lots and the lawn follow the surface.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B3 := preload("res://tools/city/pilot/pieces/n_hs_b3_site.gd")

const X0 := -140.0
const X1 := -50.0
const ALLEY := [254.0, 260.0]
const MOTEL := [-127.0, 287.4, -86.0, 301.6]      # pad (the building's walkway in front included)
const CONDO := [-84.4, 289.0, -63.6, 304.4]
const LOT := [-132.0, 260.0, -86.0, 286.0]
const CLOT := [-84.0, 260.0, -64.0, 287.6]
const WALK := [-62.0, -58.0]

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["tree_torrey_pine_b", "normal", -52.8, 262.2, 123.0],
	["prop_picnic_table", "worn", -137.2, 262.2, 106.0],
	["tree_coral_b", "normal", -52.8, 271.2, 229.0],
	["prop_picnic_table", "worn", -137.2, 271.2, 0.0],
	["palm_queen_a", "normal", -139.8, 315.2, 335.0],
	["prop_picnic_table", "worn", -52.2, 319.8, 74.0],
	["tree_jacaranda_b", "normal", -94.8, 317.8, 81.0],
	["prop_picnic_table", "worn", -113.2, 316.8, 148.0],
	["plant_bougainvillea_mound", "normal", -52.8, 267.2, 207.0, false],
	["plant_iceplant_patch", "normal", -137.2, 267.2, 278.0, false],
	["prop_sprinkler_popup", "worn", -50.2, 314.8, 349.0, false],
	["plant_agave_americana", "normal", -52.8, 277.2, 60.0, false],
	["plant_bird_of_paradise", "normal", -134.8, 315.2, 131.0, false],
	["plant_bougainvillea_mound", "normal", -100.2, 317.2, 202.0, false],
	["plant_iceplant_patch", "normal", -139.8, 309.8, 273.0, false],
	["prop_sprinkler_popup", "worn", -137.2, 277.2, 344.0, false],
	["plant_agave_americana", "normal", -122.2, 316.2, 55.0, false],
	["plant_bird_of_paradise", "normal", -116.2, 316.2, 126.0, false],
	["plant_potted_succulent", "normal", -73.2, 319.2, 90.0, false],
	["prop_trash_receptacle", "worn", -66.2, 319.2, 180.0],
	["plant_potted_leafy", "normal", -78.8, 318.8, 270.0, false],
	["plant_potted_leafy", "normal", -69.8, 315.2, 0.0, false],
	["prop_park_bench", "worn", -82.2, 314.8, 90.0],
	["prop_bike_rack", "worn", -75.8, 314.8, 180.0],
]

func _init() -> void: _run.call_deferred()

static func motel_y() -> float: return B3.g(-107.0, 301.6)
static func condo_y() -> float: return B3.g(-74.0, 304.4)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b3_motel"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b3_motel")
	var yf := B3.L(B3.g)
	var top := func(_x: float) -> float: return ALLEY[0]
	var sth := func(x: float) -> float: return B3.south(x)
	# ================================================================ ground
	var paints: Array = [[MOTEL[0], MOTEL[1], MOTEL[2], MOTEL[3], "-"], [CONDO[0], CONDO[1], CONDO[2], CONDO[3], "-"]]
	for k in 17:
		var x := LOT[0] + 1.0 + 2.7 * k
		paints.append([x - 0.05, 264.0, x + 0.05, 270.0, "white"]); paints.append([x - 0.05, 276.0, x + 0.05, 282.0, "white"])
	for k in 8: paints.append([CLOT[0] + 0.5 + 2.7 * k - 0.05, 262.0, CLOT[0] + 0.5 + 2.7 * k + 0.05, 267.0, "white"])
	paints.append_array([
		[X0, ALLEY[0], X1, ALLEY[1], "asphalt"],
		[LOT[0], LOT[1], LOT[2], LOT[3], "asphalt"],
		[CLOT[0], CLOT[1], CLOT[2], CLOT[3], "asphalt"],
		[WALK[0], ALLEY[1], WALK[1], 330.0, "plaza"],               # the public walk to the beach crossing
		[-108.5, MOTEL[3], -105.5, 330.0, "plaza"],                 # the motel's path across its lawn to the boulevard
		[CONDO[0], CONDO[3], CONDO[2], 330.0, "plaza"],             # the rentals' forecourt
		[MOTEL[0], 286.0, MOTEL[2], MOTEL[1], "concrete"],          # the motel's back walk (rooms' back doors, the office)
	])
	H.paint_band(g, X0, X1, top, sth, paints, "grass", yf)
	H.level_pad(g, "concrete", MOTEL[0], MOTEL[1], MOTEL[2], MOTEL[3], motel_y() - B3.PAD_Y, yf)
	H.level_pad(g, "concrete", CONDO[0], CONDO[1], CONDO[2], CONDO[3], condo_y() - B3.PAD_Y, yf)
	H.skirt(g, Vector2(X0, B3.south(X0)), Vector2(X1, B3.south(X1)), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b3_motel")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var ym := motel_y() - B3.PAD_Y; var yc := condo_y() - B3.PAD_Y
	K.building(bl, "extras/motel_inn_court", Vector3(-107.0, ym, 294.4), 0.0, "motel")          # rooms open south (front walkway to v 301.0)
	K.building(bl, "apartments/apt_beach_condo", Vector3(-74.0, yc, 296.8), 0.0, "condo")       # the rentals' door at u -74 (front v 304.4)
	# ---- the motel's lawn: loungers in pairs under umbrellas facing the ocean, palms, two picnic tables for the
	# families, a hedge along the boulevard open at the path, lamps along the front walk
	for k in 4:
		var x := -124.0 + 8.5 * k
		if absf(x + 107.0) < 3.0: x += 4.0
		P.call("prop_beach_umbrella", "worn", x, 307.5, 0.0, false)
		P.call("prop_adirondack_white", "worn", x - 1.45, 308.6, 10.0)
		P.call("prop_adirondack_white", "worn", x + 1.45, 308.6, -10.0)
	for t: Array in [["palm_mexican_fan_a", -126.0, 313.0], ["palm_queen_b", -116.0, 304.6], ["palm_mexican_fan_c", -98.0, 304.6], ["palm_mexican_fan_b", -90.0, 313.5]]:
		P.call(String(t[0]), "normal", float(t[1]), float(t[2]), float(t[1]) * 4.0)
	P.call("prop_picnic_table", "worn", -118.0, 313.8, 0.0)
	P.call("prop_picnic_table", "worn", -97.5, 314.4, 0.0)
	P.call("prop_beach_shower", "worn", -110.4, 316.4, 0.0)                       # sand off before going back to the room
	H.hedge(props, Vector2(-138.0, B3.south(-138.0) - 1.1), Vector2(-109.0, B3.south(-109.0) - 1.1), yf)
	H.hedge(props, Vector2(-105.0, B3.south(-105.0) - 1.1), Vector2(-86.0, B3.south(-86.0) - 1.1), yf)
	for x: float in [-122.0, -112.0, -102.0, -92.0]: P.call("prop_lamp_globe", "worn", x, 302.2)
	P.call("prop_trash_receptacle", "worn", -104.6, 302.4)
	H.put(props, "prop_ice_chest", "worn", -87.0, 291.0, func(_x: float, _z: float) -> float: return ym, 90.0)   # the guests' ice, against the building's end wall
	H.put(props, "prop_vending_soda", "worn", -87.0, 293.2, func(_x: float, _z: float) -> float: return ym, 90.0)
	# ---- the guests' lot behind: wheel stops, lights, a golf cart (the motel's runabout), oil
	for k in 16:
		var xc := LOT[0] + 1.0 + 2.7 * k + 1.35
		P.call("prop_wheel_stop_concrete", "worn", xc, 264.6, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", xc, 281.4, 0.0)
		if k % 2 == 0: W.oil(dec, rr, Vector2(xc, 266.5), 0.0, yf, 0.6)
		if k % 3 == 0: W.oil(dec, rr, Vector2(xc, 279.5), 0.0, yf, 0.6)
	P.call("prop_lot_light_pole", "worn", -120.0, 286.6)
	P.call("prop_lot_light_pole", "worn", -98.0, 286.6)
	P.call("prop_dumpster_3yd_green", "worn", -129.8, 287.0, 0.0)                  # the motel's laundry and rooms' rubbish
	P.call("prop_dumpster_3yd_blue", "worn", -132.1, 287.0, 0.0)
	# ---- the rentals' forecourt: kayaks on their rack, umbrellas closed for hire, bikes' rack, a bench for waiting
	P.call("prop_kayak_rack", "worn", -81.0, 307.0, 0.0)
	P.call("prop_kayak_rack", "worn", -67.0, 307.0, 0.0)
	for k in 3: P.call("prop_beach_umbrella_closed", "worn", -78.0 + 0.8 * k, 310.5, 0.0)
	P.call("prop_bike_rack", "worn", -71.5, 311.0, 0.0)
	P.call("prop_park_bench", "worn", -79.0, 313.0, 0.0)
	P.call("plant_potted_succulent", "normal", -75.4, 305.0, 0.0, false)
	P.call("plant_potted_succulent", "normal", -72.6, 305.0, 0.0, false)
	for k in 7: P.call("prop_wheel_stop_concrete", "worn", CLOT[0] + 0.5 + 2.7 * k + 1.35, 262.6, 0.0)
	P.call("prop_dumpster_3yd_blue", "worn", -82.8, 287.8, 0.0)
	for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -65.0 - 0.8 * k, 288.0, 0.0)
	# ---- the public walk to the beach crossing: lamps, a bike rack beside it, a bin at the boulevard end
	for v: float in [270.0, 290.0, 310.0]: P.call("prop_lamp_globe", "worn", WALK[1] + 0.5, v)
	P.call("prop_bike_rack", "worn", WALK[1] + 1.8, 300.0, 90.0)
	P.call("prop_trash_receptacle", "worn", WALK[1] + 0.6, B3.south(-57.4) - 1.0)
	P.call("tree_coral_a", "normal", -54.0, 280.0, 40.0)
	P.call("tree_coral_b", "normal", -54.0, 300.0, 140.0)
	# ---- the alley
	W.lane_wear(dec, rr, 257.0, X0, X1, false, yf)
	for c: Array in [[-120.0, 273.0], [-95.0, 270.0], [-74.0, 280.0]]:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
	dec.add(14, Vector2(-107.0, 309.0), 0.0, 1.6, 14.0, yf, Color(0.78, 0.7, 0.48, 0.3))    # sand trodden up the motel path
