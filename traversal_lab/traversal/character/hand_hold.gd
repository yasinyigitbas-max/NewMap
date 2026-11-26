extends SkeletonModifier3D
## After the arm IK: while a hand is held on something (a vault, later the climbs), the hand itself is kept turned as
## it was when it came down, instead of turning with the forearm as the body goes past it. Without this the wrist
## stayed in its place but the hand rocked about it from tick to tick (Yasin, 26 Nov: "hand jitters a lot on vaults").

var place: SkeletonModifier3D           # hand_place.gd: which hand is held, and how much (hold_w)
var _hand := [-1, -1]
var _kept: Array = [Basis.IDENTITY, Basis.IDENTITY]     # the hand's turn in the world as it came down
var _on := [false, false]


func _process_modification_with_delta(_dt: float) -> void:
	var sk := get_skeleton()
	if sk == null or place == null:
		return
	if _hand[0] < 0:
		_hand = [sk.find_bone("mixamorig_LeftHand"), sk.find_bone("mixamorig_RightHand")]
	var w: Array = place.get(&"hold_w")
	var world := sk.global_transform.basis.orthonormalized()
	for f in 2:
		var g := sk.get_bone_global_pose(_hand[f])
		if float(w[f]) <= 0.0:
			_on[f] = false
			continue
		if not _on[f]:
			_on[f] = true
			_kept[f] = (world * g.basis).orthonormalized()
		var want := (world.inverse() * (_kept[f] as Basis)).orthonormalized()
		g.basis = g.basis.orthonormalized().slerp(want, clampf(float(w[f]), 0.0, 1.0))
		sk.set_bone_global_pose(_hand[f], g)
