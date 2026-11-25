extends SceneTree
## Stage 5 test: starts, stops and turns on the spot. The report's bars: stopping from a walk takes one to two steps
## and from a run several, with no slide after the feet plant; a 180 degree turn on the spot takes about three
## steps; releasing and re-pressing the stick mid-stop recovers without a pop.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_starts.gd

var fails := 0
var lab: Node3D
var body: CharacterBody3D
var tape: Node
var character: Node3D
var skel: Skeleton3D
var feet: RefCounted
var centre := Vector3.ZERO
var legs: Array[int] = []


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("PASS  " if cond else "FAIL  ") + what)


func _initialize() -> void:
	_run.call_deferred()


func drive(at: Vector3, segments: Array, tail := 0.0) -> Array:
	lab.call(&"place", at)
	body.rotation.y = 0.0
	for i in 40:
		await physics_frame
	if tail > 0.0:
		segments = segments.duplicate()
		segments.append([tail, 0.0, 0.0, 0.0, false])
	tape.call(&"make", segments)
	tape.call(&"replay")
	var rec: Array = []
	var last: Array[Quaternion] = []
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		# the biggest turn of any thigh or shin since the tick before (degrees): a pop shows as a spike
		var jump := 0.0
		var now: Array[Quaternion] = []
		for b in legs:
			now.append(skel.get_bone_pose_rotation(b))
		if not last.is_empty():
			for i in legs.size():
				jump = maxf(jump, rad_to_deg(last[i].angle_to(now[i])))
		last = now
		rec.append({"p": body.global_position, "v": (body.get(&"hvel") as Vector3).length(), "yaw": body.rotation.y,
			"sub": String(character.get(&"sub")), "jump": jump,
			"ball": (feet.get(&"final_ball") as Array).duplicate(), "contact": (feet.get(&"contact") as Array).duplicate()})
	return rec


func subs(rec: Array, from := 0) -> String:
	var out: Array[String] = []
	for i in range(from, rec.size()):
		if out.is_empty() or out[out.size() - 1] != rec[i]["sub"]:
			out.append(rec[i]["sub"])
	return " > ".join(out)


func worst_jump(rec: Array, from := 0) -> float:
	var m := 0.0
	for i in range(from, rec.size()):
		m = maxf(m, rec[i]["jump"])
	return m


func drift(rec: Array, from: int) -> float:
	var worst := 0.0
	for f in 2:
		var start := -1
		for i in range(from, rec.size() + 1):
			var down: bool = i < rec.size() and bool(rec[i]["contact"][f])
			if down and start < 0:
				start = i
			elif not down and start >= 0:
				var a: Vector3 = rec[start]["ball"][f]
				for j in range(start, i):
					var d: Vector3 = (rec[j]["ball"][f] as Vector3) - a
					worst = maxf(worst, Vector2(d.x, d.z).length())
				start = -1
	return worst


func test_start(run: bool) -> void:
	var rec := await drive(centre + Vector3(0.0, 0.0, 5.0), [[3.0 if not run else 1.6, 0.0, -1.0, 0.0, run]])
	var want := 4.5 if run else 1.4
	var t90 := -1
	for i in rec.size():
		if t90 < 0 and rec[i]["v"] >= want * 0.9:
			t90 = i
	ok((subs(rec).begins_with("loop > start > loop") or subs(rec).begins_with("start > loop")) and drift(rec, 0) < 0.02,
		"start, %s: shows %s; 90 %% of speed after %.2f s; biggest leg turn in a tick %.1f deg; planted feet drift %.1f cm at most (bar 2)" %
		["run" if run else "walk", subs(rec), t90 / 60.0, worst_jump(rec), drift(rec, 0) * 100.0])


func test_stop(run: bool) -> void:
	var lead := 1.6 if run else 2.5
	var rec := await drive(centre + Vector3(0.0, 0.0, 5.0), [[lead, 0.0, -1.0, 0.0, run]], 3.0)
	var from := int(lead * 60.0)
	var p0: Vector3 = rec[from]["p"]
	var still := -1
	for i in range(from, rec.size()):
		if still < 0 and rec[i]["v"] < 0.02:
			still = i
	var dist := ((rec[rec.size() - 1]["p"] as Vector3) - p0).length()
	var secs := (still - from) / 60.0
	# a walking step is about 0.55 s and 0.7 m; "under two steps" at a walk, "5 steps and 2.9 m" from a flat-out run
	var most_d := 2.9 if run else 1.4
	var slide := drift(rec, still)
	ok(subs(rec, from).contains("stop") and rec[rec.size() - 1]["sub"] == "loop" and dist < most_d and slide < 0.02,
		"stop, %s: shows %s; still after %.2f s and %.2f m (bar %.1f m); once still the planted feet move %.1f cm (bar 2); biggest leg turn in a tick %.1f deg" %
		["run" if run else "walk", subs(rec, from), secs, dist, most_d, slide * 100.0, worst_jump(rec, from)])


func test_repress() -> void:
	var rec := await drive(centre + Vector3(0.0, 0.0, 5.0), [[2.5, 0.0, -1.0, 0.0, false], [0.25, 0.0, 0.0, 0.0, false], [1.5, 0.0, -1.0, 0.0, false]])
	var from := int(2.5 * 60.0)
	var jump := worst_jump(rec, from)
	var steady := worst_jump(rec.slice(60, from))
	ok(subs(rec, from).contains("stop > loop") and jump < maxf(steady * 2.0, 12.0),
		"let go and press again mid-stop (walk): shows %s; biggest leg turn in a tick %.1f deg (steady walking %.1f; bar twice that)" % [subs(rec, from), jump, steady])


func test_spot(run: bool, deg: float) -> void:
	var a := deg_to_rad(deg)
	var rec := await drive(centre, [[2.6, -sin(a), -cos(a), 0.0, run]])
	var faced := -1
	var moved := 0.0
	for i in rec.size():
		if faced < 0:
			moved = ((rec[i]["p"] as Vector3) - (rec[0]["p"] as Vector3)).length()
			if absf(wrapf(a - float(rec[i]["yaw"]), -PI, PI)) <= deg_to_rad(15.5):
				faced = i
	var secs := faced / 60.0
	# 3 to 4 steps for 180 degrees (about 75 deg a step, 0.55 s a step); his turn clips: 1.00 s walking, 0.67 s running
	var steps := absf(deg) / 75.0
	ok(subs(rec).contains("spot") and faced > 0 and secs <= steps * 0.55 + 0.1 and (absf(deg) - 15.0) / secs < 300.0 and moved < 0.15,
		"turn on the spot, %s, %d deg: shows %s; facing it after %.2f s (bar %.2f s, and under 300 deg/s); moved %.2f m meanwhile; biggest leg turn in a tick %.1f deg" %
		["run" if run else "walk", int(deg), subs(rec), secs, steps * 0.55 + 0.1, moved, worst_jump(rec)])


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 3:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	character = lab.get(&"character")
	skel = character.get(&"skel")
	feet = character.get(&"feet")
	for n: String in ["LeftUpLeg", "LeftLeg", "RightUpLeg", "RightLeg"]:
		legs.append(skel.find_bone("mixamorig_" + n))
	for s: Dictionary in (lab.get(&"course") as Node3D).get(&"stations"):
		if s["label"] == "floor: one triangle mesh":
			centre = Vector3(float(s["x"]), 0.1, -9.0)
	await test_start(false)
	await test_start(true)
	await test_stop(false)
	await test_stop(true)
	await test_repress()
	await test_spot(false, 90.0)
	await test_spot(false, -90.0)
	await test_spot(false, 180.0)
	await test_spot(true, 180.0)
	await test_spot(true, -130.0)
	print("RESULT " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
