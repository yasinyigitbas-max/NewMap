extends SceneTree
## Stage 10: the vault over a thin obstacle from a run, 0.50 to 1.10 m. The study's four tests for a traversal move:
## plays inside its band and is refused outside it; "hands rest on the edge within about 3 cm and feet land on the
## ground"; ends where the detection record said, on the ground, in the right state, at the clip's exit speed;
## cannot be cancelled. Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage10.gd

const HAND_WITHIN := 0.03       # the study: "hands rest on the edge within about 3 cm"
const HAND_ROCK := 1.0          # NOT in the study: a held hand does not turn more than this in a tick (degrees)
const TOE := 0.08                # the toes beyond the toe joint (m), allowed for each side of the obstacle
const FEET_WITHIN := 0.03
const END_WITHIN := 0.05

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var trav: Node
var skel: Skeleton3D
var stations: Array
var fails := 0
var bones := []
var stand := []
var final := []
var hand_turn := []


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
	hand_turn = [(skel.global_transform.basis * skel.get_bone_global_pose(bones[4]).basis).orthonormalized(), (skel.global_transform.basis * skel.get_bone_global_pose(bones[5]).basis).orthonormalized()]


func go_at(s: Dictionary, run: bool, flip := -1.0, near := false) -> Dictionary:
	lab.call(&"place", Vector3(float(s["x"]), 0.0, 2.6 if run else (-2.72 if near else -1.2)))
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
	var out := {"played": false, "plan": {}, "end": Vector3.ZERO, "end_state": -1, "end_speed": 0.0, "feet": INF, "hand": -1.0, "held": 0, "move_from": -1.0, "low": INF, "rock": 0.0}
	var was_in := false
	var t := 0
	var after := -1
	var last_turn := Basis()
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		await process_frame
		t += 1
		var inm := bool(body.call(&"in_move"))
		if inm and not was_in:
			out["played"] = true
			out["plan"] = (trav.get(&"_plan") as Dictionary).duplicate()
			out["move_from"] = t / 60.0
		if inm and final.size() == 6:
			var mh: Array = body.get(&"move_hand")
			# while the hand is fully held: how far the wrist is from where it is to be
			if mh.size() == 3 and float(mh[2]) >= 1.0:
				out["hand"] = maxf(float(out["hand"]), (final[4 + int(mh[0])] as Vector3).distance_to(mh[1]))
				out["held"] = int(out["held"]) + 1
				# ... and how far the hand itself has turned since the tick before
				var now: Basis = hand_turn[int(mh[0])]
				if last_turn != Basis():
					out["rock"] = maxf(float(out["rock"]), rad_to_deg(Quaternion(last_turn).angle_to(Quaternion(now))))
				last_turn = now
			else:
				last_turn = Basis()
			# the lowest any foot joint goes over the obstacle's top while he is over it
			var plan: Dictionary = out["plan"]
			# (a foot joint counts while it is itself over the obstacle: within its thickness, and the length of
			# the toes beyond the toe joint more each way)
			# ... and while he is off the ground: standing against it his toes are at its foot, which is no fault
			if plan.has("mid") and int(body.get(&"state")) >= 2:
				for k in 4:
					if absf(((final[k] as Vector3) - (plan["mid"] as Vector3)).dot(plan["m"])) < float(s["depth"]) * 0.5 + TOE:
						out["low"] = minf(float(out["low"]), final[k].y - float(plan["top"]))
						if OS.get_cmdline_user_args().has("--feet") and final[k].y < float(plan["top"]):
							print("   under: joint %d at clip %.2f, %.2f m along from the middle, y %.2f (top %.2f), body %.2f along" % [k, float(body.get(&"move_clip_t")), ((final[k] as Vector3) - (plan["mid"] as Vector3)).dot(plan["m"]), final[k].y, float(plan["top"]), (body.global_position - (plan["mid"] as Vector3)).dot(plan["m"])])
		if was_in and not inm:
			out["end"] = body.global_position
			out["end_state"] = int(body.get(&"state"))
			out["end_speed"] = (body.get(&"hvel") as Vector3).length()
			after = 0
		if after >= 0 and not inm:
			# a foot on the ground within one running step of being handed back (ball or heel, whichever is nearer)
			if final.size() == 6:
				var gy := body.global_position.y
				for f in 2:
					out["feet"] = minf(float(out["feet"]), minf(absf(final[f * 2].y - gy - stand[f * 2]), absf(final[f * 2 + 1].y - gy - stand[f * 2 + 1])))
			after += 1
			if after > 20:
				tape.call(&"stop")
		was_in = inm
		if not inm and after < 0 and int(trav.get(&"plays")) == before and t > 240:
			tape.call(&"stop")
	out["refused"] = String(trav.get(&"refused"))
	out["rest_z"] = body.global_position.z
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
	for n: String in ["LeftFoot", "LeftToeBase", "RightFoot", "RightToeBase", "LeftHand", "RightHand"]:
		bones.append(skel.find_bone("mixamorig_" + n))
	skel.skeleton_updated.connect(_after)
	lab.call(&"place", Vector3(60.0, 0.0, 10.0))
	for i in 60:
		await physics_frame
		await process_frame
	for p: Vector3 in final:
		stand.append(p.y - body.global_position.y)
	var band: Array = trav.get(&"VAULT_BAND")
	var inside: Array[Dictionary] = []
	# (stage 11: at a walk and from standing against it the same vault is used, slowed, until there is a step vault)
	# (at a walk and from standing against it: the standing vault, legs tucked, no hand on the top)
	for way: Array in [[true, 0, false], [true, 1, false], [false, 0, false], [false, 0, true]]:
		var run: bool = way[0]
		trav.set(&"force_mirror", int(way[1]))
		var which := (", the mirror image" if int(way[1]) == 1 else ", as the clip has it") if run else (", from standing against it" if bool(way[2]) else "")
		for s: Dictionary in stations:
			if not (String(s["kind"]) in ["wall_deep", "wall_thin"]) or float(s["top"]) > 2.0:
				continue
			var h := float(s["top"])
			var should := String(s["kind"]) == "wall_thin" and h >= float(band[0]) - 0.001 and h <= float(band[1]) + 0.001
			# at a walk or from standing: the standing vault up to its own most, the slowed one-hand vault above it
			# at a walk, and from standing against one higher than that there is no move (held to: not played)
			var tuck_most := float(trav.get(&"TUCK_MOST")) + 0.001
			var want_key := "vault" if (run or h > tuck_most) else "vault_tuck"
			if bool(way[2]) and h > tuck_most:
				should = false
			var r := await go_at(s, run, -1.0, bool(way[2]))
			var key := String((r["plan"] as Dictionary).get("key", ""))
			if not should:
				ok(not (key in ["vault", "vault_tuck"]), "%s, %s: the vault is not played (%s)" % [s["label"], "at a run" if run else ("from standing against it" if bool(way[2]) else "at a walk"), ("the move '%s'" % key) if key != "" else "stopped: " + String(r["refused"])])
				continue
			if run and int(way[1]) == 0:
				inside.append(s)
			var plan: Dictionary = r["plan"]
			var bad := ""
			if key != want_key:
				bad = "did not play (%s%s)" % [r["refused"], (", the move '%s' did" % key) if key != "" else ""]
			else:
				var want: Vector3 = plan["end"]
				var end: Vector3 = r["end"]
				if Vector2(end.x - want.x, end.z - want.z).length() > END_WITHIN or absf(end.y) > 0.01:
					bad = "ended %.2f m from where planned, at height %.3f" % [Vector2(end.x - want.x, end.z - want.z).length(), end.y]
				elif int(r["end_state"]) != 0:
					bad = "ended in state %d" % int(r["end_state"])
				elif absf(float(r["end_speed"]) - float(plan["exit_speed"])) > 0.05:
					bad = "exit speed %.2f, the clip's %.2f" % [float(r["end_speed"]), float(plan["exit_speed"])]
				elif int(plan["hand"]) < 0:
					# the standing vault: no hand is put down; the feet and the landing are what is checked
					if float(r["feet"]) > FEET_WITHIN:
						bad = "no foot nearer than %.1f cm to the ground in the step after" % (float(r["feet"]) * 100.0)
					elif float(r["low"]) < 0.0:
						bad = "a foot %.1f cm under the top as he goes over" % (-float(r["low"]) * 100.0)
				elif float(r["rock"]) > HAND_ROCK:
					bad = "the held hand turns %.1f degrees in a tick" % float(r["rock"])
				elif int(plan["hand"]) != int(way[1]):
					bad = "the wrong hand"
				elif int(r["held"]) == 0 or float(r["hand"]) > HAND_WITHIN:
					bad = "the wrist up to %.1f cm from its place on the top while held (%d ticks)" % [float(r["hand"]) * 100.0, int(r["held"])]
				elif float(r["feet"]) > FEET_WITHIN:
					bad = "no foot nearer than %.1f cm to the ground in the step after" % (float(r["feet"]) * 100.0)
				elif float(r["low"]) < 0.0:
					bad = "a foot %.1f cm under the top as he goes over" % (-float(r["low"]) * 100.0)
			ok(bad == "", ("%s, %s" % [s["label"], "at a run" if run else "at a walk"]) + which + (": vaults it, hand on the top (wrist within %.1f cm for %d ticks, the hand turning at most %.1f deg a tick), feet" % [float(r["hand"]) * 100.0, int(r["held"]), float(r["rock"])]) + " %.0f cm clear of the top, lands and ends where measured at the clip's exit speed (foot %.1f cm off the ground)%s" % [
					float(r["low"]) * 100.0, float(r["feet"]) * 100.0, "" if bad == "" else " -- " + bad])
	for s: Dictionary in [inside[0], inside[inside.size() / 2], inside[inside.size() - 1]]:
		trav.set(&"force_mirror", -1)
		var a := await go_at(s, true)
		var b := await go_at(s, true, float(a["move_from"]) + 0.2)
		var off := INF if not bool(b["played"]) else (b["end"] as Vector3).distance_to((b["plan"] as Dictionary)["end"])
		ok(off < 0.01, "%s: the stick reversed 0.2 s into the vault changes nothing: he ends %.3f m from where it was going" % [s["label"], off])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
