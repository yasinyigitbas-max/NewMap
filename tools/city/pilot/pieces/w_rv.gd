extends SceneTree
## Piece w_rv (residential growth, pilot area, 18 Nov): the overhead lines of the residential quadrants (r_q_*). Power
## runs down the ALLEYS here (Coronado's village pattern; the streets stay clear for the trees): the poles of every
## quadrant (meta "poles") are joined along each alley line across the whole area - neighbouring quadrants' halves of
## an alley meet at mid-block - and each house gets its service drop from the nearest pole to the wall facing it.
## Budget (Yasin: "~700 tris per area" for cables): a residential secondary is two conductors (not the alley trunk's
## three), drops in two segments: about 550 triangles a 200 m block, one draw, the camera-facing wire shader.
## Built in GRID coordinates from city_grid_layout.json: its layout row stays at [0, 0, 0]. Re-run whenever a quadrant
## is rebuilt; never once locked.
const K := preload("res://tools/city/pilot/kit_lib.gd")
const INS := [-0.7, 0.7]
const TOP := 11.2
var V := PackedVector3Array()
var NRM := PackedVector3Array()
var UVS := PackedVector2Array()
var tris := 0
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var world := Node3D.new(); root.add_child(world)
	var lines := {}; var blds: Array = []; var all: Array = []
	for n: Node3D in K.place_layout(world):
		var pc := String(n.get_meta(&"piece", ""))
		if not pc.begins_with("r_q_"): continue
		for e: Array in n.get_meta(&"poles", []):
			var t := n.transform * Transform3D(Basis(Vector3.UP, deg_to_rad(float(e[1]))), e[0])
			var along_x := absf(float(e[1]) - 90.0) < 1.0
			var key := ("x_%d" % roundi(t.origin.z)) if along_x else ("z_%d" % roundi(t.origin.x))
			if not lines.has(key): lines[key] = []
			(lines[key] as Array).append(t); all.append(t)
		for b: Node3D in n.get_node("Buildings").get_children():
			if String(b.get_meta(&"kit", "")).begins_with("houses/") or String(b.get_meta(&"kit", "")).begins_with("commercial/"): blds.append(b)
	var spans := 0
	for key: String in lines:
		var ps: Array = lines[key]
		var along_x := key.begins_with("x_")
		ps.sort_custom(func(a: Transform3D, b: Transform3D) -> bool: return (a.origin.x if along_x else a.origin.z) < (b.origin.x if along_x else b.origin.z))
		for k in ps.size() - 1:
			if (ps[k] as Transform3D).origin.distance_to((ps[k + 1] as Transform3D).origin) < 40.0: _span(ps[k], ps[k + 1]); spans += 1
	var drops := 0
	for b: Node3D in blds:
		var near := b.get_node_or_null("near") as MeshInstance3D
		if near == null: continue
		var bb := near.mesh.get_aabb()
		var inv := b.global_transform.affine_inverse()
		var best2: Transform3D; var bd := 1e9; var att := Vector3.ZERO
		for t: Transform3D in all:
			var lp := inv * t.origin
			var cx := clampf(lp.x, bb.position.x + 0.5, bb.end.x - 0.5); var cz := clampf(lp.z, bb.position.z + 0.5, bb.end.z - 0.5)
			if absf(lp.x - cx) > absf(lp.z - cz): cx = bb.end.x + 0.05 if lp.x > 0.0 else bb.position.x - 0.05
			else: cz = bb.end.z + 0.05 if lp.z > 0.0 else bb.position.z - 0.05
			var wp := b.global_transform * Vector3(cx, minf(bb.end.y * 0.6, 4.5), cz)
			var d2 := Vector2(t.origin.x - wp.x, t.origin.z - wp.z).length()
			if d2 < bd: bd = d2; best2 = t; att = wp
		if bd > 34.0: continue
		var to := Vector3(att.x - best2.origin.x, 0, att.z - best2.origin.z).normalized()
		_wire(best2.origin + Vector3(0, 9.6, 0) + to * 0.25, att, 0.02, 0.3, 2); drops += 1
	var arr := []; arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = NRM; arr[Mesh.ARRAY_TEX_UV] = UVS
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := ShaderMaterial.new(); mat.shader = load("res://map_dc/coronado/city_kit/shaders/wire.gdshader")
	am.surface_set_material(0, mat)
	am.custom_aabb = am.get_aabb().grow(1.0)
	var out := Node3D.new(); out.name = "w_rv"
	var mi := MeshInstance3D.new(); mi.name = "wires"; mi.mesh = am; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; mi.visibility_range_end = 300.0
	out.add_child(mi)
	print("w_rv: lines %d, poles %d, spans %d, drops %d, tris %d" % [lines.size(), all.size(), spans, drops, tris])
	K.save_piece(out, "w_rv")
	quit()

func _span(a: Transform3D, b: Transform3D) -> void:
	var dir := Vector3(b.origin.x - a.origin.x, 0, b.origin.z - a.origin.z).normalized(); var perp := Vector3(-dir.z, 0, dir.x)
	var ia: Array = []; var ib: Array = []
	for x: float in INS: ia.append(a * Vector3(x, TOP, 0)); ib.append(b * Vector3(x, TOP, 0))
	ia.sort_custom(func(u: Vector3, w: Vector3) -> bool: return u.dot(perp) < w.dot(perp))
	ib.sort_custom(func(u: Vector3, w: Vector3) -> bool: return u.dot(perp) < w.dot(perp))
	for k in INS.size(): _wire(ia[k], ib[k], 0.015, 0.25, 4)

func _wire(a: Vector3, b: Vector3, sag_k: float, sag_c: float, seg: int) -> void:
	var L := a.distance_to(b); var sag := sag_k * L + sag_c
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
