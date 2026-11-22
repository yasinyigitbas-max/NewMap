extends "res://tools/people/make_player_traversal.gd"
## PLAYER ONLY. The outdoor moves after the traversal (Yasin, 22 Nov: carrying, benches, bumps and stumbles, pushing past,
## pick up / put down): every take of his downloads and packs for them, no UAL.
##   godot --headless --path . -s res://tools/people/make_player_actions.gd   -> characters/rocketbox/clips_player_act_<g>.res
## Library "pact" (CityPed loads it). Sources: tools/people/player_act_sources/clips_mxact_<g>.res (the Mixamo converter,
## as the traversal's). The same fit and meta as make_player_traversal.gd. The carry takes give only their arms (and the
## box takes their spine) to the player (native/src/body_layer.cpp): his legs keep his own walk / run / idle.
## Left out (tools/people/act_scan.gd): the exact duplicates (Jogging With Box (1) (2), Tripping (2) (3), Box Turn (2), Walk
## To Stop carry / with a box = Walk carry stop); Box Idle (a box on the shoulder, not in front); Sitting Idle (1) (on the
## floor); sit Stand Up (from a stool 0.2 m higher); Kneeling, Closing A Lid (a car boot). The seat: Stand To Sit / Sitting
## Idle / Sit To Stand have the hips 0.49 m up sitting (a 0.42 m seat). Tender Placement: bends to set down what the
## hands hold in front of him onto a 0.4-0.5 m surface and stands (the put down; and, the prop taken at its lowest, the
## pick up).
const SRC_ACT := "res://tools/people/player_act_sources/clips_mxact_%s.res"
const TAKES_ACT := [
	# carrying, two hands (boxes, crates): standing, turning, walking, jogging, running, stopping
	["Box_Turn_a", "Box_Turn_a", false], ["Box_Turn_b", "Box_Turn_b", false],
	["Box_Walk_Arc", "Box_Walk_Arc", false], ["Walking_Carry", "Walking_Carry", false],
	["Jogging_With_Box_a", "Jogging_With_Box_a", false],
	["Running_With_A_Box", "Running_With_A_Box", false],
	["Walk_Carry_Stop", "Walk_Carry_Stop", false], ["Carrying_Turn", "Carrying_Turn", false],
	# carrying, one hand (bags, briefcases, a backpack by its handle)
	["Walk_With_Briefcase", "Walk_With_Briefcase", false], ["Briefcase_Idle", "Briefcase_Idle", false],
	["Briefcase_Left_Turn", "Briefcase_Left_Turn", false], ["Briefcase_Right_Turn", "Briefcase_Right_Turn", false],
	["Briefcase_Turn_180_a", "Briefcase_Turn_180_a", false], ["Briefcase_Turn_180_b", "Briefcase_Turn_180_b", false],
	["Walking_With_Shopping_Bag", "Walking_With_Shopping_Bag", false],
	# benches: sitting down, sitting, getting up
	["Stand_To_Sit", "Stand_To_Sit", false], ["Sitting_Idle_a", "Sitting_Idle_a", false], ["Sitting_Talking", "Sitting_Talking", false],
	["Sit_To_Stand", "Sit_To_Stand", false],
	# bumps and stumbles
	["Shove_Reaction_a", "Shove_Reaction_a", false], ["Shove_Reaction_b", "Shove_Reaction_b", false], ["Shoved_Reaction_With_Spin", "Shoved_Reaction_With_Spin", false],
	["Hit_On_The_Back", "Hit_On_The_Back", false], ["Shoulder_Hit_And_Fall", "Shoulder_Hit_And_Fall", false],
	["Jogging_Stumble", "Jogging_Stumble", false], ["Tripping_a", "Tripping_a", false], ["Tripping_b", "Tripping_b", false],
	["Stumble_Backwards", "Stumble_Backwards", false],
	# pushing past: the sidestep through a gap
	["Left_Strafe_Walking", "Left_Strafe_Walking", false], ["Right_Strafe_Walking", "Right_Strafe_Walking", false],
	# pick up / put down, doors
	["Tender_Placement", "Tender_Placement", false],
	["Open_Door_Outwards", "Open_Door_Outwards", false], ["Opening_Door_Inwards", "Opening_Door_Inwards", false],
]

func _initialize() -> void:
	_build(TAKES_ACT, SRC_ACT, "clips_player_act_%s.res", "PLAYER_ACT")
	quit(0)
