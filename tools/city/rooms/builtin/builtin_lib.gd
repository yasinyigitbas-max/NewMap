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
	var d := K._bdir(model) + "/"      # (kit buildings, kit modular examples, city-kit ck/ assemblies)
	if not DirAccess.dir_exists_absolute(d): return ""
	for f in DirAccess.get_files_at(d):
		if f.ends_with("_near.glb"): return d + f.trim_suffix("_near.glb")
		if f.ends_with("_near.scn"): return d + f.trim_suffix("_near.scn")
	return ""
## the kit's near file (glb, or the ck/ assemblies' scn) as a scene
static func near_scene(model: String) -> Node:
	var p := prefix_of(model)
	if FileAccess.file_exists(p + "_near.glb"): return glb_scene(p + "_near.glb", true)
	return (load(p + "_near.scn") as PackedScene).instantiate()

static func interior_path(model: String) -> String:
	var p := prefix_of(model)
	return p + "_interior.scn" if p != "" else ""

static func has_builtin(model: String) -> bool:
	var p := interior_path(model)
	return p != "" and (ResourceLoader.exists(p) or has_bays(model))

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
				if prop_file(String(lst[v])) == "": P.append("%s: prop %s (slot %s) has no kit file" % [model, lst[v], s.name])
	if slots and not fl.is_empty():
		for kind: String in kinds:
			if sets().has(kind): P.append_array(facing_problems(model, slots, fl[0], kind))
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

## FACING (Yasin 22 Nov: "the PCs face the wrong way"). The convention is one axis for props and slots alike: a kit
## indoor prop's FRONT (screen + keyboard, drawer fronts, seat front, sign or picture face) is its local +Z (Blender -Y,
## assets/coronado_kit/tools/indoor/i_check.py; tools/city/rooms/builtin/prop_facing_sheet.gd shows every prop of a set
## from +Z), and a slot marker's +Z (its yaw) is where that front goes: TOWARD THE PERSON WHO USES OR READS IT. So:
##  - desk: its user's chair (a slot whose prop is one of the set's "desk_users", default office_chair) within 1.1 m
##    in front of it, facing back at it - a visitor chair in front does not count (a desk turned round fails)
##  - till: its staff slot behind it (customers in front)
##  - staff and seat: face the desk / till / counter they serve when one is within 1.3 m
##  - wall things (decor, shelf, safe, bin, and a seat with nothing to serve): face away from the wall they stand at
## Rules live here, not per model, so every rollout model is checked the same way.
const WALL_TYPES := ["decor", "shelf", "safe", "bin", "seat"]
static func _fwd(m: Marker3D) -> Vector3: return Vector3(sin(m.rotation.y), 0.0, cos(m.rotation.y))
static func facing_problems(model: String, slots: Node, f1: Array, kind: String) -> Array:
	var P: Array = []
	var set_k: Dictionary = sets().get(kind, {})
	var users_p: Array = set_k.get("desk_users", ["office_chair"])
	var prop_of := func(m: Marker3D) -> String:
		var lst: Array = set_k.get(String(m.get_meta(&"slot_type", "")), [])
		var v := int(m.get_meta(&"variant", 0))
		return String(lst[v]) if v >= 0 and v < lst.size() else ""
	var ms: Array = slots.get_children().filter(func(n: Node) -> bool: return n is Marker3D)
	var of_type := func(types: Array) -> Array: return ms.filter(func(m: Marker3D) -> bool: return types.has(String(m.get_meta(&"slot_type", ""))))
	var nearest := func(m: Marker3D, cands: Array, maxd: float) -> Marker3D:
		var best: Marker3D = null; var bd := maxd
		for c: Marker3D in cands:
			if c == m: continue
			var d := Vector2(c.position.x - m.position.x, c.position.z - m.position.z).length()
			if d < bd: bd = d; best = c
		return best
	var dir := func(a: Marker3D, b: Marker3D) -> Vector3: var v := b.position - a.position; v.y = 0.0; return v.normalized()
	var served := {}
	for d: Marker3D in of_type.call(["desk"]):
		var users: Array = (of_type.call(["seat", "staff"]) as Array).filter(func(u: Marker3D) -> bool: return users_p.has(prop_of.call(u)) and _fwd(d).dot(dir.call(d, u)) > 0.7)
		var u: Marker3D = nearest.call(d, users, 1.1)
		if u == null: P.append("%s (%s): desk %s has no user chair in front of it (its +Z = screen / keyboard side)" % [model, kind, d.name]); continue
		if _fwd(u).dot(dir.call(u, d)) < 0.7: P.append("%s: seat %s does not face its desk %s" % [model, u.name, d.name])
		served[u] = true
	for t: Marker3D in of_type.call(["till"]):
		var st: Marker3D = nearest.call(t, of_type.call(["staff"]), 1.3)
		if st and _fwd(t).dot(dir.call(t, st)) > -0.7: P.append("%s: till %s faces its staff %s (its front is the customer side)" % [model, t.name, st.name])
	for u2: Marker3D in of_type.call(["staff", "seat"]):
		if served.has(u2): continue
		var tgt: Marker3D = nearest.call(u2, of_type.call(["desk", "till", "counter"]), 1.3)
		if tgt:
			if _fwd(u2).dot(dir.call(u2, tgt)) < 0.7: P.append("%s: %s %s does not face %s" % [model, u2.get_meta(&"slot_type"), u2.name, tgt.name])
			served[u2] = true
	for w: Marker3D in of_type.call(WALL_TYPES):
		if served.has(w): continue
		var p := w.position
		var walls := [[p.x - float(f1[0]), Vector3(1, 0, 0)], [float(f1[2]) - p.x, Vector3(-1, 0, 0)], [p.z - float(f1[1]), Vector3(0, 0, 1)], [float(f1[3]) - p.z, Vector3(0, 0, -1)]]
		walls.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		if float(walls[0][0]) > 0.8: continue      # (free-standing)
		if _fwd(w).dot(walls[0][1]) < 0.7: P.append("%s: %s %s at a wall does not face into the room" % [model, w.get_meta(&"slot_type"), w.name])
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
		var f := prop_file(base)
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

# ================================================================ the rollout (22 Nov 2026): bays
## A rollout model keeps the kit's closed near glb; each bay with a place has <prefix>_bay<i>.scn (make_interiors.gd):
## its Shell mesh, Glass, Windows, Doors, Lights, col and Slots/<kind>/<template>. The bake composes the near of a
## building from the closed near (the used bays' openings cut) + the used bays' shells (one surface), and fills each
## place from its bay's template for its kind (pick(): template, mirror, decor shift - dealt round-robin per kind).
const PROP_DIRS := ["res://assets/coronado_kit/props/house/furn/", "res://assets/coronado_kit/props/house/decor/", "res://assets/coronado_kit/props/streetside/motel/"]
const WALL_TYPES2 := ["decor", "shelf", "safe", "bin", "seat", "back", "board", "waiting"]
static var _man := {}
static var _bay_cache := {}
static var _compose_cache := {}

static func bay_path(model: String, i: int) -> String:
	var p := prefix_of(model)
	return "%s_bay%d.scn" % [p, i] if p != "" else ""
static func has_bays(model: String) -> bool:
	var p := bay_path(model, 0)
	return p != "" and ResourceLoader.exists(p)
## the bay scenes of a model: [{i, door_along, span, path}]
static func bays_of(model: String) -> Array:
	if _bay_cache.has(model): return _bay_cache[model]
	var out: Array = []
	var i := 0
	while ResourceLoader.exists(bay_path(model, i)):
		var it: Node3D = (load(bay_path(model, i)) as PackedScene).instantiate()
		out.append({"i": i, "door_along": float(it.get_meta(&"door_along", 0.0)), "span": it.get_meta(&"span", [0, 0]), "path": bay_path(model, i)})
		it.free(); i += 1
	_bay_cache[model] = out
	return out
static func bay_for(model: String, door_along: float) -> int:
	for b: Dictionary in bays_of(model):
		if absf(float(b.door_along) - door_along) < 0.3: return int(b.i)
	return -1

## a kit prop's file: indoor props first, then the house furniture / decor and the motel's streetside vending
static var _pf := {}
static func prop_file(base: String) -> String:
	var b := base.trim_prefix("prop_")
	if _pf.has(b): return _pf[b]
	var f := R.indoor_file("prop_" + b)
	if f == "":
		for d: String in PROP_DIRS:
			var p := d + "prop_" + b + "_clean_near.glb"
			if FileAccess.file_exists(p): f = p; break
	_pf[b] = f
	return f
## a prop's manifest entry (footprint_w / _d, height, mount)
static func prop_info(base: String) -> Dictionary:
	if _man.is_empty():
		var d := "res://assets/coronado_kit/props/"
		for f in DirAccess.get_files_at(d):
			if f.begins_with("manifest_") and f.ends_with(".json"):
				var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(d + f))
				if v is Dictionary: _man.merge(v)
		for k: String in ["vending_snack", "vending_soda"]: if not _man.has(k): _man[k] = {"footprint_w": 0.9, "footprint_d": 0.8, "height": 1.8, "mount": "ground"}
		if not _man.has("ice_chest"): _man["ice_chest"] = {"footprint_w": 1.2, "footprint_d": 0.7, "height": 1.0, "mount": "ground"}
	return _man.get(base, {})

## the variation pick for the rank-th place of a kind (places of a kind sorted by id): templates dealt round-robin,
## then the mirror (where the template allows it), then the decor shift
static func pick(rank: int, templates: Array, mirror_ok: Dictionary) -> Array:
	var n := maxi(templates.size(), 1)
	var t: String = templates[rank % n] if not templates.is_empty() else ""
	var mir := bool(mirror_ok.get(t, false)) and ((rank / n) % 2 == 1)
	return [t, mir, rank]

## the near of a building whose bays `used` carry interiors: the kit's closed near with those bays' openings cut, and
## their shells appended - one surface, one material (vertex alpha 0 = indoor)
static func compose_near(model: String, used: Array) -> Mesh:
	var key := model + "|" + str(used)
	if _compose_cache.has(key): return _compose_cache[key]
	var g: Node = near_scene(model)
	var mis := g.find_children("*", "MeshInstance3D", true, false)
	if g is MeshInstance3D: mis.push_front(g)
	var smi := mis[0] as MeshInstance3D
	var src: Mesh = smi.mesh
	if src.get_surface_count() != 1: push_error("compose_near %s: the kit near has %d surfaces" % [model, src.get_surface_count()])
	var regs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/textures/city_layout.json")).regions
	var ops: Array = []; var shells: Array = []
	for i: int in used:
		var it: Node3D = (load(bay_path(model, i)) as PackedScene).instantiate()
		ops.append_array(it.get_meta(&"ops", []))
		shells.append(((it.get_node(^"Shell") as MeshInstance3D).mesh as ArrayMesh).surface_get_arrays(0))
		it.free()
	var a := src.surface_get_arrays(0)
	var vv: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var tt: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	if idx.is_empty():
		idx = PackedInt32Array(); for q in vv.size(): idx.append(q)
	var keep := PackedInt32Array()
	var xf := smi.transform
	for k in idx.size() / 3:
		var i0 := idx[k * 3]; var i1 := idx[k * 3 + 1]; var i2 := idx[k * 3 + 2]
		var cu := (tt[i0] + tt[i1] + tt[i2]) / 3.0; cu.x = fposmod(cu.x, 1.0)
		var cp := xf * ((vv[i0] + vv[i1] + vv[i2]) / 3.0)
		var drop := false
		for o: Dictionary in ops:
			var uv: Array = regs[o.region].uv
			if not (cu.x >= float(uv[0]) and cu.x <= float(uv[2]) and cu.y >= float(uv[1]) and cu.y <= float(uv[3])): continue
			var fr := String(o.facade) == "front" or String(o.facade) == "back"
			var along := cp.x if fr else cp.z; var pl := cp.z if fr else cp.x
			if absf(along - float(o.along)) <= float(o.w) * 0.5 + 0.05 and cp.y >= float(o.y0) - 0.05 and cp.y <= float(o.y1) + 0.05 and absf(pl - float(o.plane)) < 0.3: drop = true; break
		if not drop: keep.append(i0); keep.append(i1); keep.append(i2)
	if g is MeshInstance3D: xf = Transform3D.IDENTITY      # (the root's own transform is the building's)
	var inv := xf.affine_inverse()
	var outv := vv.duplicate()
	var has_n: bool = a[Mesh.ARRAY_NORMAL] != null; var has_t: bool = a[Mesh.ARRAY_TANGENT] != null; var has_c: bool = a[Mesh.ARRAY_COLOR] != null
	var outn: PackedVector3Array = (a[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate() if has_n else PackedVector3Array()
	var outt: PackedFloat32Array = (a[Mesh.ARRAY_TANGENT] as PackedFloat32Array).duplicate() if has_t else PackedFloat32Array()
	var outuv := tt.duplicate()
	var outc := PackedColorArray()
	if has_c: outc = (a[Mesh.ARRAY_COLOR] as PackedColorArray).duplicate()
	else:
		outc.resize(vv.size()); outc.fill(Color(1, 1, 1, 1))
	for sa: Array in shells:
		var base := outv.size()
		for p: Vector3 in (sa[Mesh.ARRAY_VERTEX] as PackedVector3Array): outv.append(inv * p)
		for nn: Vector3 in (sa[Mesh.ARRAY_NORMAL] as PackedVector3Array): outn.append((inv.basis * nn).normalized())
		outt.append_array(sa[Mesh.ARRAY_TANGENT]); outuv.append_array(sa[Mesh.ARRAY_TEX_UV]); outc.append_array(sa[Mesh.ARRAY_COLOR])
		for q: int in (sa[Mesh.ARRAY_INDEX] as PackedInt32Array): keep.append(base + q)
	var fa := []; fa.resize(Mesh.ARRAY_MAX)
	fa[Mesh.ARRAY_VERTEX] = outv; fa[Mesh.ARRAY_NORMAL] = outn; fa[Mesh.ARRAY_TEX_UV] = outuv; fa[Mesh.ARRAY_COLOR] = outc; fa[Mesh.ARRAY_INDEX] = keep
	if has_t: fa[Mesh.ARRAY_TANGENT] = outt
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, fa); am.surface_set_material(0, src.surface_get_material(0))
	am.resource_name = src.resource_name
	am.set_meta(&"ext_tris", idx.size() / 3); am.set_meta(&"tris", keep.size() / 3)
	g.free()
	_compose_cache[key] = am
	return am

## the slot markers of a template, mirrored if asked (x -> 2c - x, yaw -> -yaw), as fresh Marker3D (caller frees the holder)
static func template_markers(it: Node3D, kind: String, t: String, mirror: bool) -> Node3D:
	var holder := Node3D.new()
	var src := it.get_node_or_null(NodePath("Slots/%s/%s" % [kind, t]))
	if src == null: return holder
	var sp: Array = it.get_meta(&"span", [0, 0]); var cx := (float(sp[0]) + float(sp[1])) * 0.5
	for m: Node in src.get_children():
		var mk := (m as Marker3D).duplicate() as Marker3D
		if mirror: mk.position.x = 2.0 * cx - mk.position.x; mk.rotation.y = -mk.rotation.y
		holder.add_child(mk)
	return holder

static func _prop_for(set_k: Dictionary, mk: Marker3D, shift: int) -> String:
	var st := String(mk.get_meta(&"slot_type", ""))
	var lst: Array = set_k.get(st, [])
	if lst.is_empty(): return ""
	var v := int(mk.get_meta(&"variant", 0))
	if st in ["decor", "top", "plant"]: v += shift      # the decor set
	return String(lst[posmod(v, lst.size())])

## every problem of one bay for its kinds, over every template x mirror x decor shift (empty = passes)
static func validate_bay(model: String, i: int, kinds: Array, contract: Dictionary = {}) -> Array:
	var P: Array = []
	var path := bay_path(model, i)
	if not ResourceLoader.exists(path): return ["%s bay %d: no bay scene" % [model, i]]
	var it: Node3D = (load(path) as PackedScene).instantiate()
	var tag := "%s bay %d" % [model, i]
	var fl: Array = it.get_meta(&"floors", [])
	var f1: Array = fl[0]
	var x0 := float(f1[0]); var z0 := float(f1[1]); var x1 := float(f1[2]); var z1 := float(f1[3])
	# 1. the shell: floor + ceiling over the rectangle, an inward wall at each side
	var sm := (it.get_node(^"Shell") as MeshInstance3D).mesh
	if sm == null or sm.get_surface_count() != 1: P.append(tag + ": shell is not one surface")
	else:
		var ma := sm.surface_get_arrays(0)
		var mv: PackedVector3Array = ma[Mesh.ARRAY_VERTEX]; var mn: PackedVector3Array = ma[Mesh.ARRAY_NORMAL]; var mix: PackedInt32Array = ma[Mesh.ARRAY_INDEX]
		var area := 0.0; var ceil := 0.0; var walls := {"x0": 0, "x1": 0, "z0": 0, "z1": 0}
		var fy := float(it.get_meta(&"floor_y", 0.02))
		for k in range(0, mix.size(), 3):
			var a := mv[mix[k]]; var b := mv[mix[k + 1]]; var c := mv[mix[k + 2]]
			var ar := (b - a).cross(c - a).length() * 0.5
			var n := (mn[mix[k]] + mn[mix[k + 1]] + mn[mix[k + 2]]).normalized(); var ctr := (a + b + c) / 3.0
			if n.y > 0.9 and absf(ctr.y - fy) < 0.05: area += ar
			if n.y < -0.9 and ctr.y > fy + 2.4: ceil += ar
			if absf(ctr.x - x0) < 0.02 and n.x > 0.9: walls.x0 += 1
			if absf(ctr.x - x1) < 0.02 and n.x < -0.9: walls.x1 += 1
			if absf(ctr.z - z0) < 0.02 and n.z > 0.9: walls.z0 += 1
			if absf(ctr.z - z1) < 0.02 and n.z < -0.9: walls.z1 += 1
		var want := (x1 - x0) * (z1 - z0)
		if area < want * 0.9: P.append("%s: floor covers %.1f of %.1f m2" % [tag, area, want])
		if ceil < want * 0.85: P.append("%s: ceiling covers %.1f of %.1f m2" % [tag, ceil, want])
		for w: String in walls: if int(walls[w]) == 0: P.append("%s: no inward wall at %s" % [tag, w])
	# 2. per kind: templates exist; every template x mirror x decor shift: types named, props exist, required, inside,
	# no overlaps (manifest footprints), entry zone clear, facing rules
	var ent: Array = (it.get_meta(&"entrances", []) as Array)[0]
	var clear := Rect2(float(ent[2]) - 0.3, z1 - 1.5, float(ent[3]) - float(ent[2]) + 0.6, 1.5)
	for kind: String in kinds:
		var set_k: Dictionary = sets().get(kind, {})
		if set_k.is_empty(): P.append("%s: no furniture set for %s (no fallback)" % [tag, kind]); continue
		var kn := it.get_node_or_null(NodePath("Slots/" + kind))
		if kn == null or kn.get_child_count() == 0: P.append("%s: no slot templates for %s" % [tag, kind]); continue
		for tn: Node in kn.get_children():
			var mirrors := [false, true] if bool(tn.get_meta(&"mirror_ok", false)) else [false]
			var nshift := 1
			for st0: String in ["decor", "top", "plant"]: nshift = maxi(nshift, (set_k.get(st0, []) as Array).size())
			for mir: bool in mirrors:
				var h := template_markers(it, kind, String(tn.name), mir)
				var tagt := "%s %s/%s%s" % [tag, kind, tn.name, " mirrored" if mir else ""]
				var have := {}
				for m: Node in h.get_children():
					var st := String(m.get_meta(&"slot_type", ""))
					have[st] = true
					if not set_k.has(st): P.append("%s: %s has no props for slot type %s (no fallback)" % [tagt, kind, st]); continue
					var p := (m as Marker3D).position
					if p.x < x0 or p.x > x1 or p.z < z0 or p.z > z1: P.append("%s: slot %s outside the floor" % [tagt, m.name])
					for sh in nshift:
						var pr := _prop_for(set_k, m, sh)
						if pr == "" or prop_file(pr) == "": P.append("%s: prop %s (slot %s) has no kit file" % [tagt, pr, m.name])
				for req: String in set_k.get("required", []):
					if not have.has(req): P.append("%s: needs a %s slot" % [tagt, req])
				# footprints (largest prop of the type: any shift fits)
				var rects: Array = []
				for m2: Node in h.get_children():
					var st2 := String(m2.get_meta(&"slot_type", ""))
					if st2 in ["till", "top", "decor", "board"] or not set_k.has(st2): continue
					var w := 0.0; var d := 0.0
					for pr2 in set_k[st2]:
						var inf := prop_info(String(pr2)); w = maxf(w, float(inf.get("footprint_w", 0.5))); d = maxf(d, float(inf.get("footprint_d", 0.5)))
					if absf(sin((m2 as Marker3D).rotation.y)) > 0.7: var tmp := w; w = d; d = tmp
					var r := Rect2((m2 as Marker3D).position.x - w * 0.5, (m2 as Marker3D).position.z - d * 0.5, w, d)
					if r.grow(-0.02).intersects(clear) and st2 != "bin" and st2 != "plant": P.append("%s: %s blocks the entry" % [tagt, m2.name])
					for q: Array in rects:
						if r.grow(-0.03).intersects(q[1]): P.append("%s: %s overlaps %s" % [tagt, m2.name, q[0]])
					rects.append([String(m2.name), r])
				P.append_array(_facing_bay(tagt, h, f1, set_k))
				h.free()
	# 3. doors: the bay's entrance has hinged leaves spanning it; it is cut
	var doors := it.get_node_or_null(^"Doors")
	var s0 := 1e9; var s1 := -1e9; var nleaf := 0
	for dd: Node in doors.get_children():
		if not String(dd.name).begins_with("DoorLeaf_"): continue
		var sp: Vector2 = dd.get_meta(&"span", Vector2.ZERO)
		if sp.y < float(ent[2]) - 0.05 or sp.x > float(ent[3]) + 0.05: continue
		s0 = minf(s0, sp.x); s1 = maxf(s1, sp.y); nleaf += 1
	if nleaf == 0: P.append(tag + ": the entrance has no door leaves")
	elif absf(s0 - float(ent[2])) > 0.04 or absf(s1 - float(ent[3])) > 0.04: P.append("%s: door leaves %.2f..%.2f do not fill the entrance %.2f..%.2f" % [tag, s0, s1, ent[2], ent[3]])
	var cuts: Array = it.get_meta(&"cuts", [])
	var da := float(it.get_meta(&"door_along", 0.0))
	if not cuts.any(func(c: Array) -> bool: return String(c[0]) == "front" and absf(float(c[1]) - da) < 0.05): P.append(tag + ": the entrance is not cut")
	var panes: Array = it.get_meta(&"panes", [])
	for c2: Array in cuts:
		if String(c2[2]) == "door": continue
		if not panes.any(func(p2: Array) -> bool: return String(p2[0]) == String(c2[0]) and absf(float(p2[1]) - float(c2[1])) < 0.05): P.append("%s: opening %s %.2f has no glass" % [tag, c2[0], c2[1]])
	var col := it.get_node_or_null(^"col")
	var nb := 0
	if col:
		for cs: Node in col.get_children():
			if cs is CollisionShape3D:
				nb += 1
				if not ((cs as CollisionShape3D).shape is BoxShape3D): P.append("%s: col %s is not a box" % [tag, cs.name])
	if nb == 0 or nb > MAX_COL_BOXES: P.append("%s: %d col boxes" % [tag, nb])
	it.free()
	return P

## the facing rules (see facing_problems) for a bay template
static func _facing_bay(tag: String, slots: Node, f1: Array, set_k: Dictionary) -> Array:
	var P: Array = []
	var users_p: Array = set_k.get("desk_users", ["office_chair"])
	var ms: Array = slots.get_children().filter(func(n: Node) -> bool: return n is Marker3D)
	var of_type := func(types: Array) -> Array: return ms.filter(func(m: Marker3D) -> bool: return types.has(String(m.get_meta(&"slot_type", ""))))
	var nearest := func(m: Marker3D, cands: Array, maxd: float) -> Marker3D:
		var best: Marker3D = null; var bd := maxd
		for c: Marker3D in cands:
			if c == m: continue
			var d := Vector2(c.position.x - m.position.x, c.position.z - m.position.z).length()
			if d < bd: bd = d; best = c
		return best
	var dir := func(a: Marker3D, b: Marker3D) -> Vector3: var v := b.position - a.position; v.y = 0.0; return v.normalized()
	var served := {}
	for d: Marker3D in of_type.call(["desk"]):
		var users: Array = (of_type.call(["staff"]) as Array).filter(func(u: Marker3D) -> bool: return _fwd(d).dot(dir.call(d, u)) > 0.7)
		var u: Marker3D = nearest.call(d, users, 1.1)
		if u == null: P.append("%s: desk %s has no user chair in front of it" % [tag, d.name]); continue
		if _fwd(u).dot(dir.call(u, d)) < 0.7: P.append("%s: staff %s does not face its desk %s" % [tag, u.name, d.name])
		served[u] = true
		var vi: Marker3D = nearest.call(d, of_type.call(["visitor"]), 1.3)
		if vi:
			if _fwd(vi).dot(dir.call(vi, d)) < 0.7: P.append("%s: visitor %s does not face desk %s" % [tag, vi.name, d.name])
			served[vi] = true
	for c: Marker3D in of_type.call(["counter"]):
		var tl: Marker3D = nearest.call(c, of_type.call(["till"]), 1.3)
		if tl and _fwd(tl).dot(_fwd(c)) < 0.7: P.append("%s: till %s does not face the way its counter %s faces" % [tag, tl.name, c.name])
	for s: Marker3D in of_type.call(["seat"]):
		var tgt: Marker3D = nearest.call(s, of_type.call(["table", "counter"]), 1.0)
		if tgt:
			if _fwd(s).dot(dir.call(s, tgt)) < 0.5: P.append("%s: seat %s does not face %s" % [tag, s.name, tgt.name])
			served[s] = true
	var fronts: Array = of_type.call(["front"])
	if fronts.is_empty(): fronts = of_type.call(["board"])
	for r: Marker3D in of_type.call(["row"]):      # rows face the front (its side of the room: the back wall)
		if not fronts.is_empty() and _fwd(r).z * signf((fronts[0] as Marker3D).position.z - r.position.z) < 0.7: P.append("%s: row %s does not face the front" % [tag, r.name])
	for w: Marker3D in of_type.call(WALL_TYPES2):
		if served.has(w): continue
		var p := w.position
		var walls := [[p.x - float(f1[0]), Vector3(1, 0, 0)], [float(f1[2]) - p.x, Vector3(-1, 0, 0)], [p.z - float(f1[1]), Vector3(0, 0, 1)], [float(f1[3]) - p.z, Vector3(0, 0, -1)]]
		walls.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		if float(walls[0][0]) > 0.8: continue
		if _fwd(w).dot(walls[0][1]) < 0.7: P.append("%s: %s %s at a wall does not face into the room" % [tag, w.get_meta(&"slot_type"), w.name])
	return P

## one place in a bay: the template's slots (mirrored, decor shifted) filled from the kind's set, + the bay's glass,
## windows, doors, lights (as fill())
static func fill_bay(model: String, i: int, kind: String, t: String, mirror: bool, shift: int, room_name: String, bid_prefix: String) -> Node3D:
	var it: Node3D = (load(bay_path(model, i)) as PackedScene).instantiate()
	var set_k: Dictionary = sets()[kind]
	var r: RefCounted = R.new(room_name)
	var h := template_markers(it, kind, t, mirror)
	var host_h := {}
	for m: Node in h.get_children():
		var pr := _prop_for(set_k, m as Marker3D, shift)
		host_h[String(m.name)] = float(prop_info(pr).get("height", 1.0))
	for m2: Node in h.get_children():
		var mk := m2 as Marker3D
		var pr2 := _prop_for(set_k, mk, shift)
		var inf := prop_info(pr2)
		var y := mk.position.y
		var lift := float(mk.get_meta(&"lift", 0.0))
		if mk.has_meta(&"on"): y += float(host_h.get(String(mk.get_meta(&"on")), 1.0))
		elif lift > 0.0 and String(inf.get("mount", "")) == "wall": y += lift - float(inf.get("height", 0.5)) * 0.5
		elif lift > 0.0: y += 0.0
		r.call("prop", pr2, mk.position.x, mk.position.z, rad_to_deg(mk.rotation.y), y)
	h.free()
	var room := Node3D.new(); room.name = room_name
	var pn := Node3D.new(); pn.name = "Props"; room.add_child(pn)
	var props: Dictionary = r.get("_props")
	for base: String in props:
		var f := prop_file(base)
		if f == "": push_error("builtin fill_bay: no kit file for " + base); it.free(); return null
		var inst: Node = glb_scene(f)
		var src := K._first_mesh(inst)
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = src.mesh
		var ts: Array = props[base]; mm.instance_count = ts.size()
		for q in ts.size(): mm.set_instance_transform(q, (ts[q] as Transform3D) * src.transform)
		var mmi := MultiMeshInstance3D.new(); mmi.name = base; mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if src.mesh.get_surface_count() == 1:
			var wm: Material = K.prop_wear_mat(src.mesh.surface_get_material(0), R.PROP_WEAR)
			if wm != src.mesh.surface_get_material(0): mmi.material_override = wm
		pn.add_child(mmi); inst.free()
	for gi: GeometryInstance3D in room.find_children("*", "GeometryInstance3D", true, false):
		gi.visibility_range_end = PROP_END; gi.visibility_range_end_margin = 1.0
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	for nm: String in ["Glass", "Windows", "Doors", "Lights"]:
		var srcn := it.get_node_or_null(NodePath(nm))
		if srcn == null: continue
		var cp := srcn.duplicate(Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SIGNALS)
		room.add_child(cp)
		for n: Node in cp.find_children("*", "", true, false) + [cp]:
			if n.get_script() != null: n.set_meta(&"bid", bid_prefix + "|" + String(n.name))
			if n is GeometryInstance3D: (n as GeometryInstance3D).visibility_range_end = NEAR_END
	_own(room, room)
	room.set_meta(&"builtin", true); room.set_meta(&"kind", kind); room.set_meta(&"model", model); room.set_meta(&"bay", i)
	room.set_meta(&"template", t); room.set_meta(&"mirror", mirror); room.set_meta(&"decor_shift", shift)
	room.set_meta(&"floors", it.get_meta(&"floors", [])); room.set_meta(&"entrances", it.get_meta(&"entrances", []))
	room.set_meta(&"cut", []); room.set_meta(&"openings", [])
	it.free()
	return room

static func bay_col_boxes(model: String, i: int) -> Array:
	var it: Node3D = (load(bay_path(model, i)) as PackedScene).instantiate()
	var out: Array = []
	var col := it.get_node_or_null(^"col")
	if col:
		for cs: Node in col.get_children():
			if cs is CollisionShape3D: out.append([(cs as CollisionShape3D).shape, (cs as CollisionShape3D).transform])
	it.free()
	return out

## Props merged for the phone (22 Nov, INDOORS rollout: "merge props to 1-2 draws per room"): every prop instance of the
## room's Props (one MultiMesh per prop type: 8-20 draws) baked into ONE mesh per material (the kit props share their
## 2048 pages: rooms come out at 1-3 draws, page I nearly always, H often, W rarely). Same visibility range, no shadows.
## The prop transforms stay on the room as meta "props_xf" {prop: [Transform3D]} (room_people.gd reads them).
## Colour palettes (variation): the props' shader (prop_wear_fix) tints the albedo by the vertex colour's hue, so a room's
## furniture (seats, tables, benches, shelves, racks, desks: not tills, machines or appliances) takes one of PALETTES,
## dealt by the place's rank among its kind (neighbours of a kind get different ones); -1 = none.
const PALETTES := [Color(1.0, 1.0, 1.0), Color(1.0, 0.86, 0.72), Color(0.80, 0.90, 1.0), Color(0.84, 1.0, 0.84), Color(1.0, 0.80, 0.78), Color(0.95, 0.92, 0.80)]
const TINTED := ["chair", "seat", "bench", "booth", "sofa", "stool", "table", "shelf", "rack", "desk", "pew", "bookcase", "cabinet", "display", "counter"]
const UNTINTED := ["register", "till", "machine", "fridge", "freezer", "oven", "espresso", "atm", "screen", "monitor", "computer"]
static func merge_props(room: Node3D, palette := -1) -> void:
	var pn := room.get_node_or_null(^"Props")
	if pn == null: return
	var groups := {}      # material -> [arrays parts]
	var mats := {}
	var xf := {}
	var vis_end := PROP_END
	for c: Node in pn.get_children():
		if not (c is MultiMeshInstance3D): continue
		var mmi := c as MultiMeshInstance3D
		var mm := mmi.multimesh
		if mm == null or mm.mesh == null: continue
		vis_end = mmi.visibility_range_end
		var ts: Array = []
		for q in mm.instance_count: ts.append(mmi.transform * mm.get_instance_transform(q))
		xf[String(mmi.name)] = ts
		for si in mm.mesh.get_surface_count():
			var mat: Material = mmi.material_override if mmi.material_override else mm.mesh.surface_get_material(si)
			var key := str(mat.get_instance_id()) if mat else "none"
			mats[key] = mat
			if not groups.has(key): groups[key] = []
			var a: Array = mm.mesh.surface_get_arrays(si)
			var nml := String(mmi.name).to_lower()
			var tint := Color.WHITE
			if palette > 0 and TINTED.any(func(w: String) -> bool: return nml.contains(w)) and not UNTINTED.any(func(w: String) -> bool: return nml.contains(w)):
				tint = PALETTES[palette % PALETTES.size()]
			for t: Transform3D in ts: (groups[key] as Array).append([a, t, tint])
	for c2: Node in pn.get_children(): pn.remove_child(c2); c2.free()
	var gi := 0
	for key: String in groups:
		var st := SurfaceTool.new()
		var V := PackedVector3Array(); var N := PackedVector3Array(); var T := PackedFloat32Array(); var UV := PackedVector2Array()
		var UV2 := PackedVector2Array(); var C := PackedColorArray(); var I := PackedInt32Array()
		var has_t := true; var has_uv2 := true; var has_c := true
		for part: Array in groups[key]:
			var a: Array = part[0]
			if a[Mesh.ARRAY_TANGENT] == null: has_t = false
			if a[Mesh.ARRAY_TEX_UV2] == null: has_uv2 = false
			if a[Mesh.ARRAY_COLOR] == null and part[2] == Color.WHITE: has_c = false
		for part1: Array in groups[key]: if part1[2] != Color.WHITE: has_c = true
		for part2: Array in groups[key]:
			var a2: Array = part2[0]; var t2: Transform3D = part2[1]
			var bs := t2.basis
			var nb := bs.inverse().transposed()
			var v: PackedVector3Array = a2[Mesh.ARRAY_VERTEX]; var base := V.size()
			var nn: PackedVector3Array = a2[Mesh.ARRAY_NORMAL] if a2[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var uv: PackedVector2Array = a2[Mesh.ARRAY_TEX_UV] if a2[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			for k in v.size():
				V.append(t2 * v[k])
				N.append((nb * nn[k]).normalized() if k < nn.size() else Vector3.UP)
				UV.append(uv[k] if k < uv.size() else Vector2.ZERO)
			if has_t:
				var tg: PackedFloat32Array = a2[Mesh.ARRAY_TANGENT]
				for k2 in v.size():
					var tv := (bs * Vector3(tg[k2 * 4], tg[k2 * 4 + 1], tg[k2 * 4 + 2])).normalized()
					T.append(tv.x); T.append(tv.y); T.append(tv.z); T.append(tg[k2 * 4 + 3] * (1.0 if bs.determinant() > 0.0 else -1.0))
			if has_uv2: UV2.append_array(a2[Mesh.ARRAY_TEX_UV2])
			if has_c:
				var cc: PackedColorArray = a2[Mesh.ARRAY_COLOR] if a2[Mesh.ARRAY_COLOR] != null else PackedColorArray()
				if cc.size() != v.size():
					cc = PackedColorArray(); cc.resize(v.size()); cc.fill(Color.WHITE)
				var tn: Color = part2[2]
				if tn == Color.WHITE: C.append_array(cc)
				else:
					for col: Color in cc: C.append(Color(col.r * tn.r, col.g * tn.g, col.b * tn.b, col.a))
			var idx: PackedInt32Array = a2[Mesh.ARRAY_INDEX] if a2[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
			if bs.determinant() < 0.0:      # (a mirrored instance: the winding turns)
				for k3 in range(0, idx.size(), 3): I.append(base + idx[k3]); I.append(base + idx[k3 + 2]); I.append(base + idx[k3 + 1])
			else:
				for k4 in idx: I.append(base + k4)
		var arr := []; arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = N; arr[Mesh.ARRAY_TEX_UV] = UV; arr[Mesh.ARRAY_INDEX] = I
		if has_t: arr[Mesh.ARRAY_TANGENT] = T
		if has_uv2: arr[Mesh.ARRAY_TEX_UV2] = UV2
		if has_c: arr[Mesh.ARRAY_COLOR] = C
		var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		if mats[key]: am.surface_set_material(0, mats[key])
		var mi := MeshInstance3D.new(); mi.name = "merged_%d" % gi; mi.mesh = am; gi += 1
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = vis_end; mi.visibility_range_end_margin = 1.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		pn.add_child(mi); mi.owner = room
	room.set_meta(&"props_xf", xf); room.set_meta(&"prop_draws", gi); room.set_meta(&"palette", palette)

