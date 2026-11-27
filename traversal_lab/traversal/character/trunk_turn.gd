extends SkeletonModifier3D
## A custom correction (the study, Part 2: "Custom corrections: a script extending `SkeletonModifier3D` ... apply
## 100 %; let `influence` blend"). Stage 18: "turn the shoulders from 0.45 to 0.60 m starting half a metre before".
## Turns the trunk about the upright: a quarter of it in the lower back and the rest in the mid-back (the study:
## "the neck turns 85 degrees each way, the mid-back 47, the lower back only 15"), and turns the neck back by the
## same, so that he goes on looking where he is going. His arms are kept swinging along his way.

var turn_deg := 0.0             # how far the shoulders are turned (set by character.gd)

var _low := -1
var _mid := -1
var _neck := -1
var _arms: Array[int] = []


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or turn_deg == 0.0:
		return
	if _low < 0:
		_low = sk.find_bone("mixamorig_Spine")
		_mid = sk.find_bone("mixamorig_Spine1")
		_neck = sk.find_bone("mixamorig_Neck")
		_arms = [sk.find_bone("mixamorig_LeftArm"), sk.find_bone("mixamorig_RightArm")]
	if _low < 0 or _mid < 0 or _neck < 0:
		return
	for part: Array in [[_low, 0.25], [_mid, 0.75], [_neck, -1.0]]:
		var g := sk.get_bone_global_pose(int(part[0]))
		g.basis = Basis(Vector3.UP, deg_to_rad(turn_deg * float(part[1]))) * g.basis
		sk.set_bone_global_pose(int(part[0]), g)
	# The arms go on swinging along the way he is going, not across it with the turned trunk: swung with the trunk
	# his hands went up to 0.09 m into the walls of a 0.50 m gap at a walk (measured). Each upper arm is turned back
	# about the upright by what the trunk was turned.
	for arm: int in _arms:
		var g := sk.get_bone_global_pose(arm)
		g.basis = Basis(Vector3.UP, -deg_to_rad(turn_deg)) * g.basis
		sk.set_bone_global_pose(arm, g)
