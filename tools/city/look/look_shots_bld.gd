extends SceneTree
const Stream := preload("res://tools/city/bake/city_stream.gd")
const Lights := preload("res://tools/city/bake/city_lights.gd")
## Before / after pictures of the building look pack (docs/LOOK_BUILDINGS.md) in the BAKED city, same sun, sky and
## ambient light as the phone rig (tools/city/rig/rig.gd). The three changes are global shader values, so one run
## takes every picture: nothing is rebuilt, nothing baked changes.
##   xvfb-run -a godot --path . --resolution 1640x720 --rendering-method mobile --rendering-driver vulkan \
##       -s res://tools/city/look/look_shots_bld.gd -- --out=res://map_dc/coronado/city_kit/review/look_18nov/buildings
##   --cams=name:x,y,z:tx,ty,tz;...   own cameras instead of the built-in street views
##   --only=centre,apartments         built-in views whose name starts with one of these
##   --times=day,night                (default both)
##   --sets=before,after              which pictures per camera and time. A set is "before" (all three off), "after"
##                                    (all on) or one change alone: "contact", "windows", "glass"
##   --ao    also "ao_off" / "ao_on": the kit's own occlusion (ORM red) switched off in memory, to show how much the
##           kit already does (look changes off in both)
##   --png   lossless files instead of JPG        --hold=frames before each picture (default 30)
## Cloud note: the software GPU draws no shadows (NOSHADOW=1) and the weathered buildings about 40 % too dark. Use the
## system Mesa driver (apt mesa-vulkan-drivers, VK_ICD_FILENAMES unset): /opt/lavapipe draws the tree leaves black.
const LOOKS := [&"ck_look_contact", &"ck_look_windows", &"ck_look_glass"]
## street level (eye 1.7 m above the road) at the three places Yasin named: city centre, apartments, pilot high street
const VIEWS := [
	["centre_a", Vector3(-6, 7.7, -592), Vector3(40, 16, -640)],
	["centre_b", Vector3(5, 7.7, -612), Vector3(-30, 13, -560)],
	["apartments_a", Vector3(244, 7.7, -594), Vector3(290, 13, -630)],
	["apartments_b", Vector3(256, 7.7, -608), Vector3(215, 12, -570)],
	["pilot_a", Vector3(-5, 5.7, 8), Vector3(20, 8, -40)],
	["pilot_b", Vector3(4, 5.7, -30), Vector3(-12, 7, 20)]]
func _init() -> void: _run.call_deferred()
func _v(s: String) -> Vector3:
	var f := s.split_floats(","); return Vector3(f[0], f[1], f[2])
func _run() -> void:
	var out := "res://map_dc/coronado/city_kit/review/look_18nov/buildings"; var cams: Array = []; var only := PackedStringArray(); var times := PackedStringArray(["day", "night"])
	var sets := PackedStringArray(["before", "after"]); var ao := false; var png := false; var hold := 30
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--only="): only = a.trim_prefix("--only=").split(",", false)
		if a.begins_with("--times="): times = a.trim_prefix("--times=").split(",", false)
		if a.begins_with("--sets="): sets = a.trim_prefix("--sets=").split(",", false)
		if a.begins_with("--hold="): hold = int(a.trim_prefix("--hold="))
		if a == "--ao": ao = true
		if a == "--png": png = true
		if a.begins_with("--cams="):
			for c in a.trim_prefix("--cams=").split(";", false):
				var p := c.split(":"); cams.append([p[0], _v(p[1]), _v(p[2])])
	if cams.is_empty():
		for v: Array in VIEWS:
			var keep := only.is_empty()
			for o in only:
				if String(v[0]).begins_with(o): keep = true
			if keep: cams.append(v)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var R := RenderingServer
	# the rig's world (rig.gd _ready and _night)
	var env := Environment.new(); var sky := Sky.new(); var psm := ProceduralSkyMaterial.new(); sky.sky_material = psm
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.62, 0.66, 0.72)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# cloud only: with sky reflections on, the software GPU draws the cut-out leaves black (rt_shots.gd turns them off
	# too). The rig keeps them on; none of the look changes uses them (the glass has its own sky gradient).
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.shadow_enabled = OS.get_environment("NOSHADOW") != "1"; sun.directional_shadow_max_distance = 50.0; root.add_child(sun)
	var gp := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(6000, 6000); gp.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.36, 0.42, 0.3); gm.roughness = 1.0; gp.material_override = gm; gp.position.y = -0.05; root.add_child(gp)
	var st: Node3D = Stream.new(); st.name = "City"; root.add_child(st)
	var lights: Node3D = Lights.new(); lights.budget = 8; lights.stream = st; root.add_child(lights)
	var cam := Camera3D.new(); cam.fov = 74.0; cam.near = 0.08; cam.far = 900.0; root.add_child(cam); cam.current = true
	root.get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	var shader: Shader = load("res://map_dc/coronado/city_kit/shaders/rt/rt_bldg.gdshader"); var code := shader.code
	var all_sets: Array = Array(sets)
	if ao: all_sets.append_array(["ao_on", "ao_off"])
	for c: Array in cams:
		cam.global_position = c[1]; cam.look_at(c[2])
		st.update_focus(c[1], true)
		for i in 10: await process_frame
		while st.busy(): await process_frame
		for tm in times:
			var night := 1.0 if tm == "night" else 0.0
			st.set_night(night); sun.light_energy = lerpf(1.25, 0.04, night); env.ambient_light_energy = lerpf(0.75, 0.22, night)
			psm.sky_top_color = Color(0.32, 0.52, 0.82).lerp(Color(0.01, 0.015, 0.04), night); psm.sky_horizon_color = Color(0.72, 0.8, 0.88).lerp(Color(0.05, 0.06, 0.1), night)
			lights.update_lights(c[1], night)
			for s: String in all_sets:
				for g: StringName in LOOKS:
					R.global_shader_parameter_set(g, 1.0 if (s == "after" or s == String(g).trim_prefix("ck_look_")) else 0.0)
				if s == "ao_off": shader.code = code.replace("AO = orm.r;", "AO = 1.0;")
				for i in hold: await process_frame
				await R.frame_post_draw
				var img := root.get_viewport().get_texture().get_image()
				var path := out.path_join("%s_%s_%s.%s" % [c[0], tm, s, "png" if png else "jpg"])
				if png: img.save_png(path)
				else: img.save_jpg(path, 0.92)
				if s == "ao_off": shader.code = code
				print("LOOK %s %dx%d draws=%d" % [path.get_file(), img.get_width(), img.get_height(), R.get_rendering_info(R.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	print("LOOK_DONE")
	quit()
