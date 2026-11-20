extends SceneTree
## The car the player drives, and the people (C++: CityCrowd.set_player_car), headless:
##   godot --headless --fixed-fps 60 --path . -s res://tests/people/test_car_hits.gd
## The real streets over a flat floor; the "car" is a plain node this script moves (a test: the people only need to
## know where the car is and how big). 1) It is driven along a pavement at 30 km/h into the people walking there: they
## jump out of its way. 2) It is driven at 25 km/h into somebody who is held where he stands (he cannot jump): his
## animated body is handed to the balancing body, which is knocked over by the car's box, lies, and gets up; then he
## walks back to the pavement.
var crowd: Node3D
var car: Node3D
var t := 0.0
var step := 0
var t0 := 0.0
var fails := 0
var spot := Vector3.ZERO
var dir := Vector3.FORWARD
var held := -1
var from := Vector3.ZERO
var speed := 0.0
var dodges0 := 0
var was_down := false
var was_body := false
var lowest := 9.0

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityCrowd"):
		print("CARHIT ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 300); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 18)
	root.add_child(crowd)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("CARHIT   %s: %s" % ["ok" if ok else "FAIL", what])

func _person(id: int) -> Dictionary:
	for p: Dictionary in crowd.call(&"people_near", spot, 400.0):
		if int(p.id) == id: return p
	return {}

func _drive(delta: float) -> void:
	car.global_position += dir * speed * delta

func _physics_process(delta: float) -> bool:
	if crowd == null: return true
	t += delta
	if car != null and speed > 0.0: _drive(delta)
	match step:
		0:
			if t < 6.0: return false
			for p: Dictionary in crowd.call(&"people_near", Vector3(0, 0, -620), 200.0):
				if int(p.mode) == 0 and int(p.state) == 0 and int(p.party) == 0 and float(p.speed) > 0.9:
					spot = p.at; dir = Vector3(sin(float(p.yaw)), 0, cos(float(p.yaw))); break
			if spot == Vector3.ZERO: _check(false, "no walker on a pavement within 200 m of the centre"); step = 9; return false
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			var cam: Camera3D = root.get_viewport().get_camera_3d()
			cam.look_at_from_position(spot + Vector3(-dir.z, 0, dir.x) * 6.0 + Vector3(0, 3, 0), spot, Vector3.UP)
			car = Node3D.new(); root.add_child(car)
			car.global_position = spot - dir * 45.0; car.rotation.y = atan2(dir.x, dir.z)
			crowd.call(&"set_player_car", car, 2.3, 1.0)
			dodges0 = int(crowd.call(&"stats").dodges)
			speed = 8.3      # 30 km/h along the pavement
			step = 1; t0 = t
		1:
			if t - t0 < 9.0: return false
			var st: Dictionary = crowd.call(&"stats")
			_check(int(st.dodges) > dodges0, "the car comes down the pavement at 30 km/h for 75 m: %d people jump out of its way" % (int(st.dodges) - dodges0))
			# 2) somebody who cannot jump: held where he stands, the camera beside him
			speed = 0.0
			car.global_position = spot - dir * 30.0
			held = int(crowd.call(&"place_walker", spot, 8181))
			step = 2; t0 = t
		2:
			if t - t0 < 1.2: return false      # (a moment for his animated body to be his)
			var p := _person(held)
			crowd.call(&"hold", held, true, float(p.yaw))
			from = p.at
			dir = ((p.at as Vector3) - car.global_position); dir.y = 0; dir = dir.normalized()
			car.rotation.y = atan2(dir.x, dir.z)
			speed = 7.0      # 25 km/h, straight at him
			step = 3; t0 = t
		3:
			for nb: Dictionary in crowd.call(&"near_bodies"):
				if int(nb.walker) != held: continue
				if int(nb.figure_mode) == 1:
					was_body = true
					lowest = minf(lowest, (nb.at as Vector3).y - from.y)
				if was_body and int(nb.figure_mode) == 2: was_down = true      # (he gets up: he was down)
			if speed > 0.0 and car.global_position.distance_to(from) > 25.0 and car.global_position.dot(dir) > from.dot(dir): speed = 0.0; car.global_position += dir * 200.0      # (the car has gone)
			var p := _person(held)
			var back: bool = was_body and not p.is_empty() and int(p.mode) == 0
			if not back and t - t0 < 30.0: return false
			_check(was_body, "the car reaches somebody who cannot jump: his body is handed to the balancing body")
			_check(lowest < 0.5 and was_down, "the car knocks him over (his hips %.2f m over the ground at the lowest), he lies, and gets up" % lowest)
			_check(back, "and he walks back to the pavement (%.0f s after the car set off; %.1f m from where he stood)" % [t - t0, (p.at as Vector3).distance_to(from) if not p.is_empty() else -1.0])
			var st: Dictionary = crowd.call(&"stats")
			_check(int(st.alarms_car_hit) >= 1 and int(st.fled) + int(st.stared) + int(st.ducked) > 0, "the street reacts to the hit (B31): %d alarm(s); %d ran, %d stared / filmed / called, %d ducked" % [int(st.alarms_car_hit), int(st.fled), int(st.stared), int(st.ducked)])
			_check(int(st.bad_numbers) == 0, "no bad number")
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
