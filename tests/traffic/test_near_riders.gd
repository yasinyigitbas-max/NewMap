extends SceneTree
## The traffic's cyclists up close and far (C++: CityCrowd's near riders, city_crowd_riders.cpp; the far riding poses
## rebaked for the cruiser; Yasin, 20 Nov: "new bikes and biking animations for npcs arent in the game"), in a window:
##   godot --path . --rendering-method mobile --resolution 960x540 --fixed-fps 60 -s res://tests/traffic/test_near_riders.gd
## The city centre at noon, many cyclists. The camera rides beside one at 5 m: he must be a real rider (a body on a
## cruiser rig, his feet on the pedals and hands on the grips: within 3 cm). Then the camera backs off to 40 m with a
## long lens on him: he is a far figure again, on the batch's cruiser. Pictures OUT/near_rider.png, OUT/far_rider.png.
var traffic: Node3D
var crowd: Node3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var bike := -1
var near_most := 0
var miss_most := 0.0
var floor_on := false

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("RIDERS  %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	cam = Camera3D.new(); cam.position = Vector3(0, 30, -600); root.add_child(cam); cam.current = true
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)
	traffic = ClassDB.instantiate(&"CityTraffic")
	traffic.set(&"max_cars", 10); traffic.set(&"parked", false); traffic.set(&"cyclists", 30); traffic.set(&"buses", false)
	root.add_child(traffic)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 60); crowd.set(&"hour", 12.5); crowd.set(&"near_max", 6)
	root.add_child(crowd)
	crowd.call(&"set_traffic", traffic)

func _bike() -> Dictionary:
	for c: Dictionary in traffic.call(&"cars_near", cam.global_position, 400.0):
		if int(c.id) == bike: return c
	return {}

func _process(delta: float) -> bool:
	t += delta
	cam.current = true
	match step:
		0:
			if t < 2.5: return false
			for c: Dictionary in traffic.call(&"cars_near", cam.global_position, 400.0):
				if bool(c.get("bike", false)) and float(c.speed) > 3.0: bike = int(c.id); break
			if bike < 0:
				if t > 40.0: _check(false, "no cyclist on the move came"); step = 9
				return false
			step = 1; t0 = t
		1, 2:
			var b := _bike()
			if b.is_empty():
				bike = -1; step = 0; return false
			var at: Vector3 = b.at; var f := Vector3(sin(float(b.yaw)), 0, cos(float(b.yaw)))
			var side := Vector3(f.z, 0, -f.x)
			if not floor_on:
				floor_on = true
				var fl := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(1200, 2, 1200); cs.shape = sh; fl.add_child(cs)
				fl.position = at - Vector3(0, 1.0, 0); root.add_child(fl)
			var st: Dictionary = crowd.call(&"stats")
			if step == 1:
				cam.fov = 60.0
				cam.look_at_from_position(at + side * 5.0 + f * 1.5 + Vector3(0, 1.4, 0), at + Vector3(0, 0.9, 0), Vector3.UP)
				if t - t0 > 1.0:
					near_most = maxi(near_most, int(st.get("riders_near", 0)))
					if int(st.get("riders_near", 0)) > 0 and float(st.get("riders_miss", 0.0)) > miss_most: miss_most = float(st.riders_miss); print("RIDERS  miss %.3f m (%s) at %.2f s: %s" % [miss_most, "a hand" if bool(st.riders_miss_hand) else "a foot", t - t0, String(st.riders_limbs)])
				if t - t0 > 4.0:
					root.get_texture().get_image().save_png("res://OUT/near_rider.png")
					_check(near_most >= 1, "beside a cyclist at 5 m: %d near riders" % near_most)
					_check(miss_most < 0.03, "their feet on the pedals and hands on the grips: at most %.3f m off" % miss_most)
					step = 2; t0 = t
			else:
				cam.fov = 9.0
				cam.look_at_from_position(at + side * 40.0 + Vector3(0, 3.0, 0), at + Vector3(0, 0.9, 0), Vector3.UP)
				if t - t0 > 1.5:
					root.get_texture().get_image().save_png("res://OUT/far_rider.png")
					_check(int(st.get("riders_near", 0)) == 0, "from 40 m he is a far figure again (%d near riders)" % int(st.get("riders_near", 0)))
					step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0); return true
	return false
