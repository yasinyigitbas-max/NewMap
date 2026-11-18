extends SceneTree
## Every kit building of the baked city (city_kit/runtime/cells) with its piece, label, model and world transform
## -> map_dc/coronado/city_kit/interiors/all_buildings.json. Read-only: the cells are derived from the locked pieces.
## godot --headless --path . -s res://tools/city/rooms/list_buildings.gd
func _init() -> void:
	var d := "res://map_dc/coronado/city_kit/runtime/cells/"
	var out: Array = []
	for f in DirAccess.get_files_at(d):
		if not f.ends_with(".scn"): continue
		var sc: Node = (load(d + f) as PackedScene).instantiate()
		var bn := sc.get_node_or_null("Buildings")
		if bn:
			for b: Node in bn.get_children():
				if not b.has_meta(&"kit"): continue
				var xf: Transform3D = (b as Node3D).transform
				if sc is Node3D: xf = (sc as Node3D).transform * xf
				out.append({"name": String(b.name), "kit": String(b.get_meta(&"kit")), "piece": String(b.get_meta(&"piece")), "label": String(b.get_meta(&"label")),
					"pos": [xf.origin.x, xf.origin.y, xf.origin.z], "yaw": rad_to_deg(xf.basis.get_euler().y), "cell": f.get_basename()})
		sc.free()
	var fo := FileAccess.open("res://map_dc/coronado/city_kit/interiors/all_buildings.json", FileAccess.WRITE)
	fo.store_string(JSON.stringify({"_doc": "every kit building of the baked city (tools/city/rooms/list_buildings.gd): name, kit model, piece, label, world position, yaw", "buildings": out}, " ")); fo.close()
	print("LIST buildings=%d" % out.size())
	quit()
