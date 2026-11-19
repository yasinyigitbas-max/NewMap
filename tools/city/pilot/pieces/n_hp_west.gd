extends SceneTree
## Piece n_hp_west (hospital zone, west of Adela): BAY MEDICAL PLAZA, the staff garage and BAYVIEW CARE RESIDENCES.
## u 400 (the zone's west line, ZONING.md "hosp"; the land west of it is not this zone's) .. 490.8 (Adela's west walk),
## v -1585.7 (1st St's south walk) .. -1414.3 (3rd St's north walk). Placed at grid [0, 2.0, 0], yaw 0. Run once.
##
## WHY (planner): the hospital's other side of Adela, for what a hospital pulls in around it. The car opening is
## Adela's west apron (v -1460 .. -1454), opposite the hospital's: MEDICAL PLAZA DRIVE runs west from it. On the drive:
## the STAFF GARAGE (ext_parking_garage, its ramp on the drive) so the hospital's own lot stays for visitors, and the
## residents' lane north. On the 3rd St / Adela corner, facing the hospital and the bus platform across Adela: the
## MEDICAL OFFICE TOWER (twr_office, urgent care behind its door; its service door on a short lane from the drive).
## On 3rd St, where people walk out of the tower and the bus station: the PHARMACY (ck_svc_trade_1d) and ISLA BISTRO
## (com_bistro, its name painted on), their tables on a forecourt, their deliveries from a row of stalls on the drive.
## On the bay (1st St): two CARE RESIDENCES (apt_garden_cream) for the elderly and the long-stay families, a garden
## court behind them, and their WELLNESS CENTER (civ_community_center, its COMMUNITY CENTER sign painted on) facing
## Adela so the bus riders walk straight in.
## LAND (Yasin: "build according to it"): the ground follows the land (n_hp_site.g; at the west line it is the land
## itself plus 5 cm, a skirt below); every building on a level pad at its front's height.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_hp_site.gd")

const X0 := 400.0
const X1 := 490.8
const DRIVE := [-1461.0, -1453.0]
## [label, folder, centre u, centre v, yaw]
const B := [
	["garage", "extras/ext_parking_garage", 460.0, -1480.3, 0.0],       # front (ramp) on the drive at v -1465
	["tower", "urban/twr_office", 471.0, -1432.0, 90.0],                # front (door) on Adela's side at u 483.5
	["pharmacy", "ck/ck_svc_trade_1d", 427.0, -1425.5, 0.0],            # front on 3rd St at v -1419.5, door at u 424
	["bistro", "commercial/com_bistro", 410.0, -1427.67, 0.0],          # front on 3rd St at v -1419.5, door at u 414.76
	["care_w", "apartments/apt_garden_cream", 428.0, -1571.9, 180.0],   # front on 1st St at v -1578
	["care_e", "apartments/apt_garden_cream", 466.0, -1571.9, 180.0],
	["wellness", "civic/civ_community_center", 476.05, -1535.0, 90.0],  # front (door) on Adela's side at u 487
]
const LANE := [404.0, 411.0]                 # the residents' lane from the drive north
const RLOT := [404.0, -1512.0, 440.0, -1494.0]
const SVC := [440.0, -1453.0, 447.0, -1422.0]

const GREEN := [
	# the garden court between the residences and the lot: trees in the lawn, benches on the loop path facing the beds,
	# a shade sail over two picnic tables, a pergola, sprinklers
	["tree_jacaranda_a", "normal", 418.0, -1545.0, 0.0, false], ["tree_magnolia_b", "normal", 452.0, -1552.0, 50.0, false],
	["tree_coral_a", "normal", 432.0, -1522.0, 100.0, false], ["palm_queen_a", "normal", 458.0, -1520.0, 0.0, false],
	["prop_park_bench", "worn", 424.0, -1556.0, 0.0], ["prop_park_bench", "worn", 446.0, -1556.0, 0.0],
	["prop_park_bench", "worn", 424.0, -1530.0, 180.0], ["prop_park_bench", "worn", 446.0, -1530.0, 180.0],
	["prop_shade_sail", "normal", 435.0, -1543.0, 0.0, false],
	["prop_picnic_table", "worn", 432.0, -1543.0, 90.0], ["prop_picnic_table", "worn", 438.5, -1543.0, 90.0],
	["prop_garden_arbor", "normal", 410.0, -1543.0, 90.0],
	["plant_bird_of_paradise", "normal", 420.0, -1537.0, 0.0, false], ["plant_bougainvillea_mound", "normal", 450.0, -1537.0, 0.0, false],
	["plant_agave_americana", "normal", 460.0, -1548.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 415.0, -1530.0, 0.0, false], ["prop_sprinkler_impact", "normal", 455.0, -1560.0, 0.0, false],
	# 1st St front gardens: low planting between the doors' paths, palms at the ends
	["palm_mexican_fan_a", "normal", 403.0, -1581.0, 0.0, false], ["palm_mexican_fan_b", "normal", 449.5, -1580.5, 0.0, false],
	["palm_mexican_fan_a", "normal", 486.0, -1581.0, 0.0, false],
	["plant_iceplant_patch", "normal", 428.0, -1581.5, 0.0, false], ["plant_iceplant_patch", "normal", 466.0, -1581.5, 0.0, false],
	# Adela side: trees in the grass strip
	["tree_jacaranda_b", "normal", 489.0, -1505.0, 0.0, false], ["tree_jacaranda_a", "normal", 489.0, -1490.0, 90.0, false],
	["tree_jacaranda_b", "normal", 489.0, -1475.0, 180.0, false], ["tree_coral_b", "normal", 489.2, -1560.0, 30.0, false],
	# 3rd St forecourt: trees in wells
	["tree_ficus_a", "normal", 436.0, -1416.0, 0.0, false], ["tree_ficus_b", "normal", 452.0, -1416.0, 0.0, false],
]

var PY: Array = []     # pad heights (local), one per row of B

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array:
	var st := K.building_stats(f)
	if st.has("near"): return (st.near as Dictionary).bbox
	var wd: Array = st.footprint_wd
	return [[-float(wd[0]) * 0.5, 0.0, -float(wd[1]) * 0.5], [float(wd[0]) * 0.5, float(st.get("height", 6.0)), float(wd[1]) * 0.5]]
## footprint [u0, v0, u1, v1] of one row of B (yaw 0 / 90 / 180)
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]   # yaw 90

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hp_west"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hp_west")
	var yb := func(x: float, z: float) -> float: return S.y(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yf := H.graded(yb, pe)
	var paints: Array = []
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	# stall lines: the residents' lot (two rows) and the delivery stalls on the drive's south side
	for k in 11:
		var x := 411.0 + 2.7 * k
		paints.append([x - 0.05, -1512.0, x + 0.05, -1506.5, "white"]); paints.append([x - 0.05, -1499.5, x + 0.05, -1494.0, "white"])
	for k in 13:
		var x := 405.0 + 2.7 * k
		paints.append([x - 0.05, -1453.0, x + 0.05, -1447.5, "white"])
	paints.append([447.0, -1457.08, 488.0, -1456.92, "yellow"])
	paints.append([488.4, -1461.0, 488.8, -1457.08, "white"])           # stop bar at the apron
	for t: Array in [[436.0, -1416.0], [452.0, -1416.0]]:
		paints.append([float(t[0]) - 0.8, float(t[1]) - 0.8, float(t[0]) + 0.8, float(t[1]) + 0.8, "mulch"])
	paints.append_array([
		[488.0, -1461.0, 490.8, -1460.0, "concrete"], [488.0, -1454.0, 490.8, -1453.0, "concrete"],   # flare to the apron
		[404.0, DRIVE[0], 490.8, DRIVE[1], "asphalt"],         # Medical Plaza Drive
		[455.0, -1465.0, 465.0, DRIVE[0], "asphalt"],          # the garage ramp's apron
		[LANE[0], -1499.5, LANE[1], DRIVE[0], "asphalt"],      # the residents' lane
		[RLOT[0], RLOT[1], RLOT[2], RLOT[3], "asphalt"],       # the residents' lot
		[404.0, -1453.0, 440.0, -1447.5, "asphalt"],           # delivery / short-stay stalls
		[SVC[0], SVC[1], SVC[2], SVC[3], "asphalt"],           # the tower's service lane
		[447.0, -1430.0, 459.5, -1422.0, "asphalt"],           # ... and its apron at the service door
		[483.5, -1453.0, 490.8, -1414.3, "plaza"],             # the tower's forecourt on Adela
		[400.0, -1419.5, 483.5, -1414.3, "plaza"],             # the 3rd St forecourt (tables, wells)
		[447.0, -1422.0, 459.5, -1419.5, "plaza"],
		[400.0, -1447.5, 440.0, -1445.5, "concrete"],          # the back walk behind the stalls
		[429.0, -1445.5, 431.0, -1431.5, "concrete"],          # ... to the pharmacy's back (service door u 430)
		[406.6, -1445.5, 408.6, -1435.12, "concrete"],         # ... to the bistro's kitchen door (u 407.6)
		[478.45, -1496.0, 483.0, -1465.0, "plaza"],            # the walk from the garage stairs to the drive and Adela
		[440.02, -1512.0, 454.53, -1494.0, "concrete"],        # the garage's north walk to the court
		[474.0, -1521.0, 476.0, -1495.75, "plaza"],            # garage stair door (u 474.4) north past the wellness center
		[476.0, -1521.0, 487.0, -1519.0, "plaza"],             # ... east to Adela's side
		[487.0, -1540.0, 490.8, -1519.0, "plaza"],             # the wellness center's door walk (door u 487, v -1535)
		[410.0, -1559.0, 462.0, -1557.5, "plaza"],             # the garden court's loop path
		[410.0, -1528.5, 462.0, -1527.0, "plaza"],
		[409.25, -1559.0, 410.75, -1527.0, "plaza"], [461.25, -1559.0, 462.75, -1527.0, "plaza"],
		[426.25, -1566.68, 427.75, -1559.0, "plaza"], [464.25, -1566.68, 465.75, -1559.0, "plaza"],   # residences' back doors
		[400.0, -1585.7, 490.8, -1583.7, "plaza"],             # the front walk along 1st St
	])
	# front paths from 1st St to the residences' doors (front doors at along +-0.75 / +-6.45 / +-7.95: u = cu - along)
	for cu: float in [428.0, 466.0]:
		for a: float in [-7.2, 0.0, 7.2]:
			paints.append([cu - a - 1.0, -1583.7, cu - a + 1.0, -1578.0, "plaza"])
	H.paint(g, X0, -1585.7, X1, S.THIRD, paints, "grass", yf)
	# the west line: the land beside is lower (2 .. 30 cm): a face down from the edge
	H.skirt(g, Vector2(X0, -1585.7), Vector2(X0, S.THIRD), yf, "wall")
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, GREEN)
	H.finish(root, g, props, dec, "n_hp_west")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the drive: lamps on its north side, the stop sign at the apron, the garage's pay station by the ramp
	for x: float in [415.0, 438.0, 482.0]: P.call("prop_lamp_cobra", "worn", x, -1463.0, 180.0)
	P.call("prop_sign_stop", "worn", 488.8, -1452.4, 90.0)
	P.call("prop_pay_station", "worn", 453.6, -1463.8, 0.0)
	P.call("prop_sign_no_parking", "worn", 466.6, -1462.0, 0.0)
	# ---- delivery stalls: wheel stops at their heads (the back walk), oil, the businesses' dumpsters on the walk's end
	for k in 12:
		P.call("prop_wheel_stop_concrete", "worn", 406.35 + 2.7 * k, -1448.1, 0.0)
		if k % 3 == 1: W.oil(dec, rr, Vector2(406.35 + 2.7 * k, -1450.5), 0.0, yf, 0.5)
	P.call("prop_dumpster_3yd_green", "worn", 402.0, -1433.0, 90.0)      # the bistro's kitchen bin, beside its back
	P.call("prop_dumpster_3yd_blue", "worn", 434.6, -1428.0, 90.0)       # the pharmacy's boxes
	P.call("prop_lot_light_pole", "worn", 427.0, -1444.2, 0.0)
	# ---- the tower's forecourt on Adela: benches facing the street and the hospital, planters, a bike rack, a bin,
	#      bollards along the drive side; its service apron: the building's dumpster and a condenser bank
	for z: float in [-1440.0, -1424.0]: P.call("prop_park_bench", "worn", 489.4, z, 90.0)
	P.call("plant_potted_leafy", "normal", 485.0, -1435.0, 0.0, false)
	P.call("plant_potted_leafy", "normal", 485.0, -1429.0, 0.0, false)
	P.call("prop_trash_receptacle", "worn", 489.6, -1436.5)
	P.call("prop_bike_rack", "worn", 486.5, -1447.0, 0.0)
	for x: float in [484.0, 485.8]: P.call("prop_bollard_concrete", "worn", x, -1452.4)
	P.call("prop_lamp_victorian", "worn", 489.6, -1418.0)
	P.call("prop_dumpster_3yd_green", "worn", 457.9, -1421.4, 90.0)
	for z: float in [-1442.0, -1439.5, -1437.0]: P.call("prop_ac_condenser", "worn", 458.4, z, 90.0)
	W.oil(dec, rr, Vector2(443.5, -1440.0), 90.0, yf, 0.5)
	# ---- the 3rd St forecourt: the bistro's tables on its side (door at u 414.76), the pharmacy's bench and paper box,
	#      a lamp, a bus-goers' bin
	P.call("prop_patio_set_4", "worn", 405.5, -1417.0, 0.0)
	P.call("prop_patio_set_4", "worn", 410.0, -1417.0, 20.0)
	P.call("plant_potted_succulent", "normal", 417.2, -1418.6, 0.0, false)
	P.call("prop_park_bench", "worn", 428.5, -1415.4, 0.0)
	P.call("prop_newspaper_box_red", "worn", 431.8, -1418.8, 0.0)
	P.call("prop_trash_receptacle", "worn", 444.0, -1415.3)
	P.call("prop_lamp_victorian", "worn", 419.5, -1415.0)
	P.call("prop_lamp_victorian", "worn", 466.0, -1415.0)
	# ---- the residents' lot: wheel stops, a light, the residences' dumpster against the garage's west wall
	for k in 10:
		P.call("prop_wheel_stop_concrete", "worn", 412.35 + 2.7 * k, -1511.4, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", 412.35 + 2.7 * k, -1494.6, 0.0)
	P.call("prop_lot_light_pole", "worn", 407.5, -1509.2, 0.0)
	P.call("prop_dumpster_3yd_green", "worn", 404.8, -1513.5, 90.0)
	P.call("prop_recycling_receptacle", "worn", 404.8, -1516.2, 0.0)
	# ---- the garage's stair walk and north side: a bin, a bench, a lamp
	P.call("prop_trash_receptacle", "worn", 481.6, -1494.0)
	P.call("prop_lamp_globe", "worn", 482.2, -1480.0)
	P.call("prop_lamp_globe", "worn", 476.8, -1508.0)
	# ---- the wellness center's door walk: benches either side, planters; a mailbox cluster for the residences
	P.call("prop_park_bench", "worn", 489.6, -1517.0, 90.0)
	P.call("prop_park_bench", "worn", 489.6, -1543.0, 90.0)
	P.call("plant_potted_leafy", "normal", 488.0, -1531.0, 0.0, false)
	P.call("plant_potted_leafy", "normal", 488.0, -1539.0, 0.0, false)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", 446.5 + 0.6 * k, -1583.2, 180.0)
	# ---- the residences: condensers on the ends, a bench at each front door path, lamps on the front walk
	for cu: float in [428.0, 466.0]:
		P.call("prop_ac_condenser", "worn", cu - 13.0, -1569.0, 90.0)
		P.call("prop_ac_condenser", "worn", cu + 13.6, -1569.0, -90.0)
		P.call("prop_lamp_globe", "worn", cu - 3.6, -1583.2)
		P.call("prop_lamp_globe", "worn", cu + 3.6, -1583.2)
	W.lane_wear(dec, rr, -1457.0, 447.0, 488.0, false, yf)
	W.lane_wear(dec, rr, -1503.0, 411.0, 440.0, false, yf)
