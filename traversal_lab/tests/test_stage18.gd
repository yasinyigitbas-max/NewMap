extends SceneTree
## Stage 18, gaps between walls. The study: "walk straight through at 0.60 m and wider, turn the shoulders from 0.45
## to 0.60 m starting half a metre before, go fully sideways from 0.45 down to 0.25 m, and block below about 0.20 m";
## of the shoulder turn, people "begin turning about half a metre before it, and do not slow down".
## The passages of the course (0.4, 0.5, 0.6, 0.8 m) and gaps built here (0.20, 0.26, 0.30, 0.46 m).
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage18.gd

const NAMES := ["Head", "LeftShoulder", "RightShoulder", "LeftForeArm", "RightForeArm", "LeftHand", "RightHand", "Hips", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]
const IN_WALL_MOST := 0.03      # OURS, how it is told: no joint's centre is further into a wall than this (m)

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var chr: Node
var skel: Skeleton3D
var fails := 0
var J := {}


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print("%s  %s" % ["ok  " if cond else "FAIL", what])


func _after() -> void:
	for n: String in NAMES:
		J[n] = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("mixamorig_" + n))).origin


## At the gap of width `w` round x = `x`, its walls from z = `zc` + 1.5 to `zc` - 1.5: from 3.5 m before its middle,
## the stick forward for `go` ticks (all the way if 0), then at rest for `rest` ticks.
func through(w: float, x: float, zc: float, run: bool, off: float, go := 0, rest := 0) -> Dictionary:
	while bool(body.call(&"in_move")):
		await physics_frame
	lab.call(&"place", Vector3(x + off, 0.0, zc + 3.5))
	body.rotation.y = 0.0
	for i in 20:
		await physics_frame
	var samples := []
	for i in 900:
		samples.append({"mx": 0.0, "mz": -1.0 if (go == 0 or i < go) else 0.0, "yaw": 0.0, "run": run, "jump": false, "crouch": false, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var out := {"kinds": {}, "slow": INF, "fast": 0.0, "turn_least": INF, "turn_most": 0.0, "from": INF, "in_wall": 0.0, "in_wall_at": "", "past": 0.0, "at_rest": {}}
	var t := 0
	while t < (go + rest if go > 0 else 860):
		await physics_frame
		await process_frame
		t += 1
		var z := body.global_position.z
		if int(body.get(&"squeeze")) > 0 and float(out["from"]) == INF:
			out["from"] = z - (zc + 1.5)
		if z < zc + 1.3 and z > zc - 1.3 and body.global_position.y < 0.3:
			(out["kinds"] as Dictionary)[int(body.get(&"squeeze"))] = true
			var sp := (body.get(&"hvel") as Vector3).length()
			if go == 0:
				out["slow"] = minf(float(out["slow"]), sp)
				out["fast"] = maxf(float(out["fast"]), sp)
			for n: String in NAMES:
				var over := absf((J[n] as Vector3).x - x) - w * 0.5
				if over > float(out["in_wall"]):
					out["in_wall"] = over
					out["in_wall_at"] = n
			# how far the line of his shoulders is turned from square to his way
			var sh: Vector3 = (J["RightShoulder"] as Vector3) - (J["LeftShoulder"] as Vector3)
			var a := absf(rad_to_deg(atan2(sh.z, sh.x)))
			a = minf(a, 180.0 - a)
			out["turn_least"] = minf(float(out["turn_least"]), a)
			out["turn_most"] = maxf(float(out["turn_most"]), a)
		out["past"] = (zc - 1.5) - z
		if go == 0 and z < zc - 2.0:
			break
	if go > 0:
		var feet_in := true
		for n: String in ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]:
			feet_in = feet_in and absf((J[n] as Vector3).x - x) < w * 0.5
		out["at_rest"] = {"kind": int(body.get(&"squeeze")), "feet_in": feet_in, "side_t": float(chr.get(&"_side_t")), "z": body.global_position.z - zc,
				"apart": absf(((J["LeftFoot"] as Vector3) - (J["RightFoot"] as Vector3)).z)}
	tape.call(&"stop")
	return out


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 5:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	chr = lab.get(&"character")
	skel = chr.get(&"skel")
	skel.skeleton_updated.connect(_after)
	var course: Node3D = lab.get(&"course")
	var stations: Array = course.get(&"stations")
	var gaps := []
	for s: Dictionary in stations:
		if String(s["kind"]) == "passage":
			gaps.append([float(s["width"]), float(s["x"]), -5.0, String(s["label"])])
	var x0 := float(stations[stations.size() - 1]["x"]) + 8.0
	var k := 0
	for w: float in [0.20, 0.26, 0.30, 0.46]:
		var x := x0 + 2.6 * k
		k += 1
		course.call(&"_box", Vector3(x - w * 0.5 - 0.5, 1.25, 8.5), Vector3(1.0, 2.5, 3.0))
		course.call(&"_box", Vector3(x + w * 0.5 + 0.5, 1.25, 8.5), Vector3(1.0, 2.5, 3.0))
		gaps.append([w, x, 8.5, "a gap %.2f m wide (built for this test)" % w])
	for i in 5:
		await physics_frame
	var side_pace := float(body.get(&"SQUEEZE_SPEED"))
	var open_pace := {}
	# the widest first: its pace is what "do not slow down" is held to
	gaps.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	for g: Array in gaps:
		var w := float(g[0])
		var band := 0 if w >= 0.60 - 0.001 else (1 if w >= 0.45 - 0.001 else (2 if w >= 0.25 - 0.001 else -1))
		for run: bool in [false, true]:
			if band < 0 and run:
				continue                # (at a run a 2.5 m wall is climbed: the wall climb of stage 14, not this stage)
			for off: float in ([0.0, 0.08] if w >= 0.4 else [0.0]):
				var r := await through(w, float(g[1]), float(g[2]), run, off)
				var how := "%s, at a %s%s" % [g[3], "run" if run else "walk", "" if off == 0.0 else ", %.2f m off its middle" % off]
				var kinds: Array = (r["kinds"] as Dictionary).keys()
				if band < 0:
					ok(float(r["past"]) < -2.5, "%s: he does not go through (stopped %.2f m before its mouth)" % [how, -float(r["past"]) - 3.0])
					continue
				ok(float(r["past"]) > 0.3, "%s: he goes through (%.2f m past its far end)" % [how, float(r["past"])])
				if band == 0:
					ok(kinds == [0], "%s: walked straight through as he is (seen: %s)" % [how, kinds])
					if off == 0.0:
						open_pace[run] = float(r["slow"])
						ok(float(r["turn_most"]) < 20.0, "%s: his shoulders stay square to his way (turned at most %.0f degrees)" % [how, float(r["turn_most"])])
				elif band == 1:
					ok(kinds == [1], "%s: taken as a gap for turned shoulders all the way (seen: %s)" % [how, kinds])
					if off == 0.0:
						ok(float(r["turn_least"]) > 20.0 and float(r["turn_most"]) < 62.0, "%s: his shoulders are turned in it (%.0f to %.0f degrees; the study's lower and mid back turn 15 + 47 at most)" % [how, float(r["turn_least"]), float(r["turn_most"])])
						ok(float(r["slow"]) >= float(open_pace.get(run, 0.0)) * 0.9, "%s: he does not slow down (%.2f m/s at his slowest in it; %.2f through the 0.6 m passage)" % [how, float(r["slow"]), float(open_pace.get(run, 0.0))])
						if not run:
							ok(float(r["from"]) > 0.3 and float(r["from"]) < 0.7, "%s: the turn begins %.2f m before it (the study: half a metre)" % [how, float(r["from"])])
							ok(float(r["in_wall"]) <= IN_WALL_MOST, "%s: no joint is in a wall (the furthest %.3f m: %s)" % [how, float(r["in_wall"]), r["in_wall_at"]])
				else:
					ok(kinds == [2], "%s: taken as a gap to go through sideways all the way (seen: %s)" % [how, kinds])
					ok(float(r["fast"]) <= side_pace + 0.05, "%s: at the side step's pace in it (at most %.2f m/s; %.2f)" % [how, float(r["fast"]), side_pace])
					if off == 0.0:
						ok(float(r["turn_least"]) > 75.0, "%s: he is sideways in it (the line of his shoulders at least %.0f degrees from square)" % [how, float(r["turn_least"])])
						ok(float(r["in_wall"]) <= IN_WALL_MOST, "%s: no joint is in a wall (the furthest %.3f m: %s)" % [how, float(r["in_wall"]), r["in_wall_at"]])
		if band == 2:
			# standing still in it: he stays sideways, his feet in the gap, and the side step runs on to feet together
			var st := await through(w, float(g[1]), float(g[2]), false, 0.0, 300, 150)
			var a: Dictionary = st["at_rest"]
			ok(int(a["kind"]) == 2 and bool(a["feet_in"]) and float(a["side_t"]) == 0.0 and absf(float(a["z"])) < 1.4,
					"%s, standing still in it: he stays sideways, his feet inside it, the side step at its end (kind %d, feet inside %s, the step at %.2f s, %.2f m from its middle, his ankles %.2f m apart along it)" % [g[3], int(a["kind"]), a["feet_in"], float(a["side_t"]), float(a["z"]), float(a["apart"])])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
