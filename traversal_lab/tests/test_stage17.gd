extends SceneTree
## Stage 17, narrow surfaces: the beams of the course (0.25, 0.10 and 0.05 m wide). The study: "on a top surface
## 0.25 m or wider, walk normally; 0.10 to 0.25 m, walk slowly with arms out (about 0.7 to 0.8 m/s ...); 0.04 to
## 0.10 m, slow heel-to-toe". Yasin, 26 Nov: arms spread to balance, standing only (no crouch), and off its side as
## off any edge. Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage17.gd

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var trav: Node
var chr: Node
var skel: Skeleton3D
var stations: Array
var fails := 0
var wrists := [Vector3.ZERO, Vector3.ZERO]


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print("%s  %s" % ["ok  " if cond else "FAIL", what])


func _after() -> void:
	wrists = [(skel.global_transform * skel.get_bone_global_pose(skel.find_bone("mixamorig_LeftHand"))).origin,
			(skel.global_transform * skel.get_bone_global_pose(skel.find_bone("mixamorig_RightHand"))).origin]


## Along the beam of `s` from its near platform: `go` ticks with the stick forward, then `rest` ticks with it at rest.
func along(s: Dictionary, run: bool, low: bool, go: int, rest: int) -> Dictionary:
	lab.call(&"place", Vector3(float(s["x"]), float(s["top"]), -4.5))
	body.rotation.y = 0.0
	for i in 30:
		await physics_frame
	var samples := []
	for i in go + rest:
		samples.append({"mx": 0.0, "mz": -1.0 if i < go else 0.0, "yaw": 0.0, "run": run, "jump": false, "crouch": low, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var out := {"fastest": 0.0, "narrow": {}, "crouched": false, "lowest": INF, "spread_walk": INF, "spread_rest": INF, "far": 0.0, "blend": 0.0}
	var t := 0
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		await process_frame
		t += 1
		var p := body.global_position
		out["far"] = minf(float(out["far"]), p.z)
		# well onto the beam, and not yet at its far end
		if p.z < -6.5 and p.z > -10.2:
			var sp := (body.get(&"hvel") as Vector3).length()
			out["fastest"] = maxf(float(out["fastest"]), sp)
			(out["narrow"] as Dictionary)[int(body.get(&"narrow"))] = true
			out["crouched"] = bool(out["crouched"]) or bool(body.get(&"crouched"))
			out["lowest"] = minf(float(out["lowest"]), p.y)
			out["blend"] = maxf(float(out["blend"]), float(chr.get(&"_narrow_w")))
			var apart: float = (wrists[0] as Vector3).distance_to(wrists[1])
			if t < go:
				out["spread_walk"] = minf(float(out["spread_walk"]), apart)
			if t > go + 50:
				out["spread_rest"] = minf(float(out["spread_rest"]), apart)
	return out


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 5:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	trav = lab.get(&"traverse")
	chr = lab.get(&"character")
	skel = chr.get(&"skel")
	stations = (lab.get(&"course") as Node3D).get(&"stations")
	skel.skeleton_updated.connect(_after)
	lab.call(&"place", Vector3(60.0, 0.0, 10.0))
	for i in 60:
		await physics_frame
		await process_frame
	var at_rest: float = (wrists[0] as Vector3).distance_to(wrists[1])
	print("      (standing on open ground his wrists are %.2f m apart)" % at_rest)
	var walk := float(body.get(&"WALK"))
	for s: Dictionary in stations:
		if String(s["kind"]) != "beam":
			continue
		var w := float(s["width"])
		var deck := float(s["top"])
		var want := 0 if w >= 0.25 - 0.001 else (1 if w >= 0.10 - 0.001 else 2)
		var most := walk if want == 0 else (float(body.get(&"NARROW_SPEED")) if want == 1 else float(body.get(&"NARROW_SPEED_LEAST")))
		# at a walk, then standing still on it
		var r := await along(s, false, false, 300 if want == 0 else 420, 120)
		var seen: Array = (r["narrow"] as Dictionary).keys()
		ok(seen == [want], "%s, at a walk: taken as %s all the way (seen: %s)" % [s["label"], ["wide enough to walk normally", "narrow", "very narrow"][want], seen])
		ok(float(r["lowest"]) > deck - 0.03, "%s, at a walk: he stays on it (lowest %.2f m against its top)" % [s["label"], float(r["lowest"]) - deck])
		ok(float(r["fastest"]) <= most + 0.05 and float(r["fastest"]) > most * 0.7, "%s, at a walk: his pace on it is %.2f m/s (the study's %.2f)" % [s["label"], float(r["fastest"]), most])
		if want > 0:
			ok(float(r["blend"]) >= 0.99, "%s: the beam walk is shown (its share %.2f)" % [s["label"], float(r["blend"])])
			ok(float(r["spread_walk"]) > at_rest + 0.5, "%s, walking: his arms are spread (wrists at least %.2f m apart; %.2f m standing on open ground)" % [s["label"], float(r["spread_walk"]), at_rest])
			ok(float(r["spread_rest"]) > at_rest + 0.5, "%s, standing still on it: his arms are spread (wrists at least %.2f m apart)" % [s["label"], float(r["spread_rest"])])
			# with the run key held: no faster
			var rr := await along(s, true, false, 300, 0)
			ok(float(rr["fastest"]) <= most + 0.05, "%s, the run key held: no faster (%.2f m/s)" % [s["label"], float(rr["fastest"])])
			# with the crouch key held: he does not crouch on it
			var rc := await along(s, false, true, 300, 0)
			ok(not bool(rc["crouched"]) and float(rc["far"]) < -6.5, "%s, the crouch key held: he is not crouched on it, and walks it (to %.1f m along)" % [s["label"], -5.0 - float(rc["far"])])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
