extends SceneTree
## Piece n_hs_b5_eleventh (high street fill, block 5, part "11th St: fire station and flats"): u 50..125, v 156..11th
## St, between the parking aisle (north, in n_hs_b5_hill), the Amber shops' rear lot (west), the residential quarter
## r_q (east) and 11th St (south). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): FIRE STATION 2 at the foot of the hill, on 11th St one block from Amber: its engines reach the high
## street, the beach and - up B Ave and 10th St - the hill; its apron opens straight onto 11th St, the crews park
## behind off the aisle. Beside it two apartment houses (a garden-apartment block and a Spanish court) continue 11th
## St's apartment front from block 4 across the street, each on its own terrace with lawns and paths; their tenants
## park nose-in off the aisle behind.
## LAND: 11th St rises 0.9 m along the piece (4.24 -> 5.13). The station stands on a pad at its apron's height; each
## apartment house on a terrace at the walk height of its middle (steps on the paths); the yards and the parking
## follow the surface; r_q's lot line is met by an edge strip at its height.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B5 := preload("res://tools/city/pilot/pieces/n_hs_b5_site.gd")

const X0 := 50.0
const X1 := 125.0
const ZN := 156.0
const ZF := 189.6            # behind the band along 11th St (0.7 .. 1.2 m)
const ZT := 166.0            # the terraces' back line
const FRONT_V := 183.4       # the buildings' fronts
const FS := [51.6, 160.6, 75.0, FRONT_V]      # the fire station's pad (its rear apron in front of the back doors)
const FS_C := Vector2(62.7, 171.45)           # yaw 0 (faces 11th St); bays at u 56.8 / 62.7 / 68.6
const STALLS := [76.0, 121.0]
## [label, folder, x0, x1, centre u, model z max, [path offsets (model x)], path width]   yaw 0 (model x -> +u)
const LOTS := [
	["a1", "apartments/apt_garden_cream", 76.0, 100.6, 88.3, 6.1, [-7.2, 0.0, 7.2], 2.4],
	["a2", "apartments/apt_spanish_white", 100.6, 123.0, 111.9, 6.5, [-6.4, 0.0, 6.4], 1.4],
]

func _init() -> void: _run.call_deferred()

static func pad_y(l: Array) -> float: return B5.n11(float(l[4]))
static func fs_y() -> float: return B5.g(FS_C.x, FRONT_V)
static func path_us(l: Array) -> Array:
	var r: Array = []
	for dx: float in l[6]: r.append(float(l[4]) + dx)
	r.sort()
	return r

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b5_eleventh"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b5_eleventh")
	var yf := B5.L(B5.g)
	var yfs := fs_y() - B5.PAD_Y
	var yfp := func(_x: float, _z: float) -> float: return yfs
	# ================================================================ ground
	H.band(g, "concrete", X0, X1, func(_x: float) -> float: return ZF, func(x: float) -> float: return B5.north11(x), yf, H.STEP, [51.0, 54.77])
	var holes: Array = H.edge_strip(g, "v", X1, -2.0, B5.Lseg([[ZN, ZF, 5.22, 5.22]]), yf, "grass", false)
	holes.append([FS[0], FS[1], FS[2], FS[3], "-"])
	for l: Array in LOTS: holes.append([float(l[2]), ZT, float(l[3]), ZF, "-"])
	for k in 17: holes.append([STALLS[0] + 2.7 * k - 0.05, ZN, STALLS[0] + 2.7 * k + 0.05, ZN + 5.5, "white"])
	holes.append_array([
		[STALLS[0], ZN, STALLS[1], ZN + 6.0, "asphalt"],              # the tenants' stalls, nose-in off the aisle
		[51.6, ZN, 75.0, FS[1], "concrete"],                          # the station's rear apron (crew parking)
		[52.0, FRONT_V, 73.6, ZF, "concrete"],                        # the station's apron to 11th St
	])
	H.paint(g, X0, ZN, X1, ZF, holes, "grass", yf)
	H.level_pad(g, "concrete", FS[0], FS[1], FS[2], FS[3], yfs, yf, "nesw")
	for l: Array in LOTS:
		var y := pad_y(l) - B5.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[2]; var x1: float = l[3]; var w: float = l[7]
		var lp: Array = []
		var ns: Array = []
		for pu: float in path_us(l):
			var dh := absf(y - float(yf.call(pu, ZF)))
			var n := 1 if dh < 0.03 else ceili(dh / 0.17)
			ns.append(n)
			lp.append([pu - w * 0.5, ZF - 0.3 * n, pu + w * 0.5, ZF, "-"])
			lp.append([pu - w * 0.5, FRONT_V - 0.2, pu + w * 0.5, ZF - 0.3 * n, "concrete"])
		lp.append([x0, ZT, x1, ZT + 3.0, "plaza"])
		H.paint(g, x0, ZT, x1, ZF, lp, "grass", yp)
		H.step_face(g, Vector2(x0, ZT), Vector2(x1, ZT), yp, yf)
		var li := LOTS.find(l)
		if li == 0: H.step_face(g, Vector2(x0, ZT), Vector2(x0, ZF), yp, yf)
		if li == LOTS.size() - 1: H.step_face(g, Vector2(x1, ZT), Vector2(x1, ZF), yp, yf)
		else:
			var yn := pad_y(LOTS[li + 1]) - B5.PAD_Y
			H.step_face(g, Vector2(x1, ZT), Vector2(x1, ZF), yp, func(_x: float, _z: float) -> float: return yn)
		var cur := x0
		var j := 0
		for pu: float in path_us(l):
			H.step_face(g, Vector2(cur, ZF), Vector2(pu - w * 0.5, ZF), yp, yf)
			H.steps_z(g, pu, w, ZF, ZF - 0.3 * int(ns[j]), float(yf.call(pu, ZF)), y)
			cur = pu + w * 0.5
			j += 1
		H.step_face(g, Vector2(cur, ZF), Vector2(x1, ZF), yp, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf, yfp)
	H.finish(root, g, props, dec, "n_hs_b5_eleventh")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, yfp: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	K.building(bl, "civic/civ_fire_station", Vector3(FS_C.x, float(yfp.call(0.0, 0.0)), FS_C.y), 0.0, "fire_station")
	# ---- the station: the hydrant at the apron's side, a bench and a bin by the side door, the crew's cars behind,
	# a lamp at the apron
	P.call("prop_hydrant_red", "worn", 51.0, 188.8, 0.0)
	P.call("prop_park_bench", "worn", 75.6, 178.0, 90.0)
	P.call("prop_trash_receptacle", "worn", 75.6, 175.6)
	P.call("prop_lamp_globe", "worn", 74.4, 188.9)
	for k in 5:
		var x := 54.0 + 4.2 * k
		P.call("prop_wheel_stop_concrete", "worn", x, ZN + 0.6, 0.0)
		if k % 2 == 0: W.oil(dec, rr, Vector2(x, ZN + 2.4), 0.0, yf, 0.5)
	H.put(props, "prop_dumpster_3yd_blue", "worn", 74.0, 161.6, yfp, 90.0)
	H.put(props, "prop_ac_condenser", "worn", 52.4, 163.0, yfp, 90.0)
	dec.add(14, Vector2(62.7, 186.5), 0.0, 20.0, 5.0, yf, Color(0.2, 0.2, 0.2, 0.25))     # the engines' tyre grime on the apron
	# ---- the apartment houses: lawns, a tree each, planting by the paths, mailboxes on the band, hedges open at the
	# paths; patios behind; the shared yard to the stalls with washing and a bench; bins at the stalls
	var i := 0
	for l: Array in LOTS:
		var y := pad_y(l) - B5.PAD_Y
		var yp := func(_x: float, _z: float) -> float: return y
		var x0: float = l[2]; var x1: float = l[3]; var c: float = l[4]
		K.building(bl, String(l[1]), Vector3(c, y, FRONT_V - float(l[5])), 0.0, String(l[0]))
		var pus := path_us(l)
		var w: float = l[7]
		H.put(props, ["palm_mexican_fan_b", "tree_jacaranda_a"][i], "normal", x1 - 1.8, 187.4, yp, float(i) * 60.0)
		H.put(props, "plant_bird_of_paradise", "normal", float(pus[0]) - w * 0.5 - 1.0, FRONT_V + 1.0, yp, 0.0, false)
		H.put(props, "plant_agave_americana_small", "normal", float(pus[pus.size() - 1]) + w * 0.5 + 1.2, FRONT_V + 1.2, yp, 0.0, false)
		P.call("prop_mailbox_post_metal", "worn", float(pus[0]) - w * 0.5 - 0.35, 189.95, 0.0)
		var cur := x0 + 0.3
		for pu: float in pus:
			if pu - w * 0.5 - 0.8 - cur >= 2.0: H.hedge(props, Vector2(cur, ZF - 0.55), Vector2(pu - w * 0.5 - 0.8, ZF - 0.55), yp)
			cur = pu + w * 0.5 + 0.5
		if x1 - 2.8 - cur >= 2.0: H.hedge(props, Vector2(cur, ZF - 0.55), Vector2(x1 - 2.8, ZF - 0.55), yp)
		match i:
			0: H.put(props, "prop_patio_set_4", "worn", c - 5.0, ZT + 1.5, yp, 0.0); H.put(props, "prop_bbq_kettle", "worn", c + 4.0, ZT + 1.4, yp, 0.0)
			1: H.put(props, "prop_picnic_table", "worn", c, ZT + 1.5, yp, 0.0); H.put(props, "plant_potted_leafy", "normal", c + 5.0, ZT + 1.0, yp, 0.0, false)
		H.put(props, "prop_ac_condenser", "worn", x0 + 0.9, ZT + 4.0, yp, 90.0)
		P.call("prop_clothesline", "worn", c - 2.0, ZT - 2.0, 90.0)
		for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", x1 - 0.7 - 0.8 * k, ZN + 6.8, 180.0)
		i += 1
	for k in 16:
		var xc := STALLS[0] + 2.7 * k + 1.35
		P.call("prop_wheel_stop_concrete", "worn", xc, ZN + 5.0, 0.0)
		if k % 3 != 2: W.oil(dec, rr, Vector2(xc, ZN + 3.4), 0.0, yf, 0.6)
	P.call("prop_lot_light_pole", "worn", 100.6, ZN + 6.6)
