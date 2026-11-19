extends SceneTree
## A sheet of the Quaternius clips on the game's own figure (fitted by tools/city/traffic/make_anims.gd), for a look by
## eye. Twelve figures in a row, each held at one moment of one clip. A small window, leaves by itself:
##   godot --path . --rendering-method mobile --resolution 1280x420 -s res://tests/people/clip_shots.gd -- --out=OUT/clip_shots [--body=M1]
const WHAT := [["ual/Walk_Loop", 0.25], ["ual/Walk_Loop", 0.9], ["ual/Sprint_Loop", 0.2], ["ual/Idle_Loop", 0.5], ["ual/Idle_TalkingPhone_Loop", 1.0], ["ual/Idle_FoldArms_Loop", 1.0],
	["ual/Sitting_Idle_Loop", 0.5], ["ual/Crouch_Idle_Loop", 0.5], ["ual/Punch_Jab", 0.35], ["ual/LayToIdle", 0.0], ["ual/LayToIdle", 0.75], ["ual/LayToIdle", 1.45]]
var out := "OUT/clip_shots"
var body := "M1"
var n := 0

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--body="): body = a.trim_prefix("--body=")
	if not ClassDB.class_exists(&"CityPed"): print("CLIPS ERROR no native module"); quit(1); return
	DirAccess.make_dir_recursive_absolute(out)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.7, 0.78, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(60, 20); fl.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.45, 0.46, 0.48); fl.material_override = fm; root.add_child(fl)
	for k in WHAT.size():
		var p: Node3D = ClassDB.instantiate(&"CityPed")
		p.set(&"body_id", body); p.set(&"clip", String(WHAT[k][0]))
		p.position = Vector3((float(k) - 5.5) * 1.5, 0, 0); p.rotation.y = deg_to_rad(35.0)      # (a little turned, so that front and side both show)
		root.add_child(p)
		p.set(&"clip_at", float(WHAT[k][1]))
	var cam := Camera3D.new(); cam.fov = 30.0; cam.position = Vector3(0, 1.6, 19.0); root.add_child(cam); cam.look_at(Vector3(0, 0.9, 0)); cam.current = true

func _process(_delta: float) -> bool:
	n += 1
	if n < 12: return false
	root.get_texture().get_image().save_png("%s/sheet.png" % out)
	print("CLIPS sheet of %d poses saved (%s): %s" % [WHAT.size(), body, str(WHAT)])
	quit(0)
	return true
