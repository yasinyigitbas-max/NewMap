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
	# beam", "make him hard land instead of a hard fall when falling from lower than 3.1 meters and if above hard
	# fall"): still on the 0.10 m beam of the course (0.5 m up), and on one built here 3.3 m up.
	var course: Node3D = lab.get(&"course")
	var hx := float(stations[stations.size() - 1]["x"]) + 8.0
	course.call(&"_box", Vector3(hx, 3.25, -8.0), Vector3(0.10, 0.1, 6.0))
	for i in 5:
		await physics_frame
	var beams := []
	for s: Dictionary in stations:
		if String(s["kind"]) == "beam" and absf(float(s["width"]) - 0.10) < 0.001:
			beams.append([s["label"], float(s["x"]), float(s["top"]), "balance_land"])
	beams.append(["a 0.10 m beam 3.30 m up (built for this test)", hx, 3.30, "balance_fall"])
	for bm: Array in beams:
		for wait: Array in [[8.0, false], [10.5, true]]:
			if not bool(wait[1]) and String(bm[3]) == "balance_fall":
				continue
			lab.call(&"place", Vector3(float(bm[1]), float(bm[2]), -8.0))
			body.rotation.y = 0.0
			var samples := []
			for i in 1700:
				# (still for `wait` seconds; then, if he is not to fall, a step along the beam)
				samples.append({"mx": 0.0, "mz": -1.0 if (not bool(wait[1]) and i > int(float(wait[0]) * 60.0)) else 0.0, "yaw": 0.0, "run": false, "jump": false, "crouch": false, "act": false})
			tape.set(&"tape", samples)
			tape.call(&"replay")
			var before := int(trav.get(&"plays"))
			var t := 0
			var began := -1
			var lowest_hips := INF
			var done_at := -1
			while int(tape.get(&"mode")) == 2 and t < (1600 if bool(wait[1]) else 720):
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
				ok(began < 0 and body.global_position.y > float(bm[2]) - 0.03, "%s, still for %.0f s and then on: he does not fall (%s)" % [bm[0], float(wait[0]), "no move" if began < 0 else "'%s' began" % key])
				continue
			var p := body.global_position
			var on_feet := String(bm[3]) == "balance_land"
			var bad := ""
			if key != String(bm[3]):
				bad = "'%s' did not play (%s)" % [bm[3], "no move" if began < 0 else "'%s' began" % key]
			elif absf(began / 60.0 - 10.0) > 0.6:
				bad = "it began after %.1f s" % (began / 60.0)
			elif done_at < 0:
				bad = "it did not end"
			elif absf(p.y) > 0.02 or int(body.get(&"state")) != 0 or absf(p.x - float(bm[1])) < 0.5:
				bad = "he is not standing on the ground beside it (at %s, state %d)" % [p, int(body.get(&"state"))]
			elif on_feet and lowest_hips < 0.30:
				bad = "he went down on the ground (his hips to %.2f m): from this height he is to land on his feet" % lowest_hips
			elif not on_feet and lowest_hips > 0.35:
				bad = "he did not go down on the ground (his hips no lower than %.2f m)" % lowest_hips
			ok(bad == "", "%s, still for 10 s: he loses his balance after %.1f s, %s (his hips to %.2f m), and is standing %.1f m to its side, on the ground, %.1f s later%s" % [
					bm[0], began / 60.0, "comes down off its side on his feet, a hard landing" if on_feet else "falls off its side face down and gets up", lowest_hips, absf(p.x - float(bm[1])), (done_at - began) / 60.0, "" if bad == "" else " -- " + bad])
	# On top of a thin wall (Yasin, 26 Nov: "he couldnt walk on teh walls, only on beams"): climbed with the stick let
	# go once the climb has begun, he stays standing on it, taken as on something narrow, and walks along it.
	for label: String in ["thin wall 1.10 m", "thin wall 1.80 m"]:
		for s: Dictionary in stations:
			if String(s["label"]) != label:
				continue
			var top := float(s["top"])
			lab.call(&"place", Vector3(float(s["x"]), 0.0, -2.72))
			body.rotation.y = 0.0
			for i in 30:
				await physics_frame
			tape.set(&"tape", [])
			var before := int(trav.get(&"plays"))
			var t := 0
			var began := -1
			var ended := false
			# forward until the climb has begun, then nothing; then, once he is on top, along the wall
			var live := []
			for i in 900:
				live.append({"mx": 0.0, "mz": -1.0, "yaw": 0.0, "run": false, "jump": false, "crouch": false, "act": false})
			tape.set(&"tape", live)
			tape.call(&"replay")
			var on_top := Vector3.ZERO
			var narrow_top := 0
			var along := 0.0
			while int(tape.get(&"mode")) == 2 and t < 880:
				await physics_frame
				t += 1
				if began < 0 and int(trav.get(&"plays")) > before:
					began = t
					for i in range(t, 900):
						(live[i] as Dictionary)["mz"] = 0.0
					tape.set(&"tape", live)
				if began >= 0 and not ended and not bool(body.call(&"in_move")) and t > began + 20:
					ended = true
					on_top = body.global_position
					for i in range(t + 30, mini(t + 150, 900)):
						(live[i] as Dictionary)["mx"] = 1.0
					tape.set(&"tape", live)
				if ended:
					narrow_top = maxi(narrow_top, int(body.get(&"narrow")))
					along = maxf(along, body.global_position.x - on_top.x)
					if t > began + 20 and absf(body.global_position.y - top) > 0.05:
						break
			tape.call(&"stop")
			var bad := ""
			if began < 0:
				bad = "no climb began"
			elif not ended or absf(on_top.y - top) > 0.02:
				bad = "he is not on its top after the climb (at height %.2f)" % on_top.y
			elif narrow_top < 1:
				bad = "he is not taken as on something narrow there"
			elif along < 0.8 or absf(body.global_position.y - top) > 0.05:
				bad = "he does not walk along it (%.2f m along, at height %.2f)" % [along, body.global_position.y]
			ok(bad == "", "%s, the stick let go once the climb has begun: he stays standing on its top (height %.2f m), taken as on something narrow, and walks %.1f m along it%s" % [label, on_top.y, along, "" if bad == "" else " -- " + bad])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)
