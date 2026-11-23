extends SceneTree
## The standard skeleton (Godot's SkeletonProfileHumanoid): one BoneMap per source rig, used by the scene importer's
## retarget options (tools/people/humanoid/set_import.py). Every body and every clip imported through these shares the
## same bone names and the same rest axes, so any clip plays on any body.
##   godot --headless --path . -s res://tools/people/humanoid/make_bonemaps.gd
const OUT := "res://assets/people/humanoid/"
const FINGERS := {"Thumb": ["Metacarpal", "Proximal", "Distal"], "Index": ["Proximal", "Intermediate", "Distal"],
	"Middle": ["Proximal", "Intermediate", "Distal"], "Ring": ["Proximal", "Intermediate", "Distal"],
	"Little": ["Proximal", "Intermediate", "Distal"]}
const SRC_FINGER := {"Thumb": "Thumb", "Index": "Index", "Middle": "Middle", "Ring": "Ring", "Little": "Pinky"}

func _map(spine: Array, neck: String, pre: String) -> Dictionary:
	var m := {"Hips": "Hips", "Spine": spine[0], "Chest": spine[1], "UpperChest": spine[2], "Neck": neck, "Head": "Head"}
	for s in ["Left", "Right"]:
		m[s + "Shoulder"] = s + "Shoulder"; m[s + "UpperArm"] = s + "Arm"; m[s + "LowerArm"] = s + "ForeArm"; m[s + "Hand"] = s + "Hand"
		m[s + "UpperLeg"] = s + "UpLeg"; m[s + "LowerLeg"] = s + "Leg"; m[s + "Foot"] = s + "Foot"; m[s + "Toes"] = s + "ToeBase"
		for f in FINGERS:
			for i in 3: m[s + f + FINGERS[f][i]] = "%sHand%s%d" % [s, SRC_FINGER[f], i + 1]
	for k in m: m[k] = pre + m[k]
	return m

func _save(m: Dictionary, file: String) -> void:
	var bm := BoneMap.new(); bm.profile = SkeletonProfileHumanoid.new()
	for k in m: bm.set_skeleton_bone_name(StringName(k), StringName(m[k]))
	print(file, " ", ResourceSaver.save(bm, OUT + file))

func _init():
	_save(_map(["Spine", "Spine1", "Spine2"], "Neck", "mixamorig_"), "bonemap_mixamo.tres")
	# Meshy names its spine from the top down (Spine02 is the lowest) and the neck in lower case
	_save(_map(["Spine02", "Spine01", "Spine"], "neck", ""), "bonemap_meshy.tres")
	quit()
