extends SceneTree
## Piece n_fn_strip (fill_east fn): CROWN HILL GREENWAY, the 25 m strip between the Crown Hill house blocks (r_q_250_*,
## west, u 375) and the strip / gritty blocks (m_*, east, u 400). Two parts across the v -1200 arterial:
## north v -1385.7 (3rd St's south walk) .. -1214.3 (the arterial's north walk), south v -1185.7 .. -1009.2 (the
## v -1000 street's north walk). Placed at grid [0, 2.0, 0], yaw 0. Run once.
##
## WHY (planner): 25 m is too narrow for a block and has no car opening on any street (3rd St and the arterial have no
## aprons; nothing may be cut into the street pieces). But the house blocks' four rear alleys (from B Ave's aprons)
## run east and END on this strip's west line (v -1346 .. -1340, -1260 .. -1254, -1146 .. -1140, -1060 .. -1054).
## So: a GREENWAY for people on foot and bike from 3rd St (the bay) up the hill to the v -1000 street, between the
## houses' back fences and the shops' yards: one straight path down the middle, entry plazas at the three streets,
## and at each alley's end a small POCKET CAR PARK on the alley's own line (the cars come in by the alley, nowhere
## else), a COMMUNITY GARDEN for the houses next to it, a TOT LOT, picnic lawns, benches along the path.
## LAND: the strip's ground follows the land and the two neighbours: between them a sheet from the house side's
## height to the shop side's (smoothed over the houses' terrace steps), at least 2 cm over the land, eased onto each
## street walk within 6 m; along each neighbour a 1 m strip at that neighbour's own measured heights (its terrace
## steps included), with retaining faces down / up to the sheet (hs_fill_lib.edge_strip).
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const H := preload("res://tools/city/pilot/pieces/hs_fill_lib.gd")
const LAND := preload("res://tools/city/pilot/pieces/n_fn_sland.gd")
const PAD_Y := 2.0
const XL := 375.0
const XR := 400.0
const PATH := [386.0, 389.0]
## the neighbours' edges, measured 20 Nov on the city ground dump (OUT/fill/fn/segs.py): [v0, v1, h0, h1] world
const LN := [[-1385.70, -1353.90, 2.150, 2.150], [-1353.90, -1346.00, 2.566, 2.566], [-1346.00, -1340.00, 2.566, 2.741], [-1340.00, -1299.90, 2.741, 2.740], [-1299.90, -1278.80, 3.853, 4.166], [-1278.80, -1263.80, 4.166, 4.356], [-1263.80, -1254.00, 4.356, 4.453], [-1254.00, -1245.90, 4.453, 4.453], [-1245.90, -1214.30, 4.670, 4.670]]
const RN := [[-1385.70, -1381.80, 2.160, 2.346], [-1381.80, -1380.80, 2.346, 2.373], [-1380.80, -1352.80, 2.373, 3.017], [-1352.80, -1336.80, 3.017, 3.373], [-1336.80, -1320.80, 3.373, 3.717], [-1320.80, -1300.00, 3.717, 4.150], [-1300.00, -1214.30, 4.150, 4.150]]
const LS := [[-1185.70, -1153.90, 4.910, 4.910], [-1153.90, -1146.00, 4.642, 4.642], [-1146.00, -1139.90, 4.642, 4.667], [-1139.90, -1099.90, 5.010, 5.010], [-1099.90, -1078.80, 4.857, 4.956], [-1078.80, -1061.80, 4.956, 5.024], [-1061.80, -1054.20, 5.024, 5.049], [-1054.20, -1045.90, 5.049, 5.049], [-1045.90, -1009.20, 5.170, 5.170]]
const RS := [[-1185.70, -1100.00, 4.150, 4.150], [-1100.00, -1079.00, 4.150, 4.190], [-1079.00, -1061.20, 4.190, 4.239], [-1061.20, -1048.20, 4.239, 4.292], [-1048.20, -1040.20, 4.292, 4.336], [-1040.20, -1027.20, 4.336, 4.437], [-1027.20, -1022.20, 4.437, 4.491], [-1022.20, -1016.20, 4.491, 4.577], [-1016.20, -1014.20, 4.577, 4.616], [-1014.20, -1011.80, 4.616, 4.710], [-1011.80, -1009.20, 4.710, 4.748]]
## the street walks at the strip's ends (u -> world height), measured the same way
const W3RD := [[375.0, 2.15], [400.0, 2.15]]
const WART := [[375.0, 4.549], [380.0, 4.412], [385.0, 4.304], [390.0, 4.222], [395.0, 4.17], [400.0, 4.15]]
const W1000 := [[375.0, 5.105], [380.0, 5.033], [385.0, 4.96], [390.0, 4.888], [395.0, 4.818], [400.0, 4.749]]
## the parts: [v0, v1, left segs, right segs, north walk, south walk]
const PARTS := [[-1385.7, -1214.3, "N"], [-1185.7, -1009.2, "S"]]
## pocket car parks on the alleys' lines: [alley v0, alley v1]
const POCKETS := [[-1346.0, -1340.0], [-1260.0, -1254.0], [-1146.0, -1140.0], [-1060.0, -1054.0]]

const ITEMS := [
	# ---- 3rd St entry (north part's foot): benches either side of the path facing the street, a rack, a lamp
	["prop_park_bench", "worn", 380.0, -1381.0, 180.0], ["prop_park_bench", "worn", 395.0, -1381.0, 180.0],
	["prop_bike_rack", "worn", 380.5, -1376.0, 0.0], ["prop_lamp_globe", "worn", 385.3, -1379.0, 0.0],
	["plant_bougainvillea_mound", "normal", 396.0, -1372.0, 0.0],
	# ---- the community garden (v -1330 .. -1306): its arbor gate on the path, a hose reel cart, benches for the
	#      gardeners, the compost bins (green carts) against the arbor's side
	["prop_garden_arbor", "worn", 385.2, -1318.0, 90.0],
	["prop_hose_reel_cart", "worn", 383.5, -1307.5, 0.0],
	["prop_park_bench", "worn", 390.6, -1324.0, 90.0],
	["prop_trash_cart_green", "worn", 384.4, -1328.6, 0.0],
	["plant_bird_of_paradise", "normal", 397.5, -1310.0, 0.0],
	# ---- the tot lot (v -1294 .. -1274, east of the path): play structure and swings on the sand, the parents'
	#      benches facing it from the path side, a fountain
	["prop_play_structure", "worn", 394.0, -1288.0, 0.0], ["prop_swing_set", "worn", 394.5, -1279.0, 90.0],
	["prop_park_bench", "worn", 389.8, -1284.0, 90.0],
	["prop_drinking_fountain", "worn", 385.3, -1290.0, 0.0],
	["prop_park_bench", "worn", 380.0, -1284.0, -90.0],
	# ---- the lawn between the tot lot and the second pocket: picnic tables
	["prop_picnic_table", "worn", 380.0, -1270.0, 0.0], ["prop_picnic_table", "worn", 395.0, -1268.0, 0.0],
	# ---- the arterial entry (north part's head): benches, a lamp, planting
	["prop_park_bench", "worn", 380.0, -1218.6, 0.0], ["prop_park_bench", "worn", 395.0, -1218.6, 0.0],
	["prop_lamp_globe", "worn", 385.3, -1222.0, 0.0], ["plant_agave_americana", "normal", 380.0, -1232.0, 0.0],
	# ---- south part: entry from the arterial, a picnic lawn, the second garden, the head at the v -1000 street
	["prop_park_bench", "worn", 380.0, -1181.4, 180.0], ["prop_park_bench", "worn", 395.0, -1181.4, 180.0],
	["prop_lamp_globe", "worn", 385.3, -1176.0, 0.0],
	["prop_picnic_table", "worn", 380.0, -1165.0, 0.0], ["prop_picnic_table", "worn", 395.0, -1163.0, 90.0],
	["prop_bbq_kettle", "worn", 397.0, -1158.0, 0.0],
	["prop_garden_arbor", "worn", 385.2, -1118.0, 90.0], ["prop_hose_reel_cart", "worn", 383.5, -1107.5, 0.0],
	["prop_park_bench", "worn", 390.6, -1124.0, 90.0],
	["prop_lamp_globe", "worn", 385.3, -1090.0, 0.0],
	["prop_picnic_table", "worn", 380.0, -1085.0, 0.0], ["prop_park_bench", "worn", 395.0, -1078.0, -90.0],
	["prop_lamp_globe", "worn", 385.3, -1035.0, 0.0],
	["prop_park_bench", "worn", 380.0, -1013.6, 0.0], ["prop_park_bench", "worn", 395.0, -1013.6, 0.0],
	["plant_bougainvillea_mound", "normal", 396.0, -1030.0, 0.0],
	["prop_sprinkler_impact", "normal", 380.0, -1360.0, 0.0, false], ["prop_sprinkler_impact", "normal", 380.0, -1060.0 + 30.0, 0.0, false],
]

## SUPERCHECKER (20 Nov; the coordinator, Yasin's word: "be MUCH more prone to delete: any prop or road/ground mark with
## any finding or any doubt is deleted with its reason, no relocating attempts"): tools/city/super/sc.py check on this
## piece (area layout OUT/fill/fn/area.json). Every prop with a finding is taken out (its reason on its line); a
## collision box on each building column the checker measured without one. Every oil mark and lane-wear stripe was
## also taken out of the script itself (the checker found oil on the drive's centre line with no car near it).
const SC := {
 "out": [
	["prop_hose_reel_cart", 383.500, -1307.500, "hydrant_nowhere: prop_hose_reel_cart stands 23.2 m from any building wall and 3.0 m inside the block"],
	["prop_hose_reel_cart", 383.500, -1107.500, "hydrant_nowhere: prop_hose_reel_cart stands 19.3 m from any building wall and 3.0 m inside the block"],
	["prop_trash_cart_green", 384.400, -1328.600, "bin_open: prop_trash_cart_green stands in the open (12.6 m from a wall, 9.5 m from a fence)"],
	["prop_park_bench", 395.000, -1381.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 390.600, -1324.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 389.800, -1284.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 380.000, -1284.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 395.000, -1218.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 395.000, -1181.400, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 390.600, -1124.000, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_park_bench", 395.000, -1013.600, "no_reason: prop_park_bench stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_play_structure", 394.000, -1288.000, "no_reason: prop_play_structure stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_swing_set", 394.500, -1279.000, "no_reason: prop_swing_set stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 380.000, -1270.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 395.000, -1268.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 380.000, -1165.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 395.000, -1163.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_picnic_table", 380.000, -1085.000, "no_reason: prop_picnic_table stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
	["prop_bbq_kettle", 397.000, -1158.000, "no_reason: prop_bbq_kettle stands alone: no door within 18 m, no wall within 8 m, nothing to sit with"],
 ],
 "boxes": [

 ],
}

func _init() -> void: _run.call_deferred()

static func seg_h(segs: Array, v: float) -> float:
	for s: Array in segs:
		if v <= float(s[1]) + 1e-6: return lerpf(float(s[2]), float(s[3]), clampf((v - float(s[0])) / maxf(float(s[1]) - float(s[0]), 1e-6), 0.0, 1.0))
	return float(segs[segs.size() - 1][3])
## the house side smoothed over its terrace steps: linear between the middles of its segments
static func smooth(segs: Array, v: float) -> float:
	var pts: Array = []
	for s: Array in segs: pts.append([(float(s[0]) + float(s[1])) * 0.5, (float(s[2]) + float(s[3])) * 0.5])
	if v <= float(pts[0][0]): return float(pts[0][1])
	for i in pts.size() - 1:
		if v <= float(pts[i + 1][0]): return lerpf(float(pts[i][1]), float(pts[i + 1][1]), (v - float(pts[i][0])) / (float(pts[i + 1][0]) - float(pts[i][0])))
	return float(pts[pts.size() - 1][1])
static func tab(t: Array, x: float) -> float:
	if x <= float(t[0][0]): return float(t[0][1])
	for i in t.size() - 1:
		if x <= float(t[i + 1][0]): return lerpf(float(t[i][1]), float(t[i + 1][1]), (x - float(t[i][0])) / (float(t[i + 1][0]) - float(t[i][0])))
	return float(t[t.size() - 1][1])
## the field (local): house side -> shop side across, eased onto the street walks at both ends, >= land + 2 cm
static func field(u: float, v: float) -> float:
	var north := v < -1200.0
	var L: Array = LN if north else LS
	var R: Array = RN if north else RS
	var t := clampf((u - XL) / (XR - XL), 0.0, 1.0)
	var y := lerpf(smooth(L, v), seg_h(R, v), t)
	var v0 := -1385.7 if north else -1185.7
	var v1 := -1214.3 if north else -1009.2
	var wn: Array = W3RD if north else WART
	var ws: Array = WART if north else W1000
	y = lerpf(tab(wn, u), y, smoothstep(0.0, 6.0, v - v0))
	y = lerpf(tab(ws, u), y, smoothstep(0.0, 6.0, v1 - v))
	y = maxf(y, LAND.at(u, v) + 0.02)
	return y - PAD_Y

func _run() -> void:
	var root := Node3D.new(); root.name = "n_fn_strip"
	var g := K.Ground.new(); var props := K.Props.new(); var dec := K.Decals.new()
	var rr := W.rng_for("n_fn_strip")
	var yf := func(x: float, z: float) -> float: return field(x, z)
	for part: Array in PARTS:
		var v0: float = part[0]; var v1: float = part[1]
		var north := String(part[2]) == "N"
		var segsL: Array = []
		for s: Array in (LN if north else LS): segsL.append([s[0], s[1], float(s[2]) - PAD_Y, float(s[3]) - PAD_Y])
		var segsR: Array = []
		for s: Array in (RN if north else RS): segsR.append([s[0], s[1], float(s[2]) - PAD_Y, float(s[3]) - PAD_Y])
		var holes: Array = []
		holes.append_array(H.edge_strip(g, "v", XL, 1.0, segsL, yf, "grass", false))
		holes.append_array(H.edge_strip(g, "v", XR, -1.0, segsR, yf, "grass", false))
		var paints: Array = holes.duplicate()
		paints.append([XL + 1.0, v0, XR - 1.0, v0 + 6.0, "plaza"])          # entry plaza at the walk
		paints.append([XL + 1.0, v1 - 6.0, XR - 1.0, v1, "plaza"])          # entry plaza at the other walk
		for pk: Array in POCKETS:
			var a0: float = pk[0]; var a1: float = pk[1]
			if a0 < v0 or a1 > v1: continue
			# the pocket: the alley's aisle carried on to the path, stalls north and south of it either side of the path
			for x: float in [377.0, 379.7, 382.4, 385.1, 390.0, 392.7, 395.4, 398.1]:
				paints.append([x - 0.05, a0 - 5.5, x + 0.05, a0, "white"]); paints.append([x - 0.05, a1, x + 0.05, a1 + 5.5, "white"])
			for z: float in [a0 + 0.75, a0 + 1.75, a0 + 2.75, a0 + 3.75, a0 + 4.75]:
				paints.append([PATH[0], z - 0.25, PATH[1], z + 0.25, "white"])     # the path's zebra over the aisle
			paints.append([XL + 1.0, a0 - 5.5, XR - 1.0, a1 + 5.5, "asphalt"])
		paints.append([PATH[0], v0, PATH[1], v1, "plaza"])                  # THE GREENWAY PATH
		if north:
			paints.append([376.0, -1330.0, 385.0, -1306.0, "mulch"])        # the community garden's beds, west
			paints.append([390.0, -1330.0, 399.0, -1306.0, "mulch"])        # ... and east of the path
			# (the tot lot's sand went with its play items: superchecker no_reason, Yasin: be very prone to delete)
		else:
			paints.append([376.0, -1130.0, 385.0, -1106.0, "mulch"])        # the second garden
			paints.append([390.0, -1130.0, 399.0, -1106.0, "mulch"])
		H.paint(g, XL, v0, XR, v1, paints, "grass", yf, 1.0)
	_build(props, dec, rr, yf)
	H.polish(props, g, ITEMS)
	H.sc_apply(root, props, dec, SC)
	H.finish(root, g, props, dec, "n_fn_strip")
	quit()

func _build(props: K.Props, dec: K.Decals, rr: RandomNumberGenerator, yf: Callable) -> void:
	var P := func(base: String, cond: String, x: float, z: float, yaw := 0.0, collide := true) -> void: H.put(props, base, cond, x, z, yf, yaw, collide)
	for pk: Array in POCKETS:
		var a0: float = pk[0]; var a1: float = pk[1]
		# wheel stops at the stalls' heads; oil in two stalls of each pocket (the houses' second cars stand here)
		for x: float in [378.35, 381.05, 383.75, 391.35, 394.05, 396.75]:
			P.call("prop_wheel_stop_concrete", "worn", x, a0 - 4.9, 0.0)
			P.call("prop_wheel_stop_concrete", "worn", x, a1 + 4.9, 0.0)
		P.call("prop_sign_no_parking", "worn", 385.6, a0 - 6.0, 0.0)      # keep the path's crossing clear
		P.call("prop_lamp_globe", "worn", 389.6, a1 + 6.2, 0.0)
