extends SceneTree
## Built-in interiors, the rollout builder (Yasin 22 Nov 2026: "roll out built-in interiors to all indoor places").
## Generic over the room contracts: for every model and bay in interiors/builtin/bays.json it writes
## <model prefix>_bay<i>.scn beside the kit's near glb (the near glb itself is NOT changed: the bake composes the near per
## building from the kit's closed near + the shells of the bays that building uses, so a bay nobody uses stays closed):
##   Shell (the bay's interior shell mesh: floor, ceiling + light panels, walls with the openings' reveals, casings,
##   sills and frames, skirting, cornice, the back's closed doors / frosted windows; vertex alpha 0 = indoor, the city
##   atlas, one surface - appended into the building's near at bake), Glass (one draw), Windows (one breakable),
##   Doors (hinged DoorLeaf nodes, interact / damage / break), Lights (<= 4, no shadows), col (the bay's inner walls as
##   boxes; the kit's concave shell stays, opened at the doors), Slots/<kind>/<A|B|C> (interiors/builtin/layouts.json).
## Metas as the pilot's _interior.scn (floors, entrances, cuts, panes, ceiling) + ops (the openings the bake cuts).
##   godot --headless --path . -s res://tools/city/rooms/builtin/make_interiors.gd -- [--models=a,b] [--only-new]
const BL := preload("res://tools/city/rooms/builtin/builtin_lib.gd")
const GLASS_SH := preload("res://tools/city/rooms/builtin/builtin_glass.gdshader")
const DOOR_GD := preload("res://tools/city/rooms/builtin/builtin_door.gd")
const WIN_GD := preload("res://tools/city/rooms/builtin/builtin_window.gd")
const BLD_MAT := "res://map_dc/coronado/city_kit/materials/bw_city_color_65.tres"
const IB := "res://map_dc/coronado/city_kit/interiors/builtin/"
const GLASS_MAT := IB + "builtin_glass.tres"
const OPEN := ["O_shopdoor", "O_civic_door", "O_storefront", "O_win_", "O_glass_plain", "O_civic_win", "O_small_"]
const DOORS := ["O_shopdoor", "O_civic_door"]
var FY := 0.02
var ROW := 1.0
var FLOOR_ROW := 0.5
var LEAN2 := false      ## still over: one ceiling quad, no skirting, no casings, frame bars on the street side only
var LEAN3 := false   # bays.json front_only: the side facades' windows stay closed (their doors still open); budget trim
var LEAN := false      ## over the model's near budget: 1.5 m floor strips, one plaster row, no cornice, frames without mullion / transom
const PLASTER := Color(0.95, 0.92, 0.86)
const STONE := Color(1.0, 0.86, 0.70)
var X0 := 0.0; var X1 := 0.0; var ZB := 0.0; var ZF := 0.0; var CY := 4.3
var LIGHTS: Array = []
var regs := {}
var V: Array = []; var N: Array = []; var UVs: Array = []; var C: Array = []
var tris_int := 0
var stats := {}

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


func _is(o: Dictionary, pfx: Array) -> bool:
	# (22 Nov) a bay whose way in is an apt door (kiosk, small shops, dorm lobbies): that one door counts as a shop door
	if bool(o.get("entry", false)) and (pfx == DOORS or pfx == OPEN): return true
	return pfx.any(func(p: String) -> bool: return String(o.region).begins_with(p))

func _run() -> void:
	regs = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/textures/city_layout.json")).regions
	var contracts: Dictionary = BL.all_contracts()
	var bays: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(IB + "bays.json")).models
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(IB + "layouts.json")).layouts
	var only: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--models="): only = a.trim_prefix("--models=").split(",")
	if not ResourceLoader.exists(GLASS_MAT):
		var gm0 := ShaderMaterial.new(); gm0.shader = GLASS_SH
		gm0.set_shader_parameter(&"far_begin", 24.0); gm0.set_shader_parameter(&"far_end", BL.PROP_END)
		ResourceSaver.save(gm0, GLASS_MAT)
	var gm: Material = load(GLASS_MAT)
	var n_ok := 0
	for model: String in bays:
		if not only.is_empty() and not only.has(model): continue
		var pfx := BL.prefix_of(model)
		if pfx == "" or not contracts.has(model): push_error("no kit dir / contract for " + model); continue
		var c: Dictionary = contracts[model]
		var f0: Dictionary = c.floors[0]
		LEAN = bool(bays[model].get("lean", false)); LEAN2 = bool(bays[model].get("lean2", false)); LEAN3 = bool(bays[model].get("front_only", false))
		ROW = 8.0 if LEAN else 1.0; FLOOR_ROW = 3.0 if LEAN2 else 1.5 if LEAN else 0.5
		for b: Dictionary in bays[model].bays:
			V = []; N = []; UVs = []; C = []; tris_int = 0
			X0 = float(b.s0); X1 = float(b.s1); ZB = float(f0.box_min[2]); ZF = float(f0.box_max[2]); FY = float(f0.get("y", 0.0)) + 0.02
			var ops: Array = []; var back_extra: Array = []
			var maxy := 2.6
			for o: Dictionary in c.openings:
				if int(o.floor) == 0 and String(o.region).begins_with("O_apt_door") and String(o.facade) == "front" and absf(float(o.along) - float(b.door_along)) <= 0.3:
					o = o.duplicate(); o["entry"] = true
				if int(o.floor) != 0 or not regs.has(o.region) or not _is(o, OPEN): continue
				var al := float(o.along); var fa := String(o.facade)
				var inb := false
				if fa == "front": inb = al > X0 and al < X1
				elif fa == "left": inb = X0 <= float(f0.box_min[0]) + 0.35 and al > ZB and al < ZF
				elif fa == "right": inb = X1 >= float(f0.box_max[0]) - 0.35 and al > ZB and al < ZF
				elif fa == "back" and al > X0 and al < X1: back_extra.append(o)
				if inb and LEAN3 and fa != "front" and not _is(o, DOORS): inb = false
				if inb:
					ops.append(o); maxy = maxf(maxy, float(o.y1))
			for o2: Dictionary in c.openings:      # the back's staff doors (residential) and small windows stay closed
				if int(o2.floor) == 0 and String(o2.facade) == "back" and float(o2.along) > X0 and float(o2.along) < X1 and not back_extra.has(o2) and String(o2.region) in ["O_apt_door"]: back_extra.append(o2)
			# ceiling: above every opening it shows (+0.3), below the next floor's slab where that is higher, 4.3 m at most
			# (the contracts' clear_h is a guess from upper sills and is too low on some models)
			var next_y := float(c.floors[1].y) if c.floors.size() > 1 else float(c.get("height", FY + 4.5)) - 0.3
			CY = minf(FY + 4.28, maxf(maxy + 0.3, next_y - 0.12))
			var area := (X1 - X0) * (ZF - ZB)
			var nl := clampi(int(round(area / 35.0)), 1, 4)
			LIGHTS = []
			var cols := 2 if nl >= 2 and X1 - X0 >= 4.0 else 1; var rows := int(ceil(float(nl) / cols))
			for j in rows:
				for i in cols:
					if LIGHTS.size() < nl: LIGHTS.append(Vector2(lerpf(X0, X1, (i + 0.5) / cols), lerpf(ZB, ZF, (j + 0.5) / rows)))
			_shell(ops, back_extra)
			var ia := []; ia.resize(Mesh.ARRAY_MAX)
			ia[Mesh.ARRAY_VERTEX] = PackedVector3Array(V); ia[Mesh.ARRAY_NORMAL] = PackedVector3Array(N)
			ia[Mesh.ARRAY_TEX_UV] = PackedVector2Array(UVs); ia[Mesh.ARRAY_COLOR] = PackedColorArray(C)
			var st := SurfaceTool.new(); st.create_from_arrays(ia); st.index()
			var arr := _axis_tangents(st.commit_to_arrays())
			var sm := ArrayMesh.new(); sm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			var it := _interior(model, b, ops, gm, lay.get(model, {}).get(str(int(b.i)), {}))
			var shm := MeshInstance3D.new(); shm.name = "Shell"; shm.mesh = sm; shm.visible = false; it.add_child(shm)
			it.set_meta(&"shell_tris", tris_int)
			_own(it, it)
			var ps := PackedScene.new(); ps.pack(it)
			var path := "%s_bay%d.scn" % [pfx, int(b.i)]
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			var err := ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS)
			stats["%s|%d" % [model, int(b.i)]] = {"lean": LEAN, "lean2": LEAN2, "front_only": LEAN3, "shell_tris": tris_int, "ops": ops.size(), "glass_tris": it.get_meta(&"glass_tris"), "rect": [X0, ZB, X1, ZF], "ceiling": CY, "lights": LIGHTS.size(), "err": err}
			if err == OK: n_ok += 1
			it.free()
	var f := FileAccess.open(IB + "make_interiors_stats.json", FileAccess.WRITE); f.store_string(JSON.stringify(stats, " ")); f.close()
	print("MAKE_INTERIORS wrote %d bay scenes" % n_ok)
	quit(0)

## facade -> wall: [axis, inner wall plane, inward sign]
func _wall_of(facade: String) -> Array:
	match facade:
		"front": return ["z", ZF, -1.0]
		"back": return ["z", ZB, 1.0]
		"right": return ["x", X1, -1.0]
	return ["x", X0, 1.0]


func _shell(ops: Array, back_extra: Array) -> void:
	var holes := {"front": [], "back": [], "right": [], "left": []}
	for o: Dictionary in ops:
		(holes[String(o.facade)] as Array).append([float(o.along) - float(o.w) * 0.5, float(o.along) + float(o.w) * 0.5, maxf(float(o.y0), FY), float(o.y1)])
	for o: Dictionary in back_extra:
		(holes.back as Array).append([float(o.along) - float(o.w) * 0.5, float(o.along) + float(o.w) * 0.5, maxf(float(o.y0), FY), float(o.y1)])
	wall("z", ZF, X0, X1, -1.0, holes.front)
	wall("z", ZB, X0, X1, 1.0, holes.back)
	wall("x", X1, ZB, ZF, -1.0, holes.right)
	wall("x", X0, ZB, ZF, 1.0, holes.left)
	var fv := _strip("T_deck")
	var zs: Array = [ZB]
	var z := ZB + FLOOR_ROW
	while z < ZF - 0.1: zs.append(z); z += FLOOR_ROW
	zs.append(ZF)
	for j in zs.size() - 1:
		var z0 := float(zs[j]); var z1 := float(zs[j + 1])
		var v1 := lerpf(fv.x, fv.y, minf((z1 - z0) / FLOOR_ROW, 1.0))
		var uv := [Vector2(X0 / 8.0, fv.x), Vector2(X1 / 8.0, fv.x), Vector2(X1 / 8.0, v1), Vector2(X0 / 8.0, v1)]
		var c0 := STONE * ao_floor((X0 + X1) * 0.5, z0); var c1 := STONE * ao_floor((X0 + X1) * 0.5, z1)
		flat(X0, z0, X1, z1, FY, true, uv, [c0, c0, c1, c1])
	var sc := _sw("S_concrete")
	for o: Dictionary in ops:
		if not _is(o, DOORS): continue
		var w: Array = _wall_of(String(o.facade))
		hrect(String(w[0]), FY, float(o.along) - float(o.w) * 0.5, float(o.along) + float(o.w) * 0.5, float(w[1]), float(o.plane), true, sc, STONE * 0.8)
	var so := _sw("S_white"); var CEIL := Color(1.0, 0.99, 0.96)
	var e := minf(0.6, minf(X1 - X0, ZF - ZB) * 0.25)
	var cxs := [X0, X0 + e, X1 - e, X1]; var czs := [ZB, ZB + e, ZF - e, ZF]
	if LEAN2: cxs = [X0, X1]; czs = [ZB, ZF]
	for j in czs.size() - 1:
		for i in cxs.size() - 1:
			var x0 := float(cxs[i]); var x1 := float(cxs[i + 1]); var z0 := float(czs[j]); var z1 := float(czs[j + 1])
			var cc := func(x: float, zz: float) -> Color: return CEIL * lerpf(0.78, 1.0, smoothstep(0.0, 0.6, minf(minf(x - X0, X1 - x), minf(zz - ZB, ZF - zz))))
			flat(x0, z0, x1, z1, CY, false, [so, so, so, so], [cc.call(x0, z0), cc.call(x1, z0), cc.call(x1, z1), cc.call(x0, z1)])
	var sw := _sw("S_white")
	for lp: Vector2 in LIGHTS:
		flat(lp.x - 0.6, lp.y - 0.3, lp.x + 0.6, lp.y + 0.3, CY - 0.012, false, [sw, sw, sw, sw], [Color(1, 1, 0.97), Color(1, 1, 0.97), Color(1, 1, 0.97), Color(1, 1, 0.97)])
	for fac: String in ["front", "back", "right", "left"]:
		var w2: Array = _wall_of(fac); var ax := String(w2[0]); var at := float(w2[1]); var inw := float(w2[2])
		var s_a := X0 if ax == "z" else ZB; var s_b := X1 if ax == "z" else ZF
		var iv: Array = [[s_a, s_b]]
		for h: Array in holes[fac]:
			if float(h[2]) <= FY + 0.01: iv = _sub(iv, float(h[0]), float(h[1]))
		for sg: Array in iv:
			if LEAN2: break
			var p := at + inw * 0.015
			vrect(ax, p, float(sg[0]), float(sg[1]), FY, FY + 0.12, inw, strip_uv("T_dark", float(sg[0]), float(sg[1])), Color(0.85, 0.8, 0.75))
			hrect(ax, FY + 0.12, float(sg[0]), float(sg[1]), at, p, true, _sw("S_dark"), Color(0.8, 0.75, 0.7))
		if LEAN: continue
		var pc := at + inw * 0.03
		vrect(ax, pc, s_a, s_b, CY - 0.14, CY - 0.002, inw, strip_uv("T_white", s_a, s_b), Color(0.97, 0.95, 0.9))
		hrect(ax, CY - 0.14, s_a, s_b, at, pc, false, _sw("S_white"), Color(0.85, 0.83, 0.8))
	var tw := _sw("S_white"); var trim := Color(0.96, 0.94, 0.89)
	for o: Dictionary in ops:
		var w3: Array = _wall_of(String(o.facade)); var ax := String(w3[0]); var at := float(w3[1]); var inw := float(w3[2])
		var pl := float(o.plane); var s0 := float(o.along) - float(o.w) * 0.5; var s1 := float(o.along) + float(o.w) * 0.5
		var y0 := maxf(float(o.y0), FY); var y1 := float(o.y1)
		var door := _is(o, DOORS)
		var rv := _sw("S_stucco"); var rc := PLASTER * 0.88
		jamb(ax, s0, at, pl, y0, y1, 1.0, rv, rc); jamb(ax, s1, at, pl, y0, y1, -1.0, rv, rc)
		hrect(ax, y1, s0, s1, at, pl, false, rv, rc * 0.85)
		var cw := 0.08; var cp := at + inw * 0.008
		if LEAN2:
			if not door: _bar(ax, pl, s0, s1, y1 - 0.06, y1, inw, trim)
			continue
		if door:
			vrect(ax, cp, s0 - cw, s0, y0, y1 + cw, inw, strip_uv("T_white", s0 - cw, s0), trim)
			vrect(ax, cp, s1, s1 + cw, y0, y1 + cw, inw, strip_uv("T_white", s1, s1 + cw), trim)
			vrect(ax, cp, s0, s1, y1, y1 + cw, inw, strip_uv("T_white", s0, s1), trim)
			var lh := minf(float(regs[o.region].get("door_leaf_m", 2.2)), y1 - 0.05)
			if y1 - lh > 0.15: _bar(ax, pl, s0, s1, lh - 0.04, lh + 0.04, inw, Color(0.7, 0.62, 0.55))
		else:
			if y0 > FY + 0.05:
				hrect(ax, y0, s0, s1, at, pl, true, tw, trim)
				var sp := at + inw * 0.04
				hrect(ax, y0 + 0.035, s0 - 0.06, s1 + 0.06, at, sp, true, tw, trim)
				vrect(ax, sp, s0 - 0.06, s1 + 0.06, y0 - 0.02, y0 + 0.035, inw, strip_uv("T_white", s0 - 0.06, s1 + 0.06), trim * 0.92)
			else:
				_bar(ax, pl, s0, s1, FY, FY + 0.12, inw, trim)      # storefront: a kick rail at the floor
			vrect(ax, cp, s0 - cw, s0, y0 + 0.035, y1 + cw, inw, strip_uv("T_white", s0 - cw, s0), trim)
			vrect(ax, cp, s1, s1 + cw, y0 + 0.035, y1 + cw, inw, strip_uv("T_white", s1, s1 + cw), trim)
			vrect(ax, cp, s0, s1, y1, y1 + cw, inw, strip_uv("T_white", s0, s1), trim)
			var fw := 0.06; var ty := y0 + (y1 - y0) * 0.72
			_bar(ax, pl, s0, s0 + fw, y0, y1, inw, trim); _bar(ax, pl, s1 - fw, s1, y0, y1, inw, trim)
			_bar(ax, pl, s0, s1, y1 - fw, y1, inw, trim)
			if not LEAN:
				if s1 - s0 > 1.0: _bar(ax, pl, float(o.along) - 0.025, float(o.along) + 0.025, y0, ty, inw, trim)
				_bar(ax, pl, s0, s1, ty - 0.025, ty + 0.025, inw, trim)
	for o: Dictionary in back_extra:
		var pl2 := float(o.plane) + 0.012; var s0b := float(o.along) - float(o.w) * 0.5; var s1b := float(o.along) + float(o.w) * 0.5
		var y0b := maxf(float(o.y0), FY); var y1b := float(o.y1)
		var rv2 := _sw("S_stucco"); var rc2 := PLASTER * 0.88
		jamb("z", s0b, ZB, pl2, y0b, y1b, 1.0, rv2, rc2); jamb("z", s1b, ZB, pl2, y0b, y1b, -1.0, rv2, rc2)
		hrect("z", y1b, s0b, s1b, ZB, pl2, false, rv2, rc2 * 0.85)
		if String(o.region).ends_with("door") or y0b <= FY + 0.05:
			vrect("z", pl2, s0b, s1b, y0b, y1b, 1.0, strip_uv("T_dark", s0b, s1b), Color(0.9, 0.82, 0.74))
			vrect("z", ZB + 0.008, s0b - 0.08, s0b, y0b, y1b + 0.08, 1.0, strip_uv("T_white", s0b - 0.08, s0b), trim)
			vrect("z", ZB + 0.008, s1b, s1b + 0.08, y0b, y1b + 0.08, 1.0, strip_uv("T_white", s1b, s1b + 0.08), trim)
			vrect("z", ZB + 0.008, s0b, s1b, y1b, y1b + 0.08, 1.0, strip_uv("T_white", s0b, s1b), trim)
		else:
			hrect("z", y0b, s0b, s1b, ZB, pl2, true, tw, trim)
			vrect("z", pl2, s0b, s1b, y0b, y1b, 1.0, [_sw("S_white"), _sw("S_white"), _sw("S_white"), _sw("S_white")], Color(0.9, 0.96, 1.0))

func _interior(model: String, b: Dictionary, ops: Array, gm: Material, lay: Dictionary) -> Node3D:
	var it := Node3D.new(); it.name = "%s_bay%d" % [model.get_file(), int(b.i)]
	var sl := Node3D.new(); sl.name = "Slots"; it.add_child(sl)
	for kind: String in lay:
		var kn := Node3D.new(); kn.name = kind; sl.add_child(kn)
		for t: String in lay[kind]:
			var tn := Node3D.new(); tn.name = t; kn.add_child(tn)
			tn.set_meta(&"mirror_ok", bool(lay[kind][t].get("mirror_ok", false))); tn.set_meta(&"tris", int(lay[kind][t].get("tris", 0)))
			for s: Array in lay[kind][t].slots:
				var m := Marker3D.new(); m.name = String(s[0])
				m.position = Vector3(float(s[3]), FY, float(s[4])); m.rotation.y = deg_to_rad(float(s[5]))
				m.set_meta(&"slot_type", String(s[1])); m.set_meta(&"variant", int(s[2])); m.set_meta(&"lift", float(s[6]))
				if String(s[7]) != "": m.set_meta(&"on", String(s[7]))
				tn.add_child(m)
	var gv: Array = []; var gn: Array = []; var gu: Array = []
	var panes: Array = []; var cuts: Array = []
	var win_node: Node3D = null
	for o: Dictionary in ops:
		var w: Array = _wall_of(String(o.facade)); var ax := String(w[0]); var inw := float(w[2])
		var door := _is(o, DOORS)
		cuts.append([String(o.facade), float(o.along), "door" if door else "window"])
		var s0 := float(o.along) - float(o.w) * 0.5; var s1 := float(o.along) + float(o.w) * 0.5
		var y0 := maxf(float(o.y0), FY); var y1 := float(o.y1)
		if door:
			y0 = minf(float(regs[o.region].get("door_leaf_m", 2.2)), y1 - 0.05) + 0.04
			if y1 - y0 < 0.1: continue
		var pl := float(o.plane)
		panes.append([String(o.facade), float(o.along)])
		if not door and win_node == null and String(o.facade) == "front":
			win_node = _break_window(o, ax, pl, s0, s1, y0, y1, inw, gm); continue
		var n := Vector3(0, 0, -inw) if ax == "z" else Vector3(-inw, 0, 0)
		var A := P(ax, pl, s0, y0); var B := P(ax, pl, s1, y0); var Cc := P(ax, pl, s1, y1); var D := P(ax, pl, s0, y1)
		for q: Array in [[A, Vector2(0, 1)], [Cc, Vector2(1, 0)], [B, Vector2(1, 1)], [A, Vector2(0, 1)], [D, Vector2(0, 0)], [Cc, Vector2(1, 0)]]:
			gv.append(q[0]); gn.append(n); gu.append(q[1])
	if not gv.is_empty():
		var ga := []; ga.resize(Mesh.ARRAY_MAX)
		ga[Mesh.ARRAY_VERTEX] = PackedVector3Array(gv); ga[Mesh.ARRAY_NORMAL] = PackedVector3Array(gn); ga[Mesh.ARRAY_TEX_UV] = PackedVector2Array(gu)
		var gam := ArrayMesh.new(); gam.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ga); gam.surface_set_material(0, gm)
		var gmi := MeshInstance3D.new(); gmi.name = "Glass"; gmi.mesh = gam; gmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		it.add_child(gmi)
	it.set_meta(&"glass_tris", gv.size() / 3)
	var wn := Node3D.new(); wn.name = "Windows"; it.add_child(wn)
	if win_node: wn.add_child(win_node)
	var dn := Node3D.new(); dn.name = "Doors"; it.add_child(dn)
	for o: Dictionary in ops:
		if _is(o, DOORS): _door_pair(dn, o, gm)
	var ln := Node3D.new(); ln.name = "Lights"; it.add_child(ln)
	for lp: Vector2 in LIGHTS:
		var l := OmniLight3D.new(); l.position = Vector3(lp.x, CY - 0.25, lp.y)
		l.light_color = Color(1.0, 0.9, 0.78); l.light_energy = 1.3; l.omni_range = 6.5; l.omni_attenuation = 1.2
		l.shadow_enabled = false; l.distance_fade_enabled = true; l.distance_fade_begin = BL.PROP_END; l.distance_fade_length = 10.0
		ln.add_child(l)
	# collision: the bay's inner walls (party walls included) as boxes just behind the shell faces, floor to ceiling
	var col := StaticBody3D.new(); col.name = "col"; it.add_child(col)
	var H := CY; var T := 0.1
	var boxes := [["left", Vector3(X0 - T * 0.5, H * 0.5, (ZB + ZF) * 0.5), Vector3(T, H, ZF - ZB)], ["right", Vector3(X1 + T * 0.5, H * 0.5, (ZB + ZF) * 0.5), Vector3(T, H, ZF - ZB)],
		["back", Vector3((X0 + X1) * 0.5, H * 0.5, ZB - T * 0.5), Vector3(X1 - X0 + 2 * T, H, T)]]
	for bx: Array in boxes:
		var cs := CollisionShape3D.new(); cs.name = String(bx[0]); var bs := BoxShape3D.new(); bs.size = bx[2]; cs.shape = bs; cs.position = bx[1]; col.add_child(cs)
	it.set_meta(&"builtin_interior", true); it.set_meta(&"model", model); it.set_meta(&"bay", int(b.i)); it.set_meta(&"kinds", b.kinds)
	it.set_meta(&"span", [X0, X1]); it.set_meta(&"door_along", float(b.door_along))
	it.set_meta(&"cuts", cuts); it.set_meta(&"panes", panes); it.set_meta(&"ops", ops)
	it.set_meta(&"floors", [[X0, ZB, X1, ZF]])
	it.set_meta(&"entrances", [["z", ZF, float(b.door_along) - float(b.door_w) * 0.5, float(b.door_along) + float(b.door_w) * 0.5]])
	it.set_meta(&"ceiling", CY); it.set_meta(&"floor_y", FY)
	return it

func _own(n: Node, o: Node) -> void:
	for c in n.get_children():
		c.owner = o; _own(c, o)

## a frame bar at the glass plane: one quad each side (just outside and just inside the pane)
func _bar(ax: String, pl: float, s0: float, s1: float, y0: float, y1: float, inw: float, col: Color) -> void:
	var t := strip_uv("T_white", s0, s1)
	vrect(ax, pl - inw * 0.012, s0, s1, y0, y1, -inw, t, col)      # street side
	vrect(ax, pl + inw * 0.025, s0, s1, y0, y1, inw, t, col)       # room side

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
	var lh := minf(float(regs[o.region].get("door_leaf_m", 2.2)), float(o.y1) - 0.05) - 0.005
	var y0 := FY; var h := lh - y0
	var nl := 2 if s1 - s0 >= 1.3 else 1
	var lw := (s1 - s0) / nl
	var plane := float(o.plane) - out * 0.05
	var bmat: Material = load(BLD_MAT)
	for i in nl:
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
