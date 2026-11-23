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
var idle_w := 0.0
var ear_rest := Vector3()
var ear_ok := false
var idle_clock := 0.0
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
		# (the body's child that MATCHES the figure's first child, by name: a file's children can come in another order - the
		# re-rigged body's Hips listed its left thigh first, and aimed along it the whole body twisted)
		if sc.size() > 0 and dc.size() > 0:
			var want_name: String = nm(MAP.get(src.get_bone_name(sc[0]), ""))
			for c in dc:
				if dst.get_bone_name(c) == want_name:
					dc = PackedInt32Array([c]); break
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
		hand_scale = minf(hand_scale * 1.21, 1.0)   # (Yasin 23 Nov: "they look too small now though. grow them by 10 percent", then "10 more")
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
	if meshy: _shoulders_down(16.0)   # (Yasin 23 Nov: "push shoulders down a bit he looks like he is shrugging" - 8, then "8 more")   # (BEFORE the arms are placed: after them, the collarbones' turn swung the hanging arms into his body)
	var idle := host != null and String(host.call(&"get_motor_state").get("state", "")) == "idle"
	# (standing: the posture solved from his landmarks - _stand. The angles tried one by one before it - spine 20 forward,
	# 5 more from the hip, neck and head 15 back each - replaced: Yasin 23 Nov, "study human anatomy a little")
	# STANDING ARMS AS IN YASIN'S PHOTO (23 Nov: "his arms are reaching behind his body as if his hands are tied from the
	# back, look at the reference photo"): eased in while he stands, out as he moves off
	var now := Time.get_ticks_msec() / 1000.0
	var dt := clampf(now - idle_clock, 0.0, 0.1); idle_clock = now
	idle_w = move_toward(idle_w, 1.0 if idle else 0.0, dt * 3.0)
	if idle_w > 0.001:
		_stand(idle_w)
		_idle_arms(idle_w)
		_relaxed_hands(idle_w)
	if idle_w < 0.99: _fit_arms()   # (standing, the arms are as Yasin set them: upper arm vertical, forearm 20 forward)
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
	# THE EAR (the plumb line's top): the head's middle, front to back, 11 cm under its top, on his centre line
	var top := -INF
	for pv in pts:
		var q := Cd.inverse() * pv - pel
		if absf(q.x) < 0.11 / dst.global_basis.get_scale().x and q.y + pel.y > nk.y: top = maxf(top, q.y + pel.y)
	if top > -INF:
		var ey := top - 0.11 / dst.global_basis.get_scale().x
		var zmin := INF; var zmax := -INF
		for pv in pts:
			var q := Cd.inverse() * pv - pel
			if absf(q.x) < 0.11 / dst.global_basis.get_scale().x and absf(q.y + pel.y - ey) < 0.02 / dst.global_basis.get_scale().x:
				zmin = minf(zmin, q.z); zmax = maxf(zmax, q.z)
		if zmax > zmin:
			ear_rest = Cd * Vector3(0.0, ey - pel.y, (zmin + zmax) * 0.5) + Cd * pel
			ear_ok = true
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

# the shoulders (clavicles) moved forward p_m metres along his facing, the arms with them
func _shoulders_forward(p_m: float) -> void:
	var f: Vector3 = dst.global_basis.inverse() * (src.global_basis.orthonormalized() * (Cs * Vector3(0, 0, 1)))
	var up: Vector3 = (dst.global_basis.inverse() * Vector3.UP).normalized()
	f -= up * f.dot(up)
	if f.length() < 1e-6: return
	f = f.normalized()
	var sc := dst.global_basis.get_scale().x
	for side in ["l", "r"]:
		var b := dst.find_bone(nm("clavicle_" + side))
		if b < 0: continue
		var par := dst.get_bone_parent(b)
		var pg := dst.get_bone_global_pose(par) if par >= 0 else Transform3D()
		# (from its rest place under its parent as posed now - not from last frame's, which already had the push: it piled up)
		var want := pg * dst.get_bone_rest(b).origin + f * (p_m / sc)
		dst.set_bone_pose_position(b, pg.affine_inverse() * want)

# his torso's middle, front to back, at the hips: the skin measured (the joints sit at his back), skeleton units ahead of
# the pelvis joint along his facing
func _hip_centre_ahead() -> float:
	for T in torso:
		if T[0] == dst.find_bone(nm("pelvis")) and T[5] <= 0.0 and T[6] >= 0.0:
			return (float(T[3]) - float(T[4])) * 0.5
	return 0.0

func _idle_arms(w: float) -> void:
	var sc := dst.global_basis.get_scale().x
	var f: Vector3 = dst.global_basis.inverse() * (src.global_basis.orthonormalized() * (Cs * Vector3(0, 0, 1)))
	var up: Vector3 = (dst.global_basis.inverse() * Vector3.UP).normalized()
	f -= up * f.dot(up)
	if f.length() < 1e-6: return
	f = f.normalized()
	var lat := up.cross(f).normalized()   # (his left)
	var pel := dst.get_bone_global_pose(dst.find_bone(nm("pelvis"))).origin
	var ahead := _hip_centre_ahead()
	var half_w := 0.0
	for T in torso:
		if T[0] == dst.find_bone(nm("pelvis")): half_w = maxf(half_w, float(T[2]))
	for i in 2:
		var side := 1.0 if i == 0 else -1.0   # (arms[0] is the left)
		# the collarbone rolled forward 12 degrees: the shoulder comes round to the front, the skin turning with it
		var cb := dst.find_bone(nm("clavicle_" + ("l" if i == 0 else "r")))
		if cb >= 0:
			var q := Quaternion(up, deg_to_rad(12.0 * w))
			var g := dst.get_bone_global_pose(cb)
			var tip := dst.get_bone_global_pose(arms[i][0]).origin - g.origin
			if (Basis(q) * tip).dot(f) < tip.dot(f): q = q.inverse()
			var par := dst.get_bone_parent(cb)
			var pg := dst.get_bone_global_pose(par).basis if par >= 0 else Basis()
			dst.set_bone_pose_rotation(cb, (pg.inverse() * (Basis(q) * g.basis)).orthonormalized().get_rotation_quaternion())
		var A: Array = arms[i]
		var wr := dst.get_bone_global_pose(A[2]).origin
		var el := dst.get_bone_global_pose(A[1]).origin
		# the wrist beside the thigh: just outside the hips' width, 12 cm under the hip joint, at the body's middle depth
		# (at the THIGH's middle depth where the hand hangs, 2 cm ahead of it - the hand by the trouser's side seam, as in the
		# photo; at the hips' middle it hung back - "his hands are still reaching back")
		var goal_h := pel - up * (0.12 / sc)
		var tc := _band_centre_at(goal_h)
		var goal := tc + lat * side * (half_w + 0.035 / sc) + f * (0.02 / sc)
		goal -= lat * (goal - pel).dot(lat) - lat * side * (half_w + 0.035 / sc)   # (its side: by the hips' width)
		goal -= up * (goal - goal_h).dot(up)                                       # (its height)
		# (first to beside the thigh - its outward angle from the front; then, SEEN FROM THE SIDE - Yasin 23 Nov: "make the
		# upper arm bone completely vertical to ground, bend the arm from elbow 20 degree forward ... i was talking about
		# his side profile": the upper arm's forward / back tilt taken out, the forearm 20 degrees forward of it)
		var pole := el + lat * side * (0.3 / sc) - f * (0.06 / sc)
		_reach(A[0], A[1], A[2], wr.lerp(goal, w), pole)
		var sh := dst.get_bone_global_pose(A[0]).origin
		el = dst.get_bone_global_pose(A[1]).origin
		var ua := el - sh
		var ua_side := ua - f * ua.dot(f)
		_aim(A[0], ua, ua.slerp(ua_side.normalized() * ua.length(), w))
		el = dst.get_bone_global_pose(A[1]).origin
		var fa0 := dst.get_bone_global_pose(A[2]).origin - el
		var fa_front := fa0 - f * fa0.dot(f)
		if fa_front.length() > 1e-6:
			var fdir := (fa_front.normalized() * cos(deg_to_rad(20.0)) + f * sin(deg_to_rad(20.0))).normalized()
			_aim(A[1], fa0, fa0.slerp(fdir * fa0.length(), w))
		# the hand hanging on from the forearm, palm to the thigh
		var fa := dst.get_bone_global_pose(A[2]).origin - dst.get_bone_global_pose(A[1]).origin
		var mid := dst.find_bone(nm("middle_01_" + ("l" if i == 0 else "r")))
		if mid >= 0:
			var hd := dst.get_bone_global_pose(mid).origin - dst.get_bone_global_pose(A[2]).origin
			var want := hd.slerp(fa.normalized() * hd.length(), w * 0.8)
			_aim(A[2], hd, want)

# a torso slice's middle (front to back, on his centre line) as posed now, the slice nearest the given point's height
func _band_centre_at(p: Vector3) -> Vector3:
	var best: Array = []; var bd := INF
	for T in torso:
		var now := dst.get_bone_global_pose(T[0]); var rest: Transform3D = T[1]; var off: Vector3 = T[7]
		var c_rest: Vector3 = rest.origin + Cd * Vector3(-off.x, (float(T[5]) + float(T[6])) * 0.5, (float(T[3]) - float(T[4])) * 0.5 - off.z)
		var c := now * rest.affine_inverse() * c_rest
		var d := absf((c - p).dot((dst.global_basis.inverse() * Vector3.UP).normalized()))
		if d < bd: bd = d; best = [c]
	return best[0] if not best.is_empty() else p

# STANDING, ANATOMICALLY (the plumb line): the shoulders' middle over the hips' middle (the spine turned, a third at each
# bone), the ear over the shoulders (the neck turned), the face level (the head turned) - landmarks from his body's shape,
# not his joints (Meshy's sit along his back)
func _stand(w: float) -> void:
	var f: Vector3 = dst.global_basis.inverse() * (src.global_basis.orthonormalized() * (Cs * Vector3(0, 0, 1)))
	var up: Vector3 = (dst.global_basis.inverse() * Vector3.UP).normalized()
	f -= up * f.dot(up)
	if f.length() < 1e-6: return
	f = f.normalized()
	var pel := dst.get_bone_global_pose(dst.find_bone(nm("pelvis"))).origin
	var shj := (dst.get_bone_global_pose(arms[0][0]).origin + dst.get_bone_global_pose(arms[1][0]).origin) * 0.5
	# 1. the shoulders' middle over the hips' middle
	for it in 2:
		var H := _band_centre_at(pel)
		var S := _band_centre_at((dst.get_bone_global_pose(arms[0][0]).origin + dst.get_bone_global_pose(arms[1][0]).origin) * 0.5)
		var v := S - H; var want := v - f * v.dot(f) * w
		_turn_chain([dst.find_bone(nm("spine_01")), dst.find_bone(nm("spine_02")), dst.find_bone(nm("spine_03"))], H, v, want)
	# 2. the ear over the shoulders' middle
	if ear_ok:
		var hb := dst.find_bone(nm("head")); var nb := dst.find_bone(nm("neck_01"))
		var hr := dst.get_bone_global_rest(hb)
		var E := dst.get_bone_global_pose(hb) * (hr.affine_inverse() * ear_rest)
		var S2 := _band_centre_at((dst.get_bone_global_pose(arms[0][0]).origin + dst.get_bone_global_pose(arms[1][0]).origin) * 0.5)
		var nkp := dst.get_bone_global_pose(nb).origin
		var v2 := E - nkp
		var want2 := v2 - f * ((E - S2).dot(f)) * w
		_turn_chain([nb], nkp, v2, want2)
		# 3. the face level: the head's forward pointer (Meshy's "headfront") level, 3 degrees down
		var hf := dst.find_bone("headfront")
		if hf >= 0:
			var fv := dst.get_bone_global_pose(hf).origin - dst.get_bone_global_pose(hb).origin
			# (straight ahead along his facing - no turn to a side: Yasin 23 Nov, "turn his face to face the camera directly ...
			# his view in front"; the take's own head turn had it 8 degrees to his right)
			var target := (f - up * 0.05).normalized() * fv.length()
			_aim(hb, fv, fv.slerp(target, w))

# a chain of bones turned (each a share) so the vector v from the point o becomes want
func _turn_chain(bones: Array, o: Vector3, v: Vector3, want: Vector3) -> void:
	if v.length() < 1e-6 or want.length() < 1e-6: return
	var q := Quaternion(v.normalized(), want.normalized())
	var part := Quaternion().slerp(q, 1.0 / bones.size())
	for b in bones:
		if b < 0: continue
		var g := dst.get_bone_global_pose(b)
		var par := dst.get_bone_parent(b)
		var pg := dst.get_bone_global_pose(par).basis if par >= 0 else Basis()
		dst.set_bone_pose_rotation(b, (pg.inverse() * (Basis(part) * g.basis)).orthonormalized().get_rotation_quaternion())

# THE RELAXED HANGING HAND (Yasin 23 Nov: "study how hands connect to the lower arm and which position they sit in
# naturally ... his fingertips are still curled in"): the wrist straight on from the forearm, the palm to the thigh with
# the thumb's side forward; the fingers in the resting cascade - a gentle bend growing from the index to the little
# finger (knuckle 8-20, middle joint 15-30, last joint 5-12 degrees), not curled into the palm; the thumb along the
# index's side, a little bent
const REST_BEND := {"index": [8.0, 15.0, 5.0], "middle": [12.0, 20.0, 7.0], "ring": [16.0, 25.0, 9.0], "pinky": [20.0, 30.0, 12.0]}

func _relaxed_hands(w: float) -> void:
	var f: Vector3 = dst.global_basis.inverse() * (src.global_basis.orthonormalized() * (Cs * Vector3(0, 0, 1)))
	var up: Vector3 = (dst.global_basis.inverse() * Vector3.UP).normalized()
	f -= up * f.dot(up)
	if f.length() < 1e-6: return
	f = f.normalized()
	for i in 2:
		var sd := "l" if i == 0 else "r"
		var A: Array = arms[i]
		var hb: int = A[2]
		var fa := (dst.get_bone_global_pose(hb).origin - dst.get_bone_global_pose(A[1]).origin).normalized()   # the forearm, down
		var mid := dst.find_bone(nm("middle_01_" + sd)); var ix := dst.find_bone(nm("index_01_" + sd)); var pk := dst.find_bone(nm("pinky_01_" + sd))
		if mid < 0 or ix < 0 or pk < 0: continue
		# 1. the hand: its length along the forearm, its width (index to little finger knuckle) pointing forward
		var hd := dst.get_bone_global_pose(mid).origin - dst.get_bone_global_pose(hb).origin
		var wd := dst.get_bone_global_pose(ix).origin - dst.get_bone_global_pose(pk).origin
		var cur := _frame(hd, wd)
		var fw := f - fa * f.dot(fa)
		if fw.length() < 1e-6: continue
		var tgt := _frame(fa, fw.normalized())
		var R := Basis(Quaternion().slerp(Quaternion((tgt * cur.inverse()).orthonormalized()), w))
		var g := dst.get_bone_global_pose(hb); var par := dst.get_bone_parent(hb)
		var pg := dst.get_bone_global_pose(par).basis if par >= 0 else Basis()
		dst.set_bone_pose_rotation(hb, (pg.inverse() * (R * g.basis)).orthonormalized().get_rotation_quaternion())
		# the palm's side, as placed: toward his middle
		var hand_dir := (dst.get_bone_global_pose(mid).origin - dst.get_bone_global_pose(hb).origin).normalized()
		var width := (dst.get_bone_global_pose(ix).origin - dst.get_bone_global_pose(pk).origin).normalized()
		var palm := hand_dir.cross(width).normalized()
		var hips := dst.get_bone_global_pose(dst.find_bone(nm("pelvis"))).origin
		if palm.dot(hips - dst.get_bone_global_pose(hb).origin) < 0.0: palm = -palm
		# 2. the fingers: each segment bent toward the palm from the one before
		for fname in REST_BEND:
			var prev := hand_dir
			for k in 3:
				var b := dst.find_bone(nm("%s_%02d_%s" % [fname, k + 1, sd]))
				if b < 0: break
				var nxt := dst.find_bone(nm("%s_%02d_%s" % [fname, k + 2, sd])) if k < 2 else -1
				var gb := dst.get_bone_global_pose(b)
				var seg := (dst.get_bone_global_pose(nxt).origin - gb.origin) if nxt >= 0 else gb.basis.y * 1.0
				if seg.length() < 1e-6: break
				var a := deg_to_rad((REST_BEND[fname] as Array)[k])
				var pn := (palm - prev * palm.dot(prev)).normalized()
				var want := (prev * cos(a) + pn * sin(a)).normalized() * seg.length()
				_aim(b, seg, seg.slerp(want, w))
				prev = want.normalized()
		# 3. the thumb: along the index's side - down and a little forward, toward the palm a little; slightly bent
		var t1 := dst.find_bone(nm("thumb_01_" + sd))
		if t1 >= 0:
			var prev_t := (hand_dir * cos(deg_to_rad(20.0)) + width * sin(deg_to_rad(20.0))).normalized()
			prev_t = (prev_t + palm * 0.4).normalized()
			for k in 3:
				var b := dst.find_bone(nm("thumb_%02d_%s" % [k + 1, sd]))
				if b < 0: break
				var nxt := dst.find_bone(nm("thumb_%02d_%s" % [k + 2, sd])) if k < 2 else -1
				var gb := dst.get_bone_global_pose(b)
				var seg := (dst.get_bone_global_pose(nxt).origin - gb.origin) if nxt >= 0 else gb.basis.y * 1.0
				if seg.length() < 1e-6: break
				var want := prev_t * seg.length()
				_aim(b, seg, seg.slerp(want, w))
				var pn2 := (palm - prev_t * palm.dot(prev_t)).normalized()
				prev_t = (prev_t * cos(deg_to_rad(10.0)) + pn2 * sin(deg_to_rad(10.0))).normalized()

# the shoulders lowered: each collarbone turned down p_deg about his facing, the shoulder's end dropping (a shrug let go)
func _shoulders_down(p_deg: float) -> void:
	var f: Vector3 = dst.global_basis.inverse() * (src.global_basis.orthonormalized() * (Cs * Vector3(0, 0, 1)))
	var up: Vector3 = (dst.global_basis.inverse() * Vector3.UP).normalized()
	f -= up * f.dot(up)
	if f.length() < 1e-6: return
	f = f.normalized()
	for i in 2:
		var cb := dst.find_bone(nm("clavicle_" + ("l" if i == 0 else "r")))
		if cb < 0: continue
		var g := dst.get_bone_global_pose(cb)
		var tip := dst.get_bone_global_pose(arms[i][0]).origin - g.origin
		var q := Quaternion(f, deg_to_rad(p_deg))
		if (Basis(q) * tip).dot(up) > tip.dot(up): q = q.inverse()   # (whichever way drops the shoulder's end)
		var par := dst.get_bone_parent(cb)
		var pg := dst.get_bone_global_pose(par).basis if par >= 0 else Basis()
		dst.set_bone_pose_rotation(cb, (pg.inverse() * (Basis(q) * g.basis)).orthonormalized().get_rotation_quaternion())
