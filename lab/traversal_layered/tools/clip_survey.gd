## CLI tool: measure every FBX in a folder (prints contacts, speed, turn). Usage:
##   godot --headless --path . -s tools/clip_survey.gd -- <folder> [filter]
extends SceneTree
const CB := preload("res://tools/clip_build.gd")
func _init():
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0]
	var filt: String = args[1] if args.size() > 1 else ""
	var cb := CB.new()
	cb.setup_body(load("res://body/player_v3.glb"))
	var files := DirAccess.get_files_at(dir)
	for f in files:
		if not (f.to_lower().ends_with(".fbx") or f.to_lower().ends_with(".glb")) or (filt != "" and f.find(filt) < 0): continue
		var c := cb.build_clip(dir.path_join(f), {"name": f.get_basename(), "loop": false})
		if c.is_empty(): print("FAIL ", f); continue
		print(CB.summary(c))
	print("leg_k=", cb.leg_k, " ankle_c=", cb.ankle_c)
	for l in cb.log_lines: print(l)
	quit()
