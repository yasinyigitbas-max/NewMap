extends SceneTree
## Ground dump (19 Nov, Yasin: "Many areas are sunk in too... I think these validators and checkers don't do what they
## are supposed to do"). Writes the "ground" mesh of every piece of the assembled city (city_grid_layout.json) to plain
## files, for tools/city/audit/ground_check.py to measure: piece against terrain, piece against its neighbours.
## Reads only. Real renderer (mesh arrays):
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/audit/ground_dump.gd -- --out=OUT/ground
## Output: <out>_v.bin (float32 x, y, z in each mesh's own frame), <out>_i.bin (int32 triangle indices),
## <out>.json: per layout instance its piece, where it came from, the mesh's world transform (12 numbers: the basis'
## three columns, then the origin) and where its numbers lie in the two files.
const LAYOUT := "res://map_dc/coronado/city_kit/city_grid_layout.json"
const PIECES := "res://map_dc/coronado/city_kit/pieces/"

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var out := "res://OUT/ground"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	if not out.begins_with("res://") and not out.is_absolute_path(): out = "res://" + out
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var fv := FileAccess.open(out + "_v.bin", FileAccess.WRITE); var fi := FileAccess.open(out + "_i.bin", FileAccess.WRITE)
	var recs: Array = []; var vo := 0; var io := 0; var k := 0
	var holder := Node3D.new(); root.add_child(holder)
	for r: Dictionary in lay["instances"]:
		var piece := String(r["piece"]); var path := PIECES + piece + ".scn"
		if not ResourceLoader.exists(path): continue
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		var p: Array = r.get("pos", [0, 0, 0]); inst.position = Vector3(float(p[0]), float(p[1]), float(p[2])); inst.rotation_degrees.y = float(r.get("yaw", 0))
		holder.add_child(inst)
		for g: MeshInstance3D in inst.find_children("ground", "MeshInstance3D", true, false):
			if g.mesh == null: continue
			var x := g.global_transform
			var rec := {"id": k, "piece": piece, "from": String(r.get("from", "")), "xf": [x.basis.x.x, x.basis.x.y, x.basis.x.z, x.basis.y.x, x.basis.y.y, x.basis.y.z, x.basis.z.x, x.basis.z.y, x.basis.z.z, x.origin.x, x.origin.y, x.origin.z], "surf": []}
			for si in g.mesh.get_surface_count():
				var arr: Array = g.mesh.surface_get_arrays(si)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ix := PackedInt32Array()
				if arr[Mesh.ARRAY_INDEX] != null: ix = arr[Mesh.ARRAY_INDEX]
				if ix.is_empty():
					ix.resize(v.size())
					for q in ix.size(): ix[q] = q
				fv.store_buffer(v.to_byte_array()); fi.store_buffer(ix.to_byte_array())
				(rec["surf"] as Array).append([String(g.mesh.surface_get_name(si)), vo, v.size(), io, ix.size()])
				vo += v.size(); io += ix.size()
			recs.append(rec)
		k += 1
		holder.remove_child(inst); inst.free()
		if k % 8 == 0: await process_frame
	fv.close(); fi.close()
	var fj := FileAccess.open(out + ".json", FileAccess.WRITE); fj.store_string(JSON.stringify(recs)); fj.close()
	print("GROUND-DUMP %d instances, %d ground meshes, %d vertices, %d triangles" % [k, recs.size(), vo, io / 3])
	quit()
