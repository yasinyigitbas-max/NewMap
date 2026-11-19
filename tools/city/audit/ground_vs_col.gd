extends SceneTree
## Drawn ground without collision (19 Nov, the collision-holes job). Reads only.
##   godot --headless --path . -s res://tools/city/audit/ground_vs_col.gd -- [piece ...] [--step=0.25] [--min=0.5]
## (no piece named: every piece of the layout, each once). For each piece: its drawn "ground" mesh and its ground
## collision (the concave shapes of its StaticBody3D nodes) are both laid on a grid from above (upward faces only, the
## piece's own frame). A grid point the drawn ground covers and no collision triangle does is a hole in that piece;
## neighbouring points are one hole. Prints each hole bigger than --min metres across (piece frame and the height),
## and the piece's surface (material / surface name) drawn there.
var step := 0.25
var min_m := 0.5

func _init() -> void: _run.call_deferred()

func _tris_mesh(m: Mesh, xf: Transform3D, out: Array) -> void:
	for si in m.get_surface_count():
		var a := m.surface_get_arrays(si)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
		var nm: String = m.surface_get_name(si)
		if nm == "" and m.surface_get_material(si): nm = m.surface_get_material(si).resource_name
		if nm == "": nm = "surface %d" % si
		for t in range(0, idx.size() - 2, 3): out.append([xf * v[idx[t]], xf * v[idx[t + 1]], xf * v[idx[t + 2]], nm])

func _collect(n: Node, xf: Transform3D, drawn: Array, col: Array) -> void:
	var nx := xf
	if n is Node3D: nx = xf * (n as Node3D).transform
	if n is MeshInstance3D and String(n.name) == "ground" and (n as MeshInstance3D).mesh: _tris_mesh((n as MeshInstance3D).mesh, nx, drawn)
	if n is CollisionShape3D and (n as CollisionShape3D).shape is ConcavePolygonShape3D:
		var f := ((n as CollisionShape3D).shape as ConcavePolygonShape3D).get_faces()
		for t in f.size() / 3: col.append([nx * f[t * 3], nx * f[t * 3 + 1], nx * f[t * 3 + 2], ""])
	for c in n.get_children(): _collect(c, nx, drawn, col)

## grid points (key Vector2i) an upward triangle covers -> [height, name]
func _raster(tris: Array, out: Dictionary) -> void:
	for t: Array in tris:
		var a: Vector3 = t[0]; var b: Vector3 = t[1]; var c: Vector3 = t[2]
		var n := (b - a).cross(c - a)
		if n.length_squared() < 1.0e-12 or absf(n.normalized().y) < 0.5: continue
		var den := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
		if absf(den) < 1.0e-9: continue
		for iz in range(ceili(minf(a.z, minf(b.z, c.z)) / step), floori(maxf(a.z, maxf(b.z, c.z)) / step) + 1):
			for ix in range(ceili(minf(a.x, minf(b.x, c.x)) / step), floori(maxf(a.x, maxf(b.x, c.x)) / step) + 1):
				var px := ix * step; var pz := iz * step
				var l0 := ((b.z - c.z) * (px - c.x) + (c.x - b.x) * (pz - c.z)) / den
				var l1 := ((c.z - a.z) * (px - c.x) + (a.x - c.x) * (pz - c.z)) / den
				var l2 := 1.0 - l0 - l1
				if l0 < -1.0e-4 or l1 < -1.0e-4 or l2 < -1.0e-4: continue
				out[Vector2i(ix, iz)] = [l0 * a.y + l1 * b.y + l2 * c.y, t[3]]

func _check(piece: String) -> Array:
	var p := "res://map_dc/coronado/city_kit/pieces/%s.scn" % piece
	if not ResourceLoader.exists(p): return []
	var inst: Node = (load(p) as PackedScene).instantiate()
	var drawn: Array = []; var col: Array = []
	for c in inst.get_children(): _collect(c, Transform3D.IDENTITY, drawn, col)
	inst.free()
	if drawn.is_empty(): return []
	var gd := {}; var gc := {}
	_raster(drawn, gd); _raster(col, gc)
	var miss := {}
	for k: Vector2i in gd:
		if not gc.has(k): miss[k] = true
	# neighbouring missing points are one hole
	var seen := {}; var holes: Array = []
	for k0: Vector2i in miss:
		if seen.has(k0): continue
		var stack: Array = [k0]; seen[k0] = true; var pts: Array = []
		while not stack.is_empty():
			var k: Vector2i = stack.pop_back(); pts.append(k)
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if miss.has(k + o) and not seen.has(k + o): seen[k + o] = true; stack.append(k + o)
		var lo := Vector2i(1 << 30, 1 << 30); var hi := -lo; var names := {}; var y := 0.0
		for k2: Vector2i in pts:
			lo = Vector2i(mini(lo.x, k2.x), mini(lo.y, k2.y)); hi = Vector2i(maxi(hi.x, k2.x), maxi(hi.y, k2.y))
			names[gd[k2][1]] = true; y += float(gd[k2][0])
		var sx := (hi.x - lo.x + 1) * step; var sz := (hi.y - lo.y + 1) * step
		if maxf(sx, sz) < min_m: continue
		holes.append({"piece": piece, "x0": lo.x * step, "z0": lo.y * step, "x1": hi.x * step, "z1": hi.y * step, "y": snappedf(y / pts.size(), 0.01), "area_m2": pts.size() * step * step, "surfaces": names.keys()})
	return holes

func _run() -> void:
	var pieces: Array = []
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--step="): step = float(a.trim_prefix("--step="))
		elif a.begins_with("--min="): min_m = float(a.trim_prefix("--min="))
		elif a.begins_with("--"): continue
		else: pieces.append(a)
	if pieces.is_empty():
		var seen := {}
		for r: Dictionary in (JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/city_grid_layout.json")) as Dictionary).instances:
			if not seen.has(r.piece): seen[r.piece] = true; pieces.append(String(r.piece))
	var all: Array = []
	for pc: String in pieces:
		var hs := _check(pc)
		for h: Dictionary in hs:
			print("GVC %s: (%.2f..%.2f, %.2f..%.2f) y %.2f, %.2f m2 drawn without collision, surface %s" % [pc, h.x0, h.x1, h.z0, h.z1, h.y, h.area_m2, str(h.surfaces)])
		all.append_array(hs)
	print("GVC done: %d pieces, %d holes over %.1f m across" % [pieces.size(), all.size(), min_m])
	var f := FileAccess.open("res://OUT/ground_vs_col.json", FileAccess.WRITE); f.store_string(JSON.stringify(all, "\t")); f.close()
	quit(0)
