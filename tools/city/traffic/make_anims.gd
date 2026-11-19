extends SceneTree
## Fits the Quaternius Universal Animation Library's clips (characters/quaternius_ual/*.glb, CC0) to the game's own
## 50-bone figure: characters/rocketbox/clips_ual_male.res and clips_ual_female.res.
## All the work is C++ (native/src/anim_retarget.cpp, class AnimRetarget); this script only calls it.
## Run it when a library file or the figure's skeleton changes, then run make_people.gd (the far figures use the walk):
##   godot --headless --path . -s res://tools/city/traffic/make_anims.gd
const SRC := ["res://characters/quaternius_ual/UAL1.glb", "res://characters/quaternius_ual/UAL2.glb"]      # the Source (pro) packs, Yasin's, 20 Nov
## Clips whose name holds one of these are NOT fitted: nothing a street of this game needs, and every clip costs
## 37 KB a figure. To have one after all, take its word out of the list and run this again.
const SKIP := ["Sword", "Bow_", "Spell_", "Zombie", "Shield", "WallRun", "NinjaJump", "LiftAir", "MonsterTransformation", "Mining", "TreeChopping"]
## Mixed clips, [name, base, top]: the base clip with the arms, neck and head of the top clip (the libraries have no
## walking while talking, no sitting with a phone: these make them).
const LAYERS := [["Walk_Talk_Loop", "Walk_Loop", "Idle_Talking_Loop"], ["Walk_Phone_Loop", "Walk_Loop", "Idle_TalkingPhone_Loop"], ["Walk_Text_Loop", "Walk_Loop", "Idle_Lantern_Loop"],
	["Sitting_Phone_Loop", "Sitting_Idle_Loop", "Idle_TalkingPhone_Loop"], ["Sitting_Text_Loop", "Sitting_Idle_Loop", "Idle_Lantern_Loop"], ["Sitting_Drink_Loop", "Sitting_Idle_Loop", "Drink"],
	["GroundSit_Ask_Loop", "GroundSit_Idle_Loop", "Counter_Show"], ["GroundSit_Thanks_Loop", "GroundSit_Idle_Loop", "Yes"],
	["Walk_Hurt_Loop", "Walk_Loop", "Crying"]]      # (walking away after a lost fight, his hands at his face)

func _initialize() -> void:
	if not ClassDB.class_exists(&"AnimRetarget"):
		print("ANIMS ERROR the native module is not built: run  bash native/build.sh"); quit(1); return
	var r: Object = ClassDB.instantiate(&"AnimRetarget")
	r.set_skip(PackedStringArray(SKIP))
	r.set_layers(LAYERS)
	var rep: PackedStringArray = r.retarget(root, PackedStringArray(SRC), "res://characters/rocketbox/")
	for l in rep: print(l)
	print("ANIMS mixed clips made: %d (counted for both figures)" % int(r.layered()))
	print("ANIMS left out by the SKIP list: %d clips (counted for both figures)" % int(r.skipped()))
	quit(0 if int(r.count()) > 0 else 1)
