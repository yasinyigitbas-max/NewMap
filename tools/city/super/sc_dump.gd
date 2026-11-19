extends SceneTree
## Superchecker, part 1: READ a saved piece or room out into plain numbers (19 Nov 2026, Yasin: "make a superchecker
## for both indoors and outdoors ... THIS TOOL MUSTNT CHANGE THE ENTIRE BLOCK WITH A GENERATOR").
## It only reads: it loads each .scn, writes what is in it, frees it. Nothing is saved back, no piece script is run.
## Real renderer (MultiMesh and mesh data are empty under --headless):
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/super/sc_dump.gd -- \
##       --out=<folder> --names=a,b,c [--dir=res://map_dc/coronado/city_kit/pieces/] [--models=<folder>]
##   or  --files=<abs or res path>.scn,...   (a copy somewhere else; the dump takes the file's base name)
## Per scene it writes <out>/<name>.json and <out>/<name>.bin (float32, little endian). The json says where each
## block of numbers lies in the bin ("off" and counts are in floats). Everything is in the SCENE'S OWN frame.
##   ground    every MeshInstance3D named "ground": triangles (9 floats each) per surface name (= ground material)
##   wear      every MeshInstance3D named "wear": the decal mesh as it is (vertex 3, uv 2, colour 4 per vertex)
##   buildings children of "Buildings": name, kit folder, transform (12: basis columns x, y, z, then origin)
##   props     every MultiMeshInstance3D: node path, name, mesh box, and one transform (12) per instance
##   cols      the prop colliders under Props/PropCol: transform (12) and a number that groups equal shapes
##   meshes    every other MeshInstance3D (name, path, triangles, box)       lights  every light (rooms)
##   meta      the root's notes (stalls, poles, site; for rooms floors, solids, entrances, cut)
## Building models are written once each to <models>/<key>.json/.bin: the near mesh's triangles in the model's frame.
const PIECES := "res://map_dc/coronado/city_kit/pieces/"

func _init() -> void: _run.call_deferred()

var buf := PackedFloat32Array()
var _tri_cache := {}

func _xf(t: Transform3D) -> Array:
	return [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z, t.origin.x, t.origin.y, t.origin.z]

func _push_xf(t: Transform3D) -> void:
	buf.append_array(PackedFloat32Array(_xf(t)))

## the transform of n in the frame of top (top itself = identity)
func _rel(n: Node, top: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var p := n
	while p != top and p != null:
		if p is Node3D: t = (p as Node3D).transform * t
		p = p.get_parent()
	return t

func _j(v: Variant) -> Variant:
	match typeof(v):
		TYPE_VECTOR3: return [v.x, v.y, v.z]
		TYPE_VECTOR2: return [v.x, v.y]
		TYPE_DICTIONARY:
			var d := {}
			for k: Variant in v: d[str(k)] = _j(v[k])
			return d
		TYPE_ARRAY:
			var a := []
			for e: Variant in v: a.append(_j(e))
			return a
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_STRING_ARRAY:
			return Array(v)
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY:
			var a2 := []
			for e2: Variant in v: a2.append(_j(e2))
			return a2
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING: return v
		TYPE_STRING_NAME: return String(v)
		TYPE_NIL: return null
	return str(v)

func _tris(mesh: Mesh, si: int, xf: Transform3D) -> int:
	var arr := mesh.surface_get_arrays(si)
	var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ix := PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null: ix = arr[Mesh.ARRAY_INDEX]
	var n := ix.size() if ix.size() > 0 else vv.size()
	n -= n % 3
	var out := PackedFloat32Array(); out.resize(n * 3)
	for k in n:
		var p := xf * vv[ix[k] if ix.size() > 0 else k]
		out[k * 3] = p.x; out[k * 3 + 1] = p.y; out[k * 3 + 2] = p.z
	buf.append_array(out)
	return n / 3

func _run() -> void:
	var out := ""; var models := ""; var dir := PIECES; var names: Array = []; var files: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		elif a.begins_with("--models="): models = a.trim_prefix("--models=")
		elif a.begins_with("--dir="): dir = a.trim_prefix("--dir=")
		elif a.begins_with("--names="): names = Array(a.trim_prefix("--names=").split(",", false))
		elif a.begins_with("--list="): names = Array(FileAccess.get_file_as_string(a.trim_prefix("--list=")).split("\n", false))
		elif a.begins_with("--files="): files = Array(a.trim_prefix("--files=").split(",", false))
	if out == "": print("SC-DUMP needs --out="); quit(1); return
	if models == "": models = out.path_join("models")
	DirAccess.make_dir_recursive_absolute(out); DirAccess.make_dir_recursive_absolute(models)
	for nm: String in names: files.append(dir + nm.strip_edges() + ".scn")
	var done := 0; var bad := 0
	for path: String in files:
		if not (FileAccess.file_exists(path) or ResourceLoader.exists(path)): print("SC-DUMP missing %s" % path); bad += 1; continue
		var ps := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		if ps == null: print("SC-DUMP cannot load %s" % path); bad += 1; continue
		var top: Node = ps.instantiate()
		_dump(top, path, out, models)
		top.free(); done += 1
		if done % 6 == 0: await process_frame
	print("SC-DUMP done %d, failed %d" % [done, bad])
	quit(1 if bad > 0 else 0)

func _dump(top: Node, path: String, out: String, models: String) -> void:
	buf = PackedFloat32Array()
	var name := path.get_file().get_basename()
	var rec := {"v": 3, "name": name, "path": path, "sha256": FileAccess.get_sha256(path), "meta": {}, "ground": [], "wear": [], "buildings": [], "props": [], "cols": {}, "meshes": [], "lights": []}
	for m in top.get_meta_list(): rec["meta"][String(m)] = _j(top.get_meta(m))
	var bn := top.get_node_or_null("Buildings")
	var in_bld := {}
	if bn:
		for b: Node in bn.get_children():
			if not (b is Node3D): continue
			var near := b.get_node_or_null("near") as MeshInstance3D
			var kit := String(b.get_meta(&"kit", ""))
			var key := kit.replace("/", "__")
			if near and near.mesh:
				if key == "":
					var ab := near.mesh.get_aabb()
					key = "shape_%d_%d_%d_%d" % [near.mesh.surface_get_array_len(0), roundi(ab.size.x * 10.0), roundi(ab.size.y * 10.0), roundi(ab.size.z * 10.0)]
				if not FileAccess.file_exists(models.path_join(key + ".json")): _model(near, key, kit, models)
				if not FileAccess.file_exists(models.path_join(key + ".col.json")): _model_col(b, key, models)
			var boxes: Array = []      # collision boxes added to this one building (columns), in the building's frame
			var cb := b.get_node_or_null("col")
			if cb:
				for cs: Node in cb.get_children():
					if cs is CollisionShape3D and (cs as CollisionShape3D).shape is BoxShape3D:
						var o := ((cb as Node3D).transform * (cs as CollisionShape3D).transform).origin; var sz := ((cs as CollisionShape3D).shape as BoxShape3D).size
						boxes.append([o.x, o.y, o.z, sz.x, sz.y, sz.z])
			rec["buildings"].append({"path": String(top.get_path_to(b)), "name": String(b.name), "kit": kit, "model": key, "xf": _xf(_rel(b, top)), "meta": _j(_metas(b)), "boxes": boxes})
			for c in b.find_children("*", "MeshInstance3D", true, false): in_bld[c] = true
	for mi: MeshInstance3D in top.find_children("*", "MeshInstance3D", true, false):
		if in_bld.has(mi) or mi.mesh == null: continue
		var xf := _rel(mi, top)
		var nm := String(mi.name)
		if nm == "ground":
			var g := {"path": String(top.get_path_to(mi)), "surf": []}
			for si in mi.mesh.get_surface_count():
				var off := buf.size()
				var n := _tris(mi.mesh, si, xf)
				g["surf"].append({"name": String((mi.mesh as ArrayMesh).surface_get_name(si)) if mi.mesh is ArrayMesh else "", "off": off, "tris": n})
			rec["ground"].append(g)
		elif nm == "wear":
			for si in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(si)
				var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
				var cc: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
				var indexed: bool = arr[Mesh.ARRAY_INDEX] != null
				var off2 := buf.size()
				var o := PackedFloat32Array(); o.resize(vv.size() * 9)
				for k in vv.size():
					var p := xf * vv[k]
					o[k * 9] = p.x; o[k * 9 + 1] = p.y; o[k * 9 + 2] = p.z
					o[k * 9 + 3] = uv[k].x if k < uv.size() else 0.0; o[k * 9 + 4] = uv[k].y if k < uv.size() else 0.0
					var c2: Color = cc[k] if k < cc.size() else Color(1, 1, 1, 1)
					o[k * 9 + 5] = c2.r; o[k * 9 + 6] = c2.g; o[k * 9 + 7] = c2.b; o[k * 9 + 8] = c2.a
				buf.append_array(o)
				rec["wear"].append({"path": String(top.get_path_to(mi)), "surface": si, "off": off2, "verts": vv.size(), "indexed": indexed})
		else:
			var tn := 0
			for si in mi.mesh.get_surface_count():
				var am := mi.mesh as ArrayMesh
				var il: int = am.surface_get_array_index_len(si) if am else 0
				tn += (il if il > 0 else (am.surface_get_array_len(si) if am else 0)) / 3
			var ab2 := mi.mesh.get_aabb()
			var e := {"path": String(top.get_path_to(mi)), "name": nm, "tris": tn, "xf": _xf(xf), "aabb": [ab2.position.x, ab2.position.y, ab2.position.z, ab2.size.x, ab2.size.y, ab2.size.z]}
			if nm == "shell" or name.begins_with("w_"):      # a room's built walls, floor, ceiling; a wire piece's wires: the checks need the faces
				e["off"] = buf.size(); var n2 := 0
				for si in mi.mesh.get_surface_count(): n2 += _tris(mi.mesh, si, xf)
				e["dumped"] = n2
			rec["meshes"].append(e)
	for mmi: MultiMeshInstance3D in top.find_children("*", "MultiMeshInstance3D", true, false):
		var mm := mmi.multimesh
		if mm == null: continue
		var xf2 := _rel(mmi, top)
		var nm2 := String(mmi.name)
		var parts := nm2.split("_")
		var tier := ""; var cond := ""; var base := nm2
		if parts.size() >= 3 and parts[parts.size() - 1] in ["near", "mid", "far"]:
			tier = parts[parts.size() - 1]; cond = parts[parts.size() - 2]
			base = "_".join(parts.slice(0, parts.size() - 2))
		var ab3 := mm.mesh.get_aabb() if mm.mesh else AABB()
		var mt := 0
		if mm.mesh:
			var mid := mm.mesh.get_instance_id()
			if not _tri_cache.has(mid): _tri_cache[mid] = mm.mesh.get_faces().size() / 3
			mt = int(_tri_cache[mid])
		var off3 := buf.size()
		for i in mm.instance_count: _push_xf(xf2 * mm.get_instance_transform(i))
		rec["props"].append({"path": String(top.get_path_to(mmi)), "name": nm2, "base": base, "cond": cond, "tier": tier, "count": mm.instance_count, "off": off3,
			"aabb": [ab3.position.x, ab3.position.y, ab3.position.z, ab3.size.x, ab3.size.y, ab3.size.z], "colors": mm.use_colors, "custom": mm.use_custom_data,
			"range": [mmi.visibility_range_begin, mmi.visibility_range_end], "tris": mt})
	var pc := top.get_node_or_null("Props/PropCol")
	if pc:
		var groups := {}; var gid: Array = []; var off4 := buf.size(); var n3 := 0
		for cs: Node in pc.get_children():
			if not (cs is CollisionShape3D): continue
			var sh := (cs as CollisionShape3D).shape
			var k2 := sh.get_instance_id() if sh else 0
			if not groups.has(k2): groups[k2] = groups.size()
			gid.append(groups[k2]); _push_xf(_rel(cs, top)); n3 += 1
		rec["cols"] = {"path": "Props/PropCol", "off": off4, "count": n3, "group": gid}
	for l: Light3D in top.find_children("*", "Light3D", true, false):
		rec["lights"].append({"path": String(top.get_path_to(l)), "class": l.get_class(), "xf": _xf(_rel(l, top)), "range": (l as OmniLight3D).omni_range if l is OmniLight3D else 0.0})
	for d: Node in top.get_children():
		if String(d.name).begins_with("DoorLeaf"): rec["meshes"].append({"path": String(top.get_path_to(d)), "name": "doorleaf", "xf": _xf(_rel(d, top)), "meta": _j(_metas(d))})
	rec["floats"] = buf.size()
	var fb := FileAccess.open(out.path_join(name + ".bin"), FileAccess.WRITE); fb.store_buffer(buf.to_byte_array()); fb.close()
	var fj := FileAccess.open(out.path_join(name + ".json"), FileAccess.WRITE); fj.store_string(JSON.stringify(rec)); fj.close()
	print("SC-DUMP %s: ground %d, wear %d, buildings %d, prop batches %d, colliders %d" % [name, rec["ground"].size(), rec["wear"].size(), rec["buildings"].size(), rec["props"].size(), int((rec["cols"] as Dictionary).get("count", 0))])

func _metas(n: Node) -> Dictionary:
	var d := {}
	for m in n.get_meta_list(): d[String(m)] = n.get_meta(m)
	return d

## a building model's own collision (the "col" body kit_lib gives it), as triangles in the model's frame
func _model_col(b: Node, key: String, models: String) -> void:
	var out := PackedFloat32Array(); var n := 0
	for body: Node in b.get_children():
		if not (body is StaticBody3D): continue
		for cs: Node in body.get_children():
			if not (cs is CollisionShape3D) or (cs as CollisionShape3D).shape == null: continue
			var xf := (body as Node3D).transform * (cs as CollisionShape3D).transform
			var sh := (cs as CollisionShape3D).shape
			var faces := PackedVector3Array()
			if sh is ConcavePolygonShape3D: faces = (sh as ConcavePolygonShape3D).get_faces()
			elif sh.get_debug_mesh() != null: faces = sh.get_debug_mesh().get_faces()
			for v: Vector3 in faces:
				var p := xf * v
				out.append(p.x); out.append(p.y); out.append(p.z)
			n += faces.size() / 3
	var fb := FileAccess.open(models.path_join(key + ".col.bin"), FileAccess.WRITE); fb.store_buffer(out.to_byte_array()); fb.close()
	var fj := FileAccess.open(models.path_join(key + ".col.json"), FileAccess.WRITE); fj.store_string(JSON.stringify({"key": key, "tris": n})); fj.close()

func _model(near: MeshInstance3D, key: String, kit: String, models: String) -> void:
	var keep := buf; buf = PackedFloat32Array()
	var n := 0
	for si in near.mesh.get_surface_count(): n += _tris(near.mesh, si, near.transform)
	var ab := near.mesh.get_aabb()
	var fb := FileAccess.open(models.path_join(key + ".bin"), FileAccess.WRITE); fb.store_buffer(buf.to_byte_array()); fb.close()
	var fj := FileAccess.open(models.path_join(key + ".json"), FileAccess.WRITE)
	fj.store_string(JSON.stringify({"key": key, "kit": kit, "tris": n, "aabb": [ab.position.x, ab.position.y, ab.position.z, ab.size.x, ab.size.y, ab.size.z]})); fj.close()
	buf = keep
