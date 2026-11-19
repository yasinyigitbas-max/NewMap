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
	
	["prop_park_bench", "worn", 424.0, -1556.0, 0.0], ["prop_park_bench", "worn", 446.0, -1556.0, 0.0],
	["prop_park_bench", "worn", 424.0, -1530.0, 180.0], ["prop_park_bench", "worn", 446.0, -1530.0, 180.0],
	["prop_shade_sail", "normal", 435.0, -1543.0, 0.0, false],
	["prop_picnic_table", "worn", 432.0, -1543.0, 90.0], ["prop_picnic_table", "worn", 438.5, -1543.0, 90.0],
	["prop_garden_arbor", "normal", 410.0, -1543.0, 90.0],
	["plant_bird_of_paradise", "normal", 420.0, -1537.0, 0.0], ["plant_bougainvillea_mound", "normal", 450.0, -1537.0, 0.0],
	["plant_agave_americana", "normal", 460.0, -1548.0, 0.0],
	["prop_sprinkler_impact", "normal", 415.0, -1530.0, 0.0, false], ["prop_sprinkler_impact", "normal", 455.0, -1560.0, 0.0, false],
	# 1st St front gardens: low planting between the doors' paths, palms at the ends
	
	["plant_iceplant_patch", "normal", 428.0, -1581.5, 0.0, false], ["plant_iceplant_patch", "normal", 466.0, -1581.5, 0.0, false],
	# Adela side: trees in the grass strip
	
	# 3rd St forecourt: trees in wells
]

var PY: Array = []     # pad heights (local), one per row of B

## POLISH (19 Nov, Yasin: "run a polish pass on the whole zone, plenty of relevant props, lots of life"): trees on open
## lawn away from the buildings, shrubs and sprinklers nearer them, benches / picnic tables / garden chairs where people
## sit (gardens, courts, lawns), benches, planters, bins, racks, fountains and paper boxes on the wide paving; each on a
## free spot this piece already had (found by a scratch tool, OUT/py/freespots_hp.py, chosen per kind of place, frozen
## here), standing on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["plant_bird_of_paradise", "normal", 406.2, -1580.4, 61.0],
	["prop_park_bench", "worn", 407.2, -1585.4, -90.0],
	["plant_potted_leafy", "normal", 414.2, -1585.4, 0.0],
	["prop_trash_receptacle", "worn", 434.8, -1585.4, 0.0],
	["prop_park_bench", "worn", 447.8, -1585.4, -90.0],
	["prop_park_bench", "worn", 458.8, -1585.4, -180.0],
	["plant_potted_succulent", "normal", 473.2, -1585.4, 0.0],
	["prop_drinking_fountain", "worn", 482.8, -1585.4, 90.0],
	["prop_newspaper_box_blue", "worn", 490.2, -1585.4, 90.0],
	["prop_picnic_table", "worn", 407.8, -1565.9, -88.5],
	["prop_park_bench", "worn", 414.8, -1552.4, -34.1],
	["prop_adirondack_wood", "worn", 421.8, -1561.9, -16.8],
	["prop_adirondack_white", "worn", 433.2, -1552.4, 44.9],
	["prop_park_bench", "worn", 443.8, -1552.9, 9.7],
	["prop_picnic_table", "worn", 453.2, -1561.9, -67.0],
	["prop_park_bench", "worn", 461.2, -1561.9, -25.6],
	["plant_bougainvillea_mound", "normal", 468.8, -1556.9, 183.0],
	
	
	["prop_adirondack_wood", "worn", 413.8, -1531.4, -4.3],
	["prop_adirondack_white", "worn", 415.2, -1545.4, 4.2],
	["prop_park_bench", "worn", 422.2, -1544.4, -41.9],
	["prop_picnic_table", "worn", 428.8, -1546.9, -13.2],
	["prop_park_bench", "worn", 434.2, -1541.9, 11.7],
	["prop_adirondack_wood", "worn", 438.8, -1547.9, 39.2],
	["prop_adirondack_white", "worn", 443.8, -1542.9, 58.6],
	["prop_park_bench", "worn", 448.8, -1547.9, -65.6],
	["prop_picnic_table", "worn", 454.8, -1533.9, -102.0],
	["prop_sprinkler_impact", "normal", 490.2, -1544.4, 244.0, false],
	
	["prop_park_bench", "worn", 414.2, -1519.9, -14.9],
	["prop_adirondack_wood", "worn", 426.8, -1524.4, 13.6],
	["prop_adirondack_white", "worn", 432.2, -1519.9, -41.0],
	["prop_park_bench", "worn", 437.8, -1515.4, -177.7],
	["prop_picnic_table", "worn", 450.8, -1518.9, -72.5],
	
	["prop_recycling_receptacle", "worn", 490.2, -1521.9, 0.0],
	
	["prop_park_bench", "worn", 481.2, -1491.9, 90.0],
	
	["plant_agave_americana_small", "normal", 413.8, -1489.9, 305.0],
	
	
	["plant_bird_of_paradise", "normal", 437.8, -1481.9, 6.0],
	["plant_potted_leafy", "normal", 481.8, -1481.4, 0.0],
	
	["plant_agave_americana", "normal", 401.2, -1450.9, 67.0],
	
	["prop_sprinkler_impact", "normal", 449.8, -1450.4, 128.0, false],
	["plant_iceplant_patch", "normal", 480.8, -1450.4, 189.0, false],
	["prop_trash_receptacle", "worn", 485.8, -1451.9, 0.0],
	["plant_agave_americana_small", "normal", 417.8, -1440.4, 250.0],
	["plant_bird_of_paradise", "normal", 424.8, -1442.4, 311.0],
	["prop_sprinkler_impact", "normal", 437.2, -1442.9, 12.0, false],
	["plant_bougainvillea_mound", "normal", 472.8, -1449.4, 73.0],
]

## SUPERCHECKER (19 Nov, Yasin: "use super checker in your entire zone and weed out the unnecessary parts ... be very
## prone to delete"): tools/city/super/sc.py check on this piece; every finding with no plainly safe place is a
## deletion (its reason on its line), lamps turned back over their road, oil where no car stands out, a collision
## box on each building column with none. Applied after everything is placed (hs_fill_lib.sc_apply).
const SC := {
 "out": [
	["prop_picnic_table", 432.0, -1543.0, "no_reason (second check): prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_trash_receptacle", 489.60001, -1436.5, "bin_open: prop_trash_receptacle stands in the open (8.6 m from a wall, 99.0 m from a fence)"],
	["prop_trash_receptacle", 444.0, -1415.30005, "bin_open: prop_trash_receptacle stands in the open (11.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_receptacle", 481.60001, -1494.0, "bin_open: prop_trash_receptacle stands in the open (3.6 m from a wall, 99.0 m from a fence)"],
	["prop_trash_receptacle", 434.79999, -1585.40002, "bin_open: prop_trash_receptacle stands in the open (9.0 m from a wall, 99.0 m from a fence)"],
	["prop_trash_receptacle", 485.79999, -1451.90002, "bin_open: prop_trash_receptacle stands in the open (9.2 m from a wall, 99.0 m from a fence)"],
	["prop_recycling_receptacle", 404.79999, -1516.19995, "bin_open: prop_recycling_receptacle stands in the open (42.7 m from a wall, 99.0 m from a fence)"],
	["prop_recycling_receptacle", 490.20001, -1521.90002, "bin_open: prop_recycling_receptacle stands in the open (7.2 m from a wall, 99.0 m from a fence)"],
	["prop_park_bench", 489.60001, -1517.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 424.0, -1556.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 424.0, -1530.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 446.0, -1530.0, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 407.20001, -1585.40002, "over_edge: prop_park_bench hangs over the edge of its block (2 of its 4 corners)"],
	["prop_park_bench", 447.79999, -1585.40002, "over_edge: prop_park_bench hangs over the edge of its block (2 of its 4 corners)"],
	["prop_park_bench", 458.79999, -1585.40002, "over_edge: prop_park_bench hangs over the edge of its block (2 of its 4 corners)"],
	["prop_park_bench", 414.79999, -1552.40002, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 422.20001, -1544.40002, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 448.79999, -1547.90002, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 414.20001, -1519.90002, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 437.79999, -1515.40002, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["plant_potted_leafy", 414.20001, -1585.40002, "over_edge: plant_potted_leafy hangs over the edge of its block (2 of its 4 corners)"],
	["prop_picnic_table", 428.79999, -1546.90002, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", 454.79999, -1533.90002, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_picnic_table", 450.79999, -1518.90002, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit wi"],
	["prop_garden_arbor", 410.0, -1543.0, "on_path: prop_garden_arbor stands in a narrow path"],
	["plant_agave_americana", 401.20001, -1450.90002, "over_edge: plant_agave_americana hangs over the edge of its block (1 of its 4 corners)"],
	["prop_drinking_fountain", 482.79999, -1585.40002, "over_edge: prop_drinking_fountain hangs over the edge of its block (2 of its 4 corners)"],
	["prop_adirondack_wood", 413.79999, -1531.40002, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_wood", 426.79999, -1524.40002, "no_reason: prop_adirondack_wood stands alone: no door within 18 m, no wall within 8 m, nothing to sit"],
	["prop_adirondack_white", 433.20001, -1552.40002, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", 415.20001, -1545.40002, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", 443.79999, -1542.90002, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_adirondack_white", 432.20001, -1519.90002, "no_reason: prop_adirondack_white stands alone: no door within 18 m, no wall within 8 m, nothing to si"],
	["prop_park_bench", 434.20001, -1541.90002, "stray_bench: a bench stands beside a picnic table (the table has its own seats)"],
	["prop_shade_sail", 435.0, -1543.0, "sail_over_nothing: a shade sail with no table, seat or play item under it"],
 ],
 "turn": [
	["prop_lamp_cobra", 415.0, -1463.0, 180.0],
	["prop_lamp_cobra", 438.0, -1463.0, 180.0],
	["prop_lamp_cobra", 482.0, -1463.0, 180.0],
 ],
 "decals": [
	[450.229, -1457.0],
	[457.289, -1457.0],
	[465.494, -1457.0],
	[473.917, -1457.0],
	[480.397, -1457.0],
 ],
 "boxes": [
	["Buildings/pharmacy", [-3.9000229835510254, 1.499967098236084, 5.650000095367432, 0.16, 2.999934196472168, 0.16]],
	["Buildings/pharmacy", [-1.0400550365447998, 1.514954686164856, 7.659996747970581, 0.20003656387329102, 3.029909372329712, 0.19999937057495118]],
	["Buildings/pharmacy", [-4.960036516189575, 1.514954686164856, 7.659996747970581, 0.20003656387329102, 3.029909372329712, 0.19999937057495118]],
	["Buildings/pharmacy", [-2.1000688076019287, 1.499967098236084, 5.650000095367432, 0.16, 2.999934196472168, 0.16]],
	["Buildings/bistro", [3.7349672317504883, 1.4999818801879883, 6.7748332023620605, 0.48997978210449217, 2.9999637603759766, 0.49008373260498045]],
	["Buildings/bistro", [1.695887565612793, 1.4999818801879883, 6.8799638748168945, 0.16, 2.9999637603759766, 0.16]],
	["Buildings/care_w", [-11.870302200317383, 1.5499759912490845, 5.8649115562438965, 0.2999201202392578, 3.099951982498169, 0.31015304565429686]],
	["Buildings/care_w", [-3.60017728805542, 1.6999465376138687, 5.624899864196777, 0.25976757049560545, 2.8000108897686005, 0.289943733215332]],
	["Buildings/care_e", [-11.870302200317383, 1.5499759912490845, 5.8649115562438965, 0.2999201202392578, 3.099951982498169, 0.31015304565429686]],
	["Buildings/care_e", [-3.60017728805542, 1.6999465376138687, 5.624899864196777, 0.25976757049560545, 2.8000108897686005, 0.289943733215332]],
	["Buildings/wellness", [0.839634895324707, 1.6999541819095612, 6.701925754547119, 0.16054443359375, 2.800045669078827, 0.16]],
 ],
}

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
	if PASS >= 2: H.polish(props, g, POLISH)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
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
	P.call("plant_potted_leafy", "normal", 485.0, -1435.0, 0.0)
	P.call("plant_potted_leafy", "normal", 485.0, -1429.0, 0.0)
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
	P.call("plant_potted_succulent", "normal", 417.2, -1418.6, 0.0)
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
	P.call("plant_potted_leafy", "normal", 488.0, -1531.0, 0.0)
	P.call("plant_potted_leafy", "normal", 488.0, -1539.0, 0.0)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", 446.5 + 0.6 * k, -1583.2, 180.0)
	# ---- the residences: condensers on the ends, a bench at each front door path, lamps on the front walk
	for cu: float in [428.0, 466.0]:
		P.call("prop_ac_condenser", "worn", cu - 13.0, -1569.0, 90.0)
		P.call("prop_ac_condenser", "worn", cu + 13.6, -1569.0, -90.0)
		P.call("prop_lamp_globe", "worn", cu - 3.6, -1583.2)
		P.call("prop_lamp_globe", "worn", cu + 3.6, -1583.2)
	W.lane_wear(dec, rr, -1457.0, 447.0, 488.0, false, yf)
	W.lane_wear(dec, rr, -1503.0, 411.0, 440.0, false, yf)
