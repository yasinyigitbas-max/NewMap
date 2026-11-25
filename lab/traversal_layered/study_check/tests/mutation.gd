## STUDY CHECK (LOCKED): mutation tests (study 9.2). Every rule must be shown to fail before any other result counts.
##   godot --headless --path . --fixed-fps <60|30> -s res://study_check/tests/mutation.gd -- [out=<file>] [seed=<n>]
## Poses the body (res://body/player_v3.glb, no lab code) directly with known values, by geometry in the skeleton's
## own axes (the body faces +Z, its left is +X), and checks:
##   - calibration: each joint axis reads 0 at rest, +30 when turned 30 deg the anatomical way, -10 the other way,
##     where "the anatomical way" is checked by geometry (the ankle goes behind the knee, the toes go up, ...);
##   - the 9.2 table: the right rule fires, with the right side, and nothing outside the allowed list fires;
##   - every case on both sides, in the rest T-pose and an A-pose, at a random yaw and a small random tilt, and (for
##     the legs) with a random hip rotation added first.
## If the lab has a final limiter class "FinalLimiter" (a SkeletonModifier3D with get_clamp_count()), each broken pose
## also goes through it: a pose inside the HARD limits must come out and its counter must go up (9.2, 10.2).
## Prints "MUTATION RESULT PASS" only if every case passes.
extends SceneTree

const BODY := "res://body/player_v3.glb"
var args := {"out": "", "seed": "7"}
var rng := RandomNumberGenerator.new()
var ground: StaticBody3D
var body: Node3D
var sk: Skeleton3D
var chk
var lim
var B := {}
var cases := []
var ci := -1
var cur: Dictionary
var fr := 0
var results := PackedStringArray()
var fails := 0
var fps := 60
var base_xf: Transform3D

func _init():
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	rng.seed = int(args.seed)
	ground = StaticBody3D.new()
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(400, 1, 400); cs.shape = bs
	ground.add_child(cs); ground.position = Vector3(0, -0.5, 0); ground.collision_layer = 1
	root.add_child(ground)
	body = load(BODY).instantiate()
	body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # the tests move it per drawn frame
	root.add_child(body)
	sk = body.find_child("Skeleton3D", true, false)
	for n in ["Hips", "Spine02", "Spine01", "Spine", "neck", "Head"]: B[n] = sk.find_bone(n)
	for sd in ["Left", "Right"]:
		for n in ["UpLeg", "Leg", "Foot", "ToeBase", "Arm", "ForeArm", "Hand", "HandMiddle1"]: B[sd + n] = sk.find_bone(sd + n)
	_build_cases()
	process_frame.connect(_frame)

# ------------------------------------------------------------------------------------------------ pose helpers
func _g(b: String) -> Transform3D: return sk.get_bone_global_pose(B[b])
func _rot(b: String, axis: Vector3, deg: float) -> void:
	var g := _g(b)
	sk.set_bone_global_pose(B[b], Transform3D(Basis(axis.normalized(), deg_to_rad(deg)) * g.basis, g.origin))
func _p(b: String) -> Vector3: return _g(b).origin * 0.01  # metres, skeleton axes
func _side(sd: int) -> String: return "Left" if sd == 0 else "Right"
func _lat(sd: int) -> float: return 1.0 if sd == 0 else -1.0  # +X is the body's left
func _hinge(sd: int) -> Vector3:
	# the knee's hinge by the study's definition (1.2): body left, perpendicular to the REST thigh
	var t: Vector3 = (sk.get_bone_global_rest(B[_side(sd) + "Leg"]).origin - sk.get_bone_global_rest(B[_side(sd) + "UpLeg"]).origin).normalized()
	return (Vector3.RIGHT - t * t.dot(Vector3.RIGHT)).normalized()
func _thigh(sd: int) -> Vector3: return (_p(_side(sd) + "Leg") - _p(_side(sd) + "UpLeg")).normalized()
func _shin(sd: int) -> Vector3: return (_p(_side(sd) + "Foot") - _p(_side(sd) + "Leg")).normalized()

# base variants (9.2: the rig's own rest pose and an A-pose; this body's rest is already a T-pose)
func _base(v: String) -> void:
	sk.reset_bone_poses()
	if v == "A":
		_rot("LeftArm", Vector3.BACK, -40.0)   # left arm down 40 deg (about the body's forward)
		_rot("RightArm", Vector3.BACK, 40.0)

# ------------------------------------------------------------------------------------------------ cases
func _add(name: String, expect: Array, allowed: Array, mode: String, setup: Callable, per_frame := Callable(), frames := 75, check := Callable()) -> void:
	for sd in [0, 1]:
		for v in ["T", "A"]:
			cases.append({"name": name, "side": sd, "variant": v, "expect": expect, "allowed": allowed, "mode": mode,
				"setup": setup, "per_frame": per_frame, "frames": frames, "check": check})

func _build_cases() -> void:
	# --- calibration (9.2 last paragraph): rest 0, +30, -10 the anatomical way, checked by geometry
	_add("calibrate rest = 0", [], [], "air", func(sd): pass, Callable(), 20, func(sd): return _read_all_zero())
	for amt in [30.0, -10.0]:
		_add("calibrate knee %+d" % amt, ([] if amt > 0 else ["KNEE_FLEX_MIN"]), [], "air",
			func(sd): _rot(_side(sd) + "Leg", _hinge(sd), amt),
			Callable(), 20, func(sd): return _expect_reading("knee_flex", sd, amt, (_p(_side(sd) + "Foot").z < _rest(_side(sd) + "Foot").z) == (amt > 0)))
		_add("calibrate ankle up %+d" % amt, (["ANKLE_DORSI"] if amt > 25 else []), [], "air",
			func(sd): _rot(_side(sd) + "Foot", _hinge(sd), -amt),
			Callable(), 20, func(sd): return _expect_reading("dorsi", sd, amt, (_p(_side(sd) + "ToeBase").y > _rest(_side(sd) + "ToeBase").y) == (amt > 0)))
		_add("calibrate hip flex %+d" % amt, [], [], "air",
			func(sd): _rot(_side(sd) + "UpLeg", _hinge(sd), -amt),
			Callable(), 20, func(sd): return _expect_reading("hip_flex", sd, amt, (_p(_side(sd) + "Leg").z > _rest(_side(sd) + "Leg").z) == (amt > 0)))
		_add("calibrate hip abduction %+d" % amt, [], [], "air",
			func(sd): _rot(_side(sd) + "UpLeg", Vector3.BACK, amt * _lat(sd)),
			Callable(), 20, func(sd): return _expect_reading("hip_abd", sd, amt, (_p(_side(sd) + "Leg").x * _lat(sd) > _rest(_side(sd) + "Leg").x * _lat(sd)) == (amt > 0)))
		_add("calibrate hip rotation out %+d" % amt, [], [], "air",
			func(sd): _rot(_side(sd) + "UpLeg", Vector3.UP, amt * _lat(sd)),
			Callable(), 20, func(sd): return _expect_reading("hip_rot", sd, amt, true))
		_add("calibrate foot toes-out %+d" % amt, [], ["FOOT_TWIST"], "air",
			func(sd): _rot(_side(sd) + "Foot", -_shin(sd), amt * _lat(sd)),
			Callable(), 20, func(sd): return _expect_reading("foot_abd", sd, amt, (_p(_side(sd) + "ToeBase").x * _lat(sd) > _rest(_side(sd) + "ToeBase").x * _lat(sd)) == (amt > 0)))
		_add("calibrate ankle inversion %+d" % amt, [], ["ANKLE_INVERSION"], "air",
			func(sd): pass, func(sd, f): if f == 2: _rot(_side(sd) + "Foot", _sole_fwd(sd), -amt * _lat(sd)),
			20, func(sd): return _expect_reading("inv", sd, amt, true))
		_add("calibrate elbow %+d" % amt, [], ["ELBOW"], "air",
			func(sd): _rot(_side(sd) + "ForeArm", _elbow_axis(sd), amt),
			Callable(), 20, func(sd): return _expect_reading("elbow", sd, amt, (_p(_side(sd) + "Hand").z > _rest(_side(sd) + "Hand").z) == (amt > 0)))
		_add("calibrate lumbar forward %+d" % amt, [], [], "air",
			func(sd): _rot("Spine01", Vector3.RIGHT, amt),
			Callable(), 20, func(sd): return _expect_reading("lumb_f", -1, amt, true))
		_add("calibrate thoracic forward %+d" % amt, [], ["SPINE_THORACIC"], "air",
			func(sd): _rot("Spine", Vector3.RIGHT, amt),
			Callable(), 20, func(sd): return _expect_reading("thor_f", -1, amt, true))
		_add("calibrate neck forward %+d" % amt, [], [], "air",
			func(sd): _rot("Head", Vector3.RIGHT, amt),
			Callable(), 20, func(sd): return _expect_reading("neck_f", -1, amt, true))
	_add("calibrate lumbar side 20", [], [], "air", func(sd): _rot("Spine01", Vector3.BACK, 20.0),
		Callable(), 20, func(sd): return _expect_abs("lumb_s", -1, 20.0))
	_add("calibrate lumbar twist 8", [], [], "air", func(sd): _rot("Spine01", Vector3.UP, 8.0),
		Callable(), 20, func(sd): return _expect_abs("lumb_t", -1, 8.0))
	_add("calibrate neck turn 40", [], [], "air", func(sd): _rot("Head", Vector3.UP, 40.0),
		Callable(), 20, func(sd): return _expect_abs("neck_t", -1, 40.0))
	_add("calibrate knee twist 4 (straight)", [], [], "air", func(sd): _rot(_side(sd) + "Leg", _shin(sd), 4.0),
		Callable(), 20, func(sd): return _expect_abs("knee_twist", sd, 4.0))
	_add("calibrate forearm twist 40", [], [], "air", func(sd): _rot(_side(sd) + "Hand", _farm(sd), 40.0),
		Callable(), 20, func(sd): return _expect_abs("farm_twist", sd, 40.0))
	_add("calibrate toe up 30", [], [], "air", func(sd): pass, func(sd, f): if f == 2: _toe_up(sd, 30.0),
		20, func(sd): return _expect_reading("toe", sd, 30.0, true))

	# --- the 9.2 table
	_add("knee -20 (backward)", ["KNEE_FLEX_MIN"], [], "air", func(sd): _hiprot(sd); _rot(_side(sd) + "Leg", _hinge(sd), -20.0))
	_add("knee +30 forward", [], [], "air", func(sd): _hiprot(sd); _rot(_side(sd) + "Leg", _hinge(sd), 30.0))
	_add("knee +40, thigh rotated 120 in", ["HIP_ROTATION"], ["KNEE_OVER_TOE", "JOINT_SPEED"], "air",
		func(sd): _rot(_side(sd) + "Leg", _hinge(sd), 40.0); _rot(_side(sd) + "UpLeg", _thigh(sd), 120.0 * _lat(sd)))
	_add("shin 15 out of the hinge plane", ["KNEE_VARUS"], ["KNEE_TWIST"], "air",
		func(sd): _hiprot(sd); _rot(_side(sd) + "Leg", Vector3.BACK, 15.0 * _lat(sd)))
	_add("foot rolled 40 onto its outer edge", ["ANKLE_INVERSION"], [], "air",
		func(sd): _hiprot(sd); _rot(_side(sd) + "Foot", _foot_fwd(sd), -40.0 * _lat(sd)))
	_add("foot twisted 60 out", ["FOOT_TWIST"], ["ANKLE_EVERSION", "ANKLE_INVERSION"], "air",
		func(sd): _hiprot(sd); _rot(_side(sd) + "Foot", -_shin(sd), 60.0 * _lat(sd)))
	_add("ankle 30 up, straight knee", ["ANKLE_DORSI"], [], "air", func(sd): _hiprot(sd); _rot(_side(sd) + "Foot", _hinge(sd), -30.0))
	_add("ankle 30 up, knee 45", [], [], "air",
		func(sd): _hiprot(sd); _rot(_side(sd) + "Leg", _hinge(sd), 45.0); _rot(_side(sd) + "Foot", _hinge(sd), -30.0))
	_add("hip 110 forward, straight knee", ["HIP_FLEX_COUPLED"], [], "air", func(sd): _rot(_side(sd) + "UpLeg", _hinge(sd), -110.0))
	_add("knee snapped 40 in one frame", ["POSE_DISCONTINUITY"], ["JOINT_SPEED"], "air", func(sd): pass,
		func(sd, f): if f == 40: _rot(_side(sd) + "Leg", _hinge(sd), 40.0))
	_add("hand inside the chest", ["SELF_INTERSECT"], [], "air",
		func(sd): _rot(_side(sd) + "Arm", Vector3.UP, -90.0 * _lat(sd)); _rot(_side(sd) + "ForeArm", _elbow_axis(sd), 120.0))
	_add("foot planted, rolled 20 (2 sole points down)", ["SOLE_ROLL"], [], "ground_contact",
		func(sd): pass, func(sd, f): if f == 2: _roll_on_edge(sd, 20.0))
	_add("foot sunk 3 cm (both feet)", ["CONTACT_SINK"], [], "ground_contact", func(sd): pass,
		func(sd, f): if f >= 5 and f < 25: body.position.y -= 0.0015)
	_add("planted foot moved 3 cm (both feet)", ["FOOT_SLIDE"], [], "ground_contact", func(sd): pass,
		func(sd, f): body.position.x = base_xf.origin.x + 0.03 * clamp((f - 30) / 30.0, 0.0, 1.0))
	_add("whole body leaning 50, no acceleration", ["LEAN_MAX", "LEAN_MISMATCH"], ["TRUNK_LEAN", "TRUNK_BEND"], "ground_physics",
		func(sd): pass, func(sd, f): if f == 2: _lean_bones_about_toes(50.0), 100)
	_add("skeleton node tilted 48 (lean put on the node)", ["LEAN_MAX"], ["LEAN_MISMATCH", "TRUNK_LEAN", "TRUNK_BEND"], "ground_physics",
		func(sd): _tilt_about_toes(48.0), Callable(), 100)
	_add("trunk folded 60 at the waist, CoM over the feet", ["TRUNK_LEAN", "TRUNK_BEND"], ["LEAN_MISMATCH"], "ground_physics",
		func(sd): _fold_waist(60.0), Callable(), 110)
	_add("hips dropped 5 cm in one frame", ["COM_DOWN_GT_G"], ["POSE_DISCONTINUITY", "FLIGHT_PARABOLA", "LEAN_MISMATCH", "COM_ACCEL_V", "COM_ACCEL_H"], "ground_physics",
		func(sd): pass, func(sd, f): if f == 40: body.position.y -= 0.05)
	_add("both feet down in the middle of a run", ["RUN_DOUBLE_SUPPORT"], ["FOOT_SLIDE"], "ground_all",
		func(sd): pass, func(sd, f): body.position.z = base_xf.origin.z + 4.0 * f / float(fps), 100)
	_add("rest pose on the ground", [], [], "ground_all", func(sd): pass, Callable(), 100)

func _hiprot(sd: int) -> void:
	# random hip rotation first (9.2), within the limits
	_rot(_side(sd) + "UpLeg", _thigh(sd), rng.randf_range(-12.0, 12.0))
func _foot_fwd(sd: int) -> Vector3:
	var a := _p(_side(sd) + "Foot"); var t := _p(_side(sd) + "ToeBase")
	return Vector3(t.x - a.x, 0, t.z - a.z).normalized()
func _sole_fwd(sd: int) -> Vector3:
	var sp: PackedVector3Array = chk.get_sole_points()
	var heel := _to_sk(sp[sd * 4]); var ball := (_to_sk(sp[sd * 4 + 1]) + _to_sk(sp[sd * 4 + 2])) * 0.5
	return (ball - heel).normalized()
func _toe_up(sd: int, deg: float) -> void:
	var sp: PackedVector3Array = chk.get_sole_points()
	var heel := _to_sk(sp[sd * 4]); var bi := _to_sk(sp[sd * 4 + 1]); var bo := _to_sk(sp[sd * 4 + 2])
	var F := ((bi + bo) * 0.5 - heel).normalized()
	var U := (bi - heel).cross(bo - heel).normalized()
	if U.y < 0: U = -U
	var side := F.cross(U).normalized()
	var tip := _to_sk(sp[sd * 4 + 3]); var tb: Vector3 = _g(_side(sd) + "ToeBase").origin
	var sgn := 1.0 if (Basis(side, deg_to_rad(deg)) * (tip - tb)).y > (tip - tb).y else -1.0
	_rot(_side(sd) + "ToeBase", side, deg * sgn)
func _farm(sd: int) -> Vector3: return (_p(_side(sd) + "Hand") - _p(_side(sd) + "ForeArm")).normalized()
func _elbow_axis(sd: int) -> Vector3:
	# the rest hinge (moves a T-pose forearm toward the body's front), turned with the upper arm since rest
	var b: int = B[_side(sd) + "Arm"]
	var u0 := (sk.get_bone_global_rest(B[_side(sd) + "ForeArm"]).origin - sk.get_bone_global_rest(b).origin).normalized()
	var e0 := u0.cross(Vector3.BACK).normalized()
	var turn := sk.get_bone_global_pose(b).basis.orthonormalized() * sk.get_bone_global_rest(b).basis.orthonormalized().inverse()
	return (turn * e0).normalized()
func _rest(b: String) -> Vector3: return cur.rest_pos[b]
func _to_sk(pw: Vector3) -> Vector3: return sk.global_transform.affine_inverse() * pw  # world -> skeleton units
func _rot_about(b: String, pivot_sk: Vector3, axis: Vector3, deg: float) -> void:
	var g := _g(b)
	var r := Basis(axis.normalized(), deg_to_rad(deg))
	sk.set_bone_global_pose(B[b], Transform3D(r * g.basis, pivot_sk + r * (g.origin - pivot_sk)))
func _roll_on_edge(sd: int, deg: float) -> void:
	# roll the foot about the line through its heel and outer-ball sole points: both stay down, the inner side lifts
	var sp: PackedVector3Array = chk.get_sole_points()
	var heel := _to_sk(sp[sd * 4 + 0]); var outer := _to_sk(sp[sd * 4 + 2])
	var ax := (outer - heel).normalized()
	var inner := _to_sk(sp[sd * 4 + 1])
	var test := Basis(ax, deg_to_rad(deg)) * (inner - heel)
	var sgn := 1.0 if test.y > (inner - heel).y else -1.0
	_rot(_side(sd) + "Foot", ax, deg * sgn)  # about the ankle: heel and outer ball move together
	cur["replace_at"] = 3
func _lean_bones_about_toes(deg: float) -> void:
	# lean the whole skeleton (root bone) forward about the line under the toe tips: the body leans, the node does not
	var sp: PackedVector3Array = chk.get_sole_points()
	var pivot := (_to_sk(sp[3]) + _to_sk(sp[7])) * 0.5
	_rot_about("Hips", pivot, Vector3.RIGHT, deg)
	cur["replace_at"] = 3
func _tilt_about_toes(deg: float) -> void:
	# tilt the whole body node forward about the line under the toe tips
	var x := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(deg)), Vector3.ZERO)
	var pivot := Vector3(0, 0.0, 0.17)
	var xf: Transform3D = base_xf
	var pv: Vector3 = xf * pivot
	body.transform = Transform3D(xf.basis.rotated(xf.basis.x.normalized(), deg_to_rad(deg)), pv + (xf.origin - pv).rotated(xf.basis.x.normalized(), deg_to_rad(deg)))
func _fold_waist(deg: float) -> void:
	# fold forward at the hips (pelvis and everything above it), the legs set back to vertical, then the legs tilted
	# forward so the feet come under the centre of mass ("hips pushed back")
	_rot("Hips", Vector3.RIGHT, deg)
	for sd in [0, 1]: _rot(_side(sd) + "UpLeg", Vector3.RIGHT, -deg)
	cur["fold_iter"] = 0

func _read_all_zero() -> String:
	var d: Dictionary = chk.get_last()
	var bad := []
	for k in d.keys():
		if k.begins_with("sh_elev") or k.begins_with("pelvis_yaw") or k in ["com", "contact_L", "contact_R", "trunk_f", "trunk_s"]: continue
		var tol := 2.0 if (cur.variant == "A" and (k.begins_with("sh_") or k.begins_with("elbow") or k.begins_with("farm") or k.begins_with("wrist"))) else 0.5
		if abs(float(d[k])) > tol: bad.append("%s=%.2f" % [k, d[k]])
	return "" if bad.is_empty() else "not 0 at rest: " + str(bad)

func _expect_reading(ch: String, sd: int, val: float, geometric_ok: bool) -> String:
	var name := ch if sd < 0 else ch + ("_L" if sd == 0 else "_R")
	var base: float = cur.get("base_reading", {}).get(name, 0.0)
	var v: float = chk.get_channel(name) - base
	if not geometric_ok: return "%s: the pose did not move the anatomical way (geometry check)" % name
	if abs(v - val) > 1.5: return "%s read %.2f, expected %.2f" % [name, v, val]
	return ""
func _expect_abs(ch: String, sd: int, val: float) -> String:
	var name := ch if sd < 0 else ch + ("_L" if sd == 0 else "_R")
	var base: float = cur.get("base_reading", {}).get(name, 0.0)
	var v: float = abs(chk.get_channel(name) - base)
	return "" if abs(v - val) <= 1.5 else "%s read %.2f, expected +-%.2f" % [name, v, val]

# ------------------------------------------------------------------------------------------------ runner
func _start_case() -> void:
	cur = cases[ci]
	fr = 0
	if chk: chk.queue_free(); chk = null
	if lim: lim.queue_free(); lim = null
	var sd: int = cur.side
	_base(cur.variant)
	# random yaw, a small random tilt, height by mode
	var yaw := rng.randf_range(-PI, PI)
	var tilt := Vector3(rng.randf_range(-0.05, 0.05), 0, rng.randf_range(-0.05, 0.05))
	var on_ground: bool = cur.mode.begins_with("ground")
	if on_ground: tilt = Vector3.ZERO
	var b := Basis(Vector3.UP, yaw) * Basis.from_euler(tilt)
	var y := 0.0 if on_ground else 0.6
	base_xf = Transform3D(b, Vector3(rng.randf_range(-5, 5), y, rng.randf_range(-5, 5)))
	body.transform = base_xf
	body.reset_physics_interpolation()  # a new case is a teleport, not motion
	chk = ClassDB.instantiate("StudyCheck")
	chk.set_seed(int(args.seed))
	chk.set_label(cur.name)
	chk.set_physics_rules(cur.mode in ["ground_physics", "ground_all"])
	chk.set_contact_rules(cur.mode in ["ground_contact", "ground_all"])
	if ClassDB.class_exists("FinalLimiter") and cur.expect.size() > 0:
		lim = ClassDB.instantiate("FinalLimiter")
		lim.name = "FinalLimiter"
		sk.add_child(lim)
	sk.add_child(chk)
	cur["base_reading"] = {}
	var rp := {}
	for k in B.keys(): rp[k] = _p(k)
	cur["rest_pos"] = rp
	cur["reset_at"] = 13 if cur.name.begins_with("trunk folded") else (6 if cur.mode.begins_with("ground") else 3)
	cur.setup.call(sd)

func _frame():
	if ci < 0 and fps == 60: fps = int(round(1.0 / max(root.get_process_delta_time(), 1e-4)))
	if ci < 0 or fr >= cur.frames:
		if ci >= 0: _end_case()
		ci += 1
		if ci >= cases.size():
			_report(); return
		_start_case()
		return
	fr += 1
	if fr == 1 and cur.has("fold_iter"): pass
	if cur.has("fold_iter") and fr >= 3 and fr <= 12:
		# move the feet under the centre of mass: tilt both legs forward until the CoM is over the feet's middle
		var sole: PackedVector3Array = chk.get_sole_points()
		var mid := Vector3.ZERO
		for k in [0, 1, 2, 4, 5, 6]: mid += sole[k]
		mid /= 6.0
		var com: Vector3 = chk.get_com()
		var fwd := (body.global_transform.basis * Vector3.BACK).normalized()
		var off := (com - mid).dot(fwd)
		var d := -rad_to_deg(off / 0.85) * 0.9
		for sd in [0, 1]:
			_rot(_side(sd) + "UpLeg", Vector3.RIGHT, d)
			_rot(_side(sd) + "Foot", Vector3.RIGHT, -d)  # soles stay flat
		var lo := 1e9
		for p in chk.get_sole_points(): lo = min(lo, p.y)
		body.position.y -= lo + 0.002
		body.reset_physics_interpolation()
	if cur.mode.begins_with("ground") and fr == 2 and not cur.has("fold_iter"):
		# the lowest sole point 2 mm into the ground (the rest sole is not flat: heel 0.9, balls 0.2-0.5 cm up)
		var lo := 1e9
		for p in chk.get_sole_points(): lo = min(lo, p.y)
		body.position.y -= lo + 0.002
		base_xf.origin.y = body.position.y
		body.reset_physics_interpolation()
	if cur.per_frame.is_valid(): cur.per_frame.call(cur.side, fr)
	if cur.get("replace_at", -1) == fr:
		var lo2 := 1e9
		for p in chk.get_sole_points(): lo2 = min(lo2, p.y)
		cur["replace_pending"] = true
	if cur.get("replace_pending", false) and fr == cur.get("replace_at", -1) + 1:
		var lo3 := 1e9
		for p in chk.get_sole_points(): lo3 = min(lo3, p.y)
		body.position.y -= lo3 + 0.002
		body.reset_physics_interpolation()
		cur["replace_pending"] = false
	if fr == cur.reset_at:
		chk.reset()  # judge the settled pose only (placing the body for the case is a teleport, not motion)

func _end_case() -> void:
	chk.flush()
	var r: Dictionary = chk.get_report()
	var fired: Array = r.rules.keys()
	var problems := []
	if not r.setup_ok: problems.append("setup failed: " + str(r.setup_error))
	for e in cur.expect:
		if not fired.has(e): problems.append("did not fire " + e)
	for f in fired:
		if not cur.expect.has(f) and not cur.allowed.has(f): problems.append("also fired %s (worst %.2f, %s)" % [f, r.rules[f].worst, r.rules[f].side])
	# the side reported must be the side posed (joint rules)
	for e in cur.expect:
		if fired.has(e):
			var s: String = r.rules[e].side
			if s in ["L", "R"] and s != ("L" if cur.side == 0 else "R") and not cur.name.contains("(both feet)"): problems.append("%s reported on side %s" % [e, s])
	if cur.check.is_valid():
		var m: String = cur.check.call(cur.side)
		if m != "": problems.append(m)
	if lim:
		var c := int(lim.get_clamp_count()) if lim.has_method("get_clamp_count") else -1
		if c <= 0: problems.append("FinalLimiter did not count a clamp")
	var tag := "%s [%s, %s]" % [cur.name, "L" if cur.side == 0 else "R", cur.variant]
	if problems.is_empty(): results.append("  ok    " + tag)
	else:
		fails += 1
		results.append("  FAIL  " + tag + ": " + "; ".join(problems))

func _report() -> void:
	fps = int(round(1.0 / max(root.get_process_delta_time(), 1e-4)))
	var lines := PackedStringArray()
	lines.append("MUTATION TESTS (study 9.2), %d cases, %d fps, seed %s, limiter: %s" % [cases.size(), fps, args.seed, "FinalLimiter" if ClassDB.class_exists("FinalLimiter") else "none"])
	lines.append_array(results)
	lines.append("MUTATION RESULT " + ("PASS" if fails == 0 else "FAIL (%d of %d cases)" % [fails, cases.size()]))
	for l in lines: print(l)
	if args.out != "":
		var f := FileAccess.open(args.out, FileAccess.WRITE)
		if f:
			for l in lines: f.store_line(l)
			f.close()
	quit(0 if fails == 0 else 1)
