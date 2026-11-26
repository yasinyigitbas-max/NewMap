extends Node3D
## The character on the body: poses the skeleton from baked clips. It only looks; it never moves the body.
## The mesh and skeleton are Mixamo's rig of player_v4; the clips are the ones Mixamo fitted to him, baked.

const Feet := preload("res://traversal/character/feet.gd")
const DIR := "res://traversal/character/clips/"
const MODEL := "res://traversal/character/player_v4.scn"
# the loops that make up moving on foot, slowest first (their speeds are read from the clips)
# The walk is a Kimodo take (26 Nov). The two Mixamo walks failed the study audit (tests/test_study.gd) on five
# counts at 1.4 m/s: 108 steps a minute (study 115 to 120), both feet down 5 % of the stride (10 to 12), hips rising
# and falling 5.6 cm (2.7 to 4.8), thigh 35 deg forward (25), knee bending 30 deg as weight lands (20). Six Kimodo
# walks were auditioned through the same audit; this one passes all of those. Its own speed is 1.22 m/s.
var GAITS := ["Standing_Idle", "KM_Walk", "Running_3", "Running"]
const FADE := 0.20              # seconds to blend from one kind of motion to the next
# the Jump clip: it dips to its lowest at 0.50 s, leaves the ground at 0.80 s and lands at 1.30 s (measured)
const JUMP_LOW := 0.50
const JUMP_OFF := 0.80
const JUMP_LAND := 1.30
# the Running Jump clip: one run stride with a leap in it. It leaves the ground at 0.10 s and is down at 0.67 s
# (a 2.7 m leap at the clip's 4.87 m/s); the body's own jump at 4.5 m/s is 2.7 m too
const RUN_JUMP := "Running_Jump"
const RUN_JUMP_OFF := 0.10
const RUN_JUMP_LAND := 0.67
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
const TURN_180_RUN := "Running_Turn_180"        # 0.67 s, turns to his right, from a running pose to a running pose:
                                                # the plant-and-turn when he is asked to run the other way
const RUN_FROM := 2.5           # above this speed the run clips are used (his jog loop is 2.53 m/s)
# Stairs are their own movement (the study: "going up and going down are different movements"): his four stair clips,
# two steps a loop, played by where he is on the stairs so that each foot comes down in the middle of a tread.
# Going up at a walk is Mixamo's Ascending Stairs. The other three were made with Kimodo (26 Nov, at Yasin's word):
# Mixamo's two going-down clips are damaged (see _floor_clamped) and its Running Up Stairs was replaced with them.
# A second round of Kimodo takes (walk up, walk down, run up) was tried on 26 Nov and measured worse at the feet
# than these (their strides do not match a 0.28 m tread), so these stay.
const STAIRS := {1: ["Ascending_Stairs", "KM_Stairs_Run_Up_D"], -1: ["KM_Stairs_Walk_Down", "KM_Stairs_Run_Down"]}
# Steep ground (26 Nov; research_notes/.../steep_slopes.md), Kimodo clips, each one a take that really climbs or
# descends (measured): up a 30 degree slope a take that rises at 29 degrees with long strides; down, one that drops
# at 27 degrees; up 45 degrees, one that rises at 44 degrees; down 45 degrees, one that drops at 27 degrees (no take
# came down steeper facing forward). A take made on the flat and fitted to a slope looked wrong (Yasin: "he pulls
# his legs up as if stretching"), and the crawl was turned down ("we look like a small baby").
# Downhill (Yasin, 26 Nov: "he takes such little steps that it's both unreal and impractical"): the first downhill
# take had a 0.62 m stride, which at his downhill pace meant about 236 steps a minute. The research says downhill
# "shortens stride and raises cadence", but gives no figure near that; uphill, 6 to 20 degrees cost 16 % of stride.
# The take in use now has a 1.0 m stride and drops at 26 degrees; with run held, one that jogs down at 34 degrees.
# Uphill (Yasin, 26 Nov, second look: "extremely small steps making it look like this is a joke rather than a hard
# walk"): the takes were chosen by the slope they climbed and nothing else; their strides were 0.55 and 0.37 m. Every
# stride of every climbing take was then measured. Real climbing strides do shorten with the slope (1.00 m at 28
# degrees, 0.91 m at 37, 0.4 to 0.7 m at 45 and over), and the longest are used: slow, long, heavy steps.
# Up steep ground: Yasin's own Kimodo take (26 Nov, "a person walking up a steep slope having a hard time climbing,
# getting assistance from their hands, having to bend over to adapt"), the whole 3.5 s of it as one loop: leaning
# steps, a bend with both hands down, the push back up. It replaces the takes made from my prompts in both bands.
# Down steep ground: Yasin's take of 26 Nov ("using hands to balance yourself while walking down steep slope with
# difficulty", 6.5 s): the two strides in the middle of its descent, crouched and leaning back.
const STEEP := {true: "KM_Climb_Hard", false: "KMY_Down_Hands_Balance_Long"}
const HANDS := {true: "KM_Climb_Hard", false: "KMY_Down_Hands_Balance_Long"}
const DRIVEN_MOST := 1.15       # NOT in the study: a struggling take is never played faster than this over its own speed
# Clips that set the body's pace themselves (his hips do not move evenly in them: he stops while the hands go down)
const DRIVEN := ["KM_Climb_Hard", "KMY_Down_Hands_Balance_Long"]
const STEEP_DOWN_RUN := "KM_Slope_Down_Run"
# Walking or running off an edge (Yasin, 26 Nov: "looks stuck and frozen on air before landing, no limbs move to
# balance itself"): Kimodo takes of stepping and of running off a ledge. [clip, leaves the edge, feet touch down]
const DROP_WALK := ["KM_Ledge_Walk_Off", 2.10, 2.62]
const DROP_RUN := ["KM_Ledge_Run_Off", 1.92, 2.72]
const STANCE := 1.0             # the feet-only pull is off: the legs are put right at the bake instead (tools/build_clips.gd)
const STANCE_FEET_ONLY := 0.32            # (0.5 at first; the audit measured 0.15 m at that, against the study's 0.08 to 0.10)
const STANCE_WAS := 0.5             # the share of his sideways foot spread kept: 0.32 m becomes 0.16 m at a walk, 0.27 m
                                # becomes 0.14 m at a run (people: 0.08 to 0.10 m; his thighs are thicker than most)
const LEAN_UPHILL := 0.9        # NOT in the study: share of the slope (over 8 degrees) the trunk leans forward going up:
                                # 20 degrees of lean on the 30 degree ramp, 33 on the 45
const REACH_BEND_DEG := 22.0     # NOT in the study: the extra bend of the trunk while the hand goes down
const LEAN_DOWNHILL := 0.25     # NOT in the study: and back, going down
# Head: "people turn head first", about 15 deg into a curve and 15 to 30 deg of lead; the trunk does not lead
const LOOK_MOST_DEG := 30.0
const LOOK_RATE_DEG := 100.0    # well under the 137 to 272 deg/s measured for deliberate turns
const HARD_DROP := 1.0          # the study: "0.30 to 1.0 m, step or hop off with a soft landing; 1.0 to 2.0 m, a heavy
                                # landing" (this stood at 1.5, a departure found in the 26 Nov audit)

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
var _jump_clip := "Jump"
var _jump_off := JUMP_OFF
var _jump_land := JUMP_LAND
var _run_out := false           # running out of a turn-round: the legs keep at least a jog while the body picks up speed
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
var _clamped := {}              # per stair clip: its feet were kept on Mixamo's floor (see _floor_clamped)
var _steep_phase := 0.0
var _driven_now := false        # this tick the pose is a clip that sets the body's pace (see DRIVEN)
var _hand_w := 0.0              # 0..1: the left hand is going to the slope
var _arm_ik: TwoBoneIK3D
var _hand_target: Node3D
var _hand_pole: Node3D
var _trunk := 0.0               # the trunk's lean for the slope (radians, + = forward)
var _stair_phase := 0.0
var _stair_on := false
var _pitch := 0.0               # the whole figure tipped to the slope, on hands and feet (radians)
var _hands := false
var _drop: Array = []           # the ledge clip in use while falling, as DROP_WALK / DROP_RUN
var _lump := {}                 # per clip that sets the pace: each foot's own ground line (see _stair_floor)
var _ride := {}                 # per stair clip: how far its hips ride above a standing man's
var _floor := {}                # per stair clip: where its own stairs stand under the hips
var _floor_now := 0.0
var _reach := {}                # per stair clip: how far ahead of the hips the left foot comes down
var _still_at := -1.0           # a stop: how far along the clip he was when the body came to rest
var _legs_i: Array[int] = []
var _neck := -1
var _head := -1
var _look := 0.0
var foot_narrow := true
var _narrow := 1.0
var foot_pin := true            # planted feet held in place
var foot_ground := true         # feet fitted to the ground under them
var landing_kind := ""          # for the readout and the audit: "" (none), "soft", "heavy" or "jump"


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
	# trying a take: -- --walk=KM_Walk puts one clip in place of the two Mixamo walks, --run=KM_Run in place of the runs
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--walk=") and clips.has(a.split("=")[1]):
			GAITS = ["Standing_Idle", a.split("=")[1], GAITS[3], GAITS[4]]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--run=") and clips.has(a.split("=")[1]):
			GAITS = GAITS.slice(0, GAITS.size() - 2) + [a.split("=")[1]]
	_make_mirrors()
	if body:
		feet = Feet.new()
		feet.call(&"setup", skel, body)
		_hand_target = Node3D.new()
		_hand_pole = Node3D.new()
		skel.add_child(_hand_target)
		skel.add_child(_hand_pole)
		_arm_ik = TwoBoneIK3D.new()
		_arm_ik.name = "ArmIK"
		skel.add_child(_arm_ik)
		_arm_ik.setting_count = 1
		_arm_ik.set_root_bone(0, _arm[0])
		_arm_ik.set_middle_bone(0, skel.find_bone("mixamorig_LeftForeArm"))
		_arm_ik.set_end_bone(0, skel.find_bone("mixamorig_LeftHand"))
		_arm_ik.set_target_node(0, _arm_ik.get_path_to(_hand_target))
		_arm_ik.set_pole_node(0, _arm_ik.get_path_to(_hand_pole))
		_arm_ik.influence = 0.0
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
	for name: String in [STOP_WALK, STOP_RUN, TURN_90, TURN_180_WALK, TURN_180_RUN]:
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
	var running: bool = not bool(body.get(&"_jump_still")) and clips.has(RUN_JUMP)
	_jump_clip = RUN_JUMP if running else "Jump"
	_jump_off = RUN_JUMP_OFF if running else JUMP_OFF
	_jump_land = RUN_JUMP_LAND if running else JUMP_LAND
	_jump_from = _jump_off - push
	_set_mode("jump")


func _on_landed(drop: float) -> void:
	if _mode == "jump" and drop < 0.9:
		_land_clip = _jump_clip
		_land_from = _jump_land
	elif drop >= HARD_DROP:
		_land_clip = "Hard_Landing"
		_land_from = HARD_CONTACT
	elif _mode == "fall" and not _drop.is_empty() and drop >= 0.35:
		# the same clip carries on from where its feet touch down
		_land_clip = _drop[0]
		_land_from = float(_drop[2])
	elif drop >= 0.35:
		_land_clip = "Falling_To_Landing"
		_land_from = LAND_CONTACT
	else:
		_set_mode("move")
		return
	_set_mode("land")
	landing_kind = "heavy" if _land_clip == "Hard_Landing" else ("jump" if _land_clip == _jump_clip else "soft")


func _set_mode(m: String) -> void:
	if m == _mode:
		return
	_mode = m
	_mode_t = 0.0
	landing_kind = ""
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
		# off an edge on foot: the step-off or run-off clip; out of a long jump: the falling loop
		_drop = []
		if _mode == "move" and in_air:
			_drop = DROP_RUN if (body.get(&"hvel") as Vector3).length() > RUN_FROM else DROP_WALK
			if not clips.has(_drop[0]):
				_drop = []
		_set_mode("fall" if in_air else "move")
	elif _mode == "fall" and not in_air:
		_set_mode("move")
	elif _mode == "jump" and not in_air and float(body.get(&"jump_timer")) <= 0.0 and _mode_t > 0.35:
		_set_mode("move")
	elif _mode == "land":
		var c: Resource = clips[_land_clip]
		if in_air:
			_set_mode("fall")
		elif _land_from + _mode_t >= float(c.get(&"length")) - 0.05 or ((body.get(&"hvel") as Vector3).length() > 1.0 and _mode_t > 0.45 and _land_clip != RUN_JUMP):
			_set_mode("move")
			# into the stride at the point nearest to how the legs are
			_to_loop((body.get(&"hvel") as Vector3).length())

	var rot: Array[Quaternion] = []
	rot.resize(_n)
	var hips := Vector3.ZERO
	match _mode:
		"move":
			hips = _on_foot(dt, rot)
		"fall":
			var window := (float(_drop[2]) - float(_drop[1])) if not _drop.is_empty() else 0.0
			if not _drop.is_empty() and _mode_t < window - 0.04:
				hips = _drop_pose(clips[_drop[0]], float(_drop[1]) + _mode_t, rot)
			else:
				# a longer fall than the clip has: the falling loop takes over
				if not _drop.is_empty():
					_drop = []
					_blend_from_here()
				var c: Resource = clips["Falling_Idle"]
				hips = _clip_pose(c, fmod(_mode_t, float(c.get(&"length"))), rot)
		"jump":
			var c: Resource = clips[_jump_clip]
			var t := _jump_from + _mode_t
			if in_air:
				# through the clip's time in the air at the pace of the body's own flight
				var flight := 2.0 * sqrt(2.0 * 9.8 * 0.45) / 9.8
				t = _jump_off + (_jump_land - _jump_off) * clampf(float(body.get(&"air_time")) / flight, 0.0, 1.0)
			else:
				t = minf(t, _jump_off)
			hips = _clip_pose(c, t, rot)
			# the clip's own rise is taken out: the body does the rising
			hips.y = minf(hips.y, (c.call(&"hips_at", _jump_off) as Vector3).y) if in_air else hips.y
		"land":
			var c: Resource = clips[_land_clip]
			if _land_clip.begins_with("KM_Ledge"):
				hips = _drop_pose(c, minf(_land_from + _mode_t, float(c.get(&"length"))), rot)
			else:
				hips = _clip_pose(c, minf(_land_from + _mode_t, float(c.get(&"length"))), rot)
			hips.y = minf(hips.y, _stand_height())

	_open_arms(rot)
	_hand_reach(dt, state == 0)
	_slope_lean(rot, dt, state == 0)
	_look_ahead(rot, dt, state == 0)
	_lean(dt, state == 0)
	# on hands and feet the whole figure is tipped to the slope he faces: a crawl on a slope is a crawl on the flat,
	# tipped (the feet and the hands then meet the slope as they met the floor)
	_hands = false      # the crawl, tipped to the slope, was taken out (Yasin, 26 Nov); kept in case a crawl returns
	var tip := 0.0
	if _hands:
		var n: Vector3 = body.get(&"ground_normal")
		var f := -body.global_transform.basis.z
		tip = atan(-(n.x * f.x + n.z * f.z) / maxf(n.y, 0.01))
	_pitch += (tip - _pitch) * (1.0 - exp(-dt / 0.15))
	_pivot.rotation.x = _pitch
	_fade = minf(_fade + dt / FADE, 1.0)
	var k := _fade * _fade * (3.0 - 2.0 * _fade)
	for i in _n:
		_rot[i] = _from[i].slerp(rot[i], k) if k < 1.0 else rot[i]
		skel.set_bone_pose_rotation(i, _rot[i])
	_hips = _from_hips.lerp(hips, k)
	var drop := 0.0
	if feet:
		# on his feet (not crawling, not in the air) the stance is narrowed; eased so it never snaps
		var want_narrow := STANCE if _mode == "move" else 1.0
		_narrow += (want_narrow - _narrow) * (1.0 - exp(-dt / 0.2))
		feet.set(&"narrow", _narrow if foot_narrow else 1.0)
		feet.set(&"pinning", foot_pin)
		feet.set(&"grounding", foot_ground and absf(_pitch) < 0.1)
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
	var ground_kind := int(body.get(&"terrain")) if st == 0 else 0
	var steep_sub: String = ["", "steep", "hands"][ground_kind]
	if st != 0 and speed > 0.15 and (sub == "loop" or sub == "start"):
		sub = "stairs"
		_blend_from_here()
	elif ground_kind != 0 and speed > 0.1 and sub != steep_sub and sub in ["loop", "start", "stop", "steep", "hands"]:
		sub = steep_sub
		_blend_from_here()
	elif (sub == "steep" or sub == "hands") and ground_kind == 0:
		_to_loop(speed)
	elif sub == "stairs" and (st == 0 or speed < 0.1):
		_to_loop(speed)
	elif spot != 0.0 and sub != "spot":
		var big := absf(spot) > deg_to_rad(120.0)
		_run_out = bool(body.get(&"spot_run"))
		var name: String = (TURN_180_RUN if _run_out else TURN_180_WALK) if big else TURN_90
		# the 180 clip turns to his right, the 90 to his left: the mirror image for the other way
		_begin(name if (spot < 0.0) == big else name + "~", "spot")
	elif sub == "spot" and spot == 0.0:
		if _run_out and wish > 0.05:
			_to_loop(RUN_FROM)      # the clip ends in a running pose: straight into the run
		elif wish > 0.05:
			_begin(START_RUN if wish > RUN_FROM else START_WALK, "start")
		else:
			_to_loop(wish)
	elif sub == "loop" and speed < 0.3 and wish > 0.05 and not _run_out and ground_kind == 0:
		_begin(START_RUN if wish > RUN_FROM else START_WALK, "start")
	elif (sub == "loop" or sub == "start") and wish < 0.05 and speed > 0.3 and st == 0 and ground_kind == 0:
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
	body.set(&"pace", 1.0)
	_driven_now = false
	if sub == "stairs" and st != 0:
		var tread := float(body.get(&"stair_tread"))
		var c: Resource = clips[STAIRS[st][1 if wish > tread / 0.4 else 0]]
		# steps climbed so far, counted from the edges he has crossed and how far he is past the last one
		var along := (body.global_position - (body.get(&"stair_edge") as Vector3)).dot(body.get(&"stair_dir"))
		var steps := float(int(body.get(&"stair_count"))) + clampf(along / tread, 0.0, 1.0)
		# the left foot comes down `reach` ahead of him; that moment must find it over the middle of a tread
		var length := float(c.get(&"length"))
		var lands := 0.5 - _stair_reach(c) / tread
		var cycle := float(c.get(&"phase_offset")) / length + (steps - lands) * 0.5
		# the stride runs on by the ground covered and is only drawn toward that place, a little each tick: tied
		# to it outright, it jumped a few hundredths of a stride at every step edge (the measured tread is never
		# exact), which showed as a twitch through the whole body
		_stair_phase += speed * dt / (2.0 * tread)
		var behind := wrapf(cycle - _stair_phase, -0.5, 0.5)
		if not _stair_on or absf(behind) > 0.25:
			_stair_phase = cycle
		else:
			_stair_phase += behind * minf(dt * 3.0, 1.0)
		_stair_on = true
		var t := fposmod(_stair_phase, 1.0) * length
		return _slope_clip_pose(c, t, out, dt)
	_stair_on = false
	var terr := int(body.get(&"terrain"))
	if (sub == "steep" or sub == "hands") and terr != 0:
		# steep ground: the stride goes by the ground covered (along the slope when he is tipped to it)
		var grade := float(body.get(&"grade"))
		var up: bool = grade >= 0.0
		var c: Resource = clips[(STEEP if sub == "steep" else HANDS)[up]]
		var name: String = (STEEP if sub == "steep" else HANDS)[up]
		var asked := float(body.get(&"steady"))
		if not up and asked > 2.0 and clips.has(STEEP_DOWN_RUN):
			c = clips[STEEP_DOWN_RUN]
		# with run held on the leaning-walk band the struggling take would have to play at three times its speed:
		# there the earlier climbing stride stays (unchanged from the last build)
		if up and sub == "steep" and float(body.get(&"steady")) > float(c.get(&"speed")) * 1.8 and clips.has("KM_Climb"):
			c = clips["KM_Climb"]
		var c_len := float(c.get(&"length"))
		_driven_now = DRIVEN.has(name) and c == clips[name]
		if _driven_now:
			# the clip runs on at the pace he asks for (his steady climbing speed over the clip's own average), and
			# the body is told how fast the clip's hips are going at this moment, so the feet hold their ground
			var mean := maxf(float(c.get(&"speed")), 0.05)
			var steady := float(body.get(&"steady"))
			# (never faster than a little over the take's own pace: his speed on this ground is then the take's)
			var rate := minf(steady / mean, DRIVEN_MOST)
			_steep_phase = fposmod(_steep_phase + dt * rate / c_len, 1.0)
			var t := _steep_phase * c_len
			var t0 := clampf(t - 0.05, 0.0, c_len - 0.1)
			var now := (float(c.call(&"dist_at", t0 + 0.1)) - float(c.call(&"dist_at", t0))) / 0.1
			body.set(&"pace", clampf(now * rate / maxf(steady, 0.01), 0.0, 3.0))
			return _slope_clip_pose(c, t, out, dt, true)
		var covered := speed * dt
		_steep_phase = fposmod(_steep_phase + covered / maxf((c.get(&"travel") as Vector3).length(), 0.1), 1.0)
		return _slope_clip_pose(c, _steep_phase * c_len, out, dt)
	_slope += (0.0 - _slope) * minf(dt / FADE, 1.0)
	_floor_now += (0.0 - _floor_now) * minf(dt / FADE, 1.0)
	if feet:
		feet.set(&"clip_slope", _slope)
		feet.set(&"clip_floor", _floor_now)
		feet.set(&"clip_lump", [0.0, 0.0])
		feet.set(&"clip_pitch", 0.0)
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
	if _run_out and (speed > RUN_FROM or wish < 0.05 or sub != "loop"):
		_run_out = sub == "spot"
	return _move_pose(maxf(speed, RUN_FROM) if _run_out and sub == "loop" else speed, dt, out)


## Pose of a clip that goes up or down its own slope or stairs (or a flat one): the clip's climb is taken out of the
## hips, and its slope out from under its feet, so that the real ground under him is what the feet are fitted to.
func _slope_clip_pose(c: Resource, t: float, out: Array[Quaternion], dt: float, driven := false) -> Vector3:
	var hips_path: PackedVector3Array = c.get(&"hips")
	var length := float(c.get(&"length"))
	var rise := hips_path[hips_path.size() - 1].y - hips_path[0].y
	for i in _n:
		out[i] = c.call(&"rotation_at", i, t)
	var h: Vector3 = c.call(&"hips_matched_at" if driven else &"hips_at", t)
	# how much of the clip's climb is behind him at this moment: by time, or for a clip that sets the pace by how
	# far its hips have come
	var part := t / length
	if driven:
		part = float(c.call(&"dist_at", t)) / maxf((c.get(&"travel") as Vector3).length(), 0.01)
	if absf(rise) < 0.06:
		# a clip made on the flat: nothing to take out
		_slope += (0.0 - _slope) * minf(dt / FADE, 1.0)
		_floor_now += (0.0 - _floor_now) * minf(dt / FADE, 1.0)
		feet.set(&"clip_slope", _slope)
		feet.set(&"clip_floor", _floor_now)
		feet.set(&"clip_lump", [0.0, 0.0])
		feet.set(&"clip_pitch", 0.0)
		return Vector3(h.x, h.y - rise * t / length, h.z)
	var slope_now := rise / maxf((c.get(&"travel") as Vector3).length(), 0.01)
	var floor_now := 0.0
	var clamped := _floor_clamped(c, rise)
	if not clamped:
		floor_now = _stair_floor(c, slope_now, rise, driven)
	if clamped:
		# see _floor_clamped: the feet of this clip stand on a flat floor that the hips sink toward. The hips
		# are held level here, so the feet are put back by exactly what the hips were let down
		slope_now = 0.0
		_slope = 0.0
		_floor_now = -rise * t / length
	else:
		_slope += (slope_now - _slope) * minf(dt / FADE, 1.0)
		_floor_now += (floor_now - _floor_now) * minf(dt / FADE, 1.0)
	feet.set(&"clip_slope", _slope)
	var lump := [0.0, 0.0]
	if _lump.has(c):
		for f in 2:
			var track: PackedFloat32Array = _lump[c][f]
			var at := t / length * track.size()
			var i0 := posmod(int(at), track.size())
			lump[f] = lerpf(track[i0], track[posmod(i0 + 1, track.size())], at - floorf(at))
	feet.set(&"clip_lump", lump)
	feet.set(&"clip_pitch", atan(_slope) if driven else 0.0)
	var ride: float = 0.0 if clamped else _ride.get(c, 0.0)
	feet.set(&"clip_floor", _floor_now if clamped else _floor_now - ride * (_floor_now / floor_now if absf(floor_now) > 0.001 else 1.0))
	# the hips stand over the clip's own slope, not over a floor at zero: they are let down (or up) onto the body's
	# ground, and the feet, which hang from them, come with them
	return Vector3(h.x, h.y - rise * part - ride, h.z)


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


## Mixamo's two clips that walk DOWN stairs (Descending Stairs, Run Down Stairs) are damaged, on X Bot and on him
## alike: the hips go down half a metre but no foot ever goes below the floor, so the legs fold into a squat by the
## end (measured 26 Nov: hips 0.94 -> 0.43 m, feet 0.01 to 0.02 m throughout). Mixamo's fitting keeps feet above
## its floor. What is left is usable: the hips' path, where the feet are along the ground, the upper body. For such
## a clip the feet are taken as already standing on a flat floor and the legs are rebuilt by the leg IK.
func _floor_clamped(c: Resource, rise: float) -> bool:
	if rise > -0.2:
		return false
	if not _clamped.has(c):
		var length := float(c.get(&"length"))
		var pose: Array[Quaternion] = []
		pose.resize(_n)
		# the lower of the two feet, through the clip: on real stairs going down it ends half a metre lower
		var low_min := 1e9
		var low_max := -1e9
		for k in 21:
			var t := length * k / 20.0
			for i in _n:
				pose[i] = c.call(&"rotation_at", i, t)
			var legs: Array = feet.call(&"_legs", pose, c.call(&"hips_at", t))
			var lower := minf((legs[0][3] as Transform3D).origin.y, (legs[1][3] as Transform3D).origin.y)
			low_min = minf(low_min, lower)
			low_max = maxf(low_max, lower)
		_clamped[c] = low_max - low_min < 0.1
	return _clamped[c]


## Where a stair clip's own stairs stand under the hips: with the stairs' slope taken out, the height of the ball of
## a foot over the frames in which the clip has that foot planted (not moving over the clip's own ground).
func _stair_floor(c: Resource, slope: float, rise: float, driven := false) -> float:
	if not _floor.has(c):
		var length := float(c.get(&"length"))
		var travel: Vector3 = c.get(&"travel")
		var pose: Array[Quaternion] = []
		pose.resize(_n)
		var was_slope: float = feet.get(&"clip_slope")
		feet.set(&"clip_slope", 0.0)
		var flat := [[], []]
		var world := [[], []]
		var steps := 60
		for k in steps + 1:
			var t := length * k / steps
			for i in _n:
				pose[i] = c.call(&"rotation_at", i, t)
			# a clip that sets the pace: its hips are held over the body all the way, and its climb goes by how far
			# they have come, not by the clock
			var h: Vector3 = c.call(&"hips_matched_at" if driven else &"hips_at", t)
			var part := t / length
			if driven:
				part = float(c.call(&"dist_at", t)) / maxf(travel.length(), 0.01)
			var legs: Array = feet.call(&"_legs", pose, h)
			for f in 2:
				var toe: Vector3 = (legs[f][3] as Transform3D).origin
				flat[f].append(toe.y - rise * part - slope * (toe.z - h.z))
				world[f].append(toe + travel * part)       # as the clip itself has it, travel and rise in
		feet.set(&"clip_slope", was_slope)
		var sum := 0.0
		var count := 0
		var lowest := 1e9
		for f in 2:
			for k in steps:
				lowest = minf(lowest, flat[f][k])
				if ((world[f][k + 1] as Vector3) - (world[f][k] as Vector3)).length() / (length / steps) < 0.4:
					sum += flat[f][k]
					count += 1
		_floor[c] = (sum / count if count > 0 else lowest) - float(feet.get(&"_toe_rest"))
		if driven and count > 0:
			# A generated clip does not climb a flat slope: the ground it imagines under each footfall is higher
			# here and lower there (this take: from 0.24 m under the even slope to 0.23 m over it, measured 26 Nov).
			# Taken as an even slope, every footfall is left that far inside the real ground or above it. So each
			# foot gets its own ground line through the clip: the height of each of its footfalls, and a straight
			# run from one footfall to the next while the foot is in the air.
			var lumps := []
			for f in 2:
				var track := PackedFloat32Array()
				track.resize(steps)
				var known: Array[int] = []
				var k := 0
				while k < steps:
					if ((world[f][k + 1] as Vector3) - (world[f][k] as Vector3)).length() / (length / steps) < 0.4:
						var k1 := k
						var run_sum := 0.0
						while k1 < steps and ((world[f][k1 + 1] as Vector3) - (world[f][k1] as Vector3)).length() / (length / steps) < 0.4:
							run_sum += flat[f][k1]
							k1 += 1
						for j in range(k, k1):
							track[j] = run_sum / (k1 - k) - sum / count
							known.append(j)
						k = k1
					else:
						k += 1
				for j in steps:
					if known.has(j):
						continue
					# the footfall before and the one after, round the loop
					var a := j
					var b := j
					var na := 0
					var nb := 0
					while not known.has(posmod(a, steps)) and na < steps:
						a -= 1
						na += 1
					while not known.has(posmod(b, steps)) and nb < steps:
						b += 1
						nb += 1
					if na < steps and nb < steps:
						track[j] = lerpf(track[posmod(a, steps)], track[posmod(b, steps)], float(na) / float(na + nb))
				lumps.append(track)
			_lump[c] = lumps
		# and how far the clip's hips, with their climb taken out, ride above a standing man's: a clip cut from
		# the middle of a flight starts wherever it had got to
		var mean := 0.0
		for k in steps:
			var t := length * k / steps
			var part := t / length
			if driven:
				part = float(c.call(&"dist_at", t)) / maxf(travel.length(), 0.01)
			mean += (c.call(&"hips_at", t) as Vector3).y - rise * part
		_ride[c] = mean / steps - _stand_height() * 0.97
		if OS.get_cmdline_user_args().has("--dbg"):
			print("stair clip %s: slope %.2f rise %.2f floor %.3f from %d planted frames, lowest %.3f" % [c.get(&"source"), slope, rise, _floor[c], count, lowest])
			for f in 2:
				var line := ""
				for k in range(0, steps, 4):
					line += " %.2f/%.2f" % [flat[f][k], ((world[f][k + 1] as Vector3) - (world[f][k] as Vector3)).length() / (length / steps)]
				print("   foot %d flat height / speed:%s" % [f, line])
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
	# the loop he will be in at this speed: the first whose own speed reaches it
	var c: Resource = clips[GAITS[GAITS.size() - 1]]
	for i in range(1, GAITS.size()):
		if speed <= float(clips[GAITS[i]].get(&"speed")):
			c = clips[GAITS[i]]
			break
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


## Very steep ground, going up: once a stride he bends and puts his left hand on the slope ahead (Yasin: "long strides
## ... assisted by hands only at some steps"; the mountaineering sources: hands "for balance", flat-hand push holds).
## The arm is solved by Godot's TwoBoneIK3D, as the legs are.
func _hand_reach(dt: float, on_ground: bool) -> void:
	if _arm_ik == null:
		return
	var want := 0.0
	# off while the uphill clip does its own bend and puts its own hands down (HANDS[true] in DRIVEN)
	if on_ground and _mode == "move" and sub == "hands" and float(body.get(&"grade")) > 0.3 and not _driven_now:
		# through the second half of the stride, in and out smoothly
		var u := (_steep_phase - 0.45) / 0.5
		if u > 0.0 and u < 1.0:
			want = sin(u * PI) * sin(u * PI)
	_hand_w = want
	_arm_ik.influence = _hand_w
	if _hand_w <= 0.001:
		return
	var s := skel.global_transform
	var shoulder: Vector3 = s * skel.get_bone_global_pose(_arm[0]).origin
	var fwd := -body.global_transform.basis.z
	var left := -body.global_transform.basis.x
	var from := shoulder + fwd * 0.40 + left * 0.08 + Vector3(0.0, 0.6, 0.0)
	var q := PhysicsRayQueryParameters3D.create(from, from - Vector3(0.0, 2.2, 0.0), body.collision_mask, [body.get_rid()])
	var hit := body.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		_arm_ik.influence = 0.0
		return
	var inv := s.affine_inverse()
	_hand_target.position = inv * ((hit["position"] as Vector3) + (hit["normal"] as Vector3) * 0.05)
	# the elbow points back, down and a little out
	_hand_pole.position = inv * (shoulder - fwd * 0.5 + left * 0.3 - Vector3(0.0, 0.3, 0.0))


## On a slope the trunk leans: "uphill the trunk tilts forward ... downhill the trunk tilts back" (the study), and the
## research has it growing with the slope. How much is NOT measured anywhere for slopes over 6 degrees, so the share
## is ours: Yasin, 26 Nov, on the 30 and 45 degree ramps: "zero forward lean ... a joke rather than a hard walk".
## The bend is shared along the spine with most in the lower back, which is where the study puts forward bending.
func _slope_lean(rot: Array[Quaternion], dt: float, on_ground: bool) -> void:
	var want := 0.0
	if on_ground and _mode == "move" and (body.get(&"hvel") as Vector3).length() > 0.1:
		var grade := float(body.get(&"grade"))
		var angle := atan(absf(grade))
		if angle > deg_to_rad(8.0):
			want = (angle - deg_to_rad(8.0)) * (LEAN_UPHILL if grade > 0.0 else -LEAN_DOWNHILL)
			if _driven_now:
				want = 0.0       # the uphill clip leans by itself: nothing added on top of it
			want += _hand_w * deg_to_rad(REACH_BEND_DEG)       # bending to put the hand down
	_trunk += (want - _trunk) * (1.0 - exp(-dt / 0.3))
	if absf(_trunk) < 0.002:
		return
	var base := Quaternion.IDENTITY
	for b in _chain:
		var share: float = [0.0, 0.5, 0.3, 0.2][mini(_chain.find(b), 3)]
		if share > 0.0:
			# lean forward = a turn about the line through his hips from side to side
			var turn := Quaternion(Vector3(1.0, 0.0, 0.0), _trunk * share)
			rot[b] = (base.inverse() * turn * base * rot[b]).normalized()
		base = base * rot[b]


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


## Pose of a ledge clip (step off, fall, land), on the spot: the body does the travelling and the falling, so the
## clip's hips keep only their height above its own landing ground.
func _drop_pose(c: Resource, t: float, out: Array[Quaternion]) -> Vector3:
	for i in _n:
		out[i] = c.call(&"rotation_at", i, t)
	var path: PackedVector3Array = c.get(&"hips")
	var at := clampf(t * float(c.get(&"fps")), 0.0, float(path.size() - 1))
	var i0 := mini(int(at), path.size() - 2)
	var y := lerpf(path[i0].y, path[i0 + 1].y, at - float(i0))
	# the clip ends standing on its landing ground: heights are taken from there
	var end_y := path[path.size() - 1].y
	return Vector3(0.0, minf(y - end_y + _stand_height(), _stand_height()), 0.0)


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
