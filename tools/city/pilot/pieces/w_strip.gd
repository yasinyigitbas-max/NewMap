extends SceneTree
## Piece w_strip (commercial strip sample; same method as w_ind): overhead wires along each leg's poles (same method and budget as w_power: 3
## conductors, one tilted ribbon, 5 segments per span, one draw) and a service drop from the nearest pole to each
## building of the four quadrants. Re-run whenever a pole or building moves; never once locked.
## Built in WORLD coordinates: its layout row must stay at pos [0, 0, 0] (16 Nov: it was placed at the site offset too,
## so every wire hung 400 m away over empty ground).
## The line turns each junction corner (first poles of neighbouring legs joined, over the corner), and feeds the
## private transformer poles in the yards; those poles feed the back-row buildings. Drops land on the wall facing the
## pole (never the building centre: the wire would pass through the roof).
const K := preload("res://tools/city/pilot/kit_lib.gd")
const INS := [-1.05, 0.35, 1.05]
const TOP := 11.2
const HALF_W := 0.02
var V := PackedVector3Array()
var NRM := PackedVector3Array()
var UVS := PackedVector2Array()
var tris := 0
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var world := Node3D.new(); root.add_child(world)
	var legs: Array = []; var blds: Array = []; var yard: Array = []
	for n: Node3D in K.place_layout(world, ["w_power", "w_strip"]):
		var pc := String(n.get_meta(&"piece", ""))
		if pc == "s_strip_art":
			var ps: Array = []
			for mmi: MultiMeshInstance3D in n.find_children("prop_utility_pole*_near", "MultiMeshInstance3D", true, false):
				for i in mmi.multimesh.instance_count: ps.append(mmi.global_transform * mmi.multimesh.get_instance_transform(i))
			var o := n.global_position
			ps.sort_custom(func(a: Transform3D, b: Transform3D) -> bool: return a.origin.distance_to(o) < b.origin.distance_to(o))   # out from the junction
			legs.append(ps)
		elif pc.begins_with("m_"):
			for b: Node3D in n.get_node("Buildings").get_children(): blds.append(b)
			for mmi: MultiMeshInstance3D in n.find_children("prop_utility_pole_transformer*_near", "MultiMeshInstance3D", true, false):
				for i in mmi.multimesh.instance_count: yard.append(mmi.global_transform * mmi.multimesh.get_instance_transform(i))
	var all: Array = []
	for ps: Array in legs:
		for k in ps.size() - 1: _span(ps[k], ps[k + 1])
		all.append_array(ps)
	# round the corners: each leg's first pole to the nearest first pole of another leg (each pair once)
	var done := {}
	for i in legs.size():
		var a: Transform3D = legs[i][0]; var bj := -1; var bd0 := 1e9
		for j in legs.size():
			if j == i or done.has("%d_%d" % [mini(i, j), maxi(i, j)]): continue
			var d0 := a.origin.distance_to((legs[j][0] as Transform3D).origin)
			if d0 < bd0: bd0 = d0; bj = j
		if bj >= 0 and bd0 < 66.0:   # the arterial line crosses the junction
			_span(a, legs[bj][0]); done["%d_%d" % [mini(i, bj), maxi(i, bj)]] = true
	# yard transformer poles: fed from the nearest street pole
	var street := all.duplicate()
	for t: Transform3D in yard:
		var bs: Transform3D; var bd1 := 1e9
		for u: Transform3D in street:
			var d1 := t.origin.distance_to(u.origin)
			if d1 < bd1: bd1 = d1; bs = u
		if bd1 < 70.0: _span(bs, t)
		all.append(t)
	var drops := 0
	for b: Node3D in blds:
		var near := b.get_node_or_null("near") as MeshInstance3D
		if near == null: continue
		var bb := near.mesh.get_aabb()
		var inv := b.global_transform.affine_inverse()
		var best: Transform3D; var bd := 1e9; var att := Vector3.ZERO
		for t: Transform3D in all:
			# nearest point of the footprint outline to the pole, in the building's frame, just outside the wall
			var lp := inv * t.origin
			var cx := clampf(lp.x, bb.position.x + 0.5, bb.end.x - 0.5); var cz := clampf(lp.z, bb.position.z + 0.5, bb.end.z - 0.5)
			if absf(lp.x - cx) > absf(lp.z - cz): cx = bb.end.x + 0.05 if lp.x > 0.0 else bb.position.x - 0.05
			else: cz = bb.end.z + 0.05 if lp.z > 0.0 else bb.position.z - 0.05
			var wp := b.global_transform * Vector3(cx, minf(bb.end.y * 0.6, 4.5), cz)
			var d := Vector2(t.origin.x - wp.x, t.origin.z - wp.z).length()
			if d < bd: bd = d; best = t; att = wp
		if bd > 35.0: continue   # no long drops over other roofs
		var to := Vector3(att.x - best.origin.x, 0, att.z - best.origin.z).normalized()
		_wire(best.origin + Vector3(0, 9.6, 0) + to * 0.25, att, 0.02, 0.3, 3); drops += 1
	var arr := []; arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = NRM; arr[Mesh.ARRAY_TEX_UV] = UVS
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := ShaderMaterial.new(); mat.shader = load("res://map_dc/coronado/city_kit/shaders/wire.gdshader")
	am.surface_set_material(0, mat)
	am.custom_aabb = am.get_aabb().grow(1.0)   # the shader widens the ribbon a little past the stored centre line
	var out := Node3D.new(); out.name = "w_strip"
	var mi := MeshInstance3D.new(); mi.name = "wires"; mi.mesh = am; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; mi.visibility_range_end = 300.0
	out.add_child(mi)
	print("w_strip: legs %d, poles %d (yard %d), drops %d, tris %d" % [legs.size(), all.size(), yard.size(), drops, tris])
	K.save_piece(out, "w_strip")
	quit()

func _span(a: Transform3D, b: Transform3D) -> void:
	var dir := Vector3(b.origin.x - a.origin.x, 0, b.origin.z - a.origin.z).normalized(); var perp := Vector3(-dir.z, 0, dir.x)
	var ia: Array = []; var ib: Array = []
	for x: float in INS: ia.append(a * Vector3(x, TOP, 0)); ib.append(b * Vector3(x, TOP, 0))
	ia.sort_custom(func(u: Vector3, w: Vector3) -> bool: return u.dot(perp) < w.dot(perp))
	ib.sort_custom(func(u: Vector3, w: Vector3) -> bool: return u.dot(perp) < w.dot(perp))
	for k in INS.size(): _wire(ia[k], ib[k], 0.015, 0.25, 5)

func _wire(a: Vector3, b: Vector3, sag_k: float, sag_c: float, seg: int) -> void:
	var L := a.distance_to(b); var sag := sag_k * L + sag_c
	# both edges sit on the centre line; the wire shader (city_kit/shaders/wire.gdshader) opens them toward the camera
	var prev := a
	for t in range(1, seg + 1):
		var u := float(t) / seg
		var q := a.lerp(b, u) - Vector3(0, 4.0 * sag * u * (1.0 - u), 0)
		var dir := (q - prev).normalized()
		V.append_array(PackedVector3Array([prev, q, q, prev, q, prev]))
		for k in 6: NRM.append(dir)
		UVS.append_array(PackedVector2Array([Vector2(-1, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(1, 0)]))
		tris += 2
		prev = q
