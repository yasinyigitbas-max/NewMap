extends SceneTree
## The player's traversal (Yasin, 22 Nov: jumps, crouches, cover, falls, vaults, climbs, "again no ual";
## native/src/city_player_traversal.cpp, library "ptrav": tools/people/make_player_traversal.gd). Each rule, on a course
## like the walk test's:
##  - a standing jump (idle), a running jump (jogging): their takes, alternating; back to the idle / the run after
##  - the crouch: in (Standing To Crouched), Crouching Idle, the crouch walks, the sideways sneaks, out (the Crouch To
##    Stand takes), Crouched To Sprinting off at a run
##  - a bush strip (0.8 m high, 0.4 m deep): running, over it and on running; walking, a vault over it
##  - a low thick box (0.8 m, 2.5 m deep): running, onto it and on running; walking, climbed onto, standing up there
##  - walls 1.8 m and 2.3 m: climbed (walking)
##  - cover: crouched into a low wall: in cover; along it (the cover sneaks); across the gap to the next: switched; at
##    its far end a look round the corner; the crouch let go: out
##  - drops off ledges 1.5 / 2.5 / 4 / 6 / 8 m: soft / soft / hard / hard (messed when the 10 % comes up: forced once)
##    / Falling Idle and Falling To Landing; never a UAL clip, never a roll
##  - standing still at a 1.5 m edge: after 15 s Falling From Losing Balance, and down
##  - the figure never pops (its hips under 0.3 m a frame) and a planted foot slides little (reported per move)
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_player_traversal.gd [-- female]
var player: CharacterBody3D
var fails := 0
var female := false
var sk: Skeleton3D
var bl := -1; var br := -1; var bp := -1
var seen := {}           # (clips seen since the last _clear)
var ual_seen := ""
var pel_prev := Vector3(); var pel_jump := 0.0; var pel_jump_at := ""
var foot_c := [false, false]; var foot_a := [Vector3(), Vector3()]; var slide := 0.0; var slide_at := ""
var slide_all := {}
var last_c := ""
var body_prev := Vector3()
var foot_prev := [Vector3(), Vector3()]

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("PTRAV  %s: %s" % ["ok" if ok else "FAIL", what])

func _box(at: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	b.position = at + Vector3(0, size.y * 0.5, 0); root.add_child(b)

func _initialize() -> void:
	female = "female" in OS.get_cmdline_user_args()
	_box(Vector3(0, -2, 0), Vector3(600, 2, 600))
	# the course (lanes 20 m apart)
	_box(Vector3(20, 0, 10), Vector3(4, 0.8, 0.4))      # bush (run)
	_box(Vector3(40, 0, 10), Vector3(4, 0.8, 0.4))      # bush (walk)
	_box(Vector3(60, 0, 11.25), Vector3(3, 0.8, 2.5))   # thick box (run)
	_box(Vector3(80, 0, 11.25), Vector3(3, 0.8, 2.5))   # thick box (walk)
	_box(Vector3(100, 0, 11), Vector3(3, 1.8, 2.0))     # 1.8 m wall
	_box(Vector3(120, 0, 11), Vector3(3, 2.3, 2.0))     # 2.3 m wall
	_box(Vector3(140, 0, 10.2), Vector3(2.4, 1.0, 0.4)) # the cover pair: 1.3 m apart
	_box(Vector3(143.7, 0, 10.2), Vector3(2.4, 1.0, 0.4))
	var hs := [1.5, 2.5, 4.0, 6.0, 8.0, 6.0]
	for i in hs.size(): _box(Vector3(-40, 0, -30 + i * 12.0), Vector3(3, hs[i], 3))
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0)
	if female: player.set(&"body_id", "F1")
	root.add_child(player)
	_run.call_deferred()

func _find_sk(n: Node) -> Skeleton3D:
	if n is Skeleton3D: return n
	for c in n.get_children():
		var s := _find_sk(c)
		if s: return s
	return null

func _clip() -> String: return String(player.call(&"get_clip"))
func _trav() -> Dictionary: return player.call(&"get_trav")

func _clear() -> void:
	seen = {}; pel_jump = 0.0; slide = 0.0; pel_jump_at = ""; slide_at = ""

var TRAV_RE := RegEx.create_from_string("jump|crouch|climb|vault|fall|land|roll|cover|hang|ledge|sneak|getup|get_up|stand_up|mantle")

## a running loop: the Mixamo runs, or the run's own fallback when a figure lacks the take picked
func _running(c: String) -> bool:
	return c.begins_with("prun/") or c in ["ual/Jog_Fwd_Loop", "ual/Sprint_Loop", "step/jog"]

var plant_body := [Vector3(), Vector3()]; var plant_clips := [[], []]; var plant_n := [0, 0]; var plant_max := [0.0, 0.0]; var plant_fo := [Vector3(), Vector3()]
var quiet := false
var plant_raw0 := [Vector3(), Vector3()]; var plant_rawmax := [0.0, 0.0]
var slides_dbg := "slides" in OS.get_cmdline_user_args()
var trace_dbg := "trace" in OS.get_cmdline_user_args(); var trace_n := 0; var trace_ring := []

func _frame() -> void:
	await physics_frame
	var c := _clip()
	if c != last_c:
		if trace_dbg and last_c.begins_with("ptrav/") and not c.begins_with("ptrav/"):
			trace_n = 25
			for l in trace_ring: print(l)
		print("PTRAV    %s (y %.2f mode %d)" % [c, player.global_position.y, int(_trav().get("mode", 0))]); last_c = c
	if not seen.has(c): seen[c] = 0
	seen[c] += 1
	# a UAL / step traversal clip (the locomotion's own fallback loops for a figure missing a take are not ours)
	if (c.begins_with("ual/") or c.begins_with("step/")) and TRAV_RE.search(c.to_lower()): ual_seen = c
	if not sk: sk = _find_sk(player)
	if sk and bl < 0: bl = sk.find_bone("Bip01_L_Foot"); br = sk.find_bone("Bip01_R_Foot"); bp = sk.find_bone("Bip01_Pelvis")
	if sk and bp >= 0:
		var g := sk.global_transform
		var pel := g * sk.get_bone_global_pose(bp).origin
		if pel_prev != Vector3():
			var j := (pel - pel_prev).length()
			if j > pel_jump: pel_jump = j; pel_jump_at = c
			if j > 0.2 and j < 3.0: print("PTRAV    jump %.2f m at %s t %.2f mode %d (body moved %.2f, pelvis %s, body %s)" % [j, c, float(_trav().get("t", 0)), int(_trav().get("mode", 0)), (player.global_position - body_prev).length(), pel, player.global_position])
		if trace_dbg:
			var lp := g.affine_inverse() * pel
			var ln := ("PTRAV      trace %s t %.3f pel %.3f local (%.3f, %.3f, %.3f) fo %s fo_t %.3f body %s fig %s" % [c, float(_trav().get("t", 0)), (pel - pel_prev).length(), lp.x, lp.y, lp.z, _trav().get("fo_off", Vector3()), float(_trav().get("fo_t", 0.0)) + (10.0 if _trav().get("fo_track", false) else 0.0), player.global_position, (player.call(&"get_frame_log") as Dictionary).get("fig_at", "")])
			trace_ring.append(ln); if trace_ring.size() > 4: trace_ring.pop_front()
		if trace_n > 0:
			trace_n -= 1
			var lp := g.affine_inverse() * pel
			print("PTRAV      trace %s pel %.3f local (%.3f, %.3f, %.3f) off %s track %s fo_t %.3f yaw %.3f body %s" % [c, (pel - pel_prev).length(), lp.x, lp.y, lp.z, _trav().get("fo_off", Vector3()), _trav().get("fo_track", false), float(_trav().get("fo_t", 0.0)), g.basis.get_euler().y, (player.call(&"get_frame_log") as Dictionary).get("fig_at", Vector3()) - player.global_position])
		body_prev = player.global_position
		pel_prev = pel
		# a planted foot: low (within 14 cm of the lower foot) and still in height; its slide over the plant
		# (as DRAWN: after the foot plant's lock, which pins a planted foot; the bone poses read here are the clip's own)
		var flog: Dictionary = player.call(&"get_frame_log")
		var fl: Vector3 = flog.get("foot_l", g * sk.get_bone_global_pose(bl).origin); var fr: Vector3 = flog.get("foot_r", g * sk.get_bone_global_pose(br).origin)
		var raw := [g * sk.get_bone_global_pose(bl).origin, g * sk.get_bone_global_pose(br).origin]
		if quiet: foot_c = [false, false]; foot_prev = [fl, fr]; return
		var low := minf(fl.y, fr.y)
		for k in 2:
			var f: Vector3 = fl if k == 0 else fr
			var vy: float = absf(f.y - (foot_prev[k] as Vector3).y) * 60.0
			var on: bool = f.y - low < 0.04 and vy < 0.15 and foot_prev[k] != Vector3() and _on_ground(f)
			foot_prev[k] = f
			if on and not foot_c[k]:
				foot_a[k] = f; plant_body[k] = player.global_position; plant_clips[k] = [c]; plant_n[k] = 0
				plant_fo[k] = _trav().get("fo", Vector3()); plant_raw0[k] = raw[k]; plant_rawmax[k] = 0.0
			if on:
				var s := Vector2(f.x - foot_a[k].x, f.z - foot_a[k].z).length()
				if s > slide and s < 1.0: slide = s; slide_at = c
				plant_n[k] += 1; plant_max[k] = maxf(plant_max[k], s)
				var rv: Vector3 = raw[k] - plant_raw0[k]; plant_rawmax[k] = maxf(plant_rawmax[k], Vector2(rv.x, rv.z).length())
				if slides_dbg and s > 0.12: print("PTRAV      f%d %s %s t %.2f drawn %.3f raw %.3f lock %s slide %s fig %s" % [Engine.get_physics_frames(), "LR"[k], c, float(_trav().get("t", 0)), s, Vector2(rv.x, rv.z).length(), flog.get("lock", ""), flog.get("slide_l" if k == 0 else "slide_r", ""), flog.get("fig_at", "")])
				if not (plant_clips[k] as Array).has(c): (plant_clips[k] as Array).append(c)
			if foot_c[k] and not on and slides_dbg and plant_max[k] > 0.12:
				var bd: Vector3 = player.global_position - plant_body[k]
				print("PTRAV    slide %s foot %.2f m (raw clip %.2f) over %d frames, body moved %.2f m, fo %s -> %s, clips %s" % ["LR"[k], plant_max[k], plant_rawmax[k], plant_n[k], Vector2(bd.x, bd.z).length(), plant_fo[k], _trav().get("fo", Vector3()), plant_clips[k]])
			if not on: plant_max[k] = 0.0
			foot_c[k] = on

## the ankle within 16 cm of the ground under it (a foot carried level over a bush is not planted)
func _on_ground(f: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(f + Vector3(0, 0.3, 0), f - Vector3(0, 0.6, 0))
	q.exclude = [player.get_rid()]
	var h := player.get_world_3d().direct_space_state.intersect_ray(q)
	return not h.is_empty() and f.y - (h.position as Vector3).y < 0.16

func _wait(sec: float) -> void:
	var n := int(sec * 60.0)
	for i in n: await _frame()

## frames until cond is true or sec run out; true if it came true
func _until(cond: Callable, sec: float) -> bool:
	var n := int(sec * 60.0)
	for i in n:
		await _frame()
		if cond.call(): return true
	return false

func _put(at: Vector3, yaw: float) -> void:
	player.call(&"set_move_tier", Vector2(), 0)
	player.call(&"set_crouch", false)
	quiet = true
	player.global_position = at
	player.call(&"set_facing", yaw)
	await _wait(0.5)
	quiet = false
	pel_prev = Vector3(); foot_prev = [Vector3(), Vector3()]; foot_c = [false, false]
	_clear()

func _go(tier: int) -> void: player.call(&"set_move_tier", Vector2(0, 1), tier)
func _stop() -> void: player.call(&"set_move_tier", Vector2(), 0)
func _any(prefixes: Array) -> String:
	for c in seen.keys():
		for p in prefixes: if String(c).begins_with(p): return c
	return ""
func _report(what: String, pop_max := 0.3) -> void:
	print("PTRAV  %s: clips %s" % [what, ", ".join(PackedStringArray(seen.keys().filter(func(k): return String(k).begins_with("ptrav/"))))])
	print("PTRAV  %s: the hips' largest step a frame %.3f m (%s), a planted foot's slide %.3f m (%s)" % [what, pel_jump, pel_jump_at, slide, slide_at])
	slide_all[what] = slide
	_check(pel_jump < pop_max, "%s: no pop (hips %.2f m in a frame)" % [what, pel_jump])
	# (as drawn, the foot plant's pin included; a foot on the ground only. Under 0.2 m in a traversal clip; in the walk /
	# run loops around it (their own clips) under 0.7 m, reported)
	# (the jog after a move: under 0.15 m since the hand-over follows the old pose out as drawn, 22 Nov. The walk / run
	# starts and stops are the locomotion's own takes, its own business: up to 0.4 m in a walk stop on its own, reported)
	var lim := 0.2
	if slide_at.begins_with("prun/jog") or slide_at.begins_with("prun/fast"): lim = 0.15
	elif slide_at.begins_with("prun/") or slide_at.begins_with("pwalk/") or slide_at.begins_with("pidle/"): lim = 0.7
	_check(slide < lim, "%s: a planted foot slides under %.2f m (%.2f m, %s)" % [what, lim, slide, slide_at])

func _run() -> void:
	await _wait(0.5)
	var lib := bool(_trav().get("lib", false))
	_check(lib, "the ptrav library is loaded")
	if not lib: _end(); return
	# STANDING JUMPS: idle, three in turn
	var takes := {}
	for i in 3:
		await _put(Vector3(0, 0.05, -20), 0.0)
		player.call(&"jump")
		var ok := await _until(func(): return _clip().begins_with("ptrav/J"), 0.3)
		takes[_any(["ptrav/J"])] = true
		await _until(func(): return int(_trav().get("mode", 0)) == 0 and _clip().begins_with("pidle/"), 5.0)
		_check(ok and _clip().begins_with("pidle/"), "standing jump %d: %s, then the idle (%s)" % [i + 1, _any(["ptrav/J"]), _clip()])
	_check(takes.size() >= 2, "standing jumps alternate takes: %s" % [takes.keys()])
	_report("standing jump")
	# RUNNING JUMPS: two
	takes = {}
	for i in 2:
		await _put(Vector3(-20, 0.05, -60), 0.0)
		_go(1); await _wait(2.5)
		_clear(); player.call(&"jump")
		var ok := await _until(func(): return _clip() == "ptrav/Running_Jump_a" or _clip() == "ptrav/Jump_b", 0.3)
		takes[_any(["ptrav/Running_Jump_a", "ptrav/Jump_b"])] = true
		await _until(func(): return int(_trav().get("mode", 0)) == 0, 3.0)
		await _wait(0.4)
		_check(ok and _running(_clip()), "running jump %d: %s, on running (%s)" % [i + 1, _any(["ptrav/Running_Jump_a", "ptrav/Jump_b"]), _clip()])
		_stop()
	_check(takes.size() == 2, "running jumps alternate: %s" % [takes.keys()])
	_report("running jump")
	# THE CROUCH
	await _put(Vector3(0, 0.05, -100), 0.0)
	player.call(&"set_crouch", true)
	await _wait(1.5)
	_check(seen.has("ptrav/Standing_To_Crouched") and _clip() == "ptrav/Crouching_Idle", "into the crouch: Standing To Crouched, Crouching Idle (%s)" % _clip())
	player.call(&"set_move_tier", Vector2(0, 1), 0); await _wait(2.0)
	_check(_clip() == "ptrav/Crouched_Walking" or _clip() == "ptrav/Sneaking_Forward", "the crouch walk: %s" % _clip())
	player.call(&"set_move_tier", Vector2(1, 0), 0); await _wait(1.5)
	var c1 := _clip()
	player.call(&"set_move_tier", Vector2(-1, 0), 0); await _wait(1.5)
	var c2 := _clip()
	_check(c1.begins_with("ptrav/Crouched_Sneaking") and c2.begins_with("ptrav/Crouched_Sneaking") and c1 != c2, "sideways in the crouch: %s / %s, facing the view" % [c1, c2])
	_stop(); await _wait(1.0)
	_clear(); player.call(&"set_crouch", false); await _wait(3.6)
	_check(_any(["ptrav/Crouch_To_Stand", "ptrav/Crouched_To_Standing"]) != "" and not bool(player.call(&"get_crouch")), "out of the crouch: %s" % _any(["ptrav/Crouch_To_Stand", "ptrav/Crouched_To_Standing"]))
	player.call(&"set_crouch", true); await _wait(1.5)
	_clear(); _go(1); await _wait(1.5)
	_check(seen.has("ptrav/Crouched_To_Sprinting") and _running(_clip()), "off at a run from the crouch: Crouched To Sprinting, then %s" % _clip())
	_stop(); await _wait(1.5)
	_report("crouch")
	# OBSTACLES
	await _obstacle("bush, running", Vector3(20, 0.05, 2), 1, "run_over", 0.0, true)
	await _obstacle("bush, walking", Vector3(40, 0.05, 6), 0, "vault", 0.0, false)
	await _obstacle("thick box, running", Vector3(60, 0.05, 2), 1, "run_onto", 0.8, true)
	await _obstacle("thick box, walking", Vector3(80, 0.05, 7), 0, "climb", 0.8, false)
	await _obstacle("1.8 m wall, walking", Vector3(100, 0.05, 7), 0, "climb_high", 1.8, false)
	await _obstacle("2.3 m wall, walking", Vector3(120, 0.05, 7), 0, "climb_high", 2.3, false)
	# COVER
	await _put(Vector3(139.6, 0.05, 8.6), 0.0)
	player.call(&"set_crouch", true); await _wait(1.2)
	player.call(&"set_move_tier", Vector2(0, 1), 0)
	var in_cover := await _until(func(): return bool(_trav().get("in_cover", false)), 3.0)
	_stop(); await _wait(0.6)
	_check(in_cover and seen.has("ptrav/Stand_To_Cover_b"), "crouched into the low wall: in cover (Stand To Cover b), %s" % _clip())
	# along it toward the gap (the wall's normal faces -z: his left is -x... ask the way along it in the world)
	var sw0 := int(_trav().get("cover_switch", 0))
	var to_gap := Vector3(1, 0, 0)
	player.call(&"set_move_tier", _inp(to_gap), 0)
	var switched := await _until(func(): return int(_trav().get("cover_switch", 0)) > sw0, 8.0)
	await _wait(0.2)
	var sneak := _any(["ptrav/Crouched_Sneaking", "ptrav/Left_Cover", "ptrav/Right_Cover"])
	_check(sneak != "", "the cover walk along it: %s" % sneak)
	_check(switched, "across the gap: cover switched (%s)" % _any(["ptrav/Crouch_Cover_To_Cover"]))
	await _until(func(): return int(_trav().get("mode", 0)) == 3, 3.0)
	var pk0 := int(_trav().get("peek", 0))
	player.call(&"set_move_tier", _inp(to_gap), 0)
	var peeked := await _until(func(): return int(_trav().get("peek", 0)) > pk0, 8.0)
	await _until(func(): return int(_trav().get("mode", 0)) == 3, 4.0)
	_check(peeked, "at the far end: a look round the corner (%s)" % _any(["ptrav/Crouch_Look_Around"]))
	player.call(&"set_move_tier", _inp(-to_gap), 0); await _wait(0.5)
	_check(int(_trav().get("cover_turn", 0)) > 0 or _any(["ptrav/Crouch_Cover_Turn"]) != "", "back the other way: the cover turn")
	_stop(); await _wait(0.5)
	player.call(&"set_crouch", false)
	await _until(func(): return int(_trav().get("mode", 0)) == 0, 3.0)
	_check(_any(["ptrav/Cover_To_Stand"]) != "", "the crouch let go: out of cover (%s)" % _any(["ptrav/Cover_To_Stand"]))
	_report("cover")
	# DROPS
	var want := ["soft", "soft", "hard", "hard", "fall_landing"]
	for i in 5:
		await _drop(i, want[i], 0.1)
	await _drop(5, "messed", 1.0)
	# THE EDGE: 15 s standing still at it
	await _put(Vector3(-40 + 1.0, 1.55, -30), PI * 0.5)
	var b0 := int(_trav().get("balance", 0))
	await _wait(14.0)
	_check(int(_trav().get("balance", 0)) == b0, "at the edge, under 15 s: still standing (%s)" % _clip())
	var fell := await _until(func(): return int(_trav().get("balance", 0)) > b0, 3.0)
	await _until(func(): return int(_trav().get("mode", 0)) == 0 and player.global_position.y < 0.3, 12.0)
	_check(fell and seen.has("ptrav/Falling_From_Losing_Balance") and player.global_position.y < 0.3, "at the edge 15 s: Falling From Losing Balance, down off it (y %.2f, landed %s)" % [player.global_position.y, _trav().get("last_land", "")])
	_report("losing balance", 0.35)
	_check(ual_seen == "", "never a UAL / step traversal clip (%s)" % ual_seen)
	_end()

func _inp(w: Vector3) -> Vector2:
	var cy := float((player.call(&"get_view") as Array)[1])
	return Vector2(w.dot(Vector3(cos(cy), 0, -sin(cy))), w.dot(Vector3(-sin(cy), 0, -cos(cy))))

func _obstacle(what: String, at: Vector3, tier: int, key: String, top: float, keep_running: bool) -> void:
	await _put(at, 0.0)
	var n0 := int(_trav().get(key, 0))
	_go(tier)
	var ok := await _until(func(): return int(_trav().get(key, 0)) > n0, 8.0)
	await _until(func(): return int(_trav().get("mode", 0)) == 0, 14.0)
	await _wait(0.3)
	var y := player.global_position.y
	var cl := _clip()
	print("PTRAV  %s: %s (%s)" % [what, _trav().get("move", ""), _trav().get("obstacle", "")])
	var on_ok := absf(y - top) < 0.15 if (top > 0.0) else y < 0.2
	_check(ok and on_ok and (not keep_running or _running(cl)), "%s: %s, y %.2f (want %.2f), then %s" % [what, key, y, top, cl])
	_stop(); await _wait(1.0)
	_report(what, 0.25)

func _drop(i: int, want: String, mess: float) -> void:
	var hs := [1.5, 2.5, 4.0, 6.0, 8.0, 6.0]
	var h: float = hs[i]
	player.call(&"set_trav_mess", mess)
	await _put(Vector3(-40 + 1.0, h + 0.05, -30 + i * 12.0), PI * 0.5)
	player.call(&"jump")
	var landed := await _until(func(): return float(_trav().get("last_drop", -1.0)) > h - 0.3 and String(_trav().get("last_land", "")) != "" and int(_trav().get("mode", 0)) != 2 and player.global_position.y < 0.5, 8.0)
	var land := String(_trav().get("last_land", ""))
	await _until(func(): return int(_trav().get("mode", 0)) == 0, 16.0)
	await _wait(0.5)
	var extra := ""
	if want == "fall_landing": extra = " Falling Idle %s" % ("seen" if seen.has("ptrav/Falling_Idle") else "MISSING")
	_check(landed and land == want and (want != "fall_landing" or seen.has("ptrav/Falling_Idle")) and _clip().begins_with("pidle/"), "a drop of %.1f m: landed %s (want %s)%s, clips %s, then %s" % [h, land, want, extra, ", ".join(PackedStringArray(seen.keys().filter(func(k): return String(k).begins_with("ptrav/")))), _clip()])
	_check(_any(["ptrav/Rolling", "ptrav/Falling_To_Roll"]) == "", "no landing roll")
	player.call(&"set_trav_mess", 0.1)
	_report("drop %.1f m" % h, 0.45)

func _end() -> void:
	print("PTRAV  slides: %s" % [slide_all])
	print("PTRAV  %s (%d failed)" % ["ALL OK" if fails == 0 else "FAILED", fails])
	quit(1 if fails else 0)
