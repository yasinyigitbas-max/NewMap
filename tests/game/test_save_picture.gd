extends SceneTree
## The saved game's picture (C++: CityGame; Yasin: "if there is a saved game, in the main menu, game should take a
## screenshot from the game will load from, that screen should be shown on the loading menu and game should load into
## that scene directly, seamlessly"; "if there isnt a saved game yet, that screen should have a black background").
## In a real window (a headless run has no frame to take):
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/game/test_save_picture.gd
## No save: the menu is black. New game into a small coloured world; the player stood somewhere, looking a chosen way;
## a save writes the picture with his place and view. The shell is made again (as when the app is opened again): the
## menu shows the picture, Continue's loading screen shows it, the player stands where he was, looking the same way,
## the loading screen fades into the live world, and the live frame matches the picture.
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var fails := 0
var saved_pos := Vector3.ZERO
var saved_view := []
const DIR := "user://test_pic_saves/"

func _check(ok: bool, what: String) -> void:
	if not ok: fails += 1
	print("PICTURE %s: %s" % ["ok" if ok else "FAIL", what])

func _make_game() -> void:
	game = ClassDB.instantiate(&"CityGame")
	game.set(&"saves_dir", DIR); game.set(&"world_scene", "res://tests/game/picture_world.tscn"); game.set(&"autosave_s", 0.0)
	game.connect(&"play_started", _on_play)
	root.add_child(game)

func _on_play(_s: int) -> void:
	var pl := current_scene.get_node_or_null("Player") if current_scene else null
	if pl: game.set_player(pl)

func _player() -> Node3D:
	return current_scene.get_node_or_null("Player") as Node3D if current_scene else null

func _frame() -> Image:
	var im := root.get_texture().get_image()
	im.resize(640, int(round(im.get_height() * 640.0 / im.get_width())), Image.INTERPOLATE_BILINEAR)
	return im

func _diff(a: Image, b: Image) -> float:
	if a.get_size() != b.get_size(): return 9.0
	var s := 0.0; var n := 0
	for y in range(0, a.get_height(), 4):
		for x in range(0, a.get_width(), 4):
			var ca := a.get_pixel(x, y); var cb := b.get_pixel(x, y)
			s += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b); n += 3
	return s / n

func _initialize() -> void:
	if not ClassDB.class_exists(&"CityGame"):
		print("PICTURE ERROR the native module is not built"); print("RESULT FAIL"); quit(1); return
	DirAccess.make_dir_recursive_absolute(DIR)
	for f in DirAccess.get_files_at(DIR): DirAccess.remove_absolute(DIR + f)
	_make_game()

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 0.5: return false
			_check(game.is_menu_open() and not game.menu_picture_shown(), "no save: the menu is black (no picture)")
			game.press("menu.new_game")
			step = 1; t0 = t
		1:
			if t - t0 < 0.1: return false
			_check(game.current_screen() == "loading" and not game.loading_picture_shown(), "a new game's loading screen is black")
			step = 2
		2:
			if not (game.is_playing() and not game.is_loading_fading()) and t - t0 < 40.0: return false
			_check(game.is_playing(), "into the world (%.1f s)" % (t - t0))
			var pl := _player()
			pl.global_position = Vector3(3.0, 0.1, 2.0)
			pl.call(&"set_view", 2.4, 2.4 + PI - 0.7, -0.28)
			step = 3; t0 = t
		3:
			if t - t0 < 2.0: return false
			_check(game.save(), "a save in the world: %.1f ms on the main thread to read the frame (%d taken)" % [game.get_shot_ms(), game.get_shots()])
			step = 31; t0 = t
		31:
			if game.is_shot_busy() and t - t0 < 3.0: return false
			_check(game.has_picture(0), "the picture is written (slot_0.jpg) on its own thread in %.2f s" % (t - t0))
			var pl := _player()
			saved_pos = pl.global_position; saved_view = pl.call(&"get_view")
			var im := Image.load_from_file(DIR + "slot_0.jpg")
			_check(im != null and im.get_width() == 640, "the picture is 640 wide: %s" % (str(im.get_size()) if im else "none"))
			im.save_png("res://OUT/save_picture_taken.png")
			step = 4; t0 = t
		4:      # the app opened again: the old shell and world go, a new shell starts
			game.queue_free()
			if current_scene: current_scene.queue_free()
			step = 5; t0 = t
		5:
			if t - t0 < 0.3: return false
			_make_game()
			step = 6; t0 = t
		6:
			if t - t0 < 0.6: return false
			_check(game.is_menu_open() and game.menu_picture_shown(), "with a save, the menu shows its picture")
			_check(game.press("menu.continue"), "Continue is pressed")
			step = 7; t0 = t
		7:
			if t - t0 < 0.1: return false
			_check(game.current_screen() == "loading" and game.loading_picture_shown(), "Continue's loading screen shows the picture")
			step = 8
		8:
			if not game.is_loading_fading() and t - t0 < 40.0: return false
			var pl := _player()
			var v: Array = pl.call(&"get_view") if pl else []
			_check(pl != null and pl.global_position.distance_to(saved_pos) < 0.3, "the player stands where the save left him: %.2f m off" % (pl.global_position.distance_to(saved_pos) if pl else 99.0))
			_check(v.size() == 3 and absf(v[0] - saved_view[0]) < 0.01 and absf(v[1] - saved_view[1]) < 0.01 and absf(v[2] - saved_view[2]) < 0.01, "looking the same way: %s (saved %s)" % [str(v), str(saved_view)])
			step = 9; t0 = t
		9:
			if game.is_loading_fading() and t - t0 < 3.0: return false
			_check(game.current_screen() != "loading", "the loading screen faded off the picture into the live world (%.2f s)" % (t - t0))
			step = 10; t0 = t
		10:
			if t - t0 < 0.3: return false
			var live := _frame()
			live.save_png("res://OUT/save_picture_live.png")
			var pic := Image.load_from_file(DIR + "slot_0.jpg")
			var d := _diff(live, pic)
			var pl := _player()
			pl.call(&"set_view", 0.0, PI, -0.18)
			step = 11; t0 = t
			_check(d < 0.05, "the live world matches the picture: mean colour difference %.3f" % d)
			set_meta(&"d_same", d)
		11:
			if t - t0 < 0.5: return false
			var d2 := _diff(_frame(), Image.load_from_file(DIR + "slot_0.jpg"))
			_check(d2 > float(get_meta(&"d_same")) * 2.0, "(the measure tells views apart: another view differs by %.3f)" % d2)
			_check(game.delete_slot(0) and not game.has_picture(0), "deleting the slot deletes its picture")
			print("RESULT %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
			quit(1 if fails else 0)
			return true
	return false
