extends SceneTree
## Piece n_apt_b3_e - apartment band fill, BLOCK 3 (B Ave - Adela Ave, 6th St - the residential quarters at z -300), its
## EAST part. Layout row: pos [250, 8, -400], yaw 0 (the B Ave x 6th St junction's frame); u = east of B Ave's centre
## line, v = SOUTH of 6th St's centre line (sx = +1, sz = +1). Outline: u 125-240.8 (the lot line with n_apt_b3_w to
## Adela's property line), v 9.2-100 (6th St's property line to the residential quarter r_q_500_m200_nw).
##
## LAND (apt_fill_b3_land.gd, measured): 6th St falls from 7.20 to 6.15 m along the north edge, Adela climbs 1.00 m
## along the east edge, the residential quarter behind stands on terraces 9.40 .. 7.27 m with its alley at u 190-196
## a metre below the lot beside it. One smooth surface through all four edges; every building on its own level pad at
## the middle of its front - the three garage townhouses on the alley step DOWN toward Adela one after the other; on the
## shared line with the residential quarter a retaining face wherever the grounds differ (up to 0.65 m behind the
## townhouses' yards, where the house terrace stands higher), their alley's mouth matched exactly.
##
## WHO LIVES HERE AND WHY:
## The quiet back of the band against the houses: families again. On 6th St two walk-ups and a stucco block facing the
## bike shop across the street; on the alley three GARAGE TOWNHOUSES, cars on their drives, small back yards fenced lot
## by lot against the retaining wall of the house terraces behind; on the corner of 6th and Adela a white court with a
## palm lawn, on Adela two walk-ups and a Spanish court; the tenants' stalls on the alleys.
## Alleys: u-alley v 54-60 (Adela's apron at z -346..-340), v-alley u 190-196 (6th St's apron at u 440-446; it runs on
## into the residential quarter's own alley at z -300, matched exactly).
## Walk-in places: none (homes only).
## Built once by its own script; a draft until Yasin has seen it. Never re-run after that.
const F := preload("res://tools/city/pilot/pieces/apt_fill_lib.gd")
const L := preload("res://tools/city/pilot/pieces/apt_fill_b3_land.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const NAME := "n_apt_b3_e"
const B := [
	["ck/ck_apt3_row2", 136.0, 18.2, "-v", "walkup_6th_s_1"],
	["apartments/apt_stucco3_cream", 159.5, 18.2, "-v", "stucco_6th_s"],
	["ck/ck_apt3_row2", 180.0, 18.2, "-v", "walkup_6th_s_2"],
	["apartments/apt_townhouse_cays", 137.6, 71.0, "-v", "townhouses_b3_1"],
	["apartments/apt_townhouse_modern", 159.0, 71.0, "-v", "townhouses_b3_2"],
	["apartments/apt_townhouse_modern", 179.0, 71.0, "-v", "townhouses_b3_3"],
	["apartments/apt_court_white", 222.0, 16.7, "-v", "white_court_6th_adela"],
	["ck/ck_apt3_row3", 231.8, 40.0, "+u", "walkup_adela_b3"],
	["ck/ck_apt3_row2", 231.8, 70.0, "+u", "walkup_adela_b3_s"],
	["apartments/apt_spanish_white", 232.8, 87.5, "+u", "spanish_adela_b3"],
]
func _init() -> void: _run.call_deferred()

func _run() -> void:
	var sx := 1.0; var sz := 1.0
	var ctx := F.begin(NAME, sx, sz)
	F.SURF = L.surface; F.GY = F.terrain; F.outline(sx, sz, 125.0, 9.2, 240.8, 100.0)
	var bl: Node3D = ctx.bl; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec
	var rr: RandomNumberGenerator = ctx.rr; var paints: Array = ctx.paints; var stalls: Array = ctx.stalls
	var poles: Array = ctx.poles; var blds: Array = ctx.blds; var stops: Array = ctx.stops
	# ---------------------------------------------------------------- land first
	var pads := {}
	for b: Array in B: pads[String(b[4])] = F.pad_for(paints, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]))
	ctx["walls"] = L.seam_faces(125.0, 240.8)
	F.alley(paints, props, dec, rr, sx, sz, true, 54.0, 125.0, 240.8, poles, [[149.0, 53.3], [215.0, 53.3]], NAN, [0])
	F.alley(paints, props, dec, rr, sx, sz, false, 190.0, 9.2, 100.0, poles, [[30.0, 189.3], [80.0, 196.7]], NAN, [1])
	if OS.get_environment("APT_GROUND_ONLY") == "1":
		F.finish(ctx, 125.0, 9.2, 240.8, 100.0); quit(); return
	var bd := {}
	for b: Array in B:
		bd[String(b[4])] = F.place(bl, sx, sz, String(b[0]), float(b[1]), float(b[2]), String(b[3]), String(b[4]), 0.75, pads[String(b[4])])
		blds.append(bd[String(b[4])])

	# ================================================================ B (east, u 125-190, v 9.2-54): 6th St
	for key: String in ["walkup_6th_s_1", "stucco_6th_s", "walkup_6th_s_2"]: F.dress(bd[key], paints, props, dec, rr, sx, sz, 9.2, true, true)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, true, 126.0, 146.0, 54.0, -1.0))
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, true, 152.0, 188.0, 54.0, -1.0))
	F.fence_uv(props, sx, sz, 124.8, 24.4, 129.8, 24.4)
	F.fence_gate(props, sx, sz, 124.6, 47.4, 188.0, 47.4, 32.0)
	F.fence_gate(props, sx, sz, 142.2, 18.0, 149.8, 18.0, 3.8)
	F.fence_gate(props, sx, sz, 169.2, 18.0, 173.8, 18.0, 2.3)
	F.fence_uv(props, sx, sz, 186.2, 24.4, 188.0, 24.4)
	F.fence_uv(props, sx, sz, 188.0, 24.4, 188.0, 47.4)
	F.put(props, "tree_coral_b", "normal", sx, sz, 148.0, 38.0, 75.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 172.0, 36.0, 0.0)
	F.put(props, "prop_picnic_table", "worn", sx, sz, 136.0, 38.0, 90.0)

	# ================================================================ E (east, u 125-190, v 60-100): the garage townhouses
	for key2: String in ["townhouses_b3_1", "townhouses_b3_2", "townhouses_b3_3"]:
		var tb: Dictionary = bd[key2]
		F.dress(tb, paints, props, dec, rr, sx, sz, 66.0, false, true, [])
		var hw := float(tb.w) * 0.5
		paints.append(F.rect(sx, sz, float(tb.u) - hw, 60.0, float(tb.u) + hw, 66.0, "concrete"))   # its own drive
		var roll: Array = [-7.8, 1.4] if String(tb.folder).contains("cays") else [-7.2, 1.2]
		for lx: float in roll:
			var p := F.at(tb, lx, 5.0 + 3.0)
			stalls.append([p.x, p.z, 0.0, F.gy(p.x, p.z)])
			W.oil(dec, rr, Vector2(p.x, p.z), 0.0, F.GY, rr.randf_range(0.5, 0.85))
			dec.add(8, Vector2(p.x, p.z - 1.0), rr.randf_range(-15, 15), 0.5, 3.5, F.GY, Color(1, 1, 1, 0.35))
	F.fence_uv(props, sx, sz, 124.8, 67.0, 127.8, 67.0)                            # side yards closed at the front, a gate in each
	F.fence_gate(props, sx, sz, 147.4, 67.0, 149.8, 67.0, 1.2)
	F.fence_gate(props, sx, sz, 168.2, 67.0, 169.8, 67.0, 0.8)
	F.fence_uv(props, sx, sz, 188.2, 67.0, 189.4, 67.0)
	F.fence_uv(props, sx, sz, 148.6, 67.0, 148.6, 99.6)                            # lot lines down to the back
	F.fence_uv(props, sx, sz, 169.0, 67.0, 169.0, 99.6)
	F.fence_uv(props, sx, sz, 189.4, 67.0, 189.4, 99.6)
	F.fence_uv(props, sx, sz, 124.6, 99.6, 189.4, 99.6)                            # the back line, on the retaining face
	for k in 3:
		var cu := 136.0 + k * 20.5
		F.put(props, "prop_patio_set_4", "worn", sx, sz, cu, 82.0, k * 25.0)
		F.put(props, ["tree_ficus_a", "tree_jacaranda_b", "tree_coral_a"][k], "normal", sx, sz, cu + 6.0, 94.0, k * 80.0)
	F.put(props, "prop_swing_set", "worn", sx, sz, 158.0, 90.0, 0.0)               # the middle family's children
	paints.insert(0, F.rect(sx, sz, 154.0, 87.5, 162.0, 92.5, "mulch"))
	F.put(props, "prop_trash_cart_green", "worn", sx, sz, 186.6, 97.6, 0.0)
	F.put(props, "prop_adirondack_white", "worn", sx, sz, 180.0, 84.0, 160.0)

	# ================================================================ C corner (u 196-240.8, v 9.2-54) and F (v 60-100)
	F.dress(bd.white_court_6th_adela, paints, props, dec, rr, sx, sz, 9.2, true, true, [-1.0])
	F.dress(bd.walkup_adela_b3, paints, props, dec, rr, sx, sz, 240.8, true, true)
	F.dress(bd.walkup_adela_b3_s, paints, props, dec, rr, sx, sz, 240.8, true, true, [-1.0])
	F.dress(bd.spanish_adela_b3, paints, props, dec, rr, sx, sz, 240.8, true, true, [1.0])
	for p2: Vector2 in [Vector2(201.0, 13.0), Vector2(207.5, 15.5), Vector2(203.0, 21.0)]:   # the palm lawn on the corner side
		F.put(props, "palm_mexican_fan_b" if int(p2.x) % 2 == 0 else "palm_queen_a", "normal", sx, sz, p2.x, p2.y, p2.x * 13.0)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 26.0, 52.0, 196.0, 1.0))
	F.fence_gate(props, sx, sz, 202.6, 21.4, 202.6, 52.2, 15.0)
	F.fence_uv(props, sx, sz, 202.6, 21.4, 213.4, 21.4)
	F.fence_uv(props, sx, sz, 202.6, 52.2, 225.6, 52.2)
	F.fence_uv(props, sx, sz, 225.6, 52.2, 225.6, 49.2)
	F.fence_uv(props, sx, sz, 230.6, 21.4, 238.0, 21.4)
	F.fence_gate(props, sx, sz, 238.0, 21.4, 238.0, 30.8, 4.7)
	F.put(props, "tree_magnolia_a", "normal", sx, sz, 214.0, 40.0, 25.0)
	F.put(props, "prop_bbq_gas_cart", "worn", sx, sz, 210.0, 30.0, 90.0)
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 61.0, 77.0, 196.0, 1.0))
	stops.append_array(F.pad(paints, stalls, dec, rr, sx, sz, false, 83.0, 96.0, 196.0, 1.0))
	F.fence_gate(props, sx, sz, 202.6, 60.4, 202.6, 99.6, 19.6)
	F.fence_uv(props, sx, sz, 202.6, 60.4, 225.6, 60.4)
	F.fence_uv(props, sx, sz, 225.6, 60.4, 225.6, 63.8)
	F.fence_uv(props, sx, sz, 225.6, 76.2, 225.6, 78.3)
	F.fence_gate(props, sx, sz, 225.6, 78.3, 227.6, 78.3, 1.0)
	F.fence_uv(props, sx, sz, 202.6, 99.6, 227.6, 99.6)
	F.fence_uv(props, sx, sz, 227.6, 99.6, 227.6, 96.7)
	F.put(props, "tree_jacaranda_a", "normal", sx, sz, 210.0, 72.0, 15.0)
	F.put(props, "prop_clothesline", "worn", sx, sz, 214.0, 90.0, 90.0)

	# ================================================================ POLISH PASS (Yasin 19 Nov: "run a polish pass in all your
	# quarters ... plenty of props"): only ADDS, with its own random sequence, after everything above (which stays identical):
	# every building's downspouts, house numbers, vine or dish, back-wall grime; and the spots chosen here, each a cluster
	# whose items go in only where their own spot is free (apt_fill_lib.polish_*)
	var prr := W.rng_for(NAME + "_polish")
	var prect := Rect2(125.0, 9.2, 115.8, 90.8)
	for pb: Dictionary in blds: F.polish_building(ctx, pb, prr, prect)
	for psp: Array in [["sit", 160, 32, 0], ["garden", 180, 30, 0], ["tools", 186, 44, 90], ["garden", 140, 96, 0], ["lounge", 178, 92, 0], ["tools", 146, 78, 90], ["garden", 206, 26, 0], ["lounge", 218, 46, 0], ["sit", 213, 66, 0], ["garden", 208, 96, 0], ["play", 214, 84, 0]]:
		F.polish_spot(ctx, String(psp[0]), float(psp[1]), float(psp[2]), float(psp[3]), prr, prect)

	F.finish(ctx, 125.0, 9.2, 240.8, 100.0)
	quit()
