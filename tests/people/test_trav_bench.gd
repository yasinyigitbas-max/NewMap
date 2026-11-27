extends SceneTree
## The traversal player sits on a bench of the city (28 Nov; C++: CityCrowd::trav_benches, TravInteract's seat take),
## headless:  godot --headless --fixed-fps 60 --path . -s res://tests/people/test_trav_bench.gd
## The crowd's own places over a flat floor at a bench's height; he stands 1.6 m in front of the bench, the act key is
## pressed: he walks the last steps, sits (Interact.seated); the stick pushed, he gets up and walks off.
var crowd: Node3D
var player: Node3D
var t := 0.0
var step := 0
var fails := 0
var at := Vector3.ZERO
var t0 := 0.0
func _initialize() -> void:
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 60); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 12)
	root.add_child(crowd)
	var cam := Camera3D.new(); cam.position = Vector3(0, 40, -620); root.add_child(cam); cam.current = true
func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("BENCH  %s: %s" % ["ok" if ok else "FAIL", what])
func _physics_process(delta: float) -> bool:
	if crowd == null: return true
	t += delta
	match step:
		0:
			if t < 3.0: return false
			var place := -1
			for k in 4000:
				var d: Dictionary = crowd.call(&"place_info", k)
				if d.is_empty(): break
				if int(d.kind) == 6 and int(d.taken_by) < 0: place = k; at = d.at; set_meta("yaw", float(d.yaw)); break
			_check(place >= 0, "a free bench among the crowd's places (%d, at %s)" % [place, str(at)])
			if place < 0: step = 9; return false
			var f := Vector3(sin(float(get_meta("yaw"))), 0, cos(float(get_meta("yaw"))))
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(400, 2, 400); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(at.x, at.y - 1.0, at.z); root.add_child(fl)
			player = ClassDB.instantiate(&"CityPlayer"); player.position = at + f * 1.6 + Vector3(0, 0.05, 0); root.add_child(player)
			crowd.call(&"set_player", player)
			step = 1; t0 = t
		1:
			if t - t0 < 0.5: return false
			player.call(&"set_traversal", true)
			crowd.call(&"set_trav_people", true)
			step = 2; t0 = t
		2:
			if t - t0 < 2.5: return false
			player.call(&"set_use", true); step = 3; t0 = t
		3:
			if t - t0 > 0.3: player.call(&"set_use", false)
			var body: Node3D = player.call(&"get_traversal_body")
			var seated := bool(body.get_node("Interact").get(&"seated"))
			if not seated and t - t0 < 10.0: return false
			_check(seated, "the act key by the bench: he is seated after %.1f s, %.2f m from the bench's place" % [t - t0, Vector2(body.global_position.x - at.x, body.global_position.z - at.z).length()])
			step = 4; t0 = t
		4:
			if t - t0 < 4.0: return false
			player.call(&"set_move", Vector2(0, 1), false); step = 5; t0 = t
		5:
			var body: Node3D = player.call(&"get_traversal_body")
			if t - t0 < 6.0: return false
			_check(not bool(body.get_node("Interact").get(&"seated")) and Vector2(body.global_position.x - at.x, body.global_position.z - at.z).length() > 1.0, "the stick pushed: he got up and walked off (%.2f m from the bench)" % Vector2(body.global_position.x - at.x, body.global_position.z - at.z).length())
			step = 9
		9:
			print("RESULT %s (%d)" % ["PASS" if fails == 0 else "FAIL", fails]); quit(1 if fails else 0); return true
	return false
