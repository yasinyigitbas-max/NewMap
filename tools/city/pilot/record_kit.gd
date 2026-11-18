extends SceneTree
## Record meta "kit" (the kit building folder) on every building of a saved piece that lacks it (17 Nov, Yasin: "those
## places should record their footprints too, all the zones should have the same standards"). Older pieces placed
## buildings before K.building stored the kit folder, so tools had to guess footprints from names or mesh shapes.
## Matching: the node name (= the kit folder's basename), else the near mesh's shape (vertex count + bounds) against
## every kit / modular / city-kit building. Nothing else in the file changes: it refuses to save unless every building
## transform and every prop batch / instance count is identical. Prints RECORD <piece> fixed n, unmatched [..].
## Run (real renderer: MultiMesh data lives in it):
##   xvfb-run -a godot --path PV --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/record_kit.gd -- <piece> ...
const K := preload("res://tools/city/pilot/kit_lib.gd")
const DIR := "res://map_dc/coronado/city_kit/pieces/"
const KIT := "res://assets/coronado_kit/buildings/"
var folders := {}
var shapes := {}

func _init() -> void: _run.call_deferred()

func _key(m: Mesh) -> String:
	var ab := m.get_aabb()
	return "%d_%.1f_%.1f_%.1f" % [m.surface_get_array_len(0), ab.size.x, ab.size.y, ab.size.z]

func _index() -> void:
	var dirs := {}
	for cat in DirAccess.get_directories_at(KIT):
		for b in DirAccess.get_directories_at(KIT + cat): dirs[cat + "/" + b] = KIT + cat + "/" + b; folders[b] = cat + "/" + b
	for b2 in DirAccess.get_directories_at("res://assets/coronado_kit/modular/examples/"):
		dirs["modular/examples/" + b2] = "res://assets/coronado_kit/modular/examples/" + b2; folders[b2] = "modular/examples/" + b2
	for b3 in DirAccess.get_directories_at("res://map_dc/coronado/city_kit/buildings/"):
		dirs["ck/" + b3] = "res://map_dc/coronado/city_kit/buildings/" + b3; folders[b3] = "ck/" + b3
	for key: String in dirs:
		var d: String = dirs[key]
		if not FileAccess.file_exists(d + "/stats.json"): continue
		var f := K._tier_file(d, "near")
		if f == "": continue
		var inst: Node = (load(f) as PackedScene).instantiate()
		var mi := K._first_mesh(inst)
		if mi and mi.mesh: shapes[_key(mi.mesh)] = key
		inst.free()

func _run() -> void:
	_index()
	var bad := 0
	for nm in OS.get_cmdline_user_args():
		if not _record(nm): bad += 1
	print("RECORD_DONE failed=%d" % bad)
	quit(1 if bad > 0 else 0)

func _digest(root: Node) -> String:
	var parts: Array = []
	var bn := root.get_node_or_null("Buildings")
	if bn:
		for b: Node3D in bn.get_children(): parts.append("%s|%s" % [b.name, b.transform])
	for mmi: MultiMeshInstance3D in root.find_children("*", "MultiMeshInstance3D", true, false):
		parts.append("%s|%d|%s" % [mmi.name, mmi.multimesh.instance_count, mmi.multimesh.get_instance_transform(0) if mmi.multimesh.instance_count > 0 else Transform3D()])
	parts.sort()
	return "\n".join(parts)

func _record(nm: String) -> bool:
	var path := DIR + nm + ".scn"
	var root: Node = (load(path) as PackedScene).instantiate()
	var bn := root.get_node_or_null("Buildings")
	if bn == null: root.free(); print("RECORD %s no buildings" % nm); return true
	var before := _digest(root)
	var fixed := 0; var unmatched: Array = []
	for b: Node3D in bn.get_children():
		if b.has_meta(&"kit"): continue
		var key := String(folders.get(String(b.name), ""))
		if key == "":
			var near := b.get_node_or_null("near") as MeshInstance3D
			if near and near.mesh: key = String(shapes.get(_key(near.mesh), ""))
		if key == "": unmatched.append(String(b.name)); continue
		b.set_meta(&"kit", key); fixed += 1
	if fixed == 0:
		print("RECORD %s nothing to record, unmatched %s" % [nm, unmatched]); root.free(); return true
	if _digest(root) != before:
		print("RECORD %s MISMATCH: not saved" % nm); root.free(); return false
	var ps := PackedScene.new(); ps.pack(root)
	var err := ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS)
	print("RECORD %s fixed %d, unmatched %s (%s)" % [nm, fixed, unmatched, error_string(err)])
	root.free()
	return err == OK
