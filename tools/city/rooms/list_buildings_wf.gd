extends SceneTree
## Every kit building of the waterfront FILL pieces (review/grow_wf_blocks.json rows, branch claude/fill-waterfront)
## with its piece, label, model and grid-frame transform -> interiors/wf_buildings.json (read by assign_wf.py).
## Read-only: loads the saved pieces, changes nothing.  godot --headless --path . -s res://tools/city/rooms/list_buildings_wf.gd
func _init() -> void:
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/review/grow_wf_blocks.json")).rows
	var out: Array = []
	for r: Dictionary in rows:
		var sc: Node3D = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % r.piece) as PackedScene).instantiate()
		var p: Array = r.pos
		var row := Transform3D(Basis(Vector3.UP, deg_to_rad(float(r.get("yaw", 0.0)))), Vector3(float(p[0]), float(p[1]), float(p[2])))
		for b: Node in sc.get_node("Buildings").get_children():
			if not b.has_meta(&"kit"): continue
			var xf: Transform3D = row * (b as Node3D).transform
			out.append({"piece": String(r.piece), "label": String(b.get_meta(&"label", b.name)), "model": String(b.get_meta(&"kit")),
				"pos": [xf.origin.x, xf.origin.y, xf.origin.z], "yaw": rad_to_deg(xf.basis.get_euler().y)})
		sc.free()
	var fo := FileAccess.open("res://map_dc/coronado/city_kit/interiors/wf_buildings.json", FileAccess.WRITE)
	fo.store_string(JSON.stringify({"_doc": "kit buildings of the waterfront fill pieces (tools/city/rooms/list_buildings_wf.gd)", "buildings": out}, " ")); fo.close()
	print("LIST wf buildings=%d" % out.size())
	quit()
