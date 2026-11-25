## CLI tool: build a test clip cache from loose files (Kimodo .glb or Mixamo .fbx), one clip per file, and print the
## measurements. Used for the Kimodo test. Usage:
##   godot --headless --path . -s tools/build_any_cli.gd -- <out.bin> <name=path[:loop]> ...
extends SceneTree
const CB := preload("res://tools/clip_build.gd")
func _init():
	var a := OS.get_cmdline_user_args()
	var cb := CB.new()
	cb.setup_body(load("res://body/player_v3.glb"))
	var clips := {}
	for arg in a.slice(1):
		var name: String = arg.get_slice("=", 0)
		var rest: String = arg.substr(name.length() + 1)
		var loop := rest.ends_with(":loop")
		var path := rest.trim_suffix(":loop")
		var c := cb.build_clip(path, {"name": name, "loop": loop})
		if c.is_empty(): print("FAIL ", name); continue
		clips[name] = c
		print(CB.summary(c))
	var f := FileAccess.open(a[0], FileAccess.WRITE)
	f.store_var({"version": 0, "bones": cb.bones, "clips": clips})
	f.close()
	quit()
