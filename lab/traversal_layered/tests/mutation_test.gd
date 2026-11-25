## Study v2 9.2: every check must be able to fail. Poses player_v3's skeleton directly (layers and limiter off) with known
## broken poses and checks that the right rule of the C++ validator (PoseCheck) fires, with nothing unexpected, on both
## sides, in the rig's rest, an A-pose and a T-pose variant, at a random root yaw, a random root tilt and random hip
## rotation. Also: each joint axis reads 0 at rest, +30 the anatomical way (defined by geometry), -10 the other way.
## Prints PASS / FAIL per case and "RESULT PASS" only if all pass.
##   godot --headless --path . -s tests/mutation_test.gd
extends SceneTree

var body: Node3D
var sk: Skeleton3D
var chk  # PoseCheck
var fails := 0
var cases := 0
var rest_glob := []          # skeleton-space global rest per bone
var ground_y := 0.0
var B := {}
var rng := RandomNumberGenerator.new()

func bone(n: String) -> int:
	return sk.find_bone(n)

func gp(b: int) -> Transform3D:
	return sk.get_bone_global_pose(b)

## rotate bone b (and so its children) by `deg` about a skeleton-space axis, about the bone's own origin
func rot(b: int, axis: Vector3, deg: float) -> void:
	var t := gp(b)
	t.basis = Basis(axis.normalized(), deg_to_rad(deg)) * t.basis
	sk.set_bone_global_pose(b, t)

## rotate bone b about an arbitrary pivot (skeleton space)
func rot_about(b: int, axis: Vector3, deg: float, pivot: Vector3) -> void:
	var t := gp(b)
	var r := Basis(axis.normalized(), deg_to_rad(deg))
	t.basis = r * t.basis
	t.origin = pivot + r * (t.origin - pivot)
	sk.set_bone_global_pose(b, t)

func reset_pose() -> void:
	sk.reset_bone_poses()
	body.transform = Transform3D()
	chk.reset()
	chk.set_frame_input(0, 0.0, Vector3.ZERO, false, false, false, false)

## pelvis axes in skeleton space (follow a tilted / yawed root)
func pel_left() -> Vector3: return (gp(B.hips).basis * rest_glob[B.hips].basis.inverse() * Vector3(1, 0, 0)).normalized()
func pel_up() -> Vector3: return (gp(B.hips).basis * rest_glob[B.hips].basis.inverse() * Vector3(0, 1, 0)).normalized()
func pel_fwd() -> Vector3: return (gp(B.hips).basis * rest_glob[B.hips].basis.inverse() * Vector3(0, 0, 1)).normalized()
func thigh_dir(s: int) -> Vector3: return (gp(B.lo[s]).origin - gp(B.up[s]).origin).normalized()
func shin_dir(s: int) -> Vector3: return (gp(B.foot[s]).origin - gp(B.lo[s]).origin).normalized()
## the knee hinge carried by the thigh (as body.cpp captures it)
var hinge_local := [Vector3.ZERO, Vector3.ZERO]
func hinge(s: int) -> Vector3: return (gp(B.up[s]).basis * hinge_local[s]).normalized()

## anatomical "lateral" for side s (+left for the left leg) in skeleton space
func lat(s: int) -> Vector3: return pel_left() * (1.0 if s == 0 else -1.0)

# ---------------- poses (geometry-defined) ----------------
func hip_flex(s: int, deg: float) -> void:    # + = knee forward
	rot(B.up[s], pel_left(), -deg)
func knee_bend(s: int, deg: float) -> void:   # + = ankle goes behind the hip-knee line
	rot(B.lo[s], hinge(s), deg)
func hip_rotate(s: int, deg: float) -> void:  # + = knee turned outward
	# rotating about the thigh line (pointing down) by +a turns the knee's front toward body-right
	var sgn := -1.0 if s == 0 else 1.0
	rot(B.up[s], thigh_dir(s), deg * sgn)
func hip_abduct(s: int, deg: float) -> void:  # + = away from the middle
	rot(B.up[s], pel_fwd(), deg * (1.0 if s == 0 else -1.0))
func shin_out_of_plane(s: int, deg: float) -> void:
	rot(B.lo[s], pel_fwd(), deg)
func ankle_dorsi(s: int, deg: float) -> void: # + = toes up
	var a := hinge(s)
	rot(B.foot[s], a, -deg)
func foot_roll_outer(s: int, deg: float, edge := false) -> void: # + = onto the outer edge (inversion), about F
	chk.measure_now()
	var inv := skg().affine_inverse()
	var heel: Vector3 = inv * chk.get_sole_point(s, 0)
	var mid: Vector3 = inv * ((chk.get_sole_point(s, 1) + chk.get_sole_point(s, 2)) * 0.5)
	var bout: Vector3 = inv * chk.get_sole_point(s, 2)
	var F := ((bout if edge else mid) - heel).normalized()   # edge: about the heel - outer ball line (both stay level)
	rot(B.foot[s], F, -deg if s == 0 else deg)
func foot_twist_out(s: int, deg: float) -> void:  # + = toes out
	rot(B.foot[s], -shin_dir(s), deg if s == 0 else -deg)
func lumbar_flex(deg: float) -> void:
	rot(B.spine_low, pel_left(), deg)
func neck_turn(deg: float) -> void:
	rot(B.head, pel_up(), deg)
func elbow_bend(s: int, deg: float) -> void:   # + = forearm toward the arm's front (palm side, T-pose palms down)
	var u := (gp(B.farm[s]).origin - gp(B.arm[s]).origin).normalized()
	var e := u.cross(pel_fwd()).normalized()
	if e.cross(u).dot(pel_fwd()) < 0: e = -e
	rot(B.farm[s], e, deg)

# ---------------- variants ----------------
func apply_variant(v: String) -> void:
	match v:
		"rest": pass
		"apose":
			for s in 2: rot(B.arm[s], pel_fwd(), -30.0 if s == 0 else 30.0)
		"tpose":
			for s in 2: rot(B.arm[s], pel_fwd(), 18.0 if s == 0 else -18.0)
		"yaw":
			var y := rng.randf_range(-180, 180)
			body.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(y)), Vector3.ZERO)
		"tilt":
			var ax := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
			rot(B.hips, ax, rng.randf_range(8, 20))
		"hiprot":
			for s in 2: hip_rotate(s, rng.randf_range(-15, 15))

const VARIANTS := ["rest", "apose", "tpose", "yaw", "tilt", "hiprot"]
# rules a variant itself may change (contacts, lean, the rotated hip) and so are not compared under it
const CONTACT_RULES := ["CONTACT_SINK", "CONTACT_HOVER", "SOLE_ROLL", "KNEE_OVER_TOE", "TRUNK_LEAN"]

func fired() -> Array:
	var r := []
	for x in chk.check_static_now(): if not r.has(x): r.append(x)
	return r

func expect(name: String, must: Array, got: Array, allowed: Array = []) -> void:
	cases += 1
	var ok := true
	for m in must: if not got.has(m): ok = false
	for g in got: if not must.has(g) and not allowed.has(g): ok = false
	if not ok: fails += 1
	print(("PASS " if ok else "FAIL ") + name + "  must=" + str(must) + " got=" + str(got))

func near(name: String, got: float, want: float, tol := 2.0) -> void:
	cases += 1
	var ok: bool = abs(got - want) <= tol
	if not ok: fails += 1
	print(("PASS " if ok else "FAIL ") + "%s read %.1f want %.1f" % [name, got, want])

func _initialize():
	rng.seed = 1234
	body = load("res://body/player_v3.glb").instantiate()
	root.add_child(body)
	sk = body.get_node("Armature/Skeleton3D")
	chk = ClassDB.instantiate("PoseCheck")
	sk.add_child(chk)
	chk.set_active(false)  # stepped by hand below
	await process_frame
	B = {"hips": bone("Hips"), "spine_low": bone("Spine02"), "chest": bone("Spine"), "head": bone("Head"),
		"up": [bone("LeftUpLeg"), bone("RightUpLeg")], "lo": [bone("LeftLeg"), bone("RightLeg")],
		"foot": [bone("LeftFoot"), bone("RightFoot")], "toe": [bone("LeftToeBase"), bone("RightToeBase")],
		"arm": [bone("LeftArm"), bone("RightArm")], "farm": [bone("LeftForeArm"), bone("RightForeArm")],
		"hand": [bone("LeftHand"), bone("RightHand")]}
	for i in sk.get_bone_count(): rest_glob.append(sk.get_bone_global_rest(i))
	for s in 2:
		var t: Vector3 = (rest_glob[B.lo[s]].origin - rest_glob[B.up[s]].origin).normalized()
		var a := (Vector3(1, 0, 0) - t * t.dot(Vector3(1, 0, 0))).normalized()
		hinge_local[s] = rest_glob[B.up[s]].basis.orthonormalized().inverse() * a
	reset_pose()
	if not chk.is_model_ok():
		print("FAIL body model: ", chk.get_model_error()); print("RESULT FAIL"); quit(); return
	# the ground under the rest soles
	chk.measure_now()
	var lo := 1e9
	for s in 2: for k in 4: lo = min(lo, chk.get_sole_point(s, k).y)
	ground_y = lo
	chk.set_flat_ground(true, ground_y)
	print("sole points (rest, left): ", [chk.get_sole_point(0,0), chk.get_sole_point(0,1), chk.get_sole_point(0,2), chk.get_sole_point(0,3)], " ground ", ground_y)

	# ---- rest: nothing at all ----
	reset_pose()
	chk.set_frame_input(0, 0.0, Vector3.ZERO, true, true, false, false)
	expect("rest pose, standing, planted", [], fired())

	# ---- axis readings (rest 0, +30, -10) in every variant ----
	var axes := [
		["knee_flex", func(s, d): knee_bend(s, d), true],
		["hip_flex", func(s, d): hip_flex(s, d), true],
		["hip_abd", func(s, d): hip_abduct(s, d), true],
		["hip_rot", func(s, d): hip_rotate(s, d), true],
		["ankle_dorsi", func(s, d): ankle_dorsi(s, d), true],
		["ankle_inv", func(s, d): foot_roll_outer(s, d), true],
		["foot_abd", func(s, d): foot_twist_out(s, d), true],
		["elbow_flex", func(s, d): elbow_bend(s, d), true],
		["lumbar_flex", func(s, d): lumbar_flex(d), false],
		["neck_turn", func(s, d): neck_turn(d), false],
	]
	for v in VARIANTS:
		for ax in axes:
			for s in (2 if ax[2] else 1):
				var key: String = ax[0] + (("_l" if s == 0 else "_r") if ax[2] else "")
				if v == "hiprot" and ax[0] == "hip_rot": continue
				reset_pose(); apply_variant(v)
				var base: float = chk.measure_now()[key]
				if v == "rest": near("%s %s rest" % [v, key], base, 0.0, 0.5)
				for want in [30.0, -10.0]:
					reset_pose(); apply_variant(v)
					if ax[0] == "knee_flex": knee_bend(s, 40); base = chk.measure_now()[key]  # bend first so -10 stays a bend
					var b0: float = chk.measure_now()[key]
					ax[1].call(s, want)
					var got: float = chk.measure_now()[key] - b0
					if ax[0] == "neck_turn": got = abs(got); want = abs(want)  # neck turn has no anatomical sign
					near("%s %s %+.0f" % [v, key, want], got, want, 2.5)

	# ---- broken poses (9.2 table) ----
	for v in VARIANTS:
		var allow: Array = CONTACT_RULES if v in ["tilt", "yaw"] else []
		for s in 2:
			var sd := "L" if s == 0 else "R"
			reset_pose(); apply_variant(v); hip_flex(s, 30); knee_bend(s, 30); knee_bend(s, -50)
			expect("%s %s knee -20 on a bent leg" % [v, sd], ["KNEE_FLEX_MIN"], fired(), allow)
			reset_pose(); apply_variant(v); hip_flex(s, 30); knee_bend(s, 30)
			expect("%s %s knee +30" % [v, sd], [], fired(), allow)
			if v != "hiprot":
				reset_pose(); apply_variant(v); knee_bend(s, 40); hip_rotate(s, -120)
				expect("%s %s knee +40, thigh 120 inward" % [v, sd], ["HIP_ROTATION"], fired(), allow + ["KNEE_VARUS"])
			reset_pose(); apply_variant(v); hip_flex(s, 30); knee_bend(s, 40); shin_out_of_plane(s, 15)
			expect("%s %s shin 15 out of plane" % [v, sd], ["KNEE_VARUS"], fired(), allow + ["KNEE_TWIST"])
			reset_pose(); apply_variant(v); foot_roll_outer(s, 40)
			expect("%s %s foot rolled 40 onto its outer edge" % [v, sd], ["ANKLE_INVERSION"], fired(), allow + ["CONTACT_SINK"])
			reset_pose(); apply_variant(v); foot_twist_out(s, 60)
			expect("%s %s foot twisted 60 out" % [v, sd], ["FOOT_TWIST"], fired(), allow + ["CONTACT_SINK"])
			reset_pose(); apply_variant(v); ankle_dorsi(s, 30)
			expect("%s %s ankle 30 up, straight knee" % [v, sd], ["ANKLE_DORSI"], fired(), allow + ["CONTACT_SINK"])
			reset_pose(); apply_variant(v); hip_flex(s, 20); knee_bend(s, 45); ankle_dorsi(s, 30)
			expect("%s %s ankle 30 up, knee 45" % [v, sd], [], fired(), allow)
			reset_pose(); apply_variant(v); hip_flex(s, 110)
			expect("%s %s hip 110 forward, straight knee" % [v, sd], ["HIP_FLEX_COUPLED"], fired(), allow)
		# a foot planted on flat ground, rolled 20 onto its outer edge (inversion 20, inside the joint limit), the ground
		# under its lowest sole point (2+ points down) - rest root only
		if v == "rest" or v == "apose" or v == "tpose":
			for s in 2:
				reset_pose(); apply_variant(v)
				foot_roll_outer(s, 20, true)
				chk.measure_now()
				var lo2 := 1e9
				for k in 4: lo2 = min(lo2, chk.get_sole_point(s, k).y)
				chk.set_flat_ground(true, lo2)
				var n_down := 0
				for k in 4: if chk.get_sole_point(s, k).y - lo2 < 0.01: n_down += 1
				chk.set_frame_input(0, 0.0, Vector3.ZERO, false, false, false, false)
				expect("%s %s planted foot rolled 20 (%d points down)" % [v, "LR"[s], n_down], ["SOLE_ROLL"], fired(), ["CONTACT_SINK"])
				chk.set_flat_ground(true, ground_y)
			reset_pose(); apply_variant(v)
			var h := gp(B.hips); h.origin.y -= 3.0; sk.set_bone_global_pose(B.hips, h)  # 3 cm (skeleton units are cm)
			expect("%s foot sunk 3 cm" % v, ["CONTACT_SINK"], fired(), [])
			# hand inside the chest
			reset_pose(); apply_variant(v)
			var tsk: Vector3 = (gp(B.up[0]).origin + gp(B.up[1]).origin) * 0.5 * 0.5 + gp(bone("neck")).origin * 0.5
			var sh := gp(B.arm[0]).origin
			var elbow_dir := (pel_fwd() * 0.9 - pel_up() * 0.4).normalized()
			var cur := (gp(B.farm[0]).origin - sh).normalized()
			var t := gp(B.arm[0]); t.basis = Basis(Quaternion(cur, elbow_dir)) * t.basis; sk.set_bone_global_pose(B.arm[0], t)
			var el := gp(B.farm[0]).origin
			var cur2 := (gp(B.hand[0]).origin - el).normalized()
			var t2 := gp(B.farm[0]); t2.basis = Basis(Quaternion(cur2, (tsk - el).normalized())) * t2.basis; sk.set_bone_global_pose(B.farm[0], t2)
			expect("%s hand inside the chest" % v, ["SELF_INTERSECT"], fired(), ["ELBOW", "SHOULDER_CONE", "SHOULDER_TWIST", "FOREARM_TWIST", "WRIST"])

	# ---- time-based cases (step_manual runs the full per-frame pipeline) ----
	seq_case("knee snapped 40 deg in one frame at 30 fps", "snap", ["POSE_DISCONTINUITY"], 1.0 / 30.0, 0, ["JOINT_SPEED", "CONTACT_HOVER"])
	seq_case("hips dropped 5 cm in one frame (60 fps)", "drop", ["COM_DOWN_GT_G"], 1.0 / 60.0, 0, ["CONTACT_SINK", "POSE_DISCONTINUITY", "COM_ACCEL_V"])
	seq_case("planted foot moved 3 cm", "slide", ["FOOT_SLIDE"], 1.0 / 60.0, 0, ["COM_ACCEL_H", "LEAN_MISMATCH", "POSE_DISCONTINUITY"])
	seq_case("both feet down in the middle of a run", "none", ["RUN_DOUBLE_SUPPORT"], 1.0 / 60.0, 2, ["LEAN_MISMATCH"])
	seq_case("skeleton node tilted 40 deg (lean on the node)", "tilt", ["LEAN_MAX"], 1.0 / 60.0, 2,
		["LEAN_MISMATCH", "TRUNK_LEAN", "TRUNK_BEND", "SOLE_ROLL", "CONTACT_SINK", "CONTACT_HOVER", "RUN_DOUBLE_SUPPORT"])
	seq_case("whole body leaning 50 deg, no acceleration", "lean50", ["LEAN_MAX", "LEAN_MISMATCH"], 1.0 / 60.0, 2,
		["TRUNK_LEAN", "TRUNK_BEND", "SOLE_ROLL", "CONTACT_SINK", "CONTACT_HOVER", "RUN_DOUBLE_SUPPORT", "HEAD_LEVEL"])
	seq_case("trunk folded 60 at the waist, hips back over the feet", "fold", ["TRUNK_LEAN", "TRUNK_BEND"], 1.0 / 60.0, 2,
		["RUN_DOUBLE_SUPPORT", "HIP_FLEX_COUPLED", "CONTACT_HOVER", "CONTACT_SINK", "SOLE_ROLL", "LEAN_MISMATCH"])
	seq_case("clean standing, 1.5 s, nothing", "none", [], 1.0 / 60.0, 0, [])

	print("cases %d, failed %d" % [cases, fails])
	print("RESULT PASS" if fails == 0 else "RESULT FAIL")
	quit()

func fold_trunk(deg: float) -> void:
	# pelvis tilted forward about the hip centre, the legs turned back to where they were (= hip flexion); then the whole
	# figure turned back about the ankles until the centre of mass is over the feet, the feet kept flat
	var hc := (gp(B.up[0]).origin + gp(B.up[1]).origin) * 0.5
	var leg_basis := [gp(B.up[0]).basis, gp(B.up[1]).basis]
	rot_about(B.hips, Vector3(1, 0, 0), deg, hc)
	for s in 2:
		var t := gp(B.up[s]); t.basis = leg_basis[s]; sk.set_bone_global_pose(B.up[s], t)
	var ank := (gp(B.foot[0]).origin + gp(B.foot[1]).origin) * 0.5
	var foot_basis := [gp(B.foot[0]).basis, gp(B.foot[1]).basis]
	chk.measure_now()
	var cop_z: float = (chk.get_sole_point(0, 0).z + chk.get_sole_point(0, 1).z) * 0.5
	var lo := 0.0; var hi := 40.0
	for it in 24:
		var th := (lo + hi) * 0.5
		sk.reset_bone_poses()
		rot_about(B.hips, Vector3(1, 0, 0), deg, hc)
		for s in 2:
			var t := gp(B.up[s]); t.basis = leg_basis[s]; sk.set_bone_global_pose(B.up[s], t)
		rot_about(B.hips, Vector3(1, 0, 0), -th, ank)
		for s in 2:
			var t := gp(B.foot[s]); t.basis = foot_basis[s]; sk.set_bone_global_pose(B.foot[s], t)
		var com: Vector3 = chk.measure_now()["com"]
		if com.z > cop_z: lo = th
		else: hi = th
	print("   fold: legs turned back %.1f deg, trunk lean %.1f" % [(lo + hi) * 0.5, chk.measure_now()["trunk_fwd"]])

func poke(kind: String, i: int) -> void:
	match kind:
		"snap":
			if i == 30: knee_bend(0, 40)
		"drop":
			if i == 40:
				var h := gp(B.hips); h.origin.y -= 5.0; sk.set_bone_global_pose(B.hips, h)
		"slide":
			if i >= 40 and i < 46:
				var h := gp(B.hips); h.origin.z += 0.5; sk.set_bone_global_pose(B.hips, h)
		"tilt":
			if i == 0:
				# tilt the node 40 deg forward about the heels' line (the heels stay on the ground)
				chk.measure_now()
				var hz: float = chk.get_sole_point(0, 0).z
				var r := Basis(Vector3(1, 0, 0), deg_to_rad(40))
				body.transform = Transform3D(r, Vector3(0, 0, hz) - r * Vector3(0, 0, hz))
		"lean50":
			if i == 0: body.transform = Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(50)), Vector3.ZERO)
		"fold":
			if i == 0: fold_trunk(60.0)

## state: 0 idle, 2 run loop at 4 m/s
func seq_case(name: String, kind: String, must: Array, dt: float, state: int, allowed: Array = []) -> void:
	reset_pose()
	var got := []
	var spd := 4.0 if state == 2 else 0.0
	for i in 90:
		poke(kind, i)
		chk.set_frame_input(state, spd, Vector3(0, 0, spd), true, true, false, false)
		for r in chk.step_manual(dt): if not got.has(r): got.append(r)
	expect(name, must, got, allowed)
	if not must.is_empty() and not got.has(must[0]): print("   log: ", chk.get_log().slice(0, 6))

func skg() -> Transform3D:
	return body.transform * (sk.get_parent() as Node3D).transform * sk.transform
