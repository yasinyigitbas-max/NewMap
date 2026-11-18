extends RefCounted
## Civic + parks band helpers (v_ne / v_nw / v_se / v_sw, w_civ; the stadium st_stadium). The band is the transition
## between zones (CITY_PLAN.md): public buildings and parks on the SAME grid as the apartment band (it reuses the
## locked j_apt / s_apt streets: residential section, parkway trees, bus stops both ways). Each quadrant is cut by two
## service lanes (u 54-60, v 54-60, entered from the streets' aprons) into four sub-blocks, one use each:
##   A [9.2, 9.2, 54, 54] corner     B [60, 9.2, 100, 54] avenue     C [9.2, 60, 54, 100] side street   D [60, 60, 100, 100] inside
## Kit parks (assets/coronado_kit/parks/park_*.json) are used for their ground and layout, but re-dressed by our rules:
## props worn / dirty (never brand new), fences rebuilt with a post at every joint and ONE gate (the kit fences have no
## posts), wear added where people walk, sit and play.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const S := preload("res://tools/city/pilot/site.gd")
const W := preload("res://tools/city/pilot/pieces/wear_lib.gd")
const I := preload("res://tools/city/pilot/pieces/ind_lib.gd")
const SL := preload("res://tools/city/pilot/pieces/strip_lib.gd")
const CC := preload("res://tools/city/pilot/pieces/cc_lib.gd")
const A := preload("res://tools/city/pilot/pieces/apt_lib.gd")
const PARKS := "res://assets/coronado_kit/parks/"
const SUB := {"A": [9.2, 9.2, 54.0, 54.0], "B": [60.0, 9.2, 100.0, 54.0], "C": [9.2, 60.0, 54.0, 100.0], "D": [60.0, 60.0, 100.0, 100.0]}

static func begin(name: String, sx: float, sz: float) -> Dictionary:
	S.hill_on = false
	var root := Node3D.new(); root.name = name
	var bl := Node3D.new(); bl.name = "Buildings"; root.add_child(bl)
	var pk := Node3D.new(); pk.name = "Parks"; root.add_child(pk)
	var ctx := {"root": root, "bl": bl, "pk": pk, "g": K.Ground.new(), "props": K.Props.new(), "dec": K.Decals.new(), "rr": W.rng_for(name),
		"paints": [], "stalls": [], "poles": [], "blds": [], "sx": sx, "sz": sz, "name": name}
	# the two service lanes, poles along them (power runs behind the public buildings)
	A.alley(ctx.paints, ctx.props, ctx.dec, ctx.rr, sx, sz, true, A.PROP, A.LEN, ctx.poles)
	A.alley(ctx.paints, ctx.props, ctx.dec, ctx.rr, sx, sz, false, A.PROP, A.AL0, ctx.poles, 0.4)
	A.alley(ctx.paints, ctx.props, ctx.dec, ctx.rr, sx, sz, false, A.AL1, A.LEN, ctx.poles, 0.4)
	return ctx

## a public building centred at (u, v) facing `face`, dressed (walk to `walk_to`, door pots and lights, hedges, AC, roof
## dish, back of house); civic buildings get a wider paved forecourt in front of the door instead of a lawn walk
static func bld(ctx: Dictionary, folder: String, u: float, v: float, face: String, label: String, walk_to: float, forecourt := 0.0) -> Dictionary:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var b := A.place(ctx.bl, sx, sz, folder, u, v, face, label, 0.7)
	if forecourt > 0.0:
		var toward := -1.0 if face.begins_with("-") else 1.0
		var line := (v if face.ends_with("v") else u) + toward * float(b.d) * 0.5
		var a0 := minf(line, walk_to); var a1 := maxf(line, walk_to)
		var along := u if face.ends_with("v") else v
		var half := minf(forecourt, float(b.w) * 0.5)
		if face.ends_with("v"): ctx.paints.append(A.rect(sx, sz, along - half, a0, along + half, a1, "plaza"))
		else: ctx.paints.append(A.rect(sx, sz, a0, along - half, a1, along + half, "plaza"))
	A.dress(b, ctx.paints, ctx.props, ctx.dec, ctx.rr, sx, sz, walk_to, forecourt <= 0.0, false)
	ctx.blds.append(b)
	return b

## A kit park placed with its centre at (u, v), local +z toward `gate_face` (quadrant facing, as for buildings).
## Ground: the kit's own near / mid / far ground meshes (a hole is cut in the piece floor under them). Props: the kit
## layout re-dressed (worn / dirty), fences rebuilt with posts at every joint and the gate kept where the kit left it.
static func park(ctx: Dictionary, pname: String, u: float, v: float, gate_face: String, fence_kind := "fence_chainlink", post_kind := "fence_chainlink_post") -> Dictionary:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PARKS + pname + ".json"))
	var dir := A.face_dir(sx, sz, gate_face)
	var yaw := rad_to_deg(atan2(dir.x, dir.y))
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), A.q(sx, sz, u, v))
	var node := Node3D.new(); node.name = pname; node.transform = xf
	(ctx.pk as Node3D).add_child(node)
	var ranges := {"near": [0.0, 62.0], "mid": [58.0, 222.0], "far": [218.0, 1500.0]}
	var col_mesh: Mesh = null
	for tier: String in ranges:
		var f := PARKS + pname + "/" + pname + "_ground_" + tier + ".glb"
		if not ResourceLoader.exists(f): continue
		var inst: Node = (load(f) as PackedScene).instantiate()
		var src := K._first_mesh(inst)
		if src:
			var mi := MeshInstance3D.new(); mi.name = tier; mi.mesh = src.mesh; mi.transform = src.transform
			mi.visibility_range_begin = ranges[tier][0]; mi.visibility_range_end = ranges[tier][1]
			mi.visibility_range_begin_margin = 2.0 if tier != "near" else 0.0; mi.visibility_range_end_margin = 2.0
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.add_child(mi)
			if tier == "near": col_mesh = src.mesh
		inst.free()
	if col_mesh:
		var body := StaticBody3D.new(); body.name = "col"
		var cs := CollisionShape3D.new(); cs.shape = col_mesh.create_trimesh_shape(); body.add_child(cs); node.add_child(body)
	# hole in the piece floor under the park ground (yaw is a multiple of 90)
	var fp: Array = d.footprint
	var hw := float(fp[0]) * 0.5; var hd := float(fp[1]) * 0.5
	if absf(sin(deg_to_rad(yaw))) > 0.5: var t := hw; hw = hd; hd = t
	var c := Vector2(sx * u, sz * v)
	ctx.paints.insert(0, [c.x - hw, c.y - hd, c.x + hw, c.y + hd, "-"])
	# props, re-dressed
	var props: K.Props = ctx.props; var rr: RandomNumberGenerator = ctx.rr
	var fences: Array = []
	for it: Dictionary in d.instances:
		var base := String(it.base)
		var p: Array = it.pos
		var wp := xf * Vector3(float(p[0]), float(p[1]), float(p[2]))
		if base.begins_with("fence"):
			fences.append(Vector2(float(p[0]), float(p[2]))); continue
		if base == "prop_tennis_net":       # two-sided see-through net with its white tape (17 Nov)
			I.add(props, base, "net", wp, yaw + float(it.rot_y)); continue
		var cond := "normal" if (base.begins_with("tree_") or base.begins_with("palm_") or base.begins_with("plant_") or base.begins_with("hedge_")) else ("dirty" if rr.randf() < 0.35 else "worn")
		I.add(props, base, cond, wp, yaw + float(it.rot_y))
	if not fences.is_empty():
		var x0 := INF; var x1 := -INF; var z0 := INF; var z1 := -INF
		for f2: Vector2 in fences:
			x0 = minf(x0, f2.x); x1 = maxf(x1, f2.x); z0 = minf(z0, f2.y); z1 = maxf(z1, f2.y)
		# the kit's gate gap: the side with fewest panels per metre
		var gate_side := "z+"
		var best := 1e9
		for side: String in ["z-", "z+", "x-", "x+"]:
			var n := 0
			for f3: Vector2 in fences:
				if (side == "z-" and absf(f3.y - z0) < 0.2) or (side == "z+" and absf(f3.y - z1) < 0.2) or (side == "x-" and absf(f3.x - x0) < 0.2) or (side == "x+" and absf(f3.x - x1) < 0.2): n += 1
			var L := (x1 - x0) if side.begins_with("z") else (z1 - z0)
			if float(n) / L < best: best = float(n) / L; gate_side = side
		var corners := {"z-": [Vector2(x0, z0), Vector2(x1, z0)], "x+": [Vector2(x1, z0), Vector2(x1, z1)], "z+": [Vector2(x1, z1), Vector2(x0, z1)], "x-": [Vector2(x0, z1), Vector2(x0, z0)]}
		for side2: String in corners:
			var a: Vector2 = corners[side2][0]; var b: Vector2 = corners[side2][1]
			var wa := xf * Vector3(a.x, 0, a.y); var wb := xf * Vector3(b.x, 0, b.y)
			if side2 == gate_side:
				var m := (a + b) * 0.5; var dirl := (b - a).normalized()
				var g0 := xf * Vector3((m - dirl * 0.6).x, 0, (m - dirl * 0.6).y); var g1 := xf * Vector3((m + dirl * 0.6).x, 0, (m + dirl * 0.6).y)
				A.privacy(props, Vector2(wa.x, wa.z), Vector2(g0.x, g0.z), fence_kind, post_kind)
				A.privacy(props, Vector2(g1.x, g1.z), Vector2(wb.x, wb.z), fence_kind, post_kind)
				var gw := xf * Vector3((m + dirl * 0.75 + Vector2(-dirl.y, dirl.x) * 0.6).x, 0, (m + dirl * 0.75 + Vector2(-dirl.y, dirl.x) * 0.6).y)
				var gyaw := yaw + rad_to_deg(atan2(dirl.x, dirl.y)) + 45.0
				I.add(props, "fence_gate_wrought_iron", "worn", Vector3(gw.x, S.walk_y(0.0), gw.z), gyaw)   # a dark metal gate on iron and chain-link alike (never picket)
			else:
				A.privacy(props, Vector2(wa.x, wa.z), Vector2(wb.x, wb.z), fence_kind, post_kind)
	# wear: people walk the paths' edges bare, sit at the benches, play under the swings
	var dec: K.Decals = ctx.dec
	for z: Dictionary in d.zones:
		var r: Array = z.rect
		var kind := String(z.kind)
		if kind == "path" or kind == "plaza" or kind == "apron" or kind == "court":
			var n2 := int(absf((float(r[1]) - float(r[0])) * (float(r[3]) - float(r[2]))) / 40.0) + 1
			for k in n2:
				var lp := Vector3(rr.randf_range(float(r[0]), float(r[1])), 0, rr.randf_range(float(r[2]), float(r[3])))
				var wp2 := xf * lp
				dec.add(0 if kind != "court" else 14, Vector2(wp2.x, wp2.z), rr.randf_range(0, 180), rr.randf_range(1.0, 2.0), rr.randf_range(0.6, 1.2), S.walk_y, Color(0.32, 0.31, 0.3, 0.6) if kind != "court" else Color(1, 1, 1, 0.35), 0.03)
	for it2: Dictionary in d.instances:
		var b2 := String(it2.base)
		if b2 in ["prop_park_bench", "prop_picnic_table", "prop_swing_set", "prop_slide", "prop_play_structure", "prop_drinking_fountain"]:
			var p2: Array = it2.pos
			var wp3 := xf * Vector3(float(p2[0]), 0, float(p2[2]) + (0.9 if b2 == "prop_park_bench" else 0.0))
			dec.add(14, Vector2(wp3.x, wp3.z), yaw, 2.4 if b2 != "prop_park_bench" else 1.8, 1.6, S.walk_y, Color(1, 1, 1, 0.5), 0.03)
	return {"node": node, "hw": hw, "hd": hd, "c": c}

## a parking lot in a sub-block rect (u0..u1, v0..v1): two rows nose-in round an aisle along u, planted ends with a
## tree, a lot light, drains, oil and aisle wear; entered from whichever lane / street edge it touches
static func lot(ctx: Dictionary, u0: float, v0: float, u1: float, v1: float) -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var paints: Array = ctx.paints; var stalls: Array = ctx.stalls; var props: K.Props = ctx.props
	var rr: RandomNumberGenerator = ctx.rr; var dec: K.Decals = ctx.dec
	var vm := (v0 + v1) * 0.5
	var n := int(floor((u1 - u0 - 6.0) / SL.STALL_W))
	var s0 := u0 + 3.0
	SL.stalls_u(paints, stalls, sx, sz, s0, n, vm - 3.5, -1.0)
	SL.stalls_u(paints, stalls, sx, sz, s0, n, vm + 3.5, 1.0)
	# islands BEFORE the asphalt: in painted_rect the first matching paint wins (17 Nov: palms stood in asphalt)
	for e: float in [u0 + 1.4, u1 - 1.4]:
		SL.island(paints, props, rr, sx, sz, e - 1.3, vm - 3.5 - SL.STALL_D, e + 1.3, vm + 3.5 + SL.STALL_D, 1)
	paints.append(A.rect(sx, sz, u0, vm - 3.5 - SL.STALL_D - 0.3, u1, vm + 3.5 + SL.STALL_D + 0.3, "asphalt"))
	SL.lot_light(props, sx, sz, (u0 + u1) * 0.5, vm - 3.5 - SL.STALL_D - 0.8)
	SL.drains(props, sx, sz, [Vector2((u0 + u1) * 0.5 + 6.0, vm)])
	SL.stall_wear(dec, rr, stalls.slice(stalls.size() - 2 * n), 0.65)
	SL.aisle_wear(dec, rr, sx, sz, u0, u1, vm)

## shade groves on the open lawns (17 Nov: the band's sub-blocks had big plain lawns): on a 9 m grid, wherever the
## grass is clear of buildings (+4 m), paving / lanes / lots (+3 m) and every prop (+4 m), a shade tree; every second
## tree gets a bench in its shade facing the nearest street or path, and a bin by one bench in three. Trees stand on
## grass only (the tree audit checks it).
static func groves(ctx: Dictionary) -> void:
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var props: K.Props = ctx.props; var rr: RandomNumberGenerator = ctx.rr; var paints: Array = ctx.paints
	var taken: Array = []
	for k: String in props.items:
		for t: Transform3D in props.items[k]: taken.append(Vector2(t.origin.x, t.origin.z))
	var boxes: Array = []
	for b: Dictionary in ctx.blds: boxes.append([(b.node as Node3D).transform.affine_inverse(), float(b.w) * 0.5 + 4.0, float(b.d) * 0.5 + 4.0])
	for pk: Node in (ctx.pk as Node3D).get_children(): taken.append(Vector2((pk as Node3D).position.x, (pk as Node3D).position.z))
	var trees := ["tree_magnolia_a", "tree_ficus_a", "tree_coral_a", "tree_jacaranda_b", "tree_magnolia_b", "tree_ficus_b", "tree_torrey_pine_a"]
	var n := 0
	var u := A.PROP + 5.0
	while u < A.LEN - 3.0:
		var v := A.PROP + 5.0
		while v < A.LEN - 3.0:
			var p := Vector2(sx * (u + rr.randf_range(-1.5, 1.5)), sz * (v + rr.randf_range(-1.5, 1.5)))
			var ok := true
			for bx: Array in boxes:
				var lp: Vector3 = (bx[0] as Transform3D) * Vector3(p.x, 0.0, p.y)
				if absf(lp.x) < float(bx[1]) and absf(lp.z) < float(bx[2]): ok = false; break
			if ok:
				for pr: Array in paints:
					if String(pr[4]) == "grass": continue
					if p.x > float(pr[0]) - 3.0 and p.x < float(pr[2]) + 3.0 and p.y > float(pr[1]) - 3.0 and p.y < float(pr[3]) + 3.0: ok = false; break
			if ok:
				for tk: Vector2 in taken:
					if tk.distance_to(p) < 4.0: ok = false; break
			if ok:
				I.add(props, trees[n % trees.size()], "normal", Vector3(p.x, S.walk_y(0.0), p.y), rr.randf_range(0, 360))
				taken.append(p)
				if n % 2 == 0:
					var bp := p + Vector2(sx * 2.2, 0.0)
					var clear := true
					for tk2: Vector2 in taken:
						if tk2.distance_to(bp) < 1.6 and tk2 != p: clear = false
					if clear:
						I.add(props, "prop_park_bench", "worn", Vector3(bp.x, S.walk_y(0.0), bp.y), 180.0 if sz > 0 else 0.0)   # facing the avenue side
						taken.append(bp)
						if n % 3 == 0: I.add(props, "prop_trash_receptacle", "worn", Vector3(bp.x + 1.4, S.walk_y(0.0), bp.y), 0.0); taken.append(bp + Vector2(1.4, 0))
						(ctx.dec as K.Decals).add(14, bp + Vector2(0.0, -sz * 0.9), 0.0, 2.0, 1.4, S.walk_y, Color(1, 1, 1, 0.5))
				n += 1
			v += 9.0
		u += 9.0
	print("groves: %d trees" % n)

static func done(ctx: Dictionary) -> void:
	A.fill_open(ctx)      # shared-yard clusters where people would use them (courts, behind buildings, side walls)
	groves(ctx)
	SL.wheel_stops(ctx.props, ctx.rr, ctx.stalls)     # kit batch 2 (17 Nov): a wheel stop at the head of every lot stall
	var g: K.Ground = ctx.g
	var sx: float = ctx.sx; var sz: float = ctx.sz
	var a := Vector2(sx * A.PROP, sz * A.PROP); var b := Vector2(sx * A.LEN, sz * A.LEN)
	K.painted_rect(g, minf(a.x, b.x), minf(a.y, b.y), maxf(a.x, b.x), maxf(a.y, b.y), ctx.paints, S.walk_y, "grass")
	A.finish(ctx.root, g, ctx.props, ctx.dec, String(ctx.name), ctx.stalls, ctx.poles)
