## The Kimodo clips of the v2 build (data only). Chosen by the C++ validator on the body (tests/clip_check.gd, 26 Nov):
## the sample with the fewest HARD-rule frames per move. Files are generated (NVIDIA Kimodo via Replicate) and live
## outside the repo in KIMODO_DIR; their licence is Yasin's to check, so the repo never carries them or anything built
## from them. The exported build carries the built cache in its pack.
## kind: idle | loop | start | stop | pivot | turn | gesture | traverse.  a / b: frame range (30 fps), -1 = to the end.
## mirror: also build the mirror (name + "_M"). trav: traversal clip (its floor changes; feet locked level-free).
extends RefCounted

const KIMODO_DIR := "/opt/lab/kimodo/out"

const CLIPS := [
	# locomotion
	{"name": "idle", "src": "idle_shift/kimodo_motion_00.glb", "kind": "idle", "loop": true},
	{"name": "walk", "src": "walk_loop/kimodo_motion_00.glb", "kind": "loop", "loop": true, "a": 59, "b": 95},
	{"name": "run", "src": "run_loop/kimodo_motion_00.glb", "kind": "loop", "loop": true, "a": 82, "b": 106},
	{"name": "walk_start", "src": "walk_loop/kimodo_motion_00.glb", "kind": "start", "a": 0, "b": 95, "mirror": true},
	{"name": "run_start", "src": "run_loop/kimodo_motion_00.glb", "kind": "start", "a": 0, "b": 106, "mirror": true},
	{"name": "walk_stop", "src": "walk_stop/kimodo_motion_01.glb", "kind": "stop", "a": 72, "mirror": true},
	{"name": "walk_stop2", "src": "walk_stop/kimodo_motion_02.glb", "kind": "stop", "a": 70, "mirror": true},
	{"name": "run_stop", "src": "run_stop/kimodo_motion_01.glb", "kind": "stop", "a": 42, "mirror": true},
	{"name": "run_stop2", "src": "run_stop/kimodo_motion_00.glb", "kind": "stop", "a": 29, "mirror": true},
	{"name": "run_pivot", "src": "run_pivot/kimodo_motion_01.glb", "kind": "pivot", "a": 30, "mirror": true},
	{"name": "walk_start_turn", "src": "start_turn_l90/kimodo_motion_01.glb", "kind": "start", "mirror": true},
	# upper-body gestures (played on the upper body while standing)
	{"name": "wave", "src": "wave/kimodo_motion_00.glb", "kind": "gesture"},
	{"name": "point_talk", "src": "point_talk/kimodo_motion_00.glb", "kind": "gesture"},
	# traversal (study v2 6.1, 6.3, 11.1)
	{"name": "step_up_40", "src": "pin_stepup_0m4/kimodo_motion_01.glb", "kind": "traverse", "trav": true, "height": 0.40},
	{"name": "mantle_80", "src": "r3g_mantle_0m8/kimodo_motion_15.glb", "kind": "traverse", "trav": true, "height": 0.80},
	{"name": "climb_150", "src": "r3g_climb_1m5/kimodo_motion_07.glb", "kind": "traverse", "trav": true, "height": 1.50},
	{"name": "drop_100", "src": "drop_1m/kimodo_motion_00.glb", "kind": "traverse", "trav": true, "height": -1.00},
]
