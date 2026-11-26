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
		# A hand laid flat on a top (the grab and climb; Yasin, 26 Nov: "check the climbs hand placements for high
		# climb, it looks a few cms off": the hand stood on edge in front of the wall, fingers up, touching nothing).
		# In the rest pose the palm faces down and the fingers point out to the side: turned a quarter about the
		# upright they point the way he faces, palm still down.
		var flat: Array = place.get(&"hold_flat")
		if bool(flat[f]):
			want = (Basis(Vector3.UP, -PI * 0.5 if f == 0 else PI * 0.5) * sk.get_bone_global_rest(_hand[f]).basis).orthonormalized()
		g.basis = g.basis.orthonormalized().slerp(want, clampf(float(w[f]), 0.0, 1.0))
		sk.set_bone_global_pose(_hand[f], g)
