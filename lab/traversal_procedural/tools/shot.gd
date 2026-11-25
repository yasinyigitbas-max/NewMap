extends SceneTree
# Tool: renders frames of main.tscn for checking poses (needs a display: xvfb-run).
# godot -s tools/shot.gd -- <scenario> <out_prefix> <frames comma list> [view: side|front|back|follow|top] [dist]
# Scenarios: rest (poser off), idle, walk, run, start_stop, turn180, analog
var player
var cam_rig
var cam: Camera3D
var scenario := "idle"
var prefix := "/tmp/shot"
var frames := []
var view := "side"
var dist := 3.0
var f := 0

func _init():
	var a = OS.get_cmdline_user_args()
	if a.size() > 0: scenario = a[0]
	if a.size() > 1: prefix = a[1]
	if a.size() > 2:
		for s in a[2].split(","): frames.append(int(s))
	if a.size() > 3: view = a[3]
	if a.size() > 4: dist = float(a[4])
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	player = m.get_node("Player")
	cam_rig = m.get_node("CameraRig")
	cam = Camera3D.new()
	m.add_child(cam)
	cam.current = true
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cam_rig.set_process(false)

func stick_for(fr: int) -> Array:
	# returns [stick Vector2, run bool]
	match scenario:
		"walk": return [Vector2(0, 1), false]
		"run": return [Vector2(0, 1), true]
		"start_stop":
			if fr < 30: return [Vector2.ZERO, false]
			if fr < 150: return [Vector2(0, 1), false]
			return [Vector2.ZERO, false]
		"run_stop":
			if fr < 30: return [Vector2.ZERO, false]
			if fr < 180: return [Vector2(0, 1), true]
			return [Vector2.ZERO, false]
		"turn180":
			if fr < 150: return [Vector2(0, 1), true]
			return [Vector2(0, -1), true]
		"circle":
			var t = fr / 60.0
			return [Vector2(sin(t * 0.8), cos(t * 0.8)), true]
		_: return [Vector2.ZERO, false]
	return [Vector2.ZERO, false]

func _process(_d) -> bool:
	if f == 1 and scenario == "rest":
		var poser = player.find_children("*", "LabPoser", true, false)[0]
		poser.active = false
		var sk = poser.get_parent()
		sk.reset_bone_poses()
	cam.current = true
	var s = stick_for(f)
	player.set_scripted_input(s[0], s[1], true)
	var hips = player.global_position + Vector3(0, 0.9, 0)
	match view:
		"side": cam.global_position = hips + Vector3(dist, 0.0, 0)
		"front": cam.global_position = hips + Vector3(0, 0.0, dist)
		"back": cam.global_position = hips + Vector3(0, 0.3, -dist)
		"top": cam.global_position = hips + Vector3(0.01, dist, 0)
		"low": cam.global_position = hips + Vector3(dist, -0.6, 0.0)
		"follow": cam.global_position = hips + Vector3(dist * 0.7, 0.4, -dist * 0.7)
	if view == "top":
		cam.look_at(hips, Vector3(0, 0, 1))
	else:
		cam.look_at(hips, Vector3.UP)
	if frames.has(f - 2):
		var img = root.get_viewport().get_texture().get_image()
		img.save_png("%s_%04d.png" % [prefix, f - 2])
	var last = frames.max() if frames.size() > 0 else 2
	f += 1
	return f > last + 3
