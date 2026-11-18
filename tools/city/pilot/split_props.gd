extends SceneTree
## Re-pack a finished piece's prop batches into spatial cells (17 Nov, Yasin: "go with the batch split").
## Why: Props.build put every instance of one prop type + tier into ONE MultiMesh. Godot measures a MultiMesh's
## visibility range to the centre of its AABB, so on a big piece small props near an edge were culled even when the
## camera stood next to them (the stadium's picnic tables never drew), and bigger props showed their mid tier up close.
## What it does: loads pieces/<name>.scn (NO piece script is re-run, nothing is re-placed), and replaces each
## MultiMeshInstance3D under "Props" whose instances span more than one CELL x CELL square with one copy per occupied
## cell (each copy under Props/cell_<tier>_<x>_<z>/, keeping the batch name) (same mesh, material, ranges, shadows; instance transforms copied verbatim). Everything else in the file is
## untouched. It checks that the multiset of (prop batch, instance transform) is identical before and after, and
## refuses to save otherwise. Prints SPLIT <piece> batches a -> b.
## Run (real renderer: MultiMesh data lives in it):
##   xvfb-run -a godot --path PV --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/split_props.gd -- <piece> ...
const CELL := 64.0      # near cells: a prop is at most 45 m from its batch centre, inside the 60 m small-prop range
const DIR := "res://map_dc/coronado/city_kit/pieces/"

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var names: Array = []
	for a in OS.get_cmdline_user_args(): names.append(a)
	var bad := 0
	for nm: String in names:
		if not _split(nm): bad += 1
	print("SPLIT_DONE failed=%d" % bad)
	quit(1 if bad > 0 else 0)

func _digest(props: Node) -> Dictionary:
	var d := {}
	for c in props.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := c as MultiMeshInstance3D
		var key := String(mmi.name)
		for i in mmi.multimesh.instance_count:
			var t := (mmi.get_parent() as Node3D).transform * mmi.transform * mmi.multimesh.get_instance_transform(i) if mmi.get_parent() != props else mmi.transform * mmi.multimesh.get_instance_transform(i)
			var k := "%s|%s" % [key, _tkey(t)]
			d[k] = int(d.get(k, 0)) + 1
	return d

func _tkey(t: Transform3D) -> String:
	return "%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f" % [t.origin.x, t.origin.y, t.origin.z, t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z]

func _split(nm: String) -> bool:
	var path := DIR + nm + ".scn"
	if not ResourceLoader.exists(path): print("SPLIT %s missing" % nm); return false
	var root: Node = (load(path) as PackedScene).instantiate()
	var props := root.get_node_or_null("Props")
	if props == null: print("SPLIT %s no Props: unchanged" % nm); root.free(); return true
	var before := _digest(props)
	var n0 := 0; var n1 := 0
	if props.get_children().any(func(x: Node) -> bool: return String(x.name).begins_with("cell_")):
		print("SPLIT %s already split: unchanged" % nm); root.free(); return true
	for c in props.get_children():
		if not (c is MultiMeshInstance3D): continue
		var mmi := c as MultiMeshInstance3D
		n0 += 1
		var mm := mmi.multimesh
		# cell size by tier: near (and near-only small props, 60 m range) 50 m; mid (58-222 m) 100 m; far (to 1500 m)
		# stays one batch - its centre error is tiny against its range
		var tier := String(mmi.name).get_slice("_", String(mmi.name).get_slice_count("_") - 1)
		var cell := CELL if tier == "near" else (128.0 if tier == "mid" else 1e9)
		# only a batch whose props can be further from its centre than the safe offset is split (45 m near, 90 m mid);
		# cells are anchored at the batch's own corner so a small batch across the piece origin is not cut in four
		var lo := Vector2(INF, INF); var hi := Vector2(-INF, -INF)
		for i0 in mm.instance_count:
			var o0 := (mmi.transform * mm.get_instance_transform(i0)).origin
			lo = lo.min(Vector2(o0.x, o0.z)); hi = hi.max(Vector2(o0.x, o0.z))
		if (hi - lo).length() * 0.5 <= cell * 0.7: n1 += 1; continue
		var cells := {}
		for i in mm.instance_count:
			var o := (mmi.transform * mm.get_instance_transform(i)).origin
			var key := Vector2i(floori((o.x - lo.x) / cell), floori((o.z - lo.y) / cell))
			if not cells.has(key): cells[key] = []
			(cells[key] as Array).append(i)
		if cells.size() <= 1: n1 += 1; continue
		for key: Vector2i in cells:
			var ids: Array = cells[key]
			var nm2 := MultiMesh.new(); nm2.transform_format = mm.transform_format; nm2.mesh = mm.mesh
			nm2.use_colors = mm.use_colors; nm2.use_custom_data = mm.use_custom_data
			nm2.instance_count = ids.size()
			for j in ids.size():
				var i2: int = ids[j]
				nm2.set_instance_transform(j, mm.get_instance_transform(i2))
				if mm.use_colors: nm2.set_instance_color(j, mm.get_instance_color(i2))
				if mm.use_custom_data: nm2.set_instance_custom_data(j, mm.get_instance_custom_data(i2))
			var dup := mmi.duplicate() as MultiMeshInstance3D
			dup.multimesh = nm2
			# a cell node keeps the batch name exact (tools find batches by "<base>_<cond>_<tier>")
			var cname := "cell_%s_%d_%d" % [tier, key.x, key.y]
			var cn := props.get_node_or_null(cname) as Node3D
			if cn == null:
				cn = Node3D.new(); cn.name = cname; props.add_child(cn); cn.owner = root
			cn.add_child(dup)
			dup.name = String(mmi.name)
			dup.owner = root
			n1 += 1
		props.remove_child(mmi); mmi.free()
	var after := _digest(props)
	if before.size() != after.size():
		print("SPLIT %s MISMATCH before %d after %d: not saved" % [nm, before.size(), after.size()]); root.free(); return false
	for k in before:
		if int(after.get(k, -1)) != int(before[k]): print("SPLIT %s MISMATCH at %s: not saved" % [nm, k]); root.free(); return false
	var ps := PackedScene.new(); ps.pack(root)
	var err := ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS)
	print("SPLIT %s batches %d -> %d, instances %d identical (%s)" % [nm, n0, n1, before.size(), error_string(err)])
	root.free()
	return err == OK
