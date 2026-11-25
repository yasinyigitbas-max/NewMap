extends SceneTree
## Stage 3 test: do planted feet stay where they are planted? At a steady walk and a steady run, the ball of each
## foot is followed while it is on the ground; the report's bar is "drifts less than about 2 cm".
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_feet.gd

var fails := 0
var lab: Node3D
var body: CharacterBody3D
var tape: Node
var skel: Skeleton3D
var centre := Vector3.ZERO


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("PASS  " if cond else "FAIL  ") + what)


func _initialize() -> void:
	_run.call_deferred()


func gait(run: bool, label: String) -> void:
	lab.call(&"place", centre + Vector3(0.0, 0.0, 5.5))
	body.rotation.y = 0.0
	for i in 20:
		await physics_frame
	var secs := 2.4 if run else 6.0
	tape.call(&"make", [[secs, 0.0, -1.0, 0.0, run]])
	tape.call(&"replay")
	var toes := [skel.find_bone("mixamorig_LeftToeBase"), skel.find_bone("mixamorig_RightToeBase")]
	var track := [[], []]
	var t := 0
	var speed := 0.0
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		t += 1
		if t > int(secs * 60.0 * 0.45):      # steady by then
			speed = (body.get(&"hvel") as Vector3).length()
			for f in 2:
				track[f].append(skel.global_transform * skel.get_bone_global_pose(toes[f]).origin)
	var worst := 0.0
	var plants := 0
	for f in 2:
		var low := 99.0
		for p: Vector3 in track[f]:
			low = minf(low, p.y)
		var start := -1
		for i in track[f].size() + 1:
			var down: bool = i < track[f].size() and (track[f][i] as Vector3).y < low + 0.015
			if down and start < 0:
				start = i
			elif not down and start >= 0:
				if i - start >= 4 and start > 0 and i < track[f].size():
					var a: Vector3 = track[f][start]
					var far := 0.0
					for j in range(start, i):
						var d: Vector3 = (track[f][j] as Vector3) - a
						far = maxf(far, Vector2(d.x, d.z).length())
					worst = maxf(worst, far)
					plants += 1
				start = -1
	ok(plants >= 2 and worst < 0.02, "%s at %.2f m/s: over %d foot plants the ball of the foot drifts %.1f cm at most (bar 2 cm)" % [label, speed, plants, worst * 100.0])


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 3:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	skel = (lab.get(&"character") as Node).get(&"skel")
	for s: Dictionary in (lab.get(&"course") as Node3D).get(&"stations"):
		if s["label"] == "floor: one triangle mesh":
			centre = Vector3(float(s["x"]), 0.1, -9.0)
	await gait(false, "walk")
	await gait(true, "run")
	print("RESULT " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
