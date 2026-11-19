extends SceneTree
## TRUE-SHAPE PROP COLLISION in saved pieces (19 Nov night; Yasin: "check whether your collisions are actually true to
## size or not" -> "fix all of them asap"). kit_lib.Props.build gave every placed prop a CONVEX HULL of the kit's
## collision mesh, which fills every open prop solid (a bus shelter or a bandstand was a block you could not step into, a
## swing set, an arbor or a billboard a wall). kit_lib now builds the mesh as it is (ConcavePolygonShape3D, both sides);
## this tool swaps the same thing into pieces already saved, WITHOUT re-running any piece script: in each piece's PropCol
## bodies, every convex prop shape is replaced by the true shape of the prop it belongs to (found by matching the
## shapes' positions with the props' instances), and nothing else is touched. After saving it reloads the file and
## checks that every node, every prop instance and every collision shape's place are as before; a piece that fails is
## not saved. Prints "TPC <piece> swapped n of m" per changed piece, "TPC-SKIP <piece> reason" otherwise.
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/true_prop_collision.gd -- [--only=a,b]
const K := preload("res://tools/city/pilot/kit_lib.gd")
const DIR := "res://map_dc/coronado/city_kit/pieces/"
const CONDS := ["_worn_", "_normal_", "_clean_", "_rusty_", "_dirty_"]
var cache := {}

func _rel(n: Node, root: Node) -> Transform3D:
	var t := Transform3D(); var p: Node = n
	while p and p != root:
		if p is Node3D: t = (p as Node3D).transform * t
		p = p.get_parent()
	return t

func _base_of(nm: String) -> Array:
	for c: String in CONDS:
		var i := nm.find(c)
		if i > 0: return [nm.substr(0, i), c.trim_prefix("_").trim_suffix("_")]
	return []

func _true_shape(base: String, cond: String) -> Array:
	if cache.has(base): return cache[base]
	cache[base] = []
	var nf := K.prop_file(base, cond, "near")
	if nf == "": nf = K.prop_file(base, "clean", "near")
	if nf == "": return []
	var colf := nf.get_base_dir().path_join(base + "_col.glb")
	if not ResourceLoader.exists(colf): return []
	var inst: Node = (load(colf) as PackedScene).instantiate()
	var cm: MeshInstance3D = K._first_mesh(inst)
	if cm and cm.mesh:
		var tsh: ConcavePolygonShape3D = cm.mesh.create_trimesh_shape(); tsh.backface_collision = true
		cache[base] = [tsh, cm.transform]
	inst.free()
	return cache[base]

func _sig(root: Node) -> String:
	var parts: PackedStringArray = []
	for n: Node in root.find_children("*", "", true, false):
		var s := "%s:%s" % [root.get_path_to(n), n.get_class()]
		if n is MultiMeshInstance3D: s += ":%d" % (n as MultiMeshInstance3D).multimesh.instance_count
		if n is CollisionShape3D: s += ":%s" % str(((n as CollisionShape3D).transform.origin * 100.0).round())
		if n is MeshInstance3D and (n as MeshInstance3D).mesh: s += ":%d" % (n as MeshInstance3D).mesh.get_surface_count()
		parts.append(s)
	return "\n".join(parts)

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var only: PackedStringArray = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="): only = a.trim_prefix("--only=").split(",", false)
	var total := 0
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".scn"): continue
		var piece := f.get_basename()
		if only.size() > 0 and not only.has(piece): continue
		var root: Node3D = (load(DIR + f) as PackedScene).instantiate()
		var cols: Array = []
		for b: Node in root.find_children("PropCol", "StaticBody3D", true, false):
			for cs in b.get_children():
				if cs is CollisionShape3D and (cs as CollisionShape3D).shape is ConvexPolygonShape3D: cols.append(cs)
		if cols.is_empty():
			print("TPC-SKIP %s no convex prop shapes" % piece); root.free(); continue
		var before := _sig(root)
		# where each prop type stands (piece frame, 2 cm keys)
		var at := {}   # key -> [[base, cond], ...]
		for mmi: MultiMeshInstance3D in root.find_children("*", "MultiMeshInstance3D", true, false):
			var bc := _base_of(String(mmi.name))
			if bc.is_empty(): continue
			var t0 := _rel(mmi, root)
			for i in mmi.multimesh.instance_count:
				var o := (t0 * mmi.multimesh.get_instance_transform(i)).origin
				var k := "%d,%d" % [roundi(o.x * 50.0), roundi(o.z * 50.0)]
				if not at.has(k): at[k] = []
				if not (at[k] as Array).has(bc): (at[k] as Array).append(bc)
		# group the shapes by the shared shape resource (one per prop type), vote for the type
		var groups := {}
		for cs: CollisionShape3D in cols:
			var id := cs.shape.get_instance_id()
			if not groups.has(id): groups[id] = []
			(groups[id] as Array).append(cs)
		var swapped := 0; var unmatched := 0
		for id in groups:
			var votes := {}
			for cs: CollisionShape3D in groups[id]:
				var o := _rel(cs, root).origin
				var k := "%d,%d" % [roundi(o.x * 50.0), roundi(o.z * 50.0)]
				for bc: Array in at.get(k, []):
					var kk := "%s|%s" % bc
					votes[kk] = int(votes.get(kk, 0)) + 1
			var best := ""; var bn := 0
			for kk: String in votes:
				if int(votes[kk]) > bn: bn = int(votes[kk]); best = kk
			if best == "" or bn * 2 < (groups[id] as Array).size():
				unmatched += (groups[id] as Array).size(); continue
			var ts := _true_shape(best.get_slice("|", 0), best.get_slice("|", 1))
			if ts.is_empty(): unmatched += (groups[id] as Array).size(); continue
			for cs: CollisionShape3D in groups[id]:
				cs.shape = ts[0]; swapped += 1
		if swapped == 0:
			print("TPC-SKIP %s nothing matched (%d shapes)" % [piece, cols.size()]); root.free(); continue
		var after := _sig(root)
		if after != before:
			print("TPC-SKIP %s the swap changed something else: not saved" % piece); root.free(); continue
		K._own(root, root)
		var ps := PackedScene.new(); ps.pack(root)
		var err := ResourceSaver.save(ps, DIR + f, ResourceSaver.FLAG_COMPRESS)
		root.free()
		var re: Node3D = (load(DIR + f) as PackedScene).instantiate()
		var ok := _sig(re) == before
		var nconc := 0
		for b2: Node in re.find_children("PropCol", "StaticBody3D", true, false):
			for cs2 in b2.get_children():
				if cs2 is CollisionShape3D and (cs2 as CollisionShape3D).shape is ConcavePolygonShape3D: nconc += 1
		re.free()
		print("TPC %s swapped %d of %d (unmatched %d) saved %s reload %s true shapes %d" % [piece, swapped, cols.size(), unmatched, error_string(err), "same" if ok else "DIFFERENT", nconc])
		total += 1
	print("TPC_DONE pieces changed %d" % total)
	quit()
