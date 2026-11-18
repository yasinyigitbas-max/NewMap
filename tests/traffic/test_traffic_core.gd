extends SceneTree
## The traffic core on the new streets, with no drawing (stage 2b of docs/TRAFFIC_PEOPLE_PORT.md). Headless:
##   godot --headless --path . -s res://tests/traffic/test_traffic_core.gd [-- --minutes=30 --cars=80]
## All the work is C++ (CityTraffic.run_test); this script only starts the runs and prints what came back.
## PASS needs, in every run: no two cars overlapping at any check (once a second of traffic time), no car standing
## over 2 minutes away from a red light with the "take a stuck car away" rule OFF, and the same seed giving the same
## state twice. Prints "TRAFFIC ..." lines and RESULT PASS / FAIL.
const STREETS := "res://map_dc/coronado/city_kit/traffic/streets.bin"

func _init() -> void:
	var minutes := 30.0; var cars := 80
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="): minutes = float(a.trim_prefix("--minutes="))
		if a.begins_with("--cars="): cars = int(a.trim_prefix("--cars="))
	if not ClassDB.class_exists(&"CityTraffic"):
		print("TRAFFIC ERROR the native module is not built: run  bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	var t: Object = ClassDB.instantiate(&"CityTraffic")
	if not t.load_streets(STREETS):
		print("TRAFFIC ERROR cannot load %s: run tools/city/traffic/make_streets.gd" % STREETS); print("RESULT FAIL"); t.free(); quit(1); return
	print("TRAFFIC streets: %s" % str(t.street_stats()))
	var fails := 0
	## name, cars, camera, whole city?, stuck rule?
	## name, most cars, camera, whole city?, stuck rule?, density (1 = what the streets carry at their busiest hour)
	var runs := [["whole city, busiest hour, every car every tick", 190, Vector3(0, 0, -600), true, false, 1.0],
		["whole city at TWICE the busiest hour", 190, Vector3(0, 0, -600), true, false, 2.0],
		["city centre as in the game", cars, Vector3(0, 6, -600), false, false, 1.0],
		["city centre at twice the busiest hour", cars, Vector3(0, 6, -600), false, false, 2.0],
		["3rd St arterial as in the game", cars, Vector3(-400, 2, -1400), false, false, 1.0],
		["3rd St arterial at twice the busiest hour", cars, Vector3(-400, 2, -1400), false, false, 2.0],
		["ring at the waterfront as in the game", cars, Vector3(573, 2, 200), false, false, 1.0],
		["bridge foot as in the game", cars, Vector3(800, 5, -1150), false, false, 1.0],
		["bridge foot at twice the busiest hour", cars, Vector3(800, 5, -1150), false, false, 2.0]]
	for r: Array in runs:
		var t0 := Time.get_ticks_msec()
		var d: Dictionary = t.run_test(int(r[1]), minutes, 7, r[2], bool(r[3]), bool(r[4]), float(r[5]))
		var wall := (Time.get_ticks_msec() - t0) / 1000.0
		# at the busiest hour nobody may stand over 2 minutes; at twice the busiest hour (more cars than the junctions
		# can pass: queues are expected) the run must still have no overlap and must not lock up (nobody over 10 minutes)
		var over: bool = float(r[5]) > 1.5
		var ok: bool = int(d.overlaps_car_car) == 0 and (int(d.stuck_over_2min_most) == 0 if not over else float(d.stuck_longest_s) < 600.0)
		if not ok: fails += 1
		print("TRAFFIC run '%s': %s | %.0f traffic minutes in %.1f s" % [String(r[0]), "ok" if ok else "FAIL", minutes, wall])
		print("TRAFFIC   cars most %d, at end %d (the streets there carry %.0f, the cap is %d) | appeared %d, left %d, taken away stuck %d, at a dead end %d | mean speed %.1f km/h" % [int(d.cars_most), int(d.cars_at_end), float(d.streets_carry), int(d.cars_wanted), int(d.spawned), int(d.despawned), int(d.taken_away_stuck), int(d.taken_away_dead_end), float(d.mean_speed_kmh)])
		print("TRAFFIC   overlapping pairs seen: car-car %d (must be 0) | standing over 2 min not at a red: at most %d cars (%s)%s" % [int(d.overlaps_car_car), int(d.stuck_over_2min_most), "must be 0" if not over else "over capacity: none may stand over 10 min", "" if int(d.stuck_over_2min_most) == 0 else ", longest %.0f s at (%.0f, %.0f), reason %d" % [float(d.stuck_longest_s), (d.stuck_at as Vector3).x, (d.stuck_at as Vector3).z, int(d.stuck_why)]])
		print("TRAFFIC   crashes %d, emergency brakes %d, hard brakes %d, honks %d, lane changes %d, junction go-aheads %d, moves refused %d, waited long and asked for a way through %d (others held back for them %d times) | a step: mean %.0f, worst %.0f microseconds" % [int(d.crashes), int(d.emergency_brakes), int(d.hard_brakes), int(d.honks), int(d.lane_changes), int(d.reservations), int(d.moves_refused), int(d.asks), int(d.let_through), float(d.step_us_mean), float(d.step_us_worst)])
		if not ok:
			for c: Dictionary in d.standing:
				print("TRAFFIC     standing: car %d at (%.0f, %.0f) %.0f s, why %d, lane %d (%.1f of %.1f m), control %d signal %d, on path %d next path %d turn %d to lane %d node %d | leader %d stopped by %d | refused: reason %d by car %d value %.1f | flags %d man %d" % [int(c.id), float(c.x), float(c.z), float(c.wait_s), int(c.why), int(c.lane), float(c.s), float(c.lane_len), int(c.control), int(c.signal), int(c.on_path), int(c.next_path), int(c.turn), int(c.to_lane), int(c.node), int(c.leader), int(c.stopped_by), int(c.refused_why), int(c.refused_by), float(c.refused_value), int(c.flags), int(c.man)])
				if int(c.leader) < 0 or int(c.why) != 5: print("TRAFFIC       named in its refusal: %s" % String(c.holder))
	# the same seed twice
	var a: Dictionary = t.run_test(cars, 3.0, 11, Vector3(0, 6, -600), false, true, 2.0)
	var b: Dictionary = t.run_test(cars, 3.0, 11, Vector3(0, 6, -600), false, true, 2.0)
	var same: bool = int(a.hash) == int(b.hash)
	if not same: fails += 1
	print("TRAFFIC the same seed twice: %s (hash %d / %d)" % ["the same state" if same else "DIFFERENT", int(a.hash), int(b.hash)])
	t.free()
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
