extends SceneTree
const K := preload("res://tools/city/pilot/kit_lib.gd")
## Run-time probe of the ASSEMBLED city (audit 18 Nov). READ ONLY. Same method as the game's gate
## (docs/perf_budget_game/perf_budget.gd): street-level cameras, draw calls + triangles from the RenderingServer,
## then each group of nodes hidden in turn to see what it costs. Counts are renderer facts (valid on lavapipe);
## frame times are NOT (software GPU).
## Run: CITYKIT_LAYOUT_ONLY=1 CITYKIT_LAYOUT_EXTRA=res://map_dc/coronado/city_kit/city_grid_layout.json xvfb-run -a godot --path . \
##   --rendering-method mobile --rendering-driver vulkan --resolution 640x360 -s res://tools/city/audit/probe.gd -- --out=FILE [--detail] [--shadows]
const SPOTS := [["pilot_amber_10th", 0, 4, 0], ["pilot_res_row", 100, 9.5, -40], ["centre", 0, 6, -600], ["centre_midblock", 0, 6, -650], ["industrial", -800, 2, -1400], ["strip", 500, 4, -1200], ["apartments", 250, 6, -600],
	["civic", -200, 6, -600], ["stadium_gate", -200, 6, -500], ["gritty", -600, 6, -1000], ["waterfront", 570, 1.4, 200], ["res_std", -400, 6, -800], ["bridge_cross", 660, 4, -1200]]

func _init() -> void: _run.call_deferred()

func _cat(g: GeometryInstance3D) -> String:
	var nm := String(g.name)
	if g is MultiMeshInstance3D:
		var tier := nm.get_slice("_", nm.get_slice_count("_") - 1)
		var kind := "prop"
		if nm.begins_with("tree_") or nm.begins_with("palm_") or nm.begins_with("plant_") or nm.begins_with("hedge_"): kind = "foliage"
		elif nm.begins_with("fence_"): kind = "fence"
		return "%s_%s" % [kind, tier]
	if g.get_parent() and g.get_parent().has_meta(&"kit"): return "bldg_" + nm
	if nm == "wear": return "wear_decals"
	if nm.begins_with("ground") or nm == "Ground": return "ground"
	return "other"

func _info() -> Array:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var R := RenderingServer
	return [R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), R.get_rendering_info(R.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)]

func _run() -> void:
	var outp := "user://probe.json"; var args := OS.get_cmdline_user_args(); var detail := "--detail" in args
	var only := ""; var radius := 0.0     # --radius=R: only pieces whose centre is within R of the camera stay visible (a streamer)
	for a in args:
		if a.begins_with("--out="): outp = a.trim_prefix("--out=")
		if a.begins_with("--spots="): only = a.trim_prefix("--spots=")
		if a.begins_with("--radius="): radius = float(a.trim_prefix("--radius="))
	var R := RenderingServer
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.6, 0.7, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.66, 0.72); env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.shadow_enabled = false; sun.directional_shadow_max_distance = 220.0; root.add_child(sun)
	for i in 3: await process_frame
	var base_mem := [R.get_rendering_info(R.RENDERING_INFO_VIDEO_MEM_USED), R.get_rendering_info(R.RENDERING_INFO_TEXTURE_MEM_USED), R.get_rendering_info(R.RENDERING_INFO_BUFFER_MEM_USED), Performance.get_monitor(Performance.MEMORY_STATIC)]
	var world := Node3D.new(); world.name = "World"; root.add_child(world)
	var t0 := Time.get_ticks_msec()
	var n := K.place_layout(world).size()
	var t1 := Time.get_ticks_msec()
	for i in 5: await process_frame
	var res := {"pieces": n, "load_all_ms": t1 - t0,
		"video_mb": (R.get_rendering_info(R.RENDERING_INFO_VIDEO_MEM_USED) - base_mem[0]) / 1048576.0, "tex_mb": (R.get_rendering_info(R.RENDERING_INFO_TEXTURE_MEM_USED) - base_mem[1]) / 1048576.0,
		"buf_mb": (R.get_rendering_info(R.RENDERING_INFO_BUFFER_MEM_USED) - base_mem[2]) / 1048576.0, "static_mb": (Performance.get_monitor(Performance.MEMORY_STATIC) - base_mem[3]) / 1048576.0,
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "objects": Performance.get_monitor(Performance.OBJECT_COUNT), "resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"phys_objects": Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS), "views": []}
	print("PROBE loaded pieces=%d in %d ms video=%.0f MB tex=%.0f buf=%.0f static=%.0f nodes=%d" % [n, t1 - t0, res.video_mb, res.tex_mb, res.buf_mb, res.static_mb, res.nodes])
	# every texture the loaded city's materials use: size, format, mipmaps, bytes in video memory
	var seen := {}; var texs: Array = []
	for g0: GeometryInstance3D in world.find_children("*", "GeometryInstance3D", true, false):
		var mats: Array = []
		if g0.material_override: mats.append(g0.material_override)
		var mesh: Mesh = (g0 as MeshInstance3D).mesh if g0 is MeshInstance3D else ((g0 as MultiMeshInstance3D).multimesh.mesh if g0 is MultiMeshInstance3D and (g0 as MultiMeshInstance3D).multimesh else null)
		if mesh:
			for si in mesh.get_surface_count():
				if mesh.surface_get_material(si): mats.append(mesh.surface_get_material(si))
				if g0 is MeshInstance3D and (g0 as MeshInstance3D).get_surface_override_material(si): mats.append((g0 as MeshInstance3D).get_surface_override_material(si))
		for mt: Material in mats:
			if seen.has(mt.get_instance_id()): continue
			seen[mt.get_instance_id()] = true
			var tl: Array = []
			if mt is BaseMaterial3D:
				var bm := mt as BaseMaterial3D
				tl = [bm.albedo_texture, bm.normal_texture, bm.roughness_texture, bm.ao_texture, bm.metallic_texture, bm.emission_texture]
			elif mt is ShaderMaterial and (mt as ShaderMaterial).shader:
				for u: Dictionary in (mt as ShaderMaterial).shader.get_shader_uniform_list():
					var val: Variant = (mt as ShaderMaterial).get_shader_parameter(u.name)
					if val is Texture2D: tl.append(val)
			for tx: Variant in tl:
				if tx == null or seen.has((tx as Texture2D).get_instance_id()): continue
				seen[(tx as Texture2D).get_instance_id()] = true
				var img: Image = (tx as Texture2D).get_image()
				texs.append({"path": (tx as Texture2D).resource_path, "w": (tx as Texture2D).get_width(), "h": (tx as Texture2D).get_height(), "fmt": img.get_format() if img else -1, "mips": img.has_mipmaps() if img else false, "bytes": img.get_data_size() if img else 0})
	res["textures"] = texs; res["materials"] = seen.size() - texs.size()
	var groups := {}
	var gis: Array = world.find_children("*", "GeometryInstance3D", true, false)
	for g: GeometryInstance3D in gis:
		var c := _cat(g)
		if not groups.has(c): groups[c] = []
		groups[c].append(g)
	var gc := {}
	for c: String in groups: gc[c] = (groups[c] as Array).size()
	res["group_nodes"] = gc
	var pcen := {}
	for p: Node3D in world.get_children():
		var nm0 := String(p.get_meta(&"piece", ""))
		if nm0 == "" or nm0.begins_with("w_") or nm0.begins_with("x_"): continue
		var ab := AABB(); var first := true
		for g1: Node in p.find_children("*", "VisualInstance3D", true, false):
			var gb: AABB = (g1 as VisualInstance3D).global_transform * (g1 as VisualInstance3D).get_aabb()
			if first: ab = gb; first = false
			else: ab = ab.merge(gb)
		var c0 := ab.get_center(); pcen[p] = Vector3((floorf(c0.x / 200.0) + 0.5) * 200.0, 0, (floorf(c0.z / 200.0) + 0.5) * 200.0)
	var cam := Camera3D.new(); cam.fov = 70.0; cam.near = 0.1; cam.far = 2600.0; root.add_child(cam); cam.current = true
	for s: Array in SPOTS:
		if only != "" and not (String(s[0]) in only.split(",")): continue
		var eye := Vector3(float(s[1]), float(s[2]) + 1.7, float(s[3]))
		if radius > 0.0:
			for p: Node3D in pcen: p.visible = (pcen[p] as Vector3).distance_to(Vector3(eye.x, 0, eye.z)) <= radius
		for d: Array in [["n", Vector3(0, 0, -1)], ["e", Vector3(1, 0, 0)], ["s", Vector3(0, 0, 1)], ["w", Vector3(-1, 0, 0)]]:
			cam.global_position = eye; cam.look_at(eye + (d[1] as Vector3) * 50.0 + Vector3(0, -0.5, 0))
			sun.shadow_enabled = false
			var b: Array = await _info()
			var v := {"spot": s[0], "dir": d[0], "draws": b[0], "tris": b[1], "objects": b[2], "groups": {}}
			sun.shadow_enabled = true
			var sh: Array = await _info()
			v["draws_shadow"] = sh[0]; v["tris_shadow"] = sh[1]
			sun.shadow_enabled = false
			if detail:
				for c: String in groups:
					for g: GeometryInstance3D in groups[c]: g.visible = false
					var h: Array = await _info()
					for g: GeometryInstance3D in groups[c]: g.visible = true
					v.groups[c] = [b[0] - h[0], b[1] - h[1]]
			res.views.append(v)
			print("PROBE %s %s draws=%d tris=%d | with sun shadow draws=%d tris=%d %s" % [s[0], d[0], b[0], b[1], sh[0], sh[1], str(v.groups) if detail else ""])
	var f := FileAccess.open(outp, FileAccess.WRITE); f.store_string(JSON.stringify(res)); f.close()
	print("PROBE_DONE -> %s" % outp)
	quit()
