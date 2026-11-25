extends SceneTree
# Tool: prints ground heights (collision, mask 1|4|8) on a grid. args: x0 x1 z0 z1 step
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	go.call_deferred()
func go():
	await physics_frame
	await physics_frame
	var a = OS.get_cmdline_user_args()
	var x0 = float(a[0]); var x1 = float(a[1]); var z0 = float(a[2]); var z1 = float(a[3]); var st = float(a[4])
	var ss = root.get_world_3d().direct_space_state
	var z = z0
	while z <= z1 + 1e-4:
		var line = "z %6.2f:" % z
		var x = x0
		while x <= x1 + 1e-4:
			var q = PhysicsRayQueryParameters3D.create(Vector3(x, 5, z), Vector3(x, -1, z), 1 | 4 | 8)
			var r = ss.intersect_ray(q)
			line += " %5.2f" % (r.position.y if r else -9.0)
			x += st
		print(line)
		z += st
	quit()
