extends SceneTree
## Warm load timings (audit 18 Nov). READ ONLY. Every piece of the layout is loaded once to warm the shared
## resources (textures, materials, shaders), then loaded again uncached: the second time is what a streamer pays
## for the piece itself. Also threaded load of the heaviest pieces, and a census of the interior rooms.
## Run: xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/audit/load_times.gd -- --out=FILE
const DIR := "res://map_dc/coronado/city_kit/pieces/"
const ROOMS := "res://map_dc/coronado/city_kit/interiors/rooms/"
func _init() -> void: _run.call_deferred()
func _tris(m: Mesh) -> int:
	var t := 0
	for si in m.get_surface_count():
		var d: Dictionary = RenderingServer.mesh_get_surface(m.get_rid(), si) if m is ArrayMesh else {}
		var ic := int(d.get("index_count", 0)); var vc := int(d.get("vertex_count", 0))
		t += (ic if ic > 0 else vc) / 3
	return t
func _run() -> void:
	var outp := "user://load.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): outp = a.trim_prefix("--out=")
	var rows: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/city_grid_layout.json")) as Dictionary).instances
	var names := {}
	for r: Dictionary in rows: names[String(r.piece)] = true
	var keep: Array = []
	for p: String in names: keep.append(load(DIR + p + ".scn"))      # warm (and hold, so shared resources stay cached)
	var res := {"pieces": {}, "rooms": {}}
	for p: String in names:
		var t0 := Time.get_ticks_usec()
		var ps: PackedScene = ResourceLoader.load(DIR + p + ".scn", "", ResourceLoader.CACHE_MODE_IGNORE)
		var t1 := Time.get_ticks_usec()
		var inst := ps.instantiate()
		var t2 := Time.get_ticks_usec()
		root.add_child(inst)
		var t3 := Time.get_ticks_usec()
		root.remove_child(inst); inst.free()
		res.pieces[p] = {"load_ms": (t1 - t0) / 1000.0, "inst_ms": (t2 - t1) / 1000.0, "tree_ms": (t3 - t2) / 1000.0}
	print("LOAD warm pass done")
	for f in DirAccess.get_files_at(ROOMS):
		if not f.ends_with(".scn"): continue
		var t0 := Time.get_ticks_usec()
		var ps: PackedScene = ResourceLoader.load(ROOMS + f, "", ResourceLoader.CACHE_MODE_IGNORE)
		var t1 := Time.get_ticks_usec()
		var inst := ps.instantiate()
		var t2 := Time.get_ticks_usec()
		var o := {"file_bytes": FileAccess.get_file_as_bytes(ROOMS + f).size(), "load_ms": (t1 - t0) / 1000.0, "inst_ms": (t2 - t1) / 1000.0, "nodes": 0, "mi": 0, "mmi": 0, "surfs": 0, "tris": 0, "lights": 0, "shadow_lights": 0, "shapes": 0, "scripts": 0, "mats": {}}
		for n: Node in [inst] + inst.find_children("*", "", true, false):
			o.nodes += 1
			if n.get_script() != null: o.scripts += 1
			if n is Light3D:
				o.lights += 1
				if (n as Light3D).shadow_enabled: o.shadow_lights += 1
			if n is CollisionShape3D: o.shapes += 1
			if n is MeshInstance3D and (n as MeshInstance3D).mesh:
				var m := (n as MeshInstance3D).mesh
				o.mi += 1; o.surfs += m.get_surface_count(); o.tris += _tris(m)
				for si in m.get_surface_count():
					var mt: Material = (n as MeshInstance3D).get_active_material(si)
					if mt: o.mats[mt.resource_path if mt.resource_path != "" else str(mt.get_instance_id())] = true
			if n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh and (n as MultiMeshInstance3D).multimesh.mesh:
				var mm := (n as MultiMeshInstance3D).multimesh
				o.mmi += 1; o.surfs += mm.mesh.get_surface_count(); o.tris += _tris(mm.mesh) * mm.instance_count
		o["mats"] = (o.mats as Dictionary).size()
		res.rooms[f] = o
		inst.free()
	var fo := FileAccess.open(outp, FileAccess.WRITE); fo.store_string(JSON.stringify(res)); fo.close()
	print("LOAD_DONE"); quit()
