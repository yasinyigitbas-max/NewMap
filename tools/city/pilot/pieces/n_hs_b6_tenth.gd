extends SceneTree
## Piece n_hs_b6_tenth (high street fill, block 6, part "10th St hilltop houses, north side"): u 146..240.8, v -54..-9.2,
## between the residents' alley (north, v -60..-54, in n_hs_b6_garden / n_hs_b6_hill), the pilot's hill row r_n (west),
## B Ave (east) and 10th St (south). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): the north side of 10th St goes on past the pilot's r_n as it began: six houses facing the street on
## 15 m lots, each different (Tudor, mid-century, a narrow two-storey, Spanish, a ranch, a craftsman), lawns open to
## the walk, private yards behind wood fences, garages on the residents' alley behind (reached by the service lane from
## 10th St's alley mouth at u 190..196) - the answer to block 5's row across the street.
## LAND: the hill top: nearly level (10.1 at the walk, 9.9 - 10.4 at the alley, rising toward B Ave). Each lot a level pad
## near the back (the garage aprons gentle), its front a few cm to 0.3 m off the walk with steps on the path.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B6 := preload("res://tools/city/pilot/pieces/n_hs_b6_site.gd")

const X0 := 146.0
const X1 := 240.8
const ZS := -9.2
const ZF := -10.4            # behind the band along 10th St (1.2 m)
const ZB := -52.0            # the lots' back line (garage doors), a 2 m apron before the alley
const SPUR := [190.0, 196.0]
const FRONT_V := -15.2       # the houses' fronts (6 m front yards)
## [label, house, garage, x0, x1, house centre u, garage centre u]   houses yaw 0 (face 10th St, model x -> +u)
const LOTS := [
	["n1", "houses/tudor_brick", "garages/double_stucco_clay", 146.6, 161.6, 154.1, 156.6],
	["n2", "houses/mcm_large", "garages/single_siding_comp", 161.6, 176.6, 169.1, 172.4],
	["n3", "houses/narrow_2sty_stucco_clay", "garages/carport_clay", 176.6, 189.4, 182.6, 186.0],
	["n4", "houses/spanish_pink", "garages/double_stucco_comp", 196.6, 211.4, 204.0, 201.0],
	["n5", "houses/ranch_siding", "garages/single_stucco_flat", 211.4, 226.0, 218.7, 222.4],
	["n6", "houses/craftsman_cedar", "garages/single_siding_comp", 226.0, 238.6, 232.3, 229.6],
]

func _init() -> void: _run.call_deferred()

static func pad_y(l: Array) -> float: return B6.g((float(l[3]) + float(l[4])) * 0.5, -45.0)
static func bb(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
static func door_u(l: Array) -> float:
	var df: Array = K.building_stats(String(l[1])).doors_front
	return float(l[5]) + float(df[0][1])
static func vret(l: Array) -> float:
	var hb := bb(String(l[1]))
	var cv := FRONT_V - float(hb[1][2])
	var fd: float = (K.building_stats(String(l[1])).footprint_wd[1] as float) * 0.5
	return cv - fd + 0.3
static func nsteps(l: Array, yf: Callable) -> int:
	var dh := absf(pad_y(l) - B6.PAD_Y - float(yf.call(door_u(l), ZF)))
	return 1 if dh < 0.03 else ceili(dh / 0.17)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b6_tenth"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b6_tenth")
	var yf := B6.L(B6.g)
	# ================================================================ ground
	var paints: Array = []
	for l: Array in LOTS: paints.append([float(l[3]), ZB, float(l[4]), ZF, "-"])
	paints.append_array([
		[SPUR[0], B6.ALLEY[1], SPUR[1], ZS, "asphalt"],    # the service lane
		[X0, ZF, X1, ZS, "concrete"],                       # band along 10th St
		[238.6, B6.ALLEY[1], X1, ZS, "concrete"],           # band along B Ave
	])
	H.paint(g, X0, B6.ALLEY[1], X1, ZS, paints, "grass", yf)
	for l: Array in LOTS:
		var y := pad_y(l) - B6.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[3]; var x1: float = l[4]; var du := door_u(l); var gu: float = l[6]
		var ns := nsteps(l, yf)
		var zs := ZF - 0.3 * ns
		var gb := bb(String(l[2]))
		var gw := maxf(-float(gb[0][0]), float(gb[1][0]))
		var lp := [[du - 0.7, zs, du + 0.7, ZF, "-"],
			[du - 0.7, FRONT_V - 0.2, du + 0.7, zs, "concrete"],
			[gu - gw, ZB, gu + gw, ZB + 7.0, "concrete"]]
		H.paint(g, x0, ZB, x1, ZF, lp, "grass", yp)
		H.steps_z(g, du, 1.4, ZF, zs, float(yf.call(du, ZF)), y)
		H.step_face(g, Vector2(x0, ZF), Vector2(du - 0.7, ZF), yp, yf)
		H.step_face(g, Vector2(du + 0.7, ZF), Vector2(x1, ZF), yp, yf)
		var li := LOTS.find(l)
		var nb: Variant = LOTS[li + 1] if li + 1 < LOTS.size() and absf(float(LOTS[li + 1][3]) - x1) < 0.01 else null
		var pb: Variant = LOTS[li - 1] if li > 0 and absf(float(LOTS[li - 1][4]) - x0) < 0.01 else null
		if pb == null: H.step_face(g, Vector2(x0, ZB), Vector2(x0, ZF), yp, yf)
		if nb == null: H.step_face(g, Vector2(x1, ZB), Vector2(x1, ZF), yp, yf)
		else:
			var yn := pad_y(nb) - B6.PAD_Y
			H.step_face(g, Vector2(x1, ZB), Vector2(x1, ZF), yp, func(_x: float, _z: float) -> float: return yn)
		H.step_face(g, Vector2(x0, ZB), Vector2(gu - 1.8, ZB), yp, yf)
		H.step_face(g, Vector2(gu + 1.8, ZB), Vector2(x1, ZB), yp, yf)
		var ya := func(x: float, z: float) -> float: return lerpf(y, float(yf.call(x, B6.ALLEY[1])), (ZB - z) / (ZB - B6.ALLEY[1]))
		H.paint(g, gu - 1.8, B6.ALLEY[1], gu + 1.8, ZB, [], "concrete", ya, 1.0)
		H.step_face(g, Vector2(gu - 1.8, B6.ALLEY[1]), Vector2(gu - 1.8, ZB), ya, yf)
		H.step_face(g, Vector2(gu + 1.8, B6.ALLEY[1]), Vector2(gu + 1.8, ZB), ya, yf)
	H.skirt(g, Vector2(X0, ZS), Vector2(X1, ZS), yf, "concrete")
	H.skirt(g, Vector2(X1, B6.ALLEY[1]), Vector2(X1, ZS), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	H.finish(root, g, props, dec, "n_hs_b6_tenth")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var i := 0
	for l: Array in LOTS:
		var y := pad_y(l) - B6.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[3]; var x1: float = l[4]; var cu: float = l[5]; var du := door_u(l); var gu: float = l[6]
		var hb := bb(String(l[1]))
		var cv := FRONT_V - float(hb[1][2])
		var vb := cv + float(hb[0][2])                           # the house's back wall (north)
		var st := K.building_stats(String(l[1]))
		var fw: float = (st.footprint_wd[0] as float) * 0.5
		K.building(bl, String(l[1]), Vector3(cu, y, cv), 0.0, String(l[0]))
		var gb := bb(String(l[2]))
		var gd := float(gb[1][2]) - float(gb[0][2])
		K.building(bl, String(l[2]), Vector3(gu, y, ZB + float(gb[1][2])), 180.0, String(l[0]) + "_garage")
		var gwl := gu - float(gb[1][0]) - 0.05; var gwr := gu - float(gb[0][0]) + 0.05
		# the back yard closed (as block 5's row): return fences from the footprint's sides, the lot lines (a shared line
		# drawn once, from the further-forward yard) to the alley line, the alley line to the garage's sides
		var vr := vret(l)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(cu - fw - 0.05, vr), Vector2(x0 + 0.1, vr), yp, 2.01)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(cu + fw + 0.05, vr), Vector2(x1 - 0.1, vr), yp, 2.01)
		var li := LOTS.find(l)
		var vre := vr
		if li + 1 < LOTS.size() and absf(float(LOTS[li + 1][3]) - x1) < 0.01: vre = maxf(vr, vret(LOTS[li + 1]))
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(x1 - 0.1, vre), Vector2(x1 - 0.1, ZB + 0.1), yp, 2.01)
		if i == 0 or i == 3: H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(x0 + 0.1, vr), Vector2(x0 + 0.1, ZB + 0.1), yp, 2.01)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(x0 + 0.1, ZB + 0.1), Vector2(gwl, ZB + 0.1), yp, 2.01)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(gwr, ZB + 0.1), Vector2(x1 - 0.1, ZB + 0.1), yp, 2.01)
		# the front: open lawn; planting by the path, the mailbox on the band, a street tree in every front yard
		P.call("prop_mailbox_post_wood" if i % 2 == 0 else "prop_mailbox_post_metal", "worn", du + 1.1, ZS - 0.35, 0.0)
		H.put(props, "plant_bird_of_paradise", "normal", du - 2.0, FRONT_V + 1.2, yp, 0.0, false)
		H.put(props, "plant_agave_americana_small", "normal", du + 2.4, FRONT_V + 1.6, yp, 0.0, false)
		var tu := x0 + 2.2 if du > (x0 + x1) * 0.5 else x1 - 2.2
		H.put(props, ["tree_magnolia_b", "tree_jacaranda_b", "tree_coral_a", "tree_magnolia_a", "tree_jacaranda_a", "tree_coral_b"][i], "normal", tu, -11.6 - 0.4, yp, float(i) * 47.0)
		if i == 2 or i == 5: H.hedge(props, Vector2(x0 + 0.6, ZF - 0.4), Vector2(du - 1.6, ZF - 0.4), yp)
		# the back yard: each family its own (bins beside the garage, a condenser behind the house)
		var cy := (vb + ZB + gd) * 0.5
		for k in 3: H.put(props, ["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", (gwr + 0.6 + 0.8 * k) if gwr + 3.0 < x1 else (gwl - 0.6 - 0.8 * k), ZB + 1.0, yp, 180.0)
		H.put(props, "prop_ac_condenser", "worn", cu - fw + 1.0, vr - 0.9, yp, 0.0)
		match i:
			0: H.put(props, "prop_patio_set_4", "worn", cu + 2.0, vb - 2.5, yp, 0.0); H.put(props, "prop_bbq_kettle", "worn", cu + 5.0, vb - 1.6, yp, 0.0)
			1: H.put(props, "prop_swing_set", "worn", cu, cy, yp, 0.0); H.put(props, "prop_adirondack_white", "worn", cu + 4.0, vb - 2.0, yp, 20.0)
			2: H.put(props, "prop_clothesline", "worn", cu, cy, yp, 90.0)
			3: H.put(props, "prop_patio_set_4", "worn", cu, vb - 2.8, yp, 0.0); H.put(props, "prop_garden_arbor", "worn", cu + 4.0, cy, yp, 0.0)
			4: H.put(props, "prop_bbq_gas_cart", "worn", cu + 3.0, vb - 1.5, yp, 0.0); H.put(props, "prop_clothesline", "worn", cu - 1.0, cy, yp, 0.0)
			5: H.put(props, "prop_adirondack_wood", "worn", cu + 2.0, vb - 2.0, yp, 200.0); H.put(props, "prop_adirondack_wood", "worn", cu + 3.4, vb - 2.0, yp, 160.0)
		H.put(props, ["tree_ficus_a", "tree_coral_b", "tree_torrey_pine_a", "tree_ficus_b", "tree_jacaranda_b", "tree_coral_a"][i], "normal", x0 + 2.6 if i % 2 == 1 else x1 - 2.6, cy - 2.0, yp, float(i) * 29.0)
		W.oil(dec, rr, Vector2(gu, ZB - 0.3), 0.0, yp, 0.4)
		i += 1
	P.call("prop_storm_drain_grate", "worn", 193.0, -52.5, 0.0, false)
	P.call("prop_lot_light_pole", "worn", 196.3, -30.0)
	W.lane_wear(dec, rr, 193.0, B6.ALLEY[1], ZS, true, yf)
