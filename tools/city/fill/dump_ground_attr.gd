extends SceneTree
## The ground of pieces, with what a patch beside it needs to look the same (28 Nov night; tools/city/fill/fill_holes.py):
## for every MeshInstance3D named "ground" in a saved piece, each surface's name and material (its resource path) and,
## per triangle, the three vertices in the piece's own frame, their UVs and their colours (white where the mesh has
## none). It only reads: nothing is saved back.
##   godot --headless --path . -s res://tools/city/fill/dump_ground_attr.gd -- --names=a,b,c --out=res://OUT/fill/attr/
## Per piece: <out>/<name>.json ({"surfaces": [{"name", "mat", "tris", "off"}]}) and <out>/<name>.bin (float32, per
## vertex: x y z u v r g b = 8 floats, 3 vertices a triangle).
const PIECES := "res://map_dc/coronado/city_kit/pieces/"

func _init() -> void: _run.call_deferred()

func _to_root(n: Node, root: Node) -> Transform3D:
	var t := Transform3D()
	var c := n
	while c != null and c != root:
		if c is Node3D: t = (c as Node3D).transform * t
		c = c.get_parent()
	return t

func _run() -> void:
	var names: PackedStringArray = []
	var out := "res://OUT/fill/attr/"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--names="): names = a.trim_prefix("--names=").split(",", false)
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var done := 0
	for name in names:
		var path := PIECES + name + ".scn"
		if not ResourceLoader.exists(path): print("ATTR missing ", name); continue
		var root: Node = (load(path) as PackedScene).instantiate()
		var buf := PackedFloat32Array()
		var surfs: Array = []
		for m in root.find_children("ground", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.mesh == null: continue
			var xf := _to_root(mi, root)
			for s in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(s)
				var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var UV: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
				var C: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
				var I: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				var n := I.size() if not I.is_empty() else V.size()
				var mat: Material = mi.get_active_material(s)
				var off := buf.size()
				for k in n:
					var vi := I[k] if not I.is_empty() else k
					var p := xf * V[vi]
					var uv := UV[vi] if vi < UV.size() else Vector2()
					var c := C[vi] if vi < C.size() else Color.WHITE
					buf.append_array([p.x, p.y, p.z, uv.x, uv.y, c.r, c.g, c.b])
				surfs.append({"name": String(mi.mesh.surface_get_name(s)) if mi.mesh is ArrayMesh else "", "mat": mat.resource_path if mat else "", "tris": n / 3, "off": off})
		var f := FileAccess.open(out + name + ".bin", FileAccess.WRITE); f.store_buffer(buf.to_byte_array()); f.close()
		var j := FileAccess.open(out + name + ".json", FileAccess.WRITE); j.store_string(JSON.stringify({"surfaces": surfs})); j.close()
		root.free()
		done += 1
	print("ATTR dumped %d pieces to %s" % [done, out])
	quit()
