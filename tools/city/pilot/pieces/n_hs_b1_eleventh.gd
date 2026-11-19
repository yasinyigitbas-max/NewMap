extends SceneTree
## Piece n_hs_b1_eleventh (high street fill, block 1, part "Eleventh Street"): u -100..-50, v 97.5..190.8, between
## the residential growth on the west (r_q_m200_200_ne), the car park of n_hs_b1_tenth on the north, the alley and
## corner yard of n_hs_b1_amber on the east and 11th St on the south. Placed at grid [0, 4.0, 0], yaw 0. Run once;
## never when locked.
##
## WHY (city planner): the high street has small rear lots and nowhere to leave a car for an afternoon in the shops
## (Yasin: "parking in garages or on the street, not open lots"). The town's PARKING GARAGE stands here, its entrance on
## the pilot's service alley (cars come in off 10th St by the alley and never cross the shopping street); people walk
## out through the paseo beside the library onto Amber. The garage is screened from the houses by a planted bank with
## trees. The residential quadrant's second rear alley (v 140..146) runs through to the service alley. South of it,
## on 11th St (the road toward the beach), two apartment houses on their own level terraces, parking off the alley
## behind, gardens between.
## LAND: 11th St falls 0.8 m from u -50 to u -100 (3.99 -> 3.19); the residential edge on the west is 3.67..3.18.
## The garage pad is level at the high street height 4.15 and the bank comes down to the houses over 17 m (<= 8 %).
## Each 11th St house stands on a level terrace at the walk height of its middle (3.41 and 3.83), with a low retaining
## wall at the front (steps on the paths), on the lot line between them and along the alley parking.
## 19 Nov pass 1: ground only, checked (ground_check / seams). Pass 2: buildings and props.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B1 := preload("res://tools/city/pilot/pieces/n_hs_b1_site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")

const X0 := -100.0
const X1 := -50.0
const ZN := 97.5
const Z_AL0 := 140.0
const Z_AL1 := 146.0
const Z_PARK := 152.0       # end of the parking off the alley, start of the gardens
const XW := -99.5           # inner line of the 0.5 m strip along the residential edge
const XE := -51.0           # inner line of the 1 m strip along n_hs_b1_amber's yard
const XL := -76.0           # lot line between the two houses
const BAND := 0.6           # flush band along the 11th St walk

## the two terraces (world heights): the 11th St walk at the middle of each house's frontage
static func h1() -> float: return B1.f11(-88.0)
static func h2() -> float: return B1.f11(-63.2)

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["tree_coral_b", "normal", -55.8, 155.2, 147.0],
	["tree_magnolia_a", "normal", -78.8, 154.8, 200.0],
	["palm_queen_a", "normal", -97.2, 137.8, 253.0],
	["tree_ficus_b", "normal", -97.2, 127.8, 306.0],
	["tree_jacaranda_b", "normal", -97.2, 103.2, 359.0],
	["tree_coral_a", "normal", -97.2, 116.8, 52.0],
	["plant_iceplant_patch", "normal", -57.8, 159.8, 63.0, false],
	["plant_bougainvillea_mound", "normal", -97.2, 121.8, 134.0, false],
	["prop_sprinkler_impact", "worn", -97.2, 113.8, 205.0, false],
	["plant_bird_of_paradise", "normal", -97.2, 132.2, 276.0, false],
	["prop_sprinkler_popup", "worn", -97.2, 108.8, 347.0, false],
	["plant_agave_americana_small", "normal", -78.8, 159.2, 58.0, false],
	["plant_iceplant_patch", "normal", -73.2, 160.8, 129.0, false],
	["plant_bougainvillea_mound", "normal", -96.8, 160.2, 200.0, false],
	["prop_sprinkler_impact", "worn", -63.2, 162.2, 271.0, false],
	["plant_bird_of_paradise", "normal", -68.2, 162.2, 342.0, false],
	["prop_sprinkler_popup", "worn", -53.8, 162.8, 53.0, false],
	["plant_agave_americana_small", "normal", -83.2, 161.8, 124.0, false],
	["plant_potted_succulent", "normal", -69.2, 155.2, 90.0, false],
	["prop_trash_receptacle", "worn", -62.2, 155.2, 180.0],
	["plant_potted_leafy", "normal", -89.8, 154.2, 270.0, false],
]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b1_eleventh"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var yw := B1.L(B1.g_west)
	var ya := B1.L(B1.g_alley_s)
	var yy := B1.L(B1.g_yard)
	var ystrip := func(_x: float, z: float) -> float: return B1.west(z) - B1.PAD_Y
	var yapron := func(x: float, _z: float) -> float: return B1.g_alley_s(x, Z_AL1) - B1.PAD_Y
	var y1 := func(_x: float, _z: float) -> float: return h1() - B1.PAD_Y
	var y2 := func(_x: float, _z: float) -> float: return h2() - B1.PAD_Y
	var yband := func(x: float, _z: float) -> float: return B1.f11(x) - B1.PAD_Y
	var zfront := func(x: float) -> float: return B1.edge11(x) - BAND
	var e11 := func(x: float) -> float: return B1.edge11(x)
	# ---------------------------------------------------------------- garage block (v 97.5..140) on g_west
	H.paint(g, X0, ZN, X1, Z_AL0, [
		[-51.0, ZN, -50.0, 134.9, "asphalt"],           # the garage's mouth to the alley
		[-83.0, ZN, -51.0, 134.9, "concrete"],          # garage pad (the garage stands on it)
		[-83.0, 134.9, -51.0, 136.9, "plaza"],          # walk along the garage's south side: garage -> alley -> paseo
		[-83.0, 136.9, -51.0, Z_AL0, "mulch"],          # planter on the retaining wall over the alley
	], "grass", yw)
	H.step_face(g, Vector2(X0, Z_AL0), Vector2(X1, Z_AL0), yw, ya)
	# ---------------------------------------------------------------- the alley carried through
	H.paint(g, X0, Z_AL0, X1, Z_AL1, [[X0, 142.6, X1, 143.4, "concrete"]], "asphalt", ya)
	# ---------------------------------------------------------------- 11th St lots
	# west strip on the residential edge, east strip at the corner yard's height
	H.paint(g, X0, Z_AL1, XW, 190.0, [], "grass", ystrip)
	H.band(g, "grass", X0, XW, func(_x: float) -> float: return 190.0, e11, ystrip)
	H.paint(g, XE, Z_AL1, X1, 188.0, [], "grass", yy)
	H.band(g, "grass", XE, X1, func(_x: float) -> float: return 188.0, e11, yy)
	# parking off the alley, nose-in stalls 2.7 m
	var stalls: Array = []
	for z0: float in [-97.6, -74.6]:
		var x := z0
		for k in 8:
			stalls.append([x - 0.05, Z_AL1, x + 0.05, Z_PARK - 0.6, "white"]); x += 2.7
	H.paint(g, XW, Z_AL1, XE, Z_PARK, stalls, "asphalt", yapron)
	# the two terraces: gardens behind, the houses, front gardens with paths to the doors (holes for the steps)
	var fz := 190.8 - BAND           # the front face is straight where the lots front 11th (the slant is east of -54.77)
	var p1 := [[-95.0, fz - 0.3, -93.8, fz, "-"], [-88.8, fz - 0.3, -87.2, fz, "-"], [-82.2, fz - 0.3, -81.0, fz, "-"],
		[-95.0, 187.0, -93.8, fz, "concrete"], [-88.8, 187.0, -87.2, fz, "concrete"], [-82.2, 187.0, -81.0, fz, "concrete"],
		[-97.8, 173.6, -78.4, 187.0, "concrete"], [-95.0, Z_PARK, -84.0, 160.0, "plaza"]]
	H.paint(g, XW, Z_PARK, XL, fz, p1, "grass", y1)
	var p2 := [[-75.4, 174.8, -51.4, 186.0, "concrete"], [-72.0, Z_PARK, -60.0, 160.0, "plaza"]]
	H.paint(g, XL, Z_PARK, XE, 186.0, p2, "grass", y2)
	_front_paths_l2(g, y2, zfront)
	H.band(g, "concrete", XW, XE, zfront, e11, yband, H.STEP, [-54.77])
	# ---------------------------------------------------------------- faces: a retaining wall on every step
	H.step_face(g, Vector2(XW, Z_AL1), Vector2(XW, 190.8), ystrip, func(x: float, z: float) -> float: return float(yapron.call(x, z)) if z < Z_PARK else (float(y1.call(x, z)) if z < fz else float(yband.call(x, z))))
	H.step_face(g, Vector2(XW, Z_PARK), Vector2(XL, Z_PARK), yapron, y1)
	H.step_face(g, Vector2(XL, Z_PARK), Vector2(XE, Z_PARK), yapron, y2)
	H.step_face(g, Vector2(XL, Z_PARK), Vector2(XL, fz), y1, y2)
	H.step_face(g, Vector2(XE, Z_AL1), Vector2(XE, 190.3), yy, func(x: float, z: float) -> float: return float(yapron.call(x, z)) if z < Z_PARK else (float(y2.call(x, z)) if z < float(zfront.call(XE)) else float(yband.call(x, z))))
	# front faces with gaps at the paths, steps in the gaps
	var gaps1 := [[-95.0, -93.8], [-88.8, -87.2], [-82.2, -81.0]]
	var gaps2 := [[-71.2, -69.6], [-64.0, -62.4], [-56.8, -55.2]]
	_front(g, XW, XL, zfront, gaps1, y1, yband)
	_front(g, XL, XE, zfront, gaps2, y2, yband)
	# ---------------------------------------------------------------- skirts under the outer edges
	var wbot := func(_x: float, z: float) -> float: return B1.west_skirt_bot(z)
	H.skirt(g, Vector2(X0, ZN), Vector2(X0, Z_AL0), yw, "wall", wbot)
	H.skirt(g, Vector2(X0, Z_AL0), Vector2(X0, Z_AL1), ya, "wall", wbot)
	H.skirt(g, Vector2(X0, Z_AL1), Vector2(X0, 190.8), ystrip, "wall", wbot)
	var pts := PackedVector2Array([Vector2(X0, 190.8), Vector2(-54.77, 190.8), Vector2(-51.0, 190.3), Vector2(X1, 190.3)])
	for k in pts.size() - 1: H.skirt(g, pts[k], pts[k + 1], func(x: float, z: float) -> float: return float(yband.call(x, z)) if x < XE else float(yy.call(x, z)), "concrete")
	# ================================================================ buildings
	var y0 := 0.15
	K.building(bl, "extras/ext_parking_garage", Vector3(-66.3, y0, 116.45), 90.0, "garage")       # u -81.75..-51.0, v 98.0..134.9; rollup to the alley
	K.building(bl, "apartments/apt_spanish_revival", Vector3(-88.0, h1() - B1.PAD_Y, 180.3), 0.0, "spanish_11th")   # faces 11th; doors u -94.4 / -88 / -81.6
	K.building(bl, "apartments/apt_garden_mint", Vector3(-63.2, h2() - B1.PAD_Y, 180.7), 0.0, "garden_11th")       # faces 11th; doors u -71.2..-55.3
	# ================================================================ props (each with its reason)
	var Pw := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yw, yaw, collide)
	var P1 := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, y1, yaw, collide)
	var P2 := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, y2, yaw, collide)
	var Pa := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yapron, yaw, collide)
	# ---- the garage: bollards guard its mouth, the pay station and a bin where people walk out toward the paseo,
	# bikes parked along its wall
	Pw.call("prop_bollard_steel", "worn", -50.5, 112.25)
	Pw.call("prop_bollard_steel", "worn", -50.5, 120.65)
	Pw.call("prop_pay_station", "worn", -52.6, 135.3, 0.0)
	Pw.call("prop_trash_receptacle", "worn", -54.0, 135.3)
	Pw.call("prop_bike_rack", "worn", -60.0, 135.35, 0.0)
	Pw.call("prop_lamp_globe", "worn", -70.0, 135.3)
	# ---- the bank between the garage and the houses: a screen of eucalyptus, a privet hedge at the garage wall, the
	# neighbours' gardens closed by a privacy fence on the lot line, a fence on top of the wall over the cross alley
	for t: Array in [["tree_eucalyptus_a", -91.5, 103.0], ["tree_eucalyptus_b", -89.8, 114.0], ["tree_eucalyptus_a", -92.0, 125.0], ["tree_eucalyptus_b", -89.5, 135.0]]:
		Pw.call(String(t[0]), "normal", float(t[1]), float(t[2]), float(t[2]) * 3.0)
	H.hedge(props, Vector2(-83.5, 103.8), Vector2(-83.5, 133.0), yw, "hedge_privet_2m")   # open at the garage's back door (v 102.05)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-99.4, 97.0), Vector2(-99.4, 139.41), yw, 2.01)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-99.4, 139.4), Vector2(-83.32, 139.4), yw, 2.01)
	H.hedge(props, Vector2(-83.0, 138.9), Vector2(-51.0, 138.9), yw)          # low hedge in the planter on the wall over the alley
	# ---- the cross alley: a drain in the gutter at its low (west) end
	H.put(props, "prop_storm_drain_grate", "worn", -97.5, 143.0, ya, 0.0, false)
	# ---- parking off the alley: a wheel stop in each stall
	for k in 7:
		Pa.call("prop_wheel_stop_concrete", "worn", -96.25 + 2.7 * k, 151.0, 0.0)
		Pa.call("prop_wheel_stop_concrete", "worn", -73.25 + 2.7 * k, 151.0, 0.0)
	# ---- back fences of the two gardens (on the terrace edge over the parking), each with its gate on the path
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-99.45, 152.25), Vector2(-91.41, 152.25), y1, 2.01)
	P1.call("fence_gate_privacy", "worn", -90.86, 152.25, 0.0)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-90.31, 152.25), Vector2(-76.24, 152.25), y1, 2.01)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-76.0, 152.25), Vector2(-67.96, 152.25), y2, 2.01)
	P2.call("fence_gate_privacy", "worn", -67.41, 152.25, 0.0)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-66.86, 152.25), Vector2(-50.78, 152.25), y2, 2.01)
	# side fences: the neighbours (west), the lot line between the two houses (on the higher terrace), the block wall
	# to the corner yard of n_hs_b1_amber (east; it meets that piece's block wall at v 186.8)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-99.45, 152.25), Vector2(-99.45, 185.3), y1, 2.01)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-75.85, 152.25), Vector2(-75.85, 185.6), y2, 2.01)
	# side-yard returns to the houses' front corners (a gate on house 1's side yard; the rest a shortened panel)
	P1.call("fence_gate_privacy", "worn", -98.9, 185.3, 0.0)
	P1.call("fence_post_privacy", "worn", -98.35, 185.3, 0.0)
	H.short_panel(props, "fence_wood_privacy", Vector2(-98.35, 185.3), Vector2(-97.5, 185.3), y1, 2.01)
	H.short_panel(props, "fence_wood_privacy", Vector2(-75.85, 185.6), Vector2(-74.6, 185.6), y2, 2.01)
	H.fence(props, "fence_stucco_wall", "", Vector2(-50.6, 152.25), Vector2(-50.6, 188.4), yy, 2.03)   # stands on the strip at the yard height
	# ---- house 1 (Spanish revival): garden with a patio (gas grill, table, deck chairs), washing line, a jacaranda;
	# the bins by the back gate; condenser and hose on the sides; front garden planted, mailbox by the main path
	P1.call("prop_bbq_gas_cart", "worn", -93.5, 153.2, 0.0)
	P1.call("prop_patio_set_4", "worn", -91.0, 156.6, 0.0)
	P1.call("prop_adirondack_wood", "worn", -87.0, 158.4, 200.0)
	P1.call("prop_adirondack_wood", "worn", -85.5, 158.4, 160.0)
	for k in 3: P1.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -89.2 + 0.8 * k, 152.95, 180.0)
	P1.call("prop_clothesline", "worn", -80.0, 165.0, 90.0)
	P1.call("tree_jacaranda_a", "normal", -96.4, 167.0, 80.0)
	P1.call("prop_ac_condenser", "worn", -98.6, 177.0, 90.0)
	P1.call("prop_hose_reel_cart", "worn", -77.2, 178.0, 90.0)
	P1.call("plant_bird_of_paradise", "normal", -97.2, 188.4, 0.0, false)
	P1.call("plant_bird_of_paradise", "normal", -90.6, 188.6, 0.0, false)
	P1.call("plant_agave_americana_small", "normal", -84.8, 188.8, 0.0, false)
	P1.call("prop_mailbox_post_metal", "worn", -86.7, 189.6, 0.0)
	for r: Array in [[-99.4, -95.2], [-93.6, -89.0], [-86.2, -82.4], [-80.8, -76.1]]:
		H.hedge(props, Vector2(float(r[0]), 189.85), Vector2(float(r[1]), 189.85), y1)
	# ---- house 2 (garden apartments): table under its own sail, deck chairs, an arbor, a coral tree; bins by the
	# gate; condenser and hose behind; front garden planted, mailbox
	P2.call("prop_picnic_table", "worn", -66.0, 156.6, 0.0)
	P2.call("prop_shade_sail", "worn", -66.0, 156.6, 0.0, false)
	for k in 3: P2.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -65.5 + 0.8 * k, 152.95, 180.0)
	P2.call("prop_adirondack_white", "worn", -58.5, 160.6, 190.0)
	P2.call("prop_adirondack_white", "worn", -57.1, 160.6, 170.0)
	P2.call("prop_garden_arbor", "worn", -56.5, 168.0, 0.0)
	P2.call("tree_coral_a", "normal", -54.0, 156.0, 250.0)
	P2.call("prop_ac_condenser", "worn", -70.0, 174.8, 180.0)
	P2.call("prop_hose_reel_cart", "worn", -60.0, 174.9, 180.0)
	P2.call("plant_agave_americana_small", "normal", -73.5, 188.5, 0.0, false)
	P2.call("plant_bird_of_paradise", "normal", -60.0, 188.5, 0.0, false)
	P2.call("prop_mailbox_post_metal", "worn", -61.9, 189.6, 0.0)
	for r: Array in [[-75.8, -71.4], [-69.4, -64.2], [-61.4, -57.0]]:
		H.hedge(props, Vector2(float(r[0]), 189.85), Vector2(float(r[1]), 189.85), y2)
	# ================================================================ wear (where its cause is)
	var rr := W.rng_for("n_hs_b1_eleventh")
	W.lane_wear(dec, rr, 143.0, X0, X1, false, ya)                                    # the cross alley's drip line
	for x: float in [-96.25, -90.85, -85.45, -82.75, -73.25, -67.85, -65.15, -59.75, -57.05]:
		W.oil(dec, rr, Vector2(x, 148.6), 0.0, yapron, 0.7)                           # residents park here every night
	for c: Array in [[-90.0, 143.5], [-70.0, 142.0], [-60.0, 148.0]]:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, ya, Color(0.14, 0.14, 0.14, 0.9))
	dec.add(14, Vector2(-88.4, 152.95), 0.0, 2.8, 1.3, y1, Color(1, 1, 1, 0.55))      # under the bin carts
	dec.add(14, Vector2(-64.7, 152.95), 0.0, 2.8, 1.3, y2, Color(1, 1, 1, 0.55))
	dec.add(14, Vector2(-60.0, 135.9), 0.0, 20.0, 1.2, yw, Color(1, 1, 1, 0.3))       # the walk out of the garage
	H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b1_eleventh")
	quit()

## front retaining face along the line z = zl(x) from xa to xb (straight, but broken at u -54.77 where the 11th St
## edge turns), open at the path gaps; in each gap the steps between the band (walk height) and the terrace. Treads go
## inward (north) from the face.
func _front(g: K.Ground, xa: float, xb: float, zl: Callable, gaps: Array, ypad: Callable, yband: Callable) -> void:
	var cur := xa
	var spans: Array = []
	for gp: Array in gaps:
		spans.append([cur, float(gp[0])])
		var xc := (float(gp[0]) + float(gp[1])) * 0.5; var w := float(gp[1]) - float(gp[0])
		var fz: float = zl.call(xc)
		H.steps_z(g, xc, w, fz, fz - 2.0, float(yband.call(xc, fz)), float(ypad.call(xc, fz)))
		cur = float(gp[1])
	spans.append([cur, xb])
	for sp: Array in spans:
		var xs: Array = [float(sp[0])]
		if float(sp[0]) < -54.77 and float(sp[1]) > -54.77: xs.append(-54.77)
		xs.append(float(sp[1]))
		for i in xs.size() - 1:
			H.step_face(g, Vector2(xs[i], zl.call(xs[i])), Vector2(xs[i + 1], zl.call(xs[i + 1])), ypad, yband)

## the second terrace's front garden (v 186..front face): paths to the doors in concrete (their last 0.3 m is the
## step), the rest grass
func _front_paths_l2(g: K.Ground, y2: Callable, zfront: Callable) -> void:
	var xs := [XL, -71.2, -69.6, -64.0, -62.4, -56.8, -55.2, XE]
	for i in xs.size() - 1:
		var path := i % 2 == 1
		H.band(g, "concrete" if path else "grass", float(xs[i]), float(xs[i + 1]), func(_x: float) -> float: return 186.0, func(x: float) -> float: return float(zfront.call(x)) - (0.3 if path else 0.0), y2, H.STEP, [-54.77])
