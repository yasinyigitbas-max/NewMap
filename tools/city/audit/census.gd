extends SceneTree
## Performance census of the pieces of a layout (audit 18 Nov). READ ONLY: loads each piece, measures, frees it.
## Per unique piece: load / instantiate / enter-tree time, nodes, meshes (embedded or shared, triangles, surfaces,
## materials, distance ranges), MultiMesh batches, collision shapes, metas. Writes one JSON.
## Run (real renderer, MultiMesh data lives in it):
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/audit/census.gd -- --out=FILE [--layout=res://...json]
const DIR := "res://map_dc/coronado/city_kit/pieces/"
var meshes := {}     # content key -> {bytes, tris, n (uses), pieces, embedded copies}

func _init() -> void: _run.call_deferred()

func _mesh_info(m: Mesh, piece: String) -> Dictionary:
	var tris := 0; var bytes := 0; var surfs := m.get_surface_count(); var key := ""
	if m is ArrayMesh:
		for si in surfs:
			var d: Dictionary = RenderingServer.mesh_get_surface(m.get_rid(), si)
			var vb: PackedByteArray = d.get("vertex_data", PackedByteArray()); var ab: PackedByteArray = d.get("attribute_data", PackedByteArray()); var ib: PackedByteArray = d.get("index_data", PackedByteArray())
			bytes += vb.size() + ab.size() + ib.size()
			var ic := int(d.get("index_count", 0)); var vc := int(d.get("vertex_count", 0))
			tris += (ic if ic > 0 else vc) / 3
			key += "%d:%d:%d:%d;" % [vc, ic, hash(vb), hash(ib)]
	else:
		for si in surfs:
			var a := m.surface_get_arrays(si); var idx: Variant = a[Mesh.ARRAY_INDEX]
			tris += ((idx as PackedInt32Array).size() if idx != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
		key = m.get_class() + str(m.get_aabb())
	var rp := m.resource_path
	var embedded := rp == "" or rp.contains("::")
	var own := rp.begins_with(DIR + piece + ".scn")
	if not meshes.has(key): meshes[key] = {"bytes": bytes, "tris": tris, "pieces": {}, "copies": {}, "path": rp}
	meshes[key].pieces[piece] = true
	meshes[key].copies[rp if rp != "" else piece + "#" + str(m.get_instance_id())] = true
	return {"tris": tris, "bytes": bytes, "surfs": surfs, "key": key.md5_text().substr(0, 10), "path": rp, "embedded": embedded, "own": own}

func _mat_path(mt: Material) -> String:
	if mt == null: return "null"
	if mt.resource_path != "" and not mt.resource_path.contains("::"): return mt.resource_path
	var s := mt.get_class()
	if mt is BaseMaterial3D:
		var b := mt as BaseMaterial3D
		s += "|" + (b.albedo_texture.resource_path.get_file() if b.albedo_texture else "notex") + "|tr%d|cull%d|n%d" % [b.transparency, b.cull_mode, int(b.normal_enabled)]
	elif mt is ShaderMaterial and (mt as ShaderMaterial).shader: s += "|" + (mt as ShaderMaterial).shader.resource_path.get_file()
	return "embedded:" + s

func _walk(n: Node, piece: String, out: Dictionary, path: String) -> void:
	out.nodes += 1
	var cls := n.get_class(); out.classes[cls] = int(out.classes.get(cls, 0)) + 1
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D; var info := _mesh_info(mi.mesh, piece)
		var mats: Array = []
		for si in mi.mesh.get_surface_count():
			var mt: Material = mi.material_override if mi.material_override else (mi.get_surface_override_material(si) if mi.get_surface_override_material(si) else mi.mesh.surface_get_material(si))
			mats.append(_mat_path(mt))
		var kit := ""
		if n.get_parent().has_meta(&"kit"): kit = String(n.get_parent().get_meta(&"kit"))
		out.mi.append({"name": String(n.name), "path": path, "kit": kit, "tris": info.tris, "bytes": info.bytes, "surfs": info.surfs, "mesh": info.key, "mesh_path": info.path, "embedded": info.embedded, "mats": mats,
			"vb": mi.visibility_range_begin, "ve": mi.visibility_range_end, "shadow": mi.cast_shadow, "pos": [mi.global_position.x, mi.global_position.y, mi.global_position.z], "aabb": [mi.get_aabb().size.x, mi.get_aabb().size.y, mi.get_aabb().size.z]})
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh:
		var mmi := n as MultiMeshInstance3D; var mm := mmi.multimesh
		if mm.mesh:
			var info2 := _mesh_info(mm.mesh, piece); var mats2: Array = []
			for si in mm.mesh.get_surface_count():
				var mt2: Material = mmi.material_override if mmi.material_override else mm.mesh.surface_get_material(si)
				mats2.append(_mat_path(mt2))
			var ab := mmi.get_aabb()
			out.mmi.append({"name": String(n.name), "cell": String(n.get_parent().name), "count": mm.instance_count, "tris": info2.tris, "bytes": info2.bytes, "surfs": info2.surfs, "mesh": info2.key, "mesh_path": info2.path, "embedded": info2.embedded, "mats": mats2,
				"vb": mmi.visibility_range_begin, "ve": mmi.visibility_range_end, "shadow": mmi.cast_shadow, "span": [ab.size.x, ab.size.y, ab.size.z], "mm_path": mm.resource_path})
	elif n is CollisionShape3D and (n as CollisionShape3D).shape:
		var sh := (n as CollisionShape3D).shape; var sc := sh.get_class()
		out.shapes[sc] = int(out.shapes.get(sc, 0)) + 1
		out.shape_res[sh.get_instance_id()] = true
		if sh is ConcavePolygonShape3D: out.trimesh_faces += (sh as ConcavePolygonShape3D).get_faces().size() / 3
		if sh is ConvexPolygonShape3D: out.convex_pts += (sh as ConvexPolygonShape3D).points.size()
	elif n is Light3D: out.lights += 1
	if n.get_script() != null: out.scripts += 1
	for c in n.get_children(): _walk(c, piece, out, path + "/" + String(c.name))

func _run() -> void:
	var outp := "user://census.json"; var layout := "res://map_dc/coronado/city_kit/city_grid_layout.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): outp = a.trim_prefix("--out=")
		if a.begins_with("--layout="): layout = a.trim_prefix("--layout=")
	var rows: Array = (JSON.parse_string(FileAccess.get_file_as_string(layout)) as Dictionary).instances
	var uses := {}; var order: Array = []
	for r: Dictionary in rows:
		var p := String(r.piece)
		if not uses.has(p): uses[p] = 0; order.append(p)
		uses[p] += 1
	var holder := Node3D.new(); root.add_child(holder)
	var res := {}
	for p: String in order:
		var path := DIR + p + ".scn"
		if not ResourceLoader.exists(path): continue
		var t0 := Time.get_ticks_usec()
		var ps: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		var t1 := Time.get_ticks_usec()
		var inst: Node3D = ps.instantiate()
		var t2 := Time.get_ticks_usec()
		holder.add_child(inst)
		var t3 := Time.get_ticks_usec()
		await process_frame; await process_frame
		var t4 := Time.get_ticks_usec()
		var o := {"uses": uses[p], "file_bytes": FileAccess.get_file_as_bytes(path).size(), "load_ms": (t1 - t0) / 1000.0, "inst_ms": (t2 - t1) / 1000.0, "tree_ms": (t3 - t2) / 1000.0, "first_frames_ms": (t4 - t3) / 1000.0,
			"nodes": 0, "classes": {}, "mi": [], "mmi": [], "shapes": {}, "shape_res": {}, "trimesh_faces": 0, "convex_pts": 0, "lights": 0, "scripts": 0, "metas": []}
		for mk in inst.get_meta_list(): o.metas.append(String(mk))
		if inst.has_meta(&"stalls"): o["stalls"] = (inst.get_meta(&"stalls") as Array).size()
		_walk(inst, p, o, "")
		o["shape_res"] = (o.shape_res as Dictionary).size()
		var ab := AABB(); var first := true
		for g: Node in inst.find_children("*", "VisualInstance3D", true, false):
			var gb: AABB = (g as VisualInstance3D).global_transform * (g as VisualInstance3D).get_aabb()
			if first: ab = gb; first = false
			else: ab = ab.merge(gb)
		o["size"] = [ab.size.x, ab.size.y, ab.size.z]
		res[p] = o
		var tf := Time.get_ticks_usec()
		holder.remove_child(inst); inst.free()
		o["free_ms"] = (Time.get_ticks_usec() - tf) / 1000.0
		print("CENSUS %s load=%.0f inst=%.0f tree=%.0f nodes=%d" % [p, o.load_ms, o.inst_ms, o.tree_ms, o.nodes])
	var ml: Array = []
	for k: String in meshes:
		var e: Dictionary = meshes[k]
		ml.append({"key": k.md5_text().substr(0, 10), "bytes": e.bytes, "tris": e.tris, "pieces": (e.pieces as Dictionary).size(), "copies": (e.copies as Dictionary).size(), "path": e.path})
	var f := FileAccess.open(outp, FileAccess.WRITE); f.store_string(JSON.stringify({"pieces": res, "meshes": ml})); f.close()
	print("CENSUS_DONE pieces=%d meshes=%d -> %s" % [res.size(), ml.size(), outp])
	quit()
