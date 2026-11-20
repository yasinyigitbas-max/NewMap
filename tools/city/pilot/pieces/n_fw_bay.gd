extends SceneTree
## Piece n_fw_bay (north-west column, block A, the bay front): BAYFRONT ROW and CROWN MEWS.
## u -390.8 (the u -400 street's walk) .. -209.2 (the u -200 street's walk), v -1585.7 (the bay-front ring's walk) ..
## -1414.3 (the v -1400 arterial's walk). Placed at grid [0, 0, 0], yaw 0 (x = u, y = world height, z = v). Run once.
##
## WHY (planner): the first block up from the bay, at the foot of Crown Hill's west slope (ZONING.md / zones.py:
## residential / Crown Hill north of v -1380; the industrial zone across the u -400 street, Crown Hill's houses across
## the u -200 street). Who lives here: people who want the bay at their door. The ring road in front has no car opening
## and the arterial behind has none either: cars come in ONLY at the two aprons 54-60 m south of the ring junctions
## (v -1460 .. -1454, one on each side street). So one private street, CROWN MEWS, joins those two aprons across the
## block, and everything that needs a car hangs off it:
##  - BAYFRONT ROW (north, facing the bay over the ring): four garden apartments and, in the middle, a beach condo whose
##    ground-floor front door is the BAYFRONT CAFE (coffee for the people on the bay walk; its terrace on the front lawn).
##    Their front lawns and door paths come off a front walk along the ring; benches face the bay.
##  - behind them their two PARKING COURTS with the BAY COURT (picnic, grill, shade) between, reached from the mews by
##    two lanes; the bins in walled corners at the courts' outer ends.
##  - the MEWS GREEN between the courts and the mews: the townhouse children's TOT LOT, a picnic lawn, a cross path.
##  - TOWNHOUSES on both sides of the mews (garages on the mews, closed back gardens): six facing north-to-south, six
##    facing south-to-north, their backs to the arterial behind a hedge-and-fence line.
##  - MEWS CORNER (SE, at the arterial junction, the block's highest corner): mailboxes, a bench, the collection box.
## LAND (Yasin: "DONT FORGET TO TAKE THE LAND INTO CONSIDERATION"): the land rises gently from 2.0 at the bay to 4.0 in
## the SE corner (at most 1.3 %). The ground follows it (n_fw_site.g: 5 cm over the land, eased onto every walk within
## 12 m); each building stands on its own level pad at the highest ground under it, the field graded up to the pads at
## 6 % (hs_fill_lib.graded), so the townhouse rows step up eastward one pad at a time.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fw_site.gd")

const X0 := -390.8
const X1 := -209.2
const Z0 := -1585.7
const Z1 := -1414.3
const MEWS := [-1461.0, -1453.0]          # Crown Mews (v): from the west apron to the east apron
const LANE_W := [-356.0, -350.0]          # the lanes (u) from the mews north to the parking courts
const LANE_E := [-250.0, -244.0]
const COURT_W := [-380.0, -1548.0, -322.0, -1530.0]
const COURT_E := [-278.0, -1548.0, -220.0, -1530.0]
const TOT := [-326.0, -1522.0, -306.0, -1504.0]      # the tot lot's level bark pad

## [label, folder, centre u, centre v, yaw]
const B := [
	["bay_1", "apartments/apt_garden_cream", -370.0, -1567.9, 180.0],     # front on the bay walk at v -1574
	["bay_2", "apartments/apt_garden_mint", -335.0, -1567.9, 180.0],
	["condo", "apartments/apt_beach_condo", -300.0, -1566.4, 180.0],      # its centre door (u -300): the Bayfront Cafe
	["bay_4", "apartments/apt_garden_cream", -265.0, -1567.9, 180.0],
	["bay_5", "apartments/apt_garden_mint", -230.0, -1567.9, 180.0],
	["tn_1", "apartments/apt_townhouse_cays", -373.0, -1473.4, 0.0],      # north of the mews: fronts (garages) at v -1467
	["tn_2", "apartments/apt_townhouse_cays", -336.68, -1473.4, 0.0],
	["tn_3", "apartments/apt_townhouse_cays", -312.24, -1473.4, 0.0],
	["tn_4", "apartments/apt_townhouse_cays", -287.8, -1473.4, 0.0],
	["tn_5", "apartments/apt_townhouse_cays", -263.36, -1473.4, 0.0],
	["tn_6", "apartments/apt_townhouse_cays", -227.0, -1473.4, 0.0],
	["ts_1", "apartments/apt_townhouse_modern", -377.28, -1440.6, 180.0], # south of the mews: fronts at v -1447
	["ts_2", "apartments/apt_townhouse_modern", -350.34, -1440.6, 180.0],
	["ts_3", "apartments/apt_townhouse_modern", -323.4, -1440.6, 180.0],
	["ts_4", "apartments/apt_townhouse_modern", -296.46, -1440.6, 180.0],
	["ts_5", "apartments/apt_townhouse_modern", -269.52, -1440.6, 180.0],
	["ts_6", "apartments/apt_townhouse_modern", -242.58, -1440.6, 180.0],
]
## the kit's front openings (along the facade, local x), read from room_contracts.json: garages ("serv", 2.6 m) and
## front doors; each townhouse gets a 3.2 m driveway at every garage and a path to its doors
const TH_GARAGE := {"apartments/apt_townhouse_cays": [-7.85, 1.45, 4.95], "apartments/apt_townhouse_modern": [-7.25, 1.25, 4.75]}
const TH_DOORS := {"apartments/apt_townhouse_cays": [[-4.7, -1.7], [7.85, 9.35]], "apartments/apt_townhouse_modern": [[-4.5, -1.5], [7.25, 8.75]]}

var PY: Array = []

func _init() -> void: _run.call_deferred()

static func bbox(f: String) -> Array: return (K.building_stats(f).near as Dictionary).bbox
static func fp(b: Array) -> Array:
	var x := bbox(String(b[1])); var cu: float = b[2]; var cv: float = b[3]; var yaw: float = b[4]
	if absf(yaw) < 1.0: return [cu + float(x[0][0]), cv + float(x[0][2]), cu + float(x[1][0]), cv + float(x[1][2])]
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]
## world u of a front opening at `along` (yaw 0: u = cu + along; yaw 180: u = cu - along)
static func ua(b: Array, along: float) -> float: return float(b[2]) + along if absf(float(b[4])) < 1.0 else float(b[2]) - along

func _run() -> void:
	var root := Node3D.new(); root.name = "n_fw_bay"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_fw_bay")
	var yb := func(x: float, z: float) -> float: return S.g("A", x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	# the tot lot's bark pad is level too: the field grades up to it like to a building's pad
	var tot_y := H.pad_height([TOT[0] + 0.3, TOT[1] + 0.3, TOT[2] - 0.3, TOT[3] - 0.3], 0.0, yb)
	pe.append([TOT[0], TOT[1], TOT[2], TOT[3], tot_y])
	var gr := H.graded(yb, pe)
	# the grading eases back onto the plain ground within 4 m of every walk, so the seams with the streets stay exact
	var yf := func(x: float, z: float) -> float: return lerpf(float(yb.call(x, z)), float(gr.call(x, z)), smoothstep(0.0, 4.0, S.edge_d("A", x, z)))
	# ---- patches painted on their own (their stall lines would cut the whole field into slivers): the two courts
	var regions: Array = []
	for c: Array in [COURT_W, COURT_E]:
		var lines: Array = []
		var lane: Array = LANE_W if c == COURT_W else LANE_E
		for k in 22:
			var x := float(c[0]) + 2.7 * k
			if x > float(c[2]) + 0.01: break
			lines.append([x - 0.05, -1548.0, x + 0.05, -1542.5, "white"])                                   # north row
			if x < float(lane[0]) - 1.2 or x > float(lane[1]) + 1.2: lines.append([x - 0.05, -1535.5, x + 0.05, -1530.0, "white"])   # south row, open at the lane
		regions.append([c[0], c[1], c[2], c[3], "asphalt", lines])
	# the mews' two mouths: stop bar on the exit half (right-hand traffic), the flare of the apron's kerb, centre line
	var mouths := [
		[X0, MEWS[0], X0 + 3.4, MEWS[1], "asphalt", [[X0, -1461.0, X0 + 2.8, -1460.0, "concrete"], [X0, -1454.0, X0 + 2.8, -1453.0, "concrete"],
			[X0 + 3.0, -1461.0, X0 + 3.4, -1457.08, "white"]]],
		[X1 - 3.4, MEWS[0], X1, MEWS[1], "asphalt", [[X1 - 2.8, -1461.0, X1, -1460.0, "concrete"], [X1 - 2.8, -1454.0, X1, -1453.0, "concrete"],
			[X1 - 3.4, -1456.92, X1 - 3.0, -1453.0, "white"]]],
		[X0 + 3.4, -1457.08, X1 - 3.4, -1456.92, "asphalt", [[X0 + 3.4, -1457.08, X1 - 3.4, -1456.92, "yellow"]]],
	]
	regions.append_array(mouths)
	# the townhouse front strips (garage driveways and door paths cut them into many short pieces: painted on their own)
	# and the bay row's front-garden strip (door paths, the cafe terrace)
	var sn: Array = [[LANE_W[0], -1466.7, LANE_W[1], MEWS[0], "asphalt"], [LANE_E[0], -1466.7, LANE_E[1], MEWS[0], "asphalt"]]
	var ss: Array = [[-232.0, MEWS[1], -229.0, -1447.3, "concrete"]]      # Mews Corner's walk crosses the south strip
	for b: Array in B:
		if not TH_GARAGE.has(String(b[1])): continue
		var north := absf(float(b[4])) < 1.0
		var za := -1466.7 if north else MEWS[1]; var zb := MEWS[0] if north else -1447.3
		for a: float in TH_GARAGE[String(b[1])]:
			var u := ua(b, a); (sn if north else ss).append([u - 1.6, za, u + 1.6, zb, "concrete"])      # a driveway at every garage
		for d: Array in TH_DOORS[String(b[1])]:
			var u0 := ua(b, float(d[0])); var u1 := ua(b, float(d[1])); (sn if north else ss).append([minf(u0, u1), za, maxf(u0, u1), zb, "plaza"])   # the door path
	var sb: Array = [[-312.0, -1583.7, -288.0, -1574.3, "plaza"]]          # the Bayfront Cafe's terrace
	for i in 5:          # the bay row's door paths: doors in pairs at along -7.95/-6.45, -0.75/0.75, 6.45/7.95 (yaw 180: u = cu - along)
		var b: Array = B[i]
		if String(b[1]).ends_with("beach_condo"): continue
		for a: float in [-7.2, 0.0, 7.2]: sb.append([ua(b, a) - 1.0, -1583.7, ua(b, a) + 1.0, -1574.3, "plaza"])
	regions.append([X0, -1466.7, X1, MEWS[0], "grass", sn])
	regions.append([X0, MEWS[1], X1, -1447.3, "grass", ss])
	regions.append([X0, -1583.7, X1, -1574.3, "grass", sb])
	var main: Array = []
	for r: Array in regions: main.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: main.append(H.pad_rect(fp(b)))
	main.append([TOT[0], TOT[1], TOT[2], TOT[3], "-"])
	main.append_array([
		[X0, MEWS[0], X1, MEWS[1], "asphalt"],                              # Crown Mews
		[LANE_W[0], -1530.0, LANE_W[1], MEWS[0], "asphalt"],               # the west lane
		[LANE_E[0], -1530.0, LANE_E[1], MEWS[0], "asphalt"],               # the east lane
		[-386.0, -1548.0, -380.0, -1530.0, "concrete"],                    # the west court's bin corner
		[-220.0, -1548.0, -214.0, -1530.0, "concrete"],                    # the east court's bin corner
		[-322.0, -1548.0, -278.0, -1530.0, "plaza"],                       # the Bay Court (picnic, grill, shade)
		[-301.0, -1559.4, -299.0, -1548.0, "plaza"],                       # the condo's back door to the court
		[-350.0, -1499.0, -250.0, -1497.0, "concrete"],                    # the green's cross path, lane to lane
		[-301.0, -1530.0, -299.0, -1499.0, "concrete"],                    # ... and its path up to the Bay Court
		[X0, Z0, X1, -1583.7, "plaza"],                                    # the front walk along the bay
		[-232.0, -1428.0, X1, Z1, "plaza"],                                # Mews Corner at the arterial junction
		[-232.0, -1447.3, -229.0, -1428.0, "concrete"],                    # ... its walk from the mews
	])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf, 1.0)
	H.paint(g, X0, Z0, X1, Z1, main, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	H.level_pad(g, "mulch", TOT[0], TOT[1], TOT[2], TOT[3], tot_y, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf, tot_y)
	H.finish(root, g, props, dec, "n_fw_bay")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, tot_y: float) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var T := func(base: String, cond: String, x: float, z: float, yaw := 0.0) -> void: props.add(base, cond, Vector3(x, tot_y, z), yaw)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the bay walk: globe lamps on the lawn edge, benches facing the bay between the buildings, the cafe terrace
	for x: float in [-386.0, -352.1, -316.5, -283.2, -247.1, -213.5]: P.call("prop_lamp_globe", "worn", x, -1583.2)     # pedestrian light on the bay walk, one per lawn gap
	P.call("prop_park_bench", "worn", -354.6, -1582.9, 180.0)          # facing the bay across the ring, between bay_1 and bay_2
	P.call("prop_park_bench", "worn", -319.0, -1582.9, 180.0)          # between bay_2 and the condo
	P.call("prop_park_bench", "worn", -280.7, -1582.9, 180.0)          # between the condo and bay_4
	P.call("prop_park_bench", "worn", -244.6, -1582.9, 180.0)          # between bay_4 and bay_5
	P.call("prop_patio_set_4", "worn", -307.0, -1577.6, 0.0)           # Bayfront Cafe: tables either side of its door path
	P.call("prop_patio_set_4", "worn", -307.0, -1581.2, 15.0)
	P.call("prop_patio_set_4", "worn", -293.0, -1577.6, 0.0)
	P.call("prop_patio_set_4", "worn", -293.0, -1581.2, -10.0)
	P.call("plant_potted_leafy", "normal", -310.6, -1575.1, 0.0)       # planters framing the terrace against the facade
	P.call("plant_potted_leafy", "normal", -289.4, -1575.1, 0.0)
	P.call("prop_newspaper_box_red", "worn", -297.4, -1583.3, 180.0)   # the morning paper for the coffee drinkers, at the walk
	P.call("prop_bike_rack", "worn", -315.5, -1580.0, 90.0)            # cyclists on the bay route stop for coffee
	P.call("prop_mailbox_post_metal", "worn", -360.2, -1582.9, 180.0)  # the bay row's mail at the walk
	P.call("prop_mailbox_post_metal", "worn", -359.6, -1582.9, 180.0)
	P.call("prop_mailbox_post_metal", "worn", -249.8, -1582.9, 180.0)
	P.call("plant_iceplant_patch", "normal", -370.0, -1578.5, 0.0, false)   # ground cover in the front lawns (walked over)
	P.call("plant_iceplant_patch", "normal", -265.0, -1578.5, 0.0, false)
	P.call("plant_bird_of_paradise", "normal", -384.0, -1576.0, 0.0)   # coastal planting at the row's ends
	P.call("plant_bird_of_paradise", "normal", -214.0, -1576.0, 0.0)
	P.call("plant_agave_americana", "normal", -339.0, -1579.0, 0.0)
	P.call("plant_agave_americana", "normal", -226.0, -1579.0, 0.0)
	# ---- behind the bay row: the rear lawns (washing lines, a grill), the condo's back door, the bins
	P.call("prop_clothesline", "clean", -370.0, -1555.0, 0.0)          # bay_1's drying line on its rear lawn
	P.call("prop_clothesline", "clean", -230.0, -1555.0, 0.0)          # bay_5's
	P.call("prop_bbq_kettle", "worn", -340.0, -1556.0, 0.0)            # bay_2's residents grill on the rear lawn
	P.call("prop_picnic_table", "worn", -334.0, -1555.5, 90.0)         # ... and eat beside it
	# the bins of each court in a closed enclosure at the court's outer end: block walls on three sides, a rolling
	# chainlink gate on the court side (closed: every wall end meets a wall or the gate)
	for e: Array in [[-386.0, -382.0, 90.0], [-214.0, -218.0, -90.0]]:
		var xw: float = e[0]; var xg: float = e[1]
		P.call("prop_dumpster_3yd_green", "worn", xw + signf(xg - xw) * 1.4, -1546.5, float(e[2]))   # general waste
		P.call("prop_dumpster_3yd_blue", "worn", xw + signf(xg - xw) * 1.4, -1543.5, float(e[2]))    # recycling
		H.fence(props, "fence_cmu_wall", "", Vector2(xw, -1547.9), Vector2(xw, -1542.1), yf, 2.03, "worn")
		H.fence(props, "fence_cmu_wall", "", Vector2(xw, -1547.9), Vector2(xg, -1547.9), yf, 2.03, "worn")
		H.fence(props, "fence_cmu_wall", "", Vector2(xw, -1542.1), Vector2(xg, -1542.1), yf, 2.03, "worn")
		H.fence(props, "fence_gate_rolling_chainlink", "", Vector2(xg, -1547.9), Vector2(xg, -1542.1), yf, 5.8, "worn")
	# ---- the parking courts: wheel stops at every stall, lot lights at the ends, a little oil where cars stand
	for c: Array in [COURT_W, COURT_E]:
		var lane: Array = LANE_W if c == COURT_W else LANE_E
		for k in 21:
			var x := float(c[0]) + 1.35 + 2.7 * k
			if x > float(c[2]): break
			P.call("prop_wheel_stop_concrete", "clean", x, -1547.4, 0.0)
			if x < float(lane[0]) - 2.5 or x > float(lane[1]) + 2.5: P.call("prop_wheel_stop_concrete", "clean", x, -1530.6, 0.0)
	P.call("prop_lot_light_pole", "worn", -381.6, -1535.0, 90.0)       # court lights on the courts' outer ends
	P.call("prop_lot_light_pole", "worn", -218.4, -1535.0, -90.0)
	P.call("prop_lot_light_pole", "worn", -321.4, -1539.0, -90.0)      # ... and on the Bay Court's sides
	P.call("prop_lot_light_pole", "worn", -278.6, -1539.0, 90.0)
	for x: float in [-372.0, -343.65, -264.5, -232.4]: Wr.oil(dec, rr, Vector2(x, -1545.5), 0.0, yf, 0.5)
	for x: float in [-367.4, -332.3, -270.95, -229.7]: Wr.oil(dec, rr, Vector2(x, -1532.5), 0.0, yf, 0.5)
	# ---- the Bay Court: tables under a sail, a grill, the residents' benches round it
	P.call("prop_shade_sail", "worn", -310.0, -1539.0, 0.0, false)     # shade over the court's two tables
	P.call("prop_picnic_table", "worn", -311.5, -1539.0, 0.0)
	P.call("prop_picnic_table", "worn", -308.0, -1541.5, 90.0)
	P.call("prop_bbq_gas_cart", "worn", -316.5, -1546.6, 0.0)          # the shared grill at the court's back edge
	P.call("prop_park_bench", "worn", -290.0, -1546.8, 0.0)            # residents' bench facing the court
	P.call("prop_park_bench", "worn", -290.0, -1531.2, 180.0)
	P.call("prop_lamp_globe", "worn", -302.4, -1546.0)                 # light on the condo's back path
	P.call("plant_potted_succulent", "normal", -297.6, -1547.2, 0.0)
	# ---- the Mews Green: the tot lot on its bark pad, parents' benches facing it, the picnic lawn, a fountain
	T.call("prop_play_structure", "worn", -319.0, -1513.0, 90.0)       # the townhouse children's climbing frame
	T.call("prop_swing_set", "worn", -311.0, -1517.5, 0.0)
	T.call("prop_slide", "worn", -310.5, -1508.5, 90.0)
	P.call("prop_park_bench", "worn", -320.0, -1524.4, 0.0)            # parents watching the tot lot (facing south into it)
	P.call("prop_park_bench", "worn", -312.0, -1524.4, 0.0)
	P.call("prop_park_bench", "worn", -316.0, -1501.4, 180.0)          # ... and from the cross path's side
	P.call("prop_drinking_fountain", "worn", -302.4, -1512.0, 90.0)    # on the path, beside the play
	P.call("prop_picnic_table", "worn", -288.0, -1513.0, 0.0)          # the picnic lawn east of the path
	P.call("prop_picnic_table", "worn", -280.0, -1517.0, 30.0)
	P.call("prop_lamp_globe", "worn", -302.4, -1500.2)                 # where the paths cross
	P.call("prop_lamp_globe", "worn", -340.0, -1500.2)
	P.call("prop_lamp_globe", "worn", -262.0, -1500.2)
	P.call("prop_sprinkler_impact", "normal", -335.0, -1512.0, 0.0, false)
	P.call("prop_sprinkler_impact", "normal", -268.0, -1512.0, 0.0, false)
	# ---- Crown Mews: globe lamps in the gaps between the townhouses, stop signs at the mouths, mailboxes
	for x: float in [-359.3, -324.46, -300.02, -275.58, -240.66]: P.call("prop_lamp_globe", "worn", x, -1463.0)
	for x: float in [-363.81, -336.87, -309.93, -282.99, -256.05]: P.call("prop_lamp_globe", "worn", x, -1451.0)
	P.call("prop_sign_stop", "worn", X0 + 2.0, -1462.4, -90.0)        # leaving west (the north half), sign on the right
	P.call("prop_sign_stop", "worn", X1 - 2.0, -1451.6, 90.0)         # leaving east (the south half)
	for k in 3: P.call("prop_mailbox_post_metal", "worn", -386.4 + 0.6 * k, -1464.0, 0.0)   # the north row's mail at the west mouth
	Wr.lane_wear(dec, rr, -1457.0, X0 + 4.0, X1 - 4.0, false, yf)
	# ---- the townhouses: carts against a side wall by the front, condensers at the back corners, each back garden its
	#      own furniture; privacy fences round the back gardens (a post at every joint), a gate onto the green (north row)
	for i in range(5, B.size()):
		var b: Array = B[i]; var f := fp(b); var north := absf(float(b[4])) < 1.0
		var wd: Array = K.building_stats(String(b[1])).footprint_wd      # the walls' own box (the bbox adds eaves, porches)
		var xa := float(b[2]) - float(wd[0]) * 0.5; var xb := float(b[2]) + float(wd[0]) * 0.5
		var zf: float = f[3] if north else f[1]                              # the front line
		var zw := float(b[3]) - float(wd[1]) * 0.5 if north else float(b[3]) + float(wd[1]) * 0.5   # the back wall
		var zg: float = -1494.0 if north else -1418.0                        # the back fence
		var s := 1.0 if north else -1.0                                       # +1: front faces +v
		P.call("prop_trash_cart_black", "worn", f[0] - 0.55, zf - s * 1.2, 90.0)     # bins at the west side wall, by the front
		P.call("prop_trash_cart_blue", "worn", f[0] - 0.55, zf - s * 2.1, 90.0)
		P.call("prop_trash_cart_green", "worn", f[2] + 0.55, zf - s * 1.2, -90.0)    # the neighbour unit's green bin, east side
		P.call("prop_ac_condenser", "worn", f[0] - 0.65, zw + s * 1.2, 90.0)          # condensers at the back corners
		P.call("prop_ac_condenser", "worn", f[2] + 0.65, zw + s * 1.2, -90.0)
		# the back garden: side fences from the back wall's corners, the back fence (north row: a gate onto the green)
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(xa, zw), Vector2(xa, zg), yf, 2.01, "worn")
		H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(xb, zw), Vector2(xb, zg), yf, 2.01, "worn")
		var cm := float(b[2])
		if north:
			H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(xa, zg), Vector2(cm - 0.5525, zg), yf, 2.01, "worn")
			H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(cm + 0.5525, zg), Vector2(xb, zg), yf, 2.01, "worn")
			H.fence(props, "fence_gate_privacy", "", Vector2(cm - 0.5525, zg), Vector2(cm + 0.5525, zg), yf, 1.105, "worn")
		else:
			H.fence(props, "fence_wood_privacy", "fence_post_privacy", Vector2(xa, zg), Vector2(xb, zg), yf, 2.01, "worn")
	# back-garden furniture, unit by unit (the back patios at along -7.6/-7.0, 1.2/1.0, 5.2/5.0)
	var gardens := [
		["prop_patio_set_4", -380.0, -1486.0], ["prop_bbq_kettle", -366.0, -1484.5],          # tn_1: table and grill
		["prop_adirondack_wood", -343.0, -1486.0], ["prop_adirondack_white", -341.5, -1486.5], ["prop_bbq_gas_cart", -330.0, -1484.0],   # tn_2
		["prop_patio_set_4", -318.0, -1486.5], ["prop_clothesline", -308.0, -1489.0],         # tn_3: table, washing line
		["prop_patio_set_4", -294.0, -1486.0], ["prop_bbq_kettle", -282.0, -1484.5],          # tn_4
		["prop_adirondack_wood", -270.0, -1486.0], ["prop_patio_set_4", -258.0, -1486.5],     # tn_5
		["prop_bbq_gas_cart", -234.0, -1484.0], ["prop_patio_set_4", -222.0, -1486.5],        # tn_6
		["prop_patio_set_4", -383.0, -1428.0], ["prop_bbq_kettle", -372.0, -1429.5],          # ts_1
		["prop_clothesline", -350.0, -1424.0], ["prop_adirondack_white", -343.0, -1429.0],    # ts_2
		["prop_patio_set_4", -329.0, -1428.0], ["prop_bbq_gas_cart", -317.0, -1430.0],        # ts_3
		["prop_patio_set_4", -302.0, -1428.0], ["prop_adirondack_wood", -291.0, -1429.0],     # ts_4
		["prop_bbq_kettle", -275.0, -1429.5], ["prop_patio_set_4", -264.0, -1428.0],          # ts_5
		["prop_clothesline", -242.6, -1424.0], ["prop_patio_set_4", -249.0, -1429.0],         # ts_6
	]
	for it: Array in gardens: P.call(String(it[0]), "clean" if String(it[0]) == "prop_clothesline" else "worn", float(it[1]), float(it[2]), 0.0)
	# ---- Mews Corner: a bench toward the junction, the collection box and paper box, a lamp
	P.call("prop_park_bench", "worn", -222.0, -1420.0, 135.0)          # looking out at the busy corner
	P.call("prop_usps_collection_box", "worn", -230.6, -1416.0, 180.0) # the mews' post box on the arterial walk side
	P.call("prop_newspaper_box_blue", "worn", -229.6, -1416.0, 180.0)
	P.call("prop_lamp_victorian", "worn", -212.0, -1417.0)
	P.call("plant_bougainvillea_mound", "normal", -216.0, -1426.0, 0.0)
