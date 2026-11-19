extends SceneTree
## Back to the menu from the game, in the real city (C++: CityGame; Yasin, 20 Nov: "whenever we go back to the menu the
## game crashes"), in a window:
##   godot --path . --rendering-method mobile --resolution 1152x648 -s res://tests/game/test_menu_back.gd
## New game into the city (the rig in game mode, as the app does); Esc (pause); Main menu; then Continue back into the
## world; then Main menu again and New game. Each step prints; a crash leaves the engine's backtrace after the last line.
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
const DIR := "user://test_menu_saves/"

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("MENU    %s: %s" % ["ok" if ok else "FAIL", what])

func _esc() -> void:
	var e := InputEventKey.new(); e.keycode = KEY_ESCAPE; e.pressed = true
	root.push_input(e)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR): DirAccess.remove_absolute(DIR + f)
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame"); game.name = "Game"
	game.set(&"saves_dir", DIR); game.set(&"autosave_s", 0.0)
	boot.add_child(game); root.add_child(boot); current_scene = boot

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 0.5: return false
			print("MENU    new game"); game.press("menu.new_game"); step = 1; t0 = t
		1:
			if not game.is_playing() and t - t0 < 120.0: return false
			_check(game.is_playing(), "in the city (%.0f s)" % (t - t0)); step = 2; t0 = t
		2:
			if t - t0 < 4.0: return false
			print("MENU    Esc: pause"); _esc(); step = 3; t0 = t
		3:
			if t - t0 < 0.5: return false
			_check(game.current_screen() == "pause", "the pause menu (%s)" % game.current_screen())
			print("MENU    Main menu"); game.press("pause.main_menu"); step = 4; t0 = t
		4:
			if t - t0 < 2.0: return false
			_check(game.is_menu_open(), "the main menu is open over the world, still alive 2 s on")
			print("MENU    Continue"); game.press("menu.continue"); step = 5; t0 = t
		5:
			if not game.is_playing() and t - t0 < 60.0: return false
			_check(game.is_playing(), "back in the world (%.1f s)" % (t - t0)); step = 6; t0 = t
		6:
			if t - t0 < 3.0: return false
			_esc(); step = 7; t0 = t
		7:
			if t - t0 < 0.5: return false
			game.press("pause.main_menu"); step = 8; t0 = t
		8:
			if t - t0 < 1.5: return false
			print("MENU    New game from the menu over the world"); game.press("menu.new_game"); step = 9; t0 = t
		9:
			if not game.is_playing() and t - t0 < 60.0: return false
			_check(game.is_playing(), "a new game over the old world (%.1f s)" % (t - t0)); step = 10; t0 = t
		10:
			if t - t0 < 3.0: return false
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
