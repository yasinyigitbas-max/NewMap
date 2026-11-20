extends SceneTree
## Piece n_fn_east (the north end, block 3): THE FERRY LANDING QUARTER. u 259.2 (B Ave's east walk) .. 400 (the
## hospital zone's n_hp_west, locked: met flush on its own heights), v -1585.7 (1st St's south walk; between u 328 and
## 372 the ferry gap, no walk) .. -1414.3 (3rd St's north walk). Placed at grid [0, 2.0, 0], yaw 0. Run once.
##
## WHY (planner): the ferry gap in 1st St (u 328 - 372) is where the ferry landing's people come ashore (ZONING.md:
## the ferry landing and the maritime museum lie north, outside the ring). So the block is the ferry's front door:
##  - FERRY PLAZA (u 320 - 382, on the gap): open paving straight off the gap, bollards across it (people walk through,
##    cars do not), benches looking at the bay, racks, a lifering at the edge. Round it: the FERRY TICKET OFFICE
##    (civ_harbor_office, its door on the plaza facing the gap), BAY KAYAK & BIKE RENTAL (com_surf_shop, on the plaza's
##    east side: kayaks and cruisers out on the paving), PIER FISH HOUSE (com_bistro, on the plaza's west side, its
##    tables on the plaza in the bay air).
##  - FERRY LANDING INN (motel_inn_court) on the bay west of the plaza: rooms with sliders to a lawn facing the water;
##    its office door on the 1st St walk, where the walkers from the ferry come by.
##  - the only car opening is B Ave's east apron (v -1461 .. -1453): FERRY DRIVE runs east from it; north of it the
##    PARK AND RIDE (people leave the car and take the ferry), its rows off the drive; the inn's guest lot on its own
##    aisle north from the drive.
##  - FERRY WALK (u 300.4 - 304): the walk from 3rd St (its bus stops and the hill) straight north to the bay, past the
##    lot and the inn; a pocket plaza where it meets 3rd St.
##  - FERRY GREEN between the lot and the ticket office: the playground and picnic lawn for the families waiting for a
##    boat and the neighbours.
##  - 3rd St (the arterial to the bridge): a row of shops facing it (corner market, boutiques, bakery, a shop row, a pub,
##    a realtor, a coffee shop), their back yard and delivery stalls on Ferry Drive; it continues the hospital's
##    pharmacy and bistro next door.
## LAND (Yasin: "build according to it"): flat here (1.94 - 2.15); the ground follows it (n_fn_site.g: 5 cm over the
## land, eased onto the walks within 12 m); every building on a level pad at the highest ground under it.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fn_site.gd")

const X0 := 259.2
const X1 := 400.0
const Z0 := -1585.7
const Z1 := -1414.3
const DRIVE := [-1461.0, -1453.0]
const FWALK := [300.4, 304.0]
## [label, folder, centre u, centre v, yaw, door sill over the pad]
const B := [
	["inn", "extras/motel_inn_court", 280.64, -1569.4, 180.0, 0.0],          # front (sliders, office) to the bay at v -1576
	["fish_house", "commercial/com_bistro", 311.83, -1572.0, 90.0, 0.0],     # front on the plaza at u 320, door v -1576.76
	["ferry_office", "civic/civ_harbor_office", 350.0, -1552.05, 180.0, 0.3], # front on the plaza at v -1562, door u 350
	["rental", "commercial/com_surf_shop", 389.95, -1574.0, -90.0, 0.0],     # front on the plaza at u 382, door v -1577.26
	["corner", "commercial/com_orange_corner", 268.0, -1427.67, 0.0, 0.0],   # 3rd St fronts at v -1419.5
	["boutiques", "commercial/com_boutique_row", 286.0, -1427.67, 0.0, 0.0],
	["bakery", "commercial/com_bakery", 309.0, -1427.67, 0.0, 0.0],
	["shop_row", "commercial/com_orange_row", 325.5, -1427.67, 0.0, 0.0],
	["pub", "commercial/com_bar_crown", 342.0, -1427.45, 0.0, 0.0],
	["realty", "commercial/com_realty", 352.0, -1427.67, 0.0, 0.0],
	["coffee", "commercial/com_cafe_seaside", 360.0, -1427.67, 0.0, 0.0],
]
## stall-line patches (their own ground, n_un_north's REGIONS: the lines would cut the whole field otherwise)
const REGIONS := [
	[304.0, -1502.5, 394.0, -1461.0, "asphalt"],     # the park and ride: rows 1-5, the two connectors
	[270.5, -1530.0, 288.5, -1466.0, "asphalt"],     # the inn's guest lot
	[304.0, -1453.0, 364.0, -1447.5, "asphalt"],     # delivery stalls behind the shops
]

## the things people use, each with its reason (placed on the ground as built: hs_fill_lib.polish)
const ITEMS := [
	# ---- FERRY PLAZA: benches facing the bay (north) at the gap, bollards across the gap (people pass, cars cannot),
	#      a lifering at the open edge, lamps, the ticket office's bins against its wall, racks by the office door
	["prop_park_bench", "worn", 336.0, -1580.5, 180.0], ["prop_park_bench", "worn", 344.0, -1580.5, 180.0],
	["prop_park_bench", "worn", 356.0, -1580.5, 180.0], ["prop_park_bench", "worn", 364.0, -1580.5, 180.0],
	["prop_bollard_steel", "worn", 330.0, -1585.0, 0.0], ["prop_bollard_steel", "worn", 334.0, -1585.0, 0.0],
	["prop_bollard_steel", "worn", 338.0, -1585.0, 0.0], ["prop_bollard_steel", "worn", 342.0, -1585.0, 0.0],
	["prop_bollard_steel", "worn", 346.0, -1585.0, 0.0], ["prop_bollard_steel", "worn", 354.0, -1585.0, 0.0],
	["prop_bollard_steel", "worn", 358.0, -1585.0, 0.0], ["prop_bollard_steel", "worn", 362.0, -1585.0, 0.0],
	["prop_bollard_steel", "worn", 366.0, -1585.0, 0.0], ["prop_bollard_steel", "worn", 370.0, -1585.0, 0.0],
	["prop_lifering_stand", "clean", 350.0, -1584.6, 180.0],
	["prop_lamp_victorian", "worn", 326.0, -1583.0, 0.0], ["prop_lamp_victorian", "worn", 374.0, -1583.0, 0.0],
	["prop_lamp_victorian", "worn", 340.0, -1566.0, 0.0], ["prop_lamp_victorian", "worn", 360.0, -1566.0, 0.0],
	["prop_trash_receptacle", "worn", 341.8, -1562.6, 0.0], ["prop_recycling_receptacle", "worn", 358.2, -1562.6, 0.0],
	["prop_bike_rack", "worn", 369.0, -1563.4, 0.0],
	["prop_newspaper_box_blue", "worn", 347.0, -1562.7, 180.0],
	["plant_potted_leafy", "normal", 323.0, -1563.5, 0.0], ["plant_potted_leafy", "normal", 377.0, -1563.5, 0.0],
	# ---- the fish house's tables on the plaza by its door (u 320), under umbrellas; its menu planters
	["prop_patio_set_4", "worn", 323.5, -1574.5, 0.0], ["prop_patio_set_4", "worn", 323.5, -1570.0, 15.0],
	["prop_patio_set_4", "worn", 327.5, -1572.0, 0.0],
	["plant_potted_succulent", "normal", 320.6, -1578.0, 0.0], ["plant_potted_succulent", "normal", 320.6, -1567.0, 0.0],
	# ---- the rental: kayak racks and rental bikes out on the paving in front of it (u 382), its sign of the day
	["prop_kayak_rack", "clean", 378.0, -1571.0, 90.0], ["prop_kayak_rack", "clean", 378.0, -1567.0, 90.0],
	["prop_beach_sign_rules", "worn", 381.0, -1582.0, -90.0],
	# ---- the inn: chairs on its bay lawn facing the water, a barbecue for the guests, vending and ice by the office
	["prop_adirondack_white", "worn", 275.5, -1580.5, 180.0], ["prop_adirondack_white", "worn", 283.5, -1580.5, 180.0],
	["prop_adirondack_wood", "worn", 290.8, -1580.5, 180.0], ["prop_adirondack_wood", "worn", 298.2, -1580.5, 180.0],
	["prop_vending_soda", "clean", 264.0, -1576.8, 180.0], ["prop_ice_chest", "clean", 261.0, -1572.0, 90.0],
	["plant_bird_of_paradise", "normal", 263.5, -1580.0, 0.0],
	["prop_mailbox_post_metal", "worn", 265.4, -1582.8, 180.0],
	["prop_bbq_gas_cart", "worn", 284.0, -1559.0, 0.0], ["prop_picnic_table", "worn", 280.0, -1556.0, 0.0],
	["prop_ac_condenser", "worn", 261.6, -1566.0, 90.0],
	# ---- FERRY GREEN: the playground on its sand (west), a shade sail over the picnic tables, benches facing the play
	#      ground for the parents, a fountain; lawn open in the middle
	["prop_play_structure", "worn", 318.0, -1528.0, 0.0], ["prop_swing_set", "worn", 326.5, -1532.0, 0.0],
	["prop_slide", "worn", 326.5, -1524.5, 90.0],
	["prop_park_bench", "worn", 314.0, -1538.6, 0.0], ["prop_park_bench", "worn", 323.0, -1538.6, 0.0],
	["prop_park_bench", "worn", 333.6, -1528.0, -90.0],
	["prop_drinking_fountain", "worn", 336.0, -1520.0, 0.0],
	["prop_shade_sail", "normal", 350.0, -1526.0, 0.0, false],
	["prop_picnic_table", "worn", 347.5, -1526.0, 0.0], ["prop_picnic_table", "worn", 352.5, -1526.0, 0.0],
	["prop_bbq_kettle", "worn", 356.6, -1528.5, 0.0],
	["prop_park_bench", "worn", 376.0, -1520.0, -90.0], ["prop_park_bench", "worn", 384.0, -1538.0, 180.0],
	["prop_sprinkler_impact", "normal", 372.0, -1530.0, 0.0, false], ["prop_sprinkler_impact", "normal", 340.0, -1510.0, 0.0, false],
	["plant_bougainvillea_mound", "normal", 390.0, -1542.0, 0.0], ["plant_agave_americana", "normal", 308.0, -1539.5, 0.0],
	# ---- FERRY WALK: lamps on its west side, a bench and bin where it meets the lot's footway
	["prop_lamp_globe", "worn", 300.0, -1550.0, 0.0], ["prop_lamp_globe", "worn", 300.0, -1520.0, 0.0],
	["prop_lamp_globe", "worn", 300.0, -1490.0, 0.0], ["prop_lamp_globe", "worn", 300.0, -1440.0, 0.0],
	# ---- the 3rd St forecourt: the bakery's and the coffee shop's tables at their doors, benches facing the street,
	#      paper boxes and racks by the doors, lamps
	["prop_patio_set_4", "worn", 306.5, -1416.6, 0.0], ["prop_patio_set_4", "worn", 362.0, -1416.6, 0.0],
	["prop_patio_set_4", "worn", 356.4, -1416.6, 15.0],
	["prop_park_bench", "worn", 300.0, -1415.4, 0.0], ["prop_bike_rack", "worn", 297.5, -1418.2, 90.0],
	["prop_newspaper_box_red", "worn", 273.0, -1418.8, 0.0], ["prop_newspaper_box_blue", "worn", 273.7, -1418.8, 0.0],
	["prop_bike_rack", "worn", 330.5, -1418.4, 0.0],
	["prop_lamp_victorian", "worn", 276.0, -1415.0, 0.0], ["prop_lamp_victorian", "worn", 316.0, -1415.0, 0.0],
	["prop_lamp_victorian", "worn", 348.0, -1415.0, 0.0], ["prop_lamp_victorian", "worn", 380.0, -1415.0, 0.0],
	["plant_potted_leafy", "normal", 300.0, -1419.0, 0.0],
	["prop_usps_collection_box", "worn", 275.5, -1418.6, 0.0],
	# ---- the corner green (u 364 - 400 on 3rd St): benches under the hospital's side, planting
	["prop_park_bench", "worn", 372.0, -1424.0, 0.0], ["prop_park_bench", "worn", 386.0, -1424.0, 0.0],
	["plant_bougainvillea_mound", "normal", 379.0, -1432.0, 0.0], ["plant_agave_americana_small", "normal", 393.0, -1430.0, 0.0],
	["prop_sprinkler_impact", "normal", 382.0, -1440.0, 0.0, false],
]

var PY: Array = []     # pad heights (local), one per row of B

## SUPERCHECKER (20 Nov; the coordinator, Yasin's word: "be MUCH more prone to delete: any prop or road/ground mark with
## any finding or any doubt is deleted with its reason, no relocating attempts"): tools/city/super/sc.py check on this
## piece (area layout OUT/fill/fn/area.json). Every prop with a finding is taken out (its reason on its line); a
## collision box on each building column the checker measured without one. Every oil mark and lane-wear stripe was
## also taken out of the script itself (the checker found oil on the drive's centre line with no car near it).
const SC := {
 "out": [
	["prop_trash_receptacle", 341.800, -1562.600, "bin_open: prop_trash_receptacle stands in the open (4.6 m from a wall, 99.0 m from a fence)"],
	["prop_recycling_receptacle", 358.200, -1562.600, "bin_open: prop_recycling_receptacle stands in the open (4.6 m from a wall, 99.0 m from a fence)"],
	["prop_park_bench", 344.000, -1580.500, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 356.000, -1580.500, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 364.000, -1580.500, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 314.000, -1538.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 323.000, -1538.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 333.600, -1528.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 376.000, -1520.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 384.000, -1538.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 386.000, -1424.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 347.500, -1526.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_play_structure", 318.000, -1528.000, "no_reason: prop_play_structure stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_swing_set", 326.500, -1532.000, "no_reason: prop_swing_set stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_slide", 326.500, -1524.500, "no_reason: prop_slide stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_shade_sail", 350.000, -1526.000, "sail_over_nothing: a shade sail with no table, seat or play item under it"],
 ],
 "boxes": [
	["Buildings/inn", [16.8874, 1.1000, -5.0201, 0.4152, 2.2000, 0.2400]],
	["Buildings/inn", [-19.0705, 1.5500, 6.3649, 0.3000, 3.1000, 0.3101]],
	["Buildings/inn", [-17.0251, 1.3000, -5.3601, 0.8399, 2.6000, 0.7598]],
	["Buildings/inn", [17.4997, 1.5300, 4.9409, 0.1600, 3.0600, 0.1620]],
	["Buildings/inn", [-10.5005, 1.7000, 6.1249, 0.2601, 2.8000, 0.2900]],
	["Buildings/fish_house", [3.7350, 1.5000, 6.7748, 0.4900, 3.0000, 0.4901]],
	["Buildings/fish_house", [1.6959, 1.5000, 6.8800, 0.1600, 3.0000, 0.1600]],
	["Buildings/ferry_office", [0.8999, 1.6999, 5.6998, 0.1600, 2.7999, 0.1600]],
	["Buildings/ferry_office", [-0.9001, 1.6999, 5.6998, 0.1600, 2.7999, 0.1600]],
	["Buildings/rental", [2.0366, 1.5000, 6.8799, 0.1600, 3.0000, 0.1600]],
	["Buildings/corner", [2.1049, 1.5000, 6.7748, 0.4900, 3.0000, 0.4901]],
	["Buildings/corner", [3.9450, 1.5000, 6.8800, 0.1600, 3.0000, 0.1600]],
	["Buildings/corner", [-1.8801, 1.5000, 6.7748, 0.1600, 3.0000, 0.4901]],
	["Buildings/bakery", [2.2349, 1.5000, 6.7748, 0.4899, 3.0000, 0.4901]],
	["Buildings/bakery", [-0.0134, 1.5000, 6.8800, 0.1600, 3.0000, 0.1600]],
	["Buildings/pub", [2.0367, 1.5000, 6.8799, 0.1600, 3.0000, 0.1600]],
	["Buildings/pub", [0.0132, 1.5000, 6.8799, 0.1600, 3.0000, 0.1600]],
	["Buildings/coffee", [1.0249, 1.5000, 6.8800, 0.1600, 3.0000, 0.1600]],
 ],
}

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array:
	var st := K.building_stats(f)
	if st.has("near"): return (st.near as Dictionary).bbox
	var wd: Array = st.footprint_wd
	return [[-float(wd[0]) * 0.5, 0.0, -float(wd[1]) * 0.5], [float(wd[0]) * 0.5, float(st.get("height", 6.0)), float(wd[1]) * 0.5]]
## footprint [u0, v0, u1, v1] of one row of B (yaw 0 / 90 / -90 / 180)
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(absf(yaw) - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]   # yaw -90

func _run() -> void:
	var root := Node3D.new(); root.name = "n_fn_east"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fn_east")
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
	# ---- stall lines: the park and ride's five rows (28 stalls each, 2.7 m, u 311 .. 386.6), the inn's lot (two rows
	#      along its aisle, 2.7 m along v), the delivery stalls behind the shops
	for k in 29:
		var x := 311.0 + 2.7 * k
		for r: Array in [[-1466.5, -1461.0], [-1472.0, -1466.5], [-1484.5, -1479.0], [-1490.0, -1484.5], [-1502.5, -1497.0]]:
			paints.append([x - 0.05, r[0], x + 0.05, r[1], "white"])
	for k in 24:
		var z := -1530.0 + 2.7 * k
		paints.append([270.5, z - 0.05, 276.0, z + 0.05, "white"]); paints.append([283.0, z - 0.05, 288.5, z + 0.05, "white"])
	for k in 22:
		var x := 304.5 + 2.7 * k
		paints.append([x - 0.05, -1453.0, x + 0.05, -1447.5, "white"])
	for z: float in [-1460.5, -1459.5, -1458.5, -1457.5, -1456.5, -1455.5, -1454.5, -1453.5]:
		paints.append([FWALK[0], z - 0.25, FWALK[1], z + 0.25, "white"])     # the zebra where Ferry Walk crosses the drive
	paints.append([262.5, -1457.08, 394.0, -1456.92, "yellow"])          # the drive's centre line
	paints.append([262.0, -1461.0, 262.4, -1457.08, "white"])            # stop bar at the apron (the inbound side)
	paints.append_array([
		[259.2, -1462.0, 262.0, -1461.0, "concrete"], [259.2, -1453.0, 262.0, -1452.0, "concrete"],   # flare to the apron
		[259.2, DRIVE[0], 394.0, DRIVE[1], "asphalt"],                  # FERRY DRIVE
		[304.0, -1502.5, 394.0, -1461.0, "asphalt"],                    # the park and ride (region)
		[270.5, -1530.0, 288.5, -1466.0, "asphalt"],                    # the inn's guest lot (region)
		[276.0, -1466.0, 283.0, DRIVE[0], "asphalt"],                   # ... its aisle's mouth on the drive
		[304.0, -1453.0, 364.0, -1447.5, "asphalt"],                    # delivery stalls (region)
		[261.0, -1447.5, 364.0, -1437.0, "concrete"],                   # the shops' back yard (bins, condensers)
		[FWALK[0], -1585.7, FWALK[1], -1414.3, "plaza"],                # FERRY WALK, bay to 3rd St
		[296.0, -1437.0, 304.0, -1414.3, "plaza"],                      # the pocket plaza where it meets 3rd St
		[259.2, -1419.5, 400.0, -1414.3, "plaza"],                      # the 3rd St forecourt
		[320.0, -1585.7, 382.0, -1562.0, "plaza"],                      # FERRY PLAZA (open to the gap)
		[359.0, -1562.0, 366.0, -1544.5, "plaza"],                      # ... its walk past the office to the green
		[362.0, -1544.5, 366.0, -1502.5, "plaza"],                      # ... and through the green to the lot
		# (the playground's sand and the picnic pad were taken out with their play items and tables: superchecker no_reason)
		[304.0, -1544.5, 362.0, -1542.5, "plaza"],                      # the green's path from Ferry Walk to the plaza walk
		[259.2, -1585.7, 300.4, -1583.7, "plaza"],                      # the 1st St front walk of the inn
		[266.3, -1583.7, 268.3, -1576.0, "plaza"],                      # the inn's office path (door u 267.34)
		[271.4, -1583.7, 273.4, -1576.0, "plaza"], [278.9, -1583.7, 280.9, -1576.0, "plaza"],   # its room pairs' paths
		[286.4, -1583.7, 288.4, -1576.0, "plaza"], [293.9, -1583.7, 295.9, -1576.0, "plaza"],
		[262.0, -1563.4, 300.4, -1561.4, "plaza"],                      # the inn's back walk (back door u 264.44)
		[278.0, -1561.4, 288.0, -1553.0, "concrete"],                   # its guests' barbecue pad
		[382.0, -1585.7, 400.0, -1583.7, "plaza"],                      # the 1st St walk on to the hospital's
		[364.0, -1437.0, 400.0, -1419.5, "grass"],                      # the corner green on 3rd St
	])
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
	# the ferry gap: the edge stands over the open land beyond (up to 15 cm): a face down from it
	H.skirt(g, Vector2(326.0, Z0), Vector2(374.0, Z0), yf, "wall")
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	# the ticket office's raised sill (0.3 m): steps up from the plaza to its door
	for i in B.size():
		var b: Array = B[i]
		var sill := float(b[5])
		if sill < 0.03: continue
		var f := fp(b); var gy: float = yf.call(float(b[2]), f[1] - 2.0); var top := float(PY[i]) + sill
		H.steps_z2(g, float(b[2]), 4.0, f[1] - ceilf((top - gy) / 0.17) * H.TREAD, f[1], gy, top, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, ITEMS)
	H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fn_east")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- Ferry Drive: the stop sign at the apron (outbound side), cobra lamps on the verges with their arms over the
	#      drive, the park and ride's pay station on the grass beside Ferry Walk (where the riders walk off), a
	#      no-parking sign at the drive's mouth
	P.call("prop_sign_stop", "worn", 262.4, -1452.4, 90.0)
	P.call("prop_sign_no_parking", "worn", 266.0, -1461.6, 0.0)
	P.call("prop_lamp_cobra", "worn", 292.0, -1462.8, 0.0)
	for x: float in [370.0, 390.0]: P.call("prop_lamp_cobra", "worn", x, -1451.5, 180.0)
	P.call("prop_pay_station", "worn", 299.6, -1464.0, 90.0)
	# ---- the park and ride: wheel stops at the stalls' heads (rows 1, 3, 5 nose north, 2 and 4 nose south), lot
	#      lights on the green's edge north of the last row (the rows are back to back: no island for a pole)
	for k in 28:
		var x := 312.35 + 2.7 * k
		P.call("prop_wheel_stop_concrete", "worn", x, -1465.9, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", x, -1467.1, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", x, -1483.9, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", x, -1485.1, 0.0)
		P.call("prop_wheel_stop_concrete", "worn", x, -1501.9, 0.0)
	for x: float in [330.0, 368.0]: P.call("prop_lot_light_pole", "worn", x, -1503.4, 0.0)
	# oil where cars stand all day (the ferry commuters' stalls nearest the walk)
	# ---- the inn's guest lot: wheel stops, a light, the inn's dumpster on its north end by the back walk
	for k in 23:
		var z := -1528.65 + 2.7 * k
		P.call("prop_wheel_stop_concrete", "worn", 271.1, z, 90.0)
		P.call("prop_wheel_stop_concrete", "worn", 287.9, z, 90.0)
	P.call("prop_lot_light_pole", "worn", 272.0, -1532.0, 0.0)
	P.call("prop_dumpster_3yd_green", "worn", 279.5, -1531.2, 0.0)       # at the aisle's head: the truck backs up the aisle
	# ---- the shops' back yard: each shop's bin against its back wall, condensers, the delivery stalls' wheel stops
	for x: float in [266.8, 287.8, 310.5, 327.3, 344.5, 354.8]: P.call("prop_dumpster_3yd_blue" if x > 300.0 else "prop_dumpster_3yd_green", "worn", x, -1436.9, 0.0)
	for x: float in [272.0, 281.8, 313.0, 321.3, 333.5, 346.5, 352.8, 361.5]: P.call("prop_ac_condenser", "worn", x, -1436.6, 0.0)
	for k in 21: P.call("prop_wheel_stop_concrete", "worn", 305.85 + 2.7 * k, -1448.1, 0.0)
	# ---- the ferry office: its flag-less monument stone by the steps, a bench either side of the door (people wait
	#      for the boat out of the wind)
	P.call("prop_park_bench", "worn", 344.0, -1563.4, 180.0)
	P.call("prop_park_bench", "worn", 356.0, -1563.4, 180.0)
