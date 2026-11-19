extends SceneTree
## Piece n_hp_transit (hospital zone, block A south): ISLAND HOSPITAL TRANSIT CENTER and the HELIPAD. u 509.2 (Adela's
## east walk) .. the ring's walk / the junction (645.7), v -1453 (Hospital Drive's south kerb, n_hp_main) .. -1414.3
## (3rd St's north walk). Placed at grid [0, 2.0, 0], yaw 0. Run once; never when locked.
##
## WHY (planner; Yasin: "Place a bus station at hospital"): the island's buses meet at the hospital, the place more
## people go to without a car than anywhere (visitors, outpatients, the night shift). The buses come in at Adela's
## apron (ambulances have their own way in off 3rd St: EMERGENCY DRIVE, east of the platform), and pull into a LAY-BY along the south side of Hospital Drive: four bays along one
## platform, each with its shelter, its stop sign and a bench; behind the platform the WAITING HALL (civ_post_office
## re-used: one civic door on the platform; tickets, timetables, benches, vending inside). West of the hall a small
## plaza meets the people walking in from the Adela / 3rd St junction's crosswalks: a coffee kiosk with tables, trees in
## wells, bike racks. East of the hall a break corner for the drivers. Further east, across the drive from the ER's
## ambulance bay, the HELIPAD in its fenced field (gate opposite the zebra to the bay; edge lights; nothing tall near it).
## LAND (Yasin: "build according to it"): the ground follows the land (n_hp_site.g); the hall and the kiosk on level pads.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_hp_site.gd")

const X0 := 509.2
const X1 := 645.7
const ZN := -1453.0
const LAYBY := [518.0, -1453.0, 584.0, -1446.5]
const PLATFORM := [516.0, -1446.5, 586.0, -1440.0]
## EMERGENCY DRIVE (19 Nov, Yasin: "make the drive way"): from 3rd St's new curb cut (s_rg_nw_b071, patched in place by
## tools/city/pilot/patch_driveway.gd: u 588.60 .. 596.43, the parkway lowered to the road) straight north across
## Hospital Drive into the ER's ambulance bay (n_hp_main), so ambulances come in off the bridge route (ZONING.md)
const EDRIVE := [588.5957, 596.4305]
const HALL := ["civic/civ_post_office", 548.0, -1428.55]    # yaw 180: front (door, u 548) on the platform at v -1440
const KIOSK := ["commercial/com_kiosk", 522.0, -1430.0]      # yaw 90: its window on the plaza (east)
const BAYS := [524.0, 536.0, 560.0, 572.0]                   # bay centres (shelters); the hall door at 548 stays clear
const PAD := [609.0, -1443.0, 629.0, -1423.0]                # the helipad's touchdown square
const HF := [598.0, -1449.0, 640.0, -1417.0]                 # the helipad field's fence line

const GREEN := [
	# plaza trees in wells (mulch squares painted below), facing the junction's crosswalks
	["tree_ficus_a", "normal", 514.0, -1437.0, 0.0, false], ["tree_ficus_b", "normal", 514.0, -1420.0, 90.0, false],
	["tree_jacaranda_a", "normal", 530.0, -1418.0, 30.0, false],
	# 3rd St frontage east of the hall: queen palms in the grass strip (low planting only along the helipad)
	["palm_queen_a", "normal", 567.0, -1416.0, 0.0, false], ["palm_queen_b", "normal", 580.0, -1416.0, 60.0, false],
	["palm_queen_a", "normal", 584.5, -1416.0, 120.0, false],
	["plant_iceplant_patch", "normal", 606.0, -1415.8, 0.0, false], ["plant_iceplant_patch", "normal", 620.0, -1415.8, 90.0, false],
	["plant_iceplant_patch", "normal", 634.0, -1415.8, 0.0, false],
	["plant_bird_of_paradise", "normal", 570.0, -1432.0, 0.0, false], ["plant_agave_americana_small", "normal", 576.0, -1436.0, 0.0, false],
	["prop_sprinkler_popup", "normal", 575.0, -1428.0, 0.0, false], ["prop_sprinkler_popup", "normal", 619.0, -1447.0, 0.0, false],
]

var HY := 0.0          # pad heights (local)
var KY := 0.0

## POLISH (19 Nov, Yasin: "run a polish pass on the whole zone, plenty of relevant props, lots of life"): trees on open
## lawn away from the buildings, shrubs and sprinklers nearer them, benches / picnic tables / garden chairs where people
## sit (gardens, courts, lawns), benches, planters, bins, racks, fountains and paper boxes on the wide paving; each on a
## free spot this piece already had (found by a scratch tool, OUT/py/freespots_hp.py, chosen per kind of place, frozen
## here), standing on the ground as built (hs_fill_lib.polish).
const POLISH := [
	["plant_bird_of_paradise", "normal", 509.5, -1452.8, 61.0, false],
	["plant_agave_americana", "normal", 603.5, -1452.8, 122.0, false],
	["plant_bougainvillea_mound", "normal", 610.5, -1452.8, 183.0, false],
	["prop_sprinkler_impact", "normal", 618.0, -1452.8, 244.0, false],
	["plant_agave_americana_small", "normal", 625.0, -1452.8, 305.0, false],
	["plant_bird_of_paradise", "normal", 632.0, -1452.8, 6.0, false],
	["prop_park_bench", "worn", 509.5, -1441.8, -90.0],
	["plant_potted_leafy", "normal", 512.5, -1434.8, 0.0, false],
	["prop_trash_receptacle", "worn", 516.0, -1444.8, 0.0],
	["prop_bike_rack", "worn", 519.5, -1438.2, -180.0],
	["plant_potted_succulent", "normal", 529.0, -1439.2, 0.0, false],
	["prop_drinking_fountain", "worn", 531.0, -1431.2, 90.0],
	["prop_newspaper_box_blue", "worn", 533.5, -1444.8, 180.0],
	["prop_recycling_receptacle", "worn", 540.5, -1443.2, 0.0],
	["prop_park_bench", "worn", 554.0, -1443.8, 180.0],
	["plant_agave_americana", "normal", 564.0, -1432.2, 67.0, false],
	["plant_potted_leafy", "normal", 564.0, -1442.8, 0.0, false],
	["prop_sprinkler_impact", "normal", 569.0, -1437.2, 128.0, false],
	["plant_iceplant_patch", "normal", 572.5, -1431.2, 189.0, false],
	["prop_park_bench", "worn", 578.0, -1443.2, 90.0],
	["plant_agave_americana_small", "normal", 580.0, -1437.2, 250.0, false],
	["prop_park_bench", "worn", 585.0, -1444.8, 90.0],
	["plant_potted_succulent", "normal", 509.5, -1414.8, 0.0, false],
	["prop_drinking_fountain", "worn", 509.5, -1428.2, -90.0],
	["prop_newspaper_box_blue", "worn", 516.0, -1419.2, 0.0],
	["prop_recycling_receptacle", "worn", 521.5, -1414.8, 0.0],
	["prop_park_bench", "worn", 524.5, -1421.2, 0.0],
	["plant_potted_leafy", "normal", 529.0, -1414.8, 0.0, false],
]

func _init() -> void: _run.call_deferred()

static func bb(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox

func _run() -> void:
	var root := Node3D.new(); root.name = "n_hp_transit"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_hp_transit")
	var yb := func(x: float, z: float) -> float: return S.y(x, z)
	var hb := bb(String(HALL[0])); var kb := bb(String(KIOSK[0]))
	# yaw 180: model x -> -u, model z -> -v
	var hall := [float(HALL[1]) - float(hb[1][0]), float(HALL[2]) - float(hb[1][2]), float(HALL[1]) - float(hb[0][0]), float(HALL[2]) - float(hb[0][2])]
	# yaw 90: model x -> -v, model z -> +u
	var kio := [float(KIOSK[1]) + float(kb[0][2]), float(KIOSK[2]) - float(kb[1][0]), float(KIOSK[1]) + float(kb[1][2]), float(KIOSK[2]) - float(kb[0][0])]
	HY = H.pad_height(hall, 180.0, yb); KY = H.pad_height(kio, 90.0, yb)
	var yf := H.graded(yb, [H.pad_entry(hall, HY), H.pad_entry(kio, KY)])
	var paints: Array = [H.pad_rect(hall), H.pad_rect(kio)]
	# helipad markings: white edge band, the H
	var c := Vector2((PAD[0] + PAD[2]) * 0.5, (PAD[1] + PAD[3]) * 0.5)
	paints.append_array([
		[c.x - 2.5, c.y - 4.0, c.x - 1.5, c.y + 4.0, "white"], [c.x + 1.5, c.y - 4.0, c.x + 2.5, c.y + 4.0, "white"],
		[c.x - 1.5, c.y - 0.5, c.x + 1.5, c.y + 0.5, "white"],
		[PAD[0], PAD[1], PAD[2], PAD[1] + 0.5, "white"], [PAD[0], PAD[3] - 0.5, PAD[2], PAD[3], "white"],
		[PAD[0], PAD[1], PAD[0] + 0.5, PAD[3], "white"], [PAD[2] - 0.5, PAD[1], PAD[2], PAD[3], "white"],
		[PAD[0], PAD[1], PAD[2], PAD[3], "concrete"],
		[604.5, -1449.0, 606.5, -1436.0, "concrete"], [606.5, -1437.0, PAD[0], -1435.0, "concrete"],   # the gurney path
	])
	# bay stop bars (white) at each bay's front end, the lay-by's edge line, the tactile strip on the platform edge
	for b: float in BAYS: paints.append([b + 5.8, LAYBY[1] + 0.3, b + 6.1, LAYBY[3], "white"])
	paints.append([LAYBY[0], -1453.1, LAYBY[2], -1452.9, "white"])
	paints.append([EDRIVE[0], -1452.2, EDRIVE[1], -1451.8, "white"])        # Emergency Drive's stop bar
	paints.append([PLATFORM[0], -1446.5, PLATFORM[2], -1446.0, "tactile"])
	# tree wells in the plaza
	for t: Array in [[514.0, -1437.0], [514.0, -1420.0], [530.0, -1418.0]]:
		paints.append([float(t[0]) - 0.8, float(t[1]) - 0.8, float(t[0]) + 0.8, float(t[1]) + 0.8, "mulch"])
	paints.append_array([
		[EDRIVE[0], ZN, EDRIVE[1], S.THIRD, "asphalt"],         # Emergency Drive
		[LAYBY[0], LAYBY[1], LAYBY[2], LAYBY[3], "asphalt"],
		[PLATFORM[0], PLATFORM[1], PLATFORM[2], PLATFORM[3], "plaza"],
		[509.2, -1446.5, 516.0, -1440.0, "plaza"],               # the platform's west end to Adela's walk
		[509.2, -1440.0, 536.28, -1417.0, "plaza"],              # the plaza from the junction
		[509.2, -1417.0, 562.0, -1414.3, "plaza"],               # ... and along 3rd St to the hall's back walk
		[555.0, -1419.55, 557.0, -1417.0, "plaza"],              # the hall's back door step
		[559.72, -1440.0, 566.0, -1436.0, "plaza"],              # the drivers' break corner
		[566.0, -1440.0, 596.0, -1430.0, "grass"],
	])
	var zlo := func(x: float) -> float: return maxf(ZN, S.ring_v(x))
	var zhi := func(_x: float) -> float: return S.THIRD
	var u := 640.0
	while u <= 645.6: paints.append([u, -1440.0, u, -1440.0, "-"]); u += 0.5
	H.paint_band(g, X0, X1, zlo, zhi, paints, "grass", yf)
	H.pad_at(g, hall, HY, yf); H.pad_at(g, kio, KY, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.polish(props, g, GREEN)
	if PASS >= 2: H.polish(props, g, POLISH)
	H.finish(root, g, props, dec, "n_hp_transit")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	K.building(bl, String(HALL[0]), Vector3(HALL[1], HY, HALL[2]), 180.0, "transit_hall")
	K.building(bl, String(KIOSK[0]), Vector3(KIOSK[1], KY, KIOSK[2]), 90.0, "kiosk")
	# ---- the platform: a shelter at every bay facing the lay-by, its stop sign at the bay's front end on the kerb,
	#      a bench between the shelters, timetable cases either side of the hall door, bins, lamps between the shelters
	for b: float in BAYS:
		P.call("prop_bus_shelter", "worn", b, -1444.0, 180.0)
		P.call("prop_bus_stop_sign", "worn", b + 4.3, -1445.6, 180.0)
	for x: float in [530.0, 566.0]: P.call("prop_bench_bus_stop", "worn", x, -1444.2, 180.0)
	for x: float in [544.2, 551.8]: P.call("prop_poster_case", "worn", x, -1440.4, 180.0)
	for x: float in [529.6, 554.6, 579.5]: P.call("prop_trash_receptacle", "worn", x, -1441.0)
	P.call("prop_recycling_receptacle", "worn", 541.4, -1441.0)
	for x: float in [518.0, 542.0, 554.0, 584.0]: P.call("prop_lamp_globe", "worn", x, -1442.4)
	P.call("prop_newspaper_box_red", "worn", 556.4, -1441.0, 180.0)
	P.call("prop_newspaper_box_blue", "worn", 557.2, -1441.0, 180.0)
	P.call("prop_vending_soda", "worn", 582.5, -1441.2, 180.0)       # at the far end, where the long waits are
	P.call("prop_bench_bus_stop", "worn", 580.0, -1444.2, 180.0)
	# ---- Emergency Drive: emergency-only signs at its mouth on 3rd St, a stop bar before Hospital Drive, a lamp
	P.call("prop_sign_no_parking", "worn", 587.6, -1416.2, 0.0)
	P.call("prop_sign_no_parking", "worn", 597.4, -1416.2, 0.0)
	P.call("prop_lamp_cobra", "worn", 587.2, -1430.0, -90.0)
	W.lane_wear(dec, rr, (EDRIVE[0] + EDRIVE[1]) * 0.5, -1450.0, -1418.0, true, yf)
	# ---- the plaza from the junction: the coffee kiosk's tables on its window side, bike racks, a paper box, a mailbox
	P.call("prop_patio_set_4", "worn", 529.5, -1433.5, 0.0)
	P.call("prop_patio_set_4", "worn", 529.5, -1426.5, 30.0)
	P.call("prop_trash_receptacle", "worn", 526.6, -1436.2)
	P.call("prop_bike_rack", "worn", 520.0, -1438.6, 0.0)
	P.call("prop_bike_rack", "worn", 520.0, -1421.0, 0.0)
	P.call("prop_usps_collection_box", "worn", 534.8, -1421.5, 0.0)
	P.call("prop_park_bench", "worn", 512.2, -1428.0, 90.0)           # faces the plaza from Adela's side
	P.call("prop_lamp_victorian", "worn", 533.5, -1438.6)
	P.call("prop_lamp_victorian", "worn", 512.0, -1415.4)
	# ---- the hall: its dumpster against the east wall, clear of the back door (u 556), a condenser on the east side
	P.call("prop_dumpster_3yd_green", "worn", 562.6, -1421.5, 90.0)
	P.call("prop_ac_condenser", "worn", 560.6, -1426.5, 90.0)
	P.call("prop_ac_condenser", "worn", 560.6, -1428.5, 90.0)
	# ---- the drivers' break corner: a picnic table, a fountain, a bin, by the platform's east end
	P.call("prop_picnic_table", "worn", 562.8, -1438.0, 90.0)
	P.call("prop_drinking_fountain", "worn", 565.4, -1435.2, 0.0)
	# ---- the lay-by: worn lanes where the buses pull in, oil at each bay
	W.lane_wear(dec, rr, -1449.75, LAYBY[0] + 2.0, LAYBY[2] - 2.0, false, yf)
	for b: float in BAYS: W.oil(dec, rr, Vector2(b + 1.0, -1449.8), 0.0, yf, 0.5)
	# ---- the helipad field: chain-link all round, the rolling gate opposite the zebra to the ambulance bay (u 605.5),
	#      edge lights (steel bollards) at the pad's corners and mid sides, a lamp at the gate, no trees inside
	var fy := yf
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(HF[0], HF[1]), Vector2(602.6, HF[1]), fy, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(608.4, HF[1]), Vector2(HF[2], HF[1]), fy, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(HF[0], HF[1]), Vector2(HF[0], HF[3]), fy, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(HF[2], HF[1]), Vector2(HF[2], HF[3]), fy, 2.0)
	H.fence(props, "fence_chainlink", "fence_chainlink_post", Vector2(HF[0], HF[3]), Vector2(HF[2], HF[3]), fy, 2.0)
	P.call("fence_gate_rolling_chainlink", "worn", 605.5, HF[1], 0.0)
	for q: Array in [[PAD[0] - 0.6, PAD[1] - 0.6], [PAD[2] + 0.6, PAD[1] - 0.6], [PAD[0] - 0.6, PAD[3] + 0.6], [PAD[2] + 0.6, PAD[3] + 0.6],
			[(PAD[0] + PAD[2]) * 0.5, PAD[1] - 0.6], [(PAD[0] + PAD[2]) * 0.5, PAD[3] + 0.6], [PAD[0] - 0.6, (PAD[1] + PAD[3]) * 0.5 + 3.0], [PAD[2] + 0.6, (PAD[1] + PAD[3]) * 0.5]]:
		P.call("prop_bollard_steel", "normal", float(q[0]), float(q[1]))
	P.call("prop_lamp_cobra", "worn", 609.5, -1450.8, 90.0)
	P.call("prop_sign_no_parking", "worn", 600.0, -1450.4, 180.0)
