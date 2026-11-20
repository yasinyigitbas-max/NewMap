extends SceneTree
## Hand edit (Yasin, 20 Nov: "those corners where we spawn are still empty" / "they have collision but no cement"):
## j_cc's four corner quarter-circles (the polygons of review/superchecker/j_cc.collision.fixes.json, which gave them
## collision on 19 Nov) drawn in the ground mesh's concrete surface, at the pavement's height (0.15). Texture mapping
## taken from the nearest concrete triangle (its own affine UV map), so the paving runs on without a seam. Real renderer.
const P := "res://map_dc/coronado/city_kit/pieces/j_cc.scn"

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/review/superchecker/j_cc.collision.fixes.json"))
	var top: Node3D = (ResourceLoader.load(P, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	var mi := top.get_node("ground") as MeshInstance3D
	var am := mi.mesh as ArrayMesh
	var si := -1
	for s in am.get_surface_count():
		if am.surface_get_material(s) and am.surface_get_material(s).resource_path.get_file() == "g_concrete.tres": si = s
	assert(si >= 0)
	var surfs: Array = []
	for s in am.get_surface_count(): surfs.append([am.surface_get_arrays(s), am.surface_get_material(s), am.surface_get_format(s)])
	var a: Array = surfs[si][0]
	var V: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var N: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var UV: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var T: PackedFloat32Array = a[Mesh.ARRAY_TANGENT] if a[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
	var C: PackedColorArray = a[Mesh.ARRAY_COLOR] if a[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var IDX: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	assert(a[Mesh.ARRAY_TEX_UV2] == null and a[Mesh.ARRAY_BONES] == null)
	var tri := func(k: int) -> PackedInt32Array:
		return PackedInt32Array([IDX[k * 3], IDX[k * 3 + 1], IDX[k * 3 + 2]]) if IDX.size() > 0 else PackedInt32Array([k * 3, k * 3 + 1, k * 3 + 2])
	var ntri := IDX.size() / 3 if IDX.size() > 0 else V.size() / 3
	var added := 0
	for f: Dictionary in fx.fixes:
		var y := float(f.y); var poly: Array = []
		for c: Array in f.poly: poly.append(Vector3(float(c[0]), y, float(c[1])))
		var cen := Vector3.ZERO
		for p: Vector3 in poly: cen += p
		cen /= poly.size()
		# the nearest flat concrete triangle at this height: its UV as an affine function of (x, z)
		var best := -1; var bd := 1.0e9
		for k in ntri:
			var t: PackedInt32Array = tri.call(k)
			var c3 := (V[t[0]] + V[t[1]] + V[t[2]]) / 3.0
			if absf(c3.y - y) > 0.03: continue
			var nn := (V[t[1]] - V[t[0]]).cross(V[t[2]] - V[t[0]])
			if nn.length() < 1.0e-6 or absf(nn.normalized().y) < 0.99: continue
			var d := Vector2(c3.x - cen.x, c3.z - cen.z).length()
			if d < bd: bd = d; best = k
		assert(best >= 0)
		var bt: PackedInt32Array = tri.call(best)
		var p0 := V[bt[0]]; var p1 := V[bt[1]]; var p2 := V[bt[2]]
		var e1 := Vector2(p1.x - p0.x, p1.z - p0.z); var e2 := Vector2(p2.x - p0.x, p2.z - p0.z); var det := e1.x * e2.y - e1.y * e2.x
		var uv_at := func(p: Vector3) -> Vector2:
			var d2 := Vector2(p.x - p0.x, p.z - p0.z)
			var s := (d2.x * e2.y - d2.y * e2.x) / det; var u := (e1.x * d2.y - e1.y * d2.x) / det
			return UV[bt[0]] + (UV[bt[1]] - UV[bt[0]]) * s + (UV[bt[2]] - UV[bt[0]]) * u
		var up_n := N[bt[0]]
		var wind := signf((p1 - p0).cross(p2 - p0).y)      # the existing triangles' winding, kept
		for i in range(1, poly.size() - 1):
			var q: Array = [poly[0], poly[i], poly[i + 1]]
			if signf(((q[1] as Vector3) - (q[0] as Vector3)).cross((q[2] as Vector3) - (q[0] as Vector3)).y) != wind: q = [q[0], q[2], q[1]]
			for p: Vector3 in q:
				if IDX.size() > 0: IDX.append(V.size())
				V.append(p); N.append(up_n); UV.append(uv_at.call(p))
				if T.size() > 0: for j in 4: T.append(T[bt[0] * 4 + j])
				if C.size() > 0: C.append(C[bt[0]])
			added += 1
		print("CORNER %s: %d corners, %d triangles, uv from the concrete triangle %.1f m away" % [str(f.at), poly.size(), poly.size() - 2, bd])
	a[Mesh.ARRAY_VERTEX] = V; a[Mesh.ARRAY_NORMAL] = N; a[Mesh.ARRAY_TEX_UV] = UV
	if T.size() > 0: a[Mesh.ARRAY_TANGENT] = T
	if C.size() > 0: a[Mesh.ARRAY_COLOR] = C
	if IDX.size() > 0: a[Mesh.ARRAY_INDEX] = IDX
	surfs[si][0] = a
	var fresh := ArrayMesh.new()
	for s in surfs.size():
		fresh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surfs[s][0])
		fresh.surface_set_material(s, surfs[s][1])
	mi.mesh = fresh
	var ps := PackedScene.new(); ps.pack(top)
	var err := ResourceSaver.save(ps, P, ResourceSaver.FLAG_COMPRESS)
	print("JCC %d triangles added to the concrete, saved %s" % [added, error_string(err)])
	top.free(); quit(0)
