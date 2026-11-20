extends SceneTree
## Dump the meshes of tier scenes (.scn / .glb) as raw arrays for tools/city/lod (no GPU needed there).
## usage: godot --headless --path . -s res://tools/city/lod/dump_mesh.gd -- OUTDIR res://a_near.scn res://b_far.scn ...
## Writes OUTDIR/<file basename>.bin (float32: P xyz, N xyz, UV uv, C rgba per vertex; then int32 indices) + .json.
func _init() -> void:
	var args := OS.get_cmdline_user_args(); var out := args[0]
	DirAccess.make_dir_recursive_absolute(out)
	for i in range(1, args.size()):
		var p := args[i]; var ps: PackedScene = load(p)
		if ps == null: print("FAIL ", p); continue
		var n := ps.instantiate(); var mi := _first(n)
		if mi == null or mi.mesh == null: print("NOMESH ", p); n.free(); continue
		var m := mi.mesh; var meta := {"src": p, "surfaces": [], "xf": _xf(mi.transform)}
		var f := FileAccess.open(out.path_join(p.get_file().get_basename() + ".bin"), FileAccess.WRITE)
		for s in m.get_surface_count():
			var a := m.surface_get_arrays(s)
			var V: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var nv := V.size()
			var N: PackedVector3Array = a[Mesh.ARRAY_NORMAL] if a[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var UV: PackedVector2Array = a[Mesh.ARRAY_TEX_UV] if a[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			var C: PackedColorArray = a[Mesh.ARRAY_COLOR] if a[Mesh.ARRAY_COLOR] != null else PackedColorArray()
			var I: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(nv))
			var fl := PackedFloat32Array()
			for k in nv:
				var v := V[k]; fl.append_array([v.x, v.y, v.z])
				var nn := N[k] if N.size() == nv else Vector3.UP; fl.append_array([nn.x, nn.y, nn.z])
				var u := UV[k] if UV.size() == nv else Vector2.ZERO; fl.append_array([u.x, u.y])
				var c := C[k] if C.size() == nv else Color.WHITE; fl.append_array([c.r, c.g, c.b, c.a])
			f.store_buffer(fl.to_byte_array()); f.store_buffer(I.to_byte_array())
			var mat: Material = mi.get_surface_override_material(s) if mi.get_surface_override_material(s) else m.surface_get_material(s)
			var alb := ""; var orm := ""
			if mat is BaseMaterial3D:
				if (mat as BaseMaterial3D).albedo_texture: alb = (mat as BaseMaterial3D).albedo_texture.resource_path
				if (mat as BaseMaterial3D).orm_texture: orm = (mat as BaseMaterial3D).orm_texture.resource_path
				elif (mat as BaseMaterial3D).roughness_texture: orm = (mat as BaseMaterial3D).roughness_texture.resource_path
			elif mat is ShaderMaterial:
				var t: Variant = (mat as ShaderMaterial).get_shader_parameter(&"albedo_tex")
				if t is Texture2D: alb = (t as Texture2D).resource_path
			meta.surfaces.append({"nv": nv, "ni": I.size(), "albedo": alb, "orm": orm, "mat": mat.resource_path if mat else ""})
		f.close()
		var j := FileAccess.open(out.path_join(p.get_file().get_basename() + ".json"), FileAccess.WRITE); j.store_string(JSON.stringify(meta, " ")); j.close()
		n.free()
	print("dumped ", args.size() - 1)
	quit()

func _xf(t: Transform3D) -> Array:
	return [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z, t.origin.x, t.origin.y, t.origin.z]

func _first(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _first(c)
		if r: return r
	return null
