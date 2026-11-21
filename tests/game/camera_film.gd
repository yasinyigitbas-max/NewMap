extends SceneTree
## THE ONE CAMERA (Yasin, 21 Nov: "getting into cars either drops the camera off the floor or us off the floor ... why do
## we even have 2 camera set ups anyway? unify the camera, make it a god of war like shoulder camera that follows us
## everywhere"; "make sure that camera switches shoulders and looks for a better view when the screen is blocked on its
## own"), in a window, through the player's own camera:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/game/camera_film.gd -- --out=OUT/camera_film
## He walks beside a wall on his right (the view swings to his left shoulder, and back once past it), gets into a car,
## drives it, gets out, gets on a bicycle and rides. Checks: the player's camera is the one in use all the way; it never
## goes under the floor or through the wall; he never drops (the hidden body held while he drives); the shoulder swapped
## at the wall. Frames <out>/f_<n>.png every 4th frame.
var out := "OUT/camera_film"
var player: CharacterBody3D
var car: RigidBody3D
var bike: RigidBody3D
var t := 0.0
var t0 := 0.0
var step := 0
var n := 0
var shot := 0
var fails := 0
var low := 99.0
var pl_low := 99.0
var other_cam := 0
var left_seen := false
var back_right := false
var in_wall := 0

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("CAMERA   %s: %s" % ["ok" if ok else "FAIL", what])

func _box(at: Vector3, size: Vector3, col: Color) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = col; mi.material_override = m; b.add_child(mi); b.position = at; root.add_child(b)

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	_box(Vector3(0, -1, 0), Vector3(300, 2, 300), Color(0.45, 0.45, 0.47))
	_box(Vector3(-1.0, 1.5, 14.0), Vector3(0.4, 3.0, 8.0), Color(0.7, 0.45, 0.35))   # the wall on his right as he walks +z
	for k in 6: _box(Vector3(6.0 + k * 3.0, 1.0, -8.0 - (k % 2) * 4.0), Vector3(1, 2, 1), Color(0.3, 0.5, 0.7))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 150, 0); sun.shadow_enabled = true; root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.55, 0.7, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.62); root.add_child(env)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(-0.3, 0.05, 7.0); player.rotation.y = 0.0; root.add_child(player)
	car = ClassDB.instantiate(&"CityCar"); car.position = Vector3(4.0, 0.05, 24.0); root.add_child(car)
	car.call(&"become", 2, 0, Color(0.55, 0.12, 0.1))

func _cam() -> Camera3D: return root.get_viewport().get_camera_3d()

func _physics_process(d: float) -> bool:
	t += d; n += 1
	var c := _cam()
	if c and step >= 1:
		if c.get_parent() != player: other_cam += 1
		low = minf(low, c.global_position.y)
		if c.global_position.x > -1.2 and c.global_position.x < -0.8 and absf(c.global_position.z - 14.0) < 4.0: in_wall += 1
		if n % 4 == 0: root.get_texture().get_image().save_png("%s/f_%04d.png" % [out, shot]); shot += 1
	if step >= 1: pl_low = minf(pl_low, player.global_position.y)
	if c and step == 1:   # by the wall: is the camera over his left shoulder? (left of him as he walks +z is +x)
		var side: float = (c.global_position - player.global_position).x
		if player.global_position.z > 11.0 and player.global_position.z < 17.0 and side > 0.2: left_seen = true
		if left_seen and player.global_position.z > 20.5 and side < -0.2: back_right = true
	match step:
		0:
			if t < 1.0: return false
			player.call(&"set_view", 0.0, PI, -0.15)   # (he faces +z, the camera behind him)
			step = 1; t0 = t
		1:
			player.call(&"set_move", Vector2(0, 0.6), false)
			if player.global_position.z < 22.0 and t - t0 < 25.0: return false
			player.call(&"set_move", Vector2.ZERO, false)
			_check(left_seen, "beside the wall on his right the view went over his left shoulder")
			# (it stays over the left shoulder after the wall: it moves only when blocked, Yasin 21 Nov: "not a timed camera")
			step = 2; t0 = t
		2:
			if t - t0 < 0.8: return false
			_check(bool(car.call(&"enter", player)), "he goes to the car")
			step = 3; t0 = t
		3:
			if not bool(car.call(&"get_player")) and t - t0 < 20.0: return false
			_check(bool(car.call(&"get_player")), "seated, the wheel his (%.1f s)" % (t - t0))
			step = 4; t0 = t
		4:
			car.call(&"set_controls", 0.5 if t - t0 < 4.0 else 0.0, 0.0 if t - t0 < 4.0 else 1.0, 0.35 if t - t0 > 1.5 else 0.0, 0.0, false)
			if t - t0 < 7.0: return false
			_check(bool(car.call(&"leave")), "stopped, he gets out")
			step = 5; t0 = t
		5:
			if int(car.call(&"get_entry_state")) != 0 and t - t0 < 15.0: return false
			_check(player.visible, "out, on his feet")
			bike = ClassDB.instantiate(&"CityBike"); bike.position = player.global_position + Vector3(1.2, 0.02, 0); root.add_child(bike)
			bike.set(&"player", true); bike.call(&"set_rider_player", player)
			step = 6; t0 = t
		6:
			if t - t0 < 0.6: return false
			_check(bool(bike.call(&"get_on")), "he gets on the bicycle")
			step = 7; t0 = t
		7:
			if String(bike.call(&"get_state").state) == "riding": bike.call(&"set_controls", 0.8, 0.0, 0.25 if t - t0 > 3.0 else 0.0, 0.0)
			if t - t0 < 8.0: return false
			_check(other_cam == 0, "the player's camera all the way (%d frames another's)" % other_cam)
			_check(low > 0.3, "the camera never under the floor (lowest %.2f m)" % low)
			_check(in_wall == 0, "never inside the wall (%d frames)" % in_wall)
			_check(pl_low > -0.3, "he never dropped through the floor (lowest %.2f m)" % pl_low)
			print("FILM %d frames: %s" % [shot, out])
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0); return true
	return false
