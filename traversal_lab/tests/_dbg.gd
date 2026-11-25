extends SceneTree
var lab: Node3D
func _initialize() -> void:
	_run.call_deferred()
func measure(tag: String, at: Vector3, face: float, seg: Array, from_t: int) -> void:
	var body: CharacterBody3D = lab.get(&"body")
	var tape: Node = lab.get(&"tape")
	var ch: Node = lab.get(&"character")
	var sk: Skeleton3D = ch.get(&"skel")
	lab.call(&"place", at)
	body.rotation.y = face
	for i in 30:
		await physics_frame
	tape.call(&"make", [seg])
	tape.call(&"replay")
	var names := ["Head", "Hips", "LeftHand", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot", "LeftToeBase"]
	var idx := []
	for n: String in names:
		idx.append(sk.find_bone("mixamorig_" + n))
	var hist := []
	var final := {}
	sk.skeleton_updated.connect(func() -> void:
		for k in idx.size():
			final[k] = sk.global_transform * sk.get_bone_global_pose(idx[k]).origin)
	var t := 0
	var notes := []
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		await process_frame
		t += 1
		if t >= from_t:
			var row := []
			for k in idx.size():
				row.append(final.get(k, Vector3.ZERO))
			hist.append(row)
			notes.append("%s cnt %d contact %s" % [ch.get(&"note"), body.get(&"stair_count"), str(ch.get(&"feet").get(&"contact"))])
	print(tag, "  ticks ", hist.size())
	for k in idx.size():
		var acc := []
		for i in range(2, hist.size()):
			var a: Vector3 = ((hist[i][k] as Vector3) - (hist[i - 1][k] as Vector3) * 2.0 + (hist[i - 2][k] as Vector3)) * 3600.0
			acc.append([a.length(), i])
		acc.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
		var med: float = acc[acc.size() / 2][0]
		var spikes := 0
		for a: Array in acc:
			if a[0] > 60.0:
				spikes += 1
		print("   %-12s median %.0f  top %.0f %.0f %.0f m/s2  ticks over 60: %d   worst at: %s" % [names[k], med, acc[0][0], acc[1][0], acc[2][0], spikes, notes[acc[0][1]]])
func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 3:
		await physics_frame
	var st := {}
	for s: Dictionary in (lab.get(&"course") as Node3D).get(&"stations"):
		st[s["label"]] = s
	var fl := Vector3(float(st["floor: one triangle mesh"]["x"]), 0.1, -3.5)
	await measure("FLAT walk", fl, 0.0, [6.0, 0.0, -1.0, 0.0, false], 150)
	var s: Dictionary = st["stairs 0.18 / 0.28 m x 10"]
	await measure("STAIRS up walk", (s["start"] as Vector3) + Vector3(0, 0, -1.5), 0.0, [6.0, 0.0, -1.0, 0.0, false], 130)
	await measure("STAIRS down walk", Vector3(float(s["x"]), float(s["top"]), -3.0 - 2.8 - 1.0), PI, [6.0, 0.0, 1.0, 0.0, false], 130)
	quit(0)
