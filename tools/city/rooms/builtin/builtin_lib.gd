extends RefCounted
## Built-in interiors (22 Nov 2026 pilot, com_bank / Crownado Savings). A kit building that carries its own interior:
##  - its near model (<prefix>_near.glb, same file name, same node names: drop-in) holds the exterior with REAL openings
##    at its shop door and ground-floor windows plus the interior shell (floor, walls, ceiling, reveals, frames, trim) in
##    the same single mesh and material (the kit's city atlas, AO in the vertex colours, the atlas normal map);
##  - <prefix>_interior.scn next to it holds what cannot live in that one mesh: "Slots" (Marker3D, meta slot_type /
##    variant / lift: hand-placed per model), "Glass" (all window panes, one draw, builtin_glass.gdshader), "Windows"
##    (breakable windows, builtin_window.gd), "Doors" (hinged DoorLeaf_* nodes, builtin_door.gd), "Lights", "col" (the
##    building's collision as boxes, open at the door) and metas (builtin_interior, model, kinds, cuts, floors);
##  - map_dc/coronado/city_kit/interiors/builtin/furniture_sets.json: per shop kind, which kit indoor prop fills each slot
##    type. No fallback filler: a missing set / slot type / prop fails validate().
## The bake (tools/city/bake/bake_runtime.gd) uses this for every building whose model has an _interior.scn: no cutting,
## the kit's near replaces the piece's frozen copy, the col boxes replace its shell, and fill() makes the room scene.
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
const BLD := "res://assets/coronado_kit/buildings/"
const SETS := "res://map_dc/coronado/city_kit/interiors/builtin/furniture_sets.json"
const PROP_END := 30.0          ## interior props drawn to here (the glass closes from GLASS_FAR_BEGIN to PROP_END)
const NEAR_END := 62.0          ## the building's near tier (glass, doors, windows live as long as the near shows)
const MAX_COL_BOXES := 12

static var _sets := {}

static func prefix_of(model: String) -> String:
	var d := BLD + model + "/"
	if not DirAccess.dir_exists_absolute(d): return ""
	for f in DirAccess.get_files_at(d):
		if f.ends_with("_near.glb"): return d + f.trim_suffix("_near.glb")
	return ""

static func interior_path(model: String) -> String:
	var p := prefix_of(model)
	return p + "_interior.scn" if p != "" else ""

static func has_builtin(model: String) -> bool:
	var p := interior_path(model)
	return p != "" and ResourceLoader.exists(p)

static func sets() -> Dictionary:
	if _sets.is_empty():
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETS))
		_sets = (v as Dictionary).get("sets", {}) if v is Dictionary else {}
	return _sets

## a glb as a scene: the imported one when Godot has imported it (and it is not older than the file), else read
## straight from the file with GLTFDocument (this box's headless import stops at the _staging .blend files, so new kit
## files - the 22 Nov svcshop / gym props, the rebuilt near - have no import here; the game's import on the PC is normal)
static func glb_scene(path: String, force_file := false) -> Node:
	var imp := path + ".import"
	if not force_file and FileAccess.file_exists(imp) and FileAccess.get_modified_time(imp) >= FileAccess.get_modified_time(path):
		var ps: Variant = ResourceLoader.load(path)
		if ps is PackedScene: return (ps as PackedScene).instantiate()
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(path), st) != OK: return null
	return doc.generate_scene(st)

static var _near_cache := {}
static func near_mesh(model: String) -> Mesh:
	if _near_cache.has(model): return _near_cache[model]
	var g: Node = glb_scene(prefix_of(model) + "_near.glb", true)
	var mi := g.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var m := mi.mesh; g.free(); _near_cache[model] = m; return m

## every problem of a built-in model for the given shop kinds (empty = passes). Run by the bake for each flagged
## building (a failure fails the bake) and by validate_builtin.gd for every model with an _interior.scn.
static func validate(model: String, kinds: Array, contract: Dictionary = {}) -> Array:
	var P: Array = []
	if not has_builtin(model): return ["%s: no interior scene (%s)" % [model, interior_path(model)]]
	var it: Node3D = (load(interior_path(model)) as PackedScene).instantiate()
	if not bool(it.get_meta(&"builtin_interior", false)): P.append("%s: interior scene lacks meta builtin_interior" % model)
	# 1. the shell: one surface; an upward floor over most of the floor rectangle; inward walls on all four sides
	var m := near_mesh(model)
	if m.get_surface_count() != 1: P.append("%s: near has %d surfaces (one mesh, one material)" % [model, m.get_surface_count()])
	var fl: Array = it.get_meta(&"floors", [])
	if fl.is_empty(): P.append("%s: no floors meta" % model)
	else:
		var f0: Array = fl[0]
		var x0 := float(f0[0]); var z0 := float(f0[1]); var x1 := float(f0[2]); var z1 := float(f0[3])
		var area := 0.0; var walls := {"x0": 0, "x1": 0, "z0": 0, "z1": 0}; var ceil := 0.0
		var ma := m.surface_get_arrays(0)
		var mv: PackedVector3Array = ma[Mesh.ARRAY_VERTEX]; var mn: PackedVector3Array = ma[Mesh.ARRAY_NORMAL]; var mix: PackedInt32Array = ma[Mesh.ARRAY_INDEX]
		for k in range(0, mix.size(), 3):
			var a := mv[mix[k]]; var b := mv[mix[k + 1]]; var c := mv[mix[k + 2]]
			var ar := (b - a).cross(c - a).length() * 0.5
			if ar < 1e-6: continue
			var n := (mn[mix[k]] + mn[mix[k + 1]] + mn[mix[k + 2]]).normalized()      # the shading normal (which way the face looks)
			var ctr := (a + b + c) / 3.0
			var inside := ctr.x > x0 - 0.05 and ctr.x < x1 + 0.05 and ctr.z > z0 - 0.05 and ctr.z < z1 + 0.05
			if not inside: continue
			if n.y > 0.9 and ctr.y < 0.1: area += ar
			if n.y < -0.9 and ctr.y > 2.4: ceil += ar
			if absf(ctr.x - x0) < 0.02 and n.x > 0.9: walls.x0 += 1
			if absf(ctr.x - x1) < 0.02 and n.x < -0.9: walls.x1 += 1
			if absf(ctr.z - z0) < 0.02 and n.z > 0.9: walls.z0 += 1
			if absf(ctr.z - z1) < 0.02 and n.z < -0.9: walls.z1 += 1
		var want := (x1 - x0) * (z1 - z0)
		if area < want * 0.9: P.append("%s: interior floor covers %.1f of %.1f m2" % [model, area, want])
		if ceil < want * 0.9: P.append("%s: interior ceiling covers %.1f of %.1f m2" % [model, ceil, want])
		for w: String in walls:
			if int(walls[w]) == 0: P.append("%s: no inward interior wall at %s" % [model, w])
	# 2. slots: inside the floor, of a type the kind's set names, a variant it has, a prop that exists
	var slots := it.get_node_or_null(^"Slots")
	var have := {}
	if slots == null or slots.get_child_count() == 0: P.append("%s: no slot markers" % model)
	else:
		for s: Node in slots.get_children():
			if not (s is Marker3D): P.append("%s: slot %s is not a Marker3D" % [model, s.name]); continue
			var st := String(s.get_meta(&"slot_type", ""))
			if st == "": P.append("%s: slot %s has no slot_type" % [model, s.name]); continue
			have[st] = int(have.get(st, 0)) + 1
			var p := (s as Marker3D).position
			if not fl.is_empty():
				var f1: Array = fl[0]
				if p.x < float(f1[0]) or p.x > float(f1[2]) or p.z < float(f1[1]) or p.z > float(f1[3]): P.append("%s: slot %s outside the floor" % [model, s.name])
			for kind: String in kinds:
				var set_k: Dictionary = sets().get(kind, {})
				if set_k.is_empty(): continue
				if not set_k.has(st): P.append("%s: kind %s has no props for slot type %s (no fallback)" % [model, kind, st]); continue
				var lst: Array = set_k[st]; var v := int(s.get_meta(&"variant", 0))
				if v < 0 or v >= lst.size(): P.append("%s: slot %s variant %d out of range for %s/%s" % [model, s.name, v, kind, st]); continue
				if R.indoor_file("prop_" + String(lst[v])) == "": P.append("%s: prop %s (slot %s) has no kit file" % [model, lst[v], s.name])
	for kind: String in kinds:
		var set_k2: Dictionary = sets().get(kind, {})
		if set_k2.is_empty(): P.append("%s: no furniture set for kind %s (no fallback)" % [model, kind]); continue
		for req: String in set_k2.get("required", []):
			if not have.has(req): P.append("%s: kind %s needs a %s slot" % [model, kind, req])
	# 3. doors: every contract entrance (the shop door) has hinged leaves spanning it and a real opening in the mesh
	var doors := it.get_node_or_null(^"Doors")
	var cuts: Array = it.get_meta(&"cuts", [])
	for e: Dictionary in contract.get("entrances", []):
		if String(e.get("kind", "")) == "residential": continue      # staff / back doors stay painted
		var along := float(e.along); var w := float(e.w)
		var s0 := 1e9; var s1 := -1e9; var nleaf := 0
		if doors:
			for d: Node in doors.get_children():
				if not String(d.name).begins_with("DoorLeaf_"): continue
				if String(d.get_meta(&"facade", "")) != String(e.facade): continue
				var sp: Vector2 = d.get_meta(&"span", Vector2.ZERO)
				s0 = minf(s0, sp.x); s1 = maxf(s1, sp.y); nleaf += 1
		if nleaf == 0: P.append("%s: entrance %s %.2f has no door leaves" % [model, e.facade, along])
		elif absf(s0 - (along - w * 0.5)) > 0.04 or absf(s1 - (along + w * 0.5)) > 0.04: P.append("%s: door leaves %.2f..%.2f do not fill the %s entrance %.2f..%.2f" % [model, s0, s1, e.facade, along - w * 0.5, along + w * 0.5])
		if not cuts.any(func(c: Array) -> bool: return String(c[0]) == String(e.facade) and absf(float(c[1]) - along) < 0.05): P.append("%s: entrance %s %.2f is not opened in the near mesh" % [model, e.facade, along])
	# 4. every cut window has glass (in Glass or a breakable window)
	var panes: Array = it.get_meta(&"panes", [])
	for c2: Array in cuts:
		if String(c2[2]) == "door": continue
		if not panes.any(func(p2: Array) -> bool: return String(p2[0]) == String(c2[0]) and absf(float(p2[1]) - float(c2[1])) < 0.05): P.append("%s: opening %s %.2f has no glass" % [model, c2[0], c2[1]])
	# 5. collision: boxes only, at most 12, none across a door
	var col := it.get_node_or_null(^"col") as StaticBody3D
	if col == null: P.append("%s: no col body" % model)
	else:
		var nb := 0
		for cs: Node in col.get_children():
			if not (cs is CollisionShape3D): continue
			nb += 1
			if not ((cs as CollisionShape3D).shape is BoxShape3D): P.append("%s: col %s is not a box" % [model, cs.name])
		if nb > MAX_COL_BOXES: P.append("%s: %d col boxes (max %d)" % [model, nb, MAX_COL_BOXES])
		for e2: Dictionary in contract.get("entrances", []):
			if String(e2.get("kind", "")) == "residential": continue
			var probe := _entrance_point(e2, contract)
			for cs2: Node in col.get_children():
				if cs2 is CollisionShape3D and (cs2 as CollisionShape3D).shape is BoxShape3D:
					var bx := (cs2 as CollisionShape3D).shape as BoxShape3D
					var lp := (cs2 as CollisionShape3D).transform.affine_inverse() * probe
					if absf(lp.x) < bx.size.x * 0.5 and absf(lp.y) < bx.size.y * 0.5 and absf(lp.z) < bx.size.z * 0.5: P.append("%s: col box %s blocks the %s door" % [model, cs2.name, e2.facade])
	it.free()
	return P

static func _entrance_point(e: Dictionary, contract: Dictionary) -> Vector3:
	for o: Dictionary in contract.get("openings", []):
		if String(o.facade) == String(e.facade) and absf(float(o.along) - float(e.along)) < 0.05:
			var pl := float(o.plane); var y := 1.0
			match String(o.facade):
				"front": return Vector3(float(o.along), y, pl)
				"back": return Vector3(float(o.along), y, pl)
				"right": return Vector3(pl, y, float(o.along))
				"left": return Vector3(pl, y, float(o.along))
	return Vector3(0, 1, 0)

## the room scene of one shop in a built-in model: the slots filled from the kind's set (kit props as MultiMeshes,
## room_lib's build), plus the model's glass, breakable windows, doors and lights. bid_prefix makes the breakables'
## persistent ids unique per building ("<piece>|<label>").
static func fill(model: String, kind: String, room_name: String, bid_prefix: String) -> Node3D:
	var it: Node3D = (load(interior_path(model)) as PackedScene).instantiate()
	var set_k: Dictionary = sets()[kind]
	var r: RefCounted = R.new(room_name)
	for s: Node in it.get_node(^"Slots").get_children():
		var mk := s as Marker3D
		var lst: Array = set_k[String(mk.get_meta(&"slot_type"))]
		var base := String(lst[int(mk.get_meta(&"variant", 0))])
		r.call("prop", base, mk.position.x, mk.position.z, rad_to_deg(mk.rotation.y), mk.position.y + float(mk.get_meta(&"lift", 0.0)))
	var room := Node3D.new(); room.name = room_name
	var pn := Node3D.new(); pn.name = "Props"; room.add_child(pn)
	var props: Dictionary = r.get("_props")
	for base: String in props:
		var f := R.indoor_file(base)
		if f == "": push_error("builtin fill: no kit file for " + base); return null
		var inst: Node = glb_scene(f)
		var src := K._first_mesh(inst)
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = src.mesh
		var ts: Array = props[base]; mm.instance_count = ts.size()
		for i in ts.size(): mm.set_instance_transform(i, (ts[i] as Transform3D) * src.transform)
		var mmi := MultiMeshInstance3D.new(); mmi.name = base; mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF      # (indoors: the sun's shadow pass would draw every prop again)
		if src.mesh.get_surface_count() == 1:
			var wm: Material = K.prop_wear_mat(src.mesh.surface_get_material(0), R.PROP_WEAR)
			if wm != src.mesh.surface_get_material(0): mmi.material_override = wm
		pn.add_child(mmi); inst.free()
	for gi: GeometryInstance3D in room.find_children("*", "GeometryInstance3D", true, false):
		gi.visibility_range_end = PROP_END; gi.visibility_range_end_margin = 1.0
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	for nm: String in ["Glass", "Windows", "Doors", "Lights"]:
		var src := it.get_node_or_null(NodePath(nm))
		if src == null: continue
		var cp := src.duplicate(Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SIGNALS)
		room.add_child(cp)
		for n: Node in cp.find_children("*", "", true, false) + [cp]:
			if n.get_script() != null: n.set_meta(&"bid", bid_prefix + "|" + String(n.name))
			if n is GeometryInstance3D:
				(n as GeometryInstance3D).visibility_range_end = NEAR_END
	_own(room, room)
	room.set_meta(&"builtin", true); room.set_meta(&"kind", kind); room.set_meta(&"model", model)
	room.set_meta(&"floors", it.get_meta(&"floors", [])); room.set_meta(&"entrances", it.get_meta(&"entrances", []))
	room.set_meta(&"cut", []); room.set_meta(&"openings", [])
	it.free()
	return room

static func _own(n: Node, o: Node) -> void:
	for c in n.get_children():
		if c != o: c.owner = o
		_own(c, o)

## the building's collision boxes from the interior scene: [[BoxShape3D, Transform3D]] in the model frame
static func col_boxes(model: String) -> Array:
	var it: Node3D = (load(interior_path(model)) as PackedScene).instantiate()
	var out: Array = []
	var col := it.get_node_or_null(^"col")
	if col:
		for cs: Node in col.get_children():
			if cs is CollisionShape3D: out.append([(cs as CollisionShape3D).shape, (cs as CollisionShape3D).transform])
	it.free()
	return out
