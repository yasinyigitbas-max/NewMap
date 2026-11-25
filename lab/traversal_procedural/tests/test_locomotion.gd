extends SceneTree
# Lab A step 4 test: standing, walking, running, starts, stops, turns. Prints the brief's numbers.
# godot --headless --fixed-fps 60 -s tests/test_locomotion.gd
var player
var results := []

func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	player = m.get_node("Player")
	run_all.call_deferred()

func frames(n: int, stick := Vector2.ZERO, run := false) -> Array:
	# returns per-frame samples
	var out := []
	for i in n:
		player.set_scripted_input(stick, run, true)
		await physics_frame
		var mt = player.get_metrics()
		out.append(mt)
	return out

func fresh(z := -2.0) -> void:
	player.set_scripted_input(Vector2.ZERO, false, true)
	player.teleport(Vector3(0, 0, z), 0.0)
	for i in 30:
		await physics_frame
	player.reset_metrics()

func time_to(samples: Array, cond: Callable) -> float:
	for i in samples.size():
		if cond.call(samples[i]):
			return (i + 1) / 60.0
	return -1.0

func bob(samples: Array) -> float:
	var lo = 1e9
	var hi = -1e9
	for s in samples:
		lo = min(lo, s.hips_y)
		hi = max(hi, s.hips_y)
	return (hi - lo) * 100.0

func count(samples: Array, cond: Callable) -> int:
	var c = 0
	for s in samples:
		if cond.call(s):
			c += 1
	return c

func report(name: String, extra: Dictionary) -> void:
	var m = player.get_metrics()
	var line = "%-22s slide %5.2f cm | hips pop %4.2f cm/f | joints past range %3d (knee %d ankle %d hip %d elbow %d) | latency %5.0f ms" % [
		name, m.slide_max_cm, m.hips_pop_max_cm, m.joint_violations, m.knee_violations, m.ankle_violations, m.hip_violations,
		m.elbow_violations, m.latency_max_ms]
	for k in extra:
		var v = extra[k]
		line += " | %s %s" % [k, ("%.2f" % v) if typeof(v) == TYPE_FLOAT else str(v)]
	line += "\n      max: knee %.0f ankle up %.0f down %.0f hip flex %.0f ext %.0f elbow %.0f" % [m.knee_max_deg, m.ankle_up_max_deg, m.ankle_down_max_deg, m.hip_flex_max_deg, m.hip_ext_max_deg, m.elbow_max_deg]
	if m.slide_max_cm > 1.0 or m.hips_pop_max_cm > 2.0:
		line += "\n      (worst slide at frame %d foot %d contact %d; worst pop at frame %d)" % [m.slide_frame, m.slide_foot, m.slide_kind, m.pop_frame]
	print(line)
	results.append({"name": name, "m": m, "extra": extra})

func run_all():
	var walk = player.walk_speed
	var runv = player.run_speed
	await fresh()
	var s = await frames(180)
	report("idle 3 s", {"bob_cm": bob(s)})

	await fresh()
	s = await frames(240, Vector2(0, 1))
	var t95 = time_to(s, func(x): return x.speed >= 0.95 * walk)
	var st = s[0].steps
	var steps_to = -1
	for x in s:
		if x.speed >= 0.95 * walk:
			steps_to = x.steps
			break
	var steady = s.slice(120, 240)
	var airborne = count(steady, func(x): return not x.planted_l and not x.planted_r)
	var st0 = steady[0].steps
	var cadence = (steady[-1].steps - st0) / 2.0 * 60.0
	report("walk start + 4 s", {"t_full_s": t95, "steps_to_full": steps_to, "bob_cm": bob(steady), "both_feet_off_frames": airborne, "cadence_spm": cadence, "step_m": walk / max(cadence / 60.0, 0.01)})

	player.reset_metrics()
	s = await frames(150)
	var tstop = time_to(s, func(x): return x.speed < 0.05)
	var tidle = time_to(s, func(x): return not x.active)
	report("walk stop", {"t_stop_s": tstop, "t_feet_set_s": tidle, "steps": s[-1].steps})

	await fresh()
	s = await frames(300, Vector2(0, 1), true)
	t95 = time_to(s, func(x): return x.speed >= 0.95 * runv)
	steps_to = -1
	for x in s:
		if x.speed >= 0.95 * runv:
			steps_to = x.steps
			break
	steady = s.slice(180, 300)
	var dbl = count(steady, func(x): return x.planted_l and x.planted_r)
	var fl = count(steady, func(x): return not x.planted_l and not x.planted_r)
	cadence = (steady[-1].steps - steady[0].steps) / 2.0 * 60.0
	report("run start + 5 s", {"t_full_s": t95, "steps_to_full": steps_to, "bob_cm": bob(steady), "both_down_frames": dbl, "flight_frames": fl, "cadence_spm": cadence, "step_m": runv / max(cadence / 60.0, 0.01)})

	player.reset_metrics()
	s = await frames(150)
	tstop = time_to(s, func(x): return x.speed < 0.05)
	tidle = time_to(s, func(x): return not x.active)
	report("run stop", {"t_stop_s": tstop, "t_feet_set_s": tidle, "steps": s[-1].steps})

	# turns
	await fresh()
	await frames(120, Vector2(0, 1))
	player.reset_metrics()
	s = await frames(120, Vector2(1, 0))
	var t_turn = time_to(s, func(x): return abs(wrapf(x.yaw - (-PI / 2), -PI, PI)) < deg_to_rad(10))
	report("walk turn 90 right", {"t_turned_s": t_turn})

	await fresh()
	await frames(180, Vector2(0, 1), true)
	player.reset_metrics()
	s = await frames(180, Vector2(0, -1), true)
	t_turn = time_to(s, func(x): return abs(wrapf(x.yaw - PI, -PI, PI)) < deg_to_rad(10))
	var t_back = time_to(s, func(x): return x.speed > 0.9 * runv and abs(wrapf(x.yaw - PI, -PI, PI)) < deg_to_rad(10))
	report("run turn 180", {"t_turned_s": t_turn, "t_full_speed_back_s": t_back})

	await fresh(-62.0) # open ground behind the start: no obstacle within the circle
	s = await frames(240, Vector2(0, 1), true)
	player.reset_metrics()
	var circle := []
	for i in 360:
		var a = i / 60.0 * 1.2
		player.set_scripted_input(Vector2(sin(a), cos(a)), true, true)
		await physics_frame
	report("run circle 6 s", {})

	await fresh()
	for i in 240:
		var a = i / 60.0 * 1.5
		player.set_scripted_input(Vector2(0, 0.4 + 0.3 * sin(a)), false, true)
		await physics_frame
	report("analog walk 0.1-0.7", {})

	await fresh()
	for k in 6:
		await frames(25, Vector2(0, 1), k % 2 == 1)
		await frames(20)
	report("stop-go jitter", {})

	# world contract: debris (layer 7) is never ground. Walk over the slab at z 30: the feet stay at ground level.
	await fresh(26.0)
	var max_ank = 0.0
	for i in 200:
		player.set_scripted_input(Vector2(0, 1), false, true)
		await physics_frame
		var m = player.get_metrics()
		if abs(player.global_position.z - 30.0) < 0.5:
			max_ank = max(max_ank, min(m.ankle_l.y, m.ankle_r.y))
	print("contract: debris ignored by probes: lowest ankle over the slab %.3f m (ground ankle ~0.16-0.17) -> %s" % [max_ank, "PASS" if max_ank < 0.2 else "FAIL"])

	var worst_slide = 0.0
	var worst_pop = 0.0
	var viol = 0
	for r in results:
		worst_slide = max(worst_slide, r.m.slide_max_cm)
		worst_pop = max(worst_pop, r.m.hips_pop_max_cm)
		viol += r.m.joint_violations
	print("SUMMARY worst slide %.2f cm, worst hips pop %.2f cm/frame, joints past range %d" % [worst_slide, worst_pop, viol])
	quit()
