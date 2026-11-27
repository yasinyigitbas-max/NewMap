extends SceneTree
## Stage 22, doors: push, then pull. The study: "Passing a push door adds about 2 to 3 s to walking through, a pull
## door about 4 s"; door opening "0.815 m wide, 2.03 m high"; "Door hardware sits 0.865 to 1.22 m above the floor";
## of every move: "hands rest on the edge within about 3 cm", "the body ends where the detection record said it
## would, standing on ground", "cancelling is impossible mid-move".
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage22.gd

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var trav: Node
var inter: Node
var skel: Skeleton3D
var fails := 0
var J := {}


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print("%s  %s" % ["ok  " if cond else "FAIL", what])


func _after() -> void:
	for n: String in ["Hips", "LeftHand", "RightHand", "Head", "LeftShoulder", "RightShoulder", "LeftLeg", "RightLeg"]:
		J[n] = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("mixamorig_" + n))).origin


## From `from`, the stick `way` (mx, mz) for `go` ticks; `back_at` >= 0: from that tick the stick is reversed.
func walk(door: Node3D, hinge: Vector3, from: Vector3, way: Vector2, run: bool, go: int, back_at := -1) -> Dictionary:
	while bool(body.call(&"in_move")) or float(door.get(&"open_deg")) > 0.0:
		await physics_frame
	lab.call(&"place", from)
	body.rotation.y = 0.0 if way.y < 0.0 else PI
	for i in 20:
		await physics_frame
	var samples := []
	for i in go:
		var w := way if (back_at < 0 or i < back_at) else -way
		samples.append({"mx": w.x, "mz": w.y, "yaw": 0.0, "run": run, "jump": false, "crouch": false, "act": false})
	for i in 400:
		samples.append({"mx": 0.0, "mz": 0.0, "yaw": 0.0, "run": false, "jump": false, "crouch": false, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var before := int(inter.get(&"plays"))
	var climbs := int(trav.get(&"plays"))
	var out := {"key": "", "began": -1, "ended": -1, "open_most": 0.0, "hand_off": 0.0, "held": 0, "leaf_least": INF, "shut_at": -1, "z_began": 0.0, "low": INF, "at_end": Vector3.ZERO, "frame_least": INF}
	for t in go + 380:
		await physics_frame
		await process_frame
		if int(out["began"]) < 0 and int(inter.get(&"plays")) > before:
			out["began"] = t
			out["key"] = String(inter.get(&"last"))
			out["z_began"] = body.global_position.z
		if int(out["began"]) >= 0 and int(out["ended"]) < 0:
			out["open_most"] = maxf(float(out["open_most"]), float(door.get(&"open_deg")))
			var mh: Array = body.get(&"move_hand")
			if mh.size() > 0 and float((mh[0] as Array)[2]) >= 0.99:
				out["held"] = int(out["held"]) + 1
				var which: String = ["LeftHand", "RightHand"][int((mh[0] as Array)[0])]
				out["hand_off"] = maxf(float(out["hand_off"]), (J[which] as Vector3).distance_to((mh[0] as Array)[1]))
			# how near the middle of his body (hips, head, shoulders, knees) comes to the leaf
			var deg := deg_to_rad(float(door.get(&"open_deg")))
			var tip := hinge + Vector3(-cos(deg), 0.0, sin(deg)) * 0.815
			for n: String in ["Hips", "Head", "LeftShoulder", "RightShoulder", "LeftLeg", "RightLeg"]:
				var q: Vector3 = J[n]
				var ab := tip - hinge
				var u := clampf((Vector3(q.x, 0.0, q.z) - hinge).dot(ab) / ab.length_squared(), 0.0, 1.0)
				out["leaf_least"] = minf(float(out["leaf_least"]), Vector3(q.x, 0.0, q.z).distance_to(hinge + ab * u))
				# in the plane of the wall: how far inside the opening (from the hinge to 0.815 m along) the joint is
				if absf(q.z - hinge.z) < 0.10:
					out["frame_least"] = minf(float(out["frame_least"]), minf(hinge.x - q.x, 0.815 - (hinge.x - q.x)))
			out["low"] = minf(float(out["low"]), body.global_position.y)
			if not bool(body.call(&"in_move")):
				out["ended"] = t
				out["at_end"] = body.global_position
				tape.call(&"stop")              # (he is not walked on, back into the door or off the course)
		if int(out["ended"]) >= 0 and int(out["shut_at"]) < 0 and float(door.get(&"open_deg")) <= 0.0:
			out["shut_at"] = t
	tape.call(&"stop")
	out["climbs"] = int(trav.get(&"plays")) - climbs
	out["at"] = body.global_position
	out["state"] = int(body.get(&"state"))
	return out


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 5:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	trav = lab.get(&"traverse")
	inter = lab.get(&"interact")
	skel = (lab.get(&"character") as Node).get(&"skel")
	skel.skeleton_updated.connect(_after)
	var st := {}
	for s: Dictionary in ((lab.get(&"course") as Node3D).get(&"extras") as Array):
		if String(s["kind"]) == "door":
			st = s
	ok(not st.is_empty(), "the course has a door station")
	if st.is_empty():
		quit(1)
		return
	var door: Node3D = st["door"]
	var hinge: Vector3 = st["hinge"]
	var mid_x := hinge.x - 0.4075
	var walk_speed := float(body.get(&"WALK"))
	# the opening itself
	var space := body.get_world_3d().direct_space_state
	var l := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(mid_x, 2.2, hinge.z + 0.5), Vector3(mid_x, 2.2, hinge.z - 0.5)))
	ok(absf(float(door.get(&"WIDE")) - 0.815) < 0.001 and absf(float(door.get(&"HIGH")) - 2.03) < 0.001 and not l.is_empty(), "the door is the study's 0.815 m by 2.03 m, a wall over it; its bar is %.2f m up (the study's hardware: 0.865 to 1.22 m)" % float(door.get(&"BAR_HIGH")))
	for side: String in ["pull", "push"]:
		var sgn := 1.0 if side == "pull" else -1.0         # which side of the wall he comes from (+Z = the pull side)
		var line_x := hinge.x - 0.35 if side == "pull" else hinge.x - 0.24
		for case: Array in [[0.0, false, -1], [0.30, false, -1], [-0.30, false, -1], [0.0, true, -1], [0.0, false, 0]]:
			var from := Vector3(line_x + float(case[0]), 0.0, hinge.z + sgn * 2.6)
			var r := await walk(door, hinge, from, Vector2(0.0, -sgn), bool(case[1]), 500, 150 if int(case[2]) == 0 else -1)
			var how := "the door from its %s side, at a %s%s%s" % [side, "run" if bool(case[1]) else "walk", "" if float(case[0]) == 0.0 else ", %+.2f m off the take's line" % float(case[0]), ", the stick turned back once it has begun" if int(case[2]) == 0 else ""]
			var at: Vector3 = r["at"]
			var through := (hinge.z - at.z) * sgn
			ok(String(r["key"]) == "door_" + side and int(r["climbs"]) == 0, "%s: the %s move plays, no climb (%s, %d climbs)" % [how, side, r["key"], int(r["climbs"])])
			if String(r["key"]) == "":
				continue
			ok(through > 0.6 and int(r["state"]) == 0 and absf(at.y) < 0.02 and float(r["low"]) > -0.02 and int(r["ended"]) > 0, "%s: he ends through it, standing on the ground (%.2f m past the door)" % [how, through])
			# (OURS, how it is told: no joint centre nearer the leaf than 4 cm; a knee is about 6 cm from its joint to its skin)
			ok(float(r["open_most"]) >= 85.0 and float(r["leaf_least"]) > 0.04, "%s: the door opens %.0f degrees and he does not go through its leaf (hips, head, shoulders and knees at least %.2f m from it)" % [how, float(r["open_most"]), float(r["leaf_least"])])
			ok(float(r["frame_least"]) > 0.04, "%s: nor through the door's frame (those joints at least %.2f m inside the opening as they pass it)" % [how, float(r["frame_least"])])
			ok(int(r["held"]) > 10 and float(r["hand_off"]) <= 0.03, "%s: his hand is on the door's bar (%d ticks, at most %.3f m off it; the study: about 3 cm)" % [how, int(r["held"]), float(r["hand_off"])])
			ok(int(r["shut_at"]) > 0 and int(r["shut_at"]) - int(r["ended"]) < 240, "%s: the door has shut again %.1f s after" % [how, (int(r["shut_at"]) - int(r["ended"])) / 60.0])
			if float(case[0]) == 0.0 and not bool(case[1]) and int(case[2]) < 0:
				# against walking the same ground at his walking pace
				var secs := (int(r["ended"]) - int(r["began"])) / 60.0
				var ground := absf((r["at_end"] as Vector3).z - float(r["z_began"]))
				var adds := secs - ground / walk_speed
				if side == "push":
					ok(adds >= 2.0 and adds <= 3.0, "%s: it takes %.2f s over %.2f m, %.1f s more than walking it (the study: a push door adds about 2 to 3 s)" % [how, secs, ground, adds])
				else:
					print("      %s: it takes %.2f s over %.2f m, %.1f s more than walking it (the study: a pull door about 4 s; this is the take's own pace)" % [how, secs, ground, adds])
	# beside the door: a wall, and nothing plays
	var r2 := await walk(door, hinge, Vector3(hinge.x + 1.2, 0.0, hinge.z + 2.6), Vector2(0.0, -1.0), false, 300)
	ok(String(r2["key"]) == "" and int(r2["climbs"]) == 0 and (r2["at"] as Vector3).z > hinge.z, "walking at the wall 1.2 m beside the door: no door move, no climb, he is stopped by it")
	# along the wall past the door: nothing plays
	var r3 := await walk(door, hinge, Vector3(hinge.x + 1.5, 0.0, hinge.z + 0.75), Vector2(-1.0, 0.0), false, 300)
	ok(String(r3["key"]) == "", "walking along the wall past the door: no door move")
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
