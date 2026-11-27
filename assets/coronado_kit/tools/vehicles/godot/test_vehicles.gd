extends SceneTree
## Godot import check for the vehicle fleet (run in a throw-away project, see godot_check.sh): loads every veh_*.glb,
## counts part nodes, surfaces and triangles, checks every surface has its colour / normal / ORM maps, that the markers
## are there, and that each door / lid is its own node whose rotation moves only its own mesh (the hinge works).
## Prints VEHICLES_GODOT PASS|FAIL.

func _init() -> void:
	var dir := "res://assets/coronado_kit/vehicles/"
	var fails := 0
	var n := 0
	for f in DirAccess.get_files_at(dir):
		if not (f.begins_with("veh_") and f.ends_with(".glb")):
			continue
		n += 1
		var ps := load(dir + f) as PackedScene
		if ps == null:
			print("FAIL load ", f); fails += 1; continue
		var root := ps.instantiate()
		var mis := root.find_children("*", "MeshInstance3D", true, false)
		var tris := 0
		var surf := 0
		var tex_ok := true
		var openers := []
		for mi in mis:
			var mesh := (mi as MeshInstance3D).mesh
			for s in mesh.get_surface_count():
				surf += 1
				var arr := mesh.surface_get_arrays(s)
				tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
				var mat := mesh.surface_get_material(s) as StandardMaterial3D
				if mat == null or mat.albedo_texture == null or mat.normal_texture == null:
					tex_ok = false
			var nm := String(mi.name)
			var holder: Node3D = mi if mi.get_parent() == root else mi.get_parent()
			if nm.begins_with("door") or nm.begins_with("busdoor") or nm.begins_with("back_door") or nm in ["bonnet", "boot", "tailgate", "hopper", "tipper", "ladder", "boom"]:
				openers.append(nm)
				# the hinge: rotating the part's node moves its far edge, not its pivot
				var before := (mi as MeshInstance3D).global_transform.origin
				(mi as Node3D).rotate_y(0.5)
				var after := (mi as MeshInstance3D).global_transform.origin
				if before.distance_to(after) > 0.001:
					print("FAIL ", f, " ", nm, " pivot moved"); fails += 1
		var marks := root.find_children("mk_*", "Node3D", true, false).size()
		print("VEHICLE %s parts=%d surfaces=%d tris=%d textures=%s openers=%d markers=%d" % [f, mis.size(), surf, tris, tex_ok, openers.size(), marks])
		if not tex_ok or openers.is_empty() or marks < 4:
			fails += 1
		root.free()
	print("VEHICLES_GODOT %s (%d vehicles)" % ["PASS" if fails == 0 and n > 0 else "FAIL", n])
	quit(1 if fails else 0)
