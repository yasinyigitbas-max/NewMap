extends SceneTree
## THE FILL's pieces (21 Nov; tools/city/fill/make_fill.py writes their data, this turns it into pieces/fl_*.scn).
## Per piece: "ground" (one mesh, a surface per g_fill_* material, vertex tint, smooth normals), "ground_col" (its
## triangles), the lagoons' still water ("pond_<id>": the sea's own shader; the look swaps in the live sea material, see
## look.gd _restyle), and the props (K.Props: the kit's tiers and colliders). Writes nothing else.
##   godot --headless --path . -s res://tools/city/fill/build_fill.gd [-- --only=fl_m6_m7,...]
const K := preload("res://tools/city/pilot/kit_lib.gd")
const DIR := "res://OUT/fill/pieces/"
const MAT_DIR := "res://map_dc/coronado/city_kit/materials/"
const MATS := {
	"lawn": ["res://map_dc/coronado/terrain/textures/grass004/grass_albedo.jpg", 0.95, Color(0.85, 0.95, 0.8)],
	"meadow": ["res://map_dc/coronado/terrain/textures/ground037/dry_albedo.jpg", 0.97, Color(0.95, 0.97, 0.86)],
	"sand": ["res://map_dc/coronado/terrain/textures/ground054/sand_albedo.jpg", 0.97, Color(0.93, 0.87, 0.74)],
	"cobble": ["res://map_dc/coronado/terrain/textures/gray_rocks/gray_rocks_diff_1k.jpg", 0.9, Color(0.86, 0.84, 0.8)],
	"rock": ["res://map_dc/coronado/terrain/textures/rock030/rock_albedo.jpg", 0.92, Color(0.82, 0.78, 0.72)],
	"trail": ["res://map_dc/coronado/terrain/textures/gravel022/gravel_albedo.jpg", 0.95, Color(0.97, 0.86, 0.7)],
}

func _init() -> void: _run.call_deferred()

func _mat(m: String) -> Material:
	var path := MAT_DIR + "g_fill_%s.tres" % m
	if ResourceLoader.exists(path): return load(path)
	var d: Array = MATS[m]
	var sm := StandardMaterial3D.new()
	sm.albedo_texture = load(d[0]); sm.albedo_color = d[2]; sm.roughness = d[1]
	sm.vertex_color_use_as_albedo = true
	sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	ResourceSaver.save(sm, path)
	return load(path)

func _water() -> Material:
	var path := MAT_DIR + "fill_pond_water.tres"
	if ResourceLoader.exists(path): return load(path)
	var m := ShaderMaterial.new(); m.shader = load("res://tools/city/look/sea.gdshader")
	m.set_shader_parameter("ripple_tex", load("res://tools/city/look/sky_noise.png"))
	ResourceSaver.save(m, path)
	return load(path)

func _run() -> void:
	var only: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="): only = Array(a.trim_prefix("--only=").split(",", false))
	var idx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "index.json"))
	var unknown := {}
	var n_done := 0
	for name: String in idx.pieces:
		if not only.is_empty() and not (name in only): continue
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + name + ".json"))
		var raw := FileAccess.get_file_as_bytes(DIR + name + ".bin").to_float32_array()
		var root := Node3D.new(); root.name = name
		var am := ArrayMesh.new()
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
			var st := SurfaceTool.new(); st.create_from_arrays(arr); st.index()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
			am.surface_set_material(am.get_surface_count() - 1, _mat(String(s.mat)))
			am.surface_set_name(am.get_surface_count() - 1, String(s.mat))
		var mi := MeshInstance3D.new(); mi.name = "ground"; mi.mesh = am
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(mi)
		var body := StaticBody3D.new(); body.name = "ground_col"
		var cs := CollisionShape3D.new(); cs.shape = am.create_trimesh_shape(); body.add_child(cs); root.add_child(body)
		for p: Dictionary in meta.ponds:
			var poly := PackedVector2Array()
			for q: Array in p.poly: poly.append(Vector2(float(q[0]), float(q[1])))
			if poly.size() > 3 and poly[0].is_equal_approx(poly[poly.size() - 1]): poly.remove_at(poly.size() - 1)
			var tri := Geometry2D.triangulate_polygon(poly)
			if tri.is_empty(): continue
			var st2 := SurfaceTool.new(); st2.begin(Mesh.PRIMITIVE_TRIANGLES)
			var lvl := float(p.level)
			for k in range(0, tri.size(), 3):
				# face up whatever the outline's direction (Godot's front face: (b-a)x(c-a) points down seen from above)
				var a2 := poly[tri[k]]; var b2 := poly[tri[k + 1]]; var c2 := poly[tri[k + 2]]
				var cy := (b2.y - a2.y) * (c2.x - a2.x) - (b2.x - a2.x) * (c2.y - a2.y)      # y of (b-a)x(c-a) in x,z
				for m: int in ([0, 2, 1] if cy > 0.0 else [0, 1, 2]):
					var q := poly[tri[k + m]]
					st2.set_color(Color(0.035, 0, 0, 1)); st2.set_normal(Vector3.UP); st2.add_vertex(Vector3(q.x, lvl, q.y))
			var wm := MeshInstance3D.new(); wm.name = "pond_%d" % int(p.id); wm.mesh = st2.commit()
			wm.material_override = _water(); wm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(wm)
		var props := K.Props.new()
		for e: Array in meta.props:
			var base := String(e[0])
			if K.manifest(base).is_empty(): unknown[base] = int(unknown.get(base, 0)) + 1; continue
			props.add(base, String(e[1]), Vector3(float(e[2]), float(e[3]), float(e[4])), float(e[5]), bool(e[6]), float(e[7]))
		if props.count() > 0: props.build(root, K)
		print("FILL %s: ground tris %d, surfaces %d, ponds %d, props %d" % [name, int(meta.tris), am.get_surface_count(), meta.ponds.size(), props.count()])
		K.save_piece(root, name)
		root.free()
		n_done += 1
	print("FILL built %d pieces; unknown prop bases: %s" % [n_done, str(unknown)])
	quit()
