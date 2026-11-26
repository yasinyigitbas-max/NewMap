extends SkeletonModifier3D
## A custom correction (the study, Part 2: "Custom corrections: a script extending `SkeletonModifier3D` ... apply
## 100 %; let `influence` blend"). Swings each upper arm out from the chest, about the chest's own front-to-back line,
## so it follows the twist of the trunk; the forearm and hand go with it.
## Why: Yasin's play-test of 25 Nov, "his arms are almost sticking to his body, they need to open up a bit". The clips
## were captured on a slimmer body than his.

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
