extends SceneTree
## Pictures of the walking crowd (C++ class CityCrowd), for a look by eye. A small window, leaves by itself:
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/people/crowd_shots.gd -- --out=OUT/crowd_shots [--at=x,z]
## The real streets and places over a plain floor (the city itself is not loaded): three pictures of where most people
## are: from a walker's eye height along the pavement, from a first floor, and from straight above.
var crowd: Node3D
var cam: Camera3D
var floor_: MeshInstance3D
var at := Vector3(0, 0, -620)
var out := "OUT/crowd_shots"
var t := 0.0
var stage := 0
var wait := 0
var spot := Vector3.ZERO
var look_dir := Vector3.FORWARD

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--at="):
			var f := a.trim_prefix("--at=").split_floats(","); at = Vector3(f[0], 0, f[1])
	if not ClassDB.class_exists(&"CityCrowd"): print("CROWD ERROR no native module"); quit(1); return
	DirAccess.make_dir_recursive_absolute(out)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, 30, 0); root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.7, 0.78, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	floor_ = MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(600, 600); floor_.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.5, 0.5, 0.5); floor_.material_override = fm; root.add_child(floor_)
	cam = Camera3D.new(); cam.fov = 60.0; cam.far = 600.0; cam.position = at + Vector3(0, 60, 0); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 500); crowd.set(&"hour", 12.5)
	root.add_child(crowd)

func _process(delta: float) -> bool:
	if crowd == null: return true
	t += delta
	if stage == 0:
		if t < 25.0: return false
		# where most people are: the walker with most others within 12 m
		var ppl: Array = crowd.call(&"people_near", at, 140.0)
		var best := 0
		for p: Dictionary in ppl:
			var n := 0
			for q: Dictionary in ppl:
				if (q.at as Vector3).distance_to(p.at) < 12.0: n += 1
			if n > best: best = n; spot = p.at; look_dir = Vector3(sin(float(p.yaw)), 0, cos(float(p.yaw)))
		print("CROWD %d people within 140 m of (%.0f, %.0f); the picture is taken where %d are within 12 m, at (%.1f, %.1f)" % [ppl.size(), at.x, at.z, best, spot.x, spot.z])
		floor_.position = Vector3(spot.x, spot.y - 0.02, spot.z)
		stage = 1; wait = 0
		return false
	if stage == 1:
		cam.fov = 55.0; cam.global_position = spot - look_dir * 9.0 + Vector3(0, 1.65, 0) + Vector3(look_dir.z, 0, -look_dir.x) * 1.2
		cam.look_at(spot + Vector3(0, 1.0, 0))
	elif stage == 2:
		cam.global_position = spot - look_dir * 14.0 + Vector3(0, 6.0, 0) + Vector3(look_dir.z, 0, -look_dir.x) * 6.0
		cam.look_at(spot + Vector3(0, 0.8, 0))
	else:
		cam.fov = 40.0; cam.global_position = spot + Vector3(0, 26.0, 0)
		cam.look_at(spot, look_dir)
	wait += 1
	if wait < 5: return false
	root.get_texture().get_image().save_png("%s/%d.png" % [out, stage])
	stage += 1; wait = 0
	if stage > 3:
		print("CROWD %s" % String(crowd.call(&"report")))
		print("CROWD stats %s" % str(crowd.call(&"stats")))
		quit(0); return true
	return false
