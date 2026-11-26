extends SceneTree
## Stage 13: the grab and climb onto something deep of 1.45 to 2.10 m. The study's four tests for a traversal move
## (see test_stage8.gd): first on a wall of the clips' own height, then the lowest, the middle and the highest of the
## band, from standing against it, at a walk and at a run; then with a jump, which raises the band by what it raises him.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage13.gd

const FEET_WITHIN := 0.03       # the study: "within about 3 cm"
const END_WITHIN := 0.05
const HAND_WITHIN := 0.03       # the study: "hands rest on the edge within about 3 cm"
const IN_WALL_MOST := 0.02      # ours: no knee or foot joint further than this inside the wall

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
var extra := []                 # wrists and knees


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
	extra.clear()
	for n: String in ["LeftHand", "RightHand", "LeftLeg", "RightLeg"]:
		extra.append((skel.global_transform * skel.get_bone_global_pose(skel.find_bone("mixamorig_" + n))).origin)


## Go at the face of `s` from `back` metres in front of it; `flip` = the stick is reversed from that many seconds on.
func go_at(s: Dictionary, back: float, run: bool, flip := -1.0, jump_at := -1) -> Dictionary:
	lab.call(&"place", Vector3(float(s["x"]), 0.0, -3.0 + back))
	body.rotation.y = 0.0
	for i in 30:
		await physics_frame
	var samples := []
	for i in 300:
		var rev := flip >= 0.0 and i >= int(flip * 60.0)
		samples.append({"mx": 0.0, "mz": 1.0 if rev else -1.0, "yaw": 0.0, "run": run, "jump": jump_at >= 0 and i >= jump_at and i < jump_at + 6, "crouch": false, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var before := int(trav.get(&"plays"))
	var out := {"played": false, "plan": {}, "end": Vector3.ZERO, "end_state": -1, "end_speed": 0.0, "feet": INF, "move_from": -1.0, "high": 0.0, "nearer": INF, "hand": -1.0, "held": 0, "in_wall": 0.0, "sole": 0.0, "sunk": 0.0, "afloat": 0.0}
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
		if inm and final.size() == 4 and extra.size() == 4:
			# while both hands are fully held: how far a wrist is from its place on the top
			var mh: Array = body.get(&"move_hand")
			# (one hand as [which, where, how much], or both as a list of two of those)
			var held_now: Array = [mh] if (mh.size() == 3 and not (mh[0] is Array)) else mh
			var full := held_now.size() > 0 and held_now.all(func(o: Array) -> bool: return float(o[2]) >= 1.0)
			if full:
				out["held"] = int(out["held"]) + 1
				for one: Array in held_now:
					out["hand"] = maxf(float(out["hand"]), (extra[int(one[0])] as Vector3).distance_to(one[1]))
			# from when his feet are down on the top: how far the lower foot is off it (each joint against its own
			# standing height)
			# (the first foot is down at about 1.45 s of the take and the second at about 2.2 s: until then the foot
			# that is down is the higher one)
			var mct := float(body.get(&"move_clip_t"))
			if String(body.get(&"move_clip")) == "climb_up" and mct >= 2.5 and mct < float(trav.get(&"MANTLE")["exit"]) - 0.1 and String((out["plan"] as Dictionary).get("key", "")) == "mantle":
				var off := [minf(final[0].y - float(stand[0]), final[1].y - float(stand[1])) - float(s["top"]), minf(final[2].y - float(stand[2]), final[3].y - float(stand[3])) - float(s["top"])]
				var down: float = maxf(off[0], off[1]) if mct < 2.3 else (off[0] if absf(off[0]) > absf(off[1]) else off[1])
				if absf(down) > absf(float(out["sole"])):
					out["sole"] = down
					out["sole_t"] = mct
			# while he is coming up onto the top: how far the lowest foot joint that is over the top is UNDER it
			if String(body.get(&"move_clip")) == "climb_up" and mct >= 1.5 and mct < 2.5:
				for k in 4:
					if final[k].z < -3.02:
						var under_by: float = float(s["top"]) - (final[k].y - float(stand[k]))
						if under_by > float(out["sunk"]):
							out["sunk"] = under_by
							out["sunk_t"] = mct
			# from when his first foot is down on the top: the lower foot is ON it, not in the air above it
			if String(body.get(&"move_clip")) == "climb_up" and mct >= 1.75:
				var up_by := minf(minf(final[0].y - float(stand[0]), final[1].y - float(stand[1])), minf(final[2].y - float(stand[2]), final[3].y - float(stand[3]))) - float(s["top"])
				# (the lower foot may still be the one hanging below the top: then the other one is the one that is down)
				if up_by < -0.10:
					up_by = maxf(minf(final[0].y - float(stand[0]), final[1].y - float(stand[1])), minf(final[2].y - float(stand[2]), final[3].y - float(stand[3]))) - float(s["top"])
				out["afloat"] = maxf(float(out["afloat"]), up_by)
			# how deep a knee or a foot joint is inside the wall itself (past its face and under its top)
			# (begun from a jump, the first 0.15 s are still the jump's own pose blending out: pressed to a wall, the
			# standing jump's knees are in it by themselves, move or no move; that is not held against this move)
			var blending := bool((out["plan"] as Dictionary).get("air", false)) and t / 60.0 - float(out["move_from"]) < 0.15
			for q: Vector3 in ([] if blending else [final[0], final[1], final[2], final[3], extra[2], extra[3]]):
				var inside := minf(minf(-3.0 - q.z, q.z + 3.0 + float(s["depth"])), float(s["top"]) - q.y)
				if inside > float(out["in_wall"]) + 0.01 and OS.get_cmdline_user_args().has("--feet"):
					print("   in the wall %.2f at %.2f s of %s, body z %.2f y %.2f" % [inside, float(body.get(&"move_clip_t")), body.get(&"move_clip"), body.global_position.z, body.global_position.y])
				out["in_wall"] = maxf(float(out["in_wall"]), inside)
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
		if not inm and int(trav.get(&"plays")) == before and (t > 240 or body.global_position.z < -3.8):
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
	var band: Array = trav.get(&"GRAB_BAND")
	# walls built here beyond the last station (not in the course: a new station changes the stage 1 random walk):
	# the jump's own height (its wrists at 2.14 m: a 2.06 m top), and the lowest and the highest of the band
	var course: Node3D = lab.get(&"course")
	var built := []
	var nx := float(stations[stations.size() - 1]["x"]) + 4.0
	for h: float in [2.06, 1.50, 2.10]:
		course.call(&"_box", Vector3(nx, h * 0.5, -3.0 - 1.25), Vector3(3.0, h, 2.5))
		built.append({"kind": "wall_deep", "label": "deep wall %.2f m (built for this test)" % h, "top": h, "depth": 2.5, "x": nx})
		nx += 4.0
	for i in 5:
		await physics_frame
	var order: Array = built + stations
	var inside: Array[Dictionary] = []
	for how: Array in [["from standing against it", 0.27, false, -1], ["at a walk", 2.6, false, -1], ["at a run", 4.0, true, -1], ["from standing, with a jump", 0.27, false, 20]]:
		var jumped := int(how[3]) >= 0
		var adds := float(body.get(&"JUMP_RISE")) if jumped else 0.0
		for s: Dictionary in order:
			if not (String(s["kind"]) in ["wall_deep", "wall_thin", "wall_roofed"]) or float(s["top"]) > 3.1 or float(s["top"]) < 1.3:
				continue
			var h := float(s["top"])
			var should := String(s["kind"]) == "wall_deep" and h > float(band[0]) + 0.001 and h <= float(band[1]) + adds + 0.001
			var r := await go_at(s, float(how[1]), bool(how[2]), -1.0, int(how[3]))
			var key := String((r["plan"] as Dictionary).get("key", ""))
			if not should:
				ok(key != "grab", "%s, %s: not this move's, the grab and climb is not played (%s)" % [s["label"], how[0],
						("taken by the move '%s'" % key) if key != "" else "he is stopped: " + String(r["refused"])])
				continue
			if how[0] == "at a walk":
				inside.append(s)
			var plan: Dictionary = r["plan"]
			var bad := ""
			if key != "grab":
				bad = "did not play (%s%s)" % [r["refused"], (", the move '%s' did" % key) if key != "" else ""]
			elif jumped and h > float(band[1]) + 0.001 and not bool(plan.get("air", false)):
				bad = "was not begun from the jump"
			else:
				var want: Vector3 = plan["end"]
				var end: Vector3 = r["end"]
				if Vector2(end.x - want.x, end.z - want.z).length() > END_WITHIN or absf(end.y - h) > 0.01:
					bad = "ended %.2f m from where planned, at height %.3f" % [Vector2(end.x - want.x, end.z - want.z).length(), end.y]
				elif int(r["end_state"]) != 0:
					bad = "ended in state %d" % int(r["end_state"])
				elif absf(float(r["end_speed"]) - float(plan["exit_speed"])) > 0.05:
					bad = "exit speed %.2f, the clip's %.2f" % [float(r["end_speed"]), float(plan["exit_speed"])]
				elif int(r["held"]) == 0 or float(r["hand"]) > HAND_WITHIN:
					bad = "a wrist up to %.1f cm from its place on the top while held (%d ticks)" % [float(r["hand"]) * 100.0, int(r["held"])]
				elif float(r["in_wall"]) > IN_WALL_MOST:
					bad = "a knee or a foot %.0f cm inside the wall" % (float(r["in_wall"]) * 100.0)
				elif float(r["feet"]) > FEET_WITHIN:
					bad = "a foot %.1f cm off the top as he is handed back" % (float(r["feet"]) * 100.0)
			ok(bad == "", "%s, %s: grabs the top and climbs up: both hands on it (wrists within %.1f cm for %d ticks), no knee or foot in the wall (%.1f cm), ends on top where measured, at rest (foot %.1f cm off the top)%s" % [
					s["label"], how[0], float(r["hand"]) * 100.0, int(r["held"]), float(r["in_wall"]) * 100.0, float(r["feet"]) * 100.0, "" if bad == "" else " -- " + bad])
	for s: Dictionary in [inside[0], inside[inside.size() / 2], inside[inside.size() - 1]]:
		var a := await go_at(s, 2.6, false)
		var b := await go_at(s, 2.6, false, float(a["move_from"]) + 0.3)
		var off := INF if not bool(b["played"]) else (b["end"] as Vector3).distance_to((b["plan"] as Dictionary)["end"])
		ok(off < 0.01, "%s: the stick reversed 0.3 s into the move changes nothing: he ends %.3f m from where the move was going" % [s["label"], off])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
