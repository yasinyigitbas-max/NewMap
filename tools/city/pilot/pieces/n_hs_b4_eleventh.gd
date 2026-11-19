extends SceneTree
## Piece n_hs_b4_eleventh (high street fill, block 4, part "11th St apartments"): u 50..190, v 209.2..254, between 11th
## St (north), the Amber shops' rear lot (west), the residents' alley (south, v 254..260, in n_hs_b4_ocean) and the
## B Ave houses' service alley (east). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner / architect): east of Amber, 11th St climbs from the shops toward the B Ave houses: the beach town's
## apartment houses line it, as on the west side (block 3's dingbats), but bigger and mixed: two three-storey modern
## rows, a Spanish revival court, a small two-storey row, a white courtyard block and a long garden-apartment block,
## each on its own lawn with paths to its doors. Behind each a shared yard (washing, a grill, a table), the tenants'
## parking nose-in off the residents' alley, bins at the parking, a walk at the east end from 11th St to the alley.
## LAND: 11th St rises 1.7 m along the row (4.24 at u 50 to 5.92 at u 188). Every lot is a level terrace at the walk
## height of its middle, a 0.6 m band follows the walk, steps on the paths, retaining faces between the terraces (up to
## 0.3 m); the yards and the parking behind follow the block's surface down to the alley. The first and last terraces
## stand 0.6 m inside the piece's seams.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B4 := preload("res://tools/city/pilot/pieces/n_hs_b4_site.gd")

const X0 := 50.0
const X1 := 190.0
const ZS := 254.0
const ZPARK := 248.0
const ZF := 210.4            # behind the band along 11th St (0.7..1.2 m: never a face within 0.6 m of the walk)
const ZT := 232.0            # the terraces' back line (a paved patio behind each building)
const FRONT_V := 215.0       # the buildings' fronts (lawns 5.2 m)
## [label, folder, x0, x1, centre u, model z max, [path centre u offsets (model x)], path width]   yaw 180 (model x -> -u)
const LOTS := [
	["a1", "ck/ck_apt3_row3", 50.6, 74.0, 62.3, 6.0, [-6.0, 0.0, 6.0], 1.4],
	["a2", "apartments/apt_spanish_revival", 74.0, 96.0, 85.0, 6.5, [-6.4, 0.0, 6.4], 1.4],
	["a3", "ck/ck_apt3_row2", 96.0, 112.0, 104.0, 6.0, [-3.0, 3.0], 1.4],
	["a4", "apartments/apt_court_white", 112.0, 134.0, 123.0, 6.1, [-4.2, 4.2], 2.4],
	["a5", "ck/ck_apt3_row3", 134.0, 156.0, 145.0, 6.0, [-6.0, 0.0, 6.0], 1.4],
	["a6", "apartments/apt_garden_mint", 156.0, 184.0, 170.0, 6.1, [-7.2, 0.0, 7.2], 2.4],
]

func _init() -> void: _run.call_deferred()

static func pad_y(l: Array) -> float: return B4.n11(float(l[4]))
static func path_us(l: Array) -> Array:
	var r: Array = []
	for dx: float in l[6]: r.append(float(l[4]) - dx)
	r.sort()
	return r

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b4_eleventh"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b4_eleventh")
	var yf := B4.L(B4.g)
	var n := func(x: float) -> float: return B4.north(x)
	var zf := func(_x: float) -> float: return ZF
	# ================================================================ ground
	H.band(g, "concrete", X0, X1, n, zf, yf, H.STEP, [51.0, 54.77])          # band along 11th St, flush with its walk
	var paints: Array = []
	for l: Array in LOTS: paints.append([float(l[2]), ZF, float(l[3]), ZT, "-"])
	for k in 52: paints.append([X0 + 1.0 + 2.7 * k - 0.05, ZPARK, X0 + 1.0 + 2.7 * k + 0.05, ZS - 0.5, "white"])
	paints.append_array([
		[X0, ZPARK, X1, ZS, "asphalt"],                     # the tenants' parking, nose-in off the alley
		[184.6, ZF, 188.6, ZPARK, "plaza"],                 # the walk from 11th St to the parking and the alley
	])
	H.paint(g, X0, ZF, X1, ZS, paints, "grass", yf)
	for l: Array in LOTS:
		var y := pad_y(l) - B4.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[2]; var x1: float = l[3]; var w: float = l[7]
		var ns: Array = []
		for pu: float in path_us(l):
			var dh := absf(y - float(yf.call(pu, ZF)))
			ns.append(1 if dh < 0.03 else ceili(dh / 0.17))
		# the terrace: lawn in front, paths to the doors (steps cut in at the band), the building, a paved patio behind
		var lp: Array = []
		var j := 0
		for pu: float in path_us(l):
			lp.append([pu - w * 0.5, ZF, pu + w * 0.5, ZF + 0.3 * int(ns[j]), "-"])
			lp.append([pu - w * 0.5, ZF + 0.3 * int(ns[j]), pu + w * 0.5, FRONT_V + 0.2, "concrete"])
			j += 1
		lp.append([x0, ZT - 3.0, x1, ZT, "plaza"])
		lp.append([x0 + 0.5, FRONT_V - 0.4, x1 - 0.5, ZT - 3.0, "concrete"])
		H.paint(g, x0, ZF, x1, ZT, lp, "grass", yp)
		H.step_face(g, Vector2(x0, ZT), Vector2(x1, ZT), yp, yf)
		H.step_face(g, Vector2(x0, ZF), Vector2(x0, ZT), yp, yf)
		H.step_face(g, Vector2(x1, ZF), Vector2(x1, ZT), yp, yf)
		var cur := x0
		j = 0
		for pu: float in path_us(l):
			H.step_face(g, Vector2(cur, ZF), Vector2(pu - w * 0.5, ZF), yp, yf)
			H.steps_z(g, pu, w, ZF, ZF + 1.0, float(yf.call(pu, ZF)), y)
			cur = pu + w * 0.5
			j += 1
		H.step_face(g, Vector2(cur, ZF), Vector2(x1, ZF), yp, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	H.finish(root, g, props, dec, "n_hs_b4_eleventh")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var trees := ["palm_mexican_fan_a", "tree_coral_a", "palm_queen_b", "tree_jacaranda_b", "palm_mexican_fan_c", "tree_magnolia_a"]
	var i := 0
	for l: Array in LOTS:
		var y := pad_y(l) - B4.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[2]; var x1: float = l[3]; var c: float = l[4]
		K.building(bl, String(l[1]), Vector3(c, y, FRONT_V + float(l[5])), 180.0, String(l[0]))
		var pus := path_us(l)
		# front lawn: a tree at the lot's corner (palms and flowering trees alternating along the street), planting by
		# the first path, the mailboxes on the band at the first path
		H.put(props, String(trees[i]), "normal", x1 - 1.8, 211.8, yp, float(i) * 61.0)
		H.put(props, "plant_bird_of_paradise", "normal", float(pus[0]) - float(l[7]) * 0.5 - 1.0, FRONT_V - 1.0, yp, 0.0, false)
		H.put(props, "plant_agave_americana_small", "normal", float(pus[pus.size() - 1]) + float(l[7]) * 0.5 + 1.2, FRONT_V - 1.2, yp, 0.0, false)
		P.call("prop_mailbox_post_metal", "worn", float(pus[0]) - float(l[7]) * 0.5 - 0.35, 210.0, 180.0)
		# a low hedge along the front, open at every path (and the mailbox)
		var cur := x0 + 0.3
		for pu: float in pus:
			if pu - float(l[7]) * 0.5 - 0.8 - cur >= 2.0: H.hedge(props, Vector2(cur, ZF + 0.55), Vector2(pu - float(l[7]) * 0.5 - 0.8, ZF + 0.55), yp)
			cur = pu + float(l[7]) * 0.5 + 0.5
		if x1 - 2.8 - cur >= 2.0: H.hedge(props, Vector2(cur, ZF + 0.55), Vector2(x1 - 2.8, ZF + 0.55), yp)
		# the patio behind (on the terrace): each building its own use
		match i:
			0: H.put(props, "prop_bbq_kettle", "worn", c - 4.0, ZT - 1.4, yp, 0.0); H.put(props, "prop_patio_set_4", "worn", c + 3.0, ZT - 1.5, yp, 0.0)
			1: H.put(props, "prop_picnic_table", "worn", c - 3.0, ZT - 1.5, yp, 0.0); H.put(props, "plant_potted_leafy", "normal", c + 5.0, ZT - 1.0, yp, 0.0, false); H.put(props, "plant_bougainvillea_mound", "normal", 81.8, 212.8, yp, 0.0, false)
			2: H.put(props, "prop_adirondack_white", "worn", c - 1.0, ZT - 1.5, yp, 200.0); H.put(props, "prop_adirondack_white", "worn", c + 1.0, ZT - 1.5, yp, 160.0)
			3: H.put(props, "prop_patio_set_4", "worn", c, ZT - 1.5, yp, 0.0); H.put(props, "prop_garden_arbor", "worn", c - 6.0, ZT - 1.5, yp, 0.0)
			4: H.put(props, "prop_bbq_gas_cart", "worn", c + 4.0, ZT - 1.3, yp, 180.0); H.put(props, "prop_picnic_table", "worn", c - 3.0, ZT - 1.5, yp, 0.0)
			5: H.put(props, "prop_patio_set_4", "worn", c - 6.0, ZT - 1.5, yp, 0.0); H.put(props, "prop_patio_set_4", "worn", c + 6.0, ZT - 1.5, yp, 0.0); H.put(props, "plant_potted_succulent", "normal", c, ZT - 0.8, yp, 0.0, false)
		H.put(props, "prop_ac_condenser", "worn", x0 + 0.9, ZT - 4.5, yp, 90.0)
		H.put(props, "prop_ac_condenser", "worn", x1 - 0.9, ZT - 4.5, yp, -90.0)
		# the shared yard (block surface): washing, a tree in every other one, a bench facing the building
		P.call("prop_clothesline", "worn", c, ZT + 6.0, 0.0)
		if i % 2 == 1: P.call(["tree_ficus_b", "tree_coral_b", "tree_jacaranda_a"][i / 2], "normal", x0 + 3.5, ZPARK - 4.0, float(i) * 50.0)
		P.call("prop_park_bench", "worn", c + 4.0, ZT + 10.0, 180.0)
		# bins at the parking's edge (not collection day)
		for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", x1 - 0.7 - 0.8 * k, ZPARK - 1.0, 0.0)
		i += 1
	# wheel stops in every stall (nose-in from the alley: the stop at the north end), oil
	for k in 51:
		var xc := X0 + 1.0 + 2.7 * k + 1.35
		P.call("prop_wheel_stop_concrete", "worn", xc, ZPARK + 0.6, 0.0)
		if k % 3 != 1: W.oil(dec, rr, Vector2(xc, ZPARK + 2.4), 0.0, yf, 0.6)
	for x: float in [80.0, 120.0, 160.0]: P.call("prop_lot_light_pole", "worn", x, ZPARK - 0.8)
	# the walk at the east end: lamps, a bike rack beside it (out of it)
	P.call("prop_lamp_globe", "worn", 189.2, 222.0)
	P.call("prop_lamp_globe", "worn", 189.2, 240.0)
	P.call("prop_bike_rack", "worn", 184.9, 236.0, 90.0)
	for c2: Array in [[70.0, 251.0], [130.0, 251.5], [175.0, 251.0]]:
		dec.add(0, Vector2(float(c2[0]), float(c2[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
