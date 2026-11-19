extends SceneTree
## Piece n_hs_b6_ninth (high street fill, block 6, part "9th St: rec center and flats"): u 50..125, v 9th St..-146,
## between 9th St (north), the Amber shops' rear lot (west), the residential quarter r_q_250_m200_sw (east) and the
## parking aisle (south, in n_hs_b6_hill). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): 9th St climbs east from Amber to the residential quarter. At its foot, the HILL REC CENTER (the hall,
## classes, the after-school club for the hill's children), its forecourt on 9th St; then the HILLTOP MARKET under three
## storeys of flats - the corner shop the hill walks to - and a modern apartment row, each on its own terrace up the
## street; parking behind off the aisle.
## LAND: 9th St rises 2.6 m along the piece (6.44 -> 9.08). The rec center on a pad at its door's walk height, each
## apartment house on a terrace at the walk height of its middle (a retaining wall of ~0.9 m between the two, steps on
## every path); the yards and the stalls follow the surface; r_q's lot line met by an edge strip at its heights.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B6 := preload("res://tools/city/pilot/pieces/n_hs_b6_site.gd")

const X0 := 50.0
const X1 := 125.0
const ZS := -146.0
const ZF := -189.6           # behind the band along 9th St
const ZT := -166.0           # the terraces' back line
const FRONT_V := -184.0      # the buildings' fronts
const RC := [52.0, FRONT_V, 78.4, -163.6]    # the rec center's pad
const RC_C := Vector2(65.0, -173.05)         # yaw 180 (faces 9th St); door at u 65
## [label, folder, x0, x1, centre u, model z max, [path offsets (model x)], path width]   yaw 180 (model x -> -u)
const LOTS := [
	["a1", "apartments/apt_stucco3_cream", 80.0, 101.0, 90.5, 8.1, [0.0], 2.4],
	["a2", "ck/ck_apt3_row3", 101.0, 122.6, 112.0, 6.0, [-6.0, 0.0, 6.0], 1.4],
]

func _init() -> void: _run.call_deferred()

static func pad_y(l: Array) -> float: return B6.n9(float(l[4]))
static func rc_y() -> float: return B6.g(RC_C.x, FRONT_V)
static func path_us(l: Array) -> Array:
	var r: Array = []
	for dx: float in l[6]: r.append(float(l[4]) - dx)
	r.sort()
	return r

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b6_ninth"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b6_ninth")
	var yf := B6.L(B6.g)
	var yr := rc_y() - B6.PAD_Y
	var yrp := func(_x: float, _z: float) -> float: return yr
	# ================================================================ ground
	H.band(g, "concrete", X0, X1, func(x: float) -> float: return B6.north9(x), func(_x: float) -> float: return ZF, yf, H.STEP, [51.0, 54.77])
	var holes: Array = H.edge_strip(g, "v", X1, -2.0, B6.Lseg([[ZF, -154.0, 9.36, 9.36], [-154.0, ZS, 8.805, 8.776]]), yf, "grass", false)
	holes.append([RC[0], RC[1], RC[2], RC[3], "-"])
	for l: Array in LOTS: holes.append([float(l[2]), ZF, float(l[3]), ZT, "-"])
	for k in 15: holes.append([82.0 + 2.7 * k - 0.05, ZS - 5.5, 82.0 + 2.7 * k + 0.05, ZS, "white"])
	for k in 9: holes.append([54.0 + 2.7 * k - 0.05, ZS - 5.5, 54.0 + 2.7 * k + 0.05, ZS, "white"])
	holes.append_array([
		[82.0, ZS - 6.0, 119.8, ZS, "asphalt"],                   # the tenants' stalls, nose-in off the aisle
		[54.0, ZS - 6.0, 75.6, ZS, "asphalt"],                    # the rec center's stalls
		[52.6, ZF, 77.8, FRONT_V, "plaza"],                       # the rec center's forecourt
	])
	H.paint(g, X0, ZF, X1, ZS, holes, "grass", yf)
	H.level_pad(g, "concrete", RC[0], RC[1], RC[2], RC[3], yr, yf)
	for l: Array in LOTS:
		var y := pad_y(l) - B6.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[2]; var x1: float = l[3]; var w: float = l[7]
		var lp: Array = []
		var ns: Array = []
		for pu: float in path_us(l):
			var dh := absf(y - float(yf.call(pu, ZF)))
			var n := 1 if dh < 0.03 else ceili(dh / 0.17)
			ns.append(n)
			lp.append([pu - w * 0.5, ZF, pu + w * 0.5, ZF + 0.3 * n, "-"])
			lp.append([pu - w * 0.5, ZF + 0.3 * n, pu + w * 0.5, FRONT_V + 0.2, "concrete"])
		lp.append([x0, ZT - 3.0, x1, ZT, "plaza"])
		H.paint(g, x0, ZF, x1, ZT, lp, "grass", yp)
		H.step_face(g, Vector2(x0, ZT), Vector2(x1, ZT), yp, yf)
		var li := LOTS.find(l)
		if li == 0: H.step_face(g, Vector2(x0, ZF), Vector2(x0, ZT), yp, yf)
		if li == LOTS.size() - 1: H.step_face(g, Vector2(x1, ZF), Vector2(x1, ZT), yp, yf)
		else:
			var yn := pad_y(LOTS[li + 1]) - B6.PAD_Y
			H.step_face(g, Vector2(x1, ZF), Vector2(x1, ZT), yp, func(_x: float, _z: float) -> float: return yn)
		var cur := x0
		var j := 0
		for pu: float in path_us(l):
			H.step_face(g, Vector2(cur, ZF), Vector2(pu - w * 0.5, ZF), yp, yf)
			H.steps_z(g, pu, w, ZF, ZF + 0.3 * int(ns[j]), float(yf.call(pu, ZF)), y)
			cur = pu + w * 0.5
			j += 1
		H.step_face(g, Vector2(cur, ZF), Vector2(x1, ZF), yp, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf, yrp)
	H.finish(root, g, props, dec, "n_hs_b6_ninth")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, yrp: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	K.building(bl, "civic/civ_rec_center", Vector3(RC_C.x, float(yrp.call(0.0, 0.0)), RC_C.y), 180.0, "rec_center")
	# ---- the rec center's forecourt: bike racks for the children, benches for waiting parents, a tree in the lawn
	# strip, lamps, bins, the drinking fountain
	for x: float in [55.0, 58.0]: P.call("prop_bike_rack", "worn", x, -187.4, 0.0)
	for x2: float in [71.0, 75.0]: P.call("prop_park_bench", "worn", x2, -188.6, 180.0)
	P.call("prop_drinking_fountain", "worn", 61.0, -188.8, 180.0)
	P.call("prop_trash_receptacle", "worn", 69.0, -188.8)
	P.call("prop_lamp_globe", "worn", 52.8, -185.0)
	P.call("prop_lamp_globe", "worn", 77.4, -185.0)
	H.put(props, "prop_dumpster_3yd_blue", "worn", 77.0, -162.6, yrp, 90.0)
	for k in 8:
		var xs := 54.0 + 2.7 * k + 1.35
		P.call("prop_wheel_stop_concrete", "worn", xs, ZS - 5.0, 0.0)
		if k % 3 == 1: W.oil(dec, rr, Vector2(xs, ZS - 3.4), 0.0, yf, 0.5)
	# ---- the apartment houses: lawns, a tree each, planting by the paths, the market's newspaper boxes and an ice
	# chest by its door, mailboxes on the band; patios behind; shared yards with washing; bins at the stalls
	var i := 0
	for l: Array in LOTS:
		var y := pad_y(l) - B6.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[2]; var x1: float = l[3]; var c: float = l[4]
		K.building(bl, String(l[1]), Vector3(c, y, FRONT_V + float(l[5])), 180.0, String(l[0]))
		var pus := path_us(l)
		var w: float = l[7]
		H.put(props, ["tree_coral_a", "palm_mexican_fan_a"][i], "normal", x1 - 1.8, -187.4, yp, float(i) * 50.0)
		P.call("prop_mailbox_post_metal", "worn", float(pus[0]) - w * 0.5 - 0.35, -190.0, 180.0)
		if i == 0:
			H.put(props, "prop_newspaper_box_blue", "worn", c + 2.2, FRONT_V - 0.6, yp, 180.0)
			H.put(props, "prop_ice_chest", "worn", c - 2.4, FRONT_V - 0.6, yp, 180.0)
			H.put(props, "plant_potted_succulent", "normal", c + 3.4, FRONT_V - 0.6, yp, 0.0, false)
		else:
			H.put(props, "plant_bird_of_paradise", "normal", float(pus[0]) - w * 0.5 - 1.0, FRONT_V - 1.0, yp, 0.0, false)
			H.put(props, "plant_agave_americana_small", "normal", float(pus[pus.size() - 1]) + w * 0.5 + 1.2, FRONT_V - 1.2, yp, 0.0, false)
		var cur := x0 + 0.3
		for pu: float in pus:
			if pu - w * 0.5 - 0.8 - cur >= 2.0: H.hedge(props, Vector2(cur, ZF + 0.55), Vector2(pu - w * 0.5 - 0.8, ZF + 0.55), yp)
			cur = pu + w * 0.5 + 0.5
		if x1 - 2.8 - cur >= 2.0: H.hedge(props, Vector2(cur, ZF + 0.55), Vector2(x1 - 2.8, ZF + 0.55), yp)
		match i:
			0: H.put(props, "prop_dumpster_3yd_green", "worn", c + 6.0, ZT - 1.4, yp, 0.0); H.put(props, "prop_picnic_table", "worn", c - 4.0, ZT - 1.5, yp, 0.0)
			1: H.put(props, "prop_patio_set_4", "worn", c - 3.0, ZT - 1.5, yp, 0.0); H.put(props, "prop_bbq_gas_cart", "worn", c + 4.0, ZT - 1.3, yp, 180.0)
		H.put(props, "prop_ac_condenser", "worn", x0 + 0.9, ZT - 4.0, yp, 90.0)
		P.call("prop_clothesline", "worn", c, ZT + 6.0, 0.0)
		for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", x1 - 0.7 - 0.8 * k, ZS - 6.8, 0.0)
		i += 1
	for k in 14:
		var xc := 82.0 + 2.7 * k + 1.35
		P.call("prop_wheel_stop_concrete", "worn", xc, ZS - 5.0, 0.0)
		if k % 3 != 2: W.oil(dec, rr, Vector2(xc, ZS - 3.4), 0.0, yf, 0.6)
	P.call("prop_lot_light_pole", "worn", 101.0, ZS - 6.6)
