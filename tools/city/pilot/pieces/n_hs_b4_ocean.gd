extends SceneTree
## Piece n_hs_b4_ocean (high street fill, block 4, part "Ocean Park"): u 50..190, v 254..Ocean Blvd, between the
## Amber shops' rear lot (west), the residents' alley (north, v 254..260, carried from B Ave to the rear lot), the
## B Ave houses' service alley (east) and Ocean Blvd (south). Placed at grid [0, 4.0, 0], yaw 0. Run once; never when
## locked.
##
## WHY (planner): block 3 across Amber gives the beach a motel; this side gives the town's young people a place by the
## beach: OCEAN PARK. A skate plaza (quarter pipes, a funbox, a bowl section, rails) in front of the SKATE SHOP (its
## shed rents and sells boards, a walk-in room), a sand volleyball court on the west lawn, a picnic lawn with palms on
## the east; parking for the park off the alley; one path from the parking down the park to its gate on Ocean Blvd and
## a cross path linking the three; a low hedge along the boulevard (the gate the one opening). The east end walk from
## 11th St (in n_hs_b4_eleventh) continues across the alley into the park.
## LAND: falls 1.5 % south and west (5.2 at the alley's east end to 2.2 at the boulevard's west end). The skate shop
## stands on a level pad at its front's height, cut into the slope behind (a retaining wall toward the alley); the
## plaza, the court, the lawns and the paths follow the surface (no wall anywhere a skater or a ball runs).
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B4 := preload("res://tools/city/pilot/pieces/n_hs_b4_site.gd")

const X0 := 50.0
const X1 := 190.0
const ALLEY := [254.0, 260.0]
const PARK_LOT := [52.0, 260.0, 103.3, 266.0]         # nose-in off the alley, 19 stalls
const SHED := [120.4, 266.4, 135.6, 282.4]            # the skate shop's pad (front walk included)
const SHED_C := Vector2(128.0, 273.5)                 # the shed (yaw 0: front +v, the shop door at u 124.4)
const PLAZA := [108.0, 282.4, 150.0, 306.0]           # the skate plaza
const COURT := [62.0, 286.0, 84.0, 312.0]             # sand volleyball
const PATH_U := [103.6, 106.6]                        # the main path, parking -> gate
const CROSS_V := [312.4, 314.8]                       # the cross path
const EAST_WALK := [184.6, 188.6]                     # from 11th St's walk across the alley into the park

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["palm_queen_a", "normal", 52.8, 324.8, 301.0],
	["prop_picnic_table", "worn", 52.8, 315.8, 80.0],
	["tree_jacaranda_b", "normal", 62.2, 324.8, 47.0],
	["prop_picnic_table", "worn", 52.8, 306.8, 154.0],
	["tree_magnolia_b", "normal", 52.8, 297.8, 153.0],
	["prop_picnic_table", "worn", 187.2, 326.2, 48.0],
	["tree_torrey_pine_b", "normal", 52.8, 288.8, 259.0],
	["prop_picnic_table", "worn", 52.8, 272.2, 122.0],
	["plant_bird_of_paradise", "normal", 52.8, 319.8, 129.0, false],
	["plant_iceplant_patch", "normal", 52.8, 309.8, 271.0, false],
	["prop_sprinkler_popup", "worn", 58.2, 319.8, 342.0, false],
	["plant_agave_americana", "normal", 63.2, 319.8, 53.0, false],
	["plant_bird_of_paradise", "normal", 52.8, 294.8, 124.0, false],
	["plant_bougainvillea_mound", "normal", 58.2, 310.2, 195.0, false],
	["plant_iceplant_patch", "normal", 68.2, 324.8, 266.0, false],
	["prop_sprinkler_popup", "worn", 52.8, 284.8, 337.0, false],
	["plant_agave_americana", "normal", 52.8, 278.8, 48.0, false],
	["prop_park_bench", "worn", 186.2, 312.8, 270.0],
	["prop_bike_rack", "worn", 104.8, 314.2, 0.0],
]

func _init() -> void: _run.call_deferred()

static func shed_y() -> float: return B4.g(SHED_C.x, SHED[3])

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b4_ocean"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b4_ocean")
	var yf := B4.L(B4.g)
	var top := func(_x: float) -> float: return ALLEY[0]
	var sth := func(x: float) -> float: return B4.south(x)
	# ================================================================ ground
	var paints: Array = [[SHED[0], SHED[1], SHED[2], SHED[3], "-"]]
	for k in 20: paints.append([PARK_LOT[0] + 0.4 + 2.7 * k - 0.05, ALLEY[1], PARK_LOT[0] + 0.4 + 2.7 * k + 0.05, PARK_LOT[3] - 0.4, "white"])
	paints.append_array([
		[X0, ALLEY[0], X1, ALLEY[1], "asphalt"],                                # the residents' alley
		[PARK_LOT[0], PARK_LOT[1], PARK_LOT[2], PARK_LOT[3], "asphalt"],
		[PATH_U[0], ALLEY[1], PATH_U[1], 340.0, "plaza"],                       # the main path to the gate
		[56.0, CROSS_V[0], 186.0, CROSS_V[1], "plaza"],                         # the cross path
		[EAST_WALK[0], ALLEY[1], EAST_WALK[1], CROSS_V[1], "plaza"],
		[PLAZA[0], PLAZA[1], PLAZA[2], PLAZA[3], "concrete"],
		[COURT[0], COURT[1], COURT[2], COURT[3], "sand"],
		[106.6, 266.4, SHED[0], 270.0, "concrete"],                            # the shop's side walk from the path
	])
	H.paint_band(g, X0, X1, top, sth, paints, "grass", yf)
	H.level_pad(g, "concrete", SHED[0], SHED[1], SHED[2], SHED[3], shed_y() - B4.PAD_Y, yf)
	H.skirt(g, Vector2(X0, B4.south(X0)), Vector2(X1, B4.south(X1)), yf, "concrete")
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b4_ocean")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var ys := shed_y() - B4.PAD_Y
	var yp := func(_x: float, _z: float) -> float: return ys
	K.building(bl, "public/pub_skate_shed", Vector3(SHED_C.x, ys, SHED_C.y), 0.0, "skate")
	# ---- the shop's front walk: boards on a rack outside the door (rentals), a bench, a bin; the roll-up door clear
	H.put(props, "prop_surfboard_rack", "clean", 121.6, 281.4, yp, 0.0)
	H.put(props, "prop_park_bench", "worn", 134.0, 281.6, yp, 180.0)
	H.put(props, "prop_trash_receptacle", "worn", 121.4, 279.0, yp)
	# ---- the skate plaza: quarter pipes facing each other across the run, a funbox in the middle, rails along the
	# sides, the bowl section in the far corner; benches round the edge for those watching
	P.call("prop_skate_quarter_pipe", "worn", 111.4, 294.0, 90.0)
	P.call("prop_skate_quarter_pipe", "worn", 146.6, 294.0, -90.0)
	P.call("prop_skate_funbox", "worn", 129.0, 294.0, 0.0)
	P.call("prop_skate_grind_rail", "worn", 120.0, 287.0, 0.0)
	P.call("prop_skate_grind_rail", "worn", 138.0, 287.0, 0.0)
	P.call("prop_skate_grind_rail", "worn", 129.0, 301.2, 0.0)
	P.call("prop_skate_bowl_section", "worn", 145.0, 302.0, 180.0)
	P.call("prop_skate_bowl_section", "worn", 113.0, 302.0, 180.0)
	for b: Array in [[109.4, 284.0, 90.0], [148.8, 285.0, -90.0], [124.0, 305.4, 180.0], [134.0, 305.4, 180.0]]:
		P.call("prop_park_bench", "worn", float(b[0]), float(b[1]), float(b[2]))
	P.call("prop_bike_rack", "worn", 107.4, 290.0, 90.0)
	P.call("prop_bike_rack", "worn", 107.4, 296.0, 90.0)
	P.call("prop_drinking_fountain", "worn", 107.3, 302.0, 90.0)
	P.call("prop_trash_receptacle", "worn", 149.4, 296.0)
	for l: Array in [[107.2, 286.0], [150.8, 286.0], [107.2, 305.0], [150.8, 305.0]]: P.call("prop_lamp_globe", "worn", float(l[0]), float(l[1]))
	# ---- the volleyball court: the net across the middle, a bench and a bin on its edge, a palm at each end
	P.call("prop_volleyball_net", "clean", 73.0, 299.0, 0.0)
	P.call("prop_park_bench", "worn", 86.0, 296.0, -90.0)
	P.call("prop_park_bench", "worn", 86.0, 302.0, -90.0)
	P.call("prop_trash_receptacle", "worn", 86.0, 299.0)
	P.call("prop_beach_shower", "worn", 60.0, 299.0, 0.0)                          # sand off before the car
	# ---- the picnic lawn (east): tables under the palms, grills by them, a bench along the cross path
	for t: Array in [[160.0, 290.0, 0.0], [170.0, 296.0, 20.0], [180.0, 288.0, 90.0], [164.0, 304.0, 0.0], [178.0, 304.0, 0.0]]:
		P.call("prop_picnic_table", "worn", float(t[0]), float(t[1]), float(t[2]))
	P.call("prop_bbq_kettle", "worn", 162.6, 291.6)
	P.call("prop_bbq_kettle", "worn", 176.0, 305.8)
	P.call("prop_trash_receptacle", "worn", 172.0, 311.6)
	P.call("prop_recycling_receptacle", "worn", 172.8, 311.6)
	# ---- trees (in grass only): palms along the boulevard inside the hedge, shade trees on the lawns
	for k in 7:
		var x := 58.0 + 20.0 * k
		if absf(x - 105.1) < 4.0: x += 6.0
		P.call(["palm_mexican_fan_a", "palm_mexican_fan_b", "palm_mexican_fan_c"][k % 3], "normal", x, B4.south(x) - 3.4, float(k) * 41.0)
	for t2: Array in [["tree_coral_a", 156.0, 282.0], ["tree_ficus_b", 184.0, 296.0], ["palm_queen_a", 168.0, 286.0], ["palm_queen_b", 160.0, 300.0],
			["tree_jacaranda_a", 94.0, 290.0], ["tree_coral_b", 56.0, 276.0], ["tree_ficus_a", 92.0, 276.0], ["tree_magnolia_b", 150.0, 272.0]]:
		P.call(String(t2[0]), "normal", float(t2[1]), float(t2[2]), float(t2[1]) * 3.0)
	# ---- the hedge along Ocean Blvd, open only at the gate (the main path)
	H.hedge(props, Vector2(51.0, B4.south(51.0) - 1.1), Vector2(PATH_U[0] - 0.6, B4.south(PATH_U[0] - 0.6) - 1.1), yf)
	H.hedge(props, Vector2(PATH_U[1] + 0.6, B4.south(PATH_U[1] + 0.6) - 1.1), Vector2(189.0, B4.south(189.0) - 1.1), yf)
	P.call("prop_beach_sign_rules", "worn", PATH_U[1] + 0.9, B4.south(106.6) - 2.0, 0.0)     # the park's rules at the gate
	# ---- lamps along the main path and the cross path, benches facing the lawns
	for v: float in [272.0, 290.0, 308.0, 324.0]: P.call("prop_lamp_globe", "worn", PATH_U[1] + 0.5, v)
	for x2: float in [70.0, 140.0, 165.0]: P.call("prop_lamp_globe", "worn", x2, CROSS_V[1] + 0.5)
	for b2: Array in [[90.0, 316.0, 180.0], [120.0, 316.0, 180.0], [150.0, 316.0, 180.0]]: P.call("prop_park_bench", "worn", float(b2[0]), float(b2[1]), float(b2[2]))
	# ---- the park's parking: wheel stops, a light, oil
	for k in 19:
		var xc := PARK_LOT[0] + 0.4 + 2.7 * k + 1.35
		P.call("prop_wheel_stop_concrete", "worn", xc, PARK_LOT[3] - 0.6, 0.0)
		if k % 3 == 0: W.oil(dec, rr, Vector2(xc, 263.6), 0.0, yf, 0.6)
	P.call("prop_lot_light_pole", "worn", 78.0, 266.8)
	# ---- the alley
	W.lane_wear(dec, rr, 257.0, X0, X1, false, yf)
	for c: Array in [[80.0, 257.5], [150.0, 256.5]]:
		dec.add(0, Vector2(float(c[0]), float(c[1])), rr.randf_range(0, 360), 4.0, 1.6, yf, Color(0.14, 0.14, 0.14, 0.9))
	dec.add(14, Vector2(128.0, 296.0), 0.0, 30.0, 16.0, yf, Color(0.2, 0.2, 0.2, 0.12))      # the plaza's wheel grime
