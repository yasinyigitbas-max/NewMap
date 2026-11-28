extends SceneTree
## CITY LIGHT, part 1 of 2 (look uplift, 28 Nov; Yasin: "we need a break thru at graphics"). Runs AFTER the runtime bake.
## Draws the baked far world (every building, the far ground) from straight above and writes the highest surface over
## every 2 m of the island: runtime/far/city_height.exr (one float a texel, metres) + city_height.json (where it lies).
## make_city_light.py (part 2) turns it into the sky-occlusion map the city's shaders read (ck_city_ao) and the height
## map they march for the far sun shadows (ck_city_h). Measures and writes; it places and decides nothing.
##   godot --path . --rendering-method mobile -s res://tools/city/look/city_light_bake.gd [-- --texel=2.0]
const RT := "res://map_dc/coronado/city_kit/runtime/"
const HSCALE := 1.0 / 128.0      # metres -> colour (the target is float: no clipping; 128 m reads 1.0)

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var texel := 2.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--texel="): texel = float(a.trim_prefix("--texel="))
		if a == "--pack": _pack(); return
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RT + "manifest.json"))
	var cm := float(man.get("cell_m", 200.0))
	var lo := Vector2i(1 << 20, 1 << 20); var hi := -lo
	for k: String in (man.cells as Dictionary).keys():
		var p := k.split("_"); var c := Vector2i(int(p[0]), int(p[1]))
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y)); hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	# one cell of margin all round: the far ground and the skyline reach past the baked cells
	lo -= Vector2i(1, 1); hi += Vector2i(1, 1)
	var x0 := lo.x * cm; var z0 := lo.y * cm; var wx := (hi.x - lo.x + 1) * cm; var wz := (hi.y - lo.y + 1) * cm
	var pw := int(round(wx / texel)); var ph := int(round(wz / texel))
	print("CITYLIGHT area x %.0f..%.0f z %.0f..%.0f, %d x %d texels of %.2f m" % [x0, x0 + wx, z0, z0 + wz, pw, ph, texel])
	var vp := SubViewport.new(); vp.size = Vector2i(pw, ph); vp.own_world_3d = true; vp.use_hdr_2d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; vp.msaa_3d = Viewport.MSAA_DISABLED; vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	root.add_child(vp)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0, 0, 0)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR; env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	var we := WorldEnvironment.new(); we.environment = env; vp.add_child(we)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.keep_aspect = Camera3D.KEEP_HEIGHT; cam.size = wz
	cam.position = Vector3(x0 + wx * 0.5, 900.0, z0 + wz * 0.5); cam.rotation_degrees = Vector3(-90, 0, 0); cam.near = 1.0; cam.far = 1200.0
	vp.add_child(cam); cam.current = true
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled, depth_draw_always;\nvarying float wy;\nvoid vertex() { wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y; }\nvoid fragment() { ALBEDO = vec3(max(wy, 0.0) * %f); }\n" % HSCALE
	var mat := ShaderMaterial.new(); mat.shader = sh
	var far: Node = (load(RT + "far/far_world.scn") as PackedScene).instantiate()
	vp.add_child(far)
	var n := [0]
	_strip(far, mat, n)
	print("CITYLIGHT far world: %d drawn things" % n[0])
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty(): print("CITYLIGHT ERROR the top-down render gave no picture"); quit(1); return
	img.convert(Image.FORMAT_RF)
	var mx := 0.0; var sum := 0.0
	for y in range(0, ph, 8):
		for x in range(0, pw, 8):
			var v := img.get_pixel(x, y).r / HSCALE; mx = maxf(mx, v); sum += v
	# scale the colour back to metres
	var data := img.get_data().to_float32_array()
	for i in data.size(): data[i] = data[i] / HSCALE
	var out := Image.create_from_data(pw, ph, false, Image.FORMAT_RF, data.to_byte_array())
	out.save_exr(ProjectSettings.globalize_path(RT + "far/city_height.exr"), true)
	var fb := FileAccess.open(RT + "far/city_height.f32", FileAccess.WRITE); fb.store_buffer(data.to_byte_array()); fb.close()      # the same, raw, for make_city_light.py
	var pv := Image.create(pw, ph, false, Image.FORMAT_L8)      # a look at it (not used by the game): 0..64 m as black..white
	for y in ph:
		for x in pw: pv.set_pixel(x, y, Color(1, 1, 1) * clampf(data[y * pw + x] / 64.0, 0.0, 1.0))
	pv.save_png(ProjectSettings.globalize_path(RT + "far/city_height_small.png"))
	var meta := {"x0": x0, "z0": z0, "wx": wx, "wz": wz, "texel": texel, "w": pw, "h": ph}
	var f := FileAccess.open(RT + "far/city_height.json", FileAccess.WRITE); f.store_string(JSON.stringify(meta)); f.close()
	print("CITYLIGHT wrote far/city_height.exr: highest %.1f m, mean %.2f m (a sample of 1 in 64)" % [mx, sum / float((pw / 8 + 1) * (ph / 8 + 1))])
	quit(0)

## Part 3 (--pack, after make_city_light.py): the two maps as textures the game loads (look.gd, ck_city_*):
## far/city_ao.res (RGBA8 + mipmaps: the sky seen at four heights) and far/city_hg.res (two half floats: surface, ground).
func _pack() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RT + "far/city_height.json"))
	var w := int(meta.w); var h := int(meta.h)
	var ao := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, FileAccess.get_file_as_bytes(RT + "far/city_ao.u8"))
	ao.generate_mipmaps()
	ResourceSaver.save(ImageTexture.create_from_image(ao), RT + "far/city_ao.res", ResourceSaver.FLAG_COMPRESS)
	var hg := Image.create_from_data(w, h, false, Image.FORMAT_RGF, FileAccess.get_file_as_bytes(RT + "far/city_hg.f32"))
	hg.convert(Image.FORMAT_RGH)
	ResourceSaver.save(ImageTexture.create_from_image(hg), RT + "far/city_hg.res", ResourceSaver.FLAG_COMPRESS)
	var f := FileAccess.open(RT + "far/city_light.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"rect": [float(meta.x0), float(meta.z0), 1.0 / float(meta.wx), 1.0 / float(meta.wz)]})); f.close()
	print("CITYLIGHT packed far/city_ao.res and far/city_hg.res (%d x %d)" % [w, h])
	quit(0)

## every drawn thing: drawn with the height shader, never culled by distance, no shadows
func _strip(nd: Node, mat: Material, n: Array) -> void:
	if nd is GeometryInstance3D:
		var g := nd as GeometryInstance3D
		g.material_override = mat; g.visibility_range_begin = 0.0; g.visibility_range_end = 0.0; g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.extra_cull_margin = 16384.0; n[0] += 1
	for c in nd.get_children(): _strip(c, mat, n)
