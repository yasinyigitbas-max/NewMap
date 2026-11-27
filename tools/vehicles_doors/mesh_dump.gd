extends SceneTree
## mesh_dump.gd -- <in.res> <out_prefix>: one ArrayMesh surface -> <out>.json (counts, metas, aabb) + <out>.bin
## (float32 positions xyz, normals xyz, tangents xyzw, uv xy, uv2 xy per vertex, then int32 indices). For cutting the
## old cars' doors in Blender (cut_doors.py) and writing them back with mesh_pack.gd.

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var m := load(a[0]) as ArrayMesh
	var arr := m.surface_get_arrays(0)
	var P: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var N: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var T: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT]
	var U: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var U2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var I: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var buf := StreamPeerBuffer.new()
	for i in P.size():
		buf.put_float(P[i].x); buf.put_float(P[i].y); buf.put_float(P[i].z)
		buf.put_float(N[i].x); buf.put_float(N[i].y); buf.put_float(N[i].z)
		for k in 4: buf.put_float(T[i * 4 + k])
		buf.put_float(U[i].x); buf.put_float(U[i].y)
		buf.put_float(U2[i].x); buf.put_float(U2[i].y)
	for i in I: buf.put_32(i)
	var f := FileAccess.open(a[1] + ".bin", FileAccess.WRITE); f.store_buffer(buf.data_array); f.close()
	var metas := {}
	for k in m.get_meta_list(): metas[k] = var_to_str(m.get_meta(k))
	var j := {"verts": P.size(), "indices": I.size(), "format": m.surface_get_format(0), "metas": metas, "aabb": var_to_str(m.get_aabb())}
	f = FileAccess.open(a[1] + ".json", FileAccess.WRITE); f.store_string(JSON.stringify(j, " ")); f.close()
	print("DUMPED ", a[0], " verts=", P.size(), " idx=", I.size())
	quit()
