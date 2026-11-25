## Test tool: plays a scripted input and saves screenshots. Run with a display (xvfb-run) and opengl3.
##   godot --path . --rendering-driver opengl3 -s tests/shots.gd -- <out_dir> <scenario>
extends SceneTree
var main; var p; var cam; var t := 0.0; var frame := 0
var out := "/tmp"; var scen := "walk"
var shots := []
func _init():
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: scen = a[1]
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	p = main.get_node("Player"); cam = main.get_node("Camera")
	main.get_node("HUD").visible = true
	physics_frame.connect(_tick)
func _tick():
	t += 1.0 / 60.0
	var dir := Vector2(0, 1); var sp := 0.0
	match scen:
		"idle": sp = 0
		"walk": sp = 1.55 if t > 0.5 else 0.0
		"run": sp = 4.2 if t > 0.5 else 0.0
		"side":
			sp = 1.55 if t > 0.5 else 0.0
	p.set_test_input(dir, sp, true)
	cam.set_view_yaw(PI + (0.0 if scen != "side" else PI * 0.5))
	frame += 1
	var times := [0.3, 1.0, 1.5, 2.0, 2.5, 3.0]
	for st in times:
		if abs(t - st) < 0.5 / 60.0:
			await process_frame
			var img := root.get_texture().get_image()
			img.save_png("%s/%s_%03d.png" % [out, scen, int(st * 100)])
	if t > 3.1: quit()
