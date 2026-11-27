extends SceneTree
## Stage 23, cars: entry and exit. The study: "`Entering Car` (5.47 s) walks 1.9 m, turns 97 degrees and sits with the
## hips at 0.88 m and the feet on a floor 0.29 m up ... `Exiting Car` (5.8 s) is the reverse. There is no bonnet
## slide." (those heights are X Bot's; on his body the lab measures hips 0.84 m, the floor 0.28 m).
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage23.gd

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var inter: Node
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
	for n: String in ["Hips", "LeftHand", "RightHand", "Head", "LeftFoot", "RightFoot", "LeftUpLeg", "RightUpLeg", "LeftShoulder", "RightShoulder"]:
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
		if String(s["kind"]) == "car":
			st = s
	ok(not st.is_empty(), "the course has a car")
	if st.is_empty():
		quit(1)
		return
	var car: Node3D = st["car"]
	var seat := car.global_position
	var ahead := -car.global_transform.basis.z
	var left := -car.global_transform.basis.x
	var start: Vector3 = (inter.call(&"_car_start", car) as Array)[0]
	print("      (the getting-in take starts %.2f m to the left of the driver's hips and %.2f m ahead of them)" % [(start - seat).dot(left), (start - seat).dot(ahead)])
	for from: Vector3 in [start + left * 0.9 + ahead * 0.6, start - ahead * 1.2]:
		lab.call(&"place", from)
		body.rotation.y = 0.0
		await ticks(30)
		await tap("act")
		var began := -1
		var seated_at := -1
		var door_most := 0.0
		var walked := 0.0
		for t in 900:
			await ticks(1)
			if began < 0:
				walked = maxf(walked, body.global_position.distance_to(from))
				if bool(body.call(&"in_move")):
					began = t
			door_most = maxf(door_most, float(car.get(&"door_deg")))
			if bool(inter.get(&"in_car")):
				seated_at = t
				break
		await ticks(40)
		var how := "E %.1f m from where the take starts" % from.distance_to(start)
		var hips: Vector3 = J["Hips"]
		var flat := Vector2(hips.x - seat.x, hips.z - seat.z).length()
		ok(began >= 0 and seated_at >= 0, "%s: he is walked there (%.2f m) and gets in, %.1f s from the take's start (the study: 5.47 s, after his turn to it)" % [how, walked, (seated_at - began) / 60.0])
		if seated_at < 0:
			continue
		ok(flat < 0.06 and hips.y > 0.78 and hips.y < 0.90 and facing().dot(ahead) > 0.95, "%s: he sits on the seat, facing the way the car points (hip joints %.2f m up over a seat %.2f m up, %.2f m from its middle)" % [how, hips.y, float(car.get(&"SEAT")), flat])
		var floor_y := float(car.get(&"FLOOR"))
		var feet := [(J["LeftFoot"] as Vector3).y - floor_y, (J["RightFoot"] as Vector3).y - floor_y]
		ok(float(feet[0]) > 0.06 and float(feet[0]) < 0.16 and float(feet[1]) > 0.06 and float(feet[1]) < 0.16, "%s: his feet are on the car's floor (ankle joints %.2f and %.2f m over it; 0.11 m standing)" % [how, float(feet[0]), float(feet[1])])
		var wheel := ((J["LeftHand"] as Vector3) + (J["RightHand"] as Vector3)) * 0.5
		ok((wheel - seat).dot(ahead) > 0.2 and (wheel - seat).dot(ahead) < 0.5 and wheel.y > 1.0 and wheel.y < 1.25, "%s: his hands are at the wheel (%.2f m ahead of his hips, %.2f m up)" % [how, (wheel - seat).dot(ahead), wheel.y])
		ok(door_most >= 40.0 and float(car.get(&"door_deg")) == 0.0, "%s: the door was opened (%.0f degrees) and is shut behind him" % [how, door_most])
		# sits there until asked
		await ticks(120)
		ok(bool(inter.get(&"in_car")) and bool(body.call(&"in_move")), "%s: he stays in the car until E" % how)
		await tap("act")
		var out_at := -1
		door_most = 0.0
		for t in 600:
			await ticks(1)
			door_most = maxf(door_most, float(car.get(&"door_deg")))
			if not bool(body.call(&"in_move")):
				out_at = t
				break
		await ticks(90)
		var p := body.global_position
		ok(out_at >= 0 and absf(p.y) < 0.02 and int(body.get(&"state")) == 0 and (p - seat).dot(left) > 1.5 and (J["Hips"] as Vector3).y > 0.9, "E: he gets out in %.1f s (the study: 5.8 s) and stands on the ground %.2f m to the left of the seat" % [out_at / 60.0, (p - seat).dot(left)])
		ok(door_most >= 40.0 and float(car.get(&"door_deg")) == 0.0, "E: the door was opened (%.0f degrees) and is shut again" % door_most)
	lab.call(&"place", Vector3(60.0, 0.0, 10.0))
	await ticks(20)
	var before := int(inter.get(&"plays"))
	await tap("act")
	await ticks(60)
	ok(int(inter.get(&"plays")) == before, "E with no car near: nothing happens")
	print("      (no bonnet slide: there is no take for it. The study: 'leave it out, or source it elsewhere')")
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
