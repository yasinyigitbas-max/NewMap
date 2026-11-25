extends SceneTree
## Pictures of the character idle, walking, running and jumping, for a look from the cloud.
## Run:  xvfb-run -a godot --path traversal_lab --rendering-driver vulkan --fixed-fps 60 -s res://tests/shot_moves.gd -- --out=/tmp/shots

var lab: Node3D
var out := "user://shots"
var n := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.split("=", true, 1)[1]
	_run.call_deferred()


func snap(tag: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, tag])
	n += 1


func play(seg: Array, shots: Array, tag: String) -> void:
	var tape: Node = lab.get(&"tape")
	var one := seg.duplicate()
	var jump := one.size() > 5 and bool(one[5])
	tape.call(&"make", [one.slice(0, 5)])
	if jump:
		for s: Dictionary in tape.get(&"tape"):
			s["jump"] = true
	tape.call(&"replay")
	var t := 0
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		t += 1
		for s: float in shots:
			if t == int(s * 60.0):
				await snap("%s_%.2f" % [tag, s])


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	lab.call(&"place", Vector3(8.0, 0.0, 14.0))
	lab.set(&"_yaw", deg_to_rad(90.0))
	lab.set(&"_pitch", deg_to_rad(-6.0))
	lab.set(&"_dist", 3.6)
	for i in 40:
		await physics_frame
	await snap("idle")
	await play([3.0, 0.0, -1.0, 0.0, false], [1.8, 2.0, 2.2, 2.4], "walk")
	await play([2.5, 0.0, -1.0, 0.0, true], [1.9, 2.0, 2.1, 2.2], "run")
	await play([1.6, 0.0, 0.0, 0.0, false], [1.5], "stopped")
	await play([0.2, 0.0, 0.0, 0.0, false, true], [0.15], "jump_push")
	await play([1.4, 0.0, 0.0, 0.0, false], [0.15, 0.3, 0.45, 0.7, 1.2], "jump")
	quit(0)
