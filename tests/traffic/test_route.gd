extends SceneTree
## The route finder inside the traffic core (C++: tc::Sim::find_route_ex, A*; CityTraffic.route, spawn_driver,
## drive_car_to, pull_car_over, let_car_go), headless:
##   godot --headless --path . -s res://tests/traffic/test_route.gd
## Part 1, no tree: ways on the map between points across the town, by car and by bike. Each must be found, be no
##   shorter than the straight line, its line must run with no gap over 16 m from one end to the other, start and end
##   by the points asked, and its length must agree with the finder's metres. A* is timed and counted.
## Part 2, in the tree (real time): a driver of the game's own is put on the road and sent to a point 300-600 m away
##   by road; the step answers the order, the car drives there and stands within 25 m of it; then it is let go.
const STREETS := "res://map_dc/coronado/city_kit/traffic/streets.bin"
var t: Node3D
var fails := 0
var step := 0
var t0 := 0.0
var clock := 0.0
var ticket := -1
var car := -1
var goal := Vector3.ZERO
var start := Vector3.ZERO

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("ROUTE   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityTraffic"):
		print("ROUTE ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	t = ClassDB.instantiate(&"CityTraffic")
	t.set(&"max_cars", 30); t.set(&"parked", false); t.set(&"cyclists", 0)
	if not t.load_streets(STREETS):
		print("ROUTE ERROR cannot load %s" % STREETS); print("RESULT FAIL"); quit(1); return
	var pairs := [[Vector3(0, 0, -600), Vector3(-400, 0, -1400)], [Vector3(573, 0, 200), Vector3(-800, 0, -1050)],
		[Vector3(800, 0, -1150), Vector3(0, 0, -100)], [Vector3(-800, 0, -1050), Vector3(573, 0, 200)],
		[Vector3(0, 0, -100), Vector3(30, 0, -130)], [Vector3(-400, 0, -1400), Vector3(800, 0, -1150)]]
	var us_most := 0.0
	for bike in [false, true]:
		for pr: Array in pairs:
			var a: Vector3 = pr[0]; var b: Vector3 = pr[1]
			var d: Dictionary = t.call(&"route", a, b, bike)
			var straight := Vector2(a.x - b.x, a.z - b.z).length()
			if not bool(d.ok):
				_check(false, "%s from %s to %s: no way found" % ["bike" if bike else "car", str(a), str(b)]); continue
			var pts: PackedVector3Array = d.points
			var line := 0.0; var gap := 0.0
			for k in range(1, pts.size()):
				var g := Vector2(pts[k].x - pts[k - 1].x, pts[k].z - pts[k - 1].z).length()
				line += g; gap = maxf(gap, g)
			var m := float(d.metres)
			var ends := Vector2(pts[0].x - a.x, pts[0].z - a.z).length() < 60.0 and Vector2(pts[pts.size() - 1].x - b.x, pts[pts.size() - 1].z - b.z).length() < 60.0
			var agree := absf(line - m) < 0.12 * m + 60.0
			us_most = maxf(us_most, float(d.us))
			_check(m >= straight * 0.9 - 60.0 and gap < 16.0 and ends and agree, "%s from (%.0f, %.0f) to (%.0f, %.0f): %.0f m by road (straight %.0f m), its line %.0f m in %d points, largest gap %.1f m, %d lanes; %d lanes searched in %.0f microseconds" % ["bike" if bike else "car", a.x, a.z, b.x, b.z, m, straight, line, pts.size(), gap, (d.lanes as PackedInt32Array).size(), int(d.searched), float(d.us)])
	print("ROUTE the slowest search took %.2f ms" % (us_most / 1000.0))
	# part 2: the game's own car, in the tree
	var cam := Camera3D.new(); cam.position = Vector3(0, 60, -600); cam.rotation_degrees = Vector3(-90, 0, 0); root.add_child(cam); cam.current = true
	root.add_child(t)

func _process(delta: float) -> bool:
	if t == null or not t.is_inside_tree(): return false
	clock += delta
	match step:
		0:
			if clock < 1.5: return false
			start = Vector3(0, 0, -600); goal = Vector3(-300, 0, -950)
			var d: Dictionary = t.call(&"route", start, goal, false)
			ticket = int(t.call(&"spawn_driver", start, goal, 2))
			print("ROUTE a driver of the game's own asked for: from %s to %s, %.0f m by road" % [str(start), str(goal), float(d.metres)])
			step = 1; t0 = clock
		1:
			var r := int(t.call(&"order_result", ticket))
			if r == -9 and clock - t0 < 5.0: return false
			_check(r >= 0, "the step answered the order: car %d" % r)
			if r < 0: step = 9; return false
			car = r; step = 2; t0 = clock
		2:
			var here := Vector3(1e9, 0, 0); var v := 9.0
			for c: Dictionary in t.call(&"cars_near", goal, 2000.0):
				if int(c.id) == car: here = c.at; v = float(c.speed)
			(root.get_viewport().get_camera_3d() as Camera3D).position = here + Vector3(0, 60, 0)
			var near := Vector2(here.x - goal.x, here.z - goal.z).length()
			if not (near < 25.0 and v < 0.3) and clock - t0 < 180.0: return false
			_check(near < 25.0 and v < 0.3, "it drove there by road and stands %.1f m from the point asked (%.0f s)" % [near, clock - t0])
			ticket = int(t.call(&"let_car_go", car))
			step = 3; t0 = clock
		3:
			var r := int(t.call(&"order_result", ticket))
			if r == -9 and clock - t0 < 5.0: return false
			_check(r == 1, "it is let go and drives on as ordinary traffic")
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
