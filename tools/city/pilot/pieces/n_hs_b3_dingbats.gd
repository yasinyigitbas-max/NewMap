extends SceneTree
## Piece n_hs_b3_dingbats (high street fill, block 3, part "11th St dingbats"): u -140..-50, v 209.2..254, between 11th
## St (north), the cottages' alley (west), the residents' alley (south, v 254..260) and the Amber shops' rear lot.
## Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner / architect): 11th St is the walk from the town to the beach; the beach town's typical small apartment
## houses line it: four 1950s DINGBATS (two colours, alternating) and a Spanish-style apartment house in the middle,
## each with a front lawn, a fan palm and a path to its doors. Their tenants park behind, nose-in off the residents'
## alley; shared yards behind (washing, a grill, a table, no fences between), bins by the parking.
## LAND: 11th St rises 1.5 m along the row (2.5 at u -140 to 4.0 at u -54). Every lot is a level terrace at the walk
## height of its middle, a 0.6 m band follows the walk, steps on the paths, retaining faces between the terraces;
## the yards and the parking behind follow the block's surface down to the alley.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B3 := preload("res://tools/city/pilot/pieces/n_hs_b3_site.gd")

const X0 := -140.0
const X1 := -50.0
const ZS := 254.0
const ZPARK := 248.0
const ZF := 209.8            # behind the 0.6 m band along 11th St
## [label, folder, x0, x1, centre u, centre v, pad end v, door u list]
const LOTS := [
	["d1", "apartments/apt_dingbat_teal", -139.4, -124.0, -132.0, 221.95, 234.2, [-136.0, -128.0]],
	["d2", "apartments/apt_dingbat_pink", -124.0, -108.0, -116.0, 221.95, 234.2, [-120.0, -112.0]],
	["s3", "apartments/apt_spanish_white", -108.0, -86.0, -97.0, 220.0, 229.3, [-103.4, -97.0, -90.6]],
	["d4", "apartments/apt_dingbat_teal", -86.0, -70.0, -78.0, 221.95, 234.2, [-82.0, -74.0]],
	["d5", "apartments/apt_dingbat_pink", -70.0, -54.0, -62.0, 221.95, 234.2, [-66.0, -58.0]],
]

func _init() -> void: _run.call_deferred()

static func pad_y(l: Array) -> float: return B3.f11(float(l[4]))

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b3_dingbats"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b3_dingbats")
	var yf := B3.L(B3.g)
	var n := func(x: float) -> float: return B3.north(x)
	var zf := func(_x: float) -> float: return ZF
	# ================================================================ ground
	H.band(g, "concrete", X0, X1, n, zf, yf, H.STEP, [-54.77, -51.0])          # band along 11th St, flush with its walk
	var paints: Array = []
	for l: Array in LOTS:
		paints.append([float(l[2]), ZF, float(l[3]), float(l[6]), "-"])
	for k in 33: paints.append([X0 + 1.0 + 2.7 * k - 0.05, ZPARK, X0 + 1.0 + 2.7 * k + 0.05, ZS - 0.5, "white"])
	paints.append_array([
		[X0, ZPARK, X1, ZS, "asphalt"],                     # the tenants' parking, nose-in off the alley
		[-54.0, ZF, X1, ZPARK, "plaza"],                    # the walk from 11th St to the parking and Amber's rear lot
	])
	H.paint(g, X0, ZF, X1, ZS, paints, "grass", yf)
	for l: Array in LOTS:
		var y := pad_y(l) - B3.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		# the terrace: lawn in front, paths to the doors, the building, a paved patio behind
		var lp: Array = []
		for dx: float in l[7]: lp.append([dx - 0.7, ZF + 0.3, dx + 0.7, 214.0, "concrete"])
		lp.append([float(l[2]), float(l[6]) - 3.0, float(l[3]), float(l[6]), "plaza"])
		lp.append([float(l[2]) + 0.5, 213.4, float(l[3]) - 0.5, float(l[6]) - 3.0, "concrete"])
		H.paint(g, float(l[2]), ZF, float(l[3]), float(l[6]), lp, "grass", yp)
		H.step_face(g, Vector2(float(l[2]), float(l[6])), Vector2(float(l[3]), float(l[6])), yp, yf)
		H.step_face(g, Vector2(float(l[2]), ZF), Vector2(float(l[2]), float(l[6])), yp, yf)
		H.step_face(g, Vector2(float(l[3]), ZF), Vector2(float(l[3]), float(l[6])), yp, yf)
		# front face along the band, open at the paths; steps in the openings
		var cur := float(l[2])
		for dx: float in l[7]:
			H.step_face(g, Vector2(cur, ZF), Vector2(dx - 0.7, ZF), yp, yf)
			H.steps_z(g, dx, 1.4, ZF, ZF + 2.0, float(yf.call(dx, ZF)), y)
			cur = dx + 0.7
		H.step_face(g, Vector2(cur, ZF), Vector2(float(l[3]), ZF), yp, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	H.finish(root, g, props, dec, "n_hs_b3_dingbats")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var palms := ["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c", "palm_mexican_fan_a", "palm_mexican_fan_b"]
	var i := 0
	for l: Array in LOTS:
		var y := pad_y(l) - B3.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		K.building(bl, String(l[1]), Vector3(float(l[4]), y, float(l[5])), 180.0, String(l[0]))
		var x0: float = l[2]; var x1: float = l[3]; var c: float = l[4]
		# front lawn: the fan palm (a dingbat street), planting by the doors, the mailbox at the first path
		H.put(props, String(palms[i]), "normal", x1 - 1.6, 211.6, yp, float(i) * 70.0)
		if not String(l[1]).ends_with("spanish_white"): H.put(props, "plant_bird_of_paradise", "normal", x0 + 1.4, 212.3, yp, 0.0, false)
		P.call("prop_mailbox_post_metal", "worn", float(l[7][0]) + 1.05, 209.95, 180.0)          # on the band, at the walk
		if String(l[1]).ends_with("spanish_white"):
			H.put(props, "plant_bougainvillea_mound", "normal", x0 + 2.2, 212.6, yp, 0.0, false)
		# the patio behind (on the terrace): each building its own use
		match i:
			0: H.put(props, "prop_bbq_kettle", "worn", c - 3.0, float(l[6]) - 1.4, yp, 0.0); H.put(props, "prop_adirondack_white", "worn", c + 2.0, float(l[6]) - 1.5, yp, 200.0)
			1: H.put(props, "prop_patio_set_4", "worn", c, float(l[6]) - 1.5, yp, 0.0)
			2: H.put(props, "prop_picnic_table", "worn", c - 4.0, float(l[6]) - 1.5, yp, 0.0); H.put(props, "plant_potted_leafy", "normal", c + 5.0, float(l[6]) - 1.2, yp, 0.0, false)
			3: H.put(props, "prop_bbq_gas_cart", "worn", c + 3.0, float(l[6]) - 1.3, yp, 180.0)
			4: H.put(props, "prop_patio_set_4", "worn", c - 2.5, float(l[6]) - 1.5, yp, 0.0); H.put(props, "plant_potted_succulent", "normal", c + 4.0, float(l[6]) - 0.8, yp, 0.0, false)
		H.put(props, "prop_ac_condenser", "worn", x0 + 0.8, float(l[6]) - 4.0, yp, 90.0)
		# the yard (block surface): washing on one line each, a tree in every other one
		P.call("prop_clothesline", "worn", c, float(l[6]) + 5.0, 0.0)
		if i % 2 == 0: P.call(["tree_coral_b", "tree_jacaranda_a", "tree_magnolia_b"][i / 2], "normal", x0 + 3.0, ZPARK - 3.0, float(i) * 50.0)
		# (the yards behind are shared, as dingbat yards are: no fences between them)
		# a low hedge along the front, open at every path; a hose by the side wall; a bench in the shared yard facing
		# the lawn (the neighbours sit out in the evening)
		var cur := x0 + 0.3
		for dx: float in l[7]:
			if dx - 1.0 - cur >= 2.0: H.hedge(props, Vector2(cur, 210.35), Vector2(dx - 1.0, 210.35), yp)
			cur = dx + 1.5          # (room for the mailbox beside the path)
		if x1 - 2.4 - cur >= 2.0: H.hedge(props, Vector2(cur, 210.35), Vector2(x1 - 2.6, 210.35), yp)
		H.put(props, "prop_hose_reel_cart", "worn", x1 - 0.6, float(l[6]) - 5.0, yp, -90.0)
		P.call("prop_park_bench", "worn", c + 2.5, float(l[6]) + 8.0, 180.0)
		# bins beside the parking at the lot's edge (not collection day)
		for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", x1 - 0.7, ZPARK - 1.0 - 0.8 * k, -90.0)
		i += 1
	# wheel stops in every stall (nose-in from the alley: the stop at the north end), oil
	for k in 32:
		var xc := X0 + 1.0 + 2.7 * k + 1.35
		P.call("prop_wheel_stop_concrete", "worn", xc, ZPARK + 0.6, 0.0)
		if k % 3 != 1: W.oil(dec, rr, Vector2(xc, ZPARK + 2.4), 0.0, yf, 0.6)
	P.call("prop_lot_light_pole", "worn", -96.0, ZPARK - 0.8)
	P.call("prop_lamp_globe", "worn", -53.4, 230.0)
	P.call("prop_bike_rack", "worn", -50.7, 240.0, 90.0)                     # along the walk, out of it
	for c2: Array in [[-120.0, 251.0], [-80.0, 251.0]]:
		dec.add(0, Vector2(float(c2[0]), float(c2[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
