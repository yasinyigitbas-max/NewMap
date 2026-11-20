extends SceneTree
## Piece n_fe_r7 (fe fill, the ring strip v -791 .. -609): GLORIETTA MEWS (townhouses on two mews) and GLORIETTA RING
## PARK's PLAYGROUND.
## u 509 (the u 500 street's east walk) .. the ring's inner walk (642.9 .. 640.5), v -791 (the -800 street's south
## walk) .. -609 (the -600 street's north walk). Placed at grid [0, 4.0, 0], yaw 0. Run once.
##
## WHY (planner): the apartment band's east end (to u 560; across the u 500 street the apartment blocks n_apt_b1_*),
## then the ring boulevard and the golf course / Glorietta Bay beyond. Families from the apartment band have no play
## space of their own: the park's main PLAYGROUND is here, on the ring path, with its own small car park off the
## -800 street's apron (u 554 .. 560). On the u 500 street's side TOWNHOUSES on two mews lanes that come in at the
## street's aprons (v -746 .. -740 and -660 .. -654): garages on the mews, gardens on the green between them, so no
## new driveway touches a street. The ring path runs north - south (from n_fe_b2 to n_fe_r5); benches on the strip
## between it and the boulevard look east over the bay.
## LAND: 6.1 at the u 500 street falling to 4.1 at the ring (1.7 %); the ground follows it (n_fe_site.g "r7"); each
## townhouse on its own level pad (the rows step down eastward), the field graded up to them.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fe_site.gd")

const BLK := "r7"
const X0 := 509.0
const Z0 := -791.0
const Z1 := -609.0
const B := [
	["t1", "apartments/apt_townhouse_cays", 522.0, -755.4, 0.0],       # mews 1 north row: garages at v -749
	["t2", "apartments/apt_townhouse_modern", 545.5, -755.4, 0.0],
	["t3", "apartments/apt_townhouse_cays", 569.0, -755.4, 0.0],
	["t4", "apartments/apt_townhouse_modern", 522.0, -730.6, 180.0],   # mews 1 south row: garages at v -737
	["t5", "apartments/apt_townhouse_cays", 545.5, -730.6, 180.0],
	["t6", "apartments/apt_townhouse_modern", 569.0, -730.6, 180.0],
	["t7", "apartments/apt_townhouse_modern", 522.0, -669.4, 0.0],     # mews 2 north row: garages at v -663
	["t8", "apartments/apt_townhouse_cays", 545.5, -669.4, 0.0],
	["t9", "apartments/apt_townhouse_modern", 569.0, -669.4, 0.0],
	["t10", "apartments/apt_townhouse_cays", 522.0, -644.6, 180.0],    # mews 2 south row: garages at v -651
	["t11", "apartments/apt_townhouse_modern", 545.5, -644.6, 180.0],
	["t12", "apartments/apt_townhouse_cays", 569.0, -644.6, 180.0],
]
const M1 := [-747.0, -739.0]
const M2 := [-661.0, -653.0]
const LOT := [563.0, -785.5, 600.0, -767.5]   # the park's car park (stalls both sides of an aisle)
const PATH := [618.0, 621.0]
const PLAY := [588.0, -722.0, 612.0, -690.0]  # the playground's bark

const ITEMS := [
	# the playground: a big play structure, two swing sets, slides, a shade sail over the toddlers' corner; benches
	# for the parents round its edge facing in; a drinking fountain and picnic tables by the path
	["prop_play_structure", "worn", 600.0, -712.0, 0.0], ["prop_play_structure", "worn", 594.0, -698.0, 90.0],
	["prop_swing_set", "worn", 607.0, -716.5, 90.0], ["prop_swing_set", "worn", 607.0, -706.0, 90.0],
	["prop_slide", "worn", 592.0, -716.0, 0.0], ["prop_slide", "worn", 604.0, -695.0, 90.0],
	["prop_park_bench", "worn", 586.4, -716.0, 90.0], ["prop_park_bench", "worn", 586.4, -700.0, 90.0],
	["prop_park_bench", "worn", 600.0, -723.6, 0.0], ["prop_park_bench", "worn", 614.0, -705.0, -90.0],
	["prop_drinking_fountain", "worn", 616.6, -722.0, 90.0],
	["prop_picnic_table", "worn", 630.0, -715.0, 0.0], ["prop_picnic_table", "worn", 630.0, -700.0, 0.0],
	["prop_bbq_kettle", "worn", 633.0, -715.0, 0.0],
	# the strip between the path and the boulevard: benches facing the bay, chairs on the lawn, sprinklers
	["prop_park_bench", "worn", 634.0, -775.0, 90.0], ["prop_park_bench", "worn", 633.0, -745.0, 90.0],
	["prop_park_bench", "worn", 633.0, -660.0, 90.0], ["prop_park_bench", "worn", 632.4, -630.0, 90.0],
	["prop_adirondack_wood", "worn", 630.0, -682.0, 90.0], ["prop_adirondack_white", "worn", 630.0, -679.6, 70.0],
	["prop_sprinkler_impact", "normal", 630.0, -760.0, 0.0, false], ["prop_sprinkler_impact", "normal", 600.0, -650.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 600.0, -750.0, 0.0, false],
	# the green between the mews: picnic tables and a grill for the townhouses, benches facing the lawn
	["prop_picnic_table", "worn", 540.0, -698.0, 0.0], ["prop_bbq_kettle", "worn", 543.2, -698.0, 0.0],
	["prop_picnic_table", "worn", 565.0, -712.0, 90.0],
	["prop_park_bench", "worn", 548.0, -713.2, 0.0], ["prop_park_bench", "worn", 548.0, -683.8, 180.0],
	# the townhouses' back gardens: chairs and grills by the back doors
	["prop_adirondack_wood", "worn", 517.0, -721.0, 180.0], ["prop_patio_set_4", "worn", 550.0, -721.4, 0.0],
	["prop_bbq_gas_cart", "worn", 572.0, -720.8, 0.0],
	["prop_adirondack_white", "worn", 517.0, -679.0, 0.0], ["prop_bbq_kettle", "worn", 541.0, -679.4, 0.0],
	["prop_patio_set_4", "worn", 574.0, -679.6, 0.0],
	# the rows' backs on the cross streets: low planting
	["plant_bougainvillea_mound", "normal", 581.6, -765.0, 0.0], ["plant_bird_of_paradise", "normal", 545.5, -766.0, 0.0],
	["plant_bird_of_paradise", "normal", 545.5, -633.6, 0.0], ["plant_agave_americana", "normal", 581.6, -632.0, 0.0],
]

## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/fe/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_trash_cart_black", 580.600, -750.000, "bin_open: prop_trash_cart_black stands in the open (2.0 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", 580.600, -664.000, "bin_open: prop_trash_cart_black stands in the open (2.6 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", 580.600, -751.200, "bin_open: prop_trash_cart_blue stands in the open (2.0 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_green", 580.600, -735.800, "bin_open: prop_trash_cart_green stands in the open (2.6 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_green", 580.600, -649.800, "bin_open: prop_trash_cart_green stands in the open (2.0 m from a wall, 99.0 m from a fence)"],
	["prop_play_structure", 600.000, -712.000, "no_reason: prop_play_structure stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_play_structure", 594.000, -698.000, "no_reason: prop_play_structure stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_swing_set", 607.000, -716.500, "no_reason: prop_swing_set stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_swing_set", 607.000, -706.000, "no_reason: prop_swing_set stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_slide", 592.000, -716.000, "no_reason: prop_slide stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_slide", 604.000, -695.000, "no_reason: prop_slide stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 586.400, -716.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 586.400, -700.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 600.000, -723.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 614.000, -705.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 634.000, -775.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 633.000, -745.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 633.000, -660.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 632.400, -630.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 548.000, -713.200, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 548.000, -683.800, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 630.000, -700.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 565.000, -712.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_play_structure", 594.000, -698.000, "park_empty: a play area with 2 play item(s): a park needs three or more"],
 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
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
	["Buildings/t5", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t5", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t5", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t5", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t5", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t6", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t6", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t6", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/t7", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t7", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t7", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/t8", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t8", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t8", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t8", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t8", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t9", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t9", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t9", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/t10", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t10", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t10", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t10", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t10", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t11", [-5.497543573379517, 1.5399726629257202, 4.9609694480896, 0.9450345420837403, 3.0799453258514404, 0.16]],
	["Buildings/t11", [-0.21016597747802734, 1.5399726629257202, 4.1608967781066895, 0.35977272033691404, 3.0799453258514404, 0.16]],
	["Buildings/t11", [6.502248764038086, 1.5399726629257202, 4.9609694480896, 0.9450350189208985, 3.0799453258514404, 0.16]],
	["Buildings/t12", [-0.7502017021179199, 1.299967885017395, -5.3601157665252686, 0.9398022079467774, 2.59993577003479, 0.7600150489807129]],
	["Buildings/t12", [-0.010235309600830078, 1.5399956703186035, 4.429953098297119, 0.35998538970947264, 3.079991340637207, 0.2600822830200195]],
	["Buildings/t12", [2.7748336791992188, 1.5399956703186035, 4.359890460968018, 0.16, 3.079991340637207, 0.16]],
	["Buildings/t12", [-3.6001501083374023, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
	["Buildings/t12", [9.1998929977417, 1.4999909400939941, 4.959969997406006, 0.23999122619628907, 2.9999818801879883, 0.16]],
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
	var root := Node3D.new(); root.name = "n_fe_r7"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fe_r7")
	var yb := func(x: float, z: float) -> float: return S.y(BLK, x, z)
	var xr := func(z: float) -> float: return S.ring_u(S.RING_R7, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yf := S.field(BLK, pe)
	# the park's car park as its own patch: stalls on both sides of the aisle (v -780 .. -773), u 563 .. 600
	var ll: Array = []
	for k in 14:
		ll.append([563.0 + 2.7 * k - 0.05, -785.5, 563.0 + 2.7 * k + 0.05, -780.0, "white"])
		ll.append([563.0 + 2.7 * k - 0.05, -773.0, 563.0 + 2.7 * k + 0.05, -767.5, "white"])
	var regions := [[LOT[0], LOT[1], LOT[2], LOT[3], "asphalt", ll]]
	var paints: Array = []
	for r: Array in regions: paints.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append_array([
		[553.0, Z0, 561.0, -767.5, "asphalt"],                 # the car park's entrance from the -800 street's apron
		[PLAY[0], PLAY[1], PLAY[2], PLAY[3], "mulch"],
		[511.0, M1[0], 582.0, M1[1], "asphalt"], [X0, M1[0] - 0.5, 511.0, M1[1] + 0.5, "concrete"],   # mews 1 (+ its mouth)
		[511.0, M2[0], 582.0, M2[1], "asphalt"], [X0, M2[0] - 0.5, 511.0, M2[1] + 0.5, "concrete"],   # mews 2
		[511.0, -749.0, 580.0, M1[0], "concrete"], [511.0, M1[1], 580.0, -737.0, "concrete"],         # garage aprons
		[511.0, -663.0, 580.0, M2[0], "concrete"], [511.0, M2[1], 580.0, -651.0, "concrete"],
		[PATH[0], Z0, PATH[1], Z1, "plaza"],                   # the ring path
		[600.0, -767.5, 602.0, -722.0, "plaza"],               # from the car park to the playground
		[511.0, -688.0, PATH[0], -686.0, "plaza"],             # the walk: mews mouths - green - playground - ring path
		[533.0, -723.0, 535.0, -677.0, "plaza"], [556.0, -723.0, 558.0, -677.0, "plaza"],   # garden walks
	])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	S.paint_rows(g, X0, Z0, Z1, xr, paints, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fe_r7")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the park's car park: wheel stops, a light, the stop sign at the apron, oil in two stalls
	for k in 13:
		P.call("prop_wheel_stop_concrete", "worn", 564.35 + 2.7 * k, -784.9, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", 564.35 + 2.7 * k, -768.1, 0.0)
	P.call("prop_lot_light_pole", "worn", 601.4, -776.5, -90.0)
	P.call("prop_sign_stop", "worn", 562.0, -788.6, 180.0)
	W.oil(dec, rr, Vector2(569.75, -782.75), 0.0, yf, 0.5); W.oil(dec, rr, Vector2(588.65, -770.25), 0.0, yf, 0.5)
	W.lane_wear(dec, rr, -776.5, 554.0, 600.0, false, yf)
	# ---- the mews: stop signs at the mouths, mailboxes beside them, trash carts by the garages, lamps between houses
	P.call("prop_sign_stop", "worn", 511.0, -737.6, -90.0); P.call("prop_sign_stop", "worn", 511.0, -651.6, -90.0)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", 510.2, -750.0 - 0.6 * k, -90.0)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", 510.2, -664.0 - 0.6 * k, -90.0)
	for x: float in [533.75, 557.25]:
		P.call("prop_lamp_globe", "worn", x, -749.4); P.call("prop_lamp_globe", "worn", x, -736.6)
		P.call("prop_lamp_globe", "worn", x, -663.4); P.call("prop_lamp_globe", "worn", x, -650.6)
	P.call("prop_trash_cart_black", "worn", 580.6, -750.0, 0.0); P.call("prop_trash_cart_blue", "worn", 580.6, -751.2, 0.0)
	P.call("prop_trash_cart_green", "worn", 580.6, -735.8, 180.0)
	P.call("prop_trash_cart_black", "worn", 580.6, -664.0, 0.0); P.call("prop_trash_cart_green", "worn", 580.6, -649.8, 180.0)
	W.lane_wear(dec, rr, -743.0, 512.0, 580.0, false, yf)
	W.lane_wear(dec, rr, -657.0, 512.0, 580.0, false, yf)
	# ---- the ring path: lamps along its west side; lamps on the playground walks
	for z: float in [-780.0, -745.0, -690.0, -655.0, -620.0]: P.call("prop_lamp_victorian", "worn", 616.8, z)
	P.call("prop_lamp_globe", "worn", 584.0, -689.2); P.call("prop_lamp_globe", "worn", 603.4, -740.0)
