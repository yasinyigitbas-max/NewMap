extends SceneTree
## LOD match (20 Nov): the baked city (city_kit/runtime, every cell of it in the scene, no streamer) photographed just
## inside and just outside each tier switch of one building, at the phone's resolution (2460 x 1080 at 3D scale 0.5).
##   xvfb-run -a godot --path . --rendering-method mobile -s res://tools/city/lod/lod_shots.gd -- --out=DIR [--runtime=res://...]
##        [--night=0..1] --list                      the buildings of the baked cells: kit, name, pivot
##        "--shots=name:kit:az:el[:nth];..."         per shot four pictures from two cameras: 59 m near / mid, 219 m mid / far
##        (az: degrees round +y from +z, el: degrees up; the camera looks at the building's tier pivot)
const CELL := 200.0
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var out := "user://lod_shots"; var rt := "res://map_dc/coronado/city_kit/runtime/"; var night := 0.0; var shots: Array = []; var list := false; var nofg := false; var sets: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--runtime="): rt = a.trim_prefix("--runtime=")
		if a.begins_with("--night="): night = float(a.trim_prefix("--night="))
		if a == "--list": list = true
		if a.begins_with("--glass="): RenderingServer.global_shader_parameter_set(&"ck_look_glass", float(a.trim_prefix("--glass=")))
		if a == "--nofg": nofg = true
		if a.begins_with("--set="): sets.append(a.trim_prefix("--set=").split("="))      # --set=uniform=value on the LOD-page materials (a trial)
		if a.begins_with("--shots="):
			for s in a.trim_prefix("--shots=").split(";", false): shots.append(s.split(":"))
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1230, 540)
	var env := Environment.new(); var sky := Sky.new(); var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.32, 0.52, 0.82).lerp(Color(0.01, 0.015, 0.04), night); psm.sky_horizon_color = Color(0.72, 0.8, 0.88).lerp(Color(0.05, 0.06, 0.1), night)
	psm.ground_horizon_color = Color(0.6, 0.62, 0.6).lerp(Color(0.04, 0.04, 0.05), night); psm.ground_bottom_color = Color(0.3, 0.32, 0.3).lerp(Color(0.02, 0.02, 0.02), night)
	sky.sky_material = psm; env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.66, 0.72).lerp(Color(0.2, 0.24, 0.36), night); env.ambient_light_energy = lerpf(0.75, 0.22, night)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED; env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if night > 0.3: env.glow_enabled = true; env.glow_intensity = 0.6; env.glow_bloom = 0.1
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = lerpf(1.25, 0.04, night)
	sun.shadow_enabled = true; sun.directional_shadow_max_distance = 220.0; root.add_child(sun)
	RenderingServer.global_shader_parameter_set(&"ck_night", night)
	var gp := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(4000, 4000); gp.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.36, 0.42, 0.3); gm.roughness = 1.0; gp.material_override = gm; gp.position.y = -0.05; root.add_child(gp)
	for f in DirAccess.get_files_at(rt + "lib"):
		if f.begins_with("mat_bldg_bld_lod") or f == "mat_far_lod.tres":
			var m: ShaderMaterial = load(rt + "lib/" + f)
			for kv: Array in sets: m.set_shader_parameter(StringName(kv[0]), str_to_var(kv[1]))
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(rt + "manifest.json"))
	var fw: Node = (load(rt + "far/far_world.scn") as PackedScene).instantiate(); root.add_child(fw)
	if nofg:      # --nofg: no far ground (its top-down picture is ETC2, which the PC's compatibility renderer shows as noise)
		for g: Node in fw.find_children("far_ground*", "", true, false): (g as Node3D).visible = false
	# where each building is: one pass over the cells (each freed again: all of them at once is more instance
	# uniforms than the renderer holds), then per shot only the building's own cell (more cells are more instance uniforms than
	# the PC's compatibility renderer holds); outside it the far world shows, as in the game for a cell not in yet
	var where := {}
	for key: String in (man.cells as Dictionary):
		var f := rt + "cells/cell_%s.scn" % key
		if not ResourceLoader.exists(f): continue
		var cn: Node = (load(f) as PackedScene).instantiate()
		for b: Node in cn.find_children("*", "Node3D", true, false):
			if b.has_meta(&"kit"):
				var kk := String(b.get_meta(&"kit"))
				if not where.has(kk): where[kk] = []
				where[kk].append([key, String(b.name), _pivot(b as Node3D)])
				if list: print("BLD %s %s %s %s" % [kk, b.name, key, _pivot(b as Node3D)])
		cn.free()
	var cam := Camera3D.new(); cam.fov = 70.0; cam.far = 2000.0; root.add_child(cam); cam.current = true
	for s: Array in shots:
		var nth := int(s[4]) if s.size() > 4 else 0
		if not where.has(String(s[1])) or (where[String(s[1])] as Array).size() <= nth: print("SHOT %s: no %s" % [s[0], s[1]]); continue
		var w: Array = where[String(s[1])][nth]
		var kc := String(w[0]).split("_"); var cx := int(kc[0]); var cz := int(kc[1])
		var img := Image.create_empty(64, 64, false, Image.FORMAT_R8); img.fill(Color(0, 0, 0))
		var held: Array = []
		for dz in [0]:
			for dx in [0]:
				var key := "%d_%d" % [cx + dx, cz + dz]
				if not (man.cells as Dictionary).has(key): continue
				var cn: Node = (load(rt + "cells/cell_%s.scn" % key) as PackedScene).instantiate(); root.add_child(cn); held.append(cn)
				img.set_pixel(cx + dx + 32, cz + dz + 32, Color(1, 0, 0))
		RenderingServer.global_shader_parameter_set(&"ck_cells_loaded", ImageTexture.create_from_image(img))
		var pv: Vector3 = w[2]; var az := deg_to_rad(float(s[2])); var el := deg_to_rad(float(s[3]))
		var dir := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
		# the same camera, the two tiers in turn: 59 m near | mid (near's window off, mid's on), 219 m mid | far (the
		# cell taken out: then the far world draws, as it does for a cell not in). Saved as <shot>_59n / 59m / 219m / 219f.
		var tiers := {}
		for cn: Node in held:
			for mi: Node in cn.find_children("*", "MeshInstance3D", true, false):
				if mi.get_parent().has_meta(&"kit") and String(mi.name) in ["near", "mid"]:
					if not tiers.has(String(mi.name)): tiers[String(mi.name)] = []
					tiers[String(mi.name)].append(mi)
		for v: Array in [[59.0, "n"], [59.0, "m"], [219.0, "m"], [219.0, "f"]]:
			cam.global_position = pv + dir * float(v[0]); cam.look_at(pv)
			if v[1] == "m" and float(v[0]) < 100.0: _force(tiers, "mid")
			elif v[1] == "f":
				for cn: Node in held: (cn as Node3D).visible = false
				RenderingServer.global_shader_parameter_set(&"ck_cells_loaded", ImageTexture.create_from_image(Image.create_empty(64, 64, false, Image.FORMAT_R8)))
			for i in 12: await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png(out.path_join("%s_%d%s.png" % [s[0], int(v[0]), v[1]]))
			if v[1] == "m" and float(v[0]) < 100.0: _force(tiers, "")
		print("SHOT %s %s %s pivot %s" % [s[0], s[1], w[1], pv])
		for cn: Node in held: cn.free()
		await process_frame
	quit()

## "mid": every mid drawn at any distance and no near (for one picture); "": the baked windows back
func _force(tiers: Dictionary, which: String) -> void:
	for t: String in tiers:
		for mi: MeshInstance3D in tiers[t]:
			if which == "":
				mi.set_instance_shader_parameter(&"ck_win", mi.get_meta(&"win")); mi.visibility_range_begin = mi.get_meta(&"vb"); mi.visibility_range_end = mi.get_meta(&"ve")
				continue
			if not mi.has_meta(&"win"): mi.set_meta(&"win", mi.get_instance_shader_parameter(&"ck_win")); mi.set_meta(&"vb", mi.visibility_range_begin); mi.set_meta(&"ve", mi.visibility_range_end)
			var on := t == which
			mi.set_instance_shader_parameter(&"ck_win", Vector2(0.0, 1.0e6) if on else Vector2(0.0, 0.0))
			mi.visibility_range_begin = 0.0; mi.visibility_range_end = 0.0 if on else 0.001

func _pivot(b: Node3D) -> Vector3:
	for mi: Node in b.get_children():
		if mi is MeshInstance3D: return (mi as MeshInstance3D).get_instance_shader_parameter(&"ck_pivot")
	return b.global_position

