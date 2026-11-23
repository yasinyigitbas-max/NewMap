extends SceneTree
## Plays our player clips (Rocketbox skeleton, characters/rocketbox/clips_player_*_male.res) on a Meshy-rigged model
## WITHOUT changing the model: its own mesh, skin and 24-bone skeleton (no fingers) as Meshy made it. Writes a GLB
## with the model and the converted clips, for the review page.
##   xvfb-run -a godot --path . -s res://tools/people/meshy/retarget_rb_to_meshy.gd -- IN.glb OUT.glb lib:clip[:inplace] ...
## How: per mapped bone, its world rotation = the clip's change from Rocketbox's rest, applied on the Meshy rest after
## turning the Meshy bone onto the Rocketbox rest direction (the two rests differ: Rocketbox's arms hang in an A-pose,
## Meshy's are out in a T). Hips position scaled by hip height. ":inplace" removes the hips' travel over the ground
## (for loops on a turntable); nothing else is changed.

const LIBS := {"pidle": "idle", "pwalk": "walk", "prun": "run", "ptrav": "trav", "pact": "act"}
var MAP := {
	"Bip01_Pelvis": "Hips", "Bip01_Spine": "Spine02", "Bip01_Spine1": "Spine01", "Bip01_Spine2": "Spine",
	"Bip01_Neck": "neck", "Bip01_Head": "Head",
	"Bip01_L_Clavicle": "LeftShoulder", "Bip01_L_UpperArm": "LeftArm", "Bip01_L_Forearm": "LeftForeArm", "Bip01_L_Hand": "LeftHand",
	"Bip01_R_Clavicle": "RightShoulder", "Bip01_R_UpperArm": "RightArm", "Bip01_R_Forearm": "RightForeArm", "Bip01_R_Hand": "RightHand",
	"Bip01_L_Thigh": "LeftUpLeg", "Bip01_L_Calf": "LeftLeg", "Bip01_L_Foot": "LeftFoot",
	"Bip01_R_Thigh": "RightUpLeg", "Bip01_R_Calf": "RightLeg", "Bip01_R_Foot": "RightFoot",
}
# bones aimed by direction (head -> this child's head) on both sides; others use the clip's change as is
var AIM := {
	"Bip01_Spine": ["Bip01_Spine1", "Spine01"], "Bip01_Spine1": ["Bip01_Spine2", "Spine"], "Bip01_Spine2": ["Bip01_Neck", "neck"],
	"Bip01_Neck": ["Bip01_Head", "Head"],
	"Bip01_L_Clavicle": ["Bip01_L_UpperArm", "LeftArm"], "Bip01_L_UpperArm": ["Bip01_L_Forearm", "LeftForeArm"], "Bip01_L_Forearm": ["Bip01_L_Hand", "LeftHand"],
	"Bip01_R_Clavicle": ["Bip01_R_UpperArm", "RightArm"], "Bip01_R_UpperArm": ["Bip01_R_Forearm", "RightForeArm"], "Bip01_R_Forearm": ["Bip01_R_Hand", "RightHand"],
	"Bip01_L_Thigh": ["Bip01_L_Calf", "LeftLeg"], "Bip01_L_Calf": ["Bip01_L_Foot", "LeftFoot"],
	"Bip01_R_Thigh": ["Bip01_R_Calf", "RightLeg"], "Bip01_R_Calf": ["Bip01_R_Foot", "RightFoot"],
}
var SAME_AS := {"Bip01_L_Hand": "Bip01_L_Forearm", "Bip01_R_Hand": "Bip01_R_Forearm"}
const FPS := 30.0
var LEAN := float(OS.get_environment("LEAN")) if OS.get_environment("LEAN") != "" else 0.0   # degrees forward


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var in_glb: String = args[0]
	var out_glb: String = args[1]
	var clips: Array = args.slice(2)

	# source: the Rocketbox hero (for its skeleton's rest)
	var hero: Node3D = load("res://characters/rocketbox/hero_male.scn").instantiate()
	root.add_child(hero)
	var ss: Skeleton3D = hero.find_children("*", "Skeleton3D", true, false)[0]
	# target: the Meshy model as it is
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(in_glb, st) != OK:
		push_error("cannot read " + in_glb); quit(1); return
	var model: Node3D = doc.generate_scene(st)
	root.add_child(model)
	var ts: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	# fingers, when the model has them (tools/people/meshy/add_fingers.py names them the Mixamo way)
	if ts.find_bone("LeftHandIndex1") >= 0:
		var FN := ["Thumb", "Index", "Middle", "Ring", "Pinky"]
		for sd in [["L", "Left"], ["R", "Right"]]:
			for f in 5:
				var rb := ["Bip01_%s_Finger%d" % [sd[0], f], "Bip01_%s_Finger%d1" % [sd[0], f], "Bip01_%s_Finger%d2" % [sd[0], f]]
				var mx := []
				for j in 3: mx.append("%sHand%s%d" % [sd[1], FN[f], j + 1])
				for j in 3: MAP[rb[j]] = mx[j]
				AIM[rb[0]] = [rb[1], mx[1]]
				AIM[rb[1]] = [rb[2], mx[2]]
				SAME_AS[rb[2]] = rb[1]
			SAME_AS.erase("Bip01_%s_Hand" % sd[0])
			AIM["Bip01_%s_Hand" % sd[0]] = ["Bip01_%s_Finger2" % sd[0], "%sHandMiddle1" % sd[1]]
		print("finger bones mapped: ", MAP.size(), " bones")
	for ap in model.find_children("*", "AnimationPlayer", true, false):
		ap.get_parent().remove_child(ap); ap.free()

	var sw := _world(ss)
	var tw := _world(ts)
	print("skeleton scales src ", sw.basis.get_scale(), " tgt ", tw.basis.get_scale())
	var s_rest := {}   # world rest transforms
	for i in ss.get_bone_count(): s_rest[ss.get_bone_name(i)] = sw * ss.get_bone_global_rest(i)
	var t_rest := {}
	for i in ts.get_bone_count(): t_rest[ts.get_bone_name(i)] = tw * ts.get_bone_global_rest(i)

	# facing: turn the source so its left-right axis (thighs) matches the target's (yaw only)
	var s_lat: Vector3 = s_rest["Bip01_R_Thigh"].origin - s_rest["Bip01_L_Thigh"].origin
	var t_lat: Vector3 = t_rest["RightUpLeg"].origin - t_rest["LeftUpLeg"].origin
	s_lat.y = 0; t_lat.y = 0
	var yaw := Basis(Quaternion(s_lat.normalized(), t_lat.normalized()))
	print("facing yaw deg ", rad_to_deg(Quaternion(yaw).get_angle()))

	# per bone: C turns the target's rest frame onto the (turned) source rest frame. A frame = the bone's direction
	# plus a second axis: the body's left-right axis for the hips, spine, neck, head and legs; the palm's normal for
	# hands and fingers (direction alone left the twist free: the thumb curled like a finger, 23 Nov). Arms: direction
	# only (in Meshy's T-pose the arm runs along the left-right axis).
	var s_latv: Vector3 = yaw * (s_rest["Bip01_R_Thigh"].origin - s_rest["Bip01_L_Thigh"].origin)
	var t_latv: Vector3 = t_rest["RightUpLeg"].origin - t_rest["LeftUpLeg"].origin
	var palm := {}
	for sd2 in [["L", "Left"], ["R", "Right"]]:
		if ts.find_bone(sd2[1] + "HandIndex1") < 0: continue
		var sw0: Vector3 = s_rest["Bip01_%s_Hand" % sd2[0]].origin
		var tw0: Vector3 = t_rest[sd2[1] + "Hand"].origin
		var sn: Vector3 = yaw * (s_rest["Bip01_%s_Finger1" % sd2[0]].origin - sw0).cross(s_rest["Bip01_%s_Finger4" % sd2[0]].origin - sw0)
		var tn: Vector3 = (t_rest[sd2[1] + "HandIndex1"].origin - tw0).cross(t_rest[sd2[1] + "HandPinky1"].origin - tw0)
		palm[sd2[0]] = [sn, tn]
	var C := {}
	for sb in MAP:
		var key: String = SAME_AS.get(sb, sb)
		var sd: Vector3
		var td: Vector3
		if AIM.has(key):
			sd = yaw * (s_rest[AIM[key][0]].origin - s_rest[key].origin)
			td = t_rest[AIM[key][1]].origin - t_rest[MAP[key]].origin
		elif sb == "Bip01_Pelvis" or sb == "Bip01_Head":
			sd = yaw * (s_rest["Bip01_Head"].origin - s_rest["Bip01_Pelvis"].origin)
			td = t_rest["Head"].origin - t_rest["Hips"].origin
		else:
			C[sb] = Basis(); continue
		var sn2 := Vector3.ZERO
		var tn2 := Vector3.ZERO
		if "Hand" in sb or "Finger" in sb:
			var side := "L" if "_L_" in sb else "R"
			if palm.has(side): sn2 = palm[side][0]; tn2 = palm[side][1]
		elif not ("Arm" in sb or "Forearm" in sb or "Clavicle" in sb):
			sn2 = s_latv; tn2 = t_latv
		if sn2 == Vector3.ZERO:
			C[sb] = Basis(Quaternion(td.normalized(), sd.normalized()))
		else:
			C[sb] = _frame(sd, sn2) * _frame(td, tn2).inverse()
	var s_hip_h: float = s_rest["Bip01_Pelvis"].origin.y - min(s_rest["Bip01_L_Foot"].origin.y, s_rest["Bip01_R_Foot"].origin.y)
	var t_hip_h: float = t_rest["Hips"].origin.y - min(t_rest["LeftFoot"].origin.y, t_rest["RightFoot"].origin.y)
	var ratio := t_hip_h / s_hip_h
	print("hip heights src %.3f tgt %.3f ratio %.3f" % [s_hip_h, t_hip_h, ratio])

	var ap := AnimationPlayer.new(); ap.name = "AnimationPlayer"
	model.add_child(ap); ap.owner = model
	var lib := AnimationLibrary.new()
	var tpath := String(model.get_path_to(ts))
	for spec in clips:
		var parts: PackedStringArray = String(spec).split(":")
		var l: AnimationLibrary = load("res://characters/rocketbox/clips_player_%s_male.res" % LIBS[parts[0]])
		var a: Animation = l.get_animation(parts[1])
		var inplace := parts.size() > 2 and parts[2] == "inplace"
		var out := Animation.new()
		out.length = a.length
		out.loop_mode = a.loop_mode
		var tracks := {}
		for i in ts.get_bone_count():
			var tr := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(tr, NodePath(tpath + ":" + ts.get_bone_name(i)))
			tracks[ts.get_bone_name(i)] = tr
		var hp := out.add_track(Animation.TYPE_POSITION_3D)
		out.track_set_path(hp, NodePath(tpath + ":Hips"))
		var n := int(ceil(a.length * FPS)) + 1
		var p0 := Vector3.ZERO
		for f in n:
			var t: float = min(f / FPS, a.length)
			ss.reset_bone_poses()
			for k in a.get_track_count():
				var bn := String(a.track_get_path(k)).get_slice(":", 1)
				var bi := ss.find_bone(bn)
				if bi < 0: continue
				match a.track_get_type(k):
					Animation.TYPE_ROTATION_3D: ss.set_bone_pose_rotation(bi, a.rotation_track_interpolate(k, t))
					Animation.TYPE_POSITION_3D: ss.set_bone_pose_position(bi, a.position_track_interpolate(k, t))
			# source global poses, chained by hand (get_bone_global_pose is not refreshed outside the tree's process)
			var sgp := []
			sgp.resize(ss.get_bone_count())
			for bi in ss.get_bone_count():
				var pp := ss.get_bone_parent(bi)
				sgp[bi] = ss.get_bone_pose(bi) if pp < 0 else (sgp[pp] as Transform3D) * ss.get_bone_pose(bi)
			# target world rotations
			var tworld := {}
			for sb in MAP:
				var sg: Transform3D = sw * (sgp[ss.find_bone(sb)] as Transform3D)
				var delta: Basis = (yaw * sg.basis.orthonormalized()) * (yaw * s_rest[sb].basis.orthonormalized()).inverse()
				tworld[MAP[sb]] = delta * C[sb] * t_rest[MAP[sb]].basis.orthonormalized()
			# upright fix (Yasin 23 Nov: "he is leaning back too much"): the upper body tilted forward by LEAN degrees,
			# spread over the spine (40 / 70 / 100 %), everything above the spine turned with it
			if LEAN != 0.0:
				var ax: Vector3 = Vector3.UP.cross(-t_latv.cross(Vector3.UP)).normalized()
				var share := {"Spine02": 0.4, "Spine01": 0.7}
				for bn2 in tworld:
					if bn2 == "Hips" or "Leg" in bn2 or "Foot" in bn2 or "Toe" in bn2: continue
					var k: float = share.get(bn2, 1.0)
					tworld[bn2] = Basis(ax, deg_to_rad(LEAN * k)) * (tworld[bn2] as Basis)
			# to local, parents first (bone order is parent-first in a glTF skeleton)
			var gpose := {}
			for i in ts.get_bone_count():
				var bn := ts.get_bone_name(i)
				var par := ts.get_bone_parent(i)
				var pw: Basis = (tw.basis.orthonormalized() if par < 0 else gpose[ts.get_bone_name(par)])
				var wb: Basis
				if tworld.has(bn): wb = tworld[bn]
				else: wb = pw * ts.get_bone_rest(i).basis.orthonormalized()
				gpose[bn] = wb
				out.rotation_track_insert_key(tracks[bn], t, Quaternion((pw.inverse() * wb).orthonormalized()))
			if f == int(FPS):   # lean check at 1 s: hips -> head, angle forward (+) / back (-) in the side plane
				var sh: Vector3 = yaw * ((sw * (sgp[ss.find_bone("Bip01_Head")] as Transform3D)).origin - (sw * (sgp[ss.find_bone("Bip01_Pelvis")] as Transform3D)).origin)
				var gt := {}
				var hb := ts.find_bone("Hips")
				var tp := []
				tp.resize(ts.get_bone_count())
				for bi in ts.get_bone_count():
					var par2 := ts.get_bone_parent(bi)
					var lq: Quaternion = out.rotation_track_interpolate(tracks[ts.get_bone_name(bi)], t)
					var lt := Transform3D(Basis(lq), ts.get_bone_rest(bi).origin)
					tp[bi] = (tw * lt) if par2 < 0 else (tp[par2] as Transform3D) * lt
				var th: Vector3 = (tp[ts.find_bone("Head")] as Transform3D).origin - (tp[hb] as Transform3D).origin
				var fwd := t_latv.cross(Vector3.UP).normalized()
				print("  lean deg (+ = BACK: fwd is his back)  source %.1f  target %.1f" % [rad_to_deg(atan2(sh.dot(fwd), sh.y)), rad_to_deg(atan2(th.dot(fwd), th.y))])
				var sp := func(a: String) -> Vector3: return yaw * (sw * (sgp[ss.find_bone(a)] as Transform3D)).origin
				var tq := func(a: String) -> Vector3: return (tp[ts.find_bone(a)] as Transform3D).origin
				var ang := func(v: Vector3) -> float: return rad_to_deg(atan2(v.dot(fwd), v.y))
				print("  segments fwd deg (pelvis-chest, chest-neck, neck-head)  source %.1f %.1f %.1f  target %.1f %.1f %.1f" % [
					ang.call(sp.call("Bip01_Spine2") - sp.call("Bip01_Pelvis")), ang.call(sp.call("Bip01_Neck") - sp.call("Bip01_Spine2")), ang.call(sp.call("Bip01_Head") - sp.call("Bip01_Neck")),
					ang.call(tq.call("Spine") - tq.call("Hips")), ang.call(tq.call("neck") - tq.call("Spine")), ang.call(tq.call("Head") - tq.call("neck"))])
				print("  rest segments  source %.1f %.1f %.1f  target %.1f %.1f %.1f" % [
					ang.call(yaw * (s_rest["Bip01_Spine2"].origin - s_rest["Bip01_Pelvis"].origin)), ang.call(yaw * (s_rest["Bip01_Neck"].origin - s_rest["Bip01_Spine2"].origin)), ang.call(yaw * (s_rest["Bip01_Head"].origin - s_rest["Bip01_Neck"].origin)),
					ang.call(t_rest["Spine"].origin - t_rest["Hips"].origin), ang.call(t_rest["neck"].origin - t_rest["Spine"].origin), ang.call(t_rest["Head"].origin - t_rest["neck"].origin)])
			# hips position
			var spel: Vector3 = (sw * (sgp[ss.find_bone("Bip01_Pelvis")] as Transform3D)).origin
			var d: Vector3 = yaw * (spel - s_rest["Bip01_Pelvis"].origin) * ratio
			if f == 0: p0 = d
			if inplace: d.x = 0; d.z = 0
			var hw: Vector3 = t_rest["Hips"].origin + d
			var hi := ts.find_bone("Hips")
			var parent_w: Transform3D = tw if ts.get_bone_parent(hi) < 0 else tw * ts.get_bone_global_rest(ts.get_bone_parent(hi))
			out.position_track_insert_key(hp, t, parent_w.affine_inverse() * hw)
		lib.add_animation(StringName(parts[1]), out)
		print("clip ", parts[0], "/", parts[1], " %.2fs" % a.length, " loop ", a.loop_mode, " frames ", n)
	ap.add_animation_library("", lib)

	var ex := GLTFDocument.new()
	var es := GLTFState.new()
	_own(model, model)
	if ex.append_from_scene(model, es) != OK:
		push_error("export failed"); quit(1); return
	ex.write_to_filesystem(es, out_glb)
	print("WROTE ", out_glb)
	quit()


func _frame(d: Vector3, n: Vector3) -> Basis:
	var x := d.normalized()
	var z := (n - x * x.dot(n)).normalized()
	return Basis(x, z.cross(x), z)


func _world(n: Node) -> Transform3D:
	# (global_transform is not ready inside _init: walk the parents)
	var t := Transform3D()
	var c: Node = n
	while c != null:
		if c is Node3D: t = (c as Node3D).transform * t
		c = c.get_parent()
	return t


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)
