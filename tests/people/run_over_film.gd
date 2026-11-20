extends SceneTree
## A car runs the player over (the Animator, 20 Nov; Yasin: "i got run over by cars several times while playing"):
## the player stands on a street, a car (a box this script drives, known to the crowd as a car like test_car_hits.gd's)
## comes at 30 km/h; he is knocked down and thrown (his balancing body), lies, gets up and has his body back. 25 fps.
##   godot --path . --rendering-method mobile --resolution 640x480 --fixed-fps 50 -s res://tests/people/run_over_film.gd -- --out=OUT/run_over
## Writes <out>/f_<frame>.png; prints RUNOVER lines and RESULT PASS / FAIL (knocked down, up again, his body back).
var out := "OUT/run_over"
var crowd: Node3D
var player: CharacterBody3D
var car: Node3D
var cam: Camera3D
var t := 0.0
var step := 0
var n := 0
var shot := 0
var spot := Vector3.ZERO
var dir := Vector3.FORWARD
var speed := 0.0
var was_down := false

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 300); crowd.set(&"hour", 12.5)
	root.add_child(crowd)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); sun.shadow_enabled = true; root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.6, 0.7, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.72, 0.73, 0.78); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	cam = Camera3D.new(); cam.position = Vector3(0, 40, -620); cam.rotation_degrees = Vector3(-90, 0, 0); cam.fov = 45.0; root.add_child(cam); cam.current = true

func _physics_process(delta: float) -> bool:
	t += delta; n += 1
	if car != null and speed > 0.0: car.global_position += dir * speed * delta
	if step >= 1:
		cam.current = true
		var f: Vector3 = player.global_position
		cam.look_at_from_position(spot + Vector3(-dir.z, 0, dir.x) * 7.0 + dir * 2.0 + Vector3(0, 2.2, 0), spot + dir * 2.0 + Vector3(0, 0.8, 0), Vector3.UP)
		if n % 2 == 0: root.get_texture().get_image().save_png("%s/f_%03d.png" % [out, shot]); shot += 1
		var fr: Dictionary = player.call(&"get_frame_log") if player.has_method(&"get_frame_log") else {}
		if n % 10 == 0 and step >= 2 and fr.has("pelvis_drawn"): print("RUNOVER t %.1f clip %s mode %d body %s down %s" % [t, fr.get("clip", ""), int(fr.get("fig_mode", -9)), str(fr.get("fig_at", Vector3())), str(crowd.call(&"stats").get("player_down_now", false))])
		if bool(crowd.call(&"stats").get("player_down_now", false)): was_down = true
	match step:
		0:
			if t < 6.0: return false
			for p: Dictionary in crowd.call(&"people_near", Vector3(0, 0, -620), 200.0):
				if int(p.mode) == 0 and int(p.state) == 0 and int(p.party) == 0 and float(p.speed) > 0.9:
					spot = p.at; dir = Vector3(sin(float(p.yaw)), 0, cos(float(p.yaw))); break
			var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
			sh.size = Vector3(800, 2, 800); cs.shape = sh; fl.add_child(cs)
			var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi)
			fl.position = Vector3(spot.x, spot.y - 1.0, spot.z); root.add_child(fl)
			spot += Vector3(-dir.z, 0, dir.x) * 2.5   # (off the pavement, where the people do not walk)
			player = ClassDB.instantiate(&"CityPlayer"); player.position = spot + Vector3(0, 0.05, 0); root.add_child(player)
			crowd.call(&"set_player", player)
			car = MeshInstance3D.new(); var cb := BoxMesh.new(); cb.size = Vector3(1.9, 1.4, 4.4); (car as MeshInstance3D).mesh = cb
			var cm := StandardMaterial3D.new(); cm.albedo_color = Color(0.7, 0.15, 0.12); (car as MeshInstance3D).material_override = cm
			root.add_child(car)
			car.global_position = spot - dir * 22.0 + Vector3(0, 0.7, 0); car.rotation.y = atan2(dir.x, dir.z)
			crowd.call(&"set_player_car", car, 2.2, 0.95)
			step = 1; t = 0.0
		1:
			if t < 0.8: return false
			speed = 8.3   # 30 km/h
			step = 2; t = 0.0
		2:
			if t < 4.0: return false
			speed = 0.0
			step = 3; t = 0.0
		3:
			if t < 12.0: return false
			var st: Dictionary = crowd.call(&"stats")
			var ok_hit := int(st.get("cars_hit_player", 0)) > 0
			var up: bool = not bool(st.get("player_down_now", false))
			print("RUNOVER cars that hit the player: %d (the last at %.1f m/s); knocked down: %s; up again with his body: %s" % [int(st.get("cars_hit_player", 0)), float(st.get("car_hit_v", 0.0)), was_down, up])
			print("FILM %d frames saved: %s" % [shot, out])
			print("RESULT %s" % ("PASS" if ok_hit and was_down and up else "FAIL"))
			quit(0); return true
	return false
