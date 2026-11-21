extends SceneTree
## Footprint dump for the fill (21 Nov, Yasin's review: "props scattered ON the tennis courts ... fill props must never
## land on existing pieces"). Reads only. For every layout row that is NOT a fill piece: every MeshInstance3D other than
## "ground" (courts, paving, decks, walls, buildings, fences ...) as triangles in world space, and every MultiMesh
## instance (props, trees) as its mesh's box corners in world space. Real renderer (MultiMesh data):
##   xvfb-run godot --path . --rendering-method mobile -s res://tools/city/fill/foot_dump.gd -- --out=OUT/fill/foot
## Output: <out>_tri.bin (float32 x, y, z, 9 per triangle), <out>_box.bin (float32 per instance: 4 x,z corners + ymin, ymax, 1 if a tree)
const LAYOUT := "res://map_dc/coronado/city_kit/city_grid_layout.json"
const PIECES := "res://map_dc/coronado/city_kit/pieces/"

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var out := "res://OUT/fill/foot"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = "res://" + a.trim_prefix("--out=")
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var ft := FileAccess.open(out + "_tri.bin", FileAccess.WRITE); var fb := FileAccess.open(out + "_box.bin", FileAccess.WRITE)
	var holder := Node3D.new(); root.add_child(holder)
	var nt := 0; var nb := 0; var k := 0
	for r: Dictionary in lay["instances"]:
		var piece := String(r["piece"])
		if piece.begins_with("fl_"): continue
		var path := PIECES + piece + ".scn"
		if not ResourceLoader.exists(path): continue
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		var p: Array = r.get("pos", [0, 0, 0]); inst.position = Vector3(float(p[0]), float(p[1]), float(p[2])); inst.rotation_degrees.y = float(r.get("yaw", 0))
		holder.add_child(inst)
		for g: Node in inst.find_children("*", "GeometryInstance3D", true, false):
			var nm := String(g.name).rstrip("0123456789")
			# (the far tiers repeat the near one; foam, wear marks and glows are decals lying on or over other ground)
			if nm == "ground" or nm in ["mid", "far"] or nm.ends_with("_mid") or nm.ends_with("_far") or nm.begins_with("glow") \
					or nm.begins_with("foam") or nm.begins_with("shore_foam") or nm.begins_with("wear"): continue
			var x: Transform3D = (g as Node3D).global_transform
			if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
				var m: Mesh = (g as MeshInstance3D).mesh
				var buf := PackedFloat32Array()
				for w0: Vector3 in m.get_faces():      # (any Mesh type: ArrayMesh, BoxMesh ...)
					var w := x * w0
					buf.append(w.x); buf.append(w.y); buf.append(w.z)
				ft.store_buffer(buf.to_byte_array()); nt += buf.size() / 9
			elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
				var mm: MultiMesh = (g as MultiMeshInstance3D).multimesh
				if mm.mesh == null: continue
				var bb: AABB = mm.mesh.get_aabb()
				var buf2 := PackedFloat32Array()
				for i in mm.instance_count:
					var t: Transform3D = x * mm.get_instance_transform(i)
					var ymin := INF; var ymax := -INF
					for c in [Vector3(bb.position.x, 0, bb.position.z), Vector3(bb.end.x, 0, bb.position.z), Vector3(bb.end.x, 0, bb.end.z), Vector3(bb.position.x, 0, bb.end.z)]:
						var w2: Vector3 = t * Vector3(c.x, bb.position.y, c.z); buf2.append(w2.x); buf2.append(w2.z)
						ymin = minf(ymin, w2.y); ymax = maxf(ymax, (t * Vector3(c.x, bb.end.y, c.z)).y)
					buf2.append(ymin); buf2.append(ymax)
					buf2.append(1.0 if (g.name.begins_with("tree_") or g.name.begins_with("palm_")) else 0.0)      # (a tree: the street cap check)
				fb.store_buffer(buf2.to_byte_array()); nb += mm.instance_count
		holder.remove_child(inst); inst.free()
		k += 1
		if k % 16 == 0: await process_frame
	ft.close(); fb.close()
	print("FOOT-DUMP %d pieces, %d triangles, %d instances" % [k, nt, nb])
	quit()
