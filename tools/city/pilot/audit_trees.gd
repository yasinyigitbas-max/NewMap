extends SceneTree
## Audit (Yasin 16 Nov: "are all trees in cement in tree wells now?"): for every tree / palm in the layout, find the
## ground surface under its trunk (topmost ground triangle of any piece at that x, z). A trunk is fine on grass,
## mulch (a well's soil or a bed), gravel, or on nothing (open ground outside the pieces); it is a problem on
## concrete, paving, asphalt or paint. Prints one line per problem and "TREES n checked, m in hard ground".
## Run with the real renderer (MultiMesh data): godot --path PV -s res://tools/city/pilot/audit_trees.gd
const K := preload("res://tools/city/pilot/kit_lib.gd")
const SOFT := ["grass", "mulch", "gravel", "sand"]
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var world := Node3D.new(); root.add_child(world)
	var nodes := K.place_layout(world, ["w_power", "w_ind", "w_strip", "w_apt"])
	var tris: Array = []      # [material, a, b, c (Vector3 world)]
	for n: Node3D in nodes:
		var g := n.get_node_or_null("ground") as MeshInstance3D
		if g == null: continue
		var xf := g.global_transform
		for si in g.mesh.get_surface_count():
			var mat: String = g.mesh.surface_get_name(si)
			var arr: Array = g.mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for k in range(0, idx.size(), 3):
				tris.append([mat, xf * v[idx[k]], xf * v[idx[k + 1]], xf * v[idx[k + 2]]])
	var bad := 0; var total := 0
	for n: Node3D in nodes:
		for mmi: MultiMeshInstance3D in n.find_children("*_near", "MultiMeshInstance3D", true, false):
			var nm := String(mmi.name)
			if not (nm.begins_with("tree_") or nm.begins_with("palm_")): continue
			for i in mmi.multimesh.instance_count:
				var p := (mmi.global_transform * mmi.multimesh.get_instance_transform(i)).origin
				total += 1
				var best := ""; var by := -1e9
				var q := Vector2(p.x, p.z)
				for t: Array in tris:
					var a: Vector3 = t[1]; var b: Vector3 = t[2]; var c: Vector3 = t[3]
					var a2 := Vector2(a.x, a.z); var b2 := Vector2(b.x, b.z); var c2 := Vector2(c.x, c.z)
					if absf((b2 - a2).cross(c2 - a2)) < 1e-4: continue     # vertical faces (kerbs, well rims): not ground
					if not Geometry2D.point_is_inside_triangle(q, a2, b2, c2): continue
					var y := maxf(a.y, maxf(b.y, c.y))
					if y > by: by = y; best = String(t[0])
				if best != "" and not (best in SOFT):
					bad += 1
					print("TREE-HARD %s %s at (%.1f, %.1f) stands on %s" % [n.get_meta(&"piece", n.name), nm.trim_suffix("_near"), p.x, p.z, best])
	print("TREES %d checked, %d in hard ground" % [total, bad])
	quit()
