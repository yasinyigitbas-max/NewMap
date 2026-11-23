extends SceneTree
const Rig := preload("res://tests/people/rig.gd")
## The new movement system carrying things (native/src/mo_motor_carry.cpp; docs/ANIMATION_PLAN.md step 6; Yasin, 22 Nov:
## "picking objects"):
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_carry.gd [-- --trace]
## Lanes: a box (taken standing, walked, stopped, jogged, stopped, put down); a briefcase (walked, stopped). Per lane:
## the states and clips, the hands on the box's sides (drawn after the IK, against their pins), the prop's motion (no
## jump in a frame), planted feet that do not slide, the hips' rise and level speed (no pops), free hands at the end.
## What it cannot see: the fingers round the box, the box's look - Yasin plays it.
var player: CharacterBody3D
var sk: Skeleton3D
var b_pel := -1; var b_ft := [-1, -1]; var b_hd := [-1, -1]; var b_el := [-1, -1]
var box_gap := 9.0; var in_torso := 0; var snap_el := [Vector3(), Vector3()]
var fails := 0
var trace := false
var lane := -1; var t := 0.0; var t_prev := 0.0
const LANES := [["box", 1], ["briefcase", 2]]
var states := {}; var clips := {}
var s_slide := 0.0; var s_pop := 0.0; var s_dv := 0.0; var hand_miss := 0.0; var prop_jump := 0.0; var free_end := false
var plant := [null, null]
var pel_prev := Vector3(); var dy_prev := 0.0; var v_prev := Vector2(); var have := 0
var prop_prev := Vector3(); var prop_have := false; var moved := 0.0; var start_p := Vector3()

func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	trace = OS.get_cmdline_user_args().has("--trace")
	_box(Vector3(200, 2, 80), Vector3(20, -1, 20))
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.02, 0); root.add_child(player)

func _next() -> void:
	lane += 1
	if lane >= LANES.size(): _finish(); return
	player.global_position = Vector3(lane * 10.0, 0.02, 0.0); player.velocity = Vector3.ZERO
	player.call(&"set_move", Vector2.ZERO, false); player.call(&"set_carry", 0)
	box_gap = 9.0; in_torso = 0
	t = 0.0; t_prev = 0.0; states = {}; clips = {}; s_slide = 0.0; s_pop = 0.0; s_dv = 0.0; hand_miss = 0.0; prop_jump = 0.0
	plant = [null, null]; have = 0; prop_have = false; free_end = false; start_p = player.global_position

func _at(when: float) -> bool: return t_prev < when and t >= when

func _act() -> void:
	var k: int = LANES[lane][1]
	if _at(0.6): player.call(&"set_carry", k)
	if _at(1.8): player.call(&"set_move", Vector2(0, 1), false)
	if _at(4.5): player.call(&"set_move", Vector2.ZERO, false)
	if k == 1:
		if _at(6.0): player.call(&"set_move", Vector2(0, 1), true)
		if _at(8.5): player.call(&"set_move", Vector2.ZERO, false)
	if _at(10.0): player.call(&"set_carry", 0)
	if _at(11.5):
		var ms: Dictionary = player.call(&"get_motor_state")
		free_end = int(ms.get("carry", 1)) == 0 and float(ms.get("carry_w", 1.0)) <= 0.0
		moved = (player.global_position - start_p).length()
		_judge()

func _process(delta: float) -> bool:
	if not player or not player.is_inside_tree(): return false
	if sk == null:
		var s := player.find_children("*", "Skeleton3D", true, false)
		if s.is_empty(): return false
		sk = s[0]; b_pel = Rig.find(sk, "Bip01_Pelvis"); b_ft = [Rig.find(sk, "Bip01_L_Foot"), Rig.find(sk, "Bip01_R_Foot")]; b_hd = [Rig.find(sk, "Bip01_L_Hand"), Rig.find(sk, "Bip01_R_Hand")]; b_el = [Rig.find(sk, "Bip01_L_Forearm"), Rig.find(sk, "Bip01_R_Forearm")]
		sk.skeleton_updated.connect(_on_pose)
		_next(); return false
	if lane >= LANES.size(): return true
	t_prev = t; t += delta
	_act()
	return false

var pose_frame := -1; var snap_ok := false
var snap_pel := Vector3(); var snap_ft := [Vector3(), Vector3()]; var snap_hd := [Vector3(), Vector3()]; var snap_ms := {}
func _on_pose() -> void:
	var f := Engine.get_process_frames()
	if f != pose_frame and snap_ok: _sample()
	pose_frame = f
	snap_pel = sk.global_transform * sk.get_bone_global_pose(b_pel).origin
	for s in 2:
		snap_ft[s] = sk.global_transform * sk.get_bone_global_pose(b_ft[s]).origin
		snap_hd[s] = sk.global_transform * sk.get_bone_global_pose(b_hd[s]).origin
		snap_el[s] = sk.global_transform * sk.get_bone_global_pose(b_el[s]).origin
	snap_ms = player.call(&"get_motor_state")
	snap_ok = true

func _sample() -> void:
	if lane < 0 or lane >= LANES.size() or t < 0.3: return
	var ms: Dictionary = snap_ms
	var st: String = ms.get("state", "off")
	states[st] = true; clips[String(ms.get("clip", ""))] = true
	# the hands on the box's sides, fully pinned
	if int(ms.get("carry", 0)) == 1 and float(ms.get("carry_w", 0.0)) >= 0.999:
		var ht: Array = ms.get("hand_t", [])
		for s in 2:
			var miss: float = (snap_hd[s] - (ht[s] as Vector3)).length()
			if miss > hand_miss:
				hand_miss = miss
				if trace: print("TRACEH lane %d t %.2f %s hand %d miss %.3f" % [lane, t, ms.get("clip", ""), s, miss])
	# CLEAR OF THE BODY (Yasin, 23 Nov: "both box and hands go into the body"): the box's back face against the belly
	# (14 cm in front of the hips' middle), the hands and elbows outside the torso (17 cm either side of the spine,
	# from 12 cm behind to 14 cm in front of it, from the hips up 60 cm)
	if int(ms.get("carry", 0)) == 1 and float(ms.get("carry_w", 0.0)) >= 0.999:
		var yw: float = float(ms.get("yaw", 0.0)); var fw := Vector3(sin(yw), 0, cos(yw)); var lf := Vector3(cos(yw), 0, -sin(yw))
		var xf: Transform3D = ms.get("carry_xf", Transform3D())
		# (the box as drawn LAST frame: against last frame's hips - at a jog a frame is 4 cm)
		var back: float = (xf.origin - (pel_prev if have > 0 else snap_pel)).dot(fw) - 0.15 - 0.14
		if back < box_gap:
			box_gap = back
			if trace and back < 0.0: print("TRACEG lane %d t %.2f %s %s box back %.3f box %s pel %s" % [lane, t, st, ms.get("clip", ""), back, str(xf.origin), str(snap_pel)])
		for q in [snap_hd[0], snap_hd[1], snap_el[0], snap_el[1]]:
			var d: Vector3 = q - snap_pel
			if absf(d.dot(lf)) < 0.17 and d.dot(fw) > -0.12 and d.dot(fw) < 0.14 and d.y > 0.0 and d.y < 0.6:
				in_torso += 1
				if trace: print("TRACEB lane %d t %.2f %s a hand / elbow in the torso at %s" % [lane, t, ms.get("clip", ""), str(d)])
	# the prop: no jump in a frame (its own motion at most a run's pace)
	if int(ms.get("carry", 0)) != 0 and float(ms.get("carry_w", 0.0)) > 0.1:
		var pp: Vector3 = (ms.get("carry_xf", Transform3D()) as Transform3D).origin
		if prop_have:
			var j := (pp - prop_prev).length()
			if j > prop_jump: prop_jump = j; if trace: print("TRACEJ lane %d t %.2f %s prop moved %.3f" % [lane, t, ms.get("clip", ""), j])
		prop_prev = pp; prop_have = true
	for s in 2:
		var down: bool = st != "off" and bool(ms.get(["down_l", "down_r"][s], false)) and not bool(ms.get(["step_l", "step_r"][s], false))
		var a: Vector3 = snap_ft[s]
		if down and a.y - player.global_position.y > 0.15: down = false
		if not down: plant[s] = null; continue
		if plant[s] == null: plant[s] = a
		var sl := Vector2(a.x - plant[s].x, a.z - plant[s].z).length()
		if sl > s_slide:
			s_slide = sl
			if trace: print("TRACES lane %d t %.2f %s %s foot %d slide %.3f" % [lane, t, st, ms.get("clip", ""), s, sl])
	var pel: Vector3 = snap_pel
	if have > 1:
		var pop := absf((pel.y - pel_prev.y) - dy_prev)
		if pop > s_pop: s_pop = pop; if trace: print("TRACEP lane %d t %.2f %s %s pop %.3f" % [lane, t, st, ms.get("clip", ""), pop])
		var v := Vector2(pel.x - pel_prev.x, pel.z - pel_prev.z) * 60.0
		if (v - v_prev).length() > s_dv: s_dv = (v - v_prev).length(); if trace: print("TRACEV lane %d t %.2f %s %s dv %.2f" % [lane, t, st, ms.get("clip", ""), s_dv])
		v_prev = v
	elif have > 0: v_prev = Vector2(pel.x - pel_prev.x, pel.z - pel_prev.z) * 60.0
	if have > 0: dy_prev = pel.y - pel_prev.y
	pel_prev = pel; have += 1

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("CARRY   %s: %s" % ["ok  " if ok else "FAIL", what])

func _judge() -> void:
	var L = LANES[lane]
	var name: String = L[0]
	print("CARRY   %-10s states %s  hands %.1f cm  prop jump %.1f cm  slide %.1f pop %.1f cm  hips_dv %.2f  moved %.1f m  clips %s" % [name, str(states.keys()), hand_miss * 100, prop_jump * 100, s_slide * 100, s_pop * 100, s_dv, moved, str(clips.keys())])
	_check(states.has("carry"), "%s: carried (%s)" % [name, str(states.keys())])
	if L[1] == 1:
		_check(clips.has("pact/Walking_Carry") and clips.has("pact/Walk_Carry_Stop") and clips.has("pact/Jogging_With_Box_a"), "box: its walk, idle and jog played")
		_check(hand_miss < 0.03, "box: the hands on its sides (%.1f < 3 cm)" % (hand_miss * 100))
		_check(box_gap > -0.005, "box: its back clear of the belly (%.1f cm at the closest)" % (box_gap * 100))
		_check(in_torso == 0, "box: hands and elbows outside the torso (%d frames in it)" % in_torso)
	else:
		_check(clips.has("pact/Briefcase_Idle") and clips.has("pact/Walk_With_Briefcase"), "briefcase: its idle and walk played")
	_check(prop_jump < 0.07, "%s: the prop moves smoothly (%.1f cm a frame at most)" % [name, prop_jump * 100])
	_check(moved > 2.0, "%s: carried somewhere (%.1f m)" % [name, moved])
	_check(free_end, "%s: put down, the hands free again" % name)
	_check(s_slide < 0.03, "%s: planted feet do not slide (%.1f < 3 cm)" % [name, s_slide * 100])
	_check(s_pop < 0.03, "%s: no hip pop (%.1f < 3 cm)" % [name, s_pop * 100])
	_check(s_dv < 1.2, "%s: no hip speed jump (%.2f < 1.2 m/s)" % [name, s_dv])
	_next()

func _finish() -> void:
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
