extends SceneTree
## Godot import check for the weapons batch: run in a throw-away project that holds assets/coronado_kit/props/weapons and
## assets/coronado_kit/atlases (see godot_check.sh). Loads every near glb, prints surfaces, triangles, material textures,
## AABB and the grip / muzzle markers. Prints WEAPONS_GODOT PASS|FAIL.

func _init() -> void:
	var dir := "res://assets/coronado_kit/props/weapons/"
	var fails := 0
	var n := 0
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with("_near.glb"):
			continue
		n += 1
		var ps := load(dir + f) as PackedScene
		if ps == null:
			print("FAIL load ", f); fails += 1; continue
		var root := ps.instantiate()
		var mis := root.find_children("*", "MeshInstance3D", true, false)
		if mis.size() != 1:
			print("FAIL ", f, " mesh instances ", mis.size()); fails += 1; continue
		var mi := mis[0] as MeshInstance3D
		var mesh := mi.mesh
		var tris := 0
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		var mat := mesh.surface_get_material(0) as StandardMaterial3D
		var tex_ok := mat != null and mat.albedo_texture != null and mat.normal_texture != null and mat.roughness_texture != null and mat.metallic_texture != null
		var marks := []
		for c in mi.get_children():
			marks.append("%s%s" % [c.name, (c as Node3D).position])
		print("WEAPON %s surfaces=%d tris=%d textures=%s aabb=%s marks=%s" % [f, mesh.get_surface_count(), tris, tex_ok, mesh.get_aabb(), marks])
		if mesh.get_surface_count() != 1 or not tex_ok:
			fails += 1
		root.free()
	print("WEAPONS_GODOT %s (%d models)" % ["PASS" if fails == 0 and n > 0 else "FAIL", n])
	quit(1 if fails else 0)
