extends SkeletonModifier3D
## A custom correction (the study, Part 2: "Custom corrections: a script extending `SkeletonModifier3D` ... apply
## 100 %; let `influence` blend"). Swings each upper arm out from the chest, about the chest's own front-to-back line,
## so it follows the twist of the trunk; the forearm and hand go with it.
## Why: Yasin's play-test of 25 Nov, "his arms are almost sticking to his body, they need to open up a bit". The clips
## were captured on a slimmer body than his.

var flat := 0.0                 # 0 to 1: his arms are laid into the plane of his chest (sideways in a gap or on a ledge: an elbow
                                # the take holds 4 cm forward of it was that far into the wall of a 0.26 m gap). Set by character.gd
var _fore := [-1, -1]
var _hand := [-1, -1]
var open_deg := 9.0             # NOT in the study: set by eye on his body

var _arm := [-1, -1]
var _chest := -1
var _chest_rest_inv := Basis.IDENTITY


func _skeleton_changed(_old: Skeleton3D, sk: Skeleton3D) -> void:
	_bind(sk)


func _bind(sk: Skeleton3D) -> void:
	if sk == null:
		return
	_arm = [sk.find_bone("mixamorig_LeftArm"), sk.find_bone("mixamorig_RightArm")]
	_chest = sk.find_bone("mixamorig_Spine2")
	_fore = [sk.find_bone("mixamorig_LeftForeArm"), sk.find_bone("mixamorig_RightForeArm")]
	_hand = [sk.find_bone("mixamorig_LeftHand"), sk.find_bone("mixamorig_RightHand")]
	if _chest >= 0:
		_chest_rest_inv = sk.get_bone_global_rest(_chest).basis.orthonormalized().inverse()


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or open_deg == 0.0:
		return
	if _chest < 0:
		_bind(sk)
	if _chest < 0 or _arm[0] < 0 or _arm[1] < 0:
		return
	var fwd := (sk.get_bone_global_pose(_chest).basis.orthonormalized() * _chest_rest_inv) * Vector3(0.0, 0.0, 1.0)
	for side in 2:
		var g := sk.get_bone_global_pose(_arm[side])
		g.basis = Basis(fwd.normalized(), deg_to_rad(open_deg) * (1.0 if side == 0 else -1.0)) * g.basis
		sk.set_bone_global_pose(_arm[side], g)
		if flat > 0.0:
			# the upper arm, then the forearm: each turned the shortest way into the plane square to `fwd`
			for pair: Array in [[_arm[side], _fore[side]], [_fore[side], _hand[side]]]:
				var b := sk.get_bone_global_pose(int(pair[0]))
				var d := (sk.get_bone_global_pose(int(pair[1])).origin - b.origin).normalized()
				var in_plane := d - fwd.normalized() * d.dot(fwd.normalized())
				if in_plane.length() < 0.2:
					continue
				var axis := d.cross(in_plane.normalized())
				if axis.length() < 0.0001:
					continue
				b.basis = Basis(axis.normalized(), d.angle_to(in_plane.normalized()) * flat) * b.basis
				sk.set_bone_global_pose(int(pair[0]), b)
