extends SceneTree
## Adds the Mixamo clips Yasin sends one by one (characters/mixamo2/*.fbx; the files themselves are not kept in git, like
## characters/mixamo) to the figure's "mx" library without rebuilding it: each fitted by AnimRetarget ("mixamo" mode)
## into clips_mx2_<g>.res, then copied into clips_mx_<g>.res under its file's name ("Ledge_Drop.fbx" -> "mx/Ledge_Drop").
## Name a file so the retarget keeps its travel when it should (a name with "jump", "step", "start", "stop", "turn",
## "walk", "run" has its travel taken out; a ledge descent must keep it).
##   godot --headless --path . --import ; godot --headless --path . -s res://tools/people/make_mixamo_extra.gd
const DIR := "res://characters/mixamo2/"

func _initialize() -> void:
	var files := PackedStringArray()
	for f in DirAccess.get_files_at(DIR): if f.to_lower().ends_with(".fbx"): files.append(DIR + f)
	if files.is_empty(): print("MXEXTRA no files"); quit(1); return
	var r: Object = ClassDB.instantiate(&"AnimRetarget")
	r.set_rig("mixamo"); r.set_out_prefix("clips_mx2_")
	for l in r.retarget(root, files, "res://characters/rocketbox/"): print(l)
	for g in ["male", "female"]:
		var src: AnimationLibrary = load("res://characters/rocketbox/clips_mx2_%s.res" % g)
		var path := "res://characters/rocketbox/clips_mx_%s.res" % g
		var lib: AnimationLibrary = load(path)
		if src == null or lib == null: print("MXEXTRA missing %s" % g); continue
		for nm in src.get_animation_list():
			var a: Animation = src.get_animation(nm).duplicate(true); a.compress()
			if lib.has_animation(nm): lib.remove_animation(nm)
			lib.add_animation(nm, a)
			print("MXEXTRA %s: mx/%s %.2f s" % [g, nm, a.length])
		print("MXEXTRA %s saved: %s" % [path, ResourceSaver.save(lib, path, ResourceSaver.FLAG_COMPRESS) == OK])
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://characters/rocketbox/clips_mx2_%s.res" % g))
	quit(0)
