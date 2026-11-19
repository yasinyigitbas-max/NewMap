extends SceneTree
## The player's bicycle (C++: CityBike, BikeReach, CityPed's balancing body), headless with physics:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_bike_ride.gd
## A flat floor. The player stands by a bicycle; the script presses its pedals, bar and brake (set_controls) as a
## thumb would. PASS needs: he gets on (the Quaternius Sitting_Enter clip, then riding: Driving_Loop with his feet on
## the pedals); pedalling takes it to a rider's speed and it stays upright; sprinting goes faster; the view wobbles with
## the pedalling; steering turns it and it leans INTO the turn; the brakes stop it in a short way without throwing him;
## he gets off (Sitting_Exit) and stands beside it as the player again; back on, he rides into a wall at a sprint: he is
## thrown (his balancing body: hips near the floor), the bicycle is damaged (the front wheel bent), he gets up by
## himself and is the player again, on foot.
var player: Node3D
var bike: RigidBody3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var p0 := Vector3.ZERO
var yaw0 := 0.0
var v_most := 0.0
var v_cruise := 0.0
var lean_most := 0.0
var clips := {}
var lowest := 9.0
var stop_from := Vector3.ZERO

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("BIKERIDE   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityBike"):
		print("BIKERIDE ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(0, -1, 0); root.add_child(fl)
	player = ClassDB.instantiate(&"CityPlayer")
	player.position = Vector3(-0.9, 0.05, 0)
	root.add_child(player)
	bike = ClassDB.instantiate(&"CityBike")
	bike.position = Vector3(0, 0.02, 0)
	root.add_child(bike)
	bike.call(&"set_rider_player", player)

func _st() -> Dictionary: return bike.call(&"get_state")

func _yaw() -> float:
	var f: Vector3 = bike.global_basis.z
	return atan2(f.x, f.z)

func _wall(ahead: float) -> void:
	var f: Vector3 = bike.global_basis.z; f.y = 0; f = f.normalized()
	var w := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(10, 3, 0.6); cs.shape = sh; w.add_child(cs)
	w.position = bike.global_position + f * ahead + Vector3(0, 1.5, 0); w.rotation.y = atan2(f.x, f.z)
	root.add_child(w)

func _physics_process(delta: float) -> bool:
	if bike == null: return true
	t += delta
	var s := _st()
	clips[String(s.rider_clip).trim_prefix("ual/")] = true
	match step:
		0:
			if t < 1.0: return false
			_check(bool(bike.call(&"get_on")), "the player standing by it gets on")
			step = 1; t0 = t
		1:
			if String(s.state) != "riding" and t - t0 < 5.0: return false
			_check(String(s.state) == "riding" and clips.has("Sitting_Enter"), "getting on plays Sitting_Enter, then he rides (%.1f s; clips %s)" % [t - t0, str(clips.keys())])
			_check(not player.visible, "the player himself is not there while he rides (his figure is the rider)")
			bike.call(&"set_controls", 1.0, 0.0, 0.0, 0.0)
			p0 = bike.global_position; step = 2; t0 = t
		2:      # pedalling
			lean_most = maxf(lean_most, absf(float(s.lean)))
			if t - t0 < 9.0: return false
			v_cruise = float(s.speed)
			_check(v_cruise > 4.5 and v_cruise < 9.5, "pedalling for 9 s: %.1f m/s (%.0f km/h), a rider's speed" % [v_cruise, v_cruise * 3.6])
			_check(lean_most < 0.08 and float(s.upright) > 0.97, "riding straight it stays upright (lean at most %.3f rad, upright %.3f)" % [lean_most, float(s.upright)])
			_check(Vector2(bike.global_position.x - p0.x, bike.global_position.z - p0.z).length() > 30.0, "it went %.0f m" % Vector2(bike.global_position.x - p0.x, bike.global_position.z - p0.z).length())
			_check(String(s.rider_clip).ends_with("Driving_Loop"), "riding, the figure plays Driving_Loop (his feet are reached to the pedals)")
			_check(float(s.view_wobble_most) > 0.01, "the view wobbles with the pedalling (roll + bob at most %.3f)" % float(s.view_wobble_most))
			bike.call(&"set_controls", 1.0, 0.0, 0.0, 1.0)
			step = 3; t0 = t
		3:      # sprinting
			v_most = maxf(v_most, float(s.speed))
			if t - t0 < 5.0: return false
			_check(v_most > v_cruise + 0.8, "sprinting goes faster: %.1f m/s" % v_most)
			bike.call(&"set_controls", 0.6, 0.0, 0.6, 0.0)
			yaw0 = _yaw(); lean_most = 0.0; step = 4; t0 = t
		4:      # a left turn
			lean_most = minf(lean_most, float(s.lean))
			if t - t0 < 3.0: return false
			var turned := rad_to_deg(wrapf(_yaw() - yaw0, -PI, PI))
			_check(turned > 45.0, "steering left turns it left: %.0f degrees in 3 s" % turned)
			_check(lean_most < -0.08 and lean_most > -0.75, "it leans into the turn (its left side down by %.2f rad)" % -lean_most)
			bike.call(&"set_controls", 1.0, 0.0, 0.0, 0.0)
			step = 5; t0 = t
		5:      # straighten, then brake hard
			if t - t0 < 4.0: return false
			bike.call(&"set_controls", 0.0, 1.0, 0.0, 0.0)
			stop_from = bike.global_position; v_cruise = float(s.speed); step = 6; t0 = t
		6:
			if absf(float(s.speed)) > 0.1 and t - t0 < 6.0: return false
			var d := Vector2(bike.global_position.x - stop_from.x, bike.global_position.z - stop_from.z).length()
			_check(absf(float(s.speed)) <= 0.1 and d < 8.0 and String(s.state) == "riding", "braking hard from %.1f m/s stops it in %.1f m, still riding" % [v_cruise, d])
			bike.call(&"set_controls", 0.0, 0.0, 0.0, 0.0)
			_check(bool(bike.call(&"get_off")), "standing still, he gets off")
			step = 7; t0 = t
		7:
			if String(s.state) != "parked" and t - t0 < 5.0: return false
			var dd: float = player.global_position.distance_to(bike.global_position)
			_check(String(s.state) == "parked" and clips.has("Sitting_Exit") and player.visible and not bool(player.call(&"is_frozen")) and dd < 1.6, "getting off plays Sitting_Exit; he stands beside it (%.2f m) as the player again" % dd)
			_wall(18.0)
			_check(bool(bike.call(&"get_on")), "he gets on again")
			step = 8; t0 = t
		8:
			if String(s.state) != "riding" and t - t0 < 5.0: return false
			bike.call(&"set_controls", 1.0, 0.0, 0.0, 1.0)
			step = 9; t0 = t
		9:      # into the wall at a sprint
			if String(s.state) != "thrown" and t - t0 < 12.0: return false
			_check(String(s.state) == "thrown", "into a wall at %.1f m/s: he is thrown (the knock %.1f m/s)" % [v_most, float(s.hardest_knock)])
			_check(float(s.damage) > 30.0 and bool(s.wheel_bent), "the bicycle is damaged: %.0f of 100, the front wheel bent" % float(s.damage))
			step = 10; t0 = t
		10:
			if int(s.rider_mode) == 1: lowest = minf(lowest, (s.rider_at as Vector3).y)
			if String(s.state) != "parked" and t - t0 < 25.0: return false
			_check(lowest < 0.6, "his balancing body took him: it went down (hips %.2f m over the floor at the lowest)" % lowest)
			_check(String(s.state) == "parked" and player.visible and not bool(player.call(&"is_frozen")), "he got up by himself and is the player again, on foot (%.0f s after the crash)" % (t - t0))
			step = 99
		99:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
