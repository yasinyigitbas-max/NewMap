extends SceneTree
## Piece n_fe_r5 (fe fill, the ring strip v -591 .. -409): GLORIETTA REC CENTER with its TENNIS COURTS, two garden
## apartment buildings, and GLORIETTA RING PARK's middle (the ring path, a lookout, a picnic grove).
## u 509 (the u 500 street's east walk) .. the ring's inner walk (640.2 .. 637.8), v -591 (the -600 street's south
## walk) .. -409 (the -400 street's north walk). Placed at grid [0, 4.0, 0], yaw 0. Run once.
##
## WHY (planner): halfway down the ring strip, between the apartment band (west across the u 500 street) and the bay,
## the neighbourhood's REC CENTER (civ_rec_center: the desk for courts, classes and kit; door on the u 500 street,
## where the buses and the walkers from the apartments pass) and two TENNIS COURTS beside it. Cars come in only at the
## u 500 street's aprons: the north one (v -546 .. -540) leads to the rec center's stalls, the south one (v -460 ..
## -454) to the stalls of two GARDEN APARTMENTS on the corner of the -400 street. East of the courts the park: the
## ring path, a LOOKOUT on the boulevard's edge, a PICNIC GROVE, benches for the tennis spectators.
## LAND: 6.1 at the u 500 street falling to 4.1 at the ring; the ground follows it (n_fe_site.g "r5"); buildings and
## the courts on level pads (the courts at their highest ground, with a face where the land falls away), the field
## graded up to them; the rec center's 0.3 m door sill gets closed steps.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fe_site.gd")

const BLK := "r5"
const X0 := 509.0
const Z0 := -591.0
const Z1 := -409.0
const B := [
	["rec", "civic/civ_rec_center", 527.95, -510.0, -90.0],            # front (door) on the u 500 street at u 517, v -510
	["ap1", "apartments/apt_spanish_revival", 521.5, -432.0, -90.0],   # front on the u 500 street at u 515
	["ap2", "apartments/apt_garden_cream", 560.0, -421.1, 0.0],        # front on the -400 street at v -415
]
const DE := [-547.0, -539.0]          # drive E from the north apron (v)
const DF := [-461.0, -453.0]          # drive F from the south apron (v)
const COURT := [547.0, -528.0, 587.0, -490.0]   # the courts' pad (asphalt), fenced at 1 m round it
const PATH := [616.0, 619.0]
const LOOK := [622.0, -506.0, 660.0, -494.0]    # the lookout plaza (clipped by the ring edge)

const ITEMS := [
	# the rec center's forecourt: a bike rack, a bench either side of the door, planters, a paper box on the walk's edge
	["prop_bike_rack", "worn", 512.0, -526.0, 90.0], ["prop_park_bench", "worn", 513.4, -517.0, -90.0],
	["prop_park_bench", "worn", 513.4, -503.0, -90.0], ["plant_potted_leafy", "normal", 515.6, -514.0, 0.0],
	["plant_potted_leafy", "normal", 515.6, -506.0, 0.0], ["prop_newspaper_box_blue", "worn", 510.0, -495.0, -90.0],
	# the picnic pavilion between the rec center and the apartments' drive: tables under a sail, grills beside
	["prop_shade_sail", "normal", 552.0, -480.0, 0.0, false],
	["prop_picnic_table", "worn", 550.6, -480.0, 90.0], ["prop_picnic_table", "worn", 554.0, -480.0, 90.0],
	["prop_bbq_kettle", "worn", 547.0, -476.0, 0.0], ["prop_bbq_gas_cart", "worn", 558.0, -476.0, 0.0],
	# spectators' benches on the courts' east side, facing them over the fence
	["prop_park_bench", "worn", 591.0, -518.0, -90.0], ["prop_park_bench", "worn", 591.0, -510.0, -90.0],
	# the lookout: benches on its east edge facing the bay, a drinking fountain where the path meets it
	["prop_park_bench", "worn", 636.0, -503.0, 90.0], ["prop_park_bench", "worn", 636.0, -497.0, 90.0],
	["prop_drinking_fountain", "worn", 620.4, -507.0, 90.0],
	# the picnic grove east of the path (tables in the lawn, a grill each) and chairs on the strip facing the bay
	["prop_picnic_table", "worn", 627.0, -465.0, 0.0], ["prop_bbq_kettle", "worn", 630.0, -465.0, 0.0],
	["prop_picnic_table", "worn", 627.0, -450.0, 0.0], ["prop_bbq_kettle", "worn", 630.0, -450.0, 0.0],
	["prop_picnic_table", "worn", 605.0, -440.0, 90.0],
	["prop_adirondack_wood", "worn", 630.0, -560.0, 90.0], ["prop_adirondack_white", "worn", 630.0, -557.6, 70.0],
	["prop_park_bench", "worn", 622.0, -575.0, 90.0], ["prop_park_bench", "worn", 622.0, -425.0, 90.0],
	["prop_sprinkler_impact", "normal", 600.0, -570.0, 0.0, false], ["prop_sprinkler_impact", "normal", 628.0, -530.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 600.0, -470.0, 0.0, false],
	# the apartments: a grill and chairs on their back lawns, planting between the door paths
	["prop_picnic_table", "worn", 536.0, -432.0, 0.0], ["prop_bbq_kettle", "worn", 539.2, -432.0, 0.0],
	["prop_adirondack_wood", "worn", 562.0, -430.0, 180.0], ["prop_adirondack_white", "worn", 564.4, -430.6, 200.0],
	["plant_bird_of_paradise", "normal", 512.0, -429.0, 0.0], ["plant_bird_of_paradise", "normal", 512.0, -435.0, 0.0],
	["plant_bird_of_paradise", "normal", 556.4, -412.0, 0.0], ["plant_agave_americana_small", "normal", 563.6, -412.0, 0.0],
	# the north strip along the -600 street: a lawn with benches facing it
	["prop_park_bench", "worn", 560.0, -575.0, 180.0], ["prop_park_bench", "worn", 585.0, -575.0, 180.0],
]

## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/fe/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_park_bench", 591.000, -518.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 591.000, -510.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 636.000, -503.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 636.000, -497.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 622.000, -575.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 622.000, -425.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 560.000, -575.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 585.000, -575.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 605.000, -440.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_bbq_kettle", 547.000, -476.000, "no_reason: prop_bbq_kettle stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_bbq_gas_cart", 558.000, -476.000, "no_reason: prop_bbq_gas_cart stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_shade_sail", 552.000, -480.000, "sail_over_nothing: a shade sail with no table, seat or play item under it"],
 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/ap2", [-11.870302200317383, 1.5499759912490845, 5.8649115562438965, 0.2999201202392578, 3.099951982498169, 0.31015304565429686]],
	["Buildings/ap2", [-3.60017728805542, 1.6999465376138687, 5.624899864196777, 0.25976757049560545, 2.8000108897686005, 0.289943733215332]],
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
	var root := Node3D.new(); root.name = "n_fe_r5"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fe_r5")
	var yb := func(x: float, z: float) -> float: return S.y(BLK, x, z)
	var xr := func(z: float) -> float: return S.ring_u(S.RING_R5, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	# the courts' pad: level at the highest ground under it (fence line included)
	var cy := H.pad_height([COURT[0] - 1.0, COURT[1] - 1.0, COURT[2] + 1.0, COURT[3] + 1.0], 0.0, yb, 0.0)
	pe.append([COURT[0] - 1.2, COURT[1] - 1.2, COURT[2] + 1.2, COURT[3] + 1.2, cy])
	var yf := S.field(BLK, pe)
	# stall rows (own patches): drive E north u 530 .. 597.8 (25), south u 540 .. 597.8 (21); drive F south u 530 .. 589.4 (22)
	var le: Array = []; var lf: Array = []
	for k in 26: le.append([530.0 + 2.7 * k - 0.05, -552.5, 530.0 + 2.7 * k + 0.05, DE[0], "white"])
	for k in 22: le.append([540.0 + 2.7 * k - 0.05, DE[1], 540.0 + 2.7 * k + 0.05, -533.5, "white"])
	for k in 23: lf.append([530.0 + 2.7 * k - 0.05, DF[1], 530.0 + 2.7 * k + 0.05, -447.5, "white"])
	# the courts' lines (doubles 10.97 x 23.77, singles, service lines, centre line), two courts centred u 556.5 / 576.5
	var cl: Array = []
	for cu: float in [556.5, 576.5]:
		for du: float in [-5.485, -4.115, 4.115, 5.485]: cl.append([cu + du - 0.05, -520.885, cu + du + 0.05, -497.115, "white"])
		for v: float in [-520.885, -497.115]: cl.append([cu - 5.485, v - 0.05, cu + 5.485, v + 0.05, "white"])
		for v: float in [-515.4, -502.6]: cl.append([cu - 4.115, v - 0.05, cu + 4.115, v + 0.05, "white"])
		cl.append([cu - 0.05, -515.4, cu + 0.05, -502.6, "white"])
	var regions := [[530.0, -552.5, 597.8, DE[0], "asphalt", le.slice(0, 26)], [540.0, DE[1], 597.8, -533.5, "asphalt", le.slice(26)],
		[530.0, DF[1], 589.4, -447.5, "asphalt", lf]]
	var paints: Array = []
	for r: Array in regions: paints.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append([COURT[0] - 1.2, COURT[1] - 1.2, COURT[2] + 1.2, COURT[3] + 1.2, "-"])
	paints.append_array([
		[X0, DE[0], 600.0, DE[1], "asphalt"], [X0, DF[0], 592.0, DF[1], "asphalt"],
		[X0, -531.0, 516.7, -489.0, "plaza"],                  # the rec center's forecourt on the u 500 street
		[X0, -533.5, PATH[0], -531.5, "plaza"],                # the walk south of the stalls: forecourt - courts - path
		[LOOK[0], LOOK[1], LOOK[2], LOOK[3], "plaza"],
		[PATH[0], Z0, PATH[1], Z1, "plaza"],                   # the ring path
		[589.0, -501.0, PATH[0], -499.0, "plaza"],             # the walk from the courts' east side to the path
		[X0, -415.0, 548.0, -413.0, "plaza"],                  # the apartments' corner walk
		[X0, -447.5, 600.0, -445.5, "plaza"],                  # the walk behind the apartments' stalls, to the path
		[600.0, -447.5, 602.0, -413.0, "plaza"],
	])
	for a: float in [-6.4, 0.0, 6.4]: paints.append([X0, -432.0 + a - 1.0, 515.0, -432.0 + a + 1.0, "plaza"])
	for a: float in [-7.2, 0.0, 7.2]: paints.append([560.0 + a - 1.0, -415.0, 560.0 + a + 1.0, -409.0, "plaza"])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	S.paint_rows(g, X0, Z0, Z1, xr, paints, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	# the courts: a level asphalt pad with its lines (own cells), a concrete margin to the fence, faces to the field
	H.paint(g, COURT[0], COURT[1], COURT[2], COURT[3], cl, "asphalt", func(_x: float, _z: float) -> float: return cy)
	for r: Array in [[COURT[0] - 1.2, COURT[1] - 1.2, COURT[2] + 1.2, COURT[1]], [COURT[0] - 1.2, COURT[3], COURT[2] + 1.2, COURT[3] + 1.2],
			[COURT[0] - 1.2, COURT[1], COURT[0], COURT[3]], [COURT[2], COURT[1], COURT[2] + 1.2, COURT[3]]]:
		H.paint(g, r[0], r[1], r[2], r[3], [], "concrete", func(_x: float, _z: float) -> float: return cy)
	var cyf := func(_x: float, _z: float) -> float: return cy
	var x0 := COURT[0] - 1.2; var x1 := COURT[2] + 1.2; var z0 := COURT[1] - 1.2; var z1 := COURT[3] + 1.2
	for e: Array in [[x0, z0, x1, z0], [x0, z1, x1, z1], [x0, z0, x0, z1], [x1, z0, x1, z1]]:
		H.step_face(g, Vector2(e[0], e[1]), Vector2(e[2], e[3]), cyf, yf)
	# the rec center's door sill (0.3 m over its pad): closed steps down to the forecourt
	H.steps_x2(g, -510.0, 2.4, 516.3, 517.0, float(PY[0]), float(PY[0]) + 0.3, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf, cy)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fe_r5")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, cy: float) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the stalls: wheel stops, lot lights at the rows' ends, stop signs at the two mouths, oil in a few stalls
	for k in 25: P.call("prop_wheel_stop_concrete", "worn", 531.35 + 2.7 * k, -551.9, 0.0)
	for k in 21: P.call("prop_wheel_stop_concrete", "worn", 541.35 + 2.7 * k, -534.1, 0.0)
	for k in 22: P.call("prop_wheel_stop_concrete", "worn", 531.35 + 2.7 * k, -448.1, 0.0)
	P.call("prop_lot_light_pole", "worn", 537.0, -536.0, 90.0)
	P.call("prop_lot_light_pole", "worn", 599.4, -550.0, -90.0)
	P.call("prop_sign_stop", "worn", 511.2, -537.4, -90.0); P.call("prop_sign_stop", "worn", 511.2, -451.4, -90.0)
	for xx: float in [542.15, 569.15]: W.oil(dec, rr, Vector2(xx, -549.75), 0.0, yf, 0.5)
	W.oil(dec, rr, Vector2(555.65, -536.25), 0.0, yf, 0.5); W.oil(dec, rr, Vector2(544.85, -450.25), 0.0, yf, 0.5)
	W.lane_wear(dec, rr, -543.0, 511.0, 598.0, false, yf)
	W.lane_wear(dec, rr, -457.0, 511.0, 590.0, false, yf)
	# ---- the rec center: its dumpster and condensers on the back (east) side, by the back door
	P.call("prop_dumpster_3yd_green", "worn", 539.0, -525.0, 0.0)
	P.call("prop_ac_condenser", "worn", 537.6, -505.0, -90.0); P.call("prop_ac_condenser", "worn", 537.6, -501.5, -90.0)
	# ---- the courts: the two nets, the chain-link fence round them (a post at every joint; the gate gap on the north
	#      side, by the walk from the stalls)
	props.add("prop_tennis_net", "worn", Vector3(556.5, cy, -509.0), 0.0)
	props.add("prop_tennis_net", "worn", Vector3(576.5, cy, -509.0), 0.0)
	var cyf := func(_x: float, _z: float) -> float: return cy + 0.02
	var a := Vector2(546.2, -528.8); var b := Vector2(587.8, -528.8); var c := Vector2(587.8, -489.2); var d := Vector2(546.2, -489.2)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", a, b, cyf, 2.0, "worn", [[3.0, 1.5]])
	H.fence(props, "fence_chainlink", "fence_chainlink_post", b, c, cyf, 2.0, "worn")
	H.fence(props, "fence_chainlink", "fence_chainlink_post", c, d, cyf, 2.0, "worn")
	H.fence(props, "fence_chainlink", "fence_chainlink_post", d, a, cyf, 2.0, "worn")
	# ---- the apartments: condensers, mailboxes by drive F's mouth, their dumpster at the stall row's east end
	P.call("prop_ac_condenser", "worn", 529.4, -439.0, -90.0); P.call("prop_ac_condenser", "worn", 573.0, -423.0, -90.0)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", 511.0, -442.6 - 0.6 * k, -90.0)
	P.call("prop_dumpster_3yd_blue", "worn", 593.0, -451.0, 90.0)
	# ---- lamps: the ring path's west side, the walks
	for z: float in [-580.0, -545.0, -470.0, -435.0]: P.call("prop_lamp_victorian", "worn", 614.8, z)
	P.call("prop_lamp_victorian", "worn", 625.0, -507.2); P.call("prop_lamp_globe", "worn", 520.0, -530.2)
	P.call("prop_lamp_globe", "worn", 603.2, -430.0)
