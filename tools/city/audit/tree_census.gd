extends SceneTree
## Tree census (19 Nov, Yasin: "which areas having trees make sense and which dont"): how many trees, palms and other
## plants every piece of the assembled city carries, by species. Reads city_grid_layout.json and the piece scenes;
## changes nothing. Run with the real renderer (MultiMesh data):
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/audit/tree_census.gd -- --json=OUT/trees.json
## Output: one row per layout instance: piece, from, pos, trees, palms, plants, species {name: n}.
const LAYOUT := "res://map_dc/coronado/city_kit/city_grid_layout.json"
const PIECES := "res://map_dc/coronado/city_kit/pieces/"

func _init() -> void: _run.call_deferred()

func _arg(key: String, def: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="): return a.substr(key.length() + 3)
	return def

func _count(piece: String) -> Dictionary:
	var out := {"trees": 0, "palms": 0, "plants": 0, "species": {}}
	var path := PIECES + piece + ".scn"
	if not ResourceLoader.exists(path): out["missing"] = true; return out
	var ps := load(path) as PackedScene
	if ps == null: out["missing"] = true; return out
	var n := ps.instantiate()
	for mmi: MultiMeshInstance3D in n.find_children("*_near", "MultiMeshInstance3D", true, false):
		var nm := String(mmi.name)
		var kind := ""
		if nm.begins_with("tree_"): kind = "trees"
		elif nm.begins_with("palm_"): kind = "palms"
		elif nm.begins_with("plant_") or nm.begins_with("hedge_") or nm.begins_with("shrub_"): kind = "plants"
		if kind == "" or mmi.multimesh == null: continue
		var c: int = mmi.multimesh.instance_count
		out[kind] = int(out[kind]) + c
		var sp := nm.trim_suffix("_near")
		var d: Dictionary = out["species"]
		d[sp] = int(d.get(sp, 0)) + c
	n.free()
	return out

func _run() -> void:
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var cache := {}
	var rows: Array = []
	var tot := {"trees": 0, "palms": 0, "plants": 0}
	for r: Dictionary in lay["instances"]:
		var piece: String = r["piece"]
		if not cache.has(piece): cache[piece] = _count(piece)
		var c: Dictionary = cache[piece]
		rows.append({"piece": piece, "from": r.get("from", ""), "pos": r.get("pos", []), "trees": c["trees"],
			"palms": c["palms"], "plants": c["plants"], "species": c["species"], "missing": c.get("missing", false)})
		for k: String in tot: tot[k] = int(tot[k]) + int(c[k])
	var f := FileAccess.open(_arg("json", "res://OUT/trees.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(rows))
	f.close()
	print("TREES-CENSUS %d instances, %d pieces: %d trees, %d palms, %d other plants" % [rows.size(), cache.size(), tot["trees"], tot["palms"], tot["plants"]])
	quit()
