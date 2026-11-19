extends SceneTree
## Piece n_hs_b5_amber (high street fill, block 5, part "Amber east, b_se to 11th St"): u 16..50, v 97.5..11th St,
## between the pilot's downtown block b_se (north), Amber (west), 11th St (south) and the hillside lane / the fire
## station (east). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner / architect): the high street goes on south of the pilot's b_se as it is there: shop fronts on the walk,
## a rear lot behind. The town's POST OFFICE on Amber (set back behind its steps), a bistro, a corner pair of
## shops by a PASEO through to the rear lot, the orange ARCADE (centred on Amber's bus stop) (its arches over the walk, four shops under them, answering the Spanish arcade at 11th
## St on block 4), a small cafe and a corner plaza on 11th St. The rear lot behind is reached by the lane from the residents'
## alley (n_hs_b5_hill): deliveries, the post office's vans, the shops' bins and staff parking.
## LAND: Amber is level here (4.15 the whole way): one height for every shop floor; the lot follows the surface
## (4.15 .. 4.29).
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B5 := preload("res://tools/city/pilot/pieces/n_hs_b5_site.gd")

const X0 := 16.0
const X1 := 50.0
const XF := 16.6
const ZN := 97.5
## [label, folder, v north, v south, centre v, centre u, back u]   (yaw -90: fronts face Amber)
const FRONT := [
	["post", "civic/civ_post_office", 98.1, 121.54, 109.82, 28.05, 37.05],
	["bistro", "commercial/com_bistro", 121.74, 134.64, 128.19, 24.77, 32.22],
	["corner", "commercial/com_orange_corner", 134.84, 147.74, 141.29, 24.77, 32.22],
	["arcade", "commercial/com_orange_arcade_block", 150.55, 177.45, 164.0, 25.15, 34.1],
	["cafe", "commercial/com_shallow_cafe", 177.65, 186.05, 181.85, 21.02, 24.72],
]
const SHOP_Y := 4.15

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b5_amber"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b5_amber")
	var yf := B5.L(B5.g)
	var ys := SHOP_Y - B5.PAD_Y
	var ysp := func(_x: float, _z: float) -> float: return ys
	var zs := func(x: float) -> float: return B5.north11(x)
	# ================================================================ ground
	var paints: Array = []
	for d: Array in FRONT: paints.append([XF, float(d[2]), float(d[6]) + 0.3, float(d[3]), "-"])
	for k in 27: paints.append([45.0, 106.0 + 2.7 * k - 0.05, X1, 106.0 + 2.7 * k + 0.05, "white"])     # stalls nose-in east (the lane's mouth v 100..106 open)
	paints.append_array([
		[X0, ZN, XF, 191.0, "concrete"],                     # the band along Amber's walk
		[18.0, 187.0, 20.4, 189.4, "grass"],                 # the corner plaza's palm bed
		[XF, 186.25, 24.72, 191.0, "plaza"],                 # the corner plaza on 11th St
		[XF, 147.94, 34.0, 150.35, "plaza"],                 # the paseo from Amber to the rear lot
		[24.72, 177.65, X1, 191.0, "grass"],                 # behind the cafe: a lawn to the lot
	])
	H.paint_band(g, X0, X1, func(_x: float) -> float: return ZN, zs, paints, "asphalt", yf)
	for d: Array in FRONT:
		H.level_pad(g, "concrete", XF, float(d[2]), float(d[6]) + 0.3, float(d[3]), ys, yf)
	H.skirt(g, Vector2(X0, ZN), Vector2(X0, B5.north11(X0)), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf, ysp)
	H.finish(root, g, props, dec, "n_hs_b5_amber")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, ysp: Callable) -> void:
	for d: Array in FRONT:
		K.building(bl, String(d[1]), Vector3(float(d[5]), float(ysp.call(0.0, 0.0)), float(d[4])), -90.0, String(d[0]))
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	# ---- the walk's edge of the shops (never before a door: post office 109.82, bistro 132.95, corner 140.21 / 142.37,
	# arcade 156.42 / 158.58 / 169.42 / 171.58, cafe 184.36; Amber's bus shelter at v 164): pots, papers, a bike rack

	P.call("prop_newspaper_box_blue", "worn", 16.3, 117.4, -90.0)
	P.call("prop_newspaper_box_red", "worn", 16.3, 118.1, -90.0)
	for z: float in [125.0, 136.4, 145.6, 179.6]: P.call("plant_potted_succulent", "normal", 16.25, z, 0.0, false)
	P.call("prop_bike_rack", "worn", 16.3, 121.6, 90.0)
	# ---- the rear lot (back doors kept clear): dumpsters behind the bistro and the cafe, the post office's carts,
	# recycling behind the shop row, wheel stops, lights, oil
	for k in 26: P.call("prop_wheel_stop_concrete", "worn", 49.4, 107.35 + 2.7 * k, 90.0)
	P.call("prop_dumpster_3yd_blue", "worn", 38.4, 100.6, 90.0)                       # the post office (cartons)
	P.call("prop_recycling_receptacle", "worn", 33.4, 138.0, 90.0)
	for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 33.2, 144.0 + 0.8 * k, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", 33.6, 126.0, 90.0)                      # the bistro's kitchen
	P.call("prop_dumpster_3yd_green", "worn", 35.4, 157.0, 90.0)                      # the arcade's food shop
	P.call("prop_recycling_receptacle", "worn", 35.2, 178.0, 90.0)
	P.call("prop_ac_condenser", "worn", 35.0, 153.4, 90.0)
	P.call("prop_ac_condenser", "worn", 38.2, 118.0, 90.0)
	for z2: float in [120.0, 160.0]: P.call("prop_lot_light_pole", "worn", 42.0, z2)
	for o: Array in [[47.5, 110.05], [47.5, 118.15], [47.5, 129.0], [47.5, 145.2], [47.5, 156.0], [47.5, 172.2], [47.5, 180.3]]:
		W.oil(dec, rr, Vector2(float(o[0]), float(o[1])), 90.0, yf, 0.7)
	for c: Array in [[40.0, 132.0], [41.0, 170.0]]:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
	# ---- the paseo: lamps at both ends; the corner plaza: its palm, a bench facing 11th St, a bin
	P.call("prop_lamp_victorian", "worn", 17.2, 149.1)
	P.call("prop_lamp_globe", "worn", 33.6, 149.1)
	P.call("palm_queen_b", "normal", 19.2, 188.2, 60.0)
	P.call("prop_park_bench", "worn", 22.6, 189.6, 0.0)
	P.call("prop_trash_receptacle", "worn", 17.2, 187.0)
	# ---- the lawn behind the cafe: a tree, a bench, the cafe's two outdoor tables
	P.call("tree_coral_b", "normal", 36.0, 186.0, 40.0)
	P.call("prop_park_bench", "worn", 30.0, 188.0, 0.0)
	P.call("prop_patio_set_4", "worn", 27.6, 184.4, 0.0)
