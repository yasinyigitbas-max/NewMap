extends SceneTree
## Fits Mixamo's clips (characters/mixamo/*.fbx, downloaded by Yasin: FBX Binary, without skin, 30 fps, no keyframe
## reduction, the moving ones "In Place"; Yasin, 21 Nov: "okay go for mixamo") to the game's own 50-bone figure:
## characters/rocketbox/clips_mx_male.res and clips_mx_female.res, each clip named after its file ("Start Walking.fbx"
## -> "Start_Walking"). Walks, runs and idles loop; starts, stops and turns play once.
## All the work is C++ (native/src/anim_retarget.cpp, AnimRetarget in its "mixamo" mode); this script only calls it.
##   godot --headless --path . -s res://tools/people/make_mixamo.gd
const DIR := "res://characters/mixamo/"
## files that are a character, not a clip (the rest pose comes from each clip's own file)
const NOT_CLIPS := ["Y Bot", "Y_Bot", "X Bot", "X_Bot", "T-Pose", "TPose"]

func _initialize() -> void:
	if not ClassDB.class_exists(&"AnimRetarget"):
		print("MIXAMO ERROR the native module is not built: run  bash native/build.sh"); quit(1); return
	var files := PackedStringArray()
	for f in DirAccess.get_files_at(DIR):
		if not f.to_lower().ends_with(".fbx"): continue
		var skip := false
		for w in NOT_CLIPS: if f.contains(w): skip = true
		if not skip: files.append(DIR + f)
	if files.is_empty():
		print("MIXAMO ERROR no .fbx clips in %s" % DIR); quit(1); return
	print("MIXAMO %d files: %s" % [files.size(), ", ".join(files)])
	var r: Object = ClassDB.instantiate(&"AnimRetarget")
	r.set_rig("mixamo")
	r.set_out_prefix("clips_mx_")
	var rep: PackedStringArray = r.retarget(root, files, "res://characters/rocketbox/")
	for l in rep: print(l)
	# compressed (Animation.compress: 39 MB a figure -> about 10, no visible change; the meta and every read still work)
	for g in ["male", "female"]:
		var path := "res://characters/rocketbox/clips_mx_%s.res" % g
		var lib: AnimationLibrary = load(path)
		if lib == null: continue
		for nm in lib.get_animation_list(): lib.get_animation(nm).compress()
		print("MIXAMO %s compressed: %s" % [path, "ok" if ResourceSaver.save(lib, path, ResourceSaver.FLAG_COMPRESS) == OK else "NOT SAVED"])
	quit(0 if int(r.count()) > 0 else 1)
