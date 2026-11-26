extends SceneTree
## A film of him going up (or down) one of the ramps, seen from the side: frames for ffmpeg, so that slope work is
## looked at in motion and not in stills.
## Run:  xvfb-run -a godot --path traversal_lab --rendering-driver vulkan --fixed-fps 60 -s res://tests/shot_climb.gd -- --out=/tmp/f --deg=45 [--down] [--run] [--yaw=90]
## Then: ffmpeg -framerate 30 -i /tmp/f/%04d.png -pix_fmt yuv420p out.mp4

var out := "user://climb"
var deg := 45
var down := false
var run := false
var yaw := 90.0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.split("=", true, 1)[1]
		if a.begins_with("--deg="):
			deg = int(a.split("=")[1])
		if a.begins_with("--yaw="):
			yaw = float(a.split("=")[1])
		if a == "--down":
			down = true
		if a == "--run":
			run = true
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var lab: Node3D = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 3:
		await physics_frame
	var s := {}
	for st: Dictionary in (lab.get(&"course") as Node3D).get(&"stations"):
		if st["label"] == "ramp %d deg" % deg:
			s = st
	var body: CharacterBody3D = lab.get(&"body")
	var tape: Node = lab.get(&"tape")
	var length := float(s["run"])
	if down:
		lab.call(&"place", Vector3(float(s["x"]), 1.5, -3.0 - length - 0.8))
	else:
		lab.call(&"place", (s["start"] as Vector3) + Vector3(0.0, 0.0, -1.2))
	lab.set(&"_yaw", deg_to_rad(yaw))
	lab.set(&"_pitch", deg_to_rad(-4.0))
	lab.set(&"_dist", 3.4)
	for i in 30:
		await physics_frame
	tape.call(&"make", [[30.0, 0.0, 1.0 if down else -1.0, 0.0, run]])
	tape.call(&"replay")
	var n := 0
	var t := 0
	var on := false
	while t < 60 * 30:
		await physics_frame
		t += 1
		var y := body.global_position.y
		if not on and ((not down and y > 0.03) or (down and y < 1.47)):
			on = true
		if on and t % 2 == 0:
			await process_frame
			root.get_texture().get_image().save_png("%s/%04d.png" % [out, n])
			n += 1
		if on and ((not down and y > 1.49) or (down and y < 0.01)):
			break
	print("frames %d" % n)
	quit(0)
