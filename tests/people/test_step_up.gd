extends SceneTree
## Steps, climbs and the crouch (C++: CityPlayer; Yasin: "make the small heights like 20 cm walkable over"; "make 24 cm
## step an obvious over step"; "put climb animation on up to 50 cm, then above that should require a jump, but if our
## height allows it we should be able to clinch and pull ourselves up"; "maybe limit it around 2.5 m"), in a window:
##   godot --path . --rendering-method mobile --resolution 1152x648 --fixed-fps 60 -s res://tests/people/test_step_up.gd
## Four lanes, each a thing across his way 3 m ahead: a 20 cm kerb (he steps over it: StepUp), a 45 cm box (he climbs
## onto it: ClimbUp_1m), a 1.6 m wall (walking: stopped; a jump: he grabs it and pulls up: ClimbUp_2m), a 3 m wall (a
## jump: too high, stopped). Then the crouch: down (Crouch_Enter), held, up (Crouch_Exit).
var player: CharacterBody3D
var cam: Camera3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var lane := 0
var top_y := -9.0
var clips := {}
var finger_off := 0.0   # (the gripping fingers: the farthest from the edge's height, m)
var finger_n := 0
var shot := false
const LANES := [[0.2, "a 20 cm kerb"], [0.45, "a 45 cm box"], [1.6, "a 1.6 m wall"], [3.0, "a 3 m wall"]]

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("CLIMB   %s: %s" % ["ok" if ok else "FAIL", what])

func _box(size: Vector3, at: Vector3, col: Color) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = col; mi.material_override = m; b.add_child(mi)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	_box(Vector3(60, 2, 60), Vector3(0, -1, 0), Color(0.4, 0.4, 0.42))
	for i in LANES.size():
		var h: float = LANES[i][0]
		_box(Vector3(3.0, h, 3.0), Vector3(i * 6.0, h * 0.5, 4.5), [Color(0.72, 0.7, 0.64), Color(0.6, 0.45, 0.3), Color(0.55, 0.3, 0.25), Color(0.35, 0.35, 0.5)][i])
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); sun.shadow_enabled = true; root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.55, 0.7, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.62); root.add_child(env)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)
	cam = Camera3D.new(); root.add_child(cam)

var _grab_later := false
var _grab_frames := 0
func _process(_d: float) -> bool:
	if _grab_later:
		_grab_frames += 1
		if _grab_frames >= 2:   # (the frame drawn from the new camera)
			_grab_later = false; _grab_frames = 0
			root.get_texture().get_image().save_png("res://OUT/climb_grip.png")
		return false
	if cam and player and not shot:
		cam.current = true
		cam.look_at_from_position(player.global_position + Vector3(4.5, 2.2, 1.5), player.global_position + Vector3(0, 0.9, 1.5), Vector3.UP)
	return false

func _start_lane() -> void:
	player.global_position = Vector3(lane * 6.0, 0.05, 0.0)
	player.velocity = Vector3.ZERO
	top_y = -9.0; clips = {}
	player.call(&"set_move", Vector2(0, 1), false)

func _physics_process(delta: float) -> bool:
	t += delta
	if player: top_y = maxf(top_y, player.global_position.y); clips[String(player.call(&"get_clip"))] = true
	if player and float(player.call(&"get_grip_weight")) > 0.95:   # the hands on the edge: the fingers at the top's height
		var e: Vector3 = player.call(&"get_edge_at")
		var hp: Array = player.call(&"get_hand_points")
		for k in [2, 3]: finger_off = maxf(finger_off, absf((hp[k] as Vector3).y - e.y)); finger_n += 1
		if lane == 2 and not shot and player.global_position.y > 0.6:
			shot = true
			cam.look_at_from_position(e + Vector3(2.2, 0.9, -2.4), e + Vector3(0, -0.2, 0), Vector3.UP)
			_grab_later = true
	match step:
		0:
			if t < 1.0: return false
			lane = 0; _start_lane(); step = 1; t0 = t
		1:      # walking into the lane's thing
			if t - t0 < 4.0: return false
			var h: float = LANES[lane][0]
			var on := top_y > h - 0.06
			match lane:
				0: _check(on and clips.has("ual/StepUp"), "%s: an obvious step over it (StepUp), his feet %.2f m up" % [LANES[lane][1], top_y])
				1: _check(on and clips.has("ual/ClimbUp_1m"), "%s: he climbs onto it (ClimbUp_1m), his feet %.2f m up" % [LANES[lane][1], top_y])
				_: _check(not on and player.global_position.z < 3.1, "%s, walking: he is stopped at it (feet at most %.2f m up)" % [LANES[lane][1], top_y])
			if lane >= 2:   # now a jump into it
				top_y = -9.0; clips = {}
				player.call(&"jump"); step = 2; t0 = t; return false
			lane += 1; _start_lane(); t0 = t
		2:      # the jump
			if t - t0 < 4.0: return false
			var h: float = LANES[lane][0]
			var on := top_y > h - 0.06
			if lane == 2:
				_check(on and clips.has("ual/ClimbUp_2m"), "%s, in a jump: he grabs it and pulls himself up (ClimbUp_2m), his feet %.2f m up" % [LANES[lane][1], top_y])
				_check(float(player.call(&"get_grip_seconds")) > 0.5 and float(player.call(&"get_grip_miss_most")) < 0.05, "his hands held the edge for %.1f s, each wrist at most %.3f m from its place on it" % [float(player.call(&"get_grip_seconds")), float(player.call(&"get_grip_miss_most"))])
				_check(float(player.call(&"get_grip_tip_most")) < 0.07, "the gripping fingertips lie on the edge's top (at most %.3f m over or under it): not above it, not into it" % float(player.call(&"get_grip_tip_most")))
				shot = false
			else: _check(not on, "%s, in a jump: too high (over 2.5 m), he is not up there (feet at most %.2f m)" % [LANES[lane][1], top_y])
			if lane == 2: lane = 3; _start_lane(); step = 1; t0 = t; return false
			player.call(&"set_move", Vector2.ZERO, false)
			step = 3; t0 = t
		3:      # the crouch
			if t - t0 < 0.5: return false
			player.global_position = Vector3(-6, 0.05, 0); clips = {}
			player.call(&"set_crouch", true); step = 4; t0 = t
		4:
			if t - t0 < 2.0: return false
			player.call(&"set_crouch", false); step = 5; t0 = t
		5:
			if t - t0 < 2.0: return false
			_check(clips.has("ual/Crouch_Enter") and clips.has("ual/Crouch_Idle_Loop") and clips.has("ual/Crouch_Exit"), "the crouch: down, held and up with its clips")
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
