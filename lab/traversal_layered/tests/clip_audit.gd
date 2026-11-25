## Test tool (study v2 1.3, 2.4, 6.12): audits one cached clip ON THE BODY (player_v3, after retargeting), per frame:
## signed knee flexion (hinge axis captured on the body's rest thigh, carried by the UpLeg bone; sign from geometry:
## a backward knee has the ankle in front of the hip->knee line), and the trunk / thigh capsules against a test wall.
##   godot --headless --path . -s tests/clip_audit.gd -- <cache.bin> <clip> [wall_top wall_z0 wall_z1]
extends SceneTree
func _init():
	var a := OS.get_cmdline_user_args()
	var d: Dictionary = FileAccess.open(a[0], FileAccess.READ).get_var()
	var clip: Dictionary = d.clips[a[1]]
	var wall := a.size() > 4
	var top := float(a[2]) if wall else 0.0; var z0 := float(a[3]) if wall else 0.0; var z1 := float(a[4]) if wall else 0.0
	var body: Node3D = load("res://body/player_v3.glb").instantiate()
	root.add_child(body)
	var sk: Skeleton3D = body.get_node("Armature/Skeleton3D")
	var S := 0.01
	var B: int = clip.bones
	var idx := {}
	for n in ["Hips", "Spine02", "Spine01", "Spine", "neck", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot"]: idx[n] = sk.find_bone(n)
	# hinge axis per side: perpendicular to the rest thigh, along the body's left (+X), stored in the UpLeg's frame
	var hinge := {}
	for side in ["Left", "Right"]:
		var g := sk.get_bone_global_rest(idx[side + "UpLeg"])
		var t := (sk.get_bone_global_rest(idx[side + "Leg"]).origin - g.origin).normalized()
		var L := Vector3(1, 0, 0)
		var ax := (L - t * L.dot(t)).normalized()
		hinge[side] = g.basis.orthonormalized().inverse() * ax
	var rot: PackedFloat32Array = clip.rot; var hips: PackedFloat32Array = clip.hips; var rt: PackedFloat32Array = clip.root
	var worst := {"Left": 999.0, "Right": 999.0}; var worst_f := {"Left": -1, "Right": -1}
	var back_frames := 0; var pen_max := 0.0; var pen_f := -1; var pen_what := ""
	for f in clip.frames:
		for i in B:
			var o: int = (f * B + i) * 4
			sk.set_bone_pose_rotation(i, Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3]))
		sk.set_bone_pose_position(0, Vector3(hips[f * 3], hips[f * 3 + 1], hips[f * 3 + 2]))
		var X := Transform3D(Basis(Vector3.UP, rt[f * 3 + 2]), Vector3(rt[f * 3], 0, rt[f * 3 + 1]))
		var W := func(n): return X * (sk.get_bone_global_pose(idx[n]).origin * S)
		var any_back := false
		for side in ["Left", "Right"]:
			var hip: Vector3 = W.call(side + "UpLeg"); var knee: Vector3 = W.call(side + "Leg"); var ank: Vector3 = W.call(side + "Foot")
			var gb := sk.get_bone_global_pose(idx[side + "UpLeg"]).basis.orthonormalized()
			var ax: Vector3 = (X.basis * (gb * hinge[side])).normalized()
			var t := (knee - hip).normalized(); var s := (ank - knee).normalized()
			var tp := (t - ax * t.dot(ax)).normalized(); var sp := (s - ax * s.dot(ax)).normalized()
			var mag := rad_to_deg(acos(clamp(tp.dot(sp), -1.0, 1.0)))
			var ft := t.cross(ax).normalized()  # thigh's forward (at rest +Z: (0,-1,0) x (1,0,0) = (0,0,1))
			var flex := mag if (ank - knee).dot(ft) < 0 else -mag
			if flex < worst[side]: worst[side] = flex; worst_f[side] = f
			if flex < -5: any_back = true
		if any_back: back_frames += 1
		if wall:
			# capsules (study v2 2.4): trunk r 0.14 on hips->spine->neck, thighs r 0.07; how deep inside the wall box
			var segs := [["Hips", "Spine01", 0.14], ["Spine01", "neck", 0.14], ["LeftUpLeg", "LeftLeg", 0.07], ["RightUpLeg", "RightLeg", 0.07]]
			for sg in segs:
				var p0: Vector3 = W.call(sg[0]); var p1: Vector3 = W.call(sg[1])
				for k in 6:
					var p := p0.lerp(p1, k / 5.0); var r: float = sg[2]
					var depth: float = min(min(p.z + r - z0, z1 - (p.z - r)), top - (p.y - r))
					if abs(p.x) < 0.8 and depth > pen_max: pen_max = depth; pen_f = f; pen_what = "%s-%s" % [sg[0], sg[1]]
	print("%s: frames %d | worst knee L %.0f deg (frame %d), R %.0f deg (frame %d) | frames with a knee bent backward > 5 deg: %d | deepest body inside wall: %.0f cm (%s, frame %d)" % [a[1], clip.frames, worst.Left, worst_f.Left, worst.Right, worst_f.Right, back_frames, pen_max * 100, pen_what, pen_f])
	quit()
