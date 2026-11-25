extends SceneTree
# Lab A step 5 test: kerbs, single steps, stairs, slopes, the real street. Prints the brief's numbers per course item
# and done / refused / failed. godot --headless --fixed-fps 60 -s tests/test_terrain.gd [-- filter]
var player
var lines := []
var filter := ""

func _initialize():
	var a = OS.get_cmdline_user_args()
	if a.size() > 0: filter = a[0]
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	player = m.get_node("Player")
	run_all.call_deferred()

# Walks (or runs) from `from` toward `to` with the stick pointing at the goal. Done when within 0.35 m of the goal (xz)
# and at its height (+-0.12 m); refused when the body stops short against something (no progress for 1.5 s); failed
# when the time runs out otherwise or the hips drop below 0.6 m above the feet (a collapse).
func item(name: String, from: Vector3, to: Vector3, run := false, limit_s := 30.0, goal_y = null) -> void:
	if filter != "" and not name.contains(filter):
		return
	var yaw = atan2(to.x - from.x, to.z - from.z)
	player.set_scripted_input(Vector2.ZERO, false, true)
	player.teleport(from, yaw)
	for i in 30:
		await physics_frame
	player.reset_metrics()
	var result = "failed (time)"
	var best = 1e9
	var stuck = 0
	var low_hips = 1e9
	var max_y = -1e9
	var stair_frames = 0
	var slope_max = 0.0
	var t = 0
	while t < int(limit_s * 60):
		var p = player.global_position
		var d = Vector2(to.x - p.x, to.z - p.z)
		var dist = d.length()
		if dist < 0.35 and (goal_y == null or abs(p.y - goal_y) < 0.12):
			result = "done"
			break
		# stick in camera space: the camera looks along +Z (yaw 0), so world +X is stick -x
		var st = Vector2(-d.x, d.y).normalized()
		player.set_scripted_input(st, run, true)
		await physics_frame
		t += 1
		var m = player.get_metrics()
		low_hips = min(low_hips, m.hips_y)
		max_y = max(max_y, p.y)
		if m.stairs: stair_frames += 1
		slope_max = max(slope_max, abs(m.slope_deg))
		if dist < best - 0.01:
			best = dist
			stuck = 0
		else:
			stuck += 1
		if stuck > 90:
			result = "refused (stopped %.2f m short)" % dist
			break
		if m.hips_y < 0.6:
			result = "failed (collapse)"
			break
	var m = player.get_metrics()
	var line = "%-26s %-28s %4.1f s | slide %5.2f cm | pop %4.2f cm/f | joints %3d | edge landings %d | steps %3d | low hips %.2f" % [
		name, result, t / 60.0, m.slide_max_cm, m.hips_pop_max_cm, m.joint_violations, m.edge_landings, m.steps, low_hips]
	if m.slide_max_cm > 1.0 or m.hips_pop_max_cm > 2.0:
		line += " | (slide f%d foot %d kind %d; pop f%d)" % [m.slide_frame, m.slide_foot, m.slide_kind, m.pop_frame]
	if m.joint_violations > 0:
		line += " | (knee %d ankle %d hip %d elbow %d; max ankle up %.0f down %.0f hip ext %.0f)" % [m.knee_violations, m.ankle_violations, m.hip_violations, m.elbow_violations, m.ankle_up_max_deg, m.ankle_down_max_deg, m.hip_ext_max_deg]
	if stair_frames > 0: line += " | stairs seen %.1f s" % (stair_frames / 60.0)
	if slope_max > 2.0: line += " | slope %.0f deg" % slope_max
	print(line)
	lines.append({"name": name, "result": result, "m": m})

func run_all():
	# kerbs and single steps: up onto the 3 m slab and down off it (lane A, x 8)
	var k = 0
	for h in [10, 12, 15, 16, 20, 24]:
		var z0 = 4.0 + 6.0 * k
		await item("kerb %d cm walk" % h, Vector3(8, 0, z0 - 2.0), Vector3(8, 0, z0 + 4.5))
		await item("kerb %d cm run" % h, Vector3(8, 0, z0 - 4.0), Vector3(8, 0, z0 + 5.0), true)
		k += 1
	# stairs (lane B, x 14): 17/28 x8 up, landing, down; 19/25 x8; the stoop 3 x 16.7 up to a porch
	await item("stairs 17/28 up+down walk", Vector3(14, 0, 2.0), Vector3(14, 0, 11.5), false, 40.0, 0.0)
	await item("stairs 17/28 up+down run", Vector3(14, 0, 0.5), Vector3(14, 0, 11.5), true, 40.0, 0.0)
	await item("stairs 17/28 up only", Vector3(14, 0, 2.0), Vector3(14, 1.36, 7.2), false, 30.0, 1.36)
	await item("stairs 19/25 up+down walk", Vector3(14, 0, 13.0), Vector3(14, 0, 21.5), false, 40.0, 0.0)
	await item("stoop 3 x 16.7 to porch", Vector3(14, 0, 23.0), Vector3(14, 0.5, 26.5), false, 20.0, 0.5)
	# ramps (lane C, x 20): up to the top and stop; then down from the top
	k = 0
	for dgr in [5, 10, 15, 25]:
		var z0 = 4.0 + 12.0 * k
		var rise = 6.0 * tan(deg_to_rad(dgr))
		await item("ramp %d deg up" % dgr, Vector3(20, 0, z0 - 1.5), Vector3(20, rise, z0 + 7.0), false, 20.0, rise)
		await item("ramp %d deg down" % dgr, Vector3(20, rise, z0 + 7.0), Vector3(20, 0, z0 - 1.5), false, 20.0, 0.0)
		k += 1
	await item("ramp 15 deg up run", Vector3(20, 0, 28.0 - 3.0), Vector3(20, 6.0 * tan(deg_to_rad(15)), 35.0), true, 20.0)
	await item("cross-slope 10 deg along", Vector3(26, 0.35, 4.5), Vector3(26, 0.35, 19.5), false, 20.0)
	# the real street (city kit s_apt, kerb 15 cm): road to walk and back, at an angle, and the porch stoop
	await item("real kerb up (road->walk)", Vector3(-62, 0, 30), Vector3(-68.0, 0.15, 30), false, 15.0, 0.15)
	await item("real kerb down (walk->road)", Vector3(-68.0, 0.15, 30), Vector3(-62, 0, 30), false, 15.0, 0.0)
	await item("real kerb up 40 deg angle", Vector3(-62, 0, 25), Vector3(-68.0, 0.15, 30), false, 15.0, 0.15)
	await item("real kerb run across", Vector3(-55, 0, 33), Vector3(-68.5, 0.15, 33), true, 15.0, 0.15)
	await item("real porch (coarse collision)", Vector3(-67.5, 0.15, 21.0), Vector3(-71.0, 0.65, 21.0), false, 15.0, 0.65)
	var done = 0
	var refused = 0
	var failed = 0
	var worst_slide = 0.0
	var worst_pop = 0.0
	var joints = 0
	var edges = 0
	for l in lines:
		if l.result == "done": done += 1
		elif l.result.begins_with("refused"): refused += 1
		else: failed += 1
		worst_slide = max(worst_slide, l.m.slide_max_cm)
		worst_pop = max(worst_pop, l.m.hips_pop_max_cm)
		joints += l.m.joint_violations
		edges += l.m.edge_landings
	print("SUMMARY %d items: done %d, refused %d, failed %d | worst slide %.2f cm | worst pop %.2f cm/f | joints past range %d | edge landings %d" % [
		lines.size(), done, refused, failed, worst_slide, worst_pop, joints, edges])
	quit()
