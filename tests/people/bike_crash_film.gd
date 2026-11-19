extends SceneTree
## A short film: the player gets on his bicycle, rides about 10 s (pedalling, then sprinting), and rides into a parked
## car: he is thrown (his balancing body), lies, gets up and stands. Filmed by the bicycle's own chase camera (its
## wobble included), with the engine's movie writer:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 30 --write-movie OUT/bike_crash.avi -s res://tests/people/bike_crash_film.gd
## (C++: CityBike, BikeReach, CityPed's balancing body, CityCar for the parked car.) Prints what happened.
var player: Node3D
var bike: RigidBody3D
var car: RigidBody3D
var t := 0.0
var step := 0
var t_hit := -1.0
var top := -9.0
var far := 0.0
var hit_at := Vector3.ZERO

func _box(at: Vector3, size: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = col; mi.material_override = m
	mi.position = at; root.add_child(mi)

func _initialize() -> void:
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(600, 2, 600); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(0, -1, 0); root.add_child(fl)
	_box(Vector3(0, -1, 0), Vector3(600, 2, 600), Color(0.36, 0.42, 0.33))       # grass
	_box(Vector3(0, -0.995, 40), Vector3(7, 2, 200), Color(0.16, 0.16, 0.17))     # the road
	for k in range(0, 40):                                                        # its middle line and posts for the speed
		_box(Vector3(0, 0.01, -10 + k * 5.0), Vector3(0.12, 0.02, 2.0), Color(0.9, 0.9, 0.85))
		if k % 2 == 0: _box(Vector3(4.2, 0.6, -10 + k * 5.0), Vector3(0.12, 1.2, 0.12), Color(0.9, 0.9, 0.9))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, 35, 0); sun.shadow_enabled = true; root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.88); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.62, 0.62, 0.65)
	root.add_child(env)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(-0.9, 0.05, 0); root.add_child(player)
	bike = ClassDB.instantiate(&"CityBike"); bike.position = Vector3(1.0, 0.02, 0); root.add_child(bike)
	bike.call(&"set_rider_player", player)
	car = ClassDB.instantiate(&"CityCar"); car.set(&"model", 2); car.position = Vector3(1.2, 0.05, 58.0); car.rotation.y = PI * 0.5
	root.add_child(car)
	car.call(&"set_controls", 0.0, 1.0, 0.0, 1.0, false)

func _process(delta: float) -> bool:
	t += delta
	var s: Dictionary = bike.call(&"get_state")
	match step:
		0:
			if t < 1.0: return false
			bike.call(&"get_on"); step = 1
		1:
			if String(s.state) != "riding": return false
			bike.call(&"set_controls", 1.0, 0.0, 0.0, 0.0); step = 2; t = 0.0
		2:
			if t > 4.0: bike.call(&"set_controls", 1.0, 0.0, 0.0, 1.0)    # sprint for the last part
			if String(s.state) == "thrown":
				print("FILM thrown after %.1f s of riding, at %.1f m/s into the car (knock %.1f m/s); damage %.0f, front wheel bent %s" % [t, absf(float(s.speed)), float(s.hardest_knock), float(s.damage), str(s.wheel_bent)])
				t_hit = t; step = 3; hit_at = bike.global_position
			if t > 20.0: print("FILM no crash in 20 s"); quit(1); return true
		3:
			if t - t_hit < 1.2 and OS.get_cmdline_user_args().has("--trace"): print("FILM   t+%.2f hips y %.2f mode %d thrown at %s body %s" % [t - t_hit, (s.rider_at as Vector3).y, int(s.rider_mode), str(s.thrown_at), str(s.rider_body).left(300)])
			if int(s.rider_mode) == 1:
				top = maxf(top, (s.rider_at as Vector3).y); far = maxf(far, Vector2((s.rider_at as Vector3).x - hit_at.x, (s.rider_at as Vector3).z - hit_at.z).length())
			if String(s.state) == "parked" or t - t_hit > 9.0:
				var car_at: Vector3 = car.global_position
				var rest: Vector3 = s.rider_at
				var f: Vector3 = Vector3(0, 0, 1)
				print("FILM his body: hips at most %.2f m over the road; he went over the car: %s (vaults %d); lies %.1f m past the car's middle, %.1f m from where the bicycle hit" % [top, str(rest.z > car_at.z + 0.9), int(s.vaults), rest.z - car_at.z, far])
				print("FILM he %s %.1f s after the crash" % ["got up and stands as the player" if String(s.state) == "parked" else "was still down", t - t_hit])
				step = 4; t_hit = t
		4:
			if t - t_hit > 1.5: quit(0); return true
	return false
