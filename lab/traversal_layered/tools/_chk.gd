extends SceneTree
func _init():
	var CB = load("res://tools/clip_build.gd")
	printerr("LOADED ", CB.can_instantiate())
	quit()
