extends SceneTree
## Makes the animation library the AnimationTree plays (traversal/character/library.res) from the baked clips
## (traversal/character/clips/*.res). The study, Part 2: "Import each clip file as an Animation Library ... Set
## `root_motion_track` to the `Root` bone", and the root bone "takes ground-plane travel and turning from the hips,
## leave the hips' vertical movement in the hips".
##
## For every clip: a rotation track per bone, the hips' position (what is left when the root has taken the travel:
## height, sway and the to-and-fro of a stride), and the Root bone's own track (travel over the ground, and turning).
##   - a loop: the root travels in a straight line at an even speed (the study's Stage 2: "steady forward travel with
##     no side-to-side wobble"), and the clip is turned so that line is straight ahead;
##   - any other clip: the root takes the hips' travel along the clip's own line of travel, and the hips' turning.
## Mirror images ("_M") are made for the clips that exist for one side only.
## Run:  godot --headless --path traversal_lab -s res://tools/build_library.gd

const DIR := "res://traversal/character/clips/"
const MODEL := "res://traversal/character/player_v4_rooted.scn"
const OUT := "res://traversal/character/library.res"
const SKEL := "Skeleton3D"
const MIRRORED := ["Female_Stop_Walking", "Run_To_Stop", "Left_Turn_90", "Walking_Turn_180", "Running_Turn_180", "Female_Start_Walking", "Idle_To_Sprint",
		"KM_Stop_Walk", "KM_Walk_To_Run", "KM_Run_To_Walk"]
# Starts, stops and changes of gait are chosen "by which foot is forward" (the study, Stage 5): for these clips how far
# the left ankle is ahead of the right, frame by frame, is noted on the animation ("lead", metres).
const LEADS := ["Female_Start_Walking", "Female_Stop_Walking", "Idle_To_Sprint", "KM_Walk_To_Run", "KM_Run_To_Walk", "KM_Stop_Walk", "KM_Slope_Down_Start", "KM_Slope_Down_Stop", "KM_Start_Walk",
		"KM_Walk", "KM_Run", "KM_Slope_Up_Start", "KM_Slope_Up_Stop"]
const TURN_LEAST_DEG := 20.0        # a clip that turns less than this is not a turning clip: its root does not turn
# In the air the body does the rising and the falling (the study: the body "alone decides where the character is"), so
# the clip's own rise is taken out: between leaving the ground and landing the hips keep at most their take-off height.
# [leaves the ground, lands] in seconds, measured on the clips.
const AIR := {"Jump": [0.80, 1.30], "Running_Jump": [0.10, 0.67]}
# Landing clips begin high up, where their fall began: the hips are never above standing height.
const GROUNDED := ["Falling_To_Landing", "Hard_Landing"]
# Ledge clips (step off, fall, land) are played on the spot: the body does the travelling and the falling, so the hips
# keep only their height above the clip's own landing ground.
const LEDGE := ["KM_Ledge_Walk_Off", "KM_Ledge_Run_Off"]
# The walk's hips, brought to the study: "The pelvis moves only a few degrees at normal walking speed: about 3 degrees
# of tilt, 8.5 of side drop and 12 of rotation in total range", and the body "rises and falls 2.7 to 4.8 cm in walking
# ... side-to-side sway shrinks from 7.0 to 3.9 cm as speed rises". Measured on him, this take had 6.2 degrees of tilt,
# 12.0 of side drop, 8.2 of rotation, 5.1 cm of rise and fall and 6.4 cm of sway (Yasin, 26 Nov: "HIPS SHAKE TOO
# MUCH"). Each is scaled about its own average by study figure / measured figure; the legs are then fitted to the
# ground by the leg IK as always. [tilt, side drop, rotation, rise and fall, sway]
# Stair clips climb or descend their own stairs. The body does the climbing, so the clip's climb is taken out of its
# hips, and the hips are set at their own height above the clip's stairs; what is left under the feet is those
# stairs' slope, which is noted on the animation ("slope": rise per metre forward; "reach": how far ahead of the hips
# the left foot comes down) for foot_place.gd to take out, so the feet are fitted to the real steps under him.
const STAIRS := ["Ascending_Stairs", "KM_Stairs_Run_Up_D", "KM_Stairs_Walk_Down", "KM_Stairs_Run_Down"]
# Steep ground (outside the study, kept at Yasin's word): his own two Kimodo takes, which climb and descend their own
# slopes. Treated as the stair clips are: the climb out of the hips, the slope of the take's own ground noted.
const SLOPES := ["KM_Climb_Hard", "KMY_Down_Hands_Balance_Long", "KM_Slope_Down_Start", "KM_Slope_Down_Stop", "KM_Slope_Up_Start", "KM_Slope_Up_Stop"]
# (The walk take in use since 26 Nov, Kimodo walk_b_s1, meets the study's pelvis tilt, side drop,
# rotation and sway as it is; only its rise and fall, 6.2 cm, is brought into the study's 2.7 to 4.8 cm.)
# A take edited a little to meet the study's joint lines (Yasin, 26 Nov: "why dont you spend any effort on making the
# clips fit into the rules by editing the clips a bit"). Each figure is study figure against what the audit measured
# on the take; see _fit.
#   pelvis: degrees the pelvis is tipped back, the trunk and legs left where they were
#   knee: [from, share]: knee bend beyond `from` degrees is kept at this share
#   ankle: [toes-up share, toes-down share] of the foot's own bend at the ankle
#   toe: share of the toes' bend
# KM_Walk (Kimodo take walk_b_s1), measured by the audit before these edits: hip flexion 35.2 and extension 4.6
# degrees (the study: 25 and 10), knee 52.9 at toe-off and 67.2 in swing (40 and 60), ankle 25.9 toes-down (20), big
# toe 31.1 (at least 35). After them: 27.4 and 14.3; 43.0 and 54.9; 19.8; 37.1.
const FIT := {"KM_Walk": {"pelvis": 7.7, "knee": [20.0, 0.7], "ankle": [1.0, 0.8], "toe": 1.2, "arms": 0.04},
		# (arms: each arm forward with the opposite leg 90 % of the time as the take came, on the study's bar of 90;
		# moved 0.04 of a stride later it is 98 %)
		# Yasin's downhill take: the ankle went 55.8 degrees toes-down at its most, the study's limit is 55
		"KMY_Down_Hands_Balance_Long": {"ankle": [1.0, 0.9]},
		# The run at 4.5 m/s is a blend of these two (the jog: Kimodo take run_a_s1; the fast run: Mixamo's Running).
		# Measured on the blend before the edits: knee 123.6 degrees in swing (the study: 94 to 119), ankle 27.5
		# toes-down (23.2), hip extension 13.3 (11.8), each arm forward with the opposite leg 78 % of the time (90 or
		# more). After: 114.4, 22.2, 12.7, 96 %. Both get the same edits.
		# Turns on the spot: the body turns at 180 degrees a second (270 out of a run) and the clips' heads swing
		# ahead of it; together the head peaked at 684 degrees a second in the audit, the study: "the head peaking
		# at 137 to 272 degrees a second". The head's and neck's own turning is kept at this share.
		"Walking_Turn_180": {"head": 0.3}, "Left_Turn_90": {"head": 0.3}, "Running_Turn_180": {"head": 0.3},
		"KM_Run": {"pelvis": -1.6, "knee": [60.0, 0.85], "ankle": [1.0, 0.8], "arms": 0.15},
		"Running": {"pelvis": -1.6, "knee": [60.0, 0.85], "ankle": [1.0, 0.8], "arms": 0.15}}
const FOOT_UP_SIGN := 1.0       # which way round the foot bone's side-to-side line counts as toes up (found by trying both)
# The run's rise and fall: "In running the bob is 8 to 9.5 cm"; the blend of the two run clips had 6.0 cm.
const HIPS := {"KM_Walk": [1.0, 1.0, 1.0, 4.2 / 6.2, 1.0], "KM_Run": [1.0, 1.0, 1.0, 8.75 / 6.0, 1.0], "Running": [1.0, 1.0, 1.0, 8.75 / 6.0, 1.0]}


func _initialize() -> void:
	var model: Node = (load(MODEL) as PackedScene).instantiate()
	var sk: Skeleton3D = model.get_node(SKEL)
	var lib := AnimationLibrary.new()
	var parents := PackedInt32Array()
	var rest: Array[Quaternion] = []
	var pair := PackedInt32Array()
	var names := PackedStringArray()
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".res"):
			names.append(f.get_basename())
	names.sort()
	var first: Resource = load(DIR + names[0] + ".res")
	var bones: PackedStringArray = first.get(&"bones")
	for i in bones.size():
		var b := sk.find_bone(bones[i])
		var p := sk.get_bone_parent(b)
		parents.append(bones.find(sk.get_bone_name(p)) if p >= 0 else -1)
		rest.append(sk.get_bone_global_rest(b).basis.get_rotation_quaternion())
		var other := bones[i].replace("Left", "#").replace("Right", "Left").replace("#", "Right")
		pair.append(bones.find(other) if bones.find(other) >= 0 else i)
	var stand := sk.get_bone_rest(sk.find_bone("mixamorig_Hips")).origin
	for n in names:
		var c: Resource = load(DIR + n + ".res")
		var made := _animation(c, n, stand.y)
		if FIT.has(n) and not OS.get_cmdline_user_args().has("--raw-hips"):
			_fit(made, FIT[n], sk, n)
		if STAIRS.has(n) or SLOPES.has(n):
			_stairs(made, c, sk)
		if LEADS.has(n):
			made.set_meta(&"lead", _lead(made, sk))
		lib.add_animation(n, made)
		if MIRRORED.has(n):
			var other := _animation(c.call(&"mirrored", parents, rest, pair), n, stand.y)
			if FIT.has(n):
				_fit(other, FIT[n], sk, n)
			if LEADS.has(n):
				other.set_meta(&"lead", _lead(other, sk))
			lib.add_animation(n + "_M", other)
	# The study: "`deterministic` is on by default, so include a RESET animation": the pose every blend starts from
	var reset := Animation.new()
	reset.length = 0.001
	for b in sk.get_bone_count():
		var t := reset.add_track(Animation.TYPE_ROTATION_3D)
		reset.track_set_path(t, NodePath("%s:%s" % [SKEL, sk.get_bone_name(b)]))
		reset.rotation_track_insert_key(t, 0.0, sk.get_bone_rest(b).basis.get_rotation_quaternion())
	for bn: String in ["Root", "mixamorig_Hips"]:
		var t := reset.add_track(Animation.TYPE_POSITION_3D)
		reset.track_set_path(t, NodePath("%s:%s" % [SKEL, bn]))
		reset.position_track_insert_key(t, 0.0, sk.get_bone_rest(sk.find_bone(bn)).origin)
	lib.add_animation("RESET", reset)
	var err := ResourceSaver.save(lib, OUT, ResourceSaver.FLAG_COMPRESS)
	print("%s: %d animations; saved: %d" % [OUT, lib.get_animation_list().size(), err])
	quit(0 if err == OK else 1)


func _animation(c: Resource, name: String, stand_y: float) -> Animation:
	var a := Animation.new()
	var frames := int(c.get(&"frames"))
	var fps := float(c.get(&"fps"))
	var loop := bool(c.get(&"loop"))
	var bones: PackedStringArray = c.get(&"bones")
	var rot: PackedFloat32Array = c.get(&"rot")
	var hips: PackedVector3Array = c.get(&"hips")
	var yaw: PackedFloat32Array = c.get(&"yaw")
	var travel: Vector3 = c.get(&"travel")
	var n := bones.size()
	a.length = float(frames - 1) / fps
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	a.step = 1.0 / fps
	var total := Vector2(travel.x, travel.z).length()
	var dir := Vector3(travel.x, 0.0, travel.z) / total if total >= 0.02 else Vector3.ZERO
	# a loop is turned so that its line of travel is straight ahead (+Z in the model)
	var aim := Quaternion.IDENTITY
	if loop and total >= 0.02:
		aim = Quaternion(Vector3.UP, -atan2(dir.x, dir.z))
	var turning: bool = not loop and not yaw.is_empty() and absf(rad_to_deg(yaw[frames - 1])) >= TURN_LEAST_DEG
	var hips_i := bones.find("mixamorig_Hips")
	var t_root_p := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(t_root_p, NodePath("%s:Root" % SKEL))
	var t_root_r := a.add_track(Animation.TYPE_ROTATION_3D)
	a.track_set_path(t_root_r, NodePath("%s:Root" % SKEL))
	var t_hips_p := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(t_hips_p, NodePath("%s:mixamorig_Hips" % SKEL))
	var tracks := PackedInt32Array()
	for b in n:
		var t := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(t, NodePath("%s:%s" % [SKEL, bones[b]]))
		tracks.append(t)
	var start := Vector3(hips[0].x, 0.0, hips[0].z)
	# the hips' own turning, tilting and dropping through the clip, and their averages (for HIPS)
	# (`-- --raw-hips`: the take as it is, for auditioning a new take and measuring what its hips do)
	var shape: Array = [] if OS.get_cmdline_user_args().has("--raw-hips") else HIPS.get(name, [])
	for arg in OS.get_cmdline_user_args():       # for trying figures: -- --hips=KM_Run/1,1,1,1.4,1
		if arg.begins_with("--hips=%s/" % name):
			shape = Array(arg.trim_prefix("--hips=%s/" % name).split_floats(","))
	var mean_yaw := 0.0
	var mean_swing := Vector3.ZERO
	var mean_pos := Vector3.ZERO
	if not shape.is_empty():
		for f in frames - 1:
			var o := (f * n + hips_i) * 4
			var q := aim * Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3])
			var yw := _yaw_of(q)
			mean_yaw += yw / (frames - 1)
			mean_swing += _swing_of(q, yw) / (frames - 1)
			var u0 := float(f) / float(frames - 1)
			var l0 := aim * (Vector3(hips[f].x, 0.0, hips[f].z) - start - dir * (total * u0))
			mean_pos += Vector3(l0.x, hips[f].y, l0.z) / (frames - 1)
	var furthest := 0.0
	for f in frames:
		var time := float(f) / fps
		var u := float(f) / float(maxi(frames - 1, 1))
		var rel := Vector3(hips[f].x, 0.0, hips[f].z) - start
		var root_pos := Vector3.ZERO
		if total >= 0.02:
			root_pos = dir * (total * u) if loop else dir * rel.dot(dir)
			if LEADS.has(name):
				# a start or a stop: the root only ever goes forward. Where the hips rock back as he comes to
				# rest, that stays in the hips, over feet that do not move (taken by the root, it slid the planted
				# feet forward 2.5 cm after a stop: the audit's stop.walk_slide).
				furthest = maxf(furthest, rel.dot(dir))
				root_pos = dir * furthest
		var root_rot := Quaternion(Vector3.UP, yaw[f]) if turning else Quaternion.IDENTITY
		var local := root_rot.inverse() * (aim * (rel - root_pos))
		var y := hips[f].y
		if AIR.has(name) and time >= float(AIR[name][0]) and time <= float(AIR[name][1]):
			y = minf(y, hips[int(round(float(AIR[name][0]) * fps))].y)
		if GROUNDED.has(name):
			y = minf(y, stand_y)
		if LEDGE.has(name):
			y = minf(y - hips[frames - 1].y + stand_y, stand_y)
			local = Vector3.ZERO
			root_pos = Vector3.ZERO
		if not shape.is_empty():
			y = mean_pos.y + (y - mean_pos.y) * float(shape[3])
			local.x = mean_pos.x + (local.x - mean_pos.x) * float(shape[4])
		a.position_track_insert_key(t_root_p, time, aim * root_pos)
		a.rotation_track_insert_key(t_root_r, time, root_rot)
		a.position_track_insert_key(t_hips_p, time, Vector3(local.x, y, local.z))
		for b in n:
			var o := (f * n + b) * 4
			var q := Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3])
			if b == hips_i:
				q = (root_rot.inverse() * aim * q).normalized()
				if not shape.is_empty():
					var yw := _yaw_of(q)
					var sw := _swing_of(q, yw)
					var new_yaw := mean_yaw + (yw - mean_yaw) * float(shape[2])
					var new_sw := Vector3(mean_swing.x + (sw.x - mean_swing.x) * float(shape[0]), 0.0, mean_swing.z + (sw.z - mean_swing.z) * float(shape[1]))
					var turn := Quaternion(Vector3.UP, new_yaw)
					var lean_q := Quaternion(new_sw.normalized(), new_sw.length()) if new_sw.length() > 0.00001 else Quaternion.IDENTITY
					# the rest of the hips' own rotation (the bone's frame) is carried through unchanged
					var was := Quaternion(sw.normalized(), sw.length()) if sw.length() > 0.00001 else Quaternion.IDENTITY
					q = (lean_q * turn * (was * Quaternion(Vector3.UP, yw)).inverse() * q).normalized()
			a.rotation_track_insert_key(tracks[b], time, q)
	return a


## Small edits to a take's joint curves (see FIT). Every edit is made to the bone's own turn from its standing pose.
func _fit(a: Animation, how: Dictionary, sk: Skeleton3D, clip: String) -> void:
	var fit := {"pelvis": 0.0, "knee": [20.0, 1.0], "ankle": [1.0, 1.0], "toe": 1.0, "arms": 0.0, "head": 1.0, "trunk": 1.0}
	fit.merge(how.duplicate(true), true)
	for arg in OS.get_cmdline_user_args():       # for trying figures: -- --fit=KM_Walk/pelvis:6,knee:20:0.8,ankle:0.6:0.8,toe:1.2
		if arg.begins_with("--fit=%s/" % clip):
			for part in arg.trim_prefix("--fit=%s/" % clip).split(","):
				var v := part.split(":")
				if v.size() == 2:
					fit[v[0]] = float(v[1])
				elif v.size() == 3:
					fit[v[0]] = [float(v[1]), float(v[2])]
	var tr := func(bone: String) -> int: return a.find_track(NodePath("%s:mixamorig_%s" % [SKEL, bone]), Animation.TYPE_ROTATION_3D)
	var rest := func(bone: String) -> Quaternion: return sk.get_bone_rest(sk.find_bone("mixamorig_" + bone)).basis.get_rotation_quaternion()
	# the arms' swing moved along the clip by a share of the stride (+ = later), so each arm is forward with the
	# opposite leg (the study: "Each arm swings with the opposite leg")
	if float(fit["arms"]) != 0.0:
		var was: Animation = a.duplicate(true)
		for t in a.get_track_count():
			if a.track_get_type(t) != Animation.TYPE_ROTATION_3D:
				continue
			var bone := String(a.track_get_path(t)).get_slice(":", 1)
			var arm := false
			for part: String in ["Shoulder", "Arm", "ForeArm", "Hand"]:
				arm = arm or bone.begins_with("mixamorig_Left" + part) or bone.begins_with("mixamorig_Right" + part)
			if arm:
				for k in a.track_get_key_count(t):
					a.track_set_key_value(t, k, was.rotation_track_interpolate(t, fposmod(a.track_get_key_time(t, k) - a.length * float(fit["arms"]), a.length)))
	# the neck's and the head's own turning kept at a share (a turn clip whose head whips round ahead of the body)
	for group: Array in [["head", ["Neck", "Head"]], ["trunk", ["Spine", "Spine1", "Spine2"]]]:
		if float(fit[group[0]]) == 1.0:
			continue
		for bone: String in group[1]:
			var ht: int = tr.call(bone)
			var hr: Quaternion = rest.call(bone)
			for k in a.track_get_key_count(ht):
				var rel := (hr.inverse() * (a.track_get_key_value(ht, k) as Quaternion)).normalized()
				if rel.w < 0.0:
					rel = -rel
				a.track_set_key_value(ht, k, (hr * Quaternion.IDENTITY.slerp(rel, float(fit[group[0]]))).normalized())
	var hips_t: int = tr.call("Hips")
	var back := deg_to_rad(float(fit["pelvis"]))
	for k in a.track_get_key_count(hips_t):
		var time := a.track_get_key_time(hips_t, k)
		var q: Quaternion = a.track_get_key_value(hips_t, k)
		if back != 0.0:
			# tipped back about its own side-to-side line; what hangs from it (spine, both thighs) is turned the
			# other way by as much, so the trunk and the legs stay where the take has them
			var side_axis := (Quaternion(Vector3.UP, _yaw_of(q)) * Vector3(1.0, 0.0, 0.0)).normalized()
			var q2 := (Quaternion(side_axis, -back) * q).normalized()
			a.track_set_key_value(hips_t, k, q2)
			for child: String in ["Spine", "LeftUpLeg", "RightUpLeg"]:
				var ct: int = tr.call(child)
				var kk := a.track_find_key(ct, time, Animation.FIND_MODE_APPROX)
				a.track_set_key_value(ct, kk, (q2.inverse() * q * (a.track_get_key_value(ct, kk) as Quaternion)).normalized())
	for side: String in ["Left", "Right"]:
		var knee: Array = fit["knee"]
		var kt: int = tr.call(side + "Leg")
		var kr: Quaternion = rest.call(side + "Leg")
		for k in a.track_get_key_count(kt):
			var rel := (kr.inverse() * (a.track_get_key_value(kt, k) as Quaternion)).normalized()
			var bend := rad_to_deg(2.0 * acos(clampf(absf(rel.w), 0.0, 1.0)))
			if bend > float(knee[0]) and float(knee[1]) != 1.0:
				var want := float(knee[0]) + (bend - float(knee[0])) * float(knee[1])
				a.track_set_key_value(kt, k, (kr * Quaternion.IDENTITY.slerp(rel, want / bend)).normalized())
		var ankle: Array = fit["ankle"]
		var ft: int = tr.call(side + "Foot")
		var fr: Quaternion = rest.call(side + "Foot")
		for k in a.track_get_key_count(ft):
			var rel := (fr.inverse() * (a.track_get_key_value(ft, k) as Quaternion)).normalized()
			if rel.w < 0.0:
				rel = -rel
			# toes up or toes down: which way the foot is turned about its own side-to-side line
			var share := float(ankle[0]) if rel.x * FOOT_UP_SIGN > 0.0 else float(ankle[1])
			if share != 1.0:
				a.track_set_key_value(ft, k, (fr * Quaternion.IDENTITY.slerp(rel, share)).normalized())
		var tt: int = tr.call(side + "ToeBase")
		var trr: Quaternion = rest.call(side + "ToeBase")
		if float(fit["toe"]) != 1.0:
			for k in a.track_get_key_count(tt):
				var rel := (trr.inverse() * (a.track_get_key_value(tt, k) as Quaternion)).normalized()
				if rel.w < 0.0:
					rel = -rel
				a.track_set_key_value(tt, k, (trr * Quaternion.IDENTITY.slerp(rel, float(fit["toe"]))).normalized())


## How far the left ankle is ahead of the right through a clip (metres, one figure a frame).
func _lead(a: Animation, sk: Skeleton3D) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var t_hips := a.find_track(NodePath("%s:mixamorig_Hips" % SKEL), Animation.TYPE_POSITION_3D)
	var frames := int(round(a.length / a.step)) + 1
	for f in frames:
		var time := f * a.step
		var z := [0.0, 0.0]
		for k in 2:
			var x := Transform3D(Basis(_rot(a, "mixamorig_Hips", time)), a.position_track_interpolate(t_hips, time))
			for bn: String in ["UpLeg", "Leg", "Foot"]:
				var name := "mixamorig_%s%s" % [["Left", "Right"][k], bn]
				x = x * Transform3D(Basis(_rot(a, name, time)), sk.get_bone_rest(sk.find_bone(name)).origin)
			z[k] = x.origin.z
		out.append(z[0] - z[1])
	return out


## How far a rotation turns about the upright (radians).
func _yaw_of(q: Quaternion) -> float:
	return wrapf(2.0 * atan2(q.y, q.w), -PI, PI)


## What is left of a rotation with that turn taken out, as a tilt: x = forward and back, z = side to side (radians).
func _swing_of(q: Quaternion, yaw: float) -> Vector3:
	var s := (q * Quaternion(Vector3.UP, -yaw)).normalized()
	var angle := 2.0 * acos(clampf(s.w, -1.0, 1.0))
	var axis := Vector3(s.x, s.y, s.z)
	return axis.normalized() * angle if axis.length() > 0.00001 else Vector3.ZERO


## A stair clip: take its climb out of the hips, find where its own stairs stand under it, and note their slope.
func _stairs(a: Animation, c: Resource, sk: Skeleton3D) -> void:
	var frames := int(c.get(&"frames"))
	var fps := float(c.get(&"fps"))
	var hips: PackedVector3Array = c.get(&"hips")
	var travel: Vector3 = c.get(&"travel")
	var total := Vector2(travel.x, travel.z).length()
	var rise := hips[frames - 1].y - hips[0].y
	var slope := rise / maxf(total, 0.01)
	var t_hips := a.find_track(NodePath("%s:mixamorig_Hips" % SKEL), Animation.TYPE_POSITION_3D)
	# how much of its way the clip has gone at each frame: evenly for a loop; for a start or a stop, which do not
	# go at an even pace, by the ground its hips have really covered
	var way := PackedFloat32Array()
	var along := Vector3(travel.x, 0.0, travel.z).normalized()
	for f in frames:
		if a.loop_mode == Animation.LOOP_NONE and total > 0.02:
			way.append(clampf((Vector3(hips[f].x, 0.0, hips[f].z) - Vector3(hips[0].x, 0.0, hips[0].z)).dot(along) / total, 0.0, 1.0))
		else:
			way.append(float(f) / float(frames - 1))
	for f in frames:
		var p: Vector3 = a.track_get_key_value(t_hips, f)
		a.track_set_key_value(t_hips, f, Vector3(p.x, p.y - rise * way[f], p.z))
	# the ball of each foot through the clip, in the frame that travels and climbs with the hips
	var toe := [sk.find_bone("mixamorig_LeftToeBase"), sk.find_bone("mixamorig_RightToeBase")]
	var toe_rest := sk.get_bone_global_rest(toe[0]).origin.y
	var balls := [[], []]
	var legs := [[], []]            # hip joint to ankle, how long the leg is in each frame
	var side := ["Left", "Right"]
	for f in frames:
		var time := float(f) / fps
		for k in 2:
			# down the leg by hand: hips, thigh, shin, foot, ball of the foot
			var x := Transform3D(Basis(_rot(a, "mixamorig_Hips", time)), a.position_track_interpolate(t_hips, time))
			var joint := Vector3.ZERO
			var ankle := Vector3.ZERO
			for bn: String in ["UpLeg", "Leg", "Foot", "ToeBase"]:
				var name := "mixamorig_%s%s" % [side[k], bn]
				x = x * Transform3D(Basis(_rot(a, name, time)), sk.get_bone_rest(sk.find_bone(name)).origin)
				if bn == "UpLeg":
					joint = x.origin
				elif bn == "Foot":
					ankle = x.origin
			balls[k].append(x.origin)
			legs[k].append(joint.distance_to(ankle))
	var sum := 0.0
	var count := 0
	var longest := 0.0
	var pivot := 0.0
	for k in 2:
		for f in frames - 1:
			# over the clip's own ground the foot moves by its move in this frame plus the travel and the climb
			var step: Vector3 = (balls[k][f + 1] as Vector3) - (balls[k][f] as Vector3) + Vector3(0.0, rise, total) * (way[f + 1] - way[f])
			if step.length() * fps < 0.4:
				sum += (balls[k][f] as Vector3).y - slope * (balls[k][f] as Vector3).z - toe_rest
				count += 1
				# where the standing leg is at its longest: how far ahead of the hips the ball of that foot is then
				longest = maxf(longest, legs[k][f])
	var floor_y := sum / count if count > 0 else 0.0
	# (the leg stays at its longest for many frames: the pivot is the earliest of them in the step, the foot furthest ahead)
	for k in 2:
		for f in frames - 1:
			var step: Vector3 = (balls[k][f + 1] as Vector3) - (balls[k][f] as Vector3) + Vector3(0.0, rise, total) * (way[f + 1] - way[f])
			if step.length() * fps < 0.4 and float(legs[k][f]) > longest - 0.002:
				pivot = maxf(pivot, (balls[k][f] as Vector3).z - (a.track_get_key_value(t_hips, f) as Vector3).z)
	for f in frames:
		var p: Vector3 = a.track_get_key_value(t_hips, f)
		a.track_set_key_value(t_hips, f, Vector3(p.x, p.y - floor_y, p.z))
	var at := int(round(fposmod(float(c.get(&"phase_offset")), a.length) * fps))
	a.set_meta(&"slope", slope)
	a.set_meta(&"pivot", pivot)
	# how near its own ground the take brings a hand (the wrist), at its lowest: for hand_place.gd
	var low := INF
	for f in frames:
		var time := float(f) / fps
		for k in 2:
			var x := Transform3D(Basis(_rot(a, "mixamorig_Hips", time)), a.position_track_interpolate(t_hips, time))
			for bn: String in ["Spine", "Spine1", "Spine2", "%sShoulder" % side[k], "%sArm" % side[k], "%sForeArm" % side[k], "%sHand" % side[k]]:
				var name := "mixamorig_" + bn
				x = x * Transform3D(Basis(_rot(a, name, time)), sk.get_bone_rest(sk.find_bone(name)).origin)
			low = minf(low, x.origin.y - slope * x.origin.z)
	a.set_meta(&"hand_low", low)
	print("      its hands come to %.3f m over its own ground at their lowest (wrist)" % low)
	a.set_meta(&"reach", (balls[0][mini(at, frames - 1)] as Vector3).z)
	print("   stairs %s: rises %.2f m over %.2f m (slope %.2f), its stairs stood %.3f m off the hips' floor (%d planted frames), left foot comes down %.2f m ahead, its standing leg is longest (%.3f m) with the ball of the foot %.2f m ahead" % [c.get(&"source"), rise, total, slope, floor_y, count, float(a.get_meta(&"reach")), longest, pivot])


func _rot(a: Animation, bone: String, time: float) -> Quaternion:
	return a.rotation_track_interpolate(a.find_track(NodePath("%s:%s" % [SKEL, bone]), Animation.TYPE_ROTATION_3D), time)
