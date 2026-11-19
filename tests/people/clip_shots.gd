extends SceneTree
## A sheet of the Quaternius clips on the game's own figure (fitted by tools/city/traffic/make_anims.gd), for a look by
## eye. Twelve figures in a row, each held at one moment of one clip. A small window, leaves by itself:
##   godot --path . --rendering-method mobile --resolution 1280x420 -s res://tests/people/clip_shots.gd -- --out=OUT/clip_shots [--body=M1]
const WHAT := [["ual/Sitting_Enter", 0.5], ["ual/GroundSit_Idle_Loop", 0.5], ["ual/GroundSit_Exit", 0.6], ["ual/IdleToLay", 0.9], ["ual/Crouch_Enter", 0.3], ["ual/PunchKick_Enter", 0.5],
	["ual/Kick", 0.4], ["ual/Melee_Hook", 0.35], ["ual/Hit_Head", 0.25], ["ual/Hit_Knockback", 0.4], ["ual/Surprise", 0.4], ["ual/Swim_Fwd_Loop", 0.5]]
## --set=2: the second dozen (the counter, the phone, the small things)
const WHAT2 := [["ual/Counter_Idle_Loop", 0.5], ["ual/Counter_Give", 0.5], ["ual/Counter_Show", 0.6], ["ual/Counter_Angry", 0.5], ["ual/Idle_Torch_Loop", 0.5], ["ual/Idle_Lantern_Loop", 0.5],
	["ual/Idle_Tired_Loop", 0.8], ["ual/Drink", 0.8], ["ual/Consume", 0.8], ["ual/Idle_Rail_Loop", 0.5], ["ual/Dance_Loop", 0.6], ["ual/Yes", 0.4]]
var out := "OUT/clip_shots"
var body := "M1"
var n := 0

func _initialize() -> void:
	var what: Array = WHAT
	for a: String in OS.get_cmdline_user_args():
		if a == "--set=2": what = WHAT2
		if a.begins_with("--clips="):      # --clips=NAME@SECONDS,NAME@SECONDS ... : a sheet of your own
			what = []
			for c: String in a.trim_prefix("--clips=").split(","): what.append(["ual/" + c.get_slice("@", 0), float(c.get_slice("@", 1))])
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--body="): body = a.trim_prefix("--body=")
	if not ClassDB.class_exists(&"CityPed"): print("CLIPS ERROR no native module"); quit(1); return
	DirAccess.make_dir_recursive_absolute(out)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.7, 0.78, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.8; we.environment = env; root.add_child(we)
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(60, 20); fl.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.45, 0.46, 0.48); fl.material_override = fm; root.add_child(fl)
	for k in what.size():
		var p: Node3D = ClassDB.instantiate(&"CityPed")
		p.set(&"body_id", body); p.set(&"clip", String(what[k][0]))
		p.position = Vector3((float(k) - 5.5) * 1.5, 0, 0); p.rotation.y = deg_to_rad(35.0)      # (a little turned, so that front and side both show)
		root.add_child(p)
		p.set(&"clip_at", float(what[k][1]))
	var cam := Camera3D.new(); cam.fov = 30.0; cam.position = Vector3(0, 1.6, 19.0); root.add_child(cam); cam.look_at(Vector3(0, 0.9, 0)); cam.current = true

func _process(_delta: float) -> bool:
	n += 1
	if n < 12: return false
	root.get_texture().get_image().save_png("%s/sheet.png" % out)
	print("CLIPS sheet of %d poses saved (%s): %s" % [n, body, out])
	quit(0)
	return true
