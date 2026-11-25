extends SceneTree
## Bake the Mixamo clips in assets_src/clips onto the character's skeleton (traversal/character/player_v4_standin.glb).
## Run:  godot --headless --path traversal_lab -s res://tools/build_clips.gd
## Each clip is retargeted in model space: how far each Mixamo bone has turned from its own T-pose is applied to the
## same-named bone of the character from the character's T-pose. That works whatever the two skeletons' bone axes
## are, and keeps the character's own stance where the clip is at rest.

const ClipData := preload("res://traversal/character/clip_data.gd")
const CHARACTER := "res://traversal/character/player_v4_standin.glb"
const SRC := "res://assets_src/clips"
const OUT := "res://traversal/character/clips"
const LOOPS := ["Standing_Idle", "Walking_4", "Walking", "Running_3", "Running", "Sprint", "Slow_Run", "Falling_Idle", "Crouched_Walking"]


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
		summary[file.get_basename()] = {"length": cd.length, "loop": cd.loop, "speed": cd.speed, "travel": [cd.travel.x, cd.travel.z], "phase_offset": cd.phase_offset}
		print("%-24s %5.2f s  travel %5.2f m  speed %4.2f m/s  loop %s  left foot forward at %.2f s" % [file.get_basename(), cd.length, cd.travel.length(), cd.speed, str(cd.loop), cd.phase_offset])
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
		# how far forward of the hips the left foot is (for lining loops up): from the source skeleton
		var sf := sg[src.find_bone("mixamorig_LeftFoot")].origin
		foot_fwd.append(sf.z - hp.z)
	cd.set(&"rot", rot)
	cd.set(&"hips", hips)
	var tv := Vector3(hips[frames - 1].x - hips[0].x, 0.0, hips[frames - 1].z - hips[0].z)
	var is_loop := name in LOOPS
	cd.set(&"loop", is_loop)
	cd.set(&"travel", tv)
	cd.set(&"speed", tv.length() / maxf(anim.length, 0.001))
	if is_loop:
		var best := 0
		for f in frames:
			if foot_fwd[f] > foot_fwd[best]:
				best = f
		cd.set(&"phase_offset", best / fps)
	return cd
