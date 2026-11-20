extends SceneTree
## Getting off the bicycle (C++: CityBike::dismount_pose, BikeReach; Yasin, 20 Nov: "WATCH THE BIKE HOP OFF ANIMATION AND FIX
## THAT TOO"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/people/test_bike_off.gd
## He rides, stops (the left foot comes down), gets off: up off the saddle, the right leg forward over the low frame, a step
## out, the hands let go; then the player stands there. Checks: the rider's hips never jump (at most 4 cm a frame); the
## player takes over where the rider stood (hips within 5 cm); the player is free to walk. Pictures: OUT/bike_off_strip.png
## (five moments of the dismount and the player after).
var player: CharacterBody3D
var bike: RigidBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var shots := []
var hips_prev := Vector3.INF
var hips_jump := 0.0
var last_rider_hips := Vector3.INF

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("BIKEOFF   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(400, 2, 400); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(0, -1, 0)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi); root.add_child(fl)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 30, 0); root.add_child(sun)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(-0.9, 0.05, 0); root.add_child(player)
	bike = ClassDB.instantiate(&"CityBike"); bike.position = Vector3(0, 0.02, 0); root.add_child(bike)
	bike.call(&"set_rider_player", player)
	cam = Camera3D.new(); root.add_child(cam)

func _shot() -> void:
	shots.append(root.get_texture().get_image())

func _physics_process(_delta: float) -> bool:
	t += _delta
	cam.current = true
	var b := bike.global_position
	var f: Vector3 = bike.global_basis.z; f.y = 0; f = f.normalized()
	var l := Vector3.UP.cross(f)
	cam.look_at_from_position(b + l * 3.0 + f * 1.2 + Vector3(0, 1.4, 0), b + l * 0.3 + Vector3(0, 0.75, 0), Vector3.UP)
	var s: Dictionary = bike.call(&"get_state")
	match step:
		0:
			if t < 1.0: return false
			bike.call(&"get_on"); step = 1
		1:
			if String(s.state) != "riding": return false
			bike.call(&"set_controls", 1.0, 0.0, 0.0, 0.0); step = 2; t0 = t
		2:
			if t - t0 < 2.0: return false
			bike.call(&"set_controls", 0.0, 1.0, 0.0, 0.0); step = 3; t0 = t
		3:
			if t - t0 < 3.0: return false
			bike.call(&"set_controls", 0.0, 0.0, 0.0, 0.0)
			_check(bool(bike.call(&"get_off")), "standing still, he gets off"); step = 4; t0 = t
		4:
			var hp: Vector3 = bike.global_transform * (s.hips_on_bike as Vector3) if s.has("hips_on_bike") else Vector3.INF
			if String(s.state) == "getting off":
				if hips_prev != Vector3.INF and hp != Vector3.INF: hips_jump = maxf(hips_jump, (hp - hips_prev).length())
				hips_prev = hp; last_rider_hips = hp
				var e := t - t0
				for k in 5:
					var at := 0.1 + 0.25 * k
					if e >= at and e < at + 1.0 / 60.0: _shot()
				return false
			if String(s.state) == "parked":
				var fl: Dictionary = player.call(&"get_frame_log")
				var ph: Vector3 = fl.get("pelvis_drawn", Vector3.INF)
				if t - t0 < 0.05 + 1.3 + 2.0 / 60.0: return false   # (the player's own figure posed once)
				_check(hips_jump < 0.04, "getting off, the rider's hips at most %.3f m in a frame" % hips_jump)
				_check(last_rider_hips != Vector3.INF and ph != Vector3.INF and (ph - last_rider_hips).length() < 0.05, "the player takes over where the rider stood: hips %.3f m apart" % (ph - last_rider_hips).length())
				step = 5; t0 = t
		5:
			if t - t0 < 0.4: return false
			_shot()
			player.call(&"set_move", Vector2(0.0, 1.0), false); step = 6; t0 = t
		6:
			if t - t0 < 1.5: return false
			_check(player.global_position.distance_to(bike.global_position) > 1.0, "he walks away from it (%.2f m)" % player.global_position.distance_to(bike.global_position))
			var w := 384; var h := 324
			var strip := Image.create(w * shots.size(), h, false, Image.FORMAT_RGBA8)
			for i in shots.size():
				var im: Image = shots[i]; im.convert(Image.FORMAT_RGBA8)
				strip.blit_rect(im, Rect2i(288, 108, w, h), Vector2i(i * w, 0))
			strip.save_png("res://OUT/bike_off_strip.png")
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0); return true
	return false
