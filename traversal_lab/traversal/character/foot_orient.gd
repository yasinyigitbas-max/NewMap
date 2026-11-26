extends SkeletonModifier3D
## Runs after the leg IK: the IK has moved the shins, so each foot is turned to the way it should point (the clip's
## own foot, tilted to the ground under it), as foot_place.gd worked it out. The study lists as unknown "whether
## `TwoBoneIK3D` orients the hand or foot to the target", so the foot is turned here and not left to the solver.

var place: SkeletonModifier3D
var _foot := [-1, -1]


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or place == null:
		return
	if _foot[0] < 0:
		_foot = [sk.find_bone("mixamorig_LeftFoot"), sk.find_bone("mixamorig_RightFoot")]
	var goal: Array = place.get(&"goal")
	for f in 2:
		var t := sk.get_bone_global_pose(_foot[f])
		t.basis = goal[f]
		sk.set_bone_global_pose(_foot[f], t)
