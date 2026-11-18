extends SceneTree
## Kit census of the residential growth pieces (18 Nov): every kit building (meta "kit") and prop (near-tier MultiMesh
## instances, cells included) in the r_q_* pieces -> prints CENSUS_B <folder> <n> / CENSUS_P <base> <n>, for KIT_USAGE.md.
## Real renderer (MultiMesh data): xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s <this>
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var bl := {}; var pr := {}
	var d := "res://map_dc/coronado/city_kit/pieces/"
	for f in DirAccess.get_files_at(d):
		if not (f.begins_with("r_q_") and f.ends_with(".scn")): continue
		var n: Node = (load(d + f) as PackedScene).instantiate()
		root.add_child(n)
		for b: Node in n.get_node("Buildings").get_children():
			var k := String(b.get_meta(&"kit", "?")); bl[k] = int(bl.get(k, 0)) + 1
		for m: MultiMeshInstance3D in n.find_children("*_near", "MultiMeshInstance3D", true, false):
			var nm := String(m.name).trim_suffix("_near")
			for c: String in ["_clean", "_worn", "_dirty", "_rusty", "_normal", "_weathered", "_iron", "_glass", "_net"]:
				if nm.ends_with(c): nm = nm.trim_suffix(c); break
			pr[nm] = int(pr.get(nm, 0)) + m.multimesh.instance_count
		n.free()
	for k: String in bl: print("CENSUS_B %s %d" % [k, bl[k]])
	for k: String in pr: print("CENSUS_P %s %d" % [k, pr[k]])
	quit()
