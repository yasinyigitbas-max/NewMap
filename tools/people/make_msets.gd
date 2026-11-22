extends SceneTree
## The movement sets' own clips (Yasin, 24 Nov: "we need at least 2 more combination sets ... with different animations
## that go well together"), downloaded from Mixamo by tools/people/mixamo_dl.py and fitted to the game's figure like the
## other Mixamo clips: characters/msets/*.fbx (not kept in git) -> characters/rocketbox/clips_ms_<g>.res, library "ms".
## Names follow the retarget's rules: a loop says walk / run / jog / sprint / idle; a one-shot with travel says none of
## those nor jump / start / stop / turn (Leap, Landing, Dash, Drop, Vault).
##   godot --headless --path . --import ; godot --headless --path . -s res://tools/people/make_msets.gd
const DIR := "res://characters/msets/"

func _initialize() -> void:
	var files := PackedStringArray()
	for f in DirAccess.get_files_at(DIR): if f.to_lower().ends_with(".fbx"): files.append(DIR + f)
	print("MSETS %d files" % files.size())
	var r: Object = ClassDB.instantiate(&"AnimRetarget")
	r.set_rig("mixamo"); r.set_out_prefix("clips_ms_")
	for l in r.retarget(root, files, "res://characters/rocketbox/"): print(l)
	for g in ["male", "female"]:
		var path := "res://characters/rocketbox/clips_ms_%s.res" % g
		var lib: AnimationLibrary = load(path)
		if lib == null: continue
		for nm in lib.get_animation_list(): lib.get_animation(nm).compress()
		print("MSETS %s: %d clips, saved %s" % [path, lib.get_animation_list().size(), ResourceSaver.save(lib, path, ResourceSaver.FLAG_COMPRESS) == OK])
	quit(0)
