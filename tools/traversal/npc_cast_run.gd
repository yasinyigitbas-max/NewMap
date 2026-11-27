extends SceneTree
## One NPC body through the civilian moves (27 Nov, Yasin: "can you test the other npcs while adding the new moves?").
## Prints one line of numbers; judged by the reader, no bar of its own.
var lab: Node3D
var body: CharacterBody3D
var tape: Node
var skel: Skeleton3D
var J := {}
var keys := {"mx": 0.0, "mz": 0.0, "run": false, "act": false, "text": false, "call": false, "jump": false, "crouch": false}
const NAMES := ["Hips", "Head", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase", "LeftHand", "RightHand"]
func _initialize() -> void:
	_run.call_deferred()
func _pose() -> void:
	for n: String in NAMES:
		var i := skel.find_bone("mixamorig_" + n)
		if i >= 0:
			J[n] = skel.global_transform * skel.get_bone_global_pose(i).origin
func ticks(n: int) -> void:
	for i in n:
		tape.set(&"tape", [{"mx": keys["mx"], "mz": keys["mz"], "yaw": 0.0, "run": keys["run"], "jump": keys["jump"], "crouch": keys["crouch"], "act": keys["act"], "text": keys["text"], "call": keys["call"]}])
		tape.call(&"replay")
		await physics_frame
func tap(key: String) -> void:
	keys[key] = true
	await ticks(3)
	keys[key] = false
	await ticks(2)
func low() -> float:
	return minf(minf((J["LeftFoot"] as Vector3).y, (J["RightFoot"] as Vector3).y), minf((J["LeftToeBase"] as Vector3).y, (J["RightToeBase"] as Vector3).y))
func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 5:
		await physics_frame
	body = lab.get(&"body"); tape = lab.get(&"tape")
	var chr: Node = lab.get(&"character")
	var inter: Node = lab.get(&"interact")
	skel = chr.get(&"skel")
	skel.skeleton_updated.connect(_pose)
	var o := {"class": chr.get_class(), "bones": skel.get_bone_count(), "fingers": skel.find_bone("mixamorig_LeftHandIndex1") >= 0}
	# standing
	lab.call(&"place", Vector3(60.0, 0.0, 10.0)); body.rotation.y = 0.0
	await ticks(120)
	o["stand_hips"] = snappedf((J["Hips"] as Vector3).y, 0.001); o["stand_head"] = snappedf((J["Head"] as Vector3).y, 0.001)
	o["stand_low"] = snappedf(low(), 0.001)
	o["stand_ankles"] = [snappedf((J["LeftFoot"] as Vector3).y, 0.001), snappedf((J["RightFoot"] as Vector3).y, 0.001)]
	# walking and running on the flat: the lowest foot joint each tick (the ground is at 0), and the pace
	for gait: String in ["walk", "run"]:
		keys["mz"] = 1.0; keys["run"] = gait == "run"
		await ticks(90)
		var lo := INF; var hi := -INF; var z0 := body.global_position.z
		var hip_lo := INF; var hip_hi := -INF
		for i in 120:
			await ticks(1)
			lo = minf(lo, low()); hi = maxf(hi, low())
			hip_lo = minf(hip_lo, (J["Hips"] as Vector3).y); hip_hi = maxf(hip_hi, (J["Hips"] as Vector3).y)
		o[gait + "_low"] = [snappedf(lo, 0.001), snappedf(hi, 0.001)]
		o[gait + "_hips"] = [snappedf(hip_lo, 0.001), snappedf(hip_hi, 0.001)]
		o[gait + "_pace"] = snappedf(absf(body.global_position.z - z0) / 2.0, 0.01)
		keys["mz"] = 0.0; keys["run"] = false
		await ticks(120)
		lab.call(&"place", Vector3(60.0, 0.0, 10.0)); body.rotation.y = 0.0
		await ticks(30)
	# every stairs and kerb station walked: how high he ends, and whether he is on the ground
	var st: Array = ((lab.get(&"course") as Node3D).get(&"stations") as Array) + ((lab.get(&"course") as Node3D).get(&"extras") as Array)
	var kinds := {}
	for s: Dictionary in st:
		var k := String(s["kind"])
		if k in ["stairs", "kerb", "step", "ramp"] and int(kinds.get(k, 0)) < 2:
			kinds[k] = int(kinds.get(k, 0)) + 1
			lab.call(&"place", s["start"]); body.rotation.y = 0.0
			keys["mz"] = -1.0
			var worst := 0.0
			for i in 300:
				await ticks(1)
				worst = maxf(worst, absf(low() - body.global_position.y) if int(body.get(&"state")) == 0 else 0.0)
			keys["mz"] = 0.0
			await ticks(60)
			o["%s%d" % [k, kinds[k]]] = [String(s["label"]), snappedf(body.global_position.y, 0.01), snappedf(worst, 0.001), int(body.get(&"state"))]
	# the phone, standing
	lab.call(&"place", Vector3(60.0, 0.0, 10.0)); body.rotation.y = 0.0
	await ticks(60)
	await tap("text")
	await ticks(90)
	o["text_hands"] = [snappedf((J["LeftHand"] as Vector3).y, 0.01), snappedf((J["RightHand"] as Vector3).y, 0.01), snappedf((J["LeftHand"] as Vector3).distance_to(J["RightHand"]), 0.01)]
	await tap("text")
	await ticks(60)
	# the bench
	for seat: Node3D in get_nodes_in_group(&"tl_seat"):
		if bool(seat.get_meta(&"desk")):
			continue
		var stand: Vector3 = inter.call(&"_seat_stand", seat)
		lab.call(&"place", stand + Vector3(0.3, 0.0, 1.2)); body.rotation.y = 0.0
		await ticks(30)
		await tap("act")
		var n := 0
		while String(inter.get(&"sit_phase")) != "idle" and n < 900:
			await ticks(1); n += 1
		await ticks(60)
		o["sit"] = [String(inter.get(&"sit_phase")), n, snappedf((J["Hips"] as Vector3).y - seat.global_position.y, 0.001), snappedf(low() - seat.global_position.y, 0.001),
				snappedf(Vector2((J["Hips"] as Vector3).x - seat.global_position.x, (J["Hips"] as Vector3).z - seat.global_position.z).length(), 0.001)]
		await tap("act")
		n = 0
		while bool(inter.get(&"seated")) and n < 600:
			await ticks(1); n += 1
		await ticks(30)
		o["sit_up"] = [n, int(body.get(&"state")), snappedf((J["Hips"] as Vector3).y - body.global_position.y, 0.001)]
		break
	# the car
	for car: Node3D in get_nodes_in_group(&"tl_car"):
		var start: Vector3 = (inter.call(&"_car_start", car) as Array)[0]
		lab.call(&"place", start + Vector3(0.5, 0.0, 0.8)); body.rotation.y = 0.0
		await ticks(30)
		await tap("act")
		var n2 := 0
		while not bool(inter.get(&"in_car")) and n2 < 1200:
			await ticks(1); n2 += 1
		await ticks(60)
		o["car_in"] = [bool(inter.get(&"in_car")), n2, snappedf((J["Hips"] as Vector3).y - car.global_position.y, 0.001), snappedf(low() - car.global_position.y, 0.001)]
		await tap("act")
		n2 = 0
		while bool(body.call(&"in_move")) and n2 < 900:
			await ticks(1); n2 += 1
		await ticks(30)
		o["car_out"] = [n2, int(body.get(&"state")), snappedf(body.global_position.y, 0.01)]
		break
	print("CAST ", JSON.stringify(o))
	quit()
