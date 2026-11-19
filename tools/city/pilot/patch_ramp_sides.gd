extends SceneTree
## Ramp sides (19 Nov; Yasin, on a junction corner: "fix those parts, they are floating. grass should gently ease into
## the cement part if not at least it shouldnt show the base ground underneath"). A kerb ramp cut through a parkway grass
## strip (road_lib._pkw_ramp, j_apt._pkw: flare 0) left the grass beside it at the walk height with a square edge 15 cm
## over the ramp: the underside showed. This tool PATCHES A SAVED PIECE, it does not re-run the piece's script:
## in the piece's "ground" mesh every vertex of the grass and the kerb face ("grass", "curb") that stands on the same
## spot (2 mm) as a vertex of the ramp ("tactile", "concrete") but more than 1 cm higher is brought down to the ramp's
## height there. The grass corner at the ramp then slopes into the ramp over its own cell (about 2 m): no step, no gap.
## Nothing else moves: it refuses to save unless every other vertex, every prop instance and every node is unchanged,
## and prints every vertex it moved. The collision of the ground is rebuilt from the patched mesh.
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/pilot/patch_ramp_sides.gd -- <piece> [<piece> ...] [--dry]
## Locked pieces: only on Yasin's word for that piece (lock.py unlock ... --by=Yasin, patch, lock.py lock).
const K := preload("res://tools/city/pilot/kit_lib.gd")
const DIR := "res://map_dc/coronado/city_kit/pieces/"
const LOWER := ["grass", "curb"]
const RAMP := ["tactile", "concrete"]

func _init() -> void: _run.call_deferred()

func _key(v: Vector3) -> Vector2i: return Vector2i(roundi(v.x * 500.0), roundi(v.z * 500.0))

func _props_sig(n: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for mm: MultiMeshInstance3D in n.find_children("*", "MultiMeshInstance3D", true, false):
		var m := mm.multimesh
		if m == null: continue
		for i in m.instance_count: out.append("%s|%s" % [mm.get_path(), m.get_instance_transform(i)])
	return out

func _run() -> void:
	var names: Array = []; var dry := false
	for a in OS.get_cmdline_user_args():
		if a == "--dry": dry = true
		elif not a.begins_with("--"): names.append(a)
	var locked: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/locked.json")) as Dictionary).get("pieces", {})
	for nm: String in names:
		if locked.has(nm) and not dry: print("RAMP %s REFUSED: locked (lock.py unlock on Yasin's word first)" % nm); continue
		var path := DIR + nm + ".scn"
		var root: Node3D = (load(path) as PackedScene).instantiate()
		var before := _props_sig(root)
		var nodes_before := root.find_children("*", "", true, false).size()
		var gi := root.get_node_or_null("ground") as MeshInstance3D
		if gi == null: print("RAMP %s: no ground mesh" % nm); root.free(); continue
		var src: ArrayMesh = gi.mesh
		# the ramp's vertices by spot
		var low := {}
		for si in src.get_surface_count():
			if not (src.surface_get_name(si) in RAMP): continue
			for v: Vector3 in (src.surface_get_arrays(si)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var k := _key(v)
				low[k] = minf(float(low.get(k, INF)), v.y)
		var out := ArrayMesh.new(); var moved := 0; var report: Array = []
		for si in src.get_surface_count():
			var arr := src.surface_get_arrays(si)
			var nm2 := src.surface_get_name(si)
			if nm2 in LOWER:
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				for i in vs.size():
					var k2 := _key(vs[i])
					if low.has(k2) and vs[i].y - float(low[k2]) > 0.01:
						report.append("%s %s (%.2f, %.2f, %.2f) -> %.2f" % [nm, nm2, vs[i].x, vs[i].y, vs[i].z, float(low[k2])])
						vs[i].y = float(low[k2]); moved += 1
				arr[Mesh.ARRAY_VERTEX] = vs
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			out.surface_set_material(si, src.surface_get_material(si))
			out.surface_set_name(si, nm2)
		for r: String in report: print("RAMP_MOVE ", r)
		if moved == 0 or dry:
			print("RAMP %s: %d vertices would move%s" % [nm, moved, " (dry)" if dry else ""]); root.free(); continue
		gi.mesh = out
		var col := root.get_node_or_null("ground_col")
		if col:
			for cs: CollisionShape3D in col.find_children("*", "CollisionShape3D", true, false): cs.shape = out.create_trimesh_shape()
		var after := _props_sig(root)
		if after != before or root.find_children("*", "", true, false).size() != nodes_before:
			print("RAMP %s REFUSED: something else differs" % nm); root.free(); continue
		K.save_piece(root, nm)
		print("RAMP %s: %d vertices moved, props and nodes identical (OK)" % [nm, moved])
		root.free()
	quit()
