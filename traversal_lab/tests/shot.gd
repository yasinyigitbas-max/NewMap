extends SceneTree
## Take pictures of stations for a look from the cloud (real renderer under xvfb).
## Run:  xvfb-run -a godot --path traversal_lab --rendering-driver vulkan -s res://tests/shot.gd -- --stations=0,16,30 --out=/tmp/shots
## Options: --walk=<seconds> walks forward first; --yaw=<deg> --pitch=<deg> --dist=<m> place the camera.

func _initialize() -> void:
	_run.call_deferred()


func _arg(name: String, def: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.split("=", true, 1)[1]
	return def


func _run() -> void:
	var lab: Node3D = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	var out := _arg("out", "user://shots")
	DirAccess.make_dir_recursive_absolute(out)
	var tape: Node = lab.get(&"tape")
	for sid in _arg("stations", "0").split(","):
		lab.call(&"go_to", int(sid))
		lab.set(&"_yaw", deg_to_rad(float(_arg("yaw", "25"))))
		lab.set(&"_pitch", deg_to_rad(float(_arg("pitch", "-18"))))
		lab.set(&"_dist", float(_arg("dist", "6")))
		var walk := float(_arg("walk", "0"))
		if walk > 0.0:
			tape.call(&"make", [[walk, 0.0, -1.0, 0.0, false]])
			tape.call(&"replay")
			while int(tape.get(&"mode")) == 2:
				await physics_frame
		for i in 6:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png("%s/station_%s.png" % [out, sid])
		print("shot ", sid)
	quit(0)
