extends SceneTree
## Built-in interior pilot (22 Nov 2026, Yasin: "make our shop models in the kits have interiors by themselves"):
## com_bank (Crownado Savings, n_hs_b2_amber). Writes, next to the kit model:
##   shop_com_bank_near.glb        the near tier, SAME file / node names (drop-in): the exterior with its shop door and its
##                                  ten ground-floor windows opened for real, plus the interior shell in the same mesh and
##                                  material (city atlas: T_deck oak board floor, W_stucco plaster walls, S_white ceiling,
##                                  T_white casings / sills / frames / cornice, T_dark skirting / staff door), AO in the
##                                  vertex colours, tangents for the atlas normal map
##   shop_com_bank_near_closed.glb the kit's original near (kept once: the source of every rebuild, and the reference the
##                                  mid / far LODs were baked from)
##   shop_com_bank_interior.scn    slots, glass, breakable window, hinged doors, lights, col boxes, metas (builtin_lib.gd)
## Mid and far stay the kit's closed shells. Run (headless):
##   godot --headless --path . -s res://tools/city/rooms/builtin/make_bank_interior.gd
const BL := preload("res://tools/city/rooms/builtin/builtin_lib.gd")
const DIR := "res://assets/coronado_kit/buildings/commercial/com_bank/"
const PFX := "shop_com_bank"
const MODEL := "commercial/com_bank"
const GLASS_SH := preload("res://tools/city/rooms/builtin/builtin_glass.gdshader")
const DOOR_GD := preload("res://tools/city/rooms/builtin/builtin_door.gd")
const WIN_GD := preload("res://tools/city/rooms/builtin/builtin_window.gd")
const BLD_MAT := "res://map_dc/coronado/city_kit/materials/bw_city_color_65.tres"
# the room inside the walls (contract: walls 0.30 m, front 0.45 m), floor and ceiling
const X0 := -6.7; const X1 := 6.7; const ZB := -6.7; const ZF := 6.55
const FY := 0.02; const CY := 4.3
const ROW := 1.0           # wall plaster rows (W_stucco strip stretched 2x: one strip a metre)
const FLOOR_ROW := 0.5     # floor boards (T_deck strip stretched 2x: 0.5 m strips of wide oak boards)
const PLASTER := Color(0.95, 0.92, 0.86)
const STONE := Color(1.0, 0.86, 0.70)      # honey oak boards (vertex tint over T_deck)
const BREAK_WIN := ["front", 3.55]      # the pilot's breakable window

var regs := {}
var V: Array = []; var N: Array = []; var UVs: Array = []; var C: Array = []
var tris_int := 0

func _init() -> void: _run.call_deferred()

# ------------------------------------------------------------------ atlas helpers
func _strip(nm: String) -> Vector2:      # v0, v1 of a strip region, half a texel inset
	var uv: Array = regs[nm].uv
	return Vector2(float(uv[1]) + 0.5 / 2048.0, float(uv[3]) - 0.5 / 2048.0)
## tangents from the face axis, not from the uvs: swatch-mapped faces have one uv for every corner, where
## SurfaceTool.generate_tangents() returns degenerate (NaN) tangents - those drew as black screen-space streaks
## through the normal map (the "ceiling stripes"). Every interior face is axis-aligned, so the frame is exact.
func _axis_tangents(arr: Array) -> Array:
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var t := PackedFloat32Array(); t.resize(n.size() * 4)
	for i in n.size():
		var tv := Vector3.RIGHT if absf(n[i].y) > 0.7 else Vector3.UP.cross(n[i]).normalized()
		t[i * 4] = tv.x; t[i * 4 + 1] = tv.y; t[i * 4 + 2] = tv.z; t[i * 4 + 3] = 1.0
	arr[Mesh.ARRAY_TANGENT] = t
	return arr
func _sw(nm: String) -> Vector2: var c: Array = regs[nm].uv_center; return Vector2(float(c[0]), float(c[1]))

## a swatch-mapped face (one uv at every corner) gets a 4-texel spread inside its 24 px swatch: a texture lookup with
## zero uv derivatives is undefined under anisotropic filtering (the kit's albedo sampler) - it drew as black
## screen-space streaks over the ceiling and walls (seen on the box's GL driver; the plain-filtered material was clean)
const SW_SPREAD := 4.0 / 2048.0
const SW_CORNER := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
## a quad p0..p3 counter-clockwise seen from the side n points to; uvs and colours per corner
func quad(p: Array, n: Vector3, uv: Array, col: Array) -> void:
	var one: bool = uv[0] == uv[1] and uv[1] == uv[2] and uv[2] == uv[3]
	for k: int in [0, 3, 2, 0, 2, 1]:      # Godot front faces wind clockwise seen from the front
		var ck: Color = col[k]; ck.a = 0.0      # vertex alpha 0 = indoor (the building shaders skip street grime / tint)
		var u: Vector2 = uv[k] + (SW_CORNER[k] * SW_SPREAD if one else Vector2.ZERO)
		V.append(p[k]); N.append(n); UVs.append(u); C.append(ck)
	tris_int += 2
func tri(p: Array, n: Vector3, uv: Vector2, col: Color) -> void:
	var ck := col; ck.a = 0.0
	for k: int in [0, 2, 1]:
		V.append(p[k]); N.append(n); UVs.append(uv + SW_CORNER[k] * SW_SPREAD); C.append(ck)
	tris_int += 1

func ao_wall(y: float) -> float:
	return lerpf(0.66, 1.0, smoothstep(FY, FY + 0.9, y)) * lerpf(1.0, 0.82, smoothstep(CY - 0.7, CY, y))
func ao_floor(x: float, z: float) -> float:
	var d := minf(minf(x - X0, X1 - x), minf(z - ZB, ZF - z))
	return lerpf(0.72, 1.0, smoothstep(0.0, 0.6, d))

## a plane point: axis "z" = wall at z = at running along x; axis "x" = wall at x = at running along z
func P(axis: String, at: float, s: float, y: float) -> Vector3: return Vector3(s, y, at) if axis == "z" else Vector3(at, y, s)

## a wall face with rectangular holes [s0, s1, y0, y1], facing `inward` (+1/-1 along the axis), plaster rows
func wall(axis: String, at: float, s0: float, s1: float, inward: float, holes: Array) -> void:
	var ys := {FY: true, CY: true}
	var y := FY + ROW
	while y < CY - 0.05: ys[y] = true; y += ROW
	for h: Array in holes: ys[clampf(float(h[2]), FY, CY)] = true; ys[clampf(float(h[3]), FY, CY)] = true
	var ya: Array = ys.keys(); ya.sort()
	var n := Vector3(inward, 0, 0) if axis == "x" else Vector3(0, 0, inward)
	var sv := _strip("W_stucco")
	for j in ya.size() - 1:
		var y0 := float(ya[j]); var y1 := float(ya[j + 1])
		if y1 - y0 < 0.005: continue
		var cy := (y0 + y1) * 0.5
		var iv: Array = [[s0, s1]]
		for h: Array in holes:
			if float(h[2]) < cy and float(h[3]) > cy: iv = _sub(iv, float(h[0]), float(h[1]))
		var r := floorf((cy - FY) / ROW); var fa := (y0 - FY) / ROW - r; var fb := (y1 - FY) / ROW - r
		var va := lerpf(sv.x, sv.y, fa); var vb := lerpf(sv.x, sv.y, fb)
		for it: Array in iv:
			var a := float(it[0]); var b := float(it[1])
			if b - a < 0.005: continue
			# counter-clockwise seen from the room: depends on axis and side
			var A := P(axis, at, a, y0); var B := P(axis, at, b, y0); var Cc := P(axis, at, b, y1); var D := P(axis, at, a, y1)
			var cw := (axis == "z") == (inward > 0.0)
			var ua := a / 8.0; var ub := b / 8.0
			var c0 := PLASTER * ao_wall(y0); var c1 := PLASTER * ao_wall(y1)
			if cw: quad([A, B, Cc, D], n, [Vector2(ua, vb), Vector2(ub, vb), Vector2(ub, va), Vector2(ua, va)], [c0, c0, c1, c1])
			else: quad([B, A, D, Cc], n, [Vector2(ub, vb), Vector2(ua, vb), Vector2(ua, va), Vector2(ub, va)], [c0, c0, c1, c1])

func _sub(iv: Array, a: float, b: float) -> Array:
	var out: Array = []
	for it: Array in iv:
		var s := float(it[0]); var e := float(it[1])
		if b <= s or a >= e: out.append(it); continue
		if a > s: out.append([s, a])
		if b < e: out.append([b, e])
	return out

## a flat rect at height y facing up or down (swatch or strip)
func flat(x0: float, z0: float, x1: float, z1: float, y: float, up: bool, uv: Array, col: Array) -> void:
	var a := Vector3(x0, y, z0); var b := Vector3(x1, y, z0); var c := Vector3(x1, y, z1); var d := Vector3(x0, y, z1)
	# seen from above, a->d->c->b is counter-clockwise (x right, z toward the viewer = down the screen)
	if up: quad([a, d, c, b], Vector3.UP, [uv[0], uv[3], uv[2], uv[1]], [col[0], col[3], col[2], col[1]])
	else: quad([a, b, c, d], Vector3.DOWN, uv, col)

## a vertical rect in plane axis at `at`, s0..s1, y0..y1, facing dir (+1/-1) - one colour, swatch or strip uvs
func vrect(axis: String, at: float, s0: float, s1: float, y0: float, y1: float, dir: float, uv4: Array, col: Color) -> void:
	var n := Vector3(dir, 0, 0) if axis == "x" else Vector3(0, 0, dir)
	var A := P(axis, at, s0, y0); var B := P(axis, at, s1, y0); var Cc := P(axis, at, s1, y1); var D := P(axis, at, s0, y1)
	var cw := (axis == "z") == (dir > 0.0)
	if cw: quad([A, B, Cc, D], n, uv4, [col, col, col, col])
	else: quad([B, A, D, Cc], n, [uv4[1], uv4[0], uv4[3], uv4[2]], [col, col, col, col])

## a horizontal strip between two planes (reveal head / sill / skirting top): y, along s0..s1, across p0..p1
func hrect(axis: String, y: float, s0: float, s1: float, p0: float, p1: float, up: bool, uv: Vector2, col: Color) -> void:
	var a := P(axis, p0, s0, y); var b := P(axis, p0, s1, y); var c := P(axis, p1, s1, y); var d := P(axis, p1, s0, y)
	var xs := [a.x, b.x, c.x, d.x]; var zs := [a.z, b.z, c.z, d.z]
	flat(xs.min(), zs.min(), xs.max(), zs.max(), y, up, [uv, uv, uv, uv], [col, col, col, col])

## a side face (reveal jamb) between two planes at along = s, facing +s or -s
func jamb(axis: String, s: float, p0: float, p1: float, y0: float, y1: float, dir: float, uv: Vector2, col: Color) -> void:
	var other := "x" if axis == "z" else "z"
	vrect(other, s, minf(p0, p1), maxf(p0, p1), y0, y1, dir, [uv, uv, uv, uv], col)

func strip_uv(nm: String, s0: float, s1: float) -> Array:
	var sv := _strip(nm)
	return [Vector2(s0 / 8.0, sv.y), Vector2(s1 / 8.0, sv.y), Vector2(s1 / 8.0, sv.x), Vector2(s0 / 8.0, sv.x)]

# ------------------------------------------------------------------ the run
func _run() -> void:
	regs = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/textures/city_layout.json")).regions
	var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/interiors/room_contracts.json")).models[MODEL]
	# the source: the kit's original near (kept as _closed the first time)
	var src_path := DIR + PFX + "_near_closed.glb"
	if not FileAccess.file_exists(src_path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(DIR + PFX + "_near.glb"), ProjectSettings.globalize_path(src_path))
		print("BANK kept the original near as ", src_path)
	var gdoc := GLTFDocument.new(); var gst := GLTFState.new()
	if gdoc.append_from_file(ProjectSettings.globalize_path(src_path), gst) != OK: push_error("read " + src_path); quit(1); return
	var gscene := gdoc.generate_scene(gst)
	var smi := gscene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var src_mesh: Mesh = smi.mesh
	var src_mat: Material = src_mesh.surface_get_material(0)
	var a := src_mesh.surface_get_arrays(0)
	var ext_tris := (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	# 1. the exterior: the panels of the openings the interior uses taken out (exactly the bake's old cut, now done once)
	var ops: Array = []
	for o: Dictionary in contract.openings:
		if int(o.floor) == 0 and String(o.facade) != "back" and String(o.region) in ["O_civic_door", "O_civic_win"]: ops.append(o)
	var vv: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var tt: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]; var keep := PackedInt32Array(); var dropped := 0
	for k in idx.size() / 3:
		var i0 := idx[k * 3]; var i1 := idx[k * 3 + 1]; var i2 := idx[k * 3 + 2]
		var cu := (tt[i0] + tt[i1] + tt[i2]) / 3.0; cu.x = fposmod(cu.x, 1.0)
		var cp := (vv[i0] + vv[i1] + vv[i2]) / 3.0
		var drop := false
		for o: Dictionary in ops:
			var uv: Array = regs[o.region].uv
			if not (cu.x >= float(uv[0]) and cu.x <= float(uv[2]) and cu.y >= float(uv[1]) and cu.y <= float(uv[3])): continue
			var fr := String(o.facade) == "front" or String(o.facade) == "back"
			var along := cp.x if fr else cp.z; var pl := cp.z if fr else cp.x
			if absf(along - float(o.along)) <= float(o.w) * 0.5 + 0.05 and cp.y >= float(o.y0) - 0.05 and cp.y <= float(o.y1) + 0.05 and absf(pl - float(o.plane)) < 0.3: drop = true; break
		if drop: dropped += 1; continue
		keep.append(i0); keep.append(i1); keep.append(i2)
	print("BANK exterior %d tris, %d panel tris cut over %d openings" % [ext_tris, dropped, ops.size()])
	# 2. the interior shell
	_shell(contract, ops)
	# 3. one surface: exterior arrays (indexed) + interior (appended), tangents for the interior from SurfaceTool
	var ia := []; ia.resize(Mesh.ARRAY_MAX)
	ia[Mesh.ARRAY_VERTEX] = PackedVector3Array(V); ia[Mesh.ARRAY_NORMAL] = PackedVector3Array(N)
	ia[Mesh.ARRAY_TEX_UV] = PackedVector2Array(UVs); ia[Mesh.ARRAY_COLOR] = PackedColorArray(C)
	var st := SurfaceTool.new(); st.create_from_arrays(ia); st.index()
	var ib := _axis_tangents(st.commit_to_arrays())
	var base := vv.size()
	var outv := vv.duplicate(); outv.append_array(ib[Mesh.ARRAY_VERTEX])
	var outn: PackedVector3Array = (a[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate(); outn.append_array(ib[Mesh.ARRAY_NORMAL])
	var outt: PackedFloat32Array = (a[Mesh.ARRAY_TANGENT] as PackedFloat32Array).duplicate(); outt.append_array(ib[Mesh.ARRAY_TANGENT])
	var outuv := tt.duplicate(); outuv.append_array(ib[Mesh.ARRAY_TEX_UV])
	var outc: PackedColorArray = (a[Mesh.ARRAY_COLOR] as PackedColorArray).duplicate(); outc.append_array(ib[Mesh.ARRAY_COLOR])
	var outi := keep.duplicate()
	for q: int in (ib[Mesh.ARRAY_INDEX] as PackedInt32Array): outi.append(base + q)
	var fa := []; fa.resize(Mesh.ARRAY_MAX)
	fa[Mesh.ARRAY_VERTEX] = outv; fa[Mesh.ARRAY_NORMAL] = outn; fa[Mesh.ARRAY_TANGENT] = outt
	fa[Mesh.ARRAY_TEX_UV] = outuv; fa[Mesh.ARRAY_COLOR] = outc; fa[Mesh.ARRAY_INDEX] = outi
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, fa); am.surface_set_material(0, src_mat)
	am.resource_name = src_mesh.resource_name
	var total := outi.size() / 3
	print("BANK interior shell %d tris; near total %d (was %d; budget 2500)" % [tris_int, total, ext_tris])
	# 4. write the near glb with the original names
	var root := Node3D.new(); root.name = gscene.name
	var mi := MeshInstance3D.new(); mi.name = smi.name; mi.mesh = am; mi.transform = smi.transform; root.add_child(mi); mi.owner = root
	var edoc := GLTFDocument.new(); var est := GLTFState.new()
	edoc.image_format = "None"      # (no embedded atlas copies: the kit material is the piece's override; 6 MB -> ~0.3 MB)
	edoc.append_from_scene(root, est)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR + PFX + "_near.glb"))      # (a new file: the old one is hard-linked into other trees)
	var err := edoc.write_to_filesystem(est, ProjectSettings.globalize_path(DIR + PFX + "_near.glb"))
	print("BANK wrote near glb: ", err)
	# 5. the interior scene
	var it := _interior(contract, ops)
	var ps := PackedScene.new(); ps.pack(it)
	print("BANK wrote interior: ", ResourceSaver.save(ps, DIR + PFX + "_interior.scn", ResourceSaver.FLAG_COMPRESS))
	var stats := {"near_tris": total, "exterior_tris": ext_tris, "panel_tris_cut": dropped, "interior_shell_tris": tris_int, "budget_near": 2500,
		"glass_tris": it.get_meta(&"glass_tris"), "openings_cut": ops.size()}
	var f := FileAccess.open(DIR + PFX + "_interior_stats.json", FileAccess.WRITE); f.store_string(JSON.stringify(stats, " ")); f.close()
	print("BANK stats ", stats)
	root.free(); gscene.free(); it.free()
	quit(0)

## facade -> wall: [axis, inner wall plane, inward sign]
func _wall_of(facade: String) -> Array:
	match facade:
		"front": return ["z", ZF, -1.0]
		"back": return ["z", ZB, 1.0]
		"right": return ["x", X1, -1.0]
	return ["x", X0, 1.0]

func _shell(contract: Dictionary, ops: Array) -> void:
	var holes := {"front": [], "back": [], "right": [], "left": []}
	for o: Dictionary in ops:
		var y0 := maxf(float(o.y0), FY)
		(holes[String(o.facade)] as Array).append([float(o.along) - float(o.w) * 0.5, float(o.along) + float(o.w) * 0.5, y0, float(o.y1)])
	# the back's staff door and its two high windows: real holes in the inner wall with the closed door / frosted glass
	var back_extra: Array = []
	for o: Dictionary in contract.openings:
		if String(o.facade) == "back" and int(o.floor) == 0 and String(o.region) in ["O_apt_door", "O_small_white"]:
			(holes.back as Array).append([float(o.along) - float(o.w) * 0.5, float(o.along) + float(o.w) * 0.5, maxf(float(o.y0), FY), float(o.y1)])
			back_extra.append(o)
	# walls
	wall("z", ZF, X0, X1, -1.0, holes.front)
	wall("z", ZB, X0, X1, 1.0, holes.back)
	wall("x", X1, ZB, ZF, -1.0, holes.right)
	wall("x", X0, ZB, ZF, 1.0, holes.left)
	# floor: oak boards in 0.5 m strips across the room, one quad a strip (u wraps along it); the strips by the walls
	# darker (AO), the skirting gives the contact line at the sides
	var fv := _strip("T_deck")
	var zs: Array = [ZB]
	var z := ZB + FLOOR_ROW
	while z < ZF - 0.1: zs.append(z); z += FLOOR_ROW
	zs.append(ZF)
	for j in zs.size() - 1:
		var z0 := float(zs[j]); var z1 := float(zs[j + 1])
		var span := (z1 - z0) / FLOOR_ROW
		var v1 := lerpf(fv.x, fv.y, minf(span, 1.0))
		var uv := [Vector2(X0 / 8.0, fv.x), Vector2(X1 / 8.0, fv.x), Vector2(X1 / 8.0, v1), Vector2(X0 / 8.0, v1)]
		var c0 := STONE * ao_floor(0.0, z0); var c1 := STONE * ao_floor(0.0, z1)
		flat(X0, z0, X1, z1, FY, true, uv, [c0, c0, c1, c1])
	# door thresholds: the floor runs out through the reveals to the door planes
	var sc := _sw("S_concrete")
	for o: Dictionary in ops:
		if String(o.region) != "O_civic_door": continue
		var w: Array = _wall_of(String(o.facade))
		hrect(String(w[0]), FY, float(o.along) - float(o.w) * 0.5, float(o.along) + float(o.w) * 0.5, float(w[1]), float(o.plane), true, sc, STONE * 0.8)
	# ceiling: soffit plaster, AO ring 0.6 m, four light panels
	var so := _sw("S_white"); var CEIL := Color(1.0, 0.99, 0.96)      # plain painted plaster ceiling
	var cxs := [X0, X0 + 0.6, X1 - 0.6, X1]; var czs := [ZB, ZB + 0.6, ZF - 0.6, ZF]
	for j in 3:
		for i in 3:
			var x0 := float(cxs[i]); var x1 := float(cxs[i + 1]); var z0 := float(czs[j]); var z1 := float(czs[j + 1])
			var cc := func(x: float, zz: float) -> Color: return CEIL * lerpf(0.78, 1.0, smoothstep(0.0, 0.6, minf(minf(x - X0, X1 - x), minf(zz - ZB, ZF - zz))))
			flat(x0, z0, x1, z1, CY, false, [so, so, so, so], [cc.call(x0, z0), cc.call(x1, z0), cc.call(x1, z1), cc.call(x0, z1)])
	var sw := _sw("S_white")
	for lp: Vector2 in LIGHTS:
		flat(lp.x - 0.6, lp.y - 0.3, lp.x + 0.6, lp.y + 0.3, CY - 0.012, false, [sw, sw, sw, sw], [Color(1, 1, 0.97), Color(1, 1, 0.97), Color(1, 1, 0.97), Color(1, 1, 0.97)])
	# skirting (T_dark wood, 0.12 m, 1.5 cm proud) and cornice (T_white, 0.14 m, 3 cm proud) on every wall run
	for fac: String in ["front", "back", "right", "left"]:
		var w2: Array = _wall_of(fac); var ax := String(w2[0]); var at := float(w2[1]); var inw := float(w2[2])
		var s_a := X0 if ax == "z" else ZB; var s_b := X1 if ax == "z" else ZF
		var iv: Array = [[s_a, s_b]]
		for h: Array in holes[fac]:
			if float(h[2]) <= FY + 0.01: iv = _sub(iv, float(h[0]), float(h[1]))
		for seg: Array in iv:
			var p := at + inw * 0.015
			vrect(ax, p, float(seg[0]), float(seg[1]), FY, FY + 0.12, inw, strip_uv("T_dark", float(seg[0]), float(seg[1])), Color(0.85, 0.8, 0.75))
			hrect(ax, FY + 0.12, float(seg[0]), float(seg[1]), at, p, true, _sw("S_dark"), Color(0.8, 0.75, 0.7))
		var pc := at + inw * 0.03
		vrect(ax, pc, s_a, s_b, CY - 0.14, CY - 0.002, inw, strip_uv("T_white", s_a, s_b), Color(0.97, 0.95, 0.9))
		hrect(ax, CY - 0.14, s_a, s_b, at, pc, false, _sw("S_white"), Color(0.85, 0.83, 0.8))
	# openings: reveals to the opening plane, casings, sills, frames at the glass
	var tw := _sw("S_white"); var trim := Color(0.96, 0.94, 0.89)
	for o: Dictionary in ops:
		var w3: Array = _wall_of(String(o.facade)); var ax := String(w3[0]); var at := float(w3[1]); var inw := float(w3[2])
		var pl := float(o.plane); var s0 := float(o.along) - float(o.w) * 0.5; var s1 := float(o.along) + float(o.w) * 0.5
		var y0 := maxf(float(o.y0), FY); var y1 := float(o.y1)
		var door := String(o.region) == "O_civic_door"
		var rv := _sw("S_stucco"); var rc := PLASTER * 0.88
		# jambs face into the opening (+s at s0, -s at s1), head faces down, sill faces up
		jamb(ax, s0, at, pl, y0, y1, 1.0, rv, rc); jamb(ax, s1, at, pl, y0, y1, -1.0, rv, rc)
		hrect(ax, y1, s0, s1, at, pl, false, rv, rc * 0.85)
		var cw := 0.08; var cp := at + inw * 0.008
		if door:
			vrect(ax, cp, s0 - cw, s0, y0, y1 + cw, inw, strip_uv("T_white", s0 - cw, s0), trim)
			vrect(ax, cp, s1, s1 + cw, y0, y1 + cw, inw, strip_uv("T_white", s1, s1 + cw), trim)
			vrect(ax, cp, s0, s1, y1, y1 + cw, inw, strip_uv("T_white", s0, s1), trim)
			# transom bar at the leaf head (2.2 m), both sides, dark painted wood like the leaves
			var lh := float(regs[o.region].get("door_leaf_m", 2.2))
			_bar(ax, pl, s0, s1, lh - 0.04, lh + 0.04, inw, Color(0.7, 0.62, 0.55))
		else:
			hrect(ax, y0, s0, s1, at, pl, true, tw, trim)      # the reveal's bottom is a painted sill board
			var sp := at + inw * 0.04      # sill nose 4 cm into the room
			hrect(ax, y0 + 0.035, s0 - 0.06, s1 + 0.06, at, sp, true, tw, trim)
			vrect(ax, sp, s0 - 0.06, s1 + 0.06, y0 - 0.02, y0 + 0.035, inw, strip_uv("T_white", s0 - 0.06, s1 + 0.06), trim * 0.92)
			vrect(ax, cp, s0 - cw, s0, y0 + 0.035, y1 + cw, inw, strip_uv("T_white", s0 - cw, s0), trim)
			vrect(ax, cp, s1, s1 + cw, y0 + 0.035, y1 + cw, inw, strip_uv("T_white", s1, s1 + cw), trim)
			vrect(ax, cp, s0, s1, y1, y1 + cw, inw, strip_uv("T_white", s0, s1), trim)
			# frame at the glass: perimeter, a centre mullion and a transom (painted metal, seen from both sides)
			var fw := 0.06; var ty := y0 + (y1 - y0) * 0.72
			_bar(ax, pl, s0, s0 + fw, y0, y1, inw, trim); _bar(ax, pl, s1 - fw, s1, y0, y1, inw, trim)
			_bar(ax, pl, s0, s1, y1 - fw, y1, inw, trim)      # (no bottom bar: the sill board and the exterior sill frame it)
			var mc := float(o.along)
			_bar(ax, pl, mc - 0.025, mc + 0.025, y0, ty, inw, trim)
			_bar(ax, pl, s0, s1, ty - 0.025, ty + 0.025, inw, trim)
	# the back: closed staff door (T_dark leaf) and two frosted high windows, each in its reveal
	for o: Dictionary in back_extra:
		var pl2 := float(o.plane) + 0.012; var s0b := float(o.along) - float(o.w) * 0.5; var s1b := float(o.along) + float(o.w) * 0.5
		var y0b := maxf(float(o.y0), FY); var y1b := float(o.y1)
		var rv2 := _sw("S_stucco"); var rc2 := PLASTER * 0.88
		jamb("z", s0b, ZB, pl2, y0b, y1b, 1.0, rv2, rc2); jamb("z", s1b, ZB, pl2, y0b, y1b, -1.0, rv2, rc2)
		hrect("z", y1b, s0b, s1b, ZB, pl2, false, rv2, rc2 * 0.85)
		if String(o.region) == "O_apt_door":
			vrect("z", pl2, s0b, s1b, y0b, y1b, 1.0, strip_uv("T_dark", s0b, s1b), Color(0.9, 0.82, 0.74))
			vrect("z", ZB + 0.008, s0b - 0.08, s0b, y0b, y1b + 0.08, 1.0, strip_uv("T_white", s0b - 0.08, s0b), trim)
			vrect("z", ZB + 0.008, s1b, s1b + 0.08, y0b, y1b + 0.08, 1.0, strip_uv("T_white", s1b, s1b + 0.08), trim)
			vrect("z", ZB + 0.008, s0b, s1b, y1b, y1b + 0.08, 1.0, strip_uv("T_white", s0b, s1b), trim)
		else:
			hrect("z", y0b, s0b, s1b, ZB, pl2, true, tw, trim)
			vrect("z", pl2, s0b, s1b, y0b, y1b, 1.0, [_sw("S_white"), _sw("S_white"), _sw("S_white"), _sw("S_white")], Color(0.9, 0.96, 1.0))      # frosted glass: bright, opaque
	print("BANK shell parts done")

## a frame bar at the glass plane: one quad each side (just outside and just inside the pane)
func _bar(ax: String, pl: float, s0: float, s1: float, y0: float, y1: float, inw: float, col: Color) -> void:
	var t := strip_uv("T_white", s0, s1)
	vrect(ax, pl - inw * 0.012, s0, s1, y0, y1, -inw, t, col)      # street side
	vrect(ax, pl + inw * 0.025, s0, s1, y0, y1, inw, t, col)       # room side

# ------------------------------------------------------------------ the interior scene
const LIGHTS := [Vector2(-3.0, 3.2), Vector2(3.0, 3.2), Vector2(-3.0, -4.4), Vector2(3.0, -4.4)]

## hand-placed slots: [name, slot_type, variant, x, z, yaw (deg, kit front +Z), lift]
## The hall: door on the front axis, 1.5 m clear inside it; the teller line across the room at z = -2.0 (four bullet-
## proof windows, a counter run each side and the business window on the left, a 0.9 m staff passage at each wall),
## the queue lane on the axis between stanchions, two loan officers' desks on the left wall between the windows (the
## officer by the wall facing the room, a customer chair across), waiting benches on the right wall under the sills,
## brochures and the coin counter by the door; behind the line the tellers' chairs, files and the safe on the back
## wall, a back-office desk in the right corner, the copier as the right-hand end of the line.
const SLOTS := [
	["till_1", "till", 0, -1.83, -2.0, 0.0, 0.0], ["till_2", "till", 0, -0.61, -2.0, 0.0, 0.0],
	["till_3", "till", 0, 0.61, -2.0, 0.0, 0.0], ["till_4", "till", 0, 1.83, -2.0, 0.0, 0.0],
	["counter_l", "counter", 0, -3.35, -2.0, 0.0, 0.0], ["counter_r", "counter", 0, 3.35, -2.0, 0.0, 0.0],
	["counter_business", "counter", 1, -5.01, -2.0, 0.0, 0.0], ["counter_copier", "counter", 2, 5.06, -2.1, 180.0, 0.0],
	["staff_1", "staff", 0, -1.83, -3.0, 0.0, 0.0], ["staff_2", "staff", 0, -0.61, -3.0, 0.0, 0.0],
	["staff_3", "staff", 0, 0.61, -3.0, 0.0, 0.0], ["staff_4", "staff", 0, 1.83, -3.0, 0.0, 0.0],
	["queue_1", "queue", 0, -0.95, 0.15, 0.0, 0.0], ["queue_2", "queue", 0, 0.95, 0.15, 0.0, 0.0],
	["queue_3", "queue", 0, -0.95, 1.05, 0.0, 0.0], ["queue_4", "queue", 0, 0.95, 1.05, 0.0, 0.0],
	["desk_1", "desk", 0, -5.55, 0.85, -90.0, 0.0], ["desk_2", "desk", 0, -5.55, 2.95, -90.0, 0.0],
	["officer_1", "seat", 2, -6.25, 0.85, 90.0, 0.0], ["officer_2", "seat", 2, -6.25, 2.95, 90.0, 0.0],
	["customer_1", "seat", 1, -4.55, 0.85, -90.0, 0.0], ["customer_2", "seat", 1, -4.55, 2.95, -90.0, 0.0],
	["bench_1", "seat", 0, 6.4, 0.6, -90.0, 0.0], ["bench_2", "seat", 0, 6.4, 2.45, -90.0, 0.0],
	["brochures", "shelf", 0, 1.8, 6.32, 180.0, 0.0], ["coin_counter", "shelf", 2, -1.85, 6.26, 180.0, 0.0],
	["files_1", "shelf", 1, 1.4, -6.36, 0.0, 0.0], ["files_2", "shelf", 1, 1.9, -6.36, 0.0, 0.0], ["files_3", "shelf", 1, 2.4, -6.36, 0.0, 0.0],
	["safe", "safe", 0, 0.3, -6.64, 0.0, 0.0],
	["office_desk", "desk", 0, 4.6, -5.2, 180.0, 0.0], ["office_chair", "seat", 2, 4.6, -6.0, 0.0, 0.0],
	["art_1", "decor", 0, -6.66, 0.85, 90.0, 1.55], ["art_2", "decor", 0, -6.66, 2.95, 90.0, 1.55],
	["notices", "decor", 1, 6.66, 1.52, -90.0, 1.0], ["mirror", "decor", 2, -6.62, 5.9, 90.0, 0.0],
	["bin_hall", "bin", 0, 6.45, 1.52, -90.0, 0.0], ["bin_desks", "bin", 0, -6.45, 1.9, 90.0, 0.0],
]

func _interior(contract: Dictionary, ops: Array) -> Node3D:
	var it := Node3D.new(); it.name = PFX + "_interior"
	var sl := Node3D.new(); sl.name = "Slots"; it.add_child(sl)
	for s: Array in SLOTS:
		var m := Marker3D.new(); m.name = String(s[0])
		m.position = Vector3(float(s[3]), FY, float(s[4])); m.rotation.y = deg_to_rad(float(s[5]))
		m.set_meta(&"slot_type", String(s[1])); m.set_meta(&"variant", int(s[2])); m.set_meta(&"lift", float(s[6]))
		m.gizmo_extents = 0.3
		sl.add_child(m)
	# glass: one mesh for every pane but the breakable one (one draw); UV 0..1 per pane
	var gm := ShaderMaterial.new(); gm.shader = GLASS_SH
	gm.set_shader_parameter(&"far_begin", 24.0); gm.set_shader_parameter(&"far_end", BL.PROP_END)
	ResourceSaver.save(gm, DIR + PFX + "_glass.tres")
	gm = load(DIR + PFX + "_glass.tres")
	var gv: Array = []; var gn: Array = []; var gu: Array = []
	var panes: Array = []; var cuts: Array = []
	var win_node: Node3D = null
	for o: Dictionary in ops:
		var w: Array = _wall_of(String(o.facade)); var ax := String(w[0]); var inw := float(w[2])
		var door := String(o.region) == "O_civic_door"
		cuts.append([String(o.facade), float(o.along), "door" if door else "window"])
		var s0 := float(o.along) - float(o.w) * 0.5; var s1 := float(o.along) + float(o.w) * 0.5
		var y0 := maxf(float(o.y0), FY); var y1 := float(o.y1)
		if door: y0 = float(regs[o.region].get("door_leaf_m", 2.2)) + 0.04      # the transom light over the leaves
		var pl := float(o.plane)
		var is_break := String(o.facade) == String(BREAK_WIN[0]) and absf(float(o.along) - float(BREAK_WIN[1])) < 0.05
		panes.append([String(o.facade), float(o.along)])
		if is_break:
			win_node = _break_window(o, ax, pl, s0, s1, y0, y1, inw, gm); continue
		var n := Vector3(0, 0, -inw) if ax == "z" else Vector3(-inw, 0, 0)      # glass normal: out to the street
		var A := P(ax, pl, s0, y0); var B := P(ax, pl, s1, y0); var Cc := P(ax, pl, s1, y1); var D := P(ax, pl, s0, y1)
		for q: Array in [[A, Vector2(0, 1)], [Cc, Vector2(1, 0)], [B, Vector2(1, 1)], [A, Vector2(0, 1)], [D, Vector2(0, 0)], [Cc, Vector2(1, 0)]]:
			gv.append(q[0]); gn.append(n); gu.append(q[1])
	var ga := []; ga.resize(Mesh.ARRAY_MAX)
	ga[Mesh.ARRAY_VERTEX] = PackedVector3Array(gv); ga[Mesh.ARRAY_NORMAL] = PackedVector3Array(gn); ga[Mesh.ARRAY_TEX_UV] = PackedVector2Array(gu)
	var gam := ArrayMesh.new(); gam.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ga); gam.surface_set_material(0, gm)
	var gmi := MeshInstance3D.new(); gmi.name = "Glass"; gmi.mesh = gam; gmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	it.add_child(gmi)
	it.set_meta(&"glass_tris", gv.size() / 3)
	var wn := Node3D.new(); wn.name = "Windows"; it.add_child(wn)
	if win_node: wn.add_child(win_node)
	# doors: the front pair, hinged at the jambs
	var dn := Node3D.new(); dn.name = "Doors"; it.add_child(dn)
	for o: Dictionary in ops:
		if String(o.region) != "O_civic_door": continue
		_door_pair(dn, o, gm)
	# lights: one per ceiling panel (CityRooms keeps the nearest rooms' lights within its 12)
	var ln := Node3D.new(); ln.name = "Lights"; it.add_child(ln)
	for lp: Vector2 in LIGHTS:
		var l := OmniLight3D.new(); l.position = Vector3(lp.x, CY - 0.25, lp.y)
		l.light_color = Color(1.0, 0.9, 0.78); l.light_energy = 1.3; l.omni_range = 6.5; l.omni_attenuation = 1.2
		l.shadow_enabled = false; l.distance_fade_enabled = true; l.distance_fade_begin = BL.PROP_END; l.distance_fade_length = 10.0
		ln.add_child(l)
	# collision: the walls as boxes, open at the shop door (7 boxes; the kit's gap hulls - steps, hood posts - stay)
	var col := StaticBody3D.new(); col.name = "col"; it.add_child(col)
	var H := 6.07
	var boxes := [["front_l", Vector3(-3.95, H * 0.5, 6.775), Vector3(6.1, H, 0.45)], ["front_r", Vector3(3.95, H * 0.5, 6.775), Vector3(6.1, H, 0.45)],
		["front_head", Vector3(0, (2.8 + H) * 0.5, 6.775), Vector3(1.8, H - 2.8, 0.45)], ["back", Vector3(0, H * 0.5, -6.85), Vector3(14.0, H, 0.3)],
		["left", Vector3(-6.85, H * 0.5, 0.0), Vector3(0.3, H, 14.0)], ["right", Vector3(6.85, H * 0.5, 0.0), Vector3(0.3, H, 14.0)],
		["roof", Vector3(0, (CY + H) * 0.5, 0.0), Vector3(14.0, H - CY, 14.0)]]
	for b: Array in boxes:
		var cs := CollisionShape3D.new(); cs.name = String(b[0]); var bs := BoxShape3D.new(); bs.size = b[2]; cs.shape = bs; cs.position = b[1]; col.add_child(cs)
	it.set_meta(&"builtin_interior", true); it.set_meta(&"model", MODEL); it.set_meta(&"kinds", ["bank"])
	it.set_meta(&"cuts", cuts); it.set_meta(&"panes", panes)
	it.set_meta(&"floors", [[X0, ZB, X1, ZF]])
	it.set_meta(&"entrances", [["z", 6.7, -0.9, 0.9]])
	it.set_meta(&"ceiling", CY)
	_own(it, it)
	return it

func _own(n: Node, o: Node) -> void:
	for c in n.get_children():
		c.owner = o; _own(c, o)

## the breakable window: node at the pane's street-side bottom-left (+X along the pane as seen from the street, +Y up)
func _break_window(o: Dictionary, ax: String, pl: float, s0: float, s1: float, y0: float, y1: float, inw: float, gm: Material) -> Node3D:
	var w := s1 - s0; var h := y1 - y0
	var nd := Node3D.new(); nd.name = "Window_%s_%d" % [String(o.facade), int(round(float(o.along) * 100.0))]
	nd.set_script(WIN_GD)
	# street side looks along -inw: for the front (inw -1) the street sees +x to the right
	var right := Vector3(1, 0, 0) if ax == "z" else Vector3(0, 0, 1)
	if inw > 0.0: right = -right
	var origin := P(ax, pl, s0 if right.x + right.z > 0.0 else s1, y0)
	var outn := Vector3(0, 0, -inw) if ax == "z" else Vector3(-inw, 0, 0)
	nd.transform = Transform3D(Basis(right, Vector3.UP, outn), origin)
	nd.set_meta(&"size", Vector2(w, h)); nd.set_meta(&"facade", String(o.facade)); nd.set_meta(&"along", float(o.along))
	# pane
	var pm := ArrayMesh.new(); var pa := []; pa.resize(Mesh.ARRAY_MAX)
	pa[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0, 0, 0), Vector3(w, h, 0), Vector3(w, 0, 0), Vector3(0, 0, 0), Vector3(0, h, 0), Vector3(w, h, 0)])
	pa[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	pa[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(0, 0), Vector2(1, 0)])
	pm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, pa); pm.surface_set_material(0, gm)
	var pmi := MeshInstance3D.new(); pmi.name = "pane"; pmi.mesh = pm; pmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; nd.add_child(pmi)
	# remnant: jagged teeth of glass left in the frame (hidden until broken)
	var rv := PackedVector3Array(); var rng := RandomNumberGenerator.new(); rng.seed = 7
	var edge := func(p0: Vector3, p1: Vector3, inn: Vector3, n_t: int) -> void:
		for k in n_t:
			var t0 := float(k) / n_t; var t1 := float(k + 1) / n_t; var tm := lerpf(t0, t1, rng.randf_range(0.3, 0.7))
			var a := p0.lerp(p1, t0); var b := p0.lerp(p1, t1); var c := p0.lerp(p1, tm) + inn * rng.randf_range(0.04, 0.22)
			rv.append(a); rv.append(c); rv.append(b)
	edge.call(Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3.UP, 7); edge.call(Vector3(w, h, 0), Vector3(0, h, 0), Vector3.DOWN, 7)
	edge.call(Vector3(0, h, 0), Vector3(0, 0, 0), Vector3.RIGHT, 12); edge.call(Vector3(w, 0, 0), Vector3(w, h, 0), Vector3.LEFT, 12)
	var ruv := PackedVector2Array(); var rn := PackedVector3Array()
	for p: Vector3 in rv: ruv.append(Vector2(p.x / w, 1.0 - p.y / h)); rn.append(Vector3.BACK)
	var ra := []; ra.resize(Mesh.ARRAY_MAX); ra[Mesh.ARRAY_VERTEX] = rv; ra[Mesh.ARRAY_NORMAL] = rn; ra[Mesh.ARRAY_TEX_UV] = ruv
	var rm := ArrayMesh.new(); rm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ra)
	var rmat := ShaderMaterial.new(); rmat.shader = GLASS_SH; rmat.set_shader_parameter(&"clear_alpha", 0.45); rmat.set_shader_parameter(&"far_end", BL.PROP_END)
	rm.surface_set_material(0, rmat)
	var rmi := MeshInstance3D.new(); rmi.name = "remnant"; rmi.mesh = rm; rmi.visible = false; rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; nd.add_child(rmi)
	# shards: one-shot CPU burst, 24 small glass quads
	var sh := CPUParticles3D.new(); sh.name = "shards"; sh.emitting = false; sh.one_shot = true; sh.amount = 24; sh.lifetime = 0.9
	sh.explosiveness = 0.95; sh.direction = Vector3(0, 0.3, 1); sh.spread = 55.0; sh.initial_velocity_min = 1.2; sh.initial_velocity_max = 3.2
	sh.gravity = Vector3(0, -9.8, 0); sh.angular_velocity_min = -400.0; sh.angular_velocity_max = 400.0
	sh.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; sh.emission_box_extents = Vector3(w * 0.35, h * 0.3, 0.01)
	sh.scale_amount_min = 0.5; sh.scale_amount_max = 1.4
	var qm := QuadMesh.new(); qm.size = Vector2(0.11, 0.08)
	var smat := StandardMaterial3D.new(); smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; smat.albedo_color = Color(0.82, 0.9, 0.93); smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	qm.material = smat; sh.mesh = qm; sh.local_coords = false; sh.visibility_aabb = AABB(Vector3(-3, -4, -3), Vector3(6, 6, 6))
	nd.add_child(sh)
	# body: blocks the opening while there is glass in it
	var body := StaticBody3D.new(); body.name = "body"; var bcs := CollisionShape3D.new(); bcs.name = "shape"
	var bb := BoxShape3D.new(); bb.size = Vector3(w, h, 0.06); bcs.shape = bb; bcs.position = Vector3(w * 0.5, h * 0.5, 0); body.add_child(bcs); nd.add_child(body)
	return nd

## the shop door: two leaves hinged at the jambs (DoorLeaf_<s0 cm>_<i>, room_lib's names and metas: CityRooms drives them)
func _door_pair(dn: Node3D, o: Dictionary, gm: Material) -> void:
	var w: Array = _wall_of(String(o.facade)); var ax := String(w[0]); var inw := float(w[2])
	var out := -inw      # out of the room
	var s0 := float(o.along) - float(o.w) * 0.5; var s1 := float(o.along) + float(o.w) * 0.5
	var lh := float(regs[o.region].get("door_leaf_m", 2.2)) - 0.005
	var y0 := FY; var h := lh - y0
	var lw := (s1 - s0) * 0.5
	var plane := float(o.plane) - out * 0.05
	var bmat: Material = load(BLD_MAT)
	for i in 2:
		var hinge := s0 if i == 0 else s1
		var dir := 1.0 if i == 0 else -1.0
		var node := Node3D.new(); node.name = "DoorLeaf_%d_%d" % [int(s0 * 100), i]
		node.position = P(ax, plane, hinge, y0)
		node.set_script(DOOR_GD)
		node.set_meta(&"hinge_axis", ax); node.set_meta(&"swing", dir); node.set_meta(&"facade", String(o.facade))
		node.set_meta(&"span", Vector2(minf(hinge, hinge + dir * lw), maxf(hinge, hinge + dir * lw)))
		node.set_meta(&"mid", Vector3(lw * 0.5 * dir, h * 0.5, 0) if ax == "z" else Vector3(0, h * 0.5, lw * 0.5 * dir))
		var sgn := -dir * out
		if ax == "x": sgn = dir * out
		node.set_meta(&"open_sign", sgn)
		node.set_meta(&"out_dir", Vector3(0, 0, out) if ax == "z" else Vector3(out, 0, 0))
		var leaf := MeshInstance3D.new(); leaf.name = "leaf"; leaf.mesh = _leaf_mesh(lw, h, dir, ax, false, bmat, gm); node.add_child(leaf)
		var lb := MeshInstance3D.new(); lb.name = "leaf_broken"; lb.mesh = _leaf_mesh(lw, h, dir, ax, true, bmat, gm); lb.visible = false
		# off its top hinge: hanging from the bottom one, swung 70 degrees in and sagged 9 degrees toward the floor
		var bas := Basis(Vector3.UP, deg_to_rad(70.0) * -sgn)      # into the room
		var tilt_axis := Vector3(0, 0, 1) if ax == "z" else Vector3(1, 0, 0)
		lb.transform = Transform3D(bas * Basis(tilt_axis, deg_to_rad(-9.0 * dir)), Vector3(0, 0.075, 0))
		node.add_child(lb)
		var body := AnimatableBody3D.new(); body.name = "body"; body.sync_to_physics = false
		var cs := CollisionShape3D.new(); cs.name = "shape"; var bs := BoxShape3D.new()
		bs.size = Vector3(lw - 0.02, h, 0.06) if ax == "z" else Vector3(0.06, h, lw - 0.02)
		cs.shape = bs; cs.position = node.get_meta(&"mid"); body.add_child(cs); node.add_child(body)
		dn.add_child(node)

## a civic leaf: painted wood stiles and rails (city atlas T_dark), a raised lower panel, glass in the upper two thirds,
## a brass push plate. broken: the glass gone, the top rail split, splinters
func _leaf_mesh(lw: float, h: float, dir: float, ax: String, broken: bool, bmat: Material, gm: Material) -> ArrayMesh:
	var wood: Array = [[], [], [], []]; var glass: Array = [[], [], []]
	var dv := _strip("T_dark"); var brass := _sw("S_terracotta")
	var box := func(c: Vector3, sz: Vector3, colr: Color, uvc: Variant) -> void:
		var cc := Vector3(c.x * dir, c.y, c.z); var s2 := sz
		if ax == "x": cc = Vector3(c.z, c.y, c.x * dir); s2 = Vector3(sz.z, sz.y, sz.x)
		var hh := s2 * 0.5
		var x0 := cc.x - hh.x; var x1 := cc.x + hh.x; var y0 := cc.y - hh.y; var y1 := cc.y + hh.y; var z0 := cc.z - hh.z; var z1 := cc.z + hh.z
		var faces := [[Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x1, y0, z1), Vector3.RIGHT],
			[Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3.LEFT],
			[Vector3(x0, y1, z0), Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3.UP],
			[Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3.DOWN],
			[Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK],
			[Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y0, z0), Vector3.FORWARD]]
		for f: Array in faces:
			for k: int in [0, 2, 1, 0, 3, 2]:      # (room_lib's face lists run counter-clockwise from outside: reversed)
				var pv: Vector3 = f[k]
				(wood[0] as Array).append(pv); (wood[1] as Array).append(f[4])
				var uv: Vector2 = (uvc as Vector2) + SW_CORNER[k] * SW_SPREAD if uvc is Vector2 else Vector2((pv.x + pv.z) / 8.0, lerpf(dv.x, dv.y, clampf(pv.y / h, 0.0, 1.0)))
				(wood[2] as Array).append(uv); (wood[3] as Array).append(colr)
	var WOOD := Color(0.95, 0.85, 0.75)
	for side: float in [0.055, lw - 0.055]: box.call(Vector3(side, h * 0.5, 0), Vector3(0.11, h, 0.05), WOOD, null)
	if not broken: box.call(Vector3(lw * 0.5, h - 0.07, 0), Vector3(lw - 0.22, 0.14, 0.05), WOOD, null)
	else:
		box.call(Vector3(lw * 0.3, h - 0.07, 0), Vector3(lw * 0.36, 0.14, 0.05), WOOD, null)
		box.call(Vector3(lw * 0.62, h - 0.11, 0.01), Vector3(0.14, 0.05, 0.03), WOOD * 0.8, null)      # splinters
		box.call(Vector3(lw * 0.55, h * 0.62, 0.0), Vector3(0.04, 0.32, 0.02), WOOD * 0.8, null)
	box.call(Vector3(lw * 0.5, h * 0.42, 0), Vector3(lw - 0.22, 0.12, 0.05), WOOD, null)
	box.call(Vector3(lw * 0.5, 0.11, 0), Vector3(lw - 0.22, 0.22, 0.05), WOOD, null)
	box.call(Vector3(lw * 0.5, h * 0.24, 0), Vector3(lw - 0.3, h * 0.30, 0.035), WOOD * 0.92, null)      # raised panel
	if not broken: box.call(Vector3(lw - 0.2, h * 0.47, 0.03), Vector3(0.08, 0.3, 0.012), Color(1.4, 1.15, 0.6), brass)      # push plate
	var am := ArrayMesh.new()
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = PackedVector3Array(wood[0]); arr[Mesh.ARRAY_NORMAL] = PackedVector3Array(wood[1])
	arr[Mesh.ARRAY_TEX_UV] = PackedVector2Array(wood[2]); arr[Mesh.ARRAY_COLOR] = PackedColorArray(wood[3])
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _axis_tangents(arr)); am.surface_set_material(0, bmat)
	if not broken:
		var gy0 := h * 0.48; var gy1 := h - 0.14; var gx0 := 0.11; var gx1 := lw - 0.11
		var q := [Vector3(gx0, gy0, 0), Vector3(gx1, gy1, 0), Vector3(gx1, gy0, 0), Vector3(gx0, gy0, 0), Vector3(gx0, gy1, 0), Vector3(gx1, gy1, 0)]
		var quv := [Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(0, 0), Vector2(1, 0)]
		for k in 6:
			var pv: Vector3 = q[k]; var cc := Vector3(pv.x * dir, pv.y, pv.z)
			if ax == "x": cc = Vector3(pv.z, pv.y, pv.x * dir)
			(glass[0] as Array).append(cc); (glass[1] as Array).append(Vector3.BACK if ax == "z" else Vector3.RIGHT); (glass[2] as Array).append(quv[k])
		var ga := []; ga.resize(Mesh.ARRAY_MAX)
		ga[Mesh.ARRAY_VERTEX] = PackedVector3Array(glass[0]); ga[Mesh.ARRAY_NORMAL] = PackedVector3Array(glass[1]); ga[Mesh.ARRAY_TEX_UV] = PackedVector2Array(glass[2])
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ga); am.surface_set_material(1, gm)
	return am
