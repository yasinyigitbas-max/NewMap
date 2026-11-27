extends Node
## Stage 8 onward: the traversal moves. The study: "Each move is built the same way (align, play, fit, hand IK, hand
## back)", and "In a traversal move the roles swap for the length of that move: the clip's root travel, stretched to
## fit the measured obstacle, drives the body, with gravity and normal collision off."
##
## BUILT: Stage 8, stepping off an edge at a walk, for drops of more than 0.30 m and up to 1.0 m (the study, going
## down: "up to 0.30 m, step down in stride; 0.30 to 1.0 m, step or hop off with a soft landing"). Lower edges are
## stepped down in stride by the body as before (Yasin, 26 Nov: "stepping down off a kerb doesnt look that bad now,
## work on bigger edges like knee height and above"). Higher ones are refused here: he falls as before, until the
## hang-and-drop of stage 15.
## At a run the same, with the Kimodo take of a man running off a ledge and running on (Yasin, 26 Nov: "only walking
## off an edge works well, running off doesnt").
## NOT BUILT: the study's "plant the last foot about 14 cm back from the edge" for kerbs.

const Detector := preload("res://traversal/detect/detector.gd")
const ClipData := preload("res://traversal/character/clip_data.gd")    # (nothing under tools/ is in the exported game)
const BAND := [0.30, 1.0]       # the study's band for this move: more than the first, up to the second (m)
# The clip: a Kimodo take of a man stepping off a ledge (the study's Part 3 has no Mixamo clip that steps off and
# lands standing in under 3 s). Measured on the take's own hip path: he begins the step at 1.45 s, his feet leave at
# 2.10 s, he is down at 2.52 s and standing again by 3.30 s; the ledge it steps off is 1.15 m high.
const MOVES := {
	"walk": {"input": "drop_walk", "res": "res://traversal/character/clips/KM_Ledge_Walk_Off.res",
		"from": 1.75, "leaves": 2.10, "down": 2.52, "exit": 3.30, "native": 1.15,
		"edge": 0.46},          # NOT in the study: where the take's edge is taken to be, along its own path (m):
                                # 5 cm behind his hips at the moment his feet leave (the take has no real ledge)
	# The run-off take, measured the same way: he is running by 1.70 s, his feet leave at 1.95 s, he is down at
	# 2.72 s and running on, upright again, by 3.70 s; its ledge is 1.76 m high.
	"run": {"input": "drop_run", "res": "res://traversal/character/clips/KM_Ledge_Run_Off.res",
		"from": 1.70, "leaves": 1.95, "down": 2.72, "exit": 3.70, "native": 1.76,
		"edge": 0.95},
	# Off a higher edge at a run: he lands, rolls forward and comes up running (Yasin, 26 Nov: "we need a hard landing
	# exit animation I think, or roll off after hard landing and continue running"). The study: "From 0.75 m a roll
	# cut the peak from 5.2 to 2.9 body weights", and for going down, "a roll for a running jump". No roll was in
	# the library (the study's "falling to roll" is in a Mixamo pack that was never downloaded for him); this is a
	# Kimodo take of 26 Nov, the one of seven that rolls: off a 1.19 m ledge, feet leave at 1.20 s, down at 1.57 s,
	# over his shoulder and up again by 2.93 s, 3.6 m further on.
	"roll": {"input": "drop_roll", "res": "res://traversal/character/clips/KM_Land_Roll.res",
		"from": 1.12, "leaves": 1.20, "down": 1.57, "exit": 2.93, "native": 1.19,
		"edge": 0.96, "landing": "heavy",
		"free": [1.68, 2.60]}}  # between these moments of the take he is rolling: the feet are not fitted to the ground
# Stage 9, the high step up (the study: "0.30 to 0.50 m | deliberate high step"). No clip for it was in the library
# (the study: "0.30 to 0.50 m, high step | none | **missing**"; Mixamo's nearest steps onto 0.59 m). A Kimodo take of
# 26 Nov, the one of six that is a single step from standing: onto 0.61 m, the right foot up from 0.40 s and on top at
# 0.83 s, the left foot following from 0.80 s and beside it at 1.77 s.
const CLIMBS := {
	"step_up": {"input": "step_up", "res": "res://traversal/character/clips/KM_Step_Up.res",
		"from": 0.30, "from_moving": 0.45, "exit": 1.95, "mirrored": true, "wants_left": false,
		"edge": 0.25},          # NOT in the study: where the take's edge is taken to be (m ahead of where his hips
                                # start): a foot's length in front of his toes, and behind the heel that lands on top
	# Stage 11, climbing onto something deep of 0.50 to 1.10 m (the study: "0.50 to 1.10 m, climb on | Jumping (2) at
	# 0.62 m, Running Jump Climb at 1.00 m | covered at both ends of the band, as jumps"). Two rows, each with its
	# own heights ("Each row has a minimum and maximum height"), from his own Mixamo clips, measured on him:
	# Step Onto Platform: onto 0.61 m; the left foot stays down 0.23 m along, the right foot is up from 0.27 s and on
	# top (1.03 m along) by 0.60 s, the left follows and is down on top at 1.20 s. No hands.
	"step_on": {"input": "step_on", "res": "res://traversal/character/clips/Step_Onto_Platform.res",
		"from": 0.0, "from_moving": 0.13, "exit": 1.33, "mirrored": true, "wants_left": true,
		"edge": 0.60},          # NOT in the study: between the toes of the foot left below (0.43 m) and the heel of
                                # the foot that lands on top (0.96 m), nearer the first
	# Running Jump Climb: onto 1.00 m; a run in, off the left foot 1.63 m along at 0.5 s, the right foot on top
	# (2.13 m along) at 0.67 s, both by 0.93 s, standing up by 1.5 s. No hands.
	"jump_on": {"input": "jump_on", "res": "res://traversal/character/clips/Running_Jump_Climb.res",
		"from": 0.27, "from_moving": 0.27, "from_run": 0.0, "exit": 1.60, "mirrored": true, "wants_left": false,
		"edge": 1.95}}          # NOT in the study: between the toes of the take-off foot (1.84 m) and the heel
                                # that lands on top (2.06 m)
const ON_BAND := [0.50, 1.10]   # the study's band for climbing on: more than the first, up to the second (m)
const STEP_ON_MOST := 0.80      # NOT in the study: up to here the step onto it (made for 0.61 m), above it the jump
                                # onto it (made for 1.00 m): each clip is then stretched by no more than a third
const UP_BAND := [0.30, 0.50]   # the study's band for the high step: more than the first, up to the second (m)
const EARLY := 0.2              # NOT in the study: on the move the step up is begun this many seconds of travel before the
                                # take's own distance from the step
# At a run the same step is taken in stride, with a leap (Yasin, 26 Nov: "there should be one for running too ...
# the running one needs to be smoother, preserving our momentum as much as possible"). Six Kimodo takes ordered for
# it did not do it (they climb stairs, or leap along the flat), so it is the Running Jump clip he already has, "one
# run stride with a leap ... in it" (the study, Part 3): the body goes on at the speed he came in at, over an arc
# that clears the edge and comes down on top, and he runs on. Leaves the ground at 0.10 s of the clip, down at 0.67 s.
const RUN_UP := {"input": "run_jump", "off": 0.10, "land": 0.67, "exit": 0.90}
const RUN_UP_AIR := 0.40        # NOT in the study: seconds in the air of the leap onto the step
const RUN_UP_FACE := 0.75       # NOT in the study: the share of the leap at which he crosses the edge
const RUN_UP_ARC := 0.25        # NOT in the study: how far the arc rises over a straight line to the top (m); at the
                                # edge he is then 3 cm or more over a 0.50 m step
# Stage 10, the vault over a thin obstacle from a run (the study: "0.50 to 1.10 m | vault if thin ... one-hand vault at
# a run"; "The speed vault is one hand down, take-off from one leg, legs kicked sideways over with no foot touching,
# landing in stride"). The clip is Mixamo's Vault 1 Hand, downloaded for him. Measured on him (tests/zz_meas, 26 Nov):
# the left foot takes off at 0.33 s, 1.3 m before the obstacle; the left wrist is on it from 0.45 to 0.72 s, at
# 0.94 m (so an obstacle about 0.88 m high, a palm lower) and 2.20 to 2.41 m along the clip's path, 0.25 m to his left
# (the obstacle is taken to be at 2.36 m: at 2.30 m his leading toe met its near face 15 cm under the top); the
# left foot comes down at 0.90 s, 1.5 m beyond it; it runs at 4.3 m/s; his hips peak at 1.32 m and leave the ground
# at 1.12 m.
const VAULT := {"input": "vault", "res": "res://traversal/character/clips/Vault_1_Hand.res",
		"from": 0.20, "off": 0.33, "hand_on": 0.47, "hand_off": 0.65, "down": 0.90, "exit": 1.13,
		"at": 2.36, "high": 0.88, "hand_side": 0.25, "speed": 4.3, "hips_off": 1.12, "hips_top": 1.32}
# The band. The study's table has the vault from 0.50 to 1.10 m and a mantle from there to 1.45 m; its sources have
# "shoulder height (1.44 m) is the vault limit". Yasin, 26 Nov: "i think we should be able vault over walls up to 1.4
# meter and then the climb over or mantles should start". So a THIN obstacle is vaulted up to 1.40 m; something DEEP
# is still climbed onto only up to 1.10 m, and from there up it is the mantle (stage 12, not built).
const VAULT_BAND := [0.50, 1.40]
const VAULT_PACE := [0.75, 1.1]     # NOT in the study: the clip is played at between these shares of its own pace, to go at his
const LIFT_EARLY := 0.07            # NOT in the study: the body's rise to a higher obstacle (or fall to a lower) is made over
                                    # this long each side of his take-off (s); made later, his leading foot met a higher wall
const CLEAR_MORE := 0.06            # NOT in the study: see _vault
# Stage 11, a thin obstacle from standing or at a walk. The study has a step vault here; no clip of one exists (his
# Step Up Vault, measured, is not one; a dozen Kimodo takes asked for one in several wordings do not go over
# anything). What there is, at Yasin's word of 26 Nov: two Kimodo takes in his own words and seed, made again on his
# character. "this new vault looks very bad. hands dont make any contact with the wall at all. use this [the jump] for
# short walls when standing still to jump on the other side. use that one you have for walls above 1m and make sure
# hand makes contact."
# For walls up to 1.0 m: "jump over obstacle when standing still". Measured on him: he sinks (hips 0.71 m at 0.67 s),
# leaves the ground at 0.87 s, tucks (ankles 1.03 to 1.13 m at 1.07 to 1.20 s), is down at 1.55 s and standing by
# 2.3 s. It jumps almost on the spot (0.3 m), so the body carries him across the obstacle while he is in the air.
const JUMP := {"input": "vault_jump", "res": "res://traversal/character/clips/KM_Jump_Over.res",
		"from": 0.30, "off": 0.87, "top": 1.15, "down": 1.55, "exit": 2.30,
		"high": 0.65}               # NOT in the study: the height its tucked feet clear as it is (found in the lab)
# NOT USED NOW (Yasin, 26 Nov, of this take over a 1.10 m wall: "they do at the very start, but then the character
# just levitates"): kept until a take with the hands truly on the top exists. It was:
# For walls over 1.0 m: "vaulting over a wall. landing on the other side". Measured on him: at 0.67 s, sunk, both
# wrists are forward and down at 0.90 m, 0.35 to 0.41 m along (where the obstacle's near edge is taken to be); he
# leaves the ground at 0.85 s, legs tucked (ankles 0.86 to 1.07 m where they cross), down at 1.65 s 0.84 m along,
# standing by 2.4 s. Both hands are held on the measured top from as they come forward until he has left the ground.
const TUCK := {"input": "vault_tuck", "res": "res://traversal/character/clips/KM_Vault_Stand.res",
		"from": 0.30, "off": 0.85, "top": 1.25, "down": 1.65, "exit": 2.40,
		"hands_on": 0.60, "hands_off": 0.84, "hand_side": 0.24,     # (held until he leaves the ground: carried up
                                    # after that, the top of a 1.10 m wall was 16 cm beyond the reach of his wrists)
		"at": 0.47,                 # NOT in the study: where the take's obstacle is taken to be (m along)
		"high": 0.50}               # NOT in the study: the height the take clears as it is (found in the lab)
const JUMP_MOST := 1.0              # his word: the jump "for short walls", the vault with the hands "for walls above 1m"
const VAULT_SLOW := 0.6             # NOT in the study: the pace of the one-hand vault at a walk (over 1.0 m)
const BEYOND := 0.45                # NOT in the study: how far past the middle of the obstacle the jump sets him down (m):
                                    # his own radius, half a thin wall, and a hand's breadth
# A thin wall over 1.0 m from standing against it: no vault from standing with the hands on the top exists (44 more
# Kimodo takes in other verbs and objects, and the Drive clips, measured 26 Nov: none). Yasin, 26 Nov: "if nothing
# else works, then use a vault over vault (which results in climbing over a thick object and then a jump down animation
# in succession smoothly". So: the climb up onto it, both hands on its top, then the step off its far side with the
# landing of stage 8, as one move. The climb is a Kimodo take in his words ("vaulting over a wall. landing on the
# other side", seed 1), measured on him: a short run in, off the ground at about 0.9 s with both wrists forward at
# the height of the top, feet on top and nearly upright by 2.3 s, standing by 2.6 s, 1.30 m up. It is taken up at
# 0.85 s, as he pushes off: its run in is not played (begun earlier, standing at the wall, its stride was in the wall).
const OVER := {"input": "climb_up", "res": "res://traversal/character/clips/KM_Climb_Up.res",
		"from": 0.85, "hands_on": 0.85, "hands_off": 1.45, "top": 2.30, "hand_side": 0.24}
# (hands_off: as his feet come down on the top. Yasin, 26 Nov: "hands are still very far off the wall once the
# character gets raised, lift them off the wall once legs touch down". His arms are too short to keep them there
# while he rises upright, so the trunk bends over them: hand_place.gd, within the study's "Lower back | 65 forward".)
# Stage 12, the mantle (the study: "1.10 to 1.45 m | two-hand mantle with a small jump"; "Mantle (1.10 to 1.45 m):
# stretch `Running Jump Climb` upward, or jump to a braced hang and climb, and judge by eye"; its own Kimodo mantles
# "had no real ledge ... Pin them with arm IK"). The take is the climb of the climb over (KM_Climb_Up, onto 1.30 m,
# inside the band), played to its end: standing on top at 2.90 s.
const MANTLE_BAND := [1.10, 1.45]   # the study's band: more than the first, up to the second (m)
const MANTLE := {"exit": 2.90,
		"edge": 2.38,               # NOT in the study, found in the lab: where the take's edge is taken to be (m along); nearer,
                                    # his knees were in the wall as he came up
		"across": [1.38, 1.90]}     # NOT in the study, found in the lab: he is carried in over the top between these moments
# The feet in the climb take (Yasin, 26 Nov: "during jump climbs foot doesnt meet the floor"): off the ground and
# until the first foot comes over the top they are the take's own; from then they are fitted to the real surface,
# measured against the TOP (the take's own ground then), not against the body on its way up: against the body, a
# foot passing over the edge was lifted by the height still to climb, and stood 0.3 m in the air.
const FEET_FROM := 1.40             # NOT in the study, measured in the lab: the first foot comes over the top then (s of the take)
# Stage 13, the grab and climb (the study: "1.45 to 2.10 m | reach up, grab the top, climb up | standing grip reach
# 2.11 m; police wall 1.83 m"; "1.45 to 2.10 m, grab and climb | Braced Hang To Crouch | the climb-up exists; the
# clip from standing into the braced hang is on Mixamo"; "the hands must be pinned to the measured ledge with arm IK
# from contact to release, and the body moved to suit"). Two of his own Mixamo clips, measured on him:
# Jump To Braced Hang: sunk at 0.3 s, off the ground at 0.45 s, both wrists at 2.14 m by 0.70 s and staying there,
# feet braced on the wall (ankles 1.0 m) by 0.9 s, hips 0.31 m from the face.
# Braced Hang To Crouch: from that hang (wrists 1.43 m over ITS origin, hips 0.64 m) up to a crouch on top, feet
# down on it at 1.72 m by 0.85 s. Its wrists rise 0.7 m while they should be planted (the study: "The hands are not
# fixed in the climb clips ... the start of each clip and its end disagree about where the ledge is"), so the body is
# set by the hands at its start and by the feet at its end, and the hands are held on the top.
const GRAB_BAND := [1.45, 2.10]     # the study's band: more than the first, up to the second (m)
# Stage 14 (the study: "2.10 to 2.60 m | jump, grab, climb up | average standing jump adds 0.41 to 0.50 m"). The clips
# the study names for it (Stand To Freehang, Freehang Climb) were measured on him, 26 Nov: they hang FREE, the legs
# swinging 0.3 to 1.0 m past the plane of the hands, through where a wall stands. They fit a ledge with nothing
# under it; on a solid wall his legs would be in it. So on walls this band is the grab and climb above, whose
# first clip is itself a jump to the hang, carried as much higher as the top is. Begun from a jump of his own it
# reaches as much higher again as that jump raises him, up to 3.0 m (Yasin, 26 Nov: "fix it until 3m").
const HIGH_BAND := [2.10, 2.60]
const NOT_ABOVE := 3.0              # the study: "above 3.0 m | not climbable"
const GRAB := {"jump": "grab_jump", "jump_res": "res://traversal/character/clips/Jump_To_Braced_Hang.res",
		"climb": "grab_climb", "climb_res": "res://traversal/character/clips/Braced_Hang_To_Crouch.res",
		"off": 0.45, "catch": 0.70, "hang": 1.00,        # of the jump: off the ground, hands on, hanging
		"wrist": 2.14,              # of the jump: how high its wrists are in the hang
		"jump_by": 0.70,            # the rise taken out of the jump's hips in the library (build_library.gd RISE_BY)
		"climb_wrist": 1.43,        # of the climb: its wrists as it begins
		"climb_by": 1.63,           # of the climb, found in the lab: where his feet end (its own ledge), and the rise taken out of it
		"feet_on": 0.85, "exit": 1.10,
		"hang_at": 0.54,            # NOT in the study, found in the lab: how far from the face his hips hang (m): his toes on it
		"hand_side": 0.33}
# The hands in the grab and climb lie flat on the top, fingers forward, the wrist at its edge, from the catch until his
# feet come down (Yasin, 26 Nov: "check the climbs hand placements for high climb, it looks a few cms off").
const WRIST_OVER := 0.04            # NOT in the study, mine: how high the wrist joint of a hand lying flat is over the surface (m)
const WRIST_IN := 0.02              # NOT in the study, mine: how far in from the edge it is (m)
# In the hang only his fingers are over the edge, the wrist is outside the face (the clip has his toes on the wall
# 16 cm further forward than his wrists: with the wrists over the edge his toes were in the wall, or his arms 10 cm
# short); on the way up the hands come in onto the top (the study: "a turn of the hands from pulling to pressing as
# the chest clears the edge").
const GRIP_OUT := 0.10              # NOT in the study, mine: how far out from the face the wrist is in the hang (m)
const GRIP_TURN := [0.10, 0.40]     # NOT in the study, mine: the hands come in onto the top between these moments of the climb
const STAND_UP := [0.10, 1.30]      # NOT in the study, mine: the part of the crouch-to-stand take played after the grab and climb (s)
const STAND_UP_TIME := 0.60         # NOT in the study, mine: ... in this long (twice the take's own pace)
const GRAB_NEAR := 0.60             # NOT in the study: it is begun from within this of the wall's face (m)
# At a run the climbs do not end standing: he is handed back running, at the pace he came in at (Yasin, 26 Nov: "do
# the running alternatives too ... most of the players will run from start to end in the game"; the study has
# Rockstar's climbs end in "a shared pose on top of the ledge that branches to stand, walk, run"). The take is left
# as his feet are down on the top, and over the last part of it the body is brought up to that pace.
const RUN_OUT := {"mantle": [2.00, 2.50],       # NOT in the study, mine: of the mantle's take: he gathers pace from, and is handed back at (s)
		"grab": [0.85, 1.10]}                   # ... and of the climb from the hang
# The running wall climb (the study: "2.60 to 3.00 m | running wall-run only"; "Sprint To Wall Climb | 2.46 m | 2 m
# run-up, hands hit the top at 0.67 s, on top by 1.6 s"; for 2.10 to 2.60 m "covered, from a stand and from a run";
# Yasin, 26 Nov: "do the running alternatives too"). His own Mixamo clip, measured on him: he runs in at 4.7 m/s,
# plants his left foot 1.42 m from the face at 0.3 s, puts his right foot on the wall 1.0 m up at 0.45 s, both hands
# on the top (2.41 m) at 0.65 s, feet over it from 1.3 s, crouched on top (2.40 m) by 1.5 s.
const WALLRUN_BAND := [2.10, 3.00]  # the study's two bands for it together: more than the first, up to the second (m)
const WALLRUN := {"input": "wallrun", "res": "res://traversal/character/clips/Sprint_To_Wall_Climb.res",
		"from_most": 0.38,          # taken up no later than this: his left foot is planted for the kick then
		"face": 3.20,               # where the take's wall face is (m along): his toe on it (found in the lab)
		"kick": 0.40, "hands_on": 0.65, "hands_off": 1.30, "exit": 1.80,
		"high": 2.40,               # the take's own wall, and the rise taken out of it in the library (RISE_BY)
		"hand_side": 0.30, "grip_out": 0.15, "grip_turn": [0.95, 1.30],
		"run_out": [1.45, 1.80]}    # NOT in the study, mine: he gathers pace over this part of it, to be handed back running
# Stage 15, turn, hang and drop (the study: "1.0 to 2.0 m, a heavy landing or a turn, hang and drop; 2.0 to 3.0 m,
# hang and drop preferred"; "The standard way to shorten a drop is to turn, hang from the edge and let go";
# "`Climbing Down` is the closest, from 1.55 m"). His own Mixamo clip Climbing Down, measured on him: he kneels at
# the edge with the drop on his LEFT, both hands on the ledge, turns to his right as his legs go out over the edge
# (0.7 to 1.2 s), lowers himself with the hands still on it (to 1.45 s), is down at 1.75 s, 1.52 m lower and 0.31 m
# out from the face, and has stood up, facing the wall, by 2.6 s. Asked for by going at an edge CROUCHED, with a
# drop of more than 1.0 m, up to 3.0 m. Upright, at a walk or a run, the edge is taken as before (the fall, the roll).
const DOWN_BAND := [1.0, 3.0]       # the study's: more than the first, up to the second (m)
const DOWN := {"input": "climb_down", "res": "res://traversal/character/clips/Climbing_Down.res",
		"high": 1.52,               # the ledge the take comes down from, found in the lab (and build_library.gd DROP_BY)
		"face": 0.10,               # NOT in the study, found in the lab: where the take's wall face is, to his left of where he kneels (m)
		"lower_from": 1.20,         # he begins to lower himself then (and build_library.gd DROP_FROM)
		"hands_on": 0.20, "hands_off": 1.45, "down": 1.75, "exit": 2.70,
		# where the take has his wrists while they are on the ledge: [to his left, up over the ledge, forward] (m)
		"hand_l": [0.17, 0.12, 0.65], "hand_r": [-0.13, 0.15, 0.23]}
const HANG_FEET := 1.03             # the study: "Falling To Landing | 1.07 s | 1.03 m": the fall that take is made for; his feet
                                    # are taken to hang that far under the ledge as he lets go
# the two landings after he lets go (the study: "Falling To Landing ... feet touch at 0.27 s, standing by 0.9 s";
# "Hard Landing | 2.50 s | 2.08 m | feet touch at 0.6 s, hands on the ground, standing at 2.5 s")
const LAND_SOFT := {"input": "land_soft", "touch": 0.27, "exit": 1.00, "kind": "soft"}
const LAND_HARD := {"input": "land_heavy", "touch": 0.60, "exit": 2.40, "kind": "heavy"}
const DOWN_OUT := 0.55              # NOT in the study, found in the lab: how far from the face he comes down (m)
const DOWN_NEAR := 0.45             # NOT in the study, mine: begun from within this of the edge (m)
# Stage 16, across a gap (the study: "People step across a gap up to about 0.94 of leg length and jump beyond that";
# "An average standing long jump is about 2.2 to 2.3 m for men"; the stage: "jump across a gap, with landing and roll
# by height | gaps over about 0.9 m"). Yasin, 26 Nov: "for moving across gaps, if we are running, just use running
# jump and continue jump after landing, implement new jumps only for walking across gaps".
# At a run: the body's own running jump is begun for him at the edge, if its flight clears the gap; he lands and runs
# on as after any jump (and rolls by the height, as from any jump). At a walk or from standing: up to 0.94 of his
# leg he steps across in stride; wider, up to the standing long jump, he jumps it with his own jump take (the one
# used over low walls: it jumps almost on the spot, so the body carries him across while he is in the air).
const LEG := 0.829                  # the study, Part 3: his hip to ankle on the Mixamo rig
const STEP_ACROSS := 0.94           # the study: of leg length
const LONG_JUMP := 2.2              # the study: the standing long jump (m)
const GAP_LOOK := 5.0               # NOT in the study, mine: a far side is looked for this far across (m): further than he can jump for
const CATCH_REACH := 0.60           # NOT in the study, mine: at a walk, how much wider than the long jump a gap may be for him to
                                    # reach its far edge with his hands (m)
const CATCH_UNDER := 0.50           # NOT in the study, mine: how far under the far top his feet are as he gets to it (m)
const GAP_DEEP_LEAST := 0.05        # NOT in the study, mine: ground this much lower ahead is looked at as a possible gap (m)
const GAP_LEAST := 0.30             # NOT in the study, mine: narrower than this is no gap: he walks it (m)
const GAP_UP := 0.30                # NOT in the study, mine: at a walk he jumps onto a far side up to this much higher (the jump take
                                    # clears 0.65 m as it is) ...
const GAP_DOWN := 0.50              # ... or this much lower
const GAP_OFF := 0.20               # NOT in the study, mine: he leaves the ground this far before the edge (m)
const GAP_ON := 0.15                # NOT in the study, mine: ... and comes down this far past the far edge, plus his own radius
# Losing his balance on something narrow (Yasin, 26 Nov: "we should fall off losing balance if we dont move more
# than 10 seconds on the beam", "we should fall onto our back or face down and get up later after a balance loss").
# Two of his own Mixamo clips, measured on him. Falling From Losing Balance: he wobbles on the spot to 4.2 s, then
# goes over forward, is down at 5.4 s and lies face down by 6.0 s, 3.4 m on, off a 1.13 m ledge. Push Up To Idle
# (the study: "Push Up To Idle 3.1 s from face down"): from lying face down, the same way round, to standing.
# He is turned to the side that has room for him first, since he goes over forward.
const BALANCE_AFTER := 10.0         # his word: seconds without moving
const HARD_FALL_FROM := 3.1         # his word: from lower than this he lands hard on his feet; from this height, the fall
const BALANCE_OUT := 0.70           # NOT in the study, mine: how far to the side he comes down on his feet (m)
const BALANCE := {"input": "balance_fall", "res": "res://traversal/character/clips/Falling_From_Losing_Balance.res",
		"from": 2.60,               # NOT in the study, mine: taken up here: 1.6 s of wobbling, then the fall
		"over": 4.20, "end": 6.60, "high": 1.13,
		"lie": 1.5,                 # NOT in the study, mine: he lies this long before he gets up (s)
		"up": "get_up_front", "up_len": 3.05}
const OVER_BACK := 0.48             # NOT in the study, found in the lab: he sinks for the jump this far from the wall's face
                                    # (nearer, his knees were in the wall). The study: "slide and turn the body over a
                                    # short fixed time so it starts at the clip's native distance from the wall"
const OVER_ACROSS := [1.30, 1.85]   # NOT in the study, found in the lab: between these moments of the take he is carried
                                    # in over the top: not before his knees and feet are above it
const OVER_NEAR := 0.45             # NOT in the study: it is begun from within this of the wall's face (m)
const PALM := 0.08                  # the study, Part 3: "the gripping palm is about 0.08 m further along" than the wrist
const HAND_FADE := 0.12             # NOT in the study: seconds over which the hand's hold comes in and goes out
const LAND_LEVEL := 0.10            # NOT in the study: the ground beyond is taken as level with his if within this (m)
const UP_LOOK_RUN := 1.6        # NOT in the study: at a run it is looked for this far ahead (m)
const UP_LOOK := 0.9            # NOT in the study: how far ahead something to step onto is looked for (m)
const RUN_ON_MOST := 1.0        # running off an edge up to this high he runs on with no landing clip: all the way to where
                                # the roll begins (Yasin, 26 Nov: "deep walls above .55 still play those timid steps when
                                # we run off them ... make the character just continue to run until that threshold").
                                # Until then it was 0.50 m, with the run-off clip from there to 1.0 m.
const ROLL_JUMP_MORE := 0.7     # a jump off an edge falls from the top of the jump: the body's own running jump rises
                                # 0.60 m (body.gd, JUMP_RISE_RUN), so that much more fall is still rolled out of
const ROLL_MOST := 3.0          # the study: "2.0 to 3.0 m, hang and drop preferred, with a roll for a running jump; above
                                # that, expect damage"
const REST_LEAST := 0.6         # NOT in the study: off the lowest edge he is standing again in this share of the take's time
const RUN_FROM := 2.5           # faster than this, and asked to run, it is the run-off (as character.gd, RUN_FROM)
const LOOK_TIME := 0.3          # NOT in the study: ... or as far as he goes in this many seconds, if that is further
const LOOK := 0.7               # NOT in the study: the ground this far ahead is looked at every tick; only when it
                                # ends there is the full measurement made
const AGAIN := 6                # ticks between measurements while he comes up to an edge
const MOST_OFF_DEG := 45.0      # NOT in the study: he steps off only when heading this near to straight at the edge
const MEASURED_WITHIN := 0.01   # NOT in the study: a drop is taken as measured to a centimetre (the course's 1.00 m
                                # wall measures 1.0003 m), so the band's edges are held with that much give
const LAND_WITHIN := 0.05       # the landing must be where the record said, within this (m): the stage 7 bar for height

var body: CharacterBody3D
var detector: RefCounted
var record: Dictionary = {}
var force_mirror := -1          # for the tests: 0 = the vault as the clip has it, 1 = its mirror image, -1 = by the foot he has forward
var enabled := true             # false = no move is begun (the tests of the body alone, and of detection alone)
var refused := ""               # why the last edge met was not taken with the move ("" = it was, or none met)
var plays := 0                  # moves begun (for the tests)
var _tick := 0
var _fwd := {}                  # move -> the take's own travel forward, frame by frame
var _high := {}                 # move -> how far above its landing the take is, as a share of its whole drop
var _fps := 30.0
var _plan: Dictionary = {}
var _c_fwd := {}                # climb row -> the take's own travel forward, frame by frame
var _c_rise := {}               # ... the share of its rise made, frame by frame
var _c_high := {}               # ... the height it climbs
var _up_record: Dictionary = {}
var _v_fwd := PackedFloat32Array()
var _v_hips := PackedFloat32Array()
var _t_fwd := PackedFloat32Array()
var _j_fwd := PackedFloat32Array()
var _o_fwd := PackedFloat32Array()
var _o_rise := PackedFloat32Array()
var _g_rise1 := PackedFloat32Array()
var _g_rise2 := PackedFloat32Array()
var _g_fwd2 := PackedFloat32Array()
var _w_fwd := PackedFloat32Array()
var _w_rise := PackedFloat32Array()
var _d_xz: PackedVector2Array = PackedVector2Array()
var _d_fall := PackedFloat32Array()
var _d_yaw := PackedFloat32Array()
var _catch_next := 0            # ticks left in which he is to be taken as in the air from a jump (after the jump for a far edge)
var _narrow_ago := 999          # ticks since he was last on something narrow
var _b_xz: PackedVector2Array = PackedVector2Array()
var _b_fall := PackedFloat32Array()
var _still := 0.0               # seconds he has stood still on something narrow
var _o_high := 0.0              # the height the climb take goes up, on him


func _ready() -> void:
	# (`-- --native`: the detector translated to C++, native/traversal, where its library has been built)
	detector = (ClassDB.instantiate(&"TravDetector") if ("--native" in OS.get_cmdline_user_args() and ClassDB.class_exists(&"TravDetector")) else Detector.new())
	detector.set(&"body", body)
	for key: String in MOVES:
		var c: Resource = load(String(MOVES[key]["res"]))
		var hips: PackedVector3Array = c.get(&"hips")
		_fps = float(c.get(&"fps"))
		var last := hips.size() - 1
		var drop := hips[0].y - hips[last].y
		var fwd := PackedFloat32Array()
		var high := PackedFloat32Array()
		for f in hips.size():
			fwd.append(hips[f].z - hips[0].z)
			high.append(clampf((hips[f].y - hips[last].y) / drop, 0.0, 1.0))
		_fwd[key] = fwd
		_high[key] = high
	for key: String in CLIMBS:
		var up: Resource = load(String(CLIMBS[key]["res"]))
		var up_hips: PackedVector3Array = up.get(&"hips")
		var up_fwd := PackedFloat32Array()
		for f in up_hips.size():
			up_fwd.append(up_hips[f].z - up_hips[0].z)
		_c_fwd[key] = up_fwd
		_c_rise[key] = ClipData.rise_of(up_hips)
		_c_high[key] = up_hips[up_hips.size() - 1].y - up_hips[0].y
	body.connect(&"landed", _on_landed)
	var jc: Resource = load(String(JUMP["res"]))
	var j_hips: PackedVector3Array = jc.get(&"hips")
	for f in j_hips.size():
		_j_fwd.append(j_hips[f].z - j_hips[0].z)
	var oc: Resource = load(String(OVER["res"]))
	var o_hips: PackedVector3Array = oc.get(&"hips")
	for f in o_hips.size():
		_o_fwd.append(o_hips[f].z - o_hips[0].z)
	_o_rise = ClipData.rise_of(o_hips)
	_o_high = o_hips[o_hips.size() - 1].y - o_hips[0].y
	var g1: PackedVector3Array = (load(String(GRAB["jump_res"])) as Resource).get(&"hips")
	_g_rise1 = ClipData.rise_of(g1)
	var g2: PackedVector3Array = (load(String(GRAB["climb_res"])) as Resource).get(&"hips")
	_g_rise2 = ClipData.rise_of(g2)
	for f in g2.size():
		_g_fwd2.append(g2[f].z - g2[0].z)
	var wh: PackedVector3Array = (load(String(WALLRUN["res"])) as Resource).get(&"hips")
	_w_rise = ClipData.rise_of(wh)
	for f in wh.size():
		_w_fwd.append(wh[f].z - wh[0].z)
	var dres: Resource = load(String(DOWN["res"]))
	var dh: PackedVector3Array = dres.get(&"hips")
	var d_fallen := 0.0
	var d_from := int(round(float(DOWN["lower_from"]) * 30.0))
	for f in dh.size():
		_d_xz.append(Vector2(dh[f].x - dh[0].x, dh[f].z - dh[0].z))
		if f >= d_from:
			d_fallen = maxf(d_fallen, clampf((dh[d_from].y - dh[f].y) / (dh[d_from].y - dh[dh.size() - 1].y), 0.0, 1.0))
		_d_fall.append(d_fallen)
	var bh: PackedVector3Array = (load(String(BALANCE["res"])) as Resource).get(&"hips")
	var b_from := int(round(float(BALANCE["over"]) * 30.0))
	var b_fallen := 0.0
	for f in bh.size():
		_b_xz.append(Vector2(bh[f].x - bh[0].x, bh[f].z - bh[0].z))
		if f >= b_from:
			b_fallen = maxf(b_fallen, clampf((bh[b_from].y - bh[f].y) / (bh[b_from].y - bh[bh.size() - 1].y), 0.0, 1.0))
		_b_fall.append(b_fallen)
	var tc: Resource = load(String(TUCK["res"]))
	var t_hips: PackedVector3Array = tc.get(&"hips")
	for f in t_hips.size():
		_t_fwd.append(t_hips[f].z - t_hips[0].z)
	var vc: Resource = load(String(VAULT["res"]))
	var v_hips: PackedVector3Array = vc.get(&"hips")
	for f in v_hips.size():
		_v_fwd.append(v_hips[f].z - v_hips[0].z)
		_v_hips.append(v_hips[f].y)


## Coming down from a jump or a fall at speed, from high enough: the roll, from its landing on, if there is the room
## for it (Yasin, 26 Nov: "roll off worked only on running off the edge ... it should work when we jump off too, but
## again with the available space to execute logic").
func _on_landed(drop: float) -> void:
	if not enabled or bool(body.call(&"in_move")) or bool(body.get(&"crouched")):
		return
	var v: Vector3 = body.get(&"hvel")
	if drop <= float(BAND[1]) + MEASURED_WITHIN or drop > ROLL_MOST + ROLL_JUMP_MORE or v.length() < RUN_FROM:
		return
	var mv: Dictionary = MOVES["roll"]
	var fwd: PackedFloat32Array = _fwd["roll"]
	var dir := v.normalized()
	var feet := body.global_position
	var travel := _at(fwd, float(mv["exit"])) - _at(fwd, float(mv["down"]))
	for share: float in [0.0, 0.5, 1.0]:
		var p := feet + dir * (travel * share)
		var g: Dictionary = body.call(&"probe", Vector3(p.x, feet.y, p.z))
		if not bool(g["hit"]) or absf(float(g["y"]) - feet.y) > LAND_WITHIN or not bool(detector.call(&"_fits", Vector3(p.x, feet.y, p.z), float(body.get(&"HEIGHT")))):
			refused = "no room to roll out of the landing"
			return
	refused = ""
	_plan = {"key": "roll_only", "from": feet, "end": feet + dir * travel, "m": dir, "yaw": atan2(-dir.x, -dir.z),
			"exit_speed": (_at(fwd, float(mv["exit"])) - _at(fwd, float(mv["exit"]) - 0.2)) / 0.2}
	plays += 1
	body.call(&"begin_move", _roll_only, String(mv["input"]))


func _roll_only(t: float) -> Dictionary:
	var mv: Dictionary = MOVES["roll"]
	var fwd: PackedFloat32Array = _fwd["roll"]
	var p := _plan
	var u := clampf(t / (float(mv["exit"]) - float(mv["down"])), 0.0, 1.0)
	var ct := lerpf(float(mv["down"]), float(mv["exit"]), u)
	var f0 := _at(fwd, float(mv["down"]))
	var f1 := _at(fwd, float(mv["exit"]))
	var free: Array = mv["free"]
	var out := {"done": u >= 1.0, "pos": (p["from"] as Vector3).lerp(p["end"], (_at(fwd, ct) - f0) / maxf(f1 - f0, 0.001)), "yaw": float(p["yaw"]),
			"clip_t": ct, "air": false, "landed": true, "landing": "heavy", "free": ct >= float(free[0]) and ct <= float(free[1])}
	if u >= 1.0:
		out["exit"] = (p["m"] as Vector3) * float(p["exit_speed"])
	return out


func _at(table: PackedFloat32Array, t: float) -> float:
	var x := clampf(t * _fps, 0.0, table.size() - 1.001)
	var i := int(x)
	return lerpf(table[i], table[i + 1], x - i)


func _physics_process(_dt: float) -> void:
	if body == null or not enabled or bool(body.call(&"in_move")):
		return
	# (walked to a seat, a car door or a place in cover by interact.gd: walking toward a wall he is about to take cover
	# against is not walking at it to climb it; he mantled a 1.10 m wall on his way to cover behind it)
	if bool(body.get(&"auto_on")):
		record = {}
		return
	_tick += 1
	var v: Vector3 = body.get(&"hvel")
	var wish := (body.get(&"_wish") as Vector3).length()
	# standing still on something narrow: after 10 s he loses his balance
	# (not on a ledge with a wall behind him: his back is against it)
	if int(body.get(&"narrow")) > 0 and int(body.get(&"squeeze")) != 3 and int(body.get(&"state")) == 0 and v.length() < 0.1:
		_still += 1.0 / 60.0
		if _still >= BALANCE_AFTER:
			_still = 0.0
			if _try_balance_fall():
				return
	else:
		_still = 0.0
	# Sidling along a ledge he is drawn in toward the wall behind him: that is not walking at the wall, and no climb
	# of it begins unless the stick itself is pushed at the wall (on the course's own ledge, a wall 2.5 m above it,
	# he grabbed the top and climbed it as he came onto the ledge).
	if int(body.get(&"squeeze")) == 3:
		var sw: Vector3 = body.get(&"stick_wish")
		if sw.length() < 0.05 or sw.normalized().dot(-(body.get(&"ledge_out") as Vector3)) < 0.5:
			record = {}
			return
	if _catch_next > 0:
		_catch_next -= 1
		if int(body.get(&"state")) >= 2:
			body.set(&"from_jump", true)
			body.set(&"_jump_still", true)
			_catch_next = 0
	if int(body.get(&"state")) >= 2 and _try_air(v):
		return
	if _try_step_up(v, body.get(&"_wish")):
		return
	# Stage 15: crouched, going at an edge with a drop of 1.0 to 3.0 m: the turn, hang and drop. (Walking off such an
	# edge upright is left as it was, a fall and the heavy landing: asked for by walking alone, it took the heavy
	# landing away, which the audit holds him to, and it began in the air after other moves.)
	if bool(body.get(&"crouched")) and int(body.get(&"state")) == 0 and wish > 0.05 and v.length() > 0.2:
		if _tick % AGAIN == 0:
			var rec: Dictionary = detector.call(&"measure", v.normalized())
			var d := float(rec.get("drop", INF))
			if String(rec["kind"]) == "drop" and d > float(DOWN_BAND[0]) + MEASURED_WITHIN and d <= float(DOWN_BAND[1]) + MEASURED_WITHIN:
				record = rec
				_try_climb_down(v.normalized(), d)
				record = {} if not bool(body.call(&"in_move")) else record
		return
	var walking := int(body.get(&"state")) == 0 and not bool(body.get(&"crouched")) and v.length() > 0.5 \
			and wish > 0.05 and int(body.get(&"stairs")) == 0 and int(body.get(&"terrain")) == 0
	var key := "run" if (wish > float(body.get(&"WALK")) + 0.1 and v.length() > RUN_FROM) else "walk"
	# Off something narrow (stage 17) he was held to a slow pace: there it is the run key that says which way he goes
	# off the edge. Yasin, 26 Nov: "if we wanna walk off, we should just step off or jump off like we do on edges
	# depending on running or walking".
	_narrow_ago = 0 if int(body.get(&"narrow")) > 0 else _narrow_ago + 1
	if _narrow_ago < 45 and bool(body.get(&"run_asked")):
		key = "run"
	var mv: Dictionary = MOVES[key]
	var fwd: PackedFloat32Array = _fwd[key]
	if not walking:
		record = {}
		return
	var dir := v.normalized()
	# the cheap look: does the ground end a little ahead?
	if record.is_empty():
		var ahead: Dictionary = body.call(&"_ray_down", body.global_position + dir * maxf(LOOK, v.length() * LOOK_TIME))
		# (ground a little lower ahead is measured too: it may be a shallow gap with a far side. Left to the walk
		# itself, as it was until trav64, he went down into it and up the other side. Yasin, 26 Nov: "the jumps
		# between the first blocks dont trigger, the still appears falling but lands on the obstacle across anyway")
		if not ahead.is_empty() and (ahead["position"] as Vector3).y > body.global_position.y - GAP_DEEP_LEAST:
			return
	# (a gap he is coming up to is measured every tick: a narrow one is under the look ahead for a few ticks only)
	if record.is_empty() or _tick % AGAIN == 0 or String(record.get("kind", "")) == "gap":
		record = detector.call(&"measure", dir, INF, GAP_LOOK)
		# A second look at the edge alone, for the gaps the first does not show as gaps: a shallow one (the first takes
		# ground up to 0.30 m lower as his ground still), a far side well below his (the first counts a far side only
		# to 0.32 m below), and a far side higher than his (the first shows that as something that stands up, and not
		# the gap before it; put together here from both). Without this he walked off the edge and fell, or down into
		# a shallow gap and up again. Yasin, 26 Nov: "the jumps between the first blocks dont trigger", "HE KEEPS
		# FALLING DIRECTLY WHEN WALKING".
		if record["kind"] != "gap":
			var e: Dictionary = detector.call(&"measure_edge", dir, GAP_LOOK, GAP_DEEP_LEAST, GAP_DOWN)
			if not e.is_empty() and String(e["kind"]) == "gap" and float(e["gap"]) >= GAP_LEAST and not bool(e.get("far_wall", false)):
				record = e
			elif not e.is_empty() and record["kind"] == "obstacle" and float(record.get("top", INF)) != INF and not bool(record.get("blocked", true)):
				var em: Vector3 = -(e["normal"] as Vector3)
				var across := ((record["edge"] as Vector3) - (e["edge"] as Vector3)).dot(em)
				if across >= GAP_LEAST:
					e["kind"] = "gap"
					e["gap"] = across
					e["far_wall"] = false
					e["landing"] = float(record["top"])
					e["landing_ok"] = bool(record.get("stand_room", false))
					record = e
		if record["kind"] == "gap":
			var gap_rec := record
			record = {}
			if not _try_gap(v, dir, gap_rec, key == "run") and refused == "coming up to the gap":
				record = gap_rec
			return
		if record["kind"] != "drop":
			refused = "" if record["kind"] == "none" else "not a plain drop (%s)" % record["kind"]
			record = {}
			return
	# is it this move's? "it plays on every course obstacle inside its height band and is refused on every obstacle
	# outside it"
	var drop := float(record.get("drop", INF))
	if drop <= float(BAND[0]) + MEASURED_WITHIN:
		refused = "low enough to step down in stride"
		return
	if drop > float(BAND[1]) + MEASURED_WITHIN:
		if key != "run" or drop > ROLL_MOST + MEASURED_WITHIN:
			refused = "too high for a step off (%.2f m)" % drop
			return
		key = "roll"
		mv = MOVES[key]
		fwd = _fwd[key]
	var m: Vector3 = -(record["normal"] as Vector3)
	if rad_to_deg(dir.angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at the edge"
		return
	# fit: the take's own path, from where it is taken up, laid from here out over the edge
	var from_t := float(mv["from"])
	var edge_at := float(mv["edge"])
	var to_edge := edge_at - _at(fwd, from_t)                  # the take's own distance to its edge at that moment
	var here := (record["edge"] as Vector3 - body.global_position).dot(m)
	if here > to_edge:
		return                                                  # not there yet
	var feet := body.global_position
	var top_y := float(record["ground"])        # the ground he stood on, not his feet, which sink a little at an edge
	var land_y := top_y - drop
	var speed_in := maxf(v.length(), 0.8)
	var t_air := sqrt(2.0 * drop / float(body.get(&"GRAVITY")))
	var t_rest := float(mv["exit"]) - float(mv["down"])
	var n := fwd.size()
	var exit_speed := (_at(fwd, float(mv["exit"])) - _at(fwd, float(mv["exit"]) - 0.2)) / 0.2
	var leave := feet + m * (here + _at(fwd, float(mv["leaves"])) - edge_at)
	# Through the air he goes on at the pace he came in at, for as long as the drop takes; the take's own travel
	# there belongs to its own, higher ledge. On the ground again he covers what the take does, at the take's pace
	# (walking), or goes from his own pace to the take's (running on).
	var down := leave + m * (speed_in * t_air if key != "walk" else _at(fwd, float(mv["down"])) - _at(fwd, float(mv["leaves"])))
	var end := down + m * ((speed_in + exit_speed) * 0.5 * t_rest if key == "run" else _at(fwd, float(mv["exit"])) - _at(fwd, float(mv["down"])))
	# the landing: the ground where he comes down and where he ends must be where the record said, with room for him
	for p: Vector3 in [down, down.lerp(end, 0.5), end]:
		var g: Dictionary = body.call(&"probe", Vector3(p.x, land_y, p.z))
		if not bool(g["hit"]) or absf(float(g["y"]) - land_y) > LAND_WITHIN:
			refused = "the ground where he would land is not level with the drop measured"
			return
		if not bool(detector.call(&"_fits", Vector3(p.x, land_y, p.z), float(body.get(&"HEIGHT")))):
			refused = "no room to land"
			return
	refused = ""
	_plan = {"key": key, "from": feet, "leave": Vector3(leave.x, top_y, leave.z), "down": Vector3(down.x, land_y, down.z), "end": Vector3(end.x, land_y, end.z),
			"m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z), "drop": drop,
			# align and step: at the pace he came in at. Air: as long as that drop takes to fall. Then the take's own time.
			"t_step": maxf((leave - feet).dot(m), 0.05) / speed_in, "t_air": t_air, "t_rest": t_rest, "exit_speed": exit_speed}
	# Running off a low edge he simply runs on (Yasin, 26 Nov: "only running off a low edge plays timid short steps
	# before the run continues, just continue running animation in that case"): the run itself is shown all the way,
	# the body is carried down as before, and he is handed back as he touches down, at the speed he came in at.
	var run_on := key == "run" and drop <= RUN_ON_MOST + MEASURED_WITHIN
	if run_on:
		_plan["end"] = _plan["down"]
		_plan["exit_speed"] = speed_in
		_plan["run_on"] = true
	# A softer landing off a lower edge (Yasin, 26 Nov: "Make a softer landing for edges lower than 1 meter"): he
	# folds by the share this drop is of the take's own (the study gives the landing forces by height, "4.4 body
	# weights from 0.45 m and 7.4 from 0.89 m", and no fold depth; taking the fold as in step with the height is
	# OURS), and is up again sooner by the same share.
	var share := 1.0 if key == "roll" else clampf(drop / float(mv["native"]), 0.0, 1.0)
	_plan["soft"] = 1.0 - share
	_plan["t_rest"] = float(_plan["t_rest"]) * lerpf(REST_LEAST, 1.0, share)
	plays += 1
	record = {}
	body.call(&"begin_move", _step_off, "ground" if run_on else String(mv["input"]))


## Where the body is `t` seconds into the step off (called by the body every tick of the move).
func _step_off(t: float) -> Dictionary:
	var p := _plan
	var dk := String(p.get("drop_key", p["key"]))
	var mv: Dictionary = MOVES[dk]
	var fwd: PackedFloat32Array = _fwd[dk]
	var high: PackedFloat32Array = _high[dk]
	var m: Vector3 = p["m"]
	var t_step := float(p["t_step"])
	var t_air := float(p["t_air"])
	var t_rest := float(p["t_rest"])
	var out := {"done": false, "yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / maxf(t_step, 0.05), 0.0, 1.0))}
	if t < t_step:
		var u := t / t_step
		out["pos"] = (p["from"] as Vector3).lerp(p["leave"], u)
		out["clip_t"] = lerpf(float(mv["from"]), float(mv["leaves"]), u)
		out["air"] = false
	elif t < t_step + t_air:
		var u := (t - t_step) / t_air
		var ct := lerpf(float(mv["leaves"]), float(mv["down"]), u)
		# forward by the take's own travel through its fall; down by the take's own fall, scaled to this drop
		var f0 := _at(fwd, float(mv["leaves"]))
		var f1 := _at(fwd, float(mv["down"]))
		var along := (_at(fwd, ct) - f0) / maxf(f1 - f0, 0.001)
		var pos := (p["leave"] as Vector3).lerp(p["down"], along)
		var h0 := _at(high, float(mv["leaves"]))
		var h1 := _at(high, float(mv["down"]))
		pos.y = (p["down"] as Vector3).y + float(p["drop"]) * clampf((_at(high, ct) - h1) / maxf(h0 - h1, 0.001), 0.0, 1.0)
		out["pos"] = pos
		out["clip_t"] = ct
		out["air"] = true
		out["soft"] = float(p["soft"]) * u
	elif bool(p.get("run_on", false)):
		out["pos"] = p["down"]
		out["clip_t"] = 0.0
		out["air"] = false
		out["done"] = true
		out["exit"] = m * float(p["exit_speed"])
	else:
		var u := clampf((t - t_step - t_air) / t_rest, 0.0, 1.0)
		var ct := lerpf(float(mv["down"]), float(mv["exit"]), u)
		var f0 := _at(fwd, float(mv["down"]))
		var f1 := _at(fwd, float(mv["exit"]))
		out["pos"] = (p["down"] as Vector3).lerp(p["end"], (_at(fwd, ct) - f0) / maxf(f1 - f0, 0.001))
		out["clip_t"] = ct
		out["air"] = false
		out["landed"] = true
		var free: Array = mv.get("free", [])
		out["free"] = free.size() == 2 and ct >= float(free[0]) and ct <= float(free[1])
		out["landing"] = String(mv.get("landing", "soft"))
		out["soft"] = float(p["soft"])
		if u >= 1.0:
			out["done"] = true
			out["exit"] = m * float(p["exit_speed"])
	return out


# ------------------------------------------------------------------------------------------------ stage 9: the high step up

## Something of 0.30 to 0.50 m ahead, with room to stand on it: step up onto it. Asked for by going at it, at a walk,
## at a run, or from standing against it (the body is stopped by anything over 0.30 m).
func _try_step_up(v: Vector3, wish: Vector3) -> bool:
	if int(body.get(&"state")) != 0 or bool(body.get(&"crouched")) or wish.length() < 0.05 \
			or int(body.get(&"stairs")) != 0 or int(body.get(&"terrain")) != 0:
		_up_record = {}
		return false
	var dir := wish.normalized()
	# the cheap look: is anything in the way just above what he steps over by himself?
	if _up_record.is_empty():
		var from := body.global_position + Vector3.UP * (float(UP_BAND[0]) + 0.03)
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * UP_LOOK_RUN, body.collision_mask, [body.get_rid()])
		if body.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			return false
	# (at a run it is measured every tick once something is seen: he covers 7 cm a tick, and a move has to be begun
	# within a few tenths of a metre of its place)
	if _up_record.is_empty() or _tick % (1 if v.length() > RUN_FROM else AGAIN) == 0:
		_up_record = detector.call(&"measure", dir)
		if _up_record["kind"] != "obstacle":
			_up_record = {}
			return false
	var rec := _up_record
	var top := float(rec["top"])
	if _try_vault(v, wish, rec):
		return true
	if top <= float(UP_BAND[0]) + MEASURED_WITHIN:
		return false                                            # the body walks onto it by itself
	if top > float(ON_BAND[1]) + MEASURED_WITHIN and top <= float(MANTLE_BAND[1]) + MEASURED_WITHIN and not bool(rec["thin"]):
		return _try_mantle(v, wish, rec)
	# at a run at something deep and high: the running wall climb, from its own run in
	if not bool(rec["thin"]) and top > float(WALLRUN_BAND[0]) + MEASURED_WITHIN and top <= float(WALLRUN_BAND[1]) + MEASURED_WITHIN \
			and wish.length() > float(body.get(&"WALK")) + 0.1 and v.length() > RUN_FROM:
		if _try_wallrun(v, wish, rec):
			return true
		if refused == "coming up to the wall climb":
			return false
	if top > float(VAULT_BAND[1] if bool(rec["thin"]) else MANTLE_BAND[1]) + MEASURED_WITHIN and top <= float(HIGH_BAND[1]) + MEASURED_WITHIN:
		return _try_grab(wish, rec)                             # stages 13 and 14 (thin: up, and off its far side)
	if top > float(ON_BAND[1]) + MEASURED_WITHIN:
		refused = "too high to step or climb onto (%.2f m)" % top
		return false
	if bool(rec["blocked"]) or not bool(rec["stand_room"]):
		refused = "no room to stand on top"
		return false
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(dir.angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at it"
		return false
	var running := wish.length() > float(body.get(&"WALK")) + 0.1 and v.length() > RUN_FROM
	var row := "step_up"
	if top <= float(UP_BAND[1]) + MEASURED_WITHIN:
		if _try_run_up(v, wish, rec, m, top):
			return true
		if not refused.is_empty():
			return false
	else:
		row = "step_on" if (top <= STEP_ON_MOST + MEASURED_WITHIN and not running) else "jump_on"
	var cl: Dictionary = CLIMBS[row]
	var c_fwd: PackedFloat32Array = _c_fwd[row]
	# Come at on the move, the take is taken up with its stepping foot already lifting, and of the take and its mirror
	# image the one whose stepping foot is the foot he has forward; and it is begun before he is stopped against the
	# step. (Begun from its standing start once he had walked into the step, the foot he had forward was already past
	# the step's face: Yasin, 26 Nov, "stepping onto the edge is jittery".)
	var moving := v.length() > 0.5
	var from_t := float(cl["from_moving"]) if moving else float(cl["from"])
	var exit_t := float(cl["exit"])
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	if running and cl.has("from_run"):
		# at a run the jump onto it is taken from its own run in, if he is not already nearer than that
		var far := float(cl["edge"]) - _at(c_fwd, float(cl["from_run"]))
		if here > far:
			refused = "coming up to the jump onto it"
			return false
		if here > far - 0.45:
			from_t = float(cl["from_run"])
	var native := float(cl["edge"]) - _at(c_fwd, from_t)             # the take's own distance from the face as it begins
	if here > native + 0.02 + (v.length() * EARLY if moving else 0.0):
		return false                                            # not there yet
	# of the take and its mirror image, the one that has forward the foot he has forward
	var mirror := false
	var ch := body.get_node_or_null(^"Character")
	if moving and bool(cl["mirrored"]) and ch != null and ch.has_method(&"_lead_now"):
		mirror = (float(ch.call(&"_lead_now")) > 0.0) != bool(cl["wants_left"])
	# fit: he ends as far in from the edge as the take does; the take's travel is stretched to that
	var inward := _at(c_fwd, exit_t) - float(cl["edge"])
	if float(rec["depth"]) < inward + float(body.get(&"RADIUS")):
		refused = "the top is not deep enough to step onto"
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var end := feet + m * (here + inward)
	end.y = ground + top
	if not bool(detector.call(&"_fits", end, float(body.get(&"HEIGHT")))):
		refused = "no room where he would end"
		return false
	refused = ""
	_plan = {"key": "up" if row == "step_up" else row, "row": row, "from": Vector3(feet.x, ground, feet.z), "end": end, "m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z),
			"top": top, "here": here, "from_t": from_t, "stretch": (here + inward) / maxf(_at(c_fwd, exit_t) - _at(c_fwd, from_t), 0.01),
			"exit_speed": maxf((_at(c_fwd, exit_t) - _at(c_fwd, exit_t - 0.2)) / 0.2, 0.0)}
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _step_up, String(cl["input"]) + ("_m" if mirror else ""))
	return true


## Where the body is `t` seconds into the step up: forward by the take's own travel (stretched to the distance
## measured), up by the take's own rise (scaled to the height measured).
func _step_up(t: float) -> Dictionary:
	var p := _plan
	var cl: Dictionary = CLIMBS[p["row"]]
	var c_fwd: PackedFloat32Array = _c_fwd[p["row"]]
	var c_rise: PackedFloat32Array = _c_rise[p["row"]]
	var high: float = _c_high[p["row"]]
	var m: Vector3 = p["m"]
	var from_t := float(p["from_t"])
	var exit_t := float(cl["exit"])
	var ct := minf(from_t + t, exit_t)
	var gone := _at(c_fwd, ct) - _at(c_fwd, from_t)
	var rise := _at(c_rise, ct)
	var pos := (p["from"] as Vector3) + m * (gone * float(p["stretch"]))
	pos.y = (p["from"] as Vector3).y + float(p["top"]) * rise
	var out := {"done": ct >= exit_t, "pos": pos, "clip_t": ct, "air": false,
			"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0)),
			# for the feet: the take's own step, as it stands ahead of him at this moment
			"step": [float(cl["edge"]) - _at(c_fwd, ct), high, high * rise, float(p["top"])]}
	if ct >= exit_t:
		out["pos"] = p["end"]
		out["exit"] = m * float(p["exit_speed"])
	return out


# The step up at a run: a leap in stride. True once it is begun; false with `refused` empty = not this move's, or
## not yet; false with `refused` set = it is waiting for its take-off point.
func _try_run_up(v: Vector3, wish: Vector3, rec: Dictionary, m: Vector3, top: float) -> bool:
	refused = ""
	var speed := v.length()
	if wish.length() <= float(body.get(&"WALK")) + 0.1 or speed <= RUN_FROM:
		return false
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	var take_off := speed * RUN_UP_AIR * RUN_UP_FACE            # how far before the edge he leaves the ground
	var beyond := speed * RUN_UP_AIR * (1.0 - RUN_UP_FACE)      # ... and how far past it he comes down
	var out_run := speed * (float(RUN_UP["exit"]) - float(RUN_UP["land"]))
	if float(rec["depth"]) < beyond + out_run + float(body.get(&"RADIUS")):
		return false                                            # not the room on top to run on: the walking step up
	if here < take_off - 0.15:
		return false                                            # too near already for the leap: the walking step up
	if here > take_off:
		refused = "coming up to the leap"
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var land := feet + m * (here + beyond)
	land.y = ground + top
	var end := land + m * out_run
	for p: Vector3 in [land, end]:
		if not bool(detector.call(&"_fits", p, float(body.get(&"HEIGHT")))):
			return false
	_plan = {"key": "run_up", "from": Vector3(feet.x, ground, feet.z), "land": land, "end": end, "m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z),
			"top": top, "speed": speed, "exit_speed": speed}
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _run_up, String(RUN_UP["input"]))
	return true


func _run_up(t: float) -> Dictionary:
	var p := _plan
	var m: Vector3 = p["m"]
	var out := {"done": false, "yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0))}
	if t < RUN_UP_AIR:
		var u := t / RUN_UP_AIR
		var pos := (p["from"] as Vector3).lerp(p["land"], u)
		pos.y = (p["from"] as Vector3).y + float(p["top"]) * u + 4.0 * RUN_UP_ARC * u * (1.0 - u)
		out["pos"] = pos
		out["clip_t"] = lerpf(float(RUN_UP["off"]), float(RUN_UP["land"]), u)
		out["air"] = true
	else:
		var rest := float(RUN_UP["exit"]) - float(RUN_UP["land"])
		var u := clampf((t - RUN_UP_AIR) / rest, 0.0, 1.0)
		out["pos"] = (p["land"] as Vector3).lerp(p["end"], u)
		out["clip_t"] = lerpf(float(RUN_UP["land"]), float(RUN_UP["exit"]), u)
		out["air"] = false
		if u >= 1.0:
			out["done"] = true
			out["exit"] = m * float(p["exit_speed"])
	return out


# ------------------------------------------------------------------------------------------------ stage 10: the vault

## A thin obstacle of 0.50 to 1.10 m, come at at a run, with level, free ground beyond it: vault it.
## `adds` > 0 = he is in the air from a running jump: the band is that much higher (what the jump raises him), and
## the clip is taken up in its own flight.
func _try_vault(v: Vector3, wish: Vector3, rec: Dictionary, adds := 0.0) -> bool:
	var top := float(rec["top"])
	# (a thin obstacle of just 0.50 m is vaulted too: there is no standing on it, so it cannot be stepped up onto)
	if top == INF or top < float(VAULT_BAND[0]) - MEASURED_WITHIN or top > float(VAULT_BAND[1]) + adds + MEASURED_WITHIN:
		return false
	if not bool(rec["thin"]) or bool(rec["blocked"]):
		return false                                            # deep: to be climbed onto (stage 11), not vaulted
	var speed := v.length()
	# Stage 11, a thin obstacle met at a walk or from standing: the standing vault (see TUCK), not this one.
	var slow := wish.length() <= float(body.get(&"WALK")) + 0.1 or speed <= RUN_FROM
	if slow and adds > 0.0:
		return false
	if slow and top <= JUMP_MOST + MEASURED_WITHIN:
		return _try_tuck(v, wish, rec, true)
	# (higher than that, at a walk: the one-hand vault at its slowest, from its own run in, the one move here in
	# which a hand truly bears on the top. The Kimodo vault from standing is NOT used above 1.0 m: its hands do not
	# come down, and carried over a higher wall he floated with his hands 16 cm and more above the top. Yasin, 26 Nov:
	# "they do at the very start, but then the character just levitates".)
	if slow and speed < 0.5:
		return _try_over(wish, rec)                             # from standing against it: the climb over
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(wish.normalized().angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at it"
		return false
	if not rec.has("landing") or absf(float(rec["landing"])) > LAND_LEVEL or not bool(rec.get("landing_ok", false)):
		refused = "the ground beyond it is not level with his, or has no room"
		return false
	# fit: the clip's own path, laid so that where its hand comes down is the middle of the obstacle's top
	var depth := float(rec["depth"])
	var to_mid := (rec["edge"] as Vector3 - body.global_position).dot(m) + depth * 0.5
	var first_t := float(VAULT["off"]) if adds > 0.0 else float(VAULT["from"])
	var start := float(VAULT["at"]) - _at(_v_fwd, first_t)       # the clip's own distance to it as it is taken up
	if to_mid > start:
		refused = "coming up to the vault"
		return false
	# Begun a little late, the clip is taken up a little later, where it is as far from its obstacle as he is from
	# his. (Until trav46 its run in was squeezed to the ground he had left instead: that brought his leading foot to
	# the wall early and low, 16 to 45 cm under the top on the higher walls, found when the test began to look at
	# each foot as it crosses the wall.) He has to leave the ground where the clip does, so nearer than that it
	# cannot be done: from standing against a thin obstacle there is still no move (it needs a step vault clip).
	var from_t := first_t
	while from_t < (float(VAULT["hand_on"]) - 0.08 if adds > 0.0 else float(VAULT["off"])) and float(VAULT["at"]) - _at(_v_fwd, from_t) > to_mid:
		from_t += 1.0 / 60.0
	if float(VAULT["at"]) - _at(_v_fwd, from_t) > to_mid + 0.08:
		refused = "too near already to vault it"
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var mid := feet + m * to_mid
	mid.y = ground
	var land := mid + m * (_at(_v_fwd, float(VAULT["down"])) - float(VAULT["at"]))
	var end := mid + m * (_at(_v_fwd, float(VAULT["exit"])) - float(VAULT["at"]))
	for p: Vector3 in [land, end]:
		var g: Dictionary = body.call(&"probe", p)
		if not bool(g["hit"]) or absf(float(g["y"]) - ground) > LAND_LEVEL or not bool(detector.call(&"_fits", Vector3(p.x, float(g["y"]), p.z), float(body.get(&"HEIGHT")))):
			refused = "no level, free ground to land on"
			return false
	refused = ""
	var pace := VAULT_SLOW if slow else clampf(speed / float(VAULT["speed"]), float(VAULT_PACE[0]), float(VAULT_PACE[1]))
	var left := Vector3.UP.cross(m).normalized()
	# The clip takes off from the left foot and puts the left hand down. With his right foot forward it is the mirror
	# image: off the right foot, the right hand down, on his right (Yasin, 26 Nov: "make a mirrored vault too").
	var mirror := false
	var ch := body.get_node_or_null(^"Character")
	if ch != null and ch.has_method(&"_lead_now"):
		mirror = float(ch.call(&"_lead_now")) < 0.0
	if force_mirror >= 0:
		mirror = force_mirror == 1
	if mirror:
		left = -left
	_plan = {"key": "vault", "from": Vector3(feet.x, ground, feet.z), "mid": mid, "end": Vector3(end.x, ground, end.z), "m": m,
			"yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z), "top": top, "pace": pace, "to_mid": to_mid, "from_t": from_t,
			# the hand: on the middle of the top, as far to his left as the clip has it, the wrist a palm over it
			# (4 cm on his side of the middle: with the obstacle set 6 cm further along the clip, for his feet, the
			# middle itself was 3.4 cm beyond his reach)
			"hand_at": Vector3(mid.x, ground + top + PALM, mid.z) - m * 0.04 + left * float(VAULT["hand_side"]),
			"hand": 1 if mirror else 0, "exit_speed": float(VAULT["speed"]) * pace}
	if adds > 0.0:
		# (the hand is held from when the vault's own pose has come in over the jump's: sooner, the wrist was 8 cm short)
		_plan.merge({"air": true, "y_from": feet.y, "hold_from": from_t + 0.17})
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _vault, String(VAULT["input"]) + ("_m" if mirror else ""))
	return true


## Where the body is `t` seconds into the vault. Forward by the clip's own travel, set so that its hand comes down
## on the obstacle. Up or down by how much higher or lower the obstacle is than the clip's own, by the share of the
## clip's own rise over its take-off height that it has made (none on the ground, all of it at the top).
func _vault(t: float) -> Dictionary:
	var p := _plan
	var m: Vector3 = p["m"]
	var from_t := float(p["from_t"])
	var exit_t := float(VAULT["exit"])
	var ct := minf(from_t + t * float(p["pace"]), exit_t)
	# (before its hand is down the little he was out by when it began is taken up evenly; after, the clip's own travel)
	var z := _at(_v_fwd, ct) - float(VAULT["at"])
	var out_by := float(p["to_mid"]) - (float(VAULT["at"]) - _at(_v_fwd, from_t))
	if z < 0.0:
		z -= out_by * clampf(z / minf(_at(_v_fwd, from_t) - float(VAULT["at"]), -0.01), 0.0, 1.0)
	var pos := (p["mid"] as Vector3) + m * z
	var air := ct >= float(VAULT["off"]) and ct < float(VAULT["down"])
	# (all of it for as long as the hand is down, coming in from take-off and going out to landing: fitted by the
	# clip's own rise alone he was still too high over a low obstacle when the hand came down, and the wrist was up
	# to 11 cm short of it. His arm is 17 % shorter than the clip's body's, so the hand is held for the middle 0.18 s
	# of the clip's 0.27 s: outside that his arm cannot reach the place.)
	# Up to a higher obstacle the rise is made about his take-off (made later, his leading foot met the wall);
	# down to a lower one it is made after it, as the hand comes down (made earlier, the foot he takes off from was
	# pushed 17 cm into the ground).
	var higher := float(p["top"]) > float(VAULT["high"])
	var over := 0.0
	if ct >= float(VAULT["off"]) - LIFT_EARLY and ct < float(VAULT["down"]):
		var up := smoothstep(float(VAULT["off"]) - LIFT_EARLY, float(VAULT["off"]) + LIFT_EARLY, ct) if higher else smoothstep(float(VAULT["off"]), float(VAULT["hand_on"]), ct)
		over = minf(up, 1.0 - smoothstep(float(VAULT["hand_off"]), float(VAULT["down"]), ct))
	# (over an obstacle higher than the clip's own he is carried CLEAR_MORE higher still: fitted exactly, his feet
	# went over the 1.00 and 1.10 m walls 1 cm clear on one side and 1 to 2 cm short on the other)
	# (... only while his leading foot goes over, and gone again by the time the hand is down: kept through the
	# hold, the top was 6.7 cm beyond the reach of his wrist)
	var more := CLEAR_MORE * (1.0 - smoothstep(float(VAULT["hand_on"]) - 0.07, float(VAULT["hand_on"]), ct)) if higher else 0.0
	pos.y += (float(p["top"]) - float(VAULT["high"]) + more) * over
	if p.has("y_from"):
		# begun in the air: from where he is, and on the vault's own path by the time the hand comes down
		pos.y = lerpf(float(p["y_from"]), pos.y, smoothstep(from_t, maxf(float(VAULT["hand_on"]) - HAND_FADE, from_t + 0.02), ct))
	var hold := clampf(minf((ct - maxf(float(VAULT["hand_on"]), float(p.get("hold_from", 0.0)))) / HAND_FADE + 1.0, (float(VAULT["hand_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0)
	hold = hold * hold * (3.0 - 2.0 * hold)         # eased in and out, not at an even rate
	var out := {"done": ct >= exit_t, "pos": pos, "clip_t": ct, "air": air, "free": true,
			"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0)),
			"hand": [int(p["hand"]), p["hand_at"], hold]}
	if ct >= exit_t:
		out["pos"] = p["end"]
		out["exit"] = m * float(p["exit_speed"])
	return out


## A thin obstacle from standing or at a walk. `low` = up to 1.0 m: the jump over it; higher: the vault with both
## hands on its top.
## Where the two hands of a climb go: `side` m to each side of him on the top, as the take has them. On a top that
## does not reach that far (a wall met end on, 0.2 m across) each hand is brought in to rest on it, HAND_IN inside
## its edge: left as the take had them they held the air to each side of the wall. Yasin, 26 Nov: "hands should
## close and grab the wall when we climb on walls from the narrow sides".
const HAND_IN := 0.04           # NOT in the study, mine: the wrist this far inside the edge of a narrow top (m)
const HAND_LEAST := 0.03        # NOT in the study, mine: and never nearer his middle than this, so the hands lie side by side
func _hands(on_top: Vector3, left: Vector3, side: float, rec: Dictionary) -> Array:
	var l := clampf(float(rec.get("width_left", INF)) - HAND_IN, HAND_LEAST, side)
	var r := clampf(float(rec.get("width_right", INF)) - HAND_IN, HAND_LEAST, side)
	return [on_top + left * l, on_top - left * r]


func _try_tuck(v: Vector3, wish: Vector3, rec: Dictionary, low: bool) -> bool:
	var top := float(rec["top"])
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(wish.normalized().angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at it"
		return false
	if not rec.has("landing") or absf(float(rec["landing"])) > LAND_LEVEL or not bool(rec.get("landing_ok", false)):
		refused = "the ground beyond it is not level with his, or has no room"
		return false
	var mv: Dictionary = JUMP if low else TUCK
	var fwd: PackedFloat32Array = _j_fwd if low else _t_fwd
	var depth := float(rec["depth"])
	var to_mid := (rec["edge"] as Vector3 - body.global_position).dot(m) + depth * 0.5
	# it is begun within a step of the obstacle (the vault: where the take is as far from its own as he is from his)
	var from_t := float(mv["from"])
	var reach := 0.75 if low else float(mv["at"]) - _at(fwd, from_t) + 0.05
	if to_mid > reach:
		refused = "coming up to it"
		return false
	if not low:
		while from_t < float(mv["hands_on"]) - 0.1 and float(mv["at"]) - _at(fwd, from_t) > to_mid:
			from_t += 1.0 / 60.0
	var feet := body.global_position
	var ground := float(rec["ground"])
	var mid := feet + m * to_mid
	mid.y = ground
	var end := mid + m * (BEYOND if low else _at(fwd, float(mv["exit"])) - float(mv["at"]))
	var g: Dictionary = body.call(&"probe", end)
	if not bool(g["hit"]) or absf(float(g["y"]) - ground) > LAND_LEVEL or not bool(detector.call(&"_fits", Vector3(end.x, float(g["y"]), end.z), float(body.get(&"HEIGHT")))):
		refused = "no level, free ground to land on"
		return false
	refused = ""
	var left := Vector3.UP.cross(m).normalized()
	var on_top := Vector3(mid.x, ground + top + PALM, mid.z) - m * (depth * 0.5 - 0.04)       # 4 cm in from its near edge
	_plan = {"key": "vault_jump" if low else "vault_tuck", "low": low, "from": Vector3(feet.x, ground, feet.z), "mid": mid,
			"end": Vector3(end.x, ground, end.z), "m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z), "top": top,
			"to_mid": to_mid, "from_t": from_t, "hand": -1 if low else 2, "exit_speed": 0.0,
			"hands_at": _hands(on_top, left, float(TUCK["hand_side"]), rec)}
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _tuck, String(mv["input"]))
	return true


func _tuck(t: float) -> Dictionary:
	var p := _plan
	var low: bool = p["low"]
	var mv: Dictionary = JUMP if low else TUCK
	var fwd: PackedFloat32Array = _j_fwd if low else _t_fwd
	var m: Vector3 = p["m"]
	var from_t := float(p["from_t"])
	var exit_t := float(mv["exit"])
	var ct := minf(from_t + t, exit_t)
	var air := ct >= float(mv["off"]) and ct < float(mv["down"])
	var pos: Vector3
	if low:
		# the jump: he stays where he is until he leaves the ground, and is carried across while he is in the air,
		# so that he is over the middle of the obstacle at the top of the jump, when his feet are tucked highest
		# (carried across evenly, from standing against it his feet were already coming down as they crossed)
		if ct <= float(mv["top"]):
			pos = (p["from"] as Vector3).lerp(p["mid"], clampf((ct - float(mv["off"])) / (float(mv["top"]) - float(mv["off"])), 0.0, 1.0))
		else:
			pos = (p["mid"] as Vector3).lerp(p["end"], clampf((ct - float(mv["top"])) / (float(mv["down"]) - float(mv["top"])), 0.0, 1.0))
	else:
		var z := _at(fwd, ct) - float(mv["at"])
		var out_by := float(p["to_mid"]) - (float(mv["at"]) - _at(fwd, from_t))
		if z < 0.0:
			z -= out_by * clampf(z / minf(_at(fwd, from_t) - float(mv["at"]), -0.01), 0.0, 1.0)
		pos = (p["mid"] as Vector3) + m * z
	# over an obstacle higher than the take clears by itself he is carried that much higher, and CLEAR_MORE more,
	# up as he leaves the ground and down again before he lands; over a lower one the take is left as it is
	var more := maxf(float(p["top"]) - float(mv["high"]), 0.0)
	if more > 0.0:
		more += CLEAR_MORE
	if air:
		pos.y += more * minf(smoothstep(float(mv["off"]), float(mv["off"]) + 0.12, ct), 1.0 - smoothstep(float(mv["top"]) + 0.2, float(mv["down"]), ct))
	var out := {"done": ct >= exit_t, "pos": pos, "clip_t": ct, "air": air, "free": air,
			"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0))}
	if not low:
		var hold := clampf(minf((ct - float(mv["hands_on"])) / HAND_FADE + 1.0, (float(mv["hands_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0)
		hold = hold * hold * (3.0 - 2.0 * hold)
		out["hand"] = [[0, (p["hands_at"] as Array)[0], hold], [1, (p["hands_at"] as Array)[1], hold]]
	if ct >= exit_t:
		out["pos"] = p["end"]
		out["exit"] = Vector3.ZERO
	return out


# ------------------------------------------------------------------------- the climb over a thin wall from standing

func _try_over(wish: Vector3, rec: Dictionary, air_ct := -1.0) -> bool:
	var top := float(rec["top"])
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(wish.normalized().angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at it"
		return false
	if not rec.has("landing") or absf(float(rec["landing"])) > LAND_LEVEL or not bool(rec.get("landing_ok", false)):
		refused = "the ground beyond it is not level with his, or has no room"
		return false
	var depth := float(rec["depth"])
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	if air_ct < 0.0 and here > OVER_NEAR:
		refused = "coming up to it"
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var mid := feet + m * (here + depth * 0.5)
	mid.y = ground + top
	# (begun in the air he is already higher, and his knees come up sooner: 5 cm further back, found in the lab)
	var back := Vector3(feet.x, ground, feet.z) - m * maxf(OVER_BACK + (0.05 if air_ct >= 0.0 else 0.0) - here, 0.0)
	if air_ct < 0.0 and not bool(detector.call(&"_fits", back, float(body.get(&"HEIGHT")))):
		refused = "no room behind him to jump up from"
		return false
	# the far side: the step off of stage 8, from the top of the wall
	var mv: Dictionary = MOVES["walk"]
	var fwd: PackedFloat32Array = _fwd["walk"]
	var leave := mid + m * (depth * 0.5 + 0.15)                 # NOT in the study: his hips this far past the far edge as his feet leave it
	var down := leave + m * (_at(fwd, float(mv["down"])) - _at(fwd, float(mv["leaves"])))
	var end := down + m * (_at(fwd, float(mv["exit"])) - _at(fwd, float(mv["down"])))
	for p: Vector3 in [down, end]:
		var g: Dictionary = body.call(&"probe", Vector3(p.x, ground, p.z))
		if not bool(g["hit"]) or absf(float(g["y"]) - ground) > LAND_LEVEL or not bool(detector.call(&"_fits", Vector3(p.x, float(g["y"]), p.z), float(body.get(&"HEIGHT")))):
			refused = "no level, free ground to land on"
			return false
	refused = ""
	var share := clampf(top / float(mv["native"]), 0.0, 1.0)
	var left := Vector3.UP.cross(m).normalized()
	var on_top := Vector3(mid.x, ground + top + PALM, mid.z) - m * (depth * 0.5 - 0.01)       # on its near edge
	_plan = {"key": "climb_over", "drop_key": "walk", "a_from": Vector3(feet.x, ground, feet.z), "a_back": back, "a_yaw0": body.rotation.y,
			"mid": mid, "top": top, "ground": ground,
			"from": mid, "leave": Vector3(leave.x, ground + top, leave.z), "down": Vector3(down.x, ground, down.z), "end": Vector3(end.x, ground, end.z),
			"m": m, "yaw0": atan2(-m.x, -m.z), "yaw1": atan2(-m.x, -m.z), "drop": top,
			"t_step": float(mv["leaves"]) - float(mv["from"]), "t_air": sqrt(2.0 * top / float(body.get(&"GRAVITY"))),
			"t_rest": (float(mv["exit"]) - float(mv["down"])) * lerpf(REST_LEAST, 1.0, share), "soft": 1.0 - share,
			"exit_speed": (_at(fwd, float(mv["exit"])) - _at(fwd, float(mv["exit"]) - 0.2)) / 0.2, "hand": 2,
			"hands_at": _hands(on_top, left, float(OVER["hand_side"]), rec)}
	if air_ct >= 0.0:
		_plan.merge({"air": true, "from_t": air_ct, "hands_on": air_ct, "y_from": feet.y})
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _over, String(OVER["input"]))
	return true


func _over(t: float) -> Dictionary:
	var p := _plan
	var from_t := float(p.get("from_t", OVER["from"]))
	var top_t := float(OVER["top"])
	if t >= top_t - from_t:
		if not p.has("a_done"):
			p["a_done"] = true
			p["from"] = body.global_position        # the step off begins where the climb has brought him
			# On top of it: with the stick let go he stays there, standing on it (a wall top is walked like a beam,
			# stage 17); with it still held he goes on over, as before. Yasin, 26 Nov: "he couldnt walk on teh
			# walls, only on beams".
			p["stay"] = not bool(body.get(&"stick_held"))
		if bool(p["stay"]):
			var cs := minf(from_t + t, float(MANTLE["exit"]))
			var mid_s: Vector3 = p["mid"]
			var here_s := Vector3(mid_s.x, _climb_y(p, cs, t), mid_s.z)
			var done_s := cs >= float(MANTLE["exit"])
			var out_s := {"done": done_s, "pos": mid_s if done_s else here_s, "clip_t": cs, "clip": String(OVER["input"]), "air": false,
					"free": false, "base": (float(p["ground"]) + float(p["top"]) - here_s.y), "yaw": float(p["yaw1"])}
			if done_s:
				out_s["exit"] = Vector3.ZERO
			return out_s
		var r := _step_off(t - (top_t - from_t))
		r["clip"] = String(MOVES["walk"]["input"])
		return r
	var ct := from_t + t
	var u := smoothstep(float(OVER_ACROSS[0]), float(OVER_ACROSS[1]), ct)
	# first back to where the jump is made from (0.2 s), then up, then in over the top
	var a: Vector3 = (p["a_from"] as Vector3).lerp(p["a_back"], smoothstep(0.0, 0.2, t))
	var mid: Vector3 = p["mid"]
	var pos := Vector3(lerpf(a.x, mid.x, u), _climb_y(p, ct, t), lerpf(a.z, mid.z, u))
	# both hands on the top from as he sinks for the jump until he has risen past the reach of his arms
	var hold := clampf(minf((ct - float(p.get("hands_on", OVER["hands_on"]))) / HAND_FADE + 1.0, (float(OVER["hands_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0)
	hold = hold * hold * (3.0 - 2.0 * hold)
	return {"done": false, "pos": pos, "clip_t": ct, "clip": String(OVER["input"]), "air": false,
			"free": ct > 1.25 and ct < FEET_FROM, "base": (float(p["ground"]) + float(p["top"]) - pos.y) if ct >= FEET_FROM else 0.0,
			"yaw": lerp_angle(float(p["a_yaw0"]), float(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0)),
			"hand": [[0, (p["hands_at"] as Array)[0], hold], [1, (p["hands_at"] as Array)[1], hold]]}


# ------------------------------------------------------------------------------------------------ stage 12: the mantle

## Something deep of 1.10 to 1.45 m with room to stand on it: both hands on its top, up onto it, standing.
func _try_mantle(v: Vector3, wish: Vector3, rec: Dictionary, air_ct := -1.0) -> bool:
	var top := float(rec["top"])
	if bool(rec["blocked"]) or not bool(rec["stand_room"]):
		refused = "no room to stand on top"
		return false
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(wish.normalized().angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at it"
		return false
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	var moving := v.length() > 0.5 and air_ct < 0.0
	var exit_t := float(MANTLE["exit"])
	var edge_at := float(MANTLE["edge"])
	var from_t := float(OVER["from"])
	var hands_on := float(OVER["hands_on"])
	if moving and here > OVER_NEAR:
		# come at on the move: the take from its own run in, taken up where it is as far from its edge as he is
		# from his. (Nearer than it is as it pushes off, he walks on up to the wall and it is made as from standing.)
		if here > edge_at - _at(_o_fwd, 0.0) + v.length() * EARLY:
			refused = "coming up to the mantle"
			return false
		if here < edge_at - _at(_o_fwd, from_t) - 0.05:
			refused = "coming up to it"
			return false
		from_t = 0.0
		while from_t < float(OVER["from"]) and edge_at - _at(_o_fwd, from_t) > here:
			from_t += 1.0 / 60.0
		# the hands come down on the top when he is near enough to it for his arms
		hands_on = from_t
		while hands_on < float(OVER["hands_off"]) and here - (_at(_o_fwd, hands_on) - _at(_o_fwd, from_t)) > OVER_BACK + 0.02:
			hands_on += 1.0 / 60.0
	elif moving:
		moving = false
	elif air_ct < 0.0 and here > OVER_NEAR:
		refused = "coming up to it"
		return false
	var inward := _at(_o_fwd, exit_t) - edge_at
	if float(rec["depth"]) < inward + float(body.get(&"RADIUS")):
		refused = "the top is not deep enough to stand on"
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var end := feet + m * (here + inward)
	end.y = ground + top
	if not bool(detector.call(&"_fits", end, float(body.get(&"HEIGHT")))):
		refused = "no room where he would end"
		return false
	var back := Vector3(feet.x, ground, feet.z) + m * (here - OVER_BACK - (0.05 if air_ct >= 0.0 else 0.0))
	if air_ct >= 0.0:
		# (in the air too he comes back to where his knees clear the face: his hands are on the top by then)
		from_t = air_ct
		hands_on = air_ct
	if air_ct < 0.0 and not moving and here < OVER_BACK and not bool(detector.call(&"_fits", back, float(body.get(&"HEIGHT")))):
		refused = "no room behind him to jump up from"
		return false
	# at a run, where the top has room for it: out at a run
	var run_v := v.length() if (air_ct < 0.0 and wish.length() > float(body.get(&"WALK")) + 0.1 and v.length() > RUN_FROM) else 0.0
	var run_d := run_v * (float(RUN_OUT["mantle"][1]) - float(RUN_OUT["mantle"][0])) * 0.5
	if run_v > 0.0 and (float(rec["depth"]) < inward + run_d + float(body.get(&"RADIUS")) + 0.5 or not bool(detector.call(&"_fits", end + m * run_d, float(body.get(&"HEIGHT"))))):
		run_v = 0.0
	if run_v > 0.0:
		end += m * run_d
	refused = ""
	var left := Vector3.UP.cross(m).normalized()
	var on_top := feet + m * (here + 0.04)                      # 4 cm in from its edge
	on_top.y = ground + top + PALM
	_plan = {"key": "mantle", "moving": moving, "a_from": Vector3(feet.x, ground, feet.z), "a_back": back, "a_yaw0": body.rotation.y,
			"end": end, "top": top, "ground": ground, "m": m, "yaw1": atan2(-m.x, -m.z), "here": here, "from_t": from_t,
			"exit_speed": run_v, "run_d": run_d if run_v > 0.0 else 0.0, "hand": 2, "hands_on": hands_on,
			"hands_at": _hands(on_top, left, float(OVER["hand_side"]), rec)}
	if air_ct >= 0.0:
		_plan.merge({"air": true, "y_from": feet.y})
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _mantle, String(OVER["input"]))
	return true


func _mantle(t: float) -> Dictionary:
	var p := _plan
	var m: Vector3 = p["m"]
	var from_t := float(p["from_t"])
	var run_d := float(p.get("run_d", 0.0))
	var exit_t := float(RUN_OUT["mantle"][1]) if run_d > 0.0 else float(MANTLE["exit"])
	var ct := minf(from_t + t, exit_t)
	var a: Vector3 = p["a_from"]
	var end: Vector3 = (p["end"] as Vector3) - m * run_d       # where the take itself brings him
	var pos: Vector3
	var on := float(p["hands_on"])
	var back: Vector3 = p["a_back"]
	if bool(p["moving"]):
		# the take's own travel, as far as the place the rise is finished from (OVER_BACK from the face)
		back = a + m * minf(_at(_o_fwd, ct) - _at(_o_fwd, from_t), float(p["here"]) - OVER_BACK)
	else:
		# from standing against it: back to where the jump is made from
		back = a.lerp(back, smoothstep(0.0, 0.2, t))
	# up there, then in over the top once his knees and feet are above it (as the climb over)
	pos = back.lerp(end, smoothstep(float(MANTLE["across"][0]), float(MANTLE["across"][1]), ct))
	if run_d > 0.0:
		var gather := clampf((ct - float(RUN_OUT["mantle"][0])) / (float(RUN_OUT["mantle"][1]) - float(RUN_OUT["mantle"][0])), 0.0, 1.0)
		pos += m * (run_d * gather * gather)
	pos.y = _climb_y(p, ct, t)
	if run_d > 0.0:
		# (left before he has stood up: the body is brought the rest of the way to the top as he gathers pace)
		var g2 := clampf((ct - float(RUN_OUT["mantle"][0])) / (float(RUN_OUT["mantle"][1]) - float(RUN_OUT["mantle"][0])), 0.0, 1.0)
		pos.y = lerpf(pos.y, float(p["ground"]) + float(p["top"]), g2 * g2)
	var hold := clampf(minf((ct - on) / HAND_FADE + 1.0, (float(OVER["hands_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0)
	hold = hold * hold * (3.0 - 2.0 * hold)
	var out := {"done": ct >= exit_t, "pos": pos, "clip_t": ct, "air": false,
			"free": ct > 1.25 and ct < FEET_FROM, "base": (float(p["ground"]) + float(p["top"]) - pos.y) if ct >= FEET_FROM else 0.0,
			"yaw": lerp_angle(float(p["a_yaw0"]), float(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0)),
			"hand": [[0, (p["hands_at"] as Array)[0], hold], [1, (p["hands_at"] as Array)[1], hold]]}
	if ct >= exit_t:
		out["pos"] = p["end"]
		out["exit"] = m * float(p["exit_speed"])
	return out


## How high his feet are (world) at `ct` of the climb take, `t` seconds into the move. Up to the push off the body
## rises by the take's share of the height measured; from when his feet come down on the top it is as far under the
## top as the take is under its own, so that his feet are ON the top whatever its height (Yasin, 26 Nov: "foot is
## landing a little higher than the surface": over a top lower than the take's own 1.30 m the first way left them
## above it by the difference times what was left of the rise, 8 cm at 1.10 m). Begun in the air, from where he is.
func _climb_y(p: Dictionary, ct: float, t: float) -> float:
	var rise := _at(_o_rise, ct)
	var top := float(p["top"])
	var y := float(p["ground"]) + lerpf(top * rise, top - _o_high * (1.0 - rise), smoothstep(float(OVER["from"]), float(OVER["hands_off"]), ct))
	if p.has("y_from"):
		y = lerpf(float(p["y_from"]), y, smoothstep(0.0, 0.2, t))
	return y


# ------------------------------------------------------------------------------- a jump into a climb or over a wall

## In the air from a jump, at something he does not clear: the climb (deep) or the climb over (thin) is begun from
## where he is. Yasin, 26 Nov: "so far we cant combine jumps and climbs or vaults, those should be possible, add the
## numbers of the distance of our jumps to existing moves and enable them". Nothing new is measured for it: the
## bands are held to what is LEFT to climb from his feet, so a jump raises them by what the jump raises him (the
## body's own figures, the study's: "An average standing jump adds 0.41 to 0.50 m for men and a run-up typically
## 0.10 to 0.20 m more").
func _try_air(v: Vector3) -> bool:
	# (the way he is steering, or failing that the way he is going: jumped from standing against a wall he has no speed)
	var wish: Vector3 = body.get(&"_wish")
	if not bool(body.get(&"from_jump")):
		return false
	if _tick % 2 != 0:
		return false
	# (jumped on the spot with the stick at rest: the way he faces. Yasin, 26 Nov: "nothing happens when we jump near
	# from standing still to 2.20 walls and above")
	var dir := wish.normalized() if wish.length() >= 0.05 else (v.normalized() if v.length() >= 0.5 else -body.global_transform.basis.z)
	dir = Vector3(dir.x, 0.0, dir.z).normalized()
	# (measured as from the ground under him: see detector.gd)
	# (over a gap the ground under him is far down, or not there: looked for 6 m down, and failing that taken 3 m down)
	var here_p := body.global_position
	var q_down := PhysicsRayQueryParameters3D.create(here_p + Vector3(0.0, 0.6, 0.0), here_p - Vector3(0.0, 6.0, 0.0), body.collision_mask, [body.get_rid()])
	var below: Dictionary = body.get_world_3d().direct_space_state.intersect_ray(q_down)
	var under_y := (below["position"] as Vector3).y if not below.is_empty() else here_p.y - 3.0
	var rec: Dictionary = detector.call(&"measure", dir, under_y)
	if String(rec["kind"]) != "obstacle" or bool(rec["blocked"]) or float(rec["top"]) == INF:
		return false
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(dir.angle_to(m)) > MOST_OFF_DEG:
		return false
	var top := float(rec["top"])
	var feet_up := body.global_position.y - float(rec["ground"])
	var left := top - feet_up
	if left <= 0.05:
		return false                                            # he clears it, or lands on it, by himself
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	# near enough for his hands, and at the top of the jump or about to meet the wall
	# at a run, over something thin: the running vault, taken up in its own flight, its band raised by what the
	# running jump raises him (Yasin, 26 Nov: "jumping over 1.80 and run vault should still be possible if we are
	# running")
	if bool(rec["thin"]) and not bool(body.get(&"_jump_still")) and v.length() > RUN_FROM:
		if _try_vault(v, wish if wish.length() >= 0.05 else v, rec, float(body.get(&"JUMP_RISE_RUN"))):
			return true
	if here > OVER_BACK + 0.05 or float(body.get(&"vy")) > 0.5:
		return false
	# the bands with a jump: what the move takes from the ground, and what the jump raises him (the body's own two
	# figures, the study's 0.41 to 0.50 m and 0.10 to 0.20 m more from a run)
	var thin := bool(rec["thin"])
	var adds := float(body.get(&"JUMP_RISE") if bool(body.get(&"_jump_still")) else body.get(&"JUMP_RISE_RUN"))
	if feet_up < adds * 0.5:
		return false
	if top > float(VAULT_BAND[1] if thin else MANTLE_BAND[1]) + adds + MEASURED_WITHIN:
		# higher than the mantle reaches with the jump: the grab and climb, as far as it goes from the ground
		# (Yasin, 26 Nov: "walk or standing still jump climb should still be possible on 2.2 wall")
		# ... and with his own jump as much higher as it raises him, up to what can be climbed at all (the study:
		# "above 3.0 m | not climbable"; Yasin, 26 Nov: "fix it until 3m")
		if top > minf(float(HIGH_BAND[1]) + adds, NOT_ABOVE) + MEASURED_WITHIN:
			refused = "too high even with the jump (%.2f m)" % top
			return false
		return _try_grab(dir, rec, true)
	if top > float(VAULT_BAND[1] if thin else MANTLE_BAND[1]) + adds + MEASURED_WITHIN:
		refused = "too high even with the jump (%.2f m)" % top
		return false
	# the take is taken up as it pushes off (its knees still down: taken up later, they were in the wall); the body
	# is brought from where he is to the take's own height over the first 0.2 s
	var ct := float(OVER["from"])
	var begun := _try_over(dir, rec, ct) if thin else _try_mantle(v, dir, rec, ct)
	return begun


# ------------------------------------------------------------------------------------------ stage 13: the grab and climb

## Something deep of 1.45 to 2.10 m with room on top: a jump to its edge, both hands on it, feet braced on its
## face, and up onto it. `air` = begun in the air from a jump, as his hands go up.
func _try_grab(wish: Vector3, rec: Dictionary, air := false) -> bool:
	var top := float(rec["top"])
	# Something thin (Yasin, 26 Nov: "i meant thin walls"): up onto it the same way, then a step off its far side,
	# and he falls and lands as the body does from any edge (the heavy landing from that height).
	var thin := bool(rec["thin"])
	if bool(rec["blocked"]) or (not thin and not bool(rec["stand_room"])):
		refused = "no room on top"
		return false
	if thin and (not rec.has("landing") or absf(float(rec["landing"])) > LAND_LEVEL or not bool(rec.get("landing_ok", false))):
		refused = "the ground beyond it is not level with his, or has no room"
		return false
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(wish.normalized().angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at it"
		return false
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	if here > GRAB_NEAR:
		refused = "coming up to it"
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var hang := Vector3(feet.x, ground, feet.z) + m * (here - float(GRAB["hang_at"]))
	if not air and here < float(GRAB["hang_at"]) and not bool(detector.call(&"_fits", hang, float(body.get(&"HEIGHT")))):
		refused = "no room behind him to jump up from"
		return false
	var inward := _at(_g_fwd2, float(GRAB["exit"])) - float(GRAB["hang_at"])
	if not thin and float(rec["depth"]) < inward + float(body.get(&"RADIUS")):
		refused = "the top is not deep enough"
		return false
	# (onto something thin he ends on the middle of its top: off the middle he was not on it as on something narrow)
	var onto := float(rec["depth"]) * 0.5 if thin else inward
	var end := feet + m * (here + onto)
	end.y = ground + top
	if not thin and not bool(detector.call(&"_fits", end, float(body.get(&"CROUCH_HEIGHT")))):
		refused = "no room where he would end"
		return false
	var v_in: Vector3 = body.get(&"hvel")
	var w_in: Vector3 = body.get(&"_wish")
	var run_v := v_in.length() if (not air and not thin and w_in.length() > float(body.get(&"WALK")) + 0.1 and v_in.length() > RUN_FROM) else 0.0
	var run_d := run_v * (float(RUN_OUT["grab"][1]) - float(RUN_OUT["grab"][0])) * 0.5
	if run_v > 0.0 and (float(rec["depth"]) < inward + run_d + float(body.get(&"RADIUS")) + 0.5 or not bool(detector.call(&"_fits", end + m * run_d, float(body.get(&"HEIGHT"))))):
		run_v = 0.0
	if run_v > 0.0:
		end += m * run_d
	refused = ""
	var left := Vector3.UP.cross(m).normalized()
	var on_top := feet + m * (here + WRIST_IN)
	on_top.y = ground + top + WRIST_OVER
	_plan = {"key": "grab", "from": Vector3(feet.x, ground, feet.z), "hang": hang, "end": end, "top": top, "ground": ground, "m": m,
			"yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z), "exit_speed": run_v, "run_d": run_d if run_v > 0.0 else 0.0, "hand": 2, "onto_more": onto - inward,
			# the body's height in the hang: his wrists on the top
			"hang_y": ground + top + WRIST_OVER - float(GRAB["wrist"]) + float(GRAB["jump_by"]),
			"from_t": float(GRAB["off"]) + 0.08 if air else 0.0,
			"hands_at": _hands(on_top, left, float(GRAB["hand_side"]), rec)}
	if thin:
		var leave := feet + m * (here + float(rec["depth"]) + 0.22)        # NOT in the study: his hips this far past the far edge as his feet leave it
		leave.y = ground + top
		_plan.merge({"over": true, "leave": leave})
	if air:
		_plan.merge({"air": true, "y_from": feet.y})
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _grab, String(GRAB["jump"]))
	return true


func _grab(t: float) -> Dictionary:
	var p := _plan
	var m: Vector3 = p["m"]
	var from_t := float(p["from_t"])
	var t1 := float(GRAB["hang"]) - from_t                      # how long the jump to the hang is played
	var ground := float(p["ground"])
	var hang: Vector3 = p["hang"]
	var hold := 0.0
	var out := {"done": false, "air": true, "free": true, "yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0))}
	if t < t1:
		# the jump to the hang: to where he hangs as he sinks and leaves the ground, up by the take's own rise set
		# to bring his wrists to the top
		var ct := from_t + t
		var pos := (p["from"] as Vector3).lerp(hang, smoothstep(0.0, 0.15, t))
		pos.y = ground + (float(p["hang_y"]) - ground) * _at(_g_rise1, ct)
		if p.has("y_from"):
			pos.y = lerpf(float(p["y_from"]), pos.y, smoothstep(0.0, float(GRAB["catch"]) - from_t, t))
		out.merge({"pos": pos, "clip_t": ct, "clip": String(GRAB["jump"]), "air": ct >= float(GRAB["off"])})
		hold = clampf((ct - float(GRAB["catch"])) / HAND_FADE + 1.0, 0.0, 1.0)
	else:
		# the climb from the hang: by the hands as it begins (his wrists on the top), by the feet as it ends (on the top)
		var ct := minf(t - t1, float(GRAB["exit"]))
		var rise := _at(_g_rise2, ct)
		var by := float(GRAB["climb_by"])
		var out_by := by + WRIST_OVER - float(GRAB["climb_wrist"])      # how far the clip's own start and end disagree about its ledge
		var run_d := float(p.get("run_d", 0.0))
		var gather := clampf((ct - float(RUN_OUT["grab"][0])) / (float(RUN_OUT["grab"][1]) - float(RUN_OUT["grab"][0])), 0.0, 1.0)
		var pos := hang + m * (_at(_g_fwd2, ct) + run_d * gather * gather + float(p.get("onto_more", 0.0)) * smoothstep(float(GRAB["feet_on"]), float(GRAB["exit"]), ct))
		pos.y = ground + float(p["top"]) - (by - out_by) * (1.0 - rise)
		# (from when his feet come down on the top they are fitted to it, as in the mantle)
		var feet_down := ct >= float(GRAB["feet_on"])
		out.merge({"pos": pos, "clip_t": ct, "clip": String(GRAB["climb"]), "free": not feet_down, "base": (ground + float(p["top"]) - pos.y) if feet_down else 0.0}, true)
		hold = clampf((float(GRAB["feet_on"]) - ct) / HAND_FADE + 1.0, 0.0, 1.0)
		if ct >= float(GRAB["exit"]) and bool(p.get("over", false)) and not p.has("stay"):
			p["stay"] = not bool(body.get(&"stick_held"))       # (as the climb over: let go of the stick, he stays on top)
		if ct >= float(GRAB["exit"]) and bool(p.get("over", false)) and not bool(p["stay"]):
			# something thin: the step off its far side (the first part of the stage 8 take), then the fall is the body's
			var mv: Dictionary = MOVES["walk"]
			var span := float(mv["leaves"]) - float(mv["from"])
			var u := clampf((t - t1 - float(GRAB["exit"])) / span, 0.0, 1.0)
			out.merge({"pos": (p["end"] as Vector3).lerp(p["leave"], u), "clip": String(mv["input"]), "clip_t": lerpf(float(mv["from"]), float(mv["leaves"]), u), "air": false, "free": false, "landed": true}, true)
			if u >= 1.0:
				out["done"] = true
				out["exit"] = m * ((_at(_fwd["walk"], float(mv["leaves"])) - _at(_fwd["walk"], float(mv["from"]))) / span)
		elif ct >= float(GRAB["exit"]) and float(p.get("run_d", 0.0)) <= 0.0:
			# ended crouched and not at a run: he stands up with the clip for it (his own crouch-to-stand take, at
			# twice its pace), not by a blend back to standing
			var u := clampf((t - t1 - float(GRAB["exit"])) / STAND_UP_TIME, 0.0, 1.0)
			out.merge({"pos": p["end"], "clip": "crouch_up", "clip_t": lerpf(float(STAND_UP[0]), float(STAND_UP[1]), u), "air": false, "free": false, "landed": true, "base": 0.0}, true)
			if u >= 1.0:
				out["done"] = true
				out["exit"] = Vector3.ZERO
		elif ct >= float(GRAB["exit"]):
			out["done"] = true
			out["air"] = false
			out["pos"] = p["end"]
			out["exit"] = m * float(p["exit_speed"])
	hold = hold * hold * (3.0 - 2.0 * hold)
	var grip: Vector3 = -m * ((GRIP_OUT + WRIST_IN) * (1.0 - (smoothstep(float(GRIP_TURN[0]), float(GRIP_TURN[1]), t - t1) if t >= t1 else 0.0)))
	out["hand"] = [[0, (p["hands_at"] as Array)[0] + grip, hold, true], [1, (p["hands_at"] as Array)[1] + grip, hold, true]]
	return out


# -------------------------------------------------------------------------------------------- the running wall climb

func _try_wallrun(v: Vector3, wish: Vector3, rec: Dictionary) -> bool:
	var top := float(rec["top"])
	if bool(rec["blocked"]) or not bool(rec["stand_room"]):
		return false
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(wish.normalized().angle_to(m)) > MOST_OFF_DEG:
		return false
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	var face := float(WALLRUN["face"])
	# taken up where the take is as far from its wall as he is from his, and no later than its last step
	var least := face - _at(_w_fwd, float(WALLRUN["from_most"]))
	if here > face - _at(_w_fwd, 0.0) + v.length() * EARLY:
		refused = "coming up to the wall climb"
		return false
	if here < least - 0.15:
		return false                                            # too near for it already: the grab and climb will take it
	var from_t := 0.0
	while from_t < float(WALLRUN["from_most"]) and face - _at(_w_fwd, from_t) > here:
		from_t += 1.0 / 60.0
	var exit_t := float(WALLRUN["exit"])
	var inward := _at(_w_fwd, exit_t) - face
	var feet := body.global_position
	var ground := float(rec["ground"])
	var end := feet + m * (here + inward)
	end.y = ground + top
	var run_v := v.length()
	var run_d := run_v * (float(WALLRUN["run_out"][1]) - float(WALLRUN["run_out"][0])) * 0.5
	if float(rec["depth"]) < inward + run_d + float(body.get(&"RADIUS")) + 0.5 or not bool(detector.call(&"_fits", end + m * run_d, float(body.get(&"HEIGHT")))):
		run_v = 0.0
		run_d = 0.0
		if float(rec["depth"]) < inward + float(body.get(&"RADIUS")) or not bool(detector.call(&"_fits", end, float(body.get(&"CROUCH_HEIGHT")))):
			return false
	refused = ""
	var left := Vector3.UP.cross(m).normalized()
	var on_top := feet + m * (here + WRIST_IN)
	on_top.y = ground + top + WRIST_OVER
	_plan = {"key": "wallrun", "from": Vector3(feet.x, ground, feet.z), "end": end + m * run_d, "top": top, "ground": ground, "m": m,
			"yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z), "exit_speed": run_v, "run_d": run_d, "hand": 2, "from_t": from_t,
			# (the little he is out by as it begins is taken up over the run in)
			"stretch": (here + inward) / maxf(_at(_w_fwd, exit_t) - _at(_w_fwd, from_t), 0.01),
			"hands_at": _hands(on_top, left, float(WALLRUN["hand_side"]), rec)}
	plays += 1
	_up_record = {}
	record = {}
	body.call(&"begin_move", _wallrun, String(WALLRUN["input"]))
	return true


func _wallrun(t: float) -> Dictionary:
	var p := _plan
	var m: Vector3 = p["m"]
	var from_t := float(p["from_t"])
	var exit_t := float(WALLRUN["exit"])
	var ct := minf(from_t + t, exit_t)
	var top := float(p["top"])
	var high := float(WALLRUN["high"])
	var rise := _at(_w_rise, ct)
	var run_d := float(p["run_d"])
	var gather := clampf((ct - float(WALLRUN["run_out"][0])) / (float(WALLRUN["run_out"][1]) - float(WALLRUN["run_out"][0])), 0.0, 1.0)
	var pos := (p["from"] as Vector3) + m * ((_at(_w_fwd, ct) - _at(_w_fwd, from_t)) * float(p["stretch"]) + run_d * gather * gather)
	# up: by the take's share of the height until his foot is on the wall; by the time his hands come down he is
	# as far under the top as the take is under its own (so the hands are on the top whatever its height)
	pos.y = float(p["ground"]) + lerpf(top * rise, top - high * (1.0 - rise), smoothstep(float(WALLRUN["kick"]), float(WALLRUN["hands_on"]), ct))
	var hold := clampf(minf((ct - float(WALLRUN["hands_on"])) / HAND_FADE + 1.0, (float(WALLRUN["hands_off"]) - ct) / HAND_FADE + 1.0), 0.0, 1.0)
	hold = hold * hold * (3.0 - 2.0 * hold)
	var turn: Array = WALLRUN["grip_turn"]
	var grip: Vector3 = -m * ((float(WALLRUN["grip_out"]) + WRIST_IN) * (1.0 - smoothstep(float(turn[0]), float(turn[1]), ct)))
	var out := {"done": ct >= exit_t, "pos": pos, "clip_t": ct, "air": ct >= float(WALLRUN["kick"]) and ct < float(WALLRUN["hands_off"]), "free": true,
			"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0)),
			"hand": [[0, (p["hands_at"] as Array)[0] + grip, hold, true], [1, (p["hands_at"] as Array)[1] + grip, hold, true]]}
	if ct >= exit_t:
		out["air"] = false
		out["pos"] = p["end"]
		out["exit"] = m * float(p["exit_speed"])
	return out


# ------------------------------------------------------------------------------- stage 15: turn, hang and drop

func _at2(table: PackedVector2Array, t: float) -> Vector2:
	var f := clampf(t * _fps, 0.0, float(table.size() - 1))
	var i := mini(int(f), table.size() - 2)
	return table[i].lerp(table[i + 1], f - float(i))


func _try_climb_down(dir: Vector3, drop: float) -> bool:
	var m: Vector3 = -(record["normal"] as Vector3)
	if rad_to_deg(dir.angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading at the edge"
		return false
	var here := (record["edge"] as Vector3 - body.global_position).dot(m)
	if here > DOWN_NEAR:
		refused = "coming up to the edge"
		return false
	var feet := body.global_position
	var top_y := float(record["ground"])
	var land_y := top_y - drop
	# the take is laid with its wall face on the edge: he kneels with the drop on his left, so he faces along the edge
	var fwd := m.cross(Vector3.UP).normalized()                 # the way the take faces as it begins (his left is then m)
	var start := feet + m * (here - float(DOWN["face"]))
	start.y = top_y
	var last := _d_xz[_d_xz.size() - 1]
	# (he comes down DOWN_OUT from the face: nearer, the knees of the landing were in the wall)
	var end := start + m * (float(DOWN["face"]) + DOWN_OUT) + fwd * last.y
	end.y = land_y
	var g: Dictionary = body.call(&"probe", Vector3(end.x, land_y, end.z))
	if not bool(g["hit"]) or absf(float(g["y"]) - land_y) > LAND_WITHIN or not bool(detector.call(&"_fits", Vector3(end.x, land_y, end.z), float(body.get(&"HEIGHT")))):
		refused = "no level, free ground under the edge to come down on"
		return false
	refused = ""
	var hl: Array = DOWN["hand_l"]
	var hr: Array = DOWN["hand_r"]
	_plan = {"key": "climb_down", "from": feet, "start": start, "end": end, "m": m, "fwd": fwd, "top_y": top_y, "land_y": land_y, "drop": drop,
			"yaw0": body.rotation.y, "yaw1": atan2(-fwd.x, -fwd.z), "yaw_end": atan2(m.x, m.z), "exit_speed": 0.0, "hand": 2,
			# after he lets go: the fall that is left with his feet hanging HANG_FEET under the ledge, and its landing
			"t_air": sqrt(2.0 * maxf(drop - HANG_FEET, 0.0) / float(body.get(&"GRAVITY"))),
			"land": LAND_HARD if drop - HANG_FEET > float(BAND[1]) else LAND_SOFT,
			"hands_at": [start + m * float(hl[0]) + Vector3.UP * float(hl[1]) + fwd * float(hl[2]),
					start + m * float(hr[0]) + Vector3.UP * float(hr[1]) + fwd * float(hr[2])]}
	plays += 1
	record = {}
	_up_record = {}
	body.call(&"begin_move", _climb_down, String(DOWN["input"]))
	return true


func _climb_down(t: float) -> Dictionary:
	var p := _plan
	var off := float(DOWN["hands_off"])
	var m: Vector3 = p["m"]
	var start: Vector3 = p["start"]
	if t <= off:
		# on the ledge and lowering himself, his hands on it: the take's own, as far under the ledge as the take is
		var xz := _at2(_d_xz, t)
		var pos := start + m * xz.x + (p["fwd"] as Vector3) * xz.y
		pos = (p["from"] as Vector3).lerp(pos, smoothstep(0.0, 0.3, t))        # first to where the take kneels
		pos.y = float(p["top_y"]) - float(DOWN["high"]) * _at(_d_fall, t)
		# (NOT in the study, found in the lab: as the kneel comes in over the crouch he was in, his knee passed up to
		# 6 cm into the ledge for a few ticks; he is held that much higher while it does)
		pos.y += 0.07 * smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(0.15, 0.35, t))
		var hold := clampf(minf((t - float(DOWN["hands_on"])) / HAND_FADE + 1.0, (off - t) / HAND_FADE + 1.0), 0.0, 1.0)
		hold = hold * hold * (3.0 - 2.0 * hold)
		return {"done": false, "pos": pos, "clip_t": t, "air": false,
				# (his feet are fitted to the ledge while he kneels down on it; after that they are the take's own)
				"free": t > 0.60, "landed": t <= 0.60,
				# he is turned to face along the edge as he kneels; the turn to the wall is in the take itself
				"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), smoothstep(0.0, 0.3, t)),
				"hand": [[0, (p["hands_at"] as Array)[0], hold], [1, (p["hands_at"] as Array)[1], hold]]}
	# He has let go (Yasin, 26 Nov: "it looks like he is hanging in the air when climbing down ... just let the hands
	# go once he is off the wall": the take keeps his arms up at its own ledge until he has landed). From here it is
	# the fall and the landing he makes from any height: his own falling-to-landing take, or the hard landing from
	# higher, the body falling as long as the height left takes.
	var tau := t - off
	var land: Dictionary = p["land"]
	var t_air := float(p["t_air"])
	var xz0 := _at2(_d_xz, off)
	var from := start + m * xz0.x + (p["fwd"] as Vector3) * xz0.y
	var pos2 := from.lerp(p["end"], smoothstep(0.0, 0.20, tau))          # out from the wall as he lets go
	var y_let := float(p["top_y"]) - float(DOWN["high"]) * _at(_d_fall, off)         # where the body was as he let go
	var y_fall := maxf(float(p["land_y"]), float(p["top_y"]) - HANG_FEET - 0.5 * float(body.get(&"GRAVITY")) * tau * tau)
	pos2.y = lerpf(y_let, y_fall, smoothstep(0.0, 0.12, tau))
	var down := tau >= t_air
	var ct := maxf(float(land["touch"]) - (t_air - tau), 0.0) if not down else minf(float(land["touch"]) + (tau - t_air), float(land["exit"]))
	var done := down and ct >= float(land["exit"])
	var out := {"done": done, "pos": pos2, "clip": String(land["input"]), "clip_t": ct, "air": not down, "free": not down, "landed": down,
			"landing": String(land["kind"]),
			"yaw": lerp_angle(float(p["yaw1"]), float(p["yaw_end"]), smoothstep(0.0, 0.15, tau))}
	if done:
		out["pos"] = p["end"]
		out["exit"] = Vector3.ZERO
	return out



# ------------------------------------------------------------------------------------------- stage 16: across a gap

func _try_gap(v: Vector3, dir: Vector3, rec: Dictionary, running: bool) -> bool:
	var m: Vector3 = -(rec["normal"] as Vector3)
	if rad_to_deg(dir.angle_to(m)) > MOST_OFF_DEG:
		refused = "not heading across it"
		return false
	if bool(rec.get("far_wall", false)) or not rec.has("landing") or not bool(rec.get("landing_ok", false)):
		refused = "no far side to come down on"
		return false
	var gap := float(rec["gap"])
	var landing := float(rec["landing"])             # the far side against his own ground: + = higher
	# A shallow gap (no deeper than what he walks down and up by himself, 0.30 m) is not jumped. Yasin, 26 Nov: "let
	# him just walk longer steps, only if necessary, and just keep running if running thru shallow gaps". At a run
	# nothing is begun; at a walk a longer step across it where one step spans it, else he walks through it.
	var shallow := float(rec.get("drop", INF)) <= float(UP_BAND[0]) + MEASURED_WITHIN and landing <= float(UP_BAND[0]) + MEASURED_WITHIN
	if shallow and (running or gap > STEP_ACROSS * LEG + MEASURED_WITHIN):
		refused = ""
		return false
	var here := (rec["edge"] as Vector3 - body.global_position).dot(m)
	var rad := float(body.get(&"RADIUS"))
	if running:
		# the body's own running jump, begun so that he leaves the ground GAP_OFF before the edge. It clears the gap
		# if he is still over the far top when he is past its edge.
		var g := float(body.get(&"GRAVITY"))
		var rise := float(body.get(&"JUMP_RISE_RUN"))
		var vy0 := sqrt(2.0 * g * rise)
		var pace := maxf(v.length(), 0.1)
		var t_far := (GAP_OFF + gap + rad + GAP_ON) / pace
		var catching := false
		if vy0 * t_far - 0.5 * g * t_far * t_far < landing:
			# it does not. If he gets to its far face with his feet no further under the top than the mantle
			# takes, he jumps for the edge: he catches it and climbs up (the mantle begun in the air does that).
			# Yasin, 26 Nov: "for gaps longer than 2m, if we can reach, cwe should catch the edge and climb up".
			var t_face := (GAP_OFF + gap - OVER_BACK) / pace
			var y_face := vy0 * t_face - 0.5 * g * t_face * t_face
			if landing - y_face > float(MANTLE_BAND[1]) - 0.10:
				refused = "too wide for the running jump, and the far edge is out of reach (%.2f m)" % gap
				return false
			catching = true
		var push := v.length() * float(body.get(&"JUMP_PUSH_RUN"))
		if here > GAP_OFF + push + v.length() / 60.0:
			refused = "coming up to the gap"
			return false
		refused = ""
		if bool(body.call(&"start_jump")):
			plays += 1
			_plan = {"key": "gap_catch" if catching else "gap_run", "gap": gap}
			return true
		return false
	var feet := body.global_position
	var ground := float(rec["ground"])
	var end := feet + m * (here + gap + rad + GAP_ON)
	end.y = ground + landing
	if gap <= STEP_ACROSS * LEG + MEASURED_WITHIN and absf(landing) <= float(UP_BAND[0]) + MEASURED_WITHIN:
		# stepped across in stride (a far side up to 0.30 m higher or lower: what he walks onto or down from by
		# himself): the walk itself is shown, the body is carried over it at the pace he has
		if not bool(detector.call(&"_fits", end, float(body.get(&"HEIGHT")))):
			refused = "no room on the far side"
			return false
		if here > 0.10 + v.length() / 60.0 * float(AGAIN):
			refused = "coming up to the gap"
			return false
		refused = ""
		var pace_w := maxf(v.length(), 0.8)
		_plan = {"key": "gap_step", "from": Vector3(feet.x, ground, feet.z), "end": end, "m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z),
				"time": (end - feet).dot(m) / pace_w, "exit_speed": pace_w, "gap": gap}
		plays += 1
		_up_record = {}
		body.call(&"begin_move", _gap_step, "ground")
		return true
	# jumped: onto a far side up to GAP_UP higher or GAP_DOWN lower. Wider than the long jump, or onto a higher far
	# side, he jumps for its edge: carried to within reach of it, his feet under its top, and let go there in the
	# air as from a jump; the mantle begun in the air catches the edge and climbs up.
	var catching_w := gap > LONG_JUMP + MEASURED_WITHIN or landing > GAP_UP + MEASURED_WITHIN
	if gap > LONG_JUMP + CATCH_REACH + MEASURED_WITHIN or landing - CATCH_UNDER > float(body.get(&"JUMP_RISE")) or landing < -GAP_DOWN - MEASURED_WITHIN:
		refused = "too wide, too high or too far down to jump from a walk (%.2f m across, far side %+.2f m)" % [gap, landing]
		return false
	if catching_w:
		end = feet + m * (here + gap - OVER_BACK)
		end.y = ground + landing - CATCH_UNDER
	elif not bool(detector.call(&"_fits", end, float(body.get(&"HEIGHT")))):
		refused = "no room on the far side"
		return false
	if here > 0.35:
		refused = "coming up to the gap"
		return false
	refused = ""
	var off := feet + m * maxf(here - GAP_OFF, 0.0)
	off.y = ground
	_plan = {"key": "gap_jump", "from": Vector3(feet.x, ground, feet.z), "off": off, "end": end, "m": m, "yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z),
			"exit_speed": 0.0, "gap": gap, "catch": catching_w}
	plays += 1
	_up_record = {}
	body.call(&"begin_move", _gap_jump, String(JUMP["input"]))
	return true


func _gap_step(t: float) -> Dictionary:
	var p := _plan
	var u := clampf(t / float(p["time"]), 0.0, 1.0)
	var out := {"done": u >= 1.0, "pos": (p["from"] as Vector3).lerp(p["end"], u), "clip_t": 0.0, "air": false, "free": true,
			"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.15, 0.0, 1.0))}
	if u >= 1.0:
		out["exit"] = (p["m"] as Vector3) * float(p["exit_speed"])
	return out


func _gap_jump(t: float) -> Dictionary:
	var p := _plan
	var from_t := float(JUMP["from"])
	var exit_t := float(JUMP["exit"])
	var ct := minf(from_t + t, exit_t)
	var off_t := float(JUMP["off"])
	var down_t := float(JUMP["down"])
	var air := ct >= off_t and ct < down_t
	# to his take-off place as he sinks, across while he is in the air, at an even pace
	var pos := (p["from"] as Vector3).lerp(p["off"], smoothstep(0.0, off_t - from_t, t))
	if ct >= off_t:
		pos = (p["off"] as Vector3).lerp(p["end"], clampf((ct - off_t) / (down_t - off_t), 0.0, 1.0))
	if bool(p.get("catch", false)):
		# let go in the air within reach of the far edge, moving at it: as from a jump of his own
		if ct >= down_t - 0.10:
			_catch_next = 3
			return {"done": true, "pos": pos, "clip_t": ct, "air": true, "free": true, "yaw": float(p["yaw1"]), "exit": (p["m"] as Vector3) * 1.5}
	var out := {"done": ct >= exit_t, "pos": pos, "clip_t": ct, "air": air, "free": air, "landed": ct >= down_t,
			"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), clampf(t / 0.2, 0.0, 1.0))}
	if ct >= exit_t:
		out["pos"] = p["end"]
		out["exit"] = Vector3.ZERO
	return out


# -------------------------------------------------------------------------------- losing his balance on something narrow

func _try_balance_fall() -> bool:
	var feet := body.global_position
	var face := -body.global_transform.basis.z
	face = Vector3(face.x, 0.0, face.z).normalized()
	var last := _b_xz[_b_xz.size() - 1]
	# from under 3.1 m: off the side onto his feet, a hard landing 0.7 m out (found first, as it needs less room)
	for way: float in [1.0, -1.0]:
		var m0 := face.cross(Vector3.UP).normalized() * way
		var e0 := feet + m0 * BALANCE_OUT
		var g0: Dictionary = body.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(e0 + Vector3(0.0, 0.5, 0.0), e0 - Vector3(0.0, 6.0, 0.0), body.collision_mask, [body.get_rid()]))
		if g0.is_empty():
			continue
		var gy0 := (g0["position"] as Vector3).y
		if gy0 > feet.y - 0.05 or feet.y - gy0 >= HARD_FALL_FROM or not bool(detector.call(&"_fits", Vector3(e0.x, gy0, e0.z), float(body.get(&"HEIGHT")))):
			continue
		refused = ""
		_plan = {"key": "balance_land", "on_feet": true, "from": feet, "end": Vector3(e0.x, gy0, e0.z), "m": m0, "top_y": feet.y, "land_y": gy0,
				"yaw0": body.rotation.y, "yaw1": atan2(-m0.x, -m0.z), "exit_speed": 0.0}
		plays += 1
		record = {}
		_up_record = {}
		body.call(&"begin_move", _balance_fall, String(BALANCE["input"]))
		return true
	# to the side that has ground and room where he would lie (he goes over forward, so he is turned to it first);
	# the take goes 3.4 m on: where there is no room for that, less far
	for reach: float in [1.0, 0.8, 0.65]:
		for way: float in [1.0, -1.0]:
			var m := face.cross(Vector3.UP).normalized() * way
			var end := feet + m * (last.y * reach)
			var q := PhysicsRayQueryParameters3D.create(end + Vector3(0.0, 0.5, 0.0), end - Vector3(0.0, 6.0, 0.0), body.collision_mask, [body.get_rid()])
			var hit: Dictionary = body.get_world_3d().direct_space_state.intersect_ray(q)
			if hit.is_empty():
				continue
			var gy := (hit["position"] as Vector3).y
			if gy > feet.y - 0.05:
				continue                                        # not lower than where he stands: no fall that way
			var ok := true
			# (room for the whole of him lying there: his head 0.6 m beyond his hips, his feet 1.0 m behind them)
			for along: float in [0.7, 0.0, -0.6, -1.1]:
				var at := end + m * along
				var g: Dictionary = body.call(&"probe", Vector3(at.x, gy, at.z))
				if not bool(g["hit"]) or absf(float(g["y"]) - gy) > LAND_LEVEL or not bool(detector.call(&"_fits", Vector3(at.x, gy, at.z), float(body.get(&"CROUCH_HEIGHT")))):
					ok = false
			if not ok:
				continue
			refused = ""
			_plan = {"key": "balance_fall", "from": feet, "end": Vector3(end.x, gy, end.z), "m": m, "top_y": feet.y, "land_y": gy, "reach": reach,
					"yaw0": body.rotation.y, "yaw1": atan2(-m.x, -m.z), "exit_speed": 0.0}
			plays += 1
			record = {}
			_up_record = {}
			body.call(&"begin_move", _balance_fall, String(BALANCE["input"]))
			return true
	return false


func _balance_fall(t: float) -> Dictionary:
	var p := _plan
	var from_t := float(BALANCE["from"])
	var fall_len := float(BALANCE["end"]) - from_t
	var m: Vector3 = p["m"]
	if bool(p.get("on_feet", false)):
		# From under 3.1 m he does not go down on his face: he wobbles, drops off the side and lands hard on his feet
		# (Yasin, 26 Nov: "make him hard land instead of a hard fall when falling from lower than 3.1 meters and if
		# above hard fall"). The wobble of the same take, then his own hard landing take, the body falling for as
		# long as the height takes.
		var wob := float(BALANCE["over"]) - from_t
		if t < wob:
			return {"done": false, "pos": p["from"], "clip_t": from_t + t, "air": false, "free": true,
					"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), smoothstep(0.0, 1.0, t))}
		var tau := t - wob
		var drop_h := float(p["top_y"]) - float(p["land_y"])
		var t_air := sqrt(2.0 * drop_h / float(body.get(&"GRAVITY")))
		var pos := (p["from"] as Vector3).lerp(p["end"], smoothstep(0.0, maxf(t_air, 0.25), tau))
		pos.y = maxf(float(p["land_y"]), float(p["top_y"]) - 0.5 * float(body.get(&"GRAVITY")) * tau * tau)
		var down := tau >= t_air
		var ct := maxf(float(LAND_HARD["touch"]) - (t_air - tau), 0.0) if not down else minf(float(LAND_HARD["touch"]) + (tau - t_air), float(LAND_HARD["exit"]))
		var fin := down and ct >= float(LAND_HARD["exit"])
		var o := {"done": fin, "pos": pos, "clip": String(LAND_HARD["input"]), "clip_t": ct, "air": not down, "free": not down, "landed": down,
				"landing": "heavy", "yaw": float(p["yaw1"])}
		if fin:
			o["pos"] = p["end"]
			o["exit"] = Vector3.ZERO
		return o
	if t < fall_len:
		# wobbling, turned to the side he will go over; then over and down: forward by the take's own travel, down by
		# the take's share of its fall, set to the height that is really there
		var ct := from_t + t
		var xz := _at2(_b_xz, ct)
		var pos := (p["from"] as Vector3) + m * (xz.y * float(p["reach"]))
		pos.y = float(p["land_y"]) + (float(p["top_y"]) - float(p["land_y"])) * (1.0 - _at(_b_fall, ct))
		return {"done": false, "pos": pos, "clip_t": ct, "air": ct >= float(BALANCE["over"]) and _at(_b_fall, ct) < 0.95, "free": true,
				"yaw": lerp_angle(float(p["yaw0"]), float(p["yaw1"]), smoothstep(0.0, 1.0, t))}
	# lying where he fell, then up
	var tu := t - fall_len - float(BALANCE["lie"])
	if tu < 0.0:
		return {"done": false, "pos": p["end"], "clip_t": float(BALANCE["end"]), "air": false, "free": true, "yaw": float(p["yaw1"])}
	var done := tu >= float(BALANCE["up_len"])
	var out := {"done": done, "pos": p["end"], "clip": String(BALANCE["up"]), "clip_t": minf(tu, float(BALANCE["up_len"])), "air": false,
			"free": tu < float(BALANCE["up_len"]) - 0.5, "landed": true, "yaw": float(p["yaw1"])}
	if done:
		out["exit"] = Vector3.ZERO
	return out
