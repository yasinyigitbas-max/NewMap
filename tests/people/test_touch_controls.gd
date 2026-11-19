extends SceneTree
## The old game's touch controls, copied (C++: CityPlayer, CityCar, CityBike; places in ui_plate; docs/OLD_CONTROLS_SPEC.md),
## headless with physics; this script lays fingers on the screen as screen-touch events:
##   godot --path . --rendering-method mobile --resolution 1152x648 --fixed-fps 60 -s res://tests/people/test_touch_controls.gd
## (a real window: headless the screen is 64 x 64 and a thumb has nowhere to land)
## On foot: a thumb dragged up on the left half walks him ahead (past 72 px he runs); a drag on the right half turns his
## view; a double tap on the right jumps, on the left crouches. The car: a finger on GAS drives it, on BRAKE stops it and,
## held at a standstill, reverses. The bicycle: on the pedal plate it rides, a thumb slid on the left half steers it.
var player: CharacterBody3D
var car: RigidBody3D
var bike: RigidBody3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var p0 := Vector3.ZERO
var y_top := -9.0
var sz := Vector2(1152, 648)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("TOUCH   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	root.size = Vector2i(1152, 648)      # (headless the window is 64 x 64: the old game's canvas, so the fingers land where a thumb would)
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(0, -1, 0); root.add_child(fl)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)

func _touch(i: int, at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new(); e.index = i; e.position = at; e.pressed = down; root.push_input(e)

func _drag(i: int, at: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new(); e.index = i; e.position = at; e.relative = rel; root.push_input(e)

func _physics_process(delta: float) -> bool:
	t += delta
	sz = root.get_visible_rect().size
	match step:
		0:
			if t < 0.5: return false
			p0 = player.global_position
			_touch(0, Vector2(200, 450), true); _drag(0, Vector2(200, 410), Vector2(0, -40))      # 40 px up: walking
			step = 1; t0 = t
		1:
			if t - t0 < 1.5: return false
			var walk: float = player.call(&"get_speed")
			_drag(0, Vector2(200, 360), Vector2(0, -50))      # 90 px up: past 72 px he runs
			step = 2; t0 = t; set_meta("walk", walk)
		2:
			if t - t0 < 1.5: return false
			var run: float = player.call(&"get_speed"); var walk: float = get_meta("walk")
			_check(walk > 0.4 and run > walk + 1.0, "a thumb dragged up on the left half walks him (%.1f m/s), further up he runs (%.1f m/s)" % [walk, run])
			_check(player.global_position.distance_to(p0) > 2.0, "he went %.1f m" % player.global_position.distance_to(p0))
			_touch(0, Vector2(200, 360), false)
			var cam := root.get_viewport().get_camera_3d(); set_meta("yaw0", cam.global_rotation.y)
			_touch(1, Vector2(900, 300), true); _drag(1, Vector2(1000, 300), Vector2(100, 0)); _touch(1, Vector2(1000, 300), false)
			step = 3; t0 = t
		3:
			if t - t0 < 0.4: return false
			var cam := root.get_viewport().get_camera_3d()
			var turned := absf(rad_to_deg(wrapf(cam.global_rotation.y - float(get_meta("yaw0")), -PI, PI)))
			_check(turned > 15.0, "a drag of 100 px on the right half turns his view %.0f degrees (the old 0.3 a pixel)" % turned)
			y_top = player.global_position.y
			_touch(2, Vector2(900, 200), true); _touch(2, Vector2(900, 200), false); _touch(2, Vector2(905, 205), true); _touch(2, Vector2(905, 205), false)
			step = 4; t0 = t
		4:
			y_top = maxf(y_top, player.global_position.y)
			if t - t0 < 1.0: return false
			_check(y_top > 0.5, "a double tap on the right half jumps (%.2f m up)" % y_top)
			_touch(3, Vector2(150, 200), true); _touch(3, Vector2(150, 200), false); _touch(3, Vector2(152, 202), true); _touch(3, Vector2(152, 202), false)
			step = 5; t0 = t
		5:
			if t - t0 < 0.3: return false
			_check(bool(player.call(&"get_crouch")) and String(player.call(&"get_clip")).contains("Crouch"), "a double tap on the left half crouches (%s)" % player.call(&"get_clip"))
			player.call(&"set_crouch", false)
			car = ClassDB.instantiate(&"CityCar"); car.set(&"model", 2); car.position = Vector3(20, 0.3, 0); root.add_child(car)
			car.set(&"player", true)
			step = 6; t0 = t
		6:
			if t - t0 < 1.0: return false
			var g: Rect2 = Rect2(sz.x - (24 + 104) * sz.y / 648.0, sz.y - (24 + 76 + 8 + 144) * sz.y / 648.0, 104 * sz.y / 648.0, 144 * sz.y / 648.0)
			_touch(4, g.get_center(), true); set_meta("g", g)
			step = 7; t0 = t
		7:
			if t - t0 < 3.0: return false
			var v: float = car.call(&"get_state").speed
			_check(v > 3.0, "a finger on GAS drives the car: %.1f m/s after 3 s" % v)
			_touch(4, (get_meta("g") as Rect2).get_center(), false)
			var b := Rect2(sz.x - (24 + 104 + 8 + 120) * sz.y / 648.0, sz.y - (24 + 76 + 8 + 96) * sz.y / 648.0, 120 * sz.y / 648.0, 96 * sz.y / 648.0)
			_touch(5, b.get_center(), true); set_meta("b", b)
			step = 8; t0 = t
		8:
			if t - t0 < 6.0: return false
			var v: float = car.call(&"get_state").speed
			_check(v < -0.3 and v > -5.0, "BRAKE stops it and, held at a standstill, reverses at a walking car's pace (%.1f m/s)" % v)
			_touch(5, (get_meta("b") as Rect2).get_center(), false)
			car.set(&"player", false)
			bike = ClassDB.instantiate(&"CityBike"); bike.position = player.global_position + Vector3(1.0, 0.02, 0); bike.set(&"chase_camera", false); root.add_child(bike)
			bike.set(&"player", true); bike.call(&"set_rider_player", player)
			step = 9; t0 = t
		9:
			if t - t0 < 0.5: return false
			_check(bool(bike.call(&"get_on")), "he gets on the bicycle")
			step = 10; t0 = t
		10:
			if String(bike.call(&"get_state").state) != "riding" and t - t0 < 5.0: return false
			_touch(6, (get_meta("g") as Rect2).get_center(), true)
			step = 11; t0 = t; set_meta("yaw_b", bike.global_rotation.y)
		11:
			if t - t0 < 4.0: return false
			var s: Dictionary = bike.call(&"get_state")
			_check(float(s.speed) > 2.5, "the pedal plate rides it: %.1f m/s" % float(s.speed))
			_touch(7, Vector2(300, 400), true); _drag(7, Vector2(240, 400), Vector2(-60, 0))      # slid left: turn left
			step = 12; t0 = t; set_meta("yaw_b", bike.global_rotation.y)
		12:
			if t - t0 < 2.0: return false
			var turned := rad_to_deg(wrapf(bike.global_rotation.y - float(get_meta("yaw_b")), -PI, PI))
			_check(turned > 20.0, "a thumb slid left on the left half steers it left: %.0f degrees in 2 s" % turned)
			step = 99
		99:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
