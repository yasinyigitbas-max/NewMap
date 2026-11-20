extends SceneTree
## A film of the high climb (the Animator, 20 Nov; Yasin: "can i see a high climb clip?"): the player walks at a 1.6 m
## wall and climbs it (ual/ClimbUp_2m, his hands on the edge), stands a moment, walks on; then the same from a jump.
## Side view, 25 fps.
##   godot --path . --rendering-method mobile --resolution 640x480 --fixed-fps 50 -s res://tests/people/climb_film.gd -- --out=OUT/climb_film
## Writes <out>/f_<frame>.png; tools/people/gait_film.py --frames <out> <gif> lays them into a GIF.
var out := "OUT/climb_film"
var player: CharacterBody3D
var cam: Camera3D
var n := 0
var shot := 0
var take := 0
var t := 0.0
var look := Vector3(0, 1.0, 0)
const WALL_H := 1.6

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	if not ClassDB.class_exists(&"CityPlayer"): print("FILM ERROR no native module"); quit(1); return
	DirAccess.make_dir_recursive_absolute(out)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 60, 0); sun.shadow_enabled = true; root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.7, 0.78, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.52, 0.53, 0.55)); img.set_pixel(1, 1, Color(0.52, 0.53, 0.55))
	img.set_pixel(1, 0, Color(0.40, 0.41, 0.43)); img.set_pixel(0, 1, Color(0.40, 0.41, 0.43))
	var tex := ImageTexture.create_from_image(img)
	_box(Vector3(60, 2, 60), Vector3(0, -1, 0), tex, Vector3(30, 30, 1))
	_box(Vector3(4, WALL_H, 3), Vector3(0, WALL_H / 2.0, 4.5), null, Vector3.ONE)   # (its face at z 3: the stick forward walks him along +z)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)
	cam = Camera3D.new(); cam.fov = 45.0; root.add_child(cam)

func _box(size: Vector3, at: Vector3, tex: Texture2D, uv: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	var m := StandardMaterial3D.new()
	if tex: m.albedo_texture = tex; m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; m.uv1_scale = uv
	else: m.albedo_color = Color(0.62, 0.5, 0.42)
	mi.material_override = m; b.add_child(mi); b.position = at; root.add_child(b)

func _physics_process(delta: float) -> bool:
	n += 1; t += delta
	cam.current = true
	look = look.lerp(player.global_position + Vector3(0, 1.0, 0), minf(delta * 3.0, 1.0))
	cam.look_at_from_position(look + Vector3(4.2, 0.7, 0.6), look, Vector3.UP)
	if n < 30: return false
	# take 0: stand 0.8 s, walk at the wall (and up it), then stand; take 1: from the start again, a jump on the way
	if t > 0.8: player.call(&"set_move", Vector2(0, 1) if t < 6.5 else Vector2.ZERO, false)
	if take == 1 and absf(t - 2.6) < delta * 0.5: player.call(&"jump")
	if t > 8.0:
		take += 1; t = 0.0
		if take >= 2: print("FILM %d frames saved: %s" % [shot, out]); quit(0); return true
		player.global_position = Vector3(0, 0.05, 0); player.velocity = Vector3.ZERO; player.call(&"set_move", Vector2.ZERO, false)
	if n % 2 == 0:
		root.get_texture().get_image().save_png("%s/f_%03d.png" % [out, shot]); shot += 1
	return false
