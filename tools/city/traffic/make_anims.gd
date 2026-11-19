extends SceneTree
## Fits the Quaternius Universal Animation Library's clips (characters/quaternius_ual/*.glb, CC0) to the game's own
## 50-bone figure: characters/rocketbox/clips_ual_male.res and clips_ual_female.res.
## All the work is C++ (native/src/anim_retarget.cpp, class AnimRetarget); this script only calls it.
## Run it when a library file or the figure's skeleton changes, then run make_people.gd (the far figures use the walk):
##   godot --headless --path . -s res://tools/city/traffic/make_anims.gd
const SRC := ["res://characters/quaternius_ual/UAL1_Standard.glb", "res://characters/quaternius_ual/UAL2_Standard.glb"]

func _initialize() -> void:
	if not ClassDB.class_exists(&"AnimRetarget"):
		print("ANIMS ERROR the native module is not built: run  bash native/build.sh"); quit(1); return
	var r: Object = ClassDB.instantiate(&"AnimRetarget")
	var rep: PackedStringArray = r.retarget(root, PackedStringArray(SRC), "res://characters/rocketbox/")
	for l in rep: print(l)
	quit(0 if int(r.count()) > 0 else 1)
