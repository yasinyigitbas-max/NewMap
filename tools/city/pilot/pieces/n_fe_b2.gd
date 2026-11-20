extends SceneTree
## Piece n_fe_b2 (fe fill, block 2): RINGSIDE (a service shop on the u 500 street, garden apartments, and the north
## end of GLORIETTA RING PARK with the OVERLOOK CAFE).
## u 509 (the u 500 street's east walk) .. the ring's inner walk (u 645.5 .. 643.1), v -985.7 (s_rg_b087's south walk)
## .. -809 (the -800 street's north walk). Placed at grid [0, 4.0, 0], yaw 0. Run once.
##
## WHY (planner): north across s_rg_b087 is the commercial strip; west across the u 500 street the shops and mews of
## n_fe_b1e; east the ring boulevard and beyond it the golf course and Glorietta Bay: this block is where the city
## meets that view. So: on the strip's side a two-bay SERVICE SHOP (bikes, a dry cleaner) facing the u 500 street, its
## customers parking off the street's north apron (v -946 .. -940); along the u 500 street four GARDEN APARTMENTS
## (the apartment band reaches u 560) with their stalls on a drive between the street's south apron (v -860 .. -854)
## and the -800 street's apron (u 554 .. 560), which also brings the park's visitors in (the bin lorry goes through);
## on the ring side the park: the ring path (north - south, it continues through n_fe_r7 .. r1), the OVERLOOK on the
## ring corner with the OVERLOOK CAFE's terrace facing the bay, a sand VOLLEYBALL court and a PICNIC GROVE under a sail.
## LAND: 4.1 along the strip and the ring, rising to 6.0 in the south-west corner; the ground follows it (n_fe_site.g
## "b2"), eased onto every walk; buildings on level pads at the highest ground under them, the field graded up to them.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fe_site.gd")

const BLK := "b2"
const X0 := 509.0
const Z0 := -985.7
const Z1 := -809.0
const B := [
	["trade", "ck/ck_svc_trade", 522.0, -975.0, -90.0],                 # front (two shop doors) on the u 500 street at u 516
	["cafe", "commercial/com_cafe_seaside", 630.0, -972.0, 90.0],       # front (its terrace) to the ring and the bay at u 638
	["a1", "apartments/apt_spanish_revival", 521.5, -919.0, -90.0],     # fronts on the u 500 street at u 515
	["a2", "apartments/apt_court_white", 521.1, -897.0, -90.0],
	["a3", "apartments/apt_spanish_white", 521.5, -875.0, -90.0],
	["a4", "apartments/apt_spanish_revival", 521.5, -838.0, -90.0],
]
const DA := [-947.0, -939.0]          # drive A from the u 500 street's north apron (v)
const DB := [-861.0, -853.0]          # drive B from the south apron (v)
const DC := [553.0, 561.0]            # drive C from the -800 street's apron (u)
const PATH := [618.0, 621.0]          # the ring path (u)
const VB := [550.0, -976.0, 570.0, -961.0]   # the volleyball sand
const OVL := [606.0, -985.7, 660.0, -962.0]  # the overlook plaza (clipped by the ring edge)

const ITEMS := [
	# the service shop's forecourt: a bike rack for the bike shop, a bench, a bin against its wall
	["prop_bike_rack", "worn", 512.2, -982.0, 90.0], ["prop_park_bench", "worn", 512.0, -967.4, -90.0],
	["prop_trash_receptacle", "worn", 515.5, -980.4, 0.0],
	# the overlook: benches on its east edge facing the bay, the cafe's terrace tables beside its door (door at v -970.2),
	# planters on the terrace's edge, a drinking fountain and a bin where the ring path arrives, a marker at the corner
	["prop_park_bench", "worn", 642.8, -981.0, 90.0], ["prop_park_bench", "worn", 642.4, -961.0, 90.0],
	["prop_patio_set_4", "worn", 641.0, -975.0, 0.0], ["prop_patio_set_4", "worn", 641.0, -966.6, 0.0],
	["plant_potted_leafy", "normal", 639.4, -978.6, 0.0], ["plant_potted_succulent", "normal", 639.4, -963.6, 0.0],
	["prop_drinking_fountain", "worn", 616.6, -963.0, 90.0],
	["prop_obelisk_monument", "worn", 611.0, -982.0, 0.0],
	# the volleyball court: benches either end for the players' bags, a cooler
	["prop_park_bench", "worn", 547.6, -968.5, 90.0], ["prop_park_bench", "worn", 572.4, -968.5, -90.0],
	["prop_ice_chest", "worn", 573.0, -964.0, 0.0],
	# the picnic grove west of the path: three tables under and beside the sail, a grill each, benches facing the path
	["prop_shade_sail", "normal", 604.0, -915.0, 0.0, false],
	["prop_picnic_table", "worn", 602.6, -915.0, 90.0], ["prop_picnic_table", "worn", 606.2, -915.0, 90.0],
	["prop_picnic_table", "worn", 604.0, -905.0, 0.0], ["prop_bbq_kettle", "worn", 600.0, -905.0, 0.0],
	["prop_bbq_kettle", "worn", 598.6, -915.0, 0.0],
	# benches along the ring path, facing east over the lawn to the boulevard and the bay
	["prop_park_bench", "worn", 622.6, -945.0, 90.0], ["prop_park_bench", "worn", 622.6, -900.0, 90.0],
	["prop_park_bench", "worn", 622.6, -855.0, 90.0], ["prop_park_bench", "worn", 622.6, -825.0, 90.0],
	["prop_adirondack_wood", "worn", 634.0, -930.0, 90.0], ["prop_adirondack_white", "worn", 634.0, -927.6, 70.0],
	["prop_picnic_table", "worn", 632.0, -880.0, 0.0],
	["prop_sprinkler_impact", "normal", 600.0, -940.0, 0.0, false], ["prop_sprinkler_impact", "normal", 632.0, -900.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 580.0, -900.0, 0.0, false],
	# the apartments' back lawns (between them and the stalls): tables and grills by the back doors, a washing line
	["prop_picnic_table", "worn", 536.0, -920.0, 0.0], ["prop_bbq_kettle", "worn", 536.0, -923.2, 0.0],
	["prop_clothesline", "worn", 540.0, -897.0, 90.0],
	["prop_adirondack_wood", "worn", 532.0, -876.0, -90.0], ["prop_adirondack_white", "worn", 532.0, -873.6, -110.0],
	["prop_picnic_table", "worn", 536.0, -838.0, 0.0],
	# the apartments' fronts on the u 500 street: planting between the door paths
	["plant_bird_of_paradise", "normal", 512.0, -916.0, 0.0], ["plant_bird_of_paradise", "normal", 512.0, -922.0, 0.0],
	["plant_agave_americana_small", "normal", 512.0, -897.0, 0.0], ["plant_agave_americana_small", "normal", 512.0, -889.0, 0.0],
	["plant_bird_of_paradise", "normal", 512.0, -872.0, 0.0], ["plant_bird_of_paradise", "normal", 512.0, -878.0, 0.0],
	["plant_iceplant_patch", "normal", 512.6, -835.0, 0.0, false], ["plant_iceplant_patch", "normal", 512.6, -841.0, 0.0, false],
]

## SUPERCHECKER (20 Nov, Yasin via the coordinator: "be MUCH more prone to delete ... any prop or road/ground mark
## with any finding or any doubt is deleted with its reason"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/fe/area.json); every finding on an item is a deletion here with the checker's reason; a collision box on
## each building column the checker measured. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_ac_condenser", 529.000, -971.000, "opening: prop_ac_condenser stands in front of a roll-up door of trade"],
	["prop_trash_receptacle", 515.500, -980.400, "opening: prop_trash_receptacle stands in front of a shop window of trade"],
	["prop_trash_cart_black", 621.600, -974.000, "bin_open: prop_trash_cart_black stands in the open (1.4 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_green", 621.600, -975.200, "bin_open: prop_trash_cart_green stands in the open (1.4 m from a wall, 99.0 m from a fence)"],
	["prop_park_bench", 547.600, -968.500, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 572.400, -968.500, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 622.600, -945.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 622.600, -900.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 622.600, -855.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 622.600, -825.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 632.000, -880.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 536.000, -838.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_shade_sail", 604.000, -915.000, "sail_over_nothing: a shade sail with no table, seat or play item under it"],
 ],
 "turn": [
 ],
 "decals": [

 ],
 "boxes": [
	["Buildings/trade", [-3.9000229835510254, 1.499967098236084, 5.650000095367432, 0.16, 2.999934196472168, 0.16]],
	["Buildings/trade", [1.03996342420578, 1.514954686164856, 7.659996747970581, 0.20003644466400147, 3.029909372329712, 0.19999937057495118]],
	["Buildings/trade", [-1.0400550365447998, 1.514954686164856, 7.659996747970581, 0.20003656387329102, 3.029909372329712, 0.19999937057495118]],
	["Buildings/trade", [-4.960036516189575, 1.514954686164856, 7.659996747970581, 0.20003656387329102, 3.029909372329712, 0.19999937057495118]],
	["Buildings/trade", [-2.1000688076019287, 1.499967098236084, 5.650000095367432, 0.16, 2.999934196472168, 0.16]],
	["Buildings/trade", [4.9599449634552, 1.514954686164856, 7.659996747970581, 0.20003656387329102, 3.029909372329712, 0.19999937057495118]],
	["Buildings/cafe", [1.0249133110046387, 1.4999818801879883, 6.8799638748168945, 0.16, 2.9999637603759766, 0.16]],
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
	var root := Node3D.new(); root.name = "n_fe_b2"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fe_b2")
	var yb := func(x: float, z: float) -> float: return S.y("b2", x, z)
	var xr := func(z: float) -> float: return S.ring_u(S.RING_B2, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yf := S.field(BLK, pe)
	# stall rows as their own patches: drive A's north row u 530 .. 551.6 (8 stalls); drive B's north row u 532 .. 551.0
	# and 563 .. 590 (drive C between), south row the same
	var la: Array = []; var lb: Array = []
	for k in 9: la.append([530.0 + 2.7 * k - 0.05, -952.5, 530.0 + 2.7 * k + 0.05, DA[0], "white"])
	for z: Array in [[-866.5, DB[0]], [DB[1], -847.5]]:
		for k in 8: lb.append([532.0 + 2.7 * k - 0.05, z[0], 532.0 + 2.7 * k + 0.05, z[1], "white"])
		for k in 11: lb.append([563.0 + 2.7 * k - 0.05, z[0], 563.0 + 2.7 * k + 0.05, z[1], "white"])
	var regions := [[530.0, -952.5, 551.6, DA[0], "asphalt", la],
		[532.0, -866.5, 550.9, DB[0], "asphalt", lb.slice(0, 8)], [563.0, -866.5, 590.0, DB[0], "asphalt", lb.slice(8, 19)],
		[532.0, DB[1], 550.9, -847.5, "asphalt", lb.slice(19, 27)], [563.0, DB[1], 590.0, -847.5, "asphalt", lb.slice(27)]]
	var paints: Array = []
	for r: Array in regions: paints.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append_array([
		[VB[0], VB[1], VB[2], VB[3], "sand"],                  # the volleyball court
		[X0, DA[0], 553.0, DA[1], "asphalt"],                  # drive A (ends in a turning head at u 553)
		[X0, DB[0], 592.0, DB[1], "asphalt"],                  # drive B
		[DC[0], DB[1], DC[1], Z1, "asphalt"],                  # drive C to the -800 street's apron
		[X0, -985.7, 516.0, -964.0, "plaza"],                  # the service shop's forecourt on the u 500 street
		[516.0, -964.0, 528.5, -947.0, "plaza"],               # the walk from its stalls to its door
		[OVL[0], OVL[1], OVL[2], OVL[3], "plaza"],             # the overlook and the cafe's terrace
		[PATH[0], OVL[3], PATH[1], Z1, "plaza"],               # the ring path
		[528.0, -959.0, PATH[0], -957.0, "plaza"],             # the walk from the u 500 street side to the volleyball and the path
		[592.0, -858.0, PATH[0], -856.0, "plaza"],             # the walk from the park's stalls to the path
	])
	# door paths from the u 500 street to the apartments' doors (spanish lobby at along 0, side doors +-6.4; court_white +-4.2)
	for cv: float in [-919.0, -875.0, -838.0]:
		for a: float in [-6.4, 0.0, 6.4]: paints.append([X0, cv + a - 1.0, 515.0, cv + a + 1.0, "plaza"])
	for a: float in [-4.2, 4.2]: paints.append([X0, -897.0 + a - 1.0, 515.0, -897.0 + a + 1.0, "plaza"])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf)
	S.paint_rows(g, X0, Z0, Z1, xr, paints, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fe_b2")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the stalls: wheel stops at every head, lot lights, stop signs where cars leave at the three aprons
	for k in 8: P.call("prop_wheel_stop_concrete", "worn", 531.35 + 2.7 * k, -951.9, 0.0)
	for z: float in [-865.9, -848.1]:
		for k in 7: P.call("prop_wheel_stop_concrete", "worn", 533.35 + 2.7 * k, z, 0.0)
		for k in 10: P.call("prop_wheel_stop_concrete", "worn", 564.35 + 2.7 * k, z, 0.0)
	P.call("prop_lot_light_pole", "worn", 552.6, -951.0, 0.0)
	P.call("prop_lot_light_pole", "worn", 591.4, -864.0, 90.0)
	P.call("prop_lot_light_pole", "worn", 531.0, -849.0, 90.0)
	P.call("prop_sign_stop", "worn", 511.2, -937.4, -90.0)
	P.call("prop_sign_stop", "worn", 511.2, -851.4, -90.0)
	P.call("prop_sign_stop", "worn", 562.4, -811.2, 180.0)
	for xx: float in [536.75, 547.55]: W.oil(dec, rr, Vector2(xx, -949.75), 0.0, yf, 0.5)
	for xx: float in [539.75, 569.75, 580.55]: W.oil(dec, rr, Vector2(xx, -863.75), 0.0, yf, 0.5)
	W.oil(dec, rr, Vector2(545.15, -850.25), 0.0, yf, 0.5)
	W.lane_wear(dec, rr, -857.0, 511.0, 590.0, false, yf)
	# ---- the service shop: its dumpster on the back (service bay) side, a condenser
	P.call("prop_dumpster_3yd_blue", "worn", 531.0, -978.0, 90.0)
	P.call("prop_ac_condenser", "worn", 529.0, -971.0, -90.0)
	# ---- the cafe: its bins against its back wall, a condenser
	P.call("prop_trash_cart_black", "worn", 621.6, -974.0, 90.0); P.call("prop_trash_cart_green", "worn", 621.6, -975.2, 90.0)
	P.call("prop_ac_condenser", "worn", 621.4, -969.5, 90.0)
	# ---- the apartments: condensers at their back corners, the mailboxes by drive B's mouth, bins on the stall walk,
	#      the residents' dumpster at drive B's east end against the lot light's island
	for cv: float in [-919.0, -875.0, -838.0]: P.call("prop_ac_condenser", "worn", 529.4, cv - 7.5, -90.0)
	for k in 4: P.call("prop_mailbox_post_metal", "worn", 512.0, -864.0 - 0.6 * k, -90.0)
	P.call("prop_dumpster_3yd_green", "worn", 593.6, -850.0, 90.0)
	# ---- the park: lamps along the ring path (west side), on the overlook and the walks
	for z: float in [-950.0, -915.0, -880.0, -845.0, -815.0]: P.call("prop_lamp_victorian", "worn", 616.8, z)
	P.call("prop_lamp_victorian", "worn", 625.0, -963.0); P.call("prop_lamp_victorian", "worn", 608.0, -963.0)
	P.call("prop_lamp_globe", "worn", 575.0, -963.2); P.call("prop_lamp_globe", "worn", 600.0, -854.8)
	# ---- the volleyball net across the sand
	P.call("prop_volleyball_net", "worn", 560.0, -968.5, 90.0)
