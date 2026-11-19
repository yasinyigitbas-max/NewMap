extends SceneTree
## Bird's-eye plan of the BAKED city (19 Nov, Yasin: "show me a birdseye view of the entire city"). A straight-down
## orthographic camera goes over the bake cell by cell (200 m tiles), each tile with its own cell and the eight round it
## loaded, and the tiles are joined into one picture. North is up, east is right. Changes nothing.
##   godot --path . --rendering-method mobile --resolution 320x180 -s res://tools/city/bake/rt_top.gd -- --out=OUT/top/city
##   options: --runtime=res://...   --px=400 (pixels a tile; drawn at twice that and scaled down)   --h=165 (camera height)
##            --close=x,z,size,height   ONE picture of size metres round a place instead (height under 60 = near tier)
## The camera is 165 m up, so the city is drawn in its MID tier (60-220 m): the shaders pick a tier by distance, and
## the far world is not loaded. Where no piece has ground the preview terrain shows (terrain_grid.json in the project
## root, from tools/city/run/terrain.sh), or a flat green plane if it is not there. No shadows (the mid tier casts none).
const TILE := 200.0

func _init() -> void: _run.call_deferred()

func _terrain(world: Node3D, tj: String) -> void:
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(tj))
	var nx := int(m.nx); var ny := int(m.ny); var st := float(m.step); var u0 := float(m.u0); var v0 := float(m.v0)
	var H := FileAccess.get_file_as_bytes(tj.get_basename() + ".f32").to_float32_array()
	var verts := PackedVector3Array(); var cols := PackedColorArray(); var nrm := PackedVector3Array()
	verts.resize(nx * ny); cols.resize(nx * ny); nrm.resize(nx * ny)
	for j in ny:
		for i in nx:
			var k := j * nx + i; var h := H[k]
			verts[k] = Vector3(u0 + i * st, h - 0.08, v0 + j * st)
			var hx := H[j * nx + mini(i + 1, nx - 1)] - H[j * nx + maxi(i - 1, 0)]
			var hz := H[mini(j + 1, ny - 1) * nx + i] - H[maxi(j - 1, 0) * nx + i]
			nrm[k] = Vector3(-hx, 2.0 * st, -hz).normalized()
			var n := sin(i * 0.37 + j * 0.11) * 0.5 + sin(i * 0.05 - j * 0.09) * 0.5
			var grass := Color(0.36, 0.42, 0.28).lerp(Color(0.45, 0.46, 0.30), 0.5 + 0.4 * n)
			var sand := Color(0.76, 0.70, 0.55)
			cols[k] = grass.lerp(sand, clampf((1.1 - h) / 0.6, 0.0, 1.0)) if h > -0.3 else Color(0.55, 0.52, 0.42)
	var idx := PackedInt32Array()
	for j in ny - 1:
		for i in nx - 1:
			var a := j * nx + i
			idx.append_array([a, a + 1, a + nx, a + 1, a + nx + 1, a + nx])
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts; arr[Mesh.ARRAY_COLOR] = cols; arr[Mesh.ARRAY_NORMAL] = nrm; arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new(); am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var sh := Shader.new()
	sh.code = "shader_type spatial; render_mode cull_disabled; void fragment(){ ALBEDO = pow(COLOR.rgb, vec3(2.2)); ROUGHNESS = 0.95; }"
	var mat := ShaderMaterial.new(); mat.shader = sh
	var mi := MeshInstance3D.new(); mi.mesh = am; mi.material_override = mat; world.add_child(mi)
	var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.07, 0.24, 0.27); wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED      # no sun glint a tile
	var sea := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(8000, 8000); sea.mesh = pm
	sea.material_override = wm; sea.position = Vector3(0, 0.0, 0); world.add_child(sea)

func _run() -> void:
	var rt := "res://map_dc/coronado/city_kit/runtime/"; var out := "res://OUT/top/city"; var px := 400; var h := 165.0
	var close := PackedFloat64Array()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--runtime="): rt = a.trim_prefix("--runtime=")
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--px="): px = int(a.trim_prefix("--px="))
		if a.begins_with("--h="): h = float(a.trim_prefix("--h="))
		if a.begins_with("--close="): close = a.trim_prefix("--close=").split_floats(",")
	if not out.begins_with("res://") and not out.begins_with("user://") and not out.is_absolute_path(): out = "res://" + out
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(rt + "manifest.json"))
	var have := {}
	var x0 := 999; var x1 := -999; var z0 := 999; var z1 := -999
	for ck: String in (man.cells as Dictionary):
		var cx := int(ck.get_slice("_", 0)); var cz := int(ck.get_slice("_", 1))
		have[Vector2i(cx, cz)] = true
		x0 = mini(x0, cx); x1 = maxi(x1, cx); z0 = mini(z0, cz); z1 = maxi(z1, cz)
	# light: a high sun, no haze, no shadows
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.07, 0.24, 0.27)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.66, 0.69, 0.74); env.ambient_light_energy = 0.8
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED; env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-62, -35, 0); sun.light_energy = 1.2; sun.shadow_enabled = false
	root.add_child(sun)
	RenderingServer.global_shader_parameter_set(&"ck_night", 0.0)
	var world := Node3D.new(); root.add_child(world)
	if FileAccess.file_exists("res://terrain_grid.json"): _terrain(world, "res://terrain_grid.json")
	else:
		var gp := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(8000, 8000); gp.mesh = pm
		var gmat := StandardMaterial3D.new(); gmat.albedo_color = Color(0.36, 0.42, 0.28); gp.material_override = gmat; gp.position.y = -0.3; world.add_child(gp)
	var rp := px * 2
	var sv := SubViewport.new(); sv.size = Vector2i(rp, rp); sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS; sv.msaa_3d = Viewport.MSAA_4X
	root.add_child(sv)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.near = 0.5; cam.far = 600.0; cam.rotation_degrees = Vector3(-90, 0, 0)
	sv.add_child(cam); cam.current = true
	var loaded := {}
	var t0 := Time.get_ticks_msec()
	if close.size() >= 4:
		var cc := Vector2i(floori(close[0] / TILE), floori(close[1] / TILE))
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var k := cc + Vector2i(dx, dz)
				if have.has(k):
					var n: Node3D = (load(rt + "cells/cell_%d_%d.scn" % [k.x, k.y]) as PackedScene).instantiate(); world.add_child(n)
		cam.size = close[2]; cam.position = Vector3(close[0], close[3], close[1])
		for i in 12: await process_frame
		await RenderingServer.frame_post_draw
		var ci := sv.get_texture().get_image(); ci.convert(Image.FORMAT_RGB8); ci.resize(px * 2, px * 2, Image.INTERPOLATE_LANCZOS)
		ci.save_png(out + ".png")
		print("TOP close %s at %s size %.0f m" % [out + ".png", str(close), close[2]])
		quit(); return
	var nxc := x1 - x0 + 1; var nzc := z1 - z0 + 1
	var big := Image.create(nxc * px, nzc * px, false, Image.FORMAT_RGB8); big.fill(Color(0.07, 0.24, 0.27))
	cam.size = TILE
	var done := 0
	for cz in range(z0, z1 + 1):
		for cx in range(x0, x1 + 1):
			var here := Vector2i(cx, cz)
			var any := false
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					if have.has(here + Vector2i(dx, dz)): any = true
			# cells no longer next to this tile go, the ones next to it come
			for lk: Vector2i in loaded.keys():
				if absi(lk.x - cx) > 1 or absi(lk.y - cz) > 1: (loaded[lk] as Node).queue_free(); loaded.erase(lk)
			if any:
				for dx in range(-1, 2):
					for dz in range(-1, 2):
						var k2 := here + Vector2i(dx, dz)
						if have.has(k2) and not loaded.has(k2):
							var n2: Node3D = (load(rt + "cells/cell_%d_%d.scn" % [k2.x, k2.y]) as PackedScene).instantiate(); world.add_child(n2); loaded[k2] = n2
			cam.position = Vector3((cx + 0.5) * TILE, h, (cz + 0.5) * TILE)
			for i in (6 if any else 2): await process_frame
			await RenderingServer.frame_post_draw
			var ti := sv.get_texture().get_image(); ti.convert(Image.FORMAT_RGB8); ti.resize(px, px, Image.INTERPOLATE_LANCZOS)
			big.blit_rect(ti, Rect2i(0, 0, px, px), Vector2i((cx - x0) * px, (cz - z0) * px))
			done += 1
		print("TOP row %d of %d (%d s)" % [cz - z0 + 1, nzc, (Time.get_ticks_msec() - t0) / 1000])
	big.save_jpg(out + "_full.jpg", 0.9)
	var sc := minf(1.0, 2400.0 / float(maxi(big.get_width(), big.get_height())))
	var small := big.duplicate() as Image
	if sc < 1.0: small.resize(int(big.get_width() * sc), int(big.get_height() * sc), Image.INTERPOLATE_LANCZOS)
	small.save_jpg(out + ".jpg", 0.9)
	print("TOP done %d tiles, cells x %d..%d z %d..%d, %dx%d px (%.1f px a metre), %s_full.jpg and %s.jpg, %d s" % [done, x0, x1, z0, z1, big.get_width(), big.get_height(), float(px) / TILE, out, out, (Time.get_ticks_msec() - t0) / 1000])
	quit()
