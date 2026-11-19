extends SceneTree
## Piece n_cc_b3_main (city-centre fill, block 3, THE MAIN PART ON THE SLOPE; claude/fill-city-centre 19 Nov). Layout
## row (0, 6.0, -600), grid frame u = x, v = z - 600. Covers u 50..240.8, v -500..-409.2: from the apartment sample /
## the arm down to 8th St, from alley A3 to B Ave; alleys C3 (v -460..-454, from B Ave's apron) and B3 (u 190..196,
## a_sw's lane carried south to C3).
## LAND (read first, 19 Nov dump and zoning/terrain_grid.npz): the land rises from 6.1 (north-west) to 8.1 (south-east).
## 8th St's walk rises 6.26 -> 8.15 from u 52 to u 228 (table T8, every 4-8 m); B Ave's walk 6.15 -> 8.15 from v -500
## to v -420 (table TB, every 4 m); the arm, a_sw and alley A3 are at 6.15. GROUND: level pads and terraces, a
## retaining face on every step (terrain(): built where two lots meet more than 2 cm apart):
##  - 1.5 m seam strips on the north (z 100..101.5) and west (x 50..51) at the neighbours' heights, so the steps fall
##    inside this piece and its seams with n_cc_b3_arm / n_cc_b3_am / a_sw share one line of heights;
##  - alley C3 slopes from 6.15 (A3) to B Ave's apron height (linear in x); alley B3 slopes from 6.15 to C3;
##  - the rows north of C3 stand on pads at C3's height in front of each building, their yards behind on the same pad
##    (the retaining face toward the north strip is their garden wall); the raised residents' garden likewise;
##  - every 8th St building on a level pad at 8th St's height at its front middle; its yard behind ramps down to C3;
##  - the B Ave buildings on pads at B Ave's height at their front middle; the corner block at 8.15;
##  - the 0.5 m east of u 178 between the fronts and 8th St's walk (whose edge eases to v -409.2) follows the walk.
## PLANNER / ARCHITECT: 8th St climbs from the centre toward the apartment band: a continuous 3-4 storey wall of shops
## with flats over them that steps up with the street (a cafe on the alley corner, an Italian restaurant, a brick row of
## small shops, a fire-escape building, a stucco block, a hardware row, a bakery condo, a walk-up, a corner bar) and a
## 4-storey brick corner block (a pharmacy) on 8th x B Ave. B Ave: walk-up flats on pads that step with its rise.
## North of C3: flats, a framing workshop and garden apartments over the service lane, and a raised residents' garden
## (a terrace held by a retaining wall over the apartment sample's lawn: benches, a play corner, a shaded table).
## Run with CCF_STAGE=ground first. Draft: never when locked.
const L := preload("res://tools/city/pilot/pieces/cc_fill_lib.gd")
const O := Vector3(0.0, 6.0, -600.0)
const T8 := [[16.0, 0.15], [28.0, 0.153], [36.0, 0.172], [44.0, 0.206], [52.0, 0.255], [60.0, 0.316], [68.0, 0.39], [76.0, 0.473], [84.0, 0.566], [92.0, 0.666], [100.0, 0.772], [108.0, 0.882], [116.0, 0.996], [124.0, 1.112], [132.0, 1.228], [140.0, 1.343], [148.0, 1.456], [156.0, 1.565], [164.0, 1.669], [172.0, 1.767], [180.0, 1.856], [188.0, 1.937], [196.0, 2.006], [204.0, 2.064], [212.0, 2.107], [220.0, 2.136], [228.0, 2.149], [232.0, 2.15], [241.0, 2.15]]
const TB := [[100.0, 0.15], [104.0, 0.166], [108.0, 0.208], [112.0, 0.274], [116.0, 0.361], [120.0, 0.466], [124.0, 0.586], [128.0, 0.718], [132.0, 0.859], [136.0, 1.005], [140.0, 1.155], [144.0, 1.304], [148.0, 1.45], [152.0, 1.591], [156.0, 1.722], [160.0, 1.841], [164.0, 1.945], [168.0, 2.031], [172.0, 2.095], [176.0, 2.136], [180.0, 2.15], [191.0, 2.15]]
const NORTH := ["ck/ck_apt3_row3", "apartments/apt_garden_cream", "ck/ck_svc_trade", "modular/examples/mod_apt_row", "ck/ck_apt3_row3"]
const SOUTH := ["ck/ck_brk3_corner2", "apartments/apt_stucco3_peach", "urban/urb_brick_row", "ck/ck_brk3_row2_fe", "apartments/apt_stucco3_cream", "modular/examples/mod_brk_row", "ck/ck_brk3_row2", "apartments/apt_beach_condo", "ck/ck_apt3_row3", "ck/ck_brk3_corner2"]
func h8(x: float) -> float: return L.prof(T8, x)
func hb(z: float) -> float: return L.prof(TB, z)
func c3(x: float, z: float) -> float: return 0.15 + clampf((x - 50.0) / 190.8, 0.0, 1.0) * (hb(z) - 0.15)
func _nearest(plan: Array, cx: float) -> int:
	var best := 0
	for i in plan.size():
		if absf(float(plan[i][2]) - cx) < absf(float(plan[best][2]) - cx): best = i
	return best
func lvl(h: float) -> Callable: return func(_x: float, _z: float) -> float: return h
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var c := L.new("n_cc_b3_main")
	# ---- the lots (ground first)
	var lots: Array = []
	lots.append([50.0, 100.0, 240.8, 101.5, lvl(0.15)])                                          # north seam strip
	lots.append([50.0, 101.5, 51.0, 190.3, func(x: float, z: float) -> float: return 0.15 + (h8(x) - 0.15) * clampf((z - 172.0) / 18.3, 0.0, 1.0)])   # west seam strip (as alley A3)
	var np := c.row_plan(NORTH, 51.1, 1.0, "s")
	var xa := 51.0
	var npad: Array[float] = []
	for i in np.size():
		var xb: float = (float(np[i][1]) + float(np[i + 1][0])) * 0.5 if i < np.size() - 1 else float(np[i][1]) + 0.05
		npad.append(c3(xb, 140.0))       # the alley's HIGHEST point along the lot: the building is never sunk in it
		lots.append([xa, 101.5, xb, 140.0, lvl(npad[i])]); xa = xb
	lots.append([xa, 101.5, 190.0, 140.0, lvl(c3((xa + 190.0) * 0.5, 140.0))])                    # the raised residents' garden
	lots.append([190.0, 101.5, 196.0, 140.0, func(x: float, z: float) -> float: return 0.15 + (z - 101.5) / 38.5 * (c3(193.0, 140.0) - 0.15)])   # alley B3
	# B Ave buildings: a pad at the walk's HIGHEST point along the building (never under the walk), and in front of the
	# wall line a frontage strip that follows the walk exactly (flush); the plinth between strip and pad is the face
	for bl: Array in [[101.5, 119.85, "ck/ck_apt3_row3"], [119.85, 132.15, "ck/ck_apt3_row2"], [146.0, 158.35, "ck/ck_apt3_row2"], [158.35, 170.65, "ck/ck_apt3_row2"]]:
		var z0: float = bl[0]; var z1: float = bl[1]; var xf := 240.8 - L.setback(String(bl[2]))
		lots.append([196.0 if z1 < 140.0 else 225.0, z0, xf, z1, lvl(hb(z1))])
		if xf < 240.78: lots.append([xf, z0, 240.8, z1, func(_x: float, z: float) -> float: return hb(z)])
	lots.append([196.0, 132.15, 240.8, 140.0, c3])                                                 # alley C3's mouth widening: follows B Ave's walk at its end
	lots.append([51.0, 140.0, 240.8, 146.0, c3])                                                   # alley C3
	var sp := c.row_plan(SOUTH, 51.1, 1.0, "s")
	var spad: Array[float] = []
	xa = 51.0
	for i in sp.size():
		var xb2: float = (float(sp[i][1]) + float(sp[i + 1][0])) * 0.5 if i < sp.size() - 1 else float(sp[i][1]) + 0.05
		var pad := h8(xb2)               # 8th St's HIGHEST point along the lot (h8 rises east): never under the walk
		spad.append(pad)
		var zf := 190.3 - L.setback(String(SOUTH[i]))
		lots.append([xa, 171.5, xb2, zf, lvl(pad)])
		if zf < 190.28: lots.append([xa, zf, xb2, 190.3, func(x: float, _z: float) -> float: return h8(x)])   # frontage strip, flush with the walk
		var p2 := pad
		lots.append([xa, 146.0, xb2, 171.5, func(x: float, z: float) -> float: return lerpf(c3(x, 146.0), p2, (z - 146.0) / 25.5)])
		xa = xb2
	lots.append([xa, 146.0, 221.25, 190.3, func(x: float, z: float) -> float: return lerpf(c3(x, 146.0), h8(x), (z - 146.0) / 44.3)])   # the passage up to 8th St
	lots.append([221.25, 170.65, 240.7, 190.3, lvl(2.15)])
	lots.append([240.7, 170.65, 240.8, 190.3, func(_x: float, z: float) -> float: return hb(z)])     # flush with B Ave's walk in front of the corner block's side
	lots.append([221.25, 146.0, 225.0, 170.65, func(x: float, z: float) -> float: return lerpf(c3(x, 146.0), 2.15, (z - 146.0) / 24.65)])
	c.terrain(lots)
	c.skirt_depth = 0.6
	# 8th St's walk edge east of u 178 eases to v -409.2: the strip between the fronts and the walk follows the walk
	var tp := PackedVector2Array()
	for e: Vector2 in [Vector2(178.000, 190.3098), Vector2(178.500, 190.3215), Vector2(179.000, 190.3370), Vector2(179.500, 190.3561), Vector2(180.000, 190.3781), Vector2(180.500, 190.4028), Vector2(181.000, 190.4296), Vector2(181.500, 190.4582), Vector2(182.000, 190.4881), Vector2(182.500, 190.5188), Vector2(183.000, 190.5500), Vector2(183.500, 190.5812), Vector2(184.000, 190.6119), Vector2(184.500, 190.6418), Vector2(185.000, 190.6704), Vector2(185.500, 190.6972), Vector2(186.000, 190.7219), Vector2(186.500, 190.7439), Vector2(187.000, 190.7630), Vector2(187.500, 190.7785), Vector2(188.000, 190.7902), Vector2(188.500, 190.7975), Vector2(189.000, 190.8000), Vector2(192.727, 190.8000), Vector2(196.455, 190.8000), Vector2(200.182, 190.8000), Vector2(203.909, 190.8000), Vector2(207.636, 190.8000), Vector2(211.364, 190.8000), Vector2(215.091, 190.8000), Vector2(218.818, 190.8000), Vector2(222.545, 190.8000), Vector2(226.273, 190.8000), Vector2(230.000, 190.8000), Vector2(240.800, 190.8000)]: tp.append(e)
	c.edge_band("concrete", tp, 190.3, func(x: float, _z: float) -> float: return h8(x))
	c.paint("grass", float(np[np.size() - 1][1]) + 0.6, 102.0, 189.4, 139.4)                     # the raised garden
	c.paint("mulch", 168.0, 112.0, 180.0, 122.0)                                                  # its play corner on bark
	c.paint("plaza", 215.4, 146.0, 221.25, 190.3)                                                 # the passage
	c.build_floor(L.rect_edges(50.0, 100.0, 240.8, 190.3))
	if c.stage == "ground": c.finish(); quit(); return
	c.neighbours([["s_rs_b105_a", Vector3(0, 6, -400), 90.0], ["s_rs_b105_b", Vector3(250, 6, -400), -90.0], ["j_rs_3l1r_c", Vector3(250, 8, -400), 90.0],
		["s_rs_b051_b", Vector3(250, 8, -400), -180.0], ["a_sw", Vector3(250, 6, -600), 0.0], ["s_apt", Vector3(250, 6, -600), -180.0]], O)
	# ---- buildings, each at its lot's level
	var N := c.row(NORTH, ["c3n_walkup_w", "c3n_garden_apts", "c3n_framer", "c3n_apt_row", "c3n_walkup_e"], 51.1, 1.0, "s", 140.0, false, func(cx: float) -> float: return npad[_nearest(np, cx)])
	var S := c.row(SOUTH, ["eighth_corner_cafe", "eighth_trattoria_block", "eighth_brick_row", "eighth_records_fe", "eighth_stucco_block", "eighth_hardware_row", "eighth_optician", "eighth_bakery_condo", "eighth_walkup", "eighth_corner_bar"], 51.1, 1.0, "s", 190.3, false, func(cx: float) -> float: return spad[_nearest(sp, cx)])
	var y_keep := c.y0
	c.y0 = 2.15
	var CB: Dictionary = c.row(["urban/urb_brick_corner"], ["eighth_bave_pharmacy"], 240.7, -1.0, "s", 190.3)[0]
	c.y0 = hb(119.85); var BN1: Dictionary = c.row(["ck/ck_apt3_row3"], ["bave_n_walkup"], 101.6, 1.0, "e", 240.8)[0]
	c.y0 = hb(132.15); var BN2: Dictionary = c.row(["ck/ck_apt3_row2"], ["bave_n_walkup2"], 119.9, 1.0, "e", 240.8)[0]
	c.y0 = hb(158.35); var BS1: Dictionary = c.row(["ck/ck_apt3_row2"], ["bave_s_walkup"], 146.1, 1.0, "e", 240.8)[0]
	c.y0 = hb(170.65); var BS2: Dictionary = c.row(["ck/ck_apt3_row2"], ["bave_s_walkup2"], 158.4, 1.0, "e", 240.8)[0]
	c.y0 = y_keep
	# ---- 8th St side: pots at shop doors, racks, the passage
	for r: Dictionary in S + [CB]:
		for dr: Array in c.front_shops(r):
			var dp: Vector3 = dr[1]
			for s: float in [-1.2, 1.2]: c.put("plant_potted_succulent", "normal", Vector3(dp.x + s * 1.08, c.yf(dp.x + s * 1.08, dp.z + 0.4), dp.z + 0.4), 0.0, "shops: a pot either side of the door")
	c.put("prop_bike_rack", "worn", Vector3(216.6, c.yf(216.6, 160.0), 160.0), 90.0, "passage: bikes along the wall, off the way up")
	c.put("prop_park_bench", "worn", Vector3(220.4, c.yf(220.4, 176.0), 176.0), -90.0, "passage: a seat halfway up")
	c.put("prop_lamp_globe", "worn", Vector3(220.6, c.yf(220.6, 152.0), 152.0), 0.0, "passage: lit at night")
	# ---- services, yards
	for r2: Dictionary in N + S + [CB, BN1, BN2, BS1, BS2]: c.services(r2, 4.0, 1, String(r2.folder).contains("apt") or String(r2.folder).contains("stucco") or String(r2.folder).contains("brk3"))
	for d: Array in [[62.0, "prop_dumpster_3yd_green", "corner cafe and trattoria: kitchen waste by alley C3"], [65.0, "prop_dumpster_3yd_blue", "8th St shops: cardboard"], [128.0, "prop_dumpster_3yd_green", "8th St shops: waste by alley C3"], [131.0, "prop_dumpster_3yd_blue", "hardware row: packaging"], [196.0, "prop_dumpster_3yd_green", "bakery and bar: waste by alley C3"]]:
		var dx: float = d[0]
		c.put(String(d[1]), "worn", Vector3(dx, c.yf(dx, 148.0), 148.0), 0.0, String(d[2]))
	c.put("prop_transformer_substation", "worn", Vector3(104.0, c.yf(104.0, 150.0), 150.0), 0.0, "the block's transformer (underground wires)")
	c.stalls.append([90.0, 156.0, 0.0, c.yf(90.0, 156.0)]); c.oil(Vector2(90.0, 156.0), 0.0)
	c.stalls.append([170.0, 156.0, 0.0, c.yf(170.0, 156.0)]); c.oil(Vector2(170.0, 156.0), 0.0)
	# ---- the raised residents' garden (held by its retaining wall over the apartment sample's lawn)
	var gx0 := float(np[np.size() - 1][1]) + 0.6
	var gy := c.yf(176.0, 120.0)
	for t: Array in [[gx0 + 4.0, 106.0, "tree_jacaranda_a", 0.85], [186.0, 132.0, "tree_ficus_b", 0.85], [gx0 + 6.0, 133.0, "tree_coral_b", 0.85]]:
		c.put(String(t[2]), "normal", Vector3(float(t[0]), gy, float(t[1])), c.rr.randf_range(0, 360), "raised garden: trees in the grass", true, float(t[3]))
	c.put("prop_play_structure", "worn", Vector3(174.0, gy, 117.0), 0.0, "raised garden: the play corner on bark")
	c.put("prop_park_bench", "worn", Vector3(174.0, gy, 125.2), 180.0, "raised garden: a parent watches the play corner")
	c.put("prop_picnic_table", "worn", Vector3(gx0 + 6.0, gy, 120.0), 90.0, "raised garden: the residents' table")
	c.put("prop_shade_sail", "worn", Vector3(gx0 + 6.0, gy, 120.0), 90.0, "raised garden: the sail over the table it shades", false)
	c.put("prop_park_bench", "worn", Vector3(186.0, gy, 104.0), 0.0, "raised garden: a seat at the wall, looking over the lawn below")
	c.iron(Vector2(gx0, 139.4), Vector2(176.45, 139.4), "raised garden: iron fence on alley C3")
	c.put("fence_gate_wrought_iron", "worn", Vector3(177.0, c.yf(177.0, 139.4), 139.4), 0.0, "raised garden: its gate on alley C3", false)
	c.iron(Vector2(177.55, 139.4), Vector2(189.4, 139.4), "raised garden: iron fence on alley C3")
	c.iron(Vector2(189.4, 139.4), Vector2(189.4, 102.0), "raised garden: iron fence on alley B3")
	c.iron(Vector2(189.4, 102.0), Vector2(gx0, 102.0), "raised garden: rail along the top of its retaining wall")
	c.iron(Vector2(gx0, 102.0), Vector2(gx0, 139.4), "raised garden: iron fence beside the walk-up, over the small step to its yard")
	# ---- alleys
	c.alley_wear(51.0, 140.0, 240.8, 146.0, false)
	c.alley_wear(190.0, 101.5, 196.0, 140.0, true)
	c.tyre(Vector2(237.5, 143.0), 70.0, 5.0, 0.4); c.tyre(Vector2(53.0, 143.0), -60.0, 5.0, 0.4); c.tyre(Vector2(194.0, 142.0), 45.0, 5.0, 0.35)
	c.put("prop_storm_drain_grate", "worn", Vector3(150.0, c.yf(150.0, 143.0) + 0.005, 143.0), 0.0, "alley C3 drains to its middle", false)
	for r3: Dictionary in S + N + [CB]: c.roof_plant(r3, [[-4.0, -3.0, "prop_ac_condenser_compact"], [3.0, -3.0, "prop_vent_plumbing"], [0.0, 2.0, "prop_tv_antenna"]], "roof plant")
	for r4: Dictionary in N + S + [CB, BN1, BN2, BS1, BS2]:
		for dr2: Array in r4.doors:
			var q: Vector3 = dr2[1]; var o: Vector3 = dr2[2]
			c.grime(Vector2(q.x + o.x * 0.9, q.z + o.z * 0.9), 0.0, 1.6, 1.4, 0.4)
	c.finish()
	quit()
