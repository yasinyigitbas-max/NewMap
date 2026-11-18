extends Node3D
# A still street-like scene with the things an upscaler is judged on: 3D text, thin rails and wires, a striped
# crosswalk, a textured ground seen at a low angle, hard building edges against the sky.
# env UP_SCALE (default 0.5), UP_MODE (0 bilinear, 1 FSR 1 mode = SGSR 1 with patch c), UP_AA (0 off, 1 FXAA),
# UP_SHARP (fsr_sharpness, default 0.2), UP_NAME (file name). Saves user://<UP_NAME>.png after 60 frames and quits.
var frame := 0

func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return d if v == "" else v

func _tex(kind: int) -> ImageTexture:
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + kind
	for y in 256:
		for x in 256:
			var c: Color
			if kind == 0:   # paving: bricks with joints and grain
				var bx := (x + (16 if (y / 16) % 2 == 1 else 0)) % 32
				var joint := bx < 2 or y % 16 < 2
				var g := 0.45 + rng.randf() * 0.12
				c = Color(0.25, 0.25, 0.25) if joint else Color(g + 0.08, g, g - 0.05)
			else:           # facade: windows grid
				var wx := x % 32
				var wy := y % 40
				var win := wx > 6 and wx < 26 and wy > 8 and wy < 32
				var frame_px := win and (wx == 7 or wx == 25 or wy == 9 or wy == 31 or wx == 16)
				c = Color(0.9, 0.9, 0.85) if frame_px else (Color(0.15, 0.22, 0.3) if win else Color(0.7, 0.55, 0.4))
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _box(pos: Vector3, size: Vector3, col: Color, tex: Texture2D = null, uv := Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	if tex:
		m.albedo_texture = tex
		m.uv1_scale = uv
	mi.material_override = m
	mi.position = pos
	add_child(mi)

func _ready() -> void:
	var vp := get_viewport()
	vp.scaling_3d_scale = float(_env("UP_SCALE", "0.5"))
	vp.scaling_3d_mode = int(_env("UP_MODE", "0")) as Viewport.Scaling3DMode
	vp.screen_space_aa = int(_env("UP_AA", "1")) as Viewport.ScreenSpaceAA
	vp.fsr_sharpness = float(_env("UP_SHARP", "0.2"))
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.72, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.75)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.7, 9)
	cam.rotation_degrees = Vector3(-6, 8, 0)
	cam.fov = 65
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var paving := _tex(0)
	var facade := _tex(1)
	_box(Vector3(0, -0.05, -10), Vector3(60, 0.1, 60), Color.WHITE, paving, Vector3(40, 40, 1))
	for i in 5:   # buildings both sides
		_box(Vector3(-7, 4 + i % 2, -2 - i * 7.0), Vector3(5, 8 + 2 * (i % 2), 6), Color.WHITE, facade, Vector3(3, 3, 1))
		_box(Vector3(7.5, 3 + (i + 1) % 2, -4 - i * 7.0), Vector3(5, 6 + 2 * ((i + 1) % 2), 6), Color(0.9, 0.95, 1.0), facade, Vector3(3, 2, 1))
	for i in 9:   # crosswalk stripes
		_box(Vector3(-3.2 + i * 0.8, 0.01, 3.0), Vector3(0.45, 0.02, 2.4), Color(0.95, 0.95, 0.95))
	for i in 24:  # railing posts + rails (thin geometry)
		_box(Vector3(-3.6, 0.5, 6 - i * 1.2), Vector3(0.04, 1.0, 0.04), Color(0.1, 0.1, 0.12))
	_box(Vector3(-3.6, 1.0, -8), Vector3(0.03, 0.03, 30), Color(0.1, 0.1, 0.12))
	_box(Vector3(-3.6, 0.6, -8), Vector3(0.03, 0.03, 30), Color(0.1, 0.1, 0.12))
	for i in 3:   # overhead wires
		_box(Vector3(0, 5.2 + i * 0.25, -6 - i * 5.0), Vector3(16, 0.015, 0.015), Color(0.05, 0.05, 0.05))
	var texts := ["CORONADO BAKERY", "Open 7:00 - 19:00", "Fresh bread every morning", "ORANGE AVE  1200"]
	for i in texts.size():
		var l := Label3D.new()
		l.text = texts[i]
		l.font_size = 64 if i == 0 else 40
		l.pixel_size = 0.006
		l.modulate = Color(0.1, 0.1, 0.1) if i % 2 == 1 else Color(0.75, 0.1, 0.1)
		l.outline_size = 0
		l.position = Vector3(3.4, 2.6 - i * 0.45, 2.0 - i * 1.5)
		l.rotation_degrees = Vector3(0, -55, 0)
		add_child(l)

func _process(_dt: float) -> void:
	frame += 1
	if frame == 60:
		await RenderingServer.frame_post_draw
		var n := _env("UP_NAME", "shot")
		get_viewport().get_texture().get_image().save_png("user://%s.png" % n)
		print("upscale: saved %s scale=%.2f mode=%d aa=%d" % [n, get_viewport().scaling_3d_scale, get_viewport().scaling_3d_mode, get_viewport().screen_space_aa])
		get_tree().quit()
