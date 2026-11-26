extends SceneTree
## Stage 8: stepping off an edge at a walk. The study's four tests for every traversal move:
## "- it plays on every course obstacle inside its height band and is refused on every obstacle outside it;
##  - hands rest on the edge within about 3 cm and feet land on the ground, checked on the lowest, middle and highest
##    obstacle of the band;
##  - the body ends where the detection record said it would, standing on ground, in the right ground state, moving
##    at the clip's exit speed;
##  - cancelling is impossible mid-move and every earlier stage's tests still pass."
## (This move has no hands on anything.) Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage8.gd

const FEET_WITHIN := 0.03       # the study: "within about 3 cm" (its figure for hands; used for the feet as well)
const END_WITHIN := 0.05        # the stage 7 bar: where the record said, within 5 cm

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var trav: Node
var skel: Skeleton3D
var stations: Array
var fails := 0
var feet_i := []
var stand := []                 # each foot joint's height above the ground when he stands
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


## Walk off the edge of `s` from on top of it; `flip` = the stick is reversed from that many seconds on.
func walk_off(s: Dictionary, flip := -1.0) -> Dictionary:
	var h := float(s["top"])
	lab.call(&"place", Vector3(float(s["x"]), h, -4.6))
	body.rotation.y = PI
	for i in 30:
		await physics_frame
	var samples := []
	for i in 300:
		var back := flip >= 0.0 and i >= int(flip * 60.0)
		samples.append({"mx": 0.0, "mz": -1.0 if back else 1.0, "yaw": 0.0, "run": false, "jump": false, "crouch": false, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var before := int(trav.get(&"plays"))
	var out := {"played": false, "plan": {}, "end": Vector3.ZERO, "end_state": -1, "end_speed": 0.0, "feet": INF, "under": 0.0, "air_ticks": 0, "move_from": -1.0}
	var was_in := false
	var landed_for := -1
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
		if inm and int(body.get(&"state")) >= 2:
			out["air_ticks"] = int(out["air_ticks"]) + 1
		if inm and bool(body.get(&"move_landed")):
			landed_for += 1
			# the feet 0.1 s after he comes down: how far the nearer foot's joints are off the ground, and how far
			# under it any joint is
			if landed_for == 6 and final.size() == 4:
				var gy := body.global_position.y
				var off := INF
				for f in 2:
					off = minf(off, maxf(absf(final[f * 2].y - gy - stand[f * 2]), absf(final[f * 2 + 1].y - gy - stand[f * 2 + 1])))
				out["feet"] = off
				for k in 4:
					out["under"] = maxf(float(out["under"]), gy + stand[k] - final[k].y - 0.0)
		if was_in and not inm:
			out["end"] = body.global_position
			out["end_state"] = int(body.get(&"state"))
			out["end_speed"] = (body.get(&"hvel") as Vector3).length()
			tape.call(&"stop")
		was_in = inm
		if not inm and int(trav.get(&"plays")) == before and body.global_position.z > -2.0:
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
	var band: Array = trav.get(&"BAND")
	var inside: Array[Dictionary] = []
	for s: Dictionary in stations:
		if not (String(s["kind"]) in ["kerb", "step", "wall_deep"]) or float(s["top"]) > 2.0:
			continue
		var h := float(s["top"])
		var should := h > float(band[0]) + 0.001 and h <= float(band[1]) + 0.001
		var r := await walk_off(s)
		if not should:
			ok(not bool(r["played"]), "%s: outside the band, refused (%s)" % [s["label"], r["refused"]])
			continue
		inside.append(s)
		var plan: Dictionary = r["plan"]
		var bad := ""
		if not bool(r["played"]):
			bad = "did not play (%s)" % r["refused"]
		else:
			var want: Vector3 = plan["end"]
			var end: Vector3 = r["end"]
			if Vector2(end.x - want.x, end.z - want.z).length() > END_WITHIN or absf(end.y) > 0.01:
				bad = "ended %.2f m from where planned, at height %.3f" % [Vector2(end.x - want.x, end.z - want.z).length(), end.y]
			elif int(r["end_state"]) != 0:
				bad = "ended in state %d" % int(r["end_state"])
			elif absf(float(r["end_speed"]) - float(plan["exit_speed"])) > 0.05:
				bad = "exit speed %.2f, the clip's %.2f" % [float(r["end_speed"]), float(plan["exit_speed"])]
			elif float(r["feet"]) > FEET_WITHIN:
				bad = "feet %.1f cm off the ground 0.1 s after landing" % (float(r["feet"]) * 100.0)
		ok(bad == "", "%s: steps off, lands where measured, on the ground, at the clip's exit speed (feet %.1f cm off, %.1f cm under; %.2f s in the air)%s" % [
				s["label"], float(r["feet"]) * 100.0, float(r["under"]) * 100.0, int(r["air_ticks"]) / 60.0, "" if bad == "" else " -- " + bad])
	# cancelling: the stick is reversed a tenth of a second into the move on the lowest, middle and highest of the band
	for s: Dictionary in [inside[0], inside[inside.size() / 2], inside[inside.size() - 1]]:
		var a := await walk_off(s)
		var b := await walk_off(s, float(a["move_from"]) + 0.1)
		# (held to where its own plan ends, made before the stick was reversed, and set beside the run left alone)
		var off := INF if not bool(b["played"]) else (b["end"] as Vector3).distance_to((b["plan"] as Dictionary)["end"])
		ok(off < 0.01, "%s: the stick reversed 0.1 s into the move changes nothing: he ends %.3f m from where the move was going (and %.3f m from where the run left alone ended)" % [s["label"], off, (b["end"] as Vector3).distance_to(a["end"])])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
