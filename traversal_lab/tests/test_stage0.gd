extends SceneTree
## Stage 0 test. Run:  godot --headless --path traversal_lab -s res://tests/test_stage0.gd
## Checks: Jolt is the engine, every obstacle measures what its label says, every station has a label,
## the readout shows the body's values, and a replayed input tape gives the same path twice.

var fails := 0
var lab: Node3D


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("PASS  " if cond else "FAIL  ") + what)


func _initialize() -> void:
	_run.call_deferred()


func ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [(lab.get(&"body") as CharacterBody3D).get_rid()]
	return lab.get_world_3d().direct_space_state.intersect_ray(q)


func top_at(p: Vector3) -> float:
	var h := ray(Vector3(p.x, 20.0, p.z), Vector3(p.x, -5.0, p.z))
	return float((h["position"] as Vector3).y) if h else -99.0


func _run() -> void:
	ok(str(ProjectSettings.get_setting("physics/3d/physics_engine")) == "Jolt Physics", "physics engine is Jolt")
	ok(Engine.physics_ticks_per_second == 60, "60 physics ticks a second")
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 3:
		await physics_frame
	var course: Node3D = lab.get(&"course")
	var st: Array = course.get(&"stations")
	var labels := course.find_children("*", "Label3D", true, false).size()
	ok(st.size() == 64, "64 stations built (got %d)" % st.size())      # 63 until the roofed wall of stage 7
	# (and the stations added later, listed apart in `extras`: the wall ledges of 27 Nov)
	ok(labels == st.size() + (course.get(&"extras") as Array).size(), "every station has its label (%d labels)" % labels)
	var kinds := {}
	var bad: Array[String] = []
	for s: Dictionary in st:
		kinds[s["kind"]] = int(kinds.get(s["kind"], 0)) + 1
		var p: Vector3 = s["probe"]
		var k: String = s["kind"]
		if k == "passage":
			var l := ray(Vector3(p.x, 1.0, p.z), Vector3(p.x - 3.0, 1.0, p.z))
			var r := ray(Vector3(p.x, 1.0, p.z), Vector3(p.x + 3.0, 1.0, p.z))
			var w := (r["position"] as Vector3).x - (l["position"] as Vector3).x if l and r else -1.0
			if absf(w - float(s["width"])) > 0.005:
				bad.append("%s measures %.3f" % [s["label"], w])
		elif k == "wall_roofed":
			# measured from the side, under its roof: the wall's own top, and the gap up to the roof
			var up := ray(Vector3(p.x, float(s["top"]) + 0.02, p.z), Vector3(p.x, 5.0, p.z))
			var down := ray(Vector3(p.x, float(s["top"]) + 0.02, p.z), Vector3(p.x, -1.0, p.z))
			var c := float((up["position"] as Vector3).y) - float(s["top"]) if up else -1.0
			var t := float((down["position"] as Vector3).y) if down else -1.0
			if absf(c - float(s["clear"])) > 0.005 or absf(t - float(s["top"])) > 0.005:
				bad.append("%s measures top %.3f, roof %.3f above it" % [s["label"], t, c])
		elif k == "overhang":
			var u := ray(Vector3(p.x, 0.05, p.z), Vector3(p.x, 5.0, p.z))
			var c := float((u["position"] as Vector3).y) if u else -1.0
			if absf(c - float(s["clear"])) > 0.005:
				bad.append("%s measures %.3f" % [s["label"], c])
		else:
			var t := top_at(p)
			if absf(t - float(s["top"])) > 0.005:
				bad.append("%s top measures %.3f, label says %.3f" % [s["label"], t, float(s["top"])])
			if k == "beam":
				var l2 := ray(Vector3(p.x - 1.0, float(s["top"]) - 0.05, p.z), Vector3(p.x + 1.0, float(s["top"]) - 0.05, p.z))
				var r2 := ray(Vector3(p.x + 1.0, float(s["top"]) - 0.05, p.z), Vector3(p.x - 1.0, float(s["top"]) - 0.05, p.z))
				var bw := (r2["position"] as Vector3).x - (l2["position"] as Vector3).x if l2 and r2 else -1.0
				if absf(bw - float(s["width"])) > 0.005:
					bad.append("%s width measures %.3f" % [s["label"], bw])
			if k == "gap":
				var pa: Vector3 = s["probe_a"]
				var edge_a := float(s["edge_z"])
				var in_gap := top_at(Vector3(p.x, 0.0, edge_a - float(s["gap"]) * 0.5))
				var before := top_at(Vector3(p.x, 0.0, edge_a + 0.02))
				var after := top_at(Vector3(p.x, 0.0, edge_a - float(s["gap"]) - 0.02))
				if absf(top_at(pa) - 1.0) > 0.005 or in_gap > 0.01 or absf(before - 1.0) > 0.005 or absf(after - 1.0) > 0.005:
					bad.append("%s: decks %.2f / %.2f, in the gap %.2f" % [s["label"], before, after, in_gap])
			if k == "stairs":
				for i in int(s["steps"]):
					var z := float(s["edge_z"]) - float(s["tread"]) * (i + 0.5)
					var want := float(s["riser"]) * (i + 1)
					if absf(top_at(Vector3(p.x, 0.0, z)) - want) > 0.005:
						bad.append("%s step %d measures %.3f, should be %.3f" % [s["label"], i + 1, top_at(Vector3(p.x, 0.0, z)), want])
			if k == "ramp":
				var m: Vector3 = s["mid"]
				if absf(top_at(m) - 0.75) > 0.01:
					bad.append("%s middle measures %.3f, should be 0.750" % [s["label"], top_at(m)])
	ok(bad.is_empty(), "every obstacle measures what its label says (%d checked)" % st.size())
	for b in bad:
		print("        " + b)
	print("      stations by kind: ", kinds)

	# the readout shows the body's values
	var readout: CanvasLayer = lab.get(&"readout")
	for i in 5:
		await process_frame
	var txt := (readout.find_children("*", "Label", true, false)[0] as Label).text
	ok(txt.contains("state") and txt.contains("on ground") and txt.contains("kerb 0.10 m"), "readout shows state, speed, height and the station")

	# a replayed tape gives the same path twice
	var tape: Node = lab.get(&"tape")
	var body: CharacterBody3D = lab.get(&"body")
	tape.call(&"make", [[1.5, 0.0, -1.0, 0.0, false], [1.0, 0.7, -0.7, 20.0, true], [1.0, -1.0, 0.0, -40.0, false], [0.5, 0.0, 0.0, 0.0, false]])
	var paths: Array = []
	for run in 2:
		lab.call(&"go_to", 4)          # a step station, so the path meets an obstacle
		for i in 2:
			await physics_frame
		tape.call(&"replay")
		var path := PackedVector3Array()
		while int(tape.get(&"mode")) == 2:
			await physics_frame
			path.append(body.global_position)
		paths.append(path)
	var a: PackedVector3Array = paths[0]
	var b2: PackedVector3Array = paths[1]
	var worst := 0.0
	for i in mini(a.size(), b2.size()):
		worst = maxf(worst, a[i].distance_to(b2[i]))
	var moved := a[0].distance_to(a[a.size() - 1]) if a.size() > 1 else 0.0
	ok(a.size() == b2.size() and a.size() > 200 and worst < 0.0005, "replay repeats: %d ticks, largest difference between the two runs %.5f m" % [a.size(), worst])
	ok(moved > 1.0, "the body moved during the replay (%.2f m)" % moved)

	# save and load a tape
	var f := "user://tapes/test_stage0.json"
	var n0 := (tape.get(&"tape") as Array).size()
	ok(bool(tape.call(&"save", f)) and bool(tape.call(&"load_from", f)) and (tape.get(&"tape") as Array).size() == n0, "a tape can be saved and loaded")

	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
