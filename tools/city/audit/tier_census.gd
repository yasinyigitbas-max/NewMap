extends SceneTree
## The building tiers as baked (Yasin, 21 Nov: "im pretty confident that our mid tiers never show up in game and instead
## we are seeing far snap directly into near, skipping middle"):
##   godot --headless --path . -s res://tools/city/audit/tier_census.gd [-- --cell=cell_0_0]
## Per cell: how many building meshes are named near / mid, their node visibility ranges and shader windows (ck_win),
## and whether a mid shares its mesh with the near (then it looks like the near) or has its own.

func _initialize() -> void:
	var dir := "res://map_dc/coronado/city_kit/runtime/cells/"
	var only := ""
	for a in OS.get_cmdline_user_args(): if a.begins_with("--cell="): only = a.substr(7)
	var tot := {}
	var ranges := {}
	var same_mesh := 0
	var mid_tris := 0; var near_tris := 0
	var shown := 0
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".scn"): continue
		if only != "" and f.get_basename() != only: continue
		var ps: PackedScene = load(dir + f)
		if ps == null: continue
		var root := ps.instantiate()
		var by_parent := {}
		for n in root.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			var nm := String(mi.name)
			if not (nm in ["near", "mid", "far"]): continue
			tot[nm] = int(tot.get(nm, 0)) + 1
			var win: Variant = mi.get_instance_shader_parameter(&"ck_win")
			var rk := "%s vr %.0f..%.0f win %s mat %s" % [nm, mi.visibility_range_begin, mi.visibility_range_end, str(win), (mi.get_surface_override_material(0).resource_path.get_file() if mi.get_surface_override_material(0) else "-")]
			ranges[rk] = int(ranges.get(rk, 0)) + 1
			var p := mi.get_parent()
			if not by_parent.has(p): by_parent[p] = {}
			by_parent[p][nm] = mi
			var tris := 0
			if mi.mesh: for s in mi.mesh.get_surface_count(): tris += mi.mesh.surface_get_array_index_len(s) / 3
			if nm == "mid": mid_tris += tris
			if nm == "near": near_tris += tris
		for p in by_parent:
			var d: Dictionary = by_parent[p]
			if d.has("near") and d.has("mid") and (d.near as MeshInstance3D).mesh == (d.mid as MeshInstance3D).mesh: same_mesh += 1
			if shown < 4 and d.has("mid"):
				shown += 1
				print("TIERS   e.g. %s: %s" % [String((p as Node).name), ", ".join(d.keys())])
		root.free()
	print("TIERS   counts: %s" % str(tot))
	for k in ranges: print("TIERS   %5d  %s" % [ranges[k], k])
	print("TIERS   mids sharing the near's mesh: %d; triangles near %d, mid %d" % [same_mesh, near_tris, mid_tris])
	quit()
