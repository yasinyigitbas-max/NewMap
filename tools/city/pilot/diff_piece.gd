extends SceneTree
## What changed in a rebuilt piece (17 Nov, for every unlock -> fix -> relock): compares two saved .scn files and
## prints, per prop batch, instances added / removed / moved (with their positions), the ground mesh per surface
## (triangle counts), decal / building counts. Run with the real renderer (MultiMesh data):
##   xvfb-run -a godot --path PV --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/diff_piece.gd -- <old.scn> <new.scn>
## Prints DIFF lines, then "DIFF_DONE n changes".

func _init() -> void: _run.call_deferred()

func _batches(root: Node) -> Dictionary:
	var out := {}
	for mmi: MultiMeshInstance3D in root.find_children("*", "MultiMeshInstance3D", true, false):
		var nm := String(mmi.name)
		if not out.has(nm): out[nm] = []
		var mm := mmi.multimesh
		for i in mm.instance_count:
			var t := mmi.global_transform * mm.get_instance_transform(i) if mmi.is_inside_tree() else _gt(mmi) * mm.get_instance_transform(i)
			(out[nm] as Array).append(t)
	return out

func _gt(n: Node3D) -> Transform3D:
	var t := n.transform; var p := n.get_parent()
	while p is Node3D: t = (p as Node3D).transform * t; p = p.get_parent()
	return t

func _ground(root: Node) -> Dictionary:
	var out := {}
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or not (mi.mesh is ArrayMesh): continue
		var m := mi.mesh as ArrayMesh
		for s in m.get_surface_count():
			var key := "%s/%s" % [mi.name, m.surface_get_name(s)]
			out[key] = m.surface_get_array_index_len(s) / 3 if m.surface_get_array_index_len(s) > 0 else m.surface_get_array_len(s) / 3
	return out

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var a: Node = (load(args[0]) as PackedScene).instantiate()
	var b: Node = (load(args[1]) as PackedScene).instantiate()
	var n := 0
	var ba := _batches(a); var bb := _batches(b)
	var names := {}
	for k in ba: names[k] = true
	for k in bb: names[k] = true
	for k: String in names:
		var la: Array = ba.get(k, []); var lb: Array = bb.get(k, [])
		var used := {}
		var moved: Array = []; var removed: Array = []
		for t: Transform3D in la:
			var hit := -1
			for j in lb.size():
				if used.has(j): continue
				if (lb[j] as Transform3D).is_equal_approx(t): hit = j; break
			if hit >= 0: used[hit] = true
			else: removed.append(t)
		var added: Array = []
		for j in lb.size():
			if not used.has(j): added.append(lb[j])
		# pair removed/added as "moved" when the nearest is within 5 m
		for t: Transform3D in removed.duplicate():
			var best := -1; var bd := 5.0
			for j in added.size():
				var d := (added[j] as Transform3D).origin.distance_to(t.origin)
				if d < bd: bd = d; best = j
			if best >= 0:
				moved.append([t.origin, (added[best] as Transform3D).origin]); removed.erase(t); added.remove_at(best)
		for m: Array in moved:
			print("DIFF moved   %s %s -> %s (%.2f m)" % [k, _v(m[0]), _v(m[1]), (m[0] as Vector3).distance_to(m[1])]); n += 1
		for t: Transform3D in removed:
			print("DIFF removed %s %s" % [k, _v(t.origin)]); n += 1
		for t: Transform3D in added:
			print("DIFF added   %s %s" % [k, _v(t.origin)]); n += 1
	var ga := _ground(a); var gb := _ground(b)
	for k: String in ga:
		if not gb.has(k) or gb[k] != ga[k]:
			print("DIFF surface %s %s -> %s tris" % [k, ga[k], gb.get(k, 0)]); n += 1
	for k: String in gb:
		if not ga.has(k):
			print("DIFF surface %s new, %s tris" % [k, gb[k]]); n += 1
	var bla := a.get_node_or_null("Buildings"); var blb := b.get_node_or_null("Buildings")
	var ca := bla.get_child_count() if bla else 0; var cb := blb.get_child_count() if blb else 0
	if ca != cb: print("DIFF buildings %d -> %d" % [ca, cb]); n += 1
	print("DIFF_DONE %d changes" % n)
	a.free(); b.free()
	quit()

func _v(p: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
