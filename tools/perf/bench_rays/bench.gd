extends SceneTree
## The rays microbenchmark (docs/FAST_RAYS.md). A floor, a field of boxes, a trimesh hill; then RayBench.run() times N
## rays from C++ the old way (intersect_ray, a Dictionary a ray) and through intersect_rays (batches of 1, 2, 3, 64, 1024)
## and checks every way hit the same, bit for bit. From GDScript too: intersect_ray against intersect_rays.
##   bash tools/perf/bench_rays/run.sh [godot binary] [rays]   (both physics engines)
var rays := 20000
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--rays="): rays = int(a.substr(7))
	_run.call_deferred()
func _box(size: Vector3, at: Vector3) -> void:
	var b := StaticBody3D.new(); var c := CollisionShape3D.new(); var s := BoxShape3D.new(); s.size = size; c.shape = s
	b.add_child(c); b.position = at; root.add_child(b)
func _run() -> void:
	_box(Vector3(60, 1, 60), Vector3(0, -0.5, 0))
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	for i in 300:
		_box(Vector3(rng.randf_range(0.2, 2), rng.randf_range(0.1, 1.5), rng.randf_range(0.2, 2)), Vector3(rng.randf_range(-25, 25), 0.3, rng.randf_range(-25, 25)))
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in 40:
		for z in 40:
			var p := func(i: int, j: int) -> Vector3: return Vector3(i - 20, 0.4 * sin(i * 0.5) * cos(j * 0.4) + 0.2, j - 20)
			st.add_vertex(p.call(x, z)); st.add_vertex(p.call(x + 1, z)); st.add_vertex(p.call(x, z + 1))
			st.add_vertex(p.call(x + 1, z)); st.add_vertex(p.call(x + 1, z + 1)); st.add_vertex(p.call(x, z + 1))
	var hill := StaticBody3D.new(); var hc := CollisionShape3D.new(); hc.shape = st.commit().create_trimesh_shape(); hill.add_child(hc); root.add_child(hill)
	var bench: CharacterBody3D = ClassDB.instantiate(&"RayBench")
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cs.shape = cap; bench.add_child(cs); bench.position = Vector3(0, 5, 0)
	root.add_child(bench)
	for i in 3: await physics_frame
	print("BENCH engine ", Engine.get_version_info().string, "  physics ", ProjectSettings.get_setting("physics/3d/physics_engine"),
		"  intersect_rays in engine: ", ClassDB.class_has_method(&"PhysicsDirectSpaceState3D", &"intersect_rays"), "  rays ", rays)
	for round in 3:
		await physics_frame
		var r: Dictionary = bench.call(&"run", rays, 50.0)
		print("BENCH C++ round %d: %s" % [round, r])
	# GDScript, the same rays
	await physics_frame
	var ss := bench.get_world_3d().direct_space_state
	var pts := PackedVector3Array()
	for i in rays:
		var x := rng.randf_range(-25, 25); var z := rng.randf_range(-25, 25)
		pts.append(Vector3(x, 3, z)); pts.append(Vector3(x, -1, z))
	var q := PhysicsRayQueryParameters3D.new(); q.exclude = [bench.get_rid()]
	var t0 := Time.get_ticks_usec(); var sum := 0.0
	for i in rays:
		q.from = pts[2 * i]; q.to = pts[2 * i + 1]
		var h := ss.intersect_ray(q)
		if not h.is_empty(): sum += (h["position"] as Vector3).y + (h["normal"] as Vector3).y
	var t1 := Time.get_ticks_usec()
	print("BENCH GDScript intersect_ray: %.3f us a ray" % (float(t1 - t0) / rays))
	if ss.has_method(&"intersect_rays"):
		t0 = Time.get_ticks_usec()
		var res: PackedFloat32Array = ss.call(&"intersect_rays", pts, 0xFFFFFFFF, [bench.get_rid()])
		t1 = Time.get_ticks_usec()
		var sum2 := 0.0
		for i in rays:
			if res[8 * i] != 0.0: sum2 += res[8 * i + 2] + res[8 * i + 5]
		print("BENCH GDScript intersect_rays (one call): %.3f us a ray, same sums: %s" % [float(t1 - t0) / rays, is_equal_approx(sum, sum2) and sum == sum2])
	quit()
