extends SceneTree
## Shop trim (21 Nov 2026, Yasin: "reduce the number of shops to 100 ... replace them with buildings fitting into their
## scene and size, preferably out of unused buildings from our kit"; then "Yes, unlock the pieces and apply the shop plan").
## Swaps listed kit buildings of SAVED pieces for other kit buildings, drop-in: the building node keeps its name, its
## place in the Buildings list, its turn (front to the street) and its pad height; only its kit model changes, and it
## slides along its own front axis by "shift" so the new front stands on the old front line (kit origin = footprint
## centre, front = +Z). Its LOD tiers and collision come from kit_lib.building, as every kit building's do; its wear
## amount is the old building's (read off its near material, bw_<atlas>_<wear>.tres). NOTHING else in the piece is
## touched: no piece script runs, no prop moves (the superchecker deals with props the old walls and roofs held).
## Real renderer (mesh and MultiMesh data are empty under --headless):
##   xvfb-run -a godot --path . --rendering-method mobile -s res://tools/city/pilot/swap_buildings.gd -- --list=<json> --piece=<name> --out=<scn>
## list: {"<piece>": [{"name": node name, "old": old kit, "kit": new kit, "shift": metres along +Z}, ...]}
## Doors to their paths (Yasin, 21 Nov: "make sure each replacement building's front door lines up with the existing
## path/walk leading to it from the street"): --walks=<json> (the shop trim's plan_walks.py) gives per piece
##   "xoff": {name: metres along the building's own +X} (a slide along its frontage, inside the old footprint) and
##   "cells": quads [[x, y, z] x 4] in the piece's frame: concrete laid 2.5 cm over soft ground (a front walk joining the
##   doors and the old path ends, or a walk from the door out to the sidewalk). They are appended to the ground mesh's
##   own "concrete" surface (its uv and colour continued from that surface); nothing else in the ground changes.
const K := preload("res://tools/city/pilot/kit_lib.gd")

func _init() -> void: _run.call_deferred()

func _arg(n: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + n + "="): return a.trim_prefix("--" + n + "=")
	return ""

func _own(n: Node, top: Node) -> void:
	for c in n.get_children():
		c.owner = top; _own(c, top)

func _run() -> void:
	PortableCompressedTexture2D.set_keep_all_compressed_buffers(true)
	var piece := _arg("piece")
	var list: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_arg("list")))
	var swaps: Array = list.get(piece, [])
	var src := "res://map_dc/coronado/city_kit/pieces/%s.scn" % piece
	var top: Node = (ResourceLoader.load(src, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	var bl := top.get_node_or_null("Buildings") as Node3D
	if bl == null: print("SWAP %s: no Buildings node" % piece); quit(1); return
	var done := 0
	var walks: Dictionary = {}
	if _arg("walks") != "": walks = (JSON.parse_string(FileAccess.get_file_as_string(_arg("walks"))) as Dictionary).get(piece, {})
	for s: Dictionary in swaps:
		var old := bl.get_node_or_null(NodePath(String(s.name))) as Node3D
		if old == null or String(old.get_meta(&"kit", "")) != String(s.old):
			print("SWAP %s: REFUSED %s (not there or not %s)" % [piece, s.name, s.old]); top.free(); quit(1); return
		var wear := 0.65
		var near := old.get_node_or_null("near") as MeshInstance3D
		if near and near.get_surface_override_material(0):
			var f := near.get_surface_override_material(0).resource_path.get_file().get_basename()
			var w := f.get_slice("_", f.get_slice_count("_") - 1)
			if w.is_valid_int(): wear = int(w) / 100.0
		var idx := old.get_index()
		var xf := old.transform
		var shift := float(s.get("shift", 0.0))
		var xoff := float((walks.get("xoff", {}) as Dictionary).get(String(s.name), 0.0))
		var pos := xf.origin + xf.basis.z.normalized() * shift + xf.basis.x.normalized() * xoff
		bl.remove_child(old); old.free()
		var nb := K.building(bl, String(s.kit), pos, 0.0, String(s.name), wear)
		nb.transform = Transform3D(xf.basis, pos)
		bl.move_child(nb, idx)
		nb.owner = top; _own(nb, top)
		print("SWAP %s: %s %s -> %s (shift %+.2f m along its front axis, %+.2f m along its frontage, wear %.2f)" % [piece, s.name, s.old, s.kit, shift, xoff, wear])
		done += 1
	var cells: Array = walks.get("cells", [])
	if not cells.is_empty():
		var n := _walks(top, cells)
		if n < 0: print("SWAP %s: REFUSED walks (no ground concrete surface)" % piece); top.free(); quit(1); return
		print("SWAP %s: walks: %d concrete cells laid" % [piece, n])
	var ps := PackedScene.new(); ps.pack(top)
	var err := ResourceSaver.save(ps, _arg("out"), ResourceSaver.FLAG_COMPRESS)
	print("SWAP_DONE %s swapped=%d saved=%s (%s)" % [piece, done, _arg("out"), error_string(err)])
	top.free()
	quit(0 if err == OK and done == swaps.size() else 1)

## concrete cells appended to the ground's "concrete" surface; uv and colour continued from the surface (a plane fit of
## uv over x, z; the surface's mean colour), the normal up, the winding the surface's own
func _walks(top: Node, cells: Array) -> int:
	var g := top.get_node_or_null("ground") as MeshInstance3D
	if g == null or not (g.mesh is ArrayMesh): return -1
	var m := g.mesh as ArrayMesh
	var si := -1
	for i in m.get_surface_count():
		if m.surface_get_name(i) == "concrete": si = i
	if si < 0: return -1
	var nm := ArrayMesh.new()
	for i in m.get_surface_count():
		var arr := m.surface_get_arrays(i)
		if i == si: arr = _append(arr, cells)
		nm.add_surface_from_arrays(m.surface_get_primitive_type(i), arr)
		nm.surface_set_name(i, m.surface_get_name(i))
		nm.surface_set_material(i, m.surface_get_material(i))
	nm.resource_name = m.resource_name
	g.mesh = nm
	return cells.size()

func _fit(v: PackedVector3Array, uv: PackedVector2Array) -> Array:      # least squares u = a x + b z + c (same for v)
	var sxx := 0.0; var sxz := 0.0; var szz := 0.0; var sx := 0.0; var sz := 0.0; var n := float(v.size())
	var su := Vector3.ZERO; var sv := Vector3.ZERO
	for k in v.size():
		var p := v[k]; sxx += p.x * p.x; sxz += p.x * p.z; szz += p.z * p.z; sx += p.x; sz += p.z
		su += Vector3(p.x, p.z, 1.0) * uv[k].x; sv += Vector3(p.x, p.z, 1.0) * uv[k].y
	var A := Basis(Vector3(sxx, sxz, sx), Vector3(sxz, szz, sz), Vector3(sx, sz, n))      # symmetric: columns = rows
	if absf(A.determinant()) < 1e-9: return [Vector3(1, 0, 0), Vector3(0, 1, 0)]
	var inv := A.inverse()
	return [inv * su, inv * sv]

func _append(arr: Array, cells: Array) -> Array:      # (packed arrays are values: taken out, grown, put back)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var has_idx: bool = arr[Mesh.ARRAY_INDEX] != null
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if has_idx else PackedInt32Array()
	var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var tan: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT] if arr[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
	var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2] if arr[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
	var tri0: Array = [v[idx[0]], v[idx[1]], v[idx[2]]] if idx.size() >= 3 else [v[0], v[1], v[2]]
	var up_sign := signf((tri0[1] - tri0[0]).cross(tri0[2] - tri0[0]).y)
	var fu: Array = _fit(v, uv) if uv.size() == v.size() and uv.size() > 0 else []
	var fu2: Array = _fit(v, uv2) if uv2.size() == v.size() and uv2.size() > 0 else []
	var col := Color(0, 0, 0, 0)
	for c: Color in cols: col += c
	if cols.size() > 0: col = col / float(cols.size())
	for q: Array in cells:
		var p: Array = []
		for c: Array in q: p.append(Vector3(float(c[0]), float(c[1]), float(c[2])))
		for t: Array in [[p[0], p[1], p[2]], [p[0], p[2], p[3]]]:
			if signf((t[1] - t[0]).cross(t[2] - t[0]).y) != up_sign: t = [t[0], t[2], t[1]]
			for w: Vector3 in t:
				if has_idx: idx.append(v.size())
				v.append(w)
				if arr[Mesh.ARRAY_NORMAL] != null: nrm.append(Vector3.UP)
				if arr[Mesh.ARRAY_TANGENT] != null: tan.append_array(PackedFloat32Array([1, 0, 0, 1]))
				if arr[Mesh.ARRAY_COLOR] != null: cols.append(col)
				var k3 := Vector3(w.x, w.z, 1)
				if arr[Mesh.ARRAY_TEX_UV] != null: uv.append(Vector2(fu[0].dot(k3), fu[1].dot(k3)) if not fu.is_empty() else Vector2.ZERO)
				if arr[Mesh.ARRAY_TEX_UV2] != null: uv2.append(Vector2(fu2[0].dot(k3), fu2[1].dot(k3)) if not fu2.is_empty() else Vector2.ZERO)
	arr[Mesh.ARRAY_VERTEX] = v
	if has_idx: arr[Mesh.ARRAY_INDEX] = idx
	if arr[Mesh.ARRAY_NORMAL] != null: arr[Mesh.ARRAY_NORMAL] = nrm
	if arr[Mesh.ARRAY_TANGENT] != null: arr[Mesh.ARRAY_TANGENT] = tan
	if arr[Mesh.ARRAY_COLOR] != null: arr[Mesh.ARRAY_COLOR] = cols
	if arr[Mesh.ARRAY_TEX_UV] != null: arr[Mesh.ARRAY_TEX_UV] = uv
	if arr[Mesh.ARRAY_TEX_UV2] != null: arr[Mesh.ARRAY_TEX_UV2] = uv2
	return arr
