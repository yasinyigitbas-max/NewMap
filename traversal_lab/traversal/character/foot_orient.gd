extends SkeletonModifier3D
## Runs after the leg IK: the IK has moved the shins, so each foot is turned back to the way it should point
## (the clip's own foot, kept where it was planted and tilted to the ground under it).

var feet: RefCounted


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or feet == null:
		return
	var foot: Array = feet.get(&"foot")
	var shin: Array = feet.get(&"shin")
	var goal: Array = feet.get(&"foot_goal")
	for f in 2:
		var parent := sk.get_bone_global_pose(shin[f]).basis.orthonormalized()
		sk.set_bone_pose_rotation(foot[f], (parent.inverse() * (goal[f] as Basis)).get_rotation_quaternion())
