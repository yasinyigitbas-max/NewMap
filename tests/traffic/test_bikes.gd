extends SceneTree
## The cyclists inside the traffic core (C++: tc::Sim K_BIKE, CityTraffic draws the bicycles, CityCrowd the riders).
## Headless, stepped as fast as it goes:
##   godot --headless --path . -s res://tests/traffic/test_bikes.gd [-- --minutes=20]
## Three runs with many cyclists among the cars (the whole city at its busiest hour; the city centre as in the game;
## residential streets with the parked cars pulling in and out). PASS needs, in every run: cyclists on the road, cars
## going past them inside their lane, no two road users overlapping at any check (cars and cyclists alike), nobody
## standing over 2 minutes away from a red light, no moving road user touching a parked car. And the same seed twice
## gives the same state with the cyclists in it.
const STREETS := "res://map_dc/coronado/city_kit/traffic/streets.bin"

func _initialize() -> void:
	var minutes := 20.0
	var only := ""
	var trace := -1      ## --trace=ID --only=PART: the history of one road user in one run
	var bikes_over := -1  ## --bikes=N: so many cyclists in every run (0: the same runs without them, to compare)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="): minutes = float(a.trim_prefix("--minutes="))
		if a.begins_with("--only="): only = a.trim_prefix("--only=")
		if a.begins_with("--trace="): trace = int(a.trim_prefix("--trace="))
		if a.begins_with("--bikes="): bikes_over = int(a.trim_prefix("--bikes="))
	if not ClassDB.class_exists(&"CityTraffic"):
		print("BIKES ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	var t: Object = ClassDB.instantiate(&"CityTraffic")
	if not t.load_streets(STREETS):
		print("BIKES ERROR cannot load %s" % STREETS); print("RESULT FAIL"); t.free(); quit(1); return
	var fails := 0
	## name, cars, camera, whole city?, cyclists, parking?
	var runs := [["whole city, busiest hour, 30 cyclists", 190, Vector3(0, 0, -600), true, 30, false],
		["city centre as in the game, 12 cyclists", 80, Vector3(0, 6, -600), false, 12, false],
		["residential streets with parking, 12 cyclists", 80, Vector3(-800, 4, -1050), false, 12, true]]
	t.set(&"debug_car", trace)
	for r: Array in runs:
		if only != "" and not String(r[0]).contains(only): continue
		t.set(&"cyclists", int(r[4]) if bikes_over < 0 else bikes_over)
		var t0 := Time.get_ticks_msec()
		var d: Dictionary = t.run_test(int(r[1]), minutes, 7, r[2], bool(r[3]), false, 1.0, bool(r[5]))
		var ok: bool = (bikes_over == 0 or (int(d.bikes_most) >= mini(int(r[4]), 4) and int(d.bike_squeezes) > 0)) and int(d.overlaps_car_car) == 0 and int(d.stuck_over_2min_most) == 0 and int(d.get("touching_parked", 0)) == 0
		if not ok: fails += 1
		print("BIKES run '%s': %s | %.0f traffic minutes in %.1f s" % [String(r[0]), "ok" if ok else "FAIL", minutes, (Time.get_ticks_msec() - t0) / 1000.0])
		print("BIKES   cyclists at most %d at once, %d put on the road; cars went past one inside their lane %d times | cars most %d | mean speed of all %.1f km/h" % [int(d.bikes_most), int(d.bikes_spawned), int(d.bike_squeezes), int(d.cars_most), float(d.mean_speed_kmh)])
		print("BIKES   overlapping pairs %d, standing over 2 min not at a red %d%s, a moving one touching a parked car %d (all must be 0) | crashes %d, hard brakes %d, honks %d" % [int(d.overlaps_car_car), int(d.stuck_over_2min_most), "" if int(d.stuck_over_2min_most) == 0 else " (longest %.0f s at %s, why %d, id %d)" % [float(d.stuck_longest_s), str(d.stuck_at), int(d.stuck_why), int(d.stuck_id)], int(d.get("touching_parked", 0)), int(d.crashes), int(d.hard_brakes), int(d.honks)])
		var tr: Array = d.get("trace", [])
		for k in tr.size(): if k % 6 == 0: print("BIKES     trace: %s" % tr[k])
		if not ok:
			for c: Dictionary in d.get("standing", []): print("BIKES     standing: %s" % str(c).left(1200))
			for tc: String in d.get("touch_cases", []): print("BIKES     touch: %s" % tc)
	if only != "": t.free(); print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails)); quit(1 if fails else 0); return
	t.set(&"cyclists", 20)
	var a: Dictionary = t.run_test(80, 3.0, 11, Vector3(0, 6, -600), false, true, 2.0)
	var b: Dictionary = t.run_test(80, 3.0, 11, Vector3(0, 6, -600), false, true, 2.0)
	var same: bool = int(a.hash) == int(b.hash) and int(a.bikes_spawned) > 0
	if not same: fails += 1
	print("BIKES the same seed twice with %d cyclists: %s (hash %d / %d)" % [int(a.bikes_spawned), "the same state" if same else "DIFFERENT", int(a.hash), int(b.hash)])
	t.free()
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
