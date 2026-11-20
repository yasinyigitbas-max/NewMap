extends SceneTree
## The player and the people bump (C++: CityCrowd's capsules on the people near the player; Yasin, 20 Nov: "we can just
## pass thru npcs, their colliders are tiny i think"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/people/test_bump.gd
## A person held standing on the street; the player walks, then runs, straight into him. Checks: the player's centre never
## comes nearer the person's than their bodies allow (0.5 m), walking or running; one picture at the closest.
var crowd: Node3D
var player: CharacterBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var who := -1
var spot := Vector3.ZERO
var nearest := 9.0
var shot := false
var knocked := false

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("BUMP    %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	crowd = ClassDB.instantiate(&"CityCrowd"); crowd.set(&"max_people", 20); crowd.set(&"hour", 12.5); root.add_child(crowd)
	cam = Camera3D.new(); cam.position = Vector3(0, 30, -600); root.add_child(cam)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)

func _person() -> Vector3:
	for p: Dictionary in crowd.call(&"people_near", spot, 30.0):
		if int(p.id) == who: return p.at
	return Vector3.INF

func _physics_process(delta: float) -> bool:
	t += delta
	if cam: cam.current = true
	match step:
		0:
			if t < 2.0: return false
			who = int(crowd.call(&"place_walker", Vector3(0, 0, -600), 4242))
			spot = Vector3(0, 0, -600); spot = _person()
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(100, 2, 100); cs.shape = sh; fl.add_child(cs)
			var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi); fl.position = spot - Vector3(0, 1, 0); root.add_child(fl)
			crowd.call(&"hold", who, true, 0.0)
			player = ClassDB.instantiate(&"CityPlayer"); player.position = spot + Vector3(0, 0.05, -6.0); root.add_child(player)
			crowd.call(&"set_player", player)
			step = 1; t0 = t
		1:
			cam.current = true
			if t - t0 < 1.0: return false
			player.call(&"set_move", Vector2(0, 1), false)   # (walking, the view behind him: straight at the person, +z)
			step = 2; t0 = t; nearest = 9.0
		2, 4:
			cam.current = true
			var at := _person()
			var d := Vector2(player.global_position.x - at.x, player.global_position.z - at.z).length()
			# (while he stands: running, the player may knock him over, and then pass him lying there)
			if int((crowd.call(&"stats") as Dictionary).capsules_on) > 0 and d < nearest: nearest = d
			if int((crowd.call(&"stats") as Dictionary).capsules_on) == 0 and d < 0.6: knocked = true
			if OS.get_cmdline_user_args().has("--trace") and int(t * 10) != int((t - delta) * 10):
				var mode := -1
				for p: Dictionary in crowd.call(&"people_near", spot, 30.0): if int(p.id) == who: mode = int(p.mode)
				print("BUMP   t %.1f dist %.2f person mode %d capsules on %d" % [t - t0, d, mode, int((crowd.call(&"stats") as Dictionary).capsules_on)])
			cam.look_at_from_position(at + Vector3(3.0, 1.6, -1.0), (at + player.global_position) * 0.5 + Vector3(0, 0.9, 0), Vector3.UP)
			if t - t0 < 5.0: return false
			var cs: Dictionary = crowd.call(&"stats"); print("BUMP      capsules on %s, steps %s, extras %s, the crowd sees the player %s" % [str(cs.get("capsules_on")), str(cs.get("capsule_steps")), str(cs.get("extras")), str(cs.get("has_player"))])
			_check(nearest > 0.5, "%s into him: while he stands their centres at the nearest %.2f m apart (the bodies need 0.5 m)%s" % ["walking" if step == 2 else "running", nearest, ", and the run knocked him over" if knocked else ""])
			if step == 2:
				root.get_texture().get_image().save_png("res://OUT/bump_walk.png")
				player.global_position = spot + Vector3(0, 0.05, -8.0); player.velocity = Vector3.ZERO
				player.call(&"set_move", Vector2(0, 1), true)
				step = 4; t0 = t; nearest = 9.0; knocked = false; return false
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
