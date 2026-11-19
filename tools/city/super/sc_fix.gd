extends SceneTree
## Superchecker, part 3: change the LISTED items of one saved piece or room, and PROVE nothing else changed
## (19 Nov 2026, Yasin: "changes irregularities that they find by hand and checks that nothing else other than the
## irregularity was changed? THIS TOOL MUSTNT CHANGE THE ENTIRE BLOCK WITH A GENERATOR").
##
## It never runs a piece's building script and never places anything by a rule. It loads the SAVED scene, and for
## each line of a fix list does one of three things to ONE item:
##   move          one prop: its instance in every detail tier and its collider go to a new place / turn
##   remove        one prop: its instance in every tier and its collider are taken out
##   remove_decal  one wear mark (its six vertices) is taken out of the piece's "wear" mesh
##   add_collider  one prop that has no collision gets one: the kit's own collision shape for that prop (as kit_lib gives
##                 every other prop), or a box of the prop's own size where the kit ships none
##   add_box       one column or post of a building gets a collision box, under that building's own collision body
##   fill_well     one tree well whose tree was taken out is paved level in its rim's own material (sc_wells.gd: the
##                 runtime bake's own well filler), and the ground's collision is lifted with it
## The fix list is a plain file, one line per item, each with the item's own position, its new position and a reason.
##
##   --apply --in=<scn> --fixes=<json> --out=<scn>     writes a NEW file; <in> is never written
##   --prove --old=<scn> --new=<scn> --fixes=<json>    loads both files from disk and compares EVERYTHING in them:
##       every node (place, class, notes, visibility), every mesh (all its numbers), every prop instance of every
##       batch and tier, every collider, every light. What differs must be exactly the listed items, each by exactly
##       the listed amount. One line per change, then "PROOF RESULT PASS" or "PROOF RESULT FAIL" with what is left over.
##       The proof does not use the fixer's own search: it starts from the raw differences between the two files.
## Real renderer (MultiMesh and mesh data are empty under --headless).
const EPS := 0.002
const Wells := preload("res://tools/city/super/sc_wells.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")

func _init() -> void: _run.call_deferred()

func _arg(name: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="): return a.trim_prefix("--" + name + "=")
	return ""

func _load(path: String) -> Node:
	var ps := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	return ps.instantiate() if ps else null

func _run() -> void:
	# a room's sign plate is a compressed picture stored INSIDE the room's file. Godot drops such a picture's data after
	# loading unless told to keep it, and a re-saved room then has a blank sign (the proof caught this on 19 Nov).
	PortableCompressedTexture2D.set_keep_all_compressed_buffers(true)
	var args := OS.get_cmdline_user_args()
	var fx: Variant = JSON.parse_string(FileAccess.get_file_as_string(_arg("fixes")))
	if not (fx is Dictionary) or not (fx as Dictionary).has("fixes"): print("SC-FIX cannot read the fix list"); quit(2); return
	var fixes: Array = fx["fixes"]
	if "--apply" in args:
		var top := _load(_arg("in"))
		if top == null: print("SC-FIX cannot load %s" % _arg("in")); quit(2); return
		var bad := 0; var done: Array = []
		for f: Dictionary in fixes:
			var msg := _apply(top, f)
			if msg == "": done.append(f); continue
			# a well line may say "if_well": the finder cannot tell a well from a bed, the well filler can
			if String(f.get("op", "")) == "fill_well" and bool(f.get("if_well", false)): print("SC-FIX skipped #%d: %s" % [int(f.get("n", 0)), msg]); continue
			print("SC-FIX REFUSED #%d %s: %s" % [int(f.get("n", 0)), str(f.get("op", "")), msg]); bad += 1
		if bad > 0:
			print("SC-FIX %d of %d lines refused: nothing saved" % [bad, fixes.size()]); top.free(); quit(1); return
		var ps := PackedScene.new(); ps.pack(top)
		var err := ResourceSaver.save(ps, _arg("out"), ResourceSaver.FLAG_COMPRESS)
		if _arg("applied") != "":      # the lines that were really carried out: the proof is run against these
			var fa := FileAccess.open(_arg("applied"), FileAccess.WRITE); fa.store_string(JSON.stringify({"scene": fx.get("scene", ""), "fixes": done}, " ")); fa.close()
		print("SC-FIX applied %d of %d lines, saved %s (%s)" % [done.size(), fixes.size(), _arg("out"), error_string(err)])
		top.free(); quit(0 if err == OK else 1); return
	if "--prove" in args:
		var a := _load(_arg("old")); var b := _load(_arg("new"))
		if a == null or b == null: print("PROOF cannot load the files"); print("PROOF RESULT FAIL"); quit(1); return
		var ok := _prove(a, b, fixes)
		a.free(); b.free()
		quit(0 if ok else 1); return
	print("SC-FIX needs --apply or --prove"); quit(2)

# ------------------------------------------------------------------------------------------------ shared small things
func _rel(n: Node, top: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var p := n
	while p != top and p != null:
		if p is Node3D: t = (p as Node3D).transform * t
		p = p.get_parent()
	return t

func _v3(a: Variant) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

## "<base>_<cond>_<tier>" -> [base, cond, tier]; a room's batch is just "<base>"
func _parse(nm: String) -> Array:
	var parts := nm.split("_")
	if parts.size() >= 3 and parts[parts.size() - 1] in ["near", "mid", "far"]:
		return ["_".join(parts.slice(0, parts.size() - 2)), parts[parts.size() - 2], parts[parts.size() - 1]]
	return [nm, "", ""]

func _batches_of(top: Node, base: String, cond: String) -> Array:
	var out: Array = []
	for mmi: MultiMeshInstance3D in top.find_children("*", "MultiMeshInstance3D", true, false):
		var p := _parse(String(mmi.name))
		if p[0] == base and (cond == "" or p[1] == cond) and mmi.multimesh: out.append(mmi)
	return out

func _delta(f: Dictionary) -> Transform3D:
	var at := _v3(f["at"]); var to := _v3(f.get("to", f["at"]))
	var turn := deg_to_rad(float(f.get("turn", 0.0)))
	return Transform3D(Basis.IDENTITY, to) * Transform3D(Basis(Vector3.UP, turn), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -at)

# ------------------------------------------------------------------------------------------------ apply
func _apply(top: Node, f: Dictionary) -> String:
	var op := String(f.get("op", ""))
	if op == "remove_decal": return _apply_decal(top, f)
	if op == "fill_well": return _apply_well(top, f)
	if op == "add_collider": return _apply_collider(top, f)
	if op == "add_box": return _apply_box(top, f)
	if op != "move" and op != "remove": return "unknown kind of change"
	var base := String(f.get("base", "")); var cond := String(f.get("cond", ""))
	var at := _v3(f["at"])
	var mmis := _batches_of(top, base, cond)
	if mmis.is_empty(): return "no batch of %s %s in this scene" % [base, cond]
	# per tier: the one instance whose origin is the listed place
	var tiers := {}       # tier -> [total instances, Array of [mmi, index]]
	var near_xf := Transform3D.IDENTITY; var have_near := false
	for mmi: MultiMeshInstance3D in mmis:
		var tier := String(_parse(String(mmi.name))[2])
		if not tiers.has(tier): tiers[tier] = [0, []]
		var rel := _rel(mmi, top); var mm := mmi.multimesh
		tiers[tier][0] = int(tiers[tier][0]) + mm.instance_count
		for i in mm.instance_count:
			var t := rel * mm.get_instance_transform(i)
			if t.origin.distance_to(at) <= EPS: (tiers[tier][1] as Array).append([mmi, i])
	var want := int(f.get("nth", 0))
	for tier: String in tiers:
		var hits: Array = tiers[tier][1]
		if hits.is_empty(): return "tier '%s' of %s has no instance at %s" % [tier, base, str(at)]
		if hits.size() > 1 and not f.has("nth"): return "%d instances of %s at the same spot in tier '%s': say which with nth" % [hits.size(), base, tier]
		if want >= hits.size(): return "nth %d but only %d there" % [want, hits.size()]
	var D := _delta(f)
	if tiers.has("near"):
		var h: Array = (tiers["near"][1] as Array)[want]
		near_xf = _rel(h[0], top) * (h[0] as MultiMeshInstance3D).multimesh.get_instance_transform(int(h[1])); have_near = true
	else:
		var tk: String = tiers.keys()[0]
		var h2: Array = (tiers[tk][1] as Array)[want]
		near_xf = _rel(h2[0], top) * (h2[0] as MultiMeshInstance3D).multimesh.get_instance_transform(int(h2[1])); have_near = true
	# the collider: among the colliders at this spot, the one whose shape group belongs to this prop type
	var col: CollisionShape3D = null
	var pc := top.get_node_or_null("Props/PropCol")
	if pc:
		var origins: Array = []
		for mmi: MultiMeshInstance3D in mmis:
			if String(_parse(String(mmi.name))[2]) != ("near" if tiers.has("near") else String(tiers.keys()[0])): continue
			var rel2 := _rel(mmi, top)
			for i in mmi.multimesh.instance_count: origins.append((rel2 * mmi.multimesh.get_instance_transform(i)).origin)
		var groups := {}      # shape id -> [members, members on one of this type's instances]
		var here: Array = []
		for cs: Node in pc.get_children():
			if not (cs is CollisionShape3D): continue
			var c := cs as CollisionShape3D
			var o := _rel(c, top).origin
			var gid := c.shape.get_instance_id() if c.shape else 0
			if not groups.has(gid): groups[gid] = [0, 0]
			groups[gid][0] = int(groups[gid][0]) + 1
			if o.distance_to(at) <= EPS: here.append(c)
		if not here.is_empty():
			var grid := {}
			for o2: Vector3 in origins: grid[Vector3i(roundi(o2.x * 100.0), roundi(o2.y * 100.0), roundi(o2.z * 100.0))] = true
			for cs: Node in pc.get_children():
				if not (cs is CollisionShape3D): continue
				var c2 := cs as CollisionShape3D
				var o3 := _rel(c2, top).origin
				if grid.has(Vector3i(roundi(o3.x * 100.0), roundi(o3.y * 100.0), roundi(o3.z * 100.0))):
					var g2 := c2.shape.get_instance_id() if c2.shape else 0
					groups[g2][1] = int(groups[g2][1]) + 1
			var best := -1.0
			for c3: CollisionShape3D in here:
				var g3 := c3.shape.get_instance_id() if c3.shape else 0
				var share := float(groups[g3][1]) / maxf(1.0, float(groups[g3][0]))
				if share > best: best = share; col = c3
			if best < 0.8:
				if here.size() > 1: return "cannot tell which of %d colliders at this spot is this prop's" % here.size()
				col = here[0] if best >= 0.5 else null
	if op == "move":
		if f.has("turn") and absf(float(f["turn"])) > 360.0: return "turn out of range"
		for tier: String in tiers:
			var h3: Array = (tiers[tier][1] as Array)[want]
			var mmi2 := h3[0] as MultiMeshInstance3D
			var rel3 := _rel(mmi2, top)
			var t_old := rel3 * mmi2.multimesh.get_instance_transform(int(h3[1]))
			mmi2.multimesh.set_instance_transform(int(h3[1]), rel3.affine_inverse() * (D * t_old))
		if col:
			var relc := _rel(col.get_parent(), top)
			col.transform = relc.affine_inverse() * (D * (relc * col.transform))
		return ""
	# remove
	for tier: String in tiers:
		var h4: Array = (tiers[tier][1] as Array)[want]
		_take_out(h4[0] as MultiMeshInstance3D, int(h4[1]))
	if col:
		col.get_parent().remove_child(col); col.free()
	return ""

func _take_out(mmi: MultiMeshInstance3D, idx: int) -> void:
	var mm := mmi.multimesh
	var n := mm.instance_count
	if n <= 1:
		mmi.get_parent().remove_child(mmi); mmi.free(); return
	var ts: Array = []; var cs: Array = []; var ds: Array = []
	for i in n:
		if i == idx: continue
		ts.append(mm.get_instance_transform(i))
		if mm.use_colors: cs.append(mm.get_instance_color(i))
		if mm.use_custom_data: ds.append(mm.get_instance_custom_data(i))
	mm.instance_count = n - 1
	for i in n - 1:
		mm.set_instance_transform(i, ts[i])
		if mm.use_colors: mm.set_instance_color(i, cs[i])
		if mm.use_custom_data: mm.set_instance_custom_data(i, ds[i])

var _col_shapes := {}      # prop type -> [shape, its own transform] (one shared shape a type, as kit_lib does)

## the collision of ONE prop that has none
func _apply_collider(top: Node, f: Dictionary) -> String:
	var base := String(f.get("base", "")); var cond := String(f.get("cond", "")); var at := _v3(f["at"])
	var props := top.get_node_or_null("Props")
	if props == null: return "this scene has no Props"
	var inst := Transform3D.IDENTITY; var mesh: Mesh = null; var found := false
	for mmi: MultiMeshInstance3D in _batches_of(top, base, cond):
		if String(_parse(String(mmi.name))[2]) != "near": continue
		var rel := _rel(mmi, top)
		for i in mmi.multimesh.instance_count:
			var t := rel * mmi.multimesh.get_instance_transform(i)
			if t.origin.distance_to(at) <= EPS: inst = t; mesh = mmi.multimesh.mesh; found = true; break
		if found: break
	if not found: return "no %s at %s" % [base, str(at)]
	var pc := props.get_node_or_null("PropCol") as StaticBody3D
	if pc:
		for cs: Node in pc.get_children():
			if cs is CollisionShape3D and _rel(cs, top).origin.distance_to(at) <= 0.03: return "it already has a collision"
	else:
		pc = StaticBody3D.new(); pc.name = "PropCol"; props.add_child(pc); pc.owner = top
	if not _col_shapes.has(base):
		_col_shapes[base] = []
		var nf: String = K.prop_file(base, cond if cond != "" else "clean", "near")
		var colf := nf.get_base_dir().path_join(base + "_col.glb")
		if nf != "" and ResourceLoader.exists(colf):
			var sc: Node = (load(colf) as PackedScene).instantiate()
			var cm: MeshInstance3D = K._first_mesh(sc)
			var src_t := Transform3D.IDENTITY
			var ns: Node = (load(nf) as PackedScene).instantiate()
			var nm: MeshInstance3D = K._first_mesh(ns)
			if nm: src_t = nm.transform
			if cm and cm.mesh: _col_shapes[base] = [cm.mesh.create_convex_shape(true, true), cm.transform, src_t]
			sc.free(); ns.free()
	var c := CollisionShape3D.new()
	var rec: Array = _col_shapes[base]
	var to_pc := _rel(pc, top).affine_inverse()
	if rec.size() == 3:
		# the prop's own place without its size factor, as kit_lib sets colliders (physics dislikes scaled shapes)
		var t0 := inst * (rec[2] as Transform3D).affine_inverse()
		c.shape = rec[0]; c.transform = to_pc * Transform3D(t0.basis.orthonormalized(), t0.origin) * (rec[1] as Transform3D)
	else:
		if mesh == null: return "no mesh to size a box from"
		var ab := mesh.get_aabb()
		var bx := BoxShape3D.new(); bx.size = (ab.size * inst.basis.get_scale()).max(Vector3(0.05, 0.05, 0.05))
		c.shape = bx; c.transform = to_pc * Transform3D(inst.basis.orthonormalized(), inst * ab.get_center())
	pc.add_child(c); c.owner = top
	return ""

## a collision box for ONE column or post of a building, under that building's own collision body
func _apply_box(top: Node, f: Dictionary) -> String:
	var b := top.get_node_or_null(String(f.get("node", ""))) as Node3D
	if b == null: return "no building at '%s'" % String(f.get("node", ""))
	var bx: Array = f.get("box", [])
	if bx.size() != 6: return "the box needs six numbers"
	var body := b.get_node_or_null("col") as StaticBody3D
	if body == null:
		body = StaticBody3D.new(); body.name = "col"; b.add_child(body); body.owner = top
	var nm := String(f.get("name", "sc_col"))
	if body.get_node_or_null(nm) != null: return "a box of that name is already there"
	var sh := BoxShape3D.new(); sh.size = Vector3(float(bx[3]), float(bx[4]), float(bx[5]))
	var c := CollisionShape3D.new(); c.name = nm; c.shape = sh
	c.transform = body.transform.affine_inverse() * Transform3D(Basis.IDENTITY, Vector3(float(bx[0]), float(bx[1]), float(bx[2])))
	body.add_child(c); c.owner = top
	return ""

func _apply_well(top: Node, f: Dictionary) -> String:
	var mi := top.get_node_or_null(String(f.get("ground", "ground"))) as MeshInstance3D
	if mi == null or mi.mesh == null: return "no ground mesh at '%s'" % String(f.get("ground", "ground"))
	var rel := _rel(mi, top)
	var res: Array = Wells.fill_wells(mi.mesh, [rel.affine_inverse() * _v3(f["at"])])
	if (res[1] as Array).is_empty(): return "no tree well found at %s (a bed, grass, or an odd shape)" % str(_v3(f["at"]))
	mi.mesh = res[0]
	# the ground's own collision: the soil lifted, the rim's face gone
	for body: Node in mi.get_parent().get_children():
		if not (body is StaticBody3D) or not String(body.name).begins_with("ground_col"): continue
		for cs: Node in body.get_children():
			if not (cs is CollisionShape3D) or not ((cs as CollisionShape3D).shape is ConcavePolygonShape3D): continue
			var to_shape := _rel(cs, top).affine_inverse() * rel
			var wl: Array = []
			for w: Array in res[1]:
				var g: Vector3 = to_shape.basis * Vector3(float(w[2]), 0.0, float(w[3]))
				wl.append([to_shape * (w[0] as Vector3), float(w[1]), g.x, g.z])
			(cs as CollisionShape3D).shape = Wells.lift_faces((cs as CollisionShape3D).shape as ConcavePolygonShape3D, wl)
	return ""

func _apply_decal(top: Node, f: Dictionary) -> String:
	var mi := top.get_node_or_null(String(f.get("wear", "wear"))) as MeshInstance3D
	if mi == null or mi.mesh == null: return "no wear mesh at '%s'" % String(f.get("wear", "wear"))
	var am := mi.mesh as ArrayMesh
	var si := int(f.get("surface", 0))
	if am == null or si >= am.get_surface_count(): return "wear mesh has no such surface"
	var arr := am.surface_get_arrays(si)
	if arr[Mesh.ARRAY_INDEX] != null: return "this wear mesh is indexed: not handled"
	var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	if vv.size() % 6 != 0: return "wear mesh is not made of six-vertex marks"
	var at := _v3(f["at"]); var rel := _rel(mi, top)
	var hit := -1; var hits := 0
	for k in vv.size() / 6:
		var c := Vector3.ZERO
		for q in 6: c += rel * vv[k * 6 + q]
		if (c / 6.0).distance_to(at) <= EPS:
			hits += 1
			if hit < 0: hit = k
	if hit < 0: return "no mark centred at %s" % str(at)
	if hits > 1 and not f.has("nth"): return "%d marks centred on the same spot: say which with nth" % hits
	var fresh := ArrayMesh.new()
	for s in am.get_surface_count():
		var a2 := am.surface_get_arrays(s)
		if s == si:
			for ch in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
				if a2[ch] == null: continue
				var per := 4 if ch == Mesh.ARRAY_TANGENT else 1
				var src: Variant = a2[ch]
				var dst: Variant = src.slice(0, hit * 6 * per)
				dst.append_array(src.slice((hit + 1) * 6 * per))
				a2[ch] = dst
			if (a2[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
				mi.get_parent().remove_child(mi); mi.free(); return ""
		fresh.add_surface_from_arrays(am.surface_get_primitive_type(s), a2)
		fresh.surface_set_material(s, am.surface_get_material(s))
		fresh.surface_set_name(s, am.surface_get_name(s))
	mi.mesh = fresh
	return ""

# ------------------------------------------------------------------------------------------------ the proof
func _f(x: float) -> String: return "%.5f" % x
func _tk(t: Transform3D) -> String:
	return "%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f" % [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z, t.origin.x, t.origin.y, t.origin.z]

func _sha(v: Variant) -> String:
	var h := HashingContext.new(); h.start(HashingContext.HASH_SHA1); h.update(var_to_bytes(v)); return h.finish().hex_encode().substr(0, 16)

var _mesh_cache := {}
func _mesh_key(m: Mesh) -> String:
	if m == null: return "none"
	var id := m.get_instance_id()
	if _mesh_cache.has(id): return _mesh_cache[id]
	var parts := PackedStringArray()
	for s in m.get_surface_count():
		parts.append(_sha(m.surface_get_arrays(s)) + ":" + _mat_key(m.surface_get_material(s)) + ":" + (String((m as ArrayMesh).surface_get_name(s)) if m is ArrayMesh else ""))
	var k := "|".join(parts)
	_mesh_cache[id] = k
	return k

## a texture by its file, or - when it is stored inside the scene (a room's sign plate) - by its own pixels
func _tex_key(t: Texture2D) -> String:
	if t == null: return ""
	if t.resource_path != "" and not t.resource_path.contains("::"): return t.resource_path
	var img := t.get_image()
	if img == null: return "inside:%dx%d" % [t.get_width(), t.get_height()]
	return "inside:%dx%d:%d:%s" % [img.get_width(), img.get_height(), img.get_format(), _sha(img.get_data())]

func _mat_key(m: Material) -> String:
	if m == null: return "nomat"
	if m.resource_path != "" and not m.resource_path.contains("::"): return m.resource_path
	var s := m.get_class()
	if m is BaseMaterial3D:
		var b := m as BaseMaterial3D
		s += "/%s/%s/%s/%s/%d/%d" % [str(b.albedo_color), _tex_key(b.albedo_texture), _f(b.roughness), _f(b.metallic), b.transparency, b.cull_mode]
	elif m is ShaderMaterial:
		var sm := m as ShaderMaterial
		s += "/" + (sm.shader.resource_path if sm.shader else "")
		if sm.shader:
			for u: Dictionary in sm.shader.get_shader_uniform_list():
				var v: Variant = sm.get_shader_parameter(u["name"])
				s += "/%s=%s" % [u["name"], (_tex_key(v as Texture2D) if v is Texture2D else (v as Resource).resource_path) if v is Resource else str(v)]
	return s

func _shape_key(sh: Shape3D) -> String:
	if sh == null: return "noshape"
	if sh is ConvexPolygonShape3D: return "convex:" + _sha((sh as ConvexPolygonShape3D).points)
	if sh is ConcavePolygonShape3D: return "concave:" + _sha((sh as ConcavePolygonShape3D).get_faces())
	if sh is BoxShape3D: return "box:" + str((sh as BoxShape3D).size)
	return sh.get_class()

## everything in a scene as a bag of lines. Returns [bag: line -> count, info: line -> small record for the changes]
func _digest(top: Node) -> Array:
	var bag := {}; var info := {}
	var stack: Array = [top]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		var path := String(top.get_path_to(n))
		var is_propcol := n is CollisionShape3D and n.get_parent() != null and String(n.get_parent().name) == "PropCol"
		var line := ""
		if is_propcol:
			var t := _rel(n, top)
			line = "C|" + _tk(t) + "|" + _shape_key((n as CollisionShape3D).shape)
			info[line] = {"k": "C", "t": t}
		else:
			var metas := PackedStringArray()
			for m in n.get_meta_list(): metas.append("%s=%s" % [m, var_to_str(n.get_meta(m))])
			line = "N|%s|%s|%s|%s" % [path, n.get_class(), _tk((n as Node3D).transform) if n is Node3D else "-", _sha(metas)]
			if n is GeometryInstance3D:
				var g := n as GeometryInstance3D
				line += "|vis %s %s %s %s %d %d|%s" % [_f(g.visibility_range_begin), _f(g.visibility_range_end), _f(g.visibility_range_begin_margin), _f(g.visibility_range_end_margin), g.visibility_range_fade_mode, g.cast_shadow, _mat_key(g.material_override)]
			if n is Node3D: line += "|shown %s" % str((n as Node3D).visible)
			if n is CollisionObject3D: line += "|layers %d %d" % [(n as CollisionObject3D).collision_layer, (n as CollisionObject3D).collision_mask]
			var gcol := n is CollisionShape3D and (n as CollisionShape3D).shape is ConcavePolygonShape3D and String(n.get_parent().name).begins_with("ground_col")
			if gcol:
				var sh := (n as CollisionShape3D).shape as ConcavePolygonShape3D
				line += "|ground collision, by face, backface %s" % str(sh.backface_collision)
				var relc := _rel(n, top); var ff := sh.get_faces()
				for t in ff.size() / 3:
					var a3 := relc * ff[t * 3]; var b3 := relc * ff[t * 3 + 1]; var c3 := relc * ff[t * 3 + 2]
					var gl := "GC|%s|%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f" % [path, a3.x, a3.y, a3.z, b3.x, b3.y, b3.z, c3.x, c3.y, c3.z]
					bag[gl] = int(bag.get(gl, 0)) + 1
					info[gl] = {"k": "GC", "v": [a3, b3, c3]}
			elif n is CollisionShape3D: line += "|" + _shape_key((n as CollisionShape3D).shape)
			if n is Light3D:
				var l := n as Light3D
				line += "|light %s %s %s %s %s" % [str(l.light_color), _f(l.light_energy), _f((l as OmniLight3D).omni_range) if l is OmniLight3D else "-", _f((l as OmniLight3D).omni_attenuation) if l is OmniLight3D else "-", str(l.shadow_enabled)]
			if n.get_script() != null: line += "|script " + (n.get_script() as Script).resource_path
			if n is MultiMeshInstance3D:
				var mmi := n as MultiMeshInstance3D; var mm := mmi.multimesh
				line += "|batch mesh %s fmt %d col %s cus %s" % [_mesh_key(mm.mesh) if mm else "none", mm.transform_format if mm else -1, str(mm.use_colors) if mm else "-", str(mm.use_custom_data) if mm else "-"]
				info[line] = {"k": "B", "path": path}
				if mm:
					var rel := _rel(mmi, top)
					for i in mm.instance_count:
						var t2 := rel * mm.get_instance_transform(i)
						var il := "I|%s|%s" % [path, _tk(t2)]
						if mm.use_colors: il += "|" + str(mm.get_instance_color(i))
						if mm.use_custom_data: il += "|" + str(mm.get_instance_custom_data(i))
						bag[il] = int(bag.get(il, 0)) + 1
						info[il] = {"k": "I", "path": path, "name": String(mmi.name), "t": t2}
			elif n is MeshInstance3D:
				var mi := n as MeshInstance3D
				if String(mi.name) == "wear" and mi.mesh and mi.mesh is ArrayMesh:
					var am := mi.mesh as ArrayMesh
					line += "|wear surfaces %d" % am.get_surface_count()
					info[line] = {"k": "WN", "path": path}
					var rel2 := _rel(mi, top)
					for s in am.get_surface_count():
						var arr := am.surface_get_arrays(s)
						var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
						line += "|" + _mat_key(am.surface_get_material(s))
						if arr[Mesh.ARRAY_INDEX] != null or vv.size() % 6 != 0:
							line += "|whole " + _sha(arr); continue
						var uv: Variant = arr[Mesh.ARRAY_TEX_UV]; var cc: Variant = arr[Mesh.ARRAY_COLOR]; var nn: Variant = arr[Mesh.ARRAY_NORMAL]
						for k in vv.size() / 6:
							var rec := [vv.slice(k * 6, k * 6 + 6), uv.slice(k * 6, k * 6 + 6) if uv != null else null, cc.slice(k * 6, k * 6 + 6) if cc != null else null, nn.slice(k * 6, k * 6 + 6) if nn != null else null]
							var c := Vector3.ZERO
							for q in 6: c += rel2 * vv[k * 6 + q]
							var wl := "W|%s|%d|%s" % [path, s, _sha(rec)]
							bag[wl] = int(bag.get(wl, 0)) + 1
							info[wl] = {"k": "W", "path": path, "c": c / 6.0}
				elif String(mi.name) == "ground" and mi.mesh and mi.mesh is ArrayMesh:
					var gm := mi.mesh as ArrayMesh
					line += "|ground, by triangle"
					var relg := _rel(mi, top)
					for s in gm.get_surface_count():
						var ga := gm.surface_get_arrays(s)
						var gv: PackedVector3Array = ga[Mesh.ARRAY_VERTEX]
						var gn: Variant = ga[Mesh.ARRAY_NORMAL]; var gu: Variant = ga[Mesh.ARRAY_TEX_UV]
						var gi := PackedInt32Array()
						if ga[Mesh.ARRAY_INDEX] != null: gi = ga[Mesh.ARRAY_INDEX]
						var cnt := gi.size() if gi.size() > 0 else gv.size()
						var head := "G|%s|%s|%s|" % [path, String(gm.surface_get_name(s)), _mat_key(gm.surface_get_material(s))]
						for t in cnt / 3:
							var parts := PackedStringArray(); var vs: Array = []; var ns: Array = []
							for e in 3:
								var vi: int = gi[t * 3 + e] if gi.size() > 0 else t * 3 + e
								var pp := relg * gv[vi]; vs.append(pp)
								var nn2: Vector3 = gn[vi] if gn != null else Vector3.ZERO
								var uu: Vector2 = gu[vi] if gu != null else Vector2.ZERO
								parts.append("%.4f,%.4f,%.4f,%.4f,%.4f" % [pp.x, pp.y, pp.z, uu.x, uu.y]); ns.append(nn2)
							var tl := head + ";".join(parts)
							bag[tl] = int(bag.get(tl, 0)) + 1
							info[tl] = {"k": "G", "v": vs, "n": ns}      # normals are stored packed: compared apart, with a tolerance
				else:
					line += "|mesh " + _mesh_key(mi.mesh)
					for s in (mi.mesh.get_surface_count() if mi.mesh else 0): line += "|" + _mat_key(mi.get_surface_override_material(s))
		bag[line] = int(bag.get(line, 0)) + 1
	return [bag, info]

func _prove(a: Node, b: Node, fixes: Array) -> bool:
	var da := _digest(a); var db := _digest(b)
	var ba: Dictionary = da[0]; var bb: Dictionary = db[0]; var ia: Dictionary = da[1]; var ib: Dictionary = db[1]
	var same := {"N": 0, "I": 0, "C": 0, "W": 0, "G": 0}
	var gone: Array = []; var come: Array = []      # lines only in the old file / only in the new file (with repeats)
	for k: String in ba:
		var na := int(ba[k]); var nb := int(bb.get(k, 0))
		var kd := "G" if k.begins_with("GC|") or k.begins_with("G|") else k.substr(0, 1)
		same[kd] = int(same.get(kd, 0)) + mini(na, nb)
		for q in maxi(0, na - nb): gone.append(k)
	for k: String in bb:
		for q in maxi(0, int(bb[k]) - int(ba.get(k, 0))): come.append(k)
	# ground triangles that are the same in place and texture: their facing must be the same too (stored packed in
	# the file, so a re-saved mesh may differ in the last digit: 0.02 is allowed, more is a change)
	var turned := 0
	for k: String in ba:
		if not k.begins_with("G|") or not bb.has(k): continue
		var n_a: Array = (ia[k] as Dictionary)["n"]; var n_b: Array = (ib[k] as Dictionary)["n"]
		for e in 3:
			if (n_a[e] as Vector3).distance_to(n_b[e]) > 0.02: turned += 1; break
	if turned > 0: print("PROOF UNEXPLAINED: %d ground triangles kept their place but face another way" % turned)
	print("PROOF compared: %d nodes (with every mesh of the buildings), %d ground and ground-collision triangles, %d prop instances, %d colliders, %d wear marks are identical in both files" % [int(same["N"]), int(same["G"]), int(same["I"]), int(same["C"]), int(same["W"])])
	print("PROOF differences found between the files: %d lines only in the old one, %d only in the new one" % [gone.size(), come.size()])
	var ok := turned == 0
	var emptied := {}      # batch path -> true when a listed removal may have emptied it
	for f: Dictionary in fixes:
		var op := String(f.get("op", "")); var at := _v3(f["at"])
		var tag := "#%d %s" % [int(f.get("n", 0)), op]
		if op == "add_collider":
			var hc := -1
			for i in come.size():
				var rc: Dictionary = ib.get(come[i], {})
				if rc.get("k", "") == "C" and (rc["t"] as Transform3D).origin.distance_to(at) <= 0.6: hc = i; break
			if hc < 0: print("PROOF MISSING %s: no collision was added at %s" % [tag, str(at)]); ok = false; continue
			come.remove_at(hc)
			print("PROOF change %s: %s at (%.2f, %.2f, %.2f) got a collision shape  [%s]" % [tag, String(f.get("base", "")), at.x, at.y, at.z, String(f.get("reason", ""))])
			continue
		if op == "add_box":
			var want_path := String(f.get("node", "")) + "/col/" + String(f.get("name", "sc_col"))
			var hb := -1
			for i in come.size():
				if String(come[i]).begins_with("N|" + want_path + "|CollisionShape3D|") and String(come[i]).contains("box:"): hb = i; break
			if hb < 0: print("PROOF MISSING %s: no collision box named %s" % [tag, want_path]); ok = false; continue
			come.remove_at(hb)
			var hbody := -1      # the building had no collision body at all: the new body is part of this line
			for i in come.size():
				if String(come[i]).begins_with("N|" + String(f.get("node", "")) + "/col|StaticBody3D|"): hbody = i; break
			if hbody >= 0: come.remove_at(hbody)
			print("PROOF change %s: a collision box %s for a column of %s  [%s]" % [tag, str(f.get("box", [])), String(f.get("node", "")), String(f.get("reason", ""))])
			continue
		if op == "fill_well":
			var g_old := 0; var g_new := 0
			for pass_i in 2:
				var lst: Array = gone if pass_i == 0 else come
				var inf: Dictionary = ia if pass_i == 0 else ib
				var q2 := 0
				while q2 < lst.size():
					var rr: Dictionary = inf.get(lst[q2], {})
					var inside := String(rr.get("k", "")) in ["G", "GC"]
					if inside:
						for vv: Vector3 in rr["v"]:
							if Vector2(vv.x - at.x, vv.z - at.z).length() > 1.3 or absf(vv.y - at.y) > 0.4: inside = false
					if inside:
						lst.remove_at(q2)
						if pass_i == 0: g_old += 1
						else: g_new += 1
					else: q2 += 1
			if g_new == 0 or g_old == 0: print("PROOF MISSING %s: no well was paved at %s" % [tag, str(at)]); ok = false; continue
			print("PROOF change %s: the tree well at (%.2f, %.2f, %.2f) paved over: %d ground / collision triangles within 1.3 m replaced by %d  [%s]" % [tag, at.x, at.y, at.z, g_old, g_new, String(f.get("reason", ""))])
			continue
		if op == "remove_decal":
			var hit := -1
			for i in gone.size():
				var r: Dictionary = ia.get(gone[i], {})
				if r.get("k", "") == "W" and (r["c"] as Vector3).distance_to(at) <= EPS: hit = i; break
			if hit < 0: print("PROOF MISSING %s: no wear mark at %s left the file" % [tag, str(at)]); ok = false; continue
			emptied[String((ia[gone[hit]] as Dictionary)["path"])] = true
			gone.remove_at(hit)
			print("PROOF change %s: one wear mark at (%.2f, %.2f, %.2f) removed  [%s]" % [tag, at.x, at.y, at.z, String(f.get("reason", ""))])
			continue
		var base := String(f.get("base", "")); var cond := String(f.get("cond", ""))
		var D := _delta(f)
		var tiers := 0; var cols := 0
		var i2 := 0
		var taken := false      # at most ONE instance per tier belongs to this line
		var seen_tier := {}
		while i2 < gone.size():
			var r2: Dictionary = ia.get(gone[i2], {})
			var mine := false
			if r2.get("k", "") == "I":
				var p := _parse(String(r2["name"]))
				if p[0] == base and (cond == "" or p[1] == cond) and (r2["t"] as Transform3D).origin.distance_to(at) <= EPS and not seen_tier.has(String(r2["path"]).get_file() + "|" + String(p[2])):
					mine = true
					if op == "move":
						var want := D * (r2["t"] as Transform3D)
						var j := -1
						for q in come.size():
							var r3: Dictionary = ib.get(come[q], {})
							if r3.get("k", "") == "I" and String(r3["path"]) == String(r2["path"]) and (r3["t"] as Transform3D).is_equal_approx(want) and _close(r3["t"], want): j = q; break
						if j < 0: mine = false
						else: come.remove_at(j)
					if mine:
						seen_tier[String(r2["path"]).get_file() + "|" + String(p[2])] = true
						tiers += 1; emptied[String(r2["path"])] = true
			elif r2.get("k", "") == "C" and cols == 0 and (r2["t"] as Transform3D).origin.distance_to(at) <= EPS:
				mine = true
				if op == "move":
					var want2 := D * (r2["t"] as Transform3D)
					var j2 := -1
					for q in come.size():
						var r4: Dictionary = ib.get(come[q], {})
						if r4.get("k", "") == "C" and _close(r4["t"], want2): j2 = q; break
					if j2 < 0: mine = false
					else: come.remove_at(j2)
				if mine: cols += 1
			if mine: gone.remove_at(i2)
			else: i2 += 1
		if tiers == 0:
			print("PROOF MISSING %s %s: nothing of it changed at %s" % [tag, base, str(at)]); ok = false; continue
		var to := _v3(f.get("to", f["at"]))
		if op == "move":
			print("PROOF change %s %s: (%.2f, %.2f, %.2f) -> (%.2f, %.2f, %.2f)%s, in %d tier(s)%s  [%s]" % [tag, base, at.x, at.y, at.z, to.x, to.y, to.z, (", turned %.0f deg" % float(f.get("turn", 0.0))) if absf(float(f.get("turn", 0.0))) > 0.001 else "", tiers, " and its collider" if cols > 0 else ", no collider", String(f.get("reason", ""))])
		else:
			print("PROOF change %s %s at (%.2f, %.2f, %.2f) removed, in %d tier(s)%s  [%s]" % [tag, base, at.x, at.y, at.z, tiers, " and its collider" if cols > 0 else ", no collider", String(f.get("reason", ""))])
	# a batch (or the wear mesh) whose last item was a listed removal leaves the file as a node: allowed, nothing else
	var i3 := 0
	while i3 < gone.size():
		var r5: Dictionary = ia.get(gone[i3], {})
		var k5 := String(r5.get("k", ""))
		if (k5 == "B" or k5 == "WN") and emptied.has(String(r5["path"])):
			var still := false
			for k6: String in bb:
				var r6: Dictionary = ib.get(k6, {})
				if String(r6.get("path", "")) == String(r5["path"]) and String(r6.get("k", "")) in ["I", "W"]: still = true; break
			var back := -1
			if k5 == "WN" and still:      # the wear mesh's own line changes with its mark count: pair it with the new line
				for q in come.size():
					var r7: Dictionary = ib.get(come[q], {})
					if r7.get("k", "") == "WN" and String(r7["path"]) == String(r5["path"]): back = q; break
				if back >= 0: come.remove_at(back); gone.remove_at(i3); continue
			if not still:
				print("PROOF note: '%s' held only listed items and is gone with them" % String(r5["path"]))
				gone.remove_at(i3); continue
		i3 += 1
	var qn := 0
	while qn < come.size():      # a PropCol body that did not exist before: allowed only when a listed line added a collider
		if String(come[qn]).begins_with("N|Props/PropCol|StaticBody3D|") and fixes.any(func(x: Dictionary) -> bool: return String(x.get("op", "")) == "add_collider"): come.remove_at(qn)
		else: qn += 1
	if not gone.is_empty() or not come.is_empty():
		ok = false
		print("PROOF UNEXPLAINED: %d lines changed that no line of the fix list accounts for" % (gone.size() + come.size()))
		for k7: String in gone.slice(0, 12): print("   old only: " + k7.substr(0, 900))
		for k8: String in come.slice(0, 12): print("   new only: " + k8.substr(0, 900))
	print("PROOF %d listed changes, %s" % [fixes.size(), "every one found, nothing else differs" if ok else "NOT clean"])
	print("PROOF RESULT %s" % ("PASS" if ok else "FAIL"))
	return ok

func _close(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.distance_to(b.origin) <= 0.0005 and a.basis.x.distance_to(b.basis.x) <= 0.0005 and a.basis.y.distance_to(b.basis.y) <= 0.0005 and a.basis.z.distance_to(b.basis.z) <= 0.0005
