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
	# Losing his balance (Yasin, 26 Nov: "we should fall off losing balance if we dont move more than 10 seconds on the
	# beam", "we should fall onto our back or face down and get up later"): still on the 0.10 m beam.
	for s: Dictionary in stations:
		if String(s["kind"]) != "beam" or absf(float(s["width"]) - 0.10) > 0.001:
			continue
		for wait: Array in [[8.0, false], [10.5, true]]:
			lab.call(&"place", Vector3(float(s["x"]), float(s["top"]), -8.0))
			body.rotation.y = 0.0
			var samples := []
			for i in 1500:
				# (still for `wait` seconds; then, if he is not to fall, a step along the beam)
				samples.append({"mx": 0.0, "mz": -1.0 if (not bool(wait[1]) and i > int(float(wait[0]) * 60.0)) else 0.0, "yaw": 0.0, "run": false, "jump": false, "crouch": false, "act": false})
			tape.set(&"tape", samples)
			tape.call(&"replay")
			var before := int(trav.get(&"plays"))
			var t := 0
			var began := -1
			var lowest_hips := INF
			var done_at := -1
			while int(tape.get(&"mode")) == 2 and t < (1400 if bool(wait[1]) else 720):
				await physics_frame
				await process_frame
				t += 1
				if began < 0 and int(trav.get(&"plays")) > before:
					began = t
				if began >= 0:
					lowest_hips = minf(lowest_hips, (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("mixamorig_Hips"))).origin.y)
					if not bool(body.call(&"in_move")):
						done_at = t
						break
			tape.call(&"stop")
			var key := String((trav.get(&"_plan") as Dictionary).get("key", "")) if began >= 0 else ""
			if not bool(wait[1]):
				ok(began < 0 and body.global_position.y > float(s["top"]) - 0.03, "%s, still for %.0f s and then on: he does not fall (%s)" % [s["label"], float(wait[0]), "no move" if began < 0 else "'%s' began" % key])
				continue
			var p := body.global_position
			var bad := ""
			if key != "balance_fall":
				bad = "he did not lose his balance (%s)" % ("no move" if began < 0 else "'%s' began" % key)
			elif absf(began / 60.0 - 10.0) > 0.6:
				bad = "it began after %.1f s" % (began / 60.0)
			elif done_at < 0:
				bad = "it did not end"
			elif absf(p.y) > 0.02 or int(body.get(&"state")) != 0 or absf(p.x - float(s["x"])) < 1.0:
				bad = "he is not standing on the ground beside it (at %s, state %d)" % [p, int(body.get(&"state"))]
			elif lowest_hips > 0.35:
				bad = "he did not go down to the ground (his hips no lower than %.2f m)" % lowest_hips
			ok(bad == "", "%s, still for 10 s: he loses his balance after %.1f s, goes down on the ground beside it (hips to %.2f m) and gets up: standing %.1f m to its side, on the ground, %.1f s later%s" % [
					s["label"], began / 60.0, lowest_hips, absf(p.x - float(s["x"])), (done_at - began) / 60.0, "" if bad == "" else " -- " + bad])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
