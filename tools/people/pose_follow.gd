extends Node3D
## A new body (a MakeHuman 2 export with its "Game engine" skeleton) drawn in the pose of the game's figure (the Rocketbox
## "Bip01" skeleton the movement system drives), bone by bone, each frame - to SEE a new character with all the
## animations before the full refit (Yasin, 25 Nov: "make a model for our main character in mhfb2 then let me see it with
## the animations applied"). Each bone takes the source bone's turn away from its rest onto its own rest; the two rests
## (a T and an A, facing different ways in their files) are compared in each body's CHARACTER FRAME (up: pelvis to neck,
## left: right hip to left hip) - in the world the facing leaked in and the arms stayed in the A. The hips' height is
## scaled by the legs. A viewer, not the game's way (the refit fits the clips to the new skeleton itself).
## Used by tests/people/motor_film.gd --body=res://...glb

var src: Skeleton3D
var dst: Skeleton3D
const MAP := {
	"Bip01_Pelvis": "pelvis", "Bip01_Spine": "spine_01", "Bip01_Spine1": "spine_02", "Bip01_Spine2": "spine_03",
	"Bip01_Neck": "neck_01", "Bip01_Head": "head",
	"Bip01_L_Clavicle": "clavicle_l", "Bip01_L_UpperArm": "upperarm_l", "Bip01_L_Forearm": "lowerarm_l", "Bip01_L_Hand": "hand_l",
	"Bip01_R_Clavicle": "clavicle_r", "Bip01_R_UpperArm": "upperarm_r", "Bip01_R_Forearm": "lowerarm_r", "Bip01_R_Hand": "hand_r",
	"Bip01_L_Thigh": "thigh_l", "Bip01_L_Calf": "calf_l", "Bip01_L_Foot": "foot_l",
	"Bip01_R_Thigh": "thigh_r", "Bip01_R_Calf": "calf_r", "Bip01_R_Foot": "foot_r",
	"Bip01_L_Finger0": "thumb_01_l", "Bip01_L_Finger01": "thumb_02_l", "Bip01_L_Finger02": "thumb_03_l",
	"Bip01_L_Finger1": "index_01_l", "Bip01_L_Finger11": "index_02_l", "Bip01_L_Finger12": "index_03_l",
	"Bip01_L_Finger2": "middle_01_l", "Bip01_L_Finger21": "middle_02_l", "Bip01_L_Finger22": "middle_03_l",
	"Bip01_L_Finger3": "ring_01_l", "Bip01_L_Finger31": "ring_02_l", "Bip01_L_Finger32": "ring_03_l",
	"Bip01_L_Finger4": "pinky_01_l", "Bip01_L_Finger41": "pinky_02_l", "Bip01_L_Finger42": "pinky_03_l",
	"Bip01_R_Finger0": "thumb_01_r", "Bip01_R_Finger01": "thumb_02_r", "Bip01_R_Finger02": "thumb_03_r",
	"Bip01_R_Finger1": "index_01_r", "Bip01_R_Finger11": "index_02_r", "Bip01_R_Finger12": "index_03_r",
	"Bip01_R_Finger2": "middle_01_r", "Bip01_R_Finger21": "middle_02_r", "Bip01_R_Finger22": "middle_03_r",
	"Bip01_R_Finger3": "ring_01_r", "Bip01_R_Finger31": "ring_02_r", "Bip01_R_Finger32": "ring_03_r",
	"Bip01_R_Finger4": "pinky_01_r", "Bip01_R_Finger41": "pinky_02_r", "Bip01_R_Finger42": "pinky_03_r",
}
var pairs := []          # [src bone, dst bone, correction (character frame, rest to rest)]
var order := []
var Cs := Basis(); var Cd := Basis()   # each skeleton's character frame in its own space (columns: left, up, forward)
var leg_k := 1.0
var d_pel := -1
var ready_ok := false

func _char_frame(sk: Skeleton3D, pel: String, neck: String, lth: String, rth: String) -> Basis:
	var up := (sk.get_bone_global_rest(sk.find_bone(neck)).origin - sk.get_bone_global_rest(sk.find_bone(pel)).origin).normalized()
	var left := (sk.get_bone_global_rest(sk.find_bone(lth)).origin - sk.get_bone_global_rest(sk.find_bone(rth)).origin)
	left = (left - up * left.dot(up)).normalized()
	var fwd := left.cross(up).normalized()
	return Basis(left, up, fwd)

func setup(p_src: Skeleton3D, p_dst: Skeleton3D) -> void:
	src = p_src; dst = p_dst
	Cs = _char_frame(src, "Bip01_Pelvis", "Bip01_Neck", "Bip01_L_Thigh", "Bip01_R_Thigh")
	Cd = _char_frame(dst, "pelvis", "neck_01", "thigh_l", "thigh_r")
	for sn in MAP:
		var s := src.find_bone(sn); var d := dst.find_bone(MAP[sn])
		if s < 0 or d < 0: continue
		var corr := Basis()
		var sc := src.get_bone_children(s); var dc := dst.get_bone_children(d)
		if sc.size() > 0 and dc.size() > 0:
			var sdir := Cs.inverse() * (src.get_bone_global_rest(sc[0]).origin - src.get_bone_global_rest(s).origin)
			var ddir := Cd.inverse() * (dst.get_bone_global_rest(dc[0]).origin - dst.get_bone_global_rest(d).origin)
			if sdir.length() > 1e-5 and ddir.length() > 1e-5 and sdir.normalized().dot(ddir.normalized()) < 0.99999:
				corr = Basis(Quaternion(ddir.normalized(), sdir.normalized()))
		pairs.append([s, d, corr])
		if sn == "Bip01_Pelvis": d_pel = d
	var ds := pairs.map(func(p): return p[1])
	for i in dst.get_bone_count():
		if i in ds: order.append(i)
	var sl := (src.global_basis * (src.get_bone_global_rest(src.find_bone("Bip01_L_Foot")).origin - src.get_bone_global_rest(src.find_bone("Bip01_L_Thigh")).origin)).length()
	var dl := (dst.global_basis * (dst.get_bone_global_rest(dst.find_bone("foot_l")).origin - dst.get_bone_global_rest(dst.find_bone("thigh_l")).origin)).length()
	leg_k = dl / maxf(sl, 1e-4)
	src.skeleton_updated.connect(_follow)
	ready_ok = true

func _follow() -> void:
	if not ready_ok: return
	# the new body's skeleton turned so its character frame is the figure's in the world, standing where it stands
	var Ss := src.global_basis.orthonormalized()
	var W := Ss * Cs                                  # (the character frame in the world)
	var dscale := dst.global_basis.get_scale()
	dst.global_transform = Transform3D((W * Cd.inverse()).scaled_local(dscale), src.global_position)
	var cur := {}   # dst bone -> its global pose basis (skeleton space) this frame
	var by_d := {}
	for p in pairs: by_d[p[1]] = p
	for d in order:
		var p = by_d[d]
		var s: int = p[0]
		# the source's turn away from its rest, in its character frame
		var delta_c := Cs.inverse() * (src.get_bone_global_pose(s).basis * src.get_bone_global_rest(s).basis.inverse()) * Cs
		var want := Cd * delta_c * (p[2] as Basis) * Cd.inverse() * dst.get_bone_global_rest(d).basis
		var par := dst.get_bone_parent(d)
		var par_g: Basis = cur.get(par, dst.get_bone_global_pose(par).basis if par >= 0 else Basis())
		var local := (par_g.inverse() * want).orthonormalized()
		dst.set_bone_pose_rotation(d, local.get_rotation_quaternion())
		cur[d] = par_g * local
	if d_pel >= 0:
		# (the hips: the figure's pelvis over its floor, its height scaled by the legs)
		var sp := src.global_transform * src.get_bone_global_pose(src.find_bone("Bip01_Pelvis")).origin
		var fy := src.global_position.y
		var target := Vector3(sp.x, fy + (sp.y - fy) * leg_k, sp.z)
		var par := dst.get_bone_parent(d_pel)
		var par_x := dst.global_transform * (dst.get_bone_global_pose(par) if par >= 0 else Transform3D())
		dst.set_bone_pose_position(d_pel, par_x.affine_inverse() * target)
