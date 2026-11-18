extends RefCounted
## The three gritty-edge VARIANTS (18 Nov, claude/grow-gritty), each a recipe for one quadrant site of
## review/grow_grt_blocks.json (frame and drape: grt_grow_lib.gd). The plan's rules: no two blocks dressed the same (the
## site's seed picks buildings, businesses and the inside of the block), the kit's unused pieces go into variants, and
## zones change by transition, never by a jump:
##   v1 YARD EDGE (industrial side, backs onto the yards): a one-storey trade corner (tyres + parts, check cashing), a
##      hand car wash or a tyre shop on 4th St, the last narrow old cottages of the street with board fences and their
##      garages on the lane, and a contractor's yard / parts depot inside the block.
##   v2 TRADE STREET (the middle, round the sample): a brick corner block with shops under flats, a row of small
##      businesses (pawn, liquor, diner, laundromat, check cashing, thrift, barber) with dead fronts between them, brick
##      walk-ups with fire escapes on the Ave, the shops' service yard and a pay lot / vacant lot / repair yard inside.
##   v3 WALK-UP HOMES (toward the Crown Hill apartments and the campus): one corner shop and a laundromat, then homes -
##      apartment rows behind small yards, a dingbat on the lane, narrow houses on the Ave - and a shared court with a
##      fenced community garden and a kids' corner inside the block.
## Fencing (the phone's see-through cost, RUNTIME_BAKE.md): chain-link only round a yard / lot inside the block, with
## its streetward side behind a building; board fences only between front yards, across the street line, short.
const GL := preload("res://tools/city/pilot/pieces/grt_grow_lib.gd")
const G := preload("res://tools/city/pilot/pieces/grt_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")

static func build(piece: String) -> void:
	var ctx := GL.begin(piece)
	match String(ctx.site.recipe):
		"v1": _v1(ctx)
		"v2": _v2(ctx)
		"v3": _v3(ctx)

static func _w(folder: String) -> float: return float(K.building_stats(folder).footprint_wd[0])
static func _d(folder: String) -> float: return float(K.building_stats(folder).footprint_wd[1])

## pack buildings along the numbered street (face "-v") from s0 to s1, clear of the aprons; items: [folder, kind,
## label, extra] where kind "shop" -> extra = [bay kinds, open], "home" -> extra = yard. Returns the placed records.
static func _row_v(ctx: Dictionary, s0: float, s1: float, items: Array, gap := 0.6) -> Array:
	var out: Array = []
	var cur := s0
	for it: Array in items:
		var w := _w(String(it[0]))
		var st := cur
		while st + w <= s1 and not GL.apron_free(ctx, st, st + w): st += 1.0
		if st + w > s1: continue
		var c := st + w * 0.5
		if String(it[1]) == "shop": out.append(GL.shop(ctx, String(it[0]), c, "-v", String(it[2]), it[3][0], it[3][1]))
		else: out.append(GL.home(ctx, String(it[0]), c, "-v", String(it[2]), float(it[3]), true))
		cur = st + w + gap
	return out

## the same along the Ave (face "-u"), clear of the lane U mouth (53-61)
static func _row_u(ctx: Dictionary, s0: float, s1: float, items: Array, gap := 0.6) -> Array:
	var out: Array = []
	var cur := s0
	for it: Array in items:
		var w := _w(String(it[0]))
		var st := cur
		while st + w <= s1 and st < 61.0 and st + w > 53.0: st += 1.0
		if st + w > s1: continue
		var c := st + w * 0.5
		if String(it[1]) == "shop": out.append(GL.shop(ctx, String(it[0]), c, "-u", String(it[2]), it[3][0], it[3][1]))
		else: out.append(GL.home(ctx, String(it[0]), c, "-u", String(it[2]), float(it[3]), true))
		cur = st + w + gap
	return out

## drives from every apron on this side to the lane U (the 4th St lots are entered from 4th St)
static func _drives(ctx: Dictionary) -> void:
	for a: float in ctx.apr:
		if a - 4.5 < GL.AL1 and a + 4.5 > GL.AL0: continue      # that one is the lane V mouth (grt_grow_lib.begin)
		GL.drive(ctx, a, GL.AL0)

## ------------------------------------------------------------------------------------------------ v1 yard edge
static func _v1(ctx: Dictionary) -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz; var L: float = ctx.plv
	var rr: RandomNumberGenerator = ctx.rr; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec; var paints: Array = ctx.paints
	var seed := int(ctx.site.seed)
	# ---- A: the trade corner on 4th St, its customers' lot behind, the last cottage on the Ave
	var names: Array = [["Rim & Tire", "Quik Check Cash"], ["Brake Masters Used Parts", "Payday Loans 4U"]][seed % 2]
	var tr := GL.shop(ctx, "ck/ck_svc_trade", 16.5, "-v", "trade_corner", ["cash", "none"], [[0, "cash", names[1]], [1, "parts", names[0]]])
	GL.roof(ctx, tr, 4); GL.downspouts(ctx, tr)
	var nx := 16.5 + 6.0 + 1.0
	var gs := GL.shop(ctx, "commercial/com_gas_station", nx + 5.0, "-v", "old_station", ["dead"], [])     # the old filling station: pumps gone, boarded
	GL.roof(ctx, gs, 2)
	paints.append(A.rect(sx, sz, GL.FORE + 9.2, L + GL.FORE + 12.5, 54.0, 54.0, "asphalt"))
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 24.0, 53.0, GL.AL0, -1.0)
	I.yard_wear(dec, rr, sx, sz, 12.0, L + 16.0, 54.0, 54.0, 1.3)
	G.bins(ctx, 14.5, 46.0, rad_to_deg(atan2(A.face_dir(sx, sz, "+u").x, A.face_dir(sx, sz, "+u").y)))
	I.add(props, "prop_cone_18in", "dirty", A.q(sx, sz, 30.0, L + 17.0), 20.0)
	I.add(props, "prop_tank_horizontal_propane", "rusty", A.q(sx, sz, 44.0, L + 18.5), 90.0)     # the old station's last tank
	# ---- B: the hand car wash (or a tyre shop) on 4th St, entered from the apron next to the lane mouth
	if seed % 2 == 0:
		var cw := GL.work(ctx, "services/svc_carwash", 81.0, L + GL.FORE + 8.0, "-v", "hand_car_wash")
		GL.roof(ctx, cw, 2)
		paints.append(A.rect(sx, sz, 66.5, L, 98.0, L + GL.FORE + 0.05, "concrete"))
		paints.append(A.rect(sx, sz, 61.0, L + GL.FORE + 16.5, 99.0, 54.0, "asphalt"))      # drying lane behind
		SL.stalls_u(paints, ctx.stalls, sx, sz, 66.0, 9, 52.5, -1.0)
		for k in 6: W.oil(dec, rr, Vector2(sx * (68.0 + k * 5.0), sz * (L + GL.FORE + 18.5)), 90.0, S.walk_y, 0.5)
		for k2 in 5: dec.add(14, Vector2(sx * rr.randf_range(66.0, 96.0), sz * rr.randf_range(L + 20.0, 50.0)), rr.randf_range(0, 180), 3.0, 2.0, S.walk_y, Color(1, 1, 1, 0.45))   # soap and water stains
		I.add(props, "prop_hose_reel_cart", "worn", A.q(sx, sz, 64.0, L + 24.0), 0.0)
		I.add(props, "prop_sign_no_parking", "worn", A.q(sx, sz, 61.0, L + 0.8), 0.0)
	else:
		var rp := GL.work(ctx, "industrial/ind_repair", 80.0, L + GL.FORE + 8.0, "-v", "tyre_shop")
		(ctx.shoplist as Array).append({"label": "tyre_shop", "model": "industrial/ind_repair", "door_index": 0, "kind": "tyres", "name": "Big Al's Tires"})
		GL.roof(ctx, rp, 2)
		paints.append(A.rect(sx, sz, 66.5, L, 99.0, L + GL.FORE + 0.05, "concrete"))
		paints.append(A.rect(sx, sz, 61.0, L + GL.FORE + 16.5, 99.0, 54.0, "asphalt"))
		for k3 in 6: I.add(props, "prop_k_rail" if k3 == 0 else "prop_channelizer_drum", "dirty", A.q(sx, sz, 96.0, L + 22.0 + k3 * 1.2), 0.0)
		SL.stalls_u(paints, ctx.stalls, sx, sz, 64.0, 10, 52.5, -1.0)
		I.yard_wear(dec, rr, sx, sz, 61.0, L + 18.0, 99.0, 54.0, 1.5)
	# ---- C: narrow old houses on the Ave behind board side fences, garages on the lane
	var houses := ["houses/narrow_cottage_siding", "houses/narrow_2sty_siding", "houses/narrow_cottage_stucco_clay", "houses/narrow_2sty_stucco_clay", "houses/ranch_siding"]
	var hs: Array = []
	for k4 in 5: hs.append([houses[(k4 + seed) % houses.size()], "home", "cottage_%d" % k4, 3.5])
	_row_u(ctx, 61.5, 99.0, hs, 1.6)
	for k5 in 4: GL.garage(ctx, ["garages/single_stucco_flat", "garages/single_stucco_clay"][(k5 + seed) % 2], 64.0 + k5 * 9.0, "+u", "garage_%d" % k5)
	# ---- D: the contractor's yard (warehouse to the lane, open yard behind, fenced on the lane sides only)
	if seed % 2 == 0:
		var wh := GL.work(ctx, "industrial/ind_warehouse", 80.0, GL.AL1 + 0.8 + 12.0, "-v", "contractor_shed")
		GL.roof(ctx, wh, 3)
		I.containers(props, sx, sz, 64.0, 90.0, 2, false, rr, 1)
		for k6 in 3: I.add(props, "prop_k_rail", "worn", A.q(sx, sz, 96.0, 88.0 - k6 * 3.6), 0.0)
		I.add(props, "prop_dumpster_rolloff_20yd", "rusty", A.q(sx, sz, 84.0, 94.0), 90.0)
		I.add(props, "prop_water_barrier_white", "dirty", A.q(sx, sz, 72.0, 93.0), 0.0)
		I.add(props, "prop_tank_vertical", "rusty", A.q(sx, sz, 92.0, 95.0), 0.0)
		paints.append(A.rect(sx, sz, GL.AL1, GL.AL1, 100.0, 100.0, "gravel"))
		I.yard_wear(dec, rr, sx, sz, 61.0, 86.0, 99.0, 99.0, 1.4)
	else:
		var dp := GL.work(ctx, "modular/examples/mod_wh_shed", 80.0, GL.AL1 + 0.8 + 12.0, "-v", "parts_depot")
		GL.roof(ctx, dp, 3)
		paints.append(A.rect(sx, sz, GL.AL1, GL.AL1, 100.0, 100.0, "asphalt"))
		SL.stalls_u(paints, ctx.stalls, sx, sz, 64.0, 11, 98.5, -1.0)
		I.add(props, "prop_dumpster_3yd_green", "rusty", A.q(sx, sz, 96.5, 88.0), 90.0)
		I.add(props, "prop_dumpster_3yd_blue", "dirty", A.q(sx, sz, 96.5, 85.0), 90.0)
		SL.lot_light(props, sx, sz, 62.0, 98.0)
		I.yard_wear(dec, rr, sx, sz, 61.0, 86.0, 99.0, 99.0, 1.2)
	# the yard's fence: chain-link along the two lanes, ONE rolling gate on lane V; the inner edges stay open (the
	# neighbouring yards / the industrial sample close them), so no fence stands in front of another
	I.lot_fence(props, Vector2(sx * 61.0, sz * 61.0), Vector2(sx * 61.0, sz * 78.0), true)
	I.lot_fence(props, Vector2(sx * 61.0, sz * 84.0), Vector2(sx * 61.0, sz * 99.0), true)
	I.add(props, "fence_gate_rolling_chainlink", "rusty", A.q(sx, sz, 61.4, 87.0), 0.0)
	_drives(ctx)
	GL.done(ctx, "gravel", true)

## ------------------------------------------------------------------------------------------------ v2 trade street
static func _v2(ctx: Dictionary) -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz; var L: float = ctx.plv
	var rr: RandomNumberGenerator = ctx.rr; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec; var paints: Array = ctx.paints
	var seed := int(ctx.site.seed)
	# businesses per site (no two alike; names are made up, no brands)
	var sets := {
		1: {"corner": "urban/urb_brick_corner", "cn": [[0, "diner", "Rosie's Diner"]], "ck": ["diner"],
			"a2": ["ck/ck_svc_cinema_fast", ["dead", "diner"], [[1, "takeout", "Wok N Roll"]]],
			"b": [["ck/ck_grt_row3", "shop", "row3", [["thrift", "dead", "cash"], [[0, "thrift", "Second Hand Rose"], [2, "cash", "Check Express"]]]],
				["commercial/com_bar_crown", "shop", "dive_bar", [["bar"], [[0, "bar", "The Anchor Inn"]]]]]},
		3: {"corner": "ck/ck_brk3_corner2", "cn": [[1, "liquor", "Fourth St Liquor"]], "ck": ["liquor"],
			"a2": ["ck/ck_svc_trade", ["pawn", "none"], [[0, "pawn", "Gold & Pawn"], [1, "barber", "Fade Kings Barber"]]],
			"b": [["ck/ck_svc_pawn_fast", "shop", "row_b", [["dead", "diner"], [[1, "takeout", "Taco Shack"]]]],
				["ck/ck_grt_row2", "shop", "launder", [["laundry"], [[0, "laundry", "Suds City Laundry"]]]]]},
		6: {"corner": "ck/ck_brk3_corner2", "cn": [[1, "bodega", "Fifth St Market"]], "ck": ["liquor"],
			"a2": ["ck/ck_svc_trade_1d", ["cash"], [[0, "tattoo", "Black Anchor Tattoo"]]],
			"b": [["urban/urb_brick_row", "shop", "brick_row", [["dead", "laundry", "none"], [[1, "laundry", "Bubbles Coin Wash"], [2, "thrift", "Junk & Treasures"]]]],
				["ck/ck_grt_row2", "shop", "boarded", [["dead"], []]]]},
	}
	var cfg: Dictionary = sets.get(seed, sets[3])
	# ---- A: the corner block (shops under flats) and the next business on 4th / 5th St, the service yard behind
	var cf := String(cfg.corner)
	var cb := GL.shop(ctx, cf, 10.2 + _w(cf) * 0.5, "-v", "corner_block", cfg.ck, cfg.cn)
	GL.downspouts(ctx, cb)
	var a2: Array = cfg.a2
	var placed := _row_v(ctx, 10.2 + _w(cf) + 0.6, 53.0, [[a2[0], "shop", "corner_next", [a2[1], a2[2]]]])
	for b0: Dictionary in placed: GL.roof(ctx, b0, 3)
	var back := L + GL.FORE + maxf(_d(cf), 12.0) + 0.5
	paints.append(A.rect(sx, sz, 9.2 + GL.FORE + 15.0, back, 54.0, 54.0, "asphalt"))
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 28.0, 53.0, GL.AL0, -1.0)
	G.bins(ctx, 44.0, back + 3.2, rad_to_deg(atan2(A.face_dir(sx, sz, "+v").x, A.face_dir(sx, sz, "+v").y)))
	I.yard_wear(dec, rr, sx, sz, 24.0, back, 54.0, 54.0, 1.4)
	# the corner block's own Ave side: a brick walk-up with the fire escape over its alley side
	_row_u(ctx, back + 0.5, 53.0, [["ck/ck_brk3_row2_fe", "home", "walkup_a", 1.5]])
	# ---- B: the row of small businesses, a drive in at each apron to the tenants' and staff parking
	var rb := _row_v(ctx, 61.0, 99.0, cfg.b, 0.4)
	for b1: Dictionary in rb: GL.roof(ctx, b1, 3); GL.downspouts(ctx, b1)
	paints.append(A.rect(sx, sz, 60.0, L + GL.FORE + 14.5, 100.0, 54.0, "asphalt"))
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 62.0, 98.0, GL.AL0, -1.0)
	G.bins(ctx, 96.0, L + GL.FORE + 18.0, rad_to_deg(atan2(A.face_dir(sx, sz, "-u").x, A.face_dir(sx, sz, "-u").y)))
	I.yard_wear(dec, rr, sx, sz, 60.0, L + 18.0, 100.0, 54.0, 1.3)
	# ---- C: brick walk-ups on the Ave (fire escapes face the lane / the court), clotheslines out the back
	var walkups := [["ck/ck_brk3_row2_fe", "home", "walkup_c0", 1.5], ["ck/ck_brk3_row2", "home", "walkup_c1", 1.5], ["ck/ck_apt3_row2", "home", "walkup_c2", 2.5]]
	if seed % 2 == 1: walkups = [walkups[1], walkups[0], ["ck/ck_apt3_row3", "home", "walkup_c2", 2.5]]
	_row_u(ctx, 61.0, 99.5, walkups, 0.8)
	# ---- D: the inside of the block
	match seed % 3:
		0:   # a vacant lot the owner fenced and forgot: gravel, self-seeded agaves, dumped stuff (ONE gate on the lane)
			G.lot(ctx, "vacant", 62.0, 62.0, 98.0, 98.0, "v0")
			paints.append(A.rect(sx, sz, 76.0, 60.0, 84.0, 62.0, "asphalt"))
		1:   # a pay lot for the strip (people who work on 4th St park here): stalls, a pay station, a lot light
			paints.append(A.rect(sx, sz, 60.0, 60.0, 100.0, 100.0, "asphalt"))
			SL.stalls_u(paints, ctx.stalls, sx, sz, 62.0, 13, 61.0, 1.0)
			SL.stalls_u(paints, ctx.stalls, sx, sz, 62.0, 13, 78.0, -1.0)
			SL.stalls_u(paints, ctx.stalls, sx, sz, 62.0, 13, 81.0, 1.0)
			SL.stalls_u(paints, ctx.stalls, sx, sz, 62.0, 13, 98.5, -1.0)
			SL.stall_wear(dec, rr, ctx.stalls.slice(ctx.stalls.size() - 52), 0.7)
			I.add(props, "prop_pay_station", "worn", A.q(sx, sz, 61.5, 79.5), 90.0)
			SL.lot_light(props, sx, sz, 99.0, 79.5)
			G.bins(ctx, 96.0, 90.0, rad_to_deg(atan2(A.face_dir(sx, sz, "-u").x, A.face_dir(sx, sz, "-u").y)))
		2:   # a back-street body shop and its row of cars waiting for parts
			var rep := GL.work(ctx, "industrial/ind_repair", 82.0, GL.AL1 + 0.8 + 8.0, "-v", "back_body_shop")
			GL.roof(ctx, rep, 2)
			paints.append(A.rect(sx, sz, 60.0, 60.0, 100.0, 100.0, "asphalt"))
			SL.stalls_u(paints, ctx.stalls, sx, sz, 63.0, 12, 98.5, -1.0)
			I.back_door_clutter(props, rr, A.at(rep, 4.0, -rep.d * 0.5 - 4.0), rad_to_deg((rep.node as Node3D).rotation.y) + 180.0, "yard")
			I.yard_wear(dec, rr, sx, sz, 60.0, 76.0, 100.0, 100.0, 1.5)
	_drives(ctx)
	GL.done(ctx, "grass", true)

## ------------------------------------------------------------------------------------------------ v3 walk-up homes
static func _v3(ctx: Dictionary) -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz; var L: float = ctx.plv
	var rr: RandomNumberGenerator = ctx.rr; var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec; var paints: Array = ctx.paints
	var seed := int(ctx.site.seed)
	var sets := {
		4: {"shop": ["ck/ck_svc_trade_1d", ["liquor"], [[0, "bodega", "G Ave Mini Mart"]]], "shop2": ["ck/ck_grt_row2", ["laundry"], [[0, "laundry", "Wash Tub Laundromat"]]],
			"b": ["ck/ck_apt3_row3", "apartments/apt_stucco3_peach"], "ding": "apartments/apt_dingbat_teal", "court": "apartments/apt_court_white"},
		5: {"shop": ["ck/ck_svc_bank_pharm", ["cash"], [[1, "cash", "Cash Now"]]], "shop2": ["commercial/com_realty", ["none"], [[0, "botanica", "Botanica San Miguel"]]],
			"b": ["apartments/apt_stucco3_cream", "ck/ck_apt3_row2"], "ding": "apartments/apt_dingbat_pink", "court": "ck/ck_apt3_row3_boarded"},
		7: {"shop": ["ck/ck_grt_row3", ["diner", "none", "laundry"], [[0, "diner", "Campus Grill"], [2, "laundry", "Spin Cycle"]]], "shop2": ["", [], []],
			"b": ["apartments/apt_court_white", "ck/ck_apt3_row3"], "ding": "apartments/apt_dingbat_teal", "court": "apartments/apt_garden_cream"},
	}
	var cfg: Dictionary = sets.get(seed, sets[4])
	# ---- A: the corner shop (and a laundromat) on the numbered street, homes behind on the Ave
	var s1: Array = cfg.shop
	var a_items: Array = [[s1[0], "shop", "corner_shop", [s1[1], s1[2]]]]
	var s2: Array = cfg.shop2
	if String(s2[0]) != "": a_items.append([s2[0], "shop", "shop_two", [s2[1], s2[2]]])
	var ra := _row_v(ctx, 10.2, 53.0, a_items, 0.6)
	for b0: Dictionary in ra: GL.roof(ctx, b0, 2)
	var back := L + GL.FORE + 14.5
	_row_u(ctx, back + 1.0, 53.0, [["houses/narrow_2sty_stucco_clay", "home", "house_a0", 3.0], ["houses/narrow_cottage_siding", "home", "house_a1", 3.0]], 1.6)
	A.pad(paints, ctx.stalls, dec, rr, sx, sz, true, 30.0, 53.0, GL.AL0, -1.0)
	G.bins(ctx, 26.0, GL.AL0 - 3.0, rad_to_deg(atan2(A.face_dir(sx, sz, "+v").x, A.face_dir(sx, sz, "+v").y)))
	# ---- B: apartment rows behind small yards on the numbered street, a dingbat on lane U behind them
	var bl: Array = cfg.b
	_row_v(ctx, 61.0, 99.0, [[bl[0], "home", "apts_b0", 3.0], [bl[1], "home", "apts_b1", 3.0]], 1.2)
	G.dingbat(ctx, String(cfg.ding), 84.0, "+v", "lane_dingbat")
	# ---- C: narrow houses and a walk-up on the Ave, garages on lane V
	var hs: Array = [["houses/narrow_cottage_stucco_clay", "home", "house_c0", 3.0], ["houses/narrow_2sty_siding", "home", "house_c1", 3.0],
		["ck/ck_apt3_row2", "home", "walkup_c", 2.5], ["houses/narrow_cottage_siding", "home", "house_c2", 3.0]]
	if seed % 2 == 1: hs.reverse()
	_row_u(ctx, 61.0, 99.5, hs, 1.4)
	for k in 3: GL.garage(ctx, ["garages/single_stucco_clay", "garages/single_stucco_flat"][(k + seed) % 2], 66.0 + k * 10.0, "+u", "garage_%d" % k)
	# ---- D: the shared court: a home along lane U, the community garden behind chain-link (ONE gate), a kids' corner
	var cf := String(cfg.court)
	var hb := A.place(ctx.bl, sx, sz, cf, 80.0, GL.AL1 + 3.0 + _d(cf) * 0.5, "-v", "court_home", GL.WEAR)
	ctx.blds.append(hb)
	A.dress(hb, paints, props, dec, rr, sx, sz, GL.AL1, false, false)
	var gv0 := GL.AL1 + 3.0 + _d(cf) + 4.0
	paints.append(A.rect(sx, sz, 68.0, gv0, 96.0, 98.0, "mulch"))
	for side: Array in [[Vector2(68.0, gv0), Vector2(68.0, 98.0)], [Vector2(68.0, 98.0), Vector2(96.0, 98.0)], [Vector2(96.0, 98.0), Vector2(96.0, gv0)]]:
		var a0: Vector2 = side[0]; var a1: Vector2 = side[1]
		I.lot_fence(props, Vector2(sx * a0.x, sz * a0.y), Vector2(sx * a1.x, sz * a1.y), false)
	I.lot_fence(props, Vector2(sx * 96.0, sz * gv0), Vector2(sx * 84.0, sz * gv0), false)      # the gate side: one 4 m gap
	I.lot_fence(props, Vector2(sx * 80.0, sz * gv0), Vector2(sx * 68.0, sz * gv0), false)
	var beds := ["plant_bird_of_paradise", "plant_agave_americana_small", "plant_bougainvillea_mound", "plant_potted_leafy", "plant_iceplant_patch"]
	for k2 in 14:
		var pu := 70.0 + (k2 % 7) * 3.8; var pv := gv0 + 2.0 + float(k2 / 7) * (98.0 - gv0 - 4.0)
		I.add(props, beds[(k2 + seed) % beds.size()], "normal", A.q(sx, sz, pu, pv), rr.randf_range(0, 360))
	I.add(props, "prop_hose_reel_cart", "worn", A.q(sx, sz, 82.0, gv0 + 1.2), 0.0)
	I.add(props, "plant_bougainvillea_wall", "normal", A.q(sx, sz, 96.4, (gv0 + 98.0) * 0.5), 90.0)
	I.add(props, "prop_park_bench", "worn", A.q(sx, sz, 64.0, gv0 + 4.0), rad_to_deg(atan2(A.face_dir(sx, sz, "+u").x, A.face_dir(sx, sz, "+u").y)))
	_drives(ctx)
	GL.done(ctx, "grass", true)
