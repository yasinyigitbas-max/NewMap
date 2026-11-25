## CLI: build the clip cache from a folder of already-downloaded files.
##   godot --headless --path . -s tools/build_cache_cli.gd -- <raw_dir> [out_path]
extends SceneTree
const CC := preload("res://tools/clip_cache.gd")
func _init():
	var a := OS.get_cmdline_user_args()
	var out: String = a[1] if a.size() > 1 else "user://clip_cache/clips.bin"
	var cc := CC.new()
	var err := cc.build(a[0], out)
	for l in cc.log_lines: printerr(l)
	var f := FileAccess.open(out, FileAccess.READ)
	var d: Dictionary = f.get_var()
	for k in d.clips: print(CC.describe(d.clips[k]))
	print("built err=", err, " clips=", d.clips.size(), " -> ", ProjectSettings.globalize_path(out))
	quit()
