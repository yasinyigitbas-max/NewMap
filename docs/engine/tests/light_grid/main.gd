extends Node3D
# A night street: ONE big ground mesh and ONE long facade mesh (like the game's merged meshes), lit by a row of
# street lamps (omni) and a few spots (headlights, a doorway). No shadows.
# env LG_GRID (0 old per-mesh lists, 1 tile light grid, 2 = switched on while running, at frame 45),
# LG_CAM (0 down the street, 1 close to a wall looking up along it, 2 looking down at the ground, rolled), LG_OMNI (lamp count, default 24), LG_SPOT (default 4),
# LG_NAME (file name), LG_SPLIT (1 = ground cut in 5 m pieces instead of one mesh, to show what pairing can reach).
# LG_CULL: 0 lights reach every layer, 1 lights have a cull mask that still includes everything drawn,
# 2 the ground is on layer 2 and the lamps skip it (the game's rule for baked ground).
# Saves user://<LG_NAME>.png after 90 frames, prints the mean frame time of frames 40-90 and quits.
var frame := 0
var shot_frame := 90   # env LG_FRAMES: take the shot later (pipelines still compiling show the ubershader)
var t_sum := 0.0
var t_n := 0
var late_on := false

func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return d if v == "" else v

func _box(pos: Vector3, size: Vector3, col: Color, layer := 1) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.8
	mi.material_override = m
	mi.position = pos
	mi.layers = layer
	add_child(mi)

func _ready() -> void:
	shot_frame = int(_env("LG_FRAMES", "90"))
	ProjectSettings.set_setting("rendering/lights_and_shadows/mobile_light_grid", _env("LG_GRID", "0") == "1")
	late_on = _env("LG_GRID", "0") == "2"
	Engine.max_fps = 0
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.22, 0.3)
	env.ambient_light_energy = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.2, 14)
	cam.rotation_degrees = Vector3(-9, 0, 0)
	cam.fov = 70
	match int(_env("LG_CAM", "0")):
		1:
			cam.position = Vector3(-7.2, 1.2, 6)
			cam.rotation_degrees = Vector3(25, -20, 0)
		2:
			cam.position = Vector3(2, 7, 0)
			cam.rotation_degrees = Vector3(-70, 35, 20)
	add_child(cam)
	var cull := int(_env("LG_CULL", "0"))
	var ground_layer := 2 if cull == 2 else 1
	if _env("LG_SPLIT", "0") == "1":
		for z in 30:
			for x in 6:
				_box(Vector3(-12.5 + x * 5.0, -0.1, 12.5 - z * 5.0), Vector3(5, 0.2, 5), Color(0.5, 0.5, 0.52), ground_layer)
	else:
		_box(Vector3(0, -0.1, -60), Vector3(30, 0.2, 150), Color(0.5, 0.5, 0.52), ground_layer)      # one merged ground mesh
	_box(Vector3(-9, 5, -60), Vector3(1, 10, 150), Color(0.75, 0.6, 0.45))               # one merged facade
	_box(Vector3(9, 4, -60), Vector3(1, 8, 150), Color(0.55, 0.6, 0.7))
	for i in 12:  # parked cars / props: small separate meshes
		_box(Vector3(5.5 if i % 2 == 0 else -5.5, 0.7, 6 - i * 9.0), Vector3(1.8, 1.4, 4.2), Color.from_hsv(i / 12.0, 0.5, 0.7))
	var n_omni := int(_env("LG_OMNI", "24"))
	for i in n_omni:  # street lamps, both sides, every 6 m
		var o := OmniLight3D.new()
		o.position = Vector3(-6.5 if i % 2 == 0 else 6.5, 4.5, 8 - (i / 2) * 6.0)
		o.omni_range = 9.0
		o.light_energy = 2.5
		o.light_color = Color(1.0, 0.82, 0.55) if i % 3 != 0 else Color(0.7, 0.85, 1.0)
		o.shadow_enabled = false
		if cull > 0: o.light_cull_mask = 1
		add_child(o)
	var n_spot := int(_env("LG_SPOT", "4"))
	for i in n_spot:  # headlights down the road
		var s := SpotLight3D.new()
		s.position = Vector3(-1.5 + (i % 2) * 3.0, 0.8, 10 - (i / 2) * 25.0)
		s.rotation_degrees = Vector3(-4, 0, 0)
		s.spot_range = 28.0
		s.spot_angle = 28.0
		s.light_energy = 6.0
		s.shadow_enabled = false
		if cull > 0: s.light_cull_mask = 1
		add_child(s)

func _process(dt: float) -> void:
	frame += 1
	if late_on and frame == 45:
		ProjectSettings.set_setting("rendering/lights_and_shadows/mobile_light_grid", true)
	if frame > shot_frame - 50 and frame <= shot_frame:
		t_sum += dt
		t_n += 1
	if frame == shot_frame:
		await RenderingServer.frame_post_draw
		var n := _env("LG_NAME", "shot")
		get_viewport().get_texture().get_image().save_png("user://%s.png" % n)
		print("light_grid: saved %s grid=%s omni=%s spot=%s frame_ms=%.2f" % [n, _env("LG_GRID", "0"), _env("LG_OMNI", "24"), _env("LG_SPOT", "4"), 1000.0 * t_sum / maxf(1, t_n)])
		get_tree().quit()
