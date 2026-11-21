extends SceneTree
## Measures only (ferry landing work, 21 Nov): the ground mesh vertices of the listed pieces (layout pos applied)
## inside a box; prints the min v (north edge) and heights there. -- --pieces=a,b --box=u0,v0,u1,v1
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var pieces: Array = []; var box := [0.0, 0.0, 0.0, 0.0]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pieces="): pieces = a.trim_prefix("--pieces=").split(",")
		elif a.begins_with("--box="): box = Array(a.trim_prefix("--box=").split(",")).map(func(x: String) -> float: return float(x))
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/city_grid_layout.json"))
	for p: String in pieces:
		var pos := Vector3.ZERO
		for r: Dictionary in lay.instances:
			if String(r.piece) == p: pos = Vector3(float(r.pos[0]), float(r.pos[1]), float(r.pos[2]))
		var inst: Node = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % p) as PackedScene).instantiate()
		var gm: MeshInstance3D = inst.get_node_or_null("ground")
		if gm == null: print("EDGE %s no ground" % p); continue
		var pts := {}
		for si in gm.mesh.get_surface_count():
			var arr := gm.mesh.surface_get_arrays(si)
			for v: Vector3 in arr[Mesh.ARRAY_VERTEX]:
				var w := v + pos
				if w.x >= box[0] and w.x <= box[2] and w.z >= box[1] and w.z <= box[3]:
					var k := "%.1f,%.2f" % [w.x, w.z]
					pts[k] = maxf(float(pts.get(k, -99.0)), w.y)
		var ks: Array = pts.keys(); ks.sort()
		var out := []
		for k: String in ks: out.append("%s:%.3f" % [k, float(pts[k])])
		print("EDGE %s pos %s n=%d :: %s" % [p, str(pos), ks.size(), " ".join(out.slice(0, 400))])
		inst.free()
	quit()
