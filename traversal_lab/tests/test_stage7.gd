extends SceneTree
## Stage 7, detection only. The study: "Pass when: at every wall, step and gap on the course, approached straight on
## and at 30 degrees, at walk and run, the drawn height is within 5 cm of the label and the depth within 10 cm; thin
## walls are reported thin and deep ones deep; nothing is reported on open ground; a wall with no headroom above it
## is reported as blocked; a hundred approaches in the replay tool give a hundred correct records."
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_stage7.gd
## Every tick of every approach on which something is reported is held to the label, not one chosen tick.

const Detector := preload("res://traversal/detect/detector.gd")
const HEIGHT_WITHIN := 0.05     # the study: "within 5 cm of the label"
const DEPTH_WITHIN := 0.10      # the study: "the depth within 10 cm"

var lab: Node3D
var body: CharacterBody3D
var tape: Node
var det: RefCounted
var stations: Array
var fails := 0
var approaches := 0
var correct := 0
var most_queries := 0


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	if not cond or OS.get_cmdline_user_args().has("--all"):
		print("%s  %s" % ["ok  " if cond else "FAIL", what])


## Walk or run from `from` toward `to` and measure on every tick. Returns the records that reported something.
func approach(from: Vector3, to: Vector3, run: bool, seconds: float) -> Array:
	lab.call(&"place", from)
	var way := to - from
	way.y = 0.0
	way = way.normalized()
	body.rotation.y = atan2(-way.x, -way.z)
	for i in 30:
		await physics_frame
	var samples := []
	for i in int(seconds * 60.0):
		samples.append({"mx": way.x, "mz": way.z, "yaw": 0.0, "run": run, "jump": false, "crouch": false, "act": false})
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var out := []
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		if int(body.get(&"state")) != 0:
			continue
		var rec: Dictionary = det.call(&"measure", way)
		most_queries = maxi(most_queries, int(rec.get("queries", 0)))
		if rec["kind"] != "none":
			rec["at"] = body.global_position
			out.append(rec)
	tape.call(&"stop")
	return out


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 5:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	stations = (lab.get(&"course") as Node3D).get(&"stations")
	# "Detection only. No clips.": the traversal moves are off while it is tested
	if lab.get(&"traverse") != null:
		(lab.get(&"traverse") as Node).set(&"enabled", false)
	# (the default since 27 Nov at his word; `-- --script` asks for the script: the detector translated to C++, native/traversal, where its library has been built)
	det = (ClassDB.instantiate(&"TravDetector") if (not ("--script" in OS.get_cmdline_user_args()) and ClassDB.class_exists(&"TravDetector")) else Detector.new())
	det.set(&"body", body)
	for s: Dictionary in stations:
		var kind := String(s["kind"])
		if kind in ["wall_thin", "wall_deep", "step", "kerb"]:
			await test_obstacle(s)
		elif kind == "gap":
			await test_gap(s)
		elif kind == "wall_roofed":
			await test_roofed(s)
	await test_open_ground()
	print("approaches: %d, with every record correct: %d; most physics queries in one measurement: %d" % [approaches, correct, most_queries])
	ok(approaches >= 100 and correct == approaches, "a hundred approaches give a hundred correct records (%d of %d)" % [correct, approaches])
	print("RESULT ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)


func test_obstacle(s: Dictionary) -> void:
	var x := float(s["x"])
	var top := float(s["top"])
	var depth := float(s["depth"])
	var face := Vector3(x, 0.0, -3.0)
	for deg: float in [0.0, 30.0]:
		for run: bool in [false, true]:
			var back := Vector3(sin(deg_to_rad(deg)), 0.0, cos(deg_to_rad(deg))) * 3.0
			var recs := await approach(face + back, face, run, 3.0 / (4.5 if run else 1.45) + 0.6)
			approaches += 1
			var bad := ""
			var seen := 0
			for r: Dictionary in recs:
				if r["kind"] != "obstacle":
					bad = "reported a %s" % r["kind"]
					break
				seen += 1
				if top > 3.0 + 0.001 or r["top"] == INF:
					if not (r["top"] == INF or bool(r["too_high"])):
						bad = "not reported too high"
					continue
				if absf(float(r["top"]) - top) > HEIGHT_WITHIN:
					bad = "height %.3f m" % float(r["top"])
				elif absf(float(r["depth"]) - depth) > DEPTH_WITHIN:
					bad = "depth %.3f m" % float(r["depth"])
				elif bool(r["thin"]) != (depth < 1.0):
					bad = "thin: %s" % str(r["thin"])
				elif bool(r["blocked"]):
					bad = "reported blocked"
				if bad != "":
					bad += " at %.2f m from the face" % float(r["face"])
					break
			if bad == "" and seen == 0:
				bad = "nothing reported"
			if bad == "":
				correct += 1
			ok(bad == "", "%s, %s, %s: %d records%s" % [s["label"], "straight on" if deg == 0.0 else "at 30 degrees", "run" if run else "walk", seen, "" if bad == "" else " -- " + bad])


func test_gap(s: Dictionary) -> void:
	var x := float(s["x"])
	var deck := float(s["top"])
	var w := float(s["gap"])
	var edge := Vector3(x, deck, float(s["edge_z"]))
	for deg: float in [0.0, 30.0]:
		for run: bool in [false, true]:
			# (2.2 m of run-up is what deck A allows at 30 degrees: it is 4 m long and 2.4 m wide)
			var back := Vector3(sin(deg_to_rad(deg)), 0.0, cos(deg_to_rad(deg))) * 2.2
			# stop short of the edge: he is not to walk off it
			var recs := await approach(edge + back, edge, run, 0.9 / (4.5 if run else 1.45) + 0.35)
			approaches += 1
			var bad := ""
			var seen := 0
			for r: Dictionary in recs:
				if r["kind"] != "gap":
					bad = "reported a %s" % r["kind"]
				elif absf(float(r["gap"]) - w) > DEPTH_WITHIN:
					bad = "gap %.3f m" % float(r["gap"])
				elif absf(float(r["drop"]) - deck) > HEIGHT_WITHIN:
					bad = "drop %.3f m" % float(r["drop"])
				elif bool(r["far_wall"]) or absf(float(r["landing"])) > HEIGHT_WITHIN:
					bad = "far side %s" % str(r.get("landing", "a wall"))
				seen += 1
				if bad != "":
					break
			if bad == "" and seen == 0:
				bad = "nothing reported"
			if bad == "":
				correct += 1
			ok(bad == "", "%s, %s, %s: %d records%s" % [s["label"], "straight on" if deg == 0.0 else "at 30 degrees", "run" if run else "walk", seen, "" if bad == "" else " -- " + bad])


func test_roofed(s: Dictionary) -> void:
	var face := Vector3(float(s["x"]), 0.0, -3.0)
	var recs := await approach(face + Vector3(0.0, 0.0, 3.0), face, false, 2.6)
	var bad := ""
	for r: Dictionary in recs:
		if r["kind"] != "obstacle" or not bool(r["blocked"]):
			bad = "not reported blocked"
		elif absf(float(r["top"]) - float(s["top"])) > HEIGHT_WITHIN:
			bad = "height %.3f m" % float(r["top"])
	if recs.is_empty():
		bad = "nothing reported"
	ok(bad == "", "%s: reported as blocked, at its own height (%d records)%s" % [s["label"], recs.size(), "" if bad == "" else " -- " + bad])


func test_open_ground() -> void:
	# the open ground on the near side of the course, walked and run across in four directions
	var n := 0
	for run: bool in [false, true]:
		for deg: float in [0.0, 90.0, 180.0, 270.0]:
			var way := Vector3(sin(deg_to_rad(deg)), 0.0, cos(deg_to_rad(deg)))
			var recs := await approach(Vector3(60.0, 0.0, 10.0), Vector3(60.0, 0.0, 10.0) + way * 5.0, run, 2.0)
			n += recs.size()
	ok(n == 0, "open ground: nothing reported (%d records)" % n)
