extends SceneTree
## Getting into and out of a car (C++: CityCar::enter / leave, city_car_door.cpp, the door in car_paint.gdshader; Yasin,
## 20 Nov: "WE NEED A GET INTO CAR, GET OUT OF CAR ANIMATION TOO. CARS DOORS SHOULD OPEN, SEATING IN, DOOR CLOSE, THEN WE CAN
## DRIVE OFF"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/game/test_car_entry.gd
## The player stands on the car's far side. Get in: he walks round the front to the driver's door, it opens, he sits in,
## the door closes, the wheel is his. Get out: the door opens, he stands up out of it, he is the player by the door, the
## door closes. Checks: every step in order; the driver's hips never jump (at most 6 cm a frame); seated, the door shut;
## out, the player stands by the door (on the car's left, within 1.3 m of its side) and can walk. Picture strip:
## OUT/car_entry_strip.png.
var player: CharacterBody3D
var car: RigidBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var seen := []
var hips_prev := Vector3.ZERO
var hips_jump := 0.0
var jump_at := -1
var shots := []
var shot_states := {}

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("CARIN   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(200, 2, 200); cs.shape = sh; fl.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi); fl.position = Vector3(0, -1, 0); root.add_child(fl)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 140, 0); root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.55, 0.7, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.62); root.add_child(env)
	car = ClassDB.instantiate(&"CityCar"); root.add_child(car)
	car.call(&"become", 2, 0, Color(0.55, 0.12, 0.1))
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(-2.6, 0.05, 0.5); root.add_child(player)
	cam = Camera3D.new(); root.add_child(cam)

func _physics_process(_d: float) -> bool:
	t += _d
	cam.current = true
	cam.look_at_from_position(Vector3(3.4, 1.7, 2.4), Vector3(0.6, 0.8, -0.3), Vector3.UP)
	var st := int(car.call(&"get_entry_state"))
	if seen.is_empty() or seen[-1] != st: seen.append(st)
	var h: Vector3 = car.call(&"get_driver_hips")
	if h != Vector3.ZERO and hips_prev != Vector3.ZERO:
		var mv := (h - hips_prev).length()
		if mv > hips_jump: hips_jump = mv; jump_at = st
	hips_prev = h
	for want in [3, 4, 5, 6, 7, 8, 10]:   # (open, sitting in, turning in, closing, opening out, standing out)
		if st == want and not shot_states.has(want):
			shot_states[want] = t
		if shot_states.has(want) and float(shot_states[want]) > 0.0 and t - float(shot_states[want]) > 0.3:
			shot_states[want] = -1.0; shots.append(root.get_texture().get_image())
	match step:
		0:
			if t < 1.5: return false
			_check(bool(car.call(&"enter", player)), "he goes to get in (from the car's far side)"); step = 1; t0 = t
		1:
			if not bool(car.call(&"is_seated")):
				if t - t0 > 20.0: _check(false, "seated within 20 s (states %s)" % str(seen)); step = 9
				return false
			_check(float(car.call(&"get_door")) < 0.01 and bool(car.call(&"get_player")), "seated after %.1f s: the door shut, the wheel his (states %s)" % [t - t0, str(seen)])
			step = 2; t0 = t
		2:
			if t - t0 < 1.0: return false
			_check(bool(car.call(&"leave")), "stopped, he gets out"); step = 3; t0 = t
		3:
			if int(car.call(&"get_entry_state")) != 0:
				if t - t0 > 15.0: _check(false, "out within 15 s (states %s)" % str(seen)); step = 9
				return false
			var l: Vector3 = car.global_transform.affine_inverse() * player.global_position
			_check(player.visible and l.x > 0.8 and l.x < 2.4 and absf(l.z) < 1.5, "out: the player stands by the driver's door (car frame x %.2f z %.2f) after %.1f s" % [l.x, l.z, t - t0])
			_check(hips_jump < 0.06, "the driver's hips at most %.3f m in a frame (worst in step %d)" % [hips_jump, jump_at])
			var away: Vector3 = car.global_transform.basis.x   # (the view turned away from the car: he walks where it looks)
			player.call(&"set_view", atan2(away.x, away.z), atan2(-away.x, -away.z), -0.15)
			player.call(&"set_move", Vector2(0, 1), false); step = 4; t0 = t; set_meta("out_at", player.global_position)
		4:
			if t - t0 < 1.5: return false
			# (he walks the way the camera looks: since the one camera, 21 Nov, it does not cut round behind him as he gets out)
			var went: float = player.global_position.distance_to(get_meta("out_at"))
			_check(went > 0.8 and player.global_position.distance_to(car.global_position) > 1.6, "he walks off (%.2f m, %.2f m from the car)" % [went, player.global_position.distance_to(car.global_position)])
			step = 9
		9:
			if not shots.is_empty():
				var w := 456; var hh := 300
				var strip := Image.create(w * shots.size(), hh, false, Image.FORMAT_RGBA8)
				for i in shots.size():
					var im: Image = shots[i]; im.convert(Image.FORMAT_RGBA8)
					var c := im.get_region(Rect2i(100, 20, 760, 500)); c.resize(w, hh)
					strip.blit_rect(c, Rect2i(0, 0, w, hh), Vector2i(i * w, 0))
				strip.save_png("res://OUT/car_entry_strip.png")
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0); return true
	return false
