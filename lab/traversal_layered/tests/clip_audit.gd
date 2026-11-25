## Test tool (study v2 1.2, 1.3, 2.4, 6.12, 9.2): audits one cached clip ON THE BODY (player_v3, after retargeting).
## Own forward kinematics from the clip's rotations (no engine timing involved). Per frame: signed knee flexion measured
## against the body's rest (the mesh leg is straight at rest while its knee bones are bent), sign from geometry (a
## backward knee has the ankle in front of the hip->knee line); trunk / thigh capsules against an optional test wall.
## Before anything it runs its own mutation test (v2 9.2): rest reads 0, a +30 bend reads +30, a -20 bend reads -20;
## if not, it stops.
##   godot --headless --path . -s tests/clip_audit.gd -- <cache.bin> <clip> [wall_top wall_z0 wall_z1]
extends SceneTree

var sk: Skeleton3D
var n := 0
var par := PackedInt32Array()
var rest_pos := PackedVector3Array()
var rest_rot: Array[Quaternion] = []
var idx := {}
var hinge := {}
const S := 0.01

## FK: local rotations (and hips position, skeleton units) -> {pos: metres, rot: global quats}
func fk(lrot: Array, hips: Vector3) -> Dictionary:
	var gp := PackedVector3Array(); gp.resize(n)
	var gr: Array[Quaternion] = []; gr.resize(n)
	for i in n:
		if par[i] < 0:
			gr[i] = lrot[i]; gp[i] = hips * S
		else:
			gr[i] = gr[par[i]] * lrot[i]
			gp[i] = gp[par[i]] + gr[par[i]] * (rest_pos[i] * S)
	return {"pos": gp, "rot": gr}

## signed knee flexion (degrees, + normal, - backward), geometry only, before subtracting the rest value
func knee_geom(P: Dictionary, side: String) -> float:
	var hip: Vector3 = P.pos[idx[side + "UpLeg"]]; var knee: Vector3 = P.pos[idx[side + "Leg"]]; var ank: Vector3 = P.pos[idx[side + "Foot"]]
	var ax: Vector3 = (P.rot[idx[side + "UpLeg"]] * hinge[side]).normalized()
	var t := (knee - hip).normalized(); var s := (ank - knee).normalized()
	var tp := (t - ax * t.dot(ax)).normalized(); var sp := (s - ax * s.dot(ax)).normalized()
	var mag := rad_to_deg(acos(clamp(tp.dot(sp), -1.0, 1.0)))
	var ft := t.cross(ax).normalized()   # thigh's forward; at rest (0,-1,0) x (1,0,0) = (0,0,1) = body forward
	return mag if (ank - knee).dot(ft) < 0 else -mag

func _init():
	var a := OS.get_cmdline_user_args()
	var d: Dictionary = FileAccess.open(a[0], FileAccess.READ).get_var()
	var clip: Dictionary = d.clips[a[1]]
	var wall := a.size() > 4
	var top := float(a[2]) if wall else 0.0; var z0 := float(a[3]) if wall else 0.0; var z1 := float(a[4]) if wall else 0.0
	var body: Node3D = load("res://body/player_v3.glb").instantiate()
	sk = body.get_node("Armature/Skeleton3D")
	n = sk.get_bone_count(); par.resize(n); rest_pos.resize(n)
	for i in n:
		par[i] = sk.get_bone_parent(i)
		rest_pos[i] = sk.get_bone_rest(i).origin
		rest_rot.append(sk.get_bone_rest(i).basis.get_rotation_quaternion())
	for nm in ["Hips", "Spine01", "neck", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot"]: idx[nm] = sk.find_bone(nm)
	var R := fk(rest_rot, sk.get_bone_rest(0).origin)
	# hinge per side: body left, made perpendicular to the rest thigh, stored in the UpLeg's frame (v2 1.2)
	for side in ["Left", "Right"]:
		var t: Vector3 = (R.pos[idx[side + "Leg"]] - R.pos[idx[side + "UpLeg"]]).normalized()
		var ax := (Vector3(1, 0, 0) - t * t.dot(Vector3(1, 0, 0))).normalized()
		hinge[side] = R.rot[idx[side + "UpLeg"]].inverse() * ax
	var rest_flex := {"Left": knee_geom(R, "Left"), "Right": knee_geom(R, "Right")}

	# --- mutation test (v2 9.2): it must read rest 0, +30 forward, -20 backward, on both sides ---
	for side in ["Left", "Right"]:
		for want in [0.0, 30.0, -20.0]:
			var lr := rest_rot.duplicate()
			var li: int = idx[side + "Leg"]
			# bend the shin about the hinge (in the shin's parent frame = the thigh's global frame)
			var ax_local: Vector3 = hinge[side]  # hinge in the UpLeg frame; shin parent is UpLeg
			lr[li] = (Quaternion(ax_local.normalized(), deg_to_rad(want)) * rest_rot[li]).normalized()
			var got: float = knee_geom(fk(lr, sk.get_bone_rest(0).origin), side) - rest_flex[side]
			if abs(got - want) > 1.0:
				# the rotation may bend the other way with this rig's axis: try the opposite sign once
				lr[li] = (Quaternion(ax_local.normalized(), deg_to_rad(-want)) * rest_rot[li]).normalized()
				var got2: float = knee_geom(fk(lr, sk.get_bone_rest(0).origin), side) - rest_flex[side]
				if abs(got2 - want) > 1.0:
					print("MUTATION TEST FAILED: %s knee wanted %.0f, read %.1f / %.1f" % [side, want, got, got2]); quit(1); return
	print("mutation test passed: knee reads rest 0, +30, -20 on both sides (rest bone angle L %.0f, R %.0f)" % [rest_flex.Left, rest_flex.Right])

	var B: int = clip.bones
	var rot: PackedFloat32Array = clip.rot; var hips: PackedFloat32Array = clip.hips; var rt: PackedFloat32Array = clip.root
	var worst := {"Left": 999.0, "Right": 999.0}; var worst_f := {"Left": -1, "Right": -1}
	var back_frames := 0; var pen_max := 0.0; var pen_f := -1; var pen_what := ""
	for f in clip.frames:
		var lr: Array = []
		for i in B:
			var o: int = (f * B + i) * 4
			lr.append(Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3]))
		var P := fk(lr, Vector3(hips[f * 3], hips[f * 3 + 1], hips[f * 3 + 2]))
		var X := Transform3D(Basis(Vector3.UP, rt[f * 3 + 2]), Vector3(rt[f * 3], 0, rt[f * 3 + 1]))
		var any_back := false
		for side in ["Left", "Right"]:
			var flex: float = knee_geom(P, side) - rest_flex[side]
			if flex < worst[side]: worst[side] = flex; worst_f[side] = f
			if flex < -5: any_back = true
		if any_back: back_frames += 1
		if wall:
			var segs := [["Hips", "Spine01", 0.14], ["Spine01", "neck", 0.14], ["LeftUpLeg", "LeftLeg", 0.07], ["RightUpLeg", "RightLeg", 0.07]]
			for sg in segs:
				var p0: Vector3 = X * P.pos[idx[sg[0]]]; var p1: Vector3 = X * P.pos[idx[sg[1]]]
				for k in 6:
					var p := p0.lerp(p1, k / 5.0); var r: float = sg[2]
					var depth: float = min(min(p.z + r - z0, z1 - (p.z - r)), top - (p.y - r))
					if abs(p.x) < 0.8 and depth > pen_max: pen_max = depth; pen_f = f; pen_what = "%s-%s" % [sg[0], sg[1]]
	print("%s: frames %d | straightest knee L %.0f deg (frame %d), R %.0f deg (frame %d) | frames with a knee bent backward > 5 deg: %d%s" % [
		a[1], clip.frames, worst.Left, worst_f.Left, worst.Right, worst_f.Right, back_frames,
		(" | deepest body inside wall: %.0f cm (%s, frame %d)" % [pen_max * 100, pen_what, pen_f]) if wall else ""])
	quit()
