extends SceneTree
## Piece n_hs_b3_amber (high street fill, block 3, part "Amber to the beach"): u -50..-16, v 209.7..Ocean Blvd: the last
## stretch of Amber, from the 11th St corner down to the ring by the beach. Placed at grid [0, 4.0, 0], yaw 0. Run once;
## never when locked.
##
## WHY (planner / architect): here the high street turns into the way to the beach: Amber falls 2 m in 100 m. The street
## wall steps down it, one level pad per building at its door's walk height: an Orange-style corner pair on 11th, a
## beach condo with a shop below, the surf shop, a beach café, a realty office (vacation rentals), the burger stand;
## then the block's landmark at the beach end, AMBER BEACH PLAZA with the old LOOKOUT TOWER: where everyone coming down
## Amber crosses to the sand: palms in wells, benches facing the ocean, bike racks, a beach shower, a fountain, a kiosk.
## Behind: the shops' rear lot off the residents' alley (it runs on from C Ave to here).
## LAND (n_hs_b3_site.gd): Amber's own fall; each building on a level pad; a 0.6 m band follows the walk.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B3 := preload("res://tools/city/pilot/pieces/n_hs_b3_site.gd")

const X0 := -50.0
const X1 := -16.0
const XF := -16.6
## [label, folder, v north (min), v south (max), centre v, centre u, door v, back u (pad)]
const FRONT := [
	["corner", "commercial/com_orange_corner", 210.0, 222.9, 216.45, -23.6, 216.45, -31.3],
	["condo", "apartments/apt_beach_condo", 223.1, 243.1, 233.1, -22.1, 233.1, -29.4],
	["surf", "commercial/com_surf_shop", 243.3, 253.2, 248.25, -23.6, 251.51, -31.3],
	["cafe", "commercial/com_cafe_seaside", 253.4, 261.22, 257.12, -23.6, 258.88, -31.3],
	["realty", "commercial/com_realty", 261.42, 268.34, 265.14, -23.6, 263.38, -31.6],
	["burger", "ck/mod_fastfood", 268.54, 280.54, 274.54, -22.6, 274.54, -29.2],
]
const PLAZA_V := 281.0                    # the plaza from here to Ocean Blvd
const LOOK := [-43.0, 292.2, -25.5, 306.2]   # the lookout's pad (its mesh: u -42.72..-25.76, v 292.5..305.95)
const KIOSK := [-25.1, 288.2, -17.3, 293.8]  # the beach kiosk's pad
const TREES := [[-20.0, 286.0], [-20.0, 300.0], [-30.0, 312.0], [-44.0, 286.0]]

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["prop_park_bench", "worn", -17.2, 321.9, 270.0],
	["prop_bike_rack", "worn", -22.2, 321.9, 0.0],
	["plant_potted_succulent", "normal", -49.8, 320.4, 90.0, false],
	["prop_trash_receptacle", "worn", -28.2, 321.9, 180.0],
	["plant_potted_leafy", "normal", -34.8, 321.4, 270.0, false],
	["plant_potted_leafy", "normal", -44.8, 320.9, 0.0, false],
	["prop_bike_rack", "worn", -39.8, 320.4, 180.0],
	["plant_potted_succulent", "normal", -21.2, 316.9, 270.0, false],
	["prop_trash_receptacle", "worn", -30.8, 317.4, 0.0],
]

func _init() -> void: _run.call_deferred()

static func pad_y(d: Array) -> float: return B3.amber(float(d[6]))
static func zs(x: float) -> float: return B3.south(x)

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b3_amber"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b3_amber")
	var yf := B3.L(B3.g)
	var look_y := B3.g(-34.0, 306.0) - B3.PAD_Y
	var kiosk_y := B3.g(-17.3, 291.0) - B3.PAD_Y
	# ================================================================ ground
	var paints: Array = []
	for d: Array in FRONT: paints.append([float(d[7]) - 0.3, float(d[2]), XF, float(d[3]), "-"])
	for t: Array in TREES: paints.append([float(t[0]) - 0.75, float(t[1]) - 0.75, float(t[0]) + 0.75, float(t[1]) + 0.75, "-"])
	for k in 10: paints.append([-50.0, 227.0 + 2.7 * k - 0.05, -45.0, 227.0 + 2.7 * k + 0.05, "white"])   # rear lot stalls (nose west), open
	for k in 7: paints.append([-50.0, 262.0 + 2.7 * k - 0.05, -45.0, 262.0 + 2.7 * k + 0.05, "white"])    # at the alley's mouth v 254..260
	paints.append_array([
		[XF, 209.7, X1, PLAZA_V, "concrete"],               # band along Amber's walk
	])
	H.paint(g, X0, 209.7, X1, PLAZA_V, paints, "asphalt", yf)
	# the plaza's strip down to the slanted Ocean Blvd edge: columns from v 280 to the edge
	var tree_holes: Array = []
	for t: Array in TREES: tree_holes.append(t)
	_plaza(g, yf, tree_holes)
	for d: Array in FRONT:
		H.level_pad(g, "concrete", float(d[7]) - 0.3, float(d[2]), XF, float(d[3]), pad_y(d) - B3.PAD_Y, yf)
	H.level_pad(g, "plaza", LOOK[0], LOOK[1], LOOK[2], LOOK[3], look_y, yf)
	H.level_pad(g, "plaza", KIOSK[0], KIOSK[1], KIOSK[2], KIOSK[3], kiosk_y, yf)
	for t: Array in TREES: S.tree_well(g, Vector2(float(t[0]), float(t[1])))
	# skirts
	H.skirt(g, Vector2(X1, 209.7), Vector2(X1, zs(X1)), yf, "concrete")
	H.skirt(g, Vector2(X0, 209.7), Vector2(X1, 209.7), yf, "concrete")
	H.skirt(g, Vector2(X0, zs(X0)), Vector2(X1, zs(X1)), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf, look_y, kiosk_y)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b3_amber")
	quit()

## the plaza between v 281 and the ring's slanted edge, holes for the lookout pad and the tree wells
func _plaza(g: K.Ground, yf: Callable, trees: Array) -> void:
	var holes: Array = [[LOOK[0], LOOK[1], LOOK[2], LOOK[3], "-"], [KIOSK[0], KIOSK[1], KIOSK[2], KIOSK[3], "-"]]
	for t: Array in trees: holes.append([float(t[0]) - 0.75, float(t[1]) - 0.75, float(t[0]) + 0.75, float(t[1]) + 0.75, "-"])
	H.paint_band(g, X0, X1, func(_x: float) -> float: return PLAZA_V, func(x: float) -> float: return zs(x), holes, "plaza", yf)

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, look_y: float, kiosk_y: float) -> void:
	for d: Array in FRONT:
		K.building(bl, String(d[1]), Vector3(float(d[5]), pad_y(d) - B3.PAD_Y, float(d[4])), 90.0, String(d[0]))
	K.building(bl, "landmarks/lmk_beach_lookout", Vector3(-37.0, look_y, 298.0), 0.0, "lookout")     # faces the ocean
	K.building(bl, "commercial/com_kiosk", Vector3(-21.5, kiosk_y, 291.0), 90.0, "kiosk")             # faces Amber
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	# ---- shop doors on the band: papers at the 11th St corner, pots at the café and the beach shop
	P.call("prop_newspaper_box_red", "worn", -16.3, 211.6, 90.0)
	P.call("prop_newspaper_box_blue", "worn", -16.3, 212.3, 90.0)
	for z: float in [231.95, 234.25, 257.73, 260.03]: P.call("plant_potted_succulent", "normal", -16.25, z, 0.0, false)
	# ---- the rear lot (off the residents' alley: its mouth at v 254..260 kept open), back doors kept clear
	for k in 9: P.call("prop_wheel_stop_concrete", "worn", -49.4, 228.35 + 2.7 * k, 90.0)
	for k in 6: P.call("prop_wheel_stop_concrete", "worn", -49.4, 263.35 + 2.7 * k, 90.0)
	P.call("prop_recycling_receptacle", "worn", -32.0, 217.6, 90.0)                  # the corner shops
	for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", -29.95, 237.0 + 0.8 * k, 90.0)   # the condos
	P.call("prop_recycling_receptacle", "worn", -31.9, 246.0, 90.0)                  # the surf shop (boxes)
	P.call("prop_dumpster_3yd_green", "worn", -32.0, 255.2, 90.0)                    # the café
	P.call("prop_dumpster_3yd_blue", "worn", -33.2, 263.6, 90.0)                     # the realty office
	P.call("prop_dumpster_3yd_green", "worn", -30.0, 277.6, 90.0)                    # the burger stand
	P.call("prop_ac_condenser", "worn", -31.9, 241.5, 90.0)
	P.call("prop_ac_condenser", "worn", -29.9, 272.0, 90.0)
	P.call("prop_lot_light_pole", "worn", -38.0, 245.0)
	P.call("prop_golf_cart_blue", "worn", -47.5, 241.85, 90.0)                       # a beach cart in a stall
	# ---- the beach plaza: palms over the benches facing the ocean, the shower where the sand comes off, bikes,
	# water, bins; bollards along Amber so no car drives in; the beach rules
	P.call("palm_queen_a", "normal", -20.0, 286.0, 0.0)
	P.call("palm_queen_b", "normal", -20.0, 300.0, 90.0)
	P.call("palm_mexican_fan_a", "normal", -30.0, 312.0, 30.0)
	P.call("palm_queen_a", "normal", -44.0, 286.0, 200.0)
	for b: Array in [[-46.0, 310.6], [-40.0, 311.4], [-25.0, 314.0], [-21.0, 314.4]]:
		P.call("prop_park_bench", "worn", float(b[0]), float(b[1]), 0.0)
	P.call("prop_beach_shower", "worn", -18.4, 318.6, 0.0)
	P.call("prop_drinking_fountain", "worn", -45.2, 300.0, 90.0)
	P.call("prop_bike_rack", "worn", -47.8, 292.0, 90.0)
	P.call("prop_bike_rack", "worn", -47.8, 296.0, 90.0)
	P.call("prop_trash_receptacle", "worn", -33.6, 311.8)
	P.call("prop_recycling_receptacle", "worn", -32.8, 311.8)
	for k in 12: P.call("prop_bollard_concrete", "worn", -16.6, 283.0 + 3.0 * k)
	P.call("prop_beach_sign_rules", "worn", -18.0, 320.6, 0.0)
	for l: Array in [[-17.2, 292.0], [-17.2, 306.0], [-46.0, 304.0], [-28.0, 286.0]]: P.call("prop_lamp_victorian", "worn", float(l[0]), float(l[1]))
	# ================================================================ wear
	for o: Array in [[-47.5, 228.35], [-47.5, 233.75], [-47.5, 244.55], [-47.5, 247.25], [-47.5, 263.35], [-47.5, 268.75], [-47.5, 274.15]]:
		W.oil(dec, rr, Vector2(float(o[0]), float(o[1])), 90.0, yf, 0.7)
	for d2: Array in [[-32.0, 255.2], [-33.2, 263.6], [-30.0, 277.6]]:
		dec.add(14, Vector2(float(d2[0]), float(d2[1])), 90.0, 3.0, 2.4, yf, Color(1, 1, 1, 0.7))
	for c: Array in [[-42.0, 235.0], [-41.0, 270.0]]:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
	dec.add(14, Vector2(-26.0, 316.0), 20.0, 8.0, 3.0, yf, Color(0.82, 0.74, 0.55, 0.4))    # sand carried up from the beach
	dec.add(14, Vector2(-20.0, 291.0), 90.0, 2.0, 2.4, yf, Color(1, 1, 1, 0.4))           # the queue at the kiosk
