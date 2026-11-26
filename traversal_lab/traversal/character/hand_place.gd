extends SkeletonModifier3D
## The hands on the ground, for the takes that put them there (Yasin, 26 Nov: "in both 45 dg ramp up and down, hands
## dont touch the floor"). The study's order of corrections has the arm `TwoBoneIK3D` after the legs', and its reason:
## "Body proportions differ from the capture, so without this the hands will miss."
## A take made on its own slope brings a hand down toward ITS ground; the real ground is steeper or shallower and
## somewhere else. While the take holds a hand near its own ground, this sets that arm's IK target on the real ground
## under the hand; as the take lifts the hand away the arm goes back to the clip. It only sets targets: the arms are
## solved by Godot's TwoBoneIK3D (one for each arm, the modifiers after this one).

const PALM := 0.08              # the study, Part 3: "Hand heights below are wrist joints; the gripping palm is about
                                # 0.08 m further along": the wrist rests this far off the ground the palm is on
const BAND := 0.15              # NOT in the study: the reach fades out as the take lifts the hand this far above its lowest (m)
const STRAIGHT := 0.995         # as for the legs: "never let the target be further than the limb's length minus a small margin"
const HIPS_MOST := 0.20         # NOT in the study: the most the hips come down for the hands (m)
const EASE := 0.10              # NOT in the study: seconds to ease the reach in and out

var body: CharacterBody3D
var on := false                 # a take that puts hands down is showing
var clip_slope := 0.0           # that take's own ground: its rise per metre forward
var hand_low := 0.0             # how near the take's own ground its hands come at their lowest (m, at the wrist)
var target: Array[Node3D] = []
var pole: Array[Node3D] = []
var ik: Array[SkeletonModifier3D] = []
var hips_down := 0.0            # how far the hips must come down for a reaching hand to get there (m): read by foot_place.gd
var reach := [0.0, 0.0]         # for the readout and the audit: how far each arm's reach is on (0..1)

var _upper := [-1, -1]
var _fore := [-1, -1]
var _hand := [-1, -1]
var _len := [0.0, 0.0]


func bind(sk: Skeleton3D) -> void:
	var side := ["Left", "Right"]
	for f in 2:
		_upper[f] = sk.find_bone("mixamorig_%sArm" % side[f])
		_fore[f] = sk.find_bone("mixamorig_%sForeArm" % side[f])
		_hand[f] = sk.find_bone("mixamorig_%sHand" % side[f])
		_len[f] = sk.get_bone_rest(_fore[f]).origin.length() + sk.get_bone_rest(_hand[f]).origin.length()


func _process_modification_with_delta(dt: float) -> void:
	var sk := get_skeleton()
	if sk == null or body == null or target.size() < 2 or ik.size() < 2 or _hand[0] < 0:
		return
	var xf := sk.global_transform
	var inv := xf.affine_inverse()
	var grounded := int(body.get(&"state")) == 0
	var short := -1.0           # the most any reaching arm is short of its ground (m; below 0 = none is)
	var reaching := false
	for f in 2:
		var shoulder_s := sk.get_bone_global_pose(_upper[f]).origin
		var elbow_s := sk.get_bone_global_pose(_fore[f]).origin
		var hand_s := sk.get_bone_global_pose(_hand[f]).origin
		var want := 0.0
		var goal := hand_s
		if on and grounded:
			# how high the take holds this hand over its own ground, against the lowest it ever brings it
			var over := hand_s.y - clip_slope * hand_s.z - hand_low
			want = clampf(1.0 - over / BAND, 0.0, 1.0)
			if want > 0.0:
				var hand: Vector3 = xf * hand_s
				var q := PhysicsRayQueryParameters3D.create(hand + Vector3(0.0, 1.0, 0.0), hand - Vector3(0.0, 1.5, 0.0), body.collision_mask, [body.get_rid()])
				var hit := body.get_world_3d().direct_space_state.intersect_ray(q)
				if hit.is_empty():
					want = 0.0
				else:
					goal = inv * ((hit["position"] as Vector3) + (hit["normal"] as Vector3) * PALM)
		reach[f] = move_toward(reach[f], want, dt / EASE)
		# never further than the arm is long
		var to := goal - shoulder_s
		var most: float = float(_len[f]) * STRAIGHT
		if want > 0.0:
			reaching = true
			short = maxf(short, (to.length() - most) * want)
		if to.length() > most:
			to = to.normalized() * most
		target[f].position = shoulder_s + to
		# the elbow keeps the side the take bends it to (the study: the pole "behind the elbow"), square to the arm's
		# line as it now is
		var line := to.normalized()
		var bend := elbow_s - (shoulder_s + hand_s) * 0.5
		var square := bend - line * bend.dot(line)
		if square.length() < 0.02:
			var back := sk.get_bone_global_pose(sk.get_bone_parent(_upper[f])).basis * Vector3(0.0, 0.0, -1.0) + Vector3.DOWN
			square = back - line * back.dot(line)
		pole[f].position = shoulder_s + to * 0.5 + square.normalized() * 0.5
		ik[f].influence = reach[f]
	# An arm that cannot reach the ground: the hips come down just far enough, as they do for a foot that cannot
	# (foot_place.gd does it, with the legs; found a little at a time, since the shoulders come down with the hips)
	if reaching:
		hips_down = clampf(hips_down + short * 0.5, 0.0, HIPS_MOST)
	else:
		hips_down = move_toward(hips_down, 0.0, HIPS_MOST * dt / (3.0 * EASE))
