extends SkeletonModifier3D
## A custom correction (the study, Part 2: "Custom corrections: a script extending `SkeletonModifier3D`"). Closes the
## four fingers of a hand round something held: each finger is laid out straight from the hand as in the rest pose,
## then bent toward the palm at its three joints. The study: "everyday grips use about 61, 60 and 39 degrees at the
## three finger joints" (and: "Fingers curl about 100 degrees at the middle knuckle and 80 at the end knuckle").
## The thumb is laid toward a point given (on the phone's face or edge): each of its joints is turned to point at it. Yasin, 27 Nov: "make the fingers grab the phone properly during phone call".

var w := [0.0, 0.0]             # how much, for his left and his right hand (0 to 1)
var deg := [[61.0, 60.0, 39.0], [61.0, 60.0, 39.0]]     # the bend at each finger's three joints, for each hand

var thumb_to := [Vector3.ZERO, Vector3.ZERO]     # where each thumb's tip is laid (skeleton space), with `thumb_w`
var thumb_w := [0.0, 0.0]

var _thumb := [[], []]
var _hand := [-1, -1]
var _knuckle := [[-1, -1, -1], [-1, -1, -1]]            # first finger, middle finger, little finger: their first joints
var _fingers := [[], []]        # for each hand: four fingers of three bones each
var _palm_sign := 1.0


func _bind(sk: Skeleton3D) -> void:
	var side := ["Left", "Right"]
	for f in 2:
		_hand[f] = sk.find_bone("mixamorig_%sHand" % side[f])
		_knuckle[f] = [sk.find_bone("mixamorig_%sHandIndex1" % side[f]), sk.find_bone("mixamorig_%sHandMiddle1" % side[f]), sk.find_bone("mixamorig_%sHandPinky1" % side[f])]
		var fingers := []
		for name: String in ["Index", "Middle", "Ring", "Pinky"]:
			fingers.append([sk.find_bone("mixamorig_%sHand%s1" % [side[f], name]), sk.find_bone("mixamorig_%sHand%s2" % [side[f], name]), sk.find_bone("mixamorig_%sHand%s3" % [side[f], name])])
		_fingers[f] = fingers
		_thumb[f] = [sk.find_bone("mixamorig_%sHandThumb1" % side[f]), sk.find_bone("mixamorig_%sHandThumb2" % side[f]), sk.find_bone("mixamorig_%sHandThumb3" % side[f]), sk.find_bone("mixamorig_%sHandThumb4" % side[f])]
	# out of the palm of his right hand: in the rest pose (arms out to the sides) the palm faces the ground
	var rw := sk.get_bone_global_rest(_hand[1]).origin
	var ri := sk.get_bone_global_rest(int(_knuckle[1][0])).origin
	var rp := sk.get_bone_global_rest(int(_knuckle[1][2])).origin
	_palm_sign = 1.0 if (ri - rw).cross(rp - rw).dot(Vector3.DOWN) > 0.0 else -1.0


## A hand's own frame in the pose as it now is: [wrist, along the fingers, out of the palm, across from the little
## finger to the first finger, how far the knuckles are from the wrist]. `f`: 0 his left hand, 1 his right.
func hand_frame(sk: Skeleton3D, f: int) -> Array:
	if _hand[0] < 0:
		_bind(sk)
	var wr := sk.get_bone_global_pose(_hand[f]).origin
	var i1 := sk.get_bone_global_pose(int(_knuckle[f][0])).origin
	var m1 := sk.get_bone_global_pose(int(_knuckle[f][1])).origin
	var p1 := sk.get_bone_global_pose(int(_knuckle[f][2])).origin
	var along := (m1 - wr).normalized()
	# (the two hands are mirror images: the same cross product points out of one palm and into the other)
	var out := ((i1 - wr).cross(p1 - wr) * _palm_sign * (-1.0 if f == 0 else 1.0)).normalized()
	return [wr, along, out, (i1 - p1).normalized(), (m1 - wr).length()]


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	if _hand[0] < 0:
		_bind(sk)
	for f in 2:
		var much := clampf(float(w[f]), 0.0, 1.0)
		if much <= 0.0 or _hand[f] < 0:
			continue
		var fr: Array = hand_frame(sk, f)
		var axis := (fr[1] as Vector3).cross(fr[2] as Vector3).normalized()         # about this a finger bends toward the palm
		var hand := sk.get_bone_global_pose(_hand[f])
		for finger: Array in _fingers[f]:
			var parent := hand
			for j in 3:
				var b := int(finger[j])
				if b < 0:
					break
				var t := parent * sk.get_bone_rest(b)
				var bent := (Basis(axis, deg_to_rad(float(deg[f][j]))) * t.basis).orthonormalized()
				var now := (parent.basis * sk.get_bone_pose(b).basis).orthonormalized()
				t.basis = now.slerp(bent, much)
				sk.set_bone_global_pose(b, t)
				parent = t
		# the thumb: laid out from the hand as in the rest pose, each joint then turned the shortest way to point at
		# the place its tip belongs
		var tw := clampf(float(thumb_w[f]), 0.0, 1.0)
		var chain: Array = _thumb[f]
		if tw > 0.0 and chain.size() == 4 and int(chain[0]) >= 0:
			var parent2 := sk.get_bone_global_pose(_hand[f])
			for j in 3:
				var b2 := int(chain[j])
				var t2 := parent2 * sk.get_bone_rest(b2)
				var from := (t2.basis * sk.get_bone_rest(int(chain[j + 1])).origin).normalized()
				var to := ((thumb_to[f] as Vector3) - t2.origin).normalized()
				var ax := from.cross(to)
				var aimed := t2.basis.orthonormalized()
				if ax.length() > 0.0001:
					aimed = (Basis(ax.normalized(), from.angle_to(to)) * aimed).orthonormalized()
				var now2 := (parent2.basis * sk.get_bone_pose(b2).basis).orthonormalized()
				t2.basis = now2.slerp(aimed, tw)
				sk.set_bone_global_pose(b2, t2)
				parent2 = t2
