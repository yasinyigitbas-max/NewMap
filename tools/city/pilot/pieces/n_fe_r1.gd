extends SceneTree
## Piece n_fe_r1 (fe fill, the ring strip's south end v -191 .. -9): GLORIETTA POINT (a bakery and a surf shop facing
## the waterfront, apartments on the hill) and GLORIETTA RING PARK's south end (the BANDSTAND lawn, a lookout).
## u 509 (the u 500 street's east walk) .. the ring's inner walk (632.5, bending at v -121 to 613.5 at the v 0
## junction), v -191 (the -200 street's south walk) .. -9 (the v 0 street's north walk). Grid [0, 4.0, 0], yaw 0.
##
## WHY (planner): Glorietta Heights' foot, where the hill (8.15 at the u 500 street's north end) comes down to the v 0
## street and the waterfront beyond it (n_wf_*). On the v 0 street, facing the people walking to the bay: a BAKERY and
## a SURF SHOP (boards, wetsuits, wax), their customers' stalls off the v 0 street's apron (u 554 .. 560), their
## deliveries and bins on a service lane from the u 500 street's south apron (v -60 .. -54). On the hill three small
## APARTMENT buildings face the u 500 street on their own terraces, their stalls on a stub from the street's north
## apron (v -146 .. -140). The park's south end: the ring path (it ends on the v 0 street's walk), the BANDSTAND on a
## lawn for summer concerts, picnic tables, and a LOOKOUT where the boulevard bends.
## LAND: 8 m in the north-west falling to 4.1 at the ring and the v 0 street; the ground follows it (n_fe_site.g
## "r1"), eased onto every walk; buildings and the bandstand on level pads, the lawn graded up to them.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fe_site.gd")

const BLK := "r1"
const X0 := 509.0
const Z0 := -191.0
const Z1 := -9.0
const B := [
	["bakery", "commercial/com_bakery", 528.0, -23.17, 0.0],           # front on the v 0 street's forecourt at v -15
	["surf", "commercial/com_surf_shop", 540.0, -22.95, 0.0],
	["a1", "apartments/apt_spanish_revival", 521.5, -172.0, -90.0],    # fronts on the u 500 street at u 515
	["a2", "apartments/apt_court_white", 521.1, -118.0, -90.0],
	["a3", "apartments/apt_spanish_white", 521.5, -90.0, -90.0],
]
const STUB := [-147.0, -139.0]        # the apartments' stub from the north apron (v)
const SVC := [-61.0, -53.0]           # the shops' service lane from the south apron (v)
const LEG := [553.0, 561.0]           # the shops' car park entrance from the v 0 street's apron (u)
const LOT := [562.0, -38.5, 596.0, -20.5]
const PATH := [600.0, 603.0]
const STAND := [569.5, -105.5, 580.5, -94.5]   # the bandstand's pad (footprint 9.4 x 10.3 inside)
const LOOK := [606.0, -128.0, 660.0, -114.0]

const ITEMS := [
	# the shops' forecourt on the v 0 street: the bakery's tables beside its door (door at u 531.3), a bench, a bike
	# rack for the beach cruisers by the surf shop, planters, a paper box
	["prop_patio_set_4", "worn", 524.6, -12.6, 0.0], ["prop_patio_set_4", "worn", 534.4, -12.6, 0.0],
	["prop_bike_rack", "worn", 546.6, -12.4, 0.0], ["plant_potted_leafy", "normal", 541.0, -14.4, 0.0],
	["prop_park_bench", "worn", 516.0, -10.6, 180.0], ["prop_newspaper_box_red", "worn", 511.0, -11.0, 0.0],
	["plant_potted_succulent", "normal", 545.6, -14.4, 0.0],
	# the bandstand lawn: benches in two arcs facing the stand, picnic tables at the lawn's edge, a drinking fountain
	["prop_park_bench", "worn", 565.0, -112.0, 45.0], ["prop_park_bench", "worn", 575.0, -114.5, 0.0],
	["prop_park_bench", "worn", 585.0, -112.0, -45.0], ["prop_park_bench", "worn", 566.0, -88.0, 135.0],
	["prop_park_bench", "worn", 575.0, -85.5, 180.0], ["prop_park_bench", "worn", 584.0, -88.0, -135.0],
	["prop_picnic_table", "worn", 565.0, -70.0, 0.0], ["prop_picnic_table", "worn", 588.0, -70.0, 0.0],
	["prop_drinking_fountain", "worn", 598.6, -103.0, -90.0],
	# the lookout: benches facing the bay where the boulevard bends
	["prop_park_bench", "worn", 624.0, -124.0, 90.0], ["prop_park_bench", "worn", 624.0, -118.0, 90.0],
	# the strip east of the path: benches facing the bay, chairs, sprinklers
	["prop_park_bench", "worn", 615.0, -175.0, 90.0], ["prop_park_bench", "worn", 615.0, -150.0, 90.0],
	["prop_park_bench", "worn", 607.0, -60.0, 90.0],
	["prop_adirondack_wood", "worn", 618.0, -95.0, 60.0], ["prop_adirondack_white", "worn", 617.0, -92.6, 40.0],
	["prop_sprinkler_impact", "normal", 580.0, -150.0, 0.0, false], ["prop_sprinkler_impact", "normal", 612.0, -140.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 560.0, -80.0, 0.0, false],
	# the hill lawn north of the bandstand: picnic tables with a view down to the bay
	["prop_picnic_table", "worn", 570.0, -170.0, 0.0], ["prop_bbq_kettle", "worn", 573.2, -170.0, 0.0],
	["prop_picnic_table", "worn", 588.0, -160.0, 90.0],
	# the apartments' back lawns: tables, grills, a washing line
	["prop_picnic_table", "worn", 536.0, -172.0, 0.0], ["prop_bbq_kettle", "worn", 539.2, -172.0, 0.0],
	["prop_clothesline", "worn", 538.0, -110.0, 90.0],
	["prop_adirondack_wood", "worn", 534.0, -92.0, -90.0], ["prop_adirondack_white", "worn", 534.0, -89.6, -110.0],
	# planting between the door paths on the u 500 street
	["plant_bird_of_paradise", "normal", 512.0, -169.0, 0.0], ["plant_bird_of_paradise", "normal", 512.0, -175.0, 0.0],
	["plant_agave_americana_small", "normal", 512.0, -118.0, 0.0], ["plant_agave_americana_small", "normal", 512.0, -110.0, 0.0],
	["plant_bird_of_paradise", "normal", 512.0, -87.0, 0.0], ["plant_bird_of_paradise", "normal", 512.0, -93.0, 0.0],
]

## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/fe/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_park_bench", 565.000, -112.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 575.000, -114.500, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 585.000, -112.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 566.000, -88.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 575.000, -85.500, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 584.000, -88.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 624.000, -124.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 624.000, -118.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 615.000, -175.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 615.000, -150.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 607.000, -60.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 565.000, -70.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 588.000, -70.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 588.000, -160.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/bakery", [2.2349212169647217, 1.4999825954437256, 6.7748332023620605, 0.48986963272094725, 2.999965190887451, 0.49008373260498045]],
	["Buildings/bakery", [-0.013369083404541016, 1.4999825954437256, 6.8799638748168945, 0.16, 2.999965190887451, 0.16]],
	["Buildings/surf", [2.036573886871338, 1.4999818801879883, 6.879859924316406, 0.16, 2.9999637603759766, 0.16]],
	["Buildings/a2", [9.469815254211426, 1.5499759912490845, 5.8649115562438965, 0.3001642608642578, 3.099951982498169, 0.31015304565429686]],
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
	var root := Node3D.new(); root.name = "n_fe_r1"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fe_r1")
	var yb := func(x: float, z: float) -> float: return S.y(BLK, x, z)
	var xr := func(z: float) -> float: return S.ring_u(S.RING_R1, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var by := H.pad_height([STAND[0], STAND[1], STAND[2], STAND[3]], 0.0, yb, 0.0)
	pe.append([STAND[0], STAND[1], STAND[2], STAND[3], by])
	var yf := S.field(BLK, pe)
	# stall rows (own patches): the stub's north row u 530 .. 559.7 (11) and south row; the shops' lot both sides
	var ls: Array = []; var ll: Array = []
	for k in 12:
		ls.append([530.0 + 2.7 * k - 0.05, -152.5, 530.0 + 2.7 * k + 0.05, STUB[0], "white"])
		ls.append([530.0 + 2.7 * k - 0.05, STUB[1], 530.0 + 2.7 * k + 0.05, -133.5, "white"])
	for k in 13:
		ll.append([562.0 + 2.7 * k - 0.05, -38.5, 562.0 + 2.7 * k + 0.05, -33.0, "white"])
		ll.append([562.0 + 2.7 * k - 0.05, -26.0, 562.0 + 2.7 * k + 0.05, -20.5, "white"])
	var regions := [[530.0, -152.5, 559.7, STUB[0], "asphalt", ls.filter(func(p: Array) -> bool: return p[1] < -150.0)],
		[530.0, STUB[1], 559.7, -133.5, "asphalt", ls.filter(func(p: Array) -> bool: return p[1] > -150.0)],
		[LOT[0], -38.5, 594.4, -33.0, "asphalt", ll.filter(func(p: Array) -> bool: return p[1] < -30.0)],
		[LOT[0], -26.0, 594.4, -20.5, "asphalt", ll.filter(func(p: Array) -> bool: return p[1] > -30.0)]]
	var paints: Array = []
	for r: Array in regions: paints.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append([STAND[0], STAND[1], STAND[2], STAND[3], "-"])
	paints.append_array([
		[X0, STUB[0], 562.0, STUB[1], "asphalt"],              # the apartments' stub
		[X0, SVC[0], 552.0, SVC[1], "asphalt"],                # the shops' service lane
		[LEG[0], -33.0, LEG[1], Z1, "asphalt"],                # the car park's entrance leg from the v 0 street's apron
		[LEG[1], -33.0, 596.0, -26.0, "asphalt"],              # the car park's aisle
		[X0, -15.0, 552.0, Z1, "plaza"],                       # the shops' forecourt on the v 0 street
		[PATH[0], Z0, PATH[1], Z1, "plaza"],                   # the ring path (to the v 0 street's walk)
		[LOOK[0], LOOK[1], LOOK[2], LOOK[3], "plaza"],
		[562.0, -101.0, PATH[0], -99.0, "plaza"],              # the bandstand lawn's walk to the path
		[524.0, -53.0, 526.0, -31.0, "concrete"],              # the shops' back walk from the service lane (bins)
		[545.0, -53.0, 547.0, -31.0, "concrete"],
		[596.0, -30.5, PATH[0], -28.5, "plaza"],               # from the car park to the path
		[562.0, -133.5, 564.0, -101.0, "plaza"],               # from the apartments' stalls down to the bandstand
	])
	for cv: float in [-172.0, -90.0]:
		for a: float in [-6.4, 0.0, 6.4]: paints.append([X0, cv + a - 1.0, 515.0, cv + a + 1.0, "plaza"])
	for a: float in [-4.2, 4.2]: paints.append([X0, -118.0 + a - 1.0, 515.0, -118.0 + a + 1.0, "plaza"])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	S.paint_rows(g, X0, Z0, Z1, xr, paints, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	H.level_pad(g, "plaza", STAND[0], STAND[1], STAND[2], STAND[3], by, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf, by)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fe_r1")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, by: float) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the bandstand on its pad, facing the lawn's south arc
	props.add("prop_bandstand", "worn", Vector3(575.0, by, -100.0), 0.0)
	# ---- the stalls: wheel stops, stop signs at the aprons, lot lights, oil
	for k in 11:
		P.call("prop_wheel_stop_concrete", "worn", 531.35 + 2.7 * k, -151.9, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", 531.35 + 2.7 * k, -134.1, 0.0)
	for k in 12:
		P.call("prop_wheel_stop_concrete", "worn", 563.35 + 2.7 * k, -37.9, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", 563.35 + 2.7 * k, -21.1, 0.0)
	P.call("prop_sign_stop", "worn", 511.2, -137.4, -90.0); P.call("prop_sign_stop", "worn", 511.2, -51.4, -90.0)
	P.call("prop_sign_stop", "worn", 562.4, -11.0, 180.0)
	P.call("prop_lot_light_pole", "worn", 561.0, -155.0, 90.0); P.call("prop_lot_light_pole", "worn", 597.6, -36.0, 90.0)
	W.oil(dec, rr, Vector2(536.75, -149.75), 0.0, yf, 0.5); W.oil(dec, rr, Vector2(547.55, -136.25), 0.0, yf, 0.5)
	W.oil(dec, rr, Vector2(568.75, -35.75), 0.0, yf, 0.5); W.oil(dec, rr, Vector2(579.55, -23.25), 0.0, yf, 0.5)
	W.lane_wear(dec, rr, -143.0, 511.0, 560.0, false, yf)
	W.lane_wear(dec, rr, -29.5, 562.0, 595.0, false, yf)
	# ---- the shops' service side: their dumpsters at the back walks' ends on the service lane, condensers on the backs
	P.call("prop_dumpster_3yd_green", "worn", 521.4, -51.8, 0.0); P.call("prop_dumpster_3yd_blue", "worn", 549.6, -51.8, 0.0)
	P.call("prop_ac_condenser", "worn", 530.0, -31.6, 0.0); P.call("prop_ac_condenser", "worn", 542.0, -31.6, 0.0)
	# ---- the apartments: condensers, mailboxes by the stub's mouth
	for cv: float in [-172.0, -90.0]: P.call("prop_ac_condenser", "worn", 529.4, cv - 7.6, -90.0)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", 511.0, -130.6 - 0.6 * k, -90.0)
	# ---- lamps: the path's west side, the forecourt, the lookout, the bandstand walk
	for z: float in [-180.0, -145.0, -70.0, -35.0]: P.call("prop_lamp_victorian", "worn", 598.8, z)
	for x: float in [520.0, 550.0]: P.call("prop_lamp_victorian", "worn", x, -10.2)
	P.call("prop_lamp_victorian", "worn", 608.0, -129.2); P.call("prop_lamp_globe", "worn", 566.0, -102.2)
