extends SceneTree
## Piece n_hs_b4_amber (high street fill, block 4, part "Amber east to the beach"): u 16..50, v 209.7..Ocean Blvd: the
## east side of Amber's last stretch, from the 11th St corner down to the ring. Placed at grid [0, 4.0, 0], yaw 0.
## Run once; never when locked.
##
## WHY (planner / architect): the east side of the street's beach end, facing block 3's shops: a Spanish arcade on the
## 11th St corner (three shops under its arches), a three-storey stucco block (shop below), a pub for the evening after
## the beach, a small two-screen BEACH CINEMA with its snack bar; each on a level pad at its door's walk height (Amber
## falls 2 m here). From the cinema to the corner on Ocean Blvd: HOTEL BEL (21 Nov, Yasin: "get to work on ... hotel bel,
## make sure they look good"), the hand-made hero (landmarks/lmk_hotel_bel, the corner where the real town has its great
## beach hotel); it replaces the palm plaza and the bakery that stood there until then. Its front (the entrance porch,
## the verandas) faces Amber, its crown tower and the ocean veranda the beach; guests' cars come in from the rear lot to the
## porte-cochere at the back, round a palm island, and park in the lot. Behind: the shops' rear lot off the residents' alley.
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
]
const PLAZA_V := 289.1
## HOTEL BEL (yaw -90: its front, model +Z, faces Amber; model +X the ocean). Model origin at u 30.0, v 301.5 (model x -> v,
## model -z -> u): front wall u 23, back wall u 38, the porte-cochere out to u 44.4 (v 296.6 - 304.5), north end (the
## north turret) v 281.9, south end (crown tower, ocean veranda steps) v 321.4.
const HOTEL := Vector2(30.0, 301.5)
const HOTEL_Y := 2.40       # its pad: Amber at the entrance is 2.26, the ground under it 2.15 (south) - 2.64 (north end)
## its level pads [u0, v0, u1, v1, ground, sides with faces]: the front terrace (porches, steps, the north turret, the
## tower), the body (walls, the back stoops, the south-back turret), the ocean veranda's steps, the drive under the
## porte-cochere (cars stop level with the doors). Only outer sides get faces (where the land stands above the pad).
const HPADS := [[18.0, 281.6, 22.7, 321.2, "paving", "nsw"], [22.7, 281.6, 40.1, 319.6, "concrete", "nes"],
	[22.7, 319.6, 36.1, 321.7, "paving", "se"], [40.1, 296.3, 44.6, 304.8, "asphalt", "nse"]]
## its grounds: the paths from the Amber walk to the entrance and to both verandas' steps, a service walk between the
## cinema and the hotel to the lot, the motor court off the rear lot (asphalt) round a palm island (mulch), the path
## from the ocean veranda's steps to the Ocean Blvd walk, a promenade along Ocean Blvd (the old plaza's benches and pots
## on it, the two Canary palms in beds) and a walk down the east side to it (bike racks); lawn everywhere else
const HPAINT := [[21.6, 323.2, 23.6, 325.2, "grass"], [38.6, 322.4, 40.6, 324.4, "grass"],
	[18.0, 322.6, 50.0, 330.0, "plaza"], [45.6, 313.0, 50.0, 330.0, "plaza"], [16.6, 298.0, 18.0, 303.0, "paving"], [16.6, 289.6, 18.0, 291.4, "paving"], [16.6, 307.6, 18.0, 309.4, "paving"],
	[16.6, 278.76, 45.0, 281.6, "concrete"], [43.5, 305.6, 47.0, 309.6, "mulch"], [40.1, 281.6, 50.0, 313.0, "asphalt"],
	[31.4, 321.7, 33.4, 330.0, "paving"]]
## (its palms are not placed here: every tree of the block is a line of the hand-written tree list
## zoning/trees/hs_b4_amber.json, built into t_hs_b4_amber by tools/city/super/sc.py trees; the two grass beds above
## and the mulch island are theirs)

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["prop_bike_rack", "worn", 47.2, 323.4, 0.0],
	["plant_potted_succulent", "normal", 41.8, 323.4, 90.0],
	["prop_trash_receptacle", "worn", 36.8, 323.4, 180.0],
	["plant_potted_leafy", "normal", 25.8, 323.4, 270.0],
	["plant_potted_leafy", "normal", 31.2, 323.4, 0.0],
	["prop_park_bench", "worn", 19.8, 323.4, 90.0],
	["prop_bike_rack", "worn", 46.2, 318.4, 90.0],         # (21 Nov: turned along the new east walk)
]
## (21 Nov, Hotel Bel: the 318.9 trash bin, leafy pot and succulent pot at u 33.8 / 28.8 / 39.2 stood where the ocean veranda and the crown
## tower stand now: out. The pots carry their colliders since the superchecker's "no_collision" lines 34-38)
## SUPERCHECKER (19 Nov, review/superchecker/n_hs_b4_amber.fixes.json, Yasin: "when in doubt erase problematic props"):
## its lines carried into the script at the 21 Nov rebuild (they were made on the saved scene only): the props it erased
## that this script still places, and the collision boxes on the shop fronts' columns. Its tree lines (1-4) are the tree
## list's; its erasures of the plaza's bins and the bakery's pots went with the plaza.
const SC := {
 "out": [
	["prop_newspaper_box_blue", 16.3, 211.4, "opening: stands in front of a shop window of arcade (superchecker line 5)"],
	["prop_newspaper_box_red", 16.3, 212.1, "opening: stands in front of a shop window of arcade (line 6)"],
	["prop_trash_receptacle", 36.8, 323.4, "bin_open: stands in the open (line 8)"],
	["prop_recycling_receptacle", 34.0, 225.0, "bin_open (line 10)"],
	["prop_trash_cart_black", 31.0, 239.0, "bin_open (line 11)"],
	["prop_trash_cart_blue", 31.0, 239.8, "bin_open (line 12)"],
	["prop_trash_cart_green", 31.0, 240.6, "bin_open (line 13)"],
	["plant_potted_succulent", 16.25, 256.93, "over_edge (line 14)"],
	["plant_potted_succulent", 16.25, 259.23, "over_edge (line 15)"],
 ],
 "turn": [],
 "decals": [],
 "boxes": [
	["Buildings/arcade", [0.126333236694336, 1.49998259544373, 7.87989139556885, 0.16, 2.99996519088745, 0.16]],
	["Buildings/arcade", [8.07297992706299, 1.49998259544373, 7.87989139556885, 0.16, 2.99996519088745, 0.16]],
	["Buildings/arcade", [1.92311573028564, 1.49998259544373, 7.87989139556885, 0.16, 2.99996519088745, 0.16]],
	["Buildings/arcade", [-3.93532848358154, 1.55998694896698, 7.8299036026001, 0.72998908996582, 3.11997389793396, 0.599989929199219]],
	["Buildings/arcade", [6.10484027862549, 1.49998259544373, 7.77485752105713, 0.489859619140625, 2.99996519088745, 0.489897766113281]],
	["Buildings/arcade", [9.8165693283081, 1.49998259544373, 7.87989139556885, 0.16, 2.99996519088745, 0.16]],
	["Buildings/pub", [2.03665637969971, 1.49998259544373, 6.87985992431641, 0.16, 2.99996519088745, 0.16]],
	["Buildings/pub", [0.0131587982177734, 1.49998259544373, 6.87985992431641, 0.16, 2.99996519088745, 0.16]],
	["Buildings/cinema", [-3.80004572868347, 1.49999821186066, 5.65000009536743, 0.16, 2.99999642372131, 0.16]],
	["Buildings/cinema", [-2.2000458240509, 1.49999821186066, 5.65000009536743, 0.16, 2.99999642372131, 0.16]],
 ],
}

func _init() -> void: _run.call_deferred()

static func pad_y(d: Array) -> float: return float(d[8]) if d.size() > 8 else B4.amber(float(d[6]))
static func zs(x: float) -> float: return B4.south(x)
## the land round the hotel: graded up to its pads (6 %), faded back to the block's own height towards the Amber walk
## band (from the terrace's edge, u 18, to the band, u 16.6) and the Ocean Blvd edge (the last 2 m): the seams with the
## street pieces keep their heights, and the land has no step anywhere (it is the same function at every vertex)
static func hotel_field(yf: Callable) -> Callable:
	var pads: Array = []
	for p: Array in HPADS: pads.append([float(p[0]), float(p[1]), float(p[2]), float(p[3]), HOTEL_Y - B4.PAD_Y])
	var gr := H.graded(yf, pads)
	return func(x: float, z: float) -> float:
		var y0 := float(yf.call(x, z))
		var t := clampf((x - XF) / 1.4, 0.0, 1.0) * clampf((zs(x) - z - 0.2) / 1.8, 0.0, 1.0)
		if t <= 0.0: return y0
		return y0 + (float(gr.call(x, z)) - y0) * t

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b4_amber"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b4_amber")
	var yf := B4.L(B4.g)
	var yh := hotel_field(yf)
	# ================================================================ ground
	var paints: Array = []
	for d: Array in FRONT: paints.append([XF, float(d[2]), float(d[7]) + 0.3, float(d[3]), "-"])
	for k in 9: paints.append([45.0, 213.0 + 2.7 * k - 0.05, X1, 213.0 + 2.7 * k + 0.05, "white"])     # rear lot stalls, nose east
	for k in 10: paints.append([45.0, 262.0 + 2.7 * k - 0.05, X1, 262.0 + 2.7 * k + 0.05, "white"])    # (the alley's mouth v 254..260 open)
	paints.append([X0, 209.7, XF, PLAZA_V, "concrete"])                                                 # the band along Amber's walk
	var hp: Array = []
	for p: Array in HPADS: hp.append([float(p[0]), float(p[1]), float(p[2]), float(p[3]), "-"])
	hp.append_array(HPAINT)
	paints.append([16.6, 281.6, 18.0, PLAZA_V, "grass"])    # the lawn strip in front of the terrace (after its path)
	paints.append_array(hp)
	H.paint(g, X0, 209.7, X1, PLAZA_V, paints, "asphalt", yh)
	var holes: Array = [[X0, PLAZA_V, XF, 330.0, "plaza"]]  # the band along Amber's walk, on to Ocean Blvd
	holes.append_array(hp)
	H.paint_band(g, X0, X1, func(_x: float) -> float: return PLAZA_V, func(x: float) -> float: return zs(x), holes, "grass", yh)
	for d: Array in FRONT:
		H.level_pad(g, "concrete", XF, float(d[2]), float(d[7]) + 0.3, float(d[3]), pad_y(d) - B4.PAD_Y, yh)
	for p: Array in HPADS:
		H.level_pad(g, String(p[4]), float(p[0]), float(p[1]), float(p[2]), float(p[3]), HOTEL_Y - B4.PAD_Y, yh, String(p[5]))
	H.skirt(g, Vector2(X0, 209.7), Vector2(X0, zs(X0)), yf, "concrete")
	H.skirt(g, Vector2(X0, 209.7), Vector2(X1, 209.7), yf, "concrete")
	H.skirt(g, Vector2(X0, zs(X0)), Vector2(X1, zs(X1)), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf, yh)
	if PASS >= 2: H.polish(props, g, POLISH)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_hs_b4_amber")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, yh: Callable) -> void:
	for d: Array in FRONT:
		K.building(bl, String(d[1]), Vector3(float(d[5]), pad_y(d) - B4.PAD_Y, float(d[4])), -90.0, String(d[0]))
	K.building(bl, "landmarks/lmk_hotel_bel", Vector3(HOTEL.x, HOTEL_Y - B4.PAD_Y, HOTEL.y), -90.0, "hotel_bel")
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yh, yaw, collide)
	# ---- shop fronts on the band: pots by the pub, papers on the 11th St corner, the cinema's poster stand is in its model
	P.call("prop_newspaper_box_blue", "worn", 16.3, 211.4, -90.0)
	P.call("prop_newspaper_box_red", "worn", 16.3, 212.1, -90.0)
	for z: float in [256.93, 259.23]: P.call("plant_potted_succulent", "normal", 16.25, z, 0.0, false)
	# ---- Hotel Bel's grounds (its palms: the tree list): a low boxwood hedge along the terrace's edge on Amber (open at the three
	# paths), lamps at the entrance path, the court and the ocean path, benches on the
	# ocean lawn facing the beach (with the POLISH row at v 323.4), iron bollards where the court meets the lawn, bike
	# racks on the east lawn
	for h: Array in [[281.8, 289.4], [291.6, 297.2], [303.8, 307.4], [309.6, 321.0]]:
		H.hedge(props, Vector2(17.75, float(h[0])), Vector2(17.75, float(h[1])), yh)
	for l: Array in [[17.1, 297.4], [17.1, 303.6], [17.1, 306.9], [41.0, 290.2], [46.8, 305.3], [34.0, 324.4]]: P.call("prop_lamp_victorian", "worn", float(l[0]), float(l[1]))
	for b: Array in [[28.4, 324.4], [44.2, 324.0]]: P.call("prop_park_bench", "worn", float(b[0]), float(b[1]), 0.0)
	for k in 5: P.call("prop_bollard_iron", "worn", 41.0 + 2.0 * k, 313.3)
	for z: float in [314.8, 320.6]: P.call("prop_bike_rack", "worn", 49.0, z, 90.0)
	# ---- the rear lot (back doors kept clear: arcade v 212.85 / 220.85 / 228.85, stucco 245.32, pub 263.14,
	# cinema 268.96 / 276.96, the hotel's kitchen door v 286.1 and its porte-cochere)
	for k in 8: P.call("prop_wheel_stop_concrete", "worn", 49.4, 214.35 + 2.7 * k, 90.0)
	for k in 9: P.call("prop_wheel_stop_concrete", "worn", 49.4, 263.35 + 2.7 * k, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", 34.4, 216.8, 90.0)                       # the arcade's café (food)
	P.call("prop_recycling_receptacle", "worn", 34.0, 225.0, 90.0)
	for k in 3: P.call(["prop_trash_cart_black", "prop_trash_cart_blue", "prop_trash_cart_green"][k], "worn", 31.0, 239.0 + 0.8 * k, 90.0)   # flats
	P.call("prop_dumpster_3yd_blue", "worn", 31.4, 250.6, 90.0)
	P.call("prop_dumpster_3yd_green", "worn", 32.4, 260.0, 90.0)                       # the pub (bottles, kitchen)
	P.call("prop_recycling_receptacle", "worn", 29.9, 272.9, 90.0)                     # the cinema's snack bar
	P.call("prop_dumpster_3yd_green", "worn", 41.6, 283.0, 90.0)                       # the hotel's kitchen (service door v 286)
	P.call("prop_ac_condenser", "worn", 34.2, 232.0, 90.0)
	P.call("prop_lot_light_pole", "worn", 40.0, 240.0)
	P.call("prop_lot_light_pole", "worn", 44.6, 287.0)                                 # (off the hotel's back wall, between court and stalls)
	# ================================================================ wear
	for o: Array in [[47.5, 214.35], [47.5, 219.75], [47.5, 227.85], [47.5, 263.35], [47.5, 271.45], [47.5, 279.55]]:
		W.oil(dec, rr, Vector2(float(o[0]), float(o[1])), 90.0, yf, 0.7)
	for d2: Array in [[34.4, 216.8], [31.4, 250.6], [32.4, 260.0], [41.6, 283.0]]:
		dec.add(14, Vector2(float(d2[0]), float(d2[1])), 90.0, 3.0, 2.4, yf, Color(1, 1, 1, 0.7))
	for c: Array in [[40.0, 230.0], [41.0, 270.0], [46.0, 293.0]]:                     # (the third in the hotel's court now)
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yh, Color(0.14, 0.14, 0.14, 0.9))
	dec.add(14, Vector2(32.4, 324.0), 0.0, 2.0, 4.0, yh, Color(0.82, 0.74, 0.55, 0.35))     # sand carried up from the beach (the ocean path)
