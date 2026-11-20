extends SceneTree
## B16 footsteps, the step detection on its own (Yasin, 20 Nov: "i think our footsteps dont play in the game yet"):
##   godot --path . --rendering-method mobile --resolution 640x360 -s res://tests/people/test_footsteps_walk.gd [-- --trace]
## A flat floor, the player (CityPlayer) and a FootSteps on his figure, as CityCrowd::set_player gives him one. He walks
## 6 s, then runs 4 s. Checks: steps are counted (walking ~1.8 a second, running more), each step's sound plays.
var player: CharacterBody3D
var fs: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var plays := 0
var trace: Array = []

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("STEPS   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var b := StaticBody3D.new(); var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(200, 2, 200); cs.shape = sh; b.add_child(cs)
	b.position = Vector3(0, -1, 0); root.add_child(b)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 35, 0); root.add_child(sun)
	player = ClassDB.instantiate(&"CityPlayer"); player.position = Vector3(0, 0.05, 0); root.add_child(player)

func _process(_d: float) -> bool:
	t += _d
	match step:
		0:
			if t < 1.0: return false
			var ped: Node = player.find_children("*", "CityPed", true, false)[0]
			fs = ClassDB.instantiate(&"FootSteps"); fs.name = "FootSteps"; player.add_child(fs); fs.call(&"set_figure", ped)
			player.call(&"set_move", Vector2(0, 1), false); step = 1; t0 = t
		1, 2:
			for p in fs.find_children("*", "AudioStreamPlayer3D", true, false): if (p as AudioStreamPlayer3D).playing: plays += 1
			if OS.get_cmdline_user_args().has("--trace"):
				var sk: Skeleton3D = player.find_children("*", "Skeleton3D", true, false)[0]
				var ped2: Node3D = player.find_children("*", "CityPed", true, false)[0]
				var at: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Bip01_L_Foot")).origin
				trace.append("%.2f" % (at.y - ped2.global_position.y))
				if trace.size() % 40 == 0: print("STEPS   trace L foot h: %s | speed %.2f clip %s steps %d" % [" ".join(trace.slice(trace.size() - 40)), float(player.call(&"get_speed")), str(player.call(&"get_clip")), int(fs.call(&"get_steps"))])
			if step == 1 and t - t0 >= 6.0:
				_check(int(fs.call(&"get_steps")) >= 6, "walking 6 s: %d steps (about 11 expected)" % int(fs.call(&"get_steps")))
				player.call(&"set_move", Vector2(0, 1), true); step = 2; t0 = t
			elif step == 2 and t - t0 >= 4.0:
				player.call(&"set_move", Vector2.ZERO, false)
				_check(int(fs.call(&"get_steps")) >= 14, "and running 4 s: %d steps in all" % int(fs.call(&"get_steps")))
				_check(plays > 10, "the sounds play (a step player playing in %d frames)" % plays)
				_check(int(fs.call(&"get_run_steps")) >= 3, "running, the run takes play (%d)" % int(fs.call(&"get_run_steps")))
				print("RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
				quit(1 if fails > 0 else 0); return true
	return false
