extends SceneTree
## B1 again (Yasin, 21 Nov: "whenever menu is accessed after start, game crashes on every device"; the S23 and the PC
## crashed the same day):
##   godot --path . --rendering-method mobile --resolution 960x540 -s res://tests/game/test_menu_roundtrip.gd
## A new game; once he is let go: Esc (the pause menu), "Main menu", then "Continue" back into the game, twice; then
## the menu once more and Quit. Every step is printed before and after it, flushed, so a crash shows where it was.
var game: Node
var t := 0.0
var t0 := 0.0
var step := 0
var round := 0

func _say(s: String) -> void:
	print("MENU    [%.1f s] %s" % [t, s])

func _initialize() -> void:
	var boot := Node.new(); boot.name = "Boot"
	game = ClassDB.instantiate(&"CityGame"); game.name = "Game"
	game.set(&"saves_dir", "user://menu_test_saves/")
	for f in DirAccess.get_files_at("user://menu_test_saves/"): DirAccess.remove_absolute("user://menu_test_saves/" + f)
	boot.add_child(game); root.add_child(boot); current_scene = boot

func _esc() -> void:
	var e := InputEventKey.new(); e.keycode = KEY_ESCAPE; e.pressed = true
	Input.parse_input_event(e)
	var u := InputEventKey.new(); u.keycode = KEY_ESCAPE; u.pressed = false
	Input.parse_input_event(u)

# a real click (mouse down and up at the button's middle, through the viewport), as a thumb does: the engine's button code
# runs round our callback, which press() (emit_signal) skips
func _click(key: String) -> bool:
	var st: Array = [game]
	while not st.is_empty():
		var n: Node = st.pop_back()
		if n is Button and n.has_meta("key") and String(n.get_meta("key")) == key and (n as Button).is_visible_in_tree() and not (n as Button).disabled:
			var at: Vector2 = (n as Button).get_global_rect().get_center()
			for down in [true, false]:
				var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = down; e.position = at; e.global_position = at
				root.push_input(e)
			return true
		for c in n.get_children(): st.append(c)
	return false

func _process(delta: float) -> bool:
	t += delta
	match step:
		0:
			if t < 1.0: return false
			_say("new game (clicked)"); _click("menu.new_game"); step = 1; t0 = t
		1:
			if game.get_start_info().is_empty() and t - t0 < 180.0: return false
			_say("the world is in (%s)" % str(game.call(&"current_screen"))); step = 2; t0 = t
		2:
			if t - t0 < 8.0: return false
			_say("Esc: the pause menu"); _esc(); step = 3; t0 = t
		3:
			if t - t0 < 1.0: return false
			_say("screen now %s; pressing Main menu" % str(game.call(&"current_screen")))
			var ok: bool = _click("pause.main_menu")
			_say("pressed: %s; screen now %s" % [str(ok), str(game.call(&"current_screen"))]); step = 4; t0 = t
		4:
			if t - t0 < 3.0: return false
			_say("3 s on the menu; pressing Continue")
			var ok: bool = _click("menu.continue")
			_say("pressed: %s; screen now %s" % [str(ok), str(game.call(&"current_screen"))]); step = 5; t0 = t
		5:
			if t - t0 < 10.0: return false
			round += 1
			_say("10 s back in the game (round %d done)" % round)
			if round < 2: step = 2; t0 = t
			else: step = 6; t0 = t
		6:
			_say("Esc, Main menu, then Quit"); _esc(); step = 7; t0 = t
		7:
			if t - t0 < 1.0: return false
			_click("pause.main_menu"); step = 8; t0 = t
		8:
			if t - t0 < 2.0: return false
			_say("RESULT PASS (no crash through %d round trips)" % round)
			quit(0); return true
	return false
