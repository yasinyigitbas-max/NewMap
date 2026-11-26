extends SceneTree
## Stage 1 test: the body alone on the measured course.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage1.gd [-- --minutes=10]
## Every line is one of the Stage 1 acceptance tests of the report (Part 2, "Build order").

const GROUND := 0
const STEEP := 1
const AIR := 3
const WALK := 1.45          # the body's own walking speed (body.gd WALK; it was 1.4 until 26 Nov, when the body's was
                            # brought to the study's "1.27 to 1.46 m/s" together with its cadence and stride)
const RUN := 4.5

var fails := 0
var lab: Node3D
var body: CharacterBody3D
var tape: Node
var stations: Array


const TURN_ROUND_MORE := 0.8    # seconds: see test_kerbs_and_stairs

func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("PASS  " if cond else "FAIL  ") + what)


func _initialize() -> void:
	_run.call_deferred()


func st(label: String) -> Dictionary:
	for s: Dictionary in stations:
		if s["label"] == label:
			return s
	push_error("no station " + label)
	return {}


## Put the body at `at`, let it settle, play `segments` ([seconds, mx, mz, yaw_deg, run]) and return one record a tick.
func drive(at: Vector3, segments: Array, until_y := -1000.0, until_below := false) -> Array:
	lab.call(&"place", at)
	body.rotation.y = 0.0
	for i in 20:
		await physics_frame
	tape.call(&"make", segments)
	tape.call(&"replay")
	var rec: Array = []
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		rec.append({"p": body.global_position, "s": int(body.get(&"state")), "v": (body.get(&"hvel") as Vector3).length(), "t": int(body.get(&"terrain"))})
		# stairs: the stick is let go when he arrives, however long the stairs took
		if until_y > -999.0 and (body.global_position.y <= until_y if until_below else body.global_position.y >= until_y):
			tape.call(&"stop")
			for i in 90:
				await physics_frame
				rec.append({"p": body.global_position, "s": int(body.get(&"state")), "v": (body.get(&"hvel") as Vector3).length()})
			break
	return rec


func max_step(rec: Array) -> float:
	var m := 0.0
	for i in range(1, rec.size()):
		m = maxf(m, absf((rec[i]["p"] as Vector3).y - (rec[i - 1]["p"] as Vector3).y))
	return m


func count_state(rec: Array, state: int) -> int:
	var n := 0
	for r: Dictionary in rec:
		if r["s"] == state:
			n += 1
	return n


func last(rec: Array) -> Vector3:
	return rec[rec.size() - 1]["p"]


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 3:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	stations = (lab.get(&"course") as Node3D).get(&"stations")
	# Stage 6: "Stage 1 tests pass in crouch". Run with `-- --crouch`: the same tests with crouch held throughout.
	if OS.get_cmdline_user_args().has("--crouch"):
		tape.set(&"hold_crouch", true)
		print("WITH CROUCH HELD")
	await test_kerbs_and_stairs()
	await test_steps()
	await test_ramps()
	await test_walls()
	await test_floors()
	await test_ledges()
	await test_random_walk()
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)


func test_kerbs_and_stairs() -> void:
	for label: String in ["kerb 0.10 m", "kerb 0.15 m", "kerb 0.20 m", "stairs 0.18 / 0.28 m x 10", "stairs 0.25 / 0.26 m x 8"]:
		var s := st(label)
		var dist := 3.0 + (float(s.get("tread", 0.0)) * float(s.get("steps", 0)) if s["kind"] == "stairs" else 0.0) + 1.5
		for run: bool in [false, true]:
			var t := dist / (RUN if run else WALK) + (1.3 if run else 0.7)
			if s["kind"] == "stairs":
				# stairs are taken a step at a time (0.51 s walking, 0.30 s running): allow for that
				t = 3.9 / (RUN if run else WALK) + float(s["steps"]) * (0.30 if run else 0.51) * 1.05 + (1.0 if run else 0.6)
			var segs: Array = [[t, 0.0, -1.0, 0.0, run]]
			if run and s["kind"] == "kerb":
				segs = [[1.5, 0.0, -1.0, 0.0, true], [1.5, 0.0, 0.0, 0.0, false]]     # a burst, then let go: stops on the kerb
			var stairs: bool = s["kind"] == "stairs"
			var up := await drive(s["start"], segs, float(s["top"]) - 0.002 if stairs else -1000.0)
			var top_ok := absf(last(up).y - float(s["top"])) < 0.01
			# (coming back he first turns round on the spot: since 26 Nov that takes the study's "about 3 to 4 steps",
			# 1.8 s, where it took 1.0 s; the time allowed is longer by that much. What is checked is unchanged.)
			var down := await drive(last(up), [[t + TURN_ROUND_MORE, 0.0, 1.0, 0.0, run]], 0.002 if stairs else -1000.0, true)
			var back_ok := absf(last(down).y) < 0.01
			var in_air := count_state(up, AIR) + count_state(up, 2)
			var pace := ""
			if s["kind"] == "stairs":
				var a := -1
				var b := -1
				for i in up.size():
					var y := (up[i]["p"] as Vector3).y
					if a < 0 and y > float(s["top"]) * 0.2:
						a = i
					if b < 0 and y > float(s["top"]) * 0.8:
						b = i
				pace = "; %.2f s a step going up" % ((b - a) / 60.0 / (float(s["steps"]) * 0.6))
			ok(top_ok and back_ok and max_step(up) <= 0.045 and max_step(down) <= 0.055 and in_air == 0,
					"%s, %s: up to %.2f m and back; biggest height step %.1f cm up, %.1f cm down; ticks off the ground going up %d, coming down %d%s" % [
					label, "run" if run else "walk", last(up).y, max_step(up) * 100.0, max_step(down) * 100.0, in_air, count_state(down, AIR), pace])


func test_steps() -> void:
	var climbed: Array[String] = []
	var blocked: Array[String] = []
	var bad: Array[String] = []
	for i in 11:
		var h := 0.10 + 0.05 * i
		var s := st("step %.2f m" % h)
		for run: bool in [false, true]:
			var segs: Array = [[6.0, 0.0, -1.0, 0.0, run]]
			if h <= 0.305:
				segs = [[1.35, 0.0, -1.0, 0.0, true], [1.5, 0.0, 0.0, 0.0, false]] if run else [[4.6 / WALK, 0.0, -1.0, 0.0, false]]
			var rec := await drive(s["start"], segs)
			var end := last(rec)
			if h <= 0.305:
				if absf(end.y - h) > 0.01:
					bad.append("step %.2f %s: ended at %.3f m, should be on top" % [h, "run" if run else "walk", end.y])
				elif not run:
					climbed.append("%.2f" % h)
			else:
				var mid: Vector3 = rec[240]["p"]
				var creep := absf(end.y - mid.y) + absf(end.z - mid.z)
				if end.y > 0.02 or end.z < -3.0 + 0.2 or creep > 0.01:
					bad.append("step %.2f %s: should stop it, ended y %.3f z %.3f, crept %.3f m in 2 s" % [h, "run" if run else "walk", end.y, end.z, creep])
				elif not run:
					blocked.append("%.2f" % h)
	ok(bad.is_empty(), "single steps: climbs %s; stopped by %s, with no creeping" % [", ".join(climbed), ", ".join(blocked)])
	for b in bad:
		print("        " + b)


func test_ramps() -> void:
	for deg: int in [5, 10, 19]:
		var s := st("ramp %d deg" % deg)
		for run: bool in [false, true]:
			# uphill he gains height at 0.35 m/s walking and 1.0 m/s running at most (the steep-ground research)
			var sp := minf(RUN if run else WALK, (1.0 if run else 0.35) / tan(deg_to_rad(float(deg))))
			var rec := await drive((s["start"] as Vector3) + Vector3(0.0, 0.0, 12.0), [[60.0, 0.0, -1.0, 0.0, run]], 1.5 - 0.002)
			var lo := 99.0
			var hi := 0.0
			for r: Dictionary in rec:
				var y := (r["p"] as Vector3).y
				if y > 0.9 and y < 1.3:     # the upper part: what speed he came in with is spent by then
					lo = minf(lo, r["v"])
					hi = maxf(hi, r["v"])
			ok(absf(last(rec).y - 1.5) < 0.02 and lo > sp * 0.97 and hi < sp * 1.03 and count_state(rec, GROUND) == rec.size(),
					"ramp %d deg, %s: reaches the top (%.2f m); speed on the ramp %.2f to %.2f m/s (wanted %.2f); ticks not on ground %d" % [deg, "run" if run else "walk", last(rec).y, lo, hi, sp, rec.size() - count_state(rec, GROUND)])
	# steep ground: 30 degrees is walked leaning in, 45 degrees is climbed on hands and feet, 60 cannot be stood on
	for deg: int in [30, 45]:
		var s := st("ramp %d deg" % deg)
		for run: bool in [false, true]:
			var rec := await drive(s["start"], [[40.0, 0.0, -1.0, 0.0, run]], 1.5 - 0.002)
			var lo := 99.0
			var hi := 0.0
			var kind := 0
			for r: Dictionary in rec:
				var y := (r["p"] as Vector3).y
				if y > 0.9 and y < 1.3:     # the upper part: what speed he came in with is spent by then
					lo = minf(lo, r["v"])
					hi = maxf(hi, r["v"])
					kind = maxi(kind, int(r["t"]))
			var want := 1 if deg == 30 else 2
			# (put back on 26 Nov: for a day this check was an average rate of climb "within 30 %", to suit a clip
			# that set the body's pace. The study's Stage 1 asks for a steady speed, and the body alone sets it.)
			ok(absf(last(rec).y - 1.5) < 0.02 and kind == want and count_state(rec, STEEP) == 0 and hi - lo < 0.05,
					"ramp %d deg, %s: reaches the top (%.2f m) %s at a steady %.2f m/s along the ground (%.2f m/s upward); never 'too steep' (OUTSIDE THE STUDY: kept at Yasin's word)" % [
					deg, "run" if run else "walk", last(rec).y, "leaning in" if kind == 1 else ("on hands and feet" if kind == 2 else "as on the flat"), hi, hi * tan(deg_to_rad(deg))])
	var s60 := st("ramp 60 deg")
	var rec60 := await drive(s60["start"], [[6.0, 0.0, -1.0, 0.0, true], [3.0, 0.0, 0.0, 0.0, false]])
	var peak := 0.0
	for r: Dictionary in rec60:
		peak = maxf(peak, (r["p"] as Vector3).y)
	ok(peak < 0.5 and last(rec60).y < 0.15 and count_state(rec60, STEEP) > 0,
			"ramp 60 deg: cannot be climbed (highest %.2f m of 1.50), slides back to the ground (ends at %.2f m), state 'too steep' for %d ticks" % [peak, last(rec60).y, count_state(rec60, STEEP)])


func test_walls() -> void:
	var s := st("thin wall 1.80 m")
	var worst_speed := 0.0
	var deepest := 0.0
	var bad: Array[String] = []
	for ang: int in [0, 15, 30, 45, 60, 75, -30, -60]:
		for run: bool in [false, true]:
			var sp := RUN if run else WALK
			var dir := Vector3(0.0, 0.0, -1.0).rotated(Vector3.UP, deg_to_rad(float(-ang)))
			var start: Vector3 = Vector3(float(s["x"]) - dir.x * 0.6, 0.0, -2.75) - dir * (6.0 if run else 2.0)
			var rec := await drive(start, [[4.0, 0.0, -1.0, float(-ang), run]])
			var slide: Array[float] = []
			var jitter := 0.0
			for i in rec.size():
				var p: Vector3 = rec[i]["p"]
				worst_speed = maxf(worst_speed, float(rec[i]["v"]) / sp)
				if absf(p.x - float(s["x"])) < 1.4:
					deepest = minf(deepest, p.z - (-3.0 + 0.25))
				# while pressed on the wall face
				if p.z < -3.0 + 0.26 and absf(p.x - float(s["x"])) < 0.9 and i > 0:
					slide.append(float(rec[i]["v"]))
					jitter = maxf(jitter, absf(float(rec[i]["v"]) - float(rec[i - 1]["v"])))
			var full := sp * absf(sin(deg_to_rad(ang)))
			if slide.size() > 12:
				var jerk := 0.0
				var over := 0.0
				for i in range(12, slide.size()):
					jerk = maxf(jerk, absf(slide[i] - 2.0 * slide[i - 1] + slide[i - 2]))
					over = maxf(over, slide[i] - full)
				var end_v: float = slide[slide.size() - 1]
				if jerk > 0.05 or over > maxf(0.05, full * 0.03) or (ang != 0 and end_v < full * 0.5):
					bad.append("%d deg %s: slides at up to %.2f m/s over the right speed (%.2f), ends at %.2f, speed jerks %.3f m/s a tick" % [ang, "run" if run else "walk", over, full, end_v, jerk])
			elif ang != 0 and absf(ang) < 70:
				bad.append("%d deg %s: only %d ticks on the wall" % [ang, "run" if run else "walk", slide.size()])
	ok(bad.is_empty() and worst_speed <= 1.02 and deepest > -0.02,
			"walls at 0 to 75 degrees, walk and run: slides no faster than the right speed, with no jitter; top speed %.0f %% of wanted; deepest into the wall %.1f cm" % [worst_speed * 100.0, -deepest * 100.0])
	for b in bad:
		print("        " + b)


func test_floors() -> void:
	for label: String in ["floor: 36 separate pieces", "floor: one triangle mesh"]:
		var s := st(label)
		for run: bool in [false, true]:
			var rec := await drive(s["start"] + Vector3(-0.5, 0.0, 0.0), [[(16.0) / (RUN if run else WALK), 0.06, -1.0, 0.0, run]])
			var lo := 99.0
			var hi := -99.0
			var off := 0
			for r: Dictionary in rec:
				var p: Vector3 = r["p"]
				if p.z < -3.6 and p.z > -14.4:
					lo = minf(lo, p.y)
					hi = maxf(hi, p.y)
					if r["s"] != GROUND:
						off += 1
			ok(hi - lo < 0.002 and absf(hi - 0.1) < 0.005 and off == 0, "%s, %s: height stays flat (%.1f mm of change), on ground every tick" % [label, "run" if run else "walk", (hi - lo) * 1000.0])


func test_ledges() -> void:
	# low edges are stepped down without leaving the ground
	for h: float in [0.20, 0.30]:
		var s := st(("kerb %.2f m" if h < 0.25 else "step %.2f m") % h)
		var rec := await drive(Vector3(float(s["x"]), h, -4.5), [[3.0 + TURN_ROUND_MORE, 0.0, 1.0, 0.0, false]])
		ok(count_state(rec, AIR) == 0 and absf(last(rec).y) < 0.01 and max_step(rec) <= 0.055, "walking off a %.2f m edge: steps down, never 'in air', biggest height step %.1f cm" % [h, max_step(rec) * 100.0])
	# high edges: in the air at once, on the ground at once on landing
	for label: String in ["deep wall 1.00 m", "deep wall 2.20 m"]:
		var s := st(label)
		var h := float(s["top"])
		for run: bool in [false, true]:
			var rec := await drive(Vector3(float(s["x"]), h, -4.5), [[4.0, 0.0, 1.0, 0.0, run]])
			var left := -1
			var air_from := -1
			var landed := -1
			for i in rec.size():
				var p: Vector3 = rec[i]["p"]
				if left < 0 and p.z > -3.0 + 0.15:
					left = i
				if air_from < 0 and rec[i]["s"] == AIR:
					air_from = i
				if air_from >= 0 and landed < 0 and rec[i]["s"] == GROUND:
					landed = i
			var bounce := 0
			for i in range(maxi(landed, 0), rec.size()):
				if rec[i]["s"] != GROUND:
					bounce += 1
			ok(left >= 0 and air_from >= 0 and air_from - left <= 2 and landed > air_from and bounce == 0 and absf(last(rec).y) < 0.01 and absf((rec[landed]["p"] as Vector3).y) < 0.03,
					"off a %.2f m ledge, %s: 'in air' %d tick(s) after the probe leaves the edge, 'on ground' at landing (height %.3f m), no bounce" % [h, "run" if run else "walk", air_from - left, (rec[maxi(landed, 0)]["p"] as Vector3).y])


func test_random_walk() -> void:
	var minutes := 2.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			minutes = float(a.split("=")[1])
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	lab.call(&"place", Vector3(60.0, 0.0, 2.0))
	for i in 20:
		await physics_frame
	var ticks := int(minutes * 3600.0)
	var seg: Array = []
	var lowest := 0.0
	var highest := 0.0
	var travelled := 0.0
	var prev := body.global_position
	var stuck_windows := 0
	var worst_stuck := 0
	var mark := body.global_position
	var mark_tick := 0
	var states := [0, 0, 0, 0]
	var t := 0
	var left_course := false
	while t < ticks:
		var p := body.global_position
		# head for a random spot among the obstacles, so the walk goes over, onto and off things
		var goal := Vector3(rng.randf_range(0.0, 244.0), 0.0, rng.randf_range(-16.0, 3.0))
		if rng.randf() < 0.5:
			var near: Dictionary = stations[rng.randi_range(0, stations.size() - 1)]
			goal = (near["probe"] as Vector3) + Vector3(rng.randf_range(-1.5, 1.5), 0.0, rng.randf_range(-3.0, 3.0))
		var yaw := rad_to_deg(atan2(-(goal.x - p.x), -(goal.z - p.z))) + rng.randf_range(-20.0, 20.0)
		var dur := rng.randf_range(1.0, 5.0)
		if rng.randf() < 0.12:
			var onto: Dictionary = stations[rng.randi_range(0, stations.size() - 1)]
			lab.call(&"place", (onto["probe"] as Vector3) + Vector3(0.0, float(onto["top"]) + 0.02, 0.0))
			prev = body.global_position
			mark = prev
		tape.call(&"make", [[dur, 0.0, -1.0 if rng.randf() > 0.08 else 0.0, yaw, rng.randf() > 0.5]])
		tape.call(&"replay")
		while int(tape.get(&"mode")) == 2 and t < ticks:
			await physics_frame
			t += 1
			var q := body.global_position
			lowest = minf(lowest, q.y)
			highest = maxf(highest, q.y)
			travelled += q.distance_to(prev)
			prev = q
			states[int(body.get(&"state"))] += 1
			if q.y < -2.0 or absf(q.x - 120.0) > 140.0 or absf(q.z + 6.0) > 60.0:
				left_course = true
			if t - mark_tick >= 180:
				if q.distance_to(mark) < 0.02 and (tape.get(&"tape") as Array).size() > 0:
					stuck_windows += 1
					worst_stuck = maxi(worst_stuck, stuck_windows)
				else:
					stuck_windows = 0
				mark = q
				mark_tick = t
		if left_course:
			break
	ok(not left_course and lowest > -0.05 and worst_stuck < 4,
			"random walk for %.0f minutes (%d ticks): %.0f m travelled, up to %.2f m high; never fell through (lowest %.3f m), never left the course, longest time without moving %d s; ticks on ground %d, too steep %d, unsupported %d, in air %d" % [
			minutes, t, travelled, highest, lowest, worst_stuck * 3, states[0], states[1], states[2], states[3]])
