## Tool: parse-check every lab script (a parse error makes a -s script hang instead of failing).
extends SceneTree
func _init():
	for f in ["res://tools/clip_cache.gd","res://tools/clip_build.gd","res://tools/clip_set.gd","res://scenes/boot.gd","res://scenes/hud.gd","res://tests/loco_test.gd","res://tests/shots.gd","res://tests/clip_audit.gd","res://tests/clip_view.gd","res://tools/build_any_cli.gd","res://tools/build_course.gd"]:
		var s = load(f)
		printerr(f, " ok=", s != null and s.can_instantiate())
	quit()
