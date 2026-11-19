extends "res://map_dc/coronado/city_kit/interiors/room_contracts.gd"
## Room contracts for the hospital zone and the university campus (claude/fill-high-street, 19 Nov). The same
## measurement as room_contracts.gd (extended, not changed) for the kit models those pieces use that have no contract
## yet in the shared room_contracts.json. Measures only. Writes interiors/room_contracts_hp.json {"models": {folder: contract}}.
## Run: xvfb-run -a godot --path . --rendering-method mobile --resolution 320x180 -s res://map_dc/coronado/city_kit/interiors/room_contracts_hp.gd
const MODELS := ["public/pub_hospital", "extras/ext_hospital", "public/pub_university", "public/pub_museum"]

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
	var models := {}
	for m: String in MODELS: models[m] = _contract(m)
	_save("room_contracts_hp.json", {"_doc": "room_contracts_hp.gd: contracts of the hospital / campus models missing from room_contracts.json (same measurement)", "models": models})
	print("RCHP models=%d" % models.size())
	quit()
