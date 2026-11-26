extends SceneTree
## THE STUDY AUDIT. What the build really shows, measured on the finished skeleton (after blending and IK) and on the
## body, against the movement study's own words. Every pass bar comes from res://study/bars.json, where each bar is a
## word-for-word quote of the study (tools/traversal/check_study.py proves it). There is NO pass bar in this file.
##
## LOCKED (Yasin, 26 Nov 2026: "OTHER SESSION INVENTED NEW CHECKS TO MAKE ITS TESTS PASS IN THE MIDDLE OF THE WORK AND
## EVERYTHING BROKE DOWN! MAKE SURE IT DOESNT HAPPEN THIS TIME!"). This file and bars.json change only at his word;
## the commit gate refuses anything else. If a line fails, fix the movement, not the line.
##
## What this file does define, because a measurement needs it (they are how things are measured, not how good they
## must be; each is marked OURS where it is used): when a foot counts as down, when it counts as resting, when a
## turn has begun.
##
## Run:  godot --headless --fixed-fps 60 --path traversal_lab -s res://tests/audit.gd
## It writes res://study/audit_result.json, stamped with a hash of the audited files; the commit gate reads it.

const BARS := "res://study/bars.json"
const RESULT := "res://study/audit_result.json"
const TICK := 1.0 / 60.0
const SIDES := ["Left", "Right"]
const NAMES := ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head",
		"LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase", "LeftToe_End",
		"RightUpLeg", "RightLeg", "RightFoot", "RightToeBase", "RightToe_End",
		"LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand"]
# OURS (measurement definitions, the same as the audit of 26 Nov used):
const LOW := 0.03               # a foot within this of its standing height above its surface is "low" (m)
const SLOW_SHARE := 0.4         # and "not travelling" while its ball moves over the ground slower than this share
const SLOW_LEAST := 0.5         # of the body's speed, or than this (m/s)
const RESTING := 0.10           # a foot whose ball and ankle both move slower than this is "resting" (m/s)
const STEP_LEAST := 0.05        # a foot has taken a step when it comes down this far from where it left the ground (m)
const BEGUN_DEG := 3.0          # a part has "started turning" once it is this far from where it was (deg)
const STEADY_SHARE := 0.99      # "steady speed" = this share of the walking speed (named in bars.json as ours)

var data := {}
var pct := 10.0
var bars := {}
var reported := {}
var measured := {}
var fails: Array[String] = []
var outside_off: Array[String] = []
var lab: Node3D
var body: CharacterBody3D
var tape: Node
var character: Node3D
var skel: Skeleton3D
var stations: Array = []
var bone := {}
var rest := {}                  # bone -> its orientation, standing, in the body's own axes
var final := {}                 # bone -> world transform after the skeleton was solved this tick
var toe_stand := 0.0            # the ball joint's height above the ground, standing
var ankle_stand := 0.0
var ankle_zero := 0.0           # the angle from shin to foot, standing
var toe_zero := [0.0, 0.0]
var limit_worst := {}           # limit id -> [value, scene]
var scene := ""
var flat := {}                  # what the flat walk showed, for the comparisons on slopes


# ------------------------------------------------------------------------------------------------ reporting

func bounds(b: Dictionary) -> Array:
	var k: String = b["kind"]
	match k:
		"range":
			return [float(b["lo"]), float(b["hi"])]
		"single":
			return [float(b["value"]) * (1.0 - pct / 100.0), float(b["value"]) * (1.0 + pct / 100.0)]
		"spread":
			var sd := float(b["sd"]) * float(b.get("sd_scale", 1.0))
			return [float(b["value"]) - sd, float(b["value"]) + sd]
		"max":
			return [-INF, float(b["value"])]
		"min":
			return [float(b["value"]), INF]
		"under":
			return [-INF, float(b["value"])]
		"ratio":
			var v := float(b["num"]) / float(b["den"])
			return [v * (1.0 - pct / 100.0), v * (1.0 + pct / 100.0)]
		"sum_range":
			var lo := 0.0
			var hi := 0.0
			for x: String in b["los"]:
				lo += float(x)
			for x: String in b["his"]:
				hi += float(x)
			return [lo, hi]
		"always":
			return [100.0 - pct, 100.0]
	return [-INF, INF]


func _range_text(b: Dictionary) -> String:
	var r := bounds(b)
	if b["kind"] == "under":
		return "under %s" % _num(r[1])
	if r[0] == -INF:
		return "at most %s" % _num(r[1])
	if r[1] == INF:
		return "at least %s" % _num(r[0])
	return "%s to %s" % [_num(r[0]), _num(r[1])]


func _num(v: float) -> String:
	var s := "%.3f" % v
	while s.contains(".") and (s.ends_with("0") or s.ends_with(".")):
		s = s.substr(0, s.length() - 1)
	return s


func _line(id: String, verdict: String, text: String) -> void:
	if reported.has(id):
		push_error("audit line reported twice: " + id)
	reported[id] = verdict
	if verdict == "FAIL":
		fails.append(id)
	print("%-9s %-24s %s" % [verdict, id, text])


## A measured number against its bar.
func bar(id: String, v: float, extra := "") -> void:
	var b: Dictionary = bars[id]
	var r := bounds(b)
	var good := v >= float(r[0]) and v <= float(r[1])
	if b["kind"] == "under":
		good = v < float(r[1])
	if is_nan(v):
		good = false
	measured[id] = v
	_line(id, "PASS" if good else "FAIL", "%s %s  [study: %s]  %s%s" % [_num(v), b.get("unit", ""), _range_text(b), b["what"], ("  (" + extra + ")") if extra != "" else ""])


## A statement of the study that is true or not.
func flag(id: String, cond: bool, extra := "") -> void:
	var b: Dictionary = bars[id]
	measured[id] = 1.0 if cond else 0.0
	_line(id, "PASS" if cond else "FAIL", "%s%s" % [b["what"], ("  (" + extra + ")") if extra != "" else ""])


func info(id: String, text: String) -> void:
	_line(id, "INFO", "%s  %s" % [bars[id]["what"], text])


## A line the scenario could not measure at all (it never happened): a failure, said plainly.
func missing(id: String, why: String) -> void:
	measured[id] = NAN
	_line(id, "FAIL", "COULD NOT BE MEASURED: %s  [%s]" % [why, bars[id]["what"]])


## Kept at Yasin's word, not covered by the study: against our own figure, listed apart, not in the RESULT.
func outside(id: String, v: float, extra := "") -> void:
	for l: Dictionary in data["outside"]["lines"]:
		if l["id"] == id:
			var good := v <= float(l["ours"])
			if not good:
				outside_off.append(id)
			measured[id] = v
			print("%-9s %-24s %s %s  [ours: at most %s]  %s%s" % ["ok" if good else "OFF", id, _num(v), l["unit"], _num(float(l["ours"])), l["what"], ("  (" + extra + ")") if extra != "" else ""])
			return
	push_error("no outside line " + id)


# ------------------------------------------------------------------------------------------------ set-up

func _initialize() -> void:
	_run.call_deferred()


func _after() -> void:
	var s := skel.global_transform
	for n: String in bone:
		final[n] = s * skel.get_bone_global_pose(bone[n])


func st(label: String) -> Dictionary:
	for s: Dictionary in stations:
		if s["label"] == label:
			return s
	push_error("no station " + label)
	return {}


func seg(seconds: float, mx: float, mz: float, yaw_deg := 0.0, run := false, jump := false) -> Array:
	var out := []
	for i in int(round(seconds * 60.0)):
		out.append({"mx": mx, "mz": mz, "yaw": deg_to_rad(yaw_deg), "run": run, "jump": jump, "crouch": false, "act": false})
	return out


func _ortho(b: Basis) -> Basis:
	return b.orthonormalized()


func _ground(p: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0.0, 0.6, 0.0), p - Vector3(0.0, 1.2, 0.0), body.collision_mask, [body.get_rid()])
	return body.get_world_3d().direct_space_state.intersect_ray(q)


## How far a point stands off the surface under it (along the surface's own normal); 99 if there is none.
func _height(p: Vector3) -> float:
	var hit := _ground(p)
	if hit.is_empty():
		return 99.0
	return (p - (hit["position"] as Vector3)).dot(hit["normal"])


## Play a tape from `at`, facing `face`; one record a tick.
func play(label: String, at: Vector3, face: float, samples: Array, until := Callable()) -> Array:
	scene = label
	# whatever the last scenario left him doing is over before this one starts
	tape.call(&"stop")
	tape.set(&"tape", seg(1.0, 0.0, 0.0))
	tape.call(&"replay")
	while int(tape.get(&"mode")) == 2:
		await physics_frame
	lab.call(&"place", at)
	body.rotation.y = face
	for i in 45:
		await physics_frame
		await process_frame
	tape.set(&"tape", samples)
	tape.call(&"replay")
	var rec := []
	var i := 0
	while int(tape.get(&"mode")) == 2:
		await physics_frame
		await process_frame
		if final.is_empty():
			continue
		var s: Dictionary = samples[mini(i, samples.size() - 1)]
		i += 1
		rec.append(_record(s))
		if until.is_valid() and until.call(body.global_position):
			tape.call(&"stop")
	_feet_marks(rec)
	_limits(rec)
	return rec


func _record(sample: Dictionary) -> Dictionary:
	var bb := _ortho(body.global_transform.basis)
	var inv := bb.inverse()
	var r := {"pos": body.global_position, "yaw": body.rotation.y, "v": (body.get(&"hvel") as Vector3).length(),
			"air": int(body.get(&"state")) >= 2, "stick": Vector2(float(sample["mx"]), float(sample["mz"])).length() > 0.05,
			"jump": bool(sample["jump"]), "landing": String(character.get(&"landing_kind")) if character.get(&"landing_kind") != null else "?"}
	var p := {}
	var d := {}
	for n: String in bone:
		var t: Transform3D = final[n]
		p[n] = t.origin
		if rest.has(n):
			d[n] = inv * _ortho(t.basis) * (rest[n] as Basis).inverse()
	r["p"] = p
	r["d"] = d
	r["inv"] = inv
	for f in 2:
		var side: String = SIDES[f]
		var ball: Vector3 = p[side + "ToeBase"]
		var ankle: Vector3 = p[side + "Foot"]
		# how far the foot is off its surface: the ball of the foot or the heel, whichever is nearer to it
		var eb := _height(ball) - toe_stand
		var ea := _height(ankle) - ankle_stand
		r["clear%d" % f] = minf(eb, ea)
		r["inside%d" % f] = maxf(maxf(-eb, -ea), 0.0)
	return r


## Mark, on every tick, which feet are down (low and not travelling) and which are resting (not moving at all).
func _feet_marks(rec: Array) -> void:
	for i in rec.size():
		var r: Dictionary = rec[i]
		for f in 2:
			var side: String = SIDES[f]
			var ball_v := 0.0
			var ankle_v := 0.0
			var over := 0.0
			if i > 0:
				var q: Dictionary = rec[i - 1]
				var db: Vector3 = (r["p"][side + "ToeBase"] as Vector3) - (q["p"][side + "ToeBase"] as Vector3)
				ball_v = db.length() * 60.0
				over = Vector2(db.x, db.z).length() * 60.0
				ankle_v = ((r["p"][side + "Foot"] as Vector3) - (q["p"][side + "Foot"] as Vector3)).length() * 60.0
			var low := float(r["clear%d" % f]) < LOW
			r["down%d" % f] = low and over < maxf(SLOW_LEAST, float(r["v"]) * SLOW_SHARE) and not bool(r["air"])
			r["rest%d" % f] = i > 0 and ball_v < RESTING and ankle_v < RESTING and not bool(r["air"])


# ------------------------------------------------------------------------------------------------ angles
# All in degrees. The body's own axes: x = to his right, y = up, z = behind him.

func _dir(r: Dictionary, a: String, b: String) -> Vector3:
	return (r["inv"] as Basis) * ((r["p"][b] as Vector3) - (r["p"][a] as Vector3)).normalized()


## A hinge's bend in its own plane: + = the way it bends, - = past straight. `front` = the way the far bone swings
## when the joint bends, in the near bone's own frame.
func _hinge(near: Vector3, far: Vector3, front: Vector3) -> float:
	var f := (front - near * front.dot(near)).normalized()
	var whole := rad_to_deg(near.angle_to(far))
	var in_plane := rad_to_deg(atan2(far.dot(f), far.dot(near)))
	if in_plane >= 0.0:
		return whole
	# past straight: only what lies in the hinge's plane counts (a sideways wobble is not a back-bend)
	return in_plane if (whole < 15.0 or absf(in_plane) > 0.7 * whole) else whole


func knee(r: Dictionary, side: String) -> float:
	return _hinge(_dir(r, side + "UpLeg", side + "Leg"), _dir(r, side + "Leg", side + "Foot"), (r["d"][side + "UpLeg"] as Basis) * Vector3(0.0, 0.0, 1.0))


func elbow(r: Dictionary, side: String) -> float:
	return _hinge(_dir(r, side + "Arm", side + "ForeArm"), _dir(r, side + "ForeArm", side + "Hand"), (r["d"][side + "Arm"] as Basis) * Vector3(0.0, 0.0, -1.0))


## The thigh against the pelvis: x = flexion (+ forward, - = extension), y = out to the side (+) or across (-).
func hip(r: Dictionary, side: String) -> Vector2:
	var v: Vector3 = (r["d"]["Hips"] as Basis).inverse() * _dir(r, side + "UpLeg", side + "Leg")
	var out := -v.x if side == "Left" else v.x
	return Vector2(rad_to_deg(atan2(-v.z, -v.y)), rad_to_deg(asin(clampf(out, -1.0, 1.0))))


## The ankle: + = toes up, - = toes down, from standing.
func ankle(r: Dictionary, side: String) -> float:
	return rad_to_deg(_dir(r, side + "Leg", side + "Foot").angle_to(_dir(r, side + "Foot", side + "ToeBase"))) - ankle_zero


## The big toe: + = bent up, from standing.
func toe(r: Dictionary, f: int) -> float:
	var side: String = SIDES[f]
	if not bone.has(side + "Toe_End"):
		return NAN
	return ankle_zero_toe(r, side) - float(toe_zero[f])


func ankle_zero_toe(r: Dictionary, side: String) -> float:
	# the toe's line against the foot's line, measured as a rise: the foot's own frame carries "up"
	var foot_d: Basis = r["d"][side + "Foot"]
	var t: Vector3 = foot_d.inverse() * _dir(r, side + "ToeBase", side + "Toe_End")
	return rad_to_deg(atan2(t.y, Vector2(t.x, t.z).length()))


func _twist(b: Basis) -> float:
	var q := b.get_rotation_quaternion()
	return wrapf(2.0 * atan2(q.y, q.w), -PI, PI)


## One part against another (or against his heading when `parent` is ""): x = forward bend (+) or back (-),
## y = to the side (always +), z = turn (+ = to his left).
func bend(r: Dictionary, parent: String, child: String) -> Vector3:
	var j: Basis = r["d"][child]
	if parent != "":
		j = (r["d"][parent] as Basis).inverse() * j
	var turn := _twist(j)
	var swing := j * Basis(Vector3.UP, -turn)
	var up := swing * Vector3.UP
	return Vector3(rad_to_deg(atan2(-up.z, up.y)), rad_to_deg(atan2(absf(up.x), up.y)), rad_to_deg(turn))


## The same with the side kept signed: + = his right side down.
func side_drop(r: Dictionary, n: String) -> float:
	var j: Basis = r["d"][n]
	var up := (j * Basis(Vector3.UP, -_twist(j))) * Vector3.UP
	return rad_to_deg(atan2(up.x, up.y))


func world_yaw(r: Dictionary, n: String) -> float:
	return float(r["yaw"]) + _twist(r["d"][n])


func trunk_lean(r: Dictionary) -> float:
	# the line from the hips to the chest against upright, + = forward
	var v := _dir(r, "Hips", "Spine2")
	return rad_to_deg(atan2(-v.z, v.y))


## Joint limits, every tick of every scenario.
func _limits(rec: Array) -> void:
	for r: Dictionary in rec:
		for side: String in SIDES:
			var k := knee(r, side)
			_worst("limit.knee_back", -k)
			_worst("limit.knee_bend", k)
			var e := elbow(r, side)
			_worst("limit.elbow_back", -e)
			_worst("limit.elbow_bend", e)
			var h := hip(r, side)
			_worst("limit.hip_flex", h.x)
			_worst("limit.hip_ext", -h.x)
			_worst("limit.hip_spread", h.y)
			_worst("limit.hip_cross", -h.y)
			var a := ankle(r, side)
			_worst("limit.ankle_down", -a)
			_worst("limit.ankle_up", a)
			var chest_down := (r["d"]["Spine2"] as Basis) * Vector3.DOWN
			_worst("limit.shoulder", rad_to_deg(_dir(r, side + "Arm", side + "ForeArm").angle_to(chest_down)))
		for part: Array in [["neck", "Spine2", "Head"], ["mid", "Spine", "Spine2"], ["low", "Hips", "Spine"]]:
			var b := bend(r, part[1], part[2])
			_worst("limit.%s_fwd" % part[0], b.x)
			_worst("limit.%s_back" % part[0], -b.x)
			_worst("limit.%s_side" % part[0], b.y)
			_worst("limit.%s_turn" % part[0], absf(b.z))


func _worst(id: String, v: float) -> void:
	if not limit_worst.has(id) or v > float(limit_worst[id][0]):
		limit_worst[id] = [v, scene]


# ------------------------------------------------------------------------------------------------ gait

func _peak(rec: Array, a: int, b: int, f: Callable) -> float:
	var hi := -INF
	for i in range(a, b):
		hi = maxf(hi, f.call(rec[i]))
	return hi


func _low(rec: Array, a: int, b: int, f: Callable) -> float:
	var lo := INF
	for i in range(a, b):
		lo = minf(lo, f.call(rec[i]))
	return lo


func _mean(rec: Array, a: int, b: int, f: Callable) -> float:
	var s := 0.0
	for i in range(a, b):
		s += f.call(rec[i])
	return s / maxf(b - a, 1)


## The ticks on which foot `f` lands from a step: it left the ground, and comes down somewhere else (a foot that
## only flickers off the ground and back, or slides along it, has not stepped), from tick `from`.
func landings(rec: Array, f: int, from := 1, to := -1) -> Array[int]:
	var out: Array[int] = []
	var side: String = SIDES[f]
	var left_at := Vector3.INF
	var lifted := false
	for i in range(1, rec.size() if to < 0 else to):
		var now := bool(rec[i]["down%d" % f])
		var was := bool(rec[i - 1]["down%d" % f])
		if was and not now and left_at == Vector3.INF:
			left_at = rec[i - 1]["p"][side + "ToeBase"]
			lifted = false
		if not now and float(rec[i]["clear%d" % f]) >= LOW:
			lifted = true          # it really left the ground: a foot that slides along it has not stepped
		elif now and not was and left_at != Vector3.INF:
			var d: Vector3 = (rec[i]["p"][side + "ToeBase"] as Vector3) - left_at
			if lifted and (Vector2(d.x, d.z).length() >= STEP_LEAST or absf(d.y) >= STEP_LEAST):
				left_at = Vector3.INF
				if i >= from:
					out.append(i)
	return out


## Every landing of either foot, in order, as [tick, foot].
func steps(rec: Array, from := 1, to := -1) -> Array:
	var out := []
	for f in 2:
		for t in landings(rec, f, from, to):
			out.append([t, f])
	out.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	return out


## The furthest the ball of a planted foot moves over the ground from where it came down (cm), ticks a..b.
func drift(rec: Array, a: int, b: int) -> float:
	var worst := 0.0
	for f in 2:
		var side: String = SIDES[f]
		var at := Vector3.ZERO
		var on := false
		for i in range(a, b):
			var ball: Vector3 = rec[i]["p"][side + "ToeBase"]
			if bool(rec[i]["down%d" % f]):
				if not on:
					on = true
					at = ball
				worst = maxf(worst, Vector2(ball.x - at.x, ball.z - at.z).length())
			else:
				on = false
	return worst * 100.0


## The worst foot fault over ticks a..b (cm): a foot inside its surface (any foot, any tick), a resting foot held
## above it, and - when `walking` - no foot on the surface at all. Returns [worst, inside, resting above, none on].
func foot_fault(rec: Array, a: int, b: int, walking: bool) -> Array:
	var inside := 0.0
	var above := 0.0
	var none := 0.0
	for i in range(a, b):
		var r: Dictionary = rec[i]
		if bool(r["air"]):
			continue
		for f in 2:
			inside = maxf(inside, float(r["inside%d" % f]))
			if bool(r["rest%d" % f]) and float(r["clear%d" % f]) < 90.0:
				above = maxf(above, float(r["clear%d" % f]))
		if walking:
			var lowest := minf(float(r["clear0"]), float(r["clear1"]))
			if lowest < 90.0:
				none = maxf(none, lowest)
	return [maxf(inside, maxf(above, none)) * 100.0, inside * 100.0, above * 100.0, none * 100.0]


func _fault_text(x: Array) -> String:
	return "inside %.1f cm, a resting foot above %.1f cm, no foot on it %.1f cm" % [x[1], x[2], x[3]]


## Steady gait over whole strides after tick `from`. Returns {} if fewer than two strides are seen.
func gait(rec: Array, from: int, least_strides := 2) -> Dictionary:
	var starts := landings(rec, 0, from)
	if starts.size() < least_strides + 1:
		return {}
	var a := starts[0]
	var b := starts[starts.size() - 1]
	var n := b - a
	var strides := starts.size() - 1
	var g := {"a": a, "b": b, "strides": strides}
	var down := [0, 0]
	var both := 0
	var none := 0
	for i in range(a, b):
		var l := bool(rec[i]["down0"])
		var r := bool(rec[i]["down1"])
		down[0] += 1 if l else 0
		down[1] += 1 if r else 0
		both += 1 if (l and r) else 0
		none += 1 if not (l or r) else 0
	g["speed"] = _mean(rec, a, b, func(r: Dictionary) -> float: return r["v"])
	var stride_t := float(n) / 60.0 / strides
	g["stride_t"] = stride_t
	g["cadence"] = 120.0 / stride_t
	g["stride"] = float(g["speed"]) * stride_t
	g["stance"] = 100.0 * (down[0] + down[1]) * 0.5 / n
	g["double"] = 100.0 * both * 0.5 / n
	g["none"] = none
	g["both"] = both
	g["flight"] = none >= strides          # OURS: a flight phase = at least one tick a stride with both feet off
	g["bob"] = 100.0 * (_peak(rec, a, b, func(r: Dictionary) -> float: return (r["p"]["Hips"] as Vector3).y - (r["pos"] as Vector3).y) - _low(rec, a, b, func(r: Dictionary) -> float: return (r["p"]["Hips"] as Vector3).y - (r["pos"] as Vector3).y))
	var side_of := func(r: Dictionary) -> float: return ((r["inv"] as Basis) * ((r["p"]["Hips"] as Vector3) - (r["pos"] as Vector3))).x
	g["sway"] = 100.0 * (_peak(rec, a, b, side_of) - _low(rec, a, b, side_of))
	for part: Array in [["pelvis_tilt", 0], ["pelvis_turn", 2]]:
		var idx: int = part[1]
		g[part[0]] = _peak(rec, a, b, func(r: Dictionary) -> float: return bend(r, "", "Hips")[idx]) - _low(rec, a, b, func(r: Dictionary) -> float: return bend(r, "", "Hips")[idx])
	g["pelvis_drop"] = _peak(rec, a, b, func(r: Dictionary) -> float: return side_drop(r, "Hips")) - _low(rec, a, b, func(r: Dictionary) -> float: return side_drop(r, "Hips"))
	# joints: each side's own peak, the two sides averaged
	for key: String in ["hip_flex", "hip_ext", "knee_swing", "ankle_up", "ankle_down", "toe", "knee_load", "knee_toeoff", "knee_mid", "elbow"]:
		g[key] = 0.0
	g["width"] = _mean(rec, a, b, func(r: Dictionary) -> float: return absf(((r["inv"] as Basis) * ((r["p"]["LeftFoot"] as Vector3) - (r["p"]["RightFoot"] as Vector3))).x))
	g["trunk"] = _mean(rec, a, b, trunk_lean)
	var contact_hip := 0.0
	var contact_knee := 0.0
	var contacts := 0
	for f in 2:
		var side: String = SIDES[f]
		g["hip_flex"] += 0.5 * _peak(rec, a, b, func(r: Dictionary) -> float: return hip(r, side).x)
		g["hip_ext"] += 0.5 * -_low(rec, a, b, func(r: Dictionary) -> float: return hip(r, side).x)
		g["knee_swing"] += 0.5 * _peak(rec, a, b, func(r: Dictionary) -> float: return knee(r, side))
		g["ankle_up"] += 0.5 * _peak(rec, a, b, func(r: Dictionary) -> float: return ankle(r, side))
		g["ankle_down"] += 0.5 * -_low(rec, a, b, func(r: Dictionary) -> float: return ankle(r, side))
		g["elbow"] += 0.5 * _mean(rec, a, b, func(r: Dictionary) -> float: return elbow(r, side))
		var toe_up := -INF
		for i in range(a, b):
			if bool(rec[i]["down%d" % f]):
				toe_up = maxf(toe_up, toe(rec[i], f))
		g["toe"] += 0.5 * toe_up
		# as weight lands: the knee's peak in the first fifth of the stride after this foot comes down; at toe-off:
		# on the tick the foot stops being down; mid-stance: its least bend between the two
		var lands := landings(rec, f, a, b)
		var load := 0.0
		var off := 0.0
		var mid := 0.0
		var count := 0
		for s in lands:
			var fifth := mini(s + int(stride_t * 60.0 * 0.2), rec.size())
			var lift := s
			while lift < rec.size() - 1 and bool(rec[lift]["down%d" % f]):
				lift += 1
			if lift >= rec.size() - 1 or lift <= fifth:
				continue
			load += _peak(rec, s, fifth, func(r: Dictionary) -> float: return knee(r, side))
			off += knee(rec[lift], side)
			mid += _low(rec, fifth, lift, func(r: Dictionary) -> float: return knee(r, side))
			count += 1
			contact_hip += hip(rec[s], side).x
			contact_knee += knee(rec[s], side)
			contacts += 1
		if count > 0:
			g["knee_load"] += 0.5 * load / count
			g["knee_toeoff"] += 0.5 * off / count
			g["knee_mid"] += 0.5 * mid / count
	g["contact_hip"] = contact_hip / maxf(contacts, 1)
	g["contact_knee"] = contact_knee / maxf(contacts, 1)
	# each arm forward while the opposite leg is forward
	var opp := 0
	for i in range(a, b):
		var r: Dictionary = rec[i]
		var inv: Basis = r["inv"]
		var hands := (inv * ((r["p"]["LeftHand"] as Vector3) - (r["p"]["RightHand"] as Vector3))).z
		var feet := (inv * ((r["p"]["RightFoot"] as Vector3) - (r["p"]["LeftFoot"] as Vector3))).z
		opp += 1 if hands * feet > 0.0 else 0
	g["opposite"] = 100.0 * opp / n
	g["drift"] = drift(rec, a, b)
	return g


func _walk_and_run() -> void:
	print("--- walking, steady, on the flat")
	var rec := await play("walk", Vector3(20.0, 0.0, 10.0), -PI * 0.5, seg(10.0, 1.0, 0.0))
	var w := gait(rec, 180)
	if w.is_empty():
		for id: String in ["walk.speed", "walk.cadence", "walk.stride", "walk.stance_a", "walk.stance_b", "walk.double", "walk.no_flight", "walk.bob", "walk.sway", "walk.pelvis_tilt", "walk.pelvis_drop", "walk.pelvis_turn", "walk.arms_opposite", "walk.hip_flex", "walk.hip_ext", "walk.knee_load", "walk.knee_straightens", "walk.knee_toeoff", "walk.knee_swing", "walk.ankle_up", "walk.ankle_down", "walk.toe", "walk.drift"]:
			missing(id, "fewer than two whole strides seen")
	else:
		flat = w
		bar("walk.speed", w["speed"])
		bar("walk.cadence", w["cadence"])
		bar("walk.stride", w["stride"])
		bar("walk.stance_a", w["stance"])
		bar("walk.stance_b", w["stance"])
		bar("walk.double", w["double"])
		flag("walk.no_flight", int(w["none"]) == 0, "%d ticks with both feet off" % int(w["none"]))
		bar("walk.bob", w["bob"])
		bar("walk.sway", w["sway"])
		bar("walk.pelvis_tilt", w["pelvis_tilt"])
		bar("walk.pelvis_drop", w["pelvis_drop"])
		bar("walk.pelvis_turn", w["pelvis_turn"])
		bar("walk.arms_opposite", w["opposite"])
		bar("walk.hip_flex", w["hip_flex"])
		bar("walk.hip_ext", w["hip_ext"])
		bar("walk.knee_load", w["knee_load"])
		flag("walk.knee_straightens", float(w["knee_mid"]) < float(w["knee_load"]), "least bend in mid-stance %.0f deg" % float(w["knee_mid"]))
		bar("walk.knee_toeoff", w["knee_toeoff"])
		bar("walk.knee_swing", w["knee_swing"])
		bar("walk.ankle_up", w["ankle_up"])
		bar("walk.ankle_down", w["ankle_down"])
		if is_nan(float(w["toe"])):
			missing("walk.toe", "the skeleton has no toe-end joint to measure the toe by")
		else:
			bar("walk.toe", w["toe"])
		bar("walk.drift", w["drift"])
		print("          (not in the study, for information: feet %.3f m apart sideways; elbows bent %.0f deg on average)" % [float(w["width"]), float(w["elbow"])])
	var walk_fault := foot_fault(rec, 180, rec.size(), true)

	print("--- running, steady, on the flat")
	rec = await play("run", Vector3(20.0, 0.0, 12.0), -PI * 0.5, seg(6.0, 1.0, 0.0, 0.0, true))
	var g := gait(rec, 150)
	if g.is_empty():
		for id: String in ["run.speed", "run.stride", "run.stance", "run.flight", "run.bob", "run.knee", "run.knee_at_speed", "run.hip_flex", "run.hip_flex_at_speed", "run.hip_ext", "run.ankle_up", "run.ankle_down", "run.width", "run.arms_opposite", "run.drift", "arms.walk_straighter"]:
			missing(id, "fewer than two whole strides seen")
	else:
		bar("run.speed", g["speed"])
		bar("run.stride", g["stride"])
		bar("run.stance", g["stance"])
		flag("run.flight", bool(g["flight"]) and int(g["both"]) == 0, "both feet off for %d ticks in %d strides, both down for %d" % [int(g["none"]), int(g["strides"]), int(g["both"])])
		bar("run.bob", g["bob"])
		bar("run.knee", g["knee_swing"])
		bar("run.knee_at_speed", g["knee_swing"])
		bar("run.hip_flex", g["hip_flex"])
		bar("run.hip_flex_at_speed", g["hip_flex"])
		bar("run.hip_ext", g["hip_ext"])
		bar("run.ankle_up", g["ankle_up"])
		bar("run.ankle_down", g["ankle_down"])
		bar("run.width", g["width"])
		bar("run.arms_opposite", g["opposite"])
		bar("run.drift", g["drift"])
		if w.is_empty():
			missing("arms.walk_straighter", "no walk to compare with")
		else:
			flag("arms.walk_straighter", float(w["elbow"]) < float(g["elbow"]), "elbows bent %.0f deg walking, %.0f running" % [float(w["elbow"]), float(g["elbow"])])
	var run_fault := foot_fault(rec, 150, rec.size(), false)
	bar("feet.flat", maxf(float(walk_fault[0]), float(run_fault[0])), "walk: %s; run: %s" % [_fault_text(walk_fault), _fault_text(run_fault)])
	info("feet.flat_ik", "not compared by this audit")

	print("--- from a walk to a run")
	rec = await play("walk to run", Vector3(20.0, 0.0, 14.0), -PI * 0.5, seg(3.0, 1.0, 0.0) + seg(3.5, 1.0, 0.0, 0.0, true))
	var order := steps(rec, 120, 330)
	var twice := 0
	for i in range(1, order.size()):
		if order[i][1] == order[i - 1][1]:
			twice += 1
	flag("gait.no_double_step", twice == 0 and order.size() >= 4, "%d landings, %d times the same foot twice" % [order.size(), twice])

	print("--- the speed at which walking turns into running")
	var switch_at := NAN
	var tried := ""
	for v: float in [1.5, 1.7, 1.9, 2.1, 2.3, 2.5]:
		rec = await play("steady %.1f m/s" % v, Vector3(20.0, 0.0, 16.0), -PI * 0.5, seg(7.0, v / 4.5, 0.0, 0.0, true))
		var s := gait(rec, 210)
		var fl: bool = not s.is_empty() and bool(s["flight"])
		tried += " %.1f:%s" % [float(s.get("speed", 0.0)), "flight" if fl else "none"]
		if fl and is_nan(switch_at):
			switch_at = float(s["speed"])
	if is_nan(switch_at):
		missing("gait.switch", "no flight phase at any speed tried (" + tried.strip_edges() + ")")
	else:
		bar("gait.switch", switch_at, tried.strip_edges())


func _standing() -> void:
	print("--- standing still")
	var rec := await play("standing", Vector3(40.0, 0.0, 10.0), 0.0, seg(16.0, 0.0, 0.0))
	var from := 120
	var still_for := 0
	var longest := 0
	var xs := PackedFloat32Array()
	var zs := PackedFloat32Array()
	for i in range(from, rec.size()):
		var h: Vector3 = (rec[i]["inv"] as Basis) * ((rec[i]["p"]["Hips"] as Vector3) - (rec[i]["pos"] as Vector3))
		xs.append(h.x)
		zs.append(h.z)
		if i > from:
			var moved := ((rec[i]["p"]["Hips"] as Vector3) - (rec[i - 1]["p"]["Hips"] as Vector3)).length()
			still_for = still_for + 1 if moved < 0.000001 else 0
			longest = maxi(longest, still_for)
	flag("stand.never_still", longest < 6, "longest spell without the hips moving: %d ticks" % longest)
	# the sway's frequency: how often the hips pass their middle position, along the line they move most on
	var use := xs
	var rx := _span(xs)
	var rz := _span(zs)
	if rz > rx:
		use = zs
	var mid := 0.0
	for v in use:
		mid += v
	mid /= maxf(use.size(), 1)
	var crossings := 0
	for i in range(1, use.size()):
		if (use[i] - mid) * (use[i - 1] - mid) < 0.0:
			crossings += 1
	var secs := use.size() / 60.0
	bar("stand.sway_freq", crossings / (2.0 * secs), "the hips move within %.1f by %.1f cm" % [rx * 100.0, rz * 100.0])
	info("stand.reversal", "")


func _span(a: PackedFloat32Array) -> float:
	var lo := INF
	var hi := -INF
	for v in a:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	return hi - lo


# ------------------------------------------------------------------------------------------------ starts, stops

func _first_tick(rec: Array, f: Callable, from := 0) -> int:
	for i in range(from, rec.size()):
		if f.call(rec[i]):
			return i
	return -1


func _starts_and_stops() -> void:
	print("--- starting and stopping, walk")
	var rec := await play("start and stop, walk", Vector3(40.0, 0.0, 12.0), -PI * 0.5, seg(0.5, 0.0, 0.0) + seg(6.0, 1.0, 0.0) + seg(3.0, 0.0, 0.0))
	var t0 := 30
	var t1 := 390
	var top := _mean(rec, 300, 380, func(r: Dictionary) -> float: return r["v"])
	var lifts := _first_tick(rec, func(r: Dictionary) -> bool: return not (bool(r["down0"]) and bool(r["down1"])), t0)
	var order := steps(rec, maxi(lifts, t0) + 1, t1)
	if order.is_empty() or lifts < 0:
		missing("start.first_step", "no step seen")
		missing("start.steady", "no step seen")
		missing("start.not_instant", "no step seen")
	else:
		bar("start.first_step", 100.0 * float(rec[order[0][0]]["v"]) / top, "the first step lands %.2f s after the stick" % ((order[0][0] - t0) / 60.0))
		var steady_at := _first_tick(rec, func(r: Dictionary) -> bool: return float(r["v"]) >= STEADY_SHARE * top, t0)
		var before := 0
		for s: Array in order:
			if s[0] < steady_at:
				before += 1
		bar("start.steady", before + 1, "steady %.2f s after the stick" % ((steady_at - t0) / 60.0))
		flag("start.not_instant", float(rec[lifts]["v"]) < STEADY_SHARE * top, "%.0f %% of walking speed when the first foot leaves the ground" % (100.0 * float(rec[lifts]["v"]) / top))
	var walk_steps := _stop(rec, t1, "walk")

	print("--- starting and stopping, run")
	rec = await play("start and stop, run", Vector3(40.0, 0.0, 14.0), -PI * 0.5, seg(0.5, 0.0, 0.0) + seg(4.0, 1.0, 0.0, 0.0, true) + seg(4.0, 0.0, 0.0))
	var run_steps := _stop(rec, 270, "run")
	if walk_steps < 0 or run_steps < 0:
		missing("stop.run_several", "a stop was not seen")
	else:
		flag("stop.run_several", run_steps > walk_steps, "%d steps from a run, %d from a walk" % [run_steps, walk_steps])

	print("--- let go and press again in the middle of a stop")
	rec = await play("stop and go", Vector3(40.0, 0.0, 16.0), -PI * 0.5, seg(4.0, 1.0, 0.0) + seg(0.25, 0.0, 0.0) + seg(2.5, 1.0, 0.0))
	var calm := _leg_turn(rec, 120, 235)
	var pop := _leg_turn(rec, 240, 330)
	info("stop.recover", "biggest leg-bone turn in one tick %.1f deg, against %.1f deg in steady walking" % [pop, calm])


func _leg_turn(rec: Array, a: int, b: int) -> float:
	var worst := 0.0
	for i in range(maxi(a, 1), mini(b, rec.size())):
		for n: String in ["LeftUpLeg", "LeftLeg", "RightUpLeg", "RightLeg"]:
			var q0 := (rec[i - 1]["d"][n] as Basis).get_rotation_quaternion()
			var q1 := (rec[i]["d"][n] as Basis).get_rotation_quaternion()
			worst = maxf(worst, rad_to_deg(q0.angle_to(q1)))
	return worst


## The stop that begins at tick `t1`. Returns the steps it took (-1 = he never came to rest).
func _stop(rec: Array, t1: int, gait_name: String) -> int:
	var still := _first_tick(rec, func(r: Dictionary) -> bool: return float(r["v"]) < 0.02, t1)
	var ids := ["stop.walk_under_two", "stop.walk_one_to_two", "stop.walk_rear_planted", "stop.walk_slide"] if gait_name == "walk" else ["stop.run_steps", "stop.run_dist", "stop.run_lean_back", "stop.run_slide"]
	if still < 0:
		for id: String in ids:
			missing(id, "he never came to rest")
		return -1
	var settle := mini(still + 60, rec.size())
	var order := steps(rec, t1 + 1, settle)
	var dist := ((rec[still]["pos"] as Vector3) - (rec[t1]["pos"] as Vector3)).length()
	var slide := drift(rec, t1, settle)
	var text := "still after %.2f s and %.2f m" % [(still - t1) / 60.0, dist]
	if gait_name == "walk":
		bar("stop.walk_under_two", order.size(), text)
		bar("stop.walk_one_to_two", order.size(), text)
		# the rear foot left planted: after the last step lands no foot is lifted again, and the feet end apart
		var last: int = order[order.size() - 1][0] if not order.is_empty() else t1
		var lifted := false
		for i in range(last + 1, settle):
			for f in 2:
				if bool(rec[i - 1]["down%d" % f]) and not bool(rec[i]["down%d" % f]):
					lifted = true
		var end: Dictionary = rec[settle - 1]
		var apart := absf(((end["inv"] as Basis) * ((end["p"]["LeftFoot"] as Vector3) - (end["p"]["RightFoot"] as Vector3))).z)
		flag("stop.walk_rear_planted", not lifted and bool(end["down0"]) and bool(end["down1"]), "a foot lifted again after the last step: %s; feet end %.2f m apart front to back" % ["yes" if lifted else "no", apart])
		bar("stop.walk_slide", slide)
	else:
		bar("stop.run_steps", order.size(), text)
		bar("stop.run_dist", dist)
		var back := _low(rec, t1, still + 1, trunk_lean)
		flag("stop.run_lean_back", back < 0.0, "the trunk's furthest lean back while stopping: %.1f deg behind upright (- = still forward of it)" % -back)
		bar("stop.run_slide", slide)
	return order.size()


# ------------------------------------------------------------------------------------------------ turns

## Unwrapped world heading of a part through a record, in degrees.
func _yaws(rec: Array, n: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var last := 0.0
	for i in rec.size():
		var y := world_yaw(rec[i], n)
		if i > 0:
			y = last + wrapf(y - last, -PI, PI)
		last = y
		out.append(rad_to_deg(y))
	return out


func _begun(y: PackedFloat32Array, from: int, base_from: int) -> int:
	var base := 0.0
	for i in range(base_from, from):
		base += y[i]
	base /= maxf(from - base_from, 1)
	for i in range(from, y.size()):
		if absf(y[i] - base) > BEGUN_DEG:
			return i
	return -1


func _turns() -> void:
	print("--- turning 180 degrees on the spot")
	var rec := await play("180 on the spot", Vector3(60.0, 0.0, 10.0), 0.0, seg(1.0, 0.0, 0.0) + seg(3.5, 0.0, 1.0))
	var t0 := 60
	var pelvis := _yaws(rec, "Hips")
	var head := _yaws(rec, "Head")
	var chest := _yaws(rec, "Spine2")
	var done := -1
	for i in range(t0, rec.size()):
		if absf(pelvis[i] - pelvis[t0]) >= 170.0:
			done = i
			break
	if done < 0:
		for id: String in ["spot.steps", "spot.steps_stage", "spot.order", "spot.head_peak"]:
			missing(id, "the pelvis never turned 170 degrees")
	else:
		var n := steps(rec, t0 + 1, done + 3).size()
		bar("spot.steps", n, "turned in %.2f s" % ((done - t0) / 60.0))
		bar("spot.steps_stage", n)
		var th := _begun(head, t0, 30)
		var tc := _begun(chest, t0, 30)
		var tp := _begun(pelvis, t0, 30)
		var tf := _first_tick(rec, func(r: Dictionary) -> bool: return not (bool(r["down0"]) and bool(r["down1"])), t0)
		flag("spot.order", th >= 0 and th < tc and tc < tp and tp < tf, "ticks after the stick: head %d, chest %d, pelvis %d, feet %d" % [th - t0, tc - t0, tp - t0, tf - t0])
		var peak := 0.0
		for i in range(t0 + 2, mini(done + 30, rec.size() - 2)):
			peak = maxf(peak, absf(head[i + 2] - head[i - 2]) / (4.0 * TICK))
		bar("spot.head_peak", peak)
	var neck_most := _peak(rec, t0, rec.size(), func(r: Dictionary) -> float: return absf(bend(r, "Spine2", "Head").z))
	flag("look.behind", neck_most <= float(bars["limit.neck_turn"]["value"]), "the head turns %.0f deg against the chest at most" % neck_most)

	print("--- a 90 degree corner at a walk")
	rec = await play("corner", Vector3(60.0, 0.0, 14.0), 0.0, seg(4.0, 0.0, -1.0) + seg(3.5, 0.0, -1.0, 90.0))
	var tc0 := 240
	pelvis = _yaws(rec, "Hips")
	head = _yaws(rec, "Head")
	chest = _yaws(rec, "Spine2")
	# a walking pelvis turns left and right by itself: a turn has begun when a part has left the band it kept
	var th2 := _left_band(head, 120, tc0)
	var tp2 := _left_band(pelvis, 120, tc0)
	var tch := _left_band(chest, 120, tc0)
	if th2 < 0 or tp2 < 0:
		for id: String in ["turn.head_first", "turn.head_lead_time", "turn.head_angle"]:
			missing(id, "no turn seen")
		missing("look.trunk_no_lead", "no turn seen")
	else:
		flag("turn.head_first", th2 < tp2, "head %d ticks after the stick, pelvis %d" % [th2 - tc0, tp2 - tc0])
		bar("turn.head_lead_time", (tp2 - th2) / 60.0)
		var most := 0.0
		for i in range(tc0, mini(tc0 + 150, rec.size())):
			most = maxf(most, bend(rec[i], "Hips", "Head").z)       # + = to his left = into this turn
		bar("turn.head_angle", most)
		flag("look.trunk_no_lead", tch >= tp2, "chest %d ticks after the stick, pelvis %d" % [tch - tc0, tp2 - tc0])
	var lean_base := _mean(rec, 120, tc0, _side_lean)
	var lean_most := 0.0
	for i in range(tc0, mini(tc0 + 150, rec.size())):
		lean_most = maxf(lean_most, -(_side_lean(rec[i]) - lean_base))        # a left turn: the lean is to his left
	bar("turn.lean", lean_most)
	var look_most := _peak(rec, 120, rec.size(), func(r: Dictionary) -> float: return absf(bend(r, "Hips", "Head").z))
	var look_speed := 0.0
	for i in range(122, rec.size() - 2):
		look_speed = maxf(look_speed, absf(bend(rec[i + 2], "Spine2", "Head").z - bend(rec[i - 2], "Spine2", "Head").z) / (4.0 * TICK))

	print("--- walking in circles")
	var straight := float(flat.get("speed", 0.0))
	var found := []
	for w: float in [35.0, 50.0, 65.0, 80.0, 95.0]:
		var samples := seg(2.0, 0.0, -1.0)
		var ticks := int(60.0 * (360.0 / w + 2.0))
		for i in ticks:
			samples.append({"mx": 0.0, "mz": -1.0, "yaw": deg_to_rad(w * i / 60.0), "run": false, "jump": false, "crouch": false, "act": false})
		rec = await play("circle %.0f deg/s" % w, Vector3(100.0, 0.0, 12.0), 0.0, samples)
		var a := 120 + 180
		var v := _mean(rec, a, rec.size(), func(r: Dictionary) -> float: return r["v"])
		found.append([v / deg_to_rad(w), v])
		look_most = maxf(look_most, _peak(rec, a, rec.size(), func(r: Dictionary) -> float: return absf(bend(r, "Hips", "Head").z)))
		for i in range(a, rec.size() - 2):
			look_speed = maxf(look_speed, absf(bend(rec[i + 2], "Spine2", "Head").z - bend(rec[i - 2], "Spine2", "Head").z) / (4.0 * TICK))
	var at_one := NAN
	var text := ""
	for i in found.size():
		text += " %.2f m at %.2f m/s;" % [found[i][0], found[i][1]]
		if i > 0 and float(found[i - 1][0]) >= 1.0 and float(found[i][0]) <= 1.0:
			var k := (float(found[i - 1][0]) - 1.0) / maxf(float(found[i - 1][0]) - float(found[i][0]), 0.0001)
			at_one = lerpf(found[i - 1][1], found[i][1], k)
	if is_nan(at_one) or straight <= 0.0:
		missing("turn.circle", "no circle of 1 m radius among those walked (" + text.strip_edges() + ")")
	else:
		bar("turn.circle", at_one / straight, "%.2f m/s on the 1 m circle, %.2f m/s straight; circles walked:%s" % [at_one, straight, text])
	bar("look.head_most", look_most, "corner and circles")
	bar("look.speed", look_speed, "corner and circles")


## The first tick after `from` on which a heading leaves the band it kept between `base_from` and `from`, by more
## than BEGUN_DEG.
func _left_band(y: PackedFloat32Array, base_from: int, from: int) -> int:
	var lo := INF
	var hi := -INF
	for i in range(base_from, from):
		lo = minf(lo, y[i])
		hi = maxf(hi, y[i])
	for i in range(from, y.size()):
		if y[i] > hi + BEGUN_DEG or y[i] < lo - BEGUN_DEG:
			return i
	return -1


func _side_lean(r: Dictionary) -> float:
	# the line from the feet (the body's own point on the ground) to the chest, seen from behind; + = to his right
	var v: Vector3 = (r["inv"] as Basis) * ((r["p"]["Spine2"] as Vector3) - (r["pos"] as Vector3))
	return rad_to_deg(atan2(v.x, v.y))


# ------------------------------------------------------------------------------------------------ stairs, slopes

## Walk (or run) a station's stairs or ramp, up or down. Returns the record and the ticks spent on it, clear of
## its two ends: {rec, a, b}.
func _climb(s: Dictionary, up: bool, run: bool, label: String) -> Dictionary:
	var x := float(s["x"])
	var length := float(s["tread"]) * int(s["steps"]) if s.has("tread") else float(s["run"])
	var far := -3.0 - length
	var speed := 0.45
	var secs := (length + 4.0) / speed
	var rec: Array
	if up:
		rec = await play(label, Vector3(x, 0.0, -1.2), 0.0, seg(minf(secs, 40.0), 0.0, -1.0, 0.0, run), func(p: Vector3) -> bool: return p.z < far - 1.2)
	else:
		rec = await play(label, Vector3(x, float(s["top"]), far - 1.8), PI, seg(minf(secs, 40.0), 0.0, 1.0, 0.0, run), func(p: Vector3) -> bool: return p.z > -1.5)
	var margin := 0.45
	var a := -1
	var b := -1
	for i in rec.size():
		var z := (rec[i]["pos"] as Vector3).z
		if z < -3.0 - margin and z > far + margin:
			if a < 0:
				a = i
			b = i + 1
	return {"rec": rec, "a": a, "b": b}


## Seconds a step on stairs: from his crossing of the second edge to his crossing of the last but one.
func _step_time(rec: Array, s: Dictionary, up: bool) -> float:
	var tread := float(s["tread"])
	var n := int(s["steps"])
	var first := -3.0 - tread * (2.0 if up else float(n - 2))
	var last := -3.0 - tread * (float(n - 2) if up else 2.0)
	var t_a := -1
	var t_b := -1
	for i in range(1, rec.size()):
		var z0 := (rec[i - 1]["pos"] as Vector3).z
		var z1 := (rec[i]["pos"] as Vector3).z
		if t_a < 0 and (z0 - first) * (z1 - first) <= 0.0 and z0 != z1:
			t_a = i
		if t_a >= 0 and t_b < 0 and i > t_a and (z0 - last) * (z1 - last) <= 0.0 and z0 != z1:
			t_b = i
	if t_a < 0 or t_b < 0:
		return NAN
	return (t_b - t_a) / 60.0 / float(n - 4)


func _stairs_and_slopes() -> void:
	var stairs := st("stairs 0.18 / 0.28 m x 10")
	for up: bool in [true, false]:
		var way := "up" if up else "down"
		print("--- stairs 0.18 / 0.28 m, walking %s" % way)
		var c: Dictionary = await _climb(stairs, up, false, "stairs %s, walk" % way)
		var rec: Array = c["rec"]
		if int(c["a"]) < 0:
			for id: String in ["stairs.%s_time" % way, "stairs.%s_hip" % way, "stairs.%s_ankle" % way, "feet.stairs_%s" % way]:
				missing(id, "he never got onto the stairs")
			continue
		var a := int(c["a"])
		var b := int(c["b"])
		var t := _step_time(rec, stairs, up)
		if is_nan(t):
			missing("stairs.%s_time" % way, "he did not cross the stairs")
		else:
			bar("stairs.%s_time" % way, t)
		var hip_peak := 0.0
		var ankle_peak := 0.0
		for side: String in SIDES:
			hip_peak += 0.5 * _peak(rec, a, b, func(r: Dictionary) -> float: return hip(r, side).x)
			ankle_peak += 0.5 * _peak(rec, a, b, func(r: Dictionary) -> float: return ankle(r, side))
		bar("stairs.%s_hip" % way, hip_peak)
		bar("stairs.%s_ankle" % way, ankle_peak)
		var x := foot_fault(rec, a, b, true)
		bar("feet.stairs_%s" % way, x[0], _fault_text(x))
		c = await _climb(stairs, up, true, "stairs %s, run" % way)
		if int(c["a"]) >= 0:
			x = foot_fault(c["rec"], int(c["a"]), int(c["b"]), false)
			outside("x.stairs_run_%s_feet" % way, x[0], _fault_text(x))

	for deg: int in [10, 19]:
		var ramp := st("ramp %d deg" % deg)
		for up: bool in [true, false]:
			var way := "up" if up else "down"
			print("--- ramp %d degrees, walking %s" % [deg, way])
			var c: Dictionary = await _climb(ramp, up, false, "ramp %d %s" % [deg, way])
			var id := "feet.ramp%d_%s" % [deg, way]
			if int(c["a"]) < 0:
				missing(id, "he never got onto the ramp")
				continue
			var rec: Array = c["rec"]
			var x := foot_fault(rec, int(c["a"]), int(c["b"]), true)
			bar(id, x[0], _fault_text(x))
			if deg == 19:
				var g := gait(rec.slice(int(c["a"]), int(c["b"])), 1, 1)
				if g.is_empty() or flat.is_empty():
					for sid: String in (["slope.up_trunk", "slope.up_legs"] if up else ["slope.down_trunk"]):
						missing(sid, "not one whole stride on the ramp, or no flat walk to compare with")
				elif up:
					flag("slope.up_trunk", float(g["trunk"]) > float(flat["trunk"]), "trunk %.1f deg forward on the ramp, %.1f on the flat" % [float(g["trunk"]), float(flat["trunk"])])
					flag("slope.up_legs", float(g["contact_hip"]) > float(flat["contact_hip"]) and float(g["contact_knee"]) > float(flat["contact_knee"]), "at foot contact: hip %.0f deg and knee %.0f deg on the ramp, %.0f and %.0f on the flat" % [float(g["contact_hip"]), float(g["contact_knee"]), float(flat["contact_hip"]), float(flat["contact_knee"])])
				else:
					flag("slope.down_trunk", float(g["trunk"]) < float(flat["trunk"]), "trunk %.1f deg forward on the ramp, %.1f on the flat" % [float(g["trunk"]), float(flat["trunk"])])

	print("--- OUTSIDE THE STUDY, kept at Yasin's word: steep ground (30 and 45 degrees)")
	var swing := 0.0
	var swing_text := ""
	for deg: int in [30, 45]:
		var ramp := st("ramp %d deg" % deg)
		for up: bool in [true, false]:
			var way := "up" if up else "down"
			var c: Dictionary = await _climb(ramp, up, false, "ramp %d %s" % [deg, way])
			var id := "x.steep%d_%s_feet" % [deg, way]
			if int(c["a"]) < 0:
				outside(id, 99.0, "he never got onto the ramp")
				continue
			var rec: Array = c["rec"]
			var a := int(c["a"])
			var b := int(c["b"])
			var x := foot_fault(rec, a, b, true)
			outside(id, x[0], _fault_text(x))
			var from := mini(a + 60, b - 1)
			var mean := _mean(rec, from, b, func(r: Dictionary) -> float: return r["v"])
			var hi := _peak(rec, from, b, func(r: Dictionary) -> float: return r["v"])
			var lo := _low(rec, from, b, func(r: Dictionary) -> float: return r["v"])
			var sw := 100.0 * maxf(hi - mean, mean - lo) / maxf(mean, 0.01)
			swing_text += " %d %s: %.2f to %.2f m/s;" % [deg, way, lo, hi]
			swing = maxf(swing, sw)
	outside("x.steep_body_in_charge", swing, swing_text.strip_edges())


# ------------------------------------------------------------------------------------------------ jumps, drops

func _jumps_and_drops() -> void:
	print("--- a standing jump")
	var rec := await play("standing jump", Vector3(80.0, 0.0, 10.0), 0.0, seg(1.0, 0.0, 0.0) + seg(0.1, 0.0, 0.0, 0.0, false, true) + seg(3.0, 0.0, 0.0))
	var tb := 60
	var off := _first_tick(rec, func(r: Dictionary) -> bool: return r["air"], tb)
	if off < 0:
		for id: String in ["jump.rise", "jump.dip", "jump.push"]:
			missing(id, "he never left the ground")
	else:
		bar("jump.rise", _peak(rec, off, rec.size(), func(r: Dictionary) -> float: return (r["pos"] as Vector3).y))
		var lowest := tb
		for i in range(tb, off + 1):
			if (rec[i]["p"]["Hips"] as Vector3).y < (rec[lowest]["p"]["Hips"] as Vector3).y - 0.0005:
				lowest = i
		bar("jump.dip", (lowest - tb) / 60.0, "the hips go down %.0f cm" % (100.0 * ((rec[tb]["p"]["Hips"] as Vector3).y - (rec[lowest]["p"]["Hips"] as Vector3).y)))
		bar("jump.push", (off - lowest) / 60.0)
	print("--- a jump at a run")
	rec = await play("running jump", Vector3(80.0, 0.0, 12.0), -PI * 0.5, seg(2.5, 1.0, 0.0, 0.0, true) + seg(0.1, 1.0, 0.0, 0.0, true, true) + seg(2.0, 1.0, 0.0, 0.0, true))
	off = _first_tick(rec, func(r: Dictionary) -> bool: return r["air"], 150)
	if off < 0:
		missing("jump.run_rise", "he never left the ground")
	else:
		bar("jump.run_rise", _peak(rec, off, rec.size(), func(r: Dictionary) -> float: return (r["pos"] as Vector3).y))

	print("--- stepping and dropping off edges")
	var in_stride := true
	var text := ""
	for item: Array in [["kerb 0.20 m", 0.20], ["step 0.30 m", 0.30]]:
		var s := st(item[0])
		rec = await play("edge %.2f" % float(item[1]), Vector3(float(s["x"]), float(item[1]), -4.4), PI, seg(3.0, 0.0, 1.0))
		var flew := 0
		var kinds := {}
		for r: Dictionary in rec:
			flew += 1 if bool(r["air"]) else 0
			if String(r["landing"]) != "":
				kinds[r["landing"]] = true
		text += " %.2f m: %d ticks in the air, landing '%s';" % [float(item[1]), flew, ",".join(kinds.keys())]
		if flew > 0 or not kinds.is_empty():
			in_stride = false
	flag("land.in_stride", in_stride, text.strip_edges())
	var soft := true
	var heavy := true
	var fold := true
	var soft_text := ""
	var heavy_text := ""
	var fold_text := ""
	for h: float in [0.50, 0.80, 1.10, 1.40, 1.80]:
		var s := st("deep wall %.2f m" % h)
		rec = await play("drop %.2f" % h, Vector3(float(s["x"]), h, -4.4), PI, seg(4.5, 0.0, 1.0))
		var left := _first_tick(rec, func(r: Dictionary) -> bool: return r["air"], 0)
		var down := _first_tick(rec, func(r: Dictionary) -> bool: return not bool(r["air"]), maxi(left, 0) + 1) if left >= 0 else -1
		var kind := "never landed"
		if down >= 0:
			kind = "none"
			for i in range(down, mini(down + 30, rec.size())):
				if String(rec[i]["landing"]) != "":
					kind = rec[i]["landing"]
					break
			var k0 := 0.5 * (knee(rec[down], "Left") + knee(rec[down], "Right"))
			var later: Dictionary = rec[mini(down + 6, rec.size() - 1)]
			var k1 := 0.5 * (knee(later, "Left") + knee(later, "Right"))
			fold_text += " %.2f m: knees %.0f deg at contact, %.0f deg 0.1 s later;" % [h, k0, k1]
			if k1 <= k0:
				fold = false
		else:
			fold = false
		if h < 1.0:
			soft_text += " %.2f m: %s;" % [h, kind]
			soft = soft and kind == "soft"
		else:
			heavy_text += " %.2f m: %s;" % [h, kind]
			heavy = heavy and kind == "heavy"
	flag("land.soft", soft, soft_text.strip_edges())
	flag("land.heavy", heavy, heavy_text.strip_edges())
	flag("land.fold", fold, fold_text.strip_edges())


# ------------------------------------------------------------------------------------------------ the run

func _tree_hash() -> String:
	var names: Array[String] = []
	_walk_dir("res://traversal", names)
	names.append("study/bars.json")
	names.append("tests/audit.gd")
	var full: Array[String] = []
	for n in names:
		full.append("traversal_lab/" + n)
	full.sort()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for n in full:
		var rel := n.substr("traversal_lab/".length())
		ctx.update(("%s %s\n" % [rel, FileAccess.get_sha256("res://" + rel)]).to_utf8_buffer())
	return ctx.finish().hex_encode()


func _walk_dir(path: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(path):
		for ext: String in [".gd", ".res", ".scn", ".tscn", ".json"]:
			if f.ends_with(ext):
				out.append((path + "/" + f).substr("res://".length()))
	for d in DirAccess.get_directories_at(path):
		_walk_dir(path + "/" + d, out)


func _run() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(BARS))
	pct = float(data["margin_rule"]["single_percent"])
	for b: Dictionary in data["bars"]:
		bars[b["id"]] = b
	lab = (load("res://traversal/main.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	for i in 5:
		await physics_frame
	body = lab.get(&"body")
	tape = lab.get(&"tape")
	character = lab.get(&"character")
	skel = character.get(&"skel")
	stations = lab.get(&"course").get(&"stations")
	for n: String in NAMES:
		var i := skel.find_bone("mixamorig_" + n)
		if i >= 0:
			bone[n] = i
	# standing straight (the skeleton's own rest), in the body's own axes
	lab.call(&"place", Vector3(40.0, 0.0, 10.0))
	body.rotation.y = 0.0
	for i in 20:
		await physics_frame
	var inv := _ortho(body.global_transform.basis).inverse()
	var sk := skel.global_transform
	for n: String in bone:
		rest[n] = inv * _ortho(sk.basis * skel.get_bone_global_rest(bone[n]).basis)
	var foot_rest: Vector3 = sk * skel.get_bone_global_rest(bone["LeftFoot"]).origin
	var toe_rest: Vector3 = sk * skel.get_bone_global_rest(bone["LeftToeBase"]).origin
	var knee_rest: Vector3 = sk * skel.get_bone_global_rest(bone["LeftLeg"]).origin
	toe_stand = toe_rest.y - body.global_position.y
	ankle_stand = foot_rest.y - body.global_position.y
	ankle_zero = rad_to_deg((foot_rest - knee_rest).angle_to(toe_rest - foot_rest))
	for f in 2:
		var side: String = SIDES[f]
		if bone.has(side + "Toe_End"):
			var t0: Vector3 = skel.get_bone_global_rest(bone[side + "ToeBase"]).origin
			var t1: Vector3 = skel.get_bone_global_rest(bone[side + "Toe_End"]).origin
			var foot_basis := _ortho(skel.get_bone_global_rest(bone[side + "Foot"]).basis)
			# (in the rest pose the foot's own frame is the rest frame: the toe's rise there is its zero)
			var v := (t1 - t0).normalized()
			toe_zero[f] = rad_to_deg(atan2(v.y, Vector2(v.x, v.z).length()))
	skel.skeleton_updated.connect(_after)
	print("THE STUDY AUDIT  (bars: res://study/bars.json; a single figure passes within %d %%: %s)" % [int(pct), data["margin_rule"]["by"]])

	await _walk_and_run()
	await _standing()
	await _starts_and_stops()
	await _turns()
	await _stairs_and_slopes()
	await _jumps_and_drops()

	print("--- joint limits, the worst seen anywhere in the audit")
	for id: String in bars:
		if not id.begins_with("limit."):
			continue
		if not limit_worst.has(id):
			if bars[id]["kind"] == "info":
				info(id, "")
			continue
		if bars[id]["kind"] == "info":
			info(id, "most seen: %.1f deg (%s)" % [float(limit_worst[id][0]), limit_worst[id][1]])
		else:
			bar(id, maxf(float(limit_worst[id][0]), 0.0), "in: %s" % limit_worst[id][1])
	print("--- stages not built yet")
	for id: String in bars:
		if bars[id]["kind"] == "not_built":
			_line(id, "NOT BUILT", bars[id]["what"])
	for id: String in bars:
		if not reported.has(id):
			_line(id, "FAIL", "NOT MEASURED by the audit  [%s]" % bars[id]["what"])

	var judged := 0
	for id: String in reported:
		if reported[id] == "PASS" or reported[id] == "FAIL":
			judged += 1
	var result := {"tree": _tree_hash(), "judged": judged, "fails": fails, "outside_off": outside_off, "measured": {}}
	for id: String in measured:
		result["measured"][id] = null if is_nan(float(measured[id])) else snappedf(float(measured[id]), 0.001)
	var f := FileAccess.open(RESULT, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "  ") + "\n")
	f.close()
	print("OUTSIDE THE STUDY: %d of %d lines off our own figure" % [outside_off.size(), (data["outside"]["lines"] as Array).size()])
	print("RESULT %s: %d of %d study lines fail" % ["PASS" if fails.is_empty() else "FAIL", fails.size(), judged])
	quit(1 if not fails.is_empty() else 0)
