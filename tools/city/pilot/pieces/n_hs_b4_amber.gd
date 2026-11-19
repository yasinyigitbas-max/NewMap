extends SceneTree
## Piece n_hs_b4_amber (high street fill, block 4, part "Amber east to the beach"): u 16..50, v 209.7..Ocean Blvd: the
## east side of Amber's last stretch, from the 11th St corner down to the ring. Placed at grid [0, 4.0, 0], yaw 0.
## Run once; never when locked.
##
## WHY (planner / architect): the east side of the street's beach end, facing block 3's shops: a Spanish arcade on the
## 11th St corner (three shops under its arches), a three-storey stucco block (shop below), a pub for the evening after
## the beach, a small two-screen BEACH CINEMA with its snack bar, a bakery by the bus stop (coffee and pastries for those waiting and
## for the beach); each on a level pad at its
## door's walk height (Amber falls 2 m here). From the bus stop (Amber's own, in the street piece) to the corner on Ocean Blvd a palm plaza: the corner where the real
## town has its great beach hotel. That hotel is a hero site (hand-made, Yasin's word): this plaza is what stands there
## until he decides. Behind: the shops' rear lot off the residents' alley.
## LAND (n_hs_b4_site.gd): Amber's own fall; each building on a level pad; a 0.6 m band follows the walk.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B4 := preload("res://tools/city/pilot/pieces/n_hs_b4_site.gd")

const X0 := 16.0
const X1 := 50.0
const XF := 16.6
## [label, folder, v north, v south, centre v, centre u, door v (pad), back u, (pad y)]  (yaw -90: fronts face Amber, -u)
const FRONT := [
	["arcade", "commercial/com_spanish_arcade_block", 209.75, 234.65, 222.2, 24.6, 219.28, 33.35, 4.161],   # (pad: between Amber at its door and 11th St along its side)
	["stucco", "apartments/apt_stucco3_peach", 235.1, 255.54, 245.32, 22.6, 245.32, 30.4],
	["pub", "commercial/com_bar_crown", 255.74, 266.56, 261.34, 23.6, 258.08, 31.35],
	["cinema", "ck/ck_svc_cinema_fast", 266.76, 278.76, 272.76, 22.6, 271.86, 28.9],
	["bakery", "commercial/com_bakery", 278.96, 288.86, 283.91, 24.77, 287.17, 32.22],
]
const PLAZA_V := 289.1
const TREES := [[21.0, 304.0], [21.0, 318.0], [40.0, 312.0], [26.0, 294.0]]

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["prop_bike_rack", "worn", 47.2, 323.4, 0.0],
	["plant_potted_succulent", "normal", 41.8, 323.4, 90.0, false],
	["prop_trash_receptacle", "worn", 36.8, 323.4, 180.0],
	["plant_potted_leafy", "normal", 25.8, 323.4, 270.0, false],
	["plant_potted_leafy", "normal", 31.2, 323.4, 0.0, false],
	["prop_park_bench", "worn", 19.8, 323.4, 90.0],
	["prop_bike_rack", "worn", 46.2, 318.4, 180.0],
	["plant_potted_succulent", "normal", 39.2, 318.9, 270.0, false],
	["prop_trash_receptacle", "worn", 33.8, 318.9, 0.0],
	["plant_potted_leafy", "normal", 28.8, 318.9, 90.0, false],
]

func _init() -> void: _run.call_deferred()

static func pad_y(d: Array) -> float: return float(d[8]) if d.size() > 8 else B4.amber(float(d[6]))
static func zs(x: float) -> float: return B4.south(x)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b4_amber"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b4_amber")
	var yf := B4.L(B4.g)
	# ================================================================ ground
	var paints: Array = []
	for d: Array in FRONT: paints.append([XF, float(d[2]), float(d[7]) + 0.3, float(d[3]), "-"])
	for k in 9: paints.append([45.0, 213.0 + 2.7 * k - 0.05, X1, 213.0 + 2.7 * k + 0.05, "white"])     # rear lot stalls, nose east
	for k in 10: paints.append([45.0, 262.0 + 2.7 * k - 0.05, X1, 262.0 + 2.7 * k + 0.05, "white"])    # (the alley's mouth v 254..260 open)
	paints.append([X0, 209.7, XF, PLAZA_V, "concrete"])                                                 # the band along Amber's walk
	H.paint(g, X0, 209.7, X1, PLAZA_V, paints, "asphalt", yf)
	var holes: Array = []
	for t: Array in TREES: holes.append([float(t[0]) - 2.0, float(t[1]) - 2.0, float(t[0]) + 2.0, float(t[1]) + 2.0, "grass"])
	holes.append([X0, PLAZA_V, 46.0, 302.0, "plaza"])
	H.paint_band(g, X0, X1, func(_x: float) -> float: return PLAZA_V, func(x: float) -> float: return zs(x), holes, "plaza", yf)
	for d: Array in FRONT:
		H.level_pad(g, "concrete", XF, float(d[2]), float(d[7]) + 0.3, float(d[3]), pad_y(d) - B4.PAD_Y, yf)
	H.skirt(g, Vector2(X0, 209.7), Vector2(X0, zs(X0)), yf, "concrete")
	H.skirt(g, Vector2(X0, 209.7), Vector2(X1, 209.7), yf, "concrete")
	H.skirt(g, Vector2(X0, zs(X0)), Vector2(X1, zs(X1)), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b4_amber")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	for d: Array in FRONT:
		K.building(bl, String(d[1]), Vector3(float(d[5]), pad_y(d) - B4.PAD_Y, float(d[4])), -90.0, String(d[0]))
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	# ---- shop fronts on the band: pots by the pub and the bakery, papers on the 11th St corner, the cinema's
	# poster stand is in its model
	P.call("prop_newspaper_box_blue", "worn", 16.3, 211.4, -90.0)
	P.call("prop_newspaper_box_red", "worn", 16.3, 212.1, -90.0)
	for z: float in [256.93, 259.23, 285.97, 288.37]: P.call("plant_potted_succulent", "normal", 16.25, z, 0.0, false)
	# ---- the corner plaza on Ocean Blvd: palms in their beds, benches facing the ocean, a fountain, bike racks, bins
	P.call("palm_canary_date_a", "normal", 21.0, 304.0, 20.0)
	P.call("palm_mexican_fan_b", "normal", 21.0, 318.0, 80.0)
	P.call("palm_canary_date_b", "normal", 40.0, 312.0, 200.0)
	P.call("palm_queen_a", "normal", 26.0, 294.0, 130.0)
	P.call("prop_park_bench", "worn", 21.4, 291.4, -90.0)                      # (beside the bus stop, for those waiting in the shade)
	for b: Array in [[27.0, 321.6], [33.0, 321.8], [46.0, 322.0]]: P.call("prop_park_bench", "worn", float(b[0]), float(b[1]), 0.0)
	P.call("prop_drinking_fountain", "worn", 30.0, 306.0, 0.0)
	P.call("prop_bike_rack", "worn", 47.8, 306.0, 90.0)
	P.call("prop_bike_rack", "worn", 47.8, 310.0, 90.0)
	P.call("prop_trash_receptacle", "worn", 30.0, 314.2)
	P.call("prop_recycling_receptacle", "worn", 30.8, 314.2)
	for k in 7: P.call("prop_bollard_concrete", "worn", 16.6, 302.0 + 3.0 * k)       # (none before the bus stop: the way to it open)
	for l: Array in [[17.2, 299.0], [17.2, 314.0], [45.0, 302.6], [30.0, 289.8]]: P.call("prop_lamp_victorian", "worn", float(l[0]), float(l[1]))
	# ---- the rear lot (back doors kept clear: arcade v 212.85 / 220.85 / 228.85, stucco 245.32, pub 263.14,
	# cinema 268.96 / 276.96, bakery)
	for k in 8: P.call("prop_wheel_stop_concrete", "worn", 49.4, 214.35 + 2.7 * k, 90.0)
	for k in 9: P.call("prop_wheel_stop_concrete", "worn", 49.4, 263.35 + 2.7 * k, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", 34.4, 216.8, 90.0)                       # the arcade's café (food)
	P.call("prop_recycling_receptacle", "worn", 34.0, 225.0, 90.0)
	for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 31.0, 239.0 + 0.8 * k, 90.0)   # flats
	P.call("prop_dumpster_3yd_blue", "worn", 31.4, 250.6, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", 32.4, 260.0, 90.0)                       # the pub (bottles, kitchen)
	P.call("prop_recycling_receptacle", "worn", 29.9, 272.9, 90.0)                     # the cinema's snack bar
	P.call("prop_dumpster_3yd_green", "worn", 33.6, 281.0, 90.0)                       # the bakery
	P.call("prop_ac_condenser", "worn", 34.2, 232.0, 90.0)
	P.call("prop_ac_condenser", "worn", 33.0, 286.2, 90.0)
	P.call("prop_lot_light_pole", "worn", 40.0, 240.0)
	P.call("prop_lot_light_pole", "worn", 40.0, 285.0)
	# ================================================================ wear
	for o: Array in [[47.5, 214.35], [47.5, 219.75], [47.5, 227.85], [47.5, 263.35], [47.5, 271.45], [47.5, 279.55]]:
		W.oil(dec, rr, Vector2(float(o[0]), float(o[1])), 90.0, yf, 0.7)
	for d2: Array in [[34.4, 216.8], [31.4, 250.6], [32.4, 260.0], [33.6, 281.0]]:
		dec.add(14, Vector2(float(d2[0]), float(d2[1])), 90.0, 3.0, 2.4, yf, Color(1, 1, 1, 0.7))
	for c: Array in [[40.0, 230.0], [41.0, 270.0], [39.0, 292.0]]:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
	dec.add(14, Vector2(24.0, 312.0), 0.0, 10.0, 3.0, yf, Color(0.82, 0.74, 0.55, 0.35))     # sand carried up from the beach
