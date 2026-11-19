extends SceneTree
## A car of the traffic that is hit becomes a physical car (C++: CityTraffic::knock, CityCar), headless:
##   godot --headless --path . -s res://tests/traffic/test_knock.gd [-- --at=x,z]
## (in real time, about a minute: the traffic steps on its own thread by the clock, so no --fixed-fps here)
## The real streets and the real traffic, on a flat test ground laid at the height of the car that is to be hit (the
## city's own ground is not loaded here). Part 1: the player's car is driven into a parked car. Part 2: it is driven
## head-on into a moving car. Each must stop being a row / a stall and become a physical car that is shoved, with no
## wild numbers; what the driver of the moving one does afterwards (drives on, or stays) is printed.
## This script only sets things up and reads the counts: every decision and every force is C++.
var traffic: Node3D
var car: Node3D
var cam: Camera3D
var ground: StaticBody3D
var at := Vector3(-600, 0, -1000)
var t := 0.0
var phase := 0
var t0 := 0.0
var fails := 0
var target := {}
var gy := 0.0
var k0 := {}
var hit_dented := 0
var k_hit := {}   # the counts as the head-on knock begins: its driver may drive on during part 2 already
var far_most := 0.0
var speed_most := 0.0
var spot := Vector3.ZERO

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var f := a.trim_prefix("--at=").split_floats(","); at = Vector3(f[0], 0, f[1])
	if not ClassDB.class_exists(&"CityTraffic") or not ClassDB.class_exists(&"CityCar"):
		print("KNOCK ERROR the native module is not built: run  bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	RenderingServer.global_shader_parameter_add(&"refl_env", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.0))
	cam = Camera3D.new(); cam.position = at + Vector3(0, 40, 0); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true
	traffic = ClassDB.instantiate(&"CityTraffic")
	traffic.set(&"max_cars", 60); traffic.set(&"parked", true)
	root.add_child(traffic)
	print("KNOCK test round (%.0f, %.0f), physics engine '%s'" % [at.x, at.z, String(ProjectSettings.get_setting_with_override("physics/3d/physics_engine"))])

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("KNOCK   %s: %s" % ["ok" if ok else "FAIL", what])

func _lay_ground(y: float, c: Vector3) -> void:
	if ground: ground.queue_free()
	ground = StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(600, 2, 600); cs.shape = sh; ground.add_child(cs); ground.position = Vector3(c.x, y - 1.0, c.z); root.add_child(ground)
	gy = y

func _set_car(p: Vector3, yaw: float, speed: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	if car == null:
		car = ClassDB.instantiate(&"CityCar")
		car.set(&"model", 2); car.set(&"wheel_mask", 0xFFFFFFEF)
		car.transform = Transform3D(b, p)
		root.add_child(car)
		traffic.call(&"set_player_car", car, 2.14, 0.94)
	car.call(&"launch", Transform3D(b, p), b.z * speed)

func _watch() -> void:
	var s: Dictionary = traffic.call(&"knock_stats")
	for c: Dictionary in s.out:
		speed_most = maxf(speed_most, float(c.speed))
		far_most = maxf(far_most, absf((c.at as Vector3).y - gy))

func _process(_delta: float) -> bool:      # the camera stays over the car: the traffic gives boxes to the cars near the camera
	if car != null and cam != null: cam.global_position = car.global_position + Vector3(0, 14, 0)
	return false

func _physics_process(delta: float) -> bool:
	if traffic == null: return true
	t += delta
	match phase:
		0:      # let the traffic fill the streets, then choose a parked car on level kerb
			if t < 20.0: return false
			var stalls: Array = traffic.call(&"stalls_near", at, 160.0)
			var best := {}; var best_d := 1.0e9
			for q: Dictionary in stalls:
				if not bool(q.kerb): continue
				var level := true
				for o: Dictionary in stalls:
					if (o.at as Vector3).distance_to(q.at) < 30.0 and absf((o.at as Vector3).y - (q.at as Vector3).y) > 0.05: level = false
				var d := (q.at as Vector3).distance_to(at)
				if level and d < best_d: best_d = d; best = q
			if best.is_empty():
				_check(false, "no parked car on level kerb within 160 m of (%.0f, %.0f): choose another place with --at=x,z (%d parked cars there)" % [at.x, at.z, stalls.size()])
				phase = 9; return false
			target = best; spot = target.at
			_lay_ground(spot.y, spot)
			# from the lane side, 45 degrees onto its flank: no other parked car in the way
			var yaw := float(target.yaw)
			var fwd := Vector3(sin(yaw), 0, cos(yaw)); var left := Vector3(fwd.z, 0, -fwd.x)
			var side := 1.0      # which side the lane is on: where a moving car is, else try the left
			for c: Dictionary in traffic.call(&"cars_near", spot, 40.0):
				side = signf(((c.at as Vector3) - spot).dot(left)); break
			var from := spot - fwd * 9.0 + left * side * 9.0
			var dir := (spot - from).normalized()
			k0 = traffic.call(&"knock_stats")
			_set_car(Vector3(from.x, spot.y + 0.05, from.z), atan2(dir.x, dir.z), 11.0)
			car.call(&"set_controls", 0.6, 0.0, 0.0, 0.0, false)
			print("KNOCK part 1: into the parked car in stall %d at (%.1f, %.1f), from 12.7 m at 40 km/h (%d parked cars and %d moving within 160 m)" % [int(target.stall), spot.x, spot.z, stalls.size(), (traffic.call(&"cars_near", at, 160.0) as Array).size()])
			phase = 1; t0 = t; speed_most = 0.0; far_most = 0.0
		1:
			_watch()
			if t - t0 > 2.5: car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
			if t - t0 < 7.0: return false
			var s: Dictionary = traffic.call(&"knock_stats")
			var n := int(s.parked) - int(k0.parked)
			_check(n >= 1, "the parked car became a physical car (%d parked cars knocked loose, %d moving)" % [n, int(s.moving) - int(k0.moving)])
			var still_there := false
			for q: Dictionary in traffic.call(&"stalls_near", spot, 1.0):
				if int(q.stall) == int(target.stall): still_there = true
			_check(not still_there, "its stall is empty now")
			var moved := 0.0; var up := 1.0
			for c: Dictionary in s.out:
				if bool(c.parked): moved = maxf(moved, Vector2((c.at as Vector3).x - spot.x, (c.at as Vector3).z - spot.z).length()); up = minf(up, float(c.up))
			_check(moved > 0.3, "it was shoved: %.1f m from its stall" % moved)
			_check(speed_most < 40.0 and far_most < 4.0, "no wild numbers: fastest knocked car %.1f m/s, farthest from the ground's height %.2f m" % [speed_most, far_most])
			var cs: Dictionary = car.call(&"get_state")
			_check(float(cs.hardest_knock_g) > 1.0 and car.global_basis.y.y > 0.5, "the player's car felt it (%.0f g) and is on its wheels (%.2f)" % [float(cs.hardest_knock_g), car.global_basis.y.y])
			print("KNOCK   (the least upright knocked car: %.2f, 1 = on its wheels)" % up)
			phase = 2
		2:      # a moving car, head-on
			var best := {}; var best_d := 1.0e9
			for c: Dictionary in traffic.call(&"cars_near", at, 200.0):
				var d := (c.at as Vector3).distance_to(spot)
				if float(c.speed) > 5.0 and d > 60.0 and d < best_d: best_d = d; best = c
			if best.is_empty():
				if t - t0 > 60.0: _check(false, "no moving car to hit within 200 m in a minute"); phase = 9
				return false
			target = best
			var p: Vector3 = target.at
			var yaw := float(target.yaw)
			var fwd := Vector3(sin(yaw), 0, cos(yaw))
			_lay_ground(p.y, p)
			k0 = traffic.call(&"knock_stats")
			var from := p + fwd * 16.0
			_set_car(Vector3(from.x, p.y + 0.05, from.z), yaw + PI, 12.0)
			car.call(&"set_controls", 0.7, 0.0, 0.0, 0.0, false)
			print("KNOCK part 2: head-on into moving car %d at (%.1f, %.1f) doing %.0f km/h, from 16 m at 43 km/h" % [int(target.id), p.x, p.z, float(target.speed) * 3.6])
			phase = 3; t0 = t; speed_most = 0.0; far_most = 0.0; spot = p
			k_hit = traffic.call(&"knock_stats")
		3:
			_watch()
			if t - t0 > 2.0: car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
			if t - t0 < 14.0: return false
			var s: Dictionary = traffic.call(&"knock_stats")
			var n := int(s.moving) - int(k0.moving)
			_check(n >= 1, "the moving car became a physical car (%d moving cars knocked loose, %d parked)" % [n, int(s.parked) - int(k0.parked)])
			_check(speed_most < 40.0 and far_most < 4.0, "no wild numbers: fastest knocked car %.1f m/s, farthest from the ground's height %.2f m" % [speed_most, far_most])
			var cs: Dictionary = car.call(&"get_state")
			_check(car.global_basis.y.y > 0.5, "the player's car is on its wheels (%.2f), hardest knock %.0f g" % [car.global_basis.y.y, float(cs.hardest_knock_g)])
			print("KNOCK   afterwards: %d drove on as traffic, %d taken away, %d still lie there, %d times no physical car was free" % [int(s.rejoined) - int(k0.rejoined), int(s.taken_away) - int(k0.taken_away), (s.out as Array).size(), int(s.no_slot)])
			for c: Dictionary in s.out:
				var dm: Dictionary = c.damage
				print("KNOCK     lies at (%.1f, %.1f) %s, upright %.2f, still for %.1f s, %.1f m from where it was hit; damage: %d dents (deepest %.2f m), health %.2f, sound %s" % [(c.at as Vector3).x, (c.at as Vector3).z, "(was parked)" if bool(c.parked) else "(was moving)", float(c.up), float(c.still_s), Vector2((c.at as Vector3).x - spot.x, (c.at as Vector3).z - spot.z).length(), int(dm.dents), float(dm.deepest), float(dm.health), String(dm.last_sound)])
			var dented := 0
			for c: Dictionary in s.out: if int((c.damage as Dictionary).dents) > 0: dented += 1
			var pd: Dictionary = car.call(&"get_damage")
			_check(dented >= 1 and int(pd.dents) >= 1, "both cars are damaged (Yasin: \"every other car should get damaged too once collided\"): %d knocked car(s) dented; the player's car %d dents, health %.2f" % [dented, int(pd.dents), float(pd.health)])
			hit_dented = dented
			# part 3: the player's car gets out of its way (30 m to the side); its driver should drive on
			k0 = s
			var side := car.global_basis.x
			_set_car(car.global_position + Vector3(side.x, 0, side.z).normalized() * 30.0, atan2(car.global_basis.z.x, car.global_basis.z.z), 0.0)
			car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
			phase = 4; t0 = t
		4:
			var s: Dictionary = traffic.call(&"knock_stats")
			if int(s.rejoined) == int(k_hit.rejoined) and t - t0 < 10.0: return false
			if hit_dented > 0:   # a dented car stays a wreck (the traffic's rows have no dents): it must not drive on
				_check(int(s.rejoined) == int(k_hit.rejoined), "the dented car stays where it came to rest with its dents, 10 s on (it does not become an undented row again)")
				phase = 9; return false
			var why := {-1: "no lane within 3.6 m of it", -2: "it stands at a lane's end", -3: "it stands across the lane", -4: "the traffic is full", -5: "something stands in its way"}
			_check(int(s.rejoined) > int(k_hit.rejoined), "with the player's car out of the way (or before) the hit driver drives on, %.1f s later (%s)" % [t - t0, "it is a car of the traffic again" if int(s.rejoined) > int(k_hit.rejoined) else "refused: " + String(why.get(int(s.last_refusal), "never asked"))])
			phase = 9
		9:
			print("KNOCK traffic: %s" % String(traffic.call(&"report")))
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			traffic.queue_free(); traffic = null
			quit(1 if fails else 0)
			return true
	return false
