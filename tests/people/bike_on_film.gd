extends SceneTree
## A film of getting on the bicycle (the Animator, 20 Nov: he appeared on the saddle at once; a fallen bicycle jumped
## upright): take 1, the bicycle standing, the player beside it gets on (the get-off played backwards) and rides off a
## little; take 2, the bicycle lying on its side: he bends down and lifts it, then gets on. 25 fps.
##   godot --path . --rendering-method mobile --resolution 640x480 --fixed-fps 50 -s res://tests/people/bike_on_film.gd -- --out=OUT/bike_on
## Writes <out>/f_<frame>.png.
var out := "OUT/bike_on"
var player: CharacterBody3D
var bike: RigidBody3D
var cam: Camera3D
var t := 0.0
var step := 0
var n := 0
var shot := 0

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 60, 0); sun.shadow_enabled = true; root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.7, 0.78, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(400, 2, 400); cs.shape = sh; fl.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.5, 0.51, 0.53); mi.material_override = m; fl.add_child(mi)
	fl.position = Vector3(0, -1, 0); root.add_child(fl)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0.9, 0.05, 0); root.add_child(player)
	bike = ClassDB.instantiate(&"CityBike"); bike.position = Vector3(0, 0.02, 0); root.add_child(bike)
	bike.call(&"set_rider_player", player)
	bike.set(&"chase_camera", false)
	cam = Camera3D.new(); cam.fov = 45.0; root.add_child(cam)

func _physics_process(delta: float) -> bool:
	t += delta; n += 1
	cam.current = true
	var focus: Vector3 = bike.global_position + Vector3(0, 0.8, 0)
	cam.look_at_from_position(focus + Vector3(3.6, 0.9, 2.2), focus, Vector3.UP)
	if n % 2 == 0 and t > 0.5: root.get_texture().get_image().save_png("%s/f_%03d.png" % [out, shot]); shot += 1
	match step:
		0:
			if t < 1.0: return false
			print("FILM get on: %s" % bike.call(&"get_on")); step = 1; t = 0.0
		1:
			if t < 3.0: return false
			print("FILM get off: %s" % bike.call(&"get_off")); step = 2; t = 0.0
		2:
			if t < 2.5: return false
			# take 2: the bicycle on its side, the player beside it
			bike.call(&"knock_over")
			player.global_position = Vector3(1.0, 0.05, 0.3); player.velocity = Vector3.ZERO
			step = 3; t = 0.0
		3:
			if t < 1.5: return false
			print("FILM lift and get on: %s" % bike.call(&"get_on")); step = 4; t = 0.0
		4:
			if t < 4.5: return false
			print("FILM %d frames saved: %s" % [shot, out]); quit(0); return true
	return false
