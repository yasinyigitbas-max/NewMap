extends SceneTree
## Colliders true to their objects (19 Nov, Yasin: "match all colliders to their object sizes, not bigger not smaller").
## For ONE saved piece, in place (the piece is not rebuilt from its script):
##  - every prop (and tree) drawn in the piece whose kit model has a collider gets its collider rebuilt from its OWN
##    drawn near mesh, triangle for triangle (a concave shape, static only): the same size as what you see, arms and
##    sign plates where they are, nothing added round it. One shape per model and scale, shared by its instances.
##    Models the kit gives no collider (sprinklers, ground-cover patches) and items placed without one stay without.
##  - every column box added to a building (col/sc_col_*) is replaced by that building's own near-mesh triangles in the
##    box's place (the real post), so the post collides at its real size.
##  - nothing else changes: the drawn props, the buildings' meshes and kit colliders, the ground and its collider, the
##    wear decals; checked node by node against the saved file before saving, refused otherwise.
##   godot --headless --path . -s res://tools/city/pilot/exact_colliders.gd -- <piece> [--save]
const PIECES := "res://map_dc/coronado/city_kit/pieces/"

func _rel(n: Node, root: Node) -> Transform3D:
	var t := Transform3D(); var nd := n
	while nd != root and nd is Node3D:
		t = (nd as Node3D).transform * t; nd = nd.get_parent()
	return t

func _inst(mm: MultiMesh, i: int) -> Transform3D:
	var b := mm.buffer; var o := i * 12        # (headless: get_instance_transform reads back identity; the buffer holds it)
	return Transform3D(Basis(Vector3(b[o], b[o + 4], b[o + 8]), Vector3(b[o + 1], b[o + 5], b[o + 9]), Vector3(b[o + 2], b[o + 6], b[o + 10])), Vector3(b[o + 3], b[o + 7], b[o + 11]))

var _fcache := {}
func _find(dir: String, file: String) -> Array:
	var key := dir + "|" + file
	if _fcache.has(key): return _fcache[key]
	var out: Array = []
	if FileAccess.file_exists(dir.path_join(file)): out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_find(dir.path_join(sub), file))
	_fcache[key] = out
	return out

func _faces(mesh: Mesh, scale: Vector3) -> PackedVector3Array:
	var f := mesh.get_faces()
	if not scale.is_equal_approx(Vector3.ONE):
		for i in f.size(): f[i] = f[i] * scale        # per axis: a fence panel is drawn shortened along its length only
	return f

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var piece := String(a[0]); var save := a.has("--save")
	var path := PIECES + piece + ".scn"
	var root: Node3D = (load(path) as PackedScene).instantiate()
	# ---- the old prop colliders: every collision shape under a Props node (PropCol, the tree pieces' cell bodies)
	var old_bodies: Array = []; var old_shapes := 0; var old_pts: Array = []
	for body: StaticBody3D in root.find_children("*", "StaticBody3D", true, false):
		var pth := String(root.get_path_to(body))
		if not (pth.contains("Props") or pth.begins_with("PropCol")) or pth.begins_with("Buildings"): continue
		old_bodies.append(body)
		for cs: Node in body.get_children():
			if cs is CollisionShape3D:
				old_shapes += 1; old_pts.append(_rel(cs, root).origin)
	# ---- the drawn instances: (base, its near mesh, transform in the piece) for every near batch
	var drawn: Array = []
	for mmi: MultiMeshInstance3D in root.find_children("*", "MultiMeshInstance3D", true, false):
		var nm := String(mmi.name)
		if not nm.ends_with("_near"): continue
		var base := nm.trim_suffix("_near")
		for c in ["_worn", "_normal", "_dirty", "_rusty", "_new", "_clean"]: base = base.trim_suffix(c)
		var rel := _rel(mmi, root)
		for i in mmi.multimesh.instance_count: drawn.append([base, mmi.multimesh.mesh, rel * _inst(mmi.multimesh, i)])
	# which drawn items had a collider: one of the old shapes stands at (or within 1.5 m of: the kit's collider can sit off
	# the model's origin) the item, matched one to one, nearest first
	var had := []; had.resize(drawn.size()); had.fill(false)
	var used := []; used.resize(old_pts.size()); used.fill(false)
	var pairs: Array = []
	for k in drawn.size():
		var o: Vector3 = (drawn[k][2] as Transform3D).origin
		for j in old_pts.size():
			var d := Vector2(o.x - old_pts[j].x, o.z - old_pts[j].z).length()
			if d < 1.5: pairs.append([d, k, j])
	pairs.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for pr: Array in pairs:
		if had[pr[1]] or used[pr[2]]: continue
		had[pr[1]] = true; used[pr[2]] = true
	# and every drawn item whose kit model has a collider gets one too (a fence post or a palm that had none), except the
	# things meant to be walked over: sprinklers and ground-cover patches
	var NO := ["prop_sprinkler_impact", "prop_sprinkler_popup", "plant_iceplant_patch", "plant_lawn_patch"]
	var n_added := 0
	for k in drawn.size():
		var base0: String = drawn[k][0]
		if had[k] or NO.has(base0): continue
		var mp := String((drawn[k][1] as Mesh).resource_path)
		var colp := ""
		for d0 in ["res://assets/coronado_kit/props", "res://assets/coronado_kit/foliage", "res://assets/coronado_kit/fences"]:
			for f0 in _find(d0, base0 + "_col.glb"): colp = f0
		if colp != "": had[k] = true; n_added += 1
	var n_had := had.count(true)
	if n_added > 0: print("EXACT note: %d drawn items had no collider though their model has one: given one" % n_added)
	# ---- the new colliders
	var shapes := {}
	var body := StaticBody3D.new(); body.name = "PropColExact"
	var n_new := 0; var per := {}
	for k in drawn.size():
		if not had[k]: continue
		var base: String = drawn[k][0]; var mesh: Mesh = drawn[k][1]; var t: Transform3D = drawn[k][2]
		var sc := Vector3(snappedf(t.basis.x.length(), 0.0001), snappedf(t.basis.y.length(), 0.0001), snappedf(t.basis.z.length(), 0.0001))
		var key := "%s|%s|%s" % [base, mesh.resource_path, str(sc)]
		if not shapes.has(key):
			var cps := ConcavePolygonShape3D.new(); cps.set_faces(_faces(mesh, sc)); shapes[key] = cps
		var cs := CollisionShape3D.new(); cs.shape = shapes[key]
		cs.transform = Transform3D(t.basis.orthonormalized(), t.origin)
		body.add_child(cs); n_new += 1; per[base] = int(per.get(base, 0)) + 1
	# ---- column boxes: the building's own triangles in each box's place
	var n_col := 0; var n_col_kept := 0
	for b: Node3D in (root.get_node("Buildings").get_children() if root.has_node("Buildings") else []):
		var colb: Node3D = b.get_node_or_null("col")
		var near: MeshInstance3D = b.get_node_or_null("near")
		if colb == null or near == null: continue
		var faces := near.mesh.get_faces()
		for cs: Node in colb.get_children():
			if not String(cs.name).begins_with("sc_col"): continue
			# already done (a post's own triangles, or a box already set to the measured post): left as it is, so a second
			# run changes nothing
			if not ((cs as CollisionShape3D).shape is BoxShape3D) or String(cs.name).ends_with("_post"): continue
			var bx := ((cs as CollisionShape3D).shape as BoxShape3D).size
			var o := (colb.transform * (cs as CollisionShape3D).transform).origin       # in the building's frame
			var lo := o - bx * 0.5 - Vector3(0.3, 0.0, 0.3); var hi := o + bx * 0.5 + Vector3(0.3, 0.0, 0.3)
			var keep := PackedVector3Array()
			for i in range(0, faces.size(), 3):
				var inside := true
				for j in 3:
					var v := near.transform * faces[i + j]
					if v.x < lo.x or v.x > hi.x or v.z < lo.z or v.z > hi.z or v.y < lo.y - 0.05 or v.y > hi.y + 0.05: inside = false; break
				if inside: keep.append_array([near.transform * faces[i], near.transform * faces[i + 1], near.transform * faces[i + 2]])
			if keep.size() < 9:
				# the post's triangles run past the box (one tall face): the box is set to the checker's measured post
				# itself (it had added 4 cm round it)
				var nb := BoxShape3D.new(); nb.size = Vector3(maxf(bx.x - 0.04, 0.05), bx.y, maxf(bx.z - 0.04, 0.05))
				(cs as CollisionShape3D).shape = nb; cs.name = String(cs.name) + "_post"; n_col_kept += 1; continue
			var cps := ConcavePolygonShape3D.new()
			var inv := colb.transform.affine_inverse()
			for i in keep.size(): keep[i] = inv * keep[i]
			cps.set_faces(keep)
			(cs as CollisionShape3D).shape = cps; (cs as CollisionShape3D).transform = Transform3D()
			n_col += 1
	for ob: Node in old_bodies: ob.get_parent().remove_child(ob); ob.free()
	root.add_child(body)
	# ---- proof: every node that is not a collider is unchanged against the saved file
	var ref: Node3D = (load(path) as PackedScene).instantiate()
	var bad := 0; var cmp := 0
	for c: Node in ref.find_children("*", "", true, false):
		var rp := ref.get_path_to(c)
		if c is CollisionShape3D or c is StaticBody3D or String(rp).contains("PropCol") or String(rp).contains("/col"): continue
		var d := root.get_node_or_null(rp)
		var under_col := false
		var up := c.get_parent()
		while up != null and up != ref:
			if up is StaticBody3D: under_col = true
			up = up.get_parent()
		if under_col: continue
		cmp += 1
		if d == null: print("EXACT diff: %s missing" % rp); bad += 1; continue
		if c is Node3D and (c as Node3D).transform != (d as Node3D).transform: print("EXACT diff: %s moved" % rp); bad += 1
		if c is MultiMeshInstance3D and (c.multimesh.buffer != d.multimesh.buffer or c.multimesh.instance_count != d.multimesh.instance_count): print("EXACT diff: %s" % rp); bad += 1
		if c is MeshInstance3D:
			for i in c.mesh.get_surface_count():
				if c.mesh.surface_get_arrays(i) != d.mesh.surface_get_arrays(i): print("EXACT diff: %s" % rp); bad += 1
	# the ground's and the buildings' kit colliders are kept as they were
	for c: Node in ref.find_children("*", "CollisionShape3D", true, false):
		var rp := String(ref.get_path_to(c))
		if rp.contains("Props") or rp.begins_with("PropCol") or c.name.begins_with("sc_col"): continue
		var d := root.get_node_or_null(rp) as CollisionShape3D
		if d == null or d.transform != (c as CollisionShape3D).transform or d.shape.get_class() != (c as CollisionShape3D).shape.get_class(): print("EXACT diff: collider %s" % rp); bad += 1
	if bad > 0: print("EXACT refused %s: %d differences outside the colliders" % [piece, bad]); quit(); return
	print("EXACT %s: %d prop colliders replaced by %d true-size ones (%d shapes), %d column boxes -> the post's own triangles (%d set to the measured post: its faces run past the box), %d other nodes identical" % [piece, old_shapes, n_new, shapes.size(), n_col, n_col_kept, cmp])
	var bl := []
	for k: String in per: bl.append("%s %d" % [k, per[k]])
	print("EXACT %s per model: %s" % [piece, ", ".join(bl)])
	if not save: print("EXACT dry run"); quit(); return
	for c: Node in root.find_children("*", "", true, false): c.owner = root
	var ps := PackedScene.new(); ps.pack(root)
	print("EXACT saved %s: %s" % [path, error_string(ResourceSaver.save(ps, path))])
	quit()
