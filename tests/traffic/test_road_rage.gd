extends SceneTree
## Road rage (C++: CityTraffic knocks and drivers out, CityCrowd's ragers and the player's fight; Yasin: "once collided,
## the driver should get out and attack us, unless its a parked car of course, then no one gets out, but if a moving car
## is hit by us first they should get off, then yell and get angry, then attack us, putting us in combat mode, also
## whenever there is an aggressor in the screen, we should get into the combat mode"). In a window, to watch:
##   godot --path . --rendering-method mobile --resolution 1280x720 -s res://tests/traffic/test_road_rage.gd [-- --at=x,z]
## The real streets, traffic and crowd on a flat test ground. Part 1: the player's car into a parked car: nobody gets out.
## Part 2: head-on into a moving car: its driver gets out (a person at its door), yells; while the player sits in his
## car nothing more; the player gets out beside his car: he is put in combat, locked on that driver, who attacks.
var traffic: Node3D
var crowd: Node3D
var player: CharacterBody3D
var car: Node3D
var cam: Camera3D
var ground: StaticBody3D
var label: Label
var at := Vector3(-600, 0, -1000)
var t := 0.0
var phase := 0
var t0 := 0.0
var fails := 0
var target := {}
var spot := Vector3.ZERO
var k0 := {}
var rager := -1
var tries := 0
var part := 2
var dist0 := 0.0

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var f := a.trim_prefix("--at=").split_floats(","); at = Vector3(f[0], 0, f[1])
	RenderingServer.global_shader_parameter_add(&"refl_env", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.0))
	cam = Camera3D.new(); cam.position = at + Vector3(0, 40, 0); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.88); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.62)
	root.add_child(env)
	traffic = ClassDB.instantiate(&"CityTraffic")
	traffic.set(&"max_cars", 60); traffic.set(&"parked", true)
	root.add_child(traffic)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 60); crowd.set(&"hour", 12.5)
	root.add_child(crowd)
	crowd.call(&"set_traffic", traffic)
	player = ClassDB.instantiate(&"CityPlayer")
	player.position = at + Vector3(0, 0.1, 0)
	_lay_ground(0.0, at)   # (ground under him from the first frame; laid again where the cars are)
	root.add_child(player)
	player.call(&"set_riding", true)   # (in his car)
	crowd.call(&"set_player", player)
	var cl := CanvasLayer.new(); root.add_child(cl)
	label = Label.new(); label.position = Vector2(20, 16); label.add_theme_font_size_override("font_size", 24); cl.add_child(label)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("RAGE    %s: %s" % ["ok" if ok else "FAIL", what])

func _lay_ground(y: float, c: Vector3) -> void:
	if ground: ground.queue_free()
	ground = StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(600, 2, 600); cs.shape = sh; ground.add_child(cs); ground.position = Vector3(c.x, y - 1.0, c.z)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.36, 0.36, 0.38); mi.material_override = m; ground.add_child(mi)
	root.add_child(ground)

func _set_car(p: Vector3, yaw: float, speed: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	if car == null:
		car = ClassDB.instantiate(&"CityCar")
		car.set(&"model", 2); car.set(&"wheel_mask", 0xFFFFFFEF)
		car.transform = Transform3D(b, p)
		root.add_child(car)
		traffic.call(&"set_player_car", car, 2.14, 0.94)
	car.call(&"launch", Transform3D(b, p), b.z * speed)

func _process(_delta: float) -> bool:
	if cam == null: return false
	cam.current = true   # (the player node makes its own camera current: this test's camera watches instead)
	var c: Vector3 = car.global_position if car else at
	if phase >= 3 and player.visible: c = player.global_position
	var fs: Dictionary = crowd.call(&"fight_stats")
	var ks: Dictionary = traffic.call(&"knock_stats")
	if label: label.text = "drivers out %d   ragers %d   combat %s   blows at you %d" % [int(ks.get("drivers_out", 0)), (fs.ragers as Array).size(), str(player.call(&"get_combat")), int(fs.attacks)]
	# (until the hit, straight over the car as test_knock does: the traffic gives physical bodies to the cars round the
	# camera; then from the side, to watch the driver)
	if phase <= 3 and int((traffic.call(&"knock_stats") as Dictionary).drivers_out) == int(k0.get("drivers_out", 0)): cam.global_position = c + Vector3(0, 14, 0); cam.rotation_degrees = Vector3(-90, 0, 0)
	else: cam.look_at_from_position(c + Vector3(7, 6, 7), c + Vector3(0, 0.8, 0), Vector3.UP)
	return false

func _rager_at() -> Vector3:
	for p: Dictionary in crowd.call(&"people_near", spot, 80.0):
		if int(p.id) == rager: return p.at
	return Vector3.INF

func _physics_process(delta: float) -> bool:
	t += delta
	match phase:
		0:      # the traffic fills the streets; part 1: a parked car
			if t < 20.0: return false
			var stalls: Array = traffic.call(&"stalls_near", at, 160.0)
			var best := {}; var best_d := 1.0e9
			for q: Dictionary in stalls:
				if not bool(q.kerb): continue
				var d := (q.at as Vector3).distance_to(at)
				if d < best_d: best_d = d; best = q
			if best.is_empty(): _check(false, "no parked car near"); phase = 9; return false
			target = best; spot = target.at
			_lay_ground(spot.y, spot)
			var yaw := float(target.yaw)
			var fwd := Vector3(sin(yaw), 0, cos(yaw)); var left := Vector3(fwd.z, 0, -fwd.x)
			var side := 1.0
			for c: Dictionary in traffic.call(&"cars_near", spot, 40.0): side = signf(((c.at as Vector3) - spot).dot(left)); break
			var from := spot - fwd * 9.0 + left * side * 9.0
			var dir := (spot - from).normalized()
			k0 = traffic.call(&"knock_stats")
			_set_car(Vector3(from.x, spot.y + 0.05, from.z), atan2(dir.x, dir.z), 11.0)
			car.call(&"set_controls", 0.6, 0.0, 0.0, 0.0, false)
			phase = 1; t0 = t
		1:
			if t - t0 > 2.5: car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
			if t - t0 < 7.0: return false
			var s: Dictionary = traffic.call(&"knock_stats")
			_check(int(s.parked) > int(k0.parked), "part 1: the parked car was knocked (%d)" % (int(s.parked) - int(k0.parked)))
			_check(int(s.drivers_out) == int(k0.drivers_out), "a parked car: nobody gets out (%d drivers out)" % (int(s.drivers_out) - int(k0.drivers_out)))
			phase = 2; t0 = t
		2:      # part 2: head-on into a moving car
			var best := {}; var best_d := 1.0e9
			for c: Dictionary in traffic.call(&"cars_near", car.global_position, 200.0):
				var d := (c.at as Vector3).distance_to(car.global_position)
				if float(c.speed) > 5.0 and d > 50.0 and d < best_d: best_d = d; best = c
			if best.is_empty():
				if t - t0 > 60.0: _check(false, "no moving car to hit"); phase = 9
				return false
			var p: Vector3 = best.at
			var yaw := float(best.yaw)
			var fwd := Vector3(sin(yaw), 0, cos(yaw))
			_lay_ground(p.y, p); spot = p
			k0 = traffic.call(&"knock_stats")
			var from := p + fwd * 16.0
			_set_car(Vector3(from.x, p.y + 0.05, from.z), yaw + PI, 12.0)
			car.call(&"set_controls", 0.7, 0.0, 0.0, 0.0, false)
			print("RAGE part 2: head-on into moving car %d at (%.1f, %.1f)" % [int(best.id), p.x, p.z])
			phase = 3; t0 = t
		3:      # its driver gets out and yells; the player is still in his car
			if t - t0 > 2.0: car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
			var fs: Dictionary = crowd.call(&"fight_stats")
			var s0: Dictionary = traffic.call(&"knock_stats")
			if int(s0.moving) == int(k0.moving) and t - t0 > 6.0 and tries < 3:   # the head-on missed (he steered round): another car
				tries += 1; print("RAGE   (missed, try %d)" % (tries + 1)); phase = 2; t0 = t; return false
			if (fs.ragers as Array).is_empty() and t - t0 < 15.0: return false
			var s: Dictionary = traffic.call(&"knock_stats")
			_check(int(s.drivers_out) > int(k0.drivers_out) and int(fs.rages) >= 1, "the hit car's driver got out (%.1f s after the hit), a person at its door" % (t - t0))
			for c: Dictionary in s.out: print("RAGE      knocked car: parked %s, still %.1f s, upright %.2f, at %s" % [str(c.parked), float(c.still_s), float(c.up), str(c.at)])
			print("RAGE      knocks: moving %d parked %d drivers out %d" % [int(s.moving), int(s.parked), int(s.drivers_out)])
			if (fs.ragers as Array).is_empty(): phase = 9; return false
			for r: Dictionary in fs.ragers: if int(r.foe) == -1: rager = int(r.walker)
			_check(rager >= 0, "he is going for the player (the one who hit him)")
			phase = 4; t0 = t
		4:      # he yells; the player stays in his car
			if t - t0 < 4.0: return false
			var fs: Dictionary = crowd.call(&"fight_stats")
			_check(int(fs.rage_fights) == 0 and not bool(player.call(&"get_combat")), "the player stays in his car: no fight, he is not taken out (the driver stands by and yells)")
			if part == 2:   # part 2: a hit and run: the player drives 80 m off
				var cb := (car as Node3D).global_basis
				_set_car((car as Node3D).global_position + cb.z * 80.0, atan2(cb.z.x, cb.z.z), 0.0)
				car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
				phase = 41; t0 = t; return false
			# part 3: the player gets out 15 m from the angry driver
			var ra := _rager_at()
			var away := ((car as Node3D).global_position - ra); away.y = 0.0
			player.call(&"set_riding", false)
			player.global_position = ra + away.normalized() * 15.0 + Vector3(0, 0.3, 0)
			phase = 5; t0 = t; dist0 = 15.0
		41:
			var fs: Dictionary = crowd.call(&"fight_stats")
			if int(fs.rage_given_up) == 0 and t - t0 < 12.0: return false
			_check(int(fs.rage_given_up) >= 1 and int(fs.rage_fights) == 0, "a hit and run: the player drove off, the driver gave up (%.1f s)" % (t - t0))
			part = 3; phase = 2; t0 = t; rager = -1
		5:      # he runs after the player and the fight starts when he reaches him
			var fs: Dictionary = crowd.call(&"fight_stats")
			if not bool(player.call(&"get_combat")) and t - t0 < 10.0: return false
			_check(int(fs.rage_chases) >= 1, "the player on foot: the angry driver ran after him (15 m)")
			_check(bool(player.call(&"get_combat")) and int(fs.walker) == rager, "he reached him: the player is in combat, locked on him (%.1f s after getting out)" % (t - t0))
			phase = 6; t0 = t
		6:      # he attacks
			var fs: Dictionary = crowd.call(&"fight_stats")
			if int(fs.attacks) == 0 and t - t0 < 12.0: return false
			_check(int(fs.attacks) >= 1, "he attacks: %d blows at the player (%d landed) in %.1f s" % [int(fs.attacks), int(fs.hits_on_player), t - t0])
			phase = 7; t0 = t
		7:
			if t - t0 < 3.0: return false
			phase = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
