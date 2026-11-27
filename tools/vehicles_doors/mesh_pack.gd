extends SceneTree
## mesh_pack.gd -- <in_prefix> <out.res> [<doors.json>]: a mesh_dump-format mesh -> ArrayMesh .res (positions, normals,
## tangents, UV, UV2, indices: the old cars' layout), with the metas it was dumped with. With doors.json (the body):
## adds the meta "doors" = {l: {hinge, max_angle_deg}, r: ...} and "cabin" = {lo, hi} for CityCar.

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(a[0] + ".json"))
	var raw := FileAccess.get_file_as_bytes(a[0] + ".bin")
	var nv := int(j["verts"])
	var ni := int(j["indices"])
	var buf := StreamPeerBuffer.new()
	buf.data_array = raw
	var P := PackedVector3Array(); var N := PackedVector3Array(); var T := PackedFloat32Array()
	var U := PackedVector2Array(); var U2 := PackedVector2Array(); var I := PackedInt32Array()
	P.resize(nv); N.resize(nv); T.resize(nv * 4); U.resize(nv); U2.resize(nv); I.resize(ni)
	for i in nv:
		P[i] = Vector3(buf.get_float(), buf.get_float(), buf.get_float())
		N[i] = Vector3(buf.get_float(), buf.get_float(), buf.get_float())
		for k in 4: T[i * 4 + k] = buf.get_float()
		U[i] = Vector2(buf.get_float(), buf.get_float())
		U2[i] = Vector2(buf.get_float(), buf.get_float())
	for i in ni: I[i] = buf.get_32()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = P; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TANGENT] = T
	arr[Mesh.ARRAY_TEX_UV] = U; arr[Mesh.ARRAY_TEX_UV2] = U2; arr[Mesh.ARRAY_INDEX] = I
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var metas: Dictionary = j.get("metas", {})
	for k in metas: m.set_meta(k, str_to_var(metas[k]))
	if a.size() > 2:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(a[2]))
		var doors := {}
		for sd in d["doors"]:
			var h: Array = d["doors"][sd]["hinge"]
			doors[sd] = {"hinge": Vector3(h[0], h[1], h[2]), "max_angle_deg": float(d["doors"][sd]["max_angle_deg"])}
		m.set_meta("doors", doors)
		var c: Dictionary = d["cabin"]
		m.set_meta("cabin", {"lo": Vector3(c["lo"][0], c["lo"][1], c["lo"][2]), "hi": Vector3(c["hi"][0], c["hi"][1], c["hi"][2])})
	var err := ResourceSaver.save(m, a[1], ResourceSaver.FLAG_COMPRESS)
	print("PACKED ", a[1], " verts=", nv, " tris=", ni / 3, " err=", err, " metas=", m.get_meta_list())
	quit()
