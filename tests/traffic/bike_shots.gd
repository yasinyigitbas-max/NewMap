extends SceneTree
## ONE picture of a cyclist of the traffic (C++: the bicycle is CityTraffic's batch, the rider CityCrowd's far figure in
## a riding pose), from beside him at 4 m, over a flat floor. Needs a renderer:
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/traffic/bike_shots.gd
## Saves map_dc/coronado/city_kit/review/traffic_19nov/bike_rider.jpg and prints the crowd's rider count.
const OUT := "res://map_dc/coronado/city_kit/review/traffic_19nov/bike_rider.jpg"
var traffic: Node3D
var crowd: Node3D
var cam: Camera3D
var t := 0.0
var bike := -1
var shot_at := -1.0

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityTraffic"):
		print("BIKESHOT ERROR the native module is not built"); quit(1); return
	cam = Camera3D.new(); cam.position = Vector3(0, 30, -600); cam.fov = 50.0; root.add_child(cam); cam.current = true
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.85); env.environment.ambient_light_color = Color(0.6, 0.6, 0.6); env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	root.add_child(env)
	traffic = ClassDB.instantiate(&"CityTraffic")
	traffic.set(&"max_cars", 10); traffic.set(&"parked", false); traffic.set(&"cyclists", 24); traffic.set(&"buses", false)
	root.add_child(traffic)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 20); crowd.set(&"hour", 12.5)
	root.add_child(crowd)
	crowd.call(&"set_traffic", traffic)

func _process(delta: float) -> bool:
	t += delta
	if t < 2.0: return false
	var best := {}
	for c: Dictionary in traffic.call(&"cars_near", cam.global_position, 600.0):
		if not bool(c.get("bike", false)): continue
		if bike < 0 and float(c.speed) > 2.0: bike = int(c.id)
		if int(c.id) == bike: best = c
	if best.is_empty():
		bike = -1
		if t > 40.0: print("BIKESHOT FAIL no cyclist came"); quit(1); return true
		return false
	var at: Vector3 = best.at; var yaw := float(best.yaw)
	var fwd := Vector3(sin(yaw), 0, cos(yaw)); var side := Vector3(fwd.z, 0, -fwd.x)
	cam.look_at_from_position(at + side * 3.6 + fwd * 1.2 + Vector3(0, 1.3, 0), at + Vector3(0, 0.9, 0), Vector3.UP)
	if shot_at < 0.0: shot_at = t + 1.5
	if t < shot_at: return false
	var img := root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	img.save_jpg(ProjectSettings.globalize_path(OUT), 0.85)
	print("BIKESHOT saved %s: cyclist %d at %s, %.1f m/s; riders drawn by the crowd this frame: %d" % [OUT, bike, str(at), float(best.speed), int(crowd.call(&"stats").get("riders", -1))])
	quit(0)
	return true
