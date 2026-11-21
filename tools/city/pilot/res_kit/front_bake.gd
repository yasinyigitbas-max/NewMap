extends SceneTree
## Orthographic, unshaded (albedo x vertex colour) render of a city-kit building's FRONT (+Z) from its near tier, for
## the LOD-match front chart (same idea as tools/city/lod/lod_bake.py: the mid / far texels come from the near).
## args: --kit=<name> --out=png --ppm=16 --y0=0 --y1=10.44 --x0=-6 --x1=6
func _init() -> void: _run.call_deferred()
func _a(n: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + n + "="): return a.trim_prefix("--" + n + "=")
	return d
func _run() -> void:
	var kit := _a("kit", ""); var ppm := float(_a("ppm", "16"))
	var x0 := float(_a("x0", "-6")); var x1 := float(_a("x1", "6")); var y0 := float(_a("y0", "0")); var y1 := float(_a("y1", "10.44"))
	var vp := SubViewport.new(); vp.size = Vector2i(int(round((x1 - x0) * ppm)), int(round((y1 - y0) * ppm)))
	vp.debug_draw = Viewport.DEBUG_DRAW_UNSHADED; vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.5, 0.5, 0.5); env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new(); we.environment = env; vp.add_child(we)
	var ps: PackedScene = load("res://map_dc/coronado/city_kit/buildings/%s/%s_near.scn" % [kit, kit]); vp.add_child(ps.instantiate())
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = y1 - y0; cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 0.05; cam.far = 60.0; cam.position = Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, 30.0); vp.add_child(cam); cam.current = true
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(_a("out", "/tmp/fb.png")); print("FRONT_BAKE ", kit, " ", vp.size)
	quit()
