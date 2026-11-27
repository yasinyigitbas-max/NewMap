extends SceneTree
## Stage 17, the wall-ledge sidle. The study: "For a ledge with a wall behind, allow a sidle down to about 0.10 m".
## The course has no such ledge: walls with a ledge 1.0 m up on each face are built here, a platform at each end.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage17_sidle.gd

const NAMES := ["LeftHand", "RightHand", "LeftArm", "RightArm", "Head", "LeftShoulder", "RightShoulder", "Hips", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]
const UP := 1.0                 # the ledges' height (m)

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var trav: Node
var skel: Skeleton3D
var fails := 0
var z_off := 0.0               # the course's own ledges are 1 m further along z than those built here, and 0.5 m up
var up_h := UP
var J := {}


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print("%s  %s" % ["ok  " if cond else "FAIL", what])


var head_fwd := Vector3.ZERO
var palms := [Vector3.ZERO, Vector3.ZERO]        # the way each palm faces


func _after() -> void:
	for f in 2:
		var hb := skel.find_bone("mixamorig_%sHand" % ["Left", "Right"][f])
		palms[f] = skel.global_transform.basis * ((skel.get_bone_global_pose(hb).basis.orthonormalized() * skel.get_bone_global_rest(hb).basis.orthonormalized().inverse()) * Vector3.DOWN)
	head_fwd = (skel.global_transform.basis * skel.get_bone_global_pose(skel.find_bone("mixamorig_Head")).basis).z.normalized()
	for n: String in NAMES:
		J[n] = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("mixamorig_" + n))).origin


## Along the ledge on the face at x = `face` (the wall is on the side `wall` of it: -1 or +1 in x), from its near
## platform (z 12) toward the far one (z under 6.5; the ledge is from 10.5 to 6.5). `plan` = [[ticks, mz], ...].
func along(face: float, wall: float, plan: Array) -> Dictionary:
	while bool(body.call(&"in_move")):
		await physics_frame
	lab.call(&"place", Vector3(face - wall * 0.4, up_h, 12.0 + z_off))
	body.rotation.y = 0.0
	for i in 20:
		await physics_frame
	var samples := []
	for step: Array in plan:
		for i in int(step[0]):
			samples.append({"mx": 0.0, "mz": float(step[1]), "yaw": 0.0, "run": false, "jump": false, "crouch": false, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var out := {"kinds": {}, "fast": 0.0, "turn_least": INF, "low": INF, "ankle_least": INF, "ankle_most": 0.0, "hips_least": INF, "toes_out": true,
			"far": INF, "moves": int(trav.get(&"plays")), "after": -1, "after_r": 0.0, "back": -INF, "head": 1.0, "arms": INF, "hand_least": INF, "palm": 1.0}
	var before := int(trav.get(&"plays"))
	for t in samples.size() - 2:
		await physics_frame
		await process_frame
		var p := body.global_position
		out["low"] = minf(float(out["low"]), p.y + (UP - up_h))
		out["far"] = minf(float(out["far"]), p.z - z_off)
		if p.y < up_h - 0.3:
			break
		# well onto the ledge
		if p.z < 10.0 + z_off and p.z > 7.0 + z_off:
			(out["kinds"] as Dictionary)[int(body.get(&"squeeze"))] = true
			out["fast"] = maxf(float(out["fast"]), (body.get(&"hvel") as Vector3).length())
			var sh: Vector3 = (J["RightShoulder"] as Vector3) - (J["LeftShoulder"] as Vector3)
			var a := absf(rad_to_deg(atan2(sh.z, sh.x)))
			out["turn_least"] = minf(float(out["turn_least"]), minf(a, 180.0 - a))
			for f: String in ["Left", "Right"]:
				var ankle := ((J[f + "Foot"] as Vector3).x - face) * -wall
				var ball := ((J[f + "ToeBase"] as Vector3).x - face) * -wall
				out["ankle_least"] = minf(float(out["ankle_least"]), ankle)
				out["ankle_most"] = maxf(float(out["ankle_most"]), ankle)
				out["toes_out"] = bool(out["toes_out"]) and ball > ankle
			out["head"] = minf(float(out["head"]), head_fwd.z * (-1.0 if (body.get(&"hvel") as Vector3).z < 0.0 else 1.0)) if (body.get(&"hvel") as Vector3).length() > 0.3 and p.z < 9.5 + z_off else float(out["head"])
			out["arms"] = minf(float(out["arms"]), (J["LeftHand"] as Vector3).distance_to(J["RightHand"])) if p.z < 9.5 + z_off else float(out["arms"])
			for f in 2:
				out["palm"] = minf(float(out["palm"]), (palms[f] as Vector3).x * wall) if p.z < 9.5 + z_off else float(out["palm"])
			for hn: String in ["LeftHand", "RightHand"]:
				out["hand_least"] = minf(float(out["hand_least"]), ((J[hn] as Vector3).x - face) * -wall)
			out["hips_least"] = minf(float(out["hips_least"]), ((J["Hips"] as Vector3).x - face) * -wall)
		if p.z < 5.6 + z_off and int(out["after"]) < 0:
			out["after"] = int(body.get(&"squeeze"))
			out["after_r"] = float(body.get(&"radius"))
		out["back"] = p.z - z_off
		# (he is not walked on off the end of a platform)
		if p.z < 5.3 + z_off or (t > 400 and p.z > 11.3 + z_off):
			break
	out["moves"] = int(trav.get(&"plays")) - before
	tape.call(&"stop")
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
	skel.skeleton_updated.connect(_after)
	var course: Node3D = lab.get(&"course")
	var stations: Array = course.get(&"stations")
	var x0 := float(stations[stations.size() - 1]["x"]) + 8.0
	var ledges := []                # [width, the x of its wall face, which side of that the wall is]
	var k := 0
	for pair: Array in [[0.15, 0.10], [0.24, 0.28], [0.20, 0.08]]:
		var xr := x0 + 3.6 * k      # the wall is from xr - 1 to xr
		k += 1
		course.call(&"_box", Vector3(xr - 0.5, 2.0, 9.0), Vector3(1.0, 4.0, 9.0))
		for side: int in 2:
			var w := float(pair[side])
			var face := xr if side == 0 else xr - 1.0
			var way := 1.0 if side == 0 else -1.0       # out from the wall
			course.call(&"_box", Vector3(face + way * 0.6, UP * 0.5, 11.5), Vector3(1.2, UP, 2.0))
			course.call(&"_box", Vector3(face + way * w * 0.5, UP - 0.05, 8.5), Vector3(w, 0.1, 4.0))
			course.call(&"_box", Vector3(face + way * 0.6, UP * 0.5, 5.5), Vector3(1.2, UP, 2.0))
			ledges.append([w, face, -way])
	for i in 5:
		await physics_frame
	var pace := float(body.get(&"SQUEEZE_SPEED"))
	# the course's own station: [width, face, wall side, z offset, height]
	for st: Dictionary in (course.get(&"extras") as Array):
		if String(st["kind"]) == "ledge":
			ledges.append([float((st["widths"] as Array)[0]), float(st["x"]) + 0.5, -1.0, 1.0, float(st["top"])])
			ledges.append([float((st["widths"] as Array)[1]), float(st["x"]) - 0.5, 1.0, 1.0, float(st["top"])])
	for l: Array in ledges:
		var w := float(l[0])
		z_off = float(l[3]) if l.size() > 3 else 0.0
		up_h = float(l[4]) if l.size() > 4 else UP
		var what := "%s %.2f m wide with a wall behind, the wall on his %s" % ["the course's ledge" if l.size() > 3 else "a ledge", w, "left" if float(l[2]) < 0.0 else "right"]
		var r := await along(float(l[1]), float(l[2]), [[900, -1.0]])
		if w < 0.10 - 0.001:
			ok(float(r["low"]) < UP - 0.3 or float(r["far"]) > 6.5, "%s: not allowed, he does not get along it (to z %.2f, lowest %.2f m)" % [what, float(r["far"]), float(r["low"])])
			continue
		var kinds: Array = (r["kinds"] as Dictionary).keys()
		ok(float(r["far"]) < 5.6 and float(r["low"]) > UP - 0.03, "%s: he gets along it to the far platform and stays on it (to z %.2f, lowest %.2f m)" % [what, float(r["far"]), float(r["low"])])
		ok(kinds == [3], "%s: taken as a ledge to sidle along all the way (seen: %s)" % [what, kinds])
		ok(float(r["fast"]) <= pace + 0.05 and float(r["fast"]) > pace * 0.7, "%s: at the side step's pace (%.2f m/s; %.2f)" % [what, float(r["fast"]), pace])
		ok(float(r["turn_least"]) > 75.0 and bool(r["toes_out"]), "%s: sideways, his back to the wall (shoulders at least %.0f degrees from square, toes out from the wall: %s)" % [what, float(r["turn_least"]), r["toes_out"]])
		ok(float(r["ankle_least"]) > 0.01 and float(r["ankle_most"]) < 0.14, "%s: his heels to the wall (ankle joints %.2f to %.2f m out from it)" % [what, float(r["ankle_least"]), float(r["ankle_most"])])
		ok(float(r["hips_least"]) > 0.10, "%s: his back on the wall, not in it (hip joints at least %.2f m out from it)" % [what, float(r["hips_least"])])
		ok(float(r["arms"]) > 0.95 and float(r["hand_least"]) > 0.0, "%s: his arms are open to both sides, on the wall and not in it (wrists at least %.2f m apart, at least %.2f m out from the wall)" % [what, float(r["arms"]), float(r["hand_least"])])
		ok(float(r["palm"]) > 0.7, "%s: his palms face the wall behind him (within %.0f degrees of it)" % [what, rad_to_deg(acos(clampf(float(r["palm"]), -1.0, 1.0)))])
		ok(float(r["head"]) > 0.8, "%s: his head looks the way he goes (within %.0f degrees of it)" % [what, rad_to_deg(acos(clampf(float(r["head"]), -1.0, 1.0)))])
		ok(int(r["after"]) == 0 and float(r["after_r"]) > 0.24 and int(r["moves"]) == 0, "%s: on the far platform he is as he was before (kind %d, his shape %.2f m, %d moves played)" % [what, int(r["after"]), float(r["after_r"]), int(r["moves"])])
	# half way along, standing still for 12 s (no loss of balance: his back is on the wall), then back the way he came
	for l: Array in ledges:
		if absf(float(l[0]) - 0.15) > 0.001 and absf(float(l[0]) - 0.20) > 0.001:
			continue
		if l.size() > 3:
			continue
		z_off = 0.0
		up_h = UP
		var what := "a ledge %.2f m wide, the wall on his %s" % [float(l[0]), "left" if float(l[2]) < 0.0 else "right"]
		var r := await along(float(l[1]), float(l[2]), [[330, -1.0], [720, 0.0], [600, 1.0]])
		ok(float(r["low"]) > UP - 0.03 and int(r["moves"]) == 0 and float(r["far"]) < 9.5 and float(r["far"]) > 7.0, "%s, half way and still for 12 s: he stays on it, no move plays (lowest %.2f m, furthest z %.2f, %d moves)" % [what, float(r["low"]), float(r["far"]), int(r["moves"])])
		ok(float(r["back"]) > 10.6 and bool(r["toes_out"]) and float(r["turn_least"]) > 75.0, "%s, then back the way he came: he is back on the near platform (z %.2f), and never turned to face the wall (toes out: %s, shoulders at least %.0f degrees from square)" % [what, float(r["back"]), r["toes_out"], float(r["turn_least"])])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
