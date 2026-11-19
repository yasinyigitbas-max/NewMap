extends SceneTree
## Piece n_hs_b3_cottages (high street fill, block 3, part "C Ave beach cottages"): u -190.8..-140, v 209.2..Ocean Blvd,
## between C Ave (west), 11th St (north), Ocean Blvd (south) and the dingbats / motel (east). Placed at grid [0, 4.0, 0],
## yaw 0. Run once; never when locked.
##
## WHY (planner): toward C Ave the block meets the beach-cottage houses of the residential growth across the street; it
## continues them: six beach cottages on their own lots facing C Ave, each one different, garages behind on a service
## alley (u -146..-140) that comes in from 11th St's alley mouth and runs down the block; the residents' alley from C
## Ave's alley mouth (v 254..260) crosses it and runs on east to the high street. The beach life in the yards: outdoor
## showers, a kayak rack, deck chairs, washing, a grill.
## LAND: nearly flat (2.15 at C Ave, up to 2.4 by the alley in the north): each lot a level pad at its middle's height,
## retaining faces where it meets the alleys and its neighbours (a few cm to 0.2 m), driveway ramps to the garages.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B3 := preload("res://tools/city/pilot/pieces/n_hs_b3_site.gd")

const X0 := -190.8
const X1 := -140.0
const XB := -190.2           # behind the 0.6 m band along C Ave
const XG := -146.6           # the garages' fronts / the lots' back line (the alley u -146..-140, aprons 0.6 m)
const ALLEY_V := [254.0, 260.0]
const DEAD := 308.0          # the service alley's dead end (a turning stub)
## [label, house, garage, v0, v1, house centre u, house centre v, door v, garage centre v]
const LOTS := [
	["c1", "houses/beach_white", "garages/single_stucco_clay", 209.8, 224.5, -181.8, 217.2, 215.8, 219.5],
	["c2", "houses/craftsman_stucco", "garages/single_siding_comp", 224.5, 239.3, -180.3, 231.9, 234.7, 230.0],
	["c3", "houses/cape_white", "garages/carport_clay", 239.3, 253.4, -182.55, 246.4, 246.4, 247.5],
	["c4", "houses/spanish_peach", "garages/single_stucco_clay", 260.6, 278.4, -181.25, 269.5, 270.9, 266.0],
	["c5", "houses/beach_large", "garages/double_siding_comp", 278.4, 296.2, -179.05, 287.3, 284.9, 290.0],
	["c6", "houses/ranch_porch", "garages/single_siding_comp", 296.2, 0.0, -182.3, 304.9, 303.9, 302.0],
]

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["tree_magnolia_a", "normal", -163.6, 313.4, 154.0],
	["palm_queen_a", "normal", -165.1, 251.9, 207.0],
	["tree_ficus_b", "normal", -164.1, 211.9, 260.0],
	["tree_jacaranda_b", "normal", -165.1, 304.4, 313.0],
	["tree_coral_a", "normal", -160.6, 276.9, 6.0],
	["tree_magnolia_b", "normal", -162.1, 239.4, 59.0],
	["plant_bougainvillea_mound", "normal", -165.1, 308.4, 66.0, false],
	["prop_sprinkler_impact", "worn", -165.1, 246.4, 137.0, false],
	["plant_bird_of_paradise", "normal", -164.6, 216.9, 208.0, false],
	["prop_sprinkler_popup", "worn", -164.1, 271.9, 279.0, false],
	["plant_agave_americana_small", "normal", -158.6, 313.9, 350.0, false],
	["plant_iceplant_patch", "normal", -164.1, 262.4, 61.0, false],
	["plant_bougainvillea_mound", "normal", -142.6, 314.4, 132.0, false],
	["prop_sprinkler_impact", "worn", -163.6, 222.9, 203.0, false],
	["plant_bird_of_paradise", "normal", -163.1, 234.4, 274.0, false],
	["prop_sprinkler_popup", "worn", -153.6, 314.4, 345.0, false],
	["plant_agave_americana_small", "normal", -148.6, 314.4, 56.0, false],
	["plant_iceplant_patch", "normal", -163.6, 227.9, 127.0, false],
]

func _init() -> void: _run.call_deferred()

static func lot_v1(l: Array) -> float: return B3.south(XB) - 0.6 if float(l[4]) == 0.0 else float(l[4])
static func pad_y(l: Array) -> float: return B3.g(-168.0, (float(l[3]) + lot_v1(l)) * 0.5)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b3_cottages"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b3_cottages")
	var yf := B3.L(B3.g)
	var n := func(x: float) -> float: return B3.north(x)
	var sth := func(x: float) -> float: return B3.south(x)
	# ================================================================ ground
	# around the lots (block surface): the C Ave band, the north band, the alleys, the strip on Ocean Blvd
	var holes: Array = []
	for l: Array in LOTS: holes.append([XB, float(l[3]), XG, lot_v1(l), "-"])
	for l: Array in LOTS: holes.append([XG, float(l[8]) - 1.6, -146.0, float(l[8]) + 1.6, "-"])     # garage ramps
	holes.append_array([
		[-146.0, 209.2, X1, DEAD, "asphalt"],              # the service alley
		[X0, ALLEY_V[0], X1, ALLEY_V[1], "asphalt"],        # the residents' alley
		[X0, 209.2, X1, 209.8, "concrete"],                # band along 11th St
		[X0, 209.2, XB, 330.0, "concrete"],                # band along C Ave
	])
	H.paint_band(g, X0, X1, n, sth, holes, "grass", yf)
	for l: Array in LOTS:
		var y := pad_y(l) - B3.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var v0: float = l[3]; var v1 := lot_v1(l)
		# the lot: front garden with its path, the house, the back yard, the garage pad by the alley
		var lp := [[XB + 0.3, float(l[7]) - 0.7, -186.3, float(l[7]) + 0.7, "concrete"],
			[XG - 7.0, float(l[8]) - 1.8, XG, float(l[8]) + 1.8, "concrete"]]
		H.paint(g, XB, v0, XG, v1, lp, "grass", yp)
		H.step_face(g, Vector2(XB, v0), Vector2(XG, v0), yp, yf)
		H.step_face(g, Vector2(XB, v1), Vector2(XG, v1), yp, yf)
		H.step_face(g, Vector2(XB, v0), Vector2(XB, v1), yp, yf)
		H.step_face(g, Vector2(XG, v0), Vector2(XG, float(l[8]) - 1.6), yp, yf)
		H.step_face(g, Vector2(XG, float(l[8]) + 1.6), Vector2(XG, v1), yp, yf)
		H.ramp_x(g, "concrete", -146.0, XG, float(l[8]) - 1.6, float(l[8]) + 1.6, y, yf)
	# skirts on the street edges
	H.skirt(g, Vector2(X0, 209.2), Vector2(X0, B3.south(X0)), yf, "concrete")
	H.skirt(g, Vector2(X0, 209.2), Vector2(X1, 209.2), yf, "concrete")
	H.skirt(g, Vector2(X0, B3.south(X0)), Vector2(X1, B3.south(X1)), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b3_cottages")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var i := 0
	for l: Array in LOTS:
		var y := pad_y(l) - B3.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var v0: float = l[3]; var v1 := lot_v1(l); var dv: float = l[7]; var gv: float = l[8]
		K.building(bl, String(l[1]), Vector3(float(l[5]), y, float(l[6])), -90.0, String(l[0]))
		var gst := K.building_stats(String(l[2]))
		var gd: float = gst.footprint_wd[1]
		K.building(bl, String(l[2]), Vector3(XG - gd * 0.5, y, gv), 90.0, String(l[0]) + "_garage")
		# the lot closed all round: a picket fence on the street with an opening at the path (iron for the Spanish house),
		# the mailbox in the opening; picket on the lot lines in front of the house, privacy behind it; a privacy fence on
		# the alley line meeting the garage's walls. A lot draws its south line (v1); the first of each group its north one.
		var fence := "fence_wrought_iron" if String(l[1]).contains("spanish") else "fence_picket_white"
		var post := "fence_post_wrought_iron" if fence == "fence_wrought_iron" else "fence_post_picket"
		var pl := 1.98 if fence == "fence_wrought_iron" else 2.0
		H.fence(props, fence, post, Vector2(-189.9, v0 + 0.1), Vector2(-189.9, dv - 0.9), yp, pl)
		H.fence(props, fence, post, Vector2(-189.9, dv + 0.9), Vector2(-189.9, v1 - 0.1), yp, pl)
		H.put(props, "prop_mailbox_post_wood", "worn", -189.6, dv - 1.25, yp, -90.0)
		var lines: Array = [v1 - 0.1]
		if i == 0 or i == 3: lines.append(v0 + 0.1)
		for lv: float in lines:
			H.fence(props, fence, post, Vector2(-189.9, lv), Vector2(-186.3, lv), yp, pl)
			H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-186.3, lv), Vector2(XG + 0.1, lv), yp, 2.01)
		var gw: float = (gst.footprint_wd[0] as float) * 0.5 + 0.05
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(XG + 0.1, v0 + 0.1), Vector2(XG + 0.1, gv - gw), yp, 2.01)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(XG + 0.1, gv + gw), Vector2(XG + 0.1, v1 - 0.1), yp, 2.01)
		# planting by the path; one tree in every back yard (kind by owner)
		H.put(props, "plant_bird_of_paradise", "normal", -187.6, (v1 - 2.0) if String(l[1]).ends_with("beach_large") else dv + 2.2, yp, 0.0, false)   # (not before the French doors)
		H.put(props, "plant_agave_americana_small", "normal", -188.0, dv - 2.6, yp, 0.0, false)
		H.put(props, ["tree_coral_a", "tree_jacaranda_b", "tree_magnolia_a", "tree_ficus_b", "tree_coral_b", "tree_torrey_pine_a"][i], "normal", -165.0, v0 + 3.2 if i % 2 == 0 else v1 - 3.2, yp, float(i) * 47.0)
		# the bins beside the garage (not collection day), the condenser on the side, the hose by the back wall
		var cz := gv + gw + 0.6 if gv + gw + 1.2 < v1 else gv - gw - 0.6
		for k in 3: H.put(props, ["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", XG - 1.4 - 0.8 * k, cz, yp, 0.0)
		H.put(props, "prop_ac_condenser", "worn", float(l[5]) + 3.0, v0 + 0.9, yp, 0.0)
		# the beach life in the back yard: each house its own
		match i:
			0: H.put(props, "prop_beach_shower", "worn", -170.5, v1 - 1.2, yp, 0.0); H.put(props, "prop_adirondack_wood", "worn", -172.0, v0 + 5.0, yp, 110.0)
			1: H.put(props, "prop_patio_set_4", "worn", -170.0, (v0 + v1) * 0.5, yp, 0.0); H.put(props, "prop_bbq_kettle", "worn", -167.0, (v0 + v1) * 0.5 + 2.5, yp, 0.0)
			2: H.put(props, "prop_clothesline", "worn", -165.0, (v0 + v1) * 0.5, yp, 0.0)
			3: H.put(props, "prop_kayak_rack", "worn", -171.0, v1 - 1.4, yp, 0.0); H.put(props, "prop_bbq_gas_cart", "worn", -168.0, v0 + 1.0, yp, 0.0)
			4: H.put(props, "prop_beach_shower", "worn", -170.0, v0 + 1.2, yp, 0.0); H.put(props, "prop_adirondack_white", "worn", -167.0, v1 - 4.0, yp, 200.0); H.put(props, "prop_adirondack_white", "worn", -165.6, v1 - 4.0, yp, 160.0)
			5: H.put(props, "prop_patio_set_4", "worn", -169.0, (v0 + v1) * 0.5, yp, 0.0); H.put(props, "prop_garden_arbor", "worn", -175.0, v1 - 2.0, yp, 90.0)
		# oil on the garage apron, a tyre mark where the car turns in from the alley
		W.oil(dec, rr, Vector2(XG - 1.5, gv), 90.0, yp, 0.5)
		dec.add(8, Vector2(-143.0, gv), 90.0, 1.0, 3.0, yf, Color(1, 1, 1, 0.3))
		i += 1
	# the alleys: a drain at the low corner, wear
	P.call("prop_storm_drain_grate", "worn", -143.0, DEAD - 1.5, 0.0, false)
	W.lane_wear(dec, rr, -143.0, 209.2, DEAD, true, yf)
	W.lane_wear(dec, rr, 257.0, X0, X1, false, yf)
