extends SceneTree
## The player's walk on foot (Yasin, 21 Nov: "we should see one of the random starts, random main walks, and random stop
## walks. again, never the same one again"; tools/people/make_player_walks.gd, library "pwalk"):
##  - each walk: a start (pwalk/start_a|b), a main loop (pwalk/walk_mx|walk_ual), a stop (pwalk/stop_a|b); in each of
##    the three never the same as the walk before
##  - asked round while walking: the walking turns (turn_l / turn_r / turn180_*)
##  - letting go while setting off ends the start at once; pushing on while stopping ends the stop at once
##  - the feet: a foot on the ground (its ankle within 1 cm of its lowest), from where it is flat (its lowest point in
##    that contact) until it lifts, moves no more than SLIDE_MAX over the ground
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_player_walk.gd [-- female]
const SLIDE_MAX := 0.05
const CYCLES := 6
var player: CharacterBody3D
var sk: Skeleton3D
var lf := -1; var rf := -1
var n := 0; var fails := 0; var t := 0.0; var phase := 0; var cyc := 0
var last_clip := ""
var cur := {"start": "", "main": "", "stop": ""}
var walks: Array = []
var turns_seen := {}
var low := [INF, INF]; var down := [false, false]; var anchor := [Vector3(), Vector3()]; var slide := [0.0, 0.0]; var slide_at := ["", ""]
var cancel_start := ""; var cancel_stop := ""
var female := false

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("PWALK   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	female = "female" in OS.get_cmdline_user_args()
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(200, 2, 200); cs.shape = sh; b.add_child(cs)
	b.position = Vector3(0, -1, 0); root.add_child(b)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0)
	if female: player.set(&"body_id", "F1")
	root.add_child(player)

func _feet() -> Array:
	return [(sk.global_transform * sk.get_bone_global_pose(lf)).origin, (sk.global_transform * sk.get_bone_global_pose(rf)).origin]

## a foot's contact with the ground: from its lowest point (flat on the ground: before it the heel is still coming down)
## until it lifts, the furthest it moves over the ground
var contact: Array = [[], []]
func _end_contact(s: int) -> void:
	var cs: Array = contact[s]
	if cs.size() < 3: contact[s] = []; return
	var lo_i := 0
	for i in cs.size(): if cs[i][0].y < cs[lo_i][0].y: lo_i = i
	var a: Vector3 = cs[lo_i][0]
	for i in range(lo_i, cs.size()):
		var p: Vector3 = cs[i][0]
		var dd := Vector2(p.x - a.x, p.z - a.z).length()
		if dd > slide[s]: slide[s] = dd; slide_at[s] = cs[i][1]
	contact[s] = []

func _track_feet(c: String) -> void:
	var f := _feet()
	for s in 2:
		low[s] = minf(low[s], f[s].y)
		if f[s].y < low[s] + 0.01: contact[s].append([f[s], c])
		elif not contact[s].is_empty(): _end_contact(s)

func _process(dt: float) -> bool:
	n += 1; t += dt
	if n == 5:
		sk = player.find_children("*", "Skeleton3D", true, false)[0]
		lf = sk.find_bone("Bip01_L_Foot"); rf = sk.find_bone("Bip01_R_Foot")
	if n < 5: return false
	var c := String(player.call(&"get_clip"))
	var d: Dictionary = player.call(&"get_frame_log")
	if n > 60: _track_feet(c)
	if c != last_clip:
		print("PWALK   t=%.2f %s (speed %.2f step %d)" % [t, c, float(d.get("speed", 0)), int(d.get("step", -1))])
		last_clip = c
	if c.begins_with("pwalk/start"): cur["start"] = c
	elif c.begins_with("pwalk/walk"): cur["main"] = c
	elif c.begins_with("pwalk/stop"): cur["stop"] = c
	elif c.begins_with("pwalk/turn"): turns_seen[c] = true
	# phase 0: settle; 1: walk on 3.5 s; 2: let go, wait for the idle; (CYCLES walks) 3..: turns, 6..: cancels
	if phase == 0:
		if t > 2.0: phase = 1; t = 0.0; player.call(&"set_move", Vector2(0, 1), false)
	elif phase == 1:
		if t > 3.5: phase = 2; t = 0.0; player.call(&"set_move", Vector2(0, 0), false)
	elif phase == 2:
		if c == "step/idle" and float(d.get("speed", 1)) < 0.02 and t > 0.5:
			walks.append(cur.duplicate()); print("PWALK   walk %d: %s" % [walks.size(), cur])
			cur = {"start": "", "main": "", "stop": ""}
			if walks.size() >= CYCLES: phase = 3; t = 0.0; player.call(&"set_move", Vector2(0, 1), false)
			else: phase = 1; t = 0.0; player.call(&"set_move", Vector2(0, 1), false)
		if t > 8.0: _check(false, "walk %d did not come back to the idle" % (walks.size() + 1)); phase = 3; t = 0.0
	elif phase == 3:   # walking on, then asked right (a right turn), ahead again (a left turn), back the way he came (a 180)
		if t > 3.0 and t < 5.5: player.call(&"set_move", Vector2(1, 0), false)
		elif t >= 5.5 and t < 8.0: player.call(&"set_move", Vector2(0, 1), false)
		elif t >= 8.0 and t < 10.5: player.call(&"set_move", Vector2(0, -1), false)
		elif t >= 10.5: phase = 4; t = 0.0; player.call(&"set_move", Vector2(0, 0), false)
	elif phase == 4:
		if c == "step/idle" and t > 1.0 and float(d.get("speed", 1)) < 0.02: phase = 5; t = 0.0; player.call(&"set_move", Vector2(0, 1), false)
		if t > 8.0: phase = 5; t = 0.0
	elif phase == 5:   # let go while setting off
		if c.begins_with("pwalk/start") and t > 0.3 and cancel_start == "":
			player.call(&"set_move", Vector2(0, 0), false); cancel_start = "wait"; t = 0.0
		elif cancel_start == "wait" and t > 0.0:
			_check(int(d.get("step", -1)) != 1, "letting go while setting off ends the start at once (step %d after %.3f s)" % [int(d.get("step", -1)), t])
			cancel_start = "done"; phase = 6; t = 0.0
		if t > 6.0 and cancel_start == "": _check(false, "no start for the cancel check"); phase = 6; t = 0.0
	elif phase == 6:   # walk, let go, push on while stopping
		if t > 1.0 and t < 1.1: player.call(&"set_move", Vector2(0, 1), false)
		if t > 4.0 and cancel_stop == "": player.call(&"set_move", Vector2(0, 0), false); cancel_stop = "go"
		if cancel_stop == "go" and c.begins_with("pwalk/stop"):
			player.call(&"set_move", Vector2(0, 1), false); cancel_stop = "wait"
		elif cancel_stop == "wait":
			_check(int(d.get("step", -1)) != 2, "pushing on while stopping ends the stop at once (step %d)" % int(d.get("step", -1)))
			cancel_stop = "done"; phase = 7; t = 0.0
		if t > 10.0 and cancel_stop != "done": _check(false, "no stop for the cancel check"); phase = 7
	if phase == 7:
		_check(walks.size() >= CYCLES, "%d walks" % walks.size())
		for key in ["start", "main", "stop"]:
			var seen := []; var rep := 0; var missing := 0
			for i in walks.size():
				var w: String = walks[i][key]
				if w == "": missing += 1
				if i > 0 and w != "" and w == walks[i - 1][key]: rep += 1
				seen.append(w.trim_prefix("pwalk/"))
			_check(missing == 0, "every walk had a %s (%s)" % [key, ", ".join(seen)])
			_check(rep == 0, "no %s twice running" % key)
		_check(turns_seen.has("pwalk/turn_l") and turns_seen.has("pwalk/turn_r"), "walking turns played: %s" % ", ".join(turns_seen.keys()))
		var t180 := false
		for k in turns_seen: if String(k).begins_with("pwalk/turn180"): t180 = true
		_check(t180, "a walking 180 played")
		_check(slide[0] < SLIDE_MAX and slide[1] < SLIDE_MAX, "planted feet drift: left %.3f m (%s), right %.3f m (%s), bound %.2f" % [slide[0], slide_at[0], slide[1], slide_at[1], SLIDE_MAX])
		print("PWALK RESULT %s %s" % ["female" if female else "male", "PASS" if fails == 0 else "FAIL (%d)" % fails])
		quit(0 if fails == 0 else 1); return true
	if n > 60 * 260: print("PWALK RESULT FAIL (timeout, phase %d)" % phase); quit(1); return true
	return false
