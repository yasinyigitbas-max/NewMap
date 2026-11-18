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
		var bodies := node.find_children("*", "StaticBody3D", true, false)
		var kinds := {}; var tris_all := 0; var worst := 0; var worst_name := ""; var per_body: Array = []; var shared := {}
		for b: Node in bodies:
			var bt := 0
			for cs: Node in b.get_children():
				if not (cs is CollisionShape3D) or (cs as CollisionShape3D).shape == null: continue
				var sh: Shape3D = (cs as CollisionShape3D).shape
				var kind := sh.get_class().replace("Shape3D", "")
				kinds[kind] = int(kinds.get(kind, 0)) + 1
				if sh is ConcavePolygonShape3D:
					var t := (sh as ConcavePolygonShape3D).get_faces().size() / 3
					bt += t
					if sh.resource_path != "" and not sh.resource_path.contains("::"): shared[sh.resource_path] = t
			tris_all += bt; per_body.append(bt)
			if bt > worst: worst = bt; worst_name = "%s (%d shapes)" % [b.name, b.get_child_count()]
		per_body.sort()
		var n := per_body.size()
		print("COL %s: bodies=%d shapes=%s | triangles in concave shapes: all=%d, per body median=%d p90=%d worst=%d in %s | concave shapes shared from lib=%d" % [k, n, str(kinds), tris_all, per_body[n / 2] if n > 0 else 0, per_body[int(n * 0.9)] if n > 0 else 0, worst, worst_name, shared.size()])
		node.free()
	quit()
