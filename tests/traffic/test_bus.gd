extends SceneTree
## The buses (C++: CityTraffic makes the lines from the map's own bus stops; the old core drives them), headless:
##   godot --headless --path . -s res://tests/traffic/test_bus.gd [-- --minutes=20]
## Part 1, stepped as fast as it goes: the lines that were made, and one run of the whole city with the buses in the
## traffic and the parked cars: buses must be put on the road and serve stops, and the traffic's own checks must hold
## with them (no two cars overlapping, nobody standing over 2 minutes, no moving car touching a parked one).
## Part 2 is tests/traffic/test_bus_people.gd (the people who wait get on: real time, in the tree).
const STREETS := "res://map_dc/coronado/city_kit/traffic/streets.bin"

func _initialize() -> void:
	var minutes := 20.0
	var trace := -1
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="): minutes = float(a.trim_prefix("--minutes="))
		if a.begins_with("--trace="): trace = int(a.trim_prefix("--trace="))      # one car's history: its first and last moments
	if not ClassDB.class_exists(&"CityTraffic"):
		print("BUS ERROR the native module is not built: run  bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	var t: Object = ClassDB.instantiate(&"CityTraffic")
	if OS.get_cmdline_user_args().has("--nobus"): t.set(&"buses", false)      # (the same run without buses, to compare)
	if not t.load_streets(STREETS):
		print("BUS ERROR cannot load %s" % STREETS); print("RESULT FAIL"); t.free(); quit(1); return
	var fails := 0
	var lines: Array = t.call(&"bus_lines")
	var stops := 0
	for l: Dictionary in lines:
		stops += int(l.stops)
		print("BUS line: %d stops, %.1f km round, %s" % [int(l.stops), float(l.metres) / 1000.0, "a loop" if bool(l.loop) else "NOT a loop (no way back to its first stop)"])
	var ok := lines.size() >= 1 and stops >= 8
	if not ok: fails += 1
	print("BUS   %s: %d lines made from the map's bus stops, %d stops served in all" % ["ok" if ok else "FAIL", lines.size(), stops])
	t.set(&"debug_car", trace)
	var t0 := Time.get_ticks_msec()
	var d: Dictionary = t.run_test(190, minutes, 7, Vector3(0, 0, -600), true, false, 1.0, true)
	ok = int(d.buses_spawned) >= 2 and int(d.bus_stops_served) >= 6
	if not ok: fails += 1
	print("BUS   %s: %.0f minutes of the whole city: %d buses put on the road, %d stops served" % ["ok" if ok else "FAIL", minutes, int(d.buses_spawned), int(d.bus_stops_served)])
	ok = int(d.overlaps_car_car) == 0 and int(d.stuck_over_2min_most) == 0 and int(d.touching_parked) == 0
	if not ok: fails += 1
	print("BUS   %s: with the buses in it: overlapping pairs %d, standing over 2 minutes %d, a moving car touching a parked one %d (all must be 0); %d cars pulled out, %d parked (%.0f s to run)" % ["ok" if ok else "FAIL", int(d.overlaps_car_car), int(d.stuck_over_2min_most), int(d.touching_parked), int(d.pulled_out), int(d.parked), (Time.get_ticks_msec() - t0) / 1000.0])
	if not ok:
		for tc: String in d.get("touch_cases", []): print("BUS     touch: %s" % tc)
		for c: Dictionary in d.get("standing", []): print("BUS     standing: %s" % str(c).left(1500))
	if trace >= 0:
		var tr: Array = d.get("trace", [])
		for k in tr.size():
			if k < 30 or k >= tr.size() - 2: print("BUS     trace: %s" % tr[k])
	t.free()
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
