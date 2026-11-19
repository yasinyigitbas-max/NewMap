extends SceneTree
## Piece n_hs_b6_amber (high street fill, block 6, part "Amber east, 9th St to b_ne"): u 16..50, v 9th St..-97.5,
## between 9th St (north), Amber (west), the pilot's downtown block b_ne (south) and the hillside lane / the 9th St
## piece (east). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner / architect): north of the pilot's b_ne the high street climbs to 9th St: shop fronts on the walk all
## the way, as in the pilot. On the 9th St corner a brick pair; a bank with the pharmacy beside it; a row of three
## small shops; a brick corner pair by a paseo to the rear lot; the trades' shop (keys, a hardware counter); a coffee house; then, where the street meets
## b_ne, a POCKET PLAZA: palms, benches and the paseo through to the rear lot, the place to sit on the climb. The rear
## lot is reached by the lane from the residents' alley (n_hs_b6_hill).
## LAND: Amber rises 2 m from b_ne to 9th St (2.2 %): every shop on its own level pad at its door's walk height (faces
## of up to 0.2 m at their ends, under their own walls); the lot and the plaza follow the surface.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B6 := preload("res://tools/city/pilot/pieces/n_hs_b6_site.gd")

const X0 := 16.0
const X1 := 50.0
const XF := 16.6
const ZS := -97.5
## [label, folder, v north, v south, centre v, centre u, door v (pad), back u]   (yaw -90: fronts face Amber, model x -> +v)
const FRONT := [
	["brick", "ck/ck_brk3_row2", -189.7, -177.7, -183.7, 23.6, -184.8, 30.6],
	["bankph", "ck/ck_svc_bank_pharm", -177.5, -165.5, -171.5, 22.6, -174.5, 28.6],
	["row", "commercial/com_boutique_row", -165.3, -146.4, -155.85, 24.77, -157.77, 32.22],
	["corner", "ck/ck_brk3_corner2", -146.2, -134.2, -140.2, 23.6, -143.2, 30.6],
	["trade", "ck/ck_svc_trade", -131.3, -119.3, -125.3, 22.6, -128.3, 28.6],
	["cafe", "commercial/com_cafe_seaside", -119.1, -111.28, -115.0, 24.77, -116.76, 32.22],
]
const PLAZA := [-111.0, ZS]

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["prop_trash_receptacle", "worn", 21.2, -100.6, 180.0],
	["plant_potted_leafy", "normal", 31.8, -103.1, 270.0, false],
	["plant_potted_leafy", "normal", 25.8, -103.6, 0.0, false],
	["prop_park_bench", "worn", 18.8, -105.1, 90.0],
	["prop_bike_rack", "worn", 29.2, -107.6, 180.0],
]

func _init() -> void: _run.call_deferred()

static func pad_y(d: Array) -> float: return B6.amb(float(d[6]))

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b6_amber"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b6_amber")
	var yf := B6.L(B6.g)
	var zn := func(x: float) -> float: return B6.north9(x)
	# ================================================================ ground
	var paints: Array = []
	for d: Array in FRONT: paints.append([XF, float(d[2]), float(d[7]) + 0.3, float(d[3]), "-"])
	for k in 25: paints.append([45.0, -112.0 - 2.7 * k - 0.05, X1, -112.0 - 2.7 * k + 0.05, "white"])   # stalls nose-in east (the lane's mouth v -106..-100 open)
	paints.append_array([
		[X0, -191.0, XF, ZS, "concrete"],                    # the band along Amber's walk
		[20.0, -109.5, 23.0, -106.5, "grass"], [27.0, -103.0, 30.0, -100.0, "grass"],      # the plaza's palm beds
		[XF, PLAZA[0], 34.0, ZS, "plaza"],                   # the pocket plaza and its paseo to the lot
		[XF, -134.2, 34.0, -131.3, "plaza"],                 # the paseo by the corner pair
		[XF, -191.0, X1, -189.9, "concrete"],                # band along 9th St
	])
	H.paint_band(g, X0, X1, zn, func(_x: float) -> float: return ZS, paints, "asphalt", yf)
	for d: Array in FRONT:
		H.level_pad(g, "concrete", XF, float(d[2]), float(d[7]) + 0.3, float(d[3]), pad_y(d) - B6.PAD_Y, yf)
	H.skirt(g, Vector2(X0, B6.north9(X0)), Vector2(X0, ZS), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b6_amber")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	for d: Array in FRONT:
		K.building(bl, String(d[1]), Vector3(float(d[5]), pad_y(d) - B6.PAD_Y, float(d[4])), -90.0, String(d[0]))
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	# ---- the walk's edge of the shops (never before a door: brick -184.8 / -180.7, bank -174.5 / -166.9, row -159.93 /
	# -157.77 / -148.09, corner -143.2 / -135.3, trade -128.3 / -122.3, cafe -116.76; Amber's own bench at -130 and
	# paper box at -178.5 kept clear too): papers on the 9th St corner, pots, a
	# bike rack between the brick pair and the row
	P.call("prop_newspaper_box_blue", "worn", 16.3, -189.2, -90.0)
	P.call("prop_newspaper_box_red", "worn", 16.3, -188.5, -90.0)
	for z: float in [-176.0, -161.8, -133.0, -113.0]: P.call("plant_potted_succulent", "normal", 16.25, z, 0.0, false)
	P.call("prop_bike_rack", "worn", 16.3, -150.8, 90.0)
	# ---- the pocket plaza: palms in their beds, benches facing Amber (the climb's rest), a fountain, lamps, bins
	P.call("palm_mexican_fan_a", "normal", 21.5, -108.0, 30.0)
	P.call("palm_canary_date_b", "normal", 28.5, -101.5, 150.0)
	for b: Array in [[24.0, -110.2, 180.0], [31.6, -106.0, -90.0], [20.0, -99.6, 0.0]]: P.call("prop_park_bench", "worn", float(b[0]), float(b[1]), float(b[2]))
	P.call("prop_drinking_fountain", "worn", 25.6, -104.6, 0.0)
	P.call("prop_lamp_victorian", "worn", 17.2, -110.6)
	P.call("prop_lamp_victorian", "worn", 33.4, -110.6)
	P.call("prop_trash_receptacle", "worn", 17.2, -98.6)
	P.call("prop_recycling_receptacle", "worn", 18.0, -98.6)
	# ---- the rear lot (back doors kept clear): the bank's armoured-car bay by its back, dumpsters behind the cafe and
	# the corner pair, the shops' carts, wheel stops, lights, oil
	for k in 24: P.call("prop_wheel_stop_concrete", "worn", 49.4, -113.35 - 2.7 * k, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", 33.6, -116.0, 90.0)                     # the cafe
	P.call("prop_dumpster_3yd_blue", "worn", 31.8, -188.4, 90.0)                      # the brick pair
	for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 33.4, -150.0 - 0.8 * k, 90.0)
	P.call("prop_recycling_receptacle", "worn", 29.8, -126.0, 90.0)
	P.call("prop_ac_condenser", "worn", 29.8, -168.6, 90.0)
	P.call("prop_ac_condenser", "worn", 31.6, -137.6, 90.0)
	for z2: float in [-125.0, -170.0]: P.call("prop_lot_light_pole", "worn", 41.0, z2)
	for o: Array in [[47.5, -115.05], [47.5, -128.55], [47.5, -142.05], [47.5, -158.25], [47.5, -174.45]]:
		W.oil(dec, rr, Vector2(float(o[0]), float(o[1])), 90.0, yf, 0.7)
	for c: Array in [[40.0, -140.0], [41.0, -180.0]]:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
