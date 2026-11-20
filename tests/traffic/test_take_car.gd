extends SceneTree
## Taking a car from its driver (Yasin, 20 Nov, his GTA IV list: "driver reacts when you take their car"), headless:
##   godot --headless --path . -s res://tests/traffic/test_take_car.gd [-- --at=x,z]
## The traffic, the crowd and the player on a flat floor at the road's height. 1) A car standing at a light: the player
## takes it (CityTraffic::take_car, the HUD's TAKE CAR): it becomes a physical car, its driver gets out and RUNS, the
## player gets in and has the wheel; the law hears of it (incident 7). 2) Another: this driver gets out to FIGHT (road
## rage: he goes for the player).
var traffic: Node3D
var crowd: Node3D
var player: CharacterBody3D
var cam: Camera3D
var ground: StaticBody3D
var at := Vector3(-600, 0, -1000)
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var taken: RigidBody3D
var robbed0 := 0
var rages0 := 0
var round := 0

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var f := a.trim_prefix("--at=").split_floats(","); at = Vector3(f[0], 0, f[1])
	if not ClassDB.class_exists(&"CityTraffic") or not ClassDB.class_exists(&"CityCrowd"):
		print("TAKE ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	RenderingServer.global_shader_parameter_add(&"refl_env", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.0))
	cam = Camera3D.new(); cam.position = at + Vector3(0, 40, 0); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true
	traffic = ClassDB.instantiate(&"CityTraffic")
	traffic.set(&"max_cars", 80); traffic.set(&"parked", false)
	root.add_child(traffic)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 150); crowd.set(&"hour", 12.5)
	root.add_child(crowd)
	crowd.call(&"set_traffic", traffic)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("TAKE    %s: %s" % ["ok" if ok else "FAIL", what])

func _lay_ground(c: Vector3) -> void:
	if ground: ground.queue_free()
	ground = StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(400, 2, 400); cs.shape = sh; ground.add_child(cs); ground.position = Vector3(c.x, c.y - 1.0, c.z); root.add_child(ground)

func _find() -> Dictionary:
	# (car_to_take looks only at cars within 2.5 m of the asker's height: one standing car's height is the asker's)
	for c: Dictionary in traffic.call(&"cars_near", at, 300.0):
		if int(c.kind) != 0 or absf(float(c.speed)) > 0.3: continue
		var id: int = traffic.call(&"car_to_take", c.at, 0.5, 0.3)
		if id == int(c.id): return c
	return {}

func _physics_process(delta: float) -> bool:
	t += delta
	match step:
		0:      # a car standing (a red light, a queue)
			if t < 8.0: return false
			var c := _find()
			if c.is_empty():
				if t > 90.0: _check(false, "no car standing within 300 m in 90 s"); step = 9
				return false
			var p: Vector3 = c.at
			var yaw: float = float(c.get("yaw", 0.0))
			_lay_ground(p)
			cam.global_position = p + Vector3(0, 30, 0)
			if player == null:
				player = ClassDB.instantiate(&"CityPlayer"); root.add_child(player)
				crowd.call(&"set_player", player)
			var side := Vector3(cos(yaw), 0, -sin(yaw))      # (the car's +x: the driver's side)
			player.global_position = p + side * 2.0 + Vector3(0, 0.1, 0)
			var near_id: int = traffic.call(&"car_to_take", player.global_position, 1.3, 0.3)
			_check(near_id == int(c.id), "by its door, the HUD would offer TAKE CAR (the car in reach: %d, wanted %d)" % [near_id, int(c.id)])
			var st: Dictionary = crowd.call(&"stats")
			robbed0 = int(st.get("drivers_robbed", 0)); rages0 = int((crowd.call(&"fight_stats") as Dictionary).rages)
			taken = traffic.call(&"take_car", int(c.id), round == 1)
			_check(taken != null and taken.is_in_group(&"vehicles"), "round %d (%s): the car is taken: a physical car, his to drive" % [round + 1, "the driver fights" if round == 1 else "the driver runs"])
			if taken == null: step = 9; return false
			print("TAKE      taken: at %s (the row at %s), visible %s, frozen %s" % [str(taken.global_position), str(p), str(taken.visible), str(taken.freeze)])
			_check(bool(taken.call(&"enter", player)), "the player goes to get in")
			traffic.call(&"set_player_car", taken, 2.2, 0.95)
			step = 1; t0 = t
		1:
			if not bool(taken.call(&"is_seated")):
				if int((t - t0) * 2.0) != int((t - t0 - delta) * 2.0):
					print("TAKE      t+%.1f entry state %d, player %s, car %s, car speed %.2f" % [t - t0, int(taken.call(&"get_entry_state")), str(player.global_position), str(taken.global_position), taken.linear_velocity.length()])
				if t - t0 > 25.0: _check(false, "seated within 25 s"); step = 9
				return false
			_check(bool(taken.call(&"get_player")), "seated after %.1f s: the wheel is his" % (t - t0))
			step = 2; t0 = t
		2:
			if t - t0 < 3.0: return false
			var st: Dictionary = crowd.call(&"stats")
			var fs: Dictionary = crowd.call(&"fight_stats")
			if round == 0:
				_check(int(st.drivers_robbed) == robbed0 + 1, "the driver got out and ran (%d)" % (int(st.drivers_robbed) - robbed0))
				var inc: Array = crowd.call(&"take_incidents")
				var seven := false
				for e: Dictionary in inc: if int(e.kind) == 7 and bool(e.by_player): seven = true
				_check(seven, "the law hears of it: a car taken, by the player")
			else:
				_check(int(fs.rages) == rages0 + 1, "the driver got out to go for the player (road rage: %d)" % (int(fs.rages) - rages0))
			# the player out again and away from it for the next round
			taken.call(&"leave")
			step = 3; t0 = t
		3:
			if int(taken.call(&"get_entry_state")) != 0 and t - t0 < 15.0: return false
			traffic.call(&"set_player_car", null, 0.0, 0.0)
			round += 1
			if round >= 2: step = 9; return false
			player.global_position += Vector3(0, 0, 0)
			step = 0; t = 8.0
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
