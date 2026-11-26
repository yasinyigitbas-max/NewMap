extends SceneTree
## The study audit: what the build actually shows, measured on the final skeleton (after blending and IK), against
## the movement study's own numbers (reports/Hybrid character traversal study.md, Part 1). Yasin, 26 Nov: "MAKE DAMN
## SURE YOU TAKE THE STUDY INTO CONSIDERATION AT EVERY STEP". Every line names the study figure it is held to.
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/test_study.gd

var fails := 0
var lab: Node3D
var body: CharacterBody3D
var tape: Node
var character: Node3D
var skel: Skeleton3D
var bones := {}
var final := {}
var rest_foot_y := 0.0
var rest_toe_y := 0.0
var rest_ankle_angle := 0.0


func ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("PASS  " if cond else "FAIL  ") + what)


func within(v: float, lo: float, hi: float) -> bool:
	return v >= lo and v <= hi


func _initialize() -> void:
	_run.call_deferred()


func _after() -> void:
	var s := skel.global_transform
	for n: String in bones:
		final[n] = s * skel.get_bone_global_pose(bones[n])


## Play one segment from `at`; from `from_s` seconds on, one record a tick in the body's own frame
## (x = to his right, y = up, z = forward).
func record(at: Vector3, face: float, seg: Array, from_s: float) -> Array:
	lab.call(&"place", at)
	body.rotation.y = face
	for i in 30:
		await physics_frame
	tape.call(&"make", [seg])
	tape.call(&"replay")
	var rec := []
	var t := 0
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		await process_frame
		t += 1
		if t < int(from_s * 60.0) or final.is_empty():
			continue
		var b := body.global_transform
		var fwd := -b.basis.z
		var right := b.basis.x
		var row := {"speed": (body.get(&"hvel") as Vector3).length(), "pos": b.origin}
		for n: String in bones:
			var w: Vector3 = (final[n] as Transform3D).origin - b.origin
			row[n] = Vector3(w.dot(right), w.y, w.dot(fwd))
		var hb := (final["Hips"] as Transform3D).basis.orthonormalized()
		row["hips_basis"] = Basis(Vector3(hb.x.dot(right), hb.x.y, hb.x.dot(fwd)), Vector3(hb.y.dot(right), hb.y.y, hb.y.dot(fwd)), Vector3(hb.z.dot(right), hb.z.y, hb.z.dot(fwd)))
		rec.append(row)
	return rec


func rng(rec: Array, f: Callable) -> Vector2:
	var lo := 1e9
	var hi := -1e9
	for r: Dictionary in rec:
		var v: float = f.call(r)
		lo = minf(lo, v)
		hi = maxf(hi, v)
	return Vector2(lo, hi)


## Is this foot on the ground on this tick? Low, and not travelling over the ground.
func down(rec: Array, i: int, side: String) -> bool:
	var r: Dictionary = rec[i]
	var toe: Vector3 = r[side + "ToeBase"]
	var foot: Vector3 = r[side + "Foot"]
	var low := toe.y < rest_toe_y + 0.03 or foot.y < rest_foot_y + 0.03
	if i == 0 or not low:
		return low
	var p: Dictionary = rec[i - 1]
	var moved: Vector3 = (toe + Vector3(0, 0, 0)) - (p[side + "ToeBase"] as Vector3)
	var over_ground := Vector2(moved.x, moved.z + float(r["speed"]) / 60.0).length() * 60.0
	return over_ground < maxf(0.5, float(r["speed"]) * 0.4)


func knee_angle(r: Dictionary, side: String) -> float:
	var thigh: Vector3 = (r[side + "Leg"] as Vector3) - (r[side + "UpLeg"] as Vector3)
	var shin: Vector3 = (r[side + "Foot"] as Vector3) - (r[side + "Leg"] as Vector3)
	return rad_to_deg(thigh.angle_to(shin))


## The thigh's angle forward (+) or back (-) of straight down, seen from the side.
func hip_angle(r: Dictionary, side: String) -> float:
	var thigh: Vector3 = (r[side + "Leg"] as Vector3) - (r[side + "UpLeg"] as Vector3)
	return rad_to_deg(atan2(thigh.z, -thigh.y))


func elbow_angle(r: Dictionary, side: String) -> float:
	var upper: Vector3 = (r[side + "ForeArm"] as Vector3) - (r[side + "Arm"] as Vector3)
	var lower: Vector3 = (r[side + "Hand"] as Vector3) - (r[side + "ForeArm"] as Vector3)
	return rad_to_deg(upper.angle_to(lower))


func gait(label: String, run: bool) -> void:
	var rec := await record(Vector3(20.0, 0.0, 10.0), -PI * 0.5, [9.0 if not run else 5.0, 1.0, 0.0, 0.0, run], 3.0 if not run else 2.2)
	var speed: float = rec[rec.size() / 2]["speed"]
	# strides: from each time the left foot comes down to the next
	var starts: Array[int] = []
	var l_down := 0
	var r_down := 0
	var both := 0
	var none := 0
	for i in range(1, rec.size()):
		var l := down(rec, i, "Left")
		var r := down(rec, i, "Right")
		if l and not down(rec, i - 1, "Left"):
			starts.append(i)
	if starts.size() < 3:
		ok(false, "%s: fewer than two whole strides seen" % label)
		return
	var a := starts[0]
	var b := starts[starts.size() - 1]
	var n := b - a
	for i in range(a, b):
		var l := down(rec, i, "Left")
		var r := down(rec, i, "Right")
		l_down += 1 if l else 0
		r_down += 1 if r else 0
		both += 1 if (l and r) else 0
		none += 1 if not (l or r) else 0
	var stride_t := float(n) / 60.0 / float(starts.size() - 1)
	var cadence := 120.0 / stride_t
	var stride := speed * stride_t
	var duty := 100.0 * float(l_down + r_down) * 0.5 / n
	var win := rec.slice(a, b)
	var bob := rng(win, func(r: Dictionary) -> float: return (r["Hips"] as Vector3).y)
	var sway := rng(win, func(r: Dictionary) -> float: return (r["Hips"] as Vector3).x)
	var knee := rng(win, func(r: Dictionary) -> float: return knee_angle(r, "Left"))
	var hip := rng(win, func(r: Dictionary) -> float: return hip_angle(r, "Left"))
	var width := 0.0
	var elbow := 0.0
	var loading := 0.0
	var opposite := 0.0
	for i in range(a, b):
		var r: Dictionary = rec[i]
		width += absf((r["LeftFoot"] as Vector3).x - (r["RightFoot"] as Vector3).x)
		elbow += elbow_angle(r, "Left")
		# arm against leg: the left hand is forward when the right foot is
		opposite += signf((r["LeftHand"] as Vector3).z - (r["RightHand"] as Vector3).z) * signf((r["RightFoot"] as Vector3).z - (r["LeftFoot"] as Vector3).z)
	width /= n
	elbow /= n
	opposite /= n
	# the knee's bend as weight lands: its peak in the first fifth of the stride after the left foot comes down
	for s in starts.slice(0, starts.size() - 1):
		var peak := 0.0
		for i in range(s, mini(s + int(stride_t * 60.0 * 0.2), rec.size())):
			peak = maxf(peak, knee_angle(rec[i], "Left"))
		loading += peak / float(starts.size() - 1)
	var hb := rng(win, func(r: Dictionary) -> float: return rad_to_deg(atan2(-(r["hips_basis"] as Basis).x.z, -(r["hips_basis"] as Basis).x.x)))
	var drop := rng(win, func(r: Dictionary) -> float: return rad_to_deg(asin(clampf((r["hips_basis"] as Basis).x.y, -1.0, 1.0))))
	print("--- %s at %.2f m/s (measured over %d strides)" % [label, speed, starts.size() - 1])
	if not run:
		ok(within(speed, 1.27, 1.46), "speed %.2f m/s (study: comfortable walking 1.27 to 1.46)" % speed)
		ok(within(cadence, 108.0, 125.0), "%.0f steps a minute (study: 115 to 120)" % cadence)
		ok(within(stride, 1.35, 1.75), "stride %.2f m (study: 1.5 to 1.7 m; at this speed and 115 to 120 steps a minute it works out at 1.40 to 1.46)" % stride)
		ok(within(duty, 55.0, 66.0), "each foot on the ground %.0f %% of the stride (study: about 60 to 62)" % duty)
		ok(within(100.0 * both / n * 0.5, 6.0, 16.0) and none == 0, "both feet down %.0f %% of the stride, twice a stride (study: 10 to 12 each); never both in the air (%d ticks)" % [100.0 * both / n * 0.5, none])
		ok(within((bob.y - bob.x) * 100.0, 2.0, 5.5), "the hips rise and fall %.1f cm (study: 2.7 to 4.8)" % ((bob.y - bob.x) * 100.0))
		ok(within((sway.y - sway.x) * 100.0, 3.0, 8.0), "the hips sway %.1f cm side to side (study: 7.0 down to 3.9 as speed rises)" % ((sway.y - sway.x) * 100.0))
		ok(within(hip.y, 18.0, 33.0) and within(-hip.x, 5.0, 20.0), "thigh swings %.0f deg forward and %.0f back (study: hip 25 of flexion to 10 of extension)" % [hip.y, -hip.x])
		ok(within(knee.y, 50.0, 72.0), "knee peaks at %.0f deg in swing (study: 60; well short of it reads as stiff)" % knee.y)
		ok(within(loading, 10.0, 30.0), "knee bends %.0f deg as weight lands (study: about 20)" % loading)
		ok(within(hb.y - hb.x, 5.0, 18.0), "pelvis turns %.0f deg in all (study: 12)" % (hb.y - hb.x))
		ok(within(drop.y - drop.x, 3.0, 13.0), "pelvis drops side to side %.1f deg in all (study: 8.5)" % (drop.y - drop.x))
		# (the study gives no angle for "mostly straight"; the bar is half the bend measured in his run)
		ok(elbow < 60.0, "elbows bent %.0f deg on average (study: arms stay mostly straight in walking, bent in running)" % elbow)
		ok(within(width, 0.06, 0.13), "feet %.2f m apart sideways (study: 0.08 to 0.10)" % width)
	else:
		ok(within(speed, 2.5, 4.6), "speed %.2f m/s (study: runners measured at 2.5 to 4.5)" % speed)
		ok(within(stride, 2.6, 3.3), "stride %.2f m (study: 2.96 m at 4.5 m/s)" % stride)
		ok(within(duty, 22.0, 40.0), "each foot on the ground %.0f %% of the stride (study: 31)" % duty)
		ok(none > 0 and both == 0, "a flight phase: both feet in the air %.0f %% of the stride, never both down (%d ticks)" % [100.0 * none / n, both])
		ok(within((bob.y - bob.x) * 100.0, 6.0, 11.0), "the hips rise and fall %.1f cm (study: 8 to 9.5)" % ((bob.y - bob.x) * 100.0))
		ok(within(knee.y, 88.0, 125.0), "knee peaks at %.0f deg in swing (study: 94 to 119)" % knee.y)
		ok(within(hip.y, 40.0, 68.0), "thigh swings %.0f deg forward (study: hip flexion 44 to 61 between 2.5 and 4.5 m/s)" % hip.y)
		ok(elbow > 50.0, "elbows bent %.0f deg on average (study: arms bent in running)" % elbow)
		ok(within(width, 0.02, 0.13), "feet %.2f m apart sideways (study gives walking only: 0.08 to 0.10)" % width)
	ok(opposite > 0.5, "each arm swings with the opposite leg (%.0f %% of the time; study: always)" % (50.0 + opposite * 50.0))


func idle() -> void:
	var rec := await record(Vector3(40.0, 0.0, 10.0), 0.0, [14.0, 0.0, 0.0, 0.0, false], 2.0)
	# the body's weight point is not measured here; the hips' path over the ground stands in for it
	var turns := 0
	var last := Vector2.ZERO
	var path := 0.0
	for i in range(1, rec.size()):
		var d := Vector2((rec[i]["Hips"] as Vector3).x - (rec[i - 1]["Hips"] as Vector3).x, (rec[i]["Hips"] as Vector3).z - (rec[i - 1]["Hips"] as Vector3).z)
		path += d.length()
		if d.length() > 0.00002:
			if last != Vector2.ZERO and d.dot(last) < 0.0:
				turns += 1
			last = d
	var secs := rec.size() / 60.0
	var sx := rng(rec, func(r: Dictionary) -> float: return (r["Hips"] as Vector3).x)
	var sz := rng(rec, func(r: Dictionary) -> float: return (r["Hips"] as Vector3).z)
	print("--- standing still for %.0f s" % secs)
	ok(path > 0.02, "never still: the hips wander %.1f cm over the ground in %.0f s, within %.1f by %.1f cm (study: quiet standing is never still)" % [path * 100.0, secs, (sx.y - sx.x) * 100.0, (sz.y - sz.x) * 100.0])
	ok(within(secs / maxf(turns, 1), 0.1, 3.2), "the drift changes direction every %.1f s (study: the pressure point under the feet about every 0.2 s, sway about 0.33 Hz = once in 3 s)" % (secs / maxf(turns, 1)))


func _run() -> void:
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 3:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	character = lab.get(&"character")
	skel = character.get(&"skel")
	for n: String in ["Hips", "Head", "LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase", "RightUpLeg", "RightLeg", "RightFoot", "RightToeBase", "LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand"]:
		bones[n] = skel.find_bone("mixamorig_" + n)
	rest_foot_y = skel.get_bone_global_rest(bones["LeftFoot"]).origin.y
	rest_toe_y = skel.get_bone_global_rest(bones["LeftToeBase"]).origin.y
	skel.skeleton_updated.connect(_after)
	await gait("walk", false)
	await gait("run", true)
	await idle()
	print("RESULT " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
