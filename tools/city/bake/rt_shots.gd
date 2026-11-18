extends SceneTree
const Stream := preload("res://tools/city/bake/city_stream.gd")
const Lights := preload("res://tools/city/bake/city_lights.gd")
const Plates := preload("res://tools/city/bake/sign_plates.gd")
## Preview and measure the BAKED city (city_kit/runtime) through the streamer. Same sun, sky and flat ground as
## tools/city/pilot/preview/shots.gd, so a shot here can be laid beside a shot of the raw pieces.
##   ... -s res://tools/city/bake/rt_shots.gd -- --out=DIR "--cams=name:x,y,z:tx,ty,tz;..."     pictures + draws / tris
##   ... -- --probe            the audit's street spots x 4 directions: PROBE lines (draws, tris) like tools/city/audit/probe.gd
##   ... -- --drive=x0,z0,x1,z1,speed    move the focus along a line and report every cell added (ms on the main thread)
##   options: --night=0..1   --wind=strength   --frames=N (N pictures per camera, run with --fixed-fps 20 for a clip)
##            --runtime=res://...   --hold=frames before each shot (default 40)
##            --lights=N  (with --night) the N lamps nearest the camera as real lights (city_lights.gd; stock engine: <= 8)
##   trials, in memory only (nothing baked or saved changes):
##            --tint      a paint tint + wear per building, fixed by its name     --plates   shop-name plates over the painted signs
##            --only=PREFIX  the two trials touch only buildings whose name starts with PREFIX (a sample: "a_")
const SPOTS := [["pilot_amber_10th", 0, 4, 0], ["pilot_res_row", 100, 9.5, -40], ["centre", 0, 6, -600], ["centre_midblock", 0, 6, -650], ["industrial", -800, 2, -1400], ["strip", 500, 4, -1200], ["apartments", 250, 6, -600],
	["civic", -200, 6, -600], ["stadium_gate", -200, 6, -500], ["gritty", -600, 6, -1000], ["waterfront", 570, 1.4, 200], ["res_std", -400, 6, -800], ["bridge_cross", 660, 4, -1200]]
func _init() -> void: _run.call_deferred()
func _v(s: String) -> Vector3:
	var f := s.split_floats(","); return Vector3(f[0], f[1], f[2])
func _info() -> Array:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var R := RenderingServer
	return [R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), R.get_rendering_info(R.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)]
func _run() -> void:
	var out := "user://rt_shots"; var cams: Array = []; var probe := false; var night := 0.0; var wind := 1.0; var frames := 1; var rt := "res://map_dc/coronado/city_kit/runtime/"; var hold := 40; var drive := PackedFloat64Array(); var only := ""; var detail := false; var tint := false; var plates := false; var nlights := 0; var prefix := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a == "--probe": probe = true
		if a == "--detail": detail = true
		if a == "--tint": tint = true
		if a == "--plates": plates = true
		if a.begins_with("--lights="): nlights = int(a.trim_prefix("--lights="))
		if a.begins_with("--only="): prefix = a.trim_prefix("--only=")
		if a.begins_with("--spots="): only = a.trim_prefix("--spots=")
		if a.begins_with("--night="): night = float(a.trim_prefix("--night="))
		if a.begins_with("--wind="): wind = float(a.trim_prefix("--wind="))
		if a.begins_with("--frames="): frames = int(a.trim_prefix("--frames="))
		if a.begins_with("--hold="): hold = int(a.trim_prefix("--hold="))
		if a.begins_with("--runtime="): rt = a.trim_prefix("--runtime=")
		if a.begins_with("--drive="): drive = a.trim_prefix("--drive=").split_floats(",")
		if a.begins_with("--cams="):
			for c in a.trim_prefix("--cams=").split(";", false):
				var p := c.split(":"); cams.append([p[0], _v(p[1]), _v(p[2])])
	DirAccess.make_dir_recursive_absolute(out)
	var env := Environment.new()
	var sky := Sky.new(); var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.32, 0.52, 0.82).lerp(Color(0.01, 0.015, 0.04), night); psm.sky_horizon_color = Color(0.72, 0.8, 0.88).lerp(Color(0.05, 0.06, 0.1), night)
	psm.ground_horizon_color = Color(0.6, 0.62, 0.6).lerp(Color(0.04, 0.04, 0.05), night); psm.ground_bottom_color = Color(0.3, 0.32, 0.3).lerp(Color(0.02, 0.02, 0.02), night)
	sky.sky_material = psm; env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.66, 0.72).lerp(Color(0.2, 0.24, 0.36), night); env.ambient_light_energy = lerpf(0.75, 0.22, night)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED; env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if night > 0.3: env.glow_enabled = true; env.glow_intensity = 0.6; env.glow_bloom = 0.1
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = lerpf(1.25, 0.04, night); sun.light_color = Color(1, 1, 1).lerp(Color(0.6, 0.7, 1.0), night)
	sun.shadow_enabled = OS.get_environment("NOSHADOW") != "1"; sun.directional_shadow_max_distance = 220.0; root.add_child(sun)
	RenderingServer.global_shader_parameter_set(&"ck_night", night)
	RenderingServer.global_shader_parameter_set(&"ck_wind_strength", wind)
	var gp := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(4000, 4000); gp.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.36, 0.42, 0.3); gm.roughness = 1.0; gp.material_override = gm; gp.position.y = -0.05; root.add_child(gp)
	var st: Node3D = Stream.new(); st.runtime_dir = rt; st.name = "City"; root.add_child(st)
	st.set_night(night)
	var cam := Camera3D.new(); cam.fov = 60.0; cam.far = 2000.0; root.add_child(cam); cam.current = true
	if "--nofar" in OS.get_cmdline_user_args() and st.far_world: st.far_world.visible = false
	var lights: Node3D = null
	if nlights > 0:
		lights = Lights.new(); lights.budget = nlights; lights.stream = st; root.add_child(lights)
	var plate_node: MeshInstance3D = null
	for c: Array in cams:
		cam.global_position = c[1]; cam.look_at(c[2])
		st.update_focus(c[1], true)
		var blds: Array = []
		for b: Node in st.find_children("*", "Node3D", true, false):
			if b.has_meta(&"kit") and (prefix == "" or String(b.name).begins_with(prefix)): blds.append(b)
		if tint:
			var pal := [Color(1, 1, 1), Color(1.0, 0.94, 0.84), Color(0.93, 0.97, 1.0), Color(1.0, 0.9, 0.86), Color(0.9, 0.96, 0.9), Color(0.98, 0.96, 0.78), Color(0.86, 0.9, 0.96), Color(1.0, 0.86, 0.74), Color(0.84, 0.86, 0.84)]
			for b2: Node3D in blds:
				var h := absi(hash(String(b2.name)))
				for mi: Node in b2.get_children():
					if mi is MeshInstance3D:
						(mi as MeshInstance3D).set_instance_shader_parameter(&"tint", pal[h % pal.size()]); (mi as MeshInstance3D).set_instance_shader_parameter(&"wear_add", float((h / 97) % 100) / 100.0 * 0.3 - 0.12)
		if plates:
			if plate_node: plate_node.queue_free()
			plate_node = await Plates.build(self, blds)
			if plate_node: root.add_child(plate_node); print("SHOTS plates=%d on %d buildings" % [int(plate_node.get_meta(&"plates")), blds.size()])
		if lights: lights.update_lights(c[1], night)
		for i in hold: await process_frame
		for fi in frames:
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png(out.path_join("%s%s.png" % [c[0], "" if frames == 1 else "_%03d" % fi]))
			if fi < frames - 1: await process_frame
		print("SHOT %s draws=%d prims=%d cells=%d" % [c[0], RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), st.loaded_count()])
	if probe:
		cam.fov = 70.0; cam.far = 2600.0; gp.visible = false; sun.shadow_enabled = false; env.background_mode = Environment.BG_COLOR
		var res: Array = []
		for s: Array in SPOTS:
			if only != "" and not (String(s[0]) in only.split(",")): continue
			var eye := Vector3(float(s[1]), float(s[2]) + 1.7, float(s[3]))
			st.update_focus(eye, true)
			for i in 4: await process_frame
			for d: Array in [["n", Vector3(0, 0, -1)], ["e", Vector3(1, 0, 0)], ["s", Vector3(0, 0, 1)], ["w", Vector3(-1, 0, 0)]]:
				cam.global_position = eye; cam.look_at(eye + (d[1] as Vector3) * 50.0 + Vector3(0, -0.5, 0))
				var b: Array = await _info()
				st.far_world.visible = false
				var nf: Array = await _info()
				st.far_world.visible = true
				var groups := {}
				if detail:      # what each kind of node costs in this view (hidden in turn)
					var by := {}
					for g: GeometryInstance3D in st.find_children("*", "GeometryInstance3D", true, false):
						if st.far_world.is_ancestor_of(g) or String(g.name).begins_with("glow_"): continue      # (night glow: hidden by day)
						var nm := String(g.name); var par := String(g.get_parent().name); var kind := "misc"
						if par == "Ground": kind = "ground"
						elif nm == "wear": kind = "wear"
						elif g.get_parent().has_meta(&"kit"): kind = "bldg_" + nm
						elif par == "Props": kind = ("merged_" if nm.begins_with("m") else "inst_") + ("mid" if nm.ends_with("_mid") else "near")
						if not by.has(kind): by[kind] = []
						by[kind].append(g)
					for kind: String in by:
						for g: GeometryInstance3D in by[kind]: g.visible = false
						var h: Array = await _info()
						for g: GeometryInstance3D in by[kind]: g.visible = true
						groups[kind] = [b[0] - h[0], b[1] - h[1]]
				res.append({"spot": s[0], "dir": d[0], "draws": b[0], "tris": b[1], "far_draws": b[0] - nf[0], "far_tris": b[1] - nf[1], "cells": st.loaded_count(), "groups": groups})
				print("PROBE %s %s draws=%d tris=%d (far world %d / %d) cells=%d" % [s[0], d[0], b[0], b[1], b[0] - nf[0], b[1] - nf[1], st.loaded_count()])
		var R := RenderingServer
		var f := FileAccess.open(out.path_join("probe_rt.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify({"views": res, "video_mb": R.get_rendering_info(R.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0, "tex_mb": R.get_rendering_info(R.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0, "buf_mb": R.get_rendering_info(R.RENDERING_INFO_BUFFER_MEM_USED) / 1048576.0})); f.close()
	if drive.size() >= 5:
		var a0 := Vector3(drive[0], 0, drive[1]); var a1 := Vector3(drive[2], 0, drive[3]); var sp := drive[4]
		cam.fov = 70.0; var dist := a0.distance_to(a1); var t := 0.0; var worst := 0.0; var nframes := 0
		st.update_focus(a0, true)
		for i in 5: await process_frame
		var t_prev := Time.get_ticks_usec(); var late := 0
		while t * sp < dist:
			var p := a0.lerp(a1, t * sp / dist)
			cam.global_position = p + Vector3(0, 7.7, 0); cam.look_at(cam.global_position + (a1 - a0).normalized() * 50.0)
			st.update_focus(p)
			await process_frame
			var now := Time.get_ticks_usec(); t += (now - t_prev) / 1000000.0; t_prev = now; nframes += 1
			# a cell is late when the focus is inside its 200 m rectangle + 60 m (the near tier's reach) before it is in
			for k: String in st.cells:
				if st.cells[k].state != 3 and st._dist(k, p) < 60.0: late += 1
		for ms: float in st.add_ms: worst = maxf(worst, ms)
		while st.busy(): await process_frame
		print("DRIVE %.0f m at %.0f m/s: %d cells added, main-thread add ms worst %.2f mean %.2f, frames with a late cell %d of %d" % [dist, sp, st.add_ms.size(), worst, (st.add_ms.reduce(func(x: float, y: float) -> float: return x + y, 0.0) / maxf(1.0, st.add_ms.size())), late, nframes])
	quit()
