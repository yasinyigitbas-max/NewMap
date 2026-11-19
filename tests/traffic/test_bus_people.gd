extends SceneTree
## People get on and off a real bus (C++: CityTraffic's bus lines + CityCrowd), headless, in REAL time (the traffic
## steps on its own thread by the clock: no --fixed-fps), up to six minutes:
##   godot --headless --path . -s res://tests/traffic/test_bus_people.gd
## The real streets, places and traffic. A stop of the first bus line is watched; three people are sent to wait there;
## a bus a minute runs on every line (the game: every five). PASS: a bus stands at that stop, its door opens to them
## (the crowd is told), the people who waited get on, and the bus drives on.
var traffic: Node3D
var crowd: Node3D
var t := 0.0
var step := 0
var t0 := 0.0
var fails := 0
var place := -1
var at := Vector3.ZERO
var sent: Array = []
var boarded0 := 0
var served0 := 0
var waited := 0

func _initialize() -> void:
	for c: StringName in [&"CityTraffic", &"CityCrowd"]:
		if not ClassDB.class_exists(c):
			print("BUSP ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	traffic = ClassDB.instantiate(&"CityTraffic")
	traffic.set(&"max_cars", 40); traffic.set(&"bus_tph", 60.0); traffic.set(&"parked", false)
	root.add_child(traffic)
	crowd = ClassDB.instantiate(&"CityCrowd")
	crowd.set(&"max_people", 250); crowd.set(&"hour", 12.5)
	root.add_child(crowd)
	crowd.call(&"set_traffic", traffic)

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("BUSP   %s: %s" % ["ok" if ok else "FAIL", what])

func _process(delta: float) -> bool:
	if traffic == null: return true
	t += delta
	match step:
		0:
			if t < 1.0: return false
			var lines: Array = traffic.call(&"bus_lines")
			if lines.is_empty(): _check(false, "no bus line was made"); step = 9; return false
			var pl: PackedInt32Array = lines[0].places
			place = int(crowd.call(&"place_from_file", pl[mini(4, pl.size() - 1)]))      # (the traffic names a stop by its number in places.bin)
			var info: Dictionary = crowd.call(&"place_info", place)
			at = info.at
			var cam := Camera3D.new(); root.add_child(cam)
			cam.look_at_from_position(at + Vector3(0, 28, 30), at, Vector3.UP); cam.current = true
			print("BUSP the first line has %d stops; watching its stop at (%.0f, %.0f)" % [pl.size(), at.x, at.z])
			step = 1; t0 = t
		1:      # the crowd fills; three people are sent to wait at the stop
			if t - t0 < 6.0: return false
			for k in 3:
				var id := int(crowd.call(&"place_walker", (info_pave() as Vector3) + Vector3(2.0 * k - 2.0, 0, 0), 3300 + k))
				if bool(crowd.call(&"set_goal", id, place, 600.0, false)): sent.append(id)
			_check(sent.size() >= 1, "%d people sent to wait at the stop" % sent.size())
			var st: Dictionary = crowd.call(&"stats")
			boarded0 = int(st.boarded); served0 = int(st.buses_served)
			step = 2; t0 = t
		2:      # until somebody has got on here (or six minutes)
			var st: Dictionary = crowd.call(&"stats")
			waited = maxi(waited, int(st.bus_waits))
			var gone := 0
			for id: int in sent:
				var here := false
				for p: Dictionary in crowd.call(&"people_near", at, 60.0):
					if int(p.id) == id: here = true
				if not here: gone += 1
			if int(st.boarded) > boarded0 and gone >= 1 or t - t0 > 360.0:
				_check(int(st.buses_served) > served0, "a bus stood at a stop with its door open %d times in %.0f s (the crowd was told)" % [int(st.buses_served) - served0, t - t0])
				_check(int(st.boarded) > boarded0 and gone >= 1, "people got on: %d in all, %d of the %d sent to this stop are on the bus; %d got off buses" % [int(st.boarded) - boarded0, gone, sent.size(), int(st.alighted)])
				_check(int(st.inside_each_other) == 0 and int(st.bad_numbers) == 0, "nobody inside anybody, no bad number")
				print("BUSP traffic: %s" % String(traffic.call(&"report")).get_slice("| bus lines", 1))
				step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false

func info_pave() -> Vector3:
	var info: Dictionary = crowd.call(&"place_info", place)
	return info.pavement
