extends SceneTree
## Bake the Mixamo clips in assets_src/clips onto the character's skeleton (traversal/character/player_v4.scn).
## Run:  godot --headless --path traversal_lab -s res://tools/build_clips.gd
## Each clip is retargeted in model space: how far each Mixamo bone has turned from its own T-pose is applied to the
## same-named bone of the character from the character's T-pose. That works whatever the two skeletons' bone axes
## are, and keeps the character's own stance where the clip is at rest.

const ClipData := preload("res://traversal/character/clip_data.gd")
const CHARACTER := "res://traversal/character/player_v4.scn"
const SRC := "res://assets_src/clips"
const OUT := "res://traversal/character/clips"
# Generated (Kimodo) clips are a few seconds of movement, not a loop: one stride is cut out of each, from the
# moment the left foot comes down to the next time it does, and its end is eased into its start.
const CUTS := {"KM_Stairs_Walk_Down": [0.67, 1.53], "KM_Stairs_Run_Up": [0.67, 1.33], "KM_Stairs_Run_Down": [1.27, 1.93],
		"KM_Slope_Down_30": [3.20, 3.93], "KM_Slope_Down_Run": [2.47, 2.93], "KM_Stairs_Run_Up_D": [1.13, 1.80],
		# one take, two of its strides: the 1.00 m stride it takes where its hill is 28 degrees, and the 0.91 m
		# stride where it is 37 degrees (the longest strides any climbing take made at those slopes)
		"KM_Climb": [1.60, 2.13], "KM_Climb_Steep": [3.27, 4.07]}
const AUTO_CUT := ["KM_Walk", "KM_Run"]
const LOOPS := ["Standing_Idle", "Running_3", "Running", "Sprint", "Slow_Run", "Falling_Idle", "Crouched_Walking", "Ascending_Stairs", "Crouching_Idle"]


func _skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _skeleton(c)
		if s:
			return s
	return null


func _player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var s := _player(c)
		if s:
			return s
	return null


func _initialize() -> void:
	var ch: Node = (load(CHARACTER) as PackedScene).instantiate()
	var tgt := _skeleton(ch)
	var names := PackedStringArray()
	for i in tgt.get_bone_count():
		names.append(tgt.get_bone_name(i))
	var summary := {}
	for file in DirAccess.get_files_at(SRC):
		if not file.ends_with(".fbx"):
			continue
		var scene: Node = (load(SRC + "/" + file) as PackedScene).instantiate()
		var src := _skeleton(scene)
		var anim := _player(scene).get_animation(_player(scene).get_animation_list()[0])
		var cd := _bake(file.get_basename(), src, tgt, names, anim)
		ResourceSaver.save(cd, "%s/%s.res" % [OUT, file.get_basename()], ResourceSaver.FLAG_COMPRESS)
		summary[file.get_basename()] = {"length": cd.length, "loop": cd.loop, "speed": cd.speed, "travel": [cd.travel.x, cd.travel.z], "phase_offset": cd.phase_offset, "turn_deg": rad_to_deg((cd.get(&"yaw") as PackedFloat32Array)[cd.frames - 1])}
		print("%-24s %5.2f s  travel %5.2f m  speed %4.2f m/s  loop %s  left foot forward at %.2f s  turns %.1f deg" % [file.get_basename(), cd.length, cd.travel.length(), cd.speed, str(cd.loop), cd.phase_offset, rad_to_deg((cd.get(&"yaw") as PackedFloat32Array)[cd.frames - 1])])
		scene.free()
	var f := FileAccess.open(OUT + "/clips.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(summary, "  "))
	quit(0)


func _bake(name: String, src: Skeleton3D, tgt: Skeleton3D, names: PackedStringArray, anim: Animation) -> Resource:
	var cd: Resource = ClipData.new()
	var fps := 30.0
	var frames := int(round(anim.length * fps)) + 1
	var nb := names.size()
	cd.set(&"fps", fps)
	cd.set(&"frames", frames)
	cd.set(&"bones", names)
	cd.set(&"source", name)
	var rot := PackedFloat32Array()
	rot.resize(frames * nb * 4)
	var hips := PackedVector3Array()
	hips.resize(frames)
	# which source bone drives each target bone, the two rests, and the leg length ratio
	var map := PackedInt32Array()
	for b in nb:
		map.append(src.find_bone(names[b]))
	var s_rest: Array[Basis] = []
	for i in src.get_bone_count():
		s_rest.append(src.get_bone_global_rest(i).basis.orthonormalized())
	var t_rest: Array[Basis] = []
	for b in nb:
		t_rest.append(tgt.get_bone_global_rest(b).basis.orthonormalized())
	# His T-pose is not a true T-pose in the legs: the thighs splay out (hip joints 0.21 m apart, ankles 0.36 m) and
	# the feet turn out. Every clip is a set of turns FROM a T-pose with the legs straight down and the feet pointing
	# ahead, so on him every clip came out bow-legged, feet apart and toes out (Yasin, 26 Nov: "legs are too spread
	# apart", then "knees are bent outwards", "feet pointing outwards too much"). Here each leg bone's T-pose is
	# first turned so that it points where a true T-pose has it: thigh and shin straight down, foot and toe in the
	# plane that runs fore and aft.
	for side: String in ["Left", "Right"]:
		for part: String in ["UpLeg", "Leg", "Foot", "ToeBase"]:
			var b := tgt.find_bone("mixamorig_%s%s" % [side, part])
			var child := -1
			for k in tgt.get_bone_children(b):
				child = k
			if b < 0 or child < 0:
				continue
			var now := (tgt.get_bone_global_rest(child).origin - tgt.get_bone_global_rest(b).origin).normalized()
			var want := Vector3(0.0, now.y, now.z).normalized()
			if part in ["UpLeg", "Leg"]:
				# straight down, and in by what brings the ankles to the study's step width: people's feet land
				# 0.08 to 0.10 m apart, and his hip joints are 0.21 m apart
				var hip_x := absf(tgt.get_bone_global_rest(tgt.find_bone("mixamorig_%sUpLeg" % side)).origin.x)
				var leg_len := tgt.get_bone_global_rest(tgt.find_bone("mixamorig_%sUpLeg" % side)).origin.y - tgt.get_bone_global_rest(tgt.find_bone("mixamorig_%sFoot" % side)).origin.y
				var inward := atan2(hip_x - 0.07, leg_len)
				want = Vector3(-sin(inward) * signf(tgt.get_bone_global_rest(b).origin.x), -cos(inward), 0.0)
			var axis := now.cross(want)
			if axis.length() > 0.0001:
				t_rest[b] = Basis(axis.normalized(), now.angle_to(want)) * t_rest[b]
	var s_hips := src.find_bone("mixamorig_Hips")
	var t_hips := tgt.find_bone("mixamorig_Hips")
	var leg := func(s: Skeleton3D) -> float:
		var a := s.get_bone_global_rest(s.find_bone("mixamorig_LeftUpLeg")).origin
		var k := s.get_bone_global_rest(s.find_bone("mixamorig_LeftLeg")).origin
		var f := s.get_bone_global_rest(s.find_bone("mixamorig_LeftFoot")).origin
		return a.distance_to(k) + k.distance_to(f)
	var scale: float = leg.call(tgt) / leg.call(src)
	var s_hips_rest := src.get_bone_global_rest(s_hips).origin
	var t_hips_rest := tgt.get_bone_global_rest(t_hips).origin
	# the source tracks
	var tracks: Array = []
	for t in anim.get_track_count():
		var path := str(anim.track_get_path(t))
		var bone := src.find_bone(path.get_slice(":", 1))
		if bone >= 0:
			tracks.append([t, anim.track_get_type(t), bone])
	var t_global: Array[Basis] = []
	t_global.resize(nb)
	var lf := tgt.find_bone("mixamorig_LeftFoot")
	var foot_fwd := PackedFloat32Array()
	var yaw := PackedFloat32Array()
	for f in frames:
		var time := minf(f / fps, anim.length)
		src.reset_bone_poses()
		for tr: Array in tracks:
			if tr[1] == Animation.TYPE_ROTATION_3D:
				src.set_bone_pose_rotation(tr[2], anim.rotation_track_interpolate(tr[0], time))
			elif tr[1] == Animation.TYPE_POSITION_3D:
				src.set_bone_pose_position(tr[2], anim.position_track_interpolate(tr[0], time))
		# the source skeleton's pose in model space, worked out here (a skeleton outside a running scene does not
		# refresh its own)
		var sg: Array[Transform3D] = []
		sg.resize(src.get_bone_count())
		for i in src.get_bone_count():
			var sp := src.get_bone_parent(i)
			var local := src.get_bone_pose(i)
			sg[i] = (sg[sp] * local) if sp >= 0 else local
		for b in nb:
			var parent := tgt.get_bone_parent(b)
			var pg := t_global[parent] if parent >= 0 else Basis.IDENTITY
			var g := t_rest[b]
			if map[b] >= 0:
				var turned := sg[map[b]].basis.orthonormalized() * s_rest[map[b]].inverse()
				g = turned * t_rest[b]
			elif parent >= 0:
				g = pg * tgt.get_bone_rest(b).basis.orthonormalized()
			t_global[b] = g
			var q := (pg.inverse() * g).get_rotation_quaternion()
			var o := (f * nb + b) * 4
			rot[o] = q.x
			rot[o + 1] = q.y
			rot[o + 2] = q.z
			rot[o + 3] = q.w
		var hp := sg[s_hips].origin
		hips[f] = t_hips_rest + (hp - s_hips_rest) * scale
		# how far the hips have turned since the first frame, counted on through half turns
		var hf := (sg[s_hips].basis.orthonormalized() * s_rest[s_hips].inverse()) * Vector3(0.0, 0.0, 1.0)
		var ang := atan2(hf.x, hf.z)
		if f == 0:
			yaw.append(ang)
		else:
			yaw.append(yaw[f - 1] + wrapf(ang - yaw[f - 1], -PI, PI))
		# how far forward of the hips the left foot is (for lining loops up): from the source skeleton
		var sf := sg[src.find_bone("mixamorig_LeftFoot")].origin
		foot_fwd.append(sf.z - hp.z)
		if name.begins_with("KM_") and OS.get_cmdline_user_args().has("--table") and f % 2 == 0:
			var rf := sg[src.find_bone("mixamorig_RightFoot")].origin
			print("    %s %.2f hips z %.2f y %.2f | L fwd %.2f y %.2f | R fwd %.2f y %.2f" % [name.substr(3), time, hp.z, hp.y, sf.z - hp.z, sf.y, rf.z - hp.z, rf.y])
	if name.begins_with("KM_"):
		# for cutting a loop out of a generated clip: when each foot is furthest forward, and where the hips are then
		var line := ""
		for f in range(1, frames - 1):
			if foot_fwd[f] > foot_fwd[f - 1] and foot_fwd[f] >= foot_fwd[f + 1] and foot_fwd[f] > 0.05:
				line += "  L %.2f s (hips z %.2f y %.2f)" % [f / fps, hips[f].z, hips[f].y]
		print("    left foot furthest forward at:" + line)
	var cut: Array = CUTS.get(name, [])
	if name in AUTO_CUT:
		# one stride from the middle of the clip: between two moments the left foot is furthest forward
		var peaks: Array[int] = []
		for f in range(2, frames - 2):
			if foot_fwd[f] > foot_fwd[f - 1] and foot_fwd[f] >= foot_fwd[f + 1] and foot_fwd[f] > foot_fwd[f - 2] and foot_fwd[f] > 0.0:
				if peaks.is_empty() or f - peaks[peaks.size() - 1] > 8:
					peaks.append(f)
		var best := -1
		for i in peaks.size() - 1:
			if best < 0 or absf((peaks[i] + peaks[i + 1]) * 0.5 - frames * 0.5) < absf((peaks[best] + peaks[best + 1]) * 0.5 - frames * 0.5):
				best = i
		if best >= 0:
			cut = [peaks[best] / fps, peaks[best + 1] / fps]
			print("    %s: stride cut at %.2f to %.2f s" % [name, cut[0], cut[1]])
	if not cut.is_empty():
		var f0 := int(round(float(cut[0]) * fps))
		var f1 := int(round(float(cut[1]) * fps))
		rot = rot.slice(f0 * nb * 4, (f1 + 1) * nb * 4)
		hips = hips.slice(f0, f1 + 1)
		yaw = yaw.slice(f0, f1 + 1)
		foot_fwd = foot_fwd.slice(f0, f1 + 1)
		frames = f1 - f0 + 1
		cd.set(&"frames", frames)
		# ease the last frames into the first pose, so the loop closes
		var ease := 6
		for b in nb:
			var e := ((frames - 1) * nb + b) * 4
			var gap := Quaternion(rot[e], rot[e + 1], rot[e + 2], rot[e + 3]).inverse() * Quaternion(rot[b * 4], rot[b * 4 + 1], rot[b * 4 + 2], rot[b * 4 + 3])
			for k in range(1, ease + 1):
				var f := frames - 1 - ease + k
				var o := (f * nb + b) * 4
				var q := (Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3]) * Quaternion.IDENTITY.slerp(gap, float(k) / ease)).normalized()
				rot[o] = q.x
				rot[o + 1] = q.y
				rot[o + 2] = q.z
				rot[o + 3] = q.w
	cd.set(&"rot", rot)
	cd.set(&"hips", hips)
	var y0 := yaw[0]
	for f in frames:
		yaw[f] -= y0
	cd.set(&"yaw", yaw)
	var tv := Vector3(hips[frames - 1].x - hips[0].x, 0.0, hips[frames - 1].z - hips[0].z)
	var is_loop := name in LOOPS or not cut.is_empty()
	cd.set(&"loop", is_loop)
	cd.set(&"travel", tv)
	cd.set(&"speed", tv.length() / maxf(float(frames - 1) / fps, 0.001))
	if is_loop:
		var best := 0
		for f in frames:
			if foot_fwd[f] > foot_fwd[best]:
				best = f
		cd.set(&"phase_offset", 0.0 if not cut.is_empty() else best / fps)
	return cd
