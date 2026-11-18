extends SceneTree
## The industrial growth blocks' buildings (review/grow_ind_blocks.json pieces) with their world transforms ->
## map_dc/coronado/city_kit/interiors/buildings_ind.json (read by assign_ind.py). Read-only. 18 Nov, claude/grow-industrial.
##   godot --headless --path . -s res://tools/city/rooms/list_buildings_ind.gd
func _init() -> void:
	var tab: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/review/grow_ind_blocks.json"))
	var out: Array = []
	for r: Dictionary in tab.rows:
		var p: Array = r.pos
		var base := Transform3D(Basis(Vector3.UP, deg_to_rad(float(r.yaw))), Vector3(float(p[0]), float(p[1]), float(p[2])))
		var sc: Node = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % r.piece) as PackedScene).instantiate()
		for b: Node in sc.get_node("Buildings").get_children():
			if not b.has_meta(&"kit"): continue
			var xf: Transform3D = base * (b as Node3D).transform
			out.append({"piece": String(r.piece), "label": String(b.name), "kit": String(b.get_meta(&"kit")), "pos": [xf.origin.x, xf.origin.y, xf.origin.z], "yaw": rad_to_deg(xf.basis.get_euler().y)})
		sc.free()
	var fo := FileAccess.open("res://map_dc/coronado/city_kit/interiors/buildings_ind.json", FileAccess.WRITE)
	fo.store_string(JSON.stringify({"_doc": "industrial growth buildings (tools/city/rooms/list_buildings_ind.gd)", "buildings": out}, " ")); fo.close()
	print("LIST_IND buildings=%d" % out.size())
	quit()
