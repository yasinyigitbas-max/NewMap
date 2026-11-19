extends SceneTree
## Tool: measure the new bicycle (assets/coronado_kit/props/bicycle, the assets branch 82d711276) for the C++ bike:
##   godot --headless --path . -s res://tools/city/traffic/bike_measure.gd
## Prints the rig's nodes (name, place, mesh triangles, box), the saddle's top, the bars' grips, the wheels' radius,
## and each tier's mesh, material and triangles.
const DIR := "res://assets/coronado_kit/props/bicycle/"

func _walk(n: Node, xf: Transform3D, depth: int) -> void:
	var t := xf
	if n is Node3D: t = xf * (n as Node3D).transform
	var line := "%s%s (%s) at %s" % ["  ".repeat(depth), n.name, n.get_class(), str(t.origin)]
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var m: Mesh = (n as MeshInstance3D).mesh
		var tris := 0
		for s in m.get_surface_count(): tris += (m.surface_get_array_index_len(s) if m.surface_get_array_index_len(s) > 0 else m.surface_get_array_len(s)) / 3
		line += "  mesh %d tris, box %s, mat %s" % [tris, str(t * m.get_aabb()), str(m.surface_get_material(0))]
	print(line)
	for c in n.get_children(): _walk(c, t, depth + 1)

func _verts(n: Node, xf: Transform3D, out: PackedVector3Array, only: String) -> void:
	var t := xf
	if n is Node3D: t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh and (only == "" or String(n.name).contains(only)):
		var m: Mesh = (n as MeshInstance3D).mesh
		for s in m.get_surface_count():
			for v in m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]: out.append(t * v)
	for c in n.get_children(): _verts(c, t, out, only)

func _initialize() -> void:
	for f in ["rig", "near", "mid", "far", "col"]:
		var ps: PackedScene = load(DIR + "prop_bicycle_cruiser_%s.glb" % f)
		var s := ps.instantiate()
		print("== %s" % f)
		_walk(s, Transform3D(), 0)
		if f == "rig":
			var vs := PackedVector3Array(); _verts(s, Transform3D(), vs, "frame")
			if vs.is_empty(): _verts(s, Transform3D(), vs, "")
			# the saddle: the highest points behind the middle; the grips: the widest points high up in front
			var top := Vector3(0, -9, 0); var gl := Vector3(-9, 0, 0); var gr := Vector3(9, 0, 0)
			for v in vs:
				if v.z < 0.05 and v.y > top.y: top = v
			var sv := PackedVector3Array(); _verts(s, Transform3D(), sv, "steer")
			var high := 0.0
			for v in sv: high = maxf(high, v.y)
			for v in sv:
				if v.x > gl.x: gl = v
				if v.x < gr.x: gr = v
			# the grip's middle: the points within 6 cm of the bar's end, averaged
			var gm := Vector3.ZERO; var gn := 0
			for v in sv: if v.x > gl.x - 0.1: gm += v; gn += 1
			if gn: print("GRIP +x middle (last 10 cm of the bar): %s" % str(gm / gn))
			print("SADDLE top %s" % str(top))
			print("GRIP +x %s   GRIP -x %s   (bars' highest %.3f)" % [str(gl), str(gr), high])
			var wv := PackedVector3Array(); _verts(s, Transform3D(), wv, "wheel_front")
			var lo := 9.0; var hi := -9.0
			for v in wv: lo = minf(lo, v.y); hi = maxf(hi, v.y)
			print("WHEEL front: y %.3f .. %.3f, radius %.3f" % [lo, hi, (hi - lo) * 0.5])
		s.free()
	quit()
