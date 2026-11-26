extends SceneTree
## Stage 16: across a gap. At a run the body's own running jump, begun for him, and he runs on; at a walk or from
## standing, up to 0.94 of his leg stepped across in stride, wider (to the standing long jump) jumped. On every gap
## of the course. Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage16.gd

const FEET_WITHIN := 0.03
const END_WITHIN := 0.05

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var trav: Node
var skel: Skeleton3D
var stations: Array
var fails := 0
var feet_i := []
var stand := []
var final := []


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print("%s  %s" % ["ok  " if cond else "FAIL", what])


func _after() -> void:
	final.clear()
	for i: int in feet_i:
		final.append((skel.global_transform * skel.get_bone_global_pose(i)).origin)


## Go at the gap of `s` from `back` metres before its edge, on its near deck.
func go_at(s: Dictionary, back: float, run: bool, flip := -1.0) -> Dictionary:
	var deck := float(s["top"])
	var edge_z := float(s["edge_z"])
	lab.call(&"place", Vector3(float(s["x"]), deck, edge_z + back))
	body.rotation.y = 0.0
	for i in 30:
		await physics_frame
	var samples := []
	for i in 360:
		var rev := flip >= 0.0 and i >= int(flip * 60.0)
		samples.append({"mx": 0.0, "mz": 1.0 if rev else -1.0, "yaw": 0.0, "run": run, "jump": false, "crouch": false, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var before := int(trav.get(&"plays"))
	var out := {"played": false, "plan": {}, "end": Vector3.ZERO, "end_state": -1, "end_speed": 0.0, "feet": INF, "lowest": INF, "move_from": -1.0, "over": false, "over_speed": 0.0}
	var was_in := false
	var t := 0
	var far_z := edge_z - float(s["gap"])
	var beyond := -1
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		await process_frame
		t += 1
		var inm := bool(body.call(&"in_move"))
		if int(trav.get(&"plays")) > before and not bool(out["played"]):
			out["played"] = true
			out["plan"] = (trav.get(&"_plan") as Dictionary).duplicate()
			out["move_from"] = t / 60.0
		out["lowest"] = minf(float(out["lowest"]), body.global_position.y)
		if was_in and not inm:
			out["end"] = body.global_position
			out["end_state"] = int(body.get(&"state"))
			out["end_speed"] = (body.get(&"hvel") as Vector3).length()
			if final.size() == 4:
				var gy := body.global_position.y
				var worst := 0.0
				var nearer := INF
				for f in 2:
					var off := minf(absf(final[f * 2].y - gy - stand[f * 2]), absf(final[f * 2 + 1].y - gy - stand[f * 2 + 1]))
					worst = maxf(worst, off)
					nearer = minf(nearer, off)
				out["feet"] = nearer if float(out["end_speed"]) > 0.5 else worst
		# on the far deck, on the ground, a third of a second after he first is: where he is and how fast he goes
		if body.global_position.z < far_z - 0.1 and int(body.get(&"state")) == 0 and not inm:
			beyond += 1
			if beyond >= 20:
				out["over"] = absf(body.global_position.y - deck) < 0.05
				out["over_speed"] = (body.get(&"hvel") as Vector3).length()
				tape.call(&"stop")
		was_in = inm
		if body.global_position.y < deck - 0.9 or t > 340:
			tape.call(&"stop")
	out["refused"] = String(trav.get(&"refused"))
	return out


## From the top of block `a` sideways onto the next block `b`.
func go_side(a: Dictionary, b: Dictionary, run: bool) -> Dictionary:
	var way := signf(float(b["x"]) - float(a["x"]))
	var z := (a["probe"] as Vector3).z
	lab.call(&"place", Vector3(float(a["x"]) - way * 0.9, float(a["top"]), z))
	body.rotation.y = -PI * 0.5 * way
	for i in 30:
		await physics_frame
	var samples := []
	for i in 420:
		samples.append({"mx": way, "mz": 0.0, "yaw": 0.0, "run": run, "jump": false, "crouch": false, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var before := int(trav.get(&"plays"))
	var out := {"plan": {}, "lowest": INF, "over": false, "at": Vector3.ZERO}
	var t := 0
	var on_b := 0
	while int(tape.get(&"mode")) == 2 and t < 400:
		await physics_frame
		t += 1
		if int(trav.get(&"plays")) > before and (out["plan"] as Dictionary).is_empty():
			out["plan"] = (trav.get(&"_plan") as Dictionary).duplicate()
		var p := body.global_position
		out["lowest"] = minf(float(out["lowest"]), p.y)
		out["at"] = p
		if absf(p.x - float(b["x"])) < 1.2 and int(body.get(&"state")) == 0 and not bool(body.call(&"in_move")) and absf(p.y - float(b["top"])) < 0.05:
			on_b += 1
			if on_b >= 6:
				out["over"] = true
				break
		if p.y < 0.05 and absf(p.x - float(a["x"])) > 1.6 and absf(p.x - float(b["x"])) > 1.6:
			break               # on the ground between them
	tape.call(&"stop")
	out["refused"] = String(trav.get(&"refused"))
	return out


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 5:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	trav = lab.get(&"traverse")
	skel = (lab.get(&"character") as Node).get(&"skel")
	stations = (lab.get(&"course") as Node3D).get(&"stations")
	for n: String in ["LeftFoot", "LeftToeBase", "RightFoot", "RightToeBase"]:
		feet_i.append(skel.find_bone("mixamorig_" + n))
	skel.skeleton_updated.connect(_after)
	lab.call(&"place", Vector3(60.0, 0.0, 10.0))
	for i in 60:
		await physics_frame
		await process_frame
	for p: Vector3 in final:
		stand.append(p.y - body.global_position.y)
	var step_most := float(trav.get(&"STEP_ACROSS")) * float(trav.get(&"LEG"))
	var gaps: Array = stations.filter(func(q: Dictionary) -> bool: return String(q["kind"]) == "gap")
	for how: Array in [["from standing at its edge", 0.35, false], ["at a walk", 2.0, false], ["at a run", 3.4, true]]:
		for s: Dictionary in gaps:
			var w := float(s["gap"])
			var deck := float(s["top"])
			var r := await go_at(s, float(how[1]), bool(how[2]))
			var plan: Dictionary = r["plan"]
			var key := String(plan.get("key", ""))
			var want := "gap_run" if bool(how[2]) else ("gap_step" if w <= step_most + 0.01 else "gap_jump")
			var bad := ""
			if key != want:
				bad = "'%s' did not play (%s%s)" % [want, r["refused"], (", '%s' did" % key) if key != "" else ""]
			elif float(r["lowest"]) < deck - 0.05:
				bad = "he went down into the gap (%.2f m under the deck)" % (deck - float(r["lowest"]))
			elif not bool(r["over"]):
				bad = "he is not on the far side, on the ground"
			elif want == "gap_run":
				if float(r["over_speed"]) < 2.5:
					bad = "he does not run on (%.2f m/s a third of a second after he is down)" % float(r["over_speed"])
			else:
				var e: Vector3 = r["end"]
				var pe: Vector3 = plan["end"]
				if Vector2(e.x - pe.x, e.z - pe.z).length() > END_WITHIN or absf(e.y - deck) > 0.01:
					bad = "ended %.2f m from where planned, at height %.3f" % [Vector2(e.x - pe.x, e.z - pe.z).length(), e.y]
				elif int(r["end_state"]) != 0:
					bad = "ended in state %d" % int(r["end_state"])
				elif absf(float(r["end_speed"]) - float(plan["exit_speed"])) > 0.05:
					bad = "handed back at %.2f m/s, planned %.2f" % [float(r["end_speed"]), float(plan["exit_speed"])]
				elif float(r["feet"]) > FEET_WITHIN:
					bad = "a foot %.1f cm off the ground as he is handed back" % (float(r["feet"]) * 100.0)
			ok(bad == "", "%s, %s: %s, never under the deck (lowest %.2f m over it), on the far side on the ground%s%s" % [s["label"], how[0],
					{"gap_run": "the running jump, begun for him", "gap_step": "stepped across in stride", "gap_jump": "jumped"}[want], float(r["lowest"]) - deck,
					(", running on at %.1f m/s" % float(r["over_speed"])) if want == "gap_run" else (", where planned (foot %.1f cm off the ground)" % (float(r["feet"]) * 100.0)),
					"" if bad == "" else " -- " + bad])
	# Too wide to clear, the far edge within reach (Yasin, 26 Nov: "for gaps longer than 2m, if we can reach, cwe should
	# catch the edge and climb up"). Gaps built here beyond the last station (the course's widest is 2.0 m).
	var course: Node3D = lab.get(&"course")
	var nx := float(stations[stations.size() - 1]["x"]) + 6.0
	var built := []
	for w: float in [2.6, 3.2, 5.5, 4.0]:
		course.call(&"_box", Vector3(nx, 0.5, 10.0), Vector3(2.4, 1.0, 12.0))
		course.call(&"_box", Vector3(nx, 0.5, 4.0 - w - 3.0), Vector3(2.4, 1.0, 6.0))
		built.append({"kind": "gap", "label": "gap %.1f m (built for this test)" % w, "top": 1.0, "gap": w, "edge_z": 4.0, "x": nx})
		nx += 4.0
	for i in 5:
		await physics_frame
	for c: Array in [[built[0], "at a walk", 2.0, false, "gap_jump", true], [built[1], "at a walk", 2.0, false, "", false],
			[built[1], "at a run", 6.0, true, "gap_catch", true], [built[3], "at a run", 6.0, true, "gap_catch", true], [built[2], "at a run", 6.0, true, "", false]]:
		var s: Dictionary = c[0]
		var r := await go_at(s, float(c[2]), bool(c[3]))
		var key := String((r["plan"] as Dictionary).get("key", ""))
		if not bool(c[5]):
			ok(key == "", "%s, %s: out of reach, no jump is begun for him (%s)" % [s["label"], c[1], ("'%s' played" % key) if key != "" else String(r["refused"])])
			continue
		var bad := ""
		if key != String(c[4]):
			bad = "'%s' did not play (%s%s)" % [c[4], r["refused"], (", '%s' did" % key) if key != "" else ""]
		elif float(r["lowest"]) < 0.15:
			bad = "he went down to the bottom of the gap"
		elif not bool(r["over"]):
			bad = "he is not on the far side, on the ground"
		ok(bad == "", "%s, %s: he jumps for the far edge, catches it and climbs up: on the far side on the ground (at his lowest %.2f m under its top)%s" % [
				s["label"], c[1], 1.0 - float(r["lowest"]), "" if bad == "" else " -- " + bad])
	# Between neighbouring blocks of the course, sideways (Yasin, 26 Nov: "the jumps between the first blocks dont
	# trigger ... AND HE KEEPS FALLING DIRECTLY WHEN WALKING"): a metre of gap between each pair, the far block a
	# little higher or lower, the gap between the first ones only as deep as they are high.
	var by_label := {}
	for q: Dictionary in stations:
		by_label[String(q["label"])] = q
	for pair: Array in [["step 0.10 m", "step 0.15 m"], ["step 0.25 m", "step 0.30 m"], ["step 0.55 m", "step 0.60 m"], ["step 0.60 m", "step 0.55 m"],
			["deep wall 1.00 m", "deep wall 1.10 m"], ["deep wall 1.10 m", "deep wall 1.40 m"], ["deep wall 1.40 m", "deep wall 1.10 m"],
			["deep wall 1.40 m", "deep wall 1.80 m"], ["deep wall 2.20 m", "deep wall 1.80 m"]]:
		if not by_label.has(pair[0]) or not by_label.has(pair[1]):
			ok(false, "no such blocks: %s, %s" % pair)
			continue
		var a: Dictionary = by_label[pair[0]]
		var b: Dictionary = by_label[pair[1]]
		for run: bool in [false, true]:
			var r := await go_side(a, b, run)
			var lower := minf(float(a["top"]), float(b["top"]))
			var bad := ""
			if not bool(r["over"]):
				bad = "he is not on the far block, on the ground (he is at %s; %s)" % [r["at"], r["refused"]]
			elif float(r["lowest"]) < lower - 0.80:
				bad = "he went down %.2f m under the lower block" % (lower - float(r["lowest"]))
			ok(bad == "", "from %s to %s, %s: he gets across onto it (%s; at his lowest %.2f m against the lower of the two)%s" % [pair[0], pair[1], "at a run" if run else "at a walk",
					String((r["plan"] as Dictionary).get("key", "no move")), float(r["lowest"]) - lower, "" if bad == "" else " -- " + bad])
	# cancelling: the stick reversed a moment into the jump from a walk changes nothing
	for s: Dictionary in [gaps[1], gaps[gaps.size() - 1]]:
		var a := await go_at(s, 2.0, false)
		var b := await go_at(s, 2.0, false, float(a["move_from"]) + 0.3)
		var off := INF if not bool(b["played"]) else (b["end"] as Vector3).distance_to((b["plan"] as Dictionary)["end"])
		ok(off < 0.01, "%s: the stick reversed 0.3 s into the jump changes nothing: he ends %.3f m from where it was going" % [s["label"], off])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
