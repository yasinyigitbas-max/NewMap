extends RefCounted
## Gritty edge helpers (g_ne / g_nw / g_se / g_sw, w_grt): the transition between the industrial sample and the
## apartment band (CITY_PLAN.md "Gritty edge"). Same grid as the apartment / civic bands (it reuses the locked j_apt /
## s_apt streets, bus stops both ways included): each quadrant is cut by two service lanes (u 54-60, v 54-60) into
## four sub-blocks A corner [9.2, 9.2, 54, 54], B avenue [60, 9.2, 100, 54], C side street [9.2, 60, 54, 100],
## D inside [60, 60, 100, 100].
## What makes it gritty, and why each thing is there:
## - old shop rows on the property line with a 2.5 m forecourt (narrow walks, Yasin 17 Nov), some open (pawn,
##   laundromat, liquor, dive bar), some boarded or abandoned (kit urb_grt fronts merged into ck_grt_row2 / _row3);
## - brick walk-ups with fire escapes on the alley side (ck_brk3_row2_fe), an apartment row with a boarded bay;
## - chain-link everywhere: front-yard fences with open gaps at the walks, vacant lots with ONE gate, barbed wire on
##   anything that stores cars or scrap; billboards over the vacant lots facing the street (that is what pays the rent
##   on an empty lot); tagged CMU walls by the bins; a stalled building site behind screened temp fence;
## - heavier wear than the apartment band: wall grime, cracks, oil, litter grime at doors and bus stops.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const FORE := 2.5       # shop forecourt depth (property line -> shopfront)
const WEAR := 0.9       # facade weathering: dirtier than the apartment band (0.75)

static func begin(name: String, sx: float, sz: float) -> Dictionary:
	var ctx := C.begin(name, sx, sz)
	ctx["shops"] = []
	return ctx

## the across-axis centre of a building whose front stands `front` from the street on a ±v / ±u frontage
static func _centre(front: float, d: float) -> float: return front + d * 0.5

## A shop building on the property line behind a paved forecourt (2.5 m): faces the street (face "-v" or "-u"),
## spans `s` (centre along the street). kind = what the business is; it decides the forecourt life:
##   "pawn": a bin and nothing else (pawn shops keep the walk bare); "laundry": a bench to wait on, the soda machine,
##   a cart people wheel their washing in; "liquor": paper boxes, the ice chest, a bin, a propane cage; "bar": the
##   smokers' bin and a bike rack; "dead": boarded / abandoned - no furniture, heavier grime, a dumped cart.
## Back of house (meters, AC, bins / dumpster at the back door) and wall grime always.
static func shop(ctx: Dictionary, folder: String, s: float, face: String, label: String, kinds: Array) -> Dictionary:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var across := _centre(A.PROP + FORE, d)
	var b: Dictionary = A.place(ctx.bl, sx, sz, folder, s if face.ends_with("v") else across, across if face.ends_with("v") else s, face, label, WEAR)
	ctx.blds.append(b); ctx.shops.append(b)
	var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec; var rr: RandomNumberGenerator = ctx.rr
	# forecourt slab (concrete) from the property line to the shopfront, the building's width + 1 m each side
	if face.ends_with("v"): ctx.paints.append(A.rect(sx, sz, s - w * 0.5 - 1.0, A.PROP, s + w * 0.5 + 1.0, A.PROP + FORE + 0.05, "concrete"))
	else: ctx.paints.append(A.rect(sx, sz, A.PROP, s - w * 0.5 - 1.0, A.PROP + FORE + 0.05, s + w * 0.5 + 1.0, "concrete"))
	CC.back_of_house(props, b.node, folder, false)
	I.bld_wear(dec, rr, b.node, w, d, folder)
	A.balconies(b, props)       # brick walk-ups over shops: the iron balconies over the flats' entry bay
	var yaw := rad_to_deg((b.node as Node3D).rotation.y)
	# forecourt furniture per shop bay: slide each item along the facade clear of every door (1.9 m)
	var doors: Array = []
	for e: Array in st.get("doors_front", []): doors.append(float(e[1]))
	# returns INF when the item cannot stand clear of every door (it is then left out: a door always wins)
	var clear_x := func(lx: float, half: float) -> float:
		var x := lx
		var gap := 1.95 + half
		for it in 8:
			var hit := false
			for dx: float in doors:
				if absf(x - dx) < gap: hit = true; x = dx + (gap + 0.05 if lx >= dx else -gap - 0.05)
			if not hit: break
		x = clampf(x, -w * 0.5 + 0.6 + half, w * 0.5 - 0.6 - half)
		for dx2: float in doors:
			if absf(x - dx2) < gap: return INF
		return x
	var placed: Array = []
	var put := func(base: String, cond: String, lx: float, out: float, dyaw: float) -> void:
		var cx: float = clear_x.call(lx, 1.25 if base == "prop_bike_rack" or base == "prop_park_bench" else 0.4)
		if cx == INF: return
		for pl: Vector2 in placed:
			if pl.distance_to(Vector2(cx, out)) < 1.0: return      # two items slid onto one spot: keep the first
		placed.append(Vector2(cx, out))
		I.add(props, base, cond, A.at(b, cx, d * 0.5 + out), yaw + dyaw)
	var nb := kinds.size()
	for k in nb:
		var c0 := -w * 0.5 + w * (k + 0.5) / nb       # bay centre (local x)
		match String(kinds[k]):
			"pawn":
				put.call("prop_trash_receptacle", "dirty", c0 + 2.2, 0.7, 0.0)
			"laundry":
				put.call("prop_park_bench", "worn", c0 - 1.0, 0.75, 0.0)            # faces the street (forward = local +z)
				put.call("prop_vending_soda", "worn", c0 + 2.3, 0.9, 0.0)
				put.call("prop_shopping_cart", "dirty", c0 + 1.2, 1.6, rr.randf_range(-40.0, 40.0))
			"liquor":
				put.call("prop_newspaper_box_red", "worn", c0 - 2.6, 0.7, 0.0)
				put.call("prop_newspaper_box_blue", "worn", c0 - 1.9, 0.7, 0.0)
				put.call("prop_ice_chest", "worn", c0 + 1.2, 0.9, 0.0)
				put.call("prop_trash_receptacle", "dirty", c0 + 3.0, 0.8, 0.0)
			"bar":
				put.call("prop_trash_receptacle", "dirty", c0 + 1.6, 0.7, 0.0)
				put.call("prop_bike_rack", "worn", c0 - 2.0, 1.5, 0.0)              # parallel to the shopfront
			"dead":
				var gp0: Vector3 = A.at(b, c0, d * 0.5 + 1.0)
				dec.add(14, Vector2(gp0.x, gp0.z), yaw + 90.0, 1.8, 4.5, S.walk_y, Color(1, 1, 1, 0.7))
				if rr.randf() < 0.6: put.call("prop_shopping_cart", "rusty", c0 + 1.3, 1.5, rr.randf_range(60, 120))
	# back door: the dumpster or bin carts, a cone, the drip of the AC
	I.back_door_clutter(props, rr, A.at(b, w * 0.25, -d * 0.5 - 2.6), yaw + 180.0, "shop")
	return b

## A home building (walk-up, apartment row, dingbat) with its front yard behind a low chain-link fence on the property
## line (gaps at the walks), dressed like the apartment band (walks, door light, mailbox, AC, dish, back of house) but
## with no clipped hedge: the yards here are fenced, not landscaped.
static func home(ctx: Dictionary, folder: String, s: float, face: String, label: String, fence := true, line := A.FRONT) -> Dictionary:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var toward := -1.0 if face.begins_with("-") else 1.0
	var across := line - toward * d * 0.5
	var b: Dictionary = A.place(ctx.bl, sx, sz, folder, s if face.ends_with("v") else across, across if face.ends_with("v") else s, face, label, WEAR)
	ctx.blds.append(b)
	A.dress(b, ctx.paints, ctx.props, ctx.dec, ctx.rr, sx, sz, A.PROP if face.begins_with("-") else line + 3.0, false, false)
	if fence and face.begins_with("-"):
		var gaps: Array = []
		for e: Array in st.get("doors_front", []):
			var wp := A.at(b, float(e[1]), 0.0)
			gaps.append(absf(wp.x) if face.ends_with("u") == false else absf(wp.z))
		gaps.sort()
		var fl := A.PROP + 0.3
		var a0 := s - w * 0.5 - 1.0
		for g: float in gaps:
			_fence_run(ctx, face, fl, a0, g - 0.75)
			a0 = g + 0.75
		_fence_run(ctx, face, fl, a0, s + w * 0.5 + 1.0)
	return b

static func _fence_run(ctx: Dictionary, face: String, line: float, s0: float, s1: float) -> void:
	if s1 - s0 < 0.6: return
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var a := Vector2(sx * s0, sz * line) if face.ends_with("v") else Vector2(sx * line, sz * s0)
	var b := Vector2(sx * s1, sz * line) if face.ends_with("v") else Vector2(sx * line, sz * s1)
	A.privacy(ctx.props, a, b, "fence_chainlink", "fence_chainlink_post")

## A fenced lot (u0..u1, v0..v1): chain-link on every side with ONE rolling gate (gate = "u0" | "u1" | "v0" | "v1",
## at the side's middle), gravel ground, barbed wire when it stores something worth stealing.
## kind: "vacant" (dry ground, a few agaves that seeded themselves, dumped stuff, a billboard facing `bill_face`),
##       "scrap" (containers, a roll-off, drums, k-rails, impounded cars on stalls, a lot light, oil everywhere),
##       "site" (a stalled building site: screened temp fence instead of chain-link, k-rails, the roll-off, drums,
##       cones, a container site office, tyre ruts).
static func lot(ctx: Dictionary, kind: String, u0: float, v0: float, u1: float, v1: float, gate: String, bill_face := "") -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec; var rr: RandomNumberGenerator = ctx.rr
	var paints: Array = ctx.paints
	var P := func(u: float, v: float) -> Vector2: return Vector2(sx * u, sz * v)
	var corners := {"v0": [Vector2(u0, v0), Vector2(u1, v0)], "u1": [Vector2(u1, v0), Vector2(u1, v1)], "v1": [Vector2(u1, v1), Vector2(u0, v1)], "u0": [Vector2(u0, v1), Vector2(u0, v0)]}
	for side: String in corners:
		var a: Vector2 = corners[side][0]; var b: Vector2 = corners[side][1]
		if kind == "site":
			if side == gate:
				var m := (a + b) * 0.5; var dl := (b - a).normalized()
				CC.site_fence(props, P.call(a.x, a.y), P.call((m - dl * 3.5).x, (m - dl * 3.5).y))
				CC.site_fence(props, P.call((m + dl * 3.5).x, (m + dl * 3.5).y), P.call(b.x, b.y))
			else: CC.site_fence(props, P.call(a.x, a.y), P.call(b.x, b.y))
			continue
		if side == gate:
			var m2 := (a + b) * 0.5; var dl2 := (b - a).normalized()
			I.lot_fence(props, P.call(a.x, a.y), P.call((m2 - dl2 * 3.0).x, (m2 - dl2 * 3.0).y), kind == "scrap")
			I.lot_fence(props, P.call((m2 + dl2 * 3.0).x, (m2 + dl2 * 3.0).y), P.call(b.x, b.y), kind == "scrap")
			# the gate leaf, rolled open along the inside of the fence
			var inward := Vector2(-dl2.y, dl2.x)
			var gp: Vector2 = m2 + dl2 * 6.0 + inward * 0.4
			var w3: Vector2 = P.call(gp.x, gp.y)
			var wa: Vector2 = P.call(a.x, a.y); var wb: Vector2 = P.call(b.x, b.y)
			var gyaw := rad_to_deg(atan2(wb.x - wa.x, wb.y - wa.y)) + 90.0
			I.add(props, "fence_gate_rolling_chainlink", "rusty", Vector3(w3.x, S.walk_y(0.0), w3.y), gyaw)
		else:
			I.lot_fence(props, P.call(a.x, a.y), P.call(b.x, b.y), kind == "scrap")
	# ground: gravel (first matching paint wins: put the lot before anything painted later underneath)
	paints.append(A.rect(sx, sz, u0, v0, u1, v1, "gravel"))
	var cu := (u0 + u1) * 0.5; var cv := (v0 + v1) * 0.5
	match kind:
		"vacant":
			for k in 5:
				var pu := rr.randf_range(u0 + 2.0, u1 - 2.0); var pv := rr.randf_range(v0 + 2.0, v1 - 2.0)
				I.add(props, ["plant_agave_americana_small", "plant_iceplant_patch", "plant_agave_americana"][k % 3], "normal", A.q(sx, sz, pu, pv), rr.randf_range(0, 360))
			I.add(props, "prop_shopping_cart", "rusty", A.q(sx, sz, u0 + 3.0, v0 + 4.0), 75.0)
			I.add(props, "prop_water_barrier_orange", "dirty", A.q(sx, sz, u1 - 3.5, v1 - 3.0), 20.0)
			I.add(props, "prop_cone_28in", "dirty", A.q(sx, sz, u1 - 5.5, v1 - 2.5), 40.0)
			for k2 in 6: dec.add(14, P.call(rr.randf_range(u0 + 2, u1 - 2), rr.randf_range(v0 + 2, v1 - 2)), rr.randf_range(0, 180), rr.randf_range(2.0, 5.0), rr.randf_range(2.0, 5.0), S.walk_y, Color(1, 1, 1, 0.6))
			# tyre ruts from the gate where people dump things at night
			var gm: Vector2 = (corners[gate][0] + corners[gate][1]) * 0.5
			I.truck_path(dec, rr, P.call(gm.x, gm.y), P.call(cu, cv))
		"scrap":
			I.containers(props, sx, sz, u0 + 4.0, v0 + 3.5, 2, false, rr, 1)
			I.add(props, "prop_dumpster_rolloff_20yd", "rusty", A.q(sx, sz, u1 - 5.0, v0 + 3.5), 90.0)
			for k3 in 4: I.add(props, "prop_channelizer_drum", "dirty", A.q(sx, sz, u1 - 2.0, v0 + 9.0 + k3 * 0.8), 0.0)
			for k4 in 3: I.add(props, "prop_k_rail", "worn", A.q(sx, sz, u0 + 2.0, v1 - 6.0 - k4 * 3.6), 0.0)
			SL.stalls_u(paints, ctx.stalls, sx, sz, u0 + 8.0, int((u1 - u0 - 14.0) / SL.STALL_W), cv - 2.0, -1.0)
			SL.stalls_u(paints, ctx.stalls, sx, sz, u0 + 8.0, int((u1 - u0 - 14.0) / SL.STALL_W), cv + 2.0, 1.0)
			SL.lot_light(props, sx, sz, u1 - 1.5, v1 - 1.5)
			I.yard_wear(dec, rr, sx, sz, u0, v0, u1, v1, 1.6)
		"site":
			for k5 in 4: I.add(props, "prop_k_rail", "worn", A.q(sx, sz, u0 + 6.0 + k5 * 3.6, v0 + 3.0), 90.0)
			I.add(props, "prop_dumpster_rolloff_20yd", "rusty", A.q(sx, sz, u1 - 6.0, v1 - 4.0), 0.0)
			I.add(props, "prop_container_20ft_white", "dirty", A.q(sx, sz, u0 + 6.0, v1 - 4.0), 90.0)     # the site office nobody visits
			for k6 in 5: I.add(props, "prop_channelizer_drum", "dirty", A.q(sx, sz, cu - 4.0 + k6 * 2.0, cv + 2.0), 0.0)
			for k7 in 3: I.add(props, "prop_cone_28in", "dirty", A.q(sx, sz, cu + 6.0 + k7 * 1.2, cv - 4.0), k7 * 30.0)
			I.add(props, "prop_water_barrier_white", "dirty", A.q(sx, sz, cu - 7.0, cv - 5.0), 0.0)
			var gm2: Vector2 = (corners[gate][0] + corners[gate][1]) * 0.5
			I.truck_path(dec, rr, P.call(gm2.x, gm2.y), P.call(cu, cv))
			I.yard_wear(dec, rr, sx, sz, u0, v0, u1, v1, 0.8)
	# the billboard: high over the lot corner nearest the street it faces, on its own posts inside the fence
	if bill_face != "":
		var bu := u0 + 4.0 if bill_face == "-u" else u0 + 6.0      # in the corner, clear of the gate track
		var bv := v0 + 4.0 if bill_face == "-v" else v0 + 6.0
		var dir := A.face_dir(sx, sz, bill_face)
		I.add(props, "prop_billboard", "worn", A.q(sx, sz, bu, bv), rad_to_deg(atan2(dir.x, dir.y)))

## A dingbat facing a service lane (face "+u" or "+v"; its open ground floor is the carport): centred `s` along the
## lane, back 0.4 m from the lane edge; 4 stalls under it, the outside stair at its end, bin carts by the stair.
static func dingbat(ctx: Dictionary, folder: String, s: float, face: String, label: String) -> Dictionary:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var st := K.building_stats(folder)
	var dw: float = st.footprint_wd[0]; var dd: float = st.footprint_wd[1]
	var across := A.AL0 - 0.4 - dd * 0.5
	var db: Dictionary = A.place(ctx.bl, sx, sz, folder, s if face.ends_with("v") else across, across if face.ends_with("v") else s, face, label, WEAR)
	ctx.blds.append(db)
	CC.back_of_house(ctx.props, db.node, folder, true)
	I.add(ctx.props, "prop_dingbat_stair", "worn", A.at(db, -dw * 0.5 - 0.6, 0.0), rad_to_deg((db.node as Node3D).rotation.y) - 90.0, false)
	if face.ends_with("v"): SL.stalls_u(ctx.paints, ctx.stalls, sx, sz, s - dw * 0.5 + 0.6, 4, A.AL0 - 0.4, -1.0)
	else: SL.stalls_v(ctx.paints, ctx.stalls, sx, sz, s - dw * 0.5 + 0.6, 4, A.AL0 - 0.4, -1.0)
	var bp: Vector3 = A.at(db, -dw * 0.5 - 0.9, dd * 0.5 - 1.2)
	I.add(ctx.props, "prop_trash_cart_black", "worn", bp, 0.0)
	I.add(ctx.props, "prop_trash_cart_blue", "worn", bp + (A.at(db, -dw * 0.5 - 0.9, dd * 0.5 - 2.0) - bp), 0.0)
	# the carport floor: oil under every stall, tyre scuffs at the lane edge
	for k in 4:
		var op: Vector3 = A.at(db, -dw * 0.5 + 0.6 + (k + 0.5) * SL.STALL_W, 0.0)
		W.oil(ctx.dec, ctx.rr, Vector2(op.x, op.z), 0.0, S.walk_y, 0.9)
	return db

## a tagged CMU bin enclosure (two dumpsters) with its overflow, facing `yaw`
static func bins(ctx: Dictionary, u: float, v: float, yaw: float) -> void:
	var at := A.q(ctx.sx, ctx.sz, u, v)
	SL.enclosure(ctx.props, at, yaw)
	SL.enclosure_mess(ctx.props, ctx.rr, at, yaw)
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	for lx: float in [-2.03, 2.03]: I.add(ctx.props, "fence_graffiti_cmu_panel", "worn", at + b * Vector3(lx, 0, -3.65), yaw)    # the tagged wall behind

static func done(ctx: Dictionary, base := "grass", fill := true) -> void:
	if fill: A.fill_open(ctx)          # the residents' yard life where people use it (courts, behind homes)
	# wheel stops on open stalls only (under a dingbat the cars nose up to the stair wall)
	var open: Array = []
	for st: Array in ctx.stalls:
		var under := false
		for bd: Dictionary in ctx.blds:
			var lp: Vector3 = (bd.node as Node3D).transform.affine_inverse() * Vector3(float(st[0]), 0.0, float(st[1]))
			if absf(lp.x) < float(bd.w) * 0.5 + 0.5 and absf(lp.z) < float(bd.d) * 0.5 + 3.5: under = true
		if not under: open.append(st)
	SL.wheel_stops(ctx.props, ctx.rr, open)
	var g: K.Ground = ctx.g
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var a := Vector2(sx * A.PROP, sz * A.PROP); var b := Vector2(sx * A.LEN, sz * A.LEN)
	K.painted_rect(g, minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), ctx.paints, S.walk_y, base)
	A.finish(ctx.root, g, ctx.props, ctx.dec, String(ctx.name), ctx.stalls, ctx.poles)
