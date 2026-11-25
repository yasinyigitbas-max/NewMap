extends SceneTree
## Pictures for a look from the cloud at Stage 4 and 5: stopping, turning on the spot, a 19 degree ramp, stairs.
## Run:  xvfb-run -a godot --path traversal_lab --rendering-driver vulkan --fixed-fps 60 -s res://tests/shot_feet.gd -- --out=/tmp/shots

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


func play(at: Vector3, yaw: float, segs: Array, shots: Array, tag: String) -> void:
	lab.call(&"place", at)
	(lab.get(&"body") as Node3D).rotation.y = 0.0
	lab.set(&"_yaw", deg_to_rad(yaw))
	lab.set(&"_pitch", deg_to_rad(-8.0))
	lab.set(&"_dist", 3.2)
	for i in 30:
		await physics_frame
	var tape: Node = lab.get(&"tape")
	tape.call(&"make", segs)
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
	var st := {}
	for s: Dictionary in (lab.get(&"course") as Node3D).get(&"stations"):
		st[s["label"]] = s
	var s: Dictionary = st["stairs 0.18 / 0.28 m x 10"]
	await play((s["start"] as Vector3) + Vector3(0.0, 0.0, -2.0), 90.0, [[5.0, 0.0, -1.0, 0.0, false]], [2.2, 2.45, 2.7, 2.95, 3.2], "stairs_up")
	await play(Vector3(float(s["x"]), float(s["top"]), -3.0 - 2.8 - 0.8), 90.0, [[5.0, 0.0, 1.0, 0.0, false]], [3.0, 3.25, 3.5, 3.75, 4.0], "stairs_down")
	await play((s["start"] as Vector3) + Vector3(0.0, 0.0, -1.0), 90.0, [[2.2, 0.0, -1.0, 0.0, true]], [1.2, 1.35, 1.5, 1.65], "stairs_run")
	var flat := Vector3(float(st["floor: one triangle mesh"]["x"]), 0.1, -5.0)
	await play(flat, 90.0, [[1.6, 0.0, -1.0, 0.0, true], [1.4, 0.0, 1.0, 0.0, true]], [1.9, 2.1, 2.3, 2.5, 2.8], "runround")
	quit(0)
