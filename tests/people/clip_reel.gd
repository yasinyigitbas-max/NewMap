extends SceneTree
## A reel of clips back to back on our own figure (the Animator, 21 Nov; Yasin: "can i see all those animations back to
## back?"): each clip played through once (a loop twice, at least 2 s; at most 4 s), its group and name on screen.
## Recorded by Godot's movie maker:
##   godot --path . --rendering-method mobile --resolution 720x720 --fixed-fps 24 --write-movie OUT/reel.avi -s res://tests/people/clip_reel.gd [-- --body=M1]
const REEL := [
	["Standing (it cycles)", ["mx/Idle_Transition", "mx/Looking_Around_idle", "mx/Neck_Stretching", "mx/Arm_Stretching"]],
	["Walking", ["mx/Start_Walking", "mx/Walking", "mx/Stop_Walking", "mx/Walking_Turn_180"]],
	["Turning on the spot", ["mx/Left_Turn_90", "mx/Left_Turn", "mx/Right_Turn_90", "mx/Right_Turn"]],
	["Jog, run, sprint", ["mx/Running_4", "mx/Slow_Run", "mx/Running_2", "mx/Running_3", "mx/Fast_Run", "mx/Running_Turn_180", "mx/Running_To_Turn"]],
	["Crouch", ["mx/Crouching_Idle", "mx/Crouch_cover_idle", "mx/Crouched_Walking", "mx/Sneaking_Forward", "mx/Crouch_To_Stand"]],
	["Jumps", ["mx/Running_Jump", "mx/Falling_To_Landing"]],
	["Climbs", ["mx/Climbing_single", "mx/Running_Jump_Climb", "mx/Climbing_double", "mx/Sprint_To_Wall_Climb"]],
	["Fight: stance and steps", ["mx/Fight_Idle_To_Action_Idle", "mx/Fighting_Idle", "mx/Fight_idle", "mx/Fight_forwardstep", "mx/Fight_backstep", "mx/Fight_walk_backwards", "mx/Fight_sidestep_L", "mx/Fight_sidestep_R", "mx/Fistfight_Taunt", "mx/Taunt"]],
	["Fight: blows", ["mx/Punching", "mx/Punching_2", "mx/Hook", "mx/Elbow_Punching", "mx/Kicking_Out"]],
	["Fight: hit", ["mx/Head_Hit", "mx/Light_Hit_To_Head", "mx/Big_Hit_To_Head", "mx/Receive_Punch_To_The_Face", "mx/Hit_To_Body", "mx/Hit_Reaction"]],
	["Talking", ["mx/Talking", "mx/Talking_2", "mx/Talking_3", "mx/Talking_4", "mx/Talking_5", "mx/Asking_Question", "mx/Telling_A_Secret", "mx/Agreeing", "mx/Acknowledging", "mx/No", "mx/Disappointed"]],
	["Phone", ["mx/Talking_On_Phone", "mx/Talking_On_A_Cell_Phone", "mx/Talking_on_phone_arguing", "mx/Texting_While_Standing", "mx/Standing_Using_Touchscreen_Tablet", "mx/Texting_And_Walking_one_hand", "mx/Walking_While_Texting"]],
]
var body := "M1"
var fig: Node3D
var ap: AnimationPlayer
var cam: Camera3D
var title: Label
var sub: Label
var gi := 0
var ci := -1
var left := 0.0
var look := Vector3(0, 1.0, 0)

func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--body="): body = a.trim_prefix("--body=")
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 35, 0); sun.shadow_enabled = true; root.add_child(sun)
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.74, 0.79, 0.86)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.76, 0.8); env.ambient_light_energy = 0.85; we.environment = env; root.add_child(we)
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.56, 0.57, 0.6)); img.set_pixel(1, 1, Color(0.56, 0.57, 0.6)); img.set_pixel(1, 0, Color(0.45, 0.46, 0.49)); img.set_pixel(0, 1, Color(0.45, 0.46, 0.49))
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(40, 40); fl.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_texture = ImageTexture.create_from_image(img); fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; fm.uv1_scale = Vector3(40, 40, 1); fl.material_override = fm; root.add_child(fl)
	fig = ClassDB.instantiate(&"CityPed"); fig.set(&"body_id", body); fig.rotation.y = 0.9; root.add_child(fig)
	cam = Camera3D.new(); cam.fov = 40.0; root.add_child(cam); cam.current = true
	var cl := CanvasLayer.new(); root.add_child(cl)
	title = Label.new(); title.position = Vector2(18, 12); title.add_theme_font_size_override("font_size", 30); title.add_theme_color_override("font_color", Color(0.1, 0.12, 0.16)); cl.add_child(title)
	sub = Label.new(); sub.position = Vector2(18, 52); sub.add_theme_font_size_override("font_size", 22); sub.add_theme_color_override("font_color", Color(0.2, 0.22, 0.28)); cl.add_child(sub)

func _next() -> bool:
	ci += 1
	if ci >= (REEL[gi][1] as Array).size(): gi += 1; ci = 0
	if gi >= REEL.size(): return false
	var c := String(REEL[gi][1][ci])
	if ap == null:
		var aps := fig.find_children("*", "AnimationPlayer", true, false)
		if aps.size() > 0: ap = aps[0]
	if ap == null or not ap.has_animation(c): left = 0.0; return true
	var a := ap.get_animation(c)
	left = clampf(a.length * (2.0 if a.loop_mode != Animation.LOOP_NONE else 1.0), 2.0, 4.0)
	fig.set(&"clip_at", -1.0); fig.set(&"clip", c); ap.seek(0.0, true)
	title.text = String(REEL[gi][0])
	sub.text = "%s   (%d / %d)" % [c.trim_prefix("mx/").replace("_", " "), ci + 1, (REEL[gi][1] as Array).size()]
	return true

func _process(delta: float) -> bool:
	left -= delta
	if left <= 0.0:
		if not _next(): print("REEL done"); quit(0); return true
	var hips := Vector3(0, 1.0, 0)
	var sk: Array = fig.find_children("*", "Skeleton3D", true, false)
	if sk.size() > 0:
		var s: Skeleton3D = sk[0]; var b := s.find_bone("Bip01_Pelvis")
		if b >= 0: hips = s.global_transform * s.get_bone_global_pose(b).origin
	look = look.lerp(Vector3(hips.x, maxf(hips.y, 0.9), hips.z), minf(delta * 4.0, 1.0))
	cam.look_at_from_position(look + Vector3(3.6, 0.5, 2.6), look, Vector3.UP)
	return false
