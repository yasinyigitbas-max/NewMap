extends SceneTree
## The player's run on foot (Yasin, 21 Nov 23:2x-23:35: "okay now running after that"; two run tiers, JOG and FAST RUN,
## every run take he named; random start, loop and stop, never the same twice running; "use two run to stops";
## tools/people/make_player_runs.gd, library "prun"):
##  - each run (tier 1, the jog): a run start (prun/start_a|b), a jog loop (prun/jog_a..d), a run stop (prun/stop_a|b);
##    in each never the same as the run before
##  - each fast run (tier 2): a fast loop (prun/fast_a..d), never the same as the fast run before
##  - one go walk -> jog -> fast -> jog -> walk -> stop: each tier's loop in turn, his pace never jumps (under 9.5 m/s2
##    frame to frame), the tiers' paces reached (jog run_speed, fast fast_speed, within 8 %)
##  - asked round in a run: the running turns (turn_l / turn_r), and a 180 (turn180_* / rturn_*)
##  - off into a run 90 degrees round: the turning run start (prun/tstart_*)
##  - prun/stop_climb (the cancelled climb's) never in the stop pool
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_player_run.gd [-- female]
const CYCLES := 6
var player: CharacterBody3D
var n := 0; var fails := 0; var t := 0.0; var phase := 0
var last_clip := ""
var cur := {"start": "", "loop": "", "stop": "", "fast": ""}
var runs: Array = []
var fasts: Array = []
var turns_seen := {}
var tiers_seen: Array = []
var max_dv := 0.0; var max_dv_at := ""; var prev_sp := -1.0
var jog_sp := 0.0; var fast_sp := 0.0; var jog_n := 0; var fast_n := 0
var climb_used := false; var tstart := ""
var female := false

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("PRUN   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	female = "female" in OS.get_cmdline_user_args()
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(400, 2, 400); cs.shape = sh; b.add_child(cs)
	b.position = Vector3(0, -1, 0); root.add_child(b)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0)
	if female: player.set(&"body_id", "F1")
	root.add_child(player)

func _idle(c: String, d: Dictionary) -> bool:
	return c.begins_with("pidle/") and float(d.get("speed", 1)) < 0.02

func _go(dir: Vector2, tier: int) -> void: player.call(&"set_move_tier", dir, tier)

var turn_ask := 0
var fwd0 := Vector3(); var ask_w := Vector3(); var ask_tier := 1
## a way in the world as the stick's (the camera need not be behind him; held each frame as the camera swings round)
func _inp(w: Vector3) -> Vector2:
	var cy := float((player.call(&"get_view") as Array)[1])
	return Vector2(w.dot(Vector3(cos(cy), 0, -sin(cy))), w.dot(Vector3(-sin(cy), 0, -cos(cy))))
func _ask(w: Vector3, tier: int, what: String) -> void:
	ask_w = w; ask_tier = tier; _go(_inp(w), tier); turn_ask += 1; t = 0.0
	print("PRUN   asked %s" % what)

## the turn asked has played, he faces the way asked and is back in a run loop at a jog's pace, a little while on
func _turned(turns: Array, c: String, sp: float) -> bool:
	var seen := false
	for k in turns: if turns_seen.has(k): seen = true
	var y := float((player.call(&"get_frame_log") as Dictionary).get("yaw", 0.0))
	var facing := Vector3(sin(y), 0, cos(y)).dot(ask_w) > 0.97   # (round the way asked: a running turn is 36 degrees, the steering does the rest)
	return seen and facing and (c.begins_with("prun/jog") or c.begins_with("prun/fast")) and t > 1.0 and sp > 2.0

func _process(dt: float) -> bool:
	n += 1; t += dt
	if n < 5: return false
	var c := String(player.call(&"get_clip"))
	var d: Dictionary = player.call(&"get_frame_log")
	var sp := float(d.get("move_speed", 0.0))
	if prev_sp >= 0.0 and n > 60:
		var dv := absf(sp - prev_sp) / dt
		if dv > max_dv: max_dv = dv; max_dv_at = "%s t=%.2f %.2f->%.2f" % [c, t, prev_sp, sp]
	prev_sp = sp
	if c != last_clip:
		print("PRUN   t=%.2f %s (speed %.2f step %d tier %d)" % [t, c, float(d.get("speed", 0)), int(d.get("step", -1)), int(d.get("tier", -1))])
		last_clip = c
	if c == "prun/stop_climb": climb_used = true
	if c.begins_with("prun/start"): cur["start"] = c
	elif c.begins_with("prun/jog"): cur["loop"] = c
	elif c.begins_with("prun/fast"): cur["fast"] = c
	elif c.begins_with("prun/stop"): cur["stop"] = c
	elif c.begins_with("prun/turn") or c.begins_with("prun/rturn"): turns_seen[c] = true
	elif c.begins_with("prun/tstart"): tstart = c
	# 0 settle; 1 jog 3 s; 2 let go -> idle (CYCLES); 3 fast 4 s; 4 let go -> idle (CYCLES); 5 one go through the tiers;
	# 6 turns in a jog; 7 turning start
	if phase == 0:
		if t > 2.0: phase = 1; t = 0.0; _go(Vector2(0, 1), 1)
	elif phase == 1:
		if t > 3.0: phase = 2; t = 0.0; _go(Vector2(0, 0), 0)
	elif phase == 2:
		if _idle(c, d) and t > 0.5:
			runs.append(cur.duplicate()); print("PRUN   run %d: %s" % [runs.size(), cur])
			cur = {"start": "", "loop": "", "stop": "", "fast": ""}
			if runs.size() >= CYCLES: phase = 3; t = 0.0; _go(Vector2(0, 1), 2)
			else: phase = 1; t = 0.0; _go(Vector2(0, 1), 1)
		if t > 8.0: _check(false, "run %d did not come back to the idle" % (runs.size() + 1)); phase = 3; t = 0.0; _go(Vector2(0, 1), 2)
	elif phase == 3:
		if t > 4.0: phase = 4; t = 0.0; _go(Vector2(0, 0), 0)
	elif phase == 4:
		if _idle(c, d) and t > 0.5:
			fasts.append(cur["fast"]); print("PRUN   fast run %d: %s" % [fasts.size(), cur])
			cur = {"start": "", "loop": "", "stop": "", "fast": ""}
			if fasts.size() >= CYCLES: phase = 5; t = 0.0
			else: phase = 3; t = 0.0; _go(Vector2(0, 1), 2)
		if t > 8.0: _check(false, "fast run %d did not come back to the idle" % (fasts.size() + 1)); phase = 5; t = 0.0
	elif phase == 5:   # walk 3 s, jog 3 s, fast 3.5 s, jog 3 s, walk 3 s, let go
		var tr := 0 if t < 3.0 else (1 if t < 6.0 else (2 if t < 9.5 else (1 if t < 12.5 else 0)))
		if t < 15.5: _go(Vector2(0, 1), tr)
		var band := "walk" if c.begins_with("pwalk/walk") else ("jog" if c.begins_with("prun/jog") else ("fast" if c.begins_with("prun/fast") else ""))
		if band != "" and (tiers_seen.is_empty() or tiers_seen[-1] != band): tiers_seen.append(band)
		if t > 5.0 and t < 6.0: jog_sp += sp; jog_n += 1
		if t > 8.8 and t < 9.5: fast_sp += sp; fast_n += 1
		if t >= 15.5: _go(Vector2(0, 0), 0)
		if t > 15.5 and _idle(c, d) and t > 16.0: phase = 6; t = 0.0; _go(Vector2(0, 1), 1)
		if t > 24.0: _check(false, "the tier run did not come back to the idle"); phase = 6; t = 0.0; _go(Vector2(0, 1), 1)
	elif phase == 6:   # jogging on, then asked right, ahead again, back the way he came; then the fast run round twice
		# (each asked once the turn before has played and he is back in a run loop at pace: asked on a timer, a turn
		# still playing, or a stride too slow to reach its cut in, made the left turn come or not by chance)
		if turn_ask == 0 and t > 3.0:
			var y0 := float((player.call(&"get_view") as Array)[0]); fwd0 = Vector3(sin(y0), 0, cos(y0))
			_ask(Vector3(-cos(y0), 0, sin(y0)), 1, "right")
		elif turn_ask == 1 and _turned(["prun/turn_r"], c, sp): _ask(fwd0, 1, "left")
		elif turn_ask == 2 and _turned(["prun/turn_l"], c, sp): _ask(-fwd0, 1, "back")
		elif turn_ask == 3 and _turned(["prun/turn180_l", "prun/turn180_r", "prun/rturn_l", "prun/rturn_r", "prun/rturn_l1", "prun/rturn_r1"], c, sp): _ask(Vector3(fwd0.z, 0, -fwd0.x), 2, "fast, round")
		elif turn_ask == 4 and t > 2.0: _ask(fwd0, 2, "fast, back")
		elif turn_ask == 5 and t > 2.5: turn_ask = 6
		if turn_ask >= 1 and turn_ask <= 3 and t > 8.0: _check(false, "no running turn for the %s request" % ["right", "left", "back"][turn_ask - 1]); turn_ask = 4; t = 0.0
		if turn_ask >= 1 and turn_ask <= 5: _go(_inp(ask_w), ask_tier)
		if turn_ask == 6: phase = 7; t = 0.0; _go(Vector2(0, 0), 0)
	elif phase == 7:
		if _idle(c, d) and t > 1.0 and tstart == "":
			# (90 degrees to his right, in the camera's terms: the camera need not be behind him)
			var v: Array = player.call(&"get_view")
			var y := float(v[0]); var cy := float(v[1])
			var want := Vector3(-cos(y), 0, sin(y))
			var cf := Vector3(-sin(cy), 0, -cos(cy)); var cr := Vector3(cos(cy), 0, -sin(cy))
			_go(Vector2(want.dot(cr), want.dot(cf)), 1); tstart = "wait"; t = 0.0
		if tstart == "wait" and t > 3.0: phase = 8
		if tstart.begins_with("prun/tstart") and t > 2.0: phase = 8
		if t > 12.0: phase = 8
	if phase == 8:
		_check(runs.size() >= CYCLES, "%d runs" % runs.size())
		for key in ["start", "loop", "stop"]:
			var seen := []; var rep := 0; var missing := 0
			for i in runs.size():
				var w: String = runs[i][key]
				if w == "": missing += 1
				if i > 0 and w != "" and w == runs[i - 1][key]: rep += 1
				seen.append(w.trim_prefix("prun/"))
			_check(missing == 0, "every run had a %s (%s)" % [key, ", ".join(seen)])
			_check(rep == 0, "no %s twice running" % key)
		var fseen := []; var frep := 0; var fmiss := 0
		for i in fasts.size():
			if fasts[i] == "": fmiss += 1
			if i > 0 and fasts[i] != "" and fasts[i] == fasts[i - 1]: frep += 1
			fseen.append(String(fasts[i]).trim_prefix("prun/"))
		_check(fasts.size() >= CYCLES and fmiss == 0, "every fast run had a fast loop (%s)" % ", ".join(fseen))
		_check(frep == 0, "no fast loop twice running")
		_check(", ".join(tiers_seen).begins_with("walk, jog, fast, jog, walk"), "one go through the tiers: %s" % ", ".join(tiers_seen))
		var js := jog_sp / maxf(jog_n, 1); var fs := fast_sp / maxf(fast_n, 1)
		var jt := float(player.get(&"run_speed")); var ft := float(player.get(&"fast_speed"))
		_check(absf(js - jt) < jt * 0.08, "the jog's pace %.2f m/s (tier %.2f)" % [js, jt])
		_check(absf(fs - ft) < ft * 0.08, "the fast run's pace %.2f m/s (tier %.2f)" % [fs, ft])
		_check(max_dv < 9.5, "his pace never jumps: worst %.1f m/s2 (%s)" % [max_dv, max_dv_at])
		_check(turns_seen.has("prun/turn_l") and turns_seen.has("prun/turn_r"), "running turns played: %s" % ", ".join(turns_seen.keys()))
		var t180 := false
		for k in turns_seen: if String(k).begins_with("prun/turn180") or String(k).begins_with("prun/rturn"): t180 = true
		_check(t180, "a running 180 played")
		_check(tstart.begins_with("prun/tstart"), "the turning run start played (%s)" % tstart)
		_check(not climb_used, "the cancelled climb's stop never in the stop pool")
		print("PRUN RESULT %s %s" % ["female" if female else "male", "PASS" if fails == 0 else "FAIL (%d)" % fails])
		quit(0 if fails == 0 else 1); return true
	if n > 60 * 300: print("PRUN RESULT FAIL (timeout, phase %d)" % phase); quit(1); return true
	return false
