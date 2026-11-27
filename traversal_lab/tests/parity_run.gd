extends SceneTree
## The same input on the script version and on the C++ version (`-- --native`): every tick's numbers written to a file.
## Run by tools/traversal/parity.sh, which runs both and compares them. (The rules of the C++ port: reports/TRAVERSAL
## JOB BOARD.md. A layer is proven when the two files are the same, byte for byte.)
var lab: Node3D
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
		f.store_var(line)
		if keys["jump"] and hold < 5:
			keys["jump"] = false
	f.close()
	print("written ", ticks, " ticks")
	quit()
