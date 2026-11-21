extends SceneTree
## Write the res2 LOD-match mid / far (res2_lod.py arrays) into map_dc/.../ck_brk3_res2/ck_brk3_res2_{mid,far}.scn with
## ck_brk3_row2's own mid / far material (same page, same material: batches with its neighbours).
func _init() -> void:
	var B := "res://OUT/shops_apply/res/bake/"; var K := "res://map_dc/coronado/city_kit/buildings/"
	for tier in ["mid", "far"]:
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(B + tier + ".json"))
		var raw := FileAccess.get_file_as_bytes(B + tier + ".bin"); var nv := int(meta.nv); var ni := int(meta.ni)
		var fl := raw.slice(0, nv * 48).to_float32_array(); var ix := raw.slice(nv * 48, nv * 48 + ni * 4).to_int32_array()
		var V := PackedVector3Array(); var N := PackedVector3Array(); var UV := PackedVector2Array(); var C := PackedColorArray()
		for k in nv:
			var o := k * 12
			V.append(Vector3(fl[o], fl[o + 1], fl[o + 2])); N.append(Vector3(fl[o + 3], fl[o + 4], fl[o + 5]).normalized())
			UV.append(Vector2(fl[o + 6], fl[o + 7])); C.append(Color(fl[o + 8], fl[o + 9], fl[o + 10], fl[o + 11]))
		var arr := []; arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_COLOR] = C; arr[Mesh.ARRAY_INDEX] = ix
		var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var rmi := _first((load(K + "ck_brk3_row2/ck_brk3_row2_%s.scn" % tier) as PackedScene).instantiate())
		am.surface_set_material(0, rmi.mesh.surface_get_material(0))
		var src := K + "ck_brk3_res2/ck_brk3_res2_%s.scn" % tier
		var root := (load(src) as PackedScene).instantiate(); var mi := _first(root); mi.mesh = am
		var out := PackedScene.new(); out.pack(root); ResourceSaver.save(out, src); root.free()
		print("res2 ", tier, " tris ", ni / 3, " mat ", am.surface_get_material(0).resource_path, " ", (am.surface_get_material(0) as BaseMaterial3D).albedo_texture.resource_path if am.surface_get_material(0) is BaseMaterial3D else "")
	quit()
func _first(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _first(c)
		if r: return r
	return null
