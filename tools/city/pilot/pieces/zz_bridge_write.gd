extends SceneTree
## Bridge hero tool (not a piece): reads the "rg" meta of every built bridge piece and writes the integration table
## map_dc/coronado/city_kit/review/bridge_sites.json ({"rows": [{piece, pos [u, y, v] GRID, yaw}]}); integrate.py places
## them. The two gateway crosses stay in ring_nw_sites.json (they replace the ring T's at the same sites).
## Usage: godot --path PV -s res://tools/city/pilot/pieces/zz_bridge_write.gd
func _init() -> void:
	var rows: Array = []
	var dir := "res://map_dc/coronado/city_kit/pieces/"
	var names: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("s_br_") and f.ends_with(".scn"): names.append(f.get_basename())
	names.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	for n: String in names:
		var root: Node = (load(dir + n + ".scn") as PackedScene).instantiate()
		var m: Dictionary = root.get_meta(&"rg", {})
		var p: Array = m.get("pos", [0, 0, 0])
		rows.append({"piece": n, "pos": [snappedf(float(p[0]), 0.001), snappedf(float(p[1]), 0.001), snappedf(float(p[2]), 0.001)], "yaw": float(m.get("yaw", 0.0)), "site": "b160" if n.begins_with("s_br_appr") else "b164"})
		root.free()
	var f := FileAccess.open("res://map_dc/coronado/city_kit/review/bridge_sites.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"note": "Bridge option A hero pieces (road_bridge.gd), grid frame; written by zz_bridge_write.gd", "rows": rows}, " "))
	f.close()
	print("BRIDGE rows %d" % rows.size())
	quit()
