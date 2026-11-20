extends SceneTree
## Piece n_fw_court (north-west column, block D, the foot of Crown Hill's west slope by the civic band): CROWN COURT
## and CROWN HILL PARK. u -390.8 .. -209.2 (the side streets' walks), v -990.8 (the v -1000 street's walk) .. -809.2
## (the v -800 street's walk). Placed at grid [0, 0, 0], yaw 0 (x = u, y = world height, z = v). Run once.
##
## WHY (planner): ZONING.md / zones.py "apt" (the apartments climbing Crown Hill) down to v -880, then the civic band
## south of it (v > -880; the campus and the civic centre beyond the v -800 street). The block is nearly level (6.15 on
## three sides, rising to 8.15 at its NE corner). The families of the apartments above need a park; the civic band and
## the people walking to the campus pass its south side. Every side street has two aprons, so two N-S drives cross the
## block from the v -1000 street's aprons to the v -800 street's: PARK LANE (u -347 .. -339) and EAST LANE
## (u -261 .. -253), all parking on them.
##  - WEST: four walk-ups (ck_apt3_row3) facing the u -400 street; on the SW corner the CROWN HILL COMMUNITY CENTER
##    (civ_community_center: meetings, classes, the neighbourhood's hall) facing the v -800 street, its lot off Park Lane.
##  - MIDDLE: CROWN COURT, four garden apartments round a court garden (two facing the v -1000 street, two facing the
##    park), and south of them CROWN HILL PARK: the playground on its bark terrace, a picnic lawn under sails, benches
##    along the paths, the entry plaza from the v -800 street with bike racks.
##  - EAST: six walk-ups facing the u -200 street (Crown Hill's houses opposite), and on the SE corner the CROWN HILL
##    PHARMACY (ck_svc_trade_1d) facing the civic band.
## LAND: the ground follows the land (n_fw_site.g); every building on its own level pad at the highest ground under it,
## the field graded up to the pads at 6 %; the playground a level terrace.
const PASS := 2
const K := preload("res://tools/city/pilot/kit_lib.gd")
const Wr := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const S := preload("res://tools/city/pilot/pieces/n_fw_site.gd")

const X0 := -390.8
const X1 := -209.2
const Z0 := -990.8
const Z1 := -809.2
const PARK_LN := [-347.0, -339.0]          # Park Lane (u), from the north apron to the south apron
const EAST_LN := [-261.0, -253.0]          # East Lane (u)
const CLOT := [-386.0, -871.0, -347.0, -853.0]   # the community center's lot (aisle v -865 .. -859)
const PLAY := [-325.0, -872.0, -305.0, -852.0]   # the playground's bark terrace

## [label, folder, centre u, centre v, yaw]
const B := [
	["apt_w1", "ck/ck_apt3_row3", -378.0, -975.0, -90.0],                   # walk-ups facing the u -400 street (front u -384)
	["apt_w2", "ck/ck_apt3_row3", -378.0, -951.0, -90.0],
	["apt_w3", "ck/ck_apt3_row3", -378.0, -927.0, -90.0],
	["apt_w4", "ck/ck_apt3_row3", -378.0, -903.0, -90.0],
	["community", "civic/civ_community_center", -369.0, -826.95, 0.0],      # front on the v -800 street at v -816
	["court_nw", "apartments/apt_garden_cream", -318.0, -977.9, 180.0],     # Crown Court: facing the v -1000 street (front v -984)
	["court_ne", "apartments/apt_garden_mint", -282.0, -977.9, 180.0],
	["court_sw", "apartments/apt_garden_mint", -318.0, -918.1, 0.0],        # ... and facing the park (front v -912)
	["court_se", "apartments/apt_garden_cream", -282.0, -918.1, 0.0],
	["apt_e1", "ck/ck_apt3_row3", -222.0, -976.0, 90.0],                    # walk-ups facing the u -200 street (front u -216)
	["apt_e2", "ck/ck_apt3_row3", -222.0, -952.0, 90.0],
	["apt_e3", "ck/ck_apt3_row3", -222.0, -928.0, 90.0],
	["apt_e4", "ck/ck_apt3_row3", -222.0, -904.0, 90.0],
	["apt_e5", "ck/ck_apt3_row3", -222.0, -880.0, 90.0],
	["apt_e6", "ck/ck_apt3_row3", -222.0, -856.0, 90.0],
	["pharmacy", "ck/ck_svc_trade_1d", -228.0, -822.0, 0.0],                # front on the v -800 street at v -816, door u -231
]

var PY: Array = []

## SUPERCHECKER (20 Nov; Yasin: "be MUCH more prone to delete: any prop or road/ground mark with any finding or any
## doubt is deleted with its reason, no relocating"): tools/city/super/sc.py check on this piece (area layout
## OUT/fill/fw/area.json); every prop with a finding taken out (its reason on its line), every mark with a finding
## taken out, a collision box on each building column the checker measured with none. Applied after everything is
## placed (hs_fill_lib.sc_apply). Left: report-only kinds (wide_batch, empty_area, ground_step).
const SC := {
 "out": [
	["prop_shade_sail", -282.000, -880.000, "sail_over_nothing (second check): its table was taken out by the first"],
	["prop_trash_cart_black", -370.000, -984.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -370.000, -960.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -370.000, -936.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -370.000, -912.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -230.000, -985.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -230.000, -961.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -230.000, -937.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -230.000, -913.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -230.000, -889.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -230.000, -865.600, "bin_open: prop_trash_cart_black stands in the open (2.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -330.600, -972.000, "bin_open: prop_trash_cart_black stands in the open (2.3 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_black", -294.600, -972.000, "bin_open: prop_trash_cart_black stands in the open (2.3 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -369.000, -984.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -369.000, -960.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -369.000, -936.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -369.000, -912.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -231.000, -985.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -231.000, -961.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -231.000, -937.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -231.000, -913.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -231.000, -889.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_blue", -231.000, -865.600, "bin_open: prop_trash_cart_blue stands in the open (3.1 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_green", -330.600, -922.000, "bin_open: prop_trash_cart_green stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_trash_cart_green", -294.600, -922.000, "bin_open: prop_trash_cart_green stands in the open (1.8 m from a wall, 99.0 m from a fence)"],
	["prop_park_bench", -297.400, -948.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -315.000, -874.400, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -315.000, -849.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -302.600, -862.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -320.000, -842.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", -280.000, -842.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -290.000, -945.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", -282.000, -880.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_bbq_gas_cart", -286.000, -942.000, "no_reason: prop_bbq_gas_cart stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_play_structure", -318.000, -862.000, "no_reason: prop_play_structure stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_swing_set", -310.000, -867.000, "no_reason: prop_swing_set stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_slide", -309.500, -857.000, "no_reason: prop_slide stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_shade_sail", -282.000, -862.000, "sail_over_nothing: a shade sail with no table, seat or play item under it"],
 ],
 "turn": [
 ],
 "decals": [
	[-358.978, -868.258],   # oil_no_car: an oil mark on white with no stall, garage or roll-up door near it
 ],
 "boxes": [
	["Buildings/community", [0.83963, 1.69995, 6.70193, 0.16054, 2.80005, 0.16]],
	["Buildings/court_nw", [-11.8703, 1.54998, 5.86491, 0.29992, 3.09995, 0.31015]],
	["Buildings/court_nw", [-3.60018, 1.69995, 5.6249, 0.25977, 2.80001, 0.28994]],
	["Buildings/court_ne", [-11.87015, 1.54996, 5.86491, 0.29997, 3.09991, 0.31015]],
	["Buildings/court_ne", [-3.60022, 1.69994, 5.6249, 0.25984, 2.79995, 0.28994]],
	["Buildings/court_sw", [-11.87015, 1.54996, 5.86491, 0.29997, 3.09991, 0.31015]],
	["Buildings/court_sw", [-3.60022, 1.69994, 5.6249, 0.25984, 2.79995, 0.28994]],
	["Buildings/court_se", [-11.8703, 1.54998, 5.86491, 0.29992, 3.09995, 0.31015]],
	["Buildings/court_se", [-3.60018, 1.69995, 5.6249, 0.25977, 2.80001, 0.28994]],
	["Buildings/pharmacy", [-3.90002, 1.49997, 5.65, 0.16, 2.99993, 0.16]],
	["Buildings/pharmacy", [-1.04006, 1.51495, 7.66, 0.20004, 3.02991, 0.2]],
	["Buildings/pharmacy", [-4.96004, 1.51495, 7.66, 0.20004, 3.02991, 0.2]],
	["Buildings/pharmacy", [-2.10007, 1.49997, 5.65, 0.16, 2.99993, 0.16]],
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
## world position along the front of a building at `along`: yaw 0 u = cu + a; 180 u = cu - a; 90 v = cv - a; -90 v = cv + a
static func fa(b: Array, along: float) -> float:
	var y: float = b[4]
	if absf(y) < 1.0: return float(b[2]) + along
	if absf(y - 180.0) < 1.0: return float(b[2]) - along
	if absf(y - 90.0) < 1.0: return float(b[3]) - along
	return float(b[3]) + along

func _run() -> void:
	var root := Node3D.new(); root.name = "n_fw_court"
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := Wr.rng_for("n_fw_court")
	var yb := func(x: float, z: float) -> float: return S.g("D", x, z)
	var pe: Array = []
	for b: Array in B:
		PY.append(H.pad_height(fp(b), float(b[4]), yb)); pe.append(H.pad_entry(fp(b), float(PY[PY.size() - 1])))
	var play_y := H.pad_height([PLAY[0] + 0.3, PLAY[1] + 0.3, PLAY[2] - 0.3, PLAY[3] - 0.3], 0.0, yb)
	pe.append([PLAY[0], PLAY[1], PLAY[2], PLAY[3], play_y])
	var gr := S.graded(yb, pe)      # 6 % aprons, then a bank (n_fw_site.graded)
	var yf := func(x: float, z: float) -> float: return lerpf(float(yb.call(x, z)), float(gr.call(x, z)), smoothstep(0.0, 4.0, S.edge_d("D", x, z)))
	var regions: Array = []
	# stall rows: [u0, u1, v0, v1, along] (along "v": lines across v every 2.7 m; "u": lines across u)
	var rows := [
		[-352.5, -347.0, -985.0, -895.0, "v"],          # Park Lane west side: the west walk-ups' stalls
		[-339.0, -333.5, -972.0, -924.0, "v"],          # Park Lane east side: Crown Court's
		[-266.5, -261.0, -972.0, -924.0, "v"],          # East Lane west side: Crown Court's
		[-253.0, -247.5, -985.0, -846.0, "v"],          # East Lane east side: the east walk-ups'
		[-386.0, -871.0, -347.0, -865.0, "u"],          # the community center's lot, north row
		[-386.0, -859.0, -347.0, -853.0, "u"],          # ... south row
	]
	for r: Array in rows:
		var sl: Array = []
		if String(r[4]) == "v":
			var z := float(r[2])
			while z <= float(r[3]) + 0.01: sl.append([r[0], z - 0.05, r[1], z + 0.05, "white"]); z += 2.7
			regions.append([r[0], r[2], r[1], r[3], "asphalt", sl])
		else:
			var x := float(r[0])
			while x <= float(r[2]) - 0.5: sl.append([x - 0.05, r[1], x + 0.05, r[3], "white"]); x += 2.7
			regions.append([r[0], r[1], r[2], r[3], "asphalt", sl])
	# door paths in strips of their own (spanning each building's pad lines)
	for b: Array in B:
		var f := fp(b); var m := String(b[1]); var sp: Array = []
		if m == "ck/ck_apt3_row3":
			if float(b[4]) < 0.0:
				for a: float in [-6.0, 0.0, 6.0]: sp.append([X0, fa(b, a) - 0.8, f[0] - 0.3, fa(b, a) + 0.8, "plaza"])
				regions.append([X0, f[1] - 0.3, f[0] - 0.3, f[3] + 0.3, "grass", sp])
			else:
				for a: float in [-6.0, 0.0, 6.0]: sp.append([f[2] + 0.3, fa(b, a) - 0.8, X1, fa(b, a) + 0.8, "plaza"])
				regions.append([f[2] + 0.3, f[1] - 0.3, X1, f[3] + 0.3, "grass", sp])
		elif m.contains("garden"):
			var za: float; var zb: float
			if absf(float(b[4])) > 1.0: za = Z0; zb = f[1] - 0.3
			else: za = f[3] + 0.3; zb = -900.0
			for a: float in [-7.2, 0.0, 7.2]: sp.append([fa(b, a) - 1.0, za, fa(b, a) + 1.0, zb, "plaza"])
			regions.append([f[0] - 0.3, za, f[2] + 0.3, zb, "grass", sp])
	var main: Array = []
	for r: Array in regions: main.append([r[0], r[1], r[2], r[3], "-"])
	for b: Array in B: main.append(H.pad_rect(fp(b)))
	main.append([PLAY[0], PLAY[1], PLAY[2], PLAY[3], "-"])
	main.append_array([
		[PARK_LN[0], Z0, PARK_LN[1], Z1, "asphalt"],                         # Park Lane
		[EAST_LN[0], Z0, EAST_LN[1], Z1, "asphalt"],                         # East Lane
		[-386.0, -865.0, -347.0, -859.0, "asphalt"],                         # the community lot's aisle
		[-381.0, Z1 - 7.0, -357.0, Z1, "plaza"],                             # the community center's forecourt (front v -816)
		[-379.0, -853.0, -377.0, -835.0, "concrete"],                        # its back door walk from the lot (door u -378)
		[-333.0, -900.0, -267.0, -898.0, "concrete"],                        # the park's north path (Crown Court's door paths end on it)
		[-301.0, -898.0, -299.0, Z1, "concrete"],                            # the park's main walk from the v -800 street
		[-312.0, Z1 - 8.0, -288.0, Z1, "plaza"],                             # the park's entry plaza
		[-333.0, -846.0, -267.0, -844.0, "concrete"],                        # the park's cross path, lane to lane
		[-301.0, -969.0, -299.0, -927.0, "concrete"],                        # Crown Court's walk between its buildings
		[-234.0, Z1 - 7.0, -222.0, Z1, "plaza"],                             # the pharmacy's forecourt
		[-221.0, -831.0, X1, -822.0, "concrete"],                            # its delivery corner on the side
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
		if m == "ck/ck_apt3_row3": ps = [[fa(b, -6.0), 1.6], [fa(b, 0.0), 1.6], [fa(b, 6.0), 1.6]]
		elif m.contains("garden"): ps = [[fa(b, -7.2), 2.0], [fa(b, 0.0), 2.0], [fa(b, 7.2), 2.0]]
		elif m.contains("community"): ps = [[-369.0, 2.0]]
		else: ps = [[-231.0, 1.6]]
		nst += S.door_steps(g, fp(b), float(b[4]), float(PY[i]), yf, ps)
	print("front steps: %d flights" % nst)
	H.level_pad(g, "mulch", PLAY[0], PLAY[1], PLAY[2], PLAY[3], play_y, yf)
	if PASS >= 2: _build(bl, props, dec, rr, yf, play_y)
	if PASS >= 2: H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fw_court")
	quit()

func _build(bl: Node3D, props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable, play_y: float) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	var Q := func(base: String, cond: String, x: float, z: float, yaw := 0.0) -> void: props.add(base, cond, Vector3(x, play_y, z), yaw)
	for i in B.size():
		var b: Array = B[i]
		K.building(bl, String(b[1]), Vector3(b[2], float(PY[i]), b[3]), float(b[4]), String(b[0]))
	# ---- the lanes: stop signs at both mouths (exit half, right side), lamps, wear
	P.call("prop_sign_stop", "worn", PARK_LN[0] - 1.4, Z0 + 2.0, 180.0)
	P.call("prop_sign_stop", "worn", PARK_LN[1] + 1.4, Z1 - 2.0, 0.0)
	P.call("prop_sign_stop", "worn", EAST_LN[0] - 1.4, Z0 + 2.0, 180.0)
	P.call("prop_sign_stop", "worn", EAST_LN[1] + 1.4, Z1 - 2.0, 0.0)
	for z: float in [-960.0, -910.0, -880.0, -830.0]: P.call("prop_lamp_cobra", "worn", PARK_LN[1] + 0.6, z, -90.0)
	for z: float in [-960.0, -910.0, -880.0, -830.0]: P.call("prop_lamp_cobra", "worn", EAST_LN[0] - 0.6, z, 90.0)
	Wr.lane_wear(dec, rr, -343.0, Z0 + 4.0, Z1 - 4.0, true, yf)
	Wr.lane_wear(dec, rr, -257.0, Z0 + 4.0, Z1 - 4.0, true, yf)
	# ---- wheel stops at the head of every stall, a little oil where cars stand
	var z := -985.0 + 1.35
	while z < -895.0: P.call("prop_wheel_stop_concrete", "clean", -351.9, z, 90.0); z += 2.7
	z = -972.0 + 1.35
	while z < -924.0: P.call("prop_wheel_stop_concrete", "clean", -334.1, z, 90.0); P.call("prop_wheel_stop_concrete", "clean", -265.9, z, 90.0); z += 2.7
	z = -985.0 + 1.35
	while z < -846.0: P.call("prop_wheel_stop_concrete", "clean", -248.1, z, 90.0); z += 2.7
	var x := -386.0 + 1.35
	while x < -347.5: P.call("prop_wheel_stop_concrete", "clean", x, -870.4, 0.0); P.call("prop_wheel_stop_concrete", "clean", x, -853.6, 0.0); x += 2.7
	for zz: float in [-966.1, -931.0, -906.7]: Wr.oil(dec, rr, Vector2(-350.0, zz), 90.0, yf, 0.5)
	for zz: float in [-950.0, -876.25]: Wr.oil(dec, rr, Vector2(-250.0, zz), 90.0, yf, 0.5)
	for xx: float in [-375.2, -359.0]: Wr.oil(dec, rr, Vector2(xx, -868.0), 0.0, yf, 0.5)
	P.call("prop_lot_light_pole", "worn", -387.5, -862.0, 90.0)          # the community lot's light at its west end
	# ---- the west and east walk-ups: carts at their back corners, condensers, mail at the middle door
	for cv: float in [-975.0, -951.0, -927.0, -903.0]:
		P.call("prop_trash_cart_black", "worn", -370.0, cv - 9.6, 0.0)
		P.call("prop_trash_cart_blue", "worn", -369.0, cv - 9.6, 0.0)
		P.call("prop_ac_condenser", "worn", -374.0, cv + 9.65, 180.0)
	for cv: float in [-976.0, -952.0, -928.0, -904.0, -880.0, -856.0]:
		P.call("prop_trash_cart_black", "worn", -230.0, cv - 9.6, 0.0)
		P.call("prop_trash_cart_blue", "worn", -231.0, cv - 9.6, 0.0)
		P.call("prop_ac_condenser", "worn", -226.0, cv + 9.65, 180.0)
	# ---- the community center: forecourt benches, notice of the place (bike racks, a bin at its wall), the lot's bins
	P.call("prop_park_bench", "worn", -378.0, -811.0, 0.0)               # facing the street, waiting for a lift
	P.call("prop_park_bench", "worn", -360.0, -811.0, 0.0)
	P.call("prop_bike_rack", "worn", -355.0, -813.0, 90.0)
	P.call("plant_potted_leafy", "normal", -374.0, -815.3, 0.0)          # framing the door against the front
	P.call("plant_potted_leafy", "normal", -364.0, -815.3, 0.0)
	P.call("prop_dumpster_3yd_green", "worn", -382.9, -840.0, 90.0)     # its bins against the hall's west flank, by the lot
	P.call("prop_usps_collection_box", "worn", -357.6, -811.0, 0.0)
	# ---- Crown Court's garden: table, grills, washing, benches by the walk
	P.call("prop_picnic_table", "worn", -310.0, -950.0, 0.0)
	P.call("prop_bbq_kettle", "worn", -306.0, -951.0, 0.0)
	P.call("prop_picnic_table", "worn", -290.0, -945.0, 90.0)
	P.call("prop_bbq_gas_cart", "worn", -286.0, -942.0, 0.0)
	P.call("prop_clothesline", "clean", -318.0, -939.0, 0.0)
	P.call("prop_clothesline", "clean", -282.0, -957.0, 0.0)
	P.call("prop_park_bench", "worn", -302.6, -948.0, -90.0)
	P.call("prop_park_bench", "worn", -297.4, -948.0, 90.0)
	P.call("prop_lamp_globe", "worn", -302.4, -960.0)
	P.call("prop_lamp_globe", "worn", -302.4, -936.0)
	for cu: float in [-318.0, -282.0]:
		P.call("prop_mailbox_post_metal", "worn", cu + 3.6, -988.6, 180.0)
		P.call("prop_trash_cart_black", "worn", cu - 12.6, -972.0, 90.0)
		P.call("prop_trash_cart_green", "worn", cu - 12.6, -922.0, 90.0)
	# ---- Crown Hill Park: the playground, parents' benches, the picnic lawn under sails, the entry plaza
	Q.call("prop_play_structure", "worn", -318.0, -862.0, 90.0)
	Q.call("prop_swing_set", "worn", -310.0, -867.0, 0.0)
	Q.call("prop_slide", "worn", -309.5, -857.0, 90.0)
	P.call("prop_park_bench", "worn", -315.0, -874.4, 0.0)               # parents facing into the playground
	P.call("prop_park_bench", "worn", -315.0, -849.6, 180.0)
	P.call("prop_park_bench", "worn", -302.6, -862.0, -90.0)             # on the main walk, facing the play
	P.call("prop_shade_sail", "worn", -282.0, -862.0, 0.0)               # the picnic lawn's shade
	P.call("prop_picnic_table", "worn", -283.5, -862.0, 0.0)
	P.call("prop_picnic_table", "worn", -280.0, -864.5, 90.0)
	P.call("prop_shade_sail", "worn", -282.0, -880.0, 0.0)
	P.call("prop_picnic_table", "worn", -282.0, -880.0, 0.0)
	P.call("prop_drinking_fountain", "worn", -297.6, -870.0, 90.0)
	P.call("prop_park_bench", "worn", -320.0, -842.6, 180.0)             # along the cross path, looking at the lawn
	P.call("prop_park_bench", "worn", -280.0, -842.6, 180.0)
	P.call("prop_park_bench", "worn", -320.0, -896.6, 180.0)             # along the north path, looking at the park
	P.call("prop_park_bench", "worn", -280.0, -896.6, 180.0)
	for xx: float in [-310.0, -290.0]: P.call("prop_bike_rack", "worn", xx, -812.0, 0.0)   # at the entry plaza
	P.call("prop_lamp_victorian", "worn", -303.0, -820.0)
	P.call("prop_lamp_victorian", "worn", -303.0, -880.0)
	P.call("prop_lamp_victorian", "worn", -303.0, -846.0 + 3.0)
	P.call("plant_bougainvillea_mound", "normal", -330.0, -830.0, 0.0)
	P.call("plant_bougainvillea_mound", "normal", -270.0, -830.0, 0.0)
	P.call("plant_agave_americana", "normal", -314.0, -816.0, 0.0)
	P.call("plant_agave_americana", "normal", -286.0, -816.0, 0.0)
	P.call("prop_sprinkler_impact", "normal", -320.0, -830.0, 0.0, false)
	P.call("prop_sprinkler_impact", "normal", -280.0, -890.0, 0.0, false)
	# ---- the pharmacy: a bench at its window, the paper box, its bins in the side corner
	P.call("prop_park_bench", "worn", -226.0, -811.0, 0.0)
	P.call("prop_newspaper_box_red", "worn", -233.0, -811.0, 0.0)
	P.call("prop_dumpster_3yd_blue", "worn", -212.0, -826.0, -90.0)
