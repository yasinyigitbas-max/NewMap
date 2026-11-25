extends Node3D
## The character on the body: poses the skeleton from baked clips. It only looks; it never moves the body.
## STAND-IN: the mesh and skeleton are Meshy's rig of player_v4 (no real fingers), with the clips Mixamo fitted to
## player_v4 retargeted onto it. To be replaced by Mixamo's own rigged file when it is available.

const DIR := "res://traversal/character/clips/"
const MODEL := "res://traversal/character/player_v4_standin.glb"
# the loops that make up moving on foot, slowest first (their speeds are read from the clips)
const GAITS := ["Standing_Idle", "Walking_4", "Walking", "Running_3", "Running"]
const FADE := 0.20              # seconds to blend from one kind of motion to the next
# the Jump clip: it dips to its lowest at 0.50 s, leaves the ground at 0.80 s and lands at 1.30 s (measured)
const JUMP_LOW := 0.50
const JUMP_OFF := 0.80
const JUMP_LAND := 1.30
const LAND_CONTACT := 0.27      # Falling To Landing: the feet touch at 0.27 s
const HARD_CONTACT := 0.60      # Hard Landing: the feet touch at 0.60 s
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


func _ready() -> void:
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	model.rotation.y = PI      # the clips face +Z, the body faces -Z
	add_child(model)
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
	if body:
		body.connect(&"jump_started", _on_jump_started)
		body.connect(&"landed", _on_landed)


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
			hips = _move_pose((body.get(&"hvel") as Vector3).length(), dt, rot)
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

	_fade = minf(_fade + dt / FADE, 1.0)
	var k := _fade * _fade * (3.0 - 2.0 * _fade)
	for i in _n:
		_rot[i] = _from[i].slerp(rot[i], k) if k < 1.0 else rot[i]
		skel.set_bone_pose_rotation(i, _rot[i])
	_hips = _from_hips.lerp(hips, k)
	skel.set_bone_pose_position(_hips_i, _hips)
	note = "%s  stride phase %.2f" % [_mode, phase]


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
	var stride_lo := stride_hi if lo_idle else (lo.get(&"travel") as Vector3).length()
	var stride := lerpf(stride_lo, stride_hi, w)
	if speed > 0.05:
		phase = fmod(phase + speed * dt / maxf(stride, 0.1), 1.0)
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
