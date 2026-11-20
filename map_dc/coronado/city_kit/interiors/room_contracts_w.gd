extends "res://map_dc/coronado/city_kit/interiors/room_contracts.gd"
## Room contracts for the CITY-CENTRE FILL (n_w_* pieces, claude/fill-city-centre, 19 Nov). A copy of
## room_contracts_strip.gd (the shared room_contracts.gd is extended, not changed): every kit model used in the n_cc_*
## pieces gets its contract (openings from the atlas, floors, inside box, signs), and every building of those pieces is
## listed with its transform in the GRID frame (rows of review/grow_uw_blocks.json, this session's own table). Writes:
##   interiors/room_contracts_w.json   {"models": {folder: contract}}
##   interiors/w_buildings.json        {"buildings": [{piece, label, model, pos, yaw, doors_front}]}
## Run: xvfb-run -a godot --path . --rendering-method mobile --resolution 320x180 -s res://map_dc/coronado/city_kit/interiors/room_contracts_cc.gd
const GRID := "res://map_dc/coronado/city_kit/review/grow_uw_blocks.json"

func _run() -> void:
	var L: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/textures/city_layout.json"))
	for r: String in L.regions:
		var e: Dictionary = L.regions[r]
		if r.begins_with("O_") and e.has("uv"): regs[r] = e.uv
		if r.begins_with("SG_") and e.has("uv"): sregs[r] = e.uv
		if r == "S_signbg" or r == "T_dark":
			var sz: Array = L.size if L.size is Array else [L.size, L.size]
			if e.has("uv") and (e.uv as Array).size() == 4: sregs[r] = e.uv
			else:
				var px: Array = e.px
				sregs[r] = [float(px[0]) / float(sz[0]), float(px[1]) / float(sz[1]), float(px[2]) / float(sz[0]), float(px[3]) / float(sz[1])]
	stext = L.get("signs", {})
	for f in DirAccess.get_files_at(LAYOUTS):
		if not f.ends_with(".json"): continue
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUTS + f))
		var rm: Dictionary = d.get("room", {})
		sets.append([String(d.set), d.get("types", []), float(rm.get("min_w", 3)), float(rm.get("max_w", 9)), float(rm.get("min_d", 4)), float(rm.get("max_d", 10))])
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(GRID)).rows
	var models := {}; var out_b: Array = []
	for r: Dictionary in rows:
		if not String(r.piece).begins_with("n_w_"): continue
		var p: Array = r.pos
		var n: Node3D = (load("res://map_dc/coronado/city_kit/pieces/%s.scn" % r.piece) as PackedScene).instantiate()
		n.position = Vector3(float(p[0]), float(p[1]), float(p[2])); n.rotation_degrees.y = float(r.get("yaw", 0))
		root.add_child(n)
		for b: Node3D in n.get_node("Buildings").get_children():
			var folder := String(b.get_meta(&"kit"))
			if not models.has(folder): models[folder] = _contract(folder)
			var xf := b.global_transform
			out_b.append({"piece": String(r.piece), "label": String(b.name), "model": folder,
				"pos": [snappedf(xf.origin.x, 0.001), snappedf(xf.origin.y, 0.001), snappedf(xf.origin.z, 0.001)],
				"yaw": snappedf(rad_to_deg(xf.basis.get_euler().y), 0.01), "doors_front": K.building_stats(folder).get("doors_front", [])})
	_save("room_contracts_w.json", {"_doc": "room_contracts_cc.gd: contracts of every model in the west fill pieces (same measurement as room_contracts.gd)", "models": models})
	_save("w_buildings.json", {"_doc": "room_contracts_cc.gd: every building of the n_w_* pieces, grid frame (review/grow_uw_blocks.json)", "buildings": out_b})
	print("RCC models=%d buildings=%d" % [models.size(), out_b.size()])
	quit()
