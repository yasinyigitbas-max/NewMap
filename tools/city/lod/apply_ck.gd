extends SceneTree
## Put the LOD-match meshes (tools/city/lod/lod_bake.py) into the city-kit merged buildings' mid / far scenes
## (map_dc/coronado/city_kit/buildings/<name>/<name>_{mid,far}.scn). Same file, same node name and transform; only the
## mesh (geometry kept, UVs into textures/bld_lod_color.png) and its material change. Near and col are not touched.
## usage: godot --headless --path . -s res://tools/city/lod/apply_ck.gd -- /tmp/lod_ck_out
func _init() -> void:
	var d := OS.get_cmdline_user_args()[0]
	var n := 0
	for f in DirAccess.get_files_at(d):
		if not f.ends_with(".json"): continue
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(d.path_join(f)))
		var raw := FileAccess.get_file_as_bytes(d.path_join(f.get_basename() + ".bin"))
		var nv := int(meta.nv); var ni := int(meta.ni)
		var fl := raw.slice(0, nv * 48).to_float32_array(); var ix := raw.slice(nv * 48, nv * 48 + ni * 4).to_int32_array()
		var V := PackedVector3Array(); var N := PackedVector3Array(); var UV := PackedVector2Array(); var C := PackedColorArray()
		for k in nv:
			var o := k * 12
			V.append(Vector3(fl[o], fl[o + 1], fl[o + 2])); N.append(Vector3(fl[o + 3], fl[o + 4], fl[o + 5]).normalized())
			UV.append(Vector2(fl[o + 6], fl[o + 7])); C.append(Color(fl[o + 8], fl[o + 9], fl[o + 10], fl[o + 11]))
		var arr := []; arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_COLOR] = C; arr[Mesh.ARRAY_INDEX] = ix
		var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mat := StandardMaterial3D.new(); mat.albedo_texture = load(String(meta.page)); mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.85; mat.resource_name = "bld_lod"
		am.surface_set_material(0, mat)
		var src := String(meta.src)
		var ps: PackedScene = load(src); var root := ps.instantiate()
		var mi := _first(root)
		mi.mesh = am
		var out := PackedScene.new(); out.pack(root); ResourceSaver.save(out, src); root.free()
		print("ck ", src.get_file(), " tris ", ni / 3); n += 1
	print("applied ", n)
	quit()

func _first(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _first(c)
		if r: return r
	return null
