extends SceneTree
## Stage 21, cover: "cover: low and high, enter, peek, exit | low 0.8 to 1.1 m, high above head". The study: "look and
## fire around the side of cover, not over the top; stay 30 to 46 cm or an arm's length off the wall; ...; keep
## exposure between positions to 3 to 5 seconds", and of the takes: "in crouch cover the head is at 1.28 m, so behind
## the 0.8 to 1.1 m low cover the head shows by 0.2 m or more. Low cover for these clips needs to be about 1.3 m, or
## the pose lowered." On the course's thin walls.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage21.gd

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var inter: Node
var trav: Node
var skel: Skeleton3D
var fails := 0
var J := {}
var keys := {"mx": 0.0, "mz": 0.0, "act": false}


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print("%s  %s" % ["ok  " if cond else "FAIL", what])


func _after() -> void:
	for n: String in ["Hips", "Head", "HeadTop_End", "LeftUpLeg", "RightUpLeg"]:
		J[n] = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("mixamorig_" + n))).origin


func ticks(n: int) -> void:
	for i in n:
		tape.set(&"tape", [{"mx": keys["mx"], "mz": keys["mz"], "yaw": 0.0, "run": false, "jump": false, "crouch": false, "act": keys["act"]}])
		tape.call(&"replay")
		await physics_frame
		await process_frame


func tap(key: String) -> void:
	keys[key] = true
	await ticks(3)
	keys[key] = false
	await ticks(2)


func until(cond: Callable, most: int) -> int:
	for i in most:
		if bool(cond.call()):
			return i
		await ticks(1)
	return -1


func facing() -> Vector3:
	var d: Vector3 = (J["RightUpLeg"] as Vector3) - (J["LeftUpLeg"] as Vector3)
	return Vector3(d.z, 0.0, -d.x).normalized()


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 5:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	inter = lab.get(&"interact")
	trav = lab.get(&"traverse")
	skel = (lab.get(&"character") as Node).get(&"skel")
	skel.skeleton_updated.connect(_after)
	var stations: Array = (lab.get(&"course") as Node3D).get(&"stations")
	var out := Vector3(0.0, 0.0, 1.0)           # the way the thin walls face him
	for s: Dictionary in stations:
		if String(s["kind"]) != "wall_thin":
			continue
		var h := float(s["top"])
		if not (absf(h - 0.62) < 0.001 or absf(h - 0.80) < 0.001 or absf(h - 1.10) < 0.001 or absf(h - 1.40) < 0.001 or absf(h - 1.80) < 0.001 or absf(h - 2.20) < 0.001):
			continue
		var x := float(s["x"])
		var face_z := float(s["edge_z"])
		while bool(body.call(&"in_move")):
			await ticks(1)
		lab.call(&"place", Vector3(x, 0.0, face_z + 1.7))
		body.rotation.y = 0.0
		await ticks(30)
		var before := int(inter.get(&"plays"))
		var climbs := int(trav.get(&"plays"))
		await tap("act")
		var n := await until(func() -> bool: return String(inter.get(&"in_cover")) != "", 600)
		var what := String(s["label"])
		if h < 0.80 - 0.001:
			await ticks(60)
			ok(n < 0 and int(inter.get(&"plays")) == before, "%s: too low for cover: E does nothing" % what)
			continue
		var kind := "high" if h >= 1.85 else "low"
		ok(n >= 0 and String(inter.get(&"in_cover")) == kind and int(trav.get(&"plays")) == climbs, "%s: E takes him into %s cover against it (%.1f s after the key), and no climb plays" % [what, kind, n / 60.0])
		if n < 0:
			continue
		await ticks(60)
		var hips: Vector3 = J["Hips"]
		var off := hips.z - face_z
		var head := (J["HeadTop_End"] as Vector3).y
		var turned := rad_to_deg(acos(clampf(facing().dot(out), -1.0, 1.0)))
		ok(off >= 0.27 and off <= 0.46 and turned < 35.0, "%s: his back to it, his hips %.2f m out from it (the study: 30 to 46 cm), turned %.0f degrees from square as the take stands" % [what, off, turned])
		if kind == "low":
			if h >= 1.10 - 0.001:
				ok(head <= h, "%s: his head is under its top (the top of his head %.2f m up)" % [what, head])
			else:
				print("      %s: the top of his head is %.2f m up: it shows %.2f m over the top (the study says so of these takes; his hips are down the most they go, 0.25 m)" % [what, head, head - h])
		else:
			ok(head <= h and (J["Hips"] as Vector3).y > 0.8, "%s: standing, his head under its top (%.2f m up)" % [what, head])
		# along it: the stick to his left for a second
		var x0 := body.global_position.x
		keys["mx"] = 1.0
		await ticks(60)
		var went := body.global_position.x - x0
		var head_side := (J["HeadTop_End"] as Vector3).y
		keys["mx"] = 0.0
		await ticks(20)
		ok(went > 0.8 and went < 1.3 and absf(body.global_position.z - (face_z + 0.30)) < 0.03 and String(inter.get(&"in_cover")) == kind, "%s: the stick along it side-steps him %.2f m in a second (the takes' pace: 1.16 m/s), still against it" % [what, went])
		if kind == "low" and h >= 1.40 - 0.001:
			ok(head_side <= h, "%s: side-stepping, his head stays under its top (%.2f m up)" % [what, head_side])
		# on to its end, and held there: he looks round it, then is back
		keys["mx"] = 1.0
		var peek_at := await until(func() -> bool: return String(inter.get(&"cover_phase")) == "peek", 400)
		var end_x := body.global_position.x
		var over_top := 0.0
		var far := -INF
		var back_at := -1
		for t in 600:
			await ticks(1)
			over_top = maxf(over_top, (J["HeadTop_End"] as Vector3).y - maxf(h, 1.80 if kind == "high" else head))
			far = maxf(far, (J["Head"] as Vector3).x)
			if String(inter.get(&"cover_phase")) != "peek":
				back_at = t
				break
		keys["mx"] = 0.0
		await ticks(30)
		ok(peek_at >= 0 and end_x > x + 0.9 and end_x < x + 1.5, "%s: he stops at its end (%.2f m from its middle; it ends at 1.50) and, the stick held on, looks round it" % [what, end_x - x])
		ok(back_at >= 0 and back_at / 60.0 <= 5.0 and over_top < 0.06 and body.global_position.distance_to(Vector3(end_x, 0.0, face_z + 0.30)) < 0.05, "%s: the look round the end takes %.1f s (the study: exposure of 3 to 5 s), round its side and not over its top, and he is back in his place (his head %.2f m past its middle at the furthest)" % [what, back_at / 60.0, far - x])
		# out: with E, or with the stick held out from the wall
		if kind == "low" and absf(h - 1.10) < 0.001:
			keys["mz"] = 1.0
			await ticks(30)
			keys["mz"] = 0.0
		else:
			await tap("act")
		var n2 := await until(func() -> bool: return not bool(body.call(&"in_move")), 400)
		await ticks(30)
		var p := body.global_position
		ok(n2 >= 0 and int(body.get(&"state")) == 0 and absf(p.y) < 0.02 and p.z - face_z > 0.9 and (J["Hips"] as Vector3).y > 0.9 and float(body.get(&"cover_drop")) == 0.0, "%s: %s brings him out: standing %.2f m out from the wall" % [what, "the stick held out from it" if absf(h - 1.10) < 0.001 else "E", p.z - face_z])
	lab.call(&"place", Vector3(60.0, 0.0, 10.0))
	await ticks(20)
	var b2 := int(inter.get(&"plays"))
	await tap("act")
	await ticks(60)
	ok(int(inter.get(&"plays")) == b2, "E with no wall in front of him: nothing happens")
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
