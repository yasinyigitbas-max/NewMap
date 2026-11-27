extends SceneTree
## Shows takes of the library on his body: six moments of each, from the front-right, in one picture a take.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var out := "."; var clips := PackedStringArray()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--clips="): clips = arg.trim_prefix("--clips=").split(",")
	var world := Node3D.new(); root.add_child(world)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.6, 0.68); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 0.7; world.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); world.add_child(sun)
	var floor_m := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(30, 30); floor_m.mesh = pm; world.add_child(floor_m)
	var lib: AnimationLibrary = load("res://traversal/character/library.res")
	var men: Array = []
	for i in 6:
		var m: Node3D = (load("res://traversal/character/player_v4_rooted.scn") as PackedScene).instantiate()
		world.add_child(m); m.position = Vector3(i * 1.3 - 3.25, 0, 0)
		var ap := AnimationPlayer.new(); m.add_child(ap); ap.add_animation_library("", lib)
		men.append([m, ap])
	var cam := Camera3D.new(); world.add_child(cam); cam.fov = 30.0
	cam.position = Vector3(2.5, 1.3, 13.5); cam.look_at(Vector3(0, 0.95, 0)); cam.make_current()
	root.size = Vector2i(1800, 560)
	for c in clips:
		var a := lib.get_animation(c)
		for i in 6:
			var ap: AnimationPlayer = men[i][1]
			ap.play(c); ap.seek(a.length * (i + 0.5) / 6.0, true); ap.pause()
			(men[i][0] as Node3D).rotation.y = 0.6
		for k in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, c])
	quit()
