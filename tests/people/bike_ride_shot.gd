extends SceneTree
## ONE picture of the player riding his bicycle (C++: CityBike, BikeReach on his figure), from beside at 3.4 m:
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/people/bike_ride_shot.gd
## Saves map_dc/coronado/city_kit/review/people_19nov/bike_ride.jpg.
var OUT := "res://map_dc/coronado/city_kit/review/people_19nov/bike_hands.jpg" if OS.get_cmdline_user_args().has("--hands") else "res://map_dc/coronado/city_kit/review/people_19nov/bike_ride.jpg"
var player: Node3D
var bike: RigidBody3D
var cam: Camera3D
var t := 0.0
var step := 0

func _initialize() -> void:
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
	sh.size = Vector3(400, 2, 400); cs.shape = sh; fl.add_child(cs); fl.position = Vector3(0, -1, 0)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(400, 2, 400); mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.33, 0.33, 0.34); mi.material_override = m; fl.add_child(mi)
	root.add_child(fl)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); sun.shadow_enabled = true; root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.85); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	root.add_child(env)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(-0.9, 0.05, 0); root.add_child(player)
	bike = ClassDB.instantiate(&"CityBike"); bike.position = Vector3(0, 0.02, 0); bike.set(&"chase_camera", false); root.add_child(bike)
	bike.call(&"set_rider_player", player)
	cam = Camera3D.new(); cam.fov = 50.0; root.add_child(cam)

func _process(delta: float) -> bool:
	t += delta
	if step == 0 and t > 1.0: bike.call(&"get_on"); step = 1
	if step == 1 and String(bike.call(&"get_state").state) == "riding": bike.call(&"set_controls", 0.8, 0.0, 0.0, 0.0); step = 2; t = 0.0
	if step >= 1:
		cam.current = true
		var f: Vector3 = bike.global_basis.z; var side := Vector3(f.z, 0, -f.x)
		cam.look_at_from_position(bike.global_position + side * (2.2 if OS.get_cmdline_user_args().has("--hands") else 3.4) + f * (1.4 if OS.get_cmdline_user_args().has("--hands") else 0.6) + Vector3(0, 1.5 if OS.get_cmdline_user_args().has("--hands") else 1.2, 0), bike.global_position + Vector3(0, 1.0 if OS.get_cmdline_user_args().has("--hands") else 0.85, 0.3), Vector3.UP)
	if step == 2 and t > 3.3:
		var img := root.get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
		img.save_jpg(ProjectSettings.globalize_path(OUT), 0.85)
		var s: Dictionary = bike.call(&"get_state")
		print("RIDESHOT saved %s at %.1f m/s, clip %s, feet miss %s, hands miss %s, reach %s %s" % [OUT, float(s.speed), String(s.rider_clip), str(s.get("foot_miss")), str(s.get("hand_miss")), str(s.get("reach_on")), str(s.get("reach_influence")) + " back " + str(s.get("back_lean")) + " hips " + str(s.get("hips_on_bike")) + " shoulder " + str(s.get("shoulder_on_bike")) + " foot " + str(s.get("foot_on_bike")) + " foot target " + str(s.get("foot_target_on_bike"))])
		quit(0); return true
	return false
