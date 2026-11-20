extends SceneTree
## Piece n_fw_crest (north-west column, block C, Crown Hill's west slope, the high half): HILLCREST.
## u -390.8 .. -209.2 (the two side streets' walks), v -1185.7 (the v -1200 arterial's walk) .. -1009.2 (the v -1000
## street's walk). Placed at grid [0, 0, 0], yaw 0 (x = u, y = world height, z = v). Run once.
##
## WHY (planner): ZONING.md / zones.py "apt", "apartments climbing". The block's NE corner (10.15) is the highest point
## of the column, where the upper arterial tops Crown Hill's shoulder; the land falls 6 m west to the u -400 street and
## 2-4 m south. The arterial has no car openings; the side streets have two aprons each and the v -1000 street two:
## CREST LANE (v -1147 .. -1139) and GARDEN WAY (v -1061 .. -1053) cross the block between the side streets' aprons,
## and two short lanes come up from the v -1000 street's aprons to Garden Way.
##  - THE CREST (NE corner, the busiest and highest corner, the walk up from the bay ends here): CREST BAKERY (com_bakery)
##    and CREST CUTS hair salon (ck_svc_trade_1d) facing the arterial, a small paved terrace between them and the corner.
##  - along the arterial west of them: three garden apartments facing it, their stalls on Crest Lane behind; between
##    them and the shops the CREST STEPS pocket garden (benches looking down the arterial to the west).
##  - the middle: HILLCREST GARDENS, two apartment courts (two garden-apartment buildings each, facing Crest Lane and
##    Garden Way, their court garden on the slope between) and between the courts HILLCREST GREEN, the residents' lawn
##    with arbors, tables and benches.
##  - the south band on the v -1000 street: seven dingbat apartments (the island's 1960s walk-ups), front doors and
##    their outside stairs to the street, their residents' stalls on Garden Way behind.
## LAND (Yasin: "DONT FORGET TO TAKE THE LAND INTO CONSIDERATION"): the ground follows the land (n_fw_site.g); the drives
## follow it (Crest Lane at most ~3.9 %); each building on its own level pad at the highest ground under it, the field
## graded up to the pads at 6 %; the bakery terrace a level paved pad.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fw_site.gd")

const X0 := -390.8
const X1 := -209.2
const Z0 := -1185.7
const Z1 := -1009.2
const CREST := [-1147.0, -1139.0]          # Crest Lane (v)
const GARDEN := [-1061.0, -1053.0]         # Garden Way (v)
const LANE_W := [-346.0, -340.0]           # the lanes up from the v -1000 street's aprons (u)
const LANE_E := [-260.0, -254.0]

## [label, folder, centre u, centre v, yaw]
const B := [
	["bakery", "commercial/com_bakery", -222.0, -1171.83, 180.0],           # front on the arterial at v -1180; door u -225.26
	["salon", "ck/ck_svc_trade_1d", -240.0, -1174.0, 180.0],                # front v -1180; door u -237
	["crest_1", "apartments/apt_garden_cream", -365.0, -1171.9, 180.0],     # facing the arterial, front v -1178
	["crest_2", "apartments/apt_garden_mint", -330.0, -1171.9, 180.0],
	["crest_3", "apartments/apt_garden_cream", -295.0, -1171.9, 180.0],
	["hg_wn", "apartments/apt_garden_mint", -355.0, -1126.9, 180.0],        # Hillcrest Gardens west court: front on Crest Lane (v -1133)
	["hg_ws", "apartments/apt_garden_cream", -355.0, -1073.1, 0.0],         # ... and on Garden Way (v -1067)
	["hg_en", "apartments/apt_garden_cream", -245.0, -1126.9, 180.0],       # the east court
	["hg_es", "apartments/apt_garden_mint", -245.0, -1073.1, 0.0],
	["ding_1", "apartments/apt_dingbat_pink", -376.0, -1023.45, 0.0],       # dingbats facing the v -1000 street, front v -1015
	["ding_2", "apartments/apt_dingbat_teal", -358.0, -1023.45, 0.0],
	["ding_3", "apartments/apt_dingbat_teal", -326.0, -1023.45, 0.0],
	["ding_4", "apartments/apt_dingbat_pink", -307.0, -1023.45, 0.0],
	["ding_5", "apartments/apt_dingbat_teal", -288.0, -1023.45, 0.0],
	["ding_6", "apartments/apt_dingbat_pink", -240.0, -1023.45, 0.0],
	["ding_7", "apartments/apt_dingbat_teal", -222.0, -1023.45, 0.0],
]

var PY: Array = []

## SUPERCHECKER (20 Nov; Yasin: "be MUCH more prone to delete: any prop or road/ground mark with any finding or any
## doubt is deleted with its reason, no relocating"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/fw/area.json); every prop with a finding taken out (its reason on its line), every mark with a finding
## taken out, a collision box on each building column the checker measured with none. Applied after everything is
## placed (hs_fill_lib.sc_apply). Left: report-only kinds (wide_batch, empty_area, ground_step).
const SC := {
 "out": [
	["prop_trash_cart_black", -377.600, -1167.000, "bin_open: prop_trash_cart_black stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -342.600, -1167.000, "bin_open: prop_trash_cart_black stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -307.600, -1167.000, "bin_open: prop_trash_cart_black stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -367.600, -1131.000, "bin_open: prop_trash_cart_black stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -257.600, -1131.000, "bin_open: prop_trash_cart_black stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -232.700, -1030.000, "bin_open: prop_trash_cart_black stands in the open (1.3 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -214.700, -1030.000, "bin_open: prop_trash_cart_black stands in the open (1.3 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -377.600, -1168.000, "bin_open: prop_trash_cart_blue stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -342.600, -1168.000, "bin_open: prop_trash_cart_blue stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -307.600, -1168.000, "bin_open: prop_trash_cart_blue stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -232.700, -1031.000, "bin_open: prop_trash_cart_blue stands in the open (1.3 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -214.700, -1031.000, "bin_open: prop_trash_cart_blue stands in the open (1.3 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_green", -367.600, -1069.000, "bin_open: prop_trash_cart_green stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_green", -257.600, -1069.000, "bin_open: prop_trash_cart_green stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_park_bench", -262.000, -1181.400, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -352.800, -1100.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -242.800, -1100.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -308.000, -1103.400, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -292.000, -1103.400, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -308.000, -1096.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -292.000, -1096.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -312.000, -1118.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -288.000, -1084.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_garden_arbor", -316.000, -1100.000, "walk_narrow: prop_garden_arbor leaves 1.1 m of a 3.6 m wide walk"],
	["prop_garden_arbor", -284.000, -1100.000, "walk_narrow: prop_garden_arbor leaves 1.1 m of a 3.6 m wide walk"],
 ],
 "turn": [
 ],
 "decals": [
	[-368.175, -1064.247],   # wear: oil mark lies on grass
	[-368.175, -1064.247],   # oil_no_car: an oil mark on grass with no stall, garage or roll-up door near it
	[-308.781, -1063.872],   # oil_no_car: an oil mark on white with no stall, garage or roll-up door near it
 ],
 "boxes": [
	["Buildings/bakery", [2.23492, 1.49998, 6.77483, 0.48987, 2.99997, 0.49008]],
	["Buildings/bakery", [-0.01337, 1.49998, 6.87996, 0.16, 2.99997, 0.16]],
	["Buildings/salon", [-3.90002, 1.49997, 5.65, 0.16, 2.99993, 0.16]],
	["Buildings/salon", [-1.04006, 1.51495, 7.66, 0.20004, 3.02991, 0.2]],
	["Buildings/salon", [-4.96004, 1.51495, 7.66, 0.20004, 3.02991, 0.2]],
	["Buildings/salon", [-2.10007, 1.49997, 5.65, 0.16, 2.99993, 0.16]],
	["Buildings/crest_1", [-11.8703, 1.54998, 5.86491, 0.29992, 3.09995, 0.31015]],
	["Buildings/crest_1", [-3.60018, 1.69995, 5.6249, 0.25977, 2.80001, 0.28994]],
	["Buildings/crest_2", [-11.87015, 1.54996, 5.86491, 0.29997, 3.09991, 0.31015]],
	["Buildings/crest_2", [-3.60022, 1.69994, 5.6249, 0.25984, 2.79995, 0.28994]],
	["Buildings/crest_3", [-11.8703, 1.54998, 5.86491, 0.29992, 3.09995, 0.31015]],
	["Buildings/crest_3", [-3.60018, 1.69995, 5.6249, 0.25977, 2.80001, 0.28994]],
	["Buildings/hg_wn", [-11.87015, 1.54996, 5.86491, 0.29997, 3.09991, 0.31015]],
	["Buildings/hg_wn", [-3.60022, 1.69994, 5.6249, 0.25984, 2.79995, 0.28994]],
	["Buildings/hg_ws", [-11.8703, 1.54998, 5.86491, 0.29992, 3.09995, 0.31015]],
	["Buildings/hg_ws", [-3.60018, 1.69995, 5.6249, 0.25977, 2.80001, 0.28994]],
	["Buildings/hg_en", [-11.8703, 1.54998, 5.86491, 0.29992, 3.09995, 0.31015]],
	["Buildings/hg_en", [-3.60018, 1.69995, 5.6249, 0.25977, 2.80001, 0.28994]],
	["Buildings/hg_es", [-11.87015, 1.54996, 5.86491, 0.29997, 3.09991, 0.31015]],
	["Buildings/hg_es", [-3.60022, 1.69994, 5.6249, 0.25984, 2.79995, 0.28994]],
	["Buildings/ding_1", [-7.17506, 1.54997, 7.87486, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_1", [-7.17506, 1.54997, -9.07518, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_1", [-5.37513, 1.46666, -9.10013, 0.28993, 2.93332, 0.16]],
	["Buildings/ding_2", [-7.17506, 1.54997, 7.87486, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_2", [-7.17506, 1.54997, -9.07518, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_2", [-5.37513, 1.46666, -9.10013, 0.28993, 2.93332, 0.16]],
	["Buildings/ding_3", [-7.17506, 1.54997, 7.87486, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_3", [-7.17506, 1.54997, -9.07518, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_3", [-5.37513, 1.46666, -9.10013, 0.28993, 2.93332, 0.16]],
	["Buildings/ding_4", [-7.17506, 1.54997, 7.87486, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_4", [-7.17506, 1.54997, -9.07518, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_4", [-5.37513, 1.46666, -9.10013, 0.28993, 2.93332, 0.16]],
	["Buildings/ding_5", [-7.17506, 1.54997, 7.87486, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_5", [-7.17506, 1.54997, -9.07518, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_5", [-5.37513, 1.46666, -9.10013, 0.28993, 2.93332, 0.16]],
	["Buildings/ding_6", [-7.17506, 1.54997, 7.87486, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_6", [-7.17506, 1.54997, -9.07518, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_6", [-5.37513, 1.46666, -9.10013, 0.28993, 2.93332, 0.16]],
	["Buildings/ding_7", [-7.17506, 1.54997, 7.87486, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_7", [-7.17506, 1.54997, -9.07518, 0.28993, 3.09993, 0.29002]],
	["Buildings/ding_7", [-5.37513, 1.46666, -9.10013, 0.28993, 2.93332, 0.16]],
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
	if absf(yaw - 180.0) < 1.0: return [cu - float(x[1][0]), cv - float(x[1][2]), cu - float(x[0][0]), cv - float(x[0][2])]
	if absf(yaw - 90.0) < 1.0: return [cu + float(x[0][2]), cv - float(x[1][0]), cu + float(x[1][2]), cv - float(x[0][0])]
	return [cu - float(x[1][2]), cv + float(x[0][0]), cu - float(x[0][2]), cv + float(x[1][0])]
static func ua(b: Array, along: float) -> float: return float(b[2]) + along if absf(float(b[4])) < 1.0 else float(b[2]) - along

func _run() -> void:
	var root := Node3D.new(); root.name = "n_fw_crest"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_fw_crest")
	var yb := func(x: float, z: float) -> float: return S.g("C", x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var gr := S.graded(yb, pe)      # 6 % aprons, then a bank (n_fw_site.graded)
	var yf := func(x: float, z: float) -> float: return lerpf(float(yb.call(x, z)), float(gr.call(x, z)), smoothstep(0.0, 4.0, S.edge_d("C", x, z)))
	var regions: Array = []
	# stall rows (5.5 m, lines every 2.7 m) on the drives between the buildings: [u0, u1, z0, z1]
	var rows := [
		[-376.0, -283.0, -1152.5, CREST[0]],                                  # the arterial row's stalls (Crest Lane north side)
		[-386.0, -368.8, CREST[1], -1133.5], [-341.2, -258.8, CREST[1], -1133.5], [-231.2, -214.0, CREST[1], -1133.5],   # Crest Lane south side
		[-386.0, -368.8, -1066.5, GARDEN[0]], [-341.2, -258.8, -1066.5, GARDEN[0]], [-231.2, -214.0, -1066.5, GARDEN[0]], # Garden Way north side
		[-385.0, -347.6, GARDEN[1], -1047.5], [-338.6, -261.6, GARDEN[1], -1047.5], [-252.6, -214.0, GARDEN[1], -1047.5], # the dingbats' stalls
	]
	for r: Array in rows:
		var sl: Array = []
		var x := float(r[0])
		while x <= float(r[1]) + 0.01: sl.append([x - 0.05, r[2], x + 0.05, r[3], "white"]); x += 2.7
		regions.append([r[0], r[2], r[1], r[3], "asphalt", sl])
	# door paths in strips of their own, spanning each building's pad lines
	for b: Array in B:
		var f := fp(b); var m := String(b[1]); var sp: Array = []
		if m.contains("garden"):
			var north := absf(float(b[4])) > 1.0
			var za: float; var zb: float
			if b[0] == "crest_1" or b[0] == "crest_2" or b[0] == "crest_3": za = Z0; zb = f[1] - 0.3          # to the arterial walk
			elif north: za = CREST[1]; zb = f[1] - 0.3
			else: za = f[3] + 0.3; zb = GARDEN[0]
			for a: float in [-7.2, 0.0, 7.2]: sp.append([ua(b, a) - 1.0, za, ua(b, a) + 1.0, zb, "plaza"])   # door pairs at -7.95/-6.45, -0.75/0.75, 6.45/7.95
			regions.append([f[0] - 0.3, za, f[2] + 0.3, zb, "grass", sp])
		elif m.contains("dingbat"):
			for a: float in [-4.0, 4.0]: sp.append([ua(b, a) - 0.8, f[3] + 0.3, ua(b, a) + 0.8, Z1, "plaza"])   # the two front doors
			regions.append([f[0] - 0.3, f[3] + 0.3, f[2] + 0.3, Z1, "grass", sp])
	# the lanes' mouths on the v -1000 street: the apron kerb's flare
	for ln: Array in [LANE_W, LANE_E]:
		regions.append([float(ln[0]) - 1.0, Z1 - 2.8, float(ln[1]) + 1.0, Z1, "asphalt", [[float(ln[0]) - 1.0, Z1 - 2.8, float(ln[0]), Z1, "concrete"], [float(ln[1]), Z1 - 2.8, float(ln[1]) + 1.0, Z1, "concrete"]]])
	var main: Array = []
	for r: Array in regions: main.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: main.append(H.pad_rect(fp(b)))
	main.append_array([
		[X0, CREST[0], X1, CREST[1], "asphalt"],                            # Crest Lane
		[X0, GARDEN[0], X1, GARDEN[1], "asphalt"],                          # Garden Way
		[LANE_W[0], GARDEN[1], LANE_W[1], Z1, "asphalt"],                   # the lanes from the south aprons
		[LANE_E[0], GARDEN[1], LANE_E[1], Z1, "asphalt"],
		[-233.0, Z0, X1, -1180.3, "plaza"],                                 # the crest terrace before the bakery and salon
		[-246.3, Z0, -233.0, -1180.3, "plaza"],
		[-282.0, -1182.0, -248.0, -1168.0, "plaza"],                        # Crest Steps, the pocket garden's paving
		[-216.5, -1163.5, X1, -1152.5, "concrete"],                         # the shops' delivery corner (bakery's back)
		[-301.0, CREST[1], -299.0, GARDEN[0], "concrete"],                  # Hillcrest Green's walk, lane to lane
		[-318.0, -1102.0, -282.0, -1098.0, "plaza"],                        # ... its sitting square
		[-356.0, -1121.0, -354.0, -1079.0, "concrete"],                     # the west court's walk between its buildings
		[-246.0, -1121.0, -244.0, -1079.0, "concrete"],                     # the east court's
	])
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf, 2.0)
	# (superchecker "ground_step": where a patch's 2 m edge meets the field's own cuts the two sheets differ by up to
	# 13 cm on the banks) a 0.2 m face under every patch edge, so nobody looks under the upper sheet
	var lo := func(x: float, z: float) -> float: return float(yf.call(x, z)) - 0.2
	for r: Array in regions:
		for e: Array in [[r[0], r[1], r[2], r[1]], [r[0], r[3], r[2], r[3]], [r[0], r[1], r[0], r[3]], [r[2], r[1], r[2], r[3]]]:
			H.skirt(g, Vector2(e[0], e[1]), Vector2(e[2], e[3]), yf, "wall", lo)
	H.paint(g, X0, Z0, X1, Z1, main, "grass", yf)
	for i in B.size(): H.pad_at(g, fp(B[i]), float(PY[i]), yf)
	# closed front steps where a door path meets a pad standing over the graded ground (n_fw_site.door_steps)
	var nst := 0
	for i in B.size():
		var b: Array = B[i]; var m := String(b[1]); var ps: Array = []
		if m.ends_with("bakery"): ps = [[-225.26, 1.6]]
		elif m.ends_with("trade_1d"): ps = [[-237.0, 1.6]]
		elif m.contains("garden"): ps = [[ua(b, -7.2), 2.0], [ua(b, 0.0), 2.0], [ua(b, 7.2), 2.0]]
		else: ps = [[ua(b, -4.0), 1.6], [ua(b, 4.0), 1.6]]
		nst += S.door_steps(g, fp(b), float(b[4]), float(PY[i]), yf, ps)
	print("front steps: %d flights" % nst)
	if PASS >= 2: _build(bl, props, dec, rr, yf)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fw_crest")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the drives: stop signs at the mouths (exit half, right side), cobra lamps on the verges, lane wear
	P.call("prop_sign_stop", "worn", X0 + 2.0, CREST[0] - 1.4, -90.0)
	P.call("prop_sign_stop", "worn", X1 - 2.0, CREST[1] + 1.4, 90.0)
	P.call("prop_sign_stop", "worn", X0 + 2.0, GARDEN[0] - 1.4, -90.0)
	P.call("prop_sign_stop", "worn", X1 - 2.0, GARDEN[1] + 1.4, 90.0)
	P.call("prop_sign_stop", "worn", LANE_W[1] + 1.4, Z1 - 2.0, 0.0)     # the lanes leaving south onto the v -1000 street
	P.call("prop_sign_stop", "worn", LANE_E[1] + 1.4, Z1 - 2.0, 0.0)
	for x: float in [-365.0, -300.0, -245.0]: P.call("prop_lamp_cobra", "worn", x, CREST[1] + 0.6, 180.0)
	for x: float in [-365.0, -300.0, -245.0]: P.call("prop_lamp_cobra", "worn", x, GARDEN[0] - 0.6, 0.0)
	Wr.lane_wear(dec, rr, -1143.0, X0 + 4.0, X1 - 4.0, false, yf)
	Wr.lane_wear(dec, rr, -1057.0, X0 + 4.0, X1 - 4.0, false, yf)
	# ---- THE CREST: bakery and salon on the corner terrace
	P.call("prop_patio_set_4", "worn", -215.0, -1183.0, 0.0)          # bakery tables on the terrace, east of its door
	P.call("prop_patio_set_4", "worn", -219.0, -1183.4, 20.0)
	P.call("plant_potted_succulent", "normal", -228.9, -1180.7, 0.0)   # against the bakery front's west corner
	P.call("prop_bench_bus_stop", "worn", -242.0, -1184.6, 180.0)      # waiting at the salon's window, facing the arterial
	P.call("prop_newspaper_box_blue", "worn", -232.0, -1184.6, 180.0)
	P.call("prop_bike_rack", "worn", -249.0, -1183.5, 0.0)
	P.call("prop_lamp_victorian", "worn", -211.0, -1184.6)
	P.call("prop_dumpster_3yd_green", "worn", -212.0, -1158.0, -90.0)  # the bakery's bins in the delivery corner behind it
	P.call("prop_dumpster_3yd_blue", "worn", -212.0, -1155.0, -90.0)
	P.call("prop_ac_condenser", "worn", -233.4, -1168.0, -90.0)         # the salon's condenser on its side wall
	# ---- Crest Steps: benches looking west down the arterial, planting
	P.call("prop_park_bench", "worn", -270.0, -1181.4, 180.0)
	P.call("prop_park_bench", "worn", -262.0, -1181.4, 180.0)
	P.call("plant_bougainvillea_mound", "normal", -276.0, -1172.0, 0.0)
	P.call("plant_agave_americana", "normal", -256.0, -1172.0, 0.0)
	P.call("prop_lamp_globe", "worn", -266.0, -1176.0)
	# ---- the arterial apartments: mail at the front, carts at the backs by their stalls
	for cu: float in [-365.0, -330.0, -295.0]:
		P.call("prop_mailbox_post_metal", "worn", cu + 3.6, -1182.6, 180.0)
		P.call("prop_mailbox_post_metal", "worn", cu + 4.2, -1182.6, 180.0)
		P.call("prop_trash_cart_black", "worn", cu - 12.6, -1167.0, 90.0)
		P.call("prop_trash_cart_blue", "worn", cu - 12.6, -1168.0, 90.0)
	var x := -374.65
	while x < -283.0: P.call("prop_wheel_stop_concrete", "clean", x, -1151.9, 0.0); x += 2.7
	Wr.oil(dec, rr, Vector2(-350.35, -1150.0), 0.0, yf, 0.5)
	Wr.oil(dec, rr, Vector2(-312.55, -1150.0), 0.0, yf, 0.5)
	# ---- Hillcrest Gardens: each court its table, grill, washing, benches; condensers and carts at the buildings
	for cu: float in [-355.0, -245.0]:
		P.call("prop_picnic_table", "worn", cu - 7.0, -1108.0, 0.0)
		P.call("prop_bbq_kettle", "worn", cu - 3.5, -1109.0, 0.0)
		P.call("prop_clothesline", "clean", cu + 7.0, -1092.0, 0.0)
		P.call("prop_park_bench", "worn", cu + 2.2, -1100.0, -90.0)        # beside the court's walk, facing it
		P.call("prop_lamp_globe", "worn", cu - 1.6, -1100.0)
		P.call("prop_trash_cart_black", "worn", cu - 12.6, -1131.0, 90.0)
		P.call("prop_trash_cart_green", "worn", cu - 12.6, -1069.0, 90.0)
		P.call("prop_ac_condenser", "worn", cu + 12.5, -1124.0, -90.0)
		P.call("prop_ac_condenser", "worn", cu + 12.5, -1076.0, -90.0)
	for r: Array in [[-386.0, -368.8], [-341.2, -258.8], [-231.2, -214.0]]:
		x = float(r[0]) + 1.35
		while x < float(r[1]):
			P.call("prop_wheel_stop_concrete", "clean", x, -1133.9, 0.0); P.call("prop_wheel_stop_concrete", "clean", x, -1066.1, 0.0); x += 2.7
	for xx: float in [-373.3, -324.7, -279.1, -221.65]: Wr.oil(dec, rr, Vector2(xx, -1136.0), 0.0, yf, 0.5)
	for xx: float in [-367.9, -308.8, -270.95]: Wr.oil(dec, rr, Vector2(xx, -1064.0), 0.0, yf, 0.5)
	# ---- Hillcrest Green: arbors over the sitting square's ends, tables, benches facing the square, a fountain
	P.call("prop_garden_arbor", "worn", -316.0, -1100.0, 90.0)
	P.call("prop_garden_arbor", "worn", -284.0, -1100.0, 90.0)
	P.call("prop_park_bench", "worn", -308.0, -1103.4, 0.0)
	P.call("prop_park_bench", "worn", -292.0, -1103.4, 0.0)
	P.call("prop_park_bench", "worn", -308.0, -1096.6, 180.0)
	P.call("prop_park_bench", "worn", -292.0, -1096.6, 180.0)
	P.call("prop_picnic_table", "worn", -312.0, -1118.0, 0.0)
	P.call("prop_picnic_table", "worn", -288.0, -1084.0, 0.0)
	P.call("prop_drinking_fountain", "worn", -302.3, -1110.0, 90.0)
	P.call("prop_lamp_globe", "worn", -302.4, -1092.0)
	P.call("plant_bird_of_paradise", "normal", -318.0, -1088.0, 0.0)
	P.call("plant_bird_of_paradise", "normal", -282.0, -1114.0, 0.0)
	P.call("prop_sprinkler_impact", "normal", -312.0, -1090.0, 0.0, false)
	# ---- the dingbats: their stalls on Garden Way, carts by their side walls, mail at the front
	for r: Array in [[-385.0, -347.6], [-338.6, -261.6], [-252.6, -214.0]]:
		x = float(r[0]) + 1.35
		while x < float(r[1]): P.call("prop_wheel_stop_concrete", "clean", x, -1048.1, 0.0); x += 2.7
	for xx: float in [-375.55, -334.55, -297.0, -242.45]: Wr.oil(dec, rr, Vector2(xx, -1050.0), 0.0, yf, 0.5)
	for cu: float in [-376.0, -358.0, -326.0, -307.0, -288.0, -240.0, -222.0]:
		P.call("prop_trash_cart_black", "worn", cu + 7.3, -1030.0, -90.0)
		P.call("prop_trash_cart_blue", "worn", cu + 7.3, -1031.0, -90.0)
		P.call("prop_mailbox_post_metal", "worn", cu + 1.2, -1011.4, 0.0)
	P.call("prop_lamp_globe", "worn", -349.0, -1012.0)
	P.call("prop_lamp_globe", "worn", -263.0, -1012.0)
	P.call("prop_hydrant_red", "worn", -337.0, -1011.0, 0.0)
