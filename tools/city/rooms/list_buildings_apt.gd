extends SceneTree
## The apartment fill's buildings (claude/fill-apartments): every kit building of the n_apt_* pieces listed in
## map_dc/coronado/city_kit/review/grow_apt_blocks.json, with its piece, label, model and transform in the GRID frame
## (the layout row's pos / yaw applied) -> map_dc/coronado/city_kit/interiors/apt_buildings.json. Reads only.
##   xvfb-run -a godot --path . --rendering-method mobile -s res://tools/city/rooms/list_buildings_apt.gd
func _init() -> void:
	var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/review/grow_apt_blocks.json"))
	var out: Array = []
	for r: Dictionary in t.rows:
		var piece := String(r.piece)
		var sc: Node3D = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % piece) as PackedScene).instantiate()
		var p: Array = r.pos
		var row := Transform3D(Basis(Vector3.UP, deg_to_rad(float(r.yaw))), Vector3(float(p[0]), float(p[1]), float(p[2])))
		var bn := sc.get_node_or_null("Buildings")
		if bn:
			for b: Node in bn.get_children():
				if not b.has_meta(&"kit"): continue
				var xf: Transform3D = row * (b as Node3D).transform
				out.append({"piece": piece, "label": String(b.name), "model": String(b.get_meta(&"kit")),
					"pos": [xf.origin.x, xf.origin.y, xf.origin.z], "yaw": rad_to_deg(xf.basis.get_euler().y)})
		sc.free()
	var fo := FileAccess.open("res://map_dc/coronado/city_kit/interiors/apt_buildings.json", FileAccess.WRITE)
	fo.store_string(JSON.stringify({"_doc": "the apartment fill's kit buildings (tools/city/rooms/list_buildings_apt.gd): piece, label, model, grid-frame position, yaw", "buildings": out}, " ")); fo.close()
	print("LIST apt buildings=%d" % out.size())
	quit()
