extends SceneTree
## Piece w_power: overhead power wires for the pilot (Yasin 16 Nov: "find and add power wires within performance
## budgets, read them from main branch"). Same method as main's map_dc/coronado/furniture/power_lines.gd: sagging
## wires (parabola, sag 1.5 % of the span + 0.25 m), ONE merged mesh, one unshaded
## dark material, no shadows, no colliders, gone past 300 m.
## Lines: each alley's poles in order (the west alley line crosses 10th St), each back-lot-line of the hill houses,
## and a span from the alley line to the first back-lot pole (the alley feeds the houses). Every house and shop gets a
## service drop from its nearest pole (a lower insulator) to its back wall.
## Reads the poles and buildings from the saved pieces: re-run this piece whenever a pole moves (and never once locked).

const K := preload("res://tools/city/pilot/kit_lib.gd")
const PIECES := ["b_nw", "b_ne", "b_se", "b_sw", "r_n", "r_s"]
const INS := [-1.05, 0.35, 1.05]           # 3 conductors (as main) on the kit pole cross-arm insulators (model X), y TOP
## Budget (Yasin: "3100 triangles for cables, really?"): ONE ribbon per wire, tilted 45 deg so it reads from the
## street and from above (main draws two crossed ribbons), 5 segments per span, 3 per service drop. About 2 triangles
## per segment: the whole pilot's wiring is ~650 triangles in one draw call.
const TOP := 11.2
const DROP_Y := 9.6                          # service drops leave from below the cross-arm
const SEG := 5
const SEG_DROP := 3
const HALF_W := 0.02
const VIS_END := 300.0

var V := PackedVector3Array()
var NRM := PackedVector3Array()
var UVS := PackedVector2Array()
var tris := 0

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var poles: Array = []      # [pos Vector3, yaw]
	var blds: Array = []       # [Transform3D, name, depth, height]
	var world := Node3D.new(); root.add_child(world)
	for n: Node3D in K.place_layout(world, ["w_power"]):
		if not (String(n.get_meta(&"piece", "")) in PIECES): continue
		for mmi: MultiMeshInstance3D in n.find_children("prop_utility_pole*_near", "MultiMeshInstance3D", true, false):
			for i in mmi.multimesh.instance_count:
				var t := mmi.global_transform * mmi.multimesh.get_instance_transform(i)
				poles.append([t.origin, atan2(t.basis.x.z, t.basis.x.x) * -1.0, t])
		var bn := n.get_node_or_null("Buildings")
		if bn:
			for b: Node3D in bn.get_children():
				var nm := String(b.name)
				if nm.begins_with("single_") or nm.begins_with("double_") or nm.begins_with("carport"): continue
				var st := _stats(nm)
				if st.is_empty(): continue
				blds.append([b.global_transform, nm, float(st.footprint_wd[1]), float(st.height)])
	# ---- lines: group poles that share a line (same x for the alleys, same z for the back-lot lines)
	var groups := {}
	for i in poles.size():
		var p: Vector3 = poles[i][0]
		var key := "x%d" % roundi(p.x) if absf(absf(p.x) - 44.4) < 1.0 else "z%d" % roundi(p.z)
		if not groups.has(key): groups[key] = []
		(groups[key] as Array).append(i)
	var spans: Array = []
	for key: String in groups:
		var ids: Array = groups[key]
		var along_x := key.begins_with("z")
		ids.sort_custom(func(a: int, b: int) -> bool: return (poles[a][0].x if along_x else poles[a][0].z) < (poles[b][0].x if along_x else poles[b][0].z))
		for k in ids.size() - 1:
			if (poles[ids[k]][0] as Vector3).distance_to(poles[ids[k + 1]][0]) < 55.0: spans.append([ids[k], ids[k + 1]])
	# feed: nearest alley pole to the first back-lot pole of each side
	for key: String in groups:
		if not key.begins_with("z"): continue
		var first: int = (groups[key] as Array)[0]
		var best := -1; var bd := 1e9
		for i in poles.size():
			if absf(absf(poles[i][0].x) - 44.4) > 1.0: continue
			var d: float = (poles[i][0] as Vector3).distance_to(poles[first][0])
			if d < bd: bd = d; best = i
		if best >= 0 and bd < 45.0: spans.append([best, first])
	for s: Array in spans: _span(poles[s[0]], poles[s[1]])
	# ---- service drops
	var drops := 0
	for b: Array in blds:
		var t: Transform3D = b[0]; var d: float = b[2]; var h: float = b[3]
		var attach := t * Vector3(0.0, minf(h * 0.55, 4.5), -d * 0.5 + 0.05)
		var best2 := -1; var bd2 := 1e9
		for i in poles.size():
			var dd := Vector2(attach.x, attach.z).distance_to(Vector2(poles[i][0].x, poles[i][0].z))
			if dd < bd2: bd2 = dd; best2 = i
		if best2 < 0 or bd2 > 45.0: continue
		var pp: Vector3 = poles[best2][0]
		var to := Vector3(attach.x - pp.x, 0, attach.z - pp.z).normalized()
		_wire(pp + Vector3(0, DROP_Y, 0) + to * 0.25, attach, 0.02, 0.3, SEG_DROP)
		drops += 1
	var arr := []; arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_NORMAL] = NRM; arr[Mesh.ARRAY_TEX_UV] = UVS
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := ShaderMaterial.new(); mat.shader = load("res://map_dc/coronado/city_kit/shaders/wire.gdshader")
	am.surface_set_material(0, mat)
	am.custom_aabb = am.get_aabb().grow(1.0)
	var out := Node3D.new(); out.name = "w_power"
	var mi := MeshInstance3D.new(); mi.name = "wires"; mi.mesh = am
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; mi.visibility_range_end = VIS_END
	out.add_child(mi)
	print("w_power: poles %d, spans %d, drops %d, tris %d" % [poles.size(), spans.size(), drops, tris])
	K.save_piece(out, "w_power")
	quit()

## one span between two poles: four wires, insulators paired across the span so wires never cross
func _span(a: Array, b: Array) -> void:
	var pa: Vector3 = a[0]; var pb: Vector3 = b[0]
	var dir := Vector3(pb.x - pa.x, 0, pb.z - pa.z).normalized(); var perp := Vector3(-dir.z, 0, dir.x)
	var ia := _ins(a, perp); var ib := _ins(b, perp)
	for k in INS.size():
		_wire(ia[k], ib[k], 0.015, 0.25)

## insulator tops of a pole, sorted along `perp`
func _ins(p: Array, perp: Vector3) -> Array:
	var t: Transform3D = p[2]
	var pts: Array = []
	for x: float in INS: pts.append(t * Vector3(x, TOP, 0))
	pts.sort_custom(func(u: Vector3, w: Vector3) -> bool: return u.dot(perp) < w.dot(perp))
	return pts

func _wire(a: Vector3, b: Vector3, sag_k: float, sag_c: float, seg := SEG) -> void:
	var L := a.distance_to(b); var sag := sag_k * L + sag_c
	# one ribbon whose edges sit on the centre line; city_kit/shaders/wire.gdshader opens it toward the camera with a
	# minimum on-screen width (a fixed 4 cm ribbon broke into dashes past ~25 m). Unlocked and rebuilt for this, Yasin 16 Nov.
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

var _cache := {}
func _stats(name: String) -> Dictionary:
	if _cache.has(name): return _cache[name]
	var out := {}
	var kit := "res://assets/coronado_kit/buildings/"
	for cat in DirAccess.get_directories_at(kit):
		var p := kit + cat + "/" + name + "/stats.json"
		if FileAccess.file_exists(p): out = JSON.parse_string(FileAccess.get_file_as_string(p)); break
	_cache[name] = out
	return out
