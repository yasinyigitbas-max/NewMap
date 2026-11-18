extends RefCounted
## Gritty edge GROWTH (18 Nov, claude/grow-gritty): the variants of the locked gritty sample (g_ne / g_nw / g_se / g_sw)
## for the blocks of the real street grid. The sample sits on its own flat pad with its own s_grt streets; the blocks
## around it do not: they face 4th St (the strip arterial section, property line 14.3 instead of 9.2, driveway aprons
## where road_art put them) and res / std streets that climb 2 m a block, and they must climb to the sample's pad.
## So a grown block is a SITE piece: one recipe (v1 / v2 / v3) built for one quadrant of one junction
## (review/grow_grt_blocks.json, tools/city/pilot/zoning/grt_sites.py), seeded so no two sites look the same.
##
## What this library adds to grt_lib (never edited: the locked sample was built with it; copies, not changes):
## - the site frame: property lines plu / plv per street, the 4th St aprons, the sub-blocks A [pl..54]^2, B [60..100] x
##   [plv..54], C [plu..54] x [60..100], D [60..100]^2 and the two service lanes at 54-60 (they line up with the
##   sample's lanes and the streets' alley aprons, so the alleys run through the city block);
## - shop() / home() with a property line (grt_lib's are fixed at 9.2);
## - the DRAPE (done()): everything is laid out flat, then lifted onto the site's ground: a Coons patch between the
##   two streets' sidewalks (measured from the BUILT street pieces of city_grid_layout.json, so the joint is exact) and
##   the block's centre (smoothstep inner edges, shared with the neighbour quadrant, flat along a locked sample);
##   every building stands on a level terrace at the height of its front's middle, the ground blends back to the
##   slope over 5 m round it (and to the sidewalk within 2 m of a property line / the neighbour within 2 m of an
##   inner edge); ground re-tessellated to 2 m, props / decals / stalls / poles lifted with it;
## - the gritty rules for fences (the phone found layered see-through things costly here, 40 % more GPU at a tier
##   fade): chain-link only round lots inside the block, never a front fence in line with a lot fence or trees behind
##   it; front yards on the streets get weathered board side fences (perpendicular to the street) and no front fence.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const C := preload("res://tools/city/pilot/pieces/civ_lib.gd")
const G := preload("res://tools/city/pilot/pieces/grt_lib.gd")
const TABLE := "res://map_dc/coronado/city_kit/review/grow_grt_blocks.json"
const LAYOUT := "res://map_dc/coronado/city_kit/city_grid_layout.json"
const FORE := 2.5
const WEAR := 0.9
const AL0 := 54.0
const AL1 := 60.0
const LEN := 100.0

## ------------------------------------------------------------------------------------------------ site + context
static func site(piece: String) -> Dictionary:
	var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TABLE))
	for s: Dictionary in t.sites:
		if String(s.piece) == piece: return s
	push_error("no site " + piece); return {}

static func begin(piece: String) -> Dictionary:
	var st := site(piece)
	S.hill_on = false
	var sx := float(st.sx); var sz := float(st.sz)
	var root := Node3D.new(); root.name = piece
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var ctx := {"root": root, "bl": bl, "g": K.Ground.new(), "props": K.Props.new(), "dec": K.Decals.new(), "rr": W.rng_for(piece),
		"paints": [], "stalls": [], "poles": [], "blds": [], "shops": [], "sx": sx, "sz": sz, "name": piece, "site": st,
		"plu": float(st.plu), "plv": float(st.plv), "apr": st.apr, "shoplist": []}
	# the lanes: U along u at v 54-60 from the Ave to the inner edge; V along v at u 54-60 from the numbered street
	# (when an apron is there to drive in) or from behind the street row, to the inner edge
	A.alley(ctx.paints, ctx.props, ctx.dec, ctx.rr, sx, sz, true, ctx.plu, LEN, ctx.poles)
	var v0 := float(ctx.plv) if bool(st.lane_v_open) else 40.0
	A.alley(ctx.paints, ctx.props, ctx.dec, ctx.rr, sx, sz, false, v0, AL0, ctx.poles, 0.4)
	A.alley(ctx.paints, ctx.props, ctx.dec, ctx.rr, sx, sz, false, AL1, LEN, ctx.poles, 0.4)
	if bool(st.lane_v_open):
		# the lane mouth widens to the 9 m apron it meets (aprons centred at 56 / 62 overlap the lane at 54-60)
		for a: float in ctx.apr:
			if a - 4.5 < AL1 and a + 4.5 > AL0:
				ctx.paints.append(A.rect(sx, sz, minf(AL0, a - 4.5), ctx.plv, maxf(AL1, a + 4.5), ctx.plv + 6.0, "asphalt"))
	return ctx

## true when [s0, s1] along the numbered street is clear of every driveway apron (+0.5 m)
static func apron_free(ctx: Dictionary, s0: float, s1: float) -> bool:
	for a: float in ctx.apr:
		if s0 < a + 5.0 and s1 > a - 5.0: return false
	return true

## an asphalt drive from an apron straight back to (and including) depth v1
static func drive(ctx: Dictionary, a: float, v1: float, w := 7.0) -> void:
	ctx.paints.append(A.rect(ctx.sx, ctx.sz, a - w * 0.5, ctx.plv, a + w * 0.5, v1, "asphalt"))
	I.truck_path(ctx.dec, ctx.rr, Vector2(ctx.sx * a, ctx.sz * ctx.plv), Vector2(ctx.sx * a, ctx.sz * v1))

## ------------------------------------------------------------------------------------------------ buildings
## a shop building on its street's property line behind a 2.5 m paved forecourt (grt_lib.shop with the line as a
## parameter). face "-v": on the numbered street (line plv), "-u": on the Ave (line plu). kinds per bay as grt_lib
## ("pawn", "laundry", "liquor", "bar", "dead", "none") plus "diner" and "cash" (forecourt life only; the room is the
## shop's own, see shops). open = [[shop door index (the contract's shop entrances, left to right), kind, name], ...]: the businesses that get a room (grt rooms table).
static func shop(ctx: Dictionary, folder: String, s: float, face: String, label: String, kinds: Array, open: Array = []) -> Dictionary:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var line: float = ctx.plv if face.ends_with("v") else ctx.plu
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var across := line + FORE + d * 0.5
	var b: Dictionary = A.place(ctx.bl, sx, sz, folder, s if face.ends_with("v") else across, across if face.ends_with("v") else s, face, label, WEAR)
	ctx.blds.append(b); ctx.shops.append(b)
	var props: K.Props = ctx.props; var dec: K.Decals = ctx.dec; var rr: RandomNumberGenerator = ctx.rr
	if face.ends_with("v"): ctx.paints.append(A.rect(sx, sz, s - w * 0.5 - 1.0, line, s + w * 0.5 + 1.0, line + FORE + 0.05, "concrete"))
	else: ctx.paints.append(A.rect(sx, sz, line, s - w * 0.5 - 1.0, line + FORE + 0.05, s + w * 0.5 + 1.0, "concrete"))
	CC.back_of_house(props, b.node, folder, false)
	I.bld_wear(dec, rr, b.node, w, d, folder)
	A.balconies(b, props)
	var yaw := rad_to_deg((b.node as Node3D).rotation.y)
	var doors: Array = []
	for e: Array in st.get("doors_front", []): doors.append(float(e[1]))
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
			if pl.distance_to(Vector2(cx, out)) < 1.0: return
		placed.append(Vector2(cx, out))
		I.add(props, base, cond, A.at(b, cx, d * 0.5 + out), yaw + dyaw)
	var nb := kinds.size()
	for k in nb:
		var c0 := -w * 0.5 + w * (k + 0.5) / nb
		match String(kinds[k]):
			"pawn":
				put.call("prop_trash_receptacle", "dirty", c0 + 2.2, 0.7, 0.0)
				put.call("prop_bollard_iron", "rusty", c0 - 2.4, 0.5, 0.0)          # against ram raids
			"laundry":
				put.call("prop_park_bench", "worn", c0 - 1.0, 0.75, 0.0)
				put.call("prop_vending_soda", "worn", c0 + 2.3, 0.9, 0.0)
				put.call("prop_shopping_cart", "dirty", c0 + 1.2, 1.6, rr.randf_range(-40.0, 40.0))
			"liquor":
				put.call("prop_newspaper_box_red", "worn", c0 - 2.6, 0.7, 0.0)
				put.call("prop_ice_chest", "worn", c0 + 1.2, 0.9, 0.0)
				put.call("prop_trash_receptacle", "dirty", c0 + 3.0, 0.8, 0.0)
			"bar":
				put.call("prop_trash_receptacle", "dirty", c0 + 1.6, 0.7, 0.0)
				put.call("prop_bike_rack", "worn", c0 - 2.0, 1.5, 0.0)
			"diner":
				put.call("prop_newspaper_box_blue", "worn", c0 - 2.2, 0.7, 0.0)
				put.call("prop_trash_receptacle", "dirty", c0 + 2.4, 0.7, 0.0)
			"cash":
				put.call("prop_vending_snack", "worn", c0 + 2.2, 0.9, 0.0)
			"dead":
				var gp0: Vector3 = A.at(b, c0, d * 0.5 + 1.0)
				dec.add(14, Vector2(gp0.x, gp0.z), yaw + 90.0, 1.8, 4.5, S.walk_y, Color(1, 1, 1, 0.7))
				if rr.randf() < 0.6: put.call("prop_shopping_cart", "rusty", c0 + 1.3, 1.5, rr.randf_range(60, 120))
	I.back_door_clutter(props, rr, A.at(b, w * 0.25, -d * 0.5 - 2.6), yaw + 180.0, "shop")
	for o: Array in open: (ctx.shoplist as Array).append({"label": label, "model": folder, "door_index": int(o[0]), "kind": String(o[1]), "name": String(o[2])})
	return b

## a home (walk-up, apartment row, narrow house) on its street behind a front yard (3 m) or on the line (stoop, 0.5 m):
## dressed like the apartment band; NO front fence (fence rule above); weathered board side fences between yards when
## side_fence; the yard is grass the tenants wore through.
static func home(ctx: Dictionary, folder: String, s: float, face: String, label: String, yard := 3.0, side_fence := true) -> Dictionary:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var line: float = ctx.plv if face.ends_with("v") else ctx.plu
	var st := K.building_stats(folder)
	var w: float = st.footprint_wd[0]; var d: float = st.footprint_wd[1]
	var across := line + yard + d * 0.5
	var b: Dictionary = A.place(ctx.bl, sx, sz, folder, s if face.ends_with("v") else across, across if face.ends_with("v") else s, face, label, WEAR)
	ctx.blds.append(b)
	A.dress(b, ctx.paints, ctx.props, ctx.dec, ctx.rr, sx, sz, line, false, true)
	if side_fence:
		for e: float in [-1.0, 1.0]:      # board fence along each side yard, from the front corner back 8 m
			var a0: float = s + e * (w * 0.5 + 0.7)
			if face.ends_with("v"): A.privacy(ctx.props, Vector2(sx * a0, sz * (line + yard + 0.5)), Vector2(sx * a0, sz * (line + yard + 8.5)), "fence_weathered_board", "fence_post_privacy")
			else: A.privacy(ctx.props, Vector2(sx * (line + yard + 0.5), sz * a0), Vector2(sx * (line + yard + 8.5), sz * a0), "fence_weathered_board", "fence_post_privacy")
	I.add(ctx.props, ["prop_house_numbers_tile", "prop_house_numbers_wood"][ctx.rr.randi() % 2], "worn", A.at(b, w * 0.5 - 0.6, d * 0.5 + 0.04, 2.0), rad_to_deg((b.node as Node3D).rotation.y), false)
	return b

## a garage on a lane (rear of a house lot), door to the lane: face "+u" / "+v" toward the lane at 54 from inside
static func garage(ctx: Dictionary, folder: String, s: float, face: String, label: String) -> Dictionary:
	var st := K.building_stats(folder)
	var d: float = st.footprint_wd[1]
	var across := AL0 - 0.6 - d * 0.5
	var b: Dictionary = A.place(ctx.bl, ctx.sx, ctx.sz, folder, s if face.ends_with("v") else across, across if face.ends_with("v") else s, face, label, WEAR)
	ctx.blds.append(b)
	var dp: Vector3 = A.at(b, 0.0, d * 0.5 + 0.8)
	W.oil(ctx.dec, ctx.rr, Vector2(dp.x, dp.z), 0.0, S.walk_y, 0.7)
	I.add(ctx.props, ["prop_trash_cart_black", "prop_trash_cart_green"][ctx.rr.randi() % 2], "worn", A.at(b, float(st.footprint_wd[0]) * 0.5 + 0.5, d * 0.5 - 0.4), rad_to_deg((b.node as Node3D).rotation.y))
	return b

## a plain building (warehouse, repair shop, car wash) facing a street or lane, with its services and wear
static func work(ctx: Dictionary, folder: String, u: float, v: float, face: String, label: String) -> Dictionary:
	var b := A.place(ctx.bl, ctx.sx, ctx.sz, folder, u, v, face, label, WEAR)
	ctx.blds.append(b)
	CC.back_of_house(ctx.props, b.node, folder, false)
	I.bld_wear(ctx.dec, ctx.rr, b.node, b.w, b.d, folder)
	return b

## rooftop plant on a flat-roofed building: vent boxes, turbine and plumbing vents (old buildings, many small vents)
static func roof(ctx: Dictionary, b: Dictionary, n := 3) -> void:
	var st := K.building_stats(String(b.folder))
	var h := float(st.get("height", 6.0))
	var yaw := rad_to_deg((b.node as Node3D).rotation.y)
	var kinds := ["prop_vent_box", "prop_vent_turbine", "prop_vent_plumbing", "prop_ac_condenser_compact"]
	for k in n:
		var lx: float = ctx.rr.randf_range(-float(b.w) * 0.3, float(b.w) * 0.3); var lz: float = ctx.rr.randf_range(-float(b.d) * 0.3, float(b.d) * 0.2)
		I.add(ctx.props, kinds[(k + ctx.rr.randi()) % kinds.size()], "rusty" if ctx.rr.randf() < 0.5 else "worn", A.at(b, lx, lz, h - 0.05), yaw + 90.0 * (ctx.rr.randi() % 4), false)

## downspouts on the street corners of a building (rust streaks are on the models; the pipes are props)
static func downspouts(ctx: Dictionary, b: Dictionary) -> void:
	var yaw := rad_to_deg((b.node as Node3D).rotation.y)
	for e: float in [-1.0, 1.0]:
		I.add(ctx.props, "prop_downspout_3m", "rusty", A.at(b, e * (float(b.w) * 0.5 - 0.15), float(b.d) * 0.5 + 0.06), yaw, false)

## ------------------------------------------------------------------------------------------------ the drape
class Field:
	var tris := {}            # cell key -> Array of [a, b, c] (Vector3, piece-local)
	var fb := PackedFloat32Array(); var fl := PackedFloat32Array()   # sidewalk heights along the two streets, every 1 m (0..100)
	var c := 0.0; var plu := 9.2; var plv := 9.2; var sx := 1.0; var sz := 1.0
	var terr: Array = []      # [inverse xf, half w, half d, hb]

	func _key(x: float, z: float) -> Vector2i: return Vector2i(floori(x / 4.0), floori(z / 4.0))

	func add_tri(a: Vector3, b: Vector3, cc: Vector3) -> void:
		var n := (b - a).cross(cc - a)
		if n.length_squared() < 1e-8 or absf(n.normalized().y) < 0.6: return
		var k0 := _key(minf(a.x, minf(b.x, cc.x)), minf(a.z, minf(b.z, cc.z))); var k1 := _key(maxf(a.x, maxf(b.x, cc.x)), maxf(a.z, maxf(b.z, cc.z)))
		for i in range(k0.x, k1.x + 1):
			for j in range(k0.y, k1.y + 1):
				var kk := Vector2i(i, j)
				if not tris.has(kk): tris[kk] = []
				(tris[kk] as Array).append([a, b, cc])

	## top street surface at (x, z) (piece-local), NAN when no street piece covers it
	func street_y(x: float, z: float) -> float:
		var best := NAN
		for t: Array in tris.get(_key(x, z), []):
			var a: Vector3 = t[0]; var b: Vector3 = t[1]; var cc: Vector3 = t[2]
			var v0 := Vector2(b.x - a.x, b.z - a.z); var v1 := Vector2(cc.x - a.x, cc.z - a.z); var v2 := Vector2(x - a.x, z - a.z)
			var den := v0.x * v1.y - v1.x * v0.y
			if absf(den) < 1e-9: continue
			var l1 := (v2.x * v1.y - v1.x * v2.y) / den; var l2 := (v0.x * v2.y - v2.x * v0.y) / den
			if l1 < -1e-4 or l2 < -1e-4 or l1 + l2 > 1.0001: continue
			var y := a.y + l1 * (b.y - a.y) + l2 * (cc.y - a.y)
			if is_nan(best) or y > best: best = y
		return best

	func _at(arr: PackedFloat32Array, s: float) -> float:
		var t := clampf(s, 0.0, 100.0); var i := mini(int(t), 99); var f := t - i
		return lerpf(arr[i], arr[i + 1], f)

	static func _ss(t: float) -> float:
		var x := clampf(t, 0.0, 1.0); return x * x * (3.0 - 2.0 * x)

	## the slope surface (Coons patch) at quadrant (u, v)
	func base(u: float, v: float) -> float:
		var s := clampf((u - plu) / (LEN - plu), 0.0, 1.0); var t := clampf((v - plv) / (LEN - plv), 0.0, 1.0)
		var b_u := _at(fb, u); var l_v := _at(fl, v)
		var p10 := _at(fb, LEN); var p01 := _at(fl, LEN); var p00 := (_at(fb, plu) + _at(fl, plv)) * 0.5
		var r_v := lerpf(p10, c, _ss(t)); var t_u := lerpf(p01, c, _ss(s))
		return (1.0 - s) * l_v + s * r_v + (1.0 - t) * b_u + t * t_u - ((1.0 - s) * (1.0 - t) * p00 + s * (1.0 - t) * p10 + (1.0 - s) * t * p01 + s * t * c)

	## the final ground height at piece-local (x, z): the slope with the building terraces blended in
	func h(x: float, z: float) -> float:
		var u := x * sx; var v := z * sz
		var y := base(u, v)
		var edge := minf(minf(u - plu, v - plv), minf(LEN - u, LEN - v))
		var e := _ss(edge / 2.0)
		if e <= 0.0: return y
		var bw := 0.0; var bh := y
		for tr: Array in terr:
			var lp: Vector3 = (tr[0] as Transform3D) * Vector3(x, 0.0, z)
			var dx := maxf(absf(lp.x) - float(tr[1]), 0.0); var dz := maxf(absf(lp.z) - float(tr[2]), 0.0)
			var dist := Vector2(dx, dz).length()
			var wgt := 1.0 - _ss((dist - 1.0) / 5.0)
			if wgt > bw: bw = wgt; bh = float(tr[3])
		return lerpf(y, bh, bw * e)

	## a prop's height: on (or 0.5 m round) a building it goes with the building's terrace (wall lights, AC units,
	## roof plant, the bins at the back door), elsewhere with the ground
	func hp(x: float, z: float) -> float:
		for tr: Array in terr:
			var lp: Vector3 = (tr[0] as Transform3D) * Vector3(x, 0.0, z)
			if absf(lp.x) < float(tr[1]) + 0.5 and absf(lp.z) < float(tr[2]) + 0.5: return float(tr[3])
		return h(x, z)

static func _field(ctx: Dictionary) -> Field:
	var st: Dictionary = ctx.site
	var F := Field.new()
	F.sx = ctx.sx; F.sz = ctx.sz; F.plu = ctx.plu; F.plv = ctx.plv
	var ju := float(st.junction[0]); var jv := float(st.junction[1]); var pad := float(st.pad)
	F.c = float(st.centre) + 0.15 - pad
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var cache := {}
	for r: Dictionary in lay.instances:
		var pc := String(r.piece)
		if not (pc.begins_with("j_") or pc.begins_with("s_")): continue
		var p: Array = r.pos
		if absf(float(p[0]) - ju) > 160.0 or absf(float(p[2]) - jv) > 160.0: continue
		var path := "res://map_dc/coronado/city_kit/pieces/%s.scn" % pc
		if not ResourceLoader.exists(path): continue
		if not cache.has(pc):
			var inst: Node = (load(path) as PackedScene).instantiate()
			var gm := inst.get_node_or_null("ground") as MeshInstance3D
			cache[pc] = gm.mesh.get_faces() if gm and gm.mesh else PackedVector3Array()
			inst.free()
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(float(r.get("yaw", 0.0)))), Vector3(float(p[0]) - ju, float(p[1]) - pad, float(p[2]) - jv))
		var faces: PackedVector3Array = cache[pc]
		for k in range(0, faces.size(), 3):
			F.add_tri(xf * faces[k], xf * faces[k + 1], xf * faces[k + 2])
	# the two sidewalks just outside the property lines, every metre (gaps in a piece's mesh: nearest found value)
	var fb := PackedFloat32Array(); var fl := PackedFloat32Array(); fb.resize(101); fl.resize(101)
	var lastb := 0.15; var lastl := 0.15; var miss := 0
	for i in 101:
		var s := float(i)
		var yb := F.street_y(F.sx * maxf(s, F.plu), F.sz * (F.plv - 0.5))
		var yl := F.street_y(F.sx * (F.plu - 0.5), F.sz * maxf(s, F.plv))
		if is_nan(yb): yb = lastb; miss += 1
		if is_nan(yl): yl = lastl; miss += 1
		fb[i] = yb; fl[i] = yl; lastb = yb; lastl = yl
	F.fb = fb; F.fl = fl
	print("GRT_FIELD %s: street tris %d, sidewalk misses %d, street ends %.2f / %.2f, corner %.2f, centre %.2f (m over the pad)" % [ctx.name, F.tris.size(), miss, fb[100], fl[100], fb[10], F.c])
	return F

## lift everything onto the site's ground (see the header); called by done() before the piece is finished
static func drape(ctx: Dictionary) -> void:
	var F := _field(ctx)
	for b: Dictionary in ctx.blds:
		var n: Node3D = b.node
		var fp: Vector3 = n.transform * Vector3(0.0, 0.0, float(b.d) * 0.5)
		var hb := F.base(fp.x * F.sx, fp.z * F.sz)
		F.terr.append([n.transform.affine_inverse(), float(b.w) * 0.5, float(b.d) * 0.5, hb])
		n.position.y = hb
	var hf := func(x: float, z: float) -> float: return F.h(x, z)
	# ground: split every up-facing triangle to <= 2 m edges, heights from the field, smooth normals from its slope
	var g: K.Ground = ctx.g
	for m: String in g.surf.keys():
		var s: Array = g.surf[m]
		var V: PackedVector3Array = s[0]; var N: PackedVector3Array = s[1]; var U: PackedVector2Array = s[2]
		var nv := PackedVector3Array(); var nn := PackedVector3Array(); var nu := PackedVector2Array()
		var stack: Array = []
		for k in range(0, V.size(), 3):
			var flat := absf(N[k].y) > 0.6
			if not flat:
				for j in 3:
					var p := V[k + j]; nv.append(Vector3(p.x, p.y + F.h(p.x, p.z) - 0.15, p.z)); nn.append(N[k + j]); nu.append(U[k + j])
				continue
			stack.append([V[k], V[k + 1], V[k + 2], U[k], U[k + 1], U[k + 2]])
			while not stack.is_empty():
				var t: Array = stack.pop_back()
				var a: Vector3 = t[0]; var b2: Vector3 = t[1]; var c2: Vector3 = t[2]
				var lab := Vector2(a.x - b2.x, a.z - b2.z).length(); var lbc := Vector2(b2.x - c2.x, b2.z - c2.z).length(); var lca := Vector2(c2.x - a.x, c2.z - a.z).length()
				var mx := maxf(lab, maxf(lbc, lca))
				if mx > 2.0:
					# split the longest edge (keeps the winding)
					if mx == lab:
						var m3 := (a + b2) * 0.5; var mu: Vector2 = (t[3] + t[4]) * 0.5
						stack.append([a, m3, c2, t[3], mu, t[5]]); stack.append([m3, b2, c2, mu, t[4], t[5]])
					elif mx == lbc:
						var m4 := (b2 + c2) * 0.5; var mu2: Vector2 = (t[4] + t[5]) * 0.5
						stack.append([a, b2, m4, t[3], t[4], mu2]); stack.append([a, m4, c2, t[3], mu2, t[5]])
					else:
						var m5 := (c2 + a) * 0.5; var mu3: Vector2 = (t[5] + t[3]) * 0.5
						stack.append([a, b2, m5, t[3], t[4], mu3]); stack.append([m5, b2, c2, mu3, t[4], t[5]])
					continue
				for j2 in 3:
					var p2: Vector3 = t[j2]
					var y := F.h(p2.x, p2.z)
					nv.append(Vector3(p2.x, p2.y + y - 0.15, p2.z))
					var gx := (F.h(p2.x + 0.5, p2.z) - F.h(p2.x - 0.5, p2.z)); var gz := (F.h(p2.x, p2.z + 0.5) - F.h(p2.x, p2.z - 0.5))
					nn.append(Vector3(-gx, 1.0, -gz).normalized()); nu.append(t[3 + j2])
		g.surf[m] = [nv, nn, nu]
	# props (drawn and colliders), decals, stalls, poles
	var props: K.Props = ctx.props
	for key: String in props.items:
		var arr: Array = props.items[key]
		for i in arr.size():
			var tf: Transform3D = arr[i]; tf.origin.y += F.hp(tf.origin.x, tf.origin.z) - 0.15; arr[i] = tf
	for ci in props.col_items.size():
		var it: Array = props.col_items[ci]
		var tc: Transform3D = it[2]; tc.origin.y += F.hp(tc.origin.x, tc.origin.z) - 0.15; it[2] = tc
	var dec: K.Decals = ctx.dec
	var DV := dec.V
	for i in DV.size(): DV[i].y += F.h(DV[i].x, DV[i].z) - 0.15
	dec.V = DV
	var ns: Array = []
	for s2: Array in ctx.stalls:
		var x := float(s2[0]); var z := float(s2[1])
		ns.append([x, z, float(s2[2]), F.h(x, z) - 0.15, (F.h(x, z + 0.5) - F.h(x, z - 0.5))])
	ctx.stalls = ns
	for pl: Array in ctx.poles:
		var pp: Vector3 = pl[0]; pp.y += F.h(pp.x, pp.z) - 0.15; pl[0] = pp
	ctx["field"] = F

## ------------------------------------------------------------------------------------------------ finish
static func done(ctx: Dictionary, base := "grass", fill := true) -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	if fill: A.fill_open(ctx)
	# nothing of the block on the streets: drop any prop in front of a property line (fill_open and the shared
	# helpers know only the 9.2 line) or past the inner edges
	var props: K.Props = ctx.props
	var inside := func(p: Vector3) -> bool:
		var u := p.x * sx; var v := p.z * sz
		return u >= float(ctx.plu) + 0.3 and v >= float(ctx.plv) + 0.3 and u <= LEN - 0.2 and v <= LEN - 0.2
	for k: String in props.items.keys():
		var keep: Array = []
		for t: Transform3D in props.items[k]:
			if inside.call(t.origin): keep.append(t)
		props.items[k] = keep
	var kc: Array = []
	for it: Array in props.col_items:
		if inside.call((it[2] as Transform3D).origin): kc.append(it)
	props.col_items = kc
	# wheel stops on open stalls only (grt_lib.done)
	var open: Array = []
	for st: Array in ctx.stalls:
		var under := false
		for bd: Dictionary in ctx.blds:
			var lp: Vector3 = (bd.node as Node3D).transform.affine_inverse() * Vector3(float(st[0]), 0.0, float(st[1]))
			if absf(lp.x) < float(bd.w) * 0.5 + 0.5 and absf(lp.z) < float(bd.d) * 0.5 + 3.5: under = true
		if not under: open.append(st)
	SL.wheel_stops(props, ctx.rr, open, "prop_wheel_stop_rubber" if ctx.rr.randf() < 0.5 else "prop_wheel_stop_concrete")
	_prune(ctx)
	# no tree within 0.9 m of a fence (apt_lib.done)
	var fence_pts: Array = []
	for k2: String in props.items:
		if not k2.begins_with("fence_"): continue
		for t2: Transform3D in props.items[k2]:
			for f: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
				var fp := t2.origin + t2.basis.x.normalized() * f
				fence_pts.append(Vector2(fp.x, fp.z))
	for k3: String in props.items.keys():
		if not (k3.begins_with("tree_") or k3.begins_with("palm_")): continue
		var keep2: Array = []
		for t3: Transform3D in props.items[k3]:
			var ok := true
			for fp2: Vector2 in fence_pts:
				if fp2.distance_to(Vector2(t3.origin.x, t3.origin.z)) < 0.9: ok = false; break
			if ok: keep2.append(t3)
		props.items[k3] = keep2
	var g: K.Ground = ctx.g
	var a := Vector2(sx * float(ctx.plu), sz * float(ctx.plv)); var b := Vector2(sx * LEN, sz * LEN)
	K.painted_rect(g, minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), ctx.paints, S.walk_y, base)
	drape(ctx)
	var root: Node3D = ctx.root
	root.set_meta("site", ctx.site)
	root.set_meta("shops", ctx.shoplist)
	A.finish(root, g, props, ctx.dec, String(ctx.name), ctx.stalls, ctx.poles)
	_write_shops(ctx)

## the ground material at (x, z): the first paint that holds the point (painted_rect's rule), else the base
static func _mat_at(ctx: Dictionary, x: float, z: float, base: String) -> String:
	for p: Array in ctx.paints:
		if x > float(p[0]) and x < float(p[2]) and z > float(p[1]) and z < float(p[3]): return String(p[4])
	return base

## the validator's rules applied while building (validate.gd overlap / inside, audit_trees): every ground prop keeps
## clear of the others and of the buildings; when two collide the one that matters less goes (fences and gates first,
## then trees, then big things, then small clutter), a tree on paving goes. Mounted / lifted props are not touched.
static func _prune(ctx: Dictionary, base_mat := "grass") -> void:
	var props: K.Props = ctx.props
	var items: Array = []     # [rank, key, index, centre, half, ang, y]
	for k: String in props.items:
		var bname := k.get_slice("|", 0)
		var e := K.manifest(bname)
		var mounted := String(e.get("mount", "ground")) != "ground"
		if bname.begins_with("plant_iceplant") or bname.begins_with("prop_shade_sail"): continue
		var fw := float(e.get("footprint_w", 0.5)); var fd := float(e.get("footprint_d", 0.5))
		var rank := 3
		if bname.begins_with("fence_"): rank = 0
		elif bname.begins_with("tree_") or bname.begins_with("palm_"): rank = 1; fw = 0.6; fd = 0.6
		elif fw * fd > 3.0: rank = 2
		if bname.begins_with("prop_utility_pole") or bname.begins_with("prop_lot_light") or bname.begins_with("prop_billboard"): fw = 0.45; fd = 0.45; rank = 0
		var arr: Array = props.items[k]
		for i in arr.size():
			var t: Transform3D = arr[i]
			var up := mounted or t.origin.y - 0.15 > 1.2
			items.append([rank + (4 if up else 0), k, i, Vector2(t.origin.x, t.origin.z), Vector2(fw, fd) * 0.5, atan2(t.basis.z.x, t.basis.z.z), t.origin.y, up])
	items.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var boxes: Array = []
	for b: Dictionary in ctx.blds:
		var n: Node3D = b.node
		boxes.append([Vector2(n.position.x, n.position.z), Vector2(float(b.w), float(b.d)) * 0.5 - Vector2(0.15, 0.15), atan2(n.transform.basis.z.x, n.transform.basis.z.z)])
	var kept: Array = []
	var drop := {}
	for it: Array in items:
		var ok := true
		var key := String(it[1])
		if int(it[0]) == 1:
			var m := _mat_at(ctx, (it[3] as Vector2).x, (it[3] as Vector2).y, base_mat)
			if not (m in ["grass", "mulch", "gravel"]): ok = false
		if ok and not bool(it[7]):
			for bx: Array in boxes:
				if _hit(it[3], it[4], it[5], bx[0], bx[1], bx[2]): ok = false; break
		if ok:
			for o: Array in kept:
				if (it[3] as Vector2).distance_to(o[3]) > (it[4] as Vector2).length() + (o[4] as Vector2).length(): continue
				if key.begins_with("fence_") and String(o[1]).begins_with("fence_"): continue
				if absf(float(it[6]) - float(o[6])) > 1.5: continue
				if bool(it[7]) and bool(o[7]) and absf(float(it[6]) - float(o[6])) > 0.6: continue
				if _hit(it[3], (it[4] as Vector2) * 0.97, it[5], o[3], (o[4] as Vector2) * 0.97, o[5]): ok = false; break
		if ok: kept.append(it)
		else:
			if not drop.has(key): drop[key] = {}
			drop[key][int(it[2])] = true
	var nd := 0
	for k2: String in drop:
		var arr2: Array = props.items[k2]; var keep: Array = []
		for i2 in arr2.size():
			if not drop[k2].has(i2): keep.append(arr2[i2])
			else: nd += 1
		props.items[k2] = keep
	# colliders of dropped props: keep only colliders that still have a drawn twin
	var live := {}
	for k3: String in props.items:
		for t3: Transform3D in props.items[k3]: live["%s@%.2f,%.2f" % [k3, t3.origin.x, t3.origin.z]] = true
	var kc: Array = []
	for ci: Array in props.col_items:
		var tt: Transform3D = ci[2]
		if live.has("%s|%s@%.2f,%.2f" % [ci[0], ci[1], tt.origin.x, tt.origin.z]): kc.append(ci)
	props.col_items = kc
	print("GRT_PRUNE %s: %d props dropped (validator rules)" % [ctx.name, nd])

static func _hit(ca: Vector2, ha: Vector2, aa: float, cb: Vector2, hb: Vector2, ab: float) -> bool:
	var axes := [Vector2(cos(aa), -sin(aa)), Vector2(sin(aa), cos(aa)), Vector2(cos(ab), -sin(ab)), Vector2(sin(ab), cos(ab))]
	var d := cb - ca
	for ax: Vector2 in axes:
		var ra := ha.x * absf(Vector2(cos(aa), -sin(aa)).dot(ax)) + ha.y * absf(Vector2(sin(aa), cos(aa)).dot(ax))
		var rb := hb.x * absf(Vector2(cos(ab), -sin(ab)).dot(ax)) + hb.y * absf(Vector2(sin(ab), cos(ab)).dot(ax))
		if absf(d.dot(ax)) > ra + rb: return false
	return true

## the open shops of this piece for the rooms (tools/city/rooms/assign_grt.py reads these)
static func _write_shops(ctx: Dictionary) -> void:
	var out: Array = []
	var st: Dictionary = ctx.site
	var ju := float(st.junction[0]); var jv := float(st.junction[1])
	for e: Dictionary in ctx.shoplist:
		var n: Node3D = null
		for b: Dictionary in ctx.blds:
			if String((b.node as Node3D).name) == String(e.label): n = b.node
		if n == null: continue
		var e2 := e.duplicate()
		e2["pos"] = [n.position.x + ju, n.position.y + float(st.pad), n.position.z + jv]
		e2["yaw"] = rad_to_deg(n.rotation.y)
		out.append(e2)
	DirAccess.make_dir_recursive_absolute("res://map_dc/coronado/city_kit/review/grow_grt")
	var f := FileAccess.open("res://map_dc/coronado/city_kit/review/grow_grt/%s_shops.json" % String(ctx.name), FileAccess.WRITE)
	f.store_string(JSON.stringify({"piece": ctx.name, "shops": out}, " ")); f.close()
