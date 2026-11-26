extends Node3D
## The character on the body. Rebuilt on 26 Nov 2026 as the study's Part 2 describes it (Yasin: "Rebuild as the study
## says"): "One `AnimationTree` set to the physics tick. In normal movement the clips play to match the body's speed;
## their root travel is cancelled by Godot and used only as a measurement." It only looks: the body alone decides
## where he is. The earlier, code-posed character is kept as character_v1.gd (run the lab with `-- --v1`).
##
## BUILT SO FAR: Stage 3 (idle, walk, run, the walk-to-run change, lean, jump, falling, landing).
## NOT REBUILT YET: Stage 4 (feet and head: leg IK, look-at) and Stage 5 (starts, stops, turns on the spot), and the
## stairs and steep-ground clips. Until they are, he walks stairs and slopes with the plain walk.

const ArmOpen := preload("res://traversal/character/arm_open.gd")
const FootPlace := preload("res://traversal/character/foot_place.gd")
const FootOrient := preload("res://traversal/character/foot_orient.gd")
const HandPlace := preload("res://traversal/character/hand_place.gd")
const HandHold := preload("res://traversal/character/hand_hold.gd")
const MODEL := "res://traversal/character/player_v4_rooted.scn"
const LIBRARY := "res://traversal/character/library.res"
const SKEL := "Skeleton3D"
# The loops of moving on foot. All three are lined up to begin with the left foot furthest forward (`start_offset`,
# the study: "lines up feet between walk and run").
const IDLE := "Standing_Idle"
const WALK := "KM_Walk"
const JOG := "KM_Run"
const RUN := "Running"
# The study: "People switch from walk to run at about 2.0 m/s". Below it he walks (the walk played faster or slower),
# above it he runs; the two are blended only across this narrow band round the switch.
const SWITCH := 2.0
# The study: "Young adults take 115 to 120 steps a minute with a 1.5 to 1.7 m stride (two steps)". The walk clip's own
# stride on him is 1.38 m, which at his 1.45 m/s made 126 quick short steps a minute (Yasin, 26 Nov: "THE WALK SOMEHOW
# CHANGED TO A WOMANS"). The stride is lengthened to this instead of the steps being hurried: the loop is paced as if
# its stride were this long, and the planted feet, held to the ground by the leg IK, take up the difference. (The
# study cites the method: Epic "scaled stride length rather than playback speed to match ground speed".)
const WALK_STRIDE := 1.506      # m: 1.45 m/s at 115.5 steps a minute
const SWITCH_BAND := 0.1        # NOT in the study: half the width of the band over which walk gives way to run (m/s)
const FADE := 0.20              # NOT in the study: seconds to blend from one kind of motion to the next
const SCALE_LEAST := 0.5        # NOT in the study: a loop is never played slower or faster than this
const SCALE_MOST := 1.8
# Lean into a turn: tan(lean) = speed x turn rate / g, and no more than people were measured to lean: "lean into a
# 90 degree corner by 4.4, 6.8 and 12.7 degrees at slow, normal and fast walking speed".
# Those figures are the whole lean of a walker, the stride's own side-to-side sway included, so it is the whole lean
# (what is added here plus where the stride has the chest at that moment) that is held to them: see _lean.
const LEAN_SLOW_DEG := 4.4
const LEAN_WALK_DEG := 6.8
const LEAN_FAST_DEG := 12.7
const LEAN_RUN_DEG := 13.0      # NOT in the study's report (its notes: 13.6 deg on a sprinted curve)
const LEAN_TIME := 0.15         # NOT in the study: how quickly the lean follows (seconds)
const LEAN_OVER := 0.05         # NOT in the study: radians the eased lean may run past the limit before it is held to it
# The Jump clip (measured): lowest at 0.50 s, leaves the ground at 0.80 s, lands at 1.30 s. The body takes the
# study's times ("0.70 s dipping and 0.30 s pushing"), so the clip's dip is played over 0.70 s and its push over 0.30.
const JUMP := {"clip": "Jump", "low": 0.50, "off": 0.80, "land": 1.30}
# The Running Jump clip: one run stride with a leap in it; leaves the ground at 0.10 s, down at 0.67 s (measured)
const RUN_JUMP := {"clip": "Running_Jump", "low": 0.0, "off": 0.10, "land": 0.67}
const LAND_SOFT := {"clip": "Falling_To_Landing", "contact": 0.27}       # the feet touch at 0.27 s (measured)
const LAND_HEAVY := {"clip": "Hard_Landing", "contact": 0.60}            # the feet touch at 0.60 s (measured)
# Walking or running off an edge (Yasin, 26 Nov: "looks stuck and frozen on air before landing"): Kimodo takes of
# stepping and of running off a ledge. leaves = the clip leaves the edge, touch = its feet touch down (measured)
const DROP_WALK := {"clip": "KM_Ledge_Walk_Off", "leaves": 2.10, "touch": 2.62}
const DROP_RUN := {"clip": "KM_Ledge_Run_Off", "leaves": 1.92, "touch": 2.72}
const FALL := "Falling_Idle"
const RUN_FROM := 2.5           # a fall that began faster than this uses the running ledge clip
const SOFT_DROP := 0.30         # the study: "up to 0.30 m, step down in stride; 0.30 to 1.0 m, step or hop off with a
const HARD_DROP := 1.0          # soft landing; 1.0 to 2.0 m, a heavy landing"
# the inputs of the tree's Transition node, and the clip each one plays under its own TimeSeek
const ACTS := {"jump": "Jump", "run_jump": "Running_Jump", "land_soft": "Falling_To_Landing", "land_heavy": "Hard_Landing",
		"drop_walk": "KM_Ledge_Walk_Off", "drop_run": "KM_Ledge_Run_Off", "drop_roll": "KM_Land_Roll", "step_up": "KM_Step_Up", "step_up_m": "KM_Step_Up_M", "vault": "Vault_1_Hand", "vault_m": "Vault_1_Hand_M",
		"vault_tuck": "KM_Vault_Stand", "climb_up": "KM_Climb_Up", "grab_jump": "Jump_To_Braced_Hang", "wallrun": "Sprint_To_Wall_Climb", "climb_down": "Climbing_Down", "grab_climb": "Braced_Hang_To_Crouch", "vault_jump": "KM_Jump_Over", "step_on": "Step_Onto_Platform", "step_on_m": "Step_Onto_Platform_M", "jump_on": "Running_Jump_Climb", "jump_on_m": "Running_Jump_Climb_M",
		"stairs_up_walk": "Ascending_Stairs", "stairs_up_run": "KM_Stairs_Run_Up_D",
		"stairs_down_walk": "KM_Stairs_Walk_Down", "stairs_down_run": "KM_Stairs_Run_Down",
		"steep_up": "KM_Climb_Hard", "steep_down": "KMY_Down_Hands_Balance_Long",
		"start_walk": "KM_Start_Walk", "start_run": "KM_Start_Run",
		"stop_walk": "KM_Stop_Walk", "stop_walk_m": "KM_Stop_Walk_M",
		"steep_down_start": "KM_Slope_Down_Start", "steep_down_stop": "KM_Slope_Down_Stop",
		"steep_up_start": "KM_Slope_Up_Start", "steep_up_stop": "KM_Slope_Up_Stop",
		"walk_to_run": "KM_Walk_To_Run", "walk_to_run_m": "KM_Walk_To_Run_M",
		"run_to_walk": "KM_Run_To_Walk", "run_to_walk_m": "KM_Run_To_Walk_M",
		"turn_90": "Left_Turn_90", "turn_90_m": "Left_Turn_90_M",
		"turn_180_walk": "Walking_Turn_180", "turn_180_walk_m": "Walking_Turn_180_M",
		"turn_180_run": "Running_Turn_180", "turn_180_run_m": "Running_Turn_180_M",
		"turn_180_step": "KM_Turn_180", "turn_180_step_m": "KM_Turn_180_M",
		"crouch_down": "KM_Crouch_Down", "crouch_up": "KM_Crouch_Up"}
# Stage 6, crouch (Yasin, 26 Nov: "DO THE CROUCH MOVES, ORDER WHATS MISSING FROM KIMODO"). The study: "Build: crouch
# idle and walk, the smaller capsule, the fit test before standing." The body crouches (body.gd); here the crouch idle
# and the crouch walk take the place of standing and the gait loops. All four clips are Kimodo takes of 26 Nov: the
# study found no clip in the folder that moves with the head under 1.29 m, and the course's overhang is 1.2 m.
# Standing still he goes down and comes up with the two clips; on the move the two sets are blended across.
# A softer landing off the lower edges (Yasin, 26 Nov: "Make a softer landing for edges lower than 1 meter"). The
# step-off take lands from 1.15 m and folds for that; the library's other landing clips fold as deep. So the take is
# blended toward its own standing end by as much as the drop is short of the take's (see traverse.gd, "soft").
# input -> the moment of the clip at which he stands again
const SOFTEN := {"drop_walk": 3.30, "drop_run": 3.70}
const JUMP_BELOW := 0.15        # NOT in the study: this far below where he jumped from, the jump is over and he is falling (m)
const CROUCH_IDLE := "KM_Crouch_Idle"
const CROUCH_WALK := "KM_Crouch_Walk"
const CROUCH_FADE := 0.3        # NOT in the study: seconds to blend between standing and crouched while he is moving
const HEAD_ROOM := 0.03         # NOT in the study: the top of his head is kept this far under the top of the crouched body
const HEAD_OVER_JOINT := 0.23   # the top of his head above his head joint: standing, the joint is at 1.57 m (measured in
                                # the lab) and the study has the "top of head about 1.80 m"
# Changes of gait and turns on the spot (Yasin, 26 Nov: "i want all of them, include all of them in the next build").
# Walk to run and run to walk: Kimodo takes of 26 Nov (GTA V's movement set has "walk-to-run and run-to-walk changes
# by foot": the study). Turns on the spot: Left Turn 90, Walking Turn 180 and, for the plant-and-turn out of a run,
# Running Turn 180, each with its mirror image for the other way (the study, Part 3). The body does the turning and
# sets the pace, as everywhere; the clips are shown by how far it has got.
# Walk to run is carried by the loops themselves again, the walk giving way to the run as he gathers speed (Yasin, 26
# Nov: "transition from walking to running plays two timid short steps before transition is complete, make that
# transition smoother"). The Kimodo walk-to-run take, in since trav30, is those two steps. Run to walk keeps its take.
const WALK_TO_RUN_CLIP := false
const CHANGE_PACE := [0.8, 1.3]   # NOT in the study: a change-of-gait clip is taken up where its own pace is within these shares of his
const TURN_PACE := [0.6, 1.5]     # NOT in the study: a turn clip runs at between these shares of its own pace
const TURN_BIG_DEG := 120.0     # NOT in the study: a turn on the spot of more than this is shown with the 180 clip, less with the 90
# The 180 on the spot from standing: Mixamo's Walking Turn 180, which spins round in one second on the balls of the
# feet. DEPARTS FROM THE STUDY AT YASIN'S WORD. The study: "Turning 180 degrees on the spot takes about 3 to 4 steps".
# A Kimodo take that turns round in steps over 1.8 s was put in for it on 26 Nov (trav31); he, the same day:
# "character doesnt turn around without stepping to some direction and slowly arching back, it should turn around
# without taking any steps". The stepped take is still in the library (turn_180_step), not used.
# Starting and stopping on the very steep ground, going down (Yasin, 26 Nov: "start slope climb stop slope climb
# needed. fit what we have into here"): the first 1.7 s and the last 1.9 s of his own long downhill take, whose
# middle is the loop: he eases off from standing, and comes to rest. Played as the flat starts and stops are, by the
# ground the body covers. Going UP there is no such clip: his uphill take has no start or stop in it, and the four
# Kimodo takes ordered for it stand still.
# Stage 5, starts and stops (Yasin, 26 Nov: "start walk, stop walk, start run ... needed. fit what we have into
# here"). The study: "Build: start, stop and turn-on-the-spot clips, chosen by direction and by which foot is
# forward." The body keeps its own speeds ("It alone decides where the character is"); a start is played by how far
# he has gone and a stop by how far he still has to go, so the feet keep to the ground he really covers.
# The clips: the walk start is a Kimodo take of a man starting to walk (Yasin, 26 Nov: "dont use female start stop,
# this is a male character. order new ones from kimodo"); Mixamo's own Start Walking takes about 3 s, which the
# study calls slow. The run start is a Kimodo take too (26 Nov), in place of Mixamo's Idle To Sprint.
# Only on ordinary ground: stairs and steep ground have their own clips.
# The walk stop is a Kimodo take of a man stopping from a walk (Yasin, 26 Nov: "Don't use female clips, this is a
# guy. Just get new ones done"). It is taken up where it has as far left to go as he has, and runs on by the ground
# he covers: the planted feet then drift 0.07 cm (the audit; 4.8 cm when it was fitted by pose and squeezed into his
# stopping distance instead). It ends with the feet together; the study has the rear foot left planted: NOT met.
const STOP_CLIP := true
const STOP_BY_POSE := false
const START_OVER := 1.35        # NOT in the study: a start is left for the loop once the body outruns the clip's
const START_OVER_MORE := 0.3    # own end speed by this share, plus this (m/s)
# Very steep ground (the body's "hands" band, over 35 degrees: the 45 degree ramp; OUTSIDE the study, kept at Yasin's
# word, "Keep it, body in charge"). Yasin, 26 Nov: "steep slope up and down are supposed to use these animations,
# open their hands to the sides just a bit in both", and then "no these clips were only for 45 degrees". Between 20
# and 35 degrees he walks with the ordinary walk, fitted by the leg IK, as before:
# his own two Kimodo takes (up: leaning steps, a bend with both hands down, the push back up; down: crouched, leaning
# back, the hands out for balance). The body sets the pace; the take is played by the ground he covers.
const STEEP_ARMS_DEG := 8.0     # NOT in the study, mine: "just a bit" (Yasin); the arms opened this much more on these takes
# Going up (Yasin, 26 Nov, after seeing the 8 degrees: "hands are too closed, open them at least 10 cm each
# direction"): 10 cm at the hand, 0.55 m from the shoulder, is 10.5 degrees more.
const STEEP_ARMS_UP_DEG := 19.0
# The takes end where the steep ground does (Yasin, 26 Nov: "it doesnt detect the end of the slope, so it keeps
# looking like climbing although a short normal step is enough at the end"): when the ground one walking step ahead
# (half the study's stride of 1.5 m, measured along the slope) is no longer very steep, he walks.
const STEEP_STEP := 0.75
# Standing (Yasin, 26 Nov: "feet need to be a bit wider both on idle and and standing still"). The study gives no
# standing foot spacing. Each foot is set this far out to its side while he stands, and comes back in as he walks.
const STAND_WIDE := 0.03        # NOT in the study, mine: "a bit" (Yasin). Metres, each foot: 6 cm wider in all
const STEEP_TURN := 0.1         # NOT in the study: the take for the other way only once the ground rises or falls this much a metre
# Stairs are their own movement (the study: "Going up and going down are different movements, not one played
# backwards"; "Stairs are climbed at about half a second per step: 0.51 s up and 0.47 s down", which is the body's
# pace there). Each stair clip is two steps a loop and is played by WHERE HE IS on the stairs, so that each foot comes
# down in the middle of a tread; the feet are then fitted to the real steps by the leg IK ("On city stairs they will
# need the feet corrected by leg IK": the clips were made on steeper stairs). Mixamo's two going-down clips are
# damaged (the study, 26 Nov) and are not used: going down, and running, are Kimodo takes.
const STAIR_RUN := 0.4          # NOT in the study: asked to take a step in less than this many seconds, he runs the stairs
const STAIR_PULL := 3.0         # NOT in the study: how fast the stride is drawn to its place on the stairs (a share a second)

var body: CharacterBody3D
var skel: Skeleton3D
var tree: AnimationTree
var player: AnimationPlayer
var note := ""
var landing_kind := ""          # for the readout and the audit: "" (none), "soft", "heavy" or "jump"
var lean := 0.0                 # radians, + = to his left
var arm_open_deg := 9.0         # see arm_open.gd

var _pivot: Node3D
var _lib: AnimationLibrary
var _stride := {}               # loop -> metres a cycle (its root's travel)
var _length := {}               # loop -> seconds a cycle
var _mode := "ground"           # ground, jump, fall, land
var _act := "ground"            # which input of the Transition is showing
var _act_t := 0.0               # where the clip under the showing input is (seconds)
var _mode_t := 0.0
var _moving := 0.0              # 0 = standing (idle), 1 = the gait loops
var _scale := 1.0
var _natural := 0.0             # the speed the gait blend would cover the ground at, played at its own pace
var _settled := 0.0             # seconds since the tree last changed what it shows
var _jump: Dictionary = JUMP
var _jump_e := 0.0              # seconds since the jump button
var _jump_still := true
var _flight := 0.6
var _drop: Dictionary = {}
var _last_dir := Vector3.ZERO
var _measured := 0.0            # the natural speed as measured from the tree's root motion (0 = not measured)
var feet: SkeletonModifier3D
var _leg_ik: TwoBoneIK3D
var _orient: SkeletonModifier3D
var _chest_i := -1
var _lean_s := 0.0              # the lean, eased, before it is held to the study's limit
var _own_mean := 0.0            # where the stride has the chest over the feet, averaged over about a stride
var _stair_phase := 0.0         # strides along the stairs (two steps a stride)
var _stair_on := false
var _steep_on := false
var _steep_up := true
var _steep_phase := 0.0         # strides along the take
var _steep_w := 0.0             # 0..1: a steep take is showing (for the arms)
var _arms: SkeletonModifier3D
var _sub := ""                  # "" (the loops), "start" or "stop": a start or stop clip is showing
var _sub_in := ""               # which input of the tree it is
var _let_go_at := -1.0
var _slope_in := "steep_down_start"
var _slope_sub := ""            # on the steep ground going down: "" (the loop), "start" or "stop"
var _stop_from := 0.0           # where in the stop clip it was taken up, and how far he then had left to go
var _stop_left := 0.0
var _gone := 0.0                # metres covered since the start began
var _yaw := {}                  # input -> radians its clip has turned, tick by tick
var _fastest := {}              # input -> the fastest its clip goes (m/s)
var _change_from := 0.0         # metres into a change-of-gait clip at which it was taken up
var _slowing := false           # he has been asked to walk while running, and no clip has been taken up for it yet
var _wish_was := 0.0            # the pace asked for last tick
var _lead_last := 0.0           # how far the left ankle was ahead last tick, and whether that is growing
var _lead_rising := false
var _dist := {}                 # input -> metres its clip has covered, tick by tick (from its root's own travel)
var hands: SkeletonModifier3D
var _slope := 0.0               # the showing stair clip's own slope, eased in and out with it
var _hips_fit := 0.0
var _slope_from := 0.0
var _slope_to := 0.0
var _slope_t := 0.0
var _foot_i := [-1, -1]
var _foot_len := 0.0            # from the ankle to the ball of the foot, along the ground (from the skeleton)
var _jump_low := 0.5            # the Jump clip: the moment its hips are lowest (found from the clip itself)
var _free := 0.0                # 0..1: the feet are left as the clip has them (a roll)
var _jump_y0 := 0.0             # the height he jumped from
var _soft := 0.0                # 0..1: how far a landing is eased toward standing
var _low_w := 0.0               # 0 = the standing set, 1 = the crouched set
var _low_was := false
var _head_i := -1


func _ready() -> void:
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	model.rotation.y = PI      # the clips face +Z, the body faces -Z
	_pivot = Node3D.new()      # turns about the feet, for the lean
	add_child(_pivot)
	_pivot.add_child(model)
	skel = model.get_node(SKEL)
	_chest_i = skel.find_bone("mixamorig_Spine2")
	_head_i = skel.find_bone("mixamorig_Head")
	_foot_i = [skel.find_bone("mixamorig_LeftFoot"), skel.find_bone("mixamorig_RightFoot")]
	_foot_len = skel.get_bone_global_rest(skel.find_bone("mixamorig_LeftToeBase")).origin.z - skel.get_bone_global_rest(skel.find_bone("mixamorig_LeftFoot")).origin.z
	# The study, Timing: "`AnimationTree.callback_mode_process` and `Skeleton3D.modifier_callback_mode_process` both
	# set to physics, so clips, IK and queries all see the same moment."
	skel.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS
	_lib = load(LIBRARY)
	player = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	model.add_child(player)
	player.add_animation_library(&"", _lib)
	for n: String in [WALK, JOG, RUN, "KM_Climb_Hard", "KMY_Down_Hands_Balance_Long", CROUCH_WALK]:
		var a := _lib.get_animation(n)
		_length[n] = a.length
		var t := a.find_track(NodePath("%s:Root" % SKEL), Animation.TYPE_POSITION_3D)
		_stride[n] = (a.position_track_interpolate(t, a.length) - a.position_track_interpolate(t, 0.0)).length()
	for key: String in ["turn_90", "turn_90_m", "turn_180_walk", "turn_180_walk_m", "turn_180_run", "turn_180_run_m", "turn_180_step", "turn_180_step_m"]:
		var a := _lib.get_animation(ACTS[key])
		var t := a.find_track(NodePath("%s:Root" % SKEL), Animation.TYPE_ROTATION_3D)
		var table := PackedFloat32Array()
		var turned := 0.0
		var last := 0.0
		for i in int(a.length * 60.0) + 1:
			var q := a.rotation_track_interpolate(t, i / 60.0)
			var yaw := wrapf(2.0 * atan2(q.y, q.w), -PI, PI)
			turned += wrapf(yaw - last, -PI, PI)
			last = yaw
			table.append(turned)
		_yaw[key] = table
	for key: String in ["start_walk", "start_run", "stop_walk", "stop_walk_m", "steep_down_start", "steep_down_stop", "steep_up_start", "steep_up_stop", "walk_to_run", "walk_to_run_m", "run_to_walk", "run_to_walk_m"]:
		var a := _lib.get_animation(ACTS[key])
		var t := a.find_track(NodePath("%s:Root" % SKEL), Animation.TYPE_POSITION_3D)
		var table := PackedFloat32Array()
		var from := a.position_track_interpolate(t, 0.0)
		for i in int(a.length * 60.0) + 1:
			table.append(maxf(a.position_track_interpolate(t, i / 60.0).distance_to(from), table[i - 1] if i > 0 else 0.0))
		_dist[key] = table
		# (and the fastest the clip itself goes, over a fifth of a second)
		var top := 0.0
		for i in range(12, table.size()):
			top = maxf(top, (table[i] - table[i - 12]) / 0.2)
		_fastest[key] = top
	# the standing jump's lowest moment, from the clip: its dip ends there and its push begins
	var ja := _lib.get_animation(String(JUMP["clip"]))
	var jt := ja.find_track(NodePath("%s:mixamorig_Hips" % SKEL), Animation.TYPE_POSITION_3D)
	var lowest := INF
	for i in int(float(JUMP["off"]) * 60.0):
		var y := ja.position_track_interpolate(jt, i / 60.0).y
		if y < lowest:
			lowest = y
			_jump_low = i / 60.0
	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	tree.tree_root = _make_tree()
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	model.add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.root_node = tree.get_path_to(model)
	tree.root_motion_track = NodePath("%s:Root" % SKEL)
	tree.active = true
	# Layer 3, the corrections, as children of the skeleton in the study's order: "a pelvis height offset (custom),
	# leg `TwoBoneIK3D`, arm `TwoBoneIK3D`, `BoneTwistDisperser3D` for forearms, look-at for spine then neck then
	# head, `LimitAngularVelocityModifier3D` as a pop filter". (Arm IK and the twist disperser come with the first
	# move that puts hands on something; they are NOT built yet.)
	if body:
		feet = FootPlace.new()
		feet.name = "FootPlace"
		feet.set(&"body", body)
		feet.call(&"bind", skel)
		skel.add_child(feet)
		var ik := TwoBoneIK3D.new()
		ik.name = "LegIK"
		skel.add_child(ik)
		ik.setting_count = 2
		var side := ["Left", "Right"]
		var targets: Array[Node3D] = []
		var poles: Array[Node3D] = []
		for f in 2:
			var t := Node3D.new()
			t.name = "%sFootTarget" % side[f]
			skel.add_child(t)
			targets.append(t)
			var p := Node3D.new()
			p.name = "%sKneePole" % side[f]
			skel.add_child(p)
			poles.append(p)
			ik.set_root_bone(f, skel.find_bone("mixamorig_%sUpLeg" % side[f]))
			ik.set_middle_bone(f, skel.find_bone("mixamorig_%sLeg" % side[f]))
			ik.set_end_bone(f, skel.find_bone("mixamorig_%sFoot" % side[f]))
			ik.set_target_node(f, ik.get_path_to(t))
			ik.set_pole_node(f, ik.get_path_to(p))
		feet.set(&"target", targets)
		feet.set(&"pole", poles)
		_leg_ik = ik
		_orient = FootOrient.new()
		_orient.name = "FootOrient"
		_orient.set(&"place", feet)
		skel.add_child(_orient)
	var arms: SkeletonModifier3D = ArmOpen.new()
	arms.name = "ArmOpen"
	arms.set(&"open_deg", arm_open_deg)
	skel.add_child(arms)
	_arms = arms
	if body:
		# after the legs, the arms (the study's order), here for the takes that put hands on the ground
		hands = HandPlace.new()
		hands.name = "HandPlace"
		hands.set(&"body", body)
		hands.call(&"bind", skel)
		skel.add_child(hands)
		var h_targets: Array[Node3D] = []
		var h_poles: Array[Node3D] = []
		var h_ik: Array[SkeletonModifier3D] = []
		var hs := ["Left", "Right"]
		for f in 2:
			var t := Node3D.new()
			t.name = "%sHandTarget" % hs[f]
			skel.add_child(t)
			h_targets.append(t)
			var p := Node3D.new()
			p.name = "%sElbowPole" % hs[f]
			skel.add_child(p)
			h_poles.append(p)
			var one := TwoBoneIK3D.new()
			one.name = "%sArmIK" % hs[f]
			skel.add_child(one)
			one.setting_count = 1
			one.set_root_bone(0, skel.find_bone("mixamorig_%sArm" % hs[f]))
			one.set_middle_bone(0, skel.find_bone("mixamorig_%sForeArm" % hs[f]))
			one.set_end_bone(0, skel.find_bone("mixamorig_%sHand" % hs[f]))
			one.set_target_node(0, one.get_path_to(t))
			one.set_pole_node(0, one.get_path_to(p))
			one.influence = 0.0
			h_ik.append(one)
		hands.set(&"target", h_targets)
		hands.set(&"pole", h_poles)
		hands.set(&"ik", h_ik)
		var hand_hold: SkeletonModifier3D = HandHold.new()
		hand_hold.name = "HandHold"
		hand_hold.set(&"place", hands)
		skel.add_child(hand_hold)       # (after the two arm IKs, which were added in the loop above)
		feet.set(&"hands", hands)
	if body:
		body.connect(&"jump_started", _on_jump_started)
		body.connect(&"landed", _on_landed)


## The tree: standing and the gait loops, and beside them one input for each clip that code plays by its own clock.
func _make_tree() -> AnimationNodeBlendTree:
	var bt := AnimationNodeBlendTree.new()
	var idle := AnimationNodeAnimation.new()
	idle.animation = IDLE
	bt.add_node(&"idle", idle, Vector2(0, 0))
	# The study: "`AnimationNodeBlendSpace1D` ... using `SYNC_MODE_CYCLIC_MUTABLE`" and "`AnimationNodeAnimation` custom
	# timeline with `start_offset`": the loops keep step with each other and all begin on the left foot.
	var gait := AnimationNodeBlendSpace1D.new()
	gait.min_space = 0.0
	gait.max_space = 2.0
	gait.sync_mode = AnimationNodeBlendSpace1D.SYNC_MODE_CYCLIC_MUTABLE
	var at := 0.0
	for n: String in [WALK, JOG, RUN]:
		var node := AnimationNodeAnimation.new()
		node.animation = n
		node.use_custom_timeline = true
		# Every loop is laid on a timeline one second long (one stride a second at scale 1), so that one moment of
		# the timeline is the same point of the stride in all three. With each loop on its own length, setting the
		# stride to a given foot (coming off the stairs, out of a start) set the three loops to three different
		# points of their strides, and the run, a blend of two of them, came apart. (Yasin, 26 Nov, after trav22,
		# the first build that set the stride: running "somehow broke".)
		node.timeline_length = 1.0
		node.stretch_time_scale = true
		node.start_offset = _phase_offset(n) / float(_length[n])     # in timeline time: a share of the stride
		node.loop_mode = Animation.LOOP_LINEAR
		gait.add_blend_point(node, at, -1, n)
		at += 1.0
	bt.add_node(&"gait", gait, Vector2(0, 200))
	bt.add_node(&"gait_speed", AnimationNodeTimeScale.new(), Vector2(200, 200))
	bt.connect_node(&"gait_speed", 0, &"gait")
	# (a TimeSeek on the gait: coming off the stairs the walk is set to the foot the stairs left him on)
	bt.add_node(&"gait_seek", AnimationNodeTimeSeek.new(), Vector2(300, 200))
	bt.connect_node(&"gait_seek", 0, &"gait_speed")
	bt.add_node(&"ground", AnimationNodeBlend2.new(), Vector2(400, 100))
	bt.connect_node(&"ground", 0, &"idle")
	bt.connect_node(&"ground", 1, &"gait_seek")
	# the crouched set beside it: crouch idle and the crouch walk, and a blend from the standing set to this one
	var low_idle := AnimationNodeAnimation.new()
	low_idle.animation = CROUCH_IDLE
	bt.add_node(&"crouch_idle", low_idle, Vector2(0, -300))
	var low_walk := AnimationNodeAnimation.new()
	low_walk.animation = CROUCH_WALK
	bt.add_node(&"crouch_walk", low_walk, Vector2(0, -200))
	bt.add_node(&"crouch_speed", AnimationNodeTimeScale.new(), Vector2(200, -200))
	bt.connect_node(&"crouch_speed", 0, &"crouch_walk")
	bt.add_node(&"crouch_ground", AnimationNodeBlend2.new(), Vector2(400, -250))
	bt.connect_node(&"crouch_ground", 0, &"crouch_idle")
	bt.connect_node(&"crouch_ground", 1, &"crouch_speed")
	bt.add_node(&"stance", AnimationNodeBlend2.new(), Vector2(600, 0))
	bt.connect_node(&"stance", 0, &"ground")
	bt.connect_node(&"stance", 1, &"crouch_ground")
	var act := AnimationNodeTransition.new()
	act.xfade_time = FADE
	act.input_count = ACTS.size() + 2
	act.set_input_name(0, "ground")
	act.set_input_reset(0, false)       # the stride carries on where it was when he comes back to it
	bt.add_node(&"act", act, Vector2(800, 100))
	bt.connect_node(&"act", 0, &"stance")
	var fall := AnimationNodeAnimation.new()
	fall.animation = FALL
	bt.add_node(&"fall_anim", fall, Vector2(400, 300))
	act.set_input_name(1, "fall")
	bt.connect_node(&"act", 1, &"fall_anim")
	var i := 2
	for key: String in ACTS:
		var a := AnimationNodeAnimation.new()
		a.animation = ACTS[key]
		bt.add_node(StringName("anim_" + key), a, Vector2(400, 300 + i * 100))
		bt.add_node(StringName("seek_" + key), AnimationNodeTimeSeek.new(), Vector2(600, 300 + i * 100))
		bt.connect_node(StringName("seek_" + key), 0, StringName("anim_" + key))
		act.set_input_name(i, key)
		if SOFTEN.has(key):
			# beside the clip, the same clip held at its standing end: blended toward it, the landing folds less
			var held := AnimationNodeAnimation.new()
			held.animation = ACTS[key]
			bt.add_node(StringName("held_" + key), held, Vector2(400, 350 + i * 100))
			bt.add_node(StringName("hold_" + key), AnimationNodeTimeSeek.new(), Vector2(600, 350 + i * 100))
			bt.connect_node(StringName("hold_" + key), 0, StringName("held_" + key))
			bt.add_node(StringName("soft_" + key), AnimationNodeBlend2.new(), Vector2(700, 320 + i * 100))
			bt.connect_node(StringName("soft_" + key), 0, StringName("seek_" + key))
			bt.connect_node(StringName("soft_" + key), 1, StringName("hold_" + key))
			bt.connect_node(&"act", i, StringName("soft_" + key))
		else:
			bt.connect_node(&"act", i, StringName("seek_" + key))
		i += 1
	bt.connect_node(&"output", 0, &"act")
	return bt


## Seconds into a loop at which the left foot is furthest forward (measured when the clip was baked).
func _phase_offset(n: String) -> float:
	var c: Resource = load("res://traversal/character/clips/%s.res" % n)
	return fposmod(float(c.get(&"phase_offset")), float(c.get(&"length")))


func _on_jump_started(_push: float) -> void:
	_jump_still = bool(body.get(&"_jump_still"))
	_jump = JUMP if _jump_still else RUN_JUMP
	_jump_e = 0.0
	_jump_y0 = body.global_position.y
	var rise := float(body.get(&"JUMP_RISE")) if _jump_still else float(body.get(&"JUMP_RISE_RUN"))
	_flight = 2.0 * sqrt(2.0 * rise / float(body.get(&"GRAVITY")))
	_set_mode("jump")
	_show("jump" if _jump_still else "run_jump", 0.0)


func _on_landed(drop: float) -> void:
	if _mode == "jump" and drop < 0.9:
		# the jump clip carries on from where its feet touch down
		landing_kind = "jump"
		_set_mode("land")
		_show(_act, float(_jump["land"]))
	elif drop >= HARD_DROP:
		landing_kind = "heavy"
		_set_mode("land")
		_show("land_heavy", float(LAND_HEAVY["contact"]))
	elif _mode == "fall" and not _drop.is_empty() and drop > SOFT_DROP:
		# the ledge clip carries on from where its feet touch down
		landing_kind = "soft"
		_set_mode("land")
		_show(_act if _act.begins_with("drop_") else ("drop_run" if _drop == DROP_RUN else "drop_walk"), float(_drop["touch"]))
	elif drop > SOFT_DROP:
		landing_kind = "soft"
		_set_mode("land")
		_show("land_soft", float(LAND_SOFT["contact"]))
	else:
		_set_mode("ground")
		_show("ground", 0.0)


func _set_mode(m: String) -> void:
	if m != "land":
		landing_kind = ""
	_mode = m
	_mode_t = 0.0


## Show one input of the Transition, its clip at `t` seconds.
func _show(input: String, t: float) -> void:
	if input != _act:
		tree.set(&"parameters/act/transition_request", input)
		_settled = 0.0
	_act = input
	_act_t = t
	_seek()


func _seek() -> void:
	if ACTS.has(_act):
		tree.set(StringName("parameters/seek_%s/seek_request" % _act), _act_t)


func _clip_length(input: String) -> float:
	return _lib.get_animation(ACTS[input]).length


func _physics_process(dt: float) -> void:
	if body == null:
		return
	var in_air := int(body.get(&"state")) >= 2
	var speed := (body.get(&"hvel") as Vector3).length()
	_mode_t += dt
	_settled += dt
	_measure(dt)
	var lead := _lead_now()
	_lead_rising = lead > _lead_last
	_lead_last = lead
	# a traversal move: the body is carried by it, and its clip is shown where the body says it is
	if bool(body.call(&"in_move")):
		if _mode != "move":
			_set_mode("move")
			_sub = ""
			_slope_sub = ""
			_stair_on = false
			_steep_on = false
		_show(String(body.get(&"move_clip")), float(body.get(&"move_clip_t")))
		_soft = float(body.get(&"move_soft"))
		landing_kind = String(body.get(&"move_landing")) if bool(body.get(&"move_landed")) else ""
	elif _mode == "move":
		_set_mode("ground")
		_to_loops()
	if _mode != "move":
		_soft = move_toward(_soft, 0.0, dt / FADE)
	for key: String in SOFTEN:
		tree.set(StringName("parameters/soft_%s/blend_amount" % key), _soft if _act == key else 0.0)
		tree.set(StringName("parameters/hold_%s/seek_request" % key), float(SOFTEN[key]))
	match _mode:
		"ground":
			var st := int(body.get(&"stairs"))
			var wish := (body.get(&"_wish") as Vector3).length()
			var low := bool(body.get(&"crouched"))
			var plain := not in_air and st == 0 and int(body.get(&"terrain")) == 0 and not low
			if low != _low_was:
				_low_was = low
				if speed < 0.3 and not in_air and not _stair_on and not _steep_on and (_act == "ground" or _sub == "crouch"):
					# standing still: down into the crouch, or up out of it, with the clip for it
					var back := _sub == "crouch"
					_sub = "crouch"
					_sub_in = "crouch_down" if low else "crouch_up"
					# (the set he is leaving stays under the clip until the clip is done. Changed at once, as it was until
					# 26 Nov, the clip was faded in from the other set: going down he dropped, came back up and went
					# down again. Yasin: "both standing still to crouch and crouching to standng are broken".)
					_low_w = 0.0 if low else 1.0
					# (turned round half way: the other clip from as far through as this one had left)
					_show(_sub_in, clampf(_clip_length(_sub_in) - _act_t, 0.0, _clip_length(_sub_in) - 0.1) if back else 0.0)
				elif _sub != "" or (ACTS.has(_act) and not _stair_on and not _steep_on):
					_sub = ""
					_show("ground", 0.0)
			# (the pace he was at when the stick was let go: a stop from a run is not a stop from a walk)
			if _wish_was > RUN_FROM and wish > 0.05 and wish <= SWITCH:
				_slowing = true
			elif wish > SWITCH or wish < 0.05 or speed <= SWITCH or _sub != "":
				_slowing = false
			if wish > 0.05:
				_let_go_at = -1.0
			elif _let_go_at < 0.0:
				_let_go_at = speed
			if _sub != "" and _sub != "crouch" and not plain:
				_sub = ""
				if not _stair_on and not _steep_on:
					_show("ground", 0.0)
			if _sub == "crouch":
				_act_t += dt
				if _act_t >= _clip_length(_sub_in) - 0.05 or speed > 0.3 or in_air:
					if _act_t >= _clip_length(_sub_in) - 0.05:
						_low_w = 1.0 if low else 0.0
					_sub = ""
					_show("ground", 0.0)
				else:
					_seek()
			elif _sub == "turn":
				_turn(dt, wish)
			elif _sub == "change":
				_change(dt, speed, wish)
			elif _sub != "":
				_start_or_stop(dt, speed, wish)
			elif plain and _act == "ground" and not _stair_on and not _steep_on:
				var spot := float(body.get(&"spot_total"))
				if spot != 0.0:
					# a turn on the spot: the clip for its size, or the one out of a run; of that clip and its mirror
					# image, the one that turns the way he is turning
					var kind := "turn_180_run" if bool(body.get(&"spot_run")) else ("turn_180_walk" if absf(spot) > deg_to_rad(TURN_BIG_DEG) else "turn_90")
					var base: PackedFloat32Array = _yaw[kind]
					_sub = "turn"
					_sub_in = kind if (base[base.size() - 1] > 0.0) == (spot > 0.0) else kind + "_m"
					_show(_sub_in, 0.0)
				elif WALK_TO_RUN_CLIP and _moving >= 1.0 and _wish_was <= SWITCH and wish > RUN_FROM and speed > 1.0 and speed < SWITCH + 0.3:
					_begin_change("walk_to_run", speed)
				elif _moving >= 1.0 and _slowing and speed > SWITCH:
					# (asked to walk while running: taken up as soon as he has slowed to a pace the clip has)
					_begin_change("run_to_walk", speed)
				elif speed < 0.3 and wish > 0.05 and _moving < 0.5:
					_sub = "start"
					_sub_in = "start_run" if wish > RUN_FROM else "start_walk"
					_gone = 0.0
					_show(_sub_in, 0.0)
				elif STOP_CLIP and wish < 0.05 and speed > 0.3 and _let_go_at <= RUN_FROM and _moving >= 1.0:
					# a stop from a walk: when what he still has to cover fits in the clip, the clip or its mirror
					# image, whichever has the same foot forward as he has now
					var total: float = _dist["stop_walk"][_dist["stop_walk"].size() - 1]
					var left := float(body.call(&"stop_distance"))
					if left <= total:
						# Taken up where the clip's feet are as far apart as his are now (among the moments from
						# which the clip still has at least his stopping distance to go), so the feet are not
						# pulled to a new spacing as it comes in; from there it runs to its end as he covers
						# what he has left. (Taken up by distance alone, the planted feet slid 2.5 cm.)
						var lead_clip: PackedFloat32Array = _lib.get_animation(ACTS["stop_walk"]).get_meta(&"lead", PackedFloat32Array())
						var now := _lead_now()
						var latest := _time_for("stop_walk", total - left)
						var t := latest
						var best := INF
						for i in (int(latest * 30.0) + 1 if STOP_BY_POSE else 0):
							var gap := absf(absf(lead_clip[mini(i, lead_clip.size() - 1)]) - absf(now))
							if gap <= best:
								best = gap
								t = i / 30.0
						var clip_left: bool = lead_clip[mini(int(t * 30.0), lead_clip.size() - 1)] > 0.0
						_sub = "stop"
						_sub_in = "stop_walk" if clip_left == (now > 0.0) else "stop_walk_m"
						_stop_from = t
						_stop_left = maxf(left, 0.01)
						_show(_sub_in, t)
			if _sub != "":
				pass
			elif _slope_sub == "stop" and not in_air and int(body.get(&"terrain")) == 2 and wish < 0.05:
				_slope_stop(dt, speed)
			elif not in_air and st != 0 and speed > 0.15 and not low:
				_steep_on = false
				_stairs(dt, st, speed)
			elif not in_air and int(body.get(&"terrain")) == 2 and speed > 0.1 and not low and _steep_ahead():
				_stair_on = false
				if _steep_on and wish < 0.05 and _slope_sub == "" and (_act == "steep_down" or _act == "steep_up"):
					# let go: the coming to rest for the way he was going (down: the end of his own take)
					_slope_sub = "stop"
					_slope_in = "steep_up_stop" if _steep_up else "steep_down_stop"
					# (taken up where the clip has as far left to go as he has)
					var stop_table: PackedFloat32Array = _dist[_slope_in]
					_show(_slope_in, _time_for(_slope_in, stop_table[stop_table.size() - 1] - float(body.call(&"stop_distance"))))
				else:
					_steep(dt, speed)
			elif _stair_on or _steep_on:
				if _stair_on and ACTS.has(_act):
					# The walk takes over on the foot the stairs left him on. (It used to carry on from wherever
					# it had been before the stairs: the foot that had just come down on the landing was lifted
					# and stepped again. Yasin, 26 Nov: "we take 1 more step after finishing the stairs".)
					var a := _lib.get_animation(ACTS[_act])
					var since_left := fposmod(_stair_phase - _phase_offset(ACTS[_act]) / a.length, 1.0)
					tree.set(&"parameters/gait_seek/seek_request", since_left)
				_stair_on = false
				_steep_on = false
				_show("ground", 0.0)
			if in_air:
				_sub = ""
				_slope_sub = ""
				_stair_on = false
				_steep_on = false
				# off an edge on foot: the step-off or run-off clip while its own fall lasts
				_drop = DROP_RUN if speed > RUN_FROM else DROP_WALK
				_set_mode("fall")
				_show("drop_run" if speed > RUN_FROM else "drop_walk", float(_drop["leaves"]))
			_wish_was = wish
		"jump":
			_jump_e += dt
			if in_air:
				var air := clampf(float(body.get(&"air_time")) / _flight, 0.0, 1.0)
				_act_t = lerpf(float(_jump["off"]), float(_jump["land"]), air)
				# (... or he is already below where he jumped from: he has jumped off something. Until 26 Nov the jump
				# clip was held on its last frame all the way down. Yasin: "we appear stuck in the same pose".)
				if float(body.get(&"air_time")) > _flight + 0.3 or body.global_position.y < _jump_y0 - JUMP_BELOW:
					# a longer fall than the jump has: the falling loop
					_drop = {}
					_set_mode("fall")
					_show("fall", 0.0)
			elif float(body.get(&"jump_timer")) > 0.0:
				if _jump_still:
					var dip := float(body.get(&"JUMP_DIP_STAND"))
					var push := float(body.get(&"JUMP_PUSH_STAND"))
					if _jump_e < dip:
						_act_t = _jump_low * _jump_e / dip
					else:
						_act_t = lerpf(_jump_low, float(_jump["off"]), clampf((_jump_e - dip) / push, 0.0, 1.0))
				else:
					_act_t = minf(_act_t + dt, float(_jump["off"]))
			elif _mode_t > 0.2:
				# the jump did not happen (the ground went from under him, or he was stopped)
				_set_mode("ground")
				_show("ground", 0.0)
			_seek()
		"fall":
			# The legs come down to meet the ground: when touchdown is as near as the landing clip's own lead-in is
			# long, that clip is played so that its contact frame falls on the tick he lands (the study: "Start the
			# landing fold on the contact frame, since force peaks within 35 to 91 ms").
			var ahead: Dictionary = body.call(&"landing_ahead") if in_air else {}
			var meet := ""
			if not ahead.is_empty():
				if float(ahead["drop"]) >= HARD_DROP and float(ahead["time"]) <= float(LAND_HEAVY["contact"]):
					meet = "land_heavy"
				elif float(ahead["drop"]) > SOFT_DROP and float(ahead["drop"]) < HARD_DROP and _drop.is_empty() and float(ahead["time"]) <= float(LAND_SOFT["contact"]):
					meet = "land_soft"
			if not in_air:
				_set_mode("ground")
				_show("ground", 0.0)
			elif meet != "":
				_drop = {}
				_show(meet, float((LAND_HEAVY if meet == "land_heavy" else LAND_SOFT)["contact"]) - float(ahead["time"]))
			elif _act.begins_with("land_"):
				pass        # between the lead-in and the ground: hold what is showing
			elif not _drop.is_empty():
				_act_t += dt
				if _act_t >= float(_drop["touch"]) - 0.04:
					_drop = {}
					_show("fall", 0.0)
				else:
					_seek()
		"land":
			if in_air:
				_drop = {}
				_set_mode("fall")
				_show("fall", 0.0)
			else:
				_act_t += dt
				var done := _act_t >= _clip_length(_act) - 0.05
				# moving off again cuts a landing short, once he has gathered himself (the body holds the stick off
				# for that long); a running jump runs on through its own clip
				if done or (speed > 1.0 and _mode_t > 0.45 and _act != "run_jump"):
					_set_mode("ground")
					_show("ground", 0.0)
				else:
					_seek()
	_ground(dt, speed)
	_lean(dt, not in_air)
	if feet:
		var want_slope := float(_lib.get_animation(ACTS[_act]).get_meta(&"slope", 0.0)) if ((_stair_on or _steep_on) and ACTS.has(_act)) else 0.0
		feet.set(&"by_speed", _steep_on)
		# a climbing move: the clip's own step, for the feet to be fitted from (see foot_place.gd)
		var st_m: Array = body.get(&"move_step") if bool(body.call(&"in_move")) else []
		feet.set(&"step_high", float(st_m[1]) if st_m.size() >= 3 else 0.0)
		feet.set(&"step_edge", float(st_m[0]) if st_m.size() >= 3 else 0.0)
		feet.set(&"step_rise", float(st_m[2]) if st_m.size() >= 3 else 0.0)
		feet.set(&"step_real", float(st_m[3]) if st_m.size() >= 4 else 0.0)
		feet.set(&"base", float(body.get(&"move_base")) if bool(body.call(&"in_move")) else 0.0)
		feet.set(&"stand_wide", STAND_WIDE * (1.0 - _moving) * (1.0 - _low_w) if _act == "ground" else 0.0)
		# (in step with the tree's own cross-fade, which is even over FADE: eased more slowly than the pose, the
		# feet of a stair clip coming in were held up on stairs that were no longer under them, 0.2 to 0.5 m high)
		if want_slope != _slope_to:
			_slope_from = _slope
			_slope_to = want_slope
			_slope_t = 0.0
		_slope_t += dt
		_slope = lerpf(_slope_from, _slope_to, clampf(_slope_t / FADE, 0.0, 1.0))
		feet.set(&"clip_slope", _slope)
		# A stair clip was made on its own stairs (Mixamo's rise 0.245 m a step, the city's 0.18: the study, Part 3).
		# Its hips stand right over its own steps; over shallower or steeper ones they are out by the difference of
		# the two slopes over the distance from the hips to the ball of the foot where the clip's leg is at its
		# longest (noted on the clip, "pivot"), so that leg is left as long as the clip has it and no longer.
		var riser := float(body.get(&"stair_riser"))
		var on_stairs := _stair_on and riser > 0.0 and ACTS.has(_act)
		var want_fit := 0.0
		if on_stairs:
			var a := _lib.get_animation(ACTS[_act])
			var real := signf(float(int(body.get(&"stairs")))) * riser / float(body.get(&"stair_tread"))
			want_fit = -(want_slope - real) * float(a.get_meta(&"pivot", 0.0))
			# where each foot next comes down: the left at the clip's own moment for it, the right half a stride on
			var tread := float(body.get(&"stair_tread"))
			var dir: Vector3 = body.get(&"stair_dir")
			var down := _phase_offset(ACTS[_act]) / a.length
			var lands: Array[Vector3] = []
			for f in 2:
				var to_go := fposmod(down + 0.5 * f - _stair_phase, 1.0)
				lands.append(body.global_position + dir * (to_go * 2.0 * tread + float(a.get_meta(&"reach", 0.0))))
			feet.set(&"land_at", lands)
			feet.set(&"stride_dir", dir)
		feet.set(&"stride_fit", on_stairs)
		# Crouched, the body's top is the limit (the study: the body "alone decides where the character is"): where
		# a take holds the top of his head higher than that, less a little room, the hips are lowered by as much.
		if _low_w > 0.0 and _act == "ground":
			var top := (skel.global_transform * skel.get_bone_global_pose(_head_i).origin).y - body.global_position.y + HEAD_OVER_JOINT
			want_fit -= maxf(top - (float(body.get(&"CROUCH_HEIGHT")) - HEAD_ROOM), 0.0) * _low_w
		_hips_fit += (want_fit - _hips_fit) * minf(dt / FADE, 1.0)
		feet.set(&"hips_fit", _hips_fit)
		# the fitting fades out in the air and back in on the ground; the three modifiers go together
		var w := float(feet.get(&"weight"))
		# (through a roll the feet are not fitted to the ground at all: he is upside down for part of it)
		_free = move_toward(_free, 1.0 if (bool(body.call(&"in_move")) and bool(body.get(&"move_free"))) else 0.0, dt / 0.15)
		w *= 1.0 - _free
		feet.influence = 1.0 - _free
		_leg_ik.influence = w
		_orient.influence = w
	_steep_w = move_toward(_steep_w, 1.0 if _steep_on else 0.0, dt / FADE)
	_arms.set(&"open_deg", arm_open_deg + (STEEP_ARMS_UP_DEG if _steep_up else STEEP_ARMS_DEG) * _steep_w)
	if hands:
		# a move that puts a hand on something: [which hand (0 left, 1 right), where its wrist goes, how much]
		var mh: Array = body.get(&"move_hand") if bool(body.call(&"in_move")) else []
		var w := [0.0, 0.0]
		# (one hand as [which, where, how much], or both as a list of two of those)
		var held: Array = [mh] if (mh.size() == 3 and not (mh[0] is Array)) else mh
		var flat := [false, false]
		for one: Array in held:
			w[int(one[0])] = float(one[2])
			(hands.get(&"hold_at") as Array)[int(one[0])] = one[1]
			flat[int(one[0])] = one.size() > 3 and bool(one[3])     # a fourth entry: the hand is laid flat on the top
		hands.set(&"hold_w", w)
		hands.set(&"hold_flat", flat)
		hands.set(&"on", _steep_on and ACTS.has(_act))
		if _steep_on and ACTS.has(_act):
			var a := _lib.get_animation(ACTS[_act])
			hands.set(&"clip_slope", float(a.get_meta(&"slope", 0.0)))
			hands.set(&"hand_low", float(a.get_meta(&"hand_low", 0.0)))
	note = "%s  gait x%.2f" % [_mode if _mode != "land" else "land (%s)" % landing_kind, _scale]


## On stairs: the clip for the way he is going and his pace, at the point of its stride that belongs to where he is.
func _stairs(dt: float, st: int, speed: float) -> void:
	var tread := float(body.get(&"stair_tread"))
	var run: bool = (body.get(&"_wish") as Vector3).length() > tread / STAIR_RUN
	var input := "stairs_%s_%s" % ["up" if st > 0 else "down", "run" if run else "walk"]
	var a := _lib.get_animation(ACTS[input])
	# steps taken so far, from the edges he has crossed and how far he is past the last one
	var along := (body.global_position - (body.get(&"stair_edge") as Vector3)).dot(body.get(&"stair_dir"))
	var steps := float(int(body.get(&"stair_count"))) + clampf(along / tread, 0.0, 1.0)
	# the left foot comes down `reach` ahead of him: that moment must find it over the middle of a tread. Going up
	# that is the ball of the foot (the heel may hang off the back of the step). Going down the whole foot has to
	# be on the tread, clear of the step above it, so there it is the middle of the foot, between ankle and ball,
	# that comes down mid-tread (with the ball mid-tread the heel stood inside the step above, and the foot was
	# thrown up onto that step: measured 26 Nov, 17 cm in one tick).
	var lands := 0.5 - float(a.get_meta(&"reach", 0.0)) / tread
	if st < 0:
		lands += 0.5 * _foot_len / tread
	var cycle := _phase_offset(ACTS[input]) / a.length + (steps - lands) * 0.5
	# the stride runs on by the ground covered and is only drawn toward that place (tied to it outright it jumped
	# at every step edge, because a measured tread is never exact)
	_stair_phase += speed * dt / (2.0 * tread)
	# A stride is two steps, so half a stride on puts the other foot on the same tread: either will do, and the one
	# nearer to where his stride already is, is the one taken. Coming onto the stairs that is the foot the walk
	# has forward. (Taken by the count of steps alone, the stair clip came in on the wrong foot as often as not:
	# both feet were off the ground for a moment. Yasin, 26 Nov: "first step is terrible, looks like switching
	# between many animations".)
	if not _stair_on:
		var lead := skel.get_bone_global_pose(_foot_i[0]).origin.z - skel.get_bone_global_pose(_foot_i[1]).origin.z
		var since_left := fposmod(cycle - _phase_offset(ACTS[input]) / a.length, 1.0)
		var clip_left := since_left < 0.25 or since_left > 0.75
		_stair_phase = cycle if clip_left == (lead > 0.0) else cycle + 0.5
	else:
		_stair_phase += wrapf(cycle - _stair_phase, -0.25, 0.25) * minf(dt * STAIR_PULL, 1.0)
	_stair_on = true
	_show(input, fposmod(_stair_phase, 1.0) * a.length)


## How far the left ankle is ahead of the right in the pose the tree has just made (metres).
func _lead_now() -> float:
	return skel.get_bone_global_pose(_foot_i[0]).origin.z - skel.get_bone_global_pose(_foot_i[1]).origin.z


## The moment a start or stop clip has covered `d` metres.
func _time_for(input: String, d: float) -> float:
	var table: PackedFloat32Array = _dist[input]
	for i in table.size():
		if table[i] >= d:
			return i / 60.0
	return (table.size() - 1) / 60.0


## Back to the loops, at the point of the stride his legs are at: the same foot forward, by the same amount, and
## going the same way (the study: "Which foot is forward at start and end | to chain clips without a stutter step").
## Until 26 Nov the loops were only set to the left or the right foot's furthest point, and a start clip handed over
## to a walk whose legs were somewhere else (Yasin: "walk start doesnt blend in well with walk animation").
func _to_loops() -> void:
	_sub = ""
	var speed := (body.get(&"hvel") as Vector3).length()
	var loop: PackedFloat32Array = _lib.get_animation(WALK if speed < SWITCH else JOG).get_meta(&"lead", PackedFloat32Array())
	var now := _lead_now()
	var at := 0.0 if now > 0.0 else 0.5
	if loop.size() > 2:
		var best := INF
		for i in loop.size() - 1:
			if (loop[i + 1] > loop[i]) != _lead_rising:
				continue
			var gap := absf(loop[i] - now)
			if gap < best:
				best = gap
				at = float(i) / float(loop.size() - 1)
	tree.set(&"parameters/gait_seek/seek_request", at)
	_show("ground", 0.0)


## The moment a turning clip has turned through `angle` (radians, by size).
func _time_for_yaw(input: String, angle: float) -> float:
	var table: PackedFloat32Array = _yaw[input]
	for i in table.size():
		if absf(table[i]) >= angle:
			return i / 60.0
	return (table.size() - 1) / 60.0


## A turn on the spot (or the plant-and-turn out of a run): the body turns; the clip that turns the same way is shown
## at the share of its own turn that the body has made of his. (The study: "Turn clips do not turn exact amounts ...
## The turn in each clip must be scaled to the angle the game needs".)
func _turn(dt: float, wish: float) -> void:
	var total := float(body.get(&"spot_total"))
	if total == 0.0:
		# the body has finished turning: what is left of the clip is let go, and he sets off (or stands)
		if _sub_in.begins_with("turn_180_run") or bool(body.get(&"spot_walk")):
			# out of the plant-and-turn he is running: the run loop, not the start from standing (Yasin, 26 Nov:
			# "dont play start running after 180 running turn, just continue the running animation")
			_moving = 1.0
		_to_loops()
		return
	var table: PackedFloat32Array = _yaw[_sub_in]
	var done := 1.0 - absf(float(body.get(&"spot_left"))) / maxf(absf(total), 0.001)
	# (never run on faster or slower than these shares of its own pace: a clip does not turn evenly, and followed
	# exactly it raced through its slow parts, and the head with it: 684 degrees a second in the audit)
	var want := _time_for_yaw(_sub_in, absf(table[table.size() - 1]) * clampf(done, 0.0, 1.0))
	_act_t = clampf(want, _act_t + dt * TURN_PACE[0], _act_t + dt * TURN_PACE[1])
	_seek()


## A change of gait, walk to run or run to walk: moved on by the ground the body covers, from the point of the clip
## that goes at his pace.
func _change(dt: float, speed: float, wish: float) -> void:
	var a := _lib.get_animation(ACTS[_sub_in])
	var to_run := _sub_in.begins_with("walk_to_run")
	_gone += speed * dt
	_act_t = maxf(_act_t, _time_for(_sub_in, _change_from + _gone))
	var over: bool = (speed > float(_fastest[_sub_in])) if to_run else (speed < SWITCH)
	var called_off: bool = wish < 0.05 or (to_run and wish <= SWITCH) or (not to_run and wish > RUN_FROM)
	if _act_t >= a.length - 0.1 or over or called_off:
		_to_loops()
	else:
		_seek()


## Take up a change-of-gait clip: where the clip itself goes at his pace, and of the clip and its mirror image the
## one with the same foot forward there as he has now.
func _begin_change(kind: String, speed: float) -> void:
	var table: PackedFloat32Array = _dist[kind]
	var lead_clip: PackedFloat32Array = _lib.get_animation(ACTS[kind]).get_meta(&"lead", PackedFloat32Array())
	# among the moments at which the clip goes at about his pace: the one, in the clip or its mirror image, at which
	# its legs are where his are and going the same way (so no foot comes down twice running)
	var now := _lead_now()
	var at := -1
	var mirror := false
	var best := INF
	for i in range(6, table.size() - 6, 2):
		var own := (table[i + 6] - table[i - 6]) / 0.2
		if own < speed * CHANGE_PACE[0] or own > speed * CHANGE_PACE[1]:
			continue
		var f := mini(int(i / 2.0), lead_clip.size() - 2)
		for m: bool in [false, true]:
			var here := -lead_clip[f] if m else lead_clip[f]
			var next := -lead_clip[f + 1] if m else lead_clip[f + 1]
			if (next > here) != _lead_rising:
				continue
			if absf(here - now) < best:
				best = absf(here - now)
				at = i
				mirror = m
	if at < 0:
		return      # the clip never goes at his pace: the loops carry the change, as before
	_sub = "change"
	_sub_in = kind + "_m" if mirror else kind
	_change_from = table[at]
	_gone = 0.0
	_show(_sub_in, at / 60.0)


## A start or a stop clip, moved on by the ground the body covers.
func _start_or_stop(dt: float, speed: float, wish: float) -> void:
	var a := _lib.get_animation(ACTS[_sub_in])
	var table: PackedFloat32Array = _dist[_sub_in]
	if _sub == "start":
		if wish < 0.05:
			_to_loops()         # let go again: the loops (and from them the standing pose) take over
			return
		_gone += speed * dt
		_act_t = maxf(_act_t, _time_for(_sub_in, _gone))
		var n := table.size()
		var end_speed := (table[n - 1] - table[maxi(n - 13, 0)]) / 0.2
		if _act_t >= a.length - 0.12 or speed > end_speed * START_OVER + START_OVER_MORE:
			_to_loops()
		else:
			_seek()
	else:
		if wish > 0.05:
			_to_loops()         # pressed again mid-stop: back into the stride on the foot he has forward
			return
		if speed > 0.05:
			if STOP_BY_POSE:
				var done := 1.0 - float(body.call(&"stop_distance")) / _stop_left
				_act_t = maxf(_act_t, lerpf(_stop_from, _time_for(_sub_in, table[table.size() - 1]), clampf(done, 0.0, 1.0)))
			else:
				_act_t = maxf(_act_t, _time_for(_sub_in, table[table.size() - 1] - float(body.call(&"stop_distance"))))
		else:
			_act_t += dt        # the body is at rest: the clip settles him over his feet
		if _act_t >= a.length - 0.02:
			_sub = ""
			_show("ground", 0.0)
		else:
			_seek()


## Coming to rest on the steep ground: the stop of his take runs to its end as he covers what he has left.
func _slope_stop(dt: float, speed: float) -> void:
	var table: PackedFloat32Array = _dist[_slope_in]
	if speed > 0.05:
		_act_t = maxf(_act_t, _time_for(_slope_in, table[table.size() - 1] - float(body.call(&"stop_distance"))))
	else:
		_act_t += dt
	if _act_t >= _clip_length(_slope_in) - 0.02:
		_slope_sub = ""
		_steep_on = false
		_show("ground", 0.0)
	else:
		_seek()


## Is the ground one walking step ahead of him still very steep? (A ray down, where that step would land.)
func _steep_ahead() -> bool:
	var v: Vector3 = body.get(&"hvel")
	if v.length() < 0.05:
		return true
	var here := deg_to_rad(float(body.get(&"slope_deg")))
	var at := body.global_position + v.normalized() * (STEEP_STEP * cos(here))
	var q := PhysicsRayQueryParameters3D.create(at + Vector3(0.0, 1.5, 0.0), at - Vector3(0.0, 1.5, 0.0), body.collision_mask, [body.get_rid()])
	var hit := body.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return false
	return rad_to_deg(acos(clampf((hit["normal"] as Vector3).y, -1.0, 1.0))) > float(body.get(&"SLOPE_HANDS_DEG"))


## On steep ground: his take for the way he is going, moved on by the ground he covers (the body sets the pace).
func _steep(dt: float, speed: float) -> void:
	var grade := float(body.get(&"grade"))
	if not _steep_on:
		_steep_up = grade >= 0.0
	elif absf(grade) > STEEP_TURN:
		_steep_up = grade > 0.0
	# from standing, going down: the take's own start, by the ground he covers; then its loop from its beginning,
	# which is where the start leaves off
	if not _steep_on and speed < 0.4:
		_slope_sub = "start"
		_slope_in = "steep_up_start" if _steep_up else "steep_down_start"
		_gone = 0.0
		_steep_on = true
		_show(_slope_in, 0.0)
		return
	if _slope_sub == "start":
		if _steep_up != (_slope_in == "steep_up_start"):
			_slope_sub = ""
		else:
			_gone += speed * dt
			_act_t = maxf(_act_t, _time_for(_slope_in, _gone))
			if _act_t >= _clip_length(_slope_in) - 0.05:
				_slope_sub = ""
				_steep_phase = 0.0
			else:
				_seek()
				return
	_slope_sub = ""
	var input := "steep_up" if _steep_up else "steep_down"
	var a := _lib.get_animation(ACTS[input])
	_steep_phase = fposmod(_steep_phase + speed * dt / maxf(float(_stride[ACTS[input]]), 0.1), 1.0)
	_steep_on = true
	_show(input, _steep_phase * a.length)


## Standing and the gait loops: which blend, and at what pace, so that the feet cover the ground at the body's speed.
func _ground(dt: float, speed: float) -> void:
	var want := 1.0 if speed > 0.15 else 0.0
	_moving = move_toward(_moving, want, dt / FADE)
	tree.set(&"parameters/ground/blend_amount", _moving)
	# the crouched set: the same, with the crouch walk paced by its own stride
	var low := bool(body.get(&"crouched"))
	if _sub != "crouch":
		_low_w = move_toward(_low_w, 1.0 if low else 0.0, dt / CROUCH_FADE)
	tree.set(&"parameters/stance/blend_amount", _low_w)
	tree.set(&"parameters/crouch_ground/blend_amount", _moving)
	tree.set(&"parameters/crouch_speed/scale", clampf(maxf(speed, 0.3) / (float(_stride[CROUCH_WALK]) / float(_length[CROUCH_WALK])), SCALE_LEAST, SCALE_MOST))
	var g := _gait_for(maxf(speed, 0.3))
	tree.set(&"parameters/gait/blend_position", g.x)
	_natural = g.y
	# "playback matched to body speed from the measured clip speeds": the pace the blend would walk at by itself is
	# known from the clips' own root travel, and is checked against the tree's root motion as it plays (see _measure)
	# (while the walk's stride is being lengthened the root's own travel is short of the ground covered by design)
	var natural := _measured if (_measured > 0.0 and g.x > 0.0) else _natural
	_scale = clampf(maxf(speed, 0.3) / maxf(natural, 0.05), SCALE_LEAST, SCALE_MOST)
	# (the tree's own scale is in strides a second: the pace over the blend's own stride time)
	var own_time: float = lerpf(_length[WALK], _length[JOG], g.x) if g.x <= 1.0 else lerpf(_length[JOG], _length[RUN], g.x - 1.0)
	tree.set(&"parameters/gait_speed/scale", _scale / own_time)


## Where on the gait blend (0 = walk, 1 = jog, 2 = run) the body's speed belongs, and the speed that blend covers
## the ground at when played at its own pace (stride over cycle time, both blended by the same weights).
func _gait_for(v: float) -> Vector2:
	var lo := SWITCH - SWITCH_BAND
	var hi := SWITCH + SWITCH_BAND
	if v <= lo:
		return Vector2(0.0, WALK_STRIDE / float(_length[WALK]))
	if v < hi:
		var w := (v - lo) / (hi - lo)
		return Vector2(w, lerpf(_stride[WALK], _stride[JOG], w) / lerpf(_length[WALK], _length[JOG], w))
	var jog := float(_stride[JOG]) / float(_length[JOG])
	if v <= jog:
		return Vector2(1.0, jog)
	# between the jog and the run: the blend whose own pace is exactly this speed
	var ds := float(_stride[RUN]) - float(_stride[JOG])
	var dl := float(_length[RUN]) - float(_length[JOG])
	var w2 := clampf((v * float(_length[JOG]) - float(_stride[JOG])) / maxf(ds - v * dl, 0.001), 0.0, 1.0)
	return Vector2(1.0 + w2, lerpf(_stride[JOG], _stride[RUN], w2) / lerpf(_length[JOG], _length[RUN], w2))


## The study: the clips' "root travel is cancelled by Godot and used only as a measurement". What the tree's root
## really covered last tick, at the pace it was played, is the blend's own speed; used while nothing else is blended in.
func _measure(dt: float) -> void:
	var covered := tree.get_root_motion_position().length()
	if _act == "ground" and _settled > FADE + 0.05 and _moving >= 1.0 and _scale > 0.0 and covered > 0.0001 and _low_w <= 0.0:
		var seen := covered / (dt * _scale)
		# (taken only when it agrees with the clips' own figures to within a fifth: a blend in progress reads low)
		_measured = seen if absf(seen - _natural) < 0.2 * _natural else 0.0
	else:
		_measured = 0.0


## Lean the whole figure about the feet into the turn the body is making: tan(lean) = speed x turn rate / g. The
## study's figures are the whole lean of a walker against how he walks straight, so what is held to them is the lean
## added here plus where the stride itself has the chest at that moment (against where it has it on average).
func _lean(dt: float, on_ground: bool) -> void:
	var v: Vector3 = body.get(&"hvel")
	var speed := v.length()
	var raw := 0.0
	var most := deg_to_rad(_lean_most(float(body.get(&"_wish").length())))
	# where the stride has the chest over the feet just now (+ = to his left; the model faces the other way round
	# under the body, so its +x is his left), and its average over about a stride
	var chest := skel.get_bone_global_pose(_chest_i).origin
	var own := atan2(chest.x, chest.y)
	if on_ground and speed > 0.5:
		_own_mean += (own - _own_mean) * (1.0 - exp(-dt / 1.0))
		var dir := v / speed
		if _last_dir != Vector3.ZERO:
			var rate := atan2(_last_dir.cross(dir).y, _last_dir.dot(dir)) / dt      # + = turning to his left
			raw = clampf(atan(speed * rate / 9.8), -most - LEAN_OVER, most + LEAN_OVER)
		_last_dir = dir
	else:
		_last_dir = Vector3.ZERO
		_own_mean = own
	_lean_s += (raw - _lean_s) * (1.0 - exp(-dt / LEAN_TIME))
	var dev := own - _own_mean
	lean = clampf(_lean_s, -most - dev, most - dev) if absf(_lean_s) > absf(dev) else _lean_s
	_pivot.rotation.z = lean


## The most he leans, by the pace he is keeping (the pace asked for: a corner is taken at the gait he is in, though
## he gives up speed in it): slow, normal and fast walking, and running.
func _lean_most(pace: float) -> float:
	var walk := float(body.get(&"WALK"))
	if pace <= walk:
		return lerpf(LEAN_SLOW_DEG, LEAN_WALK_DEG, clampf((pace - 0.8 * walk) / (0.2 * walk), 0.0, 1.0))
	if pace <= SWITCH:
		return lerpf(LEAN_WALK_DEG, LEAN_FAST_DEG, (pace - walk) / (SWITCH - walk))
	return LEAN_RUN_DEG
