extends SceneTree
## Yasin's own animation library (his Google Drive folder, 24 Nov: "i have a library of almost 400 animations ... make 2
## more complete sets"), fitted to the game's figure like the Mixamo clips (AnimRetarget, "mixamo" mode):
## characters/ylib/*.fbx (not kept in git; names cleaned: "Running (3).fbx" -> Running_3, the packs' clips prefixed LP_
## (Male Locomotion Pack) and AA_ (Action Adventure Pack)) -> characters/rocketbox/clips_yl_<g>.res, library "yl".
##   godot --headless --path . --import ; godot --headless --path . -s res://tools/people/make_ylib.gd
const DIR := "res://characters/ylib/"

func _initialize() -> void:
	var files := PackedStringArray()
	for f in DirAccess.get_files_at(DIR): if f.to_lower().ends_with(".fbx"): files.append(DIR + f)
	print("YLIB %d files" % files.size())
	var r: Object = ClassDB.instantiate(&"AnimRetarget")
	r.set_rig("mixamo"); r.set_out_prefix("clips_yl_")
	for l in r.retarget(root, files, "res://characters/rocketbox/"): print(l)
	for g in ["male", "female"]:
		var path := "res://characters/rocketbox/clips_yl_%s.res" % g
		var lib: AnimationLibrary = load(path)
		if lib == null: continue
		for nm in lib.get_animation_list(): lib.get_animation(nm).compress()
		print("YLIB %s: %d clips, saved %s" % [path, lib.get_animation_list().size(), ResourceSaver.save(lib, path, ResourceSaver.FLAG_COMPRESS) == OK])
	quit(0)
