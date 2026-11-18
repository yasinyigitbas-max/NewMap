extends SceneTree
## Take ONE prop instance out of a saved room scene (18 Nov, strip session): for a generated room where a single item no
## longer fits after a kit update (dd8d53a's grocery shelf grew and the checker's "reach" fails), without re-running or
## changing the shared generator. Everything else in the room stays byte-for-byte the same instance data.
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/rooms/room_drop_prop.gd -- <room name> <prop base> <x> <z>
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var path := "res://map_dc/coronado/city_kit/interiors/rooms/%s.scn" % a[0]
	var base := String(a[1]); var at := Vector2(float(a[2]), float(a[3]))
	var root: Node = (load(path) as PackedScene).instantiate()
	var done := 0
	for mmi: MultiMeshInstance3D in root.find_children("*", "MultiMeshInstance3D", true, false):
		if not String(mmi.name).begins_with(base): continue
		var mm := mmi.multimesh; var keep: Array = []; var cols: Array = []
		for i in mm.instance_count:
			var t := mm.get_instance_transform(i)
			if Vector2(t.origin.x, t.origin.z).distance_to(at) < 0.6: done += 1; continue
			keep.append(t)
		if keep.size() == mm.instance_count: continue
		var nm := MultiMesh.new(); nm.transform_format = MultiMesh.TRANSFORM_3D; nm.mesh = mm.mesh
		nm.instance_count = keep.size()
		for i in keep.size(): nm.set_instance_transform(i, keep[i])
		mmi.multimesh = nm
	if done == 0: print("DROP nothing found"); quit(); return
	var ps := PackedScene.new(); ps.pack(root)
	print("DROP %s: %d x %s removed, save %s" % [a[0], done, base, error_string(ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS))])
	quit()
