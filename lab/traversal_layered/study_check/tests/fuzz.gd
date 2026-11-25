## STUDY CHECK (LOCKED): the input fuzzer (study 9.3). Plays the lab's own player with seeded random input and the
## validator (StudyCheck) on the drawn pose: last on the skeleton, and a second one ("pre") just before a modifier named
## FinalLimiter if there is one.
##   godot --headless --path . --fixed-fps <fps> -s res://study_check/tests/fuzz.gd -- seconds=<s> seed=<n> out=<file> [hitches=1] [scope=flat]
## Prints "FUZZ RESULT PASS" only with 0 HARD violations after the limiter and 0 key violations before it (9.3).
## scope=flat: open ground only (step 4). scope=course: also runs at the course's obstacles (steps 5-7).
extends SceneTree

const HOME := Vector3(0, 0, 110)
const HOME_R := 45.0
const SPEEDS := [0.0, 1.1, 1.55, 2.2, 3.0, 4.2, 4.6]

var args := {"seconds": "120", "seed": "1", "out": "", "hitches": "0", "scope": "flat", "snap": ""}
var main; var p; var sk: Skeleton3D
var chk; var pre
var rng := RandomNumberGenerator.new()
var segs := []           # [t0, t1, kind, params]
var t := 0.0
var started := false
var settle := 0.0
var hitch_next := 0.0
var snaps := {}
var hitch_frames := 0
var done := false
var fps_run := 0
var ticks := 0

func _init():
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	rng.seed = int(args.seed)
	_plan(float(args.seconds))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	p = main.get_node("Player")
	process_frame.connect(_frame)
	physics_frame.connect(_phys)

func _plan(total: float) -> void:
	var t0 := 0.0
	while t0 < total:
		var kind := rng.randi_range(0, 8)
		var len := rng.randf_range(2.0, 8.0)
		var prm := {"a0": rng.randf_range(-PI, PI)}
		match kind:
			0: # random stick, 2-10 changes a second
				var ev := []; var tt := 0.0
				while tt < len:
					ev.append([tt, rng.randf_range(-PI, PI), SPEEDS[rng.randi_range(0, SPEEDS.size() - 1)] if rng.randf() < 0.6 else rng.randf_range(0, 4.6)])
					tt += rng.randf_range(0.1, 0.5)
				prm.ev = ev
			1: # full reversals at a run every 0.5-3 s
				var ev := []; var tt := 0.0; var a: float = prm.a0
				prm.sp = [4.2, 4.6][rng.randi_range(0, 1)]
				while tt < len:
					ev.append([tt, a, prm.sp]); a += PI; tt += rng.randf_range(0.5, 3.0)
				prm.ev = ev
			2: # circles at any rate (0.3-12.6 rad/s), walk or run
				prm.rate = rng.randf_range(0.3, 12.6) * (1 if rng.randf() < 0.5 else -1)
				prm.sp = [1.55, 3.0, 4.2, 4.6][rng.randi_range(0, 3)]
			3: # flicks of 50-150 ms
				var ev := []; var tt := 0.0
				while tt < len:
					ev.append([tt, rng.randf_range(-PI, PI), SPEEDS[rng.randi_range(2, 6)]])
					ev.append([tt + rng.randf_range(0.05, 0.15), 0.0, 0.0])
					tt += rng.randf_range(0.3, 1.2)
				prm.ev = ev
			4: # run on / off spam
				var ev := []; var tt := 0.0; var on := false
				while tt < len:
					ev.append([tt, prm.a0, 4.6 if on else 1.55]); on = not on; tt += rng.randf_range(0.2, 0.8)
				prm.ev = ev
			5: # stop-go spam
				var ev := []; var tt := 0.0; var go := true
				while tt < len:
					ev.append([tt, prm.a0, SPEEDS[rng.randi_range(2, 6)] if go else 0.0]); go = not go; tt += rng.randf_range(0.15, 0.6)
				prm.ev = ev
			6: # camera spin while running, up to 720 deg/s
				prm.rate = deg_to_rad(rng.randf_range(90, 720)) * (1 if rng.randf() < 0.5 else -1)
				prm.sp = [3.0, 4.2, 4.6][rng.randi_range(0, 2)]
			7: # idle
				len = rng.randf_range(0.5, 2.0)
			8: # steady walk or run in a straight line (a fair share of ordinary play)
				prm.sp = SPEEDS[rng.randi_range(1, 6)]
		segs.append([t0, t0 + len, kind, prm])
		t0 += len

func _stick(tt: float) -> Array:
	# returns [angle (0 = +Z), speed]
	for s in segs:
		if tt >= s[0] and tt < s[1]:
			var u: float = tt - s[0]
			var prm: Dictionary = s[3]
			match s[2]:
				0, 1, 3, 4, 5:
					var cur := [prm.a0, 0.0]
					for e in prm.ev:
						if u >= e[0]: cur = [e[1], e[2]]
					return cur
				2, 6: return [prm.a0 + prm.rate * u, prm.sp]
				7: return [prm.a0, 0.0]
				8: return [prm.a0, prm.sp]
	return [0.0, 0.0]

func _frame():
	if done: return
	if not started:
		if not p.is_ready_to_play(): return
		sk = p.get_node("Body/Armature/Skeleton3D")
		p.teleport(HOME, 0.0)
		settle += 1
		if settle < 30: return
		started = true
		chk = ClassDB.instantiate("StudyCheck")
		chk.name = "StudyCheckFinal"
		var lim := sk.get_node_or_null("FinalLimiter")
		if lim != null:
			pre = ClassDB.instantiate("StudyCheck")
			pre.name = "StudyCheckPre"
			pre.set_role("pre")
			sk.add_child(pre)
			sk.move_child(pre, lim.get_index())
			pre.set_controller(p); pre.set_seed(int(args.seed))
			chk.set_peer(pre)
		sk.add_child(chk)
		chk.set_controller(p)
		chk.set_seed(int(args.seed))
		fps_run = int(round(1.0 / max(root.get_process_delta_time(), 1e-4)))
		chk.set_label("fps=%d" % fps_run)
		hitch_next = rng.randf_range(3.0, 12.0)
		return
	t = chk.get_time()
	if t >= float(args.seconds):
		_finish(); return
	# hitches: a single 100-250 ms frame (time_scale for one frame)
	Engine.time_scale = 1.0
	if args.hitches == "1" and t >= hitch_next:
		var fps: float = 1.0 / max(root.get_process_delta_time(), 1e-4)
		Engine.time_scale = rng.randf_range(0.10, 0.25) * fps
		hitch_frames += 1
		hitch_next = t + rng.randf_range(3.0, 12.0)
	# pose snapshots every 0.5 s (frame-rate agreement, 9.3)
	if args.snap != "":
		var k := int(round(t * 2.0))
		if abs(t - k * 0.5) < 0.0005 and not snaps.has(k):
			var d: Dictionary = chk.get_last()
			var c: Vector3 = d.com
			d.com = [c.x, c.y, c.z]
			snaps[k] = d

func _phys():
	# the stick, once per physics tick (60 Hz), from the tick count: the same input at any drawing frame rate
	if not started or done: return
	ticks += 1
	var tt := ticks / float(Engine.physics_ticks_per_second)
	var st := _stick(tt)
	var ang: float = st[0]; var sp: float = st[1]
	var pos: Vector3 = p.global_position
	var off := Vector3(pos.x - HOME.x, 0, pos.z - HOME.z)
	if off.length() > HOME_R and sp > 0:
		# steer home: turn the stick toward the centre, no teleports (they'd read as pops)
		var home_ang := atan2(-off.x, -off.z)
		var d := wrapf(home_ang - ang, -PI, PI)
		ang += d * clamp((off.length() - HOME_R) / 10.0, 0.0, 1.0)
	p.set_test_input(Vector2(sin(ang), cos(ang)), sp, true)

func _finish():
	done = true
	Engine.time_scale = 1.0
	chk.flush()
	if pre: pre.flush()
	var r: Dictionary = chk.get_report()
	var rp: Dictionary = pre.get_report() if pre else {}
	var hard: int = r.violations
	var pre_key: int = rp.get("violations", 0) if pre else 0
	var frames: int = r.frames
	var other_ratio: float = float(r.limiter_other_frames) / max(1, frames)
	var ok: bool = r.setup_ok and hard == 0 and pre_key == 0 and other_ratio < 0.0001
	var lines := PackedStringArray()
	lines.append("FUZZ seed=%s seconds=%.1f frames=%d fps=%s hitches=%d scope=%s limiter=%s" % [args.seed, r.seconds, frames, str(fps_run), hitch_frames, args.scope, "yes" if pre else "none"])
	if not r.setup_ok: lines.append("SETUP_FAIL " + str(r.setup_error))
	var ids: Array = r.rules.keys(); ids.sort()
	for id in ids:
		var e: Dictionary = r.rules[id]
		lines.append("  %-20s %7d frames  worst %.2f (limit %.2f) at t=%.2f %s" % [id, e.count, e.worst, e.limit, e.t, e.side])
	if pre:
		var pids: Array = rp.rules.keys(); pids.sort()
		for id in pids:
			var e: Dictionary = rp.rules[id]
			lines.append("  %-20s %7d frames  worst %.2f (limit %.2f) at t=%.2f %s" % [id, e.count, e.worst, e.limit, e.t, e.side])
		lines.append("  limiter: key frames %d, other joints clamped on %.4f %% of frames (limit 0.01 %%)" % [r.limiter_key_frames, other_ratio * 100.0])
	lines.append("  states (s): " + str(r.state_seconds))
	lines.append("FUZZ RESULT " + ("PASS" if ok else "FAIL"))
	for l in lines: print(l)
	if args.out != "":
		var f := FileAccess.open(args.out, FileAccess.WRITE)
		if f:
			for l in lines: f.store_line(l)
			f.store_line("--- first violations, per rule (time, frame, rule, side, value, limit, state, seed)")
			for l in chk.get_log(): f.store_line(l)
			if pre:
				for l in pre.get_log(): f.store_line(l)
			f.close()
	if args.snap != "":
		var f2 := FileAccess.open(args.snap, FileAccess.WRITE)
		if f2:
			f2.store_string(JSON.stringify(snaps)); f2.close()
	quit(0 if ok else 1)
