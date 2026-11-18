extends SceneTree
## Which KINDS of material the baked cells draw with that the warm-up scene (lib/warm.scn) does not contain (read-only).
## A kind = the shader (file, or the built-in code), the textures' slots in use, every on / off and choice setting.
## The engine builds a shader for a kind the first time a material of it is loaded; in a drive that is one long
## frame (phone, 18 Nov: 61-546 ms at the first cell of the civic zone, 141 ms at the first industrial cell).
##   godot --headless --path . -s res://tools/city/audit/mat_census.gd            (all cells)
##   godot --headless --path . -s res://tools/city/audit/mat_census.gd -- -1_-3 -4_-7
const RT := "res://map_dc/coronado/city_kit/runtime/"

static func sig(mt: Material) -> String:
	if mt == null: return "none"
	var s := mt.get_class()
	if mt is ShaderMaterial:
		var sh := (mt as ShaderMaterial).shader
		return s + "|" + (sh.resource_path if sh and sh.resource_path != "" and not sh.resource_path.contains("::") else ("code" + str(hash(sh.code)) if sh else "noshader"))
	for p: Dictionary in mt.get_property_list():
		if not (int(p.usage) & PROPERTY_USAGE_STORAGE): continue
		var v: Variant = mt.get(p.name)
		if v is Texture: s += "|%s=tex" % p.name
		elif v is bool or v is int: s += "|%s=%s" % [p.name, str(v)]
	return s

static func mats_of(root: Node) -> Dictionary:      # signature -> [example node, material class, where it lives]
	var out := {}
	for g: Node in root.find_children("*", "GeometryInstance3D", true, false):
		var list: Array = []
		var gi := g as GeometryInstance3D
		if gi.material_override: list.append(gi.material_override)
		var mesh: Mesh = null
		if g is MeshInstance3D: mesh = (g as MeshInstance3D).mesh
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh: mesh = (g as MultiMeshInstance3D).multimesh.mesh
		if mesh and gi.material_override == null:
			for si in mesh.get_surface_count():
				var m: Material = (g as MeshInstance3D).get_surface_override_material(si) if g is MeshInstance3D and (g as MeshInstance3D).get_surface_override_material(si) else mesh.surface_get_material(si)
				list.append(m)
		for m2: Material in list:
			var k := sig(m2)
			if not out.has(k): out[k] = [String(g.name), m2.get_class() if m2 else "none", (m2.resource_path if m2 and m2.resource_path != "" else "built into a mesh or the cell") if m2 else "-"]
	return out

func _init() -> void:
	var keys: PackedStringArray = OS.get_cmdline_user_args()
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RT + "manifest.json"))
	if keys.is_empty(): keys = PackedStringArray((man.cells as Dictionary).keys())
	var w: Node = (load(RT + "lib/warm.scn") as PackedScene).instantiate()
	var warm := mats_of(w); w.free()
	var far: Node = (load(RT + "far/far_world.scn") as PackedScene).instantiate()
	for k0: String in mats_of(far): warm[k0] = true
	far.free()
	print("MAT warm-up + far world hold %d kinds of material" % warm.size())
	var missing := {}      # sig -> [first cell, example node, class, where, cells]
	for k in keys:
		var node: Node = (load(RT + "cells/cell_%s.scn" % k) as PackedScene).instantiate()
		var ms := mats_of(node); node.free()
		for s: String in ms:
			if warm.has(s): continue
			if not missing.has(s): missing[s] = [k, ms[s][0], ms[s][1], ms[s][2], 0]
			missing[s][4] = int(missing[s][4]) + 1
	print("MAT kinds the cells use that the warm-up does not draw: %d" % missing.size())
	for s2: String in missing:
		var e: Array = missing[s2]
		print("MAT   first in cell %s (in %d cells): node %s, %s, %s | %s" % [e[0], e[4], e[1], e[2], e[3], s2.substr(0, 260)])
	quit()
