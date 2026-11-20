extends SceneTree
## B16 footsteps in the real game (Yasin, 20 Nov: "i think our footsteps dont play in the game yet"):
##   godot --path . --rendering-method mobile --resolution 640x360 -s res://tests/game/test_footsteps.gd
## New game; once the player is set down, he walks forward 6 s, then runs 4 s. Checks: his FootSteps node is there, the
## figure has the foot bones it follows, steps are counted while he moves (about 1.8 a second walking), each step plays a
## sound (one of its two 3D players is playing right after), and the ground it names is a real kind.
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var pl: Node3D
var fs: Node
var plays := 0
var trace: Array = []
var skel: Skeleton3D

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("STEPS   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame")
	game.name = "Game"
	game.set(&"saves_dir", "user://steps_test_saves/")
	for f in DirAccess.get_files_at("user://steps_test_saves/"): DirAccess.remove_absolute("user://steps_test_saves/" + f)
	boot.add_child(game); root.add_child(boot); current_scene = boot

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 1.0: return false
			game.press("menu.new_game"); step = 1; t0 = t
		1:
			if game.get_start_info().is_empty() and t - t0 < 180.0: return false
			_check(not game.get_start_info().is_empty(), "the city loaded (%.0f s)" % (t - t0))
			for c in current_scene.get_children(): if c.get_class() == "CityPlayer": pl = c
			_check(pl != null, "the player is there")
			if pl == null: return _end()
			fs = pl.get_node_or_null(^"FootSteps")
			_check(fs != null, "the player has his FootSteps node (children: %s)" % str(pl.get_children().map(func(n: Node) -> String: return String(n.name))))
			if fs == null: return _end()
			var fig: Node = pl.call(&"figure") if pl.has_method(&"figure") else null
			var sk: Skeleton3D = null
			for n in pl.find_children("*", "Skeleton3D", true, false): sk = n; break
			skel = sk
			_check(sk != null, "his figure has a skeleton")
			if sk:
				var lf := sk.find_bone("Bip01_L_Foot"); var rf := sk.find_bone("Bip01_R_Foot")
				var names: Array = []
				for b in sk.get_bone_count():
					var bn := sk.get_bone_name(b)
					if bn.to_lower().contains("foot") or bn.to_lower().contains("toe"): names.append(bn)
				_check(lf >= 0 and rf >= 0, "the foot bones FootSteps follows are there (Bip01_L_Foot %d, Bip01_R_Foot %d; feet in this skeleton: %s)" % [lf, rf, str(names)])
			step = 15; t0 = t
		15:      # (the game holds him frozen until the loading screen lets him go, B2)
			if bool(pl.call(&"is_frozen")) and t - t0 < 60.0: return false
			_check(not bool(pl.call(&"is_frozen")), "he is let go (%.1f s after the start was placed)" % (t - t0))
			step = 2; t0 = t
			pl.call(&"set_move", Vector2(0, 1), false)
		2:
			for p in fs.find_children("*", "AudioStreamPlayer3D", true, false): if (p as AudioStreamPlayer3D).playing: plays += 1
			if skel and OS.get_cmdline_user_args().has("--trace"):      # the left foot's height over the figure's base, as FootSteps reads it
				var fig3: Node3D = skel.get_parent() as Node3D
				var base: Vector3 = pl.find_children("*", "CityPed", true, false)[0].global_position
				var at: Vector3 = skel.global_transform * skel.get_bone_global_pose(skel.find_bone("Bip01_L_Foot")).origin
				trace.append("%.2f" % (at.y - base.y))
				if trace.size() % 30 == 0: print("STEPS   trace L foot h: %s | player at %s speed %.2f clip %s" % [" ".join(trace.slice(trace.size() - 30)), str(pl.global_position.snapped(Vector3.ONE * 0.01)), float(pl.call(&"get_speed")) if pl.has_method(&"get_speed") else -1.0, str(pl.call(&"get_clip")) if pl.has_method(&"get_clip") else "?"])
			if t - t0 < 6.0: return false
			var walked := int(fs.call(&"get_steps"))
			_check(walked >= 6, "walking 6 s: %d steps counted (about 11 expected), last ground kind %d" % [walked, int(fs.call(&"get_last_kind"))])
			pl.call(&"set_move", Vector2(0, 1), true)
			step = 3; t0 = t
		3:
			for p in fs.find_children("*", "AudioStreamPlayer3D", true, false): if (p as AudioStreamPlayer3D).playing: plays += 1
			if t - t0 < 4.0: return false
			pl.call(&"set_move", Vector2.ZERO, false)
			_check(int(fs.call(&"get_steps")) > 6, "running 4 s: %d steps in all" % int(fs.call(&"get_steps")))
			_check(plays > 0, "the step sounds play (a step player was playing in %d frames)" % plays)
			return _end()
	return false

func _end() -> bool:
	print("RESULT %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)
	return true
