extends SceneTree
## Stage 4 test: the feet. The report's bars: a planted foot drifts less than about 2 cm; on stairs and on the 10 and
## 19 degree ramps no foot is inside its surface or floating above it by more than about 2 cm; knees never bend
## backward; on flat ground fitting the feet to the ground changes nothing.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_feet.gd

const WALK := 1.4
const RUN := 4.5

var fails := 0
var lab: Node3D
var body: CharacterBody3D
var tape: Node
var character: Node3D
var skel: Skeleton3D
var feet: RefCounted
var stations: Array
var toe_rest := 0.0


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("PASS  " if cond else "FAIL  ") + what)


func _initialize() -> void:
	_run.call_deferred()


func st(label: String) -> Dictionary:
	for s: Dictionary in stations:
		if s["label"] == label:
			return s
	push_error("no station " + label)
	return {}


func ground_under(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, p.y + 0.6, p.z), Vector3(p.x, p.y - 0.8, p.z), body.collision_mask, [body.get_rid()])
	var hit := body.get_world_3d().direct_space_state.intersect_ray(q)
	return (hit["position"] as Vector3).y if not hit.is_empty() else -1000.0


## Play `segments` from `at`; one record a tick: where the feet ended up and what the clip alone would have done.
func drive(at: Vector3, segments: Array) -> Array:
	lab.call(&"place", at)
	body.rotation.y = 0.0
	for i in 20:
		await physics_frame
	tape.call(&"make", segments)
	tape.call(&"replay")
	var rec: Array = []
	var foot_i: Array = feet.get(&"foot")
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		var s := skel.global_transform
		rec.append({
			"p": body.global_position, "v": (body.get(&"hvel") as Vector3).length(), "s": int(body.get(&"state")),
			"ball": (feet.get(&"final_ball") as Array).duplicate(), "ankle": (feet.get(&"final_ankle") as Array).duplicate(),
			"contact": (feet.get(&"contact") as Array).duplicate(), "knee": (feet.get(&"knee_side") as Array).duplicate(),
			"clip_ankle": [s * skel.get_bone_global_pose(foot_i[0]).origin, s * skel.get_bone_global_pose(foot_i[1]).origin],
			"hip": (feet.get(&"final_hip") as Array).duplicate(), "clip_h": (feet.get(&"clip_ball_h") as Array).duplicate(), "pelvis": float(feet.get(&"pelvis"))})
	return rec


## The furthest the ball of a foot moves along the ground during any one time it is planted.
func drift(rec: Array, from: int) -> Array:
	var worst := 0.0
	var plants := 0
	for f in 2:
		var start := -1
		for i in range(from, rec.size() + 1):
			var down: bool = i < rec.size() and bool(rec[i]["contact"][f])
			if down and start < 0:
				start = i
			elif not down and start >= 0:
				if i - start >= 4:
					var a: Vector3 = rec[start]["ball"][f]
					for j in range(start, i):
						var d: Vector3 = (rec[j]["ball"][f] as Vector3) - a
						worst = maxf(worst, Vector2(d.x, d.z).length())
					plants += 1
				start = -1
	return [worst, plants]


func test_flat() -> void:
	var c := Vector3(float(st("floor: one triangle mesh")["x"]), 0.1, -3.5)
	for run: bool in [false, true]:
		var secs := 2.4 if run else 6.0
		var rec := await drive(c, [[secs, 0.0, -1.0, 0.0, run]])
		var d := drift(rec, int(rec.size() * 0.45))
		ok(d[1] >= 2 and d[0] < 0.02, "flat, %s: over %d foot plants the ball of the foot drifts %.1f cm at most (bar 2 cm)" % ["run" if run else "walk", d[1], d[0] * 100.0])
	# fitting to the ground alone (planted feet not held) must leave the clip as it is on flat ground
	character.set(&"foot_pin", false)
	var rec := await drive(c, [[4.0, 0.0, -1.0, 0.0, false]])
	character.set(&"foot_pin", true)
	var off := 0.0
	for i in range(30, rec.size()):
		for f in 2:
			off = maxf(off, ((rec[i]["ankle"][f] as Vector3) - (rec[i]["clip_ankle"][f] as Vector3)).length())
	var low := 0.0
	for r: Dictionary in rec:
		low = minf(low, r["pelvis"])
	ok(off < 0.003, "flat, walk, feet fitted to the ground but not held: the ankles are where the clip puts them to within %.1f mm (bar 3 mm); hips moved %.1f mm" % [off * 1000.0, -low * 1000.0])


func slope(label: String, at: Vector3, secs: float, z_from: float, z_to: float, mz := -1.0, run := false) -> void:
	var rec := await drive(at, [[secs, 0.0, mz, 0.0, run]])
	var sunk := 0.0
	var floating := 0.0
	var knee := 99.0
	var low := 0.0
	var n := 0
	for i in range(6, rec.size() - 1):
		var r: Dictionary = rec[i]
		var z := (r["p"] as Vector3).z
		if z > z_from or z < z_to or r["s"] != 0:
			continue
		low = minf(low, r["pelvis"])
		for f in 2:
			knee = minf(knee, r["knee"][f])
			# settled: planted for the last tenth of a second and still planted on the next tick (a foot that is
			# just coming down or lifting is on its way, not standing)
			var settled: bool = rec[i + 1]["contact"][f]
			for k in 7:
				settled = settled and rec[i - k]["contact"][f]
			if not settled:
				continue
			n += 1
			var ball: Vector3 = r["ball"][f]
			var ankle: Vector3 = r["ankle"][f]
			# inside = below the ground that is under the ball itself; above = over the higher of the ground under
			# the ball and under the ankle (a foot may overhang the edge of a step), against where the clip holds
			# the ball above a flat floor
			var under := ground_under(ball)
			sunk = maxf(sunk, under - ball.y)
			floating = maxf(floating, (ball.y - maxf(under, ground_under(ankle))) - float(r["clip_h"][f]))
	ok(n > 12 and sunk < 0.02 and floating < 0.02 and knee > -0.005,
		"%s: over %d settled planted-foot ticks the ball of the foot is at most %.1f cm inside its surface and %.1f cm higher over it than the clip holds it over a flat floor (bar 2 cm); knees bend the right way (least %.1f cm); hips come down %.1f cm at most" %
		[label, n, sunk * 100.0, floating * 100.0, knee * 100.0, -low * 100.0])


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 3:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	character = lab.get(&"character")
	skel = character.get(&"skel")
	feet = character.get(&"feet")
	stations = (lab.get(&"course") as Node3D).get(&"stations")
	toe_rest = skel.get_bone_global_rest(skel.find_bone("mixamorig_LeftToeBase")).origin.y
	await test_flat()
	for label: String in ["stairs 0.18 / 0.28 m x 10", "stairs 0.25 / 0.26 m x 8"]:
		var s := st(label)
		var len := float(s["tread"]) * float(s["steps"])
		var tread := float(s["tread"])
		var top := Vector3(float(s["x"]), float(s["top"]), -3.0 - len - 1.0)
		await slope(label + ", up, walk", s["start"], 3.0 / WALK + float(s["steps"]) * 0.51 + 0.3, -3.0 - tread, -3.0 - len + tread)
		await slope(label + ", down, walk", top, 1.0 / WALK + float(s["steps"]) * 0.47 + 0.3, -3.0 - tread, -3.0 - len + tread, 1.0)
		await slope(label + ", up, run", s["start"], 3.0 / RUN + float(s["steps"]) * 0.26 + 0.5, -3.0 - tread, -3.0 - len + tread, -1.0, true)
	for deg: int in [10, 19]:
		var s := st("ramp %d deg" % deg)
		await slope("ramp %d deg, up, walk" % deg, (s["start"] as Vector3) + Vector3(0.0, 0.0, -1.5), (1.5 + float(s["run"])) / WALK, -3.3, -3.0 - float(s["run"]) + 0.3)
	print("RESULT " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
