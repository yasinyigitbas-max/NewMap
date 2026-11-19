extends SceneTree
## The game's shell (C++: CityGame, ui_plate): text, the main menu, new game / continue through the loading screen into
## a world, the clock, money, saving, pause (Esc), settings (sound buses, the phone's file), game over and retry, the
## slot picker with delete and overwrite. Headless; this script presses the buttons a thumb would (CityGame.press by
## the text key a button shows) and reads what happened:
##   godot --headless --path . -s res://tests/game/test_shell.gd
## A tiny world scene stands in for the city; the saves go to user://test_saves/ (emptied first).
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
const DIR := "user://test_saves/"

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("SHELL   %s: %s" % ["ok" if ok else "FAIL", what])

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityGame"):
		print("SHELL ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	var d := DirAccess.open("user://")
	if d and d.dir_exists("test_saves"):
		for f in DirAccess.get_files_at(DIR): DirAccess.remove_absolute(DIR + f)
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame")
	game.set(&"saves_dir", DIR); game.set(&"world_scene", "res://tests/game/tiny_world.tscn"); game.set(&"autosave_s", 0.0)
	boot.add_child(game)
	root.add_child(boot)
	current_scene = boot

func _esc() -> void:
	var e := InputEventKey.new(); e.keycode = KEY_ESCAPE; e.pressed = true
	root.push_input(e)

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 0.3: return false
			_check(ClassDB.class_call_static(&"CityGame", &"en", "menu.title") == "Crownado English" and String(ClassDB.class_call_static(&"CityGame", &"dual", "menu.title")).contains("Crownado'da"), "the text: menu.title is '%s' / '%s'" % [ClassDB.class_call_static(&"CityGame", &"en", "menu.title"), ClassDB.class_call_static(&"CityGame", &"dual", "menu.title")])
			_check(game.get_parent() == root, "the shell moved to the root (it outlives the boot scene)")
			_check(game.current_screen() == "menu" and game.is_menu_open() and paused, "the main menu is open and the game is paused (%s)" % game.current_screen())
			_check(not game.press("menu.continue"), "with no save, Continue cannot be pressed")
			_check(game.press("menu.new_game"), "New game is pressed")
			step = 1; t0 = t
		1:
			if not game.is_playing() and t - t0 < 30.0: return false
			_check(game.is_playing() and current_scene and current_scene.name == "TinyWorld" and not paused, "through the loading screen into the world (%.1f s): %s" % [t - t0, current_scene.name if current_scene else "none"])
			_check(int(game.get_active_slot()) == 0 and FileAccess.file_exists(DIR + "slot_0.json") and game.list_slots().size() == 1, "a new slot was made and saved: slot 0")
			game.set_time(9.0, 1); game.add_money(25); game.set_flag("met_ali", true)
			step = 2; t0 = t
		2:
			if t - t0 < 1.5: return false
			_check(float(game.get_hour()) > 9.0, "the clock runs: %s (one game hour = ten real minutes)" % game.hhmm())
			_esc()
			step = 3; t0 = t
		3:
			if t - t0 < 0.2: return false
			_check(game.current_screen() == "pause" and paused, "Esc opens the pause menu over the paused world")
			_check(game.press("pause.save"), "Save is pressed")
			var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "slot_0.json"))
			_check(int(j.state.game.money) == 75 and bool(j.state.game.flags.met_ali) and int(j.version) == 3, "the save file holds the money (%d) and the flag, version 3" % int(j.state.game.money))
			_check(game.press("menu.settings") and game.current_screen() == "pause_settings", "Settings opens inside the pause menu")
			game.set_setting("master", 0.5); game.set_setting("pscale", 1.0)
			var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
			_check(absf(db + 6.02) < 0.1, "the master volume at 0.5 sets the Master bus to %.1f dB" % db)
			var dv: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://device_settings.json"))
			_check(float(dv.pscale) == 1.0 and int(dv.gfx_rev) == 2, "a per-phone setting (render scale) goes to user://device_settings.json")
			_check(game.press("settings.back") and game.current_screen() == "pause", "Back to the pause list")
			_check(game.press("pause.main_menu") and game.current_screen() == "menu", "Main menu from pause")
			game.add_money(-75)      # (spent before Continue: Continue must bring back the saved 75)
			_check(game.press("menu.continue"), "Continue can be pressed now")
			step = 4; t0 = t
		4:
			if not game.is_playing() and t - t0 < 30.0: return false
			_check(game.is_playing() and int(game.get_money()) == 75 and float(game.get_setting("master")) == 0.5, "Continue loads the slot: money %d, master %.2f (the slot's settings)" % [int(game.get_money()), float(game.get_setting("master"))])
			game.add_money(-75)
			game.game_over("You ran out of money.", "Paran bitti.", "", "")
			_check(game.current_screen() == "game_over" and paused, "game over shows and pauses")
			_check(game.press("ui.retry") and not paused and int(game.get_money()) == 75, "Retry loads the last save: money %d" % int(game.get_money()))
			game.open_menu()
			_check(game.press("menu.settings") and game.press("menu.load_game") and game.current_screen() == "picker", "the slot picker (Load game)")
			_check(game.press("delete_0") and game.press("ui.yes") and game.list_slots().size() == 0, "a slot is deleted after Yes")
			for k in 4: game.create_slot("P%d" % k)
			_check(bool(game.is_full()), "four slots: full")
			game.press("menu.back"); game.press("settings.back")
			_check(game.current_screen() == "menu" and game.press("menu.new_game") and game.current_screen() == "picker", "New game with four slots asks which to overwrite")
			_check(game.press("slot_2") and game.press("ui.yes"), "overwrite slot 2 after Yes")
			step = 5; t0 = t
		5:
			if not game.is_playing() and t - t0 < 30.0: return false
			var names := []
			for s: Dictionary in game.list_slots(): names.append(String(s.name))
			_check(game.is_playing() and game.list_slots().size() == 4 and names.has("New player"), "the overwritten slot is a new game: %s" % str(names))
			step = 9
		9:
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
