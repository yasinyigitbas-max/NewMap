extends SceneTree
## Two pictures of a traffic car while it steers (C++ CityTraffic: the nearest cars have their wheels apart), for a
## look by eye. A small window, leaves by itself:
##   godot --path . --rendering-method mobile --resolution 640x400 -s res://tests/traffic/wheel_shots.gd -- --out=OUT/wheel_shots
## The real streets and traffic over a plain floor (the city is not loaded). It waits for a car that turns its wheels
## more than 8 degrees, goes to its front corner, takes one picture from there and one from straight above.
var traffic: Node3D
var cam: Camera3D
var floor_: MeshInstance3D
var at := Vector3(-600, 0, -1000)
var out := "OUT/wheel_shots"
var t := 0.0
var target := -1
var stage := 0
var wait := 0
var seen_most := 0.0
var last_say := -1

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	RenderingServer.global_shader_parameter_add(&"refl_env", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2(1.0, 0.0))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, 30, 0); root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.7, 0.78, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	floor_ = MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(400, 400); floor_.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.36, 0.37, 0.39); floor_.material_override = fm; root.add_child(floor_)
	cam = Camera3D.new(); cam.fov = 50.0; cam.position = at + Vector3(0, 30, 0); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true
	traffic = ClassDB.instantiate(&"CityTraffic")
	traffic.set(&"max_cars", 60); traffic.set(&"parked", false); traffic.set(&"bodies", false)
	root.add_child(traffic)

func _find(id: int) -> Dictionary:
	for c: Dictionary in traffic.call(&"cars_near", cam.global_position, 400.0):
		if int(c.id) == id: return c
	return {}

func _process(delta: float) -> bool:
	if traffic == null: return true
	t += delta
	if t > 75.0: print("WHEELS no car turned its wheels in 75 s"); quit(1); return true
	if stage == 0:
		if t < 20.0: return false
		var most := 0.0; var n := 0
		for c: Dictionary in traffic.call(&"cars_near", at, 220.0):
			n += 1; most = maxf(most, absf(float(c.steer)))
			if absf(float(c.steer)) > 0.14 and float(c.speed) > 2.0: target = int(c.id); stage = 1; wait = 0; break
		seen_most = maxf(seen_most, most)
		if int(t) % 10 == 0 and int(t) != last_say: last_say = int(t); print("WHEELS at %d s: %d cars within 220 m, the most any front wheels were turned so far %.0f degrees" % [int(t), n, rad_to_deg(seen_most)])
		return false
	var c := _find(target)
	if c.is_empty(): stage = 0; return false
	var p: Vector3 = c.at; var yaw := float(c.yaw)
	var fwd := Vector3(sin(yaw), 0, cos(yaw)); var left := Vector3(fwd.z, 0, -fwd.x)
	floor_.position = Vector3(p.x, p.y - 0.01, p.z)
	if stage == 1:      # from its front corner, on the side it turns to
		var side := signf(float(c.steer))
		cam.global_position = p + fwd * 5.2 + left * side * 3.4 + Vector3(0, 1.3, 0)
		cam.look_at(p + Vector3(0, 0.5, 0))
	else:               # from straight above, the car's nose up the picture
		cam.global_position = p + Vector3(0, 9.0, 0)
		cam.look_at(p, fwd)
	wait += 1
	if wait < 4: return false
	root.get_texture().get_image().save_png("%s/%s.png" % [out, "1_front_corner" if stage == 1 else "2_from_above"])
	print("WHEELS shot %d: car %d, front wheels at %.0f degrees (+ = left), %.0f km/h" % [stage, target, rad_to_deg(float(c.steer)), float(c.speed) * 3.6])
	if stage == 1 and absf(float(c.steer)) < 0.08: stage = 0; return false      # (it straightened meanwhile: another car)
	stage += 1; wait = 0
	if stage > 2:
		print("WHEELS traffic: %s" % String(traffic.call(&"report")))
		quit(0); return true
	return false
