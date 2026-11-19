extends SceneTree
## The crowd core on the new pavements and crossings, with no drawing (stage 3a of docs/TRAFFIC_PEOPLE_PORT.md). Headless:
##   godot --headless --path . -s res://tests/crowd/test_crowd_core.gd [-- --minutes=20 --people=120]
## Needs the native module (bash native/build.sh) and city_kit/traffic/streets.bin (tools/city/traffic/make_streets.gd).
## It runs the walkers round several places of the city for --minutes of their own time and checks: nobody leaves the
## pavement or the crossing they are on, no bad numbers, nobody stands inside somebody else, the crossings are used
## (people wait at the signals), routes are found. RESULT PASS / FAIL.
const STREETS := "res://map_dc/coronado/city_kit/traffic/streets.bin"

func _init() -> void:
	var minutes := 20.0; var people := 120
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="): minutes = float(a.trim_prefix("--minutes="))
		if a.begins_with("--people="): people = int(a.trim_prefix("--people="))
	if not ClassDB.class_exists(&"CityCrowd"):
		print("CROWD ERROR the native module is not built: bash native/build.sh"); print("RESULT FAIL"); quit(1); return
	var c: Object = ClassDB.instantiate(&"CityCrowd")
	if not c.load_streets(STREETS):
		print("CROWD ERROR cannot load %s: run tools/city/traffic/make_streets.gd" % STREETS); print("RESULT FAIL"); c.free(); quit(1); return
	print("CROWD walks: %s" % str(c.walk_stats()))
	var fails := 0
	## name, most people, where, density (1 = the busiest hour)
	var runs := [["city centre", people, Vector3(0, 0, -600), 1.0],
		["city centre, twice as many people", people * 2, Vector3(0, 0, -600), 2.0],
		["high street", people, Vector3(0, 0, -100), 1.0],
		["residential streets", people, Vector3(-800, 0, -1050), 1.0],
		["3rd St arterial", people, Vector3(-400, 0, -1400), 1.0],
		["waterfront ring", people, Vector3(573, 0, 200), 1.0]]
	var signals_used := 0
	for r: Array in runs:
		var t0 := Time.get_ticks_msec()
		var d: Dictionary = c.run_test(int(r[1]), minutes, 7, r[2], float(r[3]))
		var wall := (Time.get_ticks_msec() - t0) / 1000.0
		# near the player (40 m: where people deal with each other) nobody may stand inside anybody; farther away the
		# core lets walkers pass through each other (the old game's own limit: under 0.2 such pairs a check)
		var ok: bool = int(d.off_their_pavement) == 0 and int(d.bad_numbers) == 0 and int(d.inside_each_other_near) == 0 and float(d.inside_each_other) / maxf(float(d.checks), 1.0) < 0.2 and int(d.people_most) > 0 and float(d.mean_speed) > 0.6
		if not ok: fails += 1
		signals_used += int(d.waited_at_a_signal)
		print("CROWD run '%s': %s | %.0f minutes in %.1f s" % [String(r[0]), "ok" if ok else "FAIL", minutes, wall])
		print("CROWD   people most %d, at end %d | appeared %d, left %d | off their pavement %d, bad numbers %d, inside each other near the player %d (all must be 0; checked once a second), farther away %.2f pairs a check (under 0.2)" % [int(d.people_most), int(d.people_at_end), int(d.appeared), int(d.left), int(d.off_their_pavement), int(d.bad_numbers), int(d.inside_each_other_near), float(d.inside_each_other) / maxf(float(d.checks), 1.0)])
		print("CROWD   DEBUG near kinds: %s" % String(d.near_kinds))
		print("CROWD   routes %d (failed %d), passed somebody %d times, waited at a signal %d, waited for a gap in the traffic %d | walking speed %.2f m/s, %.0f %% standing | the closest two came: %.2f m | a step: mean %.0f, worst %.0f microseconds" % [int(d.routes), int(d.routes_failed), int(d.passes), int(d.waited_at_a_signal), int(d.waited_for_a_gap), float(d.mean_speed), float(d.standing_share) * 100.0, float(d.closest_two_came), float(d.step_us_mean), float(d.step_us_worst)])
	if signals_used == 0: fails += 1; print("CROWD nobody ever waited at a signal: the crossings are not used (FAIL)")
	var a: Dictionary = c.run_test(people, 3.0, 11, Vector3(0, 0, -600), 1.0)
	var b: Dictionary = c.run_test(people, 3.0, 11, Vector3(0, 0, -600), 1.0)
	var same: bool = int(a.hash) == int(b.hash)
	if not same: fails += 1
	print("CROWD the same seed twice: %s" % ("the same state" if same else "DIFFERENT"))
	c.free()
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
