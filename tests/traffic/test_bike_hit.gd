extends SceneTree
## A cyclist of the traffic hit by a car (C++: the traffic core lets him come off, CityTraffic throws his bicycle, the
## crowd's balancing body takes the rider), in real time (the traffic steps on its own thread by the clock):
##   godot --headless --path . -s res://tests/traffic/test_bike_hit.gd
## The real streets over a flat floor at the cyclist's height. A "car" (a plain node this script moves; the traffic and
## the crowd are told it is the player's car) comes up behind a cyclist at 43 km/h and into him. PASS needs: he comes
## off (he leaves the traffic); his bicycle is thrown and ends lying on its side; the rider is one of the crowd now, his
## near body is thrown by the blow (his hips under 0.5 m over the floor), he lies, gets up, and walks to the pavement.
var traffic: Node3D
var crowd: Node3D
var car: Node3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var bike := -1
var floor_y := 0.0
var downs0 := 0
var rider := -1
var lowest := 9.0
var highest := -9.0
var was_body := false
var got_up := false
var hit_at := Vector3.ZERO

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("BIKEHIT   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityTraffic"):
		print("BIKEHIT ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	cam = Camera3D.new(); cam.position = Vector3(0, 30, -600); root.add_child(cam); cam.current = true
	traffic = ClassDB.instantiate(&"CityTraffic")
	traffic.set(&"max_cars", 8); traffic.set(&"parked", false); traffic.set(&"cyclists", 24); traffic.set(&"buses", false)
	root.add_child(traffic)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 60); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 12)
	root.add_child(crowd)
	crowd.call(&"set_traffic", traffic)
	car = Node3D.new(); car.position = Vector3(0, -500, 0); root.add_child(car)
	traffic.call(&"set_player_car", car, 2.3, 1.0)
	crowd.call(&"set_player_car", car, 2.3, 1.0)

func _bike() -> Dictionary:
	for c: Dictionary in traffic.call(&"cars_near", cam.global_position, 400.0):
		if int(c.id) == bike: return c
	return {}

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:      # a cyclist on the move: the floor under him, the camera beside him
			if t < 2.5: return false
			for c: Dictionary in traffic.call(&"cars_near", cam.global_position, 400.0):
				if bool(c.get("bike", false)) and float(c.speed) > 3.0: bike = int(c.id); break
			if bike < 0:
				if t > 40.0: _check(false, "no cyclist on the move came"); step = 9
				return false
			var b := _bike(); floor_y = (b.at as Vector3).y
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(1200, 2, 1200); cs.shape = sh; fl.add_child(cs); fl.position = Vector3((b.at as Vector3).x, floor_y - 1.0, (b.at as Vector3).z); root.add_child(fl)
			downs0 = int(traffic.call(&"bike_stats").down)
			step = 1; t0 = t
		1:      # the car comes up behind him at 43 km/h, aimed at him
			var b := _bike()
			var down := int(traffic.call(&"bike_stats").down) > downs0
			if b.is_empty() and not down:
				if t - t0 > 2.0: bike = -1; step = 0
				return false
			if not b.is_empty():
				var at: Vector3 = b.at; var f := Vector3(sin(float(b.yaw)), 0, cos(float(b.yaw)))
				cam.look_at_from_position(at + Vector3(f.z, 0, -f.x) * 9.0 + Vector3(0, 4, 0), at, Vector3.UP)
				if car.position.y < -100.0: car.global_position = at - f * 28.0; car.global_position.y = floor_y; car.rotation.y = atan2(f.x, f.z)
				var to := at - car.global_position; to.y = 0
				if to.length() > 0.1: car.rotation.y = atan2(to.x, to.z); car.global_position += to.normalized() * 12.0 * delta
				hit_at = at
			if down:
				_check(true, "the car reached him at 43 km/h: he came off (%d cyclists down)" % (int(traffic.call(&"bike_stats").down) - downs0))
				step = 2; t0 = t
				return false
			if t - t0 > 15.0: _check(false, "the car never reached a cyclist"); step = 9
		2:      # the car brakes; the rider and his bicycle
			if t - t0 < 1.2: car.global_position += car.global_basis.z * 12.0 * maxf(0.0, 1.0 - (t - t0) / 1.2) * delta
			for nb: Dictionary in crowd.call(&"near_bodies"):
				if int(nb.figure_mode) == 1 and (rider < 0 or int(nb.walker) == rider):
					rider = int(nb.walker); was_body = true
					lowest = minf(lowest, (nb.at as Vector3).y - floor_y)
					highest = maxf(highest, (nb.at as Vector3).y - floor_y)
				if int(nb.walker) == rider and was_body and int(nb.figure_mode) == 2: got_up = true
			var back := false
			if rider >= 0:
				for p: Dictionary in crowd.call(&"people_near", hit_at, 120.0):
					if int(p.id) == rider and int(p.mode) == 0: back = true
			if not back and t - t0 < 45.0: return false
			var st: Dictionary = crowd.call(&"stats")
			_check(int(st.riders_thrown) >= 1 and int(st.riders_given_a_body) >= 1, "the rider is one of the crowd now, given a near body at once (%d thrown, %d given a body)" % [int(st.riders_thrown), int(st.riders_given_a_body)])
			_check(was_body and lowest < 0.5, "the blow threw his balancing body down (his hips %.2f m over the floor at the lowest)" % lowest)
			_check(highest < 2.5, "he is scooped over the car, not propelled: his hips at most %.2f m over the floor" % highest)
			_check(got_up or back, "he got up (the get-up clip after his balancing body)")
			_check(back, "and walks to the pavement (%.0f s after the hit)" % (t - t0))
			var bs: Dictionary = traffic.call(&"bike_stats")
			var lying := false; var info := "no fallen bicycle"
			for fb: Dictionary in bs.fallen:
				info = "at %s, upright %.2f (1 = standing), %.2f m/s" % [str(fb.at), float(fb.up), float(fb.speed)]
				if float(fb.up) < 0.5 and float(fb.speed) < 0.3: lying = true
			_check(lying, "his bicycle was thrown and lies on its side: %s" % info)
			_check(int(st.bad_numbers) == 0, "no bad number")
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
