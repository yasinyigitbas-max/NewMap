extends SceneTree
## Which side of a kit prop is its +Z side? Each prop alone at yaw 0, rendered from +Z, +X, -Z, -X (one row per prop).
## godot --path . --rendering-method mobile --resolution 480x480 -s <this> -- --props=washer,office_desk --out=C:/tmp/facing.png
const R := preload("res://map_dc/coronado/city_kit/interiors/rooms/room_lib.gd")
const K := preload("res://tools/city/pilot/kit_lib.gd")
func _init() -> void: _run.call_deferred()
func _run() -> void:
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.55, 0.6, 0.65)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(1, 1, 1); env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 20, 0); root.add_child(sun)
	var cam := Camera3D.new(); root.add_child(cam)
	var bases := PackedStringArray(["cash_register", "office_desk", "washer"])
	var out := "user://prop_facing.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--props="): bases = a.trim_prefix("--props=").split(",")
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	var cell := 240; var cols := 4; var rows := bases.size()
	var sheet := Image.create(cell * cols, cell * rows, false, Image.FORMAT_RGB8)
	var holder := Node3D.new(); root.add_child(holder)
	for i in bases.size():
		var base := "prop_" + bases[i]
		var f := R.indoor_file(base)
		if f == "": f = K.prop_file(base, "normal", "near")
		if f == "": f = K.prop_file(base, "clean", "near")
		if f == "": print("no file ", base); continue
		for c in holder.get_children(): c.free()
		var inst: Node3D = (load(f) as PackedScene).instantiate(); holder.add_child(inst)
		var ab := AABB(); var first := true
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			var b := mi.global_transform * mi.get_aabb()
			ab = b if first else ab.merge(b); first = false
		var ctr := ab.get_center(); var r := maxf(ab.size.length() * 0.5, 0.3)
		for vi in 4:
			var d: Vector3 = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)][vi]
			cam.global_position = ctr + Vector3(0.0, r * 0.6, 0) + d * r * 2.4; cam.look_at(ctr)
			for k in 6: await process_frame
			await RenderingServer.frame_post_draw
			var im := root.get_viewport().get_texture().get_image(); im.convert(Image.FORMAT_RGB8)
			var s := mini(im.get_width(), im.get_height()); im = im.get_region(Rect2i((im.get_width() - s) / 2, 0, s, s)); im.resize(cell, cell)
			sheet.blit_rect(im, Rect2i(0, 0, cell, cell), Vector2i(vi * cell, i * cell))
		print(i, " ", bases[i])
	sheet.save_png(out)
	quit()
