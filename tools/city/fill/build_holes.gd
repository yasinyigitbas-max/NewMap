extends SceneTree
## THE HOLES' piece (28 Nov night; tools/city/fill/fill_holes.py writes its data, this turns it into pieces/fx_holes.scn).
## One part per 200 m cell of the runtime bake (a Node3D "c_<x>_<z>"), each with "ground" (one mesh, one surface per
## material, each the very material of the ground it continues, with its UVs and colours carried on) and "ground_col"
## (its triangles). (28 Nov, Yasin: "There are still huge holes on the ground") the bake files a piece's ground mesh in
## the ONE cell of its bounding box's centre (bake_runtime.gd _walk): as one island-wide mesh every patch was filed in
## a cell near the middle, drawn and solid only near there; elsewhere the far ground's flat picture showed through.
## A triangle goes to the cell of its centre. Writes nothing else.
##   godot --headless --path . -s res://tools/city/fill/build_holes.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
const SRC := "res://OUT/fill/pieces/fx_holes"
const CELL := 200.0      # (bake_runtime.gd CELL)

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SRC + ".json"))
	var raw := FileAccess.get_file_as_bytes(SRC + ".bin").to_float32_array()
	var root := Node3D.new(); root.name = "fx_holes"
	# per cell, per material: the vertex rows (11 floats each, 3 a triangle)
	var parts := {}      # Vector2i -> {mat path -> PackedFloat32Array}
	var mat_name := {}
	for s: Dictionary in meta.surfaces:
		var cnt := int(s.count); var off := int(s.offset) / 4
		mat_name[String(s.mat)] = true
		for t in cnt / 3:
			var o := off + t * 33
			var cx := (raw[o] + raw[o + 11] + raw[o + 22]) / 3.0; var cz := (raw[o + 2] + raw[o + 13] + raw[o + 24]) / 3.0
			var c := Vector2i(floori(cx / CELL), floori(cz / CELL))
			if not parts.has(c): parts[c] = {}
			var d: Dictionary = parts[c]
			if not d.has(String(s.mat)): d[String(s.mat)] = PackedFloat32Array()
			var buf: PackedFloat32Array = d[String(s.mat)]
			buf.append_array(raw.slice(o, o + 33))
			d[String(s.mat)] = buf
	var tris := 0; var surfs := 0
	var keys: Array = parts.keys(); keys.sort()
	for c: Vector2i in keys:
		var holder := Node3D.new(); holder.name = "c_%d_%d" % [c.x, c.y]; root.add_child(holder)
		var am := ArrayMesh.new()
		var mats: Array = (parts[c] as Dictionary).keys(); mats.sort()
		for mp: String in mats:
			var b: PackedFloat32Array = parts[c][mp]
			var cnt := b.size() / 11
			var V := PackedVector3Array(); var N := PackedVector3Array(); var UV := PackedVector2Array(); var C := PackedColorArray()
			V.resize(cnt); N.resize(cnt); UV.resize(cnt); C.resize(cnt)
			for i in cnt:
				var o := i * 11
				V[i] = Vector3(b[o], b[o + 1], b[o + 2]); N[i] = Vector3(b[o + 3], b[o + 4], b[o + 5])
				UV[i] = Vector2(b[o + 6], b[o + 7]); C[i] = Color(b[o + 8], b[o + 9], b[o + 10], 1.0)
			var arr := []; arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_COLOR] = C
			var st := SurfaceTool.new(); st.create_from_arrays(arr); st.index(); st.generate_tangents()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
			am.surface_set_material(am.get_surface_count() - 1, load(mp))
			# (the surface's name is the ground's own name, as in every piece: the bake and the checks read it)
			am.surface_set_name(am.get_surface_count() - 1, mp.get_file().get_basename().trim_prefix("g_").trim_prefix("fill_"))
			tris += cnt / 3; surfs += 1
		var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = am
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; holder.add_child(mi)
		var body := StaticBody3D.new(); body.name = "ground_col"
		var cs := CollisionShape3D.new(); cs.shape = am.create_trimesh_shape(); body.add_child(cs); holder.add_child(body)
	print("HOLES fx_holes: ground tris %d, %d cells, %d surfaces" % [tris, keys.size(), surfs])
	K.save_piece(root, "fx_holes")
	root.free()
	quit()
