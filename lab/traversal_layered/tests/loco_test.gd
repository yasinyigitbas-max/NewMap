## Lab B locomotion tests (step 4). Headless, fixed 60 fps:
##   godot --headless --path . --fixed-fps 60 -s tests/loco_test.gd [-- <scenario>]
## Prints the brief's numbers per scenario: planted-foot slide (cm), hips pop (cm/frame), joints past the study's
## ranges (count), stick-to-response latency (ms), time to full speed (s), time to stop (s).
## Numbers can't judge feel: Yasin plays it (brief).
extends SceneTree

const DT := 1.0 / 60.0
var main; var p; var sk: Skeleton3D; var layer
var B := {}
var scen_list := []
var si := -1
var t := 0.0
var cur: Dictionary
var m: Dictionary
var results := []
var only := ""
var hinge := {}
var rest_knee := {}

## signed knee (study v2 1.3): + normal, - backward; sign from geometry
static func _knee_geom(hip: Vector3, knee: Vector3, ank: Vector3, ax: Vector3) -> float:
	ax = ax.normalized()
	var t := (knee - hip).normalized(); var s := (ank - knee).normalized()
	var tp := (t - ax * t.dot(ax)).normalized(); var sp := (s - ax * s.dot(ax)).normalized()
	var mag := rad_to_deg(acos(clamp(tp.dot(sp), -1.0, 1.0)))
	return mag if (ank - knee).dot(t.cross(ax).normalized()) < 0 else -mag

# scenarios: list of [time, dir_deg (0 = +Z, 90 = +X), speed]; the player starts facing +Z
func scenarios() -> Array:
	return [
		{"name": "walk start ahead, walk 3 s, stop", "steps": [[0.3, 0, 1.55], [3.3, 0, 0]], "len": 5.5, "target": 1.55},
		{"name": "walk start 90 left", "steps": [[0.3, 90, 1.55], [3.0, 90, 0]], "len": 5.0, "target": 1.55},
		{"name": "walk start 180 (behind)", "steps": [[0.3, 180, 1.55], [3.3, 180, 0]], "len": 5.5, "target": 1.55},
		{"name": "run start ahead, run 3 s, stop", "steps": [[0.3, 0, 4.2], [3.3, 0, 0]], "len": 5.5, "target": 4.2},
		{"name": "run start 90 right", "steps": [[0.3, -90, 4.2], [3.3, -90, 0]], "len": 5.5, "target": 4.2},
		{"name": "sprint (shift) 4.6", "steps": [[0.3, 0, 4.6], [3.3, 0, 0]], "len": 5.5, "target": 4.6},
		{"name": "slow walk (stick half) 1.1", "steps": [[0.3, 0, 1.1], [3.3, 0, 0]], "len": 5.5, "target": 1.1},
		{"name": "walk -> run -> walk", "steps": [[0.3, 0, 1.55], [2.0, 0, 4.2], [4.0, 0, 1.55], [5.5, 0, 0]], "len": 7.5, "target": 1.55},
		{"name": "run, reverse 180 (pivot)", "steps": [[0.3, 0, 4.2], [2.5, 180, 4.2], [4.5, 180, 0]], "len": 6.5, "target": 4.2},
		{"name": "walk, reverse 180", "steps": [[0.3, 0, 1.55], [2.5, 180, 1.55], [4.5, 180, 0]], "len": 6.5, "target": 1.55},
		{"name": "run, 90 turn right", "steps": [[0.3, 0, 4.2], [2.5, -90, 4.2], [4.5, -90, 0]], "len": 6.5, "target": 4.2},
		{"name": "run circle (stick sweeps)", "steps": [[0.3, 0, 4.2], [1.5, "sweep", 4.2], [5.5, "hold", 0]], "len": 7.5, "target": 4.2},
		{"name": "tap: start then release at once", "steps": [[0.3, 0, 1.55], [0.45, 0, 0]], "len": 2.5, "target": 1.55},
		{"name": "stop then go again", "steps": [[0.3, 0, 1.55], [2.5, 0, 0], [2.75, 0, 1.55], [4.5, 0, 0]], "len": 6.5, "target": 1.55},
	]

func _init():
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: only = a[0]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	p = main.get_node("Player")
	scen_list = scenarios()
	physics_frame.connect(_tick)

func _bones():
	sk = p.get_node("Body/Armature/Skeleton3D")
	layer = p.get_pose_layer()
	for n in ["Hips", "LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase", "RightUpLeg", "RightLeg", "RightFoot", "RightToeBase",
			"LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand", "Head"]:
		B[n] = sk.find_bone(n)
	layer.modification_processed.connect(_measure)
	# knee hinge per side (body left, perpendicular to the rest thigh, carried by the UpLeg) and the rest bone angle
	for side in ["Left", "Right"]:
		var g := sk.get_bone_global_rest(B[side + "UpLeg"])
		var t := (sk.get_bone_global_rest(B[side + "Leg"]).origin - g.origin).normalized()
		var ax := (Vector3(1, 0, 0) - t * t.dot(Vector3(1, 0, 0))).normalized()
		hinge[side] = g.basis.orthonormalized().inverse() * ax
		rest_knee[side] = _knee_geom(g.origin, sk.get_bone_global_rest(B[side + "Leg"]).origin, sk.get_bone_global_rest(B[side + "Foot"]).origin, g.basis.orthonormalized() * hinge[side])
	if OS.get_environment("LAB_LAYERS") != "": layer.set_layers(int(OS.get_environment("LAB_LAYERS")))

func _next():
	si += 1
	while si < scen_list.size() and only != "" and scen_list[si].name.find(only) < 0: si += 1
	if si >= scen_list.size():
		_report(); quit(); return
	cur = scen_list[si]
	t = -1.2  # settle with no input first, so every scenario starts from idle
	p.global_position = Vector3(-40 + 0.0, 0, 50)  # open ground, away from the course
	p.velocity = Vector3.ZERO
	m = {"slide_max": 0.0, "slide_sum": 0.0, "slides": 0, "pop_max": 0.0, "joint_bad": 0, "knee_back": 0, "ankle_up": 0,
		"knee_over": 0, "elbow": 0, "latency": -1.0, "t_full": -1.0, "t_stop": -1.0, "prev_h": null, "prev_dh": null,
		"lock": [null, null], "go_t": -1.0, "rel_t": -1.0, "base_head": null, "base_hips": null, "base_speed": 0.0,
		"switch0": p.get_switches(), "rel0": layer.get_releases(), "max_speed": 0.0, "mode_seq": [], "slide_at": "", "pop_at": ""}

func _tick():
	if sk == null:
		if p.is_ready_to_play(): _bones(); _next()
		return
	t += DT
	if t < 0.0:
		p.set_test_input(Vector2(0, 1), 0.0, true)
		if t > -0.05 and (p.get_mode() != 0 or p.get_speed() > 0.01): t = -0.3
		if t > -DT * 1.5:
			p.teleport(Vector3(-40, 0, 50), 0.0)
		return
	# input
	var dir := 0.0; var sp := 0.0
	var last_change := -1.0
	for s in cur.steps:
		if t >= s[0]:
			sp = s[2]; last_change = s[0]
			if s[1] is String:
				if s[1] == "sweep": dir = rad_to_deg((t - s[0]) * 1.4)
				else: dir = rad_to_deg((5.5 - 1.5) * 1.4)
			else: dir = s[1]
	var d := Vector2(sin(deg_to_rad(dir)), cos(deg_to_rad(dir)))
	p.set_test_input(d, sp, true)
	# first input: latency & time to full speed
	var first: Array = cur.steps[0]
	if t >= first[0] and m.go_t < 0:
		m.go_t = t
		m.base_hips = _wpos("Hips")
		m.base_head = layer.get_head_yaw_deg()
	if m.go_t >= 0 and m.latency < 0:
		var hp: Vector3 = _wpos("Hips")
		if hp.distance_to(m.base_hips) > 0.01 or abs(layer.get_head_yaw_deg() - m.base_head) > 2.0 or p.get_speed() > 0.05:
			m.latency = t - m.go_t
	if m.go_t >= 0 and m.t_full < 0 and p.get_speed() >= cur.target * 0.95:
		m.t_full = t - m.go_t
	m.max_speed = max(m.max_speed, p.get_speed())
	# release: time to stop
	var last: Array = cur.steps[cur.steps.size() - 1]
	if last[2] == 0 and t >= last[0]:
		if m.rel_t < 0: m.rel_t = t
		if m.t_stop < 0 and p.get_speed() < 0.05: m.t_stop = t - m.rel_t
	var mode: int = p.get_mode()
	if m.mode_seq.is_empty() or m.mode_seq[m.mode_seq.size() - 1] != mode: m.mode_seq.append(mode)
	if t >= cur.len:
		_finish(); _next()

func _wpos(n: String) -> Vector3:
	return sk.get_global_transform_interpolated() * sk.get_bone_global_pose(B[n]).origin

func _measure():
	if cur.is_empty() or t <= 0.05: return
	# 1. planted-foot slide: while the clip says a foot is down, its toe must not move (study 4.6/1)
	for s in 2:
		var toe := _wpos("LeftToeBase" if s == 0 else "RightToeBase")
		var ank := _wpos("LeftFoot" if s == 0 else "RightFoot")
		var gy: float = p.global_position.y
		var heel_up := ank.y - gy > 0.17 + 0.03  # ankle above its standing height (0.17 m on player_v3)
		var pt := toe if heel_up else ank
		if p.get_contact(s) and layer.get_foot_locked(s):
			if m.lock[s] == null: m.lock[s] = [pt, heel_up, 0.0]
			else:
				var prev: Array = m.lock[s]
				if prev[1] == heel_up:
					prev[2] += Vector2(pt.x - prev[0].x, pt.z - prev[0].z).length() * 100.0
				prev[0] = pt; prev[1] = heel_up
				if prev[2] > m.slide_max:
					m.slide_max = prev[2]; m.slide_at = "%.2fs %s" % [t, ["idle", "start", "loop", "stop", "pivot"][p.get_mode()]]
		else:
			m.lock[s] = null
	# 2. hips pop: change of the hips' per-frame motion (cm/frame) (study 4.6/5)
	var h := _wpos("Hips")
	if m.prev_h != null:
		var dh: Vector3 = h - m.prev_h
		if m.prev_dh != null:
			var pop: float = (dh - m.prev_dh).length() * 100.0
			if pop > m.pop_max:
				m.pop_max = pop; m.pop_at = "%.2fs %s" % [t, ["idle", "start", "loop", "stop", "pivot"][p.get_mode()]]
		m.prev_dh = dh
	m.prev_h = h
	if OS.get_environment("LAB_FEET") != "" and abs(t - float(OS.get_environment("LAB_FEET"))) < float(OS.get_environment("LAB_WIN") if OS.get_environment("LAB_WIN") != "" else "0.25"):
		var st := "%.3f m=%d " % [t, p.get_mode()]
		for s2 in 2:
			var sd := "Left" if s2 == 0 else "Right"
			var a := _wpos(sd + "Foot"); var tt := _wpos(sd + "ToeBase"); var tg: Vector3 = layer.get_foot_world(s2)
			st += "| %s c=%d ank=%s toe=%s tgt_err=%.1fcm " % [sd[0], int(p.get_contact(s2)), str(a.snapped(Vector3.ONE*0.001)), str(tt.snapped(Vector3.ONE*0.001)), a.distance_to(tg)*100]
		print(st)
	if OS.get_environment("LAB_DUMP") != "" and t > float(OS.get_environment("LAB_DUMP")) - 0.15 and t < float(OS.get_environment("LAB_DUMP")) + 0.15:
		var c: Vector3 = p.get_global_transform_interpolated().origin
		print("%.3f mode=%d v=%.2f hips=%s cap=%s rel=%s lean=%.1f yaw=%.3f" % [t, p.get_mode(), p.get_speed(), str(h.snapped(Vector3.ONE*0.001)), str(c.snapped(Vector3.ONE*0.001)), str((sk.get_bone_global_pose(B.Hips).origin*0.01).snapped(Vector3.ONE*0.001)), layer.get_lean_deg(), p.get_yaw()])
	# 3. joints past the study's ranges (1.1): knee 0-140 and never backward, ankle <= 20 deg up from the rest angle,
	# elbow 0-145
	for side in ["Left", "Right"]:
		var hip := _wpos(side + "UpLeg"); var knee := _wpos(side + "Leg"); var ank := _wpos(side + "Foot"); var toe := _wpos(side + "ToeBase")
		var gx: Transform3D = sk.get_global_transform_interpolated()
		var ax: Vector3 = gx.basis.orthonormalized() * (sk.get_bone_global_pose(B[side + "UpLeg"]).basis.orthonormalized() * hinge[side])
		var flex: float = _knee_geom(hip, knee, ank, ax) - rest_knee[side]
		if flex > 140.0: m.knee_over += 1
		if flex < -5.0: m.knee_back += 1
		var sh := _wpos(side + "Arm"); var el := _wpos(side + "ForeArm"); var wr := _wpos(side + "Hand")
		var ef := 180.0 - rad_to_deg((sh - el).angle_to(wr - el))
		if ef > 145.0: m.elbow += 1
	m.joint_bad = m.knee_over + m.knee_back + m.elbow

func _finish():
	var modes := ["idle", "start", "loop", "stop", "pivot"]
	var seq := []
	for x in m.mode_seq: seq.append(modes[x])
	results.append({"name": cur.name, "slide": m.slide_max, "pop": m.pop_max, "joints": m.joint_bad,
		"knee_back": m.knee_back, "knee_over": m.knee_over, "elbow": m.elbow,
		"latency": m.latency * 1000.0 if m.latency >= 0 else -1.0, "t_full": m.t_full, "t_stop": m.t_stop,
		"vmax": m.max_speed, "slide_at": m.slide_at, "pop_at": m.pop_at, "switches": p.get_switches() - m.switch0, "releases": layer.get_releases() - m.rel0, "seq": " > ".join(seq)})

func _report():
	print("\n=== Lab B locomotion numbers (60 fps, player_v3) ===")
	print("%-34s %7s %7s %6s %8s %7s %7s %6s %4s  %s" % ["scenario", "slide", "hipPop", "joints", "latency", "tFull", "tStop", "vmax", "sw", "modes"])
	for r in results:
		print("%-34s %6.1fc %6.1fc %6d %6.0fms %6.2fs %6.2fs %6.2f %4d  %s" % [r.name, r.slide, r.pop, r.joints, r.latency, r.t_full, r.t_stop, r.vmax, r.switches, r.seq])
		print("      worst slide at %s, worst pop at %s, feet lifted early (out of reach) %d" % [r.slide_at, r.pop_at, r.releases])
		if r.joints > 0: print("      joints: knee backward %d, knee > 140 %d, elbow > 145 %d (frames)" % [r.knee_back, r.knee_over, r.elbow])
