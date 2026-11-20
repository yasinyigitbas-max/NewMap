extends SceneTree
## The law (Yasin, 20 Nov, his GTA IV list: "police on foot or in cars, wanted level, chases", "paramedics come to the
## injured", "emergency vehicles with sirens", "small crimes by NPCs (mugging, police chasing them)"), headless:
##   godot --headless --path . -s res://tests/traffic/test_law.gd [-- --at=x,z]
## The traffic, the crowd, the player on a pavement (a flat floor at its height) and CityLaw.
##  1) Somebody near him is knocked down hard: he stays down; an ambulance comes (siren, lights), two paramedics kneel by
##     him, he gets up, they go.
##  2) Two stars: police cars come with lights and sirens, pull over by him, officers get out and run to him: BUSTED.
##  3) A mugging near him: the mugger runs, a police car comes for him and an officer runs him down.
var traffic: Node3D
var crowd: Node3D
var law: Node
var player: CharacterBody3D
var cam: Camera3D
var ground: StaticBody3D
var at := Vector3(-600, 0, -1000)
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var spot := Vector3.ZERO
var victim := -1
var seen_amb := {}
var seen_pol := {}

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var f := a.trim_prefix("--at=").split_floats(","); at = Vector3(f[0], 0, f[1])
	if not ClassDB.class_exists(&"CityLaw"):
		print("LAW ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	RenderingServer.global_shader_parameter_add(&"refl_env", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.0))
	cam = Camera3D.new(); cam.position = at + Vector3(0, 40, 0); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true
	traffic = ClassDB.instantiate(&"CityTraffic")
	traffic.set(&"max_cars", 50); traffic.set(&"parked", false)
	root.add_child(traffic)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 300); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 18)
	root.add_child(crowd)
	crowd.call(&"set_traffic", traffic)
	law = ClassDB.instantiate(&"CityLaw")
	law.set(&"crimes", false)
	root.add_child(law)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("LAW     %s: %s" % ["ok" if ok else "FAIL", what])

func _watch() -> void:
	for u: Dictionary in law.call(&"units_info"):
		var d: Dictionary = seen_amb if String(u.kind) == "ambulance" else seen_pol
		d[String(u.state)] = true
		if bool(u.lit): d["lit"] = true
		if int(u.siren) >= 0: d["siren"] = true

func _physics_process(delta: float) -> bool:
	t += delta
	if player != null:
		cam.global_position = player.global_position + Vector3(0, 30, 6)
		cam.look_at(player.global_position, Vector3.UP)
	_watch()
	match step:
		0:      # the player on a busy pavement
			if t < 6.0: return false
			var pv: Dictionary = crowd.call(&"pavement_near", at, 300.0)
			if not bool(pv.get("ok", false)): _check(false, "no pavement near (%.0f, %.0f)" % [at.x, at.z]); step = 9; return false
			spot = pv.at
			ground = StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(600, 2, 600); cs.shape = sh; ground.add_child(cs); ground.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(ground)
			player = ClassDB.instantiate(&"CityPlayer"); root.add_child(player)
			player.global_position = spot + Vector3(0, 0.1, 0)
			crowd.call(&"set_player", player)
			law.call(&"set_world", crowd, traffic, player)
			step = 1; t0 = t
		1:      # somebody near is knocked down hard
			if t - t0 < 3.0: return false
			for nb: Dictionary in crowd.call(&"near_bodies"):
				if int(nb.figure_mode) == 0 and int(nb.mode) == 0 and (nb.at as Vector3).distance_to(spot) < 30.0:
					if bool(crowd.call(&"knock_down_walker", int(nb.walker))): victim = int(nb.walker); break
			if victim < 0:
				if t - t0 > 20.0: _check(false, "nobody near to knock down"); step = 9
				return false
			print("LAW     somebody (%d) knocked down hard by the player" % victim)
			step = 2; t0 = t
		2:
			var st: Dictionary = law.call(&"stats")
			if int((t - t0) / 5.0) != int((t - t0 - delta) / 5.0):
				var us := []
				for u: Dictionary in law.call(&"units_info"):
					if String(u.kind) == "ambulance": us.append("%s car %d at %.0f m speed %.1f crew %s" % [String(u.state), int(u.car), (u.at as Vector3).distance_to(spot), float(u.speed), str(u.crew)])
				print("LAW       t+%.0f down %s, downs %s, ambulances %s" % [t - t0, str(crowd.call(&"is_down", victim)), str((crowd.call(&"downs_list") as Array).size()), str(us)])
			if int(st.treated) == 0 and t - t0 < 150.0: return false
			_check(int(st.ambulances) >= 1, "an ambulance was sent (%d)" % int(st.ambulances))
			_check(seen_amb.has("drive") and seen_amb.has("lit") and seen_amb.has("siren"), "it came with lights and its siren (%s)" % str(seen_amb.keys()))
			_check(seen_amb.has("treat"), "it stopped and the paramedics got out to him")
			_check(int(st.treated) >= 1, "he was treated (%.0f s after the knock)" % (t - t0))
			step = 3; t0 = t
		3:
			if t - t0 < 4.0: return false
			_check(not bool(crowd.call(&"is_down", victim)), "and he is up")
			# 2) two stars
			law.call(&"set_wanted", 2)
			step = 4; t0 = t
		4:
			var st: Dictionary = law.call(&"stats")
			if int(st.busted) == 0 and t - t0 < 150.0: return false
			_check(int(st.police_cars) >= 2, "two stars: police cars sent (%d)" % int(st.police_cars))
			_check(seen_pol.has("lit") and seen_pol.has("siren"), "with lights and sirens (%s)" % str(seen_pol.keys()))
			_check(int(st.officers_out) >= 1 and seen_pol.has("foot"), "officers got out and ran to him (%d out)" % int(st.officers_out))
			_check(int(st.busted) == 1, "BUSTED (%.0f s after the stars)" % (t - t0))
			step = 5; t0 = t
		5:
			if t - t0 < 5.0: return false
			_check(int(law.call(&"get_wanted")) == 0 and not bool(player.call(&"is_frozen")), "the stars are gone and he is free again")
			law.call(&"mug_now")
			law.set(&"crimes", true)
			step = 6; t0 = t
		6:
			var st: Dictionary = law.call(&"stats")
			if int(st.muggers_caught) == 0 and t - t0 < 150.0: return false
			_check(int(st.muggings) >= 1, "a mugging near him (%d)" % int(st.muggings))
			_check(int(st.police_cars) >= 3, "a police car came for the mugger")
			_check(int(st.muggers_caught) >= 1, "an officer ran the mugger down (%.0f s)" % (t - t0))
			var cs: Dictionary = crowd.call(&"stats")
			_check(int(cs.bad_numbers) == 0, "no bad number in the crowd")
			step = 9
		9:
			print("LAW     stats %s" % str(law.call(&"stats")))
			print("LAW     the traffic made way for sirens %d times (car-steps)" % int((traffic.call(&"knock_stats") as Dictionary).get("yields", 0)))
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
