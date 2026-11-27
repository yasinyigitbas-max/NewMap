extends SceneTree
## The old cars' real doors and the parallax cabin (C++: CityCar::fit_doors / door_pose; tools/vehicles_doors; Yasin,
## 27 Nov: "make the doors off the existing cars truly openable", "make the cabin look like it exists with some
## parallax effect"), in a window so the pictures show the doors and the glass:
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/car/test_real_doors.gd [-- --model=5]
## The Sakura (model 5) stands on a floor. Checks: it has real doors; with both doors shut each door node sits on its
## hinge (the door's origin = the hinge, unturned); the driver's door at 1 is turned out to the car's left by its full
## angle (its back edge further out in +x than the shut door's) and the passenger's to the right; the cabin box is drawn
## only while a door is open; set_door(0) shuts them again. Pictures: OUT/real_doors_strip.png (shut, half, open; the
## left side, the right side, the glass up close from two angles: the parallax).
var car: Node3D
var cam: Camera3D
var t := 0.0
var step := 0
var fails := 0
var shots: Array = []
var model := 5

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("DOORS  %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--model="): model = int(a.substr(8))
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(200, 2, 200); cs.shape = sh; fl.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi); fl.position = Vector3(0, -1, 0); root.add_child(fl)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 140, 0); root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.55, 0.6, 0.68)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.62); root.add_child(env)
	if not ClassDB.class_exists(&"CityCar"):
		print("DOORS  FAIL: CityCar missing (native module not built)"); quit(1); return
	car = ClassDB.instantiate(&"CityCar")
	car.set_model(model)
	car.set_paint(Color(0.55, 0.06, 0.05))
	root.add_child(car)
	cam = Camera3D.new(); cam.fov = 50; root.add_child(cam)

func _door(i: int) -> MeshInstance3D:
	# the door nodes are the car's MeshInstance3D children placed off the origin (the body and wheels: body at 0, wheels at hubs)
	var ds := []
	for c in car.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null and (c as MeshInstance3D).mesh.get_class() == "ArrayMesh":
			var m: ArrayMesh = (c as MeshInstance3D).mesh
			if m.get_aabb().size.z > 0.8 and m.get_aabb().size.z < 1.4 and c.position.length() > 0.3:
				ds.append(c)
	ds.sort_custom(func(a, b): return a.position.x > b.position.x)
	return ds[i] if i < ds.size() else null

func _cabin_box() -> MeshInstance3D:
	for c in car.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh: return c
	return null

func _shoot(from: Vector3, at: Vector3) -> void:
	cam.position = from; cam.look_at(at)

func _process(delta: float) -> bool:
	t += delta
	if t < 0.4: return false
	t = 0.0
	match step:
		0:
			_check(car.has_real_doors(), "the model has real doors")
			var dl := _door(0); var dr := _door(1)
			_check(dl != null and dr != null, "two door nodes")
			if dl and dr:
				_check(dl.position.x > 0.6 and dr.position.x < -0.6, "doors on their hinges (x %.2f, %.2f)" % [dl.position.x, dr.position.x])
				_check(dl.basis.is_equal_approx(Basis()) and dr.basis.is_equal_approx(Basis()), "shut: unturned")
			var cb := _cabin_box()
			_check(cb != null and not cb.visible, "cabin box hidden while shut")
			_shoot(Vector3(4.2, 1.6, 2.6), Vector3(0, 0.7, 0))
		1:
			shots.append(root.get_texture().get_image())
			car.set_door(0.5); car.set_door_right(0.5)
		2:
			shots.append(root.get_texture().get_image())
			car.set_door(1.0); car.set_door_right(1.0)
		3:
			var dl := _door(0); var dr := _door(1)
			if dl and dr:
				var back_l := dl.transform * Vector3(0, 0, -1.0)
				var back_r := dr.transform * Vector3(0, 0, -1.0)
				_check(back_l.x > dl.position.x + 0.6, "driver's door open outwards (back edge x %.2f vs hinge %.2f)" % [back_l.x, dl.position.x])
				_check(back_r.x < dr.position.x - 0.6, "passenger's door open outwards (back edge x %.2f vs hinge %.2f)" % [back_r.x, dr.position.x])
			var cb := _cabin_box()
			_check(cb != null and cb.visible, "cabin box shown while open")
			shots.append(root.get_texture().get_image())
			_shoot(Vector3(-4.2, 1.6, 2.6), Vector3(0, 0.7, 0))
		4:
			shots.append(root.get_texture().get_image())
			_shoot(Vector3(2.4, 1.2, -1.9), Vector3(0, 0.85, -0.4))
		5:
			shots.append(root.get_texture().get_image())
			car.set_door(0.0); car.set_door_right(0.0)
			_shoot(Vector3(2.6, 1.3, 0.6), Vector3(0, 0.95, -0.3))
		6:
			shots.append(root.get_texture().get_image())
			_shoot(Vector3(2.6, 1.3, -1.6), Vector3(0, 0.95, -0.3))
		7:
			shots.append(root.get_texture().get_image())
			var dl := _door(0)
			_check(dl != null and dl.basis.is_equal_approx(Basis()), "set_door(0) shuts it again")
			var w: int = shots[0].get_width(); var h: int = shots[0].get_height()
			var strip := Image.create(w * 2, h * 4, false, shots[0].get_format())
			for i in shots.size():
				strip.blit_rect(shots[i], Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://OUT"))
			strip.save_png("res://OUT/real_doors_strip.png")
			print("DOORS  RESULT %s (%d fails)" % ["PASS" if fails == 0 else "FAIL", fails])
			quit(1 if fails else 0)
			return true
	step += 1
	return false
