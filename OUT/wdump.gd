extends SceneTree
## west fill dump (reads only): every n_w_* piece's props (base, world position) and buildings (world AABB on the ground)
func _init() -> void: _r.call_deferred()
func _r() -> void:
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://OUT/area/w_layout.json")).instances
	var out := {"props": [], "blds": []}
	for r: Dictionary in rows:
		var p: Array = r.pos
		var n: Node3D = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % r.piece) as PackedScene).instantiate()
		n.position = Vector3(float(p[0]), float(p[1]), float(p[2])); root.add_child(n)
		for b: Node in n.get_node("Buildings").get_children():
			var ab := AABB(); var first := true
			for mi: VisualInstance3D in b.find_children("*", "VisualInstance3D", true, false):
				if String(mi.name) != "near" and String(mi.name) != "col": continue
				var a := mi.global_transform * mi.get_aabb()
				if first: ab = a; first = false
				else: ab = ab.merge(a)
			out.blds.append([String(r.piece), String(b.name), ab.position.x, ab.position.z, ab.end.x, ab.end.z])
		var seen := {}
		for mmi: MultiMeshInstance3D in n.find_children("*", "MultiMeshInstance3D", true, false):
			var nm := String(mmi.name)
			for i in mmi.multimesh.instance_count:
				var o := (mmi.global_transform * mmi.multimesh.get_instance_transform(i)).origin
				var k := "%s|%.1f|%.1f" % [nm.get_slice("_near", 0).get_slice("_mid", 0).get_slice("_far", 0), o.x, o.z]
				if seen.has(k): continue
				seen[k] = true
				out.props.append([String(r.piece), nm, o.x, o.y, o.z])
		n.queue_free()
		await process_frame
	var f := FileAccess.open("res://OUT/area/w_dump.json", FileAccess.WRITE); f.store_string(JSON.stringify(out)); f.close()
	print("WDUMP props %d buildings %d" % [out.props.size(), out.blds.size()])
	quit()
