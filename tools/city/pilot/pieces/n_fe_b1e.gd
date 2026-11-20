extends SceneTree
## Piece n_fe_b1e (fe fill, block 1 east): CROWN HILL CORNERS (shops on the strip's edge) and CROWN HILL MEWS
## (townhouses on two mews and garden apartments on the -800 street).
## u 375 (r_q_250_m1000_se / n_fe_b1w) .. 491 (the u 500 street's west walk), v -991 (the -1000 street's south walk)
## .. -809 (the -800 street's north walk). Placed at grid [0, 4.0, 0], yaw 0. Run once.
##
## WHY (planner): north, across the -1000 street, the commercial strip begins (motels, gas, drive-thrus); south, the
## apartment band. So the north edge gets the neighbourhood's own small shops (a laundromat, a cafe, a barber in a
## two-storey row, a corner market and a pharmacy counter on the corner of the u 500 street), for the people of the
## mews, the garden apartments and the houses behind, who walk in, and for the drivers off the strip, who park in the
## shops' lot. The lot's only car opening is the -1000 street's apron (u 440 .. 446).
## South of the shops the land falls 1.5 m from south-west to north-east: TOWNHOUSES (garages on the front, gardens on
## the back) on two mews lanes that come in at the u 500 street's two aprons (v -946 .. -940 and -860 .. -854), so no
## new driveway touches a street; between the mews a shared GREEN with a small play corner; along the -800 street three
## GARDEN APARTMENTS facing the apartments across it, their stalls on the second mews.
## LAND: the ground follows the land (n_fe_site.g "b1"), eased onto every walk within 12 m; every building on a level
## pad at the highest ground under it, the field graded up to it at 6 % (a forecourt, a mews apron, never a kerb).
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fe_site.gd")

const BLK := "b1"
const X0 := 375.0
const X1 := 491.0
const Z0 := -991.0
const Z1 := -809.0
const B := [
	["shops", "commercial/com_orange_row", 397.0, -976.83, 180.0],       # front on the -1000 street's forecourt at v -985
	["corner", "commercial/com_orange_corner", 474.0, -976.83, 180.0],
	["t1", "apartments/apt_townhouse_cays", 394.0, -955.4, 0.0],         # mews 1 north row: fronts (garages) at v -949
	["t2", "apartments/apt_townhouse_modern", 417.5, -955.4, 0.0],
	["t3", "apartments/apt_townhouse_cays", 441.0, -955.4, 0.0],
	["t4", "apartments/apt_townhouse_modern", 464.5, -955.4, 0.0],
	["t5", "apartments/apt_townhouse_modern", 394.0, -932.6, 180.0],     # mews 1 south row: fronts at v -939
	["t6", "apartments/apt_townhouse_cays", 417.5, -932.6, 180.0],
	["t7", "apartments/apt_townhouse_modern", 441.0, -932.6, 180.0],
	["t8", "apartments/apt_townhouse_cays", 464.5, -932.6, 180.0],
	["t9", "apartments/apt_townhouse_cays", 394.0, -868.4, 0.0],         # mews 2 north row: fronts at v -862
	["t10", "apartments/apt_townhouse_modern", 417.5, -868.4, 0.0],
	["t11", "apartments/apt_townhouse_cays", 441.0, -868.4, 0.0],
	["t12", "apartments/apt_townhouse_modern", 464.5, -868.4, 0.0],
	["g1", "apartments/apt_garden_mint", 396.0, -821.1, 0.0],            # fronts on the -800 street at v -815
	["g2", "apartments/apt_garden_cream", 432.0, -821.1, 0.0],
	["g3", "apartments/apt_garden_mint", 468.0, -821.1, 0.0],
]
const LOT := [412.0, -985.0, 462.0, -967.0]
const M1 := [-948.0, -940.0]
const M2 := [-861.0, -853.0]
const PLAY := [400.0, -912.0, 414.0, -900.0]

const ITEMS := [
	# the shops' forecourt on the -1000 street: the cafe's tables by its door, benches facing the street, planters
	# between the bays, paper boxes at the corner where people wait to cross
	["prop_patio_set_4", "worn", 394.0, -987.4, 0.0], ["prop_patio_set_4", "worn", 404.8, -987.4, 15.0],
	["plant_potted_leafy", "normal", 391.4, -985.6, 0.0], ["plant_potted_succulent", "normal", 408.2, -985.6, 0.0],
	["prop_park_bench", "worn", 384.0, -989.6, 180.0], ["prop_park_bench", "worn", 466.0, -989.6, 180.0],
	["prop_newspaper_box_red", "worn", 488.6, -989.4, 90.0], ["prop_newspaper_box_blue", "worn", 488.6, -988.6, 90.0],
	["plant_potted_leafy", "normal", 470.0, -985.6, 0.0], ["plant_potted_leafy", "normal", 478.6, -985.6, 0.0],
	# the green between the mews: picnic tables and benches round the lawn, the play corner on bark, sprinklers
	["prop_picnic_table", "worn", 430.0, -905.0, 90.0], ["prop_picnic_table", "worn", 452.0, -895.0, 0.0],
	["prop_park_bench", "worn", 416.6, -906.0, -90.0], ["prop_park_bench", "worn", 466.0, -906.0, -90.0],
	["prop_park_bench", "worn", 444.4, -886.0, 90.0],
	["prop_swing_set", "worn", 407.0, -908.5, 0.0], ["prop_slide", "worn", 410.5, -903.0, 90.0],
	["prop_drinking_fountain", "worn", 418.5, -900.8, 0.0],
	["prop_sprinkler_impact", "normal", 445.0, -910.0, 0.0, false], ["prop_sprinkler_impact", "normal", 470.0, -890.0, 0.0, false],
	# the townhouses' back gardens on the green: a chair pair or a grill at each, the bougainvillea on the end walls
	["prop_adirondack_wood", "worn", 390.0, -922.2, 180.0], ["prop_bbq_kettle", "worn", 421.0, -922.4, 0.0],
	["prop_adirondack_white", "worn", 437.0, -922.2, 160.0], ["prop_patio_set_4", "worn", 468.0, -922.6, 0.0],
	["prop_bbq_gas_cart", "worn", 398.0, -878.0, 0.0], ["prop_adirondack_wood", "worn", 414.0, -877.9, 0.0],
	["prop_patio_set_4", "worn", 445.0, -878.4, 0.0], ["prop_adirondack_white", "worn", 461.0, -877.9, 20.0],
	["plant_bougainvillea_mound", "normal", 478.6, -927.0, 0.0], ["plant_bird_of_paradise", "normal", 380.6, -872.0, 0.0],
	# the garden apartments' fronts on the -800 street: planting between the door paths
	["plant_bird_of_paradise", "normal", 392.0, -812.0, 0.0], ["plant_agave_americana_small", "normal", 400.0, -812.0, 0.0],
	["plant_bird_of_paradise", "normal", 428.0, -812.0, 0.0], ["plant_agave_americana_small", "normal", 436.0, -812.0, 0.0],
	["plant_bird_of_paradise", "normal", 464.0, -812.0, 0.0], ["plant_agave_americana_small", "normal", 472.0, -812.0, 0.0],
	# their back lawns
	["prop_clothesline", "worn", 414.0, -838.0, 0.0], ["prop_picnic_table", "worn", 450.0, -838.0, 90.0],
	["prop_bbq_kettle", "worn", 452.8, -838.0, 0.0],
]

## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/fe/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_trash_receptacle", 468.600, -985.400, "bin_open: prop_trash_receptacle stands in the open (1.6 m from a wall, 93.6 m from a fence)"],
	["prop_trash_cart_black", 383.100, -950.000, "bin_open: prop_trash_cart_black stands in the open (1.4 m from a wall, 9.1 m from a fence)"],
	["prop_trash_cart_black", 430.100, -950.000, "bin_open: prop_trash_cart_black stands in the open (1.4 m from a wall, 55.3 m from a fence)"],
	["prop_trash_cart_green", 404.900, -937.900, "bin_open: prop_trash_cart_green stands in the open (1.9 m from a wall, 30.5 m from a fence)"],
	["prop_trash_cart_green", 451.900, -937.900, "bin_open: prop_trash_cart_green stands in the open (1.9 m from a wall, 77.5 m from a fence)"],
	["prop_park_bench", 416.600, -906.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 466.000, -906.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 444.400, -886.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 430.000, -905.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 452.000, -895.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_swing_set", 407.000, -908.500, "no_reason: prop_swing_set stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_slide", 410.500, -903.000, "no_reason: prop_slide stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_swing_set", 407.000, -908.500, "park_empty: a play area with 2 play item(s): a park needs three or more"],
 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/corner", [2.1049232482910156, 1.4999825954437256, 6.7748332023620605, 0.48997978210449217, 2.999965190887451, 0.49008373260498045]],
	["Buildings/corner", [3.944995880126953, 1.4999825954437256, 6.8799638748168945, 0.16, 2.999965190887451, 0.16]],
	["Buildings/corner", [-1.8801307678222656, 1.4999825954437256, 6.7748332023620605, 0.16, 2.999965190887451, 0.49008373260498045]],
	["Buildings/t1", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t1", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t1", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t1", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t1", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t2", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t2", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t2", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/t3", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t3", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t3", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t3", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t3", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t4", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t4", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t4", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/t5", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t5", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t5", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/t6", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t6", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t6", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t6", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t6", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t7", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t7", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t7", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/t8", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t8", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t8", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t8", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t8", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t9", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t9", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t9", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t9", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t9", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t10", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t10", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t10", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/t11", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t11", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t11", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t11", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t11", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t12", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t12", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t12", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/g1", [-11.870152950286865, 1.549957036972046, 5.8649115562438965, 0.29997257232666014, 3.099914073944092, 0.31015304565429686]],
	["Buildings/g1", [-3.600220203399658, 1.6999385803937912, 5.624899864196777, 0.2598400497436523, 2.799950987100601, 0.289943733215332]],
	["Buildings/g2", [-11.870302200317383, 1.5499759912490845, 5.8649115562438965, 0.2999201202392578, 3.099951982498169, 0.31015304565429686]],
	["Buildings/g2", [-3.60017728805542, 1.6999465376138687, 5.624899864196777, 0.25976757049560545, 2.8000108897686005, 0.289943733215332]],
	["Buildings/g3", [-11.870152950286865, 1.549957036972046, 5.8649115562438965, 0.29997257232666014, 3.099914073944092, 0.31015304565429686]],
	["Buildings/g3", [-3.600220203399658, 1.6999385803937912, 5.624899864196777, 0.2598400497436523, 2.799950987100601, 0.289943733215332]],
 ],
}

var PY: Array = []

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array:
	var st := K.building_stats(f)
	if st.has("near") and (st.near as Dictionary).has("bbox"): return (st.near as Dictionary).bbox
	var wd: Array = st.footprint_wd
	return [[-float(wd[0]) * 0.5, 0.0, -float(wd[1]) * 0.5], [float(wd[0]) * 0.5, float(st.get("height", 6.0)), float(wd[1]) * 0.5]]
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]

func _run() -> void:
	var root := Node3D.new(); root.name = "n_fe_b1e"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fe_b1e")
	var yb := func(x: float, z: float) -> float: return S.y("b1", x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yf := S.field(BLK, pe)
	# the shops' lot (its own patch): north stalls u 412 .. 437.6 and 448.4 .. 462 (the entrance aisle between), the
	# aisle, south stalls u 412 .. 462; the garden apartments' stalls on mews 2's south side (u 383 .. 488)
	var ll: Array = []
	for k in 10: ll.append([412.0 + 2.7 * k - 0.05, -985.0, 412.0 + 2.7 * k + 0.05, -979.5, "white"])
	for k in 6: ll.append([448.4 + 2.7 * k - 0.05, -985.0, 448.4 + 2.7 * k + 0.05, -979.5, "white"])
	for k in 19: ll.append([412.0 + 2.7 * k - 0.05, -972.5, 412.0 + 2.7 * k + 0.05, -967.0, "white"])
	var ls: Array = []
	for k in 39: ls.append([383.0 + 2.7 * k - 0.05, -853.0, 383.0 + 2.7 * k + 0.05, -847.5, "white"])
	var regions := [[LOT[0], LOT[1], LOT[2], LOT[3], "asphalt", ll], [383.0, -853.0, 488.0, -847.5, "asphalt", ls]]
	var paints: Array = []
	for r: Array in regions: paints.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append_array([
		[438.0, Z0, 448.0, LOT[1], "asphalt"],                 # the lot's entrance from the -1000 street's apron
		[X0, Z0, X1, -985.0, "plaza"],                         # the shops' forecourt along the -1000 street
		[381.0, M1[0], X1, M1[1], "asphalt"],                  # mews 1 from the u 500 street's apron (v -946 .. -940)
		[381.0, M2[0], X1, M2[1], "asphalt"],                  # mews 2 from the apron at v -860 .. -854
		[381.0, -949.0, 476.0, M1[0], "concrete"],             # mews 1's garage aprons (north row)
		[381.0, M1[1], 476.0, -939.0, "concrete"],             # ... and south row
		[381.0, -862.0, 476.0, M2[0], "concrete"],             # mews 2's garage aprons
		[PLAY[0], PLAY[1], PLAY[2], PLAY[3], "mulch"],         # the play corner's bark
		[X0, -966.0, X1, -964.0, "concrete"],                  # the service walk behind the shops (back doors, bins)
		[377.0, -964.0, 379.0, -847.5, "plaza"],               # the west walk: shops - mews - green - garden apartments
		[379.0, -916.0, 488.0, -914.0, "plaza"],               # the green's cross walk (east-west)
		[440.0, -925.0, 442.0, -876.0, "plaza"],               # ... and north-south
		[379.0, -847.5, 488.0, -845.5, "plaza"],               # the walk behind the apartments' stalls
		[X0, -811.0, X1, -809.0, "plaza"],                     # the front walk on the -800 street
	])
	for cu: float in [396.0, 432.0, 468.0]:
		for a: float in [-7.2, 0.0, 7.2]: paints.append([cu + a - 1.0, -815.0, cu + a + 1.0, -811.0, "plaza"])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	H.paint(g, X0, Z0, X1, Z1, paints, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fe_b1e")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the shops' lot: wheel stops at the stall heads, two lot lights on its west and east edges, the stop sign at
	#      the apron, oil in the busiest stalls (by the doors)
	for k in 9: P.call("prop_wheel_stop_concrete", "worn", 413.35 + 2.7 * k, -984.4, 0.0)
	for k in 5: P.call("prop_wheel_stop_concrete", "worn", 449.75 + 2.7 * k, -984.4, 0.0)
	for k in 18: P.call("prop_wheel_stop_concrete", "worn", 413.35 + 2.7 * k, -967.6, 0.0)
	P.call("prop_lot_light_pole", "worn", 410.4, -976.0, 90.0)
	P.call("prop_lot_light_pole", "worn", 463.6, -976.0, -90.0)
	P.call("prop_sign_stop", "worn", 449.0, -987.2, 180.0)
	for xx: float in [416.05, 456.55]: W.oil(dec, rr, Vector2(xx, -982.25), 0.0, yf, 0.5)
	W.oil(dec, rr, Vector2(429.55, -969.75), 0.0, yf, 0.5)
	W.lane_wear(dec, rr, -976.0, 413.0, 461.0, false, yf)
	# ---- behind the shops: their dumpsters and a grease bin on the service walk, against the back walls
	P.call("prop_dumpster_3yd_green", "worn", 391.0, -967.2, 0.0)
	P.call("prop_dumpster_3yd_blue", "worn", 471.0, -967.2, 0.0)
	P.call("prop_ac_condenser", "worn", 404.0, -967.5, 0.0); P.call("prop_ac_condenser", "worn", 477.6, -967.5, 0.0)
	# ---- the forecourt: a bike rack for the laundromat's and cafe's walkers, a bin against the corner shop's wall,
	#      lamps at the walk's edge
	P.call("prop_bike_rack", "worn", 426.0, -987.6, 0.0)
	P.call("prop_trash_receptacle", "worn", 468.6, -985.4, 0.0)
	for x: float in [380.0, 432.0, 484.0]: P.call("prop_lamp_victorian", "worn", x, -990.2)
	# ---- the mews: a stop sign at each mouth, the mailboxes by mews 1's mouth and mews 2's, trash carts out by the
	#      garages (one pair per townhouse, beside the garage doors), lamps between the houses
	P.call("prop_sign_stop", "worn", 488.6, -938.6, 90.0)
	P.call("prop_sign_stop", "worn", 488.6, -851.6, 90.0)
	for k in 4: P.call("prop_mailbox_post_metal", "worn", 482.0 + 0.6 * k, -950.2, 0.0)
	for k in 4: P.call("prop_mailbox_post_metal", "worn", 482.0 + 0.6 * k, -863.0, 0.0)
	for cu: float in [394.0, 441.0]:
		P.call("prop_trash_cart_black", "worn", cu - 10.9, -950.0, 0.0); P.call("prop_trash_cart_blue", "worn", cu - 10.9, -951.2, 0.0)
		P.call("prop_trash_cart_green", "worn", cu + 10.9, -937.9, 180.0)
	for x: float in [405.75, 452.75]: P.call("prop_lamp_globe", "worn", x, -949.4)
	for x: float in [405.75, 452.75]: P.call("prop_lamp_globe", "worn", x, -938.6)
	for x: float in [405.75, 452.75]: P.call("prop_lamp_globe", "worn", x, -862.6)
	W.lane_wear(dec, rr, -944.0, 382.0, 488.0, false, yf)
	W.lane_wear(dec, rr, -857.0, 382.0, 488.0, false, yf)
	# ---- the apartments' stalls: wheel stops, a lot light, their dumpster at the stall row's west end
	for k in 38: P.call("prop_wheel_stop_concrete", "worn", 384.35 + 2.7 * k, -848.1, 0.0)
	P.call("prop_lot_light_pole", "worn", 440.0, -845.0, 180.0)
	P.call("prop_dumpster_3yd_green", "worn", 381.0, -850.2, 90.0)
	for xx: float in [392.45, 427.55, 462.65]: W.oil(dec, rr, Vector2(xx, -850.25), 0.0, yf, 0.5)
	# ---- the garden apartments: condensers at their ends, lamps on the front walk between them
	P.call("prop_ac_condenser", "worn", 382.6, -823.0, 90.0); P.call("prop_ac_condenser", "worn", 480.6, -823.0, -90.0)
	for x: float in [414.0, 450.0]: P.call("prop_lamp_victorian", "worn", x, -812.0)
	# ---- the green: lamps beside the cross walks
	for p: Vector2 in [Vector2(420.0, -917.2), Vector2(460.0, -917.2), Vector2(443.2, -896.0)]: P.call("prop_lamp_globe", "worn", p.x, p.y)
