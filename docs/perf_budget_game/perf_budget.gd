## Phone perf budget probe / merge gate (black-dc-perffix). Needs a real renderer (xvfb + opengl3), not --headless.
## Run through tools/perf_budget.sh (one Godot process per spot, keeps RAM low). Direct:
##   godot --rendering-driver opengl3 --resolution 1280x720 --path dense_core -s res://tests/perf/perf_budget.gd -- [opts]
## opts: --spots a,b       subset of SPOTS (default all)
##       --budget          exit 1 if any spot is over BUDGET (draws / tris / video MB)
##       --detail          per-subsystem draw/tri cost and shadow share (slow: hides each node group in turn)
##       --hide Cars,...   hide top-level nodes first (measure the rest while their owner fixes them)
##       --sun MODE:MAX[:S1:S2:S3]   override the sun shadow setup (experiments)
##       --far M           camera far plane (default 2600 = player/camera_rig.gd)
##       --shots DIR       save a 1280x720 PNG per spot
## Output lines: "PERF <spot> draws= tris= video_mb= tex_mb= buf_mb= frame_ms=", "PERFG <spot> <group> ...", "PERF_BUDGET PASS|FAIL ...".
extends SceneTree
const BUDGET := {"draws": 150, "tris": 300000, "video_mb": 1024.0}   ## mid-range phone, High preset
func _initialize() -> void: _run.call_deferred()
var _re := RegEx.create_from_string("[-_]?[-0-9]+|@")
func _k(s: String) -> String: return _re.sub(s, "", true)
func _info() -> Array:
	for i in 3: await process_frame
	var R := RenderingServer
	return [R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)]
func _key(sc: Node, g: Node) -> String:
	var p := String(sc.get_path_to(g)).split("/"); var out := []
	for i in mini(p.size(), 4): out.append(_k(p[i]))
	if p.size() > 4: out.append(_k(p[p.size() - 1]))
	return "/".join(out)
func _run() -> void:
	var args := OS.get_cmdline_user_args(); var shots := ""; var detail := "--detail" in args; var budget := "--budget" in args; var fails := []
	if "--shots" in args: shots = args[args.find("--shots") + 1]; DirAccess.make_dir_recursive_absolute(shots)
	var sc: Node = load("res://test_coronado.tscn").instantiate(); root.add_child(sc)
	for i in 8: await process_frame
	if "--hide" in args:
		for nm in args[args.find("--hide") + 1].split(","):
			var hn := sc.get_node_or_null(NodePath(nm)); if hn and "visible" in hn: hn.visible = false
	if "--sun" in args:
		var sp: PackedStringArray = args[args.find("--sun") + 1].split(":")
		for sun in sc.find_children("*", "DirectionalLight3D", true, false):
			sun.directional_shadow_mode = int(sp[0]); sun.directional_shadow_max_distance = float(sp[1])
			if sp.size() > 2: sun.directional_shadow_split_1 = float(sp[2])
			if sp.size() > 3: sun.directional_shadow_split_2 = float(sp[3])
			if sp.size() > 4: sun.directional_shadow_split_3 = float(sp[4])
			print("PERF sun mode=%d max=%.0f splits=%.2f/%.2f/%.2f" % [sun.directional_shadow_mode, sun.directional_shadow_max_distance, sun.directional_shadow_split_1, sun.directional_shadow_split_2, sun.directional_shadow_split_3])
	for sun in sc.find_children("*", "DirectionalLight3D", true, false): print("PERF sun_cur mode=%d max=%.0f splits=%.2f/%.2f/%.2f atlas=%s" % [sun.directional_shadow_mode, sun.directional_shadow_max_distance, sun.directional_shadow_split_1, sun.directional_shadow_split_2, sun.directional_shadow_split_3, str(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size"))])
	var fp: Vector3 = sc.player.global_position
	var H := func(x, z): return CoronadoTerrain.height_at(x, z)
	var views := [["street_start", fp + Vector3(0, 1.6, 0), fp + Vector3(30, 1.0, -40)],
		["orange_900_se", Vector3(-1697, H.call(-1697, 3196) + 1.7, 3196), Vector3(-1671, H.call(-1671, 3142) + 1.5, 3142)],
		["orange_900_nw", Vector3(-1697, H.call(-1697, 3196) + 1.7, 3196), Vector3(-1723, H.call(-1723, 3250) + 1.5, 3250)],
		["hotel_del", Vector3(-1730, H.call(-1730, 3720) + 1.7, 3720), Vector3(-1730, 8.0, 3800)],
		["beach_village", Vector3(-1765, H.call(-1765, 3815) + 1.7, 3815), Vector3(-1800, 1.0, 3900)]]
	if "--spots" in args:
		var want: PackedStringArray = args[args.find("--spots") + 1].split(",")
		views = views.filter(func(v): return v[0] in want)
	for v in views:
		var cam := Camera3D.new(); cam.fov = 70.0; cam.near = 0.1; cam.far = float(args[args.find("--far") + 1]) if "--far" in args else 2600.0; sc.add_child(cam)
		cam.global_position = v[1]; cam.look_at(v[2]); cam.current = true
		sc.player.global_position = v[1] - Vector3(0, 1.6, 0)
		sc.world.update_streaming(Vector3(v[1].x, 0, v[1].z), true)
		for i in 80: await process_frame
		var tf := Time.get_ticks_usec()
		for i in 10: await process_frame
		var R := RenderingServer
		var base: Array = await _info()
		print("PERF %s draws=%d tris=%d video_mb=%.0f tex_mb=%.0f buf_mb=%.0f frame_ms=%.0f" % [v[0], base[0], base[1],
			R.get_rendering_info(R.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0, R.get_rendering_info(R.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0,
			R.get_rendering_info(R.RENDERING_INFO_BUFFER_MEM_USED) / 1048576.0, (Time.get_ticks_usec() - tf) / 10000.0])
		var vm: float = R.get_rendering_info(R.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0
		if base[0] > BUDGET.draws or base[1] > BUDGET.tris or vm > BUDGET.video_mb: fails.append("%s(draws=%d tris=%d video_mb=%.0f)" % [v[0], base[0], base[1], vm])
		if shots != "": root.get_viewport().get_texture().get_image().save_png(shots.path_join(v[0] + ".png"))
		# whole-scene shadow pass
		var all: Array = sc.find_children("*", "GeometryInstance3D", true, false)
		var cs := []; for g in all: cs.append(g.cast_shadow); g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ns: Array = await _info()
		for i in all.size(): all[i].cast_shadow = cs[i]
		print("PERFG %s [shadow_pass_all] draws=%d tris=%d" % [v[0], base[0] - ns[0], base[1] - ns[1]])
		if not detail: cam.queue_free(); continue
		if "--coarse" in args:   # black-dc-perf31: per-system breakdown incl. autoloads (Traffic), traffic frozen, 2-level keys
			var tr := root.get_node_or_null(^"Traffic"); if tr: tr.process_mode = Node.PROCESS_MODE_DISABLED
			var cr := sc.find_child("Crowd2", true, false); if cr: cr.process_mode = Node.PROCESS_MODE_DISABLED
			var b2: Array = await _info()
			print("PERFC %s frozen draws=%d tris=%d" % [v[0], b2[0], b2[1]])
			var CG := {}
			var srcs: Array = [sc]; if tr: srcs.append(tr)
			for s0: Node in srcs:
				for g in s0.find_children("*", "GeometryInstance3D", true, false):
					if not (g as GeometryInstance3D).is_visible_in_tree(): continue
					var p := String(root.get_path_to(g)).split("/"); var kk := []
					for i in mini(p.size() - 1, 4): kk.append(_k(p[i]))
					if p.size() > 5: kk.append(_k(p[p.size() - 1]))
					var k := "/".join(kk); if not CG.has(k): CG[k] = []
					CG[k].append(g)
			var rows := []
			for k in CG:
				for g in CG[k]: g.visible = false
				var off: Array = await _info()
				for g in CG[k]: g.visible = true
				rows.append([b2[0] - off[0], b2[1] - off[1], k, CG[k].size()])
			rows.sort_custom(func(x, y): return x[0] > y[0])
			for r in rows: if r[0] >= 2 or r[1] >= 10000: print("PERFC %s %s n=%d draws=%d tris=%d" % [v[0], r[2], r[3], r[0], r[1]])
			if tr: tr.process_mode = Node.PROCESS_MODE_INHERIT
			if cr: cr.process_mode = Node.PROCESS_MODE_INHERIT
			cam.queue_free(); continue
		var G := {}
		for g in all:
			if not (g as GeometryInstance3D).is_visible_in_tree(): continue
			var k := _key(sc, g); if not G.has(k): G[k] = []
			G[k].append(g)
		for k in G:
			for g in G[k]: g.visible = false
			var off: Array = await _info()
			for g in G[k]: g.visible = true
			var sh := []; for g in G[k]: sh.append(g.cast_shadow); g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var so: Array = await _info()
			for i in G[k].size(): G[k][i].cast_shadow = sh[i]
			var d: int = base[0] - off[0]; var t: int = base[1] - off[1]
			if d >= 3 or t >= 15000: print("PERFG %s %s n=%d draws=%d tris=%d shadow_draws=%d shadow_tris=%d" % [v[0], k, G[k].size(), d, t, base[0] - so[0], base[1] - so[1]])
		cam.queue_free()
	print("PERF_CARINT removed=%s" % str(CarModels.interior_removed))
	print("PERF_BUDGET %s budget=%s %s" % ["PASS" if fails.is_empty() else "FAIL", str(BUDGET), " ".join(fails)])
	quit(1 if budget and not fails.is_empty() else 0)
