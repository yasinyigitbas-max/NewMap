extends SceneTree
const Rig := preload("res://tests/people/rig.gd")
## Sitting (native/src/mo_motor_sit.cpp; Yasin, 24 Nov: "add sitting animations"): a bench ahead, sit_at(its top's
## middle, facing back the way he came) - he walks to it, turns his back to it, sits; stays (two idle loops and the longer
## take between); stand_up - he stands and is free again. Seats 0.35, 0.45 and 0.6 m high.
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_sit.gd [-- --trace]
## Per lane: the states; the hips on the seat (the hip joints 4-12 cm over its top, over its middle within 10 cm) while
## seated; the feet on the ground seated; no hip pop (its rise changing more than 3 cm a frame); standing at the end.
## What it cannot see: the look - Yasin plays it.
var player: CharacterBody3D
var ankle_stand := 0.105; var stood := false; var st_sum := 0.0; var st_n := 0
var sk: Skeleton3D; var b_pel := -1; var b_ft := [-1, -1]; var b_th := [-1, -1]
var fails := 0; var trace := false
var lane := -1; var t := 0.0; var t_prev := 0.0
const LANES := [0.45, 0.35, 0.6]
const SEAT_Z := 3.0
var states := {}; var clips := {}; var seat_err := 0.0; var seat_n := 0; var foot_float := 0.0; var pop := 0.0
var pel_prev := Vector3(); var dy_prev := 0.0; var have := 0

func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	trace = OS.get_cmdline_user_args().has("--trace")
	_box(Vector3(80, 2, 40), Vector3(10, -1, 0))
	for i in LANES.size(): _box(Vector3(1.6, LANES[i], 0.45), Vector3(i * 8.0, LANES[i] * 0.5, SEAT_Z + 0.05))
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)

func _next() -> void:
	lane += 1
	if lane >= LANES.size(): _finish(); return
	player.global_position = Vector3(lane * 8.0, 0.05, 0.0); player.velocity = Vector3.ZERO
	t = 0.0; t_prev = 0.0; states = {}; clips = {}; seat_err = 0.0; seat_n = 0; foot_float = 0.0; pop = 0.0; have = 0; stood = false; st_sum = 0.0; st_n = 0

func _at(w: float) -> bool: return t_prev < w and t >= w

func _process(delta: float) -> bool:
	if not player or not player.is_inside_tree(): return false
	if sk == null:
		var s := player.find_children("*", "Skeleton3D", true, false)
		if s.is_empty(): return false
		sk = s[0]; b_pel = Rig.find(sk, "Bip01_Pelvis"); b_ft = [Rig.find(sk, "Bip01_L_Foot"), Rig.find(sk, "Bip01_R_Foot")]; b_th = [Rig.find(sk, "Bip01_L_Thigh"), Rig.find(sk, "Bip01_R_Thigh")]
		sk.skeleton_updated.connect(_on_pose)
		_next(); return false
	if lane >= LANES.size(): return true
	t_prev = t; t += delta
	var h: float = LANES[lane]
	if _at(0.8): player.call(&"sit_at", Vector3(lane * 8.0, h, SEAT_Z), PI)   # (facing back the way he came)
	if _at(22.0): player.call(&"stand_up")
	if _at(27.0): _judge()
	return false

var pose_frame := -1
func _on_pose() -> void:
	var f := Engine.get_process_frames()
	if f == pose_frame or lane < 0 or lane >= LANES.size() or t < 0.5: return
	pose_frame = f
	var ms: Dictionary = player.call(&"get_motor_state")
	var st: String = ms.get("state", "")
	states[st] = true; clips[String(ms.get("clip", ""))] = true
	# (the hip JOINTS' middle: the old figure's pelvis bone sits at them, a standard-skeleton body's above them)
	var pel: Vector3 = (sk.global_transform * sk.get_bone_global_pose(b_th[0]).origin + sk.global_transform * sk.get_bone_global_pose(b_th[1]).origin) * 0.5
	var h: float = LANES[lane]
	if st == "idle" and t > 0.3 and t < 1.0 and not stood:
		var a0: float = (sk.global_transform * sk.get_bone_global_pose(b_ft[0]).origin).y; var a1: float = (sk.global_transform * sk.get_bone_global_pose(b_ft[1]).origin).y
		st_sum += minf(a0, a1) - player.global_position.y; st_n += 1; ankle_stand = st_sum / st_n
	if st != "idle" and t > 0.3: stood = true
	if st == "sit":
		var over := pel.y - h
		var off := Vector2(pel.x - lane * 8.0, pel.z - SEAT_Z).length()
		seat_err = maxf(seat_err, maxf(maxf(0.04 - over, over - 0.12), off - 0.10)); seat_n += 1
		for s in 2:
			var fy: float = (sk.global_transform * sk.get_bone_global_pose(b_ft[s]).origin).y
			foot_float = maxf(foot_float, absf(fy - ankle_stand))   # (against his own standing ankle - the old figure 10.2 cm, the player v3 14.3; Sitting_Idle lifts the heels ~5 cm: within 6 cm)
		if trace and (seat_n % 60 == 1 or off > 0.1 or over > 0.12 or over < 0.04): print("TRACE lane %d t %.2f sit pel %s over %.3f off %.3f" % [lane, t, str(pel), over, off])
	if have > 1 and absf((pel.y - pel_prev.y) - dy_prev) > pop:
		pop = absf((pel.y - pel_prev.y) - dy_prev)
		if trace and pop > 0.03: print("TRACEP lane %d t %.2f %s %s ct %.2f pop %.3f pel %s" % [lane, t, st, ms.get("clip", ""), float(ms.get("t", 0)), pop, str(pel)])
	if have > 0: dy_prev = pel.y - pel_prev.y
	pel_prev = pel; have += 1

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("SIT     %s: %s" % ["ok  " if ok else "FAIL", what])

func _judge() -> void:
	var h: float = LANES[lane]; var name := "seat %.2f m" % h
	var ms: Dictionary = player.call(&"get_motor_state")
	print("SIT     %-10s states %s clips %s" % [name, str(states.keys()), str(clips.keys())])
	_check(states.has("sit_in") and states.has("sit") and states.has("sit_out"), "%s: down, sitting, up (%s)" % [name, str(states.keys())])
	_check(clips.keys().any(func(c): return String(c) in ["yl/Sitting_talking", "yl/Sitting_Disapproval", "yl/Sitting_Disbelief"]), "%s: a gesture between the idle's loops" % name)
	_check(seat_n > 0 and seat_err <= 0.0, "%s: the hips on the seat while sitting (worst %.1f cm out)" % [name, seat_err * 100])
	_check(foot_float < 0.06, "%s: the feet on the ground sitting (%.1f cm off at most, against his standing ankle %.1f cm)" % [name, foot_float * 100, ankle_stand * 100])
	_check(pop < 0.03, "%s: no hip pop (%.1f cm a frame at most)" % [name, pop * 100])
	_check(String(ms.get("state", "")) in ["idle", "stop", "move"] and absf(player.global_position.y) < 0.1, "%s: standing again (%s)" % [name, ms.get("state", "")])
	_next()

func _finish() -> void:
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
