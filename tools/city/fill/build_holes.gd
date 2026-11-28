extends SceneTree
## THE HOLES' piece (28 Nov night; tools/city/fill/fill_holes.py writes its data, this turns it into pieces/fx_holes.scn):
## "ground" (one mesh, one surface per material, each the very material of the ground it continues, with its UVs and
## colours carried on) and "ground_col" (its triangles). Writes nothing else.
##   godot --headless --path . -s res://tools/city/fill/build_holes.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
const SRC := "res://OUT/fill/pieces/fx_holes"

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SRC + ".json"))
	var raw := FileAccess.get_file_as_bytes(SRC + ".bin").to_float32_array()
	var root := Node3D.new(); root.name = "fx_holes"
	var am := ArrayMesh.new()
	var tris := 0
	for s: Dictionary in meta.surfaces:
		var cnt := int(s.count); var off := int(s.offset) / 4
		var V := PackedVector3Array(); var N := PackedVector3Array(); var UV := PackedVector2Array(); var C := PackedColorArray()
		V.resize(cnt); N.resize(cnt); UV.resize(cnt); C.resize(cnt)
		for i in cnt:
			var o := off + i * 11
			V[i] = Vector3(raw[o], raw[o + 1], raw[o + 2]); N[i] = Vector3(raw[o + 3], raw[o + 4], raw[o + 5])
			UV[i] = Vector2(raw[o + 6], raw[o + 7]); C[i] = Color(raw[o + 8], raw[o + 9], raw[o + 10], 1.0)
		var arr := []; arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_COLOR] = C
		var st := SurfaceTool.new(); st.create_from_arrays(arr); st.index(); st.generate_tangents()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
		var mat: Material = load(String(s.mat))
		am.surface_set_material(am.get_surface_count() - 1, mat)
		# (the surface's name is the ground's own name, as in every piece: the bake and the checks read it)
		am.surface_set_name(am.get_surface_count() - 1, String(s.mat).get_file().get_basename().trim_prefix("g_").trim_prefix("fill_"))
		tris += cnt / 3
	var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = am
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
	var body := StaticBody3D.new(); body.name = "ground_col"
	var cs := CollisionShape3D.new(); cs.shape = am.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
	print("HOLES fx_holes: ground tris %d, surfaces %d" % [tris, am.get_surface_count()])
	K.save_piece(root, "fx_holes")
	root.free()
	quit()
