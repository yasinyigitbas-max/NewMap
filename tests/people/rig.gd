## The bone names the tests know (the old Bip01 figure's) on a body imported onto Godot's standard humanoid skeleton:
## the same table as native/src/rig_names.h. Rig.find(sk, "Bip01_L_Hand") -> the old bone, else "LeftHand".
const MID := {"Pelvis": "Hips", "Spine": "Spine", "Spine1": "Chest", "Spine2": "UpperChest", "Neck": "Neck", "Head": "Head"}
const LIMB := {"Clavicle": "Shoulder", "UpperArm": "UpperArm", "Forearm": "LowerArm", "Hand": "Hand", "Thigh": "UpperLeg", "Calf": "LowerLeg", "Foot": "Foot"}
const F := ["Thumb", "Index", "Middle", "Ring", "Little"]
const PH := ["Proximal", "Intermediate", "Distal"]
const PT := ["Metacarpal", "Proximal", "Distal"]

static func standard(bip: String) -> String:
	if not bip.begins_with("Bip01_"): return ""
	var n := bip.substr(6)
	if MID.has(n): return MID[n]
	if n.length() < 3 or n[1] != "_": return ""
	var side := "Left" if n[0] == "L" else ("Right" if n[0] == "R" else "")
	var part := n.substr(2)
	if side == "": return ""
	if LIMB.has(part): return side + LIMB[part]
	if part.begins_with("Finger") and part.length() >= 7:
		var f := int(part[6]); var j := int(part[7]) if part.length() > 7 else 0
		return side + F[f] + (PT[j] if f == 0 else PH[j])
	return ""

static func find(sk: Skeleton3D, name: String) -> int:
	var b := sk.find_bone(name)
	if b >= 0: return b
	var s := standard(name)
	return sk.find_bone(s) if s != "" else -1
