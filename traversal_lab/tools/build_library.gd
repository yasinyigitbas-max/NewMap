extends SceneTree
## Makes the animation library the AnimationTree plays (traversal/character/library.res) from the baked clips
## (traversal/character/clips/*.res). The study, Part 2: "Import each clip file as an Animation Library ... Set
## `root_motion_track` to the `Root` bone", and the root bone "takes ground-plane travel and turning from the hips,
## leave the hips' vertical movement in the hips".
##
## For every clip: a rotation track per bone, the hips' position (what is left when the root has taken the travel:
## height, sway and the to-and-fro of a stride), and the Root bone's own track (travel over the ground, and turning).
##   - a loop: the root travels in a straight line at an even speed (the study's Stage 2: "steady forward travel with
##     no side-to-side wobble"), and the clip is turned so that line is straight ahead;
##   - any other clip: the root takes the hips' travel along the clip's own line of travel, and the hips' turning.
## Mirror images ("_M") are made for the clips that exist for one side only.
## Run:  godot --headless --path traversal_lab -s res://tools/build_library.gd

const DIR := "res://traversal/character/clips/"
const MODEL := "res://traversal/character/player_v4_rooted.scn"
const OUT := "res://traversal/character/library.res"
const SKEL := "Skeleton3D"
const MIRRORED := ["Female_Stop_Walking", "Run_To_Stop", "Left_Turn_90", "Walking_Turn_180", "Running_Turn_180", "Female_Start_Walking", "Idle_To_Sprint"]
const TURN_LEAST_DEG := 20.0        # a clip that turns less than this is not a turning clip: its root does not turn
# In the air the body does the rising and the falling (the study: the body "alone decides where the character is"), so
# the clip's own rise is taken out: between leaving the ground and landing the hips keep at most their take-off height.
# [leaves the ground, lands] in seconds, measured on the clips.
const AIR := {"Jump": [0.80, 1.30], "Running_Jump": [0.10, 0.67]}
# Landing clips begin high up, where their fall began: the hips are never above standing height.
const GROUNDED := ["Falling_To_Landing", "Hard_Landing"]
# Ledge clips (step off, fall, land) are played on the spot: the body does the travelling and the falling, so the hips
# keep only their height above the clip's own landing ground.
const LEDGE := ["KM_Ledge_Walk_Off", "KM_Ledge_Run_Off"]


func _initialize() -> void:
	var model: Node = (load(MODEL) as PackedScene).instantiate()
	var sk: Skeleton3D = model.get_node(SKEL)
	var lib := AnimationLibrary.new()
	var parents := PackedInt32Array()
	var rest: Array[Quaternion] = []
	var pair := PackedInt32Array()
	var names := PackedStringArray()
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".res"):
			names.append(f.get_basename())
	names.sort()
	var first: Resource = load(DIR + names[0] + ".res")
	var bones: PackedStringArray = first.get(&"bones")
	for i in bones.size():
		var b := sk.find_bone(bones[i])
		var p := sk.get_bone_parent(b)
		parents.append(bones.find(sk.get_bone_name(p)) if p >= 0 else -1)
		rest.append(sk.get_bone_global_rest(b).basis.get_rotation_quaternion())
		var other := bones[i].replace("Left", "#").replace("Right", "Left").replace("#", "Right")
		pair.append(bones.find(other) if bones.find(other) >= 0 else i)
	var stand := sk.get_bone_rest(sk.find_bone("mixamorig_Hips")).origin
	for n in names:
		var c: Resource = load(DIR + n + ".res")
		lib.add_animation(n, _animation(c, n, stand.y))
		if MIRRORED.has(n):
			lib.add_animation(n + "_M", _animation(c.call(&"mirrored", parents, rest, pair), n, stand.y))
	# The study: "`deterministic` is on by default, so include a RESET animation": the pose every blend starts from
	var reset := Animation.new()
	reset.length = 0.001
	for b in sk.get_bone_count():
		var t := reset.add_track(Animation.TYPE_ROTATION_3D)
		reset.track_set_path(t, NodePath("%s:%s" % [SKEL, sk.get_bone_name(b)]))
		reset.rotation_track_insert_key(t, 0.0, sk.get_bone_rest(b).basis.get_rotation_quaternion())
	for bn: String in ["Root", "mixamorig_Hips"]:
		var t := reset.add_track(Animation.TYPE_POSITION_3D)
		reset.track_set_path(t, NodePath("%s:%s" % [SKEL, bn]))
		reset.position_track_insert_key(t, 0.0, sk.get_bone_rest(sk.find_bone(bn)).origin)
	lib.add_animation("RESET", reset)
	var err := ResourceSaver.save(lib, OUT, ResourceSaver.FLAG_COMPRESS)
	print("%s: %d animations; saved: %d" % [OUT, lib.get_animation_list().size(), err])
	quit(0 if err == OK else 1)


func _animation(c: Resource, name: String, stand_y: float) -> Animation:
	var a := Animation.new()
	var frames := int(c.get(&"frames"))
	var fps := float(c.get(&"fps"))
	var loop := bool(c.get(&"loop"))
	var bones: PackedStringArray = c.get(&"bones")
	var rot: PackedFloat32Array = c.get(&"rot")
	var hips: PackedVector3Array = c.get(&"hips")
	var yaw: PackedFloat32Array = c.get(&"yaw")
	var travel: Vector3 = c.get(&"travel")
	var n := bones.size()
	a.length = float(frames - 1) / fps
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	a.step = 1.0 / fps
	var total := Vector2(travel.x, travel.z).length()
	var dir := Vector3(travel.x, 0.0, travel.z) / total if total >= 0.02 else Vector3.ZERO
	# a loop is turned so that its line of travel is straight ahead (+Z in the model)
	var aim := Quaternion.IDENTITY
	if loop and total >= 0.02:
		aim = Quaternion(Vector3.UP, -atan2(dir.x, dir.z))
	var turning: bool = not loop and not yaw.is_empty() and absf(rad_to_deg(yaw[frames - 1])) >= TURN_LEAST_DEG
	var hips_i := bones.find("mixamorig_Hips")
	var t_root_p := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(t_root_p, NodePath("%s:Root" % SKEL))
	var t_root_r := a.add_track(Animation.TYPE_ROTATION_3D)
	a.track_set_path(t_root_r, NodePath("%s:Root" % SKEL))
	var t_hips_p := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(t_hips_p, NodePath("%s:mixamorig_Hips" % SKEL))
	var tracks := PackedInt32Array()
	for b in n:
		var t := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(t, NodePath("%s:%s" % [SKEL, bones[b]]))
		tracks.append(t)
	var start := Vector3(hips[0].x, 0.0, hips[0].z)
	for f in frames:
		var time := float(f) / fps
		var u := float(f) / float(maxi(frames - 1, 1))
		var rel := Vector3(hips[f].x, 0.0, hips[f].z) - start
		var root_pos := Vector3.ZERO
		if total >= 0.02:
			root_pos = dir * (total * u) if loop else dir * rel.dot(dir)
		var root_rot := Quaternion(Vector3.UP, yaw[f]) if turning else Quaternion.IDENTITY
		var local := root_rot.inverse() * (aim * (rel - root_pos))
		var y := hips[f].y
		if AIR.has(name) and time >= float(AIR[name][0]) and time <= float(AIR[name][1]):
			y = minf(y, hips[int(round(float(AIR[name][0]) * fps))].y)
		if GROUNDED.has(name):
			y = minf(y, stand_y)
		if LEDGE.has(name):
			y = minf(y - hips[frames - 1].y + stand_y, stand_y)
			local = Vector3.ZERO
			root_pos = Vector3.ZERO
		a.position_track_insert_key(t_root_p, time, aim * root_pos)
		a.rotation_track_insert_key(t_root_r, time, root_rot)
		a.position_track_insert_key(t_hips_p, time, Vector3(local.x, y, local.z))
		for b in n:
			var o := (f * n + b) * 4
			var q := Quaternion(rot[o], rot[o + 1], rot[o + 2], rot[o + 3])
			if b == hips_i:
				q = (root_rot.inverse() * aim * q).normalized()
			a.rotation_track_insert_key(tracks[b], time, q)
	return a
