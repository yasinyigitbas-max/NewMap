extends Node3D
## The character on the body: poses the skeleton from baked clips. It only looks; it never moves the body.
## The mesh and skeleton are Mixamo's rig of player_v4; the clips are the ones Mixamo fitted to him, baked.

const Feet := preload("res://traversal/character/feet.gd")
const DIR := "res://traversal/character/clips/"
const MODEL := "res://traversal/character/player_v4.scn"
# the loops that make up moving on foot, slowest first (their speeds are read from the clips)
const GAITS := ["Standing_Idle", "Walking_4", "Walking", "Running_3", "Running"]
const FADE := 0.20              # seconds to blend from one kind of motion to the next
# the Jump clip: it dips to its lowest at 0.50 s, leaves the ground at 0.80 s and lands at 1.30 s (measured)
const JUMP_LOW := 0.50
const JUMP_OFF := 0.80
const JUMP_LAND := 1.30
const LAND_CONTACT := 0.27      # Falling To Landing: the feet touch at 0.27 s
const HARD_CONTACT := 0.60      # Hard Landing: the feet touch at 0.60 s
# Arms (Yasin, 25 Nov play-test: "his arms are almost sticking to his body, they need to open up a bit"). The clips
# were captured on a slim mannequin; his chest and upper arms are thicker, so each upper arm is swung out from the chest.
var arm_open_deg := 9.0         # NOT in the study: set by eye on his body
# Lean into a turn: tan(lean) = speed x turn rate / g, and no more than people were measured to lean: 6.8 deg at a
# normal walk (4.4 slow, 12.7 fast), 13.6 deg on a sprinted curve.
const LEAN_WALK_DEG := 6.8
const LEAN_RUN_DEG := 13.0
const LEAN_TIME := 0.15         # NOT in the study: how quickly the lean follows (seconds)
# Starts, stops and turns on the spot (Stage 5). The body keeps its own speeds; the clips are played by distance
# (a start by how far he has gone, a stop by how far he still has to go) and a turn by angle, so the feet keep pace
# with what the body really does. The study: a walk is steady in about three steps and stops in under two; a run
# stops over several; a turn on the spot takes 3 to 4 steps for 180 degrees.
const START_WALK := "Female_Start_Walking"      # 1.87 s, 1.71 m: the closer of his two walk starts to "three steps"
const START_RUN := "Idle_To_Sprint"             # 0.80 s, 1.67 m
const STOP_WALK := "Female_Stop_Walking"        # 1.53 s, 1.49 m (the other, Stop Walking, takes 3.0 s)
const STOP_RUN := "Run_To_Stop"                 # 0.90 s, 0.80 m
const TURN_90 := "Left_Turn_90"                 # 0.93 s, exactly 90 deg (Right Turn 90 turns 102.6: the mirror is used)
const TURN_180_WALK := "Walking_Turn_180"       # 1.00 s, turns to his right
const RUN_FROM := 2.5           # above this speed the run clips are used (his jog loop is 2.53 m/s)
# Stairs are their own movement (the study: "going up and going down are different movements"): his four stair clips,
# two steps a loop, played by where he is on the stairs so that each foot comes down in the middle of a tread.
const STAIRS := {1: ["Ascending_Stairs", "Running_Up_Stairs"], -1: ["Descending_Stairs", "Run_Down_Stairs"]}
# Head: "people turn head first", about 15 deg into a curve and 15 to 30 deg of lead; the trunk does not lead
const LOOK_MOST_DEG := 30.0
const LOOK_RATE_DEG := 100.0    # well under the 137 to 272 deg/s measured for deliberate turns
const HARD_DROP := 1.5          # drops from this height use the hard landing (the soft clip was a 1.03 m drop, the hard one 2.08 m)

var body: CharacterBody3D
var skel: Skeleton3D
var clips := {}
var phase := 0.0                # 0..1 through a stride; 0 = left foot furthest forward
var _idle_t := 0.0
var _mode := ""
var _mode_t := 0.0
var _land_clip := ""
var _land_from := 0.0
var _jump_from := JUMP_LOW
var _n := 0
var _rot: Array[Quaternion] = []
var _from: Array[Quaternion] = []
var _hips := Vector3.ZERO
var _from_hips := Vector3.ZERO
var _fade := 1.0
var _hips_i := 0
var note := ""
var lean := 0.0                 # radians, + = to his left
var _pivot: Node3D
var _last_dir := Vector3.ZERO
var _arm := [-1, -1]            # left, right upper arm
var _chest := -1
var _chain: Array[int] = []     # hips ... chest, the bones above the shoulders
var _chest_rest_inv := Quaternion.IDENTITY
var feet: RefCounted
var sub := "loop"               # within moving on foot: loop, start, stop or spot (turning on the spot)
var _clip: Resource             # the start, stop or turn clip being played
var _clip_t := 0.0
var _gone := 0.0                # distance covered since a start began
var _slope := 0.0               # the stair clip's own slope, faded in and out with the clip
var _floor := {}                # per stair clip: where its own stairs stand under the hips
var _floor_now := 0.0
var _reach := {}                # per stair clip: how far ahead of the hips the left foot comes down
var _still_at := -1.0           # a stop: how far along the clip he was when the body came to rest
var _legs_i: Array[int] = []
var _neck := -1
var _head := -1
var _look := 0.0
var foot_pin := true            # planted feet held in place
var foot_ground := true         # feet fitted to the ground under them


func _ready() -> void:
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	model.rotation.y = PI      # the clips face +Z, the body faces -Z
	_pivot = Node3D.new()      # turns about the feet, for the lean
	add_child(_pivot)
	_pivot.add_child(model)
	skel = _find_skeleton(model)
	_n = skel.get_bone_count()
	_hips_i = skel.find_bone("mixamorig_Hips")
	for f in DirAccess.get_files_at(DIR):
		var name := f.replace(".remap", "")
		if name.ends_with(".res"):
			clips[name.get_basename()] = load(DIR + name)
	for i in _n:
		_rot.append(skel.get_bone_rest(i).basis.get_rotation_quaternion())
		_from.append(_rot[i])
	_hips = skel.get_bone_rest(_hips_i).origin
	_from_hips = _hips
	_arm = [skel.find_bone("mixamorig_LeftArm"), skel.find_bone("mixamorig_RightArm")]
	_chest = skel.find_bone("mixamorig_Spine2")
	var b := _chest
	while b >= 0:
		_chain.push_front(b)
		b = skel.get_bone_parent(b)
	_chest_rest_inv = skel.get_bone_global_rest(_chest).basis.get_rotation_quaternion().inverse()
	_neck = skel.find_bone("mixamorig_Neck")
	_head = skel.find_bone("mixamorig_Head")
	for n: String in ["LeftUpLeg", "LeftLeg", "RightUpLeg", "RightLeg"]:
		_legs_i.append(skel.find_bone("mixamorig_" + n))
	_make_mirrors()
	if body:
		feet = Feet.new()
		feet.call(&"setup", skel, body)
	if body:
		body.connect(&"jump_started", _on_jump_started)
		body.connect(&"landed", _on_landed)


## Mirror images of the clips that exist for one side only ("~" after the name).
func _make_mirrors() -> void:
	var parents := PackedInt32Array()
	var rest: Array[Quaternion] = []
	var pair := PackedInt32Array()
	for i in _n:
		parents.append(skel.get_bone_parent(i))
		rest.append(skel.get_bone_global_rest(i).basis.get_rotation_quaternion())
		var name := skel.get_bone_name(i)
		var other := name.replace("Left", "#").replace("Right", "Left").replace("#", "Right")
		pair.append(skel.find_bone(other) if other != name and skel.find_bone(other) >= 0 else i)
	for name: String in [STOP_WALK, STOP_RUN, TURN_90, TURN_180_WALK]:
		if clips.has(name):
			clips[name + "~"] = clips[name].call(&"mirrored", parents, rest, pair)


func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _find_skeleton(c)
		if s:
			return s
	return null


func _on_jump_started(push: float) -> void:
	_jump_from = JUMP_OFF - push
	_set_mode("jump")


func _on_landed(drop: float) -> void:
	if _mode == "jump" and drop < 0.9:
		_land_clip = "Jump"
		_land_from = JUMP_LAND
	elif drop >= HARD_DROP:
		_land_clip = "Hard_Landing"
		_land_from = HARD_CONTACT
	elif drop >= 0.35:
		_land_clip = "Falling_To_Landing"
		_land_from = LAND_CONTACT
	else:
		_set_mode("move")
		return
	_set_mode("land")


func _set_mode(m: String) -> void:
	if m == _mode:
		return
	_mode = m
	_mode_t = 0.0
	sub = "loop"
	_blend_from_here()


func _blend_from_here() -> void:
	for i in _n:
		_from[i] = _rot[i]
	_from_hips = _hips
	_fade = 0.0


func _physics_process(dt: float) -> void:
	if body == null or clips.is_empty():
		return
	var state := int(body.get(&"state"))
	var in_air := state >= 2
	_mode_t += dt
	if _mode == "" or (_mode == "move" and in_air) or (_mode == "jump" and in_air and _mode_t > 0.9):
		_set_mode("fall" if in_air else "move")
	elif _mode == "fall" and not in_air:
		_set_mode("move")
	elif _mode == "jump" and not in_air and float(body.get(&"jump_timer")) <= 0.0 and _mode_t > 0.35:
		_set_mode("move")
	elif _mode == "land":
		var c: Resource = clips[_land_clip]
		if in_air:
			_set_mode("fall")
		elif _land_from + _mode_t >= float(c.get(&"length")) - 0.05 or ((body.get(&"hvel") as Vector3).length() > 1.0 and _mode_t > 0.45):
			_set_mode("move")

	var rot: Array[Quaternion] = []
	rot.resize(_n)
	var hips := Vector3.ZERO
	match _mode:
		"move":
			hips = _on_foot(dt, rot)
		"fall":
			var c: Resource = clips["Falling_Idle"]
			hips = _clip_pose(c, fmod(_mode_t, float(c.get(&"length"))), rot)
		"jump":
			var c: Resource = clips["Jump"]
			var t := _jump_from + _mode_t
			if in_air:
				# through the clip's time in the air at the pace of the body's own flight
				var flight := 2.0 * sqrt(2.0 * 9.8 * 0.45) / 9.8
				t = JUMP_OFF + (JUMP_LAND - JUMP_OFF) * clampf(float(body.get(&"air_time")) / flight, 0.0, 1.0)
			else:
				t = minf(t, JUMP_OFF)
			hips = _clip_pose(c, t, rot)
			# the clip's own rise is taken out: the body does the rising
			hips.y = minf(hips.y, (c.call(&"hips_at", JUMP_OFF) as Vector3).y) if in_air else hips.y
		"land":
			var c: Resource = clips[_land_clip]
			hips = _clip_pose(c, minf(_land_from + _mode_t, float(c.get(&"length"))), rot)
			hips.y = minf(hips.y, _stand_height())

	_open_arms(rot)
	_look_ahead(rot, dt, state == 0)
	_lean(dt, state == 0)
	_fade = minf(_fade + dt / FADE, 1.0)
	var k := _fade * _fade * (3.0 - 2.0 * _fade)
	for i in _n:
		_rot[i] = _from[i].slerp(rot[i], k) if k < 1.0 else rot[i]
		skel.set_bone_pose_rotation(i, _rot[i])
	_hips = _from_hips.lerp(hips, k)
	var drop := 0.0
	if feet:
		feet.set(&"pinning", foot_pin)
		feet.set(&"grounding", foot_ground)
		drop = feet.call(&"solve", _rot, _hips, dt, state == 0)
	skel.set_bone_pose_position(_hips_i, _hips + Vector3(0.0, drop, 0.0))
	note = "%s%s  stride phase %.2f" % [_mode, (" / " + sub) if _mode == "move" else "", phase]


## Moving on foot: which of loop, start, stop or turn-on-the-spot is showing, and its pose.
func _on_foot(dt: float, out: Array[Quaternion]) -> Vector3:
	var speed := (body.get(&"hvel") as Vector3).length()
	var wish := (body.get(&"_wish") as Vector3).length()
	var spot := float(body.get(&"spot_total"))
	var st := int(body.get(&"stairs"))
	# changes
	if st != 0 and speed > 0.15 and (sub == "loop" or sub == "start"):
		sub = "stairs"
		_blend_from_here()
	elif sub == "stairs" and (st == 0 or speed < 0.1):
		_to_loop(speed)
	elif spot != 0.0 and sub != "spot":
		var big := absf(spot) > deg_to_rad(120.0)
		var name: String = TURN_180_WALK if big else TURN_90
		# the 180 clip turns to his right, the 90 to his left: the mirror image for the other way
		_begin(name if (spot < 0.0) == big else name + "~", "spot")
	elif sub == "spot" and spot == 0.0:
		if wish > 0.05:
			_begin(START_RUN if wish > RUN_FROM else START_WALK, "start")
		else:
			_to_loop(wish)
	elif sub == "loop" and speed < 0.3 and wish > 0.05:
		_begin(START_RUN if wish > RUN_FROM else START_WALK, "start")
	elif (sub == "loop" or sub == "start") and wish < 0.05 and speed > 0.3 and st == 0:
		var name := STOP_RUN if speed > RUN_FROM else STOP_WALK
		var c: Resource = clips[name]
		var left := float(body.call(&"stop_distance"))
		var total := (c.get(&"travel") as Vector3).length()
		if left <= total:
			# the clip or its mirror image, whichever has the legs nearer to where they are now
			var t := float(c.call(&"time_for_dist", total - left))
			if _legs_apart(clips[name + "~"], t) < _legs_apart(c, t):
				name += "~"
			_begin(name, "stop")
			_clip_t = t
	elif sub == "stop" and wish > 0.05:
		_to_loop(maxf(speed, 1.0))
	# the pose
	var slope_now := 0.0
	if sub == "stairs" and st != 0:
		var tread := float(body.get(&"stair_tread"))
		var c: Resource = clips[STAIRS[st][1 if wish > tread / 0.4 else 0]]
		var hips_path: PackedVector3Array = c.get(&"hips")
		var rise := hips_path[hips_path.size() - 1].y - hips_path[0].y
		slope_now = rise / maxf((c.get(&"travel") as Vector3).length(), 0.01)
		# steps climbed so far, counted from the edges he has crossed and how far he is past the last one
		var along := (body.global_position - (body.get(&"stair_edge") as Vector3)).dot(body.get(&"stair_dir"))
		var steps := float(int(body.get(&"stair_count"))) + clampf(along / tread, 0.0, 1.0)
		# the left foot comes down `reach` ahead of him; that moment must find it over the middle of a tread
		var length := float(c.get(&"length"))
		var lands := 0.5 - _stair_reach(c) / tread
		var cycle := float(c.get(&"phase_offset")) / length + (steps - lands) * 0.5
		var t := fposmod(cycle, 1.0) * length
		for i in _n:
			out[i] = c.call(&"rotation_at", i, t)
		var h: Vector3 = c.call(&"hips_at", t)
		_slope += (slope_now - _slope) * minf(dt / FADE, 1.0)
		_floor_now += (_stair_floor(c, slope_now, rise) - _floor_now) * minf(dt / FADE, 1.0)
		feet.set(&"clip_slope", _slope)
		feet.set(&"clip_floor", _floor_now)
		return Vector3(h.x, h.y - rise * t / length, h.z)
	_slope += (0.0 - _slope) * minf(dt / FADE, 1.0)
	_floor_now += (0.0 - _floor_now) * minf(dt / FADE, 1.0)
	if feet:
		feet.set(&"clip_slope", _slope)
		feet.set(&"clip_floor", _floor_now)
	match sub:
		"spot":
			var done := 1.0 - absf(float(body.get(&"spot_left"))) / maxf(absf(spot), 0.001) if spot != 0.0 else 1.0
			var turn := (_clip.get(&"yaw") as PackedFloat32Array)[int(_clip.get(&"frames")) - 1]
			_clip_t = maxf(_clip_t, float(_clip.call(&"time_for_yaw", turn * clampf(done, 0.0, 1.0))))
			return _clip_pose_matched(_clip, _clip_t, out, true)
		"start":
			_gone += speed * dt
			_clip_t = maxf(_clip_t, float(_clip.call(&"time_for_dist", _gone)))
			var length := float(_clip.get(&"length"))
			var end_speed := (float(_clip.call(&"dist_at", length)) - float(_clip.call(&"dist_at", length - 0.2))) / 0.2
			if _clip_t >= length - 0.12 or speed > end_speed * 1.35 + 0.3:
				_to_loop(speed)
			else:
				return _clip_pose_matched(_clip, _clip_t, out, false)
		"stop":
			if speed > 0.05:
				var total := (_clip.get(&"travel") as Vector3).length()
				_clip_t = maxf(_clip_t, float(_clip.call(&"time_for_dist", total - float(body.call(&"stop_distance")))))
			else:
				if _still_at < 0.0:
					_still_at = float(_clip.call(&"dist_at", _clip_t))
				_clip_t += dt
			if _clip_t >= float(_clip.get(&"length")) - 0.02:
				_to_loop(0.0)
			else:
				var h := _clip_pose_matched(_clip, _clip_t, out, false)
				if _still_at >= 0.0:
					# the body is at rest: what travel the clip still has is the hips settling over the planted feet
					var along := (_clip.get(&"travel") as Vector3).normalized()
					h += along * (float(_clip.call(&"dist_at", _clip_t)) - _still_at)
				return h
	return _move_pose(speed, dt, out)


## How far ahead of the hips the left foot is when a stair clip brings it down (the clip's own measure).
func _stair_reach(c: Resource) -> float:
	if not _reach.has(c):
		var t := float(c.get(&"phase_offset"))
		var pose: Array[Quaternion] = []
		for i in _n:
			pose.append(c.call(&"rotation_at", i, t))
		var legs: Array = feet.call(&"_legs", pose, Vector3(0.0, 1.0, 0.0))
		_reach[c] = (legs[0][3] as Transform3D).origin.z
	return _reach[c]


## Where a stair clip's own stairs stand under the hips: with the stairs' slope taken out, the lowest the ball of
## either foot goes through the loop is the floor.
func _stair_floor(c: Resource, slope: float, rise: float) -> float:
	if not _floor.has(c):
		var length := float(c.get(&"length"))
		var lowest := 1e9
		var pose: Array[Quaternion] = []
		pose.resize(_n)
		var was_slope: float = feet.get(&"clip_slope")
		feet.set(&"clip_slope", 0.0)
		for k in 40:
			var t := length * k / 40.0
			for i in _n:
				pose[i] = c.call(&"rotation_at", i, t)
			var h: Vector3 = c.call(&"hips_at", t)
			h.y -= rise * t / length
			var legs: Array = feet.call(&"_legs", pose, h)
			for f in 2:
				var toe: Vector3 = (legs[f][3] as Transform3D).origin
				lowest = minf(lowest, toe.y - slope * (toe.z - h.z))
		feet.set(&"clip_slope", was_slope)
		_floor[c] = lowest - float(feet.get(&"_toe_rest"))
	return _floor[c]


func _begin(name: String, kind: String) -> void:
	_clip = clips[name]
	_clip_t = 0.0
	_gone = 0.0
	_still_at = -1.0
	sub = kind
	_blend_from_here()


## Back to the loops, entering the stride at the point nearest to how the legs are now.
func _to_loop(speed: float) -> void:
	sub = "loop"
	_blend_from_here()
	if speed < 0.3:
		return
	var c: Resource = clips[GAITS[2] if speed < RUN_FROM else GAITS[3]]
	var best := 1e9
	var length := float(c.get(&"length"))
	for i in 40:
		var p := i / 40.0
		var t := fmod(p * length + float(c.get(&"phase_offset")), length)
		var gap := 0.0
		for b in _legs_i:
			gap += _rot[b].angle_to(c.call(&"rotation_at", b, t))
		if gap < best:
			best = gap
			phase = p


## How far the legs of clip `c` at time `t` are from the legs as they are now (radians, summed).
func _legs_apart(c: Resource, t: float) -> float:
	var gap := 0.0
	for b in _legs_i:
		gap += _rot[b].angle_to(c.call(&"rotation_at", b, t))
	return gap


## Pose of a clip played by distance or by angle. `no_turn` = the clip's own turning is taken out (the body turns).
func _clip_pose_matched(c: Resource, t: float, out: Array[Quaternion], no_turn: bool) -> Vector3:
	for i in _n:
		out[i] = c.call(&"rotation_at", i, t)
	var h: Vector3 = c.call(&"hips_matched_at", t)
	if no_turn:
		var back := Quaternion(Vector3.UP, -float(c.call(&"yaw_at", t)))
		out[_hips_i] = back * out[_hips_i]
		var flat := back * Vector3(h.x, 0.0, h.z)
		h = Vector3(flat.x, h.y, flat.z)
	return h


## The head goes first: turned toward where he is asked to go, shared between neck and head.
func _look_ahead(rot: Array[Quaternion], dt: float, on_ground: bool) -> void:
	if _neck < 0 or _head < 0:
		return
	var want := 0.0
	var wish: Vector3 = body.get(&"_wish")
	if on_ground and wish.length() > 0.05:
		var off := wrapf(atan2(-wish.x, -wish.z) - body.rotation.y, -PI, PI)
		want = clampf(off, -deg_to_rad(LOOK_MOST_DEG), deg_to_rad(LOOK_MOST_DEG))
	_look = move_toward(_look, want, deg_to_rad(LOOK_RATE_DEG) * dt)
	if absf(_look) < 0.001:
		return
	var chest := Quaternion.IDENTITY
	for b in _chain:
		chest = chest * rot[b]
	var half := Quaternion(Vector3.UP, _look * 0.5)
	var neck := chest * rot[_neck]
	rot[_neck] = (chest.inverse() * half * neck).normalized()
	rot[_head] = (neck.inverse() * half * neck * rot[_head]).normalized()


## Swing each upper arm out from the chest by `arm_open_deg`, about the chest's own front-to-back line, so it
## follows the twist of the trunk. The forearm and hand go with it.
func _open_arms(rot: Array[Quaternion]) -> void:
	if arm_open_deg == 0.0 or _arm[0] < 0 or _arm[1] < 0:
		return
	var chest := Quaternion.IDENTITY
	for b in _chain:
		chest = chest * rot[b]
	var fwd := (chest * _chest_rest_inv) * Vector3(0.0, 0.0, 1.0)
	for side in 2:
		var sh := skel.get_bone_parent(_arm[side])
		var parent := chest * rot[sh]
		var swing := Quaternion(fwd.normalized(), deg_to_rad(arm_open_deg) * (1.0 if side == 0 else -1.0))
		rot[_arm[side]] = (parent.inverse() * swing * parent * rot[_arm[side]]).normalized()


## Lean the whole figure about the feet into the turn the body is making.
func _lean(dt: float, on_ground: bool) -> void:
	var v: Vector3 = body.get(&"hvel")
	var speed := v.length()
	var want := 0.0
	if on_ground and speed > 0.5:
		var dir := v / speed
		if _last_dir != Vector3.ZERO:
			var rate := atan2(_last_dir.cross(dir).y, _last_dir.dot(dir)) / dt      # + = turning to his left
			var fast := clampf((speed - 1.4) / (4.5 - 1.4), 0.0, 1.0)
			var most := deg_to_rad(lerpf(LEAN_WALK_DEG, LEAN_RUN_DEG, fast)) * minf(speed / 1.4, 1.0)
			want = clampf(atan(speed * rate / 9.8), -most, most)
		_last_dir = dir
	else:
		_last_dir = Vector3.ZERO
	lean += (want - lean) * (1.0 - exp(-dt / LEAN_TIME))
	_pivot.rotation.z = lean


func _stand_height() -> float:
	return skel.get_bone_rest(_hips_i).origin.y


## Pose of one clip at time `t` into `out`; returns the hips (bob and sway only).
func _clip_pose(c: Resource, t: float, out: Array[Quaternion]) -> Vector3:
	for i in _n:
		out[i] = c.call(&"rotation_at", i, t)
	var h: Vector3 = c.call(&"hips_at", t)
	return Vector3(h.x, h.y, h.z)


## Moving on foot: the two loops either side of the body's speed, blended, both at the same point of the stride.
## The stride advances by distance covered, so the feet keep pace with the ground whatever the speed.
func _move_pose(speed: float, dt: float, out: Array[Quaternion]) -> Vector3:
	var lo: Resource = clips[GAITS[0]]
	var hi: Resource = clips[GAITS[1]]
	var w := 0.0
	for i in range(1, GAITS.size()):
		lo = clips[GAITS[i - 1]]
		hi = clips[GAITS[i]]
		var s0 := float(lo.get(&"speed"))
		var s1 := float(hi.get(&"speed"))
		if speed <= s1 or i == GAITS.size() - 1:
			w = clampf((speed - s0) / maxf(s1 - s0, 0.001), 0.0, 1.0)
			break
	var lo_idle := float(lo.get(&"speed")) < 0.05
	var stride_hi := (hi.get(&"travel") as Vector3).length()
	# below the slowest walk the steps get shorter at the same rhythm (the blend with standing shortens them by the
	# same share), which is how the study's sources scale a gait: stride length, not playback speed
	var stride_lo := 0.0 if lo_idle else (lo.get(&"travel") as Vector3).length()
	var stride := lerpf(stride_lo, stride_hi, w)
	if speed > 0.05:
		phase = fmod(phase + speed * dt / maxf(stride, 0.05), 1.0)
	_idle_t = fmod(_idle_t + dt, float(clips[GAITS[0]].get(&"length")))
	var a: Array[Quaternion] = []
	a.resize(_n)
	var b: Array[Quaternion] = []
	b.resize(_n)
	var ha := _clip_pose(lo, _idle_t if lo_idle else _stride_time(lo), a)
	var hb := _clip_pose(hi, _stride_time(hi), b)
	for i in _n:
		out[i] = a[i].slerp(b[i], w)
	return ha.lerp(hb, w)


func _stride_time(c: Resource) -> float:
	var length := float(c.get(&"length"))
	return fmod(phase * length + float(c.get(&"phase_offset")), length)
