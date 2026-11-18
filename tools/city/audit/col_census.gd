extends SceneTree
## Collision census of baked cells (read-only): how many bodies a cell brings, of what shapes, how many triangles.
## The phone runs of 18 Nov put most hitches on frames that attach collision bodies; a concave (triangle) shape is
## built by the physics engine when it first enters the world, and that costs by the triangle.
##   godot --headless --path . -s res://tools/city/audit/col_census.gd -- 0_-3 1_-3 -1_-3
func _init() -> void:
	var keys: PackedStringArray = OS.get_cmdline_user_args()
	if keys.is_empty(): keys = ["0_-3", "1_-3", "-1_-3", "-3_-5", "2_-6", "-4_-7", "0_0", "2_0", "3_-3"]
	for k in keys:
		var path := "res://map_dc/coronado/city_kit/runtime/cells/cell_%s.scn" % k
		if not ResourceLoader.exists(path): print("COL %s: no such cell" % k); continue
		var node: Node = (load(path) as PackedScene).instantiate()
		# since 18 Nov a body is a plain Node3D with its shapes as data (bake_runtime.gd _col_marker, col_data.gd)
		var kinds := {}; var w_all := 0; var worst := 0; var worst_name := ""; var per_body: Array = []; var n := 0
		for b: Node in node.find_children("col*", "Node3D", true, false):
			if not b.has_meta(&"col"): continue
			n += 1
			var bw := 0
			for it: Array in b.get_meta(&"col"):
				var kind: String = ["triangles", "convex", "box"][int((it[0] as Resource).get(&"kind"))]
				kinds[kind] = int(kinds.get(kind, 0)) + 1
				bw += int((it[0] as Resource).call(&"weight"))
			w_all += bw; per_body.append(bw)
			if bw > worst: worst = bw; worst_name = "%s (%d shapes)" % [b.name, (b.get_meta(&"col") as Array).size()]
		per_body.sort()
		print("COL %s: bodies=%d shapes=%s | weight (triangles + convex points): all=%d, per body median=%d p90=%d worst=%d in %s" % [k, n, str(kinds), w_all, per_body[n / 2] if n > 0 else 0, per_body[int(n * 0.9)] if n > 0 else 0, worst, worst_name])
		node.free()
	quit()
