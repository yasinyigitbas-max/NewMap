extends SceneTree
## The new movement system's jumps, falls and landings (native/src/mo_motor_air.cpp; docs/ANIMATION_PLAN.md step 7;
## Yasin, 23 Nov: "in place jumps are terrible, use other animations"; "better edge jump down, use soft or hard landing
## like festive work"):
##   godot --headless --path . --fixed-fps 60 -s res://tests/people/test_motor_air.gd [-- --trace]
## Lanes: a jump standing, walking, running; walked off ledges 1, 3.5 and 8 m high, run off one 2 m high. Per lane:
## the states, the landing chosen for the height fallen (under 3 m soft, from 3 m hard, from 7 m flat and up again),
## the hips' rise in a jump, the feet on the ground at the landing's touch, standing at the end on the ground below,
## the new system having him all the way.
## What it cannot see: the look of the air pose and the landing - Yasin plays it.
var player: CharacterBody3D
var sk: Skeleton3D
var b_pel := -1; var b_ft := [-1, -1]
var fails := 0
var trace := false
var lane := -1; var t := 0.0; var t_prev := 0.0
# [name, ledge height (0: flat), run, what to do]
const LANES := [["jump standing", 0.0, false, "jump"], ["jump walking", 0.0, false, "walkjump"], ["jump running", 0.0, true, "walkjump"],
	["step off 0.5 m", 0.5, false, "off"], ["off a 1 m ledge", 1.0, false, "off"], ["off a 1.8 m ledge", 1.8, false, "off"], ["off a 3.5 m ledge", 3.5, false, "off"], ["off an 8 m ledge", 8.0, false, "off"], ["run off a 2 m ledge", 2.0, true, "off"]]
var states := {}; var clips := {}
var pel_lo := 9.0; var pel_hi := -9.0; var off_frames := 0; var touch_miss := -1.0; var in_land := false
var land_y := 0.0
var foot_lo := 9.0

func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	trace = OS.get_cmdline_user_args().has("--trace")
	for i in LANES.size():
		var h: float = LANES[i][1]; var x := i * 12.0
		# the ground: a ledge h high from z -6 to 2, then the ground h lower
		_box(Vector3(10, 2, 30), Vector3(x, -1.0 - h, 12))
		if h > 0.0: _box(Vector3(10, h, 8), Vector3(x, -h * 0.5, -2))
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, -1.0); root.add_child(player)

func _next() -> void:
	lane += 1
	if lane >= LANES.size(): _finish(); return
	var h: float = LANES[lane][1]
	player.global_position = Vector3(lane * 12.0, 0.05, -3.0 if h > 0.0 else 0.0); player.velocity = Vector3.ZERO
	player.call(&"set_move", Vector2.ZERO, false)
	t = 0.0; t_prev = 0.0; states = {}; clips = {}; pel_lo = 9.0; pel_hi = -9.0; off_frames = 0; touch_miss = -1.0; in_land = false; foot_lo = 9.0
	land_y = -h

func _at(w: float) -> bool: return t_prev < w and t >= w

func _act() -> void:
	var L = LANES[lane]
	match L[3]:
		"jump":
			if _at(1.0): player.call(&"jump")
		"walkjump":
			if _at(0.6): player.call(&"set_move", Vector2(0, 1), L[2])
			if _at(2.2): player.call(&"jump")
			if _at(3.6): player.call(&"set_move", Vector2.ZERO, false)
		"off":
			if _at(0.6): player.call(&"set_move", Vector2(0, 1), L[2])
			if _at(7.0): player.call(&"set_move", Vector2.ZERO, false)
	if _at(14.0): _judge()

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
	_act()
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
	if lane < 0 or lane >= LANES.size() or t < 0.4: return
	var ms: Dictionary = snap_ms
	var st: String = ms.get("state", "off")
	states[st] = true; clips[String(ms.get("clip", ""))] = true
	if st == "off": off_frames += 1
	pel_hi = maxf(pel_hi, snap_pel.y); pel_lo = minf(pel_lo, snap_pel.y)
	foot_lo = minf(foot_lo, minf(snap_ft[0].y, snap_ft[1].y))
	# the feet at the landing's touch: the first frame of the landing with a foot down, its height over the ground
	if st == "land" and not in_land:
		in_land = true
	if in_land and touch_miss < 0.0 and (bool(ms.get("down_l", false)) or bool(ms.get("down_r", false))):
		var lowf := minf(snap_ft[0].y, snap_ft[1].y)
		touch_miss = absf(lowf - land_y - 0.105)
		if trace: print("TRACET lane %d t %.2f %s foot %.3f ground %.3f" % [lane, t, ms.get("clip", ""), lowf, land_y])
	if trace: print("TRACE lane %d t %.3f %s %s pel %s body %s" % [lane, t, st, ms.get("clip", ""), str(snap_pel), str(player.global_position)])

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("AIR     %s: %s" % ["ok  " if ok else "FAIL", what])

func _judge() -> void:
	var L = LANES[lane]
	var name: String = L[0]
	var ms: Dictionary = player.call(&"get_motor_state")
	var p := player.global_position
	print("AIR     %-20s states %s  hips %.2f..%.2f  touch %.1f cm  fallen %.2f  at %s  clips %s" % [name, str(states.keys()), pel_lo, pel_hi, touch_miss * 100, float(ms.get("fallen", 0.0)), str(p.snapped(Vector3.ONE * 0.01)), str(clips.keys())])
	_check(off_frames == 0, "%s: the new system had him all the way (%d frames not)" % [name, off_frames])
	if L[3] == "jump" or L[3] == "walkjump":
		_check(states.has("air") or states.has("runjump"), "%s: a jump" % name)
		if not L[2]: _check(pel_hi > 0.86 + (0.2 if L[3] == "jump" else 0.35), "%s: off the ground (hips up to %.2f m)" % [name, pel_hi])
		if L[2]: _check(clips.has("ptrav/Running_Jump_a"), "%s: the running leap" % name)
		elif L[3] == "jump": _check(clips.has("ptrav/Jump_a"), "%s: the standing jump (Jump_a)" % name)
		else: _check(clips.has("ptrav/Jumping_c"), "%s: the walking leap (Jumping_c)" % name)
	else:
		var h: float = L[1]
		if not L[2] and h <= 2.0:   # walking off a ledge up to 2 m: down it, not off it (Yasin, 23 Nov: "step down or slower jump down or climb down when not running")
			var dw := "ptrav/Jumping_Down_b" if h <= 1.2 else "mx/Climbing_Down"
			_check(states.has("descend") and clips.has(dw) and not states.has("air"), "%s: down it with %s, no fall" % [name, dw])
			_check(foot_lo > land_y + 0.105 - 0.05, "%s: the feet never under the ground (lowest %.2f over it)" % [name, foot_lo - land_y - 0.105])
			_check(absf(p.y - land_y) < 0.1 and String(ms.get("state", "")) in ["idle", "stop", "move"], "%s: standing again on the ground (at %.2f, %s)" % [name, p.y, ms.get("state", "")])
			_next(); return
		var want := "ptrav/Falling_To_Landing" if h < 3.0 else ("ptrav/Hard_Landing_b" if h < 7.0 else "ptrav/Falling_Flat_Impact")
		_check(clips.has(want), "%s: the %s landing (%s)" % [name, "soft" if h < 3.0 else ("hard" if h < 7.0 else "flat"), want])
		if h >= 7.0: _check(clips.has("ptrav/Getting_Up"), "%s: up again after the fall" % name)
		_check(touch_miss >= 0.0 and touch_miss < 0.06, "%s: the feet on the ground at the landing's touch (%.1f cm off)" % [name, touch_miss * 100])
	_check(absf(p.y - land_y) < 0.1 and String(ms.get("state", "")) in ["idle", "stop", "move"], "%s: standing again on the ground (at %.2f, %s)" % [name, p.y, ms.get("state", "")])
	_next()

func _finish() -> void:
	print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
