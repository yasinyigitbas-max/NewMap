extends SceneTree
## Stage 11: climbing onto something deep of 0.50 to 1.10 m. The study's four tests for a traversal move (see
## test_stage8.gd), on every step and wall of the course, come at from standing against it, at a walk and at a run.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage11.gd

const FEET_WITHIN := 0.03       # the study: "within about 3 cm"
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


## Go at the face of `s` from `back` metres in front of it; `flip` = the stick is reversed from that many seconds on.
func go_at(s: Dictionary, back: float, run: bool, flip := -1.0) -> Dictionary:
	lab.call(&"place", Vector3(float(s["x"]), 0.0, -3.0 + back))
	body.rotation.y = 0.0
	for i in 30:
		await physics_frame
	var samples := []
	for i in 300:
		var rev := flip >= 0.0 and i >= int(flip * 60.0)
		samples.append({"mx": 0.0, "mz": 1.0 if rev else -1.0, "yaw": 0.0, "run": run, "jump": false, "crouch": false, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var before := int(trav.get(&"plays"))
	var out := {"played": false, "plan": {}, "end": Vector3.ZERO, "end_state": -1, "end_speed": 0.0, "feet": INF, "move_from": -1.0, "high": 0.0, "nearer": INF}
	var was_in := false
	var t := 0
	var after := -1
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		await process_frame
		t += 1
		var inm := bool(body.call(&"in_move"))
		if inm and not was_in:
			out["played"] = true
			out["plan"] = (trav.get(&"_plan") as Dictionary).duplicate()
			out["move_from"] = t / 60.0
		if was_in and not inm:
			out["end"] = body.global_position
			out["end_state"] = int(body.get(&"state"))
			out["end_speed"] = (body.get(&"hvel") as Vector3).length()
			# both feet as he is handed back: how far the worse foot is off the top (ball or heel, whichever is nearer)
			if final.size() == 4:
				var gy := body.global_position.y
				var worst := 0.0
				for f in 2:
					var off := minf(absf(final[f * 2].y - gy - stand[f * 2]), absf(final[f * 2 + 1].y - gy - stand[f * 2 + 1]))
					worst = maxf(worst, off)
					out["nearer"] = minf(float(out["nearer"]), off)
				# (handed back at a run only one foot is on the ground: there it is the nearer foot that is held to it)
				out["feet"] = float(out["nearer"]) if run else worst
			tape.call(&"stop")
		was_in = inm
		out["high"] = maxf(float(out["high"]), body.global_position.y)
		# (stopped once he is well onto the top, or has had time to be: he is not to walk on off its far side)
		if not inm and int(trav.get(&"plays")) == before and (t > 200 or body.global_position.z < -3.8):
			tape.call(&"stop")
	out["refused"] = String(trav.get(&"refused"))
	out["rest"] = body.global_position
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
	var band: Array = trav.get(&"ON_BAND")
	var inside: Array[Dictionary] = []
	for how: Array in [["from standing against it", 0.27, false], ["at a walk", 1.6, false], ["at a run", 3.2, true]]:
		for s: Dictionary in stations:
			if not (String(s["kind"]) in ["step", "wall_deep", "wall_thin"]) or float(s["top"]) > 1.5 or float(s["top"]) < 0.3:
				continue
			var h := float(s["top"])
			var should := h > float(band[0]) + 0.001 and h <= float(band[1]) + 0.001 and float(s["depth"]) >= 1.0
			var r := await go_at(s, float(how[1]), bool(how[2]))
			var key := String((r["plan"] as Dictionary).get("key", ""))
			if not should:
				ok(not (key in ["step_on", "jump_on"]), "%s, %s: not this move's, climbing on is not played (%s)" % [s["label"], how[0],
						("taken by the move '%s'" % key) if key != "" else "he is stopped: " + String(r["refused"])])
				continue
			if how[0] == "at a walk":
				inside.append(s)
			var plan: Dictionary = r["plan"]
			var bad := ""
			if not (key in ["step_on", "jump_on"]):
				bad = "did not play (%s%s)" % [r["refused"], (", the move '%s' did" % key) if key != "" else ""]
			else:
				var want: Vector3 = plan["end"]
				var end: Vector3 = r["end"]
				if Vector2(end.x - want.x, end.z - want.z).length() > END_WITHIN or absf(end.y - h) > 0.01:
					bad = "ended %.2f m from where planned, at height %.3f" % [Vector2(end.x - want.x, end.z - want.z).length(), end.y]
				elif int(r["end_state"]) != 0:
					bad = "ended in state %d" % int(r["end_state"])
				elif absf(float(r["end_speed"]) - float(plan["exit_speed"])) > 0.05:
					bad = "exit speed %.2f, the clip's %.2f" % [float(r["end_speed"]), float(plan["exit_speed"])]
				elif float(r["feet"]) > FEET_WITHIN:
					bad = "a foot %.1f cm off the top as he is handed back" % (float(r["feet"]) * 100.0)
			ok(bad == "", "%s, %s: climbs on, ends on top where measured, on the ground, at the clip's exit speed (foot %.1f cm off the top; %s)%s" % [
					s["label"], how[0], float(r["feet"]) * 100.0, String((r["plan"] as Dictionary).get("key", "?")), "" if bad == "" else " -- " + bad])
	for s: Dictionary in [inside[0], inside[inside.size() / 2], inside[inside.size() - 1]]:
		var a := await go_at(s, 1.6, false)
		var b := await go_at(s, 1.6, false, float(a["move_from"]) + 0.3)
		var off := INF if not bool(b["played"]) else (b["end"] as Vector3).distance_to((b["plan"] as Dictionary)["end"])
		ok(off < 0.01, "%s: the stick reversed 0.3 s into the move changes nothing: he ends %.3f m from where the move was going" % [s["label"], off])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
