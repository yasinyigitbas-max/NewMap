extends SceneTree
## Stage 15: turn, hang and drop, from an edge with a drop of 1.0 to 3.0 m, gone at crouched (upright he walks or runs
## off it as before). The study's four tests for a
## traversal move (see test_stage8.gd), from the top of every deep wall of the course.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage15.gd

const FEET_WITHIN := 0.03       # the study: "within about 3 cm"
const HAND_WITHIN := 0.03       # the study: "hands rest on the edge within about 3 cm"
const END_WITHIN := 0.05
const IN_WALL_MOST := 0.02      # ours: no knee or foot joint further than this inside the wall

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var trav: Node
var skel: Skeleton3D
var stations: Array
var fails := 0
var names := ["LeftFoot", "LeftToeBase", "RightFoot", "RightToeBase", "LeftHand", "RightHand", "LeftLeg", "RightLeg"]
var bones := []
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
	for i: int in bones:
		final.append((skel.global_transform * skel.get_bone_global_pose(i)).origin)


## Go off the edge of `s` from on top of it; `flip` = the stick is reversed from that many seconds on.
func go_off(s: Dictionary, run: bool, flip := -1.0, low := true) -> Dictionary:
	var h := float(s["top"])
	lab.call(&"place", Vector3(float(s["x"]), h, -5.3 if run else -4.6))
	body.rotation.y = PI
	for i in 30:
		await physics_frame
	var samples := []
	for i in 420:
		var back := flip >= 0.0 and i >= int(flip * 60.0)
		samples.append({"mx": 0.0, "mz": -1.0 if back else 1.0, "yaw": 0.0, "run": run, "jump": false, "crouch": low and not run, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var before := int(trav.get(&"plays"))
	var out := {"played": false, "plan": {}, "end": Vector3.ZERO, "end_state": -1, "end_speed": 0.0, "feet": INF, "hand": -1.0, "held": 0, "in_wall": 0.0, "move_from": -1.0}
	var was_in := false
	var t := 0
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		await process_frame
		t += 1
		var inm := bool(body.call(&"in_move"))
		if inm and not was_in:
			out["played"] = true
			out["plan"] = (trav.get(&"_plan") as Dictionary).duplicate()
			out["move_from"] = t / 60.0
		if inm and final.size() == 8:
			var mh: Array = body.get(&"move_hand")
			if mh.size() == 2 and mh[0] is Array and float(mh[0][2]) >= 1.0 and float(mh[1][2]) >= 1.0:
				out["held"] = int(out["held"]) + 1
				for one: Array in mh:
					out["hand"] = maxf(float(out["hand"]), (final[4 + int(one[0])] as Vector3).distance_to(one[1]))
			# how deep a knee or a foot joint is inside the wall he comes down from (behind its face and under its top)
			for k: int in [0, 1, 2, 3, 6, 7]:
				var q: Vector3 = final[k]
				var inside := minf(-3.0 - q.z, h - q.y)
				if inside > float(out["in_wall"]) + 0.01 and OS.get_cmdline_user_args().has("--feet"):
					print("   in the wall %.2f at %.2f s (%s), joint %s at z %.2f y %.2f" % [inside, float(body.get(&"move_clip_t")), body.get(&"move_clip"), names[k], q.z + 3.0, q.y])
				out["in_wall"] = maxf(float(out["in_wall"]), inside)
		if was_in and not inm:
			out["end"] = body.global_position
			out["end_state"] = int(body.get(&"state"))
			out["end_speed"] = (body.get(&"hvel") as Vector3).length()
			if final.size() == 8:
				var gy := body.global_position.y
				var worst := 0.0
				for f in 2:
					worst = maxf(worst, minf(absf(final[f * 2].y - gy - stand[f * 2]), absf(final[f * 2 + 1].y - gy - stand[f * 2 + 1])))
				out["feet"] = worst
			tape.call(&"stop")
		was_in = inm
		if not inm and int(trav.get(&"plays")) == before and (body.global_position.z > -1.0 or t > 300):
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
	for n: String in names:
		bones.append(skel.find_bone("mixamorig_" + n))
	skel.skeleton_updated.connect(_after)
	lab.call(&"place", Vector3(60.0, 0.0, 10.0))
	for i in 60:
		await physics_frame
		await process_frame
	for p: Vector3 in final:
		stand.append(p.y - body.global_position.y)
	var band: Array = trav.get(&"DOWN_BAND")
	var inside: Array[Dictionary] = []
	for way: Array in [[false, true], [false, false], [true, false]]:
		var run: bool = way[0]
		var low: bool = way[1]
		var how := "crouched" if low else ("at a run" if run else "at a walk, upright")
		for s: Dictionary in stations:
			if String(s["kind"]) != "wall_deep":
				continue
			var h := float(s["top"])
			var should := low and h > float(band[0]) + 0.001 and h <= float(band[1]) + 0.001
			var r := await go_off(s, run, -1.0, low)
			var plan: Dictionary = r["plan"]
			var key := String(plan.get("key", ""))
			if not should:
				ok(key != "climb_down", "%s, %s: not this move's, the turn, hang and drop is not played (%s)" % [s["label"], how,
						("taken by the move '%s'" % key) if key != "" else "no move: " + String(r["refused"])])
				continue
			inside.append(s)
			var bad := ""
			if key != "climb_down":
				bad = "did not play (%s%s)" % [r["refused"], (", the move '%s' did" % key) if key != "" else ""]
			else:
				var want: Vector3 = plan["end"]
				var end: Vector3 = r["end"]
				if Vector2(end.x - want.x, end.z - want.z).length() > END_WITHIN or absf(end.y) > 0.01:
					bad = "ended %.2f m from where planned, at height %.3f" % [Vector2(end.x - want.x, end.z - want.z).length(), end.y]
				elif int(r["end_state"]) != 0:
					bad = "ended in state %d" % int(r["end_state"])
				elif float(r["end_speed"]) > 0.05:
					bad = "not at rest as he is handed back (%.2f m/s)" % float(r["end_speed"])
				elif int(r["held"]) == 0 or float(r["hand"]) > HAND_WITHIN:
					bad = "a wrist up to %.1f cm from its place on the ledge while held (%d ticks)" % [float(r["hand"]) * 100.0, int(r["held"])]
				elif float(r["in_wall"]) > IN_WALL_MOST:
					bad = "a knee or a foot %.0f cm inside the wall" % (float(r["in_wall"]) * 100.0)
				elif float(r["feet"]) > FEET_WITHIN:
					bad = "a foot %.1f cm off the ground as he is handed back" % (float(r["feet"]) * 100.0)
			ok(bad == "", "%s, crouched: turns, hangs and drops: both hands on the ledge (wrists within %.1f cm for %d ticks), no knee or foot in the wall (%.1f cm), ends on the ground under it where measured, at rest (foot %.1f cm off the ground)%s" % [
					s["label"], float(r["hand"]) * 100.0, int(r["held"]), float(r["in_wall"]) * 100.0, float(r["feet"]) * 100.0, "" if bad == "" else " -- " + bad])
	for s: Dictionary in [inside[0], inside[inside.size() / 2], inside[inside.size() - 1]]:
		var a := await go_off(s, false)
		var b := await go_off(s, false, float(a["move_from"]) + 0.3)
		var off := INF if not bool(b["played"]) else (b["end"] as Vector3).distance_to((b["plan"] as Dictionary)["end"])
		ok(off < 0.01, "%s: the stick reversed 0.3 s into the move changes nothing: he ends %.3f m from where it was going" % [s["label"], off])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
