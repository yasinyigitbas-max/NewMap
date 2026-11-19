extends SceneTree
## Piece n_hs_b2_park (high street fill, block 2, part "Tenth Street Park"): u -100..-50, v -60..-9.2, between the
## residential growth on the west (r_q_m200_0_ne), 10th St on the south, the pilot's alley (b_nw) on the east and the
## residents' alley (carried through, v -60..-54) on the north. Placed at grid [0, 4.0, 0], yaw 0. Run once; never when
## locked.
##
## WHY (city planner): the high street and the flats round it have no green to sit in (the pilot's pocket park is a
## bandstand plaza). A neighbourhood park on 10th St, a block from Amber: a level play pad with swings, slide and a
## climbing frame and benches watching it, two picnic tables each under its own sail with a grill, a drinking fountain
## at the central plaza, beds along the fence, shade trees, lamps. Enclosed by an iron fence with ONE gate on 10th St
## (Yasin: park enclosures closed, one entrance), a privacy fence to the neighbours' gardens. North of it the houses'
## rear alley runs on through to the pilot's alley.
## LAND: nearly flat (4.15 at 10th St, up to 4.27 at the alley on the west); the play and picnic pads are level with a
## low edge.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const B2 := preload("res://tools/city/pilot/pieces/n_hs_b2_site.gd")

const X0 := -100.0
const X1 := -50.0
const ZN := -60.0
const Z_AL := -54.0          # the alley's south edge
const Z_BED := -12.6         # the planted bed along 10th St (inside the fence at v -10.4) ends here
const PLAY := [-97.0, -50.0, -85.0, -38.0]       # level bark pad
const PICNIC := [-65.0, -50.0, -53.0, -36.0]     # level paved pad

## POLISH (19 Nov, Yasin: "run a polish pass ... plenty of props"): more planting, trees, lawn sprinklers, benches, planters
## and racks, each on a free spot of open lawn or paving this piece already had (found by a scratch tool, OUT/py/freespots.py,
## chosen per kind of place by hand and frozen here); each stands on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["palm_queen_a", "normal", -99.8, -35.2, 31.0],
	["prop_picnic_table", "worn", -99.2, -17.8, 170.0],
	["tree_jacaranda_b", "normal", -95.8, -26.2, 137.0],
	["prop_picnic_table", "worn", -90.8, -35.8, 64.0],
	["tree_magnolia_b", "normal", -82.8, -49.2, 243.0],
	["prop_picnic_table", "worn", -90.2, -18.8, 138.0],
	["tree_torrey_pine_b", "normal", -82.2, -39.8, 349.0],
	["prop_picnic_table", "worn", -86.8, -27.8, 32.0],
	["plant_bird_of_paradise", "normal", -99.8, -23.2, 219.0, false],
	["plant_bougainvillea_mound", "normal", -99.2, -40.2, 290.0, false],
	["plant_iceplant_patch", "normal", -94.8, -22.8, 1.0, false],
	["prop_sprinkler_popup", "worn", -94.8, -15.2, 72.0, false],
	["plant_agave_americana", "normal", -90.8, -30.2, 143.0, false],
	["plant_bird_of_paradise", "normal", -87.8, -35.8, 214.0, false],
	["plant_bougainvillea_mound", "normal", -89.8, -25.2, 285.0, false],
	["plant_iceplant_patch", "normal", -77.8, -49.2, 356.0, false],
	["prop_sprinkler_popup", "worn", -88.8, -14.8, 67.0, false],
	["plant_agave_americana", "normal", -82.8, -34.8, 138.0, false],
	["prop_park_bench", "worn", -77.8, -32.8, 90.0],
	["prop_bike_rack", "worn", -77.8, -27.8, 180.0],
	["plant_potted_succulent", "normal", -72.8, -32.8, 270.0, false],
	["prop_trash_receptacle", "worn", -62.8, -47.8, 0.0],
	["plant_potted_leafy", "normal", -72.8, -27.8, 90.0, false],
	["plant_potted_leafy", "normal", -63.8, -42.8, 180.0, false],
]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hs_b2_park"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hs_b2_park")
	var yf := B2.L(B2.g)
	var e10 := func(x: float) -> float: return B2.edge10(x)
	var zb := func(_x: float) -> float: return Z_BED
	# ================================================================ ground
	# the bed along 10th St (planting inside the fence), open at the gate
	for r: Array in [[X0, -77.0, "mulch"], [-77.0, -73.0, "plaza"], [-73.0, X1, "mulch"]]:
		H.band(g, String(r[2]), float(r[0]), float(r[1]), zb, e10, yf)
	var py := _pad_y(PLAY, yf); var qy := _pad_y(PICNIC, yf)
	var paints := [
		[PLAY[0], PLAY[1], PLAY[2], PLAY[3], "-"], [PICNIC[0], PICNIC[1], PICNIC[2], PICNIC[3], "-"],
		[-76.2, -25.0, -73.8, Z_BED, "plaza"],              # entry path from the gate
		[-80.0, -35.0, -70.0, -25.0, "plaza"],              # central plaza (fountain, benches)
		[-85.0, -31.0, -80.0, -29.0, "plaza"], [-70.0, -31.0, -65.0, -29.0, "plaza"],
		[-76.0, -44.0, -74.0, -35.0, "plaza"],              # plaza -> the cross path between the pads
		[-85.0, -44.0, -65.0, -42.0, "plaza"],
		[-98.5, -53.0, -51.5, -51.5, "mulch"],              # bed along the back fence
	]
	H.paint(g, X0, Z_AL, X1, Z_BED, paints, "grass", yf)
	H.level_pad(g, "mulch", PLAY[0], PLAY[1], PLAY[2], PLAY[3], py, yf)
	H.level_pad(g, "plaza", PICNIC[0], PICNIC[1], PICNIC[2], PICNIC[3], qy, yf)
	# the alley, carried through (gutter in line with the houses' alley)
	H.paint(g, X0, ZN, X1, Z_AL, [[X0, -57.4, X1, -56.6, "concrete"]], "asphalt", yf)
	# skirts
	var wbot := func(_x: float, z: float) -> float: return B2.west_skirt_bot(z)
	H.skirt(g, Vector2(X0, ZN), Vector2(X0, -9.2), yf, "wall", wbot)
	var pts := PackedVector2Array()
	for k in 26: pts.append(Vector2(lerpf(X0, X1, k / 25.0), B2.edge10(lerpf(X0, X1, k / 25.0))))
	for k in pts.size() - 1: H.skirt(g, pts[k], pts[k + 1], yf, "concrete")
	H.skirt(g, Vector2(X1, ZN), Vector2(X1, B2.edge10(X1)), yf, "wall")
	if PASS >= 2: _build(props, dec, rr, yf, py, qy)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hs_b2_park")
	quit()

## a pad stands at the field's height at its middle
static func _pad_y(r: Array, yf: Callable) -> float:
	return float(yf.call((float(r[0]) + float(r[2])) * 0.5, (float(r[1]) + float(r[3])) * 0.5))

func _build(props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, py: float, qy: float) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var ypl := func(_x: float, _z: float) -> float: return py
	var ypc := func(_x: float, _z: float) -> float: return qy
	# ---- the enclosure: iron on the streets and the alley, privacy wood to the neighbours' gardens; ONE gate on 10th St
	H.fence(props, "fence_wrought_iron", "fence_post_wrought_iron", Vector2(-99.5, -10.4), Vector2(-77.0, -10.4), yf, 1.98)
	H.fence(props, "fence_wrought_iron", "fence_post_wrought_iron", Vector2(-73.0, -10.4), Vector2(-50.5, -10.4), yf, 1.98)
	H.fence(props, "fence_wrought_iron", "fence_post_wrought_iron", Vector2(-50.5, -53.6), Vector2(-50.5, -10.4), yf, 1.98)
	H.fence(props, "fence_wrought_iron", "fence_post_wrought_iron", Vector2(-99.5, -53.6), Vector2(-50.5, -53.6), yf, 1.98)
	H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(-99.5, -53.6), Vector2(-99.5, -10.4), yf, 2.01)
	P.call("fence_gate_wrought_iron", "worn", -77.0, -10.95, 90.0)            # the two gate leaves stand open, swung in
	P.call("fence_gate_wrought_iron", "worn", -73.0, -10.95, 90.0)
	P.call("prop_beach_sign_rules", "worn", -78.0, -12.9, 180.0)              # park rules, facing those coming in
	P.call("prop_trash_receptacle", "worn", -78.6, -14.0)
	P.call("prop_recycling_receptacle", "worn", -71.4, -14.0)
	P.call("prop_bike_rack", "worn", -66.0, -13.4, 0.0)                        # along the fence, out of the paths
	# ---- the bed along 10th St, inside the fence
	for pl: Array in [["plant_bird_of_paradise", -96.0], ["plant_agave_americana_small", -91.0], ["plant_bird_of_paradise", -86.0],
			["plant_agave_americana_small", -81.5], ["plant_agave_americana_small", -68.5], ["plant_bird_of_paradise", -63.0],
			["plant_agave_americana_small", -58.0], ["plant_bird_of_paradise", -53.5]]:
		P.call(String(pl[0]), "normal", float(pl[1]), -11.6, 0.0, false)
	for x: float in [-95.0, -85.0, -65.0, -55.0]: P.call("plant_bird_of_paradise", "normal", x, -52.25, 0.0, false)   # back bed
	# ---- the play pad (level bark): swings, slide, climbing frame; parents' benches watching it
	H.put(props, "prop_swing_set", "worn", -93.5, -46.4, ypl, 0.0)
	H.put(props, "prop_slide", "worn", -87.4, -45.0, ypl, 0.0)
	H.put(props, "prop_play_structure", "worn", -92.2, -41.0, ypl, 90.0)
	P.call("prop_park_bench", "worn", -91.0, -36.9, 180.0)
	P.call("prop_park_bench", "worn", -83.9, -47.6, -90.0)
	P.call("prop_trash_receptacle", "worn", -83.9, -45.5)
	# ---- the picnic pad (level): two tables each under its own sail, a grill between them, a bin at its corner
	for t: Array in [[-61.0, -46.0], [-57.0, -40.0]]:
		H.put(props, "prop_picnic_table", "worn", float(t[0]), float(t[1]), ypc, 0.0)
		H.put(props, "prop_shade_sail", "worn", float(t[0]), float(t[1]), ypc, 0.0, false)
	H.put(props, "prop_bbq_kettle", "worn", -55.0, -47.6, ypc, 0.0)
	H.put(props, "prop_trash_receptacle", "worn", -64.3, -36.7, ypc, 0.0)
	# ---- the plaza: benches round it (clear of the paths), the drinking fountain, lamps along the paths
	for b: Array in [[-79.4, -33.5, 90.0], [-70.6, -33.5, -90.0], [-79.4, -26.5, 90.0], [-70.6, -26.5, -90.0]]:
		P.call("prop_park_bench", "worn", float(b[0]), float(b[1]), float(b[2]))
	P.call("prop_drinking_fountain", "worn", -72.0, -34.4, 0.0)
	for l: Array in [[-77.3, -19.0], [-72.7, -14.0], [-81.0, -24.4], [-69.0, -35.6], [-84.6, -38.4], [-65.4, -35.0]]:
		P.call("prop_lamp_globe", "worn", float(l[0]), float(l[1]))
	# ---- shade trees on the lawn (>= 0.9 m from every fence)
	for t: Array in [["tree_coral_a", -95.0, -20.0], ["tree_jacaranda_a", -60.0, -20.0], ["tree_magnolia_b", -92.0, -30.0],
			["tree_torrey_pine_a", -56.0, -29.0], ["palm_queen_a", -66.5, -17.0]]:
		P.call(String(t[0]), "normal", float(t[1]), float(t[2]), float(t[1]) * 5.0)
	# ---- the alley: a drain at its low end
	P.call("prop_storm_drain_grate", "worn", -55.0, -57.0, 0.0, false)
	# ================================================================ wear
	W.lane_wear(dec, rr, -57.0, -100.0, -50.0, false, yf)
	dec.add(14, Vector2(-75.0, -18.0), 0.0, 1.6, 12.0, yf, Color(1, 1, 1, 0.3))          # the walking line in from the gate
	dec.add(14, Vector2(-93.5, -46.4), 0.0, 2.8, 1.8, ypl, Color(0.78, 0.7, 0.48, 0.55)) # bark scuffed under the swings
	dec.add(14, Vector2(-83.0, -36.5), 45.0, 1.3, 3.6, yf, Color(0.78, 0.7, 0.48, 0.5))  # the shortcut over the grass to the swings
	dec.add(14, Vector2(-55.0, -47.6), 0.0, 1.4, 1.4, ypc, Color(1, 1, 1, 0.55))         # under the grill
