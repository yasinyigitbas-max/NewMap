extends SceneTree
## Piece n_hs_b5_tenth (high street fill, block 5, part "10th St hilltop houses"): u 146..240.8, v 9.2..54, between
## 10th St (north), the pilot's hill row r_s (west), B Ave (east) and the residents' alley (south, v 54..60, in
## n_hs_b5_school / n_hs_b5_hill). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): 10th St climbs from Amber to the hill top as a street of houses (the pilot's r_s / r_n rows); past
## r_s the street goes on as it began: six more houses facing 10th St on 15 m lots, each one different, front lawns
## open to the walk as in the pilot row, private back yards behind wood fences, and - the new thing up here - their
## garages on the residents' alley behind, reached by the service lane from 10th St's alley mouth (u 190..196).
## LAND: the hill top: nearly level (10.1 at the walk, 9.9 at the alley). Each lot a level pad at its middle's height
## (faces of a few cm to 0.2 m at the lot lines), steps where the face crosses the front path.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B5 := preload("res://tools/city/pilot/pieces/n_hs_b5_site.gd")

const X0 := 146.0
const X1 := 240.8
const ZN := 9.2
const ZF := 10.4             # behind the band along 10th St (1.2 m: no lot face next to the walk)
const ZB := 52.0             # the lots' back line (garage doors), a 2 m apron before the alley
const SPUR := [190.0, 196.0] # the service lane from 10th St's alley mouth down to the residents' alley
const FRONT_V := 15.2        # the houses' fronts (6 m front yards, as the pilot row)
## [label, house, garage, x0, x1, house centre u, garage centre u]   houses yaw 180 (face 10th St, model x -> -u)
const LOTS := [
	["t1", "houses/colonial_white", "garages/double_stucco_comp", 146.6, 161.6, 154.1, 156.6],
	["t2", "houses/contemporary_grey", "garages/single_stucco_comp", 161.6, 176.6, 169.1, 172.6],
	["t3", "houses/narrow_cottage_siding", "garages/carport_comp", 176.6, 189.4, 183.0, 185.6],
	["t4", "houses/spanish_large", "garages/single_stucco_clay", 196.6, 211.4, 204.0, 200.6],
	["t5", "houses/cape_large", "garages/single_siding_comp", 211.4, 226.0, 218.7, 222.0],
	["t6", "houses/hipranch_nogarage", "garages/double_siding_comp", 226.0, 238.6, 232.4, 230.0],
]

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["palm_queen_a", "normal", 148.8, 36.4, 151.0],
	["tree_ficus_b", "normal", 235.8, 35.9, 204.0],
	["tree_jacaranda_b", "normal", 165.2, 37.4, 257.0],
	["tree_coral_a", "normal", 211.2, 43.4, 310.0],
	["tree_magnolia_b", "normal", 174.2, 37.4, 3.0],
	["palm_mexican_fan_b", "normal", 187.8, 38.4, 56.0],
	["prop_sprinkler_popup", "worn", 158.2, 35.9, 219.0, false],
	["plant_agave_americana_small", "normal", 171.2, 36.4, 290.0, false],
	["plant_iceplant_patch", "normal", 211.2, 48.4, 1.0, false],
	["plant_bougainvillea_mound", "normal", 153.2, 33.9, 72.0, false],
	["prop_sprinkler_impact", "worn", 179.2, 38.9, 143.0, false],
	["plant_bird_of_paradise", "normal", 231.8, 32.9, 214.0, false],
	["prop_sprinkler_popup", "worn", 230.8, 37.9, 285.0, false],
	["plant_agave_americana_small", "normal", 207.2, 39.9, 356.0, false],
	["plant_iceplant_patch", "normal", 153.2, 38.9, 67.0, false],
	["plant_bougainvillea_mound", "normal", 198.8, 38.9, 138.0, false],
	["prop_sprinkler_impact", "worn", 148.8, 41.4, 209.0, false],
	["plant_bird_of_paradise", "normal", 215.8, 40.9, 280.0, false],
]

func _init() -> void: _run.call_deferred()

static func pad_y(l: Array) -> float: return B5.g((float(l[3]) + float(l[4])) * 0.5, 45.0)     # (nearer the back: the garage aprons gentle)
static func bb(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
static func door_u(l: Array) -> float:
	var df: Array = K.building_stats(String(l[1])).doors_front
	return float(l[5]) - float(df[0][1])
## the back yard's return-fence line: just inside the back of the house's own footprint (stats), not its bbox (porches)
static func vret(l: Array) -> float:
	var hb := bb(String(l[1]))
	var cv := FRONT_V + float(hb[1][2])
	var fd: float = (K.building_stats(String(l[1])).footprint_wd[1] as float) * 0.5
	return cv + fd - 0.3
static func nsteps(l: Array, yf: Callable) -> int:
	var dh := absf(pad_y(l) - B5.PAD_Y - float(yf.call(door_u(l), ZF)))
	return 1 if dh < 0.03 else ceili(dh / 0.17)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b5_tenth"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b5_tenth")
	var yf := B5.L(B5.g)
	# ================================================================ ground
	var paints: Array = []
	for l: Array in LOTS: paints.append([float(l[3]), ZF, float(l[4]), ZB, "-"])
	paints.append_array([
		[SPUR[0], ZN, SPUR[1], B5.ALLEY[0], "asphalt"],    # the service lane
		[X0, ZN, X1, ZF, "concrete"],                       # band along 10th St
		[238.6, ZN, X1, B5.ALLEY[0], "concrete"],           # band along B Ave (2.2 m: no lot face next to the walk)
	])
	H.paint(g, X0, ZN, X1, B5.ALLEY[0], paints, "grass", yf)
	for l: Array in LOTS:
		var y := pad_y(l) - B5.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[3]; var x1: float = l[4]; var du := door_u(l); var gu: float = l[6]
		var ns := nsteps(l, yf)
		var zs := ZF + 0.3 * ns
		var gb := bb(String(l[2]))
		var gw := maxf(-float(gb[0][0]), float(gb[1][0]))
		var lp := [[du - 0.7, ZF, du + 0.7, zs, "-"],
			[du - 0.7, zs, du + 0.7, FRONT_V + 0.2, "concrete"],
			[gu - gw, ZB - 7.0, gu + gw, ZB, "concrete"]]                 # the garage's slab
		H.paint(g, x0, ZF, x1, ZB, lp, "grass", yp)
		H.steps_z(g, du, 1.4, ZF, zs, float(yf.call(du, ZF)), y)
		H.step_face(g, Vector2(x0, ZF), Vector2(du - 0.7, ZF), yp, yf)
		H.step_face(g, Vector2(du + 0.7, ZF), Vector2(x1, ZF), yp, yf)
		# side faces: to the next lot's pad where the lots touch (one face between them), else to the field
		var li := LOTS.find(l)
		var nb: Variant = LOTS[li + 1] if li + 1 < LOTS.size() and absf(float(LOTS[li + 1][3]) - x1) < 0.01 else null
		var pb: Variant = LOTS[li - 1] if li > 0 and absf(float(LOTS[li - 1][4]) - x0) < 0.01 else null
		if pb == null: H.step_face(g, Vector2(x0, ZF), Vector2(x0, ZB), yp, yf)
		if nb == null: H.step_face(g, Vector2(x1, ZF), Vector2(x1, ZB), yp, yf)
		else:
			var yn := pad_y(nb) - B5.PAD_Y
			H.step_face(g, Vector2(x1, ZF), Vector2(x1, ZB), yp, func(_x: float, _z: float) -> float: return yn)
		H.step_face(g, Vector2(x0, ZB), Vector2(gu - 1.8, ZB), yp, yf)
		H.step_face(g, Vector2(gu + 1.8, ZB), Vector2(x1, ZB), yp, yf)
		# the garage apron: from the lot down / up to the alley's edge
		var ya := func(x: float, z: float) -> float: return lerpf(y, float(yf.call(x, B5.ALLEY[0])), (z - ZB) / (B5.ALLEY[0] - ZB))
		H.paint(g, gu - 1.8, ZB, gu + 1.8, B5.ALLEY[0], [], "concrete", ya, 1.0)
		H.step_face(g, Vector2(gu - 1.8, ZB), Vector2(gu - 1.8, B5.ALLEY[0]), ya, yf)
		H.step_face(g, Vector2(gu + 1.8, ZB), Vector2(gu + 1.8, B5.ALLEY[0]), ya, yf)
	H.skirt(g, Vector2(X0, ZN), Vector2(X1, ZN), yf, "concrete")
	H.skirt(g, Vector2(X1, ZN), Vector2(X1, B5.ALLEY[0]), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b5_tenth")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var i := 0
	for l: Array in LOTS:
		var y := pad_y(l) - B5.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[3]; var x1: float = l[4]; var cu: float = l[5]; var du := door_u(l); var gu: float = l[6]
		var hb := bb(String(l[1]))
		var cv := FRONT_V + float(hb[1][2])
		var vb := cv - float(hb[0][2])                           # the house's back wall
		var uw := cu - float(hb[1][0]); var ue := cu - float(hb[0][0])   # its west / east walls
		K.building(bl, String(l[1]), Vector3(cu, y, cv), 180.0, String(l[0]))
		var gb := bb(String(l[2]))
		var gd := float(gb[1][2]) - float(gb[0][2])
		K.building(bl, String(l[2]), Vector3(gu, y, ZB - float(gb[1][2])), 0.0, String(l[0]) + "_garage")
		var gwl := gu + float(gb[0][0]) - 0.05; var gwr := gu + float(gb[1][0]) + 0.05
		# the back yard closed: a return fence from each side wall (the house's own footprint) to the lot line, the lot
		# lines to the alley (a shared line drawn once, from the further-forward of the two yards), the alley line to the
		# garage's sides
		var vr := vret(l)
		var fw: float = (K.building_stats(String(l[1])).footprint_wd[0] as float) * 0.5
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(cu - fw - 0.05, vr), Vector2(x0 + 0.1, vr), yp, 2.01)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(cu + fw + 0.05, vr), Vector2(x1 - 0.1, vr), yp, 2.01)
		var li := LOTS.find(l)
		var vre := vr
		if li + 1 < LOTS.size() and absf(float(LOTS[li + 1][3]) - x1) < 0.01: vre = minf(vr, vret(LOTS[li + 1]))
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(x1 - 0.1, vre), Vector2(x1 - 0.1, ZB - 0.1), yp, 2.01)
		if i == 0 or i == 3: H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(x0 + 0.1, vr), Vector2(x0 + 0.1, ZB - 0.1), yp, 2.01)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(x0 + 0.1, ZB - 0.1), Vector2(gwl, ZB - 0.1), yp, 2.01)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(gwr, ZB - 0.1), Vector2(x1 - 0.1, ZB - 0.1), yp, 2.01)
		# the front: open lawn to the walk as in the pilot row; planting by the path, the mailbox on the band, a street
		# tree in every front yard (alternating kinds along the street)
		P.call("prop_mailbox_post_metal" if i % 2 == 0 else "prop_mailbox_post_wood", "worn", du + 1.1, ZN + 0.35, 180.0)
		H.put(props, "plant_bird_of_paradise", "normal", du - 2.0, FRONT_V - 1.2, yp, 0.0, false)
		H.put(props, "plant_agave_americana_small", "normal", du + 2.4, FRONT_V - 1.6, yp, 0.0, false)
		var tu := x0 + 2.2 if du > (x0 + x1) * 0.5 else x1 - 2.2
		H.put(props, ["tree_jacaranda_a", "tree_coral_b", "tree_magnolia_a", "tree_jacaranda_b", "tree_coral_a", "tree_magnolia_b"][i], "normal", tu, 11.6, yp, float(i) * 53.0)
		if i == 1 or i == 4: H.hedge(props, Vector2(x0 + 0.6, ZF + 0.4), Vector2(du - 1.6, ZF + 0.4), yp)
		# the back yard: each family its own (the bins beside the garage on the yard side, a condenser by the side wall)
		var cy := (vb + ZB - gd) * 0.5
		for k in 3: H.put(props, ["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", (gwr + 0.6 + 0.8 * k) if gwr + 3.0 < x1 else (gwl - 0.6 - 0.8 * k), ZB - 1.0, yp, 0.0)
		H.put(props, "prop_ac_condenser", "worn", uw + 1.0, vret(l) + 0.9, yp, 0.0)       # behind the house, in the yard
		match i:
			0: H.put(props, "prop_patio_set_4", "worn", cu, vb + 2.5, yp, 0.0); H.put(props, "prop_bbq_gas_cart", "worn", cu + 4.0, vb + 1.5, yp, 180.0)
			1: H.put(props, "prop_clothesline", "worn", cu, cy, yp, 0.0); H.put(props, "prop_adirondack_wood", "worn", cu - 4.0, vb + 2.0, yp, 200.0)
			2: H.put(props, "prop_bike_stand", "worn", x0 + 1.2, vb + 2.0, yp, 90.0); H.put(props, "prop_bbq_kettle", "worn", cu + 2.0, vb + 2.0, yp, 0.0)
			3: H.put(props, "prop_garden_arbor", "worn", cu, vb + 3.0, yp, 0.0); H.put(props, "prop_patio_set_4", "worn", cu + 3.0, cy, yp, 0.0)
			4: H.put(props, "prop_swing_set", "worn", cu + 2.0, cy, yp, 0.0); H.put(props, "prop_adirondack_white", "worn", cu - 3.5, vb + 2.0, yp, 160.0)
			5: H.put(props, "prop_clothesline", "worn", cu + 2.0, cy, yp, 90.0); H.put(props, "prop_bbq_kettle", "worn", cu - 3.0, vb + 2.0, yp, 0.0)
		H.put(props, ["tree_ficus_b", "tree_torrey_pine_a", "tree_coral_a", "tree_ficus_a", "tree_jacaranda_a", "tree_coral_b"][i], "normal", x0 + 2.6 if i % 2 == 0 else x1 - 2.6, cy + 2.0, yp, float(i) * 31.0)
		W.oil(dec, rr, Vector2(gu, ZB + 0.3), 0.0, yp, 0.4)
		i += 1
	# the service lane: a drain at its low end, a light at the alley, wear; the corner on B Ave: a fire hydrant
	P.call("prop_storm_drain_grate", "worn", 193.0, 52.5, 0.0, false)
	P.call("prop_lot_light_pole", "worn", 196.3, 30.0)
	W.lane_wear(dec, rr, 193.0, ZN, B5.ALLEY[0], true, yf)
