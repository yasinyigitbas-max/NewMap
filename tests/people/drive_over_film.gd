extends SceneTree
## A car driven over a person lying in the road (the Animator, 20 Nov; Yasin: "our car shouldnt be able to go thru anyone
## too, we should drive over them and car should be lifted a bit off the ground"): the player, on foot, is pushed over
## and lies; a real car (CityCar) is driven over him at a walking pace; its wheels ride up over his body (CityCrowd::
## body_under) and it lifts. Side view, 25 fps.
##   godot --path . --rendering-method mobile --resolution 640x480 --fixed-fps 50 -s res://tests/people/drive_over_film.gd -- --out=OUT/drive_over
## Writes <out>/f_<frame>.png; prints DRIVEOVER lines and RESULT PASS when the wheels rode over him and the car lifted.
var out := "OUT/drive_over"
var crowd: Node3D
var player: CharacterBody3D
var car: RigidBody3D
var cam: Camera3D
var t := 0.0
var step := 0
var n := 0
var shot := 0
var spot := Vector3.ZERO
var y0 := 0.0
var lift := 0.0

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 60); crowd.set(&"hour", 12.5)
	root.add_child(crowd)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); sun.shadow_enabled = true; root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.6, 0.7, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.72, 0.73, 0.78); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	cam = Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); cam.fov = 45.0; root.add_child(cam); cam.current = true

func _fig() -> Node3D:
	for c in player.get_children(): if c.get_class() == "CityPed": return c
	return null

func _physics_process(delta: float) -> bool:
	t += delta; n += 1
	if step >= 1:
		cam.current = true
		cam.look_at_from_position(spot + Vector3(6.5, 1.6, 0.0), spot + Vector3(0, 0.6, 0), Vector3.UP)
		if n % 2 == 0: root.get_texture().get_image().save_png("%s/f_%03d.png" % [out, shot]); shot += 1
	if car != null and step >= 3: lift = maxf(lift, car.global_position.y - y0)
	if car != null and n % 25 == 0 and step >= 1:
		var fr: Dictionary = player.call(&"get_frame_log")
		print("DRIVEOVER t %.1f step %d car %s v %.1f | fig mode %d body %s" % [t, step, str(car.global_position), (car.linear_velocity as Vector3).length(), int(fr.get("fig_mode", -1)), str(fr.get("fig_at", Vector3()))])
	match step:
		0:
			if t < 4.0: return false
			spot = Vector3(60.0, 0.0, -560.0)   # (away from the people)
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(200, 2, 200); cs.shape = sh; fl.add_child(cs)
			var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi)
			fl.position = spot - Vector3(0, 1.0, 0); root.add_child(fl)
			player = ClassDB.instantiate(&"CityPlayer"); player.position = spot + Vector3(0, 0.05, 0); root.add_child(player)
			crowd.call(&"set_player", player)
			car = ClassDB.instantiate(&"CityCar"); car.set(&"model", 0); car.set(&"paint", Color(0.2, 0.3, 0.6))
			car.position = spot + Vector3(-0.75, 0.05, -5.5)   # (its left wheels in line with him)
			root.add_child(car)
			step = 1; t = 0.0
		1:
			if t < 1.0: return false
			var f := _fig()
			if f: f.call(&"push", Vector3(0, 0, -160), f.global_position + Vector3(0, 1.4, 0))   # (pushed over toward the car: he lies along its left wheels' line)
			step = 2; t = 0.0
		2:
			if t < 0.6: return false
			y0 = car.global_position.y
			step = 3; t = 0.0
		3:
			var v: float = (car.linear_velocity as Vector3).length()
			car.call(&"set_controls", 0.35 if v < 2.0 else 0.0, 0.0, 0.0, 0.0, false)
			if t < 9.0: return false
			car.call(&"set_controls", 0.0, 1.0, 0.0, 0.0, false)
			var st: Dictionary = car.call(&"get_state")
			var bumps := int(st.get("bumps_over", 0))
			print("DRIVEOVER wheel steps over a person: %d; the car lifted at most %.2f m" % [bumps, lift])
			print("FILM %d frames saved: %s" % [shot, out])
			print("RESULT %s" % ("PASS" if bumps > 0 and lift > 0.05 else "FAIL"))
			quit(0); return true
	return false
