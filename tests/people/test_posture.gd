extends SceneTree
## Everyone's shoulders forward (C++: Posture, the first modifier on every CityPed figure; Yasin, 20 Nov: "everyones
## shoulders are too far back, push all of them both player and npcs shoulders forward"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/people/test_posture.gd
## Checks: the player's posture is OFF (21 Nov 23:19: his idles and walks play as the mocap has them); the crowd's near
## people have it (shoulders forward).
var player: CharacterBody3D
var crowd: Node3D
var cam: Camera3D
var t := 0.0
var step := 0
var fails := 0

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("POSTURE %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(40, 2, 40); cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; b.add_child(mi); b.position = Vector3(0, -1, 0); root.add_child(b)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 60, 0); root.add_child(sun)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)
	cam = Camera3D.new(); root.add_child(cam)
	crowd = ClassDB.instantiate(&"CityCrowd"); crowd.set(&"max_people", 120); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 6); root.add_child(crowd)

func _postures(n: Node) -> Array:
	return n.find_children("*", "Posture", true, false)

func _physics_process(delta: float) -> bool:
	t += delta
	cam.current = true
	var at := player.global_position
	cam.look_at_from_position(at + Vector3(2.6, 1.3, 0.0), at + Vector3(0, 1.15, 0), Vector3.UP)   # (from his side: he faces +z)
	if t < 2.0: return false
	var ps := _postures(player)
	match step:
		0:
			# (Yasin, 21 Nov 23:19: the player's mocap plays untouched: his figure's posture is off; the crowd keeps it)
			_check(ps.size() == 1 and not bool((ps[0] as Node).get(&"active")), "the player's posture is off (his shoulders as the mocap has them)")
			step = 3
		1:
			if t < 2.5: return false
			root.get_texture().get_image().save_png("res://OUT/posture_before.png")
			(ps[0] as Node).set(&"angle", 0.21); step = 2
		2:
			if t < 3.0: return false
			root.get_texture().get_image().save_png("res://OUT/posture_after.png")
			var mv := float((ps[0] as Node).call(&"get_moved"))
			_check(mv > 0.02 and mv < 0.06, "the shoulder joints came forward %.3f m" % mv)
			step = 3
		3:
			if t < 9.0: return false
			var n := _postures(crowd).size()
			var movs := []
			for p: Node in _postures(crowd): movs.append("%.3f" % float(p.call(&"get_moved")))
			_check(n > 0, "the crowd's near people have it: %d figures, shoulders forward %s m" % [n, ", ".join(movs)])
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
