extends SceneTree
## Contact shadows BETWEEN models (look job 4, 18 Nov; PROTOTYPE): what the kit's own occlusion cannot know because it is
## baked per model. For the buildings of the chosen cells of the baked city:
##   - the pavement at a building's foot: a ground strip along every facade, dark at the wall, gone 0.9 m out;
##   - the wall under an awning: found from the awning texels in the building's near mesh (city atlas AW_* regions), a
##     wall strip under the awning's lower edge, dark at the top, gone 1.5 m down.
## All in ONE mesh per run with a multiply material (contact_mul.gdshader: no lighting, no texture read) -> one draw.
## Writes runtime/look/contact_<name>.scn (derived, not in git). How it would go into the bake: docs/look_patches/contact_between.md
##   xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan -s res://tools/city/look/contact_proto.gd -- --cells=-1_-1,0_-1 --name=pilot
const RT := "res://map_dc/coronado/city_kit/runtime/"
const FOOT_OUT := 0.9      # metres the pavement darkening reaches out from the wall
const FOOT_DARK := 0.55
const AWN_DOWN := 1.5      # metres the wall darkening reaches down from an awning's edge
const AWN_DARK := 0.5
var V := PackedVector3Array(); var C := PackedColorArray(); var I := PackedInt32Array()
var regs := {}

func _init() -> void: _run.call_deferred()

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, ka: float, kb: float, kc: float, kd: float) -> void:
	var o := V.size()
	V.append_array([a, b, c, d]); C.append_array([Color(0, 0, 0, ka), Color(0, 0, 0, kb), Color(0, 0, 0, kc), Color(0, 0, 0, kd)])
	I.append_array([o, o + 1, o + 2, o, o + 2, o + 3])

func _run() -> void:
	var cells := PackedStringArray(); var nm := "proto"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cells="): cells = a.trim_prefix("--cells=").split(",", false)
		if a.begins_with("--name="): nm = a.trim_prefix("--name=")
	var rc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/city_kit/interiors/room_contracts.json")).models
	regs = JSON.parse_string(FileAccess.get_file_as_string("res://assets/coronado_kit/textures/city_layout.json")).regions
	var nb := 0; var na := 0
	for ck in cells:
		var sc: Node3D = (load(RT + "cells/cell_%s.scn" % ck) as PackedScene).instantiate()
		var bn := sc.get_node_or_null("Buildings")
		if bn == null: sc.free(); continue
		for b: Node3D in bn.get_children():
			if not b.has_meta(&"kit"): continue
			var kit := String(b.get_meta(&"kit"))
			if not rc.has(kit): continue
			var xf := sc.transform * b.transform
			var fw: Array = (rc[kit] as Dictionary).footprint_wd
			var hx := float(fw[0]) * 0.5; var hz := float(fw[1]) * 0.5
			# the pavement along the four walls (model frame, the building's foot at y 0), 3 cm over the ground
			var y := 0.03
			for e: Array in [[Vector3(-hx, y, hz), Vector3(hx, y, hz), Vector3(0, 0, 1)], [Vector3(hx, y, -hz), Vector3(-hx, y, -hz), Vector3(0, 0, -1)],
					[Vector3(hx, y, hz), Vector3(hx, y, -hz), Vector3(1, 0, 0)], [Vector3(-hx, y, -hz), Vector3(-hx, y, hz), Vector3(-1, 0, 0)]]:
				var p0: Vector3 = e[0]; var p1: Vector3 = e[1]; var out: Vector3 = (e[2] as Vector3) * FOOT_OUT
				_quad(xf * p0, xf * p1, xf * (p1 + out), xf * (p0 + out), FOOT_DARK, FOOT_DARK, 0.0, 0.0)
			nb += 1
			na += _awnings(b, xf)
		sc.free()
	var arr := []; arr.resize(Mesh.ARRAY_MAX); arr[Mesh.ARRAY_VERTEX] = V; arr[Mesh.ARRAY_COLOR] = C; arr[Mesh.ARRAY_INDEX] = I
	var nrm := PackedVector3Array(); nrm.resize(V.size()); nrm.fill(Vector3.UP); arr[Mesh.ARRAY_NORMAL] = nrm
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var m := ShaderMaterial.new(); m.shader = load("res://tools/city/look/contact_mul.gdshader")
	am.surface_set_material(0, m)
	var mi := MeshInstance3D.new(); mi.name = "contact_" + nm; mi.mesh = am; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 220.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RT + "look"))
	var ps := PackedScene.new(); ps.pack(mi)
	ResourceSaver.save(ps, RT + "look/contact_%s.scn" % nm)
	print("CONTACT %s buildings=%d awnings=%d quads=%d tris=%d" % [nm, nb, na, V.size() / 4, I.size() / 3])
	mi.free()
	quit()

## awnings of a building: triangles of its near mesh in the city atlas' AW_* regions, grouped per facade
func _awnings(b: Node3D, xf: Transform3D) -> int:
	var near: MeshInstance3D = null
	for ch in b.get_children():
		if ch is MeshInstance3D and String(ch.name).begins_with("near"): near = ch
	if near == null or near.mesh == null: return 0
	var aw: Array = []
	for k: String in regs:
		if k.begins_with("AW_"): aw.append(regs[k].uv)
	var boxes := {}      # facade key -> [min Vector3, max Vector3]
	for si in near.mesh.get_surface_count():
		var a := near.mesh.surface_get_arrays(si)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var t: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		for k in idx.size() / 3:
			var i0 := idx[k * 3]; var i1 := idx[k * 3 + 1]; var i2 := idx[k * 3 + 2]
			var cu := (t[i0] + t[i1] + t[i2]) / 3.0; cu.x = fposmod(cu.x, 1.0)
			var hit := false
			for uv: Array in aw:
				if cu.x >= float(uv[0]) and cu.x <= float(uv[2]) and cu.y >= float(uv[1]) and cu.y <= float(uv[3]): hit = true; break
			if not hit: continue
			var p := near.transform * ((v[i0] + v[i1] + v[i2]) / 3.0)
			var n := (v[i1] - v[i0]).cross(v[i2] - v[i0])
			var key := "z+" if absf(p.z) >= absf(p.x) and p.z > 0.0 else ("z-" if absf(p.z) >= absf(p.x) else ("x+" if p.x > 0.0 else "x-"))
			for q: Vector3 in [near.transform * v[i0], near.transform * v[i1], near.transform * v[i2]]:
				if not boxes.has(key): boxes[key] = [q, q]
				else: boxes[key] = [(boxes[key][0] as Vector3).min(q), (boxes[key][1] as Vector3).max(q)]
	var n := 0
	for key: String in boxes:
		var lo: Vector3 = boxes[key][0]; var hi: Vector3 = boxes[key][1]
		var y1 := lo.y; var y0 := maxf(0.05, lo.y - AWN_DOWN)
		# the wall under the awning: the awning's inner edge is the facade (+3 cm out of it)
		if key == "z+": _quad(xf * Vector3(lo.x, y1, lo.z + 0.03), xf * Vector3(hi.x, y1, lo.z + 0.03), xf * Vector3(hi.x, y0, lo.z + 0.03), xf * Vector3(lo.x, y0, lo.z + 0.03), AWN_DARK, AWN_DARK, 0.0, 0.0)
		elif key == "z-": _quad(xf * Vector3(lo.x, y1, hi.z - 0.03), xf * Vector3(hi.x, y1, hi.z - 0.03), xf * Vector3(hi.x, y0, hi.z - 0.03), xf * Vector3(lo.x, y0, hi.z - 0.03), AWN_DARK, AWN_DARK, 0.0, 0.0)
		elif key == "x+": _quad(xf * Vector3(lo.x + 0.03, y1, lo.z), xf * Vector3(lo.x + 0.03, y1, hi.z), xf * Vector3(lo.x + 0.03, y0, hi.z), xf * Vector3(lo.x + 0.03, y0, lo.z), AWN_DARK, AWN_DARK, 0.0, 0.0)
		else: _quad(xf * Vector3(hi.x - 0.03, y1, lo.z), xf * Vector3(hi.x - 0.03, y1, hi.z), xf * Vector3(hi.x - 0.03, y0, hi.z), xf * Vector3(hi.x - 0.03, y0, lo.z), AWN_DARK, AWN_DARK, 0.0, 0.0)
		n += 1
	return n
