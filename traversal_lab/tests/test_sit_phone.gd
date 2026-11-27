extends SceneTree
## Sitting and the phone (Yasin, 27 Nov: "stand to sit, walk to sit, sitting idle, sit to stand, sit phone tAlk, sit
## messaging, sit to type, walking text, standing text, standing call"). The study has no section on these; of real
## seats and tables it gives "Bench seat | 0.43 to 0.485 m" and "Tables and counters | 0.71 to 0.965 m".
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_sit_phone.gd

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var inter: Node
var skel: Skeleton3D
var fails := 0
var J := {}
var keys := {"mx": 0.0, "mz": 0.0, "run": false, "act": false, "text": false, "call": false}


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print("%s  %s" % ["ok  " if cond else "FAIL", what])


func _after() -> void:
	for n: String in ["HeadTop_End", "Hips", "LeftHand", "RightHand", "Head", "LeftToeBase", "RightToeBase", "LeftLeg", "RightLeg", "LeftUpLeg", "RightUpLeg"]:
		J[n] = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("mixamorig_" + n))).origin


## `n` ticks with the keys as they are now (the tape is fed one tick at a time).
func ticks(n: int) -> void:
	for i in n:
		tape.set(&"tape", [{"mx": keys["mx"], "mz": keys["mz"], "yaw": 0.0, "run": keys["run"], "jump": false, "crouch": false, "act": keys["act"], "text": keys["text"], "call": keys["call"]}])
		tape.call(&"replay")
		await physics_frame
		await process_frame


## One key down for a few ticks, then up.
func tap(key: String) -> void:
	keys[key] = true
	await ticks(3)
	keys[key] = false
	await ticks(2)


## Until `cond` is true, or `most` ticks have gone. Returns how many ticks it took (-1: it never came).
func until(cond: Callable, most: int) -> int:
	for i in most:
		if bool(cond.call()):
			return i
		await ticks(1)
	return -1


## The phone as it is drawn: {shown, at (its middle), face (the way its lit face looks), up (toward its top)}, in the world.
func phone(at_ear: bool) -> Dictionary:
	var chr: Node = lab.get(&"character")
	var box: MeshInstance3D = chr.get(&"_phone_box_l") if at_ear else chr.get(&"_phone_box")
	var xf: Transform3D = skel.global_transform * box.transform
	return {"shown": box.visible, "at": xf.origin, "face": xf.basis.z.normalized(), "up": xf.basis.y.normalized()}


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
	skel = (lab.get(&"character") as Node).get(&"skel")
	skel.skeleton_updated.connect(_after)
	var st := {}
	for s: Dictionary in ((lab.get(&"course") as Node3D).get(&"extras") as Array):
		if String(s["kind"]) == "seats":
			st = s
	ok(not st.is_empty(), "the course has a station with seats")
	if st.is_empty():
		quit(1)
		return
	var seats: Array = st["seats"]
	var seat_h := float(st["seat_high"])
	ok(seat_h >= 0.43 and seat_h <= 0.485, "the seats are %.2f m high (the study's bench seat: 0.43 to 0.485 m)" % seat_h)

	# ---- standing and walking with the phone
	lab.call(&"place", Vector3(60.0, 0.0, 10.0))
	body.rotation.y = 0.0
	await ticks(60)
	var rest_r: Vector3 = (J["RightHand"] as Vector3) - (J["Hips"] as Vector3)
	await tap("text")
	await ticks(150)
	var both := (J["LeftHand"] as Vector3).distance_to(J["RightHand"])
	ok(int(body.get(&"phone")) == 1 and (J["RightHand"] as Vector3).y > 1.0 and (J["LeftHand"] as Vector3).y > 1.0 and both < 0.40, "standing text: T brings both hands up to the phone (wrists %.2f and %.2f m up, %.2f m apart)" % [(J["LeftHand"] as Vector3).y, (J["RightHand"] as Vector3).y, both])
	# the phone itself (Yasin, 27 Nov: "it gets lokst in our hands while texting")
	var ph := phone(false)
	var eyes: Vector3 = (J["Head"] as Vector3) + Vector3(0.0, 0.10, 0.0) + facing() * 0.09
	var to_eyes: Vector3 = (eyes - (ph["at"] as Vector3)).normalized()
	ok(bool(ph["shown"]) and (ph["at"] as Vector3).distance_to(J["RightHand"]) < 0.13 and (ph["face"] as Vector3).dot(to_eyes) > 0.70, "standing text: the phone is in his right hand (its middle %.2f m from the wrist), its lit face turned to his eyes (%.0f degrees off them)" % [(ph["at"] as Vector3).distance_to(J["RightHand"]), rad_to_deg(acos(clampf((ph["face"] as Vector3).dot(to_eyes), -1.0, 1.0)))])
	keys["mz"] = -1.0
	await ticks(150)
	var pace := (body.get(&"hvel") as Vector3).length()
	var hi := -INF
	var lo := INF
	for i in 90:
		await ticks(1)
		hi = maxf(hi, (J["RightHand"] as Vector3).y)
		lo = minf(lo, (J["RightHand"] as Vector3).y)
	ok(pace > 1.0 and pace <= float(body.get(&"PHONE_SPEED")) + 0.05 and lo > 1.0, "walking text: he walks at %.2f m/s with the phone up (right wrist %.2f to %.2f m up through the stride)" % [pace, lo, hi])
	keys["run"] = true
	await ticks(120)
	ok((body.get(&"hvel") as Vector3).length() <= float(body.get(&"PHONE_SPEED")) + 0.05, "walking text, the run key held: no faster (%.2f m/s)" % (body.get(&"hvel") as Vector3).length())
	keys["run"] = false
	keys["mz"] = 0.0
	await ticks(90)
	await tap("call")
	var ear := INF
	for i in 300:                   # (one whole turn of the call take)
		await ticks(1)
		ear = minf(ear, (J["LeftHand"] as Vector3).distance_to(J["Head"]))
	# the phone at his ear (Yasin, 27 Nov: "never truly touches our face on a right angle during calls")
	var pc := phone(true)
	var head_side := (J["HeadTop_End"] as Vector3) - (J["Head"] as Vector3)        # (up the head: its own lean is in this)
	var top_at: Vector3 = (pc["at"] as Vector3) + (pc["up"] as Vector3) * 0.044
	var ear_at: Vector3 = (J["Head"] as Vector3) + head_side.normalized() * 0.105
	var off_head := Vector2(top_at.x - ear_at.x, top_at.z - ear_at.z).length()
	var tilt := absf((pc["face"] as Vector3).dot(head_side.normalized()))
	var foot: Vector3 = (pc["at"] as Vector3) - (pc["up"] as Vector3) * 0.074
	ok(bool(pc["shown"]) and off_head > 0.06 and off_head < 0.11 and tilt < 0.12 and absf(top_at.y - ear_at.y) < 0.04, "standing call: the phone lies flat on the side of his head at his ear (its ear end %.3f m out from the middle of his head, at ear height within %.3f m, its face %.0f degrees from upright along the head)" % [off_head, absf(top_at.y - ear_at.y), rad_to_deg(asin(clampf(tilt, 0.0, 1.0)))])
	ok(foot.distance_to(J["LeftHand"]) < 0.09, "standing call: his left hand is on it (wrist %.3f m from its foot)" % foot.distance_to(J["LeftHand"]))
	ok(int(body.get(&"phone")) == 2 and ear < 0.32, "standing call: G brings the phone to his ear (left wrist %.2f m from his head joint)" % ear)
	await tap("call")
	await ticks(60)
	ok(int(body.get(&"phone")) == 0 and ((J["RightHand"] as Vector3) - (J["Hips"] as Vector3)).distance_to(rest_r) < 0.10, "G again: the phone is put away, his arm as it was")

	# ---- the bench
	var bench: Node3D = seats[0]
	var out := bench.global_transform.basis.z
	var stand: Vector3 = inter.call(&"_seat_stand", bench)
	for case: String in ["walk to sit", "stand to sit"]:
		if bool(inter.get(&"seated")):
			await tap("act")
			await until(func() -> bool: return not bool(body.call(&"in_move")), 600)
		var from := stand + (Vector3(-0.7, 0.0, 1.3) if case == "walk to sit" else Vector3.ZERO)
		lab.call(&"place", from)
		body.rotation.y = PI if case == "stand to sit" else 0.0       # (PI: his back to the bench already)
		await ticks(30)
		await tap("act")
		var went := 0.0
		var took := 0
		while String(inter.get(&"sit_phase")) != "down" and took < 500:
			await ticks(1)
			took += 1
			went = maxf(went, body.global_position.distance_to(from))
		var arrived := body.global_position.distance_to(stand)
		var n := await until(func() -> bool: return String(inter.get(&"sit_phase")) == "idle", 400)
		await ticks(40)
		var hips: Vector3 = J["Hips"]
		var flat := Vector2(hips.x - bench.global_position.x, hips.z - bench.global_position.z).length()
		var toes := maxf((J["LeftToeBase"] as Vector3).y, (J["RightToeBase"] as Vector3).y)
		if case == "walk to sit":
			ok(went > 1.0 and arrived < 0.15, "%s: E from 1.6 m away walks him to the bench (to within %.2f m of its standing place)" % [case, arrived])
		else:
			ok(went < 0.15, "%s: E at the bench, his back to it: he sits down where he stands (moved %.2f m first)" % [case, went])
		ok(n >= 0 and hips.y > seat_h + 0.05 and hips.y < seat_h + 0.15 and flat < 0.06 and toes < 0.05 and facing().dot(out) > 0.95,
				"%s, sitting idle: his hip joints are %.2f m up on the %.2f m seat, %.2f m from its middle, his feet on the ground (toes %.2f m up), facing out from it (%.2f)" % [case, hips.y, seat_h, flat, toes, facing().dot(out)])
	# on the bench with the phone
	var sat_r: Vector3 = J["RightHand"]
	await tap("text")
	await ticks(150)
	ok(String(inter.get(&"sit_phase")) == "idle" and (J["RightHand"] as Vector3).y > sat_r.y + 0.05 and (J["RightHand"] as Vector3).y > (J["Hips"] as Vector3).y + 0.08 and (J["LeftHand"] as Vector3).distance_to(J["RightHand"]) < 0.40, "sit messaging: seated, T brings both hands to the phone (right wrist %.2f m higher than at rest, wrists %.2f m apart)" % [(J["RightHand"] as Vector3).y - sat_r.y, (J["LeftHand"] as Vector3).distance_to(J["RightHand"])])
	await tap("call")
	var ear2 := INF
	for i in 300:
		await ticks(1)
		ear2 = minf(ear2, (J["LeftHand"] as Vector3).distance_to(J["Head"]))
	ok(String(inter.get(&"sit_phase")) == "idle" and ear2 < 0.32, "sit phone talk: seated, G brings the phone to his ear (left wrist %.2f m from his head joint)" % ear2)
	await tap("call")
	await ticks(40)
	# up again: with E, and (after sitting down again) by holding the stick
	for how: String in ["E", "the stick held"]:
		if how == "E":
			await tap("act")
		else:
			await tap("act")
			await until(func() -> bool: return String(inter.get(&"sit_phase")) == "idle", 600)
			await ticks(30)
			keys["mz"] = -1.0
			await ticks(30)
			keys["mz"] = 0.0
		var n2 := await until(func() -> bool: return not bool(body.call(&"in_move")), 400)
		await ticks(20)
		ok(n2 >= 0 and body.global_position.distance_to(stand) < 0.10 and absf(body.global_position.y) < 0.02 and int(body.get(&"state")) == 0 and (J["Hips"] as Vector3).y > 0.9,
				"sit to stand, with %s: he is standing in front of the bench again (%.2f m from its standing place, hips %.2f m up)" % [how, body.global_position.distance_to(stand), (J["Hips"] as Vector3).y])

	# ---- the desk
	var stool: Node3D = seats[2]
	var d_stand: Vector3 = inter.call(&"_seat_stand", stool)
	var d_face := stool.global_transform.basis.z
	lab.call(&"place", d_stand + Vector3(0.2, 0.0, 1.0))
	body.rotation.y = 0.0
	await ticks(30)
	await tap("act")
	var n3 := await until(func() -> bool: return String(inter.get(&"sit_phase")) == "type", 900)
	await ticks(60)
	var knees := maxf((J["LeftLeg"] as Vector3).y, (J["RightLeg"] as Vector3).y)
	var wl: Vector3 = J["LeftHand"]
	var wr: Vector3 = J["RightHand"]
	var reach := ((wl + wr) * 0.5 - stool.global_position).dot(d_face)
	ok(n3 >= 0 and facing().dot(d_face) > 0.95 and knees < 0.68, "sit to type: E by the desk: he sits on the stool from its side, turns to the desk (knees %.2f m up, under its 0.68 m underside)" % knees)
	ok(wl.y > 0.70 and wl.y < 0.85 and wr.y > 0.70 and wr.y < 0.85 and reach > 0.30 and reach < 0.55, "sit to type: his hands are at the keys (wrists %.2f and %.2f m up over a 0.72 m top, %.2f m in front of his seat)" % [wl.y, wr.y, reach])
	await tap("text")
	var n4 := await until(func() -> bool: return String(inter.get(&"sit_phase")) == "idle", 200)
	await ticks(30)
	ok(n4 >= 0 and (J["RightHand"] as Vector3).y < 0.70, "at the desk, T: his hands come off the keys (right wrist %.2f m up)" % (J["RightHand"] as Vector3).y)
	await tap("text")
	var n5 := await until(func() -> bool: return String(inter.get(&"sit_phase")) == "type", 200)
	ok(n5 >= 0, "T again: back to the keys")
	await ticks(30)
	await tap("act")
	var n6 := await until(func() -> bool: return not bool(body.call(&"in_move")), 600)
	await ticks(20)
	ok(n6 >= 0 and body.global_position.distance_to(d_stand) < 0.10 and (J["Hips"] as Vector3).y > 0.9 and int(body.get(&"state")) == 0, "E: hands off the keys, he turns from the desk and stands up beside the stool (%.2f m from its standing place)" % body.global_position.distance_to(d_stand))
	# E far from any seat does nothing
	lab.call(&"place", Vector3(60.0, 0.0, 10.0))
	await ticks(20)
	var before := int(inter.get(&"plays"))
	await tap("act")
	await ticks(60)
	ok(int(inter.get(&"plays")) == before and body.global_position.distance_to(Vector3(60.0, 0.0, 10.0)) < 0.05, "E with no seat within 2.5 m: nothing happens")
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
