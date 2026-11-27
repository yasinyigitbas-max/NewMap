extends SceneTree
## The same input on the script version and on the C++ version (`-- --native`): every tick's numbers written to a file.
## Run by tools/traversal/parity.sh, which runs both and compares them. (The rules of the C++ port: reports/TRAVERSAL
## JOB BOARD.md. A layer is proven when the two files are the same, byte for byte.)
var lab: Node3D
var _skel: Skeleton3D
var _joints: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _pose_hash := 0
const JOINTS := ["Hips", "Head", "LeftHand", "RightHand", "LeftFoot", "RightFoot"]


func _pose_done() -> void:
	for i in JOINTS.size():
		_joints[i] = _skel.get_bone_global_pose(_skel.find_bone("mixamorig_" + JOINTS[i])).origin
	var all := PackedFloat32Array()
	for b in _skel.get_bone_count():
		var g := _skel.get_bone_global_pose(b)
		all.append(g.origin.x); all.append(g.origin.y); all.append(g.origin.z)
		for c in 3:
			var col := g.basis[c]
			all.append(col.x); all.append(col.y); all.append(col.z)
	_pose_hash = hash(all.to_byte_array())

var body: CharacterBody3D
var tape: Node
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var out := ""
	var ticks := 12000
	var seed_n := 7
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		if arg.begins_with("--ticks="):
			ticks = int(arg.trim_prefix("--ticks="))
		if arg.begins_with("--seed="):
			seed_n = int(arg.trim_prefix("--seed="))
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 5:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	print("body is ", body.get_class(), "  script: ", body.get_script() != null)
	var det: RefCounted = ClassDB.instantiate(&"TravDetector") if ("--native" in OS.get_cmdline_user_args() and ClassDB.class_exists(&"TravDetector")) else (load("res://traversal/detect/detector.gd") as GDScript).new()
	det.set(&"body", body)
	print("detector is ", det.get_class(), "  script: ", det.get_script() != null)
	# the finished pose of every bone, each tick (it can only be read when the skeleton says it is finished)
	var chr: Node = lab.get(&"character")
	if chr != null and chr.get(&"skel") != null:
		_skel = chr.get(&"skel")
		_skel.skeleton_updated.connect(_pose_done)
	var trav: Node = lab.get(&"traverse")
	if trav != null:
		print("moves are ", trav.get_class(), "  script: ", trav.get_script() != null)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	var st: Array = ((lab.get(&"course") as Node3D).get(&"stations") as Array) + ((lab.get(&"course") as Node3D).get(&"extras") as Array)
	var keys := {"mx": 0.0, "mz": 0.0, "yaw": 0.0, "run": false, "jump": false, "crouch": false, "act": false, "text": false, "call": false}
	var f := FileAccess.open(out, FileAccess.WRITE)
	var hold := 0
	var names := ["state", "hvel", "vy", "ground_y", "narrow", "squeeze", "stairs", "terrain", "spot_total", "radius", "jump_timer", "land_hold", "crouched", "stair_tread", "grade", "phone", "_wish", "squeeze_side", "air_time", "move_clip_t"]
	var lanes := "--lanes" in OS.get_cmdline_user_args()
	var no_act := "--noact" in OS.get_cmdline_user_args()
	if lanes:
		ticks = st.size() * 4 * 300
	for t in ticks:
		if lanes:
			if t % 300 == 0:
				var s2: Dictionary = st[(t / 1200) % st.size()]
				var kind := (t / 300) % 4
				lab.call(&"place", (s2["start"] as Vector3) + Vector3([0.0, 0.0, 0.12, -0.2][kind], 0.0, 0.0))
				body.rotation.y = 0.0
				keys = {"mx": [0.0, 0.0, 0.15, -0.1][kind], "mz": -1.0, "yaw": 0.0, "run": kind == 1 or kind == 3, "jump": false, "crouch": kind == 2, "act": false, "text": false, "call": false}
				hold = 100000
			if (t / 300) % 4 == 3:
				keys["jump"] = (t % 300) % 70 < 4
			if (t % 300) == 200:
				keys["mz"] = 1.0            # and back the way he came
		elif t % 600 == 0:
			var s: Dictionary = st[rng.randi_range(0, st.size() - 1)]
			lab.call(&"place", s["start"])
			body.rotation.y = 0.0
		if hold <= 0:
			hold = rng.randi_range(10, 150)
			var a := rng.randf_range(-PI, PI)
			var m := 1.0 if rng.randf() < 0.8 else (0.0 if rng.randf() < 0.5 else rng.randf())
			# (mostly along the station's lane, as stage 1's walk does)
			if rng.randf() < 0.6:
				a = [0.0, PI, 0.3, -0.3][rng.randi_range(0, 3)] + PI
			keys["mx"] = sin(a) * m
			keys["mz"] = cos(a) * m
			keys["run"] = rng.randf() < 0.4
			keys["crouch"] = rng.randf() < 0.08
			keys["jump"] = rng.randf() < 0.15
			keys["act"] = rng.randf() < 0.03 and not no_act
			keys["text"] = rng.randf() < 0.02
			keys["call"] = rng.randf() < 0.02
		hold -= 1
		tape.set(&"tape", [keys.duplicate()])
		tape.call(&"replay")
		await physics_frame
		var line := PackedFloat64Array([body.global_position.x, body.global_position.y, body.global_position.z, body.rotation.y])
		for n: String in names:
			var v: Variant = body.get(n)
			if v is Vector3:
				line.append((v as Vector3).x); line.append((v as Vector3).y); line.append((v as Vector3).z)
			else:
				line.append(float(v))
		if t % 5 == 0:
			# the measuring routine, asked the way he faces and a little to each side: every number of its records
			for turn: float in [0.0, 0.5, -0.5]:
				var way := (-body.global_transform.basis.z).rotated(Vector3.UP, turn)
				_add(line, det.call(&"measure", way))
				_add(line, det.call(&"measure_edge", way))
			line.append(1.0 if bool(det.call(&"_fits", body.global_position + Vector3(0.3, 0.0, 0.0), 1.80)) else 0.0)
		# six joints as they are, and one number made of every bone's place and turn (the same number = the same pose)
		for v3: Vector3 in _joints:
			line.append(v3.x); line.append(v3.y); line.append(v3.z)
		line.append(float(_pose_hash & 0xFFFFFF)); line.append(float((_pose_hash >> 24) & 0xFFFFFF))
		# the moves: how many were begun, why the last was refused, and every number of the plan of the move in hand
		if trav != null:
			line.append(float(int(trav.get(&"plays"))))
			line.append(float(String(trav.get(&"refused")).hash()))
			_add_any(line, trav.get(&"_plan"))
			_add_any(line, trav.get(&"record"))
		f.store_var(line)
		if keys["jump"] and hold < 5:
			keys["jump"] = false
	f.close()
	print("written ", ticks, " ticks")
	quit()


## Every number of a record, in the order of its keys sorted by name (a text counts by its hash).
func _add(line: PackedFloat64Array, rec: Dictionary) -> void:
	var keys := rec.keys()
	keys.sort()
	line.append(float(keys.size()))
	for k: String in keys:
		var v: Variant = rec[k]
		if v is Vector3:
			line.append((v as Vector3).x); line.append((v as Vector3).y); line.append((v as Vector3).z)
		elif v is String:
			line.append(float((v as String).hash()))
		else:
			line.append(float(v))


## Every number of anything a plan holds: a record within a record and a list are gone through in turn.
func _add_any(line: PackedFloat64Array, v: Variant) -> void:
	if v is Dictionary:
		var keys := (v as Dictionary).keys()
		keys.sort()
		line.append(float(keys.size()))
		for k: String in keys:
			line.append(float(k.hash()))
			_add_any(line, (v as Dictionary)[k])
	elif v is Array:
		line.append(float((v as Array).size()))
		for e: Variant in (v as Array):
			_add_any(line, e)
	elif v is Vector3:
		line.append((v as Vector3).x); line.append((v as Vector3).y); line.append((v as Vector3).z)
	elif v is String or v is StringName:
		line.append(float(String(v).hash()))
	elif v is bool or v is int or v is float:
		line.append(float(typeof(v))); line.append(float(v))
	else:
		line.append(-12345.0)
