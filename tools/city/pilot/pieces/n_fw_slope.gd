extends SceneTree
## Piece n_fw_slope (north-west column, block B, Crown Hill's west slope, the low half): HILLSIDE TERRACES.
## u -390.8 .. -209.2 (the two side streets' walks), v -1385.7 (the v -1400 arterial's walk) .. -1214.3 (the v -1200
## arterial's walk). Placed at grid [0, 0, 0], yaw 0 (x = u, y = world height, z = v). Run once.
##
## WHY (planner): ZONING.md / zones.py "apt": Crown Hill's west slope, "apartments climbing". The block falls 8 m from
## its SE corner (10.15, the arterial junction near the hill's top) to its NW corner (2.15, by the bay). Both arterials
## are busy and have no car openings; each side street has two aprons (54-60 m from its nodes): so two cross drives join
## them, HILLSIDE TERRACE (v -1347 .. -1339, rising 2.4 m) and SUMMIT TERRACE (v -1261 .. -1253, rising 5.6 m, at most
## 3.9 %), and every car place hangs off them.
##  - THE LOW CORNER (NW, flat, where the arterial from the bay meets the u -400 street): the neighbourhood's HILLTOP
##    MARKET and SUDS LAUNDROMAT side by side in one corner building (com_orange_corner, two shop doors), facing the
##    arterial's walk; their customer lot east of them off Hillside Terrace; deliveries at the back.
##  - along the lower arterial: four walk-up apartment buildings (ck_apt3_row3) facing it, their residents' stalls on
##    Hillside Terrace's north side behind them; at the NE corner (the arterial meets the u -200 street) CROWN HILL
##    COFFEE (com_cafe_seaside) for the people walking down to the bay.
##  - the middle band: three APARTMENT COURTS, each two garden-court buildings (apt_court_white) facing the two drives,
##    their shared court garden between them on the slope, stalls on the drives between the buildings.
##  - the top band: three small walk-ups (ck_apt3_row2) facing the upper arterial, and on the high SE corner CROWN HILL
##    LOOKOUT: a level deck with rails looking NW down the slope to the bay, benches, a playground on its own bark
##    terrace, picnic tables under a sail.
## LAND (Yasin: "DONT FORGET TO TAKE THE LAND INTO CONSIDERATION, build according to it"): the ground follows the land
## (n_fw_site.g, 5 cm over it, eased onto every walk within 12 m); the drives follow it; each building stands on its own
## level pad at the highest ground under it, the field graded up to it at 6 % (pads up to ~1 m over the slope below
## them: their faces are retaining walls); the lookout deck and the playground are level terraces with retaining faces.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fw_site.gd")

const X0 := -390.8
const X1 := -209.2
const Z0 := -1385.7
const Z1 := -1214.3
const LOW := [-1347.0, -1339.0]           # Hillside Terrace (v)
const UP := [-1261.0, -1253.0]            # Summit Terrace (v)
const LOT := [-360.0, -1376.0, -339.5, -1347.0]      # the market's customer lot (aisle u -351 .. -345)
const DECK := [-246.0, -1252.0, -212.0, -1226.0]     # the lookout deck (level, plaza)
const PLAY := [-288.0, -1250.0, -266.0, -1232.0]     # the playground's bark terrace

## [label, folder, centre u, centre v, yaw]
const B := [
	["market", "commercial/com_orange_corner", -370.0, -1371.83, 180.0],    # front on the arterial at v -1380; doors u -368.92 / -371.08
	["apt_n1", "ck/ck_apt3_row3", -322.0, -1372.0, 180.0],                  # walk-ups facing the arterial, front v -1378
	["apt_n2", "ck/ck_apt3_row3", -297.0, -1372.0, 180.0],
	["apt_n3", "ck/ck_apt3_row3", -272.0, -1372.0, 180.0],
	["apt_n4", "ck/ck_apt3_row3", -247.0, -1372.0, 180.0],
	["coffee", "commercial/com_cafe_seaside", -222.0, -1371.83, 180.0],     # front v -1380, door u -220.24
	["court_1l", "apartments/apt_court_white", -352.0, -1323.9, 180.0],     # the courts' lower buildings face Hillside Terrace (front v -1330)
	["court_2l", "apartments/apt_court_white", -296.0, -1323.9, 180.0],
	["court_3l", "apartments/apt_court_white", -240.0, -1323.9, 180.0],
	["court_1u", "apartments/apt_court_white", -352.0, -1276.1, 0.0],       # ... the upper ones face Summit Terrace (front v -1270)
	["court_2u", "apartments/apt_court_white", -296.0, -1276.1, 0.0],
	["court_3u", "apartments/apt_court_white", -240.0, -1276.1, 0.0],
	["apt_s1", "ck/ck_apt3_row2", -378.0, -1226.0, 0.0],                    # small walk-ups facing the upper arterial (front v -1220)
	["apt_s2", "ck/ck_apt3_row2", -358.0, -1226.0, 0.0],
	["apt_s3", "ck/ck_apt3_row2", -338.0, -1226.0, 0.0],
]

var PY: Array = []

## SUPERCHECKER (20 Nov; Yasin: "be MUCH more prone to delete: any prop or road/ground mark with any finding or any
## doubt is deleted with its reason, no relocating"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/fw/area.json); every prop with a finding taken out (its reason on its line), every mark with a finding
## taken out, a collision box on each building column the checker measured with none. Applied after everything is
## placed (hs_fill_lib.sc_apply). Left: report-only kinds (wide_batch, empty_area, ground_step).
const SC := {
 "out": [
	["prop_trash_receptacle", -363.900, -1381.600, "bin_open: prop_trash_receptacle stands in the open (2.8 m from a wall, 152.2 m from a fence)"],
	["prop_trash_receptacle", -226.300, -1380.700, "bin_open: prop_trash_receptacle stands in the open (2.3 m from a wall, 136.8 m from a fence)"],
	["prop_trash_cart_black", -331.600, -1364.000, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 122.3 m from a fence)"],
	["prop_trash_cart_black", -306.600, -1364.000, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 115.7 m from a fence)"],
	["prop_trash_cart_black", -281.600, -1364.000, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 114.2 m from a fence)"],
	["prop_trash_cart_black", -256.600, -1364.000, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 114.6 m from a fence)"],
	["prop_trash_cart_black", -362.100, -1328.000, "bin_open: prop_trash_cart_black stands in the open (1.7 m from a wall, 107.9 m from a fence)"],
	["prop_trash_cart_black", -306.100, -1328.000, "bin_open: prop_trash_cart_black stands in the open (1.7 m from a wall, 80.3 m from a fence)"],
	["prop_trash_cart_black", -250.100, -1328.000, "bin_open: prop_trash_cart_black stands in the open (1.7 m from a wall, 79.8 m from a fence)"],
	["prop_trash_cart_blue", -362.100, -1327.000, "bin_open: prop_trash_cart_blue stands in the open (1.7 m from a wall, 107.1 m from a fence)"],
	["prop_trash_cart_blue", -306.100, -1327.000, "bin_open: prop_trash_cart_blue stands in the open (1.7 m from a wall, 79.3 m from a fence)"],
	["prop_trash_cart_blue", -250.100, -1327.000, "bin_open: prop_trash_cart_blue stands in the open (1.7 m from a wall, 78.9 m from a fence)"],
	["prop_park_bench", -356.000, -1301.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -348.000, -1301.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -300.000, -1301.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -292.000, -1301.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -244.000, -1301.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -236.000, -1301.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -238.000, -1248.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -230.000, -1248.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -242.000, -1240.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -221.000, -1248.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -277.000, -1229.400, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -224.000, -1236.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -218.000, -1236.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_play_structure", -280.000, -1241.000, "no_reason: prop_play_structure stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_swing_set", -272.000, -1245.500, "no_reason: prop_swing_set stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_slide", -271.000, -1236.000, "no_reason: prop_slide stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_shade_sail", -221.000, -1236.000, "sail_over_nothing: a shade sail with no table, seat or play item under it"],
 ],
 "turn": [
 ],
 "decals": [
	[-328.892, -1264.060],   # oil_no_car: an oil mark on white with no stall, garage or roll-up door near it
 ],
 "boxes": [
	["Buildings/market", [2.10492, 1.49998, 6.77483, 0.48998, 2.99997, 0.49008]],
	["Buildings/market", [3.945, 1.49998, 6.87996, 0.16, 2.99997, 0.16]],
	["Buildings/market", [-1.88013, 1.49998, 6.77483, 0.16, 2.99997, 0.49008]],
	["Buildings/coffee", [1.02491, 1.49998, 6.87996, 0.16, 2.99996, 0.16]],
	["Buildings/court_1l", [9.46982, 1.54998, 5.86491, 0.30016, 3.09995, 0.31015]],
	["Buildings/court_2l", [9.46982, 1.54998, 5.86491, 0.30016, 3.09995, 0.31015]],
	["Buildings/court_3l", [9.46982, 1.54998, 5.86491, 0.30016, 3.09995, 0.31015]],
	["Buildings/court_1u", [9.46982, 1.54998, 5.86491, 0.30016, 3.09995, 0.31015]],
	["Buildings/court_2u", [9.46982, 1.54998, 5.86491, 0.30016, 3.09995, 0.31015]],
	["Buildings/court_3u", [9.46982, 1.54998, 5.86491, 0.30016, 3.09995, 0.31015]],
	["Buildings/apt_s1", [-3.81753, 0.59994, 7.05, 0.20498, 1.19988, 1.14001]],
	["Buildings/apt_s2", [-3.81753, 0.59994, 7.05, 0.20498, 1.19988, 1.14001]],
	["Buildings/apt_s3", [-3.81753, 0.59994, 7.05, 0.20498, 1.19988, 1.14001]],
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
	var root := Node3D.new(); root.name = "n_fw_slope"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_fw_slope")
	var yb := func(x: float, z: float) -> float: return S.g("B", x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var deck_y := H.pad_height([DECK[0] + 0.3, DECK[1] + 0.3, DECK[2] - 0.3, DECK[3] - 0.3], 0.0, yb)
	var play_y := H.pad_height([PLAY[0] + 0.3, PLAY[1] + 0.3, PLAY[2] - 0.3, PLAY[3] - 0.3], 0.0, yb)
	var gr := S.graded(yb, pe)      # 6 % aprons, then a bank (n_fw_site.graded)
	# the grading eases back onto the plain ground within 4 m of every walk (the street seams stay exact); the deck and
	# the playground are NOT graded to: they stand as terraces with retaining faces (the lookout's edge is a wall)
	var yf := func(x: float, z: float) -> float: return lerpf(float(yb.call(x, z)), float(gr.call(x, z)), smoothstep(0.0, 4.0, S.edge_d("B", x, z)))
	var regions: Array = []
	# the market lot: stalls both sides of its north-south aisle
	var ll: Array = []
	for k in 11:
		var z := -1376.0 + 2.7 * k
		ll.append([-360.0, z - 0.05, -354.5, z + 0.05, "white"]); ll.append([-345.0 + 0.5, z - 0.05, -339.5, z + 0.05, "white"])
	regions.append([LOT[0], LOT[1], LOT[2], LOT[3], "asphalt", ll])
	# stall rows on the drives (5.5 m deep, lines every 2.7 m), only between the buildings; [u0, u1, z0, z1]
	var rows := [
		[-332.0, -238.0, -1352.5, LOW[0]],            # the arterial walk-ups' stalls, Hillside Terrace north side
		[-385.0, -362.2, LOW[1], -1333.5], [-342.4, -306.2, LOW[1], -1333.5], [-286.4, -250.2, LOW[1], -1333.5], [-230.4, -214.0, LOW[1], -1333.5],
		[-385.0, -362.2, -1266.5, UP[0]], [-342.4, -306.2, -1266.5, UP[0]], [-286.4, -250.2, -1266.5, UP[0]], [-230.4, -214.0, -1266.5, UP[0]],
		[-386.0, -330.0, UP[1], -1247.5],             # the upper walk-ups' stalls, Summit Terrace south side
	]
	for r: Array in rows:
		var sl: Array = []
		var x := float(r[0])
		while x <= float(r[1]) + 0.01: sl.append([x - 0.05, r[2], x + 0.05, r[3], "white"]); x += 2.7
		regions.append([r[0], r[2], r[1], r[3], "asphalt", sl])
	# the door paths, painted in strips of their own (each strip spans its building's pad lines, so the field gets no
	# new cuts): the arterial walk-ups' fronts and backs, the courts' fronts, the upper walk-ups' fronts
	var fr: Array = []; var bk: Array = []
	for bb: Array in B:
		var f := fp(bb)
		if String(bb[1]) == "ck/ck_apt3_row3":
			for a: float in [-6.0, 0.0, 6.0]:
				fr.append([ua(bb, a) - 0.8, -1385.7, ua(bb, a) + 0.8, f[1] - 0.3, "plaza"])
				bk.append([ua(bb, a) - 0.8, f[3] + 0.3, ua(bb, a) + 0.8, -1352.5, "concrete"])
		elif String(bb[1]) == "ck/ck_apt3_row2":
			var sp: Array = []
			for a: float in [-3.0, 3.0]: sp.append([ua(bb, a) - 0.8, f[3] + 0.3, ua(bb, a) + 0.8, Z1, "plaza"])
			regions.append([f[0] - 0.3, f[3] + 0.3, f[2] + 0.3, Z1, "grass", sp])
		elif String(bb[1]) == "apartments/apt_court_white":
			var lower := absf(float(bb[4])) > 1.0
			var sp2: Array = []
			for a: float in [-4.2, 4.2]:          # door pairs at along -4.95/-3.45 and 3.45/4.95
				if lower: sp2.append([ua(bb, a) - 1.3, LOW[1], ua(bb, a) + 1.3, f[1] - 0.3, "plaza"])
				else: sp2.append([ua(bb, a) - 1.3, f[3] + 0.3, ua(bb, a) + 1.3, UP[0], "plaza"])
			if lower: regions.append([f[0] - 0.3, LOW[1], f[2] + 0.3, f[1] - 0.3, "grass", sp2])
			else: regions.append([f[0] - 0.3, f[3] + 0.3, f[2] + 0.3, UP[0], "grass", sp2])
	regions.append([-331.3, -1385.7, -237.7, -1378.3, "grass", fr])
	regions.append([-331.3, -1365.7, -237.7, -1352.5, "grass", bk])
	var main: Array = []
	for r: Array in regions: main.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: main.append(H.pad_rect(fp(b)))
	main.append([DECK[0], DECK[1], DECK[2], DECK[3], "-"]); main.append([PLAY[0], PLAY[1], PLAY[2], PLAY[3], "-"])
	main.append_array([
		[X0, LOW[0], X1, LOW[1], "asphalt"],                                # Hillside Terrace
		[X0, UP[0], X1, UP[1], "asphalt"],                                  # Summit Terrace
		[-351.0, -1376.0, -345.0, LOW[0], "asphalt"],                      # (the lot aisle is inside LOT's region)
		[-376.5, -1385.7, -363.5, -1380.3, "plaza"],                       # the market's forecourt to the arterial walk
		[-363.5, -1364.0, -360.0, -1358.0, "concrete"],                    # its delivery corner at the back (beside the lot)
		[-226.0, -1385.7, -209.2, -1380.3, "plaza"],                       # Crown Hill Coffee's terrace at the corner
		[-209.2 - 7.0, -1364.0, -209.2, -1347.0, "concrete"],             # the cafe's back walk down to Hillside Terrace
		[-245.0, -1253.0, -243.0, -1252.0, "plaza"],                       # the lookout's way in from Summit Terrace (to the deck)
		[-272.0, -1253.0, -270.0, -1250.0, "plaza"],                       # the playground's way in
		[-330.0, -1226.0, -288.0, -1224.0, "plaza"],                       # the upper walk from the walk-ups to the park
	])
	for b: Array in B:
		if String(b[1]) == "apartments/apt_court_white":
			var f := fp(b)
			if absf(float(b[4])) > 1.0: main.append([float(b[2]) - 1.0, f[3] + 0.3, float(b[2]) + 1.0, -1299.0, "concrete"])    # the court's walk up the slope
			else: main.append([float(b[2]) - 1.0, -1301.0, float(b[2]) + 1.0, f[1] - 0.3, "concrete"])
	for b: Array in B:
		if String(b[1]) == "apartments/apt_court_white" and absf(float(b[4])) > 1.0:
			main.append([float(b[2]) - 6.0, -1301.0, float(b[2]) + 6.0, -1299.0, "concrete"])   # the court's sitting path across
	for r: Array in regions: H.paint(g, r[0], r[1], r[2], r[3], r[5], String(r[4]), yf, 2.0)      # 2 m: the stall lines and paths cut them finer where needed
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
		if m.ends_with("orange_corner"): ps = [[-370.0, 3.6]]
		elif m.ends_with("cafe_seaside"): ps = [[-220.24, 1.6]]
		elif m == "ck/ck_apt3_row3": ps = [[ua(b, -6.0), 1.6], [ua(b, 0.0), 1.6], [ua(b, 6.0), 1.6]]
		elif m == "ck/ck_apt3_row2": ps = [[ua(b, -3.0), 1.6], [ua(b, 3.0), 1.6]]
		else: ps = [[ua(b, -4.2), 2.6], [ua(b, 4.2), 2.6]]
		nst += S.door_steps(g, fp(b), float(b[4]), float(PY[i]), yf, ps)
	print("front steps: %d flights" % nst)
	H.level_pad(g, "plaza", DECK[0], DECK[1], DECK[2], DECK[3], deck_y, yf)
	H.level_pad(g, "mulch", PLAY[0], PLAY[1], PLAY[2], PLAY[3], play_y, yf)
	# steps up onto the two terraces where their paths meet them (closed treads down to the ground)
	H.steps_z2(g, -244.0, 2.0, -1253.0, -1252.0, float(yf.call(-244.0, -1253.0)), deck_y, yf)
	H.steps_z2(g, -271.0, 2.0, -1253.0, -1250.0, float(yf.call(-271.0, -1253.0)), play_y, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf, deck_y, play_y)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fw_slope")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, deck_y: float, play_y: float) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var D := func(base: String, cond: String, x: float, z: float, yaw := 0.0) -> void: props.add(base, cond, Vector3(x, deck_y, z), yaw)
	var Q := func(base: String, cond: String, x: float, z: float, yaw := 0.0) -> void: props.add(base, cond, Vector3(x, play_y, z), yaw)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the drives: stop signs where they meet the side streets (on the exit half's right), lamps on the verges
	P.call("prop_sign_stop", "worn", X0 + 2.0, LOW[0] - 1.4, -90.0)
	P.call("prop_sign_stop", "worn", X1 - 2.0, LOW[1] + 1.4, 90.0)
	P.call("prop_sign_stop", "worn", X0 + 2.0, UP[0] - 1.4, -90.0)
	P.call("prop_sign_stop", "worn", X1 - 2.0, UP[1] + 1.4, 90.0)
	for x: float in [-372.0, -334.0, -296.0, -258.0, -222.0]: P.call("prop_lamp_cobra", "worn", x, LOW[1] + 0.6, 180.0)   # arm over the drive
	for x: float in [-372.0, -334.0, -296.0, -258.0, -222.0]: P.call("prop_lamp_cobra", "worn", x, UP[0] - 0.6, 0.0)
	Wr.lane_wear(dec, rr, -1343.0, X0 + 4.0, X1 - 4.0, false, yf)
	Wr.lane_wear(dec, rr, -1257.0, X0 + 4.0, X1 - 4.0, false, yf)
	# ---- the market and laundromat: forecourt life, the lot, deliveries at the back
	P.call("prop_newspaper_box_red", "worn", -376.0, -1381.0, 180.0)   # papers by the market door
	P.call("prop_ice_chest", "clean", -365.2, -1380.9, 180.0)          # the market's ice merchandiser against its front
	P.call("prop_bike_rack", "worn", -380.0, -1383.0, 0.0)              # for the people who walk or cycle from the bay
	P.call("prop_trash_receptacle", "worn", -363.9, -1381.6, 0.0)      # against the market's front corner
	P.call("prop_cart_corral", "clean", -357.2, -1368.0, 90.0)          # trolleys returned at the lot's head
	P.call("prop_dumpster_3yd_green", "worn", -361.9, -1361.0, 90.0)   # the market's bins in its delivery corner
	P.call("prop_lot_light_pole", "worn", -348.0, -1377.0, 0.0)        # the lot's light at the aisle's head
	for k in 10:
		P.call("prop_wheel_stop_concrete", "clean", -359.4, -1374.65 + 2.7 * k, 90.0)
		P.call("prop_wheel_stop_concrete", "clean", -340.1, -1374.65 + 2.7 * k, 90.0)
	Wr.oil(dec, rr, Vector2(-356.0, -1369.25), 90.0, yf, 0.5)
	Wr.oil(dec, rr, Vector2(-342.5, -1358.45), 90.0, yf, 0.5)
	# ---- the arterial walk-ups: bins at their backs by the stalls, condensers, a bench for the bus walkers
	for cu: float in [-322.0, -297.0, -272.0, -247.0]:
		P.call("prop_trash_cart_black", "worn", cu - 9.6, -1364.0, 90.0)       # against the west wall at the back
		P.call("prop_trash_cart_blue", "worn", cu - 9.6, -1365.0, 90.0)
		P.call("prop_ac_condenser", "worn", cu + 9.65, -1368.0, -90.0)          # condenser on the east wall
		P.call("prop_mailbox_wall_black", "worn", cu + 2.2, -1378.1, 180.0)     # mail beside the middle door
	for k in 35:
		P.call("prop_wheel_stop_concrete", "clean", -330.65 + 2.7 * k, -1351.9, 0.0)
	Wr.oil(dec, rr, Vector2(-306.35, -1350.0), 0.0, yf, 0.5)
	Wr.oil(dec, rr, Vector2(-268.55, -1350.0), 0.0, yf, 0.5)
	# ---- Crown Hill Coffee: tables on its corner terrace, planters, a rack
	P.call("prop_patio_set_4", "worn", -215.0, -1383.0, 0.0)
	P.call("prop_patio_set_4", "worn", -211.8, -1381.8, 30.0)
	P.call("prop_patio_set_4", "worn", -224.0, -1383.2, 0.0)
	P.call("plant_potted_succulent", "normal", -217.4, -1380.6, 0.0)
	P.call("prop_bike_rack", "worn", -230.0, -1382.0, 0.0)
	P.call("prop_trash_receptacle", "worn", -226.3, -1380.7, 0.0)      # against the cafe's west front corner
	# ---- the courts: each court garden its own life (tables, a grill, washing, benches on the sitting path)
	for cu: float in [-352.0, -296.0, -240.0]:
		P.call("prop_park_bench", "worn", cu - 4.0, -1301.6, 180.0)     # on the sitting path, facing down the slope to the bay
		P.call("prop_park_bench", "worn", cu + 4.0, -1301.6, 180.0)
		P.call("prop_picnic_table", "worn", cu - 7.0, -1310.0, 0.0)      # the court's table
		P.call("prop_bbq_kettle", "worn", cu - 3.5, -1311.0, 0.0)        # ... and grill
		P.call("prop_clothesline", "clean", cu + 7.0, -1291.0, 0.0)      # washing on the upper lawn
		P.call("prop_lamp_globe", "worn", cu + 1.6, -1306.0)             # light on the court's walk
		P.call("prop_trash_cart_black", "worn", cu - 10.1, -1328.0, 90.0)   # lower building's carts at its west wall, by the front
		P.call("prop_trash_cart_blue", "worn", cu - 10.1, -1327.0, 90.0)
		P.call("prop_trash_cart_black", "worn", cu - 9.6, -1272.0, 90.0)    # upper building's
		P.call("prop_ac_condenser", "worn", cu + 10.3, -1321.0, -90.0)
		P.call("prop_ac_condenser", "worn", cu + 10.3, -1279.0, -90.0)
	for r: Array in [[-385.0, -362.2], [-342.4, -306.2], [-286.4, -250.2], [-230.4, -214.0]]:
		var x := float(r[0]) + 1.35
		while x < float(r[1]):
			P.call("prop_wheel_stop_concrete", "clean", x, -1333.9 - 0.2, 0.0); P.call("prop_wheel_stop_concrete", "clean", x, -1266.1 + 0.2, 0.0); x += 2.7
	for x: float in [-375.55, -321.55, -267.55, -224.35]: Wr.oil(dec, rr, Vector2(x, -1336.2), 0.0, yf, 0.5)
	for x: float in [-372.85, -329.0, -275.65, -221.65]: Wr.oil(dec, rr, Vector2(x, -1263.8), 0.0, yf, 0.5)
	# ---- the upper walk-ups: stalls on Summit Terrace, carts at their sides, a bench at the walk
	for k in 20: P.call("prop_wheel_stop_concrete", "clean", -384.65 + 2.7 * k, -1247.9, 0.0)
	for cu: float in [-378.0, -358.0, -338.0]:
		P.call("prop_trash_cart_black", "worn", cu + 6.6, -1229.0, -90.0)
		P.call("prop_ac_condenser", "worn", cu + 6.6, -1225.0, -90.0)
	Wr.oil(dec, rr, Vector2(-365.75, -1249.8), 0.0, yf, 0.5)
	# ---- CROWN HILL LOOKOUT: the deck's rails on its open north and west edges, benches looking NW to the bay, a
	#      coin telescope is not in the kit: a drinking fountain and a bin against the rail end instead; the playground
	for x: float in [-244.0, -239.9, -235.8, -231.7, -227.6, -223.5, -219.4]: D.call("prop_prom_rail", "clean", x + 2.045, DECK[1] + 0.2, 0.0)
	for z: float in [-1251.8, -1247.7, -1243.6, -1239.5, -1235.4, -1231.3]: D.call("prop_prom_rail", "clean", DECK[0] + 0.2, z + 2.045, 90.0)
	D.call("prop_park_bench", "worn", -238.0, -1248.6, -135.0)          # looking NW down the slope to the bay
	D.call("prop_park_bench", "worn", -230.0, -1248.6, 180.0)
	D.call("prop_park_bench", "worn", -242.0, -1240.0, -90.0)
	D.call("prop_park_bench", "worn", -221.0, -1248.6, 180.0)
	D.call("prop_picnic_table", "worn", -224.0, -1236.0, 0.0)           # lunch at the top
	D.call("prop_picnic_table", "worn", -218.0, -1236.0, 0.0)
	D.call("prop_shade_sail", "worn", -221.0, -1236.0, 0.0)
	D.call("prop_drinking_fountain", "worn", -214.0, -1244.0, -90.0)
	D.call("prop_lamp_victorian", "worn", -235.0, -1230.0, 0.0)
	D.call("plant_potted_succulent", "normal", -244.6, -1228.0, 0.0)
	Q.call("prop_play_structure", "worn", -280.0, -1241.0, 90.0)
	Q.call("prop_swing_set", "worn", -272.0, -1245.5, 0.0)
	Q.call("prop_slide", "worn", -271.0, -1236.0, 90.0)
	P.call("prop_park_bench", "worn", -277.0, -1229.4, 180.0)          # parents on the upper walk, facing the play
	# the playground terrace stands up to 1.6 m over the slope on its north and west: an iron fence round it on the
	# terrace, the one way in at the steps from Summit Terrace (u -272 .. -270)
	var py := func(_x: float, _z: float) -> float: return play_y
	var fi := 0.2
	H.fence(props, "fence_wrought_iron", "fence_post_wrought_iron", Vector2(PLAY[0] + fi, PLAY[1] + fi), Vector2(-272.2, PLAY[1] + fi), py, 1.98, "worn")
	H.fence(props, "fence_wrought_iron", "fence_post_wrought_iron", Vector2(-269.8, PLAY[1] + fi), Vector2(PLAY[2] - fi, PLAY[1] + fi), py, 1.98, "worn")
	H.fence(props, "fence_wrought_iron", "fence_post_wrought_iron", Vector2(PLAY[0] + fi, PLAY[1] + fi), Vector2(PLAY[0] + fi, PLAY[3] - fi), py, 1.98, "worn")
	H.fence(props, "fence_wrought_iron", "fence_post_wrought_iron", Vector2(PLAY[2] - fi, PLAY[1] + fi), Vector2(PLAY[2] - fi, PLAY[3] - fi), py, 1.98, "worn")
	H.fence(props, "fence_wrought_iron", "fence_post_wrought_iron", Vector2(PLAY[0] + fi, PLAY[3] - fi), Vector2(PLAY[2] - fi, PLAY[3] - fi), py, 1.98, "worn")
	P.call("plant_bougainvillea_mound", "normal", -300.0, -1236.0, 0.0)
	P.call("plant_agave_americana", "normal", -256.0, -1230.0, 0.0)
