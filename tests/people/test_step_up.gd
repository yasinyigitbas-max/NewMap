extends SceneTree
## Small heights and the crouch (C++: CityPlayer; Yasin: "make the small heights like 20 cm walkable over"; "enter exit
## crouch"), in a window:
##   godot --path . --rendering-method mobile --resolution 1152x648 --fixed-fps 60 -s res://tests/people/test_step_up.gd
## A floor, a 20 cm kerb across his way and, 6 m on, a 40 cm block. He walks on: he steps up onto the kerb (his feet
## 20 cm up) and is stopped by the block (not a step). Then the crouch: down (Crouch_Enter played), held (its loop), up
## (Crouch_Exit played).
var player: CharacterBody3D
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var top_y := -9.0
var clips := {}

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("STEP    %s: %s" % ["ok" if ok else "FAIL", what])

func _box(size: Vector3, at: Vector3, col: Color) -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; b.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm
	var m := StandardMaterial3D.new(); m.albedo_color = col; mi.material_override = m; b.add_child(mi)
	b.position = at; root.add_child(b)

func _initialize() -> void:
	_box(Vector3(40, 2, 40), Vector3(0, -1, 0), Color(0.4, 0.4, 0.42))
	_box(Vector3(6, 0.2, 4), Vector3(0, 0.1, 4.0), Color(0.7, 0.68, 0.62))     # the kerb: 20 cm, from z 2 to 6
	_box(Vector3(6, 0.4, 2), Vector3(0, 0.4, 9.0), Color(0.6, 0.3, 0.25))      # the block: 40 cm over the kerb's top level... its top at 0.6
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)
	var env := WorldEnvironment.new(); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.55, 0.7, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.62); root.add_child(env)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)

func _physics_process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 1.0: return false
			player.call(&"set_move", Vector2(0, 1), false)
			step = 1; t0 = t
		1:      # walking on: onto the kerb, then into the block
			top_y = maxf(top_y, player.global_position.y)
			if t - t0 < 9.0: return false
			player.call(&"set_move", Vector2.ZERO, false)
			var z := player.global_position.z
			_check(int(player.call(&"get_steps_up")) >= 1 and top_y > 0.17 and top_y < 0.3, "the 20 cm kerb: he stepped up onto it (his feet %.2f m up, %d steps up)" % [top_y, int(player.call(&"get_steps_up"))])
			_check(z > 6.0 and z < 8.2, "the 40 cm block: not a step, he is stopped at it (at z %.2f, the block from 8.0)" % z)
			step = 2; t0 = t
		2:      # the crouch: down, held, up
			if t - t0 < 0.5: return false
			player.call(&"set_crouch", true)
			step = 3; t0 = t
		3:
			clips[String(player.call(&"get_clip"))] = true
			if t - t0 < 2.0: return false
			player.call(&"set_crouch", false)
			step = 4; t0 = t
		4:
			clips[String(player.call(&"get_clip"))] = true
			if t - t0 < 2.0: return false
			_check(clips.has("ual/Crouch_Enter") and clips.has("ual/Crouch_Idle_Loop") and clips.has("ual/Crouch_Exit"), "the crouch: down, held and up with its clips: %s" % str(clips.keys()))
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
