extends SceneTree
## Room merge for the phone (18 Nov, rooms on all shops; PROTOTYPE): a room scene (interiors/rooms/*.scn) costs 30-40
## draws (one per shell material, one per kit prop type). This writes a merged copy to city_kit/runtime/rooms/ (derived,
## not in git) with:
##   - every kit prop in ONE mesh with the city bake's own merged prop material (runtime/lib/mat_prop_merged_near.tres:
##     the kit's prop pages, the indoor page among them, are layers of runtime_tex/arr_prop_*; per prop: page, wear,
##     normal / ORM flags in CUSTOM0, exactly as bake_runtime.gd _merge writes them), two-sided props in a second one;
##   - the shell (walls, floors, ceilings, fittings) in ONE mesh (tools/city/rooms/rt_room_shell.gdshader, the room
##     textures as layers of runtime_tex/arr_room.png); the clear glass, door leaves, signs, wear and potted plants as
##     they are. Lights unchanged.
## Needs the runtime bake (runtime/lib) and tools/city/rooms/make_room_array.py + an import first.
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/rooms/room_merge.gd [-- --only=name,name]
const DIR := "res://map_dc/coronado/city_kit/interiors/rooms/"
const OUT := "res://map_dc/coronado/city_kit/runtime/rooms/"
const LIB := "res://map_dc/coronado/city_kit/runtime/lib/"
const TEXD := "res://map_dc/coronado/city_kit/runtime_tex/"
var prop_pages: Array = []
var room_layers: Array = []
var shell_mat: ShaderMaterial

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="): only = a.trim_prefix("--only=").split(",", false)
	prop_pages = JSON.parse_string(FileAccess.get_file_as_string(TEXD + "arrays.json")).prop_albedo
	room_layers = JSON.parse_string(FileAccess.get_file_as_string(TEXD + "arr_room.json")).layers
	shell_mat = ShaderMaterial.new(); shell_mat.shader = load("res://tools/city/rooms/rt_room_shell.gdshader")
	shell_mat.set_shader_parameter(&"room_arr", load(TEXD + "arr_room.png"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	ResourceSaver.save(shell_mat, OUT + "mat_room_shell.tres"); shell_mat = load(OUT + "mat_room_shell.tres")
	var tot := [0, 0, 0]
	var rows: Array = []
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".scn"): continue
		var nm := f.get_basename()
		if not only.is_empty() and not only.has(nm): continue
		var src: Node3D = (load(DIR + f) as PackedScene).instantiate()
		var before := _draws(src)
		var dst := _merge_room(src)
		var after := _draws(dst)
		# (20 Nov, B14) no GDScript in the game's rooms: the door leaves' door_swing.gd is dropped (not in the phone build;
		# C++ CityRooms swings them from the leaves' own metas mid / out_dir / open_sign)
		for lf: Node in dst.find_children("DoorLeaf_*", "Node3D", true, false): lf.set_script(null)
		var ps := PackedScene.new(); _own(dst, dst); ps.pack(dst)
		ResourceSaver.save(ps, OUT + f, ResourceSaver.FLAG_COMPRESS)
		tot[0] += 1; tot[1] += before; tot[2] += after
		rows.append([nm, before, after])
		print("MERGE %s draws %d -> %d" % [nm, before, after])
		src.free(); dst.free()
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[2] > b[2])
	print("MERGE_DONE rooms=%d draws %d -> %d (a room: %.1f -> %.1f); heaviest after: %s" % [tot[0], tot[1], tot[2], float(tot[1]) / maxf(1, tot[0]), float(tot[2]) / maxf(1, tot[0]), str(rows.slice(0, 3))])
	quit()

func _own(n: Node, owner_n: Node) -> void:
	for c in n.get_children():
		c.owner = owner_n; _own(c, owner_n)

## draws of a room: one per surface of every mesh / multimesh
func _draws(n: Node) -> int:
	var d := 0
	for gi: GeometryInstance3D in n.find_children("*", "GeometryInstance3D", true, false):
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh: d += (gi as MeshInstance3D).mesh.get_surface_count()
		elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh and (gi as MultiMeshInstance3D).multimesh.mesh: d += (gi as MultiMeshInstance3D).multimesh.mesh.get_surface_count()
	return d

func _merge_room(src: Node3D) -> Node3D:
	var dst: Node3D = src.duplicate()
	# ---- props
	var pn := dst.get_node_or_null("Props")
	if pn:
		var groups := {"one": [], "two": []}
		for mmi: MultiMeshInstance3D in pn.get_children():
			var mm := mmi.multimesh
			if mm == null or mm.mesh == null or mm.mesh.get_surface_count() != 1: continue
			var mt: Material = mmi.material_override if mmi.material_override else mm.mesh.surface_get_material(0)
			if not (mt is ShaderMaterial): continue
			var sm := mt as ShaderMaterial
			var sh := String(sm.shader.resource_path).get_file()
			if not (sh in ["prop_wear_fix.gdshader", "prop_wear_fix_2s.gdshader"]): continue
			var at: Texture2D = sm.get_shader_parameter(&"albedo_tex")
			var page := prop_pages.find(at.resource_path) if at else -1
			if page < 0: continue
			var flags := (1.0 if sm.get_shader_parameter(&"normal_tex") != null else 0.0) + (2.0 if sm.get_shader_parameter(&"orm_tex") != null else 0.0)
			var wear := float(sm.get_shader_parameter(&"wear"))
			var g: Array = groups["two" if sh.ends_with("_2s.gdshader") else "one"]
			for i in mm.instance_count: g.append([mm.mesh, mmi.transform * mm.get_instance_transform(i), wear, float(page), flags])
			mmi.free()
		for k: String in groups:
			var items: Array = groups[k]
			if items.is_empty(): continue
			var tang := false
			for it: Array in items:
				if int(it[4]) & 1: tang = true
			var am := _merge(items, tang)
			var mi := MeshInstance3D.new(); mi.name = "props_" + k; mi.mesh = am
			mi.material_override = load(LIB + ("mat_prop_2s_merged_near.tres" if k == "two" else "mat_prop_merged_near.tres"))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_end = 62.0; mi.visibility_range_end_margin = 2.0
			pn.add_child(mi)
	# ---- shell
	var shell := dst.get_node_or_null("shell") as MeshInstance3D
	if shell and shell.mesh:
		var V := PackedVector3Array(); var N := PackedVector3Array(); var UV := PackedVector2Array(); var U2 := PackedVector2Array(); var C := PackedColorArray(); var I := PackedInt32Array()
		var keep := ArrayMesh.new()
		for si in shell.mesh.get_surface_count():
			var m := shell.mesh.surface_get_material(si)
			var a := shell.mesh.surface_get_arrays(si)
			var lay := -1; var col := Color.WHITE; var emit := 0.0; var rough := 0.8
			if m is StandardMaterial3D and (m as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
				var s3 := m as StandardMaterial3D
				col = s3.albedo_color.srgb_to_linear(); rough = s3.roughness
				if s3.emission_enabled: emit = s3.emission_energy_multiplier
				if s3.albedo_texture == null: lay = 0
				else:
					var p := s3.albedo_texture.resource_path
					lay = room_layers.find("pave" if p.contains("concrete034") else p.get_file().get_slice("_", 0))
			if lay < 0:
				keep.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a); keep.surface_set_material(keep.get_surface_count() - 1, m); continue
			var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var base := V.size(); var n := v.size()
			V.append_array(v); N.append_array(a[Mesh.ARRAY_NORMAL]); UV.append_array(a[Mesh.ARRAY_TEX_UV])
			var u2 := PackedVector2Array(); u2.resize(n); u2.fill(Vector2(float(lay), emit)); U2.append_array(u2)
			var cc := PackedColorArray(); cc.resize(n); cc.fill(Color(col.r, col.g, col.b, rough)); C.append_array(cc)
			var idx: Variant = a[Mesh.ARRAY_INDEX]
			if idx != null:
				for ix: int in (idx as PackedInt32Array): I.append(ix + base)
			else:
				for k2 in n: I.append(base + k2)
		var arr := []; arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_TEX_UV2] = U2; arr[Mesh.ARRAY_COLOR] = C; arr[Mesh.ARRAY_INDEX] = I
		var sm2 := ArrayMesh.new(); sm2.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr); sm2.surface_set_material(0, shell_mat)
		var mi2 := MeshInstance3D.new(); mi2.name = "shell_merged"; mi2.mesh = sm2; mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi2.visibility_range_end = shell.visibility_range_end; mi2.visibility_range_end_margin = 2.0
		dst.add_child(mi2)
		if keep.get_surface_count() > 0:
			shell.mesh = keep
		else:
			shell.free()
	return dst

## as bake_runtime.gd _merge: vertices in the room's frame, CUSTOM0 = the prop's origin + page * 16 + flags * 2 + wear
func _merge(items: Array, tangents: bool) -> ArrayMesh:
	var V := PackedVector3Array(); var N := PackedVector3Array(); var T := PackedFloat32Array(); var UV := PackedVector2Array(); var C := PackedColorArray(); var CU := PackedByteArray(); var I := PackedInt32Array()
	for it: Array in items:
		var mesh: Mesh = it[0]; var a := mesh.surface_get_arrays(0); var xf: Transform3D = it[1]
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var n := v.size(); var base := V.size()
		var nb := Transform3D(xf.basis.orthonormalized(), Vector3.ZERO)
		V.append_array(xf * v)
		if a[Mesh.ARRAY_NORMAL] != null: N.append_array(nb * (a[Mesh.ARRAY_NORMAL] as PackedVector3Array))
		else:
			var nn := PackedVector3Array(); nn.resize(n); nn.fill(Vector3.UP); N.append_array(nn)
		if a[Mesh.ARRAY_TEX_UV] != null: UV.append_array(a[Mesh.ARRAY_TEX_UV])
		else:
			var uu := PackedVector2Array(); uu.resize(n); UV.append_array(uu)
		if a[Mesh.ARRAY_COLOR] != null: C.append_array(a[Mesh.ARRAY_COLOR])
		else:
			var w := PackedColorArray(); w.resize(n); w.fill(Color.WHITE); C.append_array(w)
		if tangents:
			if a[Mesh.ARRAY_TANGENT] != null:
				var t: PackedFloat32Array = a[Mesh.ARRAY_TANGENT]
				for k in n:
					var tv := nb.basis * Vector3(t[k * 4], t[k * 4 + 1], t[k * 4 + 2])
					T.append(tv.x); T.append(tv.y); T.append(tv.z); T.append(t[k * 4 + 3])
			else:
				for k in n: T.append(1.0); T.append(0.0); T.append(0.0); T.append(1.0)
		var o := xf.origin
		var cu := PackedByteArray(); cu.resize(8)
		cu.encode_half(0, o.x); cu.encode_half(2, o.y); cu.encode_half(4, o.z); cu.encode_half(6, float(it[3]) * 16.0 + float(it[4]) * 2.0 + float(it[2]))
		while cu.size() < n * 8: cu.append_array(cu)
		cu.resize(n * 8); CU.append_array(cu)
		if a[Mesh.ARRAY_INDEX] != null:
			for ix: int in (a[Mesh.ARRAY_INDEX] as PackedInt32Array): I.append(ix + base)
		else:
			for k in n: I.append(base + k)
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_COLOR] = C; arr[Mesh.ARRAY_CUSTOM0] = CU; arr[Mesh.ARRAY_INDEX] = I
	if tangents: arr[Mesh.ARRAY_TANGENT] = T
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, Mesh.ARRAY_CUSTOM_RGBA_HALF << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	return am
