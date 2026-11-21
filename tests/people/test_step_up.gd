extends SceneTree
## Steps, climbs, fences and the crouch (C++: CityPlayer, HandGrip, FootPlant; Yasin, 20 Nov: "make the small heights
## like 20 cm walkable over"; "make 24 cm step an obvious over step"; "put climb animation on up to 50 cm, then above that
## should require a jump ... clinch and pull ourselves up"; "maybe limit it around 2.5 m"; "make sure the characters hands
## follow the edge and clinch to the edge"; "make their feet align automatically with collision"; "old pull over long climb
## was much better, revert to it"; "we should be able to jump over fences, same rules apply, hand on the rail"; the exit to idle),
## in a window:
##   godot --path . --rendering-method mobile --resolution 1152x648 --fixed-fps 60 -s res://tests/people/test_step_up.gd [-- --trace]
## Lanes, each a thing across his way 3 m ahead: a 20 cm kerb (StepUp), a 45 cm box (ClimbUp_1m, hands on its edge),
## a 40 cm fence (walking: over it, Vault, a hand on the rail), a 1.6 m wall (walking or in a jump: he pulls himself up,
## ClimbUp_2m, hands on its edge), a 1.1 m fence (walking or in a jump: over it), a 3 m wall (a jump: too high). After
## each, he stands a moment (Idle) before he walks on. A gripping hand within 5 cm of its place on the edge. Pictures:
## OUT/climb_ledge.png (the high climb), OUT/climb_vault.png (the fence).
var player: CharacterBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var lane := 0
var top_y := -9.0
var clips := {}
var seq := []
var shot_name := ""
var shot_frames := 0
var shot_done := {}
var hips_prev := -99.0
var hips_jump := 0.0   # the drawn hips' biggest rise or fall in one frame on this lane
# h, depth across his way (thin = a fence), what it is, what walking does, what a jump does
const LANES := [
	[0.2, 3.0, "a 20 cm kerb", "step", ""],
	[0.45, 3.0, "a 45 cm box", "climb", ""],
	[0.4, 0.08, "a 40 cm fence", "vault", ""],
	[1.6, 3.0, "a 1.6 m wall", "climb", "climb"],      # (Yasin: "lose those jumps at high vault and high climb")
	[1.1, 0.08, "a 1.1 m fence", "vault", "vault"],
	[3.0, 3.0, "a 3 m wall", "climb", "climb"],   # (the double climb, Mixamo, 21 Nov: Yasin "all kinds of movement including double climbs")
	[0.14, 3.0, "a 14 cm kerb", "walk", ""],   # (Yasin: "kerbs shouldnt require step up animation, but if you can make it truly seamless its okay")
]

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("CLIMB   %s: %s" % ["ok" if ok else "FAIL", what])

func _box(size: Vector3, at: Vector3, col: Color) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = col; mi.material_override = m; b.add_child(mi)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	_box(Vector3(80, 2, 60), Vector3(15, -1, 0), Color(0.4, 0.4, 0.42))
	for i in LANES.size():
		var h: float = LANES[i][0]; var d: float = LANES[i][1]
		_box(Vector3(3.0, h, d), Vector3(i * 6.0, h * 0.5, 3.0 + d * 0.5), Color.from_hsv(0.08 * i, 0.5, 0.75))
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.shadow_enabled = true; root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.55, 0.7, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.62); root.add_child(env)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)
	cam = Camera3D.new(); root.add_child(cam)

func _process(_d: float) -> bool:
	if cam and player:
		cam.current = true
		if shot_name != "":
			shot_frames += 1
			if shot_frames >= 2:
				root.get_texture().get_image().save_png("res://OUT/%s.png" % shot_name); shot_done[shot_name] = true; shot_name = ""
			return false
		cam.look_at_from_position(player.global_position + Vector3(4.5, 2.2, 1.5), player.global_position + Vector3(0, 0.9, 1.5), Vector3.UP)
	return false

func _start_lane() -> void:
	player.global_position = Vector3(lane * 6.0, 0.05, 0.0)
	player.velocity = Vector3.ZERO
	top_y = -9.0; clips = {}; seq = []; hips_prev = -99.0; hips_jump = 0.0
	player.call(&"set_move", Vector2(0, 1), false)

func _watch() -> void:
	top_y = maxf(top_y, player.global_position.y)
	var fl: Dictionary = player.call(&"get_frame_log")
	if fl.has("pelvis_drawn"):
		var hy: float = (fl.pelvis_drawn as Vector3).y
		if hips_prev > -90.0: hips_jump = maxf(hips_jump, absf(hy - hips_prev))
		hips_prev = hy
	var c := String(player.call(&"get_clip"))
	clips[c] = true
	if seq.is_empty() or seq[-1] != c: seq.append(c)
	if OS.get_cmdline_user_args().has("--trace") and float(player.call(&"get_grip_weight")) > 0.0:
		var gn: Vector3 = player.call(&"get_grip_now")
		print("TRACE lane %d u %.2f w %.2f miss %.3f %.3f" % [lane, gn.x, float(player.call(&"get_grip_weight")), gn.y, gn.z])
	if bool(player.call(&"is_climbing")):   # a picture in the middle of the high climb and of the high fence
		var gn2: Vector3 = player.call(&"get_grip_now")
		var want := "climb_ledge" if lane == 3 else ("climb_vault" if lane == 4 else "")
		if want != "" and not shot_done.has(want) and gn2.x > 0.45 and shot_name == "":
			var e: Vector3 = player.call(&"get_edge_at")
			cam.look_at_from_position(e + Vector3(2.4, 1.0, -2.6), e + Vector3(0, -0.1, 0), Vector3.UP)
			shot_name = want; shot_frames = 0

func _settled() -> bool:   # after the climb: Idle came between the climb's clip and walking
	var i := -1
	for k in seq.size(): if String(seq[k]).begins_with("ual/Climb") or String(seq[k]).begins_with("mx/Climb") or seq[k] == "ual/StepUp" or seq[k] == "ual/SafetyVault": i = k
	return i >= 0 and i + 1 < seq.size() and seq[i + 1] == "ual/Idle_Loop"

func _judge(what: String, jump: bool) -> void:
	var h: float = LANES[lane][0]; var deep: float = LANES[lane][1]
	var name: String = LANES[lane][2]
	var z := player.global_position.z
	var on_top := top_y > h - 0.06 and deep > 1.0
	var over := z > 3.0 + deep + 0.3
	var how := "in a jump" if jump else "walking"
	match what:
		"step": _check(on_top and clips.has("ual/StepUp") and _settled(), "%s, %s: an obvious step over it (StepUp), feet %.2f m up, then a moment standing (%s)" % [name, how, top_y, str(seq)])
		"climb":
			# (since 21 Nov the high climb is Mixamo's pull-up, a 3 m wall its double climb)
			var c := "mx/Climbing_double" if h > 2.5 else ("mx/Climbing_single" if h > 0.5 else "ual/ClimbUp_1m")
			_check(on_top and clips.has(c) and (_settled() or h > 2.5), "%s, %s: up on it (%s), feet %.2f m up, then a moment standing (%s)" % [name, how, c, top_y, str(seq)])
		"vault": _check(over and clips.has("ual/SafetyVault") and _settled(), "%s, %s: over it (Vault) to the far side (at z %.2f), then a moment standing (%s)" % [name, how, z, str(seq)])
		"walk": _check(on_top and not clips.has("ual/StepUp") and hips_jump < 0.03, "%s, %s: walked onto it, no step clip, the hips never jump (most %.3f m in a frame), feet %.2f m up (%s)" % [name, how, hips_jump, top_y, str(seq)])
		"stop": _check(not on_top and not over, "%s, %s: not up, not over (feet at most %.2f m, at z %.2f)" % [name, how, top_y, z])

func _physics_process(delta: float) -> bool:
	t += delta
	if player and step >= 1 and step <= 2: _watch()
	match step:
		0:
			if t < 1.0: return false
			lane = 0; _start_lane(); step = 1; t0 = t
		1:      # walking into the lane's thing (5 s: he walks at 1.05 m/s since 20 Nov, was 1.6, and takes a first step)
			if t - t0 < 5.0: return false
			_judge(LANES[lane][3], false)
			if LANES[lane][4] != "":   # now a jump into it
				player.global_position = Vector3(lane * 6.0, 0.05, 1.6); player.velocity = Vector3.ZERO
				top_y = -9.0; clips = {}; seq = []
				player.call(&"jump"); step = 2; t0 = t; return false
			lane += 1
			if lane >= LANES.size(): step = 3; t0 = t; return false
			_start_lane(); t0 = t
		2:      # the jump
			if t - t0 < 4.0: return false
			_judge(LANES[lane][4], true)
			lane += 1
			if lane >= LANES.size(): step = 3; t0 = t; return false
			_start_lane(); step = 1; t0 = t
		3:      # the hands, over all the climbs and vaults
			player.call(&"set_move", Vector2.ZERO, false)
			_check(float(player.call(&"get_grip_seconds")) > 0.6, "the hands held the edges and rails for %.1f s in all" % float(player.call(&"get_grip_seconds")))
			_check(float(player.call(&"get_grip_miss_most")) < 0.05, "a holding hand at most %.3f m from its place on the edge (the 5 cm target)" % float(player.call(&"get_grip_miss_most")))
			_check(float(player.call(&"get_grip_tip_most")) < 0.07, "a holding hand's fingertips at most %.3f m over or under the edge's top" % float(player.call(&"get_grip_tip_most")))
			step = 4; t0 = t
		4:      # the crouch
			if t - t0 < 0.5: return false
			player.global_position = Vector3(-6, 0.05, 0); clips = {}
			player.call(&"set_crouch", true); step = 5; t0 = t
		5:
			clips[String(player.call(&"get_clip"))] = true
			if t - t0 < 2.0: return false
			player.call(&"set_crouch", false); step = 6; t0 = t
		6:
			clips[String(player.call(&"get_clip"))] = true
			if t - t0 < 2.0: return false
			_check(clips.has("ual/Crouch_Enter") and clips.has("ual/Crouch_Idle_Loop") and clips.has("ual/Crouch_Exit"), "the crouch: down, held and up with its clips")
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
