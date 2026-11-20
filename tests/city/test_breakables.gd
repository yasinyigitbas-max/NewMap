extends SceneTree
## B9: a car knocks a small street prop over, and the prop comes back out of sight (C++ CityBreakables under CityStream).
##   godot --path . --rendering-method mobile --resolution 640x360 -s res://tests/city/test_breakables.gd
## The real baked city (needs a bake with the brk_ nodes). It finds a breakable near a road, puts a CityCar 14 m before
## it aimed at it, drives it in at about 30 km/h, and checks: the prop is knocked (CityBreakables.get_state().knocked),
## a debris body moved off its spot, and after the camera is turned away and RESET_S has passed it stands again.
var st: Node3D
var cam: Camera3D
var car: RigidBody3D
var step := -1
var t := 0.0
var fails := 0
var target := Vector3.ZERO
var start := Vector3.ZERO

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("BRK   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var w := Node3D.new(); w.name = "World"; root.add_child(w)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); w.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); w.add_child(sun)
	cam = Camera3D.new(); w.add_child(cam); cam.current = true
	st = ClassDB.instantiate(&"CityStream"); st.name = "City"; w.add_child(st)


func _brk() -> Object: return st.get_node_or_null(^"Breakables")

func _process(dt: float) -> bool:
	t += dt
	match step:
		-1:      # (the streamer's _ready has run by the first frame)
			st.update_focus(Vector3(-12, 0, -606), true)      # the city centre (the start), everything round it now
			print("BRK   loaded cells %d, breakables %s" % [st.loaded_count(), str(_brk().call(&"get_state"))])
			step = 0; return false
		0:      # a breakable standing in the open: a bus-stop sign, a cone or a bollard with 14 m of clear road before it
			var cells: Dictionary = st.cells
			for k: String in cells:
				var cn: Node = cells[k].node
				if cn == null: continue
				for n: Node in cn.find_children("brk_*", "MultiMeshInstance3D", true, false):
					var mmi := n as MultiMeshInstance3D
					for i in mmi.multimesh.instance_count:
						var p := (mmi.global_transform * mmi.multimesh.get_instance_transform(i)).origin
						if p.distance_to(Vector3(-12, 0, -606)) > 180.0: continue
						var space := cam.get_world_3d().direct_space_state
						for a in 8:      # a clear run-up: ground under it and nothing in the way (rays at bumper height)
							var dir := Vector3(sin(a * TAU / 8.0), 0, cos(a * TAU / 8.0))
							var s0 := p + dir * 14.0
							var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(s0 + Vector3(0, 3, 0), s0 - Vector3(0, 4, 0)))
							if down.is_empty() or absf((down.position as Vector3).y - p.y) > 0.4: continue
							var across := space.intersect_ray(PhysicsRayQueryParameters3D.create(s0 + Vector3(0, 0.6, 0), p + Vector3(0, 0.6, 0) + dir * 0.6))
							if not across.is_empty(): continue
							target = p; start = Vector3(s0.x, (down.position as Vector3).y + 0.6, s0.z)
							break
						if target != Vector3.ZERO: break
					if target != Vector3.ZERO: break
				if target != Vector3.ZERO: break
			_check(target != Vector3.ZERO, "a breakable with a clear run-up near the centre at %s (state %s)" % [str(target), str(_brk().call(&"get_state") if _brk() else "no Breakables node")])
			if target == Vector3.ZERO: return _end()
			cam.global_position = target + Vector3(0, 2, 6); cam.look_at(target)
			step = 10; t = 0.0
		10:      # standing: the props near the camera have colliders (nobody walks through a bollard)
			if t < 0.5: return false
			var s0: Dictionary = _brk().call(&"get_state")
			var dirc := (start - target); dirc.y = 0; dirc = dirc.normalized()
			var hit := cam.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(target + dirc * 2.0 + Vector3(0, 0.5, 0), target - dirc * 0.5 + Vector3(0, 0.5, 0)))
			_check(int(s0.colliders_now) > 0, "standing props near the camera have colliders: %s" % str(s0))
			_check(not hit.is_empty() and (hit.position as Vector3).distance_to(target + Vector3(0, 0.5, 0)) < 1.0, "a ray at knee height meets the prop itself (%s)" % str(hit.get("position", "nothing")))
			car = ClassDB.instantiate(&"CityCar"); car.name = "TestCar"; car.add_to_group("vehicles"); root.add_child(car)
			var fwd := (target - start); fwd.y = 0; fwd = fwd.normalized()
			car.global_transform = Transform3D(Basis(Vector3.UP, atan2(fwd.x, fwd.z)), start)
			car.linear_velocity = fwd * 8.5
			car.call(&"set_controls", 0.6, 0.0, 0.0, 0.0, false)
			step = 1; t = 0.0
		1:
			cam.global_position = car.global_position + Vector3(0, 6, 0) - (target - car.global_position).normalized() * 8.0; cam.look_at(target)
			var s: Dictionary = _brk().call(&"get_state")
			if int(s.knocked) > 0 or t > 6.0:
				_check(int(s.knocked) > 0, "the car knocked it over within %.1f s (speed %.1f m/s) - state %s" % [t, car.linear_velocity.length(), str(s)])
				car.call(&"set_controls", 0.0, 1.0, 0.0, 1.0, false)
				step = 2; t = 0.0
		2:
			if t > 1.0:
				var s2: Dictionary = _brk().call(&"get_state")
				_check(int(s2.debris) > 0, "a debris body is flying / lying: %s" % str(s2))
				cam.global_position = target + Vector3(0, 40, 0); cam.look_at(target + Vector3(0, 40, 50))      # looking away
				step = 3; t = 0.0
		3:
			if t > 7.5:
				var s3: Dictionary = _brk().call(&"get_state")
				_check(int(s3.knocked) == 0, "out of sight after 6 s it stands again: %s" % str(s3))
				return _end()
	return false

func _end() -> bool:
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL"))
	quit(1 if fails else 0)
	return true
