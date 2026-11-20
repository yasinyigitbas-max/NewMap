extends SceneTree
## The driver's door of every car model, open (C++: CityCar::set_door, car_paint.gdshader; Yasin, 20 Nov: "CARS DOORS
## SHOULD OPEN"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/traffic/door_shots.gd
## Ten cars, one at a time from the front left, the door shut then open: OUT/doors.png (a grid, open) and OUT/doors_shut.png.
var car: RigidBody3D
var cam: Camera3D
var k := 0
var f := 0
var shots_open := []
var shots_shut := []

func _initialize() -> void:
	var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(100, 2, 100); cs.shape = sh; fl.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sh.size; mi.mesh = bm; fl.add_child(mi); fl.position = Vector3(0, -1, 0); root.add_child(fl)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 140, 0); root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.55, 0.7, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.62); root.add_child(env)
	car = ClassDB.instantiate(&"CityCar"); car.freeze = true; root.add_child(car)
	cam = Camera3D.new(); root.add_child(cam); cam.current = true
	cam.look_at_from_position(Vector3(3.6, 1.6, 2.6), Vector3(0.5, 0.75, -0.4), Vector3.UP)

func _small(im: Image) -> Image:
	var c := im.get_region(Rect2i(160, 60, 640, 500)); c.resize(384, 300); return c

func _process(_d: float) -> bool:
	f += 1
	if f == 2: car.call(&"become", k, 0, Color(0.55, 0.12, 0.1)); car.call(&"set_door", 0.0)
	elif f == 6: shots_shut.append(root.get_texture().get_image()); car.call(&"set_door", 1.0)
	elif f == 10:
		shots_open.append(root.get_texture().get_image())
		k += 1; f = 0
		if k >= 10:
			for pair in [[shots_open, "doors"], [shots_shut, "doors_shut"]]:
				var g := Image.create(5 * 384, 2 * 300, false, Image.FORMAT_RGBA8)
				for i in (pair[0] as Array).size():
					var im: Image = pair[0][i]; im.convert(Image.FORMAT_RGBA8)
					g.blit_rect(im, Rect2i(220, 110, 520, 406), Vector2i((i % 5) * 384, (i / 5) * 300)) if false else g.blit_rect(_small(im), Rect2i(0, 0, 384, 300), Vector2i((i % 5) * 384, (i / 5) * 300))
				g.save_png("res://OUT/%s.png" % pair[1])
			quit(); return true
	return false
