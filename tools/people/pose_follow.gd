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
var dst_ankle := 0.1
var d_feet := []
var s_feet := []
const SRC_ANKLE := 0.105   # (the figure's ankle over the ground, standing: the motor's ankle_rest)
var d_pel := -1
var tips := []   # (the fingers' last joints)
var ready_ok := false
var hip_fix := false     # (on for a Meshy body: the clip's pelvis tilt dropped)
var hand_scale := 1.0    # (a Meshy body: its hands drawn smaller - 1.45x the figure's proportions, "enormous")
var s_pel := -1
var d_hands := []
var meshy := false   # (a Meshy / Mixamo-named body: Hips, Spine02, LeftArm, LeftHandIndex1 ...)
const MESHY := {"pelvis": "Hips", "spine_01": "Spine02", "spine_02": "Spine01", "spine_03": "Spine", "neck_01": "neck", "head": "Head",
	"clavicle": "Shoulder", "upperarm": "Arm", "lowerarm": "ForeArm", "hand": "Hand", "thigh": "UpLeg", "calf": "Leg", "foot": "Foot"}

# the body's own name for a bone, named as MakeHuman's Game-engine skeleton names it (its names are the keys here)
func nm(k: String) -> String:
	if not meshy: return k
	if MESHY.has(k): return MESHY[k]
	var parts := k.split("_")
	var side := "Left" if parts[parts.size() - 1] == "l" else "Right"
	if parts.size() == 2: return side + MESHY[parts[0]]
	# fingers: index_02_l -> LeftHandIndex2
	return "%sHand%s%d" % [side, parts[0].capitalize(), int(parts[1])]
var torso := []           # [dst bone, its rest global (skeleton space), half-width, front, back, low, high]: his torso's flesh
var arms := []            # per side [upperarm, lowerarm, hand]
var hand_k := 1.0         # his hand's length against the figure's
var host: Node = null      # (the player: its phone, placed on the figure's hand, carried over to the new body's hand)
var prop: Node3D = null

func _char_frame(sk: Skeleton3D, pel: String, neck: String, lth: String, rth: String) -> Basis:
	var up := (sk.get_bone_global_rest(sk.find_bone(neck)).origin - sk.get_bone_global_rest(sk.find_bone(pel)).origin).normalized()
	var left := (sk.get_bone_global_rest(sk.find_bone(lth)).origin - sk.get_bone_global_rest(sk.find_bone(rth)).origin)
	left = (left - up * left.dot(up)).normalized()
	var fwd := left.cross(up).normalized()
	return Basis(left, up, fwd)

func setup(p_src: Skeleton3D, p_dst: Skeleton3D) -> void:
	src = p_src; dst = p_dst
	Cs = _char_frame(src, "Bip01_Pelvis", "Bip01_Neck", "Bip01_L_Thigh", "Bip01_R_Thigh")
	meshy = dst.find_bone("Hips") >= 0
	hip_fix = false   # (off: with the pelvis tilt dropped, a crouch folded his thighs into his belly - "his midsection folds in two", 23 Nov; posture is _upright's)
	s_pel = src.find_bone("Bip01_Pelvis")
	Cd = _char_frame(dst, nm("pelvis"), nm("neck_01"), nm("thigh_l"), nm("thigh_r"))
	var corr_of := {}   # src bone -> its correction (a finger's last joint takes its parent's: it has no child to aim it by -
	# with none it kept the rests' difference and the fingers tangled, 25 Nov)
	for sn in MAP:
		var s := src.find_bone(sn); var d := dst.find_bone(nm(MAP[sn]))
		if s < 0 or d < 0: continue
		var corr := Basis()
		var sc := src.get_bone_children(s); var dc := dst.get_bone_children(d)
		if (sc.size() == 0 or dc.size() == 0) and corr_of.has(src.get_bone_parent(s)):
			corr = corr_of[src.get_bone_parent(s)]
		elif sc.size() > 0 and dc.size() > 0:
			var sdir := Cs.inverse() * (src.get_bone_global_rest(sc[0]).origin - src.get_bone_global_rest(s).origin)
			var ddir := Cd.inverse() * (dst.get_bone_global_rest(dc[0]).origin - dst.get_bone_global_rest(d).origin)
			if sdir.length() > 1e-5 and ddir.length() > 1e-5 and sdir.normalized().dot(ddir.normalized()) < 0.99999:
				corr = Basis(Quaternion(ddir.normalized(), sdir.normalized()))
		# THE HANDS AND FINGERS by their whole frame - the direction and the hand's width (index root to little finger root):
		# by the direction alone a finger's roll was free, it curled round another axis - "his finger tips look crooked"
		if sn.contains("_Hand") or sn.contains("_Finger"):
			var side := "L" if sn.contains("_L_") else "R"; var sd := side.to_lower()
			var sdir2 := Vector3(); var ddir2 := Vector3()
			if sn.ends_with("_Hand"):   # (the hand toward its middle finger's root: its first child is not the same finger in both)
				sdir2 = Cs.inverse() * (src.get_bone_global_rest(src.find_bone("Bip01_%s_Finger2" % side)).origin - src.get_bone_global_rest(s).origin)
				ddir2 = Cd.inverse() * (dst.get_bone_global_rest(dst.find_bone(nm("middle_01_" + sd))).origin - dst.get_bone_global_rest(d).origin)
			elif sc.size() > 0 and dc.size() > 0:
				sdir2 = Cs.inverse() * (src.get_bone_global_rest(sc[0]).origin - src.get_bone_global_rest(s).origin)
				ddir2 = Cd.inverse() * (dst.get_bone_global_rest(dc[0]).origin - dst.get_bone_global_rest(d).origin)
			else:
				var sp := src.get_bone_parent(s); var dp := dst.get_bone_parent(d)
				sdir2 = Cs.inverse() * (src.get_bone_global_rest(s).origin - src.get_bone_global_rest(sp).origin)
				ddir2 = Cd.inverse() * (dst.get_bone_global_rest(d).origin - dst.get_bone_global_rest(dp).origin)
			var slat := Cs.inverse() * (src.get_bone_global_rest(src.find_bone("Bip01_%s_Finger1" % side)).origin - src.get_bone_global_rest(src.find_bone("Bip01_%s_Finger4" % side)).origin)
			var dlat := Cd.inverse() * (dst.get_bone_global_rest(dst.find_bone(nm("index_01_" + sd))).origin - dst.get_bone_global_rest(dst.find_bone(nm("pinky_01_" + sd))).origin)
			if sn.contains("_Finger0"):   # (the THUMB turns round its own axis: its root toward the index finger's root)
				slat = Cs.inverse() * (src.get_bone_global_rest(src.find_bone("Bip01_%s_Finger1" % side)).origin - src.get_bone_global_rest(src.find_bone("Bip01_%s_Finger0" % side)).origin)
				dlat = Cd.inverse() * (dst.get_bone_global_rest(dst.find_bone(nm("index_01_" + sd))).origin - dst.get_bone_global_rest(dst.find_bone(nm("thumb_01_" + sd))).origin)
			if sdir2.length() > 1e-5 and ddir2.length() > 1e-5:
				corr = _frame(sdir2, slat) * _frame(ddir2, dlat).inverse()
		if sn == "Bip01_Head":
			# THE HEAD by its whole frame - up its neck, across its ears: Meshy's head's first child is a bone pointing out of
			# its face ("headfront"), and aimed along it the head hung, chin down (Yasin 23 Nov)
			var sn2 := src.find_bone("Bip01_Neck"); var dn2 := dst.find_bone(nm("neck_01"))
			var su := Cs.inverse() * (src.get_bone_global_rest(s).origin - src.get_bone_global_rest(sn2).origin)
			var du := Cd.inverse() * (dst.get_bone_global_rest(d).origin - dst.get_bone_global_rest(dn2).origin)
			corr = _frame(su, Vector3(1, 0, 0)) * _frame(du, Vector3(1, 0, 0)).inverse()
		corr_of[s] = corr
		pairs.append([s, d, corr])
		if sn == "Bip01_Pelvis": d_pel = d
	var ds := pairs.map(func(p): return p[1])
	for i in dst.get_bone_count():
		if i in ds: order.append(i)
	var sl := (src.global_basis * (src.get_bone_global_rest(src.find_bone("Bip01_L_Foot")).origin - src.get_bone_global_rest(src.find_bone("Bip01_L_Thigh")).origin)).length()
	var dl := (dst.global_basis * (dst.get_bone_global_rest(dst.find_bone(nm("foot_l"))).origin - dst.get_bone_global_rest(dst.find_bone(nm("thigh_l"))).origin)).length()
	leg_k = dl / maxf(sl, 1e-4)
	# (the new body's ankle over its floor standing: its skeleton's origin is its floor)
	dst_ankle = (dst.global_basis * dst.get_bone_global_rest(dst.find_bone(nm("foot_l"))).origin).y
	d_feet = [dst.find_bone(nm("foot_l")), dst.find_bone(nm("foot_r"))]
	s_feet = [src.find_bone("Bip01_L_Foot"), src.find_bone("Bip01_R_Foot")]
	for f in ["index", "middle", "ring", "pinky", "thumb"]:
		for sd in ["l", "r"]: tips.append(dst.find_bone(nm("%s_03_%s" % [f, sd])))
	d_hands = [dst.find_bone(nm("hand_l")), dst.find_bone(nm("hand_r"))]
	if meshy:
		# (his hand to his height as the figure's: the figure 0.107, Meshy's 0.157 - wrist to the last finger joint)
		var hs := (src.get_bone_global_rest(src.find_bone("Bip01_R_Finger22")).origin - src.get_bone_global_rest(src.find_bone("Bip01_R_Hand")).origin).length() * src.global_basis.get_scale().x
		var ht := ((src.global_basis * src.get_bone_global_rest(src.find_bone("Bip01_Head")).origin).y - (src.global_basis * src.get_bone_global_rest(src.find_bone("Bip01_R_Foot")).origin).y)
		var hd := (dst.get_bone_global_rest(dst.find_bone(nm("middle_03_r"))).origin - dst.get_bone_global_rest(dst.find_bone(nm("hand_r"))).origin).length() * dst.global_basis.get_scale().x
		var htd := ((dst.global_basis * dst.get_bone_global_rest(dst.find_bone(nm("head"))).origin).y - (dst.global_basis * dst.get_bone_global_rest(dst.find_bone(nm("foot_r"))).origin).y)
		hand_scale = clampf((hs / ht) / maxf(hd / htd, 1e-4), 0.6, 1.0)
		print("HANDS scale %.2f" % hand_scale)
	_measure_torso()
	for side in ["l", "r"]: arms.append([dst.find_bone(nm("upperarm_" + side)), dst.find_bone(nm("lowerarm_" + side)), dst.find_bone(nm("hand_" + side))])
	var hl_s := (src.get_bone_global_rest(src.find_bone("Bip01_R_Finger2")).origin - src.get_bone_global_rest(src.find_bone("Bip01_R_Hand")).origin).length() * src.global_basis.get_scale().x
	var hl_d := (dst.get_bone_global_rest(dst.find_bone(nm("middle_01_r"))).origin - dst.get_bone_global_rest(dst.find_bone(nm("hand_r"))).origin).length() * dst.global_basis.get_scale().x
	hand_k = hl_d * hand_scale / maxf(hl_s, 1e-4)
	src.skeleton_updated.connect(_follow)
	ready_ok = true

func _frame(dir: Vector3, lat: Vector3) -> Basis:
	var x := dir.normalized()
	var z := x.cross(lat).normalized()
	return Basis(x, z.cross(x), z)

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
		if s == s_pel and hip_fix:
			# (the clip's pelvis tilt dropped - forward / back, about his left-right axis, x in the character frame: on
			# Meshy's deep body it curved the lower back and leaned him back - Yasin 23 Nov; turn and roll kept)
			var q := Quaternion(delta_c.orthonormalized())
			delta_c = Basis(q * Quaternion(q.x, 0.0, 0.0, q.w).normalized().inverse())
		var want := Cd * delta_c * (p[2] as Basis) * Cd.inverse() * dst.get_bone_global_rest(d).basis
		var par := dst.get_bone_parent(d)
		var par_g: Basis = cur.get(par, dst.get_bone_global_pose(par).basis if par >= 0 else Basis())
		var local := (par_g.inverse() * want).orthonormalized()
		dst.set_bone_pose_rotation(d, local.get_rotation_quaternion())
		cur[d] = par_g * local
	# THE FINGERTIPS (25 Nov: "fingertips arent flat"): bent as a share of the middle joint's own bend, round his own hinge -
	# copied, they hooked further than the joint before them
	for tip in tips:
		var mid_b: int = dst.get_bone_parent(tip)
		var md := dst.get_bone_rest(mid_b).basis.get_rotation_quaternion().inverse() * dst.get_bone_pose_rotation(mid_b)
		dst.set_bone_pose_rotation(tip, dst.get_bone_rest(tip).basis.get_rotation_quaternion() * Quaternion().slerp(md, 0.65))
	if d_pel >= 0:
		# (the hips: the figure's pelvis over its floor, its height scaled by the legs)
		var sp := src.global_transform * src.get_bone_global_pose(src.find_bone("Bip01_Pelvis")).origin
		var fy := src.global_position.y
		var target := Vector3(sp.x, fy + (sp.y - fy) * leg_k, sp.z)
		var par := dst.get_bone_parent(d_pel)
		var par_x := dst.global_transform * (dst.get_bone_global_pose(par) if par >= 0 else Transform3D())
		dst.set_bone_pose_position(d_pel, par_x.affine_inverse() * target)
		# THE FEET ON THE GROUND (25 Nov: "his feet was sunk in the ground"): the hips' height by the legs' length alone left
		# them under it - moved so his lower ankle is as high over the floor as the figure's is over its own (its own ankle's
		# height standing on each side)
		var s_lo := INF; var d_lo := INF
		for i in 2:
			s_lo = minf(s_lo, (src.global_transform * src.get_bone_global_pose(s_feet[i]).origin).y)
			d_lo = minf(d_lo, (dst.global_transform * dst.get_bone_global_pose(d_feet[i]).origin).y)
		var want_lo := fy + dst_ankle + (s_lo - fy - SRC_ANKLE)
		target.y += want_lo - d_lo
		dst.set_bone_pose_position(d_pel, par_x.affine_inverse() * target)
	if hand_scale < 0.999:
		for h in d_hands: dst.set_bone_pose_scale(h, Vector3.ONE * hand_scale)
	_upright()
	var idle := host != null and String(host.call(&"get_motor_state").get("state", "")) == "idle"
	if idle:
		_straight_back()
		_arms_forward()
	_bend_forward(20.0)   # (Yasin: 10, then "10 more")
	_tilt(dst.find_bone(nm("head")), -15.0)   # (Yasin: "lift the head 15 degrees back")
	_fit_arms()
	_carry_prop()

func _carry_prop() -> void:
	# THE PHONE (the motor puts it in the figure's hand, by the figure's own arms): moved by as much as the new body's hand is
	# from the figure's - both hands' average when the hands hold it together (texting), else the right's. Its turn kept: the
	# bones' directions are copied, the hands face the same way
	if host == null: return
	if prop == null:
		for c in host.get_children():
			if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh and ((c as MeshInstance3D).mesh as BoxMesh).size.y > 0.14: prop = c; break
		if prop == null: return
	if not prop.visible: return
	var sw := func(sk: Skeleton3D, n: String) -> Vector3: return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(n)).origin
	# (by the PALMS' middles - the wrist to the middle finger's root, 0.8 along: by the wrists, his longer hands left it under them)
	var palm := func(sk: Skeleton3D, h: String, f: String) -> Vector3: return (sw.call(sk, h) as Vector3).lerp(sw.call(sk, f), 0.8)
	var sl: Vector3 = palm.call(src, "Bip01_L_Hand", "Bip01_L_Finger2"); var sr: Vector3 = palm.call(src, "Bip01_R_Hand", "Bip01_R_Finger2")
	var dl: Vector3 = palm.call(dst, nm("hand_l"), nm("middle_01_l")); var dr: Vector3 = palm.call(dst, nm("hand_r"), nm("middle_01_r"))
	var d := (dr - sr) if (sl - sr).length() > 0.25 else ((dl - sl) + (dr - sr)) * 0.5
	prop.global_position += d

# HIS TORSO (25 Nov: "his hands clip thru his body ... sunk into his stomach"): the figure the moves were made on is thin;
# his arms, copied joint by joint, went into his chest and belly. Measured once from his own skin at rest: for the hips and
# each spine bone, the flesh around it in his character frame - half its width, its front, its back, over its height band
func _measure_torso() -> void:
	# (by shape: slices from the hips to the neck, the skin within his shoulder joints' width - the arms hang outside it at
	# rest - each slice turning with the spine bone nearest its height. By the skin's weights, few points have one bone)
	var names := ["pelvis", "spine_01", "spine_02", "spine_03"]
	var ids := names.map(func(n): return dst.find_bone(nm(n)))
	# (all of him: under his shirt and jeans the skin is hidden - the garments are his outside there)
	var meshes := dst.get_parent().find_children("*", "MeshInstance3D", true, false)
	var pel := Cd.inverse() * dst.get_bone_global_rest(dst.find_bone(nm("pelvis"))).origin
	var nk := Cd.inverse() * dst.get_bone_global_rest(dst.find_bone(nm("neck_01"))).origin
	var shw := absf((Cd.inverse() * dst.get_bone_global_rest(dst.find_bone(nm("upperarm_l"))).origin).x - pel.x)
	var arm_y := (Cd.inverse() * dst.get_bone_global_rest(dst.find_bone(nm("upperarm_l"))).origin).y
	var NB := 14
	var y0 := pel.y - 0.30 / dst.global_basis.get_scale().x; var y1 := nk.y   # (down to the middle of his thighs: hanging, his hands went into his jeans)
	var bands := []
	for i in NB: bands.append([0.0, 0.0, 0.0])
	var pts := PackedVector3Array()
	var free := PackedByteArray()   # (1: no arm in it - the trousers: his hips are wider than his shoulders' joints)
	for mm in meshes:
		var skin := mm as MeshInstance3D
		if skin.mesh == null: continue
		var to_sk := dst.global_transform.affine_inverse() * skin.global_transform
		# (a skinned mesh sits on its skeleton by its skin's binds: a bone's rest times its bind is the mesh -> skeleton map.
		# Meshy's mesh is in metres on a skeleton in centimetres; by the nodes' transforms the torso measured nothing)
		if skin.skin and skin.skin.get_bind_count() > 0:
			var bb := skin.skin.get_bind_bone(0)
			if bb < 0: bb = dst.find_bone(skin.skin.get_bind_name(0))
			if bb >= 0: to_sk = dst.get_bone_global_rest(bb) * skin.skin.get_bind_pose(0)
		for si in skin.mesh.get_surface_count():
			var nofree := 1 if (String(skin.name).contains("jeans") or String(skin.name).contains("pants") or String(skin.name).contains("trouser")) else 0
			for v in (skin.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX] as PackedVector3Array): pts.append(to_sk * v); free.append(nofree)
	for pi in pts.size():
		var pv := pts[pi]
		var q := Cd.inverse() * pv - pel
		var yy := q.y + pel.y
		# (a T-posed body - Meshy's - has no arm under its armpits: the full width counted there)
		var below_arms := meshy and yy < arm_y - (nk.y - pel.y) * 0.25
		if yy < y0 or yy >= y1 or (free[pi] == 0 and not below_arms and absf(q.x) > shw * 0.92): continue
		var bi := int((yy - y0) / (y1 - y0) * NB)
		var B: Array = bands[bi]
		B[0] = maxf(B[0], absf(q.x)); B[1] = maxf(B[1], q.z); B[2] = maxf(B[2], -q.z)
	for i in NB:
		var B: Array = bands[i]
		if B[0] <= 0.0: continue
		var ylo := y0 + (y1 - y0) * i / NB; var yhi := y0 + (y1 - y0) * (i + 1) / NB
		var best: int = ids[0]; var bd := INF
		for b in ids:
			var by := (Cd.inverse() * dst.get_bone_global_rest(b).origin).y
			if absf(by - (ylo + yhi) * 0.5) < bd: bd = absf(by - (ylo + yhi) * 0.5); best = b
		var rest := dst.get_bone_global_rest(best)
		var ry := (Cd.inverse() * rest.origin).y
		# (the slice's centre over the bone, in his frame: its lateral centre the pelvis's)
		torso.append([best, rest, B[0], B[1], B[2], ylo - ry, yhi - ry, (Cd.inverse() * rest.origin) - pel])
	print("TORSO ", torso.map(func(T): return "%s w %.2f f %.2f b %.2f" % [dst.get_bone_name(T[0]), T[2], T[3], T[4]]))

# a point (skeleton space) pushed out of his torso as posed now, by a margin (the arm's own flesh)
func _out_of_torso(p: Vector3, margin: float) -> Vector3:
	for T in torso:
		var b: int = T[0]
		var now := dst.get_bone_global_pose(b)
		var rest: Transform3D = T[1]
		var off: Vector3 = T[7]
		var q := Cd.inverse() * ((rest * now.affine_inverse() * p) - rest.origin) + Vector3(off.x, 0.0, off.z)   # (in the bone's rest, his character frame, from the torso's centre line)
		if q.y < T[5] or q.y > T[6]: continue
		var ax: float = T[2] + margin
		var az: float = (T[3] if q.z > 0.0 else T[4]) + margin
		var e := sqrt((q.x / ax) * (q.x / ax) + (q.z / az) * (q.z / az))
		if e >= 1.0 or e < 1e-4: continue
		var q2 := Vector3(q.x / e, q.y, q.z / e) - Vector3(off.x, 0.0, off.z)
		p = now * rest.affine_inverse() * (rest.origin + Cd * q2)
	return p

# two bones turned so the wrist reaches p_t, the elbow toward p_pole (skeleton space)
func _reach(ua: int, la: int, ha: int, p_t: Vector3, p_pole: Vector3) -> void:
	var S := dst.get_bone_global_pose(ua).origin; var E := dst.get_bone_global_pose(la).origin; var W := dst.get_bone_global_pose(ha).origin
	var l1 := (E - S).length(); var l2 := (W - E).length()
	var to := p_t - S; var d := clampf(to.length(), absf(l1 - l2) + 1e-4, l1 + l2 - 1e-4)
	var dir := to.normalized()
	var perp := (p_pole - S) - dir * (p_pole - S).dot(dir)
	if perp.length() < 1e-5: perp = (E - S) - dir * (E - S).dot(dir)
	perp = perp.normalized()
	var ca := clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0)
	var E2 := S + dir * (l1 * ca) + perp * (l1 * sqrt(1.0 - ca * ca))
	var W2 := S + dir * d
	_aim(ua, E - S, E2 - S)
	_aim(la, dst.get_bone_global_pose(ha).origin - dst.get_bone_global_pose(la).origin, W2 - E2)

func _aim(b: int, from: Vector3, to: Vector3) -> void:
	if from.length() < 1e-6 or to.length() < 1e-6: return
	var q := Quaternion(from.normalized(), to.normalized())
	var g := dst.get_bone_global_pose(b)
	var par := dst.get_bone_parent(b)
	var pg := dst.get_bone_global_pose(par).basis if par >= 0 else Basis()
	var ng := Basis(q) * g.basis
	dst.set_bone_pose_rotation(b, (pg.inverse() * ng).orthonormalized().get_rotation_quaternion())

func _fit_arms() -> void:
	if torso.is_empty() or arms.size() < 2: return
	var sc := dst.global_basis.get_scale().x   # (skeleton units per metre: margins in metres)
	var wr := [dst.get_bone_global_pose(arms[0][2]).origin, dst.get_bone_global_pose(arms[1][2]).origin]
	# (his bigger hands held as far apart as the figure's by their size: the texting grip overlapped his fingers)
	var mid: Vector3 = (wr[0] + wr[1]) * 0.5
	var sep: float = (wr[0] - wr[1]).length()
	if sep < 0.25 / sc and sep > 1e-5:
		var want := sep * hand_k
		var dv: Vector3 = (wr[0] - wr[1]).normalized()
		wr[0] = mid + dv * want * 0.5; wr[1] = mid - dv * want * 0.5
	for i in 2:
		var A: Array = arms[i]
		var el := dst.get_bone_global_pose(A[1]).origin
		var t: Vector3 = _out_of_torso(wr[i], 0.06 / sc)
		# (the forearm's middle too: pushed out, the wrist with it)
		var fm := _out_of_torso((el + t) * 0.5, 0.06 / sc)
		t += (fm - (el + t) * 0.5)
		var pole := _out_of_torso(el, 0.055 / sc)
		if (t - dst.get_bone_global_pose(A[2]).origin).length() > 1e-4 or (pole - el).length() > 1e-4:
			_reach(A[0], A[1], A[2], t, pole + (pole - el) * 2.0)

# HIS POSTURE AS THE FIGURE'S (Yasin 23 Nov: "he is leaning back too much again"): copied joint by joint, Meshy's deep
# chest put his shoulders behind his hips. His line from the hips to the neck turned onto the figure's, a third at
# each spine bone (a bend, not a hinge); the head and arms ride on it
func _upright() -> void:
	if not meshy: return
	var sp: int = src.find_bone("Bip01_Pelvis"); var sn: int = src.find_bone("Bip01_Neck")
	var dp := dst.find_bone(nm("pelvis")); var dn := dst.find_bone(nm("neck_01"))
	var wv := src.global_basis * (src.get_bone_global_pose(sn).origin - src.get_bone_global_pose(sp).origin)
	# (UPRIGHT, not the figure's lean: the old figure leans back in its idles too - Yasin 23 Nov, both screenshots. Leaning
	# back is taken out - held at 3 degrees forward; leaning forward, a run's, kept)
	var fw := (src.global_basis.orthonormalized() * (Cs * Vector3(0, 0, 1))); fw.y = 0.0
	if fw.length() > 1e-4 and wv.length() > 1e-4:
		fw = fw.normalized()
		var up_c := wv.y; var f_c := wv.dot(fw)
		var min_f := absf(up_c) * tan(deg_to_rad(3.0))
		if f_c < min_f: wv += fw * (min_f - f_c)
	var want := dst.global_basis.inverse() * wv
	var have := dst.get_bone_global_pose(dn).origin - dst.get_bone_global_pose(dp).origin
	if want.length() < 1e-6 or have.length() < 1e-6: return
	var q := Quaternion(have.normalized(), want.normalized())
	var part := Quaternion().slerp(q, 1.0 / 3.0)
	for k in ["spine_01", "spine_02", "spine_03"]:
		var b := dst.find_bone(nm(k))
		var g := dst.get_bone_global_pose(b)
		var par := dst.get_bone_parent(b)
		var pg := dst.get_bone_global_pose(par).basis if par >= 0 else Basis()
		dst.set_bone_pose_rotation(b, (pg.inverse() * (Basis(part) * g.basis)).orthonormalized().get_rotation_quaternion())
	# (and the head carried as the figure carries it: his neck-to-head line onto the figure's - it hung, chin down)
	var sh: int = src.find_bone("Bip01_Head"); var dh := dst.find_bone(nm("head"))
	var want2 := dst.global_basis.inverse() * (src.global_basis * (src.get_bone_global_pose(sh).origin - src.get_bone_global_pose(sn).origin))
	var have2 := dst.get_bone_global_pose(dh).origin - dst.get_bone_global_pose(dn).origin
	if want2.length() > 1e-6 and have2.length() > 1e-6:
		var g2 := dst.get_bone_global_pose(dn)
		var par2 := dst.get_bone_parent(dn)
		var pg2 := dst.get_bone_global_pose(par2).basis if par2 >= 0 else Basis()
		dst.set_bone_pose_rotation(dn, (pg2.inverse() * (Basis(Quaternion(have2.normalized(), want2.normalized())) * g2.basis)).orthonormalized().get_rotation_quaternion())
	# (and his FACE where the figure's looks: by the rests alone his face pointed 21 degrees lower, every frame - a
	# Meshy head bone whose face is its "headfront" child)
	var hf := dst.find_bone("headfront")
	if hf >= 0:
		var sf: Vector3 = dst.global_basis.inverse() * (src.global_basis.orthonormalized() * ((src.get_bone_global_pose(sh).basis * src.get_bone_global_rest(sh).basis.inverse()) * (Cs * Vector3(0, 0, 1))))
		var df := dst.get_bone_global_pose(hf).origin - dst.get_bone_global_pose(dh).origin
		# (the phone out in front - texting - his eyes on it; at the ear - a call - not)
		if prop != null and prop.visible:
			var hw := dst.global_transform * dst.get_bone_global_pose(dh).origin
			var to := prop.global_position - hw
			if to.length() > 0.3:
				sf = sf.normalized().slerp((dst.global_basis.inverse() * to).normalized(), 0.85)
		if sf.length() > 1e-6 and df.length() > 1e-6:
			var g3 := dst.get_bone_global_pose(dh)
			var pg3 := dst.get_bone_global_pose(dst.get_bone_parent(dh)).basis
			dst.set_bone_pose_rotation(dh, (pg3.inverse() * (Basis(Quaternion(df.normalized(), sf.normalized())) * g3.basis)).orthonormalized().get_rotation_quaternion())

# A STRAIGHT BACK standing (Yasin 23 Nov, a photo of a man standing straight; "back is still bent"): with only the line
# hips-to-neck upright, the spine between still curved. Standing idle each spine bone points along that line
func _straight_back() -> void:
	var dp := dst.find_bone(nm("pelvis")); var dn := dst.find_bone(nm("neck_01"))
	var line := dst.get_bone_global_pose(dn).origin - dst.get_bone_global_pose(dp).origin
	if line.length() < 1e-6: return
	var chain := [dst.find_bone(nm("spine_01")), dst.find_bone(nm("spine_02")), dst.find_bone(nm("spine_03")), dn]
	for i in 3:
		var b: int = chain[i]; var c: int = chain[i + 1]
		var seg := dst.get_bone_global_pose(c).origin - dst.get_bone_global_pose(b).origin
		if seg.length() < 1e-6: continue
		_aim(b, seg, line)

# THE ARMS AT HIS SIDES standing ("arms are still going behind his back"): his shoulders sit back in his deep chest, and
# the figure's hanging arms hung behind him. Each upper arm swung forward until the wrist hangs 3 cm ahead of the hips'
# joint, beside the thigh, as in the photo; never back
func _arms_forward() -> void:
	var f: Vector3 = dst.global_basis.inverse() * (src.global_basis.orthonormalized() * (Cs * Vector3(0, 0, 1)))
	var up: Vector3 = dst.global_basis.inverse() * Vector3.UP
	f -= up.normalized() * f.dot(up.normalized())
	if f.length() < 1e-6: return
	f = f.normalized()
	var sc := dst.global_basis.get_scale().x
	var hips := dst.get_bone_global_pose(dst.find_bone(nm("pelvis"))).origin
	for A in arms:
		var sh := dst.get_bone_global_pose(A[0]).origin; var wr := dst.get_bone_global_pose(A[2]).origin
		var ahead := (wr - hips).dot(f)
		var want := 0.03 / sc
		if ahead >= want: continue
		var lat := f.cross(up).normalized()
		var r := (wr - sh); r -= lat * r.dot(lat)
		if r.length() < 1e-6: continue
		var ang := atan2(want - ahead, r.length())
		var g := dst.get_bone_global_pose(A[0]); var par := dst.get_bone_parent(A[0])
		var pg := dst.get_bone_global_pose(par).basis if par >= 0 else Basis()
		var rot := Basis(lat, -ang)
		if (rot * (wr - sh)).dot(f) < (wr - sh).dot(f): rot = Basis(lat, ang)   # (whichever way swings it forward)
		dst.set_bone_pose_rotation(A[0], (pg.inverse() * (rot * g.basis)).orthonormalized().get_rotation_quaternion())

# HIS SPINE BENT FORWARD (Yasin 23 Nov, after the x-ray: "bend his spine forward 10 degrees"): Meshy's rig runs the spine
# along his back, so a straight spine reads as leaning back - the whole spine turned forward by p_deg about his left-right
# axis, a third at each spine bone; the head, neck and arms ride on it
func _bend_forward(p_deg: float) -> void:
	var f: Vector3 = dst.global_basis.inverse() * (src.global_basis.orthonormalized() * (Cs * Vector3(0, 0, 1)))
	var up: Vector3 = (dst.global_basis.inverse() * Vector3.UP).normalized()
	f -= up * f.dot(up)
	if f.length() < 1e-6: return
	var lat := f.normalized().cross(up).normalized()   # (turning about this tips the top forward, along f)
	var q := Quaternion(lat, deg_to_rad(p_deg / 3.0))
	# (the sign: whichever way moves a point above the joint forward)
	if (Basis(q) * up).dot(f.normalized()) < 0.0: q = q.inverse()
	for k in ["spine_01", "spine_02", "spine_03"]:
		var b := dst.find_bone(nm(k))
		var g := dst.get_bone_global_pose(b)
		var par := dst.get_bone_parent(b)
		var pg := dst.get_bone_global_pose(par).basis if par >= 0 else Basis()
		dst.set_bone_pose_rotation(b, (pg.inverse() * (Basis(q) * g.basis)).orthonormalized().get_rotation_quaternion())

# one bone tipped forward (+) / back (-) by p_deg about his left-right axis, all below it riding on it
func _tilt(b: int, p_deg: float) -> void:
	if b < 0: return
	var f: Vector3 = dst.global_basis.inverse() * (src.global_basis.orthonormalized() * (Cs * Vector3(0, 0, 1)))
	var up: Vector3 = (dst.global_basis.inverse() * Vector3.UP).normalized()
	f -= up * f.dot(up)
	if f.length() < 1e-6: return
	f = f.normalized()
	var q := Quaternion(f.cross(up).normalized(), deg_to_rad(absf(p_deg)))
	var fwd_q := (Basis(q) * up).dot(f) > 0.0
	if fwd_q != (p_deg > 0.0): q = q.inverse()
	var g := dst.get_bone_global_pose(b)
	var par := dst.get_bone_parent(b)
	var pg := dst.get_bone_global_pose(par).basis if par >= 0 else Basis()
	dst.set_bone_pose_rotation(b, (pg.inverse() * (Basis(q) * g.basis)).orthonormalized().get_rotation_quaternion())
