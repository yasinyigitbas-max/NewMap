extends SceneTree
## Piece n_fn_west (the north end, block 1): CROWN LANE AND THE BAY ROW. u -190.8 (the u -200 street's east walk) ..
## -16 (Amber's west walk), v -1585.7 (1st St's south walk) .. -1414.3 (3rd St's north walk). Placed at grid
## [0, 2.0, 0], yaw 0. Run once.
##
## WHY (planner): the foot of Crown Hill's north slope, between the quiet u -200 street and Amber, the spine. The land
## rises from the bay (2.15) to 4.15 at the SW corner and 8.15 at Amber x 3rd.
##  - THE BAY ROW on 1st St: four apartment buildings (garden apartments, a white court, a Spanish revival) facing the
##    water across their lawns, their gardens behind.
##  - the only car opening is the u -200 street's east apron (v -1461 .. -1453): CROWN LANE runs east from it up the
##    slope to a turnaround at u -55; townhouses with garages on the lane both sides (south row backs onto 3rd St,
##    gardens between); a connector north from the lane to the bay row's car park.
##  - AMBER x 3rd (the hilltop corner, 8 m up, the bay in view): a two-shop corner building facing 3rd St: a DELI for
##    the people waiting at the bus stops of the arterial and a FLORIST.
##  - AMBER GREEN (the NE corner at Amber x 1st): a pocket lawn with benches looking at the bay, where the walk down
##    Amber meets the water, opposite Amber Corner's cafe.
## LAND: the ground follows the land (n_fn_site.g); every building on a level pad at the highest ground under it, the
## field graded up to the pads at 6 %.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fn_site.gd")

const X0 := -190.8
const X1 := -16.0
const Z0 := -1585.7
const Z1 := -1414.3
const LANE := [-1461.0, -1453.0]
const CONN := [-134.0, -127.0]
## [label, folder, centre u, centre v, yaw, steps to the door (u of the door, or 0: none)]
const B := [
	["bay_1", "apartments/apt_garden_cream", -165.0, -1569.9, 180.0, 0.0],    # fronts to the bay at v -1576
	["bay_2", "apartments/apt_court_white", -135.0, -1569.9, 180.0, 0.0],
	["bay_3", "apartments/apt_spanish_white", -110.0, -1569.5, 180.0, -110.0],
	["bay_4", "apartments/apt_garden_mint", -82.0, -1569.9, 180.0, 0.0],
	["deli", "commercial/com_orange_corner", -30.0, -1427.67, 0.0, 0.0],     # front on 3rd St at v -1419.5
	["th_s1", "apartments/apt_townhouse_cays", -170.0, -1443.6, 180.0, 0.0],
	["th_s2", "apartments/apt_townhouse_modern", -146.0, -1443.6, 180.0, 0.0],
	["th_s3", "apartments/apt_townhouse_cays", -122.0, -1443.6, 180.0, 0.0],
	["th_s4", "apartments/apt_townhouse_modern", -98.0, -1443.6, 180.0, 0.0],
	["th_s5", "apartments/apt_townhouse_cays", -74.0, -1443.6, 180.0, 0.0],
	["th_n1", "apartments/apt_townhouse_modern", -172.0, -1470.4, 0.0, 0.0],
	["th_n2", "apartments/apt_townhouse_cays", -148.0, -1470.4, 0.0, 0.0],
	["th_n3", "apartments/apt_townhouse_modern", -114.0, -1470.4, 0.0, 0.0],
	["th_n4", "apartments/apt_townhouse_cays", -90.0, -1470.4, 0.0, 0.0],
	["th_n5", "apartments/apt_townhouse_modern", -66.0, -1470.4, 0.0, 0.0],
]
const REGIONS := [
	[-180.0, -1527.5, -60.0, -1509.5, "asphalt"],     # the bay row's car park (two rows round one aisle)
]

const ITEMS := [
	# ---- Amber Green: benches looking at the bay, a lamp, a fountain on its walk, planting
	["prop_park_bench", "worn", -44.0, -1583.0, 180.0], ["prop_park_bench", "worn", -34.0, -1583.0, 180.0],
	["prop_park_bench", "worn", -24.0, -1583.0, 180.0],
	["prop_lamp_victorian", "worn", -50.0, -1584.8, 0.0], ["prop_lamp_victorian", "worn", -18.0, -1584.8, 0.0],
	["prop_drinking_fountain", "worn", -40.0, -1562.0, 0.0],
	["prop_picnic_table", "worn", -30.0, -1556.0, 0.0], ["prop_picnic_table", "worn", -48.0, -1550.0, 90.0],
	["plant_bougainvillea_mound", "normal", -58.0, -1544.0, 0.0], ["plant_bird_of_paradise", "normal", -22.0, -1545.0, 0.0],
	["prop_sprinkler_impact", "normal", -36.0, -1570.0, 0.0, false],
	# ---- the bay row's lawns: chairs facing the water, mailboxes at the walk, low planting
	["prop_adirondack_white", "worn", -152.0, -1581.0, 180.0], ["prop_adirondack_wood", "worn", -122.5, -1581.0, 180.0],
	["prop_adirondack_white", "worn", -96.5, -1581.0, 180.0], ["prop_adirondack_wood", "worn", -95.0, -1581.0, 180.0],
	["prop_mailbox_post_metal", "worn", -168.0, -1583.2, 180.0], ["prop_mailbox_post_metal", "worn", -138.0, -1583.2, 180.0],
	["prop_mailbox_post_metal", "worn", -106.0, -1583.2, 180.0], ["prop_mailbox_post_metal", "worn", -85.0, -1583.2, 180.0],
	["plant_iceplant_patch", "normal", -185.0, -1580.5, 0.0, false], ["plant_iceplant_patch", "normal", -66.0, -1580.5, 0.0, false],
	# ---- their back gardens: tables, a barbecue, a washing line, chairs
	["prop_picnic_table", "worn", -165.0, -1550.0, 0.0], ["prop_bbq_kettle", "worn", -160.0, -1548.0, 0.0],
	["prop_clothesline", "worn", -135.0, -1550.0, 0.0], ["prop_picnic_table", "worn", -110.0, -1550.0, 0.0],
	["prop_adirondack_wood", "worn", -84.0, -1551.0, 0.0], ["prop_adirondack_white", "worn", -81.5, -1551.0, 0.0],
	# ---- the townhouses' gardens
	["prop_patio_set_4", "worn", -172.0, -1484.0, 0.0], ["prop_bbq_kettle", "worn", -148.0, -1483.0, 0.0],
	["prop_patio_set_4", "worn", -90.0, -1484.0, 0.0], ["prop_adirondack_wood", "worn", -66.0, -1483.0, 0.0],
	["prop_patio_set_4", "worn", -146.0, -1431.0, 0.0], ["prop_bbq_gas_cart", "worn", -98.0, -1432.0, 0.0],
	["prop_adirondack_white", "worn", -170.0, -1431.0, 0.0], ["prop_patio_set_4", "worn", -74.0, -1431.0, 0.0],
	["plant_agave_americana", "normal", -184.0, -1424.0, 0.0], ["plant_bougainvillea_mound", "normal", -122.0, -1424.0, 0.0],
	# ---- the deli's forecourt on 3rd St: its tables, a bench and racks for the bus riders, a paper box, a lamp; the
	#      florist's potted plants by its door
	["prop_patio_set_4", "worn", -38.0, -1416.6, 0.0], ["prop_park_bench", "worn", -20.0, -1415.4, 0.0],
	["prop_newspaper_box_red", "worn", -34.0, -1418.8, 0.0], ["prop_bike_rack", "worn", -45.0, -1418.0, 90.0],
	["prop_lamp_victorian", "worn", -42.0, -1415.0, 0.0],
	["plant_potted_leafy", "normal", -25.4, -1418.8, 0.0], ["plant_potted_succulent", "normal", -26.4, -1418.6, 0.0],
]

var PY: Array = []

## SUPERCHECKER (20 Nov; the coordinator, Yasin's word: "be MUCH more prone to delete: any prop or road/ground mark with
## any finding or any doubt is deleted with its reason, no relocating attempts"): tools/city/super/sc.py check on this
## piece (area layout OUT/fill/fn/area.json). Every prop with a finding is taken out (its reason on its line); a
## collision box on each building column the checker measured without one. Every oil mark and lane-wear stripe was
## also taken out of the script itself (the checker found oil on the drive's centre line with no car near it).
const SC := {
 "out": [
	["prop_trash_cart_black", -158.600, -1452.400, "bin_open: prop_trash_cart_black stands in the open (4.2 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -135.000, -1452.400, "bin_open: prop_trash_cart_black stands in the open (4.3 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -110.600, -1452.400, "bin_open: prop_trash_cart_black stands in the open (4.2 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -86.600, -1452.400, "bin_open: prop_trash_cart_black stands in the open (4.5 m from a wall, 99.0 m from a fence)"],
	["prop_park_bench", -44.000, -1583.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -34.000, -1583.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -24.000, -1583.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -30.000, -1556.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -48.000, -1550.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -165.000, -1550.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -110.000, -1550.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_bbq_kettle", -160.000, -1548.000, "no_reason: prop_bbq_kettle stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_patio_set_4", -172.000, -1484.000, "no_reason: prop_patio_set_4 stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_patio_set_4", -90.000, -1484.000, "no_reason: prop_patio_set_4 stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
 ],
 "boxes": [
	["Buildings/bay_1", [-11.8703, 1.5500, 5.8649, 0.2999, 3.1000, 0.3102]],
	["Buildings/bay_1", [-3.6002, 1.6999, 5.6249, 0.2598, 2.8000, 0.2899]],
	["Buildings/bay_2", [9.4698, 1.5500, 5.8649, 0.3002, 3.1000, 0.3102]],
	["Buildings/bay_4", [-11.8702, 1.5500, 5.8649, 0.3000, 3.0999, 0.3102]],
	["Buildings/bay_4", [-3.6002, 1.6999, 5.6249, 0.2598, 2.8000, 0.2899]],
	["Buildings/deli", [2.1049, 1.5000, 6.7748, 0.4900, 3.0000, 0.4901]],
	["Buildings/deli", [3.9450, 1.5000, 6.8800, 0.1600, 3.0000, 0.1600]],
	["Buildings/deli", [-1.8801, 1.5000, 6.7748, 0.1600, 3.0000, 0.4901]],
	["Buildings/th_s1", [-0.7502, 1.3000, -5.3601, 0.9398, 2.5999, 0.7600]],
	["Buildings/th_s1", [-0.0102, 1.5400, 4.4300, 0.3600, 3.0800, 0.2601]],
	["Buildings/th_s1", [2.7748, 1.5400, 4.3599, 0.1600, 3.0800, 0.1600]],
	["Buildings/th_s1", [-3.6002, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_s1", [9.1999, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_s2", [-5.4975, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_s2", [-0.2102, 1.5400, 4.1609, 0.3598, 3.0799, 0.1600]],
	["Buildings/th_s2", [6.5022, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_s3", [-0.7502, 1.3000, -5.3601, 0.9398, 2.5999, 0.7600]],
	["Buildings/th_s3", [-0.0102, 1.5400, 4.4300, 0.3600, 3.0800, 0.2601]],
	["Buildings/th_s3", [2.7748, 1.5400, 4.3599, 0.1600, 3.0800, 0.1600]],
	["Buildings/th_s3", [-3.6002, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_s3", [9.1999, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_s4", [-5.4975, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_s4", [-0.2102, 1.5400, 4.1609, 0.3598, 3.0799, 0.1600]],
	["Buildings/th_s4", [6.5022, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_s5", [-0.7502, 1.3000, -5.3601, 0.9398, 2.5999, 0.7600]],
	["Buildings/th_s5", [-0.0102, 1.5400, 4.4300, 0.3600, 3.0800, 0.2601]],
	["Buildings/th_s5", [2.7748, 1.5400, 4.3599, 0.1600, 3.0800, 0.1600]],
	["Buildings/th_s5", [-3.6002, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_s5", [9.1999, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_n1", [-5.4975, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_n1", [-0.2102, 1.5400, 4.1609, 0.3598, 3.0799, 0.1600]],
	["Buildings/th_n1", [6.5022, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_n2", [-0.7502, 1.3000, -5.3601, 0.9398, 2.5999, 0.7600]],
	["Buildings/th_n2", [-0.0102, 1.5400, 4.4300, 0.3600, 3.0800, 0.2601]],
	["Buildings/th_n2", [2.7748, 1.5400, 4.3599, 0.1600, 3.0800, 0.1600]],
	["Buildings/th_n2", [-3.6002, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_n2", [9.1999, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_n3", [-5.4975, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_n3", [-0.2102, 1.5400, 4.1609, 0.3598, 3.0799, 0.1600]],
	["Buildings/th_n3", [6.5022, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_n4", [-0.7502, 1.3000, -5.3601, 0.9398, 2.5999, 0.7600]],
	["Buildings/th_n4", [-0.0102, 1.5400, 4.4300, 0.3600, 3.0800, 0.2601]],
	["Buildings/th_n4", [2.7748, 1.5400, 4.3599, 0.1600, 3.0800, 0.1600]],
	["Buildings/th_n4", [-3.6002, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_n4", [9.1999, 1.5000, 4.9600, 0.2400, 3.0000, 0.1600]],
	["Buildings/th_n5", [-5.4975, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_n5", [-0.2102, 1.5400, 4.1609, 0.3598, 3.0799, 0.1600]],
	["Buildings/th_n5", [6.5022, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
 ],
}

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array:
	var st := K.building_stats(f)
	if st.has("near"): return (st.near as Dictionary).bbox
	var wd: Array = st.footprint_wd
	return [[-float(wd[0]) * 0.5, 0.0, -float(wd[1]) * 0.5], [float(wd[0]) * 0.5, float(st.get("height", 6.0)), float(wd[1]) * 0.5]]
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(absf(yaw) - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]

func _run() -> void:
	var root := Node3D.new(); root.name = "n_fn_west"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fn_west")
	var yb := func(x: float, z: float) -> float: return S.y(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var yg := H.graded(yb, pe)
	# the grading up to the pads is eased back onto the plain ground within 4 m of the block's edges, so every edge
	# keeps its street walk's height (a pad near a walk otherwise lifts the edge: 8.5 cm at Amber, first build)
	var yf := func(x: float, z: float) -> float:
		var d := minf(minf(x - X0, X1 - x), minf(z - Z0, Z1 - z))
		return lerpf(float(yb.call(x, z)), float(yg.call(x, z)), smoothstep(0.0, 4.0, d))
	var paints: Array = []
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	# stall lines of the bay row's car park (u -180 .. -60, both sides of the aisle v -1522 .. -1515)
	for k in 45:
		var x := -180.0 + 2.7 * k
		if x > CONN[0] - 0.5 and x < CONN[1] + 0.5: continue
		paints.append([x - 0.05, -1527.5, x + 0.05, -1522.0, "white"]); paints.append([x - 0.05, -1515.0, x + 0.05, -1509.5, "white"])
	paints.append([-188.0, -1457.08, -60.0, -1456.92, "yellow"])         # the lane's centre line
	paints.append([-188.4, -1461.0, -188.0, -1457.08, "white"])          # stop bar at the apron (outbound side)
	paints.append_array([
		[-190.8, -1462.0, -188.0, -1461.0, "concrete"], [-190.8, -1453.0, -188.0, -1452.0, "concrete"],   # flare
		[-190.8, LANE[0], -60.0, LANE[1], "asphalt"],                   # CROWN LANE
		[-62.0, -1465.0, -50.0, -1449.0, "asphalt"],                    # its turnaround
		[CONN[0], -1509.5, CONN[1], LANE[0], "asphalt"],                # the connector up to the car park
		[CONN[0], -1527.5, CONN[1], -1509.5, "asphalt"],
		[-180.0, -1527.5, -60.0, -1509.5, "asphalt"],                   # the car park (region)
		[-190.8, -1585.7, -16.0, -1583.7, "plaza"],                     # the 1st St front walk
		[-60.0, -1583.7, -16.0, -1580.0, "plaza"],                      # Amber Green's bay terrace
		[-42.0, -1580.0, -38.0, -1540.0, "plaza"],                      # ... its walk up to the lane's end
		[-42.0, -1540.0, -38.0, -1465.0, "plaza"],
		[-62.0, -1438.0, -16.0, -1434.0, "plaza"],                      # the walk from the turnaround to Amber and the deli
		[-50.0, -1434.0, -46.0, -1414.3, "plaza"],
		[-44.0, -1419.5, -16.0, -1414.3, "plaza"],                      # the deli's forecourt
		[-111.0, -1583.7, -109.0, -1576.0, "plaza"],                    # the Spanish revival's lobby path
		[-166.0, -1583.7, -164.0, -1576.0, "plaza"], [-136.0, -1583.7, -134.0, -1576.0, "plaza"],
		[-83.0, -1583.7, -81.0, -1576.0, "plaza"],
		[-178.0, -1561.0, -70.0, -1559.0, "plaza"],                     # the back walk behind the bay row
		[CONN[1], -1559.0, CONN[1] + 2.0, -1527.5, "plaza"],             # ... down to the car park
	])
	for b: Array in B:
		if not String(b[0]).begins_with("th_"): continue
		var f := fp(b)
		if float(b[4]) > 90.0: paints.append([f[0], LANE[1], f[2], f[1], "concrete"])
		else: paints.append([f[0], f[3], f[2], LANE[0], "concrete"])
	var main: Array = []
	for r: Array in REGIONS: main.append([r[0], r[1], r[2], r[3], "-"])
	var subs: Array = []
	for r: Array in REGIONS: subs.append([])
	for p: Array in paints:
		var put := false
		for i in REGIONS.size():
			var r: Array = REGIONS[i]
			if float(p[0]) >= float(r[0]) - 0.01 and float(p[2]) <= float(r[2]) + 0.01 and float(p[1]) >= float(r[1]) - 0.01 and float(p[3]) <= float(r[3]) + 0.01:
				subs[i].append(p); put = true; break
		if not put: main.append(p)
	for i in REGIONS.size():
		var r: Array = REGIONS[i]
		H.paint(g, r[0], r[1], r[2], r[3], subs[i], String(r[4]), yf)
	H.paint(g, X0, Z0, X1, Z1, main, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	# the condos' lobby doors stand 0.3 m over their pads (and the pads over the lawn): closed steps up from the lawn
	for i in B.size():
		var b: Array = B[i]
		if float(b[5]) == 0.0: continue
		var f := fp(b); var gy: float = yf.call(float(b[5]), f[1] - 3.0); var top := float(PY[i]) + 0.3
		H.steps_z2(g, float(b[5]), 2.0, f[1] - ceilf((top - gy) / 0.17) * H.TREAD, f[1], gy, top, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fn_west")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the lane: stop sign at the apron, lamps on the verges between the houses (arm over the lane), the
	#      townhouses' bins at their garage corners, the bay row's dumpster at the car park's connector head
	P.call("prop_sign_stop", "worn", -188.4, -1462.4, 90.0)
	for x: float in [-158.0, -110.0, -86.0]: P.call("prop_lamp_cobra", "worn", x, -1451.4, 180.0)
	for x: float in [-160.0, -102.0, -78.0]: P.call("prop_lamp_cobra", "worn", x, -1462.6, 0.0)
	for x: float in [-158.6, -135.0, -110.6, -86.6]: P.call("prop_trash_cart_black", "worn", x, -1452.4, 180.0)
	P.call("prop_dumpster_3yd_green", "worn", -130.5, -1529.0, 0.0)
	P.call("prop_lot_light_pole", "worn", -150.0, -1508.5, 0.0)
	P.call("prop_lot_light_pole", "worn", -90.0, -1508.5, 0.0)
	for k in 44:
		var x := -178.65 + 2.7 * k
		if x > CONN[0] - 1.4 and x < CONN[1] + 1.4: continue
		P.call("prop_wheel_stop_concrete", "worn", x, -1526.9, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", x, -1510.1, 0.0)
	for b: Array in B:
		if not String(b[0]).begins_with("th_"): continue
		var f := fp(b)
		var mz := (float(f[1]) + float(f[3])) * 0.5
		P.call("prop_ac_condenser", "worn", float(f[0]) - 0.8, mz, 90.0)
	# ---- the deli: its dumpster and condenser behind it, on the walk's side
	P.call("prop_dumpster_3yd_blue", "worn", -40.0, -1437.0, 90.0)
