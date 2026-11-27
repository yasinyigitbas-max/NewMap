extends SkeletonModifier3D
## For an NPC body only (the player has no such correction): the first of his corrections.
## A custom correction (the study, Part 2: "Custom corrections: a script extending `SkeletonModifier3D`").
##
## The clips are the player's. They hold the hips at the height the PLAYER's legs need; an NPC made on Meshy has his
## own legs (the study: "A clip copies joint angles, so the same clip on this body takes strides about 13 % shorter
## and reaches about 8 cm less with each arm"), so with the same joint angles his feet end up above the ground: 2 cm
## for a man of the player's size, 9 cm for a woman of 1.61 m (measured, trav83).
## Each tick this works out, for the pose the clip gives, how low the player's lower foot would be and how low this
## body's lower foot is, and moves the hips by the difference: his lower foot is then as far off the clip's ground
## as the player's would be. Nothing is asked of the clip and no number is set by hand: both bodies are read from
## their own skeletons. The foot placement that follows (foot_place.gd) does the rest, as it does for the player.

const PLAYER := "res://traversal/character/player_v4_rooted.scn"
const LEG := ["UpLeg", "Leg", "Foot", "ToeBase"]

var leg := 1.0                  # this body's leg, hip joint to ankle joint, over the player's (read by npc_character.gd)
var seat := 0.0                 # 0 = he is carried by his feet, 1 = by a seat (set by npc_character.gd): the hips are
                                # then put where his hip joints are as high as the player's would be, on the seat
var moved := 0.0                # how far the hips were moved this tick (m, down is positive): for the readout and tests
var _hips := -1
var _chain := [[], []]          # this body's leg bones, hip joint to toe, for each side
var _theirs := [[], []]         # where each of those bones sits in its parent at rest ON THE PLAYER
var _sole := [0.0, 0.0]         # this body's ankle joint and toe joint above the ground at rest
var _sole_p := [0.0, 0.0]       # the player's


func bind(sk: Skeleton3D) -> void:
	var scene: Node = (load(PLAYER) as PackedScene).instantiate()
	var p := _skel(scene)
	_hips = sk.find_bone("mixamorig_Hips")
	var side := ["Left", "Right"]
	for f in 2:
		var mine := []
		var theirs := []
		for n: String in LEG:
			var name := "mixamorig_%s%s" % [side[f], n]
			mine.append(sk.find_bone(name))
			theirs.append(p.get_bone_rest(p.find_bone(name)).origin)
		_chain[f] = mine
		_theirs[f] = theirs
	var mine_len := sk.get_bone_rest(int(_chain[0][1])).origin.length() + sk.get_bone_rest(int(_chain[0][2])).origin.length()
	leg = mine_len / ((_theirs[0][1] as Vector3).length() + (_theirs[0][2] as Vector3).length())
	_sole = [sk.get_bone_global_rest(int(_chain[0][2])).origin.y, sk.get_bone_global_rest(int(_chain[0][3])).origin.y]
	_sole_p = [p.get_bone_global_rest(p.find_bone("mixamorig_LeftFoot")).origin.y, p.get_bone_global_rest(p.find_bone("mixamorig_LeftToeBase")).origin.y]
	scene.free()


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or _hips < 0:
		return
	var hips := sk.get_bone_global_pose(_hips)
	var low := INF              # this body's lower foot above the clip's ground
	var low_p := INF            # the player's, in the same pose
	for f in 2:
		var g := Transform3D(hips.basis.orthonormalized(), hips.origin)
		for k in 4:
			var b := int(_chain[f][k])
			g = g * Transform3D(Basis(sk.get_bone_pose_rotation(b)), _theirs[f][k])
			if k >= 2:
				low_p = minf(low_p, g.origin.y - float(_sole_p[k - 2]))
				low = minf(low, sk.get_bone_global_pose(b).origin.y - float(_sole[k - 2]))
	moved = low - low_p
	if seat > 0.0:
		var joint := 0.0        # his hip joints against the player's, in this pose
		for f in 2:
			joint += (sk.get_bone_global_pose(int(_chain[f][0])).origin.y - (hips.basis.orthonormalized() * (_theirs[f][0] as Vector3)).y - hips.origin.y) * 0.5
		moved = lerpf(moved, joint, clampf(seat, 0.0, 1.0))
	hips.origin.y -= moved
	sk.set_bone_global_pose(_hips, hips)


func _skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _skel(c)
		if s:
			return s
	return null
