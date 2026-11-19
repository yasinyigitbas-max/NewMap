extends SceneTree
## Piece n_hs_b2_mews (high street fill, block 2, part "Amber Mews"): u -100..-50, v -146..-60, between the residential
## growth on the west, the park's alley (v -60) on the south, the pilot's alley and its extension on the east and
## 9th St's parish hall lot on the north. Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner / architect): the step from the high street to the houses as family TOWNHOUSES, each unit with its own
## garage, on a private mews lane (u -75..-69) that runs from the residents' alley to the second rear alley (v -146..
## -140), both carried through from the houses to the high street's service alley. Three rows a side, garages on the
## lane (tyre marks only at their mouths), small gardens behind with patios and fences, the bins beside the garages.
## LAND: the mews rises 1.2 m to the north (4.15 .. 5.4, about 1.5 %) and a little to the west. The lane follows it;
## each townhouse row stands on its own level pad at the lane's height at its middle, a short driveway ramp to each
## garage, its patio behind on the pad, retaining faces to the gardens and between the rows.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B2 := preload("res://tools/city/pilot/pieces/n_hs_b2_site.gd")

const X0 := -100.0
const X1 := -50.0
const ZN := -146.0
const ZS := -60.0
const LANE := [-75.0, -69.0]
const XA := -140.0            # the cross alley's south edge (alley v -146..-140)
## townhouse rows: [label, folder, yaw, centre u, centre v, pad u0, pad u1 (lane side excluded), v north, v south]
## west rows face the lane (+u, yaw 90), east rows face it (-u, yaw -90)
const ROWS := [
	["th_w1", "apartments/apt_townhouse_cays", 90.0, -81.4, -72.6, -89.4, -76.4, -82.92, -62.28],
	["th_w2", "apartments/apt_townhouse_modern", 90.0, -81.4, -97.6, -89.4, -76.4, -107.32, -87.88],
	["th_w3", "apartments/apt_townhouse_cays", 90.0, -81.4, -122.6, -89.4, -76.4, -132.92, -112.28],
	["th_e1", "apartments/apt_townhouse_modern", -90.0, -62.6, -71.0, -67.6, -54.4, -80.72, -61.28],
	["th_e2", "apartments/apt_townhouse_cays", -90.0, -62.6, -95.5, -67.6, -54.4, -105.82, -85.18],
	["th_e3", "apartments/apt_townhouse_modern", -90.0, -62.6, -120.0, -67.6, -54.4, -129.72, -110.28],
]

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["tree_magnolia_b", "normal", -97.2, -137.8, 129.0],
	["palm_mexican_fan_b", "normal", -97.2, -109.8, 182.0],
	["tree_torrey_pine_b", "normal", -97.2, -85.2, 235.0],
	["tree_jacaranda_a", "normal", -97.2, -99.8, 288.0],
	["tree_coral_b", "normal", -97.2, -63.8, 341.0],
	["tree_magnolia_a", "normal", -97.2, -124.2, 34.0],
	["plant_iceplant_patch", "normal", -97.2, -72.2, 261.0, false],
	["prop_sprinkler_impact", "worn", -97.2, -92.8, 43.0, false],
	["plant_bird_of_paradise", "normal", -97.2, -77.2, 114.0, false],
	["prop_sprinkler_popup", "worn", -97.2, -115.2, 185.0, false],
	["plant_iceplant_patch", "normal", -52.8, -137.8, 327.0, false],
	["plant_bougainvillea_mound", "normal", -65.8, -137.8, 38.0, false],
	["prop_sprinkler_impact", "worn", -58.2, -137.8, 109.0, false],
	["plant_bird_of_paradise", "normal", -91.8, -137.8, 180.0, false],
	["prop_sprinkler_popup", "worn", -93.8, -126.2, 251.0, false],
	["plant_agave_americana_small", "normal", -93.8, -81.2, 322.0, false],
]

func _init() -> void: _run.call_deferred()

## a row's pad: the lane's height at the row's middle (its garages open onto the lane)
static func pad_y(r: Array) -> float:
	var lane_x: float = LANE[0] if float(r[2]) > 0.0 else LANE[1]
	return B2.g(lane_x, float(r[4]))

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b2_mews"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b2_mews")
	var yf := B2.L(B2.g)
	# ================================================================ ground
	var paints: Array = []
	for r: Array in ROWS:
		paints.append([float(r[5]), float(r[7]), float(r[6]), float(r[8]), "-"])          # pad
		var ramp: Array = [-76.4, -75.0] if float(r[2]) > 0.0 else [-69.0, -67.6]
		paints.append([float(ramp[0]), float(r[7]), float(ramp[1]), float(r[8]), "-"])    # driveway ramps
	paints.append_array([
		[LANE[0], XA, LANE[1], ZS, "asphalt"],                 # the mews lane
		[X0, ZN, X1, XA, "asphalt"],                           # the cross alley
		[-89.4, -138.0, -76.4, -134.0, "plaza"],               # a walk from the lane to the west gardens' gates
	])
	paints.push_front([X0, -143.4, X1, -142.6, "concrete"])    # the cross alley's gutter, in line with the houses'
	H.paint(g, X0, ZN, X1, ZS, paints, "grass", yf)
	for r: Array in ROWS:
		var y := pad_y(r) - B2.PAD_Y
		H.level_pad(g, "concrete", float(r[5]), float(r[7]), float(r[6]), float(r[8]), y, yf, "nsw" if float(r[2]) > 0.0 else "nse")
		if float(r[2]) > 0.0: H.ramp_x(g, "concrete", -75.0, -76.4, float(r[7]), float(r[8]), y, yf)
		else: H.ramp_x(g, "concrete", -69.0, -67.6, float(r[7]), float(r[8]), y, yf)
	var wbot := func(_x: float, z: float) -> float: return B2.west_skirt_bot(z)
	H.skirt(g, Vector2(X0, ZN), Vector2(X0, ZS), yf, "wall", wbot)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b2_mews")
	quit()

## footprint half-length along v (cays 19.2, modern 18.0)
static func half(r: Array) -> float: return 9.6 if String(r[1]).ends_with("cays") else 9.0

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for r: Array in ROWS:
		var y := pad_y(r) - B2.PAD_Y
		K.building(bl, String(r[1]), Vector3(float(r[3]), y, float(r[4])), float(r[2]), String(r[0]))
		var yp := func(_x: float, _z: float) -> float: return y
		var west := float(r[2]) > 0.0
		var c: float = r[4]; var hl := half(r)
		# the three bin carts of each row beside its end garage, in the gap (not collection day)
		var bx := -77.6 if west else -66.4
		for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", bx, c - hl - 1.2 - 0.8 * k, 90.0 if west else -90.0)
		# the garden behind: side fences from the back corners to the lot-line fence, a gate in the north one
		var xb := -86.4 if west else -57.6
		var xl := -99.45 if west else -50.55
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(xb, c - hl), Vector2(xl, c - hl), yf, 2.01, "worn", [[2.0 if west else 1.6, 1.2]])
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(xb, c + hl), Vector2(xl, c + hl), yf, 2.01)
		# a condenser on the patio behind each row
		H.put(props, "prop_ac_condenser", "worn", -88.8 if west else -55.0, c + 3.5, yp, 90.0 if west else -90.0)
		# tyre marks at each garage mouth on the lane (turning in), oil on the driveways
		for gx: float in ([-7.85, 1.45, 4.95] if String(r[1]).ends_with("cays") else [-7.25, 1.25, 4.75]):
			var gv: float = c - gx if west else c + gx
			var lx := -74.2 if west else -69.8
			dec.add(8, Vector2(lx, gv), 0.0, 1.0, 2.6, yf, Color(1, 1, 1, 0.3))
			W.oil(dec, rr, Vector2(-75.7 if west else -68.3, gv), 90.0, yf, 0.5)
	# the lot-line fences: the neighbours' gardens (west) and the pilot's alley (east)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-99.45, -63.0), Vector2(-99.45, -132.2), yf, 2.01)    # from the first row's side fence to the last's
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-50.55, -62.0), Vector2(-50.55, -129.0), yf, 2.01)
	# ---- the gardens: each one its own (who lives there: a family with a grill, a gardener, someone who dries washing)
	P.call("prop_patio_set_4", "worn", -93.0, -66.5, 0.0)
	P.call("prop_bbq_kettle", "worn", -91.0, -70.0, 0.0)
	P.call("tree_coral_a", "normal", -96.0, -76.0, 30.0)
	P.call("prop_clothesline", "worn", -94.0, -97.6, 90.0)
	P.call("prop_adirondack_wood", "worn", -90.8, -91.6, 120.0)
	P.call("prop_adirondack_wood", "worn", -90.8, -93.0, 60.0)
	P.call("tree_jacaranda_b", "normal", -96.3, -104.6, 200.0)
	P.call("prop_picnic_table", "worn", -93.5, -118.0, 90.0)
	P.call("prop_shade_sail", "worn", -93.5, -118.0, 90.0, false)
	P.call("prop_bbq_gas_cart", "worn", -90.6, -126.6, 90.0)
	P.call("tree_magnolia_a", "normal", -96.3, -128.8, 80.0)
	P.call("prop_patio_set_4", "worn", -53.2, -66.5, 0.0)
	P.call("plant_bougainvillea_mound", "normal", -52.8, -76.5, 0.0, false)
	P.call("prop_adirondack_white", "worn", -53.0, -92.0, -60.0)
	P.call("prop_hose_reel_cart", "worn", -56.8, -100.2, -90.0)
	P.call("prop_bbq_kettle", "worn", -53.0, -115.0, 0.0)
	P.call("prop_clothesline", "worn", -53.0, -124.0, 90.0)
	# ---- the lane: lamps in the gaps between rows, a hydrant, no parking in the lane (garages on it)
	for l: Array in [[-76.2, -85.4], [-67.8, -83.0], [-76.2, -109.8], [-67.8, -107.9], [-76.2, -136.0]]:
		P.call("prop_lamp_victorian", "worn", float(l[0]), float(l[1]))
	P.call("prop_hydrant_red", "worn", -67.9, -82.0)
	P.call("prop_sign_no_parking", "worn", -76.0, -61.2, 90.0)
	P.call("prop_sign_no_parking", "worn", -68.0, -138.8, -90.0)
	# ---- the cross alley: a drain at its low end
	P.call("prop_storm_drain_grate", "worn", -55.0, -143.0, 0.0, false)
	W.lane_wear(dec, rr, -72.0, -140.0, ZS, true, yf)
	W.lane_wear(dec, rr, -143.0, X0, X1, false, yf)
	for c2: Array in [[-72.0, -75.0], [-72.0, -118.0], [-85.0, -143.0], [-62.0, -144.0]]:
		dec.add(0, Vector2(float(c2[0]), float(c2[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
