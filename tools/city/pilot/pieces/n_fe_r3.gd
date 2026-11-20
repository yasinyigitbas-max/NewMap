extends SceneTree
## Piece n_fe_r3 (fe fill, the ring strip v -391 .. -209): GLORIETTA TERRACES (apartments stepping down the slope on
## TERRACE LANE) and GLORIETTA RING PARK's SKATE SPOT and lookout.
## u 509 (the u 500 street's east walk) .. the ring's inner walk (637.5 .. 632.9), v -391 (the -400 street's south
## walk) .. -209 (the -200 street's north walk). Placed at grid [0, 4.0, 0], yaw 0. Run once.
##
## WHY (planner): the apartment band ends at v -300 and Glorietta Heights (houses on the hill) begins; the land falls
## 2 - 4 m from the u 500 street (6.15 .. 8.15) to the ring (4.15). So: five small apartment buildings face the u 500
## street, each on its own terrace (a level pad at the highest ground under it, the lawn graded up to it); behind them
## TERRACE LANE runs north - south from the -400 street's apron (u 554 .. 560) to the -200 street's (u 554 .. 560),
## with stubs to the u 500 street's two aprons (v -346 .. -340, -260 .. -254): the residents' stalls on its west side,
## the park's on its east side. East of the lane the park: the SKATE SPOT (the teenagers of the apartment band have
## none) on a level concrete pad with a retaining face where the land falls away, a picnic lawn, the ring path and a
## LOOKOUT on the boulevard over the bay.
## LAND: the ground follows it (n_fe_site.g "r3"), eased onto every walk; pads level, faces where they stand proud.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fe_site.gd")

const BLK := "r3"
const X0 := 509.0
const Z0 := -391.0
const Z1 := -209.0
const B := [
	["a1", "apartments/apt_spanish_white", 521.5, -372.0, -90.0],      # fronts on the u 500 street at u 515
	["a2", "apartments/apt_court_white", 521.1, -325.0, -90.0],
	["a3", "apartments/apt_spanish_revival", 521.5, -300.0, -90.0],
	["a4", "apartments/apt_court_white", 521.1, -275.0, -90.0],
	["a5", "apartments/apt_spanish_white", 521.5, -232.0, -90.0],
]
const LANE := [553.0, 561.0]
const ST1 := [-347.0, -339.0]
const ST2 := [-261.0, -253.0]
const SKATE := [572.0, -335.0, 600.0, -305.0]
const PATH := [610.0, 613.0]
const LOOK := [616.0, -300.0, 660.0, -288.0]

const ITEMS := [
	# the skate spot: two quarter pipes facing each other, a funbox in the middle, a grind rail, a bowl section; benches
	# on its edge for the ones waiting their turn; a drinking fountain
	["prop_skate_quarter_pipe", "worn", 575.5, -320.0, 90.0], ["prop_skate_quarter_pipe", "worn", 596.5, -320.0, -90.0],
	["prop_skate_funbox", "worn", 586.0, -320.0, 90.0], ["prop_skate_grind_rail", "worn", 586.0, -310.0, 0.0],
	["prop_skate_bowl_section", "worn", 586.0, -330.0, 0.0],
	["prop_park_bench", "worn", 602.4, -325.0, -90.0], ["prop_park_bench", "worn", 602.4, -315.0, -90.0],
	["prop_drinking_fountain", "worn", 603.0, -306.0, -90.0],
	# the lookout: benches facing the bay
	["prop_park_bench", "worn", 630.0, -297.0, 90.0], ["prop_park_bench", "worn", 630.0, -291.0, 90.0],
	# the picnic lawn (south of the skate spot): tables, grills, a sail over the middle pair
	["prop_shade_sail", "normal", 585.0, -245.0, 0.0, false],
	["prop_picnic_table", "worn", 583.6, -245.0, 90.0], ["prop_picnic_table", "worn", 587.0, -245.0, 90.0],
	["prop_picnic_table", "worn", 575.0, -232.0, 0.0], ["prop_bbq_kettle", "worn", 578.2, -232.0, 0.0],
	["prop_picnic_table", "worn", 597.0, -232.0, 0.0], ["prop_bbq_kettle", "worn", 600.2, -232.0, 0.0],
	# the strip east of the path: benches facing the bay, chairs, sprinklers
	["prop_park_bench", "worn", 622.0, -375.0, 90.0], ["prop_park_bench", "worn", 621.0, -345.0, 90.0],
	["prop_park_bench", "worn", 620.0, -250.0, 90.0], ["prop_park_bench", "worn", 619.6, -222.0, 90.0],
	["prop_adirondack_wood", "worn", 625.0, -330.0, 90.0], ["prop_adirondack_white", "worn", 625.0, -327.6, 70.0],
	["prop_sprinkler_impact", "normal", 585.0, -370.0, 0.0, false], ["prop_sprinkler_impact", "normal", 622.0, -315.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 590.0, -270.0, 0.0, false],
	# the north lawn: benches facing it from the lane's walk
	["prop_park_bench", "worn", 580.0, -360.0, 0.0], ["prop_park_bench", "worn", 595.0, -360.0, 0.0],
	# the apartments' back lawns: tables and grills, a washing line, chairs
	["prop_picnic_table", "worn", 536.0, -372.0, 0.0], ["prop_bbq_kettle", "worn", 539.2, -372.0, 0.0],
	["prop_clothesline", "worn", 538.0, -312.0, 90.0],
	["prop_adirondack_wood", "worn", 534.0, -282.0, -90.0], ["prop_adirondack_white", "worn", 534.0, -279.6, -110.0],
	["prop_picnic_table", "worn", 536.0, -232.0, 0.0], ["prop_bbq_gas_cart", "worn", 536.0, -227.6, 0.0],
	# planting between the door paths on the u 500 street
	["plant_bird_of_paradise", "normal", 512.0, -369.0, 0.0], ["plant_bird_of_paradise", "normal", 512.0, -375.0, 0.0],
	["plant_agave_americana_small", "normal", 512.0, -325.0, 0.0], ["plant_agave_americana_small", "normal", 512.0, -317.0, 0.0],
	["plant_bird_of_paradise", "normal", 512.0, -297.0, 0.0], ["plant_bird_of_paradise", "normal", 512.0, -303.0, 0.0],
	["plant_agave_americana_small", "normal", 512.0, -275.0, 0.0], ["plant_agave_americana_small", "normal", 512.0, -267.0, 0.0],
	["plant_bird_of_paradise", "normal", 512.0, -229.0, 0.0], ["plant_bird_of_paradise", "normal", 512.0, -235.0, 0.0],
]

## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/fe/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_park_bench", 602.400, -325.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 602.400, -315.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 630.000, -297.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 630.000, -291.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 622.000, -375.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 621.000, -345.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 620.000, -250.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 619.600, -222.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 580.000, -360.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 595.000, -360.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_shade_sail", 585.000, -245.000, "sail_over_nothing: a shade sail with no table, seat or play item under it"],
 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/a2", [9.469815254211426, 1.5499759912490845, 5.8649115562438965, 0.3001642608642578, 3.099951982498169, 0.31015304565429686]],
	["Buildings/a4", [9.469815254211426, 1.5499759912490845, 5.8649115562438965, 0.3001642608642578, 3.099951982498169, 0.31015304565429686]],
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
	var root := Node3D.new(); root.name = "n_fe_r3"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fe_r3")
	var yb := func(x: float, z: float) -> float: return S.y(BLK, x, z)
	var xr := func(z: float) -> float: return S.ring_u(S.RING_R3, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var sy := H.pad_height([SKATE[0], SKATE[1], SKATE[2], SKATE[3]], 0.0, yb, 0.0)
	pe.append([SKATE[0], SKATE[1], SKATE[2], SKATE[3], sy])
	var yf := S.field(BLK, pe)
	# the stalls along the lane (lines run along u, stalls 2.7 m along v): west side u 547.5 .. 553 in three runs,
	# east side u 561 .. 566.5 by the skate spot
	var regions: Array = []
	for run: Array in [[547.5, 553.0, -385.0, 14], [547.5, 553.0, -337.0, 28], [547.5, 553.0, -251.0, 14], [561.0, 566.5, -337.0, 13]]:
		var ln: Array = []
		for k in int(run[3]) + 1: ln.append([run[0], float(run[2]) + 2.7 * k - 0.05, run[1], float(run[2]) + 2.7 * k + 0.05, "white"])
		regions.append([run[0], run[2], run[1], float(run[2]) + 2.7 * int(run[3]), "asphalt", ln])
	var paints: Array = []
	for r: Array in regions: paints.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append([SKATE[0], SKATE[1], SKATE[2], SKATE[3], "-"])
	paints.append_array([
		[LANE[0], Z0, LANE[1], Z1, "asphalt"],                 # Terrace Lane, apron to apron
		[X0, ST1[0], LANE[0], ST1[1], "asphalt"], [X0, ST2[0], LANE[0], ST2[1], "asphalt"],   # the stubs to the u 500 street
		[LOOK[0], LOOK[1], LOOK[2], LOOK[3], "plaza"],
		[PATH[0], Z0, PATH[1], Z1, "plaza"],                   # the ring path
		[566.5, -337.0, 568.5, -300.0, "plaza"],               # the walk beside the park stalls to the skate spot
		[566.5, -302.0, PATH[0], -300.0, "plaza"],             # ... and on to the path and the lookout
		[545.5, -385.0, 547.5, -215.0, "plaza"],               # the residents' walk behind their stalls
		[527.8, -363.0, 545.5, -361.0, "plaza"], [527.8, -289.0, 545.5, -287.0, "plaza"],   # walks to the back doors
		[566.0, -352.0, PATH[0], -350.0, "plaza"],             # the north lawn's walk from the lane to the path
	])
	for cv: float in [-372.0, -300.0, -232.0]:
		for a: float in [-6.4, 0.0, 6.4]: paints.append([X0, cv + a - 1.0, 515.0, cv + a + 1.0, "plaza"])
	for cv: float in [-325.0, -275.0]:
		for a: float in [-4.2, 4.2]: paints.append([X0, cv + a - 1.0, 515.0, cv + a + 1.0, "plaza"])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	S.paint_rows(g, X0, Z0, Z1, xr, paints, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	H.level_pad(g, "concrete", SKATE[0], SKATE[1], SKATE[2], SKATE[3], sy, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fe_r3")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the lane: wheel stops at the stall heads, stop signs where it meets the four aprons, lot lights, oil
	for z0: float in [-385.0, -251.0]:
		for k in 14: P.call("prop_wheel_stop_concrete", "worn", 548.1, z0 + 1.35 + 2.7 * k, 90.0)
	for k in 28: P.call("prop_wheel_stop_concrete", "worn", 548.1, -335.65 + 2.7 * k, 90.0)
	for k in 13: P.call("prop_wheel_stop_concrete", "worn", 565.9, -335.65 + 2.7 * k, 90.0)
	P.call("prop_sign_stop", "worn", 562.4, -389.0, 180.0); P.call("prop_sign_stop", "worn", 551.6, -211.0, 0.0)
	P.call("prop_sign_stop", "worn", 511.0, -337.6, -90.0); P.call("prop_sign_stop", "worn", 511.0, -251.6, -90.0)
	P.call("prop_lot_light_pole", "worn", 550.25, -387.5, 0.0); P.call("prop_lot_light_pole", "worn", 544.0, -320.0, 90.0)
	P.call("prop_lot_light_pole", "worn", 544.0, -240.0, 90.0); P.call("prop_lot_light_pole", "worn", 570.0, -320.0, 90.0)
	for zz: float in [-378.25, -321.55, -294.55, -240.55]: W.oil(dec, rr, Vector2(550.25, zz), 90.0, yf, 0.5)
	W.oil(dec, rr, Vector2(563.75, -313.45), 90.0, yf, 0.5)
	W.lane_wear(dec, rr, 557.0, -389.0, -211.0, true, yf)
	# ---- the apartments: condensers at their back corners, mailboxes at the stubs' mouths, their dumpsters by the
	#      residents' walk at the stubs
	for cv: float in [-372.0, -300.0, -232.0]: P.call("prop_ac_condenser", "worn", 529.4, cv - 7.6, -90.0)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", 511.0, -349.4 - 0.6 * k, -90.0)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", 511.0, -263.4 - 0.6 * k, -90.0)
	P.call("prop_dumpster_3yd_green", "worn", 543.0, -349.0, 90.0); P.call("prop_dumpster_3yd_blue", "worn", 543.0, -251.0, 90.0)
	# ---- lamps: the ring path's west side, the lookout, the walks
	for z: float in [-380.0, -345.0, -270.0, -235.0]: P.call("prop_lamp_victorian", "worn", 608.8, z)
	P.call("prop_lamp_victorian", "worn", 618.0, -301.2)
	P.call("prop_lamp_globe", "worn", 570.0, -303.2); P.call("prop_lamp_globe", "worn", 544.2, -300.0)
