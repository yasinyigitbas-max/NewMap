extends SceneTree
## Piece n_fn_mid (the north end, block 2): AMBER CORNER, THE BAYFRONT CONDOS AND AMBER STEPS PARK. u 16 (Amber's east
## walk) .. 240.8 (B Ave's west walk), v -1585.7 (1st St's south walk) .. -1414.3 (3rd St's north walk). Placed at grid
## [0, 2.0, 0], yaw 0. Run once.
##
## WHY (planner): Amber Ave is the island's spine; it comes down Crown Hill from 3rd St (8.15) to the bay at 1st St
## (2.15). The block's high corner is Amber x 3rd, its low side the bay and B Ave.
##  - AMBER CORNER (Amber x 1st, the foot of the spine at the bay): THE CORNER CAFE (com_cafe_seaside) and an ICE CREAM
##    shop (com_surf_shop) facing the bay over a small plaza, their tables out: people walk down Amber to the water.
##  - AMBER STEPS PARK (u 16 - 58, the slope along Amber): a hillside park from 3rd St down to the cafe corner; its walk
##    goes down in straight runs, a playground on a level terrace cut into the slope, benches at the top looking at
##    the bay, picnic tables on the lower lawn. Where the people from the hill come down to the bay.
##  - BAYFRONT CONDOS on 1st St (three beach condos, three garden apartments), facing the water, lawns in front, their
##    gardens and the residents' car park behind.
##  - the only car opening is B Ave's west apron (v -1461 .. -1453): BAYVIEW LANE runs west from it up the slope to a
##    turnaround at u 58; townhouses with their garages on the lane on both sides (south row backs onto 3rd St with
##    gardens), and the condos' car park on a connector north from the lane.
## LAND: the ground follows the land (n_fn_site.g); 8.15 at Amber x 3rd falling to 2.15 at B Ave (up to 5 %); every
## building on a level pad at the highest ground under it, the field graded up to the pads at 6 %; the playground on
## its own level terrace with retaining faces.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fn_site.gd")

const X0 := 16.0
const X1 := 240.8
const Z0 := -1585.7
const Z1 := -1414.3
const LANE := [-1461.0, -1453.0]
const CONN := [140.0, 147.0]
## [label, folder, centre u, centre v, yaw, steps to the door (u of the door, or 0: none)]
const B := [
	["cafe", "commercial/com_cafe_seaside", 24.0, -1569.83, 180.0, 0.0],      # front on the corner plaza at v -1578
	["icecream", "commercial/com_surf_shop", 35.0, -1570.05, 180.0, 0.0],     # front at v -1578, door u 38.26
	["condo_a", "apartments/apt_beach_condo", 62.0, -1568.4, 180.0, 62.0],    # fronts to the bay at v -1576
	["garden_b", "apartments/apt_garden_mint", 90.0, -1569.9, 180.0, 0.0],
	["condo_c", "apartments/apt_beach_condo", 120.0, -1568.4, 180.0, 120.0],
	["garden_d", "apartments/apt_garden_cream", 150.0, -1569.9, 180.0, 0.0],
	["condo_e", "apartments/apt_beach_condo", 180.0, -1568.4, 180.0, 180.0],
	["garden_f", "apartments/apt_garden_mint", 212.0, -1569.9, 180.0, 0.0],
	# townhouses on Bayview Lane: south row fronts (garages) north at v -1450, north row fronts south at v -1464
	["th_s1", "apartments/apt_townhouse_cays", 72.0, -1443.6, 180.0, 0.0],
	["th_s2", "apartments/apt_townhouse_modern", 96.0, -1443.6, 180.0, 0.0],
	["th_s3", "apartments/apt_townhouse_cays", 120.0, -1443.6, 180.0, 0.0],
	["th_s4", "apartments/apt_townhouse_modern", 166.0, -1443.6, 180.0, 0.0],
	["th_s5", "apartments/apt_townhouse_cays", 190.0, -1443.6, 180.0, 0.0],
	["th_s6", "apartments/apt_townhouse_modern", 214.0, -1443.6, 180.0, 0.0],
	["th_n1", "apartments/apt_townhouse_modern", 96.0, -1470.4, 0.0, 0.0],
	["th_n2", "apartments/apt_townhouse_cays", 120.0, -1470.4, 0.0, 0.0],
	["th_n3", "apartments/apt_townhouse_modern", 166.0, -1470.4, 0.0, 0.0],
	["th_n4", "apartments/apt_townhouse_cays", 190.0, -1470.4, 0.0, 0.0],
	["th_n5", "apartments/apt_townhouse_modern", 214.0, -1470.4, 0.0, 0.0],
]
const REGIONS := [
	[100.0, -1545.5, 225.0, -1527.5, "asphalt"],     # the condos' car park (two rows round one aisle)
]
## the playground terrace in Amber Steps park (level, at the highest ground under it, retaining faces round it)
const PLAY := [24.0, -1508.0, 50.0, -1490.0]

const ITEMS := [
	# ---- the corner plaza: the cafe's and the ice cream shop's tables in the sun facing the bay, benches on the
	#      bay edge, a lamp at each end, racks for the cyclists on 1st St, a bin against the cafe's side wall
	["prop_patio_set_4", "worn", 21.0, -1581.0, 0.0], ["prop_patio_set_4", "worn", 28.0, -1581.5, 20.0],
	["prop_patio_set_4", "worn", 33.0, -1581.0, 0.0],
	["prop_park_bench", "worn", 42.0, -1584.9, 180.0],
	["prop_lamp_victorian", "worn", 17.0, -1584.8, 0.0], ["prop_lamp_victorian", "worn", 46.0, -1584.8, 0.0],
	["prop_bike_rack", "worn", 44.0, -1580.0, 90.0],
	["prop_trash_receptacle", "worn", 19.2, -1574.0, 0.0],
	["plant_potted_leafy", "normal", 29.2, -1578.6, 0.0],
	["prop_newspaper_box_red", "worn", 17.0, -1580.0, 90.0],
	# ---- Amber Steps park: benches at the top looking down to the bay, the playground on its terrace, benches for
	#      the parents facing it, picnic tables on the lower lawn, a fountain on the walk, planting at the walk's turns
	["prop_park_bench", "worn", 30.0, -1424.0, 180.0], ["prop_park_bench", "worn", 44.0, -1424.0, 180.0],
	["prop_play_structure", "worn", 31.0, -1499.0, 0.0], ["prop_swing_set", "worn", 42.0, -1503.0, 0.0],
	["prop_slide", "worn", 42.0, -1495.0, 90.0],
	["prop_park_bench", "worn", 30.0, -1487.6, 180.0], ["prop_park_bench", "worn", 40.0, -1487.6, 180.0],
	["prop_drinking_fountain", "worn", 52.6, -1486.0, 0.0],
	["prop_picnic_table", "worn", 30.0, -1545.0, 0.0], ["prop_picnic_table", "worn", 42.0, -1548.0, 0.0],
	["prop_park_bench", "worn", 46.0, -1528.0, -90.0],
	["plant_bougainvillea_mound", "normal", 25.0, -1462.0, 0.0], ["plant_agave_americana", "normal", 48.0, -1440.0, 0.0],
	["plant_bird_of_paradise", "normal", 22.0, -1530.0, 0.0],
	["prop_sprinkler_impact", "normal", 36.0, -1460.0, 0.0, false], ["prop_sprinkler_impact", "normal", 36.0, -1530.0, 0.0, false],
	["prop_lamp_globe", "worn", 51.5, -1430.0, 0.0], ["prop_lamp_globe", "worn", 51.5, -1470.0, 0.0],
	["prop_lamp_globe", "worn", 51.5, -1520.0, 0.0], ["prop_lamp_globe", "worn", 51.5, -1555.0, 0.0],
	# ---- the condos' bay lawns: chairs facing the water, low planting, the residents' mailboxes at the walk
	["prop_adirondack_white", "worn", 74.5, -1581.0, 180.0], ["prop_adirondack_white", "worn", 76.0, -1581.0, 180.0],
	["prop_adirondack_wood", "worn", 133.0, -1581.0, 180.0], ["prop_adirondack_wood", "worn", 192.5, -1581.0, 180.0],
	["prop_mailbox_post_metal", "worn", 66.0, -1583.2, 180.0], ["prop_mailbox_post_metal", "worn", 124.0, -1583.2, 180.0],
	["prop_mailbox_post_metal", "worn", 184.0, -1583.2, 180.0],
	["plant_iceplant_patch", "normal", 104.5, -1580.5, 0.0, false], ["plant_iceplant_patch", "normal", 165.5, -1580.5, 0.0, false],
	["plant_iceplant_patch", "normal", 228.0, -1580.5, 0.0, false],
	# ---- the condos' back gardens: picnic tables and a barbecue, washing line, chairs
	["prop_picnic_table", "worn", 75.0, -1553.0, 0.0], ["prop_bbq_kettle", "worn", 79.0, -1551.0, 0.0],
	["prop_picnic_table", "worn", 135.0, -1553.0, 0.0], ["prop_clothesline", "worn", 165.0, -1553.0, 0.0],
	["prop_picnic_table", "worn", 196.0, -1553.0, 0.0], ["prop_bbq_gas_cart", "worn", 200.0, -1550.6, 0.0],
	["prop_adirondack_wood", "worn", 226.0, -1554.0, 0.0], ["prop_adirondack_white", "worn", 228.0, -1554.0, 0.0],
	# ---- the townhouses' gardens (north row: between them and the car park; south row: toward 3rd St)
	["prop_patio_set_4", "worn", 96.0, -1482.0, 0.0], ["prop_bbq_kettle", "worn", 166.0, -1481.0, 0.0],
	["prop_patio_set_4", "worn", 214.0, -1482.0, 0.0], ["prop_adirondack_wood", "worn", 120.0, -1481.0, 0.0],
	["prop_patio_set_4", "worn", 72.0, -1431.0, 0.0], ["prop_bbq_gas_cart", "worn", 120.0, -1432.0, 0.0],
	["prop_patio_set_4", "worn", 166.0, -1431.0, 0.0], ["prop_adirondack_white", "worn", 214.0, -1432.0, 0.0],
	["plant_bougainvillea_mound", "normal", 150.0, -1424.0, 0.0], ["plant_agave_americana", "normal", 232.0, -1430.0, 0.0],
]

var PY: Array = []

## SUPERCHECKER (20 Nov; the coordinator, Yasin's word: "be MUCH more prone to delete: any prop or road/ground mark with
## any finding or any doubt is deleted with its reason, no relocating attempts"): tools/city/super/sc.py check on this
## piece (area layout OUT/fill/fn/area.json). Every prop with a finding is taken out (its reason on its line); a
## collision box on each building column the checker measured without one. Every oil mark and lane-wear stripe was
## also taken out of the script itself (the checker found oil on the drive's centre line with no car near it).
const SC := {
 "out": [
	["prop_trash_cart_black", 82.600, -1452.400, "bin_open: prop_trash_cart_black stands in the open (3.9 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", 106.000, -1452.400, "bin_open: prop_trash_cart_black stands in the open (3.9 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", 130.600, -1452.400, "bin_open: prop_trash_cart_black stands in the open (3.9 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", 176.600, -1452.400, "bin_open: prop_trash_cart_black stands in the open (4.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", 200.000, -1452.400, "bin_open: prop_trash_cart_black stands in the open (3.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", 224.600, -1452.400, "bin_open: prop_trash_cart_black stands in the open (4.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_receptacle", 19.200, -1574.000, "bin_open: prop_trash_receptacle stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_park_bench", 30.000, -1424.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 44.000, -1424.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 30.000, -1487.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 40.000, -1487.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 46.000, -1528.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_play_structure", 31.000, -1499.000, "no_reason: prop_play_structure stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_swing_set", 42.000, -1503.000, "no_reason: prop_swing_set stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_slide", 42.000, -1495.000, "no_reason: prop_slide stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 30.000, -1545.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 42.000, -1548.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 135.000, -1553.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
 ],
 "boxes": [
	["Buildings/cafe", [1.0249, 1.5000, 6.8800, 0.1600, 3.0000, 0.1600]],
	["Buildings/icecream", [2.0366, 1.5000, 6.8799, 0.1600, 3.0000, 0.1600]],
	["Buildings/garden_b", [-11.8702, 1.5500, 5.8649, 0.3000, 3.0999, 0.3102]],
	["Buildings/garden_b", [-3.6002, 1.6999, 5.6249, 0.2598, 2.8000, 0.2899]],
	["Buildings/garden_d", [-11.8703, 1.5500, 5.8649, 0.2999, 3.1000, 0.3102]],
	["Buildings/garden_d", [-3.6002, 1.6999, 5.6249, 0.2598, 2.8000, 0.2899]],
	["Buildings/garden_f", [-11.8702, 1.5500, 5.8649, 0.3000, 3.0999, 0.3102]],
	["Buildings/garden_f", [-3.6002, 1.6999, 5.6249, 0.2598, 2.8000, 0.2899]],
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
	["Buildings/th_s6", [-5.4975, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
	["Buildings/th_s6", [-0.2102, 1.5400, 4.1609, 0.3598, 3.0799, 0.1600]],
	["Buildings/th_s6", [6.5022, 1.5400, 4.9610, 0.9450, 3.0799, 0.1600]],
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
	var root := Node3D.new(); root.name = "n_fn_mid"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fn_mid")
	var yb := func(x: float, z: float) -> float: return S.y(x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	# the playground terrace: level at the ground of its lowest (north) edge's middle; faces round it
	var play_y := -INF
	for x: float in [24.0, 28.0, 32.0, 36.0, 40.0, 44.0, 48.0, 50.0]:
		for z: float in [-1508.0, -1504.0, -1500.0, -1496.0, -1492.0, -1490.0]: play_y = maxf(play_y, float(yb.call(x, z)))   # the highest ground under it
	pe.append([PLAY[0], PLAY[1], PLAY[2], PLAY[3], play_y])
	var yg := H.graded(yb, pe)
	# the grading up to the pads is eased back onto the plain ground within 4 m of the block's edges, so every edge
	# keeps its street walk's height (a pad near a walk otherwise lifts the edge: 8.5 cm at Amber, first build)
	var yf := func(x: float, z: float) -> float:
		var d := minf(minf(x - X0, X1 - x), minf(z - Z0, Z1 - z))
		return lerpf(float(yb.call(x, z)), float(yg.call(x, z)), smoothstep(0.0, 4.0, d))
	var paints: Array = []
	for b: Array in B: paints.append(H.pad_rect(fp(b)))
	paints.append([PLAY[0], PLAY[1], PLAY[2], PLAY[3], "-"])
	# stall lines of the condos' car park (rows u 100 - 140 and 147 - 225 on both sides of the aisle v -1540 .. -1533)
	for x0: float in [100.0, 147.0]:
		var n := 14 if x0 < 120.0 else 28
		for k in n + 1:
			var x := x0 + 2.7 * k
			if x > (140.0 if x0 < 120.0 else 225.0) + 0.01: break
			paints.append([x - 0.05, -1545.5, x + 0.05, -1540.0, "white"]); paints.append([x - 0.05, -1533.0, x + 0.05, -1527.5, "white"])
	paints.append([58.0, -1457.08, 238.0, -1456.92, "yellow"])            # the lane's centre line
	paints.append([238.0, -1457.08, 238.4, -1453.0, "white"])            # stop bar at the apron (outbound side)
	paints.append_array([
		[238.0, -1462.0, 240.8, -1461.0, "concrete"], [238.0, -1453.0, 240.8, -1452.0, "concrete"],   # flare to the apron
		[58.0, LANE[0], 240.8, LANE[1], "asphalt"],                     # BAYVIEW LANE
		[54.0, -1465.0, 66.0, -1449.0, "asphalt"],                      # its turnaround at the park
		[CONN[0], -1527.5, CONN[1], LANE[0], "asphalt"],                # the connector up to the condos' car park
		[100.0, -1545.5, 225.0, -1527.5, "asphalt"],                    # the car park (region)
		[16.0, -1585.7, 48.0, -1578.0, "plaza"],                        # the corner plaza
		[48.0, -1585.7, 240.8, -1583.7, "plaza"],                       # the 1st St front walk
		[52.0, -1562.0, 56.0, -1414.3, "plaza"],                        # Amber Steps' walk (straight runs down)
		[16.0, -1430.0, 52.0, -1426.0, "plaza"],                        # its top walk from the Amber x 3rd corner
		[22.0, -1512.0, 52.0, -1508.0, "plaza"],                        # ... to the playground terrace
		[24.0, -1570.0, 52.0, -1562.0, "plaza"],                        # ... and down behind the cafe to the plaza
		[16.0, -1562.0, 24.0, -1578.0, "plaza"],
		[61.0, -1583.7, 63.0, -1576.0, "plaza"], [119.0, -1583.7, 121.0, -1576.0, "plaza"],   # condo lobby paths
		[179.0, -1583.7, 181.0, -1576.0, "plaza"],
		[89.0, -1583.7, 91.0, -1576.0, "plaza"], [149.0, -1583.7, 151.0, -1576.0, "plaza"],   # garden apartments' middle doors
		[211.0, -1583.7, 213.0, -1576.0, "plaza"],
		[62.0, -1561.0, 230.0, -1559.0, "plaza"],                       # the back walk behind the condos
		[CONN[1], -1559.0, CONN[1] + 2.0, -1545.5, "plaza"],             # ... down to the car park
	])
	# garage aprons from the lane to each townhouse's garages (concrete, the width of the house)
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
	H.level_pad(g, "grass", PLAY[0], PLAY[1], PLAY[2], PLAY[3], play_y, yf)
	# the condos' lobby doors stand 0.3 m over their pads (and the pads over the lawn): closed steps up from the lawn
	for i in B.size():
		var b: Array = B[i]
		if float(b[5]) == 0.0: continue
		var f := fp(b); var gy: float = yf.call(float(b[5]), f[1] - 3.0); var top := float(PY[i]) + 0.3
		H.steps_z2(g, float(b[5]), 2.0, f[1] - ceilf((top - gy) / 0.17) * H.TREAD, f[1], gy, top, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fn_mid")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the lane: stop sign at the apron, lamps on the verges between the houses (arm over the lane), the
	#      townhouses' bins at their garage corners on collection day, the condos' dumpster at the connector's head
	P.call("prop_sign_stop", "worn", 238.4, -1451.6, -90.0)
	for x: float in [84.0, 108.0, 178.0, 202.0]: P.call("prop_lamp_cobra", "worn", x, -1451.4, 180.0)
	for x: float in [132.0, 228.0]: P.call("prop_lamp_cobra", "worn", x, -1462.6, 0.0)
	for x: float in [82.6, 106.0, 130.6, 176.6, 200.0, 224.6]: P.call("prop_trash_cart_black", "worn", x, -1452.4, 180.0)
	P.call("prop_dumpster_3yd_green", "worn", 143.5, -1547.0, 0.0)
	P.call("prop_lot_light_pole", "worn", 160.0, -1526.5, 0.0)
	P.call("prop_lot_light_pole", "worn", 200.0, -1526.5, 0.0)
	# ---- the car park's wheel stops (north row noses north, south row noses south)
	for x0: Array in [[100.0, 14], [147.0, 28]]:
		for k in int(x0[1]):
			var x := float(x0[0]) + 1.35 + 2.7 * k
			P.call("prop_wheel_stop_concrete", "worn", x, -1544.9, 0.0)
			P.call("prop_wheel_stop_concrete", "worn", x, -1528.1, 0.0)
	# ---- the townhouses: a condenser at each end wall, oil on the aprons where the cars stand
	for b: Array in B:
		if not String(b[0]).begins_with("th_"): continue
		var f := fp(b)
		var mz := (float(f[1]) + float(f[3])) * 0.5
		P.call("prop_ac_condenser", "worn", float(f[0]) - 0.8, mz, 90.0)
