extends SceneTree
## The new movement system's crouch and cover (native/src/mo_motor_cover.cpp; docs/ANIMATION_PLAN.md step 5; Yasin, 22
## Nov: "taking cover"):
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_cover.gd [-- --trace]
## Lanes: the crouch (down, a crouched walk, up); cover at a tall wall (in, along it both ways to its end, out); cover at
## a low wall (the same, crouched). Per lane it checks the states it went through, the hips' height (crouched / standing),
## in cover the body's distance to the wall and that it never goes past the wall's end, planted feet that do not slide,
## and the hips' rise and level speed (no pops).
## What it cannot see: where his back and hands are against the wall, the look - Yasin plays it.
var player: CharacterBody3D
var sk: Skeleton3D
var b_pel := -1; var b_ft := [-1, -1]
var fails := 0
var trace := false
var lane := -1; var t := 0.0
const WALL_Z := 3.0
const WALL_W := 6.0
# [name, wall height (0: none)]
const LANES := [["crouch", 0.0], ["tall cover", 2.4], ["low cover", 1.0]]
var states := {}; var clips := {}
var s_slide := 0.0; var s_pop := 0.0; var s_dv := 0.0; var pel_min := 9.0; var pel_max := -9.0
var gap_min := 9.0; var gap_max := -9.0; var x_min := 9e9; var x_max := -9e9
var plant := [null, null]
var pel_prev := Vector3(); var dy_prev := 0.0; var v_prev := Vector2(); var have := 0
var low_seen := 9.0; var high_end := 0.0

func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	trace = OS.get_cmdline_user_args().has("--trace")
	_box(Vector3(200, 2, 60), Vector3(20, -1, 10))
	for i in LANES.size():
		var h: float = LANES[i][1]
		if h > 0.0: _box(Vector3(WALL_W, h, 0.3), Vector3(i * 12.0, h * 0.5, WALL_Z + 0.15))
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.02, 0); root.add_child(player)

func _next() -> void:
	lane += 1
	if lane >= LANES.size(): _finish(); return
	player.global_position = Vector3(lane * 12.0, 0.02, 1.6); player.velocity = Vector3.ZERO
	player.call(&"set_move", Vector2.ZERO, false); player.call(&"set_crouch", false)
	t = 0.0; states = {}; clips = {}; s_slide = 0.0; s_pop = 0.0; s_dv = 0.0; pel_min = 9.0; pel_max = -9.0
	gap_min = 9.0; gap_max = -9.0; x_min = 9e9; x_max = -9e9; plant = [null, null]; have = 0

# the script of each lane: [time, what]
func _act() -> void:
	var L = LANES[lane]
	match L[0]:
		"crouch":
			if _at(0.6): player.call(&"set_crouch", true)
			if _at(2.0): player.call(&"set_move", Vector2(0, 1), false)
			if _at(4.0): player.call(&"set_move", Vector2.ZERO, false)
			if _at(5.0): player.call(&"set_crouch", false)
			if _at(7.0): _judge()
		_:
			if _at(0.6): player.call(&"request_cover")
			if _at(2.8): player.call(&"set_move", Vector2(1, 0), false)    # (along the wall one way, past its end)
			if _at(7.5): player.call(&"set_move", Vector2(-1, 0), false)   # (and back the other)
			if _at(10.5): player.call(&"set_move", Vector2.ZERO, false)
			if _at(11.5): player.call(&"request_cover")
			if _at(14.0): _judge()

var t_prev := 0.0
func _at(when: float) -> bool: return t_prev < when and t >= when

func _process(delta: float) -> bool:
	if not player or not player.is_inside_tree(): return false
	if sk == null:
		var s := player.find_children("*", "Skeleton3D", true, false)
		if s.is_empty(): return false
		sk = s[0]; b_pel = sk.find_bone("Bip01_Pelvis"); b_ft = [sk.find_bone("Bip01_L_Foot"), sk.find_bone("Bip01_R_Foot")]
		sk.skeleton_updated.connect(_on_pose)
		_next(); return false
	if lane >= LANES.size(): return true
	t_prev = t; t += delta
	var cur := lane
	_act()
	if lane != cur: t_prev = 0.0
	return false

var pose_frame := -1; var snap_ok := false
var snap_pel := Vector3(); var snap_ft := [Vector3(), Vector3()]; var snap_ms := {}
func _on_pose() -> void:
	var f := Engine.get_process_frames()
	if f != pose_frame and snap_ok: _sample()
	pose_frame = f
	snap_pel = sk.global_transform * sk.get_bone_global_pose(b_pel).origin
	for s in 2: snap_ft[s] = sk.global_transform * sk.get_bone_global_pose(b_ft[s]).origin
	snap_ms = player.call(&"get_motor_state")
	snap_ok = true

func _sample() -> void:
	if lane < 0 or lane >= LANES.size() or t < 0.3: return
	var ms: Dictionary = snap_ms
	var st: String = ms.get("state", "off")
	states[st] = true; clips[String(ms.get("clip", ""))] = true
	var pel: Vector3 = snap_pel
	if st == "crouch" or (st == "cover" and LANES[lane][1] < 1.45): pel_min = minf(pel_min, pel.y)
	if t > (6.5 if LANES[lane][0] == "crouch" else 13.5): high_end = pel.y
	if st == "cover":
		var g: float = float(ms.get("cover_gap", -1.0))
		if g > 0.0: gap_min = minf(gap_min, g); gap_max = maxf(gap_max, g)
		var p := player.global_position
		x_min = minf(x_min, p.x - lane * 12.0); x_max = maxf(x_max, p.x - lane * 12.0)
	for s in 2:
		var down: bool = st != "off" and bool(ms.get(["down_l", "down_r"][s], false)) and not bool(ms.get(["step_l", "step_r"][s], false))
		var a: Vector3 = snap_ft[s]
		if not down: plant[s] = null; continue
		if plant[s] == null: plant[s] = a
		var sl := Vector2(a.x - plant[s].x, a.z - plant[s].z).length()
		if sl > s_slide:
			s_slide = sl
			if trace: print("TRACES lane %d t %.2f %s %s foot %d slide %.3f" % [lane, t, st, ms.get("clip", ""), s, sl])
	if have > 1:
		var pop := absf((pel.y - pel_prev.y) - dy_prev)
		if pop > s_pop: s_pop = pop; if trace: print("TRACEP lane %d t %.2f %s %s pop %.3f" % [lane, t, st, ms.get("clip", ""), pop])
		var v := Vector2(pel.x - pel_prev.x, pel.z - pel_prev.z) * 60.0
		if (v - v_prev).length() > s_dv: s_dv = (v - v_prev).length(); if trace: print("TRACEV lane %d t %.2f %s %s dv %.2f" % [lane, t, st, ms.get("clip", ""), s_dv])
		v_prev = v
	elif have > 0: v_prev = Vector2(pel.x - pel_prev.x, pel.z - pel_prev.z) * 60.0
	if have > 0: dy_prev = pel.y - pel_prev.y
	if trace: print("TRACE lane %d t %.3f %s %s pel %s body %s gap %.3f v %s ct %.3f fol %s off %.2f" % [lane, t, st, ms.get("clip", ""), str(pel), str(player.global_position), float(ms.get("cover_gap", -1.0)), str(ms.get("dbg_v", Vector3())), float(ms.get("dbg_t", 0.0)), str(ms.get("follow_v", Vector3())), float(ms.get("sneak_off", 0.0))])
	pel_prev = pel; have += 1

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("COVER   %s: %s" % ["ok  " if ok else "FAIL", what])

func _judge() -> void:
	var L = LANES[lane]
	var name: String = L[0]
	var ms: Dictionary = player.call(&"get_motor_state")
	print("COVER   %-12s states %s  hips low %.2f, at the end %.2f  gap %.2f-%.2f  along %.2f..%.2f  slide %.1f pop %.1f cm  hips_dv %.2f  sneaks %d  clips %s" % [name, str(states.keys()), pel_min, high_end, gap_min, gap_max, x_min, x_max, s_slide * 100, s_pop * 100, s_dv, int(ms.get("sneaks", 0)), str(clips.keys())])
	if name == "crouch":
		_check(states.has("stance") and states.has("crouch"), "crouch: down and up by their clips (%s)" % str(states.keys()))
		_check(clips.has("ptrav/Crouched_Walking"), "crouch: the crouched walk played")
		_check(pel_min < 0.62, "crouch: the hips low while crouched (%.2f m)" % pel_min)
	else:
		var tall: bool = L[1] >= 1.45
		_check(states.has("cover_in") and states.has("cover") and states.has("cover_out"), "%s: in, held, out (%s)" % [name, str(states.keys())])
		_check(clips.has("ptrav/" + ("Cover_Idle" if tall else "Crouch_Cover_Idle")), "%s: the %s cover idle" % [name, "standing" if tall else "crouched"])
		_check(int(ms.get("sneaks", 0)) >= 2, "%s: along the wall both ways (%d sneaks)" % [name, int(ms.get("sneaks", 0))])
		var d: float = 0.30 if tall else 0.38
		_check(gap_min > d - 0.1 and gap_max < d + 0.1, "%s: held at the wall (%.2f-%.2f m, wanted %.2f)" % [name, gap_min, gap_max, d])
		_check(x_max < WALL_W * 0.5 + 0.05 and x_min > -WALL_W * 0.5 - 0.05, "%s: never past the wall's ends (%.2f..%.2f, ends at +-%.1f)" % [name, x_min, x_max, WALL_W * 0.5])
		_check(x_max - x_min > 1.5, "%s: moved along it (%.2f m)" % [name, x_max - x_min])
		if not tall: _check(pel_min < 0.62, "%s: crouched behind it (hips %.2f m)" % [name, pel_min])
	_check(high_end > 0.78, "%s: standing again at the end (hips %.2f m)" % [name, high_end])
	_check(s_slide < 0.03, "%s: planted feet do not slide (%.1f < 3 cm)" % [name, s_slide * 100])
	_check(s_pop < 0.03, "%s: no hip pop (%.1f < 3 cm)" % [name, s_pop * 100])
	_check(s_dv < 1.2, "%s: no hip speed jump (%.2f < 1.2 m/s)" % [name, s_dv])
	_next()

func _finish() -> void:
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
