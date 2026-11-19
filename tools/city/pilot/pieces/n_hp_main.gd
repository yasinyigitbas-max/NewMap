extends SceneTree
## Piece n_hp_main (hospital zone, block A north): ISLAND HOSPITAL. u 509.2 (Adela's east walk) .. the ring's walk
## (1st St / Glorietta Blvd round the bay, n_hp_site.RING), v (the ring) .. -1453 (the campus drive's south kerb; south
## of it n_hp_transit). Placed at grid [0, 2.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner): the island's hospital on the bridge route (ZONING.md MUST site). Everybody comes in at the one car
## opening there is, Adela's apron 57 m north of 3rd St (the streets round the block are locked and have no other):
## HOSPITAL DRIVE runs east from it along the block. North of the drive the two buildings face it: the main hospital
## (pub_hospital: lobby and the hospital café behind its two front doors) with its drop-off forecourt, and the ER wing
## (ext_hospital, its EMERGENCY signs painted on) with the ambulance bay in front of its doors; the helipad is across the
## drive (n_hp_transit), so a patient goes straight over the drive into the bay. Between the two buildings a covered-walk
## line of paving from the car park to the forecourt; the ER's walk-in door opens on it. Behind: the loading dock at
## the main hospital's service door, the plant yard behind the ER (oxygen tank, generator fuel, transformer, chillers),
## the visitors' and staff car park, reached by the service drive on the east side. The bay curve of the ring holds the
## healing garden (benches facing the water, an arbor, picnic tables for staff breaks).
## LAND: flat (walks 2.150 all round, land 1.80 .. 2.13): one surface at the walk's height; no faces needed against the
## streets (same height); the buildings stand on it.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_hp_site.gd")

const X0 := 509.2
const X1 := 645.7
const ZS := -1453.0                    # south edge of this piece: the drive's south kerb
const DRIVE := [-1461.0, -1453.0]      # Hospital Drive (8 m) from the apron east to the service drive
const SVC := [612.0, 620.0]            # the service drive (north to the car park)
const SVC_N := -1537.0
## the main hospital and the ER wing, fronts on the drive's forecourt
const MAIN := ["public/pub_hospital", 541.0, -1482.46]     # front v -1468.0, u 522.55 .. 559.45, back -1493.96
const ER := ["extras/ext_hospital", 590.0, -1483.57]       # front v -1470.0, u 567.43 .. 605.72, back -1493.07
## car park rows (v ranges) and aisles; stalls 2.7 m wide, 5.5 m deep
const AISLES := [[514.0, -1519.0, 612.0, -1512.0], [514.0, -1537.0, 612.0, -1530.0], [514.0, -1555.0, 560.0, -1548.0], [514.0, -1573.0, 560.0, -1566.0],
	[514.0, -1573.0, 521.0, -1512.0]]
const ROWS := [[521.0, 610.0, -1524.5, -1519.0], [521.0, 610.0, -1530.0, -1524.5], [521.0, 599.0, -1542.5, -1537.0], [521.0, 559.0, -1548.0, -1542.5],
	[521.0, 559.0, -1560.5, -1555.0], [521.0, 559.0, -1566.0, -1560.5], [521.0, 559.0, -1578.5, -1573.0]]

## POLISH-style hand list of the garden and planting props: [base, cond, u, v, yaw(, collide)], each with its reason in
## the comment block it sits in, stood on the ground as built (hs_fill_lib.polish)
const GARDEN := [
	# healing garden on the bay curve: benches face the water (north-east), an arbor over the path, trees for shade
	["prop_park_bench", "worn", 575.0, -1556.0, 215.0], ["prop_park_bench", "worn", 589.0, -1548.0, 215.0],
	["prop_park_bench", "worn", 600.0, -1548.5, 225.0], ["prop_garden_arbor", "normal", 580.0, -1551.5, 90.0],
	["prop_picnic_table", "worn", 626.0, -1505.0, 80.0], ["prop_picnic_table", "worn", 627.5, -1482.0, 100.0],
	["prop_drinking_fountain", "worn", 605.5, -1545.0, 0.0], ["prop_trash_receptacle", "worn", 607.7, -1545.0, 0.0],
	["tree_jacaranda_a", "normal", 570.0, -1563.0, 20.0, false], ["tree_coral_b", "normal", 597.0, -1556.0, 70.0, false],
	["tree_magnolia_a", "normal", 589.0, -1562.0, 110.0, false], ["palm_queen_a", "normal", 581.0, -1563.0, 0.0, false],
	["tree_ficus_b", "normal", 630.5, -1495.0, 15.0, false], ["tree_jacaranda_b", "normal", 632.0, -1470.0, 200.0, false],
	["plant_bird_of_paradise", "normal", 578.0, -1550.0, 0.0, false], ["plant_agave_americana", "normal", 566.0, -1546.0, 40.0, false],
	["plant_bougainvillea_mound", "normal", 625.0, -1515.0, 0.0, false], ["plant_iceplant_patch", "normal", 634.0, -1460.0, 0.0, false],
	["prop_sprinkler_impact", "normal", 588.0, -1556.0, 0.0, false], ["prop_sprinkler_impact", "normal", 628.0, -1498.0, 0.0, false],
	# Adela frontage: a row of jacarandas in the grass strip in front of the car park's hedge
	["tree_jacaranda_a", "normal", 511.4, -1576.0, 0.0, false], ["tree_jacaranda_b", "normal", 511.4, -1556.0, 60.0, false],
	["tree_jacaranda_a", "normal", 511.4, -1536.0, 120.0, false], ["tree_jacaranda_b", "normal", 511.4, -1516.0, 180.0, false],
	["tree_coral_a", "normal", 511.6, -1496.0, 40.0, false], ["palm_queen_b", "normal", 512.0, -1478.0, 0.0, false],
	# the bay-front strip north of the car park (1st St)
	["tree_torrey_pine_a", "normal", 530.0, -1582.0, 0.0, false], ["tree_torrey_pine_b", "normal", 548.0, -1582.0, 90.0, false],
	["plant_agave_americana_small", "normal", 539.0, -1582.0, 0.0, false],
]

func _init() -> void: _run.call_deferred()

static func bb(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
## footprint [u0, v0, u1, v1] of a yaw-0 building
static func fp(b: Array) -> Array:
	var x := bb(String(b[0]))
	return [float(b[1]) + float(x[0][0]), float(b[2]) + float(x[0][2]), float(b[1]) + float(x[1][0]), float(b[2]) + float(x[1][2])]

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hp_main"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hp_main")
	var yf := func(x: float, z: float) -> float: return S.flat(x, z)
	# ================================================================ ground (one flat surface at the walk's height)
	var m := fp(MAIN); var e := fp(ER)
	var paints: Array = []
	# stall lines (white, 0.1 m) across every row, wheel-stop side to aisle side
	for r: Array in ROWS:
		var x := float(r[0])
		while x <= float(r[1]) + 0.01:
			paints.append([x - 0.05, float(r[2]), x + 0.05, float(r[3]), "white"])
			x += 2.7
	# the drive's centre line, the stop bar at the apron and a zebra from the helipad gate to the ambulance bay
	paints.append([512.0, -1457.08, 610.0, -1456.92, "yellow"])
	paints.append([512.0, -1461.0, 512.4, -1457.08, "white"])
	for k in 6: paints.append([604.0, DRIVE[0] + 0.6 + 1.2 * k, 607.0, DRIVE[0] + 1.2 + 1.2 * k, "white"])
	paints.append_array([
		[m[0], m[1], m[2], m[3], "concrete"],                 # under the main hospital
		[e[0], e[1], e[2], e[3], "concrete"],                 # under the ER wing
		[509.2, -1461.0, 512.0, -1460.0, "concrete"],         # the drive's flare to the 6 m apron
		[509.2, -1454.0, 512.0, -1453.0, "concrete"],
		[509.2, DRIVE[0], 620.0, DRIVE[1], "asphalt"],        # Hospital Drive
		[572.0, -1470.0, 604.0, DRIVE[0], "asphalt"],         # the ambulance bay in front of the ER doors
		[516.0, -1470.0, 572.0, DRIVE[0], "plaza"],           # the main entrance forecourt (drop-off at its kerb)
		[559.45, -1494.0, 567.43, -1468.0, "plaza"],          # the walk between the buildings (ER walk-in door)
		[604.0, -1470.0, 612.0, DRIVE[0], "plaza"],           # the walk from the bay round to the service drive
		[559.45, -1512.0, 567.43, -1494.0, "plaza"],          # ... and on to the car park
		[560.0, -1552.5, 601.5, -1550.5, "plaza"],            # the healing garden's path from the car park
		[599.5, -1550.5, 601.5, -1537.0, "plaza"],
		[522.0, -1512.0, 547.0, -1493.96, "concrete"],        # the loading dock apron at the service door
		[569.0, -1510.0, 605.0, -1493.07, "gravel"],          # the plant yard (fenced)
		[SVC[0], SVC_N, SVC[1], DRIVE[0], "asphalt"],         # the service drive
	])
	for a: Array in AISLES: paints.append([a[0], a[1], a[2], a[3], "asphalt"])
	for r: Array in ROWS: paints.append([r[0], r[2], r[1], r[3], "asphalt"])
	paints.append_array([
		[514.0, -1578.5, 560.0, -1512.0, "concrete"],         # (the car park's walk edges: grass islands below override)
	])
	# extra column lines along the ring's tight arc (zero-area entries: they only cut the columns finer)
	var u := 619.0
	while u <= 645.6: paints.append([u, -1500.0, u, -1500.0, "-"]); u += 0.5
	for p: Array in S.RING: paints.append([float(p[0]), -1500.0, float(p[0]), -1500.0, "-"])
	var zlo := func(x: float) -> float: return S.ring_v(x)
	var zhi := func(_x: float) -> float: return ZS
	H.paint_band(g, X0, X1, zlo, zhi, paints, "grass", yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, GARDEN)
	H.finish(root, g, props, dec, "n_hp_main")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	K.building(bl, String(MAIN[0]), Vector3(MAIN[1], S.WALK, MAIN[2]), 0.0, "hospital")
	K.building(bl, String(ER[0]), Vector3(ER[1], S.WALK, ER[2]), 0.0, "er_wing")
	# ---- the forecourt: benches either side of the doors (u 538.8 / 543.2) facing the drive, planters, bike racks at
	#      the west end, bollards on the drop-off kerb so nobody drives onto the forecourt, a bin and a paper box
	for x: float in [525.5, 529.5, 552.5, 556.5]: P.call("prop_park_bench", "worn", x, -1467.0, 0.0)
	for x: float in [519.0, 524.5, 535.0, 547.0, 557.5, 564.0]: P.call("prop_bollard_concrete", "worn", x, -1461.6)
	P.call("prop_bike_rack", "worn", 518.5, -1465.5, 90.0)
	P.call("prop_trash_receptacle", "worn", 533.0, -1467.3)
	P.call("prop_recycling_receptacle", "worn", 549.0, -1467.3)
	P.call("prop_newspaper_box_blue", "worn", 531.4, -1467.4, 0.0)
	P.call("plant_potted_leafy", "normal", 535.3, -1467.4, 0.0, false)
	P.call("plant_potted_leafy", "normal", 546.7, -1467.4, 0.0, false)
	P.call("prop_lamp_victorian", "worn", 521.0, -1462.2)
	P.call("prop_lamp_victorian", "worn", 541.0, -1462.2)
	P.call("prop_lamp_victorian", "worn", 561.0, -1462.2)
	P.call("prop_sign_no_parking", "worn", 516.6, -1461.5, 180.0)      # drop-off only along the forecourt kerb
	# ---- the ambulance bay: no parking signs at its two ends, bollards protecting the ER's corners, a lamp
	P.call("prop_sign_no_parking", "worn", 571.4, -1469.0, 180.0)
	P.call("prop_sign_no_parking", "worn", 604.6, -1469.0, 180.0)
	P.call("prop_bollard_steel", "worn", 568.4, -1469.4)
	P.call("prop_bollard_steel", "worn", 605.2, -1469.4)
	P.call("prop_lamp_cobra", "worn", 608.5, -1463.5, 180.0)
	W.oil(dec, rr, Vector2(582.0, -1465.0), 0.0, yf, 0.45)
	W.oil(dec, rr, Vector2(594.0, -1465.5), 0.0, yf, 0.4)
	# ---- the walk between the buildings: the ER walk-in door is on it (left facade); benches against the main
	#      hospital's east wall, a bin, an AED-style call point is not in the kit (none)
	P.call("prop_park_bench", "worn", 560.3, -1478.0, 90.0)
	P.call("prop_park_bench", "worn", 560.3, -1488.0, 90.0)
	P.call("prop_trash_receptacle", "worn", 560.2, -1491.5)
	P.call("plant_potted_succulent", "normal", 566.6, -1474.5, 0.0, false)
	# ---- the loading dock at the main hospital's service door (u 531): the dumpsters against the wall west of the door,
	#      the roll-off for the building's waste at the dock's west side, cones to keep the bay clear
	P.call("prop_dumpster_3yd_green", "worn", 524.6, -1495.2, 0.0)
	P.call("prop_dumpster_3yd_blue", "worn", 524.6, -1498.0, 0.0)
	P.call("prop_dumpster_rolloff_20yd", "worn", 543.5, -1504.0, 0.0)
	P.call("prop_cone_28in", "worn", 528.5, -1501.0)
	P.call("prop_cone_28in", "worn", 533.5, -1501.0)
	P.call("prop_lot_light_pole", "worn", 546.0, -1509.0, 90.0)
	W.oil(dec, rr, Vector2(531.0, -1503.0), 0.0, yf, 0.6)
	W.oil(dec, rr, Vector2(537.0, -1508.0), 90.0, yf, 0.5)
	# ---- the plant yard behind the ER (fenced, gate on the car park aisle): liquid oxygen tank, generator fuel tank,
	#      transformer, the chillers' condensers in a row against the ER's back wall
	H.fence(props, "fence_chainlink_lot", "fence_chainlink_lot_post", Vector2(569.0, -1510.0), Vector2(569.0, -1492.4), yf, 2.0)
	H.fence(props, "fence_chainlink_lot", "fence_chainlink_lot_post", Vector2(605.0, -1510.0), Vector2(605.0, -1492.4), yf, 2.0)
	H.fence(props, "fence_chainlink_lot", "fence_chainlink_lot_post", Vector2(569.0, -1510.0), Vector2(581.1, -1510.0), yf, 2.0)
	H.fence(props, "fence_chainlink_lot", "fence_chainlink_lot_post", Vector2(586.9, -1510.0), Vector2(605.0, -1510.0), yf, 2.0)
	P.call("fence_gate_rolling_chainlink", "worn", 584.0, -1510.0, 0.0)
	P.call("prop_tank_vertical", "worn", 576.0, -1503.5)
	P.call("prop_tank_horizontal_propane", "worn", 600.0, -1503.0, 90.0)
	P.call("prop_transformer_substation", "worn", 588.0, -1503.5, 0.0)
	for x: float in [576.0, 578.0, 580.0, 596.0, 598.0, 600.0]: P.call("prop_ac_condenser", "worn", x, -1494.4, 180.0)
	# ---- the car park: wheel stops at every stall's head, lot lights in the double rows' middles, a pay station by the
	#      walk, trees in grass islands at the rows' east ends, oil in a few stalls
	for r: Array in ROWS:
		var head := float(r[2]) + 0.6 if absf(float(r[2]) - (-1524.5)) < 0.1 or absf(float(r[2]) - (-1542.5)) < 0.1 or absf(float(r[2]) - (-1560.5)) < 0.1 or absf(float(r[2]) - (-1578.5)) < 0.1 else float(r[3]) - 0.6
		var x := float(r[0]) + 1.35; var k := 0
		while x < float(r[1]):
			P.call("prop_wheel_stop_concrete", "worn", x, head, 0.0)
			if k % 4 == 1: W.oil(dec, rr, Vector2(x, (float(r[2]) + float(r[3])) * 0.5), 0.0, yf, 0.5)
			x += 2.7; k += 1
	for x: float in [534.5, 561.5, 588.5]: P.call("prop_lot_light_pole", "worn", x, -1524.5, 0.0)
	for x: float in [534.5, 553.4]: P.call("prop_lot_light_pole", "worn", x, -1560.5, 0.0)
	P.call("prop_pay_station", "worn", 563.3, -1511.4, 180.0)
	P.call("prop_trash_receptacle", "worn", 558.8, -1511.4)
	W.lane_wear(dec, rr, -1515.5, 521.0, 612.0, false, yf)
	W.lane_wear(dec, rr, -1457.0, 512.0, 610.0, false, yf)
	# a hedge along Adela in front of the car park (cars' lights off the street), gaps at the walks
	H.hedge(props, Vector2(513.0, -1578.0), Vector2(513.0, -1520.0), yf, "hedge_privet_2m")
