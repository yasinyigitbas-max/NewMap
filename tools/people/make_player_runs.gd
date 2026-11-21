extends "res://tools/people/make_player_walks.gd"
## PLAYER ONLY. The player's run on foot, wired like the walk (Yasin, 21 Nov 23:2x: "okay now running after that";
## "use two run to stops, climb variety is for a cancelled climb"; 23:29: two run tiers, jog and fast run; 23:35: every
## run take he named goes in, only exact duplicates out; gender tags ignored: every take in both figures):
##   godot --headless --path . -s res://tools/people/make_player_runs.gd   -> characters/rocketbox/clips_player_run_<g>.res
## Library "prun" (CityPed loads it; CityPlayer picks the clips). Sources: the perf-bugs Mixamo packs (clips_mx_<g>.res)
## and his 21 Nov downloads (tools/people/player_run_sources/clips_mxrun_<g>.res, same converter: Running (4), Idle To
## Sprint, the Action Adventure and Male Locomotion packs' runs):
##   jog_a..d    JOG tier loops:  Running_4 (2.2 m/s), Slow_Run (2.7), Running_2 (3.8), Standard Run (Male Locomotion, 3.8)
##   fast_a..d   FAST tier loops: Running_3 (4.1), Fast_Run (4.9), Running (5.1), Sprint (5.3)
##   start_a / start_b          Idle To Sprint, and it mirrored (the other foot first)
##   tstart_r / tstart_l        Turn_To_Running (he turns about 105 degrees to his right as he sets off), and it mirrored
##   stop_a / stop_b            Run_To_Stop, and it mirrored
##   turn_l / turn_r            Running_Left_Turn, Running_Right_Turn (two downloads, one each way)
##   turn180_r / turn180_l      Running_Turn_180, and it mirrored
##   rturn_l / rturn_r          Running_To_Turn (runs, stops, turns round to his left: he ends standing), and it mirrored
##   stop_climb                 Run_To_Stop_Without_climb: NOT in the stop pool, kept for a cancelled climb
## Exact duplicates left out (same motion, under 2 cm): Running (4) = Running, Action Adventure "running" = Running_3,
## Action Adventure "run to stop" = Run_To_Stop_2 = Run_To_Stop, Running_Right_Turn_2 = Running_Right_Turn,
## Running_Turn_180_2 = Running_Turn_180, Running_To_Turn_180 = Running_To_Turn. The Action Adventure "left turn" /
## "right turn" and the Male Locomotion "left/right turn 90" are standing turns, not run turns (not used here).
## Meta as the walk's (make_player_walks.gd): ph_in_<loop> / in_at_<loop>, ph_out_<loop> / out_at_<loop>, still_at,
## v_out, slide_cm; the loops' ground_v (scaled by _vel_scaled: the planted foot) and left_down (their stride's phase).
const DROP_RUN := {"male": ["jog_b", "fast_a"], "female": ["jog_c", "jog_b", "fast_d"]}   # (Yasin, 22 Nov 02:14: they don't fit)
const RUN_SRC := "res://tools/people/player_run_sources/clips_mxrun_%s.res"
const LOOPS := [["jog_a", "mx", "Running_4"], ["jog_b", "mx", "Slow_Run"], ["jog_c", "mx", "Running_2"], ["jog_d", "new", "Loco_Standard_Run"],
		["fast_a", "mx", "Running_3"], ["fast_b", "mx", "Fast_Run"], ["fast_c", "mx", "Running"], ["fast_d", "mx", "Sprint"], ["fast_e", "new", "Running_New4_mixamo_com"]]
## [name, lib, source, mirrored]
const ONES := [["start_a", "new", "Sprint_Start_Idle_mixamo_com", false], ["start_b", "new", "Sprint_Start_Idle_mixamo_com", true],
		["tstart_r", "mx", "Turn_To_Running", false], ["tstart_l", "mx", "Turn_To_Running", true],
		["stop_a", "mx", "Run_To_Stop", false], ["stop_b", "mx", "Run_To_Stop", true],
		["turn_l", "mx", "Running_Left_Turn", false], ["turn_r", "mx", "Running_Right_Turn", false],
		["turn180_r", "mx", "Running_Turn_180", false], ["turn180_l", "mx", "Running_Turn_180", true],
		["rturn_l", "mx", "Running_To_Turn", false], ["rturn_r", "mx", "Running_To_Turn", true],
		["stop_climb", "mx", "Run_To_Stop_Without_climb", false],
		["start_c", "mx", "Rifle_Start_Run", false], ["start_d", "mx", "Rifle_Start_Run", true],
		["rturn_l1", "mx", "Running_To_Turn_180", false], ["rturn_r1", "mx", "Running_To_Turn_180", true]]

func _setup(gender: String) -> Node:
	var scene: Node = (load(DIR + "hero_%s.scn" % gender) as PackedScene).instantiate()
	sk = scene.find_children("*", "Skeleton3D", true, false)[0]
	skel_x = Transform3D()
	var n: Node = sk
	while n != scene: skel_x = (n as Node3D).transform * skel_x; n = n.get_parent()
	rest_g.clear()
	for b in sk.get_bone_count():
		var par := sk.get_bone_parent(b)
		rest_g.append(sk.get_bone_rest(b) if par < 0 else rest_g[par] * sk.get_bone_rest(b))
	mirror_of.resize(sk.get_bone_count())
	for b in sk.get_bone_count():
		var bn := sk.get_bone_name(b)
		var other := bn.replace("_L_", "_#_").replace("_R_", "_L_").replace("_#_", "_R_")
		if bn.ends_with(" L"): other = bn.trim_suffix(" L") + " R"
		mirror_of[b] = sk.find_bone(other) if sk.find_bone(other) >= 0 else b
	var lat := (rest_g[sk.find_bone("Bip01_L_Thigh")].origin - rest_g[sk.find_bone("Bip01_R_Thigh")].origin).normalized()
	M = Basis(Vector3(1 - 2 * lat.x * lat.x, -2 * lat.x * lat.y, -2 * lat.x * lat.z), Vector3(-2 * lat.y * lat.x, 1 - 2 * lat.y * lat.y, -2 * lat.y * lat.z), Vector3(-2 * lat.z * lat.x, -2 * lat.z * lat.y, 1 - 2 * lat.z * lat.z))
	return scene


## THE BODY'S MOVE FROM THE RAW HIPS (the converter's path pins its first and last 8 frames to the hips' first / last
## place: a run cut in at 4 m/s began at 1.2 and the planted feet slid 25-35 cm): the hips' own travel is put back
## together (the path the converter took out, plus the hips' sway left in the pose), its pace taken with a centred
## window over 9 frames (half a stride), and at the ends carried on at the pace it has there (a start from standing: 0;
## a stop's end: 0); in the body's own frame (a turning clip's pose has its turn taken out: the body turns by "yaw").
func _vel_raw(a: Animation, turn: bool, from_rest: bool, to_rest: bool) -> void:
	var vz0: PackedFloat32Array = a.get_meta("vz"); var vx0: PackedFloat32Array = a.get_meta("vx")
	var n := vz0.size()
	var pel := sk.find_bone("Bip01_Pelvis")
	var H := PackedVector3Array()
	var P := Vector3()
	for f in n:
		var y := _curve(a, "yaw_pose" if a.has_meta("yaw_pose") else "yaw", f / FPS)   # (the converter put its travel in the hips' turning frame)
		var g := _globals(_locals(a, minf(f / FPS, a.length)))
		var po: Vector3 = skel_x * g[pel].origin; po.y = 0.0
		var yb := y if turn else 0.0
		H.append(P + Basis(Vector3.UP, yb) * po)
		var fw := Vector3(sin(y), 0, cos(y)); var sd := Vector3(cos(y), 0, -sin(y))
		P += (fw * vz0[f] + sd * vx0[f]) / FPS
	# padded ends: the pace it has over its first / last 8 frames (or standing)
	var v_in := Vector3() if from_rest else (H[mini(8, n - 1)] - H[0]) * FPS / 8.0
	var v_end := Vector3() if to_rest else (H[n - 1] - H[maxi(n - 9, 0)]) * FPS / 8.0
	var W := 6
	var ext := PackedVector3Array()
	for k in range(-W - 1, n + W + 1):
		if k < 0: ext.append(H[0] + v_in * (k / FPS))
		elif k >= n: ext.append(H[n - 1] + v_end * ((k - n + 1) / FPS))
		else: ext.append(H[k])
	var vz := PackedFloat32Array(); var vx := PackedFloat32Array()
	for f in n:
		var acc := Vector3(); var wsum := 0.0
		for j in range(-W, W + 1):
			var i := f + j + W + 1
			var d := (ext[i + 1] - ext[i - 1]) * FPS * 0.5
			var w := cos(PI * 0.5 * j / (W + 1.0)); w *= w
			acc += d * w; wsum += w
		var v := acc / wsum
		var yb := _curve(a, "yaw", f / FPS) if turn else 0.0
		var b := Basis(Vector3.UP, -yb) * v
		vz.append(b.z); vx.append(b.x)
	a.set_meta("vz", vz); a.set_meta("vx", vx); a.set_meta("pace", vz)

func _smooth_pace(a: Animation, w: int) -> void:
	for key in ["vz", "vx"]:
		var c: PackedFloat32Array = a.get_meta(key)
		var o := PackedFloat32Array()
		for i in c.size():
			var acc := 0.0; var ws := 0.0
			for j in range(-w, w + 1):
				var q := clampi(i + j, 0, c.size() - 1); var ww := cos(PI * 0.5 * j / (w + 1.0)); ww *= ww
				acc += c[q] * ww; ws += ww
			o.append(acc / ws)
		a.set_meta(key, o)
	a.set_meta("pace", a.get_meta("vz"))

func _initialize() -> void:
	for gender in ["male", "female"]:
		var scene := _setup(gender)
		var libs := {"mx": load(MX_SRC % gender), "new": load(RUN_SRC % gender)}
		var steps: AnimationLibrary = load(DIR + "clips_step_%s.res" % gender)
		var idle: Animation = steps.get_animation(&"idle")
		var stance: Animation = (load(DIR + "clips_player_idle_%s.res" % gender) as AnimationLibrary).get_animation(&"base_idle")
		var out := AnimationLibrary.new()
		var loops := {}
		for L in LOOPS:
			var src: Animation = (libs[L[1]] as AnimationLibrary).get_animation(L[2])
			var a := _copy(src)
			a.loop_mode = Animation.LOOP_LINEAR
			var gv0 := float(a.get_meta("ground_v", 3.0)); var kf := _vel_scaled(a)
			a.set_meta("ground_v", gv0 * kf); a.set_meta("source", "mx/" + L[2])
			var nh := _open_hands(a, idle)
			var sl := _slide(a, a.length)
			a.set_meta("slide_cm", sl)
			loops[L[0]] = a
			out.add_animation(L[0], a)
			print("PLAYER_RUN %s %s <- %s %.2fs ground_v %.2f -> %.2f m/s left_down %.3f hands %d slide %.1f cm" % [gender, L[0], L[2], a.length, gv0, gv0 * kf, float(a.get_meta("left_down", 0.0)), nh, sl])
		for O in ONES:
			var name: String = O[0]
			var src2: Animation = (libs[O[1]] as AnimationLibrary).get_animation(O[2])
			var a := _mirror(src2) if O[3] else _copy(src2)
			a.loop_mode = Animation.LOOP_NONE
			a.set_meta("source", "mx/" + O[2] + (" (mirrored)" if O[3] else ""))
			var nh := _open_hands(a, idle)
			var info := ""
			var is_start := name.begins_with("start") or name.begins_with("tstart")
			var is_stop := name.begins_with("stop") or name.begins_with("rturn")
			var turn := String(O[2]).to_lower().contains("turn")
			a.set_meta("turning", turn)
			if not turn:   # (the hips' turn stays in the pose and the game keeps his heading: the body never turns by it)
				var yw: PackedFloat32Array = (a.get_meta("yaw") as PackedFloat32Array).duplicate()
				a.set_meta("yaw_pose", yw.duplicate()); yw.fill(0.0); a.set_meta("yaw", yw)
			# (the yaw the walk code would follow: a straight start / stop keeps his heading, so its velocity is in that frame)
			var done := float(a.get_meta("done_at", a.length))
			if is_start: done = a.length - 0.05
			# the body's pace: from the raw hips (_vel_raw) or the converter's, scaled to the planted feet (_vel_scaled, the
			# walk's way), whichever keeps the planted feet better
			var b0 := _copy(a); var kf := _vel_scaled(b0); var s_b := _slide(b0, done)
			_vel_raw(a, turn, is_start, is_stop)   # (a non-turning clip: in the fixed frame, its pose turn not taken out)
			a.set_meta("v_scale", 1.0)
			var s_a := _slide(a, done)
			if s_b < s_a: a = b0; info += " pace: converter x%.2f (slide %.1f, raw %.1f cm)" % [kf, s_b, s_a]
			else: info += " pace: raw hips (slide %.1f, converter %.1f cm)" % [s_a, s_b]
			if name.begins_with("turn"):
				# (a running turn's pace swings 1.9-5.4 m/s within the turn, footfall to footfall: eased over half a stride, his
				# body does not surge and brake with each step; the jerk probe's worst pace change in a turn was 10 m/s2)
				_smooth_pace(a, 6)
				info += " smoothed slide %.1f cm" % _slide(a, done)
			if is_stop:
				var still := a.length
				for i in range(int(a.length * 30.0), -1, -1):
					var t := i / 30.0
					if absf(_curve(a, "vz", t)) > 0.05 or absf(_curve(a, "vx", t)) > 0.05: break
					still = t
				a.set_meta("still_at", still); done = a.length
				info += " still_at %.2f" % still
			a.set_meta("done_at", done)
			if is_start or is_stop:
				# into / out of the idle's stance where that keeps the planted feet better than not (Run_To_Stop ends on both
				# feet: fitted, its feet would be moved while down; then the idle's crossfade takes it)
				var pre := _slide(a, done)
				var b := _copy(a)
				var fi := _fit_stance(b, stance, is_start)
				var post := _slide(b, done)
				if post <= pre + 2.0: a = b; info += " idle stance:" + fi + " (slide %.1f -> %.1f cm)" % [pre, post]
				else: info += " own stance (fitted it slid %.1f cm, not %.1f)" % [post, pre]
				a.set_meta("stance_fit", post <= pre + 2.0)
			if is_start:
				var vs := 0.0
				for i in 16: vs += _curve(a, "vz", done - 0.5 + i / 30.0) / 16.0
				a.set_meta("v_out", vs); info += " v_out %.2f m/s" % vs
			if not is_start:
				for lk in loops:
					var best := Vector3(0, 0, INF)
					for i in 13:
						var pin := _phase_in(loops[lk], _legs(a, i / 30.0))
						if pin.y < best.z - 0.5: best = Vector3(i / 30.0, pin.x, pin.y)
					a.set_meta("ph_in_" + lk, best.y); a.set_meta("in_at_" + lk, best.x)
					info += " in_%s %.2f@%.2fs(%.0fcm)" % [lk, best.y, best.x, best.z]
			if not is_stop:
				for lk in loops:
					var ho := _hand_over(a, loops[lk], done, 0.4 if is_start else 0.2)
					a.set_meta("ph_out_" + lk, ho.y); a.set_meta("out_at_" + lk, ho.x)
					info += " out_%s %.2f@%.2fs(%.0fcm)" % [lk, ho.y, ho.x, ho.z]
			var sl := _slide(a, done)
			a.set_meta("slide_cm", sl)
			out.add_animation(name, a)
			print("PLAYER_RUN %s %s <- %s %.2fs hands %d slide %.1f cm%s" % [gender, name, a.get_meta("source"), a.length, nh, sl, info])
		scene.free()
		# (Yasin, 22 Nov 02:14, after playing the build: "they dont fit": out of this figure's library, so out of its pools)
		for rm in DROP_RUN.get(gender, []):
			if out.has_animation(rm): out.remove_animation(rm); print("PLAYER_RUN %s %s REMOVED (Yasin, 22 Nov 02:14)" % [gender, rm])
		var err := ResourceSaver.save(out, DIR + "clips_player_run_%s.res" % gender, ResourceSaver.FLAG_COMPRESS)
		print("PLAYER_RUN saved %s %s" % [gender, "ok" if err == OK else "ERROR %d" % err])
	quit(0)
