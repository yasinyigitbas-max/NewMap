extends SceneTree
## Run: tools/city/run/checks.sh (or godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/sink_check.gd under xvfb-run). Prints SINK_DONE n.
## sunk / floating ground props on street pieces: each prop's base y vs the piece's own ground surface under it
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var names: Array = []
	for f in DirAccess.get_files_at("res://map_dc/coronado/city_kit/pieces/"):
		if f.ends_with(".scn") and (f.begins_with("j_") or f.begins_with("s_")): names.append(f.get_basename())
	names.sort()
	var bad := 0; var counts := {}
	for nm: String in names:
		var root: Node3D = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % nm) as PackedScene).instantiate()
		get_root().add_child(root)
		var tris: Array = []
		for gm: MeshInstance3D in root.find_children("ground", "MeshInstance3D", true, false):
			var m := gm.mesh as ArrayMesh
			for si in m.get_surface_count():
				var arr := m.surface_get_arrays(si)
				var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ix = arr[Mesh.ARRAY_INDEX]
				var n: int = (ix as PackedInt32Array).size() if ix != null else vv.size()
				for k in range(0, n, 3):
					var a: Vector3 = vv[ix[k] if ix != null else k]; var b: Vector3 = vv[ix[k + 1] if ix != null else k + 1]; var c: Vector3 = vv[ix[k + 2] if ix != null else k + 2]
					if absf((b - a).cross(c - a).normalized().y) < 0.3: continue      # kerb faces / walls
					tris.append([a, b, c])
		for mmi: MultiMeshInstance3D in root.find_children("*_near", "MultiMeshInstance3D", true, false):
			var nm2 := String(mmi.name).trim_suffix("_near"); var base := nm2.substr(0, nm2.rfind("_"))
			var e := K.manifest(base)
			if String(e.get("mount", "ground")) != "ground": continue
			if base.contains("manhole") or base.contains("storm_drain"): continue
			var mm := mmi.multimesh
			for i in mm.instance_count:
				var t: Transform3D = _local(mmi, root) * mm.get_instance_transform(i)
				var p := t.origin
				var best := -INF
				for tr: Array in tris:
					var a2: Vector3 = tr[0]; var b2: Vector3 = tr[1]; var c2: Vector3 = tr[2]
					if not Geometry2D.point_is_inside_triangle(Vector2(p.x, p.z), Vector2(a2.x, a2.z), Vector2(b2.x, b2.z), Vector2(c2.x, c2.z)): continue
					var hit = Plane(a2, b2, c2).intersects_ray(Vector3(p.x, 1000.0, p.z), Vector3.DOWN)
					if hit != null: best = maxf(best, (hit as Vector3).y)
				if best == -INF: continue
				var d := p.y - best
				var tree := base.begins_with("tree_") or base.begins_with("palm_")
				var lo := -0.12 if tree else -0.04
				if d < lo or d > 0.12:
					bad += 1; counts[nm.substr(0, 4)] = int(counts.get(nm.substr(0, 4), 0)) + 1
					if bad <= 60: print("SINK %s %s at (%.1f, %.1f): base %.2f m %s the ground" % [nm, base, p.x, p.z, absf(d), "below" if d < 0 else "above"])
		root.queue_free()
		await process_frame
	print("SINK_DONE %d props off the ground, by piece prefix %s" % [bad, counts])
	quit()
func _local(n: Node3D, root: Node) -> Transform3D:
	var t := n.transform; var p := n.get_parent()
	while p != root and p is Node3D: t = (p as Node3D).transform * t; p = p.get_parent()
	return t
