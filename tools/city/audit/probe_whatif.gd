extends SceneTree
const K := preload("res://tools/city/pilot/kit_lib.gd")
## What-if probe (audit 18 Nov). READ ONLY, everything in memory. Same views as probe.gd, three cases per view:
##   all      = every piece loaded (what the piece files ask for today: far tiers to 1,500 m, ground without limit)
##   stream   = only the pieces whose 200 m cell is within RADIUS of the camera (a plain streamer, nothing beyond)
##   farworld = stream + ONE merged far mesh per material per 200 m cell for everything beyond (building far hulls,
##              tree cards, far props: the same triangles the pieces' far tiers hold, merged)
## Run like probe.gd:  ... -s res://tools/city/audit/probe_whatif.gd -- --out=FILE [--radius=300]
const SPOTS := [["pilot_amber_10th", 0, 4, 0], ["pilot_res_row", 100, 9.5, -40], ["centre", 0, 6, -600], ["centre_midblock", 0, 6, -650], ["industrial", -800, 2, -1400], ["strip", 500, 4, -1200], ["apartments", 250, 6, -600],
	["civic", -200, 6, -600], ["stadium_gate", -200, 6, -500], ["gritty", -600, 6, -1000], ["waterfront", 570, 1.4, 200], ["res_std", -400, 6, -800], ["bridge_cross", 660, 4, -1200]]
const CELL := 200.0

func _init() -> void: _run.call_deferred()

func _info() -> Array:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var R := RenderingServer
	return [R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)]

func _cell(p: Vector3) -> Vector2i: return Vector2i(floori(p.x / CELL), floori(p.z / CELL))
func _cc(c: Vector2i) -> Vector3: return Vector3((c.x + 0.5) * CELL, 0, (c.y + 0.5) * CELL)

var buckets := {}   # [cell, matkey] -> {mat, V, N, UV, C}
func _add(cell: Vector2i, mat: Material, mesh: Mesh, xf: Transform3D) -> void:
	for si in mesh.get_surface_count():
		var mt: Material = mat if mat else mesh.surface_get_material(si)
		var mk := mt.resource_path if mt.resource_path != "" and not mt.resource_path.contains("::") else str(mt.get_class()) + "|" + (((mt as BaseMaterial3D).albedo_texture.resource_path + str((mt as BaseMaterial3D).transparency)) if mt is BaseMaterial3D and (mt as BaseMaterial3D).albedo_texture else "x")
		var key := [cell, mk]
		if not buckets.has(key):
			var st0 := SurfaceTool.new(); st0.begin(Mesh.PRIMITIVE_TRIANGLES); buckets[key] = {"mat": mt, "st": st0, "n": 0}
		var b: Dictionary = buckets[key]; var st: SurfaceTool = b.st
		var a := mesh.surface_get_arrays(si)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var n: Variant = a[Mesh.ARRAY_NORMAL]; var uv: Variant = a[Mesh.ARRAY_TEX_UV]; var col: Variant = a[Mesh.ARRAY_COLOR]; var idx: Variant = a[Mesh.ARRAY_INDEX]
		var order: PackedInt32Array = idx if idx != null else PackedInt32Array(range(v.size()))
		var nb := xf.basis.orthonormalized()
		for i: int in order:
			st.set_normal(nb * (n as PackedVector3Array)[i] if n != null else Vector3.UP)
			st.set_uv((uv as PackedVector2Array)[i] if uv != null else Vector2.ZERO)
			st.set_color((col as PackedColorArray)[i] if col != null else Color.WHITE)
			st.add_vertex(xf * v[i])
		b.n = int(b.n) + order.size() / 3

func _run() -> void:
	var outp := "user://whatif.json"; var radius := 300.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): outp = a.trim_prefix("--out=")
		if a.begins_with("--radius="): radius = float(a.trim_prefix("--radius="))
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.6, 0.7, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.66, 0.72)
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.shadow_enabled = false; root.add_child(sun)
	var world := Node3D.new(); world.name = "World"; root.add_child(world)
	var pieces: Array = K.place_layout(world)
	for i in 5: await process_frame
	# piece -> cell (centre of everything it draws); whole-area pieces (wires, foam) stay on in every case
	var pcell := {}; var global: Array = []
	for p: Node3D in pieces:
		var nm := String(p.get_meta(&"piece"))
		if nm.begins_with("w_") or nm.begins_with("x_"): global.append(p); continue
		var ab := AABB(); var first := true
		for g: Node in p.find_children("*", "VisualInstance3D", true, false):
			var gb: AABB = (g as VisualInstance3D).global_transform * (g as VisualInstance3D).get_aabb()
			if first: ab = gb; first = false
			else: ab = ab.merge(gb)
		pcell[p] = _cell(ab.get_center())
		# far tier of this piece -> the far world of its cell
		for g2: Node in p.find_children("*", "GeometryInstance3D", true, false):
			var nm2 := String(g2.name)
			if g2 is MultiMeshInstance3D and nm2.ends_with("_far"):
				var mmi := g2 as MultiMeshInstance3D; var mm := mmi.multimesh
				for i in mm.instance_count: _add(pcell[p], mmi.material_override, mm.mesh, mmi.global_transform * mm.get_instance_transform(i))
			elif g2 is MeshInstance3D and nm2 == "far" and g2.get_parent().has_meta(&"kit"):
				_add(pcell[p], (g2 as MeshInstance3D).material_override, (g2 as MeshInstance3D).mesh, (g2 as MeshInstance3D).global_transform)
	var far := Node3D.new(); far.name = "FarWorld"; root.add_child(far)
	var fcells := {}; var ftris := 0; var mats := {}
	for key: Array in buckets:
		var b: Dictionary = buckets[key]
		var am: ArrayMesh = (b.st as SurfaceTool).commit(); am.surface_set_material(0, b.mat)
		var mi := MeshInstance3D.new(); mi.mesh = am; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; far.add_child(mi)
		if not fcells.has(key[0]): fcells[key[0]] = []
		fcells[key[0]].append(mi); ftris += int(b.n); mats[key[1]] = true
	print("WHATIF far world: %d cells, %d meshes, %d materials, %d triangles" % [fcells.size(), buckets.size(), mats.size(), ftris])
	var res := {"radius": radius, "far_cells": fcells.size(), "far_meshes": buckets.size(), "far_materials": mats.size(), "far_tris": ftris, "views": []}
	var cam := Camera3D.new(); cam.fov = 70.0; cam.near = 0.1; cam.far = 2600.0; root.add_child(cam); cam.current = true
	for s: Array in SPOTS:
		var eye := Vector3(float(s[1]), float(s[2]) + 1.7, float(s[3])); var e2 := Vector3(eye.x, 0, eye.z)
		for d: Array in [["n", Vector3(0, 0, -1)], ["e", Vector3(1, 0, 0)], ["s", Vector3(0, 0, 1)], ["w", Vector3(-1, 0, 0)]]:
			cam.global_position = eye; cam.look_at(eye + (d[1] as Vector3) * 50.0 + Vector3(0, -0.5, 0))
			for p: Node3D in pcell: p.visible = true
			far.visible = false
			var all: Array = await _info()
			var loaded := 0
			for p: Node3D in pcell:
				p.visible = _cc(pcell[p]).distance_to(e2) <= radius
				if p.visible: loaded += 1
			var st: Array = await _info()
			far.visible = true
			for c: Vector2i in fcells:
				for mi: MeshInstance3D in fcells[c]: mi.visible = _cc(c).distance_to(e2) > radius
			var fw: Array = await _info()
			res.views.append({"spot": s[0], "dir": d[0], "all": all, "stream": st, "farworld": fw, "loaded": loaded})
			print("WHATIF %s %s all=%d/%d stream=%d/%d farworld=%d/%d loaded_pieces=%d" % [s[0], d[0], all[0], all[1], st[0], st[1], fw[0], fw[1], loaded])
	var f := FileAccess.open(outp, FileAccess.WRITE); f.store_string(JSON.stringify(res)); f.close()
	print("WHATIF_DONE"); quit()
