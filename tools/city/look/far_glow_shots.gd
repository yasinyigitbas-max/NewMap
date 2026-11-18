extends SceneTree
## Look job 5 pictures: the FAR WORLD alone (runtime/far/far_world.scn, as it shows beyond the loaded cells) at night,
## with the far shader as it is and with the proposed night windows (tools/city/look/far_glow_patch.gdshaderinc + the
## atlas with its window mask, runtime_tex/far_color_glow.png), swapped in memory only.
##   xvfb-run -a godot --path . --resolution 1640x720 --rendering-method mobile --rendering-driver vulkan -s res://tools/city/look/far_glow_shots.gd -- --out=DIR
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var out := "user://far_glow"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var env := Environment.new(); var sky := Sky.new(); var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.01, 0.015, 0.04); psm.sky_horizon_color = Color(0.05, 0.06, 0.1)
	psm.ground_horizon_color = Color(0.04, 0.04, 0.05); psm.ground_bottom_color = Color(0.02, 0.02, 0.02)
	sky.sky_material = psm; env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.2, 0.24, 0.36); env.ambient_light_energy = 0.22
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED; env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true; env.glow_intensity = 0.6; env.glow_bloom = 0.1
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = 0.04; sun.light_color = Color(0.6, 0.7, 1.0); root.add_child(sun)
	RenderingServer.global_shader_parameter_set(&"ck_night", 1.0)
	var fm: ShaderMaterial = load("res://map_dc/coronado/city_kit/runtime/lib/mat_far_solid.tres")
	var old_sh: Shader = fm.shader; var old_tex: Texture2D = fm.get_shader_parameter(&"albedo_tex")
	var new_sh := Shader.new(); new_sh.code = "shader_type spatial;\nrender_mode cull_back;\n" + FileAccess.get_file_as_string("res://tools/city/look/far_glow_patch.gdshaderinc")
	var glow_tex: Texture2D = load("res://map_dc/coronado/city_kit/runtime_tex/far_color_glow.png")
	var far: Node3D = (load("res://map_dc/coronado/city_kit/runtime/far/far_world.scn") as PackedScene).instantiate(); root.add_child(far)
	var cam := Camera3D.new(); cam.fov = 50.0; cam.far = 4000.0; root.add_child(cam); cam.current = true
	for v: Array in [["centre", Vector3(150, 35, -300), Vector3(0, 20, -620)], ["apartments", Vector3(420, 30, -420), Vector3(250, 12, -620)], ["skyline", Vector3(300, 60, 300), Vector3(0, 15, -700)]]:
		cam.global_position = v[1]; cam.look_at(v[2])
		for k: Array in [["before", old_sh, old_tex], ["after", new_sh, glow_tex]]:
			fm.shader = k[1]; fm.set_shader_parameter(&"albedo_tex", k[2])
			for i in 30: await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_jpg(out.path_join("%s_night_%s.jpg" % [v[0], k[0]]), 0.9)
			print("FG %s %s" % [v[0], k[0]])
	quit()
